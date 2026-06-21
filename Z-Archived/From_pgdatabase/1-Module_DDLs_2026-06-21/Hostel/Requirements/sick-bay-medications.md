# Sick Bay Medications — Requirements

## What It Does
Medication administration log per sick bay admission. Records every medication administered — name, dosage, route, prescribed by, administered by, and timestamps.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `sick_bay_log_id` | BIGINT UNSIGNED FK → hst_sick_bay_log | Required. ON DELETE CASCADE. |
| `medication_name` | VARCHAR(150) | Required. |
| `generic_name` | VARCHAR(150) | Nullable. |
| `dose` | VARCHAR(50) | Required. '500mg', '10ml', '2 tablets'. |
| `route` | ENUM(oral, topical, inhalation, injection_im, injection_iv, injection_sc, other) | Default 'oral'. |
| `prescribed_by` | VARCHAR(150) | Nullable. Free-text doctor name. |
| `prescribed_by_user_id` | INT UNSIGNED FK → sys_users | Nullable. |
| `administered_at` | TIMESTAMP | Required. |
| `administered_by` | INT UNSIGNED FK → sys_users | Required. |
| `is_self_administered` | TINYINT(1) | Default 0. |
| `notes` | VARCHAR(500) | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

- Medications must be linked to an active sick bay admission
- Each administration is a separate record
- Route determines how the medication was given

## CRUD Operations

**Create** — `POST /hostel/sick-bay/{sickBay}/medications` → stores medication record | Redirects to sick bay detail

**List** — Displayed as a tab within sick bay admission detail page | Shows medication history table

**View** — `GET /hostel/sick-bay-medications/{id}` → detail

**Edit** — `GET /hostel/sick-bay-medications/{id}/edit` | `PUT` → updates

**Delete (Soft)** — `DELETE /hostel/sick-bay-medications/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-sick-bay-medication.viewAny` |
| View details | `tenant.hostel-sick-bay-medication.view` |
| Create | `tenant.hostel-sick-bay-medication.create` |
| Edit/update | `tenant.hostel-sick-bay-medication.update` |
| Soft delete | `tenant.hostel-sick-bay-medication.delete` |
