# Audit Log — Business Requirements

## What This Screen Does

The Audit Log screen provides a complete record of all changes made across the Hostel module. Every create, update, delete, status change, and significant action is logged with before/after JSON snapshots and field-level diffs. This ensures full traceability for compliance and dispute resolution.

---

## When This Screen Is Used

- Investigating who changed a record and what was changed
- Compliance audit of hostel operations
- Recovering previous values after an incorrect update
- Dispute resolution (e.g., student claims they didn't damage an item)
- General security monitoring

---

## Key Fields

- **Entity Type** — Which table/entity was changed (e.g., Allotment, Complaint, Bed Maintenance)
- **Entity ID** — The record that was changed
- **Event Type** — Created / Updated / Deleted / Restored / Status Changed / Force Deleted
- **Old Values** — JSON snapshot of the record before the change
- **New Values** — JSON snapshot of the record after the change
- **Changed Fields** — List of fields that changed with before/after values
- **Performed By** — User who made the change
- **Performed At** — Timestamp
- **IP Address** — Request source IP
- **User Agent** — Browser/device info

---

## Business Rules

- All hst_* table mutations are logged automatically
- Audit logs are append-only — never deleted or edited
- Logs are retained for minimum 1 year (configurable)
- Searchable by entity type, entity ID, user, date range, and event type
- Field-level diffs show exactly what changed (old → new)
- Performance: Audit logging is asynchronous (queued) to avoid slowing down main operations

---

## Related Screens

- **All screens** — Every screen's mutations appear in the audit log
- **Notification Log** (Tab 26) — Related notifications also logged
