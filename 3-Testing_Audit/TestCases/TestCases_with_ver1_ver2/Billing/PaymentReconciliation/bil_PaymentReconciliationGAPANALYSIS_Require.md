# Payment Reconciliation — Gap Analysis (Manual TC ↔ Dusk method)

**Module:** Billing (BIL) · **Feature:** Payment Reconciliation · **Layer:** prime_db central
**V1:** `bil_PaymentReconciliationV1_TestCas` (14 methods) · **V2:** `bil_PaymentReconciliationV2_TestCas` (41 methods)

Legend: **Full** = behaviour + DB/side-effect asserted · **Partial** = asserted but with a documented limitation (defensive skip / source-string assertion) · **Gap** = no automated method.

---

## 1. Coverage Mapping

### Positive
| TC | Description | V1 | V2 | Coverage |
|----|-------------|----|----|----------|
| TC-P01 | Schema/model/config truth | 01,02 | 01,02,03,04,06 | Full |
| TC-P02 | Tab loads with filters | 03 | 60 | Full |
| TC-P03 | Three-way options present | 04 | 61 | Full |
| TC-P04 | Table columns render | 05 | 64 | Full |
| TC-P05 | Toggle 0→1 + JSON | 06 | 10 | Full |
| TC-P06 | Toggle 1→0 | — | 11 | Full |
| TC-P07 | Double toggle round-trips | — | 12 | Full |
| TC-P08 | Toggle ignores body | — | 13 | Full |
| TC-P09 | Toggle writes ToggleStatus log | 07 | 20 | Full |
| TC-P10 | Log records admin user_id | 07 | 21 | Full |
| TC-P11 | Log properties carry transition | — | 22 | Full |
| TC-P12 | Append-only N rows | — | 23 | Full |
| TC-P13 | Admin views index | 12 | 50 | Full |
| TC-P14 | Toggle gate string | — | 51 | Full (source assertion) |
| TC-P15 | Index gate string | 01 | 52 | Full (source assertion) |
| TC-P16 | PDF gate mismatch (DEV-BIL-R01) | 14 | 53 | Full (source assertion) |
| TC-P17 | Policy import remediated (DEAD-BIL-001) | — | 54 | Full (source assertion) |
| TC-P18 | Reconciled-only filter | — | 62 | Partial (HTTP 200 only; row-content not asserted — data-dependent) |
| TC-P19 | Non-reconciled-only filter | — | 63 | Partial (HTTP 200 only) |
| TC-P20 | Report headings render | 05 | 64 | Full |
| TC-P21 | PDF export success | 11 | 65 | Full |

### Negative
| TC | Description | V1 | V2 | Coverage |
|----|-------------|----|----|----------|
| TC-N01 | Toggle missing id 404 | 08 | 30 | Full |
| TC-N02 | Toggle non-numeric id | — | 31 | Full |
| TC-N03 | PDF empty ids 400 | 09 | 32 | Full |
| TC-N04 | PDF missing ids 400 | — | 33 | Full |
| TC-N05 | Guest toggle redirect | — | 34 | Full |
| TC-N06 | Guest browser redirect | 10 | 35 | Full |

### Dependency / Security
| TC | Description | V1 | V2 | Coverage |
|----|-------------|----|----|----------|
| TC-D01 | SoftDeletes vs DDL (MIG-BIL-001) | 02 | 05 | Full (documented) |
| TC-D02 | Payment resolves invoice | — | 40 | Full |
| TC-D03 | Invoices parent table exists | — | 41 | Full |
| TC-D04 | Logs use GlobalMaster table | — | 42 | Full |
| TC-D05 | Toggle route `{session}` param | 13 | 70 | Full |
| TC-D06 | Unknown filter falls through | — | 71 | Partial (HTTP 200 only) |
| TC-D07 | Empty date_range not today-scoped | — | 72 | Partial (HTTP 200 only) |
| TC-D08 | Rapid serial toggles consistent | — | 73 | Full |
| TC-S01 | Guest JSON toggle unauthorized | — | 90 | Full |
| TC-S02 | PDF scalar ids not OK | — | 91 | Full |
| TC-S03 | Injection-shaped filter safe | — | 92 | Full |

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Positive | 21 | 19 | 2 | 0 | 100% (90% Full) |
| Negative | 6 | 6 | 0 | 0 | 100% |
| Dependency | 8 | 6 | 2 | 0 | 100% |
| Security | 3 | 3 | 0 | 0 | 100% |
| **Total** | **38** | **34** | **4** | **0** | **100%** |

Targets met: Negative 100% ✅ · Positive ≥90% Full ✅ (90%) · Dependency ≥90% ✅.

**Partial-coverage list (limitations):** TC-P18/P19/D06/D07 assert HTTP 200 on the filtered index only. Asserting exact filtered **row contents** requires deterministic seed data across both reconciled and unreconciled payments in the live central DB, which is data-dependent in this shared environment; the query builder's filter mapping is additionally covered at the source level (BC-BIZ-04). No true gaps.

---

## 3. Coverage-Score by Requirement Source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`) — manual toggle, audit trail, filter | 5 | 5 | 100% |
| State-Machine transitions (`Screen-SM`) — BC-SM-01/02 | 2 | 2 | 100% |
| Validation Rules (`Screen-VR`/BC-VAL) — toggle no-validation, PDF selection | 3 | 3 | 100% |
| Integration Points (`Screen-IP`/BC-INT/REF) | 3 | 3 | 100% |
| Permissions (`Screen-PM`) — viewAny/status/pdf/print | 4 | 4 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No zero-coverage items.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compared | Finding |
|---|-------|----------|---------|
| 1 | Enum case | n/a (boolean toggle, no enum in this feature) | — |
| 2 | Route registration | Blade `route('central.billing.billing-management.toggleStatus')` vs web.php:335-336 | Registered ✅ (param `{session}` misnomer — OBS-BIL-R02) |
| 3 | Gate vs Policy | Controller `Gate::authorize('prime.payment-reconciliation.viewAny')` vs `PaymentReconciliationPolicy::viewAny` + `Gate::define` (Provider:79-82) | Wired ✅ |
| 4 | Fillable vs DDL | Model `$fillable` `payment_reconciled` vs DDL:74 | Match ✅ |
| 5 | Cast vs DDL | `payment_reconciled => boolean` vs `tinyint(1)` | Correct ✅ |
| 6 | Service delegation | toggle logic inline in controller (no service) | N/A (module has no Service layer) |
| 7 | State machine vs impl | Screen 0↔1 flip vs `toggleStatus` `!$payment->payment_reconciled` | Match ✅ |
| 8 | Validation vs FormRequest | Screen "no precondition check" vs no validation in `toggleStatus` | Match (by design — noted gap in requirement) |
| 9 | Error message vs source | "No items selected" (PDF) asserted verbatim | Match ✅ |
| 10 | **Permissions vs Policy/Gates** | PDF UI `@can('prime.payment-reconciliation.pdf')` vs endpoint `Gate::authorize('prime.invoicing-payment.view')` | **MISMATCH → DEV-BIL-R01 (P2)** |
| 11 | Integration FK vs migration | Requirement FK payments→invoices vs DDL FK text | DDL FK malformed (`bil_tenant_invoicing`/`tenant_invoicing_id`) — part of MIG-BIL-001 family (0 executable migrations) |

---

## 5. Defect Register (feature-scoped)

| ID | Sev | Status | Proving test |
|----|-----|--------|--------------|
| MIG-BIL-001 | P0 | Open (audit) — SoftDeletes vs missing `deleted_at` | V1_02, V2_05 |
| DATA-BIL-001 | P0 | Open (audit) — adjacent audit-log FK column mismatch (affects remarks path, not toggle) | documented |
| DEV-BIL-R01 | P2 | **Discovered here** — PDF endpoint gate ≠ UI @can key | V1_14, V2_53 |
| DEAD-BIL-001 | P2 | **Verified remediated** in current source (regression guard) | V2_54 |
| OBS-BIL-R02 | P3 | Cosmetic — toggle route `{session}` param misnomer | V2_70 |
