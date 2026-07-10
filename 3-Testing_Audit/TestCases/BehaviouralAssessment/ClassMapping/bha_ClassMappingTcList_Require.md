# ClassMapping — Business Conditions & Test Case List

**Module:** BehaviouralAssessment  ·  **Feature/Screen:** ClassMapping (`05-Class-Mapping.md`)
**Primary table:** `ba_class_category_jnt` (junction: Class ↔ Category)
**File prefix:** `bha_` (per DDL doc + inventory). **Live table is `ba_`** — see `DOC-BA-001`.
**Controller:** `BaClassCategoryController` (`store` / `toggleStatus` / `destroy` only — **no edit/update**) · list rendered by `BaDashboardController@setup`.
**FormRequest:** **none** — inline `$request->validate()` in the controller (`VAL-BA-001`).
**Service in write path:** none (plain Eloquent; `BehaviouralScoreService` is not called here).
**Test style:** browser **Dusk** (`extends DuskTestCase`) — matches committed sibling `ClassCategoryCrudTest.php`.
**DB scope:** **tenant-side** (DDL header `Database: tenant_db`; migration under `database/migrations/tenant/`).
**Activity log:** none for this feature (flash `->with('success', …)` only).

> ⚠️ **Prefix / doc discrepancy (`DOC-BA-001`, audit-confirmed):** the DDL doc + inventory label the table `bha_class_category_jnt`; the live migration/model/DB use `ba_class_category_jnt`. Artifact **file names** keep `bha_`; every **PHP schema assertion** targets the real `ba_` table. Do not rename in code.

> ⚠️ **NEW model finding `BUG-BA-012`:** `BaClassCategoryJnt` does **not** use the `SoftDeletes` trait even though the migration declares `softDeletes()`/`deleted_at` and `store()`'s unique rule scopes `->whereNull('deleted_at')`. Consequence: `destroy()` (`$mapping->delete()`) is a **permanent hard delete**, and `withTrashed()/restore()/forceDelete()` are unavailable. The committed sibling `ClassCategoryCrudTest.php` asserts the *opposite* (SoftDeletes present + full trash lifecycle) and its `test_..._soft_delete_restore_force_delete_lifecycle` / schema test would **error/fail** against the real model. This suite asserts the **current behaviour** (hard delete) per HARD-RULE-10 and `05_` §C12.

> ⚠️ **Committed-sibling drift corrected here:** the sibling asserts flash `'Mapping added successfully'` (real string is **`Category mapped to class successfully.`**), uses selector `.status-switch[data-id]` (real component renders **`.status-toggle[data-id]`**), clicks `.delete-mapping[data-id]` (real delete is a **POST form + `@method('DELETE')` + SweetAlert**), and references a non-existent migration path `2026_04_11_000006` (real: **`2026_06_16_130618`**, in the root `database/migrations/tenant/`). This suite uses the real strings/selectors/paths.

---

## 1. Business Conditions

### BC-DB — Schema / columns / constraints (Source: DDL + live migration)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_class_category_jnt` has `id, class_id, category_id, is_active, created_by, updated_by, created_at, updated_at, deleted_at` | DDL-ba_class_category_jnt |
| BC-DB-02 | `is_active` is `TINYINT(1)`/boolean, default `true` | migration |
| BC-DB-03 | `class_id`, `category_id`, `created_by`, `updated_by` are `NOT NULL` (DB rejects missing) | migration |
| BC-DB-04 | `uq_ba_class_cat(class_id, category_id)` is a DB unique index (**no** `deleted_at` in it) | migration |
| BC-DB-05 | Junction has **no** `academic_session_id` column | migration (vs Screen) |
| BC-DB-06 | Model casts `is_active → boolean`; fillable `class_id, category_id, is_active, created_by, updated_by` | Model |

### BC-VAL — Validation rules + messages (Source: `BaClassCategoryController@store` inline validate — no FormRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `class_id` `required, integer, exists:sch_classes,id` | Screen-VR-1 / Controller:21 |
| BC-VAL-02 | `category_id` `required, integer, exists:ba_categories,id` | Screen-VR-3 / Controller:22-25 |
| BC-VAL-03 | `category_id` **unique** on `ba_class_category_jnt` scoped `where class_id = X` + `whereNull(deleted_at)`; message `This category is already mapped to the selected class.` | Screen-BR / Controller:26-33 |
| BC-VAL-04 | Validation is **inline** in the controller — no `BaClassCategoryRequest` | Audit-VAL-BA-001 |
| BC-VAL-05 | No custom `messages()` beyond the duplicate message; other failures use Laravel defaults | Controller:31-33 |

### BC-AUTH — Permission gates (Source: Controller `Gate::authorize` + Blade `@can` + routes)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | All web routes require auth; guest → redirect `/login` | Screen-PM / routes |
| BC-AUTH-02 | `store`/`toggleStatus`/`destroy` gated by `tenant.behavioural-assessment.class-categories.{create,status,delete}` | Controller:19,50,65 |
| BC-AUTH-03 | Setup page gated by `tenant.behavioural-assessment.setup.viewAny` | BaDashboardController@setup |
| BC-AUTH-04 | `toggleStatus`/`destroy` resolve via `findOrFail($id)` → 404 on unknown id (IDOR guard) | Controller:51,66 |

### BC-BIZ — Business behaviour / flash (Source: Controller + Blade + Screen)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Setup › Class-Mapping tab renders class + category selects and "Add Mapping" | _class-mapping.blade |
| BC-BIZ-02 | Store persists the mapping, flash `Category mapped to class successfully.` | Controller@store:44-45 |
| BC-BIZ-03 | Store sets `is_active=true`, `created_by=updated_by=auth()->id()` | Controller@store:35-41 |
| BC-BIZ-05 | List loads `with(['schoolClass','category'])`, `orderBy('class_id')`, `paginate(20,'cm_page')` | BaDashboardController@setup |
| BC-BIZ-06 | List shows Class code+name, Category name, Polarity badge, Status switch | _class-mapping.blade |
| BC-BIZ-07 | Empty state: `No class-category mappings yet.` | _class-mapping.blade @empty |
| BC-BIZ-08 | Delete = POST form + `@method('DELETE')` + SweetAlert `Remove Mapping?`; flash `Mapping removed.` | _class-mapping.blade + Controller@destroy:71 |
| BC-BIZ-15 | Model omits `SoftDeletes` → `destroy()` is a HARD delete (deleted_at never set) | Audit-BUG-BA-012 |
| BC-BIZ-16 | `destroy()` performs **no** "ratings already recorded" guard (Preservation-of-Grades gap) | GAP-BA-CM-01 |

### BC-SM — State-machine / status lifecycle (Source: Controller@toggleStatus + destroy)
| ID | State → Trigger → Next | Source |
|----|-----------------------|--------|
| BC-SM-01 | active → toggleStatus → inactive (and back) — no usage guard | Controller@toggleStatus:48-61 |
| BC-SM-02 | toggleStatus returns JSON `{success, is_active, message}` (`Mapping activated./deactivated.`) | Controller@toggleStatus:56-60 |
| BC-SM-03 | present → destroy → **removed (hard delete)** — no trash/restore state exists | Controller@destroy + Audit-BUG-BA-012 |

### BC-INT — Integration points (cross-module, Source: DDL FKs + Screen)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | `class_id` → `sch_classes.id` (SchoolSetup) `ON DELETE CASCADE` (`fk_ba_cc_class_id`) | Screen-IP-1 / migration |
| BC-INT-02 | `category_id` → `ba_categories.id` `cascadeOnDelete` | Screen-IP-2 / migration |
| BC-INT-03 | Ratings grid reads `ba_class_category_jnt` per selected class; empty mapping ⇒ empty grid | Screen-BR "Dynamic Form Rendering" / Audit-BUG-BA-007 |

### BC-REF — FK & relationships (Source: DDL + Model)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `BaClassCategoryJnt::schoolClass()` belongsTo `SchoolClass` (`class_id`) | Model |
| BC-REF-02 | `BaClassCategoryJnt::category()` belongsTo `BaCategory` (`category_id`) | Model |
| BC-REF-03 | Duplicate `(class_id, category_id)` blocked by `uq_ba_class_cat` at the DB layer | migration |

### BC-EDG — Edge / boundary (Source: schema + behaviour)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | After hard delete, the same pair can be re-mapped immediately (slot freed — no soft-delete ghost) | Audit-BUG-BA-012 |
| BC-EDG-02 | The same category may map to two **different** classes (uniqueness is per pair) | migration uq |
| BC-EDG-03 | `toggleStatus` on an unknown id → `findOrFail` 404 (no success payload) | Controller:51 |
| BC-EDG-04 | Category/class names rendered with escaped Blade `{{ }}` (no `{!! !!}`) | _class-mapping.blade |

### BC-CFG — Tenancy / config
| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | Tenant-per-DB; no `tenant_id` column; requires initialized tenant | DDL header |
| BC-CFG-02 | Screen describes multi-category grid + Academic Session; implementation is single class+category, no session | GAP-BA-CM-02 |

### Known Source Defects (audit-equivalent — `BUG-BA-###`/`VAL-BA-###`/`GAP-BA-CM-##`)
| ID | Description | Proven by |
|----|-------------|-----------|
| DOC-BA-001 | DDL doc prefix `bha_` vs live `ba_` table | V1 `01` · V2 `01` |
| **BUG-BA-012 (NEW)** | Model omits `SoftDeletes` despite migration `softDeletes()`/`deleted_at` → `destroy()` is a **hard delete** | V1 `01`,`08` · V2 `04`,`22` |
| VAL-BA-001 | Core write path has no FormRequest — inline validation | V1 `12` · V2 `30` |
| BUG-BA-007 | Unmapped class ⇒ empty ratings grid (BR-BA-009 permissive default missing) | V1 `14` · V2 `41` |
| **GAP-BA-CM-01 (NEW)** | `destroy()` has no "ratings already recorded" guard (Preservation-of-Grades unenforced) | V2 `42` |
| **GAP-BA-CM-02 (NEW)** | Requirement multi-category grid + Academic Session not implemented | V2 `43` |

---

## 2. Test Case List

Columns: **TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status**

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-P01 | BC-DB-01/06 | DDL | Schema+model+config truth | Table/columns/casts/relations correct | 01 | 01/03 | ✅ |
| TC-P02 | BC-REF-03 | migration | Unique + FK migration content | uq_ba_class_cat + both FKs present | 01 | 02 | ✅ |
| TC-P03 | BC-BIZ-02 | Controller | Create mapping via form persists | Row created, flash success | 05 | 10 | ✅ |
| TC-P04 | BC-DB-05 | migration | is_active defaults true | New mapping active | 06 | 11 | ✅ |
| TC-P05 | BC-BIZ-05/06 | setup | List shows created mapping | Class name visible in list | 10 | 60 | ✅ |
| TC-P06 | BC-REF-01/02 | Model | Relationships resolve | schoolClass+category resolve to parents | 11 | 40 | ✅ |
| TC-P10 | BC-BIZ-01 | blade | Setup class-mapping tab renders | Selects + Add Mapping visible | 04 | 12 | ✅ |
| TC-P11 | BC-BIZ-03 | Controller | Store sets audit + is_active cols | created_by/updated_by/is_active correct | — | 11 | ✅ |
| TC-P13 | BC-BIZ-05 | Controller | Paginator cm_page + tab append | cm_page present, tab preserved | — | 13 | ✅ |
| TC-P60 | BC-BIZ-06 | blade | List renders headers/polarity | Class/Category/Polarity/Status columns | — | 12 | ✅ |
| TC-P61 | BC-BIZ-07 | blade | Empty-state message defined | "No class-category mappings yet." | — | 61 | ✅ |
| TC-P62 | BC-BIZ-08 | blade | Delete control is confirmed form | DELETE method + Swal confirm | — | 62 | ✅ |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-N01 | BC-DB-03 | DDL | DB rejects missing class/category | Insert throws 23000 | 02 | 05 | ✅ |
| TC-N02 | BC-DB-04 | migration | Duplicate pair violates DB unique | 23000 on re-insert | 03 | 36 | ✅ |
| TC-N03 | BC-VAL-03 | Controller | Duplicate mapping via form rejected | Message shown, no new row | 09 | 31 | ✅ |
| TC-N04 | BC-VAL-01 | Controller | Missing class rejected | No row created | — | 32 | ✅ |
| TC-N05 | BC-VAL-02 | Controller | Missing category rejected | No row created | — | 33 | ✅ |
| TC-N06 | BC-VAL-01 | Controller | Unknown class id rejected (exists) | No row for ghost class | — | 34 | ✅ |
| TC-N07 | BC-VAL-02 | Controller | Unknown category id rejected (exists) | No row for ghost category | — | 35 | ✅ |
| TC-N20 | BUG-BA-012 | Audit | Model missing SoftDeletes (proof) | Trait absent; migration has softDeletes | 01 | 04 | ✅ (proves bug) |
| TC-N02b | VAL-BA-001 | Audit | No FormRequest — inline validate (proof) | No BaClassCategoryRequest file | 12 | 30 | ✅ (proves gap) |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 | F | BC-SM-03 | Controller | Destroy hard-deletes mapping | Row physically gone (no soft-delete) | 08 | 22 | ✅ (proves BUG-BA-012) |
| TC-D02 | G | BC-EDG-01 | migration | Re-map same pair after hard delete | Succeeds (slot freed) | — | 23 | ✅ |
| TC-D03 | E | BC-INT-01 | migration | Mapping belongs to sch_classes | schoolClass->id resolves (defensive) | 11 | 40 | ✅ |
| TC-D04 | E | BC-INT-03 | Audit | Unmapped class ⇒ empty mapping (proof) | count(class)=0 → empty grid | 14 | 41 | ✅ (proves BUG-BA-007) |
| TC-D05 | E | BC-BIZ-16 | GAP | Unmap has no recorded-grades guard | destroy succeeds; controller lacks guard | — | 42 | ✅ (proves GAP-BA-CM-01) |
| TC-D06 | E | BC-CFG-02 | GAP | Single-pair form, no session scope | no multi-select/session/column | — | 43 | ✅ (proves GAP-BA-CM-02) |
| TC-D07 | G | BC-EDG-02 | migration | Same category across two classes | Both inserts succeed | — | 70 | ✅ |
| TC-D08 | G | BC-EDG-03 | Controller | Toggle unknown id (404) | No success payload; no row | — | 71 | ✅ |

### State-machine (TC-SM)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-SM01 | BC-SM-01 | Controller | Toggle active↔inactive | is_active flips | 07 | 20 | ✅ |
| TC-SM02 | BC-SM-02 | Controller | Toggle JSON payload | `{success,is_active,message}` returned | — | 21 | ✅ |

### Tenancy / Security (TC-T / TC-S)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-T01 | BC-CFG-01 | DDL | Tenant-scoped, no tenant_id | tenancy initialized, no tenant_id col | — | 90 | ✅ |
| TC-S01 | BC-AUTH-01 | routes | Guest redirected (setup) | `/login` | 13 | 50 | ✅ |
| TC-S02 | BC-AUTH-02 | Controller | Each write action gated | 3 Gate::authorize strings present | — | 51 | ✅ |
| TC-S03 | BC-AUTH-03 | Controller | Limited user blocked from setup | 403 / no Add Mapping form | — | 52 | ✅ (defensive) |
| TC-S05 | BC-EDG-04 | blade | Category name escaped on list | `{{ }}` escaped, no `{!! !!}` | — | 91 | ✅ |
| TC-S06 | BC-AUTH-04 | Controller | Invalid id not actionable | findOrFail; no ghost row | — | 92 | ✅ |

---

## 3. V2 Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_class_mapping_01_schema_and_doc_prefix_are_correct | TC-P01/DOC-BA-001 | Schema | 01–09 |
| 2 | test_class_mapping_02_migration_unique_and_foreign_keys | TC-P02 | Schema | 01–09 |
| 3 | test_class_mapping_03_model_fillable_casts_and_relationships | TC-P01 | Schema | 01–09 |
| 4 | test_class_mapping_04_model_missing_softdeletes_trait_bug_ba_012 | TC-N20 | Schema (bug) | 01–09 |
| 5 | test_class_mapping_05_db_rejects_each_missing_required_field | TC-N01 | Validation | 01–09 |
| 6 | test_class_mapping_10_create_valid_mapping_persists_and_flashes | TC-P03 | Business | 10–19 |
| 7 | test_class_mapping_11_store_sets_is_active_and_audit_columns | TC-P11 | Business | 10–19 |
| 8 | test_class_mapping_12_list_renders_class_and_polarity | TC-P60 | Business/UI | 10–19 |
| 9 | test_class_mapping_13_setup_uses_cm_page_paginator | TC-P13 | Business | 10–19 |
| 10 | test_class_mapping_20_toggle_status_deactivates_then_reactivates | TC-SM01 | State | 20–29 |
| 11 | test_class_mapping_21_toggle_endpoint_returns_json_payload | TC-SM02 | State | 20–29 |
| 12 | test_class_mapping_22_destroy_hard_deletes_row | TC-D01 | State (bug) | 20–29 |
| 13 | test_class_mapping_23_pair_can_be_remapped_after_hard_delete | TC-D02 | Edge/State | 20–29 |
| 14 | test_class_mapping_30_no_form_request_inline_validation_val_ba_001 | TC-N02b | Validation (gap) | 30–39 |
| 15 | test_class_mapping_31_duplicate_mapping_shows_validation_message | TC-N03 | Validation | 30–39 |
| 16 | test_class_mapping_32_missing_class_is_rejected | TC-N04 | Validation | 30–39 |
| 17 | test_class_mapping_33_missing_category_is_rejected | TC-N05 | Validation | 30–39 |
| 18 | test_class_mapping_34_nonexistent_class_id_is_rejected | TC-N06 | Validation | 30–39 |
| 19 | test_class_mapping_35_nonexistent_category_id_is_rejected | TC-N07 | Validation | 30–39 |
| 20 | test_class_mapping_36_db_unique_index_blocks_duplicate_pair | TC-N02 | Validation | 30–39 |
| 21 | test_class_mapping_40_class_belongs_to_school_class | TC-D03 | Integration | 40–49 |
| 22 | test_class_mapping_41_unmapped_class_yields_empty_mapping_bug_ba_007 | TC-D04 | Integration (bug) | 40–49 |
| 23 | test_class_mapping_42_unmap_has_no_recorded_grades_guard_gap | TC-D05 | Integration (gap) | 40–49 |
| 24 | test_class_mapping_43_single_pair_form_no_session_scope_gap | TC-D06 | Integration (gap) | 40–49 |
| 25 | test_class_mapping_50_guest_redirected_to_login_on_setup | TC-S01 | Auth | 50–59 |
| 26 | test_class_mapping_51_controller_gates_each_write_action | TC-S02 | Auth | 50–59 |
| 27 | test_class_mapping_52_user_without_permission_is_blocked_from_setup | TC-S03 | Auth | 50–59 |
| 28 | test_class_mapping_60_created_mapping_appears_in_list | TC-P05 | UI/UX | 60–69 |
| 29 | test_class_mapping_61_empty_state_message_is_defined | TC-P61 | UI/UX | 60–69 |
| 30 | test_class_mapping_62_delete_control_is_a_confirmed_delete_form | TC-P62 | UI/UX | 60–69 |
| 31 | test_class_mapping_70_same_category_allowed_across_two_classes | TC-D07 | Edge | 70–79 |
| 32 | test_class_mapping_71_toggle_unknown_id_does_not_crash_client | TC-D08 | Edge | 70–79 |
| 33 | test_class_mapping_90_runs_inside_initialized_tenant | TC-T01 | Tenancy | 90–99 |
| 34 | test_class_mapping_91_category_name_is_escaped_on_list | TC-S05 | Security | 90–99 |
| 35 | test_class_mapping_92_invalid_id_is_not_actionable | TC-S06 | Security | 90–99 |

**Counts:** V1 = 14 methods · V2 = 35 methods · ratio = **2.50×** (≥ 2× gate met).
