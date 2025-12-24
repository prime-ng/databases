# Screen Design Specification: Vehicle Fuel Log
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Track vehicle fuel fill-ups, consumption, and fuel cost management. Backed by `tpt_vehicle_fuel_log`.

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

Database Table: `tpt_vehicle_fuel_log`
├── id (BIGINT PRIMARY KEY)
├── vehicle_id (FK -> `tpt_vehicles.id`)
├── fuel_type (ENUM: DIESEL, PETROL, CNG, ELECTRIC)
├── quantity_liters (DECIMAL(8,2))
├── cost_per_liter (DECIMAL(6,2))
├── total_cost (DECIMAL(10,2))
├── odometer_reading (INT)
├── fuel_station_name (VARCHAR)
├── fill_up_date (DATE)
├── fill_up_time (TIME)
├── payment_method (ENUM: CASH, CHEQUE, CARD, ACCOUNT)
├── receipt_no (VARCHAR, nullable)
├── remarks (TEXT, nullable)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Fuel Log Dashboard
**Route:** `/transport/fuel-log`

#### 2.1.1 Layout (Vehicle Fuel History)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > VEHICLE FUEL LOG                                     │
├──────────────────────────────────────────────────────────────────┤
│ VEHICLE: [BUS-101 ▼]  DATE RANGE: [Nov 1 ▼] to [Dec 1 ▼]      │
│ [+ Record Fuel Fill] [Import CSV] [Fuel Report] [Export]        │
├──────────────────────────────────────────────────────────────────┤
│
│ ┌─ FUEL STATISTICS (BUS-101) ──────────────────────────┐
│ │ Total Fuel: 450 liters  | Total Cost: ₹33,750       │
│ │ Avg Consumption: 8.5 km/liter  | Mileage: 3,825 km  │
│ └──────────────────────────────────────────────────────┘
│
│ Date       | Quantity | Cost     | Odometer | Avg KM/L │ Station
├──────────────────────────────────────────────────────────────────┤
│ 2025-12-01 | 50 L     | ₹3,750   | 18,450   | 8.2      │ Shell
│ 2025-11-25 | 55 L     | ₹4,125   | 18,000   | 8.8      │ Shell
│ 2025-11-18 | 48 L     | ₹3,600   | 17,580   | 8.7      │ IOCL
│ 2025-11-12 | 50 L     | ₹3,750   | 17,200   | 8.4      │ Shell
│ 2025-11-05 | 52 L     | ₹3,900   | 16,800   | 7.7      │ IOCL
│
│ [View Details] [Edit] [Verify Receipt]
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Record Fuel Fill
#### 2.2.1 Fuel Entry Form
```
┌────────────────────────────────────────────────┐
│ RECORD FUEL FILL                            [✕]│
├────────────────────────────────────────────────┤
│ Vehicle *                [BUS-101        ▼]   │
│ Fuel Type *              [DIESEL         ▼]   │
│ Quantity (L) *           [50             ]   │
│ Cost per Liter *         [75             ]   │
│ Total Cost *             [3,750 (auto)]   │
│
│ FILL DETAILS
│ Odometer Reading *       [18450          ]   │
│ Fuel Station *           [Shell Station A]   │
│ Fill-up Date *           [2025-12-01     ]   │
│ Fill-up Time *           [10:30 AM       ]   │
│
│ PAYMENT
│ Payment Method *         [CASH ▼]            │
│ Receipt No               [________]          │
│ Remarks                  [__________]        │
│
│ CALCULATION
│ Estimated Avg: 8.2 km/liter
│ (Distance: 450 km, Fuel: 55 liters)
│
├────────────────────────────────────────────────┤
│ [Cancel]  [Save]  [Save & Print Receipt]     │
└────────────────────────────────────────────────┘
```

### 2.3 Fuel Consumption Analysis
#### 2.3.1 Performance Metrics
```
VEHICLE: BUS-101 (Volvo B11R)
Period: Nov 1 – Dec 1, 2025
────────────────────────────────────────────────────
FUEL CONSUMPTION
├─ Total Fuel: 450 liters
├─ Total Distance: 3,825 km
├─ Average: 8.5 km/liter
├─ Best Fill: 8.8 km/liter (Nov 25)
├─ Worst Fill: 7.7 km/liter (Nov 05)

COST ANALYSIS
├─ Total Cost: ₹33,750
├─ Average Cost per Liter: ₹75
├─ Cost per km: ₹8.82
├─ Estimated Monthly: ₹50,625

TREND (Last 6 Months)
 KM/L
 9.0 │    ╭─╮
 8.5 │  ╭─╯ ╰╮
 8.0 │──╯    ╰─
 7.5 │
 7.0 └─────────────
     Jun  Jul  Aug  Sep  Oct  Nov

[Detailed Report] [Maintenance Alert]
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Record Fuel Entry
```json
POST /api/v1/transport/fuel-log
{
  "vehicle_id": 1,
  "fuel_type": "DIESEL",
  "quantity_liters": 50.00,
  "cost_per_liter": 75.00,
  "total_cost": 3750.00,
  "odometer_reading": 18450,
  "fuel_station_name": "Shell Station A",
  "fill_up_date": "2025-12-01",
  "fill_up_time": "10:30:00",
  "payment_method": "CASH",
  "receipt_no": "SHELL-12345",
  "remarks": "Regular fuel fill"
}

Response:
{
  "id": 500,
  "vehicle_id": 1,
  "quantity_liters": 50.00,
  "total_cost": 3750.00,
  "odometer_reading": 18450,
  "fill_up_date": "2025-12-01",
  "created_at": "2025-12-01T10:30:00Z"
}
```

### 3.2 Get Fuel Log
```json
GET /api/v1/transport/fuel-log?vehicle_id={id}&from_date=2025-11-01&to_date=2025-12-01

Response:
{
  "data": [
    {
      "id": 500,
      "vehicle_id": 1,
      "vehicle_name": "BUS-101",
      "fuel_type": "DIESEL",
      "quantity_liters": 50.00,
      "total_cost": 3750.00,
      "odometer_reading": 18450,
      "fuel_station_name": "Shell Station A",
      "fill_up_date": "2025-12-01",
      "payment_method": "CASH"
    }
  ],
  "pagination": {"page": 1, "per_page": 20, "total": 10}
}
```

### 3.3 Get Fuel Statistics
```json
GET /api/v1/transport/fuel-log/stats/{vehicle_id}?from_date=2025-11-01&to_date=2025-12-01

Response:
{
  "vehicle_id": 1,
  "total_fuel_liters": 450,
  "total_distance_km": 3825,
  "average_consumption": 8.5,
  "total_cost": 33750.00,
  "average_cost_per_liter": 75.00,
  "cost_per_km": 8.82,
  "best_consumption": 8.8,
  "worst_consumption": 7.7
}
```

---

## 4. USER WORKFLOWS

### 4.1 Record Fuel Fill-up
```
1. Driver/Admin visits fuel station
2. Fills vehicle with fuel (e.g., 50 liters)
3. Records fill-up details in app/web
4. Enters odometer reading, cost, fuel type
5. Saves receipt number and fuel station name
6. System auto-calculates average consumption
```

### 4.2 Monitor Consumption
```
1. Admin opens Fuel Log dashboard
2. Selects vehicle (BUS-101)
3. Views fuel statistics (consumption, cost)
4. Analyzes trend chart (consumption over time)
5. Identifies any unusual patterns (sharp drop = better maintenance)
```

### 4.3 Generate Fuel Report
```
1. Finance team needs monthly fuel expenses
2. Admin opens Fuel Log
3. Selects date range (Nov 1 – Dec 1)
4. Clicks [Fuel Report]
5. Exports data with charts and summary
6. Submits to finance for budgeting
```

---

## 5. VISUAL DESIGN GUIDELINES

- Fuel statistics in prominent cards (total cost, avg consumption)
- Consumption trend chart (line graph over time)
- Payment method indicators (cash, card, check icons)
- Responsive table for mobile viewing

---

## 6. ACCESSIBILITY & USABILITY

- Decimal inputs for fuel quantity and cost
- Date/time pickers for fill-up timestamp
- Dropdown for fuel type and payment method
- Auto-calculated total cost field

---

## 7. TESTING CHECKLIST

- [ ] Record fuel entry with all required fields
- [ ] Total cost auto-calculated (quantity × cost_per_liter)
- [ ] Average consumption calculated (distance ÷ quantity)
- [ ] Fuel statistics aggregated by vehicle and date range
- [ ] Trend chart displays consumption over time
- [ ] Export to CSV includes all fuel entries
- [ ] Payment method validation (CASH/CHEQUE/CARD/ACCOUNT)
- [ ] Receipt tracking (receipt_no validation)

---

## 8. FUTURE ENHANCEMENTS

1. Fuel price forecasting (predict fuel costs)
2. Consumption anomaly detection (flag vehicles with poor economy)
3. Fuel subsidy tracking (government vs private fuel)
4. Integration with vehicle maintenance (preventive alerts)
5. Driver-specific consumption analysis (identify inefficient drivers)
6. Fuel theft detection (unusual consumption patterns)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
