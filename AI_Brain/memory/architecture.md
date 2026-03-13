# System Architecture — Prime-AI

> **Last Updated:** 2026-03-12
> **Source:** `11_Architecture_Review.md` + `12_System_Diagrams.md`

---

## Overall System Architecture

```
Client Layer
  WEB Browser / API Client / Mobile App
         │
         ▼
Application Layer
  Nginx / Apache → Laravel 12.0
         │
  Middleware Stack:
    auth / verified (session)
    auth:sanctum (API)
    InitializeTenancyByDomain → resolve tenant from prm_tenant_domains
    EnsureTenantIsActive → check is_active + profile complete + modules
    EnsureTenantHasModule → check plan module access
         │
  29 Feature Modules
    Central: Prime, GlobalMaster, SystemConfig, Billing (→ prime_db, global_db)
    Tenant: SchoolSetup, SmartTimetable, Transport, ... (→ tenant_db)
         │
Data Layer
  global_db (12 tables) — shared reference data
  prime_db (27 tables) — SaaS management
  tenant_{uuid} (368 tables) — per-school isolated data

External Services
  Razorpay API (payments)
  SMTP / SES (email)
  File Storage (local / S3)
```

---

## Request Flow

```
HTTP Request
  → auth middleware (session/Sanctum token)
  → [if tenant route] InitializeTenancyByDomain
    → resolve domain → prm_tenant_domains
    → bootstrap: DB connection + Cache prefix + FS path + Queue context
    → EnsureTenantIsActive (is_active + profile complete + modules assigned)
    → EnsureTenantHasModule (plan includes this module)
  → Controller
    → $this->authorize('action', Model) → Policy → Spatie Role check
    → Business logic (often inline, sometimes via Service class)
    → Model / DB query (auto-scoped to tenant_db)
  → Response (HTML blade / JSON)
```

---

## Module Dependency Graph

```
Central Scope:
  Prime → GlobalMaster (views)
  Prime → SystemConfig
  Prime → Billing

Core Tenant:
  SchoolSetup → GlobalMaster (countries, boards)
  SchoolSetup → Prime (User, AcademicSession, Dropdown)
  SmartTimetable → SchoolSetup (classes, teachers, rooms)
  StudentProfile → SchoolSetup (class-sections)

Operations:
  Transport → SchoolSetup + StudentProfile
  Vendor → (standalone)
  Complaint → StudentProfile
  Notification → (fire-and-forget via events)
  Payment → StudentFee

Curriculum:
  Syllabus → SchoolSetup (class, subject)
  SyllabusBooks → Syllabus
  QuestionBank → Syllabus

LMS / Assessment:
  LmsExam → QuestionBank
  LmsQuiz → QuestionBank
  LmsHomework → Syllabus
  LmsQuests → QuestionBank

Analytics:
  HPC → Syllabus + QuestionBank
  Recommendation → HPC + Syllabus
  StudentFee → StudentProfile + Payment
```

**Known Circular Dependencies (ARCH-003):**
- SchoolSetup ↔ SmartTimetable (mutual references, inverted dependency)
- Prime ↔ SchoolSetup (Prime controllers reference SchoolSetup models)

---

## Service Layer Architecture

### Current State: 12 Services Total (6 Modules)

| Module | Services | Quality |
|--------|----------|---------|
| SmartTimetable | ActivityScoreService, RoomAvailabilityService, SubActivityService, TimetableStorageService, DatabaseConstraintService + solver components | Best practice — atomic persistence, scoring formula |
| Complaint | ComplaintAIInsightEngine, ComplaintDashboardService | Good — business logic extracted |
| Notification | NotificationService | Minimal |
| Payment | PaymentService, GatewayManager | Good — pluggable gateway pattern |
| Scheduler | JobRegistry, SchedulerService | Good |
| Prime | TenantPlanAssigner | Minimal |

**23 modules have ZERO service classes.** All business logic lives directly in controllers.

### Major Controllers (Lines of Code)
| Controller | Size | Issue |
|------------|------|-------|
| SmartTimetableController | 2,958 lines | God object — zero authorization, session-based state storage |
| StudentController | ~1000+ lines | Inline parent creation validation (~70 lines) |
| ActivityController | 400+ lines | generateActivities has nested query loops |
| ComplaintController | 207+ lines in index() alone | Duplicate complaint loading, 20+ queries |
| SchoolClassController | 15+ queries in index() | Mega index method |

---

## Key Architectural Patterns

### 1. Standard CRUD Pattern (all modules)
```
Route: GET/{resource}, POST/{resource}, GET/{resource}/{id}, PUT/{resource}/{id}, DELETE/{resource}/{id}
Plus: GET/{resource}/trashed, POST/{resource}/{id}/restore, DELETE/{resource}/{id}/force-delete, POST/{resource}/{id}/toggle-status
```

### 2. Authorization Pattern
```php
// Standard policy call
$this->authorize('create', Model::class);
// Gate approach
Gate::authorize('prime.tenant.update');
// Blade
@can('update', $model) ... @endcan
// Middleware
->middleware('permission:manage-students')
```

### 3. Event-Driven Modules (only 2 active)
```
ComplaintSaved event → ProcessComplaintAIInsights listener (queued)
  → ComplaintAIInsightEngine → sentiment + risk + category scoring

SystemNotificationTriggered event → ProcessSystemNotification listener (queued)
  → NotificationService → channel dispatch (Email/In-App)
```

### 4. SmartTimetable Solver Pattern
```
Prerequisites (Setup) → Pre-Generation (Score + Room + SubActivity) → FET Solver
  → Backtracking CSP (50K iterations, 25s timeout)
  → TimetableStorageService (atomic DB transaction)
  → Approval Workflow → PUBLISHED status
```

### 5. Payment Gateway Pattern (Pluggable)
```
PaymentService → GatewayManager.resolve('razorpay') → RazorpayGateway → API
Webhook: PaymentCallbackController → signature verify → fee invoice update
```

### 6. Tenant Isolation Pattern
```
Global data: glb_* views in prime_db (read-only reference)
Central data: prm_*, bil_*, sys_* in prime_db (per-SaaS)
Tenant data: ALL other tables in tenant_{uuid} (per-school)
Storage: storage/tenant_{uuid}/ (isolated file paths)
Cache: prefixed with tenant ID (when used — currently zero caching)
Queue: QueueTenancyBootstrapper passes tenant context to jobs
```

---

## Architecture Maturity Matrix

| Aspect | Current Level | Target Level | Key Gap |
|--------|--------------|-------------|---------|
| Multi-Tenancy | 4/5 | 5/5 | env() direct usage in routes |
| Modularity | 3/5 | 5/5 | Circular deps, tight coupling |
| Service Layer | 1/5 | 4/5 | 23 modules have zero services |
| Testing | 1/5 | 4/5 | ~5 tests for 381 models |
| Caching | 0/5 | 4/5 | Zero application caching |
| API Design | 2/5 | 4/5 | No transformers, no docs |
| Event Architecture | 1/5 | 3/5 | Only 3 events total |
| Security | 2/5 | 5/5 | 4 critical vulnerabilities |
| Code Quality | 2/5 | 4/5 | Dead code, God controllers |

---

## Configuration Architecture

### Key Config Files
| File | Critical Setting |
|------|-----------------|
| `config/tenancy.php` | Tenant model, UUID generator, DB prefix `tenant_`, bootstrappers |
| `config/permission.php` | RBAC tables: sys_roles, sys_permissions; Cache: 24h |
| `config/permissionslist.php` | All prime + tenant permission definitions |
| `config/database.php` | Central MySQL + tenant template |
| `config/sanctum.php` | Stateful domains, web guard, token expiry (null = no expiry) |

### Critical Config Issue: env() in Routes
`routes/web.php` line 62 uses `Route::domain(env('APP_DOMAIN'))`. After `php artisan config:cache`, `env()` returns null, breaking ALL central admin routing. Fix: use `config('app.domain')`.

---

## Service Providers (5 Total)

| Provider | Key Responsibility |
|----------|--------------------|
| AppServiceProvider | Gate policies registration (195+ via Gate::policy()), pagination, breadcrumb binding |
| TenancyServiceProvider | Tenant events, bootstrappers (DB, Cache, FS, Queue). NOTE: MigrateDatabase commented out — BUG-004 |
| TelescopeServiceProvider | Debug toolbar |
| HelperServiceProvider | Global helper functions |
| MenuServiceProvider | Menu configuration |

---

## Data Flow Diagrams

### Multi-Tenancy Flow
```
school1.prime-ai.com → Nginx → Laravel
  → InitializeTenancyByDomain
  → prm_tenant_domains lookup → prm_tenant
  → DatabaseTenancyBootstrapper: switch DB to tenant_abc123
  → CacheTenancyBootstrapper: prefix cache keys
  → FilesystemTenancyBootstrapper: prefix storage paths
  → QueueTenancyBootstrapper: inject tenant into jobs
  → All subsequent queries → tenant_abc123 database
```

### Fee Payment Flow
```
Student → Razorpay checkout
  → PaymentService.createPayment() → pmt_payments record
  → GatewayManager.resolve('razorpay') → RazorpayGateway
  → Razorpay API: create order
  → Student completes payment
  → Webhook: POST /payment/webhook/razorpay
    [ISSUE: this route is behind auth middleware — payments fail, BUG SEC-004]
  → Signature verification → fin_fee_transactions + fin_fee_receipts
  → Invoice status → Paid
```
