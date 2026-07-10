# Consolidated Payment — Gap Analysis & Coverage

- **Feature:** Billing / Consolidated Payment
- **V1:** `bil_ConsolidatedPaymentV1_TestCas` (16 methods) · **V2:** `bil_ConsolidatedPaymentV2_TestCas` (60 methods)
- **Style:** browser Dusk, central chain (mirrors committed sibling `prm_ConsolidatedPaymentTab_TestCas`).

Coverage legend: **Full** = behaviour asserted (live or via source-truth); **Partial** = asserted defensively / environment-gated (`markTestSkipped`); **Gap** = not covered.

---

## 1. Manual TC ↔ V2 method mapping

### Positive
| TC | V2 method(s) | Coverage | Notes |
|----|--------------|----------|-------|
| TC-P01 | 01, 04, 05 | Full | schema + model reflection |
| TC-P02 | 02 | Full | |
| TC-P03 | 10 | Full | source-truth |
| TC-P04 | 12, 13 | Full | consolidated_amount total vs per-row |
| TC-P05 | 14 | Full | cumulative paid |
| TC-P06 | 15 | Full | server-side status |
| TC-P07 | 16, 17 | Full | atomic tx + rollback + guard ordering |
| TC-P08 | 18 | Full | success message |
| TC-P09 | 40 | Full | withSum |
| TC-P10 | 41 | Full | `<` hard filter |
| TC-P11 | 60 | Partial | needs module enabled (browser) |
| TC-P12 | 61, 62 | Partial | row inputs need data |
| TC-P13 | 63 | Partial | browser |
| TC-P14 | 64 | Partial | PDF endpoint; asserts not-500 |
| TC-P15 | 44 | Full | audit action_type / relation |

### Negative
| TC | V2 method(s) | Coverage |
|----|--------------|----------|
| TC-N01 | 17 (+V1-07) | Full |
| TC-N02 | 30 | Partial (endpoint) / Full (rule source 06) |
| TC-N03 | 31 | Partial / Full (06) |
| TC-N04 | 32 | Partial / Full (06) |
| TC-N05 | 33 | Partial / Full (06) |
| TC-N06 | 34 | Partial / Full (06) |
| TC-N07 | 35 | Partial / Full (06) |
| TC-N08 | 36 | Partial / Full (06) |
| TC-N09 | 39, 74 | Full |
| TC-N10 | 07 | Full (VAL-BIL-001) |
| TC-N11 | 56, 90 | Full |
| TC-N12 | 72 | Full |

### Dependency
| TC | V2 method(s) | Coverage |
|----|--------------|----------|
| TC-D01 | 46 | Full |
| TC-D02 | 09, 44, 45 | Full (model) / Partial (FK live-block skip) |
| TC-D03 | 03 | Full (documented MIG-BIL-001) |
| TC-D04 | 15 | Full |
| TC-D05 | 43 | Full |
| TC-D06 | 42, 70 | Full |
| TC-D07 | 73 | Full |

### Security
| TC | V2 method(s) | Coverage |
|----|--------------|----------|
| TC-S01 | 90 | Full |
| TC-S02 | 91 | Partial (guard returns before store; asserts non-reflection) |
| TC-S03 | 92 | Full |
| TC-S04 | 93 | Full |

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Positive | 15 | 10 | 5 | 0 | 100% |
| Negative | 12 | 12 | 0 | 0 | 100% |
| Dependency | 7 | 6 | 1 | 0 | 100% |
| Security | 4 | 3 | 1 | 0 | 100% |
| **Total** | **38** | **31** | **7** | **0** | **100%** |

Targets met: Negative 100% ✅, Positive ≥ 90% ✅, Dependency ≥ 90% ✅.

---

## 3. Coverage-Score by requirement source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR) | 6 | 6 | 100% |
| State-Machine (Screen-SM) | 0 | 0 | n/a (no explicit FSM; invoice status derivation covered in BC-BIZ-05) |
| Validation Rules (Screen-VR) | 8 | 8 | 100% |
| Integration Points (Screen-IP) | 5 | 5 | 100% |
| Permissions (Screen-PM) | 7 | 7 | 100% |

Every `Source`-tagged requirement item maps to ≥1 TC. No zero-coverage items.

---

## 4. Cross-Reference Defect Scan (11 checks)

| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 1 | Enum case | DDL ENUM vs Request `in:` | `payment_reconciled in:on,1,0,yes,no,YES,NO`; `prepareForValidation` collapses to 1/0 before validation — yes/no effectively unreachable (BC-EDG-02). No DDL enum on this column. |
| 2 | Route registration | Blade `route()` / form action vs `routes/web.php` | `billing.consolidated.store`, `billing.download.consolidated.pdf`, `billing.billing-management.print.data` all registered (web.php 384-390, 356). ✅ |
| 3 | Gate vs Policy | Controller `Gate::authorize()` vs Policy | **DEAD-BIL-001**: `ConsolidatedPaymentPolicy` covers `prime.consolidated-payment.*` but store/pdf gate on `prime.invoicing-payment.*` → policy dead. |
| 4 | Fillable vs DDL | Model `$fillable` vs DDL columns | Aligned; `id/created_at/updated_at` correctly excluded. ✅ |
| 5 | Cast vs DDL | Model `$casts` vs DDL type | **BC-EDG-05**: `gateway_response` cast `array` but stored from a string field (`gateway_resp`) → read-side `json_decode` risk. |
| 6 | Service delegation | Controller vs Service | No Service layer in Billing; logic lives in the controller. (Note.) |
| 7 | State machine vs impl | doc transitions vs controller | Invoice status derived server-side (PAID/PARTIAL/PENDING) — implemented; no separate FSM. ✅ |
| 8 | Validation vs FormRequest | screen rules vs `rules()` | **VAL-BIL-001**: `invoice_ids[]`, `new_payment[]`, `payment_status[]` consumed unvalidated. |
| 9 | Error message vs FormRequest | expected vs `messages()` | All asserted strings match verbatim. ✅ |
| 10 | Permissions vs Policy/Gates | screen matrix vs real gates | Screen doc says `prime.billing-management.*`; **real gates** = `prime.consolidated-payment.viewAny` (list), `prime.invoicing-payment.create` (store), `prime.invoicing-payment.view` (pdf). Screen doc is wrong; tests assert real strings. |
| 11 | Integration FK vs migration | screen FK vs DDL `foreign()` | **MIG-BIL-001 / DATA-BIL-001**: payments FK names non-existent `tenant_invoicing_id` and references non-existent table `bil_tenant_invoicing`; audit `performed_by`→`users` SET NULL can block inserts; SoftDeletes vs missing `deleted_at`. |

### Discovered / carried defects
| ID | Sev | Status | Proving test |
|----|-----|--------|--------------|
| MIG-BIL-001 | P0 | LIVE | V1-01, V2-03 |
| DATA-BIL-001 | P0 | model fixed; DDL FK broken; performed_by risk | V2-09/44/45 |
| SEC-BIL-002 | P0 | **REMEDIATED** in current source | V2-16, V2-17 |
| VAL-BIL-001 | P2 | LIVE | V1-03, V2-07 |
| DEAD-BIL-001 | P2 | partly remediated (dead policy remains) | V2-55 |
| BUG-BIL-005 | P2 | verify (defensive) | V2-75 |
| INT-BIL-CP-01 | P3 | LIVE — list `<` vs PDF `!=` | V2-42, V2-70 |

---

## 5. Remaining partial-coverage list

| TC | V2 | Limitation |
|----|----|-----------|
| TC-P11..P14 | 60-64 | Browser render / endpoint round-trip needs Billing module enabled + outstanding invoices; skip gracefully otherwise. |
| TC-N02..N08 | 30-36 | 422 round-trip is environment-gated; the underlying rules are additionally asserted from FormRequest source (V2-06) = Full. |
| TC-D02 | 45 | Live audit-FK block is documented, not force-triggered on the shared central DB. |
| TC-S02 | 91 | Guard returns before persistence; test asserts non-reflection of the payload rather than a stored-and-rendered path. |
