# Parent Portal — Leave Application: Test Case List

## 1. Module Information

| Field | Value |
|-------|-------|
| Module | ParentPortal |
| Feature | Leave Application |
| Controller | ParentLeaveController |
| Routes | 7 routes (index, create, store, show, respond, message, withdraw) |
| Priority | P1 — Standard |
| FRD Source | REQ-PPT-010 |

---

## 2. Assumptions & Prerequisites

- Parent is authenticated with a valid Sanctum session
- Active child is resolved and linked to the parent (can_access_parent_portal = 1)
- Active child has a current academic session (class_section_id available)
- `std_leave_types` table has at least one active leave type record
- `std_leave_applications` table and its related tables exist
- LeaveService is functional (StudentProfile module)
- Document upload uses a writable filesystem (local or S3)

---

## 3. Test Case Summary

| Test Suite | Total TC | V1 | V2 | CR | Status |
|------------|----------|----|----|----|--------|
| UI / View / Screen | 6 | — | — | ◌ | ⬜ |
| Validation (Field-Level) | 12 | — | — | ◌ | ⬜ |
| Positive / Functional | 8 | — | — | ◌ | ⬜ |
| Negative / Error | 7 | — | — | ◌ | ⬜ |
| Security / Access Control | 4 | — | — | ◌ | ⬜ |
| Business Rules (BR) | 3 | — | — | ◌ | ⬜ |
| Integration / API | 4 | — | — | ◌ | ⬜ |
| Performance / Load | 0 | — | — | ◌ | ⬜ |
| Edge Case / Boundary | 5 | — | — | ◌ | ⬜ |
| **Total** | **49** | — | — | 0 | ⬜ |

---

## 4. Detailed Test Cases

### 4.1 UI / View / Screen Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-LV-UI-01 | Leave list page renders with tabs | Active child exists; at least one leave application exists | GET /parent-portal/leave | Page loads with tab bar (All/Pending/Approved/Rejected/Cancelled) and applications list sorted by from_date DESC | — | ◌ | ⬜ |
| TC-LV-UI-02 | Status count badges display correctly | Various leave statuses exist for child | Navigate to leave list | Each tab shows correct count matching status filter | — | ◌ | ⬜ |
| TC-LV-UI-03 | Create leave form renders all fields | Active child with session; leave types exist | GET /parent-portal/leave/create | Form shows from_date, to_date, leave_type dropdown, reason textarea, half_day toggle, document upload | — | ◌ | ⬜ |
| TC-LV-UI-04 | No-session view for child without active session | Active child has no current academic session | GET /parent-portal/leave/create | no-session view rendered instead of create form | — | ◌ | ⬜ |
| TC-LV-UI-05 | Leave detail shows remark thread | Leave with remarks exists | GET /parent-portal/leave/{leave} | Remark thread displayed with teacher/parent messages ordered by created_at | — | ◌ | ⬜ |
| TC-LV-UI-06 | Action buttons visibility based on status | Leave in various statuses | Click through each status | Withdraw visible for cancellable; respond visible for info/doc requested; comment visible for non-terminal | — | ◌ | ⬜ |

### 4.2 Validation (Field-Level) Tests

| TC ID | Test Case | Precondition | Input | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-LV-VL-01 | from_date is required | — | from_date empty | Validation error: "The from date field is required." | — | ◌ | ⬜ |
| TC-LV-VL-02 | from_date must be after today | Today = 2026-06-29 | from_date = 2026-06-29 | Validation error: after:today rule violation | — | ◌ | ⬜ |
| TC-LV-VL-03 | from_date must be future | Today = 2026-06-29 | from_date = 2026-06-28 | Validation error: past date rejected | — | ◌ | ⬜ |
| TC-LV-VL-04 | from_date boundary (tomorrow) | Today = 2026-06-29 | from_date = 2026-06-30 | Validation passes | — | ◌ | ⬜ |
| TC-LV-VL-05 | to_date must be >= from_date | from_date = 2026-07-05 | to_date = 2026-07-03 | Validation error: after_or_equal:from_date violation | — | ◌ | ⬜ |
| TC-LV-VL-06 | to_date same as from_date (single day) | from_date = 2026-07-05 | to_date = 2026-07-05 | Validation passes | — | ◌ | ⬜ |
| TC-LV-VL-07 | leave_type_id required | — | leave_type_id empty | Validation error | — | ◌ | ⬜ |
| TC-LV-VL-08 | leave_type_id must be active | Inactive/deleted type ID | leave_type_id = inactive_id | exists rule with where clause fails | — | ◌ | ⬜ |
| TC-LV-VL-09 | reason required | — | reason empty | Validation error | — | ◌ | ⬜ |
| TC-LV-VL-10 | document max 5 MB | File = 6 MB | Upload 6 MB file | Validation error: max:5120 | — | ◌ | ⬜ |
| TC-LV-VL-11 | document mimes only pdf/jpg/jpeg/png | File = .docx | Upload docx | Validation error: invalid mime type | — | ◌ | ⬜ |
| TC-LV-VL-12 | document_name required_with document | File present | document_name empty | Validation error: required_with | — | ◌ | ⬜ |

### 4.3 Positive / Functional Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-LV-PF-01 | Submit leave successfully (no document) | Active child, leave types exist | Fill valid dates, type, reason; submit | Leave created with status=Submitted; redirect to list with success message | — | ◌ | ⬜ |
| TC-LV-PF-02 | Submit leave with document | Valid file ready | Fill form, upload valid PDF/JPG/PNG | Leave created; document attached; no validation errors | — | ◌ | ⬜ |
| TC-LV-PF-03 | Submit half-day leave | is_half_day = true | Select half_day_slot = Morning | Leave created with half-day flag | — | ◌ | ⬜ |
| TC-LV-PF-04 | View leave list filtered by tab | Leaves with various statuses | Click each tab | Filter works correctly; only matching statuses shown | — | ◌ | ⬜ |
| TC-LV-PF-05 | View single leave with remarks | Leave with remarks | Open leave detail | All remarks loaded (remarkedBy, parentRemark, responseDocuments) | — | ◌ | ⬜ |
| TC-LV-PF-06 | Parent responds to info request | Leave in Info Requested | Post message in respond | Remark resolved; leave returns to Under Review | — | ◌ | ⬜ |
| TC-LV-PF-07 | Parent responds to doc request | Leave in Doc Requested | Upload file in respond | Remark resolved; leave returns to Under Review | — | ◌ | ⬜ |
| TC-LV-PF-08 | Parent posts free-form comment | Leave in Submitted status | Type comment with optional file | Comment added to remark thread | — | ◌ | ⬜ |

### 4.4 Negative / Error Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-LV-NE-01 | Respond when leave does not need response | Leave in Submitted (not info/doc requested) | Call respond | Error: "This application no longer requires a response." | — | ◌ | ⬜ |
| TC-LV-NE-02 | Comment on terminal status | Leave in Approved/Rejected/Cancelled | Post comment | Error: "Cannot add comments to a resolved application." | — | ◌ | ⬜ |
| TC-LV-NE-03 | Withdraw non-cancellable leave | Leave in Approved status | Call withdraw | LogicException → back with error | — | ◌ | ⬜ |
| TC-LV-NE-04 | Submit with invalid leave type | leave_type_id = -1 | Submit form | Validation error for exists rule | — | ◌ | ⬜ |
| TC-LV-NE-05 | Respond with mismatched remark_id | remark_id from different leave | Submit respond | exists validation fails | — | ◌ | ⬜ |
| TC-LV-NE-06 | StoreParentLeaveRequest fails auth | Child context fails to resolve | Submit form | BaseRequest.authorize() returns false → 403 | — | ◌ | ⬜ |
| TC-LV-NE-07 | WithdrawParentLeaveRequest invalid | Leave not owned by child | Attempt withdraw on another child's leave | 403 abort_unless | — | ◌ | ⬜ |

### 4.5 Security / Access Control Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-LV-SC-01 | Access leave detail for unlinked child | Parent A tries to view Parent B's child leave | GET /parent-portal/leave/{leave} where leave.student_id != active child | 403 Forbidden | — | ◌ | ⬜ |
| TC-LV-SC-02 | Respond on another parent's leave | Wrong child context | POST respond on leave not owned by active child | 403 Forbidden | — | ◌ | ⬜ |
| TC-LV-SC-03 | Withdraw another parent's leave | Wrong child context | POST withdraw on leave not owned by active child | 403 Forbidden | — | ◌ | ⬜ |
| TC-LV-SC-04 | Unauthenticated access | No auth session | Access any leave route | Redirected to login | — | ◌ | ⬜ |

### 4.6 Business Rule Tests

| TC ID | Test Case | BR | Steps | Expected Result | V | CR | Status |
|-------|-----------|-----|-------|-----------------|---|----|--------|
| TC-LV-BR-01 | from_date must be >= tomorrow | BR-PPT-004 | Submit from_date=today; submit from_date=tomorrow | Today rejected; tomorrow accepted | — | ◌ | ⬜ |
| TC-LV-BR-02 | Only Pending/Withdrawable can be withdrawn | BR-PPT-019 | Try withdraw on Approved; try on Submitted | Approved blocked; Submitted succeeds | — | ◌ | ⬜ |
| TC-LV-BR-03 | Attendance event dispatched on approval | BR-PPT-017 | Teacher approves leave | Attendance module receives event for leave dates | — | ◌ | ⬜ |

### 4.7 Integration / API Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-LV-IN-01 | AJAX response for respond | AJAX request header | POST /leave/{leave}/respond with X-Requested-With=XMLHttpRequest | JSON response with success, html, status | — | ◌ | ⬜ |
| TC-LV-IN-02 | AJAX response for storeComment | AJAX request header | POST /leave/{leave}/message with AJAX | JSON response with success, html | — | ◌ | ⬜ |
| TC-LV-IN-03 | Non-AJAX respond redirects | Normal form request | POST respond without AJAX header | Redirect to leave.show with success message | — | ◌ | ⬜ |
| TC-LV-IN-04 | LeaveService.createAndSubmit error handling | InvalidArgumentException thrown | Submit with invalid data caught by service | Redirect back with input; error on leave_type_id | — | ◌ | ⬜ |

### 4.8 Performance / Load Tests

*(No performance tests defined for this feature.)*

### 4.9 Edge Case / Boundary Tests

| TC ID | Test Case | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------|-----------------|---|----|--------|
| TC-LV-EC-01 | Leave with zero active leave types | No types in std_leave_types with is_active=1 | Create form shows empty/no options | Graceful handling (no dropdown or empty state) | — | ◌ | ⬜ |
| TC-LV-EC-02 | Child with no linked GCJ record | Guardian has no StudentGuardianJnt | Access any leave route | BaseRequest.authorize() fails → 403 | — | ◌ | ⬜ |
| TC-LV-EC-03 | Maximum remark thread length | 50+ remarks on one leave | Load leave detail | All remarks load; performance acceptable | — | ◌ | ⬜ |
| TC-LV-EC-04 | Parent of two children submits leave | Multiple children | Submit for child A; switch to B; submit for B | Each leave recorded under correct student_id | — | ◌ | ⬜ |
| TC-LV-EC-05 | Document upload exactly 5 MB | File = 5,120 KB | Upload document | Validation passes (boundary accepted) | — | ◌ | ⬜ |

---

## 5. Test Data Requirements

| Entity | Fields Required | Sample Data |
|--------|----------------|-------------|
| Parent (authenticated) | id, email, password | guardian@test.com / password |
| Child (student) | id, is_active=1 | student_id = 1 |
| Guardian-Child Link (JNT) | guardian_id, student_id, can_access_parent_portal=1 | jnt record |
| Academic Session | id, is_active=1 | session_id = 1 |
| Class Section | id, class_id, section_id | class_section_id = 1 |
| Leave Type | id, name, is_active=1, deleted_at=NULL | Sick Leave, Casual Leave |
| Leave Application | Various statuses for testing | Submitted, Approved, Rejected, Cancelled records |
| Leave Remark | Various types for detail view | info_request, doc_request, comment |
| Upload File | PDF / JPG / PNG < 5 MB | test_document.pdf |

---

## 6. Environment & Setup

- **Backend:** Laravel 12, PHP 8.2+
- **Database:** MySQL 8, tenant_db with all ppt_ + std_ tables migrated
- **Storage:** Local or S3 for document uploads (`leave/documents/` path)
- **Auth:** Sanctum with web guard
- **Session:** Standard Laravel web session
- **Dependencies:** StudentProfile module, SchoolSetup module, Attendance module

---

## 7. Test Execution Notes

- All POST routes require CSRF token
- Document upload tests need multipart form data
- AJAX tests require `X-Requested-With: XMLHttpRequest` header
- Holiday exclusion for day calculation depends on populated sch_holidays
- Activity log entries must be verified in sys_activity_logs after each action

---

## 8. Known Issues

| # | Issue | Module | Severity | Status |
|---|-------|--------|----------|--------|
| KI-01 | FRD refers to `ppt_leave_applications` as missing table but actual code uses `std_leave_applications` from StudentProfile — FRD outdated | Documentation | Medium | Open |
| KI-02 | `WithdrawParentLeaveRequest` has empty rules array — all validation delegated to LeaveService::cancel() | ParentPortal | Low | Open |
| KI-03 | No explicit Gate/Policy for leave ownership — relies on `abort_unless` inline checks | ParentPortal | Medium | Open |
| KI-04 | No concurrency guard on simultaneous withdraw/submit race — possible double-processing | StudentProfile | Low | Open |

---

## 9. Route Reference

| # | Method | URI | Name | Middleware |
|---|--------|-----|------|------------|
| 1 | GET | /parent-portal/leave | parent-portal.leave.index | auth, verified, ParentPortal |
| 2 | GET | /parent-portal/leave/create | parent-portal.leave.create | auth, verified, ParentPortal |
| 3 | POST | /parent-portal/leave | parent-portal.leave.store | auth, verified, ParentPortal |
| 4 | GET | /parent-portal/leave/{leave} | parent-portal.leave.show | auth, verified, ParentPortal |
| 5 | POST | /parent-portal/leave/{leave}/respond | parent-portal.leave.respond | auth, verified, ParentPortal |
| 6 | POST | /parent-portal/leave/{leave}/message | parent-portal.leave.message | auth, verified, ParentPortal |
| 7 | POST | /parent-portal/leave/{leave}/withdraw | parent-portal.leave.withdraw | auth, verified, ParentPortal |

Middleware stack: web → InitializeTenancyByDomain → PreventAccessFromCentralDomains → EnsureTenantIsActive → auth → verified → ParentPortalMiddleware

---

## 10. Execution Status

| Test Suite | Total TC | Passed | Failed | Blocked | Skipped | Execution Date | Executed By |
|------------|----------|--------|--------|---------|---------|----------------|-------------|
| UI / View / Screen | 6 | — | — | — | — | — | — |
| Validation (Field-Level) | 12 | — | — | — | — | — | — |
| Positive / Functional | 8 | — | — | — | — | — | — |
| Negative / Error | 7 | — | — | — | — | — | — |
| Security / Access Control | 4 | — | — | — | — | — | — |
| Business Rules (BR) | 3 | — | — | — | — | — | — |
| Integration / API | 4 | — | — | — | — | — | — |
| Performance / Load | 0 | — | — | — | — | — | — |
| Edge Case / Boundary | 5 | — | — | — | — | — | — |
| **Total** | **49** | — | — | — | — | — | — |
