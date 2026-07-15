# bha_ Configuration — Test Case List & Business Conditions

**Module:** BehaviouralAssessment · **Feature/Screen:** Configuration (Setup › Configuration tab) · **Screen file:** `07-Configuration*` · **App alias:** `configs`
**Prefix:** `bha_` (registry code BHA) — **live runtime table is `ba_config`** (the `bha_` DDL-doc name is stale → **DOC-BA-001**; filenames keep `bha_` per registry).
**DB scope:** TENANT (`ba_*`, database-per-tenant, no `tenant_id` columns) · **Test style:** Browser Dusk (`extends DuskTestCase`, `Tests\Browser`).
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaConfigController` · **FormRequest:** `Modules\BehaviouralAssessment\Http\Requests\BaConfigRequest` · **Model:** `Modules\BehaviouralAssessment\Models\BaConfig` (SoftDeletes).
**Permission prefix:** `tenant.behavioural-assessment.configs.{viewAny|view|create|update|delete|restore|forceDelete|status}` (+ `tenant.behavioural-assessment.setup.viewAny`).
**Activity log:** NONE — `BaConfigController` calls no `activityLog()` and `BaConfig` has no observer (documented absence, proven in test_93).
**Test file:** `bha_Configuration_TestCas.php` (ONE file, **51 methods**) · **Source read:** live `ba_config` migration, `BaConfigRequest`, `BaConfigController`, `BaConfigPolicy`, `BaConfig` model, config blades (setup/create/edit/show/trash), 07-Configuration.md requirement, BehaviouralAssessment_Complete_Audit_2026-06-29.

---

## 1. Business Conditions

### BC-DB (schema) — Source: live `ba_config` migration / DDL
| ID | Fact | Source |
|----|------|--------|
| BC-DB-01 | Table `ba_config` exists (live `ba_` prefix); DDL-doc name `bha_config` must NOT exist at runtime | DDL / migration (DOC-BA-001) |
| BC-DB-02 | Columns: id, academic_session_id, rating_scale_id, is_result_integration_enabled, weightage_percent, aggregation_method, parent_notification_threshold, is_active, created_by, updated_by, created_at, updated_at, deleted_at | migration |
| BC-DB-03 | `weightage_percent` DECIMAL(4,1); cast decimal → string `'10.0'` | DDL / Model cast |
| BC-DB-04 | `aggregation_method` ENUM(average, weighted_average, separate_display) | DDL |
| BC-DB-05 | `parent_notification_threshold` ENUM(minor, moderate, major, critical) | DDL |
| BC-DB-06 | `is_active` TINYINT(1); cast boolean | DDL / Model |
| BC-DB-07 | `is_result_integration_enabled` TINYINT(1); cast boolean | DDL / Model |
| BC-DB-08 | Unique index `uq_ba_config_session` on `academic_session_id` (UNCONDITIONAL — ignores soft-deletes) | migration `unique('academic_session_id','uq_ba_config_session')` |
| BC-DB-09 | `deleted_at` present (SoftDeletes) | migration `softDeletes()` |
| BC-DB-10 | Model `getTable()` = `ba_config`; fillable = [academic_session_id, rating_scale_id, is_result_integration_enabled, weightage_percent, aggregation_method, parent_notification_threshold, is_active, created_by, updated_by] | Model |
| BC-DB-11 | Model `active()` scope filters `is_active=1`; relations `ratingScale()` & `academicSession()` are BelongsTo | Model |

### BC-REF (FK / onDelete) — Source: information_schema / DDL
| ID | FK | References | onDelete | Source |
|----|-----|-----------|----------|--------|
| BC-REF-01 | `academic_session_id` | `sch_org_academic_sessions_jnt.id` | RESTRICT / NO ACTION | DDL |
| BC-REF-02 | `rating_scale_id` | `ba_rating_scales.id` | RESTRICT / NO ACTION | DDL |

### BC-VAL (validation) — Source: `BaConfigRequest::rules()/messages()`
| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | academic_session_id required, `exists:sch_org_academic_sessions_jnt,id`, `Rule::unique('ba_config','academic_session_id')->whereNull('deleted_at')` | rules |
| BC-VAL-02 | rating_scale_id required, `exists:ba_rating_scales,id` | rules |
| BC-VAL-03 | weightage_percent required, numeric, `min:5`, `max:20` | rules |
| BC-VAL-04 | aggregation_method required, `in:average,weighted_average,separate_display` | rules |
| BC-VAL-05 | parent_notification_threshold required, `in:minor,moderate,major,critical` | rules |
| BC-VAL-06 | Custom message: `A configuration already exists for the selected academic session.` | messages |
| BC-VAL-07 | `prepareForValidation` coerces `is_result_integration_enabled` boolean (omitted → false) and merges `is_active` default true | FormRequest |
| BC-VAL-08 | `authorize()` returns bare `true` (mitigated by controller Gate) → **SEC-BA-002** | FormRequest |

### BC-AUTH (gates/policy) — Source: `BaConfigController` Gate::authorize / `BaConfigPolicy`
| ID | Gate string | Method | Source |
|----|-------------|--------|--------|
| BC-AUTH-01 | tenant.behavioural-assessment.configs.viewAny | index/setup list | Controller/Policy |
| BC-AUTH-02 | tenant.behavioural-assessment.configs.view | show | Controller/Policy |
| BC-AUTH-03 | tenant.behavioural-assessment.configs.create | create/store | Controller/Policy |
| BC-AUTH-04 | tenant.behavioural-assessment.configs.update | edit/update | Controller/Policy |
| BC-AUTH-05 | tenant.behavioural-assessment.configs.delete | destroy | Controller/Policy |
| BC-AUTH-06 | tenant.behavioural-assessment.configs.restore | restore | Controller/Policy |
| BC-AUTH-07 | tenant.behavioural-assessment.configs.forceDelete | forceDelete | Controller/Policy |
| BC-AUTH-08 | tenant.behavioural-assessment.configs.status | toggle-status | Controller/Policy |

### BC-BIZ (business logic / flash) — Source: Controller
| ID | Fact | String | Source |
|----|------|--------|--------|
| BC-BIZ-01 | store() persists, stamps created_by/updated_by, flash success | `Configuration created successfully.` | Controller::store |
| BC-BIZ-02 | update() persists changes, stamps updated_by, flash success | `Configuration updated successfully.` | Controller::update |
| BC-BIZ-03 | destroy() sets is_active=false then soft-deletes, flash | `Configuration moved to trash.` | Controller::destroy |
| BC-BIZ-04 | restore() returns row to default scope, flash | `Configuration restored successfully.` | Controller::restore |
| BC-BIZ-05 | forceDelete() physically removes trashed row, flash | `Configuration permanently deleted.` | Controller::forceDelete |
| BC-BIZ-06 | index() redirects to `setup?tab=configuration` | — | Controller::index |
| BC-BIZ-07 | toggle-status returns JSON `{success, is_active, message}` | `Configuration activated.` / `Configuration deactivated.` | Controller::toggleStatus |
| BC-BIZ-08 | show page renders "Assessment Configuration Details", "Weightage %", "Parent Alert Notification" | — | show.blade |
| BC-BIZ-09 | setup tab lists configs; search placeholder "Search by session or rating scale"; empty state "No configurations found." | — | setup/config blades |
| BC-BIZ-10 | NO activity log written on any config mutation | — | Controller (absence) |

### BC-SM (state machine) — Source: Controller / DATA-BA-001
| ID | State → Trigger → Next | Legal? | Source |
|----|------------------------|--------|--------|
| BC-SM-01 | Active → toggle-status → Inactive | legal | Controller::toggleStatus |
| BC-SM-02 | Inactive → toggle-status → Active | legal | Controller::toggleStatus |
| BC-SM-03 | Scale change, NO ratings for session → accepted | legal | DATA-BA-001 permissive branch |
| BC-SM-04 | Scale change, ratings EXIST for session → rejected (guard + `@disabled` lock) | illegal | DATA-BA-001 fix (update guard + edit.blade) |

### BC-INT / BC-EDG / BC-CFG — Source: cross-layer scan / requirement
| ID | Fact | Source |
|----|------|--------|
| BC-INT-01 | Depends on `sch_org_academic_sessions_jnt` (session picker + RESTRICT FK) | DDL / rules |
| BC-INT-02 | Depends on `ba_rating_scales` (scale picker + RESTRICT FK) | DDL / rules |
| BC-INT-03 | DATA-BA-001 guard reads `ba_assessment_ratings`→`ba_assessments`→`ba_assessment_periods` chain | Controller::update |
| BC-EDG-01 | Weightage boundaries 5 and 20 accepted; 4/21 rejected | rules |
| BC-EDG-02 | Invalid id → 404 on show/edit/toggle | route-model binding |
| BC-EDG-03 | **DATA-BA-003:** unique index unconditional vs FormRequest `whereNull(deleted_at)` — a soft-deleted session cannot be cleanly reused | migration vs FormRequest |
| BC-CFG-01 | parent_notification_threshold persists all 4 enum values but is **dead config** — never read to dispatch a notification → **SEC-BA-001** | Controller/Service scan |
| BC-CFG-02 | Requirement fields (Approval Workflow, Incident Escalation Threshold, Notification Settings) NOT implemented; actual fields are weightage_percent/aggregation_method/parent_notification_threshold/is_result_integration_enabled → **CFG-BA-001** | 07-Configuration.md vs schema |
| BC-CFG-03 | is_result_integration_enabled toggle + aggregation_method persist | Model |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|-----|--------|-------------|----------|--------|--------|
| TC-P01 | Schema | BC-DB-01..11 | DDL/Model | Migration/model/request config truth | All asserts pass | test_01 | ✅ |
| TC-P02 | Schema | BC-DB-01 | DDL (DOC-BA-001) | Runtime uses `ba_config`, `bha_config` absent | ba_ present, bha_ absent | test_02 | ✅ |
| TC-P03 | Schema | BC-VAL-01..06 | FormRequest | Rule/message strings present in source | strings found | test_03 | ✅ |
| TC-P04 | Biz | BC-BIZ-01 | store | Create persists + stamps + not 422 | row created, created_by set | test_10 | ✅ |
| TC-P05 | Biz | BC-BIZ-02 | update | Update persists changes | weightage/method/threshold changed | test_11 | ✅ |
| TC-P06 | Biz | BC-DB-03/06/07 | Model | weightage + boolean casts | '7.5', true, false | test_12 | ✅ |
| TC-P07 | Biz | BC-BIZ-08 | show.blade | Show page renders details | labels present | test_13 | ✅ |
| TC-P08 | Biz | BC-BIZ-09 | setup.blade | Setup tab lists configs | headers present | test_14 | ✅ |
| TC-P09 | Biz | BC-BIZ-06 | index | index redirects to setup tab | 200/302 | test_15 | ✅ |
| TC-P10 | SM | BC-SM-01/02 | toggleStatus | Active↔Inactive round-trip | flips both ways | test_20 | ✅ |
| TC-P11 | SM | BC-SM-03 | DATA-BA-001 | Scale change allowed, no ratings | scale changes | test_21 | ✅ |
| TC-P12 | SM | BC-SM-04 | DATA-BA-001 | Guard + `@disabled` lock present in source | strings found | test_22 | ✅ |
| TC-P13 | Auth | BC-AUTH-08 | toggleStatus | Toggle JSON messages | activated/deactivated | test_55 | ✅ |
| TC-P14 | Edge | BC-EDG-01 | rules | Weightage boundaries 5 & 20 accepted | not 422 | test_71 | ✅ |
| TC-P15 | Edge | BC-VAL-07 | prepareForValidation | is_active defaults true when omitted | true | test_72 | ✅ |
| TC-P16 | CFG | BC-CFG-01 | Model | parent_notification_threshold persists all values | minor/moderate/major/critical | test_80 | ✅ |
| TC-P17 | CFG | BC-CFG-03 | Model | result-integration toggle + aggregation persist | true/separate_display/18.0 | test_83 | ✅ |
| TC-P18 | UI/UX | BC-BIZ-09 | setup.blade | Search input renders + accepts query | placeholder present | test_60 | ✅ |
| TC-P19 | UI/UX | BC-DB-09 | trash.blade | Trash page renders | headers present | test_62 | ✅ |
| TC-P20 | UI/UX | BC-BIZ-08 | breadcrumb | Breadcrumb on create + show | "Configuration" text | test_63 | ✅ |
| TC-P21 | Dep | BC-BIZ-03/04/05 | lifecycle | create→toggle→delete→restore→forceDelete | all stages pass | test_46 | ✅ |
| TC-P22 | Dep | BC-BIZ-04 | restore | Restore returns to default scope | present | test_41 | ✅ |

### Negative (TC-N)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|-----|--------|-------------|----------|--------|--------|
| TC-N01 | Validation | BC-VAL-01..05 | rules | Empty payload — all required errors | 422 ×5 | test_30 | ✅ |
| TC-N02 | Validation | BC-VAL-03 | rules | weightage < min 5 | 422 | test_31 | ✅ |
| TC-N03 | Validation | BC-VAL-03 | rules | weightage > max 20 | 422 | test_32 | ✅ |
| TC-N04 | Validation | BC-VAL-03 | rules | weightage non-numeric | 422 | test_33 | ✅ |
| TC-N05 | Validation | BC-VAL-04 | rules | aggregation_method outside set | 422 | test_34 | ✅ |
| TC-N06 | Validation | BC-VAL-05 | rules | parent_notification_threshold outside set | 422 | test_35 | ✅ |
| TC-N07 | Validation | BC-VAL-01 | rules | academic_session must exist | 422 | test_36 | ✅ |
| TC-N08 | Validation | BC-VAL-02 | rules | rating_scale must exist | 422 | test_37 | ✅ |
| TC-N09 | Validation | BC-VAL-01/06 | rules | Duplicate config for session rejected | 422 + custom msg | test_38 | ✅ |
| TC-N10 | Validation | BC-VAL-07 | prepareForValidation | Omitted toggle coerces to false | false | test_39 | ✅ |
| TC-N11 | Edge | BC-EDG-02 | binding | Invalid id → 404 (show/edit/toggle) | 404 ×3 | test_70 | ✅ |
| TC-N12 | Auth | BC-AUTH | guest | Guest redirected to /login | /login | test_50 | ✅ |
| TC-N13 | Auth | BC-AUTH-03 | store | Limited user w/o create → 403 | 403 | test_51 | ✅ |
| TC-N14 | Auth | BC-AUTH-08 | toggle | Limited user w/o status → 403 | 403 | test_52 | ✅ |
| TC-N15 | Auth | BC-AUTH-05 | destroy | Limited user w/o delete → 403 | 403 | test_53 | ✅ |
| TC-N16 | UI/UX | BC-BIZ-09 | setup.blade | Empty-state message on no match | "No configurations found." | test_61 | ✅ |
| TC-N17 | SM | BC-SM-04 | DATA-BA-001 | Scale change rejected when ratings exist | scale unchanged (defensive) | test_23 | ✅ |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|-----|--------|-------------|----------|--------|--------|
| TC-D01 | F | BC-BIZ-03 | destroy | Soft delete sets inactive + moves to trash | onlyTrashed, is_active false | test_40 | ✅ |
| TC-D02 | F | BC-BIZ-04 | restore | Restore returns to default scope | present | test_41 | ✅ |
| TC-D03 | F | BC-BIZ-05 | forceDelete | Force delete removes row | withTrashed absent | test_42 | ✅ |
| TC-D04 | D | BC-REF-01 | DDL | academic_session FK is RESTRICT | RESTRICT/NO ACTION | test_43 | ✅ (defensive) |
| TC-D05 | D | BC-REF-02 | DDL | rating_scale FK is RESTRICT | RESTRICT/NO ACTION | test_44 | ✅ (defensive) |
| TC-D06 | G | BC-EDG-03 | DATA-BA-003 | Soft-deleted session not cleanly reusable | insert blocked by unique index | test_45 | ✅ (defensive) |
| TC-D07 | F | BC-BIZ-01..05 | lifecycle | Full lifecycle chain | all stages | test_46 | ✅ |
| TC-D08 | E | BC-INT-03 | DATA-BA-001 | ratings-chain probe (permissive/blocking) | branch resolved | test_21/23 | ✅ (defensive) |

### Tenancy / Security (TC-T / TC-S)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|-----|--------|-------------|----------|--------|--------|
| TC-T01 | Tenancy | BC-DB | tenancy | Tenant context initialized; no tenant_id column | initialized, no tenant_id | test_90 | ✅ |
| TC-T02 | Tenancy | BC-DB | tenancy | Cross-tenant isolation defensive | second tenant asserted | test_91 | ✅ (defensive) |
| TC-S01 | Security | BC-VAL-08 | FormRequest | authorize() returns bare true (SEC-BA-002) | regex match | test_92 | ✅ |
| TC-S02 | Security | BC-CFG-01 | scan | Severe-incident parent notification not wired (SEC-BA-001) | no notify/mail dispatch | test_81 | ✅ |
| TC-S03 | Security | BC-AUTH-01..08 | Policy | Policy methods map to permission strings | 8 gate strings found | test_54 | ✅ |
| TC-S04 | Config | BC-CFG-02 | requirement | Requirement fields NOT implemented (CFG-BA-001) | absent cols; actual cols present | test_82 | ✅ |
| TC-S05 | Audit | BC-BIZ-10 | Controller | No activity log written on mutation | no activityLog()/ActivityLog::create | test_93 | ✅ |

---

## 3. Test Method Index (bands)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_configuration_01_migration_model_and_request_configuration_are_correct | TC-P01 | Schema | 01 |
| 2 | test_configuration_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001 | TC-P02 | Schema/DOC-BA-001 | 02 |
| 3 | test_configuration_03_form_request_rules_and_messages_are_correct | TC-P03 | Schema | 03 |
| 4 | test_configuration_10_create_persists_and_redirects_with_success_flash | TC-P04 | Biz | 10 |
| 5 | test_configuration_11_update_persists_changes | TC-P05 | Biz | 11 |
| 6 | test_configuration_12_weightage_and_boolean_flags_cast_correctly | TC-P06 | Biz | 12 |
| 7 | test_configuration_13_show_page_renders_config_details | TC-P07 | Biz | 13 |
| 8 | test_configuration_14_setup_tab_lists_configs | TC-P08 | Biz | 14 |
| 9 | test_configuration_15_index_redirects_to_setup_configuration_tab | TC-P09 | Biz | 15 |
| 10 | test_configuration_20_active_to_inactive_and_back_transition_succeeds | TC-P10 | SM | 20 |
| 11 | test_configuration_21_rating_scale_change_allowed_when_no_ratings_exist | TC-P11/TC-D08 | SM/DATA-BA-001 | 21 |
| 12 | test_configuration_22_scale_lock_guard_present_in_controller_and_view_data_ba_001 | TC-P12 | SM/DATA-BA-001 | 22 |
| 13 | test_configuration_23_rating_scale_change_rejected_when_ratings_exist_data_ba_001 | TC-N17/TC-D08 | SM/DATA-BA-001 | 23 |
| 14 | test_configuration_30_required_fields_are_rejected | TC-N01 | Validation | 30 |
| 15 | test_configuration_31_weightage_below_min_5_is_rejected | TC-N02 | Validation | 31 |
| 16 | test_configuration_32_weightage_above_max_20_is_rejected | TC-N03 | Validation | 32 |
| 17 | test_configuration_33_weightage_must_be_numeric | TC-N04 | Validation | 33 |
| 18 | test_configuration_34_aggregation_method_must_be_in_allowed_set | TC-N05 | Validation | 34 |
| 19 | test_configuration_35_parent_notification_threshold_must_be_in_allowed_set | TC-N06 | Validation | 35 |
| 20 | test_configuration_36_academic_session_must_exist | TC-N07 | Validation | 36 |
| 21 | test_configuration_37_rating_scale_must_exist | TC-N08 | Validation | 37 |
| 22 | test_configuration_38_duplicate_config_for_session_is_rejected | TC-N09 | Validation | 38 |
| 23 | test_configuration_39_is_result_integration_defaults_and_coerces_boolean | TC-N10 | Validation | 39 |
| 24 | test_configuration_40_delete_soft_deletes_sets_inactive_and_moves_to_trash | TC-D01 | Integration | 40 |
| 25 | test_configuration_41_restore_from_trash_returns_config_to_default_scope | TC-P22/TC-D02 | Integration | 41 |
| 26 | test_configuration_42_force_delete_removes_config_row | TC-D03 | Integration | 42 |
| 27 | test_configuration_43_academic_session_fk_is_restrict | TC-D04 | Integration | 43 |
| 28 | test_configuration_44_rating_scale_fk_is_restrict | TC-D05 | Integration | 44 |
| 29 | test_configuration_45_soft_deleted_session_cannot_be_cleanly_reused_data_ba_003 | TC-D06 | Integration/DATA-BA-003 | 45 |
| 30 | test_configuration_46_full_lifecycle_create_toggle_delete_restore_force_delete | TC-P21/TC-D07 | Lifecycle | 46 |
| 31 | test_configuration_50_guest_is_redirected_to_login | TC-N12 | Permissions | 50 |
| 32 | test_configuration_51_limited_user_without_create_permission_gets_403 | TC-N13 | Permissions | 51 |
| 33 | test_configuration_52_limited_user_without_status_permission_gets_403_on_toggle | TC-N14 | Permissions | 52 |
| 34 | test_configuration_53_limited_user_without_delete_permission_gets_403_on_destroy | TC-N15 | Permissions | 53 |
| 35 | test_configuration_54_policy_methods_map_to_permission_strings | TC-S03 | Permissions | 54 |
| 36 | test_configuration_55_status_toggle_endpoint_returns_json_messages | TC-P13 | Permissions | 55 |
| 37 | test_configuration_60_setup_search_renders_and_accepts_query | TC-P18 | UI/UX | 60 |
| 38 | test_configuration_61_empty_state_message_when_no_configs_match | TC-N16 | UI/UX | 61 |
| 39 | test_configuration_62_trash_page_renders | TC-P19 | UI/UX | 62 |
| 40 | test_configuration_63_breadcrumb_present_on_create_and_show_pages | TC-P20 | UI/UX | 63 |
| 41 | test_configuration_70_invalid_id_returns_404 | TC-N11 | Edge | 70 |
| 42 | test_configuration_71_weightage_boundaries_5_and_20_are_accepted | TC-P14 | Edge | 71 |
| 43 | test_configuration_72_is_active_defaults_true_when_omitted | TC-P15 | Edge | 72 |
| 44 | test_configuration_80_parent_notification_threshold_persists_all_values | TC-P16 | Config | 80 |
| 45 | test_configuration_81_severe_incident_parent_notification_not_wired_sec_ba_001 | TC-S02 | Config/SEC-BA-001 | 81 |
| 46 | test_configuration_82_requirement_fields_are_not_implemented_cfg_ba_001 | TC-S04 | Config/CFG-BA-001 | 82 |
| 47 | test_configuration_83_result_integration_toggle_and_aggregation_persist | TC-P17 | Config | 83 |
| 48 | test_configuration_90_tenant_context_is_initialized_and_table_is_tenant_scoped | TC-T01 | Tenancy | 90 |
| 49 | test_configuration_91_cross_tenant_isolation_is_defensive | TC-T02 | Tenancy | 91 |
| 50 | test_configuration_92_form_request_authorize_returns_true_sec_ba_002 | TC-S01 | Security/SEC-BA-002 | 92 |
| 51 | test_configuration_93_no_activity_log_is_written_on_config_mutation | TC-S05 | Audit | 93 |

**Total: 51 methods.**

---

## 4. Known Source Defects / Findings (audit-equivalent BUG/BA IDs)

| ID | Severity | Description | Status | Proving test |
|----|----------|-------------|--------|--------------|
| DOC-BA-001 | Low | DDL/registry doc names the table `bha_config`; live runtime table is `ba_config`. Code (model) binds to `ba_config` — doc is stale. | Documented | test_02 |
| DATA-BA-001 | High (fixed) | "Active rating scale switchable mid-session." Audit (2026-06-29) flagged the guard MISSING; current source implements the canonical fix — server-side guard in `update()` + `@disabled($hasRatings)` in edit.blade. Suite proves the fix is now PRESENT. | RESOLVED (verified) | test_21, test_22, test_23 |
| DATA-BA-003 | Medium | DB unique index `uq_ba_config_session` is unconditional (ignores soft-deletes) while the FormRequest unique rule is scoped `whereNull(deleted_at)` — a soft-deleted session cannot be cleanly reused (FormRequest passes, DB INSERT blocked). | Documented | test_45 |
| SEC-BA-001 | High | Severe-incident parent notification entirely absent. `parent_notification_threshold` is configured here but is **dead config** — no controller/service reads it to dispatch a notification. | UNRESOLVED | test_80, test_81 |
| SEC-BA-002 | Low | `BaConfigRequest::authorize()` returns bare `true` (mitigated by the controller Gate::authorize). | Documented | test_92 |
| CFG-BA-001 | Info | Requirement's "Approval Workflow", "Incident Escalation Threshold", "Notification Settings" fields are NOT implemented; `ba_config` instead exposes weightage_percent / aggregation_method / parent_notification_threshold / is_result_integration_enabled. | Documented | test_82 |
