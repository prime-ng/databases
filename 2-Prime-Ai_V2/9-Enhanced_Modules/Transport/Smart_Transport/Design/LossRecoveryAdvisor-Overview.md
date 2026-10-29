# LossRecoveryAdvisor & Smart Advisor Map — Comprehensive Calculation & System Guide

> **Document Type:** Senior Management & Technical Audit Specification  
> **Target Audience:** Principal, Transport Director, Financial Controller, Lead Engineers  
> **Source Files Verified:**  
> 1. `Modules/SmartTransport/app/Services/LossRecoveryAdvisor.php` (4,458 lines)  
> 2. `public/backend/js/smart-advisor-map.js` (6,031 lines)  
> 3. `Modules/SmartTransport/app/Services/RouteProposalPlanner.php`  
> **Tone:** Clear, professional English with full mathematical transparency, real-world examples, and UI/Modal display explanations.

---

## Table of Contents
1. [Core Executive Summary](#1-core-executive-summary)
2. [Data Foundation: How Inputs Are Measured vs Fallback Defaults](#2-data-foundation-how-inputs-are-measured-vs-fallback-defaults)
3. [The Financial Core: Income, Expense, Variable Rate & Monthly KM Formulas](#3-the-financial-core-income-expense-variable-rate--monthly-km-formulas)
   - 3.1 [Student Fare Allocation (Both vs Pickup vs Drop Split)](#31-student-fare-allocation-both-vs-pickup-vs-drop-split)
   - 3.2 [Monthly Distance Calculation & Road Factor](#32-monthly-distance-calculation--road-factor)
   - 3.3 [Variable Operating Rate (Fuel + Maintenance ₹/km)](#33-variable-operating-rate-fuel--maintenance-km)
   - 3.4 [Fixed Overhead & Crew Salary Costing](#34-fixed-overhead--crew-salary-costing)
4. [The Mathematical Zero-Harm Safety Guard](#4-the-mathematical-zero-harm-safety-guard)
5. [In-Depth Card Catalog & Exact Calculation Formulas](#5-in-depth-card-catalog--exact-calculation-formulas)
   - [Tier 1: Zero / Low Cost Restructuring](#tier-1-zero--low-cost-restructuring)
   - [Tier 2: Demand & Corridor Synergy](#tier-2-demand--corridor-synergy)
   - [Tier 3: Structural & Fleet Sizing (Split, Right-Size, Van Economics)](#tier-3-structural--fleet-sizing-split-right-size-van-economics)
   - [Tier 4: Financial Governance & Policy (Fare, Rent, Maintenance Audit)](#tier-4-financial-governance--policy-fare-rent-maintenance-audit)
   - [Bus-Level Dedicated Cards](#bus-level-dedicated-cards)
6. [Interactive UI Engine: Modal Detail Display & Map Reconciliation (`smart-advisor-map.js`)](#6-interactive-ui-engine-modal-detail-display--map-reconciliation-smart-advisor-mapjs)
   - 6.1 [P&L Modal Breakdown (Current vs Proposed Income, Expense, Net)](#61-pl-modal-breakdown-current-vs-proposed-income-expense-net)
   - 6.2 [Distance & Commute Time Projection (22 km/h city bus speed + dwell)](#62-distance--commute-time-projection-22-kmh-city-bus-speed--dwell)
   - 6.3 [Stop-by-Stop Roster Table & Role Tagging](#63-stop-by-stop-roster-table--role-tagging)
   - 6.4 [Route Safety & Health Alerts (60-min Commute & Zig-Zag TSP)](#64-route-safety--health-alerts-60-min-commute--zig-zag-tsp)
7. [Synergy: How Smart Advisor Connects to RouteProposalPlanner](#7-synergy-how-smart-advisor-connects-to-routeproposalplanner)
8. [Master Comprehensive Conditions & Formulas Matrix](#8-master-comprehensive-conditions--formulas-matrix)

---

## 1. Core Executive Summary

The **Loss Recovery Advisor** coupled with the **Interactive Smart Advisor Map Engine** provides school management with an auditable, data-backed financial decision suite. School bus routes commonly run at a loss because of empty return trips, low-density detours, oversized vehicles, or uncoordinated timetables. 

Rather than guessing or applying blanket fare hikes, the engine executes real-time mathematical evaluations on every bus and route. Every recommendation generates:
1. **Concrete Rupee Savings/Gain (`monthly_saving`)**.
2. **Operational Mileage Impact (`extraKm`, `savedKm`, commute minutes)**.
3. **Zero-Harm Verification** (ensuring donor or partner routes do not collapse into losses).
4. **Interactive Geospatial Visualization** showing parents and drivers exactly where halts move or merge.

---

## 2. Data Foundation: How Inputs Are Measured vs Fallback Defaults

The system never relies on static assumptions if live ERP operational logs exist. The table below outlines how each metric is extracted, the mathematical smoothing applied, and the fallback value used when cold-started with zero historical records:

| Parameter | Primary Source in Database | Mathematical Derivation | Fallback Default |
|---|---|---|---|
| **Monthly Working Days ($D$)** | `tpt_trip.trip_date` (Trailing 30 days) | Run rate: $\text{min}\left(30, \max\left(1, \frac{\text{distinct trip dates}}{\text{elapsed days}} \times 30\right)\right)$ | Driver attendance run rate $\to$ Default: **26 days** |
| **Trips Per Day ($T_d$)** | `tpt_trip` (Trailing 30 days) | $\frac{\text{total trips completed}}{\text{active days} \times \text{active vehicles}}$, clamped $[1.0, 6.0]$ | Shift count $\div$ active buses $\to$ Default: **1.0 trip/day** |
| **Crew Duty Minutes ($M_c$)** | `tpt_driver_attendance.total_work_minutes` | Median of duty minutes $>60$ min over trailing 30 days | In/Out timestamp difference median $\to$ Default: **480 min (8 hours)** |
| **Stop Dwell Duration ($T_{dwell}$)** | `tpt_trip_stop_detail` (`reaching_time` vs `leaving_time`) | Median difference in minutes where $1 \le \Delta \le 15$ mins | Default: **3.0 minutes per stop** |
| **Mid-Day Idle Share ($S_{idle}$)** | `tpt_trip` gaps (`start_time` vs `end_time`) | Average gap between morning trip end and afternoon trip start $\div 8.0$ hours | Clamped $[0.25, 0.75] \to$ Default: **50% (0.50)** |
| **Road Winding Factor ($F_{road}$)** | `sys_pickup_point_route.total_distance` vs Haversine chain | $\text{Ratio} = \frac{\sum \text{entered road km}}{\sum \text{haversine crow-fly km}}$, verified if sane $[1.0, 2.0]$ | Fleet median ratio $\to$ Default: **1.30 (+30% road curvature)** |
| **Fuel Rate ($P_{fuel}$)** | `tpt_vehicle_fuel` (Approved last 90 days) | $\frac{\sum \text{approved cost}}{\sum \text{approved litres}}$ | Null / Flagged |
| **Driver & Helper Salaries** | `hr_salary_assignment` linked via `tpt_driver_helper` | Latest active `gross_monthly` wage | Flagged as unlinked / ₹0 |
| **Mini-Van Capacity Range** | `tpt_vehicle` active where $\text{capacity} \le 30$ | $[\text{min}(\text{capacity}), \text{max}(\text{capacity})]$ | **[8, 22] seats** |
| **Vendor Rent Threshold** | `vnd_invoice` (`is_bus_charges=true`) | $\frac{\text{invoiced bus rent}}{\text{rent} + \text{maintenance} + \text{fuel}}$, clamped $[0.15, 0.40]$ | Fleet benchmark: **30% (0.30)** |
| **Maintenance Threshold** | `tpt_vehicle_maintenance` (Approved 90 days) | $\frac{\text{maintenance cost}}{\text{rent} + \text{maintenance} + \text{fuel}}$, clamped $[0.10, 0.30]$ | Fleet benchmark: **15% (0.15)** |

---

## 3. The Financial Core: Income, Expense, Variable Rate & Monthly KM Formulas

### 3.1 Student Fare Allocation (Both vs Pickup vs Drop Split)

A common mistake in transport management is double-counting student fares. If a student pays ₹2,000/month for both morning pickup and afternoon drop, booking ₹2,000 to the morning route and ₹2,000 to the afternoon route exaggerates fleet revenue by 100%.

In `LossRecoveryAdvisor.php` (`routeLoad()` & `allAllocationStats()`):
- **`transport_use_type = 'both'`**: The monthly fare is split exactly 50/50:
  $$\text{Income}_{\text{pickup\_route}} += \frac{\text{Fare}}{2}, \quad \text{Income}_{\text{drop\_route}} += \frac{\text{Fare}}{2}$$
- **`transport_use_type = 'pickup'`**:
  $$\text{Income}_{\text{pickup\_route}} += \text{Fare}, \quad \text{Income}_{\text{drop\_route}} += 0$$
- **`transport_use_type = 'drop'`**:
  $$\text{Income}_{\text{pickup\_route}} += 0, \quad \text{Income}_{\text{drop\_route}} += \text{Fare}$$

> [!IMPORTANT]
> When evaluating stop reassignment (`optAddStop` or `findAddOptions`), the revenue gained is calculated strictly on this half-fare split. Moving a 'both' student's pickup stop credits the receiving route with $\frac{\text{Fare}}{2}$, matching the accounting P&L precisely.

---

### 3.2 Monthly Distance Calculation & Road Factor

To evaluate fuel consumption and wear-and-tear costs, the route's monthly operational kilometres must be determined.

1. **Odometer-First Hierarchy:**  
   If the bus assigned to the route has approved fuel logs with odometer entries over the last 90 days:
   $$\text{Monthly KM} = \frac{\text{Max(Odometer)} - \text{Min(Odometer)}}{\text{Elapsed Days}} \times 30$$
2. **Entered Road Leg Fallback:**  
   If odometer logs are absent:
   $$\text{Monthly KM} = \left(\sum_{i=1}^{N} \text{leg\_distance}_i\right) \times 2 \times D$$
   *(where $2$ represents the two-way return cycle, and $D$ is the monthly working days, default 26).*
3. **Haversine Geo-Chain with Road Curvature:**  
   If entered road distances are missing from database tables:
   $$\text{Haversine Crow-fly KM} = \sum_{i=1}^{N-1} 2 R \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta \text{lat}}{2}\right) + \cos(\text{lat}_i)\cos(\text{lat}_{i+1})\sin^2\left(\frac{\Delta \text{lon}}{2}\right)}\right)$$
   $$\text{Monthly KM} = \text{Haversine KM} \times F_{road} \times 2 \times D$$
   *(where $R = 6371\text{ km}$, and $F_{road}$ is the route's measured road curvature factor, typically $1.30$).*

---

### 3.3 Variable Operating Rate (Fuel + Maintenance ₹/km)

Fixed overheads (bus purchase, driver monthly salary, vendor lease) are paid whether the bus drives 10 km or 50 km. Adding or cutting a stop only impacts **variable costs** (fuel and tire/engine wear).

$$\text{Variable Cost Per KM } (R_{var}) = \frac{\text{Fuel Cost}_{\text{monthly}} + \text{Maintenance Cost}_{\text{monthly}}}{\text{Monthly KM}}$$

- **Detour Cost Evaluation:** If adding a stop adds $\Delta \text{km}$ detour:
  $$\Delta \text{Cost} = \Delta \text{km} \times F_{road} \times 2 \times D \times R_{var}$$
- **Detour Saving Evaluation:** If skipping a thin detour saves $\Delta \text{km}$ per trip:
  $$\Delta \text{Saving} = \text{Fuel Cost}_{\text{monthly}} \times \min\left(0.50, \frac{\Delta \text{km}}{\text{Route One-Way KM}}\right)$$

---

### 3.4 Fixed Overhead & Crew Salary Costing

$$\text{Total Monthly Expense} = \text{Fuel Cost} + \text{Maintenance Cost} + \text{Crew Salary} + \text{Vendor Rent}$$
$$\text{Net Profit / Loss} = \text{Monthly Income} - \text{Total Monthly Expense}$$

- If a driver or helper is reassigned or a bus is decommissioned, the entire fixed amount ($\text{Salary} + \text{Rent}$) is recouped.
- If a route merely shortens its travel distance, fixed crew salary remains untouched, but **time-value** is unlocked:
  $$\text{Crew Cost Per Minute} = \frac{\text{Driver Salary} + \text{Helper Salary}}{D \times M_c}$$

---

## 4. The Mathematical Zero-Harm Safety Guard

Every card that transfers students or alters multi-bus logistics passes through `zeroHarmGuard($proposal, $allRouteItems)`:

```
                  ┌───────────────────────────────┐
                  │    Proposed Stop Transfer     │
                  └──────────────┬────────────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
       Target Route (Gains)            Donor Route (Loses)
       - Adds Students                 - Sheds Students
       - Adds Income                   - Loses Income
       - Incurs Extra Detour KM        - Saves Detour KM
                 │                               │
                 ▼                               ▼
       Capacity Check:                 Profitability Check:
       Students + ΔS ≤ MaxCap          1. Did Net go from ≥ 0 to < 0?
       (Must NOT exceed seats)            (Profitable became Loss? ➔ BLOCKED)
                                       2. Did existing Loss worsen by >10%?
                                          (Net_new < Net_old × 1.10? ➔ BLOCKED)
```

### The Three Guard Axioms:

1. **Axiom 1: No Route May Flip from Profit into Loss.**  
   If Donor Route current net profit is $\ge 0$ (e.g. $+₹3,200$), and after transferring the stop the revised net is $< 0$ (e.g. $-₹400$):  
   $$\implies \mathbf{BLOCKED}: \text{"Route would turn loss-making. Transfer blocked to protect overall fleet margin."}$$

2. **Axiom 2: Pre-existing Losses Cannot Deteriorate by $>10\%$.**  
   If Donor Route is already losing $-₹5,000/\text{month}$, the loss cannot drop below $-₹5,500$:  
   $$\text{If } \text{Net}_{\text{current}} < 0 \text{ and } \text{Net}_{\text{revised}} < \left(\text{Net}_{\text{current}} \times 1.10\right) \implies \mathbf{BLOCKED}$$

3. **Axiom 3: Seat Capacity Cannot Be Exceeded.**  
   If Target Route receives $\Delta S$ students:  
   $$\text{Current Students} + \Delta S > \text{Vehicle Maximum Capacity} \implies \mathbf{BLOCKED}$$

> [!NOTE]
> When a proposal is blocked, it is **never hidden** from the user. It is preserved on screen, placed at the bottom of the list, clearly tagged `blocked = true`, and displays the exact math why it was rejected.

---

## 5. In-Depth Card Catalog & Exact Calculation Formulas

### Tier 1: Zero / Low Cost Restructuring

#### 1. Create a Central Hub Stop (`optCentralHubStop`)
- **Trigger:** Two or more stops are separated by $\le 600\text{ metres}$.
- **Plain English Explanation:** The bus avoids entering multiple narrow residential alleys where stopping, idling, and restarting burn excess diesel. Instead, one easily accessible stop is designated on the main junction, and students walk a safe 100–300 metres to meet the bus together.
- **Real-World Example:** Route 5 stops at Block-A (2 students) and Block-B (3 students) only 350 metres apart. Merging both into "Greenwood Main Gate" saves 6 minutes of bus idling and ₹1,450/month in diesel with 0 lost students.
- **Mathematical Centroid Formulation:**  
  The system computes the exact geographical barycentre for the new stop:
  $$\text{Lat}_{hub} = \frac{\sum_{i=1}^K \text{Lat}_i}{K}, \quad \text{Lon}_{hub} = \frac{\sum_{i=1}^K \text{Lon}_i}{K}$$
- **Monthly Savings Formula:**  
  Eliminating $(K - 1)$ halts eliminates the acceleration, deceleration, and idling cycles:
  $$\text{Monthly Saving} = (K - 1) \times T_{dwell} \times \left(\frac{\text{Crew Salary}}{D \times M_c}\right) \times (D \times T_d)$$
- **Zero Student Drop:** All students remain enrolled. They walk between 80m and 300m to the main junction stop.

#### 2. Cut Thin Detours (`optDetour`)
- **Trigger:** A lateral stop serves $\le \max(2, \min(5, \text{round}(\text{Capacity} \times 0.10)))$ students (typically $\le 3$ students on a 40-seater), and adds $\ge \max(0.3\text{ km}, \text{Route KM} \times 0.02)$ detour.
- **Plain English Explanation:** Stops that take the bus far off the main highway for only 1 or 2 students are eliminated if those students live within a safe walking distance of another stop that remains active.
- **Real-World Example:** A 40-seat bus on Route 12 takes a 1.8 km loop into "Orchard Lane" for only 2 students. Removing this detour saves 93 km and ₹2,100 in monthly fuel; both students walk 450m to "Sector 4 Crossing".
- **The Zero-Orphan Rule:** Every candidate stop must have a **surviving** stop within $800\text{ metres}$ walking distance:
  $$\text{Distance to nearest surviving stop} \le 0.80\text{ km}$$
  *(Terminal stops—the first departure and final school arrival—are strictly protected and can never be cut).*
- **Savings Formula:**
  $$\text{Monthly Saving} = \text{Fuel Cost}_{\text{monthly}} \times \min\left(0.50, \frac{\sum \text{Saved Detour KM}}{\text{Route Total KM}}\right)$$

#### 3. Consolidate Clustered Stops (`optClusterStops`)
- **Trigger:** Adjacent stops on the same route are within $500\text{m}$ (or $800\text{m}$ if low student volume $\le 14$ combined).
- **Plain English Explanation:** When two stops on the same road are so close that the bus barely accelerates before braking again, the smaller stop is combined into the larger one to keep the bus moving smoothly.
- **Real-World Example:** Stop 3 ("Apex Tower", 4 students) is 420 metres from Stop 4 ("City Plaza", 10 students). Apex Tower is consolidated into City Plaza, saving 3 minutes trip time and ₹850/month in brake and fuel wear.
- **Consolidation Logic:** The stop with lower student count merges into the higher-density stop.
- **Savings Formula:**
  $$\text{Monthly Saving} = \text{Cluster Count} \times T_{dwell} \times \text{Crew Cost Per Minute} \times (D \times T_d)$$

#### 4. Safe Walking Zone Policy (`optWalkingZonePolicy`)
- **Trigger:** Intermediate stops located within $650\text{ metres}$ of the school campus coordinates.
- **Plain English Explanation:** School buses crawling through traffic right in front of the school gate waste excessive low-gear fuel and create safety hazards. Stops within a short walk of the gate are removed from the bus route.
- **Real-World Example:** "North Gate Colony" is just 500m from the school entrance. Removing it cuts 10 minutes of morning congestion at the school gate and saves ₹920/month in crawling fuel.
- **Operational Reality:** Big buses crawling through school perimeter bottlenecks waste excessive fuel at low gears.
- **Savings Formula:**
  $$\text{Monthly Saving} = \text{Fuel Cost}_{\text{monthly}} \times 0.05 \times \text{Stop Count}$$
  *(Saves 5% crawling fuel per near-campus stop and clears 10–15 minutes of gate congestion).*

---

### Tier 2: Demand & Corridor Synergy

#### 5. Seat Fill / Add Nearby Stop (`optAddStop`)
- **Trigger:** This route has spare headroom $\ge 2$ seats; a nearby foreign route has a stop with $\ge 2$ students within reachable proximity.
- **Plain English Explanation:** An underloaded bus picks up students from a nearby crowded bus route that passes close to its path. This fills empty seats with paying students without adding significant extra travel time.
- **Real-World Example:** Route 8 has 10 empty seats. It takes over "Parkview Stop" (4 students, paying ₹7,200/month total fare) from Route 3 with only a 0.8 km detour costing ₹1,100 in diesel, netting ₹6,100/month pure profit.
- **Detour & Economics:**
  $$\text{Extra Monthly KM} = \text{Haversine Distance} \times F_{road} \times 2 \times D$$
  $$\text{Extra Detour Cost} = \text{Extra Monthly KM} \times R_{var}$$
  $$\text{Net Monthly Profit} = \text{Income Gained} - \text{Extra Detour Cost}$$
- Passed through the Zero-Harm Guard to ensure the donor route is not harmed.

#### 6. Multi-Stop Addition (`optAddMultipleStops`)
- **Trigger:** Finds up to two stops from separate donor routes that fit within headroom and optimize total detour via shortest-path ordering.
- **Plain English Explanation:** When a bus has large surplus capacity, the system pairs two nearby stops from two different crowded routes into an optimized mini-loop to maximize new student fee collections.
- **Real-World Example:** A 50-seater bus carrying only 28 students adds Stop X (3 students) and Stop Y (4 students). Total new fare is ₹12,600/month against ₹2,800 in detour running costs, yielding a net monthly gain of ₹9,800.

#### 7. Overlapping Stop Transfer (`optTransferOverlappingStop`)
- **Trigger:** A stop is served by two different routes. Route A is running at a loss; Route B has spare capacity.
- **Plain English Explanation:** When two different school buses visit the exact same bus stop, the losing bus stops going there completely and hands its passengers over to the profitable partner bus that has open seats.
- **Real-World Example:** Both Bus 4 (losing ₹6,000/mo) and Bus 7 (profitable, 8 empty seats) stop at "Central Market". Bus 4 drops the stop, transferring 5 students to Bus 7, saving Bus 4 ₹2,400/month in detour fuel.
- **Formula:** Route A drops the stop entirely. Route A loses that stop's fee income, but saves the detour mileage:
  $$\text{Fuel Saved} = \text{Leg Distance} \times 2 \times D \times R_{var}$$
  $$\text{Net Impact on Route A} = \text{Fuel Saved} - \text{Income Shed}$$
  Allowed only if Route A's net loss is reduced, and Route B absorbs the riders comfortably within vehicle limits.

#### 8. Corridor Rebalancing (`optCorridorRebalance`)
- **Trigger:** Route A is overcrowded ($\ge 88\%$ capacity), while parallel Route B running the same arterial road has $\ge 3$ empty seats. There are $\ge 2$ shared/adjacent stops ($\le 1.0\text{ km}$ apart).
- **Plain English Explanation:** Two buses travel along the same main highway, but one is dangerously packed while the other is half empty. A few stops are reassigned to balance passenger counts safely across both buses.
- **Real-World Example:** Bus 14 is at 95% capacity (38 of 40 seats filled). Bus 15 runs the same road with 18 empty seats. Moving 5 students from the highway stops to Bus 15 relieves overcrowding and transfers ₹8,500/month in balanced revenue.
- **Shift Calculation:**
  $$\text{Students Shifted} = \min(\text{Headroom}_B, \min(6, \lceil \text{Students}_A - \text{Capacity}_A \times 0.85 \rceil))$$
  $$\text{Revenue Transferred} = \text{Students Shifted} \times \text{Average Fare}_A$$
- Resolves unsafe overcrowding on Route A without buying an extra bus, while monetizing Route B's empty seats.

#### 9. Swap Buses Across Routes (`optSwap`)
- **Trigger:** Route A has a large bus ($>32$ seats) with low occupancy ($\le 60\%$). Route B has a smaller bus that is crowded ($>80\%$).
- **Plain English Explanation:** A school route with few students is driving an expensive 50-seater bus, while another busy route is crammed into a small 32-seater. Swapping their assigned buses fixes both problems immediately.
- **Real-World Example:** Route 2 has 22 students on a 52-seater bus. Route 9 has 30 students on a 32-seater bus. Swapping them gives Route 9 room to breathe and saves Route 2 ₹4,200/month in heavy diesel and maintenance.
- **Savings Formula:** Route A saves variable running costs corresponding to the smaller bus engine:
  $$\text{Monthly Saving} = (\text{Fuel Cost}_A + \text{Maintenance Cost}_A) \times 0.20$$

#### 10. Route Merge (`optMerge`)
- **Trigger:** Route A has low load; Route B's nearest stop is within $3.5\text{ km}$; combined student count $\le \text{Capacity}_B$.
- **Plain English Explanation:** An underutilized route with very few students is combined into a nearby route, completely shutting down one bus and eliminating a full driver salary and lease cost.
- **Real-World Example:** Route 18 has only 12 students and loses ₹14,000/month. Route 11 has 24 students on a 42-seat bus. Merging Route 18 into Route 11 eliminates Bus 18 entirely, saving ₹22,000 in monthly lease and driver salary.
- **Financial Payoff:** Route A is decommissioned entirely.
  $$\text{Gross Saving} = \text{Vendor Rent}_A + \text{Driver Salary}_A + \text{Helper Salary}_A + \text{Fuel Cost}_A$$
  $$\text{Survivor Detour Cost} = \text{Connecting KM} \times 2 \times D \times R_{var, B}$$
  $$\mathbf{Net Monthly Saving} = \text{Gross Saving} - \text{Survivor Detour Cost}$$

#### 11. Run Two Shifts on One Bus (`optShiftReuse`)
- **Trigger:** Route A operates only in morning; Route B operates in afternoon.
- **Plain English Explanation:** Instead of paying monthly rent for two buses that each sit idle for half the day, a single bus runs the morning junior school shift, rests, and then completes the senior afternoon shift.
- **Real-World Example:** Bus A finishes morning duty at 8:15 AM. Bus B starts afternoon duty at 1:30 PM. Operating both with Bus A decommissions Bus B, saving ₹18,000/month in redundant lease and helper wages.
- **Log-Verified Window Gap:**
  $$\text{Gap} = \text{Start Time}_B - \text{End Time}_A \ge 45\text{ minutes}$$
- **Savings:** Decommissions the second vehicle:
  $$\text{Monthly Saving} = \text{Rent}_B + \text{Driver Salary}_B + \text{Helper Salary}_B - (\text{Monthly KM}_B \times R_{var, A})$$

---

### Tier 3: Structural & Fleet Sizing (Split, Right-Size, Van Economics)

#### 12. Right-Size Vehicle (`optRightSize`)
- **Case A: Idle Bus in Yard**  
  An unassigned bus with smaller capacity exists that can seat all current students:
  - **Plain English Explanation:** When a route with only 18 students is running an expensive 45-seater bus, and the school yard already has an unused 24-seater bus sitting idle, switching to the smaller bus cuts fuel and tire costs immediately.
  - **Real-World Example:** Route 6 has 19 students on a 42-seater bus costing ₹26,000/month. Reassigning idle 24-seater Bus #10 saves ₹5,800/month in diesel and engine wear.
  $$\text{Saving} = \text{Old Rent} + [(\text{Fuel} + \text{Maint}) \times (1 - \text{Burn Ratio})]$$
  *(Burn Ratio is derived from real fuel logs of smaller vehicles in the fleet).*
- **Case B: Downsize to Mini-Bus**  
  Route capacity $\ge 30$, occupancy $\le 60\%$. Target size is calculated:
  - **Plain English Explanation:** When the school doesn't own an idle bus, but a large bus is running half empty, the school replaces the vendor contract with a compact mini-bus to eliminate paying for unused seats.
  - **Real-World Example:** Route 16 has 22 students on a 50-seater bus. Downsizing to a 28-seater mini-bus lowers monthly vendor lease from ₹15,000 to ₹8,400 and cuts fuel by 35%, saving ₹9,200/month.
  $$\text{Target Capacity} = \max\left(18, \left\lceil \frac{\text{Students} + 4}{5} \right\rceil \times 5\right)$$
  $$\text{Capacity Ratio} = \frac{\text{Target Capacity}}{\text{Old Capacity}}$$
  $$\text{Fuel Saved} = (\text{Fuel} + \text{Maint}) \times (1 - \text{Capacity Ratio})$$
  $$\text{Mini-Bus Lease Rent} = \text{Old Rent} \times \text{Capacity Ratio}$$
  $$\mathbf{Total Saving} = \text{Fuel Saved} + (\text{Old Rent} - \text{Mini-Bus Rent})$$

#### 13. Route Split with Feeder Mini-Van (`optRouteSplit`)
When a 45-seater bus drives 35 km one-way, but the final 12 km carries only 3 to 6 students, running a giant bus into rural lanes burns heavy diesel. The system tests every possible cut point $K$ (from stop 2 to $N-2$).
- **Plain English Explanation:** A big bus travels a long distance into rural or narrow lanes just to pick up 4 or 5 kids. The big bus turns around at a main junction hub, while a hired mini-van picks up those far-away students and brings them to meet the big bus.
- **Real-World Example:** Route 21 runs 32 km one-way. The last 10 km has only 4 students. Big bus stops at "Highway Junction" and saves 20 km of driving daily; a small 8-seat feeder van shuttles the 4 students, netting ₹6,400/month after paying the van driver.

```
[School] ===== Trunk (Big Bus 45-seater) =====> [Turnaround Hub K] ----- Feeder Tail (Mini-Van) -----> [Stop N]
                                                         │
                                               Tail Students Transfer
```

- **Candidate Evaluation:**
  - $\text{Big Bus KM} = \text{Chain}(0 \dots K) \times F_{road}$
  - $\text{Van KM} = \text{Chain}(K \dots N) \times F_{road}$
  - **Van Sizing:** $\text{Need} = \lceil \text{Tail Students} / 5 \rceil \times 5$, clamped to $[8, 22]$ seats.
- **Dynamic Van Costing Engine (`vanEconomics`):**
  - $\text{Van Per-KM Rate} = R_{var, \text{big}} \times \left(\frac{\text{Van Capacity}}{\text{Big Capacity}}\right)$
  - $\text{Van Fixed Monthly} = (\text{Vendor Rent Base} \times \text{Ratio}) + \text{Fleet Median Driver Salary}$
- **Net Economics:**
  $$\text{Big Bus Fuel Saved} = \text{Van KM} \times 2 \times D \times \text{Big Bus Fuel Rate Per KM}$$
  $$\text{Van Operational Cost} = (\text{Van KM} \times 2 \times D \times \text{Van Per-KM Rate}) + \text{Van Fixed Monthly}$$
  $$\mathbf{Net Saving} = \text{Big Bus Fuel Saved} - \text{Van Operational Cost}$$
  *(Must clear at least 1% of the route's total expense to be viable; otherwise, the exact shortfall is reported).*

#### 14. Tail Walking Feasibility Analysis (`optTailAnalysis`)
- **Trigger:** Tail section has $2 \le \text{Students} \le 7$ (too few to justify leasing a mini-van).
- **Condition:** If the tail students live within $450\text{ metres}$ of the designated turnaround Hub Stop:
  $$\text{Walking Distance} \le 450\text{m}$$
- **Plain English Explanation:** When there are only 2 or 3 students at the far end of the route, hiring a feeder van is too costly. If they live within 400 metres of the main road hub, they simply walk to the hub stop, and the tail is eliminated.
- **Real-World Example:** Stop 14 has 2 students living 380m from the Highway Hub. Having them board at the Hub eliminates 8 km of driving daily, saving ₹3,600/month in diesel with ₹0 extra equipment cost.
- Eliminates the tail driving entirely with zero van expenditure.

#### 15. Replace One Big Bus with Two Mini-Buses (`optTwoMiniBuses`)
- **Trigger:** Big bus $>30$ seats, students $\le 40$, and fleet yard has $\ge 2$ idle mini-buses available.
- **Plain English Explanation:** Instead of running one sluggish 50-seater bus on a sprawling 2-hour circular route, two quick 20-seater mini-buses divide the area into two fast 40-minute loops.
- **Real-World Example:** Route 1 covers 36 students on a 52-seater. Deploying two idle 20-seater mini-buses cuts student ride times in half and eliminates ₹11,000/month in heavy bus fuel.
- Deploys two synchronized mini-buses running parallel loops.

---

### Tier 4: Financial Governance & Policy (Fare, Rent, Maintenance Audit)

#### 16. Student Fare Recalibration (`optFare`)
- **Trigger:** $\text{Average Fare Per Student} < \text{Cost Per Student}$.
- **Plain English Explanation:** When transport fees collected fail to cover fuel and driver wages, the system calculates a gradual, reasonable fee increase while accounting for families who might choose private carpools.
- **Real-World Example:** Route 7 costs ₹1,650/student to operate, but charges only ₹1,200. Recommending a phased hike to ₹1,450 accounts for 1 student leaving (attrition) and still recovers ₹7,800/month of the route deficit.
- **Stepped Hike & Attrition Model:**
  $$\text{Breakeven Fare} = \frac{\text{Total Route Expense}}{\text{Student Count}}$$
  $$\text{Recommended Hike } (\Delta P) = \text{min}\left(0.20, \frac{\text{Breakeven Fare} - \text{Current Fare}}{\text{Current Fare}}\right)$$
  $$\text{Expected Attrition} = \text{Student Count} \times 0.03 \quad (3\% \text{ attrition factor derived from fee history})$$
  $$\text{Revised Income} = (\text{Student Count} - \text{Attrition}) \times (\text{Current Fare} \times (1 + \Delta P))$$
  $$\mathbf{Net Monthly Gain} = \text{Revised Income} - \text{Current Income}$$

#### 17. Vendor Lease Renegotiation (`optRent`)
- **Trigger:** Route rent share $> \text{Fleet Rent Threshold}$ (default $30\%$).
- **Plain English Explanation:** The transport vendor is charging significantly higher lease rates on this specific bus compared to the average rate across the rest of the school fleet.
- **Real-World Example:** Bus 19's vendor lease is ₹16,000/month (42% of total route cost) against a fleet average of ₹10,500. Renegotiating back to benchmark saves ₹5,500/month.
- **Formula:**
  $$\text{Benchmark Rent} = \text{Total Route Expense} \times \text{Fleet Threshold (30\%)}$$
  $$\text{Target Monthly Saving} = \text{Current Rent} - \text{Benchmark Rent}$$

#### 18. Maintenance Audit (`optMaintenance`)
- **Trigger:** Maintenance expense $> 15\%$ of total route costs.
- **Plain English Explanation:** Repair and servicing bills for this vehicle are unusually high, suggesting either questionable workshop invoicing or an aging engine that should be replaced.
- **Real-World Example:** Bus 6 billed ₹8,500 in maintenance in one month (28% of route expense). An internal audit reveals repeated brake repairs that justify warranty claims or vendor billing corrections.
- Flags workshop invoice inflation, chronic mechanical failure, or aging fleet assets.

#### 19. Subsidy or Planned Route Withdrawal (`optSubsidyOrWithdraw`)
- **Trigger:** All operational optimizations combined still leave an uncovered deficit.
- **Plain English Explanation:** After adjusting stops, routes, and vehicle sizes, the route still loses money. Management must formally decide whether to fund it as a community service or give parents 60 days notice of cancellation.
- **Real-World Example:** Route 25 serves 6 students in a remote village, leaving a ₹5,200/month deficit with no further fixes possible. The School Board formally approves a ₹5,200 monthly social subsidy.
- Presents management with two transparent options:
  1. Formal Board Budget Subsidy (e.g. ₹4,500/month for social/remote connectivity).
  2. 60-Day Notice Planned Route Withdrawal.

#### 20. Data Integrity Audit (`optVerifyData`)
- **Trigger:** Low data confidence (`crew_salary = 0`, `fuel_cost = 0`, or unlinked vehicle lease).
- **Plain English Explanation:** Important accounting or trip records are missing in the ERP system. Management is warned to update fuel and salary logs before trusting financial recommendations.
- **Real-World Example:** Driver salary is missing (₹0) and fuel receipts were not logged for 60 days. The system alerts the Transport Clerk to enter these missing records first.
- Displayed at the top of the report to prevent management from making decisions on unverified numbers.

---

### Bus-Level Dedicated Cards

1. **Deploy or Return Idle Bus:** Vehicle has an active vendor lease but no route assigned.
   - **Plain English Explanation:** A leased bus is parked in the depot doing nothing while the vendor sends monthly invoices. The school must immediately assign it to an overcrowded route or return it to end the contract.
   - **Real-World Example:** Bus DL-01-AB-1234 sits idle in the depot while costing ₹14,000/month in lease charges. Deploying it on a new morning extension recovers ₹24,000 in student fees.
   - **Formula:** Saving = 100% of monthly lease rent.

2. **Fuel Calibration (Bus-Level):** Vehicle km/litre is below the statistical outlier line ($\text{Mean} - 1\sigma$).
   - **Plain English Explanation:** Fuel log tracking identifies that a specific bus is consuming significantly more diesel per kilometre than all other buses in the fleet, signaling fuel theft or urgent engine servicing.
   - **Real-World Example:** Fleet average is 4.8 km/litre, but Bus #9 gets only 3.1 km/litre. Servicing injectors and fuel filters recovers half the gap, saving ₹4,800/month in wasted fuel.
   - **Formula:** Compares fuel burn against median.

3. **Mid-Day Trip Monetization:** Monetizes 50% idle shift window for sports charters and excursions.
   - **Plain English Explanation:** School buses sit parked between 9:00 AM and 1:00 PM. Instead of sitting idle, they are leased for inter-school sports events, field trips, or teacher excursions to bring in auxiliary revenue.
   - **Real-World Example:** Bus #3 is leased for local college sports transport during its 4-hour morning idle window, earning ₹12,000/month in extra income.
   - **Formula:** Uses vendor agreement rates across 26 working days.

---

## 6. Interactive UI Engine: Modal Detail Display & Map Reconciliation (`smart-advisor-map.js`)

When a user clicks any advisory card or add option on the route map, the engine executes a comprehensive client-side recalculation without querying the backend database.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PROPOSAL DETAIL MODAL                           │
├────────────────────────────────────────────────────────────────────────┤
│  [Overview Tab]           [Affected Stops Tab]       [Full Route P&L]  │
│                                                                        │
│  FINANCIAL IMPACT (P&L)          DISTANCE & SCHEDULE                   │
│  ─────────────────────          ───────────────────                    │
│  Income:   ₹42,000 ➔ ₹49,200 (+₹7.2k)   Monthly KM:  1,420 ➔ 1,482 (+62 km)│
│  Expense:  ₹48,000 ➔ ₹48,900 (+₹900)    Trip Time:   48 min ➔ 51 min   │
│  Net P&L: -₹6,000  ➔ +₹300   (+₹6.3k)   Halt Count:  11 stops ➔ 12     │
│  Status:   BREAKEVEN REACHED            Speed Basis: 22 km/h + 2m dwell│
│                                                                        │
│  STOP-BY-STOP ROSTER WITH ROLE BADGES                                  │
│  #  Stop Name        Students   Income    Role Badge     Action / Why  │
│  1  Rajouri Garden     4       ₹7,200    [Trunk / Kept] Runs unchanged │
│  2  Tagore Garden      6       ₹10,800   [Trunk / Kept] Runs unchanged │
│  3  Subhash Nagar      3       ₹5,400    [Added Here]   Reassigned in  │
│  4  Tilak Nagar Main   2       ₹3,600    [Merge Out]    Consolidates   │
└────────────────────────────────────────────────────────────────────────┘
```

### 6.1 P&L Modal Breakdown (Current vs Proposed Income, Expense, Net)

In `smart-advisor-map.js` (`detailPl`):
- **For Revenue Options (Add Stop, Rebalance, Fill Seats):**  
  New students raise **Income**. Extra mileage raises **Expense**:
  $$\text{Proposed Income} = \text{Current Income} + \text{Gained Fare}$$
  $$\text{Proposed Expense} = \text{Current Expense} + \text{Extra Detour Cost}$$
  $$\text{Proposed Net} = \text{Proposed Income} - \text{Proposed Expense}$$
- **For Cost-Cutting Options (Detour Cut, Cluster, Right-Size, Merge):**  
  Income remains 100% constant. Expenses drop:
  $$\text{Proposed Expense} = \text{Current Expense} - \text{Monthly Saving}$$
  $$\text{Proposed Net} = \text{Current Income} - \text{Proposed Expense}$$
- **Reconciliation Invariant:**
  $$\text{Net P&L} \equiv \text{Income} - \text{Expense}$$
  *(The UI verifies that the differences match across all three rows before rendering).*

---

### 6.2 Distance & Commute Time Projection

In `smart-advisor-map.js` (`detailKm`):
- **Per-Trip One-Way Distance:**
  $$\text{One-Way KM} = \frac{\text{Monthly KM}}{2 \times D}$$
- **Estimated Commute Duration:**
  $$\text{Est. Minutes} = \text{round}\left(\left(\frac{\text{One-Way KM}}{22\text{ km/h}}\right) \times 60\right) + (\text{Stop Count} \times 2\text{ mins})$$
  *(Assumes average urban school bus transit speed of $22\text{ km/h}$ plus $2\text{ minutes}$ deceleration/boarding dwell per stop).*

---

### 6.3 Stop-by-Stop Roster Table & Role Tagging

The modal displays every halt affected by the proposal, categorized into specific visual color-coded badges:

| Role Tag | Visual Badge | Operational Meaning |
|---|---|---|
| **`Added Here`** | Green Badge | Stop transferred from another bus to utilize empty seats. |
| **`Removed There` / `Moves Out`** | Red Badge | Stop removed from donor bus to relieve overcrowding or detours. |
| **`Combined Halt`** | Green Badge | Surviving primary stop that absorbs adjacent passengers. |
| **`Merge Out`** | Amber Badge | Secondary halt eliminated; students walk $\le 500\text{m}$ to primary stop. |
| **`New Central Hub`** | Emerald Badge | Brand new junction stop on the main road replacing multiple lane halts. |
| **`Trunk`** | Blue Badge | Core route halts retained by the big bus in a Route Split. |
| **`To Mini-Van`** | Cyan Badge | Rural tail halts handed over to the feeder van. |
| **`Kept (0 Change)`** | Gray/Slate Badge | Normal active stops that experience zero schedule or location change. |
| **`Drop Halt`** | Indigo Badge | Afternoon PM return stops displayed for complete route visibility. |

---

### 6.4 Route Safety & Health Alerts

The map engine continuously monitors route geometry:
1. **Long Commute Risk Alert:** If $\text{Est. Minutes} > 60\text{ minutes}$, the modal displays an alert recommending a Route Split to protect child welfare.
2. **Zig-Zag / Criss-Cross Backtracking Detection:** If the distance between Stop $A \to C$ is significantly shorter than $A \to B \to C$:
   $$d(A, B) + d(B, C) > 2.2 \times d(A, C) \quad \text{and} \quad \text{detour} > 2.0\text{ km}$$
   The UI displays a **Zig-Zag Warning** with a one-click button to trigger **Travelling Salesperson Problem (TSP) Optimization**.

---

## 7. Synergy: How Smart Advisor Connects to RouteProposalPlanner

The two modules in Smart Transport form a complete optimization cycle:

```
┌────────────────────────────────┐         ┌────────────────────────────────┐
│      LossRecoveryAdvisor       │         │      RouteProposalPlanner      │
│     (Financial Diagnosis)      │         │    (Database Proposal Engine)  │
├────────────────────────────────┤         ├────────────────────────────────┤
│ • Identifies loss-making lines │ ──────> │ • Takes Advisor recommendations│
│ • Calculates exact ₹ margins   │         │ • Generates SQL Proposal Batches│
│ • Validates Zero-Harm Guard    │         │ • Writes 'Stopage_Add',        │
│ • Displays Map & P&L Modals    │         │   'Stopage_Merge', allocations │
└────────────────────────────────┘         └────────────────────────────────┘
```

1. **LossRecoveryAdvisor** performs read-only analysis. It queries trips, fuel logs, attendance, and vendor contracts to discover inefficiencies.
2. Once the Coordinator and Principal approve a card (e.g. `Merge Stops` or `Add Stop`), the action is dispatched to **RouteProposalPlanner**.
3. **RouteProposalPlanner** writes the proposal into `tpt_route_proposals` and `tpt_proposed_pickup_points`:
   - Existing unchanged stops receive `proposal_type = NULL` (or baseline).
   - Brand new stops receive `Stopage_Add`.
   - Consolidated cluster stops receive `Stopage_Merge`.
   - Reassigned students receive `Student_Add` and `Student_Remove`.
4. Management approves the batch with one click, updating live master routes and student allocations simultaneously.

---

## 8. Master Comprehensive Conditions & Formulas Matrix

| # | Card Name | Primary Trigger Condition | Skip / Block Condition | Mathematical Saving Formula |
|---|---|---|---|---|
| **1** | **Central Hub Stop** | 2+ stops $\le 600\text{m}$ apart | $<3$ stops on route; single halt | $(K-1) \times T_{dwell} \times \text{CrewMinRate} \times (D \times T_d)$ |
| **2** | **Cut Detours** | Stop $\le 10\%$ cap; detour $\ge \max(0.3\text{km}, 2\%)$ | Orphan $>800\text{m}$; terminal halt | $\text{Fuel} \times \min\left(0.50, \frac{\text{Saved KM}}{\text{Route KM}}\right)$ |
| **3** | **Cluster Stops** | Adjacent stops within $500\text{m}$–$800\text{m}$ | $<3$ stops on route | $\text{Clusters} \times T_{dwell} \times \text{CrewMinRate} \times (D \times T_d)$ |
| **4** | **Walking Zone** | Stops $\le 650\text{m}$ from school coordinates | Terminal halts; no campus coords | $\text{Fuel} \times 0.05 \times \text{Stop Count}$ |
| **5** | **Add Nearby Stop** | Headroom $\ge 2$; stop riders $\ge 2$; net $>0$ | Headroom $<2$; Zero-Harm fail | $\text{Fare Income} - (\Delta \text{KM} \times R_{var})$ |
| **6** | **Multi-Stop Add** | Two stops together produce highest net profit | Exceeds headroom; Zero-Harm fail | $\sum \text{Income} - (\text{ShortestPath KM} \times R_{var})$ |
| **7** | **Overlapping Stop** | Stop shared by 2 buses; route in loss | Partner bus has 0 headroom | $\text{Detour KM} \times 2 \times D \times R_{var}$ |
| **8** | **Corridor Rebalance** | Parallel routes $\le 1\text{km}$; one crowded $>88\%$ | Headroom $<3$; routes diverge | $\text{Shifted Students} \times \text{Average Fare}_{\text{donor}}$ |
| **9** | **Swap Buses** | Large bus $\le 60\%$ full; small bus $>80\%$ full | Partner bus not crowded | $(\text{Fuel} + \text{Maint}) \times 0.20$ |
| **10** | **Route Merge** | Nearest stops $\le 3.5\text{km}$; combined $\le \text{Cap}_B$ | Combined $>$ Cap; already multi-route | $\text{Rent}_A + \text{Crew}_A + \text{Fuel}_A - \text{DetourCost}_B$ |
| **11** | **Shift Reuse** | Opposite shifts; log gap $\ge 45\text{ mins}$ | Gap $<45\text{m}$; bus already shared | $\text{Rent}_B + \text{Crew}_B - (\text{KM}_B \times R_{var, A})$ |
| **12** | **Shift Load Balance** | Asymmetric leg demand ($\| \text{Pick} - \text{Drop} \| \ge 3$) | Symmetric legs | $\Delta \text{Students} \times \text{Average Fare}$ |
| **13** | **Right-Size (Idle)** | Yard has idle bus matching student count | No matching idle vehicle | $\text{Old Rent} + [(\text{Fuel} + \text{Maint}) \times (1 - \text{BurnRatio})]$ |
| **14** | **Right-Size (Mini)** | Bus $\ge 30$ seats, occupancy $\le 60\%$ | Headroom $<2$; exceeds mini-bus | $\text{Fuel Saving} + (\text{Old Rent} - \text{Mini Rent})$ |
| **15** | **Route Split (Van)** | Big bus $\ge 4$ stops; tail $\ge 2$ students | Saving $<1\%$ route expense; cap $\le 20$ | $\text{Big Bus Fuel Saved} - \text{Van Total Cost}$ |
| **16** | **Tail Walking** | Tail students $2 \le S \le 7$; hub $\le 450\text{m}$ walk | Walk $>450\text{m}$; tail $>7$ students | $\text{Eliminated Tail KM} \times 2 \times D \times R_{var}$ |
| **17** | **Two Mini-Buses** | Big bus $>30$ seats; students $\le 40$; 2 idle vans | $<2$ idle vans in yard | $\text{Big Bus Total Cost} - (\text{Van}_1 + \text{Van}_2 \text{ Cost})$ |
| **18** | **Fare Recalibration** | Avg fare $<$ cost/student; deficit $>0$ | Loss worsens $>10\%$ via attrition | $(\text{Students} - \text{Attrition}) \times \text{NewFare} - \text{OldIncome}$ |
| **19** | **Vendor Rent Audit** | Rent share $>30\%$ of total route expense | Rent $\le 30\%$ fleet benchmark | $\text{Current Rent} - (\text{Total Cost} \times 30\%)$ |
| **20** | **Maint. Bill Audit** | Maintenance share $>15\%$ of total route costs | Maintenance $\le 15\%$ benchmark | $\text{Current Maint} - (\text{Total Cost} \times 15\%)$ |
| **21** | **Subsidy/Withdraw** | Net loss remains after all cards applied | Recoverable via operational cards | Management Policy Decision ($\text{Remaining Deficit}$) |
| **22** | **Verify Data** | Low data confidence (salary, fuel, rent zero) | Data confidence is HIGH | Flags audit list; saving = ₹0 |
| **B1** | **Idle Bus (Bus View)**| Bus has active lease rent but 0 routes | Bus assigned to route | $100\%$ of monthly vendor lease rent |
| **B2** | **Fuel Calib (Bus)** | Bus km/l is below fleet outlier ($\text{Mean} - 1\sigma$) | Bus $\ge$ outlier line | $\text{Gap} \times \text{Median Rate} \times \text{Monthly KM} \div 2$ |
| **B3** | **Mid-Day Charter** | Bus has $>1\text{ hr}$ idle window between trips | Idle gap $<1\text{ hour}$ | $\text{Work Days} \times \text{Vendor Daily Rate} \times S_{idle}$ |

---

*This document is the verified architectural specification for Smart Transport Loss Recovery and Interactive Map Simulation. It reflects the exact logic executed in production.*
