# Configuration — Business Conditions & Test Case List

**Module:** BehaviouralAssessment  ·  **Feature/Screen:** Configuration (`07-Configuration.md`)
**Primary table:** `ba_config` (one row per academic session — settings/singleton-style)
**File prefix:** `bha_` (per DDL doc `CREATE TABLE bha_config` + inventory). **Live table is `ba_config`** — see `DOC-BA-001`.
**App aliases:** route/controller `configs` / `BaConfigController`  ·  **FormRequest:** `BaConfigRequest`.
**Service in write path:** none (plain Eloquent). **Config is CONSUMED (read) by `BehaviouralScoreService`** (rating-scale binding + `aggregation_method`).
**Test style:** browser **Dusk** (`extends DuskTestCase`) — mirrors the module's committed sibling RatingScale suite.
**DB scope:** **tenant-side** (DDL header `Database: tenant_db`; migration under `database/migrations/tenant/`).
**Activity log:** none for this feature (config CRUD uses flash `->with('success', …)` only; toggle returns JSON).

> ⚠️ **Prefix / doc discrepancy (`DOC-BA-001`, audit-confirmed):** the DDL doc + inventory label the table `bha_config`; the live migration, model and DB use `ba_config`. Artifact **file names** keep `bha_`; every **PHP schema assertion** targets the real `ba_config` table. Do not rename in code.

> **Module-enabled prerequisite:** `BehaviouralAssessment` must be `true` in `prime_testing/modules_statuses.json` (currently `false` → all routes 404). See Validation Report §E.

---

## 1. Business Conditions

### BC-DB — Schema / columns / constraints (Source: DDL + live migration)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_config` has `academic_session_id, rating_scale_id, is_result_integration_enabled, weightage_percent, aggregation_method, parent_notification_threshold, is_active, created_by, updated_by, timestamps, deleted_at` | DDL-ba_config |
| BC-DB-02 | `weightage_percent` is `DECIMAL(4,1)` default 10.0; `aggregation_method`/`parent_notification_threshold` are ENUM; `is_result_integration_enabled`/`is_active` are `TINYINT(1)` | DDL / migration |
| BC-DB-04 | `academic_session_id, rating_scale_id, created_by, updated_by` are `NOT NULL` **without defaults** (DB rejects missing); all other columns carry DB defaults | DDL-ba_config |
| BC-DB-06 | Model uses `SoftDeletes`; casts: `weightage_percent → decimal:1`, `is_result_integration_enabled/is_active → boolean`, ids → integer | Model |

### BC-VAL — Validation rules + messages (Source: `BaConfigRequest`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `academic_session_id` required, integer, `exists:sch_org_academic_sessions_jnt,id`, **unique** on `ba_config.academic_session_id` ignoring self, scoped `whereNull(deleted_at)` | Screen-BR (one config/session) / Request:22-27 |
| BC-VAL-02 | Unique failure message: `A configuration already exists for the selected academic session.` | Request:48 |
| BC-VAL-03 | `rating_scale_id` required, integer, `exists:ba_rating_scales,id` | Screen-VR / Request:28 |
| BC-VAL-04 | `weightage_percent` required, numeric, `min:5`, `max:20` | Request:30 |
| BC-VAL-05 | `aggregation_method` required, `in:average,weighted_average,separate_display` | Request:31 |
| BC-VAL-06 | `parent_notification_threshold` required, `in:minor,moderate,major,critical` | Request:32 |
| BC-VAL-07 | `is_result_integration_enabled`/`is_active` cast to boolean in `prepareForValidation`; `is_active` defaults true | Request:37-43 |

### BC-AUTH — Permission gates (Source: Controller `Gate::authorize` + `BaConfigPolicy` + Blade)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | All web routes require auth; guest → redirect `/login` | routes / middleware |
| BC-AUTH-02 | `viewAny/view/create/update/delete/restore/forceDelete/status` gated by `tenant.behavioural-assessment.configs.*` | Controller + BaConfigPolicy |
| BC-AUTH-03 | `BaConfigRequest::authorize()` returns bare `true` — auth deferred to controller gates | Audit-SEC-BA-002 |
| BC-AUTH-04 | User lacking `.create` is blocked (403) from the create screen | Controller@create:27 |
| BC-AUTH-05 | Invalid id on `show` → `findOrFail` 404 | Controller@show:50 |

### BC-BIZ — Business behaviour / flash (Source: Controller + Blade)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Create page renders "Academic Context" + "Rules" sections + "Save Configuration" | create.blade |
| BC-BIZ-02 | Store persists config, flash `Configuration created successfully.` | Controller@store:44 |
| BC-BIZ-03 | Show renders "Assessment Configuration Details" table (session, scale, weightage, method, alert, integration, status) | show.blade |
| BC-BIZ-04 | Update persists, flash `Configuration updated successfully.` | Controller@update:73 |
| BC-BIZ-05 | Destroy sets `is_active=false` **then** soft-deletes; flash `Configuration moved to trash.` | Controller@destroy:80-87 |
| BC-BIZ-06 | Setup config tab lists configs (session, scale, weightage, method, parent alert, report card); paginator `cfg_page`, 15/page | _configuration.blade / BaDashboardController@setup:205-212 |
| BC-BIZ-07 | Setup search filters by academic-session name/short_name **or** rating-scale name | BaDashboardController@setup:206-211 |
| BC-BIZ-08 | Trash page lists soft-deleted configs (empty state `No trashed configurations found.`) | trash.blade |

### BC-SM — State-machine / status lifecycle (Source: Controller@toggleStatus + soft-delete)
| ID | State → Trigger → Next | Source |
|----|-----------------------|--------|
| BC-SM-01 | active → toggleStatus → inactive (and back) | Controller@toggleStatus:123-136 |
| BC-SM-02 | toggleStatus returns JSON `{success, is_active, message}` (`Configuration activated./deactivated.`) | Controller@toggleStatus:131-135 |
| BC-SM-03 | present → destroy → trashed (is_active=false) | Controller@destroy |
| BC-SM-04 | trashed → restore → present | Controller@restore |
| BC-SM-05 | trashed → forceDelete → removed | Controller@forceDelete |
| BC-SM-06 | active-scale binding should LOCK once ratings exist (BR-BA-029) — **no guard implemented** | Screen-BR / Audit-DATA-BA-001 |

### BC-REF / BC-INT — FK & integration (Source: DDL FKs + Service)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `ba_config.rating_scale_id` → `ba_rating_scales.id` `ON DELETE RESTRICT` | DDL / migration |
| BC-REF-02 | `ba_config.academic_session_id` → `sch_org_academic_sessions_jnt.id` `ON DELETE RESTRICT` | DDL / migration |
| BC-REF-03 | `BaConfig::ratingScale()` belongsTo; `BaRatingScale::configs()` hasMany | Model |
| BC-REF-04 | `BaConfig::academicSession()` belongsTo `OrganizationAcademicSession` | Model |
| BC-INT-01 | `BehaviouralScoreService` looks up config by session + reads `$config->ratingScale` and `$config->aggregation_method` | Service:45-49,90 |
| BC-INT-02 | `parent_notification_threshold` is intended (REQ-BA-015) to drive severe-incident parent notification — **never consumed** | Audit-SEC-BA-001 |

### BC-CFG — Configuration / settings behaviour (Source: Service + migration + Screen)
| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | Default rating scale binding: `$config?->ratingScale` drives scoring; fallback = `is_default` active scale | Service:49 |
| BC-CFG-02 | `aggregation_method` selects overall-score branch (`average`/`weighted_average`/`separate_display`) | Service:150-155 |
| BC-CFG-03 | `is_result_integration_enabled` flag persists (report-card inclusion) | migration / create.blade |
| BC-CFG-04 | Create form prefills `weightage_percent = 10.0` | create.blade:59 |
| BC-CFG-05 | Create form defaults `aggregation_method = weighted_average` | create.blade:73 |
| BC-CFG-06 | `weightage_percent` stored but **not consumed** by scoring service (candidate) | Service (no reference) |
| BC-CFG-07 | Tenant-per-DB; no `tenant_id` column; requires initialized tenant | DDL header |

### BC-EDG — Edge / boundary (Source: DDL limits + requirement)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `uq_ba_config_session(academic_session_id)` unique **excludes** soft-deletes → recreate collision | migration uq_ba_config_session |
| BC-EDG-02 | `weightage_percent` boundary values 5.0 / 20.0 persist | DDL / Request min/max |
| BC-EDG-03 | `weightage_percent` half-step (12.5) persists (DECIMAL(4,1)) | DDL |
| BC-EDG-04 | Screen fields "Approval Workflow" + "Incident Escalation Threshold" **absent** from schema (requirement divergence) | Screen vs migration |

### Known Source Defects (audit-equivalent — module uses `BUG-BA-###`/`SEC-BA-###`/`DATA-BA-###`)
| ID | Description | Proven by |
|----|-------------|-----------|
| SEC-BA-001 / BUG-BA-003 | `parent_notification_threshold` defined but **never consumed** for severe-incident parent notification (REQ-BA-015) | V2 `test_..._83` |
| DATA-BA-001 | Active rating scale switchable mid-session after ratings exist (BR-BA-029) — no guard, dropdown never locked | V2 `test_..._82` |
| SEC-BA-002 | `BaConfigRequest::authorize()` returns bare `true` (systemic) | V1 `test_..._15`, V2 `test_..._52` |
| DATA-BA-003 | Soft-delete + `uq_ba_config_session` (no `deleted_at`) → recreate-after-delete integrity error (500) | V2 `test_..._43` |
| DOC-BA-001 | DDL doc prefix `bha_config` vs live `ba_config` | V1/V2 `test_..._01` |
| CFG-BA-CFG-01 (candidate) | `weightage_percent` stored but not consumed by `BehaviouralScoreService` | V2 `test_..._84` |
| REQ-BA-CFG-01 (candidate) | Screen "Approval Workflow" + "Incident Escalation Threshold" fields not implemented | V2 `test_..._85` |

---

## 2. Test Case List

Columns: **TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status**

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-P01 | BC-DB-01/06 | DDL | Schema+model+softdelete config | Table/columns/casts/relations correct | 01 | 01 | ✅ |
| TC-P02 | BC-REF-01/02 | migration | FK + unique index config | uq_ba_config_session + FKs present | — | 02 | ✅ |
| TC-P03 | BC-DB-06 | Model | Fillable/relationships/scope | fillable + belongsTo + scopeActive | — | 03 | ✅ |
| TC-P04 | BC-DB-06 | Model | Casts persist | decimal:1 + boolean casts correct | — | 06 | ✅ |
| TC-P10 | BC-BIZ-01 | create.blade | Create page loads + sections | Academic Context/Rules/Save Configuration | 04 | 15 | ✅ |
| TC-P11 | BC-BIZ-02 | Controller | Create submission persists | Row created, flash success | 05 | 10 | ✅ |
| TC-P12 | BC-BIZ-03 | show.blade | Show renders config | Details table + scale name visible | 06 | 11 | ✅ |
| TC-P13 | BC-BIZ-04 | Controller | Edit update persists + flash | weightage updated, success flash | 07 | 12 | ✅ |
| TC-P14 | BC-CFG-03 | migration | Result-integration flag persists | is_result_integration_enabled=true | — | 13 | ✅ |
| TC-P15 | BC-CFG-04 | create.blade | Default weightage prefilled | weightage=10 | — | 14 | ✅ |
| TC-P16 | BC-CFG-05 | create.blade | aggregation default selected | weighted_average preselected | — | 15 | ✅ |
| TC-P60 | BC-BIZ-06 | setup partial | Setup tab lists created config | scale name appears in config tab | — | 60 | ✅ |
| TC-P61 | BC-BIZ-07 | setup | Search by scale filters list | matching config shown | — | 61 | ✅ |
| TC-P62 | BC-BIZ-08 | trash.blade | Trash lists soft-deleted | Deleted config visible in trash | 14 | 62 | ✅ |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-N01 | BC-DB-04 | DDL | DB rejects missing required | Insert throws 23000 | 03 | 05 | ✅ |
| TC-N02 | BC-VAL-* | Request | FormRequest rule strings present | Literal rules asserted | 02 | 04 | ✅ |
| TC-N10 | BC-VAL-01/02 | Request | Duplicate session config rejected | `.alert-danger` + message, no row | 10 | 31 | ✅ |
| TC-N30 | BC-VAL-01 | Request | Required fields blocked at server | `.alert-danger`, no row | — | 30 | ✅ |
| TC-N32 | BC-VAL-04 | Request | weightage < 5 rejected | Validation error, no row | 11 | 32 | ✅ |
| TC-N33 | BC-VAL-04 | Request | weightage > 20 rejected | Validation error, no row | 11 | 33 | ✅ |
| TC-N34 | BC-VAL-05 | Request | aggregation out of enum rejected | Validation error, no row | 12 | 34 | ✅ |
| TC-N35 | BC-VAL-06 | Request | threshold out of enum rejected | Validation error, no row | — | 35 | ✅ |
| TC-N36 | BC-REF-01 | DDL | Bogus rating_scale_id rejected | FK 23000 | — | 36 | ✅ |
| TC-N37 | BC-REF-02 | DDL | Bogus academic_session_id rejected | FK 23000 | — | 37 | ✅ |
| TC-N40 | SEC-BA-002 | Audit | authorize() returns true (proof) | authorize()===true | 15 | 52 | ✅ (proves gap) |
| TC-N41 | DATA-BA-001 | Audit | Mid-session scale switch not guarded (proof) | update()/blade have no lock; switch succeeds | — | 82 | ✅ (proves bug) |
| TC-N42 | SEC-BA-001 | Audit | Threshold never consumed (proof) | Incident controller lacks threshold reference | — | 83 | ✅ (proves bug) |
| TC-N43 | CFG-BA-CFG-01 | Candidate | weightage not consumed (proof) | Service lacks weightage_percent | — | 84 | ✅ (verify in source) |
| TC-N44 | REQ-BA-CFG-01 | Candidate | Screen-only fields absent (proof) | approval_workflow/escalation columns absent | — | 85 | ✅ (verify in source) |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 | F | BC-SM-03/04/05 | Controller | Full soft-delete→restore→forceDelete | Lifecycle transitions correct | 09 | 22/23/24 | ✅ |
| TC-D02 | B | BC-SM-04 | Controller | Restore from trash | Row returns to active scope | — | 23 | ✅ |
| TC-D03 | B | BC-SM-05 | Controller | forceDelete removes row | Row gone entirely | — | 24 | ✅ |
| TC-D06 | E | BC-INT-01 | Service | Config consumed by score service | ratingScale + aggregation_method read | — | 16 | ✅ |
| TC-D07 | E | BC-REF-03 | Model | ratingScale relationship resolves | config→scale id resolves | — | 40 | ✅ |
| TC-D08 | E | BC-REF-04 | Model | academicSession relationship resolves | config→session id resolves | — | 41 | ✅ |
| TC-D09 | C | BC-REF-01 | migration | rating_scale delete RESTRICT while referenced | force-delete of scale blocked | — | 42 | ✅ (defensive) |
| TC-D10 | G | DATA-BA-003 | migration | Soft-deleted session unique collision | Integrity error on re-add | — | 43 | ✅ (proves bug) |
| TC-D11 | G | BC-EDG-02 | DDL | weightage boundary persist | 5.0 / 20.0 stored | — | 70 | ✅ |
| TC-D12 | G | BC-EDG-03 | DDL | weightage half-step persist | 12.5 stored | — | 71 | ✅ |

### State-machine (TC-SM)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-SM01 | BC-SM-01 | Controller | Toggle active↔inactive | is_active flips | 08 | 20 | ✅ |
| TC-SM02 | BC-SM-02 | Controller | Toggle JSON payload | `{success,message}` returned | — | 21 | ✅ |
| TC-SM03 | BC-SM-03 | Controller | Destroy deactivates then trashes | is_active=false in trash | — | 22 | ✅ |

### Configuration (TC-CFG)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-CFG01 | BC-CFG-01 | Service | Default-scale binding read by service | config.ratingScale drives scoring | — | 80 | ✅ |
| TC-CFG02 | BC-CFG-02 | Service | aggregation_method drives overall score | match() branch present | — | 81 | ✅ |

### Tenancy / Security (TC-T / TC-S)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-T01 | BC-CFG-07 | DDL | Tenant-scoped, no tenant_id | tenancy initialized, no tenant_id col | — | 90 | ✅ |
| TC-S01 | BC-AUTH-01 | routes | Guest redirected (create) | `/login` | 13 | 50 | ✅ |
| TC-S02 | BC-AUTH-01 | routes | Guest redirected (setup) | `/login` | — | 51 | ✅ |
| TC-S04 | BC-AUTH-04 | Controller | Limited user forbidden | 403 / no create form | — | 53 | ✅ (defensive) |
| TC-S06 | BC-AUTH-05 | Controller | Invalid id no detail | Detail not rendered | — | 91 | ✅ |

---

## 3. V2 Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_config_01_schema_and_model_configuration_are_correct | TC-P01/DOC-BA-001 | Schema | 01–09 |
| 2 | test_config_02_fk_and_unique_index_configuration | TC-P02 | Schema | 01–09 |
| 3 | test_config_03_model_fillable_relationships_and_scope | TC-P03 | Schema | 01–09 |
| 4 | test_config_04_form_request_rules_contain_expected_constraints | TC-N02 | Validation-cfg | 01–09 |
| 5 | test_config_05_db_rejects_each_missing_required_field | TC-N01 | Validation | 01–09 |
| 6 | test_config_06_casts_persist_correctly | TC-P04 | Schema | 01–09 |
| 7 | test_config_10_create_valid_persists_row | TC-P11 | Business | 10–19 |
| 8 | test_config_11_show_page_renders_config | TC-P12 | Business | 10–19 |
| 9 | test_config_12_edit_update_persists_and_flashes | TC-P13 | Business | 10–19 |
| 10 | test_config_13_result_integration_flag_persists | TC-P14 | Config | 10–19 |
| 11 | test_config_14_create_page_prefills_default_weightage | TC-P15 | Config | 10–19 |
| 12 | test_config_15_aggregation_method_defaults_to_weighted_average | TC-P16 | Config | 10–19 |
| 13 | test_config_16_config_is_consumed_by_score_service | TC-D06 | Integration | 10–19 |
| 14 | test_config_20_toggle_status_active_inactive_cycle | TC-SM01 | State | 20–29 |
| 15 | test_config_21_toggle_status_endpoint_returns_json_payload | TC-SM02 | State | 20–29 |
| 16 | test_config_22_destroy_deactivates_then_soft_deletes | TC-SM03 | State | 20–29 |
| 17 | test_config_23_restore_brings_back_from_trash | TC-D02 | State | 20–29 |
| 18 | test_config_24_force_delete_removes_row | TC-D03 | State | 20–29 |
| 19 | test_config_30_required_fields_block_insert | TC-N30 | Validation | 30–39 |
| 20 | test_config_31_duplicate_session_config_is_rejected | TC-N10 | Validation | 30–39 |
| 21 | test_config_32_weightage_below_min_is_rejected | TC-N32 | Validation | 30–39 |
| 22 | test_config_33_weightage_above_max_is_rejected | TC-N33 | Validation | 30–39 |
| 23 | test_config_34_invalid_aggregation_method_is_rejected | TC-N34 | Validation | 30–39 |
| 24 | test_config_35_invalid_notification_threshold_is_rejected | TC-N35 | Validation | 30–39 |
| 25 | test_config_36_db_rejects_nonexistent_rating_scale_fk | TC-N36 | Validation/FK | 30–39 |
| 26 | test_config_37_db_rejects_nonexistent_session_fk | TC-N37 | Validation/FK | 30–39 |
| 27 | test_config_40_rating_scale_relationship_resolves | TC-D07 | Integration | 40–49 |
| 28 | test_config_41_academic_session_relationship_resolves | TC-D08 | Integration | 40–49 |
| 29 | test_config_42_rating_scale_delete_is_restricted_while_referenced | TC-D09 | Integration/FK | 40–49 |
| 30 | test_config_43_soft_deleted_session_unique_collision_data_ba_003 | TC-D10 | Edge (bug) | 40–49 |
| 31 | test_config_50_guest_redirected_to_login_on_create | TC-S01 | Auth | 50–59 |
| 32 | test_config_51_guest_redirected_to_login_on_setup | TC-S02 | Auth | 50–59 |
| 33 | test_config_52_form_request_authorize_returns_true_sec_ba_002 | TC-N40 | Auth (gap) | 50–59 |
| 34 | test_config_53_user_without_permission_is_forbidden | TC-S04 | Auth | 50–59 |
| 35 | test_config_60_setup_tab_lists_created_config | TC-P60 | UI/UX | 60–69 |
| 36 | test_config_61_search_by_scale_filters_list | TC-P61 | UI/UX | 60–69 |
| 37 | test_config_62_trash_page_lists_soft_deleted_config | TC-P62 | UI/UX | 60–69 |
| 38 | test_config_70_weightage_boundary_values_persist | TC-D11 | Edge | 70–79 |
| 39 | test_config_71_weightage_half_step_persists | TC-D12 | Edge | 70–79 |
| 40 | test_config_80_default_scale_binding_is_read_by_service | TC-CFG01 | Config | 80–89 |
| 41 | test_config_81_aggregation_method_drives_overall_score | TC-CFG02 | Config | 80–89 |
| 42 | test_config_82_mid_session_scale_switch_is_not_guarded_data_ba_001 | TC-N41 | Config (bug) | 80–89 |
| 43 | test_config_83_parent_notification_threshold_is_never_consumed_sec_ba_001 | TC-N42 | Config (bug) | 80–89 |
| 44 | test_config_84_weightage_percent_is_not_consumed_by_score_service | TC-N43 | Config (candidate) | 80–89 |
| 45 | test_config_85_screen_only_fields_are_absent_from_schema | TC-N44 | Config (candidate) | 80–89 |
| 46 | test_config_90_runs_inside_initialized_tenant | TC-T01 | Tenancy | 90–99 |
| 47 | test_config_91_invalid_id_does_not_render_detail | TC-S06 | Security | 90–99 |

**Counts:** V1 = 15 methods · V2 = 47 methods · ratio = **3.13×** (≥ 2× gate met).
