# Rating Scales — Test Case List & Business Conditions (`bha_RatingScaleTcList_Require`)

**Module:** BehaviouralAssessment · **Feature/Screen:** RatingScale (`02-Rating-Scales.md`)
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaRatingScaleController`
**FormRequest:** `Modules\BehaviouralAssessment\Http\Requests\BaRatingScaleRequest`
**Models:** `BaRatingScale`, `BaRatingLevel`
**Primary tables (RUNTIME, live):** `ba_rating_scales`, `ba_rating_levels`
**DDL spec tables (stale doc):** `bha_rating_scales`, `bha_rating_levels` — see **DOC-BA-001**
**DB scope:** TENANT-side (database-per-tenant; no `tenant_id` columns) → tenancy init required.
**Permission prefix:** `tenant.behavioural-assessment.rating-scales.{viewAny|view|create|update|delete|restore|forceDelete|status}`
**Activity log:** NONE — controller invokes no `activityLog()` helper and the model has no observer (documented absence, not a gap in this screen's scope).
**Test file:** `bha_RatingScale_TestCas.php` (single comprehensive Dusk suite — 49 methods).

> **Prefix decision (authoritative for this run):** filenames keep the caller-mandated `bha_` prefix (module registry `BHA`/`bha_`), but **all runtime assertions target the live `ba_` tables** — the migrations, both Eloquent `$table` bindings, and the FormRequest `Rule::unique('ba_rating_scales', ...)` all use `ba_`; only the DDL doc uses `bha_`. Audit **DOC-BA-001** explicitly resolves this: *"code wins, prefix is `ba_`."*

---

## 1. Business Conditions

### BC-DB — Schema / column / constraint truth (Source: `DDL-ba_rating_scales`, migrations)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_rating_scales` exists with `id,code,name,description,grade_type,min_rating,max_rating,is_default,is_active,created_by,updated_by,created_at,updated_at,deleted_at` | DDL-ba_rating_scales |
| BC-DB-02 | `code` VARCHAR(30) NOT NULL | migration `create_ba_rating_scales` |
| BC-DB-03 | `name` VARCHAR(100) NOT NULL | migration |
| BC-DB-04 | `min_rating`/`max_rating` DECIMAL(3,1) NOT NULL | migration |
| BC-DB-05 | `is_default`/`is_active` boolean (tinyint(1)), defaults 0/1 | migration |
| BC-DB-06 | `ba_rating_scales` uses `softDeletes()` (`deleted_at`) | migration |
| BC-DB-07 | `ba_rating_levels` exists with `id,rating_scale_id,label,numeric_value,description,sort_order,is_active,...,deleted_at` | DDL-ba_rating_levels |
| BC-DB-08 | `ba_rating_levels` UNIQUE (`rating_scale_id`,`sort_order`) = `uq_ba_level` | migration |
| BC-DB-09 | `ba_rating_levels.rating_scale_id` FK → `ba_rating_scales` **ON DELETE CASCADE** | migration `constrained('ba_rating_scales')->cascadeOnDelete()` |

### BC-VAL — Validation rules + messages (Source: `BaRatingScaleRequest`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `code` required, string, max:30, unique in `ba_rating_scales` scoped `whereNull(deleted_at)`, ignoring current id | Screen-VR-2 · Request `rules()` |
| BC-VAL-02 | `name` required, string, max:100 | Screen-VR-1 · Request |
| BC-VAL-03 | `description` nullable, string | Request |
| BC-VAL-04 | `grade_type` required, `in:letter,numeric,descriptive` | Request `Rule::in` |
| BC-VAL-05 | `min_rating` required, numeric, min:0 | Request |
| BC-VAL-06 | `max_rating` required, numeric, `gt:min_rating` | Request |
| BC-VAL-07 | `is_default`/`is_active` nullable boolean; `prepareForValidation` casts booleans, defaults `is_active`=true | Request `prepareForValidation` |
| BC-VAL-08 | `code` uppercased via `strtoupper()` in `prepareForValidation` | Request |
| BC-VAL-09 | Level endpoint: `label` required max:50, `numeric_value` required numeric, `sort_order` nullable int min:0 | Controller `storeLevel`/`updateLevel` inline validate |

### BC-AUTH — Permission gate ↔ controller method (Source: `Screen-PM`, Controller `Gate::authorize`, Policy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `index`/`trashed` require `...rating-scales.viewAny` | Controller:21,87 |
| BC-AUTH-02 | `create`/`store` require `...rating-scales.create` | Controller:27,33 |
| BC-AUTH-03 | `show` requires `...rating-scales.view` | Controller:46 |
| BC-AUTH-04 | `edit`/`update` + level endpoints require `...rating-scales.update` | Controller:54,62,134,158,178 |
| BC-AUTH-05 | `destroy` requires `...rating-scales.delete` | Controller:73 |
| BC-AUTH-06 | `restore` requires `...rating-scales.restore` | Controller:97 |
| BC-AUTH-07 | `forceDelete` requires `...rating-scales.forceDelete` | Controller:108 |
| BC-AUTH-08 | `toggleStatus` requires `...rating-scales.status` | Controller:119 |
| BC-AUTH-09 | Policy `BaRatingScalePolicy` maps all 8 abilities to matching permission strings | Policy |
| BC-AUTH-10 | **SEC-BA-002:** `BaRatingScaleRequest::authorize()` returns bare `true` (mitigated by controller Gate) | Audit SEC-BA-002 · Request:12 |

### BC-BIZ — Business logic / auto-behaviour (Source: `Screen-BR`, Controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `store` persists row + sets `created_by`/`updated_by`=auth id, redirects to masters tab with flash `Rating scale created successfully.` | Controller:31-42 |
| BC-BIZ-02 | `update` persists changes + sets `updated_by`, flash `Rating scale updated successfully.` | Controller:60-69 |
| BC-BIZ-03 | `destroy` sets `is_active=false` then soft-deletes; flash `Rating scale moved to trash.` | Controller:71-83 |
| BC-BIZ-04 | `restore` un-trashes; flash `Rating scale restored successfully.` | Controller:95-104 |
| BC-BIZ-05 | `forceDelete` permanently removes; flash `Rating scale permanently deleted.` | Controller:106-115 |
| BC-BIZ-06 | `toggleStatus` flips `is_active`, returns JSON `{success,is_active,message}` with `Rating scale activated./deactivated.` | Controller:117-130 |
| BC-BIZ-07 | Level nested endpoints create/update/soft-delete `ba_rating_levels` rows | Controller:132-182 |
| BC-BIZ-08 | Masters tab lists scales + `levels_count`; search by name/code; 15/page | Blade `_rating-scales`, Controller `trashed` paginate(15) |
| BC-BIZ-09 | **BUG-BA-009:** BR-BA-028 (one default) not enforced — multiple `is_default=true` scales coexist | Audit BUG-BA-009 |
| BC-BIZ-10 | **VAL-BA-002:** BR-BA-003 level `numeric_value` not range-checked against `[min,max]` | Audit VAL-BA-002 |

### BC-SM — State machine (Active ↔ Inactive) (Source: `Screen-BR` Active Status Constraints, `toggleStatus`)
| ID | State → Trigger → Next | Legal? | Source |
|----|------------------------|--------|--------|
| BC-SM-01 | Active → toggleStatus → Inactive | Legal | Controller `toggleStatus` |
| BC-SM-02 | Inactive → toggleStatus → Active | Legal | Controller `toggleStatus` |
| BC-SM-03 | Active(referenced in Config/active period) → toggleStatus → Inactive | **Should be illegal**, but ALLOWED | Screen-BR "Active Status Constraints" · **DATA-BA-001** (BR-BA-029) |

### BC-REF — FK column → referenced table → onDelete (Source: DDL/migrations)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `ba_rating_levels.rating_scale_id` → `ba_rating_scales` **CASCADE** | migration |
| BC-REF-02 | `ba_config.rating_scale_id` → `ba_rating_scales` **RESTRICT** (Laravel default; DDL `ON DELETE RESTRICT`) | migration `constrained('ba_rating_scales')` · DDL:604 |
| BC-REF-03 | `ba_assessment_ratings.rating_level_id` → `ba_rating_levels` **SET NULL** | migration `nullOnDelete()` · DDL:842 |

### BC-INT — Integration points (cross-module / cross-screen) (Source: `Screen-IP`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Configuration screen (`ba_config`) selects a scale; a linked scale must not deactivate (see BC-SM-03) | Screen-IP `07-Configuration.md` |
| BC-INT-02 | Ratings screen (`ba_assessment_ratings`) references levels; deleting a scale/level impacts historical ratings | Screen-IP `09-Ratings.md` |

### BC-EDG — Edge cases / boundaries (Source: Screen + DDL limits)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `code` up to 30 chars accepted although the requirement text says "max 10" → **RS-GAP-01** | Screen-BR "Scale Code max 10" vs Request max:30 |
| BC-EDG-02 | `max_rating == min_rating` rejected (`gt`, not `gte`) | Request |
| BC-EDG-03 | Whitespace-only `name` rejected (TrimStrings → required fails) | Laravel middleware |
| BC-EDG-04 | Invalid id → 404 on show/edit/toggle | route-model / `findOrFail` |
| BC-EDG-05 | Requirement blocks deleting a referenced scale; controller soft-deletes unconditionally → **RS-GAP-02** | Screen-BR "Soft Delete Protection" vs Controller `destroy` |
| BC-EDG-06 | `grade_type='descriptive'` is a valid Request value but the create/edit UI offers only letter/numeric → **RS-GAP-03** | Request `Rule::in` vs `create.blade.php` |

### BC-CFG — Configuration divergence (Source: DDL vs runtime)
| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | **DOC-BA-001:** DDL doc uses `bha_` prefix; live schema/models/request use `ba_` | Audit DOC-BA-001 |

---

## 2. Test Case List

### Positive (`TC-P`)
| TC ID | Cat | BC | Source | Description | Expected Result | Test Method | Status |
|-------|-----|----|--------|-------------|-----------------|-------------|--------|
| TC-P01 | Schema | BC-DB-01..06,BC-VAL-* | DDL/Request | Scale schema + model + request config truth | Table/columns/fillable/softdelete/scope correct | `test_rating_scale_01_*` | ✅ |
| TC-P02 | Schema | BC-CFG-01 | Audit DOC-BA-001 | Runtime prefix is `ba_`, doc `bha_` absent | `ba_*` exist; `bha_*` absent; model binds `ba_` | `test_rating_scale_02_*` | ✅ |
| TC-P03 | Schema | BC-DB-07..09,BC-REF-01 | DDL/migration | Levels table + FK + unique config | Columns/unique/cascade/model correct | `test_rating_scale_03_*` | ✅ |
| TC-P04 | Create | BC-BIZ-01 | Controller | Create persists + redirect + flash | Row created, is_active true, created_by set | `test_rating_scale_10_*` | ✅ |
| TC-P05 | Create | BC-VAL-08 | Request | Lowercase code uppercased | Stored code uppercase | `test_rating_scale_11_*` | ✅ |
| TC-P06 | Update | BC-BIZ-02 | Controller | Update persists changes + updated_by | Name/grade_type updated | `test_rating_scale_12_*` | ✅ |
| TC-P07 | Levels | BC-BIZ-07 | Controller | Store level nested endpoint | Level row created | `test_rating_scale_14_*` | ✅ |
| TC-P08 | Levels | BC-BIZ-07 | Controller | Update + delete level endpoints | Level updated then soft-deleted | `test_rating_scale_15_*` | ✅ |
| TC-P09 | View | BC-BIZ-08 | Blade show | Show page renders scale + levels | Name/level/"Scale Identity" visible | `test_rating_scale_16_*` | ✅ |
| TC-P10 | List | BC-BIZ-08 | Blade masters | Masters tab lists scales + levels count | Code visible in list | `test_rating_scale_17_*` | ✅ |
| TC-P11 | SM | BC-SM-01,02 | Controller | Active↔Inactive legal transitions | Both toggles succeed | `test_rating_scale_20_*` | ✅ |
| TC-P12 | Lifecycle | BC-BIZ-01..06,BC-REF-01 | Controller | Full create→toggle→delete→restore→forceDelete | Each step observable in DB | `test_rating_scale_46_*` | ✅ |
| TC-P13 | Status | BC-BIZ-06 | Controller | Toggle endpoint JSON + message | 200 JSON, correct messages | `test_rating_scale_55_*` | ✅ |
| TC-P14 | UI | BC-BIZ-08 | Blade | Masters search filters by name/code | Match shown | `test_rating_scale_60_*` | ✅ |
| TC-P15 | UI | BC-BIZ-08 | Blade | Trash page renders | Trashed code visible | `test_rating_scale_62_*` | ✅ |
| TC-P16 | UI | BC-BIZ-08 | Blade | Breadcrumb on create + show | "Rating Scales" visible | `test_rating_scale_63_*` | ✅ |
| TC-P17 | Tenancy | — | Constraint A | Tenant context initialized | tenancy()->initialized true | `test_rating_scale_90_*` | ✅ |

### Negative (`TC-N`)
| TC ID | Cat | BC | Source | Description | Expected Result | Test Method | Status |
|-------|-----|----|--------|-------------|-----------------|-------------|--------|
| TC-N01 | Required | BC-VAL-01,02,04,05,06 | Request | Empty payload | 422; errors for code,name,grade_type,min,max | `test_rating_scale_30_*` | ✅ |
| TC-N02 | Length | BC-VAL-01 | Request | code > 30 chars | 422 code error | `test_rating_scale_31_*` | ✅ |
| TC-N03 | Length | BC-VAL-02 | Request | name > 100 chars | 422 name error | `test_rating_scale_32_*` | ✅ |
| TC-N04 | Enum | BC-VAL-04 | Request | grade_type not in set | 422 grade_type error | `test_rating_scale_33_*` | ✅ |
| TC-N05 | Range | BC-VAL-05 | Request | min_rating negative / non-numeric | 422 min_rating error | `test_rating_scale_34_*` | ✅ |
| TC-N06 | Cross-field | BC-VAL-06 | Request | max_rating ≤ min_rating | 422 max_rating error | `test_rating_scale_35_*` | ✅ |
| TC-N07 | Duplicate | BC-VAL-01 | Request | Duplicate active code | 422 code error | `test_rating_scale_36_*` | ✅ |
| TC-N08 | Duplicate | BC-VAL-01 | Request | Reuse code after soft-delete | Allowed (scoped unique) | `test_rating_scale_37_*` | ✅ |
| TC-N09 | XSS | BC-EDG | Security | `<script>` in name | Escaped on show | `test_rating_scale_38_*` | ✅ |
| TC-N10 | Level Range | BC-BIZ-10 | Audit VAL-BA-002 | Out-of-range level accepted (defect) | Persists (proves VAL-BA-002); empty label 422 | `test_rating_scale_39_*` | ✅ |
| TC-N11 | Edge | BC-EDG-04 | route | Invalid id 404 on show/edit/toggle | 404 | `test_rating_scale_70_*` | ✅ |
| TC-N12 | Boundary | BC-EDG-02 | Request | max == min rejected | 422 max_rating | `test_rating_scale_72_*` | ✅ |
| TC-N13 | Whitespace | BC-EDG-03 | middleware | Whitespace-only name | 422 name error | `test_rating_scale_73_*` | ✅ |
| TC-N14 | AuthZ | BC-AUTH-02 | Gate | Guest redirected to /login | Redirect to login | `test_rating_scale_50_*` | ✅ |
| TC-N15 | AuthZ | BC-AUTH-02 | Gate | Limited user create → 403 | 403 | `test_rating_scale_51_*` | ✅ |
| TC-N16 | AuthZ | BC-AUTH-08 | Gate | Limited user toggle → 403 | 403 | `test_rating_scale_52_*` | ✅ |
| TC-N17 | AuthZ | BC-AUTH-05 | Gate | Limited user destroy → 403 | 403 | `test_rating_scale_53_*` | ✅ |
| TC-N18 | UI | BC-BIZ-08 | Blade | Empty-state message | "No rating scales found." | `test_rating_scale_61_*` | ✅ |
| TC-N19 | Security | BC-AUTH-10 | Audit SEC-BA-002 | authorize() bare true | Regex confirms `return true;` | `test_rating_scale_92_*` | ✅ |
| TC-N20 | Security | BC-EDG | Security | Stored XSS in description | Escaped on show | `test_rating_scale_93_*` | ✅ |

### Dependency (`TC-D`, sub-cat A–G)
| TC ID | Cat | BC | Source | Description | Expected Result | Test Method | Status |
|-------|-----|----|--------|-------------|-----------------|-------------|--------|
| TC-D01 (B) | Soft-delete | BC-BIZ-03 | Controller | Delete soft-deletes + sets inactive + trash | Hidden from default, in trash, inactive | `test_rating_scale_40_*` | ✅ |
| TC-D02 (B) | Restore | BC-BIZ-04 | Controller | Restore reactivates visibility | Back in default scope | `test_rating_scale_41_*` | ✅ |
| TC-D03 (B) | Cascade | BC-REF-01 | migration | Force-delete cascades levels | Scale + levels physically gone | `test_rating_scale_42_*` | ✅ |
| TC-D04 (D) | SET NULL | BC-REF-03 | migration | Force-delete level nulls ratings FK | rating_level_id nulled (or FK rule asserted) | `test_rating_scale_43_*` | ✅ |
| TC-D05 (C) | RESTRICT | BC-REF-02 | migration | Config ref restricts hard-delete | FK DELETE_RULE RESTRICT/NO ACTION | `test_rating_scale_44_*` | ✅ |
| TC-D06 (E) | Cross-module | BC-EDG-05 | Screen vs Controller | Soft-delete not blocked when referenced (RS-GAP-02) | Soft delete succeeds unconditionally | `test_rating_scale_45_*` | ✅ |
| TC-D07 (F) | Lifecycle | BC-BIZ-* | Controller | Full lifecycle | All transitions verified | `test_rating_scale_46_*` | ✅ |
| TC-D08 (E) | Cross-module | BC-SM-03 | Audit DATA-BA-001 | Deactivating a referenced scale not blocked | Toggle succeeds (proves DATA-BA-001) | `test_rating_scale_21_*` | ✅ |
| TC-D09 (G) | Isolation | BC-INT | Constraint A | Cross-tenant direct-id isolation | Second tenant isolated (defensive skip) | `test_rating_scale_91_*` | ✅ |

### Coverage-mapped defect proofs (`TC-X` — audit/discovered defects)
| TC ID | Defect | Sev | Description | Test Method | Status |
|-------|--------|-----|-------------|-------------|--------|
| TC-X01 | DOC-BA-001 | Doc | DDL `bha_` vs live `ba_` prefix | `test_rating_scale_02_*` | ✅ Proven |
| TC-X02 | BUG-BA-009 | P2 | Multiple default scales (BR-BA-028) | `test_rating_scale_13_*` | ✅ Proven |
| TC-X03 | VAL-BA-002 | P2 | Level value not range-checked (BR-BA-003) | `test_rating_scale_39_*` | ✅ Proven |
| TC-X04 | SEC-BA-002 | P1 | FormRequest authorize() bare true (D30) | `test_rating_scale_92_*` | ✅ Proven |
| TC-X05 | DATA-BA-001 | P1 | Referenced scale deactivation not blocked (BR-BA-029) | `test_rating_scale_21_*` | ✅ Proven (RatingScale-side; canonical fix at `BaConfigController`) |
| TC-X06 | RS-GAP-01 | Obs | Requirement code max 10 vs impl max 30 | `test_rating_scale_71_*` | ✅ Proven |
| TC-X07 | RS-GAP-02 | Obs | Referenced scale soft-delete not blocked | `test_rating_scale_45_*` | ✅ Proven |
| TC-X08 | RS-GAP-03 | Obs | `descriptive` valid but no UI option | `test_rating_scale_18_*` | ✅ Proven |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_rating_scale_01_migration_model_and_request_configuration_are_correct` | TC-P01 | Schema | 01–09 |
| 2 | `test_rating_scale_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001` | TC-P02/TC-X01 | Schema/Defect | 01–09 |
| 3 | `test_rating_scale_03_rating_levels_table_and_model_configuration_are_correct` | TC-P03 | Schema | 01–09 |
| 4 | `test_rating_scale_10_create_persists_and_redirects_with_success_flash` | TC-P04 | Biz | 10–19 |
| 5 | `test_rating_scale_11_code_is_uppercased_by_prepare_for_validation` | TC-P05 | Biz | 10–19 |
| 6 | `test_rating_scale_12_update_persists_changes` | TC-P06 | Biz | 10–19 |
| 7 | `test_rating_scale_13_multiple_scales_can_be_default_bug_ba_009` | TC-X02 | Biz/Defect | 10–19 |
| 8 | `test_rating_scale_14_store_level_via_nested_endpoint_persists` | TC-P07 | Biz | 10–19 |
| 9 | `test_rating_scale_15_update_and_delete_level_endpoints_work` | TC-P08 | Biz | 10–19 |
| 10 | `test_rating_scale_16_show_page_renders_scale_and_levels` | TC-P09 | Biz | 10–19 |
| 11 | `test_rating_scale_17_masters_tab_lists_scales_with_levels_count` | TC-P10 | Biz | 10–19 |
| 12 | `test_rating_scale_18_grade_type_descriptive_accepted_but_absent_from_ui_rs_gap_03` | TC-X08 | Biz/Defect | 10–19 |
| 13 | `test_rating_scale_20_active_to_inactive_transition_succeeds` | TC-P11 | State machine | 20–29 |
| 14 | `test_rating_scale_21_deactivation_not_blocked_when_referenced_data_ba_001` | TC-D08/TC-X05 | State machine/Defect | 20–29 |
| 15 | `test_rating_scale_30_required_fields_are_rejected` | TC-N01 | Validation | 30–39 |
| 16 | `test_rating_scale_31_code_max_length_30_is_enforced` | TC-N02 | Validation | 30–39 |
| 17 | `test_rating_scale_32_name_max_length_100_is_enforced` | TC-N03 | Validation | 30–39 |
| 18 | `test_rating_scale_33_grade_type_must_be_in_allowed_set` | TC-N04 | Validation | 30–39 |
| 19 | `test_rating_scale_34_min_rating_must_be_numeric_and_non_negative` | TC-N05 | Validation | 30–39 |
| 20 | `test_rating_scale_35_max_rating_must_be_greater_than_min_rating` | TC-N06 | Validation | 30–39 |
| 21 | `test_rating_scale_36_duplicate_code_is_rejected_scoped_to_non_deleted` | TC-N07 | Validation | 30–39 |
| 22 | `test_rating_scale_37_duplicate_code_is_allowed_after_soft_delete` | TC-N08 | Validation | 30–39 |
| 23 | `test_rating_scale_38_xss_payload_in_name_is_stored_escaped_on_show` | TC-N09 | Validation/Security | 30–39 |
| 24 | `test_rating_scale_39_level_numeric_value_out_of_scale_range_is_accepted_val_ba_002` | TC-N10/TC-X03 | Validation/Defect | 30–39 |
| 25 | `test_rating_scale_40_delete_soft_deletes_sets_inactive_and_moves_to_trash` | TC-D01 | Dependency-B | 40–49 |
| 26 | `test_rating_scale_41_restore_from_trash_reactivates_visibility` | TC-D02 | Dependency-B | 40–49 |
| 27 | `test_rating_scale_42_force_delete_removes_scale_and_cascades_levels` | TC-D03 | Dependency-B | 40–49 |
| 28 | `test_rating_scale_43_force_deleting_level_nulls_assessment_ratings` | TC-D04 | Dependency-D | 40–49 |
| 29 | `test_rating_scale_44_config_reference_restricts_force_delete_of_scale` | TC-D05 | Dependency-C | 40–49 |
| 30 | `test_rating_scale_45_soft_delete_is_not_blocked_when_referenced_rs_gap_02` | TC-D06/TC-X07 | Dependency-E/Defect | 40–49 |
| 31 | `test_rating_scale_46_full_lifecycle_create_toggle_delete_restore_force_delete` | TC-P12/TC-D07 | Dependency-F | 40–49 |
| 32 | `test_rating_scale_50_guest_is_redirected_to_login` | TC-N14 | AuthZ | 50–59 |
| 33 | `test_rating_scale_51_limited_user_without_create_permission_gets_403` | TC-N15 | AuthZ | 50–59 |
| 34 | `test_rating_scale_52_limited_user_without_status_permission_gets_403_on_toggle` | TC-N16 | AuthZ | 50–59 |
| 35 | `test_rating_scale_53_limited_user_without_delete_permission_gets_403_on_destroy` | TC-N17 | AuthZ | 50–59 |
| 36 | `test_rating_scale_54_policy_methods_map_to_permission_strings` | TC-P (BC-AUTH-09) | AuthZ | 50–59 |
| 37 | `test_rating_scale_55_status_toggle_endpoint_updates_is_active_and_returns_json` | TC-P13 | AuthZ/Biz | 50–59 |
| 38 | `test_rating_scale_60_masters_search_filters_by_name_and_code` | TC-P14 | UI/UX | 60–69 |
| 39 | `test_rating_scale_61_empty_state_message_when_search_matches_nothing` | TC-N18 | UI/UX | 60–69 |
| 40 | `test_rating_scale_62_trash_page_renders` | TC-P15 | UI/UX | 60–69 |
| 41 | `test_rating_scale_63_breadcrumb_present_on_create_and_show_pages` | TC-P16 | UI/UX | 60–69 |
| 42 | `test_rating_scale_70_invalid_id_returns_404` | TC-N11 | Edge | 70–79 |
| 43 | `test_rating_scale_71_code_boundary_30_chars_accepted_rs_gap_01` | TC-X06 | Edge/Defect | 70–79 |
| 44 | `test_rating_scale_72_max_rating_equal_to_min_rating_is_rejected` | TC-N12 | Edge | 70–79 |
| 45 | `test_rating_scale_73_whitespace_only_name_is_rejected` | TC-N13 | Edge | 70–79 |
| 46 | `test_rating_scale_90_tenant_context_is_initialized` | TC-P17 | Tenancy | 90–99 |
| 47 | `test_rating_scale_91_cross_tenant_direct_id_isolation` | TC-D09 | Tenancy | 90–99 |
| 48 | `test_rating_scale_92_form_request_authorize_returns_true_sec_ba_002` | TC-N19/TC-X04 | Security/Defect | 90–99 |
| 49 | `test_rating_scale_93_stored_xss_in_description_not_executed_on_show` | TC-N20 | Security | 90–99 |

**Total: 49 test methods.**

---

## 4. Known Source Defects (audit-equivalent, proven by this suite)

| ID | Severity | Requirement | Proven by |
|----|----------|-------------|-----------|
| DATA-BA-001 | P1 | BR-BA-029 — active scale switchable / deactivatable while referenced | `test_rating_scale_21_*` (+ `_45`, `_55`) |
| SEC-BA-002 | P1 | D30 — FormRequest `authorize()` returns bare `true` | `test_rating_scale_92_*` |
| BUG-BA-009 | P2 | BR-BA-028 — one-default not enforced | `test_rating_scale_13_*` |
| VAL-BA-002 | P2 | BR-BA-003 — level value not range-checked | `test_rating_scale_39_*` |
| DOC-BA-001 | Doc | DDL `bha_` prefix stale vs live `ba_` | `test_rating_scale_02_*` |
| RS-GAP-01 | Obs | Requirement code max 10 vs impl max 30 | `test_rating_scale_71_*` |
| RS-GAP-02 | Obs | Referenced scale soft-delete not blocked | `test_rating_scale_45_*` |
| RS-GAP-03 | Obs | `descriptive` grade_type valid but no UI option | `test_rating_scale_18_*` |
