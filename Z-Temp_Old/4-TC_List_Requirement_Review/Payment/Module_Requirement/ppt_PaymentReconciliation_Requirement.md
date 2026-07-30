# Payment Reconciliation — Feature Requirement

| Attribute | Value |
|-----------|-------|
| **Module** | Payment |
| **Feature ID** | F6 |
| **Prefix** | `ppt_` |
| **Type** | Infrastructure / Service |
| **Source** | Code analysis + DDL (no FRD) |
| **Version** | V1 — |
| **Status** | ⬜ Not Reviewed |
| **CR** | ◌ None |

---

## 1. Module Overview

Payment Reconciliation matches **gateway settlement statements** (CSV files from Razorpay, PhonePe, etc.) against **local payment records** to detect discrepancies. It is a **backend-only service** (no mobile API) that provides:

- **CSV Upload & Reconciliation** — Upload a gateway settlement CSV and auto-match each row to `ptm_payment_payments`
- **Scheduled Auto-Reconciliation** — Console command `payment:reconcile-settlements` runs daily at 03:00
- **Discrepancy Detection** — Flags unmatched rows and amount mismatches (tolerance: ₹0.01)
- **Resolution Workflow** — Reconciliations can be marked as resolved by authorized users
- **Summary Dashboard** — Detailed view with summary stats per reconciliation

---

## 2. Feature Summary

| Capability | Description |
|---|---|
| CSV Parsing | Parse Razorpay and generic settlement CSV formats with 20+ header aliases |
| Payment Matching | Match CSV rows to local `ptm_payment_payments` by `gateway_payment_id` or `gateway_order_id` |
| Match Status Determination | Three outcomes: `matched`, `unmatched`, `amount_mismatch` (tolerance 0.01) |
| Summary Calculation | `expected_amount` (CSV sum), `settled_amount` (matched net sum), `discrepancy` |
| Auto-Status | `matched` if all lines match, `discrepant` if any unmatched/mismatch |
| Resolution | Users can mark reconciliations as `resolved` (stamped with user ID) |
| Scheduled Cron | `payment:reconcile-settlements` runs daily at 03:00, reads from `storage/app/payment-settlements/{code}/{date}.csv` |
| Dry Run Mode | Parse and match without persisting (via console `--dry-run`) |
| Audit Trail | All reconciliations logged with bank_statement_json summary |

---

## 3. Technical Stack

| Layer | Technology | Details |
|---|---|---|
| Framework | Laravel 12 | Controller-Service pattern |
| Backend UI | Blade + AdminLTE | List, detail, upload, resolve |
| CSV Parsing | Native PHP (`fgetcsv`) | No external CSV libraries |
| Database | MySQL 8 | InnoDB, 2 tables |
| Authorization | Gates (registered in `PaymentServiceProvider`) | 4 reconciliation gates |
| Scheduled Task | Laravel Scheduler | `dailyAt('03:00')`, `withoutOverlapping`, `onOneServer` |
| Console Command | Artisan | `payment:reconcile-settlements` |

---

## 4. Architecture & Flow

### 4.1 Manual CSV Upload Flow

```
Backend User                    Backend
    │                              │
    │  POST /payment/reconciliation│
    │  multipart: gateway_id, file,│
    │             date (Y-m-d)     │
    │                              │
    ├──────► PaymentReconciliationController@store
    │         ├─ Gate: tenant.payment.reconciliation.create
    │         ├─ Validates: gateway_id (exists), file (csv/txt, max 10MB), date (Y-m-d)
    │         ├─ PaymentGateway::findOrFail(gateway_id)
    │         ├─ file->getRealPath()
    │         └─ ReconciliationService->reconcile(gateway, filePath, date)
    │                              │
    │            PaymentReconciliationService@reconcile
    │              ├─ parseCsv(filePath) → Collection of rows
    │              ├─ DB::transaction
    │              │   ├─ Create PaymentReconciliation (status=pending)
    │              │   ├─ For each CSV row:
    │              │   │   ├─ matchPayment(row) → ?Payment
    │              │   │   ├─ determineMatchStatus(payment, row)
    │              │   │   └─ Create PaymentReconciliationLine
    │              │   ├─ Update PaymentReconciliation:
    │              │   │   ├─ expected_amount = sum(CSV amounts)
    │              │   │   ├─ settled_amount = sum(matched net_amounts)
    │              │   │   ├─ discrepancy = expected - settled
    │              │   │   ├─ status = matched|discrepant
    │              │   │   └─ bank_statement_json = summary
    │              │   └─ Log::info reconciliation complete
    │              └─ Return PaymentReconciliation
    │                              │
    │  ◄── redirect(payment.reconciliation.show, id)
    │       with flash: "Reconciliation #{id} completed."
    │                              │
    │  POST /payment/reconciliation/{id}/resolve
    │         ├─ Gate: tenant.payment.reconciliation.resolve
    │         ├─ findOrFail(id)
    │         ├─ Update: status=resolved, resolved_by=auth()->id()
    │         └─ redirect with flash: "Reconciliation marked as resolved."
    │                              │
```

### 4.2 Scheduled Auto-Reconciliation Flow

```
Cron (03:00 daily)
    │
    ├────► Artisan command: payment:reconcile-settlements
    │         │
    │         ├─ Reads --date option (default: yesterday, Y-m-d)
    │         ├─ Reads --gateway option (filter by code)
    │         ├─ Reads --dry-run option (parse only, no persist)
    │         │
    │         ├─ Fetch all active gateways
    │         │     PaymentGateway::where('is_active', true)
    │         │
    │         ├─ For each gateway:
    │         │     ├─ Look for: storage/app/payment-settlements/{code}/{date}.csv
    │         │     ├─ If not found: log info, skip
    │         │     └─ If found:
    │         │           ├─ service->reconcile(gateway, filePath, date, dryRun)
    │         │           └─ Log result (status, discrepancy)
    │         │
    │         └─ Return SUCCESS
```

---

## 5. Data Model

### 5.1 `ptm_payment_reconciliations`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INT UNSIGNED | PK, AUTO_INCREMENT | |
| `gateway_id` | BIGINT UNSIGNED | FK → ptm_payment_gateways(id) ON DELETE CASCADE | |
| `date` | DATE | NOT NULL | Settlement date |
| `expected_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0 | Sum of all CSV row amounts |
| `settled_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0 | Sum of matched rows' net_amount |
| `discrepancy` | DECIMAL(12,2) | NOT NULL, DEFAULT 0 | expected_amount − settled_amount |
| `status` | VARCHAR(255) | NOT NULL, DEFAULT 'pending' | pending → matched / discrepant → resolved |
| `notes` | TEXT | NULLABLE | |
| `bank_statement_json` | JSON | NULLABLE | Summary: total/matched/unmatched/mismatch rows |
| `resolved_by` | INT UNSIGNED | FK → sys_users(id) ON DELETE SET NULL | |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 | |
| `created_by` | INT UNSIGNED | NULLABLE | |
| `created_at` | TIMESTAMP | NULLABLE | |
| `updated_at` | TIMESTAMP | NULLABLE | |
| `deleted_at` | TIMESTAMP | NULLABLE | Soft delete |

**Indexes:**
- INDEX: `(gateway_id, date)`, `(status)`

**Model Casts:** `date` → date, `expected_amount` → float, `settled_amount` → float, `discrepancy` → float, `bank_statement_json` → array, `is_active` → boolean

**Status Constants:**
```php
STATUS_PENDING    = 'pending'
STATUS_MATCHED    = 'matched'
STATUS_DISCREPANT = 'discrepant'
STATUS_RESOLVED   = 'resolved'
```

### 5.2 `ptm_reconciliation_lines`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INT UNSIGNED | PK, AUTO_INCREMENT | |
| `reconciliation_id` | INT UNSIGNED | FK → ptm_payment_reconciliations(id) ON DELETE CASCADE | |
| `gateway_payment_id` | VARCHAR(255) | NULLABLE | From CSV row |
| `gateway_order_id` | VARCHAR(255) | NULLABLE | From CSV row |
| `transaction_date` | DATE | NULLABLE | From CSV row |
| `amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0 | Gross amount from CSV |
| `fee` | DECIMAL(12,2) | NOT NULL, DEFAULT 0 | Gateway fee from CSV |
| `net_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0 | amount − fee (or explicit from CSV) |
| `matched_payment_id` | INT UNSIGNED | FK → ptm_payment_payments(id) ON DELETE SET NULL | |
| `match_status` | VARCHAR(20) | NOT NULL, DEFAULT 'unmatched' | matched / unmatched / amount_mismatch |
| `notes` | TEXT | NULLABLE | Human-readable diff for mismatches |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 | |
| `created_by` | INT UNSIGNED | NULLABLE | |
| `created_at` | TIMESTAMP | NULLABLE | |
| `updated_at` | TIMESTAMP | NULLABLE | |
| `deleted_at` | TIMESTAMP | NULLABLE | Soft delete |

**Indexes:**
- INDEX: `gateway_payment_id`, `gateway_order_id`, `reconciliation_id`, `match_status`

**Model Casts:** `transaction_date` → date, `amount` → float, `fee` → float, `net_amount` → float, `is_active` → boolean

**Match Status Constants:**
```php
MATCH_MATCHED         = 'matched'
MATCH_UNMATCHED       = 'unmatched'
MATCH_AMOUNT_MISMATCH = 'amount_mismatch'
```

### 5.3 ER Relationship

```
ptm_payment_gateways
    1 ──── * ptm_payment_reconciliations
                  1 ──── * ptm_reconciliation_lines
                                   * ──── 1 ptm_payment_payments (matched_payment_id)
```

---

## 6. API / Web Contracts

Feature is **backend-only**. No mobile API endpoints exist. All routes are Blade-based.

### 6.1 List Reconciliations

```
GET /payment/reconciliation
```

Renders a paginated list (20 per page) with gateway name, date, expected/settled/discrepancy amounts, status.

### 6.2 Show Reconciliation Detail

```
GET /payment/reconciliation/{id}
```

Renders detail view with:
- Header: gateway, date, expected/settled/discrepancy, status, resolved info
- Summary stats: `total`, `matched`, `unmatched`, `mismatch` counts
- Lines table: each row with gateway_payment_id, order_id, transaction_date, amount, fee, net_amount, match_status, matched payment link, notes
- Eager loads: `gateway`, `lines.matchedPayment`

### 6.3 Upload CSV & Reconcile

```
POST /payment/reconciliation
Content-Type: multipart/form-data
```

| Field | Type | Required | Rules |
|---|---|---|---|
| `gateway_id` | integer | Yes | `required`, `exists:ptm_payment_gateways,id` |
| `file` | file | Yes | `required`, `file`, `mimes:csv,txt`, `max:10240` (10 MB) |
| `date` | string | Yes | `required`, `date_format:Y-m-d` |

**Success:** Redirect to `/payment/reconciliation/{id}` with flash message.

**Error Responses:**
- Redirect back with validation errors
- Gateway not found: 404 (ModelNotFoundException)
- CSV empty or unreadable: `RuntimeException` with message `"Empty or unreadable CSV: {path}"`
- No data rows: `RuntimeException` with message `"No data rows found in CSV: {path}"`

### 6.4 Resolve Reconciliation

```
POST /payment/reconciliation/{id}/resolve
```

**Success:** Redirect back to show page with flash: `"Reconciliation marked as resolved."`

Updates `status` → `resolved`, `resolved_by` → `auth()->id()`.

---

## 7. Business Logic / Services

### 7.1 `PaymentReconciliationService@reconcile(gateway, filePath, date, dryRun = false)`

| Step | Description |
|---|---|
| 1 | Call `parseCsv(filePath)` → Collection of structured rows |
| 2 | Begin DB transaction |
| 3 | Create `PaymentReconciliation` (status=pending) — or in-memory if dryRun |
| 4 | Loop through each CSV row: |
|    | a. Accumulate `expectedTotal += row.amount` |
|    | b. Call `matchPayment(row)` → `?Payment` |
|    | c. Call `determineMatchStatus(payment, row)` → matched/unmatched/amount_mismatch |
|    | d. If matched: `settledTotal += row.net_amount` |
|    | e. If not dryRun: create `PaymentReconciliationLine` with matched_payment_id, match_status, notes |
| 5 | If not dryRun: update PaymentReconciliation |
|    | - `expected_amount = expectedTotal` |
|    | - `settled_amount = settledTotal` |
|    | - `discrepancy = round(expectedTotal - settledTotal, 2)` |
|    | - `status = unmatchedCount > 0 or mismatchCount > 0 ? 'discrepant' : 'matched'` |
|    | - `bank_statement_json = { total_rows, matched_rows, unmatched_rows, mismatch_rows }` |
| 6 | Log info: `"Payment reconciliation [{id}] completed for gateway [{code}] on {date}"` |
| 7 | Return `PaymentReconciliation` |

### 7.2 `PaymentReconciliationService@parseCsv(filePath)`

| Step | Description |
|---|---|
| 1 | Open file with `fopen` |
| 2 | Read headers with `fgetcsv`, trim each header |
| 3 | Call `mapHeaders(headers)` → map of field→column index |
| 4 | Loop through remaining rows with `fgetcsv` |
|    | - Skip malformed rows (fewer columns than headers) |
|    | - Build associative row using header map |
|    | - Cast `amount`, `fee`, `net_amount` to float |
|    | - If `net_amount == 0` and `amount > 0`: `net_amount = round(amount - fee, 2)` |
| 5 | Close file |
| 6 | If no rows parsed: throw `RuntimeException("No data rows found in CSV: {path}")` |
| 7 | Return Collection of rows |

### 7.3 `PaymentReconciliationService@matchPayment(row)`

| Priority | Match Strategy |
|---|---|
| 1 | `gateway_payment_id` → `Payment::where('gateway_payment_id', row.gateway_payment_id)` |
| 2 | `gateway_order_id` → `Payment::where('gateway_order_id', row.gateway_order_id)` |
| 3 | Neither available → return null |

### 7.4 `PaymentReconciliationService@determineMatchStatus(payment, row)`

| Condition | Status |
|---|---|
| `payment === null` | `unmatched` |
| `abs(row.amount - payment.amount) > 0.01` | `amount_mismatch` |
| Otherwise | `matched` |

### 7.5 `PaymentReconciliationService@mapHeaders(headers)`

Supports these aliases (case-insensitive):

| Internal Field | CSV Header Aliases |
|---|---|
| `gateway_payment_id` | `payment_id`, `gateway_payment_id`, `razorpay_payment_id`, `payment id`, `txn_id`, `transaction_id`, `transaction id` |
| `gateway_order_id` | `order_id`, `gateway_order_id`, `razorpay_order_id`, `order id`, `merchant_order_id` |
| `transaction_date` | `date`, `transaction_date`, `settlement_date`, `transaction date`, `settlement date`, `created_at`, `created` |
| `amount` | `amount`, `gross_amount`, `transaction_amount`, `txn_amount`, `payment_amount`, `total_amount` |
| `fee` | `fee`, `gateway_fee`, `processing_fee`, `commission`, `pg_fee`, `charges`, `fee_amount` |
| `net_amount` | `net_amount`, `net`, `settled_amount`, `credit`, `net amount`, `settled amount`, `deposit_amount` |

**Fallback positional mapping** (if amount header not detected):
- Col 0: amount, Col 1: fee, Col 2: net_amount, Col 3: gateway_payment_id, Col 4: gateway_order_id, Col 5: transaction_date

---

## 8. Console Command

### `payment:reconcile-settlements`

| Property | Value |
|---|---|
| Signature | `payment:reconcile-settlements {--date=} {--gateway=} {--dry-run}` |
| Description | Reconcile gateway settlement statements against recorded payments |
| Default date | `now()->subDay()->format('Y-m-d')` (yesterday) |
| File path pattern | `storage/app/payment-settlements/{gateway.code}/{date}.csv` |
| Gateway filter | All active gateways, or single if `--gateway` provided |
| Schedule | `dailyAt('03:00')`, `withoutOverlapping()`, `onOneServer()` |
| Dry run | Parse and match but do not persist |

---

## 9. Authorization

| Action | Gate | Registered In |
|---|---|---|
| View reconciliation list | `tenant.payment.reconciliation.viewAny` | `PaymentServiceProvider@registerGates` |
| View reconciliation detail | `tenant.payment.reconciliation.view` | `PaymentServiceProvider@registerGates` |
| Upload CSV / create reconciliation | `tenant.payment.reconciliation.create` | `PaymentServiceProvider@registerGates` |
| Resolve reconciliation | `tenant.payment.reconciliation.resolve` | `PaymentServiceProvider@registerGates` |

All gates are registered as explicit `Gate::define()` with same-name closure delegating to `$user->can($ability)`.

---

## 10. Validation Rules

| Source | Field | Rules |
|---|---|---|
| `PaymentReconciliationController@store` | `gateway_id` | `required`, `exists:ptm_payment_gateways,id` |
| `PaymentReconciliationController@store` | `file` | `required`, `file`, `mimes:csv,txt`, `max:10240` |
| `PaymentReconciliationController@store` | `date` | `required`, `date_format:Y-m-d` |
| `PaymentReconciliationService@parseCsv` | File | Must be readable, non-empty CSV |
| `PaymentReconciliationService@parseCsv` | Rows | At least 1 data row after headers |

---

## 11. Error Handling

| Scenario | Exception Type | Message |
|---|---|---|
| CSV file unreadable | `RuntimeException` | `"Cannot open file: {path}"` |
| CSV headers empty | `RuntimeException` | `"Empty or unreadable CSV: {path}"` |
| No data rows in CSV | `RuntimeException` | `"No data rows found in CSV: {path}"` |
| Gateway not found | `ModelNotFoundException` | From `findOrFail` |
| Reconciliation not found | `ModelNotFoundException` | From `findOrFail` |
| Unauthorized view | `AuthorizationException` | From `Gate::authorize()` |
| File too large (>10MB) | `ValidationException` | `file.max` |
| Wrong file type | `ValidationException` | `file.mimes` |
| Invalid date format | `ValidationException` | `date.date_format` |

---

## 12. State Machine

### 12.1 Reconciliation Status

```
                    ┌──────────┐
                    │  pending │
                    └────┬─────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
         ┌────▼────┐ ┌──▼──────┐   │
         │ matched │ │discrepant│   │
         └────┬────┘ └──┬──────┘   │
              │          │          │
              └────┬─────┘          │
                   │                │
              ┌────▼──────┐         │
              │  resolved  │◄────────┘
              └───────────┘
```

- **pending** — Initial state on creation
- **matched** — All lines matched cleanly (auto-set by `reconcile()`)
- **discrepant** — One or more lines unmatched or amount_mismatch (auto-set by `reconcile()`)
- **resolved** — Manually set by authorized user via `resolve()` endpoint

### 12.2 Line Match Status

```
                    CSV Row
                       │
                       │
              ┌────────┼────────┐
              │        │        │
         Payment     No       Amount
         matched   Payment    diff
         exactly    found     > 0.01
              │        │        │
         ┌────▼──┐ ┌──▼────┐ ┌──▼──────────┐
         │matched│ │unmatched│ │amount_mismatch│
         └───────┘ └────────┘ └──────────────┘
```

---

## 13. Scheduled / Cron Tasks

| Command | Schedule | Overlap | Description |
|---|---|---|---|
| `payment:reconcile-settlements` | `dailyAt('03:00')` | `withoutOverlapping()` `onOneServer()` | Auto-reconcile yesterday's settlements for all active gateways |

**Pre-requisite for auto-reconciliation:** Settlement CSV files must be placed at:
```
storage/app/payment-settlements/{gateway_code}/{YYYY-MM-DD}.csv
```

---

## 14. Configuration

No explicit configuration beyond gateway setup. Behavior determined by:

| Aspect | Configuration |
|---|---|
| Gateway resolution | `ptm_payment_gateways` table — `code`, `driver`, `credentials`, `is_active` |
| Settlement file path | Hard-coded: `storage/app/payment-settlements/{code}/{date}.csv` |
| Match amount tolerance | Hard-coded: `0.01` |
| File size limit | Controller validation: `max:10240` (10 MB) |
| Pagination | Controller: 20 per page |
| Schedule time | `PaymentServiceProvider`: `03:00` daily |

---

## 15. Security Considerations

| Concern | Mitigation |
|---|---|
| Unauthorized reconciliation access | Gate-based authorization on every endpoint |
| Unauthorized CSV upload | `tenant.payment.reconciliation.create` gate |
| Malformed CSV injection | Native `fgetcsv` parsing — no eval, no injection vector |
| Large file DoS | `max:10240` (10 MB) file size limit |
| Gateway manipulation | `gateway_id` validated against `ptm_payment_gateways` table |
| Reconciled data integrity | All operations within DB transactions |
| Soft delete protection | All rows use `SoftDeletes` + `is_active` flag |

---

## 16. Open Items / Gaps

| # | Issue | Severity | Description |
|---|---|---|---|
| 1 | **GAP-REC-001** | Low | **No explicit `viewAny`/`view` policy on PaymentReconciliation model.** Gates are registered as standalone `Gate::define()` — not via model policy. `$this->authorize('viewAny', PaymentReconciliation::class)` is not used; `Gate::authorize()` with string gate name is used instead. This is correct but inconsistent with module conventions. |
| 2 | **GAP-REC-002** | Low | **No API for reconciliation.** Feature is backend-only. Mobile apps cannot query reconciliation status or upload CSVs. This may be by design. |
| 3 | **GAP-REC-003** | Medium | **No notification for discrepancies.** When auto-reconciliation finds discrepancies, no alert/email is sent to finance team. Discrepancies are only visible in the backend UI. |
| 4 | **GAP-REC-004** | Low | **Dry-run mode only available via console.** Manual CSV upload always persists. No "preview before saving" UI. |
| 5 | **GAP-REC-005** | Low | **Settlement file naming is fixed.** Expects exact path `{code}/{date}.csv`. No support for zip files, multiple files per day, or alternative naming patterns. |
| 6 | **GAP-REC-006** | Info | **Only CSV/TXT file types supported.** No XLSX, PDF bank statement, or API-based settlement retrieval. |
| 7 | **GAP-REC-007** | Low | **No idempotency for reconciliation.** Same CSV uploaded twice creates two separate reconciliation records. No check for duplicate (gateway_id + date). |
| 8 | **GAP-REC-008** | Info | **`resolve()` can be called on already-resolved reconciliations.** No validation prevents re-resolving. `resolved_by` is overwritten. |

---

> **Document generated from source code analysis.**
> Source files: PaymentReconciliationController.php, PaymentReconciliationService.php, PaymentReconciliation.php, PaymentReconciliationLine.php, ReconcileGatewaySettlements.php, PaymentGateway.php, PaymentServiceProvider.php, routes/web.php
