# Parent Portal — Leave Application Module Requirement

## 1. Module Overview

### 1.1 Purpose
The Leave Application feature enables parents to submit, track, and withdraw leave applications on behalf of their active child. Parents fill in leave dates, type, reason, and optional supporting documents. The class teacher reviews, approves, or rejects the application via admin panel. A chat-like remark thread supports teacher–parent communication (info requests, document requests, free-form comments). Attendance records are updated on approval.

### 1.2 Business Value
- Formalises parent–school leave communication in a traceable digital workflow
- Reduces paper-based leave notes and manual attendance correction
- Gives parents real-time visibility into leave status (Pending → Approved/Rejected/Withdrawn)
- Enables automated attendance marking on approval (Leave status instead of Absent)

### 1.3 Scope
**In Scope:**
- Submit leave on behalf of active child (future dates only)
- Select leave type from active drop-down reference data
- Optional document attachment (PDF/JPG/PNG, max 5 MB)
- Tab-based listing: All / Pending / Approved / Rejected / Cancelled with status counts
- View single leave detail with full remark thread
- Respond to teacher's info_request or doc_request remarks
- Post free-form comments (with optional file attachment)
- Withdraw application while in pending/cancellable state
- Activity logging for all actions

**Out of Scope:**
- Leave approval/rejection actions (teacher-side, admin panel)
- Leave type CRUD (admin module)
- Attendance module auto-update (event-driven; handled by LeaveService)

### 1.4 Terminology
| Term | Meaning |
|------|---------|
| Leave Application | Formal request submitted by parent for child's absence |
| Leave Type | Predefined category (Sick Leave, Casual Leave, etc.) |
| Remark Thread | Ordered list of teacher/parent remarks on a leave |
| Info Request | Teacher asks parent to provide additional information |
| Doc Request | Teacher asks parent to upload a supporting document |
| Withdrawal | Parent cancels a pending application before teacher action |
| Terminal Status | Approved, Rejected, or Cancelled — no further edits possible |

---

## 2. User Roles and Access

| Role | Capability |
|------|-----------|
| Parent / Guardian | Submit, view, respond, comment, withdraw leave for own linked children |
| Class Teacher | Review, approve, reject, request info/docs (via admin panel) |
| System | Auto-calculate days, dispatch notifications, update attendance on approval |

---

## 3. Functional Requirements

### REQ-PPT-010: Leave Application
**Priority:** Standard (P1) | **Source:** FR-PPT-10 V2

**Description:** Parent submits a leave application on behalf of the active child. Class teacher reviews and approves or rejects. On approval, attendance module marks the leave dates accordingly. Parent can withdraw a pending application.

**Actors:** Initiates: Parent | Approves: Class Teacher | Notified: System

**Business Rules:**
| BR | Rule |
|----|------|
| BR-PPT-004 | Leave from_date must be >= tomorrow; same-day and past-date applications rejected |
| BR-PPT-017 | On class teacher approval, event dispatched to attendance module to mark dates as Leave |
| BR-PPT-019 | Only pending/cancellable applications may be withdrawn by the parent |

**Acceptance Criteria:**
- AC1: Leave application rejected by validation if from_date is today or a past date
- AC2: Number of leave days auto-calculated, excluding school holidays
- AC3: Class teacher receives in-app + email notification within 2 minutes of submission
- AC4: Parent notified of approval/rejection within 2 minutes of teacher action
- AC5: On approval, leave dates appear as Leave status in attendance module
- AC6: Parent can withdraw a Pending application; withdrawal triggers status change to Cancelled
- AC7: Approved or Rejected applications cannot be withdrawn
- AC8: Leave application form requires reason (max 1000 chars)

---

## 4. Business Rules Register

| ID | Rule | Enforcement Point |
|----|------|-------------------|
| BR-PPT-004 | from_date must be >= tomorrow | StoreParentLeaveRequest (after:today) |
| BR-PPT-017 | Attendance event dispatch on approval | LeaveService.createAndSubmit / cancel (via service) |
| BR-PPT-019 | Only cancellable statuses may be withdrawn | WithdrawParentLeaveRequest + ParentLeaveController::withdraw (isCancellable guard) |
| — | reason required, max 1000 chars | StoreParentLeaveRequest |
| — | document max 5 MB, mimes: pdf,jpg,jpeg,png | StoreParentLeaveRequest |
| — | to_date must be >= from_date | StoreParentLeaveRequest (after_or_equal) |
| — | Child ownership must match authenticated parent | ParentLeaveController (abort_unless $leave->student_id === $child->id) |
| — | No comments on terminal status (Approved/Rejected/Cancelled) | ParentLeaveController::storeComment (terminal statuses check) |
| — | Info/doc request response validated by remark_type | ParentLeaveController::respond (custom validate block) |

---

## 5. Data Requirements

### Primary Table: `std_leave_applications`
**Source Module:** StudentProfile (not PPT-owned)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | bigint PK | Yes | Auto-increment |
| student_id | FK | Yes | → std_students.id |
| academic_session_id | FK | Yes | → org_academic_sessions.id |
| class_section_id | FK | Yes | → sch_class_sections.id |
| leave_type_id | FK | Yes | → std_leave_types.id (is_active = 1) |
| from_date | date | Yes | >= tomorrow (BR-PPT-004) |
| to_date | date | Yes | >= from_date |
| total_days | int | Yes | Auto-calculated |
| is_half_day | boolean | No | Default false |
| half_day_slot | enum | Conditional | Morning / Afternoon |
| reason | text | Yes | Max 1000 chars |
| status | enum | Yes | Draft/Submitted/Under Review/Info Requested/Doc Requested/Approved/Rejected/Cancelled |
| applied_by | FK | Yes | → sys_users.id |
| reviewed_by | FK | No | → sys_users.id |
| reviewed_at | datetime | No | |
| approved_days | int | No | |
| review_remarks | text | No | |
| created_at | timestamp | Yes | |
| updated_at | timestamp | Yes | |
| deleted_at | timestamp | No | SoftDeletes enabled |

### Related Tables
- `std_leave_application_remarks` — remark thread (info requests, doc requests, comments)
- `std_leave_application_documents` — uploaded supporting documents
- `std_leave_types` — leave type reference data (is_active scoped)

### Cross-Module Dependencies
- **StudentProfile** — std_students, std_guardians, std_student_guardian_jnt
- **SchoolSetup** — sch_class_sections, org_academic_sessions, sch_holidays
- **Attendance module** — attendance update on leave approval (event-driven)

---

## 6. Workflow

### Workflow: Leave Application and Approval (WF-2)
**Trigger:** Parent clicks "Apply Leave" for active child
**End States:** Approved (attendance updated), Rejected (notes visible), Cancelled

| Step | Actor | Action |
|------|-------|--------|
| 1 | Parent | Fill leave form: dates, leave type, reason, optional supporting document |
| 2 | System | Validate from_date >= tomorrow; leave_type_id active; document constraints |
| 3 | System | Create std_leave_applications record with status=Submitted via LeaveService::createAndSubmit |
| 4 | System | Dispatch in-app + email notification to class teacher |
| 5 | Class Teacher | Review in admin panel; approve or reject with notes; can request info/docs |
| 6 | Parent | Respond to info/doc request via ParentLeaveController::respond |
| 7 | Parent | Post free-form comment via ParentLeaveController::storeComment |
| 8a | System (Approved) | Update status=Approved; dispatch event to attendance module; parent notified |
| 8b | System (Rejected) | Update status=Rejected with reviewer_notes; parent notified |
| 9 | Parent | Withdraw while in cancellable status via ParentLeaveController::withdraw |

**Exception Path:** Parent withdraws before teacher acts → status=Cancelled; teacher notified.
**Notifications:** Step 4 (teacher: submission); Step 6 (parent: decision/request).

---

## 7. Finite State Machine (FSM)

### FSM: Leave Application States

| From State | Event | Guard | To State | Side-Effects |
|------------|-------|-------|----------|-------------|
| (none) | Parent submits | from_date >= tomorrow; valid data | Submitted | Teacher notified |
| Submitted | Teacher processes | — | Under Review | — |
| Under Review | Teacher requests info | — | Info Requested | Parent notified to respond |
| Under Review | Teacher requests doc | — | Doc Requested | Parent notified to upload |
| Info Requested | Parent responds | message provided | Under Review | Remark resolved |
| Doc Requested | Parent uploads | file uploaded | Under Review | Remark resolved |
| Under Review | Teacher approves | — | Approved | Attendance event dispatched; parent notified |
| Under Review | Teacher rejects | reviewer_notes | Rejected | Parent notified |
| Submitted / Under Review / Info Requested / Doc Requested | Parent withdraws | status in CANCELLABLE_STATUSES | Cancelled | Teacher notified |

**Illegal transitions:** Approved → Cancelled; Rejected → Cancelled; Cancelled → any.
**Terminal states:** Approved, Rejected, Cancelled (no further edits; comments blocked).

---

## 8. Screen Specifications

| Screen | Route | Controller@Method | View | Description |
|--------|-------|-------------------|------|-------------|
| Leave List | GET /leave | index | leave/index | Tab filter (all/pending/approved/rejected/cancelled) with status counts |
| Apply Leave | GET /leave/create | create | leave/create | Form with leave_type dropdown, date pickers, reason, document upload |
| Leave Detail | GET /leave/{leave} | show | leave/show | Status badge, dates, remark thread, respond/comment/withdraw actions |
| No Session | — | create (conditional) | leave/no-session | Shown when child has no active academic session |

---

## 9. Route Reference

| Method | URI | Name | Controller@Method |
|--------|-----|------|-------------------|
| GET | /leave | leave.index | ParentLeaveController@index |
| GET | /leave/create | leave.create | ParentLeaveController@create |
| POST | /leave | leave.store | ParentLeaveController@store |
| GET | /leave/{leave} | leave.show | ParentLeaveController@show |
| POST | /leave/{leave}/respond | leave.respond | ParentLeaveController@respond |
| POST | /leave/{leave}/message | leave.message | ParentLeaveController@storeComment |
| POST | /leave/{leave}/withdraw | leave.withdraw | ParentLeaveController@withdraw |

All routes are prefixed with `/parent-portal/leave` and named with `parent-portal.leave.` prefix.

---

## 10. Controller Analysis

### ParentLeaveController

**Constructor Dependencies:**
- `ParentContextService` — resolves active child context
- `LeaveService` (StudentProfile) — handles leave creation, cancellation, remark responses

**Key Methods:**

| Method | Request | Authorization | Validation | Error Handling |
|--------|---------|---------------|------------|---------------|
| index | — | None (child scoped) | Tab query filter | — |
| create | — | No active session → no-session view | — | — |
| store | StoreParentLeaveRequest | BaseRequest (child resolved) | from_date>=tomorrow; to_date>=from_date; leave_type exists active; doc mimes+size | InvalidArgumentException → back with errors |
| show | — | abort_unless child ownership | Route model binding | 403 if wrong child |
| respond | — | abort_unless child ownership | Inline: remark_id exists; remark_type in info_request/doc_request; message/file conditional | 403; validation errors |
| storeComment | — | abort_unless child ownership; terminal status check | Inline: message required min 1 max 1000; file optional | 403; validation errors |
| withdraw | WithdrawParentLeaveRequest | abort_unless child ownership | Via service method | LogicException → back with errors |

**Key Behavioral Rules:**
1. `needsStudentResponse()` must be true for respond action — checks status is Info Requested or Doc Requested
2. Terminal statuses (Approved/Rejected/Cancelled) block storeComment
3. `isCancellable()` on LeaveApplication defines cancellable statuses (Draft/Submitted/Info Requested/Doc Requested)
4. AJAX responses supported on respond and storeComment (renders chat-item partial)
5. Activity logging on every method

---

## 11. Validation Rules & Edge Cases

| Field | Rules | Boundary | Invalid Example |
|-------|-------|----------|----------------|
| from_date | required, date, after:today | tomorrow = valid; today = invalid | 2026-06-29 (today) |
| to_date | required, date, after_or_equal:from_date | same day = valid | before from_date |
| leave_type_id | required, integer, exists:std_leave_types,id + is_active + !deleted | — | Inactive/deleted type |
| reason | required, string, max:1000 | 1000 chars max | Empty |
| is_half_day | boolean | — | Non-boolean |
| half_day_slot | required_if:is_half_day,1 | Morning/Afternoon | Invalid value |
| document | nullable, file, mimes:pdf,jpg,jpeg,png, max:5120 | 5120 KB (5 MB) | .docx, >5 MB |
| document_name | required_with:document, max:150 | — | Missing when file present |
| respond.message | required_if:remark_type,info_request, max:1000 | — | Empty for info_request |
| respond.file | required_if:remark_type,doc_request, mimes:pdf,jpg,jpeg,png, max:5120 | — | Missing for doc_request |
| comment.message | required, string, min:1, max:1000 | — | Empty |

**Edge Cases:**
- Submitting leave for a child with no active academic session → no-session view, no leave creation
- Responding to an already-resolved remark → `needsStudentResponse()` returns false → error message
- Commenting on an approved/rejected/cancelled leave → "Cannot add comments to a resolved application"
- Withdrawing an already-approved application → `cancel()` throws LogicException
- Uploading invalid file type for doc_request → validation error
- Multi-day leave including school holidays → days auto-calculated (LeaveService handles holiday exclusion)

---

## 12. Cross-Module Dependencies

| Module | Tables Used | Dependency Type |
|--------|-------------|-----------------|
| StudentProfile | std_leave_applications, std_leave_application_remarks, std_leave_application_documents | Primary data (write) |
| StudentProfile | std_students, std_guardians, std_student_guardian_jnt | Child ownership |
| StudentProfile | std_leave_types | Leave type reference |
| SchoolSetup | sch_class_sections, org_academic_sessions | Academic context |
| SchoolSetup | sch_holidays | Day calculation (exclude holidays) |
| Attendance | std_attendance | Event-driven write on approval |
| Notification | ntf_notifications | Teacher/parent alerts |

---

## 13. Known Issues / Gaps

| # | Gap Description | Severity | Impact | Status |
|---|----------------|----------|--------|--------|
| GI-01 | FRD notes `ppt_leave_applications` as "MISSING" — actual code uses `std_leave_applications` from StudentProfile module. FRD outdated. | Medium | Documentation gap; no actual table missing | Open |
| GI-02 | No explicit Gate policy for leave ownership; enforced via `abort_unless` in controller | Low | Relies on inline checks rather than reusable policy | Open |
| GI-03 | `withdraw` route uses `WithdrawParentLeaveRequest` with empty rules (all validation via service) | Low | Validation via service exception rather than FormRequest | Open |
| GI-04 | No explicit `ParentChildPolicy` — ownership verified ad-hoc per method via `resolveChild` + `abort_unless` | Medium | IDOR surface if future methods skip check | Open |
| GI-05 | Activity logging present on all methods but `reviewed_by` / `reviewed_at` updates are teacher-side | Low | No gap for parent module | — |

---

## 14. Non-Functional Requirements

| NFR | Requirement |
|-----|-------------|
| NFR-PPT-004 | Dashboard data queries ≤ 5 batch queries |
| NFR-PPT-007 | Child ownership enforced on every leave endpoint |
| NFR-PPT-009 | CSRF protection on all POST routes |
| NFR-PPT-013 | All parent actions logged to sys_activity_logs |
| NFR-PPT-016 | Mobile-first responsive design |
| NFR-PPT-018 | Graceful degradation if module inactive |

---

## 15. Future Enhancements

| ID | Enhancement | Priority |
|----|------------|----------|
| ENH-01 | ParentChildPolicy as reusable Gate for all leave ownership checks | P1 |
| ENH-02 | Leave calendar view showing approved leaves on attendance calendar | P2 |
| ENH-03 | Bulk attachment upload (multiple docs per application) | P2 |
| ENH-04 | Leave balance display per leave type | P2 |
| ENH-05 | Re-submit rejected application without re-entering all fields | P2 |

---

## 16. Traceability Matrix

| Requirement | BR | Screen | Workflow | Controller Method | Test Scope |
|-------------|----|--------|----------|-------------------|------------|
| Submit leave | BR-PPT-004 | Apply Leave | WF-2 Step 1–3 | store | Validation, submission, notification |
| View leave list | — | Leave List | — | index | Tab filters, status counts, child scoping |
| View leave detail | — | Leave Detail | — | show | Remark thread, actions visibility |
| Respond to request | — | Leave Detail | WF-2 Step 6 | respond | Info/doc request response flow |
| Post comment | — | Leave Detail | WF-2 Step 7 | storeComment | Comment on active vs terminal status |
| Withdraw leave | BR-PPT-019 | Leave Detail | WF-2 Step 9 | withdraw | Cancellable vs non-cancellable status |
| Ownership check | BR-PPT-001 | All | — | All methods | 403 for unlinked child |
