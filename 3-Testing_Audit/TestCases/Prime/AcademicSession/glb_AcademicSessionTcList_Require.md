# Academic Session — Test Case List & Business Conditions

- **Module:** Prime (PRM) — **DB scope: CENTRAL** (`global_master` DB, no tenancy)
- **Feature / Screen:** AcademicSession
- **Primary table:** `glb_academic_sessions` (DDL `_global_db_v4.sql`) — **prefix `glb_`**
  - *Registry-vs-DDL flag:* the module registry lists Prime prefix `prm_`, but this feature's primary table is `glb_academic_sessions`, so the artifact prefix follows the DDL table rule (`glb_`).
- **Controller:** `Modules\Prime\Http\Controllers\AcademicSessionController`
- **FormRequest:** `Modules\Prime\Http\Requests\AcademicSessionRequest`
- **Model:** `Modules\Prime\Models\AcademicSession` (connection `global_master_mysql`, SoftDeletes)
- **Routes (name prefix `central.prime.`):** `academic-session.{index,create,store,show,edit,update,destroy}`, `.trashed`, `.restore`, `.forceDelete`, `.toggleStatus`
- **URL base:** `http://127.0.0.1:8000/prime/academic-session`
- **Activity sink:** `sys_central_activity_logs` (central, `Modules\Prime\Models\ActivityLog`) — tenancy NOT initialized
- **Test file:** `glb_AcademicSession_TestCas.php` (35 methods) — single comprehensive suite (no V1/V2)

---

## 1. Business Conditions

### BC-DB (DDL `glb_academic_sessions`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `id` INT unsigned PK auto-increment | DDL-glb_academic_sessions |
| BC-DB-02 | `short_name` varchar(20) NOT NULL, UNIQUE | DDL-glb_academic_sessions |
| BC-DB-03 | `name` varchar(50) NOT NULL (NO db unique) | DDL-glb_academic_sessions |
| BC-DB-04 | `start_date` date NOT NULL (no default) | DDL-glb_academic_sessions |
| BC-DB-05 | `end_date` date NOT NULL (no default) | DDL-glb_academic_sessions |
| BC-DB-06 | `is_current` tinyint(1) NOT NULL DEFAULT 1 | DDL-glb_academic_sessions |
| BC-DB-07 | `current_flag` generated = CASE WHEN is_current=1 THEN 1 ELSE NULL, UNIQUE | DDL-glb_academic_sessions |
| BC-DB-08 | `deleted_at` soft-delete column present | DDL-glb_academic_sessions |
| BC-DB-09 | **No `is_active` column exists** | DDL-glb_academic_sessions |

### BC-VAL (FormRequest `AcademicSessionRequest`)
| ID | Rule / Message | Source |
|----|----------------|--------|
| BC-VAL-01 | `name` required, string, max:50, unique(glb_academic_sessions) | Screen-VR / FormRequest |
| BC-VAL-02 | `short_name` required, string, max:10, unique(glb_academic_sessions) | FormRequest |
| BC-VAL-03 | `is_current` nullable boolean; `prepareForValidation` casts checkbox to bool | FormRequest |
| BC-VAL-04 | **No rule for `start_date` / `end_date`** (defect BUG-PRM-012) | FormRequest |
| BC-VAL-05 | On update, unique ignores current record id | FormRequest |

### BC-AUTH (gates — `Gate::authorize('prime.academic-session.*')`)
| ID | Method → Gate string | Source |
|----|----------------------|--------|
| BC-AUTH-01 | index → `prime.academic-session.viewAny` | Controller |
| BC-AUTH-02 | create/store → `prime.academic-session.create` | Controller |
| BC-AUTH-03 | show → `prime.academic-session.view` | Controller |
| BC-AUTH-04 | edit/update/toggleStatus → `prime.academic-session.update` | Controller |
| BC-AUTH-05 | destroy → `prime.academic-session.delete` | Controller |
| BC-AUTH-06 | trashed/restore → `prime.academic-session.restore` | Controller |
| BC-AUTH-07 | forceDelete → `prime.academic-session.forceDelete` | Controller |
| BC-AUTH-08 | Gates are **string abilities**, resolved via permission layer + super-admin `Gate::before`; the model-mapped `AcademicSessionPolicy` is never invoked (BUG-PRM-011) | Provider/Policy |

### BC-BIZ (activity-log events — verbatim)
| ID | Behaviour → event string | Source |
|----|--------------------------|--------|
| BC-BIZ-01 | store → `'Stored'` | Controller |
| BC-BIZ-02 | update → `'Updated'` | Controller |
| BC-BIZ-03 | destroy → `'Trashed'` | Controller |
| BC-BIZ-04 | restore → `'Restored'` | Controller |
| BC-BIZ-05 | forceDelete → `'Deleted'` | Controller |
| BC-BIZ-06 | toggleStatus → `'Toggled'` | Controller |
| BC-BIZ-07 | Success toasts via `flash(...)`; update uses hyphenated key (BUG-PRM-014) | Controller/flash.php |
| BC-BIZ-08 | Redirects target `central.prime.session-board-setup.index#academicsession` | Controller |

### BC-SM (state machine — current-session lifecycle)
| ID | State → Trigger → Next | Source |
|----|------------------------|--------|
| BC-SM-01 | non-current → set is_current=1 (only one allowed) → current; 2nd current rejected by unique current_flag | Screen-SM / DDL |
| BC-SM-02 | `scopeCurrent()` yields at most one row | Model |
| BC-SM-03 | toggleStatus intends to switch active via `is_active` (nonexistent) → broken (BUG-PRM-013) | Controller |

### BC-REF / BC-INT (relationships / FK)
| ID | Relation | Source |
|----|----------|--------|
| BC-REF-01 | SoftDeletes: soft delete preserves row; force delete removes it | Model |
| BC-INT-01 | hasMany organizationAcademicSessions; belongsToMany boards; hasMany classModeRules/classGroupRequirements/activities/timetables | Model |
| BC-INT-02 | Table on `global_master_mysql` connection (shared central DB) | Model |

### BC-EDG (edge / spec inconsistencies)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | update flash key `academic-session` (hyphen) vs `academic_session` (BUG-PRM-014) | Controller |
| BC-EDG-02 | DDL short_name varchar(20) wider than request max:10 | DDL vs FormRequest |
| BC-EDG-03 | `required` allows whitespace-only name (no trim/regex) | FormRequest |
| BC-EDG-04 | `name` has app-only uniqueness (no DB backstop) | DDL vs FormRequest |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-* | DDL | Schema/model/request config truth | table/cols/casts/fillable correct; no is_active | `test_..._01` | Automated |
| TC-P02 | BC-DB-02/07 | DDL | Unique indexes match DDL | short_name & current_flag unique; name not unique | `test_..._02` | Automated |
| TC-P10 | BC-BIZ-01 | Controller | Index lists sessions + columns | table + headers render | `test_..._10` | Automated |
| TC-P11 | BC-BIZ-02 | Blade | Create form fields render | name/short/dates/is_current present | `test_..._11` | Automated |
| TC-P12 | BC-BIZ-01 | Controller | Store persists + logs Stored | row persists with dates | `test_..._12` | Automated |
| TC-P13 | BC-BIZ-02 | Controller | Update changes persist | name updated | `test_..._13` | Automated |
| TC-P14 | BC-BIZ-05 | Blade | Show displays details | name/short shown | `test_..._14` | Automated |
| TC-P15 | BC-BIZ-03/REF-01 | Controller | Soft delete → trash | deleted_at set, row kept | `test_..._15` | Automated |
| TC-P17 | BC-BIZ-04 | Controller | Restore recovers | deleted_at null | `test_..._17` | Automated |
| TC-P19 | BC-BIZ-01..06 | Controller | Activity event strings verbatim | Stored/Updated/Trashed/Restored/Deleted/Toggled | `test_..._19` | Automated |
| TC-P37 | BC-VAL-03 | FormRequest | is_current prepared as boolean | prepareForValidation present | `test_..._37` | Automated |
| TC-P53 | BC-AUTH-* | Controller | Exact permission gate strings | 7 gates verbatim | `test_..._53` | Automated |
| TC-P62 | BC-UIX | Blade | Index action + header controls | create link present | `test_..._62` | Automated |
| TC-P63 | BC-UIX | Blade | Trash view renders | table present | `test_..._63` | Automated |

### State machine (TC-S)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-S20 | BC-SM-01 | DDL | Only one current session (BR-PRM-021) | 2nd is_current=1 rejected | `test_..._20` | Automated |
| TC-S21 | BC-SM-02 | Model | scopeCurrent yields ≤1 | count ≤ 1 | `test_..._21` | Automated |
| TC-S23 | BC-SM-03 | Controller | toggle/destroy use missing is_active (BUG-PRM-013) | column absent proven | `test_..._23` | Automated |

### Negative / Validation (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N30 | BC-VAL-01 | FormRequest | name required | session error on name | `test_..._30` | Automated |
| TC-N31 | BC-VAL-02 | FormRequest | short_name required | error on short_name | `test_..._31` | Automated |
| TC-N32 | BC-VAL-01 | FormRequest | name max:50 | error on name | `test_..._32` | Automated |
| TC-N33 | BC-VAL-02 | FormRequest | short_name max:10 | error on short_name | `test_..._33` | Automated |
| TC-N34 | BC-VAL-02 | FormRequest | duplicate short_name | error on short_name | `test_..._34` | Automated |
| TC-N36 | BC-VAL-04 | FormRequest | dates not validated (BUG-PRM-012) | no start/end rules | `test_..._36` | Automated |
| TC-N39 | Security | Blade | XSS in name escaped | raw script absent | `test_..._39` | Automated |
| TC-N50 | BC-AUTH | Middleware | Guest → /login | redirect | `test_..._50` | Automated |
| TC-N55 | BC-AUTH-08 | Provider | Model policy bypassed (BUG-PRM-011) | single reg; orphan policy | `test_..._55` | Automated |
| TC-N70 | BC-EDG-01 | Controller | update flash inconsistent (BUG-PRM-014) | hyphen key proven | `test_..._70` | Automated |
| TC-N71 | BC-EDG-02 | DDL/Req | short_name 20 vs cap 10 | mismatch proven | `test_..._71` | Automated |
| TC-N73 | BC-EDG-03 | FormRequest | whitespace name passes required | no anti-ws rule | `test_..._73` | Automated |

### Dependency / Central / Security (TC-D / TC-T)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-D40 | BC-REF-01 | Model | Force delete removes row | row gone | `test_..._40` | Automated |
| TC-D42 | BC-INT-01 | Model | Relationships return relation objects | HasMany/BelongsToMany | `test_..._42` | Automated |
| TC-D43 | BC-INT-02 | Model | Table on global_master connection | connection name correct | `test_..._43` | Automated |
| TC-T90 | central | Constraint #21 | Runs central, no tenancy | tenancy not initialized | `test_..._90` | Automated |
| TC-T91 | BC-BIZ | Constraint #25 | Activity → central sink | sys_central_activity_logs | `test_..._91` | Automated |
| TC-S92 | BC-BIZ-05 | Controller | Invalid id → 404 | 404 page | `test_..._92` | Automated |

---

## 3. Known Source Defects (mapped)
| ID | Sev | Title | Proving method |
|----|-----|-------|----------------|
| BUG-PRM-012 | P1 | start_date/end_date unvalidated + controller `validated()` drops NOT NULL dates | `test_..._01`, `test_..._36` |
| BUG-PRM-013 | P1 | `is_active` referenced by controller/blades but not a column | `test_..._01`, `test_..._23` |
| BUG-PRM-011 | P1 | AcademicSessionPolicy unreachable (string gates); SessionBoardSetupPolicy orphan; no double registration | `test_..._55` |
| BR-PRM-021 | P2 | one-current-session enforced only at DB (unique current_flag), not app | `test_..._20`, `test_..._21` |
| BUG-PRM-014 | P3 | update flash uses hyphenated resource key | `test_..._70` |
| D25-PRM-001 | audit | NOT REPRODUCED — current store/update use `validated()`, not `all()` | `test_..._01` (rules), doc |

## 4. Test Method Index (bands)
| # | Method | TC | Band |
|---|--------|----|------|
| 1 | test_academicsession_01_migration_model_and_request_configuration_are_correct | TC-P01 | 01-09 |
| 2 | test_academicsession_02_unique_indexes_match_ddl | TC-P02 | 01-09 |
| 3 | test_academicsession_10_index_lists_sessions_and_columns | TC-P10 | 10-19 |
| 4 | test_academicsession_11_create_page_renders_form_fields | TC-P11 | 10-19 |
| 5 | test_academicsession_12_store_persists_and_logs_stored_event | TC-P12 | 10-19 |
| 6 | test_academicsession_13_update_changes_persist | TC-P13 | 10-19 |
| 7 | test_academicsession_14_show_displays_details | TC-P14 | 10-19 |
| 8 | test_academicsession_15_soft_delete_moves_to_trash | TC-P15 | 10-19 |
| 9 | test_academicsession_17_restore_recovers_session | TC-P17 | 10-19 |
| 10 | test_academicsession_19_activity_log_event_strings_are_verbatim | TC-P19 | 10-19 |
| 11 | test_academicsession_20_only_one_current_session_enforced_by_db | TC-S20 | 20-29 |
| 12 | test_academicsession_21_current_scope_filters_is_current | TC-S21 | 20-29 |
| 13 | test_academicsession_23_toggle_and_destroy_reference_missing_is_active_column | TC-S23 | 20-29 |
| 14 | test_academicsession_30_store_requires_name | TC-N30 | 30-39 |
| 15 | test_academicsession_31_store_requires_short_name | TC-N31 | 30-39 |
| 16 | test_academicsession_32_name_max_50_enforced | TC-N32 | 30-39 |
| 17 | test_academicsession_33_short_name_max_10_enforced | TC-N33 | 30-39 |
| 18 | test_academicsession_34_duplicate_short_name_rejected | TC-N34 | 30-39 |
| 19 | test_academicsession_36_dates_not_validated_by_formrequest | TC-N36 | 30-39 |
| 20 | test_academicsession_37_is_current_prepared_as_boolean | TC-P37 | 30-39 |
| 21 | test_academicsession_39_xss_in_name_is_escaped_on_render | TC-N39 | 30-39 |
| 22 | test_academicsession_40_force_delete_removes_row_entirely | TC-D40 | 40-49 |
| 23 | test_academicsession_42_relationships_return_relation_objects | TC-D42 | 40-49 |
| 24 | test_academicsession_43_table_lives_on_global_master_connection | TC-D43 | 40-49 |
| 25 | test_academicsession_50_guest_is_redirected_to_login | TC-N50 | 50-59 |
| 26 | test_academicsession_53_controller_uses_exact_permission_strings | TC-P53 | 50-59 |
| 27 | test_academicsession_55_model_policy_is_bypassed_by_string_gates | TC-N55 | 50-59 |
| 28 | test_academicsession_62_index_shows_action_and_header_controls | TC-P62 | 60-69 |
| 29 | test_academicsession_63_trash_view_renders | TC-P63 | 60-69 |
| 30 | test_academicsession_70_update_flash_uses_inconsistent_resource_key | TC-N70 | 70-79 |
| 31 | test_academicsession_71_short_name_ddl_20_but_request_caps_10 | TC-N71 | 70-79 |
| 32 | test_academicsession_73_whitespace_only_name_passes_required | TC-N73 | 70-79 |
| 33 | test_academicsession_90_runs_on_central_context_without_tenancy | TC-T90 | 90-99 |
| 34 | test_academicsession_91_activity_writes_to_central_sink | TC-T91 | 90-99 |
| 35 | test_academicsession_92_invalid_id_returns_404 | TC-S92 | 90-99 |
