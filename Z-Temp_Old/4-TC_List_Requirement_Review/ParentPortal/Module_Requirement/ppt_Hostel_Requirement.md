# ParentPortal — Hostel (Requirement Analysis)

## 1. Module Overview

| Attribute | Details |
|-----------|---------|
| **Feature Name** | Hostel Information |
| **Alias** | ppt_hostel |
| **Module** | ParentPortal (PPT) + Hostel Module |
| **Route Prefix** | `/parent-portal/hostel` |
| **Primary Controller** | `ParentHostelController` |
| **Primary Models** | `Allotment`, `HstAttendanceEntry`, `LeavePass`, `MessWeeklyMenu`, `MessBill`, `FeeDemand`, `LaundryTicket`, `RoomChangeRequest` (from Hostel module) |
| **Base Table(s)** | `hst_allotments`, `hst_attendance_entries`, `hst_leave_passes`, `hst_mess_weekly_menus`, `hst_mess_bills`, `hst_fee_demands`, `hst_laundry_tickets`, `hst_room_change_requests` |
| **FRD Reference** | REQ-PPT-019 |
| **Priority** | P2 (Could Have) |
| **Type** | Read-only |

## 2. Purpose

Provide parents with a comprehensive read-only view of their child's hostel life, including accommodation details, hostel attendance, leave passes, mess menu, mess bills, fee demands, laundry tickets, and room change requests.

## 3. Business Rules

| ID | Rule | Enforced In |
|----|------|-------------|
| BR-PPT-001 | Hostel data scoped to parent's active linked child | `ParentContextService::resolveChild()` |
| — | Only active and allotted allocations shown | `Allotment::where('is_active', true)->where('is_alloted', true)` |
| — | Mess menu shown only for child's hostel | `MessWeeklyMenu::where('hostel_id', $allotment->bed->room->hostel_id)` |

## 4. Screen Inventory

| Screen | Route Name | Controller Method | View | Description |
|--------|-----------|-------------------|------|-------------|
| Hostel Info | `parent-portal.hostel.index` | `index()` | `hostel/index` | 8 sections: allocation, attendance, leave, mess menu, bills, fees, laundry, room requests |

## 5. Validation Rules

No FormRequests used — read-only feature with no data submission.

## 6. Technical Implementation

### 6.1 Dependencies

| Dependency | Type | Purpose |
|-----------|------|---------|
| `Modules\Hostel\Models\Allotment` | Model | Current hostel room allocation |
| `Modules\Hostel\Models\HstAttendanceEntry` | Model | Daily hostel attendance |
| `Modules\Hostel\Models\LeavePass` | Model | Hostel leave permissions |
| `Modules\Hostel\Models\MessWeeklyMenu` | Model | Weekly mess menu |
| `Modules\Hostel\Models\MessBill` | Model | Mess billing |
| `Modules\Hostel\Models\FeeDemand` | Model | Hostel fee demands |
| `Modules\Hostel\Models\LaundryTicket` | Model | Laundry service tickets |
| `Modules\Hostel\Models\RoomChangeRequest` | Model | Room change applications |
| `ParentContextService` | Service | Resolves active child |

### 6.2 Key Implementation Details

- **Allotment Chain:** `Allotment → Bed → Room → Hostel` (with Floor and BedType).
  - `Allotment::with(['bed.room.hostel', 'bed.room.floor', 'bed.bedType'])`
- **Sections Loaded:**
  1. **Accommodation:** Building name, floor, room number, bed number, bed type
  2. **Attendance:** Hostel attendance records with session and status labels
  3. **Leave Passes:** Leave pass records with status labels
  4. **Mess Menu:** Weekly menu for child's hostel (published + active menus)
  5. **Mess Bills:** Monthly mess bills with status labels
  6. **Fee Demands:** Hostel fee demands with status labels
  7. **Laundry Tickets:** Laundry service records with status labels
  8. **Room Change Requests:** Room change history with status and requested room details
- **Graceful Empty State:** If no child or no allotment exists, all collections are empty (collect()). The view handles null/empty states.
- **Mess Menu Gating:** Only loaded if allotment exists and hostel_id is available.
- **Status Labels:** All status-dependent models eager-load `statusMaster` relationship for label resolution.

## 7. Edge Cases

| Scenario | Expected Behavior |
|----------|------------------|
| No hostel allocation for child | All sections show empty state or "Not allotted" message |
| Hostel module disabled | Graceful "Hostel module not activated" message |
| No mess menu published for current week | Mess menu section shows empty state |
| No attendance records | Attendance section shows empty state |
| No leave passes | Leave section shows empty state |
| No mess bills | Bills section shows empty state |
| Child variable is null | All collections default to `collect()` — no crash |

## 8. Known Issues / Gaps

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | FRD mentions "Room mate count shown (not names)" — not in controller data | Low | ⬜ |
| 2 | 8 separate queries executed for each section — potential performance concern for parents with multiple children | Medium | ⬜ |
| 3 | No explicit module check (EnsureTenantHasModule) — depends on route group middleware | Medium | ⬜ |
| 4 | Controllers load all data eagerly — may cause N+1 if views access additional relationships | Low | ⬜ |
| 5 | FRD classifies this as P2 but controller is fully implemented | Low | ⬜ |

## 9. Cross-Module Impact

| Module | Impact |
|--------|--------|
| Hostel | All models and tables belong to this module |
| StudentProfile | Student FK for allotment lookup |

## 10. Route Reference

```php
Route::get('/hostel', [ParentHostelController::class, 'index'])->name('hostel.index');
```

## 11. Middleware Stack

```
web → InitializeTenancyByDomain → PreventAccessFromCentralDomains
→ EnsureTenantIsActive → auth → verified → ParentPortalMiddleware
→ EnsureTenantHasModule
```

## 12. Controller Constructor Dependencies

```php
public function __construct(
    private readonly ParentContextService $context,
) {}
```

## 13. Audit Logging

- Event type: `Viewed`
- Context: student_id, student_name, module, route

## 14. Security Considerations

| Concern | Mitigation |
|---------|-----------|
| IDOR (access another child's hostel data) | ParentContextService resolves active child |
| CSRF | Not applicable (GET-only route) |

## 15. FRD Gaps

| FRD Statement | Implementation Reality | Gap |
|---------------|----------------------|-----|
| "Room mate count shown (not names)" | Not in controller data — depends on view | View-level concern |
| "Graceful not activated if HST module disabled" | Depends on route middleware | Not verified in controller |
