# Feedback Tab 10: Activity Log

This screen provides a comprehensive audit trail of all significant events in the Feedback module. It tracks configuration changes to masters (target types, relationship types, categories), template and question modifications, cycle lifecycle transitions, response submissions and withdrawals, and summary recomputation events.

---

## How It Works

The activity log shows a chronological list of events with each entry displaying the date and time, the user who performed the action, the action type (Created, Updated, Deactivated, Activated, Submitted, Withdrawn, Published), the affected entity type and name, and a brief description of what changed. The log is read-only and searchable.

Users can filter the log by date range, action type, entity type, and specific user. This helps administrators investigate when changes were made, who made them, and what the previous values were before a change. For example, to investigate why a cycle was cancelled, the administrator filters by Cycle entity and Cancelled action type to see the event and any notes.

The activity log captures changes to master data (target types, relationship types, categories) so administrators can see an audit trail of who added a new target type or modified a relationship's context rule. Template and question changes are logged with enough detail to reconstruct what the template looked like before and after an edit.

Response-level events are logged at the response header level — submission, withdrawal, and status changes. Individual answer changes are not logged separately to avoid excessive noise, but the overall response status changes provide a clear audit trail.

---

## Important Business Rules

- The activity log is append-only. Events cannot be edited, deleted, or backdated by any user, including administrators.
- The log records the exact timestamp, user identity, IP address, and user agent for each event to provide a complete forensic trail.
- Configuration change events capture the previous and new values for modified fields when possible. This allows rollback investigation.
- Cycle lifecycle events (Draft → Active → Closed → Published → Cancelled) are always logged with the previous and new status values.
- Response submission and withdrawal events are logged immediately at the time of the action. The log includes the response ID for cross-referencing with the actual response data.
- Summary recomputation events are logged at a summary level (cycle-level or cycle-feedback-type-level) rather than per-target to avoid excessive log entries during batch processing.
- Bulk operations (e.g., activating multiple cycle feedback types) are logged as individual events with a correlation ID to group related changes.
- The activity log is retained indefinitely. Schools with high volume may archive entries older than a configurable retention period, but the default is to keep all entries.
- Failed login or permission-denied attempts related to feedback actions may also be recorded for security monitoring.

---

## Database Columns & Behavior

(Note: The activity log is not stored in a fbk_* table. It uses the application's central activity log system, which records events with the following structure:)

### Central Activity Log (module-agnostic, filtered for Feedback module)
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `loggable_type` / `loggable_id` — Polymorphic reference to the affected entity (fbk_cycle, fbk_template, fbk_response, etc.).
- `user_id` — FK to sys_users.id. Who performed the action. INT UNSIGNED.
- `event` — Action type: created, updated, deleted, activated, deactivated, submitted, withdrawn, published, cancelled. VARCHAR(50).
- `old_values` — JSON snapshot of the record's previous state before the change. JSON, nullable.
- `new_values` — JSON snapshot of the record's new state after the change. JSON, nullable.
- `description` — Human-readable summary of what happened. TEXT.
- `ip_address` — Request IP. VARCHAR(45).
- `user_agent` — Browser user agent string. VARCHAR(255), nullable.
- `correlation_id` — UUID linking related events in a batch operation. VARCHAR(36), nullable.
- `created_at` — Timestamp of the event. TIMESTAMP, indexed for efficient filtering.

---

## Deep Analysis

### Business Workflows & State Machines

This tab is purely read-only with no state transitions. The workflow is filtering-based: user selects filters (date range, event type, entity type, user) → system queries central activity log with loggable_type IN (fbk_cycle, fbk_template, ...) → displays paginated sorted results. No mutations occur from this tab.

The event generation is embedded into every other tab's write operations. Each mutation in Tabs 2-9 must fire a corresponding activity log event. This makes the activity log a cross-cutting concern enforced at the service/repository layer.

### Validation Rules & Edge Cases

- **Append-only immutability**: No UPDATE or DELETE operations are permitted on activity log rows. The DB should enforce this at the database level (read-only user account for the application's read path, or DB triggers blocking updates).
- **Timestamp integrity**: created_at is server-generated (CURRENT_TIMESTAMP). The application must never accept a client-supplied timestamp to prevent backdating.
- **old_values / new_values for sensitive fields**: When tracking changes to fields like is_anonymous_to_target or anonymity settings, ensure the JSON captures the full context. For cycle lifecycle events, always include the previous and new status_id values.
- **Bulk operation correlation**: When mass-assigning targets (auto-population), each target creation event should share the same correlation_id. This allows filtering by "all targets added in batch X".
- **Summary recomputation noise**: Full recomputation on cycle close can generate thousands of summary row updates. These should be logged as a single "summary_recomputed" event with correlation_id, not one event per summary row.
- **Data retention**: The default is indefinite storage. For high-volume schools, a configurable retention period (e.g., 365 days) can be set. Archived records should be moved to a cold storage table or exported before deletion.
- **Filter performance**: The activity log table can grow very large. Indexes on (loggable_type, created_at), (user_id, created_at), (event, created_at), and (correlation_id) are essential for filter performance.
- **Description format**: Descriptions should follow a consistent template for machine parsing: "[EntityType] [EntityName] was [Action] by [UserName]". Example: "Cycle 'Q1 2025-26' was Activated by admin@school.com."
- **Correlation ID format**: UUID v4. Generated by the application at the start of a bulk operation and shared across all events in that operation.

### Integration Points

- **Central activity log (polymorphic)** — the core table. All fbk_* entities are loggable types.
- **sys_users** via user_id — identifies who performed the action.
- **fbk_target_types** — logged on create, update, deactivate.
- **fbk_relationship_types** — logged on create, update, deactivate.
- **fbk_categories** — logged on create, update, deactivate.
- **fbk_templates** — logged on create, update, clone, lock, deactivate.
- **fbk_questions** — logged on create, update, delete, reorder (bulk).
- **fbk_cycles** — logged on create, update, activate, close, publish, cancel.
- **fbk_cycle_feedback_types** — logged on add, remove, edit overrides.
- **fbk_cycle_targets** — logged on bulk add (auto-populate), manual add, remove.
- **fbk_responses** — logged on draft save, submit, withdraw.
- **fbk_summary** — logged on recomputation (batch-level event, not per-row).

### Permissions Matrix

| Action | Admin | Principal | Teacher | Student | Parent | Staff |
|---|---|---|---|---|---|---|
| View activity log | Yes | Yes | No | No | No | No |
| Filter by date range | Yes | Yes | No | No | No | No |
| Filter by event type | Yes | Yes | No | No | No | No |
| Filter by entity type | Yes | Yes | No | No | No | No |
| Filter by user | Yes | Yes | No | No | No | No |
| Download log export | Yes | Yes | No | No | No | No |
| Edit/delete events | No | No | No | No | No | No |
| Backdate events | No | No | No | No | No | No |
