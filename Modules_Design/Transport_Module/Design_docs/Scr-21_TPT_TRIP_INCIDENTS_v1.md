# Screen Design Specification: Trip Incidents
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Log and manage incident reports during trips (accidents, delays, behavioral issues, etc.). Backed by `tpt_trip_incidents`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✗    |
| Principal    |   ✓   |  ✓  |   ✓    |   ✗    |  ✓   |  ✓    |  ✗    |
| Teacher      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_trip_incidents`
├── id (BIGINT PRIMARY KEY)
├── trip_id (FK -> `tpt_trip.id`)
├── incident_type (ENUM: ACCIDENT, BREAKDOWN, DELAY, BEHAVIORAL, SAFETY, OTHER)
├── severity (ENUM: LOW, MEDIUM, HIGH, CRITICAL)
├── description (TEXT)
├── reported_by (FK -> `hrm_employees.id`)
├── reported_date (DATETIME)
├── location (VARCHAR, nullable)
├── latitude (DECIMAL(10,8), nullable)
├── longitude (DECIMAL(11,8), nullable)
├── status (ENUM: OPEN, IN_PROGRESS, RESOLVED, CLOSED)
├── resolution_notes (TEXT, nullable)
├── resolved_date (DATETIME, nullable)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Incidents Dashboard
**Route:** `/transport/incidents`

#### 2.1.1 Layout (List + Severity Filter)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > TRIP INCIDENTS                                       │
├──────────────────────────────────────────────────────────────────┤
│ STATUS: [Open ▼]  SEVERITY: [All ▼]  DATE: [Last 7 days ▼]       │
│ [+ Report Incident] [Filter by Trip] [Export] [Analytics]        │
├──────────────────────────────────────────────────────────────────┤
│
│ ┌─ CRITICAL ─────────────────────────────────────────────────────┐
│ │ ⚠️  ACCIDENT - Trip-123 (Route A)                              │
│ │ Date: 2025-12-01 07:15 AM                                      │
│ │ Location: Sector 12 Junction                                   │
│ │ Reported by: Ravi Kumar (Driver)                               │
│ │ Status: IN_PROGRESS                                            │
│ │ Description: Minor rear-end collision. No injuries.            │
│ │ [View Details] [Resolve] [Contact Admin]                       │
│ │                                                                │
│ └────────────────────────────────────────────────────────────────┘
│
│ ┌─ HIGH ─────────────────────────────────────────────────────────┐
│ │ 🔴 DELAY - Trip-125 (Route B)                                  │
│ │ Date: 2025-12-01 06:50 AM                                      │
│ │ Duration: 25 minutes                                           │
│ │ Reason: Traffic jam on main road                               │
│ │ Reported by: Anita Sharma (Driver)                             │
│ │ Status: RESOLVED                                               │
│ │ [View Details] [Timeline]                                      │
│ │                                                                │
│ └────────────────────────────────────────────────────────────────┘
│
│ ┌─ MEDIUM ───────────────────────────────────────────────────────┐
│ │ 🟡 BEHAVIORAL - Trip-123 (Route A)                             │
│ │ Date: 2025-12-01 07:10 AM                                      │
│ │ Student: Chetan Singh (ST003)                                  │
│ │ Issue: Frequent standing, not following rules                  │
│ │ Reported by: Helper                                            │
│ │ Status: OPEN                                                   │
│ │ [View Details] [Escalate to Principal]                         │
│ └────────────────────────────────────────────────────────────────┘
│                                                                  │  
│ [Bulk Actions] [Print Report]                                    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Report Incident
#### 2.2.1 Incident Form
```
┌──────────────────────────────────────────────────────┐
│ REPORT INCIDENT                                   [✕]│
├──────────────────────────────────────────────────────┤
│ INCIDENT DETAILS                                     │
│ Trip *                [Trip-123 ▼]                   │
│ Incident Type *       [ACCIDENT ▼]                   │
│                       ACCIDENT/BREAKDOWN/DELAY       │
│                       BEHAVIORAL/SAFETY/OTHER        │
│ Severity *            [CRITICAL ▼]                   │
│                       LOW / MEDIUM / HIGH / CRITICAL │
│                                                      │
│ DESCRIPTION                                          │
│ Description *         [___________________]          │
│                       [___________________]          │
│                                                      │
│ LOCATION                                             │
│ Location              [Sector 12 Junction ]          │
│ Latitude              [12.9716            ]          │
│ Longitude             [77.5946            ]          │
│                                                      │
│ ADDITIONAL INFO                                      │
│ Reported By           [Ravi Kumar (Driver)]          │
│ Reported Date         [2025-12-01 07:15 AM]          │
│ Attachments           [Choose File ▼]                │
│                                                      │
│ STATUS                                               │
│ Status *              [OPEN ▼]                       │
│                                                      │
├──────────────────────────────────────────────────────┤
│ [Cancel]  [Save] [Save & Escalate to Principal]      │
└──────────────────────────────────────────────────────┘
```

### 2.3 Incident Detail & Resolution
#### 2.3.1 Full Incident Record
```
┌────────────────────────────────────────────────────┐
│ INCIDENT REPORT                                [✕]│
├────────────────────────────────────────────────────┤
│ INCIDENT ID: INC-2025-0542
│ Type: ACCIDENT
│ Severity: CRITICAL
│ Status: IN_PROGRESS
│
│ DETAILS
│ Trip: Trip-123 (Route A - Morning)
│ Date: 2025-12-01
│ Time: 07:15 AM
│ Location: Sector 12 Junction
│ Lat/Long: 12.9716°, 77.5946°
│
│ DESCRIPTION
│ Minor rear-end collision at traffic light.
│ No injuries reported. Vehicle damage: minor.
│ Police notified. FIR filed: FR-2025-12345
│
│ REPORTED BY
│ Name: Ravi Kumar (Driver)
│ Contact: +91-98765-43210
│ Date/Time: 2025-12-01 07:15 AM
│
│ ESCALATION & ACTIONS
│ Escalated to: Principal (12:30 PM)
│ Parents Notified: Yes
│ Insurance Claim: Submitted
│ Police FIR: Filed
│
│ RESOLUTION
│ Status: IN_PROGRESS
│ Assigned To: Admin
│ Assigned Date: 2025-12-01 08:00 AM
│
│ RESOLUTION NOTES
│ [__________________________________]
│
│ [Escalate] [Assign] [Resolve] [Close] [Add Note]
│
└────────────────────────────────────────────────────┘
```

### 2.4 Incident Analytics
#### 2.4.1 Dashboard Summary
```
INCIDENT ANALYSIS - Last 30 Days
────────────────────────────────────────────────
TOTAL INCIDENTS: 42
├─ Open: 3 (7%)
├─ In Progress: 5 (12%)
├─ Resolved: 28 (67%)
├─ Closed: 6 (14%)

BY TYPE
├─ Accident: 2
├─ Breakdown: 5
├─ Delay: 18
├─ Behavioral: 12
├─ Safety: 4
├─ Other: 1

BY SEVERITY
├─ Critical: 2
├─ High: 8
├─ Medium: 18
├─ Low: 14

BY ROUTE
├─ Route A: 15 incidents
├─ Route B: 12 incidents
├─ Route C: 15 incidents
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Incident Report
```json
POST /api/v1/transport/incidents
{
  "trip_id": 123,
  "incident_type": "ACCIDENT",
  "severity": "CRITICAL",
  "description": "Minor rear-end collision. No injuries.",
  "reported_by": 5,
  "reported_date": "2025-12-01T07:15:00Z",
  "location": "Sector 12 Junction",
  "latitude": 12.9716,
  "longitude": 77.5946,
  "status": "OPEN"
}

Response:
{
  "id": 542,
  "trip_id": 123,
  "incident_type": "ACCIDENT",
  "severity": "CRITICAL",
  "status": "OPEN",
  "created_at": "2025-12-01T07:15:00Z"
}
```

### 3.2 Get Incidents
```json
GET /api/v1/transport/incidents?status=OPEN&severity=CRITICAL&from_date=2025-11-01

Response:
{
  "data": [
    {
      "id": 542,
      "trip_id": 123,
      "incident_type": "ACCIDENT",
      "severity": "CRITICAL",
      "description": "Minor rear-end collision",
      "reported_by_name": "Ravi Kumar",
      "reported_date": "2025-12-01T07:15:00Z",
      "status": "OPEN",
      "location": "Sector 12 Junction"
    }
  ],
  "pagination": {"page": 1, "per_page": 20, "total": 3}
}
```

### 3.3 Resolve Incident
```json
PATCH /api/v1/transport/incidents/{id}
{
  "status": "RESOLVED",
  "resolution_notes": "Vehicle repaired. Insurance claim processed.",
  "resolved_date": "2025-12-01T14:30:00Z"
}
```

### 3.4 Get Incident Analytics
```json
GET /api/v1/transport/incidents/analytics?from_date=2025-11-01&to_date=2025-12-01

Response:
{
  "total_incidents": 42,
  "by_status": {
    "OPEN": 3,
    "IN_PROGRESS": 5,
    "RESOLVED": 28,
    "CLOSED": 6
  },
  "by_type": {
    "ACCIDENT": 2,
    "BREAKDOWN": 5,
    "DELAY": 18,
    "BEHAVIORAL": 12,
    "SAFETY": 4,
    "OTHER": 1
  },
  "by_severity": {
    "CRITICAL": 2,
    "HIGH": 8,
    "MEDIUM": 18,
    "LOW": 14
  }
}
```

---

## 4. USER WORKFLOWS

### 4.1 Report Incident
```
1. Driver/Helper encounters incident during trip
2. Opens app/calls admin to report
3. Admin opens [+ Report Incident]
4. Selects trip and incident type
5. Sets severity (CRITICAL for accident, HIGH for delay)
6. Enters description and location
7. Saves report
8. Incident created with status OPEN
9. Principal/Admin notified
```

### 4.2 Escalate to Principal
```
1. Admin reviews critical incident
2. Clicks [Escalate to Principal]
3. Principal receives notification
4. Principal can view full incident details
5. Parents notified if safety-related
```

### 4.3 Resolve Incident
```
1. Admin takes corrective action (vehicle repair, parent meeting, etc.)
2. Updates incident status to RESOLVED
3. Adds resolution notes
4. Sets resolved_date
5. Closes incident
6. Historical record preserved for audit
```

---

## 5. VISUAL DESIGN GUIDELINES

- Color-code severity: CRITICAL (dark red), HIGH (orange), MEDIUM (yellow), LOW (green)
- Icon indicators for incident type (collision, breakdown, delay, etc.)
- Timeline visualization for incident lifecycle
- Status badges (OPEN, IN_PROGRESS, RESOLVED, CLOSED)

---

## 6. ACCESSIBILITY & USABILITY

- Severity level dropdown clear and labeled
- Datetime pickers for incident timestamp
- Decimal inputs for lat/long with validation
- Text area for detailed description
- File upload for attachments (photos, FIR)

---

## 7. TESTING CHECKLIST

- [ ] Create incident with all required fields
- [ ] Severity level set correctly (CRITICAL/HIGH/MEDIUM/LOW)
- [ ] Incident type dropdown populated with all types
- [ ] Lat/Long captured and stored
- [ ] Escalate to principal notification sent
- [ ] Update incident status to RESOLVED
- [ ] Analytics dashboard calculates counts correctly
- [ ] Export to CSV includes all incident details

---

## 8. FUTURE ENHANCEMENTS

1. Automated incident alerts (SMS/Email to principal/parents)
2. Incident trend analysis (identify problem routes)
3. Insurance claim integration (auto-generate claim forms)
4. Photo/video attachment storage (evidence documentation)
5. Root cause analysis (incident categorization by cause)
6. Preventive action tracking (follow-up on recommendations)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
