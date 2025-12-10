# Screen Design Specification: GPS Alerts
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Detect and manage real-time alerts from GPS telemetry data (overspeed, geofence violations, idle time, harsh driving). Backed by `tpt_gps_alerts`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✓    |  ✗    |
| Principal    |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✓    |  ✗    |
| Teacher      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_gps_alerts`
├── id (BIGINT PRIMARY KEY)
├── trip_id (FK -> `tpt_trip.id`)
├── vehicle_id (FK -> `tpt_vehicles.id`)
├── alert_type (ENUM: OVERSPEED, GEOFENCE_VIOLATION, IDLE_TIME, HARSH_ACCEL, HARSH_BRAKING, ENGINE_OVERHEAT, LOW_FUEL)
├── severity (ENUM: LOW, MEDIUM, HIGH, CRITICAL)
├── alert_timestamp (DATETIME)
├── location (VARCHAR, nullable)
├── latitude (DECIMAL(10,8), nullable)
├── longitude (DECIMAL(11,8), nullable)
├── alert_value (VARCHAR)
├── threshold_value (VARCHAR)
├── status (ENUM: ACTIVE, ACKNOWLEDGED, RESOLVED)
├── resolved_date (DATETIME, nullable)
├── resolved_by (FK -> `hrm_employees.id`, nullable)
├── notes (TEXT, nullable)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 GPS Alerts Dashboard
**Route:** `/transport/gps-alerts`

#### 2.1.1 Layout (Real-Time Alert Feed)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > GPS ALERTS                                           │
├──────────────────────────────────────────────────────────────────┤
│ STATUS: [Active ▼]  SEVERITY: [All ▼]  ALERT TYPE: [All ▼]     │
│ [Acknowledge Selected] [Resolve Selected] [Export] [Analytics]  │
├──────────────────────────────────────────────────────────────────┤
│
│ ┌─ CRITICAL ───────────────────────────────────────────┐
│ │ 🚨 OVERSPEED ALERT - BUS-101 (Trip-123)
│ │ Time: 2025-12-01 07:15 AM
│ │ Location: Highway Junction
│ │ Speed: 65 km/h | Threshold: 50 km/h
│ │ Status: ACTIVE
│ │ [Acknowledge] [Resolve] [View on Map]
│ │
│ └───────────────────────────────────────────────────────┘
│
│ ┌─ HIGH ────────────────────────────────────────────────┐
│ │ ⚠️  HARSH BRAKING - VAN-22 (Trip-125)
│ │ Time: 2025-12-01 06:50 AM
│ │ Deceleration: 0.8 G | Threshold: 0.5 G
│ │ Status: ACKNOWLEDGED
│ │ [Resolve]
│ │
│ └───────────────────────────────────────────────────────┘
│
│ ┌─ MEDIUM ──────────────────────────────────────────────┐
│ │ 🔔 IDLE TIME - BUS-102 (Trip-126)
│ │ Time: 2025-12-01 07:10 AM
│ │ Duration: 15 minutes | Threshold: 10 minutes
│ │ Location: Traffic Jam, Main Road
│ │ Status: RESOLVED
│ │
│ └───────────────────────────────────────────────────────┘
│
│ [View All] [Create Alert Rule]
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Alert Details
#### 2.2.1 Full Alert Card
```
┌────────────────────────────────────────────────────────┐
│ GPS ALERT DETAIL                                    [✕]│
├────────────────────────────────────────────────────────┤
│ ALERT ID: ALT-2025-0891
│ Type: OVERSPEED
│ Severity: CRITICAL
│ Status: ACTIVE
│
│ DETAILS
│ Trip: Trip-123 (Route A - Morning)
│ Vehicle: BUS-101 (Volvo)
│ Driver: Ravi Kumar
│ Time: 2025-12-01 07:15:30 AM
│
│ LOCATION
│ Location: Highway Junction
│ Lat/Long: 12.9850°, 77.6150°
│ [View on Map]
│
│ ALERT VALUES
│ Current Speed: 65 km/h
│ Speed Limit: 50 km/h
│ Excess: 15 km/h
│ Duration: 2 minutes 15 seconds
│
│ HISTORY
│ Last Similar Alert: 3 days ago
│ Pattern: 2nd overspeed in this trip
│
│ ACTION
│ Status: [ACTIVE ▼]
│ Acknowledged By: [Not Yet]
│ Resolved By: [Not Yet]
│ Notes: [__________________________]
│
│ [Acknowledge] [Resolve] [Contact Driver] [Print]
│
└────────────────────────────────────────────────────────┘
```

### 2.3 Alert Rules Configuration
#### 2.3.1 Rules Management
```
GPS ALERT RULES CONFIGURATION
─────────────────────────────────────────────────────
Alert Type          | Threshold | Severity | Enabled
─────────────────────────────────────────────────────
Overspeed           | 50 km/h   | CRITICAL | ✓
Harsh Acceleration  | 0.6 G     | HIGH     | ✓
Harsh Braking       | 0.5 G     | HIGH     | ✓
Idle Time           | 10 min    | MEDIUM   | ✓
Engine Overheat     | 95°C      | HIGH     | ✓
Low Fuel            | 15%       | MEDIUM   | ✓
Geofence Violation  | Route +/- 50m | MEDIUM | ✓

[Edit Rule] [Disable] [Delete]
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Alert (Auto-triggered)
```json
POST /api/v1/transport/gps-alerts
{
  "trip_id": 123,
  "vehicle_id": 1,
  "alert_type": "OVERSPEED",
  "severity": "CRITICAL",
  "alert_timestamp": "2025-12-01T07:15:30Z",
  "location": "Highway Junction",
  "latitude": 12.9850,
  "longitude": 77.6150,
  "alert_value": "65 km/h",
  "threshold_value": "50 km/h",
  "status": "ACTIVE"
}

Response:
{
  "id": 891,
  "trip_id": 123,
  "alert_type": "OVERSPEED",
  "severity": "CRITICAL",
  "status": "ACTIVE",
  "created_at": "2025-12-01T07:15:30Z"
}
```

### 3.2 Get Active Alerts
```json
GET /api/v1/transport/gps-alerts?status=ACTIVE&severity=CRITICAL

Response:
{
  "data": [
    {
      "id": 891,
      "trip_id": 123,
      "vehicle_id": 1,
      "vehicle_name": "BUS-101",
      "alert_type": "OVERSPEED",
      "severity": "CRITICAL",
      "alert_timestamp": "2025-12-01T07:15:30Z",
      "location": "Highway Junction",
      "alert_value": "65 km/h",
      "threshold_value": "50 km/h",
      "status": "ACTIVE"
    }
  ]
}
```

### 3.3 Acknowledge/Resolve Alert
```json
PATCH /api/v1/transport/gps-alerts/{id}
{
  "status": "ACKNOWLEDGED",
  "resolved_by": 5,
  "notes": "Driver alerted, speed reduced"
}

or

{
  "status": "RESOLVED",
  "resolved_date": "2025-12-01T07:20:00Z",
  "resolved_by": 5,
  "notes": "Speed normalized, no further action needed"
}
```

---

## 4. USER WORKFLOWS

### 4.1 Receive Real-Time Alert
```
1. Vehicle exceeds speed limit (>50 km/h)
2. GPS device detects overspeed event
3. System auto-creates ACTIVE alert
4. Push notification sent to admin + principal
5. Alert appears on dashboard
```

### 4.2 Acknowledge Alert
```
1. Admin receives alert notification
2. Reviews alert details (location, speed, duration)
3. Clicks [Acknowledge]
4. Alert moved to acknowledged status
5. Driver receives message to correct behavior
```

### 4.3 Resolve Alert
```
1. Driver corrects behavior (reduces speed)
2. Admin verifies correction
3. Clicks [Resolve]
4. Sets status to RESOLVED
5. Alert logged for audit trail
```

---

## 5. VISUAL DESIGN GUIDELINES

- Color-code severity: CRITICAL (dark red), HIGH (orange), MEDIUM (yellow)
- Alert icons specific to type (speedometer, brake, thermometer)
- Real-time update indicators (blinking/pulsing for ACTIVE)
- Status badges (ACTIVE, ACKNOWLEDGED, RESOLVED)

---

## 6. ACCESSIBILITY & USABILITY

- Datetime pickers for filtering
- Decimal inputs for threshold values
- Dropdown for status selection
- Map integration for location viewing

---

## 7. TESTING CHECKLIST

- [ ] Alert auto-triggered when threshold exceeded
- [ ] Alert severity set correctly
- [ ] Push notification sent to admin/principal
- [ ] Acknowledge changes status to ACKNOWLEDGED
- [ ] Resolve changes status to RESOLVED with timestamp
- [ ] Active alerts filtered correctly
- [ ] Export to CSV includes all alert fields
- [ ] Historical alerts show pattern analysis

---

## 8. FUTURE ENHANCEMENTS

1. Automatic penalty system (track repeat offenders)
2. Driver coaching based on alert patterns
3. Threshold tuning (adjust per vehicle/driver)
4. Predictive alerting (warn before threshold)
5. Integration with OBD-II data (richer diagnostics)
6. Alert suppression (avoid duplicate notifications)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
