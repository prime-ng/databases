# Transport Module — Consolidated Requirement Document
## Foundation Transport · Standard Transport (SmartTransport) · Prime Transport

| Field | Value |
|---|---|
| **Document** | Consolidated Requirement Document (CRD) |
| **Module family** | Transport (TPT) |
| **Version** | 2.0 — Final Analysis |
| **Date** | 2026-11-01 |
| **Status** | Analysis complete — for architecture and build planning |
| **Prepared for** | Prime-AI Product & Engineering |
| **Supersedes** | TPT_FRD_2026-06-29 (v1.0) for Transport; SmartTransport design notes; PrimeTransport Tpt_Analysis notes |
| **Output folder** | `2-Prime-Ai_V2/9-Enhanced_Modules/Transport/Final_Analysis/` |

---

## Contents

- [0. How to read this document](#0-how-to-read-this-document)
- [1. Executive summary](#1-executive-summary)
- [2. Scope](#2-scope)
- [3. Actors and access](#3-actors-and-access)
- [4. Domain model and terminology](#4-domain-model-and-terminology)
- [5. Functional requirements](#5-functional-requirements)
  - [5.1 Foundation requirements](#51-foundation-requirements)
  - [5.2 Standard requirements (SmartTransport)](#52-standard-requirements-smarttransport)
  - [5.3 Prime requirements (PrimeTransport)](#53-prime-requirements-primetransport)
- [6. The eight Prime conditions — detailed interpretation](#6-the-eight-prime-conditions--detailed-interpretation)
- [7. Business rules register](#7-business-rules-register)
- [8. Workflows](#8-workflows)
- [9. Data requirements](#9-data-requirements)
- [10. Reporting and analytics](#10-reporting-and-analytics)
- [11. Configuration catalogue](#11-configuration-catalogue)
- [12. Non-functional requirements](#12-non-functional-requirements)
- [13. Foundation / Standard / Prime mapping](#13-foundation--standard--prime-mapping)
- [14. Conflict resolution register](#14-conflict-resolution-register)
- [15. Additional suggestions](#15-additional-suggestions)
- [16. Open decisions](#16-open-decisions)
- [17. Traceability matrix](#17-traceability-matrix)
- [18. Glossary](#18-glossary)

---

## 0. How to read this document

### 0.1 Source hierarchy

This document reconciles six kinds of input. Where they disagree, the higher row wins, and the conflict is recorded in **Section 14**.

| Rank | Source | What it contributes |
|---:|---|---|
| 1 | This brief (user's 8 Prime conditions, 2026-11-01) | Target behaviour and product split |
| 2 | `4-Requirement_Module_wise/0-FRD_Documents/TPT_FRD_2026-06-29.md` | Canonical foundation requirements, 26 business rules, 11 reports |
| 3 | `prime_testing/Doc_Analysis/4-Module_Requirement/Transport_v2/` (40 screen specs) | Screen-level fields, validations and operational rules |
| 4 | DDL files — `Transport_DDL_v2.3.sql`, `Transport_DDL_v2.7.sql`, `PrimeTransport_DDL_v1.0.sql` | Physical data model and known schema intent |
| 5 | Live code — `Modules/Transport`, `Modules/SmartTransport`, `Modules/PrimeTransport` | What is actually built today |
| 6 | Design and audit notes — SmartTransport Design, PrimeTransport `Tpt_Analysis`, `16-PRIMETRANSPORT-HOW-IT-WORKS.md` | Algorithms, calculations, known defects, roadmap |

### 0.2 Requirement IDs

| Prefix | Layer | Meaning |
|---|---|---|
| `FND-` | Foundation | Shared masters, network, operations, finance, plan lifecycle, history |
| `STD-` | Standard | SmartTransport features that are **not** AI route generation or proposal approval |
| `PRM-` | Prime | PrimeTransport engine, proposals, comparison, advanced billing, ETA, safety |
| `BR-TPT-` | Business rule | Foundation rules (continues the existing FRD numbering) |
| `BR-STD-` | Business rule | Standard-tier rules |
| `BR-PRM-` | Business rule | Prime-tier rules |
| `CFG-` | Configuration | School-settable parameter |
| `RPT-` | Report | Reporting requirement |

**Priority:** P0 = must ship before a school depends on the feature; P1 = should ship in the target release; P2 = later / optional.

### 0.3 Product model (the target of this document)

```
┌────────────────────────────────────────────────────────────────────┐
│ PRIME TRANSPORT  (premium)                                         │
│ Auto stop generation · OR-Tools route engine · draft proposals     │
│ plan comparison · class/date applicability · publish/rollback      │
│ ETA · disruptions · safety scores · admission quotes               │
└──────────────────────────────▲─────────────────────────────────────┘
                               │ depends on
┌──────────────────────────────┴─────────────────────────────────────┐
│ STANDARD TRANSPORT  (SmartTransport — mid tier)                    │
│ Complete route map · rule-based Advisor · cost/P&L · loss-recovery │
│ advice · manual plan builder · live-plan comparison · savings log  │
│ NO AI route generation · NO machine-generated proposals            │
└──────────────────────────────▲─────────────────────────────────────┘
                               │ depends on
┌──────────────────────────────┴─────────────────────────────────────┐
│ FOUNDATION TRANSPORT  (base — Modules/Transport)                   │
│ Masters · routes/stops · vehicles/crew · roster · trips · boarding │
│ inspection/maintenance/fuel · allocation · billing · plan lifecycle│
│ history · reports · tenancy · audit                                │
└────────────────────────────────────────────────────────────────────┘
```

The Foundation is the single owner of the live network. Standard and Prime are **add-ons**, not forks. Both read and write through Foundation services; Prime’s AI output is staged in drafts until a human publishes it.

---

## 1. Executive summary

### 1.1 The problem the module solves

An Indian K-12 school runs a fleet of buses and vans twice a day. It must answer, every day:

1. **Safety** — is the right child on the right bus, at the right stop, and did they get off?
2. **Compliance** — is every vehicle certificate and driver licence valid, and is every crew member verified?
3. **Cost** — which routes lose money, and what is the cheapest safe way to fix them?
4. **Capacity** — which routes are overcrowded, which buses run half empty, and where should a new stop be?
5. **Money** — who has paid, who is late, what fine applies, and is the ledger posted?
6. **Evidence** — can the school prove all of the above to a parent, a board or an RTO auditor?

The Transport family digitises all six.

### 1.2 The three generations

| Generation | Module | What it added | What it got right | What it did not finish |
|---|---|---|---|---|
| **TPT v1** | `Modules/Transport` | Vehicle/route/stop/crew masters, roster, trips, QR/RFID boarding, inspection→service→maintenance, fuel, allocation, monthly fees and fines, 11 reports | The operational backbone and the child-safety trail | Automation gaps, vendor/accounting hand-offs, no plan lifecycle, several P0 audit issues |
| **TPT v2** | `Modules/SmartTransport` | Complete route map, 68-rule Advisor, 26 loss-recovery strategies, route/vehicle P&L, capacity-aware route planner, proposal tables | Diagnostic intelligence and financial reasoning | Proposals cannot be approved or published; distances are straight-line guesses; heavy maths runs inline; 155 files forked and drifted |
| **TPT v3** | `Modules/PrimeTransport` | Student geo, OR-Tools route engine, async runs, draft plans, review/approve, publish/rollback, drift guard, snapshots, P&L, Advisor persistence | A safe generate → review → publish → rollback loop | Auto stop generation is partial; class/date applicability and billing history are not first-class; several `ptr_` tables are unused; plan model duplicates `tpt_transport_plan` |

### 1.3 What this document decides

1. **Two sellable modules, one foundation.** Foundation is the base; Standard and Prime are licensed add-ons with their own keys and menus.
2. **One live network.** `tpt_*` is the only source of truth for what buses actually run.
3. **One plan model.** A plan is a versioned, class-and-date-scoped network. Drafts are staged; publishing moves them into the live tables and archives the replaced version.
4. **AI never writes live data.** Every engine or Advisor output becomes a draft plan or a suggestion. A human approves; the system publishes inside one transaction with a snapshot.
5. **Billing is plan-aware.** Every invoice and charge records the plan publication it belongs to, so a mid-term plan change does not corrupt billing history.
6. **No fork.** Standard and Prime contain only their own controllers, services, views and tables. Shared CRUD and models live once in Foundation.

### 1.4 Readiness statement

As of the 2026-10-23 audit and the 2026-10-27 PrimeTransport measurement:

- Foundation is **operationally usable but not production-safe**: one P0 (`dd($e)` / error-leak class), plaintext Aadhaar/licence, missing module gate in some route groups, no automated tests, and 12 known data-integrity bugs (B1–B12).
- Standard is **not production-ready**: a destructive one-click endpoint exists, proposals cannot complete their lifecycle, and routing uses a public demo server.
- Prime is **functionally impressive but incomplete for this brief**: publish/rollback works, but auto stop generation, class/date applicability, plan comparison and billing history are not yet first-class.

The enhancement plan in `03-Transport_Module_Enhancement_Plan.md` sequences the fixes and builds.

---

## 2. Scope

### 2.1 In scope

| Area | Foundation | Standard | Prime |
|---|:---:|:---:|:---:|
| Vehicle, personnel, shift, plan-type masters | ● | ○ | ○ |
| Route, stop, route-stop sequencing, geometry | ● | ○ | ○ |
| Driver/vehicle assignment, daily roster | ● | ○ | ○ |
| Trip lifecycle, stop events, incidents | ● | ○ | ○ |
| QR/RFID boarding, driver attendance, devices | ● | ○ | ○ |
| Inspection → service → maintenance, fuel | ● | ○ | ○ |
| Student allocation and stop change | ● | ○ | ○ |
| Fee master, invoice, late fee/penalty, payment, accounting posting | ● | ○ | ○ |
| Plan draft, review, approve, schedule, publish, history, rollback | ● | ○ | ○ |
| Class/section + date-range applicability | ● | ○ | ○ |
| Reports and dashboard (11 foundation reports) | ● | ○ | ○ |
| Complete route path on map |  | ● | ● |
| Rule-based Advisor and persisted suggestions |  | ● | ● |
| Cost/P&L per route, bus and student |  | ● | ● |
| Loss-recovery advice (stop transfer, merge, split, cluster) |  | ● | ● |
| Manual plan builder and live-plan comparison |  | ● | ● |
| Savings ledger (predicted and measured) |  | ● | ● |
| Student geocoding and consent |  |  | ● |
| Auto stop generation from lat/lng |  |  | ● |
| Auto route generation (OR-Tools) |  |  | ● |
| Configurable generation constraints |  |  | ● |
| Multi-plan / multi-scenario comparison |  |  | ● |
| Proposal lifecycle and class/date approval |  |  | ● |
| Seasonal and multi-plan scheduling |  |  | ● |
| Billable/non-billable plan billing |  |  | ● |
| Separate late/penalty billing and accounting |  |  | ● |
| ETA, disruptions, safety scores, admission quotes |  |  | ● |

● = owned / primary  ○ = consumed read-only

### 2.2 Out of scope

1. **Accounting ledger internals** — Foundation posts vouchers to Accounting through an outbox; it does not own the chart of accounts.
2. **Payment gateway internals** — Foundation records payments and reconciliation; gateways are owned by Payment.
3. **Message delivery** — Foundation composes and logs notification events; Notification owns push/SMS/email/WhatsApp delivery.
4. **Parent/student app UI** — ParentPortal and StudentPortal own the screens; Transport owns the APIs and data.
5. **Hardware procurement and AIS-140 certification** — Transport ingests certified device feeds; it does not certify devices.
6. **Payroll processing** — HR owns salary; Prime reads salary for P&L only.
7. **Admission workflow** — Admission owns enquiries; Prime offers a transport-quote widget/API.
8. **GPS hardware firmware** — Transport ingests positions and alerts.
9. **Legal advice on RTO/board rules** — rules are configurable; the school remains responsible for compliance.

### 2.3 Assumptions

- MySQL 8.0.32+ (spatial support, JSON, CTEs, window functions).
- One tenant database per school; all `tpt_*`/`ptr_*` tables live in the tenant DB.
- Academic sessions, classes, sections, students and users already exist in `sch_*`, `std_*`, `sys_*`.
- A school may run multiple shifts, multiple plans and multiple class groups in the same session.
- The school can provide student home coordinates with consent (Prime only).
- A self-hosted OSRM and open-source map stack are acceptable (no paid map API).
- Python 3.11/3.12 with OR-Tools is available for Prime; PHP owns the database.

### 2.4 Dependencies

| Dependency | Owner | Used by |
|---|---|---|
| `std_students`, `std_student_academic_sessions`, `std_student_addresses` | StudentProfile | All tiers |
| `sch_classes`, `sch_sections`, `sch_class_section_jnt` | SchoolSetup | Plan applicability |
| `sch_org_academic_sessions_jnt`, `sch_organizations` | SchoolSetup | Session and school origin |
| `sys_users`, `sys_dropdown_table`, `sys_activity_logs` | Core | Auth, lookups, audit |
| `vnd_vendors`, `vnd_agreements`, `vnd_usage_logs`, `vnd_vendor_bill_due_for_payment` | Vendor | Leased vehicles, usage, maintenance payable |
| `hrs_salary_assignments`, `sch_employees` | HR | Prime P&L crew cost |
| Accounting voucher API | Accounting | Billing and expense posting |
| Notification/Automation | Notification | Parent and crew alerts |
| OSRM + MapLibre + Protomaps | Infrastructure | Prime/Standard maps and distances |
| Python + OR-Tools | Infrastructure | Prime solver |

---

## 3. Actors and access

### 3.1 Actor definitions

| Actor | Who | Relationship to Transport |
|---|---|---|
| School Admin | System administrator | Full configuration; can act as approver if permitted |
| Principal / Approver | Senior school authority | Approves/rejects plans and high-value exceptions |
| Transport Manager / Incharge | Runs the fleet | Primary daily user; plans, rosters, publishes, approves operational exceptions |
| Route Planner | Transport analyst | Builds and compares plans; cannot approve own plan |
| Accountant / Finance | Finance staff | Fare master, billing runs, fines, collections, reconciliation, accounting posting |
| Driver | Bus driver | Own trips, attendance, inspection, fuel, stop events, incidents |
| Helper / Attendant | Bus attendant | Attendance, boarding scans, stop events, incidents |
| Class Teacher / Coordinator | Academic staff | Read-only allocation and boarding view |
| Parent / Guardian | Fee payer and guardian | Own child’s allocation, boarding, ETA, stop-change request, invoices |
| Student | Rider | Own allocation and boarding history (age-appropriate) |
| Auditor / Board | Internal or external | Read-only compliance, safety and savings evidence |
| System | Scheduled jobs, engine, queues | Expiry alerts, billing runs, advisor runs, plan generation, publish scheduler |

### 3.2 Role-feature matrix

| Feature | Admin | Principal | Transport Mgr | Planner | Accountant | Driver/Helper | Teacher | Parent |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Masters & configuration | Full | View | Full | View | View | None | None | None |
| Route/stop/plan build | Full | View | Full | Full | None | None | None | None |
| Plan submit | Full | — | Full | Full | None | None | None | None |
| Plan approve | Full | Full | Optional* | No | None | None | None | None |
| Plan publish/rollback | Full | Optional* | Full | No | None | None | None | None |
| Roster & trips | Full | View | Full | View | None | Execute own | None | None |
| Boarding scan | Full | View | Full | View | None | Scan | View | Own child |
| Inspection/service/fuel | Full | View | Full/Approve | None | View | Submit | None | None |
| Allocation | Full | View | Full | View | View | None | View | Request change |
| Fee master / billing | Full | View | View | None | Full | None | None | Own invoices |
| Reports | Full | Full | Full | Full | Finance | Own | Allocation | Own child |
| Advisor suggestions | Full | View | Full | Full | Finance | None | None | None |
| Engine generation | Full | View | Full | Full | None | None | None | None |
| Safety scores | Full | Full | Full | View | None | Own | None | None |

*Configurable approval chain: 1-step (Transport Manager) or 2-step (Transport Manager → Principal). Default for Prime: 2-step; Standard: 1-step.

---

## 4. Domain model and terminology

### 4.1 Core concepts

| Term | Meaning |
|---|---|
| **Transport Plan** | A versioned, class-and-date-scoped configuration of the whole network: routes, stops, route-stop links, vehicle/crew assignments, student allocations, fares, billing flags and constraints. A plan is the unit of approval, publishing and rollback. |
| **Live / Current Network** | The rows in `tpt_route`, `tpt_pickup_points`, `tpt_pickup_points_route_jnt`, `tpt_driver_route_vehicle_jnt`, `tpt_student_route_allocation_jnt` that carry the currently published plan. Current views read only these. |
| **Draft Plan** | A plan that is not live. Its children are staged in `tpt_plan_*`; the live tables are untouched. |
| **Proposal** | A draft plan created by an engine, an Advisor action or a disruption fix. In this document “proposal” and “draft plan” are the same object; the UI may call it a proposal. |
| **Publication** | The event/version that records a plan going live. `tpt_plan_publication` anchors all history rows and billing references. |
| **History** | The archived copy of the plan that a publication replaced. History rows are immutable and are used for billing, disputes and audits. |
| **Applicability** | The mapping of a plan to classes/sections and an effective date range. Two plans for the same class/date range cannot both be active. |
| **Shift** | An operating window with a school-arrival target and a departure time. |
| **Route** | An ordered chain of stops for one direction (Pickup or Drop) within a shift. |
| **Stop / Pickup Point** | A physical boarding/alighting location with coordinates, safety flags and a fare. |
| **Allocation** | A student’s pickup and/or drop route + stop for a session, valid for a date range, with a fare. |
| **Constraint** | A school-configured rule the engine must honour (max ride minutes, max walk metres, arrival buffer, capacity buffer, profit target, locks). |
| **Objective** | The quantity the engine optimises (fewest buses, least km, least cost, shortest max ride, minimal change). |
| **Drift guard** | A hash of the live network taken when a plan is built; publish refuses if live data changed since. |
| **Snapshot** | A self-contained JSON copy of the live rows a publish will touch, used for rollback. |
| **Savings ledger** | Predicted vs measured financial impact of accepted Advisor suggestions. |

### 4.2 Plan lifecycle (canonical)

```
                    ┌──────────────┐
                    │    Draft     │  editable; engine or manual
                    └──────┬───────┘
             submit        │        cancel / archive
                    ┌──────▼───────┐        │
                    │   InReview   │        ▼
                    └──┬───────┬───┘   ┌──────────┐
             approve   │       │ reject│ Cancelled│
                    ┌──▼─────┐  └──────▶│ Archived │
                    │Approved│         └──────────┘
                    └──┬───┬─┘
          schedule     │   │ publish now
                    ┌──▼───▼──┐
                    │Published│──────────────▶ Superseded (a newer plan wins)
                    └──┬──────┘
             rollback  │
                    ┌──▼───────┐
                    │RolledBack│
                    └──────────┘
```

| Status | Editable? | Live? | Meaning |
|---|:---:|:---:|---|
| Draft | Yes | No | Being built; children in `tpt_plan_*` |
| InReview | No | No | Submitted; approver reviewing |
| Approved | No | No | Approved; awaiting publish or scheduled date |
| Scheduled | No | No | Approved with a future `effective_from`; auto-publishes on the date |
| Published | No | Yes | Live for its classes and date range |
| Superseded | No | No | Was live; replaced by a newer publication for the same scope |
| Rejected | No | No | Approver rejected; can be revised into a new draft |
| Cancelled | No | No | Withdrawn before approval |
| Archived | No | No | Retained for history; not actionable |
| RolledBack | No | No | Publish undone; snapshot restored |

**Rules**
- Only Draft (and Rejected, by cloning) can be edited.
- A plan cannot be approved by the person who created or submitted it, unless Super Admin.
- Publishing is one transaction: drift check → snapshot → live writes → history archive → status updates → roster → audit.
- Published, Superseded, RolledBack and Archived plans are never hard-deleted.
- One active (Published/Scheduled) plan per class/section/date range per direction/shift group.

### 4.3 Data ownership

| Prefix | Owner module | Contains |
|---|---|---|
| `tpt_*` | Foundation (`Modules/Transport`) | Masters, live network, operations, finance, plan lifecycle, staging, history, Advisor tables |
| `ptr_*` | Prime (`Modules/PrimeTransport`) | Settings, distance cache, student geo, engine runs, stop-generation runs, live ETA, disruptions, quotes, safety |
| Standard (`Modules/SmartTransport`) | `tpt_adv_*` advisory tables only | Reads live `tpt_*`; no live-network tables of its own |

**Why Standard owns no live-network tables:** it is a read/advice layer over the same network. Giving it a second copy of routes/stops/allocations would recreate the fork problem. It owns only the advisory tables — configuration in `tpt_adv_rule_settings`, runs in `tpt_adv_runs`, suggestions in `tpt_adv_suggestions`, decisions in `tpt_adv_suggestion_outcomes` and measured savings in `tpt_adv_savings_ledger`.

---

## 5. Functional requirements

### 5.1 Foundation requirements

#### FND-001 — Plan type and transport plan master
**Priority:** P0 · **Tier:** Foundation

The school defines plan types (Regular, Junior, Senior, Pre-Primary, Sports Academy, Staff, Event/Special) and creates transport plans with a code, name, academic session, plan type, source, description and billing flags. A plan is the container for a network; it is also the unit of approval and billing.

**Rules**
- `code` unique within tenant; `name` unique within session.
- A plan belongs to exactly one academic session.
- A plan has `is_billable` and `billing_mode` (Monthly, Term, Annual, PerTrip, None).
- A plan may cover multiple shifts through `tpt_transport_plan_shift_jnt`.
- A plan may target multiple classes/sections through `tpt_transport_plan_class_jnt`.
- A plan stores `levers_json` (what was asked), `kpi_json` (what it achieves) and `baseline_hash` (drift guard).

**Acceptance**
1. Create/edit/archive a plan with type, session, billing flags and description.
2. Attach one or more shifts with direction and timing overrides.
3. Attach one or more classes/sections with date ranges and priority.
4. A plan cannot be published without at least one class/section and one shift.
5. Plan code/name uniqueness messages are field-specific.

#### FND-002 — Class, section and date-range applicability
**Priority:** P0 · **Tier:** Foundation

A plan applies to specific classes and sections for a specific date range. This is what allows “Junior plan for classes 1–5 from 1 April to 30 September” and “Senior plan for classes 6–12 for the same period” to coexist.

**Rules**
- `tpt_transport_plan_class_jnt` holds plan, class, section (nullable = all sections), session, effective dates, priority and active flag.
- For a given class/section/date, at most one plan may be Published. Overlap is checked at approve and publish time.
- If two plans overlap, the one with higher `priority` wins only if explicitly allowed; otherwise publish is blocked with the conflicting plan named.
- A section-level mapping overrides a class-level mapping for that section.
- Date ranges must lie inside the academic session; `effective_to` may be NULL for open-ended.

**Acceptance**
1. Attach a plan to class 6, all sections, 2026-04-01 to 2027-03-31.
2. Attach a second plan to class 6-B only, 2026-11-01 to 2027-03-31; publish is blocked until the first plan is end-dated or the second is scoped to a non-overlapping range.
3. Current view for a student resolves exactly one plan.
4. A plan change for one class group does not affect another group.

#### FND-003 — Shift and timing configuration
**Priority:** P0 · **Tier:** Foundation

Shifts define operating windows, school arrival targets, departure times, working days and grace periods. They group routes and drive trip generation, ETA and billing day counts.

**Rules**
- `code` and `name` unique.
- `shift_start_time` = time buses must reach school; `shift_end_time` = time buses leave school.
- Optional `pickup_reach_by`, `drop_depart_at` are the hard targets used by the Prime engine.
- `days_of_week` restricts operation (e.g. Mon–Sat).
- `grace_minutes` defines lateness tolerance.
- A route’s stop times must fall inside its shift window unless an override is configured.

**Acceptance**
1. Create Morning (reach 07:30, depart 14:00, Mon–Sat) and Afternoon (reach 11:30, depart 16:00).
2. Assign routes and see validations against the window.
3. Seasonal timing is handled by creating a new plan with updated shift mappings, not by editing history.

#### FND-004 — Vehicle master, documents and availability
**Priority:** P0 · **Tier:** Foundation

Register owned, leased and rented vehicles with capacity, type, fuel, emission class, vendor, depot, GPS device, cost per km and compliance documents.

**Rules**
- `registration_no` + `vehicle_no` unique.
- `max_capacity >= capacity`.
- `vendor_id` required when ownership is Leased/Rented; optional for Owned.
- Compliance documents (fitness, insurance, pollution, fire extinguisher, emission, GPS) are stored in `tpt_compliance_document` with number, validity and media.
- A vehicle with any expired mandatory document is auto-set `availability_status = 0` and cannot be assigned to a new trip.
- Returning from maintenance restores availability only when documents are valid.
- `avg_exp_per_km` and `avg_fare_per_km` are derived from approved fuel/maintenance and fares, not hand-typed.

**Acceptance**
1. Register a 40-seat diesel bus with vendor and depot.
2. Upload insurance valid to 31 Mar 2027; see “expiring” at 30 days and “expired” at 0.
3. Attempt to roster an expired bus; blocked with the document name and expiry date.
4. Renew the document; availability restores automatically or after approval per policy.

#### FND-005 — Personnel, licence and police verification
**Priority:** P0 · **Tier:** Foundation

Maintain drivers, helpers and transport managers with role, licence, experience, police verification, ID documents and device binding.

**Rules**
- Driver requires licence number, expiry and experience; expired licence blocks new assignment.
- Police verification flag is mandatory for drivers/helpers; block-vs-warn is a school setting (default: warn + flag, block for pre-primary routes).
- Government ID and licence numbers are encrypted at rest and masked in UI; a hash column supports exact search.
- One active attendance device per person.
- Role must be Driver for primary driver, Helper for helper.

**Acceptance**
1. Create a driver with a licence valid to 31 Dec 2026; roster works.
2. Expire the licence; roster is blocked for new assignments, existing trips are flagged.
3. Toggle police verification; dashboard and staff grid update.
4. Aadhaar is never shown in full to an ordinary user.

#### FND-006 — Stop master and geocoding
**Priority:** P0 · **Tier:** Foundation

Stops are physical locations with code, name, latitude/longitude, address, landmark, stop type, safety flags and verification status.

**Rules**
- Latitude −90..90, longitude −180..180.
- A stop is geocoded (`Geocoded`), manually pinned (`Manual`) or `Pending`; missing coordinates are stored as NULL, never a default city.
- A stop with `Pending` geocode cannot be used by the Prime engine; it is listed as “needs location”.
- A stop cannot be deactivated while an active route-stop row references it, unless the plan explicitly removes it.
- `tpt_pickup_point_geo` holds the spatial POINT for indexed proximity queries; the master lat/lng remains the readable source.
- Safety flags (main-road crossing, unlit, narrow lane, no shelter, unsafe for pre-primary) are configurable and used by Prime stop generation.

**Acceptance**
1. Create a stop by map pin; `geocode_status = Manual`, geo row created.
2. Import a stop without coordinates; row is `Pending`, not Bangalore.
3. Prime generation skips pending stops and reports them.
4. Deactivating a routed stop is blocked with the route list.

#### FND-007 — Route master and path geometry
**Priority:** P0 · **Tier:** Foundation

Routes are ordered stop chains for one direction and shift, with a real road path, distance and estimated duration.

**Rules**
- Route code unique within plan; name unique within plan.
- Direction is Pickup or Drop, never Both.
- `route_geometry` is a LINESTRING (SRID 4326) built from the ordered stops and, when available, OSRM road geometry.
- `total_distance_km` and `est_duration_min` are computed; manual override is logged.
- A route cannot be published with fewer than two stops, a missing shift, or a stop outside the shift window.
- A route may be Draft, Active, Inactive or Archived.

**Acceptance**
1. Create a Pickup route with 8 stops; map draws the full path.
2. Reorder stops; distance/time recalculate.
3. A route with a missing stop coordinate is flagged and cannot be published until fixed.
4. Archived routes remain visible in history but not in current views.

#### FND-008 — Route-stop sequencing, times and fares
**Priority:** P0 · **Tier:** Foundation

Assign stops to a route with a gap-free ordinal sequence, scheduled arrival/departure offsets, distance from school and one-way/both-way fares.

**Rules**
- Ordinals start at 1 and have no gaps.
- A stop appears at most once per route.
- `departure_time >= arrival_time`.
- `both_side_fare >= pickup_drop_fare`.
- Times are minutes from midnight (compatible with existing web behaviour).
- Fare precedence: class/plan fare master → route-stop fare → manual override (logged and approved).

**Acceptance**
1. Add 8 stops in order; ordinals 1–8 with no gaps.
2. Try ordinal 10 after 8; blocked with “sequence gap”.
3. Add the same stop twice; blocked.
4. Change a fare; an audit row records old, new, user and reason.

#### FND-009 — Fare master and class pricing
**Priority:** P0 · **Tier:** Foundation

A plan-aware fare matrix defines one-way and both-way fares by route, stop, class and direction, with effective dates.

**Rules**
- Fare rows are versioned by effective date; historical allocations keep the fare they were billed at.
- Precedence: exact stop + class → route + class → plan default → route-stop fallback.
- A fare change does not retroactively change issued invoices.
- Zero or negative fare is allowed only for non-billable plans.
- Proration policy is set per plan (full month, daily prorata, next cycle).

**Acceptance**
1. Set class 6 fare for stop S to ₹1,800 one-way and ₹3,200 both-way.
2. Allocate a class 6 student; fare auto-fills and is read-only.
3. Change the fare mid-month; existing invoice remains, next invoice uses the new fare.
4. Non-billable plan produces zero-value invoices or no invoice per policy.

#### FND-010 — Driver/vehicle assignment and overlap
**Priority:** P0 · **Tier:** Foundation

Assign a driver, helper and vehicle to a route and shift for a date range and direction.

**Rules**
- The same driver/vehicle cannot hold overlapping assignments for the same shift/route/direction.
- A vehicle cannot be assigned to two routes at overlapping times, even across shifts.
- A driver cannot be assigned while absent or unlicensed.
- Prior assignments are preserved; changes create a new row and end-date the old one.
- `total_students` is derived, not a drifting counter.

**Acceptance**
1. Assign Bus 3 + Driver A to Route 5 from 1 Nov.
2. Attempt an overlapping assignment; blocked with the conflicting dates.
3. End-date the assignment; history remains.
4. Roster generation uses only active assignments.

#### FND-011 — Daily roster
**Priority:** P0 · **Tier:** Foundation

The roster converts plan assignments into per-date, per-route execution rows used by trips, attendance and boarding.

**Rules**
- One route per date/shift/direction; one vehicle, driver and helper per date/shift/direction.
- A date with an existing trip is never re-rostered automatically.
- Manual one-day overrides are allowed and preserved.
- A conflict (same bus/driver/helper on two routes) is skipped and counted, never forced.
- Roster horizon runs to the end of the academic session.

**Acceptance**
1. Generate roster for a published plan; rows exist for every operating day.
2. Change a bus; only future dates change, past/tripped dates remain.
3. A conflict produces a report with the skipped dates and reason.

#### FND-012 — Trip lifecycle
**Priority:** P0 · **Tier:** Foundation

A trip is one run of a route on a date. It captures start/end time, odometer, fuel, status and approval.

**Rules**
- Status: Scheduled → InTransit → Completed → Approved; Cancelled from Scheduled/InTransit.
- A trip cannot start without a same-day passed inspection and an available vehicle.
- Start odometer must be ≥ last completed end odometer; tolerance 5 km (warning) and hard block beyond.
- End odometer > start odometer; end fuel ≥ 0.
- A vehicle already InTransit cannot start another trip.
- Only an authorised user can approve; approval freezes trip data and may raise a vendor usage log.
- A rejected trip returns to Scheduled/InTransit with mandatory remarks.

**Acceptance**
1. Start a trip; status/time/odometer saved.
2. Try to end before start; blocked.
3. Approve; data locks, approver and timestamp recorded.
4. A second start for the same bus is blocked.

#### FND-013 — Stop event tracking
**Priority:** P0 · **Tier:** Foundation

Each stop on a trip records scheduled vs actual arrival/departure, reached flag and emergency flag.

**Rules**
- Stop N cannot be marked reached until N−1 is reached.
- GPS within 50 m may auto-mark arrival (configurable).
- Leaving time ≥ reaching time.
- Emergency halt requires remarks and raises a high-severity notification.
- Actual times drive ETA learning, delay reports and safety analytics.

**Acceptance**
1. Mark stops in order; out-of-order is blocked.
2. Reach/leave times save and display variance.
3. Emergency flag requires remarks.
4. Actual times are available to Prime’s speed learner.

#### FND-014 — Trip incidents
**Priority:** P0 · **Tier:** Foundation

Record breakdowns, accidents, delays, medical events and discipline issues with severity, location and resolution.

**Rules**
- Description required.
- HIGH/CRITICAL triggers immediate multi-channel escalation.
- Resolution requires action taken and stamps resolver/time.
- Open incidents appear on the dashboard and safety reports.
- Incidents are never deleted by plan operations.

**Acceptance**
1. Log a HIGH incident; escalation event created.
2. Resolve with remarks; status and resolver recorded.
3. Incident remains in history after a plan publish/rollback.

#### FND-015 — Student transport allocation
**Priority:** P0 · **Tier:** Foundation

Allocate a student to pickup and/or drop route + stop for a session and date range, with fare.

**Rules**
- One active allocation per student per session per direction/date.
- Stop must belong to the selected route.
- Route direction must match use type.
- Capacity gate: block at 100% (configurable), warn at 90%.
- Fare is derived; manual override requires permission and reason.
- New allocation deactivates the prior one atomically.
- Allocation carries `plan_id` and `effective_from/to` for billing and history.
- Inactive/ended allocation produces no invoice in the next cycle.

**Acceptance**
1. Allocate a student to pickup route/stop and drop route/stop with fare.
2. Re-allocate; prior row ends and new row starts atomically.
3. Capacity full; allocation blocked with the route and capacity.
4. Allocation import uses admission number or class+section+roll+current session, never roll alone.

#### FND-016 — Stop-change request
**Priority:** P1 · **Tier:** Foundation

A parent or staff member requests a different stop; Transport approves or rejects with an effective date.

**Rules**
- Request records current allocation, requested route/stop, reason, requester and status.
- Approval creates a new allocation effective from the approval/effective date and ends the prior one.
- Capacity and route membership are checked at approval.
- Parent can see only their own child’s request.
- Rejection requires a reason.

**Acceptance**
1. Parent requests a closer stop.
2. Transport sees capacity and walk distance.
3. Approve; allocation changes from the effective date.
4. Reject; reason visible to parent.

#### FND-017 — Boarding/unboarding and devices
**Priority:** P0 · **Tier:** Foundation

A QR/RFID scan on a registered device records boarding/unboarding and triggers a parent notification.

**Rules**
- Scan valid only if device active, student allocation active, stop matches route/direction, and scan is not a duplicate.
- Duplicate window: 15 seconds (configurable) for the same student/trip/stop.
- One row per student per trip per direction; boarding inserts/updates, unboarding completes the row.
- Manual override requires a reason and is flagged.
- A boarding without unboarding after the trip ends raises a “missing checkout” alert.
- Device suspension returns 403 and invalidates the session token.

**Acceptance**
1. Valid scan records boarding with trip, stop, time, device.
2. Wrong stop/unallocated student/unregistered device is rejected with a clear reason.
3. Duplicate within 15 s is ignored and logged.
4. Parent notification event created.
5. Missing unboarding appears in the safety report.

#### FND-018 — Driver/helper attendance
**Priority:** P1 · **Tier:** Foundation

Attendance by device scan or manual entry, with daily summary and punch log.

**Rules**
- One summary per person per date.
- Total work minutes = last out − first in.
- Status: Present, Absent, Half-Day, Late.
- An absent driver blocks dispatch on that date.
- Manual override requires remarks.
- App-generated punches cannot be silently edited.

**Acceptance**
1. Scan in/out; summary computes.
2. Mark absent; roster/dispatch warns.
3. Manual override logs the manager and reason.

#### FND-019 — Inspection → service → maintenance
**Priority:** P0 · **Tier:** Foundation

A pre-trip checklist produces Passed/Failed; failure raises a service request and takes the vehicle out of service; approval creates maintenance; completion restores availability and raises a vendor payable.

**Rules**
- Critical failure set: tyres, lights, brakes, fire extinguisher, seat belts.
- Failed inspection auto-creates a Pending service request and sets availability 0.
- A trip cannot start without a same-day Passed inspection.
- Service request may reference an inspection; manual fault requests are allowed with a reason (configurable).
- Maintenance can only be created from an approved service request; direct creation is blocked.
- Maintenance dates: initiation ≤ in-service ≤ out-service.
- Approved maintenance is read-only; approval raises a vendor bill for leased/rented vehicles.
- Returning to service requires valid documents and an out-of-service date.

**Acceptance**
1. Fail brakes; vehicle unavailable and request created.
2. Approve request; maintenance record created.
3. Complete maintenance; vehicle available, vendor payable created.
4. Edit approved maintenance; blocked.

#### FND-020 — Fuel log
**Priority:** P1 · **Tier:** Foundation

Record refuelling with quantity, cost, odometer, station, invoice and driver.

**Rules**
- Odometer must exceed the previous approved reading.
- Entry is Pending until approved; rejected entries keep a reason.
- Only approved entries count toward km/L, cost/km and P&L.
- A fuel rate above a configured threshold raises an anomaly.
- Fuel entries are immutable after approval; corrections are reversals.

**Acceptance**
1. Add fuel; status Pending.
2. Approve; efficiency recalculates.
3. Reject with reason; excluded from analytics.
4. Anomalous rate flagged.

#### FND-021 — Notifications
**Priority:** P1 · **Tier:** Foundation

Compose notification events for trip start, approaching stop, reached stop, delay, cancellation, boarding, unboarding, fee due, fee overdue, document expiry, incident and plan change.

**Rules**
- One event per recipient/type/entity; channel status tracked independently.
- Delivery is via Notification/Automation; Foundation writes the true status back.
- Parent sees only their own child.
- Failed channels can be retried once; repeated failures raise an Advisor suggestion.
- “Approaching” refers to the next stop, not the stop just left.

**Acceptance**
1. Boarding creates an event with app/SMS/email/WhatsApp statuses.
2. Failed SMS shows in the notification report and can be retried.
3. Plan publish creates a “stop/time changed” notice for affected parents.

#### FND-022 — Plan draft and manual builder
**Priority:** P0 · **Tier:** Foundation

Standard and Prime users can build a plan manually: clone the live network or start empty, then add routes, stops, assignments and allocations in the staging tables.

**Rules**
- Draft children live in `tpt_plan_route`, `tpt_plan_route_stop`, `tpt_plan_new_stop`, `tpt_plan_vehicle_assignment`, `tpt_plan_allocation`.
- Live tables are untouched until publish.
- Clone copies every live row as `change_kind = unchanged`.
- Validation runs before submit: every route has ≥2 stops, every student has a route/stop or an explicit unserved reason, every route has a bus and crew, all stops geocoded, no capacity overflow unless allowed.
- Draft can be saved incomplete and resumed.

**Acceptance**
1. Clone the live network into a draft.
2. Move one stop between routes; change_kind becomes changed/added/removed.
3. Submit with a missing bus; validation names the route.
4. Draft persists across sessions.

#### FND-023 — Plan review and approval
**Priority:** P0 · **Tier:** Foundation

A submitted plan is reviewed with before/after maps and KPI differences, then approved or rejected with comments.

**Rules**
- Approver permission required; creator/submitter cannot approve own plan (Super Admin exception).
- Whole-plan approval or per-route comments; no partial publish.
- Rejection requires a remark; rejected plan can be revised into a new draft.
- Approval records who/when and freezes the plan.
- Approval sets class/section applicability and date range (if not already set).
- One-step or two-step chain per school.

**Acceptance**
1. Submit a plan; status InReview.
2. Approver sees live-vs-plan map, Δkm, Δcost, Δincome, Δmax ride, students moved.
3. Approve with class/date; status Approved.
4. Reject with reason; status Rejected and audit row written.
5. Self-approval blocked.

#### FND-024 — Scheduling and publish
**Priority:** P0 · **Tier:** Foundation

An approved plan is published immediately or on an effective date. Publish moves the plan into the current tables inside one transaction.

**Rules**
- Drift guard: live network hash must equal `baseline_hash`; otherwise refuse and ask to rebase/regenerate.
- Preflight: every bus, stop, student and class still exists.
- Snapshot before publish; then insert/update live rows; archive the replaced plan; snapshot after.
- Removed routes/stops are deactivated, never hard-deleted.
- Student fares are not changed by publish unless the plan explicitly carries a fare change.
- Trips, boarding logs, incidents and fees are never touched.
- Roster is rewritten only for touched routes and future dates.
- Publish writes audit rows and parent/crew notifications.

**Acceptance**
1. Publish an approved plan; live network matches the plan.
2. Change live data after plan creation; publish refuses with “live network changed”.
3. Publish is atomic; a failure leaves no partial network.
4. Old plan rows appear in history with effective_to = day before new plan.
5. Current views show the new plan.

#### FND-025 — History archive and rollback
**Priority:** P0 · **Tier:** Foundation

When a plan is published, the replaced live rows are copied to history. A publication can be rolled back to its before-publish snapshot.

**Rules**
- History tables: route, stop, route-stop, allocation, assignment, plan version.
- Every history row carries `plan_publication_id`, `effective_from`, `effective_to`, `archived_at` and reason.
- Billing references `plan_publication_id` and the allocation history row, so an old invoice can always be explained.
- Rollback checks the after-publish drift hash; if live data changed, refuse.
- Rollback restores snapshot rows, deletes/soft-deletes rows created by the publish, and restores the superseded plan to Published.
- Rollback is itself a plan review step with an audit row.

**Acceptance**
1. Publish plan B over plan A; A’s routes/allocations appear in history with 31 Oct end date.
2. Open an October invoice; it points to plan A’s publication and allocation history.
3. Roll back B; A is live again and B is RolledBack.
4. Edit live data after B; rollback refuses.

#### FND-026 — Current transport view
**Priority:** P0 · **Tier:** Foundation

Students, parents, admin and transport staff see the currently published plan only.

**Rules**
- Current views filter `plan.status = Published`, `is_active = 1`, and today within `effective_from/to`.
- A student resolves exactly one active plan via class/section/date.
- The view includes route, stops, stop times, vehicle, driver/helper (masked contact), fare and next trip.
- If no plan applies, show “no transport plan for your class/date” and an admin alert.
- Historical plans are never shown in current views.

**Acceptance**
1. Parent sees current route/stop/time and vehicle.
2. On the effective date, the view switches to the new plan automatically.
3. A class with no plan shows a clear empty state.
4. Admin can preview “as of date” without changing live data.

#### FND-027 — Billing run and invoice
**Priority:** P0 · **Tier:** Foundation

A monthly/term billing run generates invoices for active allocations under billable plans.

**Rules**
- Idempotent: one invoice per student/session/plan/period/type.
- Amount comes from the fare master or allocation fare; never hand-typed on the invoice.
- `total = subtotal − discount + fine + tax`.
- Due date ≥ period start; configurable billing day.
- Proration per plan policy.
- Invoice status: Draft → Issued → PartiallyPaid → Paid / Overdue / Cancelled / WrittenOff.
- Every invoice records `plan_id` and `plan_publication_id`.
- Re-running a billing month creates only missing invoices and reports the count.

**Acceptance**
1. Run October billing for 500 students; 500 invoices, correct fares.
2. Re-run; 0 new invoices.
3. Mid-month plan change with daily prorata; invoice reflects days.
4. Non-billable plan; no invoice or zero invoice per policy.

#### FND-028 — Late fee and penalty billing (separate)
**Priority:** P0 · **Tier:** Foundation

Late payment charges, penalties, damage and other charges are recorded separately from routine transport invoices and can be invoiced together or independently.

**Rules**
- Charge types: LateFee, Penalty, Damage, LostCard, StopChange, Other.
- Charge master supports Fixed, Percentage, PerDay and Slab; day bands cannot overlap.
- Grace days and cap are configurable.
- A charge references the routine invoice and/or student and plan.
- Waiver cannot exceed the charge; waiver requires a reason and permission.
- Penalty invoices are separate `invoice_type` rows; they do not rewrite the routine invoice.
- `student_restricted` never deactivates the student in the ERP; it only restricts transport service and is reversible.
- Charges are immutable after posting; corrections are credit notes/reversals.

**Acceptance**
1. October invoice unpaid 31 days; a LateFee charge is created per the slab.
2. Issue a separate penalty invoice; routine invoice unchanged.
3. Waive part of the charge with reason; net amount updates, audit recorded.
4. Student restriction affects transport booking only, not class attendance/LMS.

#### FND-029 — Payments and reconciliation
**Priority:** P0 · **Tier:** Foundation

Record full/part payments by cash, cheque, NEFT, UPI, card and gateway; reconcile and reverse.

**Rules**
- Paid amount cannot exceed outstanding.
- Payment modes requiring a reference (cheque/NEFT/UPI/card/gateway) must carry one.
- Cheque starts Processing; reconciliation makes it Cleared or Bounced.
- Invoice status updates from the sum of cleared payments.
- Reversal creates a negative payment, never edits history.
- Receipt number is unique.
- Every payment writes to `std_student_pay_log` and the accounting outbox.

**Acceptance**
1. Part-pay ₹500 of ₹1,450; invoice PartiallyPaid.
2. Add ₹950; invoice Paid.
3. Bounce a cheque; invoice returns to PartiallyPaid/Overdue.
4. Reverse a receipt; a new negative entry appears, original intact.

#### FND-030 — Accounting integration
**Priority:** P0 · **Tier:** Foundation

All billing, penalties, waivers, refunds, fuel, maintenance and vendor bills are posted to Accounting through a reliable outbox.

**Rules**
- `tpt_accounting_posting` is an outbox: source table/id, voucher type, amount, ledgers, status, retries, error.
- Posting is idempotent per source/type.
- Failed postings retry with backoff and appear on a finance dashboard.
- Cancellation/refund posts a reversing voucher, never deletes the original.
- The school maps transport fee/penalty/fuel/maintenance ledgers in settings.
- Accounting is the book of record; Transport is the sub-ledger.

**Acceptance**
1. Collect a fee; a receipt voucher is posted once.
2. Simulate Accounting downtime; posting stays Pending and retries.
3. Cancel an invoice; a reversal voucher is posted.
4. Finance can see posted/unposted totals and reconcile.

#### FND-031 — Reports and dashboard
**Priority:** P1 · **Tier:** Foundation

The 11 foundation reports plus a live dashboard.

**Reports:** route performance, trip execution, vehicle usage, driver performance, boarding attendance, student transport usage, finance & leakage, stop analysis, cost & maintenance, management summary, notification delivery.

**Dashboard:** active vehicles, active trips, checked-in crew, open incidents, boarding rate, expiring documents, expiring licences, unallocated transport students, pending service requests, outstanding fees, unposted accounting items.

**Rules**
- Date/route/vehicle/driver/class filters; PDF/Excel/CSV export.
- Completed trips only for performance calculations.
- Soft-deleted rows excluded.
- Finance report reconciles billed, collected, waived and outstanding.
- Dashboard counters drill through to the filtered list.

**Acceptance**
1. Each report opens with filters and correct totals.
2. Export matches the screen.
3. Dashboard refreshes without full reload.
4. A counter click opens the matching list.

#### FND-032 — Configuration and settings
**Priority:** P0 · **Tier:** Foundation

School-level settings for transport operations, billing, approvals, notifications and data policy.

**Rules**
- Settings are key/value JSON with group, default, validation and audit.
- Tenant-scoped cache key includes tenant id; changes invalidate immediately.
- Critical settings (capacity override, approval chain, proration, accounting mode) require admin permission.
- See Section 11 for the catalogue.

**Acceptance**
1. Change the approval chain from 1-step to 2-step; next plan follows it.
2. Change billing day; next run uses it.
3. Every change is audited.

#### FND-033 — Tenancy, security and audit
**Priority:** P0 · **Tier:** Foundation

Every request and job is tenant-scoped; every sensitive action is authorised and audited.

**Rules**
- `EnsureTenantHasModule:Transport` on every transport route group.
- No central-context query of tenant transport tables.
- Every scheduled command iterates tenants explicitly.
- FormRequest validation; no `$request->all()` mass assignment.
- PII encrypted at rest and masked; access logged.
- Every approval, publish, rollback, allocation change, fee collection, waiver, maintenance approval and plan change writes an audit row.
- Rate-limit scan and GPS endpoints per device.
- Error messages are user-safe; details go to logs with a reference id.

**Acceptance**
1. A tenant without Transport gets 403 on all transport routes.
2. A nightly job runs once per tenant and cannot read another tenant.
3. Aadhaar is encrypted and masked.
4. An audit report reconstructs who changed a plan and when.

#### FND-034 — Data quality gates
**Priority:** P0 · **Tier:** Foundation

The module refuses to build financial or optimisation output on known-bad data.

**Rules**
- Stop without coordinates = `Pending`, excluded from distance/fare generation.
- Vehicle/trip odometer missing or zero = flagged; trip distance not trusted.
- Allocation fare missing when plan is billable = billing blocked for that student.
- Route without geometry = map shows a warning and estimated path is labelled.
- Fuel/maintenance unapproved = excluded from P&L.
- A “data confidence” panel lists every gap with a link to fix it.

**Acceptance**
1. A missing stop coordinate appears in the data-quality list.
2. Prime generation refuses or reports skipped stops.
3. Billing lists students with no fare instead of silently billing zero.
4. P&L labels estimated vs actual.

#### FND-035 — Imports and exports
**Priority:** P1 · **Tier:** Foundation

Bulk import/export for stops, routes, route-stops, allocations, fares and opening balances.

**Rules**
- Template with headers and sample rows.
- Validation report: row, field, error; no silent skips.
- Idempotent upsert key (code/admission number + session).
- Allocation import matches by admission number or class+section+roll+current session, never roll alone.
- Import is transactional per batch; partial success is reported.
- Exports respect permissions and filters.

**Acceptance**
1. Import 500 allocations; report shows success/failure per row.
2. Duplicate roll numbers in different classes import correctly.
3. A bad row does not abort the whole file unless configured.
4. Export contains the same rows as the filtered grid.

#### FND-036 — Vendor integration
**Priority:** P1 · **Tier:** Foundation

Leased/rented vehicles raise usage logs on trip approval and vendor payables on maintenance approval.

**Rules**
- Only when `trip_usage_needs_to_be_updated_into_vendor_usage_log` is on and ownership is Leased/Rented.
- Billing unit Trip = quantity 1; KM = end odometer − start odometer.
- Maintenance approval creates a payable for the approved cost.
- Duplicate usage/payable for the same trip/maintenance is prevented.
- Failures are retried and visible.

**Acceptance**
1. Approve a leased trip; one usage log.
2. Approve maintenance; one payable.
3. Re-approve; no duplicate.
4. Vendor can reconcile usage with trips.

#### FND-037 — GPS ingestion
**Priority:** P1 · **Tier:** Foundation

Ingest vehicle positions from driver app or certified device; store high-volume points and raise alerts.

**Rules**
- Position: vehicle, trip (optional), lat/lng, speed, heading, accuracy, source, recorded_at.
- Alerts: overspeed, harsh brake, route deviation, long idle, panic, tamper, geofence.
- Ingest is rate-limited per device; duplicates are idempotent by device/time.
- Retention default 180 days, configurable.
- Parent sees only own child’s bus and only while the trip is active.
- Panic alert creates an incident and escalates.

**Acceptance**
1. Post positions; trip trail draws on map.
2. Overspeed raises an alert once per event.
3. Panic raises a HIGH incident and notifies the chain.
4. Old points are purged per retention.

#### FND-038 — Document and licence expiry alerts
**Priority:** P1 · **Tier:** Foundation

A daily per-tenant job checks vehicle documents and personnel licences, alerts the right users, and updates availability.

**Rules**
- Threshold configurable (default 30 days; 7 days for HIGH).
- Expired mandatory document sets vehicle unavailable.
- Expired licence flags driver; new assignment blocked.
- Alerts appear on dashboard and notification log.
- The job never runs in central context and never duplicates alerts.

**Acceptance**
1. Insurance 20 days out; MEDIUM alert.
2. Insurance expired; vehicle unavailable and HIGH alert.
3. Licence expired; roster blocked.
4. Job runs once per tenant.

#### FND-039 — Bulk operations and background jobs
**Priority:** P1 · **Tier:** Foundation

Long operations (billing run, roster generation, imports, exports, expiry scan, notification dispatch) run as queued jobs with progress and safe retry.

**Rules**
- Job is idempotent and tenant-scoped.
- Progress and result are pollable.
- Failure leaves no partial state.
- A job can be cancelled before commit.
- Queue worker restart is documented.

**Acceptance**
1. Start a 500-row billing run; progress shows.
2. Cancel; no invoices created.
3. Retry after failure; no duplicates.

#### FND-040 — Domain events and integrations
**Priority:** P2 · **Tier:** Foundation

Emit events for trip start/stop/completion, incident, emergency, allocation change, vehicle unavailable, driver absent and plan publish.

**Rules**
- Events carry tenant, aggregate, actor and payload.
- Delivery through an outbox; consumers are idempotent.
- Events are additive; existing behaviour does not depend on a listener.
- Prime, Notification, Accounting and ParentPortal can subscribe.

**Acceptance**
1. Trip start emits an event consumed by Notification.
2. Plan publish emits an event consumed by ParentPortal.
3. A failing consumer does not roll back the trip/publish.

---

### 5.2 Standard requirements (SmartTransport)

> **Tier definition:** Standard = Foundation + complete route map + rule-based Advisor + cost/P&L + loss-recovery advice + manual plan builder + comparison + savings log. **No AI route generation, no machine-generated proposals, no auto stop generation.**

#### STD-001 — Complete route path on the map
**Priority:** P0 · **Tier:** Standard

Every route displays its complete path — school → ordered stops → school/end — on an interactive map, in both directions.

**Rules**
- Path uses real road geometry from OSRM when available; otherwise a labelled estimated line.
- Stops are clickable; popup shows code, name, students, fare, scheduled time.
- Pickup and Drop paths are visually distinct.
- The map shows all routes of a shift/plan, with a route selector and a “show all” mode.
- A route with missing stop coordinates shows a warning pin and excludes that leg from distance.
- Map assets are self-hosted (MapLibre + PMTiles); no public tile/router call.
- The map is read-only in Standard; editing is Foundation/Prime.

**Acceptance**
1. Open a route; full path draws with every stop.
2. Toggle pickup/drop; correct path.
3. Click a stop; student count and fare appear.
4. A pending-geocode stop is flagged.
5. No network call to a public map/tile server.

#### STD-002 — Route and stop map validation
**Priority:** P1 · **Tier:** Standard

The map highlights geometry problems: zig-zag order, long detour, stop too close to another, stop inside the school walk zone, missing coordinate, unsafe crossing.

**Rules**
- Zig-zag: A→B→C > 2.2 × A→C and detour > 2 km.
- Adjacent stops < 250 m on the same route are flagged for merge.
- Stop within school walk zone is flagged.
- Long commute > configurable max ride is flagged.
- Flags are advisory in Standard; Prime can turn them into plan changes.

**Acceptance**
1. A zig-zag route shows a warning.
2. Two stops 180 m apart show a merge hint.
3. A 75-minute route shows a long-commute warning.

#### STD-003 — Persisted Advisor engine
**Priority:** P0 · **Tier:** Standard

The 68-rule Advisor runs in the background (nightly or on demand), persists suggestions, and opens instantly.

**Rules**
- Rules are classes with `code()`, `family()`, `evaluate(context): Finding[]`.
- `AdvisorContext` preloads routes, loads, costs, trips, fuel, incidents and fees once per run.
- A failing rule is logged and skipped; other rules still run.
- Rules are deduplicated by fingerprint; a rule that stops firing resolves its open suggestion.
- Each suggestion carries problem, action, benefit (₹/km/min), priority, calculation trace and target.
- Thresholds come from `tpt_adv_rule_settings`; no hard-coded money assumptions.
- Run history and failures are visible.

**Acceptance**
1. Page opens in <1 s from stored suggestions.
2. “Refresh now” queues a run with progress.
3. A rule failure does not blank the page.
4. A fixed issue resolves its suggestion on the next run.
5. A threshold change takes effect next run.

#### STD-004 — Advisor rule catalogue
**Priority:** P0 · **Tier:** Standard

The Advisor covers compliance, capacity, cost, fees, punctuality, fuel, crew, safety and parent communication.

**Rule families and examples**
- **Compliance:** vehicle document expiry, missing scans, emission class, GPS missing, police verification, licence expiry.
- **Capacity:** route overload, vehicle size mismatch, low-student stop, route merge candidate, stop split, shift imbalance.
- **Cost/profit:** route deficit, fare below cost, idle fleet, shift reuse, right-size, overlapping stops, thin detour, walking zone.
- **Fees:** outstanding, unused allocation, fare anomaly, fine waiver excess, ineffective fine policy, unreconciled payments, cash overhead, chronic default.
- **Punctuality:** late stop, skipped stop, trip approval backlog, duration variance, peak timing.
- **Fuel/maintenance:** mileage, rate anomaly, approval backlog, service due, repeat inspection failure, replace-vs-repair, garage downtime, workshop variance, fuel transition.
- **Safety:** unboarding missed, incident hotspot, unresolved incident, driver incident frequency, high-severity alert, repeated emergency stop.
- **Parent comms:** SMS failure, app adoption, notification coverage, driver app data gaps.

**Rules**
- Every rule has a stable code, family, default severity and threshold keys.
- Money assumptions are settings, not constants.
- Rules use real columns; no rule may reference a non-existent table/column.
- Each rule has a unit test with a fixture school.

**Acceptance**
1. The catalogue is documented with code, family, trigger, formula and settings.
2. Every rule runs green on a fixture.
3. No rule produces a false positive on an empty/clean tenant.

#### STD-005 — Route, bus and student P&L
**Priority:** P0 · **Tier:** Standard

For any route, bus or student, show income, variable cost, fixed cost, net margin and confidence.

**Formula**
```
Income        = Σ allocation fare × direction share (Both = 50/50)
Variable cost = fuel (approved) + maintenance (approved) + tyre/wear estimate
Fixed cost    = crew salary + vendor rent + insurance + depreciation estimate
Net margin    = income − variable − fixed
Cost/student  = total cost ÷ students
Confidence    = HIGH / MEDIUM / LOW based on data completeness
```

**Rules**
- Both-direction fares are split 50/50 to avoid double counting.
- Only approved fuel/maintenance count.
- Missing salary/rent is shown as “unlinked”, not zero silently.
- Odometer-first distance; fall back to road geometry; label estimate.
- Historical months use the plan publication in force.

**Acceptance**
1. Route P&L reconciles to sum of student fares (half each leg).
2. A missing salary shows a warning.
3. A route with fuel but no income shows a deficit.
4. Confidence changes when data is filled.

#### STD-006 — Loss-recovery recommendations
**Priority:** P0 · **Tier:** Standard

The Advisor recommends concrete recovery moves: transfer a stop, merge stops/routes, split a route, cluster stops, rebalance corridors, swap/right-size buses, reuse a bus across shifts, adjust fare, renegotiate rent, audit maintenance, or plan a withdrawal.

**Rules**
- Every recommendation states the trigger, the proposed change, the monthly ₹ impact, the km/time impact and the affected students.
- Zero-harm guard: a move must not flip a profitable donor route into loss, worsen an existing loss by >10%, or exceed capacity.
- Terminal stops and school-adjacent safety constraints are protected.
- Recommendations are read-only in Standard; “Apply” is disabled or shown as “available in Prime”.
- A blocked recommendation is shown with the exact blocking reason, not hidden.
- The calculation trace is visible.

**Acceptance**
1. A route with 3 empty stops gets a bypass recommendation with time and fuel saving.
2. A stop transfer shows donor and receiver impact.
3. A merge that would overload the receiver is blocked with reason.
4. A recommendation never edits live data.

#### STD-007 — Stop transfer, merge, split and cluster advice
**Priority:** P0 · **Tier:** Standard

The specific v2 recommendation types are available as advice:

| Type | Trigger | Proposed outcome |
|---|---|---|
| Stop transfer | Route A overloaded / Route B has seats; shared or nearby stop | Move N students/stop from A to B |
| Stop merge | Two stops ≤ merge radius; low combined volume | Keep the higher-volume anchor; students walk |
| Stop split | One stop > largest bus capacity | Split into capacity-sized groups served by separate buses |
| Cluster | Several low-volume stops within a radius | One central hub stop |
| Route merge | Two underloaded routes within radius; combined fits a bus | One route, larger bus |
| Route split | Long route / tail with few students | Trunk + feeder or two loops |

**Rules**
- Walk distance after any move must be ≤ the school’s max walk.
- Capacity after any move must be ≤ the receiving vehicle’s capacity.
- Safety flags (crossing, unlit, narrow lane, pre-primary) override savings.
- The advice shows students moved, walk distance, time delta, km delta and ₹ delta.
- Advice is reproducible: same inputs produce the same recommendation.

**Acceptance**
1. A 40-student route with a 30-seat bus recommends moving 10 students with a named receiver.
2. Two stops 180 m apart recommend a merge with a 180 m walk.
3. A stop with 84 students and a 50-seat max fleet recommends 2 groups.
4. A move that violates max walk is blocked.

#### STD-008 — Plan comparison (live and manual)
**Priority:** P1 · **Tier:** Standard

Compare two or more plans (live or draft/manual) on students picked, routes, buses, distance, cost, income, margin, average/max ride, stops, walk distance and unserved students.

**Rules**
- Comparison table with per-metric best/worst highlight.
- Maps side by side, synchronized.
- Differences are computed against a chosen baseline.
- A comparison can be saved and shared with a name and notes.
- Standard compares plans; it does not generate AI plans.

**Acceptance**
1. Compare current plan vs a manually edited draft.
2. See Δstudents, Δbuses, Δkm, Δcost, Δincome, Δmargin, Δmax ride.
3. Save the comparison; reopen it later.
4. Maps show both networks.

#### STD-009 — Manual plan builder
**Priority:** P0 · **Tier:** Standard

A planner can clone the live network or start empty and edit routes, stops, assignments, allocations and fares in a draft.

**Rules**
- Same staging tables and validation as Foundation (FND-022).
- Drag-and-drop stop ordering with map feedback.
- Add/move/remove stop; add/remove route; change bus/crew; move student; edit fare.
- Capacity, walk, ride-time and shift-window warnings update live.
- No AI generation; the planner makes every change.
- Submit for approval follows FND-023.

**Acceptance**
1. Clone live; move a stop; warnings update.
2. Add a new stop; map and route update.
3. Submit; validation passes or names the issue.
4. Publish follows Foundation rules.

#### STD-010 — Savings ledger
**Priority:** P1 · **Tier:** Standard

Every accepted suggestion records its predicted saving and, after 30/60/90 days, the measured saving.

**Rules**
- Predicted saving comes from the suggestion calculation.
- Baseline metrics are captured at acceptance.
- Measurement compares actual fuel/km/maintenance/income with baseline.
- Dashboard shows “predicted” and “measured” separately; never mix them.
- Rejected/dismissed suggestions are kept for learning.
- Confidence is shown.

**Acceptance**
1. Accept a stop-merge suggestion; baseline captured.
2. After 30 days, measured saving appears.
3. Dashboard shows ₹ saved this term (measured) and pipeline (predicted).
4. A suggestion with no measurable effect is marked “no measurable saving”.

#### STD-011 — Advisor settings
**Priority:** P1 · **Tier:** Standard

Per-school thresholds for every Advisor rule.

**Rules**
- Grouped by family; each rule shows enabled, severity, threshold fields and last run.
- Defaults are safe; changes are audited.
- Invalid ranges are rejected with the allowed range.
- Reset-to-default is available.
- Changes take effect on the next run, not mid-run.

**Acceptance**
1. Change expiry warning from 30 to 45 days; next run uses 45.
2. Disable a noisy rule; it stops producing suggestions but history remains.
3. Reset one rule; default restored.

#### STD-012 — Suggestion lifecycle
**Priority:** P1 · **Tier:** Standard

Suggestions can be opened, accepted, dismissed, snoozed, resolved or expired; acceptance does not auto-apply in Standard.

**Rules**
- Accept records a decision and owner; it does not change live data in Standard.
- Dismiss requires a reason.
- Snooze sets an until date; the suggestion does not reappear before it.
- A rule that stops firing marks its suggestion resolved.
- A materially changed fact can reopen a snoozed suggestion.
- Every decision is audited.

**Acceptance**
1. Accept a suggestion; status Accepted, no live change.
2. Snooze for 30 days; it disappears until then.
3. Fix the underlying issue; next run resolves it.
4. Dismiss with reason; history retained.

#### STD-013 — Route health and safety alerts
**Priority:** P1 · **Tier:** Standard

The map and Advisor flag long commutes, zig-zag paths, unsafe stops, missing attendants, missing inspections, overspeeding and unboarding gaps.

**Rules**
- Long commute > configured max for the age band.
- Zig-zag and detour thresholds as STD-002.
- Pre-primary route without a helper is HIGH.
- Route with a girl’s last drop and no female attendant is HIGH (configurable, state-specific).
- Missing inspection or expired document is HIGH.
- Alerts link to the underlying record.

**Acceptance**
1. A 70-minute route for class 1 shows HIGH.
2. A pre-primary route with no helper shows HIGH.
3. An expired insurance shows HIGH with the expiry date.
4. Clicking an alert opens the route/vehicle.

#### STD-014 — Standard reports
**Priority:** P1 · **Tier:** Standard

Additional reports: route profitability, bus P&L, stop profitability, savings ledger, capacity heatmap, data confidence, route health, plan comparison.

**Rules**
- Same filter/export standard as Foundation.
- P&L reports show confidence and estimated labels.
- Savings report separates predicted and measured.
- Capacity heatmap shows students vs seats by route.
- Data confidence lists every gap.

**Acceptance**
1. Profitability report ties to fee and cost data.
2. Savings report reconciles to the ledger.
3. Heatmap highlights overload and underuse.
4. Data confidence report is actionable.

#### STD-015 — Estimated vs actual labelling
**Priority:** P1 · **Tier:** Standard

Every distance, time and cost derived from a straight-line estimate is labelled “Estimated”; actual road/GPS-derived values are labelled “Measured”.

**Rules**
- A route with any estimated leg shows an estimated badge.
- A plan KPI header shows the percentage of distances estimated.
- Mixing estimated and measured is never presented as measured.
- Tooltips explain the source (OSRM, GPS, Haversine).

**Acceptance**
1. A haversine route shows “Estimated”.
2. An OSRM route shows “Measured”.
3. A mixed route shows the estimated percentage.

#### STD-016 — Read-only what-if
**Priority:** P2 · **Tier:** Standard

A planner can change a lever (shift time, bus count, walk radius, fare) and see the recalculated KPIs without creating a plan.

**Rules**
- What-if is read-only in Standard; no draft plan is created.
- Levers and results are shown side by side.
- The calculation uses the same P&L and capacity engine.
- “Promote to plan” is a Prime action.

**Acceptance**
1. Change shift time by 15 min; bus reuse/KPI updates.
2. Remove one bus; unserved students appear.
3. No live or draft data is written.

#### STD-017 — Demand and capacity heatmaps
**Priority:** P2 · **Tier:** Standard

Map and table views of student density, stop utilization, route load and unmet demand.

**Rules**
- Density by stop/ward/geohash.
- Load % = students ÷ capacity.
- Unmet demand = students with no allocation or pending stop.
- Click a cluster to see students and nearest stops.
- Privacy: aggregate only; no home pins in Standard.

**Acceptance**
1. Heatmap shows high-density wards.
2. Load table highlights >100% and <20%.
3. Unmet demand list is exportable.
4. No individual home coordinates are exposed.

#### STD-018 — Communication insights
**Priority:** P2 · **Tier:** Standard

Advisor views of notification delivery, parent app adoption and channel failures.

**Rules**
- Delivery rate per channel/type/route.
- Failed channels create a suggestion with the affected count.
- Retry action available.
- No message content is shown to unauthorized users.

**Acceptance**
1. SMS failure rate > threshold creates a suggestion.
2. Retry a failed batch.
3. Delivery report matches Notification logs.

#### STD-019 — Multi-plan overview
**Priority:** P1 · **Tier:** Standard

A dashboard of all plans (live, draft, scheduled, history) with status, scope, dates and KPI.

**Rules**
- Filter by session, plan type, class, status, date.
- Show conflicts (overlapping applicability).
- Show “expiring soon” plans.
- Click through to plan detail.
- No editing from the overview beyond permitted actions.

**Acceptance**
1. See Junior and Senior plans side by side.
2. A plan ending in 15 days is flagged.
3. An overlap conflict is visible.
4. Click opens the plan.

#### STD-020 — Standard APIs and mobile
**Priority:** P2 · **Tier:** Standard

Read APIs for route map, plan comparison, P&L, Advisor suggestions and savings; mobile-friendly views for transport managers.

**Rules**
- Tenant-scoped, permissioned, rate-limited.
- Pagination and ETags/cache headers.
- No PII beyond the caller’s scope.
- Stable versioned endpoints.
- OpenAPI documentation.

**Acceptance**
1. Mobile manager sees suggestions and route map.
2. API returns only the caller’s tenant.
3. Pagination works.
4. OpenAPI is published.

---

### 5.3 Prime requirements (PrimeTransport)

#### PRM-001 — Student geo capture and consent
**Priority:** P0 · **Tier:** Prime

Capture each transport student’s home pickup and drop coordinates from the student address, a staff map pin, or the parent app, with consent.

**Rules**
- Source: `std_student_addresses.is_pickup_location` / `is_drop_location`, manual pin, parent app, or geocoder.
- Consent is mandatory before coordinates are used; `consent_given`, `consent_at`, `consent_by` are stored.
- A student without a usable address is listed as “missing”, not given a fake point.
- Re-running “Generate” refreshes generated rows but does not overwrite manual/parent pins.
- Coordinates are visible only to authorised roles; parents see only their child.
- Retention and deletion follow the school’s privacy policy.

**Acceptance**
1. Generate geo for all transport students; missing addresses listed.
2. A manual pin survives a regeneration.
3. A student without consent is excluded from generation.
4. Parent sees only own child’s pin.

#### PRM-002 — Automatic stop generation from latitude/longitude
**Priority:** P0 · **Tier:** Prime

The system proposes stops from student home coordinates, respecting walk limits, density, safety and existing stops.

**Process**
1. Load consented student points for the session/class group.
2. Keep existing stops that are within `near_stop_m` of a student and safe.
3. Cluster remaining points by density and distance (DBSCAN/greedy radius).
4. For each cluster, propose a stop at a safe, accessible centroid (not inside a building/private plot; prefer a road/lit junction).
5. Enforce `max_walk_m` per student; if impossible, flag the student as “cannot be served within walk limit”.
6. Merge clusters closer than `stop_merge_radius_m`.
7. Split clusters larger than the largest bus capacity.
8. Compare with the existing stop set; mark Add/Merge/Split/Keep/Remove.
9. Save candidates to `ptr_stop_generation_candidate` and optionally to a draft plan (`tpt_plan_new_stop`).
10. Show a map with proposed stops, walk circles, unserved students and reasons.

**Rules**
- A proposed stop must have a name, code, lat/lng and reason.
- A proposed stop cannot be inside the school walk zone unless configured.
- Safety flags override density: no stop requiring a main-road crossing for pre-primary; prefer lit/sheltered.
- The number of stops is bounded by config; the engine reports the trade-off.
- The generation is reproducible with the same inputs and seed.
- The output is always a draft; nothing goes live without approval.

**Acceptance**
1. 600 students, 90 existing stops, max walk 500 m → proposed stop set with no student >500 m.
2. A dense apartment cluster > bus capacity is split.
3. A cluster 150 m from an existing stop merges into it.
4. An unservable student is listed with the reason.
5. Generation writes only draft/candidate rows.

#### PRM-003 — Stop generation constraints
**Priority:** P0 · **Tier:** Prime

Schools configure stop generation with:
- max walk distance (global and by age band)
- near-stop reuse distance
- home-merge distance
- stop merge radius
- minimum students per stop
- maximum stops per route
- school walk-zone radius
- safety flags (crossing, lighting, shelter, road type, pre-primary)
- “home pickup allowed” by age band
- consent requirement
- stop naming policy

**Rules**
- Constraints are hard or soft; hard violations block, soft violations cost.
- Every constraint has a default, range and explanation.
- The plan stores the constraints used, so it can be reproduced.
- A change to constraints requires a new generation.

**Acceptance**
1. Set max walk 400 m; generation respects it.
2. Set “no home pickup for class 6+”; engine uses shared stops.
3. A hard safety rule blocks a proposed crossing stop.
4. The plan shows the constraint snapshot.

#### PRM-004 — Automatic route generation
**Priority:** P0 · **Tier:** Prime

Generate a complete route network for a shift/direction/class group using a capacitated VRP with time windows.

**Process**
1. Validate shift, session, plan, class group, fleet and demand.
2. Build the distance/time matrix (OSRM or haversine fallback).
3. Assign each student to a stop (existing/proposed/home) per PRM-002 rules.
4. Solve the VRP with OR-Tools:
   - heterogeneous fleet capacity
   - max ride time by class band
   - school arrival window
   - max walk already enforced by stop assignment
   - optional stops (disjunction with penalty)
   - locks (route/vehicle/stop/student)
   - shift overlap/turnaround
   - objective (fewest buses, least km, least cost, shortest max ride, minimal change)
5. Order stops (pickup farthest→inward; drop nearest→outward).
6. Build geometry and schedule.
7. Compute P&L and KPIs.
8. Write the draft plan and allocations.
9. Report unserved students with reasons.
10. Repeat with shared stops if students are unserved (configurable rounds).

**Rules**
- Demand ≤ fleet capacity, else fail with the exact seat shortfall.
- Every served student has exactly one pickup and/or drop route/stop.
- No route exceeds vehicle capacity (unless allowed buffer).
- No student exceeds max ride.
- Every route reaches school by the deadline minus buffer.
- A vehicle is not double-booked across overlapping shifts.
- No stop without coordinates is used.
- The plan is a draft.
- The solver has a time limit and returns the best feasible solution with a gap.

**Acceptance**
1. 480 students, 10 buses, 4 shifts → feasible plan; all constraints met.
2. A class-1 student’s ride ≤ 35 min; class 6 ≤ 60 min.
3. Bus arrival ≤ 07:30 minus buffer.
4. No capacity overflow.
5. Unserved list is empty or explained.
6. Plan is Draft and live data unchanged.

#### PRM-005 — Route generation constraints
**Priority:** P0 · **Tier:** Prime

The school configures the constraints listed in Section 11, including:
- max ride minutes by age band
- school arrival buffer
- max walk (from stop generation)
- vehicle capacity buffer / allow-extra-students
- shift turnaround
- max stops per route
- max route duration/distance
- optional stop penalty
- locks
- objective and weights
- profit target / minimum load
- solver time limit
- number of retry rounds

**Rules**
- Hard constraints are enforced by the solver; soft constraints are penalties.
- A plan records the exact constraint values used.
- The UI explains which constraint caused an unserved student.
- A school cannot set a constraint that makes the problem infeasible without a warning.
- Defaults are safe and documented.

**Acceptance**
1. Set max ride 45 min; no student exceeds it.
2. Set capacity buffer 0; no standing passengers.
3. Set a lock on Route 4; it is unchanged.
4. A too-tight constraint produces a clear infeasibility message, not a crash.

#### PRM-006 — Profitability objective
**Priority:** P0 · **Tier:** Prime

The engine can optimise for profit or for a balance of profit, service and safety.

**Rules**
- Revenue = sum of student fares by direction (Both split 50/50).
- Cost = fuel + maintenance + crew + rent + insurance/depreciation estimates.
- Objective options: max margin, min cost per student, min buses, min km, min max ride, min change, weighted composite.
- The plan shows income, cost, margin and margin per student per route.
- A route below the school’s minimum margin is flagged; the engine may merge/split/right-size to fix it.
- The engine never sacrifices a hard safety constraint for profit.
- Estimated inputs are labelled.

**Acceptance**
1. Generate a profit-optimised plan; every route shows P&L.
2. A loss-making route is merged or flagged.
3. A safety constraint cannot be relaxed by the objective.
4. The KPI diff vs live shows the margin improvement.

#### PRM-007 — Background engine and progress
**Priority:** P0 · **Tier:** Prime

Generation runs as a queued job, never inside the HTTP request.

**Rules**
- Create `ptr_engine_runs` row with status queued; dispatch job.
- Job updates progress, stage and best-so-far KPIs.
- UI polls every few seconds and shows a progress modal.
- Cancel sets status cancelled; the job checks between solver events.
- A newer run supersedes an older run for the same scope.
- Failure writes a user-safe message and a detailed log.
- The solver process is reaped if orphaned.
- Queue worker restart is documented.

**Acceptance**
1. Generate a 250-route plan; page returns immediately.
2. Progress moves through stages.
3. Cancel stops the run without partial data.
4. Failure leaves no plan.
5. Two runs do not corrupt each other.

#### PRM-008 — Proposal lifecycle
**Priority:** P0 · **Tier:** Prime

Every generated plan is a draft proposal with a full lifecycle: Draft → InReview → Approved → Scheduled → Published → Superseded / RolledBack; plus Rejected, Cancelled, Archived.

**Rules**
- See Section 4.2.
- Only Draft is editable.
- Submit freezes children.
- Approve/reject with comments and audit.
- Reject can be revised into a new draft.
- Cancel/Archive from allowed states.
- Published/Superseded/RolledBack/Archived are never hard-deleted.
- Every step writes `tpt_plan_review`.

**Acceptance**
1. Generate → Draft.
2. Submit → InReview; editing blocked.
3. Approve → Approved.
4. Publish → Published.
5. New plan for same scope → old Superseded.
6. Rollback → RolledBack and old restored.
7. Cancel/Archive work from the right states.

#### PRM-009 — Multi-plan comparison
**Priority:** P0 · **Tier:** Prime

Compare any number of draft and live plans on all material parameters.

**Metrics**
- Students picked / unserved
- Routes and stops
- Buses used / spare
- Total km/day and km/month
- Fuel, maintenance, crew, rent, total expense
- Income, margin, margin per student
- Average and maximum ride
- Average and maximum walk
- On-time feasibility
- Capacity utilization
- Safety flags
- Change count vs baseline

**Rules**
- Choose a baseline; differences computed against it.
- Best/worst per metric highlighted.
- Maps side by side (up to 3).
- Save comparison with name/notes.
- Export to PDF/Excel.
- A comparison is read-only; promoting a scenario to a plan is explicit.

**Acceptance**
1. Compare 3 plans; all metrics shown.
2. Change baseline; deltas update.
3. Save and reopen.
4. Export matches screen.
5. A plan cannot be edited from the comparison.

#### PRM-010 — Class/section and date range on approval
**Priority:** P0 · **Tier:** Prime

When approving a plan, the approver sets which classes/sections it applies to and the date range.

**Rules**
- Class/section mapping is mandatory before approval.
- Default suggestion comes from the plan’s scope, but the approver can change it.
- Overlap with another Published/Scheduled plan for the same class/section/date is blocked with the conflicting plan.
- A section-level plan overrides a class-level plan.
- The approval records the mapping and dates.
- The plan can be scheduled to start on a future date.

**Acceptance**
1. Approve a plan for classes 1–5, 1 Nov–31 Mar.
2. Try to approve another for class 3 in the same range; blocked.
3. Approve for class 3-B only with a narrower date; allowed if no overlap.
4. Current view resolves the right plan per student.

#### PRM-011 — Publish to current tables
**Priority:** P0 · **Tier:** Prime

Publishing copies the approved plan into the live tables:
`tpt_route`, `tpt_pickup_points`, `tpt_pickup_points_route_jnt`, `tpt_student_route_allocation_jnt`, `tpt_driver_route_vehicle_jnt`, `tpt_route_scheduler_jnt`.

**Rules**
- One transaction; snapshot before/after; drift guard.
- New stops promoted from `tpt_plan_new_stop`.
- Removed routes/stops deactivated, not deleted.
- Changed routes keep their id; stops and bus replaced.
- Student allocations move to the plan’s routes/stops; fares unchanged unless the plan carries a fare change.
- Assignments inserted with effective_from = publish date.
- Older Published plan for the same scope becomes Superseded.
- Roster rewritten for touched routes and future dates only.
- Trips/boarding/incidents/fees untouched.
- Parent/crew notifications sent.

**Acceptance**
1. Publish; current tables match the plan.
2. Live hash after publish matches the after-snapshot.
3. A failing step rolls back everything.
4. Trips/incidents remain.
5. Parent of a moved student gets a notice.

#### PRM-012 — Archive replaced plan for billing and reference
**Priority:** P0 · **Tier:** Prime

Before a new plan goes live, the existing plan for overlapping classes/date range is copied to history.

**Rules**
- History rows carry `plan_publication_id`, original id, all business fields, old effective dates, archived_at and reason.
- The old plan header is versioned in `tpt_transport_plan_history`.
- Billing rows reference the publication and the allocation history row.
- History is immutable; no cascade delete from live rows.
- A history row survives even if the live row is later hard-deleted.
- Reports can reconstruct the network on any date.

**Acceptance**
1. Publish plan B over A; A’s routes/stops/allocations/assignments in history.
2. Open an old invoice; it resolves to A’s publication.
3. Delete a live stop; history still shows it.
4. “Network as of 15 Oct” report reconstructs A.

#### PRM-013 — Current transport view for all roles
**Priority:** P0 · **Tier:** Prime

Students, parents, admin and transport see the current service from live tables.

**Rules**
- Same as FND-026.
- Parent/student API returns current route, stop, time, vehicle, driver name (masked phone), next trip and ETA if available.
- Admin sees all plans and can preview a future plan.
- Transport sees roster, exceptions and unserved students.
- A student with no current plan is flagged to admin.
- The view never reads draft/history.

**Acceptance**
1. Parent app shows current stop/time.
2. On publish date, the view switches.
3. Admin can preview tomorrow’s plan.
4. Unserved student appears on the admin exception list.

#### PRM-014 — Multiple concurrent plans
**Priority:** P0 · **Tier:** Prime

A school can run different plans for different groups at the same time: Junior, Senior, Sports Academy, Staff, Special Event.

**Rules**
- Each plan has a type and class/section scope.
- Plans for different scopes can be Published simultaneously.
- A student belongs to exactly one plan per direction/date.
- Sports/Event plans can be non-billable and date-limited.
- The dashboard groups by plan type.
- A plan can be cloned to create a variant.

**Acceptance**
1. Publish Junior and Senior plans simultaneously.
2. A class 6 student resolves to Senior only.
3. A Sports plan runs Saturday only.
4. A student cannot be in two plans for the same direction/date.

#### PRM-015 — Seasonal and timing plans
**Priority:** P0 · **Tier:** Prime

Different plans for winter and summer, with different shift times, routes and stops.

**Rules**
- A plan carries its own shift mappings and effective dates.
- The next seasonal plan can be Approved/Scheduled while the current one runs.
- On the effective date, publish switches the network.
- A seasonal plan can change stop times without changing stops.
- Parents are notified of the timing change.
- History preserves the old timing.

**Acceptance**
1. Summer plan 1 Apr–31 Oct; Winter plan 1 Nov–31 Mar.
2. Schedule Winter; it publishes on 1 Nov.
3. Stop times change; routes remain.
4. Old timing visible in history.

#### PRM-016 — Billable/non-billable plans
**Priority:** P0 · **Tier:** Prime

A plan can be billable or non-billable, with a billing mode.

**Rules**
- `is_billable = 0` → no routine invoice; charges/penalties may still apply if configured.
- Billing mode Monthly/Term/Annual/PerTrip/None.
- Fare master is optional for non-billable.
- A non-billable plan still records cost and P&L.
- Switching a plan from billable to non-billable does not delete issued invoices.
- Switching from non-billable to billable starts billing from the effective date.

**Acceptance**
1. Create a non-billable Sports plan; no invoices.
2. P&L still shows cost.
3. Switch to billable from 1 Dec; December invoice generated.
4. Prior months unchanged.

#### PRM-017 — Separate late/penalty billing
**Priority:** P0 · **Tier:** Prime

Late fees and penalties are billed separately from routine transport invoices.

**Rules**
- Same as FND-028.
- A late fee can be generated by a scheduled run or manually.
- Penalty invoice has its own number, due date and status.
- A penalty does not change the routine invoice’s amount.
- Waiver/refund is a separate credit note.
- Parent sees both invoices clearly.
- Accounting receives separate voucher types.

**Acceptance**
1. Late fee invoice issued separately.
2. Routine invoice unchanged.
3. Waiver creates a credit note.
4. Accounting shows two voucher types.

#### PRM-018 — Accounting integration
**Priority:** P0 · **Tier:** Prime

Every billing/charge/payment and every fuel/maintenance/vendor cost posts to Accounting.

**Rules**
- Same outbox as FND-030.
- Plan and publication id travel with the voucher for analysis.
- Revenue split by plan/class/route is available.
- Reversals are explicit.
- Finance can reconcile Transport sub-ledger to Accounting.
- Posting failures are visible and retryable.

**Acceptance**
1. Publish a plan and bill; vouchers carry plan id.
2. Plan-level revenue report reconciles.
3. Failed posting retries.
4. Reversal posts.

#### PRM-019 — Optimise existing routes and stops
**Priority:** P0 · **Tier:** Prime

The Advisor analyses the live network and proposes improvements: transfer, merge, split, cluster, reorder, right-size, shift reuse, fare correction.

**Rules**
- Same advice as STD-006/007, plus “Apply as plan” in Prime.
- Apply creates a draft plan with the change, runs validation, and enters review.
- The draft shows before/after and affected students.
- Zero-harm guard applies.
- The live network is untouched until publish.
- The outcome is measured in the savings ledger.

**Acceptance**
1. Advisor finds 30 empty stops; “Apply” creates a draft bypass plan.
2. Draft shows savings and affected students.
3. Approve/publish updates live.
4. Ledger measures the result.

#### PRM-020 — What-if lab
**Priority:** P1 · **Tier:** Prime

Clone the live plan, change levers, run scenarios and compare up to 3.

**Levers**
- Shift time ± minutes
- Add/remove buses; swap vehicle types
- Fare per km/slab
- Walk-zone radius
- New demand area/pins/CSV
- Max ride
- Objective weights

**Rules**
- What-if runs are marked and excluded from Plans & Approvals until promoted.
- Compare side by side.
- Promote turns a scenario into a draft plan.
- No live data is written until publish.

**Acceptance**
1. Run “shift +20 min”; see bus reuse.
2. Compare 3 scenarios.
3. Promote one; it becomes a draft.
4. Live unchanged.

#### PRM-021 — Locks and partial regeneration
**Priority:** P1 · **Tier:** Prime

A planner can lock a route, vehicle, stop, driver or student assignment and regenerate the rest.

**Rules**
- Locks are stored per plan (`tpt_plan_lock`).
- A child plan inherits locks from its parent.
- The solver treats locks as hard constraints.
- A lock that makes the problem infeasible is reported.
- Unlocking and regenerating is allowed on a draft.

**Acceptance**
1. Lock Route 4; regenerate; Route 4 unchanged.
2. Lock a student to a stop; solver keeps it.
3. Infeasible lock reported.
4. Unlock and regenerate.

#### PRM-022 — Drift guard and snapshots
**Priority:** P0 · **Tier:** Prime

Every plan stores a hash of the live network; publish/rollback refuse if live data changed.

**Rules**
- Hash covers routes, route-stops, assignments and allocations for the plan’s scope.
- Publish compares baseline hash; mismatch → refuse with rebase/regenerate options.
- Snapshot before/after is self-contained JSON with checksum.
- Roster changes take their own snapshot.
- Snapshots survive live-row deletion.
- A manual “take snapshot” is available.

**Acceptance**
1. Change a live route after plan creation; publish refused.
2. Rebase/regenerate fixes it.
3. Snapshot restores after a live row is deleted.
4. Checksum mismatch is detected.

#### PRM-023 — Rollback
**Priority:** P0 · **Tier:** Prime

A published plan can be rolled back to its before-publish state.

**Rules**
- After-publish drift check; refuse if live changed.
- Undo roster changes newest first.
- Restore snapshot rows.
- Remove created rows (delete or soft-delete if referenced).
- Restore superseded plan to Published.
- This plan becomes RolledBack.
- Audit row written.
- Parent/crew notified if service changes.

**Acceptance**
1. Roll back; previous network live.
2. Trips/incidents intact.
3. Rollback after live edit refused.
4. Audit shows who/when.

#### PRM-024 — Scheduled publish
**Priority:** P1 · **Tier:** Prime

An approved plan can be scheduled for a future date and published automatically.

**Rules**
- Schedule sets status Scheduled and effective_from.
- A per-tenant command publishes due plans.
- On the day, drift guard runs; failure returns the plan to Approved with a reason.
- Person who scheduled is recorded as publisher.
- Notification sent on success/failure.
- Cancel schedule returns to Approved.

**Acceptance**
1. Schedule for 1 Nov; publishes at 00:05.
2. Drift on the day; plan returns to Approved with reason.
3. Cancel before date; no publish.
4. Notifications sent.

#### PRM-025 — Live ETA and parent alerts
**Priority:** P1 · **Tier:** Prime

Predict arrival at each upcoming stop from GPS and learned speeds; notify parents when the bus is close or delayed.

**Rules**
- ETA per trip/stop is upserted in `ptr_eta_live`.
- Learned speed per segment/time band overrides free-flow when sample count is sufficient.
- “Approaching” when ETA ≤ X minutes; “Delayed” when delay > Y minutes.
- Parent sees only own child’s stop.
- Notifications write true status to `tpt_notification_log`.
- A trip cancellation notifies all affected parents.

**Acceptance**
1. Bus 2 stops away; parent gets “approaching”.
2. Delay > 10 min; parent gets “delayed”.
3. ETA updates as GPS arrives.
4. No cross-tenant/cross-child leak.

#### PRM-026 — Disruption re-plan
**Priority:** P1 · **Tier:** Prime

On breakdown, driver absence or road closure, propose ranked recovery options.

**Options**
- Spare vehicle/driver
- Nearby route with free seats (repair mode, everything else locked)
- Split students across two routes
- Cancel with parent notice

**Rules**
- Options show feasibility, capacity, delay and cost.
- Chosen option writes a **date-only** override to the roster, not a permanent plan.
- Parents and crew are notified.
- The override is reversible.
- The disruption is recorded in `ptr_disruptions`.

**Acceptance**
1. Mark a bus down; ranked options appear.
2. Choose one; today’s roster updated.
3. Parents notified.
4. Tomorrow unaffected.

#### PRM-027 — Safety and compliance score
**Priority:** P1 · **Tier:** Prime

Score each driver, vehicle and route on safety and compliance.

**Components**
- Document validity
- Incidents (severity-weighted)
- Inspection failures
- Overspeed/harsh events
- Attendance/driving hours
- Attendant rules (female attendant for last girl drop; helper for pre-primary)
- Route deviation

**Rules**
- Score 0–100 per period.
- Breakdown is visible.
- Low score triggers an Advisor suggestion.
- Export PDF for RTO/board.
- Rules and weights are configurable in `ptr_safety_rules`.

**Acceptance**
1. A driver with 3 HIGH incidents scores lower.
2. A route with an expired bus scores low.
3. PDF exports.
4. Rule weights change the score.

#### PRM-028 — Admission transport quote
**Priority:** P2 · **Tier:** Prime

For an admission enquiry address, quote nearest stop, walk distance, route, seat availability and fare; flag “needs new stop”.

**Rules**
- Geocode or pin the address.
- Find nearest safe stops within walk limit.
- Check seat availability for the relevant shift/direction.
- Quote current fare and suggested fare.
- Save the quote in `ptr_admission_quotes`.
- No student/allocation is created.
- Admission can embed the quote widget via API.

**Acceptance**
1. Enter an address; get nearest stop and fare.
2. No seat; show “waitlist/needs new stop”.
3. Quote saved and auditable.
4. No allocation created.

#### PRM-029 — Plan KPI and savings ledger
**Priority:** P1 · **Tier:** Prime

Every plan stores its KPI; every accepted suggestion is measured.

**Rules**
- KPI: students, routes, buses, km, cost, income, margin, avg/max ride, avg/max walk, unserved, safety flags.
- KPI diff vs baseline is shown at review.
- Ledger measures 30/60/90 days after publish.
- Dashboard shows measured savings YTD.
- Confidence and data completeness are shown.

**Acceptance**
1. Plan review shows KPI diff.
2. Publish records the KPI.
3. 30-day measurement appears.
4. Dashboard sums measured savings.

#### PRM-030 — Engine configuration and rule settings
**Priority:** P0 · **Tier:** Prime

All engine parameters and rule thresholds are school-configurable.

**Rules**
- Groups: engine, advisor, ops, safety, maps, billing, P&L.
- Each key has type, default, range, description and audit.
- Invalid values rejected.
- Changes require a new run to take effect.
- Reset to default.

**Acceptance**
1. Change max ride; next run uses it.
2. Change distance source; next run uses it.
3. Invalid value rejected.
4. Audit shows old/new.

#### PRM-031 — Plan audit and approvals
**Priority:** P0 · **Tier:** Prime

Every plan step is auditable and approvable.

**Rules**
- Append-only review trail.
- Who submitted, reviewed, approved, rejected, scheduled, published, rolled back.
- Comments per plan or per route.
- No self-approval (Super Admin exception).
- Concurrent approvals: row lock, one wins.
- Export audit trail.

**Acceptance**
1. Audit shows every step.
2. Concurrent approve: one succeeds.
3. Self-approval blocked.
4. Export works.

#### PRM-032 — Multi-tenant job orchestration
**Priority:** P0 · **Tier:** Prime

Engine jobs, advisor runs, billing runs, expiry scans and publish schedulers run per tenant with isolation and fair scheduling.

**Rules**
- Job payload includes tenant id; job boots tenancy.
- A tenant cannot exhaust the queue for others (fair queue/priority).
- Progress is per tenant.
- Failed jobs retry with backoff; poison jobs go to a dead-letter view.
- Workers are horizontally scalable.
- Runbooks for restart and stuck jobs.

**Acceptance**
1. Two tenants generate simultaneously without data mix.
2. One tenant’s large job does not starve another (configurable).
3. Failed job retries.
4. Dead-letter visible.

#### PRM-033 — Solver fallback and error handling
**Priority:** P1 · **Tier:** Prime

If OSRM/OR-Tools is unavailable, the system degrades safely.

**Rules**
- OSRM down → haversine × road factor, labelled “Estimated”; plan header shows estimated %.
- Solver timeout → best feasible solution with gap, or clear failure.
- Solver crash → run failed, no partial plan, log with reference.
- Python/OR-Tools version mismatch → preflight check.
- A plan with too many estimated distances warns before publish.

**Acceptance**
1. Stop OSRM; generation still works with estimates.
2. Force timeout; best solution or clear error.
3. Kill solver; no partial data.
4. Preflight catches missing OR-Tools.

#### PRM-034 — Data quality gates
**Priority:** P0 · **Tier:** Prime

Prime refuses to optimise on bad data and tells the school what to fix.

**Rules**
- Missing student geo → excluded and listed.
- Missing stop coordinates → excluded.
- Missing fare on billable plan → warning; margin treated as unknown.
- Missing odometer/fuel/salary → P&L confidence low.
- Duplicate students/allocations → flagged.
- The plan cannot be approved with unresolved HIGH data issues unless explicitly overridden.

**Acceptance**
1. 20 students missing geo; plan lists them as unserved.
2. 3 stops missing coordinates; plan excludes and warns.
3. Missing fares; margin shows “unknown”.
4. Override requires a reason.

#### PRM-035 — Prime reports
**Priority:** P1 · **Tier:** Prime

Additional reports: plan comparison, plan KPI history, publish/rollback audit, savings ledger, stop-generation analysis, route-generation constraint report, ETA/delay, disruption log, safety score, admission quotes.

**Rules**
- Same filter/export standard.
- Historical plans reconstruct the network on a date.
- Savings separates predicted/measured.
- Safety export for RTO/board.
- Data confidence is always visible.

**Acceptance**
1. Plan comparison report matches the UI.
2. Historical network report reconstructs a date.
3. Savings report reconciles.
4. Safety PDF exports.

---

## 6. The eight Prime conditions — detailed interpretation

This section restates the user’s brief as testable requirements. The condition numbers are the user’s; sub-conditions are explicit.

### Condition 1 — Automatic stop generation from longitude and latitude

**Intent:** Stop placement should be derived from where students actually live, not typed by hand.

**Inputs**
- Consented student pickup/drop coordinates (`ptr_student_geo`)
- Existing stops (`tpt_pickup_points`)
- School location and walk-zone radius
- Safety flags and road data
- Config: max walk, merge radius, near-stop reuse, min students, home-pickup policy

**Process**
1. Load demand points for the class group/shift/direction.
2. Reuse safe existing stops within the near-stop distance.
3. Cluster remaining points by density and radius.
4. Place a proposed stop at a safe centroid.
5. Enforce max walk; list unservable students.
6. Merge/split clusters per capacity and radius.
7. Classify each stop as Keep/Add/Merge/Split/Remove.
8. Save candidates and optionally a draft plan.
9. Show map, walk circles, unserved list and reasons.

**Outputs**
- `ptr_stop_generation_runs`, `ptr_stop_generation_candidate`
- `tpt_plan_new_stop` in a draft plan
- A map preview and a downloadable CSV

**Rules**
- No invented coordinates; missing stays missing.
- No stop inside a building/private plot; prefer a safe road/junction.
- No stop requiring an unsafe crossing for pre-primary.
- A student never walks more than the school’s limit.
- A cluster larger than the largest bus is split.
- The output is a draft.

**Acceptance**
1. 600 students, 90 stops, 500 m walk → no student >500 m.
2. A dense 84-student cluster with a 50-seat max fleet → 2 groups.
3. A cluster 150 m from an existing stop → merge.
4. A student 2 km from any candidate → listed as unservable.
5. No live stop is created.

**Edge cases**
- Zero consented students → no generation; explain consent.
- All students within the school walk zone → no stops; suggest walking.
- Rural sparse demand → many stops; show cost trade-off.
- Duplicate addresses → one point, count students.
- School location missing → compute centroid, flag.

### Condition 2 — Automatic route generation under school constraints

**Intent:** Build safe, feasible, profitable routes automatically.

#### 2.1 Maximum travel time
- Max ride by age band (e.g. pre-primary 35, primary 45, middle 60, senior 60).
- Enforced as a hard constraint in the solver.
- The plan reports the max and average ride per route and per student.
- A route that exceeds it is infeasible, not “warned”.

#### 2.2 Maximum student walk
- Max walk by age band and globally.
- Enforced during stop assignment and re-checked after route changes.
- The plan reports max/average walk and the number of students above the limit (must be zero unless overridden).
- A stop move that increases walk beyond the limit is blocked.

#### 2.3 Profitable route planning
- Revenue and cost per route are computed from fares, fuel, maintenance, crew, rent and estimates.
- The objective can prioritise margin, cost per student, buses, km, ride time or a weighted composite.
- Routes below the minimum margin are merged/split/right-sized or flagged.
- The plan shows margin per route and per student.
- Hard safety constraints are never traded for profit.

#### 2.4 School-configurable constraints
- All parameters in Section 11 are editable by the school.
- Hard vs soft is explicit.
- The plan stores the constraint snapshot.
- Infeasibility is explained with the binding constraint.
- A school can save constraint templates (e.g. “Junior Summer”, “Senior Winter”).

**Acceptance**
1. A plan meets every hard constraint; a report proves it.
2. A tighter constraint changes the plan and the unserved list.
3. A profit objective improves margin vs the live plan without violating safety.
4. A constraint change is auditable.

### Condition 3 — Comparison of multiple transport plans

**Intent:** Management chooses between plans on evidence, not intuition.

**Parameters**
- Students picked / unserved
- Routes, stops, buses used/spare
- Distance (km/day, km/month)
- Expenses (fuel, maintenance, crew, rent, total)
- Income, margin, margin/student
- Average/max ride
- Average/max walk
- Capacity utilization
- Safety flags
- Change count vs current

**Process**
1. Select 2–N plans (live/draft).
2. Choose a baseline.
3. Compute metrics and deltas.
4. Show table + maps.
5. Highlight best/worst.
6. Save/export.

**Rules**
- Same fare/cost assumptions for all plans; differences are displayed.
- Estimated values labelled.
- A plan with missing data shows “unknown”, not zero.
- Comparison never edits a plan.
- Saved comparisons are immutable snapshots (recompute on demand with a new version).

**Acceptance**
1. Compare Junior, Senior and a merged scenario.
2. See Δstudents, Δbuses, Δkm, Δcost, Δincome, Δmargin, Δride, Δwalk.
3. Maps show all three.
4. Export is decision-ready.

### Condition 4 — Everything stays in Draft until a decision

**Intent:** No AI or planner change reaches buses without human approval.

**States and who can act**
| State | Who can move it | Next |
|---|---|---|
| Draft | Planner/engine | Submit, Cancel, Archive |
| InReview | Approver | Approve, Reject, Comment |
| Approved | Transport Manager/Principal | Schedule, Publish, Cancel |
| Scheduled | Scheduler/system | Publish on date, Cancel |
| Published | System | Supersede, Rollback |
| Rejected | Planner | Clone/revise, Archive |
| Cancelled | Planner/approver | Archive |
| Archived | — | Read-only |
| RolledBack | — | Read-only |

**Rules**
- A draft is fully isolated; live tables untouched.
- Submit freezes children.
- Approve/reject is audited.
- No partial publish.
- A rejected/cancelled plan is retained, not deleted.
- A published plan is never edited; a new plan supersedes it.

**Acceptance**
1. Generate a plan; live data unchanged.
2. Submit; editing blocked.
3. Reject; live unchanged, reason stored.
4. Approve and publish; live changes.
5. Cancel/Archive from allowed states.
6. No endpoint can bypass the lifecycle.

### Condition 5 — Approval sets classes and date range

**Intent:** A plan is not global by accident; it applies to named classes for named dates.

**Process**
1. Approver opens the plan.
2. Sees proposed scope (from generation).
3. Selects classes/sections (all or partial).
4. Sets effective_from/to.
5. System checks overlap with published/scheduled plans.
6. Approver confirms.
7. Plan becomes Approved with applicability rows.

**Rules**
- At least one class/section and a valid date range are required.
- Date range inside the academic session.
- Overlap blocked unless the school explicitly allows priority override.
- Section mapping overrides class mapping.
- The applicability is part of the approval audit.
- A plan can be approved now and scheduled later.

**Acceptance**
1. Approve for classes 1–5, 1 Nov–31 Mar.
2. Overlap with an existing plan is blocked with the conflict named.
3. Section-level override works.
4. Current view resolves one plan per student.
5. Approval audit shows the mapping.

### Condition 6 — Move the existing plan for the same classes/date range to history

**Intent:** When a new plan replaces an old one, the old network must remain explainable for billing and disputes.

**Process**
1. Identify Published plan(s) overlapping the new plan’s classes/date range.
2. End-date their applicability at the day before the new effective date.
3. Copy their live routes, stops, route-stops, allocations and assignments to history with `plan_publication_id`.
4. Mark the old plan Superseded (or end-dated if only partially replaced).
5. Keep billing rows pointing to the old publication.
6. Notify affected parents/crew.

**Rules**
- History is immutable and self-contained.
- History survives deletion of live rows.
- Billing can reconstruct the fare/route/stop in force on any date.
- A partial class/date overlap only archives the affected rows; other classes continue.
- A plan can be superseded by a seasonal plan without losing the old one.
- History retention ≥ statutory/billing period (default 8 years; configurable).

**Acceptance**
1. Publish Winter over Summer; Summer routes/allocations in history with 31 Oct end.
2. October invoice resolves to Summer publication.
3. A class not covered by Winter continues on Summer.
4. “Network as of 15 Oct” report reconstructs Summer.
5. History cannot be edited.

### Condition 7 — Add the approved plan to current tables and current view

**Intent:** Once approved and published, the plan becomes what students, parents, admin and transport see.

**Current tables**
- `tpt_route`
- `tpt_pickup_points`
- `tpt_pickup_points_route_jnt`
- `tpt_student_route_allocation_jnt`
- `tpt_driver_route_vehicle_jnt`
- `tpt_route_scheduler_jnt`

**Process**
1. Promote new stops.
2. Insert/update routes and route-stops.
3. Insert assignments.
4. Update allocations.
5. Rewrite roster for future dates.
6. Mark plan Published; supersede old.
7. Publish current view.
8. Notify.

**Rules**
- Atomic.
- Drift guard.
- Snapshot before/after.
- No hard delete.
- No change to trips/boarding/incidents/fees.
- Current view filters Published + date + class.
- A student sees exactly one plan.
- Admin can preview future plans without affecting current.

**Acceptance**
1. Publish; current tables match plan.
2. Parent sees new stop/time on the effective date.
3. Transport sees new roster.
4. Admin sees plan history and current.
5. A failed publish leaves the old network intact.

### Condition 8 — Optimization advice and multi-plan operations

#### 8.1 Suggestions to optimize existing routes and stops
- Advisor analyses live data and proposes transfer/merge/split/cluster/reorder/right-size/fare/rent/maintenance actions.
- Each has ₹/km/min impact, affected students, zero-harm guard.
- Prime can turn advice into a draft plan; Standard can only display it.
- Accepted advice is measured in the ledger.

#### 8.2 Multiple transport plans by need
- Junior, Senior, Sports Academy, Staff, Event.
- Each has its own type, scope, dates, billing and constraints.
- Concurrent publication for different scopes.
- One plan per student/direction/date.

#### 8.3 Seasonal/timing plans
- Winter/Summer plans with different times/routes.
- Scheduled transition.
- History preserves old timing.
- Parent notice.

#### 8.4 Billable/non-billable plans
- Plan-level flag and billing mode.
- Non-billable still costs/P&L.
- Switching starts/stops billing from effective date.
- No retroactive invoice changes.

#### 8.5 Separate late/penalty billing and accounting
- Routine invoice vs late fee vs penalty vs damage.
- Separate invoice types and numbers.
- Waiver/credit note.
- Accounting voucher per type.
- Plan/publication id on every voucher.
- Reconciliation report.

**Acceptance for Condition 8**
1. Advisor finds an optimization; apply creates a draft; approve/publish changes live; ledger measures.
2. Junior and Senior plans run concurrently.
3. Winter plan publishes on 1 Nov and changes times.
4. A non-billable Sports plan produces no invoice but shows cost.
5. A late fee is a separate invoice and a separate accounting voucher.
6. A plan-level revenue report reconciles to Accounting.

---

## 7. Business rules register

### 7.1 Foundation rules (canonical)

| ID | Rule | Source |
|---|---|---|
| BR-TPT-001 | Allocation blocked at 100% vehicle capacity; warning at 90% (configurable). | FRD / code |
| BR-TPT-002 | Vehicle with any expired mandatory document is unavailable and not assignable to a new trip. | FRD |
| BR-TPT-003 | Driver with expired licence is not assignable as primary driver. | FRD |
| BR-TPT-004 | Police verification missing is flagged; block-vs-warn is a school policy (default block for pre-primary). | FRD / spec |
| BR-TPT-005 | Trip status is one-directional: Scheduled → InTransit → Completed → Approved; Cancelled from Scheduled/InTransit. | FRD / spec |
| BR-TPT-006 | Only trip-approval permission may approve; approval is timestamped and attributed. | FRD |
| BR-TPT-007 | Failed critical inspection auto-raises a service request and sets vehicle unavailable. | FRD / spec |
| BR-TPT-008 | Maintenance only from an approved service request; no direct creation. | FRD / spec |
| BR-TPT-009 | One active allocation per student per session per direction/date; new allocation ends the prior atomically. | FRD |
| BR-TPT-010 | Fuel entries default Pending; only Manager/Admin approve; rejected entries keep a reason. | FRD |
| BR-TPT-011 | Transport fee is per billing period; mid-period proration is plan-configurable. | FRD |
| BR-TPT-012 | Approved maintenance raises a vendor bill for leased/rented vehicles. | FRD / spec |
| BR-TPT-013 | Trip approval raises a vendor usage log when the school setting is on and the vehicle is leased/rented. | FRD / spec |
| BR-TPT-014 | Boarding scan valid only with active allocation, matching stop, active device; duplicate flagged. | FRD |
| BR-TPT-015 | Shift/route/stop codes and names are unique within their scope. | FRD / spec |
| BR-TPT-016 | A stop appears on a route only once; ordinal sequence is gap-free from 1. | FRD / spec |
| BR-TPT-017 | No overlapping driver/vehicle assignment for the same shift/route/direction; vehicle also cannot overlap across shifts. | FRD / spec |
| BR-TPT-018 | Roster must not double-book a vehicle, driver or helper on the same date/shift/direction. | FRD / spec |
| BR-TPT-019 | One driver attendance record per day; work minutes from first-in/last-out. | FRD |
| BR-TPT-020 | Late fee = rule-based (fixed, percentage, per-day or slab); net = gross − waiver. | FRD / spec |
| BR-TPT-021 | Aadhaar/ID, licence numbers and device tokens are encrypted at rest and masked in UI. | FRD |
| BR-TPT-022 | Transport screens require the tenant to be subscribed to the Transport module. | FRD |
| BR-TPT-023 | Every transport payment is recorded in the cross-module payment audit log. | FRD |
| BR-TPT-024 | GPS/location data is tenant-isolated, retained for a limited period, and parent-scoped to own child. | FRD |
| BR-TPT-025 | Out-of-service date restores vehicle availability only when documents are valid. | FRD / spec |
| BR-TPT-026 | Scan/GPS endpoints are rate-limited per device. | FRD |
| BR-TPT-027 | Only a passed same-day inspection allows a trip to become InTransit. | Spec (12) |
| BR-TPT-028 | End odometer > start odometer; start odometer within 5 km of last end (hard block beyond). | Spec (19) |
| BR-TPT-029 | A vehicle already InTransit cannot start another trip. | Spec (19) |
| BR-TPT-030 | Stop N cannot be reached before N−1; GPS within 50 m may auto-arrive. | Spec (20) |
| BR-TPT-031 | Emergency stop requires remarks and raises a HIGH alert. | Spec (20) |
| BR-TPT-032 | One boarding row per student per trip/direction; 15-second duplicate window. | Spec (22) |
| BR-TPT-033 | HIGH incident triggers immediate multi-channel escalation; resolution requires action taken. | Spec (23) |
| BR-TPT-034 | Fee generation is idempotent per student/period; re-run creates only missing invoices. | Spec (26) |
| BR-TPT-035 | Waiver ≤ charge; waiver requires a reason; paid invoice cannot be revised. | Spec (27) |
| BR-TPT-036 | Paid amount ≤ outstanding; cheque starts Processing; reversal is a new negative entry. | Spec (28/29) |
| BR-TPT-037 | Fee log is immutable; corrections are reversals with negative amounts. | Spec (29) |
| BR-TPT-038 | Approved maintenance is read-only; approved records cannot be edited. | Spec (15) |
| BR-TPT-039 | Deactivating a stop used by an active route is blocked until the plan removes it. | Spec (06) |
| BR-TPT-040 | A plan cannot be published without class/section applicability and a valid date range. | This brief |
| BR-TPT-041 | A published plan is immutable; changes require a new plan that supersedes it. | This brief |
| BR-TPT-042 | Publishing and rollback are atomic and snapshot-guarded. | This brief |
| BR-TPT-043 | Current views show only Published plans in force today; history is never current. | This brief |
| BR-TPT-044 | Every invoice/charge/payment carries plan and publication id for audit. | This brief |
| BR-TPT-045 | Accounting posting is idempotent and retried; failures are visible. | This brief |
| BR-TPT-046 | No engine or Advisor output writes live tables directly. | This brief |
| BR-TPT-047 | Missing coordinates are NULL and flagged; never a default city. | Audit |
| BR-TPT-048 | Import matches students by admission number or class+section+roll+current session, never roll alone. | Audit B3 |
| BR-TPT-049 | Collecting a transport fee must never deactivate a student in the ERP. | Audit B1 |
| BR-TPT-050 | Web and mobile fine calculation must use the same signed day difference. | Audit B2 |

### 7.2 Standard rules

| ID | Rule |
|---|---|
| BR-STD-001 | Standard never generates routes or creates machine proposals; it advises and compares only. |
| BR-STD-002 | Advisor runs in the background and persists suggestions; page load reads stored results. |
| BR-STD-003 | A failing rule is isolated; it cannot blank the page or stop other rules. |
| BR-STD-004 | Every suggestion has a calculation trace and a ₹/km/min impact with unit. |
| BR-STD-005 | Money assumptions are settings, not hard-coded constants. |
| BR-STD-006 | Both-direction fares split 50/50 to avoid double counting. |
| BR-STD-007 | Only approved fuel/maintenance count in P&L. |
| BR-STD-008 | Estimated distances/times/costs are labelled “Estimated”; measured are labelled “Measured”. |
| BR-STD-009 | Zero-harm guard: no advice may flip a profitable route to loss, worsen a loss by >10%, or exceed capacity. |
| BR-STD-010 | Walk distance after any advice must be ≤ the school limit. |
| BR-STD-011 | Safety flags override savings. |
| BR-STD-012 | Blocked advice is shown with the reason, never hidden. |
| BR-STD-013 | Suggestion lifecycle: Open → Accepted/Dismissed/Snoozed → Resolved/Expired. |
| BR-STD-014 | Accepting advice in Standard does not change live data. |
| BR-STD-015 | Dedupe by fingerprint; a fixed issue resolves its suggestion. |
| BR-STD-016 | Savings ledger separates predicted and measured; never combines them. |
| BR-STD-017 | Route map uses self-hosted assets; no public tile/router dependency. |
| BR-STD-018 | Standard reads live and draft plans but never edits live outside Foundation services. |
| BR-STD-019 | Comparison uses the same assumptions for all plans; missing data shows “unknown”. |
| BR-STD-020 | Standard has its own licence key and menu; it does not silently inherit Transport. |

### 7.3 Prime rules

| ID | Rule |
|---|---|
| BR-PRM-001 | A plan is always Draft until submitted; only Draft is editable. |
| BR-PRM-002 | AI/engine output never writes live tables; publish is the only writer. |
| BR-PRM-003 | Publish requires approval, class/section applicability, date range, drift check and snapshot. |
| BR-PRM-004 | One Published plan per class/section/direction/date; overlap blocked. |
| BR-PRM-005 | Superseded plans are archived to history with effective_to = day before new plan. |
| BR-PRM-006 | History rows are immutable and survive live-row deletion. |
| BR-PRM-007 | Billing references plan publication and allocation history. |
| BR-PRM-008 | Rollback requires after-publish drift check and restores the superseded plan. |
| BR-PRM-009 | Removed routes/stops are deactivated, never hard-deleted. |
| BR-PRM-010 | Trips, boarding logs, incidents and fees are never touched by publish/rollback. |
| BR-PRM-011 | Roster is rewritten only for touched routes and future dates; dates with trips are skipped. |
| BR-PRM-012 | Max ride and max walk are hard constraints; violations make the plan infeasible. |
| BR-PRM-013 | School arrival deadline is a hard constraint with buffer. |
| BR-PRM-014 | Capacity is a hard constraint; standing/extra requires an explicit setting. |
| BR-PRM-015 | A vehicle cannot be double-booked across overlapping shifts. |
| BR-PRM-016 | Stops without coordinates are never used by the engine. |
| BR-PRM-017 | Student geo requires consent; no consent, no point. |
| BR-PRM-018 | The engine stores the exact constraints and objective used. |
| BR-PRM-019 | Infeasibility names the binding constraint and unserved students. |
| BR-PRM-020 | Generation runs as a queued job with progress, cancel and safe failure. |
| BR-PRM-021 | A newer run supersedes an older run for the same scope. |
| BR-PRM-022 | Locks are hard constraints; an infeasible lock is reported. |
| BR-PRM-023 | Comparison covers students, routes, buses, km, cost, income, margin, ride, walk and safety. |
| BR-PRM-024 | Non-billable plans produce no routine invoice but still cost/P&L. |
| BR-PRM-025 | Late fees/penalties are separate invoices and separate accounting vouchers. |
| BR-PRM-026 | A plan switch starts/stops billing from the effective date; prior invoices unchanged. |
| BR-PRM-027 | Accounting posting carries plan/publication id and is idempotent. |
| BR-PRM-028 | Scheduled publish re-checks drift; failure returns the plan to Approved with a reason. |
| BR-PRM-029 | Disruption overrides are date-only and reversible. |
| BR-PRM-030 | ETA and parent alerts are scoped to the parent’s own child and active trip. |

---

## 8. Workflows

### 8.1 Stop generation (Prime)

```
Select session + class group + shift + direction
  → load consented student points
  → reuse safe existing stops
  → cluster remaining points
  → place proposed stops at safe centroids
  → enforce max walk; list unservable
  → merge/split clusters
  → classify Keep/Add/Merge/Split/Remove
  → save candidates (+ optional draft plan)
  → map preview + CSV
  → planner reviews and accepts/rejects
```

**Exceptions:** no consent, no coordinates, school location missing, all students in walk zone, cluster too large, unsafe centroid, max stops reached.

### 8.2 Route generation (Prime)

```
Select plan + shift + direction + objective + constraints
  → validate session/plan/fleet/demand
  → build distance matrix
  → assign students to stops
  → solve VRP (capacity, ride, arrival, locks)
  → order stops and build geometry
  → compute schedule and P&L
  → write draft plan + allocations
  → report unserved + constraint proof
  → planner reviews / edits / compares
```

**Exceptions:** demand > capacity, missing coordinates, missing fares, solver timeout, OSRM down, infeasible constraints, too many rounds.

### 8.3 Plan review and approval

```
Draft → Submit → InReview
  → approver opens live-vs-plan map + KPI diff
  → comments per route
  → approve (sets classes + date range) or reject (reason)
  → Approved / Rejected
  → audit row
```

### 8.4 Publish and history

```
Approved
  → drift check
  → preflight
  → snapshot before
  → promote new stops
  → routes: remove/deactivate, add, change
  → route-stops
  → assignments
  → allocations
  → supersede old plan + archive history
  → mark Published
  → snapshot after
  → roster for future dates
  → notifications
  → audit
```

### 8.5 Rollback

```
Published plan
  → after-publish drift check
  → undo roster newest first
  → restore before-snapshot rows
  → remove created rows (delete/soft-delete)
  → restore superseded plan to Published
  → mark RolledBack
  → notify + audit
```

### 8.6 Billing (routine + late/penalty + accounting)

```
Monthly run
  → active billable allocations
  → fare master/allocation fare
  → proration
  → invoice (Regular)
  → due date
  → payment(s)
  → if overdue: charge (LateFee/Penalty) per rule
  → separate invoice (LateFee/Penalty)
  → waiver/credit note if approved
  → accounting outbox per invoice/payment/charge
  → reconciliation report
```

### 8.7 Advisor suggestion → action

```
Nightly/refresh run
  → context preload
  → rules evaluate
  → suggestions persisted/deduped
  → page reads stored suggestions
  → user accepts/dismisses/snoozes
  → Standard: record only
  → Prime: create draft plan from action
  → review/approve/publish
  → ledger measures 30/60/90 days
```

### 8.8 Disruption re-plan (Prime)

```
Event: vehicle down / driver absent / road closed
  → build ranked options (spare, nearby route, split, cancel)
  → show capacity/delay/cost
  → choose option
  → write date-only roster override
  → notify parents/crew
  → revert at end of day
```

### 8.9 Seasonal plan switch (Prime)

```
Winter plan Approved/Scheduled
  → on effective date: drift check
  → publish
  → archive Summer
  → switch current view
  → notify parents of timing change
```

### 8.10 Student allocation change

```
Parent/staff request
  → validate route membership, capacity, walk
  → approve/reject
  → end prior allocation, create new from effective date
  → update fare for future billing
  → notify parent
```

### 8.11 Boarding and trip

```
Trip scheduled from roster
  → driver starts (inspection + available vehicle)
  → stop events + scans
  → boarding/unboarding + parent alerts
  → trip completes
  → approval
  → vendor usage (if applicable)
  → reports/ETA learning
```

---

## 9. Data requirements

### 9.1 Entity catalogue

| Entity | Key data | Retention | Privacy | Tier |
|---|---|---|---|---|
| Plan | code, type, session, status, dates, billing flags, KPI, baseline hash | Permanent | Internal | F |
| Plan applicability | plan, class, section, dates, priority | Permanent | Internal | F |
| Route | plan, shift, direction, geometry, distance, duration | Permanent | Internal | F |
| Stop | code, name, lat/lng, geocode status, safety flags | Permanent | Internal | F |
| Route-stop | route, stop, ordinal, times, fares | Permanent | Internal | F |
| Fare | plan, route, stop, class, direction, fare, dates | 8 years | Internal | F |
| Vehicle | registration, capacity, ownership, vendor, depot, cost/km | Permanent | Internal | F |
| Compliance document | entity, type, number, validity, media | 8 years after expiry | Confidential | F |
| Personnel | role, licence, experience, verification, encrypted ID | Employment + 8 years | Sensitive | F |
| Assignment | shift, route, vehicle, driver, helper, dates | Permanent | Internal | F |
| Roster | date, shift, route, vehicle, crew | 8 years | Internal | F |
| Trip | date, route, vehicle, crew, odometer, fuel, status, approval | 8 years | Internal | F |
| Trip stop detail | stop, scheduled/actual, emergency | 8 years | Internal | F |
| Incident | type, severity, location, description, resolution | 8 years | Confidential | F |
| Attendance device | person, UUID, model, FCM token | Life of device + 1 year | Confidential | F |
| Driver attendance | date, in/out, minutes, status | 8 years | Internal | F |
| Boarding log | student, trip, stop, time, device | 8 years | Confidential (child movement) | F |
| Student event log | student, event, time, metadata | 8 years | Confidential | F |
| Allocation | student, session, plan, routes/stops, fare, dates | 8 years | Confidential (student) | F |
| Stop-change request | student, current/requested, status | 8 years | Confidential | F |
| Fuel | vehicle, date, litres, cost, odometer, approval | 8 years | Internal | F |
| Inspection | vehicle, checklist, result, issues | 8 years | Internal | F |
| Service request | vehicle, inspection, reason, approval | 8 years | Internal | F |
| Maintenance | vehicle, request, cost, workshop, dates | 8 years | Internal | F |
| Invoice | student, plan, publication, period, amounts, status | 8 years | Confidential (financial) | F |
| Invoice line | type, reference, amount | 8 years | Confidential | F |
| Charge | student, type, amount, waiver, status | 8 years | Confidential | F |
| Payment | invoice, amount, mode, reference, status | 8 years | Confidential | F |
| Accounting posting | source, voucher, amount, status | 8 years | Confidential | F |
| Notification log | recipient, type, channels, status | 2 years | Confidential | F |
| GPS point | vehicle, trip, lat/lng, speed, time | 180 days (config) | Sensitive | F |
| GPS alert | type, vehicle, driver, time, ack | 2 years | Sensitive | F |
| Plan draft route | plan, source route, change kind | Life of plan + 1 year | Internal | F |
| Plan new stop | plan, lat/lng, reason, promoted id | Life of plan + 1 year | Internal | F |
| Plan allocation | plan, student, routes/stops, walk, ride | Life of plan + 1 year | Confidential | F |
| Plan review | step, decision, comment, user, time | Permanent | Internal | F |
| Plan snapshot | scope, payload, checksum | Permanent | Internal | F |
| Plan publication | plan, version, dates, user, hashes | Permanent | Internal | F |
| History (route/stop/allocation/assignment) | archived copy + publication | 8 years+ | Internal/Confidential | F |
| Advisor settings | rule, enabled, severity, params | Life of tenant | Internal | S |
| Advisor run | trigger, status, counts, error | 2 years | Internal | S |
| Advisor suggestion | rule, target, text, impact, status | 3 years | Internal | S |
| Suggestion outcome | decision, baseline, measured | 8 years | Internal | S |
| Savings ledger | baseline/actual/saving/confidence | 8 years | Internal | S/P |
| Student geo | student, lat/lng, address, consent | Until consent withdrawn + 1 year | Sensitive | P |
| Distance matrix | point pair, distance, time, source | Cache (rebuildable) | Internal | P |
| Segment speed | stop pair, band, speed, samples | 2 years | Internal | P |
| Engine run | type, status, progress, input/output | 2 years | Internal | P |
| Stop generation run | params, counts, status | 2 years | Internal | P |
| Stop candidate | cluster, point, students, walk, decision | 2 years | Internal | P |
| Plan constraint | plan, code, scope, value, hard | Life of plan | Internal | P |
| ETA live | trip, stop, eta, delay, status | Transient (trip + 7 days) | Confidential | P |
| Disruption | type, route, window, options, status | 3 years | Internal | P |
| Admission quote | enquiry, address, stop, fare, result | 2 years | Confidential | P |
| Safety rule | code, threshold, severity, penalty | Life of tenant | Internal | P |
| Safety score | entity, period, score, breakdown | 8 years | Confidential | P |
| Domain event outbox | event, aggregate, payload, status | 30 days after processed | Internal | F |

### 9.2 Data quality rules

1. A stop without coordinates is `Pending`, excluded from distance/fare/route generation.
2. A student without consent/geo is excluded from Prime generation and listed.
3. A billable allocation without fare blocks billing for that student and lists the gap.
4. Trip odometer 0/missing is flagged; distance is not trusted; P&L uses fuel-log distance.
5. Fuel/maintenance not approved is excluded from P&L.
6. Route geometry missing = map warning + estimated path label.
7. Duplicate allocation (same student/session/direction/date) is a data error.
8. A route with a stop outside the shift window is a validation error.
9. A plan with an unresolved HIGH data issue cannot be approved without an override reason.
10. Import never silently skips a row.

### 9.3 Privacy and consent

- Student home coordinates are sensitive personal data under DPDP; consent is explicit and revocable.
- Parents see only their own child; staff see only what their role requires.
- GPS retention default 180 days; boarding/trip 8 years.
- Aadhaar/licence encrypted at rest, masked in UI, access logged.
- Data export is permissioned and logged.
- Cross-tenant access is impossible by design (per-tenant DB).
- A consent withdrawal removes the point from future generation but preserves historical billing records.

### 9.4 Retention

| Data | Default | Configurable |
|---|---|---|
| Boarding/trip/incident | 8 years | Yes |
| Invoice/payment/charge | 8 years | Yes |
| Plan/publication/history | Permanent | No |
| GPS points | 180 days | Yes |
| Notification log | 2 years | Yes |
| Advisor suggestion | 3 years | Yes |
| Engine run | 2 years | Yes |
| Student geo | Consent + 1 year | Yes |
| Audit log | 8 years | Yes |

---

## 10. Reporting and analytics

### 10.1 Foundation reports (from FRD)

| ID | Report | Audience | Key metrics | Filters |
|---|---|---|---|---|
| RPT-TPT-001 | Route Performance | Transport | Stops covered, on-time %, average delay | Date, route |
| RPT-TPT-002 | Trip Execution | Transport | Trips per route/vehicle, completion rate | Date, route, vehicle |
| RPT-TPT-003 | Vehicle Usage | Transport | Km, fuel, cost/km | Date, vehicle |
| RPT-TPT-004 | Driver Performance | Transport | Attendance, punctuality, incidents | Date, driver |
| RPT-TPT-005 | Boarding Attendance | Transport | Boarded/unboarded per route/student | Date, route, student |
| RPT-TPT-006 | Student Transport Usage | Transport | Trips, routes, boarding count | Date, student |
| RPT-TPT-007 | Finance & Leakage | Accountant | Billed, collected, waived, outstanding, cost recovery | Date, route |
| RPT-TPT-008 | Stop Analysis | Transport | Students per stop, utilization | Date, route |
| RPT-TPT-009 | Cost & Maintenance | Transport | Maintenance cost, downtime, next due | Date, vehicle |
| RPT-TPT-010 | Management Summary | Admin | Fleet, trips, attendance, incidents, CRR, NOB | Date/session |
| RPT-TPT-011 | Notification Delivery | Transport | Delivery rate per channel/type | Date, channel |

### 10.2 Standard reports

| ID | Report | Key metrics |
|---|---|---|
| RPT-STD-001 | Route Profitability | Income, variable/fixed cost, margin, cost/student, confidence |
| RPT-STD-002 | Bus P&L | Revenue, fuel, maintenance, rent, crew, margin |
| RPT-STD-003 | Stop Profitability | Students, fare, walk, detour cost, margin |
| RPT-STD-004 | Savings Ledger | Predicted vs measured savings, confidence |
| RPT-STD-005 | Capacity Heatmap | Load %, overload, underuse, unmet demand |
| RPT-STD-006 | Route Health | Long ride, zig-zag, unsafe stop, missing helper, inspection |
| RPT-STD-007 | Plan Comparison | Students, routes, buses, km, cost, income, margin, ride, walk |
| RPT-STD-008 | Data Confidence | Missing coordinates, fares, salary, odometer, fuel |

### 10.3 Prime reports

| ID | Report | Key metrics |
|---|---|---|
| RPT-PRM-001 | Plan KPI History | KPI per plan/publication over time |
| RPT-PRM-002 | Publish/Rollback Audit | Who, when, what changed, snapshot ids |
| RPT-PRM-003 | Stop Generation Analysis | Clusters, proposed/kept/merged/split, unserved, walk distribution |
| RPT-PRM-004 | Route Generation Constraint Proof | Each hard constraint, satisfied/violated, binding constraint |
| RPT-PRM-005 | Unserved Students | Student, reason, nearest stop, walk |
| RPT-PRM-006 | ETA/Delay | Predicted vs actual, delay by stop/route |
| RPT-PRM-007 | Disruption Log | Event, options, choice, impact, notification |
| RPT-PRM-008 | Safety Score | Driver/vehicle/route score, components, trend |
| RPT-PRM-009 | Admission Quotes | Enquiry, address, stop, walk, fare, seat |
| RPT-PRM-010 | Historical Network as of Date | Routes/stops/allocations/publication in force |

---

## 11. Configuration catalogue

| ID | Key | Default | Range | Applies | Description |
|---|---|---|---|---|---|
| CFG-001 | `transport.approval_chain` | `two_step` | one_step/two_step | F | Plan approval chain |
| CFG-002 | `transport.allow_self_approval` | `false` | bool | F | Super Admin exception only |
| CFG-003 | `transport.capacity_warn_pct` | `90` | 50–100 | F | Allocation warning |
| CFG-004 | `transport.allow_extra_students` | `false` | bool | F | Allow over capacity |
| CFG-005 | `transport.proration_policy` | `daily` | full_month/daily/next_cycle | F | Mid-period fee |
| CFG-006 | `transport.billing_day` | `1` | 1–28 | F | Invoice generation day |
| CFG-007 | `transport.due_days` | `15` | 0–60 | F | Due date after invoice |
| CFG-008 | `transport.late_fee_grace_days` | `5` | 0–30 | F | Grace before late fee |
| CFG-009 | `transport.late_fee_max_pct` | `25` | 0–100 | F | Cap as % of invoice |
| CFG-010 | `transport.penalty_cap_amount` | `0` | ≥0 | F | Absolute cap (0 = none) |
| CFG-011 | `transport.student_restriction_enabled` | `true` | bool | F | Allow transport-only restriction |
| CFG-012 | `transport.police_verification_mode` | `warn` | warn/block/block_preprimary | F | Verification policy |
| CFG-013 | `transport.licence_expiry_block_days` | `0` | 0–30 | F | Block new assignment |
| CFG-014 | `transport.document_expiry_alert_days` | `30` | 7–90 | F | Expiry alert |
| CFG-015 | `transport.document_expiry_high_days` | `7` | 1–30 | F | HIGH alert |
| CFG-016 | `transport.trip_odometer_tolerance_km` | `5` | 0–20 | F | Start odometer tolerance |
| CFG-017 | `transport.scan_duplicate_seconds` | `15` | 5–120 | F | Duplicate scan |
| CFG-018 | `transport.auto_arrive_radius_m` | `50` | 10–200 | F | GPS auto-arrival |
| CFG-019 | `transport.gps_retention_days` | `180` | 30–730 | F | GPS retention |
| CFG-020 | `transport.notification_retry_count` | `2` | 0–5 | F | Channel retry |
| CFG-021 | `transport.trip_usage_vendor_log` | `false` | bool | F | Vendor usage on approval |
| CFG-022 | `transport.accounting_posting_mode` | `outbox` | outbox/realtime/manual | F | Accounting mode |
| CFG-023 | `transport.plan_history_retention_years` | `8` | 3–20 | F | History retention |
| CFG-024 | `transport.map_provider` | `self_hosted` | self_hosted | F/S/P | No public map |
| CFG-025 | `transport.distance_source` | `osrm` | osrm/haversine | P | Distance engine |
| CFG-026 | `transport.road_factor` | `1.30` | 1.0–2.0 | P | Haversine fallback |
| CFG-027 | `transport.avg_speed_kmph` | `25` | 10–60 | P | Fallback speed |
| CFG-028 | `transport.max_ride_min_preprimary` | `35` | 15–60 | P | Ride limit |
| CFG-029 | `transport.max_ride_min_primary` | `45` | 20–70 | P | Ride limit |
| CFG-030 | `transport.max_ride_min_middle` | `60` | 30–90 | P | Ride limit |
| CFG-031 | `transport.max_ride_min_senior` | `60` | 30–90 | P | Ride limit |
| CFG-032 | `transport.max_walk_m_preprimary` | `300` | 100–800 | P | Walk limit |
| CFG-033 | `transport.max_walk_m_primary` | `500` | 200–1000 | P | Walk limit |
| CFG-034 | `transport.max_walk_m_senior` | `800` | 300–1500 | P | Walk limit |
| CFG-035 | `transport.near_stop_m` | `150` | 50–500 | P | Reuse existing stop |
| CFG-036 | `transport.home_merge_m` | `80` | 20–200 | P | Share doorstep |
| CFG-037 | `transport.stop_merge_radius_m` | `400` | 100–1000 | P | Merge stops |
| CFG-038 | `transport.stop_min_students` | `3` | 1–20 | P | Minimum per stop |
| CFG-039 | `transport.max_stops_per_route` | `15` | 5–40 | P | Soft stop cap |
| CFG-040 | `transport.school_walk_zone_m` | `650` | 200–1500 | P | No stops near school |
| CFG-041 | `transport.arrival_buffer_min` | `10` | 0–30 | P | School arrival buffer |
| CFG-042 | `transport.shift_turnaround_min` | `30` | 0–120 | P | Bus reuse |
| CFG-043 | `transport.capacity_buffer_pct` | `0` | 0–20 | P | Standing/seats |
| CFG-044 | `transport.optional_stop_penalty` | `1000` | ≥0 | P | Drop tiny stop |
| CFG-045 | `transport.min_route_load_pct` | `20` | 0–100 | P | Underload flag |
| CFG-046 | `transport.min_route_load_floor` | `5` | 1–20 | P | Absolute floor |
| CFG-047 | `transport.max_route_duration_min` | `75` | 30–120 | P | Route duration cap |
| CFG-048 | `transport.max_route_km` | `40` | 5–100 | P | Route distance cap |
| CFG-049 | `transport.objective` | `min_cost` | min_buses/min_km/min_cost/min_max_ride/min_change/composite | P | Optimisation goal |
| CFG-050 | `transport.objective_weights` | `{}` | JSON | P | Composite weights |
| CFG-051 | `transport.solver_time_limit_s` | `120` | 10–600 | P | Solver limit |
| CFG-052 | `transport.solver_rounds` | `3` | 1–10 | P | Shared-stop retries |
| CFG-053 | `transport.lock_enforced` | `true` | bool | P | Locks |
| CFG-054 | `transport.consent_required` | `true` | bool | P | Student geo |
| CFG-055 | `transport.geo_retention_days` | `365` | 30–3650 | P | Student geo |
| CFG-056 | `transport.eta_lead_min` | `10` | 2–30 | P | Approaching alert |
| CFG-057 | `transport.delay_alert_min` | `10` | 2–60 | P | Delayed alert |
| CFG-058 | `transport.safety_weight_docs` | `20` | 0–100 | P | Safety score |
| CFG-059 | `transport.safety_weight_incidents` | `30` | 0–100 | P | Safety score |
| CFG-060 | `transport.safety_weight_overspeed` | `20` | 0–100 | P | Safety score |
| CFG-061 | `transport.advisor_expiry_days` | `30` | 7–90 | S | Advisor |
| CFG-062 | `transport.advisor_stop_merge_m` | `400` | 100–1000 | S | Advisor |
| CFG-063 | `transport.advisor_replace_cost` | `100000` | ≥0 | S | Advisor |
| CFG-064 | `transport.advisor_max_per_rule` | `20` | 1–100 | S | Advisor |
| CFG-065 | `transport.advisor_run_time` | `02:00` | time | S | Nightly run |
| CFG-066 | `transport.pnl_rent_default` | `0` | ≥0 | S/P | P&L |
| CFG-067 | `transport.pnl_insurance_default` | `0` | ≥0 | S/P | P&L |
| CFG-068 | `transport.pnl_depreciation_default` | `0` | ≥0 | S/P | P&L |
| CFG-069 | `transport.pnl_working_days` | `26` | 1–31 | S/P | P&L |
| CFG-070 | `transport.pnl_trips_per_day` | `2` | 1–6 | S/P | P&L |

---

## 12. Non-functional requirements

### 12.1 Performance

| Requirement | Target |
|---|---|
| Plan list load | < 1 s for 500 plans |
| Current transport view | < 500 ms |
| Advisor page (stored) | < 1 s |
| Advisor run | < 10 min for 250 routes (background) |
| Route generation | < 5 min for 250 routes (background) |
| Stop generation | < 2 min for 5,000 points |
| Billing run | < 30 s for 2,000 invoices (background) |
| Boarding scan | < 500 ms |
| Map render | < 2 s for 100 routes |
| Comparison | < 2 s for 3 plans |
| Report export | < 30 s for 10,000 rows |

### 12.2 Scalability

- 10,000 students, 500 stops, 300 routes, 100 vehicles per tenant.
- 1,000 tenants; per-tenant queue isolation.
- GPS 1 point/vehicle/10 s; retention job.
- Partition/archive high-volume logs by year.

### 12.3 Availability and resilience

- Publish/rollback atomic.
- Engine failure leaves no partial plan.
- Accounting/Notification outage does not block billing; outbox retries.
- OSRM down → estimated fallback, labelled.
- Solver down → clear error; no data corruption.
- Queue worker restart documented; stuck run reaper.

### 12.4 Security

- Tenant isolation; module gate; permission per action.
- No mass assignment; FormRequest validation.
- PII encryption/masking.
- CSRF/XSS/SQLi protections; spatial values bound.
- Rate limiting on scan/GPS.
- Audit trail for sensitive actions.
- Secrets (map keys, FCM) not in views.
- File upload validation for documents.

### 12.5 Privacy

- Consent for student geo.
- Parent scoping.
- Retention and deletion.
- Access logging.
- Data minimisation (no home pins in Standard).

### 12.6 Usability

- Mobile-first for driver/helper.
- Map-based stop/route editing.
- Clear empty/error states.
- Explainable suggestions with “Why?”.
- Accessible forms and keyboard navigation.
- Localisation-ready strings; ₹ Indian grouping.

### 12.7 Auditability

- Every plan step, publish, rollback, approval, fee, waiver, maintenance, allocation change logged.
- History reconstructs any date.
- Exportable evidence pack for RTO/board.
- Snapshot checksums.

### 12.8 Maintainability

- Shared Foundation services; no forks.
- Service layer for money/plan paths.
- Unit/feature tests for all money and publish paths.
- Static analysis and lint.
- Versioned APIs.
- Runbooks.

---

## 13. Foundation / Standard / Prime mapping

| Capability | FND | STD | PRM |
|---|:---:|:---:|:---:|
| Masters and network | ● | ○ | ○ |
| Roster/trips/boarding | ● | ○ | ○ |
| Inspection/maintenance/fuel | ● | ○ | ○ |
| Allocation/stop change | ● | ○ | ○ |
| Billing/accounting | ● | ○ | ○ |
| Plan lifecycle/publish/history | ● | ○ | ○ |
| Class/date applicability | ● | ○ | ○ |
| Complete route map |  | ● | ● |
| Advisor rules |  | ● | ● |
| P&L and loss recovery |  | ● | ● |
| Manual plan builder |  | ● | ● |
| Plan comparison (live/manual) |  | ● | ● |
| Savings ledger |  | ● | ● |
| Student geo/consent |  |  | ● |
| Auto stop generation |  |  | ● |
| Auto route generation |  |  | ● |
| Constraint engine |  |  | ● |
| Multi-plan/scenario comparison |  |  | ● |
| What-if lab |  | ● (read-only) | ● |
| Locks/partial regeneration |  |  | ● |
| Scheduled publish |  |  | ● |
| ETA/disruptions |  |  | ● |
| Safety score |  |  | ● |
| Admission quote |  |  | ● |

---

## 14. Conflict resolution register

These conflicts exist across the source documents. The resolution below is canonical for the final design.

| # | Conflict | Sources | Resolution |
|---:|---|---|---|
| 1 | Trip status names: `In Progress` vs `In-Transit` vs `Ongoing` | FRD, screen specs, code | Canonical enum: `Scheduled`, `InTransit`, `Completed`, `Cancelled`, `Approved`. UI may label “In Progress”; code uses `InTransit`. |
| 2 | Fine formula: fixed amount vs days × rate | FRD BR-020, spec 10 | Canonical: `calc_type` = Fixed (one amount), PerDay (days × rate), Percentage (outstanding × rate/100), Slab. Default for late fee: PerDay with grace and cap. |
| 3 | Driver experience: 24 months vs 12 months novice | Spec 03, Advisor R09 | Canonical: 24 months minimum to be assignable as primary driver (school-configurable); Advisor flags <12 months on long routes. |
| 4 | Police verification: block vs warn | FRD BR-004, spec 03 | Canonical: configurable; default warn + flag; block for pre-primary and for routes with a girl’s last drop. |
| 5 | Boarding: one row per trip vs one row per date | FRD, spec 22 | Canonical: one row per student per trip per direction. The UI may show a daily summary; the data keeps trip-level rows for audit. Duplicate window 15 s. |
| 6 | Duplicate scan window: 15 s vs 2 min | Spec 22, Advisor R13 | Canonical: 15 s operational block; Advisor flags repeat patterns within 2 min. |
| 7 | Service request must link to inspection vs manual faults | Spec 13, real operations | Canonical: auto-created requests always link to an inspection; manual fault requests allowed with a reason and a nullable inspection link (configurable to require). |
| 8 | Stop deactivation blocked vs plan removal | Spec 06, plan lifecycle | Canonical: a stop cannot be deactivated while an active current route uses it; plan publish deactivates the route-stop link first, then the stop if unused. |
| 9 | Route/stop name unique globally vs per plan | DDL v2.3/v2.7 | Canonical: stop code/name unique per tenant; route code/name unique per plan (same corridor may exist in two plans). |
| 10 | Vendor required for all vehicles vs only leased/rented | DDL (NOT NULL), spec 02 | Canonical: vendor nullable; required when ownership is Leased/Rented. |
| 11 | `tpt_transport_plan` vs `ptr_plans` | v2.7 DDL, Prime DDL | Canonical: one plan header `tpt_transport_plan`; Prime drafts use the same header + `tpt_plan_*` children; `ptr_plans` is deprecated/migrated. |
| 12 | Proposal tables vs plan tables | v2.7, Prime | Canonical: `tpt_route_proposal_*` and `ptr_plans/ptr_plan_*` are replaced by `tpt_transport_plan` + `tpt_plan_*`. One lifecycle, one history anchor. |
| 13 | History tied to proposal vs publication | v2.7, Prime | Canonical: history is anchored to `tpt_plan_publication`, not to a proposal. This survives live-row deletion. |
| 14 | `usr_users` vs `sys_users` | v2.7 DDL | Canonical: `sys_users`. All FKs corrected. |
| 15 | `tpt_students` / `tpt_student_session` / `tpt_routes` references | v2.3/v2.7 boarding/notification DDL | Canonical: `std_students`, `std_student_academic_sessions`, `tpt_route`. All FKs corrected. |
| 16 | `route_id` FK in allocation but no column | v2.3/v2.7 DDL | Canonical: columns `pickup_route_id` and `drop_route_id`; remove the phantom `route_id` FK. |
| 17 | `notification_log.stop_id` vs `boarding_stop_id` | v2.3/v2.7 DDL | Canonical: `stop_id` column exists and FK is correct. |
| 18 | `waved_fine_amount` spelling | DDL, spec 27 | Canonical: `waived_fine_amount` in new schema; legacy column retained in the legacy table with a comment/mapping. |
| 19 | `month` DATE vs period start/end | DDL, spec 26 | Canonical: invoice stores `billing_period_from` and `billing_period_to`; legacy `month` kept as first-of-month. |
| 20 | Standard “no proposals” vs SmartTransport proposal code | Brief, code | Canonical: Standard has no proposal tables/actions. Prime owns proposals. SmartTransport’s proposal code is removed in the refactor. |
| 21 | “AI” in v2 vs deterministic Advisor | Brief, design | Canonical: Standard’s Advisor is deterministic rule-based (no LLM). Prime’s engine is optimisation (OR-Tools), not generative AI. Label features accurately. |
| 22 | Fares manual vs derived | Tpt_Analysis G7, spec 25 | Canonical: fares are maintained in a fare master and derived; manual override requires permission and reason. |
| 23 | Odometer zero on trips | How-it-works §10, audit B5 | Canonical: missing odometer stays NULL (not 0), trip distance is flagged, P&L uses fuel-log distance until fixed. |
| 24 | Parent notifications fake | Audit G5 | Canonical: Notification owns delivery; Foundation writes true status; no hard-coded “Sent”. |
| 25 | SmartTransport licence inherits Transport | Audit P1-07 | Canonical: each add-on has its own module key and menu mapping. |

---

## 15. Additional suggestions

These are recommendations beyond the literal brief. Each is optional but high-value.

### 15.1 Architecture and delivery

1. **Collapse the fork before adding features.** Make SmartTransport and PrimeTransport add-ons over Foundation. Delete duplicated CRUD (≈300 files). This removes the “fix twice” risk and makes the two-tier product real.
2. **One plan model.** Unify `tpt_transport_plan`, `ptr_plans`, `tpt_route_proposal_master` into one versioned plan with one history anchor. This is the single biggest simplification.
3. **Publish service as the only writer.** Make it the only code path allowed to touch live `tpt_*` network tables. Add an architecture test that fails if another service writes them.
4. **Feature flags per tier.** Gate Prime engine/ETA/safety behind `prime-transport.*` permissions and a module key, so phases can ship early without exposing half-built UI.
5. **Kill the destructive endpoint.** Remove `autoGenerateAllRoutes` entirely; generation must go through plans.

### 15.2 Data and trust

6. **Data-quality gate before optimisation.** A “Plan readiness” checklist (geocodes, fares, odometers, salaries, documents) should block approval when HIGH gaps exist. This prevents the “garbage in, confident garbage out” failure.
7. **Never invent coordinates.** Missing lat/lng stays NULL; a visible “needs location” queue. This single fix removes a class of absurd routes and fares.
8. **Real road distances.** Self-host OSRM; cache the matrix; label estimates. A school that checks one route on Google Maps must not find a 40% error.
9. **Versioned fare master.** Never hand-type invoice amounts; store fare versions so old invoices remain explainable.
10. **History as a first-class product.** “Network as of date” and “why was this child billed this fare?” should be one-click answers. This is also the audit evidence pack.

### 15.3 AI and optimisation

11. **Explain every recommendation.** Show trigger, formula, inputs, confidence and the exact students affected. Trust is the adoption bottleneck, not solver quality.
12. **Separate predicted from measured savings.** A savings ledger that proves value is the best renewal argument; mixing predicted with actual destroys credibility.
13. **Respect safety over savings.** Encode unsafe crossings, unlit stops, pre-primary walk limits and female-attendant rules as hard constraints. A cheaper route that endangers a child is not an optimisation.
14. **Human-in-the-loop by design.** No auto-publish. Approval must be explicit, with class/date scope and a named approver.
15. **Solver fallback with honesty.** If OSRM/OR-Tools is down, produce an estimated plan and say so. Never silently guess.
16. **What-if for management.** The fastest way to sell a plan is to show three scenarios side by side with ₹ and ride-time deltas.

### 15.4 Operations

17. **Daily disruption mode.** Breakdowns and driver absence are the most common real-world events. A ranked one-day recovery (spare bus, nearby seats, split) is higher value than another annual plan.
18. **Parent ETA and change notices.** A plan change that moves a stop without telling the parent creates a support crisis. Make notification part of publish, not an afterthought.
19. **Admission quote.** “Can we serve this address and at what fare?” is a cross-module wow feature and improves next year’s demand forecast.
20. **Safety score and RTO pack.** Schools increasingly need evidence for inspections. A per-bus/per-driver score with PDF export is a differentiator.

### 15.5 Engineering quality

21. **Test the money and publish paths first.** Unit tests for fare, proration, fine, P&L, zero-harm guard; feature tests for publish/rollback/drift. These are the paths where a bug is a legal or financial incident.
22. **Idempotency everywhere.** Billing runs, payments, accounting postings, vendor usage, notifications and publish must be safe to retry.
23. **Outbox for cross-module writes.** Accounting, Notification and Vendor should not be called inside a DB transaction; use an outbox with retries and visibility.
24. **Observability.** Log plan id, run id, tenant id and correlation id on every engine/publish/billing action. Add a “stuck run” view.
25. **Tenant-scoped cache keys.** The current Smart Advisor cache can leak/stale across tenants if the key is wrong. Include tenant id and data version.
26. **Queue fairness.** One large school must not starve others; use per-tenant queues or fair scheduling.
27. **Documentation and training.** A transport manager needs a one-page “how to publish a plan” and a “what changed for parents” guide. Adoption fails without it.
28. **Deprecation plan.** Once Prime is live, hide SmartTransport’s duplicate menus for new tenants and migrate existing data; keep Standard as the mid-tier product, not a third codebase.

---

## 16. Open decisions

| # | Decision | Recommendation | Owner |
|---:|---|---|---|
| O1 | Is Foundation sold standalone or only as part of Standard? | Sell Foundation as the base; Standard/Prime as add-ons. | Product |
| O2 | Does Standard include the Advisor, or is the Advisor Prime-only? | Include a read-only Advisor in Standard; Prime adds “apply as plan”. | Product |
| O3 | Approval chain: 1-step or 2-step? | 2-step default (Transport Manager → Principal), configurable. | School/Product |
| O4 | Is student geo collection acceptable to schools/parents? | Yes with explicit consent and role-scoped access; make it optional per school. | Legal/Product |
| O5 | OSRM hosting: all-India or regional extracts? | Start with the states of current tenants; add regions on demand. | DevOps |
| O6 | Accounting integration: real-time or batch? | Outbox with near-real-time retry; batch reconciliation report. | Finance/Eng |
| O7 | Billing basis: plan, route, stop, distance or slab? | Support plan/route/stop fare master; distance/slab as a future pricing mode. | Product |
| O8 | What happens when two plans overlap for the same class/date? | Block publish; require explicit priority override with reason. | Product |
| O9 | How long is history retained? | 8 years default, configurable; never delete publication/snapshot. | Finance/Legal |
| O10 | Is SmartTransport retired after Prime? | Keep as Standard tier; remove duplicate CRUD; one codebase. | Product |
| O11 | Does the engine optimise profit or service by default? | Default min cost per student with hard safety; school can choose. | Product |
| O12 | Are home pickups allowed for all ages? | Only pre-primary/primary by default; shared stops for senior. | School |
| O13 | Should late fees be automatic or reviewed? | Automatic draft + review before issue; configurable. | Finance |
| O14 | What is the plan approval SLA / escalation? | 48 h reminder, 5-day escalation to Principal. | School |
| O15 | Data migration window for the three DDLs? | One planned migration with dual-write/read-only freeze; see enhancement plan. | Eng |

---

## 17. Traceability matrix

| Old source | Old ID/feature | New requirement |
|---|---|---|
| FRD | REQ-TPT-001 Shift | FND-003 |
| FRD | REQ-TPT-002 Vehicle | FND-004 |
| FRD | REQ-TPT-003 Route/stop | FND-006/007/008 |
| FRD | REQ-TPT-004 Personnel | FND-005 |
| FRD | REQ-TPT-005 Device | FND-017 |
| FRD | REQ-TPT-006 Fine rules | FND-028 |
| FRD | REQ-TPT-007 Assignment | FND-010 |
| FRD | REQ-TPT-008 Scheduler | FND-011 |
| FRD | REQ-TPT-009 Trips | FND-012/013 |
| FRD | REQ-TPT-010 Incidents | FND-014 |
| FRD | REQ-TPT-011 Boarding | FND-017 |
| FRD | REQ-TPT-012 Driver attendance | FND-018 |
| FRD | REQ-TPT-013 Inspection | FND-019 |
| FRD | REQ-TPT-014 Service/maintenance | FND-019 |
| FRD | REQ-TPT-015 Fuel | FND-020 |
| FRD | REQ-TPT-016 Allocation | FND-015/016 |
| FRD | REQ-TPT-017 Fees | FND-027/028/029/030 |
| FRD | REQ-TPT-018 Notifications | FND-021 |
| FRD | REQ-TPT-019 Expiry alerts | FND-038 |
| FRD | REQ-TPT-020 Reports | FND-031 |
| FRD | REQ-TPT-021 Dashboard | FND-031 |
| FRD | REQ-TPT-022 GPS | FND-037 |
| FRD | REQ-TPT-023 ML optimisation | PRM-004/006 |
| SmartTransport | Route map | STD-001/002 |
| SmartTransport | 68-rule Advisor | STD-003/004 |
| SmartTransport | Cost analysis | STD-005 |
| SmartTransport | 26 loss-recovery strategies | STD-006/007 |
| SmartTransport | Route/stop proposals | STD-007, PRM-019 |
| SmartTransport | Route auto-generation | PRM-004 |
| SmartTransport | Proposal tables | FND-022..025, PRM-008..012 |
| Prime | Student geo | PRM-001 |
| Prime | OR-Tools engine | PRM-004/005/006/007 |
| Prime | Plans/review/publish/rollback | FND-022..025, PRM-008..012/022/023 |
| Prime | Class/date | FND-002, PRM-010 |
| Prime | History | FND-025, PRM-012 |
| Prime | Comparison | STD-008, PRM-009 |
| Prime | Billing/accounting | FND-027..030, PRM-016..018 |
| Prime | ETA/disruption/safety/quote | PRM-025..028 |
| Brief | Condition 1 | PRM-002/003 |
| Brief | Condition 2 | PRM-004/005/006 |
| Brief | Condition 3 | PRM-009 |
| Brief | Condition 4 | FND-023, PRM-008 |
| Brief | Condition 5 | FND-002, PRM-010 |
| Brief | Condition 6 | FND-025, PRM-012 |
| Brief | Condition 7 | FND-024/026, PRM-011/013 |
| Brief | Condition 8 | STD-006/007, PRM-014..019 |

---

## 18. Glossary

| Term | Meaning |
|---|---|
| Allocation | A student’s route + stop for a direction and date range |
| Applicability | Class/section + date range a plan applies to |
| Baseline hash | Fingerprint of the live network used by the drift guard |
| Billing run | Batch that creates invoices for a period |
| Change kind | `unchanged`, `added`, `changed`, `removed` for a plan child |
| Constraint | A school-configured rule the engine must honour |
| Current network | The live rows in `tpt_*` for the published plan |
| Drift guard | Refusal to publish/rollback if live data changed |
| Draft plan | A plan not yet live; children in `tpt_plan_*` |
| Fare master | Versioned fare by plan/route/stop/class/direction |
| History | Immutable archive of a replaced plan |
| Live plan | A Published plan in force today |
| Lock | A pinned route/vehicle/stop/student the engine must not move |
| Objective | What the engine optimises |
| Plan | A versioned, class/date-scoped network |
| Plan type | Regular/Junior/Senior/Sports/Staff/Event |
| Publication | The event/version of a plan going live |
| Proposal | A draft plan created by engine/Advisor/disruption |
| Proration | Mid-period fee calculation |
| Roster | Per-date, per-route execution rows |
| Savings ledger | Predicted vs measured impact of advice |
| Snapshot | JSON copy of live rows for rollback |
| Stop generation | Proposing stops from student coordinates |
| Superseded | A plan replaced by a newer publication |
| Zero-harm guard | Rule that advice cannot harm another route |

---

*End of Consolidated Requirement Document.*
