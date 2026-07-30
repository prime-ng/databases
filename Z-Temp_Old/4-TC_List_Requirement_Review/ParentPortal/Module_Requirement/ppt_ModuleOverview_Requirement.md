# ParentPortal Module — Business Requirements Overview

## Module Purpose

The Parent Portal (PPT) gives parents and guardians of enrolled students a dedicated, mobile-first self-service interface to monitor and engage with their child's school journey. Parents can view attendance, results, homework status, and timetables; pay school fees online; apply for child leave; sign digital consent forms; book Parent-Teacher Meeting slots; and download official documents — all from a single authenticated portal, with multi-child support for families with multiple enrolled children.

### Business Value

| Parent Pain Point | Portal Solution |
|---|---|
| "Is my child present today?" | Real-time absence alert + monthly attendance calendar |
| "How much fee is due?" | Live fee ledger + one-tap payment via Razorpay (UPI/Card/NetBanking) |
| "What homework is pending?" | Daily homework tracker showing due dates and submission status per subject |
| "What did my child score?" | Subject-wise marks with class-average comparison; report card download |
| "Can I speak to the maths teacher?" | Private messaging with read receipts (pending ppt_messages table build) |
| "I need the TC urgently" | Online document request with status tracking and digital delivery |
| "When is the PTM?" | PTM slot booking with reminder notifications |
| "School sent a consent form" | Digital sign / decline with e-signature and PDF confirmation |

---

## Tab Groups

| # | Tab Group | Route Prefix | Controller | Features |
|---|---|---|---|---|
| 1 | **Dashboard** | `/parent-portal/` | ParentDashboardController | Unified snapshot (attendance %, today timetable, pending homework 5, upcoming exams 5, fee summary, leave counts, recent notifications 5) |
| 2 | **My Children** | `/parent-portal/children` | ParentDashboardController@children | Lists all linked children with class/section info; subject list per class |
| 3 | **Attendance** | `/parent-portal/attendance/` | ParentAttendanceController | Monthly calendar, subject-wise breakdown, year-to-date percentage |
| 4 | **Timetable** | `/parent-portal/timetable` | ParentTimetableController | Weekly day × period grid; current period highlighted |
| 5 | **Homework** | `/parent-portal/homework/` | ParentHomeworkController | Pending/submitted/overdue/graded per subject |
| 6 | **Results** | `/parent-portal/results/` | ParentResultController | Term-wise marks, report card PDF download (gated by publish) |
| 7 | **Fees** | `/parent-portal/fees/` | ParentFeeController | Invoice view, payment history, Razorpay payment, PDF receipt |
| 8 | **Leave** | `/parent-portal/leave/` | ParentLeaveController | Submit/withdraw child leave; teacher approval flow |
| 9 | **Consent Forms** | `/parent-portal/consent-forms/` | ParentConsentFormController | View/sign/decline school consent forms; immutable responses |
| 10 | **PTM** | `/parent-portal/ptm/` | ParentPtmController | Slot booking, cancellation, rescheduling |
| 11 | **Events** | `/parent-portal/events/` | ParentEventController | Event calendar, RSVP, volunteer sign-up, .ics export |
| 12 | **Documents** | `/parent-portal/documents/` | ParentDocumentController | Vault download, request duplicates, Razorpay fee gate |
| 13 | **Complaints** | `/parent-portal/complaint/` | ParentComplaintController | File/view school complaints with subcategory routing |
| 14 | **Notifications** | `/parent-portal/notifications/` | ParentNotificationController | Unified inbox, mark read/all read |
| 15 | **Teachers** | `/parent-portal/teachers` | ParentTeacherController | Contact list for child's assigned teachers |
| 16 | **Transport** | `/parent-portal/transport` | ParentTransportController | Bus route, driver, stop info (read-only) |
| 17 | **Hostel** | `/parent-portal/hostel` | ParentHostelController | Hostel allocation details (read-only, module-gated) |
| 18 | **Health** | `/parent-portal/health/` | ParentHealthController | HPC records, counsellor reports (gated by visibility flags) |
| 19 | **Learning Hub** | `/parent-portal/learning` | ParentLearningController | Quiz/quest/exam activity overview (read-only) |
| 20 | **Account Settings** | `/parent-portal/account/` | ParentAccountController | Profile, password, notification prefs, quiet hours, devices, language |

---

## Requirements

- The system MUST provide a single authenticated portal for parents/guardians to view all academic and financial data of their linked children.
- The system MUST support multi-child families: a parent's active child selection is persisted in `ppt_parent_sessions.active_student_id` and survives page reloads, device switches, and session expiry.
- The system MUST enforce child ownership on every data endpoint — a parent may only access data for children linked via `std_student_guardian_jnt` with `can_access_parent_portal = 1`.
- The system MUST provide read-only views for attendance, timetable, homework, results, health, transport, hostel, and learning hub — parents cannot modify academic or operational data.
- The system MUST support online fee payment via Razorpay (UPI/Card/NetBanking/Wallet) with server-side signature verification and payment_id idempotency to prevent double-credit.
- The system MUST support leave application workflow: parent submits → class teacher approves/rejects → attendance module updated on approval.
- The system MUST support digital consent forms with immutable response records (no soft-delete on `ppt_consent_form_responses`), IP-captured signature, and deadline gating.
- The system MUST support PTM slot booking with database-level concurrency prevention (SELECT...FOR UPDATE) and cancellation time guard (>= 1 hour before PTM).
- The system MUST provide a notification inbox with read/unread tracking and per-channel notification preferences (in-app, SMS, email, WhatsApp) stored in `ppt_parent_sessions.notification_preferences_json`.
- The system MUST implement quiet hours during which non-urgent notifications are buffered; AbsenceAlert and EmergencyAlert always bypass quiet hours.
- The system MUST gracefully degrade when dependent modules are inactive — show "Feature not available" message; never a 500 error.
- The system MUST log all parent actions (view, payment, message, leave) to `sys_activity_logs` with student context.

---

## Dependencies

### Primary Tables (PPT-owned)

| Table | Purpose | Key Constraints |
|---|---|---|
| `ppt_parent_sessions` | Per-device portal state: active child, push tokens, notification preferences, quiet hours | UNIQUE (guardian_id, device_token_fcm); FK → std_guardians, std_students |
| `ppt_event_rsvps` | Parent RSVPs and volunteer sign-ups for school events | UNIQUE (event_id, guardian_id); NO deleted_at |
| `ppt_document_requests` | Online requests for duplicate certificates and official documents | UNIQUE (request_number); UNIQUE (payment_reference) |
| `ppt_consent_forms` | School digital consent forms with deadline and class targeting | FK → sch_classes, sch_sections, sys_users |
| `ppt_consent_form_responses` | Immutable parent consent responses with e-signature | UNIQUE (consent_form_id, student_id, guardian_id); NO deleted_at |

### External Module Dependencies

| # | Module | Tables / Data | Access Type |
|---|---|---|---|
| 1 | **StudentProfile** | `std_students`, `std_guardians`, `std_student_guardian_jnt` | Read (ownership check) |
| 2 | **SchoolSetup** | `sch_classes`, `sch_sections`, `sch_holidays` | Read (context + holiday calc) |
| 3 | **SystemConfig** | `sys_users`, `sys_media`, `sys_school_settings` | Read (auth, files, flags) |
| 4 | **StudentAttendance** | `std_attendance`, `std_subject_attendance` | Read (monthly + subject-wise) |
| 5 | **SmartTimetable** | `tt_timetable_cells`, `tt_published_timetables` | Read (weekly grid) |
| 6 | **TimetableFoundation** | Academic terms, period sets | Read (term selector, period context) |
| 7 | **LmsHomework** | `hmw_assignments`, `hmw_submissions` | Read (homework tracker) |
| 8 | **LmsExam** | `exm_results`, `exm_report_cards` | Read (results + publish gate) |
| 9 | **StudentFee** | `fin_fee_invoices`, `fin_fee_installments`, `fin_transactions` | Read + Write (payment) |
| 10 | **Payment (Razorpay)** | Razorpay orders, webhooks | Integration (payment flow) |
| 11 | **Ptm** | `ptm_events`, `ptm_teacher_slots`, `ptm_bookings` | Read + Write (slot booking) |
| 12 | **EventEngine** | Event records (source for ppt_event_rsvps.event_id) | Read (event catalog) |
| 13 | **Notification** | `ntf_notifications`, `ntf_circulars`, FCM/APNs | Read + Write (inbox + push) |
| 14 | **Hpc** | `hpc_health_profiles`, `hpc_physical_assessments`, `hpc_counsellor_reports` | Read (gated) |
| 15 | **Transport** | `tpt_routes`, `tpt_vehicles`, `tpt_student_route_jnt`, `tpt_stops` | Read |
| 16 | **Hostel** | `hst_allotments`, `hst_rooms`, `hst_buildings` | Read |
| 17 | **LmsQuiz** | Quiz attempt tables | Read (learning hub summary) |
| 18 | **LmsQuests** | Quest attempt tables | Read (learning hub summary) |
| 19 | **Complaint** | `cmp_complaints`, `cmp_categories` | Read + Write |
| 20 | **Leave (StudentProfile)** | `student_leave_applications` (or equivalent) | Read + Write + Event dispatch |

### Pending Tables (Gaps)

| Entity | Planned Table | Priority | Gap |
|---|---|---|---|
| Teacher Message | `ppt_messages` | P0 | Not in DDL v2; no MessageController |
| Leave Application | `ppt_leave_applications` | P0 | Not in DDL v2; controller exists but no backing migration |

---

## #. Known Gaps (P0)

| Gap ID | Issue | Impact | Resolution |
|---|---|---|---|
| GAP-PPT-001 | `ParentChildPolicy` MISSING — no global child ownership Gate | IDOR vulnerability on all data endpoints | Build policy + apply to all 21 web controllers |
| GAP-PPT-002 | OTP AuthController NOT STARTED — no routes for OTP login | P0 login feature absent | Build controller + rate-limiter + routes |
| GAP-PPT-003 | `ppt_leave_applications` migration MISSING | LeaveController crashes at runtime | Create migration + model |
| GAP-PPT-004 | `ppt_messages` table absent; teacher messaging deferred | P0 messaging feature not deliverable | Decide: build ppt_messages or integrate CommonChat |
