# Smart Advisor — 32 Records Explained with SQL Queries

**Reference date:** 12 October 2026  
**Database:** MySQL 8.x · Transport DDL v2.3  
**Purpose:** For each of the 32 live suggestions, this file shows (a) the card as rendered, (b) the rule that produced it, (c) the exact SQL you can run to fetch the same data, and (d) a step-by-step calculation trace.

> **How to use:** Paste each SQL block into MySQL Workbench / phpMyAdmin / DBeaver. If you are testing on a day other than 12 Oct 2026, replace every occurrence of `'2026-10-12'` with `CURDATE()` to reproduce the numbers live.

---

## Index

| # | Priority | Title | Rule |
|---|---|---|---|
| 1 | HIGH | Fitness expires — FT 42 HX 0723 | R01 |
| 2 | HIGH | Pollution expires — DP 80 GQ 9600 | R01 |
| 3 | HIGH | Insurance expired — BU 02 XP 8711 | R01 |
| 4 | HIGH | Fitness expires — IK 59 WV 6104 | R01 |
| 5 | HIGH | Fitness expires — CR 73 AC 4547 | R01 |
| 6 | HIGH | Police verification — 50 crew | R08 |
| 7 | HIGH | Route 2 overloaded | R14 |
| 8 | HIGH | Route 10 overloaded | R14 |
| 9 | HIGH | Route 1 overloaded | R14 |
| 10 | HIGH | Route 6 overloaded | R14 |
| 11 | HIGH | Attendant missing — 10 routes | R17 |
| 12 | HIGH | Pre-trip inspection missing — 10 buses | R46 |
| 13 | HIGH | Deboarding scans missing — 3 routes | R52 |
| 14 | HIGH | Driver coaching — 9 drivers | R55 |
| 15 | HIGH | 18 high-severity incidents | R56 |
| 16 | HIGH | Emergency contacts — 4 commuters | R60 |
| 17 | MEDIUM | Renewal schedule — 10 certificates | R01 |
| 18 | HIGH | Fleet double-shift reuse — 10 buses | R63 |
| 19 | HIGH | Outstanding fees ₹79,159 | R27 |
| 20 | HIGH | Fuel rate ₹189/L — NE 66 YP 5551 | R42 |
| 21 | HIGH | Stops omitted — 7 stops | R36 |
| 22 | MEDIUM | Empty stops — 30 stops | R16 |
| 23 | MEDIUM | Inactive seat — Route 1 | R28 |
| 24 | MEDIUM | Document scans pending — 40 vehicles | R02 |
| 25 | MEDIUM | Manual check-in 100% — 11 routes | R12 |
| 26 | MEDIUM | Trip approval backlog — 116 | R37 |
| 27 | MEDIUM | SMS failure 40% | R57 |
| 28 | LOW | Workshop tariff variance | R50 |
| 29 | LOW | Fleet modernization — 40 BS-IV | R03 |
| 30 | LOW | Peak bottleneck — Route 6 | R40 |
| 31 | LOW | Clean fuel — 40 diesel buses | R51 |
| 32 | LOW | Driver app sync — 60 trips | R59 |

---

# Record 1 — Fitness expires soon on FT 42 HX 0723

**Card (as rendered):**

> **1 · HIGH · Safety · Vehicle FT 42 HX 0723**  
> **Fitness certificate expires soon on FT 42 HX 0723**  
> Prevents heavy traffic police challans, vehicle impounding, and legal liability. Guarantees 100% legal compliance for student transportation.

**What the data shows**  
The live transport compliance records show that Vehicle FT 42 HX 0723's Fitness is approaching its expiry cutoff date on 12 Oct 2026 (only 0 days remaining). Renewal must be processed and verified before the certificate lapses to prevent vehicle grounding.

**Recommended Action**  
Initiate the renewal paperwork and schedule the inspection slot for Fitness within the next 0 days. Assign the task to the transport coordinator to avoid last-minute delays.

**Expected Benefit**  
Prevents heavy traffic police challans, vehicle impounding, and legal liability. Guarantees 100% legal compliance for student transportation.

**Rule:** R01 `VEHICLE_DOC_EXPIRY` — HIGH / Safety

### SQL Query

```sql
SELECT
    v.id,
    COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle,
    'Fitness'                    AS document,
    v.fitness_valid_upto         AS valid_upto,
    DATEDIFF(v.fitness_valid_upto, '2026-10-12') AS days_left,
    CASE
        WHEN DATEDIFF(v.fitness_valid_upto, '2026-10-12') < 0 THEN 'EXPIRED'
        WHEN DATEDIFF(v.fitness_valid_upto, '2026-10-12') <= 7 THEN 'URGENT'
        WHEN DATEDIFF(v.fitness_valid_upto, '2026-10-12') <= 30 THEN 'ROUTINE'
        ELSE 'OK'
    END AS bucket
FROM tpt_vehicle v
WHERE v.deleted_at IS NULL
  AND v.is_active = 1
  AND v.fitness_valid_upto IS NOT NULL
  AND COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) = 'FT 42 HX 0723';
```

### Calculation Trace

| Parameter | Value |
|---|---|
| Vehicle label | `FT 42 HX 0723` |
| Document | Fitness |
| `fitness_valid_upto` | 2026-10-12 |
| `days_left = DATEDIFF(valid_upto, today)` | `2026-10-12 − 2026-10-12 = 0` |
| `expired = days_left < 0` | false |
| Bucket | `0 ≤ 7 → URGENT → individual HIGH` |
| Current route | none (active assignments query returns empty) → "Depot Standby" |

---

# Record 2 — Pollution expires soon on DP 80 GQ 9600

**Card:**

> **2 · HIGH · Safety · Vehicle DP 80 GQ 9600**  
> **Pollution certificate expires soon on DP 80 GQ 9600**  
> Prevents heavy traffic police challans, vehicle impounding, and legal liability.

**What the data shows**  
The live transport compliance records show that Vehicle DP 80 GQ 9600's Pollution is approaching its expiry cutoff date on 14 Oct 2026 (only 2 days remaining).

**Rule:** R01 `VEHICLE_DOC_EXPIRY` — HIGH / Safety

### SQL Query

```sql
SELECT
    v.id,
    COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle,
    'Pollution'                  AS document,
    v.pollution_valid_upto       AS valid_upto,
    DATEDIFF(v.pollution_valid_upto, '2026-10-12') AS days_left
FROM tpt_vehicle v
WHERE v.deleted_at IS NULL
  AND v.is_active = 1
  AND COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) = 'DP 80 GQ 9600';
```

### Calculation Trace

| Parameter | Value |
|---|---|
| `pollution_valid_upto` | 2026-10-14 |
| `days_left` | `2026-10-14 − 2026-10-12 = 2` |
| Bucket | URGENT (≤ 7) → HIGH |

---

# Record 3 — Insurance has expired on BU 02 XP 8711

**Card:**

> **3 · HIGH · Safety · Vehicle BU 02 XP 8711**  
> **Insurance certificate has expired on BU 02 XP 8711**

**What the data shows**  
Vehicle BU 02 XP 8711's mandatory Insurance expired on 11 Oct 2026 (1 day ago). Operating a school bus with an expired certificate is a serious violation of regional transport laws.

**Rule:** R01 `VEHICLE_DOC_EXPIRY` — HIGH / Safety (expired branch)

### SQL Query

```sql
SELECT
    v.id,
    COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle,
    'Insurance'                  AS document,
    v.insurance_valid_upto       AS valid_upto,
    DATEDIFF(v.insurance_valid_upto, '2026-10-12') AS days_left
FROM tpt_vehicle v
WHERE v.deleted_at IS NULL
  AND v.is_active = 1
  AND COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) = 'BU 02 XP 8711';
```

### Calculation Trace

| Parameter | Value |
|---|---|
| `insurance_valid_upto` | 2026-10-11 |
| `days_left` | `2026-10-11 − 2026-10-12 = −1` |
| `expired` | true → HIGH |
| Action branch | "remove from active route deployment until verified" |

---

# Record 4 — Fitness expires soon on IK 59 WV 6104

**Card:**

> **4 · HIGH · Safety · Vehicle IK 59 WV 6104**  
> **Fitness certificate expires soon on IK 59 WV 6104** — 5 days remaining.

**Rule:** R01 `VEHICLE_DOC_EXPIRY` — HIGH / Safety

### SQL Query

```sql
SELECT
    v.id,
    COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle,
    'Fitness'                    AS document,
    v.fitness_valid_upto         AS valid_upto,
    DATEDIFF(v.fitness_valid_upto, '2026-10-12') AS days_left
FROM tpt_vehicle v
WHERE v.deleted_at IS NULL
  AND v.is_active = 1
  AND COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) = 'IK 59 WV 6104';
```

### Calculation Trace

| Parameter | Value |
|---|---|
| `fitness_valid_upto` | 2026-10-17 |
| `days_left` | `2026-10-17 − 2026-10-12 = 5` |
| Bucket | URGENT (≤ 7) → HIGH |

---

# Record 5 — Fitness expires soon on CR 73 AC 4547

**Card:**

> **5 · HIGH · Safety · Vehicle CR 73 AC 4547**  
> **Fitness certificate expires soon on CR 73 AC 4547** — 7 days remaining.

**Rule:** R01 `VEHICLE_DOC_EXPIRY` — HIGH / Safety (boundary case)

### SQL Query

```sql
SELECT
    v.id,
    COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle,
    'Fitness'                    AS document,
    v.fitness_valid_upto         AS valid_upto,
    DATEDIFF(v.fitness_valid_upto, '2026-10-12') AS days_left
FROM tpt_vehicle v
WHERE v.deleted_at IS NULL
  AND v.is_active = 1
  AND COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) = 'CR 73 AC 4547';
```

### Calculation Trace

| Parameter | Value |
|---|---|
| `fitness_valid_upto` | 2026-10-19 |
| `days_left` | `2026-10-19 − 2026-10-12 = 7` |
| Boundary rule | 7 is still individual HIGH; 8 flips to MEDIUM batch |

---

# Record 6 — Police verification pending for 50 crew members

**Card:**

> **6 · HIGH · Safety · Transport Crew Cohort**  
> **Staff safety compliance audit: Police verification pending for 50 crew members** — 35 drivers + 15 attendants.

**Rule:** R08 `HELPER_POLICE_VERIFICATION_PENDING` — HIGH / Safety (grouped)

### SQL Query — totals + role split

```sql
SELECT
    COUNT(*)                                         AS total_staff,
    SUM(CASE WHEN role = 'Driver' THEN 1 ELSE 0 END) AS drivers,
    SUM(CASE WHEN role = 'Helper' THEN 1 ELSE 0 END) AS helpers
FROM tpt_personnel
WHERE deleted_at IS NULL
  AND is_active = 1
  AND police_verification_done = 0;
```

### SQL Query — sample names (first 4)

```sql
SELECT id, name, role
FROM tpt_personnel
WHERE deleted_at IS NULL
  AND is_active = 1
  AND police_verification_done = 0
ORDER BY id
LIMIT 4;
```

### Calculation Trace

| Parameter | Value |
|---|---|
| `total_staff` | 50 |
| Drivers | 35 |
| Helpers | 15 |
| `benefitAmount` | 50 (unit `personnel`) |
| Sample text | "Kamlesh Lala, Wafiq Bose, Kamlesh Kapoor, Marlo Natarajan, and 46 other transport staff" |

---

# Record 7 — Route 2 is overloaded

**Card:**

> **7 · HIGH · Safety · Route 2**  
> **Route 2 is overloaded (Capacity: 30, Students: 40)**  
> +10 students travelling without dedicated seats (133% passenger occupancy).  
> **Action:** Move 10 students to 'Route 3', which has 10 free seats.

**Rule:** R14 `ROUTE_OVERLOADED` — HIGH / Safety

### SQL Query — the overloaded route

```sql
SELECT
    r.id                                                AS route_id,
    r.name                                              AS route_name,
    r.shift_id,
    r.pickup_drop,
    COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS bus,
    v.capacity,
    GREATEST(COALESCE(p.cnt,0), COALESCE(d.cnt,0))      AS students,
    GREATEST(COALESCE(p.cnt,0), COALESCE(d.cnt,0)) - v.capacity AS extra,
    ROUND(GREATEST(COALESCE(p.cnt,0), COALESCE(d.cnt,0)) / v.capacity * 100) AS utilization_pct
FROM tpt_route r
JOIN tpt_driver_route_vehicle_jnt a
     ON a.route_id = r.id
    AND a.deleted_at IS NULL
    AND a.is_active = 1
    AND DATE(a.effective_from) <= '2026-10-12'
    AND (a.effective_to IS NULL OR DATE(a.effective_to) >= '2026-10-12')
JOIN tpt_vehicle v ON v.id = a.vehicle_id AND v.deleted_at IS NULL
LEFT JOIN (
    SELECT pickup_route_id AS route_id, COUNT(DISTINCT student_id) AS cnt
    FROM tpt_student_route_allocation_jnt
    WHERE deleted_at IS NULL AND active_status = 1 AND pickup_route_id IS NOT NULL
    GROUP BY pickup_route_id
) p ON p.route_id = r.id
LEFT JOIN (
    SELECT drop_route_id AS route_id, COUNT(DISTINCT student_id) AS cnt
    FROM tpt_student_route_allocation_jnt
    WHERE deleted_at IS NULL AND active_status = 1 AND drop_route_id IS NOT NULL
    GROUP BY drop_route_id
) d ON d.route_id = r.id
WHERE r.id = 2
  AND r.deleted_at IS NULL
  AND r.is_active = 1;
```

### SQL Query — alternative route (same shift, same type, free seats)

```sql
SELECT
    r.id, r.name,
    v.capacity,
    GREATEST(COALESCE(p.cnt,0), COALESCE(d.cnt,0)) AS students,
    v.capacity - GREATEST(COALESCE(p.cnt,0), COALESCE(d.cnt,0)) AS free_seats
FROM tpt_route r
JOIN tpt_driver_route_vehicle_jnt a ON a.route_id = r.id
     AND a.deleted_at IS NULL AND a.is_active = 1
     AND DATE(a.effective_from) <= '2026-10-12'
     AND (a.effective_to IS NULL OR DATE(a.effective_to) >= '2026-10-12')
JOIN tpt_vehicle v ON v.id = a.vehicle_id
LEFT JOIN (SELECT pickup_route_id AS route_id, COUNT(DISTINCT student_id) AS cnt
           FROM tpt_student_route_allocation_jnt
           WHERE deleted_at IS NULL AND active_status = 1 AND pickup_route_id IS NOT NULL
           GROUP BY pickup_route_id) p ON p.route_id = r.id
LEFT JOIN (SELECT drop_route_id AS route_id, COUNT(DISTINCT student_id) AS cnt
           FROM tpt_student_route_allocation_jnt
           WHERE deleted_at IS NULL AND active_status = 1 AND drop_route_id IS NOT NULL
           GROUP BY drop_route_id) d ON d.route_id = r.id
WHERE r.id <> 2
  AND r.shift_id = (SELECT shift_id FROM tpt_route WHERE id = 2)
  AND r.pickup_drop = (SELECT pickup_drop FROM tpt_route WHERE id = 2)
  AND r.deleted_at IS NULL AND r.is_active = 1
  AND v.capacity - GREATEST(COALESCE(p.cnt,0), COALESCE(d.cnt,0)) > 0
ORDER BY free_seats DESC
LIMIT 1;
```

### Calculation Trace

| Step | Value |
|---|---|
| Pickup count | 40 |
| Drop count | 38 |
| `students = GREATEST(40, 38)` | 40 |
| Assigned bus | UQ 87 QC 1359 |
| `capacity` | 30 |
| `extra` | 40 − 30 = **10** |
| `utilization_pct` | `ROUND(40/30×100) = 133` |
| Alternative found | Route 3, free_seats = 10 |
| Action text | "Move 10 students to 'Route 3', which has 10 free seats" |

---

# Record 8 — Route 10 is overloaded

**Card:**

> **8 · HIGH · Safety · Route 10**  
> **Route 10 is overloaded (Capacity: 30, Students: 40)**

**Rule:** R14 `ROUTE_OVERLOADED` — HIGH / Safety

### SQL Query

```sql
SELECT
    r.id, r.name,
    COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS bus,
    v.capacity,
    GREATEST(COALESCE(p.cnt,0), COALESCE(d.cnt,0)) AS students,
    GREATEST(COALESCE(p.cnt,0), COALESCE(d.cnt,0)) - v.capacity AS extra
FROM tpt_route r
JOIN tpt_driver_route_vehicle_jnt a ON a.route_id = r.id
     AND a.deleted_at IS NULL AND a.is_active = 1
     AND DATE(a.effective_from) <= '2026-10-12'
     AND (a.effective_to IS NULL OR DATE(a.effective_to) >= '2026-10-12')
JOIN tpt_vehicle v ON v.id = a.vehicle_id
LEFT JOIN (SELECT pickup_route_id AS route_id, COUNT(DISTINCT student_id) AS cnt
           FROM tpt_student_route_allocation_jnt
           WHERE deleted_at IS NULL AND active_status = 1 AND pickup_route_id IS NOT NULL
           GROUP BY pickup_route_id) p ON p.route_id = r.id
LEFT JOIN (SELECT drop_route_id AS route_id, COUNT(DISTINCT student_id) AS cnt
           FROM tpt_student_route_allocation_jnt
           WHERE deleted_at IS NULL AND active_status = 1 AND drop_route_id IS NOT NULL
           GROUP BY drop_route_id) d ON d.route_id = r.id
WHERE r.id = 10 AND r.deleted_at IS NULL AND r.is_active = 1;
```

### Calculation Trace

| Step | Value |
|---|---|
| `students` | 40 |
| Assigned bus | FH 49 II 8340 |
| `capacity` | 30 |
| `extra` | 10 |
| `utilization_pct` | 133% |
| Alternative | Route 7 (10 free seats) |

---

# Record 9 — Route 1 is overloaded

**Card:**

> **9 · HIGH · Safety · Route 1**  
> **Route 1 is overloaded (Capacity: 40, Students: 41)**

**Rule:** R14 `ROUTE_OVERLOADED` — HIGH / Safety

### SQL Query

```sql
SELECT
    r.id, r.name,
    COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS bus,
    v.capacity,
    GREATEST(COALESCE(p.cnt,0), COALESCE(d.cnt,0)) AS students,
    GREATEST(COALESCE(p.cnt,0), COALESCE(d.cnt,0)) - v.capacity AS extra
FROM tpt_route r
JOIN tpt_driver_route_vehicle_jnt a ON a.route_id = r.id
     AND a.deleted_at IS NULL AND a.is_active = 1
     AND DATE(a.effective_from) <= '2026-10-12'
     AND (a.effective_to IS NULL OR DATE(a.effective_to) >= '2026-10-12')
JOIN tpt_vehicle v ON v.id = a.vehicle_id
LEFT JOIN (SELECT pickup_route_id AS route_id, COUNT(DISTINCT student_id) AS cnt
           FROM tpt_student_route_allocation_jnt
           WHERE deleted_at IS NULL AND active_status = 1 AND pickup_route_id IS NOT NULL
           GROUP BY pickup_route_id) p ON p.route_id = r.id
LEFT JOIN (SELECT drop_route_id AS route_id, COUNT(DISTINCT student_id) AS cnt
           FROM tpt_student_route_allocation_jnt
           WHERE deleted_at IS NULL AND active_status = 1 AND drop_route_id IS NOT NULL
           GROUP BY drop_route_id) d ON d.route_id = r.id
WHERE r.id = 1 AND r.deleted_at IS NULL AND r.is_active = 1;
```

### Calculation Trace

| Step | Value |
|---|---|
| `students` | 41 |
| Assigned bus | NE 66 YP 5551 |
| `capacity` | 40 |
| `extra` | 1 |
| `utilization_pct` | `ROUND(41/40×100) = 102` |
| Alternative | Route 3 (10 free seats) |

---

# Record 10 — Route 6 is overloaded

**Card:**

> **10 · HIGH · Safety · Route 6**  
> **Route 6 is overloaded (Capacity: 40, Students: 41)**

**Rule:** R14 `ROUTE_OVERLOADED` — HIGH / Safety

### SQL Query

```sql
SELECT
    r.id, r.name,
    COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS bus,
    v.capacity,
    GREATEST(COALESCE(p.cnt,0), COALESCE(d.cnt,0)) AS students,
    GREATEST(COALESCE(p.cnt,0), COALESCE(d.cnt,0)) - v.capacity AS extra
FROM tpt_route r
JOIN tpt_driver_route_vehicle_jnt a ON a.route_id = r.id
     AND a.deleted_at IS NULL AND a.is_active = 1
     AND DATE(a.effective_from) <= '2026-10-12'
     AND (a.effective_to IS NULL OR DATE(a.effective_to) >= '2026-10-12')
JOIN tpt_vehicle v ON v.id = a.vehicle_id
LEFT JOIN (SELECT pickup_route_id AS route_id, COUNT(DISTINCT student_id) AS cnt
           FROM tpt_student_route_allocation_jnt
           WHERE deleted_at IS NULL AND active_status = 1 AND pickup_route_id IS NOT NULL
           GROUP BY pickup_route_id) p ON p.route_id = r.id
LEFT JOIN (SELECT drop_route_id AS route_id, COUNT(DISTINCT student_id) AS cnt
           FROM tpt_student_route_allocation_jnt
           WHERE deleted_at IS NULL AND active_status = 1 AND drop_route_id IS NOT NULL
           GROUP BY drop_route_id) d ON d.route_id = r.id
WHERE r.id = 6 AND r.deleted_at IS NULL AND r.is_active = 1;
```

### Calculation Trace

| Step | Value |
|---|---|
| `students` | 41 |
| Assigned bus | RD 06 CR 4327 |
| `capacity` | 40 |
| `extra` | 1 |
| Alternative | Route 7 (10 free seats) |

---

# Record 11 — Attendant missing on 10 active routes

**Card:**

> **11 · HIGH · Safety · Route Staffing Cohort**  
> **Student transit safeguarding: Attendant missing on 10 active routes**

**Rule:** R17 `HELPER_MISSING_PREPRIMARY` — HIGH / Safety (grouped)

### SQL Query — assignments with empty helper_id

```sql
SELECT
    a.id,
    a.route_id,
    r.name AS route_name,
    a.driver_id,
    a.helper_id
FROM tpt_driver_route_vehicle_jnt a
JOIN tpt_route r ON r.id = a.route_id AND r.deleted_at IS NULL
WHERE a.deleted_at IS NULL
  AND a.is_active = 1
  AND DATE(a.effective_from) <= '2026-10-12'
  AND (a.effective_to IS NULL OR DATE(a.effective_to) >= '2026-10-12')
  AND a.helper_id IS NULL;
```

### SQL Query — grouped count + sample names

```sql
SELECT
    COUNT(*)                                          AS routes_missing_helper,
    GROUP_CONCAT(r.name ORDER BY r.id SEPARATOR ', ') AS route_names
FROM tpt_driver_route_vehicle_jnt a
JOIN tpt_route r ON r.id = a.route_id AND r.deleted_at IS NULL
WHERE a.deleted_at IS NULL
  AND a.is_active = 1
  AND DATE(a.effective_from) <= '2026-10-12'
  AND (a.effective_to IS NULL OR DATE(a.effective_to) >= '2026-10-12')
  AND a.helper_id IS NULL;
```

### Calculation Trace

| Step | Value |
|---|---|
| Routes with `helper_id IS NULL` | 10 |
| `benefitAmount` | 10 (unit `routes`) |
| Sample text | "Route 1, Route 2, Route 3, Route 4, and 6 other routes" |

> **⚠️ Validation note (F5):** The engine's current assignment read omits `helper_id` from the SELECT list, so it treats every active assignment as helper-less. The SQL above includes `helper_id`, so it shows the true count.

---

# Record 12 — Pre-trip inspection logs missing for 10 operating buses

**Card:**

> **12 · HIGH · Safety · Active Fleet**  
> **Fleet maintenance audit: Pre-trip inspection logs missing for 10 operating buses**

**Rule:** R46 `INSPECTION_MISSING` — HIGH / Safety (grouped)

### SQL Query — assigned vehicles with no inspection in 7 days

```sql
SELECT
    v.id,
    COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle
FROM tpt_vehicle v
WHERE v.deleted_at IS NULL
  AND v.is_active = 1
  AND v.id IN (
      SELECT a.vehicle_id
      FROM tpt_driver_route_vehicle_jnt a
      WHERE a.deleted_at IS NULL
        AND a.is_active = 1
        AND DATE(a.effective_from) <= '2026-10-12'
        AND (a.effective_to IS NULL OR DATE(a.effective_to) >= '2026-10-12')
  )
  AND NOT EXISTS (
      SELECT 1
      FROM tpt_daily_vehicle_inspection i
      WHERE i.vehicle_id = v.id
        AND i.deleted_at IS NULL
        AND i.inspection_date >= '2026-10-12' - INTERVAL 7 DAY
  );
```

### SQL Query — grouped count

```sql
SELECT COUNT(*) AS uninspected_vehicles
FROM tpt_vehicle v
WHERE v.deleted_at IS NULL
  AND v.is_active = 1
  AND v.id IN (
      SELECT a.vehicle_id FROM tpt_driver_route_vehicle_jnt a
      WHERE a.deleted_at IS NULL AND a.is_active = 1
        AND DATE(a.effective_from) <= '2026-10-12'
        AND (a.effective_to IS NULL OR DATE(a.effective_to) >= '2026-10-12')
  )
  AND NOT EXISTS (
      SELECT 1 FROM tpt_daily_vehicle_inspection i
      WHERE i.vehicle_id = v.id AND i.deleted_at IS NULL
        AND i.inspection_date >= '2026-10-12' - INTERVAL 7 DAY
  );
```

### Calculation Trace

| Step | Value |
|---|---|
| Assigned vehicles with no inspection in last 7 days | 10 |
| `benefitAmount` | 10 (unit `vehicles`) |
| Sample text | "NE 66 YP 5551, UQ 87 QC 1359, HC 37 LQ 7133, KI 99 JQ 3120, and 6 other active buses" |

---

# Record 13 — Deboarding scans missing across 3 routes

**Card:**

> **13 · HIGH · Safety · Campus Arrival Verification**  
> **Child transit safeguarding: Deboarding arrival scans missing across 3 routes**  
> 60 missing destination scans; 60 distinct students affected.

**Rule:** R52 `UNBOARDING_MISSED` — HIGH / Safety (grouped)

### SQL Query — per-route missed unboarding (≥ 2 events)

```sql
SELECT
    l.boarding_route_id           AS route_id,
    COUNT(*)                      AS missed_events,
    COUNT(DISTINCT l.student_id)  AS students
FROM tpt_student_boarding_log l
WHERE l.deleted_at IS NULL
  AND l.trip_date BETWEEN '2026-10-12' - INTERVAL 30 DAY AND '2026-10-12' - INTERVAL 1 DAY
  AND l.boarding_time IS NOT NULL
  AND l.unboarding_time IS NULL
  AND l.boarding_route_id IS NOT NULL
GROUP BY l.boarding_route_id
HAVING COUNT(*) >= 2;
```

### SQL Query — driver attribution (who drove the affected runs)

```sql
SELECT
    t.driver_id,
    p.name,
    COUNT(*) AS affected_runs
FROM tpt_student_boarding_log l
JOIN tpt_trip t ON t.id = l.boarding_trip_id
JOIN tpt_personnel p ON p.id = t.driver_id
WHERE l.boarding_time IS NOT NULL
  AND l.unboarding_time IS NULL
GROUP BY t.driver_id, p.name
ORDER BY affected_runs DESC;
```

### Calculation Trace

| Step | Value |
|---|---|
| Qualifying routes | 3 (Route 8, Route 9, Route 10) |
| `totalEvents` | 60 |
| `totalStudents` | 60 |
| Rule branch | 2+ routes → ONE grouped suggestion |
| `benefitAmount` | 60 (unit `students`) |

---

# Record 14 — Driver coaching programme: 9 drivers, 42 incidents

**Card:**

> **14 · HIGH · Safety · Driver Safety Roster**  
> **Fleet driver safety coaching programme: 9 drivers recommended for workshop (42 incidents)**  
> Radheshyam Deshpande (7), Marlo Natarajan (6), Samir Shere (6), Wafiq Bose (5), and 5 other drivers.

**Rule:** R55 `DRIVER_INCIDENT_FREQUENCY` — HIGH / Safety (grouped)

### SQL Query — per-driver incident counts (≥ 2 in 90 days)

```sql
SELECT
    t.driver_id,
    p.name,
    COUNT(i.id) AS incidents
FROM tpt_trip_incidents i
JOIN tpt_trip      t ON t.id = i.trip_id AND t.deleted_at IS NULL
JOIN tpt_personnel p ON p.id = t.driver_id AND p.is_active = 1
WHERE i.deleted_at IS NULL
  AND i.created_at >= '2026-10-12' - INTERVAL 90 DAY
  AND t.trip_date  >= '2026-10-12' - INTERVAL 90 DAY
  AND p.role = 'Driver'
GROUP BY t.driver_id, p.name
HAVING incidents >= 2
ORDER BY incidents DESC;
```

### Calculation Trace

| Step | Value |
|---|---|
| Qualifying drivers | 9 |
| Aggregate incidents | 42 |
| Rule branch | 3+ drivers → ONE grouped suggestion |
| `benefitAmount` | 42 (unit `incidents`) |
| Sample text | "Radheshyam Deshpande (7), Marlo Natarajan (6), Samir Shere (6), Wafiq Bose (5), and 5 other drivers" |

---

# Record 15 — 18 high-severity incidents in past 14 days

**Card:**

> **15 · HIGH · Safety · Critical Incident Cohort**  
> **Critical safety oversight: 18 high-severity incidents logged in past 14 days**  
> Latest logged on 10 Oct 2026.

**Rule:** R56 `HIGH_SEVERITY_INCIDENT_ALERT` — HIGH / Safety

### SQL Query

```sql
SELECT
    COUNT(*)                             AS total_high_severity,
    MAX(raised_at)                       AS latest_event,
    GROUP_CONCAT(DISTINCT incident_type) AS type_ids
FROM tpt_trip_incidents
WHERE deleted_at IS NULL
  AND severity IN ('HIGH', 'CRITICAL', 'High', 'Critical')
  AND created_at >= '2026-10-12' - INTERVAL 14 DAY;
```

### Calculation Trace

| Step | Value |
|---|---|
| `total_high_severity` | 18 |
| `latest_event` | 2026-10-10 |
| `benefitAmount` | 18 (unit `incidents`) |
| Type label shown | "Safety Incident" (dropdown lookup returns nothing; see F9) |

---

# Record 16 — Emergency contacts missing for 4 commuters

**Card:**

> **16 · HIGH · Safety · Emergency Contacts**  
> **Parent emergency contact info missing for 4 commuters**

**Rule:** R60 `NOTIFICATION_COVERAGE_GAP` — HIGH / Safety

### SQL Query

```sql
SELECT
    COUNT(DISTINCT student_session_id) AS students_affected
FROM tpt_notification_log
WHERE deleted_at IS NULL
  AND sms_notification_status = 'Failed'
  AND app_notification_status = 'Failed';
```

### SQL Query — list the affected sessions

```sql
SELECT DISTINCT student_session_id
FROM tpt_notification_log
WHERE deleted_at IS NULL
  AND sms_notification_status = 'Failed'
  AND app_notification_status = 'Failed';
```

### Calculation Trace

| Step | Value |
|---|---|
| Distinct student_session_id with both SMS + app Failed | 4 |
| `benefitAmount` | 4 (unit `students`) |
| Note | The title asserts "contact info missing", but the data only shows that both channels failed. No date window is applied. |

---

# Record 17 — Renewal schedule: 10 certificates due within 30 days

**Card:**

> **17 · MEDIUM · Safety · Compliance Renewal Calendar**  
> **Fleet compliance renewal schedule: 10 certificates due within 30 days**  
> LY 63 CG 0668 (Fitness), RD 06 CR 4327 (Pollution), JL 27 XD 3225 (Fire extinguisher), FH 49 II 8340 (Fitness), and 6 other renewals.

**Rule:** R01 `VEHICLE_DOC_EXPIRY` — MEDIUM / Safety (batch branch)

### SQL Query — 8–30 day window

```sql
SELECT
    COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle,
    d.document,
    d.valid_upto,
    DATEDIFF(d.valid_upto, '2026-10-12') AS days_left
FROM tpt_vehicle v
JOIN (
    SELECT id, 'Fitness'           AS document, fitness_valid_upto           AS valid_upto FROM tpt_vehicle
    UNION ALL
    SELECT id, 'Insurance',                       insurance_valid_upto                       FROM tpt_vehicle
    UNION ALL
    SELECT id, 'Pollution',                       pollution_valid_upto                       FROM tpt_vehicle
    UNION ALL
    SELECT id, 'Fire extinguisher',               fire_extinguisher_valid_upto               FROM tpt_vehicle
) d ON d.id = v.id
WHERE v.deleted_at IS NULL
  AND v.is_active = 1
  AND d.valid_upto IS NOT NULL
  AND DATEDIFF(d.valid_upto, '2026-10-12') BETWEEN 8 AND 30
ORDER BY days_left;
```

### Calculation Trace

| Step | Value |
|---|---|
| Rows in 8–30 day window | 10 |
| Rule branch | always ONE grouped MEDIUM card |
| `benefitAmount` | 10 (unit `certificates`) |
| Sample text | first 4 vehicles + "and 6 other renewals" |

---

# Record 18 — Fleet double-shift reuse: 10 single-duty buses

**Card:**

> **18 · HIGH · Saving · Fleet Deployment Roster**  
> **Fleet double-shift reuse rationalisation: 10 single-duty buses**  
> Potentially reduces active fleet requirements by up to 5 vehicles, yielding ₹210,000 monthly savings.

**Rule:** R63 `SHIFT_FLEET_REUSE_SAVING` — HIGH / Saving

### SQL Query — vehicles with exactly one active assignment

```sql
SELECT
    a.vehicle_id,
    COUNT(*) AS active_assignments
FROM tpt_driver_route_vehicle_jnt a
WHERE a.deleted_at IS NULL
  AND a.is_active = 1
  AND DATE(a.effective_from) <= '2026-10-12'
  AND (a.effective_to IS NULL OR DATE(a.effective_to) >= '2026-10-12')
GROUP BY a.vehicle_id
HAVING COUNT(*) = 1;
```

### SQL Query — grouped count

```sql
SELECT COUNT(*) AS single_duty_buses
FROM (
    SELECT a.vehicle_id
    FROM tpt_driver_route_vehicle_jnt a
    WHERE a.deleted_at IS NULL
      AND a.is_active = 1
      AND DATE(a.effective_from) <= '2026-10-12'
      AND (a.effective_to IS NULL OR DATE(a.effective_to) >= '2026-10-12')
    GROUP BY a.vehicle_id
    HAVING COUNT(*) = 1
) x;
```

### Calculation Trace

| Step | Formula | Value |
|---|---|---|
| `single_duty_buses` | COUNT | 10 |
| Trigger | `>= 4` | yes |
| `reusable = FLOOR(single_duty_buses / 2)` | `FLOOR(10/2)` | 5 |
| `monthly_saving = reusable × ₹42,000` | `5 × 42000` | **₹210,000** |
| `benefitAmount` | | 210000 (unit `rupees`) |

---

# Record 19 — Outstanding transport fees pending collection (₹79,159)

**Card:**

> **19 · HIGH · Income · Transport Fee Master**  
> **Outstanding transport fees pending collection (₹79,159)**  
> 32 students · 3 billing months · oldest due 11 Apr 2025 (549 days).

**Rule:** R27 `FEE_PENDING` — HIGH / Income

### SQL Query

```sql
SELECT
    COUNT(*)                                   AS bills,
    COUNT(DISTINCT std_academic_sessions_id)   AS students,
    COUNT(DISTINCT `month`)                    AS months,
    MIN(due_date)                              AS oldest_due,
    SUM(COALESCE(total_amount, amount, 0))     AS amount
FROM tpt_student_fee_detail
WHERE deleted_at IS NULL
  AND LOWER(status) IN ('pending', 'overdue')
  AND due_date < '2026-10-12' - INTERVAL 30 DAY;
```

### Calculation Trace

| Step | Formula | Value |
|---|---|---|
| Bills | COUNT | 41 |
| Students | COUNT DISTINCT session | 32 |
| Months | COUNT DISTINCT month | 3 |
| Oldest due | MIN(due_date) | 2025-04-11 |
| `oldest_days` | `DATEDIFF(today, oldest_due)` | 549 |
| Amount | SUM | **₹79,159** |
| Priority | `oldest_days > 90` | HIGH |

---

# Record 20 — Fuel pricing discrepancy: NE 66 YP 5551 billed at ₹189/L

**Card:**

> **20 · HIGH · Saving · NE 66 YP 5551**  
> **Fuel pricing discrepancy: NE 66 YP 5551 billed at ₹189/L**  
> 19 Sep 2026 · ₹6,632 for 35.090 L.

**Rule:** R42 `FUEL_RATE_ANOMALY` — HIGH / Saving

### SQL Query

```sql
SELECT
    f.id,
    f.vehicle_id,
    COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle,
    f.date,
    f.quantity,
    f.cost,
    ROUND(f.cost / f.quantity, 2) AS rate_per_litre
FROM tpt_vehicle_fuel f
JOIN tpt_vehicle v ON v.id = f.vehicle_id
WHERE f.deleted_at IS NULL
  AND f.date >= '2026-10-12' - INTERVAL 30 DAY
  AND f.quantity > 0
  AND f.cost > 0
  AND f.cost / f.quantity >= 120
ORDER BY f.id
LIMIT 1;
```

### Calculation Trace

| Step | Formula | Value |
|---|---|---|
| Date | | 2026-09-19 |
| Cost | | ₹6,632 |
| Quantity | | 35.090 L |
| `rate = cost / quantity` | `6632 / 35.090` | **₹188.99 → shown as ₹189** |
| Threshold | `rate >= 120` | flagged HIGH |
| Rule branch | only the first anomaly is reported | (LIMIT 1) |

---

# Record 21 — 7 stops frequently omitted (210 missed visits)

**Card:**

> **21 · HIGH · Service · Transit Service Quality Audit**  
> **Transit schedule compliance audit: 7 active passenger stops frequently omitted**  
> Stop 1 (Morning Pickup) (45 missed), Stop 10 (30), Stop 4 (30), Stop 5 (Afternoon Drop) (30), and 3 other stops.

**Rule:** R36 `SKIPPED_STOP_ANOMALY` — HIGH / Service (grouped)

### SQL Query — per-stop skip counts

```sql
SELECT
    d.stop_id,
    p.name AS stop_name,
    COUNT(*) AS total_runs,
    SUM(CASE WHEN d.reached_flag = 0 THEN 1 ELSE 0 END) AS skipped,
    ROUND(100 * SUM(CASE WHEN d.reached_flag = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS skip_pct
FROM tpt_trip_stop_detail d
JOIN tpt_pickup_points p ON p.id = d.stop_id
WHERE d.deleted_at IS NULL
  AND d.created_at >= '2026-10-12' - INTERVAL 30 DAY
  AND d.stop_id IN (
        SELECT pickup_stop_id FROM tpt_student_route_allocation_jnt
        WHERE deleted_at IS NULL AND active_status = 1 AND pickup_stop_id IS NOT NULL
        UNION
        SELECT drop_stop_id   FROM tpt_student_route_allocation_jnt
        WHERE deleted_at IS NULL AND active_status = 1 AND drop_stop_id   IS NOT NULL
  )
GROUP BY d.stop_id, p.name
HAVING total_runs >= 10
   AND skipped >= 5
   AND skipped / total_runs >= 0.25
ORDER BY skipped DESC;
```

### Calculation Trace

| Step | Value |
|---|---|
| Qualifying stops | 7 |
| Aggregate skipped | 210 |
| Rule branch | 3+ stops → ONE grouped suggestion |
| `benefitAmount` | 210 (unit `trips`) |

---

# Record 22 — 30 empty stops across 10 routes

**Card:**

> **22 · MEDIUM · Saving · Transit Network Rationalisation**  
> **Fleet route rationalisation: 30 unallocated empty stops across 10 active routes**  
> Eliminates ~120 min/day; ₹13,200 monthly diesel saving.

**Rule:** R16 `LOW_STUDENT_STOP` — MEDIUM / Saving (grouped)

### SQL Query — stops with zero allocated students

```sql
SELECT
    l.route_id,
    r.name AS route_name,
    s.id   AS stop_id,
    s.name AS stop_name,
    COUNT(DISTINCT x.student_id) AS students
FROM tpt_pickup_points_route_jnt l
JOIN tpt_route r ON r.id = l.route_id AND r.deleted_at IS NULL AND r.is_active = 1
JOIN tpt_pickup_points s ON s.id = l.pickup_point_id AND s.deleted_at IS NULL
LEFT JOIN (
    SELECT student_id, pickup_route_id AS route_id, pickup_stop_id AS stop_id
    FROM tpt_student_route_allocation_jnt
    WHERE deleted_at IS NULL AND active_status = 1
      AND pickup_route_id IS NOT NULL AND pickup_stop_id IS NOT NULL
    UNION
    SELECT student_id, drop_route_id, drop_stop_id
    FROM tpt_student_route_allocation_jnt
    WHERE deleted_at IS NULL AND active_status = 1
      AND drop_route_id IS NOT NULL AND drop_stop_id IS NOT NULL
) x ON x.route_id = l.route_id AND x.stop_id = l.pickup_point_id
WHERE l.deleted_at IS NULL
  AND l.is_active = 1
  AND (SELECT COUNT(*) FROM tpt_pickup_points_route_jnt z
       WHERE z.route_id = l.route_id AND z.deleted_at IS NULL) > 2
GROUP BY l.route_id, r.name, s.id, s.name
HAVING students = 0;
```

### Calculation Trace

| Step | Formula | Value |
|---|---|---|
| Empty stops | COUNT | 30 |
| Routes affected | COUNT DISTINCT route | 10 |
| Time saved | `30 × 4 min` | 120 min/day |
| Daily distance | `30 × 0.8 km` | 24 km |
| Monthly distance | `24 × 22` | 528 km |
| Litres | `528 / 3.8` | 138.9 L |
| Monthly saving | `138.9 × ₹95` | **₹13,200** |
| `benefitAmount` | | 13200 (unit `rupees`) |

---

# Record 23 — Inactive seat reservation on Route 1 (1 student)

**Card:**

> **23 · MEDIUM · Income · Route 1**  
> **Inactive seat reservation on Route 1 (1 student)**  
> Vivaan Bhat · ₹1,200 monthly fare value · 0 boardings in 30 days.

**Rule:** R28 `UNUSED_ALLOCATION` — MEDIUM / Income

### SQL Query — Step 1: students who boarded in the window

```sql
SELECT DISTINCT student_id
FROM tpt_student_boarding_log
WHERE deleted_at IS NULL
  AND student_id IS NOT NULL
  AND trip_date BETWEEN '2026-10-12' - INTERVAL 30 DAY AND '2026-10-12'
  AND (boarding_time IS NOT NULL OR unboarding_time IS NOT NULL);
```

### SQL Query — Step 2: routes with boarding data

```sql
SELECT DISTINCT boarding_route_id AS route_id
FROM tpt_student_boarding_log
WHERE deleted_at IS NULL
  AND trip_date >= '2026-10-12' - INTERVAL 30 DAY
  AND boarding_route_id IS NOT NULL
UNION
SELECT DISTINCT unboarding_route_id
FROM tpt_student_boarding_log
WHERE deleted_at IS NULL
  AND trip_date >= '2026-10-12' - INTERVAL 30 DAY
  AND unboarding_route_id IS NOT NULL;
```

### SQL Query — Step 3: unused allocations

```sql
SELECT
    COALESCE(a.pickup_route_id, a.drop_route_id) AS route_id,
    COUNT(*)                                     AS unused_students,
    SUM(a.fare)                                  AS fare_value
FROM tpt_student_route_allocation_jnt a
WHERE a.deleted_at IS NULL
  AND a.active_status = 1
  AND a.effective_from <= '2026-10-12' - INTERVAL 30 DAY
  AND COALESCE(a.pickup_route_id, a.drop_route_id) = 1
  AND a.student_id NOT IN (
      SELECT DISTINCT student_id FROM tpt_student_boarding_log
      WHERE deleted_at IS NULL AND student_id IS NOT NULL
        AND trip_date BETWEEN '2026-10-12' - INTERVAL 30 DAY AND '2026-10-12'
        AND (boarding_time IS NOT NULL OR unboarding_time IS NOT NULL)
  )
GROUP BY COALESCE(a.pickup_route_id, a.drop_route_id);
```

### Calculation Trace

| Step | Value |
|---|---|
| Unused students on Route 1 | 1 |
| Fare value | ₹1,200 |
| `benefitAmount` | 1200 (unit `rupees`) |
| Safeguard | If Step 1 returns empty, rule stops to avoid flagging everyone |

---

# Record 24 — Document scans pending for 40 active vehicles

**Card:**

> **24 · MEDIUM · Compliance · Fleet Document Locker**  
> **Digital document repository audit: Scans pending for 40 active vehicles**  
> NE 66 YP 5551 (Fitness), UQ 87 QC 1359 (Fitness), HC 37 LQ 7133 (Fitness), KI 99 JQ 3120 (Fitness), and 36 other vehicles.

**Rule:** R02 `VEHICLE_DOC_SCAN_MISSING` — MEDIUM / Compliance (grouped)

### SQL Query — first missing document per vehicle

```sql
SELECT
    v.id,
    COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle,
    CASE
        WHEN v.fitness_valid_upto   IS NOT NULL AND v.fitness_cert_upload   = 0 THEN 'Fitness Certificate'
        WHEN v.insurance_valid_upto IS NOT NULL AND v.insurance_cert_upload = 0 THEN 'Insurance Policy'
        WHEN v.pollution_valid_upto IS NOT NULL AND v.pollution_cert_upload = 0 THEN 'Pollution Under Control (PUC)'
    END AS first_missing_document
FROM tpt_vehicle v
WHERE v.deleted_at IS NULL
  AND v.is_active = 1
HAVING first_missing_document IS NOT NULL;
```

### SQL Query — grouped count

```sql
SELECT COUNT(*) AS vehicles_with_missing_scans
FROM (
    SELECT v.id,
           CASE
               WHEN v.fitness_valid_upto   IS NOT NULL AND v.fitness_cert_upload   = 0 THEN 'Fitness Certificate'
               WHEN v.insurance_valid_upto IS NOT NULL AND v.insurance_cert_upload = 0 THEN 'Insurance Policy'
               WHEN v.pollution_valid_upto IS NOT NULL AND v.pollution_cert_upload = 0 THEN 'Pollution Under Control (PUC)'
           END AS first_missing_document
    FROM tpt_vehicle v
    WHERE v.deleted_at IS NULL AND v.is_active = 1
) x
WHERE first_missing_document IS NOT NULL;
```

### Calculation Trace

| Step | Value |
|---|---|
| Vehicles with at least one missing scan | 40 |
| `benefitAmount` | 40 (unit `vehicles`) |
| Order of precedence | Fitness → Insurance → Pollution |

---

# Record 25 — Manual check-in 100% across 11 routes

**Card:**

> **25 · MEDIUM · Operations · Transit Operations Roster**  
> **Fleet attendance digitisation audit: High manual check-in rate across 11 routes (100%)**  
> 2,400 of 2,400 boardings manual.

**Rule:** R12 `ATTENDANCE_MANUAL_EXCESSIVE` — MEDIUM / Operations (grouped)

### SQL Query — per-route manual share

```sql
SELECT
    l.boarding_route_id                        AS route_id,
    r.name                                     AS route_name,
    COUNT(*)                                   AS total_logs,
    SUM(CASE WHEN l.device_id IS NULL THEN 1 ELSE 0 END) AS manual_logs,
    ROUND(100 * SUM(CASE WHEN l.device_id IS NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS manual_pct
FROM tpt_student_boarding_log l
JOIN tpt_route r ON r.id = l.boarding_route_id AND r.deleted_at IS NULL
WHERE l.deleted_at IS NULL
  AND l.trip_date >= '2026-10-12' - INTERVAL 30 DAY
GROUP BY l.boarding_route_id, r.name
HAVING total_logs >= 20
   AND manual_pct >= 50
ORDER BY manual_pct DESC, total_logs DESC;
```

### Calculation Trace

| Step | Formula | Value |
|---|---|---|
| Qualifying routes | COUNT | 11 |
| Total logs | COUNT | 2400 |
| Manual logs | `device_id IS NULL` | 2400 |
| `overall_pct` | `2400 / 2400 × 100` | 100% |
| Rule branch | 3+ routes → ONE grouped suggestion | |
| `benefitAmount` | | 100 (unit `percent`) |

---

# Record 26 — Trip log sign-off backlog: 116 trips

**Card:**

> **26 · MEDIUM · Operations · Trip Log Ledger**  
> **Trip log sign-off backlog: 116 trips awaiting review**  
> Oldest unreviewed trip: 26 Sep 2026.

**Rule:** R37 `TRIP_APPROVAL_BACKLOG` — MEDIUM / Operations

### SQL Query

```sql
SELECT
    COUNT(*)         AS pending_trips,
    MIN(trip_date)   AS oldest_trip
FROM tpt_trip
WHERE deleted_at IS NULL
  AND status = 'Completed'
  AND approved = 0
HAVING pending_trips >= 15;
```

### Calculation Trace

| Step | Value |
|---|---|
| `pending_trips` | 116 |
| `oldest_trip` | 2026-09-26 |
| Age of oldest | `2026-10-12 − 2026-09-26 = 16 days` |
| `benefitAmount` | 116 (unit `trips`) |

---

# Record 27 — SMS gateway delivery failure spike (40%)

**Card:**

> **27 · MEDIUM · Service · SMS Gateway**  
> **SMS gateway delivery failure spike (40% undelivered)**  
> 20 of 50 messages failed in the last 15 days.

**Rule:** R57 `NOTIFICATION_SMS_FAILURE_FALLBACK` — MEDIUM / Service

### SQL Query

```sql
SELECT
    COUNT(*)                                                              AS total_notifications,
    SUM(CASE WHEN sms_notification_status IN ('Failed','Undelivered','Bounced')
             THEN 1 ELSE 0 END)                                           AS failed_sms
FROM tpt_notification_log
WHERE deleted_at IS NULL
  AND created_at >= '2026-10-12' - INTERVAL 15 DAY;
```

### Calculation Trace

| Step | Formula | Value |
|---|---|---|
| Total notifications | COUNT | 50 |
| Failed SMS | status IN (Failed, Undelivered, Bounced) | 20 |
| `fail_pct` | `20 / 50 × 100` | 40% |
| `benefitAmount` | | 20 (unit `alerts`) |

---

# Record 28 — Workshop tariff variance: Mahindra Service Station, Gurgaon

**Card:**

> **28 · LOW · Saving · Mahindra Service Station, Gurgaon**  
> **Commercial workshop tariff variance alert: Mahindra Service Station, Gurgaon**  
> Average invoice ₹12,170 vs ₹5,774 alternative (+110.8%).

**Rule:** R50 `WORKSHOP_COST_VARIANCE` — LOW / Saving

### SQL Query — average invoice per workshop

```sql
SELECT
    workshop_details,
    ROUND(AVG(cost), 2) AS avg_invoice,
    COUNT(*)            AS jobs
FROM tpt_vehicle_maintenance
WHERE deleted_at IS NULL
  AND workshop_details IS NOT NULL
GROUP BY workshop_details
ORDER BY avg_invoice DESC;
```

### Calculation Trace

| Step | Formula | Value |
|---|---|---|
| Max avg | top of list | ₹12,170 |
| Min avg | bottom of list | ₹5,774 |
| Test 1 | `max > 1.3 × min` → `12170 > 7506` | true |
| Test 2 | `max > ₹8,000` | true |
| Premium | `(12170 − 5774) / 5774 × 100` | 110.8% |
| `benefitAmount` | `ROUND(max − min)` | **₹6,396** |

> The card text says "over 30% higher", which is standard wording — the actual premium here is about 111%.

---

# Record 29 — Fleet modernization roadmap: 40 BS-IV buses

**Card:**

> **29 · LOW · Modernization · Fleet Modernization Cohort**  
> **Fleet modernization roadmap: 40 BS-IV buses scheduled for clean-fuel transition**

**Rule:** R03 `VEHICLE_EMISSION_CLASS` — LOW / Modernization (grouped)

### SQL Query

```sql
SELECT
    v.id,
    COALESCE(NULLIF(v.registration_no,''), v.vehicle_no) AS vehicle,
    v.manufacturer,
    v.model,
    d.value AS emission_class
FROM tpt_vehicle v
LEFT JOIN sys_dropdown_table d ON d.id = v.vehicle_emission_class_id
WHERE v.deleted_at IS NULL
  AND v.is_active = 1
  AND (
        UPPER(d.value) LIKE '%BS III%'  OR UPPER(d.value) LIKE '%BS-III%'
     OR UPPER(d.value) LIKE '%BS IV%'   OR UPPER(d.value) LIKE '%BS-IV%'
     OR UPPER(d.value) LIKE '%EURO 3%'  OR UPPER(d.value) LIKE '%EURO 4%'
  );
```

### Calculation Trace

| Step | Value |
|---|---|
| Legacy vehicles | 40 |
| `benefitAmount` | 40 (unit `buses`) |
| Note (F10) | Heading always says "BS-IV" even if some rows are BS-III |

---

# Record 30 — Peak bottleneck avoidance: Route 6

**Card:**

> **30 · LOW · Service · Route 6**  
> **Peak bottleneck avoidance: Reschedule departure for Route 6**  
> Departs after 07:45 AM → 10-minute earlier departure recommended.

**Rule:** R40 `PEAK_TRAFFIC_TIMING_ADJUSTMENT` — LOW / Service

### SQL Query

```sql
SELECT
    route_id,
    COUNT(*)                                             AS trips_30d,
    SUM(CASE WHEN TIME(start_time) >= '07:45:00' THEN 1 ELSE 0 END) AS late_departures
FROM tpt_trip
WHERE deleted_at IS NULL
  AND trip_date >= '2026-10-12' - INTERVAL 30 DAY
  AND start_time IS NOT NULL
  AND end_time IS NOT NULL
GROUP BY route_id
HAVING trips_30d >= 10
   AND late_departures >= 5;
```

### Calculation Trace

| Step | Value |
|---|---|
| Qualifying route | Route 6 |
| `trips_30d` | ≥ 10 |
| `late_departures` | ≥ 5 |
| `benefitAmount` | 15 (unit `minutes`) — fixed estimate |
| Note (F18) | Delay figures "12–18 min" are standard wording, not measured |

---

# Record 31 — Clean fuel conversion: 40 diesel buses

**Card:**

> **31 · LOW · Saving · Diesel Fleet Cohort**  
> **Clean fuel conversion assessment: 40 diesel fleet buses**

**Rule:** R51 `FUEL_TYPE_TRANSITION_VIABILITY` — LOW / Saving

### SQL Query

```sql
SELECT COUNT(*) AS diesel_vehicles
FROM tpt_vehicle v
JOIN sys_dropdown_table d ON d.id = v.fuel_type_id
WHERE v.deleted_at IS NULL
  AND v.is_active = 1
  AND UPPER(d.value) LIKE '%DIESEL%';
```

### Calculation Trace

| Step | Value |
|---|---|
| `diesel_vehicles` | 40 |
| Trigger | `>= 15` |
| `benefitAmount` | 40 (unit `buses`) |

---

# Record 32 — Driver mobile trip synchronization: 60 incomplete logs

**Card:**

> **32 · LOW · Operations · Driver App Sync**  
> **Driver mobile trip synchronization audit: 60 incomplete trip logs**  
> Missing start odometer readings in last 7 days.

**Rule:** R59 `DRIVER_APP_OUTDATED_RECORDS` — LOW / Operations

### SQL Query

```sql
SELECT COUNT(*) AS incomplete_trips
FROM tpt_trip
WHERE deleted_at IS NULL
  AND trip_date >= '2026-10-12' - INTERVAL 7 DAY
  AND (start_odometer_reading IS NULL OR start_odometer_reading = 0);
```

### Calculation Trace

| Step | Value |
|---|---|
| `incomplete_trips` | 60 |
| Trigger | `>= 5` |
| `benefitAmount` | 60 (unit `trips`) |
| Note (F8) | Column defaults to `0.00`, so trips that never started are also counted |

---

## Appendix — Global Formula Reference

| Symbol | SQL | Notes |
|---|---|---|
| `days_left` | `DATEDIFF(valid_upto, '2026-10-12')` | Negative = already expired |
| `students` | `GREATEST(pickup_count, drop_count)` | From `tpt_student_route_allocation_jnt` |
| `capacity` | `tpt_vehicle.capacity` | Via the active assignment |
| `extra` | `students − capacity` | Overload amount |
| `utilization_pct` | `ROUND(students / capacity × 100)` | 133% = overloaded |
| `money(x)` | `'₹' || FORMAT(x, 0)` | Western grouping in the UI |
| `distance_m` | Haversine (see engine) | Metres between two lat/lng |

### Sort Order Used by the Engine

1. **Safety flag** — Safety category first
2. **Priority** — HIGH → MEDIUM → LOW
3. **Rupee benefit** — Largest rupee value first (only when `benefitUnit = 'rupees'`)
4. **Registry order** — ties keep original rule order

### Reference Date

All examples assume **12 October 2026**. To reproduce on the live system, replace `'2026-10-12'` with `CURDATE()` in every query above.

---

*End of Smart Advisor SQL Guide — 32 records.*