# STP — Apply Leave Requirement Document

---

## 1. Module / Sub-Module
- **Module:** StudentPortal (STP)
- **Sub-Module:** Services — Apply Leave
- **Table Prefix:** stp_ (uses std_leave_applications, std_leave_remarks from StudentProfile)

---

## 2. FRD Reference
| ID | Description | Priority |
|----|------------|----------|
| REQ-STP-025 | Student Leave Application | P1 |
| BR-STP-028 | Start date must be today or future | P0 |
| BR-STP-029 | Grievance eligibility — student must have submitted/evaluated attempt | P0 |

---

## 3. Feature Description
Enables students to submit leave requests, track application progress via a status timeline, respond to teacher queries (info request / doc request), add free-form comments with attachments, and cancel their own applications when still in a non-terminal state.

---

## 4. User Stories / Use Cases
- **As a** student, **I want to** apply for leave with type, dates, reason, and optional document **so that** I don't need a paper form.
- **As a** student, **I want to** view my leave history with status badges **so that** I can track approvals.
- **As a** student, **I want to** respond to a teacher's information or document request **so that** my application can proceed.
- **As a** student, **I want to** cancel my pending leave application **so that** I can withdraw a request I no longer need.

---

## 5. Business Rules (BR)
| BR ID | Rule | Type | Enforcement |
|-------|------|------|-------------|
| BR-STP-001 | Data must belong to authenticated student | Permission | All queries scoped to `auth()->user()->student->id` |
| BR-STP-028 | Leave start date must be today or a future date | Validation | `StoreLeaveApplicationRequest`: `from_date => after_or_equal:today` |
| BR-STP-029 | (Cross-reference) Grievance eligibility has separate guard | Permission | Applied in StudentGrievanceController |
| — | End date must be equal to or after start date | Validation | `StoreLeaveApplicationRequest`: `to_date => after_or_equal:from_date` |
| — | Leave type must be active | Validation | `StoreLeaveApplicationRequest`: `exists:std_leave_types,id` + `where('is_active', true)` |
| — | Upload max 5 MB, allowed types: PDF, JPG, JPEG, PNG | Validation | `StoreLeaveApplicationRequest`: `max:5120`, `mimes:pdf,jpg,jpeg,png` |
| — | Reason required, max 1000 characters | Validation | `StoreLeaveApplicationRequest`: `required, string, max:1000` |
| — | Half day requires slot selection (Morning/Afternoon) | Validation | `required_if:is_half_day,1` |
| — | Cannot cancel after application is Approved, Rejected, or Cancelled | Workflow | `LeaveService::cancel()` throws LogicException for terminal statuses |
| — | Cannot add comments to resolved applications (Approved/Rejected/Cancelled) | Workflow | `storeComment()` checks terminal statuses and returns error |
| — | Response required only when `needsStudentResponse()` returns true | Workflow | `respond()` checks `needsStudentResponse()` before processing |

---

## 6. Validations & Edge Cases
| Scenario | Input / Action | Expected Behaviour |
|----------|---------------|-------------------|
| Past start date | from_date = yesterday | 422 validation error: "from_date must be a date after or equal to today" |
| End date before start date | from_date = 2026-08-10, to_date = 2026-08-05 | 422 validation error: "to_date must be a date after or equal to from_date" |
| No document uploaded | Omit file field | Application created without document (optional field) |
| Document > 5 MB | Upload 6 MB file | 422 validation error |
| Invalid file type | Upload .exe file | 422 validation error |
| Cancel approved application | Click cancel on Approved leave | Error: "Cannot cancel" via LogicException |
| Respond to resolved application | Application status = Approved | Error: "This application no longer requires a response" |
| Half day without slot | is_half_day = 1, half_day_slot = null | 422 validation error |
| Non-existent leave_type_id | leave_type_id = 99999 | 422 validation error |
| No active academic session | student->currentSession() returns null | Redirect to dashboard with warning message |
| Comment on terminal application | POST /message on Approved leave | Error: "Cannot add comments to a resolved application" |

---

## 7. Route Details
| Method | Route | Name | Controller Method |
|--------|-------|------|-------------------|
| GET | /apply-leave | student-portal.leave.index | StudentLeaveController@index |
| GET | /apply-leave/create | student-portal.leave.create | StudentLeaveController@create |
| POST | /apply-leave | student-portal.leave.store | StudentLeaveController@store |
| GET | /apply-leave/{id} | student-portal.leave.show | StudentLeaveController@show |
| POST | /apply-leave/{id}/cancel | student-portal.leave.cancel | StudentLeaveController@cancel |
| POST | /apply-leave/{id}/respond | student-portal.leave.respond | StudentLeaveController@respond |
| POST | /apply-leave/{id}/message | student-portal.leave.message | StudentLeaveController@storeComment |

---

## 8. Data / Entity Reference

### A. Leave Application
- **Model:** `Modules\StudentProfile\Models\LeaveApplication`
- **Table:** `std_leave_applications`
- **Key status constants:** STATUS_DRAFT, STATUS_SUBMITTED, STATUS_UNDER_REVIEW, STATUS_INFO_REQUESTED, STATUS_DOC_REQUESTED, STATUS_APPROVED, STATUS_REJECTED, STATUS_CANCELLED
- **Eager loads (show):** leaveType, appliedBy, reviewedBy, remarks.remarkedBy, remarks.parentRemark, remarks.responseDocuments, documents, documents.uploadedBy

### B. Leave Application Remark
- **Model:** `Modules\StudentProfile\Models\LeaveApplicationRemark`
- **Table:** `std_leave_application_remarks`
- **Types:** TYPE_INFO_REQUEST, TYPE_DOC_REQUEST, TYPE_PARENT_COMMENT (inferred)

### C. Leave Service
- **Service:** `Modules\StudentProfile\Services\LeaveService`
- **Methods used:** getStudentApplications(), getActiveLeaveTypes(), createAndSubmit(), cancel(), addParentComment(), respondToInfoRequest(), respondToDocRequest()

---

## 9. Dependencies (Cross-Module)
| Module | Dependency | Type |
|--------|-----------|------|
| StudentProfile (STD) | LeaveApplication, LeaveApplicationRemark, LeaveService | Read/Write |

---

## 10. Integration / API
- AJAX support on `respond()` and `storeComment()` — returns JSON with rendered HTML
- `store()` always returns redirect (no AJAX)
- `cancel()` always returns redirect (no AJAX)

---

## 11. Security & Permissions
| Check | Implementation |
|-------|---------------|
| Authentication | Standard `auth` + `verified` middleware |
| Data ownership | All queries scoped via `where('student_id', $student->id)` |
| Cancel guard | `LeaveService::cancel()` — LogicException if terminal status |
| Comment guard | `storeComment()` checks `in_array($application->status, $terminalStatuses)` |
| Respond guard | `respond()` checks `$application->needsStudentResponse()` |

---

## 12. Assumptions & Constraints
- Student must have an active academic session to apply for leave
- `LeaveService` handles the actual state transitions (FSM)
- File uploads are stored via media library
- Leave types must be pre-configured in `std_leave_types` with `is_active = true`

---

## 13. FSM: Leave Application Status
| From State | Event | Guard | To State | Side-Effects |
|-----------|-------|-------|---------|-------------|
| (new) | Student submits form | Valid dates + future start | Submitted (Pending) | Notification to admin |
| Submitted | Admin approves | — | Approved | Notification to student |
| Submitted | Admin rejects | — | Rejected | Notification to student + reason |
| Submitted | Student cancels | — | Cancelled | Application closed |
| Submitted | Admin requests info | — | Info Requested | Student must respond to proceed |
| Submitted | Admin requests doc | — | Doc Requested | Student must upload document |
| Info/Doc Requested | Student responds | Valid response | Submitted | Re-enters review queue |
| Approved/Rejected | (No further transitions) | Terminal | — | — |

**Terminal states:** Approved, Rejected, Cancelled

---

## 14. Known Issues / Gaps
| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| — | No draft save functionality — applications are immediately submitted | Low | Open |
| — | No email/push notification on status change confirmed in codebase | Low | Open |
| — | `respond()` method uses both redirect and JSON response — inconsistent with `store()` | Low | Open |

---

## 15. Future Enhancements
| ID | Suggestion | Priority |
|----|-----------|----------|
| ENH-STP-LEV-01 | Add draft save with scheduled submission | P3 |
| ENH-STP-LEV-02 | Add leave balance / quota display | P3 |
| ENH-STP-LEV-03 | Allow editing pending application before review | P3 |

---

## 16. V1/V2 Status
- **V1:** —
- **V2:** —
- **Status:** ✅ Implemented
- **CR:** ◌

---

## 17. Revision History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 23-07-2026 | OpenCode | Initial requirement document |
