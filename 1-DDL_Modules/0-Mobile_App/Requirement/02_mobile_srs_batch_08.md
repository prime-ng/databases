# Mobile SRS — Batch 08 (Leave · Library · Hostel)

> Index: `02_mobile_srs_index.md`. Features: F-100, F-101, F-102, F-103, F-110, F-111, F-120, F-121.

---

## F-100: Apply for Student Leave (P1)

### 1. Overview
Parent / student applies for leave with date range, reason, optional medical attachment. Pre-req: BG-32 (Attendance module — PLANNED — `att_leave_*`).

### 2. User Stories
- **US-100.1** *As a parent, I apply for 2 days sick leave for Asha with a medical certificate.*
- **US-100.2** *As a student (older), I apply for half-day leave myself.*

### 3. Functional Requirements
- **FR-100.1** Date range; mutually-exclusive with attendance days; weekend-aware.
- **FR-100.2** Reason categories from `sys_dropdown_table` (`STUDENT_LEAVE_REASON`).
- **FR-100.3** Optional attachment (medical certificate).
- **FR-100.4** Status FSM: `PENDING → APPROVED | REJECTED | CANCELLED`.
- **FR-100.5** Auto-routes to class-teacher approver (F-101).

### 4. Screen Specifications
Form: from-date, to-date, half-day toggle, reason picker, description, attachment.

### 5. API Contracts

#### `POST /api/mobile/v1/leave/student/apply`
- **Status:** NEW (BG-32). Module: Attendance (PLANNED).
- **Idempotency-Key:** `leave:{applicant_id}:{from}:{to}:{type}`.

### 6. Data Model
`cache_my_leaves`, `pending_writes` for offline submits.

### 7. Offline Behavior
Queued.

### 8. Push Notifications
Emits `LEAVE_PENDING_APPROVAL` to approver. Consumer of `LEAVE_DECISION`.

### 9. Permissions & Security
- Authorize: parent of student or student-self.
- Attachment scanning (anti-malware) — Phase 3 OQ.
- Audit: `LEAVE_APPLIED`.

### 10. Non-Functional Requirements
- Submit perceived < 200 ms.
- Localization: `f100.cta`, `f100.error.*`.

### 11. Acceptance Criteria
- **AC-100.1** Overlapping pending leave for same dates returns 409.
- **AC-100.2** Leave attachment > 5 MB rejected (413).

### 12. Dependencies
- F-002, F-005. BG-32.

### 13. Out of Scope
- Multi-day attachments per day — v1.1.

---

## F-101: Approve Student Leave (Teacher / Class Teacher, P1)

### 1. Overview
Class teacher reviews pending student leaves and approves / rejects.

### 2. User Stories
- **US-101.1** *As a class teacher, I see pending leaves and clear them in 1 tap.*

### 3. Functional Requirements
- **FR-101.1** Approver determined by class-section assignment.
- **FR-101.2** Endpoint: `POST /leave/student/{id}/decision` `{ decision, remark }`.
- **FR-101.3** State transitions only from PENDING.
- **FR-101.4** Bulk-approve not in v1.

### 4. Screen Specifications
List of pending → swipe-to-approve / reject sheet.

### 5. API Contracts

#### `GET /api/mobile/v1/leave/student?status=pending`
#### `POST /api/mobile/v1/leave/student/{id}/decision`
- **Status:** NEW (BG-32).

### 6. Data Model
`cache_pending_student_leaves`.

### 7. Offline Behavior
Queued decisions.

### 8. Push Notifications
Emits `LEAVE_DECISION` to applicant.

### 9. Permissions & Security
- Approver-only (`tt_class_section.class_teacher_id`).
- Audit: `LEAVE_DECISION`.

### 10. Non-Functional Requirements
- Decision perceived < 200 ms.
- Localization: `f101.cta.{approve,reject}`.

### 11. Acceptance Criteria
- **AC-101.1** Non-class-teacher → 403.
- **AC-101.2** Approving an already-decided leave returns 409.

### 12. Dependencies
- F-100. BG-32.

### 13. Out of Scope
- Multi-level approval — v1.1.

---

## F-102: Apply for Employee Leave (Teacher / Staff, P1)

### 1. Overview
Employees apply for their own leave. Module: SchoolSetup / HrStaff. Pre-req: BG-31 (Employee Leave DDL v4 ready, code pending — D33).

### 2. User Stories
- **US-102.1** *As a teacher, I apply for 3 days casual leave with reason.*
- **US-102.2** *I see my leave balance: CL 5/12, SL 3/8.*

### 3. Functional Requirements
- **FR-102.1** Leave types from `sys_dropdown_table` (`EMP_LEAVE_TYPE`).
- **FR-102.2** Balance auto-calculated server-side from `sch_employee_leave_balances`.
- **FR-102.3** Conflict check: no overlap with existing approved leave.

### 4. Screen Specifications
Balance summary header + apply form.

### 5. API Contracts

#### `POST /api/mobile/v1/leave/employee/apply`
- **Status:** NEW (BG-31).

### 6. Data Model
`cache_my_leave_balances`.

### 7. Offline Behavior
Queued.

### 8. Push Notifications
Emits `LEAVE_PENDING_APPROVAL` (multi-level — F-103).

### 9. Permissions & Security
- Self only.
- Audit: `EMPLOYEE_LEAVE_APPLIED`.

### 10. Non-Functional Requirements
- Submit perceived < 200 ms.
- Localization: `f102.balance.*`, `f102.cta`.

### 11. Acceptance Criteria
- **AC-102.1** Overlapping leave returns 409.
- **AC-102.2** Insufficient balance returns 422.

### 12. Dependencies
- F-002. BG-31.

### 13. Out of Scope
- Comp-off conversion — v1.1.

---

## F-103: Approve Employee Leave (Multi-level, P1)

### 1. Overview
Approver chain (e.g. HOD → Principal). Each approver acts via this feature.

### 2. User Stories
- **US-103.1** *As HOD I approve leave; it forwards to Principal automatically.*

### 3. Functional Requirements
- **FR-103.1** Workflow rows in `sch_employee_leave_workflow_jnt`.
- **FR-103.2** Endpoint advances state machine; idempotent per (leave_id, approver_id, decision).
- **FR-103.3** Final approval emits `LEAVE_DECISION` to applicant.

### 4. Screen Specifications
Approvals queue → detail → approve / reject with remark.

### 5. API Contracts

#### `GET /api/mobile/v1/leave/employee?role=approver`
#### `POST /api/mobile/v1/leave/employee/{id}/decision`
- **Status:** NEW (BG-31).

### 6. Data Model
`cache_pending_emp_leaves`.

### 7. Offline Behavior
Queued.

### 8. Push Notifications
Emits `LEAVE_DECISION` (final-approver-only) and `LEAVE_PENDING_APPROVAL` (next approver).

### 9. Permissions & Security
- Approver-only by workflow lookup.
- Audit: `EMPLOYEE_LEAVE_DECISION`.

### 10. Non-Functional Requirements
- Decision perceived < 200 ms.

### 11. Acceptance Criteria
- **AC-103.1** Skipping levels rejected.
- **AC-103.2** Re-approving a finalized leave returns 409.

### 12. Dependencies
- F-102. BG-31.

### 13. Out of Scope
- Delegation when approver on leave — v1.1.

---

## F-110: Library Catalog Browse (P1)

### 1. Overview
Browse / search library catalog with availability and reservation state.

### 2. User Stories
- **US-110.1** *As a student, I search "Hindi novel" and see available copies.*
- **US-110.2** *As a parent / student, I reserve an available book.*

### 3. Functional Requirements
- **FR-110.1** Endpoint paginated; query: title / author / ISBN / category.
- **FR-110.2** Availability counts per book.
- **FR-110.3** Reservation: `POST /library/catalog/{book_id}/reserve` (P1+).

### 4. Screen Specifications
Search + grid.

### 5. API Contracts

#### `GET /api/mobile/v1/library/catalog?q=&page=`
- **Status:** REUSE. Module: Library (FULL).

### 6. Data Model
`cache_library_search`.

### 7. Offline Behavior
Recent searches cached.

### 8. Push Notifications
None.

### 9. Permissions & Security
- Read-only public to authenticated users; no PII concerns.

### 10. Non-Functional Requirements
- Search returns < 1.5 s.
- Localization: `f110.placeholder.search`.

### 11. Acceptance Criteria
- **AC-110.1** Empty search returns first 20 sorted by recently-added.

### 12. Dependencies
- F-002.

### 13. Out of Scope
- E-book reading — v1.2.

---

## F-111: My Books / Borrow History (P1)

### 1. Overview
List of currently borrowed + history. Due-date countdown, fines (if any).

### 2. User Stories
- **US-111.1** *As a student, I see I have a book due in 2 days.*
- **US-111.2** *I see history of last term's books.*

### 3. Functional Requirements
- **FR-111.1** Endpoint scoped to authenticated student / employee.
- **FR-111.2** Due-soon push T-2d.

### 4. Screen Specifications
Tabs: Current / History.

### 5. API Contracts

#### `GET /api/mobile/v1/library/me/borrowed`
- **Status:** REUSE.

### 6. Data Model
`cache_my_borrowed`.

### 7. Offline Behavior
Read-only cached.

### 8. Push Notifications
Consumes `LIBRARY_DUE_SOON`.

### 9. Permissions & Security
- Self-scoped.
- Audit: not logged.

### 10. Non-Functional Requirements
- Cached < 200 ms.

### 11. Acceptance Criteria
- **AC-111.1** Tampered student_id (other user) → 403.

### 12. Dependencies
- F-110.

### 13. Out of Scope
- Fine payment integration on mobile — v1.1.

---

## F-120: Hostel Pass / Leave Request (Boarder, P2)

### 1. Overview
Boarder requests a leave pass / day-out. Pre-req: BG-30 (Hostel module — PLANNED, DDL v3 ready, D34).

### 2. User Stories
- **US-120.1** *As a boarder, I request weekend pass; warden + parent approve.*

### 3. Functional Requirements
- **FR-120.1** Pass types: DAY_OUT, WEEKEND, MEDICAL, EMERGENCY.
- **FR-120.2** Approval chain: warden → (parent ack) → final.
- **FR-120.3** Status: `REQUESTED → WARDEN_APPROVED → PARENT_ACKED → ISSUED → CONSUMED | REJECTED`.

### 4. Screen Specifications
Form + status timeline.

### 5. API Contracts

#### `POST /api/mobile/v1/hostel/leave-pass/apply`
- **Status:** NEW (BG-30). Module: Hostel (PLANNED).

### 6. Data Model
`cache_my_passes`.

### 7. Offline Behavior
Queued submit.

### 8. Push Notifications
Emits `HOSTEL_PASS_DECISION` to boarder + parent.

### 9. Permissions & Security
- Boarder-self.
- Audit: `HOSTEL_PASS_*`.

### 10. Non-Functional Requirements
- Submit perceived < 200 ms.

### 11. Acceptance Criteria
- **AC-120.1** Non-boarder → 403.
- **AC-120.2** Pass cannot be issued without parent ack (state-machine enforced).

### 12. Dependencies
- F-002. BG-30.

### 13. Out of Scope
- Late-return penalty workflow — v1.1.

---

## F-121: Hostel Notifications (Mess opt-out, Sick-bay, P2)

### 1. Overview
Boarder-specific events: mess opt-out for a meal, sick-bay alerts to parent.

### 2. User Stories
- **US-121.1** *As a boarder, I opt-out of dinner today via 1 tap.*
- **US-121.2** *As a parent, I get a push if my child is in sick-bay.*

### 3. Functional Requirements
- **FR-121.1** Mess opt-out: `POST /hostel/mess/optout` `{ meal:LUNCH|DINNER, date }`.
- **FR-121.2** Cutoff time enforced (e.g. 1 h before meal).
- **FR-121.3** Sick-bay alert read-only on mobile (warden-side write on web).

### 4. Screen Specifications
Two cards: opt-out status, sick-bay status.

### 5. API Contracts

#### `POST /api/mobile/v1/hostel/mess/optout`
#### `GET /api/mobile/v1/hostel/notifications/me`
- **Status:** NEW (BG-30).

### 6. Data Model
`cache_hostel_status`.

### 7. Offline Behavior
Queued opt-out (subject to cutoff at sync time — server may reject if cutoff passed).

### 8. Push Notifications
Emits `HOSTEL_SICKBAY_ALERT` (parent).

### 9. Permissions & Security
- Boarder + parent scoping.
- Audit: `MESS_OPTOUT`, `SICKBAY_VIEW`.

### 10. Non-Functional Requirements
- Localization: `f121.cta.optout`, `f121.cutoff.warning`.

### 11. Acceptance Criteria
- **AC-121.1** Opt-out after cutoff → 400.

### 12. Dependencies
- BG-30.

### 13. Out of Scope
- Mess menu rating — v1.2.

---

> End Batch 08. Continue to `02_mobile_srs_batch_09.md` (Profile, Settings, Search).
