# SchoolSetup CoreSetup (SCO) — Complete Analysis Pack
**Version:** 1.0 | **Date:** 2026-06-30 | **Module Code:** SCO | **Sub-module of:** SchoolSetup
**Sources:** Live Laravel migrations (tenant/), OrganizationController, HolidayController, OrganizationAcademicSessionController, DepartmentController, SystemConfigController, and 18 other controllers; Modules/SchoolSetup/app/Models/; Modules/SchoolSetup/routes/web.php (494 lines); V2 req SCH_SchoolSetup_Requirement.md; V1 screen-specs CoreSetup_v2/
**DB Layer:** Tenant (database-per-school; no `tenant_id` column — isolation by DB)

---

## Table of Contents

1. [FRD — Functional Requirements Document](#section-1-frd)
2. [Requirements Traceability Matrix (RTM)](#section-2-rtm)
3. [Business Rules Register + Requirement Conditions + Validation Catalog](#section-3-business-rules)
4. [Process Flows + FSM Catalog](#section-4-workflows-fsm)
5. [Data Dictionary + Cross-Module Dependency Map](#section-5-data-dictionary)
6. [NFR Catalog + Risk Register](#section-6-nfr-risk)
7. [Prioritization + Effort Estimation](#section-7-prioritization-effort)
8. [User Stories + Reporting & KPI Spec](#section-8-user-stories-reporting)

---

# Section 1: FRD — Functional Requirements Document

## 1. Module Overview

### 1.1 Purpose
The School Core Setup sub-module (SCO) establishes the foundational identity and operational configuration of a school within the Prime-AI platform. Every other module depends on the data defined here — a school cannot enrol students, assign teachers, run a timetable, or generate fee invoices without first completing its core setup. SCO owns the school's public profile, its calendar of academic years and holidays, its organizational structure (departments, designations), its lookup master data (system dropdowns and configuration parameters), and the flexible entity-grouping system used platform-wide.

### 1.2 Business Value
- Enables multi-branch school societies to manage all branches from a single setup screen
- Provides a single source of truth for the school's name, logo, contact details, and board affiliation — consumed by all printed documents (marksheets, fee receipts, HPC cards)
- Dropdown master and school config tables act as the platform's configuration layer, reducing hard-coded values and giving each school customization without code changes
- Holiday calendar and leave year data remove manual duplication across attendance, HR, and payroll modules
- Entity groups replace a proliferation of module-specific grouping tables, enabling reuse across Notification, EventEngine, Transport, and future modules

### 1.3 Scope

**In Scope:**
- School identity and profile (name, logo, contact, location, government codes, board affiliation)
- Organization group management (multi-branch school societies)
- Academic session mapping and academic term definition
- Board affiliation management per session
- Holiday calendar and leave year (annual leave session) management
- Work shift configuration (time boundaries, grace periods, thresholds)
- Organizational structure masters: departments, designations
- Operational configuration masters: staff attendance types, staff leave types, staff leave entitlement policies, leave approval workflow configuration, student leave types
- Entity group and entity group member management (generic cross-purpose grouping)
- System dropdown master management (lookup values for all modules)
- School module configuration parameter management
- User account and role/permission management for school users
- Permission synchronization utility

**Out of Scope:**
- Class, section, and subject setup (SchoolSetup ClassSetup — SCC sub-module)
- Employee profile management, teacher profiles, teacher capabilities (SchoolSetup EmployeeSetup — SCE sub-module)
- Buildings, room types, and room management (SchoolSetup InfraSetup — SCI sub-module)
- Global academic session creation (GlobalMaster module — platform admin)
- Global board master management (GlobalMaster module)
- Leave application submission and approval workflow (HrStaff module)
- Payroll and salary calculations (HrStaff module)
- Biometric attendance marking (future Attendance module)
- Student enrollment and admission (StudentProfile, Admission modules)

### 1.4 Terminology

| Business Term | Meaning |
|---------------|---------|
| Organization | A single school or institution; exactly one record exists per tenant database (`flg_single_record` constraint) |
| Organization Group | A parent entity (school society or trust) grouping multiple school branches, represented by group attributes stored on the Organization record |
| Academic Session | A school year (e.g., "2026–2027") mapped from the platform's global session list with school-specific start/end dates; exactly one can be current at any time |
| Academic Term | A subdivision of an academic session (e.g., "Term 1", "Term 2") with its own calendar parameters such as teaching days, period counts, and exam days |
| Board Affiliation | The link between the school's current academic session and a recognized education board (CBSE, ICSE, State Board); managed per session |
| Leave Year | An annual leave container (school's financial/HR year) to which holidays are attached; analogous to HR fiscal year |
| Holiday Calendar | The complete list of holidays (public, religious, school-specific, optional) within a Leave Year |
| Work Shift | A defined daily attendance window with start time, end time, break, grace periods, and half-day threshold; applied to staff groups |
| Department | A functional unit within the school (e.g., Science Department, Administration) to which employees are assigned |
| Designation | A job title or position within the school hierarchy (e.g., Principal, Senior Teacher) |
| Attendance Type | A coded classification for daily attendance marking (e.g., Present, Absent, Late, Half Day) with payroll impact flags |
| Staff Leave Type | A defined category of leave (e.g., Casual Leave, Sick Leave, Earned Leave) with its rules (paid/unpaid, carry-forward, documentation requirements) |
| Leave Entitlement Policy | A rule that determines how many days of a specific leave type an employee earns per year, based on their role, department, designation, or employment type |
| Leave Approval Policy | A multi-level workflow definition specifying who must approve leave applications of a given type and in what sequence |
| Entity Group | A named, purpose-tagged collection of mixed entity types (students, employees, rooms) used platform-wide for notifications, scheduling, and operations |
| System Dropdown | A lookup value in the `sys_dropdowns` table, keyed by a group name; used by all modules as configuration-driven option lists |
| School Config | A module-scoped key-value parameter controlling application behavior (e.g., attendance grace period override, marksheet layout choice) |

---

## 2. User Roles and Access

### 2.1 Actors

| Actor | Description |
|-------|-------------|
| School Admin | Performs full configuration of all SCO entities; the primary user of this module |
| Principal | Read-only view of organization profile, academic session, and org structure |
| HR Officer | Manages departments, designations, leave types, leave entitlement policies, approval workflows, and holiday calendar |
| IT Admin | Manages user accounts, role/permission assignments, system dropdowns, and school config |
| System (Platform) | Reads organization, session, dropdown, and config data to serve all tenant-facing modules |

### 2.2 Role-Feature Matrix

| Feature | School Admin | Principal | HR Officer | IT Admin |
|---------|:---:|:---:|:---:|:---:|
| School Profile (view) | R/W | R | R | R |
| School Profile (edit) | R/W | — | — | — |
| Organization Group | R/W | R | — | — |
| Academic Sessions | R/W | R | R | R |
| Academic Terms | R/W | R | — | — |
| Board Affiliations | R/W | R | — | — |
| Holiday Calendar | R/W | R | R/W | — |
| Leave Year | R/W | — | R/W | — |
| Work Shifts | R/W | — | R/W | — |
| Departments | R/W | R | R/W | — |
| Designations | R/W | R | R/W | — |
| Attendance Types | R/W | — | R/W | — |
| Staff Leave Types | R/W | — | R/W | — |
| Leave Entitlement Policies | R/W | — | R/W | — |
| Leave Approval Policies | R/W | — | R/W | — |
| Student Leave Types | R/W | — | R/W | — |
| Entity Groups | R/W | R | — | R/W |
| System Dropdowns | — | — | — | R/W |
| School Config | — | — | — | R/W |
| User Accounts | R/W | — | — | R/W |
| Role & Permissions | R/W | — | — | R/W |
| Permission Sync | — | — | — | Super Admin only |

---

## 3. Functional Requirements

### REQ-SCO-001 — School Profile Management
**Priority:** P0 (Core/Must) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** The School Admin can create and maintain the school's single identity record containing its official name, short name, code, government identifiers, contact details, location, branding, and operational settings. The system enforces that exactly one organization record exists per school tenant.

**Actors:** Initiates: School Admin | Processes: System | Views: School Admin, Principal, IT Admin

**Business Rules:**

| BR-SCO-001 | Only one organization record is allowed per tenant | Validation | Attempt to create a second record | `flg_single_record` UNIQUE constraint; system blocks creation if record exists |
|---|---|---|---|---|
| BR-SCO-002 | Selecting a city must auto-resolve the district, state, and country | Calculation | Saving organization form | Controller reads city→district→state→country chain before persisting |
| BR-SCO-003 | Board affiliations are synced atomically on every save | Workflow | Store / Update | `syncBoardPivot()` detaches removed boards and attaches new ones in one operation |
| BR-SCO-004 | School logo must be stored via media library; only one active logo at a time | Validation | Logo upload | `school_logo` media collection is single-file; previous logo cleared on upload |
| BR-SCO-005 | All create, update, delete, and status-change operations must be audit-logged | Workflow | Every CUD action | `activityLog()` called with changed attributes |
| BR-SCO-006 | Soft delete must deactivate the record before deleting | Workflow | Delete action | `is_active = false` set before `delete()` call |

**Acceptance Criteria:**
- AC1: Attempting to create a second organization record is rejected by the database constraint
- AC2: Uploading a school logo replaces the previous logo in the `school_logo` media collection
- AC3: Saving with a `city_id` automatically populates district, state, and country without manual entry
- AC4: Board affiliation checkboxes are reflected in `sch_board_organization_jnt` — added boards appear, removed boards disappear
- AC5: All CUD operations produce an activity log entry
- AC6: `$request->validated()` is used (not `$request->all()`) in store and update [P0 gap — currently broken: SCO-P0-001]

**Integration:** Reads `glb_cities`, `glb_districts`, `glb_states`, `glb_countries` (GlobalMaster); reads `glb_boards` for affiliation options; stores logo via Spatie Media Library

**Enhancement Notes:** ENH-SCO-001 — Support multiple logos (e.g., primary + letterhead variant)

---

### REQ-SCO-002 — Organization Group Management
**Priority:** P1 (Standard/Should) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** A school that belongs to a multi-branch society or trust can record its group identity. Organization group attributes (group code, group short name, group name) are stored directly on the organization record. A separate group entity is available as optional structure for future hierarchy needs.

**Business Rules:**

| BR-SCO-007 | Group name must be unique within the tenant | Validation | Create/Update | Unique validation on group_name |
| BR-SCO-008 | Groups are optional — standalone schools operate without a group | Validation | System behavior | `group_code`, `group_short_name`, `group_name` are nullable on `sch_organizations` |

**Acceptance Criteria:**
- AC1: Organization group CRUD with soft delete, restore, force delete, and status toggle supported
- AC2: Group name uniqueness enforced per tenant

**Enhancement Notes:** ENH-SCO-002 — Separate `sch_organization_groups` table to support full multi-branch hierarchy with inter-branch reporting

---

### REQ-SCO-003 — Academic Session Mapping
**Priority:** P0 (Core/Must) | **Tags:** [DATA_ENTRY][CONFIGURATION][WORKFLOW]

**Description:** The School Admin maps the platform's global academic sessions to this school, optionally overriding start and end dates, and designates exactly one session as current. All tenant modules resolve "this year's data" from the current session. Board affiliations are maintained per session.

**Business Rules:**

| BR-SCO-009 | Only one academic session can be marked as current at any time | Concurrency | Set-as-current action | MySQL UNIQUE on `current_flag` generated column; `setActiveSession()` atomically resets all others before setting new current |
| BR-SCO-010 | Session end date must be after start date | Validation | Create/Update | `end_date` validated as `after:start_date` |
| BR-SCO-011 | Short name must be unique within the school's session list | Validation | Create/Update | Unique validation on `short_name` field |
| BR-SCO-012 | Board affiliation toggle requires an active current session | Workflow | Board toggle | `toggleBoard()` returns 422 if no current session exists |

**Acceptance Criteria:**
- AC1: Creating a session via AJAX (`ajaxStore`) returns JSON with the new session record
- AC2: Marking a session as current via `setActiveSession` atomically unmarks the previous current session
- AC3: Board linkage toggle (`toggleBoard`) links or unlinks a global board for the current session
- AC4: Soft delete, restore, and status toggle all work for sessions
- AC5: The UNIQUE constraint on `current_flag` prevents race conditions — only one session can be current at the DB level

**Integration:** Reads `glb_academic_sessions` (GlobalMaster) to populate the session picker; writes to `sch_org_academic_sessions_jnt` (tenant); writes to `sch_board_organization_jnt` for board affiliation

---

### REQ-SCO-004 — Academic Term Definition
**Priority:** P1 (Standard/Should) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** Within each academic session, the school defines the number of terms (e.g., two semesters, three terms) with their individual date ranges, teaching-day counts, period structure, and exam days. Academic terms drive the SmartTimetable solver and attendance calculation.

**Business Rules:**

| BR-SCO-013 | A term's code must be unique within its academic session | Validation | Create/Update | Composite UNIQUE on (academic_session_id, term_code) |
| BR-SCO-014 | Only one term can be marked as current within a session | Concurrency | Set-as-current | UNIQUE on `current_flag` generated column |
| BR-SCO-015 | Total teaching periods per day must be >= minimum resting periods | Validation | Create/Update | Business rule; not yet enforced at DB level [inferred from field semantics] |

**Acceptance Criteria:**
- AC1: Creating a term records teaching days, period counts, exam days, and week start day
- AC2: Composite unique constraint (session + term_code) is enforced
- AC3: `settings_json` field captures additional school-specific term parameters
- AC4: SmartTimetable solver can read `sch_academic_term` to get period grid parameters

**Integration:** Consumed by SmartTimetable (`GenerationRun` model reads `academic_session_id`), TimetableFoundation

---

### REQ-SCO-005 — Board Affiliation Management
**Priority:** P1 (Standard/Should) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** The school manages which education boards (CBSE, ICSE, State Board) it is affiliated with for each academic session. Affiliations are toggleable without disrupting the session or organization record. A school may be affiliated with multiple boards per session.

**Business Rules:**

| BR-SCO-016 | Board can only be linked when a current academic session exists | Workflow | Board toggle | System returns error if no current session; requires the session context for the board-session pivot |

**Acceptance Criteria:**
- AC1: Board affiliation toggle (`toggleBoard`) links or unlinks a board in `sch_board_organization_jnt`
- AC2: Linked boards are displayed on the organization view and printed on school documents
- AC3: Multiple boards can be simultaneously active per session

**Integration:** Reads `glb_boards` (GlobalMaster cross-DB); writes `sch_board_organization_jnt` (tenant-local pivot)

---

### REQ-SCO-006 — Holiday Calendar Management
**Priority:** P0 (Core/Must) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** The HR Officer or School Admin records all school holidays (public, religious, optional, school-specific, weekends, vacation periods) within a Leave Year container. Holidays carry metadata including type, paid/unpaid status, optional applicability (employee chooses from a list), and scope (by role or department).

**Business Rules:**

| BR-SCO-017 | Every holiday must be linked to a Leave Year | Validation | Create | `annual_leave_sessions_id` is required (FK not nullable) |
| BR-SCO-018 | Optional holidays are those from which an employee selects a given number | Validation | System behavior | `is_optional = true` marks the holiday as selectable; main calendar holiday has `is_optional = false` |
| BR-SCO-019 | A holiday's scope can be limited to a specific role or department | Workflow | Create/Edit | `applies_to_role_id` and `applies_to_department_id` are nullable; NULL means school-wide |

**Acceptance Criteria:**
- AC1: Holiday CRUD with soft delete, restore, and force delete
- AC2: Holiday type picklist includes all 8 types (Optional, Other, Public, Religious, Saturday, School_Specific, Sunday, Vacation)
- AC3: `is_paid` flag is stored and consumed by payroll calculations in HrStaff module
- AC4: Toggle status via AJAX
- AC5: Holidays are listed on the Attendance Master screen under the "Holidays" tab

**Integration:** HrStaff module reads holiday calendar for payroll and leave calculations; SmartTimetable excludes holidays from teaching day counts

---

### REQ-SCO-007 — Leave Year (Annual Leave Session) Management
**Priority:** P1 (Standard/Should) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** A Leave Year (Annual Leave Session) is the time container for all holidays and leave entitlement calculations. The HR year may differ from the academic year (e.g., April-March financial year vs. June-May academic year). The HR Officer creates and maintains Leave Years.

**Business Rules:**

| BR-SCO-020 | Leave Year name must be unique per tenant | Validation | Create | UNIQUE constraint on `name` in `sch_annual_leave_sessions` |
| BR-SCO-021 | Leave Year end date must be after start date | Validation | Create/Update | Date ordering validation |

**Acceptance Criteria:**
- AC1: Leave Year CRUD with soft delete, restore, force delete, and status toggle
- AC2: Holidays can only be created under an active Leave Year
- AC3: Name uniqueness enforced per school

---

### REQ-SCO-008 — Work Shift Configuration
**Priority:** P1 (Standard/Should) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** The HR Officer defines the daily attendance windows (shifts) for different staff groups. Each shift specifies start time, end time, break duration, grace periods for late arrival and early departure, and the threshold for marking a half-day.

**Business Rules:**

| BR-SCO-022 | Shift code must be unique per tenant | Validation | Create | UNIQUE on `code` in `sch_employee_shifts` |
| BR-SCO-023 | Only one shift can be the default | Validation | Create/Update | `is_default` flag; system should clear previous default when setting new one [inferred — not yet enforced in code] |
| BR-SCO-024 | Arriving after `start_time + grace_minutes_late` is a late mark; leaving before `end_time - grace_minutes_early` is an early departure | Calculation | Attendance marking (SCE) | These values are read by the employee attendance system |
| BR-SCO-025 | If total present minutes < `half_day_threshold_minutes`, the system marks a half-day | Calculation | Attendance marking | Consumed by SCE/HrStaff attendance calculation |

**Acceptance Criteria:**
- AC1: Shift CRUD with soft delete, restore, and status toggle
- AC2: `applies_to_days` JSON field allows specifying which weekdays the shift applies to (null = all days)
- AC3: Working hours (`working_hours`) is stored as net hours excluding break
- AC4: Shift can be assigned to individual employees (via EmployeeShiftAssignment in SCE)

---

### REQ-SCO-009 — Department Management
**Priority:** P0 (Core/Must) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** The School Admin defines the functional units (departments) of the school. Departments are used for organizing employees, scoping leave approvals, filtering complaints, and organizational reporting.

**Business Rules:**

| BR-SCO-026 | System-protected departments (is_system=true) cannot be edited or deleted by users | Permission | Edit/Delete | `is_system` flag; controller must check before allowing mutation |
| BR-SCO-027 | A department that has employees assigned cannot be force-deleted | Validation | Force Delete | Referential integrity check before permanent deletion |

**Acceptance Criteria:**
- AC1: Department CRUD with soft delete, restore, and status toggle
- AC2: System departments are read-only
- AC3: Permission prefix is `school-setup.department.*` [currently broken: uses `prime.department.*` — SCO-P1-001]
- AC4: `DepartmentPolicy` registered in SchoolSetupServiceProvider [currently missing — SCO-P1-002]

**Enhancement Notes:** ENH-SCO-003 — Department hierarchy (parent department) for large multi-campus schools

---

### REQ-SCO-010 — Designation Management
**Priority:** P0 (Core/Must) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** The School Admin defines job titles and position levels. Designations appear on employee profiles, teacher certificates, and organizational reports. They also serve as a filter dimension for leave approval policies.

**Business Rules:**

| BR-SCO-028 | System-protected designations (is_system=true) cannot be deleted | Permission | Delete | `is_system` flag guard |
| BR-SCO-029 | A designation assigned to employees cannot be force-deleted | Validation | Force Delete | Referential integrity check |

**Acceptance Criteria:**
- AC1: Designation CRUD with status toggle
- AC2: Soft delete column must be added to `sch_designations` table (currently missing — SCO-P1-006)
- AC3: `DesignationPolicy` registered [currently missing — SCO-P1-003]

---

### REQ-SCO-011 — Staff Attendance Type Configuration
**Priority:** P0 (Core/Must) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** The HR Officer configures the coded attendance categories used when marking employee daily attendance. Each type carries payroll impact (percentage of day's pay counted), presence flag (whether it counts toward percentage), and half-day eligibility.

**Business Rules:**

| BR-SCO-030 | Each attendance type code must be unique per tenant | Validation | Create | UNIQUE on `code` |
| BR-SCO-031 | System attendance types (is_system=true) cannot be deleted | Permission | Delete | Guard on `is_system` flag |
| BR-SCO-032 | At least one attendance type must have `is_present = true` | Validation | Deactivation/Delete | The system requires a "present" marker for percentage calculations [inferred] |

**Acceptance Criteria:**
- AC1: Attendance type CRUD with soft delete, restore, and display-order reordering
- AC2: `payroll_percentage` drives the payroll system's daily pay calculation when this type is marked
- AC3: `color_hex` is used in attendance calendar UI for visual coding

---

### REQ-SCO-012 — Staff Leave Type Configuration
**Priority:** P0 (Core/Must) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** The HR Officer defines all recognized leave categories (Casual Leave, Sick Leave, Earned Leave, Maternity Leave, Paternity Leave, etc.) with their full rule set governing eligibility, documentation, carry-forward, encashment, and application constraints.

**Business Rules:**

| BR-SCO-033 | Leave type code must be unique per tenant | Validation | Create | UNIQUE on `code` |
| BR-SCO-034 | `requires_substitute = true` triggers an automatic substitute-assignment flow when a teacher applies for this type | Workflow | Leave application (HrStaff) | Flag is read by HrStaff module |
| BR-SCO-035 | System leave types cannot be deleted or deactivated | Permission | Delete/Deactivate | `is_system` flag guard |
| BR-SCO-036 | `allows_back_dated = false` means the employee cannot apply retroactively | Validation | Leave application | Consumed by leave application form in HrStaff |

**Acceptance Criteria:**
- AC1: Leave type CRUD with soft delete and status toggle
- AC2: All policy flags (paid, carry-forward, encashable, requires-doc, substitute, half-day, back-dated) are persisted correctly
- AC3: `min_advance_notice_days` and `max_consecutive_days` are enforced when employees apply

---

### REQ-SCO-013 — Staff Leave Entitlement Policy
**Priority:** P0 (Core/Must) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** The HR Officer creates leave entitlement rules that determine how many days of a leave type are granted to which staff group per year, when accrual starts, carry-forward limits, and encashment rules at separation. Policies can be scoped by role, department, designation, or employment type.

**Business Rules:**

| BR-SCO-037 | Entitlement days must be greater than zero | Validation | Create/Update | `annual_entitlement > 0` |
| BR-SCO-038 | Carry-forward is only meaningful when `is_carry_forwardable = true` | Validation | Create/Update | `max_carry_forward` should only be set if carry-forward is enabled |
| BR-SCO-039 | Policy lookup order: most specific scope (role+department+designation) takes precedence over least specific | Calculation | Leave balance calculation (HrStaff) | HrStaff service resolves via `idx_lc_lookup` composite index |

**Acceptance Criteria:**
- AC1: Entitlement policy CRUD with soft delete and status toggle
- AC2: Scope filters (role, department, designation, employment type) are nullable for school-wide policies
- AC3: `accrual_method` of Monthly_Pro_Rata adjusts entitlement for mid-year joiners

---

### REQ-SCO-014 — Leave Approval Workflow Configuration
**Priority:** P1 (Standard/Should) | **Tags:** [WORKFLOW][CONFIGURATION]

**Description:** The HR Officer configures multi-level leave approval chains. Each policy is linked to one or more leave types and defines the approval levels (level 1 = immediate approver, level 2 = HOD, level 3 = Principal, etc.) with auto-escalation timing.

**Business Rules:**

| BR-SCO-040 | An approval policy must have at least one level | Validation | Save | Cannot save a policy with no approval levels |
| BR-SCO-041 | Level ordinals within a policy must be sequential and unique | Validation | Level management | Duplicate ordinals within the same policy are blocked |

**Acceptance Criteria:**
- AC1: Leave approval policy CRUD
- AC2: Policy levels can be added, reordered, and removed
- AC3: Each level can specify an approver by role, department, or designation
- AC4: `auto_approve_after_hours` triggers automatic approval if no action taken within the time limit [inferred from domain knowledge]

**Integration:** Consumed by HrStaff leave application workflow; HrStaff reads these policies to build the approval chain

---

### REQ-SCO-015 — Student Leave Type Configuration
**Priority:** P1 (Standard/Should) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** The School Admin defines leave types specifically applicable to students (e.g., Medical Leave, Family Emergency, Cultural Program). Student leave types are distinct from staff leave types and are used by the StudentProfile module.

**Business Rules:**

| BR-SCO-042 | Student leave type code must be unique per tenant | Validation | Create | UNIQUE enforcement on student leave type code |

**Acceptance Criteria:**
- AC1: Student leave type CRUD with soft delete and status toggle
- AC2: Student leave types appear as options in the student leave application form (StudentProfile module)

**Integration:** Consumed by StudentProfile module for student leave requests

---

### REQ-SCO-016 — Entity Group Management
**Priority:** P1 (Standard/Should) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** The School Admin or IT Admin creates named, purpose-tagged groups that can contain any mix of entity types (students, employees, rooms, classes, departments). Entity groups replace module-specific list management with a single generic mechanism reused by Notification, EventEngine, Transport, and other modules.

**Business Rules:**

| BR-SCO-043 | Every entity group must have a purpose from the system dropdown | Validation | Create | `entity_purpose_id` is required; purpose list managed via `sys_dropdowns` key="entity_purpose" |
| BR-SCO-044 | Group code must be unique across all groups in the tenant | Validation | Create | UNIQUE on `code` |
| BR-SCO-045 | A group with active members cannot be permanently deleted | Validation | Force Delete | Referential integrity check for member records |

**Acceptance Criteria:**
- AC1: Entity group CRUD with soft delete, restore, and status toggle
- AC2: All controller methods are protected by `Gate::authorize()` [currently partial — SCO-P1-004]
- AC3: Groups can be searched by name, code, description, and purpose

**Integration:** Consumed by Notification module for targeted broadcasts; EventEngine reads entity groups for event scope

---

### REQ-SCO-017 — Entity Group Member Management
**Priority:** P1 (Standard/Should) | **Tags:** [DATA_ENTRY]

**Description:** The admin adds or removes members from entity groups. A member can be any entity in the tenant database identified by the entity's table name and record ID. The member record stores the entity's display name and code for efficient listing without cross-table joins.

**Business Rules:**

| BR-SCO-046 | The same entity (table + record ID combination) cannot appear twice in the same group | Validation | Add member | UNIQUE on (entity_group_id, entity_table_name, entity_selected_id) |
| BR-SCO-047 | Deactivating a group does not deactivate its members | Workflow | Group deactivation | Member `is_active` flags are independent of group status |

**Acceptance Criteria:**
- AC1: Members can be added and removed from a group
- AC2: Membership record stores entity_name and entity_code for display without re-querying source table
- AC3: Deactivated members remain in the group but are excluded from active operations
- AC4: `sch_entity_group_members` table migration must be verified/created [currently unlocated — SCO-P0-002]

---

### REQ-SCO-018 — System Dropdown Master Management
**Priority:** P0 (Core/Must) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** The IT Admin manages the platform's lookup value library. Every dropdown in every module draws from `sys_dropdowns`. The `sys_dropdown_needs` registry catalogues which database fields require dropdown values. The `sys_dropdown_need_dropdowns_jnt` maps specific dropdown values to specific field needs.

**Business Rules:**

| BR-SCO-048 | Dropdown key+value combination must be unique | Validation | Create | UNIQUE on (key, value) |
| BR-SCO-049 | Ordinal must be unique within a key group | Validation | Create | UNIQUE on (key, ordinal) |
| BR-SCO-050 | Tenant-creation-allowed needs must supply all menu path attributes; system-managed needs must have no menu paths | Validation | Create (dropdown_need) | MySQL CHECK constraint on `sys_dropdown_needs` enforces this |

**Acceptance Criteria:**
- AC1: Dropdown values can be created, edited, reordered, and soft-deleted per group (key)
- AC2: `additional_info` JSON field stores supplementary metadata (e.g., colour codes for status badges)
- AC3: `sys_dropdown_needs` registry is seeded during deployment and is visible (read-only) to IT Admin
- AC4: Field needs marked `tenant_creation_allowed = true` are visible in the admin UI for school-specific additions

**Integration:** ALL modules read `sys_dropdowns` for their option lists; entity groups, holidays, leave types all reference `sys_dropdowns` for purpose/type lookups

---

### REQ-SCO-019 — School Module Configuration
**Priority:** P0 (Core/Must) | **Tags:** [CONFIGURATION]

**Description:** The IT Admin manages a key-value configuration store (`sch_configs`) that controls module-level behavior for this school. Configuration parameters are seeded by the platform for each module with defaults, and schools can modify those marked `tenant_can_modify = true`.

**Business Rules:**

| BR-SCO-051 | Config key must be unique per school tenant | Validation | Create | UNIQUE on `key` |
| BR-SCO-052 | Only config entries with `tenant_can_modify = true` can be edited by school admins | Permission | Edit | `tenant_can_modify` flag guards edit access |
| BR-SCO-053 | Config value type must match the `value_type` enum | Validation | Create/Update | Controller coerces booleans to "0"/"1"; other types validated at store |

**Acceptance Criteria:**
- AC1: Config entries are listed with module grouping and ordinal sorting
- AC2: School admins can edit only tenant-modifiable entries
- AC3: Config entries support soft delete, restore, and status toggle (for platform-level management)
- AC4: `SchConfigSeeder` seeds default config values during tenant initialization

---

### REQ-SCO-020 — School User Account Management
**Priority:** P0 (Core/Must) | **Tags:** [DATA_ENTRY][CONFIGURATION]

**Description:** The School Admin creates and manages user accounts for all school staff, teachers, and administrators. Users are assigned Spatie roles that control their access to modules. The system prevents privilege escalation via the `is_super_admin` field.

**Business Rules:**

| BR-SCO-054 | `is_super_admin` must not be settable via the user edit form | Permission | User update | `is_super_admin` must be removed from UserRequest, controller data extraction, User model `$fillable`, and edit view [P0 security gap per V2 doc] |
| BR-SCO-055 | Assigning the Teacher role to a user redirects to teacher profile completion | Workflow | Role assignment | If 'Teacher' role is assigned, system prompts teacher profile creation in SCE |

**Acceptance Criteria:**
- AC1: User CRUD with soft delete, restore, force delete, and status toggle
- AC2: `is_super_admin` is not writable via the school-facing user edit form
- AC3: Role assignment via Spatie works correctly; teacher role triggers SCE profile prompt
- AC4: `rand()` placeholder in index view replaced with real database counts [SCO-P1 gap from V2 doc]

---

### REQ-SCO-021 — Role and Permission Management
**Priority:** P0 (Core/Must) | **Tags:** [CONFIGURATION]

**Description:** The IT Admin manages Spatie roles and assigns granular permissions to control which school users can access which features. The Role Destroy function is corrected to actually delete roles (currently broken — calls `save()` instead of `delete()`).

**Business Rules:**

| BR-SCO-056 | Role destroy must call `delete()` not `save()` | Workflow | Role delete | Current code bug: `$role->save()` in `destroy()` method means roles are never deleted [P1 from V2 doc] |
| BR-SCO-057 | `PermissionSyncController::sync()` must be protected by Gate authorization | Permission | Permission sync | Only users with `school-setup.permission.sync` permission can run the sync |

**Acceptance Criteria:**
- AC1: Role create, edit, and permission sync all work
- AC2: `RolePermissionController::destroy()` calls `$role->delete()` [currently broken]
- AC3: Permission sync route requires `Gate::authorize('school-setup.permission.sync')` [currently unprotected — SCO-P1-005]
- AC4: AJAX permission-toggle and permission-load endpoints return correct JSON

---

## 4. Business Rules Register (consolidated)

| ID | Rule | Type | Trigger | Priority |
|----|------|------|---------|---------|
| BR-SCO-001 | One organization record per tenant (flg_single_record UNIQUE) | Validation | Create Organization | P0 |
| BR-SCO-002 | City selection auto-resolves district, state, country | Calculation | Save Organization | P0 |
| BR-SCO-003 | Board affiliations synced atomically on each org save | Workflow | Store/Update Organization | P0 |
| BR-SCO-004 | School logo is single-file; upload replaces existing | Validation | Logo upload | P1 |
| BR-SCO-005 | All CUD operations produce activity log entry | Workflow | Every CUD | P0 |
| BR-SCO-006 | Soft delete deactivates before hiding | Workflow | Delete any entity | P0 |
| BR-SCO-007 | Organization group name unique per tenant | Validation | Create/Update group | P1 |
| BR-SCO-008 | Group is optional for standalone schools | Validation | System behavior | P1 |
| BR-SCO-009 | Only one academic session can be current (UNIQUE constraint) | Concurrency | Set-as-current | P0 |
| BR-SCO-010 | Session end date must be after start date | Validation | Create/Update Session | P0 |
| BR-SCO-011 | Session short name unique within school | Validation | Create/Update Session | P0 |
| BR-SCO-012 | Board toggle requires an active current session | Workflow | Board toggle | P0 |
| BR-SCO-013 | Term code unique within its session | Validation | Create/Update Term | P1 |
| BR-SCO-014 | Only one academic term can be current per session | Concurrency | Set-as-current Term | P1 |
| BR-SCO-015 | Teaching periods per day >= minimum resting periods | Validation | Create/Update Term | P2 |
| BR-SCO-016 | Board affiliation linked per session context | Workflow | Board management | P1 |
| BR-SCO-017 | Holiday must be linked to a Leave Year | Validation | Create Holiday | P0 |
| BR-SCO-018 | is_optional distinguishes selectable vs mandatory holidays | Validation | Holiday type | P1 |
| BR-SCO-019 | Holiday scope: NULL means school-wide; FK → role or department | Workflow | Holiday targeting | P1 |
| BR-SCO-020 | Leave Year name unique per tenant | Validation | Create Leave Year | P0 |
| BR-SCO-021 | Leave Year end date after start date | Validation | Create/Update Leave Year | P0 |
| BR-SCO-022 | Shift code unique per tenant | Validation | Create Shift | P0 |
| BR-SCO-023 | Only one shift is the default | Validation | Set-as-default | P1 |
| BR-SCO-024 | Late arrival: arrival after start_time + grace_minutes_late | Calculation | Attendance marking (SCE) | P0 |
| BR-SCO-025 | Half-day: present minutes < half_day_threshold_minutes | Calculation | Attendance marking (SCE) | P0 |
| BR-SCO-026 | System departments (is_system=true) are read-only | Permission | Edit/Delete Department | P0 |
| BR-SCO-027 | Department with employees cannot be force-deleted | Validation | Force Delete Department | P0 |
| BR-SCO-028 | System designations are read-only | Permission | Delete Designation | P0 |
| BR-SCO-029 | Designation with employees cannot be force-deleted | Validation | Force Delete Designation | P0 |
| BR-SCO-030 | Attendance type code unique per tenant | Validation | Create Attendance Type | P0 |
| BR-SCO-031 | System attendance types cannot be deleted | Permission | Delete Attendance Type | P0 |
| BR-SCO-032 | At least one attendance type must be a "present" type | Validation | Deactivate/delete | P0 |
| BR-SCO-033 | Leave type code unique per tenant | Validation | Create Leave Type | P0 |
| BR-SCO-034 | requires_substitute flag triggers sub-assignment flow (HrStaff) | Workflow | Leave application | P1 |
| BR-SCO-035 | System leave types cannot be deleted or deactivated | Permission | Delete/Deactivate | P0 |
| BR-SCO-036 | allows_back_dated=false prevents retroactive application | Validation | Leave application (HrStaff) | P1 |
| BR-SCO-037 | Annual entitlement must be > 0 | Validation | Create/Update Entitlement Policy | P0 |
| BR-SCO-038 | max_carry_forward only applicable when carry-forward is enabled | Validation | Create/Update Entitlement Policy | P1 |
| BR-SCO-039 | Most specific policy scope takes precedence (role+dept+desig > school-wide) | Calculation | Leave balance calc (HrStaff) | P1 |
| BR-SCO-040 | Approval policy must have at least one level | Validation | Save Policy | P1 |
| BR-SCO-041 | Level ordinals within a policy must be sequential and unique | Validation | Add/Edit Level | P1 |
| BR-SCO-042 | Student leave type code unique per tenant | Validation | Create | P1 |
| BR-SCO-043 | Entity group must have a purpose from sys_dropdowns | Validation | Create Entity Group | P1 |
| BR-SCO-044 | Entity group code unique across all groups | Validation | Create Entity Group | P1 |
| BR-SCO-045 | Entity group with active members cannot be force-deleted | Validation | Force Delete Group | P1 |
| BR-SCO-046 | Same entity cannot appear twice in one group | Validation | Add Member | P1 |
| BR-SCO-047 | Deactivating a group does not deactivate members | Workflow | Group deactivation | P1 |
| BR-SCO-048 | Dropdown key+value combination unique | Validation | Create Dropdown | P0 |
| BR-SCO-049 | Dropdown ordinal unique within key group | Validation | Create Dropdown | P0 |
| BR-SCO-050 | Dropdown need: tenant_creation_allowed controls menu path requirement | Validation | Create dropdown_need | P0 |
| BR-SCO-051 | Config key unique per school tenant | Validation | Create Config | P0 |
| BR-SCO-052 | Only tenant_can_modify=true configs editable by school admins | Permission | Edit Config | P0 |
| BR-SCO-053 | Config value type must match value_type enum | Validation | Create/Update Config | P0 |
| BR-SCO-054 | is_super_admin not writable via school user form | Permission | User update | P0 |
| BR-SCO-055 | Teacher role assignment triggers teacher profile prompt | Workflow | Role assignment | P1 |
| BR-SCO-056 | Role destroy must call delete() not save() | Workflow | Role delete | P1 |
| BR-SCO-057 | Permission sync requires Gate authorization | Permission | sync action | P1 |

---

## 5. Data Requirements

### 5.1 Core Data Entities

**School Profile (`sch_organizations`)**
| Business Field | Meaning | Type | Required | PII? |
|----------------|---------|------|---------|------|
| School Code | Unique short identifier used in all cross-references | Char(20) | Yes | No |
| School Name | Full official name | String(150) | Yes | No |
| Short Name | Abbreviated name for display | String(50) | Yes | No |
| UDISE Code | Government school registration number | String(30) | No | No |
| Affiliation Number | Board affiliation certificate number | String(60) | No | No |
| CRC/BRC Code | Cluster/Block Resource Center codes | String(30) | No | No |
| Instruction Language | Primary medium of instruction | String(20) | No | No |
| Rural/Urban | Geographic classification | Enum | No | No |
| Email | School's official email | String(100) | No | Confidential |
| Website | School's website URL | String(150) | No | No |
| Address | Full postal address (lines 1 and 2) | String(200) each | No | Internal |
| City | City (links to global city master) | FK | Yes | No |
| Pincode | Postal code | String(10) | No | No |
| Phone Numbers | Primary and secondary phone | String(20) each | No | Internal |
| WhatsApp Number | WhatsApp contact | String(20) | No | Internal |
| Coordinates | GPS longitude and latitude | Decimal(10,7) | No | No |
| Locale | Language-region setting (e.g., en_IN) | String(16) | No | No |
| Currency | Default currency code (INR) | String(8) | No | No |
| Established Date | School founding date | Date | No | No |
| School Logo | Branding image (Spatie Media Library) | File | No | No |

**Academic Session (`sch_org_academic_sessions_jnt`)**
| Business Field | Meaning | Type | Required | PII? |
|----------------|---------|------|---------|------|
| Global Session Reference | Link to platform-level academic year | FK | Yes | No |
| Display Name | School's label for this session (e.g., "2026-27") | String(50) | Yes | No |
| Short Name | Abbreviated label (e.g., "26-27") | String(10) | Yes | No |
| Start Date | School-specific session start | Date | Yes | No |
| End Date | School-specific session end | Date | Yes | No |
| Is Current | Whether this is the active working session | Boolean | No | No |

**Holiday (`sch_holidays`)**
| Business Field | Meaning | Type | Required | PII? |
|----------------|---------|------|---------|------|
| Holiday Date | The calendar date | Date | Yes | No |
| Name | Holiday name | String(150) | Yes | No |
| Type | Category (Public / Religious / School_Specific / etc.) | Enum | Yes | No |
| Is Optional | Whether employees choose from a list | Boolean | No | No |
| Is Paid | Whether pay is full on this holiday | Boolean | No | No |
| Scope: Role | Limit to specific user role (or null = all) | FK nullable | No | No |
| Scope: Department | Limit to specific department (or null = all) | FK nullable | No | No |

**System Dropdown (`sys_dropdowns`)**
| Business Field | Meaning | Type | Required | PII? |
|----------------|---------|------|---------|------|
| Group Key | The dropdown group name (e.g., "entity_purpose") | String(160) | Yes | No |
| Display Value | The option label shown to users | String(100) | Yes | No |
| Value Type | Data type of the stored value | Enum | Yes | No |
| Display Order | Sort position within the group | TinyInt | Yes | No |
| Extra Info | Additional metadata in JSON | JSON | No | No |

Privacy classification: all SCO data is classified as Internal unless noted. No Sensitive (PII/health) data is stored in SCO tables.

### 5.2 Data Isolation
All tables in this module reside in the tenant database (`tenant_{uuid}`). Data is isolated per school with no `tenant_id` column — isolation is enforced by database-per-tenant architecture (stancl/tenancy v3.9). Cross-DB reads (glb_academic_sessions, glb_boards, glb_cities) use the `global_master_mysql` connection and are read-only from the tenant side.

---

## 6. Workflows

### Workflow 1: New Academic Year Rollover
**Trigger:** School Admin decides to transition to the next academic year
**End States:** New session is current; old session is archived
**Actors:** School Admin | System

1. Admin navigates to Academic Sessions and creates a new session by linking to a global session and setting school-specific dates
2. Admin marks the new session as current → System atomically unmarks previous current session (`current_flag` UNIQUE ensures DB-level safety)
3. Admin creates Academic Terms for the new session (Term 1, Term 2, etc.) with period structure and calendar parameters
4. Admin links the school's board affiliations for the new session via board toggle
5. Admin creates Leave Year for new HR year and adds holidays
6. System now resolves all "current session" references to the new session

**Exception Path A:** Admin marks wrong session as current → Admin marks the correct session as current → system automatically switches back
**Exception Path B:** No global academic session exists for the new year → System Prompt admin to contact Platform Admin (GlobalMaster) to create the session first

**Notifications:** None triggered by this workflow in SCO. Downstream modules (SmartTimetable, StudentFee) may need manual reconfiguration after year rollover.

---

### Workflow 2: School Profile First-Time Setup
**Trigger:** New tenant database provisioned; admin logs in for the first time
**End States:** Organization profile complete; academic session linked; board(s) affiliated
**Actors:** School Admin | System

1. Admin opens Organization Setup → enters school name, code, government codes, address, and contact details
2. Admin selects city (system resolves district, state, country automatically)
3. Admin uploads school logo → stored as single-file media collection
4. Admin selects affiliated board(s) — board sync happens on save
5. Admin navigates to Academic Sessions → links current year session and sets it as current
6. Admin creates term subdivisions

**Exception Path:** Admin submits without required fields → validation errors displayed inline; no record saved

---

### Workflow 3: Holiday Calendar Population
**Trigger:** New Leave Year created; HR Officer populates holidays for the year
**End States:** Holiday calendar fully populated for the year
**Actors:** HR Officer | System

1. HR Officer creates a Leave Year with name, start date, and end date
2. HR Officer adds holidays one by one (or in bulk if bulk-import added) — each holiday linked to the Leave Year
3. HR Officer marks each holiday with its type (Public, Religious, School_Specific, etc.)
4. HR Officer optionally limits holiday scope to a specific role or department (e.g., Saturday only for teaching staff)
5. HR Officer marks some holidays as Optional for employee selection

**Exception Path:** Attempting to add a holiday without first creating a Leave Year → system blocks with validation error (FK required)

**Integration:** HrStaff reads this calendar for leave calculation and payroll; SmartTimetable excludes holidays from teaching day totals

---

### Workflow 4: Staff Leave Configuration
**Trigger:** New academic year begins or employment policy changes
**End States:** All leave types and entitlement policies up to date for new year
**Actors:** HR Officer | System

1. HR Officer reviews existing leave types (CL, SL, EL, ML, PL, COMP, LWP) — system types cannot be modified; HR adds school-specific types
2. HR Officer creates Leave Entitlement Policies: for each leave type, sets annual entitlement days, accrual method, carry-forward rules, and scope (role / department / designation / employment type)
3. HR Officer creates Leave Approval Policies: for each leave type, defines the approval levels and assigns approvers by role
4. System is now ready for leave applications in the HrStaff module

**Exception Path:** Conflicting entitlement policies for the same scope → HR Officer must resolve by deactivating duplicate policies; system uses highest-priority active policy

---

### Workflow 5: Entity Group Creation
**Trigger:** Admin needs to define a named group for notifications, events, or operations
**End States:** Named group exists with members assigned
**Actors:** School Admin or IT Admin | System

1. Admin creates Entity Group: selects purpose from dropdown (e.g., "duty_roster", "transport_route"), enters name and code
2. Admin adds members: selects entity type (Student, Employee, Room, etc.), then picks specific records from that entity type
3. System stores entity_table_name + entity_selected_id + entity_name + entity_code for each member
4. Group is now available as a target in Notification, EventEngine, and other consuming modules

**Exception Path:** Attempting to add the same entity twice → system returns a duplicate member error

---

### Workflow 6: Permission Synchronization
**Trigger:** New module deployed or controller methods added; permissions need reseeding
**End States:** All permissions from all controllers are present in the `sys_permissions` table
**Actors:** IT Admin (Super Admin only) | System

1. Super Admin triggers `/sync-permissions` route
2. `PermissionSyncController::sync()` scans all registered controllers for permission strings
3. System inserts new permissions; existing permissions are not duplicated (idempotent)
4. Admin assigns newly seeded permissions to the appropriate roles via Role Permission Management

**Exception Path:** Sync route called by non-super-admin → System must reject with 403 [currently unprotected — SCO-P1-005]

---

## 7. Reporting and Analytics

### RPT-SCO-001 — Organization Profile Summary Report
**Purpose:** Official school profile for regulatory submission, letterhead setup, and platform audit
**Audience:** School Admin, Principal
**Frequency:** On demand
**Contents:** School name, code, UDISE code, affiliation number, board(s), address, contact, established date, current academic session
**Filters:** None (single-record)
**Export:** PDF (with school logo)
**Rules:** Reads from `sch_organizations` + `sch_org_academic_sessions_jnt` (current session) + `sch_board_organization_jnt` + `glb_boards`

---

### RPT-SCO-002 — Holiday Calendar Report
**Purpose:** Full year holiday list for staff planning and payroll reference
**Audience:** HR Officer, All Staff (view), School Admin
**Frequency:** Beginning of each Leave Year; on demand
**Contents:** Date, holiday name, type, paid/unpaid flag, applicable scope (all staff / specific role / department), optional flag
**Filters:** Leave Year, Holiday Type, Role, Department
**Export:** PDF, Excel

---

### RPT-SCO-003 — Department-Designation Directory
**Purpose:** Organizational chart reference listing all active departments and their designations with employee counts
**Audience:** School Admin, Principal, HR Officer
**Frequency:** On demand
**Contents:** Department name, code, active employee count; sub-list of designations within each department with employee count
**Filters:** Active/inactive status
**Export:** PDF, Excel

---

### RPT-SCO-004 — Leave Type Summary Sheet
**Purpose:** Quick reference for HR and employees listing all leave types and their key parameters
**Audience:** HR Officer, All Staff
**Frequency:** Beginning of academic year; on demand
**Contents:** Leave type code, name, paid flag, carry-forward flag, encashable flag, documentation required, annual entitlement (per policy), approval levels count
**Filters:** Employment type, Active status
**Export:** PDF

---

### RPT-SCO-005 — System Configuration Audit Report
**Purpose:** Platform audit trail of all school configuration parameters — useful during compliance checks and technical audits
**Audience:** IT Admin, School Admin
**Frequency:** On demand
**Contents:** Module code, config key, key name, current value, value type, mandatory flag, tenant-modifiable flag, last modified date
**Filters:** Module, Value Type, tenant_can_modify flag
**Export:** Excel

---

## 8. Future Enhancements

| ENH-ID | Description | Priority |
|--------|-------------|---------|
| ENH-SCO-001 | Support multiple logo variants (primary + letterhead + favicon) | P2 |
| ENH-SCO-002 | Separate sch_organization_groups table with full hierarchy (parent → child) for group-level reporting | P2 |
| ENH-SCO-003 | Department hierarchy support (parent department) for large multi-department schools | P2 |
| ENH-SCO-004 | Bulk holiday import via CSV/Excel template | P1 |
| ENH-SCO-005 | Social media links on school profile (Facebook, Twitter, Instagram) displayed on student/parent portal | P2 |
| ENH-SCO-006 | Grading system configuration (A+ to D or 1–10 scale) as part of school config — consumed by marksheet and report cards | P1 |
| ENH-SCO-007 | Academic year rollover wizard — guides admin through all steps (session, terms, holidays, leave policies) in sequence | P1 |
| ENH-SCO-008 | BoardAffiliationService — extract board sync logic from controller into a dedicated service for reuse across board-update flows | P1 |

---

## 9. Non-Functional Requirements

### 9.1 Performance
| NFR-SCO-001 | School profile and academic session pages must load within 2 seconds for standard connections |
| NFR-SCO-002 | AJAX calls for session create/update must respond within 1 second |
| NFR-SCO-003 | System dropdown reads (used in every module form) must be cached per tenant; maximum cache TTL 15 minutes |
| NFR-SCO-004 | Holiday calendar listing must support up to 400 holidays per Leave Year without pagination degradation |

### 9.2 Security
| NFR-SCO-005 | `is_super_admin` must not be settable via any school-facing form endpoint |
| NFR-SCO-006 | All SCO controller methods must call `Gate::authorize()` before any data access or mutation |
| NFR-SCO-007 | Permission sync endpoint must be restricted to Super Admin role only |
| NFR-SCO-008 | Cross-DB reads (GlobalMaster) must use the named `global_master_mysql` connection exclusively; never mix connections |
| NFR-SCO-009 | Activity logs must capture before/after values for all update operations; no raw request data in log JSON |

### 9.3 Usability
| NFR-SCO-010 | Academic session management must be AJAX-driven (no full-page reloads) |
| NFR-SCO-011 | Attendance types and leave types must support display-order drag-and-drop reordering |
| NFR-SCO-012 | School profile form must have inline city-based auto-fill for district, state, and country |

---

## 10. Gap Analysis Readiness Index

### 10.1 Coverage Table

| REQ-ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification | Test Case Needed |
|--------|---------|---------|------|:-:|:-:|:-:|:-:|:-:|
| REQ-SCO-001 | School Profile Management | P0 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-002 | Organization Group Management | P1 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-003 | Academic Session Mapping | P0 | DATA_ENTRY, CONFIGURATION, WORKFLOW | No | Yes | No | No | Yes |
| REQ-SCO-004 | Academic Term Definition | P1 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-005 | Board Affiliation Management | P1 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-006 | Holiday Calendar Management | P0 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-007 | Leave Year Management | P1 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-008 | Work Shift Configuration | P1 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-009 | Department Management | P0 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-010 | Designation Management | P0 | DATA_ENTRY, CONFIGURATION | Yes (add softDeletes) | Yes | No | No | Yes |
| REQ-SCO-011 | Staff Attendance Type Configuration | P0 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-012 | Staff Leave Type Configuration | P0 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-013 | Staff Leave Entitlement Policy | P0 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-014 | Leave Approval Workflow Configuration | P1 | WORKFLOW, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-015 | Student Leave Type Configuration | P1 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-016 | Entity Group Management | P1 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-017 | Entity Group Member Management | P1 | DATA_ENTRY | Yes (verify migration) | Yes | No | No | Yes |
| REQ-SCO-018 | System Dropdown Master Management | P0 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-019 | School Module Configuration | P0 | CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-020 | School User Account Management | P0 | DATA_ENTRY, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-SCO-021 | Role and Permission Management | P0 | CONFIGURATION | No | Yes | No | No | Yes |

### 10.2 Business Rule Coverage

| Status | Count |
|--------|-------|
| Covered by active code | 38 of 57 BRs |
| Partially covered (logic present, not enforced) | 9 BRs |
| Not yet enforced (gap) | 10 BRs (BR-SCO-015, BR-SCO-023, BR-SCO-026→029, BR-SCO-054, BR-SCO-056, BR-SCO-057) |

### 10.3 Report Coverage

| Report | Status |
|--------|--------|
| RPT-SCO-001 (Org Profile) | No dedicated report view — data available in show screen |
| RPT-SCO-002 (Holiday Calendar) | Partial — list view exists; no printable PDF |
| RPT-SCO-003 (Dept-Designation Directory) | Not built |
| RPT-SCO-004 (Leave Type Summary) | Not built |
| RPT-SCO-005 (Config Audit) | Not built |

### 10.4 Totals

| Metric | Count |
|--------|-------|
| Total REQ | 21 |
| P0 (Core/Must) | 10 |
| P1 (Standard/Should) | 8 |
| P2 (Enhanced/Could) | 3 |
| Total BR | 57 |
| Total RPT | 5 |
| Total ENH | 8 |
| Total Workflows | 6 |
| FSM Entities | 3 (Academic Session current state, Leave Year active state, Entity Group active state) |

---

# Section 2: Requirements Traceability Matrix (RTM)

| REQ-ID | Feature | BR Refs | Primary Screen | Workflow | Report | Code Status | Key Gap |
|--------|---------|---------|---------------|---------|--------|-------------|---------|
| REQ-SCO-001 | School Profile | BR-SCO-001,002,003,004,005,006 | Organization create/edit | WF-2 | RPT-SCO-001 | DONE (80%) | $request->all() bug (SCO-P0-001) |
| REQ-SCO-002 | Organization Group | BR-SCO-007,008 | Organization Group index/create | — | — | DONE (85%) | — |
| REQ-SCO-003 | Academic Sessions | BR-SCO-009,010,011,012 | AJAX modal on org page | WF-1 | — | DONE (85%) | Standalone CRUD stubs empty |
| REQ-SCO-004 | Academic Terms | BR-SCO-013,014,015 | Academic term create/edit | WF-1 | — | DONE (80%) | BR-015 not enforced |
| REQ-SCO-005 | Board Affiliations | BR-SCO-016 | Board toggle in org page | WF-1 | — | DONE (80%) | — |
| REQ-SCO-006 | Holiday Calendar | BR-SCO-017,018,019 | leave-master/holidays/* | WF-3 | RPT-SCO-002 | DONE (85%) | No bulk import |
| REQ-SCO-007 | Leave Year | BR-SCO-020,021 | annual-leave-sessions/* | WF-3 | — | DONE (85%) | — |
| REQ-SCO-008 | Work Shifts | BR-SCO-022,023,024,025 | employee-shifts/* | — | — | DONE (80%) | BR-023 not enforced |
| REQ-SCO-009 | Departments | BR-SCO-026,027 | department-designation/* | — | RPT-SCO-003 | PARTIAL (70%) | Wrong perm prefix; no policy |
| REQ-SCO-010 | Designations | BR-SCO-028,029 | department-designation/* | — | RPT-SCO-003 | PARTIAL (65%) | No softDeletes; no policy |
| REQ-SCO-011 | Attendance Types | BR-SCO-030,031,032 | attendance-master/* | — | — | DONE (80%) | — |
| REQ-SCO-012 | Staff Leave Types | BR-SCO-033,034,035,036 | leave-master/* | WF-4 | RPT-SCO-004 | DONE (85%) | — |
| REQ-SCO-013 | Leave Entitlement | BR-SCO-037,038,039 | leave-config/* | WF-4 | — | DONE (80%) | Scope precedence logic in HrStaff |
| REQ-SCO-014 | Leave Approval | BR-SCO-040,041 | leave-master approval/* | WF-4 | — | DONE (75%) | Auto-escalation not verified |
| REQ-SCO-015 | Student Leave Types | BR-SCO-042 | attendance-master/* (tab) | — | — | DONE (80%) | — |
| REQ-SCO-016 | Entity Groups | BR-SCO-043,044,045 | entity-group-mgmt/* | WF-5 | — | PARTIAL (60%) | Partial auth coverage |
| REQ-SCO-017 | Entity Group Members | BR-SCO-046,047 | entity-group-mgmt/* | WF-5 | — | PARTIAL (55%) | Migration not located |
| REQ-SCO-018 | System Dropdowns | BR-SCO-048,049,050 | system-config/* (shared) | — | RPT-SCO-005 | PARTIAL (60%) | Admin UI unclear |
| REQ-SCO-019 | School Config | BR-SCO-051,052,053 | system-config/* | — | RPT-SCO-005 | DONE (80%) | — |
| REQ-SCO-020 | User Accounts | BR-SCO-054,055 | user/* | — | — | DONE (75%) | is_super_admin security gap |
| REQ-SCO-021 | Role & Permissions | BR-SCO-056,057 | role-permission/* | WF-6 | — | PARTIAL (70%) | destroy() bug; sync unprotected |

---

# Section 3: Business Rules Register + Requirement Conditions + Validation Catalog

## Requirement Conditions Catalog

| BR-ID | Entity / Field | Condition | Type | Trigger | On-Violation |
|-------|---------------|-----------|------|---------|-------------|
| BR-SCO-001 | sch_organizations | Only one record per tenant (flg_single_record UNIQUE) | Validation | CREATE | Database constraint error |
| BR-SCO-002 | city_id → district, state, country | Auto-resolved on save | Calculation | Store/Update | N/A (auto-fill) |
| BR-SCO-006 | is_active / deleted_at | Soft delete deactivates first | Workflow | DELETE | is_active set false, then deleted_at set |
| BR-SCO-009 | sch_org_academic_sessions_jnt.current_flag | UNIQUE MySQL constraint on generated column | Concurrency | SET AS CURRENT | DB integrity error if duplicate current attempted at race |
| BR-SCO-012 | board toggle | Current session must exist | Workflow | toggleBoard() | 422 JSON error returned |
| BR-SCO-026 | sch_departments.is_system | is_system=true → no edit or delete | Permission | EDIT/DELETE | 403 Forbidden |
| BR-SCO-050 | sys_dropdown_needs.tenant_creation_allowed | If 1: all menu path fields required; if 0: all must be NULL | Validation | CREATE | CHECK constraint violation (DB-level) |
| BR-SCO-054 | sys_users.is_super_admin | Not in UserRequest, $request->only(), or $fillable | Permission | UPDATE | Field silently dropped if not in $fillable [gap: currently in $fillable] |

## Validation and Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty / Null | Concurrency |
|---|---|---|---|---|---|
| sch_organizations: city_id | City "Mumbai" → auto-resolves Maharashtra, Maharashtra, India | Non-existent city ID | City at state border (same district, two states) | NULL city_id → validation error | Two admins editing different org fields simultaneously (safe: single record, optimistic lock) |
| sch_org_academic_sessions_jnt: is_current | Setting 2026-27 as current | Attempting to set two sessions current simultaneously | Exactly one session exists | No current session → modules break; warn user | Race: two admins set different sessions as current → DB UNIQUE on current_flag lets only one through |
| sch_holidays: holiday_date | 2026-08-15 (Independence Day) | 2025-02-30 (invalid date) | First or last day of Leave Year | Missing date → required validation | Two staff add same date → allowed (no unique on date per leave year) |
| sch_employee_shifts: working_hours | 8.00 hours | 0 or negative | Exactly 24 hours | NULL → DB stores 0.00 by default | — |
| sys_dropdowns: key+value | ("holiday_type", "Public") | Duplicate ("holiday_type", "Public") | Single character value | Empty value → validation required | Two admins adding same value → DB unique constraint rejects second |
| sch_configs: value / value_type BOOLEAN | "1" or "0" | "yes" when type is BOOLEAN | — | Empty string → validation error | — |

---

# Section 4: Process Flows + FSM Catalog

## Process Flows

*Full workflow narratives are in Section 6 of the FRD (Workflows 1–6 above).*

Summary reference:
| WF | Name | Trigger | Actors |
|----|------|---------|--------|
| WF-1 | Academic Year Rollover | Year-end admin decision | School Admin, System |
| WF-2 | First-Time School Profile Setup | New tenant provisioning | School Admin, System |
| WF-3 | Holiday Calendar Population | New Leave Year created | HR Officer, System |
| WF-4 | Staff Leave Configuration | Policy change / year start | HR Officer, System |
| WF-5 | Entity Group Creation | Operational need | Admin / IT Admin, System |
| WF-6 | Permission Synchronization | New module/controller deployed | IT Admin (Super Admin), System |

## FSM Catalog

### FSM-SCO-001: Academic Session State

| From State | Event / Action | Guard | To State | Side-Effects |
|-----------|---------------|-------|---------|-------------|
| Active | Set as Current | No other session marked current | Current | All other sessions set to non-current atomically |
| Current | Set Different Session as Current | — | Active | current_flag cleared |
| Active / Current | Soft Delete | No dependent class-sections or fee structures referenced | Trashed | is_active=false, deleted_at set |
| Trashed | Restore | — | Active | deleted_at cleared |
| Trashed | Force Delete | No dependent records | Deleted | Permanent removal |

**Illegal transition:** Cannot force-delete a Current session (would break all tenant modules)

---

### FSM-SCO-002: Holiday Record State

| From State | Event / Action | Guard | To State | Side-Effects |
|-----------|---------------|-------|---------|-------------|
| Active | Toggle Off | — | Inactive | Excluded from payroll/timetable calculations |
| Inactive | Toggle On | — | Active | Re-included in calculations |
| Active | Soft Delete | — | Trashed | Excluded from calendar display |
| Trashed | Restore | — | Active | Re-appears in calendar |
| Trashed | Force Delete | No attendance or payroll records referencing it | Deleted | Permanent removal |

---

### FSM-SCO-003: Entity Group State

| From State | Event / Action | Guard | To State | Side-Effects |
|-----------|---------------|-------|---------|-------------|
| Active | Toggle Off | — | Inactive | Hidden from Notification and EventEngine target lists |
| Inactive | Toggle On | — | Active | Re-appears as available target |
| Active | Soft Delete | Group has no active downstream operations | Trashed | Members remain but group excluded from active operations |
| Trashed | Restore | — | Active | Group visible again |
| Trashed | Force Delete | No active members | Deleted | Permanent removal |

**Deactivating a group does not change member `is_active` flags (BR-SCO-047)**

---

# Section 5: Data Dictionary + Cross-Module Dependency Map

## Data Dictionary (Business View)

### sch_organizations

| Business Field | Table.Column | Required | Privacy |
|----------------|-------------|---------|---------|
| School Code | sch_organizations.code | Yes | Internal |
| School Name | sch_organizations.name | Yes | Public |
| UDISE Code | sch_organizations.udise_code | No | Internal |
| Affiliation Number | sch_organizations.affiliation_no | No | Internal |
| Instruction Language | sch_organizations.instruction_language | No | Public |
| Location Type | sch_organizations.rural_urban | No | Public |
| Official Email | sch_organizations.email | No | Confidential |
| Website | sch_organizations.website_url | No | Public |
| Coordinates | sch_organizations.longitude / .latitude | No | Internal |
| School Logo | sys_media (via Spatie Media Library) | No | Public |

### sys_dropdowns

| Business Field | Table.Column | Notes |
|----------------|-------------|-------|
| Dropdown Group | sys_dropdowns.key | All values sharing a key = one dropdown list |
| Option Label | sys_dropdowns.value | Displayed to users |
| Data Type | sys_dropdowns.type | Controls how value is parsed by consuming code |
| Sort Order | sys_dropdowns.ordinal | Within-group display order |
| Metadata | sys_dropdowns.additional_info | JSON; e.g., badge colour for status indicators |

### sch_configs

| Business Field | Table.Column | Notes |
|----------------|-------------|-------|
| Module | sch_configs.module_code | 3-char code links to GlobalMaster module registry |
| Parameter Key | sch_configs.key | Unique identifier consumed by application code |
| Value | sch_configs.value | Stored as string; cast by value_type at read time |
| Editable by School | sch_configs.tenant_can_modify | Boolean; controls school admin edit access |

## Cross-Module Dependency Map

### Inbound (SCO Provides Data To)

| Target Module | Entity / Data | Tables | Mechanism |
|--------------|--------------|--------|-----------|
| SCC (ClassSetup) | Academic sessions, departments, designations | sch_org_academic_sessions_jnt, sch_departments, sch_designations | Direct FK |
| SCE (EmployeeSetup) | Departments, designations, shifts, leave types, holidays | sch_departments, sch_designations, sch_employee_shifts, sch_staff_leave_types, sch_holidays | Direct FK |
| SmartTimetable | Academic sessions, academic terms | sch_org_academic_sessions_jnt, sch_academic_term | Direct FK |
| TimetableFoundation | Academic terms | sch_academic_term | Direct FK |
| StudentProfile | Academic sessions, student leave types | sch_org_academic_sessions_jnt | Direct FK |
| HrStaff | Leave types, leave entitlement, leave approval, shifts, holidays | Full leave policy tables | Service layer reads |
| Complaint | Departments, organization | sch_departments, sch_organizations | Direct FK |
| Notification | Organization, entity groups | sch_organizations, sch_entity_groups | Direct FK |
| Transport | Organization address | sch_organizations | Direct read |
| ALL modules | Dropdown lookup values | sys_dropdowns | Direct read (cached) |
| ALL modules | Module config parameters | sch_configs | Direct read (cached) |

### Outbound (SCO Reads From)

| Source Module | Entity | Table | Connection |
|--------------|--------|-------|-----------|
| GlobalMaster | Academic years | glb_academic_sessions | global_master_mysql |
| GlobalMaster | Education boards | glb_boards | global_master_mysql |
| GlobalMaster | Cities, districts, states, countries | glb_cities, glb_districts, glb_states, glb_countries | global_master_mysql |
| Prime | Tenant context | prm_tenant | central (via tenancy) |

---

# Section 6: NFR Catalog + Risk Register

## NFR Catalog

| NFR-ID | Category | Requirement | Threshold |
|--------|---------|-------------|---------|
| NFR-SCO-001 | Performance | School profile page load | < 2 seconds (standard broadband) |
| NFR-SCO-002 | Performance | Academic session AJAX calls | < 1 second response |
| NFR-SCO-003 | Performance | sys_dropdowns reads (used in all module forms) | Tenant-cached; max 15-minute TTL; no live query per form load |
| NFR-SCO-004 | Performance | Holiday calendar listing | Up to 400 holidays without pagination or UI degradation |
| NFR-SCO-005 | Security | is_super_admin field | Not writable via any school-facing form; removed from all three layers (FormRequest, controller, $fillable) |
| NFR-SCO-006 | Security | Gate authorization | Every controller method in SCO scope must call Gate::authorize() before data access |
| NFR-SCO-007 | Security | Permission sync route | Restricted to users with `school-setup.permission.sync` permission |
| NFR-SCO-008 | Security | Cross-DB reads | Only via named `global_master_mysql` connection; never use default connection for cross-DB queries |
| NFR-SCO-009 | Security | Activity logs | before/after attribute diff logged; no raw request payload in log JSON |
| NFR-SCO-010 | Usability | Session management UX | AJAX-driven; no full-page reloads for create/update/set-current |
| NFR-SCO-011 | Usability | Attendance/leave type reordering | Drag-and-drop ordinal reordering available |
| NFR-SCO-012 | Usability | City auto-fill | Selecting city auto-fills district, state, country without additional user interaction |
| NFR-SCO-013 | Scalability | sys_dropdowns size | Must handle > 500 dropdown keys with > 50 values each without query degradation |
| NFR-SCO-014 | Compliance | Indian regulatory | UDISE code, affiliation number, CBSE/ICSE/State Board fields present in school profile for government reporting |
| NFR-SCO-015 | Availability | School profile data | Must be readable even during maintenance windows (cached or read-replica) |

## Risk Register

| RISK-ID | Risk | Category | Likelihood | Impact | Mitigation | Owner |
|---------|------|---------|:---:|:---:|-----------|-------|
| RISK-SCO-001 | OrganizationController $request->all() allows mass assignment injection | Security | High | High | Replace with $request->validated() immediately | Dev |
| RISK-SCO-002 | is_super_admin writable via user edit form → any authorized user can escalate to super admin | Security | High | Critical | Remove from UserRequest, controller, $fillable, and view | Dev |
| RISK-SCO-003 | RolePermissionController::destroy() calls save() instead of delete() — roles never actually deleted | Functionality | Medium | High | Fix destroy() to call $role->delete() | Dev |
| RISK-SCO-004 | PermissionSyncController unprotected — any authenticated user can reseed permissions | Security | Medium | High | Add Gate::authorize('school-setup.permission.sync') | Dev |
| RISK-SCO-005 | sch_entity_group_members table migration not located — EntityGroupMember feature may break on fresh tenant | Functionality | Medium | High | Locate or create the missing migration | Dev |
| RISK-SCO-006 | sch_designations missing softDeletes — accidental permanent deletion on "trash" action | Data Loss | Low | High | Additive migration to add deleted_at column | Dev |
| RISK-SCO-007 | Academic year rollover creates orphaned session-context data if not done in correct sequence | Data Integrity | Medium | Medium | Build rollover wizard (ENH-SCO-007); document sequence | Admin |
| RISK-SCO-008 | sys_dropdowns cache staleness — new dropdown values not visible until cache expires | Usability | Low | Medium | Add cache invalidation on dropdown create/update/delete | Dev |
| RISK-SCO-009 | DepartmentController using wrong permission prefix — legitimate users may be denied access | Functionality | High | Medium | Correct permission prefix in controller and re-seed permissions | Dev |
| RISK-SCO-010 | Zero test coverage — regressions in core identity module undetected until production | Quality | High | High | Write Pest tests for all 21 controllers as next sprint priority | Dev/QA |

---

# Section 7: Prioritization + Effort Estimation

## MoSCoW Prioritization

### Must (P0 — Core — block go-live)
- REQ-SCO-001: School Profile (foundation for all documents and integration)
- REQ-SCO-003: Academic Sessions (required by every data-entry module)
- REQ-SCO-006: Holiday Calendar (required by HrStaff payroll)
- REQ-SCO-009: Department Management (required by SCE employee setup)
- REQ-SCO-010: Designation Management (required by SCE employee setup)
- REQ-SCO-011: Staff Attendance Types (required by SCE attendance module)
- REQ-SCO-012: Staff Leave Types (required by HrStaff)
- REQ-SCO-013: Leave Entitlement Policies (required by HrStaff balance calculation)
- REQ-SCO-018: System Dropdown Master (used by every module form)
- REQ-SCO-019: School Config (governs all module behavior)
- REQ-SCO-020: User Account Management (required before any module use)
- REQ-SCO-021: Role & Permissions (required for secure access)

### Should (P1 — Standard — needed in first release)
- REQ-SCO-002: Organization Group (multi-branch schools)
- REQ-SCO-004: Academic Terms (timetable, marksheets)
- REQ-SCO-005: Board Affiliations (document headers, marksheets)
- REQ-SCO-007: Leave Year (required by holiday calendar)
- REQ-SCO-008: Work Shifts (HrStaff attendance)
- REQ-SCO-014: Leave Approval Workflows (HrStaff leave applications)
- REQ-SCO-015: Student Leave Types (StudentProfile module)
- REQ-SCO-016: Entity Groups (Notification, EventEngine)
- REQ-SCO-017: Entity Group Members (same as above)

### Could (P2 — Enhanced — later iterations)
- ENH-SCO-001: Multiple logo variants
- ENH-SCO-002: Full org group hierarchy
- ENH-SCO-003: Department hierarchy
- ENH-SCO-004: Bulk holiday import
- ENH-SCO-005: Social media links
- ENH-SCO-006: Grading system config
- ENH-SCO-007: Year rollover wizard
- ENH-SCO-008: BoardAffiliationService

## Effort Estimation

| # | Task | Type | Est. Hours | Depends On | Sprint |
|---|------|------|-----------|-----------|--------|
| 1 | Fix $request->all() → $request->validated() in OrganizationController | Backend | 1h | — | 1 |
| 2 | Remove is_super_admin from UserRequest, controller, $fillable, and view | Backend/Frontend | 2h | — | 1 |
| 3 | Fix RolePermissionController::destroy() to call delete() | Backend | 0.5h | — | 1 |
| 4 | Add Gate::authorize() to PermissionSyncController::sync() | Backend | 0.5h | — | 1 |
| 5 | Create/verify sch_entity_group_members tenant migration | Schema | 2h | — | 1 |
| 6 | Additive migration: add deleted_at to sch_designations | Schema | 1h | — | 1 |
| 7 | Create DepartmentPolicy + DesignationPolicy; register in ServiceProvider | Backend | 2h | — | 1 |
| 8 | Fix DepartmentController permission prefix; re-seed permissions | Backend | 1h | 7 | 1 |
| 9 | Add FormRequests for DepartmentController and DesignationController | Backend | 2h | — | 1 |
| 10 | Add Gate::authorize() to all EntityGroupController / EntityGroupMemberController methods | Backend | 2h | — | 1 |
| 11 | Correct DepartmentController permission string (prime.department → school-setup.department) | Backend | 0.5h | 7 | 1 |
| 12 | Write Pest tests: Organization profile CRUD (happy path + validation) | Testing | 4h | 1 | 2 |
| 13 | Write Pest tests: Academic session create, set-current, board toggle | Testing | 3h | — | 2 |
| 14 | Write Pest tests: Holiday CRUD and leave year management | Testing | 3h | — | 2 |
| 15 | Write Pest tests: Department/Designation CRUD with policy enforcement | Testing | 3h | 7, 8 | 2 |
| 16 | Write Pest tests: Leave type and entitlement policy CRUD | Testing | 3h | — | 2 |
| 17 | Write Pest tests: Entity group + members | Testing | 3h | 5 | 2 |
| 18 | Write Pest tests: sys_dropdowns and sch_configs | Testing | 2h | — | 2 |
| 19 | Write Pest tests: User management and Role/Permission management | Testing | 4h | 2, 3, 4 | 2 |
| 20 | RPT-SCO-002: Holiday Calendar PDF report | Frontend/Backend | 4h | — | 3 |
| 21 | RPT-SCO-003: Department-Designation Directory report | Frontend/Backend | 3h | — | 3 |
| 22 | RPT-SCO-004: Leave Type Summary Sheet PDF | Frontend/Backend | 3h | — | 3 |
| 23 | RPT-SCO-005: School Config Audit Report (Excel export) | Frontend/Backend | 3h | — | 3 |
| 24 | ENH-SCO-004: Bulk holiday import via CSV | Backend/Frontend | 6h | — | 4 |
| 25 | ENH-SCO-007: Academic year rollover wizard | Frontend/Backend | 12h | — | 4 |
| **TOTALS** | | | **67.5h** | | |

> Assumes DDL is complete (it is); all migrations exist; no schema redesign needed. Sprint 1 = security/gap fixes (~12h); Sprint 2 = tests (~25h); Sprint 3 = reports (~13h); Sprint 4 = enhancements (~18h).

---

# Section 8: User Stories + Reporting & KPI Spec

## User Stories (P0 REQs — one story per requirement)

### US-SCO-001 — School Profile First-Time Setup
**Priority:** P0 | **REQ:** REQ-SCO-001
As a School Admin, I want to enter my school's official name, government codes, address, and logo so that all printed documents, reports, and integration points carry accurate school identity.

**Acceptance Criteria (Gherkin):**
```
Scenario: Successful school profile creation
  Given I am logged in as School Admin with school-setup.organization.store permission
  And no organization record exists yet
  When I fill in the school name, code, city, and submit the form
  Then a new organization record is created in sch_organizations
  And the city_id auto-resolved district, state, and country are stored
  And an activity log entry records the creation

Scenario: Logo upload replaces previous logo
  Given an organization record exists with an existing logo
  When I upload a new logo image
  Then the previous logo is cleared from the school_logo collection
  And the new logo is stored and accessible via the media library

Scenario: Duplicate organization creation blocked
  Given an organization record already exists (flg_single_record = 1)
  When I attempt to create a second organization record
  Then the system rejects the attempt with a unique constraint violation

Scenario: Permission denied
  Given I am logged in as a Teacher
  When I attempt to access the organization create form
  Then the system returns 403 Forbidden
```
**Definition of Done:** Profile saved; logo uploaded; audit log created; validation error shown for missing required fields; $request->validated() used (not $request->all())

---

### US-SCO-003 — Mark Academic Session as Current
**Priority:** P0 | **REQ:** REQ-SCO-003
As a School Admin, I want to designate the current academic year so that all fee invoices, attendance records, and timetable entries are correctly associated with the active year.

**Acceptance Criteria (Gherkin):**
```
Scenario: Setting a new session as current
  Given I am on the Academic Sessions panel
  And session "2026-27" is currently active
  When I click "Set as Current" for session "2027-28"
  Then session "2027-28" has is_current = true
  And session "2026-27" has is_current = false
  And both changes happen atomically (no window where two sessions are current)

Scenario: Only one current session at the DB level
  Given two concurrent admin requests attempt to set different sessions as current
  When both requests execute simultaneously
  Then MySQL UNIQUE constraint on current_flag allows only one to succeed
  And the second request receives a constraint violation error

Scenario: Empty state — no current session
  Given no academic session is set as current
  When a module attempts to resolve the current session
  Then it receives null and must display a "Please set a current academic year" prompt
```

---

### US-SCO-006 — Add Public Holiday
**Priority:** P0 | **REQ:** REQ-SCO-006
As an HR Officer, I want to record Independence Day as a paid public holiday in the 2026-27 Leave Year so that employee payroll and timetables correctly reflect it as a non-working day.

**Acceptance Criteria (Gherkin):**
```
Scenario: Create a public holiday
  Given a Leave Year "2026-27" exists and is active
  When I create a holiday with date=2026-08-15, name="Independence Day", type="Public", is_paid=true
  Then the holiday record is saved to sch_holidays linked to the Leave Year
  And it appears on the attendance-master holidays tab

Scenario: Scope holiday to a department
  Given I am creating a holiday
  When I select "Administration" as the applies_to_department
  Then only Administration staff see this holiday in their leave calendar

Scenario: Holiday requires a Leave Year
  Given no Leave Year exists for 2026-27
  When I attempt to create a holiday with annual_leave_sessions_id = null
  Then the system returns a validation error: "Leave Year is required"
```

---

### US-SCO-018 — Add System Dropdown Value
**Priority:** P0 | **REQ:** REQ-SCO-018
As an IT Admin, I want to add a new entity_purpose dropdown value ("sports_team") so that Entity Groups can use it as a group purpose without a code change.

**Acceptance Criteria (Gherkin):**
```
Scenario: Add new dropdown option
  Given I am logged in as IT Admin with appropriate permissions
  When I create a new dropdown entry with key="entity_purpose", value="sports_team", ordinal=10
  Then the value is available in all entity group purpose pickers across the platform

Scenario: Duplicate key+value blocked
  Given a dropdown entry key="entity_purpose", value="duty_roster" already exists
  When I attempt to create another with the same key and value
  Then the system returns a unique constraint violation

Scenario: Ordinal uniqueness within key group
  Given ordinal 5 is already used for key="entity_purpose"
  When I create a new entry with the same key and ordinal=5
  Then the system returns a unique constraint violation on (key, ordinal)
```

---

## Reporting & KPI Spec

| RPT-ID | Purpose | Audience | Frequency | Key Data | Filters | Export |
|--------|---------|---------|---------|---------|---------|--------|
| RPT-SCO-001 | Official school profile print | School Admin, Principal | On demand | Org name, codes, address, board, logo | None | PDF |
| RPT-SCO-002 | Annual holiday calendar | HR, All Staff | Per Leave Year | Date, name, type, paid, scope | Leave Year, Type, Department | PDF, Excel |
| RPT-SCO-003 | Department-Designation directory | HR, Principal | On demand | Dept name, code, count; designations with count | Active only | PDF, Excel |
| RPT-SCO-004 | Leave type summary sheet | HR, All Staff | Per year | Type code, name, entitlement days, key flags | Employment type, Active status | PDF |
| RPT-SCO-005 | Config audit report | IT Admin | On demand | Key, key_name, value, value_type, modified date | Module, value_type, tenant_can_modify | Excel |

### KPIs

| KPI | Definition | Source | Target |
|-----|-----------|--------|--------|
| Setup Completeness | % of mandatory SCO config fields populated (org name, session, at least one dept/desig) | Computed at runtime | 100% before any other module activation |
| Dropdown Coverage | % of sys_dropdown_needs records where dropdown_table_record_exist=true | sys_dropdown_needs | 100% |
| Holiday Calendar Coverage | Number of holidays entered for current Leave Year | sch_holidays | School-specific; typically 30–60 per year |
| Policy Coverage | Number of leave types with at least one entitlement policy | sch_staff_leave_types + sch_staff_leave_config | = Count of active leave types |

---

*Complete Analysis Pack ends.*
*Module Knowledge updated at: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/SCO_SchoolSetup_CoreSetup.md`*
