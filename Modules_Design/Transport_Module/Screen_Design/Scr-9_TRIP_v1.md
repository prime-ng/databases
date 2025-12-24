# Screen Design Specification: Trip Management
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document specifies the **Trip Management Module** for managing trip instances (scheduled occurrences of routes). Backed by `tpt_trip`.

### 1.2 User Roles & Permissions
| Role         | Create | View | Update | Delete | print | Export | Import |
|--------------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| PG Support   |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| School Admin |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✗    |   ✗    |
| Principal    |   ✓    |   ✓  |   ✗    |   ✗    |   ✓   |   ✗    |   ✗    |
| Teacher      |   ✗    |   ✓  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |
| Student      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |
| Parents      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |

### 1.3 Data Context

Database Table: `tpt_trip`
├── id (BIGINT PRIMARY KEY)
├── trip_date (DATE)
├── pickup_route_id (FK, nullable)
├── route_id (FK -> `tpt_route.id`)
├── vehicle_id (FK -> `tpt_vehicle.id`)
├── driver_id (FK -> `tpt_personnel.id`)
├── helper_id (FK -> `tpt_personnel.id`, nullable)
├── trip_type (ENUM: Morning/Afternoon/Evening/Custom)
├── start_time, end_time (DATETIME, nullable)
├── status (ENUM: Scheduled/Ongoing/Completed/Cancelled)
├── created_at, updated_at, deleted_at (timestamps)

---

## 2. SCREEN LAYOUTS

### 2.1 Trip List View
**Route:** `/transport/trips` or `/transport/routes/{routeId}/trips`

#### 2.1.1 Layout
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > TRIPS                                                 │
├──────────────────────────────────────────────────────────────────┤
│ [__________] [Search]  [+ New Trip]                             │
│ DATE: [Date Picker] ROUTE: [Dropdown] STATUS: [Dropdown]        │
├──────────────────────────────────────────────────────────────────┤
│ ☐ │ Date       │ Route     │ Vehicle  │ Driver    │ Type  │ Status│
│───┼────────────┼───────────┼──────────┼───────────┼───────┼──────│
│ ☐ │ 2025-12-01 │ Route A   │ BUS-101  │ Ravi Kumar│Morning│ Ongoing
│ ☐ │ 2025-12-01 │ Route B   │ VAN-22   │ Anita... │Evening│ Scheduled
│ ☐ │ 2025-11-30 │ Route A   │ BUS-101  │ Ravi Kumar│Morning│ Completed
│   │ ...        │ ...       │ ...      │ ...      │ ...   │ ...
│
│ Showing 1-10 of 87 trips                          [< 1 2 3 >]
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Create Trip (Modal)
#### 2.2.1 Layout
```
┌──────────────────────────────────────────────────┐
│ CREATE NEW TRIP                              [✕] │
├──────────────────────────────────────────────────┤
│ Trip Date *         [Date Picker]               │
│ Route *             [Dropdown ▼]                │
│ Vehicle *           [Typeahead]                 │
│ Driver *            [Typeahead]                 │
│ Helper              [Typeahead]                 │
│ Trip Type *         [Dropdown] Morning/Afternoon/Evening│
│ Start Time          [Time Picker]               │
│ End Time            [Time Picker]               │
│ Status              [Dropdown] Scheduled        │
├──────────────────────────────────────────────────┤
│         [Cancel]     [Save]  [Save & New]       │
└──────────────────────────────────────────────────┘
```

#### 2.2.2 Field Specifications

| Field | Type | Validation | Required |
|-------|------|------------|----------|
| Trip Date | Date Picker | >= Today | ✓ |
| Route | Dropdown | FK to `tpt_route` | ✓ |
| Vehicle | Typeahead | FK to `tpt_vehicle` | ✓ |
| Driver | Typeahead | FK to `tpt_personnel` | ✓ |
| Helper | Typeahead | FK to `tpt_personnel` | ✗ |
| Trip Type | Dropdown | Morning/Afternoon/Evening/Custom | ✓ |
| Start Time | Time Picker | <= End Time (if provided) | ✗ |
| End Time | Time Picker | >= Start Time | ✗ |
| Status | Dropdown | Scheduled, Ongoing, Completed, Cancelled | ✗ |

#### 2.2.3 Validation Rules

✓ `trip_date`, `route_id`, `vehicle_id`, `driver_id`, `trip_type` required.

✓ `trip_date` must be >= today (no past trips).

✓ `start_time` <= `end_time` when both provided.

✓ Status transitions enforced: Scheduled → Ongoing → Completed (or Cancelled at any step).

#### 2.2.4 Error Handling
```
1. Missing required fields
   Message: "Please fill: Trip Date, Route, Vehicle, Driver, Trip Type"

2. Invalid time range
   Message: "Start Time must be before End Time"

3. Vehicle/Driver conflict
   Message: "Selected vehicle/driver has conflict on this date/time"
```

### 2.3 View / Edit Trip (Tabbed)
**Route:** `/transport/trips/{id}`

#### 2.3.1 Layout
```
┌────────────────────────────────────────────────────────┐
│ TRIP DETAIL > 2025-12-01 Route A               [Edit]  │
├────────────────────────────────────────────────────────┤
│ [Basic Info] [Telemetry] [Students] [Audit Log]       │
├────────────────────────────────────────────────────────┤
│ Trip Date: 2025-12-01
│ Route: Route A
│ Vehicle: BUS-101
│ Driver: Ravi Kumar
│ Trip Type: Morning
│ Status: Ongoing
│ Start Time: 06:30 AM
│ End Time: 08:15 AM
│ [Edit] [Start Trip] [Complete] [Cancel]
```

**TAB 2: TELEMETRY** – GPS logs for this trip, speed chart, route deviation map.

**TAB 3: STUDENTS** – List of students on this trip, boarding/alighting events.

**TAB 4: AUDIT LOG** – Changes and status transitions.

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Trip Request
```json
POST /api/v1/transport/trips
{
  "trip_date": "2025-12-01",
  "route_id": 12,
  "vehicle_id": 34,
  "driver_id": 78,
  "helper_id": null,
  "trip_type": "Morning",
  "start_time": "2025-12-01T06:30:00Z",
  "end_time": "2025-12-01T08:15:00Z",
  "status": "Scheduled"
}
```

### 3.2 List Trips Request
```
GET /api/v1/transport/trips?date=2025-12-01&route=12&status=Ongoing
```

### 3.3 Update Trip Status
```json
PATCH /api/v1/transport/trips/{id}/status
{
  "status": "Ongoing",
  "start_time": "2025-12-01T06:32:00Z"
}
```

---

## 4. USER WORKFLOWS

### 4.1 Create Trip
```
1. User clicks [+ New Trip]
2. Create modal opens
3. User fills fields (date, route, vehicle, driver, trip type)
4. User clicks [Save]
5. POST /api/v1/transport/trips
6. Show success and close
```

### 4.2 Start Trip
```
1. User opens trip detail (status = Scheduled)
2. Clicks [Start Trip]
3. System updates status to Ongoing, records start_time
4. PATCH /api/v1/transport/trips/{id}/status
5. Live telemetry tracking begins
```

### 4.3 Complete Trip
```
1. While trip is Ongoing
2. User clicks [Complete]
3. System sets status to Completed, records end_time
4. Show summary: students boarded, time taken, distance
```

---

## 5. VISUAL DESIGN GUIDELINES

Follow Lesson module guidelines for colors, typography, spacing.

---

## 6. ACCESSIBILITY & USABILITY

- Keyboard navigation for modals and forms
- ARIA labels for status indicators
- Clear feedback on status transitions

---

## 7. EDGE CASES & ERROR SCENARIOS

| Scenario | Behavior |
|----------|----------|
| Trip in past | Block creation/edit |
| Invalid status transition | Show error and list valid next statuses |
| Duplicate trip same route/date | Warn user and ask to confirm |

---

## 8. TESTING CHECKLIST

- [ ] Create trip and verify fields save
- [ ] Start trip and check telemetry tracking begins
- [ ] Complete trip and verify summary shown
- [ ] Cancel trip and verify students notified
- [ ] List trips with filters

---

## 9. FUTURE ENHANCEMENTS

1. Auto-create trips from scheduler
2. ETA prediction on trip start
3. Route optimization suggestions
4. Student no-show alerts
5. Post-trip feedback and ratings

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
