# PPT — Parent Portal: Complete Analysis Pack
**Date:** 2026-06-29 | **Version:** 1.0 | **Author:** pa-business-analyst
**Sources:** V2 Requirement (PPT_ParentPortal_Requirement.md v2.0 2026-03-26), DDL v2 (ParentPortal_DDL_v2.sql 2026-06-04), V1 screen specs (12 files, ParentPortal_V2/), live code audit (Modules/ParentPortal/, migrations/tenant/), student-parent-portal.md memory (2026-04-02)

---

## Table of Contents

| Section | Artifact |
|---|---|
| 1 | FRD — Functional Requirements Document (10 sections) |
| 2 | Requirements Traceability Matrix (RTM) |
| 3 | Business Rules Register + Requirement Conditions Catalog + Validation & Edge-Case Catalog |
| 4 | Process Flows + State Machine (FSM) Catalog |
| 5 | Data Dictionary (Business View) + Cross-Module Dependency Map |
| 6 | NFR Catalog + Risk Register |
| 7 | Prioritization (MoSCoW) + Effort Estimation & Sprint Task Breakdown |
| 8 | User Stories + Acceptance Criteria (P0 Requirements) + Reporting & KPI Spec |
| 9 | Feature Specification (Screen Inventory) |

---

# Section 1: FRD — Functional Requirements Document

## 1. Module Overview

### 1.1 Purpose

The Parent Portal (PPT) gives parents and guardians of enrolled students a dedicated, mobile-first self-service interface to monitor and engage with their child's school journey. Parents can view attendance, results, homework status, and timetables; pay school fees online; apply for child leave; sign digital consent forms; book Parent-Teacher Meeting slots; and download official documents — all from a single authenticated portal, with multi-child support for families with multiple enrolled children.

### 1.2 Business Value

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

### 1.3 Scope

**In Scope:**
- Parent authentication: OTP-based passwordless login + password login
- Multi-child support: one parent account, multiple enrolled children; child-switcher widget on every screen
- Dashboard: unified snapshot for the active child (attendance, fees, homework, results)
- Attendance: monthly calendar view, subject-wise breakdown, year-to-date percentage
- Timetable: published weekly schedule for child's class-section
- Homework tracker: pending, submitted, overdue status per subject
- Academic results: term-wise marks, subject-wise view, report card download (post-publish gate)
- Leave application: submit and track child leave; class teacher approval flow
- Fee management: invoice view, Razorpay payment (UPI/Card/NetBanking/Wallet), PDF receipt
- Notification inbox: circulars, announcements, alerts; push notifications (FCM/APNs/Web Push)
- Digital consent forms: view and sign/decline school consent forms
- PTM scheduling: view available slots and book appointments
- Event calendar: school events with RSVP and volunteer sign-up
- Health reports: HPC module read-view (gated by school settings)
- Transport information: bus route, driver, pickup stop, live status if available
- Document vault: download official documents; request duplicate certificates
- Account settings: profile, password, notification preferences, device management
- Hostel information: child's hostel allocation (read-only, if Hostel module active)
- Learning hub: quiz, quest, and exam activity overview for child

**Out of Scope:**
- Direct video/audio calling (WebRTC — requires separate initiative)
- Parent-to-parent social messaging
- Real-time GPS tracking (requires hardware integration)
- Native mobile app (portal is PWA; native app is separate initiative)
- Attendance marking (belongs to Attendance/SchoolSetup module)
- Homework creation or grading (belongs to LmsHomework module)
- Fee structure management (belongs to StudentFee module)
- Parent registration/onboarding (auto-created on student enrollment per RBS B1.2.5)

### 1.4 Terminology

| Business Term | Meaning |
|---|---|
| Guardian | Parent or legal guardian linked to student(s) via the school's enrollment system |
| Active Child | The child currently selected in the portal; all data views are scoped to this child |
| Child Switcher | Navigation widget allowing a parent to change the active child without logging out |
| Portal Session | Authenticated portal access with device-specific state including the active child selection and push notification tokens |
| Consent Form | Digital form issued by the school for events, trips, or activities requiring parent authorization |
| Quiet Hours | A configurable time window during which non-urgent notifications are buffered and sent after the window ends |
| PTM | Parent-Teacher Meeting — scheduled appointment between a guardian and a teacher to discuss child's progress |
| Absence Alert | Push notification sent to parent on the same day a child is marked absent |
| Report Card Download Gate | Control that prevents report card PDF download until the school administrator officially publishes results for the term |
| Document Request | Online application for a duplicate certificate (TC, Bonafide, Marksheet, etc.) |
| IDOR | Insecure Direct Object Reference — security vulnerability; prevented here by the Child Ownership Check applied on every data endpoint |
| Child Ownership Check | Verification that the requested child's data belongs to the authenticated parent's linked children (enforced via guardian→student junction table) |
| e-Signature | Parent's typed name, timestamp, and IP address recorded as a legally defensible consent form signature |
| Fee Payment Idempotency | Payment gateway reference uniqueness check that prevents double-crediting an invoice on webhook replay |

---

## 2. User Roles and Access

### 2.1 Actors

| Actor | Description | Access Level |
|---|---|---|
| Parent / Guardian | Primary user — views child's academic and financial data; pays fees; communicates with school | Portal only; scoped exclusively to own linked children |
| Class Teacher | Approves or rejects child leave applications; receives parent messages | Admin panel; message receive + leave approval |
| Subject Teacher | Receives parent messages about subject queries | Admin panel; message receive for own subjects taught to child's class |
| Principal | Receives escalated communications | Admin panel; message receive |
| School Admin | Manages consent forms, document requests, PTM events; publishes report cards | Admin panel; full management |
| School Nurse | Controls health report visibility flags | Admin panel; sets visibility per record |
| System | Sends push notifications, fires payment webhooks, runs reminder jobs | Automated; no UI |

### 2.2 Role-Feature Matrix

| Feature | Parent | Class Teacher | School Admin | System |
|---|---|---|---|---|
| Dashboard (view own children's data) | Own children only | — | — | — |
| Switch Active Child | Own children only | — | — | — |
| Attendance View | Read-only | — | — | — |
| Timetable View | Read-only | — | — | — |
| Homework View | Read-only | — | — | — |
| Results View + Report Card Download | Read-only; gated by publish | — | Publish gate | — |
| Fee View + Online Payment | View + Pay (is_fee_payer=1) | — | — | Webhook handler |
| Leave Application | Submit + Withdraw (own child) | Approve / Reject | — | Notifier |
| Consent Form | Sign / Decline | — | Create / Publish | Reminder |
| PTM Booking | Book / Cancel slots | Slot management | Create events | Reminder |
| Event Calendar & RSVP | RSVP + Volunteer | — | Manage events | — |
| Health Reports | Read-only (gated) | — | Visibility flags (Nurse) | — |
| Transport Info | Read-only | — | — | — |
| Document Vault + Requests | Download / Request | — | Process / Upload | — |
| Notification Inbox | Read + Preferences | — | Send circulars | Dispatcher |
| Teacher Messaging | Compose (own child's teachers) | Reply | — | Notifier |
| Account Settings | Own profile + devices | — | — | — |
| Hostel Info | Read-only | — | — | — |
| Learning Hub | Read-only | — | — | — |

---

## 3. Functional Requirements

---

### REQ-PPT-001: Multi-Child Dashboard
**Priority:** Core (P0) | **Tags:** [DASHBOARD][DATA_ENTRY] | **Source:** FR-PPT-01 V2

**Description:** A parent logging in sees a unified dashboard showing all their linked children as summary cards, with a detailed academic snapshot for the currently active child. Switching the active child updates all data views throughout the portal.

**Actors:** Initiates: Parent | Processes: System (data aggregation) | Views: Parent

**Business Rules:**
| BR | Rule |
|---|---|
| BR-PPT-010 | Active child stored in portal session record (DB), not PHP session only — enables multi-device sync |
| BR-PPT-001 | All dashboard data exclusively belongs to the parent's linked children — no data from other students |

**Acceptance Criteria:**
- AC1: Dashboard loads within 3 seconds for a parent with 4 linked children
- AC2: Each child card shows photo, name, class+section, today's attendance status (Present / Absent / Not Marked)
- AC3: Active child snapshot shows: attendance percentage (current month), last test score, pending homework count, outstanding fee amount, next fee due date
- AC4: Switching active child (child card click or header switcher) immediately reloads all data for the new child
- AC5: Active child selection persists after browser refresh (stored in DB portal session)
- AC6: Parent with no linked children or no accessible children sees a clear empty state with contact instructions — no crash or error page
- AC7: Non-real-time data (homework count, test scores) cached for 5 minutes; today's attendance is never cached

**Integration:** StudentProfile (child cards), StudentFee (fee due), LmsHomework (homework count), LmsExam (last score), Attendance (today's status), SmartTimetable (current period)

**Enhancement Notes:** ENH-PPT-001 — Dashboard "Action Required" section (unsigned consent forms, unpaid fees) as a priority widget; ENH-PPT-002 — per-guardian Redis-tagged cache for targeted invalidation

---

### REQ-PPT-002: OTP-Based Passwordless Login
**Priority:** Core (P0) | **Tags:** [WORKFLOW][CONFIGURATION] | **Source:** FR-PPT-02 V2

**Description:** Parents log in via a 6-digit OTP sent to their registered mobile number. Standard password login is also supported. First-time login prompts password setup. Device tokens (FCM/APNs) registered or updated on successful login.

**Actors:** Initiates: Parent | Processes: System (OTP dispatch, rate limiter) | Views: Parent

**Business Rules:**
| BR | Rule |
|---|---|
| BR-PPT-013 | OTP expires after 10 minutes; max 3 entry attempts per OTP; 30-minute lockout after 5 consecutive failures |
| BR-PPT-009 | On re-login from a new device, FCM/APNs token registered or updated; on explicit logout, token marked inactive |

**Acceptance Criteria:**
- AC1: OTP received on registered mobile within 30 seconds
- AC2: Expired OTP shows clear error message and resend option
- AC3: After 5 consecutive failures within 30 minutes, account locked; parent informed via message (not just HTTP error)
- AC4: Max 3 OTP requests per mobile number per hour enforced
- AC5: First-time login forces password creation before portal access
- AC6: FCM device token registered/updated on login without creating duplicates (existing token updated by guardian+device_type)

**Integration:** SMS gateway (MSG91/Twilio), sys_users (auth), ppt_parent_sessions (token storage)

**Gap Note [inferred]:** No AuthController found in module; OTP route absent from web.php and api.php. This feature is NOT yet scaffolded, despite being P0. Must be built as a standalone controller with dedicated OTP route group outside the parent.portal middleware.

---

### REQ-PPT-003: Smart Notification Preferences
**Priority:** Core (P0) | **Tags:** [CONFIGURATION][NOTIFICATION] | **Source:** FR-PPT-03 V2

**Description:** Parent configures which notification types they subscribe to, which channels they receive on (In-App / SMS / Email / WhatsApp), and their quiet hours. Urgent alerts (absence, emergency) always bypass quiet hours.

**Actors:** Initiates: Parent | Processes: System (buffering logic) | Views: Parent

**Business Rules:**
| BR | Rule |
|---|---|
| BR-PPT-008 | Non-urgent notifications during quiet hours are buffered and sent after quiet period ends; AbsenceAlert and EmergencyAlert always bypass quiet hours |
| BR-PPT-009 | Multiple device tokens per guardian supported (phone + tablet + PC); notifications sent to all active tokens |

**Acceptance Criteria:**
- AC1: Disabling FeeReminder SMS prevents SMS dispatch for fee events (in-app notification still fires)
- AC2: Notification arriving during quiet hours is queued, not dropped; dispatched when quiet period ends
- AC3: AbsenceAlert is delivered immediately even during quiet hours
- AC4: Parent can set quiet_hours_start and quiet_hours_end independently per portal session (stored in ppt_parent_sessions)
- AC5: Preferences viewable and editable from Account Settings screen

**Integration:** Notification module (dispatch channels), ppt_parent_sessions (preferences JSON + quiet hours)

---

### REQ-PPT-004: Teacher Messaging
**Priority:** Core (P0) | **Tags:** [WORKFLOW][NOTIFICATION] | **Source:** FR-PPT-04 V2

**Description:** Parent composes private direct messages to any teacher who teaches their active child. Messages are grouped into threads. Read receipts indicate when the teacher has viewed the message. File attachments supported.

**Actors:** Initiates: Parent | Processes: System (thread grouping, notifications) | Views: Parent + Teacher (via admin panel)

**Business Rules:**
| BR | Rule |
|---|---|
| BR-PPT-003 | Parent can only message teachers who teach their active child's subjects (built from timetable assignment) |
| BR-PPT-001 | Message inbox and threads scoped to authenticated parent; no access to other guardians' threads |

**Acceptance Criteria:**
- AC1: Teacher dropdown shows only teachers assigned to active child's class-section subjects
- AC2: Message thread groups all messages between (guardian, teacher, child context) by a deterministic thread ID
- AC3: Read receipt timestamp shown within 1 second of teacher opening the thread
- AC4: File attachments (PDF/JPG/PNG/DOC, max 5 MB each, max 3 per message) stored in media storage; accessible via secure signed URL
- AC5: Parent cannot send a message to a teacher not assigned to their child — attempt blocked with validation error
- AC6: Full-text search on subject and body returns results within 2 seconds
- AC7: Teacher receives in-app notification within 1 minute of new parent message

**Integration:** SmartTimetable/SchoolSetup (teacher→subject→class assignment), sys_media (attachments), Notification (teacher alert)

**Gap Note:** `ppt_messages` table NOT in DDL v2 or migrations. `MessageController` absent from module. Teacher messaging must either: (a) create ppt_messages table + dedicated controller, or (b) integrate with CommonChat module. Decision pending.

---

### REQ-PPT-005: Fee Management and Online Payment
**Priority:** Core (P0) | **Tags:** [WORKFLOW][INTEGRATION][NOTIFICATION] | **Source:** FR-PPT-05 V2

**Description:** Parent views the active child's fee invoices and outstanding amounts, initiates Razorpay online payment (UPI/Card/NetBanking/Wallet), and downloads PDF payment receipts. Payment verification and idempotency are enforced server-side.

**Actors:** Initiates: Parent (with is_fee_payer permission) | Processes: System + Razorpay webhook | Views: Parent

**Business Rules:**
| BR | Rule |
|---|---|
| BR-PPT-002 | Parent can only pay invoices belonging to their own linked active child — cross-child payment attempt returns 403 |
| BR-PPT-018 | Razorpay payment_id uniqueness enforced — double-credit on webhook replay prevented |
| BR-PPT-012 | Every fee data endpoint includes child ownership verification |

**Acceptance Criteria:**
- AC1: Fee breakdown matches fin_fee_invoices data exactly; grouped by academic term
- AC2: Razorpay hosted checkout opens within 3 seconds of Pay button click
- AC3: On payment success: invoice status updated immediately; SMS receipt dispatched within 1 minute
- AC4: Cross-child invoice payment attempt blocked with HTTP 403
- AC5: Webhook replay with same payment_id does not update invoice a second time (idempotency check)
- AC6: PDF receipt downloadable immediately after payment success (DomPDF, school letterhead, A4 format)
- AC7: Non-fee-payer parent (is_fee_payer=0 on junction table) sees fee summary only; Pay button hidden
- AC8: Payment history filterable by date range and status (Success / Failed / Pending)

**Integration:** StudentFee (fin_fee_invoices, fin_transactions), Payment module (Razorpay), Notification (SMS receipt), sys_media (PDF receipt storage)

---

### REQ-PPT-006: Attendance View
**Priority:** Core (P0) | **Tags:** [DASHBOARD][REPORT] | **Source:** FR-PPT-06 V2

**Description:** Parent views the active child's attendance as a colour-coded monthly calendar and a subject-wise breakdown. Year-to-date attendance percentage shown. Absence alerts delivered on the same day.

**Actors:** Initiates: System (absence alert) + Parent (calendar view) | Views: Parent

**Business Rules:**
| BR | Rule |
|---|---|
| BR-PPT-001 | Attendance data scoped exclusively to parent's active linked child |
| BR-PPT-012 | Child ownership verified on every attendance endpoint |

**Acceptance Criteria:**
- AC1: Monthly calendar renders within 2 seconds for a full academic year of data
- AC2: Each date colour-coded: Present (green), Absent (red), Half-Day (orange), Holiday (grey), Leave (blue), Not Marked (white)
- AC3: Monthly statistics shown: Present count, Absent count, Leave count, Working days, Attendance %
- AC4: Subject-wise attendance grid shown only if school has subject-wise attendance enabled
- AC5: Parent cannot modify any attendance record — all views read-only
- AC6: Same-day absence notification reaches parent within 5 minutes of teacher marking the child absent
- AC7: Year-to-date percentage shown based on all terms in current academic session

**Integration:** Attendance module (std_attendance, std_subject_attendance), SchoolSetup (sch_holidays, academic session), Notification (absence push)

---

### REQ-PPT-007: Homework Tracker
**Priority:** Standard (P1) | **Tags:** [DASHBOARD][REPORT] | **Source:** FR-PPT-07 V2

**Description:** Parent monitors all homework assigned to the active child, grouped by subject and status (Pending / Submitted / Overdue / Graded). Overdue count shown prominently.

**Actors:** Views: Parent

**Business Rules:** BR-PPT-001 (child data scoping), BR-PPT-012 (ownership check)

**Acceptance Criteria:**
- AC1: All homework for active child's class-section shown, sourced from LmsHomework module
- AC2: Submission status accurately reflects homework module data (Pending / Submitted / Overdue / Graded)
- AC3: Parent cannot submit homework on behalf of child from this portal — view is read-only
- AC4: Overdue homework count shown as a distinct badge; push notification triggered when homework transitions to overdue
- AC5: Filter by subject and date range functional

**Integration:** LmsHomework (hmw_assignments, hmw_submissions), Notification (overdue alert)

---

### REQ-PPT-008: Timetable View
**Priority:** Standard (P1) | **Tags:** [REPORT] | **Source:** FR-PPT-08 V2

**Description:** Parent views the active child's published weekly class timetable as a day × period grid, with today's column and current period highlighted.

**Actors:** Views: Parent

**Acceptance Criteria:**
- AC1: Only published timetables are shown (draft/unpublished not accessible)
- AC2: Current day column and current period cell visually highlighted
- AC3: Each cell displays subject name and teacher name
- AC4: Academic term selector available; defaults to current active term
- AC5: Read-only — parent cannot modify timetable data

**Integration:** SmartTimetable (tt_timetable_cells, tt_published_timetables), SchoolSetup (academic terms, subjects)

---

### REQ-PPT-009: Academic Results and Report Cards
**Priority:** Standard (P1) | **Tags:** [REPORT][WORKFLOW] | **Source:** FR-PPT-09 V2

**Description:** Parent views exam results for the active child, grouped by academic term, with subject-wise marks and optional class-average comparison. Downloadable PDF report card available after school publishes results for the term.

**Actors:** Views: Parent | Controls: School Admin (publish gate)

**Business Rules:**
| BR | Rule |
|---|---|
| BR-PPT-005 | Report card PDF not downloadable until school admin has published the term's report cards |
| BR-PPT-001 | Results scoped to parent's active linked child |

**Acceptance Criteria:**
- AC1: Results match data in exam module exactly (marks_obtained, max_marks, grade, pass/fail per subject)
- AC2: Unpublished report cards show "Results not yet published" — no data leak before publication
- AC3: Class average comparison shown only if school enables this setting (privacy-preserving; no individual peer data)
- AC4: PDF report card contains school letterhead, student details, all subject marks, grades, teacher remarks (A4, DomPDF)
- AC5: Results grouped by term: Q1, Q2, Half-Yearly, Annual (as configured by school)

**Integration:** LmsExam (exm_results, exm_report_cards), SchoolSetup (academic terms), MarksheetGeneration (if integrated), sys_school_settings (class average toggle)

---

### REQ-PPT-010: Leave Application
**Priority:** Standard (P1) | **Tags:** [WORKFLOW][NOTIFICATION][APPROVAL] | **Source:** FR-PPT-10 V2

**Description:** Parent submits a leave application on behalf of the active child. Class teacher reviews and approves or rejects. On approval, the attendance module marks the leave dates accordingly. Parent can withdraw a pending application.

**Actors:** Initiates: Parent | Approves: Class Teacher | Notified: System

**Business Rules:**
| BR | Rule |
|---|---|
| BR-PPT-004 | Leave from_date must be >= tomorrow; applying leave for today or past dates rejected |
| BR-PPT-017 | On class teacher approval, an event is dispatched to the attendance module to mark approved dates as Leave (not Absent) |
| BR-PPT-019 | Only Pending applications may be withdrawn by the parent |

**Acceptance Criteria:**
- AC1: Leave application rejected by validation if from_date is today or a past date
- AC2: Number of leave days auto-calculated, excluding school holidays (sch_holidays)
- AC3: Class teacher receives in-app + email notification within 2 minutes of submission
- AC4: Parent notified of approval/rejection within 2 minutes of teacher action
- AC5: On approval, leave dates appear as Leave status in attendance module (not Absent)
- AC6: Parent can withdraw a Pending application; withdrawal triggers status change to Withdrawn
- AC7: Approved or Rejected applications cannot be withdrawn
- AC8: Leave application form requires reason minimum 20 characters

**Integration:** SchoolSetup (sch_holidays, class teacher lookup), Attendance module (leave date update), Notification (submission + decision alerts)

**Gap Note:** `ppt_leave_applications` table absent from DDL v2 and migrations. LeaveController, StoreParentLeaveRequest, WithdrawParentLeaveRequest, and leave views (create/index/show/no-session) all exist. Migration must be created before this feature can function.

---

### REQ-PPT-011: Digital Consent Forms
**Priority:** Standard (P1) | **Tags:** [WORKFLOW][NOTIFICATION] | **Source:** FR-PPT-11 V2

**Description:** School publishes digital consent forms for events, trips, and activities. Parent views pending forms, reads the full content, and signs (agrees) or declines with a reason. Signed responses are immutable.

**Actors:** Initiates: School Admin (publish) | Signs: Parent | Notified: System + School Admin

**Business Rules:**
| BR | Rule |
|---|---|
| BR-PPT-014 | Parent cannot sign the same form twice — database unique constraint on (consent_form_id, student_id, guardian_id) |
| BR-PPT-021 | Consent form responses are immutable — ppt_consent_form_responses has NO deleted_at column; no delete or soft-delete permitted |

**Acceptance Criteria:**
- AC1: Forms past their deadline show as "Closed" — sign action unavailable
- AC2: Signing records: signer name (typed), IP address, and exact timestamp — immutable from the moment of creation
- AC3: Parent cannot submit the same consent form twice — blocked by unique constraint with a user-friendly error message
- AC4: Declining a form requires a reason (minimum 10 characters)
- AC5: School admin can view a list of which parents have and have not signed each form
- AC6: Push notification sent 48 hours and 24 hours before form deadline if unsigned
- AC7: PDF copy of signed form downloadable within 1 minute of signing

**Integration:** ppt_consent_forms (school admin creates), ppt_consent_form_responses (parent response), sys_media (PDF storage), Notification (deadline reminders)

---

### REQ-PPT-012: PTM Scheduling
**Priority:** Standard (P1) | **Tags:** [WORKFLOW][NOTIFICATION][APPROVAL] | **Source:** FR-PPT-12 V2

**Description:** School publishes Parent-Teacher Meeting time slots. Parent books an available slot per teacher they wish to meet. Race conditions in slot booking are prevented with a database transaction. Parent can cancel up to 1 hour before the PTM.

**Actors:** Initiates: School Admin (create PTM events) + Parent (book slot) | Notified: Parent + Teacher

**Business Rules:**
| BR | Rule |
|---|---|
| BR-PPT-015 | One booking per teacher per PTM event per guardian; slot released immediately on cancellation |
| BR-PPT-020 | Cancellation not permitted within 1 hour of the PTM appointment |

**Acceptance Criteria:**
- AC1: Double-booking prevented via database transaction (SELECT...FOR UPDATE pattern); second concurrent booking attempt receives a user-friendly "slot just taken" message
- AC2: Booking confirmation sent to both parent and teacher within 2 minutes
- AC3: Cancelled slot is immediately available for rebooking by other parents
- AC4: Reminder push notification sent 24 hours and 1 hour before PTM appointment
- AC5: Virtual meeting link displayed on booking confirmation if school provides one

**Integration:** Ptm module (ptm_events, ptm_teacher_slots, ptm_bookings — cross-module dependency), Notification (confirmation + reminder)

---

### REQ-PPT-013: Event Calendar and RSVP
**Priority:** Standard (P1) | **Tags:** [WORKFLOW][NOTIFICATION] | **Source:** FR-PPT-13 V2

**Description:** Parent views the school event calendar and RSVPs for events requiring attendance. Parent can sign up as a volunteer for school events with role-based capacity limits.

**Actors:** Initiates: Parent | Manages: School Admin | Processes: System (capacity)

**Business Rules:**
| BR | Rule |
|---|---|
| BR-PPT-016 | Volunteer role capacity enforced — sign-up rejected if max_slots reached for a role |
| BR-PPT-001 | RSVP data scoped to authenticated guardian only |

**Acceptance Criteria:**
- AC1: RSVP unique per (guardian, event) — duplicate RSVP attempt updates existing record rather than creating duplicate
- AC2: Volunteer sign-up blocked when role capacity is reached; clear capacity-full message shown
- AC3: .ics calendar export functional on both mobile and desktop
- AC4: Push notification reminder 48 hours and 2 hours before volunteer duty

**Integration:** EventEngine (event records for ppt_event_rsvps.event_id), ppt_event_rsvps, Notification (reminders)

**Gap Note [inferred]:** ppt_event_rsvps.event_id has no FK constraint in DDL v2 — EventEngine event table status unclear. Event.php model in module is a placeholder wrapper. Decision needed on canonical event source.

---

### REQ-PPT-014: Health and HPC Reports
**Priority:** Standard (P1) | **Tags:** [REPORT][CONFIGURATION] | **Source:** FR-PPT-14 V2

**Description:** Parent views the active child's health records, physical assessment data, and counsellor reports through the HPC module's read-view. All access is gated by visibility flags.

**Actors:** Views: Parent (gated) | Controls: School Nurse / Admin (visibility flags)

**Business Rules:**
| BR | Rule |
|---|---|
| BR-PPT-006 | Medical records visible to parent ONLY if std_health_records.parent_visible = 1 |
| BR-PPT-007 | Counsellor/psychological reports visible ONLY if school setting parent_counsellor_report_visibility = 1 (default OFF) |

**Acceptance Criteria:**
- AC1: General health records (blood group, allergies, medical conditions) visible when parent_visible = 1
- AC2: Counsellor reports hidden by default; only visible after school explicitly enables the setting
- AC3: All health data is read-only for parent — no edit actions
- AC4: HPC PDF report downloadable (mirrors HPC module DomPDF generation)
- AC5: Section gracefully hidden if HPC module is not active for the school

**Integration:** Hpc module (hpc_health_profiles, hpc_physical_assessments, hpc_counsellor_reports), sys_school_settings (visibility flags)

---

### REQ-PPT-015: Transport Tracking
**Priority:** Standard (P1) | **Tags:** [DASHBOARD][INTEGRATION] | **Source:** FR-PPT-15 V2

**Description:** Parent views the bus route, vehicle, driver details, and pickup stop assigned to the active child. Live GPS status shown if the Transport module provides it. Graceful "not activated" state if Transport module is disabled.

**Actors:** Views: Parent

**Acceptance Criteria:**
- AC1: Shows graceful "Transport module not activated" message if tpt module disabled — no error
- AC2: Driver mobile number shown as click-to-call link on mobile devices
- AC3: Live GPS location shown only when real GPS data is available; static route shown otherwise
- AC4: Boarding/exit push notification shown if transport module fires RFID events

**Integration:** Transport module (tpt_routes, tpt_vehicles, tpt_student_route_jnt, tpt_stops)

---

### REQ-PPT-016: Document Vault and Requests
**Priority:** Standard (P1) | **Tags:** [WORKFLOW][INTEGRATION] | **Source:** FR-PPT-16 V2

**Description:** Parent downloads official documents for the active child (report cards, certificates, marksheets). Parent requests duplicate certificates online with payment for fee-required documents.

**Actors:** Initiates: Parent | Processes: School Admin | Notified: Parent

**Business Rules:**
| BR | Rule |
|---|---|
| BR-PPT-011 | Fulfilled document download requires Razorpay payment when fee_required > 0 |
| BR-PPT-022 | Document download links expire after 24 hours (signed temporary URL) |
| BR-PPT-001 | Documents and requests scoped to parent's linked active child |

**Acceptance Criteria:**
- AC1: Unpublished documents show "Not yet available" — no pre-release download
- AC2: Fee-required documents blocked for download until payment confirmed; download allowed immediately after payment
- AC3: Parent notified at each status change (Pending → Processing → Ready → Completed / Rejected)
- AC4: Fulfilled document download URL expires after 24 hours (Storage::temporaryUrl pattern)
- AC5: Request reason must be minimum 20 characters

**Integration:** Certificate module (certificates), StudentFee/MarksheetGeneration (marksheets), sys_media (document files), Payment (Razorpay for doc fee), Notification (status alerts)

---

### REQ-PPT-017: Notification Inbox and Circulars
**Priority:** Standard (P1) | **Tags:** [NOTIFICATION][DASHBOARD] | **Source:** FR-PPT-17 V2

**Description:** Parent views all school notifications, circulars, and alerts in a unified inbox with read/unread tracking and filter support.

**Actors:** Views: Parent | Dispatches: System

**Acceptance Criteria:**
- AC1: Unread count badge updates immediately when new notification arrives
- AC2: Marking all as read clears badge instantly
- AC3: Push notification tap deep-links to the relevant in-app screen (e.g., fee invoice, attendance calendar)
- AC4: Filter by notification type, date range, and read/unread status functional
- AC5: Individual notification detail shows full body and linked action buttons

**Integration:** Notification module (ntf_notifications, ntf_circulars), FCM/APNs (push delivery)

---

### REQ-PPT-018: Account Settings
**Priority:** Standard (P1) | **Tags:** [CONFIGURATION] | **Source:** FR-PPT-18 V2

**Description:** Parent manages their profile, changes password, views linked children, configures notification preferences and quiet hours, manages active device sessions, and sets language preference.

**Actors:** Manages: Parent

**Acceptance Criteria:**
- AC1: Profile shows own name, email, mobile, and photo (sourced from std_guardians)
- AC2: Password change requires current password verification before accepting new password
- AC3: Device session list shows all active portal sessions; parent can logout a specific device
- AC4: Language preference saved and applied to all subsequent portal views
- AC5: Notification preferences updated per REQ-PPT-003

**Integration:** sys_users (auth, password), std_guardians (profile data), ppt_parent_sessions (device management)

---

### REQ-PPT-019: Hostel Information View
**Priority:** Enhanced (P2) | **Tags:** [DASHBOARD] | **Source:** [inferred from ParentHostelController in live code]

**Description:** Parent views the active child's hostel allocation details (building, floor, room, bed) in read-only mode if the Hostel module is active.

**Acceptance Criteria:**
- AC1: Hostel section shows graceful "Hostel module not activated" if HST module disabled
- AC2: All hostel data is read-only for parent
- AC3: Room mate count shown (not individual names, for privacy)

**Integration:** Hostel module (hst_allotments, hst_rooms, hst_buildings)

---

### REQ-PPT-020: Learning Hub
**Priority:** Enhanced (P2) | **Tags:** [DASHBOARD] | **Source:** [inferred from ParentLearningController in live code]

**Description:** Parent views an aggregated overview of the active child's LMS activity — quizzes attempted, quests completed, online exam status — to understand the child's digital learning engagement.

**Acceptance Criteria:**
- AC1: Shows quiz completion count, quest badge count, and pending online exams for active child
- AC2: Data is read-only; parent cannot attempt assessments on behalf of child
- AC3: Graceful empty state if LMS modules (LmsQuiz, LmsQuests, LmsExam) are not active

**Integration:** LmsQuiz, LmsQuests, LmsExam

---

## 4. Business Rules Register

| ID | Rule (Business Statement) | Type | Trigger | Enforcement Point |
|---|---|---|---|---|
| BR-PPT-001 | Parent can access data ONLY for children linked via the guardian→student junction where can_access_parent_portal = 1 and the guardian's user matches the authenticated parent | Permission | Every data endpoint | Child Ownership Check (ConsentFormPolicy; ParentChildPolicy MISSING — P0 gap) |
| BR-PPT-002 | Fee payment allowed only for invoices belonging to the authenticated parent's linked active child | Permission | Fee payment initiation | ParentFeePaymentController + policy |
| BR-PPT-003 | Parent can message only teachers who teach their active child's subjects | Permission | Message compose | ParentMessagePolicy (MISSING — P1 gap) |
| BR-PPT-004 | Leave application from_date must be >= tomorrow; same-day and past-date applications rejected | Validation | Leave form submission | StoreParentLeaveRequest |
| BR-PPT-005 | Report card PDF is not downloadable until school admin has published results for the term | Workflow | Report card download | ParentResultController (publish gate check) |
| BR-PPT-006 | Medical records are visible to parent only if the health record's parent_visible flag = 1 | Permission | Health report view | ParentHealthController (query filter) |
| BR-PPT-007 | Counsellor/psychological reports visible only if school setting parent_counsellor_report_visibility = 1 | Permission | Health report view | ParentHealthController (settings check) |
| BR-PPT-008 | Non-urgent notifications arriving during quiet hours are buffered; AbsenceAlert and EmergencyAlert always bypass quiet hours | Workflow | Notification dispatch | NotificationPreferenceService (MISSING — P1 gap) |
| BR-PPT-009 | On login, existing FCM/APNs token for that guardian + device_type updated (not duplicated); on explicit logout, token set inactive | Workflow | Login / Logout | ParentAccountController |
| BR-PPT-010 | Active child stored in ppt_parent_sessions.active_student_id (DB) not just PHP session, for multi-device context sync | Workflow | Child switch | ParentContextService |
| BR-PPT-011 | Fulfilled document download requires Razorpay payment when fee_required > 0 on the document request | Workflow | Document download | ParentDocumentController (fee gate) |
| BR-PPT-012 | Every data endpoint verifies guardian→student ownership — P0 security requirement; IDOR prevention | Permission | All data requests | Child Ownership Check on every controller method |
| BR-PPT-013 | OTP expires after 10 minutes; maximum 3 entry attempts per OTP code; 30-minute lockout after 5 consecutive failures in a 30-minute window; max 3 OTP requests per mobile per hour | Validation + Concurrency | OTP login | OTP AuthController (MISSING — P0 gap) + rate limiter |
| BR-PPT-014 | Parent cannot sign the same consent form twice for the same child — database unique constraint on (consent_form_id, student_id, guardian_id) | Validation | Consent form sign | SignParentConsentFormRequest + DB unique constraint |
| BR-PPT-015 | One PTM slot booking per teacher per PTM event per guardian; slot released immediately on cancellation | Concurrency + Workflow | PTM slot booking | ParentPtmController + DB transaction (SELECT...FOR UPDATE) |
| BR-PPT-016 | Volunteer sign-up for an event role is rejected if max_slots for that role is already reached | Validation + Concurrency | Event volunteer signup | ParentEventController (capacity check) |
| BR-PPT-017 | On class teacher approval of a leave application, an event is dispatched to the attendance module to mark the approved dates as Leave status | Workflow | Leave approval | ParentLeaveController (event dispatch) |
| BR-PPT-018 | Razorpay payment_id uniqueness enforced — webhook replay with same payment_id does not credit the invoice a second time | Concurrency | Payment webhook | ParentFeePaymentController + DB unique constraint on payment_reference |
| BR-PPT-019 | Only Pending leave applications may be withdrawn by the parent; Approved and Rejected applications cannot be withdrawn | Workflow | Leave withdrawal | ParentLeaveController (status guard) |
| BR-PPT-020 | Cancellation of a PTM booking is not permitted within 1 hour of the appointment start time | Validation | PTM cancellation | ParentPtmController (time guard) |
| BR-PPT-021 | Consent form responses are legally immutable — ppt_consent_form_responses table has no deleted_at column; deletion or soft-delete is prohibited | Workflow | Any data modification | DB design (no deleted_at column) |
| BR-PPT-022 | All PPT data queries are automatically scoped to the current tenant database — no cross-tenant data access possible | Permission | All queries | stancl/tenancy database isolation |

---

## 5. Data Requirements

### 5.1 Owned Entities (ppt_* tables)

**Parent Portal Session** (`ppt_parent_sessions`)
Tracks per-device portal access state including the active child, push notification tokens, notification preferences, and quiet hours.

| Business Field | Meaning | Type | Required | PII? |
|---|---|---|---|---|
| Guardian | Which parent this session belongs to | Link to Guardian record | Yes | No |
| Active Child | Child currently selected in the portal | Link to Child record | No (null until first selection) | No |
| Android Push Token | Google FCM device token for push notifications | Text | No | No |
| iOS Push Token | Apple APNs device token for push notifications | Text | No | No |
| Web Push Subscription | Browser-based push subscription (PWA) JSON | Text | No | No |
| Device Type | Android / iOS / Web / Unknown | Choice | Yes | No |
| Notification Preferences | Per-alert-type channel toggles (JSON) | Text (JSON) | No | No |
| Quiet Hours Start | Time from which non-urgent notifications are buffered | Time | No | No |
| Quiet Hours End | Time at which buffered notifications are released | Time | No | No |
| Last Active | When the parent last used the portal | Timestamp | No | No |
| Session Active | Whether this session is currently active | Yes/No | Yes | No |

Privacy: No sensitive PII beyond standard auth linkage. Push tokens are device credentials — internal classification.

---

**Consent Form** (`ppt_consent_forms`)
School-created digital consent forms for events, trips, and activities.

| Business Field | Meaning | Type | Required | PII? |
|---|---|---|---|---|
| Title | Form name displayed to parent | Text (max 200) | Yes | No |
| Content | Full form text/HTML | Long text | Yes | No |
| Target Class | Class this form applies to (null = all classes) | Link to Class | No | No |
| Target Section | Section this form applies to (null = all sections) | Link to Section | No | No |
| Response Deadline | Date-time after which form closes for signing | Timestamp | Yes | No |
| Allow Decline | Whether parents may decline (vs forced consent) | Yes/No | Yes | No |
| Status | Draft / Published / Closed | Choice | Yes | No |

Privacy: Internal. No parent PII stored here.

---

**Consent Form Response** (`ppt_consent_form_responses`) — IMMUTABLE
Parent's decision on a school consent form. No deletion permitted.

| Business Field | Meaning | Type | Required | PII? |
|---|---|---|---|---|
| Consent Form | Which form this response is for | Link to Consent Form | Yes | No |
| Child | Which child this consent is for | Link to Child record | Yes | No |
| Guardian | Which parent signed | Link to Guardian record | Yes | No |
| Response | Signed / Declined | Choice | Yes | No |
| Decline Reason | Required when response is Declined | Text | Conditional | No |
| Signer Name | Parent's typed name (e-signature) | Text (max 150) | Yes | Confidential |
| Signing IP Address | IP address at time of signing | Text | No | Confidential |
| Signed At | Exact timestamp of signature | Timestamp | Yes | No |

Privacy: Signer name and IP are Confidential (legal record). These cannot be modified after creation.

---

**Event RSVP** (`ppt_event_rsvps`)
Parent's attendance confirmation and volunteer registration for school events.

| Business Field | Meaning | Type | Required | PII? |
|---|---|---|---|---|
| Event | Which school event this RSVP is for | Link to Event | Yes | No |
| Guardian | Which parent is RSVPing | Link to Guardian | Yes | No |
| Child | Which child this RSVP relates to | Link to Child | No | No |
| RSVP Status | Attending / Not Attending / Maybe | Choice | Yes | No |
| Volunteer | Whether parent is signing up to volunteer | Yes/No | Yes | No |
| Volunteer Role | Role selected (Food stall, Registration desk, etc.) | Text (max 150) | Conditional | No |
| RSVP Notes | Optional message to school | Text | No | No |
| Confirmed At | When RSVP was confirmed | Timestamp | No | No |
| Reminder Sent At | When last reminder was dispatched | Timestamp | No | No |

Privacy: Internal.

---

**Document Request** (`ppt_document_requests`)
Online application for a duplicate certificate or official document.

| Business Field | Meaning | Type | Required | PII? |
|---|---|---|---|---|
| Request Number | Unique reference (PPT-DR-YYYY-XXXXXXXX) | Text | Yes (auto) | No |
| Child | Which child the document is for | Link to Child | Yes | No |
| Guardian | Which parent made the request | Link to Guardian | Yes | No |
| Document Type | TC / Marksheet / Bonafide / Character / Migration / Medical Fitness / Other | Choice | Yes | No |
| Reason | Why the duplicate is needed | Text (min 20 chars) | Yes | Internal |
| Urgency | Normal / Urgent | Choice | Yes | No |
| Status | Pending / Processing / Ready / Completed / Rejected | Choice | Yes | No |
| Admin Notes | Admin's response or rejection reason | Text | No | Internal |
| Fee Required | Amount parent must pay before receiving document | Decimal | Yes (default 0) | No |
| Fee Paid | Whether payment was completed | Yes/No | Yes (default No) | No |
| Payment Reference | Razorpay payment ID (unique — idempotency guard) | Text | No | No |
| Fulfilled Document | File uploaded by admin after processing | Link to File | No | No |
| Fulfilled At | When document was made available | Timestamp | No | No |

Privacy: Reason is Internal. Payment reference is Internal.

---

### 5.2 Read-Only Integration Tables (not owned by PPT)

| Business Entity | Source Module | Key Tables | Access Type |
|---|---|---|---|
| Child (Student) | StudentProfile | std_students | Read |
| Guardian | StudentProfile | std_guardians | Read |
| Guardian-Child Link | StudentProfile | std_student_guardian_jnt | Read (can_access_parent_portal flag critical) |
| Health Records | StudentProfile / HPC | std_health_records, hpc_health_profiles | Read (parent_visible gated) |
| Fee Invoices | StudentFee | fin_fee_invoices | Read + status update on payment |
| Payment History | StudentFee | fin_transactions | Read + Write on payment callback |
| Timetable | SmartTimetable | tt_timetable_cells, tt_published_timetables | Read |
| Homework | LmsHomework | hmw_assignments, hmw_submissions | Read |
| Exam Results | LmsExam | exm_results, exm_report_cards | Read |
| Attendance | Attendance module | std_attendance, std_subject_attendance | Read |
| Transport | Transport | tpt_routes, tpt_vehicles, tpt_student_route_jnt | Read |
| Notifications | Notification | ntf_notifications, ntf_circulars | Read + Dispatch |
| Files / Documents | SystemConfig | sys_media | Read + Write (doc uploads) |
| School Settings | SystemConfig | sys_school_settings | Read (visibility flags) |
| School Users (Auth) | SystemConfig | sys_users | Read (teacher lookup) |
| Hostel Allocation | Hostel | hst_allotments, hst_rooms | Read |
| LMS Activities | LmsQuiz / LmsQuests / LmsExam | Various attempt tables | Read |
| PTM Events/Slots | Ptm module | ptm_events, ptm_teacher_slots, ptm_bookings | Read + Write (booking) |

---

## 6. Workflows

### Workflow 1: OTP Passwordless Login
**Trigger:** Parent selects "Login with OTP" and enters mobile number
**End States:** Authenticated (PORTAL_HOME), OTP_LOCKED (30 min)
**Actors:** Parent | System (SMS gateway, rate limiter)

| Step | Actor | Action |
|---|---|---|
| 1 | System | Rate-limit check: max 3 OTP requests/hour/mobile |
| 2a | System (limit reached) | Return error with retry timer — stop |
| 2b | System | Generate 6-digit OTP, store hashed with 10-minute expiry, dispatch via SMS |
| 3 | Parent | Enter 6-digit OTP |
| 4 | System | Validate OTP (not expired, attempt count <= 3) |
| 5a | System (invalid) | Increment attempt counter; if 5 consecutive failures → LOCKED state (30 min) |
| 5b | System (valid) | Authenticate session; check if first-time login |
| 6a | System (first login) | Force password setup screen → PORTAL_HOME after setup |
| 6b | System (returning) | Register/update device token; redirect to PORTAL_HOME (dashboard) |

**Exception Paths:** Expired OTP: prompt resend (step 2); SMS delivery failure: show retry; account lockout: show lockout timer with contact-school option.
**Notifications Triggered:** None to parent (OTP itself is the notification).

---

### Workflow 2: Leave Application and Approval
**Trigger:** Parent clicks "Apply Leave" for active child
**End States:** Approved (attendance updated), Rejected (notes visible), Withdrawn

| Step | Actor | Action |
|---|---|---|
| 1 | Parent | Fill leave form: dates, leave type, reason (min 20 chars), optional supporting document |
| 2 | System | Validate from_date >= tomorrow; calculate number_of_days (excluding holidays) |
| 3 | System | Create ppt_leave_applications record with status=Pending |
| 4 | System | Dispatch in-app + email notification to class teacher |
| 5 | Class Teacher | Review in admin panel; approve or reject with notes |
| 6a | System (Approved) | Update status=Approved; dispatch event to attendance module; parent notified |
| 6b | System (Rejected) | Update status=Rejected with reviewer_notes; parent notified |

**Exception Path:** Parent withdraws before teacher acts → status=Withdrawn; teacher notified of withdrawal.
**Notifications:** Step 4 (teacher: submission); Step 6 (parent: decision within 2 minutes of teacher action).

---

### Workflow 3: Fee Payment via Razorpay
**Trigger:** Parent selects unpaid invoices and clicks Pay
**End States:** Invoice status = Paid (success), Unpaid/Overdue (failure/cancellation)

| Step | Actor | Action |
|---|---|---|
| 1 | Parent | Select one or more unpaid installments; system validates is_fee_payer = 1 |
| 2 | System | Verify child ownership (ParentChildPolicy — P0 gap); create Razorpay order |
| 3 | Parent | Completes payment in Razorpay hosted checkout (UPI/Card/NetBanking/Wallet) |
| 4 | System | Razorpay fires success webhook; verify signature server-side |
| 5 | System | Check payment_id uniqueness (idempotency); update invoice status=Paid; create fin_transactions record |
| 6 | System | Generate DomPDF receipt; dispatch SMS receipt to parent mobile |

**Exception Path:** Razorpay payment fails or parent cancels → invoice remains Unpaid; parent can retry. Webhook replay with same payment_id → rejected silently (idempotency).
**Notifications:** Step 6 (parent: SMS receipt within 1 minute).

---

### Workflow 4: Document Request and Fulfillment
**Trigger:** Parent submits duplicate document request
**End States:** Completed (document downloadable), Rejected (admin_notes visible)

| Step | Actor | Action |
|---|---|---|
| 1 | Parent | Fill request form: document_type, reason, urgency |
| 2 | System | Create ppt_document_requests with status=Pending; auto-generate request_number |
| 3 | School Admin | Review request; move to Processing |
| 4a (fee_required = 0) | School Admin | Upload fulfilled document; set status=Completed; parent notified with download link |
| 4b (fee_required > 0) | School Admin | Set status=Ready; notify parent to pay fee |
| 5 | Parent | Pay fee via Razorpay |
| 6 | System | Verify payment; status=Completed; parent notified; download link (24-hour signed URL) |

**Exception Path:** Admin rejects at any stage → status=Rejected; admin_notes required; parent notified.
**Notifications:** Status change at each step; download link expires after 24 hours.

---

### Workflow 5: Consent Form Signing
**Trigger:** Parent views unsigned consent form within deadline
**End States:** Signed (immutable), Declined (immutable)

| Step | Actor | Action |
|---|---|---|
| 1 | Parent | Open consent form; read full content |
| 2 | Parent | Click "I Agree" or "Decline" |
| 3 | System | Validate: not past deadline; not already signed; decline_reason provided if declining |
| 4 | System | Create ppt_consent_form_responses with signed_at, signed_ip, signer_name — immutable from this point |
| 5 | System | Generate PDF confirmation; notify school admin of response |

**Exception Path:** Past deadline → form shows as Closed; sign action unavailable. Double-sign attempt → DB constraint violation → user-friendly "already signed" message.
**Notifications:** Step 5 (admin: new response); 48h and 24h pre-deadline reminder to parent if unsigned.

---

### Workflow 6: PTM Slot Booking
**Trigger:** Parent selects an available time slot for a teacher
**End States:** Booked (confirmation sent), Slot_Released (after cancellation)

| Step | Actor | Action |
|---|---|---|
| 1 | Parent | View PTM event; select teacher; choose available time slot |
| 2 | System | Initiate database transaction; check slot still available (SELECT...FOR UPDATE) |
| 3a (available) | System | Create booking; commit transaction; send confirmation to parent and teacher |
| 3b (race condition) | System | Roll back transaction; return "Slot just taken; please choose another" |
| 4 | Parent (cancel) | Request cancellation ≥ 1 hour before PTM |
| 5 | System | Check time guard (>= 1 hour remaining); release slot back to pool; notify teacher |

**Exception Path:** Cancellation attempt < 1 hour before PTM → rejected with time restriction message.
**Notifications:** Step 3a (confirmation to parent + teacher); Reminder at 24h and 1h before appointment.

---

## 7. Reporting and Analytics

### RPT-PPT-001: Child Attendance Summary
**Purpose:** Parent reviews a formatted attendance summary for sharing at meetings or for personal records
**Audience:** Parent
**Frequency:** On demand
**Contents:** Monthly and year-to-date attendance (Present/Absent/Leave/Half-Day counts and percentage), subject-wise periods attended
**Filters:** Month, academic term
**Export:** PDF (DomPDF, school letterhead, A4)

---

### RPT-PPT-002: Fee Ledger and Payment History
**Purpose:** Complete record of all invoices and payments for the active child
**Audience:** Parent
**Frequency:** On demand
**Contents:** Invoice list (fee heads, amounts, due dates, status), all transactions (date, amount, Razorpay reference, status), total outstanding
**Filters:** Academic year, term, payment status (Paid/Unpaid/Overdue)
**Export:** PDF receipt per transaction; Excel summary on request

---

### RPT-PPT-003: Homework Completion Overview
**Purpose:** Parent monitors child's homework engagement across subjects
**Audience:** Parent
**Frequency:** On demand
**Contents:** Count of Total/Submitted/Pending/Overdue homework per subject for selected date range
**Filters:** Subject, date range, status
**Export:** Not required (in-portal view sufficient)

---

### RPT-PPT-004: Academic Progress Report
**Purpose:** Term-wise exam results with subject-wise marks and comparison to class average
**Audience:** Parent
**Frequency:** Per academic term (after school publishes)
**Contents:** Exam name, date, subject, marks_obtained, max_marks, percentage, grade, pass/fail, class average (if enabled), remarks
**Filters:** Academic term, subject
**Export:** PDF report card (official, school letterhead, principal signature line)
**Rules:** RPT only available after school admin publishes results for the term

---

### RPT-PPT-005: Consent Form Response Report (Admin)
**Purpose:** School admin tracks which parents have and have not responded to a consent form
**Audience:** School Admin (not parent)
**Frequency:** On demand
**Contents:** Per consent form: list of students (class, section), guardian name, response (Signed/Declined/Pending), signed_at
**Filters:** Consent form, class, section, response status
**Export:** Excel (for follow-up with unsigned parents)

---

### RPT-PPT-006: PTM Booking Summary (Admin)
**Purpose:** School admin views all bookings for a PTM event across teachers and time slots
**Audience:** School Admin, Teachers
**Frequency:** Per PTM event
**Contents:** PTM event name, date; teacher list with slots, bookings (parent name, child name, time, confirmation status)
**Filters:** PTM event, teacher, booking status
**Export:** PDF schedule printout per teacher

---

## 8. Future Enhancements

| ID | Enhancement | Priority | Rationale |
|---|---|---|---|
| ENH-PPT-001 | Homework calendar view (in addition to list): each date shows count of due items | P1 candidate | Better mental model of child's weekly workload |
| ENH-PPT-002 | Fee payment auto-reminders: push + SMS at 3 days, 1 day, and same day before fee due date | P1 candidate | Reduces late payments without manual school follow-up |
| ENH-PPT-003 | Attendance auto-prompt: 3+ consecutive absences trigger leave application nudge to parent | P2 | Reduces unaccounted absences |
| ENH-PPT-004 | Teacher message rate-limiting: max 1 message per subject per 24 hours (configurable per school) | P2 | Prevents teacher inbox flooding |
| ENH-PPT-005 | Re-authentication (OTP re-entry) before fee payment and document download | P1 candidate | High-value action security; mirrors banking UX |
| ENH-PPT-006 | Per-guardian API rate limiting (60 requests/minute) on all API endpoints | P1 candidate | Prevents data scraping; standard for self-service portals |
| ENH-PPT-007 | PWA service worker for offline caching of last-fetched attendance/timetable data | P2 | Supports parents in low-connectivity areas |
| ENH-PPT-008 | Native mobile app (React Native / Flutter) using the PPT REST API | Future (post-V2) | Separate initiative; API endpoints already designed for this |

---

## 9. Non-Functional Requirements

### 9.1 Performance

| NFR | Requirement | Threshold |
|---|---|---|
| NFR-PPT-001 | Dashboard load time with 4 linked children | < 3 seconds |
| NFR-PPT-002 | Attendance calendar render (full academic year) | < 2 seconds |
| NFR-PPT-003 | API response time (standard data queries) | < 500 ms |
| NFR-PPT-004 | Dashboard data queries | ≤ 5 batch queries (ParentDashboardService pattern) |
| NFR-PPT-005 | Non-real-time dashboard data cached | 5-minute TTL via Laravel Cache |
| NFR-PPT-006 | Today's attendance | Never cached; always live |

### 9.2 Security

| NFR | Requirement | Priority |
|---|---|---|
| NFR-PPT-007 | Every data endpoint enforces guardian→child ownership (Child Ownership Check) | P0 |
| NFR-PPT-008 | All portal traffic over HTTPS; HSTS header applied | P0 |
| NFR-PPT-009 | CSRF protection on all POST/PUT/DELETE routes (Laravel CSRF token) | P0 |
| NFR-PPT-010 | OTP rate-limiting: max 3 requests/hour/mobile; max 3 attempts/code; 30-min lockout | P0 |
| NFR-PPT-011 | Document download links expire after 24 hours (signed temporary URL) | P1 |
| NFR-PPT-012 | Razorpay signature verified server-side before any invoice update | P0 |
| NFR-PPT-013 | All parent actions logged to sys_activity_logs (view, payment, message, leave) | P1 |
| NFR-PPT-014 | Per-guardian API rate limiting (60 req/min) on all API endpoints | P1 |
| NFR-PPT-015 | EnsureTenantHasModule middleware applied to PPT route group | P1 |

### 9.3 Usability and Availability

| NFR | Requirement |
|---|---|
| NFR-PPT-016 | Mobile-first responsive design; all interactive elements ≥ 44px touch target |
| NFR-PPT-017 | PWA installable; offline home screen available |
| NFR-PPT-018 | Graceful degradation if dependent module is inactive — show "feature not available"; never a 500 error |
| NFR-PPT-019 | Absence push notification delivered within 5 minutes of teacher marking |
| NFR-PPT-020 | Fee reminder notification delivered within 2 minutes of trigger event |
| NFR-PPT-021 | Counsellor reports default-hidden; explicitly enabled by school (privacy-first default) |
| NFR-PPT-022 | Data isolated per school via stancl/tenancy database-per-tenant; no cross-tenant data leakage |

---

## 10. Gap Analysis Readiness Index

### 10.1 Coverage Table

| Requirement ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---|---|---|---|---|---|---|---|---|
| REQ-PPT-001 | Multi-Child Dashboard | P0 | [DASHBOARD] | ppt_parent_sessions | Yes | Yes | No | Yes |
| REQ-PPT-002 | OTP Passwordless Login | P0 | [WORKFLOW] | ppt_parent_sessions | Yes | Yes | Yes (SMS) | Yes |
| REQ-PPT-003 | Smart Notification Preferences | P0 | [CONFIGURATION][NOTIFICATION] | ppt_parent_sessions | Yes | Yes | No | Yes |
| REQ-PPT-004 | Teacher Messaging | P0 | [WORKFLOW][NOTIFICATION] | ppt_messages (MISSING) | Yes | Yes | Yes | Yes |
| REQ-PPT-005 | Fee Management & Online Payment | P0 | [WORKFLOW][INTEGRATION][NOTIFICATION] | None owned | Yes | Yes | Yes | Yes |
| REQ-PPT-006 | Attendance View | P0 | [DASHBOARD][REPORT] | None owned | Yes | Yes | Yes (absence) | Yes |
| REQ-PPT-007 | Homework Tracker | P1 | [DASHBOARD][REPORT] | None owned | Yes | No | Yes (overdue) | Yes |
| REQ-PPT-008 | Timetable View | P1 | [REPORT] | None owned | Yes | No | No | No |
| REQ-PPT-009 | Academic Results & Report Cards | P1 | [REPORT][WORKFLOW] | None owned | Yes | No | No | Yes |
| REQ-PPT-010 | Leave Application | P1 | [WORKFLOW][NOTIFICATION][APPROVAL] | ppt_leave_applications (MISSING) | Yes | Yes | Yes | Yes |
| REQ-PPT-011 | Digital Consent Forms | P1 | [WORKFLOW][NOTIFICATION] | ppt_consent_forms, ppt_consent_form_responses | Yes | No | Yes | Yes |
| REQ-PPT-012 | PTM Scheduling | P1 | [WORKFLOW][NOTIFICATION][APPROVAL] | None owned (Ptm module) | Yes | Yes | Yes | Yes |
| REQ-PPT-013 | Event Calendar & RSVP | P1 | [WORKFLOW][NOTIFICATION] | ppt_event_rsvps | Yes | No | Yes | Yes |
| REQ-PPT-014 | Health & HPC Reports | P1 | [REPORT][CONFIGURATION] | None owned | Yes | No | No | Yes |
| REQ-PPT-015 | Transport Tracking | P1 | [DASHBOARD][INTEGRATION] | None owned | Yes | No | No | No |
| REQ-PPT-016 | Document Vault & Requests | P1 | [WORKFLOW][INTEGRATION] | ppt_document_requests | Yes | No | Yes | Yes |
| REQ-PPT-017 | Notification Inbox & Circulars | P1 | [NOTIFICATION][DASHBOARD] | None owned | Yes | Yes | No | Yes |
| REQ-PPT-018 | Account Settings | P1 | [CONFIGURATION] | ppt_parent_sessions | Yes | Yes | No | No |
| REQ-PPT-019 | Hostel Information View | P2 | [DASHBOARD] | None owned | Yes | No | No | No |
| REQ-PPT-020 | Learning Hub | P2 | [DASHBOARD] | None owned | Yes | No | No | No |

### 10.2 Business Rule Coverage

| BR ID | Status | Notes |
|---|---|---|
| BR-PPT-001 | PARTIAL — ConsentFormPolicy exists; ParentChildPolicy MISSING | P0 gap |
| BR-PPT-002 | NOT STARTED | Requires ParentChildPolicy + ParentFeePaymentController enforcement |
| BR-PPT-003 | NOT STARTED | Requires ParentMessagePolicy (MISSING) |
| BR-PPT-004 | PARTIAL — StoreParentLeaveRequest exists; no backing table | P0 gap (missing migration) |
| BR-PPT-005 | NOT STARTED | Publish gate logic not confirmed in ParentResultController |
| BR-PPT-006 | NOT STARTED | Requires ParentHealthController query filter verification |
| BR-PPT-007 | NOT STARTED | Requires sys_school_settings lookup in ParentHealthController |
| BR-PPT-008 | NOT STARTED | NotificationPreferenceService absent |
| BR-PPT-009 | PARTIAL — ParentAccountController exists; logout device routes present | Token update logic unverified |
| BR-PPT-010 | DONE — ParentContextService implements active child DB storage | |
| BR-PPT-011 | PARTIAL — PayInitiateParentDocumentRequest exists; payment gate logic in ParentDocumentController unverified | |
| BR-PPT-012 | NOT STARTED — CRITICAL P0 gap | No global ownership check applied |
| BR-PPT-013 | NOT STARTED — AuthController for OTP absent | |
| BR-PPT-014 | PARTIAL — SignParentConsentFormRequest + DB unique constraint in DDL | Controller enforcement unverified |
| BR-PPT-015 | NOT STARTED — PtmSchedulingService absent | Race-condition guard not implemented |
| BR-PPT-016 | NOT STARTED | Capacity check logic in ParentEventController unverified |
| BR-PPT-017 | NOT STARTED | Event dispatch to attendance module not implemented |
| BR-PPT-018 | PARTIAL — PayCallbackParentDocumentRequest exists; idempotency enforcement in controller unverified | |
| BR-PPT-019 | PARTIAL — WithdrawParentLeaveRequest exists; status guard unverified | |
| BR-PPT-020 | NOT STARTED — CancelParentPtmRequest exists; time guard in controller unverified | |
| BR-PPT-021 | DONE — DDL v2 has no deleted_at on ppt_consent_form_responses | Design-level enforcement |
| BR-PPT-022 | DONE — stancl/tenancy database isolation | Platform-level enforcement |

### 10.3 Report Coverage

| RPT ID | Report | Status |
|---|---|---|
| RPT-PPT-001 | Child Attendance Summary | NOT STARTED |
| RPT-PPT-002 | Fee Ledger & Payment History | PARTIAL (views exist; PDF generation unverified) |
| RPT-PPT-003 | Homework Completion Overview | NOT STARTED |
| RPT-PPT-004 | Academic Progress Report (Report Card) | PARTIAL (result views exist; PDF/publish gate unverified) |
| RPT-PPT-005 | Consent Form Response Report (Admin) | NOT STARTED |
| RPT-PPT-006 | PTM Booking Summary (Admin) | NOT STARTED |

### 10.4 Totals

| Count | Value |
|---|---|
| Total REQs | 20 |
| P0 REQs | 6 |
| P1 REQs | 12 |
| P2 REQs | 2 |
| Total BRs | 22 |
| Total RPTs | 6 |
| Total ENHs | 8 |
| Screens documented | 38 (SCR-PPT-01 through SCR-PPT-38) |
| Workflows | 6 |
| FSMs | 6 |

---

# Section 2: Requirements Traceability Matrix (RTM)

| REQ-ID | Feature | BR refs | Key Screen(s) | Workflow | Report(s) | Code Status | Critical Gap |
|---|---|---|---|---|---|---|---|
| REQ-PPT-001 | Multi-Child Dashboard | BR-PPT-001, BR-PPT-010 | SCR-PPT-03, SCR-PPT-04 | — | — | PARTIAL (controller + views; ParentChildPolicy MISSING) | ParentChildPolicy |
| REQ-PPT-002 | OTP Passwordless Login | BR-PPT-013, BR-PPT-009 | SCR-PPT-01, SCR-PPT-02 | WF-1 | — | NOT STARTED | AuthController, OTP routes |
| REQ-PPT-003 | Notification Preferences | BR-PPT-008, BR-PPT-009 | SCR-PPT-22 | — | — | PARTIAL (views; service MISSING) | NotificationPreferenceService |
| REQ-PPT-004 | Teacher Messaging | BR-PPT-003, BR-PPT-001 | SCR-PPT-17–19 | — | — | NOT STARTED | ppt_messages table, MessageController, ParentMessagePolicy |
| REQ-PPT-005 | Fee Management & Payment | BR-PPT-002, BR-PPT-018, BR-PPT-012 | SCR-PPT-13–16 | WF-3 | RPT-PPT-002 | PARTIAL (controllers + views; ParentChildPolicy MISSING) | ParentChildPolicy, payment service |
| REQ-PPT-006 | Attendance View | BR-PPT-001, BR-PPT-012 | SCR-PPT-05–06 | — | RPT-PPT-001 | PARTIAL (controller + views; ownership check MISSING) | ParentChildPolicy |
| REQ-PPT-007 | Homework Tracker | BR-PPT-001 | SCR-PPT-08–09 | — | RPT-PPT-003 | PARTIAL | ParentChildPolicy |
| REQ-PPT-008 | Timetable View | BR-PPT-001 | SCR-PPT-07 | — | — | PARTIAL | — |
| REQ-PPT-009 | Academic Results & Report Cards | BR-PPT-005, BR-PPT-001 | SCR-PPT-10–12 | — | RPT-PPT-004 | PARTIAL (views; publish gate unverified) | Publish gate, DomPDF report card |
| REQ-PPT-010 | Leave Application | BR-PPT-004, BR-PPT-017, BR-PPT-019 | SCR-PPT-23–25 | WF-2 | — | PARTIAL — NO BACKING TABLE | ppt_leave_applications migration |
| REQ-PPT-011 | Digital Consent Forms | BR-PPT-014, BR-PPT-021 | SCR-PPT-26–27 | WF-5 | RPT-PPT-005 | PARTIAL (DDL done; controller wiring unverified) | — |
| REQ-PPT-012 | PTM Scheduling | BR-PPT-015, BR-PPT-020 | SCR-PPT-28–29 | WF-6 | RPT-PPT-006 | PARTIAL (controller; PtmSchedulingService MISSING) | PtmSchedulingService, concurrency guard |
| REQ-PPT-013 | Event Calendar & RSVP | BR-PPT-016, BR-PPT-001 | SCR-PPT-30–31 | — | — | PARTIAL (DDL done; EventEngine FK unclear) | Event source FK |
| REQ-PPT-014 | Health & HPC Reports | BR-PPT-006, BR-PPT-007 | SCR-PPT-32–33 | — | — | PARTIAL (controller; visibility gates unverified) | — |
| REQ-PPT-015 | Transport Tracking | BR-PPT-001 | SCR-PPT-34 | — | — | PARTIAL (controller + view) | — |
| REQ-PPT-016 | Document Vault & Requests | BR-PPT-011, BR-PPT-022, BR-PPT-001 | SCR-PPT-35–37 | WF-4 | — | PARTIAL (DDL done; fee gate unverified) | Signed URL generation, fee gate |
| REQ-PPT-017 | Notification Inbox | BR-PPT-001 | SCR-PPT-20–21 | — | — | PARTIAL (controller + views) | — |
| REQ-PPT-018 | Account Settings | BR-PPT-009, BR-PPT-010 | SCR-PPT-38 | — | — | PARTIAL (controller + views; FormRequests exist) | — |
| REQ-PPT-019 | Hostel Info | BR-PPT-001 | hostel/index view | — | — | PARTIAL (controller + view; Hostel module dep.) | — |
| REQ-PPT-020 | Learning Hub | BR-PPT-001 | learning/index view | — | — | PARTIAL (controller + view) | — |

---

# Section 3: Business Rules Register + Conditions Catalog + Validation

The Business Rules Register (22 rules) is defined in FRD Section 4 above.

## Requirement Conditions Catalog

| Condition ID | Entity / Field | Condition (business statement) | Type | Trigger | On-Violation Behaviour |
|---|---|---|---|---|---|
| BR-PPT-001 | Guardian→Child access | Guardian must have at least one active linked child with can_access_parent_portal=1 | Permission | Every data request | HTTP 403; redirect to no-access screen |
| BR-PPT-002 | Fee Invoice | Invoice's student_id must match parent's active linked child | Permission | Fee payment initiation | HTTP 403; log IDOR attempt |
| BR-PPT-003 | Teacher recipient | Teacher must be assigned to at least one subject in the active child's class-section | Permission | Message compose | Validation error: "Teacher not available for your child" |
| BR-PPT-004 | Leave from_date | from_date must be >= tomorrow's date | Validation | Leave form submission | Validation error: "Leave start date must be a future date" |
| BR-PPT-005 | Report card | Report card PDF available only after school admin publishes results for the term | Workflow | Report card download click | Informational: "Results not yet published for this term" |
| BR-PPT-006 | Health record | parent_visible = 1 on the health record | Permission | Health report view | Record excluded from results (not shown; no error) |
| BR-PPT-007 | Counsellor report | sys_school_settings.parent_counsellor_report_visibility = 1 | Permission | Counsellor report view | Section hidden; no error |
| BR-PPT-008 | Notification timing | Notification type is not AbsenceAlert or EmergencyAlert during quiet hours | Workflow | Notification dispatch | Buffer notification; dispatch after quiet_hours_end |
| BR-PPT-013 | OTP attempts | Max 3 attempts per OTP code; max 5 failures in 30 minutes | Validation | OTP entry | After 3 OTP attempts: "OTP invalid, request a new one"; after 5 failures: "Account locked for 30 minutes" |
| BR-PPT-013 | OTP requests | Max 3 OTP requests per mobile per hour | Validation | OTP request | Error: "Too many OTP requests. Try again in X minutes." |
| BR-PPT-014 | Consent double-sign | Parent has not already signed this form for this child | Validation | Consent form sign | Error: "You have already responded to this consent form" |
| BR-PPT-014 | Consent deadline | Current datetime is before form's deadline | Validation | Consent form sign | Error: "This consent form is closed" |
| BR-PPT-015 | PTM slot availability | Slot must still be unbooked at time of booking transaction | Concurrency | PTM slot book | Error: "This slot was just taken. Please choose another." |
| BR-PPT-016 | Volunteer capacity | Current signup count < max_slots for the volunteer role | Concurrency | Event volunteer signup | Error: "This volunteer role is full. Please select another." |
| BR-PPT-018 | Payment idempotency | Razorpay payment_id must not already exist in fin_transactions | Concurrency | Payment webhook | Webhook silently acknowledged (200); no second credit |
| BR-PPT-019 | Leave withdrawal | Leave application status must be Pending | Workflow | Leave withdraw | Error: "This application has already been reviewed and cannot be withdrawn." |
| BR-PPT-020 | PTM cancellation time | Cancellation requested more than 1 hour before PTM start | Validation | PTM cancel | Error: "Bookings cannot be cancelled less than 1 hour before the meeting." |
| BR-PPT-021 | Consent response immutability | ppt_consent_form_responses must not be updated or deleted after creation | Workflow | Any modification | Operation blocked; DB design enforcement (no deleted_at) |

## Validation and Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty / Null | Concurrency Case | Expected Behaviour |
|---|---|---|---|---|---|---|
| Leave from_date | 2026-07-05 (future) | 2026-06-29 (today) | 2026-06-30 (tomorrow) = valid | Null → required error | — | Reject today or past; accept tomorrow+ |
| Leave reason | "Child has fever and doctor advised rest" (21 chars) | "Sick" (4 chars) | 20 chars exactly = valid | Null → required error | — | Min 20 chars enforced |
| OTP entry | "847293" (correct, < 10 min) | "847293" (expired) | 10 min expiry exact | Empty → required | Two parents share same mobile | Lock after 5 failures; treat as invalid |
| Fee payment - invoice ownership | Invoice for active child | Invoice for sibling not linked to this parent | invoice.student_id = active child | Null invoice ID → 404 | Two parents paying same invoice | First succeeds; second gets idempotency guard |
| Consent form signing | signer_name = "Ramesh Sharma" (14 chars ≥ 3) | signer_name = "R" (1 char) | 3 chars = valid minimum | signer_name null → required | Two parents of same child sign simultaneously | Both succeed; each creates own response record (unique key on form+student+guardian means two different guardians can both sign) |
| PTM slot booking | Slot with 0 bookings | Slot already booked by another parent | Capacity = 1 (only 1 parent per slot) | Null slot ID → 404 | Two parents click book same slot simultaneously | DB SELECT...FOR UPDATE; only one succeeds; other gets "slot just taken" |
| Volunteer sign-up | Role with 2/5 slots filled | Role with 5/5 slots filled | max_slots exactly reached | Null event_id → 404 | Two parents submit simultaneously at 4/5 | One succeeds (5/5); other blocked |
| Document request reason | "Need a Bonafide for bank account opening" (42 chars) | "Need doc" (8 chars) | 20 chars = valid minimum | Null → required error | — | Min 20 chars enforced |
| Report card download | Term with published=1 | Term with published=0 | publish toggle changed during download | No results for term → empty state | — | Show "not published" gate; no PDF generation |
| Child ownership check | Parent accessing own child's data | Parent submits student_id of unlinked child | student_id is linked but can_access=0 | Null student_id → validation error | — | HTTP 403; log IDOR attempt |

---

# Section 4: Process Flows + FSM Catalog

## Process Flows

The 6 key workflows are fully documented in FRD Section 6 above. Key summary:

| Workflow | Trigger | End States | Critical Path |
|---|---|---|---|
| WF-1: OTP Login | Parent requests OTP | Authenticated / OTP_Locked | Rate limiter → OTP dispatch → Verify → Portal home |
| WF-2: Leave Application | Parent submits leave | Approved / Rejected / Withdrawn | Submit → Teacher notified → Decision → Attendance update (on Approved) |
| WF-3: Fee Payment | Parent initiates payment | Invoice=Paid / Invoice=Unpaid (unchanged) | Razorpay order → Hosted checkout → Webhook verify → Invoice update + SMS |
| WF-4: Document Request | Parent submits request | Completed / Rejected | Request → Admin processes → Fee gate (optional) → Download link |
| WF-5: Consent Form | Parent views unsigned form | Signed / Declined | Read form → Sign/Decline → Immutable record + PDF |
| WF-6: PTM Slot Booking | Parent selects slot | Booked / Slot_Released | Select → DB transaction → Confirm or "slot taken" |

## FSM Catalog

### FSM-1: OTP Login States

| From State | Event | Guard | To State | Side-Effects |
|---|---|---|---|---|
| Unauthenticated | Request OTP | Rate limit < 3/hour/mobile | OTP_Sent | OTP dispatched via SMS |
| Unauthenticated | Request OTP | Rate limit >= 3/hour/mobile | Unauthenticated | Error: retry timer shown |
| OTP_Sent | Enter valid OTP | OTP not expired; attempts < 3 | Authenticated | Device token registered; session created |
| OTP_Sent | Enter invalid OTP | Attempts < 3 | OTP_Sent | Attempt counter incremented |
| OTP_Sent | Enter invalid OTP | Attempts = 5 cumulative failures | OTP_Locked | 30-minute lockout applied |
| OTP_Sent | OTP expires | — | Unauthenticated | Resend prompt shown |
| OTP_Locked | 30 minutes elapsed | — | Unauthenticated | Lock lifted |
| Authenticated | First login | No password set | Password_Setup | Force password creation |
| Authenticated | Returning login | Password exists | Portal_Home | Dashboard loaded |

**Illegal transitions:** OTP_Locked → Authenticated (must wait 30 min); Authenticated → OTP_Locked (cannot lock an active session).

---

### FSM-2: Leave Application States

| From State | Event | Guard | To State | Side-Effects |
|---|---|---|---|---|
| (none) | Parent submits | from_date >= tomorrow; reason >= 20 chars | Pending | Teacher notified; application_number generated |
| Pending | Teacher approves | — | Approved | Attendance event dispatched; parent notified |
| Pending | Teacher rejects | reviewer_notes required | Rejected | Parent notified with rejection reason |
| Pending | Parent withdraws | — | Withdrawn | Teacher notified of withdrawal |
| Approved | — | — | (terminal) | Attendance already updated; cannot un-approve |
| Rejected | — | — | (terminal) | Parent notified; new application may be submitted |
| Withdrawn | — | — | (terminal) | |

**Illegal transitions:** Approved → Withdrawn; Rejected → Withdrawn; Withdrawn → Pending.

---

### FSM-3: Fee Payment States

| From State | Event | Guard | To State | Side-Effects |
|---|---|---|---|---|
| Unpaid / Overdue | Parent initiates payment | is_fee_payer=1; child ownership verified | Payment_Initiated | Razorpay order created |
| Payment_Initiated | Razorpay success webhook | Signature verified; payment_id unique | Paid | fin_transactions created; SMS receipt; PDF generated |
| Payment_Initiated | Razorpay failure / cancel | — | Unpaid/Overdue (unchanged) | Parent can retry |
| Paid | Webhook replay | payment_id already exists | Paid (unchanged) | Webhook 200'd; no second credit |

**Terminal state:** Paid (invoices cannot be un-paid by parent action). **Illegal:** Paid → Unpaid from parent portal.

---

### FSM-4: Document Request States

| From State | Event | Guard | To State | Side-Effects |
|---|---|---|---|---|
| (none) | Parent submits | reason >= 20 chars; child ownership | Pending | request_number generated; admin notified |
| Pending | Admin starts processing | — | Processing | Parent notified |
| Processing | Admin uploads; fee = 0 | — | Completed | Parent notified; 24-hr signed URL generated |
| Processing | Admin uploads; fee > 0 | — | Ready | Parent notified to pay |
| Ready | Parent pays | fee_required > 0; payment verified | Completed | Download URL generated; parent notified |
| Pending / Processing / Ready | Admin rejects | admin_notes required | Rejected | Parent notified with rejection reason |

**Illegal transitions:** Completed → any other state (terminal). Ready → Completed without payment.

---

### FSM-5: Consent Form Response States

| From State | Event | Guard | To State | Side-Effects |
|---|---|---|---|---|
| Unsigned | Parent signs | Within deadline; not already signed; signer_name valid | Signed | Immutable record created (signed_at + IP); PDF generated; school admin notified |
| Unsigned | Parent declines | Within deadline; not already responded; decline_reason provided | Declined | Immutable record created; school admin notified |
| Unsigned | Deadline passes | — | Closed | No action possible; form shows as "Closed" |
| Signed | — | — | (immutable terminal) | Cannot be updated, cancelled, or deleted |
| Declined | — | — | (immutable terminal) | |
| Closed | — | — | (terminal) | Read-only view only |

**Illegal transitions:** Any → deletion (no deleted_at column). Signed → Unsigned. Declined → Signed.

---

### FSM-6: PTM Slot Booking States

| From State | Event | Guard | To State | Side-Effects |
|---|---|---|---|---|
| Available | Parent attempts booking | SELECT...FOR UPDATE; slot still available | Booked | Confirmation sent to parent + teacher; 24h + 1h reminders scheduled |
| Available | Concurrent booking (race) | Slot taken before transaction commits | Available | Error: "Slot just taken" shown to second parent |
| Booked | Parent cancels | >= 1 hour before PTM | Available | Slot released; teacher notified |
| Booked | Parent cancels | < 1 hour before PTM | Booked (unchanged) | Error: "Cannot cancel within 1 hour of meeting" |
| Booked | PTM time passes | — | Completed (terminal) | No action possible |

---

# Section 5: Data Dictionary (Business View) + Cross-Module Dependency Map

## Data Dictionary — PPT Owned Entities (Business View)

Entries for all 5 confirmed PPT tables are documented in FRD Section 5.1 above.

**Summary table:**

| Entity | Table | Record Volume | Privacy | Key Constraints |
|---|---|---|---|---|
| Portal Session | ppt_parent_sessions | 3–5 per guardian (multi-device) | Internal | UNIQUE(guardian_id, device_token_fcm) |
| Consent Form | ppt_consent_forms | 10–50 per school per year | Internal | Soft-delete (deleted_at); deadline gating |
| Consent Form Response | ppt_consent_form_responses | Forms × students × parents | Confidential (signer name + IP) | UNIQUE(form, student, guardian); NO deleted_at |
| Event RSVP | ppt_event_rsvps | Events × guardians | Internal | UNIQUE(event_id, guardian_id); NO deleted_at |
| Document Request | ppt_document_requests | 10–30 per student lifetime | Internal | UNIQUE(request_number); UNIQUE(payment_reference) |

**Planned but unbuilt (P0 gaps):**

| Entity | Planned Table | Priority | Schema Source |
|---|---|---|---|
| Teacher Message | ppt_messages | P0 | V2 §5.2 (FULLTEXT idx on subject+body; INDEX on thread_id+created_at) |
| Leave Application | ppt_leave_applications | P0 | V2 §5.2 (ENUM status; INDEX on student_id+status; soft-delete) |

## Cross-Module Dependency Map

### Inbound Dependencies (PPT reads from)

| Source Module | Data / Entity | Why PPT Reads It |
|---|---|---|
| StudentProfile | std_students, std_guardians, std_student_guardian_jnt | Core parent→child FK chain; can_access_parent_portal flag |
| StudentProfile | std_health_records | Health visibility check |
| SystemConfig | sys_users | Authentication; teacher lookup for messaging |
| SystemConfig | sys_media | Document files; message attachments |
| SystemConfig | sys_school_settings | Feature visibility flags (counsellor reports, class average, etc.) |
| StudentFee | fin_fee_invoices, fin_fee_installments | Outstanding fees display |
| StudentFee | fin_transactions | Payment history |
| SmartTimetable | tt_timetable_cells, tt_published_timetables | Child's weekly timetable |
| TimetableFoundation | Academic terms, period sets | Term selector; timetable context |
| LmsHomework | hmw_assignments, hmw_submissions | Homework tracker data |
| LmsExam | exm_results, exm_report_cards | Results + report card publish status |
| Hpc | hpc_health_profiles, hpc_physical_assessments, hpc_counsellor_reports | Health/HPC reports (gated) |
| Transport | tpt_routes, tpt_vehicles, tpt_student_route_jnt, tpt_stops | Bus info + live status |
| Notification | ntf_notifications, ntf_circulars | Notification inbox |
| SchoolSetup | sch_classes, sch_sections, sch_holidays | Class context; holiday calculation for leave days |
| Hostel | hst_allotments, hst_rooms, hst_buildings | Child hostel allocation (REQ-PPT-019) |
| LmsQuiz / LmsQuests / LmsExam | Attempt tables | Learning hub activity summary (REQ-PPT-020) |
| EventEngine | Event records | ppt_event_rsvps.event_id FK target |

### Outbound Dependencies (PPT writes to or triggers)

| Target Module | Mechanism | What PPT Feeds |
|---|---|---|
| StudentFee | Direct write on payment success | fin_transactions record created; fin_fee_invoices status updated to Paid |
| Notification | Event dispatch / direct notification | Absence alert acknowledgement; leave decision; PTM confirmation; consent reminder; document status |
| Attendance module | Event dispatch on leave approval | Leave dates marked as Leave status in attendance records |
| Payment module | Razorpay order creation (outbound API) | Fee payment initiation; document fee payment |
| Ptm module | Direct DB write on slot booking | ptm_bookings record created/deleted |
| sys_activity_logs | Direct write | All parent actions logged for audit |
| sys_media | Direct write (document uploads) | Fulfilled document files from admin; message attachments |

---

# Section 6: NFR Catalog + Risk Register

## NFR Catalog

| NFR-ID | Category | Requirement | Threshold |
|---|---|---|---|
| NFR-PPT-001 | Performance | Dashboard load (4 children) | < 3 seconds |
| NFR-PPT-002 | Performance | Attendance calendar (full year) | < 2 seconds |
| NFR-PPT-003 | Performance | API endpoint response | < 500 ms |
| NFR-PPT-004 | Performance | Dashboard data aggregation queries | ≤ 5 queries (batch service) |
| NFR-PPT-005 | Performance | Non-realtime dashboard cache TTL | 5 minutes |
| NFR-PPT-006 | Performance | Absence alert push delivery | < 5 minutes after teacher marks absent |
| NFR-PPT-007 | Security | Child ownership enforcement | 100% of data endpoints — zero exceptions |
| NFR-PPT-008 | Security | HTTPS + HSTS | All portal traffic; no mixed content |
| NFR-PPT-009 | Security | CSRF protection | All POST/PUT/DELETE routes |
| NFR-PPT-010 | Security | OTP rate limiting | Max 3 OTPs/hour/mobile; 5 failures → 30-min lockout |
| NFR-PPT-011 | Security | Document download link expiry | 24-hour signed URL |
| NFR-PPT-012 | Security | Razorpay signature verification | Server-side before any invoice update |
| NFR-PPT-013 | Security | Audit logging | All parent actions in sys_activity_logs |
| NFR-PPT-014 | Security | API rate limiting | 60 req/min per guardian |
| NFR-PPT-015 | Security | Module feature gating | EnsureTenantHasModule on PPT routes |
| NFR-PPT-016 | Usability | Mobile-first responsive design | All elements ≥ 44px touch target |
| NFR-PPT-017 | Usability | Progressive Web App | Installable; offline home screen |
| NFR-PPT-018 | Availability | Graceful module degradation | "Feature not available" — never 500 error |
| NFR-PPT-019 | Privacy | Counsellor report default | OFF (parent_counsellor_report_visibility = 0 default) |
| NFR-PPT-020 | Privacy | Medical record visibility | Per-record parent_visible flag; default = school policy |
| NFR-PPT-021 | Privacy | Consent form response | Immutable after creation; no deletion |
| NFR-PPT-022 | Scalability | Multi-tenant isolation | stancl/tenancy database-per-tenant; no cross-school leakage |
| NFR-PPT-023 | PDF | Report card / receipt format | DomPDF, A4, school letterhead |

## Risk Register

| RISK-ID | Risk | Category | Likelihood | Impact | Mitigation | Owner | Early Warning |
|---|---|---|---|---|---|---|---|
| RISK-PPT-001 | ParentChildPolicy absent — IDOR enables cross-child data access | Security | HIGH | HIGH | Build and apply policy before any testing or production access | Developer | Any data endpoint returns data for unlinked student |
| RISK-PPT-002 | ppt_leave_applications table missing — LeaveController crashes at runtime | Technical | HIGH | HIGH | Create migration immediately; add to sprint 1 | DB Architect | HTTP 500 on any leave route |
| RISK-PPT-003 | ppt_messages absent — messaging deferred but no formal decision; parents expect this feature | Business | MEDIUM | HIGH | Decide: (a) build ppt_messages, or (b) integrate CommonChat; document integration contract | Tech Lead | Module launch without messaging prompts parent complaints |
| RISK-PPT-004 | 0 tests — security (IDOR, payment idempotency) correctness unverifiable | Quality | HIGH | HIGH | Write 33 V2-specified test scenarios before staging | QA / Developer | Any failed payment or 403 in production |
| RISK-PPT-005 | OTP login not scaffolded — P0 feature absent for launch | Technical | HIGH | HIGH | Build OTP AuthController and rate-limiter as priority sprint 1 | Developer | Login page missing OTP option |
| RISK-PPT-006 | PtmSchedulingService absent — double-booking race condition possible | Concurrency | MEDIUM | MEDIUM | Build service with SELECT...FOR UPDATE pattern; add concurrency test | Developer | Two parents report same PTM slot booked |
| RISK-PPT-007 | EventEngine FK in ppt_event_rsvps has no DB constraint — referential integrity gap | Technical | MEDIUM | MEDIUM | Confirm canonical event table; add FK or polymorphic constraint | DB Architect | Orphaned RSVPs after event deletion |
| RISK-PPT-008 | Razorpay webhook idempotency not confirmed in controller code | Security | MEDIUM | HIGH | Verify payment_id uniqueness check in ParentFeePaymentController; add test | Developer | Double-payment complaints |
| RISK-PPT-009 | NotificationPreferenceService absent — quiet hours not enforced | UX | MEDIUM | MEDIUM | Build service; wire to notification dispatch layer | Developer | Parents receive notifications at night |

---

# Section 7: Prioritization + Effort Estimation

## MoSCoW Prioritization

### Must Have (P0 — Launch Blockers)
| REQ | Feature |
|---|---|
| REQ-PPT-001 | Multi-Child Dashboard |
| REQ-PPT-002 | OTP Passwordless Login |
| REQ-PPT-003 | Smart Notification Preferences |
| REQ-PPT-004 | Teacher Messaging (or CommonChat integration) |
| REQ-PPT-005 | Fee Management & Online Payment |
| REQ-PPT-006 | Attendance View |

Plus foundational prerequisites not in REQ list:
- ParentChildPolicy (IDOR prevention) — required before any P0 REQ is complete
- ppt_leave_applications migration

### Should Have (P1 — Release 1)
REQ-PPT-007 through REQ-PPT-018 (12 requirements covering Homework, Timetable, Results, Leave, Consent, PTM, Events, Health, Transport, Documents, Notifications, Account Settings)

### Could Have (P2 — Release 2)
REQ-PPT-019 (Hostel View), REQ-PPT-020 (Learning Hub), ENH-PPT-001 through ENH-PPT-007

### Won't Have (this release)
ENH-PPT-008 (Native mobile app), video calling, parent-to-parent messaging

## Effort Estimation and Sprint Task Breakdown

### Foundation Sprint (Pre-P0) — ~30 hours

| # | Task | Type | Effort (h) | Depends On |
|---|---|---|---|---|
| T-01 | Build ParentChildPolicy (guardian→student ownership verification) | Backend | 4 | StudentProfile models |
| T-02 | Apply ParentChildPolicy to all 21 web controllers (every data method) | Backend | 6 | T-01 |
| T-03 | Create ppt_leave_applications migration + ParentLeaveApplication model | Schema + Backend | 4 | DDL spec V2 §5.2 |
| T-04 | Build OTP AuthController (send OTP, verify OTP, rate limiter, lockout FSM) | Backend | 8 | SMS gateway config |
| T-05 | Build ParentDashboardService (batch aggregator, ≤5 queries for all widgets) | Backend | 6 | T-01, StudentProfile, StudentFee, LmsHomework, LmsExam |
| T-06 | Add EnsureTenantHasModule to PPT route group | Backend | 2 | — |

### Sprint 1 — P0 Features (~60 hours)

| # | Task | Type | Effort (h) | Depends On |
|---|---|---|---|---|
| T-07 | OTP login views + flow integration (SCR-PPT-01, 02) | Frontend | 6 | T-04 |
| T-08 | Dashboard integration with ParentDashboardService (SCR-PPT-03, 04) | Backend + Frontend | 8 | T-05 |
| T-09 | Attendance view (calendar + subject-wise) with absence alert hook (SCR-PPT-05, 06) | Backend + Frontend | 8 | T-01, T-02 |
| T-10 | Fee management view + Razorpay hosted checkout + webhook (SCR-PPT-13–16) | Backend + Integration | 10 | T-01, Payment module |
| T-11 | Build NotificationPreferenceService + quiet hours buffering | Backend | 6 | ppt_parent_sessions |
| T-12 | Decide ppt_messages vs CommonChat; implement teacher messaging | Backend | 12 | T-01 (decision-dependent) |
| T-13 | DomPDF wiring for fee receipt (fees/invoice-pdf.blade.php) | Backend | 4 | T-10 |
| T-14 | Write 10 P0 Pest tests (IDOR, payment idempotency, OTP rate limit, child switch) | Testing | 6 | T-01–T-13 |

### Sprint 2 — P1 Academics & Communication (~55 hours)

| # | Task | Type | Effort (h) | Depends On |
|---|---|---|---|---|
| T-15 | Timetable view (SCR-PPT-07) | Backend + Frontend | 4 | SmartTimetable integration |
| T-16 | Homework tracker (SCR-PPT-08, 09) | Backend + Frontend | 6 | LmsHomework integration |
| T-17 | Academic results view + report card download gate + DomPDF (SCR-PPT-10–12) | Backend + Frontend | 10 | LmsExam, MarksheetGeneration |
| T-18 | Leave application full flow (SCR-PPT-23–25) using ppt_leave_applications | Backend + Frontend | 8 | T-03, T-01 |
| T-19 | PTM scheduling + PtmSchedulingService (concurrency guard) (SCR-PPT-28, 29) | Backend | 10 | Ptm module integration |
| T-20 | Consent form view + sign/decline + PDF (SCR-PPT-26, 27) | Backend + Frontend | 6 | ppt_consent_forms, ppt_consent_form_responses |
| T-21 | Write 12 P1 Pest tests | Testing | 11 | T-15–T-20 |

### Sprint 3 — P1 Portal Completion (~40 hours)

| # | Task | Type | Effort (h) | Depends On |
|---|---|---|---|---|
| T-22 | Event calendar + RSVP (resolve EventEngine FK) (SCR-PPT-30, 31) | Backend + Frontend | 8 | EventEngine clarification |
| T-23 | Health reports view (gated) (SCR-PPT-32, 33) | Backend + Frontend | 6 | HPC module |
| T-24 | Transport info view (SCR-PPT-34) | Backend + Frontend | 4 | Transport module |
| T-25 | Document vault + requests + fee gate (SCR-PPT-35–37) | Backend + Frontend | 10 | T-01, Payment module |
| T-26 | Notification inbox + preferences UI (SCR-PPT-20–22) | Backend + Frontend | 6 | Notification module |
| T-27 | Account settings full (profile, password, devices, language) (SCR-PPT-38) | Backend + Frontend | 6 | ppt_parent_sessions |

**Estimated Total:** ~185 hours to full P0+P1 completion. Assumes ParentChildPolicy done first, DDL gaps resolved, Ptm + EventEngine integration contracts defined.

---

# Section 8: User Stories + Reporting & KPI Spec

## User Stories (P0 Requirements)

### US-PPT-001 — Multi-Child Dashboard (REQ-PPT-001)
**Priority:** P0 | **REQ ref:** REQ-PPT-001
As a Parent with two enrolled children, I want to see a unified dashboard showing both children's snapshots and switch between them instantly, so that I can monitor each child's school status without logging out or navigating to separate accounts.

**Acceptance Criteria (Gherkin):**

Scenario: Happy path — parent with two children views dashboard
Given I am logged in as a Parent with children Aarav (Class 7A) and Priya (Class 5B)
When I open the portal dashboard
Then I see two child summary cards showing name, class-section, and today's attendance status
And the first child (or last active child) is shown as the active child with a detailed snapshot

Scenario: Switch active child
Given I am viewing Aarav's data on the dashboard
When I click Priya's child card
Then all data on the page refreshes to show Priya's attendance, fees, and homework
And ppt_parent_sessions.active_student_id is updated to Priya's student ID

Scenario: Empty state — no linked children
Given I am a Parent with no linked children having can_access_parent_portal = 1
When I open the portal
Then I see a clear empty state with a "Contact your school" message rather than an error

Scenario: Permission denied — accessing another child's data
Given I am a Parent linked to only Aarav
When I submit a request with student_id set to a different student's ID
Then I receive a 403 response and the attempt is logged in the audit log

**Definition of Done:** Dashboard loads ≤3 sec; active child persists after refresh; 0 data from unlinked students visible.

---

### US-PPT-002 — OTP Login (REQ-PPT-002)
**Priority:** P0 | **REQ ref:** REQ-PPT-002
As a Parent, I want to log in with a one-time code sent to my mobile number without needing to remember a password, so that I can access the portal conveniently even if I forget my credentials.

**Acceptance Criteria (Gherkin):**

Scenario: Successful OTP login
Given my mobile number is registered as a parent
When I enter my mobile number and request an OTP
Then I receive a 6-digit code on my mobile within 30 seconds
And on entering the correct code I am taken to the dashboard

Scenario: Expired OTP
Given I received an OTP 11 minutes ago
When I enter the OTP code
Then I see "This OTP has expired. Please request a new one."

Scenario: Account lockout
Given I have entered incorrect OTPs 5 times in 30 minutes
When I try to log in again
Then I see "Your account is temporarily locked for 30 minutes."

Scenario: OTP rate limit
Given I have requested 3 OTPs in the last 60 minutes
When I request another OTP
Then I see "Too many OTP requests. Try again in X minutes."

**Definition of Done:** OTP delivered < 30s; lockout applied after 5 failures; rate limit enforced; device token registered on login.

---

### US-PPT-003 — Notification Preferences (REQ-PPT-003)
**Priority:** P0 | **REQ ref:** REQ-PPT-003
As a Parent, I want to control which notifications I receive and set quiet hours, so that I am informed about important school events without being disturbed at night.

**Acceptance Criteria (Gherkin):**

Scenario: Disable SMS for fee reminders
Given I disable SMS channel for FeeReminder in my preferences
When the school triggers a fee reminder
Then I do NOT receive an SMS
But I DO receive an in-app notification

Scenario: Quiet hours buffer
Given I have quiet hours set from 22:00 to 07:00
When a non-urgent notification is dispatched at 23:00
Then it is NOT delivered immediately
And it is delivered at 07:00

Scenario: Urgent bypass
Given I have quiet hours set from 22:00 to 07:00
When my child is marked absent at 08:30 (after quiet hours end)
Then an AbsenceAlert push is delivered within 5 minutes regardless

---

### US-PPT-005 — Fee Payment (REQ-PPT-005)
**Priority:** P0 | **REQ ref:** REQ-PPT-005
As a Parent with fee_payer permission, I want to pay my child's school fees online in one click, so that I can settle dues without visiting the school.

**Acceptance Criteria (Gherkin):**

Scenario: Successful online fee payment
Given I can see an unpaid invoice for my child
When I select the invoice and click Pay
Then Razorpay hosted checkout opens within 3 seconds
And on completing UPI payment, the invoice status changes to Paid
And I receive an SMS receipt within 1 minute

Scenario: Cross-child payment blocked
Given I am a parent linked only to Aarav
When I attempt to pay an invoice with a student_id belonging to another student
Then I receive a 403 response

Scenario: Webhook replay idempotency
Given a Razorpay webhook for payment_id "pay_123" has already been processed
When the same webhook fires again with payment_id "pay_123"
Then the invoice is NOT credited a second time

---

### US-PPT-010 — Leave Application (REQ-PPT-010)
**Priority:** P0 | **REQ ref:** REQ-PPT-010
As a Parent, I want to apply for my child's leave online and track the class teacher's decision, so that the school is formally informed and leave dates are correctly marked in attendance.

**Acceptance Criteria (Gherkin):**

Scenario: Successful leave submission
Given my child is in Class 7A with teacher assigned
When I submit a leave for 2026-07-05 to 2026-07-06 with reason "Family function (20+ chars)"
Then the leave application is created with status Pending
And the class teacher receives a notification within 2 minutes

Scenario: Past date rejected
Given today is 2026-06-29
When I submit a leave with from_date = 2026-06-29
Then I see "Leave start date must be a future date"

Scenario: Teacher approves → attendance updated
Given my child has a Pending leave application for 2026-07-05 to 2026-07-06
When the class teacher approves the application
Then the leave status shows Approved in my portal
And 2026-07-05 and 2026-07-06 show as Leave (blue) in the attendance calendar

---

## Reporting and KPI Specification

| KPI | Definition | Source | Target | Cadence |
|---|---|---|---|---|
| Portal Adoption Rate | % of guardian accounts that log in at least once per month | ppt_parent_sessions.last_active_at | > 60% within 6 months of launch | Monthly |
| Fee Online Payment Rate | % of fee payments made via portal vs total receipts | fin_transactions (source=portal vs manual) | > 40% within 6 months | Monthly |
| Leave Application Approval Time | Average time from submission to class teacher decision | ppt_leave_applications (created_at → reviewed_at) | < 24 hours | Weekly |
| Consent Form Completion Rate | % of consent form responses received vs forms sent | ppt_consent_form_responses / (forms × students) | > 80% before deadline | Per event |
| PTM Slot Utilisation | % of PTM slots booked vs total available | ptm_bookings / ptm_teacher_slots | > 70% per PTM event | Per event |
| Push Notification Delivery | % of dispatched push notifications delivered (FCM success rate) | FCM delivery reports | > 95% | Weekly |

---

# Section 9: Feature Specification (Screen Inventory)

## Full Screen List (38 Screens)

| SCR-ID | Screen Name | Route | Primary Controller@Method | Views | FR Ref | Code Status |
|---|---|---|---|---|---|---|
| SCR-PPT-01 | Login (OTP / Password) | ppt.login | AuthController@login | auth/login | REQ-PPT-002 | NOT STARTED |
| SCR-PPT-02 | OTP Verification | ppt.otp.verify | AuthController@verifyOtp | auth/otp-verify | REQ-PPT-002 | NOT STARTED |
| SCR-PPT-03 | Dashboard | parent-portal.dashboard | ParentDashboardController@index | dashboard/index | REQ-PPT-001 | PARTIAL |
| SCR-PPT-04 | Child Switcher | parent-portal.children | ParentDashboardController@children | children/index | REQ-PPT-001 | PARTIAL |
| SCR-PPT-05 | Attendance Calendar | parent-portal.attendance.index | ParentAttendanceController@index | attendance/index | REQ-PPT-006 | PARTIAL |
| SCR-PPT-06 | Subject-wise Attendance | parent-portal.attendance.subject-wise | ParentAttendanceController@subjectWise | attendance/subject-wise | REQ-PPT-006 | PARTIAL |
| SCR-PPT-07 | Timetable | parent-portal.timetable.index | ParentTimetableController@index | timetable/index | REQ-PPT-008 | PARTIAL |
| SCR-PPT-08 | Homework List | parent-portal.homework.index | ParentHomeworkController@index | homework/index | REQ-PPT-007 | PARTIAL |
| SCR-PPT-09 | Homework Detail | parent-portal.homework.show | ParentHomeworkController@show | homework/show | REQ-PPT-007 | PARTIAL |
| SCR-PPT-10 | Results List | parent-portal.results.index | ParentResultController@index | results/index | REQ-PPT-009 | PARTIAL |
| SCR-PPT-11 | Result Detail | parent-portal.results.show | ParentResultController@show | results/show | REQ-PPT-009 | PARTIAL |
| SCR-PPT-12 | Report Card PDF Download | parent-portal.results.report-card.pdf | ParentResultController@reportCardPdf | (DomPDF, no Blade) | REQ-PPT-009 | PARTIAL |
| SCR-PPT-13 | Fee Summary | parent-portal.fees.index | ParentFeeController@index | fees/index | REQ-PPT-005 | PARTIAL |
| SCR-PPT-14 | Invoice Detail | parent-portal.fees.invoice | ParentFeeController@invoice | fees/invoice | REQ-PPT-005 | PARTIAL |
| SCR-PPT-15 | Razorpay Checkout Initiation | parent-portal.fees.invoice.pay.initiate | ParentFeePaymentController@initiate | (redirect to Razorpay) | REQ-PPT-005 | PARTIAL |
| SCR-PPT-16 | Payment History | parent-portal.fees.history | ParentFeeController@history | fees/history | REQ-PPT-005 | PARTIAL |
| SCR-PPT-16a | PDF Receipt | parent-portal.fees.receipt | ParentFeeController@receipt | fees/receipt | REQ-PPT-005 | PARTIAL |
| SCR-PPT-16b | Invoice PDF Download | parent-portal.fees.invoice.download | ParentFeeController@downloadInvoice | fees/invoice-pdf | REQ-PPT-005 | PARTIAL |
| SCR-PPT-17 | Message Inbox | ppt.messages.index | MessageController@index | (NOT BUILT) | REQ-PPT-004 | NOT STARTED |
| SCR-PPT-18 | Message Thread | ppt.messages.thread | MessageController@thread | (NOT BUILT) | REQ-PPT-004 | NOT STARTED |
| SCR-PPT-19 | Compose Message | ppt.messages.compose | MessageController@compose | (NOT BUILT) | REQ-PPT-004 | NOT STARTED |
| SCR-PPT-20 | Notification Inbox | parent-portal.notifications.index | ParentNotificationController@index | notifications/index | REQ-PPT-017 | PARTIAL |
| SCR-PPT-21 | (via mark-read) | parent-portal.notifications.mark-read | ParentNotificationController@markRead | — | REQ-PPT-017 | PARTIAL |
| SCR-PPT-22 | Notification Preferences | parent-portal.account.notifications.update | ParentAccountController@updateNotificationPreferences | account/index | REQ-PPT-003 | PARTIAL |
| SCR-PPT-23 | Leave List | parent-portal.leave.index | ParentLeaveController@index | leave/index | REQ-PPT-010 | PARTIAL (no table) |
| SCR-PPT-24 | Apply Leave | parent-portal.leave.create | ParentLeaveController@create | leave/create | REQ-PPT-010 | PARTIAL (no table) |
| SCR-PPT-25 | Leave Status | parent-portal.leave.show | ParentLeaveController@show | leave/show | REQ-PPT-010 | PARTIAL (no table) |
| SCR-PPT-26 | Consent Forms List | parent-portal.consent-forms.index | ParentConsentFormController@index | consent-forms/index | REQ-PPT-011 | PARTIAL |
| SCR-PPT-27 | Consent Form Detail + Sign | parent-portal.consent-forms.show | ParentConsentFormController@show | consent-forms/show | REQ-PPT-011 | PARTIAL |
| SCR-PPT-28 | PTM Events List | parent-portal.ptm.index | ParentPtmController@index | ptm/index | REQ-PPT-012 | PARTIAL |
| SCR-PPT-29 | PTM Slot Booking | parent-portal.ptm.show | ParentPtmController@show | ptm/show | REQ-PPT-012 | PARTIAL |
| SCR-PPT-30 | Event Calendar | parent-portal.events.index | ParentEventController@index | events/index | REQ-PPT-013 | PARTIAL |
| SCR-PPT-31 | Event Detail + RSVP | parent-portal.events.show | ParentEventController@show | events/show | REQ-PPT-013 | PARTIAL |
| SCR-PPT-32 | Health Overview | parent-portal.health.index | ParentHealthController@index | health/index | REQ-PPT-014 | PARTIAL |
| SCR-PPT-33 | Health Report Detail | parent-portal.health.show | ParentHealthController@show | (via health/index) | REQ-PPT-014 | PARTIAL |
| SCR-PPT-34 | Transport Info | parent-portal.transport.index | ParentTransportController@index | transport/index | REQ-PPT-015 | PARTIAL |
| SCR-PPT-35 | Document Vault | parent-portal.documents.index | ParentDocumentController@index | documents/index | REQ-PPT-016 | PARTIAL |
| SCR-PPT-36 | Document Request Form | parent-portal.documents.create | ParentDocumentController@create | documents/create | REQ-PPT-016 | PARTIAL |
| SCR-PPT-37 | Document Request Status | parent-portal.documents.show | ParentDocumentController@show | documents/show | REQ-PPT-016 | PARTIAL |
| SCR-PPT-38 | Account Settings | parent-portal.account.index | ParentAccountController@index | account/index | REQ-PPT-018 | PARTIAL |
| (bonus) | Complaint List/Create/Show | parent-portal.complaint.* | ParentComplaintController | complaint/* | [inferred] | PARTIAL |
| (bonus) | Hostel View | parent-portal.hostel.index | ParentHostelController@index | hostel/index | REQ-PPT-019 | PARTIAL |
| (bonus) | Learning Hub | parent-portal.learning.index | ParentLearningController@index | learning/index | REQ-PPT-020 | PARTIAL |
| (bonus) | Teachers List | parent-portal.teachers.index | ParentTeacherController@index | teachers/index | [teacher contact] | PARTIAL |

---

*End of PPT Complete Analysis Pack v1.0 | 2026-06-29*
*Module Knowledge: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/PPT_ParentPortal.md`*
*Source files verified: DDL v2 (2026-06-04), 5 tenant migrations (2026-06-16), 28 controllers, 22 FormRequests, 45 views, 267 route lines confirmed against live filesystem 2026-06-29*
