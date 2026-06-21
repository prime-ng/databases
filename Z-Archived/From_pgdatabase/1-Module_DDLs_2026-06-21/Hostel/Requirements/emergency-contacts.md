# Emergency Contacts — Requirements

## What It Does
Hostel-level emergency contact directory (doctor, ambulance, hospital, fire, police, plumber, electrician, etc.). Distinct from student emergency contacts in the StudentProfile module.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `contact_type` | ENUM(local_doctor, ambulance, hospital, fire, police, plumber, electrician, warden_emergency, transport, vendor_mess, vendor_security, other) | Required. |
| `name` | VARCHAR(150) | Required. Contact person/organisation name. |
| `organisation` | VARCHAR(150) | Nullable. |
| `mobile_primary` | VARCHAR(20) | Required. |
| `mobile_alternate` | VARCHAR(20) | Nullable. |
| `email` | VARCHAR(150) | Nullable. |
| `address` | VARCHAR(500) | Nullable. |
| `availability_24x7` | TINYINT(1) | Default 0. |
| `availability_hours` | VARCHAR(100) | Nullable. Free-text. |
| `priority_order` | TINYINT UNSIGNED | Default 100. Lower = called first. |
| `is_verified` | TINYINT(1) | Default 0. |
| `last_verified_at` | DATE | Nullable. |
| `notes` | VARCHAR(500) | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Scoping**
- Contacts are hostel-specific
- Indexed on (`hostel_id`, `contact_type`, `priority_order`)

**Verification**
- Verified contacts show a badge and last verified date
- Verification is manual (tested by warden)

## CRUD Operations

**Create** — `GET /hostel/emergency-contacts/create` → form | `POST /hostel/emergency-contacts` → validates → saves → redirects with `#emergency-contacts`

**List** — Tab in Hostel Setup | Columns: Name, Type, Phone, Priority, Verified, Status, Actions

**View** — `GET /hostel/emergency-contacts/{id}` → full detail

**Edit** — `GET /hostel/emergency-contacts/{id}/edit` | `PUT` → updates → redirects

**Delete (Soft)** — `DELETE /hostel/emergency-contacts/{id}`

**Restore** — `GET /hostel/emergency-contacts/{id}/restore`

**Force Delete** — `DELETE /hostel/emergency-contacts/{id}/force-delete`

**Toggle Status** — `POST /hostel/emergency-contacts/{contact}/toggle-status` → AJAX JSON

**Trash Page** — `GET /hostel/emergency-contacts/trash/view`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-emergency-contact.viewAny` |
| View details | `tenant.hostel-emergency-contact.view` |
| Create | `tenant.hostel-emergency-contact.create` |
| Edit/update | `tenant.hostel-emergency-contact.update` |
| Soft delete | `tenant.hostel-emergency-contact.delete` |
| View trash & restore | `tenant.hostel-emergency-contact.restore` |
| Force delete | `tenant.hostel-emergency-contact.forceDelete` |
