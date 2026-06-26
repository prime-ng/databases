# Status Masters — Business Requirements

## What This Screen Does

The Status Masters screen provides a centralized, dynamic status code system used across the entire Hostel module. Instead of hardcoding ENUM values in the database, all entity statuses (room status, bed status, allotment status, complaint status, maintenance status, etc.) are defined here. This allows schools to add custom status values without code changes.

---

## When This Screen Is Used

- During initial setup to pre-configure all required status values
- When a new status is needed for a specific entity type
- To rename or deactivate existing status values

---

## Key Fields

- **Entity Type** — Which entity this status applies to (e.g., Room, Bed, Allotment, Complaint, Maintenance)
- **Status Code** — Unique code for the status (e.g., `available`, `occupied`, `under_maintenance`)
- **Display Name** — Human-readable label shown in the UI
- **Color** — Badge color for visual identification (e.g., green for available, red for occupied)
- **Is Default** — Whether this is the default status for the entity type
- **Sort Order** — Display order in dropdowns
- **Status** — Active / Inactive

---

## Business Rules

- Each entity type can have multiple status values but only one default
- Status code must be unique within an entity type
- Deactivating a status prevents it from being selected but existing records retain the value
- At least one status must be active for each entity type at all times
- Default status is auto-assigned to new records

---

## Example Status Values

| Entity Type | Status Code | Display Name | Color |
|-------------|------------|--------------|-------|
| Room | available | Available | bg-success |
| Room | occupied | Occupied | bg-primary |
| Room | under_maintenance | Under Maintenance | bg-warning |
| Bed | free | Free | bg-success |
| Bed | occupied | Occupied | bg-danger |
| Complaint | open | Open | bg-info |
| Complaint | in_progress | In Progress | bg-primary |
| Complaint | resolved | Resolved | bg-success |
| Complaint | escalated | Escalated | bg-danger |
| Maintenance | reported | Reported | bg-warning |
| Maintenance | in_progress | In Progress | bg-primary |
| Maintenance | completed | Completed | bg-success |

---

## Related Screens

- **All entity screens** — Status fields across the module use values defined here
