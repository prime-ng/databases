# Route Proposal Planner — Comprehensive Architectural & Calculation Specification

> **Document Type:** Senior Management, Operational & Engineering Deep-Dive  
> **Target Audience:** School Principals, Transport Directors, Chief Financial Officers, Senior Lead Engineers  
> **Source File Audited:** `Modules/SmartTransport/app/Services/RouteProposalPlanner.php` (2,154 lines)  
> **Tone:** Highly articulate, mathematically transparent English with practical school fleet examples, database integrity safeguards, and financial formulas.

---

## Table of Contents
1. [Executive Overview: The Automated Route Redesign Engine](#1-executive-overview-the-automated-route-redesign-engine)
2. [Core Architectural Constants & Mathematical Assumptions](#2-core-architectural-constants--mathematical-assumptions)
3. [The 8-Stage Lifecycle: Deep Step-by-Step Breakdown](#3-the-8-stage-lifecycle-deep-step-by-step-breakdown)
   - [Stage 1: Precondition Gate & Capacity Feasibility](#stage-1-precondition-gate--capacity-feasibility)
   - [Stage 2: Student Transport Demand Model (Both vs Pickup vs Drop Split)](#stage-2-student-transport-demand-model-both-vs-pickup-vs-drop-split)
   - [Stage 3: Spatial Filtering & Halt Optimization](#stage-3-spatial-filtering--halt-optimization)
     - 3.1 [Centroid-Based Merge of Nearby Halts (600m Radius)](#31-centroid-based-merge-of-nearby-halts-600m-radius)
     - 3.2 [Safe Walking Zone Suppression (650m Campus Radius)](#32-safe-walking-zone-suppression-650m-campus-radius)
     - 3.3 [Dead Demand Pruning & Inactive Stop Reconnection](#33-dead-demand-pruning--inactive-stop-reconnection)
     - 3.4 [High-Volume Halt Splitting (`Stopage_Split`)](#34-high-volume-halt-splitting-stopage_split)
   - [Stage 4: Capacity-Aware K-Means Clustering & Farthest-Point Seeding](#stage-4-capacity-aware-k-means-clustering--farthest-point-seeding)
   - [Stage 5: Underloaded Route Consolidation & Vehicle Capacity Upgrade](#stage-5-underloaded-route-consolidation--vehicle-capacity-upgrade)
   - [Stage 6: Directional Proximity Sequencing & Detour Pruning](#stage-6-directional-proximity-sequencing--detour-pruning)
   - [Stage 7: Route Assembly, Road Curvature & Schedule Generation](#stage-7-route-assembly-road-curvature--schedule-generation)
   - [Stage 8: Comprehensive Financial P&L Engine](#stage-8-comprehensive-financial-pl-engine)
4. [Relational Classification Codes (Routes, Halts & Students)](#4-relational-classification-codes-routes-halts--students)
5. [Database Integrity & Zero-Orphan Atomic Transaction Safeguards](#5-database-integrity--zero-orphan-atomic-transaction-safeguards)
6. [Complete Conditions & Edge-Case Reference Matrix](#6-complete-conditions--edge-case-reference-matrix)
7. [Post-Proposal Review & Approval Workflow](#7-post-proposal-review--approval-workflow)

---

## 1. Executive Overview: The Automated Route Redesign Engine

The **Route Proposal Planner** (`RouteProposalPlanner.php`) is an automated mathematical route-design engine built into the school ERP transport module. When school administrators run route planning (annually or per term), manual route planning typically leads to:
- Overcrowded buses on some corridors while other buses run half-empty.
- Redundant halts spaced only 100 to 200 metres apart, burning heavy low-gear fuel.
- Inefficient zigzag driving paths where buses double back across arterial roads.
- Unmonitored routes running with fewer than 5 students costing thousands in driver wages.

The planner resolves this by automatically analyzing active student registrations, active fleet capacities, and GPS stop coordinates to construct an optimized draft network.

> [!IMPORTANT]
> **Total Draft Isolation:** Running the planner does **not** alter active live routes, bus timetables, or student pickup points. It writes an isolated draft proposal master (`TptRouteProposalMaster`, status `Auto_Generated`) complete with spatial routes, halt timetables, student seat mappings, and monthly P&L projections for management review.

---

## 2. Core Architectural Constants & Mathematical Assumptions

The planning engine utilizes rigorous spatial and transit constants mirrored from the `LossRecoveryAdvisor` to guarantee operational realism:

| Constant | Value | Plain English Operational Meaning |
|---|---|---|
| `ROAD_FACTOR` | **1.30** | Multiplier applied to straight-line Haversine crow-fly distances. Accounts for a 30% winding curvature overhead found on standard municipal roads. |
| `AVG_SPEED_KPH` | **25.0 km/h** | Assumed average urban school bus transit speed including traffic lights, turns, and speed bumps. |
| `MERGE_RADIUS_KM` | **0.60 km (600m)** | Maximum walking radius within which multiple close stops are merged into one primary anchor halt. |
| `WALK_ZONE_RADIUS_KM` | **0.65 km (650m)** | Campus perimeter radius. Intermediate halts within 650m of school are eliminated to prevent bus gate congestion. |
| `THIN_STOP_WALK_KM` | **0.80 km (800m)** | Maximum acceptable walking distance for students when a low-density detour halt is pruned. |
| `MIN_DETOUR_KM` | **0.30 km (300m)** | Minimum detour distance required before a lateral detour halt is considered for pruning. |
| `MIN_ROUTE_LOAD_RATIO` | **0.20 (20%)** | Utilization threshold. A route carrying less than 20% of its vehicle capacity is flagged as underloaded. |
| `MIN_ROUTE_LOAD_FLOOR` | **5 Students** | Absolute minimum passenger count below which a route is forcibly evaluated for merging. |
| `MERGE_ROUTE_RADIUS_KM` | **3.00 km** | Maximum centroid distance between two separate route clusters that permits them to merge into one bus. |
| `MAX_STOPS_PER_ROUTE` | **15 Stops** | Soft ceiling on intermediate stops to prevent student commute durations from exceeding 60 minutes. |

---

## 3. The 8-Stage Lifecycle: Deep Step-by-Step Breakdown

```
Stage 1: Validation (Shift, Session, Capacity Check)
   │
Stage 2: Demand Model (Student Fare & Leg Allocation)
   │
Stage 3: Spatial Filtering (600m Merge, 650m Campus Zone, Orphan Reconnection)
   │
Stage 4: Spatial Clustering (Farthest-Point Seeds, Capacity K-Means)
   │
Stage 5: Fleet Load Consolidation (Underloaded Route Merging & Vehicle Upgrades)
   │
Stage 6: Transit Sequencing (Farthest-Inward Pickup, Nearest-Outward Drop)
   │
Stage 7: Route Assembly (Distance, Speed, Schedule, WKT Geometry)
   │
Stage 8: Financial Calculation (Income, Fuel, HR Crew Salaries, Vendor Rent)
   │
Atomic Transaction: Save Master, Proposed Routes, Proposed Halts, Allocations
```

---

### Stage 1: Precondition Gate & Capacity Feasibility

Before consuming processing cycles or generating routes, the planner executes strict verification:
1. **Shift Verification:** Validates that `Shift` exists and is active.
2. **Current Academic Session:** Verifies active session ID from `OrganizationAcademicSession`.
3. **Database Proposal Type Codes:** Confirms all 10 required database proposal type codes (`Route_New`, `Route_Merge`, `Route_Split`, `Route_Remove`, `Stopage_Add`, `Stopage_Remove`, `Stopage_Merge`, `Stopage_Split`, `Student_Add`, `Student_Remove`) exist in `tpt_proposal_type`.
4. **Fleet Availability & Capacity Check:**
   $$\text{Total Fleet Capacity} = \sum_{v \in \text{Vehicles}} \max(1, \text{capacity}_v)$$
   $$\text{Direction Demand} = \sum \text{Students Needing Transport in Direction}$$
   $$\text{If } \text{Direction Demand} > \text{Total Fleet Capacity} \implies \mathbf{FATAL\ EXCEPTION}$$

*Real Example:* If Morning Pickup has 480 registered students, but the school's fleet of 10 buses only provides 440 seats total:
$$\implies \text{"Insufficient vehicle capacity for Pickup: 480 students need seats but only 440 are available."}$$
The system halts immediately, alerting the director to lease an additional bus before designing routes.

---

### Stage 2: Student Transport Demand Model (Both vs Pickup vs Drop Split)

Student fees and passenger counts are extracted from active `TptStudentAllocationJnt` records. To maintain financial accuracy, fares are split according to trip direction:

$$\text{Pickup Share} = \begin{cases} 1.0 & \text{if } \text{transport\_use\_type} = \text{'pickup'} \\ 0.0 & \text{if } \text{transport\_use\_type} = \text{'drop'} \\ 0.5 & \text{if } \text{transport\_use\_type} = \text{'both'} \end{cases}$$

$$\text{Drop Share} = \begin{cases} 0.0 & \text{if } \text{transport\_use\_type} = \text{'pickup'} \\ 1.0 & \text{if } \text{transport\_use\_type} = \text{'drop'} \\ 0.5 & \text{if } \text{transport\_use\_type} = \text{'both'} \end{cases}$$

For each stop $S$, the system aggregates:
- $\text{Students}_S = \text{Count of distinct students using stop } S$
- $\text{Income}_S = \sum (\text{Student Fare} \times \text{Direction Share})$
- $\text{Allocations}_S = \text{List of student allocation IDs mapped to stop } S$

---

### Stage 3: Spatial Filtering & Halt Optimization

#### 3.1 Centroid-Based Merge of Nearby Halts (600m Radius)
Stops located within $\le 600\text{ metres}$ of each other are consolidated:
1. Stops are sorted in descending order of student volume ($\text{students}_A \ge \text{students}_B$).
2. The halt with the largest passenger volume is selected as the **Anchor Halt**.
3. All other candidate stops within $600\text{m}$ (calculated via the Haversine equation) are merged into the Anchor.
4. The Anchor inherits all students, fares, and student allocation objects:
   $$\text{Anchor Students} = \sum_{m \in \text{Group}} \text{Students}_m, \quad \text{Anchor Income} = \sum_{m \in \text{Group}} \text{Income}_m$$
5. Merged secondary stops are flagged with code `Stopage_Merge` and stored in the database audit log with their exact walking distance (e.g. `240m walk`).

- **Plain English Example:**  
  *Scenario:* On Palm Avenue, there is "Palm Gate 1" with 8 students (earning ₹14,400/month) and "Palm Gate 3" with 2 students (earning ₹3,600/month) located 320 metres apart.  
  *What Planner Does:* The planner selects "Palm Gate 1" as the Anchor. "Palm Gate 3" is closed and merged into "Palm Gate 1". The combined halt now carries 10 students earning ₹18,000/month. The 2 students from Gate 3 walk 320 metres to board. The bus saves 3 minutes of braking and idling at no loss of revenue.

#### 3.2 Safe Walking Zone Suppression (650m Campus Radius)
Intermediate stops located within $\le 650\text{ metres}$ of the school campus coordinates:
- The stop is removed from the bus driving itinerary.
- Its allocated students and fare income are shifted to the **nearest surviving halt** outside the walk zone.
- Pruning near-campus stops saves up to 15 minutes of bus idling in school-gate traffic jams.
- *Safeguard:* The first departure terminus and final arrival stop are never deleted.

- **Plain English Example:**  
  *Scenario:* "School Staff Quarters Stop" has 3 students and is only 480 metres from the main school entrance.  
  *What Planner Does:* The stop is suppressed from the route. The 3 students are re-allocated to the nearest active neighborhood stop 680m away ("Community Center"), or designated as school walking arrivals. The school bus completely bypasses the school gate traffic queue, cutting 8 minutes off the morning trip schedule.

#### 3.3 Dead Demand Pruning & Inactive Stop Reconnection
- **Zero-Demand Stops:** Any registered stop that currently has 0 allocated students for the given direction is dropped from the route, preventing buses from stopping at empty points.
- **Orphan Demand Reconnection:** If an active student is assigned to a stop that was deactivated or soft-deleted in the master table, the engine searches all active candidates, links the student to the geographically closest active stop, and logs an informational warning.

- **Plain English Example:**  
  *Scenario:* Stop "Old Post Office" had 4 students last academic session, but all 4 graduated, leaving 0 active riders. Separately, student Rohan was mapped to "Sector 9 Park", but that stop was deactivated by administration.  
  *What Planner Does:* The planner drops "Old Post Office" so no bus drives there needlessly. For Rohan, it detects his orphaned status, searches the nearest active stop ("Sector 9 Market", 250m away), places him safely on that bus, and prints a review warning for his parents.

#### 3.4 High-Volume Halt Splitting (`Stopage_Split`)
If an apartment complex or township stop has more students than the largest bus in the fleet can carry ($\text{Students}_S > \text{MaxCapacity}_{\text{fleet}}$):
$$\text{Number of Chunks} = \left\lceil \frac{\text{Students}_S}{\text{MaxCapacity}_{\text{fleet}}} \right\rceil$$
The stop is split into capacity-sized virtual halts (e.g. `City Centre - Group 1`, `City Centre - Group 2`) marked `Stopage_Split`, enabling separate buses to service each cohort without overloading.

- **Plain English Example:**  
  *Scenario:* "Grand Heights Society" has 84 students registered for morning pickup. The largest bus in the school fleet has 50 seats. One bus cannot physically board everyone.  
  *What Planner Does:* The planner calculates $\lceil 84 / 50 \rceil = 2$ groups. It creates "Grand Heights - Group 1" (50 students) assigned to Route 1 (50-seater bus) and "Grand Heights - Group 2" (34 students) assigned to Route 2 (40-seater bus). Both buses arrive at scheduled 10-minute staggered intervals without overloading either vehicle.

---

### Stage 4: Capacity-Aware K-Means Clustering & Farthest-Point Seeding

The clustering algorithm groups stops into separate routes while respecting bus capacities:

```
[School Origin]
       │
       ├── Farthest Stop A (12 km away) ───> Seed Centroid 1
       ├── Farthest from A (10 km away) ───> Seed Centroid 2
       └── Farthest from A & B (8 km)   ───> Seed Centroid 3
```

1. **Route Count Determination:**
   $$\text{Min Routes} = \max\left(1, \left\lceil \frac{\text{Total Students}}{\text{Max Vehicle Capacity}} \right\rceil\right)$$
   $$\text{Route Count} = \min(\text{Candidate Stops Count}, \min(\text{Available Vehicles Count}, \text{Min Routes}))$$
2. **Farthest-Point Sampling (Initial Centroid Seeding):**  
   Rather than dropping initial seeds at random or in a clump near the school:
   - Seed 1 is placed at the stop farthest from the school.
   - Seed 2 is placed at the stop farthest from Seed 1.
   - Seed $k$ is placed at the stop that maximizes the minimum distance to all established seeds:
     $$\max_{p \in \text{Candidates}} \left( \min_{c \in \text{Centroids}} \text{Haversine}(p, c) \right)$$
3. **Iterative Capacity-Constrained K-Means (12 Iterations):**
   - In each iteration, stops are assigned to their nearest seed centroid.
   - If assigning stop $S$ causes a cluster's student count to exceed the assigned bus's seat capacity ($\sum \text{Students} > \text{Capacity}_k$), the stop is reassigned to the next-closest cluster with available headroom.
   - If all clusters are full, the engine dynamically increments the route count ($\text{Route Count} \to \text{Route Count} + 1$), reseeds, and restarts clustering.
   - Centroids are recomputed as student-weighted geographic centres:
     $$\text{Lat}_{new} = \frac{\sum (\text{Lat}_i \times \text{Students}_i)}{\sum \text{Students}_i}, \quad \text{Lng}_{new} = \frac{\sum (\text{Lng}_i \times \text{Students}_i)}{\sum \text{Students}_i}$$

- **Plain English Example:**  
  *Scenario:* A school has 115 morning students across 16 stops, and three buses: Bus 1 (50 seats), Bus 2 (40 seats), and Bus 3 (30 seats). Total capacity is 120 seats.  
  *What Planner Does:* Instead of making random circles, it finds Stop 1 in North Zone (14 km away) as Seed 1, Stop 8 in East Zone (11 km away) as Seed 2, and Stop 12 in South Zone (9 km away) as Seed 3. Over 12 iterations, stops in the North cluster fill Bus 1 to 48 students, East stops fill Bus 2 to 38 students, and South stops fill Bus 3 to 29 students. Every child has a seat, and no bus crosses another bus's territory.

---

### Stage 5: Underloaded Route Consolidation & Vehicle Capacity Upgrade

If an automated route has very low ridership:
$$\text{Minimum Student Threshold} = \max(5, \text{round}(\text{Vehicle Capacity} \times 0.20))$$
*(e.g., a 40-seater bus carrying only 4 students has a threshold of $\max(5, 8) = 8$ students).*

The system searches for a neighbouring route whose centroid is within $\le 3.0\text{ km}$:
1. **Feasibility Check:**
   $$\text{Students}_{\text{combined}} = \text{Students}_{\text{current}} + \text{Students}_{\text{neighbour}}$$
   $$\text{Max Available Capacity} = \max(\text{Capacity}_{\text{current}}, \text{Capacity}_{\text{neighbour}})$$
   $$\text{If } \text{Students}_{\text{combined}} \le \text{Max Available Capacity} \implies \mathbf{MERGE\ APPROVED}$$
2. **Vehicle Capacity Upgrade:**
   If the smaller route had a 30-seater bus and the neighbour had a 40-seater bus, the merged route is automatically assigned the 40-seater bus to guarantee all passengers have seats.
3. **Fleet Efficiency Impact:** One entire vehicle run, driver duty, and bus lease are eliminated.

- **Plain English Example:**  
  *Scenario:* Proposed Route 4 has only 4 students assigned to a 32-seater bus (underloaded threshold is $\max(5, 6) = 6$). Neighboring Route 3 has 28 students assigned to a 42-seater bus, and its stops are only 1.8 km away.  
  *What Planner Does:* Combined load is $4 + 28 = 32$ students, which fits comfortably inside the 42-seater bus ($32 \le 42$). The planner dissolves Route 4, moves its 4 students into Route 3, and assigns the 42-seater bus. The 32-seater bus and its driver are freed, saving the school ₹21,000/month in lease and wages.

---

### Stage 6: Directional Proximity Sequencing & Detour Pruning

#### 6.1 Directional Ordering Heuristic
Buses cannot drive in random stop orders; route direction determines transit sequence:
- **Morning Pickup Direction (Farthest $\to$ Inward):**  
  The route starts at the halt farthest from the school. From that anchor, the bus progresses to the nearest unvisited neighbor that moves progressively closer to the school:
  $$\text{Score} = \text{Distance}(\text{Current}, \text{Next}) + (\text{Distance}(\text{Next}, \text{School}) \times 0.1)$$
  *(The bus sweeps inward, arriving at the school gate fully loaded).*
- **Afternoon Drop Direction (Outward $\to$ Farthest):**  
  The bus departs the school gate, visits the closest intermediate stops first, and terminates at the farthest residential stop:
  $$\text{Score} = \text{Distance}(\text{Current}, \text{Next}) - (\text{Distance}(\text{Next}, \text{School}) \times 0.1)$$

- **Plain English Example:**  
  *Scenario:* On Route 2, Stop A is 12 km from school, Stop B is 7 km, and Stop C is 3 km.  
  *In Morning Pickup:* Bus starts at Stop A at 7:00 AM, drives inward to Stop B at 7:15 AM, picks up Stop C at 7:30 AM, and pulls into the school gate at 7:45 AM.  
  *In Afternoon Drop:* Bus leaves school at 2:15 PM, drops Stop C first at 2:25 PM, drops Stop B at 2:40 PM, and drops Stop A last at 2:55 PM before returning to depot. This eliminates zigzag driving.

#### 6.2 Thin Detour Pruning
If an intermediate stop on the route carries very few passengers ($\le 10\%$ of bus capacity) and introduces a detour of $\ge \max(0.3\text{ km}, \text{Route KM} \times 0.02)$:
- Detour distance is calculated using triangle inequality:
  $$\Delta_{\text{detour}} = \text{Dist}(P_{i-1}, P_i) + \text{Dist}(P_i, P_{i+1}) - \text{Dist}(P_{i-1}, P_{i+1})$$
- If an alternate surviving stop exists within $\le 800\text{ metres}$ walking distance, the detour stop is dropped.
- Students are shifted to the surviving stop, saving fuel and 5–10 minutes of driving.

- **Plain English Example:**  
  *Scenario:* On a 40-seater bus route, Stop 4 ("Rose Villa") has only 2 students, but requires the bus to turn off the main boulevard into a dead-end lane, adding 1.6 km of driving. Stop 5 on the main boulevard is only 400 metres away from Rose Villa.  
  *What Planner Does:* The detour is pruned. The 2 students walk 400m to Stop 5. The bus stays on the main road, saving 1.6 km per trip (83 km/month) and cutting ₹1,900 in monthly diesel expenses.

---

### Stage 7: Route Assembly, Road Curvature & Schedule Generation

1. **Total Route Mileage:**
   $$\text{Total Driving KM} = \left(\sum_{i=1}^{N-1} \text{Haversine}(P_i, P_{i+1})\right) \times \text{ROAD\_FACTOR (1.30)}$$
2. **Timetable Generation:**
   $$\text{Transit Minutes to Stop } i = \text{round}\left(\left(\frac{\text{Cumulative KM}_i}{\text{AVG\_SPEED\_KPH (25)}}\right) \times 60\right) + \text{Stop Index}_i$$
   - `arrival_time` = Scheduled transit minutes.
   - `departure_time` = Scheduled transit minutes $+ 1\text{ minute dwell}$.
3. **Spatial Map Line Geometry:**  
   Constructs standard spatial WKT (Well-Known Text):
   $$\text{LINESTRING}(Lng_1\ Lat_1,\ Lng_2\ Lat_2,\ \dots,\ Lng_{\text{school}}\ Lat_{\text{school}})$$
   This line geometry is saved into `tpt_proposed_routes.route_geometry` for instant rendering on the map interface.

- **Plain English Example:**  
  *Scenario:* A proposed pickup route has 6 stops with a raw crow-fly chain of 15.0 km.  
  *What Planner Does:* It applies the 1.30 road factor: $15.0 \times 1.30 = 19.5\text{ km}$ true road distance. At 25 km/h, transit takes $(19.5 / 25) \times 60 = 47\text{ mins}$, plus 6 stops $\times 1\text{ min} = 53\text{ minutes}$ total trip time. The system automatically sets Stop 1 arrival at 7:00 AM, Stop 2 at 7:11 AM, etc., arriving at school at 7:53 AM.

---

### Stage 8: Comprehensive Financial P&L Engine

For every proposed route, the system calculates full monthly operating economics:

$$\text{Monthly Net Margin} = \text{Monthly Income} - \text{Total Monthly Expense}$$

$$\text{Total Monthly Expense} = \text{Fuel Expense} + \text{Crew Salary} + \text{Maintenance \& Rent Expense}$$

#### 1. Monthly Student Income
$$\text{Monthly Income} = \sum_{s \in \text{Route Stops}} \text{Income}_s$$

#### 2. Fuel Expense
- **Working Days ($D$):** Derived from trailing 30-day driver attendance logs (`tpt_driver_attendance`); fallback is **26 days**.
- **Trips Per Day ($T_d$):** Calculated from active trips; standard is **2.0 trips/day** (morning + return).
- **Vehicle Fuel Cost Per KM ($R_{km}$):** Pulled from vehicle's historical approved fuel logs (`avg_exp_per_km`); benchmark fallback is **₹18.50/km**.
$$\text{Monthly Fuel Expense} = \text{Route Total KM} \times T_d \times D \times R_{km}$$

#### 3. Crew Salary (Driver & Helper)
Directly queries active HR payroll records (`hr_salary_assignment`) linked to the assigned driver and conductor via `tpt_driver_route_vehicle_jnt`:
$$\text{Crew Salary} = \text{Gross Monthly Driver Wage} + \text{Gross Monthly Helper Wage}$$
*(If unlinked in HR, ₹0 is entered and a warning is logged).*

#### 4. Maintenance & Vendor Rent Expense
- **Maintenance:** Sum of approved repair invoices from `tpt_vehicle_maintenance` over the last 90 days divided by 3 (monthly run-rate).
- **Vendor Lease:** Fixed monthly charges from active agreements in `vnd_agreement_items`.

- **Plain English Example:**  
  *Scenario:* Proposed Route 1 has 34 students paying an average fare of ₹1,800/month. The route is 22 km one-way, runs 2 trips/day over 26 working days, and has an assigned bus with ₹19.00/km fuel cost, ₹22,000 driver+helper payroll, and ₹4,500 monthly workshop maintenance.  
  *Calculation by System:*
  - **Monthly Income:** $34 \times ₹1,800 = ₹61,200$
  - **Monthly Mileage:** $22\text{ km} \times 2 \times 26 = 1,144\text{ km}$
  - **Fuel Expense:** $1,144\text{ km} \times ₹19.00 = ₹21,736$
  - **Total Expense:** $₹21,736\text{ (fuel)} + ₹22,000\text{ (crew)} + ₹4,500\text{ (maint)} = ₹48,236$
  - **Net Profit:** $₹61,200 - ₹48,236 = \mathbf{+₹12,964/\text{month}}$  
  Management sees at a glance that Route 1 is self-sustaining and profitable.

#### 3. Crew Salary (Driver & Helper)
Directly queries active HR payroll records (`hr_salary_assignment`) linked to the assigned driver and conductor via `tpt_driver_route_vehicle_jnt`:
$$\text{Crew Salary} = \text{Gross Monthly Driver Wage} + \text{Gross Monthly Helper Wage}$$
*(If unlinked in HR, ₹0 is entered and a warning is logged).*

#### 4. Maintenance & Vendor Rent Expense
- **Maintenance:** Sum of approved repair invoices from `tpt_vehicle_maintenance` over the last 90 days divided by 3 (monthly run-rate).
- **Vendor Lease:** Fixed monthly charges from active agreements in `vnd_agreement_items`.

---

## 4. Relational Classification Codes (Routes, Halts & Students)

To provide transparency during human review, every proposed entity is tagged with an auditable classification code:

### Route Classification Codes (`tpt_proposed_routes.proposal_type`)
| Code | When It Is Applied | Operational Meaning |
|---|---|---|
| **`Route_New`** | No matching historical route ID exists in the stop history. | Brand new route serving a new geographic corridor. |
| **`Route_Merge`** | Stops originate from 2 or more distinct live routes. | Two underutilized live routes consolidated into one bus. |
| **`Route_Split`** | Stops from 1 historical route are divided across 2+ proposed routes. | Overloaded live route divided into two smaller loops. |
| **`Route_Remove`** | A live route has 0 students in the new proposal. | Live route decommissioned and bus released to depot. |

### Stop Classification Codes (`tpt_proposed_pickup_points.proposal_type`)
| Code | When It Is Applied | Operational Meaning |
|---|---|---|
| **`Stopage_Add`** | Stop does not exist on any active live route. | Newly created halt added to transport network. |
| **`Stopage_Merge`** | Stop acts as an anchor absorbing adjacent close stops. | Consolidated central halt. |
| **`Stopage_Split`** | Stop was split into chunks due to exceeding bus capacity. | High-density stop served by multiple scheduled buses. |
| **`Stopage_Remove`** | Stop eliminated due to zero demand, walk zone, or thin detour. | Decommissioned stop; students redirected. |

### Student Allocation Codes (`tpt_proposed_student_route_allocations.proposal_type`)
| Code | When It Is Applied | Operational Meaning |
|---|---|---|
| **`Student_Add`** | Student is assigned to a proposed route or stop. | Active student provided confirmed seat and schedule. |
| **`Student_Remove`** | An active student was unassigned in this shift. | Student flagged for transport withdrawal or transfer. |

---

## 5. Database Integrity & Zero-Orphan Atomic Transaction Safeguards

The entire proposal is executed within an atomic database transaction (`DB::transaction(..., 3)`) with three strict validation checkpoints before committing:

```
[Transaction Start]
   │
   ├── Write Master Header (TptRouteProposalMaster)
   ├── Write Proposed Routes (TptProposedRoute)
   ├── Write Proposed Halts (TptProposedPickupPoint)
   ├── Write Route-Stop Junctions (TptProposedPickupPointRoute)
   ├── Write Student Allocations (TptProposedStudentRouteAllocation)
   │
   ├── Checkpoint 1: Expected Allocations Count == Generated Count?
   │   (If mismatch: ROLLBACK)
   │
   ├── Checkpoint 2: Stored Allocations in DB == In-Memory Allocations?
   │   (If mismatch: ROLLBACK)
   │
   ├── Checkpoint 3: Any Student Allocation with NULL Pickup & NULL Drop?
   │   (If orphans > 0: ROLLBACK)
   │
[Transaction Commit & Return Summary]
```

### The Three Strict Invariants:
1. **No Lost Students:** If 312 students had active allocations in the academic session, exactly 312 student allocation records must be generated. If even 1 student cannot be placed, the transaction rolls back:
   $$\text{"Only 311 of 312 student allocations could be placed on a route. Transaction Aborted."}$$
2. **Persistence Integrity:** The number of database rows inserted into `tpt_proposed_student_route_allocations` must match the in-memory plan count.
3. **No Unrouted Passengers (Zero-Orphan Invariant):** Any allocation record where both `new_pickup_route_id` is null AND `new_drop_route_id` is null triggers an immediate transaction failure.

---

## 6. Complete Conditions & Edge-Case Reference Matrix

| # | System Condition | Code Location | Mathematical Check | System Action Taken |
|---|---|---|---|---|
| **1** | Shift inactive | `generateProposal` | `!$shift->is_active` | Throws `RuntimeException`. Generation halted. |
| **2** | No academic year | `generateProposal` | `$academicYearId <= 0` | Throws `RuntimeException`. Generation halted. |
| **3** | No allocations | `generateProposal` | `$allocations->isEmpty()` | Throws `RuntimeException`. |
| **4** | No vehicles | `generateProposal` | `$vehicles === []` | Throws `RuntimeException`. |
| **5** | Demand $>$ Fleet capacity | `generateProposal` | $\sum \text{Demand} > \sum \text{Capacity}$ | Throws `RuntimeException` with exact seat shortfall. |
| **6** | Missing type codes | `generateProposal` | Missing key in `proposalTypes` | Throws `RuntimeException` to run seeder. |
| **7** | Stop missing GPS | `planDirection` | `$lat === null \|\| $lng === null` | Stop skipped; warning logged with stop name. |
| **8** | Missing school GPS | `resolveSchoolOrigin` | `org->lat === null` | Computes geographic centroid of all stops. |
| **9** | Stops $\le 600\text{m}$ apart | `mergeNearbyCandidates` | $\text{Haversine} \le 0.60\text{ km}$ | Merges into anchor; secondary tagged `Stopage_Merge`. |
| **10** | Stop in campus zone | `applyWalkingZone` | $\text{Dist}(\text{School}) \le 0.65\text{ km}$ | Stop removed; students walked to nearest kept halt. |
| **11** | Zero students at stop | `removeNoDemandCandidates`| $\text{Students} == 0$ | Stop pruned; tagged `Stopage_Remove`. |
| **12** | Inactive stop demand | `attachOrphanDemand` | Stop in `withTrashed()` | Students moved to nearest active stop with walk distance. |
| **13** | Stop $>$ Bus capacity | `splitOversizedCandidates`| $\text{Students} > \text{MaxCapacity}$ | Chunks stop into capacity groups tagged `Stopage_Split`. |
| **14** | Capacity K-Means overflow| `clusterCandidates` | Cluster load $>$ bus seats | Increments route count and restarts clustering. |
| **15** | Underloaded route | `mergeUnderloadedRoutes` | Load $< \max(5, \text{Cap} \times 0.20)$ | Merges into nearest route $\le 3\text{km}$; upgrades bus size. |
| **16** | Underloaded merge fails | `mergeUnderloadedRoutes` | Neighbour routes full | Route preserved; management warning generated. |
| **17** | Thin detour halt | `removeThinDetours` | Detour $\ge 0.3\text{km}$, riders $\le 10\%$ | Prunes detour; students shifted to stop $\le 800\text{m}$ away. |
| **18** | Fuel logs missing | `availableVehicles` | `avg_exp_per_km <= 0` | Uses standard fleet benchmark ₹18.50/km. |
| **19** | Attendance missing | `resolveWorkingDays` | Attendance logs empty | Uses academic standard fallback 26 working days. |
| **20** | Trip logs missing | `resolveTripsPerDay` | Trip logs empty | Uses standard 2.0 trips/day. |
| **21** | Student placement fail | Transaction Checkpoint | $\text{Placed} \ne \text{Expected}$ | Transaction rollback; zero data altered. |
| **22** | Unrouted orphan | Transaction Checkpoint | `new_pickup == null && drop == null` | Transaction rollback; fatal exception. |

---

## 7. Post-Proposal Review & Approval Workflow

```
[Proposal Generated: Status 'Auto_Generated']
                     │
                     ▼
             [Reviewer Audit]
  • Inspect Visual Route Lines & Stops on Map
  • Verify Student Walk Distances (e.g. 150m-400m)
  • Review Financial P&L (Fuel vs Crew vs Income)
                     │
         ┌───────────┴───────────┐
         ▼                       ▼
    [APPROVED]              [REJECTED]
         │                       │
  • Live Routes Updated   • Proposal dismissed
  • Halts Reassigned      • Live data untouched
  • Student Passes Issued
```

1. **Review Stage (`In_Review`):**  
   The transport manager inspects the proposal in the management console. Every route can be reviewed alongside its financial summary (monthly revenue, fuel cost, HR crew salary, net margin).
2. **Approval Stage (`Approved`):**  
   When management clicks **"Approve & Apply"**:
   - Live routes in `sys_routes` are updated.
   - Decommissioned routes are soft-deleted.
   - Live student allocations in `tpt_student_allocation_jnt` are updated to point to the new route IDs and stop IDs.
   - Student ID cards and boarding passes reflect the new timetable.
3. **Rejection Stage (`Rejected`):**  
   The proposal record is archived with reviewer feedback. The existing live transport network continues running without disruption.

---

*This document is the verified architectural specification for `Modules/SmartTransport/app/Services/RouteProposalPlanner.php`.*  
*Maintained in AI Brain: `/home/shailesh/shailesh/ai-brain-daily/RouteProposalPlanner-Overview.md`*
