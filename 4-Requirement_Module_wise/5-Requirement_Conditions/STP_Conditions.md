# STP — Student Portal
## Requirement Conditions Catalog v1.0

**Date:** 2026-06-30 | **Module Code:** STP | **FRD Source:** `STP_FRD_2026-06-30.md`
**Author:** Business Analyst (AI_Brain v1.0, 2026-06-30)

> This file is the canonical per-condition reference for the Student Portal module. Conditions are keyed to BR- IDs from the FRD. Each entry describes the guard/validation/calculation that enforces the business rule, the trigger point in the application, and the correct system behaviour on violation.

---

## Condition Categories

| Category | Prefix | Count |
|---------|--------|-------|
| Data Isolation / Ownership | BR-STP-001 series | 3 |
| Fee & Payment | BR-STP-002 series | 8 |
| Timetable | BR-STP-011 series | 3 |
| Attendance | BR-STP-014 series | 2 |
| Complaint | BR-STP-016 series | 3 |
| Learning / LMS | BR-STP-019 series | 4 |
| Homework Submission | BR-STP-022 series | 1 |
| Online Exam / Attempt Engine | BR-STP-023 series | 4 |
| Quiz Player | BR-STP-027 series | 2 |
| Leave Application | BR-STP-028 series | 2 |
| Grievance | BR-STP-029 series | 2 |
| Notification | BR-STP-030 series | 3 |
| Account Settings | BR-STP-035 series | 2 |
| Cross-Module / Library | BR-STP-033 series | 2 |

**Total Conditions: 41**

---

## Conditions (Full Detail)

### C-STP-001 — Student Data Isolation
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-001 |
| **REQ Refs** | REQ-STP-001 through REQ-STP-035 (all screens) |
| **Entity / Field** | Any tenant_db table containing student data |
| **Business Condition** | All data fetched by any StudentPortal controller must belong to the currently authenticated student. A student must never see data belonging to another student. |
| **Type** | Permission / Authorization |
| **Trigger** | Every `findOrFail`, `where`, `whereHas`, or `firstOrFail` query in any web or mobile STP controller |
| **Guard Mechanism** | Scope all queries through `$request->user()->student` relationship. Do not accept `student_id` from the client. |
| **On-Violation Behaviour** | 404 Not Found (preferred to avoid confirming that the record exists). Optionally 403 Forbidden for authenticated but unauthorized access. |
| **Current Code Status** | Partially enforced. proceedPayment() and invoice-related endpoints have confirmed IDOR gaps. Mobile controllers rely on ResolvesMobileStudent trait. |
| **Gap ID** | SEC-STP-01, SEC-STP-13 |

---

### C-STP-002 — Fee Invoice Ownership
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-002 |
| **REQ Refs** | REQ-STP-004, REQ-STP-005 |
| **Entity / Field** | Fee Invoice (fee_invoices table) |
| **Business Condition** | A student may only view or initiate payment on an invoice that is assigned to them via the fee assignment chain (fee_structure → fee_assignment → student). |
| **Type** | Ownership Validation |
| **Trigger** | viewInvoice(), payDueAmount(), paymentInitiate(), proceedPayment() |
| **Guard Mechanism** | `FeeInvoice::whereHas('feeStudentAssignment', fn($q) => $q->where('student_id', $student->id))` — must be applied before any further query |
| **On-Violation Behaviour** | 404 Not Found; Razorpay order must NOT be created |
| **Current Code Status** | Broken in proceedPayment() — accepts client-supplied payable_id without ownership check |
| **Gap ID** | SEC-STP-01 |

---

### C-STP-003 — Payment Amount Range
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-007 |
| **REQ Refs** | REQ-STP-005 |
| **Entity / Field** | payment.amount (POST body) |
| **Business Condition** | The payment amount must be a positive value and must not exceed the remaining balance on the invoice. |
| **Type** | Validation |
| **Trigger** | proceedPayment() POST |
| **Guard Mechanism** | Server-side: `amount >= 1 AND amount <= $invoice->remaining_balance`. Client-side max is a UX aid only — the server must re-validate. |
| **On-Violation Behaviour** | 422 Unprocessable Entity with field error: "Amount must be between INR 1 and the remaining balance of INR {X}" |
| **Current Code Status** | Not implemented server-side |
| **Gap ID** | GAP-STP-06 |

---

### C-STP-004 — Invoice Status for Payment
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-006 |
| **REQ Refs** | REQ-STP-005 |
| **Entity / Field** | fee_invoices.status |
| **Business Condition** | Payment may only be initiated on invoices with status Published, Partially Paid, or Overdue. Paid, Cancelled, or Draft invoices must not be payable. |
| **Type** | State Validation |
| **Trigger** | paymentInitiate() page load and proceedPayment() POST |
| **Guard Mechanism** | `$invoice->status->in(['Published', 'Partially Paid', 'Overdue'])` — validated on page load (redirects) and re-validated on POST |
| **On-Violation Behaviour** | Redirect to invoice view with flash message: "This invoice cannot be paid at this time." |
| **Current Code Status** | Status check on page load exists; re-check on POST not confirmed |
| **Gap ID** | GAP-STP-06 |

---

### C-STP-005 — Active Payment Gateway Required
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-008 |
| **REQ Refs** | REQ-STP-005 |
| **Entity / Field** | payment_gateways.status |
| **Business Condition** | Only Active payment gateways must be shown on the payment page. Inactive or disabled gateways must be excluded. |
| **Type** | Filter |
| **Trigger** | Payment page render (gateway select list) |
| **Guard Mechanism** | `PaymentGateway::where('status', 'Active')->get()` — must NOT use `PaymentGateway::all()` |
| **On-Violation Behaviour** | Inactive gateways shown → student sees incorrect options → payment fails downstream |
| **Current Code Status** | Bug: code uses `PaymentGateway::all()` — fetches inactive gateways |
| **Gap ID** | BUG-STP-08 |

---

### C-STP-006 — Payment Rate Limiting
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-010 |
| **REQ Refs** | REQ-STP-005 |
| **Entity / Field** | POST /fee/invoice/{invoice}/pay/initiate |
| **Business Condition** | A student may not initiate more than 3 payment attempts within any 5-minute window. |
| **Type** | Rate Limit / Concurrency |
| **Trigger** | proceedPayment() POST route |
| **Guard Mechanism** | `throttle:3,5` middleware applied to payment POST route |
| **On-Violation Behaviour** | 429 Too Many Requests with Retry-After header |
| **Current Code Status** | Not implemented |
| **Gap ID** | ENH-STP-006 related |

---

### C-STP-007 — Timetable Break Cell Exclusion
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-013 |
| **REQ Refs** | REQ-STP-008 |
| **Entity / Field** | tt_timetable_cells.is_break |
| **Business Condition** | Timetable cells where is_break = true must not be rendered as class periods. They must be displayed as a "Break" label with no subject, teacher, or room information. |
| **Type** | Filter / Display |
| **Trigger** | Timetable grid build in timetable() controller method |
| **Guard Mechanism** | Filter applied during grid construction: if `is_break = true`, render as break row only. |
| **On-Violation Behaviour** | Break cells rendered as class periods → confusing timetable for students |
| **Current Code Status** | Implemented; verified through T-STP-010 |
| **Gap ID** | None |

---

### C-STP-008 — Attendance Status Normalization
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-015 |
| **REQ Refs** | REQ-STP-007 |
| **Entity / Field** | std_daily_attendance.status (or equivalent attendance table field) |
| **Business Condition** | Attendance status values from the source table must be normalized to the student-facing labels: Present, Absent, Late, On Leave. Unknown or NULL values must not be rendered as raw codes. |
| **Type** | Calculation / Normalization |
| **Trigger** | Attendance view render (controller or model accessor) |
| **Guard Mechanism** | Model accessor on `StudentAttendance::getStatusAttribute()` that maps raw values to business labels; NULL maps to "Not Marked" |
| **On-Violation Behaviour** | Raw DB codes like "P", "A", "L" shown → student confusion |
| **Current Code Status** | Partially implemented; accessor may not handle all raw values |
| **Gap ID** | BR-STP-015 |

---

### C-STP-009 — Complainant Type Dynamic Lookup
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-018 |
| **REQ Refs** | REQ-STP-028 |
| **Entity / Field** | cmp_complaints.complainant_type_id (FK to sys_dropdowns) |
| **Business Condition** | The complainant type for a Student-submitted complaint must be resolved by the string key "COMPLAINANT_STUDENT" from the sys_dropdowns master, not by a hardcoded integer ID. |
| **Type** | Dynamic Lookup |
| **Trigger** | Complaint create page load (for form pre-population) and complaint store() POST |
| **Guard Mechanism** | `SysDropdown::where('key', 'COMPLAINANT_STUDENT')->value('id')` — must not use `id = 104` |
| **On-Violation Behaviour** | Hardcoded ID 104 breaks on any fresh database seed → 500 error on complaint submission |
| **Current Code Status** | Hardcoded ID 104 in current code — P0 fix required |
| **Gap ID** | SEC-STP-04 |

---

### C-STP-010 — LMS Allocation Expiry
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-020 |
| **REQ Refs** | REQ-STP-011, REQ-STP-031, REQ-STP-032 |
| **Entity / Field** | lms quiz/quest allocation end_date |
| **Business Condition** | Quiz and quest allocations past their end date must not be shown on the Learning Hub and the student must not be permitted to start an attempt on an expired allocation. |
| **Type** | Date Guard |
| **Trigger** | Learning hub index load; quiz/quest start attempt |
| **Guard Mechanism** | `->where('end_date', '>=', now())` on allocation queries; re-validated at start attempt time |
| **On-Violation Behaviour** | Expired allocation shown → student clicks Start → 422 "This assessment is no longer available" |
| **Current Code Status** | Implemented on listing; start-attempt re-validation not confirmed |
| **Gap ID** | — |

---

### C-STP-011 — Homework Late Submission Gate
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-022 |
| **REQ Refs** | REQ-STP-012 |
| **Entity / Field** | hmw_homeworks.restrict_late_submission, hmw_homeworks.due_date |
| **Business Condition** | When restrict_late_submission = true on a homework record, a student may not submit after the due_date. The submit form must be hidden and the POST endpoint must reject late submissions. |
| **Type** | Business Rule Guard |
| **Trigger** | Homework detail view render; homework submit POST |
| **Guard Mechanism** | Controller check: `if ($homework->restrict_late_submission && now()->isAfter($homework->due_date))` → return error or redirect |
| **On-Violation Behaviour** | "Late submission is not accepted for this homework. The due date was {date}." — submit button hidden |
| **Current Code Status** | Implemented in HomeworkController |
| **Gap ID** | — |

---

### C-STP-012 — Exam Attempt Uniqueness
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-023 |
| **REQ Refs** | REQ-STP-030 |
| **Entity / Field** | lms_exam_attempts (exam_paper_id + student_id) |
| **Business Condition** | A student may have at most one attempt per exam paper. Starting an exam must be idempotent — if an attempt already exists, the student is redirected to that attempt, not given a new one. |
| **Type** | Concurrency Guard / Idempotency |
| **Trigger** | POST /student-portal/exam/{id}/start |
| **Guard Mechanism** | `firstOrCreate` on (exam_paper_id, student_id); DB UNIQUE constraint as backstop |
| **On-Violation Behaviour** | Existing IN_PROGRESS attempt → redirect to attempt player. Existing SUBMITTED attempt → redirect to result screen. |
| **Current Code Status** | Implemented via `firstOrCreate` pattern in StartAttemptRequest/controller |
| **Gap ID** | — |

---

### C-STP-013 — Only In-Progress Attempts Accept Answers
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-024 |
| **REQ Refs** | REQ-STP-030, REQ-STP-031, REQ-STP-032 |
| **Entity / Field** | lms_exam_attempts.status, lms_quiz_quest_attempts.status |
| **Business Condition** | The save-answer, checkpoint, and activity-log endpoints must only accept data when the attempt is in IN_PROGRESS status. Any other status must result in a rejected request. |
| **Type** | State Guard |
| **Trigger** | POST /exam/{id}/save-answer, /checkpoint, /log |
| **Guard Mechanism** | `if ($attempt->status !== 'IN_PROGRESS') abort(409, 'Attempt not in progress')` |
| **On-Violation Behaviour** | 409 Conflict — "This attempt is no longer active." |
| **Current Code Status** | Implemented in SaveAnswerRequest and attempt controllers |
| **Gap ID** | — |

---

### C-STP-014 — Exam Auto-Timeout
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-025 |
| **REQ Refs** | REQ-STP-030 |
| **Entity / Field** | lms_exam_attempts.status, lms_exam_attempts.start_time |
| **Business Condition** | IN_PROGRESS exam attempts that have exceeded their time limit must be automatically submitted and transitioned to TIMEOUT status. This must not require student action. |
| **Type** | System Automation |
| **Trigger** | `TimeoutStaleAttempts` Artisan command (scheduled cron, recommended: every 5 minutes) |
| **Guard Mechanism** | `->where('status', 'IN_PROGRESS')->whereRaw('TIMESTAMPDIFF(MINUTE, start_time, NOW()) > time_limit_minutes')` → auto-submit |
| **On-Violation Behaviour** | Stale IN_PROGRESS attempts persist indefinitely → students cannot re-take; exam results incomplete |
| **Current Code Status** | Command exists as `TimeoutStaleAttempts`; must verify registration in Scheduler |
| **Gap ID** | RISK-STP-005 |

---

### C-STP-015 — Quiz Maximum Attempts
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-027 |
| **REQ Refs** | REQ-STP-031 |
| **Entity / Field** | quiz allocation max_attempts vs. lms_quiz_quest_attempts count for this student |
| **Business Condition** | A student may not start a new quiz attempt if their attempt count for this quiz equals or exceeds the max_attempts value defined in the quiz allocation. |
| **Type** | Business Rule Guard |
| **Trigger** | Quiz start POST; quiz instructions page render |
| **Guard Mechanism** | `$attemptCount = LmsQuizQuestAttempt::where('student_id', ...)->where('quiz_id', ...)->count(); if ($attemptCount >= $allocation->max_attempts) abort(422, 'Maximum attempts reached')` |
| **On-Violation Behaviour** | 422 — "You have reached the maximum number of attempts for this quiz." |
| **Current Code Status** | Implemented in quiz start controller |
| **Gap ID** | — |

---

### C-STP-016 — Leave Start Date Validation
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-028 |
| **REQ Refs** | REQ-STP-025 |
| **Entity / Field** | leave_applications.start_date |
| **Business Condition** | The leave start date must be today or a future date. Students may not apply for leave retroactively. |
| **Type** | Validation |
| **Trigger** | StoreLeaveApplicationRequest |
| **Guard Mechanism** | `'start_date' => 'required|date|after_or_equal:today'` |
| **On-Violation Behaviour** | 422 — "Leave start date must be today or a future date." |
| **Current Code Status** | Implemented in StoreLeaveApplicationRequest |
| **Gap ID** | — |

---

### C-STP-017 — Grievance Eligibility
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-029 |
| **REQ Refs** | REQ-STP-033 |
| **Entity / Field** | lms_exam_attempts.status |
| **Business Condition** | A student may only raise a grievance against an exam paper for which they have a SUBMITTED or EVALUATED attempt. Students who have not attempted the exam, or whose attempt is IN_PROGRESS, cannot raise a grievance. |
| **Type** | Permission Guard |
| **Trigger** | GET /student-portal/exam/{id}/grievance/create |
| **Guard Mechanism** | `LmsExamAttempt::where('student_id', ...)->where('exam_paper_id', ...)->whereIn('status', ['SUBMITTED', 'EVALUATED'])->exists() || abort(403)` |
| **On-Violation Behaviour** | 403 Forbidden — "You must have completed this exam before raising a grievance." |
| **Current Code Status** | Implemented in grievance create controller |
| **Gap ID** | — |

---

### C-STP-018 — Notice Board Data Source
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-031 |
| **REQ Refs** | REQ-STP-023 |
| **Entity / Field** | Notice Board screen data source |
| **Business Condition** | The notice board must display official school announcements from the school's announcements/circulars model (SchoolSetup module), not from the user's personal notification inbox. |
| **Type** | Data Source |
| **Trigger** | Notice board page render |
| **Guard Mechanism** | Query `sch_announcements` (or equivalent SchoolSetup model), not `auth()->user()->notifications()` |
| **On-Violation Behaviour** | Wrong source renders personal notifications as "notices" → official circulars not visible to students |
| **Current Code Status** | Bug — notice board currently queries personal notifications |
| **Gap ID** | GAP-STP-07 |

---

### C-STP-019 — Notification Mark-Read HTTP Method
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-032 |
| **REQ Refs** | REQ-STP-027 |
| **Entity / Field** | Route: notifications/{id}/mark-read |
| **Business Condition** | Marking a notification as read must use a POST or PATCH HTTP method, not GET. GET endpoints may be pre-fetched by browsers, search crawlers, or link prefetchers, causing notifications to be marked read without student intent. |
| **Type** | HTTP Method Correctness |
| **Trigger** | Notifications inbox — "Mark as read" action |
| **Guard Mechanism** | Route defined as `Route::post('notifications/{id}/mark-read', ...)` or `Route::patch(...)` |
| **On-Violation Behaviour** | GET route on a state-changing endpoint → CSRF and pre-fetch risk |
| **Current Code Status** | Route currently uses GET — must be changed |
| **Gap ID** | BR-STP-032 |

---

### C-STP-020 — Notification Ownership Check
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-030 |
| **REQ Refs** | REQ-STP-027 |
| **Entity / Field** | notifications table — notifiable_id |
| **Business Condition** | A student may only mark their own notifications as read. Attempting to mark another user's notification as read must fail silently or return 403. |
| **Type** | Ownership |
| **Trigger** | notifications/{id}/mark-read endpoint |
| **Guard Mechanism** | `$notification = $user->notifications()->findOrFail($id)` — scoped through the user relationship |
| **On-Violation Behaviour** | 404 (preferred) — the notification is not found in the user's scope |
| **Current Code Status** | Likely implemented via Eloquent relationship; confirm scoping |
| **Gap ID** | — |

---

### C-STP-021 — Password Change Verification
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-035 |
| **REQ Refs** | REQ-STP-029 |
| **Entity / Field** | Account Settings — password change form |
| **Business Condition** | The student must provide their current password before a password change is accepted. The new password and confirmation must match. Minimum password complexity applies. |
| **Type** | Validation |
| **Trigger** | Account settings password change POST |
| **Guard Mechanism** | `Hash::check($request->current_password, $user->password) || abort(422, 'Current password is incorrect')` + `confirmed` rule on new_password |
| **On-Violation Behaviour** | 422 — "Current password is incorrect." or "Password confirmation does not match." |
| **Current Code Status** | Not implemented (account settings backend is a stub) |
| **Gap ID** | GAP in REQ-STP-029 |

---

### C-STP-022 — Guardian-Child Link for Parent Portal Mode
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-004 |
| **REQ Refs** | REQ-STP-035 |
| **Entity / Field** | std_student_guardians.can_access_parent_portal |
| **Business Condition** | A parent may only view a student's data if that student is linked to the parent's account AND the `can_access_parent_portal` flag is true on the guardian junction record. |
| **Type** | Permission Guard |
| **Trigger** | All portal data endpoints when accessed by a user with role = Parent |
| **Guard Mechanism** | `$student = $user->guardianStudents()->where('can_access_parent_portal', true)->where('student_id', $requested_student_id)->firstOrFail()` |
| **On-Violation Behaviour** | 403 Forbidden |
| **Current Code Status** | Not fully implemented — child switcher context not built |
| **Gap ID** | ENH-STP-002 |

---

### C-STP-023 — Library Resource Authorization
| Attribute | Value |
|-----------|-------|
| **BR Ref** | BR-STP-033 |
| **REQ Refs** | REQ-STP-018 |
| **Entity / Field** | Digital resource access endpoint; book reservation |
| **Business Condition** | A student may only access digital library resources they have been granted access to. Physical book reservations require an active library membership. |
| **Type** | Permission |
| **Trigger** | Library digital access request; physical book reserve |
| **Guard Mechanism** | Check `lib_memberships.is_active = true` for physical reservations; check `lib_digital_access.student_id = $student->id` for digital downloads |
| **On-Violation Behaviour** | 403 — "Your library membership is not active." or 403 for unauthorized digital access |
| **Current Code Status** | Implemented in library-related STP controllers |
| **Gap ID** | — |

---

## Cross-Reference to Module Knowledge

The authoritative technical implementation notes for each condition are in the module knowledge file at:
`/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/STP_StudentPortal.md`

Gaps tagged as SEC-STP-* are tracked in the knowledge file's P0 Issues section.

---

*Conditions Catalog saved: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/5-Requirement_Conditions/STP_Conditions.md`*
*FRD Source: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/STP_FRD_2026-06-30.md`*
