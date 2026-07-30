# Refund Management — Test Case List

| Attribute | Value |
|-----------|-------|
| **Module** | Payment |
| **Feature ID** | F5 |
| **Prefix** | `ppt_` |
| **Type** | Infrastructure / Service |
| **Version** | V1 — |
| **Status** | ⬜ Not Reviewed |
| **CR** | ◌ None |

---

## 1. Test Case Summary

| Total TC | Automated | Manual | Pass | Fail | Blocked | Not Run |
|----------|-----------|--------|------|------|---------|---------|
| 30 | 0 | 30 | 0 | 0 | 0 | 30 |

---

## 2. Test Case List

### 2.1 Initiate Refund — API Validation

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REF_TC_001 | Initiate refund with valid amount and reason | Payment exists with status=success, user has `tenant.payment.refund` permission | 1. POST `/api/v1/payments/{ulid}/refund` with valid body | `amount: 500.00`, `reason: "Student withdrawn"` | 201 Created. Response contains `refund.ulid`, `refund.amount: 500`, `refund.status: "pending"`, `refund.reason`. New row in `ptm_payment_refunds` with status=pending. | — | ⬜ |
| PPT_REF_TC_002 | Initiate refund with amount = 0.01 (minimum) | Same as above | 1. POST with amount=0.01 | `amount: 0.01`, `reason: "Test minimum refund"` | 201 Created. Refund created with amount 0.01. | — | ⬜ |
| PPT_REF_TC_003 | Initiate refund with amount = 0 (below minimum) | Same as above | 1. POST with amount=0 | `amount: 0`, `reason: "Test zero refund"` | 422 Unprocessable. Validation error: `amount.min` = `The amount must be at least 0.01`. | — | ⬜ |
| PPT_REF_TC_004 | Initiate refund with negative amount | Same as above | 1. POST with amount=-100 | `amount: -100`, `reason: "Test negative"` | 422 Unprocessable. Validation error: `amount.min`. | — | ⬜ |
| PPT_REF_TC_005 | Initiate refund with non-numeric amount | Same as above | 1. POST with amount="abc" | `amount: "abc"`, `reason: "Test non-numeric"` | 422 Unprocessable. Validation error: `amount.numeric`. | — | ⬜ |
| PPT_REF_TC_006 | Initiate refund with empty reason | Same as above | 1. POST with reason="" | `amount: 100`, `reason: ""` | 422 Unprocessable. Validation error: `reason.required`. | — | ⬜ |
| PPT_REF_TC_007 | Initiate refund with reason exceeding 500 chars | Same as above | 1. POST with reason=501 chars | `amount: 100`, `reason: "a" x 501` | 422 Unprocessable. Validation error: `reason.max`. | — | ⬜ |
| PPT_REF_TC_008 | Initiate refund with reason = 500 chars exactly | Same as above | 1. POST with reason=500 chars | `amount: 100`, `reason: "a" x 500` | 201 Created. Refund initiated successfully. | — | ⬜ |
| PPT_REF_TC_009 | Initiate refund with missing amount field | Same as above | 1. POST without amount field | `reason: "Missing amount"` | 422 Unprocessable. Validation error: `amount.required`. | — | ⬜ |
| PPT_REF_TC_010 | Initiate refund with missing reason field | Same as above | 1. POST without reason field | `amount: 100` | 422 Unprocessable. Validation error: `reason.required`. | — | ⬜ |

### 2.2 Initiate Refund — Authorization

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REF_TC_011 | Initiate refund without auth token | Payment exists | 1. POST without Authorization header | `amount: 100`, `reason: "Test"` | 401 Unauthorized or redirect to login. | — | ⬜ |
| PPT_REF_TC_012 | Initiate refund with invalid/expired token | Payment exists | 1. POST with invalid Bearer token | `amount: 100`, `reason: "Test"` | 401 Unauthorized. | — | ⬜ |
| PPT_REF_TC_013 | Initiate refund without permission | User authenticated but lacks `tenant.payment.refund` | 1. POST with valid auth but insufficient role | `amount: 100`, `reason: "Test"` | 403 Forbidden. Gate `tenant.payment.refund` denies access. | — | ⬜ |
| PPT_REF_TC_014 | Initiate refund for non-existent payment ULID | Authenticated user with permission | 1. POST with non-existent ULID | ULID: `"00000000000000000000000000"` | 404 Not Found. `PaymentService@getByUlid` throws ModelNotFoundException. | — | ⬜ |

### 2.3 Initiate Refund — Business Logic

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REF_TC_015 | Initiate refund for payment with status=initiated | Payment exists with status=initiated | 1. POST with valid amount/reason | `amount: 100`, `reason: "Test"` | 409 Conflict. Error: `"Cannot refund payment in status: initiated"`. | — | ⬜ |
| PPT_REF_TC_016 | Initiate refund for payment with status=pending | Payment exists with status=pending | 1. POST with valid amount/reason | `amount: 100`, `reason: "Test"` | 409 Conflict. Error: `"Cannot refund payment in status: pending"`. | — | ⬜ |
| PPT_REF_TC_017 | Initiate refund for payment with status=failed | Payment exists with status=failed | 1. POST with valid amount/reason | `amount: 100`, `reason: "Test"` | 409 Conflict. Error: `"Cannot refund payment in status: failed"`. | — | ⬜ |
| PPT_REF_TC_018 | Initiate refund for payment with status=cancelled | Payment exists with status=cancelled | 1. POST with valid amount/reason | `amount: 100`, `reason: "Test"` | 409 Conflict. Error: `"Cannot refund payment in status: cancelled"`. | — | ⬜ |
| PPT_REF_TC_019 | Initiate refund for payment with status=refunded | Payment exists with status=refunded | 1. POST with valid amount/reason | `amount: 100`, `reason: "Test"` | 409 Conflict. Error: `"Cannot refund payment in status: refunded"`. | — | ⬜ |
| PPT_REF_TC_020 | Initiate refund exceeding payment amount | Payment exists: amount=500, status=success, no prior refunds | 1. POST with amount=600 | `amount: 600`, `reason: "Exceeding"` | 409 Conflict. Error: `"Refund amount (600) exceeds max refundable amount (500)"`. | — | ⬜ |
| PPT_REF_TC_021 | Initiate refund exceeding remaining refundable (partial refund exists) | Payment: amount=1000, status=success, 1 existing refund of 300 (success) | 1. POST with amount=800 | `amount: 800`, `reason: "Exceeds remaining"` | 409 Conflict. Error: `"Refund amount (800) exceeds max refundable amount (700)"`. | — | ⬜ |
| PPT_REF_TC_022 | Initiate partial refund (less than full amount) | Payment: amount=1000, status=success, no prior refunds | 1. POST with amount=400 | `amount: 400`, `reason: "Partial refund"` | 201 Created. Refund with amount=400, status=pending. Payment status remains `success`. | — | ⬜ |
| PPT_REF_TC_023 | Initiate full refund (equal to payment amount) | Payment: amount=1000, status=success, no prior refunds | 1. POST with amount=1000 | `amount: 1000`, `reason: "Full refund"` | 201 Created. Refund with amount=1000, status=pending. After webhook confirmation, payment status changes to `refunded`. | — | ⬜ |
| PPT_REF_TC_024 | Concurrent refund initiation (race condition) | Payment: amount=1000, status=success, no prior refunds | 1. Send 2 simultaneous POST requests with amount=600 each | Both: `amount: 600`, `reason: "Concurrent"` | Exactly one refund succeeds (600). Second request gets 409: `"Refund amount (600) exceeds max refundable amount (400)"`. | — | ⬜ |

### 2.4 List Refunds

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REF_TC_025 | List refunds for payment (no refunds) | Payment exists, no refunds | 1. GET `/api/v1/payments/{ulid}/refunds` | — | 200 OK. Empty array `[]`. | — | ⬜ |
| PPT_REF_TC_026 | List refunds for payment (multiple refunds) | Payment exists with 2 refunds | 1. GET `/api/v1/payments/{ulid}/refunds` | — | 200 OK. Array of 2 refund objects, ordered by latest first. | — | ⬜ |
| PPT_REF_TC_027 | List refunds for non-existent payment | No payment with given ULID | 1. GET with non-existent ULID | ULID: `"00000000000000000000000000"` | 404 Not Found. | — | ⬜ |

### 2.5 Backend Refund List

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REF_TC_028 | Backend refund list loads with pagination | Multiple refunds exist across payments | 1. GET `/refunds` | — | 200 OK. View renders refunds table with 20 per page, pagination links. Each row shows payment gateway info. | — | ⬜ |
| PPT_REF_TC_029 | Backend refund list with no data | No refunds exist | 1. GET `/refunds` | — | 200 OK. View renders empty state message. | — | ⬜ |
| PPT_REF_TC_030 | Backend refund list — authorization check | User without `viewAny` on PaymentRefund | 1. GET `/refunds` | — | 403 Forbidden. | — | ⬜ |

### 2.6 Webhook-Driven Refund Success

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REF_TC_031 | Razorpay refund.processed webhook marks refund as success | Refund exists with gateway_refund_id, status=processing | 1. POST `/payment/webhooks/razorpay` with refund.processed payload containing matching gateway_refund_id | Webhook payload with `event: "refund.processed"`, proper `refund.entity.id` | Refund status updated to `success`, `refunded_at` set. Payment marked `refunded` if fully refunded. Audit log `refund.succeeded` created. RefundSucceeded event dispatched. | — | ⬜ |
| PPT_REF_TC_032 | Razorpay refund.processed with unknown gateway_refund_id | No local refund with that ID | 1. POST webhook with non-matching refund.id | Webhook with refund_id that doesn't exist locally | Webhook processed but no-op (no matching refund found). No error thrown. | — | ⬜ |
| PPT_REF_TC_033 | Full refund updates payment status to refunded | Payment: amount=500, 1 existing refund of 300 (success) | 1. Initiate second refund of 200 | `amount: 200` | After webhook confirms refund, total refunded = 500 >= 500. Payment status changes from `success` to `refunded`. | — | ⬜ |

### 2.7 RefundSucceededListener — Fee Integration

| TC ID | Test Scenario | Prerequisites | Test Steps | Test Data | Expected Result | Actual Result | Status |
|-------|---------------|---------------|------------|-----------|-----------------|---------------|--------|
| PPT_REF_TC_034 | RefundSucceededListener records FeeRefund and marks transaction refunded | Payment payable is FeeInvoice, FeeTransaction exists with matching gateway_payment_id | 1. Webhook confirms refund (markRefundSuccess) | Refund for fee invoice payment | RefundSucceededListener finds FeeTransaction, calls FeeInvoiceService@recordRefund, calls transaction->markRefunded(). Audit log `refund.ledger_updated` created. | — | ⬜ |
| PPT_REF_TC_035 | RefundSucceededListener skips non-FeeInvoice payable | Payment payable is MealCard (not FeeInvoice) | 1. Webhook confirms refund | Refund for non-fee payment | Listener returns early (no-op). No FeeTransaction lookup attempted. | — | ⬜ |
| PPT_REF_TC_036 | RefundSucceededListener skips when FeeTransaction not found | Payment payable is FeeInvoice, but no matching FeeTransaction | 1. Webhook confirms refund | Refund for fee invoice but tx not found | Listener returns early. No fatal error. | — | ⬜ |

---

## 3. Negative Test Cases

| TC ID | Scenario | Expected Error |
|-------|----------|----------------|
| PPT_REF_TC_003 | amount = 0 | `amount.min` |
| PPT_REF_TC_004 | amount = -100 | `amount.min` |
| PPT_REF_TC_005 | amount = "abc" | `amount.numeric` |
| PPT_REF_TC_006 | reason = "" | `reason.required` |
| PPT_REF_TC_007 | reason > 500 chars | `reason.max` |
| PPT_REF_TC_015 | Payment status = initiated | `"Cannot refund payment in status: initiated"` |
| PPT_REF_TC_016 | Payment status = pending | `"Cannot refund payment in status: pending"` |
| PPT_REF_TC_017 | Payment status = failed | `"Cannot refund payment in status: failed"` |
| PPT_REF_TC_018 | Payment status = cancelled | `"Cannot refund payment in status: cancelled"` |
| PPT_REF_TC_019 | Payment status = refunded | `"Cannot refund payment in status: refunded"` |
| PPT_REF_TC_020 | Amount > payment amount | `"exceeds max refundable amount"` |
| PPT_REF_TC_021 | Amount > remaining refundable | `"exceeds max refundable amount"` |
| PPT_REF_TC_024 | Concurrent excessive refund | `"exceeds max refundable amount"` |
| PPT_REF_TC_030 | Backend without permission | 403 Forbidden |

---

## 4. Boundary Value Analysis

| Field | Boundary | Valid | Invalid |
|-------|----------|-------|---------|
| `amount` | Min = 0.01 | 0.01 | 0, -0.01 |
| `amount` | Max = payment.amount | payment.amount | payment.amount + 0.01 |
| `amount` | Remaining refundable | maxRefundable | maxRefundable + 0.01 |
| `reason` | Max length = 500 | 500 chars | 501 chars |

---

## 5. State Transition Coverage

| Transition | Trigger | Valid |
|---|---|---|
| success → refunded | Total refunded >= payment.amount | ✓ |
| refund pending → processing | Gateway refund API called | ✓ |
| refund processing → success | Webhook confirms refund | ✓ |
| refund processing → failed | Webhook/gateway reports failure | ✓ |
| refund success → (any) | Terminal state | ✗ |
| refund failed → (any) | Terminal state | ✗ |

---

## 6. Data Integrity Tests

| TC ID | Scenario | Verification |
|-------|----------|-------------|
| PPT_REF_TC_INT_001 | Create refund — verify `ulid` is unique | Query `ptm_payment_refunds` by ulid — exactly 1 row |
| PPT_REF_TC_INT_002 | Create 2 refunds for same payment — verify `payment_id` FK | Both rows reference same payment_id |
| PPT_REF_TC_INT_003 | Create refund — verify `amount` decimal precision | Stored as DECIMAL(12,2), no rounding loss |
| PPT_REF_TC_INT_004 | Delete payment (cascade) — verify refunds also deleted | `payment_id` ON DELETE CASCADE |
| PPT_REF_TC_INT_005 | Gateway refund ID unique constraint | Second refund with same `gateway_refund_id` fails |

---

## 7. Permission / Authorization Matrix

| Action | Gate/Permission | Applied At |
|---|---|---|
| Initiate refund (API) | `tenant.payment.refund` | `InitiateRefundRequest@authorize` + `PaymentPolicy@refund` |
| List refunds for payment (API) | `tenant.payment.refund` | `PaymentPolicy@refund` |
| View all refunds (Backend) | `viewAny` on `PaymentRefund` | `Backend\RefundController@index` |

> ⚠️ **Note:** No explicit policy registered for `PaymentRefund` model. `viewAny` on `PaymentRefund` may fall through to default behavior.

---

## 8. Known Issues

| # | Issue ID | Description | Severity | Status |
|---|---|---|---|---|
| 1 | GAP-REF-001 | **Offline gateway refunds never complete.** `RefundService@initiate()` sets status=processing regardless of gateway. OfflineGateway returns sync success, but status stays processing forever — no webhook will confirm it. | Medium | Open |
| 2 | GAP-REF-002 | **No PaymentRefund policy registered.** Backend `viewAny` authorization on `PaymentRefund` has no explicit policy in `PaymentServiceProvider`. | Low | Open |
| 3 | GAP-REF-004 | **No idempotency key on refund API.** Retry of same refund request after timeout creates duplicate refund records. | Low | Open |
| 4 | GAP-REF-005 | **No `partially_refunded` payment status.** Partial refunds leave payment in `success` state with no visual indicator. | Low | Open |
| 5 | GAP-REF-006 | **No notification on refund events.** Refund success/failure does not trigger email/SMS/push. | Low | Open |
| 6 | GAP-REF-007 | **No retry/cancel for stuck processing refunds.** No endpoint to retry a failed refund or cancel a stuck one. | Low | Open |

---

## 9. Route Reference

| Method | URI | Name | Controller@Method | Auth |
|---|---|---|---|---|
| POST | `/api/v1/payments/{ulid}/refund` | `payment.refund.store` | `RefundController@store` | Sanctum + `tenant.payment.refund` |
| GET | `/api/v1/payments/{ulid}/refunds` | `payment.refund.index` | `RefundController@index` | Sanctum + `tenant.payment.refund` |
| GET | `/refunds` | `payment.backend.refunds.index` | `Backend\RefundController@index` | Session + `viewAny` on PaymentRefund |

---

## 10. Execution Status

| TC ID | Tester | Date | Browser/Env | Actual Result | Status (Pass/Fail/Blocked) | Remarks |
|-------|--------|------|-------------|---------------|---------------------------|---------|
| All | — | — | — | — | ⬜ Not Run | — |

---

> **Document generated from source code analysis.**
> Total test cases: 36 (30 Functional + 4 Integrity + 2 Note)
