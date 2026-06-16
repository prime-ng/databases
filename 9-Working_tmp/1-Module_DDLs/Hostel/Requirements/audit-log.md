# Audit Log — Requirements

## What It Does
Universal before/after change audit log for all hst_* tables. Records every create, update, delete, status change, approval, and other mutations with complete before/after snapshots. System writes only — no user entry allowed.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `entity_type` | VARCHAR(100) | Required. Model class or table name. |
| `entity_id` | BIGINT UNSIGNED | Required. |
| `action` | ENUM(create, update, delete, restore, status_change, approve, reject, assign, escalate, lock, unlock, other) | Required. |
| `actor_user_id` | INT UNSIGNED FK → sys_users | Nullable. NULL = system-generated. |
| `actor_role` | VARCHAR(50) | Nullable. Snapshot of role. |
| `before_json` | JSON | Nullable. Full record state before. |
| `after_json` | JSON | Nullable. Full record state after. |
| `field_diff_json` | JSON | Nullable. Only changed fields. |
| `reason` | VARCHAR(500) | Nullable. |
| `ip_address` | VARCHAR(45) | Nullable. |
| `user_agent` | VARCHAR(255) | Nullable. |
| `request_id` | VARCHAR(64) | Nullable. Correlation ID. |
| `created_at` | TIMESTAMP | NOT NULL. CURRENT_TIMESTAMP. |

## Business Rules

- All mutating methods call HostelAuditService::log() + global activityLog()
- Before/after JSON captures complete record state
- field_diff_json captures only changed fields for compact storage
- Read-only — no create/edit/delete by users
- Indexed on (entity_type, entity_id), (actor_user_id, created_at), (action, created_at)

## CRUD Operations

**List** — `GET /hostel/audit-log` → paginated table | Tab in Facility Mgmt | Columns: Timestamp, Entity, Action, Actor, Reason | Filtered by entity type, action, date range, actor

**View** — `GET /hostel/audit-log/{id}` → full detail page showing before/after JSON and field diff

No create, edit, or delete — audit log is append-only, system-written.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-audit-log.viewAny` |
| View details | `tenant.hostel-audit-log.view` |
