# Module Knowledge Summary: Billing (BIL)

**Date:** 2026-06-27
**Agent:** Business Analyst
**Source Files:**
- `4-Requirement_Module_wise/4-Initial_Requirements/V2/BIL_Billing_Requirement.md` (consolidated V2)
- `4-Requirement_Module_wise/2-Module_Requirement_V1/Billing_v1/` (screen-spec folder — both formats confirmed)
- `prime_db_v2.sql` — **NO standalone DDL file; all `bil_*` tables defined here**
- `Herd/prime_ai/Modules/Billing/` (live filesystem verification — two passes: seeding 2026-06-25 + update 2026-06-27)

**Knowledge File:** `AI_Brain/module-knowledge/BIL_Billing.md`

---

## 1. Module Identity — PRIME MODULE (Not Tenant)

| Item | Finding |
|------|---------|
| Module Code | `BIL` |
| **Module Type** | **PRIME** — operates on `prime_db` (central SaaS database), NOT `tenant_db` |
| Table Prefix | `bil_*` (+ shared `prm_billing_cycles`) |
| **DDL Location** | **`prime_db_v2.sql`** — NO standalone DDL file in `2-DDL_Tenant_Consolidated/` |
| Laravel Path | `Modules/Billing/` |
| DDL Version | Embedded in prime_db_v2.sql (5 tables) |
| V2 Requirement | `BIL_Billing_Requirement.md` (consolidated V2) |
| Both Req Formats | ✅ Confirmed — consolidated V2 + `Billing_v1/` screen-spec folder |
| FRD Status | Not yet generated |

**Critical architectural distinction:** BIL is the only module in this project where:
1. The database is `prime_db`, not `tenant_db` — Super Admin bills ALL school tenants from a single central panel
2. There is no standalone DDL file — searching `2-DDL_Tenant_Consolidated/` for `BIL*` or `Billing*` returns nothing
3. The module temporarily **connects to a tenant's isolated database** to count active students for billing quantity (`Tenancy::initialize()` / `Tenancy::end()` pattern)

---

## 2. The Critical Status Correction: 100% → ~55%

**The most important finding from this module's knowledge work:**

BIL was listed in `AI_Brain/memory/progress.md` under **"Completed Modules (100%)"** at the start of this session. This was incorrect. The knowledge file seeded 2026-06-25 documented 7 P0 critical issues and ~55% actual completion. The progress.md entry was never updated after seeding.

**This session:** BIL was moved from the "Completed (100%)" section to "In Progress / Code Scaffold Present (~55%)" with the full gap inventory. Any previous planning that assumed Billing was complete must be revisited.

---

## 3. Actual vs. Baseline Comparison

| Metric | Seeded (2026-06-25) | Re-Verified (2026-06-27) | Change |
|--------|---------------------|--------------------------|--------|
| Controllers | 6 (undercount) | **7** | +1 (BillingCycleController found) |
| Models | 6 | **6** | No change |
| FormRequests | 3 | **3** | No change (all partial) |
| Policies | 7 (undercount) | **8** | +1 (BillingCyclePolicy found) |
| Jobs | 1 | **1** (`SendInvoiceEmailJob`) | No change |
| Views | "27+" (undercount) | **43** | Corrected |
| Module Route Lines | Unknown | **11 lines** in `Modules/Billing/routes/web.php` | Clarified |
| Unit Tests | 1 file (~55 cases) | **1 file** | No change |
| Feature Tests | 0 | **0** | Critical gap |
| Services | 0 | **0** | P0 gap (GOD controller) |
| Migrations | 0 | **0** | Gap |
| Completion % | "100% complete" (wrong) | **~55%** | Corrected |

**Note on routes:** Prior seeding referenced "49 routes" — those were in central `routes/web.php` duplicated 3× across 3 central domains (RT-04). The actual module route file is 11 lines post-2026-04-02 migration. Whether the old central duplicates were cleaned up requires verification.

---

## 4. DDL Structure (5 Tables in prime_db_v2.sql)

Since there is no standalone DDL file, all schema changes require migrations against `prime_db`. The 5 tables and their known issues:

| Table | Purpose | Known DDL Issues |
|-------|---------|-----------------|
| `prm_billing_cycles` | Billing cycle types (MONTHLY, QUARTERLY, YEARLY, ONE_TIME) | Clean |
| `bil_tenant_invoices` | Core invoice document — plan rate × qty, 4 tax lines, net payable | Missing `created_by`, `deleted_at` |
| `bil_tenant_invoicing_modules_jnt` | Modules included in each invoice | Missing `is_active`, `created_by`, `deleted_at` |
| `bil_tenant_invoicing_payments` | Individual + consolidated payment records | Missing `created_by`, `deleted_at`, `is_active`; missing index on `tenant_invoice_id` |
| `bil_tenant_invoicing_audit_logs` | Invoice lifecycle event log with JSON `event_info` | **P0 FK column mismatch**; missing `updated_at`, `is_active`, `created_by`, `deleted_at`; missing index on `action_date` |
| `bil_tenant_email_schedules` | Delayed email scheduling for invoices | No FK on `invoice_id`; missing standard columns; model class name has typo |

---

## 5. Seven P0 Critical Issues (All Unverified for Resolution)

The seeding audit (2026-06-25) identified 7 P0 issues. The update pass (2026-06-27) confirmed they remain open — Technical Audit needed to verify whether any have been resolved.

### P0-1: Duplicate Policy Registrations — ALL Authorization is Silently Dead (POL-01, POL-02)

**Location:** `AppServiceProvider.php` lines 617–623

`BilTenantInvoice` model is registered with TWO policies — `BillingManagementPolicy` is overwritten by `InvoicingPolicy`. `InvoicingPayment` model is registered with FOUR policies — only the last (`InvoicingPaymentPolicy`) survives.

**Impact:** `Gate::authorize('prime.billing-management.*')` calls in `BillingManagementController` resolve against `InvoicingPolicy` which has no such ability strings defined. Authorization fails **silently open** — no exception, no 403, just unchecked access.

**Additional damage:** `ConsolidatedPaymentPolicy` references non-existent `App\Models\ConsolidatedPayment` (POL-03). `PaymentReconciliationPolicy` references non-existent `App\Models\PaymentReconciliation` (POL-04). All 4 dead policy classes should be deleted.

**Fix:** One model = one policy. Redesign surviving policy to handle all ability strings OR switch to `Gate::define()` pattern.

### P0-2: FK Column Name Mismatch — Audit Log Inserts Fail Silently (DB-01, MDL-01)

**Location:** `bil_tenant_invoicing_audit_logs` DDL vs `InvoicingAuditLog` model

DDL defines column `tenant_invoice_id`. Model `$fillable` and all controller insert calls use `tenant_invoicing_id`. On a fresh database, **ALL audit log inserts fail silently** — null constraint or column not found error at runtime.

**Also:** Model missing `'event_info' => 'array'` cast (MDL-02) and `'action_date' => 'datetime'` cast (MDL-03).

### P0-3: DB Transactions Without try/catch (ERR-01, ERR-02)

**Location:** `InvoicingPaymentController::store()` line 52 and `consolidatedStore()` line 158

Both methods call `DB::beginTransaction()` with NO surrounding try/catch. Any exception leaves an open transaction that never rolls back → data inconsistency until connection reset.

**Also:** `generateInvoiceForOrganization()` (ERR-04) returns bare `false` on failure. Caller at line 611 accesses `$result['status']` → array access on boolean = fatal error.

### P0-4: Nine Controller Methods With No Gate::authorize (SEC-01 to SEC-09)

| Method | Issue |
|--------|-------|
| `BillingManagementController::index()` | `Gate::any()` used with incorrect `||` operator (SEC-01) |
| `BillingManagementController::subscriptionDetails()` | No auth — exposes ANY tenant's subscription data (SEC-03) |
| `BillingManagementController::invoiceDetails()` | No auth — exposes ANY tenant's invoice data (SEC-03) |
| `BillingManagementController::moduleDetails()` | No auth (SEC-03) |
| `BillingManagementController::view()` | No auth (SEC-03) |
| `BillingManagementController::printData()` | Partial gate check only (SEC-04) |
| `InvoicingPaymentController::paymentDetails()` | No auth (SEC-05) |
| `InvoicingAuditLogController::auditAddNote()` | No auth (SEC-06) |
| `InvoicingAuditLogController::auditAddNoteUpdate()` | No auth — anyone can update billing notes (SEC-07) |
| `InvoicingAuditLogController::auditEventInfo()` | No auth (SEC-08) |
| `InvoicingAuditLogController::downloadAuditNotePdf()` | No auth (SEC-09) |

### P0-5: Sensitive Data Leak in Audit Log (INP-06)

**Location:** `InvoicingPaymentController::store()` line 94

Full `$request->all()` is stored in `event_info` JSON column — can include `gateway_response`, credentials, or raw card references in plaintext.

**Fix:** Whitelist only safe fields: `['amount_paid', 'payment_mode', 'payment_status', 'transaction_id', 'currency', 'payment_date']`

### P0-6: Duplicate $fillable in BilTenantInvoice (DB-07)

8 fields duplicated in `BilTenantInvoice.php` lines 20–69: `paid_amount`, `currency`, `status`, `credit_days`, `payment_due_date`, `is_recurring`, `auto_renew`, `remarks` each appear twice.

### P0-7: Razorpay Webhook Architecture (SEC-004)

Gateway not yet implemented, but when integrated: webhook route MUST NOT be behind `auth` middleware. Must register in `routes/api.php`, verify via HMAC signature (`X-Razorpay-Signature` header + `razorpay.webhook_secret`), return HTTP 400 on failure (not 401/403).

---

## 6. The Unique Cross-Database Pattern (Tenancy::initialize / end)

BIL is the **only Prime module** that temporarily initialises a tenant's isolated database to read data. This happens during invoice generation to count active students for `total_user_qty`.

```php
// Correct pattern — must always follow this exact sequence
Tenancy::initialize($tenant);
$studentCount = DB::table('std_students')->where('is_active', 1)->count();
Tenancy::end();

// If Tenancy::end() is missing:
// → All subsequent prime_db queries run against the tenant's DB
// → Activity logs, invoice writes, audit entries go into the WRONG database
// → Silent data corruption in both databases
```

**Business Rule BR-011:** `Tenancy::end()` MUST be called after the student count query. This is enforced by convention only — no framework-level guard exists.

**Recommended fix:** Extract this into `BillingService::countTenantStudents(Tenant $tenant): int` which encapsulates the `initialize/end` boundary and cannot be called without `end()`.

---

## 7. GOD Controller — Zero Service Layer

`BillingManagementController` is approximately 800+ lines. It contains:
- Invoice generation logic (~170 lines in `generateInvoiceForOrganization()`)
- Tenant student counting (cross-DB query — should be isolated)
- PDF generation
- ZIP bundling
- Email dispatch
- Activity logging
- Dashboard data assembly

**There are 0 service files** in `Modules/Billing/app/Services/`. All business logic is in controllers.

**Minimum extract required:**
| Service Method | Extract From |
|----------------|-------------|
| `BillingService::generateInvoice(int $scheduleId): array` | `BillingManagementController::generateInvoiceForOrganization()` |
| `BillingService::recordPayment(array $data): InvoicingPayment` | `InvoicingPaymentController::store()` |
| `BillingService::countTenantStudents(Tenant $tenant): int` | Inline Tenancy calls in BillingManagementController |

---

## 8. Feature Area Completion Map

| Feature Area | Completion | P0 Issues |
|-------------|:----------:|-----------|
| Billing Cycle Master CRUD | 95% | — |
| Invoice Generation Engine | 80% | SEC-02, ERR-04, FRQ-01 |
| Billing Management Dashboard | 75% | SEC-01, SEC-03, INP-03 |
| Individual Payment Recording | 70% | ERR-01, INP-01, INP-06 |
| Consolidated Payment | 65% | ERR-02, INP-02, FRQ-03 |
| Payment Reconciliation | 85% | — |
| Invoice PDF & ZIP Download | 80% | INP-04 (sync ZIP blocks) |
| Invoice Email (Immediate + Scheduled) | 75% | FRQ-02, LOG-02 |
| Billing Audit Log | 70% | DB-01, MDL-01, MDL-02 |
| Policy / Authorization | **30%** | POL-01/02, SEC-03–09 |
| Service Layer | **0%** | SVC-01, SVC-02 |
| Usage Metering & Overage | 0% | — |
| Payment Gateway (Razorpay) | 0% | SEC-004 |
| Tenant Billing Portal | 0% | — |
| Compliance / GST Reports | 0% | — |
| Automated Invoice Scheduler | 0% | — |

---

## 9. Secondary Code Quality Issues

| Issue | Detail |
|-------|--------|
| Class name typo | `BillTenatEmailSchedule` → should be `BillTenantEmailSchedule` (MDL-04) |
| Filter typo | `tenat_id` in `BillingManagementController::index()` → should be `tenant_id` (INP-03) |
| N+1 / Full-table scan | `Tenant::get()` and `User::get()` on every billing index load — no filter, no pagination |
| Activity log event names | `activityLog($model, 'Store', ...)` → should be `'Created'`/`'Updated'`/`'Deleted'` |
| `Auth::id()` in queue job | `SendInvoiceEmailJob::handle()` calls `Auth::id()` → returns `null` in queue worker context (LOG-02) |
| Synchronous ZIP download | Bulk ZIP is synchronous — blocks HTTP request; should be queued for >10 invoices |
| Temp file leak | ZIP download calls `@unlink($zipPath)` but individual temp PDF files are NOT deleted |
| Dead controller | `InvoicingController` exists (~empty stub) but is NOT registered in routes |
| Route duplication | Billing route block duplicated 3× in central `routes/web.php` for 3 domains |
| Raw route param | `BillingManagement@view($id)` uses raw `$id`, not route model binding |

---

## 10. FormRequest Gaps (4 Missing)

| Gap | Issue |
|-----|-------|
| FRQ-01 | `BillingManagementController::store()` uses raw `Request` — no FormRequest for invoice generation |
| FRQ-02 | `sendEmail()`, `scheduleEmail()`, `downloadPDF()` accept raw `Request` |
| FRQ-03 | `ConsolidatedPaymentRequest` missing validation rules for `invoice_ids[]`, `new_payment[]`, `payment_status[]` arrays |
| FRQ-04 | `StoreInvoicePaymentRequest` exists but controller accesses `$request->date` directly instead of `$request->validated()['date']` |

**4 new FormRequests to create:** `GenerateInvoiceRequest`, `SendEmailRequest`, `ScheduleEmailRequest`, `DownloadPDFRequest`

---

## 11. DDL Migration Plan (9 Migrations Needed)

All migrations run against `prime_db`, not tenant DB.

| Priority | Migration | Action |
|----------|-----------|--------|
| **P0** | M-05 | Fix FK column: `tenant_invoicing_id` → `tenant_invoice_id` in `bil_tenant_invoicing_audit_logs` |
| P1 | M-01 | ADD `created_by`, `deleted_at` to `bil_tenant_invoices` |
| P1 | M-03 | ADD `created_by`, `deleted_at`, `is_active` to `bil_tenant_invoicing_payments` |
| P1 | M-04 | ADD `updated_at`, `is_active`, `created_by`, `deleted_at` to `bil_tenant_invoicing_audit_logs` |
| P2 | M-06 | ADD INDEX on `action_date` (`bil_tenant_invoicing_audit_logs`) |
| P2 | M-07 | ADD INDEX on `tenant_invoice_id` (`bil_tenant_invoicing_payments`) |
| P2 | M-08 | ADD `is_active`, `created_by`, `deleted_at` to `bil_tenant_invoicing_modules_jnt` |
| P2 | M-09 | ADD standard columns + FK to `bil_tenant_email_schedules` |
| P2 | M-10 | Fix FK: add `invoice_id` FK to `bil_tenant_email_schedules` |

---

## 12. Key Lessons Learned

1. **"100% complete" in progress.md was wrong for Billing.** The prior seeding session (2026-06-25) found 7 P0 issues and ~55% completion, but the progress tracker was never updated. After any knowledge file seeding, progress.md MUST be updated immediately — stale "100% complete" entries give false confidence to the entire team.

2. **Prime modules are easy to overlook.** Most modules in this project are tenant-scoped. BIL breaks the pattern — it operates on `prime_db`, has no standalone DDL file, and its tables appear embedded in `prime_db_v2.sql` among hundreds of other tables. Any agent searching `2-DDL_Tenant_Consolidated/` for Billing DDL will find nothing.

3. **Silent auth bypass is the most dangerous type of bug.** Duplicate policy registrations (POL-01/02) produce no error, no 403, no log entry — they just silently let all requests through. This is harder to catch than an exception and was only found by reading `AppServiceProvider.php` directly.

4. **The Tenancy::initialize/end boundary is a safety-critical coding convention, not a framework guarantee.** Missing `Tenancy::end()` after the student count query silently routes all subsequent prime_db writes to the tenant database. There is no guard, no assertion, no test. This must be encapsulated in a service method that cannot be called without the paired `end()`.

5. **Two requirement file formats existing for one module is not always obvious.** BIL has both `BIL_Billing_Requirement.md` (consolidated V2) and a `Billing_v1/` screen-spec folder. The consolidated V2 file was the seeding source; the screen-spec folder was only discovered during the update pass. FRD generation should use both.

6. **File undercount patterns repeat.** Seeding recorded "6 controllers, 7 policies, 27+ views" — update pass found 7 controllers, 8 policies, 43 views. The pattern from ACC and ADM repeats: initial seedings from requirement docs undercount actual files. `ls` commands against the filesystem are mandatory.

7. **`Auth::id()` in queued jobs returns null.** `SendInvoiceEmailJob` calls `Auth::id()` in its `handle()` method. Queue workers run outside the HTTP request cycle — no authenticated user exists. Any audit or activity log written from a job must use a stored user ID passed as a job property, not `Auth::id()` at execution time.

---

## 13. Recommended Next Steps

| Priority | Action | Agent |
|----------|--------|-------|
| 1 | Fix P0-1: Delete 4 dead policy classes, redesign policy ability strings, verify auth chain | Developer |
| 2 | Fix P0-2: Align model `$fillable` column name `tenant_invoice_id`; update all controller insert call sites | Developer |
| 3 | Fix P0-3: Wrap `store()` and `consolidatedStore()` in try/catch/rollBack; fix `generateInvoiceForOrganization()` false return | Developer |
| 4 | Fix P0-4: Add `Gate::authorize()` to all 9 unprotected controller methods | Developer |
| 5 | Fix P0-5: Replace `$request->all()` with whitelist in audit log insert | Developer |
| 6 | Create `BillingService` — extract invoice generation, payment recording, `countTenantStudents()` | Backend Developer |
| 7 | Run DDL migration M-05 (P0 FK column rename) | DB Architect |
| 8 | Technical Audit — verify P0 resolution status; audit `Tenancy::initialize/end` usage; confirm `InvoicingController` dead stub removal | Technical Auditor |
| 9 | Generate FRD — Prime module scope; SaaS billing lifecycle; use both requirement formats | Business Analyst → "create an FRD for Billing" |
| 10 | Create 4 missing FormRequests: `GenerateInvoiceRequest`, `SendEmailRequest`, `ScheduleEmailRequest`, `DownloadPDFRequest` | Developer |
