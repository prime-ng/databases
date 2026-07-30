# Seat Capacity — Business Requirements

## What This Screen Does

The Seat Capacity screen defines the seat budget per class and quota type for an admission cycle. Each entry specifies total seats available, tracks how many have been allotted and enrolled, and computes remaining available seats. The allotment and enrollment counters are updated by downstream processes (MeritListService, EnrollmentService).

It is the fourth tab in `/admission/setup?tab=seats`.

## When This Screen Is Used

- Admission Setup: Defining seat budgets per class per quota
- Mid-Cycle: Adjusting seat counts if needed
- Monitoring: Viewing allotment/enrollment progress against budget

## Default Data

A seeder creates seat capacity entries matching each quota config for the active cycle, copying `total_seats` and setting `seats_allotted=0`, `seats_enrolled=0`.

## Key Fields

- **Admission Cycle** — FK to cycle
- **Class** — FK to class (required)
- **Quota Type** — Enum: General, Government, Management, RTE, NRI, Staff_Ward, Sibling, EWS
- **Total Seats** — Budgeted seats for this quota+class (min 1)
- **Seats Allotted** — Running count, incremented by allotment process (read-only in CRUD)
- **Seats Enrolled** — Running count, incremented by enrollment process (read-only in CRUD)
- **Available Seats** — Computed: max(0, total - allotted)

## Business Rules

**Unique Combination:** Only one entry per (cycle, class, quota_type) — enforced by database unique constraint `uq_adm_sc_cycle_class_quota`.

**Read-Only Counters:** `seats_allotted` and `seats_enrolled` are set to 0 on creation and only incremented by backend services (MeritListService, EnrollmentService), not through this CRUD.

**Computed Availability:** `available_seats` is a model accessor, not a stored column. It calculates remaining seats as `max(0, total_seats - seats_allotted)`.

## Workflow

1. Admin navigates to Seat Capacity tab and clicks Add New
2. Selects cycle, class, quota type, enters total seats
3. Saves — entry appears in table showing total/allotted/enrolled/available
4. After allotments and enrollments process, counters increase automatically
5. Can edit total seats, toggle active status, soft-delete, restore, force-delete

## Requirements

- MUST display seat capacities per active cycle in setup tab with search/filter
- MUST authorize via `tenant.adm-seat-capacity.*` gates
- MUST enforce validation: total_seats ≥ 1, quota_type in enum, unique (cycle, class, quota_type)
- MUST default seats_allotted=0, seats_enrolled=0 on create
- MUST compute available_seats as max(0, total - allotted) via model accessor
- MUST log all CRUD operations via activityLog()
- MUST support soft-delete, restore, force-delete
- MUST provide AJAX toggle-status endpoint returning JSON
