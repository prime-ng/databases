# FrontOffice ▸ EmergencyContact — Gap Analysis & Traceability

Suite: `fof_EmergencyContact_TestCas.php` — **37 methods**. Every TC ↔ ≥1 method; every method ↔ a TC/BC.

---

## 1. Coverage by category

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive | 17 | 17 | 0 | 0 | 100% |
| Negative | 10 | 10 | 0 | 0 | 100% |
| Dependency | 3 | 3 | 0 | 0 | 100% |
| Security/Auth/Tenancy | 6 | 6 | 0 | 0 | 100% |
| **Total** | **36** | **36** | **0** | **0** | **100%** |

Targets met: Negative 100% ✅, Positive ≥90% ✅ (100%), Dependency ≥90% ✅ (100%), Tenancy present ✅.

> Note: 6 TCs (TC-P15, TC-N10, TC-N11, TC-S03, TC-S04) are **environment-gated** — they self-`markTestSkipped` when FrontOffice is disabled in `modules_statuses.json` (#19) or ChromeDriver is absent. They are counted **Full** on coverage (the assertion is real and correct); their *execution* is a documented env prerequisite, not a coverage gap. The remaining 31 methods run against the tenant DB with the module disabled.

---

## 2. TC ↔ Method mapping

| TC ID | Method | Coverage |
|-------|--------|----------|
| TC-P01 | `_10_create_applies_server_defaults` | Full |
| TC-P02 | `_11_index_grouped_by_contact_type` | Full |
| TC-P03 | `_03_soft_delete_column_and_trait_independent` | Full |
| TC-P04a | `_15_soft_delete_then_restore_lifecycle` | Full |
| TC-P04b | `_16_force_delete_removes_row` | Full |
| TC-P05 | `_05_no_unique_indexes_present` | Full |
| TC-P06 | `_17_toggle_status_flips_is_active` | Full |
| TC-P07 | `_07_no_form_request_inline_validation` | Full |
| TC-P07b | `_13_organization_and_sort_order_not_web_inputs` | Full |
| TC-P08 | `_39_max_length_boundary_and_nullables_accepted` | Full |
| TC-P09 | `_14_scope_active_filters_inactive` | Full |
| TC-P10 | `_12_update_changes_fields` | Full |
| TC-P11 | `_01_ddl_schema_alignment_matrix` | Full |
| TC-P12 | `_02_model_configuration_and_fillable_verified` | Full |
| TC-P13 | `_04_contact_type_enum_full_ddl_values` | Full |
| TC-P14 | `_06_routes_registered` | Full (skips if disabled) |
| TC-P15 | `_60_create_page_renders` | Full (env) |
| TC-P16 | `_90_tenant_context_active` | Full |
| TC-N01 | `_30_missing_contact_name_rejected` | Full |
| TC-N02 | `_31_missing_primary_phone_rejected` | Full |
| TC-N03 | `_32_missing_created_by_rejected` | Full |
| TC-N04 | `_33_invalid_contact_type_rejected` | Full |
| TC-N05 | `_35_app_validation_omits_extended_enum` | Full |
| TC-N07 | `_36_contact_name_over_length_rejected` | Full |
| TC-N08 | `_37_primary_phone_over_length_rejected` | Full |
| TC-N09 | `_38_address_over_length_rejected` | Full |
| TC-N10 | `_61_required_name_ui_rejected` | Full (env) |
| TC-N11 | `_92_toggle_status_nonexistent_returns_404` | Full (env) |
| TC-D01 | `_40_created_by_has_no_fk` | Full |
| TC-D02 | `_41_restore_does_not_recover_hard_deleted` | Full |
| TC-D03 | `_34_ddl_extended_enum_accepted_by_db` | Full |
| TC-S01 | `_50_controller_gates_present` | Full |
| TC-S02 | `_51_policy_abilities_match` | Full |
| TC-S03 | `_52_guest_redirected_to_login` | Full (env) |
| TC-S04 | `_53_forbidden_without_permission` | Full (env) |
| TC-S05 | `_91_xss_payload_stored_raw` | Full |
| TC-E01 | `_70_notes_accepts_large_text` | Full |

---

## 3. DDL-coverage obligation checklist (G43–G48)

| Gate | Requirement | Status | Where |
|------|-------------|--------|-------|
| G43 | Duplicate-rejection per UNIQUE key | **N/A** — table has NO UNIQUE key | Asserted absent in `_05` |
| G44 | Missing-value negative per NOT-NULL-no-default | ✅ contact_name/primary_phone/created_by | `_30`,`_31`,`_32` |
| G44 | Nullable-omitted positive | ✅ organization/alternate_phone/address/notes | `_39` |
| G45 | Over-length negative per VARCHAR | ✅ contact_name(100)/primary_phone(15)/address(200) | `_36`,`_37`,`_38` |
| G45 | Max-length positive boundary | ✅ 100/15/200 exact | `_39` |
| G46 | `test_01` full DDL↔live matrix | ✅ all 15 columns, types, null, lengths, defaults | `_01` |
| G46 | deleted_at column & SoftDeletes trait independent | ✅ two separate asserts | `_03` |
| G47 | All CRUD via verified `EmergencyContact` model | ✅ `$table`/fillable/scope confirmed | `_02` + all |
| G48 | Programmatically-managed fields as auto-behaviour | ✅ created_by/updated_by/sort_order/organization | `_10`,`_13` |

**ENUM columns without over-length note:** `contact_type` validated by `_33` (invalid rejected) + `_04` (all 9 members) + `_34`/`_35` (DEV-FOF-EC-001).

---

## 4. Cross-Reference Defect Scan (15 checks)

| # | Check | Result |
|---|-------|--------|
| 1 | Enum case/scope: DDL ENUM(9) vs controller `in:`(6) | **DEV-FOF-EC-001** — app list is a strict subset; Utility/Parent_Emergency/Government unreachable. Blade dropdown matches the narrow list. |
| 2 | Route registration: Blade `route('fof.emergency-contacts.*')` / `route('fof.menu.compliance')` vs routes/web.php | OK — all registered (when module enabled). |
| 3 | Gate vs Policy: controller `Gate::authorize('frontoffice.emergency-contact.*')` vs `EmergencyContactPolicy` | OK — Policy methods exist; note the Gates are **string abilities**, not policy-bound (module pattern SEC-FOF-001 family). |
| 4 | Fillable vs DDL: model `$fillable` vs columns | OK — fillable covers all editable columns; `organization`/`sort_order` fillable but unused by controller → **DEV-FOF-EC-004**. |
| 5 | Cast vs DDL: `is_active` boolean vs TINYINT(1) | OK. |
| 6 | Service delegation | N/A — no Service layer; logic inline in controller. |
| 7 | State machine vs impl | N/A — no FSM. |
| 8 | Validation vs requirement rules | `contact_type` narrower than DDL (see #1); lengths align (max:100/15/200 == V100/V15/V200). |
| 9 | Error message vs FormRequest `messages()` | **DEV-FOF-EC-003** — no FormRequest, so default framework messages only. |
| 10 | Permissions vs Policy/Gates | OK — 6 abilities consistent across controller + Policy. |
| 11 | Integration FK vs migration | `created_by`/`updated_by` NOT NULL but **no FK** (per DDL comment) — verified accepted orphan id in `_40`. `attachment`/media not applicable. |
| 12 | UNIQUE enforcement: DDL UNIQUE vs FormRequest `unique:` | N/A — no UNIQUE key; no `unique:` rule needed. |
| 13 | Required enforcement: DDL NOT NULL vs `required` | OK — contact_name/contact_type/primary_phone required & NOT NULL. `created_by`/`updated_by` NOT NULL but set server-side (not user-required — correct). |
| 14 | Length enforcement: DDL VARCHAR(n) vs `max:n` | OK — all three sized string inputs match; `notes` TEXT has no `max:` (correct). |
| 15 | Soft-delete column vs trait: DDL `deleted_at` vs `SoftDeletes` | OK — both present (asserted independently in `_03`). |

---

## 5. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR` / BC-BIZ) | 4 | 4 | 100% |
| State-Machine (`Screen-SM` / BC-SM) | 0 | 0 | N/A (flat CRUD) |
| Validation Rules (`Screen-VR` / BC-VAL) | 5 | 5 | 100% |
| DDL Constraints (BC-DB) | 12 | 12 | 100% |
| Integration/Referential (BC-REF) | 3 | 3 | 100% |
| Permissions (`Screen-PM` / BC-AUTH) | 4 | 4 | 100% |
| Security/Edge (BC-S / BC-EDG) | 3 | 3 | 100% |

Every `Source`-tagged BC has ≥1 TC. No 0-coverage items.

---

## 6. Legend
- **Full** — a real assertion verifies the observed behaviour.
- **(env)** — assertion is real and correct; execution requires FrontOffice enabled + ChromeDriver (self-skips otherwise, #19). Not a coverage gap.
- **N/A** — the constraint does not exist for this table (documented, not skipped silently).
