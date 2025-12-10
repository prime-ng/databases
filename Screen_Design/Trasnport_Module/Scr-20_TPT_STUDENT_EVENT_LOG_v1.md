# Screen Design Specification: Student Event Log
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Track student boarding and alighting events during trips with timestamp and device verification. Backed by `tpt_student_event_log`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✓    |  ✗    |
| Principal    |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✓    |  ✗    |
| Teacher      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_student_event_log`
├── id (BIGINT PRIMARY KEY)
├── trip_id (FK -> `tpt_trip.id`)
├── student_id (FK -> `std_students.id`)
├── stop_id (FK -> `tpt_pickup_points.id`)
├── event_type (ENUM: BOARDED, ALIGHTED)
├── event_timestamp (DATETIME)
├── device_id (VARCHAR)
├── device_type (ENUM: RFID, NFC, MOBILE, MANUAL)
├── latitude (DECIMAL(10,8), nullable)
├── longitude (DECIMAL(11,8), nullable)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Event Log Dashboard
**Route:** `/transport/event-logs`

#### 2.1.1 Layout (Trip Events Timeline)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > STUDENT EVENT LOG                                    │
├──────────────────────────────────────────────────────────────────┤
│ TRIP: [Trip-123 ▼]  DATE: [2025-12-01 ▼]                        │
│ EVENT TYPE: [All ▼]  DEVICE: [All ▼]                            │
│ [Print Report] [Export CSV] [Map View]                          │
├──────────────────────────────────────────────────────────────────┤
│ Time       | Student       | Stop    | Event   | Device │ Lat/Long
├──────────────────────────────────────────────────────────────────┤
│ 06:45:22   | Aarav Patel   | Stop 5  | BOARDED │ RFID   │ ✓
│ 06:45:38   | Bhavna Gupta  | Stop 5  | BOARDED │ RFID   │ ✓
│ 06:51:15   | Chetan Singh  | Stop 6  | BOARDED │ NFC    │ ✓
│ 07:25:30   | Aarav Patel   | School  | ALIGHTED│ RFID   │ ✓
│ 07:25:45   | Bhavna Gupta  | School  | ALIGHTED│ RFID   │ ✓
│ 07:26:10   | Chetan Singh  | School  | ALIGHTED│ NFC    │ ✓
│
│ [View Timeline] [View Students] [Attendance Verification]
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Event Timeline Visualization
#### 2.2.1 Trip Progress Map
```
┌────────────────────────────────────────────────────────┐
│ TRIP PROGRESS: Trip-123 (Route A - Morning)         [✕]│
├────────────────────────────────────────────────────────┤
│
│ ROUTE MAP WITH EVENTS
│ Depot → Stop 5 → Stop 6 → School
│        (↓ 4 boarded)  (↓ 3 boarded)  (↓ all alighted)
│        06:45:22      06:51:15      07:26:10
│
│ TIMELINE
│ 06:45:00  [Trip Started]
│ 06:45:22  ✓ Aarav Patel (RFID)
│ 06:45:38  ✓ Bhavna Gupta (RFID)
│ 06:46:00  ✓ Pradeep Singh (NFC)
│ 06:47:15  ✓ Suresh Patel (MANUAL)
│ 06:51:15  ✓ Chetan Singh (NFC)
│ ...
│ 07:26:10  ✓ Last student alighted
│ 07:30:00  [Trip Completed]
│
│ VERIFICATION SUMMARY
│ Total Students Expected: 45
│ Boarded: 45 (100%)
│ Alighted: 45 (100%)
│ Exceptions: 0
│
│ [Reconcile] [Print Attendance]
│
└────────────────────────────────────────────────────────┘
```

### 2.3 Manual Event Entry
#### 2.3.1 Quick Add Event
```
┌────────────────────────────────────────────────┐
│ ADD EVENT (MANUAL)                          [✕]│
├────────────────────────────────────────────────┤
│ Trip *                [Trip-123          ▼]   │
│ Student *             [Aarav Patel    ▼]   │
│ Stop *                [Stop 5         ▼]   │
│ Event Type *          [BOARDED        ▼]   │
│ Device Type *         [MANUAL         ▼]   │
│ Event Timestamp *     [2025-12-01 06:45:22] │
│ Latitude              [12.9716           ]   │
│ Longitude             [77.5946           ]   │
│ Notes                 [__________________]   │
│
├────────────────────────────────────────────────┤
│ [Cancel]  [Save]  [Save & Add Another]       │
└────────────────────────────────────────────────┘
```

### 2.4 Attendance Verification Report
#### 2.4.1 Student Attendance
```
TRIP: Trip-123 (Route A - Morning)
Date: 2025-12-01
────────────────────────────────────────────────
Roll No | Student Name       | Expected | Boarded | Alighted │ Status
────────────────────────────────────────────────
ST001   | Aarav Patel        | ✓        | ✓      | ✓        | OK
ST002   | Bhavna Gupta       | ✓        | ✓      | ✓        | OK
ST003   | Chetan Singh       | ✓        | ✓      | ✓        | OK
ST004   | Diya Verma         | ✓        | ✗      | N/A      | MISSED
ST005   | Esha Krishnan      | ✓        | ✓      | ✓        | OK
ST006   | Farhan Ali         | ✓        | ✓      | ✓        | OK

EXCEPTIONS
• ST004: Expected but did not board (absence confirmed)
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Record Event
```json
POST /api/v1/transport/event-logs
{
  "trip_id": 123,
  "student_id": 10,
  "stop_id": 5,
  "event_type": "BOARDED",
  "event_timestamp": "2025-12-01T06:45:22Z",
  "device_id": "rfid-device-001",
  "device_type": "RFID",
  "latitude": 12.9716,
  "longitude": 77.5946
}

Response:
{
  "id": 1000,
  "trip_id": 123,
  "student_id": 10,
  "stop_id": 5,
  "event_type": "BOARDED",
  "event_timestamp": "2025-12-01T06:45:22Z",
  "device_type": "RFID",
  "created_at": "2025-12-01T06:45:22Z"
}
```

### 3.2 Get Events for Trip
```json
GET /api/v1/transport/event-logs?trip_id={id}&event_type=BOARDED

Response:
{
  "data": [
    {
      "id": 1000,
      "trip_id": 123,
      "student_id": 10,
      "student_name": "Aarav Patel",
      "stop_id": 5,
      "stop_name": "Stop 5",
      "event_type": "BOARDED",
      "event_timestamp": "2025-12-01T06:45:22Z",
      "device_type": "RFID",
      "latitude": 12.9716,
      "longitude": 77.5946
    }
  ],
  "pagination": {"page": 1, "per_page": 50, "total": 125}
}
```

### 3.3 Get Attendance Verification
```json
GET /api/v1/transport/event-logs/attendance/{trip_id}

Response:
{
  "trip_id": 123,
  "trip_date": "2025-12-01",
  "total_expected": 45,
  "total_boarded": 45,
  "total_alighted": 45,
  "exceptions": [
    {
      "student_id": 4,
      "student_name": "Diya Verma",
      "expected": true,
      "boarded": false,
      "alighted": false,
      "reason": "Absence confirmed"
    }
  ]
}
```

---

## 4. USER WORKFLOWS

### 4.1 Auto-Record Events
```
1. Student approaches RFID/NFC scanner at stop
2. Device reads student ID from card/tag
3. System auto-creates event_log record (BOARDED/ALIGHTED)
4. Timestamp recorded
5. Lat/Long captured from vehicle GPS
6. Real-time dashboard updated
```

### 4.2 Manual Event Entry
```
1. Device malfunction or student without card
2. Driver/Admin manually records event
3. Opens [Add Event] form
4. Selects student, stop, event type
5. Sets device_type to MANUAL
6. Saves event
```

### 4.3 Verify Attendance
```
1. Trip completed
2. Admin opens Event Log
3. Clicks [Attendance Verification]
4. System compares expected vs actual (boarded + alighted)
5. Generates report highlighting exceptions (missed students)
6. Parents notified if student missed trip
```

---

## 5. VISUAL DESIGN GUIDELINES

- Color-code events: BOARDED (green), ALIGHTED (orange)
- Device types indicated by icons (RFID scanner, NFC, mobile app, manual)
- Timeline visualization showing trip progression
- Exceptions highlighted in red

---

## 6. ACCESSIBILITY & USABILITY

- Datetime pickers for manual event timestamps
- Decimal inputs for lat/long with validation
- Dropdown for device type selection
- Clear visual status indicators (✓/✗)

---

## 7. TESTING CHECKLIST

- [ ] Auto-record event from RFID scan
- [ ] Manual event entry captures all required fields
- [ ] Lat/Long stored with event
- [ ] Event timestamp in correct format
- [ ] Attendance verification calculates boarded/alighted count
- [ ] Exceptions report identifies missed students
- [ ] Export to CSV includes all event details
- [ ] Timeline visualization shows correct order

---

## 8. FUTURE ENHANCEMENTS

1. Real-time attendance alerts (notify if student doesn't board)
2. Duplicate event prevention (same student/stop within 1 min)
3. Event reconciliation workflow (resolve timing discrepancies)
4. Parent notifications (student boarded/alighted alerts)
5. Automated absence reporting (send to parents/teachers)
6. Event analytics (boarding/alighting patterns)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
