# Module Knowledge: Billing (BIL)
# Last Updated: 2026-06-27 (update pass — file counts re-verified against Herd/prime_ai)
# Completion Status: ~55% | 40 total gap issues (7 × P0 critical) — P0 resolution status unverified; needs Technical Audit

---

## IMPORTANT: Prime Module — Not Tenant

**Database:** `prime_db` (central SaaS database — NOT tenant_db)
**Scope:** Super Admin manages billing for ALL school tenants from a single central panel
**Table prefix:** `bil_*` (+ 1 shared table `prm_billing_cycles`)
**No standalone DDL file** — `bil_*` tables are defined inside `prime_db_v2.sql`, NOT in `2-DDL_Tenant_Consolidated/`

---

## Module Facts

| Item | Value |
|------|-------|
| Module Code | BIL |
| Module Type | **Prime** (prime_db — central database) |
| Table prefix | `bil_*` |
| DDL location | `prime_db_v2.sql` (no standalone DDL file) |
| Laravel Module Path | `Modules/Billing/` |
| Controllers | **7** (re-verified 2026-06-27): BillingCycleController, BillingManagementController *(GOD — ~800+ lines)*, EmailScheduleController, InvoicingAuditLogController, InvoicingController *(empty stub)*, InvoicingPaymentController, SubscriptionController |
| Models | 6 (re-verified 2026-06-27) |
| FormRequests | 3 (re-verified 2026-06-27 — all partial; see FRQ gaps) |
| Jobs | 1 (`SendInvoiceEmailJob` — ShouldQueue) |
| Mail Classes | 1 (`InvoiceMail`) |
| Policies | **8** (re-verified 2026-06-27 — **ALL BROKEN due to duplicate registrations**): BillingCyclePolicy *(new)*, BillingManagementPolicy, ConsolidatedPaymentPolicy, InvoicingAuditLogPolicy, InvoicingPaymentPolicy, InvoicingPolicy, PaymentReconciliationPolicy, SubscriptionPolicy |
| Unit Tests | 1 file (`tests/Unit/BillingModuleTest.php`, ~55 test cases, Pest syntax) |
| Feature Tests | 0 |
| Module Route Lines | **11** lines in `Modules/Billing/routes/web.php` (post-2026-04-02 route migration; central `routes/web.php` previously had 49 billing routes duplicated 3× — check if those are still present) |
| API Routes | 0 (api.php is empty) |
| Views | **43** blade files (re-verified 2026-06-27; prior "27+" was an undercount) |
| Migrations | 0 (module bootstrapped via prime_db DDL directly) |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/BIL_Billing_Requirement.md` |
| Screen-spec folder | `4-Requirement_Module_wise/2-Module_Requirement_V1/Billing_v1/` |

---

## Feature Area Completion

| Feature Area | Completion | P0 Gaps |
|-------------|:---:|---------|
| Billing Cycle Master CRUD | 95% | — |
| Invoice Generation Engine | 80% | SEC-02, ERR-04, FRQ-01 |
| Billing Management Dashboard | 75% | SEC-01, SEC-03, INP-03 |
| Individual Payment Recording | 70% | ERR-01, INP-01, INP-06 |
| Consolidated Payment | 65% | ERR-02, INP-02, FRQ-03 |
| Payment Reconciliation | 85% | — |
| Invoice PDF & ZIP Download | 80% | INP-04 (sync ZIP) |
| Invoice Email (Immediate + Scheduled) | 75% | FRQ-02, LOG-02 |
| Billing Audit Log | 70% | DB-01, MDL-01, MDL-02 |
| **Policy / Authorization** | **30%** | POL-01, POL-02, SEC-03–09 |
| **Service Layer** | **0%** | SVC-01, SVC-02 |
| Usage Metering & Overage | 0% | — |
| Payment Gateway (Razorpay) | 0% | SEC-004 |
| Tenant Billing Portal | 0% | — |
| Compliance / GST Reports | 0% | — |
| Automated Invoice Scheduler | 0% | — |

---

## P0 Critical Issues (7 total)

### 1. Duplicate Policy Registrations — ALL Auth is Dead (POL-01, POL-02)
- **Where:** `AppServiceProvider.php` lines 617-623
- **What:** `BilTenantInvoice` is registered with TWO policies — `BillingManagementPolicy` is overwritten by `InvoicingPolicy`. `InvoicingPayment` is registered with FOUR policies — only the last (`InvoicingPaymentPolicy`) survives.
- **Impact:** `Gate::authorize('prime.billing-management.*')` calls in `BillingManagementController` resolve to NOTHING — no gate named that exists in the surviving `InvoicingPolicy`. Authorization is silently bypassed.
- **Fix:** One model = one policy. Delete dead policy classes: `BillingManagementPolicy`, `ConsolidatedPaymentPolicy`, `PaymentReconciliationPolicy`, `SubscriptionPolicy`. Redesign surviving policy to handle all ability strings OR switch to `Gate::define()` pattern.
- **Also:** `ConsolidatedPaymentPolicy` references non-existent `App\Models\ConsolidatedPayment` (POL-03); `PaymentReconciliationPolicy` references non-existent `App\Models\PaymentReconciliation` (POL-04)

### 2. FK Column Name Mismatch — Audit Log Inserts Will Fail (DB-01, MDL-01)
- **Where:** `bil_tenant_invoicing_audit_logs` DDL vs `InvoicingAuditLog` model
- **What:** DDL defines column `tenant_invoice_id`. Model `$fillable` and all controller insert calls use `tenant_invoicing_id`. On a fresh database, ALL audit log inserts fail silently (null constraint or column not found).
- **Fix:** Align model `$fillable` to `tenant_invoice_id` (matching DDL) — or run migration to rename DDL column. Update all controller call sites.
- **Also fix:** Add `'event_info' => 'array'` cast (MDL-02) and `'action_date' => 'datetime'` cast (MDL-03) on InvoicingAuditLog

### 3. DB Transactions Without try/catch (ERR-01, ERR-02)
- **Where:** `InvoicingPaymentController::store()` line 52 and `consolidatedStore()` line 158
- **What:** Both methods call `DB::beginTransaction()` with NO surrounding try/catch. Any exception leaves an open transaction that never rolls back → data inconsistency.
- **Fix:** Wrap in `try { ... DB::commit(); } catch (\Throwable $e) { DB::rollBack(); ... }` pattern.
- **Also:** `generateInvoiceForOrganization()` (ERR-04) returns bare `false` on failure; the caller at line 611 accesses `$result['status']` → array access on bool = fatal error. Fix to return `['status' => false, 'message' => ...]`.

### 4. Duplicate $fillable in BilTenantInvoice Model (DB-07)
- **Where:** `BilTenantInvoice.php` lines 20-69
- **What:** 8 fields duplicated: `paid_amount`, `currency`, `status`, `credit_days`, `payment_due_date`, `is_recurring`, `auto_renew`, `remarks` each appear TWICE — result of concatenation without dedup.
- **Fix:** Remove duplicate entries from `$fillable`.

### 5. Nine Controller Methods With NO Gate::authorize (SEC-01 to SEC-09)
- `BillingManagementController::index()` — `Gate::any()` used incorrectly with `||` operator (SEC-01)
- `BillingManagementController::store()` — has Gate::authorize but uses raw Request (SEC-02)
- `BillingManagementController::subscriptionDetails()`, `invoiceDetails()`, `moduleDetails()`, `view()` — NO auth, exposes ANY tenant's data (SEC-03)
- `BillingManagementController::printData()` — partial Gate check only (SEC-04)
- `InvoicingPaymentController::paymentDetails()` — NO auth (SEC-05)
- `InvoicingAuditLogController::auditAddNote()` — NO auth (SEC-06)
- `InvoicingAuditLogController::auditAddNoteUpdate()` — NO auth; anyone can update billing notes (SEC-07)
- `InvoicingAuditLogController::auditEventInfo()` — NO auth (SEC-08)
- `InvoicingAuditLogController::downloadAuditNotePdf()` — NO auth (SEC-09)

### 6. Sensitive Data Leak — `$request->all()` in Audit Log (INP-06)
- **Where:** `InvoicingPaymentController::store()` line 94
- **What:** Full `$request->all()` is stored in `event_info` JSON column — can include `gateway_response`, credentials, or raw card references in plaintext DB column.
- **Fix:** Whitelist only: `['amount_paid', 'payment_mode', 'payment_status', 'transaction_id', 'currency', 'payment_date']`

### 7. Razorpay Webhook Behind Auth Middleware (SEC-004)
- **Status:** Gateway not yet implemented, but when it is:
- **What:** Webhook route MUST NOT be behind `auth` middleware — webhooks are server-to-server with no user session.
- **Fix:** Register in `routes/api.php` (not web.php); verify using Razorpay HMAC signature (`X-Razorpay-Signature` header + `razorpay.webhook_secret`); on failure return HTTP 400 (not 401/403).

---

## DDL Tables (5 tables — all in prime_db_v2.sql)

| Table | Purpose | Status |
|-------|---------|--------|
| `prm_billing_cycles` | Billing cycle types (MONTHLY, QUARTERLY, YEARLY, ONE_TIME) | Clean |
| `bil_tenant_invoices` | Core invoice document — plan rate × qty, 4 tax lines, net payable | Missing `created_by`, `deleted_at` |
| `bil_tenant_invoicing_modules_jnt` | Modules included in each invoice | Missing `is_active`, `created_by`, `deleted_at` |
| `bil_tenant_invoicing_payments` | Payment records (individual + consolidated) | Missing `created_by`, `deleted_at`, `is_active`; missing index on `tenant_invoice_id` |
| `bil_tenant_invoicing_audit_logs` | Invoice lifecycle event log with JSON event_info | **FK column mismatch** (P0); missing `updated_at`, `is_active`, `created_by`, `deleted_at`; missing index on `action_date` |
| `bil_tenant_email_schedules` | Delayed email scheduling for invoices | No FK on `invoice_id`; missing `is_active`, `created_by`, `deleted_at`; model lacks SoftDeletes; class name typo (`BillTenatEmailSchedule`) |

### DDL Migration Plan

| Migration | Table | Action | Priority |
|-----------|-------|--------|----------|
| M-05 | `bil_tenant_invoicing_audit_logs` | Fix FK column: `tenant_invoicing_id` → `tenant_invoice_id` | **P0** |
| M-01 | `bil_tenant_invoices` | ADD `created_by`, `deleted_at` | P1 |
| M-03 | `bil_tenant_invoicing_payments` | ADD `created_by`, `deleted_at`, `is_active` | P1 |
| M-04 | `bil_tenant_invoicing_audit_logs` | ADD `updated_at`, `is_active`, `created_by`, `deleted_at` | P1 |
| M-06 | `bil_tenant_invoicing_audit_logs` | ADD INDEX on `action_date` | P2 |
| M-07 | `bil_tenant_invoicing_payments` | ADD INDEX on `tenant_invoice_id` | P2 |
| M-08 | `bil_tenant_invoicing_modules_jnt` | ADD `is_active`, `created_by`, `deleted_at` | P2 |
| M-09/10 | `bil_tenant_email_schedules` | ADD standard columns + FK to `bil_tenant_invoices` | P2 |

---

## FormRequest Gaps (FRQ-01 to FRQ-04)

| Gap | Issue |
|-----|-------|
| FRQ-01 | `BillingManagementController::store()` uses raw `Request` — no FormRequest for invoice generation |
| FRQ-02 | `sendEmail()`, `scheduleEmail()`, `downloadPDF()` accept raw `Request` |
| FRQ-03 | `ConsolidatedPaymentRequest` missing rules for `invoice_ids[]`, `new_payment[]`, `payment_status[]` arrays |
| FRQ-04 | `StoreInvoicePaymentRequest` exists but controller accesses `$request->date` instead of `$request->validated()['date']` |

**4 new FormRequests to create:** `GenerateInvoiceRequest`, `SendEmailRequest`, `ScheduleEmailRequest`, `DownloadPDFRequest`

---

## Service Layer (Currently Zero — SVC-01, SVC-02)

`BillingManagementController::generateInvoiceForOrganization()` is ~170 lines of business logic in the controller.

**Create `Modules\Billing\Services\BillingService` with:**
- `generateInvoice(int $scheduleId): array`
- `recordPayment(array $data): InvoicingPayment`
- `countTenantStudents(Tenant $tenant): int` — encapsulates `Tenancy::initialize()/end()` to avoid context leak

---

## Key Business Rules

| Rule | Summary |
|------|---------|
| BR-001 | `invoice_no` = `INV-YYYYMMDD-NNN` (globally unique, NNN = today's count + 1 padded) |
| BR-002 | `billing_qty = max(min_billing_qty, total_user_qty)` |
| BR-003 | `total_user_qty` is counted from the TENANT's isolated database via `Tenancy::initialize()` |
| BR-004 | `net_payable = sub_total − discount + extra_charges + total_tax` |
| BR-006 | `payment_due_date = invoice_date + credit_days` |
| BR-007 | A billing schedule entry can only be invoiced once (`bill_generated` flag) |
| BR-009 | `paid_amount` is cumulative — never decremented |
| BR-011 | **Critical:** `Tenancy::end()` MUST be called after student count query — failure leaks tenant context |
| BR-012 | Audit log entries are append-only (only `notes` field is updatable) |
| BR-019 | `$request->all()` must NEVER be stored in audit `event_info` — whitelist only |
| BR-020 | DB transactions must wrap ALL multi-model writes in try/catch |

---

## Cross-Module Dependencies

| Dependency | Direction | Integration Point |
|------------|-----------|-------------------|
| `prm_tenant` | BIL consumes | Tenant master — every invoice links to a tenant |
| `prm_tenant_plan_jnt` | BIL consumes | Subscription plan (rate, credit_days, billing cycle) |
| `prm_tenant_plan_billing_schedule` | BIL consumes | Source records for invoice generation; sets `bill_generated=1` |
| `prm_tenant_plan_rate` | BIL consumes | Rate per period used in billing_qty × plan_rate calculation |
| `glb_modules` | BIL consumes | Module list stored in `bil_tenant_invoicing_modules_jnt` per invoice |
| `sys_users` | BIL consumes | `performed_by` FK in audit log; `Auth::id()` used in activity logs |
| `sys_activity_logs` | BIL produces | Activity entries for all CRUD operations |
| `sys_dropdown_table` | BIL consumes | Dropdown values for `invoice_status`, `payment_mode`, `payment_status` |
| `Prime module (PRM)` | BIL reads | Subscription and plan assignment data — BIL doesn't own these |
| **Tenant DB** (cross-query) | BIL reads | `Tenancy::initialize()` to count `std_students` for `total_user_qty` |
| Razorpay | BIL future | Gateway integration — composer package installed, implementation not started |

**Key cross-DB pattern:** BIL is the only Prime module that temporarily initializes a tenant's database connection to count active students. `Tenancy::end()` is critical after this query.

---

## Route Issues

| Issue | Severity | Details |
|-------|----------|---------|
| RT-01 | P1 | No role-based middleware on billing route group — auth relies entirely on Gate checks inside methods (most of which are broken — see P0 issues) |
| RT-02 | P2 | `InvoicingController` exists but not registered in routes — dead stub |
| RT-03 | P2 | `BillingManagement@view($id)` takes raw `$id` param, not route model binding |
| RT-04 | P2 | Route block duplicated 3× in app `routes/web.php` for 3 central domains — DRY violation |

---

## Other Code Quality Issues

| Issue | Detail |
|-------|--------|
| Model typo | Class `BillTenatEmailSchedule` → should be `BillTenantEmailSchedule` (MDL-04) |
| Filter typo | `tenat_id` filter in `BillingManagementController::index()` → should be `tenant_id` (INP-03) |
| N+1 performance | `Tenant::get()` and `User::get()` load ALL records on every billing index page load (no filter, no pagination) |
| Activity log event names | Multiple `activityLog($model, 'Store', ...)` calls — should be 'Created'/'Updated'/'Deleted' (LOG-01) |
| Auth::id() in queue | `SendInvoiceEmailJob::handle()` calls `Auth::id()` which returns null in queue worker context (LOG-02) |
| ZIP sync issue | Bulk ZIP download is synchronous — blocks request; should move to queued job for > 10 invoices |
| Temp file cleanup | ZIP download does `@unlink($zipPath)` but does NOT delete individual temp PDF files |
| PDF injection | PDF views should sanitize displayed data |

---

## Design Decisions Made

*(none yet — FRD not yet generated)*

---

## Lessons Learned

- [2026-06-25 | Seed] Billing is a **Prime module** — easy to miss because most modules in this project are Tenant. No standalone DDL file exists; tables are in `prime_db_v2.sql`. When any agent needs to read the DDL, look in prime_db_v2.sql, not the Consolidated DDL folder.
- [2026-06-25 | Seed] The `Tenancy::initialize()` / `Tenancy::end()` cross-DB pattern is unique to this module. Any work on invoice generation must preserve this boundary — a missing `Tenancy::end()` leaks tenant DB context into subsequent prime_db queries.
- [2026-06-25 | Seed] The duplicate policy registration bug means authorization is completely silently broken in BillingManagementController — not a runtime error, it just fails open. Fix this before any other auth work.

---

## Pending Next Steps

| # | Work | Agent | Notes |
|---|------|-------|-------|
| 1 | Fix P0 duplicate policy registrations | `act as Developer` | One policy per model; redesign ability strings; delete 4 dead policy classes |
| 2 | Fix P0 audit log FK column mismatch | `act as Developer` | Rename `tenant_invoicing_id` → `tenant_invoice_id` in model $fillable + all controller calls |
| 3 | Fix P0 DB transaction try/catch | `act as Developer` | Wrap `store()` and `consolidatedStore()` in try/catch/rollBack pattern |
| 4 | DDL migrations M-01 through M-10 | `act as DB Architect` | Add missing standard columns + index + FK |
| 5 | Create BillingService | `act as Backend Developer` | Extract invoice generation + payment logic + countTenantStudents() |
| 6 | Create 4 missing FormRequests | `act as Backend Developer` | GenerateInvoiceRequest, SendEmailRequest, ScheduleEmailRequest, DownloadPDFRequest |
| 7 | Generate FRD | `act as Business Analyst` | "create an FRD for Billing" — Prime module scope, SaaS billing lifecycle |

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-25 | Business Analyst | Knowledge file seeded from `BIL_Billing_Requirement.md` (V2, 2026-03-26). No DDL file exists — tables are in prime_db_v2.sql. No session work yet. Controller count recorded as 6 (undercounted — BillingCycleController missed). Views recorded as "27+" (undercount). |
| 2026-06-27 | Business Analyst | Update pass: re-verified all file counts. Corrections: controllers 6→7 (BillingCycleController confirmed), policies 7→8 (BillingCyclePolicy found), views 27+→43, routes clarified (11 lines in module web.php post-migration). Both requirement formats confirmed: consolidated V2 (`BIL_Billing_Requirement.md`) + screen-spec folder (`Billing_v1/`). P0 issues from seeding audit remain open — resolution status unverified. Needs Technical Audit to confirm whether POL-01, DB-01, ERR-01/02, SEC-01–09 have been addressed. |
