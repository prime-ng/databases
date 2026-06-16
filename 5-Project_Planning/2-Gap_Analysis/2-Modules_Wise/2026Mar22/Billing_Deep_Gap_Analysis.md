# Billing Module — Production-Readiness Gap Analysis
**Date:** 2026-03-22  |  **Branch:** Brijesh_SmartTimetable  |  **Auditor:** Claude Code (Deep Audit)
**Module Path:** /Users/bkwork/Herd/prime_ai/Modules/Billing

---

## EXECUTIVE SUMMARY

| Category | Critical (P0) | High (P1) | Medium (P2) | Low (P3) | Total |
|----------|:---:|:---:|:---:|:---:|:---:|
| Security | 4 | 3 | 2 | 0 | 9 |
| Data Integrity | 2 | 3 | 2 | 0 | 7 |
| Architecture | 1 | 2 | 3 | 1 | 7 |
| Performance | 0 | 2 | 3 | 1 | 6 |
| Code Quality | 0 | 2 | 4 | 2 | 8 |
| Test Coverage | 0 | 1 | 2 | 0 | 3 |
| **TOTAL** | **7** | **13** | **16** | **4** | **40** |

### Module Scorecard

| Dimension | Score | Grade |
|-----------|:-----:|:-----:|
| Feature Completeness | 75% | B- |
| Security | 45% | F |
| Performance | 60% | D |
| Test Coverage | 30% | F |
| Code Quality | 55% | D+ |
| Architecture | 60% | D |
| **Overall** | **54%** | **D+** |

---

## SECTION 1: DATABASE INTEGRITY

### 1.1 DDL Tables (from prime_db_v2.sql)

| # | Table Name | Columns | PKs | FKs | Indexes | Unique Keys |
|---|-----------|---------|-----|-----|---------|-------------|
| 1 | `bil_tenant_invoices` | 30+ | 1 (id) | 3 (tenant_id, tenant_plan_id, billing_cycle_id) | 0 explicit | 1 (invoice_no) |
| 2 | `bil_tenant_invoicing_modules_jnt` | 3 | 1 (id) | 2 (tenant_invoice_id, module_id) | 0 | 1 (invoice+module) |
| 3 | `bil_tenant_invoicing_payments` | 13 | 1 (id) | 1 (tenant_invoice_id) | 0 | 0 |
| 4 | `bil_tenant_invoicing_audit_logs` | 8 | 1 (id) | 2 (tenant_invoice_id, performed_by) | 0 | 0 |
| 5 | `bil_tenant_email_schedules` | 5 | 1 (id) | 0 | 0 | 0 |

### 1.2 DDL vs Model Column Gaps

| Issue ID | Severity | Table | Issue |
|----------|----------|-------|-------|
| DB-01 | **P0** | `bil_tenant_invoices` | DDL has FK column `tenant_invoice_id` in audit logs, but model uses `tenant_invoicing_id` (FK name mismatch). InvoicingAuditLog model line 32 uses `tenant_invoicing_id` but DDL defines it as `tenant_invoice_id`. |
| DB-02 | **P1** | `bil_tenant_invoices` | Model `BilTenantInvoice` has `SoftDeletes` trait but DDL has NO `deleted_at` column. Also missing `created_by` column per project rules. |
| DB-03 | **P1** | `bil_tenant_invoicing_payments` | Model `InvoicingPayment` has `SoftDeletes` trait but DDL has NO `deleted_at` column. |
| DB-04 | **P1** | `bil_tenant_invoicing_audit_logs` | Model `InvoicingAuditLog` has `SoftDeletes` trait but DDL has NO `deleted_at`, no `updated_at`, no `is_active` column. |
| DB-05 | **P2** | `bil_tenant_invoicing_modules_jnt` | Model `BillOrgInvoicingModulesJnt` has `SoftDeletes` trait but DDL has NO `deleted_at`, `is_active`, or `created_by` columns. |
| DB-06 | **P2** | `bil_tenant_email_schedules` | Model `BillTenatEmailSchedule` does NOT use `SoftDeletes` (violates project rule). Also missing `is_active`, `deleted_at`, `created_by` per project rules. |
| DB-07 | **P0** | `bil_tenant_invoices` | BilTenantInvoice model `$fillable` has DUPLICATE entries: `paid_amount`, `currency`, `status`, `credit_days`, `payment_due_date`, `is_recurring`, `auto_renew`, `remarks` each appear TWICE. File: `BilTenantInvoice.php` lines 20-69. |
| DB-08 | **P2** | `bil_tenant_email_schedules` | DDL has NO FK from `invoice_id` to `bil_tenant_invoices.id`. Missing referential integrity. |
| DB-09 | **P2** | `bil_tenant_invoicing_payments` | DDL has NO index on `tenant_invoice_id`. High-volume table needs index for join performance. |
| DB-10 | **P2** | `bil_tenant_invoicing_audit_logs` | DDL has NO index on `action_date` for range queries used in controller. |

### 1.3 Missing Standard Columns (per project rules: id, is_active, created_by, created_at, updated_at, deleted_at)

| Table | Missing Columns |
|-------|----------------|
| `bil_tenant_invoices` | `created_by` |
| `bil_tenant_invoicing_modules_jnt` | `is_active` (missing in DDL but not in some models), `created_by`, `deleted_at` |
| `bil_tenant_invoicing_payments` | `created_by`, `deleted_at`, `is_active` |
| `bil_tenant_invoicing_audit_logs` | `updated_at`, `is_active`, `created_by`, `deleted_at` |
| `bil_tenant_email_schedules` | `is_active`, `created_by`, `deleted_at` |

---

## SECTION 2: ROUTE INTEGRITY

### 2.1 Routes (from routes/web.php, central domain)

All Billing routes are in `routes/web.php` under `billing.` prefix with `auth` + `verified` middleware.

| Route Group | Controller | Methods | Middleware |
|-------------|-----------|---------|------------|
| billing-management | BillingManagementController | index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus, view, downloadPDF, sendEmail, scheduleEmail, subscriptionDetails, invoiceDetails, moduleDetails, printData, invoiceRemarks, updateInvoiceRemarks, AuditLog | auth, verified |
| subscription | SubscriptionController | index, create, store, show, edit, update, destroy, pricingDetails, billingDetails | auth, verified |
| invoicing-payment | InvoicingPaymentController | index, create, store, show, edit, update, destroy, paymentDetails, consolidatedStore, downloadConsolidatedPdf, downloadSelectedPdf | auth, verified |
| invoicing-audit-log | InvoicingAuditLogController | index, create, store, show, edit, update, destroy, auditAddNote, auditAddNoteUpdate, auditEventInfo, downloadAuditNotePdf | auth, verified |
| billing-cycle | BillingCycleController | index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus | auth, verified |

### 2.2 Route Issues

| Issue ID | Severity | Issue |
|----------|----------|-------|
| RT-01 | **P1** | No `EnsureTenantHasModule` middleware on billing route group — however Billing is a Prime-level module so tenant middleware is N/A. But there is no rate limiting or role-based middleware. |
| RT-02 | **P2** | `InvoicingController` has routes via resource but is essentially a STUB (all methods empty). Unreferenced in web.php routes. Dead code. |
| RT-03 | **P2** | `BillingManagementController` has `view($id)` routed but method signature takes `$id` raw param, not route model binding. |

---

## SECTION 3: CONTROLLER AUDIT

### 3.1 Authorization Issues (CRITICAL)

| Issue ID | Severity | Controller | Method | Line | Issue |
|----------|----------|-----------|--------|------|-------|
| SEC-01 | **P0** | BillingManagementController | `index()` | 54-62 | Uses `Gate::any()` with `\|\| abort(403)` pattern. `Gate::any()` returns the Gate response but the `\|\|` operator treats false-like responses incorrectly. Should use `Gate::check()` or proper `authorize()`. |
| SEC-02 | **P0** | BillingManagementController | `store()` | 593-627 | Uses `Gate::authorize('prime.billing-management.create')` BUT uses `Request $request` (NOT FormRequest). No validation on `$request->ids` beyond `isset`. Invoice generation for arbitrary IDs. |
| SEC-03 | **P0** | BillingManagementController | `subscriptionDetails()`, `invoiceDetails()`, `moduleDetails()`, `view()` | Various | These AJAX methods have NO Gate::authorize calls. Anyone authenticated can view any tenant's billing data. |
| SEC-04 | **P1** | BillingManagementController | `printData()` | 136 | Has `Gate::authorize('prime.billing-management.print')` BUT not all sub-paths check permissions (only `consolidated-payment` and `payment-reconcilation` sub-types check additional Gate). |
| SEC-05 | **P1** | InvoicingPaymentController | `paymentDetails()` | 108-116 | NO Gate::authorize. Any authenticated user can view payment details for any invoice. |
| SEC-06 | **P1** | InvoicingAuditLogController | `auditAddNote()` | 78 | NO Gate::authorize. Any authenticated user can view audit notes. |
| SEC-07 | **P2** | InvoicingAuditLogController | `auditAddNoteUpdate()` | 87-98 | NO Gate::authorize. Any authenticated user can UPDATE audit notes. |
| SEC-08 | **P2** | InvoicingAuditLogController | `auditEventInfo()` | 101-111 | NO Gate::authorize. Any authenticated user can view event info. |
| SEC-09 | **P2** | InvoicingAuditLogController | `downloadAuditNotePdf()` | 113-145 | NO Gate::authorize. Any authenticated user can download audit PDFs. |

### 3.2 Input Handling Issues

| Issue ID | Severity | Controller | Method | Line | Issue |
|----------|----------|-----------|--------|------|-------|
| INP-01 | **P0** | InvoicingPaymentController | `store()` | 48-106 | Uses `StoreInvoicePaymentRequest` but then accesses `$request->consolidated_amount` which sets to `$request->amount_paid` (not from validated). Also `$request->date`, `$request->payment_mode`, `$request->pay_mode_other`, etc. are used DIRECTLY from request, not from `$request->validated()`. |
| INP-02 | **P1** | InvoicingPaymentController | `consolidatedStore()` | 154-255 | Uses `ConsolidatedPaymentRequest` but accesses `$request->invoice_ids`, `$request->new_payment`, `$request->payment_status` which are NOT in the FormRequest rules. Unvalidated array input. |
| INP-03 | **P1** | BillingManagementController | `index()` | 78-89 | `$request->only()` pulls raw, unvalidated filter data including `tenat_id` (typo in field name). |
| INP-04 | **P2** | BillingManagementController | `downloadPDF()` | 475-531 | `$request->ids` array not validated. Any array of IDs accepted. |
| INP-05 | **P2** | BillingManagementController | `sendEmail()` | 536-549 | `$request->ids` array not validated. Could dispatch jobs for non-existent invoices. |
| INP-06 | **P1** | InvoicingPaymentController | `store()` | 94 | `$request->all()` logged inside `event_info` JSON. Leaks ALL request data including potentially sensitive fields. |

### 3.3 Error Handling Issues

| Issue ID | Severity | Controller | Method | Line | Issue |
|----------|----------|-----------|--------|------|-------|
| ERR-01 | **P0** | InvoicingPaymentController | `store()` | 52-106 | `DB::beginTransaction()` called but NO `try/catch`. If any exception occurs, transaction is never rolled back. |
| ERR-02 | **P1** | InvoicingPaymentController | `consolidatedStore()` | 158-255 | Same issue: `DB::beginTransaction()` with no `try/catch` wrapper. |
| ERR-03 | **P2** | BillingManagementController | `printData()` | 170-176 | Line 172: `$totalPayable = $recordPayment->getCollection()->sum(...)` — `getCollection()` is a paginator method but `->get()` returns a Collection, not a paginator. Will throw `Method not found` error. |
| ERR-04 | **P2** | BillingManagementController | `generateInvoiceForOrganization()` | 644 | Returns bare `false` on failure instead of the expected `['status' => false, 'message' => ...]` format. Caller at line 611 checks `$result['status']`, so returning `false` will throw array access on bool. |

### 3.4 Activity Logging Issues

| Issue ID | Severity | Issue |
|----------|----------|-------|
| LOG-01 | **P2** | Multiple places use `activityLog($model, 'Store', ...)` — the event name 'Store' is inconsistent. Standard should be 'Created', 'Updated', 'Deleted'. |
| LOG-02 | **P3** | `SendInvoiceEmailJob::handle()` line 32 calls `activityLog()` inside a queued job — `Auth::id()` will be null in queue worker context. |

---

## SECTION 4: MODEL AUDIT

| Model | Table | SoftDeletes | Fillable OK | Casts OK | Relationships | Issues |
|-------|-------|:-----------:|:-----------:|:--------:|:-------------:|--------|
| BilTenantInvoice | bil_tenant_invoices | YES | **NO** (duplicates) | YES (4 dates, 2 booleans) | 5 (tenant, tenantPlan, auditLogs, billingCycle, payments) | Duplicate fillable entries; DDL has no deleted_at |
| BillingCycle | prm_billing_cycles | YES | YES | YES (3) | 4 (tenantPlanRates, billingSchedules, invoices, plans) | Maps to `prm_` prefix table — cross-module boundary |
| InvoicingPayment | bil_tenant_invoicing_payments | YES | YES | YES (4) | 3 (invoice, paymentStatusData, paymentModeData) | DDL has no deleted_at |
| InvoicingAuditLog | bil_tenant_invoicing_audit_logs | YES | YES | NO (no casts defined) | 2 (invoice, user) | FK column mismatch: model uses `tenant_invoicing_id`, DDL has `tenant_invoice_id`; no casts for JSON `event_info` or date `action_date` |
| BillOrgInvoicingModulesJnt | bil_tenant_invoicing_modules_jnt | YES | YES | NO (none) | 1 (module) | DDL has no deleted_at |
| BillTenatEmailSchedule | bil_tenant_email_schedules | **NO** | YES | NO (none) | 0 | Missing SoftDeletes (violates project rules); no relationships; typo in class name `Tenat` |

### Model Issues

| Issue ID | Severity | Issue |
|----------|----------|-------|
| MDL-01 | **P0** | `InvoicingAuditLog` FK column `tenant_invoicing_id` does not match DDL column `tenant_invoice_id`. All audit log inserts in controllers use `tenant_invoicing_id`. This will fail on a fresh DB with DDL schema. |
| MDL-02 | **P1** | `InvoicingAuditLog` has no cast for `event_info` (should be `'array'` or `'json'`). Controller at line 84 manually `json_encode()`s it. |
| MDL-03 | **P1** | `InvoicingAuditLog` has no cast for `action_date` (should be `'datetime'`). |
| MDL-04 | **P2** | `BillTenatEmailSchedule` — typo in class name (`Tenat` instead of `Tenant`). |
| MDL-05 | **P2** | `BillingCycle` model references `prm_billing_cycles` table — a Prime DB table living in the Billing module. Cross-module coupling. |

---

## SECTION 5: SERVICE LAYER AUDIT

| Issue ID | Severity | Issue |
|----------|----------|-------|
| SVC-01 | **P1** | **NO service classes exist** in Billing module. All business logic (invoice generation, payment processing, reconciliation) lives directly in controllers. BillingManagementController `generateInvoiceForOrganization()` is ~170 lines of complex business logic (lines 633-800+). |
| SVC-02 | **P1** | Tenancy::initialize/end() called inside controller (line 669-673). Should be encapsulated in a service. |

---

## SECTION 6: FORM REQUEST AUDIT

| FormRequest | Used In | Rules Complete | Issues |
|-------------|---------|:--------------:|--------|
| BillingCycleRequest | BillingCycleController store/update | YES | Clean implementation |
| StoreInvoicePaymentRequest | InvoicingPaymentController store | Partial | Rules exist but controller accesses non-validated fields directly |
| ConsolidatedPaymentRequest | InvoicingPaymentController consolidatedStore | Partial | Missing validation for `invoice_ids[]`, `new_payment[]`, `payment_status[]` arrays |

| Issue ID | Severity | Issue |
|----------|----------|-------|
| FRQ-01 | **P1** | No FormRequest for BillingManagementController `store()` (invoice generation) — uses raw `Request`. |
| FRQ-02 | **P1** | No FormRequest for `sendEmail()`, `scheduleEmail()`, `downloadPDF()` — all accept `Request`. |
| FRQ-03 | **P2** | `ConsolidatedPaymentRequest` missing rules for critical array fields: `invoice_ids`, `new_payment`, `payment_status`. |
| FRQ-04 | **P2** | `StoreInvoicePaymentRequest` — controller accesses `$request->date` instead of `$request->validated()['date']`. |

---

## SECTION 7: POLICY AUDIT

### 7.1 Policy Registration (AppServiceProvider.php)

| Registration | Issue |
|-------------|-------|
| `Gate::policy(BilTenantInvoice::class, BillingManagementPolicy::class)` Line 617 | OK |
| `Gate::policy(BilTenantInvoice::class, InvoicingPolicy::class)` Line 618 | **CONFLICT**: Same model registered with TWO different policies. Second registration OVERWRITES first. BillingManagementPolicy is dead. |
| `Gate::policy(InvoicingPayment::class, ConsolidatedPaymentPolicy::class)` Line 620 | InvoicingPayment model registered 4 times (lines 620-623). Only LAST policy (InvoicingPaymentPolicy) is effective. |
| `Gate::policy(InvoicingPayment::class, PaymentReconciliationPolicy::class)` Line 621 | Overwritten by next registration |
| `Gate::policy(InvoicingPayment::class, SubscriptionPolicy::class)` Line 622 | Overwritten by next registration |
| `Gate::policy(InvoicingPayment::class, InvoicingPaymentPolicy::class)` Line 623 | This is the ONLY effective policy for InvoicingPayment |

| Issue ID | Severity | Issue |
|----------|----------|-------|
| POL-01 | **P0** | `BilTenantInvoice` model has TWO Gate::policy registrations (lines 617-618). Second (`InvoicingPolicy`) overwrites first (`BillingManagementPolicy`). BillingManagementPolicy is effectively dead code. Controllers use `Gate::authorize('prime.billing-management.*')` which are NOT defined in InvoicingPolicy. |
| POL-02 | **P0** | `InvoicingPayment` model registered with 4 different policies (lines 620-623). Only `InvoicingPaymentPolicy` (last) is effective. ConsolidatedPaymentPolicy, PaymentReconciliationPolicy, SubscriptionPolicy are all dead code. |
| POL-03 | **P1** | `ConsolidatedPaymentPolicy` references non-existent model `App\Models\ConsolidatedPayment`. |
| POL-04 | **P1** | `PaymentReconciliationPolicy` references non-existent model `App\Models\PaymentReconciliation`. |
| POL-05 | **P2** | `SubscriptionPolicy` uses `InvoicingPayment` as the model type-hint but should logically be a subscription-related model. |
| POL-06 | **P2** | Controllers use `Gate::authorize('prime.billing-management.*')` pattern (Gate::define style) but policies are registered via `Gate::policy()`. The `Gate::authorize()` calls with string abilities like `prime.billing-management.create` will NOT route through the policy — they need explicit `Gate::define()` registrations. |

---

## SECTION 8: VIEW AUDIT

### 8.1 View Files (67 blade files total)

Views are well-organized with partials for each billing sub-feature:
- `billing-cycle/` (4 views: index, create, edit, trash)
- `billing-management/` (main index + 20+ partials for details, PDF, print)
- `components/layouts/master.blade.php`

| Issue ID | Severity | Issue |
|----------|----------|-------|
| VW-01 | **P3** | No CSRF token verification visible in AJAX calls from views (would need to check JS). |
| VW-02 | **P3** | PDF views have no input sanitization for displayed data. |

---

## SECTION 9: SECURITY AUDIT

| Check | Status | Details |
|-------|:------:|--------|
| SEC-AUTH: All methods have Gate/Policy | FAIL | 8+ methods missing authorization (subscriptionDetails, invoiceDetails, moduleDetails, paymentDetails, auditAddNote, auditEventInfo, downloadAuditNotePdf, etc.) |
| SEC-VALID: FormRequest on all mutations | FAIL | store(), sendEmail(), scheduleEmail(), downloadPDF() use raw Request |
| SEC-MASS: No $request->all() for create | FAIL | InvoicingPaymentController uses individual fields but MenuController line 127 uses $request->all() |
| SEC-SQL: No raw queries | PASS | All queries use Eloquent/Query Builder |
| SEC-XSS: Blade {{ }} escaping | PASS | Views use {{ }} |
| SEC-FILE: File upload validation | WARN | ZIP temp files created in storage/app with unlink — temp files may persist on error |
| SEC-RATE: Rate limiting | FAIL | No rate limiting on any endpoint |
| SEC-LOG: Sensitive data in logs | FAIL | `$request->all()` stored in audit event_info JSON (line 94, InvoicingPaymentController) |

---

## SECTION 10: PERFORMANCE AUDIT

| Check | Status | Details |
|-------|:------:|--------|
| PERF-N+1: Eager loading | WARN | `index()` loads `Tenant::get()` and `User::get()` (ALL records) on every page load (line 117-118). |
| PERF-PAG: Pagination | PARTIAL | Main queries paginate(10) but `Tenant::get()` and `User::get()` load all records. |
| PERF-IDX: Query columns indexed | FAIL | `action_date`, `payment_reconciled` used in WHERE but not indexed. |
| PERF-CACHE: Caching | FAIL | No caching anywhere. Dropdown, Tenant, User queries re-run on every request. |
| PERF-EAGER: Relationship loading | WARN | `buildMainBillingQuery()` eager loads 3 levels deep but some views may N+1 on sub-relations. |
| PERF-ZIP: ZIP generation | WARN | ZIP files generated synchronously in HTTP request. Large invoice batches will timeout. Should be queued. |

---

## SECTION 11: ARCHITECTURE AUDIT

| Check | Status | Details |
|-------|:------:|--------|
| ARCH-SRP: Controller SRP | FAIL | BillingManagementController is a GOD controller (~800+ lines) handling invoicing, printing, PDF, email, audit, subscription details — 7+ responsibilities. |
| ARCH-SVC: Service layer | FAIL | Zero service classes. All business logic in controllers. |
| ARCH-TENANT: Tenancy isolation | WARN | `Tenancy::initialize()` and `Tenancy::end()` called directly in controller for student count. Should be a service. |
| ARCH-NAME: Naming consistency | WARN | Typo: `tenat_id` filter name (should be `tenant_id`). Class name `BillTenatEmailSchedule` has typo. |
| ARCH-DRY: Code duplication | FAIL | Filter parsing logic repeated in `index()`, `printData()`, `downloadPDF()`. Now partially refactored into private methods but `buildQuery()` backward-compat wrapper is dead code. |
| ARCH-MOD: Module boundaries | WARN | Billing module models reference Prime module models (TenantPlan, TenantPlanRate, etc.) — acceptable for cross-module Prime data but BillingCycle model maps to `prm_` prefix table. |

---

## SECTION 12: TEST COVERAGE

### 12.1 Existing Tests

File: `Modules/Billing/tests/Unit/BillingModuleTest.php` (~315 lines)

| Test Category | Count | Coverage |
|---------------|:-----:|----------|
| Model Structure Tests | 24 | All 6 models tested for table, SoftDeletes, fillable, casts, relationships |
| Controller Auth Tests | 19 | BillingCycleController (11 methods), BillingManagementController (6 methods flagged as known gaps) |
| Architecture Tests | 11 | Class existence checks for controllers, models, requests, job, mail |
| Policy Tests | 4 | Standard methods check for 3 policies + BillingManagementPolicy gap detection |

### 12.2 Test Gaps

| Issue ID | Severity | Issue |
|----------|----------|-------|
| TST-01 | **P1** | Zero Feature/Integration tests. No actual HTTP request testing. All tests are unit-level reflection/existence checks. |
| TST-02 | **P2** | No test for invoice generation business logic (`generateInvoiceForOrganization`). |
| TST-03 | **P2** | No test for consolidated payment logic. |
| TST-04 | **P2** | No test for email scheduling. |

---

## SECTION 13: BUSINESS LOGIC COMPLETENESS

| Feature | Status | Issues |
|---------|:------:|--------|
| Invoice Generation | 80% | Works but no validation for duplicate invoices on same period. `generateInvoiceForOrganization()` returns `false` instead of array on failure. |
| Payment Recording | 70% | Single payment works. Consolidated payment works. BUT no rollback on partial failure in consolidated. |
| PDF Generation | 85% | Invoice, subscription, reconciliation PDFs. But ZIP generation is synchronous (timeout risk). |
| Email Sending | 75% | Job-based email dispatch. Schedule email works. But `auth()->id()` is null in queued context. |
| Audit Logging | 70% | Dual audit: sys_activity_logs + bil_tenant_invoicing_audit_logs. But FK column name mismatch may cause failures. |
| Payment Reconciliation | 60% | Basic filter/view works. No automated reconciliation logic. |
| Billing Cycles | 95% | Full CRUD with soft delete, restore, force delete, toggle status. Clean implementation. |

---

## PRIORITY FIX PLAN

### P0 — Critical (Fix immediately)

1. **POL-01/POL-02**: Fix duplicate Gate::policy registrations in AppServiceProvider. Use Gate::define() for non-model-based abilities, or create distinct model classes.
2. **DB-01/MDL-01**: Fix InvoicingAuditLog FK column: change `tenant_invoicing_id` to `tenant_invoice_id` across model and all controllers OR update DDL.
3. **DB-07**: Remove duplicate fillable entries in BilTenantInvoice model.
4. **SEC-01**: Fix Gate::any() usage in BillingManagementController::index() — use `Gate::check()` or `$this->authorize()`.
5. **ERR-01/ERR-02**: Wrap DB::beginTransaction() in try/catch blocks in InvoicingPaymentController.
6. **SEC-03**: Add Gate::authorize() to all AJAX detail methods (subscriptionDetails, invoiceDetails, moduleDetails, view).

### P1 — High (Fix within 1 sprint)

7. **SVC-01**: Extract business logic into BillingService (invoice generation, payment processing).
8. **INP-02/FRQ-03**: Add validation rules for array inputs (invoice_ids, new_payment, payment_status) in ConsolidatedPaymentRequest.
9. **FRQ-01/FRQ-02**: Create FormRequests for invoice generation, email, and PDF endpoints.
10. **SEC-05/SEC-06**: Add Gate::authorize to paymentDetails(), auditAddNote(), auditAddNoteUpdate().
11. **INP-06**: Remove `$request->all()` from audit event_info logging.
12. **TST-01**: Write Feature tests for invoice generation, payment, and email flows.

### P2 — Medium (Fix within 2 sprints)

13. **DB-02/DB-03**: Add `deleted_at` columns to DDL or remove SoftDeletes trait where DDL does not support it.
14. **MDL-02/MDL-03**: Add proper casts to InvoicingAuditLog.
15. **ERR-03**: Fix `printData()` consolidated-payment path calling `getCollection()` on Collection.
16. **ERR-04**: Fix `generateInvoiceForOrganization()` to return proper array format on all paths.
17. **PERF-N+1**: Replace `Tenant::get()` / `User::get()` with filtered/paginated queries.

### P3 — Low (Fix in maintenance)

18. **MDL-04**: Rename `BillTenatEmailSchedule` to `BillTenantEmailSchedule`.
19. **LOG-01**: Standardize activity log event names.
20. **LOG-02**: Fix `auth()->id()` in queued job context.

---

## EFFORT ESTIMATION

| Priority | Items | Estimated Hours |
|----------|:-----:|:---------------:|
| P0 | 6 | 8-12 hrs |
| P1 | 6 | 16-24 hrs |
| P2 | 5 | 12-16 hrs |
| P3 | 3 | 4-6 hrs |
| **Total** | **20** | **40-58 hrs** |
