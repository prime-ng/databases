# RatingScale — Business Conditions & Test Case List

**Module:** BehaviouralAssessment  ·  **Feature/Screen:** RatingScale (`02-Rating-Scales.md`)
**Primary table:** `ba_rating_scales`  ·  **Child:** `ba_rating_levels`
**File prefix:** `bha_` (per DDL doc `CREATE TABLE bha_rating_scales` + inventory). **Live tables are `ba_`** — see `DOC-BA-001`.
**Controller:** `BaRatingScaleController`  ·  **FormRequest:** `BaRatingScaleRequest`  ·  **Service in write path:** none (plain Eloquent).
**Test style:** browser **Dusk** (`extends DuskTestCase`) — matches committed sibling `RatingScaleCrudTest.php`.
**DB scope:** **tenant-side** (DDL header `Database: tenant_db`; migrations under `database/migrations/tenant/`).
**Activity log:** none for this feature (RatingScale CRUD uses flash `->with('success', …)` only; `ba_audit_log` covers assessment ratings/incidents, **not** scales).

> ⚠️ **Prefix / doc discrepancy (`DOC-BA-001`, audit-confirmed):** the DDL doc + inventory label the tables `bha_*`; the live migrations, models and DB use `ba_rating_scales` / `ba_rating_levels`. Artifact **file names** keep `bha_`; every **PHP schema assertion** targets the real `ba_` tables. Do not rename in code.

---

## 1. Business Conditions

### BC-DB — Schema / columns / constraints (Source: DDL + live migration)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_rating_scales` has `code, name, description, grade_type, min_rating, max_rating, is_default, is_active, created_by, updated_by, timestamps, deleted_at` | DDL-ba_rating_scales |
| BC-DB-02 | `min_rating`/`max_rating` are `DECIMAL(3,1)`; `is_default`/`is_active` are `TINYINT(1)` boolean | DDL-ba_rating_scales |
| BC-DB-03 | `ba_rating_levels` has `rating_scale_id, label, numeric_value(DEC 3,1), description, sort_order(TINYINT UNS), is_active, …, deleted_at` | DDL-ba_rating_levels |
| BC-DB-04 | `code, name, grade_type, min_rating, max_rating, created_by, updated_by` are `NOT NULL` (DB rejects missing) | DDL-ba_rating_scales |
| BC-DB-05 | `description` is nullable | DDL-ba_rating_scales |
| BC-DB-06 | Both models use `SoftDeletes`; casts: `min_rating/max_rating → decimal:1`, `is_default/is_active → boolean` | Model |

### BC-VAL — Validation rules + messages (Source: `BaRatingScaleRequest`, `storeLevel`/`updateLevel`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `code` required, string, `max:30`, **unique** on `ba_rating_scales.code` ignoring self, scoped `whereNull(deleted_at)` | Screen-VR-2 / Request:22 |
| BC-VAL-02 | `name` required, string, `max:100` | Screen-VR-1 / Request:23 |
| BC-VAL-03 | `grade_type` required, `Rule::in(['letter','numeric','descriptive'])` | Request:25 |
| BC-VAL-04 | `min_rating` required, numeric, `min:0` | Request:26 |
| BC-VAL-05 | `max_rating` required, numeric, `gt:min_rating` (equal rejected) | Request:27 |
| BC-VAL-06 | `code` upper-cased in `prepareForValidation` (`strtoupper`) | Request:36 |
| BC-VAL-07 | `is_default`/`is_active` cast to boolean; `is_active` defaults true | Request:37-38 |
| BC-VAL-08 | Level: `label` required max:50; `numeric_value` required **numeric only (NO range check)**; `sort_order` nullable int min:0 | Controller@storeLevel:135-140 |

### BC-AUTH — Permission gates (Source: Controller `Gate::authorize` + Policy + Blade)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | All web routes require auth; guest → redirect `/login` | Screen-PM / routes |
| BC-AUTH-02 | `viewAny/view/create/update/delete/restore/forceDelete/status` gated by `tenant.behavioural-assessment.rating-scales.*` | Controller + Policy |
| BC-AUTH-03 | `BaRatingScaleRequest::authorize()` returns bare `true` — auth deferred to controller gates | Audit-SEC-BA-002 |
| BC-AUTH-04 | User lacking `.create` is blocked (403) from the create screen | Controller@create:27 |
| BC-AUTH-05 | Invalid id on `show` → `findOrFail` 404 | Controller@show:47 |

### BC-BIZ — Business behaviour / flash / auto (Source: Controller + Screen)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Create page renders "Scale Identity" + "Score Range & Settings" + "Save Rating Scale" | create.blade |
| BC-BIZ-02 | Store persists scale, flash `Rating scale created successfully.` | Controller@store:41 |
| BC-BIZ-03 | Show renders identity + range + "Configured Rating Levels" | show.blade |
| BC-BIZ-04 | Update persists, flash `Rating scale updated successfully.` | Controller@update:68 |
| BC-BIZ-05 | Destroy sets `is_active=false` **then** soft-deletes; flash `Rating scale moved to trash.` | Controller@destroy:75-82 |
| BC-BIZ-06 | Restore flash `Rating scale restored successfully.`; forceDelete flash `Rating scale permanently deleted.` | Controller@restore/forceDelete |
| BC-BIZ-07 | Levels: add via edit page → flash `Level added.`; update `Level updated.`; delete `Level removed.` | Controller@storeLevel/updateLevel/destroyLevel |
| BC-BIZ-08 | Masters list search filters by `name` OR `code` (paginator `rs_page`, 15/page) | BaDashboardController@masters:151-156 |
| BC-BIZ-09 | `is_default` is saved as submitted (checkbox) | Controller@store/update |

### BC-SM — State-machine / status lifecycle (Source: Controller@toggleStatus + soft-delete)
| ID | State → Trigger → Next | Source |
|----|-----------------------|--------|
| BC-SM-01 | active → toggleStatus → inactive (and back) — **no usage guard** | Controller@toggleStatus:117-130 |
| BC-SM-02 | toggleStatus returns JSON `{success, is_active, message}` (`Rating scale activated./deactivated.`) | Controller@toggleStatus:125-129 |
| BC-SM-03 | present → destroy → trashed (is_active=false) → restore → present | Controller |
| BC-SM-04 | trashed → forceDelete → removed (cascades levels via FK) | Controller@forceDelete + migration cascade |

### BC-REF / BC-INT — FK & integration (Source: DDL FKs)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `ba_rating_levels.rating_scale_id` → `ba_rating_scales.id` `ON DELETE CASCADE` | DDL / migration |
| BC-REF-02 | Force-deleting a scale cascades its levels at DB level | migration cascadeOnDelete |
| BC-REF-03 | `BaRatingLevel::scale()` belongsTo, `BaRatingScale::levels()` hasMany | Model |
| BC-INT-01 | `ba_config.rating_scale_id` → `ba_rating_scales.id` `ON DELETE RESTRICT` (scale used by config) | DDL-ba_config |

### BC-EDG — Edge / boundary (Source: DDL limits + requirement)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Create page prefills `min_rating=1.0`, `max_rating=5.0` | create.blade |
| BC-EDG-02 | `code` reusable after soft-delete (no DB unique on code; request scoped to non-deleted) | Request:22 |
| BC-EDG-03 | `uq_ba_level(rating_scale_id, sort_order)` unique **excludes** soft-deletes → recreate collision | migration uq_ba_level |
| BC-EDG-04 | DECIMAL(3,1) boundary values (0.0 … 9.9) persist | DDL |
| BC-EDG-05 | Long `description` (TEXT) accepted | DDL |
| BC-EDG-06 | Scale `name` free-text; Blade `{{ }}` escapes stored XSS on show | show.blade |

### BC-CFG — Tenancy / config
| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | Tenant-per-DB; no `tenant_id` column; requires initialized tenant | DDL header |

### Known Source Defects (audit-equivalent — module uses `BUG-BA-###`/`SEC-BA-###`/`DATA-BA-###`/`VAL-BA-###`)
| ID | Description | Proven by |
|----|-------------|-----------|
| BUG-BA-009 | BR-BA-028 not enforced — multiple scales can be `is_default=true` | V2 `test_..._13` |
| VAL-BA-002 | BR-BA-003 — level `numeric_value` not range-checked against scale bounds | V2 `test_..._38` |
| DATA-BA-003 | Soft-delete + `uq_ba_level` (no `deleted_at`) → recreate-after-delete integrity error (500) | V2 `test_..._39` |
| SEC-BA-002 | `BaRatingScaleRequest::authorize()` returns bare `true` (systemic) | V2 `test_..._52` |
| DATA-BA-001 | BR-BA-029 — active scale deactivatable mid-session with no usage/config guard | V2 `test_..._26`, `_27` |
| DOC-BA-001 | DDL doc prefix `bha_` vs live `ba_` tables | V2 `test_..._01` |

---

## 2. Test Case List

Columns: **TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status**

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-P01 | BC-DB-01/06 | DDL | Schema+model+softdelete config | Table/columns/casts/relations correct | 01 | 01 | ✅ |
| TC-P02 | BC-DB-03/REF-01 | DDL | Levels schema + uq_ba_level + FK | Unique index + cascade FK present | 02 | 02 | ✅ |
| TC-P03 | BC-DB-06 | Model | Fillable/relationships/scope | fillable + hasMany + scopeActive | — | 03 | ✅ |
| TC-P04 | BC-DB-05 | DDL | Null description accepted | Saves with null description | 04 | 06 | ✅ |
| TC-P10 | BC-BIZ-01/02 | Controller | Create valid persists | Row created, code upper-cased | 11 | 10 | ✅ |
| TC-P11 | BC-VAL-06 | Request | Code upper-cased on store | Persisted code = strtoupper(input) | 11 | 11 | ✅ |
| TC-P12 | BC-BIZ-09 | Controller | is_default persists | is_default = true stored | — | 12 | ✅ |
| TC-P13 | BC-BIZ-03 | show.blade | Show renders scale+levels | Code/name/levels visible | 12 | 14 | ✅ |
| TC-P14 | BC-BIZ-04 | Controller | Edit update persists + flash | Name updated, success flash | 13 | 15 | ✅ |
| TC-P15 | BC-BIZ-07 | Controller | Add level via edit page | Level row created, `Level added.` | 16 | 16 | ✅ |
| TC-P16 | BC-BIZ-07 | Controller | Remove level soft-deletes | Level hidden, trashed row remains | — | 17 | ✅ |
| TC-P17 | BC-EDG-01 | create.blade | Default range prefilled | min=1.0 max=5.0 | — | 18 | ✅ |
| TC-P21 | BC-BIZ-08 | trash.blade | Trash lists soft-deleted | Deleted scale visible in trash | 21 | 63 | ✅ |
| TC-P60 | BC-BIZ-08 | masters | List shows created scale | Code appears in masters list | — | 60 | ✅ |
| TC-P61 | BC-BIZ-08 | masters | Search by name | Only matching scale shown | — | 61 | ✅ |
| TC-P62 | BC-BIZ-08 | masters | Search by code | Only matching scale shown | — | 62 | ✅ |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-N01 | BC-DB-04 | DDL | DB rejects missing required | Insert throws 23000 | 03 | 05 | ✅ |
| TC-N02 | BC-VAL-* | Request | FormRequest rule strings present | Literal rules asserted | — | 04 | ✅ |
| TC-N30 | BC-VAL-01/02 | Request | Required fields blocked at server | `.alert-danger`, no row | — | 30 | ✅ |
| TC-N31 | BC-VAL-01 | Request | code > 30 rejected | Validation error, no row | — | 31 | ✅ |
| TC-N32 | BC-VAL-02 | Request | name > 100 rejected | Validation error, no row | — | 32 | ✅ |
| TC-N33 | BC-VAL-03 | Request | grade_type out of enum rejected | Validation error, no row | 18 | 33 | ✅ |
| TC-N34 | BC-VAL-04 | Request | min_rating negative rejected | Validation error, no row | — | 34 | ✅ |
| TC-N35 | BC-VAL-05 | Request | max == min rejected (gt) | Validation error, no row | 19 | 35 | ✅ |
| TC-N36 | BC-VAL-01 | Request | Duplicate active code rejected | Validation error, no new row | 17 | 36 | ✅ |
| TC-N20 | BUG-BA-009 | Audit | Multiple defaults allowed (proof) | Both remain is_default=true | — | 13 | ✅ (proves bug) |
| TC-N21 | DATA-BA-001 | Audit | Deactivate no usage guard (proof) | Toggle inactive succeeds | — | 26 | ✅ (proves bug) |
| TC-N22 | Screen-BR | Audit | Destroy no reference guard (proof) | Soft-deletes unconditionally | — | 27 | ✅ (proves gap) |
| TC-N23 | VAL-BA-002 | Audit | Level value not range-checked (proof) | 9.9 saved on 1–5 scale | — | 38 | ✅ (proves bug) |
| TC-S03 | SEC-BA-002 | Audit | authorize() returns true (proof) | authorize()===true | — | 52 | ✅ (proves gap) |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 | F | BC-SM-03 | Controller | Full soft-delete→restore→forceDelete | Lifecycle transitions correct | 15 | 22/23 | ✅ |
| TC-D02 | B | BC-BIZ-06 | Controller | Restore from trash | Row returns to active scope | — | 23 | ✅ |
| TC-D03 | B | BC-REF-02 | migration | forceDelete cascades levels | Child levels removed | — | 24 | ✅ |
| TC-D04 | G | BC-EDG-02 | Request | Code reuse after soft-delete | New scale accepts old code | — | 37 | ✅ |
| TC-D05 | G | DATA-BA-003 | migration | Soft-deleted level sort_order collision | Integrity error on re-add | — | 39 | ✅ (proves bug) |
| TC-D06 | E | BC-INT-01 | DDL | Config relationship defined | configs() + ba_config FK (defensive) | — | 40 | ✅ |
| TC-D07 | E | BC-REF-03 | Model | Level belongs to scale | scale->id resolves | — | 41 | ✅ |
| TC-D08 | G | BC-EDG-04 | DDL | Decimal boundary persist | 0.0 / 9.9 stored | — | 70 | ✅ |
| TC-D09 | G | BC-EDG-05 | DDL | Long description accepted | TEXT stored intact | — | 71 | ✅ |

### State-machine (TC-SM)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-SM01 | BC-SM-01 | Controller | Toggle active↔inactive | is_active flips | 14 | 20 | ✅ |
| TC-SM02 | BC-SM-02 | Controller | Toggle JSON payload | `{success,message}` returned | — | 21 | ✅ |
| TC-SM03 | BC-SM-03 | Controller | Destroy deactivates then trashes | is_active=false in trash | — | 22 | ✅ |

### Tenancy / Security (TC-T / TC-S)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-T01 | BC-CFG-01 | DDL | Tenant-scoped, no tenant_id | tenancy initialized, no tenant_id col | — | 90 | ✅ |
| TC-S01 | BC-AUTH-01 | routes | Guest redirected (create) | `/login` | 20 | 50 | ✅ |
| TC-S02 | BC-AUTH-01 | routes | Guest redirected (index) | `/login` | — | 51 | ✅ |
| TC-S04 | BC-AUTH-04 | Controller | Limited user forbidden | 403 / no create form | — | 53 | ✅ (defensive) |
| TC-S05 | BC-EDG-06 | show.blade | Stored XSS escaped | Script not executed | — | 91 | ✅ |
| TC-S06 | BC-AUTH-05 | Controller | Invalid id no detail | Detail not rendered | — | 92 | ✅ |

---

## 3. V2 Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_rating_scale_01_schema_and_model_configuration_are_correct | TC-P01/DOC-BA-001 | Schema | 01–09 |
| 2 | test_rating_scale_02_levels_schema_unique_index_and_fk | TC-P02 | Schema | 01–09 |
| 3 | test_rating_scale_03_model_fillable_relationships_and_scope | TC-P03 | Schema | 01–09 |
| 4 | test_rating_scale_04_form_request_rules_contain_expected_constraints | TC-N02 | Validation-cfg | 01–09 |
| 5 | test_rating_scale_05_db_rejects_each_missing_required_field | TC-N01 | Validation | 01–09 |
| 6 | test_rating_scale_06_nullable_description_accepts_null | TC-P04 | Schema | 01–09 |
| 7 | test_rating_scale_10_create_valid_persists_row | TC-P10 | Business | 10–19 |
| 8 | test_rating_scale_11_code_is_uppercased_on_store | TC-P11 | Business | 10–19 |
| 9 | test_rating_scale_12_is_default_flag_persists | TC-P12 | Business | 10–19 |
| 10 | test_rating_scale_13_multiple_default_scales_are_allowed_bug_ba_009 | TC-N20 | Business (bug) | 10–19 |
| 11 | test_rating_scale_14_show_page_renders_scale_and_levels | TC-P13 | Business | 10–19 |
| 12 | test_rating_scale_15_edit_update_persists_and_flashes | TC-P14 | Business | 10–19 |
| 13 | test_rating_scale_16_add_level_persists | TC-P15 | Business | 10–19 |
| 14 | test_rating_scale_17_remove_level_soft_deletes | TC-P16 | Business | 10–19 |
| 15 | test_rating_scale_18_create_page_prefills_default_range | TC-P17 | Edge/UI | 10–19 |
| 16 | test_rating_scale_20_toggle_status_active_inactive_cycle | TC-SM01 | State | 20–29 |
| 17 | test_rating_scale_21_toggle_status_endpoint_returns_json_payload | TC-SM02 | State | 20–29 |
| 18 | test_rating_scale_22_destroy_deactivates_then_soft_deletes | TC-SM03 | State | 20–29 |
| 19 | test_rating_scale_23_restore_brings_back_from_trash | TC-D02 | State | 20–29 |
| 20 | test_rating_scale_24_force_delete_cascades_levels | TC-D03 | State/FK | 20–29 |
| 21 | test_rating_scale_26_deactivate_has_no_usage_guard_data_ba_001 | TC-N21 | State (bug) | 20–29 |
| 22 | test_rating_scale_27_destroy_has_no_reference_guard | TC-N22 | State (gap) | 20–29 |
| 23 | test_rating_scale_30_required_fields_show_errors_and_block_insert | TC-N30 | Validation | 30–39 |
| 24 | test_rating_scale_31_code_exceeding_max_is_rejected | TC-N31 | Validation | 30–39 |
| 25 | test_rating_scale_32_name_exceeding_max_is_rejected | TC-N32 | Validation | 30–39 |
| 26 | test_rating_scale_33_grade_type_out_of_enum_is_rejected | TC-N33 | Validation | 30–39 |
| 27 | test_rating_scale_34_negative_min_rating_is_rejected | TC-N34 | Validation | 30–39 |
| 28 | test_rating_scale_35_max_equal_to_min_is_rejected | TC-N35 | Validation | 30–39 |
| 29 | test_rating_scale_36_duplicate_active_code_is_rejected | TC-N36 | Validation | 30–39 |
| 30 | test_rating_scale_37_code_may_be_reused_after_soft_delete | TC-D04 | Edge | 30–39 |
| 31 | test_rating_scale_38_level_value_is_not_range_checked_val_ba_002 | TC-N23 | Validation (bug) | 30–39 |
| 32 | test_rating_scale_39_soft_deleted_level_sort_order_collision_data_ba_003 | TC-D05 | Edge (bug) | 30–39 |
| 33 | test_rating_scale_40_config_relationship_is_defined | TC-D06 | Integration | 40–49 |
| 34 | test_rating_scale_41_level_belongs_to_its_scale | TC-D07 | Integration | 40–49 |
| 35 | test_rating_scale_50_guest_redirected_to_login_on_create | TC-S01 | Auth | 50–59 |
| 36 | test_rating_scale_51_guest_redirected_to_login_on_index | TC-S02 | Auth | 50–59 |
| 37 | test_rating_scale_52_form_request_authorize_returns_true_sec_ba_002 | TC-S03 | Auth (gap) | 50–59 |
| 38 | test_rating_scale_53_user_without_permission_is_forbidden | TC-S04 | Auth | 50–59 |
| 39 | test_rating_scale_60_masters_list_shows_created_scale | TC-P60 | UI/UX | 60–69 |
| 40 | test_rating_scale_61_search_by_name_filters_list | TC-P61 | UI/UX | 60–69 |
| 41 | test_rating_scale_62_search_by_code_filters_list | TC-P62 | UI/UX | 60–69 |
| 42 | test_rating_scale_63_trash_page_lists_soft_deleted_scale | TC-P21 | UI/UX | 60–69 |
| 43 | test_rating_scale_70_decimal_boundary_values_persist | TC-D08 | Edge | 70–79 |
| 44 | test_rating_scale_71_long_description_is_accepted | TC-D09 | Edge | 70–79 |
| 45 | test_rating_scale_90_runs_inside_initialized_tenant | TC-T01 | Tenancy | 90–99 |
| 46 | test_rating_scale_91_stored_xss_in_name_is_escaped_on_show | TC-S05 | Security | 90–99 |
| 47 | test_rating_scale_92_invalid_id_does_not_render_detail | TC-S06 | Security | 90–99 |

**Counts:** V1 = 16 methods · V2 = 47 methods · ratio = **2.94×** (≥ 2× gate met).
