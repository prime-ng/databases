# Configuration Templates — Business Conditions & Test Case List

**Module:** MarksheetGeneration (MSH) · **Feature/Screen:** Configuration Templates (`02-Configuration-Templates.md`)
**Primary table:** `msh_config_templates` (tenant_db, prefix `msh_`) · **Prefix verified against DDL** `CREATE TABLE ... msh_config_templates`.
**Screen:** Configuration composite tab — `route('marksheet-generation.configuration.combined', ['tab' => 'config-templates'])` → `/marksheet-generation/configuration`
**Create page:** `/marksheet-generation/config-template/create` (full page — NOT a modal) · **Store:** `POST /marksheet-generation/config-template` (redirects; no JSON branch)
**Controllers:** `ConfigTemplateController` (primary), `MarksheetTypeController`, `ClassGroupController`, `ExamGroupController`, `IaComponentTypeController`, `MarksheetGenerationController::configuration()`
**Service:** `ConfigTemplateService` (create/update/delete + `syncClassAssignments` on `msh_class_config_jnt`)
**Activity events (literal):** `Stored`, `Updated`, `Toggled`, `Deleted`, `Restored` → table `sys_activity_logs` (`Modules\GlobalMaster\Models\ActivityLog`, issuer = `user_id`)
**Permissions:** `tenant.msh-config-template.{viewAny|view|create|update|delete|restore|forceDelete}`; combined page gate `tenant.msh-configuration.view`
**Test style:** browser Dusk (`extends DuskTestCase`) — no committed MSH sibling; tenant-side scaffolding.

> Scope note: `config_templates` is the primary table for schema truth (`test_01`). The master entities (marksheet-type, class-group, exam-group, ia-component-type) are covered as secondary create/validation/dependency flows and cross-referenced by DDL. The full component-weightage matrix (tables 9–12) belongs to the **Components** screen and is out of scope here.

---

## 1. Business Conditions

### BC-DB — Schema (DDL: `msh_config_templates`, table 8)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `id` INT UNSIGNED PK auto-increment | DDL-msh_config_templates |
| BC-DB-02 | `academic_session_id` SMALLINT UNSIGNED **NOT NULL**, FK → `sch_org_academic_sessions_jnt` | DDL-msh_config_templates |
| BC-DB-03 | `marksheet_type_id` INT UNSIGNED **NOT NULL**, FK → `msh_marksheet_types` | DDL-msh_config_templates |
| BC-DB-04 | `exam_group_id` INT UNSIGNED **NOT NULL**, FK → `msh_exam_groups` | DDL-msh_config_templates |
| BC-DB-05 | `grading_schema_id` INT UNSIGNED **NULL**, FK → `slb_grade_division_master` | DDL-msh_config_templates |
| BC-DB-06 | `code` VARCHAR(50) NOT NULL | DDL-msh_config_templates |
| BC-DB-07 | `name` VARCHAR(150) NOT NULL | DDL-msh_config_templates |
| BC-DB-08 | `description` VARCHAR(500) NULL | DDL-msh_config_templates |
| BC-DB-09 | `board_code` VARCHAR(50) NULL (informational) | DDL-msh_config_templates |
| BC-DB-10 | `passing_percentage` DECIMAL(5,2) NOT NULL **DEFAULT 33.00** | DDL-msh_config_templates |
| BC-DB-11 | `compartment_max_failures` TINYINT UNSIGNED NOT NULL DEFAULT 2 | DDL-msh_config_templates |
| BC-DB-12 | `is_best_of_n_enabled` TINYINT(1) DEFAULT 0; `best_of_n_count` TINYINT UNSIGNED NULL | DDL-msh_config_templates |
| BC-DB-13 | `is_locked` TINYINT(1) DEFAULT 0 (BR-MSG-027 immutability marker) | DDL-msh_config_templates |
| BC-DB-14 | `is_active` TINYINT(1) DEFAULT 1; `created_by` NOT NULL, `updated_by` NULL | DDL-msh_config_templates |
| BC-DB-15 | `created_at/updated_at/deleted_at` — SoftDeletes | DDL-msh_config_templates |
| BC-DB-16 | **UNIQUE** (`academic_session_id`, `code`) — `uq_msh_ct_session_code` | DDL-msh_config_templates |
| BC-DB-17 | Indexes on session/type/exam_group/grading | DDL-msh_config_templates |

### BC-VAL — Validation (`ConfigTemplateRequest`; default Laravel messages — no custom `messages()`)

| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | `academic_session_id` required·integer·exists:sch_org_academic_sessions_jnt,id | ConfigTemplateRequest |
| BC-VAL-02 | `marksheet_type_id` required·integer·exists:msh_marksheet_types,id | ConfigTemplateRequest |
| BC-VAL-03 | `exam_group_id` required·integer·exists:msh_exam_groups,id | ConfigTemplateRequest |
| BC-VAL-04 | `grading_schema_id` nullable·integer·exists:slb_grade_division_master,id | ConfigTemplateRequest |
| BC-VAL-05 | `code` required·string·max:50·unique(msh_config_templates,code) scoped to session·ignore(id) | ConfigTemplateRequest |
| BC-VAL-06 | `name` required·string·max:150 | ConfigTemplateRequest |
| BC-VAL-07 | `description` nullable·string·max:500 | ConfigTemplateRequest |
| BC-VAL-08 | `board_code` nullable·string·max:50 | ConfigTemplateRequest |
| BC-VAL-09 | `passing_percentage` required·numeric·min:0·max:100 | ConfigTemplateRequest |
| BC-VAL-10 | `compartment_max_failures` required·integer·min:0·max:255 | ConfigTemplateRequest |
| BC-VAL-11 | `best_of_n_count` nullable·integer·min:1·max:255 | ConfigTemplateRequest |
| BC-VAL-12 | `is_best_of_n_enabled` / `is_locked` / `is_active` sometimes·boolean | ConfigTemplateRequest |
| BC-VAL-13 | `class_assignments` array; `.*.type` in:class,group; `.*.target_id` required_with·integer·min:1 | ConfigTemplateRequest |
| BC-VAL-14 | `prepareForValidation` coerces id/boolean fields to int/bool | ConfigTemplateRequest |

### BC-AUTH — Authorization

| ID | Gate ↔ method | Source |
|----|---------------|--------|
| BC-AUTH-01 | `tenant.msh-config-template.viewAny` → index/trashed | ConfigTemplateController + Policy |
| BC-AUTH-02 | `tenant.msh-config-template.view` → show | ConfigTemplateController + Policy |
| BC-AUTH-03 | `tenant.msh-config-template.create` → create/store | ConfigTemplateController + Policy |
| BC-AUTH-04 | `tenant.msh-config-template.update` → edit/update/toggleStatus/restore | ConfigTemplateController + Policy |
| BC-AUTH-05 | `tenant.msh-config-template.delete` → destroy/forceDelete | ConfigTemplateController + Policy |
| BC-AUTH-06 | combined page gate `tenant.msh-configuration.view` | MarksheetGenerationController::configuration |
| BC-AUTH-07 | **SEC-MSH-003** — `ConfigTemplateRequest::authorize()` returns `true`; gate enforced only in controller | ConfigTemplateRequest / Audit-SEC-MSH-003 |
| BC-AUTH-08 | **D39-MSH** — MSH permissions unseeded (env prereq; grant explicitly) | Audit-D39-MSH |

### BC-BIZ — Business logic / activity

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `store` → `ConfigTemplateService::create` (DB transaction) + `activityLog(..., 'Stored')` + redirect to combined `?tab=config-templates` | ConfigTemplateController::store |
| BC-BIZ-02 | `update` → `ConfigTemplateService::update` + `activityLog(..., 'Updated')` + redirect | ConfigTemplateController::update |
| BC-BIZ-03 | `destroy` → soft delete + `activityLog(..., 'Deleted')` | ConfigTemplateController::destroy |
| BC-BIZ-04 | `toggleStatus` → JSON `{success,is_active,message}` + `activityLog(..., 'Toggled')` | ConfigTemplateController::toggleStatus |
| BC-BIZ-05 | `restore` → restore + `is_active=true` + `activityLog(..., 'Restored')` | ConfigTemplateController::restore |
| BC-BIZ-06 | `create`/`update` sync `class_assignments` into `msh_class_config_jnt` (soft-delete old, restore/insert new) | ConfigTemplateService::syncClassAssignments |
| BC-BIZ-07 | `created_by` forced to `auth()->id()` in service (spoofed value ignored — not a rule key) | ConfigTemplateService::create |
| BC-BIZ-08 | `forceDelete` catches SQL `23000` → friendly "Cannot delete this record because it is referenced by other records." | ConfigTemplateController::forceDelete |
| BC-BIZ-09 | `passing_percentage` DB default is `33.00` when omitted | DDL / Screen-FR-02 |

### BC-SM — State machine (`is_locked` lifecycle)

| ID | State → Trigger → Next | Source |
|----|-----------------------|--------|
| BC-SM-01 | Unlocked → publish schedule → Locked (`is_locked=1`, BR-MSG-027) | Screen-FR / DDL comment |
| BC-SM-02 | Locked → update attempt → **should be rejected** (immutable). **Current code has NO guard** → update succeeds (candidate DEV, verify in source). | Audit-candidate / ConfigTemplateController::update |

### BC-INT / BC-REF — Integration & FK

| ID | FK → referenced table → onDelete | Source |
|----|----------------------------------|--------|
| BC-REF-01 | `academic_session_id` → `sch_org_academic_sessions_jnt` — **RESTRICT** | DDL fk_msh_ct_session |
| BC-REF-02 | `marksheet_type_id` → `msh_marksheet_types` — **RESTRICT** | DDL fk_msh_ct_type |
| BC-REF-03 | `exam_group_id` → `msh_exam_groups` — **RESTRICT** | DDL fk_msh_ct_exam_group |
| BC-REF-04 | `grading_schema_id` → `slb_grade_division_master` — **SET NULL** | DDL fk_msh_ct_grading |
| BC-INT-01 | Children `msh_class_config_jnt`, `msh_template_*` — config_template FK **CASCADE** | DDL tables 9–13 |
| BC-INT-02 | `msh_marksheet_schedules.config_template_id` — **RESTRICT** (template with schedule cannot be force-deleted → 23000) | DDL fk_msh_ms_template |
| BC-INT-03 | `msh_class_group_items_jnt.class_id` → `sch_classes` RESTRICT; `msh_exam_group_items_jnt.exam_type_id` → `lms_exam_types` RESTRICT | DDL tables 5,7 |

### BC-EDG / BC-CFG — Edge & config

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Same `code` allowed across **different** academic sessions (unique is per-session) | DDL uq_msh_ct_session_code |
| BC-EDG-02 | Max lengths: code 50, name 150, description 500, board_code 50 | DDL / ConfigTemplateRequest |
| BC-EDG-03 | Stored XSS in `name`/`description` escaped on render (Blade `{{ }}`) | Screen-security |
| BC-CFG-01 | `board_code` informational only (guides UI defaults); best-of-N optional config | DDL comments |

### Known Source Defects (audit-equivalent)

| ID | Severity | Description | Proving test |
|----|----------|-------------|--------------|
| BUG-MSH-003 | P2 | `ExamGroupController::edit()` has no `ExamGroup` model-binding param → redirects to combined page instead of an edit form, and does **not** 404 on a bogus id. | V1 `_16`, V2 `_56` |
| SEC-MSH-003 | P1 | Every FormRequest here returns `authorize()=true` (no gate) — authorization lives only in the controller `Gate::authorize()`. | V2 `_53`; asserted in V1 `_01` |
| D39-MSH | P1 | MSH permissions unseeded → routes 403/blank until seeded. Env prerequisite; permission-gate tests grant permissions explicitly. | Validation Report §5 |
| DEV-MSH-CT-01 (candidate — verify in source) | P2 | BR-MSG-027 `is_locked` immutability guard is **not implemented**: `ConfigTemplateController::update` / `ConfigTemplateService::update` update a locked template with no guard. | V2 `_21` |
| DEV-MSH-CT-02 (candidate — verify in source) | P3 | `ConfigTemplateController::store/update` have **no** `expectsJson()` JSON branch (unlike sibling master controllers) — AJAX callers always get a 302 redirect, not `{status,message,redirect}`. | Gap §Cross-Reference #6 |

---

## 2. Test Case List

**Legend — V1 col:** method # in V1 suite · **V2 col:** method # in V2 suite · Status: A=Automated.

### Positive (TC-P)

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-P01 | Schema | BC-DB-* | DDL | Table/columns/indexes/model/request config correct | All asserts pass | 01,02 | 01,02,03 | A |
| TC-P02 | Create | BC-BIZ-01 | Screen-FR-02 | Create template persists + `Stored` activity | Row + log by admin | 04 | 10 | A |
| TC-P03 | Create | BC-DB-05 | DDL | Create with NULL grading schema allowed | Row, grading_schema_id NULL | – | 11 | A |
| TC-P04 | Create | BC-BIZ-06 | Service | Create with class assignment syncs junction | `msh_class_config_jnt` row | – | 12 | A |
| TC-P05 | Update | BC-BIZ-02 | Screen-FR-02 | Update persists + `Updated` activity | Fields changed, log | 05 | 13 | A |
| TC-P06 | Default | BC-BIZ-09 | DDL | `passing_percentage` DB default 33.00 | `33.00` | – | 14 | A |
| TC-P07 | Config | BC-DB-12 | DDL | best-of-N fields persist | Values stored | – | 15 | A |
| TC-P08 | Config | BC-DB-09 | DDL | board_code optional | With/without accepted | – | 16 | A |
| TC-P09 | Toggle | BC-BIZ-04 | Controller | toggleStatus JSON + `Toggled` activity | `is_active` flips, log | 06 | (state via V1) | A |
| TC-P10 | Delete | BC-BIZ-03 | Controller | Soft delete + `Deleted` activity | deleted_at set, log | 07 | 17 | A |
| TC-P11 | Restore | BC-BIZ-05 | Controller | Restore + reactivate + `Restored` activity | deleted_at null, log | 08 | 18 | A |
| TC-P12 | ForceDelete | BC-DB-15 | Controller | Force delete removes row | Row gone | – | 19 | A |
| TC-P13 | Render | BC-AUTH-06 | Screen | Combined page renders config-templates tab | `#config-templates-pane` | 03 | 60 | A |
| TC-P14 | Search | BC-BIZ | Controller | Search filters templates | Match shown | – | 61 | A |
| TC-P15 | Filter | BC-BIZ | Controller | Status filter loads | 200 | – | 62 | A |
| TC-P16 | Breadcrumb | Screen | Blade | Create page breadcrumb present | Sees crumbs | 03 | 63 | A |

### Negative (TC-N)

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-N01 | Required | BC-VAL-01/02/03/05/06 | Screen-VR | Empty store rejected | 422 with keys | 09 | 30 | A |
| TC-N02 | Length | BC-EDG-02 | Screen-VR | code>50 rejected | 422 code | – | 31 | A |
| TC-N03 | Length | BC-EDG-02 | Screen-VR | name>150 rejected | 422 name | – | 32 | A |
| TC-N04 | Length | BC-EDG-02 | Screen-VR | description>500 rejected | 422 description | – | 33 | A |
| TC-N05 | Length | BC-EDG-02 | Screen-VR | board_code>50 rejected | 422 board_code | – | 34 | A |
| TC-N06 | Range | BC-VAL-09 | Screen-VR | passing_percentage >100 / <0 rejected | 422 | 12 | 35 | A |
| TC-N07 | Range | BC-VAL-10 | Screen-VR | compartment_max_failures >255 rejected | 422 | – | 36 | A |
| TC-N08 | Range | BC-VAL-11 | Screen-VR | best_of_n_count <1 rejected | 422 | – | 37 | A |
| TC-N09 | Duplicate | BC-VAL-05 | DDL | Duplicate code same session rejected | 422, no insert | 10 | 38 | A |
| TC-N10 | Uniqueness | BC-EDG-01 | DDL | Same code, different session allowed | Row created | – | 39 | A |
| TC-N11 | Exists | BC-VAL-02 | ConfigTemplateRequest | invalid marksheet_type_id | 422 | 11 | 40 | A |
| TC-N12 | Exists | BC-VAL-03 | ConfigTemplateRequest | invalid exam_group_id | 422 | 11 | 41 | A |
| TC-N13 | Exists | BC-VAL-01 | ConfigTemplateRequest | invalid academic_session_id | 422 | – | 42 | A |
| TC-N14 | Exists | BC-VAL-04 | ConfigTemplateRequest | invalid grading_schema_id | 422 | – | 43 | A |
| TC-N15 | Auth | BC-AUTH-* | Screen-PM | Guest redirected to /login | /login | 14 | 50 | A |
| TC-N16 | Auth | BC-AUTH-03 | Screen-PM | No-create user → 403 | 403 | – | 51 | A |
| TC-N17 | Auth | BC-AUTH-05 | Screen-PM | No-delete user → 403 | 403 | – | 52 | A |
| TC-N18 | Security | BC-AUTH-07 | Audit-SEC-MSH-003 | FormRequest self-authorizes true | authorize()=true | 01 | 53 | A |
| TC-N19 | Security | BC-EDG-03 | Screen | XSS name escaped on render | No raw `<script>` | – | 70 | A |
| TC-N20 | IDOR | BC-INT | Screen | Non-existent id 404 | 404 | – | 91 | A |

### Dependency (TC-D)

| TC ID | Sub | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 | C | BC-REF-02 | DDL | Delete referenced marksheet type blocked (RESTRICT) | Blocked, row kept | 13 | 44 | A |
| TC-D02 | C | BC-REF-03 | DDL | Delete referenced exam group blocked (RESTRICT) | Blocked | – | 45 | A |
| TC-D03 | B | BC-INT-01 | DDL | Force-delete template cascades `msh_class_config_jnt` | Junction rows gone | – | 46 | A |
| TC-D04 | C | BC-INT-02 | DDL | Force-delete template referenced by schedule blocked (23000) | Blocked, friendly error path | – | 47 | A |
| TC-D05 | F | BC-BIZ-01..05 | Controller | Full lifecycle create→toggle→delete→restore→forceDelete | Each step + activity | 04-08 | 10,17,18,19 | A |
| TC-D06 | E | BC-INT | Audit-BUG-MSH-003 | ExamGroup edit redirects w/o binding (no 404) | 302→200 combined | 16 | 56 | A |
| TC-D07 | G | BC-BIZ-07 | Service | Spoofed created_by ignored, forced to auth id | created_by=admin | – | 71 | A |
| TC-D08 | G | BC-SM-02 | Audit-candidate | Locked template still mutable (no guard) — documents current behaviour | Update succeeds | – | 21 | A |

### Tenancy (TC-T)

| TC ID | BC | Source | Description | Expected | V2 |
|-------|----|--------|-------------|----------|----|
| TC-T01 | BC-DB | 05_A4 | `msh_config_templates` tenant-scoped (no tenant_id column) | Table present, no tenant_id | 90 |
| TC-T02 | BC-INT | 05_A4 | Cross-tenant / bogus direct id does not leak | 404 | 91 |

---

## 3. V2 Test Method Index

| # | Method | TC Map | Cat | Band |
|---|--------|--------|-----|------|
| 1 | test_config_template_01_schema_and_model_configuration_are_correct | TC-P01 | Schema | 01-09 |
| 2 | test_config_template_02_column_types_and_indexes_match_ddl | TC-P01 | Schema | 01-09 |
| 3 | test_config_template_03_request_rules_and_controller_events_are_correct | TC-P01/TC-N18 | Schema | 01-09 |
| 4 | test_config_template_10_create_persists_with_activity_stored | TC-P02 | Business | 10-19 |
| 5 | test_config_template_11_create_with_null_grading_schema_is_allowed | TC-P03 | Business | 10-19 |
| 6 | test_config_template_12_create_with_class_assignments_syncs_junction | TC-P04 | Business | 10-19 |
| 7 | test_config_template_13_update_persists_with_activity_updated | TC-P05 | Business | 10-19 |
| 8 | test_config_template_14_default_passing_percentage_is_33_at_db_level | TC-P06 | Business | 10-19 |
| 9 | test_config_template_15_best_of_n_fields_persist | TC-P07 | Business | 10-19 |
| 10 | test_config_template_16_board_code_is_optional | TC-P08 | Business | 10-19 |
| 11 | test_config_template_17_soft_delete_records_activity_deleted | TC-P10 | Business | 10-19 |
| 12 | test_config_template_18_restore_records_activity_restored | TC-P11 | Business | 10-19 |
| 13 | test_config_template_19_force_delete_removes_row_permanently | TC-P12 | Business | 10-19 |
| 14 | test_config_template_20_is_locked_flag_persists_on_create | BC-SM-01 | State | 20-29 |
| 15 | test_config_template_21_br_msg_027_update_not_blocked_when_locked_verify_in_source | TC-D08/BC-SM-02 | State | 20-29 |
| 16 | test_config_template_30_required_fields_rejected_422 | TC-N01 | Validation | 30-39 |
| 17 | test_config_template_31_code_max_50_enforced | TC-N02 | Validation | 30-39 |
| 18 | test_config_template_32_name_max_150_enforced | TC-N03 | Validation | 30-39 |
| 19 | test_config_template_33_description_max_500_enforced | TC-N04 | Validation | 30-39 |
| 20 | test_config_template_34_board_code_max_50_enforced | TC-N05 | Validation | 30-39 |
| 21 | test_config_template_35_passing_percentage_out_of_range_rejected | TC-N06 | Validation | 30-39 |
| 22 | test_config_template_36_compartment_max_failures_out_of_range_rejected | TC-N07 | Validation | 30-39 |
| 23 | test_config_template_37_best_of_n_count_min_1_enforced | TC-N08 | Validation | 30-39 |
| 24 | test_config_template_38_duplicate_code_same_session_rejected | TC-N09 | Validation | 30-39 |
| 25 | test_config_template_39_same_code_in_different_session_allowed | TC-N10 | Validation | 30-39 |
| 26 | test_config_template_40_invalid_marksheet_type_id_rejected | TC-N11 | Integration | 40-49 |
| 27 | test_config_template_41_invalid_exam_group_id_rejected | TC-N12 | Integration | 40-49 |
| 28 | test_config_template_42_invalid_academic_session_id_rejected | TC-N13 | Integration | 40-49 |
| 29 | test_config_template_43_invalid_grading_schema_id_rejected | TC-N14 | Integration | 40-49 |
| 30 | test_config_template_44_marksheet_type_delete_restricted_while_referenced | TC-D01 | Integration | 40-49 |
| 31 | test_config_template_45_exam_group_delete_restricted_while_referenced | TC-D02 | Integration | 40-49 |
| 32 | test_config_template_46_force_delete_cascades_class_config_junction | TC-D03 | Integration | 40-49 |
| 33 | test_config_template_47_force_delete_blocked_when_referenced_by_schedule | TC-D04 | Integration | 40-49 |
| 34 | test_config_template_50_guest_redirected_to_login | TC-N15 | Permissions | 50-59 |
| 35 | test_config_template_51_user_without_create_permission_gets_403 | TC-N16 | Permissions | 50-59 |
| 36 | test_config_template_52_user_without_delete_permission_gets_403 | TC-N17 | Permissions | 50-59 |
| 37 | test_config_template_53_sec_msh_003_form_request_self_authorizes_true | TC-N18 | Permissions | 50-59 |
| 38 | test_config_template_54_combined_page_requires_configuration_gate | TC-P13/BC-AUTH-06 | Permissions | 50-59 |
| 39 | test_config_template_56_bug_msh_003_exam_group_edit_redirects_without_binding | TC-D06 | Permissions | 50-59 |
| 40 | test_config_template_60_combined_page_renders_config_templates_tab | TC-P13 | UI/UX | 60-69 |
| 41 | test_config_template_61_search_filters_config_templates | TC-P14 | UI/UX | 60-69 |
| 42 | test_config_template_62_status_filter_narrows_list | TC-P15 | UI/UX | 60-69 |
| 43 | test_config_template_63_create_page_shows_breadcrumb | TC-P16 | UI/UX | 60-69 |
| 44 | test_config_template_70_xss_in_name_is_stored_and_escaped_on_render | TC-N19 | Edge/Security | 70-79 |
| 45 | test_config_template_71_created_by_is_forced_to_authenticated_user | TC-D07 | Edge/Security | 70-79 |
| 46 | test_config_template_90_config_templates_table_is_tenant_scoped | TC-T01 | Tenancy | 90-99 |
| 47 | test_config_template_91_cross_tenant_direct_id_is_not_leaked | TC-T02 | Tenancy | 90-99 |

**Counts:** V1 = 16 methods · V2 = 47 methods · Ratio = **2.94×** (gate: ≥ 2× ✔).
