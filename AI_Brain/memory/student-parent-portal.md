---
name: Student & Parent Portal Architecture
description: Comprehensive architecture, screens, and requirements for Student Portal (27 screens) and Parent Portal (23 screens)
type: reference
---

# Student & Parent Portal — Architecture Reference

> **Source:** Team member's architecture packs (v2/v3) from `pgdatabase/7-Work_on_Modules/StudentParentPortal/`
> **Last Updated:** 2026-03-21
> **Overall Maturity:** Student Portal ~28% | Parent Portal ~5%

## Student Portal Screens (S1-S27)

| ID | Screen Name | Route | Key Tables | Status |
|----|-------------|-------|------------|--------|
| S1 | Login / Authentication | `/student-portal/login` | `sys_users` | 80% Existing |
| S2 | Dashboard | `/student-portal/dashboard` | `std_attendance`, `lms_exams`, `lms_homework`, `fin_fee_invoices`, `tt_timetable_cells` | 15% Partial (dummy data) |
| S3 | Profile / Account / Settings | `/student-portal/account` | `sys_users`, `std_students`, `std_guardians` | 30% Partial (no POST) |
| S4 | Academic Information | `/student-portal/academic-information` | `sch_academic_sessions`, `sch_class_sections`, `slb_subject_syllabus`, `slb_lessons` | 40% Partial |
| S5 | Attendance | `/student-portal/attendance` | `std_attendance`, `sch_holidays` | 10% Partial (dummy) |
| S6 | Timetable / Class Schedule | `/student-portal/timetable` | `tt_timetable_cells`, `tt_activities` | 5% Stub |
| S7 | Lesson Plan / Digital Content | `/student-portal/lessons` | `slb_lessons`, `slb_topics` | 0% Missing |
| S8 | Homework | `/student-portal/homework` | `lms_homework`, `lms_homework_allocations`, `lms_homework_submissions` | 0% Missing |
| S9 | Assignments | `/student-portal/assignments` | `lms_assignments`, `lms_assignment_allocations` | 0% Missing |
| S10 | Quiz / Assessment | `/student-portal/quizzes` | `lms_quizzes`, `lms_quiz_allocations`, `lms_quiz_attempts`, `qns_question_banks` | 0% Missing |
| S11 | Question Bank / Self-Practice | `/student-portal/practice` | `qns_question_banks`, `qns_question_options`, `slb_topics` | 0% Missing |
| S12 | Exam Timetable | `/student-portal/exam-timetable` | `lms_exams`, `lms_exam_allocations` | 0% Missing |
| S13 | Exam Modes (Online/Offline/Hybrid/Practical) | `/student-portal/exams/{id}/attempt` | `lms_exams`, `lms_exam_attempts`, `qns_paper_sets` | 0% Missing -- CRITICAL |
| S14 | Result / Marksheet / Report Card | `/student-portal/results` | `lms_exam_results`, `hpc_reports` | 0% Missing |
| S15 | Gradebook | `/student-portal/gradebook` | `lms_exam_results`, `lms_quiz_attempts`, `lms_homework_submissions` | 0% Missing |
| S16 | Course / LMS View | `/student-portal/courses` | `lms_courses`, `lms_course_modules`, `lms_course_enrollments` | 0% Missing |
| S17 | Certificates | `/student-portal/certificates` | `std_certificates`, `lms_course_enrollments` | 0% Missing |
| S18 | Quest / Gamification / Badges | `/student-portal/quests` | `lms_quests`, `lms_quest_allocations`, `lms_quest_badges` | 3% Stub |
| S19 | Fee / Invoice / Payment | `/student-portal/fees` | `fin_fee_assignments`, `fin_fee_invoices`, `fin_fee_receipts` | 45% Partial (SEC bug) |
| S20 | Complaint / Grievance | `/student-portal/complaint` | `cmp_complaints`, `cmp_complaint_categories` | 60% Partial |
| S21 | Notifications | `/student-portal/all-notifications` | `notifications` (polymorphic) | 65% Existing |
| S22 | Document Vault | `/student-portal/documents` | `std_documents`, `fin_fee_receipts` | 10% Partial |
| S23 | Events / School Calendar | `/student-portal/events` | `sch_school_events` (NEW), `sch_holidays` | 0% Missing |
| S24 | Transport Visibility | `/student-portal/transport` | `tpt_student_route_allocation_jnt`, `tpt_routes`, `tpt_stops` | 0% Missing |
| S25 | AI Insights / Progress Analytics | `/student-portal/insights` | All academic data aggregated | 0% Missing |
| S26 | Health & Medical Records | `/student-portal/health` | `std_medical_details` (NEW) | 0% Missing |
| S27 | Mentorship & Career Pathing | `/student-portal/mentorship` | `std_mentorship_assignments` (NEW) | 0% Missing |

## Parent Portal Screens (P1-P23)

Parent portal is READ-ONLY + monitoring. Every screen requires child context validation via `std_student_guardian_jnt`.

| ID | Screen Name | Route | Key Tables | Status |
|----|-------------|-------|------------|--------|
| P1 | Login / Auth / Access | `/parent-portal/login` | `sys_users`, `std_guardians`, `std_student_guardian_jnt` | 0% Missing |
| P2 | Dashboard | `/parent-portal/dashboard` | Aggregates from all child data sources | 0% Missing |
| P3 | Multi-Child Switcher | `POST /parent-portal/child/switch` | `std_student_guardian_jnt` (Global Component) | 0% Missing |
| P4 | Child Academic Snapshot | `/parent-portal/child/{id}/academic` | `std_students`, `slb_subject_syllabus`, `std_attendance` | 0% Missing |
| P5 | Attendance Visibility | `/parent-portal/child/{id}/attendance` | `std_attendance`, `sch_holidays` | 0% Missing |
| P6 | Timetable Visibility | `/parent-portal/child/{id}/timetable` | `tt_timetable_cells`, `tt_activities` | 3% Partial |
| P7 | Homework Monitoring | `/parent-portal/child/{id}/homework` | `lms_homework`, `lms_homework_submissions` | 0% Missing |
| P8 | Assignment Monitoring | `/parent-portal/child/{id}/assignments` | `lms_assignments`, `lms_assignment_submissions` | 0% Missing |
| P9 | Quiz Monitoring | `/parent-portal/child/{id}/quizzes` | `lms_quizzes`, `lms_quiz_attempts` | 0% Missing |
| P10 | Exam Timetable Visibility | `/parent-portal/child/{id}/exams` | `lms_exams`, `lms_exam_allocations` | 0% Missing |
| P11 | Exam Visibility (Online/Offline/Practical) | Part of P10 detail | `lms_exams`, `lms_exam_attempts` | 0% Missing |
| P12 | Result / Report Card | `/parent-portal/child/{id}/results` | `lms_exam_results`, `hpc_reports` | 0% Missing |
| P13 | HPC / Holistic Progress Card | `/parent-portal/child/{id}/hpc` | `hpc_parent_form_tokens`, `hpc_reports` | 70% Partial (token works) |
| P14 | Fee Management | `/parent-portal/child/{id}/fee` | `fin_fee_invoices`, `fin_fee_receipts` | 0% Missing |
| P15 | Notification Management | `/parent-portal/notifications` | `notifications`, `notification_preferences` | 0% Missing |
| P16 | Communication / Messaging | `/parent-portal/messages` | `msg_threads` (NEW), `msg_messages` (NEW) | 0% Missing |
| P17 | Complaint / Escalation | `/parent-portal/complaint` | `cmp_complaints`, `cmp_complaint_categories` | 0% Missing |
| P18 | Document Vault | `/parent-portal/child/{id}/documents` | `std_documents`, `fin_fee_receipts` | 0% Missing |
| P19 | Events / Calendar / RSVP | `/parent-portal/events` | `sch_school_events` (NEW), `sch_event_rsvp` (NEW) | 0% Missing |
| P20 | PTM Slot Booking | `/parent-portal/ptm` | `sch_ptm_events` (NEW), `sch_ptm_teacher_slots` (NEW), `sch_ptm_bookings` (NEW) | 0% Missing |
| P21 | Quest / Badge Monitoring | `/parent-portal/child/{id}/quests` | `lms_quests`, `lms_quest_badges` | 0% Missing |
| P22 | Certificate Visibility | `/parent-portal/child/{id}/certificates` | `std_certificates` | 0% Missing |
| P23 | Transport Visibility | `/parent-portal/child/{id}/transport` | `tpt_student_route_allocation_jnt`, `tpt_routes` | 0% Missing |

## Architecture Decisions

1. **Separate Modules**: `Modules/StudentPortal/` and `Modules/ParentPortal/` as distinct nwidart modules; both consume data from dependent modules (never own the data).
2. **Custom Middleware**: `EnsureStudentAccess` (checks `user_type=STUDENT`, `is_active`, student record linkage) and `EnsureParentAccess` (checks `user_type=PARENT`, `is_active`, guardian record, at least one `can_access_parent_portal=true` child).
3. **Multi-Child Context (Parent)**: Selected child stored in `session('parent_selected_student_id')`. Every parent controller method validates child belongs to guardian via junction table with `can_access_parent_portal=true`. Auto-selects first accessible child on login.
4. **Service Layer**: Dedicated aggregator services -- `StudentDashboardAggregatorService`, `ParentDashboardAggregatorService`, `ParentChildContextService`, `StudentExamService`, `StudentFeeService`, `StudentProgressService`, `ParentFeeService`.
5. **Routes in tenant.php**: All routes registered in `routes/tenant.php` (module `routes/web.php` intentionally unused). Student prefix: `/student-portal/*`. Parent prefix: `/parent-portal/*`.
6. **5-Layer Security**: Tenant isolation (stancl/tenancy) -> Authentication (Laravel session) -> Role verification (custom middleware) -> Data ownership (query scoping) -> Gate authorization (feature-specific: `is_fee_payer`, `medical_consent`, result publication).
7. **Anti-Cheat for Online Exams (S13)**: Server-side timer, fullscreen enforcement, tab-switch detection, copy-paste disabled, DevTools detection, auto-save every 60s, auto-submit on expiry.
8. **Fee Payment Gate**: Only parents with `is_fee_payer=true` on `std_student_guardian_jnt` can initiate Razorpay payment. Non-fee-payer parents see summary only.
9. **Caching Strategy**: Per-student per-day cache for dashboard widgets. Per-guardian per-child per-date for parent dashboard. Redis/File driver.

## Dependencies on Other Modules

| Portal Screen(s) | Depends On Module | Tables Used |
|-------------------|-------------------|-------------|
| S1, P1 | Core Auth | `sys_users`, `sessions`, `password_reset_tokens` |
| S2, S3, S4, P2, P3, P4 | StudentProfile | `std_students`, `std_guardians`, `std_student_guardian_jnt` |
| S4, S7 | Syllabus | `slb_lessons`, `slb_topics`, `slb_subject_syllabus` |
| S5, P5 | Attendance | `std_attendance` |
| S6, P6 | SmartTimetable | `tt_timetable_cells`, `tt_activities` |
| S8, S9, P7, P8 | LmsHomework | `lms_homework`, `lms_homework_allocations`, `lms_homework_submissions` |
| S10, P9 | LmsQuiz | `lms_quizzes`, `lms_quiz_allocations`, `lms_quiz_attempts` |
| S11 | QuestionBank | `qns_question_banks`, `qns_question_options` |
| S12, S13, S14, P10, P11, P12 | LmsExam | `lms_exams`, `lms_exam_allocations`, `lms_exam_attempts`, `lms_exam_results` |
| S14, P13 | HPC | `hpc_reports`, `hpc_parent_form_tokens` |
| S18, P21 | LmsQuests | `lms_quests`, `lms_quest_allocations`, `lms_quest_badges` |
| S19, P14 | StudentFee (Finance) | `fin_fee_assignments`, `fin_fee_invoices`, `fin_fee_receipts` |
| S20, P17 | Complaint | `cmp_complaints`, `cmp_complaint_categories` |
| S21, P15 | Notification | `notifications` (polymorphic) |
| S24, P23 | Transport | `tpt_routes`, `tpt_stops`, `tpt_student_route_allocation_jnt` |
| S4, S23, P19 | SchoolSetup | `sch_academic_sessions`, `sch_class_sections`, `sch_holidays` |

## LMS Integration Points

From LMS v4 documentation (6 modules: Syllabus, LmsQuiz, LmsQuests, LmsExam, LmsHomework, QuestionBank):

- **Quiz Taking (S10)**: Student starts attempt via `lms_quiz_attempts`. Questions loaded from `qns_question_banks` via `lms_quiz_allocations`. Server-side timer. Shuffle if `shuffle_questions=true`. Max attempts configurable. Instant result if `show_result_immediately=true`.
- **Homework Submission (S8)**: Student submits via file upload (PDF/JPG/PNG/DOC, max 10MB) or text entry. Late submission gated by `restrict_late_submission` flag. Grading + feedback by teacher.
- **Exam Modes (S13)**: Online (ONXO) = full anti-cheat exam interface; Offline (OFFL) = info + venue only; Hybrid = combined; Practical = lab info. Paper sets from `qns_paper_sets`. Negative marking, section-wise time limits, question flagging.
- **Gradebook (S15)**: Aggregates ALL graded activities (exams via `lms_exam_results`, quizzes via `lms_quiz_attempts`, homework via `lms_homework_submissions`). Weighted per school grading policy.
- **Self-Practice (S11)**: Ungraded practice from approved `qns_question_banks`. Instant feedback + explanations. Tracks history for AI insights.
- **Difficulty Engine**: LmsQuiz and LmsExam share `DifficultyDistributionConfig` for question selection. 5-step validation at add-time. Portal shows difficulty labels but does not interact with engine.

## Known Security Issues

| ID | Severity | Screen | Issue |
|----|----------|--------|-------|
| SR-AUTH-001 | CRITICAL | S19 | Fee routes lack ownership checks (student can see other invoices) |
| SEC-004 | CRITICAL | S19/P14 | Razorpay webhook broken -- prevents invoice status updates |
| SR-AUTH-003 | HIGH | S20/S21 | AJAX endpoints (subcategory, mark-read) lack auth checks |
| SR-AUTH-004 | HIGH | S21 | `testNotification` has hardcoded `user_id` |
| QB-SEC-001 | CRITICAL | S11 | Hardcoded API keys in `AIQuestionGeneratorController` (needs `.env`) |
| BUG-007 | MEDIUM | P14 | `Student::currentFeeAssignment()` crashes on null session (needs `?->id`) |

## New Tables Required

| Table | Needed By | Purpose |
|-------|-----------|---------|
| `sch_school_events` | S23, P19 | School events/calendar data |
| `sch_event_rsvp` | P19 | Parent RSVP for events |
| `sch_event_volunteer_roles` | P19 | Volunteer role definitions |
| `sch_event_volunteer_signup` | P19 | Volunteer sign-ups |
| `sch_ptm_events` | P20 | PTM event definitions |
| `sch_ptm_teacher_slots` | P20 | Teacher time slots for PTM |
| `sch_ptm_bookings` | P20 | Parent slot bookings |
| `sch_ptm_meeting_notes` | P20 | Post-PTM teacher notes |
| `msg_threads` | P16 | Parent-teacher message threads |
| `msg_messages` | P16 | Individual messages |
| `msg_attachments` | P16 | Message file attachments |
| `std_medical_details` | S26 | Student health/medical records |
| `std_vaccination_records` | S26 | Vaccination records |
| `std_mentorship_assignments` | S27 | Mentor-student mapping |
| `std_career_assessments` | S27 | Career interest assessment results |
| `std_certificates` | S17, P22 | Earned certificates (if not already exists) |

## Reference File Locations

| Category | Path |
|----------|------|
| Student Portal v2 requirements | `{DB_REPO}/7-Work_on_Modules/StudentParentPortal/v2/student_portal_requirements_v2.md` |
| Parent Portal v2 requirements | `{DB_REPO}/7-Work_on_Modules/StudentParentPortal/v2/parent_portal_requirements_v2.md` |
| Architecture Packs (Student v2) | `{DB_REPO}/7-Work_on_Modules/StudentParentPortal/v2/architecture_pack/StudentPortal_Detailed_Screens/S1-S27/` |
| Architecture Packs (Parent v2) | `{DB_REPO}/7-Work_on_Modules/StudentParentPortal/v2/architecture_pack/ParentPortal/P1-P16/` |
| Architecture Packs (Student v3) | `{DB_REPO}/7-Work_on_Modules/StudentParentPortal/v3/architecture_pack/StudentPortal_Detailed_Screens/S1/` |
| v3 System Design & Flowcharts | `{DB_REPO}/7-Work_on_Modules/StudentParentPortal/v3/system_design_and_flowcharts_v3.md` |
| LMS v4 summary | `{DB_REPO}/7-Work_on_Modules/LMS/v4/lms_summary_index.md` |
| LMS v4 requirements | `{DB_REPO}/7-Work_on_Modules/LMS/v4/lms_requirements.md` |
| Student portal generation prompt | `{DB_REPO}/8-Team_Work/Shailesh/Student Parent Portal/student_portal_prompt.md` |
| Parent portal generation prompt | `{DB_REPO}/8-Team_Work/Shailesh/Student Parent Portal/parent_portal_prompt.md` |

`{DB_REPO}` = `/Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase`
