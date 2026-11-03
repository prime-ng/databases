# Final Transport Schema — Evaluation and Design Decisions

| Field | Value |
|---|---|
| **Document** | Schema evaluation, consolidation and migration guide |
| **Module family** | Transport (TPT) |
| **Version** | 1.0 — Final Analysis |
| **Date** | 2026-11-01 |
| **Companion DDL** | `02-Final_Transport_DDL_v1.0.sql` (82 tables + 3 views) |
| **Status** | Target-state design — no code or live database changed |

---

## 1. Executive summary

Three schema generations were evaluated:

| Generation | File | Tables (declared) | Verdict |
|---|---|---:|---|
| TPT v1 | `Transport_DDL_v2.3.sql` | 27 | Good operational core; several broken FKs, no plan lifecycle, no billing separation |
| TPT v2 | `Transport_DDL_v2.7.sql` | ~37 | Added transport plan, proposals and history; proposal lifecycle never finished; history tied to a proposal; still broken FKs |
| TPT v3 | `PrimeTransport_DDL_v1.0.sql` | 25 | Strong snapshot/rollback model; parallel plan model duplicates `tpt_transport_plan`; no class/date scope, no billing, several unused tables |
| Live migrations | `database/migrations/tenant` + module folders | 42 shared + 2 Transport + 23 Prime | Source of truth for what actually runs; has drifted from all three DDL files |

### 1.1 Capability matrix

| Capability | v2.3 | v2.7 | Prime v1.0 | Final |
|---|:---:|:---:|:---:|:---:|
| Masters / network / operations | ● | ● | ○ | ● |
| Transport plan header | — | ● | ● (`ptr_plans`) | ● (one model) |
| Class/section applicability | — | — | — | ● |
| Plan effective date range | — | partial | only `effective_from` | ● |
| Draft plan children | — | ● | ● | ● |
| Proposal lifecycle | — | partial | ● | ● |
| Publish to live tables | — | — | ● | ● |
| Drift guard / snapshots | — | — | ● | ● |
| History for billing | — | partial | — | ● |
| Rollback | — | — | ● | ● |
| Fare master | — | partial | — | ● |
| Routine invoice | ● | ● | — | ● |
| Separate late fee/penalty | partial | partial | — | ● |
| Accounting outbox | — | — | — | ● |
| Advisor suggestions | — | — | schema only | ● |
| Student geo / consent | — | — | ● | ● |
| Auto stop generation | — | — | partial | ● |
| Auto route generation | — | partial | ● | ● |
| Constraint engine | — | — | partial | ● |
| Profitability objective | — | — | — | ● |
| Plan comparison | — | — | partial | ● |
| ETA / disruptions / safety / quote | — | — | schema only | ● |
| Automated tests | — | — | Python only | planned |

● = present  ○ = read-only/partial  — = absent

The final schema resolves four structural problems:

1. **One plan model.** `tpt_transport_plan` is the only plan header. Drafts use `tpt_plan_*`; publish moves them into live tables; `tpt_plan_publication` anchors history. `ptr_plans` and `tpt_route_proposal_*` are retired.
2. **History that survives.** History is anchored to a publication, not a proposal, and has no FK to the live row it copies. A deleted live route cannot erase its history.
3. **Class/date scope is first-class.** `tpt_transport_plan_class_jnt` + `tpt_transport_plan_shift_jnt` make “Junior plan, classes 1–5, 1 Apr–31 Oct” a database fact.
4. **Billing is plan-aware and separable.** Routine invoices, late fees, penalties and damage charges are separate rows/types, all carrying plan and publication id, all posting through an accounting outbox.

It also fixes every known referential and naming defect found in the three DDL files.

---

## 2. What was evaluated

### 2.1 DDL v2.3 (TPT v1)

**Strengths**
- Clean master set: vehicle, personnel, shift, route, stop, route-stop, assignment, scheduler, trip, stop detail.
- Correct operational grain: one route per shift/direction; one assignment row per dated crew/vehicle link; one attendance row per driver/day.
- Boarding and notification logs present; spatial geometry intent.

**Defects**
| # | Defect | Impact |
|---|---|---|
| 1 | `tpt_student_route_allocation_jnt` declares `fk_sa_route` on a non-existent `route_id` column. | Migration fails or FK is silently absent. |
| 2 | `tpt_student_boarding_log` FKs reference `tpt_students`, `tpt_student_session`, `tpt_routes` — none exist. | Boarding DDL cannot be applied as written. |
| 3 | `tpt_notification_log` FK uses `stop_id` but column is `boarding_stop_id`. | FK fails. |
| 4 | `SPATIAL INDEX` on nullable `route_geometry` / `location`. | MySQL requires NOT NULL for a spatial index; DDL fails. |
| 5 | No plan / publication / history model. | No safe change management. |
| 6 | Billing is one `tpt_student_fee_detail`; fines are embedded. | Cannot separate late fee/penalty or explain historical fares. |
| 7 | `vendor_id` NOT NULL on every vehicle. | Owned vehicles need a fake vendor. |
| 8 | Several tables lack `updated_at`, `is_active`, `created_by`. | Audit and soft-delete inconsistent. |
| 9 | Status columns are free-text VARCHAR rather than enums/lookups. | Typos and report drift. |
| 10 | `tpt_route` and `tpt_pickup_points` names unique tenant-wide. | The same corridor cannot exist in two plans. |

### 2.2 DDL v2.7 (TPT v2)

**Additions**
- `tpt_transport_plan` (shift, validity, billable flags).
- `tpt_shift.shift_start_time` / `shift_end_time`.
- `tpt_vehicle.facilities`, `avg_exp_per_km`, `avg_fare_per_km`, `rating`.
- `tpt_route.tpt_plan_id`, `est_exp_per_km`.
- Proposal family: `tpt_proposal_type`, `tpt_route_proposal_master`, `tpt_proposed_route`, `tpt_proposed_pickup_points`, `tpt_proposed_pickup_points_route_jnt`, `tpt_proposed_student_route_allocation`, `tpt_proposed_driver_route_vehicle_jnt`.
- Five history tables keyed by `proposal_master_id`.

**Defects**
| # | Defect | Impact |
|---|---|---|
| 1 | Plan is split between `tpt_transport_plan` (live) and `tpt_route_proposal_master` (draft). | Two lifecycles, two histories, no single answer to “what plan is live?”. |
| 2 | History rows FK to live rows and to the proposal. | Deleting a live row or a proposal destroys history; cannot serve billing/audit. |
| 3 | `tpt_proposed_pickup_points_route_jnt` FK names use `route_id` / `pickup_point_id` but columns are `proposed_*`. | FK creation fails. |
| 4 | `tpt_proposal_type` is child-level only; the master has no status/review columns. | No master approval state. |
| 5 | `tpt_route_proposal_master.academic_year_id` references `acad_academic_years` in DDL but the migration references `sch_org_academic_sessions_jnt`. | DDL/migration drift. |
| 6 | `usr_users` referenced 8× instead of `sys_users`. | FK creation fails. |
| 7 | Same boarding/notification/allocation FK defects as v2.3. | DDL cannot apply. |
| 8 | `tpt_route` / `tpt_pickup_points` carry `tpt_plan_id` NOT NULL. | SmartTransport (written against v2.4) does not populate it; CRUD fails. |
| 9 | No class/section mapping and no `effective_to` on the plan header. | Cannot scope a plan to classes or a date range. |
| 10 | No billing link from plan/publication to invoice. | Mid-term changes cannot be reconciled. |

### 2.3 PrimeTransport DDL v1.0 (TPT v3)

**Strengths**
- Explicit `ptr_` namespace; strong separation from live tables.
- `ptr_plans` lifecycle with baseline hash, levers, KPI, review, publish, rollback.
- Full-copy plan children (`ptr_plan_routes`, `ptr_plan_route_stops`, `ptr_plan_new_stops`, `ptr_plan_allocations`, `ptr_plan_vehicle_assignments`).
- Self-contained `ptr_snapshots` JSON with checksum — correct rollback design.
- `ptr_settings`, `ptr_rule_settings`, `ptr_distance_matrix`, `ptr_student_geo`, `ptr_engine_runs`.
- Reserved tables for ETA, disruptions, admission quotes, safety.

**Defects**
| # | Defect | Impact |
|---|---|---|
| 1 | `ptr_plans` duplicates `tpt_transport_plan` as a second plan header. | Two sources of truth; routes point at both. |
| 2 | No class/section scope and no `effective_to`; only `effective_from`. | Cannot implement “Junior classes 1–5 for a date range”. |
| 3 | `ptr_plan_new_stops.promoted_stop_id` is read by publish but no code writes it. | Plans containing proposed stops cannot publish. |
| 4 | No billing, invoice, charge or accounting table. | Late/penalty billing and accounting integration absent. |
| 5 | `ptr_advisor_*`, `ptr_suggestions`, `ptr_eta_live`, `ptr_disruptions`, `ptr_admission_quotes`, `ptr_safety_scores` are unused. | Schema exists, product does not. |
| 6 | `ptr_safety_scores` is driver-only. | No vehicle/route score. |
| 7 | `ptr_plan_locks.target_id` is polymorphic with no FK. | Correct for locks, but needs app validation. |
| 8 | `ptr_distance_matrix` has no time band, while `ptr_segment_speeds` does. | Matrix cannot cache peak/off-peak separately. |
| 9 | `ptr_plan_comparison` is absent; comparison is ad hoc in the UI. | Cannot save/share a comparison. |
| 10 | `ptr_snapshots.row_count` is computed incorrectly in code (nested array count). | Cosmetic but misleading. |

### 2.4 Live migrations (the real source of truth)

| Finding | Detail |
|---|---|
| Base `tpt_*` migrations | 27 create migrations + `deleted_at` alter + vehicle fare/rating alter. |
| Proposal/history migrations | 12 create migrations + one alter. They live in the **shared** tenant folder, not the SmartTransport module. |
| Transport-owned migrations | `tpt_gps_trip_log`, `tpt_gps_alerts` — present in code, missing from DDL v2.8. |
| SmartTransport migrations | Empty (`.gitkeep`). |
| PrimeTransport migrations | 23, exact 1:1 with models. |
| DDL drift | `tpt_route` / `tpt_pickup_points.tpt_plan_id` NOT NULL, but SmartTransport models/forms omit it. |
| Phantom models | `TptFeeCollection` → `tpt_fee_collection` (no table); `TptFeatureStore`, `TptModelRecommendations`, `TptRecommendationHistory`, `TptStudentEventLog` → no tables. |
| Wrong model table | SmartTransport `TptGpsTripLog` derives `tpt_gps_trip_logs` instead of `tpt_gps_trip_log`. |
| DDL/migration mismatch | `tpt_route_proposal_master.academic_year_id` targets different tables in DDL vs migration. |
| Module ownership | All proposal/history tables are in the shared folder despite being Smart-only domain. |

### 2.5 Code drift

- SmartTransport is a ~343-file fork; 155+ files have diverged. It writes the same `tpt_*` tables as Transport.
- PrimeTransport has its own lifecycle but no class/date, billing, history or advisor engine.
- No PHP tests in any of the three modules; Prime’s Python has 7 toy cases.

**Conclusion:** the schema cannot be fixed table-by-table in place. A target-state consolidation is required, followed by a controlled migration.

---

## 3. Design decisions

### D1 — Two prefixes, three modules

| Prefix | Owner | Purpose |
|---|---|---|
| `tpt_` | Foundation (`Modules/Transport`) | Live network, operations, finance, plan lifecycle, staging, history, Standard Advisor |
| `ptr_` | Prime (`Modules/PrimeTransport`) | Settings, distance cache, student geo, engine runs, stop generation, ETA, disruptions, quotes, safety |
| — | Standard (`Modules/SmartTransport`) | Owns `tpt_adv_*` advisory tables; reads live `tpt_*`; no live-network tables |

This ends the “which table does Smart write?” problem.

### D2 — One plan model

`tpt_transport_plan` is the only plan header. It carries:
- type, session, source, status, version, parent
- baseline hash, levers, KPI
- effective dates
- billing flags and proration
- approval/publish/rollback stamps

Draft children: `tpt_plan_route`, `tpt_plan_new_stop`, `tpt_plan_route_stop`, `tpt_plan_allocation`, `tpt_plan_vehicle_assignment`, `tpt_plan_lock`, `tpt_plan_review`, `tpt_plan_snapshot`.

`ptr_plans` and `tpt_route_proposal_*` are retired. Migration maps them into this model.

### D3 — Class/date scope is a join table

`tpt_transport_plan_class_jnt` (plan, class, section, session, effective dates, priority) and `tpt_transport_plan_shift_jnt` (plan, shift, direction, timing) make scope explicit.

- Section-level row overrides class-level row.
- Overlap is blocked at approve/publish; the DB cannot express a partial exclusion constraint, so the service enforces it with a row lock.
- A plan without applicability cannot publish.

### D4 — One publication anchors history and billing

`tpt_plan_publication` records each publish:
- plan, version, effective dates, publisher, status
- before/after hashes
- before/after snapshot ids
- superseded plan

Every history row carries `plan_publication_id`. Every invoice and charge carries `plan_publication_id`. This is what makes “why was this child billed ₹1,800 in October?” answerable after the network changed.

### D5 — History has no FK to the live row it copies

History tables store `original_*_id` as a plain integer, not a FK. This is deliberate:
- a live route/stop/allocation may be hard-deleted by another module or a cleanup job;
- history must still reconstruct the network and the bill;
- a FK with `CASCADE` would destroy the evidence, and `RESTRICT` would block legitimate cleanup.

History FKs only to `tpt_plan_publication` (RESTRICT) and, where useful, `tpt_transport_plan` (SET NULL).

### D6 — Publish is the only writer of live network tables

The live tables are:
`tpt_route`, `tpt_pickup_points`, `tpt_pickup_points_route_jnt`, `tpt_driver_route_vehicle_jnt`, `tpt_student_route_allocation_jnt`, `tpt_route_scheduler_jnt`.

Only `PlanPublishService` writes them for plan changes. CRUD remains for one-off master edits, but a plan change must go through publish. The enhancement plan adds an architecture test for this.

### D7 — Billing is plan-aware and separable

| Table | Purpose |
|---|---|
| `tpt_transport_fare` | Versioned fare matrix by plan/route/stop/class/direction |
| `tpt_billing_run` | Idempotent run header (Regular/LateFee/Penalty/Adjustment) |
| `tpt_transport_invoice` | Routine, late-fee, penalty, adjustment, credit-note invoices |
| `tpt_transport_invoice_line` | Line detail |
| `tpt_transport_charge` | Separate charge record before/after invoicing |
| `tpt_transport_payment` | Payment/receipt with reversal |
| `tpt_accounting_posting` | Outbox to Accounting |

Legacy `tpt_student_fee_detail`, `tpt_student_fine_detail`, `tpt_student_fee_collection` are retained for compatibility and migration, clearly marked `LEGACY-COMPAT`. New code uses the invoice/charge/payment layer.

`tpt_fine_master` is extended with `charge_type`, `calc_type`, `grace_days`, `max_amount`, `applies_to` and `effective_from/to`, so it can drive late fees, penalties and damage charges without a second rule table.

### D8 — Advisor is Standard, not Prime

Advisor tables are `tpt_adv_*` because Standard is a read/advice layer over Foundation data:
- `tpt_adv_rule_settings`
- `tpt_adv_runs`
- `tpt_adv_suggestions`
- `tpt_adv_suggestion_outcomes`
- `tpt_adv_savings_ledger`

Prime reuses them; its only extra is `action_plan_id` on a suggestion and `ptr_plan_constraint` for engine-specific constraints.

### D9 — Student geo and consent are Prime-only

`ptr_student_geo` stores home/drop points with source, status, accuracy and consent. Missing coordinates remain NULL; a student without consent is not used. This is deliberately outside `tpt_*` so Standard never sees individual home pins.

### D10 — Spatial columns

- `tpt_pickup_points.location` is nullable and **has no spatial index** (MySQL disallows a spatial index on a nullable column).
- `tpt_pickup_point_geo.location` is `POINT NOT NULL SRID 4326` with a `SPATIAL INDEX`. One row per geocoded stop.
- `tpt_route.route_geometry` is nullable `LINESTRING SRID 4326` with no spatial index. Route lines are drawn, not proximity-queried.
- Prime’s `ptr_distance_matrix` is the proximity cache; it does not need spatial indexes.

This fixes the invalid `SPATIAL INDEX` in v2.3/v2.7.

### D11 — Referential policy

| Reference | Policy |
|---|---|
| Plan → its draft/history children | CASCADE (deleting a draft removes its content) |
| History → publication | RESTRICT (never lose the anchor) |
| History → live row | No FK; plain `original_*_id` |
| Live plan → routes/stops/allocations | RESTRICT/SET NULL as appropriate; never cascade away operational history |
| User FKs (`created_by`, `approved_by`, etc.) | SET NULL |
| Vehicle/personnel on operational rows | RESTRICT (deactivate, don't delete) |
| Polymorphic ids (locks, suggestions, distance matrix) | No FK; app validation |

All FK names are unique across the tenant schema: `fk_<table>_<column>`.

### D12 — Naming and standard columns

- Tables: plural nouns, `tpt_`/`ptr_` prefix.
- Columns: snake_case; no reserved words (`group_name`, `fuel_date`, `setting_key`).
- Status: ENUM for closed sets; lookup table for school-configurable sets.
- Standard columns: `is_active`, `created_by`, `updated_by`, `created_at`, `updated_at`, `deleted_at`.
- High-volume logs (GPS, events, boarding) omit `updated_at`/`deleted_at` where immutability is the point.
- Money `DECIMAL(12,2)`/`(14,2)`; coordinates `DECIMAL(10,7)`; distance `DECIMAL(7,2)`/`(8,2)`.

### D13 — What is retired

| Retired | Replacement |
|---|---|
| `tpt_route_proposal_master` | `tpt_transport_plan` (source = Engine/Advisor/Manual) |
| `tpt_proposed_route` | `tpt_plan_route` |
| `tpt_proposed_pickup_points` | `tpt_plan_new_stop` |
| `tpt_proposed_pickup_points_route_jnt` | `tpt_plan_route_stop` |
| `tpt_proposed_student_route_allocation` | `tpt_plan_allocation` |
| `tpt_proposed_driver_route_vehicle_jnt` | `tpt_plan_vehicle_assignment` |
| `tpt_route_history` (proposal-keyed) | `tpt_route_history` (publication-keyed) |
| `tpt_pickup_points_history` | `tpt_pickup_point_history` |
| `tpt_pickup_points_route_jnt_history` | `tpt_pickup_point_route_history` |
| `tpt_student_route_allocation_history` | `tpt_student_route_allocation_history` |
| `tpt_driver_route_vehicle_jnt_history` | `tpt_driver_route_vehicle_history` |
| `ptr_plans` | `tpt_transport_plan` |
| `ptr_plan_routes` | `tpt_plan_route` |
| `ptr_plan_new_stops` | `tpt_plan_new_stop` |
| `ptr_plan_route_stops` | `tpt_plan_route_stop` |
| `ptr_plan_allocations` | `tpt_plan_allocation` |
| `ptr_plan_vehicle_assignments` | `tpt_plan_vehicle_assignment` |
| `ptr_plan_locks` | `tpt_plan_lock` |
| `ptr_plan_reviews` | `tpt_plan_review` |
| `ptr_snapshots` | `tpt_plan_snapshot` |
| `ptr_advisor_runs` | `tpt_adv_runs` |
| `ptr_suggestions` | `tpt_adv_suggestions` |
| `ptr_suggestion_outcomes` | `tpt_adv_suggestion_outcomes` |
| `tpt_fee_collection` (phantom) | `tpt_transport_payment` |
| `tpt_feature_stores`, `tpt_model_recommendations`, `tpt_recommendation_histories`, `tpt_student_event_logs` (phantom) | `tpt_adv_suggestions`, `tpt_adv_savings_ledger`, `tpt_student_event_log` |

---

## 4. Final table inventory

82 tables + 3 views. Grouped by owner and status.

### 4.1 Foundation masters (tpt_)

| # | Table | Status | Notes |
|---:|---|---|---|
| 1 | `tpt_plan_type` | **New** | Regular/Junior/Senior/Sports/Staff/Event |
| 2 | `tpt_shift` | Changed | + pickup/drop targets, days, grace, direction |
| 3 | `tpt_vehicle` | Changed | + depot, facilities, cost/km, rating; vendor nullable |
| 4 | `tpt_personnel` | Changed | + encrypted IDs, hash, email, verification validity |
| 5 | `tpt_transport_plan` | **Unified** | The only plan header |
| 6 | `tpt_transport_plan_class_jnt` | **New** | Class/section/date applicability |
| 7 | `tpt_transport_plan_shift_jnt` | **New** | Multi-shift plan |
| 8 | `tpt_transport_plan_rule` | **New** | Per-plan constraint snapshot |
| 9 | `tpt_compliance_document` | **New** | Polymorphic document validity |

### 4.2 Network (tpt_)

| # | Table | Status | Notes |
|---:|---|---|---|
| 10 | `tpt_pickup_points` | Changed | No plan/shift FK; geocode status, safety flags |
| 11 | `tpt_pickup_point_geo` | **New** | NOT NULL POINT + spatial index |
| 12 | `tpt_route` | Changed | Plan-scoped; distance, duration, status |
| 13 | `tpt_pickup_points_route_jnt` | Changed | Unique sequence, route-stop |
| 14 | `tpt_transport_fare` | **New** | Versioned fare matrix |

### 4.3 Assignment, roster, trips (tpt_)

| # | Table | Status | Notes |
|---:|---|---|---|
| 15 | `tpt_driver_route_vehicle_jnt` | Changed | Overlap validation |
| 16 | `tpt_route_scheduler_jnt` | Changed | + plan, override, reason |
| 17 | `tpt_trip` | Changed | + shift/plan/direction; nullable odometer |
| 18 | `tpt_trip_stop_detail` | Changed | + GPS, unique trip/stop |
| 19 | `tpt_trip_incidents` | Changed | + action taken, status enum |

### 4.4 Attendance and boarding (tpt_)

| # | Table | Status | Notes |
|---:|---|---|---|
| 20 | `tpt_attendance_device` | Changed | Device→person, encrypted FCM |
| 21 | `tpt_driver_attendance` | Changed | Standard columns, source |
| 22 | `tpt_driver_attendance_log` | Changed | Immutable punch log |
| 23 | `tpt_student_boarding_log` | Changed | Correct FKs, direction, manual flag |
| 24 | `tpt_student_event_log` | **New** | Full student movement audit |

### 4.5 Vehicle lifecycle (tpt_)

| # | Table | Status | Notes |
|---:|---|---|---|
| 25 | `tpt_vehicle_fuel` | Changed | `fuel_date`, station, invoice, approval |
| 26 | `tpt_daily_vehicle_inspection` | Changed | 15 checks, critical fail |
| 27 | `tpt_vehicle_service_request` | Changed | Vehicle FK, optional inspection, priority |
| 28 | `tpt_vehicle_maintenance` | Changed | Vehicle FK, vendor, invoice |

### 4.6 Student allocation (tpt_)

| # | Table | Status | Notes |
|---:|---|---|---|
| 29 | `tpt_student_route_allocation_jnt` | Changed | Plan, fare source, date range, correct FKs |
| 30 | `tpt_student_stop_change_request` | **New** | Parent/staff request workflow |

### 4.7 Billing and accounting (tpt_)

| # | Table | Status | Notes |
|---:|---|---|---|
| 31 | `tpt_fine_category` | Retained | |
| 32 | `tpt_fine_master` | Changed | Charge type, calc type, grace, cap |
| 33 | `tpt_billing_run` | **New** | Idempotent run header |
| 34 | `tpt_transport_invoice` | **New** | Routine/late/penalty/credit note |
| 35 | `tpt_transport_invoice_line` | **New** | Line detail |
| 36 | `tpt_transport_charge` | **New** | Separate charge record |
| 37 | `tpt_transport_payment` | **New** | Payment/receipt/reversal |
| 38 | `tpt_student_fee_detail` | Legacy | Kept for migration |
| 39 | `tpt_student_fine_detail` | Legacy | Kept for migration; `waived_` spelling |
| 40 | `tpt_student_fee_collection` | Legacy | Kept for migration |
| 41 | `std_student_pay_log` | Retained | Shared payment audit |
| 42 | `tpt_accounting_posting` | **New** | Accounting outbox |

### 4.8 Plan staging (tpt_)

| # | Table | Status | Notes |
|---:|---|---|---|
| 43 | `tpt_plan_route` | **New** | Draft route |
| 44 | `tpt_plan_new_stop` | **New** | Proposed stop |
| 45 | `tpt_plan_route_stop` | **New** | Draft route-stop |
| 46 | `tpt_plan_allocation` | **New** | Draft student allocation |
| 47 | `tpt_plan_vehicle_assignment` | **New** | Draft bus/crew |
| 48 | `tpt_plan_lock` | **New** | Regeneration locks |
| 49 | `tpt_plan_review` | **New** | Append-only audit |
| 50 | `tpt_plan_snapshot` | **New** | Rollback source |
| 51 | `tpt_plan_comparison` | **New** | Saved comparison |
| 52 | `tpt_plan_comparison_item` | **New** | Per-plan metrics |

### 4.9 Lifecycle and history (tpt_)

| # | Table | Status | Notes |
|---:|---|---|---|
| 53 | `tpt_plan_publication` | **New** | Publish version anchor |
| 54 | `tpt_route_history` | **New** | Publication-keyed |
| 55 | `tpt_pickup_point_history` | **New** | Publication-keyed |
| 56 | `tpt_pickup_point_route_history` | **New** | Publication-keyed |
| 57 | `tpt_student_route_allocation_history` | **New** | Publication-keyed, billing lock |
| 58 | `tpt_driver_route_vehicle_history` | **New** | Publication-keyed |
| 59 | `tpt_transport_plan_history` | **New** | Versioned plan header |

### 4.10 Standard Advisor (tpt_)

| # | Table | Status | Notes |
|---:|---|---|---|
| 60 | `tpt_adv_rule_settings` | **New** | Per-school thresholds |
| 61 | `tpt_adv_runs` | **New** | Run history |
| 62 | `tpt_adv_suggestions` | **New** | Persisted suggestion |
| 63 | `tpt_adv_suggestion_outcomes` | **New** | Decision + measured |
| 64 | `tpt_adv_savings_ledger` | **New** | Measured savings |

### 4.11 Prime intelligence (ptr_)

| # | Table | Status | Notes |
|---:|---|---|---|
| 65 | `ptr_settings` | Retained/Changed | `group_name`, typed JSON |
| 66 | `ptr_rule_settings` | Retained | |
| 67 | `ptr_distance_matrix` | Retained | |
| 68 | `ptr_segment_speeds` | Retained | |
| 69 | `ptr_student_geo` | Changed | + status, verified, address |
| 70 | `ptr_engine_runs` | Retained | |
| 71 | `ptr_stop_generation_runs` | **New** | Auto stop generation |
| 72 | `ptr_stop_generation_candidate` | **New** | Proposed stop + walk + safety |
| 73 | `ptr_plan_constraint` | **New** | Per-plan hard/soft constraint |
| 74 | `ptr_eta_live` | Retained | |
| 75 | `ptr_disruptions` | Changed | + driver, options, resolution plan |
| 76 | `ptr_admission_quotes` | Retained | |
| 77 | `ptr_safety_rules` | Retained | |
| 78 | `ptr_safety_scores` | Changed | Driver/vehicle/route |

### 4.12 Integration (tpt_)

| # | Table | Status | Notes |
|---:|---|---|---|
| 79 | `tpt_domain_event_outbox` | **New** | Reliable cross-module events |

### 4.13 Notifications and GPS (tpt_)

| # | Table | Status | Notes |
|---:|---|---|---|
| 80 | `tpt_notification_log` | Changed | Correct `stop_id`, recipient, template, retry, true channel status |
| 81 | `tpt_gps_trip_log` | **Moved to Foundation** | High-volume insert-only positions |
| 82 | `tpt_gps_alerts` | **Moved to Foundation** | Overspeed/deviation/panic alerts |

### 4.14 Views

| View | Purpose |
|---|---|
| `v_tpt_current_plan` | Published plans in force today |
| `v_tpt_current_route` | Active routes of the current plan |
| `v_tpt_current_student_allocation` | Active allocations of the current plan |

---

## 5. Old → new mapping

### 5.1 Transport v2.3/v2.7 → final

| Old table | New table | Change |
|---|---|---|
| `tpt_vehicle` | `tpt_vehicle` | Vendor nullable, depot/facilities/cost fields |
| `tpt_personnel` | `tpt_personnel` | Encrypted IDs, hash, verification validity |
| `tpt_shift` | `tpt_shift` | Times, days, targets, grace |
| `tpt_route` | `tpt_route` | Plan-scoped, status, distance/duration |
| `tpt_pickup_points` | `tpt_pickup_points` + `tpt_pickup_point_geo` | Plan/shift removed; geocode status; spatial copy |
| `tpt_pickup_points_route_jnt` | `tpt_pickup_points_route_jnt` | Unique sequence |
| `tpt_driver_route_vehicle_jnt` | `tpt_driver_route_vehicle_jnt` | Overlap validation, derived count |
| `tpt_route_scheduler_jnt` | `tpt_route_scheduler_jnt` | Plan, override |
| `tpt_trip` | `tpt_trip` | Shift/plan/direction, nullable readings |
| `tpt_trip_stop_detail` | `tpt_trip_stop_detail` | GPS, unique trip/stop |
| `tpt_trip_incidents` | `tpt_trip_incidents` | Status enum, action taken |
| `tpt_attendance_device` | `tpt_attendance_device` | Encrypted FCM, device→person |
| `tpt_driver_attendance` | `tpt_driver_attendance` | Standard columns, source |
| `tpt_driver_attendance_log` | `tpt_driver_attendance_log` | Immutable |
| `tpt_student_route_allocation_jnt` | `tpt_student_route_allocation_jnt` | Plan, fare source, date range, FKs fixed |
| `tpt_student_boarding_log` | `tpt_student_boarding_log` | FKs fixed, direction |
| `tpt_notification_log` | `tpt_notification_log` | `stop_id` fixed, recipient, retry |
| `tpt_vehicle_fuel` | `tpt_vehicle_fuel` | `fuel_date`, station, invoice |
| `tpt_daily_vehicle_inspection` | `tpt_daily_vehicle_inspection` | Critical fail, photos |
| `tpt_vehicle_service_request` | `tpt_vehicle_service_request` | Vehicle FK, optional inspection |
| `tpt_vehicle_maintenance` | `tpt_vehicle_maintenance` | Vehicle FK, vendor, invoice |
| `tpt_fine_category` | `tpt_fine_category` | Retained |
| `tpt_fine_master` | `tpt_fine_master` | Charge type, calc, grace, cap |
| `tpt_student_fee_detail` | legacy + `tpt_transport_invoice` | Dual-write then cut over |
| `tpt_student_fine_detail` | legacy + `tpt_transport_charge` | Dual-write then cut over |
| `tpt_student_fee_collection` | legacy + `tpt_transport_payment` | Dual-write then cut over |
| `std_student_pay_log` | `std_student_pay_log` | Retained |
| `tpt_transport_plan` | `tpt_transport_plan` | Lifecycle, class/date, billing |
| `tpt_proposal_type` | `tpt_plan_type` + `tpt_plan_review` | Proposal type becomes plan type; steps become review |
| `tpt_route_proposal_master` | `tpt_transport_plan` | `source = Engine/Advisor/Manual` |
| `tpt_proposed_route` | `tpt_plan_route` | `change_kind` |
| `tpt_proposed_pickup_points` | `tpt_plan_new_stop` | `promoted_stop_id` |
| `tpt_proposed_pickup_points_route_jnt` | `tpt_plan_route_stop` | Correct column names |
| `tpt_proposed_student_route_allocation` | `tpt_plan_allocation` | Unserved reason |
| `tpt_proposed_driver_route_vehicle_jnt` | `tpt_plan_vehicle_assignment` | Plan id |
| `tpt_route_history` | `tpt_route_history` | Publication-keyed, no live FK |
| `tpt_pickup_points_history` | `tpt_pickup_point_history` | Publication-keyed |
| `tpt_pickup_points_route_jnt_history` | `tpt_pickup_point_route_history` | Publication-keyed |
| `tpt_student_route_allocation_history` | `tpt_student_route_allocation_history` | Publication-keyed |
| `tpt_driver_route_vehicle_jnt_history` | `tpt_driver_route_vehicle_history` | Publication-keyed |
| `tpt_gps_trip_log` | `tpt_gps_trip_log` | Moved to Foundation |
| `tpt_gps_alerts` | `tpt_gps_alerts` | Moved to Foundation |

### 5.2 PrimeTransport → final

| Old table | New table | Change |
|---|---|---|
| `ptr_settings` | `ptr_settings` | `group` → `group_name` |
| `ptr_rule_settings` | `ptr_rule_settings` | Retained |
| `ptr_distance_matrix` | `ptr_distance_matrix` | Retained |
| `ptr_segment_speeds` | `ptr_segment_speeds` | Retained |
| `ptr_student_geo` | `ptr_student_geo` | + status, verified, address |
| `ptr_engine_runs` | `ptr_engine_runs` | + StopGeneration type |
| `ptr_plans` | `tpt_transport_plan` | Merged |
| `ptr_plan_routes` | `tpt_plan_route` | Merged |
| `ptr_plan_new_stops` | `tpt_plan_new_stop` | Merged |
| `ptr_plan_route_stops` | `tpt_plan_route_stop` | Merged |
| `ptr_plan_allocations` | `tpt_plan_allocation` | Merged |
| `ptr_plan_vehicle_assignments` | `tpt_plan_vehicle_assignment` | Merged |
| `ptr_plan_locks` | `tpt_plan_lock` | Merged |
| `ptr_plan_reviews` | `tpt_plan_review` | Merged |
| `ptr_snapshots` | `tpt_plan_snapshot` | Merged |
| `ptr_advisor_runs` | `tpt_adv_runs` | Moved to Standard |
| `ptr_suggestions` | `tpt_adv_suggestions` | Moved to Standard |
| `ptr_suggestion_outcomes` | `tpt_adv_suggestion_outcomes` | Moved to Standard |
| `ptr_eta_live` | `ptr_eta_live` | Retained |
| `ptr_disruptions` | `ptr_disruptions` | + driver, options, plan |
| `ptr_admission_quotes` | `ptr_admission_quotes` | Retained |
| `ptr_safety_rules` | `ptr_safety_rules` | Retained |
| `ptr_safety_scores` | `ptr_safety_scores` | Driver/vehicle/route |
| — | `ptr_stop_generation_runs` | New |
| — | `ptr_stop_generation_candidate` | New |
| — | `ptr_plan_constraint` | New |
| — | `tpt_plan_comparison` / `_item` | New |

### 5.3 Column-level breaking changes to plan for

| Old column | New location | Migration action |
|---|---|---|
| `tpt_transport_plan.shift_id` | `tpt_transport_plan_shift_jnt.shift_id` | One row per plan/shift/direction; copy the old shift as `Pickup` + `Drop` rows if the plan covered both |
| `tpt_pickup_points.tpt_plan_id` | Removed | Stops are physical masters; plan scope comes from the route that references the stop |
| `tpt_pickup_points.shift_id` | Removed | Same: route + route-stop carry the shift/plan |
| `tpt_route.name` unique tenant-wide | Unique per plan | Existing names remain; new plans may reuse a corridor name |
| `tpt_shift.effective_from/to` | Retained | Shift validity remains; plan dates are separate |
| `tpt_trip.status` free text | ENUM | Map `In Progress`/`Ongoing` → `InTransit`; `Approved` is a status, not only a flag |
| `tpt_vehicle.vendor_id` NOT NULL | Nullable | Owned vehicles no longer need a fake vendor; backfill only leased/rented |
| `tpt_vehicle.fitness_valid_upto` etc. | Retained + `tpt_compliance_document` | Backfill documents; keep columns for compatibility until cutover |
| `tpt_personnel.id_no`, `license_no` | `*_encrypted` + `*_hash` | Encrypt existing values; add hash; drop plaintext after verification |
| `tpt_student_fee_detail.month` | `billing_month` + invoice period | Map first-of-month; dual-write |
| `tpt_student_fine_detail.waved_fine_amount` | `waived_fine_amount` (new table) | Legacy column retained; new code uses correct spelling |
| `tpt_fine_master.fine_type` | `calc_type` | Map Fixed/Percentage; add PerDay/Slab where needed |
| `tpt_fine_master.Remark` | `remarks` | Normalise casing |
| `tpt_vehicle_service_request.Vehicle_status` | `vehicle_status_id` | Map dropdown id |
| `tpt_vehicle_fuel.date` | `fuel_date` | Rename to avoid ambiguity |
| `tpt_daily_vehicle_inspection` mixed-case `Create Table` | Standard `CREATE TABLE` | DDL hygiene only |
| `tpt_student_route_allocation_jnt.route_id` (phantom) | `pickup_route_id` / `drop_route_id` | Remove phantom FK; no data change |
| `tpt_notification_log.boarding_stop_id` | `stop_id` | Rename/migrate |

---

## 6. Integrity rules

### 6.1 Enforced by the database

| Rule | Mechanism |
|---|---|
| Unique plan code | `uq_tpt_plan_code` |
| One plan route code per plan | `uq_tpt_plan_route_code` |
| One stop per route | `uq_tpt_route_stop` |
| Gap-free sequence intent | `uq_tpt_route_ordinal` |
| One roster row per route/date/shift/direction | `uq_tpt_sched_route` |
| One vehicle/driver/helper per date/shift/direction | `uq_tpt_sched_vehicle/driver/helper` |
| One attendance summary per person/day | `uq_tpt_attendance_day` |
| One invoice per student/session/plan/period/type | `uq_tpt_invoice_period` |
| One accounting posting per source/type | `uq_tpt_acct_source` |
| One settings key per tenant | `uq_ptr_settings_key` |
| One distance pair | `uq_ptr_dist_pair` |
| One plan/student draft allocation | `uq_tpt_plan_alloc_student` |
| One plan class/date row | `uq_tpt_plan_class` |
| One publication version per plan | `uq_tpt_publication_version` |
| Spatial proximity | `sp_idx_tpt_stop_geo` |

### 6.2 Enforced by the application (with row locks)

| Rule | Why not DB |
|---|---|
| No overlapping published plan for the same class/section/date | MySQL has no exclusion constraint; service checks under a lock |
| No overlapping driver/vehicle assignment | Trigger is optional; service checks on create and update |
| Exactly one of `stop_id` / `new_stop_id` on a plan route stop | MySQL rejects CHECK on a column with a FK cascade action; app enforces |
| One active allocation per student/session/direction/date | Date-range overlap; app enforces atomically |
| Fare precedence and version selection | Business logic |
| Publish drift guard | Hash comparison in service |
| Capacity / walk / ride constraints | Solver + validation |
| `student_restricted` only restricts transport | Never touch `std_students` |
| Invoice idempotency | Unique key + run-level check |
| Waiver ≤ charge | App validation |

### 6.3 Data-quality guards

1. Missing coordinates → NULL + `Pending`, excluded from generation.
2. Missing fare on a billable plan → billing blocked for that student, listed.
3. Odometer NULL/0 → distance flagged; P&L uses fuel-log distance.
4. Unapproved fuel/maintenance → excluded from P&L.
5. Route without geometry → map warning + estimated label.
6. Duplicate allocation → validation error.
7. Plan with unresolved HIGH data issue → approval blocked unless override recorded.

---

## 7. Migration sequence (recommended)

This is the safe path from today’s three schemas to the target. It is expanded in the enhancement plan.

### Phase 0 — Freeze and back up
1. Full tenant DB backup and restore rehearsal.
2. Freeze SmartTransport writes (read-only) for the migration window.
3. Inventory every live plan/proposal and map it to a target plan.

### Phase 1 — Additive schema
1. Create the new tables (`tpt_transport_plan` extensions, class/shift/rule joins, `tpt_plan_*`, `tpt_plan_publication`, history, `tpt_adv_*`, billing, `ptr_stop_generation_*`, outbox).
2. Add new columns to existing tables (nullable first).
3. Keep all old tables and columns in place. No drops.

### Phase 2 — Dual-write
1. Foundation writes both legacy fee tables and the new invoice/payment/charge layer.
2. Plan publish writes the new `tpt_plan_*` + history, and the legacy proposal tables for one release.
3. Advisor writes `tpt_adv_*`; Standard page switches to stored suggestions.

### Phase 3 — Data backfill
1. Create a `tpt_transport_plan` row for every live `tpt_transport_plan`/`ptr_plans`/proposal that represents a network.
2. Create a **legacy plan** for orphan routes/stops that have no plan; assign every route a plan before `tpt_route.tpt_plan_id` can become NOT NULL.
3. De-duplicate `tpt_pickup_points` by geo/code because the new stop master is plan-independent; repoint route-stop links to the surviving stop.
4. Map classes/sections and effective dates from the current session and plan scope.
5. Copy proposal children into `tpt_plan_*`.
6. Backfill `plan_publication_id` on history and invoices.
7. Backfill `tpt_transport_fare` from route-stop fares.
8. Backfill `tpt_compliance_document` from vehicle/personnel columns.
9. Backfill `tpt_notification_log.stop_id` from the legacy boarding-stop column.
10. Reconcile row counts: every live route, stop link, assignment and allocation must have a plan and a publication.

### Phase 4 — Cut over
1. Switch reads to the new tables/views.
2. Switch publish to the new lifecycle.
3. Switch Standard to `tpt_adv_*`.
4. Switch Prime to `tpt_transport_plan` + `tpt_plan_*` and `ptr_*` intelligence tables.
5. Stop writing legacy proposal/fee tables.

### Phase 5 — Retire
1. Rename legacy tables to `zz_legacy_*` (not drop) after a full billing/audit cycle.
2. Remove dead models and routes.
3. Drop after the retention period.

### Migration checks
- Every live allocation has a target plan and class/date scope.
- Every live route has a target plan and sequence.
- Every invoice maps to a publication and an allocation history row.
- Every student resolves to exactly one current plan.
- Row counts reconcile old vs new.
- Publish/rollback rehearsal on a staging tenant.

---

## 8. Validation checklist

Use this before signing off the DDL.

### 8.1 Structural
- [ ] All 82 tables create on a clean MySQL 8.0.32+ tenant DB.
- [ ] All FKs resolve; `FOREIGN_KEY_CHECKS=1` succeeds.
- [ ] No duplicate constraint names.
- [ ] All spatial indexes are on NOT NULL columns.
- [ ] All views compile.
- [ ] No reserved-word column names without backticks.
- [ ] Every table has a primary key.
- [ ] Every FK column has an index (MySQL creates one if absent; confirm no duplicates).

### 8.2 Business
- [ ] A plan can be created for classes 1–5, 1 Apr–31 Oct.
- [ ] A second overlapping plan is blocked under a row lock.
- [ ] A draft plan’s children do not appear in current views.
- [ ] Publish moves routes/stops/allocations/assignments and archives the old plan.
- [ ] History rows survive deletion of the live row.
- [ ] An October invoice resolves to the October publication and allocation history.
- [ ] A late fee is a separate invoice and a separate accounting posting.
- [ ] A non-billable plan produces no routine invoice but still has P&L.
- [ ] A proposed stop is promoted exactly once.
- [ ] A student without consent is excluded from Prime generation.
- [ ] A stop without coordinates is excluded and listed.
- [ ] Rollback restores the previous network and preserves trips/incidents.

### 8.3 Operational
- [ ] Billing run is idempotent on retry.
- [ ] Accounting posting is idempotent on retry.
- [ ] Publish is atomic and leaves no partial network.
- [ ] Drift guard refuses a stale plan.
- [ ] Roster generation skips dates with trips.
- [ ] GPS retention job purges old points.
- [ ] Tenant A cannot see Tenant B’s plans, stops, students or invoices.

### 8.4 Performance
- [ ] Current plan view < 100 ms for 300 routes.
- [ ] Allocation lookup by student/session < 50 ms.
- [ ] Invoice lookup by student/period < 50 ms.
- [ ] Plan comparison for 3 plans < 2 s.
- [ ] Distance matrix upsert is batched (no N+1).

---

## 9. Open schema questions

| # | Question | Recommendation |
|---:|---|---|
| 1 | Should `tpt_transport_plan` hold both drafts and live plans, or should drafts be a separate table? | One table with status; simpler history and fewer joins. |
| 2 | Should plan class applicability allow priority overrides? | Only with an explicit permission and reason; default block. |
| 3 | Should a penalty invoice consolidate multiple charges or be one per charge? | Consolidate per student/period/type; lines carry each charge. |
| 4 | Should legacy fee tables be kept indefinitely? | Keep for one full billing cycle + audit, then archive. |
| 5 | Should `tpt_pickup_points` keep the nullable `location` column? | Yes for app compatibility; `tpt_pickup_point_geo` is authoritative for spatial queries. |
| 6 | Should `tpt_route.route_geometry` be NOT NULL for published routes? | Yes at publish validation; DB stays nullable for drafts. |
| 7 | Should `ptr_distance_matrix` include a time band? | Yes if Prime learns peak speeds; add `time_band` or rely on `ptr_segment_speeds`. |
| 8 | Should advisor suggestions be partitioned by year? | Yes when >1M rows; start unpartitioned. |
| 9 | Should history tables be partitioned by publication year? | Yes for large tenants; start unpartitioned. |
| 10 | Should `tpt_plan_review` store the full diff JSON? | Yes, optional `diff_json` for audit; currently the snapshot holds it. |

---

## 10. How to use the DDL file

1. **Do not run it against production.** It is the target-state schema for the enhancement programme.
2. Run it on a clean MySQL 8.0.32+ tenant database to validate.
3. Compare the resulting `SHOW CREATE TABLE` output with the live schema; generate additive migrations for differences.
4. Keep the existing create migrations until the cutover; add new migrations rather than editing old ones.
5. Enable the optional overlap trigger only where the client supports `DELIMITER`.
6. Treat the three views as read-only helpers; do not write through them.

---

*End of schema evaluation.*
