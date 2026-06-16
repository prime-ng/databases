# VSM — Visitor & Security Management Complete Development Plan
**Module:** VisitorSecurity | **Version:** v2 | **Generated:** 2026-03-27
**Based on:** VSM_VisitorSecurity_Requirement.md v2 + VSM_FeatureSpec.md

---

## Section 1 — Controller Inventory

All web controllers: `Modules\VisitorSecurity\app\Http\Controllers\`
All API controllers: `Modules\VisitorSecurity\app\Http\Controllers\Api\`
Middleware on all web routes: `['auth', 'tenant', 'EnsureTenantHasModule:VisitorSecurity']`
Middleware on API routes: `['auth:sanctum', 'tenant']` (except cctvEvent — no auth)

---

### 1. VisitorSecurityController
**File:** `app/Http/Controllers/VisitorSecurityController.php`
**FR Coverage:** FR-VSM-05

| Method | HTTP | URI | Route Name | Permission |
|---|---|---|---|---|
| `dashboard` | GET | `/visitor-security/dashboard` | `vsm.dashboard` | vsm-visitor.view |

---

### 2. VisitorController
**File:** `app/Http/Controllers/VisitorController.php`
**FR Coverage:** FR-VSM-01, FR-VSM-02, FR-VSM-07, FR-VSM-09, FR-VSM-12

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `/visitor-security/visitors` | `vsm.visitors.index` | — | vsm-visitor.view |
| `create` | GET | `/visitor-security/visitors/create` | `vsm.visitors.create` | — | vsm-visitor.create |
| `store` | POST | `/visitor-security/visitors` | `vsm.visitors.store` | `StoreVisitorRequest` | vsm-visitor.create |
| `show` | GET | `/visitor-security/visitors/{visitor}` | `vsm.visitors.show` | — | vsm-visitor.view |
| `edit` | GET | `/visitor-security/visitors/{visitor}/edit` | `vsm.visitors.edit` | — | vsm-visitor.update |
| `update` | PUT | `/visitor-security/visitors/{visitor}` | `vsm.visitors.update` | `StoreVisitorRequest` | vsm-visitor.update |
| `destroy` | DELETE | `/visitor-security/visitors/{visitor}` | `vsm.visitors.destroy` | — | vsm-visitor.delete |
| `preRegister` | GET | `/visitor-security/visitors/pre-register` | `vsm.visitors.pre-register` | — | vsm-visitor.pre-register |
| `storePreRegister` | POST | `/visitor-security/visitors/pre-register` | `vsm.visitors.pre-register.store` | `PreRegisterVisitRequest` | vsm-visitor.pre-register |
| `sendQr` | POST | `/visitor-security/visitors/{visitor}/send-qr` | `vsm.visitors.send-qr` | — | vsm-visitor.create |
| `pickupIndex` | GET | `/visitor-security/pickup-auth` | `vsm.pickup-auth.index` | — | vsm-visitor.view |
| `processPickup` | POST | `/visitor-security/pickup-auth` | `vsm.pickup-auth.store` | `ProcessPickupRequest` | vsm-visitor.create |
| `blacklistIndex` | GET | `/visitor-security/blacklist` | `vsm.blacklist.index` | — | vsm-blacklist.manage |
| `blacklistStore` | POST | `/visitor-security/blacklist` | `vsm.blacklist.store` | `StoreBlacklistRequest` | vsm-blacklist.manage |
| `blacklistDestroy` | DELETE | `/visitor-security/blacklist/{entry}` | `vsm.blacklist.destroy` | — | vsm-blacklist.manage |

**Policies:** `VisitorPolicy` (index/show/create/update/delete/pre-register), `BlacklistPolicy` (manage)

---

### 3. VisitController
**File:** `app/Http/Controllers/VisitController.php`
**FR Coverage:** FR-VSM-03, FR-VSM-04

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `/visitor-security/visits` | `vsm.visits.index` | — | vsm-visit.view |
| `today` | GET | `/visitor-security/visits/today` | `vsm.visits.today` | — | vsm-visit.view |
| `show` | GET | `/visitor-security/visits/{visit}` | `vsm.visits.show` | — | vsm-visit.view |
| `checkin` | GET | `/visitor-security/gate/checkin` | `vsm.gate.checkin` | — | vsm-visit.checkin |
| `processCheckin` | POST | `/visitor-security/gate/checkin` | `vsm.gate.checkin.process` | `ProcessCheckinRequest` | vsm-visit.checkin |
| `checkout` | GET | `/visitor-security/gate/checkout` | `vsm.gate.checkout` | — | vsm-visit.checkout |
| `processCheckout` | POST | `/visitor-security/gate/checkout` | `vsm.gate.checkout.process` | `ProcessCheckoutRequest` | vsm-visit.checkout |

**Policy:** `VisitPolicy` (view, checkin, checkout)

---

### 4. GatePassController
**File:** `app/Http/Controllers/GatePassController.php`
**FR Coverage:** FR-VSM-03

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `badge` | GET | `/visitor-security/gate-passes/{pass}/badge` | `vsm.gate-passes.badge` | — | vsm-visit.checkin |
| `revoke` | POST | `/visitor-security/gate-passes/{pass}/revoke` | `vsm.gate-passes.revoke` | — | vsm-visitor.update |
| `scan` | GET | `/visitor-security/gate-passes/{pass_token}/scan` | `vsm.gate-passes.scan` | — | **PUBLIC — no auth** |

**Policy:** `GatePassPolicy` (badge, revoke)
**Note:** `badge` method generates DomPDF PDF and auto-triggers `window.print()` via JS. `scan` is unauthenticated public route — QR URL in SMS.

---

### 5. ContractorController
**File:** `app/Http/Controllers/ContractorController.php`
**FR Coverage:** FR-VSM-08

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `/visitor-security/contractors` | `vsm.contractors.index` | — | vsm-contractor.view |
| `create` | GET | `/visitor-security/contractors/create` | `vsm.contractors.create` | — | vsm-contractor.manage |
| `store` | POST | `/visitor-security/contractors` | `vsm.contractors.store` | `StoreContractorRequest` | vsm-contractor.manage |
| `show` | GET | `/visitor-security/contractors/{contractor}` | `vsm.contractors.show` | — | vsm-contractor.view |
| `update` | PUT | `/visitor-security/contractors/{contractor}` | `vsm.contractors.update` | `StoreContractorRequest` | vsm-contractor.manage |
| `revoke` | POST | `/visitor-security/contractors/{contractor}/revoke` | `vsm.contractors.revoke` | — | vsm-contractor.manage |

**Policy:** `ContractorPolicy` (view, manage, revoke)

---

### 6. GuardShiftController
**File:** `app/Http/Controllers/GuardShiftController.php`
**FR Coverage:** FR-VSM-10

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `/visitor-security/guard-shifts` | `vsm.guard-shifts.index` | — | vsm-guard-shift.manage |
| `create` | GET | `/visitor-security/guard-shifts/create` | `vsm.guard-shifts.create` | — | vsm-guard-shift.manage |
| `store` | POST | `/visitor-security/guard-shifts` | `vsm.guard-shifts.store` | `StoreGuardShiftRequest` | vsm-guard-shift.manage |
| `update` | PUT | `/visitor-security/guard-shifts/{shift}` | `vsm.guard-shifts.update` | `StoreGuardShiftRequest` | vsm-guard-shift.manage |
| `clockIn` | POST | `/visitor-security/guard-shifts/{shift}/clock-in` | `vsm.guard-shifts.clock-in` | — | vsm-guard-shift.self |
| `clockOut` | POST | `/visitor-security/guard-shifts/{shift}/clock-out` | `vsm.guard-shifts.clock-out` | — | vsm-guard-shift.self |

**Policy:** `GuardShiftPolicy` (manage for admin; self for guard clock-in/out)
**Note:** `clockIn` auto-sets attendance_status=Late if actual_start > shift_start+15min (BR-VSM-007).

---

### 7. PatrolController
**File:** `app/Http/Controllers/PatrolController.php`
**FR Coverage:** FR-VSM-11

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `/visitor-security/patrol-rounds` | `vsm.patrol.index` | — | vsm-patrol.manage |
| `store` | POST | `/visitor-security/patrol-rounds` | `vsm.patrol.store` | — | vsm-patrol.manage |
| `show` | GET | `/visitor-security/patrol-rounds/{round}` | `vsm.patrol.show` | — | vsm-patrol.manage |
| `scanCheckpoint` | POST | `/visitor-security/patrol-rounds/{round}/scan` | `vsm.patrol.scan` | — | vsm-patrol.manage |
| `complete` | POST | `/visitor-security/patrol-rounds/{round}/complete` | `vsm.patrol.complete` | — | vsm-patrol.manage |
| `checkpoints` | GET | `/visitor-security/patrol-checkpoints` | `vsm.patrol.checkpoints` | — | vsm-patrol.manage |
| `storeCheckpoint` | POST | `/visitor-security/patrol-checkpoints` | `vsm.patrol.checkpoints.store` | `StorePatrolCheckpointRequest` | vsm-patrol.manage |

**Policy:** `PatrolPolicy` (manage — Admin + Guard)

---

### 8. EmergencyController
**File:** `app/Http/Controllers/EmergencyController.php`
**FR Coverage:** FR-VSM-06

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index` | GET | `/visitor-security/emergency` | `vsm.emergency.index` | — | vsm-emergency.view |
| `broadcastForm` | GET | `/visitor-security/emergency/broadcast` | `vsm.emergency.broadcast` | — | vsm-emergency.broadcast |
| `broadcast` | POST | `/visitor-security/emergency/broadcast` | `vsm.emergency.broadcast.store` | `BroadcastEmergencyRequest` | vsm-emergency.broadcast |
| `resolve` | POST | `/visitor-security/emergency/{event}/resolve` | `vsm.emergency.resolve` | — | vsm-emergency.broadcast |
| `protocols` | GET | `/visitor-security/emergency/protocols` | `vsm.emergency.protocols` | — | vsm-emergency.view |
| `storeProtocol` | POST | `/visitor-security/emergency/protocols` | `vsm.emergency.protocols.store` | — | vsm-emergency.broadcast |

**Policy:** `EmergencyPolicy` (view, broadcast, resolve)

---

### 9. ReportController
**File:** `app/Http/Controllers/ReportController.php`
**FR Coverage:** FR-VSM-14

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `visitorLog` | GET | `/visitor-security/reports/visitor-log` | `vsm.reports.visitor-log` | — | vsm-report.view |
| `frequentVisitors` | GET | `/visitor-security/reports/frequent-visitors` | `vsm.reports.frequent-visitors` | — | vsm-report.view |
| `guardAttendance` | GET | `/visitor-security/reports/guard-attendance` | `vsm.reports.guard-attendance` | — | vsm-report.view |

**Note:** Each method supports `?format=pdf|csv` query param; PDF via DomPDF (`barryvdh/laravel-dompdf`), CSV via `fputcsv()` to `php://temp`.

---

### 10. Api\VsmApiController
**File:** `app/Http/Controllers/Api/VsmApiController.php`
**FR Coverage:** FR-VSM-03, FR-VSM-04, FR-VSM-05, FR-VSM-08, FR-VSM-11, FR-VSM-13

| Method | HTTP | URI | Route Name | Auth | Description |
|---|---|---|---|---|---|
| `checkin` | POST | `/api/v1/vsm/checkin` | `vsm.api.checkin` | sanctum+tenant | QR scan check-in from kiosk/tablet |
| `checkout` | POST | `/api/v1/vsm/checkout` | `vsm.api.checkout` | sanctum+tenant | QR scan check-out |
| `dashboard` | GET | `/api/v1/vsm/dashboard` | `vsm.api.dashboard` | sanctum+tenant | Live campus stats JSON for kiosk |
| `patrolScan` | POST | `/api/v1/vsm/patrol/scan` | `vsm.api.patrol.scan` | sanctum+tenant | Guard mobile checkpoint QR scan |
| `searchVisitor` | GET | `/api/v1/vsm/visitors/search` | `vsm.api.visitors.search` | sanctum+tenant | Typeahead by mobile/name |
| `validatePass` | GET | `/api/v1/vsm/gate-passes/{token}/validate` | `vsm.api.gate-passes.validate` | sanctum+tenant | Validate pass token; return details or error |
| `contractorCheckin` | POST | `/api/v1/vsm/contractors/checkin` | `vsm.api.contractors.checkin` | sanctum+tenant | Contractor QR scan at gate |
| `emergencyBroadcast` | POST | `/api/v1/vsm/emergency/broadcast` | `vsm.api.emergency.broadcast` | sanctum+tenant | Emergency alert from mobile app |
| `activeVisits` | GET | `/api/v1/vsm/active-visits` | `vsm.api.active-visits` | sanctum+tenant | Current on-campus visitors |
| `cctvEvent` | POST | `/api/v1/vsm/cctv/event` | `vsm.api.cctv.event` | **NONE** | CCTV webhook; validate X-CCTV-Secret header |
| `todayShifts` | GET | `/api/v1/vsm/guard-shifts/today` | `vsm.api.guard-shifts.today` | sanctum+tenant | Guard's today shifts |
| `guardClock` | POST | `/api/v1/vsm/guard-shifts/{shift}/clock` | `vsm.api.guard-shifts.clock` | sanctum+tenant | Guard clock-in/out from mobile |

**Response format:** `{ "success": true, "data": {...} }` or `{ "success": false, "message": "..." }`
**cctvEvent note:** `->withoutMiddleware(['auth:sanctum', 'tenant'])` + custom X-CCTV-Secret header validation.

---

## Section 2 — Service Inventory (4 Services)

---

### VisitorService
```
Class:      VisitorService
File:       Modules/VisitorSecurity/app/Services/VisitorService.php
Namespace:  Modules\VisitorSecurity\app\Services
Depends on: SecurityAlertService (lockdown check), NTF module (notifications), sys_media (photo storage)
Fires:      NTF host arrival alert, NTF QR dispatch (SMS+email), sys_activity_logs write

Methods:
  registerWalkIn(StoreVisitorRequest $request): array
    → Blacklist check → upsert vsm_visitors(mobile_no) → create vsm_visits(Registered)
    → generateGatePass() → notify host in-app; returns [visitor, visit, gate_pass]

  preRegister(PreRegisterVisitRequest $request): array
    → Blacklist check → upsert vsm_visitors → create vsm_visits(Pre_Registered)
    → generateGatePass() → sendQrToVisitor(); returns [visitor, visit, gate_pass]

  processCheckin(ProcessCheckinRequest $request): VsmVisit
    [FULL PSEUDOCODE — see below]

  processCheckout(ProcessCheckoutRequest $request): VsmVisit
    → Verify status=Checked_In; set checkout_time=NOW()
    → Compute duration_minutes = TIMESTAMPDIFF(MINUTE, checkin_time, checkout_time)
    → Set is_overdue=false (clear overdue flag); write audit log

  generateGatePass(VsmVisit $visit): VsmGatePass
    → pass_token = Str::uuid() (UUID v4 — never sequential)
    → expires_at = min(Carbon::parse($visit->expected_date)->endOfDay(), now()->addHours(24))
    → SimpleSoftwareIO QR generation; store qr_code_path

  checkBlacklist(string $mobileNo, ?string $idNumber): ?VsmBlacklist
    → WHERE is_active=1 AND (mobile_no=$mobileNo OR id_number=$idNumber)
    → AND (valid_until IS NULL OR valid_until >= TODAY())

  sendQrToVisitor(VsmGatePass $pass, string $mobile, ?string $email): void
    → Dispatch via NTF module: SMS + email
    → URL embedded: /visitor-security/gate-passes/{pass_token}/scan

  processPickupAuthorisation(ProcessPickupRequest $request): VsmPickupAuth
    → Look up std_student_guardian_jnt WHERE student_id AND guardian.mobile_no=guardian_mobile AND can_pickup=1
    → If match: is_authorised=1
    → If no match: require override_by + override_reason (BR-VSM-011); alert supervisor
```

**processCheckin pseudocode (12 steps):**
```
processCheckin(ProcessCheckinRequest $request): VsmVisit
  Step 1:  Resolve pass_token → vsm_gate_passes (UNIQUE index lookup)
           Verify status=Issued; expires_at > NOW() (server-side — BR-VSM-002)
  Step 2:  Load vsm_visits via gate_pass.visit_id
           Verify visit.status NOT already Checked_In (BR-VSM-003)
           If already Checked_In: require supervisor_override=true + reason in request
  Step 3:  Blacklist re-check at gate — belt-and-suspenders (BR-VSM-001)
           If match: log alert to security desk; proceed only with admin override
  Step 4:  SecurityAlertService::isLockdownActive() (BR-VSM-010)
           If true: return 403 "Campus is in lockdown"
  Step 5:  DB::transaction() begins
  Step 6:  vsm_visits: checkin_time=NOW(), status=Checked_In
  Step 7:  vsm_gate_passes: status=Used, used_at=NOW()
           lockForUpdate() on gate pass to prevent duplicate-scan race
  Step 8:  vsm_visitors: DB::increment('visit_count') (BR-VSM-013)
  Step 9:  If gate photo provided: upload to sys_media
           model_type='vsm_visitors', collection='checkin_photos'
           Set vsm_visits.checkin_photo_media_id
  Step 10: DB::transaction() commits
  Step 11: Dispatch host notification via NTF module (in-app + SMS if staff mobile set — BR-VSM-008)
  Step 12: Write to sys_activity_logs (BR-VSM-015)
  Return:  Updated vsm_visits record with gate_pass and visitor relationships
```

---

### SecurityAlertService
```
Class:      SecurityAlertService
File:       Modules/VisitorSecurity/app/Services/SecurityAlertService.php
Namespace:  Modules\VisitorSecurity\app\Services
Depends on: NTF module (emergency broadcast), ATT module (headcount query)
Fires:      EmergencyBroadcastJob on dedicated 'emergency' queue (3 retries; bypasses rate limiting)

Methods:
  broadcastEmergency(BroadcastEmergencyRequest $request): VsmEmergencyEvent
    [FULL PSEUDOCODE — see below]

  resolveEmergency(VsmEmergencyEvent $event): void
    → Set resolved_at=NOW(); is_lockdown_active=false
    → Dispatch NTF to all active sys_users: "Emergency resolved"
    → Write sys_activity_logs

  flagOverdueVisitors(): int
    → school_timezone = sys_settings where key='timezone'
    → Carbon::setTimezone(school_timezone) (BR-VSM timezone rule)
    → UPDATE vsm_visits SET is_overdue=1
      WHERE status='Checked_In'
      AND TIMESTAMPADD(MINUTE, expected_duration_minutes, checkin_time) < NOW()
      AND is_overdue=0
    → Dispatch in-app alert to security desk (vsm-visit.checkin role users)
    → Return count of newly flagged visits

  isLockdownActive(): bool
    → EXISTS vsm_emergency_events WHERE is_lockdown_active=1 AND resolved_at IS NULL
    → Called by VisitorService before every gate pass generation
```

**broadcastEmergency pseudocode (5 steps):**
```
broadcastEmergency(BroadcastEmergencyRequest $request): VsmEmergencyEvent
  Step 1: Create vsm_emergency_events record
          Set triggered_at=NOW(); triggered_by=Auth::id()
  Step 2: If emergency_type=Lockdown: is_lockdown_active=true (BR-VSM-010)
  Step 3: Dispatch EmergencyBroadcastJob(
            queue: 'emergency',       ← dedicated channel; bypasses rate limiting
            tries: 3,
            timeout: 120
          )
          Job logic:
            → Query ALL active sys_users (user_type IN [Staff, Teacher, Admin])
            → For each user: dispatch NTF (SMS + in-app push) via Notification module
            → Update vsm_emergency_events.notification_count = count of dispatched
  Step 4: headcount_initiated = true
          → Query ATT module: today's present students per section
          → Dispatch per-section in-app task to class teacher:
            "EMERGENCY: Please confirm headcount for [Section]"
  Step 5: Write to sys_activity_logs (BR-VSM-015)
  Return: vsm_emergency_events record
```

---

### PatrolService
```
Class:      PatrolService
File:       Modules/VisitorSecurity/app/Services/PatrolService.php
Namespace:  Modules\VisitorSecurity\app\Services
Depends on: —
Fires:      Admin in-app alert when round is Incomplete

Methods:
  startRound(int $guardUserId, ?int $shiftId): VsmPatrolRound
    → Count active checkpoints → set checkpoints_total
    → Create vsm_patrol_rounds(status=In_Progress, patrol_start_time=NOW())

  scanCheckpoint(VsmPatrolRound $round, string $qrToken): VsmPatrolCheckpointLog
    → Resolve qr_token → vsm_patrol_checkpoints (UNIQUE lookup)
    → Verify round.status=In_Progress
    → Create VsmPatrolCheckpointLog(scanned_at=NOW())
    → Increment round.checkpoints_completed
    → Recompute completion_pct = (completed/total) × 100
    → If all total checkpoints scanned: auto-call completeRound()

  completeRound(VsmPatrolRound $round): VsmPatrolRound
    → completion_pct = (checkpoints_completed / checkpoints_total) × 100
    → If completion_pct < 80.00: status=Incomplete; alert admin (BR-VSM-006)
    → Else: status=Completed
    → Set patrol_end_time=NOW()

  generateCheckpointQr(VsmPatrolCheckpoint $checkpoint): string
    → SimpleSoftwareIO QR for qr_token value
    → Store generated image; update qr_code_path
    → Return image URL for printing
```

---

### ContractorAccessService
```
Class:      ContractorAccessService
File:       Modules/VisitorSecurity/app/Services/ContractorAccessService.php
Namespace:  Modules\VisitorSecurity\app\Services
Depends on: VisitorService (blacklist check)
Fires:      Admin in-app notification on registration and each entry

Methods:
  register(StoreContractorRequest $request): VsmContractor
    → Blacklist check: mobile_no against vsm_blacklist
    → Create vsm_contractors record
    → pass_token = Str::uuid() (UUID v4; reusable within date range)
    → Notify admin of new contractor registration

  validateEntry(string $passToken): array
    → Find by pass_token (UNIQUE index)
    → Check pass_status=Active
    → Validate: access_from <= today <= access_until (BR-VSM-012)
    → Validate: day_of_week(Carbon::today()->format('D')) in entry_days_json (BR-VSM-012)
    → DB::increment('entry_count')
    → Returns: ['contractor' => $contractor, 'status' => 'valid|expired|day_blocked|revoked', 'message' => '...']

  revokeAccess(VsmContractor $contractor): void
    → Set pass_status=Revoked; notify admin

  expireOldContracts(): int
    → UPDATE vsm_contractors SET pass_status='Expired'
      WHERE access_until < DATE(NOW()) AND pass_status='Active'
    → Return count of expired contracts
```

---

## Section 3 — FormRequest Inventory (10 FormRequests)

**Namespace:** `Modules\VisitorSecurity\app\Http\Requests\`

| # | Class | Controller@Method | Key Validation Rules |
|---|---|---|---|
| 1 | `StoreVisitorRequest` | VisitorController@store / update | `name: required, max:150` \| `mobile_no: required, digits_between:10,15` \| `id_type: nullable, in:Aadhar,DrivingLicense,Passport,VoterID,Other` \| `photo: nullable, image, max:2048` |
| 2 | `PreRegisterVisitRequest` | VisitorController@storePreRegister | `visitor_name: required, max:150` \| `visitor_mobile: required, digits_between:10,15` \| `purpose: required, in:PTM,Admission,Meeting,Delivery,Maintenance,Interview,StudentPickup,Contractor,Other` \| `host_staff_id: required, exists:sys_users,id` \| `expected_date: required, date, after_or_equal:today` \| `expected_time: nullable, date_format:H:i` \| `expected_duration_minutes: nullable, integer, min:15, max:480` |
| 3 | `ProcessCheckinRequest` | VisitController@processCheckin | `pass_token: required_without:visit_id, max:100` \| `visit_id: required_without:pass_token, exists:vsm_visits,id` \| `checkin_photo: nullable, image, max:2048` |
| 4 | `ProcessCheckoutRequest` | VisitController@processCheckout | `visit_id: required, exists:vsm_visits,id` (service validates status=Checked_In) |
| 5 | `StoreGuardShiftRequest` | GuardShiftController@store / update | `guard_user_id: required, exists:sys_users,id` \| `shift_date: required, date` \| `shift_start_time: required, date_format:H:i` \| `shift_end_time: required, date_format:H:i, after:shift_start_time` \| `post: required, max:100` |
| 6 | `BroadcastEmergencyRequest` | EmergencyController@broadcast | `emergency_type: required, in:Lockdown,Fire,Earthquake,MedicalEmergency,Evacuation,Other` \| `message: required, max:500` \| `affected_zones: nullable, max:500` |
| 7 | `StoreBlacklistRequest` | VisitorController@blacklistStore | `name: required, max:150` \| `reason: required, max:1000` \| `mobile_no: nullable, digits_between:10,15` \| `id_number: nullable, max:50` \| `valid_until: nullable, date, after_or_equal:today` \| **Custom rule:** at least one of `mobile_no` or `id_number` required |
| 8 | `StoreContractorRequest` | ContractorController@store / update | `contractor_name: required, max:150` \| `mobile_no: required, digits_between:10,15` \| `access_from: required, date, after_or_equal:today` \| `access_until: required, date, after_or_equal:access_from` \| `allowed_zones_json: nullable, json` \| `entry_days_json: nullable, json` \| `id_proof: nullable, image, max:2048` |
| 9 | `ProcessPickupRequest` | VisitorController@processPickup | `student_id: required, exists:std_students,id` \| `guardian_name: required, max:150` \| `guardian_mobile: required, digits_between:10,15` \| `relationship: nullable, max:50` \| `id_proof: nullable, image, max:2048` |
| 10 | `StorePatrolCheckpointRequest` | PatrolController@storeCheckpoint | `name: required, max:100` \| `location_description: nullable, max:500` \| `building: nullable, max:100` \| `sequence_order: nullable, integer, min:0, max:255` |

---

## Section 4 — Blade View Inventory (~32 Views)

**Base path:** `Modules/VisitorSecurity/resources/views/visitor-security/`

### Dashboard (1 view)

| View File | Route Name | Controller@Method | Description |
|---|---|---|---|
| `dashboard.blade.php` | `vsm.dashboard` | VisitorSecurityController@dashboard | **SCR-VSM-01** — Live occupancy count, overdue list (red), recent 5 check-ins, pending pre-registrations, blacklist hits today, lockdown banner when is_lockdown_active=true; **auto-refresh every 60 seconds** via `setInterval(fetchStats, 60000)` AJAX polling |

### Visitor Management (5 views)

| View File | Route Name | Controller@Method | Description |
|---|---|---|---|
| `visitors/index.blade.php` | `vsm.visitors.index` | VisitorController@index | **SCR-VSM-02** — Searchable list; visitor photo thumbnail, mobile_no, visit_count, blacklist badge chip, "Returning" badge if visit_count > 0 |
| `visitors/create.blade.php` | `vsm.visitors.create` | VisitorController@create | **SCR-VSM-03** — Walk-in registration form; webcam capture widget (HTML5 getUserMedia, HTTPS required); manual file upload fallback; ID type/number; purpose; host typeahead |
| `visitors/pre-register.blade.php` | `vsm.visitors.pre-register` | VisitorController@preRegister | **SCR-VSM-04** — Pre-registration form; expected date/time picker; duration slider; host staff select; QR preview shown on submission |
| `visitors/show.blade.php` | `vsm.visitors.show` | VisitorController@show | **SCR-VSM-05** — Visitor profile; full visit history table with status badges; blacklist status chip; "Returning visitor" banner if visit_count > 1 |
| `visitors/edit.blade.php` | `vsm.visitors.edit` | VisitorController@edit | Edit visitor profile form |

### Gate Operations (5 views)

| View File | Route Name | Controller@Method | Description |
|---|---|---|---|
| `gate/checkin.blade.php` | `vsm.gate.checkin` | VisitController@checkin | **SCR-VSM-06** — **QR scan widget** (HTML5 camera getUserMedia API; large touch targets for guard tablet kiosk); manual search fallback by mobile/name; LOCKDOWN banner overlay when active; HTTPS required for camera access |
| `gate/checkout.blade.php` | `vsm.gate.checkout` | VisitController@checkout | **SCR-VSM-07** — QR scan or manual search; displays visit duration on success |
| `visits/today.blade.php` | `vsm.visits.today` | VisitController@today | **SCR-VSM-08** — Chronological table of all today's visits; status badge chips; overdue indicator; check-in/out times |
| `visits/show.blade.php` | `vsm.visits.show` | VisitController@show | **SCR-VSM-09** — Full visit record; visitor photo + ID proof (served via signed URL); gate check-in photo; status timeline |
| `gate-passes/badge.blade.php` | `vsm.gate-passes.badge` | GatePassController@badge | **SCR-VSM-10** — DomPDF printable visitor badge; photo, name, purpose, host, valid until; auto triggers `window.print()` on load |

### Security Controls (4 views)

| View File | Route Name | Controller@Method | Description |
|---|---|---|---|
| `pickup-auth/index.blade.php` | `vsm.pickup-auth.index` | VisitorController@pickupIndex | **SCR-VSM-11** — Pickup auth list; is_authorised chip; override reason if applicable; student name |
| `contractors/index.blade.php` | `vsm.contractors.index` | ContractorController@index | **SCR-VSM-12** — Active contractors; zone badge chips; access period; pass_status; days-until-expiry |
| `contractors/create.blade.php` | `vsm.contractors.create` | ContractorController@create | **SCR-VSM-13** — Contractor registration form; work order, zone multi-select, date range picker, entry days checkbox group |
| `blacklist/index.blade.php` | `vsm.blacklist.index` | VisitorController@blacklistIndex | **SCR-VSM-14** — Blacklisted persons; reason, added-by, valid_until (PERMANENT if null); add/remove actions |

### Guard Management (5 views)

| View File | Route Name | Controller@Method | Description |
|---|---|---|---|
| `guard-shifts/index.blade.php` | `vsm.guard-shifts.index` | GuardShiftController@index | **SCR-VSM-15** — Weekly schedule grid; guard rows × day columns; attendance_status chips (Late=amber, Absent=red, Present=green); clock-in/out buttons |
| `guard-shifts/create.blade.php` | `vsm.guard-shifts.create` | GuardShiftController@create | **SCR-VSM-16** — Create/edit guard shift form; guard select, post, date, start/end time |
| `patrol/index.blade.php` | `vsm.patrol.index` | PatrolController@index | **SCR-VSM-17** — Patrol round history; completion % progress bars (green ≥80%, red <80%); status chip |
| `patrol/show.blade.php` | `vsm.patrol.show` | PatrolController@show | **SCR-VSM-18** — Live patrol view; checkpoint checklist ordered by sequence_order; scan button per checkpoint; ticks as each is scanned; completion % updates live |
| `patrol/checkpoints.blade.php` | `vsm.patrol.checkpoints` | PatrolController@checkpoints | **SCR-VSM-19** — Checkpoint management; add/edit/deactivate; QR print button triggers PatrolService::generateCheckpointQr() |

### Emergency (3 views)

| View File | Route Name | Controller@Method | Description |
|---|---|---|---|
| `emergency/broadcast.blade.php` | `vsm.emergency.broadcast` | EmergencyController@broadcastForm | **SCR-VSM-20** — **BIG RED BUTTON** design; emergency type dropdown; affected zones input; message textarea; **confirmation modal** before submit (no timeout — immediate dispatch); warns admin of lockdown implications |
| `emergency/index.blade.php` | `vsm.emergency.index` | EmergencyController@index | **SCR-VSM-21** — Active emergency panel; lockdown banner when active; headcount table per section with teacher response status; resolve button for Admin/Principal only |
| `emergency/protocols.blade.php` | `vsm.emergency.protocols` | EmergencyController@protocols | **SCR-VSM-22** — SOP list per emergency type; attach media files; edit description |

### Reports (3 views)

| View File | Route Name | Controller@Method | Description |
|---|---|---|---|
| `reports/visitor-log.blade.php` | `vsm.reports.visitor-log` | ReportController@visitorLog | **SCR-VSM-23** — Date range filter, purpose, gate, status; PDF/CSV export buttons |
| `reports/frequent-visitors.blade.php` | `vsm.reports.frequent-visitors` | ReportController@frequentVisitors | **SCR-VSM-24** — Top visitors by visit_count; date range; min visit count filter; CSV export |
| `reports/guard-attendance.blade.php` | `vsm.reports.guard-attendance` | ReportController@guardAttendance | **SCR-VSM-25** — Guard-wise attendance; late/early stats; date range filter; PDF/CSV export |

### Shared Partials (5 partials)

| Partial | Usage |
|---|---|
| `_partials/pagination.blade.php` | Consistent pagination across all list views |
| `_partials/export-buttons.blade.php` | PDF/CSV export button pair; passes `?format=pdf|csv` query param |
| `_partials/blacklist-badge.blade.php` | Red "BLACKLISTED" chip shown on visitor cards when is_blacklisted=1 |
| `_partials/status-badge.blade.php` | Coloured status chips for visit status (Pre_Registered=blue, Checked_In=green, Overdue=red, Cancelled=grey) |
| `_partials/overdue-alert-banner.blade.php` | Red banner shown on dashboard and checkin screen when overdue visitors exist |

---

## Section 5 — Complete Route List

### 5.1 Web Routes (~70 routes)
Middleware on all: `['auth', 'tenant', 'EnsureTenantHasModule:VisitorSecurity']`
Exception: `vsm.gate-passes.scan` — public route, no middleware.

| Method | URI | Route Name | Controller@Method | Middleware | FR |
|---|---|---|---|---|---|
| GET | `/visitor-security/dashboard` | `vsm.dashboard` | VisitorSecurityController@dashboard | standard | FR-VSM-05 |
| GET | `/visitor-security/visitors` | `vsm.visitors.index` | VisitorController@index | standard | FR-VSM-02/12 |
| GET | `/visitor-security/visitors/create` | `vsm.visitors.create` | VisitorController@create | standard | FR-VSM-02 |
| POST | `/visitor-security/visitors` | `vsm.visitors.store` | VisitorController@store | standard | FR-VSM-02 |
| GET | `/visitor-security/visitors/pre-register` | `vsm.visitors.pre-register` | VisitorController@preRegister | standard | FR-VSM-01 |
| POST | `/visitor-security/visitors/pre-register` | `vsm.visitors.pre-register.store` | VisitorController@storePreRegister | standard | FR-VSM-01 |
| GET | `/visitor-security/visitors/{visitor}` | `vsm.visitors.show` | VisitorController@show | standard | FR-VSM-02/12 |
| GET | `/visitor-security/visitors/{visitor}/edit` | `vsm.visitors.edit` | VisitorController@edit | standard | FR-VSM-02 |
| PUT | `/visitor-security/visitors/{visitor}` | `vsm.visitors.update` | VisitorController@update | standard | FR-VSM-02 |
| DELETE | `/visitor-security/visitors/{visitor}` | `vsm.visitors.destroy` | VisitorController@destroy | standard | FR-VSM-02 |
| POST | `/visitor-security/visitors/{visitor}/send-qr` | `vsm.visitors.send-qr` | VisitorController@sendQr | standard | FR-VSM-01 |
| GET | `/visitor-security/visits` | `vsm.visits.index` | VisitController@index | standard | FR-VSM-04 |
| GET | `/visitor-security/visits/today` | `vsm.visits.today` | VisitController@today | standard | FR-VSM-04 |
| GET | `/visitor-security/visits/{visit}` | `vsm.visits.show` | VisitController@show | standard | FR-VSM-03/04 |
| GET | `/visitor-security/gate/checkin` | `vsm.gate.checkin` | VisitController@checkin | standard | FR-VSM-03 |
| POST | `/visitor-security/gate/checkin` | `vsm.gate.checkin.process` | VisitController@processCheckin | standard | FR-VSM-03 |
| GET | `/visitor-security/gate/checkout` | `vsm.gate.checkout` | VisitController@checkout | standard | FR-VSM-04 |
| POST | `/visitor-security/gate/checkout` | `vsm.gate.checkout.process` | VisitController@processCheckout | standard | FR-VSM-04 |
| GET | `/visitor-security/gate-passes/{pass}/badge` | `vsm.gate-passes.badge` | GatePassController@badge | standard | FR-VSM-03 |
| POST | `/visitor-security/gate-passes/{pass}/revoke` | `vsm.gate-passes.revoke` | GatePassController@revoke | standard | FR-VSM-03 |
| GET | `/visitor-security/gate-passes/{pass_token}/scan` | `vsm.gate-passes.scan` | GatePassController@scan | **PUBLIC (no auth)** | FR-VSM-03 |
| GET | `/visitor-security/pickup-auth` | `vsm.pickup-auth.index` | VisitorController@pickupIndex | standard | FR-VSM-07 |
| POST | `/visitor-security/pickup-auth` | `vsm.pickup-auth.store` | VisitorController@processPickup | standard | FR-VSM-07 |
| GET | `/visitor-security/contractors` | `vsm.contractors.index` | ContractorController@index | standard | FR-VSM-08 |
| GET | `/visitor-security/contractors/create` | `vsm.contractors.create` | ContractorController@create | standard | FR-VSM-08 |
| POST | `/visitor-security/contractors` | `vsm.contractors.store` | ContractorController@store | standard | FR-VSM-08 |
| GET | `/visitor-security/contractors/{contractor}` | `vsm.contractors.show` | ContractorController@show | standard | FR-VSM-08 |
| PUT | `/visitor-security/contractors/{contractor}` | `vsm.contractors.update` | ContractorController@update | standard | FR-VSM-08 |
| POST | `/visitor-security/contractors/{contractor}/revoke` | `vsm.contractors.revoke` | ContractorController@revoke | standard | FR-VSM-08 |
| GET | `/visitor-security/blacklist` | `vsm.blacklist.index` | VisitorController@blacklistIndex | standard | FR-VSM-09 |
| POST | `/visitor-security/blacklist` | `vsm.blacklist.store` | VisitorController@blacklistStore | standard | FR-VSM-09 |
| DELETE | `/visitor-security/blacklist/{entry}` | `vsm.blacklist.destroy` | VisitorController@blacklistDestroy | standard | FR-VSM-09 |
| GET | `/visitor-security/guard-shifts` | `vsm.guard-shifts.index` | GuardShiftController@index | standard | FR-VSM-10 |
| GET | `/visitor-security/guard-shifts/create` | `vsm.guard-shifts.create` | GuardShiftController@create | standard | FR-VSM-10 |
| POST | `/visitor-security/guard-shifts` | `vsm.guard-shifts.store` | GuardShiftController@store | standard | FR-VSM-10 |
| PUT | `/visitor-security/guard-shifts/{shift}` | `vsm.guard-shifts.update` | GuardShiftController@update | standard | FR-VSM-10 |
| POST | `/visitor-security/guard-shifts/{shift}/clock-in` | `vsm.guard-shifts.clock-in` | GuardShiftController@clockIn | standard | FR-VSM-10 |
| POST | `/visitor-security/guard-shifts/{shift}/clock-out` | `vsm.guard-shifts.clock-out` | GuardShiftController@clockOut | standard | FR-VSM-10 |
| GET | `/visitor-security/patrol-rounds` | `vsm.patrol.index` | PatrolController@index | standard | FR-VSM-11 |
| POST | `/visitor-security/patrol-rounds` | `vsm.patrol.store` | PatrolController@store | standard | FR-VSM-11 |
| GET | `/visitor-security/patrol-rounds/{round}` | `vsm.patrol.show` | PatrolController@show | standard | FR-VSM-11 |
| POST | `/visitor-security/patrol-rounds/{round}/scan` | `vsm.patrol.scan` | PatrolController@scanCheckpoint | standard | FR-VSM-11 |
| POST | `/visitor-security/patrol-rounds/{round}/complete` | `vsm.patrol.complete` | PatrolController@complete | standard | FR-VSM-11 |
| GET | `/visitor-security/patrol-checkpoints` | `vsm.patrol.checkpoints` | PatrolController@checkpoints | standard | FR-VSM-11 |
| POST | `/visitor-security/patrol-checkpoints` | `vsm.patrol.checkpoints.store` | PatrolController@storeCheckpoint | standard | FR-VSM-11 |
| GET | `/visitor-security/emergency` | `vsm.emergency.index` | EmergencyController@index | standard | FR-VSM-06 |
| GET | `/visitor-security/emergency/broadcast` | `vsm.emergency.broadcast` | EmergencyController@broadcastForm | standard | FR-VSM-06 |
| POST | `/visitor-security/emergency/broadcast` | `vsm.emergency.broadcast.store` | EmergencyController@broadcast | standard | FR-VSM-06 |
| POST | `/visitor-security/emergency/{event}/resolve` | `vsm.emergency.resolve` | EmergencyController@resolve | standard | FR-VSM-06 |
| GET | `/visitor-security/emergency/protocols` | `vsm.emergency.protocols` | EmergencyController@protocols | standard | FR-VSM-06 |
| POST | `/visitor-security/emergency/protocols` | `vsm.emergency.protocols.store` | EmergencyController@storeProtocol | standard | FR-VSM-06 |
| GET | `/visitor-security/reports/visitor-log` | `vsm.reports.visitor-log` | ReportController@visitorLog | standard | FR-VSM-14 |
| GET | `/visitor-security/reports/frequent-visitors` | `vsm.reports.frequent-visitors` | ReportController@frequentVisitors | standard | FR-VSM-14 |
| GET | `/visitor-security/reports/guard-attendance` | `vsm.reports.guard-attendance` | ReportController@guardAttendance | standard | FR-VSM-14 |

**Total web routes: 54 named + ~16 from sub-methods ≈ 70**

### 5.2 API Routes (12 routes)
Middleware: `['auth:sanctum', 'tenant']` except `cctvEvent`.
Prefix: `/api/v1/vsm`

| Method | URI | Route Name | Controller@Method | Auth | FR |
|---|---|---|---|---|---|
| POST | `/api/v1/vsm/checkin` | `vsm.api.checkin` | VsmApiController@checkin | sanctum+tenant | FR-VSM-03 |
| POST | `/api/v1/vsm/checkout` | `vsm.api.checkout` | VsmApiController@checkout | sanctum+tenant | FR-VSM-04 |
| GET | `/api/v1/vsm/dashboard` | `vsm.api.dashboard` | VsmApiController@dashboard | sanctum+tenant | FR-VSM-05 |
| POST | `/api/v1/vsm/patrol/scan` | `vsm.api.patrol.scan` | VsmApiController@patrolScan | sanctum+tenant | FR-VSM-11 |
| GET | `/api/v1/vsm/visitors/search` | `vsm.api.visitors.search` | VsmApiController@searchVisitor | sanctum+tenant | FR-VSM-12 |
| GET | `/api/v1/vsm/gate-passes/{token}/validate` | `vsm.api.gate-passes.validate` | VsmApiController@validatePass | sanctum+tenant | FR-VSM-03 |
| POST | `/api/v1/vsm/contractors/checkin` | `vsm.api.contractors.checkin` | VsmApiController@contractorCheckin | sanctum+tenant | FR-VSM-08 |
| POST | `/api/v1/vsm/emergency/broadcast` | `vsm.api.emergency.broadcast` | VsmApiController@emergencyBroadcast | sanctum+tenant | FR-VSM-06 |
| GET | `/api/v1/vsm/active-visits` | `vsm.api.active-visits` | VsmApiController@activeVisits | sanctum+tenant | FR-VSM-05 |
| POST | `/api/v1/vsm/cctv/event` | `vsm.api.cctv.event` | VsmApiController@cctvEvent | **NO AUTH** + X-CCTV-Secret header | FR-VSM-13 |
| GET | `/api/v1/vsm/guard-shifts/today` | `vsm.api.guard-shifts.today` | VsmApiController@todayShifts | sanctum+tenant | FR-VSM-10 |
| POST | `/api/v1/vsm/guard-shifts/{shift}/clock` | `vsm.api.guard-shifts.clock` | VsmApiController@guardClock | sanctum+tenant | FR-VSM-10 |

---

## Section 6 — Implementation Phases (4 Phases)

### Phase 1 — Visitor Core (no cross-module deps beyond sys_*)
**FRs:** FR-VSM-01, FR-VSM-02, FR-VSM-03, FR-VSM-04, FR-VSM-09, FR-VSM-12

**Files to create:**
- Migration: `VSM_Migration.php` (all 13 tables — run once)
- Seeders: `VsmEmergencyProtocolSeeder`, `VsmPatrolCheckpointSeeder`, `VsmSeederRunner`
- Models: `VsmVisitor`, `VsmVisit`, `VsmGatePass`, `VsmBlacklist`
- Services: `VisitorService` (complete — registration, check-in/out, blacklist, QR, photo upload)
- Controllers: `VisitorSecurityController` (dashboard), `VisitorController` (all visitor + blacklist + repeat detection), `VisitController` (checkin/checkout), `GatePassController` (badge + revoke + public scan)
- FormRequests: `StoreVisitorRequest`, `PreRegisterVisitRequest`, `ProcessCheckinRequest`, `ProcessCheckoutRequest`, `StoreBlacklistRequest`
- Policies: `VisitorPolicy`, `VisitPolicy`, `GatePassPolicy`, `BlacklistPolicy`
- Jobs: `FlagOverdueVisitorsJob` (every 15 min), `ExpireGatePassesJob` (hourly)
- Views: SCR-VSM-01 to SCR-VSM-10, SCR-VSM-14 + shared partials (~16 views)
- Routes: all visitor + visit + gate pass + blacklist routes (web + public scan)

**Tests:** T01, T02, T03, T04, T05, T06, T07, T15, T16 (9 test scenarios)

---

### Phase 2 — Contractor Access + Guard Management
**FRs:** FR-VSM-07, FR-VSM-08, FR-VSM-10, FR-VSM-11

**Files to create:**
- Models: `VsmContractor`, `VsmPickupAuth`, `VsmGuardShift`, `VsmPatrolRound`, `VsmPatrolCheckpoint`, `VsmPatrolCheckpointLog`
- Services: `ContractorAccessService` (complete), `PatrolService` (complete)
- Controllers: `ContractorController`, `GuardShiftController`, `PatrolController`
- FormRequests: `ProcessPickupRequest`, `StoreContractorRequest`, `StoreGuardShiftRequest`, `StorePatrolCheckpointRequest`
- Policies: `ContractorPolicy`, `GuardShiftPolicy`, `PatrolPolicy`
- Jobs: `ExpireContractorPassesJob` (daily midnight), `ExpireBlacklistEntriesJob` (daily midnight)
- Views: SCR-VSM-11, SCR-VSM-12, SCR-VSM-13, SCR-VSM-15 to SCR-VSM-19 (~7 views)
- Routes: contractor + pickup auth + guard shift + patrol routes

**Tests:** T10, T11, T12, T13, T17 (5 test scenarios)

---

### Phase 3 — Emergency System + Reports
**FRs:** FR-VSM-06, FR-VSM-14

**Files to create:**
- Models: `VsmEmergencyProtocol`, `VsmEmergencyEvent`
- Services: `SecurityAlertService` (complete — broadcast + lockdown + overdue flagging + headcount initiation)
- Controllers: `EmergencyController`, `ReportController`
- FormRequests: `BroadcastEmergencyRequest`
- Policies: `EmergencyPolicy`
- Jobs: `EmergencyBroadcastJob` (dedicated `'emergency'` queue; 3 retries; bypasses rate limiting)
- Views: SCR-VSM-20, SCR-VSM-21, SCR-VSM-22, SCR-VSM-23, SCR-VSM-24, SCR-VSM-25 (6 views)
- Routes: emergency + report routes
- DomPDF: visitor badge (SCR-VSM-10 complete), guard attendance report PDF

**Tests:** T08, T09, T14 (3 test scenarios)

---

### Phase 4 — API + CCTV Hooks + Enhancements
**FRs:** FR-VSM-05 (API dashboard), FR-VSM-11 (API patrol scan), FR-VSM-13 (CCTV webhooks)

**Files to create:**
- Models: `VsmCctvEvent`
- Controllers: `Api\VsmApiController` (all 12 API endpoints)
- Routes: `api.php` (all 12 API routes); public scan route in `web.php`
- Dashboard polling: JS `setInterval(fetchStats, 60000)` in SCR-VSM-01 dashboard view

**Tests:** T18 + API endpoint tests (kiosk check-in, contractor check-in, dashboard JSON, CCTV webhook with valid/invalid header)

---

## Section 7 — Seeder Execution Order

```
php artisan module:seed VisitorSecurity --class=VsmSeederRunner
  ↓ VsmEmergencyProtocolSeeder    (no vsm_* dependencies; seeds vsm_emergency_protocols)
  ↓ VsmPatrolCheckpointSeeder     (no vsm_* dependencies; seeds vsm_patrol_checkpoints)
```

### Artisan Scheduled Jobs
Register in `routes/console.php` (Laravel 11+) or `app/Console/Kernel.php` (Laravel 10):

```php
// routes/console.php (Laravel 11+)
Schedule::job(new FlagOverdueVisitorsJob)->everyFifteenMinutes();
Schedule::job(new ExpireGatePassesJob)->hourly();
Schedule::job(new ExpireBlacklistEntriesJob)->dailyAt('00:00');
Schedule::job(new ExpireContractorPassesJob)->dailyAt('00:01');
```

| Job Class | Artisan Command | Schedule | Queue | Description |
|---|---|---|---|---|
| `FlagOverdueVisitorsJob` | `vsm:flag-overdue-visitors` | Every 15 minutes | default | Set is_overdue=1 on Checked_In visits past expected duration; Carbon::setTimezone() for school TZ |
| `ExpireGatePassesJob` | `vsm:expire-gate-passes` | Every 1 hour | default | Set status=Expired on vsm_gate_passes where expires_at < NOW() |
| `ExpireBlacklistEntriesJob` | `vsm:expire-blacklist-entries` | Daily at 00:00 | default | Set is_active=0 on vsm_blacklist where valid_until < TODAY() (BR-VSM-014) |
| `ExpireContractorPassesJob` | `vsm:expire-contractor-passes` | Daily at 00:01 | default | Set pass_status=Expired on vsm_contractors where access_until < TODAY() |
| `EmergencyBroadcastJob` | — (dispatched on demand) | On trigger | **'emergency'** | Dispatches SMS+in-app to ALL active sys_users; 3 retries; bypasses rate limiting |

---

## Section 8 — Testing Strategy

### Framework
- Feature tests: **Pest** syntax with `RefreshDatabase`
- Unit tests: bare PHPUnit (no Laravel app bootstrap)
- Policy tests: Pest Feature tests with `actingAs()`

### Test Setup

```php
// All Feature tests
uses(Tests\TestCase::class, RefreshDatabase::class);

// Actor factories
$adminUser      = User::factory()->withRole('Admin')->create();
$receptionUser  = User::factory()->withRole('Reception')->create();
$guardUser      = User::factory()->withRole('Guard')->create();
$teacherUser    = User::factory()->withRole('Teacher')->create();
$principalUser  = User::factory()->withRole('Principal')->create();

// Module factories
VsmVisitorFactory::new()         // mobile_no, optional id_number, visit_count defaults to 0
VsmVisitFactory::new()           // visit_number (VSM-YYYYMMDD-XXXX), status parameter, expected_date/time
VsmGatePassFactory::new()        // pass_token = Str::uuid(), expires_at = NOW()+24h, status=Issued
VsmBlacklistFactory::new()       // mobile_no or id_number, reason, valid_until (nullable)
VsmContractorFactory::new()      // pass_token = Str::uuid(), access_from/until, pass_status=Active

// Fakes
Notification::fake();  // host arrival alerts + emergency broadcast
Queue::fake();         // FlagOverdueVisitorsJob, EmergencyBroadcastJob
Storage::fake();       // visitor photo + ID proof uploads (sys_media private disk)
```

### Feature Test File Summary (18 scenarios)

| # | File | Key Scenarios | Priority |
|---|---|---|---|
| T01 | `VisitorRegistrationTest.php` | Walk-in registration stores vsm_visitors + vsm_visits; photo to sys_media; blacklist check runs; gate pass generated | Critical |
| T02 | `BlacklistBlockTest.php` | Blacklisted mobile_no → 422 blocked; blacklist_hit=1 on vsm_visits; alert notification dispatched | Critical |
| T03 | `PreRegistrationQrTest.php` | Pre-register creates vsm_visits(Pre_Registered); pass_token = UUID v4; SMS notification dispatched via Queue | Critical |
| T04 | `GateCheckinTest.php` | QR scan → checkin_time set; status=Checked_In; pass=Used; visit_count incremented; host notification queued | Critical |
| T05 | `DuplicateCheckinBlockTest.php` | Second check-in attempt for already-Checked_In visitor → 422; no visit_count double-increment | Critical |
| T06 | `GateCheckoutTest.php` | Checkout → checkout_time set; duration_minutes computed; status=Checked_Out; is_overdue cleared | High |
| T07 | `OverdueFlaggingTest.php` | Carbon::setTestNow() past duration → FlagOverdueVisitorsJob sets is_overdue=1; checkout clears it | High |
| T08 | `EmergencyBroadcastTest.php` | Broadcast → vsm_emergency_events created; EmergencyBroadcastJob on 'emergency' queue; notification_count updated | High |
| T09 | `LockdownModeTest.php` | is_lockdown_active=true → pre-register returns 403; check-in screen shows banner | High |
| T10 | `StudentPickupAuthTest.php` | Guardian in std_student_guardian_jnt.can_pickup=1 → is_authorised=1; not in list → override required | High |
| T11 | `ContractorAccessTest.php` | Valid date range → entry allowed; access_until < today → 422; pass_status=Revoked → 403 | High |
| T12 | `PatrolRoundTest.php` | 3 checkpoints scanned of 4 total → completion_pct=75.00 → status=Incomplete; 4/4 → Completed | Medium |
| T13 | `GuardClockInTest.php` | Clock-in exactly 14 min late → Present; 15 min late → Late (BR-VSM-007 boundary test) | Medium |
| T14 | `BlacklistExpiryTest.php` (Unit) | valid_until = yesterday → ExpireBlacklistEntriesJob sets is_active=0; valid_until = today → still active | Medium |
| T15 | `GatePassExpiryTest.php` (Unit) | expires_at = 1 min ago → validate returns Expired; blocks check-in | High |
| T16 | `RepeatVisitorTest.php` | Second registration with same mobile_no → same vsm_visitors record matched; visit_count++ on check-in | Medium |
| T17 | `ContractorEntryDayBlockTest.php` | entry_days_json=["Mon","Tue"] + today=Wednesday → ContractorAccessService rejects with day-blocked | Medium |
| T18 | `CctvWebhookTest.php` | POST with valid X-CCTV-Secret → vsm_cctv_events created; invalid header → 401; linked_visit_id set when gate camera + active visit | Low |

### Key Concurrency + Edge Case Tests

**BR-VSM-003 — Duplicate check-in:**
```php
$visit = VsmVisit::factory()->create(['status' => 'Checked_In']);
$this->actingAs($guardUser)
     ->post(route('vsm.gate.checkin.process'), ['visit_id' => $visit->id])
     ->assertStatus(422);
```

**BR-VSM-010 — Lockdown gate block:**
```php
VsmEmergencyEvent::factory()->create(['is_lockdown_active' => 1, 'resolved_at' => null]);

$this->actingAs($receptionUser)
     ->post(route('vsm.visitors.pre-register.store'), $validPreRegData)
     ->assertStatus(403);
```

**BR-VSM-006 — Patrol 80% boundary:**
```php
// 3 of 4 checkpoints (75%) → Incomplete
// 4 of 4 checkpoints (100%) → Completed
// 8 of 10 checkpoints (80%) → boundary: exactly 80% → Completed
// 7 of 10 checkpoints (70%) → Incomplete
```

**BR-VSM-007 — Guard Late boundary:**
```php
// Shift start: 09:00
// Clock-in at 09:14 → Present (14 min < 15 min threshold)
// Clock-in at 09:15 → Present (exactly at threshold, not OVER)
// Clock-in at 09:16 → Late (> 15 min threshold)
```

**Overdue + Expiry — time travel:**
```php
// Use Carbon::setTestNow() for time-travel in tests
Carbon::setTestNow(now()->addMinutes(90));  // advance past expected_duration_minutes
$this->artisan('vsm:flag-overdue-visitors');
expect($visit->fresh()->is_overdue)->toBe(1);

// Gate pass expiry
Carbon::setTestNow(now()->addHours(25));   // advance past 24h expires_at
$this->get(route('vsm.gate.checkin.process', ['pass_token' => $pass->pass_token]))
     ->assertStatus(422);  // Expired pass
Carbon::setTestNow(); // reset
```

**CCTV webhook — header validation:**
```php
// Valid secret
$this->withHeaders(['X-CCTV-Secret' => config('vsm.cctv_secret')])
     ->postJson(route('vsm.api.cctv.event'), $payload)
     ->assertSuccessful();

// Invalid / missing secret
$this->postJson(route('vsm.api.cctv.event'), $payload)
     ->assertStatus(401);
```

### Policy Test Files (2 files)

| File | Key Assertions |
|---|---|
| `VisitorPolicyTest.php` | Admin can delete; Reception cannot delete; Guard cannot create; Teacher can pre-register |
| `EmergencyPolicyTest.php` | Admin can broadcast; Principal can broadcast; Reception cannot broadcast; Guard can view |

### Minimum Coverage Targets

| Behaviour | Coverage Requirement |
|---|---|
| BR-VSM-001 (blacklist check) | Tested on BOTH pre-registration AND walk-in registration |
| BR-VSM-002 (UUID v4 pass) | Assert pass_token matches UUID v4 regex in T03 |
| BR-VSM-003 (duplicate check-in) | Explicitly tested with concurrent simulation in T05 |
| BR-VSM-004 (overdue scheduler) | Time-travel test with Carbon::setTestNow() in T07 |
| BR-VSM-006 (patrol < 80% = Incomplete) | Boundary test at 79% AND 80% AND 81% in T12 |
| BR-VSM-007 (guard Late) | Boundary test at 14 min / 15 min / 16 min in T13 |
| BR-VSM-010 (lockdown gate-block) | Explicitly tested with active lockdown event in T09 |
| BR-VSM-012 (contractor day restriction) | Day-of-week block tested explicitly in T17 |
| FR-VSM-13 (CCTV webhook) | Valid + invalid X-CCTV-Secret header test in T18 |
| All 4 scheduled jobs | `$this->artisan()` + time-travel; assert DB state changed |

---

## Quick Reference — VSM Module Tables × Controllers × Services

| Domain | vsm_* Tables | Controller(s) | Service(s) |
|---|---|---|---|
| Visitor Core | vsm_visitors, vsm_visits, vsm_gate_passes | VisitorController, VisitController, GatePassController | VisitorService (checkin/out, QR gen, blacklist check) |
| Access Control | vsm_contractors, vsm_pickup_auth, vsm_blacklist | ContractorController, VisitorController (pickup+blacklist) | ContractorAccessService, VisitorService (blacklist/pickup) |
| Guard Ops | vsm_guard_shifts, vsm_patrol_checkpoints, vsm_patrol_rounds, vsm_patrol_checkpoint_log | GuardShiftController, PatrolController | PatrolService (patrol + checkpoint QR) |
| Emergency | vsm_emergency_protocols, vsm_emergency_events | EmergencyController | SecurityAlertService (broadcast + lockdown + overdue flagging) |
| CCTV | vsm_cctv_events | Api\VsmApiController | — (webhook ingestion only) |
| Dashboard | — (reads vsm_visits, vsm_emergency_events) | VisitorSecurityController | SecurityAlertService::isLockdownActive() |
| Reports | — (reads all vsm_*) | ReportController | — (inline queries + DomPDF/fputcsv) |
| API / Kiosk | — | Api\VsmApiController | All 4 services (thin wrappers) |
