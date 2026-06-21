# Bed Types — Requirements

## What It Does
Master list of bed types (Lower Bunk, Upper Bunk, Single Bed). Referenced by `hst_beds.bed_type`. Allows dynamic bed type definitions without code changes.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | TINYINT UNSIGNED PK | Auto-increment |
| `code` | VARCHAR(20) | Required. Unique. e.g., 'lower_bunk', 'upper_bunk'. |
| `name` | VARCHAR(100) | Required. Display name. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Seeded Data**
| Code | Name | Description |
|---|---|---|
| single | Single Bed | Standalone single bed |
| lower_bunk | Lower Bunk | Lower bed in a bunk pair |
| upper_bunk | Upper Bunk | Upper bed in a bunk pair |

**Validation**
- Code must be unique
- Cannot delete if referenced by any bed

## CRUD Operations

**Create** — `GET /hostel/bed-types/create` → form | `POST /hostel/bed-types` → validates → saves → redirects with `#bed-types`

**List** — Tab in Hostel Setup | Columns: Code, Name, Status, Actions

**View** — `GET /hostel/bed-types/{id}` → detail view

**Edit** — `GET /hostel/bed-types/{id}/edit` → pre-filled form | `PUT /hostel/bed-types/{id}` → updates → redirects

**Delete (Soft)** — `DELETE /hostel/bed-types/{id}` → deactivates → soft deletes

**Restore** — `GET /hostel/bed-types/{id}/restore`

**Force Delete** — blocked if beds reference this type

**Toggle Status** — `POST /hostel/bed-types/{bed_type}/toggle-status` → AJAX JSON

**Trash Page** — `GET /hostel/bed-types/trash/view`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-bed-type.viewAny` |
| View details | `tenant.hostel-bed-type.view` |
| Create | `tenant.hostel-bed-type.create` |
| Edit/update | `tenant.hostel-bed-type.update` |
| Soft delete | `tenant.hostel-bed-type.delete` |
| View trash & restore | `tenant.hostel-bed-type.restore` |
| Force delete | `tenant.hostel-bed-type.forceDelete` |
