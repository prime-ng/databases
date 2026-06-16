# Feedback Tab 6: Cycle Setup

This screen allows administrators to create and manage feedback collection cycles. A cycle defines a time window during which feedback is collected. One cycle can include multiple feedback types simultaneously — for example, a single Q1 cycle could collect Student-to-Teacher feedback, Teacher-to-Student feedback, and Peer-to-Peer feedback all at the same time.

---

## How It Works

The screen shows a list of existing cycles with their name, academic session, term label, date range, status, and number of feedback types included. Administrators can create new cycles, edit draft cycles, activate them, close them, publish results, or cancel them.

When creating a cycle, the administrator provides a name, selects the academic session and term, sets the start and end dates, and configures default settings for anonymity and minimum response visibility threshold. The administrator then adds one or more feedback types to the cycle. Each feedback type selects a relationship type and a template, and can optionally override the cycle defaults for anonymity, minimum responses, draft saving, and withdrawal. The scope for each feedback type can be set to All (all eligible targets), Specific Classes, Specific Departments, Specific Targets, or Custom with a flexible JSON filter.

Once a cycle is saved as Draft, the administrator can edit it freely. When ready, the cycle is activated, which typically happens on the start date. During Active status, respondents can submit their feedback. After the end date, the cycle automatically closes. The administrator can then publish the results, making aggregated summaries visible to targets.

---

## Important Business Rules

- A cycle cannot be activated if it has no feedback types configured. At least one relationship-type and template pair must be added.
- The start date must be on or before the end date. Cycles cannot have negative duration.
- A cycle cannot be activated if any of its feedback types reference a template that has no active questions.
- Status transitions follow a strict flow: Draft → Active → Closed → Published. A cycle can be Cancelled from any state except Published.
- Once a cycle is active, its feedback types and templates cannot be changed. Only the description and instructions can be edited.
- The default minimum responses for visibility applies to all feedback types in the cycle. Each feedback type can increase this threshold but cannot lower it below the cycle default.
- Academic session and term label are informational for reporting purposes. The system does not enforce date range alignment with the session.
- When a cycle is published, all targets can view their aggregate results. Summary data is computed and written to fbk_summary at this point if not already computed incrementally.
- Publishing a cycle is irreversible. Once published, results cannot be hidden again.

---

## Database Columns & Behavior

### fbk_cycles
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `code` — Unique cycle code. VARCHAR(50). Unique with soft-delete.
- `name` — Cycle display name. VARCHAR(200).
- `academic_session_id` — FK to sch_org_academic_sessions_jnt.id. Links to school academic year. INT UNSIGNED.
- `term_label` — Optional label like Q1, Q2, Mid-Term, Annual. VARCHAR(50).
- `start_date` / `end_date` — Feedback collection window. DATE.
- `status_id` — FK to sys_dropdown_table.id (key: fbk_cycles.status). Draft, Active, Closed, Published, Cancelled. INT UNSIGNED.
- `default_is_anonymous_to_target` — Default anonymity setting. TINYINT(1), default 1.
- `default_min_responses_for_visibility` — Minimum responses before showing aggregates. TINYINT UNSIGNED, default 3.
- `instructions` — Instructions shown to respondents. TEXT, nullable.
- `is_published_to_targets` — Flag indicating results are published. TINYINT(1), default 0.
- `created_by` / `published_by` — FK to sys_users.id. INT UNSIGNED, nullable.

### fbk_cycle_feedback_types (junction table for feedback types within a cycle)
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `cycle_id` — FK to fbk_cycles.id. INT UNSIGNED. Cascade delete.
- `relationship_type_id` — FK to fbk_relationship_types.id. SMALLINT UNSIGNED.
- `template_id` — FK to fbk_templates.id. INT UNSIGNED.
- `is_anonymous_to_target` — Override default. TINYINT(1), default 1.
- `min_responses_for_visibility` — Override default. TINYINT UNSIGNED, default 3.
- `allow_draft_save` — Whether respondents can save drafts. TINYINT(1), default 1.
- `allow_withdrawal` — Whether respondents can withdraw submissions. TINYINT(1), default 1.
- `scope_type_id` — FK to sys_dropdown_table.id (key: fbk_cycle_feedback_types.scope_type). All, Specific_Classes, Specific_Departments, Specific_Targets, Custom. INT UNSIGNED.
- `scope_filter_json` — JSON filter for scope restriction. JSON, nullable.
- `is_auto_populated_targets` — 1 = auto-populate targets from relationships, 0 = manual entry. TINYINT(1), default 1.

---

## Deep Analysis

### Business Workflows & State Machines

The cycle has a strict state machine with five statuses:

```
                  ┌──────────┐
                  │  Draft   │
                  └────┬─────┘
                       │ Activate
                       ▼
                  ┌──────────┐
          ┌───────│  Active  │────────┐
          │       └────┬─────┘        │
          │            │ End date     │ Cancel
          │            ▼              │
          │       ┌──────────┐        │
          │       │  Closed  │        │
          │       └────┬─────┘        │
          │            │ Publish      │
          │            ▼              │
          │       ┌───────────┐       │
          └───────│ Published │       │
                  └───────────┘       ▼
                  ┌───────────┐
                  │ Cancelled │ (from Draft, Active, Closed)
                  └───────────┘
```

Transition rules:
- **Draft → Active**: Requires at least one feedback type, all templates must have active questions, start_date ≤ end_date, all relationship types must be active. Side-effect: all referenced templates become locked (is_locked=1). Side-effect: auto-populate fbk_cycle_targets if is_auto_populated_targets=1.
- **Active → Closed**: Automatic when end_date passes (scheduler). Can also be triggered manually by admin. Side-effect: incremental summary computation if not already done.
- **Closed → Published**: Admin action. Side-effect: full fbk_summary recomputation. Sets is_published_to_targets=1 and published_at. Irreversible.
- **Draft/Active/Closed → Cancelled**: Admin action. Side-effect: none on responses — existing drafts remain accessible until cycle cancellation is confirmed. All pending submissions are voided.
- **Published → Cancelled**: NOT allowed. Published is a terminal state.

### Validation Rules & Edge Cases

- **At least one feedback type**: Cycle must have ≥ 1 row in fbk_cycle_feedback_types before activation.
- **Date validation**: start_date ≤ end_date. On edit of an Active cycle, date changes that would pre-date existing responses should warn the admin.
- **Template question validation**: Before activation, verify that each template referenced by fbk_cycle_feedback_types has at least one active question. Templates with zero questions cannot be used.
- **min_responses_for_visibility override**: Each fbk_cycle_feedback_type.min_responses_for_visibility must be ≥ cycle.default_min_responses_for_visibility. It can increase the threshold but not decrease it below the cycle default.
- **Peer relationship anonymity override**: If relationship_type.is_peer_relationship = 1, is_anonymous_to_target on the cycle feedback type MUST be 1. The UI should lock this field and show a tooltip explaining why.
- **NEP 2020 mandatory check**: When activating a cycle, if the cycle covers target types that have NEP 2020 mandated relationship types, the system must verify those relationships are included. If missing, show a warning but allow activation (soft enforcement).
- **Cancel with drafts**: When cancelling a cycle, there may be Draft responses. The system should prompt the admin on how to handle them — delete drafts, or leave them for reference.
- **Published is irreversible**: The UI must show a confirmation dialog explaining that once published, results cannot be hidden. Consider a two-step confirmation: "Are you sure? This cannot be undone."
- **Cross-session cycles**: A cycle's start_date could fall in one academic session and end_date in another. The academic_session_id is informational; the system does not enforce alignment.
- **Scope filter for Specific_Targets**: When scope_type_id = Specific_Targets, scope_filter_json must contain target identifiers. The system should validate that each target exists in the relevant entity table.
- **Edit restrictions on active cycles**: Only description and instructions fields can be edited once status is Active. All other fields are read-only. On Closed cycles, even less is editable.

### Integration Points

- **sch_org_academic_sessions_jnt** via academic_session_id — links cycle to school academic year.
- **sys_dropdown_table** via status_id (key: fbk_cycles.status) and scope_type_id (key: fbk_cycle_feedback_types.scope_type).
- **fbk_relationship_types** via relationship_type_id — determines the feedback flow.
- **fbk_templates** via template_id — links to the question set. Triggers template lock on cycle activation.
- **fbk_cycle_feedback_types** via cycle_id — cascade delete when cycle is deleted.
- **fbk_cycle_targets** — generated from cycle feedback types during activation (auto-populate) or manually.
- **fbk_responses** via cycle_id — responses are linked to cycles. Cycle cannot be cancelled or deleted with submitted responses without handling them.
- **fbk_summary** via cycle_id — recomputed during Close and Publish transitions.

### Permissions Matrix

| Action | Admin | Principal | Teacher | Student | Parent | Staff |
|---|---|---|---|---|---|---|
| View cycle list | Yes | Yes | Yes (read-only) | No | No | No |
| Create draft cycle | Yes | Yes | No | No | No | No |
| Edit draft cycle | Yes | Yes | No | No | No | No |
| Activate cycle | Yes | Yes | No | No | No | No |
| Close cycle | Yes | Yes | No | No | No | No |
| Publish cycle | Yes | Yes | No | No | No | No |
| Cancel cycle | Yes | Yes | No | No | No | No |
| Delete draft cycle | Yes | Yes | No | No | No | No |
