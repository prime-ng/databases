# PPT — Parent Portal Module: Development Plan
**Version:** 1.0 | **Date:** 2026-03-27 | **Module:** ParentPortal | **Status:** Greenfield (0%)
**Laravel Namespace:** `Modules\ParentPortal` | **Estimated Total Effort:** ~16 person-days
**Route Count:** ~75 web + ~18 API = ~93 total | **Phases:** P0 → P1 → P2 → P3

---

## Section 1 — Controller Inventory (17 Controllers)

> **⚠️ IDOR mandate:** `$this->authorize('viewChildData', $student)` is called in **every** data-fetching controller method. No exceptions. See Section 6 P0 for enforcement pattern.

---

### 1.1 AuthController
**File:** `app/Http/Controllers/AuthController.php`
**Complexity:** Complex | **Phase:** P0

| Method | Route | Notes |
|---|---|---|
| `showLogin()` | `GET /parent-portal/auth/login` | Renders SCR-PPT-01 — mobile + password form |
| `sendOtp()` | `POST /parent-portal/auth/otp/send` | `throttle:3,1` middleware; `RateLimiter::tooManyAttempts('otp-send:'.$mobile, 3)`; stores hash in cache with 10-min TTL |
| `showOtpVerify()` | `GET /parent-portal/auth/otp/verify` | Renders SCR-PPT-02 — 6-digit entry + countdown |
| `verifyOtp()` | `POST /parent-portal/auth/otp/verify` | Max 3 attempts; 5 consecutive fails → `RateLimiter::hit('otp-lockout:'.$mobile, 1800)` (30-min lockout) |
| `logout()` | `POST /parent-portal/auth/logout` | Sets `ppt_parent_sessions.is_active = 0`; token revoked |
| `showSetupPassword()` | `GET /parent-portal/auth/setup-password` | First-login only: `sys_users.password = NULL` check |
| `setupPassword()` | `POST /parent-portal/auth/setup-password` | Sets `sys_users.password`; redirects to dashboard |

**Services:** None (direct cache + RateLimiter)
**Policies:** None (pre-auth)
**FormRequests:** None (inline validation for OTP flow)
**External tables read:** `sys_users` (find by mobile), `std_guardians` (validate guardian exists)
**Special:** OTP endpoints excluded from `parent.portal` middleware. Password endpoints excluded from rate limiting.

---

### 1.2 ParentPortalController
**File:** `app/Http/Controllers/ParentPortalController.php`
**Complexity:** Complex | **Phase:** P0/P1

| Method | Route | Notes |
|---|---|---|
| `dashboard()` | `GET /parent-portal/dashboard` | Delegates to `ParentDashboardService::getDashboardData()`; renders SCR-PPT-03 |
| `children()` | `GET /parent-portal/children` | Lists all guardian's linked children; renders SCR-PPT-04 |
| `switchChild()` | `POST /parent-portal/children/switch` | `SwitchChildRequest`; updates `ppt_parent_sessions.active_student_id`; invalidates cache |

**Services:** `ParentDashboardService`
**Policies:** `ParentChildPolicy::viewChildData()` in `dashboard()`; `ParentChildPolicy::isActiveChild()` in `switchChild()`
**FormRequests:** `SwitchChildRequest`
**External tables read:** `std_students`, `std_student_guardian_jnt`, `std_guardians`
**Cache:** Dashboard: `Cache::tags(['parent', $guardianId])->remember(300, ...)` — 5-min TTL

---

### 1.3 AttendanceViewController
**File:** `app/Http/Controllers/AttendanceViewController.php`
**Complexity:** Medium | **Phase:** P1

| Method | Route | Notes |
|---|---|---|
| `index()` | `GET /parent-portal/attendance` | Monthly calendar view; renders SCR-PPT-05 |
| `subjectWise()` | `GET /parent-portal/attendance/subject-wise` | Subject-wise breakdown; renders SCR-PPT-06 |

**Services:** None
**Policies:** `ParentChildPolicy::viewChildData($activeStudent)` in both methods
**FormRequests:** None
**External tables read:** `std_attendance`, `std_subject_attendance`, `sch_academic_sessions`
**Graceful degradation:** If STD module unavailable, render `module-unavailable` component

---

### 1.4 TimetableViewController
**File:** `app/Http/Controllers/TimetableViewController.php`
**Complexity:** Medium | **Phase:** P1

| Method | Route | Notes |
|---|---|---|
| `index()` | `GET /parent-portal/timetable` | Weekly timetable grid; renders SCR-PPT-07 |
| `api()` | `GET /api/v1/parent/timetable` | JSON response for mobile/PWA |

**Services:** None
**Policies:** `ParentChildPolicy::viewChildData($activeStudent)` in both methods
**FormRequests:** None
**External tables read:** `tt_timetable_cells`, `tt_published_timetables`, `sch_class_sections`
**Graceful degradation:** If no published timetable → render `module-unavailable` component

---

### 1.5 HomeworkViewController
**File:** `app/Http/Controllers/HomeworkViewController.php`
**Complexity:** Medium | **Phase:** P1

| Method | Route | Notes |
|---|---|---|
| `index()` | `GET /parent-portal/homework` | Paginated list + optional calendar view; renders SCR-PPT-08 |
| `show()` | `GET /parent-portal/homework/{assignment}` | Detail view; renders SCR-PPT-09 |
| `api()` | `GET /api/v1/parent/homework` | JSON — upcoming + overdue count for dashboard widget |

**Services:** None
**Policies:** `ParentChildPolicy::viewChildData($activeStudent)` in all methods
**FormRequests:** None
**External tables read:** `hmw_assignments`, `hmw_submissions`
**Graceful degradation:** If HMW module not active → `module-unavailable` component

---

### 1.6 ResultViewController
**File:** `app/Http/Controllers/ResultViewController.php`
**Complexity:** Medium | **Phase:** P1

| Method | Route | Notes |
|---|---|---|
| `index()` | `GET /parent-portal/results` | All exam results list; renders SCR-PPT-10 |
| `show()` | `GET /parent-portal/results/{result}` | Single result detail; renders SCR-PPT-11 |
| `downloadReportCard()` | `GET /parent-portal/results/{reportCard}/download` | Gate: `exm_report_cards.is_published = 1` (BR-PPT-005); serves DomPDF |
| `api()` | `GET /api/v1/parent/results` | JSON — latest result summary for dashboard |

**Services:** None
**Policies:** `ParentChildPolicy::viewChildData($activeStudent)` in all methods; `is_published` gate in `downloadReportCard()`
**FormRequests:** None
**External tables read:** `exm_results`, `exm_report_cards`, `exm_exams`
**Graceful degradation:** Unpublished report card → 403 with friendly message (not 404)

---

### 1.7 FeeViewController
**File:** `app/Http/Controllers/FeeViewController.php`
**Complexity:** Complex | **Phase:** P1 — **⚠️ Fee IDOR is P0 critical**

| Method | Route | Middleware Override | Notes |
|---|---|---|---|
| `index()` | `GET /parent-portal/fees` | — | Fee summary; renders SCR-PPT-13 |
| `show()` | `GET /parent-portal/fees/{invoice}` | — | Invoice detail with installments |
| `pay()` | `POST /parent-portal/fees/pay` | `throttle:3,5` | `FeePaymentRequest`; initiates Razorpay order via `FeePaymentService::initiatePayment()` |
| `razorpayCallback()` | `POST /parent-portal/fees/razorpay-callback` | **`withoutMiddleware(['parent.portal', 'web'])`** | Public webhook; HMAC verify; idempotency check; delegates to `FeePaymentService::verifyAndRecord()` |
| `history()` | `GET /parent-portal/fees/history` | — | `fee_transactions` list; renders SCR-PPT-16 |
| `downloadReceipt()` | `GET /parent-portal/fees/{transaction}/receipt` | — | DomPDF signed receipt via `FeePaymentService::generateReceipt()` |
| `api()` | `GET /api/v1/parent/fees` | — | JSON — outstanding balance for dashboard |
| `apiCallback()` | `POST /api/v1/parent/fees/razorpay-callback` | **`withoutMiddleware(['parent.portal'])`** | Mobile app webhook path — same handler as `razorpayCallback()` |

**Services:** `FeePaymentService`
**Policies:** `ParentChildPolicy::payInvoice($invoice)` in `pay()` + `show()`. `ParentChildPolicy::viewChildData()` on all list views.
**FormRequests:** `FeePaymentRequest`
**External tables read:** `fee_invoices`, `fee_student_assignments`, `fee_installments`, `fee_transactions`
**⚠️ Critical:** `fee_invoices` has NO `student_id` — always verify via `student_assignment_id → fee_student_assignments.student_id` chain

---

### 1.8 MessageController
**File:** `app/Http/Controllers/MessageController.php`
**Complexity:** Medium | **Phase:** P2

| Method | Route | Notes |
|---|---|---|
| `index()` | `GET /parent-portal/messages` | Thread list; renders SCR-PPT-17 |
| `thread()` | `GET /parent-portal/messages/{threadId}` | Full conversation; renders SCR-PPT-18 |
| `compose()` | `GET /parent-portal/messages/compose` | Compose form with teacher selector; renders SCR-PPT-19 |
| `store()` | `POST /parent-portal/messages` | `ComposeMessageRequest`; creates new thread via `MessagingService::getOrCreateThread()` |
| `reply()` | `POST /parent-portal/messages/{threadId}/reply` | Adds reply to existing thread |
| `markRead()` | `POST /parent-portal/messages/{message}/read` | Sets `ppt_messages.read_at = NOW()` |
| `api()` | `GET /api/v1/parent/messages` | JSON — unread count + recent threads |
| `apiStore()` | `POST /api/v1/parent/messages` | Mobile compose endpoint |

**Services:** `MessagingService`
**Policies:** `ParentMessagePolicy::composeMessage()` in `store()`; `ParentMessagePolicy::viewThread()` in `thread()`
**FormRequests:** `ComposeMessageRequest`
**External tables read:** `sys_users` (teacher profiles), `tt_timetable_cells` (allowed teacher list)

---

### 1.9 NotificationController
**File:** `app/Http/Controllers/NotificationController.php`
**Complexity:** Medium | **Phase:** P2

| Method | Route | Notes |
|---|---|---|
| `index()` | `GET /parent-portal/notifications` | Paginated notification list; renders SCR-PPT-20 |
| `show()` | `GET /parent-portal/notifications/{notification}` | Detail; renders SCR-PPT-21; auto-marks read |
| `markRead()` | `POST /parent-portal/notifications/{id}/read` | Single mark-read |
| `markAllRead()` | `POST /parent-portal/notifications/read-all` | Bulk mark-read |
| `preferences()` | `GET /parent-portal/notifications/preferences` | Preference form; renders SCR-PPT-22 |
| `savePreferences()` | `POST /parent-portal/notifications/preferences` | `NotificationPreferencesRequest`; upserts `ppt_parent_sessions.notification_preferences_json` |
| `api()` | `GET /api/v1/parent/notifications` | JSON — unread count + last 5 notifications |

**Services:** `NotificationPreferenceService`
**Policies:** `ParentChildPolicy::viewChildData($activeStudent)` — notifications scoped to active child
**FormRequests:** `NotificationPreferencesRequest`
**External tables read:** `ntf_notifications`, `ntf_circulars`

---

### 1.10 LeaveController
**File:** `app/Http/Controllers/LeaveController.php`
**Complexity:** Medium | **Phase:** P2

| Method | Route | Notes |
|---|---|---|
| `index()` | `GET /parent-portal/leave` | Leave history list; renders SCR-PPT-23 |
| `create()` | `GET /parent-portal/leave/create` | Application form; renders SCR-PPT-24 |
| `store()` | `POST /parent-portal/leave` | `ApplyLeaveRequest`; generates `PPT-LV-{YYYY}-{XXXXXXXX}`; inserts to `ppt_leave_applications` |
| `show()` | `GET /parent-portal/leave/{leave}` | Status view; renders SCR-PPT-25 |
| `destroy()` | `DELETE /parent-portal/leave/{leave}` | Withdraw; only if `status = Pending`; `ParentLeavePolicy::withdraw()` |

**Services:** None
**Policies:** `ParentChildPolicy::viewChildData($activeStudent)` in all; `ParentLeavePolicy::withdraw()` in `destroy()`
**FormRequests:** `ApplyLeaveRequest`
**External tables read/written:** `ppt_leave_applications` (write); `std_students` (read)
**Event dispatch on teacher approval (admin-side handler):** `event(new LeaveApproved($leaveApplication))` — see BR-PPT-017 note in Section 6 P2

---

### 1.11 ConsentFormController
**File:** `app/Http/Controllers/ConsentFormController.php`
**Complexity:** Medium | **Phase:** P2

| Method | Route | Notes |
|---|---|---|
| `index()` | `GET /parent-portal/consent-forms` | List of active consent forms for student; renders SCR-PPT-26 |
| `show()` | `GET /parent-portal/consent-forms/{consentFormId}` | Form detail + sign/decline UI; renders SCR-PPT-27 |
| `sign()` | `POST /parent-portal/consent-forms/{consentFormId}/sign` | `ConsentFormSignRequest`; IMMUTABLE insert to `ppt_consent_form_responses`; checks deadline |

**Services:** None
**Policies:** `ParentChildPolicy::viewChildData($activeStudent)` in all; deadline check + `uq_ppt_consent_response` uniqueness caught via DB exception in `sign()`
**FormRequests:** `ConsentFormSignRequest`
**External tables read:** Event/Activity consent form records (soft dependency; degrade gracefully if absent)
**⚠️ Immutability:** `sign()` does INSERT ONLY — no update path; `uq_ppt_consent_response` DB constraint is backstop for double-sign

---

### 1.12 PtmController
**File:** `app/Http/Controllers/PtmController.php`
**Complexity:** Complex | **Phase:** P2

| Method | Route | Notes |
|---|---|---|
| `index()` | `GET /parent-portal/ptm` | PTM events list; renders SCR-PPT-28 |
| `slots()` | `GET /parent-portal/ptm/{ptmEvent}/slots` | Teacher slot picker; renders SCR-PPT-29 |
| `book()` | `POST /parent-portal/ptm/{ptmEvent}/book` | `PtmBookingRequest`; delegates to `PtmSchedulingService::bookSlot()` with `DB::transaction` + `lockForUpdate` |
| `cancelBooking()` | `DELETE /parent-portal/ptm/booking/{booking}` | Cancels and releases slot immediately (BR-PPT-015) |

**Services:** `PtmSchedulingService`
**Policies:** `ParentChildPolicy::viewChildData($activeStudent)` in all
**FormRequests:** `PtmBookingRequest`
**External tables read:** PTM event module tables (soft dependency)
**⚠️ Race condition:** `bookSlot()` uses `DB::transaction() + SELECT...FOR UPDATE` — only one booking per slot under concurrent requests

---

### 1.13 EventController
**File:** `app/Http/Controllers/EventController.php`
**Complexity:** Medium | **Phase:** P3

| Method | Route | Notes |
|---|---|---|
| `index()` | `GET /parent-portal/events` | Calendar view of upcoming events; renders SCR-PPT-30 |
| `show()` | `GET /parent-portal/events/{eventId}` | Event detail + RSVP options; renders SCR-PPT-31 |
| `rsvp()` | `POST /parent-portal/events/{eventId}/rsvp` | `EventRsvpRequest`; upserts `ppt_event_rsvps` |
| `volunteerSignup()` | `POST /parent-portal/events/{eventId}/volunteer` | `EventRsvpRequest` with volunteer fields; BR-PPT-016 capacity check |
| `icsDownload()` | `GET /parent-portal/events/{eventId}/ics` | Returns `.ics` file for calendar import |
| `api()` | `GET /api/v1/parent/events` | JSON — upcoming events + RSVP status |

**Services:** None
**Policies:** `ParentChildPolicy::viewChildData($activeStudent)` on school-specific events; not strictly needed for global school events but applied for consistency
**FormRequests:** `EventRsvpRequest`
**External tables read:** Event engine event records (no FK — soft dependency); `ppt_event_rsvps` (write)

---

### 1.14 HealthReportController
**File:** `app/Http/Controllers/HealthReportController.php`
**Complexity:** Medium | **Phase:** P3

| Method | Route | Notes |
|---|---|---|
| `index()` | `GET /parent-portal/health-reports` | Health overview; renders SCR-PPT-32 |
| `show()` | `GET /parent-portal/health-reports/{type}` | Specific report type; renders SCR-PPT-33 |
| `download()` | `GET /parent-portal/health-reports/{record}/download` | DomPDF export of health summary |

**Services:** None
**Policies:** `ParentChildPolicy::viewChildData($activeStudent)` + counsellor report gate (BR-PPT-007)
**FormRequests:** None
**External tables read:** `std_health_profiles` (with `parent_visible = 1` filter — ⚠️ needs P1 migration), `hpc_counsellor_reports` (gated), `hpc_physical_assessments`
**⚠️ Two gates:**
1. Per-record: `->where('parent_visible', 1)` on `std_health_profiles`
2. Counsellor reports: `app('school_settings')->get('parent_counsellor_report_visibility', false)` must be truthy

---

### 1.15 TransportViewController
**File:** `app/Http/Controllers/TransportViewController.php`
**Complexity:** Simple | **Phase:** P3

| Method | Route | Notes |
|---|---|---|
| `index()` | `GET /parent-portal/transport` | Route + vehicle + driver info; renders SCR-PPT-34 |

**Services:** None
**Policies:** `ParentChildPolicy::viewChildData($activeStudent)`
**FormRequests:** None
**External tables read:** `tpt_routes`, `tpt_vehicles`, `tpt_student_route_jnt`
**Graceful degradation:** If TPT module not active → `module-unavailable` component

---

### 1.16 DocumentController
**File:** `app/Http/Controllers/DocumentController.php`
**Complexity:** Medium | **Phase:** P3

| Method | Route | Notes |
|---|---|---|
| `index()` | `GET /parent-portal/documents` | Document vault; renders SCR-PPT-35 |
| `download()` | `GET /parent-portal/documents/{documentId}/download` | `Storage::temporaryUrl($path, now()->addHours(24))` — signed 24-hr URL (BR-PPT-007 / SUG-PPT-07) |
| `requestForm()` | `GET /parent-portal/documents/request` | Request form; renders SCR-PPT-36 |
| `storeRequest()` | `POST /parent-portal/documents/request` | `DocumentRequestForm`; generates `PPT-DR-{YYYY}-{XXXXXXXX}`; inserts `ppt_document_requests` |
| `trackRequest()` | `GET /parent-portal/documents/track` | Renders SCR-PPT-37 — pending/completed requests |

**Services:** None
**Policies:** `ParentChildPolicy::viewChildData($activeStudent)` in all
**FormRequests:** `DocumentRequestForm`
**External tables read/written:** `ppt_document_requests` (write); `sys_media` (read fulfilled_media_id)
**Fee gate:** If `fee_required > 0` and `fee_paid = 0`, redirect to fee payment before serving download

---

### 1.17 AccountSettingsController
**File:** `app/Http/Controllers/AccountSettingsController.php`
**Complexity:** Medium | **Phase:** P2

| Method | Route | Notes |
|---|---|---|
| `index()` | `GET /parent-portal/settings` | Settings overview; renders SCR-PPT-38 |
| `profile()` | `POST /parent-portal/settings/profile` | Update guardian profile fields |
| `changePassword()` | `POST /parent-portal/settings/password` | Updates `sys_users.password`; requires current password |
| `devices()` | `GET /parent-portal/settings/devices` | Lists active `ppt_parent_sessions` for guardian |
| `logoutDevice()` | `DELETE /parent-portal/settings/devices/{sessionId}` | Sets `is_active = 0` on target session |
| `registerToken()` | `POST /parent-portal/settings/push-token` | Upserts FCM/APNs/WebPush token in `ppt_parent_sessions` |
| `removeToken()` | `DELETE /parent-portal/settings/push-token` | Clears device token; `is_active = 0` |

**Services:** `NotificationPreferenceService` (for quiet hours validation)
**Policies:** None (settings are own-account only; guardian_id from auth)
**FormRequests:** None (inline validation)
**External tables read/written:** `ppt_parent_sessions` (write), `std_guardians` (read/write profile fields)

---

## Section 2 — Service Inventory (5 Services)

---

### 2.1 ParentDashboardService
**File:** `app/Services/ParentDashboardService.php`
**Phase:** P1 | **DB:** Read-only across 6+ external tables

**Constructor:**
```php
public function __construct(
    private readonly CacheRepository $cache
) {}
```

| Method | Signature | Called From | DB Impact |
|---|---|---|---|
| `getDashboardData()` | `getDashboardData(int $guardianId, int $activeStudentId): array` | `ParentPortalController@dashboard` | Reads: std_students, std_attendance, tt_timetable_cells, hmw_assignments, fee_invoices, ntf_notifications |
| `invalidateDashboardCache()` | `invalidateDashboardCache(int $guardianId): void` | `FeeViewController@razorpayCallback`, `LeaveController` (on status change) | Cache tags flush only |

**Caching strategy:**
```php
return Cache::tags(['parent', $guardianId])->remember(
    "dashboard:{$guardianId}:{$activeStudentId}",
    300,  // 5 minutes
    fn() => $this->loadDashboardWidgets($activeStudentId)
);
```

**Performance contract:** Max 5 queries total for all widgets:
1. Student + guardian + linked children (1 query with eager load)
2. Attendance summary for active month (1 query)
3. Today's timetable + pending homework count (1 query each, combined if possible)
4. Fee outstanding + overdue count (1 query via fee_student_assignments join)
5. Last 3 notifications (1 query)

**Cache invalidation triggers:**
- Fee payment recorded → `Cache::tags(['parent', $guardianId])->flush()`
- Leave status changed → same flush
- New message received → same flush

---

### 2.2 FeePaymentService
**File:** `app/Services/FeePaymentService.php`
**Phase:** P1 | **DB:** Writes `fee_transactions`; reads `fee_invoices`, `fee_student_assignments`

**Constructor:**
```php
public function __construct(
    private readonly \Razorpay\Api\Api $razorpay,
    private readonly ParentDashboardService $dashboardService
) {}
```

| Method | Signature | Called From | DB Impact |
|---|---|---|---|
| `initiatePayment()` | `initiatePayment(array $invoiceIds, int $guardianId): array` | `FeeViewController@pay` | Reads fee_invoices; creates Razorpay order; returns order_id |
| `verifyAndRecord()` | `verifyAndRecord(array $razorpayPayload, int $guardianId): FeeTransaction` | `FeeViewController@razorpayCallback`, `FeeViewController@apiCallback` | Writes fee_transactions; updates fee_invoices.status |
| `generateReceipt()` | `generateReceipt(int $transactionId): string` | `FeeViewController@downloadReceipt` | Reads fee_transactions, fee_invoices; returns DomPDF base64 |

**Idempotency guard** (BR-PPT-018) — MUST check before any DB write:
```php
// verifyAndRecord() — idempotency check before insert
$existing = FeeTransaction::where('payment_reference', $razorpayPayload['razorpay_payment_id'])->first();
if ($existing) {
    return $existing;  // replay detected — return existing record, do NOT create duplicate
}
```

**⚠️ Note:** `razorpayCallback()` (web POST) and `apiCallback()` (API POST) both call the SAME `verifyAndRecord()` service method. Webhook endpoint is excluded from `parent.portal` middleware.

---

### 2.3 MessagingService
**File:** `app/Services/MessagingService.php`
**Phase:** P2 | **DB:** Writes `ppt_messages`; reads `sys_users`, `tt_timetable_cells`

**Constructor:**
```php
public function __construct() {}
```

| Method | Signature | Called From | DB Impact |
|---|---|---|---|
| `getOrCreateThread()` | `getOrCreateThread(int $guardianId, int $teacherUserId, int $studentId): string` | `MessageController@store` | Computes `thread_id = MD5($guardianId.'_'.$teacherUserId.'_'.$studentId)` |
| `getAllowedTeachers()` | `getAllowedTeachers(int $studentId): Collection` | `ComposeMessageRequest::authorize()`, `MessageController@compose` | Reads tt_timetable_cells to find teachers of student's class/section |
| `storeMessage()` | `storeMessage(array $data, string $threadId): PptMessage` | `MessageController@store`, `MessageController@reply` | Writes ppt_messages; stores attachment media IDs JSON |
| `searchMessages()` | `searchMessages(int $guardianId, string $query): Collection` | `MessageController@index` (search) | FULLTEXT query: `MATCH(subject, message_body) AGAINST (? IN BOOLEAN MODE)` |

---

### 2.4 NotificationPreferenceService
**File:** `app/Services/NotificationPreferenceService.php`
**Phase:** P2 | **DB:** Reads `ppt_parent_sessions`

**Constructor:**
```php
public function __construct() {}
const URGENT_ALERT_TYPES = ['AbsenceAlert', 'EmergencyAlert'];
```

| Method | Signature | Called From | DB Impact |
|---|---|---|---|
| `getPreferences()` | `getPreferences(int $guardianId, string $deviceType): array` | `NotificationController@preferences` | Reads ppt_parent_sessions.notification_preferences_json |
| `savePreferences()` | `savePreferences(int $guardianId, array $prefs): void` | `NotificationController@savePreferences` | Writes ppt_parent_sessions.notification_preferences_json |
| `shouldDeliver()` | `shouldDeliver(int $guardianId, string $alertType, string $channel): bool` | Notification listeners (not in PPT module — called by NTF module) | Reads session prefs + quiet hours |
| `isQuietHoursActive()` | `isQuietHoursActive(string $start, string $end): bool` | `shouldDeliver()` | No DB — time comparison |

**Quiet hours — midnight-crossing window handling:**
```php
public function isQuietHoursActive(string $start, string $end): bool
{
    $now = now()->format('H:i');
    if ($start > $end) {
        // Crosses midnight: e.g. 22:00–07:00
        return $now >= $start || $now < $end;
    }
    return $now >= $start && $now < $end;
}
```

**Urgent bypass rule:** `AbsenceAlert` and `EmergencyAlert` types always bypass quiet hours and channel preference (BR-PPT-008):
```php
if (in_array($alertType, self::URGENT_ALERT_TYPES)) {
    return true;  // Always deliver
}
```

---

### 2.5 PtmSchedulingService
**File:** `app/Services/PtmSchedulingService.php`
**Phase:** P2 | **DB:** Writes PTM booking records; reads PTM event tables

**Constructor:**
```php
public function __construct() {}
```

| Method | Signature | Called From | DB Impact |
|---|---|---|---|
| `getAvailableSlots()` | `getAvailableSlots(int $ptmEventId, int $teacherUserId): Collection` | `PtmController@slots` | Reads PTM slot table; filters `is_booked = 0` |
| `bookSlot()` | `bookSlot(array $data, int $guardianId): PtmBooking` | `PtmController@book` | `DB::transaction()` + `lockForUpdate()`; writes PTM booking |
| `cancelBooking()` | `cancelBooking(int $bookingId, int $guardianId): void` | `PtmController@cancelBooking` | Soft-deletes booking; sets `ptm_slots.is_booked = 0` immediately (BR-PPT-015) |

**Race condition guard (BR-PPT-015):**
```php
public function bookSlot(array $data, int $guardianId): PtmBooking
{
    return DB::transaction(function () use ($data, $guardianId) {
        $slot = PtmSlot::lockForUpdate()->findOrFail($data['slot_id']);
        abort_if($slot->is_booked, 409, 'Slot just taken; please choose another.');
        $slot->update(['is_booked' => 1, 'booked_by_guardian_id' => $guardianId]);
        return PtmBooking::create([...]);
    });
}
```

---

## Section 3 — FormRequest Inventory (9 FormRequests)

| Class | File | Controller@Method | authorize() Logic | Key Rules | Phase |
|---|---|---|---|---|---|
| `SwitchChildRequest` | `Requests/SwitchChildRequest.php` | `ParentPortalController@switchChild` | Queries `std_student_guardian_jnt` WHERE `guardian_id = guardian()->id AND student_id = $this->student_id AND can_access_parent_portal = 1` — prevents child-swapping IDOR | `student_id: required\|integer\|exists:std_students,id` | P0 |
| `FeePaymentRequest` | `Requests/FeePaymentRequest.php` | `FeeViewController@pay` | Ownership chain: `FeeInvoice::whereHas('studentAssignment', fn→whereIn('student_id', $allowedStudentIds))` + status in `['Published','Partially Paid','Overdue']` + `balance_amount > 0` — P0 IDOR prevention | `invoice_ids: required\|array\|min:1`; each `integer\|exists:fee_invoices,id`; `total_amount: required\|numeric\|min:1` | P0 |
| `ComposeMessageRequest` | `Requests/ComposeMessageRequest.php` | `MessageController@store` | Calls `MessagingService::getAllowedTeachers($activeStudentId)` and verifies `recipient_user_id` is in that list | `recipient_user_id: required\|exists:sys_users,id`; `subject: required\|max:200`; `message_body: required\|min:10`; `attachments: nullable\|array\|max:3` each `file\|max:5120\|mimes:pdf,jpg,png,doc,docx`; `prepareForValidation()` → `strip_tags($message_body)` | P2 |
| `ApplyLeaveRequest` | `Requests/ApplyLeaveRequest.php` | `LeaveController@store` | `ParentChildPolicy::viewChildData($activeStudent)` must pass | `from_date: required\|date\|after:today` (BR-PPT-004); `to_date: required\|date\|after_or_equal:from_date`; `leave_type: required\|in:Sick,Family,Personal,Festival,Medical,Other`; `reason: required\|min:20\|max:1000` | P2 |
| `NotificationPreferencesRequest` | `Requests/NotificationPreferencesRequest.php` | `NotificationController@savePreferences` | Guardian is always authorized for own preferences | `preferences: required\|array`; `withValidator()` checks all keys are valid alert type names; values are arrays with keys `in_app,sms,email,whatsapp` (bool); `quiet_hours_start/end: nullable\|date_format:H:i` | P2 |
| `ConsentFormSignRequest` | `Requests/ConsentFormSignRequest.php` | `ConsentFormController@sign` | `ParentChildPolicy::viewChildData()` + deadline check: `$consentForm->deadline >= today()` | `signer_name: required\|min:3\|max:150`; `response: required\|in:Signed,Declined`; `decline_reason: required_if:response,Declined\|min:10`; `prepareForValidation()` → `strip_tags($this->signer_name)` | P2 |
| `PtmBookingRequest` | `Requests/PtmBookingRequest.php` | `PtmController@book` | `ParentChildPolicy::viewChildData()` | `ptm_event_id: required\|integer`; `slot_id: required\|integer`; `teacher_user_id: required\|integer\|exists:sys_users,id` | P2 |
| `EventRsvpRequest` | `Requests/EventRsvpRequest.php` | `EventController@rsvp`, `EventController@volunteerSignup` | `ParentChildPolicy::viewChildData()` | `event_id: required\|integer`; `rsvp_status: required\|in:Attending,Not_Attending,Maybe`; `is_volunteer: boolean`; `volunteer_role: required_if:is_volunteer,true\|max:150` | P3 |
| `DocumentRequestForm` | `Requests/DocumentRequestForm.php` | `DocumentController@storeRequest` | `ParentChildPolicy::viewChildData()` | `document_type: required\|in:TC,MarkSheet,Bonafide,Character,Migration,MedicalFitness,Other`; `reason: required\|min:20`; `urgency: required\|in:Normal,Urgent` | P3 |

---

## Section 4 — Blade View Inventory (~45 Views)

**Namespace:** `parentportal::`
**Layout base:** `parentportal::components.layouts.master`
**Mobile-first:** All views use Bootstrap 5 or Tailwind responsive; touch targets ≥ 44px height

### 4.1 Shared Components (Build in P0 — used across all views)

| Component | File | Purpose | Phase |
|---|---|---|---|
| Master Layout | `components/layouts/master.blade.php` | Base layout: header, child switcher nav bar, side nav, content area | P0 |
| Child Switcher | `components/child-switcher.blade.php` | Fixed top bar dropdown showing all linked children; POST to `ppt.children.switch`; SUG-PPT-09 | P0 |
| Unread Badge | `components/unread-badge.blade.php` | Notification count badge rendered in nav; reads count from shared view data | P0 |
| Fee Status Chip | `components/fee-status-chip.blade.php` | Colour-coded chip: green=Paid, orange=Due/Partially Paid, red=Overdue; SUG-PPT-11 | P0 |
| Module Unavailable | `components/module-unavailable.blade.php` | Graceful "module not activated" card; renders when external module dep is absent | P0 |

### 4.2 Auth Views (P0)

| SCR # | Screen | View File | Complexity | Data Variables |
|---|---|---|---|---|
| SCR-PPT-01 | Login | `auth/login.blade.php` | Medium | `$loginMode` (otp\|password), `$errors` |
| SCR-PPT-02 | OTP Verification | `auth/otp-verify.blade.php` | Medium | `$mobile` (masked), `$expiresAt`, `$errors` |
| — | Password Setup | `auth/setup-password.blade.php` | Simple | `$errors` |

### 4.3 Dashboard & Navigation (P1)

| SCR # | Screen | View File | Complexity | Data Variables |
|---|---|---|---|---|
| SCR-PPT-03 | Dashboard | `dashboard.blade.php` | Complex | `$widgets` (attendance%, homework, fee, timetable, notifications), `$activeStudent`, `$children` |
| SCR-PPT-04 | Children List | `children/index.blade.php` | Simple | `$children` (Collection of Student), `$activeStudentId` |

### 4.4 Academic Views (P1)

| SCR # | Screen | View File | Complexity | Data Variables |
|---|---|---|---|---|
| SCR-PPT-05 | Attendance Calendar | `attendance/index.blade.php` | Medium | `$calendar` (month→day→status map), `$student`, `$month`, `$year` |
| SCR-PPT-06 | Subject-wise Attendance | `attendance/subject-wise.blade.php` | Medium | `$subjects` (Collection with attendance%), `$student` |
| SCR-PPT-07 | Timetable | `timetable/index.blade.php` | Medium | `$timetable` (days×periods grid), `$student`, `$publishedAt` |
| SCR-PPT-08 | Homework List | `homework/index.blade.php` | Medium | `$assignments` (paginated), `$student`, `$pendingCount` |
| SCR-PPT-09 | Homework Detail | `homework/show.blade.php` | Simple | `$assignment`, `$submission` (if exists), `$student` |
| SCR-PPT-10 | Results List | `results/index.blade.php` | Medium | `$results` (Collection by exam), `$student` |
| SCR-PPT-11 | Result Detail | `results/show.blade.php` | Simple | `$result`, `$student` |
| SCR-PPT-12 | Report Card | `results/report-card.blade.php` | Medium | `$reportCard`, `$student`, `$downloadUrl` |

### 4.5 Finance Views (P1)

| SCR # | Screen | View File | Complexity | Data Variables |
|---|---|---|---|---|
| SCR-PPT-13 | Fee Summary | `fees/index.blade.php` | Complex | `$invoices` (paginated), `$outstanding`, `$student`, uses `fee-status-chip` component |
| SCR-PPT-14 | Razorpay Checkout | `fees/pay.blade.php` | Complex | `$invoice`, `$razorpayOrderId`, `$razorpayKey`, `$callbackUrl` |
| SCR-PPT-15 | Payment Success | `fees/success.blade.php` | Medium | `$transaction`, `$receiptUrl` |
| SCR-PPT-16 | Payment History | `fees/history.blade.php` | Medium | `$transactions` (paginated), `$student` |

### 4.6 Communication Views (P2)

| SCR # | Screen | View File | Complexity | Data Variables |
|---|---|---|---|---|
| SCR-PPT-17 | Message Inbox | `messages/index.blade.php` | Medium | `$threads` (by thread_id), `$unreadCount`, `$student` |
| SCR-PPT-18 | Message Thread | `messages/thread.blade.php` | Medium | `$messages` (Collection), `$teacher`, `$student`, `$threadId` |
| SCR-PPT-19 | Compose | `messages/compose.blade.php` | Medium | `$allowedTeachers` (with subject + photo), `$student` |
| SCR-PPT-20 | Notification Inbox | `notifications/index.blade.php` | Medium | `$notifications` (paginated), `$unreadCount` |
| SCR-PPT-21 | Notification Detail | `notifications/show.blade.php` | Simple | `$notification` |
| SCR-PPT-22 | Notification Prefs | `notifications/preferences.blade.php` | Medium | `$preferences`, `$alertTypes`, `$quietHours` |

### 4.7 Requests & Forms Views (P2)

| SCR # | Screen | View File | Complexity | Data Variables |
|---|---|---|---|---|
| SCR-PPT-23 | Leave List | `leave/index.blade.php` | Simple | `$leaves` (paginated with status badges), `$student` |
| SCR-PPT-24 | Apply Leave | `leave/create.blade.php` | Medium | `$leaveTypes`, `$student`, `$errors` |
| SCR-PPT-25 | Leave Status | `leave/show.blade.php` | Simple | `$leave`, `$canWithdraw` |
| SCR-PPT-26 | Consent Forms List | `consent-forms/index.blade.php` | Simple | `$consentForms` (pending + signed), `$student` |
| SCR-PPT-27 | Consent Form Detail | `consent-forms/show.blade.php` | Medium | `$consentForm`, `$alreadySigned`, `$deadline` |

### 4.8 Meetings & Events Views (P2/P3)

| SCR # | Screen | View File | Complexity | Data Variables |
|---|---|---|---|---|
| SCR-PPT-28 | PTM Events | `ptm/index.blade.php` | Medium | `$ptmEvents`, `$existingBookings`, `$student` |
| SCR-PPT-29 | PTM Slot Booking | `ptm/slots.blade.php` | Complex | `$ptmEvent`, `$slots` (by teacher), `$student` — JS modal for slot confirmation |
| SCR-PPT-30 | Event Calendar | `events/index.blade.php` | Medium | `$events` (month view), `$upcomingCount`, `$student` |
| SCR-PPT-31 | Event Detail | `events/show.blade.php` | Medium | `$event`, `$myRsvp`, `$volunteerRoles`, `$remainingCapacity` |

### 4.9 Health, Info & Settings Views (P3)

| SCR # | Screen | View File | Complexity | Data Variables |
|---|---|---|---|---|
| SCR-PPT-32 | Health Overview | `health-reports/index.blade.php` | Medium | `$healthProfile`, `$vaccinations`, `$student`, `$counsellorReportVisible` |
| SCR-PPT-33 | Health Report Detail | `health-reports/show.blade.php` | Medium | `$report`, `$student`, `$downloadUrl` |
| SCR-PPT-34 | Transport Info | `transport/index.blade.php` | Simple | `$route`, `$vehicle`, `$driver`, `$student` |
| SCR-PPT-35 | Document Vault | `documents/index.blade.php` | Medium | `$documents` (issued), `$pendingRequests`, `$student` |
| SCR-PPT-36 | Document Request | `documents/request.blade.php` | Medium | `$documentTypes`, `$student`, `$errors` |
| SCR-PPT-37 | Request Status | `documents/track.blade.php` | Simple | `$requests` (with FSM status), `$student` |
| SCR-PPT-38 | Account Settings | `settings/index.blade.php` | Medium | `$guardian`, `$devices` (ppt_parent_sessions), `$user` |

**Total views:** 5 components + 3 auth + 2 dashboard + 8 academic + 4 finance + 6 communication + 5 requests + 4 meetings + 8 health/info/settings = **45 views**

---

## Section 5 — Complete Route List

**Web route file:** `routes/web.php` (within module)
**All web routes:** prefix `parent-portal/`, name prefix `ppt.`, middleware `[web, EnsureTenantHasModule:ParentPortal]`
**Portal routes additionally use:** `parent.portal` middleware (except OTP and webhook endpoints)

### 5.1 Auth Routes (exclude `parent.portal`)

| Method | URI | Route Name | Controller@Method | Middleware Override |
|---|---|---|---|---|
| GET | `/parent-portal/auth/login` | `ppt.login` | `AuthController@showLogin` | No `parent.portal` |
| POST | `/parent-portal/auth/otp/send` | `ppt.otp.send` | `AuthController@sendOtp` | No `parent.portal`; `throttle:3,1` |
| GET | `/parent-portal/auth/otp/verify` | `ppt.otp.verify.form` | `AuthController@showOtpVerify` | No `parent.portal` |
| POST | `/parent-portal/auth/otp/verify` | `ppt.otp.verify` | `AuthController@verifyOtp` | No `parent.portal` |
| POST | `/parent-portal/auth/logout` | `ppt.logout` | `AuthController@logout` | Requires `parent.portal` |
| GET | `/parent-portal/auth/setup-password` | `ppt.setup-password.form` | `AuthController@showSetupPassword` | No `parent.portal` |
| POST | `/parent-portal/auth/setup-password` | `ppt.setup-password` | `AuthController@setupPassword` | No `parent.portal` |

### 5.2 Dashboard Routes

| Method | URI | Route Name | Controller@Method | Notes |
|---|---|---|---|---|
| GET | `/parent-portal/dashboard` | `ppt.dashboard` | `ParentPortalController@dashboard` | |
| GET | `/parent-portal/children` | `ppt.children` | `ParentPortalController@children` | |
| POST | `/parent-portal/children/switch` | `ppt.children.switch` | `ParentPortalController@switchChild` | `SwitchChildRequest` |

### 5.3 Academic Routes

| Method | URI | Route Name | Controller@Method | Notes |
|---|---|---|---|---|
| GET | `/parent-portal/attendance` | `ppt.attendance.index` | `AttendanceViewController@index` | |
| GET | `/parent-portal/attendance/subject-wise` | `ppt.attendance.subject-wise` | `AttendanceViewController@subjectWise` | |
| GET | `/parent-portal/timetable` | `ppt.timetable.index` | `TimetableViewController@index` | |
| GET | `/parent-portal/homework` | `ppt.homework.index` | `HomeworkViewController@index` | |
| GET | `/parent-portal/homework/{assignment}` | `ppt.homework.show` | `HomeworkViewController@show` | |
| GET | `/parent-portal/results` | `ppt.results.index` | `ResultViewController@index` | |
| GET | `/parent-portal/results/{result}` | `ppt.results.show` | `ResultViewController@show` | |
| GET | `/parent-portal/results/{reportCard}/download` | `ppt.results.report-card` | `ResultViewController@downloadReportCard` | |

### 5.4 Finance Routes

| Method | URI | Route Name | Controller@Method | Middleware Override |
|---|---|---|---|---|
| GET | `/parent-portal/fees` | `ppt.fees.index` | `FeeViewController@index` | |
| GET | `/parent-portal/fees/{invoice}` | `ppt.fees.show` | `FeeViewController@show` | |
| POST | `/parent-portal/fees/pay` | `ppt.fees.pay` | `FeeViewController@pay` | `throttle:3,5` |
| POST | `/parent-portal/fees/razorpay-callback` | `ppt.fees.callback` | `FeeViewController@razorpayCallback` | **`withoutMiddleware(['parent.portal', 'web'])`** |
| GET | `/parent-portal/fees/history` | `ppt.fees.history` | `FeeViewController@history` | |
| GET | `/parent-portal/fees/{transaction}/receipt` | `ppt.fees.receipt` | `FeeViewController@downloadReceipt` | |

### 5.5 Communication Routes

| Method | URI | Route Name | Controller@Method | Notes |
|---|---|---|---|---|
| GET | `/parent-portal/messages` | `ppt.messages.index` | `MessageController@index` | |
| GET | `/parent-portal/messages/compose` | `ppt.messages.compose` | `MessageController@compose` | |
| POST | `/parent-portal/messages` | `ppt.messages.store` | `MessageController@store` | `ComposeMessageRequest` |
| GET | `/parent-portal/messages/{threadId}` | `ppt.messages.thread` | `MessageController@thread` | |
| POST | `/parent-portal/messages/{threadId}/reply` | `ppt.messages.reply` | `MessageController@reply` | |
| POST | `/parent-portal/messages/{message}/read` | `ppt.messages.read` | `MessageController@markRead` | |
| GET | `/parent-portal/notifications` | `ppt.notifications.index` | `NotificationController@index` | |
| GET | `/parent-portal/notifications/preferences` | `ppt.notifications.preferences` | `NotificationController@preferences` | |
| POST | `/parent-portal/notifications/preferences` | `ppt.notifications.preferences.save` | `NotificationController@savePreferences` | `NotificationPreferencesRequest` |
| GET | `/parent-portal/notifications/{id}` | `ppt.notifications.show` | `NotificationController@show` | |
| POST | `/parent-portal/notifications/{id}/read` | `ppt.notifications.read` | `NotificationController@markRead` | |
| POST | `/parent-portal/notifications/read-all` | `ppt.notifications.read-all` | `NotificationController@markAllRead` | |

### 5.6 Requests & Forms Routes

| Method | URI | Route Name | Controller@Method | Notes |
|---|---|---|---|---|
| GET | `/parent-portal/leave` | `ppt.leave.index` | `LeaveController@index` | |
| GET | `/parent-portal/leave/create` | `ppt.leave.create` | `LeaveController@create` | |
| POST | `/parent-portal/leave` | `ppt.leave.store` | `LeaveController@store` | `ApplyLeaveRequest` |
| GET | `/parent-portal/leave/{leave}` | `ppt.leave.show` | `LeaveController@show` | |
| DELETE | `/parent-portal/leave/{leave}` | `ppt.leave.destroy` | `LeaveController@destroy` | `ParentLeavePolicy::withdraw()` |
| GET | `/parent-portal/consent-forms` | `ppt.consent-forms.index` | `ConsentFormController@index` | |
| GET | `/parent-portal/consent-forms/{id}` | `ppt.consent-forms.show` | `ConsentFormController@show` | |
| POST | `/parent-portal/consent-forms/{id}/sign` | `ppt.consent-forms.sign` | `ConsentFormController@sign` | `ConsentFormSignRequest` |

### 5.7 Meetings, Events & Extended Routes

| Method | URI | Route Name | Controller@Method | Notes |
|---|---|---|---|---|
| GET | `/parent-portal/ptm` | `ppt.ptm.index` | `PtmController@index` | |
| GET | `/parent-portal/ptm/{ptmEvent}/slots` | `ppt.ptm.slots` | `PtmController@slots` | |
| POST | `/parent-portal/ptm/{ptmEvent}/book` | `ppt.ptm.book` | `PtmController@book` | `PtmBookingRequest`; `lockForUpdate` |
| DELETE | `/parent-portal/ptm/booking/{booking}` | `ppt.ptm.cancel` | `PtmController@cancelBooking` | |
| GET | `/parent-portal/events` | `ppt.events.index` | `EventController@index` | |
| GET | `/parent-portal/events/{id}` | `ppt.events.show` | `EventController@show` | |
| POST | `/parent-portal/events/{id}/rsvp` | `ppt.events.rsvp` | `EventController@rsvp` | `EventRsvpRequest` |
| POST | `/parent-portal/events/{id}/volunteer` | `ppt.events.volunteer` | `EventController@volunteerSignup` | `EventRsvpRequest` |
| GET | `/parent-portal/events/{id}/ics` | `ppt.events.ics` | `EventController@icsDownload` | |
| GET | `/parent-portal/health-reports` | `ppt.health-reports.index` | `HealthReportController@index` | School setting gate |
| GET | `/parent-portal/health-reports/{type}` | `ppt.health-reports.show` | `HealthReportController@show` | per-record `parent_visible` filter |
| GET | `/parent-portal/health-reports/{record}/download` | `ppt.health-reports.download` | `HealthReportController@download` | |
| GET | `/parent-portal/transport` | `ppt.transport.index` | `TransportViewController@index` | |
| GET | `/parent-portal/documents` | `ppt.documents.index` | `DocumentController@index` | |
| GET | `/parent-portal/documents/{id}/download` | `ppt.documents.download` | `DocumentController@download` | Signed URL; fee gate |
| GET | `/parent-portal/documents/request` | `ppt.documents.request` | `DocumentController@requestForm` | |
| POST | `/parent-portal/documents/request` | `ppt.documents.store` | `DocumentController@storeRequest` | `DocumentRequestForm` |
| GET | `/parent-portal/documents/track` | `ppt.documents.track` | `DocumentController@trackRequest` | |
| GET | `/parent-portal/settings` | `ppt.settings.index` | `AccountSettingsController@index` | |
| POST | `/parent-portal/settings/profile` | `ppt.settings.profile` | `AccountSettingsController@profile` | |
| POST | `/parent-portal/settings/password` | `ppt.settings.password` | `AccountSettingsController@changePassword` | |
| GET | `/parent-portal/settings/devices` | `ppt.settings.devices` | `AccountSettingsController@devices` | |
| DELETE | `/parent-portal/settings/devices/{id}` | `ppt.settings.devices.logout` | `AccountSettingsController@logoutDevice` | |
| POST | `/parent-portal/settings/push-token` | `ppt.settings.push-token` | `AccountSettingsController@registerToken` | |
| DELETE | `/parent-portal/settings/push-token` | `ppt.settings.push-token.remove` | `AccountSettingsController@removeToken` | |

**Web route total: ~75 routes ✅**

### 5.8 API Routes (~18 routes)

**File:** `routes/api.php`
**Prefix:** `/api/v1/parent/`
**Standard middleware stack:** `auth:sanctum, parent.portal, throttle:60,1, EnsureTenantHasModule:ParentPortal` (SUG-PPT-22)
**Exceptions noted below**

| Method | URI | Route Name | Controller@Method | Middleware Override | Phase |
|---|---|---|---|---|---|
| POST | `/api/v1/parent/otp/send` | `api.ppt.otp.send` | `AuthController@sendOtp` | **No auth; no parent.portal**; `throttle:3,1` | P0 |
| POST | `/api/v1/parent/otp/verify` | `api.ppt.otp.verify` | `AuthController@verifyOtp` | **No auth; no parent.portal** | P0 |
| GET | `/api/v1/parent/dashboard` | `api.ppt.dashboard` | `ParentPortalController@dashboard` | Standard | P1 |
| GET | `/api/v1/parent/attendance` | `api.ppt.attendance` | `AttendanceViewController@api` | Standard | P1 |
| GET | `/api/v1/parent/timetable` | `api.ppt.timetable` | `TimetableViewController@api` | Standard | P1 |
| GET | `/api/v1/parent/homework` | `api.ppt.homework` | `HomeworkViewController@api` | Standard | P1 |
| GET | `/api/v1/parent/results` | `api.ppt.results` | `ResultViewController@api` | Standard | P1 |
| GET | `/api/v1/parent/fees` | `api.ppt.fees` | `FeeViewController@api` | Standard | P1 |
| POST | `/api/v1/parent/fees/pay` | `api.ppt.fees.pay` | `FeeViewController@pay` | Standard; `throttle:3,5` | P1 |
| POST | `/api/v1/parent/fees/razorpay-callback` | `api.ppt.fees.callback` | `FeeViewController@apiCallback` | **No auth; no parent.portal** (webhook) | P1 |
| GET | `/api/v1/parent/messages` | `api.ppt.messages` | `MessageController@api` | Standard | P2 |
| POST | `/api/v1/parent/messages` | `api.ppt.messages.store` | `MessageController@apiStore` | Standard | P2 |
| GET | `/api/v1/parent/notifications` | `api.ppt.notifications` | `NotificationController@api` | Standard | P2 |
| POST | `/api/v1/parent/notifications/preferences` | `api.ppt.notifications.prefs` | `NotificationController@savePreferences` | Standard | P2 |
| POST | `/api/v1/parent/children/switch` | `api.ppt.children.switch` | `ParentPortalController@switchChild` | Standard | P0 |
| GET | `/api/v1/parent/events` | `api.ppt.events` | `EventController@api` | Standard | P3 |
| GET | `/api/v1/parent/transport` | `api.ppt.transport` | `TransportViewController@index` | Standard | P3 |
| POST | `/api/v1/parent/push-token` | `api.ppt.push-token` | `AccountSettingsController@registerToken` | Standard | P2 |

**API route total: 18 routes ✅**
**Grand total: ~93 routes**

---

## Section 6 — Implementation Phases

---

### Phase P0 — Foundation: Auth + Middleware + Core Authorization
**Effort:** 2 person-days | **Blocks ALL other phases — deploy before feature work begins**

**FRs addressed:** FR-PPT-02 (OTP auth), middleware foundation, IDOR guards
**BRs addressed:** BR-PPT-001, BR-PPT-002, BR-PPT-010, BR-PPT-012, BR-PPT-013

#### Files to Create:

| File | Path | Purpose |
|---|---|---|
| Migration | `database/migrations/tenant/2026_xx_xx_create_ppt_tables.php` | All 6 ppt_* tables (use `PPT_Migration.php`) |
| Middleware | `app/Http/Middleware/EnsureParentPortalAccess.php` | `parent.portal` — three-condition check, returns 404 |
| Policy | `app/Policies/ParentChildPolicy.php` | 5 methods — IDOR guard on every data endpoint |
| Policy | `app/Policies/ParentMessagePolicy.php` | 2 methods — messaging teacher scope |
| Policy | `app/Policies/ParentLeavePolicy.php` | 2 methods — leave ownership |
| Controller | `app/Http/Controllers/AuthController.php` | OTP send/verify, login, logout, setup-password |
| FormRequest | `app/Http/Requests/SwitchChildRequest.php` | Child-swapping IDOR prevention |
| FormRequest | `app/Http/Requests/FeePaymentRequest.php` | Fee invoice ownership chain guard |
| Controller | `app/Http/Controllers/ParentPortalController.php` | dashboard (stub), children, switchChild |
| ServiceProvider | `app/Providers/ParentPortalServiceProvider.php` | Register middleware alias + all 3 policies |
| View | `resources/views/components/layouts/master.blade.php` | Base layout |
| View | `resources/views/components/child-switcher.blade.php` | Child switcher nav component |
| View | `resources/views/components/unread-badge.blade.php` | Notification badge |
| View | `resources/views/components/fee-status-chip.blade.php` | Fee colour chip |
| View | `resources/views/components/module-unavailable.blade.php` | Graceful degradation card |
| View | `resources/views/auth/login.blade.php` | SCR-PPT-01 |
| View | `resources/views/auth/otp-verify.blade.php` | SCR-PPT-02 |
| View | `resources/views/auth/setup-password.blade.php` | First-login password setup |
| Routes | `routes/web.php` + `routes/api.php` | Auth routes + base structure |

**ServiceProvider registration (in `ParentPortalServiceProvider::register()`):**
```php
// Middleware alias
$this->app['router']->aliasMiddleware('parent.portal', EnsureParentPortalAccess::class);

// Policy registration
Gate::policy(Student::class, ParentChildPolicy::class);
Gate::policy(PptMessage::class, ParentMessagePolicy::class);
Gate::policy(PptLeaveApplication::class, ParentLeavePolicy::class);
```

**Health profiles migration (add to P0 batch):**
```php
// database/migrations/tenant/2026_xx_xx_add_parent_visible_to_std_health_profiles.php
Schema::table('std_health_profiles', function (Blueprint $table) {
    $table->tinyInteger('parent_visible')->default(0)->after('dietary_restrictions')
          ->comment('1 = visible to parent in portal; 0 = hidden (default)');
});
```

**IDOR enforcement pattern (copy to every data-fetching controller method):**
```php
// At the start of EVERY controller method that returns student data:
$activeStudent = $this->getActiveStudent();  // from middleware-shared guardian
$this->authorize('viewChildData', $activeStudent);  // ParentChildPolicy::viewChildData()
```

**P0 Test scenarios to pass before P1:**

| Test Class | File | Scenarios |
|---|---|---|
| `ParentAuthTest` | `tests/Feature/ParentPortal/ParentAuthTest.php` | T-01: OTP login flow; first-login redirect; logout |
| `OtpRateLimitTest` | `tests/Feature/ParentPortal/OtpRateLimitTest.php` | T-02: 4th OTP in 1 hour → blocked; 5 failures → 30-min lockout |
| `ParentChildAccessTest` | `tests/Feature/ParentPortal/ParentChildAccessTest.php` | T-03: parent.portal middleware: STUDENT type → 404; STAFF → 404; no guardian → 404; can_access_portal=0 → 404 |
| `FeePaymentAuthTest` | `tests/Feature/ParentPortal/FeePaymentAuthTest.php` | T-04: ParentA cannot pay ParentB's child's invoice |
| `FeePaymentIdempotencyTest` | `tests/Feature/ParentPortal/FeePaymentIdempotencyTest.php` | T-05: webhook replay with same payment_id → no duplicate transaction |
| `SwitchChildTest` | `tests/Feature/ParentPortal/SwitchChildTest.php` | T-06: ParentA cannot switch to StudentB (non-owned child) |

---

### Phase P1 — Core Portal Features
**Effort:** 5 person-days | **Requires P0 complete**

**FRs addressed:** FR-PPT-01 (dashboard), FR-PPT-06 (attendance), FR-PPT-08 (timetable), FR-PPT-07 (homework), FR-PPT-09 (results), FR-PPT-05 (fee management)
**BRs addressed:** BR-PPT-005 (report card publish gate), BR-PPT-011 (fee gate), BR-PPT-018 (Razorpay idempotency)
**Suggestions addressed:** SUG-PPT-02 (dashboard batch query), SUG-PPT-03 (tagged cache), SUG-PPT-05 (active_student_id in DB), SUG-PPT-06 (Razorpay hosted checkout), SUG-PPT-07 (signed URLs), SUG-PPT-10 (action required section), SUG-PPT-11 (fee status chips)

#### Files to Create:

| File | Path | Purpose |
|---|---|---|
| Service | `app/Services/ParentDashboardService.php` | Dashboard batch query + Cache::tags() |
| Service | `app/Services/FeePaymentService.php` | Razorpay integration + idempotency |
| Controller | `app/Http/Controllers/AttendanceViewController.php` | SCR-PPT-05, 06 |
| Controller | `app/Http/Controllers/TimetableViewController.php` | SCR-PPT-07 |
| Controller | `app/Http/Controllers/HomeworkViewController.php` | SCR-PPT-08, 09 |
| Controller | `app/Http/Controllers/ResultViewController.php` | SCR-PPT-10, 11, 12 |
| Controller | `app/Http/Controllers/FeeViewController.php` | SCR-PPT-13–16 + webhook |
| Views (12) | `attendance/`, `timetable/`, `homework/`, `results/`, `fees/` | All academic + finance views |
| Routes | `routes/web.php` additions | Academic + finance routes |
| API routes | `routes/api.php` additions | 7 API endpoints (dashboard through fees) |

**P1 Test scenarios (T-07 to T-16):**
- T-07: Dashboard shows correct active student data
- T-08: Attendance calendar renders correct present/absent/leave statuses
- T-09: Homework list only shows homework for active student's class
- T-10: Result list only shows active student's results
- T-11: Report card download blocked when `is_published = 0`
- T-12: Report card download succeeds when `is_published = 1`
- T-13: Fee summary only shows active student's invoices
- T-14: Fee payment succeeds for own child's payable invoice
- T-15: Fee payment blocked for draft/cancelled invoice
- T-16: Fee payment receipt PDF generated and downloadable

---

### Phase P2 — Communication + Requests
**Effort:** 5 person-days | **Requires P1 complete**

**FRs addressed:** FR-PPT-04 (messaging), FR-PPT-10 (leave), FR-PPT-11 (consent forms), FR-PPT-12 (PTM), FR-PPT-03 (notification preferences), FR-PPT-17 (notification inbox), FR-PPT-18 (account settings)
**BRs addressed:** BR-PPT-003 (messaging scope), BR-PPT-004 (leave date), BR-PPT-008 (quiet hours), BR-PPT-009 (device tokens), BR-PPT-013 (consent immutability), BR-PPT-014 (PTM booking), BR-PPT-015 (concurrent booking), BR-PPT-017 (leave approval event)
**Suggestions addressed:** SUG-PPT-04 (queue notifications), SUG-PPT-09 (child switcher nav), SUG-PPT-13 (teacher photo in compose), SUG-PPT-14 (teacher photo in PTM), SUG-PPT-18 (message rate limit), SUG-PPT-21 (audit logging), SUG-PPT-22 (API rate limit)

#### Files to Create:

| File | Path | Purpose |
|---|---|---|
| Service | `app/Services/MessagingService.php` | Thread management, teacher scope, FULLTEXT search |
| Service | `app/Services/NotificationPreferenceService.php` | Quiet hours, urgent bypass, shouldDeliver() |
| Service | `app/Services/PtmSchedulingService.php` | Slot booking with `lockForUpdate()` |
| Controller | `app/Http/Controllers/MessageController.php` | ppt_messages CRUD |
| Controller | `app/Http/Controllers/NotificationController.php` | ntf_notifications view + prefs |
| Controller | `app/Http/Controllers/LeaveController.php` | ppt_leave_applications CRUD |
| Controller | `app/Http/Controllers/ConsentFormController.php` | ppt_consent_form_responses (immutable sign) |
| Controller | `app/Http/Controllers/PtmController.php` | PTM booking with race condition guard |
| Controller | `app/Http/Controllers/AccountSettingsController.php` | Device management, push tokens |
| FormRequest | `app/Http/Requests/ComposeMessageRequest.php` | Teacher scope authorization |
| FormRequest | `app/Http/Requests/ApplyLeaveRequest.php` | `after:today` date guard |
| FormRequest | `app/Http/Requests/NotificationPreferencesRequest.php` | Preference key validation |
| FormRequest | `app/Http/Requests/ConsentFormSignRequest.php` | `strip_tags()` + deadline check |
| FormRequest | `app/Http/Requests/PtmBookingRequest.php` | Slot + teacher validation |
| Event | `app/Events/LeaveApproved.php` | Dispatched when teacher approves leave (BR-PPT-017) |
| Views (17) | `messages/`, `notifications/`, `leave/`, `consent-forms/`, `ptm/`, `settings/` | All P2 screens |
| Routes | `routes/web.php` + `api.php` additions | All P2 routes |

**LeaveApproved event design (BR-PPT-017):**
```php
// app/Events/LeaveApproved.php
class LeaveApproved
{
    public function __construct(
        public readonly PptLeaveApplication $leaveApplication
    ) {}
}

// Dispatched from admin-side LeaveReviewController (not PPT module) when teacher approves:
event(new LeaveApproved($leaveApplication));

// Listener in attendance module (app/Listeners/MarkAttendanceAsLeave.php):
// Updates std_attendance for leave dates with status = 'Leave'
```

**P2 Test scenarios (T-17 to T-24):**
- T-17: Parent can only message teachers who teach active student's class
- T-18: Two parents simultaneously book same PTM slot → only one succeeds (concurrent DB test)
- T-19: Leave from_date = today → rejected (BR-PPT-004)
- T-20: Leave from_date = tomorrow → accepted
- T-21: Leave withdrawal when `status = Approved` → blocked
- T-22: Consent form double-sign → unique constraint error returned as validation message (not 500)
- T-23: Quiet hours: non-urgent notification → buffered; AbsenceAlert → delivered (BR-PPT-008)
- T-24: Audit log record created for every parent data-access action

---

### Phase P3 — Extended Features + REST API
**Effort:** 4 person-days | **Requires P2 complete**

**FRs addressed:** FR-PPT-13 (events), FR-PPT-14 (health), FR-PPT-15 (transport), FR-PPT-16 (documents), FR-PPT-02 (OTP API)
**BRs addressed:** BR-PPT-006 (medical record gate), BR-PPT-007 (counsellor report gate), BR-PPT-016 (volunteer capacity)
**Suggestions addressed:** SUG-PPT-01 (Sanctum for mobile), SUG-PPT-08 (PWA service worker), SUG-PPT-12 (homework calendar), SUG-PPT-16 (fee reminders), SUG-PPT-19 (consent PDF), SUG-PPT-20 (doc delivery estimate), SUG-PPT-23 (login notification), SUG-PPT-24 (re-auth for payments)

#### Files to Create:

| File | Path | Purpose |
|---|---|---|
| Controller | `app/Http/Controllers/EventController.php` | ppt_event_rsvps + volunteer + .ics |
| Controller | `app/Http/Controllers/HealthReportController.php` | std_health_profiles + counsellor gate |
| Controller | `app/Http/Controllers/TransportViewController.php` | TPT soft-dep view |
| Controller | `app/Http/Controllers/DocumentController.php` | ppt_document_requests + signed URL |
| FormRequest | `app/Http/Requests/EventRsvpRequest.php` | RSVP + volunteer validation |
| FormRequest | `app/Http/Requests/DocumentRequestForm.php` | Document type + reason |
| Views (13) | `events/`, `health-reports/`, `transport/`, `documents/` | All P3 screens |
| PWA | `public/sw.js` | Service worker for offline dashboard caching (SUG-PPT-08) |
| Routes | `routes/web.php` + `api.php` additions | All P3 routes (6 API routes) |

**Signed URL pattern for document downloads (BR-PPT-007 / SUG-PPT-07):**
```php
// DocumentController@download
$path = $document->fulfilled_media_id
    ? SystemMedia::findOrFail($document->fulfilled_media_id)->file_path
    : abort(404);

return redirect(Storage::temporaryUrl($path, now()->addHours(24)));
```

**Counsellor report gate (BR-PPT-007):**
```php
// HealthReportController@show (when type = 'counsellor')
$visible = app('school_settings')->get('parent_counsellor_report_visibility', false);
abort_unless($visible, 403, 'Counsellor reports are not enabled for this school.');
```

**P3 Test scenarios (T-25 to T-33):**
- T-25: Event RSVP created + updated correctly; volunteer capacity enforced (BR-PPT-016)
- T-26: Health overview with `parent_visible = 0` record → record not shown
- T-27: Health overview with `parent_visible = 1` record → record shown
- T-28: Counsellor report with school setting = 0 → 403
- T-29: Counsellor report with school setting = 1 → visible
- T-30: Document download returns signed URL (not direct path)
- T-31: Document download with `fee_paid = 0` and `fee_required > 0` → redirected to pay
- T-32: Transport view when TPT module not active → module-unavailable component (no 500)
- T-33: All 18 API endpoints return correct JSON structure with `sanctum` token auth

---

### Suggestion Assignment Summary

| Suggestion | Description | Phase |
|---|---|---|
| SUG-PPT-01 | Sanctum for mobile API auth | P3 (API routes) |
| SUG-PPT-02 | Dashboard batch query (max 5 queries) | P1 (ParentDashboardService) |
| SUG-PPT-03 | Tagged cache for dashboard | P1 (ParentDashboardService) |
| SUG-PPT-04 | Database queue for notifications | P2 (NotificationController dispatch) |
| SUG-PPT-05 | active_student_id in DB (not session) | P0 (ppt_parent_sessions) |
| SUG-PPT-06 | Razorpay hosted checkout | P1 (FeeViewController) |
| SUG-PPT-07 | Signed temporary URLs for documents | P3 (DocumentController) |
| SUG-PPT-08 | PWA service worker | P3 (public/sw.js) |
| SUG-PPT-09 | Child switcher in fixed nav bar | P0 (master layout + child-switcher component) |
| SUG-PPT-10 | Dashboard "Action required" section | P1 (dashboard.blade.php) |
| SUG-PPT-11 | Fee status colour chips | P0 (fee-status-chip component) |
| SUG-PPT-12 | Homework calendar view | P3 (homework/index.blade.php calendar tab) |
| SUG-PPT-13 | Teacher photo in compose dropdown | P2 (messages/compose.blade.php) |
| SUG-PPT-14 | Teacher photo + room on PTM slot screen | P2 (ptm/slots.blade.php) |
| SUG-PPT-15 | Auto-create portal account on enrollment | **Backlog** — RBS B1.2.5 welcome SMS; STD module work |
| SUG-PPT-16 | Fee payment reminders (3d, 1d, same-day) | **Backlog** — requires scheduled job in FIN module |
| SUG-PPT-17 | Auto leave prompt after 3 consecutive absences | **Backlog** — attendance listener job |
| SUG-PPT-18 | Message rate limit (1 per subject/24h) | P2 (ComposeMessageRequest + MessagingService) |
| SUG-PPT-19 | Principal digital signature on consent PDF | **Backlog** — requires school setup config |
| SUG-PPT-20 | Estimated delivery date on doc request | P3 (DocumentController@storeRequest) |
| SUG-PPT-21 | Log all access attempts including 403s | P2 (EnsureParentPortalAccess middleware audit) |
| SUG-PPT-22 | Per-guardian API rate limit (60 req/min) | P3 (`throttle:60,1` on API routes) |
| SUG-PPT-23 | Login notification via SMS | P0 (AuthController@verifyOtp — queue notification) |
| SUG-PPT-24 | Re-auth before payment/document download | **Backlog** — future security enhancement |

---

## Section 7 — Seeder Execution Order

```
PPT Module Seeders: NONE

ppt_* tables are portal state tables — no reference/master data to seed.
All data comes from other modules:

std_guardians, std_students, std_student_guardian_jnt → STD module (already seeded)
sys_users (parent accounts) → SYS module (created at enrollment)
fee_invoices, fee_student_assignments → FIN module
ntf_notifications → NTF module
```

### Test Data Requirements Per Phase

**Phase P0 tests require:**
- 2 parent users: `ParentA` + `ParentB` — `sys_users.user_type = 'PARENT'`
- `std_guardians` record for each
- `std_students` records: `StudentA` (linked to ParentA), `StudentB` (linked to ParentB)
- `std_student_guardian_jnt`: ParentA → StudentA (`can_access_parent_portal = 1`); ParentB → StudentB (`can_access_parent_portal = 1`)
- **ParentA has ZERO access to StudentB** — IDOR test baseline
- `fee_invoices` for StudentA (via `fee_student_assignments`) with status `'Published'` and `balance_amount > 0`
- `fee_invoices` for StudentB — ParentA must be blocked from paying this
- `sys_school_settings` active record for tenant

**Phase P1 tests require:**
- `sch_academic_sessions` records for each student
- `std_attendance` records: present, absent, leave entries for calendar rendering
- `hmw_assignments` for StudentA's class/section (both due + overdue)
- `exm_results` for StudentA: pass + fail results
- `exm_report_cards` for StudentA: one `is_published = 0`, one `is_published = 1`
- `fee_invoices` in statuses: `'Published'`, `'Partially Paid'`, `'Overdue'`, `'Draft'`, `'Cancelled'`

**Phase P2 tests require:**
- Teachers who teach StudentA's class/section: entries in `tt_timetable_cells` linking teacher → class/section
- `sys_users` records for those teachers with `user_type = 'TEACHER'`
- `sys_activity_logs` table available (for audit logging assertions)
- Consent form records (any table used by Event/Activity module) with deadline in future + past
- PTM event records + PTM slot records (2 slots for same teacher/event for concurrent test T-18)

**Phase P3 tests require:**
- `std_health_profiles` records: one with `parent_visible = 0`, one with `parent_visible = 1`
- `hpc_counsellor_reports` records (HPC module DDL)
- `sys_school_settings.parent_counsellor_report_visibility` = 0 (for T-28) and 1 (for T-29)
- `tpt_routes`, `tpt_vehicles`, `tpt_student_route_jnt` records for StudentA
- Event engine event records (at least 2: upcoming + past) for RSVP tests
- `ppt_document_requests` with `fee_paid = 0 / fee_required > 0` for fee-gate test T-31

---

## Section 8 — Testing Strategy

**Framework:** Pest (Feature tests) + PHPUnit (Unit tests)
**Location:** `tests/Feature/ParentPortal/` + `tests/Unit/ParentPortal/`

### 8.1 Feature Test Base Setup

```php
// All PPT feature tests
uses(Tests\TestCase::class, RefreshDatabase::class);

// Parent user factory helpers (to be added to DatabaseSeeder or test helpers)
function createParentA(Student $studentA): User
{
    $user = User::factory()->create(['user_type' => 'PARENT']);
    $guardian = Guardian::factory()->create(['user_id' => $user->id]);
    StudentGuardianJnt::factory()->create([
        'guardian_id' => $guardian->id,
        'student_id'  => $studentA->id,
        'can_access_parent_portal' => 1,
    ]);
    return $user;
}

// Queue::fake() — all notification dispatches
Queue::fake();

// Event::fake() — leave approval event assertions
Event::fake([LeaveApproved::class]);

// Mail::fake() — receipt email assertions
Mail::fake();

// OTP test helper — inject known OTP into cache
Cache::put('otp:'.$mobile, Hash::make('123456'), 600);
```

### 8.2 P0 Security Test Patterns

**IDOR test — cross-child resource access:**
```php
it('blocks parent A from paying child B invoice', function () {
    $studentA = Student::factory()->create();
    $studentB = Student::factory()->create();
    $parentA = createParentA($studentA);

    $assignmentB = FeeStudentAssignment::factory()->create(['student_id' => $studentB->id]);
    $invoiceB = FeeInvoice::factory()->create([
        'student_assignment_id' => $assignmentB->id,
        'status' => 'Published',
    ]);

    $this->actingAs($parentA)
         ->post(route('ppt.fees.pay'), ['invoice_ids' => [$invoiceB->id], 'total_amount' => 500])
         ->assertForbidden();  // FeePaymentRequest::authorize() returns false
});
```

**Child switch IDOR test:**
```php
it('blocks parent A from switching to child B', function () {
    $studentA = Student::factory()->create();
    $studentB = Student::factory()->create();  // No jnt record for parentA
    $parentA = createParentA($studentA);

    $this->actingAs($parentA)
         ->post(route('ppt.children.switch'), ['student_id' => $studentB->id])
         ->assertForbidden();  // SwitchChildRequest::authorize() returns false
});
```

**parent.portal middleware test — non-PARENT users get 404:**
```php
it('returns 404 for student user type on portal routes', function () {
    $student = User::factory()->create(['user_type' => 'STUDENT']);

    $this->actingAs($student)
         ->get(route('ppt.dashboard'))
         ->assertNotFound();  // 404, not 403 — prevents portal enumeration
});

it('returns 404 for staff user type on portal routes', function () {
    $staff = User::factory()->create(['user_type' => 'STAFF']);

    $this->actingAs($staff)
         ->get(route('ppt.dashboard'))
         ->assertNotFound();
});

it('returns 404 when can_access_parent_portal = 0', function () {
    $user = User::factory()->create(['user_type' => 'PARENT']);
    $guardian = Guardian::factory()->create(['user_id' => $user->id]);
    $student = Student::factory()->create();
    StudentGuardianJnt::factory()->create([
        'guardian_id' => $guardian->id,
        'student_id'  => $student->id,
        'can_access_parent_portal' => 0,  // explicitly disabled
    ]);

    $this->actingAs($user)
         ->get(route('ppt.dashboard'))
         ->assertNotFound();
});
```

**OTP rate limit test:**
```php
it('blocks 4th OTP request within 1 hour', function () {
    $mobile = '9876543210';

    // Simulate 3 prior sends
    RateLimiter::hit('otp-send:'.$mobile);
    RateLimiter::hit('otp-send:'.$mobile);
    RateLimiter::hit('otp-send:'.$mobile);

    $this->post(route('ppt.otp.send'), ['mobile' => $mobile])
         ->assertStatus(429);
});
```

### 8.3 P2 Concurrent PTM Booking Test (T-18)

```php
it('allows only one booking when two parents book the same PTM slot concurrently', function () {
    $slot = PtmSlot::factory()->create(['is_booked' => 0]);
    $parentA = createParentA(Student::factory()->create());
    $parentB = createParentA(Student::factory()->create());

    // Simulate concurrent requests via parallel execution
    // In practice: use DB transaction isolation; test via sequential with rollback check
    $resultA = rescue(fn() => app(PtmSchedulingService::class)->bookSlot(
        ['slot_id' => $slot->id, 'ptm_event_id' => $slot->ptm_event_id, 'teacher_user_id' => $slot->teacher_user_id],
        $parentA->guardian->id
    ));

    $resultB = rescue(fn() => app(PtmSchedulingService::class)->bookSlot(
        ['slot_id' => $slot->id, 'ptm_event_id' => $slot->ptm_event_id, 'teacher_user_id' => $slot->teacher_user_id],
        $parentB->guardian->id
    ));

    // Exactly one succeeds, one gets 409
    expect([$resultA instanceof PtmBooking, $resultB instanceof PtmBooking])
        ->toContain(true)->toContain(false);

    expect($slot->fresh()->is_booked)->toBeTrue();
});
```

### 8.4 Fee Payment Idempotency Test (T-05)

```php
it('does not create duplicate transaction on webhook replay', function () {
    Queue::fake();
    $student = Student::factory()->create();
    $parentA = createParentA($student);
    $assignment = FeeStudentAssignment::factory()->create(['student_id' => $student->id]);
    $invoice = FeeInvoice::factory()->create(['student_assignment_id' => $assignment->id, 'status' => 'Published']);

    $payload = [
        'razorpay_payment_id' => 'pay_test123',
        'razorpay_order_id'   => 'order_test456',
        'razorpay_signature'  => 'valid_hmac',  // mocked
    ];

    // First callback
    $this->post(route('ppt.fees.callback'), $payload)->assertOk();
    $count1 = FeeTransaction::count();

    // Replay the same webhook
    $this->post(route('ppt.fees.callback'), $payload)->assertOk();
    $count2 = FeeTransaction::count();

    expect($count2)->toBe($count1);  // No duplicate created
});
```

### 8.5 Minimum Coverage Targets

| Requirement | Test | Must Pass |
|---|---|---|
| All T-01 to T-06 pass before P1 work | P0 test suite | ✅ P0 gate |
| IDOR: ParentA cannot access StudentB's data | `FeePaymentAuthTest`, `SwitchChildTest`, `ParentChildAccessTest` | ✅ All phases |
| `parent.portal` middleware: non-PARENT → 404 (not 403) | `ParentChildAccessTest` | ✅ P0 |
| `parent.portal`: `can_access_parent_portal=0` → 404 | `ParentChildAccessTest` | ✅ P0 |
| OTP: 4th request in 1 hour → 429 blocked | `OtpRateLimitTest` | ✅ P0 |
| Fee webhook replay: same payment_id → no duplicate | `FeePaymentIdempotencyTest` | ✅ P1 |
| Consent double-sign → unique constraint (not 500) | `ConsentFormTest` | ✅ P2 |
| PTM concurrent booking → only one succeeds | `PtmConcurrentBookingTest` | ✅ P2 |
| Counsellor report: setting=0 → hidden; setting=1 → visible | `HealthReportTest` | ✅ P3 |
| Module unavailable → graceful card, no 500 | Each module's viewer test | ✅ All phases |

---

## Screen → Phase Assignment Summary (All 38 Screens)

| Phase | Screens | Count |
|---|---|---|
| P0 | SCR-PPT-01 (Login), SCR-PPT-02 (OTP Verify), SCR-PPT-04 (Child Switcher — as nav component) | 3 |
| P1 | SCR-PPT-03 (Dashboard), SCR-PPT-05–12 (Academic), SCR-PPT-13–16 (Finance) | 12 |
| P2 | SCR-PPT-17–19 (Messages), SCR-PPT-20–22 (Notifications), SCR-PPT-23–25 (Leave), SCR-PPT-26–27 (Consent Forms), SCR-PPT-28–29 (PTM), SCR-PPT-38 (Account Settings) | 13 |
| P3 | SCR-PPT-30–31 (Events), SCR-PPT-32–33 (Health), SCR-PPT-34 (Transport), SCR-PPT-35–37 (Documents) | 8 |
| P0 Components | Master layout, Child Switcher widget, Unread Badge, Fee Status Chip, Module Unavailable | 5 views |
| **Total** | | **41 screens + 5 components = ~46 views** |

---

## Quick Reference — Controller × Service × Policy

| Controller | Service Used | Policy Applied | FormRequest | Phase |
|---|---|---|---|---|
| AuthController | — | None (pre-auth) | — | P0 |
| ParentPortalController | ParentDashboardService | ParentChildPolicy | SwitchChildRequest | P0/P1 |
| AttendanceViewController | — | ParentChildPolicy | — | P1 |
| TimetableViewController | — | ParentChildPolicy | — | P1 |
| HomeworkViewController | — | ParentChildPolicy | — | P1 |
| ResultViewController | — | ParentChildPolicy | — | P1 |
| FeeViewController | FeePaymentService | ParentChildPolicy | FeePaymentRequest | P1 |
| MessageController | MessagingService | ParentMessagePolicy | ComposeMessageRequest | P2 |
| NotificationController | NotificationPreferenceService | ParentChildPolicy | NotificationPreferencesRequest | P2 |
| LeaveController | — | ParentChildPolicy + ParentLeavePolicy | ApplyLeaveRequest | P2 |
| ConsentFormController | — | ParentChildPolicy | ConsentFormSignRequest | P2 |
| PtmController | PtmSchedulingService | ParentChildPolicy | PtmBookingRequest | P2 |
| AccountSettingsController | NotificationPreferenceService | None (own account) | — | P2 |
| EventController | — | ParentChildPolicy | EventRsvpRequest | P3 |
| HealthReportController | — | ParentChildPolicy + school setting gate | — | P3 |
| TransportViewController | — | ParentChildPolicy | — | P3 |
| DocumentController | — | ParentChildPolicy | DocumentRequestForm | P3 |

---

*PPT Development Plan v1.0 — 2026-03-27*
*Generated from: PPT_2step_Prompt1.md Phase 3 | Source: PPT_FeatureSpec.md + PPT_DDL_Auth.md + PPT_ParentPortal_Requirement.md*
*Next step: Build P0 — run PPT_Migration.php, create EnsureParentPortalAccess + ParentChildPolicy, pass T-01 to T-06 before any feature work begins.*
