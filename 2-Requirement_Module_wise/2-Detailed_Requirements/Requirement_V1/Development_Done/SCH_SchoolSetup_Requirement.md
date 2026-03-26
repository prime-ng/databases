# SCH — School Setup Module
## Requirement Document v1.0

**Module Code:** SCH
**Module Type:** Tenant Module (per-school) — FOUNDATION MODULE
**Table Prefix:** `sch_*`
**RBS Reference:** Module A — Tenant & System Management (A1–A9) + Module H — Academics Management (H1–H7)
**Completion Status:** ~55%
**Document Date:** 2026-03-25

> **CRITICAL NOTE:** SchoolSetup is the foundation module for the entire tenant stack.
> Almost all other tenant modules depend on its entities — classes, sections, subjects,
> teachers, employees, rooms, and academic sessions. Changes to SchoolSetup schema or
> models propagate throughout: Transport, Library, LMS, SmartTimetable, Exams, Syllabus,
> Recommendations, Complaints, and Student Management all hold foreign keys into `sch_*` tables.

---

## 1. Module Overview

School Setup is the first module an administrator configures after a school (tenant) is provisioned. It establishes the full organizational, academic, and infrastructure skeleton that all other modules build upon:

- **Organization Setup:** School name, address, affiliation boards, UDISE code, logo
- **Academic Structure:** Classes (Grade 1 to Grade 12), sections (A, B, C...), class-section junction
- **Subject Management:** Subjects, subject types, study formats, subject groups, class-subject mapping
- **Staff Management:** Departments, designations, employees, teachers, teacher profiles, teaching capabilities
- **Infrastructure:** Buildings, room types, rooms, classroom assignment
- **User & Role Management:** Tenant user accounts, Spatie-based roles and permissions, RBAC
- **Academic Session Mapping:** Link global academic sessions to the school's calendar
- **Configuration Masters:** Attendance types, leave types, leave config, disability reasons, categories

No other module can function without School Setup being correctly configured. Student enrollment requires classes and sections. Timetable requires teachers and rooms. Syllabus requires subjects and classes. Exams require class-sections. Recommendations require subjects and classes.

---

## 2. Business Context

Indian schools have diverse structures:
- CBSE schools with Classes 1–12 divided into sections A, B, C
- State board schools with different naming (Std 1, 2, Div A, B)
- Schools with buildings on multiple campuses
- Staff split into teaching staff (teachers) and non-teaching staff (employees)
- Complex leave policies varying by staff category

School Setup must accommodate all these variations through a flexible, configurable structure rather than hardcoded assumptions.

---

## 3. Module Scope

### In Scope
1. Organization profile and multi-board affiliation
2. Class creation with ordinal sequencing and soft-delete
3. Section master and class-section junction (with class teacher, assistant teacher, room assignment)
4. Subject master, subject types, study formats, subject groups, subject-class mapping
5. Building, room type, and room management (capacity, floor, block)
6. Department and designation management
7. Employee creation (user account + employee profile linkage)
8. Teacher creation (user account + teacher profile + subject-teacher capabilities)
9. Teacher capability management (subject proficiency, priority, effective dates)
10. User management (create/edit/deactivate tenant users, role assignment)
11. Role and permission management using Spatie Permission
12. Organization-academic session mapping
13. Leave types, attendance types, categories, leave config, disable reasons

### Out of Scope
- Global academic session creation (managed in GlobalMaster module)
- Biometric attendance marking (separate Attendance module)
- Student enrolment into class-sections (Student Management module)
- Payroll and salary processing (HR & Payroll module — pending)
- Admission enquiry (Admission module — pending)

---

## 4. Database Schema

### 4.1 Organization Tables

**`sch_organizations`** — The core school profile record.

Key columns: `name`, `short_name`, `code`, `udise_code`, `affiliation_number`, `contact_person`, `phone`, `email`, `website`, `address_line_1/2`, `city_id`, `district_id`, `state_id`, `country_id`, `lat`, `lng`, `is_active`, `deleted_at`

Media: Logo stored via Spatie Media Library (`image` collection)
Board mapping: Many-to-many via `sch_organization_boards_jnt` to global board table

**`sch_organization_groups`** — Groups multiple schools under a trust/chain (e.g., "Delhi Public School Group").

**`sch_academic_sessions`** — Maps global academic sessions to a specific school (tenant). Schools can have different session start/end overlaps.

### 4.2 Academic Structure Tables

**`sch_classes`** — Class/grade master.

Key columns: `name` (e.g., "Class 1"), `short_name`, `code`, `ordinal` (drag-reorder supported), `is_active`, `deleted_at`

**`sch_sections`** — Section/division master.

Key columns: `name` (e.g., "Section A"), `code` (e.g., "A"), `ordinal`, `is_active`, `deleted_at`

**`sch_class_sections`** — Junction between class and section (the actual class-section combination e.g., "Class 6 - A").

Key columns: `class_id`, `section_id`, `code` (e.g., "6_A"), `section_code` (e.g., "A"), `name` ("Class 6 - Section A"), `capacity`, `min_required_student`, `max_allowed_student`, `actual_total_student`, `class_teacher_id` (FK to `sys_users`), `assistance_class_teacher_id`, `rooms_type_id` (FK to `sch_room_types`), `class_house_roome_id` (FK to `sch_rooms`), `total_periods_daily`, `ordinal`, `is_active`, `deleted_at`

### 4.3 Subject Tables

**`sch_subjects`** — Subject master.

Key columns: `name`, `short_name`, `code`, `subject_type_id` (FK to `sch_subject_types`), `ordinal`, `is_active`, `deleted_at`

**`sch_subject_types`** — Classification of subjects (Core, Elective, Activity, Language, Co-curricular).

Key columns: `name`, `code`, `short_name`, `ordinal`, `is_active`

**`sch_study_formats`** — How a subject is taught (Theory, Practical, Project, Tutorial, Online).

Key columns: `name`, `code`, `short_name`, `ordinal`, `is_active`

**`sch_subject_study_formats`** — Combination of subject + study format (e.g., "Physics - Lab").

Key columns: `subject_id`, `study_format_id`, `name`, `code`, `ordinal`, `is_active`

**`sch_subject_groups`** — Groups of subjects offered at a class-section level (e.g., "Science Stream").

Key columns: `name`, `short_name`, `code`, `class_id`, `section_id`, `ordinal`, `is_active`

**`sch_subject_group_subjects`** — Junction mapping subjects to subject groups.

Key columns: `subject_group_id`, `subject_id`, `subject_study_format_id`, `class_group_id`, `is_active`

**`sch_class_groups_jnt`** — Class-subject groups junction. Maps a class+section to a subject study format with subject type metadata.

Key columns: `class_id`, `section_id`, `subject_study_format_id` (FK to `sch_subject_study_formats`), `subject_types` (JSON or FK), `code`, `name`, `ordinal`, `is_active`

### 4.4 Infrastructure Tables

**`sch_buildings`** — Physical building master.

Key columns: `name`, `code`, `description`, `total_floors`, `is_active`, `deleted_at`

**`sch_room_types`** — Type classification for rooms (Classroom, Laboratory, Library, Hall, Staff Room).

Key columns: `name`, `code`, `description`, `is_active`, `deleted_at`

**`sch_rooms`** — Individual room/space records.

Key columns: `name`, `code`, `building_id` (FK to `sch_buildings`), `room_type_id` (FK to `sch_room_types`), `floor`, `block`, `capacity`, `is_active`, `deleted_at`

### 4.5 Employee and Teacher Tables

**`sch_employees`** — Employee master (both teaching and non-teaching staff).

Key columns: `user_id` (FK to `sys_users`), `emp_code`, `emp_id_card_type` (QR/RFID/NFC/Barcode), `emp_smart_card_id`, `is_teacher` (TINYINT — 1 if this employee is also a teacher), `joining_date`, `total_experience_years`, `highest_qualification`, `specialization`, `last_institution`, `qualifications_json` (JSON array), `certifications_json` (JSON array), `experiences_json` (JSON array), `is_active`, `deleted_at`

**`sch_employees_profile`** — Extended employee profile (role, department, work capacity, skills).

Key columns: `employee_id`, `user_id`, `role_id` (FK to `sch_employee_roles`), `department_id` (FK to `sch_departments`), `specialization_area`, `qualification_level`, `certifications` (JSON), `work_hours_daily`, `max_hours_daily`, `work_hours_weekly`, `max_hours_weekly`, `preferred_shift` (morning/evening/flexible), `is_full_time`, `core_responsibilities` (JSON), `technical_skills` (JSON), `soft_skills` (JSON), `experience_months`, `performance_rating`, `reporting_to` (FK to `sch_employees`), `can_approve_budget`, `can_manage_staff`, `effective_from`, `effective_to`, `is_active`, `deleted_at`

**`sch_teachers`** — Teacher-specific extension record. The `sch_employees.is_teacher = 1` flag identifies which employees are also teachers.

Key columns: `user_id`, `emp_code`, `max_periods_per_week`, subject/proficiency related fields, `is_active`, `deleted_at`

**`sch_subject_teachers`** — Teaching capability mapping (teacher + subject + study format + proficiency).

Key columns: `teacher_id` (FK to `sch_teachers`), `subject_id`, `study_format_id`, `priority` (PRIMARY/SECONDARY/BACKUP), `proficiency` (level 1–5), `effective_from`, `effective_to`, `is_active`

**`sch_teacher_capabilities`** — Additional teacher capability records (used by SmartTimetable for constraint matching).

**`sch_departments`** — Department master (Academic, Administration, Accounts, IT, Sports, etc.).

**`sch_designations`** — Designation master (Principal, Vice Principal, HOD, Teacher, Admin Officer, etc.).

### 4.6 HR Configuration Tables

**`sch_attendance_types`** — Attendance status master (P/Present, A/Absent, L/Leave, H/Holiday), applicable for STUDENT, STAFF, or BOTH.

Key columns: `code`, `name`, `applicable_for` (ENUM), `is_present`, `is_absent`, `display_order`, `is_active`

**`sch_leave_types`** — Leave category master (CL/Casual Leave, SL/Sick Leave, PL/Parental Leave, LOP).

Key columns: `code`, `name`, `is_paid`, `requires_approval`, `allow_half_day`, `is_active`

**`sch_categories`** — General category master for student and staff classification (SC, ST, OBC, General, Specially Abled, etc.).

Key columns: `code`, `name`, `applicable_for` (STUDENT/STAFF/BOTH), `is_active`

**`sch_leave_config`** — Per-year, per-staff-category leave entitlement configuration.

Key columns: `academic_year` (e.g., '2025-26'), `staff_category_id`, `leave_type_id`, `total_allowed`, `carry_forward`, `max_carry_forward`, `is_active`

**`sch_disable_reasons`** — Reasons for deactivating a student or staff member (Withdrawn, Expelled, Transferred, Resigned, etc.).

Key columns: `code`, `name`, `applicable_for`, `is_reversible`, `count_attrition`, `is_active`

---

## 5. Functional Requirements

### 5.1 Organization Setup (Feature Group 1)

| Feature | Controller | FormRequest | Status |
|---|---|---|---|
| View school profile | `OrganizationController::show()` | — | Complete |
| Create organization | `OrganizationController::create()`, `store()` | `OrganizationRequest` | Complete |
| Edit organization | `OrganizationController::edit()`, `update()` | `OrganizationRequest` | Complete |
| Upload school logo | Inside `store()` / `update()` via Spatie Media Library | — | Complete |
| Board affiliation sync | `$organization->boards()->sync($data['board_id'])` | — | Complete |
| City/district/state auto-populate | Resolved from `city_id` via City model chain | — | Complete |
| Toggle active status | `OrganizationController::toggleStatus()` | — | Complete |
| Soft delete / restore / force delete | `destroy()`, `trashedOrganization()`, `restore()`, `forceDelete()` | — | Complete |
| Organization groups | `OrganizationGroupController` | `OrganizationGroupRequest` | Complete |

**Business Rule:** When creating an organization, `city_id` is the only geographic input required. `district_id`, `state_id`, and `country_id` are derived from the city's chain of relationships automatically.

### 5.2 Academic Structure (Feature Group 2)

All academic structure (classes, sections, class-sections, subject types, study formats, subjects, subject groups, subject-class mapping) is managed through `SchoolClassController` which serves a **multi-tab index page** at `/school-setup/school-class`.

**Classes:**

| Feature | Description | Status |
|---|---|---|
| Create class | JSON response (AJAX), returns class data with sections | Complete |
| Create class-sections in same request | Pass `sections[]` array in class create request | Complete |
| Update class | JSON response, updates class and reprocesses all sections | Complete |
| Delete class | JSON response, cascades to `sch_class_sections` | Complete |
| Toggle class active | JSON response | Complete |
| Drag-and-drop reorder | `commonReorder()` handles ordinal updates with old/new index | Complete |
| Trash/restore/force-delete | Full lifecycle, restores class AND its sections together | Complete |

**Sections:**
- Managed via `SectionController` — full CRUD with `SectionRequest` FormRequest
- Sections are global masters (not class-specific at this level)

**Class-Section Junction:**

The class-section creation/update logic is in the private `saveClassSections()` method of `SchoolClassController`:

- Iterates through `request->sections[]` array
- Creates new `ClassSection` records or updates existing ones
- Skips incomplete rows (missing section_id, capacity, class_teacher_id, rooms_type_id, or class_house_roome_id)
- Deactivates (sets `is_active=0`) class-sections that were removed from the request
- Auto-calculates `ordinal` for new sections

**Student Count Refresh:**
`updateStudentCounts()` recalculates `actual_total_student` on all class sections by counting active `student_academic_sessions` records.

**Subject Types, Study Formats, Subjects, Subject Groups:**

All managed through the same `SchoolClassController::index()` page (multi-tab). Each sub-entity has its own CRUD via dedicated controllers (`SubjectController`, `SubjectTypeController`, `StudyFormatController`, `SubjectGroupController`, `SubjectGroupSubjectController`, `SubjectStudyFormatController`) with FormRequests.

**Class Groups (SchClassGroupsJnt):**

`ClassGroupController` — manages the class-section to subject-study-format mapping with subject type metadata. This is consumed by SmartTimetable for activity generation.

**Reorder Support:**

`commonReorder()` in `SchoolClassController` supports drag-reorder for: `sections`, `class-sections`, `subject-type`, `study-format`, `subject-study-format`, `subject`, `subject-group`, `class-group`. Uses a module-keyed array to resolve the Eloquent model class.

### 5.3 Infrastructure Setup (Feature Group 3)

Infrastructure is managed through `InfrasetupController` (multi-tab index) plus dedicated controllers:

| Feature | Controller | Status |
|---|---|---|
| Building CRUD | `BuildingController` + `BuildingRequest` | Complete |
| Room Type CRUD | `RoomTypeController` + `RoomTypeRequest` | Complete |
| Room CRUD | `RoomController` + `RoomRequest` | Complete |
| Room type → rooms lookup (AJAX) | `InfrasetupController::roomTypeRooms()` | Complete |
| Room type counts update | `RoomTypeController::updateRoomTypeCounts()` | Complete |

**Business Rule:** A Room must belong to a Building and have a Room Type. A Class-Section's `class_house_roome_id` links to a specific Room — this is the default home classroom.

### 5.4 Employee Management (Feature Group 4)

Employee management is the most complex feature group, handled by `EmployeeProfileController`:

**Employee Creation Flow:**
1. Create a `sys_users` account (via `UserController`) with `user_type = 'EMPLOYEE'`
2. From `EmployeeProfileController::store()`, create `sch_employees` record linking `user_id`
3. Add employee profile details via `addProfile()` — creates `sch_employees_profile` record
4. If employee is also a teacher: `addTeacherProfile()` creates `sch_teachers` record
5. Update documents via `updateDocuments()`
6. Generate QR code via `generateQrCode()`

**Teacher Capability Management:**
- Teacher capabilities (subject-teacher mappings) managed in `TeacherController::store()` and `update()`
- Creates `sch_subject_teachers` records with `teacher_id`, `subject_id`, `study_format_id`, `priority`, `proficiency`, `effective_from/to`
- On update: force-deletes all existing `sch_subject_teachers` for the teacher, then re-creates from request arrays
- Priority update endpoint: `employee.update-priority` allows drag-reorder of subject priorities
- Capability delete: `employee.delete-capability` removes a single `sch_teacher_capabilities` record

**Teacher Profile (Show) View:**
`TeacherController::show()` is the most complex show method — it builds a full timetable grid for the teacher:
- Loads teacher's `activityAssignments` and `subjects`
- Resolves the selected timetable (from `?timetable_id` param, or finds PUBLISHED > GENERATED > latest)
- Loads `TimetableCell` records where this teacher is assigned
- Maps cells to days and periods using `periodsByOrd` index
- Calculates workload percentage vs `max_periods_per_week`
- Renders `smarttimetable::timetable.show` view (cross-module view reference)

### 5.5 User & Role Management (Feature Group 5)

**User Management (`UserController`):**

| Feature | Description | Status |
|---|---|---|
| Create user | Creates `sys_users` record, syncs roles, handles image upload via Spatie Media | Complete |
| Edit user | Updates user data, role sync, optional password change | Complete |
| Role-based redirect | If user is assigned 'Teacher' role on create, redirects to `teacher.completeProfile` | Complete |
| Filter by role | `usersByRole($role)` — shows users filtered by role | Partial (query not filtered) |
| Filter by type (AJAX) | `usersByTypeAjax()` — returns employees or teachers not yet linked to an employee record | Complete |
| Toggle status | JSON response | Complete |
| Soft delete / restore / force delete | Full lifecycle | Complete |

**SECURITY ISSUE:** `UserController::update()` includes `is_super_admin` in the `$userData = $request->only([...])` list. This means any user with `school-setup.user.update` permission can set another user's `is_super_admin = true` through a crafted POST request. This is a critical privilege escalation vulnerability.

**Role & Permission Management (`RolePermissionController`):**

| Feature | Description | Status |
|---|---|---|
| Role list with permissions | Loads all roles with their permissions | Complete |
| Create role | Creates Spatie Role with permission sync | Complete |
| Edit role | `prime.role-permission.update` permission required | Complete |
| Group-based permission update | Filters permissions by prefix group (e.g., `tenant.menu`) and syncs only that group | Complete |
| Update role permissions (AJAX) | `updateRolePermission()` — give/revoke single permission | Complete |
| Bulk permission sync (AJAX) | `updatePermissions()` — sync array of permission names | Complete |
| Get permissions for role (AJAX) | `getPermissions()` — returns JSON array of role's permission names | Complete |
| Load permissions by group (AJAX) | `permissionForRole($role, $group)` — returns permissions + assigned status | Complete |

**ISSUE:** `RolePermissionController::index()` uses `Gate::any(['prime.role-permission.viewAny']) || abort(403)` — `Gate::any()` with a single-element array is equivalent to `Gate::authorize()` but syntactically awkward. No functional bug here.

**ISSUE:** `RolePermissionController::destroy()` only calls `$role->save()` (no-op) and redirects. No actual deletion occurs. The role is never deleted.

**Permission Sync (`PermissionSyncController`):**

`GET /school-setup/sync-permissions` — Utility endpoint to scan all controllers and seed permissions into the `sys_permissions` table. Used during deployment and when new permissions are added.

### 5.6 Academic Session Mapping (Feature Group 6)

`OrganizationAcademicSessionController` — maps global academic sessions (from `glb_academic_sessions`) to this school:

| Feature | Description |
|---|---|
| List session mappings | Shows which global sessions are linked to this school |
| Create mapping | Links a global session to this school with school-specific start/end date override |
| Edit mapping | Modify school-specific dates |
| Delete mapping | Remove the link |

FormRequest: `OrganizationAcademicSessionRequest`

### 5.7 HR Configuration (Feature Group 7)

| Feature | Controller | FormRequest | Status |
|---|---|---|---|
| Attendance Types CRUD | `AttendanceTypeController` | `AttendanceTypeRequest` | Complete |
| Leave Types CRUD | `LeaveTypeController` | `LeaveTypeRequest` | Complete |
| Leave Config CRUD | `LeaveConfigController` | `LeaveConfigRequest` | Complete |
| School Categories CRUD | `SchCategoryController` | `SchCategoryRequest` | Complete |
| Disable Reasons CRUD | `DisableReasonController` | `DisableReasonRequest` | Complete |
| Department/Designation (multi-tab) | `DepartmentController` | — | Partial (see gaps) |

`DepartmentController::index()` is a large multi-tab page showing: employees list, teacher capabilities list, departments list, designations list, leave config list. All with pagination and filters.

---

## 6. Non-Functional Requirements

| Requirement | Specification |
|---|---|
| Authentication | All routes behind `auth, verified` middleware |
| Authorization | Gate-based per-action using `school-setup.{entity}.{action}` pattern. SchoolClassController uses `Gate::any([...]) || abort(403)` for multi-entity index pages. |
| Soft Deletes | All primary entities use SoftDeletes. Class restore cascades to class-sections. |
| Audit Trail | `activityLog()` called on all CUD operations |
| Pagination | All index views paginated (10 per page standard; some use 12 or 20 per page) |
| Drag Reorder | Ordinal-based drag-and-drop reorder supported for 8 entity types via `commonReorder()` |
| Media Storage | Logo and images via Spatie Media Library (toMediaCollection) |
| JSON Responses | Class CRUD uses JSON responses (AJAX-driven UI) rather than redirects |

---

## 7. Controllers Inventory

| Controller | Approx. Lines | Key Features | Auth Status | FormRequest |
|---|---|---|---|---|
| `OrganizationController` | ~250 | Full CRUD, media upload, board sync, trash/restore | Complete | `OrganizationRequest` |
| `OrganizationGroupController` | ~150 | Full CRUD, trash/restore | Complete | `OrganizationGroupRequest` |
| `SchoolSetupController` | ~80 | Hub/index only — 4 empty stub section methods | None — STUB | None |
| `SchoolClassController` | ~920 | Classes, sections, subjects, study formats, groups — multi-entity hub. JSON responses. Drag reorder. | Partial (`Gate::any()`) | `SchoolClassRequest` |
| `SectionController` | ~150 | Full CRUD, toggle status | Complete | `SectionRequest` |
| `SubjectController` | ~150 | Full CRUD, toggle status | Complete | `SubjectRequest` |
| `SubjectTypeController` | ~150 | Full CRUD | Complete | `SubjectTypeRequest` |
| `StudyFormatController` | ~150 | Full CRUD | Complete | `StudyFormatRequest` |
| `SubjectGroupController` | ~200 | Full CRUD | Complete | `SubjectGroupRequest` |
| `SubjectGroupSubjectController` | ~150 | Full CRUD | Partial | None |
| `SubjectStudyFormatController` | ~150 | Full CRUD | Partial | None |
| `SubjectClassMappingController` | ~100 | Subject-class assignment | Partial | None |
| `ClassGroupController` | ~200 | SchClassGroupsJnt CRUD + trash/restore | Complete | None |
| `ClassSubjectManagementController` | ~150 | Class-subject management hub | Partial | None |
| `ClassSubjectGroupController` | ~150 | Subject group per class | Partial | None |
| `InfrasetupController` | ~100 | Multi-tab infra hub, roomTypeRooms AJAX | Partial (`Gate::any()`) | None |
| `BuildingController` | ~200 | Full CRUD, trash/restore, toggle | Complete | `BuildingRequest` |
| `RoomTypeController` | ~200 | Full CRUD, trash/restore, toggle, count update | Complete | `RoomTypeRequest` |
| `RoomController` | ~200 | Full CRUD, trash/restore, toggle | Complete | `RoomRequest` |
| `DepartmentController` | ~400 | Multi-tab: employees, capabilities, departments, designations, leave config | Partial | None |
| `DesignationController` | ~150 | Full CRUD | Complete | None |
| `EmployeeProfileController` | ~600 | Employee create/edit, profile add, teacher profile, documents, QR code | Complete | `StoreEmployeeRequest`, `UpdateEmployeeRequest` |
| `TeacherController` | ~480 | Teacher CRUD, subject-teacher sync, timetable view | Complete | `TeacherRequest` |
| `UserController` | ~330 | User CRUD, role sync, type filter AJAX | Complete (with security issue) | `UserRequest` |
| `RolePermissionController` | ~330 | Role CRUD, group permission update, AJAX endpoints | Complete (with destroy issue) | `RolePermissionRequest` |
| `UserRolePrmController` | ~100 | User-role dashboard hub | Partial | None |
| `PermissionSyncController` | ~50 | Scan and seed permissions | No auth | None |
| `OrganizationAcademicSessionController` | ~150 | Academic session mapping CRUD | Complete | `OrganizationAcademicSessionRequest` |
| `AttendanceTypeController` | ~200 | Full CRUD | Complete | `AttendanceTypeRequest` |
| `LeaveTypeController` | ~200 | Full CRUD | Complete | `LeaveTypeRequest` |
| `LeaveConfigController` | ~200 | Full CRUD | Complete | `LeaveConfigRequest` |
| `SchCategoryController` | ~200 | Full CRUD | Complete | `SchCategoryRequest` |
| `DisableReasonController` | ~200 | Full CRUD | Complete | `DisableReasonRequest` |
| `EntityGroupController` | ~150 | Entity groups management | Partial | None |
| `EntityGroupMemberController` | ~150 | Entity group membership | Partial | None |
| `AttendanceTypeController` (duplicate?) | ~200 | File exists in controllers dir | Partial | `AttendanceTypeRequest` |

**Backup/obsolete files in controllers directory (should be removed):**
- `ClassGroupController_02_02_2026.php`
- `ClassGroupController_06_02_2026.php`
- `ClassGroupJntController_09_02_2026.php`
- `competency.blade.php` (incorrectly placed in controllers directory)
- `StudentController_20_11_2025.php`
- `StudentController_backup_04_12_2025.php`
- `StudentController.bk`

---

## 8. Models Inventory

| Model | Table | SoftDeletes | Key Relationships |
|---|---|---|---|
| `Organization` | `sch_organizations` | Yes | HasMany: OrganizationGroup, OrganizationAcademicSession. BelongsToMany: boards via junction. HasMany media via Spatie. |
| `OrganizationGroup` | `sch_organization_groups` | Yes | BelongsTo: Organization |
| `OrganizationAcademicSession` | `sch_academic_sessions` | Yes | BelongsTo: Organization, GlobalAcademicSession |
| `OrganizationPlan` | `sch_organization_plans` | Yes | Prime DB plans mapping to tenant |
| `OrganizationPlanRate` | `sch_organization_plan_rates` | Yes | Billing rate records |
| `SchoolClass` | `sch_classes` | Yes | HasMany: ClassSection, SchClassGroupsJnt. Used extensively in Timetable, Syllabus, Exam, Recommendation. |
| `Section` | `sch_sections` | Yes | HasMany: ClassSection |
| `ClassSection` | `sch_class_sections` | Yes | BelongsTo: SchoolClass, Section, User (classTeacher), User (assistantTeacher), RoomType, Room. HasMany: studentAcademicSessions. |
| `Subject` | `sch_subjects` | Yes | BelongsTo: SubjectType. HasMany: SubjectStudyFormat, SubjectGroupSubject, SubjectTeacher. |
| `SubjectType` | `sch_subject_types` | Yes | HasMany: Subject |
| `StudyFormat` | `sch_study_formats` | Yes | HasMany: SubjectStudyFormat |
| `SubjectStudyFormat` | `sch_subject_study_formats` | Yes | BelongsTo: Subject, StudyFormat. HasMany: SchClassGroupsJnt. |
| `SubjectGroup` | `sch_subject_groups` | Yes | BelongsTo: SchoolClass, Section. HasMany: SubjectGroupSubject. |
| `SubjectGroupSubject` | `sch_subject_group_subjects` | Yes | BelongsTo: SubjectGroup, Subject, SubjectStudyFormat, SchClassGroupsJnt. |
| `SchClassGroupsJnt` | `sch_class_groups_jnt` | Yes | BelongsTo: SchoolClass, Section, SubjectStudyFormat. HasMany: SubjectGroupSubject. |
| `Building` | `sch_buildings` | Yes | HasMany: Room |
| `RoomType` | `sch_room_types` | Yes | HasMany: Room, ClassSection. |
| `Room` | `sch_rooms` | Yes | BelongsTo: Building, RoomType. HasMany: ClassSection (classSections). |
| `Employee` | `sch_employees` | Yes | BelongsTo: User. HasOne: EmployeeProfile. HasMany: SubjectTeacher (via teacher). |
| `EmployeeProfile` | `sch_employees_profile` | Yes | BelongsTo: Employee, User, Role, Department. |
| `Teacher` | `sch_teachers` | Yes | BelongsTo: User. HasMany: SubjectTeacher, TeacherCapability, activityAssignments (SmartTimetable). |
| `TeacherCapability` | `sch_teacher_capabilities` | Yes | BelongsTo: Teacher |
| `SubjectTeacher` | `sch_subject_teachers` | Yes | BelongsTo: Teacher, Subject, StudyFormat. |
| `Department` | `sch_departments` | Yes | HasMany: EmployeeProfile, Designation |
| `Designation` | `sch_designations` | Yes | BelongsTo: Department |
| `User` | `sys_users` | Yes | (From App\Models\User). HasOne: Employee, Teacher. HasRoles (Spatie). |
| `Role` | `sys_roles` | No (Spatie) | Spatie Permission role. HasPermissions. BelongsToMany: Users. |
| `Permission` | `sys_permissions` | No (Spatie) | Spatie Permission permission. BelongsToMany: Roles. |
| `SchCategory` | `sch_categories` | Yes | Simple master |
| `AttendanceType` | `sch_attendance_types` | Yes | Simple master |
| `LeaveType` | `sch_leave_types` | Yes | HasMany: LeaveConfig |
| `LeaveConfig` | `sch_leave_config` | Yes | BelongsTo: LeaveType, SchCategory |
| `DisableReason` | `sch_disable_reasons` | Yes | Simple master |
| `EntityGroup` | (table TBC) | Yes | Groups of entities for collective operations |
| `EntityGroupMember` | (table TBC) | Yes | Members of entity groups |

**Backup/obsolete models in models directory (should be removed):**
- `SchClassGroupsJnt_06_02_2026.bk`
- `Student_Backup_04_12_2025.php`
- `Student.bk`
- `StudentAcademicSession_Backup_04_12_2025.php`
- `StudentAcademicSession.bk`
- `StudentDetail_Backup_04_12_2025.php`
- `StudentDetail.bk`

---

## 9. FormRequests Inventory

| FormRequest | Controller | Key Rules |
|---|---|---|
| `OrganizationRequest` | `OrganizationController` | name required, city_id required (drives district/state/country resolution) |
| `OrganizationGroupRequest` | `OrganizationGroupController` | name, code required |
| `SchoolClassRequest` | `SchoolClassController` | class_name, code, ordinal |
| `SectionRequest` | `SectionController` | name, code, ordinal |
| `SubjectRequest` | `SubjectController` | name, code, subject_type_id |
| `SubjectTypeRequest` | `SubjectTypeController` | name, code |
| `SubjectGroupRequest` | `SubjectGroupController` | name, class_id, section_id |
| `StudyFormatRequest` | `StudyFormatController` | name, code |
| `BuildingRequest` | `BuildingController` | name, code |
| `RoomTypeRequest` | `RoomTypeController` | name, code |
| `RoomRequest` | `RoomController` | name, code, building_id, room_type_id, capacity |
| `StoreEmployeeRequest` | `EmployeeProfileController` | user_id, emp_code, joining_date, is_teacher flag |
| `UpdateEmployeeRequest` | `EmployeeProfileController` | All fields sometimes/nullable |
| `TeacherRequest` | `TeacherController` | user_id, max_periods_per_week |
| `UserRequest` | `UserController` | name, email required; password required on create |
| `RolePermissionRequest` | `RolePermissionController` | name, short_name required |
| `OrganizationAcademicSessionRequest` | `OrganizationAcademicSessionController` | session_id, start_date, end_date |
| `AttendanceTypeRequest` | `AttendanceTypeController` | code (unique), name, applicable_for |
| `LeaveTypeRequest` | `LeaveTypeController` | code (unique), name, is_paid |
| `LeaveConfigRequest` | `LeaveConfigController` | academic_year, staff_category_id, leave_type_id, total_allowed |
| `SchCategoryRequest` | `SchCategoryController` | code (unique), name, applicable_for |
| `DisableReasonRequest` | `DisableReasonController` | code (unique), name, applicable_for |
| `ClassGroupRequest` | `ClassGroupController` | class_id, section_id, subject_study_format_id |
| `LessonRequest` | (unused?) | Appears to be misplaced from Syllabus module |
| `RoomRequest21_Nov.php` | Obsolete backup | Should be removed |
| `StudentRequest_Backup_04_12_2025.php` | Obsolete backup | Should be removed |

---

## 10. Routes Structure

All tenant school-setup routes are prefixed with `/school-setup` and named `school-setup.*`:

### Organization Routes
```
GET    /school-setup/organization                     → OrganizationController@index
GET    /school-setup/organization/create              → OrganizationController@create
POST   /school-setup/organization                     → OrganizationController@store
GET    /school-setup/organization/{id}/edit           → OrganizationController@edit
PUT    /school-setup/organization/{id}                → OrganizationController@update
DELETE /school-setup/organization/{id}                → OrganizationController@destroy
GET    /school-setup/organization/trash/view          → OrganizationController@trashedOrganization
GET    /school-setup/organization/{id}/restore        → OrganizationController@restore
DELETE /school-setup/organization/{id}/force-delete   → OrganizationController@forceDelete
POST   /school-setup/organization/{id}/toggle-status  → OrganizationController@toggleStatus
```

### User & Role Management Routes
```
GET    /school-setup/user-role-prm        → UserRolePrmController@index
GET    /school-setup/user                 → UserController@index
GET    /school-setup/user/{role}/by-role  → UserController@usersByRole
GET    /school-setup/users/by-type        → UserController@usersByTypeAjax (AJAX)
GET    /school-setup/role-permission      → RolePermissionController@index
PATCH  /school-setup/role-permission/{role}/update    → updateRolePermission (AJAX)
GET    /school-setup/role-permission/{role}/permissions → getPermissions (AJAX)
POST   /school-setup/role-permission/{role}/permissions/update → updatePermissions (AJAX)
GET    /school-setup/permissions-for-role/{role}/load/{group} → permissionForRole (AJAX)
GET    /school-setup/sync-permissions     → PermissionSyncController@sync
```

### Infrastructure Routes
```
GET    /school-setup/infrasetup           → InfrasetupController@index (multi-tab)
POST   /school-setup/room-type/rooms      → InfrasetupController@roomTypeRooms (AJAX)
[Full CRUD for building, room-type, room with trash/restore]
```

### Class & Subject Routes
```
GET    /school-setup/school-class         → SchoolClassController@index (multi-tab)
POST   /school-setup/common/reorder       → SchoolClassController@commonReorder (AJAX)
POST   /school-setup/school-class         → SchoolClassController@store (JSON AJAX)
PUT    /school-setup/school-class/{id}    → SchoolClassController@update (JSON AJAX)
DELETE /school-setup/school-class/{id}    → SchoolClassController@destroy (JSON AJAX)
[Plus section, subject, study-format, subject-group resources]
```

### Employee Routes
```
GET    /school-setup/employee             → EmployeeProfileController@index
POST   /school-setup/employee             → EmployeeProfileController@store
POST   /school-setup/{id}/add-profile    → EmployeeProfileController@addProfile
POST   /school-setup/{id}/add-teacher-profile → EmployeeProfileController@addTeacherProfile
POST   /school-setup/{id}/update-documents → EmployeeProfileController@updateDocuments
GET    /school-setup/{id}/generate-qr    → EmployeeProfileController@generateQrCode
GET    /school-setup/employee/{id}/capability/{cap}/details → getCapabilityDetails (AJAX)
DELETE /school-setup/employee/capability/{cap} → deleteCapability
POST   /school-setup/employees/update-priority → updatePriority
```

---

## 11. Cross-Module Dependencies

SchoolSetup is the **provider** for almost all other modules. The following modules **consume** SchoolSetup entities:

| Module | Entities Consumed |
|---|---|
| SmartTimetable | `sch_classes`, `sch_sections`, `sch_class_sections`, `sch_subjects`, `sch_teachers`, `sch_rooms`, `sch_buildings`, `sch_subject_study_formats`, `sch_class_groups_jnt` |
| Standard Timetable | Same as SmartTimetable |
| Syllabus (Homework, Quiz, Exam) | `sch_classes`, `sch_sections`, `sch_subjects`, `sch_teachers`, `sch_class_sections` |
| Student Management | `sch_classes`, `sch_class_sections`, `sch_sections`, `sch_categories`, `sch_disable_reasons` |
| Student Fee | `sch_class_sections`, `sch_categories` |
| Library | `sch_class_sections` (for book allocation) |
| Transport | `sch_organizations` (school address as origin) |
| Recommendation | `sch_classes`, `sch_subjects`, `sch_teachers` |
| Complaint | `sch_departments`, `sch_employees`, `sch_organizations` |
| Vendor Management | `sch_organizations` |
| HPC (Report Cards) | `sch_class_sections`, `sch_students`, `sch_subjects` |
| Notification | `sch_organizations` (school settings for SMS/email) |
| Audit | `sch_organizations` (context identifier) |

---

## 12. Browser Tests (Existing)

9 browser tests exist in `/tests/Browser/Modules/Class&SubjectMgmt/`:

These use Laravel Dusk for end-to-end UI testing of the class and subject management flows. Test files cover:
1. Class creation flow
2. Section creation and assignment to class
3. Subject creation
4. Subject type management
5. Study format management
6. Subject group creation
7. Class-section junction creation with teacher assignment
8. Subject-class mapping
9. Drag-and-drop reorder

---

## 13. Identified Gaps and Issues

### 13.1 Critical Security Issues

| Issue | Location | Impact |
|---|---|---|
| `is_super_admin` flag settable via `UserController::update()` — included in `$request->only([..., 'is_super_admin'])` | `UserController.php` line ~135 | Any admin user can escalate any user to super_admin via crafted PUT request |
| `RolePermissionController::destroy()` does not delete the role — only calls `$role->save()` | `RolePermissionController.php` | Deleted roles remain active, UI shows success but no deletion occurs |
| `PermissionSyncController` has no `Gate::authorize()` | `PermissionSyncController.php` | Any authenticated user can trigger permission reseed |

### 13.2 Architecture Issues

| Issue | Description | Priority |
|---|---|---|
| Zero service classes for 40 controllers | All business logic inline. SchoolClassController alone is 920 lines. EmployeeProfileController is 600 lines. No testable service layer. | HIGH |
| `SchoolSetupController` is a stub | The main hub controller has 4 empty methods: `coreConfiguration()`, `foundationSetup()`, `admissionStudentManagement()`, `operationManagement()` | MEDIUM |
| Backup files in controllers and models directories | 7+ dated backup files should be deleted | LOW |
| `LessonRequest` in SchoolSetup requests | Belongs in Syllabus module | LOW |
| `RoomRequest21_Nov.php` obsolete backup | Should be deleted | LOW |
| `QuestionType` model in SchoolSetup | Belongs in QuestionBank module | LOW |
| `PrmTenantPlan` and `PrmTenantPlanRate` models in SchoolSetup | These are Prime DB models, not SchoolSetup tenant models | LOW |
| `ClassSubgroupController` commented out in routes | Route group exists in routes/tenant.php but commented out — ClassSubgroupController is missing | MEDIUM |

### 13.3 Auth Gaps

| Controller | Unprotected Methods |
|---|---|
| `SchoolSetupController` | All methods (stub) |
| `SchoolClassController::index()` | Uses `Gate::any(...)  || abort(403)` — correct but multi-permission |
| `SubjectGroupSubjectController` | Partial auth coverage |
| `SubjectStudyFormatController` | Partial auth coverage |
| `SubjectClassMappingController` | Partial auth coverage |
| `DepartmentController` | Uses `prime.department.viewAny` — should be `school-setup.department.viewAny` |
| `EntityGroupController` | Partial auth |
| `EntityGroupMemberController` | Partial auth |

### 13.4 Naming Inconsistencies

| Issue | Example |
|---|---|
| Permission prefix mixing | `DepartmentController` uses `prime.department.*` while all others use `school-setup.*` |
| `Gate::any()` without `abort(403)` would silently fail | Two controllers use the `||abort(403)` pattern correctly; one does not |
| `Gate::authorize('school-setup.organization.store')` on `store()` duplicates the `Gate::authorize('school-setup.organization.create')` on `create()` | `OrganizationController` has separate store permission |

### 13.5 PHP Crash Risk

| Issue | Location | Impact |
|---|---|---|
| PHP string concatenation crash | Reported in MEMORY but specific file not confirmed in current code review — warrants verification | Runtime PHP error on specific controller method |

---

## 14. Permission Naming Convention (Target State)

Standard pattern: `school-setup.{entity}.{action}`

```
school-setup.organization.viewAny
school-setup.organization.view
school-setup.organization.create
school-setup.organization.update
school-setup.organization.delete
school-setup.organization.restore
school-setup.organization.forceDelete
school-setup.school-class.viewAny
school-setup.school-class.create
school-setup.school-class.update
school-setup.school-class.delete
school-setup.school-class.restore
school-setup.school-class.forceDelete
school-setup.section.viewAny
school-setup.section.create
school-setup.section.update
school-setup.section.delete
school-setup.subject.viewAny
school-setup.subject.create
school-setup.subject.update
school-setup.subject.delete
school-setup.subject-type.viewAny
school-setup.subject-type.create
school-setup.subject-type.update
school-setup.subject-type.delete
school-setup.study-format.viewAny
school-setup.study-format.create
school-setup.study-format.update
school-setup.study-format.delete
school-setup.subject-group.viewAny
school-setup.subject-group.create
school-setup.subject-group.update
school-setup.subject-group.delete
school-setup.building.viewAny
school-setup.building.create
school-setup.building.update
school-setup.building.delete
school-setup.building.restore
school-setup.building.forceDelete
school-setup.room-type.viewAny
school-setup.room-type.create
school-setup.room-type.update
school-setup.room-type.delete
school-setup.room-type.restore
school-setup.room-type.forceDelete
school-setup.room.viewAny
school-setup.room.create
school-setup.room.update
school-setup.room.delete
school-setup.room.restore
school-setup.room.forceDelete
school-setup.employee.viewAny
school-setup.employee.create
school-setup.employee.update
school-setup.employee.delete
school-setup.employee.restore
school-setup.employee.forceDelete
school-setup.teacher.viewAny
school-setup.teacher.create
school-setup.teacher.update
school-setup.teacher.delete
school-setup.teacher.restore
school-setup.teacher.forceDelete
school-setup.user.viewAny
school-setup.user.create
school-setup.user.update
school-setup.user.delete
school-setup.user.restore
school-setup.user.forceDelete
school-setup.role-permission.viewAny
school-setup.role-permission.create
school-setup.role-permission.update
school-setup.role-permission.delete
school-setup.department.viewAny
school-setup.department.create
school-setup.department.update
school-setup.department.delete
school-setup.designation.viewAny
school-setup.designation.create
school-setup.designation.update
school-setup.designation.delete
```

---

## 15. Development Work Remaining

### Priority 1 — Security Fixes
1. Remove `is_super_admin` from `UserController::update()` `$request->only([...])` list — this field must only be set via a dedicated admin-level action with a higher-privilege gate check
2. Fix `RolePermissionController::destroy()` to actually delete the role: `$role->delete()`
3. Add `Gate::authorize()` to `PermissionSyncController::sync()`
4. Fix `DepartmentController` permission prefix from `prime.department.*` to `school-setup.department.*`

### Priority 2 — Architecture
5. Extract `SchoolClassController` business logic into `SchoolSetupService`:
   - `createClass(array $data): SchoolClass`
   - `saveClassSections(SchoolClass $class, array $sections): void`
   - `updateStudentCounts(): void`
   - `reorderEntity(string $module, int $itemId, int $oldIndex, int $newIndex): void`
6. Extract `EmployeeProfileController` logic into `EmployeeService`:
   - `createEmployeeFromUser(User $user, array $data): Employee`
   - `addTeacherProfile(Employee $employee, array $data): Teacher`
   - `syncTeacherSubjects(Teacher $teacher, array $subjects): void`
7. Create `TeacherService`:
   - `getTeacherTimetableGrid(Teacher $teacher, ?Timetable $timetable): array`
   - `calculateWorkloadStats(Teacher $teacher, int $totalPeriods): array`

### Priority 3 — Cleanup
8. Delete all dated backup files from controllers and models directories
9. Move `QuestionType` model to QuestionBank module
10. Move `PrmTenantPlan` / `PrmTenantPlanRate` to Prime module
11. Move `LessonRequest` to Syllabus module
12. Delete `RoomRequest21_Nov.php` and `StudentRequest_Backup_04_12_2025.php`
13. Implement (or remove) `SchoolSetupController::coreConfiguration()`, `foundationSetup()`, `admissionStudentManagement()`, `operationManagement()`
14. Fix or remove commented-out ClassSubgroupController routes

### Priority 4 — Missing CRUD Completions
15. Add `Gate::authorize()` to all unprotected methods in: `SubjectGroupSubjectController`, `SubjectStudyFormatController`, `SubjectClassMappingController`, `EntityGroupController`, `EntityGroupMemberController`
16. Implement `UserController::usersByRole()` actual query filter (currently shows all users regardless of role parameter)
17. Standardize `OrganizationController` to use single `school-setup.organization.create` permission on both `create()` and `store()` (remove redundant `school-setup.organization.store`)

### Priority 5 — Features
18. Create school-wide dashboard showing: total classes, total students, total teachers, total staff, pending academic session setup
19. Implement bulk student count refresh as a scheduled job (rather than manual URL hit)
20. Add teacher workload summary to `DepartmentController` index (aggregate by dept)

---

## 16. Testing Requirements

### Existing Tests
9 browser tests in `tests/Browser/Modules/Class&SubjectMgmt/`

### Unit Tests Needed
- `SchoolClassServiceTest` — class creation with sections, reorder logic
- `TeacherServiceTest` — subject sync, timetable grid building
- `EmployeeServiceTest` — employee creation, teacher profile linkage

### Feature Tests Needed
- `OrganizationControllerTest` — full CRUD lifecycle, city cascade, board sync
- `UserControllerSecurityTest` — verify `is_super_admin` is NOT settable via PUT
- `RolePermissionControllerTest` — create role, assign permissions, group update, destroy
- `SchoolClassControllerTest` — AJAX JSON create/update/delete, ordinal reorder
- `EmployeeProfileControllerTest` — create employee, add profile, add teacher profile

---

## 17. Completion Criteria

The module is considered complete when:

1. **Security:** `is_super_admin` privilege escalation vulnerability is fixed
2. **Security:** `RolePermissionController::destroy()` actually deletes the role
3. **Security:** All controllers have proper `Gate::authorize()` on every action
4. **Architecture:** Business logic extracted into at least `SchoolSetupService`, `EmployeeService`, `TeacherService`
5. **Cleanup:** All backup/dated files removed from controllers and models directories
6. **Completeness:** All 40 controllers have working create/read/update/delete operations
7. **Auth Consistency:** All permissions follow `school-setup.{entity}.{action}` pattern
8. **Testing:** Unit tests for service classes; feature tests for all critical controllers
9. **Documentation:** Permission seeder is up-to-date with all `school-setup.*` permissions
10. **Cascade Integrity:** SchoolClass delete/restore correctly cascades to ClassSection in all cases
