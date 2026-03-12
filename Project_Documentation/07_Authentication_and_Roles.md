# 07 — Authentication and Roles

## Authentication System

### Technology Stack

| Component | Technology | Configuration |
|-----------|-----------|---------------|
| **Web Auth** | Laravel Session | Cookie-based, database-backed sessions |
| **API Auth** | Laravel Sanctum 4.0 | Token-based authentication |
| **RBAC** | Spatie Laravel Permission 6.21 | Role-based access control |
| **Hashing** | Bcrypt | 12 rounds (configurable) |
| **Password Reset** | Token-based | 60-minute expiry, 60-second throttle |

### Authentication Flow

```
Login Request
    │
    ▼
LoginRequest validation (email + password, rate limited: 5 attempts/60s)
    │
    ▼
AuthenticatedSessionController@store
    │
    ├── Auth::attempt(['email' => $email, 'password' => $password])
    ├── Session regeneration (CSRF protection)
    │
    ▼
Role-Based Redirect
    ├── Super Admin → /dashboard
    ├── Student → /student-portal/dashboard
    ├── Teacher → /student-portal/dashboard
    ├── Librarian → /student-portal/dashboard
    └── Others → /dashboard (default)
```

### User Model (`sys_users`)

**Key Fields:**
- `name`, `short_name`, `email`, `phone_no`, `mobile_no`
- `user_type` — Categorization
- `password` — Bcrypt hashed (cast)
- `is_super_admin` — Boolean flag
- `two_factor_auth_enabled` — 2FA support (field exists)
- `email_verified_at` — Email verification timestamp
- `is_active` — Account status
- `status` — Account status detail
- `last_login_at` — Last login tracking
- `remember_token` — "Remember me" support

**Traits Used:**
- `HasFactory` — Factory support for testing
- `Notifiable` — Notification support
- `HasRoles` (Spatie) — Role/permission management
- `SoftDeletes` — Soft deletion
- `InteractsWithMedia` (Spatie) — Media library support

**Relationships:**
- `organization()` — School affiliation
- `employee()` — Employee record
- `teacher()` — Teacher record
- `student()` — Student record
- `activityLogs()` — Audit trail

### Authentication Controllers

| Controller | Purpose |
|-----------|---------|
| `AuthenticatedSessionController` | Login/logout handling with role-based redirect |
| `RegisteredUserController` | New user registration |
| `PasswordResetLinkController` | Forgot password email dispatch |
| `NewPasswordController` | Password reset processing |
| `PasswordController` | Password change (authenticated) |
| `ConfirmablePasswordController` | Password confirmation for sensitive actions |
| `EmailVerificationPromptController` | Email verification prompt |
| `EmailVerificationNotificationController` | Resend verification email |
| `VerifyEmailController` | Email verification processing |

### API Authentication (Sanctum)

```
API Request
    │
    ▼
auth:sanctum middleware
    │
    ├── Checks Authorization: Bearer <token> header
    ├── Validates personal_access_tokens table
    ├── Resolves user from token
    │
    ▼
Request proceeds with authenticated user context
```

**Configuration:**
- Stateful domains: localhost, 127.0.0.1, APP_URL
- Token expiration: None (no auto-expiry)
- Guard: `web`
- Middleware: Session authentication + CSRF validation

---

## Role-Based Access Control (RBAC)

### Permission System Architecture

```
┌─────────────────────────────────────────────────┐
│                  RBAC Architecture               │
│                                                  │
│  User ──M2M──► Roles ──M2M──► Permissions       │
│    │                                             │
│    └──M2M──► Permissions (direct assignment)     │
│                                                  │
│  Tables:                                         │
│  sys_users ◄──► sys_model_has_roles_jnt          │
│  sys_roles ◄──► sys_role_has_permissions_jnt     │
│  sys_users ◄──► sys_model_has_permissions_jnt    │
│  sys_permissions                                 │
└─────────────────────────────────────────────────┘
```

### Central Roles (Prime DB — 6 Roles)

| Role | System | Description |
|------|--------|-------------|
| **Super Admin** | Yes | Full system access — bypasses all permission checks |
| **Manager** | No | Company operations management |
| **Accounting** | No | Financial and bookkeeping |
| **Invoicing** | No | Billing and payment processing |
| **Student** | No | Student access to central features |
| **Parent** | No | Parent access to central features |

### Tenant Roles (Tenant DB — 9 Roles)

| Role | System | Description |
|------|--------|-------------|
| **Super Admin** | Yes | Full tenant access — bypasses all tenant permission checks |
| **Principal** | No | School head, oversees all operations |
| **Vice Principal** | No | Academic and discipline management |
| **Teacher** | No | Classroom teaching and student management |
| **Staff** | No | Non-teaching administrative staff |
| **Accountant** | No | Financial and fee management |
| **Librarian** | No | Library resource management |
| **Parent** | No | Ward/student data access |
| **Student** | No | Personal academic data access |

### Permission Naming Convention

```
Format: module.feature.action

Examples:
  prime.tenant.create
  prime.tenant.viewAny
  prime.user.update
  prime.billing-management.pdf
  tenant.class.create
  tenant.student.viewAny
  tenant.timetable.generate
  tenant.fee-invoice.export
```

### Standard CRUD Actions

| Action | Description |
|--------|-------------|
| `create` | Create new record |
| `view` | View single record |
| `viewAny` | List/view all records |
| `update` | Edit existing record |
| `delete` | Soft delete record |
| `restore` | Restore soft-deleted record |
| `forceDelete` | Permanently delete record |
| `import` | Bulk import from Excel |
| `export` | Export to Excel/CSV |
| `print` | Print/PDF generation |
| `status` | Toggle active/inactive status |
| `email-schedule` | Schedule email dispatch |
| `remark` | Add remarks/notes |
| `pdf` | Generate PDF document |

### Permission Modules (Central — Prime Scope)

| Category | Modules |
|----------|---------|
| **Core** | menu, setting, dropdown, activity-log, language |
| **Geography** | country, state, district, city |
| **Auth** | user, role-permission |
| **Academic** | academic-session, board, module |
| **Billing** | billing-cycle, plan, invoicing, subscription, invoicing-payment, consolidated-payment, payment-reconciliation, invoicing-audit-log, billing-management |

### Permission Modules (Tenant Scope)

| Category | Modules |
|----------|---------|
| **School** | class, section, subject, teacher, student, infrastructure, rooms, building, room-type, study-format, timing-profile, department, designation, entity-group |
| **Timetable** | activity, period, period-set, day-type, school-day, working-day, constraint, timetable, tt-config, generation-strategy, academic-term, teacher-availability, room-unavailable |
| **Transport** | vehicle, route, trip, driver-helper, pickup-point, shift, student-allocation, student-boarding, student-attendance, driver-attendance, fee-master, fee-collection, fine-master, vehicle-inspection, vehicle-fuel, vehicle-maintenance, dashboard, reports |
| **Finance** | fee-head, fee-group, fee-structure, fee-installment, fee-invoice, fee-receipt, fee-concession, fee-fine, fee-scholarship, payment-gateway |
| **Academics** | lesson, topic, competency, bloom-taxonomy, cognitive-skill, complexity-level, performance-category, study-material, question-type, syllabus-schedule |
| **Assessment** | question-bank, question-tag, question-version, question-statistic, exam, exam-paper, quiz, homework, quest |
| **HPC** | learning-outcome, learning-activity, hpc-parameter, performance-descriptor, circular-goal, student-evaluation |
| **Operations** | complaint, complaint-category, department-sla, notification, notification-template, notification-channel, vendor, vendor-agreement, vendor-invoice |
| **Recommendation** | recommendation-rule, recommendation-material, student-recommendation, trigger-event |

---

## Middleware Stack

### Authentication Middleware

| Middleware | Purpose | Applied To |
|-----------|---------|-----------|
| `auth` | Verify user is authenticated | All protected routes |
| `verified` | Verify email is confirmed | Central admin routes |
| `auth:sanctum` | API token verification | All API routes |
| `guest` | Redirect if already authenticated | Login/register routes |

### Tenancy Middleware

| Middleware | Purpose | Applied To |
|-----------|---------|-----------|
| `InitializeTenancyByDomain` | Resolve tenant from domain | All tenant routes |
| `PreventAccessFromCentralDomains` | Block central domain on tenant routes | Tenant route group |
| `EnsureTenantIsActive` | Check tenant is active + complete | All tenant routes |
| `EnsureTenantHasModule` | Check module access per plan | Feature-specific routes |
| `PreventBackHistory` | Browser back-button prevention | All responses |

### Authorization Flow

```
Request → auth → verified → InitializeTenancyByDomain
    → EnsureTenantIsActive → EnsureTenantHasModule
    → Controller → $this->authorize() → Policy
    → Gate checks role/permission via Spatie
    → Super Admin bypasses all checks
    → Response
```

---

## Authorization Policies (195+ Files)

Located in: `/app/Policies/`

**Coverage by Module:**

| Module | Estimated Policies | Examples |
|--------|-------------------|----------|
| SchoolSetup | 15+ | ClassPolicy, SectionPolicy, SubjectPolicy, TeacherPolicy, RoomPolicy |
| SmartTimetable | 8+ | TimetablePolicy, ActivityPolicy, ConstraintPolicy, PeriodPolicy |
| Transport | 20+ | VehiclePolicy, RoutePolicy, TripPolicy, DriverPolicy |
| StudentProfile | 3+ | StudentPolicy, AttendancePolicy, MedicalCheckPolicy |
| StudentFee | 5+ | FeePolicy, InvoicePolicy, ReceiptPolicy |
| Complaint | 4+ | ComplaintPolicy, ComplaintCategoryPolicy, SlaPolicy |
| LMS (all) | 15+ | ExamPolicy, QuizPolicy, HomeworkPolicy, QuestPolicy |
| Vendor | 4+ | VendorPolicy, AgreementPolicy, InvoicePolicy |
| HPC | 4+ | LearningOutcomePolicy, EvaluationPolicy, ParameterPolicy |
| QuestionBank | 5+ | QuestionBankPolicy, QuestionTagPolicy, StatisticPolicy |
| Central | 50+ | TenantPolicy, PlanPolicy, UserPolicy, BillingPolicy |

**Standard Policy Methods:**
```php
viewAny(User $user)          // Can list all records
view(User $user, $model)     // Can view specific record
create(User $user)            // Can create new record
update(User $user, $model)   // Can edit record
delete(User $user, $model)   // Can soft-delete record
restore(User $user, $model)  // Can restore soft-deleted
forceDelete(User $user, $model) // Can permanently delete
```

---

## Permission Helper Utility

**Location:** `/app/Helpers/PermissionHelper.php`

| Method | Purpose |
|--------|---------|
| `all(?role)` | Get all permissions (optionally filtered by role) |
| `flatten(?role)` | Flat array with dot notation (e.g., `module.action`) |
| `forModule(module, ?role)` | Get permissions for specific module |
| `forActions(module, actions[])` | Map actions to dot-notation permissions |
| `structured(?role)` | Raw permission config structure |
| `exists(permission, ?role)` | Check if permission exists |
| `getDisplayName(permission)` | Format for UI display |

---

## Seeders

| Seeder | Purpose |
|--------|---------|
| `RolePermissionSeeder` | Creates 6 central roles + assigns 'prime' scope permissions |
| `TenantRolePermissionSeeder` | Creates 9 tenant roles + assigns 'tenant' scope permissions |

Both seeders use `Role::firstOrCreate()` with `guard_name: 'web'` for idempotent execution.
