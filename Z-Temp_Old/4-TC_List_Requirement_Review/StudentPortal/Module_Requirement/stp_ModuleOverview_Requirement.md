# StudentPortal Module — Business Requirements Overview

## Module Purpose

The StudentPortal Module is a comprehensive self-service web portal for students in K-12 schools. It serves as the single digital gateway through which students access their academic, financial, examination, learning, library, transport, health, and support services. The portal aggregates data from 17+ source modules into a unified experience, presenting each student with their personalised attendance, timetable, homework, fee status, exam schedule, results, learning hub (LMS quizzes/quests), library catalogue, transport allocation, health records, ID card, leave applications, complaints, grievances, notifications, recommendations, and account settings.

The module operates on a **read-heavy, write-light** model: most screens display information sourced from other modules, while the portal's own write operations are limited to exam/quiz/quest attempts, homework submissions, complaints, leave applications, grievances, PTM bookings, fee payment initiation, library reservations, and study resource ratings. The module owns seven `lms_*` tables that form the attempt engine for online examinations, quizzes, and quests.

The StudentPortal enforces **strict data isolation**: every controller method filters data to the authenticated student's identity chain (`auth()->user()->student`), ensuring no student can access another student's records. However, as of the current codebase, zero `Gate::authorize()` calls exist across the 18 web controllers — a systemic security gap that must be addressed.

## Default Data Load

The Module Overview is not a standalone screen — the Dashboard (`StudentPortalController.dashboard()`) is the landing page. On page load, it executes queries across 7+ source modules to display aggregate statistics (attendance percentage, pending homework count, upcoming exam count, fee due/paid/total, pending quiz/quest counts, total LMS results, leave counts), today's timetable cells, pending homework entries, upcoming exam allocations, recent LMS results, notifications, and quick-navigation links. The student's current academic session (`std_student_academic_sessions`), class-section, and fee assignment are resolved at the start of every request chain.

---

## Dashboard — Student Central

The dashboard is the primary entry point for all portal activity. It presents a profile card (student avatar, name, class-section, roll number, session), stat cards (attendance %, pending homework count, upcoming exams count, fee due, leave counts), today's timetable widget, pending homework table, upcoming exams table, recent LMS results list, quick-navigation panel, and notifications feed. All data is scoped to the authenticated student's current academic session.

**Route:** `GET /dashboard` — `StudentPortalController.dashboard()`

---

## Account — My Account / Settings

A multi-tab settings hub showing the student's profile information, academic details, personal parameters, guardian directory, address details, sibling verification block, and (planned) security and notification preference settings. The `account()` method eager-loads the user with `student`, `student.profile`, `student.addresses`, `student.studentGuardianJnts`, `student.sessions`, `student.guardians.user` and queries siblings sharing the same guardian IDs.

**Route:** `GET /account` — `StudentPortalController.account()`

---

## Academic — Academic Hub

Aggregates general academic data across sessions, including historical exam marksheets grouped by academic session with per-exam aggregates, summary attendance benchmarks (total/present/absent/late days and monthly trends), fee invoice overview (latest plus older invoices), and planned certifications section. This is the most data-heavy page in the portal, loading results from `lms_exam_results`, attendance from `std_student_attendance`, and invoices from `fee_invoices`.

| Screen | Route | Controller Method |
|--------|-------|-------------------|
| Academic Information Hub | `GET /academic-information` | `academicInformation()` |
| My Attendance | `GET /my-attendance` | `StudentProgressController.attendance()` |
| My Timetable | `GET /my-timetable` | `StudentTimetableController.index()` |
| My Teachers | `GET /my-teachers` | `StudentTeachersController.index()` |
| Syllabus Progress | `GET /syllabus-progress` | `StudentProgressController.syllabusProgress()` |

---

## Examinations — Schedule & Results

Provides a full examination management view: exam schedule with upcoming/today/concluded/ongoing filters, published exam results with obtained marks/percentage/grade, and online exam player (instructions → attempt → auto-save → submit → result). The exam player supports checkpoint recovery (browser crash resume), timer-based auto-submit via `TimeoutStaleAttempts` artisan command, and post-exam grievances.

| Screen | Route | Controller |
|--------|-------|------------|
| Exam Schedule | `GET /exam-schedule` | `StudentPortalController.examSchedule()` |
| Results | `GET /results` | `StudentPortalController.results()` |
| Online Exam Player | `GET /online-exams` + attempt flow | `StudentExamAttemptController` |
| Quiz Player | `GET /my-quizzes` + attempt flow | `StudentQuizAttemptController` |
| Quest Player | `GET /my-quests` + attempt flow | `StudentQuestAttemptController` |
| My Grievances | `GET /my-grievances` | `StudentGrievanceController.index()` |

**Online Exam Player Flow:** Instructions → Start (creates attempt + checkpoint) → Attempt (timed question-by-question with auto-save) → Submit (freezes answers) → Result (published marks). Supports grievance filing post-evaluation.

---

## Finance — Fee Summary & Payments

Displays the student's fee assignment with full invoice history (latest invoice highlighted, older invoices listed), total/paid/due amounts, and per-invoice breakdown. Payment initiation is gated to the Parent Portal (`payDueAmount()` and `proceedPayment()` redirect with "Fee payments can only be processed through the Parent Portal"). Fee summary loads the `currentFeeAssignemnt` relationship with `feeStructure.details.head` and `invoices`.

| Screen | Route | Controller Method |
|--------|-------|-------------------|
| Fee Summary | `GET /fee-summary` | `feeSummary()` |
| Invoice View | `GET /view-invoice/{invoice}` | `viewInvoice()` |
| Pay Due Amount | `GET /pay-due-amount/pay-now/{invoice}` | `payDueAmount()` (redirects to parent portal) |

**Known Issue:** `currentFeeAssignemnt` typo on the Student model — the relationship name is misspelled (should be `currentFeeAssignment`). This causes silent null returns in three controller methods if the relationship is ever renamed.

---

## Learning — LMS Hub & Homework

The learning hub (`myLearning()`) aggregates all LMS content: quizzes, quests, and homework assignments allocated to the student's class-section. Homework module supports list view, detail view, file upload submission (text-only allowed, 10 MB max, validated MIME types), and late-submission gating via `restrict_late_submission` flag. The quiz and quest players follow the same attempt engine pattern as online exams.

| Screen | Route | Controller |
|--------|-------|------------|
| My Learning Hub | `GET /my-learning` | `StudentLmsController.index()` |
| My Homework | `GET /my-homework` | `StudentHomeworkController.index()` |
| Homework Detail | `GET /homework/{id}` | `StudentHomeworkController.show()` |
| Homework Submit | `POST /homework/{id}/submit` | `StudentHomeworkController.submit()` |

---

## Library — Catalogue & My Books

Full library integration allowing students to browse the physical catalogue, search resources, reserve books, request digital access, view and download digital resources, manage wishlist, submit reviews, renew borrowed books, and cancel requests. The library routes are hard-coupled to Library module controllers (flagged architectural concern).

**Route:** `GET /library` and sub-routes — `StudentLibraryController`

---

## Services — Leave, PTM, Transport, Hostel

| Screen | Route | Controller |
|--------|-------|------------|
| Leave Applications | `GET /apply-leave{/create,/id,/cancel,/respond,/message}` | `StudentLeaveController` |
| Parent-Teacher Meeting | `GET /ptm` + book/cancel | `StudentPtmController` |
| Transport Information | `GET /transport` | `StudentPortalController.transport()` |
| Hostel Information | `GET /hostel` | `StudentPortalController.hostel()` (stub — blocked on Hostel module) |

Leave applications support the full lifecycle: create (future-date validated) → Pending → Admin Approve/Reject → Student Cancel. Status FSM: Draft → Submitted/Pending → Approved/Rejected/Cancelled.

---

## Resources — Notice Board, Study Resources, Prescribed Books, School Calendar

| Screen | Route | Controller Method |
|--------|-------|-------------------|
| Notice Board | `GET /notice-board` | `noticeBoard()` |
| Study Resources | `GET /study-resources` | `studyResources()` |
| Prescribed Books | `GET /prescribed-books` | `prescribedBooks()` |
| School Calendar | `GET /school-calendar` | `schoolCalendar()` |

**Known Issue:** The Notice Board currently loads `auth()->user()->notifications()` (personal inbox) instead of a dedicated school announcements model — students miss official notices.

---

## Support — Complaints, Grievances, Notifications, Chat, Recommendations

| Screen | Route | Controller |
|--------|-------|------------|
| Complaints | `GET /complaint{/create,/store,/show}` | `StudentPortalComplaintController` |
| Exam Grievances | `GET /my-grievances` + create/store | `StudentGrievanceController` |
| Notifications | `GET /all-notifications` | `NotificationController` |
| Chat | `GET /chat` | `StudentChatController` |
| Recommendations | `GET /my-recommendations{/show,/status,/rate}` | `StudentRecommendationPortalController` |

**Known Issue:** Complaint form uses hardcoded dropdown ID `104` for complainant type instead of key-based lookup (`COMPLAINANT_STUDENT`) — breaks after re-seed.

---

## Reports — Progress Card, Performance Analytics, ID Card, Health Records

| Screen | Route | Controller Method |
|--------|-------|-------------------|
| Progress Card | `GET /progress-card` | `progressCard()` |
| Performance Analytics | `GET /performance-analytics` | `performanceAnalytics()` |
| Student ID Card | `GET /student-id-card` | `idCard()` — loads student, healthProfile, addresses, guardians, currentSession |
| Health Records | `GET /health-records` | `healthRecords()` — loads student, healthProfile |

---

## Requirements

- The system MUST authenticate students via the existing Laravel `auth` guard with Sanctum token support for mobile API access
- The system MUST scope ALL data queries to the authenticated student's identity (`auth()->user()->student`), enforcing BR-STP-001 data isolation
- The system MUST display a dashboard aggregating attendance %, pending homework count, upcoming exams count, fee due amount, leave counts, today's timetable, recent results, and notifications
- The system MUST provide read-only views for academic information, fee invoices, attendance records, exam schedules, results, prescribed books, study resources, transport, health records, and the school calendar
- The system MUST implement a full online exam/quiz/quest attempt engine with timed player, checkpoint recovery, auto-submit on timeout, and result display
- The system MUST support homework list/detail/submit flow with file upload validation (max 10 MB, restricted MIME types) and late-submission gating
- The system MUST support complaint creation with category/subcategory dropdowns, file attachment (max 5 MB), and listing with pagination
- The system MUST support leave application lifecycle (create → pending → approve/reject/cancel) with future-date validation
- The system MUST display a secure digital ID card with student photo, academic identifiers, blood group, emergency contact, and QR barcode
- The system MUST display health records including vital statistics, medical conditions/allergies, immunization log, medical history, and emergency action details
- The system MUST integrate with the Library module for catalogue browsing, book reservation, renewal, digital access, and wishlist management
- The system MUST log all state-changing operations (dashboard view, account view, academic info view, exam attempts, homework submissions, complaints, etc.) via `activityLog()` helper

## Dependencies (Modules & Tables)

### Primary Tables (STP-Owned)

| Table Name | Description | Area |
|-----------|-------------|------|
| `lms_exam_attempts` | Online exam attempt records — student, paper, status, timestamps, violation count, IP, browser | Attempt Engine |
| `lms_exam_attempt_answers` | Per-question answers for exam attempts | Attempt Engine |
| `lms_exam_grievances` | Post-exam grievance records — type, description, status, marks changed | Attempt Engine |
| `lms_quiz_quest_attempts` | Quiz/Quest attempt records (polymorphic via assessment_type) | Attempt Engine |
| `lms_quiz_quest_attempt_answers` | Per-question answers for quiz/quest attempts | Attempt Engine |
| `lms_attempt_checkpoints` | Checkpoint snapshots for browser-crash resume | Attempt Engine |
| `lms_attempt_activity_logs` | Anti-cheat activity log (tab switches, etc.) | Attempt Engine |

### External Module Dependencies

| Source Module | Data / Entity | Why STP Needs It |
|--------------|--------------|-----------------|
| **StudentProfile (STD)** | Student identity, profile, guardians, addresses, academic session, health, attendance | Core identity chain; all portal screens derive from this |
| **StudentFee (FIN)** | Fee assignments, fee invoices | Fee summary, invoice view, payment initiation |
| **Payment** | PaymentService API, payment gateways | Razorpay checkout creation |
| **Notification** | User notifications (Laravel Notifiable) | Notifications inbox; notification count on dashboard |
| **Complaint (CMP)** | Complaint records, categories | Complaint listing and submission |
| **TimetableFoundation** | Timetable cells, school days | Timetable grid, teachers directory, timetable widget on dashboard |
| **LmsExam** | Exam allocations, exam papers, paper sets, exam results | Exam schedule, online exam player, results view |
| **LmsHomework** | Homework records, submission records | Homework list, homework submission, dashboard homework widget |
| **LmsQuiz** | Quiz records, quiz allocations | Quiz player, learning hub |
| **LmsQuests** | Quest records, quest allocations | Quest player, learning hub |
| **QuestionBank** | Questions, answer options | Online exam/quiz/quest player (question rendering) |
| **Syllabus** | Syllabus schedule records | Syllabus progress tracker |
| **HPC** | HPC report records | Progress card screen |
| **Recommendation (REC)** | Student recommendation records | My Recommendations screen |
| **Library (LIB)** | Book master records, library memberships, transactions | Library browse, my borrowed books, reserve/renew/digital access |
| **Transport (TPT)** | Student transport allocations, routes, stops | Transport information screen |
| **SyllabusBooks (BOK)** | Prescribed books, book-class-subject mapping | Study resources, prescribed books screen |
| **Hostel (HST)** | Hostel room allocations, mess schedule | Hostel screen (planned — stub only) |
| **SystemConfig** | Dropdown values, user auth record | Complaint form dropdowns, authentication identity |

### Known Critical Gaps

| Gap | Severity | Description |
|-----|----------|-------------|
| Zero `Gate::authorize()` calls | P0 | All 18 web controllers lack authorization gates — systemic security gap |
| IDOR in `proceedPayment()` | P0 | Student A can initiate payment on Student B's invoice |
| Missing `EnsureTenantHasModule` | P0 | StudentPortal routes accessible even when module is not in tenant's plan |
| Hardcoded dropdown ID 104 | P0 | Complaint form complainant type resolved by ID, not key — breaks after re-seed |
| `currentFeeAssignemnt` typo | P1 | Misspelled relationship name causes silent null in 3 controller methods |
| Notice board uses wrong data source | P1 | Shows personal notifications instead of school announcements |
| Results screen shows no marks | P1 | `lms_exam_results` not integrated into results controller |
| Student ID Card PDF route missing | P1 | No download/print PDF endpoint defined |
