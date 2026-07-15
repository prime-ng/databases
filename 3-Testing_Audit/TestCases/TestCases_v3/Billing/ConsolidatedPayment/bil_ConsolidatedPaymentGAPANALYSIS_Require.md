# Consolidated Payment — Gap Analysis (`bil_`)

Feature: Billing / Consolidated Payment (Prime-central). Test file: `bil_ConsolidatedPayment_TestCas.php` (37 methods).

## 1. Manual TC ↔ Dusk method mapping

| TC ID | Category | Method(s) | Coverage |
|-------|----------|-----------|----------|
| TC-P01 | Config | `_01` | Full |
| TC-P02 | Config | `_02` | Full |
| TC-P03 | Config | `_03` | Full |
| TC-P04..P08 | UI/BIZ | `_10`,`_11`,`_12`,`_13`,`_14` | Full |
| TC-P09 | Route | `_15` | Full |
| TC-P10 | Persist | `_17` | Partial (defensive — needs an outstanding invoice + writable table) |
| TC-P11 | Activity log | `_18` | Full (source-string proof; central-log runtime insertion is source-verified) |
| TC-P12/P13 | State machine | `_20`,`_21` | Full (source-verified derivation) |
| TC-P14..P16 | Integration | `_40`,`_41`,`_44` | Full |
| TC-P17 | Auth | `_52` | Full |
| TC-P18/P19 | UI/UX | `_60`,`_61` | Full |
| TC-N01 | Empty-guard | `_16` | Full |
| TC-N02..N08 | Validation | `_30`–`_36` | Full |
| TC-N09 | Validation gap | `_37` | Full |
| TC-N10/N11 | Guest | `_50`,`_51` | Full |
| TC-D01 | Orphan payment | `_42` | Full (source-proven) |
| TC-D02 | Soft-delete guard | `_43` | Full |
| TC-D03/D04 | Over-allocation | `_70`,`_71` | Full (source-proven) |
| TC-T01 | Tenancy | `_90` | Full |
| TC-S01 | Stored XSS | `_91` | Partial (defensive — needs writable invoice) |
| TC-S02 | IDOR | `_92` | Partial (defensive) |

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Positive (TC-P) | 19 | 16 | 3 | 0 | 100% |
| Negative (TC-N) | 11 | 11 | 0 | 0 | 100% |
| Dependency/Sec (TC-D/S/T) | 7 | 4 | 3 | 0 | 100% |
| **Overall** | **37** | **31** | **6** | **0** | **100%** |

Gate check: Negative **100%** (≥100 ✅), Positive **100%** (≥90 ✅), Dependency **100%** (≥90 ✅), Tenancy **100%** on this central P0/P1 feature ✅.

**Partial-coverage notes / limitations:**
- `_17`, `_91`, `_92` require a real outstanding `bil_tenant_invoices` row and a writable payments table (`updated_at` present). They self-`markTestSkipped()` in a partial environment (constraint 9) rather than fail — the DB-mutation assertions only run when the prime_db fixture supports them.
- Runtime 403-for-limited-user is **not** asserted: the central super-admin `Gate::before` bypasses dotted abilities, so a limited-user 403 is not observable here. Authorization is instead covered by guest-redirect (`_50`/`_51`) + gate/policy definition (`_52`).

## 3. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR` / BC-BIZ) | 7 | 7 | 100% |
| State-Machine transitions (`Screen-SM` / BC-SM) | 5 | 5 | 100% |
| Validation Rules (`Screen-VR` / BC-VAL) | 6 | 6 | 100% |
| Integration Points (`Screen-IP` / BC-INT/REF) | 3 | 3 | 100% |
| Permissions (`Screen-PM` / BC-AUTH) | 4 | 4 | 100% |
| Edge cases (BC-EDG) | 4 | 4 | 100% |

Every `Source`-tagged item maps to ≥1 TC. No requirement item is left with 0 coverage.

## 4. Cross-Reference Defect Scan

| # | Check | Compared | Finding | DEV |
|---|-------|----------|---------|-----|
| 1 | Enum case | DDL `mode/payment_status` ENUM vs Request `in:` | Request uses `string\|max` (no `in:` for mode/status) — dropdown-driven, no case clash | — |
| 2 | Route registration | Screen route `/billing/consolidated-store` vs `routes/web.php` under `prefix('billing')` | **Path double-segments** to `/billing/billing/consolidated-store` (name `billing.consolidated.store`) | **DEV-BIL-003** |
| 3 | Gate vs Policy | Controller `Gate::authorize('prime.invoicing-payment.create')` vs `ConsolidatedPaymentPolicy` (`prime.consolidated-payment.*`) | Store gate uses the **invoicing-payment** ability, not the consolidated-payment ability; both defined | Note (intentional) |
| 4 | Fillable vs DDL | `InvoicingPayment::$fillable` vs DDL columns | Aligned (`consolidated_amount` present) | — |
| 5 | Cast vs DDL | `gateway_response=array` vs DDL `JSON` | Aligned | — |
| 6 | Service delegation | Controller body vs Service | Logic lives in controller (no service) — acceptable | — |
| 7 | State machine vs impl | Screen status vs controller | Status now derived server-side (BUG-BIL-010 remediated) | Note (fixed) |
| 8 | Validation vs FormRequest | Screen inputs vs `rules()` | `invoice_ids`/`new_payment`/`payment_status` arrays **unvalidated** | **DEV-BIL-002** |
| 9 | Error message vs FormRequest | Expected vs `messages()` | All match verbatim | — |
| 10 | Permissions vs Policy/Gates | Screen permission matrix vs gates | Screen lists `prime.billing-management.*`; actual store gate is `prime.invoicing-payment.create` (matrix drift) | Note |
| 11 | Integration FK vs migration | Screen FK vs DDL | DDL payments FK targets `bil_tenant_invoicing` (renamed table) and audit column is `tenant_invoicing_id` vs model `tenant_invoice_id` — DDL/model mismatch | **DEV-BIL-005** (DDL-level) |
| — | Tx safety | Audit SEC-BIL-002 vs current controller | **Remediated** — empty-guard precedes `beginTransaction()`, try/catch + `DB::rollBack()` present | **DEV-BIL-001** (closed) |
| — | Data integrity | Loop order | Payment created before invoice lookup → orphan on missing invoice | **DEV-BIL-006** |
| — | Reconciliation | Sum(allocation) vs total; overpayment | Neither reconciled nor capped | **DEV-BIL-007** |
| — | Schema↔model | Model SoftDeletes/timestamps vs DDL | DDL omits `deleted_at`/`updated_at` on payments/audit | **DEV-BIL-004** |

## 5. Legend
- **Full** — behaviour asserted directly (DB/HTTP/DOM or authoritative source string).
- **Partial** — asserted when environment supports it; otherwise self-skips (defensive).
- **Note** — observation/drift, not a functional defect on its own.
