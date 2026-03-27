# PPT — Parent Portal Module Feature Specification
**Version:** 1.0 | **Date:** 2026-03-27 | **Mode:** Greenfield (0% code)
**Roles:** Business Analyst + DB Architect | **Source:** PPT_ParentPortal_Requirement.md v2

---

## Section 1 — Module Identity & Scope

### 1.1 Identity

| Field | Value |
|---|---|
| Module Code | PPT |
| Module Name | ParentPortal |
| Laravel Namespace | `Modules\ParentPortal` |
| Route Prefix | `parent-portal/` |
| Route Name Prefix | `ppt.` |
| DB Table Prefix | `ppt_` (6 owned tables) |
| Auth Mechanism | Custom `parent.portal` middleware (NOT Spatie roles) |
| Module Type | Parent/guardian-facing portal — separate from admin backend and StudentPortal (STP) |
| Status | 0% — Greenfield |

### 1.2 Module Scale

| Artifact | Current | Target |
|---|---|---|
| Controllers | 0 | 16 + AuthController = 17 |
| Services | 0 | 5 |
| FormRequests | 0 | 9 |
| Policies | 0 | 3 |
| Middleware | 0 | 1 (`parent.portal`) |
| Blade Views | 0 | ~45 |
| Web Routes | 0 | ~75 |
| API Endpoints | 0 | ~18 |
| Tables Owned (ppt_*) | 0 | 6 |
| Tables Consumed (external) | — | 30+ |

### 1.3 In-Scope Features (All 18 FRs)

1. FR-PPT-01 — Multi-Child Dashboard
2. FR-PPT-02 — OTP-Based Passwordless Login
3. FR-PPT-03 — Smart Notification Preferences
4. FR-PPT-04 — Teacher Messaging (ppt_messages)
5. FR-PPT-05 — Fee Management & Online Payment (Razorpay)
6. FR-PPT-06 — Attendance View (calendar + subject-wise)
7. FR-PPT-07 — Homework Tracker
8. FR-PPT-08 — Timetable View
9. FR-PPT-09 — Academic Results & Report Cards
10. FR-PPT-10 — Leave Application (ppt_leave_applications)
11. FR-PPT-11 — Digital Consent Forms (ppt_consent_form_responses)
12. FR-PPT-12 — PTM Scheduling (race-condition-safe)
13. FR-PPT-13 — Event Calendar & RSVP (ppt_event_rsvps)
14. FR-PPT-14 — Health & HPC Reports (gated)
15. FR-PPT-15 — Transport Tracking
16. FR-PPT-16 — Document Vault & Requests (ppt_document_requests)
17. FR-PPT-17 — Notification Inbox & Circulars
18. FR-PPT-18 — Account Settings

### 1.4 Out-of-Scope (V2)

- Admin student management — STD module
- Fee structure management — FIN module
- Payment processing logic — Payment module
- Attendance marking — ACD/STD module
- Homework creation — HMW module
- Direct video/audio calling (WebRTC)
- Parent-to-parent social messaging
- Native mobile app (PPT is PWA; native = separate initiative)

### 1.5 Tables Owned

| Table | Purpose |
|---|---|
| `ppt_parent_sessions` | Per-device portal state, active child, FCM/APNs/WebPush tokens, notification prefs, quiet hours |
| `ppt_messages` | Parent-teacher direct messages scoped to child context; thread-based with FULLTEXT search |
| `ppt_leave_applications` | Leave applications submitted by parent on behalf of child |
| `ppt_event_rsvps` | Parent RSVPs and volunteer sign-ups for school events |
| `ppt_document_requests` | Online requests for duplicate certificates |
| `ppt_consent_form_responses` | Parent responses to digital consent forms (immutable after signing) |

### 1.6 Key External Tables Consumed (30+ tables)

`std_students`, `std_guardians`, `std_student_guardian_jnt`, `std_health_profiles`, `std_vaccination_records`, `fee_invoices`, `fee_installments`, `fee_transactions`, `tt_timetable_cells`, `tt_published_timetables`, `hmw_assignments`, `hmw_submissions`, `exm_results`, `exm_report_cards`, `std_attendance`, `std_subject_attendance`, `hpc_*` (own module DDL), `tpt_routes`, `tpt_vehicles`, `tpt_student_route_jnt`, `sys_users`, `sys_media`, `sys_school_settings`, `ntf_notifications`, `ntf_circulars`, `sys_activity_logs`

---

## Section 2 — Screens Inventory (All 38 Screens)

All status: 🆕 To Build (greenfield)

### 2.1 Auth

| # | Screen Name | Route Name | View File | FR Ref | Controller@Method | Complexity |
|---|---|---|---|---|---|---|
| SCR-PPT-01 | Login (OTP/Password) | `ppt.login` | `parentportal::auth.login` | FR-PPT-02 | `AuthController@login` | Medium |
| SCR-PPT-02 | OTP Verification | `ppt.otp.verify` | `parentportal::auth.otp-verify` | FR-PPT-02 | `AuthController@verifyOtp` | Medium |

**Data:** SCR-PPT-01 — mobile number field, password field toggle; SCR-PPT-02 — 6-digit OTP entry, 10-minute countdown, resend button.

### 2.2 Dashboard & Navigation

| # | Screen Name | Route Name | View File | FR Ref | Controller@Method | Complexity |
|---|---|---|---|---|---|---|
| SCR-PPT-03 | Dashboard | `ppt.dashboard` | `parentportal::dashboard` | FR-PPT-01 | `ParentPortalController@dashboard` | Complex |
| SCR-PPT-04 | Child Switcher | `ppt.children` | `parentportal::children.index` | FR-PPT-01 | `ParentPortalController@children` | Simple |

**Data:** SCR-PPT-03 — child cards (photo/name/class/attendance status), active child snapshot (attendance%, last test, pending homework, fee due), today's timetable, transport status; served by `ParentDashboardService`. SCR-PPT-04 — linked children list, POST switch action.

### 2.3 Academic

| # | Screen Name | Route Name | View File | FR Ref | Controller@Method | Complexity |
|---|---|---|---|---|---|---|
| SCR-PPT-05 | Attendance Calendar | `ppt.attendance.index` | `parentportal::attendance.index` | FR-PPT-06 | `AttendanceViewController@index` | Medium |
| SCR-PPT-06 | Subject-wise Attendance | `ppt.attendance.subject-wise` | `parentportal::attendance.subject-wise` | FR-PPT-06 | `AttendanceViewController@subjectWise` | Medium |
| SCR-PPT-07 | Timetable | `ppt.timetable.index` | `parentportal::timetable.index` | FR-PPT-08 | `TimetableViewController@index` | Medium |
| SCR-PPT-08 | Homework List | `ppt.homework.index` | `parentportal::homework.index` | FR-PPT-07 | `HomeworkViewController@index` | Medium |
| SCR-PPT-09 | Homework Detail | `ppt.homework.show` | `parentportal::homework.show` | FR-PPT-07 | `HomeworkViewController@show` | Simple |
| SCR-PPT-10 | Results List | `ppt.results.index` | `parentportal::results.index` | FR-PPT-09 | `ResultViewController@index` | Medium |
| SCR-PPT-11 | Result Detail | `ppt.results.show` | `parentportal::results.show` | FR-PPT-09 | `ResultViewController@show` | Simple |
| SCR-PPT-12 | Report Card Download | `ppt.results.report-card` | `parentportal::results.report-card` | FR-PPT-09 | `ResultViewController@downloadReportCard` | Medium |

**External deps:** STD (attendance), TT (timetable), HMW (homework), EXM (results) — all soft dependencies with graceful degradation.

### 2.4 Finance

| # | Screen Name | Route Name | View File | FR Ref | Controller@Method | Complexity |
|---|---|---|---|---|---|---|
| SCR-PPT-13 | Fee Summary | `ppt.fees.index` | `parentportal::fees.index` | FR-PPT-05 | `FeeViewController@index` | Complex |
| SCR-PPT-14 | Razorpay Checkout | `ppt.fees.pay` | `parentportal::fees.pay` | FR-PPT-05 | `FeeViewController@pay` | Complex |
| SCR-PPT-15 | Payment Success | `ppt.fees.success` | `parentportal::fees.success` | FR-PPT-05 | `FeeViewController@razorpayCallback` | Medium |
| SCR-PPT-16 | Payment History | `ppt.fees.history` | `parentportal::fees.history` | FR-PPT-05 | `FeeViewController@history` | Medium |

**Data:** Reads `fee_invoices` (via `student_assignment_id → fee_student_assignments.student_id`) + `fee_transactions`. ⚠️ See Section 3 for IDOR ownership chain.

### 2.5 Communication

| # | Screen Name | Route Name | View File | FR Ref | Controller@Method | Complexity |
|---|---|---|---|---|---|---|
| SCR-PPT-17 | Message Inbox | `ppt.messages.index` | `parentportal::messages.index` | FR-PPT-04 | `MessageController@index` | Medium |
| SCR-PPT-18 | Message Thread | `ppt.messages.thread` | `parentportal::messages.thread` | FR-PPT-04 | `MessageController@thread` | Medium |
| SCR-PPT-19 | Compose Message | `ppt.messages.compose` | `parentportal::messages.compose` | FR-PPT-04 | `MessageController@compose` | Medium |
| SCR-PPT-20 | Notification Inbox | `ppt.notifications.index` | `parentportal::notifications.index` | FR-PPT-17 | `NotificationController@index` | Medium |
| SCR-PPT-21 | Notification Detail | `ppt.notifications.show` | `parentportal::notifications.show` | FR-PPT-17 | `NotificationController@show` | Simple |
| SCR-PPT-22 | Notification Preferences | `ppt.notifications.preferences` | `parentportal::notifications.preferences` | FR-PPT-03 | `NotificationController@preferences` | Medium |

**Data:** SCR-PPT-17/18/19 write to `ppt_messages`; teacher list from timetable (soft dep). SCR-PPT-20/21 reads `ntf_notifications`, `ntf_circulars`. SCR-PPT-22 writes `ppt_parent_sessions.notification_preferences_json`.

### 2.6 Requests & Forms

| # | Screen Name | Route Name | View File | FR Ref | Controller@Method | Complexity |
|---|---|---|---|---|---|---|
| SCR-PPT-23 | Leave List | `ppt.leave.index` | `parentportal::leave.index` | FR-PPT-10 | `LeaveController@index` | Simple |
| SCR-PPT-24 | Apply Leave | `ppt.leave.create` | `parentportal::leave.create` | FR-PPT-10 | `LeaveController@create` + `store` | Medium |
| SCR-PPT-25 | Leave Status | `ppt.leave.show` | `parentportal::leave.show` | FR-PPT-10 | `LeaveController@show` | Simple |
| SCR-PPT-26 | Consent Forms List | `ppt.consent-forms.index` | `parentportal::consent-forms.index` | FR-PPT-11 | `ConsentFormController@index` | Simple |
| SCR-PPT-27 | Consent Form Detail | `ppt.consent-forms.show` | `parentportal::consent-forms.show` | FR-PPT-11 | `ConsentFormController@show` + `sign` | Medium |

### 2.7 Meetings & Events

| # | Screen Name | Route Name | View File | FR Ref | Controller@Method | Complexity |
|---|---|---|---|---|---|---|
| SCR-PPT-28 | PTM Events | `ppt.ptm.index` | `parentportal::ptm.index` | FR-PPT-12 | `PtmController@index` | Medium |
| SCR-PPT-29 | PTM Slot Booking | `ppt.ptm.slots` | `parentportal::ptm.slots` | FR-PPT-12 | `PtmController@slots` + `book` | Complex |
| SCR-PPT-30 | Event Calendar | `ppt.events.index` | `parentportal::events.index` | FR-PPT-13 | `EventController@index` | Medium |
| SCR-PPT-31 | Event Detail | `ppt.events.show` | `parentportal::events.show` | FR-PPT-13 | `EventController@show` + `rsvp` + `volunteerSignup` | Medium |

**PTM note:** SCR-PPT-29 requires `DB::transaction() + lockForUpdate()` — race condition safe (BR-PPT-015).

### 2.8 Health & Info

| # | Screen Name | Route Name | View File | FR Ref | Controller@Method | Complexity |
|---|---|---|---|---|---|---|
| SCR-PPT-32 | Health Overview | `ppt.health-reports.index` | `parentportal::health-reports.index` | FR-PPT-14 | `HealthReportController@index` | Medium |
| SCR-PPT-33 | Health Report Detail | `ppt.health-reports.show` | `parentportal::health-reports.show` | FR-PPT-14 | `HealthReportController@show` | Medium |
| SCR-PPT-34 | Transport Info | `ppt.transport.index` | `parentportal::transport.index` | FR-PPT-15 | `TransportViewController@index` | Simple |
| SCR-PPT-35 | Document Vault | `ppt.documents.index` | `parentportal::documents.index` | FR-PPT-16 | `DocumentController@index` | Medium |
| SCR-PPT-36 | Document Request Form | `ppt.documents.request` | `parentportal::documents.request` | FR-PPT-16 | `DocumentController@requestForm` + `storeRequest` | Medium |
| SCR-PPT-37 | Document Request Status | `ppt.documents.track` | `parentportal::documents.track` | FR-PPT-16 | `DocumentController@trackRequest` | Simple |

**Gated features:** SCR-PPT-32/33 gated by school setting (`parent_counsellor_report_visibility`) and per-record `parent_visible` flag — see Section 3 for DDL gap note.

### 2.9 Settings

| # | Screen Name | Route Name | View File | FR Ref | Controller@Method | Complexity |
|---|---|---|---|---|---|---|
| SCR-PPT-38 | Account Settings | `ppt.settings.index` | `parentportal::settings.index` | FR-PPT-18 | `AccountSettingsController@index` | Medium |

---

## Section 3 — Security Architecture Matrix

| # | Requirement | Category | Priority | Enforcement Point | Implementation |
|---|---|---|---|---|---|
| 1 | ⚠️ **IDOR — ParentChildPolicy** on EVERY data request | IDOR | P0 | Laravel Policy on every controller method | `$this->authorize('viewChildData', $student)` — verifies `std_student_guardian_jnt` WHERE `guardian.user_id = auth()->id()` AND `can_access_parent_portal = 1` |
| 2 | ⚠️ **Fee payment IDOR** — parent pays own child's invoice only | IDOR | P0 | `FeePaymentRequest::authorize()` + `ParentChildPolicy::payInvoice()` | `fee_invoices` has NO direct `student_id` — chain: `fee_invoices.student_assignment_id → fee_student_assignments.student_id` |
| 3 | ⚠️ **Custom `parent.portal` middleware** — three-condition check | Auth | P0 | Middleware on every route group | Condition 1: `user_type=PARENT`; Condition 2: `std_guardians` record exists; Condition 3: `std_student_guardian_jnt.can_access_parent_portal=1`. **Returns 404 (not 401/403)** to prevent portal enumeration |
| 4 | ⚠️ **Multi-child context verify** per request | IDOR | P0 | `ppt_parent_sessions.active_student_id` DB (not session) | Every data endpoint verifies `active_student_id` is in guardian's allowed children list. Enforced via middleware + service layer |
| 5 | ⚠️ **OTP rate limiting** — 3-tier | Auth | P0 | `AuthController` + Laravel `RateLimiter` | `throttle:3,1` on OTP send (3/hour/mobile); max 3 OTP attempts per code (10-min expiry); `RateLimiter::hit('otp-lockout:'.$mobile, 1800)` after 5 failures (30-min lockout) |
| 6 | ⚠️ **Razorpay idempotency** — webhook replay protection | Payment | P0 | `FeeViewController::razorpayCallback()` + DB unique | `payment_reference` UNIQUE nullable on `ppt_document_requests`; for fee payments, check `fin_transactions` payment_id uniqueness before writing |
| 7 | **Signed URLs** — document downloads | Document | P1 | `DocumentController` | `Storage::temporaryUrl($path, now()->addHours(24))` — 24-hour expiry; prevents link sharing |
| 8 | **Counsellor report gate** | Privacy | P1 | `HealthReportController` + Settings | `sys_school_settings.parent_counsellor_report_visibility = 1` required; default = 0 (hidden) |
| 9 | **Medical record gate** | Privacy | P1 | `HealthReportController` + DDL flag | Per-record `parent_visible = 1` required — ⚠️ **DDL GAP**: `std_health_profiles` in tenant_db_v2.sql has NO `parent_visible` column; must add via migration |
| 10 | **Quiet hours enforcement** | Notifications | P1 | `NotificationPreferenceService` | Buffer non-urgent; `AbsenceAlert` + `EmergencyAlert` ALWAYS bypass |
| 11 | **CSRF protection** | Web Security | P0 | Laravel CSRF middleware (default) | All POST/PUT/DELETE routes protected; Razorpay webhook uses `withoutMiddleware(['web'])` |
| 12 | **Audit logging** | Audit | P2 | Controllers + `sys_activity_logs` | All parent actions: view, payment, message, leave logged via `SysActivityLog::record()` |
| 13 | **Consent form immutability** | Data Integrity | P1 | DB unique constraint + no update path | `uq_ppt_consent_response (consent_form_id, student_id, guardian_id)` — prevents double-sign; no UPDATE allowed after creation |
| 14 | **Per-guardian API rate limit** | API Security | P2 | Route middleware | `throttle:60,1` on all `/api/v1/parent/*` routes |

### 3.1 Critical DDL Findings (Verified Against `tenant_db_v2.sql`)

| Item | Status | Finding | Impact |
|---|---|---|---|
| `std_student_guardian_jnt.can_access_parent_portal` | ✅ CONFIRMED | `TINYINT(1) DEFAULT 0` at line 5982 | Core auth chain works as designed |
| `sys_users.id` type | ✅ CONFIRMED | `INT UNSIGNED` (NOT BIGINT) | `sender_user_id`, `recipient_user_id` in `ppt_messages` = `INT UNSIGNED` |
| `fee_invoices` table name | ⚠️ MISMATCH | Table is `fee_invoices` (no `fin_` prefix); req uses `fin_fee_invoices` | Use `fee_invoices` in all code/queries |
| `fee_invoices.student_id` | ⚠️ ABSENT | No direct `student_id` on `fee_invoices`; ownership via `student_assignment_id → fee_student_assignments.student_id` | `FeePaymentRequest::authorize()` must use whereHas chain: `fee_invoices.student_assignment_id → fee_student_assignments.student_id` |
| `fee_invoices` status ENUM | ✅ CONFIRMED | `'Draft','Published','Partially Paid','Paid','Overdue','Cancelled'` — NO 'Unpaid' value | Use `in_array($status, ['Published', 'Partially Paid', 'Overdue'])` for payable check |
| `fee_invoices.balance_amount` | ✅ CONFIRMED | `GENERATED ALWAYS AS (total_amount - paid_amount) STORED` | Cannot write directly; computed |
| `fee_transactions` table name | ⚠️ MISMATCH | Table is `fee_transactions` (no `fin_` prefix) | Use `fee_transactions` in code |
| `std_health_profiles` | ⚠️ MISMATCH | Table is `std_health_profiles` (not `std_health_records`); no `parent_visible` column | P1 requires adding `parent_visible TINYINT(1) DEFAULT 0` via migration |
| `hpc_*` tables | ⚠️ NOT IN MAIN DDL | HPC module has its own DDL (`5-Work-In-Progress/14-HPC`) | Reference HPC module DDL separately for health/physical/counsellor report tables |

### 3.2 Fee Invoice Ownership Chain (P0 Critical)

```
auth()->user()
    └── guardian (std_guardians, via user_id)
         └── studentGuardianJnts (std_student_guardian_jnt, can_access_parent_portal=1)
              └── students (std_students) — allowed children
                   └── active child
                        └── fee_student_assignments (student_id = active_child.id)
                             └── fee_invoices (student_assignment_id = fee_student_assignments.id)
```

**Authorization guard code:**
```php
// FeePaymentRequest::authorize()
$invoice = FeeInvoice::whereHas('studentAssignment',
    fn($q) => $q->whereIn('student_id', $this->allowedStudentIds())
)->where('status', '!=', 'Cancelled')
 ->where('status', '!=', 'Draft')
 ->find((int) $this->invoice_id);
if (!$invoice) return false;
if (!in_array($invoice->status, ['Published', 'Partially Paid', 'Overdue'])) return false;
if ($invoice->balance_amount <= 0) return false;
return true;
```

---

## Section 4 — Business Rules (All 18 Rules)

### Group 1 — Data Isolation (BR-PPT-001 to BR-PPT-003)

| Rule ID | Rule Text | Enforcement Point | Implementation |
|---|---|---|---|
| BR-PPT-001 | Parent can ONLY access data for children linked via `std_student_guardian_jnt` where `guardian.user_id = auth()->id()` AND `can_access_parent_portal = 1` | `ParentChildPolicy` on EVERY data request | Policy method: `viewChildData(User $user, Student $student): bool` — queries junction table |
| BR-PPT-002 | Fee payment: parent can only pay invoices for their own linked child | `FeePaymentRequest::authorize()` + `ParentChildPolicy::payInvoice()` | Ownership via `student_assignment_id` chain (no direct student_id on fee_invoices) |
| BR-PPT-003 | Messaging: parent can only message teachers who teach their active child's subjects | `ParentMessagePolicy` | Teacher list built from timetable assignment for child's class+section |

### Group 2 — Application Rules (BR-PPT-004 to BR-PPT-007)

| Rule ID | Rule Text | Enforcement Point | Implementation |
|---|---|---|---|
| BR-PPT-004 | Leave: `from_date` >= tomorrow; cannot apply for today or past dates | `ApplyLeaveRequest::rules()` | `'from_date' => 'required|date|after:today'` |
| BR-PPT-005 | Report card download: only after school admin publishes the term | `ResultViewController` publish gate | Check `exm_report_cards.is_published = 1` before serving PDF |
| BR-PPT-006 | Medical records visible ONLY if per-record `parent_visible = 1` | `HealthReportController` query filter | `->where('parent_visible', 1)` — ⚠️ column needs migration |
| BR-PPT-007 | Counsellor reports visible ONLY if `sys_school_settings.parent_counsellor_report_visibility = 1` | `HealthReportController` settings check | `app('school_settings')->get('parent_counsellor_report_visibility', false)` |

### Group 3 — Notification Rules (BR-PPT-008 to BR-PPT-009)

| Rule ID | Rule Text | Enforcement Point | Implementation |
|---|---|---|---|
| BR-PPT-008 | Quiet hours: non-urgent buffered; `AbsenceAlert` + `EmergencyAlert` ALWAYS bypass | `NotificationPreferenceService::shouldDeliver()` | Check alert type before checking quiet hours; bypass for AbsenceAlert + EmergencyAlert |
| BR-PPT-009 | Device tokens: on re-login update existing token; on logout set `is_active = 0` | `AccountSettingsController` | Upsert on `ppt_parent_sessions` by (guardian_id, device_type) |

### Group 4 — Multi-Child & Payments (BR-PPT-010 to BR-PPT-012)

| Rule ID | Rule Text | Enforcement Point | Implementation |
|---|---|---|---|
| BR-PPT-010 | Active child stored in `ppt_parent_sessions.active_student_id` (DB, not PHP session) for multi-device sync | Middleware + `ParentPortalController` | DB upsert on child switch; session variable used as fast cache only |
| BR-PPT-011 | Document request fee payment required when `fee_required > 0` | `DocumentController` fee gate | Check `ppt_document_requests.fee_required > 0` before returning download link |
| BR-PPT-012 | ⚠️ **IDOR prevention** on EVERY data endpoint — no exceptions | `ParentChildPolicy` enforced everywhere | `$this->authorize('viewChildData', $student)` in every controller method |

### Group 5 — Auth & Session Rules (BR-PPT-013 to BR-PPT-018)

| Rule ID | Rule Text | Enforcement Point | Implementation |
|---|---|---|---|
| BR-PPT-013 | OTP: max 3/hour/mobile + max 3 attempts per code (10-min expiry) + 30-min lockout after 5 failures | `AuthController` + `RateLimiter` | `RateLimiter::tooManyAttempts('otp-send:'.$mobile, 3)` per hour; attempt counter in cache; `RateLimiter::hit('otp-lockout:'.$mobile, 1800)` |
| BR-PPT-014 | Consent form: cannot sign the same form twice; deadline enforced | `ConsentFormController` + DB unique constraint | `uq_ppt_consent_response (consent_form_id, student_id, guardian_id)` — catches duplicate on DB level |
| BR-PPT-015 | PTM booking: one slot per teacher per PTM per guardian; slot released immediately on cancel | `PtmController` + `PtmSchedulingService` | `DB::transaction()` + `lockForUpdate()` |
| BR-PPT-016 | Volunteer sign-up: max capacity per role enforced | `EventController` | Count existing volunteers per role; block if at capacity |
| BR-PPT-017 | 🔗 Leave approval: on teacher approval, event dispatched to attendance module to mark dates as Leave | `LeaveController` event dispatch | `event(new LeaveApproved($leaveApplication))` — attended by attendance module listener |
| BR-PPT-018 | Fee payment idempotency: `payment_id` uniqueness prevents double-credit on webhook replay | `FeeViewController` + DB | Check `fee_transactions` for existing `payment_reference` before creating new transaction |

---

## Section 5 — Workflow Diagrams (6 FSMs)

### 5.1 OTP Login Flow

```
UNAUTHENTICATED
    │ Parent enters mobile number
    ├─ ⚠️ Rate limit check: RateLimiter::tooManyAttempts('otp-send:'.$mobile, 3)
    │       ├─ Limit reached → 429 + retry_after timer shown
    │       └─ Send OTP via SMS (MSG91/Twilio) → State: OTP_SENT (10-min TTL)
    │
OTP_SENT
    │ Parent enters 6-digit OTP
    │       ├─ ⚠️ Attempt counter check (max 3 attempts per code)
    │       ├─ Invalid → counter++ | counter=3 → abort code, prompt resend
    │       ├─ ⚠️ 5 consecutive failures → RateLimiter::hit('otp-lockout:'.$mobile, 1800)
    │       ├─ Expired → prompt resend
    │       └─ Valid → State: AUTHENTICATED
    │
AUTHENTICATED
    │       ├─ sys_users.password = NULL (first login) → Redirect to password setup
    │       └─ Returning user → Register/update FCM token → PORTAL_HOME (dashboard)
```

**Test refs:** T-01 (ParentAuthTest), T-02 (OtpRateLimitTest)

### 5.2 Fee Payment FSM

```
INVOICE (fee_invoices.status = Published | Partially Paid | Overdue)
    │ Parent selects invoice + clicks Pay
    │   ⚠️ FeePaymentRequest::authorize() — ownership via student_assignment chain
    │   ⚠️ balance_amount > 0 check (GENERATED column)
    ▼
PAYMENT_INITIATED
    │ FeePaymentService::initiatePayment() → Razorpay order created
    │ Razorpay hosted checkout opened
    │       ├─ ⚠️ Success callback: Razorpay signature HMAC verified server-side
    │       │       ├─ ⚠️ Idempotency: check fee_transactions for existing payment_id
    │       │       ├─ Create fee_transactions record
    │       │       ├─ Update fee_invoices.status = 'Paid' or 'Partially Paid'
    │       │       ├─ SMS receipt dispatched (queued)
    │       │       └─ PDF receipt generated (DomPDF)
    │       └─ Failure/Cancel → UNPAID (unchanged; parent retries)
```

**Test refs:** T-04 (FeePaymentAuthTest), T-05 (FeePaymentIdempotencyTest)

### 5.3 Leave Application FSM

```
Parent submits (ApplyLeaveRequest validated: from_date >= tomorrow ⚠️)
    ▼
PENDING
    │ Class teacher notified (in-app + email, queued)
    │       ├─ Teacher APPROVES
    │       │       ├─ status = 'Approved'
    │       │       └─ 🔗 event(new LeaveApproved($leave)) → Attendance module marks dates as Leave
    │       ├─ Teacher REJECTS
    │       │       ├─ status = 'Rejected'
    │       │       └─ reviewer_notes stored; parent notified
    │       └─ Parent WITHDRAWS (from PENDING only)
    │               └─ status = 'Withdrawn'
```

**Test refs:** T-11 (LeaveApplicationTest), T-12 (LeavePastDateTest), T-13 (LeaveApprovalTest), T-14 (LeaveRejectionTest)

### 5.4 Document Request FSM

```
SUBMITTED (status=Pending) → Admin reviews
    ▼
PROCESSING → Admin completes
    │
    ├─── fee_required > 0:
    │         ▼
    │     READY
    │         │ ⚠️ payment gate: parent pays via Razorpay
    │         │ idempotency check on payment_reference ⚠️
    │         ▼
    │     COMPLETED
    │         │ 🔗 fulfilled_media_id set; parent notified
    │         └─ ⚠️ Download link = Storage::temporaryUrl($path, now()->addHours(24))
    │
    └─── fee_required = 0:
              ▼
          COMPLETED (immediately downloadable)

Admin can REJECT at any stage → REJECTED (admin_notes required)
```

**Test refs:** T-20 (DocumentRequestTest), T-21 (DocumentRequestFeeTest)

### 5.5 Consent Form FSM

```
PUBLISHED (within deadline, unsigned)
    │ Parent views full form text
    │
    ├─── Sign:
    │       ├─ ConsentFormSignRequest validated (signer_name, strip_tags)
    │       ├─ ⚠️ deadline check: form.deadline_date >= today
    │       ├─ ⚠️ DB unique constraint: uq_ppt_consent_response (form+student+guardian)
    │       ├─ SIGNED — signed_at timestamp + signed_ip recorded (IMMUTABLE)
    │       └─ PDF confirmation generated; school admin notified
    │
    └─── Decline:
            ├─ decline_reason required
            └─ DECLINED — school admin notified

DEADLINE_PASSED → form = read-only; sign/decline buttons hidden
```

**Test refs:** T-15 (ConsentFormSignTest), T-16 (ConsentFormDeadlineTest)

### 5.6 PTM Slot Booking FSM

```
SLOT_AVAILABLE (unbooked slot for teacher in PTM event)
    │ Parent selects slot → PtmBookingRequest validated
    ▼
BOOKING_PENDING
    │ ⚠️ PtmSchedulingService::bookSlot():
    │   DB::transaction(function() {
    │       $slot = PtmSlot::lockForUpdate()->findOrFail($slotId);  // SELECT FOR UPDATE
    │       abort_if($slot->is_booked, 409, 'Slot just taken; please choose another');
    │       // ... mark booked, create booking record
    │   })
    │       ├─ Race condition won → BOOKED (confirmation to parent + teacher, queued)
    │       └─ Race condition lost → 409 Error: "Slot just taken"
    │
BOOKED
    │ Parent cancels (> 1 hour before PTM time) ✓
    │ ├─ SLOT_RELEASED → back to SLOT_AVAILABLE
    └─ ⚠️ Within 1 hour of PTM → LOCKED (cancellation rejected)
```

**Test refs:** T-17 (PtmBookingTest), T-18 (PtmDoubleBookingTest), T-19 (PtmCancellationTest)

---

## Section 6 — Functional Requirements Summary (18 FRs)

| FR ID | Name | Status | Controller@Method | ppt_* Tables Written | External Tables Read | Priority |
|---|---|---|---|---|---|---|
| FR-PPT-01 | Multi-Child Dashboard | 🆕 To Build | `ParentPortalController@dashboard` | `ppt_parent_sessions` (read active) | `std_students`, `std_student_guardian_jnt`, `std_attendance`, `tt_timetable_cells`, `hmw_assignments`, `fee_invoices`, `ntf_notifications` | P0 |
| FR-PPT-02 | OTP Login | 🆕 To Build | `AuthController@sendOtp,verifyOtp,login,logout` | `ppt_parent_sessions` (token) | `sys_users`, `std_guardians`, `std_student_guardian_jnt` | P0 |
| FR-PPT-03 | Notification Preferences | 🆕 To Build | `NotificationController@preferences,savePreferences` | `ppt_parent_sessions` (prefs JSON) | — | P1 |
| FR-PPT-04 | Teacher Messaging | 🆕 To Build | `MessageController@*` | `ppt_messages` | `sys_users` (teachers), `tt_timetable_cells` | P2 |
| FR-PPT-05 | Fee Management | 🆕 To Build | `FeeViewController@*` | — (writes `fee_transactions`) | `fee_invoices`, `fee_student_assignments`, `fee_installments`, `fee_transactions` | P1 — ⚠️ IDOR P0 |
| FR-PPT-06 | Attendance View | 🆕 To Build | `AttendanceViewController@*` | — | `std_attendance`, `std_subject_attendance` | P1 |
| FR-PPT-07 | Homework Tracker | 🆕 To Build | `HomeworkViewController@*` | — | `hmw_assignments`, `hmw_submissions` | P1 |
| FR-PPT-08 | Timetable View | 🆕 To Build | `TimetableViewController@*` | — | `tt_timetable_cells`, `tt_published_timetables` | P1 |
| FR-PPT-09 | Results & Report Cards | 🆕 To Build | `ResultViewController@*` | — | `exm_results`, `exm_report_cards` | P1 |
| FR-PPT-10 | Leave Application | 🆕 To Build | `LeaveController@*` | `ppt_leave_applications` | `std_students`, `sys_media` | P2 — 🔗 attendance |
| FR-PPT-11 | Consent Forms | 🆕 To Build | `ConsentFormController@*` | `ppt_consent_form_responses` | Event/activity consent records | P2 |
| FR-PPT-12 | PTM Scheduling | 🆕 To Build | `PtmController@*` | PTM bookings (event module tables) | PTM event records | P2 |
| FR-PPT-13 | Event Calendar & RSVP | 🆕 To Build | `EventController@*` | `ppt_event_rsvps` | Event engine event records | P3 |
| FR-PPT-14 | Health & HPC Reports | 🆕 To Build | `HealthReportController@*` | — | `hpc_*`, `std_health_profiles` | P3 — gated |
| FR-PPT-15 | Transport Tracking | 🆕 To Build | `TransportViewController@index` | — | `tpt_routes`, `tpt_vehicles`, `tpt_student_route_jnt` | P3 |
| FR-PPT-16 | Document Vault | 🆕 To Build | `DocumentController@*` | `ppt_document_requests` | `sys_media`, `fee_invoices` (for doc fees) | P3 |
| FR-PPT-17 | Notification Inbox | 🆕 To Build | `NotificationController@index,show,markRead,markAllRead` | — | `ntf_notifications`, `ntf_circulars` | P1 |
| FR-PPT-18 | Account Settings | 🆕 To Build | `AccountSettingsController@*` | `ppt_parent_sessions` | `std_guardians`, `sys_users` | P2 |

---

## Section 7 — External Module Dependencies Matrix

### 7.1 Hard Dependencies (portal broken if absent)

| Module | Tables/Models Used | Portal Feature(s) | Notes |
|---|---|---|---|
| STD (StudentProfile) | `std_students`, `std_guardians`, `std_student_guardian_jnt` | Core auth chain; every feature | `can_access_parent_portal` ✅ confirmed in DDL |
| SYS (System) | `sys_users`, `sys_media`, `sys_school_settings`, `sys_activity_logs` | Auth, documents, settings, audit | All confirmed in tenant_db_v2.sql |
| FIN (StudentFee) | `fee_invoices`, `fee_student_assignments`, `fee_transactions` | Fee view + payment | ⚠️ No `fin_` prefix in actual DDL |
| PAY (Payment) | Razorpay service | Online fee payment | Via `razorpay/razorpay` v2.9 |

### 7.2 Soft Dependencies (graceful degradation)

| Module | Tables | Feature Affected | Degradation |
|---|---|---|---|
| Smart Timetable | `tt_timetable_cells`, `tt_published_timetables` | Timetable view; teacher list | "Timetable not configured" card |
| LMS Homework | `hmw_assignments`, `hmw_submissions` | Homework tracker | "Homework module not enabled" card |
| LMS Exam | `exm_results`, `exm_report_cards` | Results, report cards | "Exam module not enabled" card |
| Attendance | `std_attendance`, `std_subject_attendance` | Attendance calendar | "Attendance data unavailable" card |
| HPC | `hpc_health_profiles`, `hpc_physical_assessments`, `hpc_counsellor_reports` | Health reports | Section hidden if HPC not active |
| Transport | `tpt_routes`, `tpt_vehicles`, `tpt_student_route_jnt` | Transport tracking | "Transport module not activated" card |
| Notification | `ntf_notifications`, `ntf_circulars` | Push notifications, inbox | Notification features disabled |
| Event Engine | Event records | Event calendar, RSVP | Empty calendar shown |

### 7.3 Core FK Chain

```
auth()->user() [sys_users, user_type=PARENT, id=INT UNSIGNED ✅]
    └── guardian [std_guardians, via user_id FK]
         └── studentGuardianJnts [std_student_guardian_jnt, can_access_parent_portal=1 ✅]
              └── students [std_students] — the allowed children
                   └── active child [ppt_parent_sessions.active_student_id]
                        ├── attendance [std_attendance]
                        ├── feeAssignments [fee_student_assignments] ← ⚠️ not std_students directly
                        │       └── feeInvoices [fee_invoices via student_assignment_id]
                        ├── timetableCells [tt_timetable_cells]
                        ├── homeworkAssignments [hmw_assignments]
                        ├── examResults [exm_results]
                        ├── healthProfile [std_health_profiles] ← ⚠️ not std_health_records
                        └── transportAllocation [tpt_student_route_jnt]
```

### 7.4 DDL Verification Summary

| Column/Table | Expected by Req | Actual in tenant_db_v2.sql | Action |
|---|---|---|---|
| `std_student_guardian_jnt.can_access_parent_portal` | ✅ | ✅ EXISTS | No action |
| `sys_users.id` type | INT UNSIGNED | ✅ INT UNSIGNED | No action — use INT UNSIGNED for all sender/recipient FK |
| `std_health_records.parent_visible` | ✅ expected | ❌ Table is `std_health_profiles`, no `parent_visible` column | P1 migration: add `parent_visible TINYINT(1) DEFAULT 0` to `std_health_profiles` |
| `fin_fee_invoices` | Used in req | ❌ Table is `fee_invoices` (no `fin_`) | Use `fee_invoices` everywhere |
| `fin_transactions` | Used in req | ❌ Table is `fee_transactions` (no `fin_`) | Use `fee_transactions` everywhere |
| `fee_invoices.student_id` | Expected by BR-PPT-002 | ❌ No direct `student_id` — via `student_assignment_id` | Use whereHas chain in all policies |
| `hpc_health_profiles` | Used in req Section 5.3 | ❌ Not in main DDL (HPC has own DDL) | Reference HPC module DDL; soft dep |

---

## Section 8 — Service Architecture (5 Services)

### 8.1 ParentDashboardService

```
File:    Modules/ParentPortal/app/Services/ParentDashboardService.php
Purpose: Aggregate all dashboard widgets for active child in ≤ 5 queries total
Cache:   Cache::tags(['parent', $guardianId])->remember(300, ...)  [5-min TTL]
Cache invalidation triggers: fee payment, leave status change, new message (clear tag)

Key Methods:
  getDashboardData(Guardian $guardian, Student $activeChild): array
    └── 1. Eager-load: $guardian->load([
              'studentGuardianJnts.student.currentAcademicSession.classSection.class',
              'studentGuardianJnts.student.currentAcademicSession.classSection.section'
           ])
        2. Attendance stats (current month): std_attendance
        3. Today's timetable: tt_timetable_cells (NOT cached)
        4. Pending homework count: hmw_assignments (scoped to class+section)
        5. Fee summary: fee_invoices via fee_student_assignments
        Returns: [child_cards, snapshot, today_timetable, transport_status, action_required]

  getChildSummary(Student $student): array
    └── Academic session, class, section, roll number (from eager-loaded data)

  getActionRequired(Guardian $guardian, Student $student): array
    └── Unpaid invoices + unsigned consent forms + pending leaves (3 quick queries)
```

### 8.2 FeePaymentService

```
File:    Modules/ParentPortal/app/Services/FeePaymentService.php
Purpose: Razorpay order creation, signature verification, payment recording

Key Methods:
  initiatePayment(Guardian $guardian, Student $student, array $invoiceIds): array
    └── Verify ownership (guardian→student→fee_student_assignments→fee_invoices)
        → Razorpay order create via API
        → Return [order_id, razorpay_key, amount, currency]

  verifyAndRecord(array $razorpayPayload): bool
    └── HMAC SHA256 signature verify (razorpay_order_id + "|" + razorpay_payment_id)
        → ⚠️ Idempotency: check fee_transactions WHERE payment_reference = $razorpayPaymentId
        → Create fee_transactions record (status=Success)
        → Update fee_invoices.status to 'Paid' or 'Partially Paid'
        → Dispatch receipt notification (queued)
```

### 8.3 MessagingService

```
File:    Modules/ParentPortal/app/Services/MessagingService.php
Purpose: Thread-based parent-teacher messaging with ownership enforcement

Key Methods:
  getOrCreateThread(int $guardianId, int $teacherUserId, int $studentId): string
    └── thread_id = MD5($guardianId . '_' . $teacherUserId . '_' . $studentId)

  getAllowedTeachers(Student $student): Collection
    └── Teachers from timetable assignments for child's class+section
        (via tt_timetable_cells → teacher user IDs)
        Fallback: search all staff if timetable unavailable

  storeMessage(ComposeMessageRequest $request, Guardian $guardian): PptMessage
    └── Verify teacher is in getAllowedTeachers(activeChild) — ParentMessagePolicy
        → Create ppt_messages record (direction=Parent_to_Teacher)
        → Dispatch in-app notification to teacher_user_id (queued)
```

### 8.4 NotificationPreferenceService

```
File:    Modules/ParentPortal/app/Services/NotificationPreferenceService.php
Purpose: Evaluate notification delivery considering prefs and quiet hours

Key Methods:
  shouldDeliver(PptParentSession $session, string $alertType, string $channel): bool
    └── ⚠️ AbsenceAlert + EmergencyAlert ALWAYS return true (bypass quiet hours)
        → Check preferences JSON for alertType+channel toggle
        → Check current time vs quiet_hours_start/quiet_hours_end

  savePreferences(Guardian $guardian, array $preferences): void
    └── Upsert ppt_parent_sessions.notification_preferences_json (all active sessions)

  getQuietHoursBuffer(): Collection
    └── Return buffered notifications waiting for quiet period end (cron-triggered)
```

### 8.5 PtmSchedulingService

```
File:    Modules/ParentPortal/app/Services/PtmSchedulingService.php
Purpose: Race-condition-safe PTM slot booking

Key Methods:
  getAvailableSlots(int $ptmEventId, int $teacherUserId): Collection
    └── Return unbooked slots for teacher in PTM event

  bookSlot(PtmBookingRequest $request, Guardian $guardian): object
    └── DB::transaction(function() {
            $slot = PtmSlot::lockForUpdate()->findOrFail($request->slot_id);
            abort_if($slot->is_booked, 409, 'Slot just taken; please choose another');
            $slot->update(['is_booked' => 1, 'booked_by_guardian_id' => $guardian->id]);
            // create booking record, dispatch confirmations
        })

  cancelBooking(int $bookingId, Guardian $guardian): bool
    └── Verify guardian owns booking
        → Check: booking_time >= now() + 1 hour (else reject cancellation)
        → Mark slot as unbooked; notify teacher
```

---

## Section 9 — FormRequest Architecture (9 FormRequests)

| # | Class | Controller@Method | authorize() Logic | Key Rules | Phase |
|---|---|---|---|---|---|
| 1 | `SwitchChildRequest` | `ParentPortalController@switchChild` | Verify `student_id` is in guardian's allowed children via `std_student_guardian_jnt` | `student_id` required\|integer\|exists:std_students,id | P0 |
| 2 | `FeePaymentRequest` | `FeeViewController@pay,apiPay` | ⚠️ Invoice ownership via `fee_student_assignments` chain; status must be payable; balance > 0 | `invoice_ids` required\|array; each exists:fee_invoices,id + ownership; `total_amount` numeric\|min:0.01 | P0 — IDOR guard |
| 3 | `ComposeMessageRequest` | `MessageController@store,apiStore` | `parent.portal` middleware handles auth; verify recipient is allowed teacher via `MessagingService::getAllowedTeachers()` | `recipient_user_id` required; `subject` max:200; `message_body` min:10\|max:5000; `attachments` nullable\|array\|max:3; each mimes:pdf,jpg,png,doc + max:5120 | P2 |
| 4 | `ApplyLeaveRequest` | `LeaveController@store` | `parent.portal` + active child verified via `ParentChildPolicy` | `from_date` after:today; `to_date` after_or_equal:from_date; `leave_type` in enum; `reason` min:20\|max:1000 | P2 |
| 5 | `EventRsvpRequest` | `EventController@rsvp,volunteerSignup` | `parent.portal` middleware | `event_id` required; `rsvp_status` in:Attending,Not_Attending,Maybe; `is_volunteer` boolean; `volunteer_role` required_if:is_volunteer,true | P3 |
| 6 | `DocumentRequestForm` | `DocumentController@storeRequest` | `parent.portal` + active child verified | `document_type` in:TC,MarkSheet,Bonafide,Character,Migration,MedicalFitness,Other; `reason` min:20; `urgency` in:Normal,Urgent | P3 |
| 7 | `NotificationPreferencesRequest` | `NotificationController@savePreferences` | `parent.portal` middleware | `preferences` required\|array (validated against allowed alert types); `quiet_hours_start` nullable\|date_format:H:i; `quiet_hours_end` required_with:quiet_hours_start | P2 |
| 8 | `ConsentFormSignRequest` | `ConsentFormController@sign` | `parent.portal` + active child verified + deadline not passed | `response` in:Signed,Declined; `decline_reason` required_if:response,Declined\|min:10; `signer_name` min:3\|max:150; `prepareForValidation()`: strip_tags on signer_name | P2 |
| 9 | `PtmBookingRequest` | `PtmController@book` | `parent.portal` + active child verified | `ptm_event_id` required\|exists; `slot_id` required\|integer; `teacher_user_id` required\|exists:sys_users,id | P2 |

---

## Section 10 — Policy Architecture (3 Policies)

### 10.1 ParentChildPolicy (Core — applied on every data request)

```
File: Modules/ParentPortal/app/Policies/ParentChildPolicy.php
Registration: Gate::policy(Student::class, ParentChildPolicy::class)
              (in ParentPortalServiceProvider::boot())
```

| Method | Arguments | Authorization Logic |
|---|---|---|
| `viewChildData` | User, Student | `std_student_guardian_jnt` WHERE `guardian.user_id = user.id` AND `student_id = student.id` AND `can_access_parent_portal = 1` AND `is_active = 1` |
| `isActiveChild` | User, Student | `viewChildData()` + `ppt_parent_sessions.active_student_id = student.id` for this guardian |
| `viewHealthRecord` | User, Student, $record | `viewChildData()` + `data_get($record, 'parent_visible', false) === 1` |
| `viewCounsellorReport` | User | `sys_school_settings.parent_counsellor_report_visibility = 1` |
| `payInvoice` | User, Student, FeeInvoice | `viewChildData()` + `fee_invoices` linked via `fee_student_assignments.student_id = student.id` + `status` in `['Published','Partially Paid','Overdue']` + `balance_amount > 0` |

### 10.2 ParentMessagePolicy

```
File: Modules/ParentPortal/app/Policies/ParentMessagePolicy.php
```

| Method | Arguments | Authorization Logic |
|---|---|---|
| `composeMessage` | User, User $teacher | `ParentChildPolicy::viewChildData()` passes + teacher is in `MessagingService::getAllowedTeachers($activeChild)` — teaches at least one subject for child's class+section |
| `viewThread` | User, string $threadId | Reconstruct expected thread_id = MD5(guardian_id + "_" + teacher_id + "_" + student_id); verify guardian_id belongs to auth user |

### 10.3 ParentLeavePolicy

```
File: Modules/ParentPortal/app/Policies/ParentLeavePolicy.php
```

| Method | Arguments | Authorization Logic |
|---|---|---|
| `apply` | User, Student | Delegates to `ParentChildPolicy::viewChildData()` |
| `withdraw` | User, PptLeaveApplication | `leaveApplication.guardian_id = auth()->user()->guardian->id` AND `leaveApplication.status = 'Pending'` (can only withdraw from Pending state) |

### 10.4 ServiceProvider Registration

```php
// ParentPortalServiceProvider::boot()
$router->aliasMiddleware('parent.portal', EnsureParentPortalAccess::class);
Gate::policy(Student::class, ParentChildPolicy::class);
// ParentMessagePolicy and ParentLeavePolicy registered as needed per controller
```

---

## Section 11 — Test Plan Outline

### 11.1 P0 Security Tests (6 scenarios — Critical — MUST PASS before P1 begins)

| # | Test Class | Scenario | Expected Result | Test Ref |
|---|---|---|---|---|
| 1 | `ParentAuthTest` | PARENT user logs in via OTP; portal dashboard loads. STUDENT/STAFF/ADMIN user attempts portal access. | 200 for parent; 404 for non-parent (middleware returns 404 not 403) | T-01 |
| 2 | `OtpRateLimitTest` | > 3 OTP requests/hour same mobile blocked; > 5 consecutive failures trigger 30-min lockout | 429 on 4th request; 423/429 on lockout; lockout respected even after page refresh | T-02 |
| 3 | `ParentChildAccessTest` | ParentA accesses StudentA's attendance (200). ParentA attempts StudentB's attendance (403/404). | IDOR prevented; ParentChildPolicy blocks | T-03 |
| 4 | `FeePaymentAuthTest` | ParentA pays StudentA's invoice (200). ParentA attempts to pay StudentB's invoice (403). | 403 on cross-child; FeePaymentRequest::authorize() blocks | T-04 |
| 5 | `FeePaymentIdempotencyTest` | Razorpay webhook replayed with same payment_id twice | Second replay returns 200 but creates NO duplicate `fee_transactions` record | T-05 |
| 6 | `SwitchChildTest` | ParentA switches to StudentA (200). ParentA attempts to switch to StudentB (403). All data after switch reflects StudentA only. | IDOR blocked; SwitchChildRequest::authorize() validates ownership | T-06 |

**Test Setup Pattern:**
```php
// IDOR test pattern (ParentChildPolicy)
$parentA = User::factory()->create(['user_type' => 'PARENT']);
$guardianA = Guardian::factory()->for($parentA, 'user')->create();
$studentA = Student::factory()->create();
$studentB = Student::factory()->create();
StudentGuardianJnt::factory()->create([
    'guardian_id' => $guardianA->id, 'student_id' => $studentA->id,
    'can_access_parent_portal' => 1
]);
// StudentB has NO junction record to parentA
$invoice = FeeInvoice::factory()->for($studentB)->create();
$this->actingAs($parentA)
     ->post(route('ppt.fees.pay'), ['invoice_ids' => [$invoice->id]])
     ->assertForbidden();
```

### 11.2 P1 Functional Tests (17 scenarios — T-07 to T-24)

| # | Test Class | Scenario | Priority |
|---|---|---|---|
| 7 | `ComposeMessageTest` | Message to child's teacher creates ppt_messages record; teacher notified | High |
| 8 | `MessageIdrRestrictionTest` | Cannot message teacher who doesn't teach child | High |
| 9 | `ReadReceiptTest` | Teacher opens message; read_at updated | High |
| 10 | `MessageSearchTest` | FULLTEXT search returns matching messages | Medium |
| 11 | `LeaveApplicationTest` | Future date leave; correct number_of_days; teacher notified | High |
| 12 | `LeavePastDateTest` | Today/past date fails validation | High |
| 13 | `LeaveApprovalTest` | Teacher approves; Event::fake() catches LeaveApproved | High |
| 14 | `LeaveRejectionTest` | Teacher rejects with notes; parent sees Rejected + notes | High |
| 15 | `ConsentFormSignTest` | Sign creates immutable record with timestamp+IP; second sign attempt fails unique constraint | High |
| 16 | `ConsentFormDeadlineTest` | Past-deadline form shows "Closed"; sign blocked | Medium |
| 17 | `PtmBookingTest` | Book available slot; slot marked booked; confirmations dispatched | Medium |
| 18 | `PtmDoubleBookingTest` | Concurrent booking via two clients; only one succeeds (DB transaction + lockForUpdate) | Medium |
| 19 | `PtmCancellationTest` | Cancel > 1hr before PTM (slot released); < 1hr before (rejected) | Medium |
| 20 | `DocumentRequestTest` | TC request creates ppt_document_requests; admin notified | Medium |
| 21 | `DocumentRequestFeeTest` | fee_required > 0: download blocked until paid; allowed after payment | Medium |
| 22 | `ReportCardGateTest` | is_published=0: PDF blocked; is_published=1: download available | High |
| 23 | `NotificationPreferencesTest` | Disable FeeReminder SMS; Queue::fake() confirms no SMS job dispatched | Medium |
| 24 | `QuietHoursTest` | Non-urgent notification during quiet hours buffered; AbsenceAlert NOT buffered | Medium |

### 11.3 P2 Integration Tests (9 scenarios — T-25 to T-33)

| # | Test Class | Scenario | Priority |
|---|---|---|---|
| 25 | `MultiDeviceTokenTest` | Login on second device registers new FCM token; logout deactivates | Low |
| 26 | `MedicalRecordVisibilityTest` | `parent_visible=0` → hidden; `parent_visible=1` → shown | High |
| 27 | `CounsellorReportGateTest` | School setting=0 → hidden; setting=1 → visible | High |
| 28 | `EventRsvpTest` | RSVP created; duplicate RSVP unique constraint triggers graceful error | Medium |
| 29 | `VolunteerCapacityTest` | Sign-up when slots available (200); blocked when at capacity (422) | Medium |
| 30 | `TransportModuleGraceTest` | Transport disabled → 200 with graceful "not activated" message (not 500) | Medium |
| 31 | `ParentDashboardServiceTest` (Unit) | `getDashboardData()` returns correct metrics; max 5 queries (withQueryLog) | High |
| 32 | `NotificationPreferenceServiceTest` (Unit) | Quiet hours + urgent bypass logic correct | Medium |
| 33 | `PtmSchedulingServiceTest` (Unit) | Slot conflict detection works under concurrent booking simulation | High |

---

## Summary — Phase 1 Quality Gate Verification

- [x] All 38 screens inventoried in Section 2 with controller mapping and FR reference
- [x] All 18 FRs (FR-PPT-01 to FR-PPT-18) in Section 6 with priority, tables, and design notes
- [x] All 18 business rules (BR-PPT-001 to BR-PPT-018) in Section 4 with enforcement point
- [x] ParentChildPolicy enforcement requirement (BR-PPT-012) explicitly documented as ⚠️ P0 in Section 3
- [x] All 6 FSM workflows in Section 5 with security checkpoints marked
- [x] Multi-child architecture (active_student_id in DB — BR-PPT-010) documented in Sections 3 and 8
- [x] OTP rate limiting (BR-PPT-013) three-tier limits documented in Section 3
- [x] Razorpay idempotency (BR-PPT-018) documented with payment_reference unique constraint
- [x] Custom `parent.portal` middleware three-condition check documented in Section 3
- [x] Fee invoice ownership chain (guardian→student→fee_student_assignments→fee_invoices) documented in Sections 3 and 7
- [x] `std_student_guardian_jnt.can_access_parent_portal` CONFIRMED EXISTS in tenant_db_v2.sql ✅
- [x] `std_health_records.parent_visible` — ⚠️ COLUMN ABSENT; table is `std_health_profiles`, no `parent_visible` column — documented in Section 3 (DDL gap)
- [x] `fee_invoices` table name discrepancy (`fin_fee_invoices` vs `fee_invoices`) documented in Sections 3 and 7
- [x] `sys_users.id` type = INT UNSIGNED confirmed — sender/recipient FK in ppt_messages = INT UNSIGNED documented in Section 7
- [x] All 5 services designed with method signatures in Section 8
- [x] All 9 FormRequest classes designed with authorize() logic in Section 9
- [x] All 3 policies designed with methods in Section 10
- [x] Soft/hard module dependencies clearly separated in Section 7
- [x] Counsellor report gate (BR-PPT-007: school setting) and medical record gate (BR-PPT-006: per-record flag) documented
- [x] Quiet hours bypass rule (AbsenceAlert + EmergencyAlert always bypass) documented in Section 4
- [x] Leave approval → attendance module event dispatch (BR-PPT-017) flagged as cross-module integration in Sections 5 and 6
- [x] All 6 P0 security test scenarios in Section 11
- [x] 24-hour signed URL requirement for document downloads documented in Sections 3 and 5
- [x] Consent form immutability (signed_at + signed_ip + unique key) documented in Sections 4 and 10
