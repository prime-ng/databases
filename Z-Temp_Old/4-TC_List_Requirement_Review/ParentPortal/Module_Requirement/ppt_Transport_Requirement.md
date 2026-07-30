# ParentPortal — Transport (Requirement Analysis)

## 1. Module Overview

| Attribute | Details |
|-----------|---------|
| **Feature Name** | Transport Information |
| **Alias** | ppt_transport |
| **Module** | ParentPortal (PPT) + Transport Module |
| **Route Prefix** | `/parent-portal/transport` |
| **Primary Controller** | `ParentTransportController` |
| **Primary Model** | `TptStudentAllocationJnt` (from Transport module) |
| **Base Table(s)** | `tpt_student_route_jnt`, `tpt_routes`, `tpt_vehicles`, `tpt_stops`, `tpt_student_boarding_log` |
| **FRD Reference** | REQ-PPT-015 |
| **Priority** | P1 (Should Have) |
| **Type** | Read-only |

## 2. Purpose

Provide parents with a read-only view of their child's transport assignment, including bus route details, vehicle information, driver/helper contact details, pickup/drop points, and recent boarding history. Graceful "not activated" state if the Transport module is disabled.

## 3. Business Rules

| ID | Rule | Enforced In |
|----|------|-------------|
| BR-PPT-001 | Transport data scoped to parent's active linked child | `ParentContextService::resolveChild()` |
| — | Only active transport allocation shown | `TptStudentAllocationJnt::where('active_status', true)` |
| — | Most recent active vehicle assignment shown | `driverRouteVehicles` — ordered by latest with `is_active` filter |

## 4. Screen Inventory

| Screen | Route Name | Controller Method | View | Description |
|--------|-----------|-------------------|------|-------------|
| Transport Info | `parent-portal.transport.index` | `index()` | `transport/index` | Route, vehicle, driver, stop details + boarding log |

## 5. Validation Rules

No FormRequests used — read-only feature with no data submission.

## 6. Technical Implementation

### 6.1 Dependencies

| Dependency | Type | Purpose |
|-----------|------|---------|
| `Modules\Transport\Models\TptStudentAllocationJnt` | Model | Student-route allocation junction |
| Modules\Transport\Models\TptRoute, TptVehicle, TptDriver, TptStop | Models | Eager-loaded relationships |
| `ParentContextService` | Service | Resolves active child |

### 6.2 Key Implementation Details

- **Allocation Fetching:** Queries `TptStudentAllocationJnt` with `active_status = true` for the active child. Eager-loads:
  - `pickupRoute.shift` — Pickup route and its shift
  - `pickupRoute.pickupPointRoutes` — Route stops
  - `pickupStop` — Specific pickup stop
  - `dropRoute.shift` — Drop route and its shift
  - `dropStop` — Specific drop stop
  - `pickupRoute.driverRouteVehicles` — Active driver-route-vehicle assignment
- **Vehicle Assignment:** Gets the first (most recent) active `driverRouteVehicles` record which contains vehicle, driver, and helper details.
- **Live GPS:** `$gpsAvailable = false` and `$livePosition = null` — GPS tracking not yet implemented (tpt_live_trip table not in schema).
- **Boarding Log:** Checks if `tpt_student_boarding_log` table exists via `Schema::hasTable()`. If yes, fetches last 5 RFID boarding events.
- **Graceful Degradation:** If no allocation exists, the view should show "Transport module not activated" or similar.

### 6.3 Data Model Chains

```
TptStudentAllocationJnt
├── student_id → Student
├── pickupRoute (TptRoute)
│   ├── shift (TptShift)
│   ├── pickupPointRoutes (TptPickupPointRoute → TptStop)
│   └── driverRouteVehicles (TptDriverRouteVehicle)
│       ├── vehicle (TptVehicle)
│       ├── driver (TptDriver → User)
│       └── helper (TptHelper → User)
└── dropRoute (TptRoute)
    └── shift (TptShift)
```

## 7. Edge Cases

| Scenario | Expected Behavior |
|----------|------------------|
| No transport allocation for child | Graceful "not assigned" message |
| Transport module disabled | Graceful "not activated" message |
| tpt_student_boarding_log table missing | Boarding log section skipped (no error) |
| No active vehicle assignment (no driverRouteVehicles) | Vehicle/driver section hidden |
| Driver mobile number available | Displayed as click-to-call link |
| Multiple active vehicle assignments | Most recent one shown (latest()) |
| GPS data unavailable (always) | "Live tracking not available" shown |

## 8. Known Issues / Gaps

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | Live GPS tracking not implemented (tpt_live_trip table not in schema) | Low | ⬜ |
| 2 | Graceful "module not activated" state depends on EnsureTenantHasModule middleware | Medium | ⬜ |
| 3 | Boarding log relies on Schema::hasTable() — fragile if table exists but is empty | Low | ⬜ |
| 4 | FRD mentions boarding/exit push notification — not implemented | Low | ⬜ |

## 9. Cross-Module Impact

| Module | Impact |
|--------|--------|
| Transport | All models and tables belong to this module |
| StudentProfile | Student FK for allocation lookup |

## 10. Route Reference

```php
Route::get('/transport', [ParentTransportController::class, 'index'])->name('transport.index');
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
| IDOR (access another child's transport) | ParentContextService resolves active child |
| CSRF | Not applicable (GET-only route) |

## 15. FRD Gaps

| FRD Statement | Implementation Reality | Gap |
|---------------|----------------------|-----|
| "Live GPS status shown if available" | Not implemented (tpt_live_trip missing) | Feature not available |
| "RFID boarding/exit push notifications" | Not implemented | Feature not available |
| "Driver mobile number shown as click-to-call" | Data available but depends on view rendering | View-level |
