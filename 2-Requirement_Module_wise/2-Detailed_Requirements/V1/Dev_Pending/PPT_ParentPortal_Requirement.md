# ParentPortal Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Greenfield RBS-Only)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** PPT | **Module Path:** `Modules/ParentPortal`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `ppt_*` (minimal — most data read from other modules) | **Processing Mode:** RBS_ONLY (Greenfield)
**RBS Reference:** Module Z — Parent Portal & Mobile App (lines 4377–4441)

> **GREENFIELD MODULE** — No code, no DDL, no tests exist. All features are 📐 Proposed. This document defines the complete functional specification to guide development from scratch.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Module Overview](#2-module-overview)
3. [Stakeholders & Actors](#3-stakeholders--actors)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [Controller & Route Inventory](#6-controller--route-inventory)
7. [Form Request Validation Rules](#7-form-request-validation-rules)
8. [Business Rules](#8-business-rules)
9. [Permission & Authorization Model](#9-permission--authorization-model)
10. [Tests Inventory](#10-tests-inventory)
11. [Known Issues & Technical Debt](#11-known-issues--technical-debt)
12. [API Endpoints](#12-api-endpoints)
13. [Non-Functional Requirements](#13-non-functional-requirements)
14. [Integration Points](#14-integration-points)
15. [Pending Work & Gap Analysis](#15-pending-work--gap-analysis)

---

## 1. Executive Summary

### 1.1 Purpose

The ParentPortal module provides a dedicated parent-facing self-service interface for the Prime-AI platform. Parents of enrolled students can view their child's academic progress, attendance, fee dues, timetable, homework, exam results, and health records — all in a unified child-centric dashboard. Parents can make online fee payments via Razorpay, communicate directly with teachers, receive smart alerts (attendance absence, fee reminders, exam results), access and download documents (report cards, certificates), and participate in school events.

The portal is the parent-facing counterpart to the StudentPortal (`Modules/StudentPortal`). Both share the same tenant infrastructure and auth system but render role-specific UI for PARENT user type.

### 1.2 Scope

This module covers:
- Parent authentication (shared Laravel Auth, user_type=PARENT, linked via std_guardians.user_id)
- Multi-child support: parent selects active child; all views switch context to that child
- Unified dashboard: today's timetable, attendance %, last test score, pending homework, fee due
- Attendance view: date-wise attendance history, monthly calendar, total present/absent percentage
- Fee management: view outstanding invoices, pay online via Razorpay, download receipts as PDF
- Academic performance: exam results, subject-wise marks, grade reports, report card download
- Homework tracker: view pending/submitted homework assignments per subject
- Timetable view: child's weekly timetable (SmartTimetable integration)
- Teacher messaging: direct message to child's subject teacher; read receipts
- Circular / notification inbox: school announcements, event notifications
- HPC report access: health, physical, psychological (counsellor) report download
- Leave application: apply leave for child; track approval status
- Transport tracking: real-time bus location if transport module enabled
- Event management: view school events, RSVP, volunteer sign-up
- Document vault: report cards, marksheets, certificates, medical records
- Notification preferences: configure alert types and quiet hours per device

Out of scope for this version: direct video calling with teachers, parent-to-parent messaging, payment dispute management, real-time GPS tracking (requires hardware integration).

### 1.3 Design Philosophy: Read-Aggregation with Minimal New Tables

The ParentPortal is primarily a **read-aggregation portal** over existing module data. Most screens display data that already exists in other modules (StudentProfile, StudentFee, SmartTimetable, LmsHomework, LmsExam, Notification, HPC, Transport). This module introduces a small number of `ppt_*` tables for portal-specific state (notification read tracking, message threads, feedback, leave applications, event RSVPs).

### 1.4 Relationship to StudentPortal

| Aspect | StudentPortal (STP) | ParentPortal (PPT) |
|---|---|---|
| Auth user_type | STUDENT | PARENT |
| Primary user | Student | Guardian/Parent |
| DB link | std_students.user_id | std_guardians.user_id |
| Multi-child | N/A | Yes — child switcher |
| Fee payment | View own invoices | View + pay child's invoices |
| Messaging | Not yet built | Message teacher about child |
| Controller location | Modules/StudentPortal | Modules/ParentPortal |
| Complaint | Submit own complaint | Submit on behalf of child |

### 1.5 Module Statistics

| Metric | Count |
|---|---|
| RBS Features (F.Z*) | 6 (F.Z1.1–F.Z6.1) |
| RBS Tasks | 12 |
| RBS Sub-tasks | 24 (ST.Z1.1.1.1–ST.Z6.1.2.2) |
| Proposed new DB Tables (ppt_*) | 5 |
| Proposed Named Routes | ~65 |
| Proposed Blade Views | ~35 |
| Proposed Controllers | 10 |
| Proposed Models | 5 (ppt_* only; other modules' models reused) |
| Proposed Services | 4 |
| Proposed FormRequests | 7 |
| Proposed Policies | 3 |

### 1.6 Implementation Status

| Layer | Status | Notes |
|---|---|---|
| DB Schema / Migrations | ❌ Not Started | 5 new ppt_* tables |
| Models | ❌ Not Started | 5 ppt_* models; reuse std/fin/ntf models |
| Controllers | ❌ Not Started | 10 controllers |
| Services | ❌ Not Started | 4 services |
| Views | ❌ Not Started | ~35 blade views |
| Routes | ❌ Not Started | ~65 named routes |
| Tests | ❌ Not Started | Feature + Unit |

**Overall Implementation: 0%** (Greenfield)

---

## 2. Module Overview

### 2.1 Business Purpose

Indian school parents are actively engaged in their child's education but have traditionally relied on physical diaries, report cards, and parent-teacher meetings (PTM) for information. Modern Indian parents — especially urban and semi-urban — expect digital access to their child's school data. Key pain points solved by ParentPortal:

1. **Real-time attendance** — parent gets SMS alert when child is marked absent; can see full attendance history
2. **Fee management** — view outstanding fees with breakdown; pay via UPI/card from mobile without visiting school office
3. **Academic visibility** — see subject-wise marks, compare to class average, download official report cards
4. **Homework visibility** — know what homework is pending; reduce "I forgot" from children
5. **Direct teacher communication** — message subject teacher privately; no need to wait for PTM
6. **Document access** — download report cards, TC, medical certificates anytime without office visits
7. **Transport safety** — see live bus location; know when child boarded/alighted (if transport module active)

### 2.2 Key Features Summary

| Feature Area | Description | RBS Ref | Status |
|---|---|---|---|
| Child Overview Dashboard | All children in single view; switch active child | ST.Z1.1.1.1 | 📐 Proposed |
| Academic Snapshot | Attendance %, last score, pending homework, fee dues | ST.Z1.1.1.2, ST.Z1.1.2.1–2 | 📐 Proposed |
| Smart Alerts | Configure alert types (fee, absence, results); quiet hours | ST.Z2.1.1.1–2 | 📐 Proposed |
| Push Notifications (FCM/APNs) | Reliable delivery with device token management | ST.Z2.1.2.1–2 | 📐 Proposed |
| Teacher Messaging | Direct message with file attachments; read receipts | ST.Z3.1.1.1–2, ST.Z3.1.2.1–2 | 📐 Proposed |
| Fee View & Online Payment | View invoices, pay via Razorpay (UPI/card/netbanking) | ST.Z4.1.1.1–2 | 📐 Proposed |
| Payment History & Receipts | All transactions; download PDF receipt | ST.Z4.1.2.1–2 | 📐 Proposed |
| Event Calendar & RSVP | School events, PTM; RSVP + calendar sync | ST.Z5.1.1.1–2 | 📐 Proposed |
| Volunteer Sign-up | Sign up for event volunteer roles | ST.Z5.1.2.1–2 | 📐 Proposed |
| Document Vault | Report cards, marksheets, certificates, medical | ST.Z6.1.1.1–2 | 📐 Proposed |
| Document Request | Request duplicate certificates; track + pay online | ST.Z6.1.2.1–2 | 📐 Proposed |
| Attendance Detail View | Monthly calendar view; subject-wise attendance | Beyond RBS | 📐 Proposed |
| Homework Tracker | Pending/submitted homework per subject | Beyond RBS | 📐 Proposed |
| Timetable View | Child's weekly schedule | Beyond RBS | 📐 Proposed |
| HPC Report Access | Health/physical/psychological report download | Beyond RBS | 📐 Proposed |
| Leave Application | Apply child leave; track approval | Beyond RBS | 📐 Proposed |
| Transport Tracking | Live bus location if transport module active | Beyond RBS | 📐 Proposed |
| Account Settings | Profile, password, notification preferences, linked children | Beyond RBS | 📐 Proposed |

### 2.3 Authentication & Child Context

```
Parent logs in → user_type = PARENT
→ std_guardians.user_id = sys_users.id
→ std_student_guardian_jnt WHERE guardian_id = std_guardians.id
  AND can_access_parent_portal = 1
→ List of linked children (std_students)
→ Parent selects active child (stored in session/cookie)
→ All portal views filter data by active child's std_students.id
```

A parent with multiple children sees a child switcher on every screen. All data views (attendance, fees, homework, results) are scoped to the currently selected child.

### 2.4 Menu Navigation Path

```
Parent Portal [/parent-portal]
├── Dashboard                   [/parent-portal/dashboard]
├── My Children                 [/parent-portal/children]          (switch active child)
├── Academics
│   ├── Attendance              [/parent-portal/attendance]
│   ├── Timetable               [/parent-portal/timetable]
│   ├── Homework                [/parent-portal/homework]
│   └── Results & Report Cards  [/parent-portal/results]
├── Fee & Payments
│   ├── Fee Summary             [/parent-portal/fees]
│   └── Payment History         [/parent-portal/fees/history]
├── Communication
│   ├── Messages                [/parent-portal/messages]
│   └── Notifications           [/parent-portal/notifications]
├── Health
│   └── HPC Reports             [/parent-portal/health-reports]
├── Leave Application
│   └── Apply / Track Leave     [/parent-portal/leave]
├── Transport
│   └── Track Bus               [/parent-portal/transport]
├── Events
│   └── School Events           [/parent-portal/events]
├── Documents
│   └── Document Vault          [/parent-portal/documents]
└── Account Settings            [/parent-portal/settings]
```

### 2.5 Module Architecture

```
Modules/ParentPortal/
├── app/
│   ├── Http/Controllers/
│   │   ├── ParentPortalController.php          # Dashboard, auth, child-switcher
│   │   ├── AttendanceViewController.php         # Child attendance read-view
│   │   ├── TimetableViewController.php          # Child timetable read-view
│   │   ├── HomeworkViewController.php           # Homework tracker read-view
│   │   ├── ResultViewController.php             # Results, report cards
│   │   ├── FeeViewController.php                # Fee view + Razorpay payment
│   │   ├── MessageController.php                # Parent-teacher messaging
│   │   ├── NotificationController.php           # Circular/notification inbox
│   │   ├── EventController.php                  # Events, RSVP, volunteer
│   │   └── DocumentController.php               # Document vault + requests
│   ├── Models/
│   │   ├── ParentSession.php                    # ppt_parent_sessions
│   │   ├── ParentMessage.php                    # ppt_messages
│   │   ├── ParentLeaveApplication.php           # ppt_leave_applications
│   │   ├── EventRsvp.php                        # ppt_event_rsvps
│   │   └── DocumentRequest.php                  # ppt_document_requests
│   ├── Services/
│   │   ├── ParentDashboardService.php           # Aggregate child summary data
│   │   ├── FeePaymentService.php                # Razorpay integration (mirrors StudentPortal)
│   │   ├── MessagingService.php                 # Message thread management
│   │   └── NotificationPreferenceService.php    # Alert preferences + quiet hours
│   ├── Policies/
│   │   ├── ParentChildPolicy.php                # Verify parent→child authorization
│   │   ├── ParentMessagePolicy.php
│   │   └── ParentLeavePolicy.php
│   └── Providers/
├── database/migrations/ (5 migrations)
├── resources/views/parent-portal/
│   ├── layouts/parent-portal.blade.php          # Parent-specific layout
│   ├── dashboard.blade.php
│   ├── children/        (index, switch)
│   ├── attendance/      (index, calendar, subject-wise)
│   ├── timetable/       (index)
│   ├── homework/        (index, show)
│   ├── results/         (index, show, report-card)
│   ├── fees/            (index, pay, history, receipt)
│   ├── messages/        (index, thread, compose)
│   ├── notifications/   (index, show)
│   ├── health-reports/  (index, show)
│   ├── leave/           (index, create, show)
│   ├── transport/       (index)
│   ├── events/          (index, show, rsvp)
│   ├── documents/       (index, request)
│   └── settings/        (profile, password, preferences)
└── routes/
    ├── api.php
    └── web.php
```

---

## 3. Stakeholders & Actors

| Actor | Role in ParentPortal | Permissions |
|---|---|---|
| Parent (Guardian) | Primary user — views child data, pays fees, communicates | Portal access only to own child's data |
| School Admin | Manage parent accounts, approve document requests, configure portal settings | Full admin access |
| Class Teacher | Receives/sends messages from parent, approves leave | Message receive, leave approve |
| Subject Teacher | Receives messages about subject-related queries | Message receive (own subjects) |
| Principal | Receives escalated communications | Message receive |
| System | Sends push notifications, tracks read status, fires payment webhooks | system actor |

---

## 4. Functional Requirements

---

### FR-PPT-001: Parent Dashboard — Child Overview (F.Z1.1)

**RBS Reference:** F.Z1.1 — Child Overview; T.Z1.1.1, T.Z1.1.2
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `ppt_parent_sessions` + read aggregation from other modules

#### Requirements

**REQ-PPT-001.1: Multi-Child Dashboard View (ST.Z1.1.1.1)**
| Attribute | Detail |
|---|---|
| Description | Parent lands on a dashboard showing all linked children with key summary; clicks on child to set active context |
| Actors | Parent |
| Preconditions | Parent authenticated; std_student_guardian_jnt records exist with can_access_parent_portal=1 |
| Processing | Load guardian record via std_guardians.user_id; query all children via std_student_guardian_jnt; for each child load: class+section, today's timetable next_period, current_transport_status if transport enabled; display as child cards |
| Output | Child cards; active child selected sets session variable |
| Status | 📐 Proposed |

**REQ-PPT-001.2: Academic Snapshot per Child (ST.Z1.1.2.1–2)**
| Attribute | Detail |
|---|---|
| Description | Dashboard shows key academic metrics for the active child |
| Processing | Aggregate: attendance_pct (current month, from attendance module), last_test_score (most recent exam result), pending_homework_count (from LmsHomework), fee_due_amount (from fin_fee_invoices WHERE status=Unpaid), upcoming_payment_deadline (nearest fin_fee_installments.due_date) |
| Output | Summary widgets on dashboard |
| Status | 📐 Proposed |

**REQ-PPT-001.3: Today's Timetable & Transport Status (ST.Z1.1.1.2)**
| Attribute | Detail |
|---|---|
| Description | Show today's class schedule and current transport location if enabled |
| Processing | Query SmartTimetable / StandardTimetable for today's published schedule for child's class+section; query transport module for child's assigned route and bus GPS status |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.Z1.1.1.1 — All children visible with photos, classes, sections
- [ ] ST.Z1.1.1.2 — Today's timetable, next class shown
- [ ] ST.Z1.1.2.1 — Attendance %, last test score, pending homework shown
- [ ] ST.Z1.1.2.2 — Fee dues and payment deadline shown

---

### FR-PPT-002: Smart Notification Preferences (F.Z2.1)

**RBS Reference:** F.Z2.1 — Smart Alerts; T.Z2.1.1, T.Z2.1.2
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `ppt_notification_preferences` (stored in ppt_parent_sessions or as JSON column)

#### Requirements

**REQ-PPT-002.1: Configure Alert Preferences (ST.Z2.1.1.1)**
| Attribute | Detail |
|---|---|
| Description | Parent configures which types of alerts they want to receive |
| Actors | Parent |
| Alert Types | FeeReminder, AbsenceAlert, ExamResult, HomeworkDue, CircularAnnouncement, TransportUpdate, EventReminder |
| Channels | In-App, SMS, Email, WhatsApp (based on std_student_guardian_jnt.notification_preference) |
| Processing | Store alert preferences per guardian per alert_type per channel in ppt_parent_sessions JSON or dedicated column; Notification module reads preferences before dispatch |
| Status | 📐 Proposed |

**REQ-PPT-002.2: Quiet Hours (ST.Z2.1.1.2)**
| Attribute | Detail |
|---|---|
| Description | Parent sets quiet hours during which non-urgent notifications are muted |
| Input | quiet_hours_start (TIME), quiet_hours_end (TIME), timezone |
| Processing | Notification module checks quiet hours before dispatching non-urgent notifications (urgent = Absence, Emergency always bypass) |
| Status | 📐 Proposed |

**REQ-PPT-002.3: Device Token Management (ST.Z2.1.2.1–2)**
| Attribute | Detail |
|---|---|
| Description | FCM (Android) and APNs (iOS) tokens managed per device per parent |
| Processing | On login, register/update device token in ppt_parent_sessions; on logout mark inactive; handle token refresh events; Notification module sends to all active tokens for the guardian |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.Z2.1.1.1 — Parent can configure alert types (Fee, Absence, Results)
- [ ] ST.Z2.1.1.2 — Quiet hours configured to mute non-urgent notifications
- [ ] ST.Z2.1.2.1 — FCM/APNs delivery for Android/iOS
- [ ] ST.Z2.1.2.2 — Device token updates handled automatically

---

### FR-PPT-003: Teacher Messaging (F.Z3.1)

**RBS Reference:** F.Z3.1 — Teacher Messaging; T.Z3.1.1, T.Z3.1.2
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `ppt_messages`

#### Requirements

**REQ-PPT-003.1: Compose Message to Teacher (ST.Z3.1.1.1)**
| Attribute | Detail |
|---|---|
| Description | Parent selects a teacher from their child's subject list and composes a message |
| Actors | Parent |
| Preconditions | Child is enrolled in classes with assigned subject teachers |
| Input | recipient_user_id (selected from child's subject teacher list), subject (required, max 200), message_body (required text), attachments[] (optional files up to 3, via sys_media) |
| Processing | Create ppt_messages record; notify teacher via in-app notification; link to child context (student_id) |
| Output | Message sent; appears in inbox of both parent and teacher |
| Status | 📐 Proposed |

**REQ-PPT-003.2: File Attachments & Read Receipts (ST.Z3.1.1.2)**
| Attribute | Detail |
|---|---|
| Description | Message can include file attachments; sender sees read receipt when teacher opens message |
| Processing | Files stored in sys_media; read receipt: update ppt_messages.read_at when teacher views thread; parent sees "Read [timestamp]" indicator |
| Status | 📐 Proposed |

**REQ-PPT-003.3: Message History & Search (ST.Z3.1.2.1–2)**
| Attribute | Detail |
|---|---|
| Description | Parent views full conversation history with any teacher; search by keyword, teacher, date |
| Processing | Thread view: group messages by (parent_guardian_id, teacher_user_id, student_id); search: FULLTEXT on subject + message_body; filter by teacher, date range |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.Z3.1.1.1 — Select teacher from child's subject list; compose and send message
- [ ] ST.Z3.1.1.2 — File attachments; read receipt shown
- [ ] ST.Z3.1.2.1 — Full conversation history viewable
- [ ] ST.Z3.1.2.2 — Search by keyword, teacher, date range

---

### FR-PPT-004: Fee Management & Online Payment (F.Z4.1)

**RBS Reference:** F.Z4.1 — Online Payments; T.Z4.1.1, T.Z4.1.2
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** Read from `fin_fee_invoices`, `fin_transactions` (write via Payment module); `ppt_*` tables minimal

#### Requirements

**REQ-PPT-004.1: View Fee Invoices & Breakdown (ST.Z4.1.1.1)**
| Attribute | Detail |
|---|---|
| Description | Parent views detailed fee breakdown for the active child |
| Actors | Parent |
| Processing | Query fin_fee_invoices WHERE student_id = active_child.id; group by academic_term; show: invoice number, fee heads breakdown, amount, due_date, status (Paid/Unpaid/Overdue), total_outstanding |
| Output | Fee summary with per-invoice details |
| Status | 📐 Proposed |

**REQ-PPT-004.2: Select Installments & Pay Online (ST.Z4.1.1.2)**
| Attribute | Detail |
|---|---|
| Description | Parent selects specific unpaid installments and initiates Razorpay payment |
| Actors | Parent |
| Input | invoice_ids[] (selected unpaid invoices), payment_method (Card/NetBanking/UPI/Wallet) |
| Processing | Calculate total; create Razorpay order (mirrors fin_* Payment module pattern); on success: update fin_fee_invoices.status=Paid; create fin_transactions record; send receipt SMS; dispatch receipt PDF via DomPDF |
| Security | Enforce parent→child authorization: parent can only pay their own child's invoices (prevent IDOR) |
| Output | Payment confirmation; receipt generated |
| Status | 📐 Proposed |

**REQ-PPT-004.3: Payment History & PDF Receipts (ST.Z4.1.2.1–2)**
| Attribute | Detail |
|---|---|
| Description | Parent views all past transactions and downloads PDF receipts |
| Processing | Query fin_transactions WHERE student_id = active_child.id AND guardian_id = current_guardian.id; show: date, amount, mode, status (Success/Failed/Pending), receipt link |
| PDF | DomPDF receipt: school letterhead, transaction ID, fee heads paid, amount, date, stamp |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.Z4.1.1.1 — Detailed fee breakdown with installment selection
- [ ] ST.Z4.1.1.2 — UPI/Card/NetBanking/Wallet payment via Razorpay
- [ ] ST.Z4.1.2.1 — All past transactions visible with status
- [ ] ST.Z4.1.2.2 — PDF receipt downloadable
- [ ] SECURITY — Parent can ONLY pay their own child's invoices (ParentChildPolicy enforced)

---

### FR-PPT-005: Attendance View (Beyond RBS — Core Feature)

**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** Read from attendance tables in StudentProfile/School modules

#### Requirements

**REQ-PPT-005.1: Monthly Attendance Calendar**
| Attribute | Detail |
|---|---|
| Description | Parent views child's attendance for current academic year as a monthly calendar |
| Processing | Query attendance records for active child; display month view: Present (green), Absent (red), Holiday (grey), Late (yellow); calculate monthly and YTD attendance percentage |
| Status | 📐 Proposed |

**REQ-PPT-005.2: Subject-wise Attendance**
| Attribute | Detail |
|---|---|
| Description | View attendance per subject (for college-style minimum attendance requirements) |
| Processing | If school has subject-wise attendance enabled: group by subject; show periods attended / total periods per subject |
| Status | 📐 Proposed |

---

### FR-PPT-006: Homework Tracker (Beyond RBS — Core Feature)

**Priority:** 🟠 High
**Status:** 📐 Proposed
**Table(s):** Read from LmsHomework tables

#### Requirements

**REQ-PPT-006.1: View Child's Homework**
| Attribute | Detail |
|---|---|
| Description | Parent views all homework assigned to the active child, grouped by status |
| Processing | Query homework_assignments WHERE student's class+section; show: subject, title, assigned_date, due_date, status (Pending/Submitted/Overdue); link to homework detail |
| Output | Today's homework section; upcoming deadlines; overdue count |
| Status | 📐 Proposed |

---

### FR-PPT-007: Timetable View (Beyond RBS — Core Feature)

**Priority:** 🟠 High
**Status:** 📐 Proposed
**Table(s):** Read from SmartTimetable / StandardTimetable

#### Requirements

**REQ-PPT-007.1: View Weekly Timetable**
| Attribute | Detail |
|---|---|
| Description | Parent views the active child's published weekly class schedule |
| Processing | Query published timetable for child's class+section+academic_term; display as weekly grid: day × period → subject + teacher name; highlight today's column |
| Status | 📐 Proposed |

---

### FR-PPT-008: Academic Results & Report Cards (Beyond RBS — Core Feature)

**Priority:** 🟠 High
**Status:** 📐 Proposed
**Table(s):** Read from LmsExam / Exam result tables

#### Requirements

**REQ-PPT-008.1: View Exam Results**
| Attribute | Detail |
|---|---|
| Description | Parent views all exam results for the active child |
| Processing | Query exam results for child: exam name, subject, marks_obtained, max_marks, grade, pass/fail, rank (if school enables); show term-wise |
| Status | 📐 Proposed |

**REQ-PPT-008.2: Download Report Card**
| Attribute | Detail |
|---|---|
| Description | Parent downloads official report card generated by school |
| Processing | Retrieve HPC/Exam report card from sys_media or generate via DomPDF (school report card template); require school to publish report card before it is downloadable |
| Security | Only accessible after school has published report cards for that term |
| Status | 📐 Proposed |

---

### FR-PPT-009: Event Calendar & Volunteer Sign-up (F.Z5.1)

**RBS Reference:** F.Z5.1 — Event Participation; T.Z5.1.1, T.Z5.1.2
**Priority:** 🟡 Medium
**Status:** 📐 Proposed
**Table(s):** `ppt_event_rsvps` + read from Event Engine module

#### Requirements

**REQ-PPT-009.1: View School Events (ST.Z5.1.1.1)**
| Attribute | Detail |
|---|---|
| Description | Parent views calendar of upcoming school events |
| Processing | Query published events from Event Engine module (or ntf_circulars); filter by date; show: name, date, venue, type (PTM/Sports Day/Festival/Exam/Holiday) |
| Status | 📐 Proposed |

**REQ-PPT-009.2: RSVP for Events (ST.Z5.1.1.2)**
| Attribute | Detail |
|---|---|
| Description | Parent RSVPs for events requiring attendance confirmation (e.g., PTM) |
| Processing | Create ppt_event_rsvps record with guardian_id, event_id, rsvp_status (Attending/Not_Attending), rsvp_notes; send confirmation notification |
| Status | 📐 Proposed |

**REQ-PPT-009.3: Volunteer Sign-up (ST.Z5.1.2.1–2)**
| Attribute | Detail |
|---|---|
| Description | Parent signs up for volunteer roles for school events |
| Input | event_id, volunteer_role (e.g., Food stall, Decoration, Registration desk), parent_name |
| Processing | Create ppt_event_rsvps record with volunteer_role; notify event coordinator; send confirmation and reminders to parent |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.Z5.1.1.1 — Events calendar viewable (PTM, Sports Day, Festivals)
- [ ] ST.Z5.1.1.2 — RSVP and add to personal calendar
- [ ] ST.Z5.1.2.1 — Volunteer sign-up for event roles
- [ ] ST.Z5.1.2.2 — Confirmation and reminders for volunteer duties

---

### FR-PPT-010: Document Vault & Requests (F.Z6.1)

**RBS Reference:** F.Z6.1 — Secure Document Access; T.Z6.1.1, T.Z6.1.2
**Priority:** 🟡 Medium
**Status:** 📐 Proposed
**Table(s):** `ppt_document_requests` + read from sys_media

#### Requirements

**REQ-PPT-010.1: Access Child Documents (ST.Z6.1.1.1–2)**
| Attribute | Detail |
|---|---|
| Description | Parent views and downloads official documents of the active child |
| Document Types | Report cards, marksheets, TC (Transfer Certificate), bonafide certificates, vaccination records, medical certificates (with consent flag) |
| Processing | Query sys_media WHERE model_type relates to child; enforce school-published flag (document not accessible until school marks it as available); for medical records: only accessible if std_health_records.parent_visible=1 |
| Status | 📐 Proposed |

**REQ-PPT-010.2: Request Duplicate Copies (ST.Z6.1.2.1–2)**
| Attribute | Detail |
|---|---|
| Description | Parent submits online request for duplicate documents; tracks status and pays any fees |
| Input | document_type (TC/MarkSheet/Bonafide/Certificate), reason, urgency |
| Processing | Create ppt_document_requests record; notify admin; admin processes and uploads; if fee applicable, initiate payment via Razorpay; parent downloads once paid and approved |
| Output | Request tracked with status: Pending/Processing/Ready/Completed |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.Z6.1.1.1 — Report cards, marksheets, certificates viewable and downloadable
- [ ] ST.Z6.1.1.2 — Medical records accessible with consent flag
- [ ] ST.Z6.1.2.1 — Online request for duplicate certificates
- [ ] ST.Z6.1.2.2 — Request status tracked; fees paid online if applicable

---

### FR-PPT-011: Leave Application for Child (Beyond RBS)

**Priority:** 🟠 High
**Status:** 📐 Proposed
**Table(s):** `ppt_leave_applications`

#### Requirements

**REQ-PPT-011.1: Apply Leave for Child**
| Attribute | Detail |
|---|---|
| Description | Parent applies for leave on behalf of child for upcoming dates |
| Actors | Parent |
| Input | student_id (active child), from_date (required, future), to_date (required, >= from_date), leave_type (ENUM: Sick/Family/Personal/Other), reason (required), supporting_doc (optional medical certificate) |
| Processing | Create ppt_leave_applications; notify class teacher for approval; calculate number_of_days |
| Output | Leave application submitted; status=Pending |
| Status | 📐 Proposed |

**REQ-PPT-011.2: Track Leave Application Status**
| Attribute | Detail |
|---|---|
| Description | Parent tracks the approval status of leave applications |
| Processing | List all applications with status (Pending/Approved/Rejected); show teacher's comments if rejected; on approval, flag is_approved=1 and class teacher notified |
| Status | 📐 Proposed |

---

### FR-PPT-012: Health & HPC Reports (Beyond RBS)

**Priority:** 🟡 Medium
**Status:** 📐 Proposed
**Table(s):** Read from HPC module tables

#### Requirements

**REQ-PPT-012.1: View HPC Reports**
| Attribute | Detail |
|---|---|
| Description | Parent views health, physical, and psychological (counsellor) assessment reports for their child |
| Processing | Query HPC module: std_health_records, std_physical_assessment, std_counsellor_reports for active child; show summary; allow download as PDF (DomPDF, mirrors HPC module PDF generation) |
| Access Control | Counsellor psychological notes: only if school enables parent_visible; medical records subject to std consent flags |
| Status | 📐 Proposed |

---

### FR-PPT-013: Transport Tracking (Beyond RBS)

**Priority:** 🟡 Medium
**Status:** 📐 Proposed
**Table(s):** Read from Transport module (tpt_*)

#### Requirements

**REQ-PPT-013.1: View Bus Route & Status**
| Attribute | Detail |
|---|---|
| Description | Parent sees the bus route their child is assigned to, including today's status |
| Preconditions | Transport module is enabled for the school |
| Processing | Query tpt_student_route_jnt for active child → tpt_routes → tpt_vehicles; show: route name, bus number, driver name, driver mobile, departure time, child's pickup stop; if GPS data available show live location on map |
| Status | 📐 Proposed |

---

## 5. Data Model

### 5.1 Design Principle

The ParentPortal creates **5 new `ppt_*` tables** for portal-specific state. All other data is read from existing module tables. The core FK chain is:

```
sys_users (user_type=PARENT) ←→ std_guardians ←→ std_student_guardian_jnt ←→ std_students
```

Access control: `ParentChildPolicy` verifies that the guardian making the request has an active `std_student_guardian_jnt` record with `can_access_parent_portal=1` for the requested `student_id`.

---

#### 📐 `ppt_parent_sessions`

Tracks per-device portal state: active child selection, device tokens, notification preferences, quiet hours.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| guardian_id | INT UNSIGNED | NOT NULL FK→std_guardians | |
| active_student_id | INT UNSIGNED | NULL FK→std_students | Currently selected child |
| device_token_fcm | VARCHAR(255) | NULL | Android FCM token |
| device_token_apns | VARCHAR(255) | NULL | iOS APNs token |
| device_type | ENUM('Android','iOS','Web') | NULL | |
| notification_preferences_json | JSON | NULL | {"FeeReminder":{"in_app":1,"sms":1},...} |
| quiet_hours_start | TIME | NULL | |
| quiet_hours_end | TIME | NULL | |
| last_active_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

UNIQUE KEY `uq_ppt_session_guardian_device` (`guardian_id`, `device_token_fcm`) — prevent duplicate tokens

---

#### 📐 `ppt_messages`

Parent-teacher direct messages scoped to a child context.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| guardian_id | INT UNSIGNED | NOT NULL FK→std_guardians | Parent sending/receiving |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | Child context |
| direction | ENUM('Parent_to_Teacher','Teacher_to_Parent') | NOT NULL | |
| sender_user_id | INT UNSIGNED | NOT NULL FK→sys_users | |
| recipient_user_id | INT UNSIGNED | NOT NULL FK→sys_users | |
| thread_id | VARCHAR(64) | NOT NULL | Hash of (guardian_id+teacher_user_id+student_id) |
| subject | VARCHAR(200) | NOT NULL | |
| message_body | TEXT | NOT NULL | |
| attachment_media_ids_json | JSON | NULL | Array of sys_media.id |
| read_at | TIMESTAMP | NULL | When recipient read message |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

INDEX on `(thread_id, created_at)` for conversation view
FULLTEXT INDEX on `(subject, message_body)` for search

---

#### 📐 `ppt_leave_applications`

Leave applications by parent on behalf of child.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| application_number | VARCHAR(30) | NOT NULL UNIQUE | PPT-LV-YYYYXXXXXXXX |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | |
| guardian_id | INT UNSIGNED | NOT NULL FK→std_guardians | |
| from_date | DATE | NOT NULL | |
| to_date | DATE | NOT NULL | |
| number_of_days | TINYINT UNSIGNED | NOT NULL | Calculated |
| leave_type | ENUM('Sick','Family','Personal','Festival','Medical','Other') | NOT NULL | |
| reason | TEXT | NOT NULL | |
| supporting_doc_media_id | INT UNSIGNED | NULL FK→sys_media | |
| status | ENUM('Pending','Approved','Rejected','Withdrawn') | DEFAULT 'Pending' | |
| reviewed_by_user_id | INT UNSIGNED | NULL FK→sys_users | Class teacher |
| reviewed_at | TIMESTAMP | NULL | |
| reviewer_notes | TEXT | NULL | Rejection reason |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

---

#### 📐 `ppt_event_rsvps`

Parent RSVPs and volunteer sign-ups for school events.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| event_id | INT UNSIGNED | NOT NULL | FK to Event Engine event record |
| guardian_id | INT UNSIGNED | NOT NULL FK→std_guardians | |
| student_id | INT UNSIGNED | NULL FK→std_students | Which child this RSVP is for (if event is child-linked) |
| rsvp_status | ENUM('Attending','Not_Attending','Maybe') | NOT NULL DEFAULT 'Attending' | |
| is_volunteer | TINYINT(1) | DEFAULT 0 | |
| volunteer_role | VARCHAR(150) | NULL | e.g., "Food stall" |
| rsvp_notes | TEXT | NULL | |
| confirmed_at | TIMESTAMP | NULL | |
| reminder_sent_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

UNIQUE KEY `uq_ppt_rsvp` (`event_id`, `guardian_id`)

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
| fee_required | DECIMAL(8,2) | DEFAULT 0.00 | |
| fee_paid | TINYINT(1) | DEFAULT 0 | |
| payment_reference | VARCHAR(100) | NULL | |
| fulfilled_media_id | INT UNSIGNED | NULL FK→sys_media | Document uploaded by admin |
| fulfilled_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

---

### 5.2 Entity Relationships

```
sys_users (PARENT) ──── std_guardians ──── std_student_guardian_jnt ──── std_students
                              │
                    ppt_parent_sessions (device token, prefs)
                              │
                    ppt_messages (student_id context)
                    ppt_leave_applications (student_id)
                    ppt_event_rsvps (guardian_id)
                    ppt_document_requests (student_id)

READ INTEGRATIONS:
std_students ──── Attendance tables (read)
std_students ──── fin_fee_invoices (read + payment)
std_students ──── tt_timetable / SmartTimetable (read)
std_students ──── LmsHomework tables (read)
std_students ──── Exam/Result tables (read)
std_students ──── HPC module tables (read)
std_students ──── tpt_* transport (read)
std_guardians ──── ntf_notifications (read)
```

---

## 6. Controller & Route Inventory

| Controller | Route Prefix | Named Prefix | Key Methods |
|---|---|---|---|
| 📐 ParentPortalController | /parent-portal | ppt | dashboard, switchChild, index |
| 📐 AttendanceViewController | /parent-portal/attendance | ppt.attendance | index, calendar, subjectWise |
| 📐 TimetableViewController | /parent-portal/timetable | ppt.timetable | index |
| 📐 HomeworkViewController | /parent-portal/homework | ppt.homework | index, show |
| 📐 ResultViewController | /parent-portal/results | ppt.results | index, show, downloadReportCard |
| 📐 FeeViewController | /parent-portal/fees | ppt.fees | index, show, pay, razorpayCallback, history, downloadReceipt |
| 📐 MessageController | /parent-portal/messages | ppt.messages | index, thread, compose, store, reply, markRead |
| 📐 NotificationController | /parent-portal/notifications | ppt.notifications | index, show, markRead, markAllRead, preferences |
| 📐 EventController | /parent-portal/events | ppt.events | index, show, rsvp, volunteerSignup |
| 📐 DocumentController | /parent-portal/documents | ppt.documents | index, show, download, requestForm, storeRequest, trackRequest |

**Additional routes:**
- GET /parent-portal/health-reports → attached to ResultViewController or dedicated HealthViewController
- GET/POST /parent-portal/leave → LeaveController
- GET /parent-portal/transport → TransportViewController
- GET/POST /parent-portal/settings → AccountSettingsController

**Estimated total named routes:** ~65

---

## 7. Form Request Validation Rules

| FormRequest | Key Rules |
|---|---|
| 📐 ComposeMessageRequest | recipient_user_id required\|exists:sys_users,id; subject required\|max:200; message_body required\|min:10; attachments nullable\|array\|max:3; each attachment: file\|max:5120\|mimes:pdf,jpg,png,doc,docx |
| 📐 ApplyLeaveRequest | student_id required\|exists:std_students,id; from_date required\|date\|after_or_equal:tomorrow; to_date required\|date\|after_or_equal:from_date; leave_type required\|in:Sick,Family,...; reason required\|min:20 |
| 📐 EventRsvpRequest | event_id required\|integer; rsvp_status required\|in:Attending,Not_Attending,Maybe; volunteer_role nullable\|max:150 |
| 📐 DocumentRequestForm | document_type required\|in:TC,MarkSheet,...; reason required\|min:20; urgency required\|in:Normal,Urgent |
| 📐 NotificationPreferencesRequest | preferences required\|array; each alert_type in allowed list; quiet_hours_start nullable\|date_format:H:i; quiet_hours_end nullable\|date_format:H:i |
| 📐 SwitchChildRequest | student_id required\|exists:std_students,id (validated against guardian's children in policy) |
| 📐 FeePaymentRequest | invoice_ids required\|array\|min:1; each invoice_id exists:fin_fee_invoices,id; total_amount required\|numeric\|min:1 |

---

## 8. Business Rules

| Rule ID | Rule Description |
|---|---|
| BR-PPT-001 | Parent can only access data for children linked via std_student_guardian_jnt WHERE guardian.user_id = auth.user.id AND can_access_parent_portal = 1. This is enforced by ParentChildPolicy on EVERY data request. |
| BR-PPT-002 | Fee payment: parent can only initiate payment for their own child's invoices. Invoice ownership is validated by student_id match in fin_fee_invoices. |
| BR-PPT-003 | Messages: parent can only compose messages to teachers who teach their active child's enrolled subjects. Teacher list is dynamically built from class+section timetable assignment. |
| BR-PPT-004 | Leave application: from_date must be tomorrow or later (cannot apply leave for today or past). |
| BR-PPT-005 | Report card download: available only after school admin marks the term's report cards as published. |
| BR-PPT-006 | Medical records visible to parent only if std_health_records.parent_visible = 1 (set by school nurse/admin). |
| BR-PPT-007 | Counsellor psychological reports visible only if school has enabled parent_counsellor_report_visibility in sys_school_settings. |
| BR-PPT-008 | Quiet hours: urgent notifications (type: AbsenceAlert, EmergencyAlert) bypass quiet hours and are always sent immediately. |
| BR-PPT-009 | Device tokens: on re-login from a different device, the old device's token is deactivated (is_active=0 in ppt_parent_sessions). |
| BR-PPT-010 | Multi-child: the active child context is stored in the PHP session and validated on every data request. Switching child is an explicit action. |
| BR-PPT-011 | Document requests require fee payment (if fee > 0) before the fulfilled document becomes downloadable. |
| BR-PPT-012 | IDOR prevention is mandatory: all data queries include a guardian→student ownership check via ParentChildPolicy. This is a P0 security requirement. |

---

## 9. Permission & Authorization Model

### 9.1 Portal-Level Access

Access to the parent portal is entirely separate from the admin panel. Parent users (`user_type=PARENT`) cannot access any admin routes. The portal runs on the same tenant but under a different route group with its own middleware.

```php
Route::prefix('parent-portal')
    ->middleware(['auth', 'verified', 'parent.portal'])
    ->group(...);
```

The `parent.portal` middleware enforces:
1. `auth()->user()->user_type === 'PARENT'`
2. Guardian record exists in `std_guardians` with an active linked child

### 9.2 Authorization Policies

| Policy | Method | Logic |
|---|---|---|
| ParentChildPolicy | access(guardian, student) | Verify std_student_guardian_jnt.guardian_id + student_id + can_access_parent_portal=1 |
| ParentMessagePolicy | create(guardian, teacher_user) | Verify teacher teaches a subject in active child's class |
| ParentLeavePolicy | create(guardian, student) | Verify active child ownership; from_date > today |

### 9.3 No Spatie Roles for Portal Users

Parent portal users do NOT use Spatie Roles/Permissions. All authorization is handled via Laravel Policies and custom middleware (same pattern as existing StudentPortal). This avoids complexity and potential permission configuration issues.

---

## 10. Tests Inventory

| # | Test Class | Type | Scenario | Priority |
|---|---|---|---|---|
| 1 | 📐 ParentAuthTest | Feature | Login with PARENT user; portal home loads; STUDENT user redirected | Critical |
| 2 | 📐 ParentChildAccessTest | Feature | Parent can view own child's data; cannot access another student's data (IDOR test) | Critical |
| 3 | 📐 FeePaymentAuthTest | Feature | Parent can only pay own child's invoices; cross-child payment blocked | Critical |
| 4 | 📐 SwitchChildTest | Feature | Switch active child; all subsequent views reflect new child context | High |
| 5 | 📐 ComposeMessageTest | Feature | Parent composes message to child's teacher; message created; teacher notified | High |
| 6 | 📐 MessageSearchTest | Feature | Search by keyword returns matching messages | Medium |
| 7 | 📐 LeaveApplicationTest | Feature | Apply leave with future date; class teacher notified | High |
| 8 | 📐 LeaveApprovalTest | Feature | Teacher approves leave; parent sees status Approved | High |
| 9 | 📐 DocumentRequestTest | Feature | Parent requests TC; admin receives notification; request tracked | Medium |
| 10 | 📐 NotificationPreferencesTest | Feature | Parent disables FeeReminder SMS; SMS not sent on next fee event | Medium |
| 11 | 📐 QuietHoursTest | Feature | Non-urgent notification at quiet hours → not dispatched | Medium |
| 12 | 📐 ReportCardAccessControlTest | Feature | Report card not downloadable before school publishes | High |
| 13 | 📐 MultiDeviceTokenTest | Feature | Login on second device → first device token deactivated | Low |
| 14 | 📐 EventRsvpTest | Feature | RSVP for event; confirmation notification dispatched | Medium |

---

## 11. Known Issues & Technical Debt

| ID | Issue | Severity | Notes |
|---|---|---|---|
| 📐 | IDOR vulnerability risk — identical to confirmed bug in StudentPortal | CRITICAL | Must enforce ParentChildPolicy on EVERY data endpoint before launch |
| 📐 | Performance: Dashboard aggregates data from 5+ modules; N+1 risk | High | Use eager loading and dedicated ParentDashboardService with query optimisation |
| 📐 | Teacher message list: requires timetable module to be active to build teacher dropdown | Medium | Fallback: allow parent to search teachers if timetable unavailable |
| 📐 | Transport live tracking requires GPS hardware + Transport module APIs | Medium | Show static route info if live GPS unavailable |
| 📐 | Counsellor report visibility gated on school settings — default should be OFF (privacy-first) | High | Default sys_school_settings.parent_counsellor_report_visibility = 0 |
| 📐 | Razorpay webhook for fee payment needs idempotency key (prevent double credit) | High | Mirrors fin_* Payment module pattern — use razorpay_payment_id uniqueness check |
| 📐 | Leave application: when leave approved, school attendance module must be notified | Medium | Event dispatch to attendance module on leave approval |

---

## 12. API Endpoints

| Method | URI | Name | Description |
|---|---|---|---|
| 📐 GET | /api/v1/parent/dashboard | api.ppt.dashboard | Dashboard summary data (JSON) |
| 📐 GET | /api/v1/parent/children | api.ppt.children | List parent's children |
| 📐 POST | /api/v1/parent/switch-child | api.ppt.switch-child | Set active child context |
| 📐 GET | /api/v1/parent/attendance/{studentId} | api.ppt.attendance | Child's attendance for month/year |
| 📐 GET | /api/v1/parent/fees/{studentId} | api.ppt.fees | Outstanding fee invoices |
| 📐 POST | /api/v1/parent/fees/pay | api.ppt.fees.pay | Initiate Razorpay payment |
| 📐 POST | /api/v1/parent/fees/razorpay-callback | api.ppt.fees.callback | Razorpay webhook handler |
| 📐 GET | /api/v1/parent/messages | api.ppt.messages | List message threads |
| 📐 POST | /api/v1/parent/messages | api.ppt.messages.store | Send message to teacher |
| 📐 GET | /api/v1/parent/notifications | api.ppt.notifications | Notification inbox |
| 📐 POST | /api/v1/parent/device-token | api.ppt.device-token | Register/update FCM/APNs token |

All API endpoints: middleware `auth:sanctum`, prefix `/api/v1/parent`, additional gate: parent-portal access check

---

## 13. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Security (P0) | ALL data endpoints must enforce ParentChildPolicy. No child's data is accessible without a verified guardian→child link. |
| Performance | Dashboard aggregation must complete in < 3 seconds using caching (Laravel Cache, TTL 5 minutes) for non-realtime data |
| Concurrency | Fee payment uses DB transaction + Razorpay idempotency key to prevent double-payment |
| Privacy | Counsellor psychological notes default-hidden from parents; medical records gated by consent flags |
| Mobile-first | All views must be responsive; portal primarily used on mobile devices |
| PDF | Report cards and fee receipts generated via DomPDF with school letterhead |
| QR | Not used in this module |
| Notifications | FCM (Android) + APNs (iOS) via Laravel Notification channels; fallback to SMS via Twilio/MSG91 |
| Session | Active child stored in PHP session; session invalidated on logout |
| HTTPS | All portal traffic must be HTTPS; no mixed content |

---

## 14. Integration Points

| Module | Integration Type | Specific Data |
|---|---|---|
| StudentProfile (std_*) | Read FK | std_students, std_guardians, std_student_guardian_jnt, std_health_records |
| StudentFee (fin_*) | Read + Write | fin_fee_invoices (read dues), fin_transactions (write on payment) |
| Payment | Read + Write | Razorpay order creation, webhook handling (mirrors STP/FIN pattern) |
| SmartTimetable (tt_*) | Read | Published timetable for child's class+section |
| LmsHomework | Read | Homework assignments for child's class+section |
| LmsExam | Read | Exam results, report card data |
| Attendance (sch_*/std_*) | Read | Daily attendance records for child |
| HPC (hpc_*) | Read | Health records, physical assessment, counsellor reports |
| Transport (tpt_*) | Read | Student route assignment, bus GPS data |
| Notification (ntf_*) | Read + Dispatch | Inbox circulars; dispatch alerts, leave notifications |
| Event Engine | Read | Published events for RSVP and calendar |
| sys_media | Read + Write | Document vault files, message attachments |
| sys_school_settings | Read | Portal visibility flags, counsellor report access, quiet hours defaults |

---

## 15. Pending Work & Gap Analysis

### 15.1 Development Roadmap

| Phase | Tasks | Priority |
|---|---|---|
| Phase 1 — Auth & Foundation | Parent auth middleware, ParentChildPolicy, ppt_* migrations (5 tables), Models, Providers | Critical |
| Phase 2 — Dashboard | ParentPortalController, child switcher, dashboard aggregation service | Critical |
| Phase 3 — Academics | Attendance view, timetable view, homework tracker, results view | Critical |
| Phase 4 — Fee Management | Fee view, Razorpay payment, payment history, PDF receipt | Critical |
| Phase 5 — Communication | Teacher messaging (ppt_messages), notification inbox, preferences | High |
| Phase 6 — Leave & Documents | Leave application, document vault, document requests | High |
| Phase 7 — Events | Event calendar, RSVP, volunteer sign-up | Medium |
| Phase 8 — Health & Transport | HPC report view, transport tracking (if Transport module active) | Medium |
| Phase 9 — Mobile API | REST API endpoints for future React Native / Flutter mobile app | Low |
| Phase 10 — Testing | Security tests (IDOR), payment flow tests, notification tests | Critical |

### 15.2 Dependencies on Other Modules

| Dependency | Status | Impact |
|---|---|---|
| SmartTimetable (tt_*) | ~100% complete | Phase 3 timetable view available immediately |
| LmsHomework | ~85% complete | Phase 3 homework view available with minor gaps |
| LmsExam | ~85% complete | Phase 3 results view available with minor gaps |
| Transport (tpt_*) | ~70% complete | Phase 8 transport view needs Transport module completion |
| HPC (hpc_*) | ~90% complete | Phase 8 health reports available |
| Event Engine | ~20% complete | Phase 7 events view requires Event Engine completion |

### 15.3 Open Design Decisions

| Decision | Options | Recommendation |
|---|---|---|
| Multi-child session handling | Laravel Session vs DB ppt_parent_sessions.active_student_id | Laravel Session for speed; DB fallback for multi-device sync |
| Message threading model | Simple list vs email-like threads | Thread model (thread_id hash) — cleaner conversation view |
| Dashboard caching | No cache vs 5-min cache vs real-time | 5-minute Laravel Cache for non-realtime data; attendance today = no cache |
| Payment flow | In-portal redirect vs same-page AJAX Razorpay checkout | Razorpay hosted checkout page (simpler, PCI-compliant) |
| Counsellor report visibility | Default ON vs Default OFF | Default OFF (privacy-first); school explicitly enables per-student |

---

*RBS Reference: Module Z — Parent Portal & Mobile App (ST.Z1.1.1.1 – ST.Z6.1.2.2)*
*Document generated: 2026-03-25 | Status: Greenfield — All features 📐 Proposed*
