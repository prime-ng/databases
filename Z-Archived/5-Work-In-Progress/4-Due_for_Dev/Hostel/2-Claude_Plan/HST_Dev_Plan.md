# HST — Hostel Management Module Development Plan
**Module:** HST (Hostel Management) | **Version:** 1.0 | **Date:** 2026-03-27
**Namespace:** `Modules\Hostel` | **Route Prefix:** `hostel/` | **Table Prefix:** `hst_*`
**Phase 1 Ref:** `HST_FeatureSpec.md` | **Phase 2 Ref:** `HST_DDL_v1.sql` + Migration + Seeders

---

## Section 1 — Controller Inventory (20 Controllers)

> Namespace: `Modules\Hostel\app\Http\Controllers`
> Base path: `app/Http/Controllers/` (within Hostel module)
> Middleware on all routes: `['auth', 'tenant', 'EnsureTenantHasModule:Hostel']`
> Additional: `['WardenScopeMiddleware']` on allotment, attendance, leave pass, incident routes

---

### 1. HstDashboardController
**File:** `HstDashboardController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/dashboard` | `hostel.dashboard` | — | `hostel.view` |

**Dashboard KPIs (all pre-computed — no aggregation on page load):**
- Live occupancy: from `hst_hostels.current_occupancy` (denormalized)
- Today's attendance: from `hst_attendance.present_count` for today's sessions
- Pending leave passes: `COUNT` where status='pending'
- Open incidents: `COUNT` where status IN (open, under_investigation)
- Current sick bay occupants: `hst_sick_bay_log` where `discharge_datetime IS NULL`
- Fee defaulters: from `HostelFeeService::getFeeDefaulters()`
- Attendance compliance %: `present_count / (total_students - leave_count)` per hostel

---

### 2. HostelController
**File:** `HostelController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/hostels` | `hostel.hostels.index` | — | `hostel.hostel.viewAny` |
| `store` | POST | `hostel/hostels` | `hostel.hostels.store` | `StoreHostelRequest` | `hostel.hostel.create` |
| `show` | GET | `hostel/hostels/{hostel}` | `hostel.hostels.show` | — | `hostel.hostel.view` |
| `update` | PUT | `hostel/hostels/{hostel}` | `hostel.hostels.update` | `StoreHostelRequest` | `hostel.hostel.update` |
| `destroy` | DELETE | `hostel/hostels/{hostel}` | `hostel.hostels.destroy` | — | `hostel.hostel.delete` |
| `toggleStatus` | POST | `hostel/hostels/{hostel}/toggle-status` | `hostel.hostels.toggle-status` | — | `hostel.hostel.update` |

---

### 3. FloorController
**File:** `FloorController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/floors` | `hostel.floors.index` | — | `hostel.hostel.viewAny` |
| `store` | POST | `hostel/floors` | `hostel.floors.store` | `StoreFloorRequest` | `hostel.hostel.create` |
| `show` | GET | `hostel/floors/{floor}` | `hostel.floors.show` | — | `hostel.hostel.view` |
| `update` | PUT | `hostel/floors/{floor}` | `hostel.floors.update` | `StoreFloorRequest` | `hostel.hostel.update` |
| `destroy` | DELETE | `hostel/floors/{floor}` | `hostel.floors.destroy` | — | `hostel.hostel.delete` |

---

### 4. RoomController
**File:** `RoomController.php`
*(Includes nested room inventory sub-routes)*

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/rooms` | `hostel.rooms.index` | — | `hostel.hostel.viewAny` |
| `store` | POST | `hostel/rooms` | `hostel.rooms.store` | `StoreRoomRequest` | `hostel.hostel.create` |
| `show` | GET | `hostel/rooms/{room}` | `hostel.rooms.show` | — | `hostel.hostel.view` |
| `update` | PUT | `hostel/rooms/{room}` | `hostel.rooms.update` | `StoreRoomRequest` | `hostel.hostel.update` |
| `destroy` | DELETE | `hostel/rooms/{room}` | `hostel.rooms.destroy` | — | `hostel.hostel.delete` |
| `toggleStatus` | POST | `hostel/rooms/{room}/toggle-status` | `hostel.rooms.toggle-status` | — | `hostel.hostel.update` |
| `roomInventory` | GET | `hostel/rooms/{room}/inventory` | `hostel.rooms.inventory.index` | — | `hostel.inventory.manage` |
| `storeInventory` | POST | `hostel/rooms/{room}/inventory` | `hostel.rooms.inventory.store` | `StoreRoomInventoryRequest` | `hostel.inventory.manage` |
| `updateInventory` | PUT | `hostel/rooms/{room}/inventory/{item}` | `hostel.rooms.inventory.update` | `StoreRoomInventoryRequest` | `hostel.inventory.manage` |
| `destroyInventory` | DELETE | `hostel/rooms/{room}/inventory/{item}` | `hostel.rooms.inventory.destroy` | — | `hostel.inventory.manage` |

---

### 5. BedController
**File:** `BedController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/beds` | `hostel.beds.index` | — | `hostel.hostel.viewAny` |
| `store` | POST | `hostel/beds` | `hostel.beds.store` | `StoreBedRequest` | `hostel.hostel.create` |
| `show` | GET | `hostel/beds/{bed}` | `hostel.beds.show` | — | `hostel.hostel.view` |
| `update` | PUT | `hostel/beds/{bed}` | `hostel.beds.update` | `StoreBedRequest` | `hostel.hostel.update` |
| `destroy` | DELETE | `hostel/beds/{bed}` | `hostel.beds.destroy` | — | `hostel.hostel.delete` |
| `toggleMaintenance` | POST | `hostel/beds/{bed}/toggle-maintenance` | `hostel.beds.toggle-maintenance` | — | `hostel.hostel.update` |

---

### 6. WardenAssignmentController
**File:** `WardenAssignmentController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/warden-assignments` | `hostel.wardens.index` | — | `hostel.warden.manage` |
| `store` | POST | `hostel/warden-assignments` | `hostel.wardens.store` | `StoreWardenAssignmentRequest` | `hostel.warden.manage` |
| `show` | GET | `hostel/warden-assignments/{assignment}` | `hostel.wardens.show` | — | `hostel.warden.manage` |
| `update` | PUT | `hostel/warden-assignments/{assignment}` | `hostel.wardens.update` | `StoreWardenAssignmentRequest` | `hostel.warden.manage` |
| `end` | POST | `hostel/warden-assignments/{assignment}/end` | `hostel.wardens.end` | — | `hostel.warden.manage` |

---

### 7. AllotmentController
**File:** `AllotmentController.php` | **Additional Middleware:** `WardenScopeMiddleware`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/allotments` | `hostel.allotments.index` | — | `hostel.allotment.viewAny` |
| `store` | POST | `hostel/allotments` | `hostel.allotments.store` | `StoreAllotmentRequest` | `hostel.allotment.allot` |
| `show` | GET | `hostel/allotments/{allotment}` | `hostel.allotments.show` | — | `hostel.allotment.view` |
| `update` | PUT | `hostel/allotments/{allotment}` | `hostel.allotments.update` | `StoreAllotmentRequest` | `hostel.allotment.allot` |
| `vacate` | POST | `hostel/allotments/{allotment}/vacate` | `hostel.allotments.vacate` | — | `hostel.allotment.vacate` |
| `transfer` | POST | `hostel/allotments/{allotment}/transfer` | `hostel.allotments.transfer` | `TransferAllotmentRequest` | `hostel.allotment.transfer` |
| `bulkVacate` | POST | `hostel/allotments/bulk-vacate` | `hostel.allotments.bulk-vacate` | `BulkVacateRequest` | `hostel.allotment.bulk-vacate` |
| `availability` | GET | `hostel/allotments/availability` | `hostel.allotments.availability` | — | `hostel.allotment.viewAny` |

---

### 8. RoomChangeRequestController
**File:** `RoomChangeRequestController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/room-change-requests` | `hostel.rcr.index` | — | `hostel.allotment.viewAny` |
| `store` | POST | `hostel/room-change-requests` | `hostel.rcr.store` | `StoreRoomChangeRequest` | `hostel.allotment.allot` |
| `show` | GET | `hostel/room-change-requests/{rcr}` | `hostel.rcr.show` | — | `hostel.allotment.view` |
| `approve` | POST | `hostel/room-change-requests/{rcr}/approve` | `hostel.rcr.approve` | — | `hostel.allotment.transfer` |
| `reject` | POST | `hostel/room-change-requests/{rcr}/reject` | `hostel.rcr.reject` | — | `hostel.allotment.transfer` |

---

### 9. HstAttendanceController
**File:** `HstAttendanceController.php` | **Additional Middleware:** `WardenScopeMiddleware`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/attendance` | `hostel.attendance.index` | — | `hostel.attendance.viewAny` |
| `store` | POST | `hostel/attendance` | `hostel.attendance.store` | `StoreHstAttendanceRequest` | `hostel.attendance.create` |
| `show` | GET | `hostel/attendance/{session}` | `hostel.attendance.show` | — | `hostel.attendance.view` |
| `update` | PUT | `hostel/attendance/{session}` | `hostel.attendance.update` | `StoreHstAttendanceRequest` | `hostel.attendance.update` |
| `entries` | GET | `hostel/attendance/{session}/entries` | `hostel.attendance.entries` | — | `hostel.attendance.view` |
| `storeEntries` | POST | `hostel/attendance/{session}/entries` | `hostel.attendance.store-entries` | `BulkMarkAttendanceRequest` | `hostel.attendance.create` |
| `bulkMark` | POST | `hostel/attendance/{session}/bulk-mark` | `hostel.attendance.bulk-mark` | `BulkMarkAttendanceRequest` | `hostel.attendance.create` |
| `lock` | POST | `hostel/attendance/{session}/lock` | `hostel.attendance.lock` | — | `hostel.attendance.lock` |

---

### 10. MovementLogController
**File:** `MovementLogController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/movement-log` | `hostel.movement.index` | — | `hostel.attendance.viewAny` |
| `store` | POST | `hostel/movement-log` | `hostel.movement.store` | `StoreMovementLogRequest` | `hostel.attendance.create` |
| `show` | GET | `hostel/movement-log/{log}` | `hostel.movement.show` | — | `hostel.attendance.view` |
| `recordReturn` | POST | `hostel/movement-log/{log}/return` | `hostel.movement.return` | — | `hostel.attendance.create` |
| `pendingReturns` | GET | `hostel/movement-log/pending` | `hostel.movement.pending` | — | `hostel.attendance.viewAny` |

---

### 11. LeavePassController
**File:** `LeavePassController.php` | **Additional Middleware:** `WardenScopeMiddleware`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/leave-passes` | `hostel.leave.index` | — | `hostel.leave.viewAny` |
| `store` | POST | `hostel/leave-passes` | `hostel.leave.store` | `StoreLeavePassRequest` | `hostel.leave.create` |
| `show` | GET | `hostel/leave-passes/{pass}` | `hostel.leave.show` | — | `hostel.leave.view` |
| `update` | PUT | `hostel/leave-passes/{pass}` | `hostel.leave.update` | `StoreLeavePassRequest` | `hostel.leave.create` |
| `approve` | POST | `hostel/leave-passes/{pass}/approve` | `hostel.leave.approve` | `ApproveLeavePassRequest` | `hostel.leave.approve` |
| `reject` | POST | `hostel/leave-passes/{pass}/reject` | `hostel.leave.reject` | — | `hostel.leave.approve` |
| `markReturned` | POST | `hostel/leave-passes/{pass}/return` | `hostel.leave.return` | `MarkReturnedRequest` | `hostel.leave.approve` |
| `cancel` | POST | `hostel/leave-passes/{pass}/cancel` | `hostel.leave.cancel` | — | `hostel.leave.approve` |
| `print` | GET | `hostel/leave-passes/{pass}/print` | `hostel.leave.print` | — | `hostel.leave.print` |
| `calendar` | GET | `hostel/leave-passes/calendar` | `hostel.leave.calendar` | — | `hostel.leave.viewAny` |

---

### 12. IncidentController
**File:** `IncidentController.php` | **Additional Middleware:** `WardenScopeMiddleware`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/incidents` | `hostel.incidents.index` | — | `hostel.incident.viewAny` |
| `store` | POST | `hostel/incidents` | `hostel.incidents.store` | `StoreIncidentRequest` | `hostel.incident.create` |
| `show` | GET | `hostel/incidents/{incident}` | `hostel.incidents.show` | — | `hostel.incident.view` |
| `update` | PUT | `hostel/incidents/{incident}` | `hostel.incidents.update` | `StoreIncidentRequest` | `hostel.incident.create` |
| `escalate` | POST | `hostel/incidents/{incident}/escalate` | `hostel.incidents.escalate` | — | `hostel.incident.escalate` |
| `printWarningLetter` | GET | `hostel/incidents/{incident}/warning-letter` | `hostel.incidents.warning-letter` | — | `hostel.incident.warning-letter` |
| `notifyParent` | POST | `hostel/incidents/{incident}/notify-parent` | `hostel.incidents.notify-parent` | — | `hostel.incident.create` |
| `storeMedia` | POST | `hostel/incidents/{incident}/media` | `hostel.incidents.media.store` | — | `hostel.incident.create` |
| `destroyMedia` | DELETE | `hostel/incidents/{incident}/media/{media}` | `hostel.incidents.media.destroy` | — | `hostel.incident.create` |

---

### 13. MessMenuController
**File:** `MessMenuController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/mess/menus` | `hostel.mess.menus.index` | — | `hostel.mess.viewAny` |
| `store` | POST | `hostel/mess/menus` | `hostel.mess.menus.store` | `StoreMessMenuRequest` | `hostel.mess.menu.manage` |
| `show` | GET | `hostel/mess/menus/{menu}` | `hostel.mess.menus.show` | — | `hostel.mess.viewAny` |
| `update` | PUT | `hostel/mess/menus/{menu}` | `hostel.mess.menus.update` | `StoreMessMenuRequest` | `hostel.mess.menu.manage` |
| `destroy` | DELETE | `hostel/mess/menus/{menu}` | `hostel.mess.menus.destroy` | — | `hostel.mess.menu.manage` |
| `copyWeek` | POST | `hostel/mess/menus/copy-week` | `hostel.mess.menus.copy-week` | — | `hostel.mess.menu.manage` |

---

### 14. SpecialDietController
**File:** `SpecialDietController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/mess/special-diets` | `hostel.mess.diets.index` | — | `hostel.mess.viewAny` |
| `store` | POST | `hostel/mess/special-diets` | `hostel.mess.diets.store` | `StoreSpecialDietRequest` | `hostel.mess.diet.manage` |
| `show` | GET | `hostel/mess/special-diets/{diet}` | `hostel.mess.diets.show` | — | `hostel.mess.viewAny` |
| `update` | PUT | `hostel/mess/special-diets/{diet}` | `hostel.mess.diets.update` | `StoreSpecialDietRequest` | `hostel.mess.diet.manage` |
| `destroy` | DELETE | `hostel/mess/special-diets/{diet}` | `hostel.mess.diets.destroy` | — | `hostel.mess.diet.manage` |

---

### 15. MessAttendanceController
**File:** `MessAttendanceController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/mess/attendance` | `hostel.mess.attendance.index` | — | `hostel.mess.viewAny` |
| `store` | POST | `hostel/mess/attendance` | `hostel.mess.attendance.store` | `StoreMessAttendanceRequest` | `hostel.mess.attendance.mark` |
| `bulkStore` | POST | `hostel/mess/attendance/bulk` | `hostel.mess.attendance.bulk` | `BulkMessAttendanceRequest` | `hostel.mess.attendance.mark` |
| `monthlyReport` | GET | `hostel/mess/attendance/report` | `hostel.mess.attendance.report` | — | `hostel.report.view` |

---

### 16. HstFeeController
**File:** `HstFeeController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/fee-structures` | `hostel.fee.index` | — | `hostel.fee.viewAny` |
| `store` | POST | `hostel/fee-structures` | `hostel.fee.store` | `StoreHstFeeStructureRequest` | `hostel.fee.manage` |
| `show` | GET | `hostel/fee-structures/{structure}` | `hostel.fee.show` | — | `hostel.fee.viewAny` |
| `update` | PUT | `hostel/fee-structures/{structure}` | `hostel.fee.update` | `StoreHstFeeStructureRequest` | `hostel.fee.manage` |
| `destroy` | DELETE | `hostel/fee-structures/{structure}` | `hostel.fee.destroy` | — | `hostel.fee.manage` |
| `calculate` | GET | `hostel/fee-structures/calculate` | `hostel.fee.calculate` | — | `hostel.fee.viewAny` |
| `defaulters` | GET | `hostel/fee-structures/defaulters` | `hostel.fee.defaulters` | — | `hostel.fee.viewAny` |

---

### 17. HstComplaintController
**File:** `HstComplaintController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/complaints` | `hostel.complaints.index` | — | `hostel.complaint.viewAny` |
| `store` | POST | `hostel/complaints` | `hostel.complaints.store` | `StoreHstComplaintRequest` | `hostel.complaint.create` |
| `show` | GET | `hostel/complaints/{complaint}` | `hostel.complaints.show` | — | `hostel.complaint.view` |
| `update` | PUT | `hostel/complaints/{complaint}` | `hostel.complaints.update` | `StoreHstComplaintRequest` | `hostel.complaint.manage` |
| `assign` | POST | `hostel/complaints/{complaint}/assign` | `hostel.complaints.assign` | — | `hostel.complaint.manage` |
| `resolve` | POST | `hostel/complaints/{complaint}/resolve` | `hostel.complaints.resolve` | `ResolveComplaintRequest` | `hostel.complaint.manage` |
| `escalate` | POST | `hostel/complaints/{complaint}/escalate` | `hostel.complaints.escalate` | — | `hostel.complaint.manage` |

---

### 18. VisitorLogController
**File:** `VisitorLogController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/visitors` | `hostel.visitors.index` | — | `hostel.visitor.manage` |
| `store` | POST | `hostel/visitors` | `hostel.visitors.store` | `StoreVisitorLogRequest` | `hostel.visitor.manage` |
| `show` | GET | `hostel/visitors/{visitor}` | `hostel.visitors.show` | — | `hostel.visitor.manage` |
| `update` | PUT | `hostel/visitors/{visitor}` | `hostel.visitors.update` | `StoreVisitorLogRequest` | `hostel.visitor.manage` |
| `checkout` | POST | `hostel/visitors/{visitor}/checkout` | `hostel.visitors.checkout` | — | `hostel.visitor.manage` |

---

### 19. SickBayController
**File:** `SickBayController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `hostel/sick-bay` | `hostel.sickbay.index` | — | `hostel.sickbay.manage` |
| `store` | POST | `hostel/sick-bay` | `hostel.sickbay.store` | `StoreSickBayRequest` | `hostel.sickbay.manage` |
| `show` | GET | `hostel/sick-bay/{log}` | `hostel.sickbay.show` | — | `hostel.sickbay.manage` |
| `update` | PUT | `hostel/sick-bay/{log}` | `hostel.sickbay.update` | `StoreSickBayRequest` | `hostel.sickbay.manage` |
| `discharge` | POST | `hostel/sick-bay/{log}/discharge` | `hostel.sickbay.discharge` | `DischargeSickBayRequest` | `hostel.sickbay.manage` |
| `current` | GET | `hostel/sick-bay/current` | `hostel.sickbay.current` | — | `hostel.sickbay.manage` |

---

### 20. HstReportController
**File:** `HstReportController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `occupancy` | GET | `hostel/reports/occupancy` | `hostel.reports.occupancy` | — | `hostel.report.view` |
| `attendance` | GET | `hostel/reports/attendance` | `hostel.reports.attendance` | — | `hostel.report.view` |
| `leaveRegister` | GET | `hostel/reports/leave-register` | `hostel.reports.leave-register` | — | `hostel.report.view` |
| `movement` | GET | `hostel/reports/movement` | `hostel.reports.movement` | — | `hostel.report.view` |
| `feeDefaulters` | GET | `hostel/reports/fee-defaulters` | `hostel.reports.fee-defaulters` | — | `hostel.report.view` |
| `incidents` | GET | `hostel/reports/incidents` | `hostel.reports.incidents` | — | `hostel.report.view` |
| `messAttendance` | GET | `hostel/reports/mess-attendance` | `hostel.reports.mess-attendance` | — | `hostel.report.view` |
| `roomInventory` | GET | `hostel/reports/room-inventory` | `hostel.reports.room-inventory` | — | `hostel.report.view` |
| `visitors` | GET | `hostel/reports/visitors` | `hostel.reports.visitors` | — | `hostel.report.view` |
| `sickBay` | GET | `hostel/reports/sick-bay` | `hostel.reports.sick-bay` | — | `hostel.report.view` |
| `export` | GET | `hostel/reports/{type}/export` | `hostel.reports.export` | — | `hostel.report.export` |

---

## Section 2 — Service Inventory (7 Services)

> Namespace: `Modules\Hostel\app\Services`
> Base path: `app/Services/` (within Hostel module)

---

### 1. AllotmentService
**File:** `AllotmentService.php`
**Depends on:** `HostelFeeService`
**Fires:** *(no events — direct service call to HostelFeeService after commit)*

```
Key Methods:

  create(array $data): Allotment
    └── Full 12-step allotment creation (see pseudocode below)

  transfer(Allotment $current, array $data): Allotment
    └── Marks old allotment 'transferred'; creates new active allotment;
        updates bed/room/hostel occupancy for both; calls
        HostelFeeService::calculateRoomChangeDifferential()

  vacate(Allotment $allotment, ?string $reason = null): void
    └── Sets status='vacated', vacating_date=today; bed → 'available';
        room.current_occupancy -1; hostel.current_occupancy -1;
        calls HostelFeeService::calculateVacatingRefund() if mid-month

  bulkVacate(int $academicSessionId, User $admin): int
    └── Marks all active allotments for session as 'vacated';
        bulk-updates bed statuses; writes audit entry to sys_activity_logs;
        returns count of vacated records

  validateGender(Student $student, Hostel $hostel): void
    └── Throws HostelGenderMismatchException if student.gender ≠ hostel.type
        (boys/girls/mixed)

  checkBedAvailability(int $bedId): void
    └── Throws BedNotAvailableException if hst_beds.status ≠ 'available'

  checkDoubleAllotment(int $bedId, int $studentId): void
    └── Catches MySQL DuplicateEntry (1062) on UNIQUE(gen_active_bed_id) and
        UNIQUE(gen_active_student_id); re-throws as user-friendly
        DuplicateAllotmentException

  validateFeeStructureExists(int $hostelId, string $roomType,
                              string $mealPlan, int $academicSessionId): void
    └── Queries hst_fee_structures; throws FeeStructureNotFoundException
        if none found (BR-HST-015)
```

**AllotmentService::create() — 12-step pseudocode:**
```
create(array $data): Allotment
  Step 1:  Load bed + room; validate bed.status = 'available'
  Step 2:  Check gen_active_bed_id uniqueness — catch DuplicateEntry (1062)
           → re-throw as DuplicateAllotmentException('Bed already occupied')
  Step 3:  Check gen_active_student_id uniqueness — same pattern
           → re-throw as DuplicateAllotmentException('Student already allotted')
  Step 4:  Load hostel; validateGender($student, $hostel) — throw on mismatch
  Step 5:  validateFeeStructureExists($hostel, $room->room_type, $data['meal_plan'],
           $data['academic_session_id'])
  Step 6:  DB::transaction() begins
  Step 7:  INSERT hst_allotments (status='active', allotment_date=$data['allotment_date'])
  Step 8:  UPDATE hst_beds SET status='occupied' WHERE id=$bed->id
  Step 9:  UPDATE hst_rooms SET current_occupancy = current_occupancy + 1 WHERE id=$room->id
           if new current_occupancy >= capacity → SET status='full'
  Step 10: UPDATE hst_hostels SET current_occupancy = current_occupancy + 1 WHERE id=$hostel->id
  Step 11: DB::transaction() commits
  Step 12: HostelFeeService::pushFeeDemand($allotment) — called AFTER commit
           (separate from transaction — fee push failure must not rollback allotment)
```

---

### 2. LeavePassService
**File:** `LeavePassService.php`
**Depends on:** `HstAttendanceService`, `IncidentService`
**Fires:** `LeavePassApproved`, `LeavePassRejected`, `StudentReturned`

```
Key Methods:

  approve(LeavePass $pass, User $warden): void
    └── Full 8-step transaction (see pseudocode below)

  reject(LeavePass $pass, User $warden, string $reason): void
    └── Sets status='rejected', rejection_reason; dispatches LeavePassRejected event

  markReturned(LeavePass $pass, Carbon $actualReturnDate, User $warden): void
    └── Sets status='returned', actual_return_date;
        if actual_return_date > to_date →
          IncidentService::createAutoIncident(pass, 'late_arrival')
          pass.late_return_incident_id = incident->id;
        dispatches StudentReturned event (with is_late flag)

  cancel(LeavePass $pass, User $warden): void
    └── Only from 'approved' status; reverts attendance entries from 'leave' → 'absent';
        reverts mess attendance from 'on_leave' → 'absent'; sets status='cancelled'

  markAttendanceForLeave(LeavePass $pass): void
    └── For each date in [$pass->from_date ... $pass->to_date]:
          For each shift in [morning, evening, night]:
            Fetch or create hst_attendance session for (hostel, date, shift)
            INSERT/UPDATE hst_attendance_entries: student_id, status='leave'
            Recompute and UPDATE session leave_count + absent_count

  markMessAttendanceForLeave(LeavePass $pass): void
    └── For each date in [$pass->from_date ... $pass->to_date]:
          For each meal in [breakfast, lunch, dinner, snacks]:
            INSERT/UPDATE hst_mess_attendance: student_id, status='on_leave'

  generateGatePassPdf(LeavePass $pass): string
    └── DomPDF render → returns PDF path; sets is_gate_pass_printed=1

  generateLeaveRegisterPdf(array $filters): string
    └── DomPDF render of filtered leave register report
```

**LeavePassService::approve() — 8-step pseudocode:**
```
approve(LeavePass $pass, User $warden): void
  Step 1: Validate $pass->status === 'pending' — throw if not
  Step 2: Validate $warden has 'hostel.leave.approve' permission for this hostel/floor
  Step 3: DB::transaction() begins
  Step 4: UPDATE hst_leave_passes:
            status='approved', approved_by=$warden->id, approved_at=now()
  Step 5: markAttendanceForLeave($pass):
            → For each date in [$pass->from_date ... $pass->to_date]:
                For each shift (morning, evening, night):
                  Fetch or create hst_attendance session (hostel, date, shift)
                  INSERT/UPDATE hst_attendance_entries:
                    student_id=$pass->student_id, status='leave'
                  HstAttendanceService::computeAndStoreCounts($session)
  Step 6: markMessAttendanceForLeave($pass):
            → For each date in date range:
                For each meal (breakfast, lunch, dinner, snacks):
                  INSERT/UPDATE hst_mess_attendance:
                    student_id=$pass->student_id, status='on_leave'
  Step 7: DB::transaction() commits
  Step 8: Dispatch SendHstNotificationJob(new LeavePassApproved($pass))
            → queued (does NOT block response)
```

---

### 3. HstAttendanceService
**File:** `HstAttendanceService.php`
**Depends on:** *(none)*
**Fires:** `HostelAbsenceDetected` (per absent student not on leave)

```
Key Methods:

  createSession(int $hostelId, Carbon $date, string $shift,
                int $markedBy): HstAttendance
    └── upsert on UNIQUE (hostel_id, attendance_date, shift) — returns
        existing session if already created (idempotent)

  bulkMarkPresent(HstAttendance $session, array $studentIds): void
    └── Batch INSERT hst_attendance_entries status='present';
        chunked at 100; calls computeAndStoreCounts() once at end

  markEntry(HstAttendance $session, int $studentId, string $status): void
    └── Single upsert on UNIQUE (attendance_id, student_id);
        if status='absent' AND student not on approved leave →
          dispatch HostelAbsenceDetected event

  computeAndStoreCounts(HstAttendance $session): void
    └── COUNT entries by status; UPDATE session row with
        present_count, absent_count, leave_count, late_count
        (never aggregated on page load — stored at save time)

  lockSession(HstAttendance $session, User $warden): void
    └── Only Chief Warden (hostel.attendance.lock); sets is_locked=1;
        can be called > 24h after attendance_date

  isEditable(HstAttendance $session): bool
    └── Returns true if within 24h of attendance_date OR warden is Chief Warden
```

---

### 4. IncidentService
**File:** `IncidentService.php`
**Depends on:** *(none)*
**Fires:** `HostelIncidentRecorded`

```
Key Methods:

  record(array $data, User $warden): HstIncident
    └── INSERT hst_incidents; if severity IN (moderate, serious) →
        dispatches HostelIncidentRecorded event → parent notification;
        if serious → sets is_escalated=1, escalated_at=now()

  createAutoIncident(LeavePass $pass, string $type): HstIncident
    └── INSERT hst_incidents with is_auto_generated=1;
        type='late_arrival' (from LeavePassService on late return)

  escalate(HstIncident $incident, User $warden): void
    └── Sets is_escalated=1, escalated_at=now(); dispatches
        HostelIncidentRecorded (re-fires to notify Principal)

  notifyParent(HstIncident $incident): void
    └── Direct dispatch of HostelIncidentRecorded if not already fired

  generateWarningLetter(HstIncident $incident): string
    └── DomPDF render; sets warning_letter_sent=1, warning_letter_date=today();
        returns PDF path

  checkRepeatedOffender(int $studentId, int $academicSessionId): bool
    └── COUNT(incidents) ≥ 3 in session → returns true;
        caller marks student on dashboard repeated_offender flag (BR-HST-022)
```

---

### 5. HostelFeeService
**File:** `HostelFeeService.php`
**Depends on:** `StudentFeeService` (from StudentFee module — injected via interface)
**Fires:** *(no events — direct service-to-service calls only)*

```
Key Methods:

  lookupFeeStructure(int $hostelId, string $roomType, string $mealPlan,
                     int $academicSessionId): HstFeeStructure
    └── Finds matching record; throws FeeStructureNotFoundException if none

  calculateMonthlyFee(HstFeeStructure $structure): array
    └── Returns breakdown: room_rent + mess_charge + electricity +
        laundry + security_deposit

  calculateProratedAmount(HstFeeStructure $structure,
                          Carbon $fromDate): float
    └── Formula: (monthly_rate / 30) × remaining_days_in_month
        where remaining = days_in_month - fromDate->day + 1 (BR-HST-011)

  calculateVacatingRefund(Allotment $allotment,
                          Carbon $vacatingDate): float
    └── Refund = (monthly_rate / 30) × unused_days_remaining_in_month

  calculateRoomChangeDifferential(Allotment $old,
                                  Allotment $new): float
    └── Difference in room rates for remaining days in current month;
        can be positive (upgrade) or negative (downgrade)

  pushFeeDemand(Allotment $allotment): void
    └── Calls StudentFeeService::createFeeDemand() within tenant context;
        pushes room_rent, mess_charge, electricity, laundry as separate
        fee items to fin_fee_head_master — NO direct DB write from HST to fin_*

  pushDamageCharge(HstRoomInventory $item, Student $student): void
    └── Calls StudentFeeService::createFeeDemand() for damage recovery charge

  getFeeDefaulters(): array
    └── Calls StudentFeeService::getDefaulters() filtered by hostel fee head types
```

---

### 6. HstComplaintService
**File:** `HstComplaintService.php`
**Depends on:** *(none)*
**Fires:** *(no events — escalation notification handled by SendHstComplaintEscalationJob)*

```
Key Methods:

  create(array $data): HstComplaint
    └── INSERT hst_complaints; sets sla_due_at = computeSlaDeadline($data['priority'])

  assign(HstComplaint $complaint, int $staffUserId): void
    └── Sets assigned_to=$staffUserId, status='in_progress'

  resolve(HstComplaint $complaint, string $notes, User $warden): void
    └── Sets resolution_notes, resolved_at=now(), resolved_by, status='resolved'

  escalate(HstComplaint $complaint): void
    └── Sets is_escalated=1, escalated_at=now(), status='escalated';
        triggers notification to Chief Warden

  checkSlaBreaches(): int
    └── Called by SendHstComplaintEscalationJob hourly;
        finds complaints WHERE status NOT IN (resolved, closed)
          AND sla_due_at < NOW()
          AND is_escalated = 0;
        calls escalate() on each; returns count escalated

  computeSlaDeadline(string $priority): Carbon
    └── urgent/high → NOW() + 48 hours
        medium → NOW() + 72 hours
        low → NOW() + 7 days
        (BR-HST-020)
```

---

### 7. SickBayService
**File:** `SickBayService.php`
**Depends on:** `HstAttendanceService`
**Fires:** `SickBayAdmissionRecorded`, `SickBayDischarged`

```
Key Methods:

  admit(array $data, User $nurse): HstSickBayLog
    └── Checks sick_bay_capacity (hst_hostels.sick_bay_capacity) not exceeded;
        INSERT hst_sick_bay_logs; calls HstAttendanceService to auto-mark
        current shift attendance as 'sick_bay' for student;
        dispatches SickBayAdmissionRecorded → parent notification

  updateTreatmentNotes(HstSickBayLog $log, string $notes, ?string $diagnosis): void
    └── Updates nurse_notes, diagnosis on log

  discharge(HstSickBayLog $log, array $data, User $nurse): void
    └── Sets discharge_datetime=now(), discharge_notes, discharge_status,
        discharged_by; dispatches SickBayDischarged → parent notification;
        resumes normal attendance tracking for student

  setHospitalReferral(HstSickBayLog $log, ?int $hpcRecordId): void
    └── Sets is_hospital_referred=1, hpc_record_id=$hpcRecordId;
        NOTE: hpc_record_id is a soft FK — NO DB FK constraint exists;
        HPC module reads this column on its side

  getCurrentOccupancy(int $hostelId): Collection
    └── Returns hst_sick_bay_logs WHERE discharge_datetime IS NULL
        AND hostel_id=$hostelId (current inpatients)
```

---

## Section 3 — FormRequest Inventory (27 FormRequests)

> Namespace: `Modules\Hostel\app\Http\Requests`

### Infrastructure FormRequests

| Class | Controller Method | Key Validation Rules |
|-------|------------------|---------------------|
| `StoreHostelRequest` | HostelController@store/update | `name` required max:150; `type` in:boys,girls,mixed; `sick_bay_capacity` integer min:0; `warden_id` nullable exists:sys_users,id |
| `StoreFloorRequest` | FloorController@store/update | `hostel_id` required exists:hst_hostels,id; `floor_number` integer min:0; `floor_number` unique:hst_floors (scoped to hostel_id) |
| `StoreRoomRequest` | RoomController@store/update | `floor_id` required exists:hst_floors,id; `room_number` required max:20; unique:hst_rooms (scoped to floor_id); `room_type` in:single,double,triple,dormitory; `capacity` integer min:1 max:50 |
| `StoreBedRequest` | BedController@store/update | `room_id` required exists:hst_rooms,id; `bed_label` required max:20; unique:hst_beds (scoped to room_id); `status` in:available,occupied,maintenance; `condition` in:good,fair,poor |
| `StoreRoomInventoryRequest` | RoomController@storeInventory/updateInventory | `room_id` required exists:hst_rooms,id; `item_name` required max:255; `quantity` integer min:1; `condition` in:good,fair,poor,under_repair,disposed; `repair_status` in:none,pending,under_repair,repaired,written_off |

### Warden FormRequests

| Class | Controller Method | Key Validation Rules |
|-------|------------------|---------------------|
| `StoreWardenAssignmentRequest` | WardenAssignmentController@store/update | `user_id` required exists:sys_users,id; `hostel_id` required exists:hst_hostels,id; `floor_id` nullable exists:hst_floors,id; `assignment_type` in:chief,block,floor,assistant; `effective_from` required date; `effective_to` nullable date after:effective_from |

### Allotment FormRequests

| Class | Controller Method | Key Validation Rules |
|-------|------------------|---------------------|
| `StoreAllotmentRequest` | AllotmentController@store/update | `student_id` required exists:std_students,id; `bed_id` required exists:hst_beds,id; `academic_session_id` required exists:sch_academic_term,id; `allotment_date` required date; `meal_plan` required in:full_board,lunch_only,dinner_only,none |
| `TransferAllotmentRequest` | AllotmentController@transfer | `target_bed_id` required exists:hst_beds,id; `reason` required string; custom rule: target_bed status must be 'available' |
| `BulkVacateRequest` | AllotmentController@bulkVacate | `academic_session_id` required exists:sch_academic_term,id; `confirmation_text` required in:CONFIRM (exact string — irreversible action gate) |
| `StoreRoomChangeRequest` | RoomChangeRequestController@store | `allotment_id` required exists:hst_allotments,id; custom rule: allotment status must be 'active'; `reason` required min:10; `requested_room_id` nullable exists:hst_rooms,id |

### Attendance FormRequests

| Class | Controller Method | Key Validation Rules |
|-------|------------------|---------------------|
| `StoreHstAttendanceRequest` | HstAttendanceController@store/update | `hostel_id` required exists:hst_hostels,id; `attendance_date` required date not_in_future; `shift` required in:morning,evening,night; `marked_by` required exists:sys_users,id |
| `BulkMarkAttendanceRequest` | HstAttendanceController@bulkMark/storeEntries | `attendance_id` required exists:hst_attendance,id; `entries` required array min:1; `entries.*.student_id` required exists:std_students,id; `entries.*.status` required in:present,absent,leave,home,late,sick_bay |
| `StoreMovementLogRequest` | MovementLogController@store | `student_id` required exists:std_students,id; `hostel_id` required exists:hst_hostels,id; `movement_type` required in:out,in; `movement_date` required date; `out_time` required_if:movement_type,out time; `purpose` required in:leave,outing,emergency,medical,other |

### Leave Pass FormRequests

| Class | Controller Method | Key Validation Rules |
|-------|------------------|---------------------|
| `StoreLeavePassRequest` | LeavePassController@store/update | `student_id` required exists:std_students,id; `from_date` required date; `to_date` required date after_or_equal:from_date; `leave_type` required in:home,emergency,medical,festival,vacation,other; `destination` required max:255; `parent_contact` nullable max:20 |
| `ApproveLeavePassRequest` | LeavePassController@approve | Custom rule: leave pass status must be 'pending' |
| `MarkReturnedRequest` | LeavePassController@markReturned | `actual_return_date` required date; Custom rule: leave pass status must be 'approved' |

### Incident FormRequests

| Class | Controller Method | Key Validation Rules |
|-------|------------------|---------------------|
| `StoreIncidentRequest` | IncidentController@store/update | `student_id` required exists:std_students,id; `hostel_id` required exists:hst_hostels,id; `incident_date` required date; `incident_type` required max:100; `severity` required in:minor,moderate,serious; `description` required min:10 |

### Mess FormRequests

| Class | Controller Method | Key Validation Rules |
|-------|------------------|---------------------|
| `StoreMessMenuRequest` | MessMenuController@store/update | `hostel_id` required exists:hst_hostels,id; `academic_term_id` required exists:sch_academic_term,id; `week_start_date` required date; Custom rule: week_start_date must be a Monday; `day_of_week` required in:monday,tuesday,wednesday,thursday,friday,saturday,sunday; `meal_type` required in:breakfast,lunch,dinner,snacks; `menu_items_json` required array |
| `StoreSpecialDietRequest` | SpecialDietController@store/update | `student_id` required exists:std_students,id; `hostel_id` required exists:hst_hostels,id; `diet_type` required in:diabetic,jain_vegetarian,gluten_free,nut_allergy,religious_fasting,custom; `effective_from` required date; `effective_to` nullable date after:effective_from; `notes` nullable |
| `StoreMessAttendanceRequest` | MessAttendanceController@store | `hostel_id` required exists:hst_hostels,id; `attendance_date` required date; `meal_type` required in:breakfast,lunch,dinner,snacks; `student_id` required exists:std_students,id; `status` required in:present,absent,on_leave,opted_out |
| `BulkMessAttendanceRequest` | MessAttendanceController@bulkStore | `hostel_id` required exists:hst_hostels,id; `attendance_date` required date; `meal_type` required in:breakfast,lunch,dinner,snacks; `entries` required array min:1; `entries.*.student_id` required exists:std_students,id; `entries.*.status` required in:present,absent,on_leave,opted_out |

### Fee FormRequests

| Class | Controller Method | Key Validation Rules |
|-------|------------------|---------------------|
| `StoreHstFeeStructureRequest` | HstFeeController@store/update | `hostel_id` required exists:hst_hostels,id; `academic_term_id` required exists:sch_academic_term,id; `room_type` required in:single,double,triple,dormitory; `meal_plan` required in:full_board,lunch_only,dinner_only,none; `room_rent_monthly` required numeric min:0; `effective_from` required date |

### Complaint FormRequests

| Class | Controller Method | Key Validation Rules |
|-------|------------------|---------------------|
| `StoreHstComplaintRequest` | HstComplaintController@store/update | `hostel_id` required exists:hst_hostels,id; `category` required in:maintenance,electrical,plumbing,cleanliness,security,food,other; `subject` required max:255; `description` required min:10; `priority` required in:low,medium,high,urgent; `room_id` nullable exists:hst_rooms,id |
| `ResolveComplaintRequest` | HstComplaintController@resolve | `resolution_notes` required min:10; Custom rule: complaint status must be in:open,in_progress,escalated |

### Visitor & Sick Bay FormRequests

| Class | Controller Method | Key Validation Rules |
|-------|------------------|---------------------|
| `StoreVisitorLogRequest` | VisitorLogController@store/update | `hostel_id` required exists:hst_hostels,id; `student_id` required exists:std_students,id; `visitor_name` required max:255; `relationship` required in:parent,guardian,sibling,relative,other; `visit_date` required date; `in_time` required date_format:H:i; `id_proof_type` nullable max:50; `id_proof_last4` nullable digits:4 max:4 *(never store full ID number)* |
| `StoreSickBayRequest` | SickBayController@store/update | `hostel_id` required exists:hst_hostels,id; `student_id` required exists:std_students,id; `admission_datetime` required date; `presenting_symptoms` required min:5; `attended_by` required exists:sys_users,id |
| `DischargeSickBayRequest` | SickBayController@discharge | `discharge_notes` nullable; `discharge_status` required in:recovered,referred,hospitalized; Custom rule: sick bay log must have discharge_datetime IS NULL (not already discharged); `hpc_record_id` nullable integer *(set only if discharge_status=referred/hospitalized)* |

---

## Section 4 — Blade View Inventory (~65 Views)

> Namespace: `resources/views/hostel/` (within Hostel module)

### Dashboard (1 view)
| View File | Route Name | Controller@Method | Description |
|-----------|-----------|------------------|-------------|
| `dashboard/index.blade.php` | `hostel.dashboard` | `HstDashboardController@index` | KPI cards: occupancy, attendance, pending passes, open incidents, sick bay count, fee defaulters |

### Infrastructure — Hostel (3 views)
| View File | Route Name | Controller@Method | Description |
|-----------|-----------|------------------|-------------|
| `hostels/index.blade.php` | `hostel.hostels.index` | `HostelController@index` | Hostel list with occupancy bar |
| `hostels/form.blade.php` | `hostel.hostels.store/update` | `HostelController@store/update` | Create/edit hostel with facility list |
| `hostels/show.blade.php` | `hostel.hostels.show` | `HostelController@show` | Hostel detail with floors + room type stats |

### Infrastructure — Floor & Room & Bed (6 views)
| View File | Route Name | Controller@Method | Description |
|-----------|-----------|------------------|-------------|
| `floors/index.blade.php` | `hostel.floors.index` | `FloorController@index` | Floor list per hostel |
| `floors/form.blade.php` | `hostel.floors.store/update` | `FloorController@store/update` | Create/edit floor |
| `rooms/index.blade.php` | `hostel.rooms.index` | `RoomController@index` | Room list with occupancy; cascading hostel→floor filter |
| `rooms/form.blade.php` | `hostel.rooms.store/update` | `RoomController@store/update` | Create/edit room + amenities |
| `rooms/inventory.blade.php` | `hostel.rooms.inventory.index` | `RoomController@roomInventory` | Per-room furniture/fixtures with condition badges |
| `beds/index.blade.php` | `hostel.beds.index` | `BedController@index` | Bed grid with status colour-coding |

### Warden Assignments (3 views)
| View File | Route Name | Controller@Method | Description |
|-----------|-----------|------------------|-------------|
| `wardens/index.blade.php` | `hostel.wardens.index` | `WardenAssignmentController@index` | Active warden assignments per hostel/floor |
| `wardens/form.blade.php` | `hostel.wardens.store/update` | `WardenAssignmentController@store/update` | Assign warden with date range |
| `wardens/history.blade.php` | `hostel.wardens.show` | `WardenAssignmentController@show` | Assignment history log |

### Allotment (7 views)
| View File | Route Name | Controller@Method | Description |
|-----------|-----------|------------------|-------------|
| `allotments/index.blade.php` | `hostel.allotments.index` | `AllotmentController@index` | Active allotment list with filters |
| `allotments/form.blade.php` | `hostel.allotments.store` | `AllotmentController@store` | **Cascading dropdowns:** Hostel→Floor→Room (availability)→Bed; inline gender check; fee preview |
| `allotments/show.blade.php` | `hostel.allotments.show` | `AllotmentController@show` | Allotment detail with history |
| `allotments/transfer.blade.php` | `hostel.allotments.transfer` | `AllotmentController@transfer` | Transfer form with fee differential preview |
| `allotments/availability.blade.php` | `hostel.allotments.availability` | `AllotmentController@availability` | Bed availability grid: hostel→floor→room view |
| `allotments/bulk-vacate.blade.php` | `hostel.allotments.bulk-vacate` | `AllotmentController@bulkVacate` | Bulk vacate wizard with CONFIRM input gate (irreversible) |
| `room-change-requests/index.blade.php` | `hostel.rcr.index` | `RoomChangeRequestController@index` | Room change request list with approve/reject actions |

### Attendance (5 views)
| View File | Route Name | Controller@Method | Description |
|-----------|-----------|------------------|-------------|
| `attendance/index.blade.php` | `hostel.attendance.index` | `HstAttendanceController@index` | Attendance session list by date/shift/hostel |
| `attendance/form.blade.php` | `hostel.attendance.store` | `HstAttendanceController@store` | Create session (hostel + date + shift selector) |
| `attendance/entry-sheet.blade.php` | `hostel.attendance.entries` | `HstAttendanceController@entries` | **Tablet-optimised bulk-mark sheet** — Alpine.js one-tap per student; individual exception toggles; count preview before save |
| `attendance/show.blade.php` | `hostel.attendance.show` | `HstAttendanceController@show` | Session detail with summary counts |
| `movement-log/index.blade.php` | `hostel.movement.index` | `MovementLogController@index` | In-out register |
| `movement-log/pending.blade.php` | `hostel.movement.pending` | `MovementLogController@pendingReturns` | **Pending returns dashboard** — polls `/movement-log/pending` every 60s; overdue in red |

### Leave Pass (7 views)
| View File | Route Name | Controller@Method | Description |
|-----------|-----------|------------------|-------------|
| `leave-passes/index.blade.php` | `hostel.leave.index` | `LeavePassController@index` | Leave pass list with status filters |
| `leave-passes/form.blade.php` | `hostel.leave.store` | `LeavePassController@store` | Apply leave pass form |
| `leave-passes/show.blade.php` | `hostel.leave.show` | `LeavePassController@show` | Pass detail with approve/reject/return actions |
| `leave-passes/approve.blade.php` | `hostel.leave.approve` | `LeavePassController@approve` | **Approval form** — shows date range, attendance sessions to be auto-marked (count preview), confirm button |
| `leave-passes/calendar.blade.php` | `hostel.leave.calendar` | `LeavePassController@calendar` | Calendar view of all active/pending passes |
| `leave-passes/gate-pass-pdf.blade.php` | `hostel.leave.print` | `LeavePassController@print` | DomPDF gate pass template |
| `leave-passes/register-pdf.blade.php` | `hostel.reports.leave-register` | `HstReportController@leaveRegister` | DomPDF leave register report template |

### Incidents (5 views)
| View File | Route Name | Controller@Method | Description |
|-----------|-----------|------------------|-------------|
| `incidents/index.blade.php` | `hostel.incidents.index` | `IncidentController@index` | Incident list with severity badges + repeated offender flag |
| `incidents/form.blade.php` | `hostel.incidents.store` | `IncidentController@store` | Record incident with media upload |
| `incidents/show.blade.php` | `hostel.incidents.show` | `IncidentController@show` | Incident detail with escalation + notify parent buttons |
| `incidents/warning-letter-pdf.blade.php` | `hostel.incidents.warning-letter` | `IncidentController@printWarningLetter` | DomPDF warning letter template |
| `incidents/media-upload.blade.php` | `hostel.incidents.media.store` | `IncidentController@storeMedia` | Media attachment panel (partial / modal) |

### Mess (7 views)
| View File | Route Name | Controller@Method | Description |
|-----------|-----------|------------------|-------------|
| `mess/menus/index.blade.php` | `hostel.mess.menus.index` | `MessMenuController@index` | Menu list by academic term + hostel |
| `mess/menus/weekly-grid.blade.php` | `hostel.mess.menus.show` | `MessMenuController@show` | **7-day × 4-meal grid** with copy-week button |
| `mess/menus/form.blade.php` | `hostel.mess.menus.store` | `MessMenuController@store` | Create/edit menu entry |
| `mess/diets/index.blade.php` | `hostel.mess.diets.index` | `SpecialDietController@index` | Special diet assignments per student |
| `mess/diets/form.blade.php` | `hostel.mess.diets.store` | `SpecialDietController@store` | Assign diet with effective dates |
| `mess/attendance/sheet.blade.php` | `hostel.mess.attendance.index` | `MessAttendanceController@index` | Meal attendance bulk-mark sheet |
| `mess/attendance/monthly-report.blade.php` | `hostel.mess.attendance.report` | `MessAttendanceController@monthlyReport` | Monthly mess attendance summary for billing |

### Fee Structures (4 views)
| View File | Route Name | Controller@Method | Description |
|-----------|-----------|------------------|-------------|
| `fee/index.blade.php` | `hostel.fee.index` | `HstFeeController@index` | Fee structures list by academic term |
| `fee/form.blade.php` | `hostel.fee.store` | `HstFeeController@store` | Create/edit fee structure per room type + meal plan |
| `fee/calculate.blade.php` | `hostel.fee.calculate` | `HstFeeController@calculate` | Prorated fee calculator (interactive) |
| `fee/defaulters.blade.php` | `hostel.fee.defaulters` | `HstFeeController@defaulters` | Fee defaulter list |

### Complaints (4 views)
| View File | Route Name | Controller@Method | Description |
|-----------|-----------|------------------|-------------|
| `complaints/index.blade.php` | `hostel.complaints.index` | `HstComplaintController@index` | Complaint list with SLA status badges |
| `complaints/form.blade.php` | `hostel.complaints.store` | `HstComplaintController@store` | Lodge complaint |
| `complaints/show.blade.php` | `hostel.complaints.show` | `HstComplaintController@show` | Complaint detail with assign/resolve/escalate |
| `complaints/resolve-form.blade.php` | `hostel.complaints.resolve` | `HstComplaintController@resolve` | Resolution form with notes |

### Visitor Log (3 views)
| View File | Route Name | Controller@Method | Description |
|-----------|-----------|------------------|-------------|
| `visitors/index.blade.php` | `hostel.visitors.index` | `VisitorLogController@index` | Visitor log with in/out status |
| `visitors/form.blade.php` | `hostel.visitors.store` | `VisitorLogController@store` | Log visitor entry — ID proof stores last 4 digits only |
| `visitors/show.blade.php` | `hostel.visitors.show` | `VisitorLogController@show` | Visitor detail with checkout button |

### Sick Bay (4 views)
| View File | Route Name | Controller@Method | Description |
|-----------|-----------|------------------|-------------|
| `sick-bay/index.blade.php` | `hostel.sickbay.index` | `SickBayController@index` | Sick bay log list |
| `sick-bay/form.blade.php` | `hostel.sickbay.store` | `SickBayController@store` | Admit student (symptoms, attending nurse) |
| `sick-bay/current.blade.php` | `hostel.sickbay.current` | `SickBayController@current` | Current inpatients list (no discharge_datetime) |
| `sick-bay/discharge-form.blade.php` | `hostel.sickbay.discharge` | `SickBayController@discharge` | Discharge form with HPC record ID field (optional soft link) |

### Reports (11 views)
| View File | Route Name | Controller@Method | Description |
|-----------|-----------|------------------|-------------|
| `reports/occupancy.blade.php` | `hostel.reports.occupancy` | `HstReportController@occupancy` | Hostel-wise occupancy report |
| `reports/attendance.blade.php` | `hostel.reports.attendance` | `HstReportController@attendance` | Attendance summary by date range |
| `reports/leave-register.blade.php` | `hostel.reports.leave-register` | `HstReportController@leaveRegister` | Leave register (DomPDF printable) |
| `reports/movement.blade.php` | `hostel.reports.movement` | `HstReportController@movement` | In-out movement register |
| `reports/fee-defaulters.blade.php` | `hostel.reports.fee-defaulters` | `HstReportController@feeDefaulters` | Fee defaulters list |
| `reports/incidents.blade.php` | `hostel.reports.incidents` | `HstReportController@incidents` | Incident register with severity breakdown |
| `reports/mess-attendance.blade.php` | `hostel.reports.mess-attendance` | `HstReportController@messAttendance` | Mess attendance summary |
| `reports/room-inventory.blade.php` | `hostel.reports.room-inventory` | `HstReportController@roomInventory` | Room inventory condition report |
| `reports/visitors.blade.php` | `hostel.reports.visitors` | `HstReportController@visitors` | Visitor log report |
| `reports/sick-bay.blade.php` | `hostel.reports.sick-bay` | `HstReportController@sickBay` | Sick bay admission history |
| `reports/export.blade.php` | `hostel.reports.export` | `HstReportController@export` | Export format selector (CSV/PDF) |

### Shared Partials
| Partial | Used In | Purpose |
|---------|---------|---------|
| `_hostel-filter.blade.php` | all list views | Hostel selector dropdown |
| `_floor-selector.blade.php` | allotment, attendance | Hostel→Floor cascading selector |
| `_student-search.blade.php` | allotment, leave, sick bay | Student autocomplete search |
| `_pagination.blade.php` | all paginated lists | Standard pagination |

**Total views: ~68** (65 main + 4 partials)

---

## Section 5 — Complete Route List (~67 Routes)

All routes in `routes/tenant.php`.
**Base middleware:** `['auth', 'tenant', 'EnsureTenantHasModule:Hostel']`
**+Warden scope:** `['WardenScopeMiddleware']` added where noted.

### 6.1 Infrastructure Routes
| Method | URI | Route Name | Controller@Method | Middleware | FR |
|--------|-----|-----------|------------------|-----------|-----|
| GET | `hostel/dashboard` | `hostel.dashboard` | `HstDashboardController@index` | base | HST-020 |
| GET | `hostel/hostels` | `hostel.hostels.index` | `HostelController@index` | base | HST-001 |
| POST | `hostel/hostels` | `hostel.hostels.store` | `HostelController@store` | base | HST-001 |
| GET | `hostel/hostels/{hostel}` | `hostel.hostels.show` | `HostelController@show` | base | HST-001 |
| PUT | `hostel/hostels/{hostel}` | `hostel.hostels.update` | `HostelController@update` | base | HST-001 |
| DELETE | `hostel/hostels/{hostel}` | `hostel.hostels.destroy` | `HostelController@destroy` | base | HST-001 |
| POST | `hostel/hostels/{hostel}/toggle-status` | `hostel.hostels.toggle-status` | `HostelController@toggleStatus` | base | HST-001 |
| GET | `hostel/floors` | `hostel.floors.index` | `FloorController@index` | base | HST-001 |
| POST | `hostel/floors` | `hostel.floors.store` | `FloorController@store` | base | HST-001 |
| GET | `hostel/floors/{floor}` | `hostel.floors.show` | `FloorController@show` | base | HST-001 |
| PUT | `hostel/floors/{floor}` | `hostel.floors.update` | `FloorController@update` | base | HST-001 |
| DELETE | `hostel/floors/{floor}` | `hostel.floors.destroy` | `FloorController@destroy` | base | HST-001 |
| GET | `hostel/rooms` | `hostel.rooms.index` | `RoomController@index` | base | HST-002 |
| POST | `hostel/rooms` | `hostel.rooms.store` | `RoomController@store` | base | HST-002 |
| GET | `hostel/rooms/{room}` | `hostel.rooms.show` | `RoomController@show` | base | HST-002 |
| PUT | `hostel/rooms/{room}` | `hostel.rooms.update` | `RoomController@update` | base | HST-002 |
| DELETE | `hostel/rooms/{room}` | `hostel.rooms.destroy` | `RoomController@destroy` | base | HST-002 |
| POST | `hostel/rooms/{room}/toggle-status` | `hostel.rooms.toggle-status` | `RoomController@toggleStatus` | base | HST-002 |
| GET | `hostel/rooms/{room}/inventory` | `hostel.rooms.inventory.index` | `RoomController@roomInventory` | base | HST-019 |
| POST | `hostel/rooms/{room}/inventory` | `hostel.rooms.inventory.store` | `RoomController@storeInventory` | base | HST-019 |
| PUT | `hostel/rooms/{room}/inventory/{item}` | `hostel.rooms.inventory.update` | `RoomController@updateInventory` | base | HST-019 |
| DELETE | `hostel/rooms/{room}/inventory/{item}` | `hostel.rooms.inventory.destroy` | `RoomController@destroyInventory` | base | HST-019 |
| GET | `hostel/beds` | `hostel.beds.index` | `BedController@index` | base | HST-003 |
| POST | `hostel/beds` | `hostel.beds.store` | `BedController@store` | base | HST-003 |
| GET | `hostel/beds/{bed}` | `hostel.beds.show` | `BedController@show` | base | HST-003 |
| PUT | `hostel/beds/{bed}` | `hostel.beds.update` | `BedController@update` | base | HST-003 |
| DELETE | `hostel/beds/{bed}` | `hostel.beds.destroy` | `BedController@destroy` | base | HST-003 |
| POST | `hostel/beds/{bed}/toggle-maintenance` | `hostel.beds.toggle-maintenance` | `BedController@toggleMaintenance` | base | HST-003 |

### 6.2 Warden Routes
| Method | URI | Route Name | Controller@Method | Middleware | FR |
|--------|-----|-----------|------------------|-----------|-----|
| GET | `hostel/warden-assignments` | `hostel.wardens.index` | `WardenAssignmentController@index` | base | HST-016 |
| POST | `hostel/warden-assignments` | `hostel.wardens.store` | `WardenAssignmentController@store` | base | HST-016 |
| GET | `hostel/warden-assignments/{assignment}` | `hostel.wardens.show` | `WardenAssignmentController@show` | base | HST-016 |
| PUT | `hostel/warden-assignments/{assignment}` | `hostel.wardens.update` | `WardenAssignmentController@update` | base | HST-016 |
| POST | `hostel/warden-assignments/{assignment}/end` | `hostel.wardens.end` | `WardenAssignmentController@end` | base | HST-016 |

### 6.3 Allotment Routes
| Method | URI | Route Name | Controller@Method | Middleware | FR |
|--------|-----|-----------|------------------|-----------|-----|
| GET | `hostel/allotments` | `hostel.allotments.index` | `AllotmentController@index` | base + Warden | HST-005 |
| POST | `hostel/allotments` | `hostel.allotments.store` | `AllotmentController@store` | base + Warden | HST-005 |
| GET | `hostel/allotments/{allotment}` | `hostel.allotments.show` | `AllotmentController@show` | base + Warden | HST-005 |
| PUT | `hostel/allotments/{allotment}` | `hostel.allotments.update` | `AllotmentController@update` | base + Warden | HST-005 |
| POST | `hostel/allotments/{allotment}/vacate` | `hostel.allotments.vacate` | `AllotmentController@vacate` | base + Warden | HST-005 |
| POST | `hostel/allotments/{allotment}/transfer` | `hostel.allotments.transfer` | `AllotmentController@transfer` | base + Warden | HST-005 |
| POST | `hostel/allotments/bulk-vacate` | `hostel.allotments.bulk-vacate` | `AllotmentController@bulkVacate` | base | HST-005 |
| GET | `hostel/allotments/availability` | `hostel.allotments.availability` | `AllotmentController@availability` | base + Warden | HST-005 |
| GET | `hostel/room-change-requests` | `hostel.rcr.index` | `RoomChangeRequestController@index` | base | HST-006 |
| POST | `hostel/room-change-requests` | `hostel.rcr.store` | `RoomChangeRequestController@store` | base | HST-006 |
| GET | `hostel/room-change-requests/{rcr}` | `hostel.rcr.show` | `RoomChangeRequestController@show` | base | HST-006 |
| POST | `hostel/room-change-requests/{rcr}/approve` | `hostel.rcr.approve` | `RoomChangeRequestController@approve` | base | HST-006 |
| POST | `hostel/room-change-requests/{rcr}/reject` | `hostel.rcr.reject` | `RoomChangeRequestController@reject` | base | HST-006 |

### 6.4 Attendance Routes
| Method | URI | Route Name | Controller@Method | Middleware | FR |
|--------|-----|-----------|------------------|-----------|-----|
| GET | `hostel/attendance` | `hostel.attendance.index` | `HstAttendanceController@index` | base + Warden | HST-007 |
| POST | `hostel/attendance` | `hostel.attendance.store` | `HstAttendanceController@store` | base + Warden | HST-007 |
| GET | `hostel/attendance/{session}` | `hostel.attendance.show` | `HstAttendanceController@show` | base + Warden | HST-007 |
| PUT | `hostel/attendance/{session}` | `hostel.attendance.update` | `HstAttendanceController@update` | base + Warden | HST-007 |
| GET | `hostel/attendance/{session}/entries` | `hostel.attendance.entries` | `HstAttendanceController@entries` | base + Warden | HST-007 |
| POST | `hostel/attendance/{session}/entries` | `hostel.attendance.store-entries` | `HstAttendanceController@storeEntries` | base + Warden | HST-007 |
| POST | `hostel/attendance/{session}/bulk-mark` | `hostel.attendance.bulk-mark` | `HstAttendanceController@bulkMark` | base + Warden | HST-007 |
| POST | `hostel/attendance/{session}/lock` | `hostel.attendance.lock` | `HstAttendanceController@lock` | base | HST-007 |
| GET | `hostel/movement-log` | `hostel.movement.index` | `MovementLogController@index` | base | HST-008 |
| POST | `hostel/movement-log` | `hostel.movement.store` | `MovementLogController@store` | base | HST-008 |
| GET | `hostel/movement-log/{log}` | `hostel.movement.show` | `MovementLogController@show` | base | HST-008 |
| POST | `hostel/movement-log/{log}/return` | `hostel.movement.return` | `MovementLogController@recordReturn` | base | HST-008 |
| GET | `hostel/movement-log/pending` | `hostel.movement.pending` | `MovementLogController@pendingReturns` | base | HST-008 |

### 6.5 Leave Pass Routes
| Method | URI | Route Name | Controller@Method | Middleware | FR |
|--------|-----|-----------|------------------|-----------|-----|
| GET | `hostel/leave-passes` | `hostel.leave.index` | `LeavePassController@index` | base + Warden | HST-009 |
| POST | `hostel/leave-passes` | `hostel.leave.store` | `LeavePassController@store` | base + Warden | HST-009 |
| GET | `hostel/leave-passes/{pass}` | `hostel.leave.show` | `LeavePassController@show` | base + Warden | HST-009 |
| PUT | `hostel/leave-passes/{pass}` | `hostel.leave.update` | `LeavePassController@update` | base + Warden | HST-009 |
| POST | `hostel/leave-passes/{pass}/approve` | `hostel.leave.approve` | `LeavePassController@approve` | base + Warden | HST-009 |
| POST | `hostel/leave-passes/{pass}/reject` | `hostel.leave.reject` | `LeavePassController@reject` | base + Warden | HST-009 |
| POST | `hostel/leave-passes/{pass}/return` | `hostel.leave.return` | `LeavePassController@markReturned` | base + Warden | HST-009 |
| POST | `hostel/leave-passes/{pass}/cancel` | `hostel.leave.cancel` | `LeavePassController@cancel` | base + Warden | HST-009 |
| GET | `hostel/leave-passes/{pass}/print` | `hostel.leave.print` | `LeavePassController@print` | base | HST-009 |
| GET | `hostel/leave-passes/calendar` | `hostel.leave.calendar` | `LeavePassController@calendar` | base | HST-009 |

### 6.6 Incident Routes
| Method | URI | Route Name | Controller@Method | Middleware | FR |
|--------|-----|-----------|------------------|-----------|-----|
| GET | `hostel/incidents` | `hostel.incidents.index` | `IncidentController@index` | base + Warden | HST-010 |
| POST | `hostel/incidents` | `hostel.incidents.store` | `IncidentController@store` | base + Warden | HST-010 |
| GET | `hostel/incidents/{incident}` | `hostel.incidents.show` | `IncidentController@show` | base + Warden | HST-010 |
| PUT | `hostel/incidents/{incident}` | `hostel.incidents.update` | `IncidentController@update` | base + Warden | HST-010 |
| POST | `hostel/incidents/{incident}/escalate` | `hostel.incidents.escalate` | `IncidentController@escalate` | base | HST-010 |
| GET | `hostel/incidents/{incident}/warning-letter` | `hostel.incidents.warning-letter` | `IncidentController@printWarningLetter` | base | HST-010 |
| POST | `hostel/incidents/{incident}/notify-parent` | `hostel.incidents.notify-parent` | `IncidentController@notifyParent` | base | HST-010 |
| POST | `hostel/incidents/{incident}/media` | `hostel.incidents.media.store` | `IncidentController@storeMedia` | base | HST-010 |
| DELETE | `hostel/incidents/{incident}/media/{media}` | `hostel.incidents.media.destroy` | `IncidentController@destroyMedia` | base | HST-010 |

### 6.7 Mess Routes
| Method | URI | Route Name | Controller@Method | Middleware | FR |
|--------|-----|-----------|------------------|-----------|-----|
| GET | `hostel/mess/menus` | `hostel.mess.menus.index` | `MessMenuController@index` | base | HST-011 |
| POST | `hostel/mess/menus` | `hostel.mess.menus.store` | `MessMenuController@store` | base | HST-011 |
| GET | `hostel/mess/menus/{menu}` | `hostel.mess.menus.show` | `MessMenuController@show` | base | HST-011 |
| PUT | `hostel/mess/menus/{menu}` | `hostel.mess.menus.update` | `MessMenuController@update` | base | HST-011 |
| DELETE | `hostel/mess/menus/{menu}` | `hostel.mess.menus.destroy` | `MessMenuController@destroy` | base | HST-011 |
| POST | `hostel/mess/menus/copy-week` | `hostel.mess.menus.copy-week` | `MessMenuController@copyWeek` | base | HST-011 |
| GET | `hostel/mess/special-diets` | `hostel.mess.diets.index` | `SpecialDietController@index` | base | HST-012 |
| POST | `hostel/mess/special-diets` | `hostel.mess.diets.store` | `SpecialDietController@store` | base | HST-012 |
| GET | `hostel/mess/special-diets/{diet}` | `hostel.mess.diets.show` | `SpecialDietController@show` | base | HST-012 |
| PUT | `hostel/mess/special-diets/{diet}` | `hostel.mess.diets.update` | `SpecialDietController@update` | base | HST-012 |
| DELETE | `hostel/mess/special-diets/{diet}` | `hostel.mess.diets.destroy` | `SpecialDietController@destroy` | base | HST-012 |
| GET | `hostel/mess/attendance` | `hostel.mess.attendance.index` | `MessAttendanceController@index` | base | HST-012 |
| POST | `hostel/mess/attendance` | `hostel.mess.attendance.store` | `MessAttendanceController@store` | base | HST-012 |
| POST | `hostel/mess/attendance/bulk` | `hostel.mess.attendance.bulk` | `MessAttendanceController@bulkStore` | base | HST-012 |
| GET | `hostel/mess/attendance/report` | `hostel.mess.attendance.report` | `MessAttendanceController@monthlyReport` | base | HST-012 |

### 6.8–6.12 Fee, Complaint, Visitor, Sick Bay, Reports
| Method | URI | Route Name | Controller@Method | Middleware | FR |
|--------|-----|-----------|------------------|-----------|-----|
| GET | `hostel/fee-structures` | `hostel.fee.index` | `HstFeeController@index` | base | HST-013 |
| POST | `hostel/fee-structures` | `hostel.fee.store` | `HstFeeController@store` | base | HST-013 |
| GET | `hostel/fee-structures/{structure}` | `hostel.fee.show` | `HstFeeController@show` | base | HST-013 |
| PUT | `hostel/fee-structures/{structure}` | `hostel.fee.update` | `HstFeeController@update` | base | HST-013 |
| DELETE | `hostel/fee-structures/{structure}` | `hostel.fee.destroy` | `HstFeeController@destroy` | base | HST-013 |
| GET | `hostel/fee-structures/calculate` | `hostel.fee.calculate` | `HstFeeController@calculate` | base | HST-013 |
| GET | `hostel/fee-structures/defaulters` | `hostel.fee.defaulters` | `HstFeeController@defaulters` | base | HST-013 |
| GET | `hostel/complaints` | `hostel.complaints.index` | `HstComplaintController@index` | base | HST-014 |
| POST | `hostel/complaints` | `hostel.complaints.store` | `HstComplaintController@store` | base | HST-014 |
| GET | `hostel/complaints/{complaint}` | `hostel.complaints.show` | `HstComplaintController@show` | base | HST-014 |
| PUT | `hostel/complaints/{complaint}` | `hostel.complaints.update` | `HstComplaintController@update` | base | HST-014 |
| POST | `hostel/complaints/{complaint}/assign` | `hostel.complaints.assign` | `HstComplaintController@assign` | base | HST-014 |
| POST | `hostel/complaints/{complaint}/resolve` | `hostel.complaints.resolve` | `HstComplaintController@resolve` | base | HST-014 |
| POST | `hostel/complaints/{complaint}/escalate` | `hostel.complaints.escalate` | `HstComplaintController@escalate` | base | HST-014 |
| GET | `hostel/visitors` | `hostel.visitors.index` | `VisitorLogController@index` | base | HST-017 |
| POST | `hostel/visitors` | `hostel.visitors.store` | `VisitorLogController@store` | base | HST-017 |
| GET | `hostel/visitors/{visitor}` | `hostel.visitors.show` | `VisitorLogController@show` | base | HST-017 |
| PUT | `hostel/visitors/{visitor}` | `hostel.visitors.update` | `VisitorLogController@update` | base | HST-017 |
| POST | `hostel/visitors/{visitor}/checkout` | `hostel.visitors.checkout` | `VisitorLogController@checkout` | base | HST-017 |
| GET | `hostel/sick-bay` | `hostel.sickbay.index` | `SickBayController@index` | base | HST-018 |
| POST | `hostel/sick-bay` | `hostel.sickbay.store` | `SickBayController@store` | base | HST-018 |
| GET | `hostel/sick-bay/{log}` | `hostel.sickbay.show` | `SickBayController@show` | base | HST-018 |
| PUT | `hostel/sick-bay/{log}` | `hostel.sickbay.update` | `SickBayController@update` | base | HST-018 |
| POST | `hostel/sick-bay/{log}/discharge` | `hostel.sickbay.discharge` | `SickBayController@discharge` | base | HST-018 |
| GET | `hostel/sick-bay/current` | `hostel.sickbay.current` | `SickBayController@current` | base | HST-018 |
| GET | `hostel/reports/occupancy` | `hostel.reports.occupancy` | `HstReportController@occupancy` | base | HST-021 |
| GET | `hostel/reports/attendance` | `hostel.reports.attendance` | `HstReportController@attendance` | base | HST-021 |
| GET | `hostel/reports/leave-register` | `hostel.reports.leave-register` | `HstReportController@leaveRegister` | base | HST-021 |
| GET | `hostel/reports/movement` | `hostel.reports.movement` | `HstReportController@movement` | base | HST-021 |
| GET | `hostel/reports/fee-defaulters` | `hostel.reports.fee-defaulters` | `HstReportController@feeDefaulters` | base | HST-021 |
| GET | `hostel/reports/incidents` | `hostel.reports.incidents` | `HstReportController@incidents` | base | HST-021 |
| GET | `hostel/reports/mess-attendance` | `hostel.reports.mess-attendance` | `HstReportController@messAttendance` | base | HST-021 |
| GET | `hostel/reports/room-inventory` | `hostel.reports.room-inventory` | `HstReportController@roomInventory` | base | HST-019 |
| GET | `hostel/reports/visitors` | `hostel.reports.visitors` | `HstReportController@visitors` | base | HST-017 |
| GET | `hostel/reports/sick-bay` | `hostel.reports.sick-bay` | `HstReportController@sickBay` | base | HST-018 |
| GET | `hostel/reports/{type}/export` | `hostel.reports.export` | `HstReportController@export` | base | HST-021 |

**Total routes: 67**

---

## Section 6 — Implementation Phases (7 Phases)

---

### Phase 1 — Infrastructure (K1: Rooms & Beds)
**FRs covered:** HST-001 (Hostel Setup), HST-002 (Room Management), HST-003 (Bed Management), HST-004 (Room Inventory)

| Artifact | Files |
|----------|-------|
| **Controllers** | `HstDashboardController` (stub — full in Phase 7), `HostelController`, `FloorController`, `RoomController` (+ inventory sub-routes), `BedController` |
| **Services** | *(none — Phase 1 is CRUD only)* |
| **Models** | `Hostel`, `Floor`, `Room`, `Bed`, `RoomInventory` |
| **FormRequests** | `StoreHostelRequest`, `StoreFloorRequest`, `StoreRoomRequest`, `StoreBedRequest`, `StoreRoomInventoryRequest` |
| **Seeders** | `HstRoomTypeSeeder`, `HstIncidentTypeSeeder`, `HstSeederRunner` |
| **Policies** | `HostelPolicy` |
| **Views** | ~10: hostel list/form/show, floor list/form, room list/form + inventory, bed index |
| **Routes** | 28 (all 6.1 infrastructure routes) |
| **Tests** | `HostelInfrastructureTest` |

**Phase 1 key tasks:**
- Run `HST_Migration.php` — create all 21 tables
- Run `HstSeederRunner` — seed room type labels + incident types
- Implement cascading Hostel→Floor→Room dropdowns in allotment form (stub; full in Phase 2)
- `hst_hostels.current_occupancy` starts at 0 (updated by AllotmentService in Phase 2)
- `hst_rooms.current_occupancy` starts at 0 (same)

---

### Phase 2 — Warden & Allotment (K2)
**FRs covered:** HST-005 (Student Allotment), HST-006 (Room Change Requests), HST-016 (Warden Management)

| Artifact | Files |
|----------|-------|
| **Controllers** | `WardenAssignmentController`, `AllotmentController`, `RoomChangeRequestController` |
| **Services** | `AllotmentService` (full — gender check, occupancy update, fee validation, generated-column duplicate handling, transfer, bulk-vacate) |
| **Models** | `WardenAssignment`, `Allotment`, `RoomChangeRequest` |
| **FormRequests** | `StoreWardenAssignmentRequest`, `StoreAllotmentRequest`, `TransferAllotmentRequest`, `BulkVacateRequest`, `StoreRoomChangeRequest` |
| **Middleware** | `WardenScopeMiddleware` — inject floor_id scope into Eloquent query builder; block/floor wardens see only assigned floors; Chief Warden full-hostel access |
| **Views** | ~11: warden list/form/history, allotment list/form/show/transfer/availability/bulk-vacate, room-change-request list |
| **Routes** | 13 (6.2 + 6.3) |
| **Tests** | `AllotmentTest`, `RoomChangeRequestTest` |

**Phase 2 key tasks:**
- `AllotmentService::create()` — 12-step pseudocode; catch MySQL 1062 on generated columns
- `WardenScopeMiddleware` registered in `Modules/Hostel/app/Http/Middleware/`
- Bulk vacate requires `confirmation_text = 'CONFIRM'` + audit log write to `sys_activity_logs`
- `HostelFeeService::pushFeeDemand()` called AFTER `DB::transaction()` commits
- Stub `HostelFeeService::pushFeeDemand()` in Phase 2 (full implementation in Phase 6)

---

### Phase 3 — Attendance (K3)
**FRs covered:** HST-007 (Hostel Attendance), HST-008 (Movement Log)

| Artifact | Files |
|----------|-------|
| **Controllers** | `HstAttendanceController`, `MovementLogController` |
| **Services** | `HstAttendanceService` (create session + bulk mark + compute counts + lock) |
| **Models** | `HstAttendance`, `HstAttendanceEntry`, `MovementLog` |
| **FormRequests** | `StoreHstAttendanceRequest`, `BulkMarkAttendanceRequest`, `StoreMovementLogRequest` |
| **Events** | `HostelAbsenceDetected` (dispatch per absent student not on leave) |
| **Views** | ~6: attendance session list/form/entry-sheet/show, movement-log list, pending-returns dashboard |
| **Routes** | 13 (6.4) |
| **Tests** | `HstAttendanceTest` |

**Phase 3 key tasks:**
- Attendance entry sheet: tablet-optimised Alpine.js UI, one-tap per student
- `computeAndStoreCounts()` called ONCE at the end of bulk-mark — never per row
- `UNIQUE(hostel_id, attendance_date, shift)` — upsert pattern; no duplicate sessions
- `isEditable()` enforces 24h lock (Chief Warden can override)
- Pending returns dashboard polls every 60 seconds via Alpine.js/Livewire
- `HostelAbsenceDetected` — dispatch only for students not on approved leave

---

### Phase 4 — Leave Pass (K3b)
**FRs covered:** HST-009 (Leave Pass Management)

| Artifact | Files |
|----------|-------|
| **Controllers** | `LeavePassController` |
| **Services** | `LeavePassService` (full — `DB::transaction` approve, markReturned, auto-incident, DomPDF) |
| **Models** | `LeavePass` |
| **FormRequests** | `StoreLeavePassRequest`, `ApproveLeavePassRequest`, `MarkReturnedRequest` |
| **Events** | `LeavePassApproved`, `LeavePassRejected`, `StudentReturned` |
| **Jobs** | `SendHstNotificationJob` (generic — used by all hostel notification events; queued) |
| **Views** | ~7: leave pass list/form/show/approve/calendar/gate-pass-PDF/leave-register-PDF |
| **Routes** | 10 (6.5) |
| **Tests** | `LeavePassTest` |

**Phase 4 key tasks:**
- Approval form shows preview: "This will auto-mark attendance for X sessions and Y meals"
- `DB::transaction()` wraps: pass update + ALL attendance entries + ALL mess attendance (all atomic)
- `SendHstNotificationJob` is queued → approval response is not blocked
- Late return: `actual_return_date > to_date` → `IncidentService::createAutoIncident()` → `hst_leave_passes.late_return_incident_id` set
- DomPDF gate pass template includes: student name, hostel, dates, destination, warden signature block
- Cancel: reverts attendance 'leave' → 'absent'; reverts mess 'on_leave' → 'absent'

---

### Phase 5 — Incidents & Mess (K4 + Discipline)
**FRs covered:** HST-010 (Incident Management), HST-011 (Mess Menu), HST-012 (Mess Attendance & Special Diets)

| Artifact | Files |
|----------|-------|
| **Controllers** | `IncidentController`, `MessMenuController`, `SpecialDietController`, `MessAttendanceController` |
| **Services** | `IncidentService` (record, auto-incident, escalate, DomPDF warning letter) |
| **Models** | `Incident`, `IncidentMedia`, `MessWeeklyMenu`, `SpecialDiet`, `MessAttendance` |
| **FormRequests** | `StoreIncidentRequest`, `StoreMessMenuRequest`, `StoreSpecialDietRequest`, `StoreMessAttendanceRequest`, `BulkMessAttendanceRequest` |
| **Events** | `HostelIncidentRecorded` (moderate/serious only), `HostelAbsenceDetected` (fires from attendance service) |
| **Views** | ~12: incident list/form/show/warning-letter-PDF + incident media upload, mess weekly-grid/copy-week, diet assignment, meal attendance bulk-sheet, monthly-report |
| **Routes** | 15 (6.6 + 6.7) |
| **Tests** | `IncidentTest`, `MessMenuTest` |

**Phase 5 key tasks:**
- Minor incidents: no auto-notification
- Moderate/Serious: `HostelIncidentRecorded` event dispatched → parent SMS/push
- Serious: additionally set `is_escalated=1`, prompt for Principal escalation
- Auto-incidents (from late return): `is_auto_generated=1`, same severity rules apply
- `checkRepeatedOffender()` — 3+ incidents in academic year → flag student on dashboard
- Mess weekly grid: 7-day × 4-meal matrix; copy-week clones previous week's menu
- Special diet auto-marks mess attendance as 'special' for flagged students
- `BulkMessAttendanceRequest`: batch marks all students for one meal session

---

### Phase 6 — Fee, Complaints, Visitor & Sick Bay (K5 + K6 + Additional)
**FRs covered:** HST-013 (Hostel Fee), HST-014 (Complaints), HST-015 (Waitlist — integrated with Allotment), HST-017 (Visitor Log), HST-018 (Sick Bay), HST-019 (Room Inventory damage charges)

| Artifact | Files |
|----------|-------|
| **Controllers** | `HstFeeController`, `HstComplaintController`, `VisitorLogController`, `SickBayController` |
| **Services** | `HostelFeeService` (full — StudentFee push, proration, defaulters), `HstComplaintService` (SLA computation, escalation), `SickBayService` (admit/discharge/HPC link) |
| **Models** | `HstFeeStructure`, `HstComplaint`, `VisitorLog`, `SickBayLog` |
| **FormRequests** | `StoreHstFeeStructureRequest`, `StoreHstComplaintRequest`, `ResolveComplaintRequest`, `StoreVisitorLogRequest`, `StoreSickBayRequest`, `DischargeSickBayRequest` |
| **Events** | `SickBayAdmissionRecorded`, `SickBayDischarged` |
| **Jobs** | `SendHstComplaintEscalationJob` (hourly scheduler — checks SLA breaches) |
| **Artisan Commands** | `hst:escalate-complaints` (calls `HstComplaintService::checkSlaBreaches()`) |
| **Views** | ~14: fee list/form/calculate/defaulters, complaint list/form/show/resolve, visitor list/form/show, sick-bay list/form/current/discharge |
| **Routes** | 21 (6.8–6.11) |
| **Tests** | `HstFeeTest`, `HstComplaintTest`, `VisitorLogTest`, `SickBayTest` |

**Phase 6 key tasks:**
- `HostelFeeService::pushFeeDemand()` calls `StudentFeeService` — NO direct `fin_*` DB writes from HST
- Prorated fee formula: `(monthly_rate / 30) × remaining_days_in_month` (BR-HST-011)
- `StoreVisitorLogRequest`: `id_proof_last4` is `digits:4` — never store full ID
- `SickBayService::admit()`: checks `hst_hostels.sick_bay_capacity` not exceeded
- `SickBayService::setHospitalReferral()`: sets `is_hospital_referred=1` + `hpc_record_id` — **no FK constraint** (soft reference)
- `SendHstComplaintEscalationJob::handle()` calls `HstComplaintService::checkSlaBreaches()`
- SLA: urgent/high → 48h; medium → 72h; low → 7 days

---

### Phase 7 — Dashboard (Complete) & Reports
**FRs covered:** HST-020 (Dashboard), HST-021 (Reports)

| Artifact | Files |
|----------|-------|
| **Controllers** | `HstDashboardController` (complete — all KPIs), `HstReportController` (all 11 report types + export) |
| **Services** | *(reads from all hst_* tables; no new service — DomPDF for PDF reports; `fputcsv()` for CSV exports — no external package)* |
| **Models** | *(no new)* |
| **Views** | ~11 report views + 1 export (see Section 4 Reports) |
| **Routes** | 11 (6.12) |
| **Artisan Commands** | `hst:send-attendance-alerts` (daily), `hst:flag-overdue-movements` (every 30 min) |
| **Tests** | Report output format tests; dashboard KPI accuracy tests |

**Phase 7 key tasks:**
- Dashboard KPIs read only from denormalized columns — no aggregation on page load
- CSV exports use `fputcsv()` to `php://temp` stream (no external library)
- PDF reports use existing DomPDF (already in project)
- `hst:send-attendance-alerts`: if attendance compliance < 90% for any hostel → notify Chief Warden
- `hst:flag-overdue-movements`: query `hst_movement_log` WHERE `actual_return_time IS NULL AND expected_return_time < NOW()`

---

## Section 7 — Seeder Execution Order

```
php artisan module:seed Hostel --class=HstSeederRunner

  Step 1: HstRoomTypeSeeder
          → Seeds 4 room type display configs to sys_settings
          → Keys: hostel.room_type_labels.single
                  hostel.room_type_labels.double
                  hostel.room_type_labels.triple
                  hostel.room_type_labels.dormitory
          → No dependencies

  Step 2: HstIncidentTypeSeeder
          → Seeds 6 incident types to sys_settings
          → Key: hostel.incident_types (JSON array)
          → 1 is_auto_generated=true (late_arrival), 5 manual
          → No dependencies
```

**For test runs:** Both seeders are required minimum. Ensure test DB has:
- `std_students` factory available (cross-module FK in allotments, attendance, leave pass, incidents, mess, sick bay)
- `sch_academic_term` factory available (cross-module FK in allotments, fee structures, mess menus, attendance)
- `sys_users` factory available (warden IDs, approved_by, created_by)

**Artisan Scheduled Commands** (register in `routes/console.php`):
```php
// routes/console.php

Schedule::command('hst:escalate-complaints')
    ->hourly()
    ->description('HST: Auto-escalate complaints past SLA due_at');

Schedule::command('hst:send-attendance-alerts')
    ->dailyAt('07:00')
    ->description('HST: Send daily attendance compliance alerts if below 90%');

Schedule::command('hst:flag-overdue-movements')
    ->everyThirtyMinutes()
    ->description('HST: Flag students with overdue movement log returns');
```

---

## Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; PHPUnit for Unit tests.

### Feature Test Setup (Pest)
```php
// All feature test files use:
uses(Tests\TestCase::class, Illuminate\Foundation\Testing\RefreshDatabase::class);

// Standard test helpers:
Event::fake([
    LeavePassApproved::class,
    LeavePassRejected::class,
    StudentReturned::class,
    HostelIncidentRecorded::class,
    HostelAbsenceDetected::class,
    SickBayAdmissionRecorded::class,
    SickBayDischarged::class,
]);

Queue::fake();  // for SendHstNotificationJob

Bus::fake();    // for Artisan command tests (hst:escalate-complaints, etc.)

// HostelFeeService mock in allotment tests:
$this->mock(HostelFeeService::class, function ($mock) {
    $mock->shouldReceive('pushFeeDemand')->once()->andReturn(true);
    $mock->shouldReceive('validateFeeStructureExists')->andReturn(true);
});
```

### Feature Test File Summary (11 files)

| Test File | Path | Tests | Key Scenarios |
|-----------|------|-------|---------------|
| `HostelInfrastructureTest` | `tests/Feature/Hostel/HostelInfrastructureTest.php` | 8 | Create hostel; create floor; create room; create beds; gender type validation; capacity auto-update on allotment; deactivation blocked when active allotments exist |
| `AllotmentTest` | `tests/Feature/Hostel/AllotmentTest.php` | 10 | Allot student to bed; **prevent double-allotment on same bed** (MySQL 1062 → user error); **prevent two active allotments per student**; gender mismatch rejection; vacate reverts bed status + occupancy; transfer executes correctly; bulk-vacate with audit log; fee structure validation |
| `RoomChangeRequestTest` | `tests/Feature/Hostel/RoomChangeRequestTest.php` | 5 | Submit request; approve executes AllotmentService::transfer(); reject with reason; fee recalculation on approval; pending request blocks another |
| `LeavePassTest` | `tests/Feature/Hostel/LeavePassTest.php` | 9 | Apply leave pass; approve dispatches LeavePassApproved; **attendance auto-marked 'leave' on approval** (all shifts in date range); **mess auto-marked 'on_leave' on approval**; mark returned; **late return auto-creates incident with is_auto_generated=1**; cancel reverts attendance + mess; transaction failure rolls back all 3 operations |
| `HstAttendanceTest` | `tests/Feature/Hostel/HstAttendanceTest.php` | 8 | Create session; bulk mark present 500 students in < 3s; mark individual exceptions; **duplicate session returns existing** (no 422); **summary counts computed correctly from DB row** (not aggregated); lock after 24h; Chief Warden can edit locked session; absent student fires HostelAbsenceDetected |
| `IncidentTest` | `tests/Feature/Hostel/IncidentTest.php` | 7 | Record minor (no notification); record moderate (HostelIncidentRecorded dispatched); record serious (event + is_escalated=1); **auto-incident from late return** (is_auto_generated=1); escalate; generate warning letter; **3+ incidents flags repeated offender** |
| `MessMenuTest` | `tests/Feature/Hostel/MessMenuTest.php` | 7 | Create weekly menu; duplicate menu slot blocked; copy-week function; special diet assignment; **auto-absent on leave approval** (mess attendance set 'on_leave' atomically); special diet served flag; monthly report data |
| `HstFeeTest` | `tests/Feature/Hostel/HstFeeTest.php` | 6 | Configure fee structure; calculate monthly fee on allotment; **prorated mid-month allotment** `(rate/30 × remaining_days)`; **prorated vacating refund**; room change differential; fee structure missing → allotment blocked |
| `HstComplaintTest` | `tests/Feature/Hostel/HstComplaintTest.php` | 6 | Lodge complaint; assign to staff; resolve with notes; **SLA breach triggers escalation** via SendHstComplaintEscalationJob; urgent → 48h SLA; low → 7 day SLA |
| `SickBayTest` | `tests/Feature/Hostel/SickBayTest.php` | 7 | Admit student; **attendance auto-marked 'sick_bay'**; **parent notification dispatched** (SickBayAdmissionRecorded); discharge; SickBayDischarged event; hospital referral sets hpc_record_id (no FK error); capacity check |
| `VisitorLogTest` | `tests/Feature/Hostel/VisitorLogTest.php` | 4 | Log visitor; checkout; out-of-hours visitor requires reason; ID proof stores last 4 digits only (full number not stored) |

### Unit Test File Summary (4 files)

| Test File | Path | Key Scenarios |
|-----------|------|---------------|
| `AllotmentServiceTest` | `tests/Unit/Hostel/AllotmentServiceTest.php` | Bed availability check logic (available/occupied/reserved/maintenance); gender validation (boys-student + girls-hostel = exception; boys + co-ed = allowed); double-allotment detection (both bed UNIQUE and student UNIQUE) |
| `LeavePassServiceTest` | `tests/Unit/Hostel/LeavePassServiceTest.php` | Date range calculation for attendance auto-mark (3-day leave = 9 attendance entries for 3 shifts × 3 days); late return detection (actual_return_date > to_date = true); date range edge case (same-day leave = 1 day) |
| `HostelFeeServiceTest` | `tests/Unit/Hostel/HostelFeeServiceTest.php` | **Prorated calculation mid-month allotment** — allotment on 15th of 30-day month → 16/30 of monthly rate; **mid-month vacate refund** — vacate on 20th → 10/30 refund; room change differential = new_rate - old_rate for remaining days |
| `HstComplaintServiceTest` | `tests/Unit/Hostel/HstComplaintServiceTest.php` | `computeSlaDeadline('urgent')` = NOW() + 48h; `computeSlaDeadline('high')` = NOW() + 48h; `computeSlaDeadline('medium')` = NOW() + 72h; `computeSlaDeadline('low')` = NOW() + 7 days |

### Policy Test
```php
// tests/Feature/Hostel/HostelPolicyTest.php
// Chief Warden can approve leave (hostel.leave.approve)
// Block/Floor Warden can only see own-floor allotments (WardenScopeMiddleware)
// Mess Supervisor has mess-only access (hostel.mess.* but NOT hostel.allotment.*)
// School Admin has full access
```

### Factory Requirements
```php
HostelFactory      — type, sick_bay_capacity, current_occupancy=0
FloorFactory       — hostel_id, floor_number
RoomFactory        — floor_id, room_type, capacity, current_occupancy=0, status='available'
BedFactory         — room_id, bed_label, status='available', condition='good'
AllotmentFactory   — student_id, bed_id, academic_session_id, status='active', meal_plan='full_board'
LeavePassFactory   — student_id, allotment_id, from_date, to_date, status='pending', leave_type='home'
```

### Critical Test Coverage Checklist
- [x] Dual active-allotment prevention: attempt to allot same bed twice → DuplicateEntry; attempt to allot same student twice → DuplicateEntry
- [x] Gender restriction: boys student + girls hostel = rejected
- [x] Leave approval transaction: atomicity — simulate mid-transaction failure → ALL 3 operations rolled back
- [x] Late return → auto-incident: `is_auto_generated=1`, `late_return_incident_id` set on leave pass
- [x] Attendance UNIQUE: duplicate session creation returns existing (not 422)
- [x] Attendance counts: `present_count` verified from DB row — NOT aggregated in query
- [x] SLA breach: complaint past `sla_due_at` gets escalated by `SendHstComplaintEscalationJob`
- [x] Sick bay attendance: student admitted → auto-marked 'sick_bay'; parent notification dispatched
- [x] Prorated fee: mid-month allotment = `(rate/30) × remaining_days`; mid-month vacate = refund
- [x] Warden scope: block warden cannot view allotments/attendance for floor not in their assignment
- [x] `hst_sick_bay_log.hpc_record_id`: setting a value generates NO FK constraint error (no FK exists)
- [x] `Event::fake()` used in: leave pass, incident, absence, sick bay, complaint escalation tests
- [x] `Queue::fake()` used in: `SendHstNotificationJob` tests
- [x] `Bus::fake()` used in: `hst:escalate-complaints`, `hst:send-attendance-alerts` Artisan tests

---

## Appendix — FR Coverage Matrix

| FR | Name | Phase | Controller(s) | Service(s) | Tables Used |
|----|------|-------|--------------|-----------|-------------|
| HST-001 | Hostel Setup | 1 | HostelController, FloorController | — | hst_hostels, hst_floors |
| HST-002 | Room Management | 1 | RoomController | — | hst_rooms |
| HST-003 | Bed Management | 1 | BedController | — | hst_beds |
| HST-004 | Room Inventory | 1 | RoomController (nested) | HostelFeeService (damage charge) | hst_room_inventory |
| HST-005 | Student Allotment | 2 | AllotmentController | AllotmentService, HostelFeeService | hst_allotments, hst_beds, hst_rooms, hst_hostels |
| HST-006 | Room Change Requests | 2 | RoomChangeRequestController | AllotmentService | hst_room_change_requests, hst_allotments |
| HST-007 | Hostel Attendance | 3 | HstAttendanceController | HstAttendanceService | hst_attendance, hst_attendance_entries |
| HST-008 | Movement Log | 3 | MovementLogController | — | hst_movement_log |
| HST-009 | Leave Pass | 4 | LeavePassController | LeavePassService, IncidentService | hst_leave_passes, hst_attendance_entries, hst_mess_attendance |
| HST-010 | Incident Management | 5 | IncidentController | IncidentService | hst_incidents, hst_incident_media |
| HST-011 | Mess Menu | 5 | MessMenuController | — | hst_mess_weekly_menus |
| HST-012 | Mess Attendance | 5 | SpecialDietController, MessAttendanceController | LeavePassService (auto-mark) | hst_special_diets, hst_mess_attendance |
| HST-013 | Hostel Fee | 6 | HstFeeController | HostelFeeService | hst_fee_structures |
| HST-014 | Complaint Register | 6 | HstComplaintController | HstComplaintService | hst_complaints |
| HST-015 | Fee Validation | 2/6 | AllotmentController | AllotmentService, HostelFeeService | hst_fee_structures, hst_allotments |
| HST-016 | Warden Management | 2 | WardenAssignmentController | — | hst_warden_assignments |
| HST-017 | Visitor Log | 6 | VisitorLogController | — | hst_visitor_log |
| HST-018 | Sick Bay | 6 | SickBayController | SickBayService | hst_sick_bay_log |
| HST-019 | Room Inventory | 1/6 | RoomController | HostelFeeService | hst_room_inventory |
| HST-020 | Dashboard | 7 | HstDashboardController | all (reads denormalized cols) | hst_hostels, hst_attendance, hst_allotments, hst_incidents, hst_sick_bay_log |
| HST-021 | Reports | 7 | HstReportController | DomPDF, fputcsv | all hst_* tables |
