# Payment Reconciliation — Test Case List

| Attribute | Value |
|-----------|-------|
| **Module** | Payment |
| **Feature ID** | F6 |
| **Prefix** | `ppt_` |
| **Type** | Infrastructure / Service |
| **Version** | V1 — |
| **Status** | ⬜ Not Reviewed |
| **CR** | ◌ None |

---

## 1. Test Case Summary

| Total TC | Automated | Manual | Pass | Fail | Blocked | Not Run |
|----------|-----------|--------|------|------|---------|---------|
| 32 | 0 | 32 | 0 | 0 | 0 | 32 |

---

## 2. Test Case List

### 2.1 CSV Upload & Reconcile — Validation

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REC_TC_001 | Upload valid CSV with all rows matching | Gateway exists (Razorpay), CSV file with 3 rows where all gateway_payment_ids exist locally as success payments | 1. POST `/payment/reconciliation` with multipart form data | `gateway_id: 1`, `file: valid_razorpay_settlement.csv`, `date: 2026-07-22` | 302 Redirect to `/payment/reconciliation/{id}`. Flash success: `"Reconciliation #{id} completed."`. Reconciliation created with status=matched. All lines matched. | — | ⬜ |
| PPT_REC_TC_002 | Upload CSV with some unmatched rows | CSV with 2 matched rows + 1 unmatched gateway_payment_id | 1. POST as above | CSV with mixed match statuses | 302 Redirect. Reconciliation status=discrepant. Summary: total=3, matched=2, unmatched=1, mismatch=0. Discrepancy = amount of unmatched row. | — | ⬜ |
| PPT_REC_TC_003 | Upload CSV with amount mismatch | CSV row with amount different from payment amount by > 0.01 | 1. POST as above | CSV with amount=500 but payment amount=450 | 302 Redirect. Reconciliation status=discrepant. Line match_status=amount_mismatch. Notes: `"System amount: 450, settlement amount: 500, difference: 50"` | — | ⬜ |
| PPT_REC_TC_004 | Upload CSV amount mismatch within tolerance (0.01) | CSV amount differs by exactly 0.01 | 1. POST as above | CSV amount=450.01, payment amount=450.00 | Line match_status=matched (within 0.01 tolerance). No notes. | — | ⬜ |
| PPT_REC_TC_005 | Upload CSV with missing gateway_id | — | 1. POST without gateway_id | `file: valid.csv`, `date: 2026-07-22` | 302 Redirect back. Validation error: `gateway_id.required`. | — | ⬜ |
| PPT_REC_TC_006 | Upload CSV with non-existent gateway_id | — | 1. POST with gateway_id=9999 | `gateway_id: 9999`, `file: valid.csv`, `date: 2026-07-22` | 302 Redirect back. Validation error: `gateway_id.exists`. | — | ⬜ |
| PPT_REC_TC_007 | Upload CSV with invalid file type | — | 1. POST with PDF file | `file: document.pdf` | 302 Redirect back. Validation error: `file.mimes`. | — | ⬜ |
| PPT_REC_TC_008 | Upload CSV exceeding max file size (10MB) | — | 1. POST with 11MB file | `file: large.csv` (>10MB) | 302 Redirect back. Validation error: `file.max`. | — | ⬜ |
| PPT_REC_TC_009 | Upload CSV with invalid date format | — | 1. POST with bad date | `date: 22-07-2026` | 302 Redirect back. Validation error: `date.date_format`. | — | ⬜ |
| PPT_REC_TC_010 | Upload empty CSV file | — | 1. POST with CSV containing only headers | `file: empty.csv` (headers only) | 500 Error. `RuntimeException`: `"No data rows found in CSV: {path}"` | — | ⬜ |

### 2.2 CSV Parsing — Header Aliases

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REC_TC_011 | Parse Razorpay format CSV | Gateway exists | 1. POST with Razorpay-format CSV | Headers: `payment_id,order_id,date,amount,fee,net_amount` | CSV parsed correctly. All 6 fields mapped. Reconciliation runs successfully. | — | ⬜ |
| PPT_REC_TC_012 | Parse generic format CSV with aliases | Gateway exists | 1. POST with aliased headers | Headers: `txn_id,merchant_order_id,transaction date,gross_amount,processing_fee,settled amount` | CSV parsed correctly via header alias mapping. All fields recognized. | — | ⬜ |
| PPT_REC_TC_013 | Parse CSV with unknown headers (fallback positional) | Gateway exists | 1. POST with unrecognized headers | Headers: `colA,colB,colC,colD,colE,colF` | Fallback positional mapping used: col0=amount, col1=fee, col2=net_amount, col3=gateway_payment_id, col4=gateway_order_id, col5=transaction_date. | — | ⬜ |
| PPT_REC_TC_014 | Parse CSV with malformed rows (fewer columns) | Gateway exists, 1 good row + 1 malformed | 1. POST with mixed quality CSV | Row 1: complete, Row 2: only 3 fields | Malformed row skipped. Only 1 row processed. | — | ⬜ |
| PPT_REC_TC_015 | Parse CSV where net_amount is auto-calculated | CSV has amount and fee but no net_amount | 1. POST with CSV missing net_amount column | Headers without net_amount, data rows with amount=100, fee=2 | net_amount auto-calculated: `round(100 - 2, 2) = 98.00` | — | ⬜ |

### 2.3 Payment Matching

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REC_TC_016 | Match payment by gateway_payment_id | Payment exists with matching gateway_payment_id | 1. Upload CSV with that gateway_payment_id | CSV: `gateway_payment_id: "pay_ABC123"` | Line matched. matched_payment_id set. | — | ⬜ |
| PPT_REC_TC_017 | Match payment by gateway_order_id when gateway_payment_id is null | Payment exists with matching gateway_order_id | 1. Upload CSV with null gateway_payment_id but valid order_id | CSV: `gateway_payment_id: "", gateway_order_id: "order_DEF456"` | Line matched by order_id fallback. | — | ⬜ |
| PPT_REC_TC_018 | No match when both IDs are null/empty | — | 1. Upload CSV row with no payment_id or order_id | CSV: both gateway_payment_id and gateway_order_id empty | Line unmatchable. match_status=unmatched. | — | ⬜ |
| PPT_REC_TC_019 | No match when neither ID exists in payments | — | 1. Upload CSV with IDs not in database | CSV: non-existent gateway_payment_id and gateway_order_id | Line unmatched. | — | ⬜ |
| PPT_REC_TC_020 | Multiple CSV rows matching same payment | Payment exists, CSV has 2 rows with same gateway_payment_id | 1. Upload CSV with duplicate payment reference | 2 rows, same gateway_payment_id | Both lines created. Both reference same matched_payment_id. Status may be amount_mismatch on second (if amounts differ cumulatively... actually each matched independently to same payment). Both are matched individually. | — | ⬜ |

### 2.4 Reconciliation Calculation

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REC_TC_021 | Verify expected_amount calculation | 3 CSV rows with amounts [100, 200, 300] | 1. Upload and reconcile | amounts: 100, 200, 300 | expected_amount = 600.00 | — | ⬜ |
| PPT_REC_TC_022 | Verify settled_amount calculation | 2 matched rows with net_amounts [98, 198] | 1. Upload and reconcile | net_amounts: 98, 198 (matched) | settled_amount = 296.00 | — | ⬜ |
| PPT_REC_TC_023 | Verify discrepancy calculation (all matched) | All rows match, amounts equal | 1. Upload and reconcile | expected=1000, settled=1000 | discrepancy = 0.00. status=matched | — | ⬜ |
| PPT_REC_TC_024 | Verify discrepancy calculation (with mismatch) | 1 row amount mismatched | 1. Upload and reconcile | CSV amount=100, payment amount=90. Net=98 | discrepancy = expected - settled. status=discrepant. | — | ⬜ |
| PPT_REC_TC_025 | Verify bank_statement_json summary | 3 matched, 1 unmatched, 1 mismatch | 1. Upload and reconcile | 5 rows | bank_statement_json: `{total_rows:5, matched_rows:3, unmatched_rows:1, mismatch_rows:1}` | — | ⬜ |

### 2.5 Reconciliation Detail View

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REC_TC_026 | View reconciliation detail | Reconciliation exists with lines | 1. GET `/payment/reconciliation/{id}` | Existing recon ID | 200 OK. Summary stats displayed: total, matched, unmatched, mismatch. Lines table with match_status, gateway IDs, amounts. matched_payment linked. | — | ⬜ |
| PPT_REC_TC_027 | View non-existent reconciliation | — | 1. GET with invalid ID | ID: 9999 | 404 Not Found. | — | ⬜ |
| PPT_REC_TC_028 | View reconciliation without permission | User lacks `tenant.payment.reconciliation.view` | 1. GET | Valid recon ID | 403 Forbidden. Gate denies. | — | ⬜ |

### 2.6 Reconciliation List View

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REC_TC_029 | List all reconciliations | 5 reconciliations exist | 1. GET `/payment/reconciliation` | — | 200 OK. Paginated list with gateway, date, amounts, status. 20 per page. | — | ⬜ |
| PPT_REC_TC_030 | List reconciliations with no data | No reconciliations exist | 1. GET | — | 200 OK. Empty state displayed. | — | ⬜ |

### 2.7 Resolve Reconciliation

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REC_TC_031 | Resolve a reconciliation | Recon exists with status=matched or discrepant | 1. POST `/payment/reconciliation/{id}/resolve` | Valid recon ID | 302 Redirect. Flash: `"Reconciliation marked as resolved."`. Status=resolved. resolved_by=current user ID. | — | ⬜ |
| PPT_REC_TC_032 | Resolve without permission | User lacks `tenant.payment.reconciliation.resolve` | 1. POST | Valid recon ID | 403 Forbidden. Gate denies. | — | ⬜ |
| PPT_REC_TC_033 | Resolve non-existent reconciliation | — | 1. POST with invalid ID | ID: 9999 | 404 Not Found. | — | ⬜ |
| PPT_REC_TC_034 | Re-resolve an already-resolved reconciliation | Recon exists with status=resolved | 1. POST resolve again | Already resolved recon | 302 Redirect. status remains resolved. resolved_by overwritten with new user ID. No validation prevents this. | — | ⬜ |

### 2.8 Console Command

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REC_TC_035 | Run scheduled reconciliation with existing settlement file | Active gateway exists, settlement file at expected path | 1. Run `php artisan payment:reconcile-settlements --date=2026-07-22` | Settlement file at `storage/app/payment-settlements/razorpay/2026-07-22.csv` | Reconciliation created. Output: `"Reconciled [razorpay] on 2026-07-22: status=matched, discrepancy=0"`. | — | ⬜ |
| PPT_REC_TC_036 | Run reconciliation with missing settlement file | No file at expected path | 1. Run `php artisan payment:reconcile-settlements` | No file for yesterday | Output: `"No settlement file found for [razorpay] on {date}."`. No reconciliation created. | — | ⬜ |
| PPT_REC_TC_037 | Run reconciliation with `--dry-run` flag | Settlement file exists | 1. Run `php artisan payment:reconcile-settlements --dry-run --date=2026-07-22` | Valid file | Output: `"Reconciled [razorpay] on 2026-07-22: status=DRY-RUN, discrepancy=0"`. No rows inserted in DB. | — | ⬜ |
| PPT_REC_TC_038 | Run reconciliation for specific gateway with `--gateway=` | Multiple gateways exist | 1. Run `php artisan payment:reconcile-settlements --gateway=phonepe` | — | Only PhonePe gateway processed. Others skipped. | — | ⬜ |
| PPT_REC_TC_039 | Run reconciliation with no active gateways | All gateways inactive | 1. Run `php artisan payment:reconcile-settlements` | — | Output: `"No active payment gateways found for reconciliation."`. Exit code 0. | — | ⬜ |
| PPT_REC_TC_040 | Run reconciliation with CSV parse error | Settlement file exists but is corrupt | 1. Run `php artisan payment:reconcile-settlements` | Corrupt CSV | Output: `"Failed to reconcile [razorpay] on {date}: {error}"`. Other gateways continue processing. | — | ⬜ |

---

## 3. Negative Test Cases

| TC ID | Scenario | Expected Error |
|-------|----------|----------------|
| PPT_REC_TC_005 | Empty gateway_id | `gateway_id.required` |
| PPT_REC_TC_006 | Non-existent gateway_id | `gateway_id.exists` |
| PPT_REC_TC_007 | Wrong file type (PDF) | `file.mimes` |
| PPT_REC_TC_008 | File > 10MB | `file.max` |
| PPT_REC_TC_009 | Invalid date format | `date.date_format` |
| PPT_REC_TC_010 | Empty CSV (headers only) | `RuntimeException: No data rows found` |
| PPT_REC_TC_028 | View without permission | 403 Forbidden |
| PPT_REC_TC_032 | Resolve without permission | 403 Forbidden |
| PPT_REC_TC_033 | Resolve non-existent | 404 Not Found |
| PPT_REC_TC_027 | View non-existent | 404 Not Found |

---

## 4. Boundary Value Analysis

| Field | Boundary | Valid | Invalid |
|-------|----------|-------|---------|
| `file` | Max size = 10MB (10240 KB) | 10240 KB | 10241 KB |
| `date` | Format = Y-m-d | 2026-07-22 | 22-07-2026, 07/22/2026 |
| `amount` matching tolerance | ±0.01 | 450.01 vs 450.00 | 450.02 vs 450.00 |

---

## 5. CSV Parsing — Header Alias Coverage

| Internal Field | Number of Aliases | Aliases Tested |
|---|---|---|
| `gateway_payment_id` | 7 | `payment_id`, `gateway_payment_id`, `razorpay_payment_id`, `payment id`, `txn_id`, `transaction_id`, `transaction id` |
| `gateway_order_id` | 5 | `order_id`, `gateway_order_id`, `razorpay_order_id`, `order id`, `merchant_order_id` |
| `transaction_date` | 7 | `date`, `transaction_date`, `settlement_date`, `transaction date`, `settlement date`, `created_at`, `created` |
| `amount` | 6 | `amount`, `gross_amount`, `transaction_amount`, `txn_amount`, `payment_amount`, `total_amount` |
| `fee` | 7 | `fee`, `gateway_fee`, `processing_fee`, `commission`, `pg_fee`, `charges`, `fee_amount` |
| `net_amount` | 7 | `net_amount`, `net`, `settled_amount`, `credit`, `net amount`, `settled amount`, `deposit_amount` |

> **Note:** Header matching is case-insensitive (`strtolower` comparison).

---

## 6. State Transition Coverage

| Transition | Trigger | Valid |
|---|---|---|
| pending → matched | All lines match cleanly after reconcile() | ✓ |
| pending → discrepant | Any line unmatched or amount_mismatch | ✓ |
| matched → resolved | User clicks Resolve | ✓ |
| discrepant → resolved | User clicks Resolve | ✓ |
| resolved → resolved | User clicks Resolve again (no validation) | ✓ (allowed but overwrites) |
| matched → (any other) | No other transitions | Terminal |
| discrepant → (any other) | No other transitions | Terminal unless resolved |

---

## 7. Data Integrity Tests

| TC ID | Scenario | Verification |
|-------|----------|-------------|
| PPT_REC_INT_001 | Create reconciliation — verify FK to gateway | `gateway_id` references `ptm_payment_gateways.id` |
| PPT_REC_INT_002 | Create reconciliation lines — verify FK cascade | Delete reconciliation → lines deleted |
| PPT_REC_INT_003 | Matched line — verify FK to payment | `matched_payment_id` references `ptm_payment_payments.id` ON DELETE SET NULL |
| PPT_REC_INT_004 | Verify expected_amount, settled_amount, discrepancy precision | All stored as DECIMAL(12,2), no rounding errors |
| PPT_REC_INT_005 | Verify bank_statement_json is valid JSON | Stored in JSON column, retrievable as array |

---

## 8. Known Issues

| # | Issue ID | Description | Severity | Status |
|---|---|---|---|---|
| 1 | GAP-REC-003 | **No notification for discrepancies.** Auto-reconciliation discrepancies are only visible in UI — no email/alert to finance team. | Medium | Open |
| 2 | GAP-REC-004 | **No dry-run from UI.** `--dry-run` only available via console command. Manual CSV uploads always persist. | Low | Open |
| 3 | GAP-REC-007 | **No duplicate reconciliation check.** Same CSV (gateway_id + date) uploaded twice creates duplicate records. | Low | Open |
| 4 | GAP-REC-008 | **Resolve overwrites previous resolver.** Calling `resolve()` on an already-resolved reconciliation silently overwrites `resolved_by`. | Low | Open |
| 5 | GAP-REC-009 | **No settlement file download UI.** User must manually upload CSV — no integration with gateway APIs to auto-fetch settlements. | Low | Open |

---

## 9. Route Reference

| Method | URI | Name | Controller@Method | Auth |
|---|---|---|---|---|
| GET | `/payment/reconciliation` | `payment.reconciliation.index` | `PaymentReconciliationController@index` | `tenant.payment.reconciliation.viewAny` |
| GET | `/payment/reconciliation/{id}` | `payment.reconciliation.show` | `PaymentReconciliationController@show` | `tenant.payment.reconciliation.view` |
| POST | `/payment/reconciliation` | `payment.reconciliation.store` | `PaymentReconciliationController@store` | `tenant.payment.reconciliation.create` |
| POST | `/payment/reconciliation/{id}/resolve` | `payment.reconciliation.resolve` | `PaymentReconciliationController@resolve` | `tenant.payment.reconciliation.resolve` |

**Console Command:**

| Signature | Schedule | Description |
|---|---|---|
| `payment:reconcile-settlements {--date=} {--gateway=} {--dry-run}` | `dailyAt('03:00')` | Reconcile gateway settlement statements against recorded payments |

---

## 10. Execution Status

| TC ID | Tester | Date | Browser/Env | Actual Result | Status (Pass/Fail/Blocked) | Remarks |
|-------|--------|------|-------------|---------------|---------------------------|---------|
| All | — | — | — | — | ⬜ Not Run | — |

---

> **Document generated from source code analysis.**
> Total test cases: 40 (30 Functional + 5 Console/CLI + 5 Integrity)
