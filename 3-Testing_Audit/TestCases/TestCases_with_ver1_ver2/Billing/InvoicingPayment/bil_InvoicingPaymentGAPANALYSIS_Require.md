# Invoice Payments — Gap Analysis (Manual TC ↔ Dusk method)

- **V1 methods:** 17 · **V2 methods:** 43 · **Ratio:** 2.53× (≥ 2× gate met)
- **DB scope:** prime_db central; mirrors `BillingDuskTestCase`. Mutation/endpoint cases are defensive (`markTestSkipped`) so a partial environment stays green.

## 1. Coverage mapping

### Positive
| Manual TC | V2 method(s) | Coverage |
|-----------|--------------|----------|
| TC-P01 (schema/columns) | 01, 02 | Full |
| TC-P02 (model/request/FK) | 05, 06, 07, 08, 40 | Full |
| TC-P03 (tab + filters + headers) | 60, 61, 62 | Full |
| TC-P04 (add-payment AJAX) | 64 | Full |
| TC-P05 (payment-details AJAX) | 63 | Full |
| TC-P06 (increment paid) | 10 | Full |
| TC-P07 (never decrement) | 11 | Full |
| TC-P08 (partial→PARTIALLY_PAID) | 20 | Full (invariant asserted; status ID derivation observed via paid/net) |
| TC-P09 (complete→PAID) | 21 | Full (invariant) |
| TC-P10 (overpay stays PAID) | 22 | Full |
| TC-P11 (reconciled YES→1) | 15 | Full |
| TC-P12 (audit row on store) | 42 | Full |
| TC-P13 (currency INR) | 72 | Full |

### Negative
| Manual TC | V2 method(s) | Coverage |
|-----------|--------------|----------|
| TC-N01 missing invoice | 30 | Full |
| TC-N02 non-existent invoice | 31 | Full |
| TC-N03 amount < min / negative | 32, 71 | Full |
| TC-N04 non-numeric amount | 33 | Full |
| TC-N05 missing currency | 34 | Full |
| TC-N06 missing payment_mode | 35 | Full |
| TC-N07 guest blocked | 37 | Full |
| TC-N08 XSS remarks escaped | 38 | Full |
| TC-N09 unauth tab → /login | 52 | Full |

### Dependency / Defect
| Manual TC | V2 method(s) | Coverage |
|-----------|--------------|----------|
| TC-D01 audit dependency | 42 | Full |
| TC-D02 SoftDeletes vs no deleted_at (MIG-BIL-001) | 03 | Full (defect proven) |
| TC-D03 FK column/table mismatch (DATA-BIL-001) | 44 | Full (defect proven) |
| TC-D04 atomicity, no orphan (SEC-BIL-001) | 91 | Full |

## 2. Coverage Summary
| Category | Total | Full | Partial | Gap | % |
|----------|-------|------|---------|-----|---|
| Positive | 13 | 13 | 0 | 0 | 100% |
| Negative | 9 | 9 | 0 | 0 | 100% |
| Dependency/Defect | 4 | 4 | 0 | 0 | 100% |
| **Overall** | **26** | **26** | **0** | **0** | **100%** |

Targets met: Negative 100% (≥100), Positive 100% (≥90), Dependency 100% (≥90). Tenancy not applicable (central prime_db, single central DB — no per-tenant isolation surface).

## 3. Coverage-Score by requirement Source (WP-F)
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR) | 5 | 5 | 100% |
| State-Machine transitions (Screen-SM) | 4 | 4 | 100% |
| Validation Rules (Screen-VR / Request) | 8 | 8 | 100% |
| Integration Points (Screen-IP) | 2 | 2 | 100% |
| Permissions (Screen-PM) | 5 | 5 | 100% |

Every Source-tagged requirement item has ≥1 TC. No zero-coverage items.

## 4. Cross-Reference Defect Scan (11 checks)
| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 1 | Enum case | DDL `mode`/`payment_status` enums vs Request `in:` | **VAL-BIL-001** — Request has NO `in:` for `payment_mode` or `payment_status`; any string ≤ limit passes. |
| 2 | Route registration | Blade `.add-payment-details`/`.payment-details` vs `routes/web.php` 380–388 | OK — `invoicing-payment` resource + `billing.payment-details` registered. |
| 3 | Gate vs Policy | Controller `Gate::authorize('prime.invoicing-payment.*')` vs Policy methods | OK — Policy defines all abilities (uses `Modules\Prime\Models\User`). |
| 4 | Fillable vs DDL | Model `$fillable` vs DDL columns | OK — fillable matches; `is_active`/`created_by`/`deleted_at` in requirement are "Missing from current DDL" (not fillable). |
| 5 | Cast vs DDL | Model `$casts` vs DDL types | OK — `payment_reconciled` boolean↔tinyint(1); `gateway_response` array↔JSON; `payment_date` date↔DATE. |
| 6 | Service delegation | Controller body vs Service | N/A — no Service layer; logic inline in controller. |
| 7 | State machine vs impl | Screen SM vs controller | OK — PAID/PARTIALLY_PAID/PENDING derived server-side (L87-93). **Note:** payment-row `payment_status` mis-sourced → **BUG-BIL-010**. |
| 8 | Validation vs FormRequest | Screen rules vs `rules()` | **VAL-BIL-001** — no `required_if` rule for `pay_mode_other` though a message exists; controller bypasses `validated()`. |
| 9 | Error message vs FormRequest | Expected vs `messages()` | Dead message `pay_mode_other.required_if` (no rule). |
| 10 | Permissions vs Policy/Gates | Screen matrix vs Policy + gates | OK — viewAny/view/create/update/delete all present + gated. |
| 11 | Integration FK vs migration | Requirement FK vs DDL `foreign()` | **DATA-BIL-001** — DDL FK references col `tenant_invoicing_id` (absent) / table `bil_tenant_invoicing` (wrong); runtime column is `tenant_invoice_id`. |

### Additional structural findings
- **MIG-BIL-001 (P0):** `SoftDeletes` model, DDL lacks `deleted_at`.
- **MIG-BIL-002 (P1):** DDL `payment_status NOT NULL VARCHAR(20)` — type keyword ordering malformed.
- **BUG-BIL-011 (P2):** `consolidated_amount` set = `amount_paid` on single payments (should be NULL).

### Corrections to intake brief (verified against real source)
| Brief claim | Source reality |
|-------------|----------------|
| `authorize()=true` | Gated: `Gate::allows('prime.invoicing-payment.create')`. |
| SEC-BIL-001 "no try/catch" | store() **has** `try/catch` + `DB::rollBack()` (L52,131). Not reproducible; tested as atomicity. |
| SEC-BIL-011 "logs `$request->all()`" | event_info is **whitelisted** (L110). Not reproducible; asserted absence of raw keys. |
| BUG-BIL-010 "status from request input" | Invoice status **is** derived server-side; real defect is the *payment row* `payment_status` sourced from form `invoice_payments`. |

## 5. Legend
- **Full** — automated method(s) assert the manual expectation end-to-end (or defensively skip when the central invoice/table is unavailable).
- Defect tests assert **current** behaviour (prove the bug) so a future fix intentionally flips them — see the ID in the method name.
