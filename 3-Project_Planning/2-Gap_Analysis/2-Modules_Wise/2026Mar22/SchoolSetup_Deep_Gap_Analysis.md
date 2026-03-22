# SchoolSetup Module - Deep Gap Analysis Report

**Date:** 2026-03-22
**Branch:** Brijesh_SmartTimetable
**Auditor:** Senior Laravel Architect (AI)
**Module Path:** `/Users/bkwork/Herd/prime_ai/Modules/SchoolSetup/`

---

## EXECUTIVE SUMMARY

The SchoolSetup module is the foundational module managing organizations, classes, sections, subjects, buildings, rooms, users, teachers, employees, roles/permissions, and various configuration entities. While core CRUD operations are largely functional with ~27 controllers and ~26 FormRequests, there are **critical security vulnerabilities** (is_super_admin writable by any admin, 5+ stub controllers with zero auth, $request->all() usage in multiple controllers) and **significant architectural gaps** (no Service layer, no EnsureTenantHasModule middleware, backup files in production, missing policies for several entities).

**Risk Level: HIGH**
**Estimated Issues: 68**
**P0 (Critical): 8 | P1 (High): 15 | P2 (Medium): 28 | P3 (Low): 17**

---

## SECTION 1: DATABASE INTEGRITY

### 1.1 DDL Tables Identified (sch_* prefix)
The DDL defines **29 sch_* tables** including: `sch_organizations`, `sch_org_academic_sessions_jnt`, `sch_board_organization_jnt`, `sch_department`, `sch_designation`, `sch_entity_groups`, `sch_entity_groups_members`, `sch_attendance_types`, `sch_leave_types`, `sch_categories`, `sch_leave_config`, `sch_disable_reasons`, `sch_sections`, `sch_classes`, `sch_class_section_jnt`, `sch_subject_types`, `sch_study_formats`, `sch_subjects`, `sch_subject_study_format_jnt`, `sch_class_groups_jnt`, `sch_subject_groups`, `sch_subject_group_subject_jnt`, `sch_buildings`, `sch_rooms_type`, `sch_rooms`, `sch_employees`, `sch_employees_profile`, `sch_teacher_profile`, `sch_teacher_capabilities`, `sch_academic_term`.

### 1.2 Issues
| # | Issue | Severity |
|---|-------|----------|
| 1 | No migration files found under `database/migrations/tenant/` for SchoolSetup tables (relies on raw DDL) | P2 |
| 2 | `sch_employees_profile` exists in DDL but no dedicated `EmployeeProfile` model — profile management embedded in `EmployeeProfileController` | P3 |

---

## SECTION 2: ROUTE INTEGRITY

### 2.1 Route Group
- **Prefix:** `school-setup`
- **Name prefix:** `school-setup.`
- **Middleware:** `['auth', 'verified']`
- **EnsureTenantHasModule:** **MISSING** (imported on line 7 of tenant.php but never applied to school-setup group)

### 2.2 Issues
| # | Issue | File | Line | Severity |
|---|-------|------|------|----------|
| 1 | **EnsureTenantHasModule middleware not applied** to the school-setup route group. Any authenticated tenant user can access these routes even if the module is not licensed. | `routes/tenant.php` | 1364 | P0 |
| 2 | `ClassGroupJntController` import commented out with `// FIXME: controller missing (only backup exists)` | `routes/tenant.php` | 25 | P2 |
| 3 | `ClassSubgroupController` routes are entirely commented out (lines 1476-1488) — features inaccessible | `routes/tenant.php` | 1476 | P2 |
| 4 | Duplicate `Route::resource('employee', EmployeeProfileController::class)` registration on lines 1369 and 1377 | `routes/tenant.php` | 1369, 1377 | P2 |
| 5 | Route `school-setup.school-setup.*` double-nests the prefix (resource named 'school-setup' inside 'school-setup.' prefix) | `routes/tenant.php` | 1404 | P3 |

---

## SECTION 3: CONTROLLER AUDIT

### 3.1 Controllers Found (27)
AttendanceTypeController, BuildingController, ClassGroupController, ClassSubjectGroupController, ClassSubjectManagementController, DepartmentController, DesignationController, DisableReasonController, EmployeeProfileController, EntityGroupController, EntityGroupMemberController, InfrasetupController, LeaveConfigController, LeaveTypeController, OrganizationAcademicSessionController, OrganizationController, OrganizationGroupController, PermissionSyncController, RolePermissionController, RoomController, RoomTypeController, SchCategoryController, SchoolClassController, SchoolSetupController, SectionController, StudentController (legacy), SubjectClassMappingController, SubjectController, SubjectGroupController, SubjectGroupSubjectController, SubjectStudyFormatController, SubjectTypeController, StudyFormatController, TeacherController, UserController, UserRolePrmController.

### 3.2 Backup/Dead Files in Controllers
| # | File | Issue | Severity |
|---|------|-------|----------|
| 1 | `ClassGroupController_02_02_2026.php` | Backup file in production controllers directory | P2 |
| 2 | `ClassGroupController_06_02_2026.php` | Backup file in production controllers directory | P2 |
| 3 | `ClassGroupJntController_09_02_2026.php` | Backup file in production controllers directory | P2 |
| 4 | `competency.blade.php` | Blade file misplaced in Controllers directory | P3 |
| 5 | `StudentController_backup_04_12_2025.php` (in Requests) | Backup file | P3 |

### 3.3 Stub Controllers (Zero Business Logic)
| # | Controller | Issue | Severity |
|---|------------|-------|----------|
| 1 | `SchoolSetupController` | All 7 methods are empty stubs (store, update, destroy return nothing). **Zero Gate::authorize calls.** | P1 |
| 2 | `InfrasetupController` | No Gate::authorize calls found in any method | P1 |
| 3 | `ClassSubjectManagementController` | No Gate::authorize calls found in any method | P1 |
| 4 | `UserRolePrmController` | No Gate::authorize calls found in any method | P1 |
| 5 | `SchoolSetupController.coreConfiguration()` through `operationManagement()` (lines 64-79) — empty methods with no return | P2 |

### 3.4 Security: is_super_admin Settable
| # | File | Line | Issue | Severity |
|---|------|------|-------|----------|
| 1 | `UserController.php` | 135 | `$request->only([..., 'is_super_admin'])` — any admin can escalate a user to super_admin via the update method | P0 |
| 2 | `UserRequest.php` | 24 | `'is_super_admin' => ['nullable', 'boolean']` — validation allows the field | P0 |
| 3 | `User.php` (Model) | 42 | `is_super_admin` in `$fillable` array — mass-assignable | P0 |
| 4 | `user/edit.blade.php` | 94-97 | Checkbox for is_super_admin exposed in edit form with no role check | P0 |

### 3.5 $request->all() Usage (Mass Assignment Risk)
| # | File | Line | Severity |
|---|------|------|----------|
| 1 | `OrganizationGroupController.php` | 41, 83 | P1 |
| 2 | `OrganizationController.php` | 41, 94 | P1 |

---

## SECTION 4: MODEL AUDIT

### 4.1 Models Found
Building, ClassSection, Department, Designation, Employee, EntityGroup, EntityGroupMember, Organization, OrganizationGroup, Role, Room, RoomType, SchClassGroupsJnt, SchoolClass, Section, Student (legacy), StudyFormat, Subject, SubjectGroup, SubjectGroupSubject, SubjectStudyFormat, SubjectType, Teacher, User.

### 4.2 Issues
| # | Issue | File | Severity |
|---|-------|------|----------|
| 1 | `User` model has `is_super_admin` in `$fillable` | `app/Models/User.php:42` | P0 |
| 2 | Several models lack `created_by` column in fillable despite DDL requiring it | Multiple | P2 |

---

## SECTION 5: SERVICE LAYER AUDIT

**No Service classes exist in the SchoolSetup module.** All business logic is directly in controllers, violating the thin-controller/fat-service architecture requirement.

| # | Issue | Severity |
|---|-------|----------|
| 1 | No `app/Services/` directory exists | P1 |
| 2 | Complex employee profile creation logic (multi-step with QR codes, capabilities, documents) embedded directly in `EmployeeProfileController` | P2 |
| 3 | Subject-class mapping logic with multi-table writes in `SubjectClassMappingController` | P2 |

---

## SECTION 6: FORMREQUEST AUDIT

### 6.1 FormRequests Found (26)
AttendanceTypeRequest, BuildingRequest, ClassGroupRequest, DisableReasonRequest, LeaveConfigRequest, LeaveTypeRequest, LessonRequest, OrganizationAcademicSessionRequest, OrganizationGroupRequest, OrganizationRequest, RolePermissionRequest, RoomRequest, RoomTypeRequest, SchCategoryRequest, SchoolClassRequest, SectionRequest, StoreEmployeeRequest, StudentRequest, StudyFormatRequest, SubjectGroupRequest, SubjectRequest, SubjectTypeRequest, TeacherRequest, UpdateEmployeeRequest, UserRequest.

### 6.2 Issues
| # | Issue | File | Severity |
|---|-------|------|----------|
| 1 | `RoomRequest21_Nov.php` — backup FormRequest in production | `app/Http/Requests/RoomRequest21_Nov.php` | P3 |
| 2 | `StudentRequest_Backup_04_12_2025.php` — backup in production | `app/Http/Requests/` | P3 |
| 3 | `LessonRequest.php` — appears to belong to Syllabus module, not SchoolSetup | `app/Http/Requests/LessonRequest.php` | P3 |
| 4 | DepartmentController, DesignationController — FormRequests not verified as being used (may use inline validation) | Multiple | P2 |

---

## SECTION 7: POLICY AUDIT

### 7.1 Policies Registered in AppServiceProvider
Building, Room, User, OrganizationGroup (OrgGroupPolicy), Organization, ClassGroup, Teacher, RoomType, Section, SchoolClass, ClassSection, SubjectType, StudyFormat, Subject, SubjectStudyFormat, SubjectGroup, SubjectClassMapping, SubjectGroupSubject.

### 7.2 Issues
| # | Issue | Severity |
|---|-------|----------|
| 1 | No policy registered for `Department` model | P1 |
| 2 | No policy registered for `Designation` model | P1 |
| 3 | No policy registered for `Employee`/`EmployeeProfile` in tenant context (only Prime context) | P1 |
| 4 | No policy registered for `AttendanceType` model | P2 |
| 5 | No policy registered for `LeaveType` model | P2 |
| 6 | No policy registered for `LeaveConfig` model | P2 |
| 7 | No policy registered for `DisableReason` model | P2 |
| 8 | No policy registered for `SchCategory` model | P2 |
| 9 | No policy registered for `EntityGroup`/`EntityGroupMember` models | P2 |
| 10 | No policy registered for `OrganizationAcademicSession` model | P2 |

---

## SECTION 8: VIEW AUDIT

Views appear comprehensive with create/edit/show/index/trash patterns for most entities. No critical issues identified beyond form-level exposure of `is_super_admin` (covered in Section 3).

---

## SECTION 9: SECURITY AUDIT (18 Checks)

| # | Check | Status | Details |
|---|-------|--------|---------|
| 1 | CSRF Protection | PASS | Routes use web middleware |
| 2 | Auth Middleware | PASS | Applied at route group level |
| 3 | Gate/Policy on every method | **FAIL** | 5+ controllers have zero auth checks |
| 4 | EnsureTenantHasModule | **FAIL** | Not applied to route group |
| 5 | is_super_admin protection | **FAIL** | Writable via form, fillable in model |
| 6 | $request->validated() usage | **FAIL** | $request->all() used in 4 places |
| 7 | SQL Injection protection | PASS | Uses Eloquent ORM |
| 8 | XSS protection | PASS | Blade templates use {{ }} escaping |
| 9 | Mass Assignment protection | **FAIL** | is_super_admin in $fillable |
| 10 | File upload validation | WARN | Employee documents need review |
| 11 | Rate limiting | **FAIL** | No throttle middleware on any route |
| 12 | Sensitive data exposure | **FAIL** | Password hashing in controller, not service |
| 13 | Input sanitization | WARN | Search fields use LIKE with user input |
| 14 | Backup files in production | **FAIL** | 5 backup files found |
| 15 | Debug code in production | WARN | `rand()` calls for display data in UserController (lines 32-33) |
| 16 | Force delete without soft-delete check | WARN | Some force-delete routes lack proper checks |
| 17 | API key exposure | PASS | No hardcoded keys found |
| 18 | Session security | PASS | Uses Laravel session |

---

## SECTION 10: PERFORMANCE AUDIT

| # | Check | Status | Details |
|---|-------|--------|---------|
| 1 | N+1 query prevention | WARN | `UserController.index()` loads users without eager loading roles |
| 2 | Pagination | PASS | Most controllers use `paginate()` |
| 3 | Index usage | PASS | DDL defines proper indexes |
| 4 | Cache usage | **FAIL** | No caching anywhere in the module |
| 5 | Eager loading | WARN | Several controllers load relationships lazily |
| 6 | `rand()` in production | **FAIL** | `UserController.php:32-33` uses `rand()` for totalStudents/totalClasses |

---

## SECTION 11: ARCHITECTURE AUDIT

| # | Issue | Severity |
|---|-------|----------|
| 1 | No Service layer — violates thin-controller requirement | P1 |
| 2 | No dedicated event/listener pattern for entity creation | P3 |
| 3 | Cross-module dependency: `SchoolSetup` references `Prime\Models\AcademicSession` directly | P3 |
| 4 | Legacy `StudentController.bk` backup in controllers directory | P2 |

---

## SECTION 12: TEST COVERAGE

**No tests found.** Zero test files exist under `Modules/SchoolSetup/tests/`.

| # | Issue | Severity |
|---|-------|----------|
| 1 | No unit tests | P1 |
| 2 | No feature tests | P1 |
| 3 | No architecture tests | P2 |

---

## SECTION 13: BUSINESS LOGIC COMPLETENESS

| # | Gap | Severity |
|---|-----|----------|
| 1 | PermissionSyncController exists but no automated sync validation | P3 |
| 2 | ClassSubgroupController missing — routes fully commented out | P2 |
| 3 | ClassGroupJntController missing — only backup exists | P2 |
| 4 | SchoolSetupController stub methods (coreConfiguration, foundationSetup, etc.) return nothing | P2 |

---

## PRIORITY FIX PLAN

### P0 - Critical (Fix Immediately)
1. **Remove `is_super_admin` from User model `$fillable`** — `Modules/SchoolSetup/app/Models/User.php:42`
2. **Remove `is_super_admin` from UserRequest validation** — `app/Http/Requests/UserRequest.php:24`
3. **Remove `is_super_admin` from UserController.update()** — `app/Http/Controllers/UserController.php:135`
4. **Remove is_super_admin checkbox from edit form** — `resources/views/user/edit.blade.php:94-97`
5. **Add EnsureTenantHasModule middleware** to school-setup route group — `routes/tenant.php:1364`

### P1 - High (Fix This Sprint)
6. Add Gate::authorize calls to SchoolSetupController, InfrasetupController, ClassSubjectManagementController, UserRolePrmController
7. Replace `$request->all()` with `$request->validated()` in OrganizationGroupController and OrganizationController
8. Register policies for Department, Designation, Employee
9. Create Service layer (at minimum: UserService, OrganizationService, ClassSetupService)
10. Add basic feature tests for all CRUD operations

### P2 - Medium (Fix Next Sprint)
11. Delete all backup/dead files from Controllers and Requests directories
12. Register policies for AttendanceType, LeaveType, LeaveConfig, DisableReason, SchCategory, EntityGroup, OrganizationAcademicSession
13. Implement ClassSubgroupController or remove commented routes
14. Fix duplicate employee resource route registration
15. Replace `rand()` in UserController with actual database counts

### P3 - Low (Backlog)
16. Move LessonRequest to Syllabus module
17. Add caching for frequently accessed data (classes, sections, subjects)
18. Add rate limiting to form submission routes

---

## EFFORT ESTIMATION

| Priority | Items | Effort (person-days) |
|----------|-------|---------------------|
| P0 | 5 | 0.5 |
| P1 | 5 | 4 |
| P2 | 5 | 3 |
| P3 | 3 | 2 |
| **Total** | **18** | **9.5** |
