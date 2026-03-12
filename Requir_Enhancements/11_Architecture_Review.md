# 11 — Architecture Review

## Executive Summary

The architectural foundation is decent — multi-tenant with database-per-tenant isolation, modular structure with 29 nwidart modules, RBAC via Spatie Permission. However, the implementation has significant gaps: near-total absence of a service layer (23/27 modules have zero services), no repository pattern, circular module dependencies, session-based state for large data, and inconsistent patterns across modules.

---

## 1. Service Layer Assessment

### ARCH-001: Only 6 of ~27 Active Modules Have Service Classes

| Module | Services | Assessment |
|--------|----------|------------|
| SmartTimetable | 15 files (14 deprecated in EXTRA_delete_10_02/) | Has services but controller still has 2,958 lines |
| Complaint | 2 (ComplaintAIInsightEngine, ComplaintDashboardService) | Good — dashboard logic properly extracted |
| Notification | 1 (NotificationService + 1 deprecated backup) | Minimal |
| Payment | 2 (GatewayManager, PaymentService) | Good |
| Scheduler | 2 (JobRegistry, SchedulerService) | Good |
| Prime | 1 (TenantPlanAssigner) | Minimal |

**23 modules have ZERO service classes.** All business logic lives directly in controllers.

### Impact
- Controllers are untestable (2,958-line SmartTimetableController)
- Business logic cannot be reused across controllers or API endpoints
- No separation between HTTP concerns and domain logic
- Module interfaces are tightly coupled to HTTP request/response cycle

### Recommendation
Create services for at minimum these high-complexity modules:
1. `TimetableGenerationService` — Extract from SmartTimetableController
2. `StudentManagementService` — Extract from StudentController
3. `ActivityManagementService` — Extract from ActivityController
4. `ComplaintEscalationService` — Extract duplicated escalation logic
5. `FeeCalculationService` — Extract from StudentFeeController
6. `ExamPaperService` — Extract from LmsExamController

---

## 2. Repository Pattern

### ARCH-002: No Repository Pattern

Zero repository classes exist in the entire codebase. The heavy query logic currently embedded in controllers (especially SmartTimetableController with 20+ inline `DB::table()` queries) would benefit from repositories.

### Recommendation
While not all modules need repositories, the following would benefit:
- SmartTimetable (complex joins, raw SQL, aggregations)
- StudentProfile (multi-table student data access)
- Complaint (repeated dropdown lookups, dashboard aggregations)

---

## 3. Module Coupling

### ARCH-003: Circular Module Dependencies (High Severity)

Modules directly reference other modules' models extensively:

| Dependency | Direction | Locations |
|-----------|-----------|-----------|
| SchoolSetup → SmartTimetable | **Inverted** (lower depends on higher) | 7+ controller files, 5+ model files |
| SmartTimetable → SchoolSetup | Expected | 20+ locations |
| Prime → SchoolSetup | **Inverted** | Controllers and models |
| All modules → Prime | Expected | User, AcademicSession, Dropdown |

**Circular dependencies:** SchoolSetup ↔ SmartTimetable, Prime ↔ SchoolSetup

### Impact
- Modules are not independently deployable
- Changes in one module can break others
- Testing requires loading dependent modules
- Violates Dependency Inversion Principle

### Recommendation
- Define interfaces in lower-level modules, implement in higher-level
- Use Laravel events for cross-module communication
- Use shared contracts/DTOs for inter-module data exchange

---

## 4. Session-Based State Management

### ARCH-005: Session Storage for Large Data

`SmartTimetableController::generateWithFET()` stores entire timetable grids, activity IDs, room assignments, and generation statistics in the PHP session (lines 2766-2815). This can create sessions of several MB per user generation attempt and will fail silently on session store size limits.

### Recommendation
- Use database-backed temporary storage (create a `tt_generation_sessions` table)
- Or use queued jobs with status polling
- Or use Redis for transient data with TTL

---

## 5. Request Validation

### ARCH-006: Inline Validation for Complex Operations

Most controllers use inline `$request->validate([...])` even for complex forms with 20+ fields. Only a few controllers use dedicated FormRequest classes.

| Pattern | Count | Assessment |
|---------|-------|------------|
| Dedicated FormRequest classes | ~168 | Good |
| Inline `$request->validate()` with 10+ rules | ~30+ | Should be FormRequests |
| No validation at all | ~15+ methods | Security risk |

### Notable Cases
- `StudentController::createParentDetails` has ~70 lines of inline validation rules
- `SmartTimetableController` has zero validation on generation parameters

---

## 6. Dependency Injection

### ARCH-007: Constructor vs Inline Instantiation

| Pattern | Controllers | Assessment |
|---------|------------|------------|
| Constructor injection | ComplaintController | Good practice |
| No injection — `new Service()` inline | SmartTimetableController, ActivityController | Untestable |
| No injection at all | StudentController, most others | No services to inject |

---

## 7. Event-Driven Architecture

### Current State

| Component | Count | Assessment |
|-----------|-------|------------|
| Events | 3 | Very minimal |
| Listeners | 2 | Very minimal |
| Jobs | 9 | Adequate for current scope |

Only 2 modules use events:
- Complaint: `ComplaintSaved` → `ProcessComplaintAIInsights`
- Notification: `SystemNotificationTriggered` → `ProcessSystemNotification`

### Missing Event Opportunities
- Student enrollment → trigger fee assignment, notification
- Timetable published → notify teachers, update dashboard
- Attendance marked → trigger compliance check
- Fee payment received → update invoice status, send receipt
- Exam results published → trigger HPC recalculation

---

## 8. API Architecture

### Current State
- Module API routes use `apiResource()` pattern with Sanctum auth
- API controllers are separate from web controllers
- No API versioning beyond the `/v1/` prefix
- No API documentation (Swagger/OpenAPI)
- No rate limiting beyond Laravel defaults

### Missing
- API response transformers (Fractal or Laravel API Resources)
- Consistent error response format
- API pagination standards
- Request/response logging for API endpoints

---

## 9. Testing Architecture

### Current State
- Pest 4.1 configured
- Only ~5 active tests
- No feature tests for controllers
- No unit tests for services
- No integration tests for multi-tenant scenarios

### Impact
- No regression protection for 381 models, 283 controllers
- Multi-tenant data isolation cannot be verified
- Permission/authorization rules are untested
- Payment webhook handling is untested

---

## 10. Configuration Architecture

### Strengths
- Clean 3-layer database separation (global/prime/tenant)
- Domain-based tenant identification
- Proper bootstrappers (DB, Cache, Filesystem, Queue)
- Well-structured permission configuration

### Weaknesses
- `env()` used directly in routes and controllers (breaks after config:cache)
- No environment-specific route names
- Debug tools (Telescope, Debugbar) not gated by environment
- Seeder/debug routes accessible in production

---

## Architecture Maturity Matrix

| Aspect | Current Level | Target Level | Gap |
|--------|--------------|-------------|-----|
| Multi-Tenancy | 4/5 | 5/5 | Minor (env() issues) |
| Modularity | 3/5 | 5/5 | Circular deps, tight coupling |
| Service Layer | 1/5 | 4/5 | 23 modules have zero services |
| Testing | 1/5 | 4/5 | ~5 tests for 381 models |
| Caching | 0/5 | 4/5 | Zero application caching |
| API Design | 2/5 | 4/5 | No transformers, no docs |
| Event Architecture | 1/5 | 3/5 | Only 3 events total |
| Security | 2/5 | 5/5 | Critical vulnerabilities found |
| Code Quality | 2/5 | 4/5 | Dead code, God controllers |
| Documentation | 3/5 | 4/5 | Good external, poor inline |

---

## Priority Recommendations

### Phase 1: Critical Fixes (Week 1-2)
1. Fix security vulnerabilities (SEC-002, SEC-004, SEC-005, SEC-008)
2. Remove `dd()` calls and debug routes from production
3. Fix `env()` usage in routes

### Phase 2: Foundation (Week 3-6)
4. Create service layer for top 6 complex modules
5. Split God controllers (SmartTimetable, Student)
6. Implement caching for reference data
7. Add FormRequest validation where missing

### Phase 3: Architecture (Week 7-12)
8. Resolve circular module dependencies
9. Implement event-driven cross-module communication
10. Add comprehensive test suite (start with critical paths)
11. Replace session storage with DB-backed temporary storage

### Phase 4: Polish (Week 13+)
12. Add API documentation (OpenAPI/Swagger)
13. Implement API response transformers
14. Add monitoring and alerting
15. Performance optimization based on production metrics
