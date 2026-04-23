# Screen Design Specification: Vehicle Maintenance
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Track vehicle maintenance activities, schedule preventive maintenance, and manage service history. Backed by `tpt_vehicle_maintenance`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✗    |
| Principal    |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✓    |  ✗    |
| Teacher      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_vehicle_maintenance`
├── id (BIGINT PRIMARY KEY)
├── vehicle_id (FK -> `tpt_vehicles.id`)
├── maintenance_type (ENUM: PREVENTIVE, CORRECTIVE, ROUTINE, EMERGENCY)
├── service_category (ENUM: OIL_CHANGE, TIRE_ROTATION, BRAKE_CHECK, ENGINE_CHECK, AC_SERVICE, TRANSMISSION, OTHER)
├── description (TEXT)
├── scheduled_date (DATE, nullable)
├── completion_date (DATE, nullable)
├── cost (DECIMAL(10,2))
├── service_provider (VARCHAR)
├── odometer_reading (INT, nullable)
├── status (ENUM: SCHEDULED, IN_PROGRESS, COMPLETED, OVERDUE, CANCELLED)
├── parts_replaced (TEXT, nullable)
├── next_service_date (DATE, nullable)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Maintenance Dashboard
**Route:** `/transport/maintenance`

#### 2.1.1 Layout (Vehicle Service Schedule)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > VEHICLE MAINTENANCE                                  │
├──────────────────────────────────────────────────────────────────┤
│ VEHICLE: [All ▼]  STATUS: [All ▼]  DATE: [Due ▼]              │
│ [+ Schedule Service] [Bulk Schedule] [Export] [Calendar View]   │
├──────────────────────────────────────────────────────────────────┤
│
│ ┌─ URGENT (OVERDUE) ───────────────────────────────────┐
│ │ 🔴 BUS-101 - OIL CHANGE (OVERDUE)
│ │ Scheduled: 2025-11-25 | Days Overdue: 6
│ │ Odometer: 18,450 km | Last Oil Change: 15,000 km
│ │ Cost Estimate: ₹800
│ │ [Schedule] [Mark Completed]
│ │
│ └───────────────────────────────────────────────────────┘
│
│ ┌─ DUE THIS WEEK ──────────────────────────────────────┐
│ │ 🟡 VAN-22 - TIRE ROTATION
│ │ Scheduled: 2025-12-05
│ │ Provider: Good Garage
│ │ Cost Estimate: ₹1,200
│ │ [Reschedule] [View History]
│ │
│ └───────────────────────────────────────────────────────┘
│
│ ┌─ COMPLETED ──────────────────────────────────────────┐
│ │ ✓ BUS-102 - BRAKE CHECK (COMPLETED)
│ │ Date: 2025-12-01 | Cost: ₹1,500
│ │ Provider: XYZ Service Center
│ │ Next Service: 2026-03-01
│ │ [View Details] [Print Invoice]
│ │
│ └───────────────────────────────────────────────────────┘
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Schedule Maintenance
#### 2.2.1 Service Scheduling Form
```
┌────────────────────────────────────────────────┐
│ SCHEDULE MAINTENANCE                        [✕]│
├────────────────────────────────────────────────┤
│ VEHICLE *                [BUS-101        ▼]   │
│ Maintenance Type *       [PREVENTIVE     ▼]   │
│ Service Category *       [OIL_CHANGE     ▼]   │
│
│ DETAILS
│ Description              [Oil change every 5000 km]
│ Scheduled Date *         [2025-12-10     ]   │
│ Service Provider *       [Good Garage    ]   │
│ Cost Estimate *          [800            ]   │
│
│ HISTORY
│ Last Service Date        [2025-09-15     ]   │
│ Last Odometer            [12,000 km      ]   │
│ Current Odometer         [18,450 km      ]   │
│
│ NEXT SERVICE
│ Next Service Date        [2026-03-10 (auto)]│
│
│ PARTS
│ Parts to Replace         [__________]        │
│
├────────────────────────────────────────────────┤
│ [Cancel]  [Schedule]  [Schedule & Print Order]
└────────────────────────────────────────────────┘
```

### 2.3 Maintenance History
#### 2.3.1 Service Record Detail
```
┌────────────────────────────────────────────────────┐
│ MAINTENANCE RECORD                              [✕]│
├────────────────────────────────────────────────────┤
│ ID: MNT-2025-1234
│ Vehicle: BUS-101 (Volvo B11R)
│ Type: PREVENTIVE
│ Category: OIL_CHANGE
│ Status: COMPLETED
│
│ DATES
│ Scheduled: 2025-12-01
│ Completion: 2025-12-01
│ Completed On Time: ✓
│
│ SERVICE DETAILS
│ Service Provider: Good Garage, Sector 12
│ Description: Scheduled oil change and filter replacement
│ Cost: ₹800
│
│ VEHICLE INFO AT SERVICE
│ Odometer: 18,450 km
│ Mileage Since Last: 3,450 km
│
│ WORK PERFORMED
│ Parts Replaced: Oil (Castrol 10W-30), Oil Filter
│ Additional Work: None
│
│ NEXT SERVICE
│ Due: 2026-03-01 (or 23,450 km, whichever first)
│
│ [Print Invoice] [Upload Receipt] [Edit Notes]
│
└────────────────────────────────────────────────────┘
```

### 2.4 Maintenance Calendar
#### 2.4.1 Calendar View
```
MAINTENANCE SCHEDULE - December 2025
Sun  Mon  Tue  Wed  Thu  Fri  Sat
                              1
                           🟡 BUS-101
                           OIL CHANGE
 2    3    4    5    6    7    8
            🔴              🟡
          BUS-102          VAN-22
        BRAKE CHECK     TIRE ROTATION

 9   10   11   12   13   14   15
                  ✓
                BUS-103
              ENGINE CHECK
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Schedule Maintenance
```json
POST /api/v1/transport/maintenance
{
  "vehicle_id": 1,
  "maintenance_type": "PREVENTIVE",
  "service_category": "OIL_CHANGE",
  "description": "Scheduled oil change and filter replacement",
  "scheduled_date": "2025-12-10",
  "cost": 800.00,
  "service_provider": "Good Garage",
  "odometer_reading": 18450,
  "status": "SCHEDULED",
  "next_service_date": "2026-03-10"
}

Response:
{
  "id": 1234,
  "vehicle_id": 1,
  "maintenance_type": "PREVENTIVE",
  "service_category": "OIL_CHANGE",
  "status": "SCHEDULED",
  "scheduled_date": "2025-12-10",
  "created_at": "2025-12-01T10:00:00Z"
}
```

### 3.2 Get Maintenance Records
```json
GET /api/v1/transport/maintenance?vehicle_id={id}&status={status}&from_date={date}

Response:
{
  "data": [
    {
      "id": 1234,
      "vehicle_id": 1,
      "vehicle_name": "BUS-101",
      "maintenance_type": "PREVENTIVE",
      "service_category": "OIL_CHANGE",
      "scheduled_date": "2025-12-10",
      "completion_date": null,
      "cost": 800.00,
      "service_provider": "Good Garage",
      "status": "SCHEDULED",
      "next_service_date": "2026-03-10"
    }
  ]
}
```

### 3.3 Mark Service Completed
```json
PATCH /api/v1/transport/maintenance/{id}
{
  "status": "COMPLETED",
  "completion_date": "2025-12-10",
  "parts_replaced": "Oil (Castrol 10W-30), Oil Filter",
  "cost": 850.00,
  "next_service_date": "2026-03-10"
}
```

### 3.4 Get Maintenance Dashboard
```json
GET /api/v1/transport/maintenance/dashboard

Response:
{
  "overdue": 2,
  "due_this_week": 3,
  "scheduled": 8,
  "completed_this_month": 5,
  "total_cost_month": 8500.00
}
```

---

## 4. USER WORKFLOWS

### 4.1 Schedule Preventive Maintenance
```
1. Admin checks maintenance calendar
2. Identifies BUS-101 oil change due
3. Clicks [+ Schedule Service]
4. Selects vehicle and service category (OIL_CHANGE)
5. Sets scheduled date and service provider
6. Saves scheduled maintenance
7. Notification sent to service provider
8. Reminder sent to admin 1 day before
```

### 4.2 Complete Maintenance
```
1. Vehicle taken to service provider
2. Maintenance work completed
3. Admin updates record with completion date
4. Enters actual cost and parts replaced
5. Sets next_service_date based on odometer/time
6. Status changed to COMPLETED
7. Invoice uploaded for audit
```

### 4.3 Bulk Schedule Maintenance
```
1. Admin plans annual maintenance for all fleet
2. Clicks [Bulk Schedule]
3. Uploads CSV with vehicles and service dates
4. System creates multiple maintenance records
5. Calendar view updated
6. Email reminders queued
```

---

## 5. VISUAL DESIGN GUIDELINES

- Color-code status: SCHEDULED (blue), OVERDUE (red), IN_PROGRESS (yellow), COMPLETED (green)
- Calendar view with visual indicators (colored dots)
- Status badges prominent on cards
- Cost displayed prominently

---

## 6. ACCESSIBILITY & USABILITY

- Date pickers for scheduling
- Dropdown for maintenance type and category
- Decimal inputs for cost
- Text area for description and parts replaced
- Keyboard accessible calendar

---

## 7. TESTING CHECKLIST

- [ ] Schedule maintenance with all required fields
- [ ] Scheduled maintenance appears on calendar
- [ ] Status change to COMPLETED updates next_service_date
- [ ] Overdue maintenance flagged and highlighted
- [ ] Dashboard shows correct counts (overdue, due, completed)
- [ ] Export to CSV includes all maintenance history
- [ ] Bulk schedule CSV upload creates records for multiple vehicles
- [ ] Maintenance reminders sent 1 day before scheduled date

---

## 8. FUTURE ENHANCEMENTS

1. Predictive maintenance alerts (based on usage patterns)
2. Automatic service provider selection (based on location/ratings)
3. Maintenance cost analysis (trend and budget tracking)
4. Integration with fleet insurance (maintenance verification)
5. Vendor management (rate comparison, contract terms)
6. Compliance tracking (regulatory maintenance requirements)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
