# Screen Design Specification: GPS Trip Log
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Store and analyze GPS telemetry data collected during trips (location, speed, ignition, fuel consumption). Backed by `tpt_gps_trip_log`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✓    |  ✗    |
| Principal    |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✗    |  ✗    |
| Teacher      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_gps_trip_log`
├── id (BIGINT PRIMARY KEY)
├── trip_id (FK -> `tpt_trip.id`)
├── vehicle_id (FK -> `tpt_vehicles.id`)
├── latitude (DECIMAL(10,8))
├── longitude (DECIMAL(11,8))
├── speed_kmh (DECIMAL(5,1))
├── altitude (INT, nullable)
├── accuracy (INT)
├── heading (INT, nullable)
├── ignition_status (ENUM: ON, OFF)
├── fuel_level_percent (INT, nullable)
├── timestamp (DATETIME)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 GPS Trip Log Dashboard
**Route:** `/transport/gps-logs`

#### 2.1.1 Layout (Map + Log Table)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > GPS TRIP LOG                                         │
├──────────────────────────────────────────────────────────────────┤
│ TRIP: [Trip-123 ▼]  VEHICLE: [BUS-101 ▼]  DATE: [2025-12-01 ▼]│
│ [Live Track] [Route Replay] [Export KML] [Speed Analysis]       │
├──────────────────────────────────────────────────────────────────┤
│
│ ┌──────────────────────────────────────────────────────┐         │
│ │             [TRIP MAP WITH GPS PATH]                │         │
│ │  • Start: Depot (06:45 AM)                          │         │
│ │  • Stops: 1 → 2 → 3 → School                        │         │
│ │  • End: School (07:30 AM)                           │         │
│ │  • Route polyline traced (colored by speed)         │         │
│ │  • Speed: < 40 km/h (green), 40–60 (yellow)        │         │
│ │            > 60 km/h (red)                          │         │
│ └──────────────────────────────────────────────────────┘         │
│
│ ┌─ GPS LOG DATA ────────────────────────────────────────────┐
│ │ Time       | Lat/Long      | Speed | Ignition | Fuel │ Acc │
│ │ 06:45:22   | 12.9716/77.59 | 0     | ON       | 45%  │ 5m  │
│ │ 06:45:30   | 12.9720/77.59 | 12    | ON       | 45%  │ 5m  │
│ │ 06:46:00   | 12.9780/77.60 | 35    | ON       | 45%  │ 6m  │
│ │ 06:47:30   | 12.9850/77.61 | 42    | ON       | 44%  │ 5m  │
│ │ 07:25:00   | 13.0052/77.58 | 25    | ON       | 40%  │ 5m  │
│ │ 07:30:00   | 13.0065/77.57 | 0     | OFF      | 40%  │ 5m  │
│ │
│ │ [View on Map] [Download CSV] [Speed Profile]
│ │
│ └───────────────────────────────────────────────────────────────┘
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Route Replay
#### 2.2.1 Playback Viewer
```
┌────────────────────────────────────────────────────────┐
│ TRIP ROUTE REPLAY                                   [✕]│
├────────────────────────────────────────────────────────┤
│ Trip: Trip-123 | Vehicle: BUS-101 | Duration: 45 min  │
│
│ ┌──────────────────────────────────────────────────────┐
│ │              [MAP WITH PLAYBACK]                    │
│ │  🚌 Current vehicle position (at 07:15 AM)         │
│ │  --- Path traced so far                            │
│ │  --- Path remaining                                │
│ └──────────────────────────────────────────────────────┘
│
│ PLAYBACK CONTROLS
│ [◄◄] [◄] [▶] [►►]  Speed: [1x ▼]  [Time Slider ▼▼▼]
│ 06:45 ──────────●───── 07:30  (Current: 07:15)
│
│ REAL-TIME DATA
│ Speed: 35 km/h  |  Fuel: 40%  |  Ignition: ON
│ Location: Main Road, Sector 12
│
│ [Export Video] [Print Route]
│
└────────────────────────────────────────────────────────┘
```

### 2.3 Speed Analysis
#### 2.3.1 Speed Profile Chart
```
TRIP SPEED ANALYSIS: Trip-123
────────────────────────────────────────────────
Maximum Speed: 52 km/h (07:10–07:15)
Average Speed: 28 km/h
Speeding Instances (>50 km/h): 1
Duration Over Speed Limit: 5 minutes

SPEED PROFILE (Time vs Speed)
 │
 │        ╱╲
 │       ╱  ╲        ╭╮
 │      ╱    ╲      ╱  ╲
 │     ╱      ╲    ╱    ╲
 │    ╱        ╰──╱      ╰─
 │───────────────────────────
    06:45    07:00    07:15    07:30

Green Zone (0–40 km/h): Safe
Yellow Zone (40–50 km/h): Caution
Red Zone (>50 km/h): Over limit
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Record GPS Data
```json
POST /api/v1/transport/gps-logs
{
  "trip_id": 123,
  "vehicle_id": 1,
  "latitude": 12.9716,
  "longitude": 77.5946,
  "speed_kmh": 35.5,
  "altitude": 520,
  "accuracy": 5,
  "heading": 45,
  "ignition_status": "ON",
  "fuel_level_percent": 45,
  "timestamp": "2025-12-01T06:46:00Z"
}

Response:
{
  "id": 10000,
  "trip_id": 123,
  "vehicle_id": 1,
  "latitude": 12.9716,
  "longitude": 77.5946,
  "speed_kmh": 35.5,
  "timestamp": "2025-12-01T06:46:00Z",
  "created_at": "2025-12-01T06:46:00Z"
}
```

### 3.2 Get GPS Log for Trip
```json
GET /api/v1/transport/gps-logs?trip_id={id}&start_time={ts}&end_time={ts}

Response:
{
  "data": [
    {
      "id": 10000,
      "trip_id": 123,
      "vehicle_id": 1,
      "latitude": 12.9716,
      "longitude": 77.5946,
      "speed_kmh": 35.5,
      "altitude": 520,
      "accuracy": 5,
      "heading": 45,
      "ignition_status": "ON",
      "fuel_level_percent": 45,
      "timestamp": "2025-12-01T06:46:00Z"
    }
  ],
  "pagination": {"page": 1, "per_page": 100, "total": 240}
}
```

### 3.3 Get Trip Statistics
```json
GET /api/v1/transport/gps-logs/trip-stats/{trip_id}

Response:
{
  "trip_id": 123,
  "total_records": 240,
  "max_speed": 52.3,
  "average_speed": 28.5,
  "speeding_instances": 1,
  "duration_over_limit": 300,
  "distance_km": 15.8,
  "ignition_off_duration": 0,
  "fuel_consumed_percent": 5
}
```

---

## 4. USER WORKFLOWS

### 4.1 Record GPS Points
```
1. Trip starts (06:45 AM)
2. Vehicle GPS device sends location every 30 seconds
3. System records lat/long, speed, heading, fuel level
4. Data stored in gps_trip_log
5. Real-time map updates with vehicle position
```

### 4.2 Review Trip on Map
```
1. Trip completed
2. Admin opens GPS Trip Log
3. Selects trip and vehicle
4. Views full trip path on map
5. Can playback route at variable speed
6. Analyzes speed profile
```

### 4.3 Analyze Speeding Violations
```
1. Admin views trip speed analysis
2. Identifies instances where speed > 50 km/h
3. Calculates total duration of speeding
4. Flags for driver coaching
5. Exports report
```

---

## 5. VISUAL DESIGN GUIDELINES

- Map color-coded by speed: green (<40), yellow (40–50), red (>50)
- Real-time vehicle icon on map
- Playback controls intuitive (standard media player)
- Speed profile chart with highlighted zones

---

## 6. ACCESSIBILITY & USABILITY

- Date/time pickers for log filtering
- Map keyboard navigation
- Playback speed control
- Export to KML (Google Earth compatible)

---

## 7. TESTING CHECKLIST

- [ ] Record GPS point with all required fields
- [ ] Speed calculated and stored correctly
- [ ] Accuracy value within expected range (typically 5–30m)
- [ ] Trip map displays full route path
- [ ] Route replay plays at correct speed
- [ ] Speed analysis calculates max/average correctly
- [ ] Speeding instances identified (>50 km/h)
- [ ] Export to KML includes all waypoints

---

## 8. FUTURE ENHANCEMENTS

1. Real-time live tracking (push updates to principal/parents)
2. Geofence violation detection (vehicle left designated route)
3. Harsh acceleration/braking detection (safety)
4. Fuel consumption analysis and optimization
5. Route comparison (actual vs planned, efficiency analysis)
6. Integration with traffic data (delay attribution)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
