# Complete Audit — SchoolSetup (SCH) — 2026-06-30
## Mode X: A + B + C + G + scoped D

| Field | Value |
|-------|-------|
| Module | SchoolSetup |
| Code | SCH |
| Table Prefix | `sch_*` |
| Module Path | `Modules/SchoolSetup/` |
| DB Layer | Tenant |
| Audit Date | 2026-06-30 |
| Auditor | pa-technical-auditor (Mode X) |
| Evidence Base | Live code + tenant migrations + DDL spec + FRD (SCH_FRD_2026-06-30.md) |

---

## Executive Summary

SchoolSetup is the largest and most critical module in Prime-AI — 52 `sch_*` tables, 56 active web controllers, 69 models, 26 FormRequests, 336 views, 4 Artisan console commands, and zero tests. As the provider of foundational reference data (`sch_classes`, `sch_sections`, `sch_subjects`, `sch_employees`, `sch_organizations`) consumed by every other tenant module, security and correctness failures here propagate platform-wide.

The audit confirms six **P0 blockers** that prevent safe production use: a mass-assignable `is_super_admin` field that allows any authenticated user to self-promote to super-admin; the complete absence of `EnsureTenantHasModule` middleware meaning the module is accessible without a license; a missing `sch_entity_group_members` migration that crashes on any entity-group-member operation (SQLSTATE 42S02); an unescaped `{!! $user->name !!}` XSS in the user edit form; and a D36 failure on `sch_org_academic_sessions_jnt.current_flag` (plain boolean with no unique constraint allows multiple "current" sessions). The module also accumulates 14 P1 findings including 8 routes that map to missing controller methods (fatal 500s), the D30 pattern (all 26 FormRequests return bare `true`), and the D41 pattern (`session('tenant_id')` in 6 controller locations).

**Health Score: 37/100 (P0 capped at 40)** — DEPLOY: **NO-GO**.

---

## Health Score

| Layer | Weight | Color | Score | Key Finding |
|-------|--------|-------|-------|-------------|
| 6 Tenancy | 15 | AMBER | 0.5 | EnsureTenantHasModule absent (P0); session('tenant_id') in 6 locations (TEN-SCH-001); console cmds initialize() without end() (TEN-SCH-002) |
| 5 Authorization | 14 | RED | 0.0 | is_super_admin in $fillable (P0); 4+ controllers with zero Gate calls; UserController index() auth commented out; all 26 FormRequests return true (D30) |
| 8 Data Integrity/Tx | 13 | AMBER | 0.5 | Good DB::transaction use; zero lockForUpdate; D36 available_balance plain column; add/revert alter migration sequence |
| 7 Validation/Mass-assign | 11 | RED | 0.0 | $request->all() in OrganizationController (×2) and OrganizationGroupController (×2); D25+D30 double-exposure; ClassSubjectManagementController empty bodies |
| 12 Deployment | 10 | AMBER | 0.5 | RSP correctly configured; EnsureTenantHasModule missing; SEC-RTG-001 platform seeder route still live |
| 2 Migration↔Model↔DDL | 9 | AMBER | 0.5 | sch_entity_group_members missing migration (P0 crash); sch_designations no softDeletes vs model uses SoftDeletes; D36 degradations; cross-DB FKs |
| 1 DDL Schema | 7 | AMBER | 0.5 | 11 ENUM columns (D29); cross-DB FKs to glb_cities, glb_academic_sessions, glb_boards; D36 current_flag/available_balance |
| 9 Performance | 7 | AMBER | 0.5 | Role::all() in 15+ request paths (PERF-SCH-003); PERF-SCH-001/002 N+1 previously registered |
| 10 Queue/Job | 6 | AMBER | 0.5 | 0 Jobs (no queue risk); console commands have tenancy context leak |
| 4 Code Quality | 4 | AMBER | 0.5 | EmployeeProfileController 1595 lines (God controller); rand() debug code in production; 8 routes → missing methods; competency.blade.php misplaced |
| 3 ORM | 2 | AMBER | 0.5 | EmployeeBankDetail PII plaintext; misplaced models (QuestionType, PrmTenantPlan); D36 column mismatches |
| 11 Frontend | 2 | RED | 0.0 | XSS — {!! $user->name !!} in user/edit.blade.php (FE-SCH-001) |

**Weighted Score:** 15×0.5 + 14×0.0 + 13×0.5 + 11×0.0 + 10×0.5 + 9×0.5 + 7×0.5 + 7×0.5 + 6×0.5 + 4×0.5 + 2×0.5 + 2×0.0 = **37/100**
**P0 cap applies (any P0 → max 40). Final Health = 37/100 (P0 capped).**

---

## Deploy Gate Verdict: NO-GO

| # | Blocker | Code | Severity |
|---|---------|------|----------|
| 1 | `is_super_admin` writable via `$request->all()` + User.$fillable | SEC-SCH-001 | P0 |
| 2 | `EnsureTenantHasModule` absent from all school-setup routes | SEC-SCH-002 | P0 |
| 3 | `sch_entity_group_members` migration missing → SQLSTATE 42S02 | BUG-SCH-012 (prev. registered) | P0 |
| 4 | XSS: `{!! old('name', $user->name) !!}` in user/edit.blade.php | FE-SCH-001 (NEW) | P0 |
| 5 | D36: `sch_org_academic_sessions_jnt.current_flag` plain boolean, no unique constraint | DAT-SCH-001 (NEW) | P0 |
| 6 | 8 live routes map to missing controller methods (fatal 500s) | BUG-SCH-017 through BUG-SCH-022 (prev. registered) | P0 |

---

## P0 Findings

---

```
[SEC-SCH-001] Severity: P0 | is_super_admin + super_admin_flag in User.$fillable — Privilege Escalation
- Location: Modules/SchoolSetup/app/Models/User.php:67-70
- Evidence:
    'user_type',      // line 59
    'password',       // line 67
    'is_super_admin', // line 68
    'super_admin_flag', // line 70
- Why it's a risk: Any authenticated user with school-setup.user.update permission can send a crafted
  PUT request that sets is_super_admin=1. Combined with the app/Providers/AppServiceProvider.php:65-67
  Gate::before() bypass (returns true for is_super_admin), this gives platform-wide super-admin access
  instantly. password is also fillable — a user can change another user's password through the same path.
- Fix: Remove 'is_super_admin', 'super_admin_flag', 'password', 'user_type' from $fillable.
  In UserController::update(), use $request->validated() and only permit the fields explicitly
  allowed by UserRequest. Remove the is_super_admin checkbox from user/edit.blade.php.
- Confidence: High
- Systemic?: Module-local (SchoolSetup owns the User model in its namespace; confirmed live in User.php:68,70)
```

---

```
[SEC-SCH-002] Severity: P0 | EnsureTenantHasModule absent from SchoolSetup RSP middleware
- Location: Modules/SchoolSetup/app/Providers/RouteServiceProvider.php:40-48
- Evidence:
    Route::middleware([
        'web',
        InitializeTenancyByDomain::class,
        PreventAccessFromCentralDomains::class,
        EnsureTenantIsActive::class,   // present
        'auth',
        'verified',
        // EnsureTenantHasModule::class  ← MISSING
    ])
- Why it's a risk: A tenant whose plan does NOT include the SchoolSetup module can access all 56+
  controllers, all employee data, and all RBAC configuration. This is a subscription bypass —
  schools get an entire foundational module without paying for it.
- Fix: Add EnsureTenantHasModule::class to the RSP middleware array (or EnsureTenantHasModule::using('SchoolSetup')).
- Confidence: High
- Systemic?: Platform-wide pattern (modules-map.md: EnsureTenantHasModule usage = 1 across entire tenant.php; all module RSPs are missing it)
```

---

```
[BUG-SCH-012 — PRODUCTION CRASH] Severity: P0 | sch_entity_group_members migration MISSING
- Location: database/migrations/tenant/ — no file creates sch_entity_group_members / sch_entity_groups_members
  Confirmed: ls database/migrations/tenant/ | grep entity_group → only 2026_06_15_145412_create_entity_groups_table.php
  EntityGroupMemberController: Modules/SchoolSetup/app/Http/Controllers/EntityGroupMemberController.php (exists)
  EntityGroupMember model: Modules/SchoolSetup/app/Models/EntityGroupMember.php (exists, $table='sch_entity_group_members')
- Evidence:
    // EntityGroupMember.php
    protected $table = 'sch_entity_group_members'; // no matching migration
- Why it's a risk: Any attempt to add/list/delete entity group members throws
  SQLSTATE[42S02]: Base table or view not found — the table does not exist in tenant DB.
  Entity group feature (notifications, supervision assignments) is silently broken platform-wide.
- Fix: Create a new tenant migration:
  Schema::create('sch_entity_group_members', function (Blueprint $table) {
      $table->id();
      $table->unsignedBigInteger('entity_group_id');
      $table->foreign('entity_group_id')->references('id')->on('sch_entity_groups');
      $table->string('entity_type', 50); // 'employee'|'department'|'section'|etc.
      $table->unsignedBigInteger('entity_id');
      $table->boolean('is_active')->default(true);
      $table->unsignedBigInteger('created_by')->nullable();
      $table->timestamps();
      $table->softDeletes();
  });
- Confidence: High
- Systemic?: Module-local (missing migration file, unique to SchoolSetup)
```

---

```
[FE-SCH-001] Severity: P0 | XSS — {!! $user->name !!} rendered unescaped in user edit form
- Location: Modules/SchoolSetup/resources/views/user/edit.blade.php:38
- Evidence:
    <x-backend.form.input-text type="text" name="name" id="name" label="Name"
        placeholder="Enter Full Name" required="true"
        value="{!! old('name', $user->name) !!}" />
- Why it's a risk: $user->name is user-controlled data emitted into an HTML attribute without escaping.
  A name containing "><script>alert(document.cookie)</script> closes the value attribute and injects
  arbitrary JavaScript into any admin browser viewing the user edit page. Since this is inside the
  school admin panel, it can exfiltrate session cookies or perform CSRF actions on the admin's behalf.
  Note: short_name on the same form uses {{ }} (safe) — inconsistent handling confirms this is an oversight.
- Fix: Replace {!! old('name', $user->name) !!} with {{ old('name', $user->name) }}
  Blade's {{ }} applies htmlspecialchars() automatically.
- Confidence: High
- Systemic?: Module-local; the x-backend.form.input-text Blade component should accept an :value
  binding and escape internally — check if the component propagates raw HTML to its value attribute.
```

---

```
[DAT-SCH-001] Severity: P0 | D36: sch_org_academic_sessions_jnt.current_flag plain boolean, no unique constraint
- Location: database/migrations/tenant/2026_06_15_145404_create_sch_org_academic_sessions_jnt_table.php:31
- Evidence:
    $table->boolean('is_current')->default(false);
    $table->boolean('current_flag')->default(false); // plain boolean, no UNIQUE
    // No $table->unique('current_flag') anywhere in this migration
- Why it's a risk: DDL spec declares current_flag as a GENERATED STORED column with a UNIQUE constraint
  to enforce "exactly one current session per tenant." As a plain writable boolean with no unique
  constraint, multiple sessions can have current_flag = true simultaneously. BR-SCH-009 is violated:
  setting a new current session does NOT atomically unset the previous one at the DB level — the
  application must do it, and there is no transaction-level protection. Race conditions between two
  concurrent HTTP requests can leave two sessions active simultaneously, breaking all downstream
  modules that read sch_org_academic_sessions_jnt for the current session.
- Fix: Create an additive migration:
  (1) Add unique constraint: $table->unique('current_flag', 'uq_org_session_current');
  (2) Ensure setActiveSession() uses a DB::transaction with lockForUpdate() on the current session row
  (3) The DDL pattern should be: current_flag TINYINT(1) NULL UNIQUE (only one non-NULL value allowed)
      update code to set current_flag=1 for new current, current_flag=NULL for old current.
- Confidence: High
- Systemic?: D36 platform pattern (state/decisions.md D36); sch_academic_term.current_flag DOES have
  UNIQUE (correct pattern); only sch_org_academic_sessions_jnt is broken here.
```

---

```
[BUG-SCH-017] Severity: P0 | EmployeeProfileController 5 routed methods missing — fatal 500s
- Location: Modules/SchoolSetup/routes/web.php:117-121 → Modules/SchoolSetup/app/Http/Controllers/EmployeeProfileController.php
- Evidence:
    // routes/web.php:117-121:
    Route::post('/{id}/add-profile', [EmployeeProfileController::class, 'addProfile'])->name('addProfile');
    Route::post('/{id}/add-teacher-profile', [EmployeeProfileController::class, 'addTeacherProfile'])->name('addTeacherProfile');
    Route::post('/{id}/update-documents', [EmployeeProfileController::class, 'updateDocuments'])->name('updateDocuments');
    Route::get('/{id}/generate-qr', [EmployeeProfileController::class, 'generateQrCode'])->name('generateQrCode');
    Route::post('/{id}/toggle-profile-status', [EmployeeProfileController::class, 'toggleProfileStatus'])->name('toggleProfileStatus');
    // grep confirms: zero matches for any of these function names in EmployeeProfileController.php
- Why it's a risk: The 4-step employee onboarding flow (Step 2: addProfile, Step 3: addTeacherProfile)
  is core to employee creation (FR-SCH-11). Every attempt to save an employee profile step throws
  a BadMethodCallException / 500 error. Employee creation is broken for all teaching staff.
- Fix: Implement all 5 methods in EmployeeProfileController. Highest priority: addProfile() and
  addTeacherProfile() (core 4-step onboarding); generateQrCode() (QR card generation for ID badges).
- Confidence: High
- Systemic?: Module-local; not all BUG-SCH-018 through BUG-SCH-022 missing-method findings are
  repeated here to avoid duplication — see those codes.
```

---

## P1 Findings

---

```
[SEC-SCH-019] Severity: P1 | RolePermissionController::index() Gate::authorize commented out
- Location: Modules/SchoolSetup/app/Http/Controllers/RolePermissionController.php:24
- Evidence:
    // Gate::authorize('tenant.role-permission.viewAny');  // commented out line 24
    // Code instead uses Gate::any() with a different permission set
- Why it's a risk: The role + permission management hub (who can do what in the school) is reachable
  by any authenticated user. An attacker who gains any tenant user account can view and potentially
  manipulate the entire RBAC configuration.
- Fix: Uncomment Gate::authorize('tenant.role-permission.viewAny') and remove Gate::any() workaround.
- Confidence: High (previously registered in known-issues.md)
- Systemic?: Module-local
```

---

```
[SEC-SCH-020] Severity: P1 | D30: All 26 FormRequests return bare authorize(){return true;}
- Location: Modules/SchoolSetup/app/Http/Requests/ — all 26 files
  Confirmed: grep output shows every FormRequest has "return true;" as the only authorize() body.
- Evidence (representative):
    // UserRequest.php:50
    public function authorize(): bool { return true; }
    // OrganizationRequest.php:70
    public function authorize(): bool { return true; }
    // TeacherRequest.php:65
    public function authorize(): bool { return true; }
- Why it's a risk: Defense-in-depth collapses to a single layer. Where controller-side Gate::authorize()
  is commented out (SEC-SCH-019) or missing (InfrasetupController), there is zero authorization on
  the mutating endpoint. Several FormRequests protect critical HR data (StoreEmployeeRequest,
  UpdateEmployeeRequest, TeacherRequest) with no resource-level ownership check.
- Fix: Each FormRequest authorize() must call Gate::allows('matching.permission.string').
  Priority: UserRequest, TeacherRequest, EmployeeRequest, RolePermissionRequest.
- Confidence: High
- Systemic?: D30 platform pattern — 26/26 (100%) is above the 437/485 (90%) platform average.
```

---

```
[TEN-SCH-001] Severity: P1 | D41: session('tenant_id') used in 6 locations — wrong tenant on queued/async paths
- Location:
    Modules/SchoolSetup/app/Http/Controllers/EmployeeSeparationController.php:54,210
    Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationController.php:466,953,1028
    Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApprovalController.php:384
- Evidence (representative):
    // EmployeeSeparationController.php:54
    'tenant_id' => session('tenant_id'),
    // EmployeeLeaveApplicationController.php:466
    'tenant_id' => session('tenant_id'),
- Why it's a risk: session('tenant_id') is unreliable outside the HTTP request lifecycle
  (queued jobs, concurrent async requests, tests). Fallback ?? 1 hardcodes tenant 1 and creates
  notification/audit records on the wrong tenant. In synchronous HTTP requests, it may also return
  null if the session hasn't loaded the tenant_id key.
- Fix: Replace all session('tenant_id') ?? 1 with tenant()->id (stancl/tenancy current tenant accessor,
  always correct in tenancy-initialized context). Move notification inserts outside DB::transaction()
  or dispatch as queued jobs with ->afterCommit().
- Confidence: High
- Systemic?: D41 platform pattern (state/decisions.md D41); confirmed in 3 SchoolSetup controllers (6 sites).
```

---

```
[TEN-SCH-002] Severity: P1 | tenancy()->initialize() without tenancy()->end() in console commands
- Location:
    Modules/SchoolSetup/app/Console/Commands/ProcessLeaveAccrual.php:40
    Modules/SchoolSetup/app/Console/Commands/ProcessDailyAttendance.php:46
- Evidence:
    // ProcessLeaveAccrual.php:40
    tenancy()->initialize($tenant);
    // ... remainder of handle() runs in tenant context
    // No matching tenancy()->end() anywhere in the file
- Why it's a risk: When the command exits, the tenancy context is NOT reverted. If multiple commands
  run in the same process (e.g., via Artisan::call() chain), subsequent commands execute in the
  last initialized tenant's DB context, silently processing the wrong tenant's data.
  Also leaves a dangling DB connection to the tenant DB.
- Fix: Wrap the tenant-scoped block in $tenant->run(fn() => ...) which auto-reverts.
  Or add tenancy()->end() in a try-finally block at the end of handle().
- Confidence: High
- Systemic?: Platform pattern (known-issues.md baseline cites SchoolSetup console cmds as P1 context-leak site).
```

---

```
[BUG-SCH-013] Severity: P1 | rand() produces fake student/class statistics in production UserController
- Location: Modules/SchoolSetup/app/Http/Controllers/UserController.php:34-35
- Evidence:
    $totalStudents = rand(1000, 2000);
    $totalClasses  = rand(10, 30);
    // Also: auth check commented out (lines 30-32):
    // if ($request->user()->cannot('school-setup.user.viewAny', User::class)) { return redirect()->back()... }
- Why it's a risk: The user management dashboard shows random fabricated student/class counts on
  every page load. Combined with the commented-out authorization check, any authenticated user
  (including students, if they have a user account) can view the complete user list with RBAC data.
- Fix: Replace rand() with DB::table('std_students')->whereNull('deleted_at')->count() and
  DB::table('sch_classes')->whereNull('deleted_at')->count(). Uncomment the authorization check.
- Confidence: High
- Systemic?: Module-local (debug code left in production)
```

---

```
[DAT-SCH-002] Severity: P1 | D36: sch_employee_leave_balance.available_balance plain decimal — no GENERATED expression
- Location: database/migrations/tenant/2026_06_16_104157_create_sch_employee_leave_balance_table.php:21
- Evidence:
    $table->decimal('available_balance', 5, 2); // plain writable column
    // DDL spec (state/decisions.md D26) declares this as:
    // available_balance DECIMAL(5,2) GENERATED ALWAYS AS (opening_balance + carry_forward - total_used) STORED
- Why it's a risk: D36 failure mode 2. The available balance is a computed value that MUST equal
  opening_balance + carry_forward - total_used. As a plain column, if the application forgets to
  update it on any of the three source columns' mutations, the displayed balance drifts silently
  and employees may see incorrect entitlement figures. ProcessLeaveAccrual increments opening_balance
  via balance->increment('opening_balance') but does NOT update available_balance.
- Fix: Create additive migration: modify column to storedAs('opening_balance + carry_forward - total_used').
  Remove 'available_balance' from EmployeeLeaveBalance $fillable (guard against writes).
  Until migration is applied, add a recompute() method to EmployeeLeaveBalance service that enforces
  the formula after every balance mutation.
- Confidence: High
- Systemic?: D36 platform pattern (state/decisions.md D36); confirmed — 0 storedAs/virtualAs calls in any sch_* migration.
```

---

```
[BUG-SCH-011] Severity: P1 | sch_designations migration missing softDeletes() but Designation model uses SoftDeletes trait
- Location:
    database/migrations/tenant/2026_06_15_145912_create_sch_designations_table.php (no softDeletes call)
    Modules/SchoolSetup/app/Models/Designation.php:7 (use SoftDeletes;)
- Evidence:
    // Designation.php:7
    use Illuminate\Database\Eloquent\SoftDeletes;
    // Migration 2026_06_15_145912: grep for 'softDeletes|deleted_at' → no output
- Why it's a risk: When DesignationController::destroy() calls $designation->delete(), Eloquent
  attempts to UPDATE sch_designations SET deleted_at = NOW() WHERE id = ?. The column does not
  exist → SQLSTATE 42S22: Unknown column 'deleted_at'. Every soft-delete attempt throws a 500 error.
  The designation cannot be retired without a raw SQL workaround.
- Fix: Create additive migration: $table->softDeletes(); on sch_designations.
  Alternatively: if sch_designations is intended as a hard-delete table (like sch_designations was
  designed without soft-deletes), remove SoftDeletes from Designation model.
  Recommended: add softDeletes() to the migration (convention-compliant with all other SCH tables).
- Confidence: High
- Systemic?: D38 platform pattern (model uses SoftDeletes, table lacks deleted_at); sibling to MIG-BIL-001.
```

---

```
[BUG-SCH-023] Severity: P1 | ClassSubjectManagementController::store()/update()/destroy() empty bodies
- Location: Modules/SchoolSetup/app/Http/Controllers/ClassSubjectManagementController.php:29,52,59
- Evidence:
    public function store(Request $request)
    {
    }   // completely empty
    public function update(Request $request, $id)
    {
    }   // completely empty
    public function destroy($id)
    {
    }   // completely empty
- Why it's a risk: The class-subject mapping resource routes (POST/PUT/DELETE) are live and reachable
  by any authenticated user (no Gate::authorize in any method). All state-changing operations
  silently do nothing — data manipulation through the UI is a no-op, and users receive no error.
- Fix: Implement the three methods. Use DB::transaction(); validate with a FormRequest;
  add Gate::authorize('tenant.class-subject-management.create/update/delete').
- Confidence: High
- Systemic?: Module-local
```

---

```
[ORM-SCH-001] Severity: P1 | EmployeeBankDetail — account_number and ifsc_code stored as plaintext
- Location: Modules/SchoolSetup/app/Models/EmployeeBankDetail.php:17-34
- Evidence:
    protected $fillable = [
        'account_number',  // plaintext VARCHAR — no encrypted cast
        'ifsc_code',       // plaintext VARCHAR — no encrypted cast
        'iban',            // plaintext VARCHAR — no encrypted cast
        ...
    ];
    protected $casts = [
        'is_primary_for_salary' => 'boolean',
        'is_active' => 'boolean',
        'verified_at' => 'datetime',
        // account_number and ifsc_code NOT in $casts
    ];
- Why it's a risk: Indian bank account numbers and IFSC codes are classified as sensitive personal
  financial information (PII). Stored in plaintext in the tenant DB: any DB admin, BI tool, or
  SQL injection vulnerability can trivially read all employee banking data.
  BR-SCH-039 explicitly requires encryption: "Employee bank account details must be stored with
  encryption — they are classified as sensitive personal information."
- Fix: Add 'account_number' => 'encrypted', 'ifsc_code' => 'encrypted', 'iban' => 'encrypted'
  to $casts in EmployeeBankDetail.php. Laravel's encrypted cast uses the app key for AES-256-GCM
  automatically. Run a one-time data migration to encrypt existing plaintext values.
- Confidence: High
- Systemic?: Known pattern in VND module (lessons: encrypted cast applied); VND module enforces it; SCH does not.
```

---

```
[SEC-SCH-018] Severity: P1 | EmployeeReportController::index() has no Gate::authorize
- Location: Modules/SchoolSetup/app/Http/Controllers/EmployeeReportController.php:28
- Evidence (known-issues.md SEC-SCH-018):
    public function index(Request $request) {
        // No Gate::authorize() call
        // Loads all employee attendance, leave balances, separation data, HR analytics
        'roles' => Role::all(),   // EmployeeReportController.php:70
    }
- Why it's a risk: The HR analytics report page (attendance, leave balance, separation records,
  teacher capabilities) is accessible to any authenticated user — teachers, students' parents (PPT),
  or any account without the HR Officer role. Exposes confidential HR data across all employees.
- Fix: Add Gate::authorize('tenant.employee-report.viewAny'); as the first statement in index().
- Confidence: High (previously registered in known-issues.md)
- Systemic?: Module-local
```

---

```
[PERF-SCH-003] Severity: P1 | Role::all() called in 15+ request paths without caching
- Location: 15 controllers in Modules/SchoolSetup/app/Http/Controllers/
  Representative: UserController.php:37,51; EmployeeProfileController.php:312,718;
  LeaveApprovalPolicyController.php:40,84; LeaveApprovalLevelApproverController.php:43,103;
  HolidayController.php:27,74; EmployeeReportController.php:70; EmployeeLifecycleController.php:30;
  StaffLeaveConfigController.php:47,145; PermissionSyncController.php:57; EmployeeRoleHistoryController.php:26,88
- Evidence:
    $roles = Role::all();   // unbounded, no pagination, no cache — appears 15+ times
    Department::all();      // EmployeeProfileController.php:169; DepartmentController.php:182
    Subject::all();         // TeacherController.php:278
- Why it's a risk: Role::all() on the Spatie roles table (sys_roles) returns all roles for every
  page load. For schools with 20–50 roles, this adds an uncached full-table scan to every HR
  form render. At 56 controllers × multiple index/create/edit methods, this compounds on high-traffic
  instances. Subject::all() on large schools (100+ subjects) is similarly unbounded.
- Fix: Cache role/department lookups: Cache::remember('school_roles_' . tenant('id'), 3600, fn() => Role::all()).
  Invalidate the cache in RolePermissionController on role CRUD. For Subject::all() in TeacherController,
  constrain to the relevant classes or paginate.
- Confidence: High
- Systemic?: Platform pattern (PERF-SCH-001 N+1 ClassGroupController, PERF-SCH-002 SchoolClassController 9 queries).
```

---

```
[MIG-SCH-001] Severity: P1 | 11 ENUM columns across SchoolSetup migrations — D29 violation
- Location: database/migrations/tenant/
    2026_06_15_150600_create_sch_employees_table.php: emp_id_card_type, gender, marital_status,
      blood_group, employment_status (8-value FSM!), employment_type (6 values)
    2026_06_16_104147_create_sch_holidays_table.php: holiday_type (8 values)
    2026_06_16_104159_create_sch_staff_leave_config_table.php: applies_to_employment_type, accrual_method
    2026_06_16_104201_create_sch_employee_leave_applications_table.php: half_day_slot, status (9-value FSM!)
- Evidence (representative):
    $table->enum('employment_status', ['Active', 'Notice Period', 'On Leave', 'On Sabbatical',
        'Resigned', 'Retired', 'Suspended', 'Terminated'])->default('Active');
    $table->enum('status', ['Approved', 'Cancelled', 'Doc Requested', 'Draft', 'Escalated',
        'Info Requested', 'Rejected', 'Submitted', 'Under Review'])->default('Draft');
- Why it's a risk: Any extension of employment_status (e.g. 'Maternity Leave', 'Deputation') or
  leave application status requires a ALTER TABLE migration against EVERY tenant DB —
  a high-risk DDL operation at scale (100+ tenant databases). D29 decision mandates sys_dropdown_table FK.
  The 9-value leave status FSM is especially risky — HR business rules evolve frequently.
- Fix: Create sys_dropdown_needs entries and migrate to INT UNSIGNED FK → sys_dropdowns for each ENUM.
  Priority: employment_status (FSM evolution risk), status (leave application FSM, 9 values).
  For truly stable binary values (half_day_slot: Morning/Afternoon), TINYINT(1) boolean is acceptable.
- Confidence: High
- Systemic?: D29 platform pattern — sch_ has 22 ->enum() calls (platform baseline); this confirms 11 of those.
```

---

## P2 Findings

---

```
[GAP-SCH-18] Severity: P2 | 5 Policy files unregistered in SchoolSetupServiceProvider
- Location: Modules/SchoolSetup/app/Providers/SchoolSetupServiceProvider.php::registerPolicies()
  Unregistered: InfrasetupPolicy, ClassSubjectManagementPolicy, SubjectClassPolicy,
                SchoolAcademicTermPolicy, SchoolSetupPolicy
- Evidence: 44 policy files in Policies/; 38 registered in ServiceProvider → 6 unregistered gap
  (5 confirmed via module knowledge file GAP-SCH-18; 1 may be intentionally unregistered).
- Why it's a risk: Controllers that call Gate::authorize('tenant.infrasetup.viewAny') will either
  silently pass (no policy = allow by default in Gate::define-less mode) or silently deny,
  depending on Gate fallback behavior. InfrasetupController has NO Gate calls at all (Layer 5.1 hit),
  so the unregistered InfrasetupPolicy is irrelevant there — but for controllers that DO call Gate::authorize,
  the missing registration causes unpredictable behavior.
- Fix: Add Gate::policy() entries for all 5 missing policies in registerPolicies(). Also add
  Gate::authorize() calls to InfrasetupController (all methods) and ClassSubjectManagementController.
- Confidence: High
- Systemic?: Module-local
```

---

```
[DDL-SCH-01] Severity: P2 | Cross-DB foreign keys in sch_* migrations — FK integrity not enforced
- Location:
    database/migrations/tenant/2026_06_15_145404_create_sch_org_academic_sessions_jnt_table.php:21
    database/migrations/tenant/2026_06_16_152548_create_sch_organizations_table.php:51
    database/migrations/tenant/2026_06_16_152610_create_sch_board_organization_jnt_table.php (glb_boards)
- Evidence:
    $table->foreign('academic_session_id', 'fk_org_acad_session')
          ->references('id')->on($globalDb . '.glb_academic_sessions')
          ->restrictOnDelete();
    $table->foreign('city_id', 'fk_organizations_cityId')
          ->references('id')->on($globalDb . '.glb_cities');
- Why it's a risk: MySQL InnoDB does NOT enforce foreign key constraints that cross databases.
  The FK syntax is accepted but the constraint is silently ignored at the storage engine level.
  This means orphan rows (academic_session_id referencing a deleted global session) are NOT prevented.
  Additionally, DB::connection('global_master_mysql') is used at migration creation time to get
  the database name — if the global_master connection is unavailable during tenants:migrate, the
  migration throws.
- Fix: Remove the cross-DB FK constraint declarations; add an application-layer validation in
  OrganizationAcademicSessionController that the academic_session_id exists in glb_academic_sessions.
  Add index-only on the FK column for query performance.
- Confidence: High
- Systemic?: Platform-wide pattern (known-issues.md baseline: "52 tenant FKs → sys_dropdowns cross-DB")
```

---

```
[ARCH-SCH-01] Severity: P2 | 3 misplaced models + 2 misplaced FormRequests in SchoolSetup module
- Location:
    Modules/SchoolSetup/app/Models/QuestionType.php → should be QuestionBank module
    Modules/SchoolSetup/app/Models/PrmTenantPlan.php → should be Prime module
    Modules/SchoolSetup/app/Models/PrmTenantPlanRate.php → should be Prime/Billing module
    Modules/SchoolSetup/app/Http/Requests/LessonRequest.php → should be Syllabus module
    Modules/SchoolSetup/app/Http/Requests/StudentRequest.php → should be StudentProfile module
- Why it's a risk: SchoolSetup's autoloader bootstraps models that belong to other modules.
  Import coupling: if QuestionBank changes its QuestionType model signature, SchoolSetup breaks.
  If SchoolSetup is ever disabled, QuestionBank loses its QuestionType model. PSR-4 namespace
  violations make static analysis (Larastan) misleading.
- Fix: Move each model/FormRequest to its correct module directory. Update all use statements
  and composer.json autoload entries accordingly.
- Confidence: High
- Systemic?: Module-local (ARCH-SCH-27/-28 in module knowledge)
```

---

```
[BUG-SCH-014] Severity: P2 | usersByRole() query does not filter by role
- Location: Modules/SchoolSetup/app/Http/Controllers/UserController.php (usersByRole method)
- Evidence (known-issues.md BUG-SCH-014): The $role parameter is accepted but not applied —
  returns full unfiltered user list regardless of which role was requested.
- Why it's a risk: The role-filtered user view on the SchoolSetup dashboard shows all users
  regardless of the selected role. Not a security issue per se (auth is present on the route)
  but a data accuracy defect — HR officers filtering by 'Teacher' see all users including students.
- Fix: Apply ->whereHas('roles', fn($q) => $q->where('name', $role)) to the user query.
- Confidence: High (previously registered)
- Systemic?: Module-local
```

---

```
[PROD-SCH-01] Severity: P2 | Dead/backup files in production codebase
- Location:
    Modules/SchoolSetup/app/Http/Controllers/competency.blade.php — Blade file misplaced in Controllers/
    Modules/SchoolSetup/app/Http/Requests/RoomRequest21_Nov.php — backup FormRequest
    Modules/SchoolSetup/resources/views/student_Backup_04_12_2025/ — backup view folder
- Why it's a risk: Backup files indicate manual file copying rather than version control;
  competency.blade.php in Controllers/ will confuse any future module:make-controller scaffolding;
  backup views may contain outdated/vulnerable HTML not covered by security reviews.
- Fix: Delete all three. Ensure git history serves as the backup, not checked-in files.
- Confidence: High
- Systemic?: Module-local (PROD-SCH-26 in module knowledge)
```

---

## P3 Findings

---

```
[GAP-SCH-32] Severity: P3 | Zero test coverage across 56+ controllers
- Location: Modules/SchoolSetup/tests/ — empty
- Evidence: modules-map.md: Tests = 0 for SchoolSetup; find Modules/SchoolSetup/tests -name '*.php' → no output
- Why it's a risk: The is_super_admin escalation, RolePermission destroy bug, and entity_group_members
  crash have all survived in production code with no automated regression detection.
  SchoolSetup is the most widely consumed module — a breaking change here breaks every other module.
- Fix: Write Pest feature tests in priority order per GAP-SCH-32 in module knowledge:
  1. is_super_admin escalation test (SEC)
  2. role destroy test (RBAC)
  3. EnsureTenantHasModule gate test (SEC)
  4. sch_entity_group_members table-exists test (migration smoke)
  5. Employee bank details NOT returned in plaintext (ORM)
- Confidence: High
- Systemic?: Module-local (0 tests out of 56 controllers; same pattern in Transport, HPC — platform-wide 0-test issue)
```

---

```
[GAP-SCH-33] Severity: P3 | No caching for master data read by every tenant module
- Location: sch_classes, sch_sections, sch_subjects, sch_employees — read on nearly every page
- Why it's a risk: Classes, sections, and subjects are loaded with separate DB queries on every
  form render across SmartTimetable, Syllabus, LmsExam, LmsHomework, LmsQuiz, LmsQuests,
  StudentProfile, StudentFee, Hpc. A 300-student school with 30 class-sections fires ~15 identical
  queries to sch_class_section_jnt per page load across all modules.
- Fix: Add Cache::remember('sch_classes_' . tenant('id'), 1800, fn() => SchoolClass::active()->get()).
  Tag-based invalidation: Cache::tags(['sch_master_' . tenant('id')])->flush() on any sch_classes
  mutation. Do NOT cache employee data (changes too frequently).
- Confidence: Medium (risk level depends on tenant size and page load patterns)
- Systemic?: Module-local but platform-wide impact
```

---

## STEP 1 Reading-Discipline Output — Three-Way Reconcile

| Table | DDL Spec | Migration | Model | Verdict |
|-------|----------|-----------|-------|---------|
| `sch_org_academic_sessions_jnt.current_flag` | GENERATED STORED + UNIQUE (D26/D36) | Plain `boolean()->default(false)`, NO unique | N/A | DEGRADED — DAT-SCH-001 (P0) |
| `sch_employee_leave_balance.available_balance` | GENERATED AS `opening_balance + carry_forward - total_used` (D26) | Plain `decimal(5,2)` | `decimal` type in fillable | DEGRADED — DAT-SCH-002 (P1) |
| `sch_employees_profile.active_flag` | GENERATED STORED with UNIQUE (D33) | Plain `boolean()->nullable()` + UNIQUE on (employee_id, role_id, active_flag) | Not in fillable | PARTIALLY OK — nullable+unique pattern works; write-protection missing from model |
| `sch_academic_term.current_flag` | GENERATED STORED + UNIQUE (D35) | Plain `boolean()->nullable()` + UNIQUE on column alone | N/A | PARTIALLY OK — nullable+unique correct; not GENERATED but functionally equivalent if app manages null/1 correctly |
| `sch_entity_group_members` | EXISTS in DDL (sch_entity_groups_members) | NO create migration found | `EntityGroupMember` model ($table='sch_entity_group_members') | MISSING — BUG-SCH-012 (P0) |
| `sch_designations.deleted_at` | Expected per D8 (soft deletes everywhere) | NOT present (no softDeletes() call in migration) | `Designation::class` uses SoftDeletes trait | MISMATCH — BUG-SCH-011 (P1) |
| `sch_employee_bank_details.account_number` | PII — should be encrypted (D25/BR-SCH-039) | Plain VARCHAR | Plain string, no encrypted cast | MISSING — ORM-SCH-001 (P1) |

**Snapshot correction:** Module knowledge (SCH_SchoolSetup.md v1.0) says `sch_entity_group_members` migration is a "P1 gap" — auditor upgrades to **P0** because the migration is confirmed missing and any entity-group-member operation will throw SQLSTATE 42S02 (production crash on first use). The knowledge file was written by the Business Analyst who cannot assess production crash risk; the Technical Auditor classifies this as P0.

---

## FRD Gap Summary (Mode B)

| REQ-ID | Title | DDL | Code | Tests | Gap |
|--------|-------|-----|------|-------|-----|
| REQ-SCH-001 | Organization Profile CRUD | OK | PARTIAL | MISSING | $request->all() mass-assignment (BUG-SCH-04/05); no audit trail verify |
| REQ-SCH-002 | Academic Session Management | PARTIAL | PARTIAL | MISSING | current_flag no unique (DAT-SCH-001); standard CRUD stubs empty (BUG-SCH-024 sub) |
| REQ-SCH-003 | Academic Term Management | OK | PARTIAL | MISSING | No dedicated AcademicTermController found (GAP-SCH-34) |
| REQ-SCH-004 | Holiday Calendar | OK | OK | MISSING | — |
| REQ-SCH-005 | Grade (Class) Management | OK | OK | MISSING | — |
| REQ-SCH-006 | Section Management | OK | PARTIAL | MISSING | BUG-SCH-001 concat crash (index) |
| REQ-SCH-007 | Class-Section Configuration | OK | OK | MISSING | — |
| REQ-SCH-008 | Subject Management | OK | OK | MISSING | — |
| REQ-SCH-009 | Subject Groups + Mapping | OK | PARTIAL | MISSING | ClassSubjectManagementController empty (BUG-SCH-023) |
| REQ-SCH-010 | Infrastructure (Rooms/Buildings) | OK | PARTIAL | MISSING | InfrasetupController no auth (SEC-SCH-009-017 group) |
| REQ-SCH-011 | Employee Management | OK | PARTIAL | MISSING | 5 routed methods missing in EmployeeProfileController (BUG-SCH-017) — employee onboarding broken |
| REQ-SCH-012 | Teacher Profiles + Capabilities | OK | OK | MISSING | — |
| REQ-SCH-013 | User Account Management | OK | PARTIAL | MISSING | is_super_admin P0; rand() fake data; usersByRole broken |
| REQ-SCH-014 | Role + Permission Management | OK | PARTIAL | MISSING | destroy() bug (save vs delete); index() auth commented out |
| REQ-SCH-015 | HR Config Masters | OK | PARTIAL | MISSING | DepartmentPolicy + DesignationPolicy missing |
| REQ-SCH-016 | Entity Groups | PARTIAL | PARTIAL | MISSING | Members table MISSING migration (P0 crash) |
| REQ-SCH-017 | Employee Leave Management | OK | OK | MISSING | available_balance not GENERATED (DAT-SCH-002) |
| REQ-SCH-018 | Employee Attendance | OK | PARTIAL | MISSING | No tenants:run wrapping for console commands |
| REQ-SCH-019 | Employee Reports | OK | PARTIAL | MISSING | No authorization on index() (SEC-SCH-018) |
| REQ-SCH-020 | System Dropdowns | OK | OK | MISSING | — |
| REQ-SCH-021 | School Config (sch_config) | OK | OK | MISSING | — |
| REQ-SCH-022 | Permission Sync Utility | OK | PARTIAL | MISSING | No Gate::authorize on sync() (SEC-SCH-006) |
| REQ-SCH-023 | RBAC Configuration | OK | PARTIAL | MISSING | UserRolePrmController index no auth |
| REQ-SCH-024 | Department + Designation | OK | PARTIAL | MISSING | No policies registered; wrong permission prefix; sch_designations no softDeletes |
| REQ-SCH-025 | Employee Lifecycle | OK | PARTIAL | MISSING | Promotions/transfers unclear; assignSubjects() missing |
| REQ-SCH-026 | Shift Management | OK | OK | MISSING | — |

**Summary:** 26 REQs — 7 GREEN, 18 PARTIAL (code exists but has bugs/gaps), 1 RED (entity_group_members migration missing), 26 MISSING tests.

---

## Business-Rule Enforcement (Mode C)

| BR-ID | Rule | Type | Location | Status | Gap |
|-------|------|------|----------|--------|-----|
| BR-SCH-001 | One org profile per tenant | Validation | flg_single_record UNIQUE in migration | ENFORCED | — |
| BR-SCH-002 | No unverified fields persisted | Validation | OrganizationController::store()/update() | MISSING | $request->all() used — D25 mass-assignment (BUG-SCH-04) |
| BR-SCH-007 | Org group code unique | Validation | OrganizationGroupRequest rules | ENFORCED | — |
| BR-SCH-009 | One current session at a time | Concurrency | sch_org_academic_sessions_jnt migration | MISSING | current_flag plain boolean, no UNIQUE — two rows can both be current (DAT-SCH-001) |
| BR-SCH-013 | One current term per session | Concurrency | sch_academic_term migration | PARTIAL | UNIQUE on current_flag exists; plain boolean (not GENERATED); app must set NULL correctly |
| BR-SCH-024 | Class teacher: one section per session | Validation | SubjectClassMappingController | MISSING | No unique constraint enforcement in migration or controller |
| BR-SCH-025 | Subject codes unique | Validation | sch_subjects migration UNIQUE on code | ENFORCED | — |
| BR-SCH-031 | Room count auto-maintained | Calculation | RoomTypeController::updateRoomTypeCounts() | PARTIAL | Called manually (GET route), not triggered on room create/delete |
| BR-SCH-036 | Employee code unique | Validation | sch_employees migration UNIQUE on emp_code | ENFORCED | — |
| BR-SCH-037 | Employee must link to user account | Workflow | EmployeeProfileController 4-step flow | PARTIAL | addProfile() method missing (BUG-SCH-017) — step 2 crashes |
| BR-SCH-039 | Bank details encrypted | Security | EmployeeBankDetail model | MISSING | account_number and ifsc_code stored plaintext (ORM-SCH-001) |
| BR-SCH-040 | Employee docs visible to HR only | Permission | EmployeeProfileController | PARTIAL | updateDocuments() missing; doc controller has no Gate::authorize on all methods |

**BR Enforcement Summary:** 4 ENFORCED, 4 PARTIAL, 4 MISSING out of 12 sampled critical BRs.

---

## Systemic-Pattern Scorecard (Mode D — scoped to SchoolSetup)

| Pattern | Present in SCH? | Count / Detail | vs Platform Baseline |
|---------|----------------|----------------|---------------------|
| D30: FormRequest authorize() = true | YES | 26/26 (100%) | Above platform avg (90%). Worse than norm. |
| D25: $request->all() into Model::create/update | YES | 4 confirmed sites (OrganizationController ×2, OrganizationGroupController ×2) | Platform baseline: 24 sites total. SCH contributes 4/24 (17%). |
| D29: ->enum() in tenant migrations | YES | 11 ENUM columns across 4 migration files | sch_ baseline: 22 -> enum() calls; 11 confirmed here. |
| D36: GENERATED column degraded to plain | YES | 2 confirmed (current_flag no unique, available_balance plain decimal) | Platform-wide (every SCH migration: 0 storedAs/virtualAs calls). |
| D17: $fillable references missing column | YES (partial) | is_super_admin in User.$fillable IS in DB (sys_users); but super_admin_flag in DB is storedAs (D36/PRM-D-002) — User.$fillable 'super_admin_flag' violates PRM-D-002 | Refer to PRM-D-002: super_admin_flag SHOULD NOT be in $fillable. |
| D41: session('tenant_id') unreliable | YES | 6 confirmed sites across 3 controllers | SCH is the heaviest D41 offender found to date. |
| Layer 6.2: initialize() without end() | YES | ProcessLeaveAccrual.php:40, ProcessDailyAttendance.php:46 | Platform baseline cites SCH console commands as a P1 site. |
| D24: Permission prefix chaos | PARTIAL | 38 registered policies use 'tenant.*' prefix (correct); DepartmentController uses 'prime.department.*' (wrong prefix — 1 confirmed typo) | Module-local prefix inconsistency. |
| Layer 2.5: Cross-DB / missing FK target | YES | sch_org_academic_sessions_jnt → glb_academic_sessions (cross-DB); sch_organizations → glb_cities (cross-DB); sch_board_organization_jnt → glb_boards (cross-DB). FK constraints silently not enforced. | Platform baseline 52 cross-DB FK sites; SCH contributes ~3. |
| D38: SoftDeletes/timestamps declared, table lacks column | YES | Designation model uses SoftDeletes; sch_designations no deleted_at column | Module-local (sibling to MIG-BIL-001). |
| TEN module middleware | MISSING | EnsureTenantHasModule absent from RSP | modules-map.md: EnsureTenantHasModule usage = 1 platform-wide; SCH is not that 1. |
| SEC-RTG-001: Seeder routes outside auth | YES (platform) | seeder/school-setup route at routes/tenant.php:330 outside auth | Platform-wide P0; not SCH-specific. |

---

## vs Platform Baseline

| Metric | Platform Baseline | SchoolSetup | Delta |
|--------|-------------------|-------------|-------|
| FormRequests returning bare true | 90% (437/485) | 100% (26/26) | WORSE than baseline |
| $request->all() sites | 24 platform | 4 (OrganizationController ×2, OrganizationGroupController ×2) | 17% of platform total |
| Enum in migrations | sch baseline 22 | 11 confirmed | Typical (in the known-worst tier) |
| Eager-load ratio (with:get) | Hpc 0.04 worst, SCH ~1.06 (baseline) | Good (confirmed with() calls in EmployeeProfileController) | BETTER than most modules |
| God controllers >1000 lines | StudentController 4222, LmsExam 3767 | EmployeeProfileController 1595 | Moderate — below worst-case |
| Tests | 80 total module-level | 0 | Zero — same as 80%+ of modules |
| Jobs without tenancy | Multiple platform | 0 jobs exist | N/A (no jobs) |
| $fillable privilege fields | User.php only (platform baseline) | Confirmed: is_super_admin, super_admin_flag, password, user_type | Only confirmed P0 on this platform |
| Cross-DB FKs | 52 sites | ~3 confirmed | Moderate (not heaviest) |

**Overall platform standing:** SchoolSetup is a **above-average-risk** module. Its risk profile is elevated not because it is worse than typical (most metrics are typical) but because it is the foundational module consumed by 13+ downstream modules — every defect here has platform-wide blast radius.

---

## Recommended Fix Order

| Priority | Item | Fix | Est. Effort |
|----------|------|-----|-------------|
| 1 | SEC-SCH-001: Remove is_super_admin from User.$fillable and UserController | Remove 4 fields from $fillable; use $request->validated(); remove checkbox from edit.blade.php | 0.5d |
| 2 | BUG-SCH-012: Create sch_entity_group_members migration | Create + run tenant migration; add SoftDeletes, FK, audit columns | 0.5d |
| 3 | FE-SCH-001: Fix XSS in user/edit.blade.php | Change {!! !!} to {{ }} on $user->name | 15min |
| 4 | DAT-SCH-001: Add UNIQUE to sch_org_academic_sessions_jnt.current_flag | Additive migration; fix setActiveSession() to use transaction + lockForUpdate + set old = NULL | 1d |
| 5 | SEC-SCH-002: Add EnsureTenantHasModule to SchoolSetup RSP | 1-line change to RouteServiceProvider.php | 15min |
| 6 | BUG-SCH-017: Implement 5 missing EmployeeProfileController methods | addProfile, addTeacherProfile, updateDocuments, generateQrCode, toggleProfileStatus | 3d |
| 7 | BUG-SCH-011: Add softDeletes() to sch_designations migration | Additive migration; verify Designation model cascade behavior | 0.5d |
| 8 | TEN-SCH-001: Replace session('tenant_id') with tenant()->id in 3 controllers (6 sites) | Search-replace + test | 0.5d |
| 9 | ORM-SCH-001: Add encrypted cast to EmployeeBankDetail | Add to $casts; data migration for existing rows | 1d |
| 10 | DAT-SCH-002: Fix sch_employee_leave_balance.available_balance | Additive migration to storedAs(); remove from $fillable | 1d |
| 11 | BUG-SCH-023: Implement ClassSubjectManagementController methods | With Gate::authorize + FormRequest | 1d |
| 12 | TEN-SCH-002: Fix tenancy context in console commands | Add tenancy()->end() in finally block or use $tenant->run() | 0.5d |
| 13 | SEC-SCH-018/019: Add Gate::authorize to EmployeeReportController, uncomment RolePermissionController | One-line fixes per controller | 0.5d |
| 14 | SEC-SCH-020 + D30: Implement real authorize() in all 26 FormRequests | Gate::allows() per FormRequest (priority: UserRequest, TeacherRequest, EmployeeRequest) | 3d |
| 15 | BUG-SCH-013: Replace rand() with real counts; uncomment auth in UserController | DB::table() count queries | 0.5d |
| 16 | GAP-SCH-32: Write Pest tests — P0 flows first | See test priority list | 5d |
| 17 | MIG-SCH-001: Convert 11 ENUMs to sys_dropdown FK (D29) | Per-column additive migrations + seeder for each | 3d |
| 18 | PERF-SCH-003: Cache Role::all() and Department::all() | Cache::remember with tag-based invalidation | 1d |
| 19 | GAP-SCH-18: Register 5 unregistered policies | Add Gate::policy() calls in registerPolicies() | 0.5d |
| 20 | DDL-SCH-01: Remove cross-DB FK declarations; add application-layer validation | Migration + controller validation | 1d |

**Estimated total to clear all P0:** ~7d
**Estimated total to clear P0+P1:** ~20d
**Estimated total to reach deploy-ready (P0+P1+critical P2):** ~28d

---

## Knowledge File Updates Required

1. **SCH_SchoolSetup.md** — update:
   - P0 issue DAT-SCH-001 (current_flag unique constraint missing — upgrade from P1 to P0)
   - New issues: FE-SCH-001 (XSS), TEN-SCH-001 (D41 session), TEN-SCH-002 (tenancy end missing), DAT-SCH-002, ORM-SCH-001, PERF-SCH-003, MIG-SCH-001
   - Lessons Learned block: `[2026-06-30 | Technical Auditor] XSS in user/edit.blade.php; D41 pattern in 3 controllers (6 sites); sch_entity_group_members confirmed missing migration P0 crash; super_admin_flag in $fillable violates PRM-D-002; Role::all() unbounded in 15+ paths.`
   - Version: 1.2

2. **known-issues.md** — append new codes:
   - FE-SCH-001: XSS user/edit.blade.php
   - TEN-SCH-001: D41 session('tenant_id') in 6 locations
   - TEN-SCH-002: ProcessLeaveAccrual/ProcessDailyAttendance initialize() without end()
   - DAT-SCH-001: sch_org_academic_sessions_jnt.current_flag no unique (D36 failure mode 1)
   - DAT-SCH-002: sch_employee_leave_balance.available_balance plain column (D36 failure mode 2)
   - ORM-SCH-001: EmployeeBankDetail PII plaintext
   - PERF-SCH-003: Role::all() unbounded 15+ request paths
   - MIG-SCH-001: sch_designations missing softDeletes vs model using SoftDeletes (D38)

3. **state/decisions.md** — no new D-number warranted (all findings fall under existing D17, D25, D29, D30, D36, D38, D41 patterns).

---

## Deliverable F — Next Steps

```
Audit complete — Health 37/100 (capped: P0 present). DEPLOY: NO-GO.

1. Fix P0 issues (SEC-SCH-001, BUG-SCH-012, FE-SCH-001, DAT-SCH-001, SEC-SCH-002, BUG-SCH-017)
   → act as Developer (priority order above, items 1-6)
2. Fix missing migration + schema gaps → act as DB Architect
3. Completeness score → act as Status_Analyzer
4. Test coverage plan → act as Testing Architect
5. Platform sweep for D41 session('tenant_id') across all modules → re-run Mode D
```
