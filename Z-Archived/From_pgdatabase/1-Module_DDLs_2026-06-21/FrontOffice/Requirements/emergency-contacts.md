# Emergency Contact Directory — Requirements

## What It Does
External emergency contact directory for the school front desk. Grouped by contact type (Hospital, Police, Fire, Ambulance, Transport, Utility, etc.) with quick-call capability. Used during emergencies to quickly find the right contact.

## Database Fields

### fof_emergency_contacts

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `contact_name` | VARCHAR(100) | Required. |
| `organization` | VARCHAR(150) | Nullable. |
| `contact_type` | ENUM('Hospital','Police','Fire','Ambulance','Transport','Utility','Parent_Emergency','Government','Other') | Required. |
| `primary_phone` | VARCHAR(15) | Required. |
| `alternate_phone` | VARCHAR(15) | Nullable. |
| `address` | VARCHAR(200) | Nullable. |
| `notes` | TEXT | Nullable. |
| `sort_order` | TINYINT UNSIGNED | Default 0. Display order within type group. |

## Business Rules
- `primary_phone` is always required
- Contacts are grouped by `contact_type` for UI display
- `sort_order` controls display order within each type group
- No foreign key dependencies to other FOF tables (Layer 1 table)

## CRUD Operations

**List**
- Grouped by `contact_type` with type headers
- Quick-call buttons (tel: links)
- CRUD inline (edit/delete available in list view)

**Create**
- `POST /front-office/emergency-contacts` — validates contact_name, contact_type, primary_phone

**Update**
- `PUT /front-office/emergency-contacts/{contact}` — edit contact details

**Delete**
- `DELETE /front-office/emergency-contacts/{contact}` — soft delete

## Permissions

| Operation | Permission Key |
|---|---|
| View contacts | `frontoffice.emergency-contact.view` |
| Create/update/delete | `frontoffice.emergency-contact.create` |
