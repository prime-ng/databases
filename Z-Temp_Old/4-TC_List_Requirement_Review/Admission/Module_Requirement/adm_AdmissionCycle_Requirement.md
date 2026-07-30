# Admission Cycles — Business Requirements

## What This Screen Does

The Admission Cycles screen defines yearly admission campaigns — each cycle has its own application window (start/end dates), fee structure, age eligibility, refund policy, and status lifecycle. All downstream features (enquiries, applications, tests, merit lists, allotments, enrollment) are scoped within one active cycle.

The cycles tab is the first of four tabs in `/admission/setup?tab=cycles`. It presents a paginated table with search/status filtering and actions: create, view, edit, activate, close, delete, restore, force delete.

## When This Screen Is Used

- Annual Setup: Creating a new admission cycle for the upcoming academic year
- Mid-Cycle: Adjusting dates, fees, or policies
- Activation: Opening the cycle for enquiries/applications
- Closure: Ending the admission period
- Audit: Reviewing past cycles and configurations

## Key Fields

- **Cycle Name** — Human-readable label (e.g., "Academic Year 2026-27")
- **Cycle Code** — Short unique identifier (max 20 chars)
- **Academic Session** — FK to `sch_org_academic_sessions_jnt`; dropdown shows only active sessions
- **Start Date / End Date** — Application window; end must be after start
- **Application Fee** — Fee to apply (decimal, min 0)
- **Status** — Draft → Active → Closed → Archived (one-way transitions)
- **Age Rules (JSON)** — Min/max age per class for eligibility validation
- **Refund Policy (JSON)** — Refund % tiers by days since application

## Business Rules

**One Active Per Session:** Only one cycle can be Active per session (enforced by pipeline). This prevents concurrent campaigns from creating data ambiguity.

**Status Lifecycle Is One-Way:** Draft → Active → Closed → Archived. No reverse transitions. Archived cycles return 403 on update.

**Soft-Delete Preserves Integrity:** Destroyed cycles are hidden but existing enquiries/applications remain intact.

**JSON Flexibility:** `age_rules_json` and `refund_policy_json` store flexible configuration as JSON columns with textarea-to-JSON conversion in `prepareForValidation()`.

**Activity Audit:** All state-changing operations are logged via `activityLog()` with old/new value tracking on updates.

## Workflow

1. Admin creates a cycle in Draft status with all configuration fields
2. Admin verifies settings and clicks Activate (pipeline validates no other active cycle)
3. Enquiries and applications flow through the active cycle
4. After the admission period, admin clicks Close to stop new applications
5. Cycle becomes read-only for future reference/audit

## Related Screens

- Document Checklist, Quota Config, Seat Capacity — other setup tabs scoped by cycle
- Enquiries, Applications, Entrance Tests, Merit Lists, Allotments — scoped within the active cycle

## Requirements

- MUST display paginated cycles at `/admission/cycles` with search (name, cycle_code) and status filter
- MUST authorize via `tenant.adm-cycle.*` gates
- MUST enforce validation rules (BC-VAL-01 through BC-VAL-14)
- MUST default status=Draft, is_active=false on create
- MUST abort 403 on updating Archived cycles
- MUST track changes and log activity on all state changes
- MUST support soft-delete, restore, force-delete lifecycle
- MUST provide AJAX toggle-status endpoint returning JSON
- MUST enforce one Active cycle per session via pipeline
- MUST catch DomainException on activate/close and redirect with error flash
