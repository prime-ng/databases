# Transport Final Analysis — Index

**Folder:** `2-Prime-Ai_V2/9-Enhanced_Modules/Transport/Final_Analysis/`
**Date:** 2026-11-01
**Status:** Analysis complete — no code, schema or live data changed.

This folder consolidates the three Transport generations into a single requirement baseline, a target database schema, and a module-by-module enhancement plan.

---

## Deliverables

| # | File | What it answers |
|---:|---|---|
| 1 | [`01-Consolidated_Requirement_Document.md`](01-Consolidated_Requirement_Document.md) | What the Transport family must do — 40 Foundation requirements, 20 Standard requirements, 35 Prime requirements, the 8 Prime conditions, business rules, workflows, reports, configuration catalogue, conflict resolutions and additional suggestions |
| 2 | [`02-Schema_Evaluation_and_Design.md`](02-Schema_Evaluation_and_Design.md) | How the three DDLs compare, every defect found, the design decisions behind the target schema, the 82-table inventory, old→new mapping, integrity rules and migration sequence |
| 3 | [`02-Final_Transport_DDL_v1.0.sql`](02-Final_Transport_DDL_v1.0.sql) | The final refined tenant schema — 82 tables + 3 current-view helpers, ready to validate on a clean MySQL 8 database |
| 4 | [`03-Transport_Module_Enhancement_Plan.md`](03-Transport_Module_Enhancement_Plan.md) | What to keep, remove and add in each of the three modules; services, jobs, backlog, phases, estimates, risks and definition of done |

---

## The decision in one page

### Product model

```
PRIME TRANSPORT (premium)     Modules/PrimeTransport     ptr_* + tpt_plan_* drafts
        ▲ depends on
STANDARD TRANSPORT (mid)     Modules/SmartTransport     owns tpt_adv_*; reads tpt_* live data
        ▲ depends on
FOUNDATION TRANSPORT (base)  Modules/Transport          tpt_* live network, plans, billing, history
```

- **Foundation** is the only owner of the live network and the only writer of live plan changes.
- **Standard** adds the complete route map, the 68-rule Advisor, P&L and loss-recovery advice, a manual plan builder, comparison and the savings ledger. **No AI route generation, no machine proposals.**
- **Prime** adds automatic stop generation, OR-Tools route generation under school constraints, profitability optimisation, proposals, class/date approval, publish/rollback, comparison, seasonal and multi-plan operations, separate late/penalty billing, accounting, ETA, disruptions, safety scores and admission quotes.

### Schema model

| Prefix | Owner | Contains |
|---|---|---|
| `tpt_` | Foundation | Masters, live network, operations, finance, plan lifecycle, staging, history, Standard Advisor |
| `ptr_` | Prime | Settings, distance cache, student geo, engine runs, stop generation, ETA, disruptions, quotes, safety |

- **One plan header:** `tpt_transport_plan` (draft and live).
- **Draft children:** `tpt_plan_route`, `tpt_plan_new_stop`, `tpt_plan_route_stop`, `tpt_plan_allocation`, `tpt_plan_vehicle_assignment`, `tpt_plan_lock`, `tpt_plan_review`, `tpt_plan_snapshot`.
- **One publication anchor:** `tpt_plan_publication`.
- **Immutable history:** route, stop, route-stop, allocation, assignment, plan version.
- **Plan-aware billing:** fare master, billing run, invoice, charge, payment, accounting outbox.
- **Retired:** `tpt_route_proposal_*`, `ptr_plans`, `ptr_plan_*`, the proposal-keyed history tables and the phantom models.

### Why this fixes the current problems

| Current problem | Fix in this design |
|---|---|
| SmartTransport can wipe every route/trip/incident | Destructive endpoint removed; generation only through plans |
| Proposals can be saved but never approved/published | One lifecycle: Draft → InReview → Approved → Scheduled → Published → Superseded/RolledBack |
| Prime plans cannot publish proposed stops | `tpt_plan_new_stop.promoted_stop_id` is written by publish |
| A stop change can be ignored if the route id is unchanged | Stop-level change kind is computed from route + stop + time + bus |
| No class/date scope | `tpt_transport_plan_class_jnt` + `tpt_transport_plan_shift_jnt`, overlap locked |
| Old plan disappears when a new one is published | Publication-keyed history survives live-row deletion |
| Old invoices cannot be explained | Invoice and charge carry `plan_id` + `plan_publication_id`; allocation history carries the fare |
| Late fee/penalty mixed into routine billing | Separate invoice types, charge records and accounting vouchers |
| Three forked codebases | Standard/Prime become add-ons over Foundation; shared CRUD exists once |
| No tests on money/publish | Money/trip/publish/rollback/solver test plan is Phase 0–1 |

---

## Read in this order

1. **Product/BA:** `01-Consolidated_Requirement_Document.md` — Sections 1–6 for scope and the 8 conditions; Section 7 for rules; Section 15 for suggestions.
2. **Architect/DB:** `02-Schema_Evaluation_and_Design.md` — Sections 2–4 for findings and decisions; Section 5 for table mapping; Section 7 for migration.
3. **Engineer:** `03-Transport_Module_Enhancement_Plan.md` — Sections 4–6 for module work; Section 8 for phases; Section 9 for the backlog.
4. **Everyone:** this index, then the definition of done in the enhancement plan.

---

## Key numbers

| Item | Value |
|---|---:|
| Foundation requirements | 40 |
| Standard requirements | 20 |
| Prime requirements | 35 |
| Business rules (foundation / standard / prime) | 50 / 20 / 30 |
| Final tables | 82 |
| Current views | 3 |
| Foundation reports | 11 |
| Standard reports | 8 |
| Prime reports | 10 |
| Configuration keys | 70 |
| Current Transport files / LOC | 368 / ~70.9K |
| Current SmartTransport files / LOC | 388 / ~89.6K |
| Current PrimeTransport files / LOC | 165 / ~18.5K |
| Fork drift | 342 common paths, 314 modified |
| Existing PHP tests | 0 |
| Estimate to target | ~16 weeks with a small team |

---

## Non-negotiable rules

1. **Foundation is the only writer of the live network.** No module edits `tpt_route`, `tpt_pickup_points_route_jnt`, `tpt_student_route_allocation_jnt` or `tpt_driver_route_vehicle_jnt` outside the publish service.
2. **No AI output goes live without human approval.** Engine and Advisor produce drafts/suggestions only.
3. **Every publish is atomic, drift-guarded and snapshotted.**
4. **History is never destroyed by a live-row delete.**
5. **Every invoice resolves to a plan publication and an allocation history row.**
6. **Missing coordinates, fares and odometers are flagged, never guessed.**
7. **A fee action never deactivates a student in the ERP.**
8. **Each product has its own licence key, menu and permission set.**
9. **Money, publish and rollback paths have automated tests before launch.**
10. **No public map/tile/router dependency in production.**

---

## Immediate next actions

1. Approve the consolidated requirements.
2. Validate the DDL on a clean MySQL 8 tenant database.
3. Delete the destructive SmartTransport endpoint.
4. Fix B1/B2 (fee deactivation, signed fine).
5. Stop the Bangalore coordinate default.
6. Add the module gate and PII encryption.
7. Stand up the self-hosted map/OSRM stack.
8. Build the 500-student fixture school.
9. Create the additive plan/billing migrations.
10. Run the first publish/rollback rehearsal on staging.

---

*This folder is analysis only. No application code, migration or database was modified.*
