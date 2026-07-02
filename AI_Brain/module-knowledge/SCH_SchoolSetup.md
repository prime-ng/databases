# Module Knowledge — SCH: SchoolSetup
**Seeded:** 2026-06-30 | **Agent:** Business Analyst
**Version:** 1.0

---

## Module Facts

| Attribute | Value |
|-----------|-------|
| Module Name | SchoolSetup |
| Module Code | SCH |
| Table Prefix | `sch_*` (primary) + `sys_dropdowns` / `sys_dropdown_needs` / `sys_dropdown_need_dropdowns_jnt` (cross-cutting) |
| Laravel Module Path | `Modules/SchoolSetup/` |
| Namespace | `Modules\SchoolSetup` |
| DB Layer | **Tenant** — tenant_db (no `tenant_id` column; isolated by DB connection) |
| Domain Scope | Foundation module — all tenant users; School Admin, HR Officer, IT Admin, Principal, Teacher |
| V2 Requirement | Exists: `SCH_SchoolSetup_Requirement.md` (2026-03-26); ~55% claimed at time of writing |
| V1 Screen Specs | 46 files across 4 sub-folders: `ClassSetup_v2/` (12), `CoreSetup_v2/` (3), `EmployeeSetup_v2/` (27), `InfraSetup_v2/` (4) |
| RBS Reference | A1–A9 (Tenant & System Mgmt) + H1–H7 (Academics) |
| Role in Platform | **Provider** — provides `sch_*` entities to 13+ downstream modules; must be fully configured before any other module functions |
| Related Knowledge | `SCO_SchoolSetup_CoreSetup.md` — dedicated sub-module knowledge for the CoreSetup sub-domain (organization, sessions, calendar, config) |

---

## Sub-Module Architecture

SchoolSetup is the largest module on the platform. It is organized into 4 functional sub-domains, each with its own V1 screen-spec folder:

| Sub-Domain | V1 Folder | Tables | Domain |
|-----------|-----------|--------|--------|
| **SCO — CoreSetup** | `CoreSetup_v2/` | `sch_organizations`, `sch_org_academic_sessions_jnt`, `sch_board_organization_jnt`, `sch_annual_leave_sessions`, `sch_holidays`, `sch_employee_shifts`, `sch_departments`, `sch_designations`, `sch_entity_groups`, `sch_staff_attendance_types`, `sch_staff_leave_types`, `sch_staff_leave_config`, `sch_leave_approval_policies*`, `sch_configs`, `sys_dropdowns*` | Organization profile, academic sessions, holiday calendar, employee shifts, leave config masters, sys dropdowns |
| **SCC — ClassSetup** | `ClassSetup_v2/` | `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_subjects`, `sch_subject_types`, `sch_study_formats`, `sch_subject_study_format_jnt`, `sch_subject_study_format_options`, `sch_class_groups_jnt`, `sch_class_group_subject_options_jnt`, `sch_subject_groups`, `sch_subject_group_subject_jnt` | Classes, sections, subjects, study formats, class-subject mappings |
| **SCE — EmployeeSetup** | `EmployeeSetup_v2/` | `sch_employees`, `sch_employees_profile`, `sch_teacher_profile`, `sch_teacher_capabilities`, `sch_employee_addresses`, `sch_employee_bank_details`, `sch_employee_documents`, `sch_employee_emergency_contacts`, `sch_employee_role_history`, `sch_employee_separations`, `sch_employee_shift_assignments`, `sch_employee_leave_balance`, `sch_employee_leave_applications`, `sch_leave_approval_policy_levels`, `sch_leave_approval_level_approvers`, `sch_employee_leave_application_docs`, `sch_employee_leave_application_remarks`, `sch_employee_leave_approvals`, `sch_employee_attendance`, `sch_employee_attendance_punches`, `sch_employee_attendance_corrections` | Employee profiles, teacher profiles + capabilities, leave management, attendance tracking |
| **SCI — InfraSetup** | `InfraSetup_v2/` | `sch_buildings`, `sch_rooms_type`, `sch_rooms` | Physical infrastructure |
| **RBAC** | (part of CoreSetup_v2) | `sys_users`, `sys_roles`, `sys_permissions` | User accounts, roles, permissions |

> **Note:** SCO sub-domain has a dedicated knowledge file: `SCO_SchoolSetup_CoreSetup.md`. Consult it for deep CoreSetup gaps, DDL details, and the SCO FRD (generated 2026-06-30).

---

## Verified File Counts (from `find Modules/SchoolSetup -type f` — 2026-06-30)

| Component | Actual | V2 Said (Mar 2026) | Notes |
|-----------|--------|--------------------|-------|
| Controllers (total files) | 60 | 36 active + 5 backup/dead | Includes 2 Mobile/, 1 Api/, 1 misplaced `.blade.php` |
| Controllers (active, non-mobile, non-API) | 56 | 36 | Full list below; large growth since V2 (Employee Leave/Attendance added) |
| Controllers (Mobile API) | 2 | 0 | `Mobile/AdminStaffLeaveController`, `Mobile/EmployeeAttendanceController` |
| Controllers (REST API) | 1 | 0 | `Api/AdminAuthController` |
| Controllers (dead/misplaced) | 1 | 5 backup files | `competency.blade.php` misplaced in Controllers/ — P2 cleanup |
| Models | 61 | 24 active + 6 backup | Count includes 3 models that belong in other modules (see gaps) |
| FormRequests | 26 | 26 active + 3 backup | `RoomRequest21_Nov.php` = backup (still present); `LessonRequest.php`, `StudentRequest.php` = wrong module |
| Policies (files) | 44 | 19 registered | Significant improvement; but 5 policy files NOT registered (see gaps) |
| Policies (registered in ServiceProvider) | 38 | 19 | All in `SchoolSetupServiceProvider::registerPolicies()` |
| Services | 3 | 0 | `LeaveBalanceService`, `LeaveRolloverService`, `StaffLeaveService` — all leave-domain |
| Console Commands | 4 | 0 | `ProcessDailyAttendance`, `ProcessLeaveAccrual`, `LeaveRolloverCommand`, `ProcessLeaveEscalations` |
| Jobs | 0 | — | — |
| Events | 1 | — | `StudentRegistration.php` — appears misplaced (belongs in StudentProfile module) |
| Seeders | 29 | — | Comprehensive seeder suite for all sub-domains |
| Views | ~336 | — | Largest view count in the platform |
| Tests | 0 | 0 | Zero test coverage — P2 critical gap |
| DDL tables (`sch_*`) | 52 active | 30 confirmed | V2 was written before Employee Leave/Attendance tables were added |

### Active Controller Inventory (56 web controllers)

| Sub-Domain | Controllers |
|-----------|------------|
| **CoreSetup** | OrganizationController, OrganizationGroupController, OrganizationAcademicSessionController, HolidayController, AnnualLeaveSessionController, EmployeeShiftController, DepartmentController, DesignationController, EntityGroupController, EntityGroupMemberController, SystemConfigController, PermissionSyncController |
| **ClassSetup** | SchoolClassController, SectionController, SubjectController, SubjectTypeController, StudyFormatController, SubjectStudyFormatController, SubjectGroupController, SubjectGroupSubjectController, ClassGroupController, ClassSubjectGroupController, ClassSubjectManagementController, SubjectClassMappingController, SchClassGroupSubjectOptionsController |
| **InfraSetup** | BuildingController, RoomTypeController, RoomController, InfrasetupController |
| **EmployeeSetup** | EmployeeProfileController, TeacherController, EmployeeLifecycleController, EmployeeSeparationController, EmployeeRoleHistoryController, EmployeeShiftAssignmentController |
| **Leave Management** | StaffLeaveTypeController, StaffLeaveConfigController, LeaveApprovalPolicyController, LeaveApprovalPolicyLevelController, LeaveApprovalLevelApproverController, LeaveConfigController, LeaveMasterController, EmployeeLeaveApplicationController, EmployeeLeaveApplicationDocController, EmployeeLeaveApplicationRemarkController, EmployeeLeaveApprovalController, EmployeeLeaveBalanceController, StudentLeaveTypeController, AttendanceMasterController |
| **Attendance** | EmployeeAttendanceController |
| **HR Reports** | EmployeeReportController, EmployeeReportSeederController |
| **RBAC** | UserController, RolePermissionController, UserRolePrmController, SchoolSetupController (stub) |

---

## Module Score Summary (V2 Gap Analysis 2026-03-26 baseline)

| Area | V2 Score | Current Est. | Key Issue |
|------|----------|-------------|-----------|
| DB Integrity | — | 6/10 | `sch_entity_group_members` migration missing; DDL naming discrepancy (singular vs plural); alter-revert sequence on `sch_organizations` |
| Route Integrity | — | 5/10 | EnsureTenantHasModule missing; multiple unprotected AJAX routes; routes/web.php used in parallel with tenant.php |
| Controller Quality | — | 6/10 | 4+ controllers with zero auth; `$request->all()` in 2 controllers; `rand()` in UserController |
| Model Quality | — | 6/10 | 3 misplaced models; `StudentRegistration` event misplaced |
| Service Layer | — | 3/10 | Only 3 services (all leave-domain); all class/employee/org logic inline in controllers |
| FormRequest Coverage | — | 7/10 | 26 FormRequests; missing for DepartmentController, DesignationController |
| Policy / Auth | — | 6/10 | 38 policies registered; 5 policy files not registered; 4+ controllers ignore all policies |
| Test Coverage | **0/10** | **0/10** | Zero tests — highest risk gap |
| Security | — | 4/10 | `is_super_admin` privilege escalation (P0); no EnsureTenantHasModule (P0); role destroy bug (P1) |
| **Overall** | **~55%** | **~62%** | Major Employee Leave/Attendance features added post-V2; security gaps remain unchanged |

---

## DDL Table Inventory (52 active `sch_*` tables — confirmed in tenant migrations)

### CoreSetup Tables (SCO sub-domain)

| Table | Migration File | SoftDeletes | Key DDL Notes |
|-------|---------------|:-----------:|---------------|
| `sch_organizations` | `2026_06_16_152548` | YES | `flg_single_record` UNIQUE enforces single org per tenant; `city_id` FK→`glb_cities` (cross-DB); altered 2026-06-30 (columns added then reverted in two follow-up migrations) |
| `sch_org_academic_sessions_jnt` | `2026_06_15_145404` | YES | `current_flag` GENERATED STORED column with UNIQUE — enforces single current session; `academic_sessions_id` FK→`glb_academic_sessions` (cross-DB) |
| `sch_board_organization_jnt` | `2026_06_16_152610` | NO | `organization_id` column added by alter migration `2026_06_30_000002` — was missing in original; `board_id` FK→`glb_boards` (cross-DB) |
| `sch_academic_term` | `2026_06_15_145405` | YES (added by alter `2026_06_18_100112`) | `current_flag` UNIQUE; `academic_session_id` FK→`sch_org_academic_sessions_jnt` |
| `sch_annual_leave_sessions` | `2026_06_16_104142` | YES | `name` UNIQUE; leave year container for holidays |
| `sch_holidays` | `2026_06_16_104147` | YES | `holiday_type` ENUM(Optional/Other/Public/Religious/Saturday/School_Specific/Sunday/Vacation); `applies_to_role_id` + `applies_to_department_id` nullable FK filters |
| `sch_employee_shifts` | `2026_06_16_104143` | YES | `code` UNIQUE; `applies_to_days` JSON; `is_default` flag; `working_hours` auto-calculated |
| `sch_departments` | `2026_06_15_145911` | YES | `is_system` flag for platform-seeded records; DDL uses plural name (`sch_departments`) — V2 references also match |
| `sch_designations` | `2026_06_15_145912` | NO | Missing SoftDeletes in migration — architectural inconsistency vs all other SCH tables (P1 gap) |
| `sch_entity_groups` | `2026_06_15_145412` | YES | `entity_purpose_id` FK→`sys_dropdowns`; `code` UNIQUE |
| `sch_staff_attendance_types` | `2026_06_16_104145` | YES | `code` UNIQUE; `category` ENUM(Attendance/Holiday/Leave/Other); `affects_payroll` + `payroll_percentage` |
| `sch_staff_leave_types` | `2026_06_16_104146` | YES | `code` UNIQUE; rich leave rules: `min/max_days_per_application`, `min_advance_notice_days`, `requires_substitute`, `allows_half_day`, `allows_back_dated` |
| `sch_staff_leave_config` | `2026_06_16_104159` | YES | Links `leave_type_id` to employment type + role/dept/designation + `annual_entitlement`; `accrual_method` ENUM |
| `sch_leave_approval_policies` | `2026_06_16_104158` | YES (inferred) | `max_approval_levels`; drives multi-level leave approval workflow |
| `sch_leave_approval_policy_levels` | `2026_06_16_104202` | YES (inferred) | `level_ordinal`; `auto_approve_after_hours`; links policy to approver criteria |
| `sch_leave_approval_level_approvers` | `2026_06_16_104207` | YES (inferred) | Links approval level to specific user/role |
| `sch_config` | `2026_06_26_145700` | YES | `ordinal` UNIQUE; `key` UNIQUE; `value_type` ENUM(STRING/NUMBER/BOOLEAN/DATE/TIME/DATETIME/JSON); `tenant_can_modify` flag |
| `sys_dropdowns` | `2026_06_15_145406` (renamed `..._145407`) | YES | Shared across ALL modules; `key` acts as group name; `ordinal` UNIQUE within key |
| `sys_dropdown_needs` | `2026_06_15_145405` | YES | CHECK constraint: `tenant_creation_allowed=0` → menu fields must be NULL; `=1` → all 5 menu path fields required |
| `sys_dropdown_need_dropdowns_jnt` | `2026_06_15_145408` | NO | UNIQUE(`needs_id`, `table_id`) |

> **Missing migration:** `sch_entity_groups_members` — model `EntityGroupMember` and controller `EntityGroupMemberController` exist but NO migration file found in `database/migrations/tenant/`. This is a P1 gap.

### ClassSetup Tables (SCC sub-domain)

| Table | Migration File | SoftDeletes | Key DDL Notes |
|-------|---------------|:-----------:|---------------|
| `sch_classes` | `2026_06_15_145401` | YES | `ordinal` for drag-reorder; `short_name`, `code` |
| `sch_sections` | `2026_06_15_145402` | YES | `ordinal`; global per school (not class-specific at master level) |
| `sch_class_section_jnt` | `2026_06_15_150105` | YES | `class_teacher_id`, `assistance_class_teacher_id` FK→`sch_employees`; `rooms_type_id`; `actual_total_student` (updated by `updateStudentCounts()`) |
| `sch_subject_types` | `2026_06_15_150103` | YES | `ordinal`; CRUD via SubjectTypeController |
| `sch_study_formats` | `2026_06_15_150102` | YES | `ordinal`; CRUD via StudyFormatController |
| `sch_subjects` | `2026_06_15_145403` | YES | `subject_type_id` FK→`sch_subject_types`; `ordinal` |
| `sch_subject_study_format_jnt` | `2026_06_15_150108` | YES | `ordinal` changed to SMALLINT by alter migration `2026_06_19_113000` |
| `sch_subject_study_format_options` | `2026_06_15_150110` | Unknown | Options table for subject-study-format combinations (added with class_group multiple_options feature) |
| `sch_class_groups_jnt` | `2026_06_15_150109` | **NO** | SoftDeletes REMOVED by alter migration `2026_06_18_000001`; `has_multiple_options` column ADDED; column `subject_study_format_id` RENAMED by alter `2026_06_20_123000`; consumed by SmartTimetable |
| `sch_class_group_subject_options_jnt` | `2026_06_15_150107` | Unknown | New junction for multiple subject options per class group; added with `has_multiple_options` feature |
| `sch_subject_groups` | `2026_06_15_150106` | YES | `class_id` + `section_id` FK; `ordinal` |
| `sch_subject_group_subject_jnt` | `2026_06_15_150111` | YES | Links subjects to subject groups + class group |

### InfraSetup Tables (SCI sub-domain)

| Table | Migration File | SoftDeletes | Key DDL Notes |
|-------|---------------|:-----------:|---------------|
| `sch_buildings` | `2026_06_15_150020` | YES | `total_floors` counter |
| `sch_rooms_type` | `2026_06_15_150021` | YES | `total_rooms` counter (updated by `updateRoomTypeCounts()`) |
| `sch_rooms` | `2026_06_15_150022` | YES | `building_id`, `room_type_id`, `floor`, `block`, `capacity` |

### EmployeeSetup Tables (SCE sub-domain)

| Table | Migration File | SoftDeletes | Key DDL Notes |
|-------|---------------|:-----------:|---------------|
| `sch_employees` | `2026_06_15_150600` | YES | `user_id` FK→`sys_users`; `emp_code` UNIQUE; `emp_id_card_type` ENUM(QR/RFID/NFC/Barcode); `is_teacher` flag; `qualifications_json`, `certifications_json`, `experiences_json` |
| `sch_employees_profile` | `2026_06_16_104155` | YES | `employee_id` FK; `role_id` FK; `department_id`, `designation_id`; `work_hours_daily/weekly`; `core_responsibilities` JSON; `preferred_shift` FK |
| `sch_teacher_profile` | `2026_06_16_104156` | YES | UNIQUE `uq_teacher_employee(employee_id)`; `max_available_periods_weekly`, `min_available_periods_weekly`; `can_be_used_for_substitution`; `certified_for_lab` |
| `sch_teacher_capabilities` | `2026_06_16_104200` | YES | `teacher_profile_id` + `class_id` + `subject_study_format_id`; proficiency + priority for drag-reorder |
| `sch_teachers` | `2026_06_15_145411` | Unknown | Legacy or separate teacher record table (migration exists; may be superseded by sch_teacher_profile) |
| `sch_employee_addresses` | `2026_06_16_104148` | YES | Address records per employee |
| `sch_employee_bank_details` | `2026_06_16_104149` | YES | Bank account details — **PII: bank_account_no + IFSC should use encrypted cast** |
| `sch_employee_documents` | `2026_06_16_104150` | YES | Document attachments (may use Spatie Media) |
| `sch_employee_emergency_contacts` | `2026_06_16_104151` | YES | Emergency contact details |
| `sch_employee_role_history` | `2026_06_16_104152` | YES | Tracks role changes over time |
| `sch_employee_separations` | `2026_06_16_104153` | YES | Separation/resignation/retirement records |
| `sch_employee_shift_assignments` | `2026_06_16_104154` | YES | Employee-to-shift assignments |
| `sch_employee_leave_balance` | `2026_06_16_104157` | YES | `leave_type_id`; running balance per employee per leave type |
| `sch_employee_leave_applications` | `2026_06_16_104201` | YES | Full leave application: `start_date`, `end_date`, `is_half_day`; `status` (pending/approved/rejected/cancelled) |
| `sch_employee_leave_application_docs` | `2026_06_16_104204` | YES | Documents attached to leave applications |
| `sch_employee_leave_application_remarks` | `2026_06_16_104205` | YES | Approval/rejection remarks per application |
| `sch_employee_leave_approvals` | `2026_06_16_104206` | YES | Approval workflow records per level |
| `sch_employee_attendance` | `2026_06_16_104203` | YES | Daily attendance records per employee; `attendance_type_id` FK→`sch_staff_attendance_types` |
| `sch_employee_attendance_punches` | `2026_06_16_104209` | YES | Biometric/manual punch records (in/out timestamps) |
| `sch_employee_attendance_corrections` | `2026_06_16_104208` | YES | Attendance correction requests |

---

## Known Gaps & Open Issues

### P0 — Critical (Security / Production Blockers)

| ID | Issue | Location | Fix |
|----|-------|----------|-----|
| SEC-SCH-01 | **`is_super_admin` privilege escalation** — `UserController::update()` includes `is_super_admin` in the data passed to the User model. Any school-level user with `school-setup.user.update` permission can send a crafted PUT request to make ANY user a super admin. Three-layer fix required: (1) remove from `UserRequest` validation rules, (2) remove from controller data extraction, (3) remove from `User::$fillable`, (4) remove checkbox from `user/edit.blade.php` | `UserController.php`, `UserRequest.php`, `User.php`, `edit.blade.php` | Remove `is_super_admin` from all four locations |
| SEC-SCH-02 | **`EnsureTenantHasModule` middleware absent** from entire `school-setup` route group in `routes/tenant.php` (line ~211). Any authenticated tenant user can access school-setup routes without a module license. V2 confirms this as P0 at line 37 | `routes/tenant.php` school-setup group | Add `EnsureTenantHasModule:SchoolSetup` to the middleware array |
| BUG-SCH-03 | **`RolePermissionController::destroy()` calls `$role->save()` instead of `$role->delete()`** — roles are never actually deleted; the method silently succeeds while leaving the role in the database. V2 FR-SCH-14 confirms this bug | `RolePermissionController.php::destroy()` | Replace `$role->save()` with `$role->delete()` |

### P1 — High Priority

| ID | Issue | Location | Fix |
|----|-------|----------|-----|
| BUG-SCH-04 | **`$request->all()` used in `OrganizationController::store()` (line 41) and `update()` (line 94)** — mass assignment risk. Must use `$request->validated()` exclusively | `OrganizationController.php` | Replace `$request->all()` with `$request->validated()` in both methods |
| BUG-SCH-05 | **`$request->all()` used in `OrganizationGroupController::store()` (line 41) and `update()` (line 83)**  | `OrganizationGroupController.php` | Replace with `$request->validated()` |
| SEC-SCH-06 | **`PermissionSyncController::sync()` has no `Gate::authorize()`** — any authenticated user can trigger permission reseed, which modifies the global Spatie permission table for the tenant | `PermissionSyncController.php` | Add `Gate::authorize('school-setup.permission.sync')` |
| SEC-SCH-07 | **`UserRolePrmController` has no `Gate::authorize()` on `index()`** — the user+role+permission hub page is unprotected | `UserRolePrmController.php` | Add `Gate::authorize('school-setup.user-role.viewAny')` |
| SEC-SCH-08 | **`InfrasetupController` has no `Gate::authorize()` calls on any method** — the multi-tab infra overview page is unprotected | `InfrasetupController.php` | Add `Gate::authorize()` to all methods |
| BUG-SCH-09 | **Missing `DepartmentPolicy` registration** — `DepartmentController` calls `Gate::authorize()` but no `DepartmentPolicy` is registered in `SchoolSetupServiceProvider` or `AppServiceProvider`. Also uses wrong permission prefix `prime.department.*` instead of `school-setup.department.*` | `SchoolSetupServiceProvider.php`, `DepartmentController.php` | Create `DepartmentPolicy`, register in ServiceProvider, fix permission prefix |
| BUG-SCH-10 | **Missing `DesignationPolicy` registration** — same issue as DepartmentPolicy | `SchoolSetupServiceProvider.php` | Create and register `DesignationPolicy` |
| BUG-SCH-11 | **`sch_designations` migration missing `softDeletes()`** — all other SCH tables use SoftDeletes; `sch_designations` does not. If `Designation` model has `SoftDeletes` trait, `$designation->delete()` will throw SQL error (no `deleted_at` column) | `2026_06_15_145912` migration | Create additive migration: `$table->softDeletes()` |
| BUG-SCH-12 | **`sch_entity_group_members` table migration NOT FOUND** — `EntityGroupMember` model and `EntityGroupMemberController` exist, but no migration file creates this table in `database/migrations/tenant/`. Entity group member feature is silently broken | Missing migration | Create tenant migration for `sch_entity_groups_members` table |
| BUG-SCH-13 | **`rand()` used in `UserController::index()`** to display totalStudents and totalClasses counts — debug code producing fake statistics in production | `UserController.php:32-33` | Replace with actual `DB::table('...')->count()` queries |
| BUG-SCH-14 | **`usersByRole()` query in `UserController` does not actually filter by role** — returns unfiltered user list regardless of the `$role` parameter | `UserController.php::usersByRole()` | Fix query to apply `whereHas('roles', ...)` filter |
| GAP-SCH-15 | **`ClassGroupController` is mapped to BOTH `class-group` and `class-subgroup` routes** — `class-subgroup` resource should use a dedicated `ClassSubgroupController` which is missing | `routes/tenant.php` | Create `ClassSubgroupController` or rename mapping |
| GAP-SCH-16 | **`SubjectClassMappingController` routes have no `Gate::authorize()`** — 3 AJAX routes (`getSections`, `store`, `loadExisting`) are unprotected | `SubjectClassMappingController.php` | Add Gate::authorize to all 3 methods |

### P2 — Medium Priority

| ID | Issue | Location |
|----|-------|---------|
| GAP-SCH-17 | `EntityGroupController` and `EntityGroupMemberController` partial auth coverage — not all mutating methods call `Gate::authorize()`. No `EntityGroupPolicy` registered in ServiceProvider | Both controllers + ServiceProvider |
| GAP-SCH-18 | 5 policy files exist but are NOT registered in ServiceProvider: `InfrasetupPolicy`, `ClassSubjectManagementPolicy`, `SubjectClassPolicy`, `SchoolAcademicTermPolicy`, `SchoolSetupPolicy` | `SchoolSetupServiceProvider.php` |
| GAP-SCH-19 | No `FormRequest` for `DepartmentController` or `DesignationController` — use inline `$request->validate()` | Both controllers |
| GAP-SCH-20 | `ClassSubjectManagementController` has no `Gate::authorize()` calls | `ClassSubjectManagementController.php` |
| DDL-SCH-21 | `sch_class_groups_jnt` had SoftDeletes REMOVED by alter migration `2026_06_18_000001` — this is now inconsistent with platform standard (all tables should use soft deletes unless there is a documented reason). No documented reason found for removal | DDL + migration |
| DDL-SCH-22 | `sch_board_organization_jnt` was missing `organization_id` in original migration — added by alter `2026_06_30_000002`. Any tenant provisioned before this migration has an incomplete junction table | Alter migration |
| ARCH-SCH-23 | Only 3 services exist (all leave-domain): `LeaveBalanceService`, `LeaveRolloverService`, `StaffLeaveService`. V2 requires services for User, Organization, ClassSetup, Employee/Teacher. All org/class/employee business logic is inline in controllers (some 400–600 line controllers) | No service files for SCO/SCC/SCI/SCE sub-domains |
| GAP-SCH-24 | `OrganizationAcademicSessionController` standard CRUD methods (index, create, store, show, edit, update) are empty stubs — only AJAX variants (`ajaxStore`, `ajaxUpdate`, `setActiveSession`, `toggleBoard`) are implemented | `OrganizationAcademicSessionController.php` |
| DDL-SCH-25 | `sch_employee_bank_details.bank_account_no` (and related IFSC) stored as plaintext. PII that should use Laravel `encrypted` cast | `EmployeeBankDetail` model `$casts` |
| PROD-SCH-26 | Backup/dead files still present in production code: `RoomRequest21_Nov.php` (old FormRequest), `competency.blade.php` (misplaced Blade file in Controllers/), `student_Backup_04_12_2025/` (view backup folder) | Multiple paths |
| ARCH-SCH-27 | 3 models that do NOT belong in SchoolSetup module: `QuestionType` (→ QuestionBank), `PrmTenantPlan` + `PrmTenantPlanRate` (→ Prime/Billing module) | `Models/` directory |
| ARCH-SCH-28 | 2 FormRequests that do NOT belong in SchoolSetup: `LessonRequest.php` (→ Syllabus), `StudentRequest.php` (→ StudentProfile) | `Http/Requests/` directory |
| ARCH-SCH-29 | `Events/StudentRegistration.php` event likely belongs in StudentProfile module, not SchoolSetup | `app/Events/` |
| ARCH-SCH-30 | Duplicate employee resource route registration in `routes/tenant.php` (V2 S-16): employee resource registered twice (lines ~1369 and ~1377) — second registration silently overrides the first | `routes/tenant.php` |
| DDL-SCH-31 | V2 references `sch_department` (singular) vs migration creates `sch_departments` (plural). Similarly `sch_designation` vs `sch_designations`. The migration files use plural names — this is the correct convention. V2 doc has outdated singular names. | V2 doc discrepancy — not a code issue |

### P3 — Backlog

| ID | Issue |
|----|-------|
| GAP-SCH-32 | Zero test coverage across 56+ controllers — highest priority tests: `is_super_admin` escalation test (T-SEC-01), role destroy test (T-RBAC-02), EnsureTenantHasModule test (T-SEC-03), class CRUD test (T-CLS-01), employee onboarding test (T-EMP-01) |
| GAP-SCH-33 | No caching for frequently-accessed masters (classes, sections, subjects) — these are consumed on nearly every page of every module. Add cache layer with tag-based invalidation on mutation |
| GAP-SCH-34 | `sch_academic_term` model + controller: DDL exists + migration exists + `SchoolAcademicTermPolicy` exists, but no `AcademicTermController` found in the file listing. Feature partially built (V2 S-25) |
| GAP-SCH-35 | `EmployeeLifecycleController` exists but promotions/transfers not documented in V2 — `EmployeeSetup_v2/14-Employee_Transfer_Promotion-Promotion_Transfer.md` and `15-Employee_Transfer_Promotion-Separation_Retirement.md` V1 specs exist. Code status unclear |
| GAP-SCH-36 | No rate limiting on form submission routes (throttle:60,1 on store/update/destroy) |
| GAP-SCH-37 | N+1 risk: `UserController::index()` loads users without eager-loading roles relationship |

---

## Feature Area Status (as of 2026-06-30)

| # | Feature Area | V2 FR | Status | Notes |
|---|-------------|-------|--------|-------|
| 1 | Organization Profile | FR-SCH-01 | 🟡 80% | CRUD works; `$request->all()` mass assignment risk; no service class |
| 2 | Organization Groups | FR-SCH-02 | 🟡 75% | CRUD works; `$request->all()` risk |
| 3 | Academic Session Mapping | FR-SCH-03 | 🟡 80% | AJAX CRUD works; standard CRUD stubs empty |
| 4 | Class Management | FR-SCH-04 | ✅ 90% | AJAX JSON CRUD + drag-reorder + cascade restore works |
| 5 | Section Management | FR-SCH-05 | ✅ 90% | CRUD + reorder complete |
| 6 | Class-Section Junction | FR-SCH-06 | 🟡 80% | Inline creation works; `actual_total_student` maintained |
| 7 | Subject Management | FR-SCH-07 | ✅ 90% | Subject + type + format complete |
| 8 | Subject Groups + Class-Subject Mapping | FR-SCH-08 | 🟡 60% | Core works; partial auth; `ClassSubgroupController` missing; multiple-options feature added post-V2 |
| 9 | Infrastructure (Buildings/Rooms) | FR-SCH-09 | 🟡 75% | CRUD works; `InfrasetupController` has zero auth |
| 10 | Department + Designation | FR-SCH-10 | 🟡 55% | No policies registered; wrong permission prefix; no FormRequests; `sch_designations` missing softDeletes |
| 11 | Employee Management | FR-SCH-11 | 🟡 70% | 4-step flow works; `EmployeeService` not extracted; bank details PII unencrypted |
| 12 | Teacher Profile + Capabilities | FR-SCH-12 | 🟡 80% | Profile + capabilities + priority reorder work |
| 13 | User Account Management | FR-SCH-13 | 🟡 60% | P0 `is_super_admin` escalation; `rand()` fake data; `usersByRole` filter broken |
| 14 | Role + Permission Management | FR-SCH-14 | 🟡 65% | Destroy bug (calls save not delete); AJAX permission toggle works; `UserRolePrmController` unprotected |
| 15 | HR Config Masters | FR-SCH-15 | 🟡 70% | 5 masters implemented; some policies not registered |
| 16 | Entity Groups | FR-SCH-16 | 🔴 30% | `sch_entity_group_members` migration missing (feature silently broken); partial auth; no policy registered |
| 17 | Permission Sync Utility | FR-SCH-17 | 🟡 50% | Sync works but NO auth gate — P1 |
| 18 | Employee Leave Management | (post-V2) | 🟡 70% | Full workflow built post-V2: applications, approvals, docs, remarks, balance; 3 services added |
| 19 | Employee Attendance | (post-V2) | 🟡 65% | Attendance + punches + corrections; 4 Artisan commands; mobile API added |
| 20 | Employee Lifecycle | (post-V2) | 🟡 50% | Separations + role history built; promotions/transfers unclear |
| 21 | EnsureTenantHasModule | — | ❌ 0% | Not applied to any school-setup route |
| 22 | Service Layer (core) | — | ❌ 10% | Only leave-domain services; no UserService/OrgService/ClassService/EmployeeService |
| 23 | Test Coverage | — | ❌ 0/10 | Zero tests across all controllers |
| 24 | Academic Term Management | (partial) | 🟡 40% | Table + migration + policy exist; no dedicated controller found |

---

## Cross-Module Dependencies

### SCH Consumes From (Inbound)

| Source Module | Data / Entity | Table Referenced | Note |
|--------------|--------------|-----------------|------|
| GlobalMaster | Academic sessions | `glb_academic_sessions` | Cross-DB read; FK in `sch_org_academic_sessions_jnt` |
| GlobalMaster | Boards | `glb_boards` | Cross-DB read; FK in `sch_board_organization_jnt` |
| GlobalMaster | Cities | `glb_cities` | Cross-DB read; FK in `sch_organizations.city_id` |
| SystemConfig | Dropdown values | `sys_dropdowns` | `entity_purpose_id` in `sch_entity_groups`; many FK lookups |
| Prime (Billing) | Tenant plan | `prm_tenant` | `sch_organizations.id` matches `prm_tenant.id` (soft reference) |
| Spatie Permission | Roles, permissions | `sys_roles`, `sys_permissions` | RBAC for all SCH entities |
| Spatie Media Library | Media files | `media` (sys schema) | Logo, employee photos, documents |

### SCH Provides To (Outbound — SCH is the most critical provider module)

| Consumer Module | Entities Required | Tables | Blocker? |
|----------------|------------------|--------|---------|
| SmartTimetable | Classes, sections, class_sections, subjects, study formats, teachers, rooms, class_groups_jnt | 8+ tables | YES |
| StandardTimetable | Same as SmartTimetable | 8+ tables | YES |
| Syllabus (SLB) | Classes, sections, subjects, teachers | 4 tables | YES |
| LMS (Homework/Quiz/Exam) | Class sections, subjects, teachers | 3 tables | YES |
| StudentProfile (STD) | Classes, class_sections, categories, disable_reasons | 4 tables | YES |
| StudentFee (FIN) | Class sections | `sch_class_section_jnt` | YES |
| Examination (EXA) | Class sections, subjects | 2 tables | YES |
| Library (LIB) | Class sections | `sch_class_section_jnt` | YES |
| HPC (Report Cards) | Class sections, subjects | 2 tables | YES |
| Recommendation (REC) | Classes, subjects, teachers | 3 tables | YES |
| Complaint (CMP) | Departments, employees, organizations | 3 tables | Partial |
| Transport (TPT) | Organization (school address) | `sch_organizations` | Partial |
| Notification (NTF) | Organization (SMS/email config), entity groups | 2 tables | Partial |
| ALL modules | System dropdowns | `sys_dropdowns` | YES — all modules use dropdown lookups |
| ALL modules | School config values | `sch_config` | YES |

> **Critical dependency note:** SCH must be fully provisioned before any tenant module can operate. `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_subjects`, and `sch_organizations` are the most widely consumed tables.

---

## Permission Architecture

### Registered Policies (38 — confirmed in `SchoolSetupServiceProvider::registerPolicies()`)

| Policy | Model | Permission Prefix |
|--------|-------|------------------|
| `OrganizationPolicy` | `Organization` | `tenant.organization.*` |
| `OrgGroupPolicy` | `OrganizationGroup` | `tenant.org-group.*` |
| `BuildingPolicy` | `Building` | `tenant.building.*` |
| `RoomPolicy` | `Room` | `tenant.room.*` |
| `RoomTypePolicy` | `RoomType` | `tenant.room-type.*` |
| `UserPolicy` | `User` | `tenant.user.*` |
| `ClassGroupPolicy` | `SchClassGroupsJnt` (ClassGroup alias) | `tenant.class-group.*` |
| `TeacherPolicy` | `Teacher` | `tenant.teacher.*` |
| `SectionPolicy` | `Section` | `tenant.section.*` |
| `SchoolClassPolicy` | `SchoolClass` | `tenant.school-class.*` |
| `ClassSectionPolicy` | `ClassSection` | `tenant.class-section.*` |
| `ClassPolicy` | `ClassSection` (shared model) | `tenant.class.*` |
| `SubjectTypePolicy` | `SubjectType` | `tenant.subject-type.*` |
| `StudyFormatPolicy` | `StudyFormat` | `tenant.study-format.*` |
| `SubjectPolicy` | `Subject` | `tenant.subject.*` |
| `SubjectStudyFormatPolicy` | `Section` (shared model) | `tenant.subject-study-format.*` |
| `SubjectGroupPolicy` | `SubjectGroup` | `tenant.subject-group.*` |
| `SubjectClassMappingPolicy` | `Section` (shared model) | `tenant.subject-class-mapping.*` |
| `SubjectGroupSubjectPolicy` | `SubjectGroupSubject` | `tenant.subject-group-subject.*` |
| `EmployeeProfilePolicy` | `EmployeeProfile` | `tenant.employee.*` |
| `TeacherProfilePolicy` | `TeacherProfile` | `tenant.teacher-profile.*` |
| `EmployeeAttendancePolicy` | `EmployeeAttendance` | `tenant.employee-attendance.*` |
| `EmployeeAttendancePunchPolicy` | `EmployeeAttendancePunch` | `tenant.employee-attendance-punch.*` |
| `EmployeeAttendanceCorrectionPolicy` | `EmployeeAttendanceCorrection` | `tenant.employee-attendance-correction.*` |
| `LeaveConfigPolicy` | `LeaveConfig` | `tenant.leave-config.*` |
| `LeaveApprovalPolicyPolicy` | `LeaveApprovalPolicy` | `tenant.leave-approval-policy.*` |
| `LeaveApplicationPolicy` | `EmployeeLeaveApplication` | `tenant.leave-application.*` |
| `LeaveBalancePolicy` | `EmployeeLeaveBalance` | `tenant.leave-balance.*` |
| `HolidayPolicy` | `Holiday` | `tenant.holiday.*` |
| `EmployeeShiftPolicy` | `EmployeeShift` | `tenant.employee-shift.*` |
| `EmployeeShiftAssignmentPolicy` | `EmployeeShiftAssignment` | `tenant.employee-shift-assignment.*` |
| `LeavePolicyLevelPolicy` | `LeaveApprovalPolicyLevel` | `tenant.leave-policy-level.*` |
| `LeaveLevelApproverPolicy` | `LeaveApprovalLevelApprover` | `tenant.leave-level-approver.*` |
| `LeaveApprovalActionPolicy` | `EmployeeLeaveApproval` | `tenant.leave-approval-action.*` |
| `LeaveDocumentPolicy` | `EmployeeLeaveApplicationDoc` | `tenant.leave-document.*` |
| `LeaveRemarkPolicy` | `EmployeeLeaveApplicationRemark` | `tenant.leave-remark.*` |
| `StaffAttendanceTypePolicy` | `StaffAttendanceType` | `tenant.staff-attendance-type.*` |
| `EmployeeRoleHistoryPolicy` | `EmployeeRoleHistory` | `tenant.employee-role-history.*` |
| `EmployeeSeparationPolicy` | `EmployeeSeparation` | `tenant.employee-separation.*` |

### Policy Files NOT Registered (5 — exist in Policies/ but absent from ServiceProvider)

| Policy File | Should Protect | Gap ID |
|------------|---------------|--------|
| `InfrasetupPolicy` | `InfrasetupController` overview | GAP-SCH-18 |
| `ClassSubjectManagementPolicy` | `ClassSubjectManagementController` | GAP-SCH-18 |
| `SubjectClassPolicy` | Subject-class management | GAP-SCH-18 |
| `SchoolAcademicTermPolicy` | `sch_academic_term` entity | GAP-SCH-18 |
| `SchoolSetupPolicy` | `SchoolSetupController` (hub) | GAP-SCH-18 |

### Models with NO Policy (unprotected by RBAC)

| Model | Notes |
|-------|-------|
| `Department` | No DepartmentPolicy created or registered (BUG-SCH-09) |
| `Designation` | No DesignationPolicy created or registered (BUG-SCH-10) |
| `EntityGroup` | No EntityGroupPolicy registered (GAP-SCH-17) |
| `EntityGroupMember` | No EntityGroupMemberPolicy registered (GAP-SCH-17) |

---

## Design Decisions Made

| Decision | Detail | Source |
|----------|--------|--------|
| `flg_single_record` UNIQUE constraint | Enforces exactly one `sch_organizations` record per tenant DB — prevents accidental multi-record scenarios | DDL `sch_organizations` |
| `current_flag` UNIQUE constraint on sessions and terms | Both `sch_org_academic_sessions_jnt.current_flag` and `sch_academic_term.current_flag` use MySQL UNIQUE constraints to prevent multiple concurrent sessions atomically | DDL |
| Board affiliations managed via manual DB pivot | `sch_board_organization_jnt` pivot crosses DB connections (tenant→global); `syncBoardPivot()` private method handles attach/detach manually using `DB::table()` instead of Eloquent `sync()` | `OrganizationController` |
| Academic Session CRUD is AJAX-only | Standard Blade CRUD methods (index, create, store, edit, update) are empty stubs; all operations go through `ajaxStore`, `ajaxUpdate`, `setActiveSession`, `toggleBoard` | `OrganizationAcademicSessionController` |
| Class CRUD returns JSON (not page reload) | `SchoolClassController::store()`, `update()`, `destroy()` all return JSON — consumed by Alpine.js or Axios in the class management UI | V2 FR-SCH-04 |
| Class restore cascades to child class-sections | `SchoolClassController::restore()` restores all `sch_class_section_jnt` records for the class | V2 FR-SCH-04 AC5 |
| Class-section deactivation (not deletion) | Sections removed from class update are set `is_active=0`, not soft-deleted; preserves FK integrity | V2 FR-SCH-06 AC3 |
| Teacher capabilities force-delete then re-create | `TeacherController::store()/update()` force-deletes all existing `sch_teacher_capabilities` then recreates from request — avoids conflict resolution on update | V2 FR-SCH-12 AC2 |
| `sch_class_groups_jnt` SoftDeletes removed | Alter migration `2026_06_18_000001` explicitly removes SoftDeletes from `sch_class_groups_jnt`. Also adds `has_multiple_options` column for multi-subject-option per class group slot (used by SmartTimetable). No documented business reason on file. | Alter migration |
| Multi-level leave approval | `sch_leave_approval_policies` → `sch_leave_approval_policy_levels` → `sch_leave_approval_level_approvers` three-tier hierarchy; `auto_approve_after_hours` enables escalation fallback. `LeaveApprovalActionPolicy` controls action permissions. | SCE sub-domain |
| `sch_employee_bank_details` PII risk | `bank_account_no` and `ifsc_code` stored in plaintext. The encrypted cast pattern (from VND module lessons) should be applied here. Current state: not encrypted. | Code review |
| `sys_dropdowns` cross-cutting | `sys_dropdowns` is shared by ALL modules. The `key` column acts as a "group name" (e.g., `entity_purpose`, `holiday_type`). All rows with the same `key` form one dropdown list. The `CHECK` constraint on `sys_dropdown_needs` enforces admin visibility rules. | DDL `sys_dropdowns` |
| Policies registered in module's own ServiceProvider | All 38 policies are registered in `SchoolSetupServiceProvider::registerPolicies()` — not in `AppServiceProvider`. This is the correct pattern for modular architecture. | `SchoolSetupServiceProvider.php` |

---

## Route Registration Pattern

All functional routes registered in central `routes/tenant.php` under:
- Group prefix: `school-setup`, name prefix: `school-setup.`
- Middleware: `['auth', 'verified']` — **`EnsureTenantHasModule` NOT applied (P0 — SEC-SCH-02)**

Module-level `Modules/SchoolSetup/routes/web.php` (494 lines) appears to duplicate some route registrations. V2 suggests a duplicate employee resource registration (S-16 in suggestions).

Key route anomalies (from V2 audit):
- `class-subgroup` resource maps to `ClassGroupController` instead of a dedicated `ClassSubgroupController` (GAP-SCH-15)
- `SubjectClassMappingController` routes (`getSections`, `store`, `loadExisting`) have no Gate protection (SEC-SCH-08-ish)
- `UserRolePrmController::index()` — no auth (SEC-SCH-07)
- `InfrasetupController` — no auth on any method (SEC-SCH-08)
- `PermissionSyncController::sync()` — no auth gate (SEC-SCH-06)
- `RolePermissionController::destroy()` — bug: saves instead of deletes (BUG-SCH-03)
- Duplicate employee resource route (V2 S-16: ~lines 1369 + 1377 in routes/tenant.php)

---

## V1 Screen Spec Inventory (46 files across 4 sub-folders)

### ClassSetup_v2/ (12 files)

| File | Coverage |
|------|---------|
| `00-Module-Overview.md` | Class domain architecture |
| `01-Sections.md` | Section master CRUD |
| `02-Class.md` | Class master CRUD |
| `03-Class-Sections.md` | Class-section junction configuration |
| `04-Subject-Type.md` | Subject type master |
| `05-Study-Format.md` | Study format master |
| `06-Subject.md` | Subject master |
| `07-Subject-StudyFormat.md` | Subject-study-format junction |
| `08-Class-Group.md` | Class group (timetable activity units) |
| `09-Subject-Group.md` | Subject group per class-section |
| `10-SubjectGroup-Subject.md` | Subject group subject junction |
| `11-ClassGroup-Options.md` | Class group multiple options feature (post-V2 addition) |

### CoreSetup_v2/ (3 files)

| File | Coverage |
|------|---------|
| `00-Module-Overview.md` | Core domain architecture |
| `01-Organization.md` | Organization profile + board affiliations |
| `01-Department-Designation.md` | Departments and designations |
| `02-Entity-Groups.md` | Entity groups and members |

### EmployeeSetup_v2/ (27 files)

| File | Coverage |
|------|---------|
| `01-Attendance_Masters-Staff_Attendance_Types.md` | Staff attendance type CRUD |
| `02-Attendance_Masters-Holiday_Calendar.md` | Holiday calendar management |
| `03-Attendance_Masters-Employee_Shifts.md` | Employee shift configuration |
| `04-Attendance_Masters-Shift_Assignments.md` | Employee-to-shift assignments |
| `05-Leave_Config-Staff_Leave_Types.md` | Staff leave types master |
| `06-Leave_Config-Staff_Leave_Config.md` | Leave entitlement configuration |
| `07-Leave_Config-Leave_Approval_Policies.md` | Leave approval policy setup |
| `08-Leave_Config-Approval_Policy_Leaves.md` | Policy-leave mapping |
| `09-Leave_Config-Policy_Leave_Approvers.md` | Approver assignment |
| `10-Leave_Config-Employee_Leave_Balance.md` | Leave balance management |
| `11-Leave_Config-Annual_Leave_Sessions.md` | Annual leave session container |
| `12-Employee_Creation_Profile_Mgmt-Employee.md` | Employee CRUD + documents |
| `13-Employee_Creation_Profile_Mgmt-Teacher_Profile.md` | Teacher profile + capabilities |
| `14-Employee_Transfer_Promotion-Promotion_Transfer.md` | Promotions and transfers |
| `15-Employee_Transfer_Promotion-Separation_Retirement.md` | Separations |
| `16-Employee_Attendance_Management-Employee_Attendance.md` | Daily attendance |
| `17-Employee_Attendance_Management-Employee_Punches.md` | Biometric punch records |
| `18-Employee_Attendance_Management-Employee_Corrections.md` | Attendance corrections |
| `19-Leave_Management-Leave_Applications.md` | Leave application CRUD |
| `20-Leave_Management-Leave_Approval_Requests.md` | Multi-level approval workflow |
| `21-Leave_Management-Separation_Approvals.md` | Separation approval flow |
| `22-Employee_Reports-Attendance.md` | Attendance reports |
| `23-Employee_Reports-Leave_Balance.md` | Leave balance report |
| `24-Employee_Reports-Staffing.md` | Staffing report |
| `25-Employee_Reports-Leave_Usage.md` | Leave usage report |
| `26-Employee_Reports-Compliance.md` | Compliance/statutory report |
| `27-Employee_Reports-Capabilities.md` | Teacher capability report |

### InfraSetup_v2/ (4 files)

| File | Coverage |
|------|---------|
| `00-Module-Overview.md` | Infrastructure architecture |
| `01-Room-Type.md` | Room type master |
| `02-Room-Type-Rooms.md` | Rooms per type |
| `03-Building.md` | Building master |
| `04-Room.md` | Room CRUD |

---

## Lessons Learned

- [2026-06-30 | Business Analyst] SCH is the **largest and most critical** module on the platform — 52 `sch_*` tables, 56+ controllers, 336+ views, 29 seeders, 4 Artisan commands. Any gap analysis must split by sub-domain (SCO/SCC/SCI/SCE) and treat each independently. The existing `SCO_SchoolSetup_CoreSetup.md` knowledge file covers the CoreSetup sub-domain; subsequent knowledge files should cover SCC, SCI, and SCE separately.
- [2026-06-30 | Business Analyst] V2 said 30 DDL tables. Actual count is 52 confirmed in tenant migrations. The gap is entirely explained by the Employee Leave Management and Employee Attendance tables (21 new tables) added after V2 was authored. Always verify table counts against migrations, never against V2.
- [2026-06-30 | Business Analyst] V2 said 0 services. Actual count is 3 (all leave-domain). Significant backend work happened between V2 (March 2026) and now (June 2026) — Employee Leave/Attendance sub-domains were built. This pattern will recur in other modules.
- [2026-06-30 | Business Analyst] The `sch_entity_group_members` migration is NOT present in `database/migrations/tenant/` despite the model and controller existing. The `sch_entity_groups` migration (for the parent table) IS present. The members table creation was either overlooked or embedded somewhere else. This means the Entity Group feature is silently broken — any attempt to add members to a group will throw `SQLSTATE[42S02]: Base table or view not found`.
- [2026-06-30 | Business Analyst] `sch_class_groups_jnt` had SoftDeletes removed by a post-V2 alter migration. This is the only `sch_*` table without SoftDeletes (excluding junction tables). When querying this table, do NOT use `SoftDeletes` scopes; use raw `whereNull('deleted_at')` only if the column exists, or none at all.
- [2026-06-30 | Business Analyst] Policies for `Department` and `Designation` models do NOT exist (not even in the Policies/ folder). These are basic CRUD entities with large downstream exposure (every employee references them). Creating the policy files + registering + fixing the wrong `prime.*` permission prefix is a must-do P1 item.
- [2026-06-30 | Business Analyst] 3 models clearly belonging to other modules are in `Modules/SchoolSetup/app/Models/`: `QuestionType` (QuestionBank), `PrmTenantPlan` + `PrmTenantPlanRate` (Billing/Prime). This creates import coupling: if SchoolSetup ever bootstraps independently, it will try to instantiate these models. Move to correct modules.
- [2026-06-30 | Business Analyst] `sch_board_organization_jnt` was missing its `organization_id` column in the original migration. This was only detected and corrected via an alter migration on 2026-06-30 (`2026_06_30_000002`). Any tenant provisioned before that date lacks this column. A data backfill is needed.

---

## Pending Next Steps

1. **P0**: Remove `is_super_admin` from `UserRequest`, `UserController::update()`, `User::$fillable`, and `user/edit.blade.php` (SEC-SCH-01)
2. **P0**: Add `EnsureTenantHasModule:SchoolSetup` to school-setup route group in `routes/tenant.php` (SEC-SCH-02)
3. **P0**: Fix `RolePermissionController::destroy()` — change `$role->save()` to `$role->delete()` (BUG-SCH-03)
4. **P1**: Replace `$request->all()` with `$request->validated()` in `OrganizationController` and `OrganizationGroupController` (BUG-SCH-04, -05)
5. **P1**: Add `Gate::authorize('school-setup.permission.sync')` to `PermissionSyncController::sync()` (SEC-SCH-06)
6. **P1**: Create `DepartmentPolicy` and `DesignationPolicy`; register in `SchoolSetupServiceProvider`; fix permission prefix in `DepartmentController` from `prime.*` to `school-setup.*` (BUG-SCH-09, -10)
7. **P1**: Create tenant migration for `sch_entity_groups_members` table (BUG-SCH-12)
8. **P1**: Create additive migration to add `softDeletes()` to `sch_designations` (BUG-SCH-11)
9. **P1**: Add `Gate::authorize()` to `UserRolePrmController::index()` and `InfrasetupController` all methods (SEC-SCH-07, -08)
10. **P1**: Replace `rand()` in `UserController::index()` with real COUNT queries; fix `usersByRole()` filter (BUG-SCH-13, -14)
11. **P2**: Register 5 unregistered policy files in ServiceProvider: `InfrasetupPolicy`, `ClassSubjectManagementPolicy`, `SubjectClassPolicy`, `SchoolAcademicTermPolicy`, `SchoolSetupPolicy` (GAP-SCH-18)
12. **P2**: Create `ClassSubgroupController` or correct route mapping (GAP-SCH-15)
13. **P2**: Add Gate::authorize to all `SubjectClassMappingController` methods (GAP-SCH-16)
14. **P2**: Apply `encrypted` cast to `EmployeeBankDetail` model for `bank_account_no` and IFSC (DDL-SCH-25)
15. **P2**: Delete backup files: `RoomRequest21_Nov.php`, `competency.blade.php`, `student_Backup_04_12_2025/` view folder (PROD-SCH-26)
16. **P2**: Move misplaced files to correct modules: `QuestionType`, `PrmTenantPlan`, `PrmTenantPlanRate` (models); `LessonRequest.php`, `StudentRequest.php` (FormRequests); `StudentRegistration.php` (Event) (ARCH-SCH-27/-28/-29)
17. **P2**: Create `FormRequest` for `DepartmentController` and `DesignationController` (GAP-SCH-19)
18. **P3**: Add `EntityGroupPolicy` + `EntityGroupMemberPolicy`; fix `EntityGroupController` auth coverage (GAP-SCH-17)
19. **P3**: Extract service layer: `UserService`, `OrganizationService`, `ClassSetupService`, `EmployeeService` (ARCH-SCH-23)
20. **Test priority**: `is_super_admin` escalation test, role destroy bug test, EnsureTenantHasModule test, entity_group_members table-exists test, class cascade restore test (GAP-SCH-32)

---

## Related Knowledge Files

| File | Content |
|------|---------|
| `SCO_SchoolSetup_CoreSetup.md` | Deep dive: org profile, academic sessions, calendar, leave config masters, sys_dropdowns, sch_configs — 21 tables, 21 controllers, FRD generated 2026-06-30 |

---

---

## FRD Summary (Generated 2026-06-30)

| FRD Field | Value |
|-----------|-------|
| FRD File | `0-FRD_Documents/SCH_FRD_2026-06-30.md` |
| Complete Analysis Pack | `0-FRD_Documents/SCH_FRD_Complete_2026-06-30.md` |
| Total REQs | 26 (REQ-SCH-001 through REQ-SCH-028) |
| Total BRs | 84 (BR-SCH-001 through BR-SCH-084) |
| Workflows Defined | 6 (Employee Onboarding, Academic Session Setup, Leave Application & Approval, Class & Subject Setup, Employee Attendance, RBAC Configuration) |
| Reports Required | 6 (RPT-SCH-001 through RPT-SCH-006) |
| Enhancements Logged | 7 (ENH-SCH-001 through ENH-SCH-007) |
| P0 REQs (Core) | 10 |
| P1 REQs (Standard) | 12 |
| P2 REQs (Enhanced) | 4 |
| Total Documented Gaps | 26 (4 P0, 9 P1, 7 P2, 6 P3) |
| Overall Completion Estimate | ~62% (SCO 70%, SCC 80%, SCI 90%, SCE 45%) |
| Prior FRD (sub-domain only) | `SCO_FRD_Complete_2026-06-29.md` — CoreSetup sub-domain only; superseded in scope |

### Open Questions Raised During FRD Analysis

| Q# | Question | Owner |
|----|---------|-------|
| Q-1 | Is bank_account_encrypted actually encrypted (Laravel Crypt) or plain VARCHAR? | Backend Team |
| Q-2 | Does emergency_contact exist as explicit columns or inside JSON in sch_employees? | Backend Team |
| Q-3 | Is the teacher capability force-delete/recreate pattern safe given SmartTimetable FK usage? | SmartTimetable Team |
| Q-4 | What is the auto-timeout period for leave approval levels? Per-policy or global? | HR Business Owner |
| Q-5 | Should sch_annual_leave_sessions be same as academic sessions, or always separate? | HR Business Owner |
| Q-6 | Does actual_student_count on class-sections auto-update when StudentProfile enrolls a student? | Backend Team |

---

## Post-FRD Pending Next Steps (Priority Order)

1. **P0 [0.5d]**: Create `sch_entity_group_members` migration and deploy — feature is silently broken in production (BUG-SCH-03 / FIX-SCH-001)
2. **P0 [0.5d]**: Remove `is_super_admin` from User model `$fillable` and block in `UserController` (SEC-SCH-02 / FIX-SCH-002)
3. **P0 [0.5d]**: Add `EnsureTenantHasModule:SchoolSetup` to school-setup route group in `routes/tenant.php` (SEC-SCH-01 / FIX-SCH-003)
4. **P0 [1d]**: Register all 44 policy files in `AuthServiceProvider` — 5 currently unregistered and silently inactive (FIX-SCH-004)
5. **P0 [6d]**: Write Pest feature tests for all P0 REQs: org profile, sessions, grades, sections, subjects, user accounts, roles (TEST-SCH-001)
6. **P1 [0.5d]**: Add 4 missing permissions to `SchoolSetupPermissions` seeder and re-seed (FIX-SCH-005)
7. **P1 [2d]**: Implement `LeaveApprovalTimeoutJob` and register in kernel scheduler — currently leave approvals stuck indefinitely at Level 1 (FIX-SCH-006)
8. **P1 [1d]**: Verify and add bank account/IFSC encryption to `sch_employees` (FIX-SCH-007)
9. **P1 [3d]**: Add Redis cache layer for master data reads (classes, sections, subjects) with tag-based invalidation (FIX-SCH-008)
10. **P2 [5d]**: Build employee report screens: RPT-SCH-001 (Attendance), RPT-SCH-002 (Leave Balance), RPT-SCH-003 (Staffing), RPT-SCH-005 (Teacher Capability) (FIX-SCH-012)

> For full list of pre-FRD pending steps (20 items with detailed bug references), see the Pending Next Steps section above this block.

---

---

## Technical Audit Findings — Mode X (2026-06-30)

**Health Score: 37/100 (P0 capped). Deploy: NO-GO.**
Full report: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Audit_Reports/SchoolSetup_Complete_Audit_2026-06-30.md`

### New P0 Findings (confirmed in live code)

| Code | Finding | File:Line |
|------|---------|-----------|
| SEC-SCH-001 | `is_super_admin`, `super_admin_flag`, `password`, `user_type` in `User.$fillable` — privilege escalation | `Models/User.php:59,67-70` |
| SEC-SCH-002 | `EnsureTenantHasModule` missing from RSP — subscription bypass for all 56+ controllers | `Providers/RouteServiceProvider.php:40-48` |
| BUG-SCH-012 | `sch_entity_group_members` migration missing — SQLSTATE 42S02 on any member CRUD | `database/migrations/tenant/` |
| FE-SCH-001 | XSS: `{!! $user->name !!}` in user/edit.blade.php — admin session hijack via crafted name | `resources/views/user/edit.blade.php:38` |
| DAT-SCH-001 | D36: `sch_org_academic_sessions_jnt.current_flag` plain boolean, no UNIQUE — BR-SCH-009 unenforced | `migrations/tenant/2026_06_15_145404_..._jnt_table.php:31` |
| BUG-SCH-017 | 5 routed methods missing in EmployeeProfileController — employee onboarding steps 2+ fatal 500 | `routes/web.php:117-121`; `Controllers/EmployeeProfileController.php` |

### New P1 Findings (confirmed in live code)

| Code | Finding | File:Line |
|------|---------|-----------|
| TEN-SCH-001 | D41: `session('tenant_id')` in 6 locations across 3 controllers — wrong tenant on queued/async | `EmployeeSeparationController.php:54,210`; `EmployeeLeaveApplicationController.php:466,953,1028`; `EmployeeLeaveApprovalController.php:384` |
| TEN-SCH-002 | `tenancy()->initialize()` without `->end()` in 2 console commands — context leak | `Commands/ProcessLeaveAccrual.php:40`; `Commands/ProcessDailyAttendance.php:46` |
| BUG-SCH-011 | D38: `sch_designations` no `softDeletes()` in migration; `Designation` model uses `SoftDeletes` — delete() throws SQLSTATE 42S22 | `migrations/2026_06_15_145912_create_sch_designations_table.php`; `Models/Designation.php:7` |
| BUG-SCH-013 | `rand()` for fake student/class counts in UserController production code; auth commented out | `Controllers/UserController.php:30-35` |
| DAT-SCH-002 | D36: `available_balance` plain decimal not GENERATED — leave balance drifts after accrual | `migrations/2026_06_16_104157_create_sch_employee_leave_balance_table.php:21` |
| ORM-SCH-001 | `EmployeeBankDetail.account_number/ifsc_code/iban` plaintext — no `encrypted` cast; BR-SCH-039 violated | `Models/EmployeeBankDetail.php:17-34` |
| PERF-SCH-003 | `Role::all()` unbounded in 15+ controller paths; `Department::all()` / `Subject::all()` unbounded | 15+ controllers; `EmployeeProfileController.php:312,718`; `UserController.php:37` |
| MIG-SCH-001 | 11 ENUM columns across 4 migrations (D29 violation); 8-value employment_status FSM and 9-value leave status FSM | `sch_employees`, `sch_holidays`, `sch_staff_leave_config`, `sch_employee_leave_applications` migrations |

### Q-1 Resolution (from Open Questions)
Q-1 asked whether `bank_account_encrypted` is actually encrypted — confirmed NOT encrypted (ORM-SCH-001). `account_number` and `ifsc_code` stored as plaintext VARCHAR; no `encrypted` cast present in `EmployeeBankDetail.$casts`.

### Lessons Learned

```
[2026-06-30 | Technical Auditor]
- XSS in user/edit.blade.php — {!! !!} used on a user-controlled field ($user->name); upgraded from
  BA-unknown to P0 because any school admin editing a user is exposed. Fix: change to {{ }}.
- D41 pattern heaviest in SchoolSetup — 6 confirmed session('tenant_id') sites; more than any other
  module reviewed. All three HR workflow controllers (separation, leave application, leave approval) affected.
- sch_entity_group_members migration never written — the BA correctly flagged this as P1; the Technical
  Auditor upgrades to P0 because the first production access produces an uncaught exception at the
  storage layer. Rule: a missing migration for an existing model+controller is always P0.
- Role::all() unbounded appears in 15+ request paths (PERF-SCH-003) — this is the highest single-module
  Role::all() density found in the platform. Cache with tenant-scoped key + 1h TTL minimum.
- super_admin_flag in User.$fillable violates PRM-D-002 (super_admin_flag is GENERATED STORED in sys_users;
  it should never appear in $fillable in any module's User model binding).
- D36 failure mode 1 (plain boolean, missing UNIQUE) is more critical than failure mode 2 (plain decimal
  not GENERATED) — mode 1 allows concurrent active records at the DB level, mode 2 is a drift risk.
  Both require additive migrations.
- sch_employee_leave_balance.available_balance: ProcessLeaveAccrual increments opening_balance but does
  NOT call recompute on available_balance — balance will drift after every cron run until D36 fix applied.
```

---

## Version History

| Version | Date | Agent | Changes |
|---------|------|-------|---------|
| 1.0 | 2026-06-30 | Business Analyst | Initial seed — V2 requirement (full read, 968 lines) + V1 screen specs (46 files, 4 sub-folders noted) + full filesystem verification (60 controller files, 61 models, 44 policy files, 38 registered, 29 seeders, 4 commands, 336 views, 52 `sch_*` migrations); all 37 gaps catalogued with fix actions; references SCO sub-module knowledge |
| 1.2 | 2026-06-30 | Technical Auditor (Mode X) | Added 6 P0 + 8 P1 findings from 12-layer audit; Q-1 resolved (bank details confirmed plaintext); Lessons Learned block added; all new issue codes registered in known-issues.md. Health: 37/100. Deploy: NO-GO. Full report at 3-Audit_Reports/SchoolSetup_Complete_Audit_2026-06-30.md |
| 1.1 | 2026-06-30 | Business Analyst | Added FRD Summary block, Post-FRD Pending Next Steps, and 6 Open Questions from Complete Analysis Pack generation. FRD: `SCH_FRD_2026-06-30.md`; Pack: `SCH_FRD_Complete_2026-06-30.md`. |
