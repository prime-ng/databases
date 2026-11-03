# 04 — Research & Roadmap: making SmartTransport a star feature (2026-10-23)

## 1. What the market does (research summary)

| Who | Notable capability | Source |
|---|---|---|
| Transfinder Routefinder Pro/Plus (US) | Automated route optimisation; **"what-if" scenario analysis** to cut operating cost; schedule exceptions | schoolbusfleet.com, transfinder.com |
| Edulog (US) | Stop assignment restricted by **safety rules** (e.g. no major-road crossing); special-needs checks on ride time, distance and equipment; parent portal | schoolbusfleet.com |
| Tyler Traversa (US) | End-to-end routing + onboard tablet + maintenance cost | schoolbusfleet.com |
| US districts | **Bell-time tiering**: one bus serves 2–4 school runs. Cumberland study: moving one school's tier frees 4 buses (~$400K/yr projected). Litchfield NJ: routes cut 38 → 27 after bell changes | schoolbusfleet.com, cumberlandschools.org |
| Indian players (Entab CampusCare, TRAKOM, SkoolWay, LittleMove, eTechSchoolBus) | GPS live tracking, **RFID boarding**, parent ETA and delay alerts, geofence deviation alerts, fee linkage. "Route planning" is mostly manual or marketing-level | sourceforge.net, entab.in, vendor pages |
| India regulation | **AIS-140**: certified VLTD + **panic button** on school buses; data to the state backend; tamper detection; NavIC | fleetx.io, loconav.com (vendor sources; verify against the MoRTH notification) |
| Research (SBRP) | School Bus Routing Problem = capacitated, time-constrained *open* VRP: capacity, **max ride time**, school time windows, **max walking distance**; stop selection is a separate sub-problem; heuristics such as iterated local search for mixed fleets | redalyc.org, oasis.postech.ac.kr, rhydlewis.eu |

**Positioning insight:** Indian competitors sell *tracking*. US competitors sell *optimisation*. Nobody in the Indian K-12 ERP space sells **optimisation + P&L reasoning + an approval workflow inside the ERP**. SmartTransport's existing LossRecoveryAdvisor already does that P&L reasoning. That is the differentiator; the gaps below are what make it credible.

## 2. Star features to build (ranked by impact ÷ effort)

### ★1 Route Engine v2: background, road-aware, constraint-honouring
SmartTimetable parity; reuses `SmartTimetable/app/Services/Python/PythonRunner.php` + `SolverProcessReaper.php`.
- **Solver:** Python + Google OR-Tools CVRP. The constraints:
  - heterogeneous capacity
  - **max ride time per student**
  - school arrival window per shift
  - optional stops as disjunctions (allows stop merge/drop with a penalty)
  - open routes (start at the driver's home or depot)
  - **locks** ("keep Route 7 as is", "this vehicle stays on this corridor")
- **Distance matrix:** self-hosted **OSRM** on the VPS (India extract), cached per stop pair in a new `tpt_distance_matrix` table. This kills the haversine × 1.3 guess and the public demo-server dependency.
- **Runs as a queued job** with the SmartTimetable live-status modal (progress %, current best km, routes, unplaced students).
- **Objectives the user chooses:** fewest buses · least km · shortest max ride · lowest ₹ cost.

### ★2 Proposal Review & Publish, with rollback
Completes the DDL v2.4 design.
- **Side-by-side map, before vs after:** routes, stops, students moved, Δkm, Δ₹/month, Δmax ride time, routes going loss → profit.
- **Per-item accept/reject:** route by route, not all-or-nothing. Statuses go `Proposed → In-Review → Approved`.
- **Publish:**
  - takes a snapshot into `*_history`
  - promotes the proposal to live tables in one transaction, with an **effective date**
  - re-links student allocations
  - **notifies affected parents** of the new stop and time (Automation/Notification core)
- **Restore** a previous snapshot with one click.

### ★3 Savings Ledger: "SmartTransport saved you ₹X this term"
- Persist every suggestion as a row: rule, entity, predicted ₹ impact, status `open/accepted/dismissed/snoozed`, owner and due date.
- After acceptance, compare 30/60/90-day actual fuel, km and cost with the baseline.
- A dashboard tile shows **₹ saved year to date**. This is the number that sells renewals.
- It also fixes the "suggestions recomputed and forgotten every 10 min" problem: compute nightly, and track the delta.

### ★4 What-if Simulator
The Transfinder pattern, inside the ERP. Clone the live plan into a sandbox proposal, change one lever, and re-run the engine:
- shift/bell time ±15 min (**tiering → bus reuse**)
- remove or add N buses; swap to mini-vans
- fare per km / slab change
- new residential area or admissions batch
- walking-zone radius (e.g. no service under 1 km)

Output: compare cards side by side. This reuses ★1 + ★2 with zero new UI concepts.

### ★5 Learned ETAs and live operations
- Replace the constant 25 km/h with **per-segment, per-time-of-day speeds learned** from `tpt_trip_stop_detail` actuals. The data is already captured.
- **Parent ETA push:** "bus 2 stops away / delayed 8 min" through the parent app.
- **Deviation and delay detection:** geofence + "trip running 15 min behind its learned profile" → transport incharge alert.
- **AIS-140 integration:** ingest the certified VLTD feed (location, panic button, tamper) instead of only phone GPS. A panic alert creates a `tpt_trip_incidents` row and notifies the escalation chain.

### ★6 Stop Placement Optimiser (needs student geocodes)
- **Data gap:** no tenant table holds student home lat/lng; students attach only to stops.
- **Step 1:** geocode student addresses (admission form + bulk geocode + "drop a pin" in the parent app).
- **Step 2:** propose stops that minimise stops and walking distance under a **max walk ≤ X m** limit and **safety rules** (no stop needing a main-road crossing for pre-primary, lit area for the last drop).
- This turns Stopage_Add/Remove/Merge proposals from guesswork into evidence.

### ★7 Admission-time transport quote
At enquiry or admission, enter an address and get:
- nearest stop and walk distance
- route and seat availability
- **fare quote**
- "needs new stop" flag

This links the Admission and Transport modules (a cross-module "wow" in demos) and feeds next year's demand forecast.

### ★8 Daily dynamic plan (Transport "Substitute Management")
Mirrors the timetable substitute feature:
- When a bus breaks down or a driver is absent, suggest a ranked replacement (spare vehicle, a vehicle free between shifts, or merging into the nearest route with spare seats), and notify parents.
- One-way and absent students (from attendance) → skip stops and shorten the day's route.

### ★9 Safety & compliance score (India-specific)
- Per bus and driver score from:
  - overspeed and harsh braking (AIS-140 data)
  - incidents
  - expired documents
  - **female attendant on routes whose last drop is a girl** (a widely followed school-bus safety norm in India; verify the state circular)
  - helper present for pre-primary
- One page for the principal and auditors; export for the RTO or board inspection.

### ★10 Natural-language transport assistant (optional, later)
Example question: "Why is Route 12 losing money and what should I do?" It answers from the Advisor's existing cards and P&L, with links to apply the proposal.

## 3. Phased plan

| Phase | Content | Depends on | Rough size |
|---|---|---|---|
| **0 — Make it safe** | Remove `autoGenerateAllRoutes` (P0-01). Stop the Bangalore defaults (P1-03). Tenancy in the expiry command (P1-04). Generic error messages (P2-01). User FKs → SET NULL (P2-02). Refresh the DDL file (P2-08). | — | 2–3 days |
| **1 — Close the loop** | ★2 review/publish/rollback. Background job + snapshot for the Smart Advisor (P1-01). Persist suggestions → ★3 ledger skeleton. | Phase 0 | 1.5–2 weeks |
| **2 — Real engine** | Self-host OSRM + distance matrix. ★1 OR-Tools engine via PythonRunner. Locks. Live-status modal. | Phase 1 | 2–3 weeks |
| **3 — Differentiators** | ★4 what-if + tiering. ★7 admission quote. ★5 learned ETAs + parent ETA push. | Phase 2 | 2–3 weeks |
| **4 — Field & safety** | ★6 geocoding + stop optimiser. ★8 daily dynamic plan. ★9 safety score + AIS-140 ingest. | Phase 3, plus hardware decisions | 3–4 weeks |
| **Parallel — structure** | P1-06: collapse SmartTransport into an add-on over Transport with its own licence key (P1-07). | Decide before Phase 2 | 1 week |

## 4. Decisions the team needs to take
1. **Fork strategy (P1-06):** collapse SmartTransport into an add-on over Transport, or keep two full modules permanently?
2. **Routing data:** self-host OSRM on the VPS (free, needs ~4–8 GB RAM for India) or a paid API (Google/Mapbox matrix; costs per element)?
3. **Engine language:** Python + OR-Tools (matches SmartTimetable infra) or stay in PHP?
4. **Licensing:** is SmartTransport a paid tier on top of Transport?
5. **Student geocoding:** is collecting home location acceptable to schools and parents (privacy, consent)? ★6 and ★7 depend on it.

## Sources
- [10 options for more efficient school bus routing — School Bus Fleet](https://www.schoolbusfleet.com/articles/10-options-for-more-efficient-school-bus-routing)
- [Software systems offer diverse features — School Bus Fleet](https://www.schoolbusfleet.com/10011125/software-systems-offer-diverse-features)
- [Routefinder Pro — Capterra](https://www.capterra.com.au/software/154923/routefinder-pro)
- [How to optimize the use of transportation tiers — School Bus Fleet](https://www.schoolbusfleet.com/articles/how-to-optimize-the-use-of-transportation-tiers)
- [Cumberland bell times update (PDF)](https://cumberlandschools.org/wp-content/uploads/2026/09/Cumberland-SC-Update-8.27-Bell-Times-Boundary-Mapping-2.pdf)
- [Top school transportation software in India — SourceForge](https://sourceforge.net/software/school-transportation/india/)
- [CampusCare 10X transport module — Entab](https://entab.in/entab-blog-gps-track.html)
- [AIS-140 VLTD guide — Fleetx](https://blog.fleetx.io/blog-vltd-ais-140-vehicle-location-tracking-device-guide/)
- [Why AIS-140 is mandatory — LocoNav](https://loconav.com/blog/ais-140-revamping-indian-transport-sector/)
- [The school bus routing problem: a review — POSTECH](https://oasis.postech.ac.kr/handle/2014.oak/27660)
- [SBRP heuristic study (PDF) — Redalyc](https://www.redalyc.org/pdf/4988/498850180008.pdf)
- [School bus routing, EvoCOP 2021 (PDF) — R. Lewis](https://www.rhydLewis.eu/papers/evocop2021.pdf)
- [OSRM API usage policy — GitHub wiki](https://github.com/Project-OSRM/osrm-backend/wiki/API%20Usage%20Policy)
