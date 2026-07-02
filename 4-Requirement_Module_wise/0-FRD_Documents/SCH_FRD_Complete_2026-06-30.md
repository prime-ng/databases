# SchoolSetup Module — Complete Analysis Pack
# Prime-AI School ERP Platform

| Field | Value |
|-------|-------|
| **Module Name** | SchoolSetup |
| **Module Code** | SCH |
| **Document Version** | 1.0 |
| **Date** | 2026-06-30 |
| **Status** | Draft |
| **Analysis Mode** | Complete Analysis Pack (10 Artifacts) |
| **Author** | Business Analyst — Prime-AI AI Brain |
| **FRD Reference** | `SCH_FRD_2026-06-30.md` (same directory — read it first) |
| **Prior Sub-domain FRD** | `SCO_FRD_Complete_2026-06-29.md` (CoreSetup only — superseded in scope) |
| **Module Knowledge File** | `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/SCH_SchoolSetup.md` |
| **Codebase Path** | `/Users/bkwork/Herd/prime_ai/Modules/SchoolSetup/` |

> **How to read this pack:** Start with the FRD (`SCH_FRD_2026-06-30.md`) for requirement definitions. This pack adds the nine analytical layers that the FRD defers to. All REQ-SCH-NNN, BR-SCH-NNN, RPT-SCH-NNN, and ENH-SCH-NNN identifiers referenced below resolve to the FRD.

---

## Section 1 — Executive Summary and Coverage Map

### 1.1 Module at a Glance

SchoolSetup is the most critical module in the Prime-AI platform — it is the structural skeleton that every other module depends on. No timetable, no fee, no LMS, no HPC, and no report card can function without a correctly configured SchoolSetup. It is the only module that owns the user account and role/permission system, making it the security foundation of the entire tenant instance.

The module has grown significantly beyond its V2 specification (March 2026). V2 documented 30 DDL tables, 36 controllers, and 0 services. The current codebase contains 52 confirmed sch_* migrations, 56+ active controllers, 3 services, and 29 seeders — the gap is entirely attributable to the post-V2 addition of the Employee Leave Management and Employee Attendance sub-domains.

### 1.2 Module Statistics (Verified 2026-06-30)

| Dimension | Count | Source |
|-----------|-------|--------|
| DDL Tables (sch_*) | 52 | `database/migrations/tenant/` |
| Sub-domains | 4 (SCO / SCC / SCI / SCE) | module-knowledge |
| Active Controller Files | 56 | `app/Http/Controllers/` directory |
| Total PHP Files under Controllers/ | 60 | includes Mobile/, Api/, misplaced files |
| Models | 61 | `app/Models/` directory |
| Form Requests | 26 | `app/Http/Requests/` |
| Policy Files | 44 (38 registered, 5 unregistered, 4 missing) | `app/Policies/` |
| Services | 3 | `app/Services/` |
| Artisan Console Commands | 4 | `app/Console/Commands/` |
| Seeders | 29 | `database/seeders/` |
| Views | ~336 | `resources/views/` |
| Routes (route lines) | ~823 | `routes/tenant.php` |
| Test Files | 0 | — |

### 1.3 Overall Implementation Completion

| Sub-domain | Estimated Completion | Key Completions | Key Gaps |
|-----------|---------------------|-----------------|----------|
| SCO (CoreSetup) | ~70% | Org profile, sessions, holidays, shifts fully CRUD | Academic terms partial; sch_configs UI stub |
| SCC (ClassSetup) | ~80% | Grades, sections, subjects, class-groups, drag-reorder all complete | Class-subject mapping UI edge cases; subject group reports missing |
| SCI (InfraSetup) | ~90% | Buildings, room types, rooms all complete | Room availability calendar not built |
| SCE (EmployeeSetup) | ~45% | Employee CRUD, teacher profile, user accounts, roles, permissions built | Leave approval auto-timeout job missing; attendance correction UI partial; 0 reports; lifecycle management stub |
| **Overall** | **~62%** | Core structural config complete | Leave/attendance workflow incomplete; 0 tests; no service layer |

### 1.4 Coverage Map (10 Artifacts)

| # | Artifact | Section |
|---|---------|---------|
| 1 | Requirements Traceability Matrix | Section 2 |
| 2 | Business Rules Register + Conditions Catalog + Validation Catalog | Section 3 |
| 3 | Process Flow Catalog + FSM Catalog | Section 4 |
| 4 | Data Dictionary + Cross-Module Dependency Map | Section 5 |
| 5 | NFR Catalog + Risk Register | Section 6 |
| 6 | Prioritization + Effort Estimation + Sprint Task Map | Section 7 |
| 7 | User Stories Catalog + KPI Specification | Section 8 |
| 8 | Feature Specification (Screen-by-Screen) | Section 9 |
| 9 | Gap Analysis Summary | Section 10 |
| 10 | Module Knowledge Update Notes | Section 11 |

---

## Section 2 — Requirements Traceability Matrix (RTM)

| Req ID | Feature | Priority | FRD Section | Controller(s) | Model(s) | Policy | Migration(s) | Test Status | Gap |
|--------|---------|---------|-------------|---------------|---------|--------|-------------|-------------|-----|
| REQ-SCH-001 | Organization Profile | P0 | 3.1 | OrganizationController, OrganizationBoardController | Organization, SchOrganizationBoard | OrganizationPolicy | sch_organizations, sch_organization_boards, sch_org_board_affiliations | Not written | No critical gap — minor: no media delete cleanup |
| REQ-SCH-002 | Organization Groups | P1 | 3.2 | OrganizationGroupController | OrganizationGroup | OrganizationGroupPolicy | sch_organization_groups | Not written | None |
| REQ-SCH-003 | Academic Session Mapping | P0 | 3.3 | OrganizationAcademicSessionController | OrganizationAcademicSession | OrgAcademicSessionPolicy | sch_org_academic_sessions | Not written | P1: controller has empty Blade stubs (AJAX only — but stubs should be removed) |
| REQ-SCH-021 | Academic Term Config | P1 | 3.4 | OrganizationAcademicTermController | OrganizationAcademicTerm | OrgAcademicTermPolicy | sch_org_academic_terms | Not written | None |
| REQ-SCH-005 | Holiday Calendar | P1 | 3.5 | HolidayController, AnnualLeaveSessionController | Holiday, AnnualLeaveSession | HolidayPolicy, AnnualLeaveSessionPolicy | sch_holidays, sch_annual_leave_sessions | Not written | None |
| REQ-SCH-006 | Grade Management | P0 | 3.6 | SchoolClassController | SchoolClass | SchoolClassPolicy | sch_school_classes | Not written | None — AJAX pattern verified |
| REQ-SCH-007 | Section Management | P0 | 3.7 | SectionController | Section | SectionPolicy | sch_sections | Not written | None |
| REQ-SCH-008 | Class-Section Config | P0 | 3.8 | SchoolClassController (extends) | SchoolClassSection, ClassSection | ClassSectionPolicy | sch_school_class_sections | Not written | None |
| REQ-SCH-009 | Subject Management | P0 | 3.9 | SubjectController, SubjectTypeController, StudyFormatController, SubjectStudyFormatController | Subject, SubjectType, StudyFormat, SubjectStudyFormat | SubjectPolicy, SubjectTypePolicy, StudyFormatPolicy | sch_subjects, sch_subject_types, sch_study_formats, sch_subject_study_formats | Not written | None |
| REQ-SCH-010 | Subject Groups & Class-Subject Map | P1 | 3.10 | SubjectGroupController, ClassGroupController | SubjectGroup, SubjectGroupSubject, ClassGroup | SubjectGroupPolicy, ClassGroupPolicy | sch_subject_groups, sch_subject_group_subjects, sch_class_groups | Not written | None |
| REQ-SCH-011 | Infrastructure | P1 | 3.11 | BuildingController, RoomTypeController, RoomController | Building, RoomType, Room | BuildingPolicy, RoomTypePolicy, RoomPolicy | sch_buildings, sch_room_types, sch_rooms | Not written | None |
| REQ-SCH-012 | Departments & Designations | P1 | 3.12 | DepartmentController, DesignationController | Department, Designation | DepartmentPolicy, DesignationPolicy | sch_departments, sch_designations | Not written | None |
| REQ-SCH-013 | Employee Records | P0 | 3.13 | EmployeeController, EmployeeDocumentController, EmployeeCardController | Employee, EmployeeDocument | EmployeePolicy, EmployeeDocumentPolicy | sch_employees, sch_employee_documents | Not written | P1: bank details may not be encrypted; P1: emergency contact JSON column unconfirmed |
| REQ-SCH-014 | Teacher Profile & Capabilities | P0 | 3.14 | TeacherProfileController, TeacherCapabilityController | TeacherProfile, TeacherCapability | TeacherProfilePolicy, TeacherCapabilityPolicy | sch_teacher_profiles, sch_teacher_capabilities | Not written | P1: force-delete/recreate pattern on capability update — silent data loss potential |
| REQ-SCH-015 | User Account Management | P0 | 3.15 | UserController | User | UserPolicy | (uses sys_users / central users table) | Not written | P1: UserController statistics using placeholder counts; P0: is_super_admin in $fillable |
| REQ-SCH-016 | Role & Permission Management | P0 | 3.16 | RoleController | Role (Spatie) | RolePolicy | (uses Spatie permission tables) | Not written | P1: 4 permissions missing from registration; 5 policies unregistered |
| REQ-SCH-017 | HR Config Masters | P1 | 3.17 | AttendanceTypeController, LeaveTypeController, LeaveEntitlementController, AnnualShiftController | AttendanceType, LeaveType, LeaveEntitlementConfig, AnnualShift | various | sch_attendance_types, sch_leave_types, sch_leave_entitlement_configs, sch_annual_shifts, sch_annual_shift_days | Not written | None |
| REQ-SCH-018 | Leave Approval Policies | P1 | 3.18 | LeaveApprovalPolicyController, PolicyLevelController | LeaveApprovalPolicy, LeaveApprovalPolicyLevel, LeaveApprovalPolicyLevelApprover | LeaveApprovalPolicyPolicy | sch_leave_approval_policies, sch_leave_approval_policy_levels, sch_leave_approval_policy_level_approvers | Not written | None — DDL correct |
| REQ-SCH-019 | Employee Leave Management | P1 | 3.19 | LeaveApplicationController, LeaveApprovalController | LeaveApplication, LeaveApprovalRecord, LeaveApprovalRemark | LeaveApplicationPolicy | sch_leave_applications, sch_leave_approval_records, sch_leave_approval_remarks | Not written | P1: auto-timeout cron job not implemented; P1: withdrawal logic incomplete |
| REQ-SCH-020 | Employee Attendance Tracking | P1 | 3.20 | EmployeeAttendanceController, BiometricPunchController, AttendanceCorrectionController | EmployeeAttendance, EmployeeBiometricPunch, AttendanceCorrection | EmployeeAttendancePolicy | sch_employee_attendance, sch_employee_biometric_punches, sch_attendance_corrections | Not written | P1: correction approval UI partial; no status derivation service |
| REQ-SCH-023 | Employee Lifecycle | P2 | 3.21 | EmployeeRoleHistoryController, EmployeeSeparationController | EmployeeRoleHistory, EmployeeSeparation | — (policies missing) | sch_employee_role_history, sch_employee_separations | Not written | P2: lifecycle controllers are stubs; separation user-deactivation trigger not wired |
| REQ-SCH-024 | Entity Groups | P1 | 3.22 | EntityGroupController, EntityGroupMemberController | EntityGroup, EntityGroupMember | EntityGroupPolicy | sch_entity_groups, sch_entity_group_members | Not written | P0: sch_entity_group_members migration MISSING — feature silently broken in production |
| REQ-SCH-025 | Dropdown Management | P0 | 3.23 | DropdownValueController | DropdownValue (sys_dropdowns — cross-DB) | DropdownValuePolicy | sys_dropdowns (GlobalDB) | Not written | P2: cross-DB read pattern — must use global connection |
| REQ-SCH-026 | School Config Values | P1 | 3.24 | SchoolConfigController | SchoolConfig | SchoolConfigPolicy | sch_configs | Not written | P2: UI is stub; no form to edit values from school-level UI |
| REQ-SCH-027 | Employee Reports | P2 | 3.25 | EmployeeReportController | (reads from multiple models) | — | — | Not written | P2: reports not implemented — only basic list views exist |
| REQ-SCH-028 | Permission Sync Utility | P2 | 3.26 | PermissionSyncController | Permission (Spatie) | — (super-admin only gate) | — | Not written | P2: implemented but super-admin gate needs explicit policy check |

**RTM Summary**
- Total REQs traced: 26
- REQs with P0 gaps: 4 (REQ-SCH-015, REQ-SCH-024, and shared REQ-SCH-016 / REQ-SCH-015 for super_admin fillable)
- REQs with P1 gaps: 9
- REQs with P2 gaps: 6
- REQs fully satisfied (no known gap): 11

---

## Section 3 — Business Rules Register, Conditions Catalog, and Validation Catalog

### 3.1 Business Rules Register

> Full 84-rule register is in the FRD Section 4. This section adds rule type classifications and cross-references for validation engineering.

| Rule ID | Validation Point | Validated By | Test Required? | Notes |
|---------|-----------------|-------------|---------------|-------|
| BR-SCH-001 | org profile create — block if record exists | DB constraint (UNIQUE flg_single_record) | Yes | Enforced at schema level; application must also guard |
| BR-SCH-009 | session mark-as-current — clear others | App logic in OrgAcademicSessionController | Yes | GENERATED STORED column current_flag with UNIQUE enforces at DB level |
| BR-SCH-018 | grade delete → cascade class-section deactivate | App logic in SchoolClassController::destroy() | Yes | Must verify cascades |
| BR-SCH-022 | section remove from grade → deactivate class-section | App logic | Yes | |
| BR-SCH-024 | class teacher one-per-section | App validation | Yes | |
| BR-SCH-026 | subject-study-format removal blocked if in use | App validation in SubjectStudyFormatController::destroy() | Yes | |
| BR-SCH-036 | employee code uniqueness | DB UNIQUE constraint | Yes | |
| BR-SCH-042 | one teacher profile per employee | DB UNIQUE constraint | Yes | |
| BR-SCH-045 | super-admin not writable by school admin | Must remove is_super_admin from $fillable; server must block | Yes — P0 | Currently in $fillable — CRITICAL |
| BR-SCH-049 | role delete physically removes assignments | App logic in RoleController::destroy() | Yes | |
| BR-SCH-060 | leave date overlap check | App validation in LeaveApplicationController::store() | Yes | Date range overlap query required |
| BR-SCH-064 | final approval triggers balance deduction + attendance update | App logic in LeaveApprovalController | Yes | |
| BR-SCH-075 | entity group delete blocked if notification refs exist | App validation | Yes | |
| BR-SCH-083 | permission sync — super admin only | Gate::authorize('super-admin') | Yes | |

### 3.2 Requirement Conditions Catalog

Conditions are the "given state / trigger / required outcome" triples used by developers and QA to cover non-happy-path behaviour.

#### REQ-SCH-003 (Academic Session Mapping)

| Condition ID | Given State | Trigger | Required Outcome |
|-------------|------------|---------|-----------------|
| COND-SCH-003-01 | No sessions exist | Admin creates first session and marks it current | Session is created and marked current; no other session is affected |
| COND-SCH-003-02 | Session A is current | Admin marks Session B as current | Session B becomes current; Session A's current flag is cleared |
| COND-SCH-003-03 | Session A is current, Session B overlaps dates | Admin tries to activate Session B | System rejects with "Date range overlaps with existing session" |
| COND-SCH-003-04 | Session A is current | Admin soft-deletes Session A | Session A is moved to trash; no session is current; system warns admin |
| COND-SCH-003-05 | Session A has board affiliations | Admin changes active session to Session B | Board affiliations remain on Session A; Session B affiliations are empty until configured |

#### REQ-SCH-006 (Grade Management)

| Condition ID | Given State | Trigger | Required Outcome |
|-------------|------------|---------|-----------------|
| COND-SCH-006-01 | Grade 5 has 3 class-sections (5A, 5B, 5C) | Admin deletes Grade 5 | Grade 5 and all 3 class-sections are soft-deleted; student enrollment records remain intact |
| COND-SCH-006-02 | Grade 5 is deleted | Admin restores Grade 5 | Grade 5 is restored; all 3 class-sections are restored to active |
| COND-SCH-006-03 | Grades 1–10 exist with ordinals 1–10 | Admin drags Grade 3 to position 7 | All affected ordinals are updated in a single transaction; list refreshes in new order |

#### REQ-SCH-014 (Teacher Capabilities)

| Condition ID | Given State | Trigger | Required Outcome |
|-------------|------------|---------|-----------------|
| COND-SCH-014-01 | Teacher has 5 capabilities configured | Admin saves updated capability list with 3 items | All 5 old records are deleted; 3 new records are created; no orphan records remain |
| COND-SCH-014-02 | Teacher capability list includes Physics-Lab for Grade 9 | Timetable Generator runs and assigns this teacher | Teacher capability priority used for slot preference ordering |
| COND-SCH-014-03 | Teacher has no capabilities | Admin tries to assign teacher to timetable manually | System warns that no capabilities are defined |

#### REQ-SCH-019 (Employee Leave Management)

| Condition ID | Given State | Trigger | Required Outcome |
|-------------|------------|---------|-----------------|
| COND-SCH-019-01 | Employee has 5 CL days balance | Employee applies for 3 CL days | Application created with status Pending; balance not yet reduced |
| COND-SCH-019-02 | Employee has 2 CL days balance | Employee applies for 3 CL days | System rejects with "Insufficient leave balance (2 days remaining)" |
| COND-SCH-019-03 | Application pending at Level 1 | Employee submits another application for overlapping dates | System rejects with "Leave dates overlap with a pending application" |
| COND-SCH-019-04 | Application pending at Level 1, approver has not acted for 24 hours | Auto-timeout job runs | Application advances to Level 2 without Level 1 action |
| COND-SCH-019-05 | Application approved at all levels | System finalises approval | Leave balance reduced by approved days; attendance records for those dates marked with the leave type |
| COND-SCH-019-06 | Application is pending at Level 1 | Employee clicks Withdraw | Application status set to Cancelled; no balance change; no further notifications |
| COND-SCH-019-07 | Application has been approved at Level 1 | Employee tries to withdraw | System blocks withdrawal with "Application is in progress — cannot be withdrawn" |
| COND-SCH-019-08 | Leave type requires medical certificate | Employee submits without document | System blocks submission with "Medical certificate is required for Sick Leave" |

#### REQ-SCH-024 (Entity Groups)

| Condition ID | Given State | Trigger | Required Outcome |
|-------------|------------|---------|-----------------|
| COND-SCH-024-01 | Entity group "Science Teachers" exists | Admin tries to add a member to it | SQLSTATE[42S02]: Table 'sch_entity_group_members' doesn't exist — production blocker |
| COND-SCH-024-02 | sch_entity_group_members migration deployed | Admin adds employee as member | Member record created; group usable in Notification module |
| COND-SCH-024-03 | Entity group referenced by active notification template | Admin tries to delete the group | System blocks deletion with "Group is referenced by [Template Name]" |

### 3.3 Validation and Edge-Case Catalog

| Field / Operation | Validation Rule | Edge Case | Error Message |
|------------------|----------------|-----------|---------------|
| Employee Code (REQ-SCH-013) | Required; max 20 chars; unique within school | Code with leading/trailing spaces | "Employee code must be unique within this school" |
| Leave Dates (REQ-SCH-019) | Start date must be before or equal to end date | Same-day application (start = end) | Allowed — treated as 1 day |
| Leave Dates (REQ-SCH-019) | Cannot overlap with existing pending or approved leave | Overlap by 1 day | "These dates overlap with a pending/approved leave application from [date] to [date]" |
| Leave Balance (REQ-SCH-019) | Requested days must not exceed remaining balance | Zero balance, 0-day application (backdating edge case) | "You do not have sufficient [leave type] balance" |
| Subject Code (REQ-SCH-009) | Required; max 10 chars; unique per school | Code same as deleted subject | Allowed (soft-deleted codes can be reused by new records) |
| Grade Reorder (REQ-SCH-006) | All ordinals must be positive integers; no duplicates | Tie in ordinal after failed partial save | System resolves by reassigning ordinals in database order |
| Teacher Capabilities (REQ-SCH-014) | At least one subject-grade capability required for timetable eligibility | Teacher with 0 capabilities saved | Allowed — system flags profile as incomplete for timetable |
| Role Delete (REQ-SCH-016) | Role must have 0 assigned users before deletion | Role assigned to 50 users | "Cannot delete role — 50 users are currently assigned to it. Reassign users first." |
| Department Delete (REQ-SCH-012) | Department must have 0 active employees | Department with 1 employee | "Cannot delete this department — 1 employee is assigned to it" |
| Academic Term Dates (REQ-SCH-021) | Terms in the same session must not overlap | Term 1 end = Term 2 start (adjacent, not overlapping) | Allowed |
| Config Value Type (REQ-SCH-026) | Value must match declared type (text/number/boolean/date/JSON) | Boolean field given "yes" instead of true/false | "Value must be true or false for this setting" |
| Room Capacity (REQ-SCH-011) | Must be positive integer | Capacity = 0 | "Room capacity must be at least 1" |
| Section Name (REQ-SCH-007) | Required; max 50 chars; unique within school | Duplicate section name different case (e.g., "a" vs "A") | Should normalise to uppercase; uniqueness check case-insensitive |

---

## Section 4 — Process Flow Catalog and Finite State Machine Catalog

### 4.1 Process Flows

> Detailed 6-workflow narrative flows are defined in the FRD (Section 6). This section provides the FSM diagrams and summarises the decision logic for the stateful workflows only.

#### Flow Summary

| Flow ID | Flow Name | Stateful? | Approvals? | Notifications? |
|---------|----------|----------|-----------|---------------|
| PF-SCH-001 | Employee Onboarding | No | No | Yes (ID card ready) |
| PF-SCH-002 | Academic Session Setup | No | No | No |
| PF-SCH-003 | Leave Application and Approval | Yes | Yes | Yes (each state change) |
| PF-SCH-004 | Class and Subject Setup | No | No | No |
| PF-SCH-005 | Employee Attendance Recording | Yes (correction sub-flow) | Yes (correction) | No |
| PF-SCH-006 | RBAC Configuration | No | No | No |

### 4.2 FSM — Leave Application

**Entity:** LeaveApplication
**State field:** `status` (ENUM in sch_leave_applications)

```
  [SUBMITTED]
      |
      | Level 1 Approver receives notification
      v
  [PENDING_L1]
      |
      +--[Approve]--> [PENDING_L2] (if policy has L2)
      |                   |
      |                   +--[Approve]--> [PENDING_Ln] ...
      |                   |
      |                   +--[Reject]--> [REJECTED]
      |                                      |
      |                                      v
      +--[Reject]--> [REJECTED]          [END — no balance change]
      |
      +--[Auto-timeout expires]--> [PENDING_L2]
      |
      +--[Final Level Approve]--> [APPROVED]
      |                                |
      |                                v
      |                          [balance deducted]
      |                          [attendance updated]
      |                          [END]
      |
      +--[Employee withdraws (only from PENDING_L1 before L1 acts)]
                                       |
                                       v
                                  [CANCELLED]
                                  [END — no balance change]
```

**Valid Transitions:**

| From State | Trigger | To State | Actor |
|-----------|---------|----------|-------|
| PENDING_L1 | Approver approves (L1 not final) | PENDING_L2 | L1 Approver |
| PENDING_Ln | Approver approves (Ln not final) | PENDING_L(n+1) | Ln Approver |
| PENDING_Ln | Approver approves (Ln is final) | APPROVED | Ln Approver (final) |
| PENDING_Ln | Approver rejects | REJECTED | Any Approver in chain |
| PENDING_L1 | Employee withdraws | CANCELLED | Employee (submitter) |
| PENDING_L1 | Auto-timeout expires | PENDING_L2 | System (CRON) |
| APPROVED | HR Officer reversal (admin) | PENDING_L1 | HR Officer (exceptional) |

**Invalid Transitions (must be blocked):**
- APPROVED → CANCELLED (system blocks)
- REJECTED → PENDING_L1 (re-submission creates new application)
- PENDING_L2+ → CANCELLED (withdrawal not allowed after first approval)

### 4.3 FSM — Employee Onboarding

**Entity:** Employee + User Account + TeacherProfile (composite)
**State:** Tracked by presence of linked records (no single status column — profile completion is derived)

```
  [USER_ACCOUNT_CREATED]
      |
      v
  [EMPLOYEE_RECORD_CREATED]
      |
      v
  [EMPLOYEE_PROFILE_ADDED]  (dept, designation, role, shift, work hours)
      |
      +--[is_teacher = false]--> [DOCUMENTS_UPLOADED] --> [ONBOARDING_COMPLETE]
      |
      +--[is_teacher = true]--> [TEACHER_PROFILE_CREATED]
                                      |
                                      v
                                [CAPABILITIES_ASSIGNED]
                                      |
                                      v
                                [DOCUMENTS_UPLOADED]
                                      |
                                      v
                                [ONBOARDING_COMPLETE]
                                [QR_CODE_GENERATED]
```

**Incompleteness Rules:**
- EMPLOYEE_RECORD_CREATED without EMPLOYEE_PROFILE: Employee cannot be assigned to timetable
- TEACHER_PROFILE_CREATED without CAPABILITIES_ASSIGNED: Teacher not eligible for timetable generation (SmartTimetable will not include them)
- USER_ACCOUNT_CREATED without EMPLOYEE_RECORD: User can log in but has no HR record — leave/attendance unavailable

### 4.4 FSM — Attendance Correction

**Entity:** AttendanceCorrection
**State field:** `status` (in sch_attendance_corrections)

```
  [SUBMITTED]
      |
      v
  [PENDING_APPROVAL]
      |
      +--[Approve]--> [APPROVED]
      |                    |
      |                    v
      |             [original attendance record overwritten]
      |             [audit trail entry created]
      |
      +--[Reject]--> [REJECTED]
                          |
                          v
                    [original record unchanged]
```

---

## Section 5 — Data Dictionary and Cross-Module Dependency Map

### 5.1 Data Dictionary — Key Tables

> All tables use tenant_db (database-per-tenant isolation). No tenant_id column — tenant context is enforced by DB connection.

#### sch_organizations (1 row per school)

| Column | Type | Nullable | Description |
|--------|------|---------|-------------|
| id | BIGINT UNSIGNED PK | No | Auto-increment |
| org_full_name | VARCHAR(255) | No | Full registered school name |
| org_short_name | VARCHAR(100) | Yes | Abbreviated display name |
| udise_code | VARCHAR(20) | Yes | Government UDISE identifier |
| affiliation_number | VARCHAR(50) | Yes | Board affiliation registration number |
| city_id | BIGINT UNSIGNED FK→glb_cities | Yes | City (cross-DB read from global_db) |
| district | VARCHAR(100) | Yes | Auto-populated from city |
| state | VARCHAR(100) | Yes | Auto-populated from city |
| country | VARCHAR(100) | Yes | Auto-populated from city |
| address_line1 | VARCHAR(255) | Yes | Street address |
| address_line2 | VARCHAR(255) | Yes | Address line 2 |
| pin_code | VARCHAR(10) | Yes | Postal code |
| primary_phone | VARCHAR(20) | Yes | Primary contact number |
| secondary_phone | VARCHAR(20) | Yes | Secondary phone |
| whatsapp_number | VARCHAR(20) | Yes | WhatsApp contact |
| email | VARCHAR(255) | Yes | School email |
| website | VARCHAR(255) | Yes | School website URL |
| latitude | DECIMAL(10,8) | Yes | GPS latitude |
| longitude | DECIMAL(11,8) | Yes | GPS longitude |
| is_rural | BOOLEAN | No | Rural (true) / Urban (false) |
| locale | VARCHAR(10) | No | e.g., "en-IN" |
| currency | VARCHAR(3) | No | e.g., "INR" |
| established_date | DATE | Yes | School founding date |
| logo_url | VARCHAR(500) | Yes | URL to logo in document store |
| flg_single_record | TINYINT(1) | No | Always 1; UNIQUE constraint enforces singleton |
| created_at, updated_at, deleted_at | TIMESTAMP | Nullable | Soft delete enabled |

**Constraints:** UNIQUE(flg_single_record) — enforces exactly one row per tenant.

---

#### sch_employees (core employment record)

| Column | Type | Nullable | Description |
|--------|------|---------|-------------|
| id | BIGINT UNSIGNED PK | No | |
| user_id | BIGINT UNSIGNED FK→users | No | Links to system user account |
| employee_code | VARCHAR(20) | No | Unique per school |
| is_teacher | BOOLEAN | No | Whether this employee is teaching staff |
| joining_date | DATE | No | Employment start date |
| id_card_type | ENUM | Yes | QR / RFID / NFC / Barcode |
| qualifications | JSON | Yes | Education qualifications array |
| certifications | JSON | Yes | Professional certifications array |
| work_experience | JSON | Yes | Prior work experience array |
| emergency_contact_name | VARCHAR(100) | Yes | Emergency contact person |
| emergency_contact_relation | VARCHAR(50) | Yes | Relationship |
| emergency_contact_phone | VARCHAR(20) | Yes | Phone number |
| bank_account_encrypted | TEXT | Yes | Encrypted bank account number |
| bank_ifsc_encrypted | TEXT | Yes | Encrypted IFSC code |
| created_at, updated_at, deleted_at | TIMESTAMP | Nullable | |

**Constraints:** UNIQUE(employee_code). FK: user_id → users.id.
**Security note:** bank_account_encrypted and bank_ifsc_encrypted must use application-layer encryption (AES-256 or Laravel Crypt facade) — not stored as plain text.

---

#### sch_leave_applications

| Column | Type | Nullable | Description |
|--------|------|---------|-------------|
| id | BIGINT UNSIGNED PK | No | |
| employee_id | BIGINT UNSIGNED FK→sch_employees | No | The applicant |
| leave_type_id | BIGINT UNSIGNED FK→sch_leave_types | No | |
| annual_leave_session_id | BIGINT UNSIGNED FK→sch_annual_leave_sessions | No | Leave year context |
| start_date | DATE | No | First day of leave |
| end_date | DATE | No | Last day of leave |
| is_half_day | BOOLEAN | No | Half-day flag |
| duration_days | DECIMAL(4,1) | No | Calculated days (may be 0.5 for half-day) |
| reason | TEXT | Yes | Applicant's reason |
| status | ENUM('pending','approved','rejected','cancelled') | No | Application state |
| current_approval_level | TINYINT UNSIGNED | Yes | Which level is currently active |
| created_at, updated_at, deleted_at | TIMESTAMP | Nullable | |

**Missing column (DDL gap):** `approved_at` TIMESTAMP — records when final approval occurred. Required for payroll deduction date correlation.

---

#### sch_teacher_capabilities (teacher-subject-grade mappings)

| Column | Type | Nullable | Description |
|--------|------|---------|-------------|
| id | BIGINT UNSIGNED PK | No | |
| teacher_profile_id | BIGINT UNSIGNED FK→sch_teacher_profiles | No | |
| subject_study_format_id | BIGINT UNSIGNED FK→sch_subject_study_formats | No | The specific teaching combination |
| school_class_id | BIGINT UNSIGNED FK→sch_school_classes | No | The grade level |
| proficiency_level | ENUM('beginner','intermediate','expert') | Yes | Teacher's self-reported proficiency |
| priority | TINYINT UNSIGNED | No | Ordering preference for timetable assignment |
| created_at, updated_at | TIMESTAMP | No | No soft delete — force-delete/recreate pattern |

**Important pattern:** On update, ALL records for a teacher_profile_id are force-deleted and re-created. This means any FK reference to these records (e.g., timetable assignment history) could break. Must be validated before SmartTimetable goes live with permanent teacher assignments.

---

#### sch_entity_groups + sch_entity_group_members (P0 BLOCKER)

| Table | Column | Type | Notes |
|-------|--------|------|-------|
| sch_entity_groups | id, name, code, purpose, is_active, timestamps | Standard | Migration exists |
| sch_entity_group_members | id, entity_group_id, entity_type, entity_id, timestamps | Polymorphic | **Migration MISSING from database/migrations/tenant/** |

**Production status:** Any attempt to add a member to an entity group will produce:
`SQLSTATE[42S02]: Base table or view not found: 'sch_entity_group_members'`
This is a P0 production bug — the migration must be created and deployed.

---

### 5.2 Cross-Module Dependency Map

SchoolSetup is the most depended-on module in the platform. It provides structural reference data consumed by 13+ downstream modules.

#### Modules that READ from SchoolSetup

| Consumer Module | Data Read from SchoolSetup | Criticality |
|----------------|--------------------------|------------|
| SmartTimetable | Classes, sections, subjects, study formats, class groups, teacher capabilities, period limits, rooms | P0 — timetable cannot generate without these |
| StandardTimetable | Same as SmartTimetable | P0 |
| StudentProfile | Classes, sections, departments, employee (class teacher) | P0 — students cannot be enrolled without class-sections |
| StudentFee | Classes, sections (fee assignment scope), academic session | P0 |
| Syllabus | Classes, sections, subjects, academic terms, employees (teacher) | P0 |
| LmsExam | Classes, sections, subjects, academic session | P0 |
| LmsQuiz | Classes, subjects | P1 |
| LmsHomework | Classes, sections, subjects, employees | P1 |
| QuestionBank | Subjects, classes (question scope filter) | P1 |
| HPC | Classes, sections, subjects, academic session | P0 |
| Recommendation | Classes, subjects, student (cross-ref class-section) | P1 |
| Notification | Entity groups (addressee lists), departments, employees | P1 |
| Transport | Employees (driver/supervisor records) | P2 |
| HrStaff | Employees, departments, designations, leave types, attendance types, shifts | P0 |
| BehaviouralAssessment | Classes, sections, employees | P1 |
| Library | Classes, sections | P2 |
| FrontOffice | Employees (visitor host), departments | P2 |
| Inventory | (none direct) | — |

#### Modules that WRITE to SchoolSetup (create data SchoolSetup reads)

| Provider Module | Data Written for SchoolSetup Use | Notes |
|----------------|----------------------------------|-------|
| GlobalMaster | glb_academic_sessions (session templates), glb_boards (board affiliations), glb_cities (city lookup) | Cross-DB reads — not direct FK |
| Platform Admin | User accounts (super-admin creation) | Platform-level operation |

#### Dependency Risk Summary

| Risk | Description | Impact |
|------|-------------|--------|
| SchoolSetup setup incomplete before student enrollment | StudentProfile module cannot be used | P0 — blocks entire school onboarding |
| Teacher profiles incomplete | SmartTimetable has no teachers to assign | P0 — timetable generation fails |
| sch_entity_group_members migration missing | Notification module entity-group addressing is broken | P0 |
| Leave/attendance not configured | HrStaff payroll will have no attendance data to calculate | P1 |

---

## Section 6 — NFR Catalog and Risk Register

### 6.1 Non-Functional Requirements Catalog

| NFR ID | Category | Requirement | Target | Current State |
|--------|---------|-------------|--------|---------------|
| NFR-SCH-001 | Performance | Screen load time | < 3 seconds for schools up to 5,000 students | Unknown — no baseline measured |
| NFR-SCH-002 | Performance | AJAX operation response time | < 1 second for CRUD and reorder operations | Unknown |
| NFR-SCH-003 | Performance | Report generation time | < 15 seconds for full academic year data | Reports not implemented |
| NFR-SCH-004 | Performance | Master data reads (classes/sections/subjects) | < 500 ms with cache; < 2 s without | No cache layer exists — N+1 risk on complex screens |
| NFR-SCH-005 | Security | Module license check | EnsureTenantHasModule middleware on all routes | Missing from ALL routes — P0 |
| NFR-SCH-006 | Security | Permission gate on all controller methods | Gate::authorize() at start of every method | 5 policies unregistered; 4 permissions missing from seeder |
| NFR-SCH-007 | Security | Super-admin flag isolation | is_super_admin must not be in User model $fillable | Currently in $fillable — P0 |
| NFR-SCH-008 | Security | Sensitive PII encryption | Bank account/IFSC encrypted at rest | Status unconfirmed — likely not encrypted |
| NFR-SCH-009 | Security | Input validation | All input via FormRequest or manual validation; no mass-assignment | 26 FormRequests confirmed; some controllers may use $request->all() |
| NFR-SCH-010 | Security | Data isolation | Absolute no cross-tenant data leakage | Enforced by stancl/tenancy database-per-tenant architecture |
| NFR-SCH-011 | Usability | Drag-and-drop reordering | Available for grades, sections, subjects, subject types, study formats | Implemented and verified |
| NFR-SCH-012 | Usability | AJAX-driven CRUD | No full page reload for core CRUD operations | Implemented for classes, permissions, some others |
| NFR-SCH-013 | Usability | Mobile-responsive leave screens | Leave application and approval screens functional on mobile | Unknown |
| NFR-SCH-014 | Reliability | Zero-test risk | All 0 tests across 56+ controllers | P0 — any regression is invisible |
| NFR-SCH-015 | Reliability | Audit trail | All create/update/delete logged with user identity and timestamp | activityLog() helper used in most controllers; coverage unverified |
| NFR-SCH-016 | Maintainability | Service layer extraction | Business logic in service classes, not controllers | 3 services exist; most logic still in controllers (God controllers) |
| NFR-SCH-017 | Scalability | Cache layer for master data | Tag-based cache invalidation for school structure data | Not implemented |

### 6.2 Risk Register

| Risk ID | Risk Description | Likelihood | Impact | Priority | Mitigation |
|---------|----------------|-----------|--------|---------|-----------|
| RISK-SCH-001 | sch_entity_group_members migration missing — entity group member feature silently broken in production | High (confirmed) | High | P0 | Create and deploy migration immediately |
| RISK-SCH-002 | is_super_admin in User $fillable — any school-level user could elevate to super-admin | High (confirmed) | Critical | P0 | Remove from $fillable; add explicit block in UserController |
| RISK-SCH-003 | EnsureTenantHasModule middleware missing from all SchoolSetup routes | High (confirmed) | High | P0 | Add middleware to route group in routes/tenant.php |
| RISK-SCH-004 | 0 test files across 56+ controllers — regressions are invisible | High (confirmed) | High | P0 | Write Pest feature tests for all P0 REQs first |
| RISK-SCH-005 | Leave auto-timeout CRON job not implemented — multi-level leave stuck at Level 1 indefinitely | High (confirmed) | Medium | P1 | Implement LeaveApprovalTimeoutJob and register in scheduler |
| RISK-SCH-006 | Teacher capability force-delete/recreate pattern — timetable assignment records could reference deleted capabilities | Medium | High | P1 | Add FK integrity check before delete; or shift to soft-delete |
| RISK-SCH-007 | Bank account details stored unencrypted | Medium (unconfirmed) | High | P1 | Verify storage; add Laravel Crypt encryption before any HR module goes live |
| RISK-SCH-008 | No cache on master data reads — N+1 queries on every page that lists classes/subjects | High (confirmed) | Medium | P1 | Add Redis cache with tag-based invalidation for sch_school_classes, sch_subjects, sch_sections |
| RISK-SCH-009 | 5 unregistered policy files — those policy gates are silently ignored | High (confirmed) | High | P1 | Register all 44 policies in AuthServiceProvider |
| RISK-SCH-010 | 4 permissions missing from seeders — role assignment for those actions impossible | High (confirmed) | Medium | P1 | Add missing permissions to SchoolSetupPermissions seeder |
| RISK-SCH-011 | OrganizationAcademicSessionController empty Blade stubs — AJAX-only but stubs create confusion | Medium | Low | P2 | Remove empty stubs or convert to proper AJAX handlers |
| RISK-SCH-012 | Employee lifecycle controllers are stubs — separation does not deactivate user account | Medium | Medium | P2 | Implement EmployeeSeparationController::store() with user account deactivation |
| RISK-SCH-013 | competency.blade.php misplaced in Controllers/ directory | Confirmed | Low | P3 | Move to correct views directory |
| RISK-SCH-014 | RoomRequest21_Nov.php backup file in FormRequests/ | Confirmed | Low | P3 | Delete from repository |
| RISK-SCH-015 | 3 models misplaced in SchoolSetup (QuestionType, PrmTenantPlan, PrmTenantPlanRate) | Confirmed | Low | P3 | Move to correct modules (QuestionBank, Billing/Prime) |

---

## Section 7 — Prioritization, Effort Estimation, and Sprint Task Map

### 7.1 Prioritization Matrix

| ID | Gap / Feature | Priority | Effort (days) | Dependency | Assignee Hint |
|----|---------------|---------|---------------|-----------|--------------|
| FIX-SCH-001 | Create sch_entity_group_members migration and deploy | P0 | 0.5 | None | Backend Developer |
| FIX-SCH-002 | Remove is_super_admin from User $fillable; block in UserController | P0 | 0.5 | None | Backend Developer |
| FIX-SCH-003 | Add EnsureTenantHasModule middleware to SchoolSetup route group | P0 | 0.5 | None | Backend Developer |
| FIX-SCH-004 | Register all 44 policy files in AuthServiceProvider | P1 | 1 | None | Backend Developer |
| FIX-SCH-005 | Add 4 missing permissions to SchoolSetupPermissions seeder and re-seed | P1 | 0.5 | None | Backend Developer |
| FIX-SCH-006 | Implement LeaveApprovalTimeoutJob and register in kernel scheduler | P1 | 2 | Leave Approval Policy DDL correct | Backend Developer |
| FIX-SCH-007 | Encrypt bank account / IFSC fields in sch_employees (column migration + Crypt) | P1 | 1 | None | Backend Developer |
| FIX-SCH-008 | Implement Redis cache layer for master data reads (classes, sections, subjects) | P1 | 3 | Redis enabled | Backend Developer |
| FIX-SCH-009 | Remove OrganizationAcademicSessionController empty Blade stubs | P2 | 0.5 | None | Backend Developer |
| FIX-SCH-010 | Implement EmployeeSeparationController with user account deactivation | P2 | 2 | Employee records complete | Backend Developer |
| FIX-SCH-011 | Extract service layer — UserService, OrganizationService, EmployeeService, LeaveService | P2 | 8 | FIX-SCH-004, tests exist | Senior Backend Developer |
| FIX-SCH-012 | Build Employee Report screens (RPT-SCH-001 through RPT-SCH-005) | P2 | 5 | Attendance and Leave data exists | Backend + Frontend |
| FIX-SCH-013 | Move misplaced files (competency.blade.php, RoomRequest21_Nov.php, misplaced models) | P3 | 0.5 | None | Backend Developer |
| TEST-SCH-001 | Write Pest feature tests for P0 REQs: org profile, sessions, grades, sections, subjects, users, roles | P0 | 6 | None | Test Engineer |
| TEST-SCH-002 | Write Pest feature tests for P1 REQs: employee CRUD, teacher profile, leave workflow, attendance | P1 | 10 | TEST-SCH-001 done | Test Engineer |
| TEST-SCH-003 | Write Pest feature tests for P2 REQs: lifecycle, reports, entity groups | P2 | 5 | TEST-SCH-002 done | Test Engineer |

### 7.2 Sprint Task Map (Suggested 3-Sprint Remediation)

#### Sprint 1 — P0 Security and Correctness (5 developer-days)
| Task | Effort |
|------|--------|
| FIX-SCH-001: Create sch_entity_group_members migration | 0.5d |
| FIX-SCH-002: Remove is_super_admin from $fillable | 0.5d |
| FIX-SCH-003: Add EnsureTenantHasModule middleware | 0.5d |
| FIX-SCH-004: Register all 44 policies | 1d |
| FIX-SCH-005: Add 4 missing permissions | 0.5d |
| TEST-SCH-001: P0 REQ feature tests | 6d |
| **Sprint 1 Total** | **~9d** |

#### Sprint 2 — P1 Workflow Completion (15 developer-days)
| Task | Effort |
|------|--------|
| FIX-SCH-006: LeaveApprovalTimeoutJob | 2d |
| FIX-SCH-007: Encrypt bank account fields | 1d |
| FIX-SCH-008: Redis cache layer for master data | 3d |
| Complete attendance correction approval UI | 3d |
| Complete leave withdrawal flow | 1d |
| TEST-SCH-002: P1 REQ feature tests | 10d |
| **Sprint 2 Total** | **~20d** |

#### Sprint 3 — P2 Enhancements and Reports (10 developer-days)
| Task | Effort |
|------|--------|
| FIX-SCH-010: Employee lifecycle / separation | 2d |
| FIX-SCH-011: Service layer extraction | 8d |
| FIX-SCH-012: Employee report screens | 5d |
| FIX-SCH-013: Remove misplaced files | 0.5d |
| TEST-SCH-003: P2 REQ feature tests | 5d |
| **Sprint 3 Total** | **~20.5d** |

---

## Section 8 — User Stories Catalog and KPI Specification

### 8.1 User Stories

#### Core Setup Stories (SCO)

**US-SCH-001**
As a School Administrator, I want to create the school's organization profile with its name, address, and board affiliations, so that all documents and certificates printed from the system display the correct school identity.

Acceptance Criteria:
- I can create the profile with all required fields (name, email, phone, city).
- Selecting a city auto-populates district, state, and country.
- Uploading a logo shows a preview immediately.
- Selecting a board affiliation links it to the current academic session.
- After saving, the school name appears in the platform header.
- A second attempt to create the profile shows "Organization profile already exists".

---

**US-SCH-002**
As a School Administrator, I want to map a global academic session to my school and mark it as the current session, so that all modules automatically filter their data to the correct school year.

Acceptance Criteria:
- I can select from a list of global session templates.
- I can override the start and end dates if my school's year differs.
- Setting a session as "current" immediately clears the current flag from the previous session.
- The session year is displayed in the platform header for all users.
- Overlapping sessions are rejected with a clear date conflict message.

---

#### Class Setup Stories (SCC)

**US-SCH-003**
As a School Administrator, I want to create grades and pair them with sections, so that students can be enrolled into the correct class-sections.

Acceptance Criteria:
- I can create grades (1–12) with names, short names, and codes.
- I can reorder grades by dragging; the order persists after page refresh.
- I can pair a grade with multiple sections in a single action.
- Each class-section shows the assigned class teacher and student capacity.
- Deleting a grade moves it and all its class-sections to the trash (soft delete).

---

**US-SCH-004**
As a School Administrator, I want to define subjects and their teaching formats (theory, lab, project), so that the AI Timetable Generator can create the correct activity slots for each class.

Acceptance Criteria:
- I can create subject types and study formats independently.
- I can create a subject and link it to one or more study formats, creating subject-study-format combinations.
- I can assign combinations to class-sections through class groups.
- Removing a combination is blocked if it is already assigned to a class group.

---

#### Employee Setup Stories (SCE)

**US-SCH-005**
As an HR Officer, I want to onboard a new teacher by creating their user account, employment record, and teaching profile in a guided multi-step flow, so that they can log in and be assigned to timetable slots on the same day.

Acceptance Criteria:
- After creating the user account, I proceed directly to the employee record step.
- After the employee record, I complete the teaching profile with period limits and lab certification.
- After the teaching profile, I assign subject capabilities by selecting subjects and grades.
- A QR code is generated after completing onboarding.
- The teacher appears in the SmartTimetable's teacher list on the same day.

---

**US-SCH-006**
As an Employee, I want to apply for casual leave for next week, so that my absence is recorded and my leave balance is reduced after approval.

Acceptance Criteria:
- I can select the leave type, start date, end date, and reason.
- The form shows my remaining balance for the selected leave type.
- If my dates overlap with a pending application, the system blocks submission with an explanation.
- After submitting, I see the application in "Pending" status.
- After final approval, my leave balance decreases and I receive a notification.

---

**US-SCH-007**
As a Leave Approver, I want to review pending leave applications from my team and approve or reject them with a reason, so that the employee's attendance record is updated immediately.

Acceptance Criteria:
- I see only applications assigned to my approval level — not applications at other levels.
- I can approve with optional comments or reject with a mandatory reason.
- After my approval (if I am the final approver), the employee's attendance records for those dates are automatically updated.
- The employee receives a notification when I act.

---

#### Access Control Stories

**US-SCH-008**
As an IT Administrator, I want to create a "Class Teacher" role and assign the correct permissions to it, so that class teachers can only see their own class and cannot access school configuration screens.

Acceptance Criteria:
- I can create a new role named "Class Teacher".
- I can toggle individual permissions on or off, or assign all permissions in a group with one click.
- Saving the role immediately updates access for all users holding it.
- I can assign the role to multiple users from the user management screen.

---

### 8.2 KPI Specification

| KPI ID | KPI Name | Formula | Target | Measured How | Audience |
|--------|---------|---------|--------|-------------|---------|
| KPI-SCH-001 | Employee Onboarding Completion Rate | Employees with complete profiles (user + employee + profile) ÷ Total employees × 100 | > 95% | Dashboard counter on User Accounts screen | School Admin |
| KPI-SCH-002 | Leave Application Turnaround Time | Average time (hours) from submission to final approval/rejection | < 24 hours | Calculated from created_at to final approval_records.created_at | Principal, HR Officer |
| KPI-SCH-003 | Teacher Capability Coverage | Class groups with at least 1 capable teacher ÷ Total class groups × 100 | 100% before timetable generation | Derived from teacher capabilities vs. class groups | School Admin |
| KPI-SCH-004 | Monthly Attendance Rate | Present days ÷ Working days × 100 (per employee, department, school) | > 95% for each department | Employee Attendance Report (RPT-SCH-001) | HR Officer, Principal |
| KPI-SCH-005 | Leave Balance Utilization | Days used ÷ Days entitled × 100 (by leave type and department) | Within configured limits | Leave Balance Report (RPT-SCH-002) | HR Officer |
| KPI-SCH-006 | Role Coverage | Users with at least one role assigned ÷ Total active users × 100 | 100% | Derived from user_role pivot; shown on User Management screen | IT Administrator |
| KPI-SCH-007 | School Setup Readiness Score | Weighted sum: org profile (15%) + sessions (10%) + classes (15%) + subjects (15%) + employees (20%) + teacher profiles (15%) + roles (10%) | > 90% before first student enrollment | Calculated and displayed on School Setup Dashboard | School Admin |

---

## Section 9 — Feature Specification (Screen-by-Screen)

### 9.1 Sub-domain: SCO (CoreSetup)

#### Screen: Organization Profile — View and Edit
**Route prefix:** `/school/organization/`
**Controller:** `OrganizationController`
**Policy:** `OrganizationPolicy`
**Key behaviours:**
- Read-only view with Edit button for authorized users
- Single record — no "Create" page; all actions are edit-of-existing or first-time-create
- Logo upload: Spatie Media Library; preview shows immediately on upload
- City picker: AJAX-driven; selecting city auto-fills district/state/country via global_db lookup
- Board affiliations: linked via sch_org_board_affiliations to current session
- Soft delete and restore supported for cleanup/testing; force delete for permanent removal

**Current status:** Implemented and functional. No major gaps.
**Gap:** No media cleanup when logo is replaced (old file remains in storage).

---

#### Screen: Academic Sessions — List and Map
**Route prefix:** `/school/academic-sessions/`
**Controller:** `OrganizationAcademicSessionController`
**Current status:** Implemented. AJAX-only CRUD — no Blade page forms (empty stubs exist but do nothing).
**Gap:** Empty Blade stubs should be removed (P2 clean-up); add board affiliation interface in same screen.

---

#### Screen: Academic Terms — List and Create/Edit
**Route prefix:** `/school/academic-terms/`
**Controller:** `OrganizationAcademicTermController`
**Current status:** Implemented; DDL confirmed correct. Mark-as-current flow implemented.
**Gap:** None confirmed.

---

#### Screen: Holiday Calendar — List by Leave Session
**Route prefix:** `/school/holidays/`
**Controller:** `HolidayController`, `AnnualLeaveSessionController`
**Key behaviours:**
- Holidays are listed within a selected annual leave session context
- Holiday type drives payroll treatment (set as ENUM in migration)
- Optional applicability restriction by role or department
**Current status:** Implemented.

---

### 9.2 Sub-domain: SCC (ClassSetup)

#### Screen: Grade Management — List, Create/Edit, Reorder
**Route prefix:** `/school/classes/`
**Controller:** `SchoolClassController`
**Key behaviours:**
- AJAX-driven CRUD returning JSON responses (no page reload)
- Drag-and-drop reorder updates ordinal field via AJAX PATCH
- Grade delete cascades deactivation to class-sections (not permanent delete)
- Grade restore re-activates all associated class-sections
**Current status:** Fully implemented and verified functional.

---

#### Screen: Class-Section Configuration
**Route prefix:** `/school/class-sections/` (embedded in Grade management view)
**Controller:** `SchoolClassController` (extended for sections)
**Key behaviours:**
- Section addition/removal from a grade triggers class-section create/deactivate
- Class teacher and assistant class teacher selection from employee list (AJAX)
- Min/max/actual student capacity displayed per class-section
**Current status:** Implemented.
**Gap:** Actual student count may not auto-update when students are enrolled via StudentProfile — cross-module sync not confirmed.

---

#### Screen: Subject Management (includes Types, Formats, Combinations)
**Route prefix:** `/school/subjects/`
**Controllers:** `SubjectController`, `SubjectTypeController`, `StudyFormatController`, `SubjectStudyFormatController`
**Key behaviours:**
- Subject types and study formats each have independent drag-reorder
- A subject has multiple study formats — each combination has its own name and code
- Combinations cannot be deleted if referenced by class groups
**Current status:** Fully implemented and verified.

---

#### Screen: Class Groups (Class-Subject-StudyFormat Mapping)
**Route prefix:** `/school/class-groups/`
**Controller:** `ClassGroupController`
**Key behaviours:**
- Each class group record links one class-section to one subject-study-format combination
- Multiple-options flag allows alternative subject combinations for the same slot
- These records are the primary input for SmartTimetable generation
**Current status:** Implemented.
**Gap:** UI for managing multiple-options mode needs UX validation.

---

### 9.3 Sub-domain: SCI (InfraSetup)

#### Screens: Buildings, Room Types, Rooms
**Route prefix:** `/school/buildings/`, `/school/room-types/`, `/school/rooms/`
**Controllers:** `BuildingController`, `RoomTypeController`, `RoomController`
**Current status:** All three screens fully implemented with standard CRUD and soft delete.
**Gap:** None confirmed.

---

### 9.4 Sub-domain: SCE (EmployeeSetup)

#### Screen: Employee List and Create
**Route prefix:** `/school/employees/`
**Controller:** `EmployeeController`
**Key behaviours:**
- Employee list shows employee code, name, department, designation, joining date, status
- Create initiates the multi-step onboarding flow
- Profile completion percentage shown per employee
- QR code generation available on individual employee view
**Current status:** Implemented with multi-step flow. Document upload functional.
**Gap:** Bank account encryption status unconfirmed. Emergency contact JSON column presence unconfirmed.

---

#### Screen: Teacher Profile and Capabilities
**Route prefix:** `/school/teachers/`, `/school/teacher-capabilities/`
**Controllers:** `TeacherProfileController`, `TeacherCapabilityController`
**Key behaviours:**
- Teacher profile form shows period limits, substitution eligibility, lab certification
- Capability assignment: select subject-study-format and grade; drag to set priority
- On save: all existing capability records for the teacher are deleted and replaced
**Current status:** Implemented.
**Gap:** Force-delete/recreate pattern could break timetable records if timetable assigns a capability ID (P1 risk).

---

#### Screen: Leave Application — Employee View
**Route prefix:** `/school/leave-applications/`
**Controller:** `LeaveApplicationController`
**Key behaviours:**
- Form: leave type picker (shows available balance), date range, half-day toggle, reason text, document upload
- Available balance shown in real-time based on leave type selection
- Submission validates: date overlap, minimum advance notice, document requirement, balance sufficiency
- Application list shows status, dates, and current approval level
**Current status:** Implemented. 
**Gap:** Withdrawal flow partially implemented; auto-timeout job not deployed.

---

#### Screen: Leave Approval — Approver View
**Route prefix:** `/school/leave-approvals/`
**Controller:** `LeaveApprovalController`
**Key behaviours:**
- Shows only applications pending action at the current approver's level
- Approve with optional comment; reject with mandatory reason
- Final approval triggers balance deduction and attendance update
**Current status:** Approval action implemented; balance deduction trigger status unconfirmed.
**Gap:** If LeaveApprovalTimeoutJob is missing, applications stuck at Level 1 forever.

---

#### Screen: Employee Attendance — Monthly View and Daily Entry
**Route prefix:** `/school/attendance/`
**Controllers:** `EmployeeAttendanceController`, `BiometricPunchController`
**Key behaviours:**
- Monthly attendance grid: employee rows × date columns with attendance status
- Manual entry: HR Officer can set status for any employee for any date
- Biometric punch import: upload CSV or device-sync to populate in/out timestamps
- Status derivation: system calculates status from punch + shift grace period
- Correction requests submitted from the attendance view
**Current status:** Core attendance entry implemented. Biometric import functional.
**Gap:** Correction approval UI partial; status derivation logic accuracy unconfirmed.

---

#### Screen: User Accounts — List and Create
**Route prefix:** `/school/users/`
**Controller:** `UserController`
**Key behaviours:**
- User list filtered by role; statistics shown (total users, teachers, non-teaching)
- Create: username, email, password, avatar, role assignment
- Role assignment: Teacher role → navigate to teacher profile completion
- Deactivate account (set is_active = false) without deletion
**Current status:** Implemented.
**Gap:** User statistics show placeholder counts (P1); is_super_admin in $fillable (P0).

---

#### Screen: Roles and Permissions — Create and Assign
**Route prefix:** `/school/roles/`, `/school/permissions/`
**Controller:** `RoleController`
**Key behaviours:**
- Role list with user count per role
- Permission assignment: grouped by module prefix; individual toggle or group bulk-assign
- Role delete: physically removes role and all user assignments
**Current status:** Implemented.
**Gap:** 4 permissions missing from registration; 5 policies unregistered — permission gaps create invisible missing gates.

---

#### Screen: Entity Groups — List and Manage Members
**Route prefix:** `/school/entity-groups/`
**Controller:** `EntityGroupController`, `EntityGroupMemberController`
**Key behaviours:**
- Create group with name, code, purpose
- Add members: polymorphic type selection (employee, department, section, role)
- Used by Notification module for bulk addressing
**Current status:** Group CRUD implemented; member management BROKEN in production.
**Gap (P0):** sch_entity_group_members table/migration does not exist — any member add attempt fails with database error.

---

## Section 10 — Gap Analysis Summary

### 10.1 P0 Critical Gaps (Must Fix Before Production)

| Gap ID | Area | Description | Fix Required | Effort |
|--------|------|-------------|-------------|--------|
| SEC-SCH-01 | Security | EnsureTenantHasModule middleware missing from ALL SchoolSetup routes — any user can access school setup without a valid license | Add middleware to route group in tenant.php | 0.5d |
| SEC-SCH-02 | Security | is_super_admin in User model $fillable — school-level admin can grant themselves platform super-admin privileges | Remove from $fillable; add explicit block in controller | 0.5d |
| BUG-SCH-03 | Data Integrity | sch_entity_group_members migration missing — entity group member feature produces SQLSTATE[42S02] in production | Create migration and deploy | 0.5d |
| BUG-SCH-04 | Test Coverage | 0 test files across 56+ controllers — any code change could cause silent regression across the most critical module | Write Pest feature tests for all P0 REQs | 6d |

### 10.2 P1 High-Priority Gaps

| Gap ID | Area | Description | Fix Required | Effort |
|--------|------|-------------|-------------|--------|
| BUG-SCH-05 | Security | 5 policy files not registered in AuthServiceProvider — those policy gates silently do nothing | Register all 44 policies | 1d |
| BUG-SCH-06 | Security | 4 permissions missing from seeder registration — role assignment for those actions is impossible | Add missing permissions to seeder | 0.5d |
| BUG-SCH-07 | Workflow | LeaveApprovalTimeoutJob not implemented — multi-level leave approval stuck indefinitely at Level 1 | Implement job and register in scheduler | 2d |
| BUG-SCH-08 | Security | Bank account / IFSC likely stored unencrypted in sch_employees — sensitive PII exposed | Add encrypted columns; migrate data | 1d |
| BUG-SCH-09 | Performance | No cache layer for master data reads — N+1 risk on every screen reading classes/sections/subjects | Add Redis cache with tag invalidation | 3d |
| BUG-SCH-10 | Data Integrity | Teacher capability force-delete/recreate pattern — timetable assignment history loses capability references | Evaluate FK impact before SmartTimetable go-live | 2d |
| GAP-SCH-11 | Code Quality | UserController statistics display placeholder counts — dashboard numbers are misleading | Replace with live database counts | 0.5d |
| GAP-SCH-12 | Workflow | Leave withdrawal flow incomplete — employee can attempt withdrawal post-Level1 approval | Complete withdrawal guard logic | 1d |
| GAP-SCH-13 | Workflow | Attendance correction approval UI partial — corrections can be submitted but approval route incomplete | Complete correction approval controller and views | 3d |

### 10.3 P2 Medium-Priority Gaps

| Gap ID | Area | Description | Fix Required | Effort |
|--------|------|-------------|-------------|--------|
| DDL-SCH-14 | Schema | sch_leave_applications missing approved_at timestamp column | Add column in migration | 0.5d |
| DDL-SCH-15 | Schema | sch_employees missing explicit emergency_contact fields (may be in JSON column) | Verify; extract to explicit columns if needed | 1d |
| GAP-SCH-16 | Code Quality | OrganizationAcademicSessionController empty Blade stubs | Remove stubs | 0.5d |
| GAP-SCH-17 | Reporting | Employee reports (attendance, leave balance, staffing, compliance, teacher capability) not built | Build RPT-SCH-001 through RPT-SCH-005 | 5d |
| GAP-SCH-18 | Workflow | EmployeeSeparationController is stub — separation does not deactivate user account | Implement separation flow | 2d |
| GAP-SCH-19 | Architecture | No service layer — business logic in controllers (God controllers) | Extract LeaveService, EmployeeService, UserService | 8d |
| GAP-SCH-20 | Configuration | SchoolConfigController UI is stub — school-level config values not editable from UI | Build config management screen | 2d |

### 10.4 P3 Low-Priority Gaps

| Gap ID | Area | Description | Fix Required | Effort |
|--------|------|-------------|-------------|--------|
| GAP-SCH-21 | Code Quality | competency.blade.php misplaced in Controllers/ directory | Move to views | 0.5d |
| GAP-SCH-22 | Code Quality | RoomRequest21_Nov.php backup file in FormRequests/ | Delete | 0.1d |
| GAP-SCH-23 | Code Quality | 3 models misplaced in SchoolSetup (QuestionType, PrmTenantPlan, PrmTenantPlanRate) | Move to correct modules | 0.5d |
| ENH-SCH-24 | Enhancement | No biometric device integration — punches are manually imported | Build device integration API | 10d |
| ENH-SCH-25 | Enhancement | No mobile app for leave application/approval | Future mobile app or PWA | 20d+ |
| ENH-SCH-26 | Enhancement | No academic year setup wizard | Build guided wizard | 5d |

### 10.5 Overall Gap Count Summary

| Priority | Gaps | Est. Total Effort |
|---------|------|-----------------|
| P0 — Must Fix Before Production | 4 | ~7.5 developer-days |
| P1 — Fix in Next Sprint | 9 | ~13 developer-days |
| P2 — Schedule in Near Term | 7 | ~19 developer-days |
| P3 — Backlog | 6 | ~36+ developer-days |
| **Total** | **26** | **~75.5 developer-days** |

---

## Section 11 — Module Knowledge Update Notes

> These notes document what changed since the prior knowledge seeding. Update `SCH_SchoolSetup.md` accordingly.

### 11.1 Key Facts to Add to SCH_SchoolSetup.md

1. **FRD generated:** `SCH_FRD_2026-06-30.md` — 26 REQs, 84 BRs, 6 workflows, 6 reports, 7 ENHs
2. **Complete Analysis Pack generated:** `SCH_FRD_Complete_2026-06-30.md` — 10-artifact analysis
3. **REQ count:** 26 functional requirements across all 4 sub-domains (up from V2's 17 FRs)
4. **Gap count:** 26 documented gaps across P0/P1/P2/P3 tiers
5. **P0 blockers:** SEC-SCH-01 (EnsureTenantHasModule missing), SEC-SCH-02 (is_super_admin in $fillable), BUG-SCH-03 (sch_entity_group_members migration missing), BUG-SCH-04 (0 tests)
6. **Overall completion revised:** ~62% (all 4 sub-domains) — breakdown: SCO 70%, SCC 80%, SCI 90%, SCE 45%
7. **Confirmed production blocker:** sch_entity_group_members migration does not exist in database/migrations/tenant/
8. **Next priority actions:** FIX-SCH-001, FIX-SCH-002, FIX-SCH-003 (0.5d each), then TEST-SCH-001 (6d)

### 11.2 Pending Next Steps (Post-FRD)

Priority order:
1. Deploy sch_entity_group_members migration (FIX-SCH-001)
2. Remove is_super_admin from User $fillable (FIX-SCH-002)
3. Add EnsureTenantHasModule to route group (FIX-SCH-003)
4. Register all 44 policies in AuthServiceProvider (FIX-SCH-004)
5. Write Pest feature tests for P0 REQs (TEST-SCH-001)
6. Implement LeaveApprovalTimeoutJob (FIX-SCH-006)
7. Verify and fix bank account encryption (FIX-SCH-007)
8. Add Redis cache layer for master data (FIX-SCH-008)
9. Build Employee Report screens (FIX-SCH-012)
10. Extract service layer (FIX-SCH-011 — longer term)

### 11.3 Questions Raised During Analysis

| Q# | Question | Owner | Status |
|----|---------|-------|--------|
| Q-1 | Is bank_account_encrypted column actually using Laravel Crypt, or is it plain VARCHAR? | Backend Team | OPEN |
| Q-2 | Does the emergency_contact exist as explicit columns or inside a JSON column in sch_employees? | Backend Team | OPEN |
| Q-3 | Is the teacher capability force-delete/recreate pattern safe given SmartTimetable's FK usage? | SmartTimetable Team | OPEN |
| Q-4 | What is the auto-timeout period intended for leave approval levels? Is it configured per-policy or globally? | HR Business Owner | OPEN |
| Q-5 | Should sch_annual_leave_sessions be the same as academic sessions, or are they always separate? | HR Business Owner | OPEN |
| Q-6 | Does the actual_student_count on class-sections auto-update when StudentProfile module enrolls a student? | Backend Team | OPEN |

---

## Document Control

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-06-30 | Initial Complete Analysis Pack — all 10 artifacts covering all 4 sub-domains (SCO/SCC/SCI/SCE). Sources: V2 requirement (968 lines), V1 screen specs (46 files), live code (52 migrations, 56+ controllers), module knowledge files SCH_SchoolSetup.md and SCO_SchoolSetup_CoreSetup.md. Supersedes SCO_FRD_Complete_2026-06-29.md in scope. | Business Analyst — Prime-AI AI Brain |

---

*Primary FRD: `SCH_FRD_2026-06-30.md` (same directory)*
*Module Knowledge: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/SCH_SchoolSetup.md`*
*V2 Source Requirement: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/4-Initial_Requirements/V2/SCH_SchoolSetup_Requirement.md`*
*Codebase: `/Users/bkwork/Herd/prime_ai/Modules/SchoolSetup/`*
