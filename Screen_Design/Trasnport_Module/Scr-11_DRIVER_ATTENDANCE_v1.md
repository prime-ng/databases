# Screen Design Specification: Driver Attendance
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Manage driver check-in/out records and attendance tracking. Backed by `tpt_driver_attendance`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✓   |  ✓  |   ✓    |   ✗    |  ✓   |  ✓    |  ✗    |
| Principal    |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✓    |  ✗    |
| Teacher      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_driver_attendance`
├── id (BIGINT PRIMARY KEY)
├── driver_id (FK -> `hrm_employees.id`)
├── check_in_time (DATETIME)
├── check_out_time (DATETIME, nullable)
├── status (ENUM: CHECKED_IN, CHECKED_OUT)
├── location (VARCHAR, nullable)
├── device_id (VARCHAR, nullable)
├── remarks (TEXT, nullable)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Attendance Dashboard
**Route:** `/transport/attendance`

#### 2.1.1 Layout (List + Summary Cards)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > DRIVER ATTENDANCE                                    │
├──────────────────────────────────────────────────────────────────┤
│ DATE: [Calendar] [Today] [This Week] [This Month]               │
│ FILTER: Driver [▼] Status [▼]                                   │
├──────────────────────────────────────────────────────────────────┤
│ 
│ ┌─ Checked In ─┐  ┌─ Checked Out ─┐  ┌─ On Leave ─┐
│ │      12      │  │      18       │  │      2     │
│ └──────────────┘  └───────────────┘  └────────────┘
│
├──────────────────────────────────────────────────────────────────┤
│ Driver Name    | Check-in      | Check-out    | Duration  | View │
├──────────────────────────────────────────────────────────────────┤
│ Ravi Kumar     | 06:45 AM      | 07:30 PM     | 12h 45m   | [Edit]
│ Anita Sharma   | 06:30 AM      | -            | Ongoing   | [Edit]
│ Pradeep Singh  | On Leave      | -            | -         | [Edit]
│ Suresh Patel   | 07:00 AM      | 07:15 PM     | 12h 15m   | [Edit]
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Quick Check-In/Check-Out
#### 2.2.1 Modal Dialog
```
┌────────────────────────────────────────┐
│ DRIVER ATTENDANCE                   [✕]│
├────────────────────────────────────────┤
│ Driver *             [Dropdown ▼]       │
│ Check-in Time *      [Time Picker]      │
│ Check-out Time       [Time Picker]      │
│ Location             [________________] │
│ Status *             [Dropdown ▼]       │
│                      CHECKED_IN / CHECKED_OUT
│ Remarks              [________________] │
│
├────────────────────────────────────────┤
│         [Cancel]        [Save]          │
└────────────────────────────────────────┘
```

### 2.3 Attendance History
#### 2.3.1 Detailed View
```
Driver: Ravi Kumar
─────────────────────────────────────────
Date       | Check-in | Check-out | Duration  | Location
─────────────────────────────────────────
2025-12-01 | 06:45 AM | 07:30 PM  | 12h 45m   | Depot
2025-11-30 | 06:30 AM | 07:15 PM  | 12h 45m   | Depot
2025-11-29 | On Leave | -         | -         | -
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Attendance Record
```json
POST /api/v1/transport/driver-attendance
{
  "driver_id": 5,
  "check_in_time": "2025-12-01T06:45:00Z",
  "check_out_time": "2025-12-01T19:30:00Z",
  "status": "CHECKED_OUT",
  "location": "Depot",
  "device_id": "device-12345",
  "remarks": "Standard shift completed"
}

Response:
{
  "id": 100,
  "driver_id": 5,
  "check_in_time": "2025-12-01T06:45:00Z",
  "check_out_time": "2025-12-01T19:30:00Z",
  "status": "CHECKED_OUT",
  "created_at": "2025-12-01T06:45:00Z"
}
```

### 3.2 Get Attendance Records
```json
GET /api/v1/transport/driver-attendance?driver_id={id}&date_from={date}&date_to={date}

Response:
{
  "data": [
    {
      "id": 100,
      "driver_id": 5,
      "driver_name": "Ravi Kumar",
      "check_in_time": "2025-12-01T06:45:00Z",
      "check_out_time": "2025-12-01T19:30:00Z",
      "duration_minutes": 765,
      "status": "CHECKED_OUT"
    }
  ],
  "pagination": {"page": 1, "per_page": 20, "total": 150}
}
```

### 3.3 Update Attendance
```json
PATCH /api/v1/transport/driver-attendance/{id}
{
  "check_out_time": "2025-12-01T19:30:00Z",
  "status": "CHECKED_OUT"
}
```

---

## 4. USER WORKFLOWS

### 4.1 Check-In Driver
```
1. Driver arrives at depot
2. Admin/Driver opens attendance screen
3. Selects driver from dropdown
4. Clicks [Check-In]
5. System records time and location
6. Confirmation message displayed
```

### 4.2 Check-Out Driver
```
1. Driver ends shift
2. Admin clicks [Check-Out] on driver record
3. System updates check_out_time
4. Duration auto-calculated
5. Report accessible to principal
```

### 4.3 View Attendance Reports
```
1. Principal/Admin open attendance dashboard
2. Select date range
3. Filter by driver (optional)
4. View summary cards (checked-in, checked-out counts)
5. Export to CSV/PDF
```

---

## 5. VISUAL DESIGN GUIDELINES

- Color-code status: Checked-in (green), Checked-out (gray), On-leave (orange)
- Summary cards: large, bold numbers with icons
- List view: minimal, sortable columns

---

## 6. ACCESSIBILITY & USABILITY

- Time picker accessible via keyboard (arrow keys, numeric input)
- Responsive layout for mobile check-in/out

---

## 7. TESTING CHECKLIST

- [ ] Driver check-in creates record with correct timestamp
- [ ] Check-out updates existing record
- [ ] Duration calculated correctly (check_out - check_in)
- [ ] Filters by driver and date range work
- [ ] Export to CSV includes all fields
- [ ] Mobile responsiveness verified

---

## 8. FUTURE ENHANCEMENTS

1. Geofence-based auto check-in (location verification)
2. Biometric check-in on mobile app
3. Late arrival alerts
4. Attendance analytics (on-time %, average daily hours)
5. Integration with payroll for wage calculation

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
