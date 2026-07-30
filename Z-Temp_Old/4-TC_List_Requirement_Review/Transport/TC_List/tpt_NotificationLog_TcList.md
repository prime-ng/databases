# tpt_NotificationLog_TcList

## Module: Transport → Trip Management → Notification Log

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Trip Management |
| Feature | Notification Log |
| URL(s) | `/transport/trip-management?tab=notification_log` (index via tab) |
| Tab Controller | `Modules\Transport\Http\Controllers\TripMgmtController@index()` — tab: `notification_log` |
| Query Method | `TripMgmtController@notificationLogQuery()` (line 487) |
| Model | `Modules\Transport\Models\TptNotificationLog` — table: `tpt_notification_log` |
| Dedicated Controller | None — no CRUD controller exists for NotificationLog |
| Permissions | **MISMATCH** — Controller checks `tenant.transport.viewAny` (TripMgmtController@index line 38), blade tab uses `tenant.notification-log.viewAny` (tripmanagement.blade.php line 23). `permissionslist.php` defines `notification-log` with only `viewAny`, `view`. A user with only `tenant.notification-log.viewAny` but not `tenant.transport.viewAny` gets 403 at controller level before blade renders. |
| Soft Deletes | No — model does NOT use SoftDeletes (though migration has `$table->softDeletes()`) |
| Notification Creation | Created via TripController@stopAction() (start_trip→TripStart, reach→ReachedStop/Delayed, leave→ApproachingStop) and TripController@update() (Cancelled) |
| Report Integration | TransportReportController@buildNotificationsSection (line 237) — completely standalone synthetic report using incidents + boarding logs + trip statuses — does NOT query TptNotificationLog |
| Blade View | `notification-log/index.blade.php` — tab partial (82 lines) |
| Route Definition | No dedicated routes — index only via `Route::resource('transport.trip-management', TripMgmtController::class)` |
| Paginator Name | `page` (default) — reuses same paginator as all other tabs, causing cross-tab pagination conflict |
| Query Ordering | `latest()` — orders by `created_at` DESC |
| Timezone | No explicit timezone handling — uses `Carbon::now()` which defaults to app timezone |
| Data Retention | No archival/purge mechanism — table grows indefinitely with every trip action |

---

## 2. Pre-conditions

- Dedicated permission `tenant.notification-log.viewAny` exists in `permissionslist.php` and blade, but controller only checks `tenant.transport.viewAny` — permission mismatch
- Notifications are auto-created during trip stop actions and trip cancellation
- Read-only view — no create/edit/delete operations in UI
- `student_session_id` FK is defined in migration but NEVER populated by any controller
- Model has NO Eloquent relationships defined — `with(['trip','boardingStop'])` in `notificationLogQuery()` will throw `BadMethodCallException`
- TransportReportController has a parallel `notifications` tab that builds synthetic notification data from incidents, boarding events, and trip statuses — it does NOT use TptNotificationLog table at all
- No `activityLog()` is called for any notification creation event — zero audit trail for notification generation
- All notification status fields except `app_notification_status` remain NULL permanently — no multi-channel delivery implemented
- Paginator name `page` is shared across all tabs in TripMgmtController — switching pages on one tab can affect another tab's pagination

---

## 3. Default Data Load

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Notification Log | `TripMgmtController@notificationLogQuery()` | `TptNotificationLog::with(['trip','boardingStop'])->latest()` | tab=notification_log: `notification_type` | 10/page |

---

## 4. Test Data Strategy

- Notifications are created as side-effects of stop actions in TripController:
  - `start_trip` → notification_type='TripStart'
  - `reach` (on time) → 'ReachedStop'
  - `reach` (delayed >5min) → 'Delayed'
  - `leave` → 'ApproachingStop'
  - `end_trip` → no notification
  - `emergency` → no notification
  - `Cancelled` status update → 'Cancelled'
- All notifications currently hardcode `app_notification_status = 'Sent'`
- sms/email/whatsapp status are never set (remain NULL = NotRegistered)
- `student_session_id` is NEVER set in any notification creation call — FK remains NULL always
- Model has empty $fillable array — no mass assignment protection issues since notifications are created with explicit column assignments
- No `activityLog()` call is made when notifications are created — no audit trail for notification generation
- Notification filter uses button-group styled links (not dropdown), rendered in blade at `notification-log/index.blade.php:15-20`
- **CRITICAL CRASH**: `notificationLogQuery()` calls `with(['trip', 'boardingStop'])` but model has NO relationships — tab crashes on load with `BadMethodCallException`
- **TransportReportController notifications report** generates synthetic data — must verify independently using trip incidents + boarding logs
- **No factory exists** — `HasFactory` trait present but `newFactory()` is commented out; no `TptNotificationLogFactory` class exists

---

## 5. Business Conditions

### 5.1 Database Schema — `tpt_notification_log`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | student_session_id | INT UNSIGNED | DEFAULT NULL, FK → std_student_academic_sessions.id, ON DELETE SET NULL |
| BC-DB-03 | trip_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_trip.id, ON DELETE SET NULL |
| BC-DB-04 | boarding_stop_id | INT UNSIGNED | DEFAULT NULL, FK → tpt_pickup_points.id, ON DELETE SET NULL |
| BC-DB-05 | notification_type | ENUM('TripStart','ApproachingStop','ReachedStop','Delayed','Cancelled') | DEFAULT NULL |
| BC-DB-06 | sent_time | DATETIME | DEFAULT NULL |
| BC-DB-07 | app_notification_status | ENUM('NotRegistered','Sent','Failed') | DEFAULT NULL |
| BC-DB-08 | sms_notification_status | ENUM('NotRegistered','Sent','Failed') | DEFAULT NULL |
| BC-DB-09 | email_notification_status | ENUM('NotRegistered','Sent','Failed') | DEFAULT NULL |
| BC-DB-10 | whatsapp_notification_status | ENUM('NotRegistered','Sent','Failed') | DEFAULT NULL |
| BC-DB-11 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-12 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-13 | deleted_at | TIMESTAMP | NULL (no SoftDeletes in model) |

### 5.2 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | start_trip action | Notification created: type='TripStart', sent_time=now, app_status='Sent' |
| BC-BIZ-02 | reach action (on time) | Notification created: type='ReachedStop', sent_time=now, app_status='Sent' |
| BC-BIZ-03 | reach action (delayed >5min after sch_arrival) | Notification created: type='Delayed', sent_time=now, app_status='Sent' |
| BC-BIZ-04 | leave action | Notification created: type='ApproachingStop', sent_time=now, app_status='Sent' |
| BC-BIZ-05 | Cancelled status update | Notification created: type='Cancelled', sent_time=now, app_status='Sent' |
| BC-BIZ-06 | SMS/Email/WhatsApp are never set | All remain NULL (NotRegistered) — no SMS/email/WhatsApp sending implemented |
| BC-BIZ-07 | Notification creation lacks `activityLog()` | TripController@stopAction creates TptNotificationLog (lines 210, 231, 246) without calling `activityLog()`. Same for TripController@update (line 370). No audit trail for notification creation. |
| BC-BIZ-08 | `student_session_id` never populated | Migration defines FK to `std_student_academic_sessions`, but none of the `TptNotificationLog::create()` calls set `student_session_id` |
| BC-BIZ-09 | end_trip / emergency actions produce zero notifications | Both cases in stopAction switch have NO TptNotificationLog::create() call |
| BC-BIZ-10 | Delay threshold hardcoded at 5 minutes | `$now->gt(Carbon::parse($stop->sch_arrival_time)->addMinutes(5))` — not configurable |
| BC-BIZ-11 | Multiple stop actions on same trip create independent records | Each create() inserts a new row — no update or dedup logic |
| BC-BIZ-12 | Notification types match DB ENUM exactly | ENUM values: TripStart, ApproachingStop, ReachedStop, Delayed, Cancelled — all 5 are used |

### 5.3 Model — `TptNotificationLog`

| BC ID | Property | Value |
|-------|----------|-------|
| BC-MOD-01 | Table | `tpt_notification_log` |
| BC-MOD-02 | Fillable | `[]` (empty array — no mass assignment) |
| BC-MOD-03 | SoftDeletes | NOT used (no trait) — migration has `softDeletes()` but model has no trait |
| BC-MOD-04 | HasFactory | Trait `use HasFactory` present, but `newFactory()` method is commented out — no actual factory class exists |
| BC-MOD-05 | Relationships | **NONE** — no `trip()`, `boardingStop()`, or `studentSession()` methods defined |
| BC-MOD-06 | Extends | `App\Models\BaseModel` (extends `Illuminate\Database\Eloquent\Model`) |
| BC-MOD-07 | Hidden | None |
| BC-MOD-08 | Appends | None |
| BC-MOD-09 | Casts | None (timestamps default to Carbon via BaseModel) |
| BC-MOD-10 | Observers | None registered |

**Critical Note:** The model has NO relationships defined despite the DDL having FKs to student_session, trip, and boarding_stop. The query `TptNotificationLog::with(['trip', 'boardingStop'])` in `notificationLogQuery()` will throw `BadMethodCallException` because Eloquent cannot resolve the relationship name.

### 5.4 BC-BIZ-DEEP — Deep Business Condition Analysis

#### 5.4.1 Notification State Machine

Each created notification follows this implicit state:

```
[Action Triggered] → [Record Created] → [App Status = 'Sent'] → [App UI shows 'Sent']
                                                ↓
                                   [SMS/Email/WhatsApp = NULL]
                                   (No channel sending implemented)
```

**Terminal states:**
- `app_notification_status`: NULL → 'Sent' (set during create). NO transition to 'Failed' or 'NotRegistered' ever occurs.
- Other channels: NULL (eternal). NEVER set to any value.
- No retry mechanism, no fallback, no delivery confirmation.

#### 5.4.2 Trip Stop Action → Notification Data Flow

```
TripController@stopAction()
│
├─ action='start_trip' (line 189)
│   ├─ Update TptTripStopDetail (reached_flag=1, reaching_time=now, leaving_time=now)
│   ├─ Update TptTrip (start_time, start_odometer, status='Ongoing')
│   └─ TptNotificationLog::create([
│       trip_id, boarding_stop_id, notification_type='TripStart',
│       sent_time=now, app_notification_status='Sent'
│   ]) ← NO student_session_id, NO sms/email/whatsapp
│
├─ action='reach' (line 219)
│   ├─ Update TptTripStopDetail (reached_flag=1, reaching_time=now)
│   ├─ Compute notification_type: ReachedStop or Delayed
│   │   └─ Condition: $now > sch_arrival_time + 5min → 'Delayed'
│   └─ TptNotificationLog::create([
│       trip_id, boarding_stop_id, notification_type=$type,
│       sent_time=now, app_notification_status='Sent'
│   ])
│
├─ action='leave' (line 240)
│   ├─ Update TptTripStopDetail (leaving_time=now)
│   └─ TptNotificationLog::create([
│       trip_id, boarding_stop_id, notification_type='ApproachingStop',
│       sent_time=now, app_notification_status='Sent'
│   ])
│
├─ action='end_trip' (line 255)
│   ├─ Update TptTripStopDetail (reached_flag=1, reaching_time=now, leaving_time=now)
│   ├─ Update TptTrip (end_time, end_odometer, status='Completed')
│   └─ ⛔ NO notification created
│
├─ action='emergency' (line 277)
│   ├─ Update TptTripStopDetail (emergency_flag=1, emergency_time=now, emergency_remarks)
│   ├─ TptTripIncidents::create([...])
│   └─ ⛔ NO notification created
│
└─ END

TripController@update() with status='Cancelled' (line 369)
├─ Update TptTrip (status='Cancelled')
├─ activityLog($trip, 'Updated', [...]) ← logs trip update, NOT notification
└─ TptNotificationLog::create([
    trip_id, notification_type='Cancelled',
    sent_time=now, app_notification_status='Sent'
    ← NO boarding_stop_id (null — makes sense for cancellation)
    ← NO student_session_id
  ])
```

#### 5.4.3 Channel Delivery Status Matrix

| Channel | Column | Value Set By | Actual Value | Real Delivery |
|---------|--------|-------------|-------------|---------------|
| App | `app_notification_status` | TripController | 'Sent' (hardcoded) | ❌ No actual push/notification sent |
| SMS | `sms_notification_status` | Never set | NULL (displays as '-') | ❌ No SMS gateway called |
| Email | `email_notification_status` | Never set | NULL (displays as '-') | ❌ No email sent |
| WhatsApp | `whatsapp_notification_status` | Never set | NULL (displays as '-') | ❌ No WhatsApp API called |

**Impact:** Every notification log record displays 'Sent' for App and '-' for all other channels regardless of actual delivery. The `app_notification_status` value is misleading — it indicates "we decided to send" not "we successfully delivered."

#### 5.4.4 Timing Analysis

- `sent_time` is populated with `Carbon::now()` at the moment of TripController action
- This represents server-side timestamp, not device/push delivery timestamp
- No correlation with actual notification delivery since no delivery mechanism exists
- Format used in blade: `date('d M Y h:i A', strtotime($item->sent_time))` — converts to readable string
- Timezone: Application default timezone (configurable via `config/app.php` timezone)
- TripController's `$now = Carbon::now()` captures microseconds-precision but stored as DATETIME (seconds precision)

#### 5.4.5 `student_session_id` — Complete Gap Trace

1. **Migration DDL:** `$table->foreignId('student_session_id')->nullable()->constrained('std_student_academic_sessions')->onDelete('set null');`
2. **FK Target:** `std_student_academic_sessions.id` — identifies a specific student's enrollment in an academic session
3. **Controller Gap:** All 4 `TptNotificationLog::create()` calls at TripController lines 210, 231, 246, 370 do NOT pass `student_session_id`
4. **Why it matters:** Without `student_session_id`, the notification cannot be linked to a specific student. The FK exists for future per-student notification delivery but is never populated.
5. **Data available at creation site:** At `stopAction()`, the trip context includes `trip_id` which could be used to join to `TptStudentAllocationJnt` → `student_session_id`. But this join is never performed.
6. **Blade display:** The `notification-log/index.blade.php` does not attempt to display student info (columns are: #, Type, Trip, Stop, Sent Time, App, SMS, Email, WhatsApp).

#### 5.4.6 ORM Relationship Crash Analysis

**The Bug:**
```php
// TripMgmtController@notificationLogQuery() line 489
$query = TptNotificationLog::with(['trip', 'boardingStop']);
```

**Why It Crashes:**
```php
// TptNotificationLog model (complete — only 24 lines)
class TptNotificationLog extends BaseModel
{
    use HasFactory;
    protected $table = 'tpt_notification_log';
    protected $fillable = [];
    // NO relationship methods defined
}
```

Eloquent's `with()` eager-loading resolves relationship names to methods on the model:
- `'trip'` → looks for `$model->trip()` method → NOT FOUND → `BadMethodCallException`
- `'boardingStop'` → looks for `$model->boardingStop()` → NOT FOUND → same exception

**Blade mitigation:** `notification-log/index.blade.php` uses null-safe operators `$item->trip?->id` and `$item->boardingStop?->name`. But these never execute because the query crashes before the view is rendered.

**Severity: CRITICAL** — The notification log tab is entirely broken. No user can view notification logs through the UI.

#### 5.4.7 Blade View Permission Analysis

**TripManagement blade (`tripmanagement.blade.php`):**
- Line 23: `'permission' => 'tenant.notification-log.viewAny'` — tab nav-tab entry
- Line 49-51: `@can('tenant.notification-log.viewAny') @include('transport::notification-log.index') @endcan`

**Controller gate:**
- Line 38: `Gate::authorize('tenant.transport.viewAny');` — this is a blanket gate that blocks ALL tabs if user lacks `transport.viewAny`

**Mismatch scenario:**
- User has `tenant.notification-log.viewAny` + `tenant.notification-log.view`
- User does NOT have `tenant.transport.viewAny`
- Expected: User should see Notification Log tab
- Actual: User gets **403 Forbidden** from `TripMgmtController@index` before blade renders

**Double security at blade level:**
- Tab nav button hidden via `permission` key in nav-tab component — functional ✅
- `@can` wrapper around `@include` — functional ✅
- Both use correct permission key `tenant.notification-log.viewAny` ✅
- But controller gate uses WRONG key `tenant.transport.viewAny` ❌

#### 5.4.8 TransportReportController Notifications — Parallel Implementation

`TransportReportController@buildNotificationsSection` (line 237) builds a completely separate notifications report:

**Data Sources (not from TptNotificationLog):**
1. **Trip Incidents** (TptTripIncidents) — mapped as 'IncidentAlert' type
2. **Boarding Events** (StudentBoardingLog) — mapped as 'BoardUnboard' type
3. **Trip Status Changes** (TptTrip) — mapped as 'TripStart' and 'TripCompletion' types

**Synthetic fields generated:**
- `notification_type` — mapped from source (IncidentAlert, BoardUnboard, TripStart, TripCompletion)
- `notification_category` — hardcoded ('Safety Alert', 'Boarding Alert', 'Unboarding Alert', 'Trip Status')
- `student_name` — derived from relations or 'All Students'
- `route_name` — from trip → routeScheduler → route relation
- `sent_time` — from incident_time / boarding_time / start_time / end_time
- `severity` — from incident severity or hardcoded 'LOW'
- `source` — from source table name ('Trip Incident', 'Boarding Log', 'Trip Log')

**Overlap with TptNotificationLog:**
- `TripStart` type exists in BOTH — real TptNotificationLog AND synthetic report
- `Delayed`, `ApproachingStop`, `ReachedStop`, `Cancelled` — only in TptNotificationLog
- `IncidentAlert`, `BoardUnboard`, `TripCompletion` — only in synthetic report
- No code shares or deduplicates between the two systems

**Filter options via `getFilterData()`:**
- `notificationTypes` in TransportReportController includes extra types: 'IncidentAlert', 'SafetyAlert' — these DO NOT exist in the DB ENUM

#### 5.4.9 Pagination Conflict Analysis

`TripMgmtController@index()` calls 8 separate `paginate(10)->withQueryString()` calls:
1. `StopDetailsNew` (line 84) — default page name
2. `TripData` (line 85) — default page name
3. `bordUnBordData` (line 86) — default page name
4. `incidentData` (line 87) — default page name
5. `driverRouteVehicles` (line 88) — default page name
6. `sheduleData` (line 89) — default page name
7. `notificationLog` (line 90) — default page name

ALL seven use the default `page` paginator name. Only `StopDetailsNew` uses a different syntax but still defaults. When a user navigates to `?tab=notification_log&page=2`, ALL queries receive `page=2` — every tab's pagination shifts simultaneously.

**Impact:** If tab A has 15 records and tab B has 25, page 2 on tab A shows records 11-15 while page 2 on tab B shows records 11-20. Cross-tab pagination corruption is guaranteed.

### 5.5 CODE-TRACE — Code-Level Trace Analysis

#### 5.5.1 Trace: TripStart Notification Creation

**Trigger:** POST `/trip/stop-action` with `{action: "start_trip", id: "new_<jntId>"}` or `{action: "start_trip", id: <existing stopDetail id>}`

**Code Flow:**
```
TripController@stopAction()                                  [tripController.php:123]
│
├─ Gate::authorize('tenant.stop-details.update')             [line 125]
│   └─ Permission key: 'tenant.stop-details.update'
│
├─ ID Parsing: str_starts_with($request->id, 'new_')         [line 127]
│   ├─ TRUE: Parse jntId, find PickupPointRoute, find/create TptTripStopDetail
│   │   └─ PickupPointRoute::find($jntId)                   [line 135]
│   │   └─ TptTrip::whereDate('trip_date', $date)->first()  [line 141-148]
│   │   └─ TptTripStopDetail::updateOrCreate(...)           [line 157-171]
│   └─ FALSE: TptTripStopDetail::find($request->id)          [line 176]
│
├─ switch($request->action)                                  [line 187]
│   └─ case 'start_trip':                                    [line 189]
│       ├─ $stop->update([reached_flag=1, reaching_time=$now, leaving_time=$now])
│       ├─ $trip->update([start_time, start_odometer, status='Ongoing'])
│       └─ TptNotificationLog::create([                      [line 210-216]
│           'trip_id'             => $trip->id,              ✓ populated
│           'boarding_stop_id'    => $stop->stop_id,         ✓ populated
│           'notification_type'   => 'TripStart',            ✓ hardcoded
│           'sent_time'           => $now,                   ✓ Carbon::now()
│           'app_notification_status' => 'Sent',             ✓ hardcoded
│           ⛔ No activityLog() called                       ← GAP
│           ⛔ 'student_session_id' not set                   ← GAP
│           ⛔ sms/email/whatsapp status not set               ← GAP
│       ])
│
├─ response()->json([status: true])                          [line 300-304]
└─ END
```

**Variables set at create time:**
- `trip_id` = `$trip->id` (from TptTrip record)
- `boarding_stop_id` = `$stop->stop_id` (= `$jnt->pickup_point_id`)  
- `notification_type` = `'TripStart'` (literal string)
- `sent_time` = `$now` (= `Carbon::now()`)
- `app_notification_status` = `'Sent'` (literal string)
- All other columns = NULL (database defaults)

**Columns NOT set (remain NULL):**
- `student_session_id` — available at scope via `$trip` → `TptStudentAllocationJnt.where('pickup_route_id', $trip->route_id)`, but never queried
- `sms_notification_status` — no SMS logic exists
- `email_notification_status` — no email logic exists
- `whatsapp_notification_status` — no WhatsApp logic exists
- `created_at`/`updated_at` — handled by Eloquent timestamps (auto-set)
- `deleted_at` — never set (no SoftDeletes anyway)

#### 5.5.2 Trace: ReachedStop / Delayed Notification Creation

**Trigger:** POST `/trip/stop-action` with `{action: "reach", id: <stopDetailId>}`

**Code Flow:**
```
TripController@stopAction()                                  [tripController.php:123]
│
├─ Gate::authorize('tenant.stop-details.update')             [line 125]
│
├─ // Same ID resolution as Trace 5.5.1                      [lines 127-181]
│
├─ switch($request->action)                                  [line 187]
│   └─ case 'reach':                                         [line 219]
│       ├─ $stop->update([reached_flag=1, reaching_time=$now])
│       │
│       ├─ notification_type COMPUTATION:                    [line 226-229]
│       │   $notificationType = 'ReachedStop';               ← default
│       │   if ($stop->sch_arrival_time                       ← guard: must exist
│       │       && $now->gt(                                  ← guard: must be past
│       │           Carbon::parse($stop->sch_arrival_time)
│       │               ->addMinutes(5)                       ← hardcoded threshold
│       │       )) {
│       │       $notificationType = 'Delayed';               ← delayed
│       │   }
│       │
│       └─ TptNotificationLog::create([                      [line 231-237]
│           'trip_id'             => $trip->id,
│           'boarding_stop_id'    => $stop->stop_id,
│           'notification_type'   => $notificationType,      ← DYNAMIC: 'ReachedStop' | 'Delayed'
│           'sent_time'           => $now,
│           'app_notification_status' => 'Sent',
│           ⛔ No activityLog() called
│           ⛔ 'student_session_id' not set
│       ])
│
└─ END
```

**Delay Detection Logic Notes:**
- Requires `sch_arrival_time` to be populated on TptTripStopDetail — if NULL, notification_type is ALWAYS 'ReachedStop' (never 'Delayed')
- Threshold is exactly 5 minutes (`addMinutes(5)`) — `$now->gt(...)` uses strict greater-than, not greater-than-or-equal
- No configuration exists for this threshold — hardcoded magic number
- No logging when delay is detected — no audit trail of why 'Delayed' was chosen

#### 5.5.3 Trace: ApproachingStop Notification Creation

**Trigger:** POST `/trip/stop-action` with `{action: "leave", id: <stopDetailId>}`

**Code Flow:**
```
TripController@stopAction()                                  [tripController.php:123]
│
├─ Gate::authorize('tenant.stop-details.update')             [line 125]
├─ // Same ID resolution
├─ switch($request->action)                                  [line 187]
│   └─ case 'leave':                                         [line 240]
│       ├─ $stop->update([leaving_time=$now])
│       └─ TptNotificationLog::create([                      [line 246-252]
│           'trip_id'             => $trip->id,
│           'boarding_stop_id'    => $stop->stop_id,
│           'notification_type'   => 'ApproachingStop',
│           'sent_time'           => $now,
│           'app_notification_status' => 'Sent',
│           ⛔ No activityLog() called
│           ⛔ 'student_session_id' not set
│       ])
│
└─ END
```

**Note:** Even though this is a "leave" action (driver leaving the stop), the notification type is semantically misleading — 'ApproachingStop' suggests arriving at the next stop, not leaving the current one.

#### 5.5.4 Trace: Cancelled Notification Creation

**Trigger:** PUT `/trip/{id}` with `status: "Cancelled"`

**Code Flow:**
```
TripController@update(TripRequest $request, $id)             [tripController.php:343]
│
├─ Gate::authorize('tenant.trip.update')                     [line 345]
│   └─ Permission key: 'tenant.trip.update'
│
├─ DB::transaction(function() use (...)) {                   [line 350]
│   ├─ $trip->update([status => $request->status, ...])      [line 356-367]
│   │
│   ├─ if ($request->status === 'Cancelled') {               [line 369]
│   │   └─ TptNotificationLog::create([                      [line 370-375]
│   │       'trip_id'             => $trip->id,
│   │       'notification_type'   => 'Cancelled',
│   │       'sent_time'           => now(),
│   │       'app_notification_status' => 'Sent',
│   │       ⛔ No 'boarding_stop_id' (NULL — correct for cancellation) ✓
│   │       ⛔ No 'student_session_id'
│   │       ⛔ No activityLog() specifically for notification
│   │   ])
│   │
│   ├─ activityLog($trip, 'Updated', [                       [line 378-380]
│   │   ← Logs trip update, NOT notification creation
│   │   ← 'message' => 'Trip and stop details updated successfully.'
│   │   ← Inaccurate: stop details might not have been updated
│   │   ← NO mention of notification being created
│   └─ ])
│ })
│
├─ redirect()->route('transport.trip-management.index', ...)
└─ END
```

**Key observations:**
- The `activityLog()` call logs the TRIP update, not the notification creation
- `boarding_stop_id` is intentionally NULL — cancellation has no associated stop
- The cancellation notification is created inside the DB transaction — if transaction rolls back, notification is also rolled back (correct behavior)
- No `student_session_id` — cancellation is trip-level, not student-level

#### 5.5.5 Trace: Notification Log Tab Load

**Trigger:** GET `/transport/trip-management?tab=notification_log`

**Code Flow:**
```
TripMgmtController@index(Request $request)                   [tripMgmtController.php:36]
│
├─ Gate::authorize('tenant.transport.viewAny')               [line 38]
│   ← Uses WRONG permission key — should be 'tenant.notification-log.viewAny'
│
├─ $tripIds = TptTrip::where(...)->first()                   [lines 54-63]
│   ← Executes even if tab=notification_log — unnecessary query
│
├─ $request->merge(['trip_id' => ..., 'tripe_id' => ...])    [lines 66-71]
│   ← Unnecessary for notification_log tab
│
├─ // ALL 8 sub-queries execute regardless of active tab:    [lines 73-90]
│   $stopDetails                                         ← unnecessary
│   $StopDetailsNew ->paginate(10)                        ← unnecessary
│   $TripData ->paginate(10)                              ← unnecessary
│   $bordUnBordData ->paginate(10)                        ← unnecessary
│   $incidentData ->paginate(10)                          ← unnecessary
│   $driverRouteVehicles ->paginate(10)                   ← unnecessary
│   $sheduleData ->paginate(10)                           ← unnecessary
│   $notificationLog ->paginate(10)                       ← needed
│
├─ notificationLog = $this->notificationLogQuery($request)   [line 90]
│   └─ →paginate(10)->withQueryString()
│
├─ return view('transport::tab_module.tripmanagement',       [line 92]
│   compact(..., 'notificationLog'))
│
└─ ⚠ BLADE RENDERS:
    tripmanagement.blade.php                                  [tripmanagement.blade.php]
    │
    ├─ x-backend.tab.nav-tab(:tabs=[...])                    [lines 9-24]
    │   └─ 'permission' => 'tenant.notification-log.viewAny'  ← correct key (line 23)
    │
    ├─ @can('tenant.notification-log.viewAny')                [line 49]
    │   └─ @include('transport::notification-log.index')      [line 50]
    │
    └─ notification-log/index.blade.php                       [notification-log/index.blade.php]
        ├─ Hidden input: tab=notification_log                  [line 9]
        ├─ Button group filter for notification_type           [lines 10-22]
        ├─ FOREACH $notificationLog                            [line 39]
        │   ├─ $item->trip?->id        ← null-safe (won't crash, but won't work)
        │   ├─ $item->boardingStop?->name  ← null-safe
        │   └─ Channel status badges    ← all display '-' except App
        ├─ Empty state: colspan=9                               [line 71]
        └─ Pagination: ->appends(['tab' => 'notification_log']) [line 79]
```

**Performance Issues:**
1. ALL 8 sub-queries execute on every page load, even when only one tab is visible
2. Trip ID query executes first (lines 54-63), then ALL pagination queries follow
3. No lazy loading or deferred execution for inactive tabs
4. Shared paginator `page` name across all 7 sub-queries

#### 5.5.6 Trace: TransportReportController Notifications Section

**Trigger:** GET `/transport/reports?tab=notifications&section=...`

**Code Flow:**
```
TransportReportController@index(Request $request)             [transportReportController.php:34]
│
├─ Gate::authorize('tenant.transport.viewAny')               [line 36]
│
├─ $activeTab = $request->get('tab', 'route-performance')    [line 38]
│   ← Default is 'route-performance', NOT 'notifications'
│
├─ $reqFilters = [...                                        [lines 42-53]
│   'notification_type' => ...,                              ← passed but not used in underlying query
│   'delivery_status' => ...                                 ← not stored in DB; only compared during collection filter
│   ]
│
├─ if ($request->ajax() && $section) {                       [line 60]
│   └─ $this->loadTabSection($activeTab, ...)                 [line 61]
│       └─ match($tab) { ... 'notifications'                  [line 87]
│           └─ $this->buildNotificationsSection(...)           [line 87]
│
│           buildNotificationsSection                            [line 237-244]
│           ├─ getNotificationsAlertsReport($reqFilters, ...)   [line 240]
│           │   ← Queries 3 tables INDEPENDENTLY
│           │     1. TptTripIncidents (lines 376-410)
│           │     2. StudentBoardingLog (lines 413-471)
│           │     3. TptTrip (lines 474-532)
│           │   ← Merges results into single synthetic collection
│           │   ← Applies notification_type/delivery_status filter at PHP level
│           │     (NOT in DB query — potential memory issues with large datasets)
│           │
│           ├─ prepareNotificationsSummary($notificationsData)  [line 241]
│           │   ← Computes delivery status from synthetic 'overall_status' field
│           │   ← Computes daily trend from synthetic 'sent_time'
│           │   ← References 'sla_status' field — NEVER SET by mapping functions
│           │     → $slaCompliant = 0 always → sla_rate = 0 always
│           │
│           └─ view('transport::report.transport-notifications-alerts.index')
│
└─ END
```

**Issues in getNotificationsAlertsReport:**
- `$filters['delivery_status']` filter at line 547-552 references `$notification->overall_status` and `$notification->status_class` — NEITHER IS SET by the mapping functions. The filter will always filter to empty results because `overall_status` is undefined.
- `$filters['delivery_status']` defaults to `all` — the condition `$filters['delivery_status'] !== 'all'` allows through. But even then, `ucfirst($filters['delivery_status'])` will never match undefined properties.
- `$filters['notification_type']` filter at lines 541-545 compares against only the 4 synthetic types, not the 5 real DB types
- `take(500)` at line 555 silently truncates — no user-facing pagination indicator showing hidden records
- `limit(200)` at line 431 on StudentBoardingLog subquery introduces hardcoded limit within a paginated collection — records beyond 200 per query are silently ignored

#### 5.5.7 Trace: Permission Check Chain

```
USER REQUESTS: GET /transport/trip-management?tab=notification_log
│
├─ WEB ROUTE: Route::resource('transport.trip-management', TripMgmtController::class)
│   ← Maps to TripMgmtController@index()
│
├─ CONTROLLER: TripMgmtController@index()
│   ├─ Gate::authorize('tenant.transport.viewAny')      ← BLOCKING GATE (line 38)
│   │   └─ If user lacks 'tenant.transport.viewAny'     → 403 FORBIDDEN
│   │   └─ If user has 'tenant.transport.viewAny'       → PASS
│   │
│   └─ ...query and view render...
│
├─ BLADE: tripmanagement.blade.php
│   ├─ x-backend.tab.nav-tab                             ← Component hides tab button
│   │   └─ permission='tenant.notification-log.viewAny'  ← If user lacks → button hidden
│   │
│   ├─ @can('tenant.notification-log.viewAny')           ← IF PASS → include partial
│   │   └─ @include('transport::notification-log.index')
│   │
│   └─ View renders notification log data
│
└─ END
```

**Permission Hierarchy Issue:**
| User Permission Set | Can Reach Tab? | Can See Tab Button? | Can See Content? |
|--------------------|----------------|---------------------|------------------|
| `transport.viewAny` + `notification-log.viewAny` | ✅ Yes | ✅ Yes | ✅ Yes |
| `notification-log.viewAny` only | ❌ 403 at Gate | N/A | N/A |
| `transport.viewAny` only | ✅ Yes | ❌ Hidden | ❌ `@can` blocks |
| Neither | ❌ 403 at Gate | N/A | N/A |

**Result:** Dedicated `notification-log.viewAny` permission is USELESS without `transport.viewAny`. The permission separation violates principle of least privilege.

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Notification Log Tab Loads | `/transport/trip-management?tab=notification_log` shows notification grid | — | — | ⬜ |
| TC-P02 | TripStart Notification Created | POST stopAction start_trip → notification_log record with type='TripStart', app_status='Sent' | — | — | ⬜ |
| TC-P03 | ReachedStop Notification Created | POST stopAction reach → notification type='ReachedStop' | — | — | ⬜ |
| TC-P04 | Delayed Notification Created | POST stopAction reach when >5min late → notification type='Delayed' | — | — | ⬜ |
| TC-P05 | ApproachingStop Notification Created | POST stopAction leave → notification type='ApproachingStop' | — | — | ⬜ |
| TC-P06 | Cancelled Notification Created | PUT trip status='Cancelled' → notification type='Cancelled' | — | — | ⬜ |
| TC-P07 | Notification Shows Trip and Stop Info | Grid displays trip info and boarding stop name — **BLOCKED by TC-CR14** (missing relationships crash with()) | — | — | ⬜ |
| TC-P08 | Filter by Notification Type | Click type button group → matching notifications | — | — | ⬜ |
| TC-P09 | Empty State — No Notifications | "No notification logs found" message displayed | — | — | ⬜ |
| TC-P10 | Notification Time Shows sent_time | sent_time displayed in "d M Y, h:i A" format | — | — | ⬜ |
| TC-P11 | Multiple Stop Actions Create Multiple Notifications | start_trip + reach + leave → 3 notification records for same trip | — | — | ⬜ |
| TC-P12 | App Status Badge Shows 'Sent' | Green badge with 'Sent' displayed for app_notification_status | — | — | ⬜ |
| TC-P13 | SMS/Email/WhatsApp Show '-' When NULL | All non-app channels display '-' in table cells | — | — | ⬜ |
| TC-P14 | Filter 'All' Shows All Types | Click 'All' button → all notification types displayed with no filter | — | — | ⬜ |
| TC-P15 | Filter Persists Across Pagination | Navigate to page 2 → notification_type filter still applied | — | — | ⬜ |
| TC-P16 | TransportReportController Notifications Tab Loads | AJAX request to reports → notifications section renders HTML with synthetic data | — | — | ⬜ |
| TC-P17 | Tab Persists After Browser Refresh | Reload page → same tab 'notification_log' stays active | — | — | ⬜ |
| TC-P18 | sent_time Displays Correctly in Different Timezones | sent_time stored and displayed consistently with app timezone | — | — | ⬜ |
| TC-P19 | Exactly 5 Filter Buttons Displayed | TripStart, ApproachingStop, ReachedStop, Delayed, Cancelled — all 5 visible | — | — | ⬜ |
| TC-P20 | 10 Records Per Page | Pagination shows exactly 10 records per page (or fewer on last page) | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No Notifications for end_trip Action | end_trip does NOT create any notification | — | — | ⬜ |
| TC-N02 | No Notifications for emergency Action | emergency does NOT create any notification | — | — | ⬜ |
| TC-N03 | SMS/Email/WhatsApp Always NULL | All notification records have NULL for non-app channels | — | — | ⬜ |
| TC-N04 | Invalid notification_type Filter | No validation on filter; no results returned | — | — | ⬜ |
| TC-N05 | Tab Hidden Without notification-log.viewAny | Tab button hidden if user lacks `tenant.notification-log.viewAny` | — | — | ⬜ |
| TC-N06 | Guest Access | Redirect to `/login` | — | — | ⬜ |
| TC-N07 | Permission Mismatch — Controller vs Blade | User with ONLY `tenant.notification-log.viewAny` (not `tenant.transport.viewAny`) gets 403 from TripMgmtController@index before tab renders | — | — | ⬜ |
| TC-N08 | Direct URL Access Without Controller Permission | Visiting `/transport/trip-management?tab=notification_log` without `tenant.transport.viewAny` returns 403 | — | — | ⬜ |
| TC-N09 | No activityLog on Notification Creation | stopAction and update create notifications silently — no audit trail entry generated | — | — | ⬜ |
| TC-N10 | No Notification When sch_arrival_time is NULL | stopAction reach with NULL sch_arrival_time → ReachedStop (never Delayed) | — | — | ⬜ |
| TC-N11 | Notification Count Not Modified by Deleted Trip | Trip deleted → notifications remain with trip_id = NULL (ON DELETE SET NULL) | — | — | ⬜ |
| TC-N12 | Pagination Page Parameter Corrupts Other Tabs | `?tab=notification_log&page=2` incorrectly shifts other tabs' data to page 2 | — | — | ⬜ |
| TC-N13 | TransportationReport Notifications Cannot Be Created Directly | No create/store route exists for TptNotificationLog from report | — | — | ⬜ |
| TC-N14 | Delayed Notification Not Created When Exactly 5 Minutes Late | `$now->gt(sch_arrival + 5min)` — exactly equal does NOT trigger 'Delayed' | — | — | ⬜ |
| TC-N15 | No Notification When Trip Update Status Is Not 'Cancelled' | Setting status to 'Completed' or 'Ongoing' does NOT create notification | — | — | ⬜ |
| TC-N16 | Cannot Edit or Delete Notification via UI | No edit/delete buttons or routes exist for notification log records | — | — | ⬜ |
| TC-N17 | TransportReportController Notifications Empty State | No incidents, boarding logs, or trip activity → empty report section | — | — | ⬜ |
| TC-N18 | TransportReportController delivery_status Filter Never Matches | `overall_status` undefined in synthetic data → filter produces empty result | — | — | ⬜ |
| TC-N19 | Cross-Tab Search Parameters Affect Notification Tab | `?tab=notification_log&shift_id=X` — shift_id has no effect on notification query | — | — | ⬜ |
| TC-N20 | sent_time Remains NULL for Manual DB Inserts | INSERT without sent_time → displayed as '-' in blade | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Trip Deletion — Notification SET NULL | FK SET NULL on trip_id → trip_id becomes NULL | — | — | ⬜ |
| TC-D02 | B | Stop (PickupPoint) Deletion — Notification SET NULL | FK SET NULL on boarding_stop_id | — | — | ⬜ |
| TC-D03 | C | Multiple Actions Create Multiple Notifications | start_trip → reach → leave → 3 notification records for same trip | — | — | ⬜ |
| TC-D04 | D | Trip Cancelled Creates Notification Without Affecting Existing | Existing notifications remain; new Cancelled record added | — | — | ⬜ |
| TC-D05 | E | Student Session Deletion — Notification SET NULL | FK SET NULL on student_session_id (though never populated) | — | — | ⬜ |
| TC-D06 | F | Trip Deletion Cascades to Notification Display | Deleted trip → notification row still exists but trip_id = NULL → grid shows '-' for trip | — | — | ⬜ |
| TC-D07 | G | No Notifications Created for Trips Without Stop Actions | Trip created via store() → no stops → no notifications | — | — | ⬜ |
| TC-D08 | H | Same Trip Action Twice Creates Two Notifications | POST start_trip twice for same trip → two TripStart records | — | — | ⬜ |
| TC-D09 | I | TransportReport Tab Filters Share Same Scope | notification_type filter applies to all 3 synthetic sources | — | — | ⬜ |
| TC-D10 | J | Notification Log Independent of Trip Approval Status | Trip approved or disapproved — no notification created for approval action | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — No Dedicated NotificationLogController | No index/create/store/edit/update/destroy methods — only listing via TripMgmtController | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — Notification creation in TripController@stopAction | 4 notification types created: TripStart, ReachedStop/Delayed, ApproachingStop | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — Notification creation in TripController@update | When status='Cancelled', creates 'Cancelled' notification | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — No notification for end_trip action | End trip is silent — no notification created | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — No notification for emergency action | Emergency is silent — no notification created | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — All notifications hardcode app_status='Sent' | No actual push notification or SMS/email sending logic | — | — | ◌ |
| TC-CR07 | CR | P1 | Model — Empty fillable array | `protected $fillable = []` — all attributes must be set individually | — | — | ◌ |
| TC-CR08 | CR | P1 | Model — No SoftDeletes trait | `deleted_at` column exists in DDL but model does not use SoftDeletes | — | — | ◌ |
| TC-CR09 | CR | P1 | Model — No relationships defined | Despite FKs to trip, student_session, boarding_stop, no Eloquent relationships exist | — | — | ◌ |
| TC-CR10 | CR | P1 | TripMgmtController — notificationLogQuery uses with(['trip','boardingStop']) | Eager loads from model but model has no relationships defined → this will FAIL | — | — | ◌ |
| TC-CR11 | CR | P1 | DDL — FK Constraints | All 3 FKs use ON DELETE SET NULL | — | — | ◌ |
| TC-CR12 | CR | P1 | DDL — ENUM for notification_type | Values: TripStart, ApproachingStop, ReachedStop, Delayed, Cancelled | — | — | ◌ |
| TC-CR13 | CR | P1 | Routes — No dedicated routes | No resource or custom routes for notification log CRUD | — | — | ◌ |
| TC-CR14 | CR | P1 | Gap — Critical: notificationLogQuery uses with() on model with no relationships | `TptNotificationLog::with(['trip','boardingStop'])` will crash because model has NO relationships defined. **CRITICAL BUG** | — | — | ◌ |
| TC-CR15 | CR | P1 | Gap — No SoftDeletes despite DDL having deleted_at | Model missing `use SoftDeletes` — deleted_at will never be set | — | — | ◌ |
| TC-CR16 | CR | P1 | Gap — No actual notification sending implemented | All channels except app_status remain NULL; app_status hardcoded to 'Sent' without actual delivery | — | — | ◌ |
| TC-CR17 | CR | P1 | Gap — No CRUD operations on notification log | Users cannot update notification status, retry failed, or delete records | — | — | ◌ |
| TC-CR18 | CR | P1 | Gap — Missing activityLog in stopAction | stopAction creates TptNotificationLog (lines 210, 231, 246) without calling `activityLog()` — no audit trail | — | — | ◌ |
| TC-CR19 | CR | P1 | Gap — Missing activityLog in update Cancelled | TripController@update creates 'Cancelled' notification (line 370) without calling `activityLog()` — no audit trail | — | — | ◌ |
| TC-CR20 | CR | P2 | Gap — student_session_id never populated | Migration defines FK to `std_student_academic_sessions` (column: `student_session_id`) but TripController never sets it in any `TptNotificationLog::create()` call | — | — | ◌ |
| TC-CR21 | CR | P2 | Gap — HasFactory declared but no factory class | Model uses `HasFactory` trait but `newFactory()` is commented out — `TptNotificationLogFactory` does not exist | — | — | ◌ |
| TC-CR22 | CR | P1 | Gap — No delete/restore/forceDelete for notifications | No dedicated controller or routes, so no way to trash, restore, or permanently delete notification log records | — | — | ◌ |
| TC-CR23 | CR | P2 | Notification type filter uses button-group links not dropdown | Blade uses `<a>` button-group styled links, not `<select>` dropdown — UI difference from TC-P08 assumption | — | — | ◌ |
| TC-CR24 | CR | P2 | Blade uses null-safe operators `$item->trip?->id` | `notification-log/index.blade.php` uses `$item->trip?->id` and `$item->boardingStop?->name` — works only if with() doesn't crash, otherwise silently returns '-' | — | — | ◌ |
| TC-CR25 | CR | P1 | Gap — Blade view crashes before rendering due to with() | notificationLogQuery() throws BadMethodCallException → tab never renders → blank page or 500 error | — | — | ◌ |
| TC-CR26 | CR | P1 | Gap — Controller permission key mismatch | TripMgmtController@index checks `tenant.transport.viewAny` but blade uses `tenant.notification-log.viewAny` | — | — | ◌ |
| TC-CR27 | CR | P1 | Gap — TransportReportController notifications use synthetic data | Separate implementation doesn't query TptNotificationLog — duplicate logic, no dedup, no shared types | — | — | ◌ |
| TC-CR28 | CR | P2 | Gap — TransportReportController delivery_status filter references undefined fields | `overall_status` and `status_class` never set in synthetic data → filter produces empty results or PHP warnings | — | — | ◌ |
| TC-CR29 | CR | P2 | Gap — TransportReportController notifications have hardcoded limit(200) on boarding subquery | StudentBoardingLog subquery has ->limit(200) within a paginated context — records beyond 200 silently dropped | — | — | ◌ |
| TC-CR30 | CR | P2 | Gap — Cross-tab pagination conflict | All 8 paginate() calls in TripMgmtController@index use default `page` paginator name | — | — | ◌ |
| TC-CR31 | CR | P1 | Gap — All 8 sub-queries execute on every tab load | No lazy loading — notification_log tab triggers ALL queries even though only one is needed | — | — | ◌ |
| TC-CR32 | CR | P2 | Gap — Delay threshold hardcoded at 5 minutes | `addMinutes(5)` in TripController line 227 — not configurable, not documented | — | — | ◌ |
| TC-CR33 | CR | P2 | Gap — 'ApproachingStop' semantic mismatch | Type named 'ApproachingStop' but created on 'leave' action, not 'approach' — semantically misleading | — | — | ◌ |
| TC-CR34 | CR | P2 | Gap — No data retention / archival policy | Notification log table grows unbounded with every trip stop action — no purge/archive mechanism | — | — | ◌ |
| TC-CR35 | CR | P1 | Gap — No test factory for notifications | `TptNotificationLogFactory` class doesn't exist but `HasFactory` trait is used — factory() call will fail | — | — | ◌ |
| TC-CR36 | CR | P2 | Gap — TransportReportController calculateWorkingDays excludes only weekends | `!$start->isWeekend()` — doesn't account for holidays, school events, or partial days | — | — | ◌ |
| TC-CR37 | CR | P2 | Gap — notifications tab is NOT default tab | TransportReportController defaults to 'route-performance' — notifications requires explicit tab param | — | — | ◌ |
| TC-CR38 | CR | P2 | Gap — notification_type filter in TransportReport not validated | `$filters['notification_type']` accepts any string — no ENUM validation | — | — | ◌ |
| TC-CR39 | CR | P1 | Gap — permissionslist.php defines only viewAny+view for notification-log | `'notification-log' => ['viewAny', 'view']` — no create, update, delete, restore, forceDelete, status, export, print | — | — | ◌ |
| TC-CR40 | CR | P1 | Gap — Model timestamp columns not explicitly cast | `created_at` and `updated_at` handled by Eloquent defaults but `sent_time` is a plain DATETIME with no Carbon casting | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P01: Notification Log Tab Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with both `tenant.transport.viewAny` AND `tenant.notification-log.viewAny` | Dashboard loads |
| 2 | Navigate to `/transport/trip-management?tab=notification_log` | Page loads without error |
| 3 | Verify breadcrumb shows "Trip Management" | Breadcrumb displayed |
| 4 | Verify Notification Log tab is active (highlighted) | Tab has 'active' styling |
| 5 | Verify notification grid/table area is visible | Table with columns: #, Type, Trip, Stop, Sent Time, App, SMS, Email, WhatsApp |
| 6 | Verify filter buttons are displayed above table | 6 buttons: All, TripStart, ApproachingStop, ReachedStop, Delayed, Cancelled |
| 7 | NOTE: If page crashes (500 error), verify model relationships exist | See TC-CR14 — this tab is currently broken |

### TC-P02: TripStart Notification Created

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure an active trip exists for today with route scheduler configured | Trip record exists |
| 2 | POST `/trip/stop-action` with `action=start_trip, id=new_{jntId}` where jntId maps to first stop | Stop action succeeds (HTTP 200, status=true) |
| 3 | DB check: `SELECT * FROM tpt_notification_log WHERE trip_id={tripId} AND notification_type='TripStart'` | Record exists |
| 4 | Verify `sent_time` is set to current timestamp | sent_time equals request time |
| 5 | Verify `app_notification_status = 'Sent'` | Status is 'Sent' |
| 6 | Verify `sms_notification_status IS NULL` | SMS is NULL |
| 7 | Verify `email_notification_status IS NULL` | Email is NULL |
| 8 | Verify `whatsapp_notification_status IS NULL` | WhatsApp is NULL |
| 9 | Verify `boarding_stop_id` matches the stop's pickup_point_id | FK populated correctly |
| 10 | Verify `student_session_id IS NULL` | student_session_id is NULL (unpopulated) |
| 11 | Navigate to Notification Log tab (if tab works — see TC-CR14) | Record visible in grid with 'TripStart' badge |

### TC-P03: ReachedStop Notification Created

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify an active stop detail with `sch_arrival_time` set to >6 minutes from now (to avoid delay detection) | Stop detail record exists |
| 2 | POST `/trip/stop-action` with `action=reach, id={stopDetailId}` | Action succeeds (HTTP 200) |
| 3 | DB check: `SELECT notification_type, sent_time FROM tpt_notification_log WHERE trip_id={tripId} ORDER BY id DESC LIMIT 1` | notification_type='ReachedStop' |
| 4 | Verify `sent_time` is approximately current time | Difference < 2 seconds |
| 5 | Verify stop detail's `reached_flag = 1` and `reaching_time` is set | Stop detail updated |

### TC-P04: Delayed Notification Created

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a stop detail where `sch_arrival_time` is set to >5 minutes ago (e.g., sch_arrival_time = now - 6min) | Stop with known past arrival time |
| 2 | If no stop has past sch_arrival_time, create one: update `sch_arrival_time = DATE_SUB(NOW(), INTERVAL 6 MINUTE)` | sch_arrival_time is in past |
| 3 | POST `/trip/stop-action` with `action=reach, id={stopDetailId}` | Action succeeds |
| 4 | DB check: `SELECT notification_type FROM tpt_notification_log WHERE trip_id={tripId} ORDER BY id DESC LIMIT 1` | notification_type='Delayed' |
| 5 | Verify: if `sch_arrival_time` is NULL, notification_type should be 'ReachedStop' even if reach is late | NULL sch_arrival → ReachedStop, never Delayed |

### TC-P05: ApproachingStop Notification Created

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a stop detail that has been reached (reached_flag=1) but not yet left | Stop detail exists |
| 2 | POST `/trip/stop-action` with `action=leave, id={stopDetailId}` | Action succeeds |
| 3 | DB check: `SELECT * FROM tpt_notification_log WHERE trip_id={tripId} AND notification_type='ApproachingStop'` | Record exists |
| 4 | Verify `boarding_stop_id` matches the stop | Correct stop ID |
| 5 | Verify `app_notification_status = 'Sent'` | Status is 'Sent' |
| 6 | NOTE: Notification type 'ApproachingStop' is created on 'leave' — semantic mismatch documented in TC-CR33 | Deviation noted |

### TC-P06: Cancelled Notification Created

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify an active trip (status NOT 'Cancelled') | Trip exists |
| 2 | PUT `/trip/{id}` with payload including `status=Cancelled` | Update succeeds, redirect to trip management |
| 3 | DB check: `SELECT * FROM tpt_notification_log WHERE trip_id={tripId} AND notification_type='Cancelled'` | Record exists |
| 4 | Verify `boarding_stop_id IS NULL` (cancellation has no stop) | boarding_stop_id is NULL |
| 5 | Verify `sent_time` is set | sent_time populated |
| 6 | Verify `app_notification_status = 'Sent'` | Status is 'Sent' |
| 7 | Check activity_log table: `SELECT * FROM activity_log WHERE subject_id = {tripId} ORDER BY created_at DESC` | Trip update logged, but NO activity_log entry for notification creation specifically |

### TC-P07: Notification Shows Trip and Stop Info

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PREREQUISITE: Add `trip()` and `boardingStop()` relationships to `TptNotificationLog` model | Model has relationships defined |
| 2 | PREREQUISITE: Replace `with(['trip','boardingStop'])` in notificationLogQuery with correct relationship paths | Query works |
| 3 | Navigate to Notification Log tab | Tab loads, grid visible |
| 4 | For each notification record, verify trip ID column shows the associated trip ID | `$item->trip->id` displays correctly |
| 5 | Verify stop name column shows the boarding stop name | `$item->boardingStop->name` displays correctly |
| 6 | If relationships NOT yet fixed, verify 500 error occurs when loading tab | See TC-CR14 for the blocking bug |
| 7 | THIS TEST IS BLOCKED until TC-CR14 is resolved | ⛔ BLOCKED |

### TC-P08: Filter by Notification Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Notification Log tab with existing notifications of multiple types | Multiple type records exist |
| 2 | Click "TripStart" filter button | URL changes to include `?tab=notification_log&notification_type=TripStart`, only TripStart records shown |
| 3 | Click "ReachedStop" filter button | Only ReachedStop records shown |
| 4 | Click "Delayed" filter button | Only Delayed records shown |
| 5 | Click "ApproachingStop" filter button | Only ApproachingStop records shown |
| 6 | Click "Cancelled" filter button | Only Cancelled records shown |
| 7 | Click "All" filter button | All notification types displayed |
| 8 | Verify active filter button has `btn-primary` class, others have `btn-outline-secondary` | Active state visible |

### TC-P09: Empty State — No Notifications

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no notifications exist: `DELETE FROM tpt_notification_log` (or use fresh test DB) | Table empty |
| 2 | Navigate to Notification Log tab | Page loads successfully |
| 3 | Verify "No notification logs found." message displayed | Text in `<td colspan="9">` element |
| 4 | Verify message is centered with `text-center text-muted py-3` classes | Styling correct |
| 5 | Verify table header row is still visible | Columns: #, Type, Trip, Stop, Sent Time, App, SMS, Email, WhatsApp |

### TC-P10: Notification Time Shows sent_time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a notification record exists with non-null `sent_time` | sent_time is '2026-07-22 14:30:00' for example |
| 2 | Navigate to Notification Log tab | Grid displays |
| 3 | Verify Sent Time column shows time in "d M Y h:i A" format | e.g., "22 Jul 2026 02:30 PM" |
| 4 | Verify record with NULL sent_time displays '-' | Hyphen displayed for NULL |
| 5 | Verify format matches PHP `date('d M Y h:i A', strtotime(...))` pattern | AM/PM, 12-hour format |

### TC-P11: Multiple Stop Actions Create Multiple Notifications

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST start_trip for a trip | TripStart notification created |
| 2 | POST reach for the same trip | ReachedStop OR Delayed notification created |
| 3 | POST leave for the same trip | ApproachingStop notification created |
| 4 | DB check: `SELECT COUNT(*) FROM tpt_notification_log WHERE trip_id={tripId}` | 3 records |
| 5 | Verify each record has different notification_type | Types: TripStart, ReachedStop/Delayed, ApproachingStop |
| 6 | Verify each record has different sent_time | Timestamps increment with each action |

### TC-P12: App Status Badge Shows 'Sent'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure notification records exist with `app_notification_status='Sent'` | Records exist |
| 2 | Inspect App column in grid | Badge displays 'Sent' |
| 3 | Verify badge uses success color scheme | `bg-success-subtle text-success border border-success rounded-pill` |
| 4 | If `app_notification_status` is NULL, badge shows '-' | Fallback to secondary color scheme |

### TC-P13: SMS/Email/WhatsApp Show '-' When NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure notification records exist with NULL sms/email/whatsapp statuses | Records exist |
| 2 | Inspect SMS column | '-' displayed (secondary badge or text) |
| 3 | Inspect Email column | '-' displayed |
| 4 | Inspect WhatsApp column | '-' displayed |
| 5 | Verify each column uses `bg-secondary-subtle text-secondary border border-secondary rounded-pill` | Fallback styling applied |

### TC-P14: Filter 'All' Shows All Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Notification Log tab with notifications of various types present | Multiple types exist |
| 2 | Verify 'All' button has `btn-primary` class (active) | Active styling |
| 3 | Click a type filter (e.g., TripStart) | Filter applied, only TripStart shown |
| 4 | Click 'All' button | All types shown again |
| 5 | Verify URL no longer has `notification_type` parameter | Clean URL or ?tab=notification_log only |

### TC-P15: Filter Persists Across Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 25+ notification records of type 'TripStart' | 25+ records exist |
| 2 | Navigate to Notification Log tab | Page 1 shows first 10 records |
| 3 | Click 'TripStart' filter | Filter applied |
| 4 | Click page 2 link | Page 2 loads with TripStart filter still active |
| 5 | Verify URL contains both `notification_type=TripStart` and `page=2` | Parameters persist |
| 6 | Verify only TripStart records shown on page 2 | Filter maintained across pages |

### TC-P16: TransportReportController Notifications Tab Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.transport.viewAny` permission | Authenticated |
| 2 | Navigate to `/transport/reports?tab=notifications` | Report page loads |
| 3 | Verify notifications tab is NOT the default — URL uses `tab=notifications` explicitly | Tab shows notifications section |
| 4 | Trigger AJAX load (if lazy-loaded) | Section renders with synthetic data |
| 5 | Verify data includes `IncidentAlert` type (from TptTripIncidents) | Incident data shown |
| 6 | Verify data includes `BoardUnboard` type (from StudentBoardingLog) | Boarding data shown |
| 7 | Verify data includes `TripStart` and `TripCompletion` types (from TptTrip) | Trip status data shown |
| 8 | Verify notification type in report does NOT include DB-only types | Delayed, ReachedStop, ApproachingStop, Cancelled NOT present |

### TC-P17: Tab Persists After Browser Refresh

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/transport/trip-management?tab=notification_log` | Tab loads |
| 2 | Apply a filter: click 'Delayed' button | URL: `?tab=notification_log&notification_type=Delayed` |
| 3 | Press F5 / browser refresh | Same tab + filter maintained |
| 4 | Verify Notification Log tab is still active | Active styling |
| 5 | Verify filter still shows Delayed records | Only Delayed notifications shown |
| 6 | Navigate to a different tab (e.g., daily_trip) | Switch to daily_trip |
| 7 | Navigate back to notification_log | Tab restores, filter state may reset (GET param lost) |

### TC-P18: sent_time Displays Correctly in Different Timezones

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create notification with sent_time = '2026-07-22 14:30:00' UTC | Record created |
| 2 | Verify app timezone in `config/app.php` | e.g., 'Asia/Kolkata' (UTC+5:30) |
| 3 | Load Notification Log tab | sent_time displayed in app timezone |
| 4 | NOTE: Carbon::now() creates timestamp in default timezone | sent_time uses app timezone, no explicit conversion needed |
| 5 | Verify blade does NOT apply additional timezone conversion | `date('d M Y h:i A', strtotime($item->sent_time))` — plain PHP date, no Carbon format |

### TC-P19: Exactly 5 Filter Buttons Displayed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Notification Log tab | Page loads |
| 2 | Count filter buttons in the `.d-flex.flex-wrap.gap-2` container | 6 buttons: All + 5 type buttons |
| 3 | Verify each type button text matches ENUM: TripStart, ApproachingStop, ReachedStop, Delayed, Cancelled | All 5 present |
| 4 | Verify 'All' button is first in order | 'All' appears before type buttons |

### TC-P20: 10 Records Per Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 25 notification records | 25 records in table |
| 2 | Navigate to Notification Log tab | 10 records displayed |
| 3 | Verify pagination links shown below table | Page 1, 2, 3 links visible |
| 4 | Count records on page 1 | 10 records |
| 5 | Navigate to page 2 | 10 records |
| 6 | Navigate to page 3 | 5 records |
| 7 | Verify `->paginate(10)` is used in controller | 10 per page |

### TC-N01: No Notifications for end_trip Action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify an active trip with at least one stop reached | Trip in progress |
| 2 | POST `/trip/stop-action` with `action=end_trip, id={lastStopDetailId}` | Action succeeds |
| 3 | DB check: `SELECT COUNT(*) FROM tpt_notification_log WHERE trip_id={tripId} AND notification_type NOT IN ('TripStart','ReachedStop','Delayed','ApproachingStop')` | No records beyond expected types |
| 4 | Verify no new notification was created with type related to end_trip | No 'TripEnd' or 'Completed' type in ENUM anyway |
| 5 | Verify trip `status` changed to 'Completed' | Trip status updated |

### TC-N02: No Notifications for emergency Action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/trip/stop-action` with `action=emergency, id={stopDetailId}, remark="Test emergency"` | Action succeeds |
| 2 | DB check: `SELECT COUNT(*) FROM tpt_notification_log WHERE trip_id={tripId}` | Count unchanged from before emergency (no new notification for emergency) |
| 3 | Verify `TptTripIncidents` record was created | Incident record exists with emergency data |
| 4 | Cross-check: no ENUM value exists for 'Emergency' or 'SafetyAlert' in tpt_notification_log.notification_type | ENUM doesn't support emergency notifications |

### TC-N03: SMS/Email/WhatsApp Always NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Execute all 5 notification creation scenarios (start_trip, reach, leave, cancel) | 5 notification records |
| 2 | Query: `SELECT sms_notification_status, email_notification_status, whatsapp_notification_status FROM tpt_notification_log` | All NULL for all records |
| 3 | Verify no controller code sets these fields | grep for 'sms_notification_status', 'email_notification_status', 'whatsapp_notification_status' → no writes |
| 4 | Verify blade displays '-' for all NULL channels | '-' visible in UI |

### TC-N04: Invalid notification_type Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Notification Log tab | Tab loads |
| 2 | Manually edit URL to: `?tab=notification_log&notification_type=InvalidTypeXYZ` | Page loads |
| 3 | Verify no records shown (invalid type matches nothing) | Empty table with "No notification logs found" |
| 4 | Verify no SQL error occurs | ENUM column silently ignores invalid WHERE value — MySQL returns empty set |
| 5 | Verify no validation error or flash message | Filter silently produces empty results |

### TC-N05: Tab Hidden Without notification-log.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.transport.viewAny` but WITHOUT `tenant.notification-log.viewAny` | User authenticated |
| 2 | Navigate to `/transport/trip-management` | Trip Management page loads (no 403) |
| 3 | Verify Notification Log tab button is NOT visible in tab navigation | Tab button absent |
| 4 | Verify URL manipulation: visit `?tab=notification_log` | Tab nav component hides button, but @can in blade also prevents rendering |
| 5 | Verify notification content is NOT rendered (even via URL manipulation) | `@can('tenant.notification-log.viewAny')` prevents `@include` |

### TC-N06: Guest Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout or use incognito session | Not authenticated |
| 2 | Visit `/transport/trip-management?tab=notification_log` | Redirected to `/login` |
| 3 | Verify HTTP 302 redirect | Redirect status |
| 4 | Verify after login, user is redirected back to original URL (if configured) | Return to tab |

### TC-N07: Permission Mismatch — Controller vs Blade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create user with role granting ONLY `tenant.notification-log.viewAny` (NOT `tenant.transport.viewAny`) | User exists with limited permissions |
| 2 | Navigate to `/transport/trip-management?tab=notification_log` | **403 Forbidden** — TripMgmtController@index checks `tenant.transport.viewAny` which user lacks |
| 3 | Does tab button render? | Never reached — controller blocks before blade |
| 4 | Severity | **MEDIUM** — Dedicated `notification-log` permission is unusable on its own |
| 5 | Verify `permissionslist.php` defines notification-log permissions | `'notification-log' => ['viewAny', 'view']` |
| 6 | Verify controller gate string | `'tenant.transport.viewAny'` — does not match |

### TC-N08: Direct URL Access Without Controller Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.transport.viewAny` | User exists |
| 2 | Direct URL: `/transport/trip-management?tab=notification_log` | **403 Forbidden** |
| 3 | Verify Gate::authorize() blocks before any query executes | Controller line 38 fails |
| 4 | Verify no blade rendering occurs | Exception thrown before view |

### TC-N09: No activityLog on Notification Creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Execute start_trip action (creates TripStart notification) | Notification created |
| 2 | Query activity_log table: `SELECT * FROM activity_log WHERE subject_type LIKE '%TptNotificationLog%'` | 0 records — no audit trail |
| 3 | Execute reach action (creates ReachedStop/Delayed notification) | Notification created |
| 4 | Query activity_log again | Still 0 records for notification |
| 5 | Execute leave action (creates ApproachingStop notification) | Notification created |
| 6 | Query activity_log again | Still 0 records |
| 7 | Cancel trip (creates Cancelled notification) | Notification created |
| 8 | Query activity_log for trip update event | Trip update is logged (activityLog in update() at line 378), but notification creation is NOT logged |

### TC-N10: No Notification When sch_arrival_time is NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify or create a stop detail with `sch_arrival_time IS NULL` | NULL arrival time |
| 2 | POST `/trip/stop-action` with `action=reach, id={stopDetailId}` | Action succeeds |
| 3 | DB check: `SELECT notification_type FROM tpt_notification_log WHERE trip_id={tripId} ORDER BY id DESC LIMIT 1` | `notification_type='ReachedStop'` (NOT 'Delayed') |
| 4 | Verify delay condition: `$stop->sch_arrival_time` is NULL → condition `$now->gt(...)` is NOT evaluated as true | Guard clause prevents delay detection |

### TC-N11: Notification Count Not Modified by Deleted Trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create notification records for a trip | Notifications exist |
| 2 | Get current count: `SELECT COUNT(*) FROM tpt_notification_log WHERE trip_id={tripId}` | N records |
| 3 | Delete the trip: `DELETE FROM tpt_trip WHERE id={tripId}` (or via UI) | Trip deleted |
| 4 | Re-count: `SELECT COUNT(*) FROM tpt_notification_log WHERE trip_id={tripId}` | Still N records (FK SET NULL, not CASCADE) |
| 5 | Verify `trip_id` column now contains NULL for those records | SET NULL applied |
| 6 | Verify record still exists in table | Row preserved |

### TC-N12: Pagination Page Parameter Corrupts Other Tabs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 25+ records for multiple tab types (e.g., trips, notifications, incidents) | Records exist |
| 2 | Navigate to a non-notification tab (e.g., daily_trip) and note page count | daily_trip has X pages |
| 3 | Navigate to `?tab=notification_log&page=2` | Page 2 of notifications shows |
| 4 | Navigate BACK to daily_trip: `?tab=daily_trip` (without page param) | daily_trip shows page 1? Or page 2 because `page` parameter was in session? |
| 5 | Verify issue: all paginate() calls share default `page` name | Cross-tab pagination corruption |
| 6 | This is a design flaw — no unique page names per tab | See TC-CR30 |

### TC-N13: TransportReport Notifications Cannot Be Created Directly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check routes: `php artisan route:list | grep notification` | Only trip-management index route |
| 2 | Check TransportReportController methods | No create/store methods for notifications |
| 3 | Verify synthetic report is read-only | No form/submit in notifications report |
| 4 | Verify no POST/DELETE endpoints for notification log exist | No create, update, delete routes |

### TC-N14: Delayed Notification Not Created When Exactly 5 Minutes Late

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `sch_arrival_time` to exactly 5 minutes before now | sch_arrival = now - 5min |
| 2 | POST `/trip/stop-action` with `action=reach` | Action succeeds |
| 3 | Check code: `$now->gt(Carbon::parse($stop->sch_arrival_time)->addMinutes(5))` | `gt()` is strict greater-than — if now == sch_arrival + 5min, condition is FALSE |
| 4 | Expected: `notification_type='ReachedStop'` (NOT delayed) | Strict inequality means exactly 5 min = NOT delayed |
| 5 | Now set sch_arrival to 5min 1sec before now | sch_arrival = now - 5min - 1sec |
| 6 | POST reach again | Action succeeds |
| 7 | Expected: `notification_type='Delayed'` | Now condition is TRUE |

### TC-N15: No Notification When Trip Update Status Is Not 'Cancelled'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/trip/{id}` with `status=Completed` | Update succeeds |
| 2 | DB check: `SELECT COUNT(*) FROM tpt_notification_log WHERE trip_id={tripId} AND notification_type='Cancelled'` | 0 — no notification created |
| 3 | PUT `/trip/{id}` with `status=Ongoing` | Update succeeds |
| 4 | DB check: same query | 0 — no notification |
| 5 | Verify only `$request->status === 'Cancelled'` triggers notification | Line 369 in TripController |

### TC-N16: Cannot Edit or Delete Notification via UI

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Notification Log tab | Grid displays |
| 2 | Inspect each row | No Edit or Delete buttons/links |
| 3 | Inspect blade view for action column | No action column exists (colspan=9 in empty state) |
| 4 | Check routes for notification-log resource | No resource or custom routes |
| 5 | Verify no `Gate::authorize('tenant.notification-log.update')` used anywhere | Permission not checked |

### TC-N17: TransportReportController Notifications Empty State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no trip incidents, boarding logs, or trip activity exist | All sources empty |
| 2 | Navigate to `/transport/reports?tab=notifications` | Report loads |
| 3 | Trigger notifications section (AJAX or direct) | Empty state displayed |
| 4 | Verify "No data available" or equivalent message | Empty state message shown |
| 5 | Verify no PHP errors from empty collections | Graceful degradation |

### TC-N18: TransportReportController delivery_status Filter Never Matches

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to notifications report with data | Notifications display |
| 2 | Apply `delivery_status=Delivered` filter | Filter applied |
| 3 | Code analysis: filter at line 547-552 checks `$notification->overall_status` | NEVER SET by mapping functions |
| 4 | Code analysis: checks `$notification->status_class` | NEVER SET by mapping functions |
| 5 | Expected result with code as-is: Filter produces empty results every time | Bug — delivery_status filter is broken |

### TC-N19: Cross-Tab Search Parameters Affect Notification Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `?tab=notification_log&search=test&shift_id=5&route_id=3` | Tab loads |
| 2 | Check notificationLogQuery — only checks `notification_type` filter | Other params ignored |
| 3 | Verify search/shift/route params don't affect notification query | Query where clause unchanged |
| 4 | Note: unnecessary params stay in URL without effect | Not cleaned from URL |

### TC-N20: sent_time Remains NULL for Manual DB Inserts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manually INSERT into tpt_notification_log without setting sent_time: `INSERT INTO tpt_notification_log (trip_id, notification_type) VALUES (1, 'TripStart')` | Row inserted, sent_time = NULL |
| 2 | Navigate to Notification Log tab | Row displays with '-' in Sent Time column |
| 3 | Verify blade: `$item->sent_time` evaluates to falsy → displays '-' | `$item->sent_time ? date(...) : '-'` outputs '-' |

### TC-D01: Trip Deletion — Notification SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with stopAction notifications | Notifications linked to trip |
| 2 | Note trip_id value | trip_id = X |
| 3 | Force delete trip: `DELETE FROM tpt_trip WHERE id = X` | Trip deleted |
| 4 | Query `SELECT trip_id FROM tpt_notification_log WHERE id = Y` (Y = notification for that trip) | trip_id = NULL (SET NULL applied) |

### TC-D02: Stop (PickupPoint) Deletion — Notification SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify notification with boarding_stop_id set | boarding_stop_id = Z |
| 2 | Delete pickup point: `DELETE FROM tpt_pickup_points WHERE id = Z` | Stop deleted |
| 3 | Query `SELECT boarding_stop_id FROM tpt_notification_log` | boarding_stop_id = NULL |

### TC-D03: Multiple Actions Create Multiple Notifications

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | start_trip on trip X | 1st notification created (TripStart) |
| 2 | reach on trip X | 2nd notification created (ReachedStop/Delayed) |
| 3 | leave on trip X | 3rd notification created (ApproachingStop) |
| 4 | Query `SELECT COUNT(*) FROM tpt_notification_log WHERE trip_id = X` | 3 |
| 5 | Query `SELECT notification_type FROM tpt_notification_log WHERE trip_id = X ORDER BY id` | TripStart, ReachedStop, ApproachingStop |

### TC-D04: Trip Cancelled Creates Notification Without Affecting Existing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create notifications via stop actions | 3 notifications exist |
| 2 | Cancel trip: PUT status=Cancelled | 4th notification created (Cancelled) |
| 3 | Query `SELECT notification_type FROM tpt_notification_log WHERE trip_id = X ORDER BY id` | Original 3 + Cancelled |
| 4 | Verify existing notifications unchanged | sent_time, types preserved |

### TC-D05: Student Session Deletion — Notification SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | NOTE: student_session_id is NEVER populated (TC-CR20) | All records have NULL |
| 2 | In future: if student_session_id is populated and student session is deleted | FK SET NULL sets to NULL |
| 3 | Verify ON DELETE SET NULL is defined in migration | `$table->foreignId('student_session_id')->nullable()->constrained('std_student_academic_sessions')->onDelete('set null')` |

### TC-D06: Trip Deletion Cascades to Notification Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create notifications for trip X | Notifications exist with trip_id = X |
| 2 | Delete trip X | trip_id set to NULL |
| 3 | Navigate to Notification Log tab (if tab works) | Row shows '-' instead of trip reference in Trip column |
| 4 | Blade: `$item->trip?->id ?? '-'` evaluates to '-' because trip() returns null | '-' displayed |

### TC-D07: No Notifications Created for Trips Without Stop Actions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip via TripController@store (no stop actions) | Trip record created |
| 2 | Query: `SELECT COUNT(*) FROM tpt_notification_log WHERE trip_id = X` | 0 — no notifications |
| 3 | Notifications only created by stopAction() and update() | Store() has no notification logic |

### TC-D08: Same Trip Action Twice Creates Two Notifications

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST start_trip for trip X | TripStart notification #1 created |
| 2 | POST start_trip AGAIN for same trip (with same or different stop) | TripStart notification #2 created |
| 3 | Query notifications for trip X | 2 TripStart records |
| 4 | Verify no dedup or upsert logic | Each create() inserts new row |

### TC-D09: TransportReport Tab Filters Share Same Scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to TransportReport notifications | All synthetic data displayed |
| 2 | Apply `notification_type=TripStart` filter | TripStart records from TptTrip shown; IncidentAlert and BoardUnboard hidden |
| 3 | Apply `notification_type=IncidentAlert` filter | Only incident records shown |
| 4 | Verify filter applies across all 3 merged data sources | Filter is PHP-side collection filter |

### TC-D10: Notification Log Independent of Trip Approval Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Approve a trip: POST toggleApproval with status=1 | Trip approved |
| 2 | Query: `SELECT COUNT(*) FROM tpt_notification_log WHERE trip_id = X` | No new notification created for approval |
| 3 | Disapprove trip | No notification created |
| 4 | Verify toggleApproval in TripController | No TptNotificationLog::create() called |

### TC-CR25: Blade View Crashes Before Rendering Due to with()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TripMgmtController@notificationLogQuery() at line 487-498 | `$query = TptNotificationLog::with(['trip', 'boardingStop'])` |
| 2 | Open TptNotificationLog model | No `trip()` or `boardingStop()` method |
| 3 | Load Notification Log tab | **500 Server Error** — `BadMethodCallException: Call to undefined relationship [trip] on model [TptNotificationLog]` |
| 4 | Verify error logged in storage/logs | Laravel log shows exception |
| 5 | This is the PRIMARY blocking bug for the entire feature | ⛔ CRITICAL |

### TC-CR37: Notifications Tab Is NOT Default Tab in TransportReportController

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect TransportReportController@index | `$activeTab = $request->get('tab', 'route-performance')` |
| 2 | Navigate to `/transport/reports` without tab parameter | Route Performance tab loads (default), not Notifications |
| 3 | Navigate to `/transport/reports?tab=notifications` | Notifications tab loads |
| 4 | Verify no redirect/fallback to notifications tab | Explicit tab parameter required |

### TC-CR39: permissionslist.php Defines Only viewAny+view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/permissionslist.php` | Find `'notification-log' => ['viewAny', 'view']` under tenant.transport |
| 2 | Compare with other transport features (e.g., 'vehicle' => $crud) | Full CRUD features have 14+ actions; notification-log has only 2 |
| 3 | Verify no create/update/delete/restore/forceDelete defined | Missing actions confirmed |
| 4 | Note: This is intentional since no CRUD exists for notifications | Permission scope matches implementation scope (read-only) |

---

## 8. Traceability Matrix

| Requirement | TC ID(s) | Code Location | Status |
|-------------|----------|---------------|--------|
| Notification Log tab visible | TC-P01, TC-N05, TC-N06, TC-N07 | TripMgmtController@index:38, tripmanagement.blade.php:23,49 | ⬜ |
| TripStart notification created | TC-P02, TC-D03, TC-D08 | TripController@stopAction:210-216 | ⬜ |
| ReachedStop notification created | TC-P03, TC-N10 | TripController@stopAction:231-237 | ⬜ |
| Delayed notification created | TC-P04, TC-N14 | TripController@stopAction:226-229 | ⬜ |
| ApproachingStop notification created | TC-P05, TC-D03 | TripController@stopAction:246-252 | ⬜ |
| Cancelled notification created | TC-P06, TC-D04 | TripController@update:369-376 | ⬜ |
| Grid shows trip/stop info | TC-P07, TC-D06 | notification-log/index.blade.php:45-46 | ⛔ BLOCKED |
| Filter by notification_type | TC-P08, TC-P15, TC-P19 | notificationLogQuery:492-494, index.blade.php:10-22 | ⬜ |
| Empty state | TC-P09 | index.blade.php:70-72 | ⬜ |
| sent_time displayed | TC-P10, TC-P18, TC-N20 | index.blade.php:47 | ⬜ |
| Channel status display | TC-P12, TC-P13 | index.blade.php:49-66 | ⬜ |
| Pagination (10/page) | TC-P20, TC-N12 | TripMgmtController@index:90 | ⬜ |
| No notification for end_trip | TC-N01 | TripController@stopAction:255-275 | ⬜ |
| No notification for emergency | TC-N02 | TripController@stopAction:277-297 | ⬜ |
| No audit trail (activityLog) | TC-N09, TC-CR18, TC-CR19 | stopAction:210,231,246; update:370 | ⬜ |
| Permission mismatch | TC-N07, TC-N08 | Controller:38 vs Blade:23 | ⬜ |
| CRITICAL: with() crash | TC-CR10, TC-CR14, TC-CR25 | notificationLogQuery:489, Model:1-24 | ⛔ BLOCKING |
| No SoftDeletes trait | TC-CR15 | Model:9-23 | ⬜ |
| No relationships defined | TC-CR09, TC-CR14 | Model:9-23 | ⬜ |
| student_session_id never set | TC-CR20, TC-D05 | stopAction:210,231,246; update:370 | ⬜ |
| Cross-tab pagination | TC-CR30, TC-N12 | index():84-90 | ⬜ |
| All 8 queries always execute | TC-CR31 | index():73-90 | ⬜ |
| Hardcoded delay threshold | TC-CR32, TC-N14 | TripController@stopAction:227 | ⬜ |
| TransportReport synthetic data | TC-P16, TC-CR27, TC-CR28, TC-CR29, TC-N17, TC-N18 | TransportReportController:237-556 | ⬜ |
| Broken delivery_status filter | TC-CR28, TC-N18 | TransportReportController:547-552 | ⬜ |

---

## 9. Risk Assessment

| Risk ID | Description | Severity | Likelihood | Impact | Mitigation |
|---------|-------------|----------|------------|--------|------------|
| RISK-01 | Tab crashes on load (with() on model with no relationships) | **CRITICAL** | 100% | Complete feature unusable — 500 error on tab load | Add `trip()` and `boardingStop()` relationships to model, or remove `with()` from query |
| RISK-02 | Permission mismatch makes notification-log permission unusable | HIGH | 100% | Users with only notification-log permission cannot access | Change controller gate to check `tenant.notification-log.viewAny` for that tab or use `Gate::any()` |
| RISK-03 | No audit trail for notification events | MEDIUM | 100% | Compliance gap — no record of who/when notifications were generated | Add `activityLog()` after each `TptNotificationLog::create()` in TripController |
| RISK-04 | Cross-tab pagination corruption | MEDIUM | 100% | Pagination state leaks between tabs | Assign unique paginator names to each tab's paginate() call |
| RISK-05 | Unbounded table growth (no archival/purge) | MEDIUM | 100% | Performance degradation over time | Implement archival/purge job for records older than X months |
| RISK-06 | TransportReport 'notifications' 'delivery_status' filter broken | MEDIUM | 100% | User sees empty results when filtering by delivery status | Fix synthetic data mapping to include `overall_status` and `status_class` |
| RISK-07 | TransportReport notification_type filter accepts invalid values | LOW | 75% | Silent empty results — no user feedback | Add validation against known ENUM types |
| RISK-08 | No actual notification delivery implemented | LOW | 100% | User-facing 'Sent' status is misleading | Implement push notification/email/SMS/WhatsApp delivery or rename status to 'Logged' |
| RISK-09 | Loads all 8 sub-queries on every tab visit | LOW | 100% | Unnecessary DB load, slower page response | Defer inactive tab queries or use lazy/eager loading per tab |
| RISK-10 | student_session_id never populated | LOW | 100% | FK remains NULL, no per-student notification linking | Add student_session_id resolution in TripController before notification creation |

---

## 10. Gap Analysis Summary

| Gap ID | Description | Type | Priority | Status |
|--------|-------------|------|----------|--------|
| GAP-01 | Model missing `trip()` and `boardingStop()` relationships | Code Bug | P1 | ❌ Open |
| GAP-02 | Query uses `with(['trip','boardingStop'])` but relationships don't exist | Code Bug | P1 | ❌ Open |
| GAP-03 | TripMgmtController uses wrong permission key (`tenant.transport.viewAny`) | Code Bug | P1 | ❌ Open |
| GAP-04 | No `activityLog()` called for any notification creation | Missing Audit | P1 | ❌ Open |
| GAP-05 | No SoftDeletes trait despite DDL having `deleted_at` column | Code Inconsistency | P2 | ❌ Open |
| GAP-06 | No relationships defined despite 3 FK columns | Code Incompleteness | P1 | ❌ Open |
| GAP-07 | `student_session_id` never populated in any controller | Missing Data | P2 | ❌ Open |
| GAP-08 | No CRUD routes/controller — read-only via tab only | Missing Feature | P2 | ❌ Open |
| GAP-09 | No factory class despite `HasFactory` trait | Test Gap | P2 | ❌ Open |
| GAP-10 | Cross-tab pagination conflict (shared `page` name) | Code Bug | P2 | ❌ Open |
| GAP-11 | All 8 sub-queries always execute regardless of active tab | Performance | P3 | ❌ Open |
| GAP-12 | No actual notification delivery — app_status hardcoded 'Sent' | Missing Feature | P1 | ❌ Open |
| GAP-13 | TransportReportController notification data is synthetic, not from TptNotificationLog | Design Inconsistency | P2 | ❌ Open |
| GAP-14 | TransportReport `delivery_status` filter references undefined properties | Code Bug | P2 | ❌ Open |
| GAP-15 | Delay threshold (5 min) hardcoded, not configurable | Missing Config | P3 | ❌ Open |
| GAP-16 | No data retention/archival policy — indefinite table growth | Missing Policy | P3 | ❌ Open |
| GAP-17 | 'ApproachingStop' notification created on 'leave' action (semantic mismatch) | Design Issue | P3 | ❌ Open |
| GAP-18 | `sent_time` not cast as Carbon in model | Code Gap | P3 | ❌ Open |
| GAP-19 | `permissionslist.php` only defines viewAny+view for notification-log | Design Intent | — | ✅ By Design |
| GAP-20 | No edit/delete/restore functionality for notification logs | Design Intent | — | ✅ By Design |

---

## 11. Summary Statistics

| Metric | Count |
|--------|-------|
| Total Positive Test Cases | 20 (TC-P01 to TC-P20) |
| Total Negative Test Cases | 20 (TC-N01 to TC-N20) |
| Total Dependency Test Cases | 10 (TC-D01 to TC-D10) |
| Total Code Review Test Cases | 40 (TC-CR01 to TC-CR40) |
| **Total Test Cases** | **90** |
| Critical Blocking Bugs | 1 (TC-CR14/TC-CR25: with() crash) |
| High Priority Issues | 3 (TC-CR26: permission mismatch, TC-CR31: all queries execute, TC-CR39: permission scope) |
| Medium Priority Issues | 7 |
| Low Priority Issues | 5 |
| Database Columns | 13 |
| ENUM Values | 5 notification types, 3 statuses per channel |
| Code Locations Creating Notifications | 4 (3 in stopAction + 1 in update) |
| Unique BG/BIZ IDs | 12 (BC-DB-01 to BC-DB-13, BC-BIZ-01 to BC-BIZ-12, BC-MOD-01 to BC-MOD-10) |
| Unique BC-BIZ-DEEP Subsections | 9 (5.4.1 through 5.4.9) |
| Unique CODE-TRACE Subsections | 9 (5.5.1 through 5.5.9) |

---

## 12. End-to-End Scenario Test Steps

### SCENARIO 1: Full Trip Lifecycle with Notification Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a route with 3 pickup points (ordinal 1, 2, 3) each with arrival/departure times | Route + stops configured |
| 2 | Create a route scheduler for today with that route | Scheduler active |
| 3 | Create a trip via TripController@store | Trip record created, status='Scheduled' |
| 4 | Navigate to Trip Management → Notification Log tab | Tab loads (verify relationships exist first — see GAP-01) |
| 5 | Verify 0 notifications for this trip | `SELECT COUNT(*) FROM tpt_notification_log WHERE trip_id = X` = 0 |
| 6 | POST stopAction start_trip on stop ordinal 1 | Action succeeds |
| 7 | Query notifications: `SELECT notification_type FROM tpt_notification_log WHERE trip_id = X` | 'TripStart' |
| 8 | POST stopAction reach on stop ordinal 1 (on time) | Action succeeds |
| 9 | Query latest notification | 'ReachedStop' |
| 10 | POST stopAction leave on stop ordinal 1 | Action succeeds |
| 11 | Query latest notification | 'ApproachingStop' |
| 12 | POST stopAction reach on stop ordinal 2 (delayed — sch_arrival was 6 min ago) | Action succeeds |
| 13 | Query latest notification | 'Delayed' |
| 14 | POST stopAction end_trip on stop ordinal 3 (last stop) | Trip status = 'Completed' |
| 15 | Verify NO notification created for end_trip | Query returns same count as after step 13 |
| 16 | Total notifications for this trip | 4 (TripStart, ReachedStop, ApproachingStop, Delayed) |
| 17 | Navigate to Notification Log tab | All 4 records visible (if tab works) |
| 18 | Filter by 'Delayed' | Only 1 record shown |

### SCENARIO 2: Trip Cancellation Mid-Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with 2 stops | Trip exists |
| 2 | start_trip on stop 1 | TripStart notification created |
| 3 | reach on stop 1 (on time) | ReachedStop notification created |
| 4 | leave on stop 1 | ApproachingStop notification created |
| 5 | PUT `/trip/{id}` with `status=Cancelled` | Trip status changed to Cancelled |
| 6 | Query notifications | 4 records: TripStart, ReachedStop, ApproachingStop, Cancelled |
| 7 | Verify `boarding_stop_id` is NULL for Cancelled notification | Only Cancelled has NULL boarding_stop_id |
| 8 | Verify trip's `stopAction` can no longer be called for this trip | Trip is cancelled, stops are final |

### SCENARIO 3: Emergency Stop (No Notification Created)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with 1 stop | Trip exists |
| 2 | start_trip on stop | TripStart created |
| 3 | reach on stop | ReachedStop created |
| 4 | POST emergency on stop with remark "Student feeling unwell" | Emergency flag set |
| 5 | Query notifications count | 2 — same as after step 3 |
| 6 | Query TptTripIncidents | 1 incident record created |
| 7 | Verify no TptNotificationLog for 'Emergency' or 'SafetyAlert' | No such ENUM value exists |

### SCENARIO 4: Permission Boundary Testing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with ONLY `tenant.transport.viewAny` (not notification-log.viewAny) | Authenticated |
| 2 | Navigate to Trip Management | Page loads (transport.viewAny passes) |
| 3 | Verify Notification Log tab button is hidden | Tab absent from nav |
| 4 | Attempt URL: `/transport/trip-management?tab=notification_log` | 403 from controller OR tab hidden at blade level |
| 5 | Attempt direct access to notification log data (API) | No dedicated API exists |
| 6 | Login as user with ONLY `tenant.notification-log.viewAny` (not transport.viewAny) | Authenticated |
| 7 | Attempt to access `/transport/trip-management?tab=notification_log` | **403 Forbidden** — controller gate blocks |
| 8 | Verify user cannot bypass by using different URL pattern | No alternative route exists |

### SCENARIO 5: TransportReport Synthetic Notification vs Real Notification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a trip with incidents, boarding logs, and stop actions | Both real TptNotificationLog and source data exist |
| 2 | Navigate to Transport Reports → Notifications tab | Synthetic report loads |
| 3 | Count 'TripStart' records in synthetic report | Count matches trips with start_time (not notifications) |
| 4 | Compare: `SELECT COUNT(*) FROM tpt_notification_log WHERE notification_type='TripStart'` | Count differs from synthetic count |
| 5 | Verify synthetic 'IncidentAlert' type exists | Shows trip incidents |
| 6 | Verify synthetic 'BoardUnboard' type exists | Shows boarding events |
| 7 | Verify 'Delayed' type does NOT appear in TransportReport | Not in TransportReportController mapping |
| 8 | Verify 'Cancelled' type does NOT appear in TransportReport | Not in TransportReportController mapping |
| 9 | Note: Two parallel notification systems produce different counts for same trip | Data inconsistency between reports |

### SCENARIO 6: Pagination Boundary Testing Across Tabs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 25 notifications and 30 trips | Records for both tabs |
| 2 | Navigate to Notification Log tab | Page 1: records 1-10 |
| 3 | Click page 2 → URL: `?tab=notification_log&page=2` | Notifications 11-20 |
| 4 | Without changing page parameter, click 'Daily Trip' tab | Daily trip loads with page=2 still in URL |
| 5 | Daily Trip shows records 21-30 (page 2 of trips) | **This is incorrect** if trips have different total |
| 6 | Expected behavior: each tab should reset/remember its own page | Cross-tab contamination confirmed |
| 7 | Fix: Assign unique pageName to each paginate() call | See GAP-10 |

### SCENARIO 7: Data Retention / Long-Running System

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate 6 months of daily operations with average 10 trips/day × 3 stops/trip | ~5,400 notifications created (10 trips × 3 stops × 30 days × 6 months) |
| 2 | Query `SELECT COUNT(*) FROM tpt_notification_log` | ~5,400 records |
| 3 | Navigate to Notification Log tab | Slow page load due to table size |
| 4 | Query `SELECT TABLE_ROWS FROM information_schema.TABLES WHERE TABLE_NAME='tpt_notification_log'` | No index optimization beyond PK |
| 5 | Check for archival job | None exists |
| 6 | Risk: Table grows unbounded — no purge mechanism | Performance degrades over time |

### SCENARIO 8: Concurrency — Multiple Drivers Actioning Same Trip Simultaneously

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trip exists with 3 stops | Trip ready |
| 2 | Send 3 simultaneous POST requests: start_trip, reach, leave for different stops | All 3 requests processed |
| 3 | Query notifications for trip | 3 notification records (may vary depending on timing of reach) |
| 4 | Verify no race condition duplicates | Each create() is atomic |
| 5 | Verify no deadlock or transaction conflict | Each request runs independently (no DB transaction wrapping stopAction) |
| 6 | Note: stopAction does NOT use DB::transaction() | Each create is individually committed |

---

## 13. Appendix A: ENUM Values Reference

### notification_type ENUM

| ENUM Value | Created By | TripController Location | Stop Action | Notes |
|-----------|-----------|----------------------|-------------|-------|
| `TripStart` | stopAction('start_trip') | Line 210 | start_trip | First stop reached and left |
| `ApproachingStop` | stopAction('leave') | Line 246 | leave | Driver leaving stop, approaching next |
| `ReachedStop` | stopAction('reach') | Line 231 (default) | reach | On-time arrival |
| `Delayed` | stopAction('reach') | Line 231 (conditional) | reach | Arrival >5min after sch_arrival |
| `Cancelled` | update(status='Cancelled') | Line 370 | N/A | Trip cancelled entirely |

### Channel Status ENUM (per channel)

| Value | Meaning | Blade Display | Badge Color |
|-------|---------|---------------|-------------|
| `NULL` | Not configured / no attempt | `-` | secondary |
| `NotRegistered` | Channel not registered for user | `NotRegistered` | secondary |
| `Sent` | Notification sent (or marked as sent) | `Sent` | success |
| `Failed` | Delivery failed | `Failed` | danger |

---

## 14. Appendix B: Blade View Column ↔ Model Attribute Mapping

| Column | Blade Code | Model Attribute | Expected Data Source |
|--------|-----------|-----------------|---------------------|
| # | `{{ $item->id }}` | `id` | Auto-increment PK |
| Type | `{{ $item->notification_type }}` | `notification_type` | ENUM value |
| Trip | `{{ $item->trip?->id ?? '-' }}` | `trip_id` (FK) | `trip()` relationship (NEEDS FIX — see GAP-01) |
| Stop | `{{ $item->boardingStop?->name ?? '-' }}` | `boarding_stop_id` (FK) | `boardingStop()` relationship (NEEDS FIX — see GAP-01) |
| Sent Time | `{{ $item->sent_time ? date(...) : '-' }}` | `sent_time` | DATETIME from TripController |
| App | `{{ $item->app_notification_status ?? '-' }}` | `app_notification_status` | Always 'Sent' |
| SMS | `{{ $item->sms_notification_status ?? '-' }}` | `sms_notification_status` | Always NULL |
| Email | `{{ $item->email_notification_status ?? '-' }}` | `email_notification_status` | Always NULL |
| WhatsApp | `{{ $item->whatsapp_notification_status ?? '-' }}` | `whatsapp_notification_status` | Always NULL |

---

## 15. Appendix C: Recommendation for Immediate Fixes

| Order | Fix | File(s) | Effort | Impact |
|-------|-----|---------|--------|--------|
| 1 | Add `trip()` and `boardingStop()` relationships to TptNotificationLog model | `Modules/Transport/Models/TptNotificationLog.php` | 5 min | **CRITICAL** — unblocks entire feature |
| 2 | Fix `notificationLogQuery()` — ensure query matches model capabilities | `TripMgmtController.php:489` | 2 min | **CRITICAL** — prevents 500 error |
| 3 | Fix permission gate in `index()` to use `Gate::any()` or tab-aware check | `TripMgmtController.php:38` | 15 min | HIGH — unblocks dedicated permission |
| 4 | Add `activityLog()` after each `TptNotificationLog::create()` call | `TripController.php:210,231,246,370` | 10 min | HIGH — enables audit trail |
| 5 | Assign unique paginator names to each tab's paginate() call | `TripMgmtController.php:84-90` | 10 min | MEDIUM — fixes cross-tab pagination |
| 6 | Add model `$casts` for `sent_time` as `datetime` | `TptNotificationLog.php` | 2 min | LOW — improves type handling |
| 7 | Add SoftDeletes trait to model | `TptNotificationLog.php` | 2 min | LOW — aligns DDL with code |
| 8 | Fix TransportReport `delivery_status` filter to handle undefined properties | `TransportReportController.php:547-552` | 10 min | MEDIUM — fixes report filter |

(End of file)
