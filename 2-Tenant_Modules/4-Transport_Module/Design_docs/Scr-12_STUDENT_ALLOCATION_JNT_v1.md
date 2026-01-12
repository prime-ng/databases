# Screen Design Specification: Student Allocation
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Manage student-to-route and student-to-stop allocations. Backed by `tpt_student_allocation_jnt`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| Principal    |   ✓   |  ✓  |   ✓    |   ✗    |  ✓   |  ✓    |  ✗    |
| Teacher      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_student_allocation_jnt`
├── id (BIGINT PRIMARY KEY)
├── student_id (FK -> `std_students.id`)
├── route_id (FK -> `tpt_routes.id`)
├── pickup_stop_id (FK -> `tpt_pickup_points.id`)
├── drop_stop_id (FK -> `tpt_pickup_points.id`)
├── session_id (FK -> `sch_sessions.id`)
├── status (ENUM: ACTIVE, INACTIVE, ON_LEAVE)
├── allocation_date (DATE)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Student Allocation Dashboard
**Route:** `/transport/student-allocation`

#### 2.1.1 Layout (List + Filters)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > STUDENT ALLOCATION                                   │
├──────────────────────────────────────────────────────────────────┤
│ CLASS: [▼]  ROUTE: [▼]  STATUS: [All ▼]  SEARCH: [__________]    │
│ [Bulk Upload CSV] [Add Student] [Export]                         │
├──────────────────────────────────────────────────────────────────┤
│ Roll No | Student Name      | Class | Route  | Pickup    | Drop  │
├──────────────────────────────────────────────────────────────────┤
│ ST001   | Aarav Patel       | 10-A  | Route1 | Stop 5    | Stop2 │
│ ST002   | Bhavna Gupta      | 10-A  | Route1 | Stop 5    | Stop3 │
│ ST003   | Chetan Singh      | 10-B  | Route2 | Stop 12   | Stop1 │
│ ST004   | Diya Verma (Away) | 10-A  | Route1 | ON LEAVE  | -     │
│                                                                  │
│ [Edit] [Remove] [View Details]                                   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Allocate Student to Route
#### 2.2.1 Create/Edit Modal
```
┌────────────────────────────────────────────────┐
│ ALLOCATE STUDENT                            [✕]│
├────────────────────────────────────────────────┤
│ Student *                [Dropdown ▼ Search]    │
│ Class                    [Auto-populated]       │
│ Route *                  [Dropdown ▼]          │
│ Pickup Stop *            [Dropdown ▼]          │
│ Drop Stop *              [Dropdown ▼]          │
│ Status *                 [ACTIVE ▼]            │
│ Allocation Date *        [Calendar Picker]     │
│
│ VERIFICATION
│ ☑ Stop exists on route
│ ☑ No conflicting allocations
│
├────────────────────────────────────────────────┤
│         [Cancel]          [Save]               │
└────────────────────────────────────────────────┘
```

### 2.3 Bulk Upload CSV
#### 2.3.1 Upload Dialog
```
┌────────────────────────────────────────────┐
│ BULK UPLOAD STUDENT ALLOCATIONS         [✕]│
├────────────────────────────────────────────┤
│ CSV File * [Choose File ▼]                  │
│            [Template Download]              │
│
│ PREVIEW (up to 5 rows)
│ Student | Route | Pickup | Drop | Date
│ ST001   | Route1| Stop 5 | Stop2| 2025-12-01
│ ST002   | Route1| Stop 5 | Stop3| 2025-12-01
│
│ [ ] Replace existing allocations
│
├────────────────────────────────────────────┤
│         [Cancel]      [Upload]             │
└────────────────────────────────────────────┘
```

### 2.4 Student Allocation View
#### 2.4.1 Detailed Panel
```
Student: Aarav Patel (ST001)
Class: 10-A, Admission: 20250101
────────────────────────────────────────────
Route: Route A (Morning)
Pickup Stop: Stop 5 (Sector 12, 06:45 AM pickup)
Drop Stop: Stop 2 (School Gate, 07:30 AM drop)
Status: ACTIVE (from: 2025-12-01)
Session: 2025-26 (Jan–Mar)

[Update] [Deactivate] [View Trip History]
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Allocation
```json
POST /api/v1/transport/student-allocation
{
  "student_id": 10,
  "route_id": 1,
  "pickup_stop_id": 5,
  "drop_stop_id": 2,
  "session_id": 1,
  "status": "ACTIVE",
  "allocation_date": "2025-12-01"
}

Response:
{
  "id": 200,
  "student_id": 10,
  "student_name": "Aarav Patel",
  "route_id": 1,
  "route_name": "Route A",
  "pickup_stop_id": 5,
  "drop_stop_id": 2,
  "status": "ACTIVE",
  "created_at": "2025-12-01T10:00:00Z"
}
```

### 3.2 Get Allocations
```json
GET /api/v1/transport/student-allocation?route_id={id}&class_id={id}

Response:
{
  "data": [
    {
      "id": 200,
      "student_id": 10,
      "student_name": "Aarav Patel",
      "roll_no": "ST001",
      "class": "10-A",
      "route_id": 1,
      "route_name": "Route A",
      "pickup_stop_id": 5,
      "pickup_stop_name": "Stop 5",
      "drop_stop_id": 2,
      "drop_stop_name": "Stop 2",
      "status": "ACTIVE"
    }
  ],
  "pagination": {"page": 1, "per_page": 50, "total": 250}
}
```

### 3.3 Update Allocation
```json
PATCH /api/v1/transport/student-allocation/{id}
{
  "status": "ON_LEAVE",
  "pickup_stop_id": 6,
  "drop_stop_id": 3
}
```

### 3.4 Bulk Upload CSV
```json
POST /api/v1/transport/student-allocation/bulk-upload
{
  "file": <binary>,
  "replace_existing": false
}
```

---

## 4. USER WORKFLOWS

### 4.1 Create Single Allocation
```
1. Admin opens Student Allocation screen
2. Clicks [Add Student]
3. Selects student from dropdown
4. Route, pickup, drop stops auto-filled or manually selected
5. Status set to ACTIVE
6. Saves record
```

### 4.2 Bulk Upload Allocations
```
1. Admin downloads CSV template
2. Populates with student roll_no, route_name, pickup_stop, drop_stop
3. Uploads file via [Bulk Upload CSV]
4. System validates each row
5. Preview shown; [Upload] confirmed
6. Allocations created or updated
7. Success/error report displayed
```

### 4.3 Change Allocation on Leave
```
1. Principal/Admin sees student "On Leave"
2. Clicks [Edit] on student row
3. Changes status to ON_LEAVE
4. Saves
5. System excludes from trip boarding list
```

---

## 5. VISUAL DESIGN GUIDELINES

- Color-code status: Active (green), Inactive (gray), On Leave (orange)
- Inline editing for status change
- Responsive grid for mobile

---

## 6. ACCESSIBILITY & USABILITY

- Dropdowns searchable (type to filter)
- Keyboard navigation for table rows
- CSV template clearly documented

---

## 7. TESTING CHECKLIST

- [ ] Single student allocation creates record
- [ ] Bulk CSV upload processes all rows
- [ ] Duplicate roll_no in CSV handled (skip or replace)
- [ ] Filters by class and route work
- [ ] Status change from ACTIVE to ON_LEAVE excludes from trip
- [ ] Export to CSV includes all active allocations

---

## 8. FUTURE ENHANCEMENTS

1. Parent-verified allocations (parents approve stop preferences)
2. Automatic allocation recommendation based on distance
3. Allocation history and changes audit trail
4. Smart allocation suggestions (same neighborhood students)
5. Integration with fee master (fee varies by stop/distance)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
