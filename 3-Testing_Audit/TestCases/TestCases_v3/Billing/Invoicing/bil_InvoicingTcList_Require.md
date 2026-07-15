# Billing → Invoicing — Test Case List & Business Conditions

**Module:** Billing (`BIL`, prefix `bil_`) · **Feature/Screen:** Invoicing (Invoice Generation)
**Primary table:** `bil_tenant_invoices` · **DB scope:** PRIME / CENTRAL (`prime_db`, 127.0.0.1)
**Screen URL:** `GET /billing/billing-management` (default `type=invoicing`, `#invoicing-pane`)
**Controllers:** `BillingManagementController` (real screen) · `InvoiceGeneratorService` (generation) · `InvoicingController` (dead stub, DEV-BIL-004)
**Console:** `prime:generate-invoices` (`GenerateInvoicesCommand`) · **Policy:** `InvoicingPolicy` (gates `prime.invoicing.*`) + `prime.billing-management.*`
**Activity-log events (verbatim):** `Store`, `ToggleStatus` (NOT the tenant `Stored`/`ToggelStatus` set)
**Test style:** Browser Dusk, central base `BillingDuskTestCase` (05_ E21/E22) — no tenant scaffolding.
**Single test file:** `bil_Invoicing_TestCas.php` (48 methods).

---

## 1. Business Conditions

### BC-DB (schema/columns — Source: `DDL-bil_tenant_invoices`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `bil_tenant_invoices` has all 42 DDL columns (id … updated_at) | DDL-bil_tenant_invoices |
| BC-DB-02 | `invoice_no` VARCHAR(50) UNIQUE (`uq_tenantInvoices_invoiceNo`) | DDL |
| BC-DB-03 | Money columns are DECIMAL; date columns are DATE | DDL |
| BC-DB-04 | **No `deleted_at` column exists** (model still declares SoftDeletes) | DDL / Audit-MIG-BIL-001 |
| BC-DB-05 | `bil_tenant_invoicing_modules_jnt` has `tenant_invoice_id`, `module_id` | DDL |
| BC-DB-06 | Audit table column is `tenant_invoicing_id` (code writes `tenant_invoice_id`) | DDL / Audit-DATA-BIL-001 |

### BC-VAL (validation — Source: `BillingManagementController`)
| ID | Condition | Message/Behaviour | Source |
|----|-----------|-------------------|--------|
| BC-VAL-01 | `updateInvoiceRemarks`: `id` required integer | 422 validation error | Controller L758 |
| BC-VAL-02 | `updateInvoiceRemarks`: `remarks` nullable string max:5000 | 422 on overflow | Controller L759 |
| BC-VAL-03 | `store` (generate) requires `ids[]` array | 400 JSON `No plan rate IDs received.` | Controller L610 |
| BC-VAL-04 | Filters are presence-checked only (`!empty()`) — no type/format validation | garbage filters do not error | Screen §Filter / Controller |

### BC-AUTH (permissions — Source: `Screen-PM`, `InvoicingPolicy`, `BillingServiceProvider`)
| ID | Condition | Gate | Source |
|----|-----------|------|--------|
| BC-AUTH-01 | View invoicing tab | `prime.billing-management.viewAny` (Gate::any) | Controller L61 |
| BC-AUTH-02 | Generate invoice | `prime.invoicing.create` / `prime.billing-management.create` | Blade / Controller |
| BC-AUTH-03 | Print / PDF | `prime.invoicing.print` / `prime.invoicing.pdf` | Blade L103/L118 |
| BC-AUTH-04 | View details / remarks | `prime.invoicing.view` / `prime.invoicing.remark` | Blade |
| BC-AUTH-05 | Guest is redirected to `/login` | auth+verified middleware | routes/web.php L323 |
| BC-AUTH-06 | `prime.invoicing.*` gates registered for 10 abilities | Gate::define loop | Provider L67-72 |

### BC-BIZ (business rules — Source: `Screen-BR`, `InvoiceGeneratorService`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `invoice_no` auto-format `INV-YYYYMMDD-NNN` (count today + 1, zero-pad 3) | Screen-BR / Service L78-79 |
| BC-BIZ-02 | `billing_qty = max(min_billing_qty, total_user_qty)` | Screen-BR / Service L87 |
| BC-BIZ-03 | `sub_total = plan_rate × billing_qty` | Screen-BR / Service L88 |
| BC-BIZ-04 | `tax_base = sub_total − discount_amount + extra_charges`; each `tax = base × pct/100` | Service L91-96 |
| BC-BIZ-05 | `total_tax_amount = Σ tax1..tax4` | Service L98 |
| BC-BIZ-06 | `net_payable_amount = sub_total − discount + extra_charges + total_tax` | Service L99 |
| BC-BIZ-07 | `payment_due_date = invoice_date + credit_days` | Service L81-83 |
| BC-BIZ-08 | `total_user_qty` counted inside `Tenancy::initialize/end` on tenant DB | Screen-BR / Service L58-65 |
| BC-BIZ-09 | Generation atomic (`DB::transaction`): invoice + module junction + GENERATED audit + schedule flag | Service L72-174 |
| BC-BIZ-10 | One-time constraint: `bill_generated=1` blocks re-invoicing | Screen-BR / Service L37 |
| BC-BIZ-11 | Initial status seeded from dropdown key `bil_tenant_invoices.status.invoice_status` ordinal 1 | Service L101-103 |
| BC-BIZ-12 | Activity-log event string on generate/print/remark = `Store` | Controller / Service |
| BC-BIZ-13 | `currency` defaults to `INR` (ISO 4217, CHAR(3)) | DDL / Screen-BR |

### BC-SM (status lifecycle — Source: `Screen-SM`)
| ID | State → Trigger → Next | Notes | Source |
|----|------------------------|-------|--------|
| BC-SM-01 | (new) → generate → `PENDING` | via dropdown ordinal | Screen-SM |
| BC-SM-02 | `PENDING` → partial payment → `PARTIALLY_PAID` | no dedicated endpoint on this screen | Screen-SM |
| BC-SM-03 | `PENDING`/`PARTIALLY_PAID` → full payment → `PAID` | driven from payments feature | Screen-SM |
| BC-SM-04 | `PENDING` → due date passed → `OVERDUE` | **no automated detection** | Screen-SM (gap) |
| BC-SM-05 | `PENDING` → cancel → `CANCELLED` | **no dedicated cancel endpoint** | Screen-SM (gap) |

### BC-INT / BC-REF (FK integrity — Source: `DDL`, `Screen-IP`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `tenant_id` → `prm_tenant` ON DELETE CASCADE | DDL |
| BC-REF-02 | `tenant_plan_id` → `prm_tenant_plan_jnt` ON DELETE CASCADE | DDL |
| BC-REF-03 | `billing_cycle_id` → `prm_billing_cycles` ON DELETE RESTRICT | DDL |
| BC-INT-01 | `prm_tenant_plan_billing_schedule.generated_invoice_id` back-refs invoice | DDL |
| BC-REF-04 | modules_jnt DDL FK targets wrong table/column name | DDL / Audit (DEV-BIL-008) |

### BC-CFG / BC-EDG
| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | `prime:generate-invoices` exposes `--as-of`, `--dry-run` | Command L16-18 |
| BC-EDG-01 | `invoiceDetails` invalid id → `findOrFail` 404 | Controller L700 |
| BC-EDG-02 | `store` with empty `ids[]` handled gracefully | Controller L610 |
| BC-EDG-03 | `date_range` parsed on ` - ` (space-dash-space); defaults to today | Controller L242-252 |

### Known Source Defects (audit-equivalent DEV-BIL-###)
| DEV | Audit | Sev | Summary | Proving test |
|-----|-------|-----|---------|--------------|
| DEV-BIL-001 | MIG-BIL-001 | P0 | SoftDeletes declared but `bil_tenant_invoices` has no `deleted_at` → trashed queries throw | `test_..._02` |
| DEV-BIL-002 | DATA-BIL-002 | P0 (remediated) | Audit claimed phantom `invoice_amount` in `$fillable`; NOT in current source | `test_..._03` (regression guard) |
| DEV-BIL-003 | DATA-BIL-001 | P0 | Audit table column `tenant_invoicing_id` vs code `tenant_invoice_id` | `test_..._07` |
| DEV-BIL-004 | Layer-4 | P2 | `InvoicingController` dead stub (unrouted, non-existent views) | `test_..._81` |
| DEV-BIL-008 | Layer-1 | P2 | modules_jnt DDL FK/unique-key wrong table/column name | `test_..._41` |
| DEV-BIL-005 | doc | P3 | DDL comment "invoice_date = day after billing_end_date" vs impl = generation date (requirement field table agrees with impl) | documented (Gap) |

---

## 2. Test Case List

### Positive (`TC-P`)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01 | DDL | Schema/model/config truth | table + 42 cols + relations | `_01` | Full |
| TC-P02 | BC-DB-03 | DDL | Money/date casts correct | decimal/date casts | `_05` | Full |
| TC-P03 | BC-DB-05 | DDL | Junction schema + model | fillable + cols | `_06` | Full |
| TC-P04 | BC-DB-02 | DDL | invoice_no UNIQUE index | unique index present | `_08` | Full |
| TC-P05 | BC-CFG-01 | Command | Generate command registered | present | `_09` | Full |
| TC-P06 | BC-BIZ-01 | Service | invoice_no auto-format | `INV-YYYYMMDD-NNN` | `_10` | Full |
| TC-P07 | BC-BIZ-06 | Service | net_payable formula holds | equals derived | `_11` | Full |
| TC-P08 | BC-BIZ-02 | Service | billing_qty = max(...) | matches | `_12` | Full |
| TC-P09 | BC-BIZ-07 | Service | payment_due_date = inv+credit | matches | `_13` | Full |
| TC-P10 | BC-BIZ-13 | DDL | currency ISO code | 3-letter | `_14` | Full |
| TC-P11 | BC-BIZ-05 | Service | total_tax = Σ tax lines | matches | `_15` | Full |
| TC-P12 | BC-CFG-01 | Command | dry-run executes | exit 0 | `_16` | Full |
| TC-P13 | BC-BIZ-11 | Service | status seeded from dropdown key | key referenced | `_20` | Full |
| TC-P14 | BC-AUTH-01 | Screen | Invoicing tab loads with filters | pane+filters | `_60` | Full |
| TC-P15 | BC-BIZ-10 | Blade | data_type options present | both options | `_61` | Full |
| TC-P16 | BC-AUTH | Blade | table headers present | 4 headers | `_62` | Full |
| TC-P17 | BC-EDG-03 | Controller | filter submit renders | table shown | `_63` | Full |
| TC-P18 | BC-AUTH | Blade | action menu or empty state | menu/empty | `_64` | Full |
| TC-P19 | UX | Blade | pagination or empty state | rows/pager/empty | `_65` | Full |
| TC-P20 | BC-INT-01 | DDL | schedule back-reference cols | present | `_42` | Full |
| TC-P21 | BC-REF-01/03 | DDL | FKs reference prm_* tables | correct targets | `_40` | Full |
| TC-P22 | BC-AUTH-06 | Provider | prime.invoicing.* gates registered | all present | `_50` | Full |
| TC-P23 | BC-AUTH-01 | Controller | prime.billing-management.* gates exist | present | `_51` | Full |
| TC-P24 | BC-AUTH | Policy | InvoicingPolicy methods exist | 10 methods | `_52` | Full |
| TC-P25 | BC-INT | routes | invoice-details route registered | present | `_43` | Full |
| TC-P26 | BC-EDG | routes | toggle-status route registered | present | `_72` | Full |
| TC-P27 | BC-EDG | routes | print route registered | present | `_73` | Full |
| TC-P28 | BC-CFG-01 | Command | command options `--as-of/--dry-run` | present | `_80` | Full |
| TC-P29 | BC-BIZ-08 | Service | generation wraps count in tenancy | init+end | `_91` | Full |
| TC-P30 | BC-SM-01 | Service | status populated once generated | not null | `_21` | Full |

### Negative (`TC-N`)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-VAL-01 | Controller | remarks update without id | 422/denied | `_30` | Full |
| TC-N02 | BC-VAL-02 | Controller | remarks over 5000 chars | 422/denied | `_31` | Full |
| TC-N03 | BC-VAL-03 | Controller | generate without ids[] | 400/denied | `_32` | Full |
| TC-N04 | BC-VAL-04 | Controller | garbage filters do not error | page renders | `_33` | Full |
| TC-N05 | BC-AUTH-05 | routes | guest redirected to login | /login | `_53` | Full |
| TC-N06 | BC-AUTH-05 | routes | unauth HTTP index denied | 302/403/404 | `_54` | Full |
| TC-N07 | BC-EDG-01 | Controller | invoice-details invalid id | 404/denied | `_70` | Full |
| TC-N08 | BC-EDG-02 | Controller | generate empty ids[] | 400/200 graceful | `_71` | Full |
| TC-N09 | BC-DB-04 | DDL | trashed query throws (no deleted_at) | throws | `_02` | Full |
| TC-N10 | BC-VAL | Security | invoice-details requires permission | no HTML leak | `_93` | Full |

### Dependency / Defect (`TC-D`)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | B | BC-DB-04 | Audit | SoftDeletes without deleted_at (DEV-BIL-001) | column absent + throws | `_02` | Full |
| TC-D02 | — | BC-DB-06 | Audit | audit-log column mismatch (DEV-BIL-003) | documented | `_07` | Full |
| TC-D03 | — | — | Audit | fillable no phantom (DEV-BIL-002 guard) | fillable ⊆ DDL | `_03` | Full |
| TC-D04 | C | BC-REF-03 | DDL | billing_cycle_id RESTRICT | FK target | `_40` | Full |
| TC-D05 | E | BC-BIZ-08 | Service | cross-DB student count | init/end | `_91` | Full |
| TC-D06 | — | BC-REF-04 | Audit | modules_jnt FK target defect (DEV-BIL-008) | documented | `_41` | Full |
| TC-D07 | — | Layer-4 | Audit | InvoicingController dead stub (DEV-BIL-004) | unrouted | `_81` | Full |

### Security / Tenancy (`TC-S` / `TC-T`)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-T01 | BC-BIZ-08 | Service | central-scoped (no tenant scaffolding) | prm_* present | `_90` | Full |
| TC-S01 | Security | Blade | remarks not raw-echoed (XSS) | escaped | `_92` | Full |
| TC-S02 | BC-AUTH-04 | Controller | details endpoint permission-gated | no leak | `_93` | Full |
| TC-S03 | BC-AUTH-05 | routes | guest redirect | /login | `_53` | Full |

---

## 3. Test Method Index (48 methods)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_invoicing_01_schema_model_and_configuration_are_correct` | TC-P01 | Config truth | 01-09 |
| 2 | `test_invoicing_02_softdeletes_without_deleted_at_column_defect` | TC-N09/TC-D01 | Defect/Schema | 01-09 |
| 3 | `test_invoicing_03_fillable_has_no_phantom_columns` | TC-D03 | Defect guard | 01-09 |
| 4 | `test_invoicing_04_model_declares_expected_traits` | TC-P01 | Config | 01-09 |
| 5 | `test_invoicing_05_casts_cover_money_and_date_columns` | TC-P02 | Config | 01-09 |
| 6 | `test_invoicing_06_modules_junction_schema_and_model` | TC-P03 | Config | 01-09 |
| 7 | `test_invoicing_07_audit_log_table_column_name_mismatch_defect` | TC-D02 | Defect | 01-09 |
| 8 | `test_invoicing_08_invoice_no_unique_index_present` | TC-P04 | Config | 01-09 |
| 9 | `test_invoicing_09_generate_command_is_registered` | TC-P05 | Config | 01-09 |
| 10 | `test_invoicing_10_invoice_no_follows_auto_format` | TC-P06 | BC-BIZ | 10-19 |
| 11 | `test_invoicing_11_net_payable_amount_formula_holds` | TC-P07 | BC-BIZ | 10-19 |
| 12 | `test_invoicing_12_billing_qty_is_max_of_min_and_total_user` | TC-P08 | BC-BIZ | 10-19 |
| 13 | `test_invoicing_13_payment_due_date_equals_invoice_date_plus_credit_days` | TC-P09 | BC-BIZ | 10-19 |
| 14 | `test_invoicing_14_currency_is_three_letter_iso_code` | TC-P10 | BC-BIZ | 10-19 |
| 15 | `test_invoicing_15_total_tax_amount_equals_sum_of_tax_lines` | TC-P11 | BC-BIZ | 10-19 |
| 16 | `test_invoicing_16_generate_command_dry_run_executes` | TC-P12 | BC-BIZ | 10-19 |
| 17 | `test_invoicing_20_status_dropdown_key_is_used` | TC-P13 | BC-SM | 20-29 |
| 18 | `test_invoicing_21_status_values_within_documented_set` | TC-P30 | BC-SM | 20-29 |
| 19 | `test_invoicing_30_remarks_update_requires_id` | TC-N01 | BC-VAL | 30-39 |
| 20 | `test_invoicing_31_remarks_update_rejects_overlong_text` | TC-N02 | BC-VAL | 30-39 |
| 21 | `test_invoicing_32_generate_store_requires_ids_array` | TC-N03 | BC-VAL | 30-39 |
| 22 | `test_invoicing_33_filters_have_no_server_side_validation` | TC-N04 | BC-VAL | 30-39 |
| 23 | `test_invoicing_40_foreign_keys_reference_prime_tables` | TC-P21/TC-D04 | BC-REF | 40-49 |
| 24 | `test_invoicing_41_modules_junction_ddl_fk_target_name_defect` | TC-D06 | Defect | 40-49 |
| 25 | `test_invoicing_42_generated_invoice_backreference_column_exists` | TC-P20 | BC-INT | 40-49 |
| 26 | `test_invoicing_43_invoice_details_endpoint_registered` | TC-P25 | BC-INT | 40-49 |
| 27 | `test_invoicing_50_prime_invoicing_gates_registered` | TC-P22 | BC-AUTH | 50-59 |
| 28 | `test_invoicing_51_billing_management_gates_backing_the_tab_exist` | TC-P23 | BC-AUTH | 50-59 |
| 29 | `test_invoicing_52_invoicing_policy_methods_exist` | TC-P24 | BC-AUTH | 50-59 |
| 30 | `test_invoicing_53_guest_is_redirected_to_login` | TC-N05/TC-S03 | BC-AUTH | 50-59 |
| 31 | `test_invoicing_54_index_requires_authentication_http` | TC-N06 | BC-AUTH | 50-59 |
| 32 | `test_invoicing_55_action_buttons_gated_by_permission` | TC-P14 | BC-AUTH | 50-59 |
| 33 | `test_invoicing_60_invoicing_tab_loads_with_filters` | TC-P14 | UI/UX | 60-69 |
| 34 | `test_invoicing_61_data_type_filter_options_present` | TC-P15 | UI/UX | 60-69 |
| 35 | `test_invoicing_62_table_headers_present` | TC-P16 | UI/UX | 60-69 |
| 36 | `test_invoicing_63_data_type_filter_submits` | TC-P17 | UI/UX | 60-69 |
| 37 | `test_invoicing_64_action_menu_or_empty_state` | TC-P18 | UI/UX | 60-69 |
| 38 | `test_invoicing_65_pagination_or_empty_state` | TC-P19 | UI/UX | 60-69 |
| 39 | `test_invoicing_70_invoice_details_invalid_id_is_not_found` | TC-N07 | BC-EDG | 70-79 |
| 40 | `test_invoicing_71_generate_store_empty_ids_array` | TC-N08 | BC-EDG | 70-79 |
| 41 | `test_invoicing_72_toggle_status_route_registered` | TC-P26 | BC-EDG | 70-79 |
| 42 | `test_invoicing_73_print_route_registered` | TC-P27 | BC-EDG | 70-79 |
| 43 | `test_invoicing_80_generate_command_signature_has_options` | TC-P28 | BC-CFG | 80-89 |
| 44 | `test_invoicing_81_invoicing_controller_is_a_dead_stub` | TC-D07 | Defect | 80-89 |
| 45 | `test_invoicing_90_module_is_central_prime_scoped` | TC-T01 | Tenancy | 90-99 |
| 46 | `test_invoicing_91_generation_wraps_student_count_in_tenancy` | TC-P29/TC-D05 | Tenancy | 90-99 |
| 47 | `test_invoicing_92_remarks_stored_value_is_escaped_on_render` | TC-S01 | Security | 90-99 |
| 48 | `test_invoicing_93_invoice_details_requires_permission_when_authenticated` | TC-S02/TC-N10 | Security | 90-99 |
