# Transport Module Enhancement Plan
## Foundation Transport · Standard Transport · Prime Transport

| Field | Value |
|---|---|
| **Document** | Module enhancement and delivery plan |
| **Module family** | Transport (TPT) |
| **Version** | 1.0 — Final Analysis |
| **Date** | 2026-11-01 |
| **Companions** | `01-Consolidated_Requirement_Document.md`, `02-Schema_Evaluation_and_Design.md`, `02-Final_Transport_DDL_v1.0.sql` |
| **Status** | Plan only — no code, schema or live data changed |

---

## 1. Executive summary

### 1.1 The decision

Build **two sellable Transport modules on one foundation**:

| Product | Codebase | Role |
|---|---|---|
| **Foundation Transport** | `Modules/Transport` | The single owner of masters, live network, operations, billing, plan lifecycle and history |
| **Standard Transport** | `Modules/SmartTransport` | Foundation + complete route map + rule-based Advisor + P&L + loss-recovery advice + manual plan builder + comparison + savings ledger. **No AI route generation, no machine-generated proposals.** |
| **Prime Transport** | `Modules/PrimeTransport` | Foundation + auto stop generation + OR-Tools route generation + configurable constraints + proposals + class/date approval + publish/rollback + comparison + advanced billing + ETA/disruption/safety + admission quote |

### 1.2 Why this plan

Today the three modules are not three products; they are **three overlapping copies of one product**:

- SmartTransport is a 343-file fork of Transport; 314 common files have diverged.
- SmartTransport and Transport both write the same `tpt_*` tables, so a bug in one can corrupt the other.
- SmartTransport has a destructive one-click endpoint that can wipe every route, trip and incident in the tenant.
- SmartTransport’s proposal lifecycle stops at “saved”; it cannot review, approve or publish.
- PrimeTransport has its own plan model (`ptr_plans`) that duplicates `tpt_transport_plan`, and its publish path cannot promote proposed stops.
- None of the three has automated PHP tests for money, publish or allocation logic.

The plan fixes the foundation first, then turns each module into a thin, licensed layer over it.

### 1.3 Headline outcomes

| Outcome | Measure |
|---|---|
| One live network | No module other than Foundation writes `tpt_route` / `tpt_pickup_points_route_jnt` / `tpt_student_route_allocation_jnt` / `tpt_driver_route_vehicle_jnt` |
| One plan model | Draft, review, approve, publish, history and rollback use `tpt_transport_plan` + `tpt_plan_*` + `tpt_plan_publication` |
| Safe AI | No engine/Advisor output reaches live tables without a human approval and a snapshot |
| Explainable billing | Every invoice resolves to a plan publication and an allocation history row |
| Sellable tiers | Each module has its own licence key, menu and permission set |
| Testable money paths | Unit/feature tests for fare, proration, fine, P&L, publish, rollback, accounting posting |
| Faster delivery | Shared CRUD is fixed once, not three times |

---

## 2. Current state assessment

### 2.1 Inventory

| Metric | Transport | SmartTransport | PrimeTransport |
|---|---:|---:|---:|
| Files | 368 | 388 | 165 |
| PHP + Blade LOC (approx.) | 70.9K | 89.6K | 18.5K |
| Controllers | 34 | 36 | 9 |
| Models | 35 | 46 | 23 |
| Services | 7 | 13 | 19 (12 top + 7 engine) |
| Policies | 49 | 50 | — (gates) |
| Views | 163 | 175 | 43 |
| Migrations (module-owned) | 2 | 0 | 23 |
| Tests | 0 | 0 | 0 PHP; 7 Python cases |
| Own tables | Shared `tpt_*` | Shared `tpt_*` + proposal/history | `ptr_*` (23) |
| Licence gate | `Transport` | `Transport` (inherits) | `Prime Transport` |
| Route prefix | `/transport` | `/smarttransport` | `/prime-transport` |
| Menu entries | 7 | 8 | 9 |

### 2.2 What each module actually does well

**Transport (Foundation candidate)**
- Broad, working CRUD for vehicles, personnel, shifts, routes, stops, assignments, roster, trips, boarding, attendance, inspection, service, maintenance, fuel, allocation, fees, fines and 11 reports.
- Real operational grain and a child-safety trail (QR/RFID boarding, device registry).
- Mobile APIs already loaded from `routes/api.php`.
- Transport plan master and monthly invoice service exist, though limited.

**SmartTransport (Standard candidate)**
- `SuggestionEngine` — 68 rules across compliance, capacity, cost, fees, punctuality, fuel, crew, safety and parent comms.
- `LossRecoveryAdvisor` — 26 recovery strategies with a zero-harm guard.
- `TransportCostAnalysisService` — route and bus P&L.
- `RouteProposalPlanner` — capacity-aware clustering (8 stages).
- Smart Advisor UI, cost-analysis map, roster drill-downs.

**PrimeTransport (Prime candidate)**
- Async OR-Tools engine (`GeneratePlanJob`, `PtrPythonRunner`, `vrp.py`) with capacity, ride-time, dwell, school-arrival, optional stops and whole-stop vehicle locks.
- Draft plan writer with full children and KPI.
- Review/approve with no self-approval.
- Publish with drift guard, before/after snapshots, supersede, roster rewrite, rollback.
- What-if lab, plan impact, route diff, unserved explanation, trip map.
- Settings registry and seeded advisor/safety rules.

### 2.3 What is broken or missing (the real backlog)

#### P0 — data loss or unsafe

| ID | Module | Issue | Evidence |
|---|---|---|---|
| P0-01 | Smart | `autoGenerateAllRoutes` nulls every allocation, deletes every trip/incident/scheduler, force-deletes every route/assignment, and never re-links students | `SmartTransport/app/Http/Controllers/PickupPointController.php:611-652` |
| P0-02 | Smart | Proposal lifecycle has generate/preview/apply only; no review/approve/publish/restore | `RouteProposalController`; proposal tables |
| P0-03 | Prime | Proposed stops (`HP-*`, `NS-*`) are never promoted; publish refuses every plan that contains them | `PlanPublishService::preflight()`; no writer for `promoted_stop_id` |
| P0-04 | Prime | Stop-level allocation changes are marked `unchanged` when the route id is unchanged, so publish never moves the student | `PlanSolutionWriter::writeAllocations()`; publish filters `change_kind != unchanged` |
| P0-05 | Foundation | Collecting a transport fee can set `std_students.is_active = 0` for the whole ERP | `FeeCollectionController.php:99-106` (audit B1) |
| P0-06 | Foundation | Aadhaar/licence numbers and FCM tokens are plaintext | `tpt_personnel.id_no`, `license_no`, `tpt_attendance_device.pgm_fcm_token` |
| P0-07 | Foundation | Module gate missing/incorrect on some route groups; Smart inherits Transport | Route providers |
| P0-08 | All | No automated tests on money, publish, rollback or allocation | `tests/` empty |

#### P1 — wrong results or broken feature

| ID | Module | Issue |
|---|---|---|
| P1-01 | Foundation | Late fines never apply on web: Carbon 3 signed diff produces negative delay days (B2) |
| P1-02 | Foundation | Allocation import matches by roll number only (B3) |
| P1-03 | Foundation | Web trip start/end saves nothing; mobile writes odometer/fuel 0 (B4/B5) |
| P1-04 | Foundation | New allocation links to the first academic year, not the current one (B6) |
| P1-05 | Foundation | `total_students` counter drifts; capacity check is wrong (B7) |
| P1-06 | Foundation | Trip state not enforced (B8); mobile part payment saved fully paid (B9); “Delayed” uses wrong date (B10); “Approaching” is for the wrong stop (B11); expiry command has no tenant (B12) |
| P1-07 | Foundation | Missing coordinates silently become Bangalore in imports/models |
| P1-08 | Smart | Advisor computes 68 rules inline, caches 10 min, date filter ignored for suggestions, 45 s vs 10 min cache conflict |
| P1-09 | Smart | Distances are haversine × 1.30; stop order is radial, not routed; dead `orderStopsByProximity`; restart can drop stops |
| P1-10 | Smart | Public OSRM demo and unpkg used from the browser |
| P1-11 | Smart | `apply` trusts a client-supplied plan array; preview token is not bound |
| P1-12 | Smart | Advisor roster covers 19 of 68 rules; the rest show a generic route manifest |
| P1-13 | Prime | No class/section scope and no plan `effective_to` |
| P1-14 | Prime | No billing, late/penalty, or accounting integration |
| P1-15 | Prime | No Advisor engine; 8 `ptr_` tables unused |
| P1-16 | Prime | Solver has no profitability/revenue objective and no per-stop time windows |
| P1-17 | Prime | What-if promotion can carry stale drift/levers; no re-check |
| P1-18 | Prime | Payload JSON files accumulate forever; `row_count` is meaningless |

#### P2 — hardening and hygiene

- 150+ raw `$e->getMessage()` leaks to users.
- Mass assignment via `$request->all()` in several controllers.
- User FKs `ON DELETE CASCADE` in proposal migrations.
- Dead models (`TptFeeCollection`), dead controllers (`NewTripController`), dead mobile API (`SmartTransport/routes/mobile_api.php`).
- UI typos (“Stundet”, “Bord Unbord”, “Stopage”).
- Duplicate cron commands (`transport:check-expiries`, `smarttransport:check-expiries`).
- No eager-load strategy; god controllers (`TripController` 800+, `TransportReportController` 1,567).
- No observability (run id, plan id, tenant id correlation).

### 2.4 Fork drift

| Metric | Value |
|---|---:|
| Common relative paths | 342 |
| Byte-identical common files | 28 |
| Modified common files | 314 |
| Common views | 157 |
| Identical views | 14 |
| Smart-only files | 46 |
| Transport-only files | 26 |

Most diffs are namespace/permission/route-prefix rewrites, but some are real fixes that landed in only one fork. This is a permanent correctness risk.

### 2.5 Verdict

| Module | Verdict |
|---|---|
| Transport | Conditionally usable for CRUD; not production-safe until P0/P1 fixes and tests |
| SmartTransport | Not production-ready; destructive endpoint and half-built lifecycle |
| PrimeTransport | Strong prototype; cannot satisfy the brief until stop promotion, class/date, billing, advisor and comparison are built |
| Combined | **Do not add features until the fork is collapsed and the Foundation is hardened** |

---

## 3. Target architecture

### 3.1 Dependency graph

```
                         ┌──────────────────────────────┐
                         │  PRIME TRANSPORT (premium)   │
                         │  Modules/PrimeTransport      │
                         │  ptr_* + tpt_plan_* drafts   │
                         └──────────────▲───────────────┘
                                        │ depends on
                         ┌──────────────┴───────────────┐
                         │  STANDARD TRANSPORT (mid)    │
                         │  Modules/SmartTransport      │
                         │  Advisor/P&L/Map/Compare     │
                         └──────────────▲───────────────┘
                                        │ depends on
                         ┌──────────────┴───────────────┐
                         │  FOUNDATION TRANSPORT (base) │
                         │  Modules/Transport           │
                         │  tpt_* live + plan + billing │
                         └──────────────────────────────┘
```

**Rules**
1. Foundation has no dependency on Standard or Prime.
2. Standard depends on Foundation; it never writes live network tables directly.
3. Prime depends on Foundation; it writes live tables only through Foundation’s `PlanPublishService`.
4. Standard and Prime do not depend on each other.
5. Shared models/services live once in Foundation. Standard/Prime may extend or compose, not copy.

### 3.2 Ownership boundaries

| Concern | Owner | Notes |
|---|---|---|
| Vehicle/personnel/shift/route/stop masters | Foundation | |
| Trip, boarding, attendance, inspection, maintenance, fuel | Foundation | |
| Allocation, fare, billing, accounting | Foundation | |
| Plan draft/review/approve/publish/history/rollback | Foundation | The lifecycle is foundational; every plan needs it |
| Class/date applicability | Foundation | |
| Advisor rule framework and suggestions | Standard | Tables `tpt_adv_*`; Prime reuses |
| Route map, P&L, loss recovery, manual builder, live comparison | Standard | Read/advice layer |
| Student geo, stop generation, route engine, constraints | Prime | `ptr_*` |
| Plan comparison across draft scenarios | Prime (extends Foundation service) | Foundation owns the comparison table |
| ETA, disruptions, safety scores, admission quote | Prime | `ptr_*` |
| Notification delivery | Notification module | Foundation composes; Standard/Prime consume |
| Accounting ledger | Accounting module | Foundation posts via outbox |

### 3.3 Shared kernel (Foundation)

These classes are used by all three modules and must be stable:

| Class | Purpose |
|---|---|
| `TransportPlanService` | Create/clone/validate a plan; status transitions |
| `PlanApplicabilityService` | Class/section/date mapping and overlap lock |
| `PlanDraftService` | Stage routes/stops/allocations/assignments |
| `PlanValidationService` | Pre-submit and pre-publish checks |
| `PlanReviewService` | Submit/approve/reject/comment; no self-approval |
| `PlanPublishService` | Drift guard, snapshot, live writes, history, roster, audit |
| `PlanRollbackService` | Restore snapshot, undo roster, reopen superseded plan |
| `PlanHistoryService` | Archive and query history |
| `PlanRosterService` | Per-date roster generation |
| `PlanSnapshotService` | Self-contained JSON snapshots |
| `PlanComparisonService` | Save/compare metrics |
| `FareService` | Fare precedence and version selection |
| `AllocationService` | Allocation/stop change, capacity, atomic swap |
| `BillingService` | Billing run, invoice, proration |
| `ChargeService` | Late fee/penalty/damage rules and waiver |
| `PaymentService` | Payment, reversal, reconciliation |
| `AccountingPostingService` | Outbox, retry, reconciliation |
| `TripService` | Trip FSM, odometer, approval |
| `BoardingService` | Scan validation, duplicate, event log |
| `InspectionService` | Checklist, failure → service request |
| `MaintenanceService` | Approval → maintenance → vendor payable |
| `FuelService` | Approval, efficiency |
| `ComplianceService` | Document expiry, availability |
| `DataQualityService` | Gaps and confidence |
| `TransportEventService` | Domain events/outbox |
| `TenantJobRunner` | Tenant-scoped queued jobs |

### 3.4 Licensing, menu and permissions

| Product | Module key | Menu | Permission prefix |
|---|---|---|---|
| Foundation | `Transport` | Transport | `tenant.transport.*` |
| Standard | `SmartTransport` (display: Standard Transport) | Standard Transport | `tenant.smarttransport.*` |
| Prime | `PrimeTransport` (display: Prime Transport) | Prime Transport | `tenant.prime-transport.*` |

**Rules**
- Each add-on has its own `glb_modules` row and menu mapping.
- Standard/Prime routes require **both** their own module key and Foundation (dependency check).
- Hide duplicate foundation menus when Standard/Prime is active; show one entry per product.
- Default role grants go through seeders, not migrations.
- A tenant can buy Foundation + Standard, Foundation + Prime, or all three.

**Naming recommendation:** keep folder namespaces (`Transport`, `SmartTransport`, `PrimeTransport`) to avoid a risky rename. Change product/display names and menu labels only. If a folder rename is mandatory, do it after Phase 1 with a dedicated namespace migration and a full regression pass.

---

## 4. Module 1 — Transport (Foundation)

### 4.1 Role

Foundation is the **only** owner of the live transport network and the **only** writer of live plan changes. It is not a “dumb CRUD” module: it owns the plan lifecycle, billing and history that Standard and Prime depend on.

### 4.2 Keep

- All master CRUD (vehicle, personnel, shift, route, stop, route-stop, device, fine).
- Roster, trip, stop detail, incident, boarding, attendance.
- Inspection → service → maintenance, fuel.
- Allocation, fee master, collection, fine detail.
- 11 reports and dashboard.
- Mobile APIs.
- Transport plan master (extend, don’t replace).
- Vendor integration points.

### 4.3 Remove / retire

| Remove | Reason | Replacement |
|---|---|---|
| `TptFeeCollection` model (`tpt_fee_collection`) | Table does not exist; dead code | `tpt_transport_payment` |
| `TptFeatureStore`, `TptModelRecommendations`, `TptRecommendationHistory`, `TptStudentEventLog` stubs | No tables, no usage | `tpt_adv_*`, `tpt_adv_savings_ledger`, `tpt_student_event_log` |
| Duplicate `CheckTransportExpiries` schedule in Smart | Two identical crons | One Foundation command |
| Bangalore coordinate defaults | Wrong geography | NULL + `Pending` + data-quality queue |
| Direct live writes from Smart/Prime | Fork corruption | `PlanPublishService` |
| `autoGenerateAllRoutes` (Smart) | Destructive | Delete route + method; generation only through plans |

### 4.4 Add — Foundation capabilities

#### A. Plan lifecycle (the biggest addition)

| Capability | Detail |
|---|---|
| Plan create/clone | Clone live network or start empty; copy children as `Unchanged` |
| Draft editor | Routes, stops, stops-on-route, allocations, bus/crew, fares |
| Validation | ≥2 stops/route, geocoded stops, bus/crew present, capacity, walk, ride, shift window, unserved reasons |
| Submit/review/approve/reject | Permissioned, no self-approval, comments, audit |
| Class/date applicability | `tpt_transport_plan_class_jnt` + shift join; overlap lock |
| Publish | Drift guard, preflight, snapshot before/after, live writes, history, roster, notifications |
| Schedule | Future effective date, hourly publisher |
| Rollback | After-publish drift check, roster undo, snapshot restore |
| History | Publication-keyed immutable copies; “network as of date” |
| Comparison | Saved comparison of any plans |

#### B. Billing and accounting

| Capability | Detail |
|---|---|
| Fare master | Versioned by plan/route/stop/class/direction |
| Billing run | Idempotent, queued, progress |
| Invoice | Regular, late fee, penalty, adjustment, credit note |
| Charge | Separate record with grace/cap/waiver |
| Payment | Full/part, modes, cheque processing, reversal |
| Accounting outbox | Idempotent posting, retry, visible failures |
| Plan/publication id | On every invoice, charge and payment |

#### C. Data integrity and safety

| Capability | Detail |
|---|---|
| Missing coordinate policy | NULL + `Pending`; exclude from generation |
| Odometer policy | NULL, not 0; validate start/end; flag trip |
| Capacity | Count live allocations; no drifting counter |
| Allocation import | Admission number or class+section+roll+current session |
| Fee safety | Never deactivate `std_students`; transport-only restriction |
| Tenant-scoped jobs | Every command iterates tenants |
| PII | Encrypted casts, hash lookup, masking, access log |
| Error handling | User-safe messages + reference id |
| Audit | Every sensitive action |
| Data-quality panel | Gaps with links |

#### D. Operational additions

- GPS ingestion (`tpt_gps_trip_log`, `tpt_gps_alerts`).
- Document/licence expiry alerts with notifications.
- Domain events/outbox.
- Bulk imports/exports with error reports.
- Notification status write-back.
- Vendor usage/payable idempotency.
- Real parent notification hand-off.

### 4.5 Services to create/refactor

| Service | Action |
|---|---|
| `TransportPlanService` | New |
| `PlanApplicabilityService` | New |
| `PlanDraftService` | New |
| `PlanValidationService` | New |
| `PlanReviewService` | Move/generalize from Prime |
| `PlanPublishService` | Move/generalize from Prime |
| `PlanRollbackService` | Extract from Prime |
| `PlanHistoryService` | New |
| `PlanRosterService` | Move/generalize from Prime |
| `PlanSnapshotService` | Extract from Prime |
| `PlanComparisonService` | New |
| `FareService` | New |
| `AllocationService` | Extract from controller |
| `BillingService` | New |
| `ChargeService` | New |
| `PaymentService` | New |
| `AccountingPostingService` | New |
| `TripService` | Extract from `TripController`/`MobileTripService` |
| `BoardingService` | Extract; implement scan validation |
| `InspectionService` | Extract |
| `MaintenanceService` | Extract; vendor payable |
| `FuelService` | Extract |
| `ComplianceService` | Implement expiry/availability |
| `DataQualityService` | New |
| `TransportEventService` | New |
| `TenantJobRunner` | New |

### 4.6 Controllers and UI

| Area | Change |
|---|---|
| Masters | Keep; add plan type, depot, document, fare master |
| Plan lifecycle | New pages: Plans, Draft editor, Review, Publish, History, Rollback |
| Billing | New invoice/charge/payment screens; keep legacy fee screens behind a flag |
| Allocation | Add plan/date scope, stop-change request, capacity panel |
| Dashboard | Add plan status, data quality, unposted accounting, expiring documents |
| Data quality | New page with fix links |
| Reports | Keep 11; add network-as-of-date, billing reconciliation, plan history |
| Mobile | Keep; add current-plan and ETA-ready endpoints |

### 4.7 Foundation backlog

#### P0 (must ship before any school depends on it)

| # | Item | Requirement | Acceptance |
|---:|---|---|---|
| F-01 | Remove fee → student deactivation | BR-TPT-049 | Paying a fee never changes `std_students.is_active` |
| F-02 | Fix signed delay/fine calculation | BR-TPT-050 | Web and mobile produce the same fine for the same dates |
| F-03 | Fix allocation import matching | BR-TPT-048 | Duplicate rolls in different classes import correctly |
| F-04 | Fix web/mobile trip start/end persistence | FND-012 | Status, times, odometer, fuel saved; end ≥ start |
| F-05 | Fix allocation session selection | FND-015 | Uses current session; clear error if none |
| F-06 | Replace drifting seat counter | FND-015 | Capacity from live allocations |
| F-07 | Stop Bangalore defaults | FND-006 | Missing coordinates NULL + Pending |
| F-08 | Enforce trip state machine | FND-012 | No end-before-start, no stop events on closed trip |
| F-09 | Fix mobile part payment | FND-029 | Part payment stays PartiallyPaid |
| F-10 | Fix “Delayed” date and “Approaching” stop | FND-013/021 | Correct date and next stop |
| F-11 | Tenant-scope expiry command + notify | FND-038 | Runs once per tenant; sends alert |
| F-12 | Encrypt PII + FCM | BR-TPT-021 | Ciphertext at rest; masked UI |
| F-13 | Module gate on every route group | BR-TPT-022 | 403 without module |
| F-14 | Remove raw exception messages | FND-033 | User-safe message + reference |
| F-15 | Add tests for fare/fine/trip/allocation | FND-027..029 | CI green |
| F-16 | Plan lifecycle MVP | FND-022..026 | Draft → approve → publish → history on a staging tenant |
| F-17 | Billing invoice/charge/payment MVP | FND-027..030 | Routine + separate late fee + accounting posting |
| F-18 | History writer on publish | FND-025 | Old plan in history; invoice resolves to publication |
| F-19 | Class/date applicability | FND-002 | Overlap blocked under lock |
| F-20 | Data quality gate | FND-034 | Missing coords/fares/odometer listed and blocking where required |

#### P1

| # | Item | Requirement |
|---:|---|---|
| F-21 | Schedule publish command | FND-024 |
| F-22 | Rollback + roster undo | FND-025 |
| F-23 | Plan comparison table + UI | STD-008, PRM-009 |
| F-24 | Domain events/outbox | FND-040 |
| F-25 | GPS ingest + alerts | FND-037 |
| F-26 | Compliance documents normalized | FND-004/005 |
| F-27 | Document expiry notifications | FND-038 |
| F-28 | Billing report + reconciliation | FND-031 |
| F-29 | Bulk import/export error report | FND-035 |
| F-30 | Vendor usage/payable idempotency | FND-036 |

#### P2

- Partition high-volume logs.
- Multi-currency readiness.
- Advanced audit export.
- Mobile offline scan queue.
- Localisation.

---

## 5. Module 2 — SmartTransport (Standard Transport)

### 5.1 Role

Standard is the **mid tier**: the full operational product plus a complete route map, deterministic Advisor and financial reasoning. It does **not** generate routes or create machine proposals.

### 5.2 Keep (the crown jewels)

| Asset | Action |
|---|---|
| `SuggestionEngine` (68 rules) | Refactor into rule classes; persist results; move thresholds to settings |
| `LossRecoveryAdvisor` (26 strategies) | Keep logic; split god class; expose as recommendations |
| `TransportCostAnalysisService` | Keep; harden; label estimates |
| `RouteProposalPlanner` | **Do not keep in Standard**; move optional parts to Prime or retire |
| Smart Advisor UI | Keep; add lifecycle/settings/savings |
| Cost-analysis map | Keep; replace public OSRM/Leaflet with self-hosted stack |
| Roster drill-down | Keep; cover all rules or hide unsupported action |
| P&L / profitability advisor | Keep; add confidence and plan scope |

### 5.3 Remove

| Remove | Reason |
|---|---|
| All duplicated CRUD controllers/models/views (≈300 files) | Foundation owns them |
| `autoGenerateAllRoutes` | Destructive |
| Route generation + proposal apply | Prime only |
| Proposal tables/models/actions | Prime only |
| Proposal Type master | Prime only |
| `RouteProposalPlanner` | Prime only (or retire) |
| Duplicate mobile API/services | Foundation owns mobile |
| Duplicate `CheckTransportExpiries` | Foundation owns |
| Smart namespace on shared models | Use Foundation models |
| Public OSRM/unpkg calls | Self-hosted maps |

### 5.4 Add

#### A. Persisted Advisor

| Capability | Detail |
|---|---|
| Rule framework | `AdvisorRule` interface, registry, context preload |
| Background run | Nightly + “Refresh now”, queued, progress |
| Persistence | `tpt_adv_runs`, `tpt_adv_suggestions`, outcomes |
| Dedupe/lifecycle | Fingerprint, open/accepted/dismissed/snoozed/resolved/expired |
| Settings | Per-rule enabled/severity/thresholds |
| Explainability | Problem, action, benefit, calculation trace, confidence |
| Rule coverage | All 68 rules; no generic fallback |

#### B. Complete route path on map

| Capability | Detail |
|---|---|
| Full path | School → all stops → school/end, pickup and drop |
| Real geometry | OSRM road path when available; estimated label otherwise |
| Self-hosted | MapLibre + PMTiles + OSRM; no public tile/router |
| Interactions | Stop popup, students, fare, time, warnings |
| Multi-route | Show all routes of a shift/plan |
| Warnings | Missing coordinate, zig-zag, long ride, unsafe stop |

#### C. Manual plan builder

| Capability | Detail |
|---|---|
| Clone live | Full copy as Unchanged |
| Edit | Drag stops, add/remove route/stop, change bus/crew, move student, edit fare |
| Live warnings | Capacity, walk, ride, shift window |
| Submit/review | Foundation lifecycle |
| No AI | Every change is human-made |

#### D. Comparison and savings

| Capability | Detail |
|---|---|
| Compare | Live vs manual draft; 2–N plans |
| Metrics | Students, routes, buses, km, cost, income, margin, ride, walk, unserved |
| Save/export | Named comparison, PDF/Excel |
| Savings ledger | Predicted vs measured, 30/60/90 days |
| Dashboard | ₹ saved YTD (measured) + pipeline (predicted) |

#### E. Route health and data confidence

- Long commute, zig-zag, thin detour, unsafe stop, missing helper, missing inspection, expired document.
- Data confidence panel (coordinates, fares, odometer, salary, fuel, approvals).
- Estimated vs measured labels.

### 5.5 Services to create/refactor

| Service | Action |
|---|---|
| `Advisor\RuleRegistry` | New |
| `Advisor\AdvisorContext` | New |
| `Advisor\AdvisorRunner` | New (queued) |
| `Advisor\Rules\*` | 68 rule classes |
| `Advisor\SuggestionService` | New |
| `Advisor\SavingsLedgerService` | New |
| `PnlService` | Refactor `TransportCostAnalysisService` |
| `RecommendationService` | Split `LossRecoveryAdvisor` |
| `RouteMapService` | New server-side payload |
| `RouteHealthService` | New |
| `ManualPlanBuilderService` | New (uses Foundation staging) |
| `PlanComparisonService` | Use Foundation service |
| `DataConfidenceService` | New |

### 5.6 Controllers and UI

| Menu | Tabs |
|---|---|
| Standard Transport Dashboard | KPIs, plan status, alerts |
| Transport Masters | Read-only/redirect to Foundation |
| Operations | Redirect to Foundation (trips, boarding, maintenance) |
| Route Map | All routes, route detail, stop detail, warnings |
| Smart Advisor | All suggestions, by family, my actions, settings |
| Cost & P&L | Route P&L, bus P&L, student cost |
| Plan Builder | Clone, draft editor, validation, submit |
| Compare | Plan comparison, maps, export |
| Savings | Ledger, dashboard |
| Reports | Foundation reports + profitability/health/data confidence |

Remove “Route Auto Generation” and “Proposal Type” menus entirely.

### 5.7 Standard backlog

#### P0

| # | Item | Requirement | Acceptance |
|---:|---|---|---|
| S-01 | Remove destructive endpoint | P0-01 | Route/method gone; regression test proves no wipe |
| S-02 | Collapse fork: depend on Foundation | Architecture | Smart has no duplicated CRUD; shared models used |
| S-03 | Own licence key/menu | BR-STD-020 | Tenant without Smart key does not see Standard menu |
| S-04 | Persisted Advisor framework | STD-003 | Page <1 s from stored suggestions |
| S-05 | Port all 68 rules | STD-004 | Every rule has code, threshold, test |
| S-06 | Rule settings | STD-011 | Threshold change takes effect next run |
| S-07 | Suggestion lifecycle | STD-012 | Accept/dismiss/snooze/resolve audited |
| S-08 | Complete route map | STD-001 | Full path, all stops, self-hosted assets |
| S-09 | P&L hardening | STD-005 | Both split 50/50; approved costs only; confidence |
| S-10 | Loss-recovery advice | STD-006/007 | Transfer/merge/split/cluster with zero-harm |
| S-11 | Manual plan builder | STD-009 | Clone/edit/submit/publish |
| S-12 | Plan comparison | STD-008 | 2–N plans, metrics, maps, save/export |
| S-13 | Savings ledger | STD-010 | Predicted/measured separated |
| S-14 | Remove public OSRM/unpkg | STD-001 | No browser call to public map/router |
| S-15 | Tests | STD-004/005/006 | Rule/P&L/zero-harm tests green |

#### P1

| # | Item | Requirement |
|---:|---|---|
| S-16 | Route health alerts | STD-013 |
| S-17 | Standard reports | STD-014 |
| S-18 | Estimated vs measured labels | STD-015 |
| S-19 | Read-only what-if | STD-016 |
| S-20 | Demand/capacity heatmaps | STD-017 |
| S-21 | Communication insights | STD-018 |
| S-22 | Multi-plan overview | STD-019 |
| S-23 | Advisor roster coverage | STD-003 |
| S-24 | Data confidence report | STD-014 |

#### P2

- Standard mobile APIs.
- OpenAPI docs.
- Advanced heatmaps.
- Advisor simulation.

---

## 6. Module 3 — PrimeTransport (Prime Transport)

### 6.1 Role

Prime is the **premium tier**: it generates stops and routes, proves them against school constraints, compares plans, and takes an approved plan safely to production with billing/history.

### 6.2 Keep

| Asset | Action |
|---|---|
| OR-Tools engine (`vrp.py`) | Extend constraints/objective; keep PHP↔Python boundary |
| `GeneratePlanJob` + `PtrPythonRunner` + progress | Keep; harden queue/observability |
| `PlanPayloadBuilder` | Keep; add profitability/time windows/class scope |
| `PlanSolutionWriter` | Keep; fix change-kind and stop promotion |
| `PlanPublishService` / `PlanRosterService` / snapshots | Move/generalize into Foundation; Prime calls it |
| `PlanReviewService` | Move to Foundation; keep Prime approval UI |
| Drift guard/rollback | Move to Foundation |
| What-if lab | Keep; fix promotion/drift |
| Plan impact/route diff/unserved | Keep |
| Trip map | Keep |
| Student geo | Keep; add consent/status |
| Distance matrix | Keep; add OSRM/time bands |
| P&L | Keep; share with Standard |

### 6.3 Fix (before adding)

| # | Fix | Acceptance |
|---:|---|---|
| X-01 | Promote proposed stops at publish | `HP-*`/`NS-*` become `tpt_pickup_points`; `promoted_stop_id` set; plan publishes |
| X-02 | Propagate stop-level allocation changes | A student whose stop/time changes is moved even if route id is unchanged |
| X-03 | Unify plan model | Prime writes `tpt_transport_plan` + `tpt_plan_*`; `ptr_plans` retired |
| X-04 | Add class/section + `effective_to` | Approval requires scope; overlap blocked |
| X-05 | Add billing/accounting | Invoice/charge/payment/accounting outbox |
| X-06 | Add PHP tests | Publish/rollback/drift/stop promotion/class overlap |
| X-07 | Remove/Soap the 8 unused tables or implement them | No dead schema |
| X-08 | Fix payload file retention | Prune per run/tenant |
| X-09 | Fix `row_count` and rollback restore | Correct counts; recreate deleted rows or report |
| X-10 | Fix what-if promotion drift | Re-check hash; clear stale levers |
| X-11 | Add observability | run id, plan id, tenant id, stage, duration |
| X-12 | Add queue fairness/reaper | Large tenant does not starve others |

### 6.4 Add

#### A. Automatic stop generation (Condition 1)

| Capability | Detail |
|---|---|
| Input | Consented student geo, existing stops, school point |
| Reuse | Existing safe stop within `near_stop_m` |
| Cluster | Density/radius clustering |
| Place | Safe centroid, not building/private plot |
| Walk | Hard max walk by age band |
| Merge/split | Merge close clusters; split > largest bus |
| Safety | Crossing/lit/shelter/pre-primary rules |
| Output | Candidates + optional draft plan + map + CSV |
| Review | Accept/reject per candidate |
| Never | Write live stop without plan approval |

#### B. Automatic route generation (Condition 2)

| Capability | Detail |
|---|---|
| Solver | OR-Tools CVRP with time windows |
| Capacity | Heterogeneous fleet, optional standing buffer |
| Max ride | Per age band, hard |
| Arrival | School deadline minus buffer, hard |
| Walk | Enforced in stop assignment and re-checked |
| Shift overlap | Vehicle not double-booked; turnaround |
| Optional stops | Disjunction + penalty |
| Locks | Route/vehicle/stop/student |
| Objectives | Fewest buses, least km, least cost, shortest max ride, minimal change, composite |
| Profitability | Revenue/cost/margin objective and per-route P&L |
| Output | Draft plan, allocations, unserved reasons, constraint proof |
| Time limit | Configurable; best feasible + gap |
| Rounds | Shared-stop retry for unserved |

#### C. Constraints and settings (Condition 2.4)

- Per-school and per-plan hard/soft constraints.
- Constraint snapshot stored with the plan.
- Infeasibility names the binding constraint.
- Templates for Junior Summer/Senior Winter/Sports.
- See the 70-key configuration catalogue in the requirement document.

#### D. Comparison (Condition 3)

- Any number of draft/live plans.
- Metrics: students, unserved, routes, stops, buses, km, cost, income, margin, ride, walk, safety, change count.
- Baseline selection, best/worst highlight.
- Up to 3 synchronized maps.
- Save/export.
- Promote a scenario explicitly.

#### E. Proposal lifecycle (Condition 4)

- Draft/InReview/Approved/Scheduled/Published/Superseded/Rejected/Cancelled/Archived/RolledBack.
- No self-approval; append-only audit.
- Only Draft editable.
- No partial publish.
- Published/Superseded/RolledBack/Archived never hard-deleted.
- Every endpoint permissioned.

#### F. Class/date approval (Condition 5)

- Approver selects classes/sections and date range.
- Overlap blocked with the conflicting plan named.
- Section override; priority only with permission/reason.
- Current view resolves one plan per student.
- Schedule for future date.

#### G. Publish + history (Conditions 6–7)

- Promote new stops.
- Insert/update live routes, route-stops, assignments, allocations.
- Archive old plan to history with publication id and effective_to.
- Rewrite roster for touched routes/future dates only.
- Never touch trips/boarding/incidents/fees.
- Notify parents/crew.
- Rollback with drift check and snapshot.

#### H. Multi-plan, seasonal, billing (Condition 8)

- Concurrent Junior/Senior/Sports/Staff/Event plans.
- Seasonal Winter/Summer plans with scheduled switch.
- Billable/non-billable per plan; billing mode.
- Separate late fee/penalty invoices and accounting vouchers.
- Plan/publication id on every invoice.
- Revenue by plan/class/route.

#### I. Advisor + optimization (Condition 8.1)

- Reuse Standard’s rule framework.
- Prime can turn advice into a draft plan (“Apply as plan”).
- Zero-harm guard.
- Savings ledger measures outcome.

#### J. Advanced Prime features

- What-if lab and scenario comparison.
- Locks/partial regeneration.
- ETA live + parent alerts + learned speeds.
- Disruption re-plan (date-only overrides).
- Safety scores (driver/vehicle/route) + PDF.
- Admission quote.
- Plan KPI history and publish audit.

### 6.5 Services to create/refactor

| Service | Action |
|---|---|
| `StudentGeoService` | Refactor `StudentGeoGenerator`; consent/status |
| `StopGenerationService` | New: cluster, place, merge/split, safety |
| `StopPlacementPolicy` | New: safe centroid rules |
| `RouteGenerationService` | New: orchestrate payload → solver → writer |
| `ConstraintService` | New: hard/soft, snapshot, feasibility explanation |
| `ProfitabilityService` | New: fare/cost/margin objective and KPIs |
| `PlanPayloadBuilder` | Extend: class scope, time windows, revenue, locks |
| `PlanSolutionWriter` | Refactor to Foundation `tpt_plan_*` |
| `DistanceMatrixService` | Extend: OSRM batching, time bands, fallback |
| `SpeedLearningService` | New: `ptr_segment_speeds` |
| `EtaService` | New: `ptr_eta_live`, alerts |
| `DisruptionService` | New: ranked options, one-day override |
| `SafetyScoreService` | New: driver/vehicle/route |
| `AdmissionQuoteService` | New |
| `WhatIfService` | New/refactor |
| `PlanPublishService` | Delegate to Foundation; keep Prime-specific notifications |
| `PlanComparisonService` | Extend Foundation with draft plans |
| `EngineRunService` | New: queue, progress, cancel, reaper |
| `PythonRunner` | Harden: timeout, payload retention, version check |

### 6.6 Jobs and commands

| Job/command | Purpose |
|---|---|
| `GeneratePlanJob` | Route generation |
| `GenerateStopsJob` | Stop generation |
| `RunAdvisorJob` | Advisor (shared with Standard) |
| `SpeedLearnJob` | Nightly segment speeds |
| `RecalculateEtaJob` | On GPS/stop events |
| `SafetyScoreJob` | Nightly scores |
| `PublishScheduledPlans` | Hourly publish |
| `PruneEnginePayloads` | Retention |
| `SolverProcessReaper` | Orphan runs |
| `TenantBillingRunJob` | Foundation billing |

### 6.7 Python engine changes

| Change | Detail |
|---|---|
| Time windows | Per-stop earliest/latest to model arrival window and traffic |
| Multi-shift | One model or coordinated runs with turnaround |
| Profit objective | Revenue per student/stop minus distance/fixed cost |
| Optional stops | Disjunction penalty from settings |
| Route locks | Route-level and ordered-stop locks, not only vehicle pinning |
| Max route duration/km | Hard constraints |
| Multi-depot/start | Depot/driver home as optional start |
| Output | Constraint-proof block: each hard constraint, satisfied/violated, slack |
| Tests | Pytest for each constraint, objective, lock, infeasible case |
| Version check | Preflight OR-Tools/Python version |

### 6.8 Prime backlog

#### P0

| # | Item | Requirement | Acceptance |
|---:|---|---|---|
| P-01 | Promote proposed stops | PRM-011 | Plan with `HP-*`/`NS-*` publishes; stop created once |
| P-02 | Fix stop-level allocation propagation | PRM-011 | Changed stop/time moves the student |
| P-03 | Unify plan model | PRM-008 | Prime uses `tpt_transport_plan` + `tpt_plan_*` |
| P-04 | Class/section + date range | PRM-010 | Approval requires scope; overlap blocked |
| P-05 | Publish/history writer | PRM-012 | Old plan in history; invoice resolves |
| P-06 | Auto stop generation | PRM-002/003 | Candidates with walk/safety; no live write |
| P-07 | Route generation constraints | PRM-004/005 | Max ride/walk/arrival/capacity/locks enforced |
| P-08 | Profitability objective | PRM-006 | Margin KPI and route P&L |
| P-09 | Plan comparison | PRM-009 | 2–N plans, all metrics, maps, save/export |
| P-10 | Billing/accounting | PRM-016..018 | Separate late/penalty invoice + posting |
| P-11 | PHP tests | — | Publish/rollback/drift/stop promotion/overlap |
| P-12 | Remove/implement dead tables | — | No unused `ptr_` table |
| P-13 | Queue/observability/reaper | PRM-032/033 | Progress, cancel, dead-letter, runbook |

#### P1

| # | Item | Requirement |
|---:|---|---|
| P-14 | Advisor engine + apply-as-plan | PRM-019 |
| P-15 | Savings ledger measurement | PRM-029 |
| P-16 | What-if lab | PRM-020 |
| P-17 | Locks/partial regeneration | PRM-021 |
| P-18 | Scheduled publish | PRM-024 |
| P-19 | ETA + parent alerts | PRM-025 |
| P-20 | Disruption re-plan | PRM-026 |
| P-21 | Safety scores | PRM-027 |
| P-22 | Admission quote | PRM-028 |
| P-23 | Prime reports | PRM-035 |
| P-24 | Data quality gates | PRM-034 |
| P-25 | Engine settings UI | PRM-030 |

#### P2

- Learned time-band matrix.
- Multi-depot.
- What-if 3-way compare.
- Natural-language advisor.
- AIS-140 certified feed.

---

## 7. Cross-cutting workstreams

### 7.1 Schema consolidation

| Step | Output |
|---|---|
| 1 | Approve `02-Final_Transport_DDL_v1.0.sql` |
| 2 | Create additive migrations in Foundation/Prime |
| 3 | Backfill scripts with reconciliation counts |
| 4 | Dual-write for one release |
| 5 | Cut over reads/writes |
| 6 | Rename legacy tables to `zz_legacy_*` |
| 7 | Drop after retention |

### 7.2 Billing and accounting

- Fare master + versioning.
- Billing run + invoice + charge + payment.
- Late fee/penalty separate.
- Accounting outbox + reconciliation.
- Plan/publication id on every money row.
- Cutover from legacy fee tables.
- Finance UAT with real school data.

### 7.3 Maps and distance

- Self-host OSRM (regional extract).
- MapLibre + PMTiles self-hosted.
- Distance matrix cache.
- Estimated vs measured labels.
- No public tile/router in production.
- Map performance for 100+ routes.

### 7.4 Jobs, queues and observability

- Per-tenant job payload and tenancy boot.
- Fair queues/priority.
- Progress polling and cancel.
- Dead-letter view.
- Correlation id on every log.
- Runbooks: queue restart, stuck solver, OSRM down, accounting down.
- Payload retention.

### 7.5 Security, tenancy and privacy

- Module gate per product.
- Permission per action; no bare `true` authorize.
- FormRequest validation; no `$all()`.
- PII encryption/masking.
- Student geo consent and retention.
- Rate limits on scan/GPS.
- User-safe errors.
- Audit trail.
- Tenant isolation tests.

### 7.6 Testing

| Layer | Coverage |
|---|---|
| Unit | Fare, proration, fine, P&L, zero-harm, capacity, walk, overlap |
| Feature | Plan lifecycle, publish, rollback, drift, history, billing idempotency, payment reversal, accounting retry |
| Integration | Notification, Accounting, Vendor, StudentProfile |
| Python | Each solver constraint, objective, lock, infeasible case |
| Performance | 250 routes, 5,000 students, 100 vehicles |
| Security | Tenant isolation, authorization, PII |
| UAT | School transport manager + accountant + principal |

### 7.7 Documentation and change management

- One-page “publish a plan” guide.
- Parent “what changed” notice template.
- Finance “how billing works” guide.
- Admin “data quality” checklist.
- API/OpenAPI docs.
- Runbooks.
- Training videos for transport managers.

---

## 8. Phased roadmap

Estimates assume a small team (1 backend, 1 frontend, 1 QA, part-time DevOps/BA). Solo effort is longer.

### Phase 0 — Safety and truth (2 weeks)

**Goal:** stop data loss and wrong money/trip data; establish a test baseline.

| Deliverable | Module |
|---|---|
| Delete `autoGenerateAllRoutes` + route | Smart |
| Fix B1–B12 | Foundation |
| Stop Bangalore defaults | Foundation/Smart |
| Encrypt PII/FCM | Foundation |
| Module gate on all route groups | All |
| User-safe errors | All |
| One expiry command with tenancy | Foundation |
| Tests for money/trip/allocation | Foundation |
| Freeze new feature work in duplicated CRUD | All |

**Exit:** no destructive endpoint; money/trip tests green; a school can collect a fee without deactivating a student.

### Phase 1 — Foundation plan + billing (3 weeks)

**Goal:** Foundation owns one plan model, publish, history and plan-aware billing.

| Deliverable | Requirement |
|---|---|
| Plan type/plan/class/shift/rule tables | FND-001..003 |
| Draft staging + validation | FND-022 |
| Review/approve | FND-023 |
| Publish/history/rollback | FND-024..026 |
| Fare master + billing run + invoice + charge + payment | FND-009, 027..029 |
| Accounting outbox | FND-030 |
| Class/date overlap lock | FND-002 |
| Current views | FND-026 |
| Data quality panel | FND-034 |
| Plan lifecycle UI | — |
| Migration scripts + reconciliation | — |

**Exit:** on a staging tenant, create a plan for classes 1–5, approve, publish, bill, change plan, publish, and resolve the old invoice to history.

### Phase 2 — Standard add-on (2.5 weeks)

**Goal:** Standard becomes a thin, licensed add-on with a persisted Advisor and complete map.

| Deliverable | Requirement |
|---|---|
| Collapse fork; remove duplicated CRUD | Architecture |
| Own module key/menu | BR-STD-020 |
| Advisor framework + 68 rules | STD-003/004 |
| Advisor settings/lifecycle | STD-011/012 |
| Complete route map (self-hosted) | STD-001/002 |
| P&L + loss recovery | STD-005/006/007 |
| Manual plan builder | STD-009 |
| Comparison | STD-008 |
| Savings ledger | STD-010 |
| Tests | — |

**Exit:** Standard has no CRUD duplication, no destructive endpoint, no public map dependency, and its Advisor page opens from stored suggestions.

### Phase 3 — Prime core (3.5 weeks)

**Goal:** Prime generates stops/routes under constraints, compares plans, and publishes with class/date and history.

| Deliverable | Requirement |
|---|---|
| Unify Prime plan model | PRM-008 |
| Stop promotion + stop-level propagation | PRM-011 |
| Auto stop generation | PRM-002/003 |
| Constraint engine + profitability | PRM-004/005/006 |
| Background runs/progress/reaper | PRM-007 |
| Class/date approval | PRM-010 |
| Comparison | PRM-009 |
| Publish/history/rollback integration | PRM-011/012/022/023 |
| Billing integration | PRM-016..018 |
| Tests | — |

**Exit:** a 480-student, 10-bus school generates a plan that meets max ride, max walk, arrival, capacity and profit targets; approves it for classes 1–5; publishes; sees history; bills; rolls back.

### Phase 4 — Prime advanced (3 weeks)

**Goal:** close the loop with advice, ETA, disruptions, safety and quotes.

| Deliverable | Requirement |
|---|---|
| Advisor + apply-as-plan | PRM-019 |
| Savings ledger measurement | PRM-029 |
| What-if + locks | PRM-020/021 |
| Scheduled publish | PRM-024 |
| ETA + parent alerts + learned speeds | PRM-025 |
| Disruption re-plan | PRM-026 |
| Safety scores | PRM-027 |
| Admission quote | PRM-028 |
| Reports | PRM-035 |

**Exit:** a vehicle-down drill produces ranked options and a one-day override; a parent gets an ETA; a safety PDF exports; a suggestion is measured 30 days later.

### Phase 5 — Hardening and launch (2 weeks)

| Deliverable |
|---|
| Load/performance tests |
| Security/tenancy penetration tests |
| Finance reconciliation |
| UAT with 2–3 schools |
| Runbooks and training |
| Legacy table rename/retention |
| Menu cleanup and deprecation notices |
| Go/no-go review |

**Total:** ~16 weeks with a small team; ~24+ weeks solo. Phase 0–1 are non-negotiable before any new Standard/Prime feature.

---

## 9. Backlog summary by priority

### P0 (must)

| Area | Count | Examples |
|---|---:|---|
| Foundation data safety | 11 | B1–B12, PII, module gate |
| Foundation plan/billing | 10 | Plan lifecycle, publish, history, invoice, charge, accounting |
| Standard collapse | 6 | Remove fork, destructive endpoint, licence, persisted Advisor, map, P&L |
| Prime core | 13 | Stop promotion, stop propagation, unified plan, class/date, stop/route generation, comparison, billing |
| Testing | 3 | Money, publish, solver |

### P1 (should)

Foundation schedule/rollback/events/GPS/compliance; Standard health/reports/what-if/heatmaps; Prime advisor/ledger/what-if/locks/ETA/disruption/safety/quote.

### P2 (later)

Partitioning, multi-currency, mobile offline, natural-language advisor, AIS-140, advanced heatmaps.

---

## 10. Risks and mitigations

| # | Risk | Likelihood | Impact | Mitigation |
|---:|---|---|---|---|
| 1 | Data migration corrupts live allocations/billing | Medium | High | Additive schema, dual-write, reconciliation counts, staging rehearsal, rollback plan |
| 2 | Fork collapse breaks a working screen | High | Medium | Strangler pattern: redirect duplicate menus to Foundation, delete only after parity tests |
| 3 | Prime solver infeasible on real data | High | High | Constraint proof, unserved reasons, time limit, fallback, pilot with 2 schools |
| 4 | OSRM/OR-Tools infrastructure unavailable | Medium | High | Self-host with runbook, haversine fallback labelled, preflight version check |
| 5 | Student geo consent/privacy objection | Medium | High | Consent gate, role-scoped access, retention, no home pins in Standard |
| 6 | Billing/accounting mismatch | Medium | High | Outbox, reconciliation report, finance UAT, reversal not edit |
| 7 | Plan overlap causes wrong student plan | Medium | High | Class/date uniqueness under row lock, current-view tests |
| 8 | Parents not informed of stop/time change | Medium | High | Publish notification as a required step, retry, report |
| 9 | Scope creep (three products at once) | High | High | Phase gates, feature flags, P0-only Phase 0–1 |
| 10 | No tests on money/publish | High | High | Test-first for Phases 0–1; CI gate |
| 11 | Queue starvation/large tenant | Medium | Medium | Fair queues, per-tenant limits, reaper, progress |
| 12 | Legacy proposal/fee data left behind | Medium | Medium | Explicit mapping, reconciliation, archive not drop |
| 13 | SmartTransport users lose familiar screens | Medium | Medium | Redirects, release notes, training, dual menu for one release |
| 14 | Permission/menu misconfiguration | Medium | Medium | Seeders, permission tests, tenant smoke test |
| 15 | Solver output trusted without review | Low | High | No auto-publish, human approval, zero-harm guard, drift guard |

---

## 11. Definition of done

### Foundation

- [ ] One plan model; no proposal/ptr plan duplication.
- [ ] Publish is the only writer of live network tables; architecture test enforces it.
- [ ] Every publish is atomic, drift-guarded, snapshotted and audited.
- [ ] History reconstructs any date; old invoices resolve to publication and allocation.
- [ ] Billing run is idempotent; late fee/penalty are separate; accounting posting retries.
- [ ] No fee action can deactivate a student in the ERP.
- [ ] Missing coordinates/fares/odometer are flagged, not guessed.
- [ ] Tenant isolation and PII tests pass.
- [ ] Money/trip/allocation tests green.

### Standard

- [ ] No duplicated CRUD; depends on Foundation.
- [ ] Own licence key/menu.
- [ ] Advisor runs in background, persists, dedupes, resolves.
- [ ] All 68 rules have code, threshold and test.
- [ ] Complete route path on a self-hosted map.
- [ ] Manual plan builder and comparison work end to end.
- [ ] Savings ledger separates predicted and measured.
- [ ] No public OSRM/unpkg dependency.

### Prime

- [ ] Auto stop generation produces candidates with walk/safety and never writes live.
- [ ] Route generation enforces max ride, max walk, arrival, capacity, shift overlap and locks.
- [ ] Profitability objective and per-route P&L.
- [ ] Plans are class/date scoped; overlap blocked.
- [ ] Proposed stops promote; stop-level changes propagate.
- [ ] Publish/rollback/history work with billing.
- [ ] Comparison covers all required metrics.
- [ ] Advisor apply-as-plan and ledger measurement.
- [ ] ETA/disruption/safety/quote work or are explicitly deferred behind flags.
- [ ] Python and PHP tests green; load test at 250 routes.

### Product

- [ ] Foundation, Standard and Prime can be sold and licensed separately.
- [ ] Menus show one product entry per purchased tier; no duplicate “Smart X” confusion.
- [ ] A school can run Junior and Senior plans concurrently, switch seasonally, and bill separately.
- [ ] A transport manager can publish a plan without engineering help.
- [ ] A principal can see evidence: map, KPI diff, savings, safety, history.

---

## 12. First 30 / 60 / 90 days

### First 30 days

1. Approve the requirement document and target schema.
2. Delete the destructive endpoint; freeze new feature work in duplicated CRUD.
3. Fix B1–B12 and the Bangalore default.
4. Add the module gate and PII encryption.
5. Stand up the test harness for money/trip/allocation.
6. Create the additive schema for plans, class/date, history and billing.
7. Pilot the plan lifecycle on one staging tenant.

### First 60 days

1. Ship Foundation plan lifecycle + billing/accounting MVP.
2. Convert SmartTransport to an add-on: remove duplicate CRUD, add licence key.
3. Persist the Advisor and port the 68 rules.
4. Build the self-hosted route map.
5. Build the manual plan builder and comparison.
6. Start Prime stop-generation and constraint engine.

### First 90 days

1. Ship Prime stop generation + route generation with constraints/profitability.
2. Ship class/date approval, publish/history, comparison.
3. Add late/penalty billing and accounting.
4. Run a 480-student pilot; measure max ride, walk, cost and margin.
5. Publish the first real plan with rollback rehearsal.
6. Decide whether to schedule ETA/disruption/safety for the next release.

---

## 13. Immediate next actions (this week)

| # | Action | Owner | Output |
|---:|---|---|---|
| 1 | Review and approve the consolidated requirement document | Product/BA | Signed scope |
| 2 | Review the final DDL on a clean tenant DB | DB architect | DDL validation report |
| 3 | Remove `autoGenerateAllRoutes` | Backend | PR + regression test |
| 4 | Fix B1/B2 (fee deactivation, signed fine) | Backend | PR + tests |
| 5 | Fix Bangalore defaults + import | Backend | PR + tests |
| 6 | Add module gate + PII encryption | Backend/Security | PR + tests |
| 7 | Create the plan lifecycle migration set | DB/Backend | Additive migrations |
| 8 | Stand up OSRM + MapLibre staging | DevOps | Working map stack |
| 9 | Build the fixture school dataset | QA/BA | 500 students, 90 stops, 12 buses |
| 10 | Write the publish/rollback test plan | QA | Test cases |

---

*End of enhancement plan.*
