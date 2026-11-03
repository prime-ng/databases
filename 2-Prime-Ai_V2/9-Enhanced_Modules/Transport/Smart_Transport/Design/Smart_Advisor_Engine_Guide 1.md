# Smart Advisor Engine: Technical Process Guide

| Item | Detail |
|---|---|
| Module | Transport |
| Component | Suggestion Engine (live, rule-based), Smart Advisor controller and page |
| Database | MySQL 8.x, Transport DDL v2.3 |
| Storage model | Live calculation. Nothing is saved; every page load re-runs all rules |
| Reference date used in examples | 12 October 2026 (the date of the sample screen) |
| Scope | 68 registered rules in 9 groups, plus 1 rule that exists but is not registered |

---

## Table of Contents

1. [What the Engine Does](#1-what-the-engine-does)
2. [Variable Reference](#2-variable-reference)
3. [Shared Data Access (Reused Queries)](#3-shared-data-access-reused-queries)
4. [Rule Catalogue (R01 to R69)](#4-rule-catalogue)
5. [Ranking and Display Logic](#5-ranking-and-display-logic)
6. [Reading the Live Screen: Item-by-Item Mapping](#6-reading-the-live-screen)
7. [Validation Findings and Recommended Corrections](#7-validation-findings-and-recommended-corrections)

---

## 1. What the Engine Does

The Smart Advisor reads existing transport data (vehicles, personnel, routes, stops, student allocations, trips, boarding logs, fuel, maintenance, fees, notifications) and applies business rules. Each rule that finds a problem produces one **suggestion** with five parts:

1. **What the data shows** (the problem, with real numbers)
2. **Recommended action** (what the school should do)
3. **Expected benefit** (safety, rupees, minutes, compliance)
4. **Priority** (HIGH, MEDIUM, LOW)
5. **Calculation** (the figures behind the suggestion, shown in the "Why?" panel)

### 1.1 Processing pipeline

```
Browser request
   |
   v
Permission check (viewAny on transport)
   |
   v
Engine created with default settings (Section 2.1)
   |
   v
Reference date fixed = today at 00:00
Assignment cache cleared
   |
   v
For each rule in the registry (R01, R02, ... R68), in order:
   |-- run the rule (one or more SQL reads + in-memory calculation)
   |-- keep at most 20 suggestions from that rule
   |-- if the rule fails for any reason, log the error and continue
   v
Merge all suggestions
   |
   v
Global sort (Safety first, then priority, then rupee benefit)
   |
   v
Page renders suggestion cards
```

### 1.2 Design principles

| Principle | Meaning |
|---|---|
| Live data | Results always reflect the database at the moment of the request |
| Failure isolation | A failing rule is logged and skipped; other rules still run |
| Consolidation | When many records share one problem, the engine may produce one grouped suggestion instead of many (for example, 50 staff without police verification become one suggestion) |
| Safety first | Safety suggestions always appear above all other categories |
| Explainability | Every suggestion carries a calculation block so the school can verify it |

---

## 2. Variable Reference

### 2.1 Engine settings (configurable thresholds)

These are the defaults set when the engine starts. They can be overridden when the engine is created.

| Variable | Default | Unit | Used by | Meaning |
|---|---|---|---|---|
| `expiry_days` | 30 | days | R01, R07 | A document or licence is flagged when it expires within this many days (or has already expired) |
| `unboarding_days` | 30 | days | R52 | Look-back window for "boarded but not unboarded" |
| `unboarding_min` | 2 | events | R52 | Minimum missed-unboarding events on a route before it is reported |
| `incident_days` | 60 | days | R53 | Look-back window for incident hotspots |
| `incident_min` | 3 | incidents | R53 | Minimum incidents in one location cell to call it a hotspot |
| `inspection_days` | 15 | days | R45 | Look-back window for repeated inspection failures |
| `inspection_min_fails` | 3 | times | R45 | Same checklist item must fail at least this many times |
| `fee_pending_days` | 30 | days | R27 | A bill is "pending beyond grace" when its due date is older than this |
| `unused_days` | 30 | days | R28 | Look-back window for "allocated but never boarded" |
| `low_student_stop` | 3 | students | R16 | A stop with fewer students than this is "low-student" |
| `stop_merge_distance` | 1000 | metres | R16 | Reserved for nearest-stop advice (currently not used in the output) |
| `service_due_days` | 15 | days | R44 | Service is flagged when due within this many days or overdue |
| `late_days` | 30 | days | R35 | Look-back window for late-running stops |
| `late_minutes` | 5 | minutes | R35 | An arrival is "late" when it exceeds the schedule by more than this |
| `late_min_records` | 5 | records | R35 | Minimum trips recorded at a stop before judging it |
| `late_share_pct` | 60 | percent | R35 | Share of trips that must be late for the stop to be flagged |
| `max_per_rule` | 20 | suggestions | All | Maximum suggestions kept from any single rule |

### 2.2 Runtime variables

| Variable | Type | Description |
|---|---|---|
| `today` | Date at 00:00 | The reference date. All "days left" calculations compare against it |
| `assignments` | Cached list | The set of currently active route-vehicle-driver assignments, read once per run (Section 3.1) |
| `settings` | Map | The merged result of defaults and any overrides (Section 2.1) |
| `all` | List | Accumulator of suggestions from all rules |

### 2.3 Constants

**Rule registry.** An ordered list mapping each rule code to the routine that executes it (R01 to R68). Order matters: when two suggestions tie on category, priority and rupee value, the one from the earlier rule appears first.

**Inspection checklist.** The 14 inspection columns used by R45, with the label shown to users:

| Column in `tpt_daily_vehicle_inspection` | Label |
|---|---|
| `tire_condition_ok` | Tyres |
| `lights_condition_ok` | Lights |
| `brakes_condition_ok` | Brakes |
| `engine_condition_ok` | Engine |
| `battery_condition_ok` | Battery |
| `fire_extinguisher_condition_ok` | Fire extinguisher |
| `first_aid_kit_condition_ok` | First aid kit |
| `seat_belts_condition_ok` | Seat belts |
| `headlights_condition_ok` | Headlights |
| `tailights_condition_ok` | Tail lights |
| `wipers_condition_ok` | Wipers |
| `mirrors_condition_ok` | Mirrors |
| `steering_wheel_condition_ok` | Steering |
| `emergency_tools_condition_ok` | Emergency tools |

A value of `0` means "not OK".

### 2.4 Suggestion fields (output record)

| Field | Type | Description |
|---|---|---|
| `ruleCode` | Text | The rule that produced the suggestion (for example `ROUTE_OVERLOADED`) |
| `category` | Text | Safety, Saving, Income, Service, Maintenance, Compliance, Modernization or Operations |
| `priority` | Text | HIGH, MEDIUM or LOW |
| `title` | Text | One-line heading |
| `problem` | Text | "What the data shows" |
| `suggestion` | Text | "Recommended action" |
| `benefitText` | Text | "Expected benefit" in words |
| `benefitAmount` | Number or empty | The benefit as a number (rupees, minutes, count and so on) |
| `benefitUnit` | Text | `rupees`, `minutes`, `days`, `students`, `trips`, `vehicles`, `percent`, `km/L`, `none` and others |
| `entityType` | Text | vehicle, driver, route, stop, trip, fee and so on |
| `entityId` | Number | ID of the main entity (a placeholder `1` is used for grouped suggestions) |
| `entityName` | Text | Label shown under the badges (for example "Route 2" or "Transport Crew Cohort") |
| `routeId`, `vehicleId`, `driverId` | Number or empty | Optional links for filtering |
| `calculation` | Key-value list | The figures shown in the "Why?" panel |

### 2.5 Common working variables

These names appear inside many rules.

| Variable | Formula or source | Example |
|---|---|---|
| `days_left` | `valid_upto date - today`, in whole days. Negative means already past | 12 Oct 2026 vs today 12 Oct = 0; 11 Oct = -1 |
| `expired` | `days_left < 0` | Insurance dated 11 Oct 2026 gives true |
| `label` (vehicle) | `registration_no`, or `vehicle_no` when registration is empty | `NE 66 YP 5551` |
| `onRoute` | Comma-separated names of routes from the active assignments of the vehicle or driver | `Route 3, Route 4` |
| `students` | Students allocated to a route (Section 3.2) | 40 |
| `capacity` | Seating capacity of the vehicle assigned to the route | 30 |
| `extra` | `students - capacity` | 10 |
| `utilization_pct` | `students / capacity x 100` | 40 / 30 = 133% |
| `money(x)` | `₹` followed by `x` rounded to a whole number with thousands separators | `₹79,159` |
| `distance_m(a,b)` | Haversine great-circle distance in metres between two coordinates | 180 m |

**Haversine formula** used for distances (R16, R62):

```
a = sin²(Δlat/2) + cos(lat1) x cos(lat2) x sin²(Δlon/2)
distance = 2 x 6,371,000 x atan2(√a, √(1-a))      (metres)
```

### 2.6 Hard-coded business assumptions

These values are fixed inside the rules (not in the settings). They should be reviewed and ideally moved to settings.

| Rule | Value | Meaning |
|---|---|---|
| R01 | 7 days | Certificates expiring within 7 days are individual HIGH alerts; 8 to 30 days are batched |
| R06 | ₹150,000 | Indicative annual saving per rented route |
| R09 | 12 months | Driver experience below this is "novice" |
| R10 | 1 to 7 trips in 30 days | Treated as irregular driver attendance |
| R11 | 15 days, 11 hours, 3 days | Duty-spread window, spread threshold, minimum number of long days |
| R12 | 20 logs, 50%, 3 routes | Minimum logs per route, manual share threshold, grouping threshold |
| R13 | 120 seconds, 3 events | Duplicate-scan interval and minimum count |
| R15 | 35 seats, 15 students | Large-bus underuse thresholds |
| R16 | 4 min, 5 min, 0.8 km, 22 days, 3.8 km/L, ₹95/L | Time saved per empty stop; fuel saving assumptions |
| R19 | 10 days | Assignment-expiry look-ahead |
| R20 | 20 students, 50% | Shift-imbalance thresholds |
| R21 | 4 stops, 3 reversals, 15 min | Stop-sequence thresholds and benefit |
| R22 | 16 + 16 students, 32, ₹40,000 | Route-merge thresholds and benefit |
| R23 | 1 student, 8 min | Isolated stop and benefit |
| R24 | 5 students | One-way commuter threshold |
| R30 | ₹5,000, 50% | Fine-waiver thresholds |
| R31 | 15 days, 10 payments | Late-payment thresholds |
| R33 | 20 payments, 50% | Cash-share thresholds |
| R34 | 60 days | Chronic default age |
| R36 | 10 records, 5 skips, 25% | Skipped-stop thresholds |
| R37 | 15 trips | Trip approval backlog threshold |
| R38 | 70 minutes | Long-trip threshold |
| R40 | 07:45, 10 trips, 5 late departures | Peak-hour thresholds |
| R41 | 3.5 km/L, 50 km, 20 L | Mileage thresholds |
| R42 | ₹120 per litre | Fuel-rate anomaly threshold |
| R43 | 5 vouchers | Fuel approval backlog threshold |
| R46 | 7 days | Inspection look-back |
| R47 | 180 days, ₹100,000 | Repair-spend window and threshold |
| R48 | 60 days, 12 days | Garage-downtime window and threshold |
| R50 | 1.3x, ₹8,000 | Workshop price-gap multiplier and floor |
| R51 | 15 vehicles | Diesel fleet threshold |
| R55 | 90 days, 2 incidents, 3 drivers | Driver-incident thresholds |
| R56 | 14 days | High-severity look-back |
| R57 | 15 days, 10 messages, 3 failures | SMS-failure thresholds |
| R58 | 20 messages, 40% | App-adoption thresholds |
| R59 | 7 days, 5 trips | Odometer-log look-back and threshold |
| R61 | ₹28,000 per bus | Monthly holding cost of an idle bus |
| R62 | 10 m to 250 m, ₹3,200 per pair | Adjacent-stop distance band and monthly saving |
| R63 | 4 buses, ₹42,000 | Fleet-reuse threshold and monthly cost per bus |
| R64 | 25 L, ₹95 | Monthly idling fuel per bus, diesel price |
| R65 | 60 days, ₹2,500 | Weekend look-back and cost per event |
| R67 | ₹3.00 per litre, 500 L, 220 L per bus | Fuel-card rebate and volume assumptions |
| R68 | ₹6,500 per driver, ₹18,000 | Overtime cost assumptions |

---

## 3. Shared Data Access (Reused Queries)

### 3.1 Active assignments

Many rules need to know which vehicle and driver are working which route **today**. The engine reads this once per run and reuses it.

```sql
SELECT a.id, a.route_id, a.vehicle_id, a.driver_id, a.effective_from, a.effective_to
FROM   tpt_driver_route_vehicle_jnt a
WHERE  a.deleted_at IS NULL
  AND  a.is_active = 1
  AND  DATE(a.effective_from) <= CURDATE()
  AND  (a.effective_to IS NULL OR DATE(a.effective_to) >= CURDATE());
```

Route and vehicle details are then attached (route name, shift, pickup/drop type; vehicle number, registration, capacity). In the rest of this guide this condition is written as **[ACTIVE ASSIGNMENT]**.

### 3.2 Route load (students and capacity)

A route's student count is the larger of its pickup count and its drop count, counting each student once.

```sql
-- Pickup students per route
SELECT pickup_route_id AS route_id, COUNT(DISTINCT student_id) AS cnt
FROM   tpt_student_route_allocation_jnt
WHERE  deleted_at IS NULL AND active_status = 1 AND pickup_route_id IS NOT NULL
GROUP  BY pickup_route_id;

-- Drop students per route
SELECT drop_route_id AS route_id, COUNT(DISTINCT student_id) AS cnt
FROM   tpt_student_route_allocation_jnt
WHERE  deleted_at IS NULL AND active_status = 1 AND drop_route_id IS NOT NULL
GROUP  BY drop_route_id;
```

```
students = GREATEST(pickup_count, drop_count)
capacity = capacity of the vehicle on the first active assignment of the route that has a vehicle
```

### 3.3 Conventions used in all queries

| Convention | Meaning |
|---|---|
| `deleted_at IS NULL` | Soft-deleted rows are always excluded |
| `is_active = 1` | Used for vehicles, personnel, routes and assignments marked active |
| `active_status = 1` | Used for student allocations |
| Dropdown lookups | Names such as emission class, ownership type and fuel type come from `sys_dropdown_table` joined on the stored ID |
| Day counts | Whole days between midnight of two dates |

---

## 4. Rule Catalogue

**How to read a rule card**

| Block | Content |
|---|---|
| Header | Rule ID, code, category and priority |
| Purpose | The business question the rule answers |
| Data sources | Tables used |
| Query | SQL showing how the data is read |
| Logic | Conditions and formulas applied |
| Example | Sample result (from the live screen where available) |
| Status | Working, Working (review), or Not producing output (see Section 7) |

Examples marked *Illustrative* are not from the sample screen.

---

### Group 1: Vehicles and Fleet

#### R01 `VEHICLE_DOC_EXPIRY` | Safety | HIGH or MEDIUM

**Purpose:** Warn before a vehicle certificate (Fitness, Insurance, Pollution, Fire extinguisher) expires, or after it has expired.

**Data sources:** `tpt_vehicle`; active assignments (to show which route is affected).

**Query (set-based equivalent):**

```sql
SELECT v.id, COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle,
       d.document, d.valid_upto, DATEDIFF(d.valid_upto, CURDATE()) AS days_left
FROM   tpt_vehicle v
JOIN (
    SELECT id, 'Fitness'           AS document, fitness_valid_upto           AS valid_upto FROM tpt_vehicle
    UNION ALL
    SELECT id, 'Insurance',                     insurance_valid_upto                       FROM tpt_vehicle
    UNION ALL
    SELECT id, 'Pollution',                     pollution_valid_upto                       FROM tpt_vehicle
    UNION ALL
    SELECT id, 'Fire extinguisher',             fire_extinguisher_valid_upto               FROM tpt_vehicle
) d ON d.id = v.id
WHERE  v.deleted_at IS NULL AND v.is_active = 1
  AND  d.valid_upto IS NOT NULL
  AND  DATEDIFF(d.valid_upto, CURDATE()) <= 30;
```

**Logic:**

| `days_left` | Result |
|---|---|
| Below 0 (expired) | One individual suggestion, HIGH. Action: renew immediately and remove the vehicle from active routes until verified |
| 0 to 7 | One individual suggestion, HIGH. Action: start renewal now |
| 8 to 30 | Not shown individually. All such certificates are collected into **one** MEDIUM "renewal schedule" suggestion; `benefitAmount` = number of certificates, unit `certificates` |

**Example:**

| Vehicle | Document | Valid until | days_left | Output |
|---|---|---|---|---|
| FT 42 HX 0723 | Fitness | 12 Oct 2026 | 0 | HIGH, "only 0 days remaining" |
| DP 80 GQ 9600 | Pollution | 14 Oct 2026 | 2 | HIGH |
| BU 02 XP 8711 | Insurance | 11 Oct 2026 | -1 | HIGH, "expired ... 1 days ago" |
| IK 59 WV 6104 | Fitness | 17 Oct 2026 | 5 | HIGH |
| CR 73 AC 4547 | Fitness | 19 Oct 2026 | 7 | HIGH (boundary: 7 is still individual) |
| 10 other certificates | various | 8 to 30 days ahead | 8 to 30 | One MEDIUM batch: "10 certificates due within 30 days" |

**Status:** Working.

---

#### R02 `VEHICLE_DOC_SCAN_MISSING` | Compliance | MEDIUM

**Purpose:** Find vehicles whose certificates are recorded with a validity date but have no scanned copy uploaded.

**Data sources:** `tpt_vehicle` (`*_valid_upto`, `*_cert_upload`).

**Query:**

```sql
SELECT v.id,
       COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle,
       CASE
         WHEN v.fitness_valid_upto   IS NOT NULL AND v.fitness_cert_upload   = 0 THEN 'Fitness Certificate'
         WHEN v.insurance_valid_upto IS NOT NULL AND v.insurance_cert_upload = 0 THEN 'Insurance Policy'
         WHEN v.pollution_valid_upto IS NOT NULL AND v.pollution_cert_upload = 0 THEN 'Pollution Under Control (PUC)'
       END AS first_missing_document
FROM   tpt_vehicle v
WHERE  v.deleted_at IS NULL AND v.is_active = 1
HAVING first_missing_document IS NOT NULL;
```

**Logic:** One entry per vehicle (the first missing document in the order Fitness, Insurance, Pollution). If at least one vehicle qualifies, **one** grouped suggestion is produced. `benefitAmount` = number of vehicles.

**Example:** 40 vehicles listed; sample shown as "NE 66 YP 5551 (Fitness Certificate), UQ 87 QC 1359 (Fitness Certificate) ... and 36 other vehicles".

**Status:** Working.

---

#### R03 `VEHICLE_EMISSION_CLASS` | Modernization | LOW

**Purpose:** Identify legacy emission standards (BS III, BS IV, Euro 3, Euro 4) for a fleet-renewal plan.

**Data sources:** `tpt_vehicle`, `sys_dropdown_table` (emission class).

**Query:**

```sql
SELECT v.id, COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle,
       v.manufacturer, v.model, d.value AS emission_class
FROM   tpt_vehicle v
LEFT JOIN sys_dropdown_table d ON d.id = v.vehicle_emission_class_id
WHERE  v.deleted_at IS NULL AND v.is_active = 1
  AND (UPPER(d.value) LIKE '%BS III%'  OR UPPER(d.value) LIKE '%BS-III%'
    OR UPPER(d.value) LIKE '%BS IV%'   OR UPPER(d.value) LIKE '%BS-IV%'
    OR UPPER(d.value) LIKE '%EURO 3%'  OR UPPER(d.value) LIKE '%EURO 4%');
```

**Logic:** One grouped suggestion; `benefitAmount` = number of legacy vehicles, unit `buses`.

**Example:** 40 buses on BS-IV. The heading text always says "BS-IV" even if some vehicles are BS-III.

**Status:** Working (see finding F10).

---

#### R04 `VEHICLE_GPS_MISSING` | Safety | HIGH

**Purpose:** Find buses on active routes that have no GPS device registered.

**Query:**

```sql
SELECT DISTINCT v.id, COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle
FROM   tpt_vehicle v
JOIN   tpt_driver_route_vehicle_jnt a ON a.vehicle_id = v.id
WHERE  v.deleted_at IS NULL AND v.is_active = 1
  AND  (v.gps_device_id IS NULL OR v.gps_device_id = '')
  AND  /* [ACTIVE ASSIGNMENT] */ a.deleted_at IS NULL AND a.is_active = 1
  AND  DATE(a.effective_from) <= CURDATE()
  AND  (a.effective_to IS NULL OR DATE(a.effective_to) >= CURDATE());
```

**Logic:** One suggestion per vehicle. `benefitAmount` = 1, unit `device`.

**Example (illustrative):** Vehicle KI 99 JQ 3120 on Route 4 has no GPS terminal; install an AIS-140 unit.

**Status:** Working. No output on the sample screen because every active bus has a GPS ID.

---

#### R05 `VEHICLE_UNAVAILABLE_ASSIGNED` | Operations | HIGH

**Purpose:** Find vehicles marked "Not Available" that are still rostered on an active route.

**Query:**

```sql
SELECT DISTINCT v.id, COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle
FROM   tpt_vehicle v
JOIN   tpt_driver_route_vehicle_jnt a ON a.vehicle_id = v.id
WHERE  v.deleted_at IS NULL
  AND  v.availability_status = 0
  AND  /* [ACTIVE ASSIGNMENT] */ a.deleted_at IS NULL AND a.is_active = 1
  AND  DATE(a.effective_from) <= CURDATE()
  AND  (a.effective_to IS NULL OR DATE(a.effective_to) >= CURDATE());
```

**Logic:** One suggestion per vehicle; action is to assign a standby vehicle or restore the availability status after verification.

**Example (illustrative):** Vehicle HC 37 LQ 7133 is "Not Available" but is rostered on Route 2.

**Status:** Working.

---

#### R06 `VEHICLE_RENTED_REVIEW` | Saving | LOW

**Purpose:** Prompt a cost review for rented or leased vehicles.

**Query:**

```sql
SELECT v.id, COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle,
       v.capacity, d.value AS ownership_type
FROM   tpt_vehicle v
JOIN   sys_dropdown_table d ON d.id = v.ownership_type_id
WHERE  v.deleted_at IS NULL AND v.is_active = 1
  AND (UPPER(d.value) LIKE '%RENTED%' OR UPPER(d.value) LIKE '%LEASED%' OR UPPER(d.value) LIKE '%VENDOR%');
```

**Logic:** One suggestion per vehicle. `benefitAmount` is a fixed ₹150,000 (an indicative annual saving, not a computed value).

**Status:** Working.

---

### Group 2: Drivers and Crew

#### R07 `DRIVER_LICENSE_EXPIRY` | Safety | HIGH or MEDIUM

**Purpose:** Warn before a driver's licence expires.

**Query:**

```sql
SELECT p.id, p.name, p.role, p.license_valid_upto,
       DATEDIFF(p.license_valid_upto, CURDATE()) AS days_left
FROM   tpt_personnel p
WHERE  p.deleted_at IS NULL AND p.is_active = 1
  AND  p.role IN ('Driver', 'Both')
  AND  p.license_valid_upto IS NOT NULL
  AND  DATEDIFF(p.license_valid_upto, CURDATE()) <= 30;
```

**Logic:** One suggestion per driver. Priority is HIGH when expired or 7 days or fewer remain; otherwise MEDIUM. The driver's current routes (from the active assignments) are included in the text.

**Example (illustrative):** Driver Ramesh Patel, licence valid until 1 Nov 2026 (20 days left), on Route 3: MEDIUM, "renew this week and keep a backup driver".

**Status:** Working (see finding F13).

---

#### R08 `HELPER_POLICE_VERIFICATION_PENDING` | Safety | HIGH

**Purpose:** Find transport staff without cleared police verification.

**Query:**

```sql
SELECT p.id, p.name, p.role
FROM   tpt_personnel p
WHERE  p.deleted_at IS NULL AND p.is_active = 1
  AND  p.police_verification_done = 0;
```

**Logic:** One grouped suggestion. `driverCount` = rows with role `Driver`; `helperCount` = rows with role `Helper`. `benefitAmount` = total staff, unit `personnel`.

**Example:** 50 staff = 35 drivers + 15 attendants. Sample names: Kamlesh Lala, Wafiq Bose, Kamlesh Kapoor, Marlo Natarajan, "and 46 other transport staff".

**Status:** Working.

---

#### R09 `DRIVER_LOW_EXP_LONG_ROUTE` | Safety | MEDIUM

**Purpose:** Flag novice drivers on active routes.

**Query:**

```sql
SELECT p.id, p.name, p.driving_exp_months, r.name AS route_name
FROM   tpt_personnel p
JOIN   tpt_driver_route_vehicle_jnt a ON a.driver_id = p.id
JOIN   tpt_route r ON r.id = a.route_id AND r.deleted_at IS NULL
WHERE  p.deleted_at IS NULL AND p.is_active = 1 AND p.role = 'Driver'
  AND  p.driving_exp_months > 0 AND p.driving_exp_months < 12
  AND  /* [ACTIVE ASSIGNMENT] */ a.deleted_at IS NULL AND a.is_active = 1
  AND  DATE(a.effective_from) <= CURDATE()
  AND  (a.effective_to IS NULL OR DATE(a.effective_to) >= CURDATE());
```

**Logic:** One suggestion per driver (first assignment). Note: route length is **not** measured; any assigned route qualifies.

**Example (illustrative):** Driver with 8 months' experience on Route 5.

**Status:** Working (see finding F16).

---

#### R10 `DRIVER_FREQUENT_ABSENT_STANDBY` | Service | MEDIUM

**Purpose:** Detect drivers with very few completed trips in the last month (a proxy for irregular attendance).

**Query:**

```sql
SELECT d.id, d.name, COUNT(t.id) AS trips_30d
FROM   tpt_personnel d
JOIN   tpt_trip t ON t.driver_id = d.id AND t.deleted_at IS NULL
                 AND t.trip_date >= CURDATE() - INTERVAL 30 DAY
WHERE  d.deleted_at IS NULL AND d.is_active = 1 AND d.role = 'Driver'
GROUP  BY d.id, d.name
HAVING trips_30d BETWEEN 1 AND 7;
```

**Logic:** A driver with 1 to 7 trips in 30 days is flagged. Drivers with zero trips are not flagged. The count includes every trip row regardless of status.

**Example (illustrative):** A driver with 5 trips in 30 days: "assign a relief driver to the morning standby bench".

**Status:** Working (see finding F16).

---

#### R11 `DRIVER_OVERTIME_FATIGUE` | Safety | HIGH

**Purpose:** Find drivers whose daily duty spread (first start to last end) is 11 hours or more on at least 3 days in the last 15 days.

**Query:**

```sql
SELECT driver_id, COUNT(*) AS long_duty_days
FROM (
    SELECT t.driver_id, t.trip_date,
           TIMESTAMPDIFF(HOUR, MIN(t.start_time), MAX(t.end_time)) AS spread_hours
    FROM   tpt_trip t
    WHERE  t.deleted_at IS NULL
      AND  t.trip_date >= CURDATE() - INTERVAL 15 DAY
      AND  t.start_time IS NOT NULL AND t.end_time IS NOT NULL
    GROUP  BY t.driver_id, t.trip_date
    HAVING spread_hours >= 11
) x
GROUP  BY driver_id
HAVING COUNT(*) >= 3;
```

**Logic:** `spread_hours` is whole hours between the earliest start and the latest end on the same day. `benefitAmount` = number of long days, unit `days`.

**Example (illustrative):** Driver logs 06:40 start and 18:10 end on 4 days: spread 11 hours, 4 long days: HIGH.

**Status:** Working.

---

#### R12 `ATTENDANCE_MANUAL_EXCESSIVE` | Operations | MEDIUM

**Purpose:** Find routes where most boarding entries were recorded without an attendance device (manual entry).

**Query:**

```sql
SELECT l.boarding_route_id AS route_id,
       COUNT(*) AS total_logs,
       SUM(l.device_id IS NULL) AS manual_logs,
       ROUND(100 * SUM(l.device_id IS NULL) / COUNT(*), 1) AS manual_pct
FROM   tpt_student_boarding_log l
WHERE  l.deleted_at IS NULL
  AND  l.trip_date >= CURDATE() - INTERVAL 30 DAY
GROUP  BY l.boarding_route_id
HAVING total_logs >= 20 AND manual_pct >= 50;
```

**Logic:**

- "Manual" means `device_id IS NULL`.
- If **3 or more** routes qualify, one grouped suggestion is produced with `overall_pct = SUM(manual) / SUM(total) x 100` across the qualifying routes.
- If fewer than 3 qualify, one suggestion per route.

**Example:** 11 routes qualify; 2,400 of 2,400 boardings manual: overall 100%.

**Status:** Working.

---

#### R13 `ATTENDANCE_SCAN_ANOMALIES` | Operations | LOW

**Purpose:** Detect rapid duplicate scans (same student, same route, same day, within 2 minutes).

**Query (equivalent form):**

```sql
SELECT a.boarding_route_id AS route_id, COUNT(*) AS duplicate_events
FROM   tpt_student_boarding_log a
JOIN   tpt_student_boarding_log b
       ON  b.student_id = a.student_id
       AND b.trip_date = a.trip_date
       AND b.boarding_route_id = a.boarding_route_id
       AND b.boarding_time > a.boarding_time
       AND TIMESTAMPDIFF(SECOND, a.boarding_time, b.boarding_time) < 120
WHERE  a.deleted_at IS NULL AND b.deleted_at IS NULL
  AND  a.trip_date >= CURDATE() - INTERVAL 15 DAY
GROUP  BY a.boarding_route_id
HAVING duplicate_events >= 3;
```

**Logic:** The engine sorts each student-day by time and compares consecutive entries; 3 or more such pairs on a route trigger a LOW suggestion.

**Status:** Working.

---

### Group 3: Routes and Capacity

#### R14 `ROUTE_OVERLOADED` | Safety | HIGH

**Purpose:** Find routes carrying more students than the assigned vehicle has seats, and propose a fix.

**Data sources:** `tpt_student_route_allocation_jnt`, `tpt_driver_route_vehicle_jnt`, `tpt_vehicle`, `tpt_route`.

**Query:**

```sql
SELECT r.id AS route_id, r.name AS route_name, r.shift_id, r.pickup_drop,
       COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS bus,
       v.capacity,
       GREATEST(COALESCE(p.cnt, 0), COALESCE(d.cnt, 0)) AS students
FROM   tpt_route r
JOIN   tpt_driver_route_vehicle_jnt a ON a.route_id = r.id
JOIN   tpt_vehicle v ON v.id = a.vehicle_id AND v.deleted_at IS NULL
LEFT JOIN (SELECT pickup_route_id AS route_id, COUNT(DISTINCT student_id) AS cnt
           FROM tpt_student_route_allocation_jnt
           WHERE deleted_at IS NULL AND active_status = 1 AND pickup_route_id IS NOT NULL
           GROUP BY pickup_route_id) p ON p.route_id = r.id
LEFT JOIN (SELECT drop_route_id AS route_id, COUNT(DISTINCT student_id) AS cnt
           FROM tpt_student_route_allocation_jnt
           WHERE deleted_at IS NULL AND active_status = 1 AND drop_route_id IS NOT NULL
           GROUP BY drop_route_id) d ON d.route_id = r.id
WHERE  r.deleted_at IS NULL AND r.is_active = 1
  AND  /* [ACTIVE ASSIGNMENT] */ a.deleted_at IS NULL AND a.is_active = 1
  AND  DATE(a.effective_from) <= CURDATE()
  AND  (a.effective_to IS NULL OR DATE(a.effective_to) >= CURDATE())
  AND  GREATEST(COALESCE(p.cnt, 0), COALESCE(d.cnt, 0)) > v.capacity;
```

**Logic:**

```
extra            = students - capacity
utilization_pct  = ROUND(students / capacity x 100)

Alternative route = another active route with
     the same shift_id AND the same pickup/drop type
     AND capacity > 0 AND free seats (capacity - students) > 0,
     choosing the route with the most free seats.

Action text:
  alternative found     -> "Move {extra} students to '{alt}', which has {free} free seats"
                           (adds "arrange an additional vehicle for the remaining" when free < extra)
  no alternative found  -> "Arrange an additional vehicle ... or split the route"
```

Results are sorted by `extra`, largest first.

**Worked example (Route 2):**

| Step | Value |
|---|---|
| Pickup count | 40 |
| Drop count | 38 |
| `students` = GREATEST(40, 38) | 40 |
| Assigned bus | UQ 87 QC 1359, capacity 30 |
| `extra` | 40 - 30 = 10 |
| `utilization_pct` | 40 / 30 x 100 = 133% |
| Alternative | Route 3 (same shift, 10 free seats) |
| Output | "Move 10 students to 'Route 3', which has 10 free seats" |

**Other results on the sample screen:** Route 10 (40 vs 30, alternative Route 7), Route 1 (41 vs 40, alternative Route 3), Route 6 (41 vs 40, alternative Route 7).

**Status:** Working.

---

#### R15 `VEHICLE_SIZE_MISMATCH` | Saving | MEDIUM

**Purpose:** Find large buses (35 or more seats) carrying 15 students or fewer.

**Intended logic:**

```sql
-- using the route-load result from Section 3.2
SELECT route_id, route_name, capacity, students,
       ROUND(100 * students / capacity, 1) AS load_pct
FROM   route_load
WHERE  capacity >= 35 AND students > 0 AND students <= 15;
```

`benefitAmount` = 25, unit `percent` (an estimated fuel reduction from using a 20-seat vehicle).

**Example (illustrative):** Route 9: 40-seat bus, 12 students = 30% load.

**Status:** Not producing output (see finding F2).

---

#### R16 `LOW_STUDENT_STOP` | Saving | MEDIUM

**Purpose:** Find stops on active routes that have no allocated students, so buses can bypass them.

**Query:**

```sql
SELECT l.route_id, r.name AS route_name, s.id AS stop_id, s.name AS stop_name,
       COUNT(DISTINCT x.student_id) AS students
FROM   tpt_pickup_points_route_jnt l
JOIN   tpt_route r ON r.id = l.route_id AND r.deleted_at IS NULL AND r.is_active = 1
JOIN   tpt_pickup_points s ON s.id = l.pickup_point_id AND s.deleted_at IS NULL
LEFT JOIN (
        SELECT student_id, pickup_route_id AS route_id, pickup_stop_id AS stop_id
        FROM   tpt_student_route_allocation_jnt
        WHERE  deleted_at IS NULL AND active_status = 1
          AND  pickup_route_id IS NOT NULL AND pickup_stop_id IS NOT NULL
        UNION
        SELECT student_id, drop_route_id, drop_stop_id
        FROM   tpt_student_route_allocation_jnt
        WHERE  deleted_at IS NULL AND active_status = 1
          AND  drop_route_id IS NOT NULL AND drop_stop_id IS NOT NULL
      ) x ON x.route_id = l.route_id AND x.stop_id = l.pickup_point_id
WHERE  l.deleted_at IS NULL AND l.is_active = 1
  AND  (SELECT COUNT(*) FROM tpt_pickup_points_route_jnt z
        WHERE z.route_id = l.route_id AND z.deleted_at IS NULL) > 2
GROUP  BY l.route_id, r.name, s.id, s.name
HAVING students = 0;
```

**Logic:**

- Only routes with more than 2 stops are examined.
- Stops with 1 or 2 students are identified but **not** reported in the current output.
- If **3 or more** routes contain empty stops, one fleet-level suggestion is produced; otherwise one suggestion per route.

**Formulas:**

```
Time saved (fleet level)  = empty_stops x 4 minutes
Time saved (single route) = empty_stops x 5 minutes

Monthly diesel saving (fleet level)
  = ROUND( empty_stops x 0.8 km x 22 working days / 3.8 km per litre x ₹95 per litre )
```

**Worked example (sample screen):**

| Step | Value |
|---|---|
| Empty stops | 30 across 10 routes |
| Time saved | 30 x 4 = 120 minutes per day |
| Distance | 30 x 0.8 = 24 km per day |
| Monthly distance | 24 x 22 = 528 km |
| Litres | 528 / 3.8 = 138.9 L |
| Monthly saving | 138.9 x ₹95 = ₹13,200 |

**Status:** Working (see finding F10).

---

#### R17 `HELPER_MISSING_PREPRIMARY` | Safety | HIGH

**Purpose:** Find active route assignments with no helper (attendant).

**Query:**

```sql
SELECT a.route_id, r.name AS route_name
FROM   tpt_driver_route_vehicle_jnt a
JOIN   tpt_route r ON r.id = a.route_id AND r.deleted_at IS NULL
WHERE  /* [ACTIVE ASSIGNMENT] */ a.deleted_at IS NULL AND a.is_active = 1
  AND  DATE(a.effective_from) <= CURDATE()
  AND  (a.effective_to IS NULL OR DATE(a.effective_to) >= CURDATE())
  AND  a.helper_id IS NULL;
```

**Logic:** One grouped suggestion; `benefitAmount` = number of routes, unit `routes`. The text refers to a "female attendant", but the database has no gender field; the rule only tests for an empty helper.

**Example on screen:** "10 active routes (Route 1, Route 2, Route 3, Route 4, and 6 other routes)".

**Status:** Working (review): see finding F5. The screen count equals the total number of routes, which suggests every assignment is being flagged.

---

#### R18 `ROUTE_DRIVER_VEHICLE_UNASSIGNED` | Operations | HIGH

**Purpose:** Find active routes with no active assignment at all.

**Query:**

```sql
SELECT r.id, r.name
FROM   tpt_route r
WHERE  r.deleted_at IS NULL AND r.is_active = 1
  AND  NOT EXISTS (
        SELECT 1
        FROM   tpt_driver_route_vehicle_jnt a
        WHERE  a.route_id = r.id AND a.deleted_at IS NULL AND a.is_active = 1
          AND  DATE(a.effective_from) <= CURDATE()
          AND  (a.effective_to IS NULL OR DATE(a.effective_to) >= CURDATE()));
```

**Logic:** One suggestion per route. A route with an assignment that lacks a vehicle or a driver is not detected by this rule.

**Status:** Working.

---

#### R19 `ASSIGNMENT_EXPIRING_SOON` | Operations | MEDIUM

**Purpose:** Warn when an assignment end date is within 10 days.

**Query:**

```sql
SELECT a.id, r.name AS route_name, a.effective_to,
       DATEDIFF(a.effective_to, CURDATE()) AS days_left
FROM   tpt_driver_route_vehicle_jnt a
JOIN   tpt_route r ON r.id = a.route_id
WHERE  a.deleted_at IS NULL AND a.is_active = 1 AND a.effective_to IS NOT NULL
  AND  DATE(a.effective_to) BETWEEN CURDATE() AND CURDATE() + INTERVAL 10 DAY;
```

**Example (illustrative):** Route 4 assignment ends 20 Oct 2026: 8 days left; extend or rotate the crew.

**Status:** Working.

---

#### R20 `SHIFT_LOAD_IMBALANCE` | Service | LOW

**Purpose:** Find routes with a large gap between pickup and drop passenger counts.

**Query:** Uses the two counts from Section 3.2.

```sql
SELECT r.id, r.name, p.cnt AS pickup_students, d.cnt AS drop_students,
       ABS(p.cnt - d.cnt) AS diff,
       ROUND(100 * ABS(p.cnt - d.cnt) / GREATEST(p.cnt, d.cnt), 1) AS imbalance_pct
FROM   tpt_route r
JOIN   pickup_counts p ON p.route_id = r.id
JOIN   drop_counts   d ON d.route_id = r.id
WHERE  r.deleted_at IS NULL AND r.is_active = 1
  AND  GREATEST(p.cnt, d.cnt) >= 20
  AND  ABS(p.cnt - d.cnt) / GREATEST(p.cnt, d.cnt) >= 0.5;
```

**Example (illustrative):** Route 8: 38 pickup, 14 drop; difference 24; imbalance 63%.

**Status:** Working.

---

#### R21 `STOP_SEQUENCE_OPTIMIZATION` | Saving | LOW

**Purpose:** Detect zig-zag stop order along a route using latitude direction changes.

**Query:**

```sql
SELECT l.route_id, l.ordinal, s.name, s.latitude
FROM   tpt_pickup_points_route_jnt l
JOIN   tpt_pickup_points s ON s.id = l.pickup_point_id
WHERE  l.deleted_at IS NULL
ORDER  BY l.route_id, l.ordinal;
```

**Logic:** For each route with at least 4 stops (and 4 stops with a latitude):

```
d1 = lat[i+1] - lat[i]
d2 = lat[i+2] - lat[i+1]
reversal when (d1 > 0 and d2 < 0) or (d1 < 0 and d2 > 0)
```

If reversals are 3 or more, the route is flagged. `benefitAmount` = 15 minutes (fixed estimate).

**Worked example (illustrative):** Latitudes 21.17, 21.19, 21.16, 21.20, 21.15.

| i | d1 | d2 | Reversal |
|---|---|---|---|
| 0 | +0.02 | -0.03 | Yes (1) |
| 1 | -0.03 | +0.04 | Yes (2) |
| 2 | +0.04 | -0.05 | Yes (3) |

Three reversals: flagged. Only latitude is checked, so a purely east-west route is never flagged.

**Status:** Working.

---

#### R22 `ROUTE_MERGE_CANDIDATE` | Saving | MEDIUM

**Purpose:** Find two low-load routes (16 students or fewer each) whose combined load (32 or fewer) fits one bus.

**Intended logic:**

```sql
SELECT a.route_id AS route_a, b.route_id AS route_b, a.students + b.students AS combined
FROM   route_load a
JOIN   route_load b ON b.route_id > a.route_id
WHERE  a.students BETWEEN 1 AND 16 AND b.students BETWEEN 1 AND 16
  AND  a.students + b.students <= 32;
```

Only the first pair is reported. `benefitAmount` = ₹40,000 per month (fixed estimate). The rule does not compare shift, direction or geography.

**Status:** Not producing output (see finding F2).

---

#### R23 `STOP_TRANSFER_EFFICIENCY` | Saving | LOW

**Purpose:** Find pickup stops serving exactly one student.

**Query:**

```sql
SELECT pickup_route_id AS route_id, pickup_stop_id AS stop_id, COUNT(*) AS cnt
FROM   tpt_student_route_allocation_jnt
WHERE  deleted_at IS NULL AND active_status = 1
GROUP  BY pickup_route_id, pickup_stop_id
HAVING cnt = 1
LIMIT  5;
```

**Logic:** At most 5 results, with no particular ordering. `benefitAmount` = 8 minutes (fixed estimate).

**Status:** Working.

---

#### R24 `ONE_WAY_COMMUTE_PLAN` | Income | LOW

**Purpose:** Highlight students who use only one direction.

**Query:**

```sql
SELECT COUNT(*) AS one_way_students
FROM   tpt_student_route_allocation_jnt
WHERE  deleted_at IS NULL AND active_status = 1
  AND  transport_use_type IN ('Pickup', 'Drop')
HAVING one_way_students >= 5;
```

**Logic:** One grouped suggestion; `benefitAmount` = number of one-way students.

**Status:** Working.

---

#### R25 `ALLOCATION_DATA_INCONSISTENCY` | Operations | HIGH

**Purpose:** Find "Both" allocations that have no drop route or drop stop.

**Query:**

```sql
SELECT COUNT(*) AS inconsistent
FROM   tpt_student_route_allocation_jnt
WHERE  deleted_at IS NULL AND active_status = 1
  AND  transport_use_type = 'Both'
  AND  (drop_route_id IS NULL OR drop_stop_id IS NULL);
```

**Logic:** One grouped suggestion with the number of incomplete records.

**Status:** Working.

---

### Group 4: Fees and Revenue

#### R26 `ROUTE_FINANCIAL_DEFICIT` | Income | HIGH

**Purpose:** Find routes whose monthly fare income is below the fuel cost of the assigned vehicle.

**Query:**

```sql
SELECT r.id, r.name,
       rev.revenue,
       fuel.fuel_cost,
       fuel.fuel_cost - rev.revenue AS deficit
FROM   tpt_route r
JOIN  (SELECT pickup_route_id AS route_id, SUM(fare) AS revenue
       FROM   tpt_student_route_allocation_jnt
       WHERE  deleted_at IS NULL AND active_status = 1
       GROUP  BY pickup_route_id) rev ON rev.route_id = r.id
JOIN   tpt_driver_route_vehicle_jnt a ON a.route_id = r.id
       /* [ACTIVE ASSIGNMENT] */ AND a.deleted_at IS NULL AND a.is_active = 1
       AND DATE(a.effective_from) <= CURDATE()
       AND (a.effective_to IS NULL OR DATE(a.effective_to) >= CURDATE())
JOIN  (SELECT vehicle_id, SUM(cost) AS fuel_cost
       FROM   tpt_vehicle_fuel
       WHERE  deleted_at IS NULL AND `date` >= CURDATE() - INTERVAL 30 DAY
       GROUP  BY vehicle_id) fuel ON fuel.vehicle_id = a.vehicle_id
WHERE  r.deleted_at IS NULL AND r.is_active = 1
  AND  fuel.fuel_cost > 0 AND rev.revenue > 0 AND rev.revenue < fuel.fuel_cost;
```

**Logic:** `deficit = fuel_cost - revenue`. Revenue is counted by pickup route only. Fuel includes every voucher status.

**Example (illustrative):** Route 7: revenue ₹31,200; fuel ₹38,900; deficit ₹7,700.

**Status:** Working (see finding F12).

---

#### R27 `FEE_PENDING` | Income | HIGH or MEDIUM

**Purpose:** Quantify transport fees overdue beyond the grace period.

**Query:**

```sql
SELECT COUNT(*)                                   AS bills,
       COUNT(DISTINCT std_academic_sessions_id)   AS students,
       COUNT(DISTINCT `month`)                    AS months,
       MIN(due_date)                              AS oldest_due,
       SUM(COALESCE(total_amount, amount, 0))     AS amount
FROM   tpt_student_fee_detail
WHERE  deleted_at IS NULL
  AND  LOWER(status) IN ('pending', 'overdue')
  AND  due_date < CURDATE() - INTERVAL 30 DAY;
```

**Logic:**

```
oldest_days = whole days between oldest_due and today
priority    = HIGH when oldest_days > 90, otherwise MEDIUM
benefitAmount = amount (unit: rupees)
```

"Students" is the count of distinct academic-session IDs, which acts as a student count.

**Worked example (sample screen):**

| Field | Value |
|---|---|
| Students | 32 |
| Billing months | 3 |
| Oldest due date | 11 Apr 2025 |
| Oldest days | 11 Apr 2025 to 12 Oct 2026 = 549 days |
| Amount | ₹79,159 |
| Priority | 549 > 90, so HIGH |

**Status:** Working.

---

#### R28 `UNUSED_ALLOCATION` | Income | MEDIUM

**Purpose:** Find students with an active transport allocation who have not used the bus in the last 30 days.

**Query (in three steps):**

```sql
-- Step 1: students who boarded or unboarded in the window
SELECT DISTINCT student_id
FROM   tpt_student_boarding_log
WHERE  deleted_at IS NULL AND student_id IS NOT NULL
  AND  trip_date BETWEEN CURDATE() - INTERVAL 30 DAY AND CURDATE()
  AND  (boarding_time IS NOT NULL OR unboarding_time IS NOT NULL);

-- Step 2: routes that actually have boarding data in the window
SELECT DISTINCT boarding_route_id   FROM tpt_student_boarding_log
WHERE  deleted_at IS NULL AND trip_date >= CURDATE() - INTERVAL 30 DAY AND boarding_route_id IS NOT NULL
UNION
SELECT DISTINCT unboarding_route_id FROM tpt_student_boarding_log
WHERE  deleted_at IS NULL AND trip_date >= CURDATE() - INTERVAL 30 DAY AND unboarding_route_id IS NOT NULL;

-- Step 3: allocations on those routes whose student is NOT in Step 1
SELECT COALESCE(a.pickup_route_id, a.drop_route_id) AS route_id,
       COUNT(*) AS unused_students, SUM(a.fare) AS fare_value
FROM   tpt_student_route_allocation_jnt a
WHERE  a.deleted_at IS NULL AND a.active_status = 1
  AND  a.effective_from <= CURDATE() - INTERVAL 30 DAY
  AND  COALESCE(a.pickup_route_id, a.drop_route_id) IN (/* Step 2 */)
  AND  a.student_id NOT IN (/* Step 1 */)
GROUP  BY COALESCE(a.pickup_route_id, a.drop_route_id);
```

**Safeguards built into the rule:**

| Safeguard | Reason |
|---|---|
| If Step 1 returns nothing, the rule stops | Prevents flagging every student when no boarding data exists |
| Only routes with boarding data (Step 2) | Avoids flagging routes where scanning is not recorded |
| `effective_from` at least 30 days old | New allocations are not flagged |

**Example:** Route 1: 1 student (Vivaan Bhat), fare ₹1,200. Title: "Inactive seat reservation on Route 1 (1 student)". `benefitAmount` = sum of fares.

**Status:** Working.

---

#### R29 `FARE_DISCREPANCY_TWO_WAY` | Income | LOW

**Purpose:** Detect a two-way fare that is more than 2.1 times the one-way fare.

**Intended query:**

```sql
SELECT AVG(CASE WHEN transport_use_type = 'Both' THEN fare END) AS avg_both,
       COALESCE(AVG(CASE WHEN transport_use_type = 'Pickup' THEN fare END),
                AVG(CASE WHEN transport_use_type = 'Drop'   THEN fare END)) AS avg_one_way
FROM   tpt_student_route_allocation_jnt
WHERE  deleted_at IS NULL AND active_status = 1
HAVING avg_both > 2.1 * avg_one_way;
```

`benefitAmount = ROUND(avg_both - 2 x avg_one_way)`.

**Example (illustrative):** Average two-way ₹2,600, one-way ₹1,100: 2,600 > 2,310; difference ₹400.

**Status:** Not producing output (see finding F3).

---

#### R30 `FINE_WAIVER_EXCESSIVE` | Income | MEDIUM

**Query:**

```sql
SELECT SUM(fine_amount) AS total_fine,
       SUM(waved_fine_amount) AS total_waived,
       ROUND(100 * SUM(waved_fine_amount) / SUM(fine_amount), 1) AS waived_pct
FROM   tpt_student_fine_detail
WHERE  deleted_at IS NULL
HAVING total_fine > 5000 AND waived_pct >= 50;
```

**Example (illustrative):** Fines ₹60,000, waived ₹33,000: 55%. `benefitAmount` = total waived.

**Status:** Working.

---

#### R31 `FINE_POLICY_INEFFECTIVE` | Income | LOW

**Query:**

```sql
SELECT COUNT(*) AS delayed_payments, ROUND(AVG(total_delay_days)) AS avg_delay_days
FROM   tpt_student_fee_collection
WHERE  deleted_at IS NULL AND total_delay_days > 15
HAVING delayed_payments >= 10;
```

**Example (illustrative):** 24 payments, average delay 22 days. `benefitAmount` = average delay in days.

**Status:** Working.

---

#### R32 `UNRECONCILED_PAYMENTS` | Compliance | HIGH

**Query:**

```sql
SELECT COUNT(*) AS transactions, SUM(paid_amount) AS total_amount
FROM   tpt_student_fee_collection
WHERE  deleted_at IS NULL AND reconciled = 0
HAVING transactions > 0;
```

**Example (illustrative):** 85 payments, ₹1,42,500 unreconciled. Any unreconciled payment triggers a HIGH suggestion.

**Status:** Working.

---

#### R33 `CASH_TRANSACTION_OVERHEAD` | Saving | LOW

**Query:**

```sql
SELECT COUNT(*) AS total_payments,
       SUM(payment_mode = 'Cash') AS cash_payments,
       SUM(CASE WHEN payment_mode = 'Cash' THEN paid_amount ELSE 0 END) AS cash_amount,
       ROUND(100 * SUM(payment_mode = 'Cash') / COUNT(*), 1) AS cash_pct
FROM   tpt_student_fee_collection
WHERE  deleted_at IS NULL
HAVING total_payments >= 20 AND cash_pct >= 50;
```

**Note:** The engine performs the comparison in memory and is case-sensitive; the value must be exactly `Cash`.

**Status:** Working (review): see finding F7.

---

#### R34 `FEE_DEFAULT_RESTRICTION_WARNING` | Income | HIGH

**Query:**

```sql
SELECT COUNT(*) AS accounts, SUM(total_amount) AS arrears
FROM   tpt_student_fee_detail
WHERE  deleted_at IS NULL AND status = 'Unpaid'
  AND  due_date <= CURDATE() - INTERVAL 60 DAY
HAVING accounts > 0;
```

**Example (illustrative):** 14 accounts, ₹52,300 arrears older than 60 days.

**Status:** Working (review): see finding F7. The table's default status is `Pending`, not `Unpaid`.

---

### Group 5: Trips and Schedules

#### R35 `LATE_RUNNING_STOP` | Service | MEDIUM

**Purpose:** Find stops where the bus arrives late on most days.

**Query:**

```sql
SELECT d.stop_id, p.name AS stop_name,
       COUNT(*) AS trips_checked,
       SUM(TIMESTAMPDIFF(SECOND, d.sch_arrival_time, d.reaching_time) / 60 > 5) AS late_trips,
       AVG(CASE WHEN TIMESTAMPDIFF(SECOND, d.sch_arrival_time, d.reaching_time) / 60 > 5
                THEN TIMESTAMPDIFF(SECOND, d.sch_arrival_time, d.reaching_time) / 60 END) AS avg_late_min,
       MAX(d.sch_arrival_time) AS latest_scheduled
FROM   tpt_trip_stop_detail d
JOIN   tpt_pickup_points p ON p.id = d.stop_id
WHERE  d.deleted_at IS NULL AND d.reached_flag = 1
  AND  d.reaching_time IS NOT NULL AND d.sch_arrival_time IS NOT NULL
  AND  d.sch_arrival_time >= CURDATE() - INTERVAL 30 DAY
  AND  d.sch_arrival_time <  CURDATE() + INTERVAL 1 DAY
GROUP  BY d.stop_id, p.name
HAVING trips_checked >= 5
   AND 100 * late_trips / trips_checked >= 60;
```

**Formulas:**

```
delay (minutes)  = (actual arrival - scheduled arrival) / 60
late trip        = delay > 5 minutes
late share       = late_trips / trips_checked x 100        (must be 60% or more)
avg_late         = average delay of the late trips only
new time         = latest scheduled time + CEILING(avg_late / 5) x 5 minutes
```

**Worked example (illustrative):** Stop "City Light", 22 trips, 18 late (81.8%), average late 11.2 min.

- CEILING(11.2 / 5) = 3; 3 x 5 = 15 minutes.
- Latest scheduled 07:40 AM gives proposed 07:55 AM.

**Status:** Working. The action wording ("advance ... earlier") and the proposed later time point in opposite directions (see finding F14).

---

#### R36 `SKIPPED_STOP_ANOMALY` | Service | HIGH

**Purpose:** Find stops with registered students that buses frequently did not reach.

**Query:**

```sql
SELECT d.stop_id, p.name AS stop_name,
       COUNT(*) AS total_runs,
       SUM(d.reached_flag = 0) AS skipped,
       ROUND(100 * SUM(d.reached_flag = 0) / COUNT(*), 1) AS skip_pct
FROM   tpt_trip_stop_detail d
JOIN   tpt_pickup_points p ON p.id = d.stop_id
WHERE  d.deleted_at IS NULL
  AND  d.created_at >= CURDATE() - INTERVAL 30 DAY
  AND  d.stop_id IN (
         SELECT pickup_stop_id FROM tpt_student_route_allocation_jnt
         WHERE  deleted_at IS NULL AND active_status = 1 AND pickup_stop_id IS NOT NULL
         UNION
         SELECT drop_stop_id   FROM tpt_student_route_allocation_jnt
         WHERE  deleted_at IS NULL AND active_status = 1 AND drop_stop_id   IS NOT NULL)
GROUP  BY d.stop_id, p.name
HAVING total_runs >= 10 AND skipped >= 5 AND skipped / total_runs >= 0.25;
```

**Logic:** If 3 or more stops qualify, one grouped suggestion (total missed = sum of `skipped`); otherwise one suggestion per stop.

**Example:** 7 stops, 210 missed visits; sample: "Stop 1 (Morning Pickup) (45 missed), Stop 10 (Morning Pickup) (30 missed), Stop 4 (30 missed), Stop 5 (Afternoon Drop) (30 missed), and 3 other stops".

**Status:** Working (review): see finding F8. The query counts every stop row, including rows of trips that never ran.

---

#### R37 `TRIP_APPROVAL_BACKLOG` | Operations | MEDIUM

**Query:**

```sql
SELECT COUNT(*) AS pending_trips, MIN(trip_date) AS oldest_trip
FROM   tpt_trip
WHERE  deleted_at IS NULL AND status = 'Completed' AND approved = 0
HAVING pending_trips >= 15;
```

**Example:** 116 completed trips awaiting approval; oldest 26 Sep 2026 (16 days old).

**Status:** Working.

---

#### R38 `TRIP_DURATION_VARIANCE` | Service | MEDIUM

**Query:**

```sql
SELECT route_id,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, start_time, end_time))) AS avg_minutes
FROM   tpt_trip
WHERE  deleted_at IS NULL AND trip_date >= CURDATE() - INTERVAL 15 DAY
  AND  start_time IS NOT NULL AND end_time IS NOT NULL
GROUP  BY route_id
HAVING avg_minutes >= 70;
```

**Example (illustrative):** Route 9 averages 78 minutes; recommended maximum 45 minutes; split the route.

**Status:** Working.

---

#### R39 `REPEATED_EMERGENCY_STOP` | Safety | HIGH

**Query:**

```sql
SELECT d.stop_id, p.name, COUNT(*) AS emergencies
FROM   tpt_trip_stop_detail d
JOIN   tpt_pickup_points p ON p.id = d.stop_id
WHERE  d.deleted_at IS NULL AND d.emergency_flag = 1
  AND  d.created_at >= CURDATE() - INTERVAL 60 DAY
GROUP  BY d.stop_id, p.name;
```

**Logic:** One suggestion per stop. There is no minimum count, so a single emergency triggers it despite the word "recurrent" in the title.

**Status:** Working (review): see finding F11.

---

#### R40 `PEAK_TRAFFIC_TIMING_ADJUSTMENT` | Service | LOW

**Query:**

```sql
SELECT route_id,
       COUNT(*) AS trips_30d,
       SUM(TIME(start_time) >= '07:45:00') AS late_departures
FROM   tpt_trip
WHERE  deleted_at IS NULL AND trip_date >= CURDATE() - INTERVAL 30 DAY
  AND  start_time IS NOT NULL AND end_time IS NOT NULL
GROUP  BY route_id
HAVING trips_30d >= 10 AND late_departures >= 5;
```

**Logic:** Only the **first** qualifying route produces a suggestion (one fleet-wide advice). The delay figures in the text (12 to 18 minutes) are standard wording, not measured. `benefitAmount` = 15 minutes.

**Example:** Route 6.

**Status:** Working (review): see finding F18.

---

### Group 6: Fuel and Maintenance

#### R41 `MILEAGE_EFFICIENCY_ALERT` | Saving | MEDIUM

**Query:**

```sql
SELECT f.vehicle_id,
       MAX(f.odometer_reading) - MIN(f.odometer_reading)                       AS distance_km,
       SUM(f.quantity)                                                         AS litres,
       ROUND((MAX(f.odometer_reading) - MIN(f.odometer_reading)) / SUM(f.quantity), 1) AS km_per_litre
FROM   tpt_vehicle_fuel f
WHERE  f.deleted_at IS NULL AND f.`date` >= CURDATE() - INTERVAL 30 DAY
GROUP  BY f.vehicle_id
HAVING COUNT(*) >= 2 AND distance_km > 50 AND litres > 20 AND km_per_litre < 3.5;
```

**Formula:** `mileage = distance / litres`.

**Worked example (illustrative):** Odometer 51,200 to 51,620 = 420 km; fuel 150 L; 420 / 150 = 2.8 km/L, below 3.5: flagged.

**Status:** Working (see finding F12).

---

#### R42 `FUEL_RATE_ANOMALY` | Saving | HIGH

**Query:**

```sql
SELECT f.id, f.vehicle_id, f.`date`, f.quantity, f.cost,
       ROUND(f.cost / f.quantity, 2) AS rate_per_litre
FROM   tpt_vehicle_fuel f
WHERE  f.deleted_at IS NULL AND f.`date` >= CURDATE() - INTERVAL 30 DAY
  AND  f.quantity > 0 AND f.cost > 0 AND f.cost / f.quantity >= 120
ORDER  BY f.id
LIMIT  1;
```

**Logic:** Only the first anomaly is reported.

**Worked example (sample screen):**

| Field | Value |
|---|---|
| Vehicle | NE 66 YP 5551 |
| Date | 19 Sep 2026 |
| Cost | ₹6,632 |
| Quantity | 35.090 L |
| Rate | 6,632 / 35.090 = ₹188.99, shown as ₹189/L |
| Threshold | ₹120/L: flagged |

**Status:** Working.

---

#### R43 `FUEL_APPROVAL_PENDING` | Operations | MEDIUM

**Query:**

```sql
SELECT COUNT(*) AS vouchers, SUM(cost) AS total_cost
FROM   tpt_vehicle_fuel
WHERE  deleted_at IS NULL AND status = 'Pending'
HAVING vouchers >= 5;
```

**Example (illustrative):** 9 vouchers, ₹58,400 awaiting approval.

**Status:** Working.

---

#### R44 `SERVICE_DUE` | Maintenance | HIGH or MEDIUM

**Purpose:** Warn when a vehicle's next service date is near or past.

**Query:**

```sql
WITH latest AS (
  SELECT i.vehicle_id, m.maintenance_type, m.maintenance_initiation_date, m.next_due_date,
         ROW_NUMBER() OVER (PARTITION BY i.vehicle_id
                            ORDER BY m.maintenance_initiation_date DESC, m.id DESC) AS rn
  FROM   tpt_vehicle_maintenance m
  JOIN   tpt_vehicle_service_request sr ON sr.id = m.vehicle_service_request_id AND sr.deleted_at IS NULL
  JOIN   tpt_daily_vehicle_inspection i ON i.id = sr.vehicle_inspection_id       AND i.deleted_at IS NULL
  WHERE  m.deleted_at IS NULL AND m.status = 'Approved'
)
SELECT l.vehicle_id, l.maintenance_type, l.maintenance_initiation_date, l.next_due_date,
       DATEDIFF(l.next_due_date, CURDATE()) AS days_left
FROM   latest l
JOIN   tpt_vehicle v ON v.id = l.vehicle_id AND v.deleted_at IS NULL AND v.is_active = 1
WHERE  l.rn = 1 AND l.next_due_date IS NOT NULL
  AND  DATEDIFF(l.next_due_date, CURDATE()) <= 15;
```

**Logic:** The vehicle is linked to maintenance **through** the service request and the inspection. Only the latest approved record per vehicle decides the next due date. Overdue gives HIGH; due within 15 days gives MEDIUM.

**Example (illustrative):** Van 3 service due 24 Oct 2026 (12 days left): MEDIUM; book the service for a non-working day and assign a backup.

**Status:** Working.

---

#### R45 `INSPECTION_REPEAT_FAIL` | Safety | HIGH

**Query (shown for four of the 14 checklist items; the engine tests all 14):**

```sql
SELECT i.vehicle_id,
       COUNT(*)                          AS failed_inspections,
       SUM(i.brakes_condition_ok = 0)    AS brakes_fails,
       SUM(i.tire_condition_ok   = 0)    AS tyre_fails,
       SUM(i.engine_condition_ok = 0)    AS engine_fails,
       SUM(i.lights_condition_ok = 0)    AS lights_fails
       /* ... same pattern for the other 10 checklist columns ... */
FROM   tpt_daily_vehicle_inspection i
WHERE  i.deleted_at IS NULL
  AND  i.inspection_status = 'Failed'
  AND  i.inspection_date >= CURDATE() - INTERVAL 15 DAY
GROUP  BY i.vehicle_id
HAVING brakes_fails >= 3 OR tyre_fails >= 3 OR engine_fails >= 3 OR lights_fails >= 3;
```

**Logic:** Only inspections with status `Failed` are used, because pending inspections carry default zero values. Every item with 3 or more failures is listed.

**Example (illustrative):** Bus 1: 4 failed inspections in 15 days; Brakes failed 4 times, Tyres 3 times.

**Status:** Working.

---

#### R46 `INSPECTION_MISSING` | Safety | HIGH

**Query:**

```sql
SELECT v.id, COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle
FROM   tpt_vehicle v
WHERE  v.deleted_at IS NULL AND v.is_active = 1
  AND  v.id IN (SELECT a.vehicle_id FROM tpt_driver_route_vehicle_jnt a
                WHERE  a.deleted_at IS NULL AND a.is_active = 1
                  AND  DATE(a.effective_from) <= CURDATE()
                  AND  (a.effective_to IS NULL OR DATE(a.effective_to) >= CURDATE()))
  AND  NOT EXISTS (SELECT 1 FROM tpt_daily_vehicle_inspection i
                   WHERE  i.vehicle_id = v.id AND i.deleted_at IS NULL
                     AND  i.inspection_date >= CURDATE() - INTERVAL 7 DAY);
```

**Logic:** One grouped suggestion; `benefitAmount` = number of vehicles.

**Example:** 10 buses (NE 66 YP 5551, UQ 87 QC 1359, HC 37 LQ 7133, KI 99 JQ 3120, and 6 others) have no inspection in 7 days.

**Status:** Working.

---

#### R47 `REPLACE_VS_REPAIR_THRESHOLD` | Saving | HIGH

**Intended query:**

```sql
SELECT i.vehicle_id, COUNT(*) AS repair_visits, SUM(m.cost) AS total_cost
FROM   tpt_vehicle_maintenance m
JOIN   tpt_vehicle_service_request sr ON sr.id = m.vehicle_service_request_id
JOIN   tpt_daily_vehicle_inspection i ON i.id = sr.vehicle_inspection_id
WHERE  m.deleted_at IS NULL
  AND  m.maintenance_initiation_date >= CURDATE() - INTERVAL 180 DAY
GROUP  BY i.vehicle_id
HAVING SUM(m.cost) >= 100000;
```

**Example (illustrative):** Bus 5: 5 repairs in 6 months, ₹1,15,000: consider replacement.

**Status:** Not producing output (see finding F1).

---

#### R48 `GARAGE_DOWNTIME_EXCESSIVE` | Operations | MEDIUM

**Intended query:**

```sql
SELECT i.vehicle_id,
       SUM(DATEDIFF(m.out_service_date, m.in_service_date)) AS downtime_days
FROM   tpt_vehicle_maintenance m
JOIN   tpt_vehicle_service_request sr ON sr.id = m.vehicle_service_request_id
JOIN   tpt_daily_vehicle_inspection i ON i.id = sr.vehicle_inspection_id
WHERE  m.deleted_at IS NULL
  AND  m.maintenance_initiation_date >= CURDATE() - INTERVAL 60 DAY
  AND  m.in_service_date IS NOT NULL AND m.out_service_date IS NOT NULL
GROUP  BY i.vehicle_id
HAVING downtime_days >= 12;
```

**Example (illustrative):** Bus 4 spent 18 days in the garage in 60 days.

**Status:** Not producing output (see finding F1).

---

#### R49 `SERVICE_REQUEST_PENDING` | Operations | HIGH

**Query:**

```sql
SELECT COUNT(*) AS pending_requests
FROM   tpt_vehicle_service_request
WHERE  deleted_at IS NULL AND request_approval_status = 'Pending'
HAVING pending_requests > 0;
```

**Example (illustrative):** 3 requests waiting for approval.

**Status:** Working.

---

#### R50 `WORKSHOP_COST_VARIANCE` | Saving | LOW

**Query:**

```sql
SELECT workshop_details, ROUND(AVG(cost), 2) AS avg_invoice, COUNT(*) AS jobs
FROM   tpt_vehicle_maintenance
WHERE  deleted_at IS NULL AND workshop_details IS NOT NULL
GROUP  BY workshop_details;
```

**Logic:**

```
max_avg = highest average invoice      min_avg = lowest average invoice
Flag when  max_avg > 1.3 x min_avg  AND  max_avg > ₹8,000     (and at least 2 workshops)
premium % = (max_avg - min_avg) / min_avg x 100
benefitAmount = ROUND(max_avg - min_avg)
```

**Worked example (sample screen):**

| Item | Value |
|---|---|
| Highest: Mahindra Service Station, Gurgaon | ₹12,170 |
| Lowest workshop | ₹5,774 |
| Test | 12,170 > 1.3 x 5,774 = 7,506: yes; 12,170 > 8,000: yes |
| Premium | (12,170 - 5,774) / 5,774 = 110.8% |
| Benefit amount | ₹6,396 |

The on-screen text says "over 30% higher"; the actual premium here is about 111%.

**Status:** Working.

---

#### R51 `FUEL_TYPE_TRANSITION_VIABILITY` | Saving | LOW

**Query:**

```sql
SELECT COUNT(*) AS diesel_vehicles
FROM   tpt_vehicle v
JOIN   sys_dropdown_table d ON d.id = v.fuel_type_id
WHERE  v.deleted_at IS NULL AND v.is_active = 1
  AND  UPPER(d.value) LIKE '%DIESEL%'
HAVING diesel_vehicles >= 15;
```

**Example:** 40 diesel buses. `benefitAmount` = 40, unit `buses`.

**Status:** Working.

---

### Group 7: Safety and Incidents

#### R52 `UNBOARDING_MISSED` | Safety | HIGH

**Purpose:** Find boarding records with no matching drop-off scan.

**Query:**

```sql
SELECT l.boarding_route_id AS route_id,
       COUNT(*) AS missed_events,
       COUNT(DISTINCT l.student_id) AS students
FROM   tpt_student_boarding_log l
WHERE  l.deleted_at IS NULL
  AND  l.trip_date BETWEEN CURDATE() - INTERVAL 30 DAY AND CURDATE() - INTERVAL 1 DAY
  AND  l.boarding_time IS NOT NULL AND l.unboarding_time IS NULL
  AND  l.boarding_route_id IS NOT NULL
GROUP  BY l.boarding_route_id
HAVING COUNT(*) >= 2;

-- Driver attribution
SELECT t.driver_id, COUNT(*) AS affected_runs
FROM   tpt_student_boarding_log l
JOIN   tpt_trip t ON t.id = l.boarding_trip_id
WHERE  l.boarding_time IS NOT NULL AND l.unboarding_time IS NULL
GROUP  BY t.driver_id;
```

**Logic:**

- Today is excluded because trips may still be running.
- If 2 or more routes qualify, one grouped suggestion; otherwise one per route.
- On a single-route suggestion, the driver with the most affected runs is named when that driver has 2 or more.

**Example:** 3 routes (Route 8, Route 9, Route 10), 60 missing drop-off scans, 60 distinct students.

**Status:** Working.

---

#### R53 `INCIDENT_HOTSPOT` | Safety | HIGH

**Query:**

```sql
SELECT ROUND(latitude, 3) AS lat, ROUND(longitude, 3) AS lng,
       COUNT(*) AS incidents,
       SUM(resolved_at IS NULL) AS open_incidents,
       SUM(severity = 'HIGH') AS high_severity
FROM   tpt_trip_incidents
WHERE  deleted_at IS NULL
  AND  incident_time >= CURDATE() - INTERVAL 60 DAY
  AND  latitude IS NOT NULL AND longitude IS NOT NULL
GROUP  BY lat, lng
HAVING incidents >= 3;
```

**Logic:** Coordinates are rounded to 3 decimals, which groups incidents into cells of roughly 110 metres. The most frequent incident type (0 Stop Emergency, 1 Vehicle Breakdown, 2 Accident, 3 Route Blocked) and the busiest hour (`HOUR(incident_time)`) are added to the text.

**Example (illustrative):** Location 21.141, 72.771: 5 incidents, 2 open, 3 HIGH, peak 08:00 to 09:00, mostly "Route Blocked".

**Status:** Working.

---

#### R54 `INCIDENT_RESOLUTION_OVERDUE` | Safety | HIGH

**Purpose:** Find incidents unresolved for 7 days or more.

**Intended query:**

```sql
SELECT i.id, i.incident_type, i.severity, i.raised_at,
       DATEDIFF(CURDATE(), DATE(i.raised_at)) AS age_days
FROM   tpt_trip_incidents i
WHERE  i.deleted_at IS NULL
  AND  i.resolved_at IS NULL
  AND  i.raised_at <= CURDATE() - INTERVAL 7 DAY;
```

The engine currently tests `status = 1` as "open"; the model defines `0 = OPEN` and `1 = RESOLVED`.

**Status:** Working (review): see finding F6.

---

#### R55 `DRIVER_INCIDENT_FREQUENCY` | Safety | HIGH

**Query:**

```sql
SELECT t.driver_id, p.name, COUNT(i.id) AS incidents
FROM   tpt_trip_incidents i
JOIN   tpt_trip t ON t.id = i.trip_id AND t.deleted_at IS NULL
JOIN   tpt_personnel p ON p.id = t.driver_id AND p.is_active = 1
WHERE  i.deleted_at IS NULL
  AND  i.created_at >= CURDATE() - INTERVAL 90 DAY
  AND  t.trip_date  >= CURDATE() - INTERVAL 90 DAY
  AND  p.role = 'Driver'
GROUP  BY t.driver_id, p.name
HAVING incidents >= 2;
```

**Logic:** If 3 or more drivers qualify: one grouped suggestion, `benefitAmount` = sum of incidents. Otherwise one suggestion per driver.

**Example:** 9 drivers, 42 incidents: Radheshyam Deshpande (7), Marlo Natarajan (6), Samir Shere (6), Wafiq Bose (5), and 5 others.

**Status:** Working.

---

#### R56 `HIGH_SEVERITY_INCIDENT_ALERT` | Safety | HIGH

**Query:**

```sql
SELECT COUNT(*) AS total, MAX(raised_at) AS latest, GROUP_CONCAT(DISTINCT incident_type) AS type_ids
FROM   tpt_trip_incidents
WHERE  deleted_at IS NULL
  AND  severity IN ('HIGH', 'CRITICAL', 'High', 'Critical')
  AND  created_at >= CURDATE() - INTERVAL 14 DAY
HAVING total > 0;
```

**Example:** 18 high-severity incidents in 14 days; latest 10 Oct 2026. The type label shows "Safety Incident" because the engine looks up names in the dropdown table and falls back to this default when none are found (see finding F9).

**Status:** Working.

---

### Group 8: Parents and Technology

#### R57 `NOTIFICATION_SMS_FAILURE_FALLBACK` | Service | MEDIUM

**Query:**

```sql
SELECT COUNT(*) AS total_notifications,
       SUM(sms_notification_status IN ('Failed', 'Undelivered', 'Bounced')) AS failed_sms
FROM   tpt_notification_log
WHERE  deleted_at IS NULL AND created_at >= CURDATE() - INTERVAL 15 DAY
HAVING total_notifications >= 10 AND failed_sms >= 3;
```

**Formula:** `fail_pct = failed_sms / total_notifications x 100`.

**Example (sample screen):** 20 of 50 = 40%.

**Status:** Working.

---

#### R58 `PARENT_APP_ADOPTION_LOW` | Service | LOW

**Query:**

```sql
SELECT COUNT(*) AS total_notifications,
       SUM(app_notification_status IN ('Failed', 'Unregistered', 'NotInstalled')) AS app_failed
FROM   tpt_notification_log
WHERE  deleted_at IS NULL
HAVING total_notifications >= 20 AND 100 * app_failed / total_notifications >= 40;
```

**Logic:** There is no date window (all history). The schema value for "not registered" is `NotRegistered`, which this test does not match (see finding F7).

**Status:** Working (review).

---

#### R59 `DRIVER_APP_OUTDATED_RECORDS` | Operations | LOW

**Query:**

```sql
SELECT COUNT(*) AS incomplete_trips
FROM   tpt_trip
WHERE  deleted_at IS NULL
  AND  trip_date >= CURDATE() - INTERVAL 7 DAY
  AND  (start_odometer_reading IS NULL OR start_odometer_reading = 0)
HAVING incomplete_trips >= 5;
```

**Example:** 60 trips with a missing start odometer reading in 7 days.

**Status:** Working (review): see finding F8. The column defaults to `0.00`, so trips that have not started are also counted.

---

#### R60 `NOTIFICATION_COVERAGE_GAP` | Safety | HIGH

**Query:**

```sql
SELECT COUNT(DISTINCT student_session_id) AS students_affected
FROM   tpt_notification_log
WHERE  deleted_at IS NULL
  AND  sms_notification_status = 'Failed'
  AND  app_notification_status = 'Failed'
HAVING students_affected >= 3;
```

**Example:** 4 students with both SMS and app notifications failing. The title says "contact info missing", which is an assumption; the data only shows that both channels failed. There is no date window.

**Status:** Working.

---

### Group 9: Advanced Cost Cutting and Operational Savings

#### R61 `IDLE_FLEET_CAPITAL_WASTAGE` | Saving | HIGH

**Intended query:**

```sql
SELECT v.id, COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle
FROM   tpt_vehicle v
WHERE  v.deleted_at IS NULL AND v.is_active = 1
  AND  v.id NOT IN (SELECT a.vehicle_id FROM tpt_driver_route_vehicle_jnt a
                    WHERE  a.deleted_at IS NULL AND a.is_active = 1 AND a.vehicle_id IS NOT NULL
                      AND  DATE(a.effective_from) <= CURDATE()
                      AND  (a.effective_to IS NULL OR DATE(a.effective_to) >= CURDATE()))
  AND  v.id NOT IN (SELECT t.vehicle_id FROM tpt_trip t
                    WHERE  t.deleted_at IS NULL AND t.trip_date >= CURDATE() - INTERVAL 30 DAY);
```

**Formula:** `monthly saving = idle_count x ₹28,000`.

**Example (illustrative):** 3 idle buses: ₹84,000 per month.

**Status:** Not producing output (see finding F1).

---

#### R62 `OVERLAPPING_STOPS_CONSOLIDATION` | Saving | MEDIUM

**Query:**

```sql
SELECT * FROM (
  SELECT l.route_id, s.name AS stop, 
         LEAD(s.name) OVER w AS next_stop,
         ST_Distance_Sphere(POINT(s.longitude, s.latitude),
                            POINT(LEAD(s.longitude) OVER w, LEAD(s.latitude) OVER w)) AS metres
  FROM   tpt_pickup_points_route_jnt l
  JOIN   tpt_pickup_points s ON s.id = l.pickup_point_id
  WHERE  l.deleted_at IS NULL AND l.is_active = 1 AND s.latitude IS NOT NULL
  WINDOW w AS (PARTITION BY l.route_id ORDER BY l.ordinal)
) q
WHERE metres > 10 AND metres <= 250;
```

**Formula:** `monthly saving = pairs x ₹3,200`; time effect ≈ 4 minutes per pair.

**Example (illustrative):** 6 pairs: ₹19,200 per month. Example pair: "Green Park" and "Nehru Chowk", 180 m apart on Route 5.

**Status:** Working.

---

#### R63 `SHIFT_FLEET_REUSE_SAVING` | Saving | HIGH

**Query:**

```sql
SELECT a.vehicle_id
FROM   tpt_driver_route_vehicle_jnt a
WHERE  a.deleted_at IS NULL AND a.is_active = 1
  AND  DATE(a.effective_from) <= CURDATE()
  AND  (a.effective_to IS NULL OR DATE(a.effective_to) >= CURDATE())
GROUP  BY a.vehicle_id
HAVING COUNT(*) = 1;
```

**Formulas:**

```
single_duty_buses = number of vehicles with exactly one active assignment row
Trigger           = single_duty_buses >= 4
reusable          = FLOOR(single_duty_buses / 2)
monthly saving    = reusable x ₹42,000
```

**Worked example (sample screen):** 10 buses, so 5 reusable and 5 x 42,000 = **₹210,000**. The rule counts assignment rows, not shifts, so it is an approximation.

**Status:** Working.

---

#### R64 `EXCESSIVE_IDLING_FUEL_BURN` | Saving | MEDIUM

**Intended calculation:** `monthly saving = active_buses x 25 L x ₹95`. Example (illustrative): 40 buses = ₹95,000 per month.

**Status:** Not producing output (see finding F1).

---

#### R65 `OFF_HOURS_MILEAGE_PILFERAGE` | Saving | HIGH

**Intended queries:**

```sql
-- weekend trips (Sunday = 1, Saturday = 7)
SELECT id, vehicle_id, trip_date FROM tpt_trip
WHERE  deleted_at IS NULL AND trip_date >= CURDATE() - INTERVAL 60 DAY
  AND  DAYOFWEEK(trip_date) IN (1, 7);

-- Sunday fuel entries
SELECT id, vehicle_id, `date`, quantity, cost FROM tpt_vehicle_fuel
WHERE  deleted_at IS NULL AND `date` >= CURDATE() - INTERVAL 60 DAY AND DAYOFWEEK(`date`) = 1;
```

**Formula:** `estimated loss = MAX(SUM(Sunday fuel cost), weekend_events x ₹2,500)`.

**Status:** Not producing output (see finding F1).

---

#### R66 `PREMATURE_PARTS_WEAR_ALERT` | Saving | MEDIUM

**Intended query:**

```sql
SELECT i.vehicle_id, COUNT(*) AS replacements, SUM(m.cost) AS cost
FROM   tpt_vehicle_maintenance m
JOIN   tpt_vehicle_service_request sr ON sr.id = m.vehicle_service_request_id
JOIN   tpt_daily_vehicle_inspection i ON i.id = sr.vehicle_inspection_id
WHERE  m.deleted_at IS NULL
  AND  m.maintenance_initiation_date >= CURDATE() - INTERVAL 180 DAY
  AND (m.maintenance_type LIKE '%tyre%' OR m.maintenance_type LIKE '%tire%'
    OR m.maintenance_type LIKE '%battery%' OR m.maintenance_type LIKE '%clutch%')
GROUP  BY i.vehicle_id
HAVING replacements >= 2;
```

**Formula:** `benefit = ROUND(total_cost x 0.40)`.

**Status:** Not producing output (see finding F1).

---

#### R67 `BULK_FUEL_PROCUREMENT_DISCOUNT` | Saving | HIGH

**Intended calculation:**

```sql
SELECT SUM(quantity) AS litres_30d
FROM   tpt_vehicle_fuel
WHERE  deleted_at IS NULL AND `date` >= CURDATE() - INTERVAL 30 DAY;
```

```
if litres_30d <= 500:  litres = MAX(1,200, active_buses x 220)
monthly rebate = ROUND(litres x ₹3.00)
```

**Example (illustrative):** 6,000 litres gives ₹18,000 per month.

**Status:** Not producing output (see finding F1).

---

#### R68 `OVERTIME_CREW_ROSTER_OPTIMIZATION` | Saving | MEDIUM

**Intended calculation:** Counts active drivers; takes the number of overtime drivers from R11; `monthly cost = MAX(₹18,000, overtime_drivers x ₹6,500)`.

**Status:** Not producing output (see finding F1).

---

### Rule outside the registry

#### R69 `FAILED_VEHICLE_STILL_AVAILABLE` | Safety | HIGH (not registered)

**Purpose:** Find vehicles whose latest inspection is `Failed` while the vehicle is still marked Available.

**Query:**

```sql
WITH latest AS (
  SELECT i.vehicle_id, i.inspection_date, i.inspection_status, i.issues_description,
         ROW_NUMBER() OVER (PARTITION BY i.vehicle_id ORDER BY i.inspection_date DESC, i.id DESC) AS rn
  FROM   tpt_daily_vehicle_inspection i
  WHERE  i.deleted_at IS NULL
    AND  i.inspection_status IN ('Passed', 'Failed')
    AND  i.inspection_date >= CURDATE() - INTERVAL 30 DAY
)
SELECT v.id, COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle,
       l.inspection_date, l.issues_description
FROM   latest l
JOIN   tpt_vehicle v ON v.id = l.vehicle_id
WHERE  l.rn = 1 AND l.inspection_status = 'Failed'
  AND  v.deleted_at IS NULL AND v.is_active = 1 AND v.availability_status = 1;
```

**Status:** The routine exists but is not in the registry, so it never runs (see finding F4).

---

## 5. Ranking and Display Logic

### 5.1 Truncation

Each rule keeps at most `max_per_rule` = 20 suggestions. This happens **before** the global sort, so if a single rule produces more than 20, the extras are dropped in the order the rule found them, not by severity.

### 5.2 Global sort key

Suggestions are ordered ascending by this three-part key:

| Part | Value |
|---|---|
| 1. Safety flag | 0 if category is Safety, otherwise 1 |
| 2. Priority rank | HIGH = 0, MEDIUM = 1, LOW = 2 |
| 3. Rupee benefit | Negative of `benefitAmount`, only when `benefitUnit = rupees` (larger rupee values first); 0 otherwise |

When all three parts are equal, the original order is kept (registry order).

### 5.3 Resulting order on the sample screen

| Position | Block | Why |
|---|---|---|
| 1 to 16 | Safety, HIGH | Part 1 = 0, Part 2 = 0; ties keep registry order (R01, R08, R14, R17, R46, R52, R55, R56, R60) |
| 17 | Safety, MEDIUM | Same category, lower priority (the R01 renewal batch) |
| 18 to 21 | Non-safety, HIGH | R63 (₹210,000), R27 (₹79,159), R42 (₹189), R36 (no rupee value) |
| 22 to 27 | Non-safety, MEDIUM | R16, R28, R02, R12, R37, R57 |
| 28 to 32 | Non-safety, LOW | R50, R03, R40, R51, R59 |

### 5.4 Header counters

The header shows the total and the counts by priority: **32 total = 20 HIGH + 7 MEDIUM + 5 LOW**. These are simple counts of the suggestion list by `priority`.

---

## 6. Reading the Live Screen

Mapping of every item on the sample screen (12 October 2026) to its rule and the figures behind it.

| # | Priority | Title (short) | Rule | How the figure was obtained |
|---|---|---|---|---|
| 1 | HIGH | Fitness expires, FT 42 HX 0723 | R01 | Valid until 12 Oct; days_left = 0 |
| 2 | HIGH | Pollution expires, DP 80 GQ 9600 | R01 | Valid until 14 Oct; days_left = 2 |
| 3 | HIGH | Insurance expired, BU 02 XP 8711 | R01 | Valid until 11 Oct; days_left = -1 |
| 4 | HIGH | Fitness expires, IK 59 WV 6104 | R01 | Valid until 17 Oct; days_left = 5 |
| 5 | HIGH | Fitness expires, CR 73 AC 4547 | R01 | Valid until 19 Oct; days_left = 7 |
| 6 | HIGH | Police verification, 50 crew | R08 | 50 active staff with `police_verification_done = 0` (35 Driver + 15 Helper) |
| 7 | HIGH | Route 2 overloaded | R14 | 40 students vs 30 seats; alternative Route 3 |
| 8 | HIGH | Route 10 overloaded | R14 | 40 vs 30; alternative Route 7 |
| 9 | HIGH | Route 1 overloaded | R14 | 41 vs 40; alternative Route 3 |
| 10 | HIGH | Route 6 overloaded | R14 | 41 vs 40; alternative Route 7 |
| 11 | HIGH | Attendant missing, 10 routes | R17 | Assignments with empty helper (see F5) |
| 12 | HIGH | Pre-trip inspection missing, 10 buses | R46 | Assigned buses with no inspection in 7 days |
| 13 | HIGH | Deboarding scans missing, 3 routes | R52 | 60 boarded-not-unboarded logs, 60 students |
| 14 | HIGH | Driver coaching, 9 drivers | R55 | 9 drivers with 2 or more incidents; total 42 |
| 15 | HIGH | 18 high-severity incidents | R56 | Severity HIGH in the last 14 days |
| 16 | HIGH | Emergency contacts, 4 commuters | R60 | 4 sessions with SMS and app both Failed |
| 17 | MEDIUM | Renewal schedule, 10 certificates | R01 | Certificates with days_left 8 to 30 |
| 18 | HIGH | Fleet double-shift reuse, 10 buses | R63 | 10 single-assignment buses; FLOOR(10/2) = 5; 5 x 42,000 = ₹210,000 |
| 19 | HIGH | Outstanding fees ₹79,159 | R27 | 32 students, 3 months, oldest 11 Apr 2025 (549 days) |
| 20 | HIGH | Fuel rate ₹189/L, NE 66 YP 5551 | R42 | 6,632 / 35.090 = 188.99 |
| 21 | HIGH | Stops omitted, 7 stops | R36 | 210 skipped stop rows |
| 22 | MEDIUM | Empty stops, 30 stops | R16 | 30 x 4 = 120 min; 30 x 0.8 x 22 / 3.8 x 95 = ₹13,200 |
| 23 | MEDIUM | Inactive seat, Route 1 | R28 | 1 student (Vivaan Bhat), ₹1,200 |
| 24 | MEDIUM | Document scans pending, 40 vehicles | R02 | Vehicles with a date but upload flag 0 |
| 25 | MEDIUM | Manual check-in 100%, 11 routes | R12 | 2,400 of 2,400 logs with no device |
| 26 | MEDIUM | Trip approval backlog, 116 | R37 | Completed and unapproved; oldest 26 Sep 2026 |
| 27 | MEDIUM | SMS failure 40% | R57 | 20 of 50 messages failed in 15 days |
| 28 | LOW | Workshop tariff variance | R50 | ₹12,170 vs ₹5,774 (+110.8%) |
| 29 | LOW | Fleet modernization, 40 BS-IV buses | R03 | Emission class contains BS IV |
| 30 | LOW | Peak bottleneck, Route 6 | R40 | 10 or more trips, 5 or more departing 07:45 or later |
| 31 | LOW | Clean fuel conversion, 40 diesel buses | R51 | Fuel type contains DIESEL |
| 32 | LOW | Driver app sync, 60 trips | R59 | Trips in 7 days with start odometer null or 0 |

---

## 7. Validation Findings and Recommended Corrections

This section compares the engine behaviour with the DDL (v2.3) and the live screen. Items should be reviewed and corrected before the page is relied on for decisions. Corrections are described in words.

### 7.1 Rules that cannot produce output

| ID | Rules | Issue | Recommended correction |
|---|---|---|---|
| F1 | R47, R48, R61, R64, R65, R66, R67, R68 | They read columns that do not exist in the DDL: `vehicle_id` on `tpt_vehicle_maintenance`; `maintenance_date`, `description`, `service_type`; `ownership_type` on `tpt_vehicle`; `actual_start_time` / `actual_end_time` on `tpt_trip`; `fuel_date`, `total_amount`, `fuel_rate` on `tpt_vehicle_fuel`; `personnel_type`, `full_name` on `tpt_personnel` | Use the real columns: `date` and `cost` for fuel; `start_time` / `end_time` for trips; `name` for personnel; `ownership_type_id` with the dropdown for ownership; and reach the vehicle through service request and inspection (Section 4, R44) |
| F2 | R15, R22 | The route-load result is a list of objects, but these rules access it like an array, which raises an error | Read the fields as object properties, as R14 does |
| F3 | R29 | The registry points to a routine name that does not exist (the implemented routine has a different name) | Align the registry name with the implemented routine |
| F4 | R69 | The routine exists but is not in the registry | Add it to the registry (Safety group) |

Each failure is logged and skipped, so the page still loads.

### 7.2 Rules that run but may be inaccurate

| ID | Rules | Issue | Recommended correction |
|---|---|---|---|
| F5 | R17 | The assignment read does not load `helper_id`, so every assignment appears to have no helper (the screen shows all 10 routes) | Include `helper_id` in the assignment read |
| F6 | R54 | Open incidents are tested as `status = 1`, but the model defines 0 = OPEN, 1 = RESOLVED | Use `resolved_at IS NULL` |
| F7 | R33, R34, R58 | Value mismatches: `Cash` vs lowercase `cash` (case-sensitive in-memory check); `Unpaid` vs default `Pending`; `Unregistered` / `NotInstalled` vs schema value `NotRegistered` | Compare case-insensitively and use the schema's actual values |
| F8 | R36, R59 | Rows for trips that have not run are counted (stop rows start with `reached_flag = 0`; odometer defaults to 0) | Restrict to trips with status Completed (or Ongoing) |
| F9 | R56 | Incident type names come from a dropdown lookup that returns nothing, so every type shows "Safety Incident" | Use the model's type map (0 Stop Emergency, 1 Vehicle Breakdown, 2 Accident, 3 Route Blocked) |
| F10 | R03, R16 | R03 heading always says "BS-IV"; R16 collects stops with 1 to 2 students but never reports them, and `stop_merge_distance` is unused | Use the actual class name in the heading; either emit or remove the low-student branch |
| F11 | R39 | No minimum count, despite the word "recurrent" | Require 2 or more events at a stop |
| F12 | R26, R41 | Fuel is summed across all statuses, including Rejected and Pending, and the whole vehicle's fuel is attributed to one route | Use `status = 'Approved'` only; split cost by trip share when a vehicle serves several routes |
| F13 | R07 | `license_no` is not loaded, so the calculation always shows the fallback text | Include `license_no` in the read |
| F14 | R35 | Wording says "advance earlier" while the proposed time is later | Align the wording with the calculation |
| F15 | All | The 20-per-rule limit is applied before sorting | Sort within the rule first, or apply the limit after the global sort |
| F16 | R09, R10 | R09 does not measure route length; R10 counts trips, not attendance days | Rename or refine using route distance and `tpt_driver_attendance` |
| F17 | R63 | Counts assignment rows, not distinct shifts | Count distinct shifts per vehicle |
| F18 | R40 | Delay figures in the text are standard wording, not measured | Measure the actual delay or rephrase |
| F19 | R06, R16, R61 to R68 | Many monetary assumptions are fixed in the code | Move them to settings so the school can adjust them |

### 7.3 Informational

| Topic | Note |
|---|---|
| Currency format | Amounts use Western grouping (₹210,000); Indian grouping would read ₹2,10,000 |
| Time zones | `tpt_trip_stop_detail.reaching_time` is a TIMESTAMP while `sch_arrival_time` is a DATETIME; both must use the same time zone or delay values will be offset |
| Estimated savings | Savings are estimates from fixed assumptions (Section 2.6). They show the order of magnitude, not an audited figure |
| Missing cost data | Vehicle rent, driver salary and EMI are not in the DDL, so rupee savings reflect fuel, maintenance and the fixed assumptions only |

### 7.4 Summary

| Status | Count of rules |
|---|---|
| Producing output (working or working with review notes) | 57 |
| Not producing output (F1 to F3) | 11 |
| Exists but not registered (F4) | 1 |
| Registered total | 68 |

---

*End of document.*
