# STP — Student Portal
## Complete Analysis Pack v1.0

**Date:** 2026-06-30 | **Module Code:** STP | **Module Name:** StudentPortal
**FRD Reference:** `STP_FRD_2026-06-30.md` (same directory — all REQ-/BR-/RPT-/ENH- IDs are sourced from it)
**Sources:** V2 Requirement (2026-03-26) · Module Knowledge (2026-06-30) · Laravel codebase (`Modules/StudentPortal/`, verified 2026-06-30) · Portal Architecture Memory (2026-04-02)

---

## Table of Contents

| Section | Artifact |
|---------|---------|
| A | FRD Reference + Executive Summary |
| B | Requirements Traceability Matrix (RTM) |
| C | Business Rules Register + Requirement Conditions Catalog + Validation & Edge-Case Catalog |
| D | Process Flows + FSM Catalog |
| E | Data Dictionary (Business View) + Cross-Module Dependency Map |
| F | NFR Catalog + Risk Register |
| G | Prioritization (MoSCoW) + Effort Estimation & Sprint Task Breakdown |
| H | User Stories + Acceptance Criteria (P0/P1 REQs) + Reporting & KPI Spec |
| I | Module Knowledge Reference |

---

## Section A: FRD Reference & Executive Summary

**FRD File:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/STP_FRD_2026-06-30.md`

### Module Snapshot

| Attribute | Value |
|-----------|-------|
| Module Code | STP |
| Module Name | StudentPortal |
| Table Prefix | `lms_*` (7 owned tables); consumes 32+ external tables from 17 source modules |
| DB Layer | Tenant (`tenant_{uuid}`) — data isolated per school |
| Completion | ~75–80% as of 2026-06-30 (CLAUDE.md incorrectly labels it "Pending") |
| Controllers | 37 total: 18 web + 19 mobile |
| Models | 11 (all STP-owned attempt engine: ExamAttempt, QuizQuestAttempt, ExamGrievance, AttemptCheckpoint, AttemptActivityLog, ExamAttemptAnswer, QuizQuestAttemptAnswer, ExamResult, ExamMarksEntry, QuizQuestResult, AttemptActivityEventType) |
| FormRequests | 5 (RespondToLeaveRemarkRequest, SaveAnswerRequest, StartAttemptRequest, StoreLeaveApplicationRequest, SubmitAttemptRequest) |
| Services | 1 (AllocationService — paper set assignment at exam start) |
| Traits | 2 (StudentAttemptTrait, ResolvesMobileStudent) |
| Console Commands | 1 (TimeoutStaleAttempts — auto-submits stale exam attempts) |
| Blade Views | ~99 across 36 feature areas |
| Tests | 9 (5 Feature + 4 Unit) |
| Web Route Lines | ~150 across web.php |
| Mobile API Routes | ~45 in mobile_api.php |
| P0 Blockers | 4 (IDOR in proceedPayment, zero Gate::authorize(), missing EnsureTenantHasModule, hard-coded dropdown ID 104) |

### FRD Totals (from Section 10.4)
- **REQ:** 35 (P0: 14 | P1: 18 | P2: 3)
- **BR:** 35
- **RPT:** 7
- **ENH:** 10

---

## Section B: Requirements Traceability Matrix (RTM)

| REQ-ID | Feature Name | Priority | BR Refs | Key Screen(s) | Workflow | Report(s) | Test IDs | Code Status | Gap |
|--------|-------------|---------|---------|--------------|---------|----------|---------|------------|-----|
| REQ-STP-001 | Student Authentication | P0 | BR-STP-001, 027 | Student Login | WF-1 (entry) | — | T-STP-003, 004 | ✅ | ENH-STP-001 (rate limiting) |
| REQ-STP-002 | Dashboard | P0 | BR-STP-001, 019, 021 | Dashboard | — | — | T-STP-010–013 | ✅ | ENH-STP-005 (service extract) |
| REQ-STP-003 | Academic Information | P1 | BR-STP-001 | Academic Info Hub | — | — | — | 🟡 | Profile tab complete; certifications tab stub |
| REQ-STP-004 | Fee Invoice View | P0 | BR-STP-001, 002 | Invoice View | — | — | T-STP-001 | 🟡 | SEC-STP-13 (ownership guard may fail) |
| REQ-STP-005 | Fee Payment | P0 | BR-STP-001–010 | Payment Page, Proceed | WF-1 | — | T-STP-002 | 🟡 | SEC-STP-01 (IDOR in proceedPayment) |
| REQ-STP-006 | Fee Summary | P1 | BR-STP-001 | Fee Summary | — | — | — | ✅ | — |
| REQ-STP-007 | Attendance View | P0 | BR-STP-001, 014, 015 | Attendance | — | — | T-STP-014 | ✅ | BR-STP-015 (normalization incomplete) |
| REQ-STP-008 | Timetable View | P0 | BR-STP-011–013 | Timetable | — | — | T-STP-010 | ✅ | — |
| REQ-STP-009 | Exam Schedule | P0 | BR-STP-001, 021 | Exam Schedule | — | — | — | ✅ | — |
| REQ-STP-010 | Results View | P0 | BR-STP-001, 021 | Results | — | — | T-STP-024 | 🟡 | GAP-STP-05: no marks shown |
| REQ-STP-011 | My Learning Hub | P0 | BR-STP-019–021 | Learning Hub | — | — | — | ✅ | — |
| REQ-STP-012 | Homework + Submission | P0 | BR-STP-001, 019, 022 | Homework List, Homework Detail | WF-4 (related) | — | — | ✅ | — |
| REQ-STP-013 | Syllabus Progress | P1 | BR-STP-001 | Syllabus Progress | — | — | T-STP-020 | ✅ | — |
| REQ-STP-014 | My Teachers | P1 | BR-STP-001 | Teachers Directory | — | — | T-STP-021 | ✅ | — |
| REQ-STP-015 | Progress Card (HPC) | P1 | BR-STP-001, 023 | Progress Card | — | RPT-STP-005 | T-STP-024 | ✅ (no PDF link) | GAP-STP-15 |
| REQ-STP-016 | Performance Analytics | P1 | BR-STP-001 | Analytics | — | RPT-STP-007 | — | 🟡 | Subject-wise charts missing |
| REQ-STP-017 | Recommendations | P1 | BR-STP-001 | Recommendations List, Detail | — | — | — | ✅ | — |
| REQ-STP-018 | Library Integration | P1 | BR-STP-001, 033, 034 | Library Catalogue, My Books | — | — | T-STP-022 | ✅ | Hard coupling to Library controller |
| REQ-STP-019 | Transport Information | P1 | BR-STP-001 | Transport | — | — | T-STP-023 | ✅ | — |
| REQ-STP-020 | Health Records | P1 | BR-STP-001 | Health | — | — | — | ✅ | — |
| REQ-STP-021 | Student ID Card | P1 | BR-STP-001 | ID Card | — | RPT-STP-004 | — | 🟡 | PDF route not defined |
| REQ-STP-022 | Study Resources + Books | P1 | BR-STP-001 | Study Resources, Prescribed Books | — | — | — | ✅ | — |
| REQ-STP-023 | Notice Board | P1 | BR-STP-031, 034 | Notice Board | — | — | — | 🟡 | GAP-STP-07: wrong data source |
| REQ-STP-024 | School Calendar | P2 | — | School Calendar | — | — | — | ❌ | No data wired |
| REQ-STP-025 | Student Leave Application | P1 | BR-STP-028, 029 | Leave List, Leave Create, Leave Detail | WF-3 | — | T-STP-015 | ✅ | — |
| REQ-STP-026 | Hostel Information | P2 | — | Hostel | — | — | — | ❌ | Blocked on HST module |
| REQ-STP-027 | Notifications Inbox | P0 | BR-STP-030, 031 | Notifications | — | — | T-STP-005, 018 | ✅ (method bug) | BR-STP-032: mark-read uses GET |
| REQ-STP-028 | Complaints | P0 | BR-STP-016–019 | Complaint List, Create | WF-4 | — | T-STP-015, 016 | ✅ (ID bug + no pagination) | SEC-STP-04; GAP-STP-10 |
| REQ-STP-029 | Account Settings | P2 | BR-STP-035, 036 | Account Settings (tabs) | — | — | — | 🟡 | Backend stubs |
| REQ-STP-030 | Online Exam Player | P0 | BR-STP-023–026 | Instructions, Attempt, Result | WF-2 | RPT-STP-001 | T-STP-001 (IDOR related) | ✅ | — |
| REQ-STP-031 | Quiz Player | P0 | BR-STP-027, 020 | Quiz Instructions, Attempt, Result | WF-2 (pattern) | RPT-STP-002 | — | ✅ | — |
| REQ-STP-032 | Quest Player | P0 | BR-STP-028, 020 | Quest Instructions, Attempt, Result | WF-2 (pattern) | RPT-STP-003 | — | ✅ | — |
| REQ-STP-033 | Exam Grievances | P1 | BR-STP-029, 030 | Grievance Create, My Grievances | — | — | — | ✅ | — |
| REQ-STP-034 | Mobile API | P1 | BR-STP-001 | (all via API) | All | — | — | ✅ 80% | Dead api.php scaffold |
| REQ-STP-035 | Parent Portal Mode | P1 | BR-STP-004, 005 | Dashboard (parent view) | — | — | — | 🟡 | Child switcher not built |

---

## Section C: Business Rules Register + Conditions Catalog + Validation Catalog

> All BR IDs are defined in FRD Section 4. This section adds the full enforcement specifications.

### C.1 Requirement Conditions Catalog

> Also saved to: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/5-Requirement_Conditions/STP_Conditions.md`

| Condition ID | Entity / Field | Condition (Business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| BR-STP-001 | Student data (any) | Data must belong to the authenticated student | Permission | Every controller data-fetch | 404 Not Found or 403 Forbidden; never show another student's data |
| BR-STP-002 | Fee Invoice | Ownership verified via fee assignment chain | Validation | Invoice view / payment initiation | 404 Not Found |
| BR-STP-003 | payable_id (payment POST) | Server-side ownership check before Razorpay order | Validation | proceedPayment POST | 403 Forbidden; Razorpay order not created |
| BR-STP-004 | Guardian-child link | can_access_parent_portal = true in junction | Permission | Every parent data request | 403 Forbidden |
| BR-STP-006 | Fee Invoice status | Status must be Published, Partially Paid, or Overdue | Validation | Payment page load | Redirect to invoice view with "Invoice cannot be paid" message |
| BR-STP-007 | Payment amount | 1 ≤ amount ≤ remaining balance | Validation | Payment form submit | 422 Unprocessable — field error shown |
| BR-STP-008 | Payment gateway | Must be Active status | Validation | Payment page gateway list | Inactive gateways are excluded from the select list |
| BR-STP-010 | Payment attempts | Max 3 per 5 minutes per user | Concurrency | Payment POST route | 429 Too Many Requests |
| BR-STP-013 | Timetable cells | is_break = true cells excluded | Validation | Timetable grid build | Filtered out before rendering |
| BR-STP-015 | Attendance status | Normalized to Present/Absent/Late/On Leave | Calculation | Attendance view render | Normalization applied via model accessor |
| BR-STP-018 | Dropdown ID for complaints | Looked up by string key, not hardcoded integer | Validation | Complaint create/store | If lookup fails: validation error shown |
| BR-STP-020 | Quiz/Quest allocation cut-off | Expired allocations excluded | Validation | Learning hub, quiz/quest index | Allocation not shown; attempt start refused |
| BR-STP-022 | Homework late submission | restrict_late_submission = true gates submission | Validation | Homework detail / submit | Submit form hidden after due date |
| BR-STP-023 | Exam attempt uniqueness | One attempt per student per paper | Concurrency | Exam player start | DB UNIQUE constraint violation → redirect to existing attempt |
| BR-STP-024 | Attempt status for answers | Only IN_PROGRESS attempts accept saves | Workflow | save-answer, checkpoint | 422 or 409 — "Attempt not in progress" |
| BR-STP-027 | Quiz max attempts | attempt_number < max_attempts | Validation | Quiz start | "Maximum attempts reached" — start button disabled |
| BR-STP-029 | Grievance eligibility | Student must have SUBMITTED or EVALUATED attempt | Permission | Grievance create | 403 if no eligible attempt |
| BR-STP-031 | Notice board data source | Official announcement model, not notification inbox | Validation | Notice board page load | Wrong source produces misleading data; must be corrected |
| BR-STP-032 | Notification mark-read HTTP method | Must be POST or PATCH | Validation | Notifications mark-read route | GET requests may be pre-fetched by browsers — data integrity risk |
| BR-STP-035 | Password change verification | Current password must match | Validation | Account settings security tab | 422 — "Current password is incorrect" |

### C.2 Validation & Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty / Null | Concurrency Case | Expected Behaviour |
|-------------|--------------|----------------|---------|-------------|-----------------|-------------------|
| Fee payable_id | Student A's own invoice ID | Student B's invoice ID | Invoice at zero balance | Missing from POST body | Two simultaneous payments on same invoice | Server verifies ownership; zero-balance rejected; second payment creates duplicate Razorpay order (Razorpay deduplication handles) |
| Payment amount | INR 500 on INR 800 balance | INR 0, INR -100, INR 900 on INR 800 balance | INR 1 (minimum), exact balance (maximum) | Missing | — | Outside range → 422 with field error |
| Homework file upload | 9.5 MB PDF | 11 MB MP4 | 10 MB exact | No file (text-only submission allowed) | Two submissions simultaneously | Over 10 MB → 422; unsupported type → 422; duplicate submission → upsert submission record |
| Exam attempt start | First attempt on a valid paper | Attempt on a paper already SUBMITTED | — | Student has no active academic session | Two tabs start simultaneously | Already submitted → redirect to result; no session → empty state; race condition → second start hits UNIQUE constraint, returns existing attempt |
| Leave start date | Tomorrow (future) | Yesterday | Today (same day — allowed) | Missing | — | Past date → 422 |
| Complaint description | "The canteen food was spoiled last Tuesday." | 1-character entry | 10,000 characters | Empty string | — | Short text → 422 (minimum length); long text → truncate or 422 |
| Complaint attachment | 4.9 MB PDF | 6 MB PNG, .exe file | 5 MB exact | No file | — | Unsupported MIME → 422; over 5 MB → 422 |
| Notification mark-read | Valid notification belonging to the user | Notification belonging to another user | — | Non-existent notification ID | Two tabs mark-read simultaneously | Foreign notification → 403 or no-op; non-existent → 404; race → both succeed (idempotent) |
| Attendance status value | "Present" | "PRS" (unknown code) | — | NULL | — | Unknown code → display as Unknown; NULL → display as Not Marked |
| Timetable with no school days | — | — | Single-day school week | No school days configured | — | Renders empty grid with "No school days configured" message |
| Student with no academic session | — | — | — | student.currentSession() returns null | — | All session-scoped screens render a "No active session" empty state |

---

## Section D: Process Flows + FSM Catalog

### D.1 FSM: Fee Invoice Status

| From State | Event / Action | Guard | To State | Side-Effects |
|-----------|---------------|-------|---------|-------------|
| (not created) | Admin publishes fee invoice | Fee assignment exists | Published | Notification to student: "Your invoice is ready" |
| Published | Student makes partial payment | amount < balance | Partially Paid | Receipt created; invoice balance updated |
| Published | Student makes full payment | amount = balance | Paid | Receipt created; balance = 0; notification: "Invoice paid" |
| Partially Paid | Student makes further payment | amount ≤ remaining balance | Partially Paid or Paid | As above |
| Published / Partially Paid | Due date passes | today > due_date | Overdue | Fine may be applied per fee structure rules |
| Overdue | Student makes full payment | — | Paid | — |
| Any | Admin cancels invoice | — | Cancelled | No refund from portal; contact admin |

**Terminal states:** Paid, Cancelled
**Illegal transitions (must be blocked):** Student → Paid (direct); Payment module redirect → any status change (only webhook can update)

---

### D.2 FSM: Exam Attempt Status

| From State | Event / Action | Guard | To State | Side-Effects |
|-----------|---------------|-------|---------|-------------|
| NOT_STARTED | Allocation created for student | — | NOT_STARTED | — |
| NOT_STARTED | Student POSTs /start | Allocation is Published + student targeted | IN_PROGRESS | Attempt record created; paper set allocated; checkpoint created |
| IN_PROGRESS | Student POSTs /submit | — | SUBMITTED | End time recorded; answers frozen; redirect to result |
| IN_PROGRESS | Timer expires (client or server) | elapsed > time_limit | SUBMITTED / TIMEOUT | TimeoutStaleAttempts auto-submits |
| IN_PROGRESS | Student abandons (no action, past timeout) | detected by cron | TIMEOUT | `TimeoutStaleAttempts` transitions; answers as entered are used for evaluation |
| SUBMITTED | Admin evaluates | — | EVALUATED | Marks entered in `lms_exam_results` |
| EVALUATED | Admin publishes result | — | RESULT_PUBLISHED | Notification to student: "Your result is published" |
| — | Admin cancels exam | — | CANCELLED | All IN_PROGRESS attempts cancelled |
| — | Student was absent | — | ABSENT | Manually set by admin |

**Terminal states for student:** SUBMITTED, TIMEOUT, ABSENT, CANCELLED
**Illegal transitions:** Student → EVALUATED (only admin can evaluate); SUBMITTED → IN_PROGRESS (resumption after submit forbidden)

---

### D.3 FSM: Quiz/Quest Attempt Status

| From State | Event / Action | Guard | To State | Side-Effects |
|-----------|---------------|-------|---------|-------------|
| NOT_STARTED | Student opens quiz/quest | Allocation valid + max_attempts not reached | NOT_STARTED | — |
| NOT_STARTED | Student POSTs /start | — | IN_PROGRESS | Attempt record created (attempt_number incremented) |
| IN_PROGRESS | Student POSTs /submit | — | SUBMITTED | Score computed; result shown |
| IN_PROGRESS | Timer expires | — | SUBMITTED / TIMEOUT | Auto-submit with current answers |
| SUBMITTED | Reassignment by teacher | max_attempts check | REASSIGNED | New attempt allowed |
| Any | Student abandons (closes browser, no resume) | timeout exceeded | ABANDONED | No score |

---

### D.4 FSM: Leave Application Status

| From State | Event / Action | Guard | To State | Side-Effects |
|-----------|---------------|-------|---------|-------------|
| (new) | Student submits leave form | Valid dates + future start date | Pending | Application created; notification to admin |
| Pending | Admin approves | — | Approved | Notification to student: "Leave approved" |
| Pending | Admin rejects | — | Rejected | Notification to student: "Leave rejected" + reason |
| Pending | Student cancels | — | Cancelled | Application cancelled; no further action |
| Approved | Leave period ends | Date-based | (no state change) | System notes leave taken |

**Terminal states:** Approved (after dates pass), Rejected, Cancelled
**Illegal transitions:** Student cannot move from Approved or Rejected to any other state

---

### D.5 FSM: Exam Grievance Status

| From State | Event / Action | Guard | To State | Side-Effects |
|-----------|---------------|-------|---------|-------------|
| (new) | Student submits grievance | Has SUBMITTED/EVALUATED attempt | Open | Grievance created; notification to admin |
| Open | Admin picks up grievance | — | Under Review | — |
| Under Review | Admin resolves (no mark change) | — | Resolved | `marks_changed = false`; notification to student |
| Under Review | Admin resolves (mark change) | — | Resolved | `marks_changed = true`; old_marks, new_marks recorded; exam result updated |
| Under Review | Admin rejects | — | Rejected | Reason recorded; notification to student |

---

## Section E: Data Dictionary (Business View) + Cross-Module Dependency Map

### E.1 Data Dictionary — STP-Owned Entities

#### Exam Attempt

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|---------|----------------|------|
| Attempt Number | Unique internal ID | Integer | Yes | Auto-generated | No |
| Student | The student who took the exam | FK | Yes | Active students | Yes |
| Exam Paper | Which exam paper this attempt covers | FK | Yes | Published papers | No |
| Paper Set | The randomized version of the paper assigned to this student | FK | Yes | Allocated by system | No |
| Attempt Mode | How the exam was attempted | Dropdown | Yes | Online, Offline | No |
| Status | Current state of the attempt | Dropdown | Yes | Not Started, In Progress, Submitted, Evaluated, Result Published, Timeout, Absent, Cancelled | No |
| Violation Count | Number of anti-cheat violations detected (tab switches, etc.) | Integer | No | 0+ | No |
| Start Time | When the student officially started the exam | DateTime | No | — | No |
| Actual End Time | When the student submitted or timed out | DateTime | No | — | No |
| IP Address | Network address at the time of submission | Text | No | — | Sensitive |
| Browser Info | Browser and device at submission | Text | No | — | No |

#### Attempt Checkpoint

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|---------|----------------|------|
| Attempt Type | Whether this checkpoint belongs to an exam, quiz, or quest | Dropdown | Yes | Exam, Quiz, Quest | No |
| Attempt Reference | The specific attempt this checkpoint tracks | FK (polymorphic) | Yes | — | No |
| Current Question Position | The question number the student was last on | Integer | Yes | 1 to paper length | No |
| Answered Questions | JSON list of question IDs answered so far | JSON | No | — | Confidential |
| Flagged Questions | JSON list of question IDs flagged for review | JSON | No | — | No |
| Checkpoint Data | Full state snapshot for resume (answers, timer, position) | JSON | No | — | Confidential |
| Last Saved At | When this checkpoint was last updated | DateTime | Yes | — | No |

#### Exam Grievance

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|---------|----------------|------|
| Student | The student raising the grievance | FK | Yes | — | Yes |
| Exam Paper | The exam paper in question | FK | Yes | — | No |
| Grievance Type | Nature of the grievance | Dropdown | Yes | Marking Error, Out of Syllabus, Question Error, Other | No |
| Description | Student's detailed explanation | Text | Yes | — | Confidential |
| Status | Resolution status | Dropdown | Yes | Open, Under Review, Resolved, Rejected | No |
| Marks Changed | Whether resolution resulted in a mark revision | Yes/No | No | — | No |
| Original Marks | Marks before resolution | Decimal | No | — | Confidential |
| Revised Marks | Marks after resolution | Decimal | No | — | Confidential |
| Resolution Note | Admin's explanation of the resolution | Text | No | — | Internal |

### E.2 Cross-Module Dependency Map

#### STP Reads From (Inbound Dependencies)

| Source Module | Data / Entity | Why STP Needs It |
|--------------|--------------|-----------------|
| StudentProfile (STD) | Student identity, profile, guardians, addresses, academic session, health, attendance | Core identity chain; all portal screens derive from this |
| StudentFee (FIN) | Fee assignments, fee invoices | Fee summary, invoice view, payment initiation |
| Payment | PaymentService API, payment gateways | Razorpay checkout creation |
| Notification | User notifications (Laravel Notifiable) | Notifications inbox; notification count on dashboard header |
| Complaint (CMP) | Complaint records, categories | Complaint listing and submission |
| SmartTimetable / TimetableFoundation | Timetable cells, school days | Timetable grid, teachers directory, timetable widget on dashboard |
| LmsExam | Exam allocations, exam papers, paper sets, exam results | Exam schedule, online exam player, results view |
| LmsHomework | Homework records, submission records | Homework list, homework submission, dashboard homework widget |
| LmsQuiz | Quiz records, quiz allocations | Quiz player, learning hub |
| LmsQuests | Quest records, quest allocations | Quest player, learning hub |
| QuestionBank | Questions, answer options | Online exam/quiz/quest player (question rendering) |
| Syllabus | Syllabus schedule records | Syllabus progress tracker |
| HPC | HPC report records | Progress card screen |
| Recommendation (REC) | Student recommendation records | My Recommendations screen |
| Library (LIB) | Book master records, library memberships, transactions | Library browse, my borrowed books, reserve/renew/digital access |
| Transport (TPT) | Student transport allocations, routes, stops | Transport information screen |
| SyllabusBooks (BOK) | Prescribed books, book-class-subject mapping | Study resources, prescribed books screen |
| Hostel (HST) | Hostel room allocations, mess schedule | Hostel screen (planned — stub only) |
| SystemConfig | Dropdown values, user auth record | Complaint form dropdowns, authentication identity |

#### STP Provides To (Outbound Data)

| Target Module | Data / Mechanism | Notes |
|--------------|-----------------|-------|
| LmsExam | `lms_exam_attempts`, `lms_exam_attempt_answers`, `lms_exam_grievances` | STP creates attempt records; LmsExam admin uses them for evaluation and mark entry |
| LmsQuiz | `lms_quiz_quest_attempts` (assessment_type=QUIZ), `lms_quiz_quest_attempt_answers` | STP creates quiz attempt records; LmsQuiz admin reads them for reporting |
| LmsQuests | `lms_quiz_quest_attempts` (assessment_type=QUEST), `lms_quiz_quest_attempt_answers` | STP creates quest attempt records; LmsQuests admin reads them for badge/completion reporting |
| Payment | Payment initiation payload (student, amount, payable_id, gateway) | STP calls PaymentService to create Razorpay orders |

#### Cross-Module Events / Integration Points

| Integration | Mechanism | Direction |
|------------|----------|---------|
| Fee payment status update | Razorpay webhook → Payment module → fee invoice update | Payment → StudentFee |
| Attempt auto-timeout | `TimeoutStaleAttempts` Artisan command (scheduled) | STP internal cron |
| Library wishlist toggle | Direct class reference to `LibWishlistController` | STP → Library (hard coupling — flagged for refactoring) |
| Notification delivery | Laravel Notifiable on `sys_users` | Notification module → STP reads |
| Result publication | LmsExam publishes result → student can view in STP | LmsExam → STP reads |

---

## Section F: NFR Catalog + Risk Register

### F.1 NFR Catalog

| NFR-ID | Category | Requirement | Acceptance Threshold |
|--------|---------|------------|-------------------|
| NFR-STP-001 | Performance | Dashboard page load time | < 2 seconds for a student with complete data |
| NFR-STP-002 | Performance | Exam answer-save and checkpoint endpoint response | < 500 ms (timed exam UX critical) |
| NFR-STP-003 | Performance | Library catalogue, complaint listing, notification inbox paginated | All paginated; no unbounded `->get()` calls |
| NFR-STP-004 | Performance | Dashboard data loaded in a single eager-load chain | Zero N+1 queries in `StudentPortalController::dashboard()` |
| NFR-STP-005 | Scalability | Exam attempt engine supports concurrent students | 500 concurrent students per tenant taking online exams; DB unique constraint is the concurrency guard |
| NFR-STP-006 | Security | IDOR prevention | Zero cross-student data exposures; verified by T-STP-001 through T-STP-005 |
| NFR-STP-007 | Security | EnsureTenantHasModule applied | StudentPortal routes inaccessible when module is not in tenant's plan |
| NFR-STP-008 | Security | No stack traces shown to students | All exceptions render student-friendly error pages |
| NFR-STP-009 | Security | File uploads validated | MIME and size validated on all upload endpoints |
| NFR-STP-010 | Security | Login rate limiting | 5 attempts per 2 minutes on the login POST route |
| NFR-STP-011 | Security | Payment PCI DSS | No card data stored by the application; Razorpay tokenization used |
| NFR-STP-012 | Usability | Responsive design | Usable on mobile browser (320 px minimum width) without native app |
| NFR-STP-013 | Usability | Student-friendly error messages | No technical error codes or database error strings visible |
| NFR-STP-014 | Usability | Exam player timer warning | 5-minute countdown warning before timer expires |
| NFR-STP-015 | Availability | Portal uptime | 99.5% during school hours (8 AM – 6 PM IST); tenant-level SLA |
| NFR-STP-016 | Compliance | DPDP Act 2023 | Data minimization; student data accessed only for stated portal purposes; cross-student access is zero-tolerance |
| NFR-STP-017 | Compliance | Razorpay compliance | Payment integration follows Razorpay's PCI DSS and RBI guidelines |

### F.2 Risk Register

| Risk ID | Risk | Category | Likelihood | Impact | Mitigation | Owner | Early Warning |
|---------|------|---------|-----------|--------|-----------|-------|--------------|
| RISK-STP-001 | IDOR in `proceedPayment()` exploited before fix: Student A pays from Student B's invoice, causing fee balance inconsistency | Security | High | High | Fix: server-side ownership check before Razorpay order; P0 priority | Dev Lead | Any payment mismatch in fee receipts |
| RISK-STP-002 | `EnsureTenantHasModule` absent: school that has not subscribed to StudentPortal can still access all portal routes | Security | Medium | High | Add middleware to RouteServiceProvider portal group | Dev Lead | Support ticket: "why can students access portal?" |
| RISK-STP-003 | Exam attempt state corruption: a student who crashes mid-exam cannot resume and loses answers | Data Integrity | Medium | High | Checkpoint system already in place; ensure `TimeoutStaleAttempts` is scheduled and tested | QA | Student complaints about lost exam progress |
| RISK-STP-004 | Library wishlist hard coupling: Library module rename or disable causes STP routes to fail | Architecture | Low | Medium | Replace direct controller reference with an event or shared service call | Dev Lead | Library module refactoring ticket |
| RISK-STP-005 | `TimeoutStaleAttempts` not registered in Scheduler: stale IN_PROGRESS attempts never auto-submit; students get stuck | Operations | Medium | High | Verify command is registered in `app/Console/Kernel.php` or `routes/console.php` | DevOps | IN_PROGRESS attempts accumulating without submission |
| RISK-STP-006 | `currentFeeAssignemnt` model typo causes silent null in 3 controller methods if relationship is renamed | Bug | Low | Medium | Fix typo; add unit test asserting the relationship returns the expected object | Dev | Fee widgets showing zero or blank data |
| RISK-STP-007 | Results screen (`/student-portal/results`) shows no marks; students escalate via complaints | UX/Product | High | Medium | Integrate `lms_exam_results` model into results controller; P1 priority | Dev | High complaint volume about results screen |
| RISK-STP-008 | Notice board shows personal notifications instead of school announcements; students miss official notices | UX/Product | High | Medium | Replace `user()->notifications()` with dedicated announcement model | Dev | Teacher reports "students not seeing circular" |
| RISK-STP-009 | Hard-coded dropdown ID `104` breaks after re-seeding in any environment | Bug | Medium | Medium | Replace with key-based lookup: `sys_dropdowns.where('key', 'COMPLAINANT_STUDENT')` | Dev | Complaint form submission fails with 500 |
| RISK-STP-010 | GET method on `notifications/mark-read` allows browser link pre-fetchers to mark notifications as read | Security | Low | Low | Change route to POST/PATCH | Dev | Students report notifications being auto-read |

---

## Section G: Prioritization + Effort Estimation

### G.1 MoSCoW Prioritization

#### Must (P0 — Production Blockers)

| Item | Justification |
|------|--------------|
| REQ-STP-004, 005: Fee Invoice IDOR fix | SEC-STP-01/13 — critical security; financial data at risk |
| ENH-STP-006: Login rate limiting | Brute-force login protection; absent from current build |
| NFR-STP-007: EnsureTenantHasModule | Subscription enforcement; tenant security boundary |
| BR-STP-018: Replace hard-coded dropdown ID 104 | Production blocker — ID will break after re-seed |
| REQ-STP-010: Results with actual marks | Core student value; current implementation shows nothing |
| REQ-STP-027: Notification mark-read HTTP method fix | Low-risk but semantically incorrect; easy to fix |
| All of: REQ-STP-001, 002, 007, 008, 009, 011, 012, 027, 028, 030, 031, 032 | Core portal value; already implemented — maintain and test |

#### Should (P1 — Current Release)

| Item | Justification |
|------|--------------|
| REQ-STP-023: Notice board data source fix | Students miss official announcements; high UX impact |
| REQ-STP-021: Student ID Card PDF | Common parent request at admission time |
| REQ-STP-015: Progress Card PDF link | HPC module generates the PDF; STP only needs a link |
| REQ-STP-029: Account settings backend (password change, notification preferences) | Student account management is expected |
| ENH-STP-005: StudentPortalService extraction | Enables unit testing of dashboard aggregation |
| ENH-STP-001: Dedicated student auth guard | Stronger session isolation |
| ENH-STP-002: Parent dashboard with child switcher | Multi-child families need this; otherwise portal is unusable for parents |
| REQ-STP-034: Mobile API documentation and dead scaffold removal | Eliminates confusion; enables mobile app integration |
| REQ-STP-035: Parent portal mode completion | Child context validation; fee payment gate for `is_fee_payer` |
| REQ-STP-033: Exam grievances | Already built; ensure grievance-to-result notification works |
| REQ-STP-013, 014, 016, 017, 018, 019, 020, 022, 025: All P1 screens | Already built; regression testing required |

#### Could (P2 — Next Release)

| Item | Justification |
|------|--------------|
| REQ-STP-024: School Calendar | Nice-to-have; requires SchoolSetup event model integration |
| REQ-STP-026: Hostel Information | Blocked on Hostel module readiness |
| ENH-STP-003: Subject-wise performance charts | Analytics enhancement; not core flow |
| ENH-STP-004: Push notifications / FCM | Mobile enhancement; not blocking web portal |
| ENH-STP-007: School Calendar integration | Paired with REQ-STP-024 |
| ENH-STP-008: Hostel integration | Paired with REQ-STP-026 |
| ENH-STP-010: Quest badge/gamification display | LmsQuests enhancement |

#### Won't (this release)

| Item | Justification |
|------|--------------|
| Parent-teacher messaging | Belongs to ParentPortal/CommonChat modules |
| PTM slot booking | Belongs to Ptm module |
| Peer feedback and teacher ratings | Belongs to Feedback module |
| Student-initiated grade challenge (outside grievance) | Requires academic policy changes |

---

### G.2 Effort Estimation & Sprint Task Breakdown

**Estimation basis:** Similar modules (HPC, Complaint, LmsExam) for security/service layer tasks. Assessment attempt engine already complete.

| # | Task | Type | REQ / Gap Ref | Effort (h) | Depends On | Sprint |
|---|------|------|--------------|-----------|-----------|--------|
| 1 | Fix IDOR in `proceedPayment()` — add `whereHas('feeStudentAssignment', ...)` ownership chain | Backend | REQ-STP-005 / SEC-STP-01 | 2 | — | S1 |
| 2 | Verify and fix `viewInvoice()` / `payDueAmount()` ownership guard — confirm correct column chain | Backend | REQ-STP-004 / SEC-STP-13 | 2 | — | S1 |
| 3 | Add `EnsureTenantHasModule:StudentPortal` middleware to RouteServiceProvider portal group | Backend | NFR-STP-007 | 1 | — | S1 |
| 4 | Replace hardcoded dropdown ID `104` with key-based lookup in `StudentPortalComplaintController` | Backend | REQ-STP-028 / SEC-STP-04 | 1 | — | S1 |
| 5 | Change `notifications/{id}/mark-read` from GET to POST/PATCH; update Blade references | Backend/Frontend | REQ-STP-027 / BR-STP-032 | 1 | — | S1 |
| 6 | Fix `PaymentGateway::all()` → `PaymentGateway::active()->get()` | Backend | REQ-STP-005 / BUG-STP-08 | 0.5 | — | S1 |
| 7 | Fix `currentFeeAssignemnt` typo on Student model and update all 3 callers | Backend | GAP across REQs | 1 | — | S1 |
| 8 | Paginate complaint listing: `->paginate(15)->withQueryString()` | Backend | REQ-STP-028 / GAP-STP-10 | 0.5 | — | S1 |
| 9 | Write P0 IDOR security tests (T-STP-001 through T-STP-005) | Testing | SEC-STP-01, 13 | 4 | Tasks 1–2 | S1 |
| 10 | Add login rate limiting: `throttle:5,2` on student portal login POST route | Backend | ENH-STP-006 | 0.5 | — | S1 |
| **S1 Total** | | | | **13.5 h** | | |
| 11 | Integrate `lms_exam_results` into `/student-portal/results` — display obtained marks, percentage, grade | Backend/Frontend | REQ-STP-010 / GAP-STP-05 | 4 | LmsExam result model | S2 |
| 12 | Fix notice board: replace `user()->notifications()` with dedicated announcement model from SchoolSetup | Backend/Frontend | REQ-STP-023 / GAP-STP-07 | 3 | SchoolSetup notice model | S2 |
| 13 | Add Student ID Card PDF route (`/student-portal/student-id-card/download`) using DomPDF | Backend/Frontend | REQ-STP-021 / GAP-STP-16 | 3 | — | S2 |
| 14 | Add Progress Card PDF link: wire HPC module's PDF generation route per report on the progress card page | Frontend | REQ-STP-015 / GAP-STP-15 | 1 | HPC module PDF route | S2 |
| 15 | Extract `StudentDashboardAggregatorService` from `StudentPortalController::dashboard()` | Backend | ENH-STP-005 | 4 | — | S2 |
| 16 | Implement Account Settings backend: password change endpoint + notification preference storage | Backend/Frontend | REQ-STP-029 | 5 | — | S2 |
| 17 | Remove dead `api.php` scaffold; document `mobile_api.php` as canonical mobile API | Backend | REQ-STP-034 / ENH-STP-009 | 1 | — | S2 |
| 18 | Write P1 functional tests (T-STP-010 through T-STP-025) | Testing | Multiple P1 REQs | 6 | S2 tasks | S2 |
| **S2 Total** | | | | **27 h** | | |
| 19 | Implement dedicated student auth guard in `config/auth.php` scoped to `user_type IN ('STUDENT','PARENT')` | Backend | ENH-STP-001 | 3 | — | S3 |
| 20 | Implement parent dashboard with child switcher: detect Parent role → list linked children → select child context | Backend/Frontend | REQ-STP-035 / ENH-STP-002 | 8 | StudentProfile guardian junction | S3 |
| 21 | Implement attendance status normalization accessor on `StudentAttendance` model | Backend | BR-STP-015 | 1 | — | S3 |
| 22 | School calendar: integrate school events and holidays from SchoolSetup; wire FullCalendar.js | Backend/Frontend | REQ-STP-024 / ENH-STP-007 | 5 | SchoolSetup event model | S3 |
| 23 | Refactor library wishlist toggle from direct class coupling to event or shared service call | Backend | ARCH-STP / REQ-STP-018 | 3 | Library module | S3 |
| 24 | Register `TimeoutStaleAttempts` command in Scheduler (if not already registered) | Backend/DevOps | BR-STP-025 / RISK-STP-005 | 1 | — | S3 |
| 25 | Subject-wise performance charts on analytics page | Frontend | ENH-STP-003 | 4 | Exam results data | S4 |
| 26 | Hostel screen integration (when Hostel module is ready) | Backend/Frontend | REQ-STP-026 / ENH-STP-008 | 4 | Hostel module | S4 |
| 27 | Push notifications / FCM integration for mobile | Backend | ENH-STP-004 | 8 | Notification module | S4 |
| **S3–S4 Total** | | | | **37 h** | | |
| **Grand Total** | | | | **~77.5 h (~10 person-days)** | | |

> **Note:** The V2 estimate was 15 person-days (2026-03-26). By 2026-06-30 the module advanced from 55% to ~78%; the remaining effort reduces to approximately 10 person-days. The attempt engine (exam/quiz/quest players) was the largest piece and is now complete.

---

## Section H: User Stories + Reporting & KPI Spec

### H.1 User Stories (P0 REQs — abbreviated set; all include IDOR-critical scenarios)

---

**US-STP-001** | Priority: P0 | REQ: REQ-STP-005
As a student, I want to pay my fee invoice online so that I can settle my dues without visiting the school accounts counter.

Scenario: Successful payment
- Given I am logged in as Student A and have a Published invoice of INR 2,000
- When I navigate to the payment page and enter INR 2,000 with an Active gateway
- Then the system creates a Razorpay order and redirects me to the payment checkout

Scenario: IDOR payment attempt
- Given I am logged in as Student A
- When I POST to proceed-payment with the invoice ID belonging to Student B
- Then the system returns a 403 Forbidden response and does not create a Razorpay order

Scenario: Payment on a paid invoice
- Given my invoice status is Paid
- When I attempt to navigate to the payment page for that invoice
- Then the system renders the invoice as read-only with no payment option

Scenario: Amount exceeds balance
- Given my invoice has a remaining balance of INR 500
- When I submit a payment amount of INR 600
- Then the server rejects the request with a field validation error

Definition of Done: IDOR ownership check implemented and verified by T-STP-002; Razorpay order creation tested in staging; invoice status unchanged after failed/cancelled payment.

---

**US-STP-002** | Priority: P0 | REQ: REQ-STP-030
As a student, I want to take my online exam through the portal so that I can complete my assessment digitally.

Scenario: Normal exam flow
- Given I am logged in and have a Published online exam allocated to my class
- When I navigate to the exam and click "Start Exam"
- Then a timed exam interface appears with my questions, a countdown timer, and an auto-save indicator

Scenario: Browser crash and resume
- Given I am IN_PROGRESS on an exam and my browser crashes
- When I reopen the exam player
- Then I am placed at the question I was last on with all previously saved answers intact

Scenario: Timer expiry
- Given 5 minutes remain on my exam timer
- When the timer reaches zero
- Then the system auto-submits my current answers and I am redirected to the result or "evaluation pending" screen

Scenario: Duplicate attempt blocked
- Given I have already submitted this exam paper
- When I try to navigate to the instructions page again
- Then I am redirected to my result screen, not a new instructions page

Definition of Done: Checkpoint recovery tested; auto-submit by `TimeoutStaleAttempts` verified; UNIQUE constraint on (exam_paper_id, student_id) prevents duplicate attempts.

---

**US-STP-003** | Priority: P0 | REQ: REQ-STP-004
As a student, I want to view my fee invoice securely so that I can see my billing details without any risk of seeing another student's data.

Scenario: Own invoice
- Given I am logged in as Student A
- When I navigate to `/student-portal/view-invoice/{my_invoice_id}`
- Then I see my invoice with all fee components displayed

Scenario: Another student's invoice
- Given I am logged in as Student A
- When I navigate to `/student-portal/view-invoice/{student_B_invoice_id}`
- Then I receive a Not Found response; Student B's data is not shown

Definition of Done: T-STP-001 passes; ownership guard uses `whereHas('feeStudentAssignment', ...)` chain; test confirmed on staging.

---

**US-STP-004** | Priority: P0 | REQ: REQ-STP-027
As a student, I want to manage my notifications so that I can track important school communications.

Scenario: Mark notification read
- Given I have an unread notification
- When I click "Mark as read" (POST request)
- Then the notification is marked read and the unread count decreases by 1

Scenario: Mark another user's notification
- Given I am logged in as Student A
- When I POST to mark Student B's notification as read
- Then the system returns a 403 or silently ignores the request; Student B's notification is unchanged

Scenario: GET request is blocked
- Given the `notifications/{id}/mark-read` route uses GET
- When a browser pre-fetcher accesses the URL
- Then the system returns a Method Not Allowed response (after the GET → POST fix)

Definition of Done: Route changed to POST/PATCH; notification ownership check implemented; T-STP-005 passes.

---

**US-STP-005** | Priority: P0 | REQ: REQ-STP-028
As a student, I want to raise a complaint so that I can report issues to the school management.

Scenario: Successful complaint submission
- Given I select a category, subcategory, and enter a description
- When I submit the complaint form
- Then a complaint record is created with my user ID as the complainant and I see a success message

Scenario: Complainant type resolved correctly
- Given the complainant type for "Student" is keyed as `COMPLAINANT_STUDENT` in the dropdown master
- When the complaint form is processed
- Then the system resolves the complainant type ID by key, not by the hardcoded value 104

Definition of Done: Hardcoded ID 104 removed; key-based lookup tested; T-STP-016 passes.

---

**US-STP-006** | Priority: P1 | REQ: REQ-STP-010
As a student, I want to view my exam results with actual marks so that I know how I performed.

Scenario: Published result
- Given my exam result has been published by the teacher
- When I navigate to `/student-portal/results`
- Then I see my obtained marks, maximum marks, percentage, and grade for that exam

Scenario: Result awaited
- Given an exam has concluded but the result has not been published
- When I navigate to my results
- Then the exam appears with a "Result Awaited" status, not an error

Definition of Done: `lms_exam_results` integrated into results controller; T-STP-024 passes.

---

**US-STP-007** | Priority: P1 | REQ: REQ-STP-025
As a student, I want to apply for leave online so that I do not need to submit a paper form.

Scenario: Valid leave application
- Given I fill in a leave type, start date (tomorrow), end date, and reason
- When I submit the form
- Then a leave application with Pending status is created and I can see it in my leave history

Scenario: Past start date rejected
- Given I enter a start date in the past
- When I submit the form
- Then the server returns a validation error: "Leave start date must be today or a future date"

Scenario: Cancel pending application
- Given I have a Pending leave application
- When I click Cancel
- Then the application status changes to Cancelled and cannot be resubmitted

Definition of Done: `StoreLeaveApplicationRequest` validates start date; cancel endpoint changes status; T-STP-015 passes.

---

**US-STP-008** | Priority: P1 | REQ: REQ-STP-035
As a parent, I want to view my child's academic data so that I can monitor their progress.

Scenario: Parent views linked child's dashboard
- Given I am logged in as a Parent with one linked child who has `can_access_parent_portal = true`
- When I access the portal dashboard
- Then I see my child's attendance, timetable, homework, and fee data

Scenario: Parent tries to view unlinked student
- Given I am logged in as a Parent
- When I attempt to access data for a student not linked to my account
- Then I receive a 403 Forbidden response

Scenario: Parent without fee_payer flag
- Given I am logged in as a Parent with `is_fee_payer = false` on my guardian junction
- When I view my child's invoices
- Then I see the invoice summary but the Pay Now button is not shown

Definition of Done: Guardian junction validation implemented; `is_fee_payer` gate applied; T-STP-008 equivalent passes.

---

### H.2 Reporting & KPI Specification

| KPI | Definition / Formula | Source Data | Target | Cadence |
|-----|---------------------|------------|--------|--------|
| Student Portal Adoption Rate | (Students with at least one login in the last 30 days / Total active students) × 100 | `sys_users` last_login, `std_students` | > 70% within 3 months of launch | Monthly |
| Online Fee Payment Rate | (Invoices paid via portal / Total invoices paid) × 100 | `fee_invoices` payment method | > 40% of fee collections via portal | Monthly |
| Student Portal Session Duration | Average time between login and logout per session | Session logs | > 5 minutes (indicating meaningful engagement) | Weekly |
| Exam Attempt Completion Rate | (SUBMITTED + EVALUATED attempts / Total IN_PROGRESS + SUBMITTED + EVALUATED attempts) × 100 | `lms_exam_attempts` | > 95% | Per exam |
| Complaint Response Time | Average hours from complaint submission to first status change | `cmp_complaints` created_at vs. updated_at | < 48 hours | Weekly |
| Library Portal Usage | Count of book reserves and digital resource accesses via portal per month | `lib_transactions`, `lib_digital_accesses` | > 100 per tenant per month | Monthly |
| Homework Submission Rate | (Homework submissions via portal / Total homework allocations with active students) × 100 | `hmw_homework_submissions`, `hmw_homeworks` | > 60% | Per homework cycle |

---

## Section I: Module Knowledge Reference

The module knowledge file is current as of 2026-06-30 and contains comprehensive details on file counts, DDL table inventory, all known gaps (P0–P3), permission architecture, route registration pattern, V1 screen spec inventory, attempt flow diagrams, design decisions, and lessons learned.

**Path:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/STP_StudentPortal.md`

**Key facts from the knowledge file:**
- Module is ~75–80% complete despite CLAUDE.md labelling it "Pending"
- The module owns 7 `lms_*` tables for the attempt engine (all created 2026-06-16)
- Mobile API tier (19 controllers) was added entirely after V2 was written
- Leave application, full quiz/quest/exam players, library reservation/renewal, homework submission, and recommendation rating were all added post-V2
- Zero `Gate::authorize()` calls in any of the 18 web controllers is the most systemic quality gap
- The library wishlist route has a hard cross-module class coupling that needs architectural correction
- `api.php` is dead scaffold; `mobile_api.php` is the real mobile API

---

## Quality Gate Checklist

- [x] FRD generated and saved first as `STP_FRD_2026-06-30.md`; all sections in this complete file reference its REQ-/BR-/RPT-/ENH- IDs — no parallel numbering invented
- [x] RTM rows reconcile to FRD Section 10.4 totals (35 REQ, 35 BR, 7 RPT, 10 ENH)
- [x] Every P0 REQ has at least one User Story with acceptance criteria (US-STP-001 through US-STP-005)
- [x] P1 REQs with highest user impact have User Stories (US-STP-006 through US-STP-008)
- [x] Conditions/Validation catalog reuses BR- IDs; Sprint tasks reference REQ- and Gap IDs
- [x] Module knowledge file confirmed current (`STP_StudentPortal.md`, 2026-06-30)
- [x] Complete file saved as `STP_FRD_Complete_2026-06-30.md` in flat FRD directory
- [x] Requirement Conditions also saved to `5-Requirement_Conditions/STP_Conditions.md`

---

*Complete Analysis Pack saved: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/STP_FRD_Complete_2026-06-30.md`*
*FRD: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/STP_FRD_2026-06-30.md`*
*Module Knowledge: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/STP_StudentPortal.md`*
*Conditions Catalog: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/5-Requirement_Conditions/STP_Conditions.md`*
