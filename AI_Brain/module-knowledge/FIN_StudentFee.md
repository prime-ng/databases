# Module Knowledge — FIN: StudentFee
**Seeded:** 2026-06-30 | **Agent:** Business Analyst
**Version:** 1.1

---

## FRD Summary (v1.0 — 2026-06-30)

| Attribute | Value |
|---|---|
| FRD File | `FIN_FRD_2026-06-30.md` in `4-Requirement_Module_wise/0-FRD_Documents/` |
| Complete Analysis Pack | `FIN_FRD_Complete_2026-06-30.md` (same folder) |
| Requirement Conditions Catalog | `FIN_Conditions.md` in `4-Requirement_Module_wise/5-Requirement_Conditions/` |
| REQ Count | 20 (P0: 12 · P1: 7 · P2: 1) |
| BR Count | 87 (BR-FIN-001 through BR-FIN-087) |
| Workflow Count | 5 (WF-1 Invoice Lifecycle; WF-2 Concession; WF-3 Scholarship; WF-4 Fine+Name Removal; WF-5 Cheque Clearance) |
| Report Count | 8 (RPT-FIN-001 through RPT-FIN-008) |
| Enhancement Count | 5 (ENH-FIN-001 through ENH-FIN-005) |
| FRD Date | 2026-06-30 |
| Producer | Business Analyst agent |
| Overall Implementation Assessment | ~78% — 12 of 20 requirements substantially implemented; 4 P0 security gaps; 2 complete controller gaps |

---

## Module Facts

| Attribute | Value |
|-----------|-------|
| Module Name | StudentFee |
| Module Code | FIN |
| Table Prefix | `fee_*` (not `fin_*` — module code is FIN for documentation; DB prefix is `fee_`) |
| Laravel Module Path | `Modules/StudentFee/` |
| Namespace | `Modules\StudentFee` |
| DB Layer | **Tenant** — tenant_db (no `tenant_id` column; isolated by DB connection) |
| Domain Scope | Tenant — School Admin, Accountant/Cashier, Principal, Class Teacher, Student/Parent |
| V2 Requirement | Exists: `FIN_StudentFee_Requirement.md` (2026-03-26); stated ~80–90% completion |
| V1 Screen Specs | 15 files in `StudentFee_v1/` (fee-heads, fee-groups, fee-structures, fee-installments, fee-assignments, fee-invoicing, fee-payments, fee-concessions, fee-fines, fee-scholarships, fee-reconciliation, fee-refunds, fee-name-removal, fee-dashboard, implementation-plan) |
| RBS Reference | Module J — Finance & Billing |
| Route Prefix | `student-fee` (web); `api` (API) |
| Route Name Prefix | `student-fee.` |
| Payment Gateway | Razorpay (primary, via PAY module); also Paytm, CCAvenue, BillDesk configured |
| PDF Generation | DomPDF (invoice and receipt PDF) |
| Scheduler Command | `fee:apply-fines` (registered but scheduler NOT wired — P1 gap) |
| CLAUDE.md Completion | 80–95% (listed) |

### Verified File Counts (from `find Modules/StudentFee -type f` — 2026-06-30)

| Component | Actual | V2 Claimed | Notes |
|-----------|--------|-----------|-------|
| Controllers | 15 | 15 | See controller inventory in Appendix |
| Models | 24 | 23 | `FeeConcessionApplicableHead` EXISTS — V2 wrongly listed it as missing |
| FormRequests | 36 | 0 | V2 claimed 0 FormRequests; they were built after V2 was written |
| Policies (files) | 15 | 15 | `FeeMasterPolicy` file exists but is NOT registered |
| Policies (registered) | 13 | 15 | See policy registration bug note |
| Services | 3 | 0 | `FeeFineService`, `FeeInvoiceService`, `FeeScholarshipService` — V2 wrongly said 0 |
| Commands | 1 | 1 | `ApplyFines` registered; scheduler **commented out** (P1) |
| Tests (Feature) | 1 | 1 | `ArchitectureTest` |
| Tests (Unit) | 25 | 24 | `FeeModelTableNamesTest` is an extra file |
| Seeders | 22 | — | Full seeder suite for all 24 tables |
| Views | ~100 | — | Full CRUD views for all entities; hub pages; PDF/email templates |
| Migrations (fee_*) | 24 | 24 | All in tenant migrations dated 2026-06-16 |

---

## Module Score Summary (V2 Gap Analysis 2026-03-22, updated with filesystem verification 2026-06-30)

| Area | Score | Key Issue |
|------|-------|-----------|
| DB Integrity | 7/10 | `balance_amount` is NOT a GENERATED column (see DDL issue); `join_in_mid-year` hyphen column name |
| Route Integrity | 6/10 | `EnsureTenantHasModule` missing; seeder route exposed; `fee-transaction.store` points to wrong controller |
| Controller Quality | 7/10 | Seeder route + Faker import in `StudentFeeController`; most controllers well-structured |
| Model Quality | 8/10 | `balance_amount` not in `$fillable` (correct) but not updated on payment — stale DB value |
| Service Layer | 7/10 | 3 services exist; `FeeConcessionService` still missing |
| FormRequest Coverage | 9/10 | 36 FormRequests cover all CRUD; minor gaps (e.g., bulk-generate) |
| Policy / Auth | 6/10 | Policy override bug (FeeHeadMaster/StudentFeeManagement); 4 policy files missing for new entities |
| Test Coverage | 5/10 | 25 unit (model-level only); zero feature tests for financial flows |
| Security | 5/10 | Seeder route exposed; `EnsureTenantHasModule` missing; no gateway webhook signature check |
| Performance | 7/10 | `ApplyFines` uses `DB::transaction()` correctly; bulk invoice generation synchronous for >100 students |
| **Overall** | **6.7/10** | Higher than VND; core flows work; security + scheduler + balance_amount integrity gaps remain |

---

## DDL Table Inventory (24 tables, all `fee_*` prefix)

### Active Tables

| # | Table | Model | SoftDeletes | GENERATED Col | Key DDL Issues |
|---|-------|-------|:-----------:|:-------------:|----------------|
| 1 | `fee_head_master` | `FeeHeadMaster` | YES | None | UQ on `code`; `frequency` ENUM; `account_head_code` for FAC mapping |
| 2 | `fee_group_master` | `FeeGroupMaster` | YES | None | UQ on `code` |
| 3 | `fee_group_heads_jnt` | `FeeGroupHeadsJnt` | NO | None | UQ (`group_id`, `head_id`) — SoftDeletes NOT applied; model may lack `deleted_at` |
| 4 | `fee_structure_master` | `FeeStructureMaster` | YES | None | idx on session+class; no DDL-level unique for session+class+category (enforced at app level only) |
| 5 | `fee_structure_details` | `FeeStructureDetail` | NO | None | UQ (`structure_id`, `head_id`); SoftDeletes NOT applied |
| 6 | `fee_installments` | `FeeInstallment` | YES | None | UQ (`fee_structure_id`, `installment_no`); `grace_days` default |
| 7 | `fee_fine_rules` | `FeeFineRule` | YES | None | `applicable_on`, `fine_type`, `fine_calculation_mode`, `action_on_expiry` ENUMs |
| 8 | `fee_concession_types` | `FeeConcessionType` | YES | None | `discount_type`, `applicable_on` ENUMs; `requires_approval` flag |
| 9 | `fee_concession_applicable_heads` | `FeeConcessionApplicableHead` | NO | None | CHECK constraint `chk_cah_head_or_group` ensures exactly one of head_id or group_id is non-null; SoftDeletes NOT applied |
| 10 | `fee_student_assignments` | `FeeStudentAssignment` | YES | None | **DDL WARNING:** `join_in_mid-year` column has a hyphen in the name — requires backtick quoting in raw SQL; UQ (`student_id`, `academic_session_id`) |
| 11 | `fee_student_concessions` | `FeeStudentConcession` | NO | None | `approval_status` ENUM; SoftDeletes NOT applied |
| 12 | `fee_invoices` | `FeeInvoice` | YES | **NONE** | **CRITICAL:** `balance_amount` is a plain `DECIMAL(12,2)` in the migration — NOT a GENERATED STORED column (V2 claims GENERATED; migration is a regular column); model has PHP helper `getBalanceAmount()` but DB column is NOT updated by `updatePayment()` — stale DB value risk |
| 13 | `fee_transactions` | `FeeTransaction` | YES | None | `payment_mode` ENUM; `payment_reference` stored as plaintext (cheque/UPI refs) |
| 14 | `fee_transaction_details` | `FeeTransactionDetail` | NO | None | UQ (`transaction_id`, `head_id`); SoftDeletes NOT applied |
| 15 | `fee_receipts` | `FeeReceipt` | NO | None | UQ `receipt_no`; `receipt_format` ENUM; SoftDeletes NOT applied |
| 16 | `fee_fine_transactions` | `FeeFineTransaction` | NO | None | `waived_amount = NULL` means full waiver; non-NULL = partial waiver; SoftDeletes NOT applied |
| 17 | `fee_payment_gateway_logs` | `FeePaymentGatewayLog` | NO | None | `request_payload` and `response_payload` cast as array (JSON); `gateway_transaction_id`, `order_id`, `payment_id` stored as plaintext strings — no encrypted cast; `gateway_name` ENUM: Razorpay/Paytm/CCAvenue/BillDesk/Other |
| 18 | `fee_scholarships` | `FeeScholarship` | YES | None | `eligibility_criteria` and `renewal_criteria` JSON; `available_fund` decremented on disbursement |
| 19 | `fee_scholarship_applications` | `FeeScholarshipApplication` | NO | None | UQ (`scholarship_id`, `student_id`, `academic_session_id`); `application_data` and `documents_submitted` JSON; `status` ENUM; SoftDeletes NOT applied |
| 20 | `fee_scholarship_approval_history` | `FeeScholarshipApprovalHistory` | NO | None | Audit trail; FK cascade on application_id; SoftDeletes NOT applied |
| 21 | `fee_name_removal_log` | `FeeNameRemovalLog` | NO | None | Tracks name removal and re-admission; SoftDeletes NOT applied |
| 22 | `fee_refunds` | `FeeRefund` | NO | None | UQ `refund_no`; `status` ENUM; SoftDeletes NOT applied |
| 23 | `fee_payment_reconciliation` | `FeePaymentReconciliation` | NO | None | UQ on `transaction_id`; cheque/DD lifecycle status ENUM; SoftDeletes NOT applied |
| 24 | `fee_defaulter_history` | `FeeDefaulterHistory` | NO | None | UQ (`student_id`, `academic_session_id`); `defaulter_score` DECIMAL(5,2) for AI/PAN module; SoftDeletes NOT applied |

### Critical DDL Notes

- **`fee_invoices.balance_amount`:** Plain `DECIMAL(12,2)` column in migration (NOT `GENERATED ALWAYS AS`). Model excludes it from `$fillable`. The `updatePayment()` method on `FeeInvoice` updates `paid_amount` and `status` but does NOT update `balance_amount`. The PHP helper `getBalanceAmount()` computes `total_amount - paid_amount` at runtime. However, the DB column `balance_amount` becomes stale after any payment is recorded. Any raw SQL query or report relying on `fee_invoices.balance_amount` will return incorrect values. Fix: either add `balance_amount` update inside `updatePayment()`, or convert to a true MySQL GENERATED STORED column via migration.
- **`fee_student_assignments.join_in_mid-year`:** Hyphen in column name is a DDL artifact. Confirmed in migration: `$table->boolean('join_in_mid-year')`. Use backtick quoting in raw SQL. In Eloquent: `$assignment->{'join_in_mid-year'}` or use `getAttributeValue('join_in_mid-year')`.
- **Tables without SoftDeletes:** 11 of 24 tables do not have `deleted_at` — `fee_group_heads_jnt`, `fee_structure_details`, `fee_concession_applicable_heads`, `fee_student_concessions`, `fee_transaction_details`, `fee_receipts`, `fee_fine_transactions`, `fee_payment_gateway_logs`, `fee_scholarship_applications`, `fee_scholarship_approval_history`, `fee_name_removal_log`, `fee_refunds`, `fee_payment_reconciliation`, `fee_defaulter_history`. These are mostly junction/audit/log tables where soft-delete may be intentional, but check models for SoftDeletes trait inconsistency.

### Amount Precision
All monetary columns use `DECIMAL(12,2)` — correct for Indian school fees up to ₹9,999,999,999.99. No integer overflow risk. Paise/cents are correctly handled via 2 decimal places.

---

## Known Gaps & Open Issues

### P0 — Critical (Security / Production Blockers)

| ID | Issue | Location |
|----|-------|---------|
| SEC-FIN-01 | **Seeder route exposed:** `Route::get('/seeder', [StudentFeeController::class, 'seederFunction'])` is registered in module `web.php` line 22. Although the route group has `auth`/`verified` middleware, any authenticated user can trigger it, creating test data (students, invoices, transactions) in production. Must be removed immediately. | `Modules/StudentFee/routes/web.php:22` |
| SEC-FIN-02 | **Faker import in production controller:** `StudentFeeController.php` line 7 has `use Faker\Factory as Faker` — Faker is a dev dependency; this import will cause a class-not-found error if Composer installs without dev dependencies (--no-dev) and the controller is loaded. | `Modules/StudentFee/app/Http/Controllers/StudentFeeController.php:7` |
| SEC-FIN-03 | **`EnsureTenantHasModule` middleware missing:** `RouteServiceProvider::mapWebRoutes()` applies `web`, `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`, `auth`, `verified` — but NOT `EnsureTenantHasModule`. Any authenticated user of a tenant that does NOT have StudentFee licensed can access all fee routes. | `Modules/StudentFee/app/Providers/RouteServiceProvider.php:41` |
| SEC-FIN-04 | **No Razorpay webhook handler:** `routes/api.php` exposes only a generic `apiResource('studentfees', StudentFeeController::class)`. There is no dedicated webhook endpoint that verifies Razorpay signature (`X-Razorpay-Signature` HMAC-SHA256 check). Online payment callbacks without signature verification allow replay attacks and fake payment confirmations. | `Modules/StudentFee/routes/api.php` |

### P1 — High

| ID | Issue | Location |
|----|-------|---------|
| BUG-FIN-05 | **`balance_amount` stale in DB:** `fee_invoices.balance_amount` is a regular DECIMAL column, NOT a GENERATED STORED column as V2 states. `FeeInvoice::updatePayment()` updates `paid_amount` and `status` but never updates `balance_amount`. DB column value is stale after every payment. Raw SQL reports and any query on `balance_amount` return incorrect outstanding amounts. PHP `getBalanceAmount()` is correct at runtime but DB value cannot be trusted. | `Modules/StudentFee/app/Models/FeeInvoice.php:144-158`, migration `2026_06_16_092641` |
| BUG-FIN-06 | **`ApplyFines` scheduler commented out:** The command `fee:apply-fines` is registered in `StudentFeeServiceProvider::registerCommands()` but `registerCommandSchedules()` has the schedule block entirely commented out. The nightly fine application will never execute automatically unless triggered manually. | `Modules/StudentFee/app/Providers/StudentFeeServiceProvider.php:107-111` |
| BUG-FIN-07 | **Policy override bug:** `StudentFeeServiceProvider::registerPolicies()` registers `Gate::policy(FeeHeadMaster::class, FeeHeadMasterPolicy::class)` on line 75, then OVERRIDES it with `Gate::policy(FeeHeadMaster::class, StudentFeeManagementPolicy::class)` on line 89. Laravel's last registration wins. `FeeHeadMasterPolicy` is silently disabled — all FeeHeadMaster authorization runs through `StudentFeeManagementPolicy` instead. | `Modules/StudentFee/app/Providers/StudentFeeServiceProvider.php:75,89` |
| BUG-FIN-08 | **Route bug — `fee-transaction.store` wrong controller:** Line 141 of `web.php` has `Route::post('/fee-transaction/store', [FeeInvoiceController::class, 'store'])`. Payment recording routes to the Invoice controller's generic `store` method, not a `FeeTransactionController` method. This means the named route `fee-transaction.store` actually creates an invoice rather than a payment transaction. | `Modules/StudentFee/routes/web.php:141` |
| GAP-FIN-09 | **`FeeRefundController` missing:** Model (`FeeRefund`) and seeder exist, but no controller, no routes, and no policy file for refund management. The full refund lifecycle (Pending → Approved → Processed/Rejected) is unimplemented. | — |
| GAP-FIN-10 | **`FeeChequeController` missing:** `FeePaymentReconciliation` model and migration exist, but no controller or routes for cheque/DD clearance lifecycle. Schools using cheque payment have no way to mark cheques as deposited, cleared, or bounced. | — |
| GAP-FIN-11 | **Policy files missing for 4 entities:** `FeeRefundPolicy`, `FeeReceiptPolicy`, `FeePaymentReconciliationPolicy`, `FeeDefaulterHistoryPolicy` — none of these policy files exist in the module's `app/Policies/`. These models have no authorization layer. | `Modules/StudentFee/app/Policies/` |
| GAP-FIN-12 | **`FeeMasterPolicy` not registered:** File `Modules/StudentFee/app/Policies/FeeMasterPolicy.php` exists but is NOT wired up in `StudentFeeServiceProvider::registerPolicies()`. | `Modules/StudentFee/app/Providers/StudentFeeServiceProvider.php` |
| GAP-FIN-13 | **D21 Event Contract not implemented:** No `StudentFeeCollected` or `StudentFeeRefunded` Laravel event classes exist in `Modules/StudentFee/Events/`. The `EventServiceProvider` is registered but no events/listeners are defined. FAC (Accounting) module cannot receive fee collection hooks. | `Modules/StudentFee/app/Providers/EventServiceProvider.php` |
| GAP-FIN-14 | **`FeeConcessionService` missing:** V2 planned 4 services; only 3 built: `FeeFineService`, `FeeInvoiceService`, `FeeScholarshipService`. Concession calculation logic remains in `FeeStudentConcessionController`. | `Modules/StudentFee/app/Services/` |
| GAP-FIN-15 | **Bulk invoice generation synchronous:** `FeeInvoiceController@generateFeeInvoice` runs synchronously. For schools with 300+ students, HTTP timeout risk on bulk generation. No queue job implemented. | `Modules/StudentFee/app/Http/Controllers/FeeInvoiceController.php` |
| GAP-FIN-16 | **`StudentFeeManagementController` missing Gate::authorize:** Hub methods (dashboard, configuration, assignment, billing, payment, fine-management, scholarship, governance) have no `Gate::authorize` call. Any authenticated user can access the fee management hub. | `Modules/StudentFee/app/Http/Controllers/StudentFeeManagementController.php` |
| GAP-FIN-17 | **`StudentFeeController::seederFunction` still present:** Must be removed along with the route. The method itself is ~100 lines of Faker-based test-data generation that should not exist in a production controller. | `Modules/StudentFee/app/Http/Controllers/StudentFeeController.php` |

### P2 — Medium

| ID | Issue | Location |
|----|-------|---------|
| BUG-FIN-18 | **`fee-student-concession.trashed` is a redirect:** Line 94 of `web.php` returns `fn() => redirect()->route('student-fee.configuration')` instead of a real trash view. Same pattern for `fee-fine-transaction.trashed` (line 107 redirects to fineManagement). Users expecting a restore flow get silently redirected. | `Modules/StudentFee/routes/web.php:94,107` |
| BUG-FIN-19 | **Backup view file in production resources:** `resources/views/fee-invoice/invoice_27_02_2026.blade.php` is a dated backup file that should be deleted. Causes confusion during maintenance and may render if accidentally referenced. | `Modules/StudentFee/resources/views/fee-invoice/` |
| GAP-FIN-20 | **`FeeDefaulterHistoryController` missing:** `FeeDefaulterHistory` model and seeder exist; no controller or routes for the defaulter analytics screen (SCR-FIN-29). Defaulter history records are created by `ApplyFines` but cannot be viewed via UI. | — |
| GAP-FIN-21 | **Concession approval notification absent:** When a concession with `requires_approval = true` is submitted, no notification is dispatched to the `approval_level_role_id` user. Approval requests go unnoticed. | `FeeStudentConcessionController::store()` |
| GAP-FIN-22 | **No caching for master data:** `fee_head_master`, `fee_structure_master`, `fee_concession_types` are frequently read but never cached. High-traffic schools will see repeated DB lookups for largely static configuration data. | — |
| GAP-FIN-23 | **No CSV export:** `FeeStudentManagementController` dashboard does not expose a CSV export for fee collection summary or defaulter list. V2 FR-FIN-14.9 planned this. | — |
| GAP-FIN-24 | **`FeePaymentGatewayLog` gateway tokens unencrypted:** `gateway_transaction_id`, `order_id`, `payment_id` stored as plaintext strings in `fee_payment_gateway_logs`. These are transactional references; while not PII of the same sensitivity as PAN, they should be treated as financial-sensitive data. Currently no encrypted cast applied. | `Modules/StudentFee/app/Models/FeePaymentGatewayLog.php` |
| GAP-FIN-25 | **SoftDeletes inconsistency:** 11 of 24 tables lack `deleted_at`. For most this is intentional (audit/log tables). However `fee_student_concessions` and `fee_fine_transactions` are transactional records that may benefit from soft-delete for auditing. Review each case. | DDL/Models |
| GAP-FIN-26 | **Fee rollover not implemented:** FR-FIN-14.10 (copy fee structures from one session to next with amount adjustment) is not built. Admins must recreate all fee structures at the start of each academic year. | — |

### P3 — Backlog

| ID | Issue |
|----|-------|
| GAP-FIN-27 | Zero feature tests for financial flows. No test for: invoice generation, payment recording, fine calculation, concession approval, scholarship disbursement. Only unit (model) tests exist. |
| GAP-FIN-28 | `fee:apply-fines` command does NOT dispatch `FeeFineApplied` notification event. Parents/guardians are not notified when a fine is applied to their child's invoice. |
| GAP-FIN-29 | `fee:apply-fines` action_on_expiry = 'Remove Name' creates `fee_name_removal_log` entry but does NOT notify principal/admin. |
| GAP-FIN-30 | Due date reminder (3 days before installment due_date): no scheduler for `FeeDueReminder` event — V2 FR-11.3 proposed this. |
| GAP-FIN-31 | Transport/Hostel fee auto-integration (FR-P3-05): when student assigned to transport route, auto-assign transport fee head. Not implemented. |
| GAP-FIN-32 | `api.php` Razorpay callback route (`/api/v1/student-fee/payment-callback`) planned but not implemented. Online payment cannot complete without this callback handling and idempotency check. |
| GAP-FIN-33 | `fee-reciept` directory: V2 mentioned a typo in the view directory. Actual filesystem has `fee-receipt/index.blade.php` (correctly spelled) — this gap was resolved. |

---

## Feature Area Status (as of 2026-06-30)

| # | Feature | FR | Status | Notes |
|---|---------|----|----|------|
| 1 | Fee Head Master | FR-FIN-01 | 🟢 95% | Full CRUD + toggle + trash; `account_head_code` for FAC mapping |
| 2 | Fee Group Master | FR-FIN-02 | 🟢 95% | Full CRUD + junction table; `FeeConcessionApplicableHead` model EXISTS (V2 wrong) |
| 3 | Fee Structure Master | FR-FIN-03 | 🟢 90% | Full CRUD; no DDL-level unique for session+class+category |
| 4 | Fee Installment Scheduling | FR-FIN-04 | 🟢 95% | Full CRUD + `grace_days` |
| 5 | Student Fee Assignment | FR-FIN-05 | 🟢 90% | Bulk generate + individual + mid-year; idempotency on duplicate run needs verify |
| 6 | Fee Concession Management | FR-FIN-06 | 🟡 75% | CRUD works; approval workflow exists; notification on submit MISSING; FeeConcessionService missing |
| 7 | Scholarship Management | FR-FIN-07 | 🟢 90% | Full lifecycle including disburse; `FeeScholarshipService` exists |
| 8 | Fee Invoice Generation | FR-FIN-08 | 🟡 80% | Generation works; bulk sync only (no queue); `balance_amount` stale in DB |
| 9 | Fee Transaction / Payment | FR-FIN-09 | 🟡 75% | Offline recording works; route bug `fee-transaction.store`; receipt generation partial; no DB::transaction wrapper verified |
| 10 | Fine Management | FR-FIN-10 | 🟡 70% | `FeeFineService` + `ApplyFines` command built; scheduler NOT registered; no notification on fine applied |
| 11 | Cheque/DD Clearance | FR-FIN-11 | ❌ 0% | Table + model exist; no controller, no routes |
| 12 | Fee Refund Management | FR-FIN-12 | ❌ 0% | Table + model exist; no controller, no routes, no policy file |
| 13 | Name Removal Log | FR-FIN-13 | 🟡 50% | ApplyFines creates records; no UI controller; re-admission workflow missing |
| 14 | Fee Reports & Dashboard | FR-FIN-14 | 🟡 70% | Dashboard + defaulter/scholar/concession lists work; no CSV export; no DefaulterHistoryController |
| 15 | Security: Seeder Route Removal | FR-FIN-15 | ❌ 0% | Still present in web.php + controller (P0 — must fix before next deploy) |
| 16 | EnsureTenantHasModule | — | ❌ 0% | Not in RouteServiceProvider middleware chain (P0) |
| 17 | D21 FAC Events | — | ❌ 0% | No event classes created; EventServiceProvider empty |
| 18 | Razorpay Online Payment | — | 🟡 40% | `Payable` contract on FeeInvoice; PAY module integration partial; no webhook handler |
| 19 | Feature Test Coverage | — | ❌ 0% | Zero feature tests for any financial flow |

---

## Payment Gateway Integration

### Current State
- `FeeInvoice` implements `Modules\Payment\Contracts\Payable` interface — provides `getPayableLabel()`, `getPayableAmount()`, `getPayableCustomer()`, `getPayableMetadata()` for PAY module.
- `FeePaymentGatewayLog` model supports: Razorpay, Paytm, CCAvenue, BillDesk, Other.
- Primary intended gateway: **Razorpay** via PAY module.

### Critical Gaps (all P0/P1)

| Gap | Severity | Detail |
|-----|----------|--------|
| No webhook endpoint | P0 | `routes/api.php` has no Razorpay callback handler. Online payments cannot complete. |
| No signature verification | P0 | Even if webhook route existed, no HMAC-SHA256 `X-Razorpay-Signature` verification code exists. Any POST to a webhook URL would be accepted — allows fake payment injection. |
| No idempotency guard | P1 | No check for duplicate `payment_id` before processing a webhook. Replayed webhooks would double-count payments. |
| No Razorpay refund API call | P1 | `FeeRefund` model exists but no controller. Even when built, `BR-FIN-08.5` requires a Razorpay Refund API call for online payment refunds — this is not planned in current code. |
| Webhook must bypass CSRF | — | Any Razorpay webhook route MUST be added to `VerifyCsrfToken::$except` array. Forgetting this causes a 419 error on every payment callback. |

### Gateway Log Fields
`fee_payment_gateway_logs` captures: `gateway_name`, `gateway_transaction_id`, `order_id`, `payment_id`, `request_payload` (JSON array), `response_payload` (JSON array), `amount`, `status`, `error_message`, `ip_address`, `user_agent`. No encrypted casts — these fields should be treated as financial-sensitive.

---

## Fee Calculation Engine

### Invoice Generation Logic (currently in `FeeInvoiceController` and `FeeInvoiceService`)
1. Load student assignment → fee structure → installment (if installment-based).
2. `base_amount` = installment.amount_due (from `percentage_due × total_fee_amount`) or one-time fee.
3. `concession_amount` = sum of approved `fee_student_concessions.discount_amount` for the assignment.
4. `fine_amount` = sum of active `fee_fine_transactions.fine_amount` for the assignment not yet waived.
5. `tax_amount` = sum over applicable fee heads: `head.tax_percentage × head_amount / 100`.
6. `total_amount` = `base_amount - concession_amount + fine_amount + tax_amount`.
7. `paid_amount` starts at 0.00.
8. `balance_amount` (DB column) = set to `total_amount` at creation — but is NOT updated by `updatePayment()`. Use `getBalanceAmount()` PHP method for accurate balance at runtime.
9. Invoice number: auto-generated; uniqueness enforced via `UNIQUE` on `invoice_no`.

### Fine Calculation Modes (in `FeeFineService`)

| Mode | Formula |
|------|---------|
| `PerDay` | `fine_amount = fine_value × days_late` (from `applicable_from_day` to `applicable_to_day`) |
| `FlatPerTier` | `fine_amount = fine_value` applied once when overdue period enters that day bracket |
| `Percentage+Capped` | `fine_amount = min(base_amount × fine_value / 100, max_fine_amount)` |

**Idempotency:** `ApplyFines` checks `fine_date` per invoice+rule before inserting — same-day re-run is safe.
**Scheduler:** Command registered, schedule commented out — must be activated.

### Concession Application Order (business rule)
- Only concessions with `approval_status = 'Approved'` are included.
- Multiple concessions per assignment are cumulative.
- Each concession subject to its `max_cap_amount` (per-concession cap).
- Total cumulative concession should not exceed `total_fee_amount` (application-level guard needed).

### Partial Payment Rules
- `updatePayment(float $amount)` adds to `paid_amount`; computes new status via match:
  - `paid_amount <= 0` → Draft/Published (reset case)
  - `paid_amount < total_amount` → Partially Paid
  - default (>= total_amount) → Paid
- Overpayment is accepted (status goes to Paid even if paid > total) — excess handling not implemented.

---

## Cross-Module Dependencies

### FIN Consumes From

| Source Module | Code | Data / Service Used | Tables Referenced |
|--------------|------|---------------------|-------------------|
| StudentProfile | STD | Student list, guardian, fee_payer flag | `std_students`, `std_guardians`, `std_student_guardian_jnt` |
| SchoolSetup | SCH | Academic sessions, classes, sections, sys_users | `sch_org_academic_sessions_jnt`, `sch_classes`, `sch_sections`, `sys_users` |
| SystemConfig | SYS | RBAC roles, dropdown values (fee head type, concession category, student category) | `sys_roles`, `sys_dropdown_table` |
| Payment | PAY | Razorpay gateway (order creation, payment verification) | `Payable` contract interface |
| Transport | TPT | Transport fee integration (planned P3) | `tpt_student_fee_detail`, `tpt_student_fee_collection` |

### FIN Provides To

| Consumer | Code | Mechanism | What FIN Provides |
|----------|------|-----------|-------------------|
| Finance/Accounting | FAC | Laravel Event `StudentFeeCollected` (D21 — not yet emitted) | Receipt voucher creation trigger with head-wise breakdown |
| Notification | NTF | Laravel Events (not yet fired from fine/invoice flows) | Invoice generated, payment received, fine applied, due reminders |
| StudentPortal | STP | REST API (partially planned) | Invoice list, payment initiation, receipt download |
| ParentPortal | PPT | REST API (planned) | Same as StudentPortal for guardian view |
| PredictiveAnalytics | PAN | `fee_defaulter_history.defaulter_score` | AI risk score for defaulter prediction |

### D21 Event Contract (defined, not implemented)

| Event | Emitter Location | Consumer | Status |
|-------|-----------------|----------|--------|
| `StudentFeeCollected` | `FeeTransactionController@store` (after DB commit) | FAC `CreateReceiptVoucher` | ❌ Event class not created |
| `StudentFeeRefunded` | `FeeRefundController@process` | FAC `CreateRefundVoucher` | ❌ Controller not built |
| `FeeFineApplied` | `ApplyFines` command | NTF notification | ❌ Not emitted |
| `FeeInvoiceGenerated` | `FeeInvoiceController@generateFeeInvoice` | NTF notification | ❌ Not emitted |
| `FeeDueReminder` | Scheduler (new) | NTF notification | ❌ Not implemented |

---

## Permission Architecture

### Registered Policies (13 in StudentFeeServiceProvider — confirmed 2026-06-30)

| Policy | Model | Permission Prefix | Registered |
|--------|-------|------------------|:---------:|
| `FeeHeadMasterPolicy` | `FeeHeadMaster` | `tenant.fee-head-master.*` | OVERRIDDEN (see BUG-FIN-07) |
| `FeeGroupMasterPolicy` | `FeeGroupMaster` | `tenant.fee-group-master.*` | YES |
| `FeeStructureMasterPolicy` | `FeeStructureMaster` | `tenant.fee-structure-master.*` | YES |
| `FeeInstallmentPolicy` | `FeeInstallment` | `tenant.fee-installment.*` | YES |
| `FeeStudentAssignmentPolicy` | `FeeStudentAssignment` | `tenant.fee-student-assignment.*` | YES |
| `FeeConcessionTypePolicy` | `FeeConcessionType` | `tenant.fee-concession-type.*` | YES |
| `FeeStudentConcessionPolicy` | `FeeStudentConcession` | `tenant.fee-student-concession.*` | YES |
| `FeeFineRulePolicy` | `FeeFineRule` | `tenant.fee-fine-rule.*` | YES |
| `FeeFineTransactionPolicy` | `FeeFineTransaction` | `tenant.fee-fine-transaction.*` | YES |
| `FeeTransactionPolicy` | `FeeTransaction` | `tenant.fee-transaction.*` | YES |
| `FeeInvoicePolicy` | `FeeInvoice` | `tenant.fee-invoice.*` | YES |
| `FeeScholarshipPolicy` | `FeeScholarship` | `tenant.fee-scholarship.*` | YES |
| `FeeScholarshipApplicationPolicy` | `FeeScholarshipApplication` | `tenant.fee-scholarship-application.*` | YES |
| `StudentFeeManagementPolicy` | `FeeHeadMaster` (virtual) | `tenant.student-fee-management.*` | YES (overrides FeeHeadMasterPolicy!) |

### Policy Gaps

| Entity | Policy File | Registered |
|--------|------------|:---------:|
| `FeeRefund` | MISSING (file not created) | NO |
| `FeeReceipt` | MISSING (file not created) | NO |
| `FeePaymentReconciliation` | MISSING (file not created) | NO |
| `FeeDefaulterHistory` | MISSING (file not created) | NO |
| `FeeMaster` (legacy) | EXISTS but unused | NO |

### Role-Based Access Summary

| Action | School Admin | Accountant | Principal | Class Teacher | Student/Parent |
|--------|:---:|:---:|:---:|:---:|:---:|
| Configure fee structures | Y | N | N | N | N |
| Bulk assign fees | Y | Y | N | N | N |
| Generate invoices | Y | Y | N | N | N |
| Record offline payment | Y | Y | N | N | N |
| Download invoice PDF / receipt | Y | Y | Y | N | Y (own) |
| Approve concessions | Y | N | Y | N | N |
| Approve scholarships | Y | N | Y | N | N |
| Waive fines | Y | N | Y | N | N |
| Initiate refund | Y | N | N | N | N |
| View fee reports / dashboard | Y | Y | Y | Y | N |
| Online payment (portal) | N | N | N | N | Y |

---

## Route Registration Pattern

Routes registered via module's `RouteServiceProvider::mapWebRoutes()` under:
```
middleware: ['web', InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, 'auth', 'verified']
prefix: 'student-fee'
name prefix: 'student-fee.'
source: Modules/StudentFee/routes/web.php
```

**EnsureTenantHasModule: NOT APPLIED (P0 gap)**

The module's `web.php` routes are loaded by the module itself — not from central `routes/tenant.php` (the comment in tenant.php at line 90 says routes were moved to the module).

### Key Route Issues

| Issue | Severity |
|-------|----------|
| `GET /student-fee/seeder` — seeder route with no authorization guard | P0 |
| `EnsureTenantHasModule:StudentFee` missing from RouteServiceProvider | P0 |
| `fee-transaction.store` → `FeeInvoiceController::store` (wrong controller) | P1 |
| `fee-student-concession.trashed` → redirect to configuration (not a real trash view) | P2 |
| `fee-fine-transaction.trashed` → redirect to fineManagement (not a real trash view) | P2 |
| API routes (`routes/api.php`) expose only generic `apiResource` — no webhook handler | P0 |

---

## Design Decisions Made

| Decision | Detail | Source |
|----------|--------|--------|
| Table prefix `fee_*` not `fin_*` | Module code is FIN but all tables use `fee_` prefix. Always check actual prefix vs module code. | DDL migrations |
| `balance_amount` is a regular column, not GENERATED | V2 claims GENERATED STORED; actual migration creates plain DECIMAL(12,2). PHP helper `getBalanceAmount()` is accurate; DB column becomes stale after payments. | migration `2026_06_16_092641` |
| Policies in module `StudentFeeServiceProvider` | Moved from AppServiceProvider to module provider (comment at AppServiceProvider line 125 confirms the move). | `Modules/StudentFee/app/Providers/StudentFeeServiceProvider.php` |
| `FeeInvoice` implements `Payable` contract | Integration point for PAY module (Razorpay). `getPayableAmount()` returns `getBalanceAmount()`. | `Modules/StudentFee/app/Models/FeeInvoice.php` |
| `join_in_mid-year` hyphen column | DDL artifact using a column name with a hyphen. Boolean column in migration. Requires backtick quoting in raw SQL. | migration `2026_06_16_092639` |
| Governance hub page | `StudentFeeManagementController@governance` route and view exist but were not listed in V2 screens — added as extra hub navigation. | `routes/web.php:31` |
| `fee_invoices.invoice_no` unique | Invoice number uniqueness enforced at DB level (UQ index). V2 does not mention the exact numbering scheme — check FeeInvoiceController for auto-generation logic. | migration + model |
| `fee_scholarship_applications.academic_session_id` is SMALLINT UNSIGNED | Matches `sch_org_academic_sessions_jnt.id` type. Important for FK join queries. | migration `2026_06_16_092636` |
| Partial fine waiver | `fee_fine_transactions.waived_amount = NULL` means full waiver; non-NULL value means partial waiver. `waived = 1` is the flag; `waived_amount` quantifies the waived portion. | V2 BR-FIN-04.7 |

---

## V1 Screen Spec Inventory (15 files)

| File | Coverage |
|------|---------|
| `implementation-plan.md` | Architecture overview, tech stack, rollout plan |
| `fee-heads.md` | Fee head CRUD, type, frequency, tax, account code |
| `fee-groups.md` | Fee group CRUD, head-to-group mapping |
| `fee-structures.md` | Structure CRUD, session+class+category template, head amounts |
| `fee-installments.md` | Installment schedule, grace days, percentage_due |
| `fee-assignments.md` | Bulk/individual assignment, mid-year join, proration |
| `fee-invoicing.md` | Invoice generation, PDF, email, WhatsApp, cancellation |
| `fee-payments.md` | Offline recording, payment modes, receipt generation |
| `fee-concessions.md` | Concession type CRUD, student application, approval workflow |
| `fee-fines.md` | Fine rule configuration, ApplyFines, waiver |
| `fee-scholarships.md` | Scholarship fund, application lifecycle, disbursement |
| `fee-reconciliation.md` | Cheque/DD clearance lifecycle (not yet built in code) |
| `fee-refunds.md` | Refund initiation and approval (not yet built in code) |
| `fee-name-removal.md` | Name removal log, re-admission workflow |
| `fee-dashboard.md` | Dashboard KPI cards, defaulter list, collection chart |

---

## Controller Inventory

| Controller | Primary Responsibility |
|------------|----------------------|
| `StudentFeeController` | **MUST DELETE seederFunction(); remove Faker import** — stub only |
| `StudentFeeManagementController` | Dashboard, hub page navigation (configuration, assignment, billing, payment, fine-management, scholarship, governance) |
| `FeeHeadMasterController` | Fee head CRUD + toggle + trash/restore/forceDelete |
| `FeeGroupMasterController` | Fee group CRUD + toggle + trash/restore/forceDelete |
| `FeeStructureMasterController` | Fee structure CRUD + toggle + trash/restore/forceDelete |
| `FeeInstallmentController` | Installment CRUD + toggle + trash/restore/forceDelete |
| `FeeConcessionTypeController` | Concession type CRUD + toggle + trash/restore/forceDelete |
| `FeeStudentConcessionController` | Student concession apply + approve/reject |
| `FeeFineRuleController` | Fine rule CRUD + toggle + trash/restore/forceDelete |
| `FeeFineTransactionController` | Fine transaction list + waive |
| `FeeStudentAssignmentController` | Assignment CRUD + bulk generate + section AJAX + update-structure |
| `FeeScholarshipController` | Scholarship fund CRUD + toggle + trash/restore/forceDelete |
| `FeeScholarshipApplicationController` | Application CRUD + submit/approve/reject/waitlist/disburse |
| `FeeInvoiceController` | Invoice CRUD + bulk generate + PDF + email + WhatsApp + cancel + recordPayment |
| `FeeTransactionController` | Transaction list (read-only) + receipt download |

**Missing controllers (P1):** `FeeRefundController`, `FeeChequeController` (reconciliation), `FeeDefaulterHistoryController`

---

## Lessons Learned

- [2026-06-30 | Business Analyst] The V2 requirement document (2026-03-26) claimed 0 FormRequests and 0 Services as P1 gaps. The actual code (2026-06-30) has 36 FormRequests and 3 Services. Always verify counts against the filesystem before trusting V2 claims. V2 was accurate when written but the module was actively developed afterward.
- [2026-06-30 | Business Analyst] `fee_invoices.balance_amount` is described as a GENERATED STORED column in V2, but the actual migration creates it as a plain DECIMAL(12,2). The model has a PHP helper `getBalanceAmount()` that computes it at runtime correctly. However the DB column becomes stale after any payment via `updatePayment()`. When reporting on fee balances from raw SQL, always use `total_amount - paid_amount` rather than `balance_amount`. This discrepancy between V2 and actual DDL must be resolved before the module goes to production.
- [2026-06-30 | Business Analyst] `StudentFeeServiceProvider` registers `FeeHeadMaster` → `StudentFeeManagementPolicy` AFTER registering `FeeHeadMaster` → `FeeHeadMasterPolicy`. Laravel's last-registration-wins means `FeeHeadMasterPolicy` is silently overridden. Always check duplicate model registrations in policy providers — they are silent failures.
- [2026-06-30 | Business Analyst] The `ApplyFines` scheduler is commented out in `registerCommandSchedules()`. This is a common pattern during development to avoid running scheduled tasks locally. However it means the production fine application never runs automatically. Always check `registerCommandSchedules()` (or the central Laravel 12 scheduler config) when verifying that a registered Artisan command actually fires.
- [2026-06-30 | Business Analyst] The StudentFee module moved its routes from central `routes/tenant.php` to the module's own `RouteServiceProvider`. The comment in tenant.php at line 90 confirms this. When auditing routes for this module, check `Modules/StudentFee/app/Providers/RouteServiceProvider.php` and `Modules/StudentFee/routes/web.php` — not tenant.php.
- [2026-06-30 | Business Analyst] The table prefix is `fee_*` but the module code is `FIN`. This is a common source of confusion. When searching for migrations, use `fee_` not `fin_`. When writing module code documentation, note both the code (FIN) and the actual DB prefix (fee_).
- [2026-06-30 | Business Analyst] `join_in_mid-year` column name with a hyphen in `fee_student_assignments` is a second instance of this pattern (after VND's GENERATED column). Always grep new financial migrations for unusual column name characters (`-`, spaces, periods) that require special quoting in SQL.
- [2026-06-30 | Technical Auditor] GAP-FIN-16 from BA analysis was WRONG — `StudentFeeManagementController` DOES have `Gate::authorize('tenant.student-fee-management.viewAny')` on ALL public methods (dashboard, configuration, assignment, billing, payment, fineManagement, scholarship, governance). Auth was added after the BA analysis was written. FIN has the best Gate coverage on the platform — 100% of methods in all 15 controllers. Never trust BA findings about auth gaps without live code verification.
- [2026-06-30 | Technical Auditor] `fee_invoices.invoice_no` has NO UNIQUE constraint in the migration (only idx_invoice_status, idx_invoice_due_date, idx_invoice_student). Module knowledge claimed UNIQUE enforcement — it does not exist at DB level. Combined with the TOCTOU race in generateInvoiceNumber() (max('id') before INSERT), duplicate invoice numbers are possible under concurrent load. Always verify unique constraints with grep on the actual migration file.
- [2026-06-30 | Technical Auditor] `fee_invoices.balance_amount` is `DECIMAL(12,2)` with no default and NOT NULL in migration. `store()` and `generateFeeInvoice()` never set it → MySQL permissive mode gives it 0. `updatePayment()` never updates it. DB column is always 0. Dashboard sort by balance_amount is wrong. Use `getBalanceAmount()` PHP method for accurate runtime values. Fix: migrate to GENERATED STORED column or add update to all write paths.
- [2026-06-30 | Technical Auditor] All 36 FormRequests return `true` from `authorize()` (D30 platform pattern). Controllers compensate with Gate::authorize (100% coverage confirmed). FormRequest-level ownership validation is absent for payment-critical requests.
- [2026-06-30 | Technical Auditor] 16 ENUM columns across fee_ migrations (D29). Priority for conversion: fee_invoices.status (most queried), fee_transactions.status (payment-critical), fee_fine_rules (4 ENUMs in one table).
- [2026-06-30 | Technical Auditor] Two route closures in web.php (lines 94 and 107) break `route:cache`. These cover the "trashed" redirect behavior for fee-student-concession and fee-fine-transaction. Convert to controller methods to enable route caching.
- [2026-06-30 | Technical Auditor] `mapApiRoutes()` in RouteServiceProvider applies only `'api'` middleware — no tenancy stack. Inner api.php adds `auth:sanctum` only. Same pattern as SEC-TT-004/SEC-TTF-004. All StudentFee API requests run without tenant DB context (SEC-FIN-34 P0). All module RSPs must be audited for this pattern.

---

## Pending Next Steps

1. **P0:** Remove `Route::get('/seeder', ...)` from `Modules/StudentFee/routes/web.php:22`
2. **P0:** Remove `use Faker\Factory as Faker` import + `seederFunction()` method from `StudentFeeController`
3. **P0:** Add `EnsureTenantHasModule:StudentFee` to `RouteServiceProvider::mapWebRoutes()` middleware array
4. **P0:** Implement Razorpay webhook endpoint in `routes/api.php` with HMAC signature verification + CSRF bypass + idempotency check
5. **P1:** Fix `balance_amount` stale data: either add `balance_amount` update inside `FeeInvoice::updatePayment()`, or convert to MySQL GENERATED STORED column via new migration
6. **P1:** Uncomment and configure the `ApplyFines` schedule in `StudentFeeServiceProvider::registerCommandSchedules()` to run nightly at 00:30
7. **P1:** Fix policy override bug: split `StudentFeeManagementPolicy` to a dedicated model or use a virtual model rather than re-registering `FeeHeadMaster`
8. **P1:** Create `FeeRefundController` + routes (`fee-refund.*`) for full refund lifecycle
9. **P1:** Create `FeeChequeController` + routes (`fee-cheque-clearance.*`) for reconciliation lifecycle
10. **P1:** Fix `fee-transaction.store` route: point to `FeeTransactionController` not `FeeInvoiceController`
11. **P1:** Add `Gate::authorize` to all `StudentFeeManagementController` hub methods
12. **P1:** Create `StudentFeeCollected` and `StudentFeeRefunded` event classes; register listeners in `EventServiceProvider`
13. **P1:** Create missing policy files: `FeeRefundPolicy`, `FeeReceiptPolicy`, `FeePaymentReconciliationPolicy`, `FeeDefaulterHistoryPolicy`; register in `StudentFeeServiceProvider`
14. **P2:** Create `FeeDefaulterHistoryController` + analytics screen (SCR-FIN-29)
15. **P2:** Add concession approval notification dispatch in `FeeStudentConcessionController::store()`
16. **P2:** Queue bulk invoice generation for > 100 students via `GenerateFeeInvoicesJob`
17. **P2:** Delete `resources/views/fee-invoice/invoice_27_02_2026.blade.php`
18. **Test priority:** Feature tests for invoice generation flow, payment recording (including stale balance_amount verification), fine calculation (PerDay/FlatPerTier), scholarship disbursement, seeder route returns 403/404 after removal (regression), EnsureTenantHasModule returns 403 without license

---

## Version History

| Version | Date | Agent | Changes |
|---------|------|-------|---------|
| 1.0 | 2026-06-30 | Business Analyst | Initial seed — V2 requirement (full read, 1167 lines), V1 screen specs (15 files), full filesystem verification, 24 migrations confirmed; balance_amount DDL discrepancy documented; policy override bug identified; scheduler gap found; all 33 gaps catalogued |
| 1.1 | 2026-06-30 | Business Analyst | FRD completed (20 REQ, 87 BR, 5 workflows, 8 reports, 5 ENH); Complete Analysis Pack produced (RTM, conditions catalog, FSM catalog, data dictionary, cross-module dependency map, NFR catalog, risk register, sprint task breakdown, user stories, KPI spec); Conditions Catalog saved to 5-Requirement_Conditions; FRD summary block added to module knowledge |
