# Screen Design Specification: Route Scheduler (Daily Schedule)
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Route Scheduler Module**, enabling Transport Admins to schedule routes on specific dates and optionally assign vehicles/drivers for daily trip operations. Backed by `tpt_route_scheduler_jnt`.

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

Database Table: `tpt_route_scheduler_jnt`
├── id (BIGINT PRIMARY KEY)
├── scheduled_date (DATE)
├── shift_id (FK -> `tpt_shift.id`)
├── route_id (FK -> `tpt_route.id`)
├── vehicle_id (FK -> `tpt_vehicle.id`, nullable)
├── driver_id (FK -> `tpt_personnel.id`, nullable)
├── helper_id (FK -> `tpt_personnel.id`, nullable)
├── is_active (TINYINT boolean)
├── created_at, updated_at, deleted_at (timestamps)

---

## 2. SCREEN LAYOUTS

### 2.1 Schedule Calendar/List View
**Route:** `/transport/scheduler` or `/transport/routes/{routeId}/schedule`

#### 2.1.1 Page Layout (Calendar View)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > SCHEDULER                                             │
├──────────────────────────────────────────────────────────────────┤
│ [Calendar View] [List View]  SHIFT: [Dropdown ▼]  ROUTE: [Dropdown ▼]│
├──────────────────────────────────────────────────────────────────┤
│
│ December 2025                              [< Previous | Next >]
│
│   Sun   Mon   Tue   Wed   Thu   Fri   Sat
│    1     2 ●   3     4 ●   5     6     7
│    8     9    10     11    12    13 ●  14
│   15    16 ●  17     18    19    20    21
│   22    23    24 ●   25    26    27    28
│   29    30    31
│
│ Legend: ● = Route scheduled
│         Hover for details: Route A (Morning), Vehicle: BUS-101
│
└──────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 List View
```
┌──────────────────────────────────────────────────────────────────┐
│ Scheduled Date | Shift   | Route     | Vehicle  | Driver    │ Status│
├──────────────────────────────────────────────────────────────────┤
│ 2025-12-02     │ Morning │ Route A   │ BUS-101  │ Ravi Kumar│ Active│
│ 2025-12-04     │ Morning │ Route A   │ BUS-102  │ Anita... │ Active│
│ 2025-12-13     │ Evening │ Route B   │ VAN-22   │ (None)   │ Active│
│ ...                                                              │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Create Schedule Entry (Modal)
**Route:** Modal overlay

#### 2.2.1 Layout
```
┌──────────────────────────────────────────────────┐
│ CREATE SCHEDULE ENTRY                        [✕] │
├──────────────────────────────────────────────────┤
│ Scheduled Date *    [Date Picker]               │
│ Shift *             [Dropdown ▼]                │
│ Route *             [Dropdown ▼]                │
│ Vehicle             [Typeahead / Select]        │
│ Driver              [Typeahead / Select]        │
│ Helper              [Typeahead / Select]        │
│ Active Status       [☑] Enable schedule         │
├──────────────────────────────────────────────────┤
│          [Cancel]     [Save]  [Save & New]      │
└──────────────────────────────────────────────────┘
```

#### 2.2.2 Field Specifications

| Field | Type | Validation | Placeholder | Required |
|-------|------|------------|-------------|----------|
| Scheduled Date | Date Picker | >= Today | "YYYY-MM-DD" | ✓ |
| Shift | Dropdown | FK to `tpt_shift` | "Select Shift" | ✓ |
| Route | Dropdown | FK to `tpt_route` | "Select Route" | ✓ |
| Vehicle | Typeahead/Select | FK to `tpt_vehicle` | "Search vehicle" | ✗ |
| Driver | Typeahead/Select | FK to `tpt_personnel` | "Search driver" | ✗ |
| Helper | Typeahead/Select | FK to `tpt_personnel` | "Search helper" | ✗ |
| Active Status | Toggle | Boolean | Checked | ✗ |

#### 2.2.3 Validation Rules

✓ `scheduled_date`, `shift_id`, `route_id` are required.

✓ `scheduled_date` must be >= today (no scheduling in past allowed).

✓ If vehicle assigned, validate vehicle is active and not double-booked for same date+shift.

#### 2.2.4 Error Handling
```
1. Missing required fields
   Message: "Please fill: Scheduled Date, Shift, Route"

2. Vehicle already scheduled
   Message: "Vehicle already scheduled for this date/shift"

3. Invalid date
   Message: "Cannot schedule for past dates"
```

#### 2.2.5 Smart Features
- **Bulk Schedule:** CSV upload with date range, route, shift
- **Auto-assign from previous week:** suggest last week's vehicle/driver
- **Copy schedule:** duplicate schedule from another date

### 2.3 View / Edit Schedule Entry
**Route:** `/transport/scheduler/{id}` or Modal

#### 2.3.1 Layout (Tabbed)
```
┌──────────────────────────────────────────────────┐
│ SCHEDULE DETAIL > 2025-12-02               [Edit]│
├──────────────────────────────────────────────────┤
│ [Basic Info] [Trip History] [Audit Log]        │
├──────────────────────────────────────────────────┤
│ Scheduled Date: 2025-12-02
│ Shift: Morning
│ Route: Route A
│ Vehicle: BUS-101
│ Driver: Ravi Kumar
│ Status: Active
│ [Edit] [Duplicate] [Deactivate]
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Schedule Request
```json
POST /api/v1/transport/scheduler
{
  "scheduled_date": "2025-12-15",
  "shift_id": 2,
  "route_id": 12,
  "vehicle_id": 34,
  "driver_id": 78,
  "helper_id": null,
  "is_active": true
}
```

### 3.2 Create Schedule Response
```json
{
  "success": true,
  "data": {
    "id": 456,
    "scheduled_date": "2025-12-15",
    "shift_id": 2,
    "route_id": 12,
    "vehicle_id": 34,
    "driver_id": 78,
    "is_active": true
  },
  "message": "Schedule entry created successfully"
}
```

### 3.3 List Schedule Entries Request
```
GET /api/v1/transport/scheduler?from=2025-12-01&to=2025-12-31&shift=2&route=12
```

### 3.4 Get Schedule Detail Request
```
GET /api/v1/transport/scheduler/{id}
```

### 3.5 Update Schedule Request
```json
PUT /api/v1/transport/scheduler/{id}
{
  "vehicle_id": 35,
  "driver_id": 80,
  "is_active": false
}
```

### 3.6 Soft-Delete
```
DELETE /api/v1/transport/scheduler/{id}
// sets deleted_at
```

---

## 4. USER WORKFLOWS

### 4.1 Create Schedule Entry Workflow
```
1. User clicks [+ New Schedule] or selects date in calendar
2. Create modal opens with date pre-filled (if from calendar)
3. User selects Shift and Route
4. User optionally assigns Vehicle and Driver
5. User clicks [Save]
6. System validates date/shift/route availability
7. POST /api/v1/transport/scheduler
8. Show success and close modal
```

### 4.2 Bulk Schedule Workflow
```
1. User clicks [Bulk Schedule] or [Upload CSV]
2. File picker opens
3. User selects CSV with columns: scheduled_date, shift_id, route_id, vehicle_id
4. System validates and shows preview with row count and conflicts
5. User confirms and system batches the inserts
6. Show completion summary
```

### 4.3 Calendar View Workflow
```
1. User selects month/year
2. Calendar shows color-coded dots for scheduled dates
3. User clicks date to see schedule details or create new
4. User can drag to reschedule entry to different date
```

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Colors & Typography
Follow Lesson module guidelines. Keep consistent spacing and responsive design.

### 5.2 Icons
- Calendar: 📅
- List: 📋
- Add: ➕
- Bulk: 📦
- Drag: ≡

---

## 6. ACCESSIBILITY & USABILITY

- Keyboard accessible calendar and date picker
- ARIA labels for calendar cells
- Clear error messages

---

## 7. EDGE CASES & ERROR SCENARIOS

| Scenario | Behavior |
|----------|----------|
| Vehicle unavailable | Show conflict and block unless override confirmed |
| Past date selected | Prevent selection in date picker |
| Large bulk upload | Show progress indicator and background job |

---

## 8. TESTING CHECKLIST

- [ ] Create schedule entry for single date
- [ ] Bulk upload schedule from CSV
- [ ] Calendar view displays correct dates
- [ ] Edit/deactivate schedule entry
- [ ] Conflict detection works

---

## 9. FUTURE ENHANCEMENTS

1. Recurring schedules (weekly, biweekly)
2. Automatic trip generation on schedule publish
3. Conflict resolution UI
4. Export schedule to parent mobile app
5. Analytics on schedule execution vs plan

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
**Next Review Date:** March 10, 2026
