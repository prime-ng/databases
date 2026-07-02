# Module Knowledge — STP: Student Portal
**Seeded:** 2026-06-30 | **Agent:** Business Analyst
**Version:** 1.0

---

## Module Facts

| Attribute | Value |
|-----------|-------|
| Module Name | StudentPortal |
| Module Code | STP |
| Table Prefix | `lms_*` for STP-owned attempt tables (7); consumes `std_*`, `fee_*`, `cmp_*`, `lib_*`, `tpt_*`, etc. — no `stp_*` tables exist |
| Laravel Module Path | `Modules/StudentPortal/` |
| Module Alias | `studentportal` |
| Namespace | `Modules\StudentPortal` |
| DB Layer | **Tenant** — tenant_db (no `tenant_id` column; isolated by DB connection) |
| Domain Scope | Tenant — student and parent/guardian self-service portal |
| V2 Requirement | Exists: `STP_StudentPortal_Requirement.md` (2026-03-26); estimated 55% at time of V2 writing |
| V1 Screen Specs | 34 files in `StudentPortal/` V1 folder |
| CLAUDE.md Status | Listed as "Pending" — **inaccurate; module is substantially built** |
| Actual Completion | **~75–80%** (as of 2026-06-30, verified from filesystem) |
| Auth Pattern | Spatie `role:Student|Parent` middleware at RouteServiceProvider level; **no Gate::authorize() anywhere** |
| Portal Layout | Separate `studentportal::components.layouts.master` — fully isolated from admin backend |
| Mobile API | Full mobile tier: 19 Mobile controllers + comprehensive `mobile_api.php` routes |
| Payment Gateway | Razorpay via `Payment` module `PaymentService::createPayment()` |

### Verified File Counts (from `find Modules/StudentPortal -type f` — 2026-06-30)

| Component | Actual | V2 Said (2026-03-26) | Notes |
|-----------|--------|----------------------|-------|
| Web Controllers | 18 | 7 | Added: StudentExamAttemptController, StudentGrievanceController, StudentHomeworkController, StudentLeaveController, StudentLibraryController, StudentQuestAttemptController, StudentQuizAttemptController, StudentRecommendationPortalController, FeePaymentController, ParentResultsController, PaymentDemoController |
| Mobile Controllers | 19 | 0 | Full mobile API tier added after V2: MobileStudentController, MobileTimetableController, MobileLeaveController, MobileComplaintController, MobileQuizAttemptController, MobileHomeworkController, etc. |
| Models | 11 | 0 | AttemptActivityEventType, AttemptActivityLog, AttemptCheckpoint, ExamAttempt, ExamAttemptAnswer, ExamGrievance, ExamMarksEntry, ExamResult, QuizQuestAttempt, QuizQuestAttemptAnswer, QuizQuestResult |
| FormRequests | 5 | 0 | RespondToLeaveRemarkRequest, SaveAnswerRequest, StartAttemptRequest, StoreLeaveApplicationRequest, SubmitAttemptRequest |
| Services | 1 | 0 | AllocationService |
| Traits | 2 | 0 | StudentAttemptTrait, ResolvesMobileStudent |
| HTTP Resources | 1 | 0 | StudentDashboardResource (mobile) |
| Console Commands | 1 | 0 | TimeoutStaleAttempts |
| Policies | 0 | 0 | None registered in AppServiceProvider |
| Tests — Feature | 5 | 3 | Added FeePaymentControllerTest, StudentLeaveControllerTest |
| Tests — Unit | 4 | 3 | Added LeaveServiceTest |
| Seeders | 3 | — | StudentPortalDatabaseSeeder, StudentPortalDemoDataSeeder, QuizReportsDemoSeeder |
| Blade Views | ~120 | 57 | Major additions: exam/quiz/quest player flows, leave, library detail, grievances, shared-results |
| Web Routes | ~95 | ~55 | Full quiz/quest/exam player, leave, library, recommendations, homework submission |
| Mobile API Routes | ~45 | 0 | Comprehensive mobile tier |
| Owned DB Migrations | 7 | 0 | All use `lms_*` prefix (see DDL Inventory) |

---

## Module Score Summary (V2 Gap Analysis 2026-03-26)

> V2 score was assessed at 55% overall. The analysis below reflects the 2026-06-30 state where applicable.

| Area | V2 Score | 2026-06-30 Estimate | Key Issue |
|------|----------|---------------------|-----------|
| Feature Completeness | 55% | 78% | Quiz/quest/exam players, leave, library fully added |
| Security — Auth | 50% | 50% | `role:Student|Parent` applied; EnsureTenantHasModule missing; zero Gate::authorize() |
| IDOR Protection | 20% | 40% | viewInvoice/payDueAmount partially fixed; proceedPayment IDOR still present |
| Service Layer | 0% | 5% | 1 AllocationService; all major logic still in controllers |
| FormRequest Coverage | 0% | 15% | 5 FormRequests for attempt/leave; complaint/payment still unguarded |
| Policy Architecture | 0% | 0% | Zero policies registered in AppServiceProvider |
| Test Coverage | 10% | 20% | Basic tests exist; critical IDOR tests absent |
| Mobile API | 0% | 80% | Full mobile tier; not in V2 scope |
| **Overall** | **~55%** | **~75–80%** | — |

---

## DDL Table Inventory — STP-Owned Tables (7, all `lms_*` prefix)

> IMPORTANT: StudentPortal module owns 7 tables despite V2 stating "zero owned tables." All were created by migrations on 2026-06-16. The prefix is `lms_` (shared namespace with LmsExam, LmsQuiz, LmsQuests) — not `stp_*`.

| Table | Model | SoftDeletes | Purpose |
|-------|-------|:-----------:|---------|
| `lms_attempt_activity_logs` | `AttemptActivityLog` | No | Polymorphic event log for all attempt types (EXAM/QUIZ/QUEST); tracks violations, tab-switches, etc. |
| `lms_attempt_checkpoints` | `AttemptCheckpoint` | No | Resumable attempt state (current question index, flagged/answered question IDs, checkpoint JSON) |
| `lms_exam_attempts` | `ExamAttempt` | YES | Online exam attempt record per student+paper; tracks start/end time, status, IP, browser, violations |
| `lms_exam_attempt_answers` | `ExamAttemptAnswer` | No | Per-question answer for exam attempts; supports MCQ (option_ids), descriptive (text), and attachment |
| `lms_quiz_quest_attempts` | `QuizQuestAttempt` | YES | Combined quiz/quest attempt (assessment_type discriminator); stores score, percentage, pass/fail |
| `lms_quiz_quest_attempt_answers` | `QuizQuestAttemptAnswer` | No | Per-question answer for quiz/quest attempts |
| `lms_exam_grievances` | `ExamGrievance` | YES | Student grievance on exam result; types: MARKING_ERROR, OUT_OF_SYLLABUS, QUESTION_ERROR, OTHER |

### Key Column Details

#### `lms_exam_attempts`
| Column | Type | Notes |
|--------|------|-------|
| `attempt_mode` | ENUM | OFFLINE / ONLINE |
| `status` | ENUM | ABSENT / CANCELLED / EVALUATED / EVALUATION_PENDING / IN_PROGRESS / NOT_STARTED / RESULT_PUBLISHED / SUBMITTED |
| `violation_count` | INT | Tab-switch/focus-loss count |
| `paper_set_id` | FK → `lms_exam_paper_sets` | Randomized paper set |
| UNIQUE | `(exam_paper_id, student_id)` | One attempt per student per paper |

#### `lms_quiz_quest_attempts`
| Column | Type | Notes |
|--------|------|-------|
| `assessment_type` | ENUM | QUIZ / QUEST |
| `status` | ENUM | ABANDONED / CANCELLED / IN_PROGRESS / NOT_STARTED / REASSIGNED / SUBMITTED / TIMEOUT |
| `attempt_number` | TINYINT | Supports multiple attempts if configured |
| CHECK constraint | — | `quiz_id IS NOT NULL AND quest_id IS NULL` when `assessment_type = 'QUIZ'` (and inverse for QUEST) |

#### `lms_exam_grievances`
| Column | Type | Notes |
|--------|------|-------|
| `grievance_type` | ENUM | MARKING_ERROR / OTHER / OUT_OF_SYLLABUS / QUESTION_ERROR |
| `status` | ENUM | OPEN / REJECTED / RESOLVED / UNDER_REVIEW |
| `marks_changed` | BOOL | Set to `true` if resolution changes marks |
| `old_marks` / `new_marks` | DECIMAL(5,2) | Marks before/after resolution |

### Tables Consumed (Read or Write — External Modules)

| Table | Module | Access |
|-------|--------|--------|
| `sys_users` | SystemConfig | Auth identity, photo, email |
| `sys_dropdowns` | SystemConfig | Complaint form dropdowns (hardcoded ID 104) |
| `sys_notifications` | Notification | Notification inbox via Laravel Notifiable |
| `std_students` | StudentProfile | Core student entity |
| `std_student_profiles` | StudentProfile | Extended personal data |
| `std_student_addresses` | StudentProfile | Address fields |
| `std_guardians` | StudentProfile | Guardian details |
| `std_student_guardian_jnt` | StudentProfile | Student-guardian flags incl. `can_access_parent_portal` |
| `std_student_academic_sessions` | StudentProfile | Class, section, roll number |
| `std_health_profiles` | StudentProfile | Blood group, allergies |
| `std_student_attendance` | StudentProfile | Attendance records |
| `fee_student_assignments` | StudentFee | Fee structure per session |
| `fee_invoices` | StudentFee | Invoice view and payment |
| `cmp_complaints` | Complaint | Complaint submission |
| `cmp_complaint_categories` | Complaint | Category / subcategory |
| `tt_timetable_cells` | SmartTimetable | Weekly timetable grid |
| `tt_school_days` | SmartTimetable | School day names/ordinals |
| `lms_exam_allocations` | LmsExam | Exam schedule and targeting |
| `lms_exam_papers` | LmsExam | Paper config (time limit, etc.) |
| `lms_exam_paper_sets` | LmsExam | Randomized paper sets |
| `lms_exam_results` | LmsExam | Published exam marks |
| `hmw_homeworks` | LmsHomework | Homework assignments |
| `hmw_homework_submissions` | LmsHomework | Submission records |
| `lms_quizzes` | LmsQuiz | Quiz config |
| `lms_quiz_allocations` | LmsQuiz | Quiz-to-class/student allocation |
| `lms_quests` | LmsQuests | Quest config |
| `lms_quest_allocations` | LmsQuests | Quest-to-class/student allocation |
| `slb_syllabus_schedules` | Syllabus | Topic-level schedule |
| `hpc_reports` | HPC | Published progress cards |
| `rec_student_recommendations` | Recommendation | Personalized content |
| `lib_book_masters` | Library | Library book catalog |
| `lib_members` | Library | Library membership |
| `lib_transactions` | Library | Borrowing/return history |
| `tpt_student_allocation_jnt` | Transport | Transport route allocation |
| `bok_books` | SyllabusBooks | Prescribed book catalog |
| `bok_book_class_subjects` | SyllabusBooks | Book-class-subject mapping |
| `pay_payment_gateways` | Payment | Gateway config (should filter active only) |

---

## Known Gaps & Open Issues

### P0 — Critical (Security / Production Blockers)

| ID | Issue | Location |
|----|-------|---------|
| SEC-STP-01 | **IDOR in `proceedPayment()` — `payable_id` accepted from client without ownership check.** Any authenticated student can pay another student's invoice by submitting the target invoice's ID. Fix: `FeeInvoice::whereHas('feeStudentAssignment', fn($q) => $q->where('student_id', $student->id))->findOrFail($request->payable_id)` before calling PaymentService | `FeePaymentController::initiate()` or `StudentPortalController::proceedPayment()` |
| SEC-STP-02 | **Zero `Gate::authorize()` or `$this->authorize()` calls in all 18 web controllers.** Only `role:Student|Parent` middleware guards the route group — no per-resource ownership checks at the controller level. Any Student-role user can call any endpoint if they know the URL. | All controllers |
| SEC-STP-03 | **`EnsureTenantHasModule` middleware absent** from the student portal route group. Any student on any tenant can access portal routes regardless of whether that tenant has the StudentPortal module enabled | `RouteServiceProvider` or `routes/web.php` |
| SEC-STP-04 | **Hard-coded dropdown ID `104`** in `StudentPortalComplaintController` at lines 73 and 125. ID will be wrong after any re-seeding. Must replace with `sys_dropdowns` `key`-based lookup (e.g., `where('key', 'COMPLAINANT_STUDENT')->value('id')`) | `StudentPortalComplaintController.php` |

### P1 — High

| ID | Issue | Location |
|----|-------|---------|
| GAP-STP-05 | **Results screen shows no actual marks.** `/student-portal/results` lists concluded exam allocations but does not display obtained marks, percentage, or grade — `ExamResult` model exists and is populated by the exam attempt flow | `StudentPortalController::results()` |
| GAP-STP-06 | **School calendar still stub.** `/student-portal/school-calendar` renders `calendar/index.blade.php` with no data. V1 screen spec `resources_school_calendar.md` exists. Requires integration with school event/holiday tables | `StudentPortalController::schoolCalendar()` |
| GAP-STP-07 | **Notice board uses wrong data source.** `/student-portal/notice-board` pulls from `auth()->user()->notifications()` (the transactional notification inbox) instead of a dedicated announcement/notice model (`sch_notices` or equivalent) | `StudentPortalController::noticeBoard()` |
| BUG-STP-08 | **`PaymentGateway::all()` instead of `::active()->get()`** in `payDueAmount()` — disabled payment gateways appear on the payment page | `StudentPortalController::payDueAmount()` |
| BUG-STP-09 | **`currentFeeAssignemnt` typo** on `Student` model relationship (missing letter 'n' before 't'). Referenced in 3+ controller methods. If the relationship is renamed, all callers must be updated simultaneously | `Student` model + all callers |
| GAP-STP-10 | **Complaint index not paginated.** `Complaint::where('created_by', Auth::id())->get()` loads all complaints at once — will degrade at scale | `StudentPortalComplaintController::index()` |
| GAP-STP-11 | **`proceedPayment()` invoice ownership guard incomplete.** Current guard `where('student_id', ...)` on `fee_invoices` may fail if `fee_invoices` does not have a direct `student_id` column — ownership is correctly via `fee_student_assignments`. Must use `whereHas('feeStudentAssignment', ...)` chain | `StudentPortalController::proceedPayment()` |
| GAP-STP-12 | **`notifications/{id}/mark-read` uses GET method** — browser pre-fetchers can mark notifications as read unintentionally. Must change to POST/PATCH | `routes/web.php`, `NotificationController` |
| SEC-STP-13 | **IDOR in `viewInvoice()` / `payDueAmount()`** — partial fix applies `where('student_id', ...)` directly on `fee_invoices`. If `fee_invoices` does not have a direct `student_id` column, the fix provides no protection. Verify DDL or switch to `whereHas('feeStudentAssignment', ...)` | `StudentPortalController` |

### P2 — Medium

| ID | Issue | Location |
|----|-------|---------|
| GAP-STP-14 | **Account settings backend stubs.** Three tabs have views but no backend: password change (`_security-settings.blade.php`), notification preferences (`_notification-settings.blade.php`), privacy settings (`_privacy-settings.blade.php`) | `account/_partials/` views |
| GAP-STP-15 | **No PDF download for Progress Card.** HPC reports are shown but no PDF link is present. Should link to HPC module's PDF generation route per report | `StudentPortalController::progressCard()` |
| GAP-STP-16 | **No PDF download for Student ID Card.** `id-card/index.blade.php` exists; `/student-portal/student-id-card/download` route not defined | `routes/web.php` |
| GAP-STP-17 | **Hostel stub.** `/student-portal/hostel` renders `hostel/index.blade.php` with no data. Blocked on Hostel module completion | `StudentPortalController::hostel()` |
| GAP-STP-18 | **`test-notification` route** — V2 flagged this as needing removal; status unconfirmed | `routes/tenant.php` or `routes/web.php` |
| ARCH-STP-19 | **No dedicated student auth guard.** V2 recommended a dedicated `student` guard using `sys_users` scoped to `user_type IN ('STUDENT','PARENT')` to fully isolate portal sessions from admin sessions. Currently Spatie role middleware is the only isolation | `config/auth.php` |
| ARCH-STP-20 | **`StudentPortalController` contains 24+ methods** (558 lines per V2). Scaffold stubs (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`) still present. Controller should be split; stubs removed | `StudentPortalController.php` |
| GAP-STP-21 | **`api.php` routes are scaffold-only.** The file contains `apiResource('studentportals', StudentPortalController::class)` — dead scaffold. `mobile_api.php` is the real mobile API file. Should either remove `api.php` scaffold or implement REST endpoints | `routes/api.php` |
| GAP-STP-22 | **Service layer absent for web tier.** `AllocationService` covers attempt allocation logic; all portal aggregation (dashboard: attendance + timetable + homework + exams + fee — 110+ lines) remains in `StudentPortalController::dashboard()` | `StudentPortalController::dashboard()` |
| BUG-STP-23 | **Attendance status value normalization missing.** Status values in `std_student_attendance` use inconsistent casing (`Present/P/present`, `Absent/A/absent`, etc.). Normalization should happen at model level via accessor | `StudentProgressController::attendance()` |

### P3 — Backlog

| ID | Issue |
|----|-------|
| GAP-STP-24 | **REST API for mobile/PWA.** `api.php` has scaffold only; `mobile_api.php` is the real mobile tier (uses `auth:sanctum`). Standardize and document the mobile API contract |
| GAP-STP-25 | **Parent dashboard separation.** Parent-role users currently see the same view as students. V2 recommends a distinct parent view listing linked children from `std_student_guardian_jnt` where `can_access_parent_portal = 1`, with child-switching capability |
| GAP-STP-26 | **Push notifications / FCM.** `sys_notifications` (Laravel database channel) exists; Firebase Cloud Messaging for mobile push not implemented |
| GAP-STP-27 | **Login rate limiting** not applied. V2 recommends `throttle:5,2` (5 attempts per 2 minutes) on the login POST route |
| GAP-STP-28 | **Zero test coverage for IDOR scenarios.** Critical tests T-STP-001 to T-STP-005 (Student A accessing Student B's invoice, proceeding payment with foreign invoice, admin user blocked from portal, notification ownership check) not in any test file |

---

## Feature Area Status (as of 2026-06-30)

| # | Feature | FR | Status | Notes |
|---|--------|----|--------|-------|
| 1 | Student Login | FR-STP-01 | ✅ Done | Separate login page; password reset available |
| 2 | Dashboard | FR-STP-02 | ✅ Done | Attendance, timetable, homework, exams, fee fully populated |
| 3 | Academic Information | FR-STP-03 | 🟡 80% | Profile, guardian, health loaded; attendance/exam via separate routes |
| 4 | Fee Invoice View | FR-STP-04 | 🟡 70% | Partial IDOR fix via `where('student_id', ...)` — may not be correct guard |
| 5 | Fee Payment (Web) | FR-STP-05 | 🟡 65% | `FeePaymentController` added; IDOR in proceedPayment still present |
| 6 | Fee Summary | FR-STP-06 | ✅ Done | Dedicated fee summary screen |
| 7 | Attendance View | FR-STP-07 | ✅ Done | Month-grouped attendance with summary counts |
| 8 | Timetable View | FR-STP-08 | ✅ Done | Weekly grid with break filtering |
| 9 | Exam Schedule | FR-STP-09 | ✅ Done | Partitioned into upcoming/today/concluded |
| 10 | Results View | FR-STP-10 | 🟡 60% | Shows concluded exams; no actual marks displayed |
| 11 | My Learning (LMS Hub) | FR-STP-11 | ✅ Done | Homework, exams, quizzes, quests consolidated |
| 12 | Homework + Submission | FR-STP-12 | ✅ Done | `StudentHomeworkController` with submit endpoint + file upload |
| 13 | Syllabus Progress | FR-STP-13 | ✅ Done | Topic-level status with subject percentages |
| 14 | My Teachers | FR-STP-14 | ✅ Done | Teachers directory from timetable data |
| 15 | Progress Card (HPC) | FR-STP-15 | 🟡 80% | Published reports shown; PDF download missing |
| 16 | Performance Analytics | FR-STP-16 | 🟡 75% | Monthly attendance + exam stats; subject-wise charts missing |
| 17 | Recommendations | FR-STP-17 | ✅ Done | Paginated list + detail + rating + status update |
| 18 | Library (browse + borrow) | FR-STP-18 | ✅ Done | Catalog, my-books, reserve, renew, digital access |
| 19 | Transport Information | FR-STP-19 | ✅ Done | Route/stop details with null-safe empty state |
| 20 | Health Records | FR-STP-20 | ✅ Done | Blood group, allergies, emergency contact |
| 21 | Student ID Card | FR-STP-21 | 🟡 80% | Digital view done; PDF download missing |
| 22 | Study Resources + Prescribed Books | FR-STP-22 | ✅ Done | Notes + book catalog; download + e-book routes |
| 23 | Notice Board | FR-STP-23 | 🟡 50% | View exists; uses notification inbox as source — wrong model |
| 24 | School Calendar | FR-STP-24 | ❌ Stub | Route + view exist; no data loaded |
| 25 | Student Leave Application | FR-STP-25 | ✅ Done | `StudentLeaveController` fully built (was stub in V2) |
| 26 | Hostel Info | FR-STP-26 | ❌ Stub | Blocked on Hostel module completion |
| 27 | Notifications | FR-STP-27 | 🟡 90% | Implemented; mark-read HTTP method should be POST/PATCH |
| 28 | Complaints | FR-STP-28 | 🟡 80% | CRUD works; hard-coded ID 104; not paginated |
| 29 | Account Settings | FR-STP-29 | 🟡 50% | Tab structure; password/notification/privacy backend stubs |
| 30 | Online Exam Player | FR-STP-30 | ✅ Done | Full flow: instructions/start/attempt/save-answer/checkpoint/submit/result/PDF |
| 31 | Quiz Player | — | ✅ Done | Full flow (same pattern as exam) + PDF result |
| 32 | Quest Player | — | ✅ Done | Full flow (same pattern as quiz) + PDF result |
| 33 | Exam Grievances | — | ✅ Done | `StudentGrievanceController` with create/store/index |
| 34 | Mobile API | — | ✅ 80% | 19 mobile controllers covering all major features; no mobile auth guard |
| 35 | Parent Results View | — | 🟡 Partial | `ParentResultsController` exists; extent unknown |
| 36 | EnsureTenantHasModule | — | ❌ 0% | Not applied anywhere |
| 37 | Policy Layer | — | ❌ 0% | Zero policies; no AppServiceProvider registration |

---

## Attempt Infrastructure (New Since V2 — Major Addition)

The most significant post-V2 development is the complete online assessment attempt engine:

### Attempt Flow (Exam / Quiz / Quest)

```
Student → /online-exam/{id}/instructions
  → StudentExamAttemptController::instructions()
  → Render instructions (time limit, question count, rules)

Student → POST /online-exam/{id}/start
  → StartAttemptRequest (validated)
  → Create `lms_exam_attempts` record (status: IN_PROGRESS)
  → AllocationService::allocatePaperSet() — assigns randomized paper set
  → Create initial `lms_attempt_checkpoints` record

Student → GET /online-exam/{id}/attempt
  → Render question paper from checkpoint
  → Anti-cheating: tab-switch events logged to `lms_attempt_activity_logs`

Student → POST /online-exam/{id}/save-answer  (AJAX — per question)
  → SaveAnswerRequest (validated)
  → Upsert `lms_exam_attempt_answers`
  → Update `lms_attempt_checkpoints.answered_question_ids`

Student → POST /online-exam/{id}/checkpoint  (auto-save heartbeat)
  → Update `lms_attempt_checkpoints.checkpoint_data` (JSON)
  → Update `lms_attempt_checkpoints.saved_at`

Student → POST /online-exam/{id}/submit
  → SubmitAttemptRequest (validated)
  → Update `lms_exam_attempts.status = SUBMITTED`
  → Update `lms_exam_attempts.actual_end_time`

Student → GET /online-exam/{id}/result
  → Show score (if auto-evaluated MCQ) or "evaluation pending"

Student → GET /online-exam/{id}/result/pdf
  → DomPDF render of result PDF

Exam Grievance:
Student → GET /online-exam/{id}/grievance/create
  → POST /online-exam/{id}/grievance
  → Create `lms_exam_grievances` (status: OPEN)
```

### Console Command: `TimeoutStaleAttempts`
Artisan command to auto-submit stale `IN_PROGRESS` attempts past their time limit. Should be registered in Scheduler.

---

## Cross-Module Dependencies

### STP Consumes From (Inbound)

| Source Module | Data / Entity | Why |
|---------------|--------------|-----|
| StudentProfile (STD) | `std_students`, `std_student_profiles`, `std_student_addresses`, `std_student_academic_sessions`, `std_student_attendance`, `std_guardians`, `std_student_guardian_jnt`, `std_health_profiles` | Core student identity and data chain |
| StudentFee (FIN) | `fee_student_assignments`, `fee_invoices` | Fee view and payment |
| Payment | `PaymentService::createPayment()`, `pay_payment_gateways` | Razorpay checkout |
| Notification | `sys_notifications` via Laravel Notifiable | Notification inbox |
| Complaint (CMP) | `cmp_complaints`, `cmp_complaint_categories` | Complaint submission |
| SmartTimetable / TimetableFoundation | `tt_timetable_cells`, `tt_school_days` | Timetable grid and teacher lookup |
| LmsExam | `lms_exam_allocations`, `lms_exam_papers`, `lms_exam_paper_sets`, `lms_exam_results` | Exam schedule, attempt, and results |
| LmsHomework | `hmw_homeworks`, `hmw_homework_submissions` | Homework list and submission |
| LmsQuiz | `lms_quizzes`, `lms_quiz_allocations` | Quiz listing and attempt |
| LmsQuests | `lms_quests`, `lms_quest_allocations` | Quest listing and attempt |
| Syllabus (SLB) | `slb_syllabus_schedules` | Syllabus progress tracker |
| HPC | `hpc_reports` | Published progress cards |
| Recommendation (REC) | `rec_student_recommendations` | Personalized content |
| Library (LIB) | `lib_book_masters`, `lib_members`, `lib_transactions` | Book browse, reserve, renew |
| Transport (TPT) | `tpt_student_allocation_jnt` | Student bus route and stop info |
| SyllabusBooks (BOK) | `bok_books`, `bok_book_class_subjects` | Prescribed book list |
| SystemConfig | `sys_dropdowns`, `sys_users` | Dropdown lookups, auth user |
| Hostel (HST) | Planned — stub only | Room, mess, hostel allocation |
| Library (LIB) | `LibWishlistController` cross-module call via route | Wishlist toggle — hard coupling via `\Modules\Library\Http\Controllers\LibWishlistController` |

### STP Provides To (Outbound)

| Target Module | Data / Mechanism | Notes |
|---------------|-----------------|-------|
| LmsExam | `lms_exam_attempts`, `lms_exam_attempt_answers`, `lms_exam_grievances` | STP creates attempt records read by LmsExam for evaluation |
| LmsQuiz / LmsQuests | `lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers` | STP creates attempt records for quiz/quest evaluation |
| Payment | Payment initiation payload | STP sends Razorpay order requests to Payment module |

---

## Permission Architecture

### Auth Strategy (Current — Gap-Heavy)

| Layer | Implementation | Status |
|-------|---------------|--------|
| Route-level | `role:Student|Parent` Spatie middleware in RouteServiceProvider | ✅ Applied |
| EnsureTenantHasModule | Not applied | ❌ Missing |
| Gate / Policy | Zero calls in all 18 controllers | ❌ Missing |
| CSRF | Web middleware (correct) | ✅ Applied |
| IDOR guards | Partial on viewInvoice/payDueAmount; absent on proceedPayment | 🟡 Partial |

### Proposed Policy (S-STP-25 from V2)

A `StudentPortalPolicy` class with:
- `viewInvoice(User $user, FeeInvoice $invoice)` — verify ownership via feeStudentAssignment
- `payInvoice(User $user, FeeInvoice $invoice)` — verify ownership + payable status
- `createComplaint(User $user)` — verify Student role
- `viewGrievance(User $user, ExamGrievance $grievance)` — verify student_id matches
- `viewAttempt(User $user, ExamAttempt|QuizQuestAttempt $attempt)` — verify student_id matches

### Role-Based Access Target

| Role | Access Level |
|------|-------------|
| Student | Full portal access scoped to own data; no access to other students' data |
| Parent | Same portal access as student but viewing linked child's data only (`can_access_parent_portal = 1`) |
| Admin | Manages student login credentials via admin backend; no portal routes |

---

## Design Decisions Made

| Decision | Detail | Source |
|----------|--------|--------|
| No `stp_*` tables (portal layer) | StudentPortal is a read-focused portal — all data lives in domain module tables. Zero `stp_*` tables | V2 §5.1; confirmed DDL |
| STP owns `lms_*` attempt tables | 7 attempt/grievance tables use `lms_*` prefix despite belonging to STP module — intentional shared LMS namespace for cross-module visibility | Migration files 2026-06-16 |
| Spatie `role:Student|Parent` as primary auth gate | Route group protected by Spatie role middleware in RouteServiceProvider; no per-controller policies | V2 §3.1; code |
| Shared `sys_users` auth — no dedicated guard | Students authenticate via standard Laravel Auth against same `sys_users` table as admin; isolated only by Spatie role | V2 §3.1 (dedicated guard recommended but not yet implemented) |
| Separate portal layout | `studentportal::components.layouts.master` fully isolates the student portal UI from the admin backend layout | Code; V2 §2.1 |
| Quiz and Quest use combined attempt table | `lms_quiz_quest_attempts` uses `assessment_type` ENUM discriminator rather than two separate tables — with CHECK constraints enforcing FK consistency | Migration 2026-06-16 |
| Attempt checkpoints for resumability | `lms_attempt_checkpoints` stores JSON state of in-progress attempts — allows students to resume after browser crash or disconnect | Migration 2026-06-16 |
| `TimeoutStaleAttempts` Artisan command | Automated timeout for stale `IN_PROGRESS` attempts — must be registered in the Scheduler | `Console/Commands/` |
| Hard coupling to Library wishlist | `routes/web.php` uses `\Modules\Library\Http\Controllers\LibWishlistController` directly — creates cross-module class dependency | `routes/web.php` line 149 |
| Mobile API as separate route file | `mobile_api.php` is the actual mobile REST API (Sanctum-guarded); `api.php` is dead scaffold | `routes/` directory |

---

## Route Registration Pattern

Routes are registered in the module-level `Modules/StudentPortal/routes/web.php` (not in central `routes/tenant.php`). The `RouteServiceProvider` maps this file with:
- Prefix: `student-portal/`
- Name prefix: `student-portal.`
- Middleware stack: `web → InitializeTenancyByDomain → PreventAccessFromCentralDomains → EnsureTenantIsActive → auth → verified → role:Student|Parent`
- **Missing: `EnsureTenantHasModule:StudentPortal`**

Login route is registered with `withoutMiddleware(['auth', 'verified'])` group within the same file — allows unauthenticated access to the login page.

Mobile API is registered in `mobile_api.php` under Sanctum guard (`auth:sanctum`), prefix `student/` within `/api/` namespace.

Central `routes/tenant.php` — no STP routes present (correctly delegated to module file).

API file (`api.php`) — contains only `apiResource('studentportals', StudentPortalController::class)` scaffold — dead code.

---

## V1 Screen Spec Inventory (34 files)

| File | Coverage |
|------|---------|
| `dashboard.md` | Dashboard screen |
| `academic_overview.md` | Academic information hub |
| `academic_my_attendance.md` | Attendance view |
| `academic_my_teachers.md` | Teachers directory |
| `academic_my_timetable.md` | Timetable grid |
| `academic_syllabus_progress.md` | Syllabus progress |
| `examinations_exam_schedule.md` | Exam schedule |
| `examinations_my_results.md` | Results view |
| `examinations_my_grievances.md` | Exam grievance workflow |
| `learning_lms_dashboard.md` | LMS learning hub |
| `learning_homework_submission.md` | Homework + submission |
| `learning_online_exam_attempt.md` | Online exam player |
| `learning_quiz_attempt.md` | Quiz attempt player |
| `learning_quest_attempt.md` | Quest attempt player |
| `finance_fee_summary.md` | Fee summary |
| `finance_payment_integration.md` | Razorpay payment flow |
| `MyProfile_account_settings.md` | Account settings (6 tabs) |
| `MyProfile_digital_id_card.md` | Student ID card |
| `MyProfile_health_records.md` | Health records |
| `MyProfile_Teachers.md` | Teacher profile detail |
| `MyReports_performance_analytics.md` | Performance analytics |
| `MyReports_recommendations.md` | Recommendations |
| `resources_library_browse.md` | Library catalog |
| `resources_library_my_books.md` | My borrowed books |
| `resources_notes_and_resources.md` | Study resources / notes |
| `resources_notice_board.md` | Notice board (announcements) |
| `resources_prescribed_books.md` | Prescribed books |
| `resources_school_calendar.md` | School calendar |
| `services_apply_leave.md` | Leave application |
| `services_hostel.md` | Hostel info |
| `services_transport.md` | Transport info |
| `support_complaints_create.md` | Submit complaint |
| `support_complaints_view.md` | View complaint history |
| `support_notifications.md` | Notifications inbox |

---

## Lessons Learned

- [2026-06-30 | Business Analyst] CLAUDE.md listed StudentPortal as "Pending" — it is in fact ~75-80% complete with 37 controllers, 7 owned DB tables, a full online assessment attempt engine, and a comprehensive mobile API. Always verify via `find Modules/{MODULE} -type f` before trusting CLAUDE.md status labels.
- [2026-06-30 | Business Analyst] STP owns 7 tables despite V2 stating "zero owned tables." The 2026-06-16 migrations created `lms_*`-prefixed tables for the attempt engine. The prefix overlaps with LmsExam/LmsQuiz/LmsQuests namespace — when auditing LMS tables, check whether a given `lms_*` table belongs to STP or to the LMS modules.
- [2026-06-30 | Business Analyst] The V2 document (2026-03-26) reflected a 55% complete state. By 2026-06-30 the module advanced to ~78%: leave application, full quiz/quest/exam players, library reservation/renewal, homework submission, recommendations with rating, and a 19-controller mobile API were all added. The gap is largest in the security architecture (zero policies, IDOR in payment) and three stub screens (calendar, hostel, account settings backend).
- [2026-06-30 | Business Analyst] `routes/web.php` directly instantiates `\Modules\Library\Http\Controllers\LibWishlistController` for the wishlist toggle route (line 149) — this is a hard cross-module class coupling. If the Library module is disabled or renamed, STP breaks. The pattern should use an API call or event instead.
- [2026-06-30 | Business Analyst] The `api.php` route file is a dead scaffold (`apiResource('studentportals', ...)`) — the real mobile API is in `mobile_api.php`. Do not confuse the two when reviewing or extending API coverage.
- [2026-06-30 | Business Analyst] STP is the most cross-module-dependent module in the platform — it reads from 17+ modules. This makes it the last module to integrate cleanly; every upstream module incompleteness (Library, Hostel, HPC, LmsExam result publication) directly creates a stub or gap in the portal.
- [2026-06-30 | Technical Auditor] **STALE CORRECTION: SEC-STP-01 CLEARED.** BA claimed IDOR in `proceedPayment()`. Live code: `proceedPayment()` returns `redirect()->route('student-portal.fee-summary')->with('error', 'Fee payments can only be processed through the Parent Portal.')` — no data processing at all. Actual fee payment via `FeePaymentController::initiate()` which has `abort_if($authStudentId === null || $invoice->studentAssignment->student_id !== $authStudentId, 403)`.
- [2026-06-30 | Technical Auditor] **STALE CORRECTION: SEC-STP-008 CLEARED.** BA claimed IDOR in `StudentExamAttemptController::attempt($id)` — allocation check missing. Live code: private `assertAllocation(int $paperId, array $ctx)` method is called at the TOP of every action method: `instructions()`, `start()`, `attempt()`, `submit()`, `saveAnswer()`, `checkpoint()`, `result()` (7 methods confirmed). The check verifies `ExamAllocation::where('exam_paper_id', $paperId)->where('is_active', true)->where(classId/sectionId/studentId)->exists()` — proper ownership check. Same pattern in `StudentQuizAttemptController` and `StudentQuestAttemptController`.
- [2026-06-30 | Technical Auditor] **STALE CORRECTION: SEC-STP-04 CLEARED.** BA claimed hardcoded dropdown ID 104 in `StudentPortalComplaintController::create()`. Live code: `create()` returns `ComplaintCategory::parents()->get()` — no hardcoded IDs. `store()` uses `sys_dropdowns` lookup by `key`/`value` pairs.
- [2026-06-30 | Technical Auditor] **STALE CORRECTION: SEC-STP-09 CLEARED.** BA claimed `User::all()` in complaint controller. Not present anywhere in STP.
- [2026-06-30 | Technical Auditor] **STALE CORRECTION: BUG-STP-08 CLEARED.** BA claimed `PaymentGateway::all()` exposes all gateways. Not found. `FeePaymentController` uses injected `GatewayManager::resolve('razorpay')`.
- [2026-06-30 | Technical Auditor] **NEW P0 CONFIRMED: SEC-STP-03.** EnsureTenantHasModule absent from `mapWebRoutes()`. Fix: add `\App\Http\Middleware\EnsureTenantHasModule::class` to RSP middleware array.
- [2026-06-30 | Technical Auditor] **NEW P1: SEC-STP-014.** Mobile routes in central `routes/api.php` use `['mobile.key', 'tenant.mobile', 'auth:sanctum']` — no `role:Student|Parent`. Any Sanctum-authed user (teacher, admin) can access all 45+ student mobile endpoints.
- [2026-06-30 | Technical Auditor] **NEW P1: SEC-STP-02 confirmed.** Zero Gate::authorize across all 37 controllers. Zero policy registrations in ServiceProvider. Authorization model is: role middleware (web) + query-scoping (DB). Not necessarily a bug but fails audit standards.
- [2026-06-30 | Technical Auditor] Mobile routes are NOT registered in the module RSP. They are loaded via `require base_path(...)` in central `routes/api.php`. The `InitializeTenancyByMobileHeader` middleware (alias: `tenant.mobile`) resolves the tenant from `X-School-Code` header and calls `tenancy()->initialize($tenant)` — this is a valid custom tenancy mechanism, not a security gap.
- [2026-06-30 | Technical Auditor] **FE-STP-001 (P2):** Stored XSS in `{!! $q['text'] !!}` (exam/quiz attempt and result views), `{!! $hw->description !!}` (homework), `{!! $rec->material->content_text !!}` (recommendations) — teacher-authored rich content rendered unescaped. Safe pattern already in use: `{!! nl2br(e($notification->data['body'])) !!}` in notifications. Fix: HTML sanitizer on all rich content before rendering.
- [2026-06-30 | Technical Auditor] `FeePaymentController::callback()` correctly cross-checks ULID: `abort_if($payment->payable_type !== FeeInvoice::class || $payment->payable_id !== $invoice->getKey(), 403)` — prevents a client from substituting another payment's ULID to confirm an unrelated invoice.
- [2026-06-30 | Technical Auditor] `mapPublicRoutes()` is a third RSP method (not in BA knowledge) — serves signed URL routes for parent-accessible result sharing (`/student-portal/shared-results/{studentId}`) with tenancy but no auth. The route applies `.middleware('signed')` correctly.

---

## Pending Next Steps (Updated 2026-06-30 after Mode X audit)

**P0 (Block Deploy):**
1. **SEC-STP-03** — Add `EnsureTenantHasModule` to `mapWebRoutes()` middleware in RSP (1 line)

**P1 (Major):**
2. **SEC-STP-014** — Wrap STP `mobile_api.php` require in central `routes/api.php` with `role:Student|Parent` middleware
3. **SEC-STP-02** — Register policies for ExamAttempt, AttemptCheckpoint; add Gate::authorize to exam/quiz/quest attempt entry points

**P2:**
4. **FE-STP-001** — Sanitize rich content before `{!! !!}` output in exam/quiz/homework/recommendation views
5. **GAP-STP-012** — Change `GET /notifications/{id}/mark-read` to `PATCH`
6. **BUG-STP-001** — Paginate `StudentPortalComplaintController::index()` (->paginate(15))
7. **DAT-STP-001** — Plan ENUM → VARCHAR migration for 5 lms_* table columns (coordinate with LmsExam/LmsQuiz)

**P3:**
8. **DEAD-STP-001** — Remove empty edit/update/destroy from complaint route resource
9. **DEAD-STP-002** — Delete dead `api.php` apiResource scaffold
10. **BUG-STP-002** — Schedule `TimeoutStaleAttempts` in registerCommandSchedules()

---

## Version History

| Version | Date | Agent | Changes |
|---------|------|-------|---------|
| 1.0 | 2026-06-30 | Business Analyst | Initial seed — V2 requirement (full read) + V1 screen spec inventory (34 files) + filesystem verification (37 controllers, 11 models, 5 FormRequests, 7 owned DB tables, mobile API tier); completion upgraded from V2-stated 55% to actual ~78% |
| 1.1 | 2026-06-30 | Technical Auditor | Mode X Complete Audit — 5 BA P0s CLEARED (SEC-STP-01, SEC-STP-008, SEC-STP-04, SEC-STP-09, BUG-STP-08); 1 P0 confirmed (SEC-STP-03); 2 P1 confirmed (SEC-STP-02, SEC-STP-014 new); 4 P2 (FE-STP-001, GAP-STP-012, BUG-STP-001, DAT-STP-001); 3 P3. Health 40/100. Full report at 3-Audit_Reports/StudentPortal_Complete_Audit_2026-06-30.md |
