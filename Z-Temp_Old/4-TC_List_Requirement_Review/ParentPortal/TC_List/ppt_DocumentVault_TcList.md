# ParentPortal — Document Vault & Requests (TC List)

## 1. Feature Overview

| Attribute | Details |
|-----------|---------|
| Feature | Document Vault & Requests |
| Module | ParentPortal (PPT) |
| Priority | P1 |
| Type | Write (Form submission + Payment + Download) |
| Test Strategy | Functional + Validation + Security + Payment Integration |

## 2. Test Environment

| Parameter | Value |
|-----------|-------|
| Base URL | `{tenant_url}/parent-portal/documents` |
| Auth Required | Yes (Parent role) |
| Child Context | Active child must be selected |
| Database | Tenant database with ppt_document_requests table |
| Payment Gateway | Razorpay test mode |

## 3. Test Case Matrix

### 3.1 UI / Screen Navigation

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-DOC-001 | Verify Document Vault page loads with tabbed view | 1. Login as Parent<br>2. Navigate to Documents | Page shows two sections: Vault (report cards) and Requests (request history) | ⬜ | ◌ |
| TC-PPT-DOC-002 | Verify document request list shows created requests | 1. Submit a document request<br>2. Navigate to Documents index | The submitted request appears in the list sorted by newest first | ⬜ | ◌ |
| TC-PPT-DOC-003 | Verify empty state when no documents or requests exist | 1. Login as Parent with no document requests<br>2. Navigate to Documents | Empty state message shown; no errors | ⬜ | ◌ |
| TC-PPT-DOC-004 | Verify "Request Document" button/link navigates to create form | 1. On Documents index<br>2. Click Request Document | Navigated to document create form | ⬜ | ◌ |
| TC-PPT-DOC-005 | Verify create form displays all 7 document types in dropdown | 1. Navigate to create form<br>2. Examine document type dropdown | All 7 types present: TC, MarkSheet, Bonafide, Character, Migration, MedicalFitness, Other | ⬜ | ◌ |
| TC-PPT-DOC-006 | Verify request show page renders with full details | 1. Click on a request in the list<br>2. View request details | Request number, type, reason, status, timeline visible | ⬜ | ◌ |
| TC-PPT-DOC-007 | Verify download link visible only for Ready/Completed requests | 1. Create request with fee_required=0 and status=Completed<br>2. View request show page | Download link/button visible | ⬜ | ◌ |
| TC-PPT-DOC-008 | Verify download link hidden for Pending/Processing/Rejected/Withdrawn requests | 1. Create request in each non-downloadable status<br>2. View each | Download link hidden or disabled | ⬜ | ◌ |
| TC-PPT-DOC-009 | Verify Pay Now button visible only for Ready status with fee_required > 0 | 1. Create request with Ready status and fee_required > 0<br>2. View request | Pay Now button visible | ⬜ | ◌ |

### 3.2 Create Document Request (Validation)

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-DOC-010 | Submit valid document request with all required fields | 1. Fill all required fields correctly<br>2. Submit | Request created; redirected to index with success message showing request number | ⬜ | ◌ |
| TC-PPT-DOC-011 | Submit with document_type empty | 1. Leave document_type blank<br>2. Submit | Validation error for document_type | ⬜ | ◌ |
| TC-PPT-DOC-012 | Submit with document_type as invalid value | 1. Select invalid document_type<br>2. Submit | Validation error; form not submitted | ⬜ | ◌ |
| TC-PPT-DOC-013 | Submit with reason less than 20 characters | 1. Enter reason with 10 chars<br>2. Submit | Validation error: reason must be at least 20 characters | ⬜ | ◌ |
| TC-PPT-DOC-014 | Submit with reason at exactly 20 characters boundary | 1. Enter reason with exactly 20 chars<br>2. Submit | Validation passes; request created | ⬜ | ◌ |
| TC-PPT-DOC-015 | Submit with reason exceeding 2000 characters | 1. Enter reason with 2001 chars<br>2. Submit | Validation error: reason too long | ⬜ | ◌ |
| TC-PPT-DOC-016 | Submit with reason empty | 1. Leave reason blank<br>2. Submit | Validation error: reason required | ⬜ | ◌ |
| TC-PPT-DOC-017 | Submit with urgency empty | 1. Leave urgency unselected<br>2. Submit | Validation error for urgency | ⬜ | ◌ |
| TC-PPT-DOC-018 | Submit with urgency = Normal | 1. Select Normal urgency<br>2. Submit | Request created with Normal urgency | ⬜ | ◌ |
| TC-PPT-DOC-019 | Submit with urgency = Urgent | 1. Select Urgent urgency<br>2. Submit | Request created with Urgent urgency | ⬜ | ◌ |
| TC-PPT-DOC-020 | Verify request_number format after creation | 1. Create a request<br>2. Check request_number in response | Format: `PPT-DR-{YYYY}-{XXXXXXXX}` (e.g., PPT-DR-2026-00000001) | ⬜ | ◌ |
| TC-PPT-DOC-021 | Verify request_number increments sequentially | 1. Create two requests<br>2. Compare request_numbers | Second has next sequence number | ⬜ | ◌ |
| TC-PPT-DOC-022 | Verify guardian_id auto-assigned from authenticated user | 1. Create request<br>2. Check DB record | guardian_id matches parent's guardian record | ⬜ | ◌ |
| TC-PPT-DOC-023 | Verify student_id matches active child | 1. Set child A as active<br>2. Create request<br>3. Check DB | student_id = active child's ID | ⬜ | ◌ |
| TC-PPT-DOC-024 | Verify fee_required defaults to 0.00 | 1. Create request<br>2. Check DB | fee_required = 0.00 | ⬜ | ◌ |

### 3.3 Withdraw Request

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-DOC-025 | Withdraw a Pending request | 1. Create request (Pending status)<br>2. Click Withdraw | Request withdrawn; success message; is_active=false; soft-deleted | ⬜ | ◌ |
| TC-PPT-DOC-026 | Withdraw a Processing request | 1. Status changed to Processing<br>2. Click Withdraw | Error: "This request can no longer be withdrawn." (422) | ⬜ | ◌ |
| TC-PPT-DOC-027 | Withdraw a Completed request | 1. Status changed to Completed<br>2. Click Withdraw | Error: "This request can no longer be withdrawn." (422) | ⬜ | ◌ |
| TC-PPT-DOC-028 | Withdraw a Rejected request | 1. Status changed to Rejected<br>2. Click Withdraw | Error: "This request can no longer be withdrawn." (422) | ⬜ | ◌ |
| TC-PPT-DOC-029 | Withdraw a Ready request | 1. Status = Ready<br>2. Click Withdraw | Error: "This request can no longer be withdrawn." (422) | ⬜ | ◌ |
| TC-PPT-DOC-030 | Verify withdraw button hidden for non-Pending statuses | 1. View request in Processing/Completed/Rejected state | Withdraw button not rendered | ⬜ | ◌ |
| TC-PPT-DOC-031 | Withdraw another parent's request (IDOR attempt) | 1. Attempt to withdraw request belonging to different parent's child | 403 Forbidden | ⬜ | ◌ |

### 3.4 Payment Flow

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-DOC-032 | Confirm Pay Now initiates Razorpay payment | 1. Pay Initiate for Ready request with fee > 0<br>2. Verify response | JSON response with checkout data + payment_ulid | ⬜ | ◌ |
| TC-PPT-DOC-033 | Pay initiate when fee_required = 0 (no payment needed) | 1. Try payInitiate on request with fee = 0 | 422: "No payment required for this request." | ⬜ | ◌ |
| TC-PPT-DOC-034 | Payment callback with valid Razorpay signature | 1. Submit valid payment details + signature<br>2. Callback | fee_paid = true; payment_reference saved; success response | ⬜ | ◌ |
| TC-PPT-DOC-035 | Payment callback with invalid Razorpay signature | 1. Submit invalid signature<br>2. Callback | 422: "Payment signature verification failed." | ⬜ | ◌ |
| TC-PPT-DOC-036 | Payment callback after fee already paid | 1. Mark fee_paid = true<br>2. Submit callback again | 422: "Fee already paid." | ⬜ | ◌ |
| TC-PPT-DOC-037 | Payment callback for request belonging to different child | 1. Attempt callback on request from different child | 403 Forbidden | ⬜ | ◌ |
| TC-PPT-DOC-038 | Verify payment_reference uniqueness (idempotency) | 1. Process payment successfully<br>2. Attempt same payment_id via different path | DB unique constraint prevents duplicate; operation fails gracefully | ⬜ | ◌ |
| TC-PPT-DOC-039 | Pay Initiate with missing payment_ulid | 1. Submit empty payment_ulid<br>2. Pay Initiate endpoint | Validation error | ⬜ | ◌ |

### 3.5 Download Fulfilled Document

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-DOC-040 | Download document when status is Completed and fee paid | 1. Ensure status = Completed, fee_paid = true<br>2. Click Download | File download initiated; status stays Completed | ⬜ | ◌ |
| TC-PPT-DOC-041 | Download document when status is Ready and fee paid | 1. Status = Ready, fee_paid = true<br>2. Download | File download; status transitions to Completed; fulfilled_at set | ⬜ | ◌ |
| TC-PPT-DOC-042 | Download when status is Ready but fee not paid | 1. Status = Ready, fee_required > 0, fee_paid = false<br>2. Download | 422: "Document is not yet available for download." | ⬜ | ◌ |
| TC-PPT-DOC-043 | Download when status is Pending | 1. Status = Pending<br>2. Download | 422: "Document is not yet available for download." | ⬜ | ◌ |
| TC-PPT-DOC-044 | Download when fulfilled_media_id is null | 1. Set fulfilled_media_id = null<br>2. Download | 404: "Fulfilled document not found." | ⬜ | ◌ |
| TC-PPT-DOC-045 | Download when media record deleted from sys_media | 1. Delete the media record<br>2. Download | 404: "Fulfilled document not found." | ⬜ | ◌ |
| TC-PPT-DOC-046 | Download another parent's request (IDOR attempt) | 1. Attempt download on request from different child | 403 Forbidden | ⬜ | ◌ |
| TC-PPT-DOC-047 | Verify file downloaded is the correct uploaded document | 1. Upload a test document by admin<br>2. Parent downloads | File name and content match what was uploaded | ⬜ | ◌ |

### 3.6 Security Tests

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-DOC-048 | Access documents page without authentication | 1. Logout<br>2. Navigate to documents index | Redirected to login | ⬜ | ◌ |
| TC-PPT-DOC-049 | Access document create form without authentication | 1. Logout<br>2. Navigate to create form | Redirected to login | ⬜ | ◌ |
| TC-PPT-DOC-050 | POST to store without CSRF token | 1. Submit form without CSRF token | 419 CSRF mismatch | ⬜ | ◌ |
| TC-PPT-DOC-051 | IDOR: Access another child's request by ID | 1. Switch child<br>2. Access request number from previous child | 403 Forbidden via abort_unless check | ⬜ | ◌ |
| TC-PPT-DOC-052 | IDOR: Pay another child's request | 1. Attempt payInitiate on request from different child | 403 Forbidden | ⬜ | ◌ |
| TC-PPT-DOC-053 | Authenticated but no active child session | 1. Create parent without active child<br>2. Access documents | 403 or redirect to no-access screen | ⬜ | ◌ |

### 3.7 Audit Logging

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-DOC-054 | Verify audit log on view document index | 1. Access documents index<br>2. Check sys_activity_logs | "Viewed" event logged with student context | ⬜ | ◌ |
| TC-PPT-DOC-055 | Verify audit log on create request | 1. Submit valid request<br>2. Check activity logs | "Requested" event logged | ⬜ | ◌ |
| TC-PPT-DOC-056 | Verify audit log on withdraw | 1. Withdraw Pending request<br>2. Check logs | "Withdrawn" event logged | ⬜ | ◌ |
| TC-PPT-DOC-057 | Verify audit log on payment initiation | 1. Initiate payment<br>2. Check logs | "PaymentInitiated" event logged | ⬜ | ◌ |
| TC-PPT-DOC-058 | Verify audit log on payment callback | 1. Complete payment<br>2. Check logs | "Paid" event logged | ⬜ | ◌ |
| TC-PPT-DOC-059 | Verify audit log on download | 1. Download fulfilled document<br>2. Check logs | "Downloaded" event logged | ⬜ | ◌ |

## 4. API Contract (JSON Responses)

### Pay Initiate — Success Response (200)
```json
{
    "success": true,
    "payment_ulid": "01J8XYZ...",
    "checkout": { "razorpay_order_id": "order_...", "amount": 5000, ... }
}
```

### Pay Initiate — Failure Response (422)
```json
{
    "success": false,
    "error": "No payment required for this request."
}
```

### Pay Callback — Success Response (200)
```json
{
    "success": true,
    "new_status": "Ready"
}
```

### Pay Callback — Failure Response (422)
```json
{
    "success": false,
    "message": "Payment signature verification failed."
}
```

## 5. Test Data Setup

| Entity | Required Records |
|--------|-----------------|
| Student | At least 2 students linked to the test parent |
| Guardian | Guardian record linked to auth user |
| Document Request | Create requests in each status: Pending, Processing, Ready, Completed, Rejected |
| Media | Upload at least one test document via spatie media library |
| Payment | Configure Razorpay test keys in .env |

## 6. Database Assertions

| Assertion | Query / Check |
|-----------|--------------|
| Request created | `SELECT * FROM ppt_document_requests WHERE request_number = ?` |
| Request withdrawn | `is_active = 0` and `deleted_at IS NOT NULL` |
| Request soft-deleted | `SELECT * FROM ppt_document_requests WHERE id = ?` returns null (with active scope) |
| Fee paid | `fee_paid = 1`, `payment_reference IS NOT NULL` |
| Payment idempotency | Attempt inserting same payment_reference → unique constraint violation |
| Status transition | `status` column updated correctly on each action |

## 7. Browser / Device Compatibility

| Platform | Support |
|----------|---------|
| Chrome (Desktop) | ✅ |
| Firefox (Desktop) | ✅ |
| Chrome (Android) | ✅ |
| Safari (iOS) | ✅ |
| PWA mode | ✅ |

## 8. Known Issues

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | No signed URL with 24-hour expiry — uses direct `response()->download()` | Medium | ⬜ |
| 2 | No notification dispatch to parent on status change | Medium | ⬜ |
| 3 | Fee amount always defaults to 0.00 on store; admin must manually update | Low | ⬜ |
| 4 | HPC report cards shown in vault but they belong to HPC module conceptually | Low | ⬜ |
| 5 | Payable contract implemented but no test to verify idempotency guard | Medium | ⬜ |

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/parent-portal/documents` | `documents.index` | `index` |
| GET | `/parent-portal/documents/create` | `documents.create` | `create` |
| POST | `/parent-portal/documents` | `documents.store` | `store` |
| GET | `/parent-portal/documents/{documentRequest}` | `documents.show` | `show` |
| POST | `/parent-portal/documents/{documentRequest}/withdraw` | `documents.withdraw` | `withdraw` |
| POST | `/parent-portal/documents/{documentRequest}/pay/initiate` | `documents.pay.initiate` | `payInitiate` |
| POST | `/parent-portal/documents/{documentRequest}/pay/callback` | `documents.pay.callback` | `payCallback` |
| GET | `/parent-portal/documents/{documentRequest}/download` | `documents.download` | `download` |

## 10. Execution Status

| TC Count | Automated | Manual | Pass | Fail | Blocked | Not Run |
|----------|-----------|--------|------|------|---------|---------|
| 59 | 0 | 0 | 0 | 0 | 0 | 59 |
