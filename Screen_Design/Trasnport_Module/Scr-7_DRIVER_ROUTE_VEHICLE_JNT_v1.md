# Screen Design Specification: Driver-Route-Vehicle Assignment Module
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Driver - Route - Vehicle Assignment Module**, enabling Transport Admins to create, view, edit, and manage assignments of drivers and vehicles to routes and shifts. The design follows the Lesson template structure for consistency across modules.

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

> Notes on roles: access to create/update/delete assignments should typically be limited to Super Admin, PG Support and School Admin. Principal and Teacher may have view-only access. The driver-facing mobile app will not have UI to change these records — only to view assigned route/shift.

### 1.3 Data Context

Database Table: `tpt_driver_route_vehicle_jnt`
├── id (BIGINT PRIMARY KEY)
├── shift_id (FK -> `tpt_shift.id`)
├── route_id (FK -> `tpt_route.id`)
├── vehicle_id (FK -> `tpt_vehicle.id`)
├── driver_id (FK -> `tpt_personnel.id`)
├── helper_id (FK -> `tpt_personnel.id`, nullable)
├── effective_from (DATE)
├── effective_to (DATE, nullable)
├── is_active (TINYINT boolean)
├── created_at, updated_at, deleted_at (timestamps)
└── Notes: uniqueness/sequencing and conflict rules enforced at application or via backend validations (avoid overlapping assignments for same vehicle+shift+date-range).

---

## 2. SCREEN LAYOUTS

### 2.1 Assignment List Screen
**Route:** `/transport/assignments` or `/transport/routes/{routeId}/assignments`

#### 2.1.1 Page Layout

┌────────────────────────────────────────────────────────────────────────────────────┐
│ TRANSPORT > ASSIGNMENTS                                                             │
├────────────────────────────────────────────────────────────────────────────────────┤
│   [__________________________________________] [Search]  [+ New Assignment]          │
├────────────────────────────────────────────────────────────────────────────────────┤
│ SHIFT: [Dropdown ▼]   ROUTE: [Dropdown ▼]   VEHICLE: [Typeahead]  DRIVER: [Typeahead]│
├────────────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Shift  | Route         │ Vehicle   │ Driver       │ From       │ To         │ Status │
│────────────────────────────────────────────────────────────────────────────────────│
│ ☐ │ Morning│ Route A       │ BUS-101   │ Ravi Kumar   │ 2025-12-01 │ 2026-03-31 │ Active │
│ ☐ │ Morning│ Route A       │ BUS-102   │ Anita Sharma │ 2025-11-01 │ NULL      │ Active │
│ ☐ │ Evening│ Route B       │ VAN-22    │ Manoj Patel  │ 2025-09-01 │ 2025-12-31 │ Inactive│
│   │ ...                                                                          │
│────────────────────────────────────────────────────────────────────────────────────│
│ Showing 1-10 of 42 assignments                                        [< 1 2 3 >]   │
└────────────────────────────────────────────────────────────────────────────────────┘

#### 2.1.2 Components & Interactions

**Filter Bar:**
- **Shift Dropdown** – Single-select (filter by shift)
  - Options from `tpt_shift` (Morning/Afternoon/Evening/custom)
  - Default: All or current context
- **Route Dropdown** – Single-select
  - Populated with available routes
- **Vehicle/Driver Typeahead** – Search by vehicle_no/registration_no or driver name/phone
- **Date Filter** – Date or date-range to show assignments effective on that date

**Search:**
- Placeholder: "Search by route, vehicle, driver..."
- Real-time filtering across route.name, vehicle_no, driver.name

**Sort Options:**
- By Shift, Route Name, Vehicle No, Driver Name, Effective From (asc/desc)

**Buttons:**
- **[+ New Assignment]** – Opens Create Assignment Modal (Primary)
- **Bulk Actions** – Activate, Deactivate, Export Selected

**Row Actions:**
- View detail, Edit, Deactivate (soft-delete), Duplicate
- Right-click context menu with same actions

**Pagination & Selection:**
- Page sizes: 10/25/50/100
- Bulk select across pages supported (with explicit confirmation for large sets)

---

### 2.2 Create Assignment Screen (Modal)
**Route:** `GET /transport/assignments/new` or Modal overlay

#### 2.2.1 Layout (Modal)
```
┌──────────────────────────────────────────────────┐
│ CREATE NEW ASSIGNMENT                        [✕] │
├──────────────────────────────────────────────────┤
│ Shift *             [Dropdown ▼]                │
│ Route *             [Dropdown ▼]                │
│ Vehicle *           [Typeahead / Select]        │
│ Driver *            [Typeahead / Select]        │
│ Helper              [Typeahead / Select]        │
│ Effective From *    [Date Picker]               │
│ Effective To        [Date Picker]               │
│ Active Status       [☑] Enable assignment        │
│                                                  │
├──────────────────────────────────────────────────┤
│            [Cancel]     [Save]  [Save & New]     │
└──────────────────────────────────────────────────┘
```

#### 2.2.2 Field Specifications

| Field | Type | Validation | Placeholder | Required |
|-------|------|------------|-------------|----------|
| Shift | Dropdown | FK to `tpt_shift` | "Select Shift" | ✓ |
| Route | Dropdown | FK to `tpt_route` | "Select Route" | ✓ |
| Vehicle | Typeahead/Select | FK to `tpt_vehicle`, only active vehicles | "Search vehicle no" | ✓ |
| Driver | Typeahead/Select | FK to `tpt_personnel`, role = Driver | "Search driver name" | ✓ |
| Helper | Typeahead/Select | FK to `tpt_personnel`, role = Helper | "(optional)" | ✗ |
| Effective From | Date Picker | <= Effective To (if provided) | "YYYY-MM-DD" | ✓ |
| Effective To | Date Picker | >= Effective From | "YYYY-MM-DD" | ✗ |
| Active Status | Toggle | Boolean | Checked | ✗ |

#### 2.2.3 Validation Rules

✓ `shift`, `route`, `vehicle`, `driver`, `effective_from` are required.

✓ `effective_from` must be <= `effective_to` when `effective_to` provided.

✓ Prevent overlapping active assignment for the same `vehicle_id` + `shift_id` in overlapping date ranges. Backend must enforce; UI should show a warning and block unless user explicitly confirms override (admin only).

✓ Driver cannot have two active assignments for the same time window that conflict (validation similar to vehicle).

#### 2.2.4 Error Handling
```
1. Missing required fields
   Message: "Please fill required fields: Shift, Route, Vehicle, Driver, Effective From"

2. Overlapping assignment for vehicle
   Message: "Selected vehicle is already assigned for the selected shift/date range." 
   Action: Show existing conflicting assignment with link to details; provide Confirm Override option for privileged users.

3. Invalid date range
   Message: "Effective From must be earlier than or equal to Effective To"

4. Network error on save
   Message: "Failed to save assignment. Try again or contact support."
```

#### 2.2.5 Smart Features
- **Auto-suggest vehicle/driver based on route+shift** (previous assignments)
- **Conflict preview**: show any overlapping assignments with quick link to resolve/adjust
- **Save & New**: quick entry when creating many assignments

---

### 2.3 View / Edit Assignment Screen
**Route:** `/transport/assignments/{id}` or Modal overlay

#### 2.3.1 Layout (Tabbed)
```
┌──────────────────────────────────────────────────────────┐
│ ASSIGNMENT DETAIL > Assignment #123               [Edit] │
├──────────────────────────────────────────────────────────┤
│ [Basic Info] [History] [Audit Log]                    │
├──────────────────────────────────────────────────────────┤
│ TAB 1: BASIC INFO
│ Shift: Morning
│ Route: Route A
│ Vehicle: BUS-101 (Reg: KA-01-1234)
│ Driver: Ravi Kumar (Phone: 9xxxxxxxxx)
│ Helper: Anita Sharma
│ Effective From: 2025-12-01
│ Effective To: 2026-03-31
│ Status: Active
│ Created At: 2025-11-15
│ Updated At: 2025-11-20
│ [Edit] [Duplicate] [Deactivate]
```

**TAB 2: HISTORY**
- Shows previous assignments for the same vehicle/driver, with effective ranges and who changed them.

**TAB 3: AUDIT LOG**
- Shows audit entries (tpt_audit_log) related to this assignment.

#### 2.3.2 Edit Mode
- Edit opens inline or modal with same fields as Create.
- For changes that alter the historical record (e.g., vehicle/driver change), recommend creating a new assignment record (UI option: "Replace/End current and create new").

---

### 2.4 Assignment Conflict Resolver
**Route:** accessible from list row conflict badge or Create modal

#### 2.4.1 Purpose
Resolve conflicting overlapping assignments with guided steps: view conflicting assignments, choose to reschedule, unassign, or override (admin only).

#### 2.4.2 UI
- Side-panel showing conflict list with radio/checkbox to select resolution action
- Actions: End existing assignment (set effective_to), Move existing assignment (pick new dates), Override (create assignment with admin confirmation)

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Assignment Request
```json
POST /api/v1/transport/assignments
{
  "shift_id": 2,
  "route_id": 12,
  "vehicle_id": 34,
  "driver_id": 78,
  "helper_id": 99,
  "effective_from": "2025-12-01",
  "effective_to": "2026-03-31",
  "is_active": true
}
```

### 3.2 Create Assignment Response
```json
{
  "success": true,
  "data": {
    "id": 123,
    "shift_id": 2,
    "route_id": 12,
    "vehicle_id": 34,
    "driver_id": 78,
    "helper_id": 99,
    "effective_from": "2025-12-01",
    "effective_to": "2026-03-31",
    "is_active": true,
    "created_at": "2025-11-20T10:30:00Z"
  },
  "message": "Assignment created successfully"
}
```

### 3.3 List Assignments Request
```
GET /api/v1/transport/assignments?shift=2&route=12&active=1&page=1&limit=25
```

### 3.4 List Assignments Response
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "shift": "Morning",
      "route": "Route A",
      "vehicle_no": "BUS-101",
      "vehicle_registration": "KA-01-1234",
      "driver_name": "Ravi Kumar",
      "helper_name": "Anita Sharma",
      "effective_from": "2025-12-01",
      "effective_to": "2026-03-31",
      "is_active": true
    }
  ],
  "pagination": {"page":1, "limit":25, "total":42, "pages":2}
}
```

### 3.5 Get Assignment Detail Request
```
GET /api/v1/transport/assignments/{id}
```

### 3.6 Update Assignment Request
```json
PUT /api/v1/transport/assignments/{id}
{
  "vehicle_id": 35,
  "driver_id": 80,
  "effective_to": "2026-06-30",
  "is_active": false
}
```

### 3.7 Soft-Delete / Deactivate
```
DELETE /api/v1/transport/assignments/{id}
// sets deleted_at and is_active=false
```

---

## 4. USER WORKFLOWS

### 4.1 Create New Assignment Workflow
```
1. User clicks [+ New Assignment] on list screen
2. Create Assignment modal opens
3. User selects Shift
4. User selects Route (optionally pre-selects vehicle suggestions)
5. User selects Vehicle (typeahead)
6. User selects Driver and optional Helper
7. User picks Effective From (and optionally Effective To)
8. System validates conflict rules
   - If conflict: show conflicts and open Conflict Resolver
9. User confirms and clicks [Save]
10. System calls POST /api/v1/transport/assignments
11. On success: show toast "Assignment created successfully" and close modal (or remain open for Save & New)
```

### 4.2 Edit Assignment Workflow
```
1. User opens Assignment detail
2. Clicks [Edit]
3. Edit modal opens (or inline fields become editable)
4. User updates fields
5. System validates (conflict checks)
6. User clicks [Save]
7. PUT /api/v1/transport/assignments/{id}
8. On success: show success toast and refresh
```

### 4.3 Resolve Conflict Workflow
```
1. While creating/editing, conflict warning appears
2. User opens Conflict Resolver
3. Resolver shows conflicting assignment(s)
4. User chooses action: End existing, Move existing, or Override
5. If End existing: system sets effective_to on existing assignment via PATCH
6. If Move existing: open small schedule editor to change dates
7. If Override: require admin confirmation (checkbox + reason)
8. After resolution, continue save
```

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Colors & Typography
Use same style guidelines as Lesson module (see Appendix A below). Keep page title, section titles, field labels and buttons consistent with the product design system.

### 5.2 Spacing & Layout
Follow same spacing, modal sizing, and list row heights as Lesson module. Maintain responsive behavior (mobile/tablet/desktop).

### 5.3 Icons
- New: ➕
- Edit: ✏️
- Delete/Deactivate: 🗑️
- Conflict: ⚠️
- Duplicate: 📋
- Map: 🗺️

---

## 6. ACCESSIBILITY & USABILITY

- Keyboard navigation: all form controls accessible by Tab/Shift+Tab
- ARIA labels for typeaheads and map preview
- Clear error messaging and focus on first invalid field
- Screen-reader friendly conflict resolver dialog

---

## 7. EDGE CASES & ERROR SCENARIOS

| Scenario | Behavior |
|----------|----------|
| Vehicle already assigned | Block create, show conflict resolver
| Driver assigned elsewhere | Show warning and block unless override confirmed
| Missing required fields | Inline errors, disable Save
| Overly large bulk operations | Confirm dialog and background job tracking (use migration jobs)
| Concurrent edits | Show optimistic lock warning: "This assignment changed — refresh?" |

---

## 8. PERFORMANCE CONSIDERATIONS

- Assignment list: server-side pagination and filters
- Typeahead: debounce queries, limit to top 25
- Conflict checks: implemented server-side; return lightweight conflict summary for UI

---

## 9. TESTING CHECKLIST

### 9.1 Functional Tests
- [ ] Create assignment with valid data
- [ ] Create assignment that conflicts -> conflict resolver opens
- [ ] Edit assignment dates and verify history retained
- [ ] Deactivate assignment -> removed from active lists
- [ ] Bulk activate/deactivate

### 9.2 UI/UX Tests
- [ ] Modal open/close
- [ ] Typeahead works and keyboard accessible
- [ ] Conflict resolver accessible and actions apply
- [ ] Responsive on mobile/tablet/desktop

### 9.3 Integration Tests
- [ ] API contract matches requests/responses above
- [ ] Conflict checks return expected results
- [ ] Audit log entries created for create/update/delete actions

---

## 10. FUTURE ENHANCEMENTS

1. Visual timeline for vehicle & driver assignments
2. Auto-assign suggestions based on availability & proximity
3. Bulk scheduling by CSV with validation preview
4. Assignment templates per route/shift
5. Integration with rostering/HR for driver availability

---

## Appendix A: Component Library References
(Use same references as Lesson module — Headless UI / Chakra UI for dropdowns/modals, TanStack Table for lists, React Hot Toast for notifications.)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
**Next Review Date:** March 10, 2026
**Version Control:** See Git Commit History
