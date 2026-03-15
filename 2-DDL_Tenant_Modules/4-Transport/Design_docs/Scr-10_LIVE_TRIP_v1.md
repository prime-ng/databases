# Screen Design Specification: Live Trip Dashboard
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Real-time monitoring dashboard for active trips. Backed by `tpt_live_trip`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✗    |  ✗    |
| Principal    |   ✓   |  ✓  |   ✗    |   ✗    |  ✓   |  ✗    |  ✗    |
| Teacher      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_live_trip`
├── id (BIGINT PRIMARY KEY)
├── trip_id (FK -> `tpt_trip.id`)
├── current_stop_id (FK -> `tpt_pickup_points.id`, nullable)
├── eta (DATETIME, nullable)
├── reached_flag (TINYINT boolean)
├── emergency_flag (TINYINT boolean)
├── last_update (TIMESTAMP)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Live Trips Dashboard
**Route:** `/transport/live-trips`

#### 2.1.1 Layout (Map-Centric)
```
┌─────────────────────────────────────────────────────────────────┐
│ TRANSPORT > LIVE TRIPS                                          │
├─────────────────────────────────────────────────────────────────┤
│ [Map View] [List View]  FILTER: Route [▼] Status [▼]            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ ┌──────────────────────────────────────────────────────┐        │
│ │                 [FULL SCREEN MAP]                    │        │
│ │  📍 Vehicle Icon (color by status)                   │        │
│ │  🛣️  Route polyline                                  │        │
│ │  📌 Pickup/Drop stops                                │        │
│ │  ⚠️  Alert markers if any                            │        │
│ └──────────────────────────────────────────────────────┘        │
│                                                                 │
│ [Live Trips Sidebar]                                            │
│ ├─ Route A (Morning) - Ongoing                                  │
│ │  Vehicle: BUS-101                                             │
│ │  Driver: Ravi Kumar                                           │
│ │  Current Stop: Stop 5 (Reached)                               │
│ │  ETA: 07:15 AM                                                │
│ │  Next Stop: Stop 6 (ETA: 07:22 AM)                            │
│ │  [View Details] [Emergency Alert]                             │
│ │                                                               │
│ └─ Route B (Evening) - Scheduled                                │
│    Vehicle: VAN-22                                              │
│    Driver: Anita Sharma                                         │
│    Status: Not Started (Starts: 04:30 PM)                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 List View
```
Route  | Trip   | Vehicle | Driver     | Next Stop | ETA      │ Status   │ Actions
─────────────────────────────────────────────────────────────────────────────────
Route A│Morning │ BUS-101 │ Ravi Kumar │ Stop 6    │ 07:22 AM │ Ongoing  │ [Details] [Emergency]
Route B│Evening │ VAN-22  │ Anita S.  │ (Not yet) │ 04:30 PM │ Scheduled│ [Details]
```

### 2.2 Live Trip Detail Panel
#### 2.2.1 Expandable Sidebar
```
┌─────────────────────────────────────────┐
│ LIVE TRIP: Route A - Morning        [✕] │
├─────────────────────────────────────────┤
│ Trip ID: #123
│ Date: 2025-12-01
│ Vehicle: BUS-101
│ Driver: Ravi Kumar
│ Route: Route A
│ Status: Ongoing
│ Last Update: 07:12 AM
│
│ CURRENT LOCATION
│ Lat/Long: 12.9716° N, 77.5946° E
│ Speed: 45 km/h
│
│ PROGRESS
│ Current Stop: Stop 5 (Reached ✓)
│ Next Stop: Stop 6
│ ETA to Next: 07:22 AM
│ Time to Next: 10 minutes
│
│ ALERTS: None
│ [Send Notification] [Emergency Button]
│
│ [Full Trip Log] [Telemetry] [Student List]
│
└─────────────────────────────────────────┘
```

### 2.3 Update ETA / Current Stop
#### 2.3.1 Quick Update Dialog
```
┌────────────────────────────────────────┐
│ UPDATE LIVE STATUS                  [✕]│
├────────────────────────────────────────┤
│ Current Stop *  [Dropdown ▼]            │
│ Reached         [☑] Yes                 │
│ ETA (Next Stop) [Time Picker]           │
│ Emergency       [☐] Mark Emergency      │
│ Notes           [______________________]│
├────────────────────────────────────────┤
│         [Cancel]        [Save]          │
└────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create/Get Live Trip
```json
GET /api/v1/transport/live-trips?trip_id={id}
POST /api/v1/transport/live-trips
{
  "trip_id": 123,
  "current_stop_id": 5,
  "eta": "2025-12-01T07:22:00Z",
  "reached_flag": 1,
  "emergency_flag": 0
}
```

### 3.2 Update Live Status
```json
PATCH /api/v1/transport/live-trips/{id}
{
  "current_stop_id": 6,
  "eta": "2025-12-01T07:22:00Z",
  "reached_flag": 1,
  "emergency_flag": 0
}
```

---

## 4. USER WORKFLOWS

### 4.1 Monitor Live Trips
```
1. User opens Live Trips dashboard
2. System displays all ongoing trips on map
3. User can filter by route or status
4. Real-time updates via WebSocket (low-latency)
5. Hover/click trip for sidebar details
```

### 4.2 Update Current Stop
```
1. Driver/Admin updates current stop via mobile app or web
2. PATCH /api/v1/transport/live-trips/{id}
3. Map and dashboard refresh in real-time
4. Parents and students receive stop notification
```

### 4.3 Emergency Alert
```
1. User clicks [Emergency Button]
2. Sets emergency_flag = true
3. Alert badge appears on map
4. Notifications sent to admin/principal/parents
5. Escalation workflow triggered
```

---

## 5. VISUAL DESIGN GUIDELINES

- Map: use Leaflet or Google Maps, color-code vehicles (Ongoing: green, Scheduled: blue, Delayed: orange, Emergency: red)
- Real-time updates: use WebSocket for low-latency sync
- Responsive: full-screen map on desktop, card-based on mobile

---

## 6. ACCESSIBILITY & USABILITY

- Map keyboard accessible (Tab through markers)
- ARIA live regions for status updates
- Screen-reader friendly stop announcements

---

## 7. TESTING CHECKLIST

- [ ] Map displays all ongoing trips
- [ ] Real-time GPS updates reflected on map
- [ ] ETA updates propagate to parents
- [ ] Emergency flag triggers notifications
- [ ] Responsive on mobile/tablet/desktop

---

## 8. FUTURE ENHANCEMENTS

1. Predictive ETA based on traffic and pattern ML
2. Offline mode for driver app
3. Parent notification preferences
4. Historical route replay
5. Route deviation detection and alerts

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
