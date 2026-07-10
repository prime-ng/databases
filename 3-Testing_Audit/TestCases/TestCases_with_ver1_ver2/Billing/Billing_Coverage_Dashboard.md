# Billing (BIL) — Module Coverage Dashboard

**Generated:** 2026-Jul-09 (report mode) · **Module folder:** `TestCases/Billing/`
**Layer:** `prime_db` central (Prime / Super-Admin SaaS-invoicing — NOT tenant-per-school) · **No tenancy scaffolding** · Browser Dusk · `App\Models\User` · permissions `prime.<entity>.<action>`
**Reference audit:** `Billing_Complete_Audit_2026-06-29.md` (Health 37/100, Deploy NO-GO) — **now materially stale vs current source (see §Audit Drift).**

## Per-feature coverage

| # | Feature | Screen file | Prefix | Type | V1 | V2 | ×  | php -l | Coverage (Pos / Neg / Dep) | Verdict |
|---|---------|-------------|--------|------|----|----|----|--------|----------------------------|---------|
| 1 | BillingCycle | `billing-cycles.md` | `prm_` | Full CRUD + soft-delete + toggle | 13 | 36 | 2.77× | ✅ | 100 / 100 / 100 | PASS w/ notes |
| 2 | Subscription | `subscription.md` | `prm_` | Read-only / report + AJAX panels | 16 | 43 | 2.69× | ✅ | 100 / 100 / 100 (Full+Partial) | PASS w/ notes |
| 3 | Invoicing | `invoicing.md` | `bil_` | Composite: generate + list/detail | 14 | 37 | 2.64× | ✅ | 100 / 100 / 100 (94.9% auto) | PASS w/ notes |
| 4 | InvoicingPayment | `invoice-payments.md` | `bil_` | Create + cumulative-paid + report | 17 | 43 | 2.53× | ✅ | 100 / 100 / 100 | PASS w/ notes |
| 5 | ConsolidatedPayment | `consolidated-payments.md` | `bil_` | Multi-invoice atomic pay + report | 16 | 60 | 3.75× | ✅ | 100 / 100 / 100 | PASS w/ notes |
| 6 | PaymentReconciliation | `payment-reconciliation.md` | `bil_` | Toggle + report/PDF | 14 | 41 | 2.93× | ✅ | 100 / 100 / 100 | PASS w/ notes |
| 7 | InvoicingAuditLog | `audit-log.md` | `bil_` | Append-only + notes + event-info | 16 | 61 | 3.81× | ✅ | 100 / 100 / 100 | PASS w/ notes |
| 8 | EmailSchedule | `email-schedule.md` | `bil_` | List/show/cancel + queued job | 16 | 50 | 3.13× | ✅ | 100 / 100 / 100 (+SM 100) | PASS w/ notes |
| 9 | GatewayIntegration | `gateway-integration.md` | `bil_` | **Planned / not implemented** | 14 | 42 | 3.00× | ✅ | 100 of current-reality; planned = skipped stubs | PASS w/ notes |
| | **TOTALS** | 9 features | | | **136** | **413** | **3.04× avg** | **all clean** | Neg 100% module-wide | 9/9 PASS w/ notes |

**Gate status:** V2 ≥ 2× V1 met on all 9 · `php -l` clean on all 18 PHP files · every feature has all 8 artifacts · every TC↔method mapped · Negative coverage 100% module-wide · Tenancy pack N/A (central prime_db — no per-tenant surface).

## Open source defects (proving tests attached in each feature's V1/V2)

### STILL LIVE (verified against current source)
| Code | Sev | Feature(s) | Summary |
|------|-----|-----------|---------|
| **MIG-BIL-001** | P0 | ALL | Models declare `SoftDeletes`+timestamps; DDL tables lack `deleted_at`/`updated_at` → `SQLSTATE 42S22` on a schema-correct prime_db. Dev DB is hand-patched. Schema-guarded (fail-fast) in every V1 `test_01/02`. |
| **DATA-BIL-001** | P0 | InvoicingAuditLog, Invoicing, Payment | Model↔DDL audit-FK column mismatch. **Direction is DDL-vs-code:** the live models use `tenant_invoice_id` (remediated); `Billing_DDL_v1.sql:84` still declares `tenant_invoicing_id` and `prime_db_v4.sql` uses `tenant_invoice_id` → conflicting DDLs. Audit read/PDF path 500s on the stale DDL. |
| **VAL-BIL-001** | P2 | InvoicingPayment, ConsolidatedPayment | No array rules for `invoice_ids[]`/`new_payment[]`/`payment_status[]`; controller reads `$request->date`/`->tenant_invoice_id` directly, bypassing `validated()`; no `in:` enum on `payment_mode`. |
| **BUG-BIL-010** | P1 | InvoicingPayment | Payment-row `payment_status` written from the form's invoice-status value (PENDING/PARTIAL/PAID) — mismatches DDL enum {INITIATED,SUCCESS,FAILED}. (Invoice status IS derived server-side — screen doc was imprecise.) |
| **BUG-BIL-005** | P2 | ConsolidatedPayment | Consolidated-payment print path crash (`getCollection()`/`isNotEmpty()` misuse) — asserted defensively. |
| **BUG-BIL-013 / 014** | P2 | Invoicing | Broken `billing-management.view` route (no `view()` method); central billing route block registered 3×. |
| **PERF-BIL-001** | P2 (partial) | Subscription, Invoicing | Temp PDFs now `@unlink`'d and dashboard capped `limit(500)`; **synchronous ZIP still stands**. |

### NEWLY DISCOVERED this run (cross-reference scan — "verify in source")
| Code | Sev | Feature | Summary |
|------|-----|---------|---------|
| DEV-BIL-INV-001 | P1 | Invoicing | Blade action buttons gate on `prime.invoicing.*` while Controller+Policy enforce `prime.billing-management.*` → buttons show/hide on a different permission than the one enforced. |
| AUTH-BIL-002 | P2 | InvoicingAuditLog | Blade action column gates on `audit.invoicing-audit-log.remakr`/`.viewAny` (wrong prefix + typo), unbacked by any Policy ability → Add-Note/Event-Info UI unreachable for `prime.*` holders. |
| VAL-BIL-002 | P2 | InvoicingAuditLog | `auditAddNoteUpdate` has no FormRequest / no `max:500` / no sanitization on `notes` VARCHAR(500) → truncation + stored-XSS risk. |
| DEV-BIL-SUB-001 | P2 | Subscription | Detail-panel permission namespaces split: `subscription/module-details`→`prime.billing-management.view`; `pricing/billing-details`→`prime.subscription.view`. |
| DEV-EMS-001 (DATA-BIL-003) | P2 | EmailSchedule | `bil_tenant_email_schedules.invoice_id` has no FK — orphan ids insert. |
| DEV-EMS-002 | P2 | EmailSchedule | `sendEmail`/`scheduleEmail` have no FormRequest validation. |
| DEV-BIL-R01 | P2 | PaymentReconciliation | `downloadSelectedPdf` authorizes `prime.invoicing-payment.view` while the reconciliation PDF button `@can('prime.payment-reconciliation.pdf')` — key mismatch. |
| INT-BIL-CP-01 | P3 | ConsolidatedPayment | List filter uses `<` (outstanding) while `downloadConsolidatedPdf` uses `!=` → overpaid invoices handled inconsistently. |
| DEV-BIL-201/202, SUB-002/003/004, EMS-005/006, OBS-BIL-R02, DEV-BIL-020, DATA-BIL-003(AL) | P3 | various | Policy model-type copy-paste (`InvoicingPayment` on `SubscriptionPolicy`), forceDelete gate-key drift, `{session}` param misnomer, double-`billing` route path, unguarded `explode(' - ')`, razorpay dep in root not module composer, DDL FKs referencing non-existent objects (`bil_tenant_invoicing`, `users`). |

## Audit Drift — Jun-2026 audit is STALE (source-wins per HARD RULE)
Multiple features independently verified that several audit P0/P1 items are **already remediated in current `prime_ai` source**. Recommend the audit register be re-baselined:
| Audit code | Audit sev | Current source state |
|------------|-----------|----------------------|
| SEC-BIL-001 | P0 | **REMEDIATED** — `store()` wraps `DB::beginTransaction()` + try/catch + `rollBack()`. |
| SEC-BIL-002 | P0 | **REMEDIATED** — `consolidatedStore()` try/catch + rollback; empty-selection guard moved before `beginTransaction`. |
| SEC-BIL-005 | P1 | **REMEDIATED** — student count runs before the prime tx, inside try/finally. |
| SEC-BIL-010 | P1 | **REMEDIATED** — `auditAddNoteUpdate`, `pricingDetails`, `billingDetails` now gated. |
| SEC-BIL-011 | P1 | **REMEDIATED** — `event_info` is whitelisted, not `$request->all()`. |
| DATA-BIL-002 | P0 | **REMEDIATED** — no phantom `invoice_amount`, no duplicated fillable block. |
| BUG-BIL-011 | P1 | **REMEDIATED** — `generateInvoiceForOrganization()` returns `['status'=>..,'message'=>..]` arrays. |
| BUG-BIL-015 | P1 | **MITIGATED** — unique-collision retry loop added. |
| JOB-BIL-001 | P2 | **REMEDIATED** — job declares `$tries/$backoff/$timeout` + `failed()`; performer id passed to constructor. |
| DEAD-BIL-001 | P2 | **PARTLY** — non-existent-model imports gone; some policies still effectively dead (real paths gate on `invoicing-payment.*`). |
| **MIG-BIL-001 / DATA-BIL-001 / VAL-BIL-001 / BUG-BIL-005/010/013/014 / PERF-BIL-001** | — | **STILL LIVE** (see above). |

## Environment prerequisites (every feature's runner + Validation Report)
- Billing must be enabled in `prime_testing/modules_statuses.json` (currently nearly all `false` → 404 on all routes) — **environment fix, not a test-code fix**.
- `APP_ENV=testing` (CSRF bypass; else 419); Prime/central host pinned to `http://127.0.0.1:8000` (`PrimeDuskTestCase` fails setUp otherwise — see `05_` #21); `MAIN_PROJECT_PATH`→`prime_ai` for schema-truth/code-inspection tests.
- Row-level positive flows (payments, reconciliation, audit, generation) require seeded `bil_tenant_invoices` / `prm_tenant_plan_*` data — otherwise the suites `markTestSkipped` defensively to stay green in partial environments.

## Test-infra note (NOT modified — outside OUTPUT_ROOT)
Committed siblings `use ...\BillingDuskTestCase` (short name) while the physical class is `prm_BillingDuskTestCase_TestCas`; resolution depends on `tests/Browser/Modules/preload.php` `class_alias` (documented as `05_` constraint #22). Generated V1/V2 mirror the sibling verbatim so they load exactly as the committed tests do.
