# STP — Student Portal
## Complete Development Plan (P0 → P1 → P2 → P3)
**Version:** 1.0 | **Generated:** 2026-03-27
**Source:** STP_FeatureSpec.md + STP_Security_Arch.md + Req v2 Section 14
**Developer:** Brijesh | **Estimated Total Effort:** ~15 person-days

---

> **Deploy Order: P0 → P1 → P2 → P3. Never merge P1/P2/P3 before P0 security fixes are live.**

---

## Table of Contents

1. [Controller Inventory](#1-controller-inventory)
2. [Service Inventory](#2-service-inventory)
3. [FormRequest Inventory](#3-formrequest-inventory)
4. [Blade View Inventory](#4-blade-view-inventory)
5. [Complete Route List](#5-complete-route-list)
6. [Implementation Phases](#6-implementation-phases)
7. [Seeder / Test Data Requirements](#7-seeder--test-data-requirements)
8. [Testing Strategy](#8-testing-strategy)

---

## 1. Controller Inventory

### 1.1 Overview (7 Controllers — Target State)

| Controller Class | File Path | Lines (current) | Lines (target) | Status |
|---|---|---|---|---|
| `StudentPortalController` | `app/Http/Controllers/StudentPortalController.php` | 172 (committed) | ~280 (after cleanup + new methods) | 🟡 Committed — needs fixes |
| `StudentPortalComplaintController` | `app/Http/Controllers/StudentPortalComplaintController.php` | 248 | ~200 (after FormRequest refactor) | 🟡 Committed — needs fixes |
| `NotificationController` | `app/Http/Controllers/NotificationController.php` | 140 | ~100 (after cleanup) | 🟡 Committed — needs fixes |
| `StudentLmsController` | `app/Http/Controllers/StudentLmsController.php` | 0 (not committed) | ~105 | ❌ Not yet in repo |
| `StudentProgressController` | `app/Http/Controllers/StudentProgressController.php` | 0 (not committed) | ~137 | ❌ Not yet in repo |
| `StudentTeachersController` | `app/Http/Controllers/StudentTeachersController.php` | 0 (not committed) | ~115 | ❌ Not yet in repo |
| `StudentTimetableController` | `app/Http/Controllers/StudentTimetableController.php` | 0 (not committed) | ~83 | ❌ Not yet in repo |

> **Note on line counts:** Req v2 Appendix 15.1 documents the intended line counts for all 7 controllers (1,317 total). Actual committed code has only 3 controllers — the 4 missing controllers must be committed/created as part of P1.

---

### 1.2 `StudentPortalController` (mega-controller)

**Committed methods (actual):**

| Method | Route Served | Issues | Action |
|---|---|---|---|
| `login()` | `GET /student-portal/login` | No rate limiting on login POST | P1: add `throttle:5,2` to login route |
| `dashboard()` | `GET /student-portal/dashboard` | Only loads notifications — missing attendance/timetable/homework/exams/fee data | P1: extract to `StudentPortalService::getDashboardData()` |
| `account()` | `GET /student-portal/account` | 3 tabs are view-only stubs | P2: implement password change, notification prefs, privacy |
| `academicInformation()` | `GET /student-portal/academic-information` | `currentFeeAssignemnt` typo ×3; no IDOR check on invoice chain | P0/P1: fix typo; IDOR handled via `findStudentInvoice()` |
| `viewInvoice($id)` | `GET /student-portal/view-invoice/{id}` | ⚠️ **P0 IDOR** — bare `findOrFail($id)`, no ownership check | P0: replace with `findStudentInvoice($id)` + `authorize()` |
| `payDueAmount($id)` | `GET /student-portal/pay-due-amount/pay-now/{id}` | ⚠️ **P0 IDOR** + `PaymentGateway::all()` | P0: replace with `findStudentInvoice($id)` + `authorize()` + P1: `::active()->get()` |
| `proceedPayment(Request $request)` | `GET /student-portal/pay-due-amount/proceed-payment` | ⚠️ **P0 IDOR** — `payable_id` unverified; route is GET not POST | P0: change to POST + use `ProcessPaymentRequest` |
| `index()` | `Route::resource` scaffold | **STUB — remove** | P1: delete |
| `create()` | scaffold | **STUB — remove** | P1: delete |
| `store()` | scaffold | **STUB — remove** | P1: delete |
| `show()` | scaffold | **STUB — remove** | P1: delete |
| `edit()` | scaffold | **STUB — remove** | P1: delete |
| `update()` | scaffold | **STUB — remove** | P1: delete |
| `destroy()` | scaffold | **STUB — remove** | P1: delete |

**Uncommitted methods described in req v2** (must be committed — all need to go into StudentPortalController or appropriate controller):

| Method | Route | Target Controller |
|---|---|---|
| `feeSummary()` | `GET /fee-summary` | `StudentPortalController` |
| `healthRecords()` | `GET /health-records` | `StudentPortalController` |
| `examSchedule()` | `GET /exam-schedule` | `StudentPortalController` |
| `idCard()` | `GET /student-id-card` | `StudentPortalController` |
| `results()` | `GET /results` | `StudentPortalController` |
| `noticeBoard()` | `GET /notice-board` | `StudentPortalController` |
| `studyResources()` | `GET /study-resources` | `StudentPortalController` |
| `prescribedBooks()` | `GET /prescribed-books` | `StudentPortalController` |
| `library()` | `GET /library` | `StudentPortalController` |
| `libraryMyBooks()` | `GET /library/my-books` | `StudentPortalController` |
| `schoolCalendar()` | `GET /school-calendar` | `StudentPortalController` |
| `applyLeave()` | `GET /apply-leave` | `StudentPortalController` |
| `transport()` | `GET /transport` | `StudentPortalController` |
| `hostel()` | `GET /hostel` | `StudentPortalController` |
| `progressCard()` | `GET /progress-card` | `StudentPortalController` |
| `performanceAnalytics()` | `GET /performance-analytics` | `StudentPortalController` |
| `myRecommendations()` | `GET /my-recommendations` | `StudentPortalController` |

**Methods needing `ProcessPaymentRequest`:**
- `proceedPayment()` — replace `Request` with `ProcessPaymentRequest`

**Methods needing `$this->authorize()` (StudentPortalPolicy):**
- `viewInvoice()` — `$this->authorize('viewInvoice', $feeInvoice)`
- `payDueAmount()` — `$this->authorize('payInvoice', $feeInvoice)`

**Methods to extract to `StudentPortalService`:**
- `dashboard()` → `StudentPortalService::getDashboardData()`
- `account()` attendance tab → `StudentPortalService::getAttendanceSummary()`
- `feeSummary()` → `StudentPortalService::getFeeSummary()`
- `syllabusProgress()` → `StudentPortalService::getSyllabusProgress()`

---

### 1.3 `StudentPortalComplaintController`

**Routes served:**
```
GET    /student-portal/complaint                      student-portal.complaint.index
GET    /student-portal/complaint/create               student-portal.complaint.create
POST   /student-portal/complaint                      student-portal.complaint.store
GET    /student-portal/complaint/{id}                 student-portal.complaint.show     (stub)
GET    /student-portal/complaint/{id}/edit            student-portal.complaint.edit     (stub)
PUT    /student-portal/complaint/{id}                 student-portal.complaint.update   (stub)
DELETE /student-portal/complaint/{id}                 student-portal.complaint.destroy  (stub)
GET    /student-portal/complaint/ajax/subcategories/{c}      student-portal.complaint.subCategories
GET    /student-portal/complaint/ajax/subcategory-meta/{c}   student-portal.complaint.categoryMeta
```

**Current issues:**
- `store()` uses inline `$request->validate()` + `$request->merge()` anti-pattern
- Hard-coded `(int) $request->complainant_type_id === 104` at lines 73 and 125
- `index()` uses `->get()` — no pagination
- `complainant_user_id` accepted from client (not forced to `auth()->id()`)
- `User::select('id','name')->get()` in `create()` loads ALL system users (potential data leak)

**Required changes (P1):**
1. Replace `store(Request $request)` signature with `store(StoreComplaintRequest $request)`
2. Remove `$request->validate()` and `$request->merge()` blocks from `store()` — handled by FormRequest
3. Remove hard-coded ID `104` checks — complainant_type resolved in `StoreComplaintRequest::prepareForValidation()`
4. Change `index()`: `Complaint::where('created_by', Auth::id())->get()` → `->paginate(15)`
5. Remove `User::select('id','name')->get()` from `create()` (portal complaints are always self-identified)
6. Remove show/edit/update/destroy stub methods (students cannot edit/delete complaints after submission)

---

### 1.4 `NotificationController`

**Routes served:**
```
GET    /student-portal/test-notification                       student-portal.test-notification  ← REMOVE
GET    /student-portal/all-notifications                       student-portal.all-notifications
POST   /student-portal/notifications/mark-all-read             student-portal.notifications.mark-all-read
GET    /student-portal/notifications/{id}/mark-read            student-portal.notifications.mark-read  ← change to POST
```

**Duplicate methods note:** `NotificationController` has two pairs of similar methods:
- `markRead()` (uses `auth()->user()->notifications()->findOrFail($id)`) — correct scoping ✅
- `markAsRead()` (uses `Notification::where(...)`) — duplicate; use `markRead()` pattern

- `markAllRead()` (uses `->markAsRead()`) — correct ✅
- `markAllAsRead()` (uses `->update(['read_at' => now()])`) — duplicate; consolidate

**Required changes (P1):**
1. Remove duplicate `markAsRead()` (alias of markRead) and `markAllAsRead()` (alias of markAllRead)
2. Change `mark-read` route from GET → POST
3. Remove `test-notification` route and `testNotification()` method

---

### 1.5 Controllers to Create (P1 — commit / implement)

#### `StudentLmsController` (~105 lines)
```
File: app/Http/Controllers/StudentLmsController.php
Route: GET /student-portal/my-learning → index()
```
Methods: `index()` — loads Homework (published, not submitted by student, limit N), ExamAllocations (published, future, class+section+student scope), QuizAllocations, QuestAllocations. Pass to `learning/index` view.

#### `StudentProgressController` (~137 lines)
```
File: app/Http/Controllers/StudentProgressController.php
Routes:
  GET /student-portal/my-attendance    → attendance()
  GET /student-portal/syllabus-progress → syllabusProgress()
```
Methods:
- `attendance()` — calls `StudentPortalService::getAttendanceSummary()`; passes byMonth data to view
- `syllabusProgress()` — calls `StudentPortalService::getSyllabusProgress()`; passes grouped data to view

#### `StudentTeachersController` (~115 lines)
```
File: app/Http/Controllers/StudentTeachersController.php
Route: GET /student-portal/my-teachers → index()
```
Method: `index()` — queries `TimetableCell` for student's class+section+active timetable; groups unique teachers by `teacher_id` with subjects and day schedule grid.

#### `StudentTimetableController` (~83 lines)
```
File: app/Http/Controllers/StudentTimetableController.php
Route: GET /student-portal/my-timetable → index()
```
Method: `index()` — queries `TimetableCell` + `SchoolDay`; builds `[day_of_week][period_ord] => cell` grid; filters `is_break = false`; handles `noSession` state.

---

## 2. Service Inventory

### `StudentPortalService`

```
File:      Modules/StudentPortal/app/Services/StudentPortalService.php
Namespace: Modules\StudentPortal\app\Services
Create:    php artisan module:make-service StudentPortalService StudentPortal
```

**Constructor dependencies:** None required (all models accessed via static Eloquent calls).

**Public Methods:**

| Method | Signature | Replaces | Performance Impact |
|---|---|---|---|
| `getDashboardData` | `getDashboardData(Student $student): array` | `StudentPortalController@dashboard` (~110 lines of scattered queries) | Reduces ~6 separate queries to 1 eager-load chain + 4 scoped queries |
| `getAttendanceSummary` | `getAttendanceSummary(Student $student, ?int $sessionId): array` | Attendance stats block in `StudentProgressController@attendance` | 1 query; PHP grouping replaces N+1 per-month queries |
| `getFeeSummary` | `getFeeSummary(Student $student): array` | Fee summary block (works from already eager-loaded relationship — 0 extra queries) | 0 additional queries if `currentFeeAssignment.invoices` already loaded |
| `getSyllabusProgress` | `getSyllabusProgress(Student $student, int $classId, int $sectionId, int $sessionId): array` | `StudentProgressController@syllabusProgress` | 1 query; status derived in PHP from scheduled_date vs today |

**Dashboard N+1 fix:**

| | Current (uncommitted) | After Service Extraction |
|---|---|---|
| Queries on `/dashboard` | ~6 separate: student, session, attendance count, timetable cells, homework count, exam count, fee sum | 1 eager-load chain + 4 scoped aggregate queries |
| Pattern | Multiple `->where()->count()` and `->where()->get()` calls scattered in 110-line controller method | `$student->loadMissing([...])` + 4 targeted queries |
| N+1 risk | High — `currentSession->classSection->class` accessed multiple times | Eliminated via `loadMissing` |

Full implementation: See `STP_Security_Arch.md` Part 3.

---

## 3. FormRequest Inventory

| Class | File | Controller Method | `authorize()` Logic | Key Rules | Priority |
|---|---|---|---|---|---|
| `ProcessPaymentRequest` | `app/Http/Requests/ProcessPaymentRequest.php` | `StudentPortalController@proceedPayment` | Verifies `payable_id` belongs to `auth()->user()->student` via `feeStudentAssignment` chain; checks payable status + balance > 0 | `amount` (numeric, min:0.01), `payable_type` (in:fee_invoice), `payable_id` (integer), `gateway` (in:razorpay,stripe,paytm,phonepe) | **P0** |
| `StoreComplaintRequest` | `app/Http/Requests/StoreComplaintRequest.php` | `StudentPortalComplaintController@store` | `auth()->user()->hasRole('Student')` | dropdown ID resolution in `prepareForValidation()`; `strip_tags()` on description; force `complainant_user_id = auth()->id()`; `complaint_img` mimes:jpg,jpeg,png,pdf, max:5120 | P1 |
| `LeaveApplicationRequest` | `app/Http/Requests/LeaveApplicationRequest.php` | `StudentPortalController@storeLeave` (future) | `auth()->user()->hasRole('Student\|Parent')` | `start_date` after_or_equal:today, `end_date` after_or_equal:start_date, reason max:1000, attachment mimes:jpg,jpeg,png,pdf | P2 |
| `PasswordChangeRequest` | `app/Http/Requests/PasswordChangeRequest.php` | `StudentPortalController@changePassword` (future) | `auth()->check()` | `current_password` Hash::check validation, `password` confirmed + min:8 + mixedCase + numbers | P2 |

**Replaces inline validation patterns:**

| Controller | Current Pattern | After FormRequest |
|---|---|---|
| `StudentPortalController@proceedPayment` | `$request->validate([...])` with no ownership check | `ProcessPaymentRequest` — ownership in `authorize()` |
| `StudentPortalComplaintController@store` | `$request->merge([...]) + $request->validate([...])` | `StoreComplaintRequest` — merge in `prepareForValidation()` |
| `StudentPortalController@storeLeave` (future) | None — stub | `LeaveApplicationRequest` |
| `StudentPortalController@changePassword` (future) | None — stub | `PasswordChangeRequest` |

Full class implementations: See `STP_Security_Arch.md` Part 2.

---

## 4. Blade View Inventory

### 4.1 Existing Views by Area (57 total per req v2)

| Area | View Files | Status | Data Change Needed |
|---|---|---|---|
| **Academic Information** | `academic-information/details.blade.php`, `invoice.blade.php`, `payment-page.blade.php`, `_partials/_academic-performance.blade.php`, `_partials/_attendance-records.blade.php`, `_partials/_fee-details.blade.php`, `_partials/_guardian-information.blade.php`, `_partials/_information-card.blade.php`, `_partials/_scripts.blade.php`, `_partials/_student-details.blade.php` | 🟡 | P0: remove `$request->student_id` scope assumption; pass verified invoice object |
| **Account (tabs)** | `account/index.blade.php`, `_partials/_profile-information.blade.php`, `_partials/_billing-payments.blade.php`, `_partials/_notification-settings.blade.php`, `_partials/_privacy-settings.blade.php`, `_partials/_security-settings.blade.php`, `_partials/_sidebar-menu.blade.php` | 🟡 | P2: wire security/notification/privacy tabs to backend endpoints |
| **Attendance** | `attendance/index.blade.php` | ✅ | — |
| **Auth** | `auth/login.blade.php` | ✅ | — |
| **Calendar** | `calendar/index.blade.php` | ❌ Stub | P2: wire to school calendar data source |
| **Complaint** | `complaint/index.blade.php`, `complaint/create.blade.php` | ✅ | P1: add pagination links to index; update AJAX form to handle FormRequest errors |
| **Components/Layout** | `components/layouts/master.blade.php` | ✅ | — |
| **Dashboard** | `dashboard/index.blade.php` | 🟡 | P1: ensure view accepts all 6 keys from `getDashboardData()` |
| **Exams** | `exams/schedule.blade.php` | ✅ | — |
| **Fee** | `fee/summary.blade.php` | ✅ | — |
| **Health** | `health/index.blade.php` | ✅ | — |
| **Homework** | `homework/index.blade.php` | 🟡 | P2: add submission form with file upload |
| **Hostel** | `hostel/index.blade.php` | ❌ Stub | P3: wire when HST module complete |
| **ID Card** | `id-card/index.blade.php` | ✅ | P2: add PDF download button → `/student-id-card/download` |
| **Learning** | `learning/index.blade.php` + up to 4 sub-views | ✅ | P2: wire quiz/quest player links |
| **Leave** | `leave/index.blade.php` | ❌ Stub | P2: add form with date range + reason + attachment |
| **Library** | `library/index.blade.php`, `library/my-books.blade.php` | ✅ | — |
| **Notice Board** | `notice-board/index.blade.php` | 🟡 Wrong source | P2: change data source — see note below |
| **Notification** | `notification/index.blade.php`, `_partials/_notification_card.blade.php`, `_partials/_scripts.blade.php`, `_partials/_styles.blade.php` | ✅ | P1: update mark-read link from `<a href>` to `<form POST>` |
| **Online Exam** | `online-exam/index.blade.php` | ❌ Stub | P3: wire to LmsExam online player |
| **Quest** | `quest/index.blade.php` | ❌ Stub | P2: wire routes + controller method |
| **Quiz** | `quiz/index.blade.php` | ❌ Stub | P2: wire routes + controller method |
| **Reports** | `reports/progress-card.blade.php`, `reports/analytics.blade.php`, `reports/recommendations.blade.php` | ✅ / 🟡 | P2: add PDF download to progress-card; fix analytics missing subject charts |
| **Resources** | `resources/index.blade.php`, `resources/prescribed-books.blade.php` | ✅ | — |
| **Results** | `results/index.blade.php` | 🟡 No marks | P2: integrate ExamResult model for marks/grades |
| **Syllabus** | `syllabus/progress.blade.php` | ✅ | — |
| **Teachers** | `teachers/index.blade.php` | ✅ | — |
| **Timetable** | `timetable/index.blade.php` | ✅ | P1: highlight current day column |
| **Transport** | `transport/index.blade.php` | ✅ | — |
| **Misc** | `index.blade.php` (scaffold), `coming-soon.blade.php` | Remove scaffold | P1: delete `index.blade.php` scaffold |

### 4.2 Notice Board Data Source — Design Decision Required

**Current:** `noticeBoard()` reads `auth()->user()->notifications()` — this is the user's personal notification inbox, NOT a school announcement board.

**DDL check result:** Neither `sch_notices` nor `sys_announcements` table exists in `tenant_db_v2.sql`.

**Options:**
1. **Option A — Use existing `sys_notifications` with a filter:** Filter to notifications of type `NOTICE` or `ANNOUNCEMENT` (if notification type column exists). No new table needed.
2. **Option B — Create `sch_notices` table** (requires tenant migration): New table with `title`, `body`, `published_at`, `class_target_json`, `expires_at`. Requires SchoolSetup module integration.
3. **Option C — Redirect to dashboard notice widget** until Option B is ready.

**Recommendation:** Use Option A temporarily (filter `sys_notifications` by category = 'ANNOUNCEMENT'); plan Option B for a future SchoolCommunication module.

### 4.3 New Views to Create

| View File | Purpose | Priority |
|---|---|---|
| `account/_change-password.blade.php` | Password change form (current tab is read-only) | P2 |
| `account/_notification-preferences.blade.php` | Notification channel toggles | P2 |
| `leave/create.blade.php` | Leave application form (start/end date, reason, attachment) | P2 |
| `id-card/download.blade.php` | Minimal DomPDF template for ID card | P2 |
| `homework/submit.blade.php` | Homework submission form with file upload | P2 |

---

## 5. Complete Route List

### 5.1 Web Routes — Current + Target (~65 web routes after completion)

**Route group definition (target state):**
```php
Route::middleware([
    'auth',
    'verified',
    'role:Student|Parent',              // Fix 3 — currently missing
    'EnsureTenantHasModule:StudentPortal', // Fix 4 — currently missing
])->prefix('student-portal')->name('student-portal.')->group(function () {
    // ... all routes below ...
});

// Public (outside auth group):
Route::get('/student-portal/login', [StudentPortalController::class, 'login'])->name('student-portal.login');
Route::post('/student-portal/login', [StudentPortalController::class, 'processLogin'])->name('student-portal.login.post')->middleware('throttle:5,2');
```

| Method | URI | Route Name | Controller@method | Status | Notes |
|---|---|---|---|---|---|
| GET | `student-portal/login` | `student-portal.login` | `StudentPortalController@login` | ✅ | Public; outside auth group |
| POST | `student-portal/login` | `student-portal.login.post` | (Fortify or custom) | 📐 Add | Add `throttle:5,2` |
| GET | `student-portal/dashboard` | `student-portal.dashboard` | `StudentPortalController@dashboard` | ✅ Committed | Needs `StudentPortalService` injection |
| GET | `student-portal/account` | `student-portal.account` | `StudentPortalController@account` | ✅ Committed | 3 tabs stub |
| POST | `student-portal/account/password` | `student-portal.account.password` | `StudentPortalController@changePassword` | ❌ Add P2 | `PasswordChangeRequest` |
| POST | `student-portal/account/notifications` | `student-portal.account.notifications` | `StudentPortalController@saveNotificationPrefs` | ❌ Add P2 | — |
| GET | `student-portal/academic-information` | `student-portal.academic-information` | `StudentPortalController@academicInformation` | ✅ Committed | Fix typo callers |
| GET | `student-portal/view-invoice/{invoice}` | `student-portal.view-invoice` | `StudentPortalController@viewInvoice` | 🟡 **P0 IDOR** | Fix: `findStudentInvoice()` |
| GET | `student-portal/pay-due-amount/pay-now/{invoice}` | `student-portal.pay-due-amount` | `StudentPortalController@payDueAmount` | 🟡 **P0 IDOR** | Fix: `findStudentInvoice()` |
| ~~GET~~ **POST** | `student-portal/pay-due-amount/proceed-payment` | `student-portal.proceed-payment` | `StudentPortalController@proceedPayment` | 🟡 **P0** | Change GET→POST; `throttle:3,5`; `ProcessPaymentRequest` |
| GET | `student-portal/fee-summary` | `student-portal.fee-summary` | `StudentPortalController@feeSummary` | ❌ Not committed | Commit P1 |
| GET | `student-portal/my-timetable` | `student-portal.my-timetable` | `StudentTimetableController@index` | ❌ Not committed | Commit P1 |
| GET | `student-portal/my-attendance` | `student-portal.my-attendance` | `StudentProgressController@attendance` | ❌ Not committed | Commit P1 |
| GET | `student-portal/syllabus-progress` | `student-portal.syllabus-progress` | `StudentProgressController@syllabusProgress` | ❌ Not committed | Commit P1 |
| GET | `student-portal/results` | `student-portal.results` | `StudentPortalController@results` | ❌ Not committed | Commit P1; P2: add marks |
| GET | `student-portal/my-teachers` | `student-portal.my-teachers` | `StudentTeachersController@index` | ❌ Not committed | Commit P1 |
| GET | `student-portal/health-records` | `student-portal.health-records` | `StudentPortalController@healthRecords` | ❌ Not committed | Commit P1 |
| GET | `student-portal/progress-card` | `student-portal.progress-card` | `StudentPortalController@progressCard` | ❌ Not committed | Commit P1 |
| GET | `student-portal/progress-card/{report}/download` | `student-portal.progress-card.download` | `StudentPortalController@downloadProgressCard` | ❌ Add P2 | Link to HPC PDF route |
| GET | `student-portal/performance-analytics` | `student-portal.performance-analytics` | `StudentPortalController@performanceAnalytics` | ❌ Not committed | Commit P1 |
| GET | `student-portal/my-recommendations` | `student-portal.my-recommendations` | `StudentPortalController@myRecommendations` | ❌ Not committed | Commit P1 |
| GET | `student-portal/my-learning` | `student-portal.my-learning` | `StudentLmsController@index` | ❌ Not committed | Commit P1 |
| GET | `student-portal/exam-schedule` | `student-portal.exam-schedule` | `StudentPortalController@examSchedule` | ❌ Not committed | Commit P1 |
| GET | `student-portal/homework` | `student-portal.homework` | `StudentLmsController@homework` | ❌ Add P2 | Dedicated homework list |
| POST | `student-portal/homework/{homework}/submit` | `student-portal.homework.submit` | `StudentLmsController@submitHomework` | ❌ Add P2 | `HomeworkSubmission::create()` |
| GET | `student-portal/quiz` | `student-portal.quiz` | `StudentLmsController@quiz` | ❌ Add P2 | Wire to quiz/index view |
| GET | `student-portal/quest` | `student-portal.quest` | `StudentLmsController@quest` | ❌ Add P2 | Wire to quest/index view |
| GET | `student-portal/notice-board` | `student-portal.notice-board` | `StudentPortalController@noticeBoard` | ❌ Not committed | Commit P1; P2: fix data source |
| GET | `student-portal/school-calendar` | `student-portal.school-calendar` | `StudentPortalController@schoolCalendar` | ❌ Not committed | P2: wire data source |
| GET | `student-portal/student-id-card` | `student-portal.student-id-card` | `StudentPortalController@idCard` | ❌ Not committed | Commit P1 |
| GET | `student-portal/student-id-card/download` | `student-portal.student-id-card.download` | `StudentPortalController@downloadIdCard` | ❌ Add P2 | DomPDF minimal PDF |
| GET | `student-portal/apply-leave` | `student-portal.apply-leave` | `StudentPortalController@applyLeave` | ❌ Not committed | P2: add form |
| POST | `student-portal/apply-leave` | `student-portal.apply-leave.store` | `StudentPortalController@storeLeave` | ❌ Add P2 | `LeaveApplicationRequest`; needs `std_leave_applications` migration |
| GET | `student-portal/transport` | `student-portal.transport` | `StudentPortalController@transport` | ❌ Not committed | Commit P1 |
| GET | `student-portal/hostel` | `student-portal.hostel` | `StudentPortalController@hostel` | ❌ Not committed | P3: wire when HST module ready |
| GET | `student-portal/library` | `student-portal.library` | `StudentPortalController@library` | ❌ Not committed | Commit P1 |
| GET | `student-portal/library/my-books` | `student-portal.library.my-books` | `StudentPortalController@libraryMyBooks` | ❌ Not committed | Commit P1 |
| GET | `student-portal/study-resources` | `student-portal.study-resources` | `StudentPortalController@studyResources` | ❌ Not committed | Commit P1 |
| GET | `student-portal/prescribed-books` | `student-portal.prescribed-books` | `StudentPortalController@prescribedBooks` | ❌ Not committed | Commit P1 |
| GET,POST,PUT,DELETE | `student-portal/complaint/*` | `student-portal.complaint.*` | `StudentPortalComplaintController` | ✅ Committed | P1: StoreComplaintRequest + pagination |
| GET | `student-portal/complaint/ajax/subcategories/{c}` | `student-portal.complaint.subCategories` | `StudentPortalComplaintController@getCategories` | ✅ | — |
| GET | `student-portal/complaint/ajax/subcategory-meta/{c}` | `student-portal.complaint.categoryMeta` | `StudentPortalComplaintController@getCategoryMeta` | ✅ | — |
| GET | `student-portal/all-notifications` | `student-portal.all-notifications` | `NotificationController@allNotifications` | ✅ | — |
| POST | `student-portal/notifications/mark-all-read` | `student-portal.notifications.mark-all-read` | `NotificationController@markAllRead` | ✅ | — |
| ~~GET~~ **POST** | `student-portal/notifications/{id}/mark-read` | `student-portal.notifications.mark-read` | `NotificationController@markRead` | 🟡 **P1** | Change GET→POST + `throttle:10,1` |

**Route count: ~52 web routes → ~65 after P2 additions**

### 5.2 API Routes — Planned (9 endpoints — P3)

**Route group:** `auth:sanctum` + `role:Student|Parent` + prefix `/api/v1/portal/`

| Method | Endpoint | Description | Controller@method |
|---|---|---|---|
| GET | `/api/v1/portal/profile` | Student profile JSON | `StudentPortalApiController@profile` |
| GET | `/api/v1/portal/invoices` | Invoice list for student | `StudentPortalApiController@invoices` |
| POST | `/api/v1/portal/pay` | Initiate payment (reuses ProcessPaymentRequest) | `StudentPortalApiController@pay` |
| GET | `/api/v1/portal/timetable` | Current week timetable JSON | `StudentPortalApiController@timetable` |
| GET | `/api/v1/portal/attendance` | Attendance summary JSON | `StudentPortalApiController@attendance` |
| GET | `/api/v1/portal/notifications` | Notification list JSON | `StudentPortalApiController@notifications` |
| POST | `/api/v1/portal/notifications/read` | Mark notification(s) read | `StudentPortalApiController@markRead` |
| GET | `/api/v1/portal/homework` | Pending homework list JSON | `StudentPortalApiController@homework` |
| GET | `/api/v1/portal/exams` | Exam schedule JSON | `StudentPortalApiController@exams` |

**Total target: ~65 web + 9 API = ~74 routes after full completion**

---

## 6. Implementation Phases

### Phase P0 — Security Critical
**Effort:** 1 person-day | **Deploy:** Immediately, before any other work

**FRs addressed:** FR-STP-04 (Invoice IDOR), FR-STP-05 (Payment IDOR)
**Security issues resolved:** 4 P0 + 1 undocumented (role middleware)

**Files to change:**

| Action | File | Change |
|---|---|---|
| MODIFY | `routes/tenant.php` | Add `role:Student\|Parent` to portal route group (undocumented P0 finding) |
| MODIFY | `routes/tenant.php` | Add `EnsureTenantHasModule:StudentPortal` to portal route group |
| MODIFY | `routes/tenant.php` | Change `proceed-payment` route: GET → POST + `throttle:3,5` |
| MODIFY | `routes/tenant.php` | Remove `test-notification` route |
| MODIFY | `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php` | Add `findStudentInvoice()` private helper |
| MODIFY | `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php` | Fix `viewInvoice()`: use `findStudentInvoice()` + `$this->authorize('viewInvoice', ...)` |
| MODIFY | `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php` | Fix `payDueAmount()`: use `findStudentInvoice()` + `$this->authorize('payInvoice', ...)` |
| MODIFY | `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php` | Fix `proceedPayment()`: use `ProcessPaymentRequest` (replaces `Request`) |
| CREATE | `Modules/StudentPortal/app/Http/Requests/ProcessPaymentRequest.php` | Full class — ownership check in `authorize()` |
| CREATE | `Modules/StudentPortal/app/Policies/StudentPortalPolicy.php` | `viewInvoice`, `payInvoice`, `createComplaint` methods |
| MODIFY | `Modules/StudentPortal/app/Providers/StudentPortalServiceProvider.php` | Register `Gate::policy(FeeInvoice::class, StudentPortalPolicy::class)` |

**Tests required before marking P0 complete:**

| Test ID | Scenario | Expected |
|---|---|---|
| T-STP-001 | Student A accesses student B's invoice via `view-invoice/{id}` | 404 |
| T-STP-002 | Student A POSTs `proceed-payment` with student B's `payable_id` | 403 or 422 |
| T-STP-003 | Admin user (non-Student) accesses `/student-portal/dashboard` | 403 |
| T-STP-004 | Unauthenticated request to `/student-portal/dashboard` | Redirect to login |
| T-STP-005 | Student marks another user's notification as read | 403 or 404 |

---

### Phase P1 — High Priority Quality Fixes
**Effort:** 3 person-days | **Deploy:** Sprint 1

**FRs addressed:** FR-STP-27 (notifications), FR-STP-28 (complaints), FR-STP-01 (login rate limit), plus commit all 22 built-but-uncommitted screens

**Files to change / create:**

| Action | File | Change |
|---|---|---|
| MODIFY | `routes/tenant.php` | Change `mark-read` from GET → POST + `throttle:10,1` |
| MODIFY | `routes/tenant.php` | Add all ~40 uncommitted routes (timetable, attendance, syllabus, exams, teachers, health, library, transport, etc.) |
| MODIFY | `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php` | Remove 7 scaffold stub methods (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`) |
| MODIFY | `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php` | Fix `currentFeeAssignemnt` → `currentFeeAssignment` (3 locations) — **after STD team fixes model** |
| MODIFY | `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php` | Fix `payDueAmount()`: `PaymentGateway::all()` → `::active()->get()` |
| MODIFY | `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php` | Inject `StudentPortalService`; refactor `dashboard()` to call `getDashboardData()` |
| MODIFY | `Modules/StudentPortal/app/Http/Controllers/StudentPortalComplaintController.php` | Use `StoreComplaintRequest`; remove inline validation + merge; paginate index; remove stub show/edit/update/destroy; remove `User::all()` from create() |
| MODIFY | `Modules/StudentPortal/app/Http/Controllers/NotificationController.php` | Remove `testNotification()` + `markAsRead()` + `markAllAsRead()` duplicates |
| CREATE | `Modules/StudentPortal/app/Http/Requests/StoreComplaintRequest.php` | Full class (see `STP_Security_Arch.md`) |
| CREATE | `Modules/StudentPortal/app/Services/StudentPortalService.php` | Full class (see `STP_Security_Arch.md`) |
| COMMIT | `Modules/StudentPortal/app/Http/Controllers/StudentLmsController.php` | Commit + wire `GET /my-learning` route |
| COMMIT | `Modules/StudentPortal/app/Http/Controllers/StudentProgressController.php` | Commit + wire `GET /my-attendance` + `GET /syllabus-progress` |
| COMMIT | `Modules/StudentPortal/app/Http/Controllers/StudentTeachersController.php` | Commit + wire `GET /my-teachers` |
| COMMIT | `Modules/StudentPortal/app/Http/Controllers/StudentTimetableController.php` | Commit + wire `GET /my-timetable` |
| MODIFY | `Modules/StudentPortal/routes/web.php` | Remove scaffold `Route::resource('studentportals', ...)` |
| MODIFY (STD team) | `Modules/StudentProfile/app/Models/Student.php` | Rename `currentFeeAssignemnt()` → `currentFeeAssignment()` |
| MODIFY | `Modules/StudentPortal/resources/views/notification/*` | Update mark-read `<a href>` links → `<form method="POST">` |

**Tests for P1:**

| Test ID | Scenario |
|---|---|
| T-STP-010 | Timetable grid populated with correct subjects; break cells excluded |
| T-STP-011 | Student with no session sees `noSession` state — no exception |
| T-STP-012 | Dashboard fee summary shows correct total/paid/due |
| T-STP-013 | Dashboard pending homework count matches unsubmitted published homework |
| T-STP-014 | Attendance page groups records by month in "March 2026" format |
| T-STP-015 | Complaint created with `created_by = auth()->id()` + `complainant_user_id = auth()->id()` |
| T-STP-016 | Complaint listing shows only own complaints |
| T-STP-017 | Payment page shows only active gateways |
| T-STP-018 | `mark-all-read` marks only authenticated user's notifications |

---

### Phase P2 — Completeness
**Effort:** 7 person-days | **Deploy:** Sprint 2

**FRs addressed:** FR-STP-10 (results marks), FR-STP-12 (homework submission), FR-STP-24 (calendar), FR-STP-25 (leave), FR-STP-29 (account settings), FR-STP-30 (quiz/quest)

**Files to change / create:**

| Action | File | Change |
|---|---|---|
| MODIFY | `StudentPortalController@results()` | Integrate `ExamResult` model (from LmsExam) to display `obtained_marks`, `percentage`, `grade` alongside exam allocations |
| MODIFY | `StudentPortalController@noticeBoard()` | Change data source from `auth()->user()->notifications()` → filter to announcement-type notifications (Option A) — see Section 4.2 |
| ADD METHOD | `StudentPortalController@submitHomework()` | `POST /student-portal/homework/{homework}/submit` → `HomeworkSubmission::create([student_id, homework_id, file_path, submitted_at])` |
| ADD ROUTE | `routes/tenant.php` | `POST /student-portal/homework/{homework}/submit` |
| ADD METHOD | `StudentLmsController@quiz()` | `GET /student-portal/quiz` → loads `QuizAllocation` for student's class+section+student; passes to `quiz/index` view |
| ADD METHOD | `StudentLmsController@quest()` | `GET /student-portal/quest` → loads `QuestAllocation`; passes to `quest/index` view |
| ADD ROUTES | `routes/tenant.php` | `GET /quiz`, `GET /quest` |
| ADD METHOD | `StudentPortalController@applyLeave()` (form) | Build leave application form view — **requires migration first** |
| ADD METHOD | `StudentPortalController@storeLeave()` | `POST /apply-leave` → validate with `LeaveApplicationRequest` → `StdLeaveApplication::create()` |
| CREATE | `database/migrations/tenant/` | `create_std_leave_applications_table` — `student_id`, `leave_type`, `start_date`, `end_date`, `reason`, `attachment_path`, `status ENUM('Pending','Approved','Rejected')`, `approved_by`, standard columns |
| CREATE | `LeaveApplicationRequest.php` | Full class (see `STP_Security_Arch.md`) |
| ADD ROUTES | `routes/tenant.php` | `POST /apply-leave` |
| MODIFY | `StudentPortalController@account()` | Wire password change tab → `PasswordChangeRequest` + `Hash::make()` |
| MODIFY | `StudentPortalController@account()` | Wire notification preferences tab → store in `sys_user_preferences` or JSON column |
| CREATE | `PasswordChangeRequest.php` | Full class |
| CREATE | `account/_change-password.blade.php` | Password change form partial |
| MODIFY | `StudentPortalController@progressCard()` | Add PDF download link per report → `GET /progress-card/{report}/download` (links to HPC module's PDF generation route) |
| ADD METHOD | `StudentPortalController@downloadProgressCard()` | `GET /progress-card/{report}/download` → redirect to HPC module's PDF endpoint; verify report belongs to student first |
| ADD METHOD | `StudentPortalController@downloadIdCard()` | `GET /student-id-card/download` → DomPDF minimal ID card template |
| CREATE | `id-card/download.blade.php` | Minimal DomPDF template: student name, class, section, roll no, photo, school name |
| MODIFY | `StudentPortalController@schoolCalendar()` | Wire to school academic calendar — query `sch_academic_sessions` events or `sys_notifications` of type CALENDAR |

**Leave migration columns:**
```sql
CREATE TABLE `std_leave_applications` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `leave_type` VARCHAR(50) NOT NULL,
    `start_date` DATE NOT NULL,
    `end_date` DATE NOT NULL,
    `reason` TEXT NOT NULL,
    `attachment_path` VARCHAR(255) NULL,
    `status` ENUM('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
    `approved_by` INT UNSIGNED NULL,
    `approval_note` TEXT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_leave_student` (`student_id`),
    INDEX `idx_leave_status` (`status`),
    CONSTRAINT `fk_leave_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_leave_approver` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Tests for P2:**

| Test ID | Scenario |
|---|---|
| T-STP-020 | Syllabus progress shows correct completed/in_progress/upcoming per topic |
| T-STP-021 | My teachers page builds unique teacher list with no duplicates |
| T-STP-022 | Library my-books shows empty state for student with no membership |
| T-STP-023 | Transport page shows empty state for student with no allocation |
| T-STP-024 | Progress card shows only Published reports |
| T-STP-025 | `EnsureTenantHasModule` blocks portal when module is disabled for tenant |

---

### Phase P3 — REST API + Enhancements
**Effort:** 4 person-days | **Deploy:** Sprint 3+

**FRs addressed:** API for mobile/PWA (req Section 6.2), Parent dashboard separation, push notifications

**Files to create / change:**

| Action | File | Change |
|---|---|---|
| POPULATE | `Modules/StudentPortal/routes/api.php` | Add all 9 API routes with `auth:sanctum` + `role:Student\|Parent` middleware |
| CREATE | `Modules/StudentPortal/app/Http/Controllers/StudentPortalApiController.php` | 9 methods: `profile`, `invoices`, `pay`, `timetable`, `attendance`, `notifications`, `markRead`, `homework`, `exams` — all return JSON `{ success: true, data: {...} }` |
| MODIFY | `StudentPortalApiController@pay` | Reuse `ProcessPaymentRequest` (same ownership guard) |
| MODIFY | All API methods | Add IDOR guards: each method must scope to `auth()->user()->student->id` |
| CREATE | `StudentPortalApiController@parentDashboard()` | Lists linked children from `std_student_guardian_jnt` where `can_access_parent_portal = 1`; allows switching between children |
| ADD | Push notification setup | FCM service provider integration for Firebase Cloud Messaging |
| ADD | `hostel()` | Wire when HST module is complete |
| MODIFY | `online-exam/index.blade.php` | Wire to LmsExam online exam player |

**API IDOR test pattern:**
```php
it('student A cannot access student B data via API', function () {
    $studentA = User::factory()->withStudentRole()->withStudentRecord()->create();
    $studentB = User::factory()->withStudentRole()->withStudentRecord()->create();
    $invoice  = FeeInvoice::factory()->forStudentAssignment($studentB->student)->create();

    $this->actingAs($studentA, 'sanctum')
         ->getJson("/api/v1/portal/invoices?id={$invoice->id}")
         ->assertStatus(403);
});
```

---

## 7. Seeder / Test Data Requirements

STP has **no owned tables** — no seeders required.

### Test Data per Phase

**Phase P0 tests require:**
```
- 2 student users: StudentA + StudentB with distinct std_students records
- fee_student_assignments: one for StudentA, one for StudentB
- fee_invoices: one belonging to StudentA's assignment (NOT StudentB's)
- pay_payment_gateways: 1 active + 1 inactive record
- sys_users: 1 admin user (non-Student role) for T-STP-003
```

**Phase P1 tests require:**
```
- cmp_complaint_categories: 2 parent categories + 2 children
- sys_dropdowns: record with key='COMPLAINANT_STUDENT'
- sys_dropdowns: record with key='complainant_type' (for prepareForValidation)
- sys_notifications: 5 notifications for StudentA, 5 for StudentB
- tt_timetable_cells: cells for StudentA's class+section (ACTIVE status)
- tt_school_days: at least 5 school days with ordinals
- hmw_homeworks: 3 published homeworks for StudentA's class+section
- exm_exam_allocations: 3 published exams for StudentA's class+section
```

**Phase P2 tests require:**
```
- exm_exam_allocations: with associated ExamResult records (marks, grade)
- hmw_homeworks: published homeworks for StudentA (for submission test)
- slb_syllabus_schedules: records spanning past/today/future dates
- lib_members: StudentA has membership, StudentB does not (for empty-state test)
- lib_transactions: 2 active borrowed books for StudentA
- tpt_student_allocation_jnt: StudentA has allocation, StudentC does not
- hpc_reports: 1 Published + 1 Draft for StudentA (only Published shown)
```

**Leave table prerequisite:**
```
- std_leave_applications table must exist (Phase P2 migration) before P2 leave tests run
- Migration: php artisan tenants:migrate (after adding migration file to tenant/ folder)
```

---

## 8. Testing Strategy

### Framework
- **Feature tests:** Pest + `RefreshDatabase` + `Tests\TestCase`
- **Unit tests:** Pest (pure PHP, no Laravel app boot for service method logic)

### Factory Setup (create these before writing any test)

```php
// Student user factory — add to User factory or create StudentUser factory
User::factory()->withStudentRole()->withStudentRecord()
// Creates: sys_users record + Spatie role 'Student' + linked std_students record

// Parent user factory
User::factory()->withParentRole()->withGuardianRecord($student, canAccessPortal: true)
// Creates: sys_users + Spatie role 'Parent' + std_student_guardian_jnt (can_access_parent_portal=1)

// Admin user factory (must be blocked from portal)
User::factory()->withAdminRole()
// Creates: sys_users + Spatie role 'Admin' (no Student/Parent role)

// PaymentService mock — bind in test AppServiceProvider or per-test
app()->bind(PaymentService::class, fn() => new MockPaymentService());
```

### P0 Security Test Patterns

```php
// T-STP-001 — IDOR viewInvoice
it('student A cannot view student B invoice', function () {
    $studentA = User::factory()->withStudentRole()->withStudentRecord()->create();
    $studentB = User::factory()->withStudentRole()->withStudentRecord()->create();
    $assignmentB = FeeStudentAssignment::factory()->for($studentB->student)->create();
    $invoiceB = FeeInvoice::factory()->for($assignmentB, 'feeStudentAssignment')->create();

    $this->actingAs($studentA)
         ->get(route('student-portal.view-invoice', $invoiceB->id))
         ->assertNotFound();  // 404
});

// T-STP-002 — IDOR proceedPayment
it('student A cannot pay student B invoice', function () {
    $studentA = User::factory()->withStudentRole()->withStudentRecord()->create();
    $studentB = User::factory()->withStudentRole()->withStudentRecord()->create();
    $assignmentB = FeeStudentAssignment::factory()->for($studentB->student)->create();
    $invoiceB = FeeInvoice::factory()
        ->for($assignmentB, 'feeStudentAssignment')
        ->create(['status' => 'Published', 'balance_amount' => 5000]);

    $this->actingAs($studentA)
         ->post(route('student-portal.proceed-payment'), [
             'payable_id'   => $invoiceB->id,
             'payable_type' => 'fee_invoice',
             'amount'       => 1000,
             'gateway'      => 'razorpay',
         ])
         ->assertForbidden();  // 403 from ProcessPaymentRequest::authorize()
});

// T-STP-003 — Admin blocked from portal
it('admin user cannot access student portal', function () {
    $admin = User::factory()->withAdminRole()->create();

    $this->actingAs($admin)
         ->get(route('student-portal.dashboard'))
         ->assertForbidden();  // 403 from role:Student|Parent middleware
});

// T-STP-004 — Unauthenticated redirect
it('unauthenticated user is redirected to login', function () {
    $this->get(route('student-portal.dashboard'))
         ->assertRedirect(route('login'));
});

// T-STP-005 — Notification IDOR
it('student cannot mark another user notification as read', function () {
    $studentA = User::factory()->withStudentRole()->withStudentRecord()->create();
    $studentB = User::factory()->withStudentRole()->withStudentRecord()->create();

    // Create notification for studentB
    $notificationId = $studentB->notifications()->create([...])->id;

    $this->actingAs($studentA)
         ->post(route('student-portal.notifications.mark-read', $notificationId))
         ->assertNotFound();  // 404 — auth()->user()->notifications()->findOrFail() scopes correctly
});
```

### Minimum Coverage Gates

| Gate | Requirement |
|---|---|
| P0 gate | All 5 T-STP-001 to T-STP-005 PASS before P1 work begins |
| IDOR gate | Student A cannot view/pay Student B's invoice under ANY parameter manipulation |
| Module gate | `EnsureTenantHasModule:StudentPortal` returns 403/redirect when module disabled |
| Auth gate | All portal routes redirect unauthenticated users to login |
| Role gate | Admin/Teacher/Staff (non-Student) receive 403 on all portal routes |
| Guardian gate | Parent with `can_access_parent_portal=0` cannot access child's data |
| Rate limit gate | Payment initiation is throttled (mock throttle middleware in test env) |

---

## Appendix A — All 25 Suggestions (S-STP-01 to S-STP-25) Phase Assignment

| Suggestion | Description | Phase | Status |
|---|---|---|---|
| S-STP-01 | Fix IDOR `proceedPayment()` — `payable_id` ownership | P0 | ❌ Fix 1 in Security Arch |
| S-STP-02 | Verify + fix `viewInvoice`/`payDueAmount` ownership guard | P0 | ❌ Fix 2 in Security Arch |
| S-STP-03 | Add `EnsureTenantHasModule:StudentPortal` to route group | P0 | ❌ Fix 4 in Security Arch |
| S-STP-04 | Remove `test-notification` route | P0 | ❌ Fix 7 in Security Arch |
| S-STP-05 | Create `StoreComplaintRequest` + `ProcessPaymentRequest` | P0/P1 | ❌ Part 2 of Security Arch |
| S-STP-06 | Replace hard-coded ID `104` with key-based lookup | P1 | ❌ Handled in StoreComplaintRequest |
| S-STP-07 | Fix `PaymentGateway::all()` → `::active()->get()` | P1 | ❌ Fix 5 in Security Arch |
| S-STP-08 | Fix typo `currentFeeAssignemnt` → `currentFeeAssignment` | P1 | ❌ Fix 6 in Security Arch |
| S-STP-09 | Paginate complaint index (add `->paginate(15)`) | P1 | ❌ Section 1.3 |
| S-STP-10 | Change `notifications/mark-read` from GET to POST/PATCH | P1 | ❌ Fix 8 in Security Arch |
| S-STP-11 | Remove scaffold stub methods from `StudentPortalController` | P1 | ❌ Section 1.2 |
| S-STP-12 | Extract `StudentPortalService` class | P1 | ❌ Part 3 of Security Arch |
| S-STP-13 | Implement leave application workflow | P2 | ❌ Section 6 Phase P2 |
| S-STP-14 | Implement school calendar (FullCalendar.js) | P2 | ❌ Section 6 Phase P2 |
| S-STP-15 | Implement account settings backend (3 tabs) | P2 | ❌ Section 6 Phase P2 |
| S-STP-16 | Implement homework submission from portal | P2 | ❌ Section 6 Phase P2 |
| S-STP-17 | Implement results with actual marks | P2 | ❌ Section 6 Phase P2 |
| S-STP-18 | Wire quiz/quest player screens | P2 | ❌ Section 6 Phase P2 |
| S-STP-19 | Fix notice board data source | P2 | ❌ Section 4.2 |
| S-STP-20 | Add PDF download for progress card + ID card | P2 | ❌ Section 6 Phase P2 |
| S-STP-21 | REST API for mobile/PWA (9 endpoints) | P3 | ❌ Section 5.2 |
| S-STP-22 | Parent dashboard separation (child-switcher) | P3 | ❌ Section 6 Phase P3 |
| S-STP-23 | Hostel integration (when HST module complete) | P3 | ❌ Section 6 Phase P3 |
| S-STP-24 | Push notifications / FCM | P3 | ❌ Section 6 Phase P3 |
| S-STP-25 | Add `Gate::authorize()` across all controllers | P0 | ❌ Via `StudentPortalPolicy` |

---

## Appendix B — artisan Commands for File Creation

```bash
# FormRequests
php artisan module:make-request ProcessPaymentRequest StudentPortal
php artisan module:make-request StoreComplaintRequest StudentPortal
php artisan module:make-request LeaveApplicationRequest StudentPortal
php artisan module:make-request PasswordChangeRequest StudentPortal

# Policy
php artisan module:make-policy StudentPortalPolicy StudentPortal

# Service (manual — no artisan command for services in nwidart)
# Create: Modules/StudentPortal/app/Services/StudentPortalService.php

# Missing controllers
php artisan module:make-controller StudentLmsController StudentPortal
php artisan module:make-controller StudentProgressController StudentPortal
php artisan module:make-controller StudentTeachersController StudentPortal
php artisan module:make-controller StudentTimetableController StudentPortal

# Leave application migration (tenant)
php artisan module:make-migration create_std_leave_applications_table StudentPortal
# Then move file to: database/migrations/tenant/

# Run on all tenants after migration file is created
php artisan tenants:migrate
```
