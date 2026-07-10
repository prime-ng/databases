# Consolidated Payment — Validation Report (`bil_`)

**Feature:** Billing / Consolidated Payment (Prime-central, `prime_db`)
**Generated:** 2026-Jul-10
**Test file:** `bil_ConsolidatedPayment_TestCas.php` — 37 methods, single comprehensive suite.

## 1. File Existence Summary
| # | Artifact | Present |
|---|----------|:---:|
| 1 | `bil_ConsolidatedPaymentTcList_Require.md` | ✅ |
| 2 | `bil_ConsolidatedPaymentMANUALTESTING_Require.md` | ✅ |
| 3 | `bil_ConsolidatedPaymentGAPANALYSIS_Require.md` | ✅ |
| 4 | `bil_ConsolidatedPayment_TestCas.php` | ✅ |
| 5 | `bil_ConsolidatedPaymentValidation_Report.md` | ✅ |
| 6 | `run-ConsolidatedPayment-tests.ps1` | ✅ |
| 7 | `run-ConsolidatedPayment-tests.sh` | ✅ |

## 2. Naming Conventions
- Prefix `bil_` = DDL table prefix of primary table `bil_tenant_invoicing_payments` (verified in `Billing_DDL_v1.sql` `CREATE TABLE`). ✅
- Feature PascalCase `ConsolidatedPayment`. ✅
- Class name = filename `bil_ConsolidatedPayment_TestCas`. ✅
- Methods snake_case, zero-padded, semantic bands (`test_consolidated_payment_NN_*`). ✅

## 3. Structure Validation
- `extends BillingDuskTestCase` (central base; resolves to `prm_BillingDuskTestCase_TestCas` via preloader alias — E22). ✅
- Namespace `Tests\Browser\Modules\Prime\Billing\ConsolidatedPayment` (mirrors committed sibling). ✅
- `use App\Models\User;` per constraint E21/task; no tenant scaffolding (central `prime_db`). ✅
- Typed property use limited to inherited base props (`$adminUser`, `$centralBaseUrl`) — all initialised in base. ✅
- `php -l` → **No syntax errors detected.** ✅
- HTTP endpoint/validation via in-process `postJson` + `actingAs` (constraint 14/15); browser via `authenticateCentral`/`visitAuthenticated` (E21). ✅

## 4. Coverage Completeness
- **Total methods:** 37. Every TC-ID maps to ≥1 method; every method maps back to a TC/BC (see TcList §3 index + Gap §1).
- Category coverage: Negative **100%**, Positive **100%**, Dependency/Security **100%**, Tenancy **100%** (central P0/P1). Gates met.
- Semantic bands populated: 01–09 config, 10–19 BIZ, 20–29 SM, 30–39 VAL, 40–49 INT/REF, 50–59 AUTH, 60–69 UIX, 70–79 EDG, 90–99 tenancy/security.

## 5. Known Source Defects Documented
| DEV | Sev | Status | Where proven |
|-----|-----|--------|--------------|
| DEV-BIL-001 (audit SEC-BIL-002) | P0 | **Remediated in source** — documented as closed | `_16`, `_20` |
| DEV-BIL-002 (audit VAL-BIL-001) | P2 | Open | `_37` |
| DEV-BIL-003 (route double-prefix) | P3 | Open | `_15` |
| DEV-BIL-004 (MIG-BIL-001 SoftDeletes/DDL) | P0 | Open | `_43` |
| DEV-BIL-005 (DDL FK/column mismatch) | P2 | Open (DDL-level) | Gap §4 #11 |
| DEV-BIL-006 (orphan payment) | P2 | Open | `_42` |
| DEV-BIL-007 (no sum/overpayment guard) | P2 | Open | `_70`, `_71` |

> **Audit discrepancy noted:** the audit's headline P0 `SEC-BIL-002` (no-rollback + early-return-in-open-transaction) does **not** reproduce against the current `InvoicingPaymentController::consolidatedStore()` — the empty-selection guard now precedes `DB::beginTransaction()` and the loop is wrapped in `try { … DB::commit(); } catch { DB::rollBack(); }`. The suite proves the current (fixed) behaviour and records the remediation.

## 6. Constraints Applied (from `05_`)
- E21/E22 — central base `BillingDuskTestCase`, `authenticateCentral()`/`visitAuthenticated()`/`centralUrl()` on 127.0.0.1; no tenant init.
- E19 — Billing must be enabled in `modules_statuses.json` (else 404); `_30`–`_36` fail loudly with an E19 hint on a 404.
- E20 — `APP_ENV=testing` for CSRF bypass (set by the runners).
- E23 — routes asserted by name (`Route::has`) / built via `route()`, never hand-built (double-prefix quirk).
- Constraint 12 — `SoftDeletes` calls guarded by `Schema::hasColumn` (DEV-BIL-004).
- Constraint 14/15 — HTTP test methods + `actingAs` for status/validation.
- Constraint 17 — schema types asserted tolerantly via `Schema::hasColumn` (no exact `COLUMN_TYPE`).
- Constraint 9 — DB-mutation tests self-`markTestSkipped()` in partial environments.

## 7. Environment Prerequisites
1. Billing module **enabled** in `prime_testing/modules_statuses.json` (E19).
2. Central app served on `http://127.0.0.1:8000`, `APP_ENV=testing`.
3. A resolvable super-admin (`DUSK_ADMIN_EMAIL`/`is_super_admin`).
4. For full persistence coverage: at least one outstanding `bil_tenant_invoices` row (`paid_amount < net_payable_amount`) and payments table carrying `created_at`/`updated_at` (DEV-BIL-004). Absent these, `_17`/`_91`/`_92` self-skip.

## 8. Final Verdict
**PASS WITH NOTES.** All 7 artifacts present; single suite `php -l` clean; coverage gates met; selectors/routes/messages/permissions sourced from real code. Notes: (a) DB-mutation cases are environment-gated (defensive skips); (b) audit SEC-BIL-002 is remediated in current source and recorded as closed; (c) DEV-BIL-002/004/006/007 remain open and are proven/documented.
