# SCH — School Setup
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL

---

## 1. Executive Summary

School Setup (SCH) is the **foundation module** of the Prime-AI tenant stack. It must be fully configured before any other module can function. It owns the organizational skeleton: school profile, academic structure (classes, sections, subjects), staff management (employees, teachers, roles), infrastructure (buildings, rooms), academic session mapping, and HR configuration masters.

**Current State:** ~55% complete. Core CRUD operations work for most entities. Critical security vulnerabilities exist (privilege escalation via `is_super_admin`, unprotected endpoints). Architectural gaps include zero service classes, 5+ stub controllers, backup files in production, and missing module-license middleware.

**Risk Level: HIGH** — 8 P0/P1 security bugs must be fixed before any production deployment.

| Metric | Value |
|--------|-------|
| Controllers | 36 active + 5 backup/dead files |
| FormRequests | 26 active + 3 backup files |
| Models | 24 active + 6 backup files |
| Policies | 19 registered; 10 entities unprotected |
| Services | 0 (all logic inline in controllers) |
| Test files | 0 (zero coverage) |
| DDL tables (sch_*) | 30 confirmed |
| Gap analysis issues | 68 total (P0:8, P1:15, P2:28, P3:17) |

---

## 2. Module Overview

| Attribute | Value |
|-----------|-------|
| Module Code | SCH |
| Module Type | Tenant (per-school) |
| Table Prefix | `sch_` |
| Route Prefix | `/school-setup` |
| Route Name Prefix | `school-setup.` |
| Middleware | `auth, verified` (EnsureTenantHasModule MISSING — P0) |
| Laravel Module Path | `Modules/SchoolSetup/` |
| Primary Controller Hub | `SchoolSetupController` (stub — needs implementation) |
| RBS Reference | A1–A9 (Tenant & System Mgmt) + H1–H7 (Academics) |

### 2.1 Scope Summary

| In Scope | Out of Scope |
|----------|-------------|
| School profile + board affiliation | Global academic session creation (GlobalMaster) |
| Academic sessions mapping | Biometric attendance marking (Attendance module) |
| Classes, sections, class-section junction | Student enrollment (StudentProfile module) |
| Subjects, subject types, study formats, groups | Payroll and salary processing (HR & Payroll) |
| Class-subject mapping | Admission enquiry (Admission module) |
| Buildings, room types, rooms | |
| Departments, designations | |
| Employees (teaching + non-teaching), teacher profiles | |
| Teacher capability management | |
| User accounts + Spatie RBAC | |
| Attendance types, leave types, leave config | |
| Categories, disable reasons, entity groups | |

### 2.2 Cross-Module Impact

SchoolSetup is a **provider** module. Foreign-key dependents:

| Consumer Module | Entities Used from SCH |
|-----------------|------------------------|
| SmartTimetable | classes, sections, class_sections, subjects, teachers, rooms, buildings, class_groups_jnt |
| Syllabus / Homework / Quiz / Exam | classes, sections, subjects, teachers, class_sections |
| Student Management | classes, class_sections, sections, categories, disable_reasons |
| Student Fee | class_sections, categories |
| Library | class_sections |
| Transport | organizations (school address) |
| Recommendation | classes, subjects, teachers |
| Complaint | departments, employees, organizations |
| HPC (Report Cards) | class_sections, students, subjects |
| Notification | organizations (SMS/email config) |
| Vendor Management | organizations |

---

## 3. Stakeholders & Roles

| Role | Key Actions |
|------|-------------|
| Super Admin (prime level) | Provision tenant, assign plan/modules |
| School Admin (`school-setup.*`) | Configure organization, users, classes, staff, infrastructure |
| Principal | Read-only view of org profile, staff list, class structure |
| HR Officer | Manage employees, leave config, departments, designations |
| IT Admin | User accounts, role/permission management, permission sync |
| Teacher | Read-only view of own profile, timetable, capabilities |
| Tenant System | Consumes sch_* entities via FK relationships |

---

## 4. Functional Requirements

### FR-SCH-01: Organization Profile Management
**Status:** ✅ Implemented (with P1 security gap)
**Description:** Create and maintain the school's core identity record in `sch_organizations`. A unique constraint (`flg_single_record`) enforces exactly one record per tenant DB.
**Gaps from gap analysis:**
- `$request->all()` used in `OrganizationController.php` lines 41, 94 — mass assignment risk (P1)
- Should use `$request->validated()` exclusively
**Acceptance Criteria:**
- AC1: Only one organization record can exist per tenant (enforced by `flg_single_record` generated column)
- AC2: Uploading a logo stores it via Spatie Media Library to the `image` collection
- AC3: Board affiliations are synced via `sch_board_organization_jnt` junction on save
- AC4: `city_id` auto-resolves district, state, and country via city relationship chain
- AC5: All CUD operations are logged via `activityLog()`
- AC6: `$request->validated()` must be used (not `$request->all()`)
- AC7: Soft delete / restore / force delete lifecycle supported

---

### FR-SCH-02: Organization Groups
**Status:** ✅ Implemented (with P1 security gap)
**Description:** Group multiple schools under a trust or school chain via `sch_org_academic_sessions_jnt`.
**Gaps from gap analysis:**
- `$request->all()` in `OrganizationGroupController.php` lines 41, 83 — must replace with `$request->validated()`
**Acceptance Criteria:**
- AC1: Full CRUD with soft delete / restore / force delete
- AC2: Toggle active status via AJAX
- AC3: `$request->validated()` used in store/update

---

### FR-SCH-03: Academic Session Mapping
**Status:** ✅ Implemented
**Description:** Map global academic sessions (from `glb_academic_sessions`) to this school with optional school-specific start/end date override. Only one session can be `is_current = 1` (enforced by `current_flag` generated column UNIQUE constraint).
**Acceptance Criteria:**
- AC1: Link global session to school via `OrganizationAcademicSessionController`
- AC2: Exactly one session can be marked as current (UNIQUE on generated `current_flag` column)
- AC3: `setActiveSession()` atomically clears previous current before setting new
- AC4: AJAX store (`ajaxStore`) and AJAX update (`ajaxUpdate`) endpoints supported
- AC5: Soft delete / restore / toggle active status

---

### FR-SCH-04: Class Management
**Status:** ✅ Implemented
**Description:** Manage grade/class master records in `sch_classes`. Classes have an `ordinal` for sequenced display. CRUD is AJAX/JSON-driven (not full page reloads).
**Acceptance Criteria:**
- AC1: Create class returns JSON; creates `sch_class_sections` junction records in same request if `sections[]` provided
- AC2: Update class reprocesses all associated sections
- AC3: Delete class cascades deactivation of all `sch_class_sections` for that class
- AC4: Drag-and-drop ordinal reorder supported via `commonReorder()`
- AC5: Trash / restore / force-delete lifecycle; restore also restores child class-sections
- AC6: Toggle active status returns JSON

---

### FR-SCH-05: Section Management
**Status:** ✅ Implemented
**Description:** Section master records (`sch_sections`). Sections are global per school (not class-specific at this level — the junction `sch_class_section_jnt` handles the class-specific pairing).
**Acceptance Criteria:**
- AC1: Full CRUD with `SectionRequest` validation (name, code required)
- AC2: Soft delete / restore / force delete / toggle status
- AC3: Ordinal-based reorder

---

### FR-SCH-06: Class-Section Junction Configuration
**Status:** ✅ Implemented
**Description:** Configure the actual class-section combinations (e.g., "Class 6 - A") in `sch_class_section_jnt`. Each junction record carries capacity limits, class teacher assignment, assistant teacher, and default room assignment.
**Key fields:** `class_id`, `section_id`, `capacity`, `min_required_student`, `max_allowed_student`, `actual_total_student`, `class_teacher_id`, `assistance_class_teacher_id`, `rooms_type_id`, `class_house_roome_id`, `total_periods_daily`
**Acceptance Criteria:**
- AC1: Created inline during class create/update via `saveClassSections()` private method
- AC2: Rows with missing required fields (section_id, capacity, class_teacher_id, rooms_type_id, class_house_roome_id) are skipped
- AC3: Removed sections are deactivated (is_active=0), not deleted
- AC4: `updateStudentCounts()` recalculates `actual_total_student` from active enrollment records

---

### FR-SCH-07: Subject Management
**Status:** ✅ Implemented
**Description:** Subject master in `sch_subjects`, subject types in `sch_subject_types`, study formats in `sch_study_formats`, subject-study-format junction in `sch_subject_study_format_jnt`.
**Acceptance Criteria:**
- AC1: Subject requires `name`, `code`, `subject_type_id`
- AC2: Subject types (Core, Elective, Activity, Language, Co-curricular) CRUD via `SubjectTypeController`
- AC3: Study formats (Theory, Practical, Project, Tutorial, Online) CRUD via `StudyFormatController`
- AC4: Subject-study-format combinations managed via `SubjectStudyFormatController` and `getSubjectStudyFormat` / `saveSubjectStudyFormat` AJAX routes
- AC5: Ordinal-based reorder for subjects, types, and formats
- AC6: All entities support soft delete / restore / force delete

---

### FR-SCH-08: Subject Groups and Class-Subject Mapping
**Status:** 🟡 Partial
**Description:** Subject groups (`sch_subject_groups`) group subjects offered at a class-section level. `sch_subject_group_subject_jnt` maps subjects to groups. `sch_class_groups_jnt` is the class-subject mapping consumed by SmartTimetable for activity generation.
**Gaps from gap analysis:**
- `SubjectGroupSubjectController` — partial auth coverage, no FormRequest
- `SubjectStudyFormatController` — partial auth coverage, no FormRequest
- `SubjectClassMappingController` — partial auth coverage, no FormRequest
- `ClassSubgroupController` — missing (routes use `ClassGroupController` as workaround)
- `ClassGroupJntController` — only backup file exists
**Acceptance Criteria:**
- AC1: Subject group requires `name`, `class_id`, `section_id` — associates subjects available for a class-section
- AC2: Class-group junction `sch_class_groups_jnt` links class+section to a subject-study-format with ordinal
- AC3: `SubjectGroupSubjectController`, `SubjectStudyFormatController`, `SubjectClassMappingController` must have `Gate::authorize()` on every mutating method
- AC4: FormRequests added for `SubjectGroupSubjectController` and `SubjectClassMappingController`
- AC5: `ClassSubgroupController` must be implemented or removed from routes

---

### FR-SCH-09: Infrastructure — Buildings, Room Types, Rooms
**Status:** ✅ Implemented
**Description:** Physical infrastructure in `sch_buildings`, `sch_rooms_type`, `sch_rooms`. Rooms link buildings to room types with floor/block/capacity metadata.
**Gaps from gap analysis:**
- `InfrasetupController` — no `Gate::authorize()` calls on any method (P1)
**Acceptance Criteria:**
- AC1: Building CRUD with soft delete / restore / force delete / toggle status
- AC2: Room type CRUD; `updateRoomTypeCounts()` updates aggregated room count on type record
- AC3: Room CRUD with building_id and room_type_id required; capacity field required
- AC4: `roomTypeRooms()` AJAX endpoint returns rooms filtered by room_type_id
- AC5: `InfrasetupController` must add `Gate::authorize()` to all methods

---

### FR-SCH-10: Department and Designation Management
**Status:** 🟡 Partial
**Description:** Department master (`sch_department`) and designation master (`sch_designation`). `DepartmentController::index()` is a large multi-tab page also showing employees, teacher capabilities, and leave config.
**Gaps from gap analysis:**
- No policy registered for `Department` model (P1)
- No policy registered for `Designation` model (P1)
- `DepartmentController` uses `prime.department.viewAny` permission — must be `school-setup.department.viewAny` (P2)
- No FormRequest for Department or Designation CRUD (P2)
**Acceptance Criteria:**
- AC1: Department CRUD (name, code fields)
- AC2: Designation CRUD with optional department linkage
- AC3: `DepartmentPolicy` and `DesignationPolicy` registered in AppServiceProvider
- AC4: Permission prefix corrected to `school-setup.department.*` and `school-setup.designation.*`
- AC5: FormRequests added for both controllers

---

### FR-SCH-11: Employee Management
**Status:** ✅ Implemented (complex multi-step flow)
**Description:** Employee creation is a 4-step flow across multiple controllers and endpoints. `sch_employees` stores core employment data; `sch_employees_profile` stores role, department, work capacity, and skills.
**Employee creation flow:**
1. Create `sys_users` account (UserController) with `user_type = EMPLOYEE`
2. Create `sch_employees` record linking `user_id` (EmployeeProfileController::store)
3. Add profile details → `sch_employees_profile` record (addProfile endpoint)
4. If `is_teacher = 1`: create `sch_teacher_profile` record (addTeacherProfile endpoint)
5. Upload documents (updateDocuments endpoint)
6. Generate QR code (generateQrCode endpoint)
**Gaps from gap analysis:**
- Complex multi-step logic embedded directly in `EmployeeProfileController` (~600 lines) — no service class
- `EmployeeProfile` model has no policy registered in tenant context (P1)
**Acceptance Criteria:**
- AC1: Employee creation requires `user_id`, `emp_code`, `joining_date`; `emp_code` unique per tenant
- AC2: `emp_id_card_type` ENUM: QR, RFID, NFC, Barcode
- AC3: `is_teacher` flag drives whether teacher profile step is shown
- AC4: Documents uploaded and linked via Spatie Media Library
- AC5: QR code generated via `generateQrCode()` with emp_code as payload
- AC6: `EmployeeService` extracted for create/update/document/QR logic (📐 proposed)

---

### FR-SCH-12: Teacher Profile and Capability Management
**Status:** ✅ Implemented
**Description:** Teacher-specific profile in `sch_teacher_profile` extending `sch_employees`. Subject-teaching capabilities in `sch_teacher_capabilities` link teacher_profile to class + subject_study_format with proficiency levels.
**DDL key fields (sch_teacher_profile):** `max_available_periods_weekly`, `min_available_periods_weekly`, `capable_handling_multiple_classes`, `can_be_used_for_substitution`, `certified_for_lab`, `preferred_shift`
**DDL key fields (sch_teacher_capabilities):** `teacher_profile_id`, `class_id`, `subject_study_format_id` (+ proficiency, priority, effective dates)
**Acceptance Criteria:**
- AC1: Teacher profile created via `addTeacherProfile()` — one record per employee
- AC2: Subject capabilities created/synced in `TeacherController::store()/update()` — force-deletes existing then re-creates
- AC3: `priority` field supports DRAG-reorder via `updatePriority` endpoint
- AC4: Single capability delete via `deleteCapability` endpoint
- AC5: `TeacherController::show()` builds timetable grid for teacher (cross-module: consumes SmartTimetable data)
- AC6: `getCapabilityDetails()` AJAX endpoint returns single capability JSON

---

### FR-SCH-13: User Account Management
**Status:** ✅ Implemented (with P0 security vulnerability)
**Description:** Tenant user accounts in `sys_users`. `UserController` handles CRUD with Spatie role assignment and avatar upload.
**CRITICAL SECURITY BUG (P0):** `UserController::update()` includes `is_super_admin` in `$request->only([...])`. Any user with `school-setup.user.update` permission can escalate ANY user to super_admin via crafted PUT request. Three-layer fix required: remove from FormRequest validation, remove from controller data extraction, remove from model `$fillable`, remove checkbox from edit.blade.php.
**Gaps from gap analysis:**
- `UserController::index()` uses `rand()` for totalStudents/totalClasses display (debug code in production — P1)
- `UserController` loads users without eager-loading roles (N+1 query — P2)
- `usersByRole($role)` route exists but query is not actually filtered by role (P2)
**Acceptance Criteria:**
- AC1: `is_super_admin` removed from UserRequest, UserController::update(), User model `$fillable`, and edit view
- AC2: User creation syncs Spatie roles; if 'Teacher' role assigned, redirects to teacher.completeProfile
- AC3: `usersByTypeAjax()` returns employees or teachers not yet linked to an employee record
- AC4: `rand()` replaced with actual COUNT queries from database
- AC5: `usersByRole()` actually filters query by role
- AC6: Eager-load roles in index query

---

### FR-SCH-14: Role and Permission Management (RBAC)
**Status:** 🟡 Partial (destroy bug)
**Description:** Spatie Permission-based RBAC. `RolePermissionController` manages roles and permission assignment. Supports group-based permission sync (filter by permission prefix group).
**Critical Bug (P1):** `RolePermissionController::destroy()` calls `$role->save()` instead of `$role->delete()` — roles are never actually deleted; UI shows success message.
**Gaps from gap analysis:**
- No `EnsureTenantHasModule` middleware on route group (P0)
- `PermissionSyncController` has no `Gate::authorize()` — any authenticated user can trigger reseed (P1)
**Acceptance Criteria:**
- AC1: Role create with Spatie Role creation and initial permission assignment
- AC2: Role edit updates name and syncs permissions
- AC3: `destroy()` MUST call `$role->delete()` not `$role->save()` (fix the destroy bug)
- AC4: `updateRolePermission()` AJAX: give or revoke single permission on role
- AC5: `updatePermissions()` AJAX: sync array of permission names for role
- AC6: `getPermissions()` AJAX: return JSON array of role's current permission names
- AC7: `permissionForRole($role, $group)` AJAX: return permissions filtered by prefix group with assigned status
- AC8: `PermissionSyncController` must require a `Gate::authorize('school-setup.permission.sync')` check

---

### FR-SCH-15: HR Configuration Masters
**Status:** ✅ Implemented
**Description:** Configuration master tables for attendance, leave, categories, and disable reasons.
**Gaps from gap analysis:**
- No policy registered for `AttendanceType`, `LeaveType`, `LeaveConfig`, `DisableReason`, `SchCategory` (all P2)
**Acceptance Criteria:**

| Master | Controller | FormRequest | Table | Key Fields |
|--------|-----------|-------------|-------|-----------|
| Attendance Types | AttendanceTypeController | AttendanceTypeRequest | sch_attendance_types | code (unique), applicable_for ENUM(STUDENT/STAFF/BOTH), is_present |
| Leave Types | LeaveTypeController | LeaveTypeRequest | sch_leave_types | code (unique), is_paid, requires_approval, allow_half_day |
| Leave Config | LeaveConfigController | LeaveConfigRequest | sch_leave_config | academic_year, staff_category_id, leave_type_id, total_allowed, carry_forward |
| Categories | SchCategoryController | SchCategoryRequest | sch_categories | code (unique), applicable_for |
| Disable Reasons | DisableReasonController | DisableReasonRequest | sch_disable_reasons | code (unique), applicable_for, is_reversible |

- AC1: All 5 masters support full CRUD with soft delete
- AC2: Policies registered for all 5 in AppServiceProvider
- AC3: Permission names follow `school-setup.{entity}.*` convention

---

### FR-SCH-16: Entity Groups
**Status:** 🟡 Partial
**Description:** Entity groups (`sch_entity_groups`) allow creating named collections of mixed entity types (students, teachers, departments, roles) for use in notifications, events, supervision. Members stored in `sch_entity_groups_members`.
**DDL:** `entity_purpose_id` (FK to sys_dropdown_table), polymorphic via `entity_table_name` + `entity_selected_id`
**Gaps from gap analysis:**
- No policy registered for EntityGroup / EntityGroupMember (P2)
- Partial auth coverage in `EntityGroupController` and `EntityGroupMemberController`
**Acceptance Criteria:**
- AC1: Create entity group with purpose, name, code
- AC2: Add members of any entity type (class, section, subject, designation, department, role, student, staff, vehicle)
- AC3: `EntityGroupPolicy` registered; all controller methods protected
- AC4: Consumed by Notification, Event Engine modules

---

### FR-SCH-17: Permission Sync Utility
**Status:** 🟡 Partial (unprotected)
**Description:** `PermissionSyncController::sync()` scans all controllers and seeds permissions into `sys_permissions`. Used during deployment.
**Gaps from gap analysis:**
- No `Gate::authorize()` check — any authenticated user can trigger (P1)
**Acceptance Criteria:**
- AC1: Protected by `Gate::authorize('school-setup.permission.sync')` — only super admins can run
- AC2: Idempotent — re-running does not create duplicate permissions
- AC3: Returns count of added/existing permissions in response

---

## 5. Data Model

### 5.1 Existing Tables (sch_* prefix — 30 tables confirmed in DDL)

| Table | DDL Line | Status | Key Columns |
|-------|----------|--------|-------------|
| `sch_organizations` | 405 | ✅ | id (same as prm_tenant), code, name, udise_code, affiliation_no, city_id, rural_urban, flg_single_record (UNIQUE) |
| `sch_org_academic_sessions_jnt` | 445 | ✅ | academic_sessions_id, name, start_date, end_date, is_current, current_flag (generated UNIQUE) |
| `sch_board_organization_jnt` | 465 | ✅ | academic_sessions_id, board_id |
| `sch_department` | 476 | ✅ | name, code |
| `sch_designation` | 486 | ✅ | name, code |
| `sch_entity_groups` | 497 | 🟡 | entity_purpose_id, code (unique), name, description |
| `sch_entity_groups_members` | 515 | 🟡 | entity_group_id, entity_type_id, entity_table_name, entity_selected_id (app-level FK) |
| `sch_attendance_types` | 543 | ✅ | code, name, applicable_for ENUM, is_present, display_order |
| `sch_leave_types` | 564 | ✅ | code, name, is_paid, requires_approval, allow_half_day |
| `sch_categories` | 584 | ✅ | code, name, applicable_for ENUM(STUDENT/STAFF/BOTH) |
| `sch_leave_config` | 602 | ✅ | academic_year, staff_category_id, leave_type_id, total_allowed, carry_forward |
| `sch_disable_reasons` | 624 | ✅ | code, name, applicable_for, is_reversible, count_attrition |
| `sch_sections` | 643 | ✅ | name, code, ordinal |
| `sch_classes` | 660 | ✅ | name, short_name, code, ordinal |
| `sch_class_section_jnt` | 677 | ✅ | class_id, section_id, capacity, class_teacher_id, assistance_class_teacher_id, rooms_type_id, class_house_roome_id, total_periods_daily, actual_total_student |
| `sch_subject_types` | 710 | ✅ | name, code, ordinal |
| `sch_study_formats` | 725 | ✅ | name, code, ordinal |
| `sch_subjects` | 741 | ✅ | name, short_name, code, subject_type_id, ordinal |
| `sch_subject_study_format_jnt` | 759 | ✅ | subject_id, study_format_id, name, code, ordinal |
| `sch_class_groups_jnt` | 787 | 🟡 | class_id, section_id, subject_study_format_id, subject_types, code, name, ordinal |
| `sch_subject_groups` | 832 | 🟡 | name, short_name, code, class_id, section_id, ordinal |
| `sch_subject_group_subject_jnt` | 858 | 🟡 | subject_group_id, subject_id, subject_study_format_id, class_group_id |
| `sch_buildings` | 883 | ✅ | name, code, description, total_floors |
| `sch_rooms_type` | 898 | ✅ | name, code, description, total_rooms (counter) |
| `sch_rooms` | 916 | ✅ | name, code, building_id, room_type_id, floor, block, capacity |
| `sch_employees` | 955 | ✅ | user_id, emp_code (unique), emp_id_card_type, is_teacher, joining_date, qualifications_json, certifications_json, experiences_json |
| `sch_employees_profile` | 984 | 🟡 | employee_id, role_id, department_id, work_hours_daily/weekly, preferred_shift, is_full_time, core_responsibilities JSON, reporting_to |
| `sch_teacher_profile` | 1035 | 🟡 | employee_id, role_id, department_id, designation_id, max_available_periods_weekly, can_be_used_for_substitution, certified_for_lab |
| `sch_teacher_capabilities` | 1088 | 🟡 | teacher_profile_id, class_id, subject_study_format_id |
| `sch_academic_term` | 2775 | ❌ | academic_session_id, term_name, start_date, end_date |

### 5.2 Referenced Tables (other prefixes, managed by other modules)

| Table | Prefix | Module | Used By SCH |
|-------|--------|--------|-------------|
| `sys_users` | sys | Core Auth | User accounts; employees/teachers FK here |
| `sys_roles` / `sys_permissions` | sys | Spatie Permission | RBAC for all SCH entities |
| `sys_media` | sys | Spatie Media | Logo, employee photos, documents |
| `sys_activity_logs` | sys | Audit | All CUD audit trails |
| `glb_academic_sessions` | glb | GlobalMaster | Source for session mapping |
| `glb_boards` | glb | GlobalMaster | School board affiliations |
| `glb_cities` | glb | GlobalMaster | City lookup for org address |

### 5.3 Proposed New Tables / Missing Referenced Tables (📐)

| Table | Reason |
|-------|--------|
| `sch_departments` | DDL uses `sch_department` (singular) — model and FK references use `sch_departments` (plural). Naming alignment needed. |
| `sch_designations` | DDL uses `sch_designation` (singular) — FK references use `sch_designations`. Alignment needed. |
| `sch_employee_roles` | Referenced in DDL FKs for `sch_employees_profile.role_id` and `sch_teacher_profile.role_id` — not found as a standalone DDL entry. Needs to be created or mapped to `sys_roles`. |
| `sch_shifts` | Referenced in `sch_teacher_profile.preferred_shift` as FK — no DDL definition found. Needs DDL. |

---

## 6. API Endpoints & Routes

> Route group prefix: `/school-setup` | Middleware: `auth, verified` | EnsureTenantHasModule: **MISSING**

### 6.1 Organization Routes

| Method | URI | Controller@Method | Auth | Status |
|--------|-----|-------------------|------|--------|
| GET | /school-setup/organization | OrganizationController@index | school-setup.organization.viewAny | ✅ |
| GET | /school-setup/organization/create | OrganizationController@create | school-setup.organization.create | ✅ |
| POST | /school-setup/organization | OrganizationController@store | school-setup.organization.create | ✅ |
| GET | /school-setup/organization/{id}/edit | OrganizationController@edit | school-setup.organization.update | ✅ |
| PUT | /school-setup/organization/{id} | OrganizationController@update | school-setup.organization.update | ✅ |
| DELETE | /school-setup/organization/{id} | OrganizationController@destroy | school-setup.organization.delete | ✅ |
| GET | /school-setup/organization/trash/view | OrganizationController@trashedOrganization | school-setup.organization.restore | ✅ |
| GET | /school-setup/organization/{id}/restore | OrganizationController@restore | school-setup.organization.restore | ✅ |
| DELETE | /school-setup/organization/{id}/force-delete | OrganizationController@forceDelete | school-setup.organization.forceDelete | ✅ |
| POST | /school-setup/organization/{org}/toggle-status | OrganizationController@toggleStatus | school-setup.organization.update | ✅ |
| GET/POST | /school-setup/organization-group | OrganizationGroupController (CRUD) | school-setup.org-group.* | ✅ |

### 6.2 Academic Session Routes

| Method | URI | Controller@Method | Auth | Status |
|--------|-----|-------------------|------|--------|
| GET | /school-setup/organization-academic-session | OrgAcademicSessionController@index | school-setup.org-session.viewAny | ✅ |
| POST | /school-setup/organization-academic-session | OrgAcademicSessionController@store | school-setup.org-session.create | ✅ |
| POST | /school-setup/organization-academic-session/ajax-store | OrgAcademicSessionController@ajaxStore | school-setup.org-session.create | ✅ |
| POST | /school-setup/organization-academic-session/{id}/ajax-update | OrgAcademicSessionController@ajaxUpdate | school-setup.org-session.update | ✅ |
| POST | /school-setup/organization-academic-session/{id}/set-active-session | OrgAcademicSessionController@setActiveSession | school-setup.org-session.update | ✅ |
| DELETE | /school-setup/organization-academic-session/{id}/force-delete | OrgAcademicSessionController@forceDelete | school-setup.org-session.forceDelete | ✅ |

### 6.3 Academic Structure Routes

| Method | URI | Controller@Method | Auth | Status |
|--------|-----|-------------------|------|--------|
| GET | /school-setup/school-class | SchoolClassController@index | school-setup.school-class.viewAny | ✅ |
| POST | /school-setup/school-class | SchoolClassController@store | school-setup.school-class.create | ✅ (JSON) |
| PUT | /school-setup/school-class/{id} | SchoolClassController@update | school-setup.school-class.update | ✅ (JSON) |
| DELETE | /school-setup/school-class/{id} | SchoolClassController@destroy | school-setup.school-class.delete | ✅ (JSON) |
| GET | /school-setup/school-class/trash/view | SchoolClassController@trashedSchoolClass | school-setup.school-class.restore | ✅ |
| GET | /school-setup/school-class/{id}/restore | SchoolClassController@restore | school-setup.school-class.restore | ✅ |
| POST | /school-setup/common/reorder | SchoolClassController@commonReorder | school-setup.school-class.update | ✅ (AJAX) |
| Resource | /school-setup/section | SectionController | school-setup.section.* | ✅ |
| Resource | /school-setup/subject | SubjectController | school-setup.subject.* | ✅ |
| Resource | /school-setup/subject-type | SubjectTypeController | school-setup.subject-type.* | ✅ |
| Resource | /school-setup/study-format | StudyFormatController | school-setup.study-format.* | ✅ |
| POST | /school-setup/get-subject-study-format | StudyFormatController@getSubjectStudyFormat | school-setup.study-format.* | ✅ (AJAX) |
| POST | /school-setup/save-subject-study-format | StudyFormatController@saveSubjectStudyFormat | school-setup.study-format.* | ✅ (AJAX) |
| Resource | /school-setup/subject-group | SubjectGroupController | school-setup.subject-group.* | ✅ |
| Resource | /school-setup/class-group | ClassGroupController | school-setup.class-group.* | ✅ |
| Resource | /school-setup/class-subgroup | ClassGroupController | school-setup.class-subgroup.* | 🟡 (uses ClassGroupController — wrong) |
| Resource | /school-setup/class-subject-management | ClassSubjectManagementController | school-setup.class-subject-management.* | 🟡 no auth |
| GET | /school-setup/class/{classId}/sections | SubjectClassMappingController@getSections | — | 🟡 no auth |
| POST | /school-setup/study-format-class/store | SubjectClassMappingController@store | — | 🟡 no auth |
| POST | /school-setup/subject-class-mapping/load-existing | SubjectClassMappingController@loadExisting | — | 🟡 no auth |

### 6.4 Infrastructure Routes

| Method | URI | Controller@Method | Auth | Status |
|--------|-----|-------------------|------|--------|
| Resource | /school-setup/infrasetup | InfrasetupController | (none — P1) | 🟡 no auth |
| Resource | /school-setup/building | BuildingController | school-setup.building.* | ✅ |
| Resource | /school-setup/room-type | RoomTypeController | school-setup.room-type.* | ✅ |
| Resource | /school-setup/room | RoomController | school-setup.room.* | ✅ |

### 6.5 Employee / Teacher / User Routes

| Method | URI | Controller@Method | Auth | Status |
|--------|-----|-------------------|------|--------|
| GET | /school-setup/employee | EmployeeProfileController@index | school-setup.employee.viewAny | ✅ |
| POST | /school-setup/employee | EmployeeProfileController@store | school-setup.employee.create | ✅ |
| POST | /school-setup/{id}/add-profile | EmployeeProfileController@addProfile | school-setup.employee.update | ✅ |
| POST | /school-setup/{id}/add-teacher-profile | EmployeeProfileController@addTeacherProfile | school-setup.employee.update | ✅ |
| POST | /school-setup/{id}/update-documents | EmployeeProfileController@updateDocuments | school-setup.employee.update | ✅ |
| GET | /school-setup/{id}/generate-qr | EmployeeProfileController@generateQrCode | school-setup.employee.view | ✅ |
| GET | /school-setup/employee/{id}/capability/{cap}/details | EmployeeProfileController@getCapabilityDetails | school-setup.employee.view | ✅ (AJAX) |
| DELETE | /school-setup/employee/capability/{cap} | EmployeeProfileController@deleteCapability | school-setup.employee.delete | ✅ |
| POST | /school-setup/employees/update-priority | EmployeeProfileController@updatePriority | school-setup.employee.update | ✅ |
| Resource | /school-setup/teacher | TeacherController | school-setup.teacher.* | ✅ |
| GET | /school-setup/teacher/complete-profile/{user_id} | TeacherController@completeProfile | school-setup.teacher.create | ✅ |
| GET | /school-setup/teacher/assign-subjects/{user_id} | TeacherController@assignSubjects | school-setup.teacher.update | ✅ |
| Resource | /school-setup/user | UserController | school-setup.user.* | ✅ |
| GET | /school-setup/user/{role}/by-role | UserController@usersByRole | school-setup.user.viewAny | 🟡 (filter not applied) |
| GET | /school-setup/users/by-type | UserController@usersByTypeAjax | school-setup.user.viewAny | ✅ (AJAX) |
| POST | /school-setup/user/{user}/toggle-status | UserController@toggleStatus | school-setup.user.update | ✅ |

### 6.6 Role/Permission Routes

| Method | URI | Controller@Method | Auth | Status |
|--------|-----|-------------------|------|--------|
| GET | /school-setup/user-role-prm | UserRolePrmController@index | (none — P1) | 🟡 no auth |
| Resource | /school-setup/role-permission | RolePermissionController | school-setup.role.* | 🟡 destroy broken |
| PATCH | /school-setup/role-permission/{role}/update | RolePermissionController@updateRolePermission | school-setup.role.update | ✅ (AJAX) |
| GET | /school-setup/role-permission/{role}/permissions | RolePermissionController@getPermissions | school-setup.role.view | ✅ (AJAX) |
| POST | /school-setup/role-permission/{role}/permissions/update | RolePermissionController@updatePermissions | school-setup.role.update | ✅ (AJAX) |
| GET | /school-setup/permissions-for-role/{role}/load/{group} | RolePermissionController@permissionForRole | school-setup.role.view | ✅ (AJAX) |
| GET | /school-setup/sync-permissions | PermissionSyncController@sync | (none — P1) | 🟡 no auth |

---

## 7. UI Screens

| Screen | Route Name | Controller | View | Status |
|--------|-----------|-----------|------|--------|
| Organization Profile | school-setup.organization.* | OrganizationController | organization/index, create, edit | ✅ |
| Organization Groups | school-setup.org-group.* | OrganizationGroupController | organization-group/* | ✅ |
| Academic Sessions | school-setup.organization-academic-session.* | OrgAcademicSessionController | organization-academic-session/* | ✅ |
| Class & Subject Management (multi-tab) | school-setup.school-class.* | SchoolClassController | school-class/index | ✅ |
| Section Master | school-setup.section.* | SectionController | section/* | ✅ |
| Subject Master | school-setup.subject.* | SubjectController | subject/* | ✅ |
| Study Format Master | school-setup.study-format.* | StudyFormatController | study-format/* | ✅ |
| Subject Groups | school-setup.subject-group.* | SubjectGroupController | subject-group/* | ✅ |
| Infrastructure (multi-tab) | school-setup.infrasetup.* | InfrasetupController | infrasetup/* | ✅ |
| Buildings | school-setup.building.* | BuildingController | building/* | ✅ |
| Room Types | school-setup.room-type.* | RoomTypeController | room-type/* | ✅ |
| Rooms | school-setup.room.* | RoomController | room/* | ✅ |
| Department & Staff Hub (multi-tab) | school-setup.department.* | DepartmentController | department/* | 🟡 |
| Employee Management | school-setup.employee.* | EmployeeProfileController | employee/* | ✅ |
| Teacher Management | school-setup.teacher.* | TeacherController | teacher/* | ✅ |
| Teacher Profile Complete | school-setup.teacher.completeProfile | TeacherController | teacher/complete-profile | ✅ |
| User Management | school-setup.user.* | UserController | user/* | ✅ |
| User/Role Hub | school-setup.user-role-prm.index | UserRolePrmController | user-role-permission/index | 🟡 |
| Role & Permissions | school-setup.role-permission.* | RolePermissionController | role-permission/* | 🟡 |

---

## 8. Business Rules

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-01 | One organization record per tenant DB | `flg_single_record` UNIQUE constraint in DDL |
| BR-02 | One current academic session at a time | `current_flag` generated column UNIQUE constraint |
| BR-03 | `is_super_admin` is NOT settable by school admin users | Remove from UserRequest, controller, model `$fillable`, and view |
| BR-04 | All entity mutations require corresponding Gate authorization | Enforced via `Gate::authorize()` in every controller method |
| BR-05 | `EnsureTenantHasModule` must gate entire school-setup route group | Add middleware — currently missing (P0) |
| BR-06 | `$request->validated()` (never `$request->all()`) for all store/update | Code review / audit required |
| BR-07 | Employee codes must be unique per tenant | `emp_code` UNIQUE in DDL |
| BR-08 | Teacher profile: exactly one record per employee | UNIQUE KEY `uq_teacher_employee (employee_id)` in DDL |
| BR-09 | Class restore cascades to all child class-sections | Implemented in SchoolClassController::restore() |
| BR-10 | Sections removed from class update are deactivated, not deleted | Implemented in saveClassSections() private method |
| BR-11 | Permission prefix must be `school-setup.*` not `prime.*` | DepartmentController uses wrong prefix — must be fixed |
| BR-12 | Role destroy must actually delete the role | Fix RolePermissionController::destroy() (currently calls save() instead of delete()) |
| BR-13 | `PermissionSyncController` accessible to super admins only | Add Gate::authorize check |
| BR-14 | Backup files must not exist in production code directories | Delete 7+ dated backup files from Controllers, Models, and Requests |
| BR-15 | `rand()` must not be used to display real data | Replace UserController rand() calls with actual DB COUNT queries |

---

## 9. Workflows

### 9.1 New Employee Onboarding Workflow

```
Admin creates User Account
  └─ UserController::store()
  └─ Assigns role (Teacher or Staff)
     If Teacher → redirect to teacher.completeProfile

Admin creates Employee Record
  └─ EmployeeProfileController::store()
  └─ Links user_id → sch_employees record

Admin adds Employee Profile
  └─ EmployeeProfileController::addProfile()
  └─ Creates sch_employees_profile record (role, dept, work capacity)

[If is_teacher = 1] Admin adds Teacher Profile
  └─ EmployeeProfileController::addTeacherProfile()
  └─ Creates sch_teacher_profile record

Admin uploads Documents
  └─ EmployeeProfileController::updateDocuments()
  └─ Spatie Media Library attachment

System generates QR code
  └─ EmployeeProfileController::generateQrCode()
  └─ emp_code used as QR payload

[If teacher] Admin assigns Subject Capabilities
  └─ TeacherController::store()/update()
  └─ Force-deletes existing sch_teacher_capabilities
  └─ Re-creates from request arrays (teacher_profile_id + class_id + subject_study_format_id)
```

### 9.2 Class Setup Workflow

```
Admin opens /school-setup/school-class (multi-tab page)

Tab 1: Classes
  └─ Create class (SchoolClassController::store JSON)
  └─ Pass sections[] array → saveClassSections() creates class_section_jnt records
  └─ Drag-reorder ordinals via commonReorder()

Tab 2: Subjects
  └─ Create subject types, study formats
  └─ Create subjects → link to subject_type_id
  └─ Create subject-study-format combinations

Tab 3: Subject Groups
  └─ Create subject group for a class-section
  └─ Assign subjects to group via SubjectGroupSubjectController

Tab 4: Class Groups
  └─ Create sch_class_groups_jnt records
  └─ Links class+section to subject_study_format with ordinal
  └─ Consumed by SmartTimetable for activity generation
```

### 9.3 RBAC Configuration Workflow

```
Admin opens /school-setup/role-permission

List roles → Create new role
  └─ RolePermissionController::store()
  └─ Creates Spatie Role
  └─ Assigns initial permissions

Edit role permissions
  └─ Select permission group (e.g., "school-setup.student.*")
  └─ updatePermissions() AJAX syncs selected permission names
  └─ updateRolePermission() AJAX toggles single permission

Assign role to user
  └─ UserController::store()/update()
  └─ $user->syncRoles($request->role_id)
```

---

## 10. Non-Functional Requirements

| Category | Requirement | Current State |
|----------|-------------|---------------|
| Authentication | All routes behind `auth, verified` middleware | ✅ |
| Module Licensing | `EnsureTenantHasModule` applied to route group | ❌ MISSING (P0) |
| Authorization | `Gate::authorize()` on every controller method | 🟡 5+ controllers unprotected |
| Mass Assignment | `$request->validated()` only; no mass-assignable sensitive fields | 🟡 2 controllers use `$request->all()` |
| Soft Deletes | All primary entities use SoftDeletes trait | ✅ |
| Audit Trail | `activityLog()` called on all CUD operations | ✅ |
| Pagination | `paginate()` on all index queries (10 per page default) | ✅ |
| Drag Reorder | `commonReorder()` for 8 entity types via ordinal column | ✅ |
| Media Storage | Spatie Media Library for logos, photos, documents | ✅ |
| JSON Responses | Class CRUD uses JSON/AJAX (not full reloads) | ✅ |
| Service Layer | Business logic extracted to Service classes | ❌ Zero services exist |
| Cache | Frequently accessed masters (classes, sections, subjects) cached | ❌ Not implemented |
| Rate Limiting | Throttle middleware on form submission routes | ❌ Not implemented |
| N+1 Prevention | Eager-load relationships in index queries | 🟡 UserController loads without eager-load |
| Test Coverage | Feature tests for all CRUD operations | ❌ Zero tests exist |
| Production Hygiene | No backup files, debug code, or rand() in production | ❌ 7+ backup files + rand() in UserController |
| MySQL Version | MySQL 8.x, InnoDB, UTF8MB4 | ✅ |
| Multi-tenant Isolation | All tenant data in tenant_db; global refs via cross-db reads | ✅ |

---

## 11. Dependencies

### 11.1 Upstream (SCH depends on)

| Dependency | Type | Why |
|-----------|------|-----|
| `glb_academic_sessions` (GlobalMaster module) | Hard | Source for academic session mapping |
| `glb_boards` (GlobalMaster module) | Hard | Board affiliation in organization |
| `glb_cities` (GlobalMaster module) | Hard | City FK in organization address |
| `sys_users` (Core Auth) | Hard | All employee/teacher user accounts |
| `sys_roles` / `sys_permissions` (Spatie) | Hard | RBAC system |
| `sys_dropdown_table` (Core) | Hard | entity_purpose_id in entity_groups; instruction_language |
| Spatie Media Library | Package | Logo, photos, documents |
| Spatie Permission | Package | Roles and permissions |
| prm_tenant (Prime DB) | Soft | Organization ID matches prm_tenant.id |

### 11.2 Downstream (Modules that depend on SCH)

| Module | Entities Required | Blocker? |
|--------|-------------------|---------|
| SmartTimetable | classes, sections, class_sections, subjects, teachers, rooms, class_groups_jnt | YES — cannot generate without |
| StandardTimetable | Same as SmartTimetable | YES |
| Syllabus (SLB) | classes, sections, subjects, teachers | YES |
| LMS (Homework/Quiz/Exam) | class_sections, subjects, teachers | YES |
| StudentProfile (STD) | classes, class_sections, categories, disable_reasons | YES |
| StudentFee (FIN) | class_sections, categories | YES |
| Examination (EXA) | class_sections, subjects | YES |
| Library (LIB) | class_sections | YES |
| Transport (TPT) | organizations | Partial |
| Recommendation (REC) | classes, subjects, teachers | YES |
| Complaint (CMP) | departments, employees, organizations | YES |
| HPC Report Cards | class_sections, subjects | YES |
| Notification (NTF) | organizations (SMS/email config) | Partial |

### 11.3 Package Dependencies

| Package | Version | Usage |
|---------|---------|-------|
| `spatie/laravel-permission` | ^6.x | Role and permission management |
| `spatie/laravel-medialibrary` | ^11.x | Logo, employee photos, documents |
| `nwidart/laravel-modules` | ^12 | Module structure |
| `stancl/tenancy` | ^3.9 | Multi-tenant DB isolation |

---

## 12. Test Scenarios

### 12.1 Security Tests (P0 — Must Pass Before Deploy)

| ID | Test | Expected |
|----|------|----------|
| T-SEC-01 | POST /school-setup/user/{id} with `is_super_admin=1` | Field ignored; 403 or value not persisted |
| T-SEC-02 | GET /school-setup/school-class without auth | 302 redirect to login |
| T-SEC-03 | GET /school-setup/school-class while module not licensed | 403 from EnsureTenantHasModule |
| T-SEC-04 | GET /school-setup/sync-permissions without super_admin role | 403 |
| T-SEC-05 | POST /school-setup/organization with extra mass-assignment fields | Extra fields ignored |

### 12.2 Organization Tests

| ID | Test | Expected |
|----|------|----------|
| T-ORG-01 | Create organization with valid data | 201 / redirect; record in sch_organizations |
| T-ORG-02 | Attempt second organization create | 422 UNIQUE constraint violation on flg_single_record |
| T-ORG-03 | Upload logo | File stored via Spatie Media; getFirstMediaUrl() returns path |
| T-ORG-04 | Sync board affiliations | sch_board_organization_jnt updated |
| T-ORG-05 | Soft delete organization | deleted_at set; not shown in index |
| T-ORG-06 | Restore soft-deleted organization | deleted_at cleared |

### 12.3 Academic Structure Tests

| ID | Test | Expected |
|----|------|----------|
| T-CLS-01 | Create class with sections[] array | sch_classes + sch_class_section_jnt records created |
| T-CLS-02 | Delete class | All child class_sections deactivated (is_active=0) |
| T-CLS-03 | Restore class | Class + child class_sections restored |
| T-CLS-04 | Reorder classes via commonReorder | ordinal values updated in correct order |
| T-CLS-05 | Create two sessions with is_current=1 | Second assignment clears first (generated UNIQUE constraint) |
| T-SUB-01 | Create subject with invalid subject_type_id | 422 validation error |
| T-SUB-02 | Create subject-study-format combination | sch_subject_study_format_jnt record created |

### 12.4 Employee / Teacher Tests

| ID | Test | Expected |
|----|------|----------|
| T-EMP-01 | Create employee with duplicate emp_code | 422 unique constraint violation |
| T-EMP-02 | Create employee with is_teacher=1 | Teacher profile step shown in UI |
| T-EMP-03 | Add teacher capabilities then update | Force-delete old capabilities; re-create new |
| T-EMP-04 | Reorder teacher subject priorities | ordinal values updated |
| T-EMP-05 | Generate QR code | Returns QR image; emp_code embedded |
| T-EMP-06 | Teacher show page | Timetable grid loaded from SmartTimetable cells |

### 12.5 RBAC Tests

| ID | Test | Expected |
|----|------|----------|
| T-RBAC-01 | Create role with permissions | Spatie role created; permissions assigned |
| T-RBAC-02 | Delete role | Role actually deleted from database (not just save() called) |
| T-RBAC-03 | Assign role to user | User has role; can access permitted routes |
| T-RBAC-04 | Revoke permission from role | User with role can no longer access route |
| T-RBAC-05 | permissionForRole AJAX | Returns correct permissions with assigned flag |

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Class | A grade level (e.g., Class 1, Class 10). Master record in `sch_classes`. |
| Section | A division within a grade (e.g., Section A, Section B). Master in `sch_sections`. |
| Class-Section | The junction of class + section forming the actual teaching unit (e.g., "Class 6 - A") in `sch_class_section_jnt`. |
| Subject Type | Classification of subjects: Core, Elective, Activity, Language, Co-curricular. |
| Study Format | How a subject is taught: Theory, Practical, Project, Tutorial, Online. |
| Subject-Study-Format | Combination record (e.g., "Physics - Lab") in `sch_subject_study_format_jnt`. |
| Class Group (sch_class_groups_jnt) | Maps a class+section to a subject-study-format — the unit consumed by SmartTimetable for timetable activity generation. |
| Subject Group | A named bundle of subjects for a class-section (e.g., "Science Stream"). |
| Employee Profile | Extended profile record for non-teaching staff — work hours, responsibilities, skills. |
| Teacher Profile | Teaching-specific profile — period limits, substitution eligibility, lab certification. |
| Teacher Capability | A teacher's ability to teach a specific subject-study-format for a specific class. |
| RBAC | Role-Based Access Control using Spatie Permission package. |
| EnsureTenantHasModule | Middleware that validates the tenant's plan includes the requested module. |
| flg_single_record | Generated column ensuring exactly one org record per tenant. |
| current_flag | Generated column ensuring exactly one current academic session. |
| is_super_admin | Privilege flag on sys_users — must NOT be writable by school admins. |
| Spatie Media Library | Package for polymorphic file storage (logos, photos, documents). |
| P0 | Critical bug — blocks production deployment. |
| P1 | High severity — fix this sprint. |

---

## 14. Suggestions & Improvements

### 14.1 P0 — Critical (Fix Before Any Production Deploy)

| # | Suggestion | Files Affected |
|---|-----------|----------------|
| S-01 | Remove `is_super_admin` from UserRequest, UserController::update(), User model `$fillable`, and user/edit.blade.php | UserRequest.php, UserController.php, User.php, edit.blade.php |
| S-02 | Add `EnsureTenantHasModule` middleware to school-setup route group in routes/tenant.php | routes/tenant.php:1364 |
| S-03 | Fix `RolePermissionController::destroy()` — replace `$role->save()` with `$role->delete()` | RolePermissionController.php |

### 14.2 P1 — High (Fix This Sprint)

| # | Suggestion | Files Affected |
|---|-----------|----------------|
| S-04 | Add `Gate::authorize()` to all methods in SchoolSetupController, InfrasetupController, ClassSubjectManagementController, UserRolePrmController | 4 controllers |
| S-05 | Replace `$request->all()` with `$request->validated()` in OrganizationController and OrganizationGroupController | 2 controllers |
| S-06 | Register policies for Department, Designation, Employee/EmployeeProfile | AppServiceProvider |
| S-07 | Add `Gate::authorize('school-setup.permission.sync')` to PermissionSyncController | PermissionSyncController.php |
| S-08 | Create Service layer: UserService (user creation + role sync), OrganizationService (profile + board sync), ClassSetupService (class + sections), EmployeeService (employee + teacher profile + QR) | New files in app/Services/ |
| S-09 | Replace `rand()` in UserController::index() with real COUNT queries | UserController.php:32-33 |
| S-10 | Fix usersByRole() query to actually filter by the role parameter | UserController.php |
| S-11 | Add feature tests for Organization CRUD, Class CRUD, Employee onboarding, RBAC | tests/Feature/SchoolSetup/ |

### 14.3 P2 — Medium (Next Sprint)

| # | Suggestion | Files Affected |
|---|-----------|----------------|
| S-12 | Delete all backup/dead files: ClassGroupController_02_02_2026.php, ClassGroupController_06_02_2026.php, ClassGroupJntController_09_02_2026.php, competency.blade.php, StudentController_20_11_2025.php, StudentController_backup_04_12_2025.php, RoomRequest21_Nov.php, StudentRequest_Backup_04_12_2025.php | Multiple |
| S-13 | Register policies for AttendanceType, LeaveType, LeaveConfig, DisableReason, SchCategory, EntityGroup, OrganizationAcademicSession | AppServiceProvider |
| S-14 | Fix permission prefix in DepartmentController from `prime.department.*` to `school-setup.department.*` | DepartmentController.php |
| S-15 | Implement or remove ClassSubgroupController (currently routes point to wrong ClassGroupController) | routes/web.php |
| S-16 | Fix duplicate employee resource route registration (lines 1369, 1377 in routes/tenant.php) | routes/tenant.php |
| S-17 | Resolve DDL naming discrepancy: `sch_department` / `sch_designation` (singular) vs `sch_departments` / `sch_designations` (plural) used in FKs | DDL + Models |
| S-18 | Create `sch_employee_roles` table DDL (referenced in FKs for sch_employees_profile and sch_teacher_profile but not defined) | tenant_db_v2.sql |
| S-19 | Create `sch_shifts` table DDL (referenced in sch_teacher_profile.preferred_shift FK) | tenant_db_v2.sql |
| S-20 | Move LessonRequest.php to Syllabus module; move QuestionType model to QuestionBank module | File moves |

### 14.4 P3 — Low (Backlog)

| # | Suggestion |
|---|-----------|
| S-21 | Add caching for frequently accessed masters (classes, sections, subjects) — used on nearly every page of every module |
| S-22 | Add rate limiting to form submission routes (throttle:60,1 on store/update/destroy) |
| S-23 | Add eager loading in UserController::index() for roles relationship |
| S-24 | Architecture test: verify no cross-module direct DB queries from SCH (should use model relationships) |
| S-25 | Add `sch_academic_term` model + controller (DDL exists at line 2775, no controller found) |

---

## 15. Appendices

### 15.1 Controllers Summary

| Controller | Lines (approx) | Has Auth | Has FormRequest | Service Layer |
|-----------|---------------|----------|-----------------|---------------|
| OrganizationController | ~250 | ✅ | OrganizationRequest | ❌ |
| OrganizationGroupController | ~150 | ✅ | OrganizationGroupRequest | ❌ |
| SchoolSetupController | ~80 | ❌ STUB | None | ❌ |
| SchoolClassController | ~920 | 🟡 Gate::any | SchoolClassRequest | ❌ |
| SectionController | ~150 | ✅ | SectionRequest | ❌ |
| SubjectController | ~150 | ✅ | SubjectRequest | ❌ |
| SubjectTypeController | ~150 | ✅ | SubjectTypeRequest | ❌ |
| StudyFormatController | ~150 | ✅ | StudyFormatRequest | ❌ |
| SubjectGroupController | ~200 | ✅ | SubjectGroupRequest | ❌ |
| SubjectGroupSubjectController | ~150 | 🟡 | None | ❌ |
| SubjectStudyFormatController | ~150 | 🟡 | None | ❌ |
| SubjectClassMappingController | ~100 | 🟡 | None | ❌ |
| ClassGroupController | ~200 | ✅ | ClassGroupRequest | ❌ |
| ClassSubjectManagementController | ~150 | ❌ | None | ❌ |
| ClassSubjectGroupController | ~150 | 🟡 | None | ❌ |
| InfrasetupController | ~100 | ❌ | None | ❌ |
| BuildingController | ~200 | ✅ | BuildingRequest | ❌ |
| RoomTypeController | ~200 | ✅ | RoomTypeRequest | ❌ |
| RoomController | ~200 | ✅ | RoomRequest | ❌ |
| DepartmentController | ~400 | 🟡 (wrong prefix) | None | ❌ |
| DesignationController | ~150 | ✅ | None | ❌ |
| EmployeeProfileController | ~600 | ✅ | StoreEmployeeRequest, UpdateEmployeeRequest | ❌ |
| TeacherController | ~480 | ✅ | TeacherRequest | ❌ |
| UserController | ~330 | ✅ (P0 vuln) | UserRequest | ❌ |
| RolePermissionController | ~330 | ✅ (destroy broken) | RolePermissionRequest | ❌ |
| UserRolePrmController | ~100 | ❌ | None | ❌ |
| PermissionSyncController | ~50 | ❌ | None | ❌ |
| OrganizationAcademicSessionController | ~150 | ✅ | OrganizationAcademicSessionRequest | ❌ |
| AttendanceTypeController | ~200 | ✅ | AttendanceTypeRequest | ❌ |
| LeaveTypeController | ~200 | ✅ | LeaveTypeRequest | ❌ |
| LeaveConfigController | ~200 | ✅ | LeaveConfigRequest | ❌ |
| SchCategoryController | ~200 | ✅ | SchCategoryRequest | ❌ |
| DisableReasonController | ~200 | ✅ | DisableReasonRequest | ❌ |
| EntityGroupController | ~150 | 🟡 | None | ❌ |
| EntityGroupMemberController | ~150 | 🟡 | None | ❌ |

### 15.2 Policies Registered (AppServiceProvider)

Registered: Building, Room, User, OrgGroupPolicy, Organization, ClassGroup, Teacher, RoomType, Section, SchoolClass, ClassSection, SubjectType, StudyFormat, Subject, SubjectStudyFormat, SubjectGroup, SubjectClassMapping, SubjectGroupSubject (19 total)

Not Registered: Department, Designation, Employee/EmployeeProfile (tenant), AttendanceType, LeaveType, LeaveConfig, DisableReason, SchCategory, EntityGroup/EntityGroupMember, OrganizationAcademicSession (10 missing)

### 15.3 Permission Naming Convention

Standard: `school-setup.{entity}.{action}`
Actions: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`

Exception currently in code: `DepartmentController` uses `prime.department.*` — must be corrected.

### 15.4 Backup Files to Delete (Production Hygiene)

**Controllers directory:**
- ClassGroupController_02_02_2026.php
- ClassGroupController_06_02_2026.php
- ClassGroupJntController_09_02_2026.php
- competency.blade.php (misplaced blade file)
- StudentController_20_11_2025.php
- StudentController_backup_04_12_2025.php

**Requests directory:**
- RoomRequest21_Nov.php
- StudentRequest_Backup_04_12_2025.php

**Models directory:**
- SchClassGroupsJnt_06_02_2026.bk
- Student_Backup_04_12_2025.php
- Student.bk
- StudentAcademicSession_Backup_04_12_2025.php
- StudentAcademicSession.bk
- StudentDetail_Backup_04_12_2025.php
- StudentDetail.bk

**Routes directory:**
- web_04_12_2025.php

---

## 16. V1 to V2 Delta

### New Content in V2

| Area | Change |
|------|--------|
| Security bugs | P0 `is_super_admin` privilege escalation fully documented with 4-file fix list |
| Security bugs | P0 `EnsureTenantHasModule` missing from route group documented |
| Security bugs | P1 `RolePermissionController::destroy()` broken documented |
| Security bugs | P1 `PermissionSyncController` unprotected documented |
| Mass assignment | $request->all() in OrganizationController and OrganizationGroupController documented |
| Auth gaps | 10 unprotected entities without policies tabulated |
| Architecture | Zero service layer explicitly flagged with proposed service list (UserService, OrganizationService, ClassSetupService, EmployeeService) |
| DDL gaps | `sch_employee_roles` and `sch_shifts` tables referenced in DDL FKs but not defined — flagged |
| DDL naming | `sch_department` vs `sch_departments` plural/singular discrepancy flagged |
| `sch_academic_term` | DDL exists at line 2775; no model or controller exists |
| Test coverage | Zero tests documented; 25 test scenarios added |
| Routes file | Full routes/web.php parsed and tabulated (replaces approximate list in V1) |
| Backup files | Complete inventory of 15 backup/dead files across all directories |
| Suggestions | 25 numbered improvement items with P0/P1/P2/P3 priority |
| DDL table list | All 30 sch_* tables with DDL line numbers |

### Status Changes from V1

| Feature | V1 Status | V2 Status | Reason |
|---------|-----------|-----------|--------|
| Overall module | ~55% complete | ~55% (unchanged) | No code changes between V1 and V2 doc; V2 reflects same code more accurately |
| Security | Not assessed | HIGH RISK | Deep gap analysis revealed P0 vulnerabilities |
| Service layer | Not mentioned | ❌ explicitly | Gap analysis confirmed zero services |
| Test coverage | Not mentioned | ❌ explicitly | Gap analysis confirmed zero tests |
| Backup files | Partially noted | Full list | Complete inventory added |
| Permission prefix bug | Noted in gaps | Documented per-controller | DepartmentController uses wrong prefix |

---

*Document generated: 2026-03-26 | Next review: Before production deployment of SCH module fixes*
