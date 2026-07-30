# STP — Apply Leave TC List

---

## 1. Module / Sub-Module
- **Module:** StudentPortal (STP)
- **Sub-Module:** Services — Apply Leave

---

## 2. FRD / BR Reference
- **REQ-STP-025** — Student Leave Application (P1)
- **BR-STP-028** — Start date must be today or future
- **BR-STP-029** — Grievance eligibility guard (cross-ref)

---

## 3. Test Scenarios

| TC ID | Test Case | Preconditions | Test Steps | Expected Result | Status |
|-------|-----------|--------------|------------|----------------|--------|
| TC-STP-LEV-001 | Verify leave list page loads with existing applications | Student has 1+ leave applications | 1) Login as student 2) Navigate to /apply-leave | Page renders list with leave type, dates, reason, status badge | ⬜ |
| TC-STP-LEV-002 | Verify leave list empty state | Student has NO leave applications | 1) Login as student 2) Navigate to /apply-leave | "No applications" empty state shown | ⬜ |
| TC-STP-LEV-003 | Verify create form loads with leave types | Active leave types exist in DB | 1) Login as student 2) Navigate to /apply-leave/create | Form renders: leave type dropdown, date pickers, reason textarea, file upload | ⬜ |
| TC-STP-LEV-004 | Verify successful leave submission | Valid form data with future dates | 1) Login as student 2) Fill form 3) Submit | Redirect to show page with success message; status = Submitted | ⬜ |
| TC-STP-LEV-005 | Verify past start date rejected | from_date = yesterday | 1) Login as student 2) Set past start date 3) Submit | 422 validation error: "from_date must be a date after or equal to today" | ⬜ |
| TC-STP-LEV-006 | Verify end date before start date rejected | to_date before from_date | 1) Login as student 2) Set invalid dates 3) Submit | 422 validation error: "to_date must be a date after or equal to from_date" | ⬜ |
| TC-STP-LEV-007 | Verify submission without document (optional field) | No file uploaded | 1) Login as student 2) Fill form without file 3) Submit | Application created; documents relation is empty | ⬜ |
| TC-STP-LEV-008 | Verify document upload within limits | Upload 4 MB valid PDF | 1) Login as student 2) Attach valid file 3) Submit | File stored via media library; document link shown | ⬜ |
| TC-STP-LEV-009 | Verify document exceeds 5 MB rejected | Upload 6 MB file | 1) Login as student 2) Attach oversized file 3) Submit | 422 validation error: "document must not be greater than 5120 kilobytes" | ⬜ |
| TC-STP-LEV-010 | Verify invalid file type rejected | Upload .exe file | 1) Login as student 2) Attach invalid type 3) Submit | 422 validation error: "document must be a file of type: pdf, jpg, jpeg, png" | ⬜ |
| TC-STP-LEV-011 | Verify cancel pending application | Status = Submitted | 1) Login as student 2) POST to /apply-leave/{id}/cancel | Status changes to Cancelled; redirect with success message | ⬜ |
| TC-STP-LEV-012 | Verify cancel on approved application rejected | Status = Approved | 1) Login as student 2) POST /apply-leave/{id}/cancel | Error message: "Cannot cancel in current status" | ⬜ |
| TC-STP-LEV-013 | Verify cancel on rejected application rejected | Status = Rejected | 1) Login as student 2) POST /apply-leave/{id}/cancel | Error message: "Cannot cancel in current status" | ⬜ |
| TC-STP-LEV-014 | Verify show page with remark thread | Application has remarks | 1) Login as student 2) Navigate to /apply-leave/{id} | Timeline shows remarks with sender, message, timestamp, file attachments | ⬜ |
| TC-STP-LEV-015 | Verify add comment on active application | Status = Submitted | 1) Login as student 2) POST /apply-leave/{id}/message with text | Comment added; redirect with "Message sent" | ⬜ |
| TC-STP-LEV-016 | Verify add comment on resolved application rejected | Status = Approved | 1) Login as student 2) POST /apply-leave/{id}/message | Error: "Cannot add comments to a resolved application" | ⬜ |
| TC-STP-LEV-017 | Verify respond to info request | Status = Info Requested, has pending remark | 1) Login as student 2) POST /apply-leave/{id}/respond with message | Remark resolved; status returns to Submitted | ⬜ |
| TC-STP-LEV-018 | Verify respond to doc request | Status = Doc Requested, has pending remark | 1) Login as student 2) POST /apply-leave/{id}/respond with file | Remark resolved; status returns to Submitted; file stored | ⬜ |
| TC-STP-LEV-019 | Verify respond when not needed | Status = Approved, no pending remarks | 1) Login as student 2) POST /apply-leave/{id}/respond | Error: "This application no longer requires a response" | ⬜ |
| TC-STP-LEV-020 | Verify AJAX response on respond() | Request with X-Requested-With: XMLHttpRequest | 1) Login as student 2) POST respond with AJAX header | JSON response with rendered HTML + updated status | ⬜ |
| TC-STP-LEV-021 | Verify AJAX response on storeComment() | Request with AJAX header | 1) Login as student 2) POST message with AJAX header | JSON response with rendered chat item HTML | ⬜ |
| TC-STP-LEV-022 | Verify no active academic session redirects | Student has no current session | 1) Login as student 2) Navigate to /apply-leave | Redirect to dashboard with warning message | ⬜ |
| TC-STP-LEV-023 | Verify data ownership — another student's leave not visible | Student B's application ID | 1) Login as Student A 2) Navigate to /apply-leave/{B_id} | 404 Not Found | ⬜ |
| TC-STP-LEV-024 | Verify half day application with slot | is_half_day = 1, half_day_slot = Morning | 1) Login as student 2) Fill half-day form 3) Submit | Application created with half_day flag and slot | ⬜ |
| TC-STP-LEV-025 | Verify half day without slot rejected | is_half_day = 1, no slot | 1) Login as student 2) Check half-day 3) Leave slot empty 4) Submit | 422 validation error | ⬜ |

---

## 4. Test Data Requirements
- Student with active academic session
- Multiple leave applications in various statuses (Submitted, Approved, Rejected, Cancelled, Info Requested, Doc Requested)
- Active leave types in std_leave_types
- LeaveApplicationRemark records for remark thread testing

---

## 5. Test Environment
- **Browser:** Chrome / Firefox / Edge (latest)
- **Auth:** Authenticated student user
- **DB:** Tenant database seeded with leave types + sample applications + remarks

---

## 6. Automation Scope
| TC ID | Automatable? | Notes |
|-------|-------------|-------|
| TC-STP-LEV-001–025 | Yes | All testable via Pest HTTP tests or Laravel Dusk |

---

## 7. Pass / Fail Criteria
- **Pass:** All TC IDs pass; validations enforce FRD rules; ownership guard works
- **Fail:** Any IDOR violation, validation bypass, or incorrect state transition

---

## 8. Known Issues
| Issue | Description | Severity |
|-------|-------------|----------|
| — | No draft save — applications immediately submitted | Low |
| — | No email notification on status change confirmed | Low |
| — | respond() inconsistently supports AJAX vs store() which doesn't | Low |

---

## 9. Route Reference
| Method | URI | Name |
|--------|-----|------|
| GET | /apply-leave | student-portal.leave.index |
| GET | /apply-leave/create | student-portal.leave.create |
| POST | /apply-leave | student-portal.leave.store |
| GET | /apply-leave/{id} | student-portal.leave.show |
| POST | /apply-leave/{id}/cancel | student-portal.leave.cancel |
| POST | /apply-leave/{id}/respond | student-portal.leave.respond |
| POST | /apply-leave/{id}/message | student-portal.leave.message |

---

## 10. Execution Status
| Total TCs | Passed | Failed | Blocked | Not Run |
|-----------|--------|--------|---------|---------|
| 25 | — | — | — | 25 |
