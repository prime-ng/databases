# Board (PRM / GlobalMaster) — Test Case List & Requirements

- **Module:** Prime (PRM) — screen surfaced under the central `prime` route group.
- **Feature / Screen:** Board (Academic Board master).
- **Primary table:** `glb_boards` — **DDL prefix `glb_`** (verified in `_global_db_v4.sql`), database **global_master** (model connection `global_master_mysql`).
- **PREFIX FLAG (registry mismatch):** the module registry maps `Prime -> prm_`, but this screen's primary table is `glb_boards` (prefix `glb_`) living in **global_master**, not `prm_`/`prime_db`. Artifacts therefore use the **`glb_`** prefix. This is a documented registry-vs-DDL flag, not a code defect.
- **DB scope:** CENTRAL. No tenant init. Host `http://127.0.0.1:8000`.
- **Effective classes (verified from `BoardController` imports):**
  - Model `Modules\GlobalMaster\Models\Board`
  - Request `Modules\GlobalMaster\Http\Requests\BoardRequest`
  - Controller `Modules\Prime\Http\Controllers\BoardController`
  - Policy `Modules\GlobalMaster\Policies\BoardPolicy`
  - Activity sink `Modules\Prime\Models\ActivityLog` → `sys_central_activity_logs` (central `mysql`).
- **Routes (verified — `central.` domain → `prime.` prefix):** `central.prime.board.{index,create,store,show,edit,update,destroy}`, `.trashed`, `.restore`, `.forceDelete`, `.toggleStatus`. URLs under `/prime/board`.

---

## 1. Business Conditions

### BC-DB — Schema (Source: `DDL-glb_boards` in `_global_db_v4.sql`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `glb_boards` exists in global_master | DDL-glb_boards |
| BC-DB-02 | Columns: id, name, short_name, is_active, created_at, updated_at, deleted_at | DDL-glb_boards |
| BC-DB-03 | `name` varchar(255) NOT NULL | DDL-glb_boards |
| BC-DB-04 | `short_name` varchar(20) NOT NULL | DDL-glb_boards |
| BC-DB-05 | `is_active` tinyint(1) NOT NULL DEFAULT 1 | DDL-glb_boards |
| BC-DB-06 | UNIQUE(`name`) — `uq_glb_academicBoard_name` | DDL-glb_boards |
| BC-DB-07 | UNIQUE(`short_name`) — `uq_glb_academicBoard_shortName` | DDL-glb_boards |
| BC-DB-08 | Soft delete via `deleted_at` | DDL-glb_boards + Model |

### BC-VAL — Validation (Source: `GlobalMaster\BoardRequest`)

| ID | Rule + message | Source |
|----|----------------|--------|
| BC-VAL-01 | `name` required | Req-rules |
| BC-VAL-02 | `name` string, max:50 | Req-rules |
| BC-VAL-03 | `name` unique(`glb_boards`)->ignore(id) | Req-rules |
| BC-VAL-04 | `short_name` required | Req-rules |
| BC-VAL-05 | `short_name` string, max:10 | Req-rules |
| BC-VAL-06 | `short_name` unique(`glb_boards`)->ignore(id) | Req-rules |
| BC-VAL-07 | `is_active` required|boolean | Req-rules |
| BC-VAL-08 | `prepareForValidation` coerces checkbox `'on'`→bool | Req-prepare |

### BC-AUTH — Authorization (Source: Controller `Gate::authorize` + `BoardPolicy`)

| ID | Ability ↔ method | Source |
|----|-------------------|--------|
| BC-AUTH-01 | `prime.board.viewAny` → index | Ctrl-index |
| BC-AUTH-02 | `prime.board.create` → create/store | Ctrl-create/store |
| BC-AUTH-03 | `prime.board.view` → show | Ctrl-show |
| BC-AUTH-04 | `prime.board.update` → edit/update | Ctrl-edit/update |
| BC-AUTH-05 | `prime.board.delete` → destroy | Ctrl-destroy |
| BC-AUTH-06 | `prime.board.restore` → trashedBoard/restore | Ctrl-restore |
| BC-AUTH-07 | `prime.board.forceDelete` → forceDelete | Ctrl-forceDelete |
| BC-AUTH-08 | `prime.board.update` → toggleStatus (no dedicated status gate) | Ctrl-toggleStatus |
| BC-AUTH-09 | Policy maps each ability to `can('prime.board.*')` | Policy |
| BC-AUTH-10 | Guest → redirect to `/login` | auth middleware |

### BC-BIZ — Business logic + activity events (Source: Controller)

| ID | Behaviour | Verified event string | Source |
|----|-----------|----------------------|--------|
| BC-BIZ-01 | store creates board | `Stored` | Ctrl-store |
| BC-BIZ-02 | update writes change set | `Updated` | Ctrl-update |
| BC-BIZ-03 | destroy sets is_active=false then soft-deletes | `Trashed` | Ctrl-destroy |
| BC-BIZ-04 | restore restores soft-deleted board | `Restored` | Ctrl-restore |
| BC-BIZ-05 | forceDelete permanently removes | `Deleted` | Ctrl-forceDelete |
| BC-BIZ-06 | toggleStatus updates is_active, returns JSON | `Toggled` | Ctrl-toggleStatus |
| BC-BIZ-07 | store/update/destroy redirect → `central.prime.session-board-setup.index#academicboard` + flash | — | Ctrl |
| BC-BIZ-08 | activity written to central `sys_central_activity_logs` (tenancy uninitialised) | — | Constraint-25 |
| BC-BIZ-09 | index paginates 10/page | — | Ctrl-index |

### BC-SM — State-machine transitions (Source: is_active + soft-delete lifecycle)

| ID | State → Trigger → Next state | Source |
|----|------------------------------|--------|
| BC-SM-01 | Active → toggle → Inactive | Screen-SM |
| BC-SM-02 | Inactive → toggle → Active | Screen-SM |
| BC-SM-03 | Present → destroy → Trashed (is_active=false) | Screen-SM |
| BC-SM-04 | Trashed → restore → Present | Screen-SM |
| BC-SM-05 | Trashed → forceDelete → Gone (unrecoverable) | Screen-SM |

### BC-INT / BC-REF — Integration & FK (Source: Model + DDL FKs)

| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | `organizations()` belongsToMany via `sch_board_organization_jnt` (tenant-side; cross-module) | Model |
| BC-REF-01 | `sch_board_organization_jnt.board_id` → `glb_boards.id` ON DELETE CASCADE | DDL-`_tenant_db_v4.sql` |
| BC-REF-02 | Timetable `board_id` → `glb_boards.id` | DDL-`Timetable_DDL_v7.8.sql` |

### BC-EDG — Edge cases

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | name at 50-char boundary accepted | Screen-VR |
| BC-EDG-02 | short_name at 10-char boundary accepted | Screen-VR |
| BC-EDG-03 | name 51 chars rejected | Screen-VR |
| BC-EDG-04 | short_name 11 chars rejected | Screen-VR |
| BC-EDG-05 | XSS payload in name escaped on render | Security |
| BC-EDG-06 | whitespace-only name rejected (required) | Screen-VR |
| BC-EDG-07 | soft-deleted name/short_name still blocks a new unique | DEV-PRM-BOARD-05 |

### BC-CFG — Configuration

| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | flash() resolves Board-scoped success text from `config/flash.php` | config/flash.php |

---

## 2. Test Case List

### Positive (TC-P)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-*/VAL-*/AUTH-09 | Multiple | Config-truth mega-assert | All config correct | test_board_01 | Ready |
| TC-P02 | BC-DB-01,02 | DDL | Table + columns exist | Present | test_board_02 | Ready |
| TC-P03 | BC-DB-06,07 | DDL | Unique indexes exist | name & short_name unique | test_board_03 | Ready |
| TC-P04 | BC-DB-08 | DDL/Model | SoftDeletes + connection | global_master + trait | test_board_04 | Ready |
| TC-P05 | BC-BIZ-08 | Constraint-25 | Central activity sink | sys_central_activity_logs | test_board_05 | Ready |
| TC-P10 | BC-BIZ-01 | Ctrl | store logs Stored | event asserted | test_board_10 | Ready |
| TC-P11 | BC-BIZ-02 | Ctrl | update logs Updated | event asserted | test_board_11 | Ready |
| TC-P12 | BC-BIZ-03 | Ctrl | destroy soft-deletes+Trashed | deleted_at set | test_board_12 | Ready |
| TC-P13 | BC-BIZ-04 | Ctrl | restore logs Restored | restored | test_board_13 | Ready |
| TC-P14 | BC-BIZ-05 | Ctrl | forceDelete logs Deleted | gone | test_board_14 | Ready |
| TC-P15 | BC-BIZ-06 | Ctrl | toggleStatus logs Toggled+JSON | JSON success | test_board_15 | Ready |
| TC-P16 | BC-BIZ-09 | Ctrl | index paginate 10 | paginate(10) | test_board_16 | Ready |
| TC-P17 | BC-BIZ-07 | Ctrl | redirect + flash | session-board-setup#academicboard | test_board_17 | Ready |
| TC-P60 | UI | View | index renders table | table shown | test_board_60 | Ready |
| TC-P61 | UI | View | create form fields | name+short_name | test_board_61 | Ready |
| TC-P62 | UI | View | empty state | "Not Data Found" | test_board_62 | Ready |
| TC-P63 | BC-BIZ-06 | View | status-switch wiring | toggleStatus route | test_board_63 | Ready |
| TC-P64 | BC-AUTH | View | action wiring | edit/delete routes | test_board_64 | Ready |
| TC-P65 | BC-AUTH-04 | View | show gates Edit | @can update | test_board_65 | Ready |
| TC-P70 | BC-EDG-01 | Screen-VR | name 50 boundary | accepted | test_board_70 | Ready |
| TC-P71 | BC-EDG-02 | Screen-VR | short_name 10 boundary | accepted | test_board_71 | Ready |
| TC-P80 | BC-CFG-01 | config | flash text | exact strings | test_board_80 | Ready |

### Negative (TC-N)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N30 | BC-VAL-01 | Req | name required | error on name | test_board_30 | Ready |
| TC-N31 | BC-VAL-04 | Req | short_name required | error on short_name | test_board_31 | Ready |
| TC-N32 | BC-VAL-07 | Req | is_active required|boolean | rule present | test_board_32 | Ready |
| TC-N33 | BC-VAL-02 | Req | name max:50 | error | test_board_33 | Ready |
| TC-N34 | BC-VAL-05 | Req | short_name max:10 | error | test_board_34 | Ready |
| TC-N35 | BC-VAL-03 | Req | name unique | error | test_board_35 | Ready |
| TC-N36 | BC-VAL-06 | Req | short_name unique | error | test_board_36 | Ready |
| TC-N37 | BC-VAL-03 | Req | unique ignores current on update | ->ignore | test_board_37 | Ready |
| TC-N38 | BC-EDG-06 | Req | whitespace-only name | error | test_board_38 | Ready |
| TC-N39 | BC-VAL | Req | rule strings present | exact | test_board_39 | Ready |
| TC-N50 | BC-AUTH-01..08 | Ctrl | gate strings | all present | test_board_50 | Ready |
| TC-N51 | BC-AUTH-09 | Policy | policy maps | can() present | test_board_51 | Ready |
| TC-N52 | BC-AUTH-10 | auth | guest redirect | /login or 404 | test_board_52 | Ready |
| TC-N53 | BC-AUTH-01 | Policy | index denied w/o viewAny | 403/redirect | test_board_53 | Ready |
| TC-N54 | BC-AUTH-02 | Policy | store denied w/o create | 403/redirect | test_board_54 | Ready |
| TC-N55 | BC-AUTH-08 | Ctrl | toggle uses update gate | update in body | test_board_55 | Ready |
| TC-N56 | BC-AUTH | Cross-ref | dual BoardRequest divergence | documented | test_board_56 | Ready |
| TC-N72 | BC-EDG-03 | Screen-VR | name 51 rejected | error | test_board_72 | Ready |
| TC-N73 | BC-EDG-04 | Screen-VR | short_name 11 rejected | error | test_board_73 | Ready |
| TC-N75 | BC-EDG-07 | DEV-05 | soft-deleted name blocks new | error | test_board_75 | Ready |
| TC-N76 | BC-VAL-08 | Req | checkbox coercion | 'on'→true | test_board_76 | Ready |
| TC-N94 | Security | Route | invalid id 404 | 403/404 | test_board_94 | Ready |
| TC-N95 | BC-EDG | Req | duplicate short_name | error | test_board_95 | Ready |

### Dependency (TC-D)

| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D40 | E | BC-INT-01 | Model | organizations() belongsToMany | defined | test_board_40 | Ready |
| TC-D41 | C | BC-REF-01 | DDL | junction FK cascade | ON DELETE CASCADE | test_board_41 | Ready |
| TC-D42 | E | BC-REF-02 | DDL | timetable FK | references glb_boards | test_board_42 | Ready |
| TC-D43 | E | BC-INT-01 | Model | cross-module access defensive | int or skip | test_board_43 | Ready |
| TC-D22 | B | BC-SM-03 | SM | present→trashed | soft-deleted | test_board_22 | Ready |
| TC-D23 | B | BC-SM-04 | SM | trashed→present | restored | test_board_23 | Ready |
| TC-D24 | B | BC-SM-05 | SM | trashed→gone | force-deleted | test_board_24 | Ready |
| TC-D25 | B | BC-SM-05 | SM | restore after force fails | not recovered | test_board_25 | Ready |
| TC-D20 | F | BC-SM-01 | SM | active→inactive | toggled | test_board_20 | Ready |
| TC-D21 | F | BC-SM-02 | SM | inactive→active | toggled | test_board_21 | Ready |

### Tenancy / Security (TC-T / TC-S)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-T90 | BC-BIZ-08 | Model | central DB scope | global_master, no tenancy | test_board_90 | Ready |
| TC-T91 | BC-BIZ-08 | Constraint-25 | central sink when uninit | sys_central_activity_logs | test_board_91 | Ready |
| TC-S74 | BC-EDG-05 | Security | stored XSS in name escaped | escaped | test_board_74 | Ready |
| TC-S92 | BC-EDG-05 | Security | reflected XSS short_name escaped | {{ }} echo | test_board_92 | Ready |
| TC-S93 | Security | Model | mass-assignment guard | only fillable | test_board_93 | Ready |

---

## 3. Known Source Defects (candidate — verify in source)

| ID | Severity | Description | Proving test |
|----|----------|-------------|--------------|
| DEV-PRM-BOARD-01 | P3 | Two `BoardRequest` classes: controller uses `GlobalMaster` (authorize=true); the `Prime` duplicate gates by ability and is dead code | test_board_56 |
| DEV-PRM-BOARD-02 | P3 | Two `Board` model files both namespaced `Modules\GlobalMaster\Models` (Prime path copy has `organizations()` commented) — PSR-4 ambiguity | test_board_40 |
| DEV-PRM-BOARD-03 | P3 | Validation `name` max:50 / `short_name` max:10 stricter than DDL varchar(255)/varchar(20) | test_board_33/34 |
| DEV-PRM-BOARD-04 | P3 | `toggleStatus` writes the `Toggled` activity log **before** `$board->save()` and unconditionally (logs even if save fails) | test_board_15 |
| DEV-PRM-BOARD-05 | P2 | `Rule::unique('glb_boards')` does not exclude soft-deleted rows → a trashed board's name/short_name stays reserved | test_board_75 |
| DEV-PRM-BOARD-06 | Flag | Registry maps Prime→prm_, but primary table `glb_boards` lives in global_master (prefix glb_) | Prefix flag (this doc) |
| BUG-PRM-011 | P1 (N/A) | PrimeServiceProvider double-registers AcademicSession policy — **N/A to Board** (Board gate/policy unaffected) | — |

---

## 4. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_board_01_migration_model_and_request_configuration_are_correct | TC-P01 | Config | 01-09 |
| 2 | test_board_02_glb_boards_table_and_columns_exist | TC-P02 | Config | 01-09 |
| 3 | test_board_03_unique_indexes_on_name_and_short_name_exist | TC-P03 | Config | 01-09 |
| 4 | test_board_04_model_uses_softdeletes_and_global_master_connection | TC-P04 | Config | 01-09 |
| 5 | test_board_05_activity_log_sink_is_central_sys_central_activity_logs | TC-P05 | Config | 01-09 |
| 6 | test_board_10_store_creates_board_and_logs_stored_event | TC-P10 | BIZ | 10-19 |
| 7 | test_board_11_update_modifies_board_and_logs_updated_event | TC-P11 | BIZ | 10-19 |
| 8 | test_board_12_destroy_soft_deletes_and_sets_inactive_logs_trashed | TC-P12 | BIZ | 10-19 |
| 9 | test_board_13_restore_restores_and_logs_restored | TC-P13 | BIZ | 10-19 |
| 10 | test_board_14_force_delete_permanently_removes_and_logs_deleted | TC-P14 | BIZ | 10-19 |
| 11 | test_board_15_toggle_status_updates_is_active_and_logs_toggled | TC-P15 | BIZ | 10-19 |
| 12 | test_board_16_index_paginates_ten_per_page | TC-P16 | BIZ | 10-19 |
| 13 | test_board_17_store_redirects_to_session_board_setup_with_success_flash | TC-P17 | BIZ | 10-19 |
| 14 | test_board_20_active_board_toggles_to_inactive | TC-D20 | SM | 20-29 |
| 15 | test_board_21_inactive_board_toggles_to_active | TC-D21 | SM | 20-29 |
| 16 | test_board_22_present_board_transitions_to_trashed_on_destroy | TC-D22 | SM | 20-29 |
| 17 | test_board_23_trashed_board_transitions_to_present_on_restore | TC-D23 | SM | 20-29 |
| 18 | test_board_24_trashed_board_transitions_to_gone_on_force_delete | TC-D24 | SM | 20-29 |
| 19 | test_board_25_restore_does_not_recover_after_force_delete | TC-D25 | SM | 20-29 |
| 20 | test_board_30_name_is_required | TC-N30 | VAL | 30-39 |
| 21 | test_board_31_short_name_is_required | TC-N31 | VAL | 30-39 |
| 22 | test_board_32_is_active_is_required_boolean | TC-N32 | VAL | 30-39 |
| 23 | test_board_33_name_max_50_enforced | TC-N33 | VAL | 30-39 |
| 24 | test_board_34_short_name_max_10_enforced | TC-N34 | VAL | 30-39 |
| 25 | test_board_35_name_must_be_unique | TC-N35 | VAL | 30-39 |
| 26 | test_board_36_short_name_must_be_unique | TC-N36 | VAL | 30-39 |
| 27 | test_board_37_unique_ignores_current_record_on_update | TC-N37 | VAL | 30-39 |
| 28 | test_board_38_whitespace_only_name_rejected | TC-N38 | VAL | 30-39 |
| 29 | test_board_39_request_rules_file_contains_exact_rule_strings | TC-N39 | VAL | 30-39 |
| 30 | test_board_40_organizations_relationship_defined_belongsToMany | TC-D40 | INT | 40-49 |
| 31 | test_board_41_board_organization_junction_fk_cascade_documented | TC-D41 | REF | 40-49 |
| 32 | test_board_42_timetable_board_fk_references_glb_boards | TC-D42 | REF | 40-49 |
| 33 | test_board_43_cross_module_organization_access_is_defensive | TC-D43 | INT | 40-49 |
| 34 | test_board_50_controller_gate_authorize_strings_are_correct | TC-N50 | AUTH | 50-59 |
| 35 | test_board_51_board_policy_maps_abilities_to_permissions | TC-N51 | AUTH | 50-59 |
| 36 | test_board_52_guest_is_redirected_to_login | TC-N52 | AUTH | 50-59 |
| 37 | test_board_53_index_forbidden_without_viewAny | TC-N53 | AUTH | 50-59 |
| 38 | test_board_54_store_forbidden_without_create | TC-N54 | AUTH | 50-59 |
| 39 | test_board_55_toggle_status_uses_update_permission | TC-N55 | AUTH | 50-59 |
| 40 | test_board_56_prime_and_globalmaster_request_authorize_divergence_documented | TC-N56 | AUTH | 50-59 |
| 41 | test_board_60_index_page_renders_board_table | TC-P60 | UIX | 60-69 |
| 42 | test_board_61_create_form_has_name_and_short_name_fields | TC-P61 | UIX | 60-69 |
| 43 | test_board_62_index_empty_state_shows_no_data | TC-P62 | UIX | 60-69 |
| 44 | test_board_63_status_switch_component_targets_toggle_route | TC-P63 | UIX | 60-69 |
| 45 | test_board_64_action_component_wires_edit_delete_routes | TC-P64 | UIX | 60-69 |
| 46 | test_board_65_show_view_gates_edit_button_by_update_permission | TC-P65 | UIX | 60-69 |
| 47 | test_board_70_name_at_max_50_boundary_accepted | TC-P70 | EDG | 70-79 |
| 48 | test_board_71_short_name_at_max_10_boundary_accepted | TC-P71 | EDG | 70-79 |
| 49 | test_board_72_name_51_chars_rejected | TC-N72 | EDG | 70-79 |
| 50 | test_board_73_short_name_11_chars_rejected | TC-N73 | EDG | 70-79 |
| 51 | test_board_74_xss_payload_in_name_is_escaped_on_render | TC-S74 | EDG/SEC | 70-79 |
| 52 | test_board_75_soft_deleted_name_still_blocks_new_unique | TC-N75 | EDG | 70-79 |
| 53 | test_board_76_checkbox_on_coerced_to_true_by_prepareForValidation | TC-N76 | VAL | 70-79 |
| 54 | test_board_80_flash_messages_resolve_board_resource_text | TC-P80 | CFG | 80-89 |
| 55 | test_board_90_board_data_lives_in_central_global_master_not_tenant | TC-T90 | Tenancy | 90-99 |
| 56 | test_board_91_activity_written_to_central_sink_when_tenancy_uninitialized | TC-T91 | Tenancy | 90-99 |
| 57 | test_board_92_reflected_xss_in_short_name_escaped | TC-S92 | Security | 90-99 |
| 58 | test_board_93_mass_assignment_guard_only_fillable_columns | TC-S93 | Security | 90-99 |
| 59 | test_board_94_invalid_board_id_returns_404 | TC-N94 | Security | 90-99 |
| 60 | test_board_95_duplicate_short_name_case_sensitivity_boundary | TC-N95 | EDG | 90-99 |
