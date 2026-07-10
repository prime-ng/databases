# Invoicing (Invoice Generation) — Gap Analysis (`bil_InvoicingGAPANALYSIS_Require`)

Manual TC ↔ Dusk method mapping, coverage %, cross-reference defect scan, and requirement coverage score.
Legend: **Full** = automated end-to-end · **Partial** = automated but environment-gated / defensive-skip · **Gap** = manual only.

---

## 1. Coverage Mapping

### Positive

| TC ID | Description | V1 | V2 | Coverage |
|-------|-------------|----|----|----------|
| TC-P01 | Schema/model config | `test_01` | `test_01`,`test_02` | Full |
| TC-P02 | Audit-log FK (DATA-BIL-001) | `test_02` | `test_03` | Full |
| TC-P03 | SoftDeletes guard (MIG-BIL-001) | `test_03` | `test_05` | Full |
| TC-P04 | Tab loads with filters | `test_04` | `test_30` | Partial (module-enabled + live DB) |
| TC-P05 | Rows or empty state | `test_05` | `test_61` | Partial |
| TC-P06 | Invoice number format | `test_10` | `test_10` | Full |
| TC-P07 | Financial formula | `test_11` | `test_11`,`test_13` | Full |
| TC-P08 | billing_qty max | `test_12` | `test_14` | Full |
| TC-P09 | discount/tax_base/total_tax | — | `test_12` | Full |
| TC-P10 | payment_due_date | — | `test_15` | Full |
| TC-P11 | Routes registered | — | `test_04` | Partial (in-process route load) |
| TC-P12 | Column headers | — | `test_60` | Partial |
| TC-P13 | Pagination container | — | `test_62` | Partial |
| TC-P14..P18 | Filters (5 modes) | — | `test_31`,`test_32`,`test_33`,`test_34`,`test_35` | Partial |
| TC-P19 | status = dropdown id (D37) | `test_20` | `test_20` | Partial (defensive skip if no rows) |

### State Machine

| TC ID | Description | V2 | Coverage |
|-------|-------------|----|----------|
| TC-SM01 | Initial status PENDING (ordinal 1) | `test_20` | Partial (defensive) |
| TC-SM02 | No cancel/transition endpoint | `test_21` | Full |
| TC-SM03 | PENDING→PARTIALLY_PAID→PAID (payments) | — | **Gap** (cross-module — Payment feature) |
| TC-SM04 | Illegal PAID→PENDING not guarded (BUG-BIL-010) | — | **Gap** (documented DEV) |

### Negative

| TC ID | Description | V1 | V2 | Coverage |
|-------|-------------|----|----|----------|
| TC-N01 | remarks requires id | `test_30` | `test_36` | Partial (defensive) |
| TC-N02 | remarks > 5000 rejected | — | `test_37` | Partial (defensive) |
| TC-N03 | store rejects non-array ids | — | `test_41` | Partial (defensive) |
| TC-N04 | Guest → /login (index) | `test_50` | `test_50` | Full |
| TC-N05 | Detail endpoint requires auth | `test_60` | `test_51`,`test_90` | Full |
| TC-N06 | Non super-admin forbidden | — | `test_52` | Partial (defensive) |
| TC-N07 | invoice-details bogus id → 404 | `test_60` | `test_44` | Partial (defensive) |
| TC-N08 | subscription-details bogus id → 404 | — | `test_45` | Partial (defensive) |

### Dependency / Edge / Security

| TC ID | Description | V1 | V2 | Coverage |
|-------|-------------|----|----|----------|
| TC-D01 | billing_cycle_id RESTRICT | `test_41` | `test_42` | Partial (defensive) |
| TC-D02 | tenant_id/plan_id CASCADE | — | `test_42` | Partial (defensive) |
| TC-D03 | referenced tables exist | — | `test_43` | Partial (defensive) |
| TC-D04 | modules junction shape | — | `test_71` | Partial (defensive) |
| TC-D05 | generate array contract (BUG-BIL-011) | `test_40` | `test_40` | Partial (defensive) |
| TC-EDG01 | default (today) range renders | — | `test_70` | Partial |
| TC-S01 | invoice-details requires auth | `test_60` | `test_90` | Full |
| TC-S02 | injection-shaped filter safe | — | `test_91` | Partial |

---

## 2. Coverage Summary

| Class | Total | Full | Partial | Gap | % (Full+Partial automated) |
|-------|-------|------|---------|-----|-----------------------------|
| Positive | 19 | 8 | 11 | 0 | 100% |
| State machine | 4 | 1 | 1 | 2 | 50% |
| Negative | 8 | 2 | 6 | 0 | 100% |
| Dependency | 5 | 0 | 5 | 0 | 100% |
| Edge | 1 | 0 | 1 | 0 | 100% |
| Security | 2 | 1 | 1 | 0 | 100% |
| **Total** | **39** | **12** | **25** | **2** | **94.9% automated** |

Targets: Negative 100% ✅ · Positive ≥90% ✅ (100%) · Dependency ≥90% ✅ (100%). The 2 Gaps are cross-module payment-driven status transitions (belong to the Payment/InvoicingPayment feature) and the documented BUG-BIL-010 illegal transition — both recorded as DEV items, not automatable within this read/report screen.

---

## 3. Coverage-Score by Requirement Section (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`: invoice#, qty, sub_total, tax, net, due date, atomic, bill-once, currency) | 8 | 9 | 89% |
| State-Machine transitions (`Screen-SM`: create→PENDING, →PARTIAL, →PAID, →OVERDUE, →CANCELLED) | 2 | 5 | 40% (rest cross-module/no-endpoint) |
| Validation Rules (`Screen-VR`: remarks id/len, ids array, filter presence) | 3 | 3 | 100% |
| Integration Points (`Screen-IP`: tenant-DB count, plan-rate, schedule, modules-jnt, FKs) | 5 | 5 | 100% |
| Permissions (`Screen-PM`: viewAny/create/view/remark/print/pdf/email/status) | 3 | 8 | 38% (guest+gate+detail auth automated; per-permission button matrix is manual due to DEV-BIL-INV-001) |

> Every `Source`-tagged BC maps to ≥1 TC. Zero-coverage items with an explicit reason: Screen-SM payment transitions (cross-module Payment feature), Screen-SM OVERDUE (no automated detection in source), per-permission button visibility (blocked by the `prime.invoicing.*` vs `prime.billing-management.*` mismatch — DEV-BIL-INV-001).

---

## 4. Cross-Reference Defect Scan (11 checks)

| # | Check | Compared | Finding | Defect |
|---|-------|----------|---------|--------|
| 1 | Enum case | DDL `status` values vs stored value | Code stores a **Dropdown id** into `status VARCHAR(20)` (D37), not the enum literal 'PENDING' | Documented (D37 / BC-DB-07) |
| 2 | Route registration | Blade `route('central.billing.billing-management.view')` vs controller | Controller has **no `view()`** method; central billing block registered **3×** | **BUG-BIL-013 / BUG-BIL-014** (P2) |
| 3 | Gate vs Policy | Controller `Gate::authorize('prime.billing-management.*')` vs `BillingManagementPolicy` | Policy methods present and aligned | OK |
| 4 | Fillable vs DDL | `BilTenantInvoice $fillable` vs DDL columns | No phantom `invoice_amount`, no duplicated block | **DATA-BIL-002 remediated** ✅ |
| 5 | Cast vs DDL | Model casts vs DDL types | boolean/date/decimal casts align with DDL | OK |
| 6 | Service delegation | Controller vs Service | Logic lives in the controller (`generateInvoiceForOrganization`) — no service layer for this screen | Noted (God-controller, Audit L4) |
| 7 | State machine vs impl | Screen SM vs controller | Only create→PENDING is implemented here; PARTIAL/PAID via payments; OVERDUE has no detection; CANCELLED has no endpoint | **BUG-BIL-010** + Screen gaps |
| 8 | Validation vs FormRequest | Screen rules vs controller `validate()` | remarks id/len enforced; filters presence-only (no type/format rules) | Noted (thin filter validation) |
| 9 | Error message vs source | Expected vs controller strings | "No plan rate IDs received.", "No billing schedule found.", "Remarks updated successfully!" verbatim | OK |
| 10 | Permissions vs Policy/Gates | Blade `@can` vs Controller/Policy | **Blade gates buttons on `prime.invoicing.*`; controller/policy enforce `prime.billing-management.*`** — buttons show/hide on a different permission than the one enforced | **DEV-BIL-INV-001 (P1, NEW)** |
| 11 | Integration FK vs migration | Screen FKs vs DDL `CONSTRAINT` | tenant CASCADE, plan CASCADE, cycle RESTRICT match; audit-log DDL column name (`tenant_invoicing_id`) disagrees with code (`tenant_invoice_id`) and with prime_db_v4 (`tenant_invoice_id`) — **DDL-vs-DDL inconsistency** | **DATA-BIL-001** (code remediated; DDL `Billing_DDL_v1.sql` still inconsistent) |

### Discovered / carried DEV defects

| ID | Severity | Description | Status in current source | Proving/док |
|----|----------|-------------|--------------------------|-------------|
| MIG-BIL-001 | P0 | SoftDeletes model vs DDL without `deleted_at` | **Present** (dev hand-patched) | V1 `test_03`, V2 `test_05` (schema guard fails on DDL-only build) |
| DATA-BIL-001 | P0 | Audit-log FK column mismatch | **Code remediated** to `tenant_invoice_id`; `Billing_DDL_v1.sql` still says `tenant_invoicing_id` (DDL bug) | V1 `test_02`, V2 `test_03` |
| DATA-BIL-002 | P0 | Phantom `invoice_amount` + duplicate fillable | **Remediated** | V1 `test_01`, V2 `test_02` |
| BUG-BIL-011 | P1 | bool/array return contract | **Remediated** (array everywhere) | V1 `test_40`, V2 `test_40` |
| SEC-BIL-005 | P1 | Tenancy init/end without try/finally | **Remediated** (try/finally, before tx) | Documented (source lines 668-675) |
| BUG-BIL-015 | P1 | Invoice-number race | **Mitigated** (unique-collision retry ≤5) | Documented (source lines 677-814) |
| BUG-BIL-010 | P1 | Status from request, not derived | Payment path; **present** | BC-SM-03/06 (manual) |
| **DEV-BIL-INV-001** | **P1 (NEW)** | Blade `prime.invoicing.*` vs controller/policy `prime.billing-management.*` permission-key mismatch | **Present** | Cross-Ref #10 (documented; button matrix un-automatable until fixed) |
| BUG-BIL-013 | P2 | Broken `billing-management.view` route (no controller method) | Present | Cross-Ref #2 |
| BUG-BIL-014 | P2 | Central billing route block registered 3× | Present | Cross-Ref #2 |

---

## 5. Remaining Partial-Coverage Notes / Limitations

1. **Browser + endpoint tests are environment-gated:** they require the Billing module enabled in `modules_statuses.json`, `APP_ENV=testing`, a live central DB, and the central dev server on `http://127.0.0.1:8000`. Defensive `markTestSkipped` keeps them green in partial environments.
2. **Generation-path assertions are defensive** (`try/catch` + `markTestSkipped`): full generation needs `prm_tenant_plan_billing_schedule` + `prm_tenant_plan_rates` + a reachable tenant DB. The suite asserts the store **contract** (array envelope, non-array rejection, formula math) rather than fabricating cross-DB fixtures.
3. **Financial-formula and invoice-number tests are pure specification tests** (no DB) — they lock the exact controller math to catch regressions without requiring a generated invoice.
4. **Cross-module status transitions (SM03/SM04)** belong to the Payment / InvoicingPayment feature and are intentionally out of scope here (recorded as Gaps + DEV BUG-BIL-010).
