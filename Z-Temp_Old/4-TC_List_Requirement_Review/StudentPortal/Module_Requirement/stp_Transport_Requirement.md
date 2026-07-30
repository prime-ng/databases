# STP — Transport Information Requirement Document

---

## 1. Module / Sub-Module
- **Module:** StudentPortal (STP)
- **Sub-Module:** Services — Transport Information
- **Table Prefix:** stp_ (read-only from tpt_* tables)

---

## 2. FRD Reference
| ID | Description | Priority |
|----|------------|----------|
| REQ-STP-019 | Transport Information | P1 |
| BR-STP-001 | Data must belong to authenticated student | P0 |

---

## 3. Feature Description
Read-only display of the student's allocated transport route details, vehicle and crew assignment, and recent boarding logs. All data is consumed from the Transport module (TPT) — no STP-owned tables.

---

## 4. User Stories / Use Cases
- **As a** student, **I want to** view my assigned bus route, pickup/drop stops, driver details, **so that** I know my daily transport schedule.
- **As a** student, **I want to** view my recent boarding history **so that** I can track my attendance on the school bus.

---

## 5. Business Rules (BR)
| BR ID | Rule | Type | Enforcement |
|-------|------|------|-------------|
| BR-STP-001 | All transport data must belong to the authenticated student | Permission | Controller loads via `auth()->user()->student` chain; no cross-student data leakage |
| — | Allocation must be currently active (`active_status = true`) | Validation | Controller filter: `where('active_status', true)` |
| — | Boarding logs shown only for last 30 days | Display | Controller filter: `where('trip_date', '>=', now()->subDays(30))` |
| — | Boarding logs limited to 20 most recent entries | Display | Controller: `limit(20)` + `orderByDesc('trip_date')` |

---

## 6. Validations & Edge Cases
| Scenario | Expected Behaviour |
|----------|-------------------|
| Student has no transport allocation | `$allocation` is null; view renders empty state |
| Allocation exists but no vehicle assignment | `$vehicleAssignment` is null; vehicle/crew section hidden |
| No boarding logs in last 30 days | Empty table with "No boarding records" message |
| Student not found (`$student` is null) | All variables return empty collections; view handles gracefully |
| Active allocation has no pickup_route_id | Vehicle assignment query skipped (null-safe guard) |

---

## 7. Route Details
| Method | Route | Name | Controller Method |
|--------|-------|------|-------------------|
| GET | /transport | student-portal.transport | StudentPortalController@transport |

---

## 8. Data / Entity Reference

### A. Student Allocation
- **Model:** `Modules\Transport\Models\TptStudentAllocationJnt`
- **Table:** `tpt_student_allocations_jnt`
- **Eager loads:** `pickupRoute.shift`, `pickupRoute.pickupPointRoutes.pickupPoint`, `dropRoute.pickupPointRoutes.pickupPoint`, `pickupStop`, `dropStop`

### B. Vehicle & Crew
- **Model:** `Modules\Transport\Models\DriverRouteVehicleJnt`
- **Table:** `tpt_driver_route_vehicle_jnt`
- **Eager loads:** `vehicle`, `driver`, `helper`
- **Lookup key:** `route_id` = `allocation->pickup_route_id`

### C. Boarding Logs
- **Model:** `Modules\Transport\Models\StudentBoardingLog`
- **Table:** `tpt_boarding_logs`
- **Eager loads:** `boardingStop`, `unboardingStop`
- **Scope:** Last 30 days, max 20 records

---

## 9. Dependencies (Cross-Module)
| Module | Dependency | Type |
|--------|-----------|------|
| Transport (TPT) | TptStudentAllocationJnt, DriverRouteVehicleJnt, StudentBoardingLog | Read-only |

---

## 10. Integration / API
- No write operations; purely read-only view
- No AJAX endpoints

---

## 11. Security & Permissions
| Check | Implementation |
|-------|---------------|
| Authentication | Standard `auth` + `verified` middleware (applied at route group level) |
| Data ownership | All queries scoped to `auth()->user()->student` |
| Cross-student access | Impossible — no user-supplied IDs accepted |

---

## 12. Assumptions & Constraints
- Transport module (TPT) must be properly seeded with routes, stops, vehicle assignments
- Student must have an active transport allocation (`active_status = true`)
- Only the pickup route's vehicle assignment is shown (not the drop route's)

---

## 13. Known Issues / Gaps
| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| — | No vehicle assignment shown for drop route (only pickup route queried) | Low | Open |
| — | Boarding status values not documented; view relies on raw DB values | Low | Open |

---

## 14. Future Enhancements
| ID | Suggestion | Priority |
|----|-----------|----------|
| ENH-STP-TRN-01 | Add drop route vehicle assignment display | P3 |
| ENH-STP-TRN-02 | Add GPS live tracking link (when TPT module supports it) | P4 |
| ENH-STP-TRN-03 | Show route map with pickup/drop stops visual | P4 |

---

## 15. V1/V2 Status
- **V1:** —
- **V2:** —
- **Status:** ✅ Implemented
- **CR:** ◌

---

## 16. Revision History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 23-07-2026 | OpenCode | Initial requirement document |
