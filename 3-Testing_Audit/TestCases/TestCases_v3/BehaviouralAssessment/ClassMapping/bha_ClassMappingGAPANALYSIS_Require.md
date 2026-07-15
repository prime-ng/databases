# Behavioural Assessment — Class-Mapping — Gap Analysis

Coverage of the manual TC matrix by the single comprehensive suite `bha_ClassMapping_TestCas.php` (**44 methods**). Legend: **Full** = automated end-to-end; **Partial** = asserted but environment-gated (`markTestSkipped`) on optional dependency; **Gap** = not automated.

---

## 1. Coverage Mapping by Category

### Config-truth (schema / model / request)
| Manual TC | Test method | Coverage |
|-----------|-------------|----------|
| TC-C01 | `test_..._01_migration_model_and_request_configuration_are_correct` | Full |
| TC-C02 | `test_..._02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001` | Full |
| TC-C03 | `test_..._03_model_omits_softdeletes_despite_migration_softdeletes_data_ba_cm_01` | Full |

### Positive / Business rules
| Manual TC | Test method | Coverage |
|-----------|-------------|----------|
| TC-P01 | `test_..._10_store_creates_mapping_and_redirects_with_success` | Full |
| TC-P02 | `test_..._11_store_stamps_created_and_updated_by_admin` | Full |
| TC-P03 | `test_..._12_toggle_status_flips_is_active_and_returns_json` | Full |
| TC-P04 | `test_..._13_destroy_removes_mapping_and_redirects` | Full |
| TC-P05 | `test_..._14_setup_tab_lists_mapping_class_and_category` | Full |
| TC-P06 | `test_..._15_browser_form_add_mapping_shows_success_flash` | Full |
| TC-P07 | `test_..._16_delete_control_is_rendered_for_permitted_user` | Full |
| TC-P08 | `test_..._44_full_lifecycle_create_toggle_destroy` | Full |
| TC-P09 | `test_..._60_setup_tab_renders_form_and_table_headers` | Full |
| TC-P10 | `test_..._61_mapping_row_shows_polarity_badge` | Partial (skips if category has no polarity) |
| TC-P11 | `test_..._62_empty_state_message_is_defined_in_view` | Full |

### State machine
| Manual TC | Test method | Coverage |
|-----------|-------------|----------|
| TC-SM01 | `test_..._20_active_to_inactive_and_back_transition_succeeds` | Full |
| TC-SM02 | `test_..._21_toggle_stamps_updated_by` | Full |

### Negative / validation
| Manual TC | Test method | Coverage |
|-----------|-------------|----------|
| TC-N01 | `test_..._30_required_fields_are_rejected` | Full |
| TC-N02 | `test_..._31_class_id_must_exist_in_sch_classes` | Full |
| TC-N03 | `test_..._32_category_id_must_exist_in_ba_categories` | Full |
| TC-N04 | `test_..._33_class_id_must_be_integer` | Full |
| TC-N05 | `test_..._34_category_id_must_be_integer` | Full |
| TC-N06 | `test_..._35_duplicate_mapping_is_rejected_with_message` | Full |
| TC-N07 | `test_..._36_same_category_different_class_is_allowed` | Partial (skips if only one class) |
| TC-N08 | `test_..._37_different_category_same_class_is_allowed` | Partial (skips if only one category) |
| TC-N09 | `test_..._38_whitespace_class_id_is_rejected` | Full |
| TC-N10 | `test_..._73_null_category_id_is_rejected` | Full |

### Dependency / FK / integrity
| Manual TC | Test method | Coverage |
|-----------|-------------|----------|
| TC-D01 | `test_..._40_class_id_fk_is_cascade_on_delete` | Partial (MySQL-only, else skip) |
| TC-D02 | `test_..._41_category_id_fk_is_cascade_on_delete` | Partial (MySQL-only, else skip) |
| TC-D03 | `test_..._42_unique_index_enforces_class_category_pair_val_ba_cm_02` | Partial (MySQL-only, else skip) |
| TC-D04 | `test_..._43_destroy_hard_deletes_despite_deleted_at_column_data_ba_cm_01` | Full |

### Permissions / authorization
| Manual TC | Test method | Coverage |
|-----------|-------------|----------|
| TC-A01 | `test_..._50_guest_is_redirected_to_login` | Full |
| TC-A02 | `test_..._51_limited_user_without_create_gets_403_on_store` | Full |
| TC-A03 | `test_..._52_limited_user_without_status_gets_403_on_toggle` | Full |
| TC-A04 | `test_..._53_limited_user_without_delete_gets_403_on_destroy` | Full |
| TC-A05 | `test_..._54_policy_methods_map_to_permission_strings` | Full |
| TC-A06 | `test_..._55_setup_tab_requires_setup_viewany_permission` | Full |

### Edge / security / mass-assignment
| Manual TC | Test method | Coverage |
|-----------|-------------|----------|
| TC-E01 | `test_..._70_toggle_invalid_id_returns_404` | Full |
| TC-E02 | `test_..._71_destroy_invalid_id_returns_404` | Full |
| TC-E03 | `test_..._72_store_ignores_client_supplied_is_active_and_auditors` | Full |

### Tenancy / security pack
| Manual TC | Test method | Coverage |
|-----------|-------------|----------|
| TC-T01 | `test_..._90_tenant_context_is_initialized` | Full |
| TC-T02 | `test_..._91_cross_tenant_direct_id_isolation` | Partial (skips if only one tenant domain) |
| TC-S01 | `test_..._92_form_request_authorize_returns_true_sec_ba_002` | Full |
| TC-S02 | `test_..._93_no_activity_log_written_for_mapping_mutations` | Full |
| TC-S03 | `test_..._94_form_request_has_dead_non_post_branch_cm_gap_03` | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Config-truth | 3 | 3 | 0 | 0 | 100% |
| Positive / Business | 11 | 10 | 1 | 0 | 100% |
| State machine | 2 | 2 | 0 | 0 | 100% |
| Negative / validation | 10 | 8 | 2 | 0 | 100% |
| Dependency / FK | 4 | 1 | 3 | 0 | 100% |
| Permissions | 6 | 6 | 0 | 0 | 100% |
| Edge / security | 3 | 3 | 0 | 0 | 100% |
| Tenancy / security pack | 5 | 4 | 1 | 0 | 100% |
| **Total** | **44** | **37** | **7** | **0** | **100%** |

**Coverage gates:** Negative 100% ✅ · Positive ≥ 90% ✅ (100%) · Dependency ≥ 90% ✅ (100%) · Tenancy 100% on P0/P1 ✅.
The 7 "Partial" cases are all environment-gated by design (MySQL-only FK/index inspection, single-tenant / single-class / single-category / no-polarity fallbacks) — each degrades to `markTestSkipped` so partial environments stay green.

---

## 3. Cross-Reference Defect Scan

| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 1 | Enum case | DDL ENUM vs FormRequest `in:` | N/A — no enum columns on `ba_class_category_jnt` ✅ |
| 2 | Route registration | Blade `route()` / endpoints vs `routes/*.php` | `store`, `toggleStatus`, `destroy` registered; **no `update` route** while FormRequest carries a non-POST branch → **CM-GAP-03** (proven `test_..._94`) ⚠️ |
| 3 | Gate vs Policy | Controller `Gate::authorize()` vs Policy methods | 8 abilities map to `tenant.behavioural-assessment.class-categories.*` strings ✅ (proven `test_..._54`) |
| 4 | Fillable vs DDL | Model `$fillable` vs DDL columns | fillable = [class_id, category_id, is_active, created_by, updated_by]; `deleted_at` present in DDL but managed columns only — see #6 for the softDeletes gap ✅/⚠️ |
| 5 | Cast vs DDL | Model `$casts` vs DDL type | `is_active` boolean cast over TINYINT ✅ (proven `test_..._01`) |
| 6 | SoftDeletes vs migration | Model trait vs migration `softDeletes()` | Migration adds `deleted_at` but the model omits the `SoftDeletes` trait → `destroy()` HARD-deletes; Policy `restore()`/`forceDelete()` dead → **DATA-BA-CM-01** (proven `test_..._03`, `test_..._43`) ⚠️ |
| 7 | State machine vs impl | doc transitions vs controller | `is_active` Active↔Inactive both implemented in `toggleStatus()` ✅ (proven `test_..._20`) |
| 8 | Validation vs FormRequest | requirement rules vs `rules()` | class_id/category_id required+integer+exists + unique pair all present ✅ (proven `test_..._30..38, 73`) |
| 9 | Error message vs FormRequest | expected vs `messages()` | "This category is already mapped to the selected class." verbatim ✅ (proven `test_..._35`) |
| 10 | Permissions vs Policy/Gates | requirement matrix vs Policy | create/status/delete/setup.viewAny gates enforced (403) ✅ (proven `test_..._51..55`) |
| 11 | Integration FK vs migration | requirement FK vs migration `foreign()` | class_id→sch_classes CASCADE, category_id→ba_categories CASCADE ✅ (proven `test_..._40,41`); **unique index `uq_ba_class_cat` lacks `deleted_at` scope** while the request rule has it → **VAL-BA-CM-02** (proven `test_..._42`) ⚠️ |
| — | Doc vs runtime prefix | DDL/registry `bha_` vs runtime `ba_` | runtime table is `ba_class_category_jnt`; `bha_` name must not exist → **DOC-BA-001** (proven `test_..._02`) ⚠️ |
| — | FormRequest authorize | `authorize()` return | bare `return true;` (mitigated by controller Gate) → **SEC-BA-002** (proven `test_..._92`) ⚠️ |
| — | Activity log | controller/model | no activity log written for mutations (documented absence, proven `test_..._93`) ✅ |

---

## 4. Coverage-Score (by requirement Source)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`) | 6 | 6 | 100% |
| State-Machine transitions (`Screen-SM`) | 3 | 3 | 100% |
| Validation Rules (`Screen-VR`) | 5 | 5 | 100% |
| Integration Points (`Screen-IP` / FK) | 3 | 3 | 100% |
| Permissions (`Screen-PM`) | 6 | 6 | 100% |

Every `Source`-tagged requirement item has ≥ 1 TC. No zero-coverage requirement item.

---

## 5. Known Source Defects (audit-equivalent)

| ID | Layer | Description | Severity | Proving test | Recommendation |
|----|-------|-------------|----------|--------------|----------------|
| DOC-BA-001 | DDL / doc | Spec prefix `bha_` diverges from live `ba_` table name | Low | `test_..._02` | Correct the DDL/registry doc to `ba_` (code is authoritative) |
| DATA-BA-CM-01 | Model / migration | Model omits `SoftDeletes` though migration adds `softDeletes()`; `destroy()` hard-deletes; `deleted_at` unused; Policy `restore()`/`forceDelete()` dead | Medium | `test_..._03`, `test_..._43` | Either add the `SoftDeletes` trait + trash/restore routes, or drop the `softDeletes()`/`deleted_at` migration column and dead Policy abilities |
| VAL-BA-CM-02 | Migration / FormRequest | DB unique index `uq_ba_class_cat` has no `deleted_at` scope while the request unique rule does — divergent scopes | Low | `test_..._42` | Align scopes once the soft-delete decision (DATA-BA-CM-01) is made |
| SEC-BA-002 | FormRequest | `authorize()` returns bare `true` (mitigated by controller Gate) | Low | `test_..._92` | Return a real Policy check in `authorize()` for defense-in-depth |
| CM-GAP-03 | FormRequest / routes | Non-POST (PUT/PATCH) rules branch present but no `update` route → dead branch | Low | `test_..._94` | Remove the dead branch or add the intended update route |
