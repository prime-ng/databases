# PPT — Parent Portal
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** RBS_ONLY

---

## 1. Executive Summary

The Parent Portal (PPT) module provides a dedicated, parent-facing self-service interface within the Prime-AI multi-tenant SaaS platform. Parents of enrolled students can monitor their child's academic journey — attendance, grades, homework, timetable, fee dues, health reports — and take actions such as online fee payment, leave application submission, teacher messaging, and document download, all from a mobile-first responsive portal.

This module is a **Greenfield** implementation (0% code, 0% DDL). All functional requirements are marked 📐 Proposed. The module is primarily a **read-aggregation layer** over existing module data (StudentProfile, StudentFee, SmartTimetable, LmsHomework, LmsExam, HPC, Transport, Notification), introducing only 6 new `ppt_*` tables for portal-specific state.

The portal is the parent-facing counterpart to the Student Portal (`STP` module). Both share the same tenant infrastructure and auth system but render role-specific UI for the `PARENT` user type.

**Key V2 additions over V1:** Parent-Teacher Meeting (PTM) scheduling, digital consent forms, OTP-based passwordless login, PWA push notification support, and a dedicated `ppt_consent_forms` table.

---

## 2. Module Overview

### 2.1 Business Context

Indian school parents — especially urban and semi-urban — expect digital access to their child's school data. Traditional physical diaries and termly PTMs are insufficient. Key pain points this portal solves:

| Pain Point | Solution |
|---|---|
| "Is my child present today?" | Real-time absence alert + monthly attendance calendar |
| "How much fee is due?" | Live fee ledger + one-tap UPI/card payment via Razorpay |
| "What is my child's rank?" | Subject-wise marks, class average comparison, report card download |
| "What homework is pending?" | Daily homework tracker showing due dates and submission status |
| "I need the TC urgently" | Online document request with status tracking and digital delivery |
| "Can I talk to the Math teacher?" | Direct private messaging with read receipts |
| "When is the annual function?" | Event calendar with RSVP and volunteer sign-up |

### 2.2 Scope

**In Scope:**
- Parent authentication (OTP-based passwordless + password login)
- Multi-child support — one parent account, multiple enrolled children
- Unified dashboard: attendance %, last test score, pending homework, fee dues, today's timetable
- Attendance: monthly calendar view, subject-wise breakdown, YTD percentage
- Fee management: invoice view, Razorpay online payment (UPI/card/netbanking/wallet), PDF receipt
- Academic results: term-wise marks, subject-wise grades, report card download
- Homework tracker: pending/submitted/overdue homework per subject
- Timetable: published weekly schedule for child's class+section
- Teacher messaging: direct message with file attachments and read receipts
- Leave application: apply and track leave approval for child
- Digital consent forms: view and sign school consent forms for activities/trips
- Parent-Teacher Meeting (PTM) scheduling: book available slots
- Notification inbox: circulars, announcements, alerts
- Push notifications: FCM (Android) + APNs (iOS) + Web Push (PWA)
- Health reports: HPC module read-view (gated by school settings)
- Transport tracking: bus route + live status if Transport module active
- Events: school event calendar, RSVP, volunteer sign-up
- Document vault: report cards, certificates, medical records download
- Document requests: request duplicate certificates online
- Account settings: profile, notification preferences, quiet hours

**Out of Scope (V2):**
- Direct video/audio calling with teachers (requires WebRTC)
- Parent-to-parent social messaging
- Payment dispute/chargeback management
- Real-time GPS tracking (requires hardware integration)
- Native mobile app (portal is PWA; native app is a separate initiative)

### 2.3 Authentication & Child Context Flow

```
Parent logs in (OTP or password) → user_type = PARENT
→ std_guardians WHERE user_id = sys_users.id
→ std_student_guardian_jnt WHERE guardian_id AND can_access_parent_portal = 1
→ List of linked children (std_students records)
→ Parent selects active child (stored in ppt_parent_sessions.active_student_id)
→ ALL portal data views filter by active child's std_students.id
→ ParentChildPolicy enforced on every data request
```

A parent with multiple children sees a child-switcher widget in the top navigation on every screen.

### 2.4 Module Architecture

```
Modules/ParentPortal/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── ParentPortalController.php          # Dashboard, child-switcher
│   │   │   ├── AttendanceViewController.php
│   │   │   ├── TimetableViewController.php
│   │   │   ├── HomeworkViewController.php
│   │   │   ├── ResultViewController.php
│   │   │   ├── FeeViewController.php               # Fee view + Razorpay
│   │   │   ├── MessageController.php               # Parent-teacher messaging
│   │   │   ├── NotificationController.php          # Inbox + preferences
│   │   │   ├── EventController.php                 # Events + RSVP
│   │   │   ├── DocumentController.php              # Document vault + requests
│   │   │   ├── LeaveController.php                 # Leave application
│   │   │   ├── ConsentFormController.php           # Digital consent forms
│   │   │   ├── PtmController.php                   # PTM scheduling
│   │   │   ├── HealthReportController.php          # HPC read-view
│   │   │   ├── TransportViewController.php         # Bus tracking
│   │   │   └── AccountSettingsController.php       # Profile, prefs
│   │   ├── Middleware/
│   │   │   └── ParentPortalMiddleware.php          # Enforce PARENT user_type
│   │   └── Requests/
│   │       ├── ComposeMessageRequest.php
│   │       ├── ApplyLeaveRequest.php
│   │       ├── EventRsvpRequest.php
│   │       ├── DocumentRequestForm.php
│   │       ├── NotificationPreferencesRequest.php
│   │       ├── SwitchChildRequest.php
│   │       ├── FeePaymentRequest.php
│   │       ├── ConsentFormSignRequest.php
│   │       └── PtmBookingRequest.php
│   ├── Models/
│   │   ├── ParentSession.php                       # ppt_parent_sessions
│   │   ├── ParentMessage.php                       # ppt_messages
│   │   ├── ParentLeaveApplication.php              # ppt_leave_applications
│   │   ├── EventRsvp.php                           # ppt_event_rsvps
│   │   ├── DocumentRequest.php                     # ppt_document_requests
│   │   └── ConsentFormResponse.php                 # ppt_consent_form_responses
│   ├── Services/
│   │   ├── ParentDashboardService.php
│   │   ├── FeePaymentService.php
│   │   ├── MessagingService.php
│   │   ├── NotificationPreferenceService.php
│   │   └── PtmSchedulingService.php
│   └── Policies/
│       ├── ParentChildPolicy.php
│       ├── ParentMessagePolicy.php
│       └── ParentLeavePolicy.php
├── database/migrations/                            # 6 ppt_* migrations
├── resources/views/parent-portal/
│   ├── layouts/parent-portal.blade.php
│   ├── dashboard.blade.php
│   ├── children/
│   ├── attendance/
│   ├── timetable/
│   ├── homework/
│   ├── results/
│   ├── fees/
│   ├── messages/
│   ├── notifications/
│   ├── health-reports/
│   ├── leave/
│   ├── consent-forms/
│   ├── ptm/
│   ├── transport/
│   ├── events/
│   ├── documents/
│   └── settings/
└── routes/
    ├── api.php
    └── web.php
```

### 2.5 Module Statistics

| Metric | Count |
|---|---|
| New DB Tables (ppt_*) | 6 |
| Proposed Controllers | 16 |
| Proposed Services | 5 |
| Proposed Models | 6 (ppt_* only; other modules' models reused) |
| Proposed FormRequests | 9 |
| Proposed Policies | 3 |
| Proposed Named Routes (web) | ~75 |
| Proposed API Endpoints | ~18 |
| Proposed Blade Views | ~45 |
| Implementation Status | 0% (Greenfield) |

### 2.6 Menu Navigation

```
Parent Portal [/parent-portal]
├── Dashboard                       [/parent-portal/dashboard]
├── My Children                     [/parent-portal/children]
├── Academics
│   ├── Attendance                  [/parent-portal/attendance]
│   ├── Timetable                   [/parent-portal/timetable]
│   ├── Homework                    [/parent-portal/homework]
│   └── Results & Report Cards      [/parent-portal/results]
├── Fee & Payments
│   ├── Fee Summary                 [/parent-portal/fees]
│   └── Payment History             [/parent-portal/fees/history]
├── Communication
│   ├── Messages                    [/parent-portal/messages]
│   ├── Notifications               [/parent-portal/notifications]
│   └── PTM Scheduling              [/parent-portal/ptm]
├── Forms & Consents                [/parent-portal/consent-forms]
├── Leave Application               [/parent-portal/leave]
├── Health Reports                  [/parent-portal/health-reports]
├── Transport                       [/parent-portal/transport]
├── Events                          [/parent-portal/events]
├── Documents                       [/parent-portal/documents]
└── Account Settings                [/parent-portal/settings]
```

---

## 3. Stakeholders & Roles

| Actor | Role in Parent Portal | Permissions |
|---|---|---|
| Parent / Guardian | Primary user — views child data, pays fees, communicates | Portal access scoped to own linked children only |
| School Admin | Manages parent accounts, approves document requests, configures portal settings | Full admin access via admin panel |
| Class Teacher | Receives messages from parents; approves leave applications; conducts PTMs | Message receive; leave approve; PTM slot management |
| Subject Teacher | Receives messages about subject queries from parents | Message receive (own subjects for child's class) |
| Principal | Receives escalated communications | Message receive |
| School Nurse / Counsellor | Controls health report visibility flags for parents | Sets parent_visible on health/counsellor records |
| System | Sends push notifications, tracks read status, fires payment webhooks | System actor — no UI |

### 3.1 Authorization Model

Parent portal users (`user_type = PARENT`) are entirely separated from admin panel users. They cannot access any admin routes. All authorization uses Laravel Policies and custom middleware — **not** Spatie roles/permissions.

```php
Route::prefix('parent-portal')
    ->middleware(['auth', 'verified', 'parent.portal'])
    ->group(function () { ... });
```

`parent.portal` middleware enforces:
1. `auth()->user()->user_type === 'PARENT'`
2. `std_guardians` record exists for `auth()->user()->id`
3. At least one active child linked via `std_student_guardian_jnt.can_access_parent_portal = 1`

---

## 4. Functional Requirements

---

### FR-PPT-01: Multi-Child Dashboard
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** F.Z1.1

**Description:** Parent lands on a unified dashboard showing summary cards for each linked child and a detailed snapshot for the currently active child.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-01.1 | Child cards overview | All linked children shown as cards: photo, name, class+section, today's attendance status (Present/Absent/Not Marked) |
| REQ-01.2 | Child switcher | Clicking a child card sets that child as active; all data views switch context; active_student_id stored in ppt_parent_sessions |
| REQ-01.3 | Academic snapshot | For active child: attendance_pct (current month), last_test_score, pending_homework_count, fee_due_amount, next_fee_due_date |
| REQ-01.4 | Today's timetable | Current/next class period for active child based on published timetable; highlights current period |
| REQ-01.5 | Transport status | If Transport module active: bus route name, pickup time, current GPS status (En Route / At School / Departed) |
| REQ-01.6 | Dashboard caching | Non-realtime data (test scores, homework count) cached for 5 minutes via Laravel Cache; today's attendance not cached |

**Acceptance Criteria:**
- AC1: Dashboard loads within 3 seconds even with 4 linked children
- AC2: Active child persists across page reloads (stored in DB, not session only)
- AC3: All child-specific data exclusively belongs to that child (ParentChildPolicy enforced)
- AC4: Empty state shown gracefully when no children linked

---

### FR-PPT-02: OTP-Based Passwordless Login
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** Beyond RBS (V2 New)

**Description:** Parents can log in via OTP sent to registered mobile number without needing to remember a password. Standard password login also supported.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-02.1 | OTP login flow | Parent enters mobile number → system sends 6-digit OTP via SMS (MSG91/Twilio) → parent enters OTP → authenticated |
| REQ-02.2 | OTP validity | OTP expires after 10 minutes; max 3 attempts per OTP; lockout for 30 minutes after 5 consecutive failures |
| REQ-02.3 | OTP rate limiting | Max 3 OTP requests per mobile number per hour (prevent SMS bombing) |
| REQ-02.4 | Standard password login | Existing Laravel Auth password login supported as fallback |
| REQ-02.5 | First-time account setup | New parent accounts (auto-created on student enrollment per RBS B1.2.5) prompted to set password on first login |
| REQ-02.6 | Device token registration | On successful login, FCM/APNs device token registered or updated in ppt_parent_sessions |

**Acceptance Criteria:**
- AC1: OTP received within 30 seconds on registered mobile
- AC2: Expired/invalid OTP shows clear error message
- AC3: After 5 failures in 30 minutes, account temporarily locked with notification to parent
- AC4: First-time login forces password setup before portal access

---

### FR-PPT-03: Smart Notification Preferences
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** F.Z2.1 (ST.Z2.1.1, ST.Z2.1.2)

**Description:** Parent configures which alert types and channels they subscribe to; sets quiet hours; manages push notification device tokens.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-03.1 | Alert type configuration | Toggle per alert type: FeeReminder, AbsenceAlert, ExamResult, HomeworkDue, CircularAnnouncement, TransportUpdate, EventReminder, LeaveStatus, PTMReminder |
| REQ-03.2 | Channel selection | Per alert type: In-App, SMS, Email, WhatsApp (based on school's active notification channels) |
| REQ-03.3 | Quiet hours | quiet_hours_start (TIME), quiet_hours_end (TIME); non-urgent notifications buffered until quiet period ends |
| REQ-03.4 | Urgent bypass | AbsenceAlert and EmergencyAlert always bypass quiet hours |
| REQ-03.5 | FCM/APNs token management | On login: register/update token in ppt_parent_sessions; on logout: deactivate; handle token refresh (Firebase token rotation) |
| REQ-03.6 | Web Push (PWA) | Web push subscription stored alongside FCM/APNs tokens; supports desktop and mobile browser notifications |
| REQ-03.7 | Multi-device | Parent can have multiple active device tokens (phone + tablet + PC); notifications sent to all active tokens |

**Acceptance Criteria:**
- AC1: Disabling FeeReminder SMS prevents SMS for fee events (but in-app still fires)
- AC2: Notification sent during quiet hours is NOT dispatched immediately; dispatched after quiet period
- AC3: AbsenceAlert sent even during quiet hours
- AC4: Device token updated on every login without creating duplicates

---

### FR-PPT-04: Teacher Messaging
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** F.Z3.1 (ST.Z3.1.1, ST.Z3.1.2)

**Description:** Parent composes private messages to any teacher who teaches their active child; read receipts; full conversation history; file attachments.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-04.1 | Teacher selection | Dropdown built from child's enrolled subjects + assigned teachers from timetable; fallback: search all staff if timetable unavailable |
| REQ-04.2 | Compose message | recipient_user_id, subject (max 200 chars), message_body (min 10 chars), up to 3 attachments (PDF/JPG/PNG/DOC, max 5 MB each) via sys_media |
| REQ-04.3 | Thread model | Messages grouped by hash(guardian_id + teacher_user_id + student_id) as thread_id; conversation view |
| REQ-04.4 | Read receipts | ppt_messages.read_at updated when teacher first opens thread; parent sees "Read [timestamp]" indicator |
| REQ-04.5 | Teacher reply | Teacher replies via admin panel (or dedicated teacher view); reply creates ppt_messages with direction=Teacher_to_Parent |
| REQ-04.6 | Search | FULLTEXT search on (subject, message_body); filter by teacher name, date range |
| REQ-04.7 | Teacher notification | On new message from parent: in-app notification dispatched to teacher_user_id immediately |

**Acceptance Criteria:**
- AC1: Parent can only message teachers who teach their active child
- AC2: File attachment stored in sys_media; accessible via signed URL
- AC3: Read receipt timestamp shown within 1 second of teacher opening message
- AC4: Full conversation history grouped in threads
- AC5: Search returns results in < 2 seconds

---

### FR-PPT-05: Fee Management & Online Payment
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** F.Z4.1 (ST.Z4.1.1, ST.Z4.1.2)

**Description:** Parent views detailed fee invoices for active child and pays online via Razorpay.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-05.1 | Fee invoice view | All invoices from fin_fee_invoices for active child; grouped by academic_term; shows: invoice number, fee heads breakdown, amount, due_date, status (Paid/Unpaid/Overdue/Partial), total_outstanding |
| REQ-05.2 | Installment selection | Parent selects one or more unpaid installments to pay in a single transaction |
| REQ-05.3 | Razorpay checkout | Creates Razorpay order via API; opens Razorpay hosted checkout (PCI-compliant); supports UPI, Card, Net Banking, Wallet |
| REQ-05.4 | Payment verification | On callback: verify Razorpay signature; update fin_fee_invoices.status = Paid; create fin_transactions record; send SMS receipt |
| REQ-05.5 | IDOR prevention | ParentChildPolicy enforced: parent can ONLY pay invoices belonging to their linked child (student_id match mandatory) |
| REQ-05.6 | Idempotency | Razorpay payment_id uniqueness check prevents double-credit on webhook replay |
| REQ-05.7 | PDF receipt | DomPDF receipt with school letterhead: transaction ID, fee heads, amount, date, school stamp |
| REQ-05.8 | Payment history | All fin_transactions for active child filterable by date range, status (Success/Failed/Pending) |
| REQ-05.9 | Partial payment | If school enables partial payment: parent can pay a portion of an installment |

**Acceptance Criteria:**
- AC1: Fee breakdown matches fin_fee_invoices data exactly
- AC2: Razorpay order created and checkout opens within 3 seconds
- AC3: On payment success: invoice status updated immediately; SMS receipt sent within 1 minute
- AC4: Cross-child payment attempt blocked with 403 error
- AC5: Double-payment via webhook replay prevented
- AC6: PDF receipt downloadable immediately after payment success

---

### FR-PPT-06: Attendance View
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** Beyond RBS (Core)

**Description:** Parent views child's attendance history as a calendar and subject-wise breakdown.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-06.1 | Monthly calendar | Month view: each date colour-coded — Present (green), Absent (red), Half-Day (orange), Holiday (grey), Leave (blue), Not Marked (white) |
| REQ-06.2 | Monthly statistics | Present count, Absent count, Leave count, Working days, Attendance % for displayed month |
| REQ-06.3 | YTD summary | Year-to-date attendance percentage across all academic terms |
| REQ-06.4 | Subject-wise attendance | If school uses subject-wise attendance: grid showing periods attended / total periods per subject |
| REQ-06.5 | Absence drill-down | Click on absent date to see: class period, subject, teacher, reason (if entered by teacher) |
| REQ-06.6 | Alert on absence | Same-day absence: push notification to parent immediately when child is marked absent for the day |

**Acceptance Criteria:**
- AC1: Calendar renders within 2 seconds with full academic year data
- AC2: Absence notification reaches parent within 5 minutes of teacher marking absent
- AC3: Subject-wise view only shown if school has feature enabled
- AC4: Parent cannot modify attendance records (read-only view)

---

### FR-PPT-07: Homework Tracker
**Status:** 📐 Proposed | **Priority:** High | **RBS Ref:** Beyond RBS (Core)

**Description:** Parent views all homework assigned to the active child, grouped by status and subject.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-07.1 | Pending homework | Today's homework and upcoming deadlines listed with: subject, title, assigned_date, due_date |
| REQ-07.2 | Submission status | For each homework: Pending / Submitted / Overdue / Graded — sourced from LmsHomework tables |
| REQ-07.3 | Overdue alert | Count of overdue homework shown prominently; push notification on homework becoming overdue |
| REQ-07.4 | Subject filter | Filter homework list by subject |
| REQ-07.5 | Date range filter | View homework for a specific date range |

**Acceptance Criteria:**
- AC1: All homework for child's class+section visible
- AC2: Submission status accurately reflects LmsHomework data
- AC3: Parent cannot submit homework on behalf of child from this portal (read-only view)

---

### FR-PPT-08: Timetable View
**Status:** 📐 Proposed | **Priority:** High | **RBS Ref:** Beyond RBS (Core)

**Description:** Parent views the active child's published weekly class timetable.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-08.1 | Weekly grid | Published timetable for child's class+section; day columns × period rows; each cell shows subject + teacher |
| REQ-08.2 | Today highlight | Current day column highlighted; current period highlighted |
| REQ-08.3 | Academic term selector | Parent selects which term's timetable to view; defaults to current active term |
| REQ-08.4 | Smart vs Standard | Reads from SmartTimetable if available; falls back to StandardTimetable |

**Acceptance Criteria:**
- AC1: Only published timetables visible (unpublished/draft not shown)
- AC2: Parent cannot modify timetable data (read-only)

---

### FR-PPT-09: Academic Results & Report Cards
**Status:** 📐 Proposed | **Priority:** High | **RBS Ref:** Beyond RBS (Core)

**Description:** Parent views exam results and downloads official report cards for the active child.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-09.1 | Exam results list | All exam results for active child: exam name, date, subject, marks_obtained, max_marks, percentage, grade, pass/fail |
| REQ-09.2 | Term-wise grouping | Results grouped by academic term (Q1/Q2/Half-yearly/Annual) |
| REQ-09.3 | Subject-wise view | Marks across all exams per subject; trend visible |
| REQ-09.4 | Class average comparison | If school enables: show child's marks vs class average (without individual peer data) |
| REQ-09.5 | Report card download | Download PDF report card (DomPDF); ONLY available after school admin publishes for the term |
| REQ-09.6 | Publish gate | Report card not downloadable until term report cards published by admin |

**Acceptance Criteria:**
- AC1: Results match data in LmsExam tables exactly
- AC2: Unpublished report cards show "Not yet available" message
- AC3: PDF report card contains school letterhead, student details, all subject marks, grades, teacher remarks

---

### FR-PPT-10: Leave Application
**Status:** 📐 Proposed | **Priority:** High | **RBS Ref:** Beyond RBS (Core)

**Description:** Parent submits leave application for active child; class teacher approves/rejects; attendance module notified on approval.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-10.1 | Apply leave | Input: from_date (>= tomorrow), to_date (>= from_date), leave_type (Sick/Family/Personal/Festival/Medical/Other), reason (min 20 chars), optional supporting_doc (sys_media) |
| REQ-10.2 | Number of days | Auto-calculated (excluding holidays); shown before submission |
| REQ-10.3 | Submission notification | On submission: in-app + email notification to class teacher |
| REQ-10.4 | Approval flow | Class teacher reviews via admin panel; approves or rejects with notes |
| REQ-10.5 | Parent status tracking | Parent sees: Pending / Approved / Rejected; rejection reason shown |
| REQ-10.6 | Attendance integration | On approval: leave dates flagged in attendance module as Leave (not Absent) |
| REQ-10.7 | Withdrawal | Parent can withdraw a Pending application before it is processed |

**Acceptance Criteria:**
- AC1: Cannot apply leave for today or past dates (future-only)
- AC2: Class teacher notified within 2 minutes of submission
- AC3: Parent notified of approval/rejection decision within 2 minutes of teacher action
- AC4: Approved leave dates marked correctly in attendance module

---

### FR-PPT-11: Digital Consent Forms
**Status:** 📐 Proposed | **Priority:** High | **RBS Ref:** Beyond RBS (V2 New)

**Description:** School sends digital consent forms for events, trips, and activities; parent views and signs from the portal.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-11.1 | View pending forms | List of unsigned consent forms for active child with deadline |
| REQ-11.2 | Read form content | Full form text/HTML rendered in portal; scroll-to-read requirement optional |
| REQ-11.3 | Sign consent | Parent taps "I Agree" + enters name (e-signature); creates ppt_consent_form_responses record with signed_at timestamp |
| REQ-11.4 | Decline option | Parent can decline consent with reason; school notified |
| REQ-11.5 | Signed history | View all previously signed consent forms; download PDF copy of signed form |
| REQ-11.6 | Deadline enforcement | Forms past deadline shown as "Closed" and cannot be signed |
| REQ-11.7 | Reminder notification | Push notification 48 hours and 24 hours before form deadline if unsigned |

**Acceptance Criteria:**
- AC1: Parent signature creates immutable record with timestamp and IP address
- AC2: Parent cannot sign the same form twice
- AC3: School admin can see which parents have/haven't signed from admin panel
- AC4: Signed form PDF available for download within 1 minute of signing

---

### FR-PPT-12: Parent-Teacher Meeting (PTM) Scheduling
**Status:** 📐 Proposed | **Priority:** Medium | **RBS Ref:** Beyond RBS (V2 New)

**Description:** School publishes PTM time slots; parent books a slot for each teacher they wish to meet.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-12.1 | View PTM events | List of scheduled PTMs for child's class; date, time range, venue, teachers available |
| REQ-12.2 | Book time slot | Parent selects available slot per teacher; slot marked as booked |
| REQ-12.3 | Slot availability | Only available (unbooked) slots shown; real-time slot count updated |
| REQ-12.4 | Booking confirmation | Confirmation notification to parent + teacher with appointment details |
| REQ-12.5 | Cancel booking | Parent can cancel up to 1 hour before PTM; slot released back to pool |
| REQ-12.6 | Reminder | Push notification 24 hours and 1 hour before PTM appointment |
| REQ-12.7 | Virtual PTM link | If school provides a video call link, displayed on booking confirmation |

**Acceptance Criteria:**
- AC1: Double-booking prevented (one slot per teacher per PTM event per parent)
- AC2: Booking confirmation reaches parent and teacher within 2 minutes
- AC3: Cancelled slot immediately available for rebooking by other parents

---

### FR-PPT-13: Event Calendar & RSVP
**Status:** 📐 Proposed | **Priority:** Medium | **RBS Ref:** F.Z5.1 (ST.Z5.1.1, ST.Z5.1.2)

**Description:** Parent views school events, RSVPs for events requiring attendance, and volunteers for school events.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-13.1 | Event calendar | Monthly/list view of published events: PTM, Sports Day, Annual Function, Exams, Holidays, Circulars |
| REQ-13.2 | RSVP | For events requiring RSVP: Attending / Not Attending / Maybe; confirmation notification sent |
| REQ-13.3 | Volunteer sign-up | Parent signs up for volunteer role (Food stall, Decoration, Registration, etc.); max capacity per role enforced |
| REQ-13.4 | Calendar export | Export individual event to device calendar (.ics format) |
| REQ-13.5 | Volunteer reminders | Push notification 48h and 2h before volunteer duty |

**Acceptance Criteria:**
- AC1: RSVP or volunteer sign-up unique per (guardian, event) pair
- AC2: Volunteer role capacity enforced — cannot exceed max slots
- AC3: .ics download works on mobile and desktop

---

### FR-PPT-14: Health & HPC Reports
**Status:** 📐 Proposed | **Priority:** Medium | **RBS Ref:** Beyond RBS

**Description:** Parent views the active child's health, physical assessment, and counsellor reports generated by the HPC module.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-14.1 | Health record view | General health records (blood group, allergies, vaccination records, medical conditions) from std_health_records |
| REQ-14.2 | Physical assessment | Height, weight, BMI, fitness test results — if parent_visible = 1 |
| REQ-14.3 | Counsellor reports | Psychological/counsellor assessment reports — ONLY if school setting parent_counsellor_report_visibility = 1 |
| REQ-14.4 | PDF download | Download HPC report PDF (mirrors HPC module DomPDF generation) |
| REQ-14.5 | Default privacy | Counsellor reports default-hidden from parent; nurse must explicitly set parent_visible = 1 |

**Acceptance Criteria:**
- AC1: Medical records not visible unless parent_visible flag set
- AC2: Counsellor reports only visible if school setting explicitly enabled
- AC3: All health data read-only (parent cannot modify)

---

### FR-PPT-15: Transport Tracking
**Status:** 📐 Proposed | **Priority:** Medium | **RBS Ref:** Beyond RBS

**Description:** Parent views the bus route assigned to the active child and live status if Transport module provides GPS data.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-15.1 | Route information | Bus route name, vehicle number, driver name, driver mobile, departure time from school |
| REQ-15.2 | Pickup stop | Child's assigned pickup/drop stop, scheduled time |
| REQ-15.3 | Live status | If GPS data available: current bus location on map, estimated arrival at stop |
| REQ-15.4 | Module dependency check | If Transport module disabled for school: show "Transport module not activated" message |
| REQ-15.5 | Boarding notification | If transport module sends events: push notification when child boards/exits bus (RFID-based) |

**Acceptance Criteria:**
- AC1: Transport view shows "Not activated" gracefully if tpt module not enabled
- AC2: Driver mobile shown as click-to-call link on mobile
- AC3: Live GPS shown only if real GPS data available; otherwise static route info

---

### FR-PPT-16: Document Vault & Requests
**Status:** 📐 Proposed | **Priority:** Medium | **RBS Ref:** F.Z6.1 (ST.Z6.1.1, ST.Z6.1.2)

**Description:** Parent downloads official documents for the active child; requests duplicate certificates online.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-16.1 | Available documents | Report cards, marksheets, TC, Bonafide, Character Certificate, Migration Certificate, Medical Fitness Certificate |
| REQ-16.2 | Publish gate | Document only accessible after school admin marks it as available (prevents premature access) |
| REQ-16.3 | Medical documents | Vaccination records, medical certificates — gated by std_health_records.parent_visible = 1 |
| REQ-16.4 | Request duplicate | Online request: document_type, reason (min 20 chars), urgency (Normal/Urgent) |
| REQ-16.5 | Request tracking | Status: Pending / Processing / Ready / Completed / Rejected; admin notes visible |
| REQ-16.6 | Fee payment for duplicates | If admin sets fee_required > 0: payment via Razorpay before document download |
| REQ-16.7 | Fulfilled document | Admin uploads fulfilled document to sys_media; parent gets notification and download link |

**Acceptance Criteria:**
- AC1: Unpublished documents show "Not yet available"
- AC2: Fee payment required before download when fee_required > 0
- AC3: Request status updated in real-time; parent notified at each status change
- AC4: Completed document download link expires after 24 hours (signed URL)

---

### FR-PPT-17: Notification Inbox & Circulars
**Status:** 📐 Proposed | **Priority:** High | **RBS Ref:** F.Z2.1

**Description:** Parent views all notifications and circulars sent by the school in a unified inbox.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-17.1 | Inbox view | Paginated list of all notifications/circulars for parent; unread count badge |
| REQ-17.2 | Notification types | Circulars, fee reminders, absence alerts, exam results, event invites, leave status, system alerts |
| REQ-17.3 | Read/unread tracking | Mark individual or all as read; unread count badge in navigation |
| REQ-17.4 | Notification detail | Full notification body; linked action (e.g., "View invoice", "Pay now") |
| REQ-17.5 | Filter | Filter by type, date range, read/unread |
| REQ-17.6 | Deep linking | Notification push tap opens specific screen (fee invoice, attendance calendar, etc.) |

**Acceptance Criteria:**
- AC1: Unread count badge updates immediately on new notification
- AC2: Marking all as read clears badge instantly
- AC3: Push notification tap deep-links to correct in-app screen

---

### FR-PPT-18: Account Settings
**Status:** 📐 Proposed | **Priority:** Medium | **RBS Ref:** Beyond RBS

**Description:** Parent manages their account profile, linked children, password, and notification preferences.

**Sub-requirements:**

| ID | Requirement | Details |
|---|---|---|
| REQ-18.1 | Profile view | View own name, email, mobile, photo (from std_guardians) |
| REQ-18.2 | Change password | Standard Laravel password change with current password verification |
| REQ-18.3 | Linked children | View list of linked children; see link status and access permissions |
| REQ-18.4 | Notification preferences | Toggle alert types per channel; set quiet hours (FR-PPT-03) |
| REQ-18.5 | Manage devices | View active device sessions; logout from specific device |
| REQ-18.6 | Language preference | Select portal language if school has multi-language support enabled |

---

## 5. Data Model

### 5.1 Design Principle

The Parent Portal introduces **6 new `ppt_*` tables** for portal-specific state. All other data is **read** from existing module tables. The core FK chain:

```
sys_users (user_type=PARENT)
    └── std_guardians (via user_id)
          └── std_student_guardian_jnt (via guardian_id, can_access_parent_portal=1)
                └── std_students (the children)
```

All `ppt_*` tables follow the platform standard: `is_active` soft-delete, `created_by` FK to `sys_users`, `created_at`/`updated_at`/`deleted_at` timestamps.

---

### 5.2 New Tables (ppt_* prefix)

| Table | Description | Status |
|---|---|---|
| `ppt_parent_sessions` | Per-device portal state, active child, device tokens, notification prefs | 📐 Proposed |
| `ppt_messages` | Parent-teacher direct messages scoped to a child context | 📐 Proposed |
| `ppt_leave_applications` | Leave applications by parent on behalf of child | 📐 Proposed |
| `ppt_event_rsvps` | Parent RSVPs and volunteer sign-ups for school events | 📐 Proposed |
| `ppt_document_requests` | Online requests for duplicate certificates | 📐 Proposed |
| `ppt_consent_form_responses` | Parent responses to school digital consent forms | 📐 Proposed |

---

#### 📐 `ppt_parent_sessions`

Tracks per-device portal state: active child, device tokens, notification preferences, quiet hours.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| guardian_id | INT UNSIGNED | NOT NULL FK→std_guardians | |
| active_student_id | INT UNSIGNED | NULL FK→std_students | Currently selected child |
| device_token_fcm | VARCHAR(255) | NULL | Android FCM push token |
| device_token_apns | VARCHAR(255) | NULL | iOS APNs push token |
| device_token_webpush | TEXT | NULL | Web Push (PWA) subscription JSON |
| device_type | ENUM('Android','iOS','Web','Unknown') | DEFAULT 'Unknown' | |
| notification_preferences_json | JSON | NULL | `{"FeeReminder":{"in_app":1,"sms":1,"email":0}}` |
| quiet_hours_start | TIME | NULL | |
| quiet_hours_end | TIME | NULL | |
| last_active_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | 0 on logout |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | NOT NULL | |
| updated_at | TIMESTAMP | NOT NULL | |

UNIQUE KEY `uq_ppt_session_guardian_device_fcm` (`guardian_id`, `device_token_fcm`)

---

#### 📐 `ppt_messages`

Parent-teacher direct messages scoped to child context.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| guardian_id | INT UNSIGNED | NOT NULL FK→std_guardians | |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | Child context |
| direction | ENUM('Parent_to_Teacher','Teacher_to_Parent') | NOT NULL | |
| sender_user_id | INT UNSIGNED | NOT NULL FK→sys_users | |
| recipient_user_id | INT UNSIGNED | NOT NULL FK→sys_users | |
| thread_id | VARCHAR(64) | NOT NULL | MD5(guardian_id+teacher_user_id+student_id) |
| subject | VARCHAR(200) | NOT NULL | |
| message_body | TEXT | NOT NULL | |
| attachment_media_ids_json | JSON | NULL | Array of sys_media.id values |
| read_at | TIMESTAMP | NULL | When recipient opened the message |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | NOT NULL | |
| updated_at | TIMESTAMP | NOT NULL | |
| deleted_at | TIMESTAMP | NULL | |

INDEX `idx_ppt_messages_thread` (`thread_id`, `created_at`)
FULLTEXT INDEX `ft_ppt_messages_search` (`subject`, `message_body`)

---

#### 📐 `ppt_leave_applications`

Leave applications submitted by parent on behalf of child.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| application_number | VARCHAR(30) | NOT NULL UNIQUE | PPT-LV-YYYYXXXXXXXX |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | |
| guardian_id | INT UNSIGNED | NOT NULL FK→std_guardians | |
| from_date | DATE | NOT NULL | Must be >= tomorrow |
| to_date | DATE | NOT NULL | Must be >= from_date |
| number_of_days | TINYINT UNSIGNED | NOT NULL | Computed (excl. holidays) |
| leave_type | ENUM('Sick','Family','Personal','Festival','Medical','Other') | NOT NULL | |
| reason | TEXT | NOT NULL | Minimum 20 chars |
| supporting_doc_media_id | INT UNSIGNED | NULL FK→sys_media | Optional medical certificate |
| status | ENUM('Pending','Approved','Rejected','Withdrawn') | DEFAULT 'Pending' | |
| reviewed_by_user_id | INT UNSIGNED | NULL FK→sys_users | Class teacher |
| reviewed_at | TIMESTAMP | NULL | |
| reviewer_notes | TEXT | NULL | Rejection reason |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | NOT NULL | |
| updated_at | TIMESTAMP | NOT NULL | |
| deleted_at | TIMESTAMP | NULL | |

INDEX `idx_ppt_leave_student_status` (`student_id`, `status`)

---

#### 📐 `ppt_event_rsvps`

Parent RSVPs and volunteer registrations for school events.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| event_id | INT UNSIGNED | NOT NULL | FK to Event Engine event record |
| guardian_id | INT UNSIGNED | NOT NULL FK→std_guardians | |
| student_id | INT UNSIGNED | NULL FK→std_students | Child this RSVP is for |
| rsvp_status | ENUM('Attending','Not_Attending','Maybe') | NOT NULL DEFAULT 'Attending' | |
| is_volunteer | TINYINT(1) | DEFAULT 0 | |
| volunteer_role | VARCHAR(150) | NULL | e.g. "Food stall", "Registration desk" |
| rsvp_notes | TEXT | NULL | |
| confirmed_at | TIMESTAMP | NULL | |
| reminder_sent_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | NOT NULL | |
| updated_at | TIMESTAMP | NOT NULL | |

UNIQUE KEY `uq_ppt_rsvp_event_guardian` (`event_id`, `guardian_id`)

---

#### 📐 `ppt_document_requests`

Online requests for duplicate certificates and official documents.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| request_number | VARCHAR(30) | NOT NULL UNIQUE | PPT-DR-YYYYXXXXXXXX |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | |
| guardian_id | INT UNSIGNED | NOT NULL FK→std_guardians | |
| document_type | ENUM('TC','MarkSheet','Bonafide','Character','Migration','MedicalFitness','Other') | NOT NULL | |
| reason | TEXT | NOT NULL | |
| urgency | ENUM('Normal','Urgent') | DEFAULT 'Normal' | |
| status | ENUM('Pending','Processing','Ready','Completed','Rejected') | DEFAULT 'Pending' | |
| admin_notes | TEXT | NULL | |
| fee_required | DECIMAL(8,2) | DEFAULT 0.00 | 0 = free |
| fee_paid | TINYINT(1) | DEFAULT 0 | |
| payment_reference | VARCHAR(100) | NULL | Razorpay payment_id |
| fulfilled_media_id | INT UNSIGNED | NULL FK→sys_media | Document uploaded by admin |
| fulfilled_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | NOT NULL | |
| updated_at | TIMESTAMP | NOT NULL | |
| deleted_at | TIMESTAMP | NULL | |

---

#### 📐 `ppt_consent_form_responses`

Parent responses to digital consent forms issued by the school.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| consent_form_id | INT UNSIGNED | NOT NULL | FK to school's consent form record (Event/Activity module) |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | |
| guardian_id | INT UNSIGNED | NOT NULL FK→std_guardians | |
| response | ENUM('Signed','Declined') | NOT NULL | |
| decline_reason | TEXT | NULL | Required if response=Declined |
| signer_name | VARCHAR(150) | NOT NULL | Parent's typed name (e-signature) |
| signed_ip | VARCHAR(45) | NULL | IP address at time of signing |
| signed_at | TIMESTAMP | NOT NULL | Immutable timestamp |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | NOT NULL | |
| updated_at | TIMESTAMP | NOT NULL | |

UNIQUE KEY `uq_ppt_consent_response` (`consent_form_id`, `student_id`, `guardian_id`)

---

### 5.3 Read-Only Integration Tables (Existing)

| Module | Tables Read (Key) | Purpose |
|---|---|---|
| StudentProfile | `std_students`, `std_guardians`, `std_student_guardian_jnt`, `std_health_records` | Core FK chain; health visibility flags |
| StudentFee | `fin_fee_invoices`, `fin_fee_installments`, `fin_transactions` | Fee ledger; payment history |
| SmartTimetable | `tt_timetable_cells`, `tt_published_timetables` | Child's weekly schedule |
| LmsHomework | `hmw_assignments`, `hmw_submissions` | Homework status per child |
| LmsExam | `exm_results`, `exm_report_cards` | Marks; report card publish status |
| Attendance | `std_attendance`, `std_subject_attendance` | Daily and subject attendance records |
| HPC | `hpc_health_profiles`, `hpc_physical_assessments`, `hpc_counsellor_reports` | Health/physical/psychological data |
| Transport | `tpt_routes`, `tpt_vehicles`, `tpt_student_route_jnt` | Bus assignment; live GPS data |
| Notification | `ntf_notifications`, `ntf_circulars` | Inbox; dispatch target for alerts |
| sys_media | `sys_media` | Document files; message attachments |
| sys_users | `sys_users` | Auth; teacher lookup |

### 5.4 Entity Relationship Summary

```
sys_users (PARENT) ──FK── std_guardians ──FK── std_student_guardian_jnt ──FK── std_students
                               │
                    ppt_parent_sessions
                    ppt_messages ─────────────────────────────── FK ── std_students
                    ppt_leave_applications ───────────────────── FK ── std_students
                    ppt_event_rsvps
                    ppt_document_requests ────────────────────── FK ── std_students
                    ppt_consent_form_responses ───────────────── FK ── std_students

READ INTEGRATIONS (no FK in ppt_ tables):
std_students.id ──── Attendance tables
std_students.id ──── fin_fee_invoices
std_students.id ──── tt_* (Timetable)
std_students.id ──── hmw_* (Homework)
std_students.id ──── exm_* (Exam results)
std_students.id ──── hpc_* (Health)
std_students.id ──── tpt_* (Transport)
```

---

## 6. API Endpoints & Routes

### 6.1 Web Routes (Blade — tenant web.php)

| Method | URI | Controller@Method | Auth | Description |
|---|---|---|---|---|
| GET | /parent-portal/dashboard | ParentPortalController@dashboard | parent.portal | Main dashboard |
| GET | /parent-portal/children | ParentPortalController@children | parent.portal | List linked children |
| POST | /parent-portal/children/switch | ParentPortalController@switchChild | parent.portal | Switch active child |
| GET | /parent-portal/attendance | AttendanceViewController@index | parent.portal | Monthly calendar |
| GET | /parent-portal/attendance/subject-wise | AttendanceViewController@subjectWise | parent.portal | Subject attendance |
| GET | /parent-portal/timetable | TimetableViewController@index | parent.portal | Weekly timetable |
| GET | /parent-portal/homework | HomeworkViewController@index | parent.portal | Homework list |
| GET | /parent-portal/homework/{id} | HomeworkViewController@show | parent.portal | Homework detail |
| GET | /parent-portal/results | ResultViewController@index | parent.portal | Results list |
| GET | /parent-portal/results/{id} | ResultViewController@show | parent.portal | Result detail |
| GET | /parent-portal/results/report-card/{termId} | ResultViewController@downloadReportCard | parent.portal | PDF report card |
| GET | /parent-portal/fees | FeeViewController@index | parent.portal | Fee summary |
| GET | /parent-portal/fees/{invoiceId} | FeeViewController@show | parent.portal | Invoice detail |
| POST | /parent-portal/fees/pay | FeeViewController@pay | parent.portal | Initiate Razorpay |
| POST | /parent-portal/fees/razorpay-callback | FeeViewController@razorpayCallback | — | Razorpay webhook |
| GET | /parent-portal/fees/history | FeeViewController@history | parent.portal | Payment history |
| GET | /parent-portal/fees/receipt/{txnId} | FeeViewController@downloadReceipt | parent.portal | PDF receipt |
| GET | /parent-portal/messages | MessageController@index | parent.portal | Message inbox |
| GET | /parent-portal/messages/thread/{threadId} | MessageController@thread | parent.portal | Conversation thread |
| GET | /parent-portal/messages/compose | MessageController@compose | parent.portal | Compose form |
| POST | /parent-portal/messages | MessageController@store | parent.portal | Send message |
| POST | /parent-portal/messages/{id}/reply | MessageController@reply | parent.portal | Reply in thread |
| POST | /parent-portal/messages/{id}/mark-read | MessageController@markRead | parent.portal | Mark read |
| GET | /parent-portal/notifications | NotificationController@index | parent.portal | Notification inbox |
| GET | /parent-portal/notifications/{id} | NotificationController@show | parent.portal | Notification detail |
| POST | /parent-portal/notifications/{id}/read | NotificationController@markRead | parent.portal | Mark as read |
| POST | /parent-portal/notifications/read-all | NotificationController@markAllRead | parent.portal | Mark all read |
| GET | /parent-portal/notifications/preferences | NotificationController@preferences | parent.portal | Preferences form |
| POST | /parent-portal/notifications/preferences | NotificationController@savePreferences | parent.portal | Save preferences |
| GET | /parent-portal/leave | LeaveController@index | parent.portal | Leave list |
| GET | /parent-portal/leave/create | LeaveController@create | parent.portal | Apply leave form |
| POST | /parent-portal/leave | LeaveController@store | parent.portal | Submit leave |
| GET | /parent-portal/leave/{id} | LeaveController@show | parent.portal | Leave status |
| DELETE | /parent-portal/leave/{id} | LeaveController@destroy | parent.portal | Withdraw leave |
| GET | /parent-portal/consent-forms | ConsentFormController@index | parent.portal | Pending forms list |
| GET | /parent-portal/consent-forms/{id} | ConsentFormController@show | parent.portal | View form |
| POST | /parent-portal/consent-forms/{id}/sign | ConsentFormController@sign | parent.portal | Sign form |
| GET | /parent-portal/ptm | PtmController@index | parent.portal | PTM events list |
| GET | /parent-portal/ptm/{ptmId}/slots | PtmController@slots | parent.portal | Available slots |
| POST | /parent-portal/ptm/{ptmId}/book | PtmController@book | parent.portal | Book slot |
| DELETE | /parent-portal/ptm/booking/{id} | PtmController@cancelBooking | parent.portal | Cancel booking |
| GET | /parent-portal/events | EventController@index | parent.portal | Event calendar |
| GET | /parent-portal/events/{id} | EventController@show | parent.portal | Event detail |
| POST | /parent-portal/events/{id}/rsvp | EventController@rsvp | parent.portal | RSVP |
| POST | /parent-portal/events/{id}/volunteer | EventController@volunteerSignup | parent.portal | Volunteer sign-up |
| GET | /parent-portal/events/{id}/calendar | EventController@icsDownload | parent.portal | .ics download |
| GET | /parent-portal/health-reports | HealthReportController@index | parent.portal | Health overview |
| GET | /parent-portal/health-reports/{type} | HealthReportController@show | parent.portal | Report detail |
| GET | /parent-portal/health-reports/download | HealthReportController@download | parent.portal | PDF download |
| GET | /parent-portal/transport | TransportViewController@index | parent.portal | Bus info + status |
| GET | /parent-portal/documents | DocumentController@index | parent.portal | Document vault |
| GET | /parent-portal/documents/{id}/download | DocumentController@download | parent.portal | Download document |
| GET | /parent-portal/documents/request | DocumentController@requestForm | parent.portal | Request form |
| POST | /parent-portal/documents/request | DocumentController@storeRequest | parent.portal | Submit request |
| GET | /parent-portal/documents/request/{id} | DocumentController@trackRequest | parent.portal | Track status |
| GET | /parent-portal/settings | AccountSettingsController@index | parent.portal | Settings home |
| GET | /parent-portal/settings/profile | AccountSettingsController@profile | parent.portal | Profile |
| POST | /parent-portal/settings/password | AccountSettingsController@changePassword | parent.portal | Change password |
| GET | /parent-portal/settings/devices | AccountSettingsController@devices | parent.portal | Active devices |
| DELETE | /parent-portal/settings/devices/{id} | AccountSettingsController@logoutDevice | parent.portal | Logout device |

### 6.2 REST API Endpoints (Sanctum — api.php)

| Method | URI | Controller@Method | Auth | Description |
|---|---|---|---|---|
| GET | /api/v1/parent/dashboard | ParentPortalController@apiDashboard | sanctum+parent | Dashboard JSON |
| GET | /api/v1/parent/children | ParentPortalController@apiChildren | sanctum+parent | Children list |
| POST | /api/v1/parent/switch-child | ParentPortalController@apiSwitchChild | sanctum+parent | Switch active child |
| GET | /api/v1/parent/attendance | AttendanceViewController@api | sanctum+parent | Attendance data |
| GET | /api/v1/parent/homework | HomeworkViewController@api | sanctum+parent | Homework list |
| GET | /api/v1/parent/fees | FeeViewController@api | sanctum+parent | Fee invoices |
| POST | /api/v1/parent/fees/pay | FeeViewController@apiPay | sanctum+parent | Initiate payment |
| POST | /api/v1/parent/fees/razorpay-callback | FeeViewController@apiCallback | — | Webhook handler |
| GET | /api/v1/parent/messages | MessageController@api | sanctum+parent | Message threads |
| POST | /api/v1/parent/messages | MessageController@apiStore | sanctum+parent | Send message |
| GET | /api/v1/parent/notifications | NotificationController@api | sanctum+parent | Notifications |
| POST | /api/v1/parent/device-token | AccountSettingsController@registerToken | sanctum+parent | Register FCM/APNs |
| DELETE | /api/v1/parent/device-token | AccountSettingsController@removeToken | sanctum+parent | Deregister token |
| POST | /api/v1/parent/otp/send | AuthController@sendOtp | — | Request OTP |
| POST | /api/v1/parent/otp/verify | AuthController@verifyOtp | — | Verify OTP + login |
| GET | /api/v1/parent/timetable | TimetableViewController@api | sanctum+parent | Timetable data |
| GET | /api/v1/parent/results | ResultViewController@api | sanctum+parent | Exam results |
| GET | /api/v1/parent/events | EventController@api | sanctum+parent | Events list |

---

## 7. UI Screens

| Screen ID | Screen Name | Route Name | Description |
|---|---|---|---|
| SCR-PPT-01 | Login (OTP / Password) | ppt.login | OTP entry or password login; mobile number field |
| SCR-PPT-02 | OTP Verification | ppt.otp.verify | 6-digit OTP entry with 10-minute countdown |
| SCR-PPT-03 | Dashboard | ppt.dashboard | Child cards + active child academic snapshot |
| SCR-PPT-04 | Child Switcher | ppt.children | List all linked children; switch active |
| SCR-PPT-05 | Attendance Calendar | ppt.attendance.index | Monthly calendar with colour-coded dates |
| SCR-PPT-06 | Subject-wise Attendance | ppt.attendance.subject-wise | Grid: subject × period stats |
| SCR-PPT-07 | Timetable | ppt.timetable.index | Weekly day × period grid |
| SCR-PPT-08 | Homework List | ppt.homework.index | Pending/overdue/submitted homework grouped by subject |
| SCR-PPT-09 | Homework Detail | ppt.homework.show | Assignment description, due date, submission status |
| SCR-PPT-10 | Results List | ppt.results.index | Exam list grouped by academic term |
| SCR-PPT-11 | Result Detail | ppt.results.show | Subject marks, grade, class average comparison |
| SCR-PPT-12 | Report Card Download | ppt.results.report-card | Term selector + PDF download button |
| SCR-PPT-13 | Fee Summary | ppt.fees.index | Outstanding invoices with pay button per installment |
| SCR-PPT-14 | Razorpay Checkout | ppt.fees.pay | Razorpay hosted checkout redirect |
| SCR-PPT-15 | Payment Success | ppt.fees.success | Payment confirmation + receipt download |
| SCR-PPT-16 | Payment History | ppt.fees.history | All transactions with status + PDF receipt links |
| SCR-PPT-17 | Message Inbox | ppt.messages.index | List of message threads per teacher |
| SCR-PPT-18 | Message Thread | ppt.messages.thread | Conversation view (parent ↔ teacher) |
| SCR-PPT-19 | Compose Message | ppt.messages.compose | Teacher selector + subject + body + attachments |
| SCR-PPT-20 | Notification Inbox | ppt.notifications.index | Paginated notifications; unread badge |
| SCR-PPT-21 | Notification Detail | ppt.notifications.show | Full notification body + action links |
| SCR-PPT-22 | Notification Preferences | ppt.notifications.preferences | Toggle matrix: alert type × channel; quiet hours |
| SCR-PPT-23 | Leave List | ppt.leave.index | All applications with status timeline |
| SCR-PPT-24 | Apply Leave | ppt.leave.create | Leave form: dates, type, reason, document upload |
| SCR-PPT-25 | Leave Status | ppt.leave.show | Application details + reviewer notes |
| SCR-PPT-26 | Consent Forms List | ppt.consent-forms.index | Unsigned forms with deadline |
| SCR-PPT-27 | Consent Form Detail | ppt.consent-forms.show | Full form text + Sign / Decline actions |
| SCR-PPT-28 | PTM Events | ppt.ptm.index | Upcoming PTMs for child's class |
| SCR-PPT-29 | PTM Slot Booking | ppt.ptm.slots | Available time slots per teacher |
| SCR-PPT-30 | Event Calendar | ppt.events.index | Month view of school events |
| SCR-PPT-31 | Event Detail | ppt.events.show | Event info + RSVP + volunteer sign-up |
| SCR-PPT-32 | Health Overview | ppt.health-reports.index | General health summary |
| SCR-PPT-33 | Health Report Detail | ppt.health-reports.show | Physical/counsellor report (gated) |
| SCR-PPT-34 | Transport Info | ppt.transport.index | Bus route, driver, pickup stop, live map |
| SCR-PPT-35 | Document Vault | ppt.documents.index | Available documents with download links |
| SCR-PPT-36 | Document Request Form | ppt.documents.request | Request type, reason, urgency |
| SCR-PPT-37 | Document Request Status | ppt.documents.track | Status timeline; payment + download link |
| SCR-PPT-38 | Account Settings | ppt.settings.index | Profile, password, devices, preferences |

---

## 8. Business Rules

| Rule ID | Description | Enforcement |
|---|---|---|
| BR-PPT-001 | Parent can ONLY access data for children linked via `std_student_guardian_jnt` where `guardian.user_id = auth()->id()` AND `can_access_parent_portal = 1` | ParentChildPolicy on EVERY data request |
| BR-PPT-002 | Fee payment: parent can only pay invoices for their own linked child (`student_id` match mandatory) | FeePaymentRequest + ParentChildPolicy |
| BR-PPT-003 | Messaging: parent can only message teachers who teach their active child's subjects | ParentMessagePolicy; teacher list built from timetable assignment |
| BR-PPT-004 | Leave application: `from_date` must be >= tomorrow; cannot apply for today or past dates | ApplyLeaveRequest validation |
| BR-PPT-005 | Report card download: only accessible after school admin has published the term's report cards | ResultViewController publish gate check |
| BR-PPT-006 | Medical records visible to parent ONLY if `std_health_records.parent_visible = 1` | HealthReportController query filter |
| BR-PPT-007 | Counsellor psychological reports visible ONLY if `sys_school_settings.parent_counsellor_report_visibility = 1` | HealthReportController settings check |
| BR-PPT-008 | Quiet hours: non-urgent notifications buffered; AbsenceAlert and EmergencyAlert ALWAYS bypass quiet hours | NotificationPreferenceService |
| BR-PPT-009 | Device tokens: on re-login from a new device, existing token for that guardian+device_type may be updated; on explicit logout, token marked is_active = 0 | AccountSettingsController |
| BR-PPT-010 | Multi-child active context: stored in `ppt_parent_sessions.active_student_id` (DB, not session only) for multi-device sync | ParentPortalController + Middleware |
| BR-PPT-011 | Document requests: fulfilled document download requires fee payment when `fee_required > 0` | DocumentController fee gate |
| BR-PPT-012 | IDOR prevention: every single data endpoint includes guardian→student ownership verification — this is a P0 security requirement | ParentChildPolicy + Middleware |
| BR-PPT-013 | OTP: max 3 attempts per OTP code; max 3 OTP requests per mobile per hour; 30-minute lockout after 5 consecutive failures | AuthController + rate limiter |
| BR-PPT-014 | Consent form: parent cannot sign the same form twice (unique key on form+student+guardian); deadline enforced | ConsentFormController + DB unique constraint |
| BR-PPT-015 | PTM booking: one slot per teacher per PTM event per guardian; slot released immediately on cancellation | PtmController + DB transaction |
| BR-PPT-016 | Volunteer sign-up: max capacity per volunteer role enforced; sign-up rejected if role is full | EventController capacity check |
| BR-PPT-017 | Leave approval event: on class teacher approval, an event is dispatched to attendance module to mark dates as Leave | LeaveController event dispatch |
| BR-PPT-018 | Fee payment idempotency: Razorpay `payment_id` uniqueness check prevents double-credit on webhook replay | FeeViewController + DB unique constraint |

---

## 9. Workflow Diagrams (FSM Descriptions)

### 9.1 Parent Login Flow (OTP)

```
UNAUTHENTICATED
    │
    ├─ Enter mobile number
    │       └─ Rate limit check (max 3 OTPs/hour)
    │               ├─ Limit reached → Error + retry timer
    │               └─ Send OTP via SMS → State: OTP_SENT
    │
OTP_SENT
    │
    ├─ Enter OTP (max 3 attempts, 10-min expiry)
    │       ├─ Invalid OTP → Attempt counter++
    │       │       └─ 3 failures → State: OTP_LOCKED (30 min)
    │       ├─ Expired OTP → Prompt resend
    │       └─ Valid OTP → State: AUTHENTICATED
    │
AUTHENTICATED
    │
    ├─ First time login → Force password setup → PORTAL_HOME
    └─ Returning user → PORTAL_HOME (dashboard)
```

### 9.2 Leave Application FSM

```
DRAFT (not submitted)
    │ Parent submits
    ▼
PENDING
    │ Class teacher reviews
    ├─── Approve ──────────► APPROVED
    │                              │ Event dispatched → Attendance module marks dates as Leave
    ├─── Reject ──────────► REJECTED
    │                              │ Reviewer notes stored; parent notified
    └─── Parent withdraws ► WITHDRAWN (only from PENDING state)
```

### 9.3 Fee Payment FSM

```
INVOICE (status=Unpaid/Overdue)
    │ Parent selects + clicks Pay
    ▼
PAYMENT_INITIATED (Razorpay order created)
    │ Razorpay hosted checkout
    ├─── Success callback (signature verified) ──► PAID
    │                                                    │ fin_transactions created
    │                                                    │ SMS receipt sent
    │                                                    │ PDF receipt generated
    └─── Failure / Cancel ──────────────────────► UNPAID (unchanged; parent retries)
```

### 9.4 Document Request FSM

```
SUBMITTED (status=Pending)
    │ Admin reviews
    ▼
PROCESSING
    │ Admin completes processing
    ├─── fee_required > 0:
    │         ▼
    │     READY (parent must pay before download)
    │         │ Parent pays via Razorpay
    │         ▼
    │     COMPLETED (document downloadable)
    │
    └─── fee_required = 0:
              ▼
          COMPLETED (document immediately downloadable)
              │ Parent notified with download link

Admin can REJECT at any stage → REJECTED (admin_notes required)
```

### 9.5 Consent Form FSM

```
PUBLISHED (unsigned, within deadline)
    │ Parent views form
    │
    ├─── Sign → SIGNED (immutable; timestamp + IP recorded)
    │                │ PDF confirmation generated; school admin notified
    └─── Decline → DECLINED (reason required; school admin notified)

DEADLINE_PASSED → form becomes read-only; unsigned parents cannot sign
```

### 9.6 PTM Slot Booking FSM

```
SLOT_AVAILABLE
    │ Parent selects slot
    ▼
BOOKING_PENDING (DB transaction locked)
    │ Conflict check (slot still available?)
    ├─── Available → BOOKED (confirmation sent to parent + teacher)
    └─── Taken (race condition) → Error: "Slot just taken; please choose another"

BOOKED
    │ Parent cancels (>= 1 hour before PTM)
    ▼
SLOT_RELEASED (slot returns to SLOT_AVAILABLE pool)

Within 1 hour of PTM → cancellation not allowed (LOCKED)
```

---

## 10. Non-Functional Requirements

| Category | Requirement | Details |
|---|---|---|
| Security (P0) | IDOR prevention | ALL data endpoints enforce `ParentChildPolicy`; no child data accessible without verified guardian→child link |
| Security | HTTPS | All portal traffic HTTPS; no mixed content; HSTS header |
| Security | CSRF | All POST/PUT/DELETE routes protected by Laravel CSRF token |
| Security | OTP rate limiting | Max 3 OTP requests/hour/mobile; max 3 OTP attempts/code; 30-min lockout |
| Security | Signed URLs | Document download links expire after 24 hours (signed URL via `Storage::temporaryUrl()`) |
| Security | Payment | Razorpay signature verified server-side before updating invoice status; idempotency via payment_id uniqueness |
| Performance | Dashboard load | < 3 seconds for dashboard with 4 children; non-realtime data cached 5 minutes (Laravel Cache) |
| Performance | Attendance calendar | < 2 seconds to render full academic year calendar |
| Performance | API responses | All API endpoints respond in < 500ms for standard data queries |
| Performance | Query optimization | Eager loading on all relationship queries; N+1 queries prohibited; ParentDashboardService batch-fetches all child data in 5 queries max |
| Scalability | Multi-tenant | All queries scoped to tenant DB via stancl/tenancy; no cross-tenant data leakage |
| Mobile-first | Responsive design | All Blade views responsive (Bootstrap 5 or Tailwind); primary usage on mobile devices |
| Mobile-first | PWA | Portal installable as PWA; offline-capable home screen for basic data viewing |
| Mobile-first | Touch targets | All interactive elements >= 44px touch target |
| Availability | Module dependency degradation | If a dependent module is inactive (e.g., Transport not enabled), portal shows graceful "feature not available" state — never a 500 error |
| PDF | Generation | DomPDF for receipts, report cards, HPC reports; school letterhead applied; all PDFs A4 format |
| Notifications | Push | FCM (Android), APNs (iOS), Web Push (PWA); Laravel Notification channels; fallback: SMS via MSG91/Twilio |
| Notifications | Delivery SLA | Absence alert push: < 5 minutes from teacher marking; fee reminder: < 2 minutes of trigger |
| Privacy | Counsellor reports | Default-hidden from parents (`parent_counsellor_report_visibility = 0`); school explicitly enables |
| Privacy | Medical records | Per-record `parent_visible` flag; default follows school policy |
| Audit | Logging | All parent actions logged to `sys_activity_logs` (view, payment, message, leave) |
| Concurrency | Fee payment | DB transaction + Razorpay idempotency prevents double-payment in concurrent webhook scenarios |
| Session | Active child | Stored in `ppt_parent_sessions.active_student_id` (DB) for multi-device sync; session variable used for speed |

---

## 11. Module Dependencies

### 11.1 Hard Dependencies (must be present for basic portal function)

| Module | Code | Dependency Reason | Status |
|---|---|---|---|
| Student Profile | STD | Core FK chain: std_students, std_guardians, std_student_guardian_jnt | Completed |
| System Config | SYS | sys_users (auth), sys_media (documents, attachments), sys_school_settings | Completed |
| Student Fee | FIN | fin_fee_invoices, fin_transactions for fee view and payment | ~80% |
| Payment Gateway | PAY | Razorpay integration for online fee payment | ~90% |

### 11.2 Soft Dependencies (portal degrades gracefully if absent)

| Module | Code | Feature Affected | Degradation Behavior |
|---|---|---|---|
| Smart Timetable | TTF/TTS | Timetable view; teacher list for messaging | Show "Timetable not configured" |
| Standard Timetable | TTS | Fallback timetable source | Falls back to Smart, then "Not available" |
| LMS Homework | HMW | Homework tracker | Show "Homework module not enabled" |
| LMS Exam | EXM | Results, report cards | Show "Exam module not enabled" |
| Attendance | ACD | Attendance calendar | Show "Attendance data unavailable" |
| HPC | HPC | Health reports | Section hidden if HPC not active |
| Transport | TPT | Transport tracking | Show "Transport module not activated" |
| Notification | NTF | Push notifications, inbox | Notification features disabled |
| Event Engine | EVN | Event calendar, RSVP | Show empty calendar |
| Communication | COM | Circulars in inbox | Falls back to ntf_circulars only |

### 11.3 Database Dependencies

| Existing Table | Usage | Access Type |
|---|---|---|
| `std_students` | Core child record | Read |
| `std_guardians` | Parent/guardian record linked to sys_users | Read |
| `std_student_guardian_jnt` | Parent-child link with `can_access_parent_portal` flag | Read |
| `fin_fee_invoices` | Outstanding fees | Read |
| `fin_transactions` | Payment history | Read + Write (on payment) |
| `sys_users` | Auth, teacher lookup for messaging | Read |
| `sys_media` | Document files, message attachments | Read + Write |
| `sys_school_settings` | Portal visibility flags, feature toggles | Read |
| `ntf_notifications` | Notification inbox | Read + Dispatch |

---

## 12. Test Scenarios

| # | Test Class | Type | Scenario | Priority |
|---|---|---|---|---|
| 1 | ParentAuthTest | Feature | PARENT user logs in via OTP; portal dashboard loads; STUDENT/STAFF user redirected | Critical |
| 2 | OtpRateLimitTest | Feature | More than 3 OTP requests/hour blocked; more than 5 failures trigger lockout | Critical |
| 3 | ParentChildAccessTest | Feature | Parent accesses own child's data; attempt to access another student's data returns 403 (IDOR test) | Critical |
| 4 | FeePaymentAuthTest | Feature | Parent pays own child's invoice; cross-child invoice payment blocked with 403 | Critical |
| 5 | FeePaymentIdempotencyTest | Feature | Replay of Razorpay webhook with same payment_id does not double-credit invoice | Critical |
| 6 | SwitchChildTest | Feature | Parent switches active child; all subsequent data views reflect new child context | High |
| 7 | ComposeMessageTest | Feature | Parent composes message to child's teacher; ppt_messages record created; teacher notified | High |
| 8 | MessageIdrRestrictionTest | Feature | Parent cannot message a teacher who does not teach their child | High |
| 9 | ReadReceiptTest | Feature | Teacher opens message; read_at updated; parent sees "Read [timestamp]" in thread | High |
| 10 | MessageSearchTest | Feature | Search by keyword returns matching messages; non-matching messages excluded | Medium |
| 11 | LeaveApplicationTest | Feature | Apply leave with future date; correct number_of_days calculated; teacher notified | High |
| 12 | LeavePastDateTest | Feature | Applying leave for today or past date returns validation error | High |
| 13 | LeaveApprovalTest | Feature | Teacher approves leave; parent sees status Approved; attendance module event dispatched | High |
| 14 | LeaveRejectionTest | Feature | Teacher rejects with notes; parent sees status Rejected + reviewer_notes | High |
| 15 | ConsentFormSignTest | Feature | Parent signs consent form; response created with timestamp + IP; cannot sign twice | High |
| 16 | ConsentFormDeadlineTest | Feature | Consent form past deadline shows as Closed; sign action blocked | Medium |
| 17 | PtmBookingTest | Feature | Parent books available PTM slot; slot marked as booked; teacher notified | Medium |
| 18 | PtmDoubleBookingTest | Feature | Two parents simultaneously book same slot; only one succeeds; other gets error | Medium |
| 19 | PtmCancellationTest | Feature | Parent cancels booking > 1 hour before PTM; slot released | Medium |
| 20 | DocumentRequestTest | Feature | Parent requests TC; ppt_document_requests created; admin notified | Medium |
| 21 | DocumentRequestFeeTest | Feature | Document with fee > 0 not downloadable until paid; download allowed after payment | Medium |
| 22 | ReportCardGateTest | Feature | Report card PDF not downloadable before school publishes; download available after publish | High |
| 23 | NotificationPreferencesTest | Feature | Parent disables FeeReminder SMS; SMS not dispatched on next fee event | Medium |
| 24 | QuietHoursTest | Feature | Non-urgent notification during quiet hours buffered; urgent absence alert NOT buffered | Medium |
| 25 | MultiDeviceTokenTest | Feature | Parent logs in on second device; FCM token registered for new device; logout deactivates token | Low |
| 26 | MedicalRecordVisibilityTest | Feature | Medical record with parent_visible=0 not shown to parent; parent_visible=1 shows | High |
| 27 | CounsellorReportGateTest | Feature | Counsellor report hidden when school setting = 0; visible when setting = 1 | High |
| 28 | EventRsvpTest | Feature | RSVP for event; confirmation sent; cannot RSVP same event twice | Medium |
| 29 | VolunteerCapacityTest | Feature | Volunteer sign-up succeeds when slots available; blocked when role at capacity | Medium |
| 30 | TransportModuleGraceTest | Feature | Transport module disabled → transport screen shows graceful "not activated" message, not 500 | Medium |
| 31 | ParentDashboardServiceTest | Unit | ParentDashboardService aggregates correct metrics for given student_id | High |
| 32 | NotificationPreferenceServiceTest | Unit | Service correctly applies quiet hours and urgent bypass logic | Medium |
| 33 | PtmSchedulingServiceTest | Unit | Slot conflict detection works correctly under concurrent booking | High |

---

## 13. Glossary

| Term | Definition |
|---|---|
| Guardian | A parent or legal guardian of an enrolled student; linked to system via `std_guardians.user_id` |
| Active Child | The child currently selected by the parent in the portal; all data views are scoped to this child |
| Child Switcher | UI widget allowing parent to change the active child without logging out |
| IDOR | Insecure Direct Object Reference — security vulnerability where attacker accesses another user's data by manipulating IDs |
| ParentChildPolicy | Laravel Policy class that verifies parent→child authorization on every data request |
| Thread ID | MD5 hash of (guardian_id + teacher_user_id + student_id) used to group messages into conversation threads |
| FCM | Firebase Cloud Messaging — Google's push notification service for Android |
| APNs | Apple Push Notification service — Apple's push notification service for iOS |
| PWA | Progressive Web App — web app installable on mobile/desktop that supports push notifications and offline use |
| Razorpay | Indian payment gateway used for online fee collection; supports UPI, Card, Net Banking, Wallet |
| DomPDF | PHP PDF generation library used for report cards and fee receipts |
| Quiet Hours | Time window configured by parent during which non-urgent notifications are buffered, not sent |
| PTM | Parent-Teacher Meeting — scheduled meeting between parent and teacher to discuss child's progress |
| Consent Form | Digital form issued by school for events/trips/activities requiring parent authorization |
| OTP | One-Time Password — 6-digit time-limited code sent via SMS for passwordless login |
| can_access_parent_portal | Column on `std_student_guardian_jnt` that controls whether a guardian has access to the portal for a specific child |
| parent_visible | Column on health/counsellor records controlling whether the record is visible to parent |
| RBS | Requirement Breakdown Structure — the master specification document for the Prime-AI platform |
| RBS_ONLY | Processing mode indicating no existing code; all requirements are greenfield proposals |
| STP | Student Portal module — the student-facing counterpart to this parent portal |
| fin_fee_invoices | Table in tenant_db storing fee invoices per student per term |
| sys_activity_logs | Platform audit log table where all significant actions are recorded |

---

## 14. Suggestions & Improvements

### 14.1 Architecture Suggestions

| ID | Suggestion | Rationale |
|---|---|---|
| SUG-PPT-01 | Use Laravel Sanctum for mobile API auth (token per device) rather than session-based auth for API routes | Enables future React Native / Flutter app without auth rework |
| SUG-PPT-02 | Implement `ParentDashboardService` as a batch query service (max 5 queries for all dashboard widgets) | Prevents N+1 cascade across 5+ modules; keeps dashboard snappy |
| SUG-PPT-03 | Cache dashboard aggregates with tagged cache (`Cache::tags(['parent', guardian_id])->remember(...)`) | Allows targeted cache invalidation per parent when data changes |
| SUG-PPT-04 | Use database queue (not sync) for all notification dispatches from portal actions | Prevents UI latency; ensures notification delivery even on slow SMS gateway |
| SUG-PPT-05 | Store `active_student_id` in `ppt_parent_sessions` (DB) not PHP session | Enables multi-device context sync; parent on phone and tablet see same active child |
| SUG-PPT-06 | Use Razorpay hosted checkout page (not Razorpay.js embed) | Simpler integration; PCI-compliant; school does not need PCI certification |
| SUG-PPT-07 | Generate signed temporary URLs for document downloads (24-hour expiry) | Prevents link sharing and unauthorized document access after session ends |
| SUG-PPT-08 | Implement a PWA service worker for offline dashboard caching | Parents in low-connectivity areas can still view last-fetched attendance/timetable |

### 14.2 UX Suggestions

| ID | Suggestion | Rationale |
|---|---|---|
| SUG-PPT-09 | Child switcher in fixed top navigation bar (not a separate screen) | Reduces clicks; parents with 2-3 children switch frequently throughout session |
| SUG-PPT-10 | Dashboard "Action required" section: unpaid fees, unsigned consent forms, pending leave | Parents miss important items in Indian school context; surface them prominently |
| SUG-PPT-11 | Colour-coded fee status chips (green=Paid, orange=Due, red=Overdue) across all fee views | Instant visual parsing; reduces reading cognitive load |
| SUG-PPT-12 | Homework calendar view (in addition to list): each date shows count of due items | Calendar gives better mental model of child's workload across the week |
| SUG-PPT-13 | Teacher messaging: show teacher's photo and subject in the compose teacher selector dropdown | Helps parent identify the right teacher; common confusion with same-name teachers |
| SUG-PPT-14 | PTM booking: show teacher photo + subject + room number on slot selection screen | Reduces "which room is my appointment?" queries to school office |

### 14.3 Business Logic Suggestions

| ID | Suggestion | Rationale |
|---|---|---|
| SUG-PPT-15 | Auto-create parent portal account on student enrollment (already in RBS B1.2.5); send welcome SMS with OTP login link | Eliminates separate parent registration step; immediate portal adoption |
| SUG-PPT-16 | Fee payment: send payment reminder push notification 3 days, 1 day, and same-day before due date | Reduces late payments without manual school follow-up |
| SUG-PPT-17 | Attendance: if child absent for 3+ consecutive days, auto-trigger leave application prompt to parent | Reduces cases where absence is unaccounted; helps school track genuine leaves |
| SUG-PPT-18 | Message to teacher: limit to 1 message per subject per 24 hours (configurable by school) | Prevents teacher inbox flooding; common problem in similar portals |
| SUG-PPT-19 | Consent form: add school's physical address and principal's digital signature in PDF confirmation | Makes signed form legally defensible; required by some school boards |
| SUG-PPT-20 | Document request: add estimated delivery date shown to parent on submission | Reduces "when will my TC be ready?" calls to school office |

### 14.4 Security Suggestions

| ID | Suggestion | Rationale |
|---|---|---|
| SUG-PPT-21 | Add middleware to log all data access attempts (including 403s) to `sys_activity_logs` | Enables audit of IDOR attempts; helps identify if parent is probing for other children's data |
| SUG-PPT-22 | Implement per-guardian API rate limiting (60 requests/minute) on all API endpoints | Prevents scraping of child data via API; standard for self-service portals |
| SUG-PPT-23 | Add parent login notification: "Your account was accessed from [Device] at [Time]" | Security awareness; parent can detect if account is compromised |
| SUG-PPT-24 | Require re-authentication (OTP re-entry) before showing full fee payment or document download | High-value actions need additional identity confirmation; mirrors banking UX |

---

## 15. Appendices

### 15.1 Form Request Validation Rules

| FormRequest | Key Validation Rules |
|---|---|
| SwitchChildRequest | `student_id` required\|integer\|exists:std_students,id — ownership validated by ParentChildPolicy, not FormRequest |
| ComposeMessageRequest | `recipient_user_id` required\|exists:sys_users,id; `subject` required\|max:200; `message_body` required\|min:10; `attachments` nullable\|array\|max:3; each: file\|max:5120\|mimes:pdf,jpg,png,doc,docx |
| ApplyLeaveRequest | `student_id` required\|exists:std_students,id; `from_date` required\|date\|after:today; `to_date` required\|date\|after_or_equal:from_date; `leave_type` required\|in:Sick,Family,Personal,Festival,Medical,Other; `reason` required\|min:20\|max:1000 |
| FeePaymentRequest | `invoice_ids` required\|array\|min:1; each: integer\|exists:fin_fee_invoices,id; `total_amount` required\|numeric\|min:1 |
| EventRsvpRequest | `event_id` required\|integer; `rsvp_status` required\|in:Attending,Not_Attending,Maybe; `is_volunteer` boolean; `volunteer_role` required_if:is_volunteer,true\|max:150 |
| DocumentRequestForm | `document_type` required\|in:TC,MarkSheet,Bonafide,Character,Migration,MedicalFitness,Other; `reason` required\|min:20; `urgency` required\|in:Normal,Urgent |
| NotificationPreferencesRequest | `preferences` required\|array; each key in allowed alert types; each value: array with keys in_app\|sms\|email\|whatsapp (boolean); `quiet_hours_start` nullable\|date_format:H:i; `quiet_hours_end` nullable\|date_format:H:i |
| ConsentFormSignRequest | `signer_name` required\|min:3\|max:150; `response` required\|in:Signed,Declined; `decline_reason` required_if:response,Declined\|min:10 |
| PtmBookingRequest | `ptm_event_id` required\|integer; `slot_id` required\|integer; `teacher_user_id` required\|integer\|exists:sys_users,id |

### 15.2 Authorization Policies

| Policy | Method | Logic |
|---|---|---|
| ParentChildPolicy | `access(Guardian $guardian, int $studentId): bool` | Query `std_student_guardian_jnt` WHERE `guardian_id = $guardian->id` AND `student_id = $studentId` AND `can_access_parent_portal = 1` AND `is_active = 1` |
| ParentMessagePolicy | `create(Guardian $guardian, int $teacherUserId, int $studentId): bool` | Verify ParentChildPolicy passes; verify teacher teaches a subject in student's class+section via timetable or subject assignment |
| ParentLeavePolicy | `create(Guardian $guardian, array $data): bool` | Verify ParentChildPolicy passes; verify `from_date >= tomorrow` |

### 15.3 Implementation Phases

| Phase | Tasks | Priority | Dependencies |
|---|---|---|---|
| Phase 1: Auth & Foundation | Parent auth middleware, OTP controller, ParentChildPolicy, ppt_* migrations (6 tables), Models, Providers | Critical | SYS, STD complete |
| Phase 2: Dashboard | ParentPortalController, child switcher, ParentDashboardService, dashboard Blade view | Critical | Phase 1 + STD |
| Phase 3: Academics | Attendance, Timetable, Homework, Results controllers + views | Critical | Phase 2 + TTS/TTF + HMW + EXM |
| Phase 4: Fee Management | FeeViewController, Razorpay integration, PDF receipt, payment history | Critical | Phase 1 + FIN + PAY |
| Phase 5: Communication | MessageController (ppt_messages), NotificationController, preferences | High | Phase 1 + NTF |
| Phase 6: Leave & Consent | LeaveController (ppt_leave_applications), ConsentFormController | High | Phase 1 |
| Phase 7: PTM | PtmController, slot booking, PtmSchedulingService | Medium | Phase 5 |
| Phase 8: Events | EventController, EventRsvpController (ppt_event_rsvps) | Medium | Event Engine partial |
| Phase 9: Health & Transport | HealthReportController, TransportViewController | Medium | HPC + TPT modules |
| Phase 10: Documents | DocumentController (ppt_document_requests), document vault | Medium | Phase 4 (Razorpay for doc fees) |
| Phase 11: Mobile API | REST API endpoints (Sanctum), PWA push, FCM/APNs integration | Low | Phase 1–4 complete |
| Phase 12: Security Tests | IDOR test suite, payment security tests, OTP rate limit tests | Critical | All phases |

### 15.4 Migration List

| # | Migration File | Creates Table | Notes |
|---|---|---|---|
| 1 | `2026_xx_xx_create_ppt_parent_sessions_table.php` | `ppt_parent_sessions` | Unique idx on guardian+device_token_fcm |
| 2 | `2026_xx_xx_create_ppt_messages_table.php` | `ppt_messages` | FULLTEXT idx; INDEX on thread_id+created_at |
| 3 | `2026_xx_xx_create_ppt_leave_applications_table.php` | `ppt_leave_applications` | INDEX on student_id+status |
| 4 | `2026_xx_xx_create_ppt_event_rsvps_table.php` | `ppt_event_rsvps` | Unique idx on event_id+guardian_id |
| 5 | `2026_xx_xx_create_ppt_document_requests_table.php` | `ppt_document_requests` | Unique on request_number |
| 6 | `2026_xx_xx_create_ppt_consent_form_responses_table.php` | `ppt_consent_form_responses` | Unique on consent_form_id+student_id+guardian_id |

---

## 16. V1 → V2 Delta

### 16.1 What Changed from V1

| Area | V1 | V2 Change | Status |
|---|---|---|---|
| Document structure | 15 sections, mixed format | 16 standardized sections per V2 template | Restructured |
| Tables | 5 ppt_* tables | 6 ppt_* tables (added `ppt_consent_form_responses`) | 🆕 Added |
| OTP Login | Not in V1 | Full OTP-based passwordless login with rate limiting, lockout FSM | 📐 New |
| Digital Consent Forms | Not in V1 | FR-PPT-11 + `ppt_consent_form_responses` table + ConsentFormController | 📐 New |
| PTM Scheduling | Not in V1 | FR-PPT-12 + PtmController + PtmSchedulingService + FSM | 📐 New |
| PWA Push | Mentioned briefly in V1 | Full Web Push subscription stored in ppt_parent_sessions.device_token_webpush | 📐 New |
| API endpoints | 11 endpoints in V1 | 18 API endpoints in V2; OTP auth endpoints added | Expanded |
| Web routes | ~65 in V1 | ~75 in V2; consent forms + PTM routes added | Expanded |
| Controllers | 10 in V1 | 16 in V2: +LeaveController, +ConsentFormController, +PtmController, +HealthReportController, +TransportViewController, +AccountSettingsController | Expanded |
| Services | 4 in V1 | 5 in V2: added PtmSchedulingService | Expanded |
| FormRequests | 7 in V1 | 9 in V2: added ConsentFormSignRequest, PtmBookingRequest | Expanded |
| Business Rules | 12 in V1 | 18 in V2: added OTP rules, consent form rules, PTM booking rules, volunteer capacity | Expanded |
| Test scenarios | 14 in V1 | 33 in V2: full coverage including PTM, consent, OTP, capacity tests | Expanded |
| Screens | ~35 in V1 | 38 in V2: +SCR-PPT-26 through 29 (consent + PTM) | Expanded |
| Security suggestions | Not in V1 | 4 dedicated security suggestions (SUG-PPT-21 through 24) | 📐 New |

### 16.2 What Was Retained from V1 (Unchanged)

- Core FK chain: `sys_users → std_guardians → std_student_guardian_jnt → std_students`
- Design philosophy: read-aggregation portal with minimal new tables
- 5 original `ppt_*` tables (schema refined but not restructured)
- All FR-PPT-01 through FR-PPT-10 functional requirements (retained, formatted to V2 template)
- Business rules BR-PPT-001 through BR-PPT-012 (retained + numbered consistently)
- All integration points with external modules
- Authorization model: Policies + Middleware (no Spatie roles for parent users)
- DomPDF for PDF generation; Razorpay for payments
- Razorpay idempotency requirement (BR-PPT-018 in V2, BR-PPT-012 equivalent in V1)

### 16.3 V1 Open Questions — V2 Decisions

| V1 Open Question | V2 Decision |
|---|---|
| Multi-child session: Laravel Session vs DB? | DB (ppt_parent_sessions.active_student_id) for multi-device sync; session used as cache |
| Message threading: simple list vs threads? | Thread model (thread_id hash) adopted — cleaner conversation UX |
| Dashboard caching: real-time vs cached? | 5-minute cache for non-realtime; today's attendance = no cache |
| Payment flow: in-portal AJAX vs hosted checkout? | Razorpay hosted checkout (PCI-compliant, simpler integration) |
| Counsellor report visibility default? | Default OFF (privacy-first); school explicitly enables per-setting |

---

*RBS Reference: Module Z — Parent Portal & Mobile App (ST.Z1.1.1.1 – ST.Z6.1.2.2)*
*V2 Document generated: 2026-03-26 | Status: Draft | All features 📐 Proposed (Greenfield)*
