# Module Knowledge: Billing (BIL)
# Last Updated: 2026-06-29 (BA Complete Analysis Pack — every count/status re-verified against live Herd/prime_ai code, prime_db_v4.sql, models, central routes)
# Completion Status: ~60% functional (8 of 17 REQ built/partial; 5 future). Several seed-era P0s CONFIRMED open; one ("auth fully bypassed") REFUTED — see Corrections.

---

## IMPORTANT: Prime Module — Not Tenant

**Database:** `prime_db` (central SaaS database — NOT tenant_db)
**Scope:** Super Admin manages SaaS subscription billing for ALL school tenants from a single central panel.
**Table prefix:** `bil_*` (+ 1 shared table `prm_billing_cycles`)
**DDL location:** `bil_*` tables are defined inside `0-DDL_Masters/prime_db_v4.sql` (v4) — NO standalone module DDL file.
**Unique cross-DB pattern:** BIL is the only Prime module that temporarily calls `Tenancy::initialize()` to read a tenant's isolated DB (active student count) for billing quantity; `Tenancy::end()` MUST follow immediately.

---

## Module Facts

| Item | Value |
|------|-------|
| Module Code | BIL |
| Module Type | **Prime** (prime_db — central database) |
| Table prefix | `bil_*` |
| DDL location | `prime_db_v4.sql` (no standalone DDL file) |
| Laravel Module Path | `Modules/Billing/` |
| Controllers | **7** (verified 2026-06-29): BillingCycleController (199 ln), BillingManagementController (**1036 ln — GOD**), EmailScheduleController (61), InvoicingAuditLogController (146), InvoicingController (69 — **dead stub, not routed**), InvoicingPaymentController (328), SubscriptionController (154) |
| Models | **6**: BillingCycle, BilTenantInvoice, BillOrgInvoicingModulesJnt, InvoicingPayment, InvoicingAuditLog, BillTenatEmailSchedule (class-name typo retained) |
| FormRequests | **3**: BillingCycleRequest (clean), ConsolidatedPaymentRequest (partial — array rules thin), StoreInvoicePaymentRequest (now typed into store()) |
| Jobs | 1 (`SendInvoiceEmailJob` — ShouldQueue; no retry/failed() handling) |
| Mail Classes | 1 (`InvoiceMail`) |
| Policies | **8** — largely DEAD CODE (see Corrections #3): BillingCyclePolicy, BillingManagementPolicy, ConsolidatedPaymentPolicy, InvoicingAuditLogPolicy, InvoicingPaymentPolicy, InvoicingPolicy, PaymentReconciliationPolicy, SubscriptionPolicy |
| Policy registration | In **`BillingServiceProvider::registerPolicies()` lines 58–71** (NOT AppServiceProvider) |
| Unit Tests | 1 file (`tests/Unit/BillingModuleTest.php`, ~55 Pest cases) |
| Feature Tests | 0 |
| Module routes/web.php | **EMPTY** — `foreach(config('tenancy.central_domains'))` loop with empty group body → registers nothing |
| Actual route registration | **central `routes/web.php`** — billing block duplicated **3×** (lines ~311, ~558, ~888) inside the single `central.` domain group |
| API Routes | 0 (`Modules/Billing/routes/api.php` empty) |
| Views | **43** Blade files (verified 2026-06-29) |
| Migrations | 0 (bootstrapped via prime_db DDL directly) |
| V2 Requirement | `4-Initial_Requirements/V2/BIL_Billing_Requirement.md` (26 FR items incl. defect-fix FRs) |
| Screen-spec folder | `2-Module_Requirement_V1/Billing_v1/` (10 files) |
| FRD | `0-FRD_Documents/BIL_FRD_Complete_2026-06-29.md` (Complete Analysis Pack — FRD is embedded as Sections 1–10) |

---

## FRD Summary

- **File:** `0-FRD_Documents/BIL_FRD_Complete_2026-06-29.md` (single consolidated Complete Analysis Pack; FRD = Sections 1–10).
- **Counts:** 17 REQ · 43 BR · 5 Workflows · 7 Reports (RPT) · 12 ENH.
- **Priority split:** P0 = 4 (REQ-001 Billing Cycle, REQ-003 Invoice Generation, REQ-004 Invoice Listing/Detail, REQ-006 Individual Payment); P1 = 8; P2 = 5.
- **Built:** REQ-001, 004, 005, 008. **Partial (built w/ defects):** REQ-002, 003, 006, 007, 009, 010, 011. **Not started:** REQ-012 (scheduler), 013 (overdue), 014 (metering), 015 (gateway), 016 (tenant portal), 017 (GST reports).
- IDs are stable — downstream gap analyses reuse REQ-/BR-/RPT-/ENH-; never renumber.

---

## Three-Way Reconciliation — Corrections to Prior Knowledge (2026-06-29)

**These overturn / refine seed-era and reconnaissance claims. Verified against live code.**

1. **Route 3× duplication is NOT resolved** (recon note said it was). Module `routes/web.php` IS empty, but central `routes/web.php` still has the billing block **three times** (~311/558/888); the whole `central.` group body appears triplicated. → duplicate route-name registration; RT-04 persists.
2. **Policy registration moved to `BillingServiceProvider.php` (lines 58–71)**, not AppServiceProvider. Duplicate registrations persist: `BilTenantInvoice`→(BillingManagementPolicy then InvoicingPolicy, last wins); `InvoicingPayment`→(Consolidated, Reconciliation, Subscription, then InvoicingPaymentPolicy, last wins). Dead policies: BillingManagementPolicy + 3 InvoicingPayment policies. ConsolidatedPaymentPolicy/PaymentReconciliationPolicy reference **non-existent** `App\Models\ConsolidatedPayment` / `App\Models\PaymentReconciliation`.
3. **"Duplicate policy = ALL auth silently bypassed" — REFUTED.** `AppServiceProvider` has a Spatie `Gate::before` hook (line 65). Controllers use dotted permission strings (`prime.billing-management.create`…) resolved by **Spatie permissions**, not policy methods (`viewAny/create/...`). So the duplicate registrations do NOT bypass auth — the policies are simply dead/unused. The **genuine** auth gaps are methods with **no `Gate::authorize` call at all** (see Open Issues). Technical Auditor: confirm the Spatie permission rows exist.
4. **Audit-log FK mismatch confirmed, DDL is the correct side.** `prime_db_v4.sql` defines `tenant_invoice_id`; the **model + relationships + all controller inserts use `tenant_invoicing_id`** → fix the model/controllers to match DDL.
5. **Several seed-era SEC gaps are RESOLVED:** `subscriptionDetails`, `invoiceDetails`, `moduleDetails`, `printData`, `sendEmail`, `scheduleEmail`, `downloadPDF` now have `Gate::authorize`; `index()` uses `Gate::any([...]) || abort(403)`. **New finding:** route `billing-management.view` points to a `view()` method that **does not exist** (broken route).

---

## Confirmed Open Issues (verified 2026-06-29)

> **Technical Auditor Mode-X pass 2026-06-29 — report:** `3-Audit_Reports/V1_Jun-2026/Billing_Complete_Audit_2026-06-29.md`. Health **37/100, P0 cap, DEPLOY: NO-GO**. New P0 raised below (MIG-BIL-001). Correction: REQ-BIL-001 "Billing Cycle = clean" is WRONG vs the DDL — see Lessons Learned.

### P0 (Technical Auditor additions)
- **MIG-BIL-001 — SoftDeletes + default timestamps on every model vs DDL tables that have neither.** ALL bil_ models (and BillingCycle on `prm_billing_cycles`) use `SoftDeletes` + default `$timestamps`, but `prm_billing_cycles` has NO created_at/updated_at/deleted_at; `bil_tenant_invoices`/`_payments` have no `deleted_at`; `bil_tenant_invoicing_audit_logs` has `created_at` only (no updated_at, no deleted_at). On a DDL-built prime_db every cycle CRUD / invoice soft-delete / payment write / audit insert throws `SQLSTATE 42S22 Unknown column`. Degrade to P1 only if live prime_db was hand-patched. (DATA-BIL-001 audit column mismatch is a strict subset of this — also missing updated_at.)
- **DATA-BIL-002 — BilTenantInvoice $fillable phantom `invoice_amount` (not in DDL) + duplicated 8-field block** (BilTenantInvoice.php:20–69). Same as DB-07.

### P0 (BA-flagged, re-confirmed live)
- **DB-01 / MDL-01 — Audit-log FK column mismatch.** Model `InvoicingAuditLog` ($fillable + `invoice()`/`auditLogs()` relations) and inserts in `InvoicingPaymentController::store()` (~line 80) & `consolidatedStore()` (~line 221) use `tenant_invoicing_id`; DDL = `tenant_invoice_id`. Audit inserts fail on a correct DB. Also: model uses SoftDeletes but DDL has no `deleted_at`/`updated_at`; missing casts `event_info`→array, `action_date`→datetime.
- **ERR-01 / ERR-02 — DB transaction without try/catch.** `InvoicingPaymentController::store()` (begin@52/commit@100) and `consolidatedStore()` (begin@158/commit@247) have NO try/catch/rollBack.
- **DB-07 — Duplicate $fillable + phantom column.** `BilTenantInvoice::$fillable` duplicates 8 fields and includes `invoice_amount` which does **not** exist in DDL (DDL has `sub_total`/`net_payable_amount`).

### P1
- **INP-06 — Sensitive data leak.** `InvoicingPaymentController::store()` stores `'request_data' => $request->all()` in audit `event_info` (violates BR-BIL-022; whitelist required).
- **SEC (auth-missing).** No `Gate::authorize` on: `InvoicingPaymentController::paymentDetails/downloadConsolidatedPdf/downloadSelectedPdf`; `InvoicingAuditLogController::auditAddNote/auditAddNoteUpdate/auditEventInfo/downloadAuditNotePdf`; `SubscriptionController::pricingDetails/billingDetails`. (`auditAddNoteUpdate` allows note edits with no permission check.)
- **SVC-01/02 — No service layer.** `BillingManagementController::generateInvoiceForOrganization()` (~170 ln) holds invoice business logic in the controller (GOD controller, 1036 ln).
- **Email job reliability.** `SendInvoiceEmailJob` lacks `$tries`/`$backoff`/`failed()`; `Auth::id()` is null in queue context (LOG-02).

### P2
- **RT-03 — broken route** (`view()` missing). **RT-04 — 3× route block.** **RT-02 — InvoicingController dead stub.**
- ZIP download synchronous (timeout risk for many invoices); temp PDF files not cleaned. Missing standard columns/indexes/FK (M-01..M-10). Activity-log event-name inconsistency ('Store' vs 'Created'). Class-name typo `BillTenatEmailSchedule`.

---

## DDL Tables (6 — prime_db_v4.sql)

| Table | Purpose | Status |
|-------|---------|--------|
| `prm_billing_cycles` | Billing cycle types (MONTHLY/QUARTERLY/YEARLY/ONE_TIME) | Clean |
| `bil_tenant_invoices` | Core invoice: plan rate × qty, 4 tax lines, net payable | Missing `created_by`, `deleted_at`; model has duplicate fillable + phantom `invoice_amount` |
| `bil_tenant_invoicing_modules_jnt` | Modules covered per invoice | Missing `is_active`, `created_by`, `deleted_at` |
| `bil_tenant_invoicing_payments` | Payment records (individual + consolidated) | Missing `created_by`, `deleted_at`, `is_active`; no index on `tenant_invoice_id` |
| `bil_tenant_invoicing_audit_logs` | Per-invoice event log w/ JSON event_info | **Model uses wrong column name** (P0); missing `updated_at`, `is_active`, `created_by`, `deleted_at`; no index on `action_date` |
| `bil_tenant_email_schedules` | Delayed invoice-email scheduling | No FK on `invoice_id`; missing `is_active`, `created_by`, `deleted_at`; model lacks SoftDeletes; class typo |

---

## Key Business Rules (FRD §4 — see FRD for all 43)

| Rule | Summary |
|------|---------|
| BR-BIL-006 | `invoice_no` globally unique, `INV-YYYYMMDD-NNN` (NNN = today's count + 1) |
| BR-BIL-007 | `billing_qty = max(min_billing_qty, active_student_count)` |
| BR-BIL-008 | Student count read from tenant DB; `Tenancy::end()` mandatory after |
| BR-BIL-011 | `net_payable = sub_total − discount + extra_charges + total_tax` |
| BR-BIL-012 | `payment_due_date = invoice_date + credit_days` |
| BR-BIL-013 | A billing-schedule entry can be invoiced only once (`bill_generated`) |
| BR-BIL-014/021/026 | Generation & payment postings must be atomic (all-or-nothing) |
| BR-BIL-020 | `paid_amount` cumulative — never decremented |
| BR-BIL-022 | Never store `$request->all()` in audit `event_info` — whitelist only |
| BR-BIL-040 | Gateway callback (future) verified by signature, not session auth |

---

## Cross-Module Dependencies

| Dependency | Direction | Integration Point |
|------------|-----------|-------------------|
| `prm_tenant`, `prm_tenant_plan_jnt`, `prm_tenant_plan_billing_schedule`, plan rate | BIL consumes | Tenant identity, subscription, rate, due entries, credit days (Prime module) |
| `glb_modules`, `sys_dropdown_table` (Dropdown) | BIL consumes | Module list per invoice; config status/mode lists |
| Tenant DB `std_students` | BIL reads (cross-DB) | `Tenancy::initialize()` to count active students for `total_user_qty` |
| `sys_users`, `sys_activity_logs` | BIL consumes/produces | Audit `performed_by`; activity logging |
| Prime billing schedule | BIL feeds | Sets `bill_generated=1`, links generated invoice |
| Razorpay (`razorpay/razorpay` v2.9) | BIL future | Gateway — installed, not integrated |
| Notification / Analytics | BIL feeds (future) | Generation/overdue alerts; revenue dashboards |

---

## Design Decisions Made
- BA FRD treats the **business capabilities** as REQ-BIL-001..017; the V2 "defect-fix FRs" (FR-BIL-014..026) are captured in the FRD **Technical Reconciliation Appendix (Section I)**, not as business REQs — defects are fixes to REQ-003/006/007/011/015, not separate features.
- Priority split set as P0=4 / P1=8 / P2=5 (Section 10.4) — billing cycle, invoice generation, invoice listing, individual payment are the P0 core.

---

## Lessons Learned

- [2026-06-29 | Technical Auditor] **The DDL `prm_billing_cycles` / `bil_*` tables carry no `deleted_at` and (cycles) no timestamps, yet every model uses `SoftDeletes`+default timestamps.** This makes the BA "REQ-BIL-001 Billing Cycle = Built/clean" status WRONG against the schema authority — the cycle CRUD breaks on a DDL-fresh DB. Always reconcile SoftDeletes/`$timestamps` against the actual table columns, not just `$fillable`. (MIG-BIL-001 P0.)
- [2026-06-29 | Technical Auditor] Confirmed: BR-BIL-023 NOT enforced — invoice `status` is taken from `$request->payment_status` (InvoicingPaymentController:75), never computed from `paid_amount >= net_payable_amount`. BR-BIL-006 invoice-number is a `count()+1` race (no lock). BR-BIL-014 generation IS atomic (DB::transaction closure) — contrast the payment paths which use `beginTransaction` with no rollback. The Spatie/super-admin `Gate::before` is at `app/Providers/AppServiceProvider.php:65-74` (confirms auth is NOT bypassed; dotted abilities resolve there). `view()` route confirmed broken (no method). Consolidated-payment Print crashes (`getCollection()`/`isNotEmpty()` on a Collection/float).
- [2026-06-25 | Seed] Billing is a **Prime module**; no standalone DDL — tables in `prime_db_v*.sql`. The `Tenancy::initialize()/end()` cross-DB student count is unique to this module.
- [2026-06-29 | BA] **Verify the "broken auth" trope before repeating it.** The seed file claimed duplicate policy registration silently bypasses all authorization. Live code has a Spatie `Gate::before` hook resolving the dotted ability strings — so the policies are *dead code*, not an auth bypass. The real auth holes are methods with **zero** `Gate::authorize`. Always trace how the ability string is resolved (policy method name vs Spatie permission) before asserting impact.
- [2026-06-29 | BA] **Recon notes can be stale.** The "3× route duplication resolved" note was wrong — duplication moved from module web.php (now empty) into the central web.php (still 3×). Always grep the central routes file, not just the module's.
- [2026-06-29 | BA] DDL is the authoritative side for the audit-log column name (`tenant_invoice_id`); the model/controllers are the wrong side. Fix code to DDL, not DDL to code, unless a migration is explicitly preferred.
- [2026-06-29 | BA] Controllers were hardened since the 2026-06 seed (most detail/print/email methods now authorize; payments use typed FormRequests). Re-verify each method live before reporting a SEC gap — half the seed-era SEC list is now closed.

---

## Pending Next Steps

| # | Work | Agent | Notes |
|---|------|-------|-------|
| 1 | DDL/Code gap analysis vs FRD §10.1 | `act as Technical Auditor` | Confirm Spatie permission rows exist; verify I.3 defects |
| 2 | Fix P0 audit-log column mismatch | `act as Developer` | Align model/relations/inserts to `tenant_invoice_id` |
| 3 | Fix P0 payment try/catch + rollback | `act as Developer` | store() + consolidatedStore() |
| 4 | Fix P0 duplicate fillable + phantom `invoice_amount` | `act as Developer` | BilTenantInvoice |
| 5 | Add permission checks to unprotected methods (I.3 SEC list) | `act as Developer` | + whitelist audit event_info |
| 6 | DDL migrations M-01..M-10 | `act as DB Architect` | standard columns, indexes, FK |
| 7 | Consolidate 3× central billing route block; remove/define `view()` | `act as Developer` | RT-03, RT-04 |
| 8 | Extract BillingService from GOD controller | `act as Backend Developer` | SVC-01/02 |

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-25 | Business Analyst | Knowledge file seeded from V2. Controllers undercounted (6); views "27+". |
| 2026-06-27 | Business Analyst | Counts re-verified: controllers 7, policies 8, views 43; both requirement formats confirmed. P0s unverified. |
| 2026-06-29 | Business Analyst | **Complete Analysis Pack produced** (`BIL_FRD_Complete_2026-06-29.md`: 17 REQ/43 BR/5 WF/7 RPT/12 ENH). Live-code three-way reconcile: REFUTED "auth fully bypassed" (Spatie Gate::before); corrected route-duplication location (central web.php 3×, module web.php empty); confirmed P0 audit FK mismatch, payment no-try/catch, duplicate fillable + phantom `invoice_amount`; logged resolved SEC methods; new finding `view()` route broken. DDL re-read from prime_db_v4.sql (6 tables). |
