# 05 — API Documentation

## API Architecture

The platform uses a **dual routing strategy**:

1. **Central API** (`routes/api.php`) — Minimal, mostly for user authentication
2. **Module APIs** (`Modules/*/routes/api.php`) — Per-module RESTful endpoints
3. **Web Routes** (`routes/web.php` + `routes/tenant.php`) — Server-rendered CRUD operations

**Authentication:** Laravel Sanctum (`auth:sanctum` middleware) for API token-based access.

**API Versioning:** `/v1/` prefix on all module API routes.

---

## Central API Endpoints

### Authentication

| Method | Endpoint | Controller | Middleware | Description |
|--------|----------|------------|------------|-------------|
| GET | `/api/user` | — (closure) | `auth:sanctum` | Get authenticated user |

### Auth Web Routes (Central Domain)

| Method | Endpoint | Controller | Description |
|--------|----------|------------|-------------|
| GET | `/login` | AuthenticatedSessionController@create | Show login form |
| POST | `/login` | AuthenticatedSessionController@store | Process login |
| POST | `/logout` | AuthenticatedSessionController@destroy | Logout user |
| GET | `/register` | RegisteredUserController@create | Show registration form |
| POST | `/register` | RegisteredUserController@store | Process registration |
| GET | `/forgot-password` | PasswordResetLinkController@create | Show reset form |
| POST | `/forgot-password` | PasswordResetLinkController@store | Send reset link |
| GET | `/reset-password/{token}` | NewPasswordController@create | Show new password form |
| POST | `/reset-password` | NewPasswordController@store | Process password reset |
| GET | `/verify-email` | EmailVerificationPromptController | Show verification prompt |
| GET | `/verify-email/{id}/{hash}` | VerifyEmailController | Verify email address |
| POST | `/email/verification-notification` | EmailVerificationNotificationController | Resend verification |

---

## Module API Endpoints (RESTful)

All module APIs follow this pattern:
```
Middleware: auth:sanctum
Prefix: /v1
Pattern: apiResource (generates 5 standard endpoints)
```

### Prime Module API

| Method | Endpoint | Controller | Description |
|--------|----------|------------|-------------|
| GET | `/v1/primes` | PrimeController@index | List all tenants/resources |
| POST | `/v1/primes` | PrimeController@store | Create resource |
| GET | `/v1/primes/{id}` | PrimeController@show | Get resource detail |
| PUT | `/v1/primes/{id}` | PrimeController@update | Update resource |
| DELETE | `/v1/primes/{id}` | PrimeController@destroy | Delete resource |

### GlobalMaster Module API

| Method | Endpoint | Controller | Description |
|--------|----------|------------|-------------|
| GET | `/v1/globalmasters` | GlobalMasterController@index | List global masters |
| POST | `/v1/globalmasters` | GlobalMasterController@store | Create master record |
| GET | `/v1/globalmasters/{id}` | GlobalMasterController@show | Get master detail |
| PUT | `/v1/globalmasters/{id}` | GlobalMasterController@update | Update master record |
| DELETE | `/v1/globalmasters/{id}` | GlobalMasterController@destroy | Delete master record |

### SchoolSetup Module API

| Method | Endpoint | Controller | Description |
|--------|----------|------------|-------------|
| GET | `/v1/schoolsetups` | SchoolSetupController@index | List school setup items |
| POST | `/v1/schoolsetups` | SchoolSetupController@store | Create setup item |
| GET | `/v1/schoolsetups/{id}` | SchoolSetupController@show | Get setup detail |
| PUT | `/v1/schoolsetups/{id}` | SchoolSetupController@update | Update setup item |
| DELETE | `/v1/schoolsetups/{id}` | SchoolSetupController@destroy | Delete setup item |

### SmartTimetable Module API

| Method | Endpoint | Controller | Description |
|--------|----------|------------|-------------|
| GET | `/v1/smarttimetables` | SmartTimetableController@index | List timetables |
| POST | `/v1/smarttimetables` | SmartTimetableController@store | Create timetable |
| GET | `/v1/smarttimetables/{id}` | SmartTimetableController@show | Get timetable detail |
| PUT | `/v1/smarttimetables/{id}` | SmartTimetableController@update | Update timetable |
| DELETE | `/v1/smarttimetables/{id}` | SmartTimetableController@destroy | Delete timetable |

### Complaint Module API

| Method | Endpoint | Controller | Description |
|--------|----------|------------|-------------|
| GET | `/v1/complaints` | ComplaintController@index | List complaints |
| POST | `/v1/complaints` | ComplaintController@store | Create complaint |
| GET | `/v1/complaints/{id}` | ComplaintController@show | Get complaint detail |
| PUT | `/v1/complaints/{id}` | ComplaintController@update | Update complaint |
| DELETE | `/v1/complaints/{id}` | ComplaintController@destroy | Delete complaint |

### StudentProfile Module API

| Method | Endpoint | Controller | Description |
|--------|----------|------------|-------------|
| GET | `/v1/studentprofiles` | StudentProfileController@index | List students |
| POST | `/v1/studentprofiles` | StudentProfileController@store | Create student |
| GET | `/v1/studentprofiles/{id}` | StudentProfileController@show | Get student detail |
| PUT | `/v1/studentprofiles/{id}` | StudentProfileController@update | Update student |
| DELETE | `/v1/studentprofiles/{id}` | StudentProfileController@destroy | Delete student |

### Other Module APIs (Same Pattern)

| Module | Endpoint Prefix | Controller |
|--------|----------------|------------|
| Transport | `/v1/transports` | TransportController |
| Syllabus | `/v1/syllabi` | SyllabusController |
| QuestionBank | `/v1/questionbanks` | QuestionBankController |
| LmsQuiz | `/v1/lmsquizzes` | LmsQuizController |
| StudentFee | `/v1/studentfees` | StudentFeeController |
| Hpc | `/v1/hpcs` | HpcController |

> **Note:** Modules without active API routes: Billing, Notification, Vendor, LmsExam, LmsHomework, LmsQuests, Recommendation, SyllabusBooks, Documentation, Scheduler, SystemConfig.

---

## Web Route Endpoints (Central Admin)

**Domain:** Central admin domain (`env('APP_DOMAIN')`)
**Middleware:** `auth`, `verified`

### Dashboard Routes

| Method | Endpoint | Controller | Description |
|--------|----------|------------|-------------|
| GET | `/dashboard` | DashboardController@index | Admin dashboard |
| GET | `/dashboard/configuration` | DashboardController@configuration | Config dashboard |
| GET | `/dashboard/foundational-setup` | DashboardController@foundationalSetup | Setup dashboard |
| GET | `/dashboard/subscription-billing` | DashboardController@subscriptionBilling | Billing dashboard |

### Prime Management Routes (`/prime/*`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET/POST | `/prime/tenants` | Tenant list / create |
| GET/PUT/DELETE | `/prime/tenants/{id}` | Show / update / delete tenant |
| POST | `/prime/tenants/{id}/toggle-status` | Toggle tenant active/inactive |
| POST | `/prime/tenants/{id}/restore` | Restore soft-deleted tenant |
| DELETE | `/prime/tenants/{id}/force-delete` | Permanently delete tenant |
| GET/POST | `/prime/users` | User management |
| GET/POST | `/prime/role-permission` | Role-permission management |
| GET/POST | `/prime/academic-sessions` | Academic session management |
| GET/POST | `/prime/boards` | Board management |

### Billing Routes (`/billing/*`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| CRUD | `/billing/billing-management` | Billing management |
| CRUD | `/billing/subscription` | Subscription management |
| CRUD | `/billing/invoicing-payment` | Payment tracking |
| CRUD | `/billing/invoicing-audit-log` | Audit log viewing |
| CRUD | `/billing/billing-cycle` | Billing cycle configuration |
| POST | `/billing/send-email/{id}` | Send invoice email |
| POST | `/billing/schedule-email/{id}` | Schedule invoice email |

### Global Master Routes (`/global-master/*`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| CRUD | `/global-master/country` | Country management |
| CRUD | `/global-master/state` | State management |
| CRUD | `/global-master/city` | City management |
| CRUD | `/global-master/district` | District management |
| CRUD | `/global-master/plan` | Plan management |
| CRUD | `/global-master/language` | Language management |
| CRUD | `/global-master/module` | Module management |
| CRUD | `/global-master/activity-log` | Activity log viewing |
| CRUD | `/global-master/dropdown` | Dropdown management |
| GET | `/global-master/getStatesByCountry/{id}` | Get states for a country (AJAX) |

---

## Web Route Endpoints (Tenant)

**Middleware:** `auth`, `verified`, `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`

### School Setup Routes (`/school-setup/*`)

| Endpoint Pattern | Description |
|------------------|-------------|
| `/school-setup/organization` | Organization CRUD + toggle-status, restore, force-delete |
| `/school-setup/class` | Class CRUD |
| `/school-setup/section` | Section CRUD |
| `/school-setup/subject` | Subject CRUD |
| `/school-setup/teacher` | Teacher CRUD |
| `/school-setup/room` | Room CRUD |
| `/school-setup/room-type` | Room type CRUD |
| `/school-setup/building` | Building CRUD |
| `/school-setup/department` | Department CRUD |
| `/school-setup/designation` | Designation CRUD |
| `/school-setup/subject-group` | Subject group CRUD |
| `/school-setup/class-group` | Class group management |
| `/school-setup/entity-group` | Entity group CRUD |
| `/school-setup/study-format` | Study format CRUD |
| `/school-setup/role-permission` | Tenant RBAC management |
| `/school-setup/users` | Tenant user management |

### SmartTimetable Routes (`/smart-timetable/*`)

| Endpoint Pattern | Description |
|------------------|-------------|
| `/smart-timetable/timetable` | Timetable generation and management |
| `/smart-timetable/activity` | Activity CRUD |
| `/smart-timetable/period-set` | Period set CRUD |
| `/smart-timetable/constraint` | Constraint management |
| `/smart-timetable/teacher-availability` | Teacher availability tracking |
| `/smart-timetable/teacher-unavailable` | Teacher unavailability |
| `/smart-timetable/room-unavailable` | Room unavailability |
| `/smart-timetable/school-day` | School day configuration |
| `/smart-timetable/working-day` | Working day setup |
| `/smart-timetable/tt-config` | Timetable configuration |
| `/smart-timetable/generation-strategy` | Generation strategy setup |
| `/smart-timetable/consolidate` | Requirement consolidation |

### Transport Routes (`/transport/*`)

| Endpoint Pattern | Description |
|------------------|-------------|
| `/transport/vehicle` | Vehicle CRUD |
| `/transport/route` | Route CRUD |
| `/transport/trip` | Trip management |
| `/transport/driver-helper` | Driver management |
| `/transport/pickup-point` | Pickup point CRUD |
| `/transport/student-allocation` | Student-route allocation |
| `/transport/student-attendance` | Student transport attendance |
| `/transport/driver-attendance` | Driver attendance (QR) |
| `/transport/fee-master` | Transport fee setup |
| `/transport/fee-collection` | Fee collection |
| `/transport/fine-master` | Fine configuration |
| `/transport/vehicle-inspection` | Daily inspections |
| `/transport/vehicle-maintenance` | Maintenance records |
| `/transport/vehicle-fuel` | Fuel tracking |
| `/transport/dashboard` | Transport dashboard |
| `/transport/reports` | Transport reports |

### Additional Tenant Route Groups

| Route Group | Prefix | Key Endpoints |
|-------------|--------|---------------|
| Student Profile | `/student/*` | Students, attendance, medical, reports |
| Student Fee | `/student-fee/*` | Fee heads, invoices, scholarships, concessions, fines |
| Syllabus | `/syllabus/*` | Lessons, topics, competencies, bloom taxonomy |
| Question Bank | `/question-bank/*` | Questions, tags, statistics, AI generation |
| LMS Exam | `/exam/*` | Exams, papers, allocations, blueprints |
| LMS Quiz | `/quiz/*` | Quizzes, questions, allocations |
| LMS Homework | `/homework/*` | Homework, submissions, rules |
| LMS Quests | `/quests/*` | Quests, questions, scopes |
| HPC | `/hpc/*` | Learning outcomes, evaluations, parameters |
| Complaint | `/complaint/*` | Complaints, categories, SLA, dashboard |
| Notification | `/notification/*` | Channels, templates, targets, delivery |
| Vendor | `/vendor/*` | Vendors, agreements, invoices, payments |
| Payment | `/payment/*` | Payment processing, gateway config |
| Recommendation | `/recommendation/*` | Rules, materials, student recommendations |
| Student Portal | `/student-portal/*` | Student dashboard, academics, payments |
| System Config | `/system-config/*` | Settings, menus |

---

## Common CRUD Pattern

Most resources follow this standard pattern:

```
GET    /{resource}                    → index (list with pagination)
GET    /{resource}/create             → create (show form)
POST   /{resource}                    → store (save new)
GET    /{resource}/{id}               → show (detail view)
GET    /{resource}/{id}/edit          → edit (show edit form)
PUT    /{resource}/{id}               → update (save changes)
DELETE /{resource}/{id}               → destroy (soft delete)
GET    /{resource}/trashed            → trashedResource (list deleted)
POST   /{resource}/{id}/restore       → restore (restore deleted)
DELETE /{resource}/{id}/force-delete   → forceDelete (permanent delete)
POST   /{resource}/{id}/toggle-status → toggleStatus (enable/disable)
```
