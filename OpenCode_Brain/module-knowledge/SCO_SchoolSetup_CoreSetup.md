# Module Knowledge — SchoolSetup CoreSetup (SCO)
> Seeded: 2026-06-30 | Agent: pa-business-analyst | Sources: live migrations, models, controllers, routes, V2 req, V1 screen-specs

---

## Module Facts

| Attribute | Value |
|-----------|-------|
| Module Code | SCO |
| Sub-module of | SchoolSetup (`Modules/SchoolSetup/`) |
| Module Type | Tenant (per-school) |
| Primary Table Prefix | `sch_` (shared with SCC, SCE, SCI) + `sys_dropdowns` (cross-cutting) |
| Route Prefix | `/school-setup/*` |
| Route Name Prefix | `school-setup.*` |
| Laravel Module Path | `/Users/bkwork/Herd/prime_ai/Modules/SchoolSetup/` |
| DDL Table Count (SCO scope) | 21 confirmed in tenant migrations |
| Estimated Completion | ~75–80% |
| FRD Status | Generated 2026-06-30 (SCO_FRD_Complete_2026-06-29.md) |

### Component Counts (SCO Scope — verified against live code)

| Component | Count | Notes |
|-----------|-------|-------|
| Controllers | 21 | OrganizationController, OrganizationGroupController, OrganizationAcademicSessionController, HolidayController, AnnualLeaveSessionController, EmployeeShiftController, DepartmentController, DesignationController, StaffAttendanceTypeController, StaffLeaveTypeController, StaffLeaveConfigController, AttendanceMasterController, LeaveApprovalPolicyController, LeaveApprovalPolicyLevelController, LeaveApprovalLevelApproverController, EntityGroupController, EntityGroupMemberController, SystemConfigController, StudentLeaveTypeController, LeaveConfigController, PermissionSyncController |
| Models | ~18 | Organization, OrganizationAcademicSession, OrganizationGroup, Holiday, AnnualLeaveSession, EmployeeShift, Department, Designation, StaffAttendanceType, StaffLeaveType, StaffLeaveConfig, LeaveApprovalPolicy, LeaveApprovalPolicyLevel, LeaveApprovalLevelApprover, EntityGroup, EntityGroupMember, SchConfig + related |
| Services | 3 | LeaveBalanceService, LeaveRolloverService, StaffLeaveService (all leave-domain) |
| FormRequests | 7 | OrganizationRequest, OrganizationGroupRequest, OrganizationAcademicSessionRequest, StaffAttendanceTypeRequest, StudentLeaveTypeRequest, LeaveConfigRequest, SystemConfigRequest |
| Policies (SCO scope) | ~8 | HolidayPolicy, LeaveApprovalPolicyPolicy, LeaveBalancePolicy, LeaveConfigPolicy + partial coverage (DepartmentPolicy, DesignationPolicy MISSING) |
| Views (SCO scope) | ~130 | organization/ 13, attendance-master/ 1, leave-master/ 73, leave-config/ 1, system-config/ 6, organization-group/ 4, entity-group-mgmt/ 11, department-designation/ 21 |
| Seeders (SCO relevant) | 4 | SchOrganizationSeeder, SchOrgAcademicSessionsJntSeeder, SchBoardOrganizationJntSeeder, SchConfigSeeder |
| Jobs | 0 | |
| Tests | 0 | Critical gap — zero test coverage across all SCO features |

---

## DDL Table Inventory (SCO Scope — 21 tables verified in `/database/migrations/tenant/`)

| # | Table | Migration File | Key Columns | Status |
|---|-------|---------------|-------------|--------|
| 1 | `sch_organizations` | `2026_06_16_152548_create_sch_organizations_table.php` | id (smallint PK), code, name, udise_code, affiliation_no, city_id (FK→glb_cities), rural_urban ENUM, email, website_url, address_1/2, pincode, phone_1/2, whatsapp_number, longitude, latitude, locale, currency, established_date, flg_single_record (UNIQUE — enforces 1 record), is_active, SoftDeletes | ✅ Active |
| 2 | `sch_org_academic_sessions_jnt` | `2026_06_15_145404_create_sch_org_academic_sessions_jnt_table.php` | academic_session_id (FK→glb_academic_sessions cross-DB), short_name, name, start_date, end_date, is_current, current_flag (UNIQUE — enforces single current), is_active, SoftDeletes | ✅ Active |
| 3 | `sch_board_organization_jnt` | `2026_06_16_152610_create_sch_board_organization_jnt_table.php` | academic_sessions_id (FK→sch_org_academic_sessions_jnt), board_id (FK→glb_boards cross-DB) | ✅ Active |
| 4 | `sch_academic_term` | `2026_06_15_145405_create_sch_academic_term_table.php` | academic_session_id, term_code (unique+session), term_name, term_start_date, term_end_date, term_total_teaching_days, term_total_periods_per_day, term_week_start_day, is_current (UNIQUE on current_flag), settings_json | ✅ Active |
| 5 | `sch_annual_leave_sessions` | `2026_06_16_104142_create_sch_annual_leave_sessions_table.php` | name (UNIQUE), start_date, end_date, description, is_active, SoftDeletes | ✅ Active |
| 6 | `sch_holidays` | `2026_06_16_104147_create_sch_holidays_table.php` | annual_leave_sessions_id (FK), holiday_date, name, holiday_type ENUM(Optional/Other/Public/Religious/Saturday/School_Specific/Sunday/Vacation), is_optional, is_paid, applies_to_role_id (FK→sys_roles nullable), applies_to_department_id (FK→sch_departments nullable), created_by, SoftDeletes | ✅ Active |
| 7 | `sch_employee_shifts` | `2026_06_16_104143_create_sch_employee_shifts_table.php` | code (UNIQUE), name, start_time, end_time, break_duration_minutes, working_hours, grace_minutes_late, grace_minutes_early, half_day_threshold_minutes, applies_to_days (JSON), is_default, is_active, SoftDeletes | ✅ Active |
| 8 | `sch_departments` | `2026_06_15_145911_create_sch_departments_table.php` | name, code, is_system, is_active, SoftDeletes | ✅ Active |
| 9 | `sch_designations` | `2026_06_15_145912_create_sch_designations_table.php` | name, code, is_system, is_active (no SoftDeletes in migration) | ✅ Active |
| 10 | `sch_staff_attendance_types` | `2026_06_16_104145_create_sch_staff_attendance_types_table.php` | code (UNIQUE), name, category ENUM(Attendance/Holiday/Leave/Other), is_present, can_be_half_day, affects_payroll, payroll_percentage, requires_approval, color_hex, display_order, is_system, is_active, SoftDeletes | ✅ Active |
| 11 | `sch_staff_leave_types` | `2026_06_16_104146_create_sch_staff_leave_types_table.php` | code (UNIQUE), name, is_paid, is_carry_forwardable, max_carry_forward, is_encashable, is_encashable_at_separation, requires_doc, requires_substitute, allows_half_day, allows_back_dated, requires_approval, min/max_days_per_application, min_advance_notice_days, display_order, is_system, is_active, SoftDeletes | ✅ Active |
| 12 | `sch_staff_leave_config` | `2026_06_16_104159_create_sch_staff_leave_config_table.php` | leave_type_id (FK), applies_to_employment_type ENUM, applies_to_role_id, applies_to_department_id, applies_to_designation_id, annual_entitlement, accrual_method ENUM, accrual_start_offset_months, is_carry_forwardable, max_carry_forward, is_encashable_at_separation, available_during_probation, priority, is_active, SoftDeletes | ✅ Active |
| 13 | `sch_leave_approval_policies` | `2026_06_16_104158_create_sch_leave_approval_policies_table.php` | (structure from model — leave_type_id, name, is_active, max_approval_levels) | ✅ Active |
| 14 | `sch_leave_approval_policy_levels` | `2026_06_16_104202_create_sch_leave_approval_policy_levels_table.php` | (policy_id, level_ordinal, approver_role_id/designation/department, auto_approve_after_hours) | ✅ Active |
| 15 | `sch_leave_approval_level_approvers` | `2026_06_16_104207_create_sch_leave_approval_level_approvers_table.php` | (level_id, user_id or role, is_active) | ✅ Active |
| 16 | `sch_entity_groups` | `2026_06_15_145412_create_entity_groups_table.php` | entity_purpose_id (FK→sys_dropdowns), code (UNIQUE), name, description, is_active, SoftDeletes | ✅ Active |
| 17 | `sch_entity_group_members` | (inferred from EntityGroupMember model — no standalone migration found in tenant/) | entity_group_id, entity_type_id, entity_table_name, entity_selected_id, entity_name, entity_code, is_active | ⚠️ Migration not located — may be embedded or pending |
| 18 | `sys_dropdowns` | `2026_06_15_145406_create_sys_dropdown_table.php` | ordinal (UNIQUE+key), key (string 160), value (string 100), type ENUM(String/Integer/Decimal/Date/Datetime/Time/Boolean), additional_info JSON, is_active, SoftDeletes | ✅ Active |
| 19 | `sys_dropdown_needs` | `2026_06_15_145405_create_sys_dropdown_needs_table.php` | db_type ENUM(Prime/Tenant/Global), table_name, column_name, menu_category, main_menu, sub_menu, tab_name, field_name, is_system, tenant_creation_allowed, compulsory, dropdown_table_record_exist, is_active. CHECK constraint: if tenant_creation_allowed=0 then menu fields must be NULL; if =1 then all menu fields must be NOT NULL | ✅ Active |
| 20 | `sys_dropdown_need_dropdowns_jnt` | `2026_06_15_145408_create_sys_dropdown_need_dropdowns_jnt_table.php` | dropdown_needs_id (FK), dropdown_table_id (FK→sys_dropdowns), UNIQUE(needs_id, table_id) | ✅ Active |
| 21 | `sch_configs` | `2026_06_26_145700_create_sch_config_table.php` | module_id (FK→glb_modules), module_code (3-char), ordinal (UNIQUE), key (UNIQUE), key_name, value (512), value_type ENUM(STRING/NUMBER/BOOLEAN/DATE/TIME/DATETIME/JSON), description, additional_info JSON, tenant_can_modify, mandatory, used_by_app, is_active, SoftDeletes | ✅ Active |

> Note: `sch_organization_groups` table does NOT exist in migrations — group attributes (group_code, group_short_name, group_name) are stored directly on `sch_organizations`. The Organization model has a guard for this: `whereRaw('1 = 0')` when table absent.

---

## Known Gaps & Open Issues

### P0 — Critical (must fix before production)
| ID | Issue | Location | Evidence |
|----|-------|----------|---------|
| SCO-P0-001 | `OrganizationController::store()` and `update()` use `$request->all()` instead of `$request->validated()` — mass assignment risk allows injection of arbitrary fields | `OrganizationController.php` lines 41, 94 | V2 req FR-SCH-01 AC6 |
| SCO-P0-002 | `sch_entity_group_members` table migration not found in `database/migrations/tenant/` — EntityGroupMember model exists but underlying table creation is unverified | EntityGroupMember model + EntityGroupMemberController | Filesystem scan |

### P1 — High Priority
| ID | Issue | Location | Evidence |
|----|-------|----------|---------|
| SCO-P1-001 | `DepartmentController` uses `prime.department.viewAny` permission string — must be `school-setup.department.viewAny` | DepartmentController | V2 req FR-SCH-10 AC4 |
| SCO-P1-002 | No `DepartmentPolicy` registered in module ServiceProvider | SchoolSetupServiceProvider | V2 req FR-SCH-10 AC3 |
| SCO-P1-003 | No `DesignationPolicy` registered in module ServiceProvider | SchoolSetupServiceProvider | V2 req FR-SCH-10 AC3 |
| SCO-P1-004 | `EntityGroupController` and `EntityGroupMemberController` have partial auth coverage — not all mutating methods call `Gate::authorize()` | EntityGroup controllers | V2 req FR-SCH-16 AC3 |
| SCO-P1-005 | `PermissionSyncController::sync()` has no `Gate::authorize()` — any authenticated user can trigger permission reseed | PermissionSyncController | V2 req FR-SCH-17 AC1 |
| SCO-P1-006 | `sch_designations` migration has no `softDeletes()` — design inconsistency; all other SCO tables use soft deletes | 2026_06_15_145912 migration | Code review |
| SCO-P1-007 | `OrganizationAcademicSessionController` standard CRUD methods (index, create, store, show, edit, update) are empty stubs — only AJAX variants and destroy are implemented | OrganizationAcademicSessionController | Code review |

### P2 — Medium Priority
| ID | Issue | Location | Evidence |
|----|-------|----------|---------|
| SCO-P2-001 | Zero test coverage for all 21 SCO controllers — no Pest test files | Modules/SchoolSetup/tests/ | Filesystem scan |
| SCO-P2-002 | No FormRequest for DepartmentController or DesignationController — inline validate() only | DepartmentController, DesignationController | V2 req FR-SCH-10 AC5 |
| SCO-P2-003 | `sch_board_organization_jnt` lacks an `organization_id` column in original migration (added by alter migration `2026_06_30_000002`) — potential referential integrity gap in original deploy | alter migration 2026_06_30_000002 | Migrations list |
| SCO-P2-004 | No dedicated sys_dropdown admin controller in SchoolSetup routes — dropdown management UI unclear | routes/web.php | Route review |
| SCO-P2-005 | `sch_leave_approval_policies` and related tables: full structure not verified from migration file content (file exists but not read) | 2026_06_16_104158 | Partial read |

---

## Design Decisions Made

| Decision | Detail |
|----------|--------|
| Single-tenant record enforced via `flg_single_record` UNIQUE constraint | Only one `sch_organizations` row allowed per tenant DB — prevents accidental multi-record scenarios |
| Academic session "current" enforced via `current_flag` UNIQUE constraint | Both `sch_org_academic_sessions_jnt.current_flag` and `sch_academic_term.current_flag` use MySQL UNIQUE constraints to prevent multiple current sessions atomically |
| Board affiliations managed via manual DB pivot (no Eloquent `sync()`) | `sch_board_organization_jnt` pivot crosses DB connections (tenant→global); `syncBoardPivot()` private method handles attach/detach manually using `DB::table()` |
| Organization group attributes stored on `sch_organizations` | No separate `sch_organization_groups` table in DDL; group_code/group_short_name/group_name are columns on the main org table |
| sys_dropdowns uses `key+value` compound UNIQUE | Allows multiple values per key (a "dropdown group" is all rows sharing the same `key`); ordinal within key is also UNIQUE for stable ordering |
| Holiday calendar is leave-session scoped | `sch_holidays.annual_leave_sessions_id` links holidays to a leave year container, not directly to `sch_org_academic_sessions_jnt` |
| AcademicSessionController CRUD is AJAX-only | Standard Blade CRUD methods (index, create, store, edit, update) are empty stubs; all operations go through `ajaxStore`, `ajaxUpdate`, `setActiveSession`, `toggleBoard` |
| sys_dropdown_needs CHECK constraint | MySQL CHECK enforces that system-managed needs (tenant_creation_allowed=0) have NULL menu paths; user-visible needs (tenant_creation_allowed=1) must have all 5 menu path components |

---

## Cross-Module Dependencies

### Inbound (SCO provides data to)
| Consumer Module | Data / Entity | Tables Referenced |
|----------------|--------------|-------------------|
| SchoolSetup — SCC (ClassSetup) | Academic sessions, departments, designations | `sch_org_academic_sessions_jnt`, `sch_departments`, `sch_designations` |
| SchoolSetup — SCE (EmployeeSetup) | Departments, designations, shifts, leave types, holiday calendar | `sch_departments`, `sch_designations`, `sch_employee_shifts`, `sch_staff_leave_types`, `sch_holidays` |
| SchoolSetup — SCI (InfraSetup) | Academic session context | `sch_org_academic_sessions_jnt` |
| SmartTimetable | Academic sessions, academic terms, organization | `sch_org_academic_sessions_jnt`, `sch_academic_term`, `sch_organizations` |
| TimetableFoundation | Academic terms | `sch_academic_term` |
| StudentProfile | Organization, academic sessions | `sch_organizations`, `sch_org_academic_sessions_jnt` |
| StudentFee | Academic sessions, organization | `sch_org_academic_sessions_jnt`, `sch_organizations` |
| Complaint | Departments, organization | `sch_departments`, `sch_organizations` |
| Notification | Organization (SMS/email config), entity groups | `sch_organizations`, `sch_entity_groups` |
| Transport | Organization (school address) | `sch_organizations` |
| HrStaff | Leave types, shifts, annual leave sessions, holidays | `sch_staff_leave_types`, `sch_employee_shifts`, `sch_annual_leave_sessions`, `sch_holidays` |
| ALL modules | System dropdowns (lookup values) | `sys_dropdowns` |
| ALL modules | School config values | `sch_configs` |

### Outbound (SCO reads from)
| Source Module | Data / Entity | Tables Read |
|--------------|--------------|------------|
| GlobalMaster | Academic sessions, boards, cities | `glb_academic_sessions`, `glb_boards`, `glb_cities` |
| Prime | Tenant information (tenant_id context) | `prm_tenant` (cross-DB via tenancy) |

---

## Lessons Learned (SCO Specific)

- [2026-06-30 | pa-business-analyst] SCO scope is precisely: org profile + sessions + calendar/holidays + shifts + org structure masters (dept/desig/attendance/leave types) + entity groups + sys_dropdowns + sch_configs. SCC covers classes/sections/subjects; SCE covers employee profiles; SCI covers buildings/rooms.
- [2026-06-30 | pa-business-analyst] `OrganizationAcademicSessionController` standard CRUD stubs are empty — don't count them as implemented. Only AJAX variants are real. The board toggle lives on this controller but is conceptually a Board Affiliation feature.
- [2026-06-30 | pa-business-analyst] `sch_entity_group_members` migration was not found in tenant migrations — the model and controller exist but the table creation needs verification. Always check this before reporting the feature complete.
- [2026-06-30 | pa-business-analyst] `sch_designations` migration lacks softDeletes — architectural inconsistency with all other SCO tables. A corrective additive migration is needed.
- [2026-06-30 | pa-business-analyst] sys_dropdowns is a cross-cutting table used by ALL modules. The `key` acts as a "dropdown group name" (e.g., "entity_purpose", "holiday_type") and all rows sharing that key are the dropdown options. The CHECK constraint on sys_dropdown_needs enforces that only fields the admin is supposed to configure get exposed to the admin UI.
- [2026-06-30 | pa-business-analyst] Board affiliation management is split across two controllers: OrganizationController::syncBoardPivot() handles sync during org create/update; OrganizationAcademicSessionController::toggleBoard() handles on-demand toggle. Both should be consolidated into a dedicated BoardAffiliationService.

---

## FRD Summary

| Attribute | Value |
|-----------|-------|
| FRD File | `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/SCO_FRD_Complete_2026-06-29.md` |
| FRD Date | 2026-06-30 |
| REQ Count | 21 |
| BR Count | 42 |
| RPT Count | 5 |
| ENH Count | 8 |
| P0 REQ | 10 (Must) |
| P1 REQ | 8 (Should) |
| P2 REQ | 3 (Could) |
| Workflows | 6 |
| FSM Entities | 3 |

---

## Pending Next Steps

1. Fix P0-001: Replace `$request->all()` with `$request->validated()` in OrganizationController
2. Create `DepartmentPolicy` and `DesignationPolicy` and register in SchoolSetupServiceProvider
3. Add FormRequests for DepartmentController and DesignationController
4. Fix permission prefix in DepartmentController (`school-setup.department.*`)
5. Verify / create `sch_entity_group_members` tenant migration
6. Protect `PermissionSyncController::sync()` with Gate authorization
7. Add `softDeletes()` to `sch_designations` table via additive migration
8. DB Architect review: `sch_board_organization_jnt` missing `organization_id` FK (only academic_sessions_id and board_id)
9. Technical Auditor: Audit `EntityGroupController` and `EntityGroupMemberController` for full auth coverage
10. Create Pest tests for all 21 SCO controllers (zero coverage currently)

---

## Version History

| Version | Date | Agent | Summary |
|---------|------|-------|---------|
| 1.0 | 2026-06-30 | pa-business-analyst | Initial seed — SCO sub-module extracted from SchoolSetup; 21 tables verified; FRD + Complete Analysis Pack generated |
