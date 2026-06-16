# Sick Bay Vitals — Requirements

## What It Does
Periodic vital-sign readings during a sick bay admission. Records temperature, pulse, BP, SpO2, weight, pain score, and other metrics at regular intervals for trend tracking.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `sick_bay_log_id` | BIGINT UNSIGNED FK → hst_sick_bay_log | Required. ON DELETE CASCADE. |
| `recorded_at` | TIMESTAMP | Required. |
| `recorded_by` | INT UNSIGNED FK → sys_users | Required. |
| `temperature_c` | DECIMAL(4,1) | Nullable. Celsius. |
| `pulse_bpm` | SMALLINT UNSIGNED | Nullable. |
| `respiratory_rate` | SMALLINT UNSIGNED | Nullable. |
| `bp_systolic` | SMALLINT UNSIGNED | Nullable. |
| `bp_diastolic` | SMALLINT UNSIGNED | Nullable. |
| `spo2_percent` | TINYINT UNSIGNED | Nullable. |
| `weight_kg` | DECIMAL(5,2) | Nullable. |
| `height_cm` | DECIMAL(5,2) | Nullable. |
| `pain_score` | TINYINT UNSIGNED | Nullable. 0-10. |
| `notes` | VARCHAR(500) | Nullable. |
| `is_alarm` | TINYINT(1) | Default 0. Abnormal reading flagged. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

- Vitals must be linked to an active sick bay admission
- Each reading is timestamped automatically
- Abnormal vitals (outside configurable ranges) set `is_alarm = 1`
- Vitals can be recorded even after discharge (follow-up)

## CRUD Operations

**Create** — `POST /hostel/sick-bay/{sickBay}/vitals` → stores a vital reading for the admission | Redirects back to sick bay detail

**List** — Displayed as a tab within the sick bay admission detail page | Shows vitals in a table with trend indication

**View** — `GET /hostel/sick-bay-vitals/{id}` → detail view

**Edit** — `GET /hostel/sick-bay-vitals/{id}/edit` | `PUT` → updates reading

**Delete (Soft)** — `DELETE /hostel/sick-bay-vitals/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-sick-bay-vitals.viewAny` |
| View details | `tenant.hostel-sick-bay-vitals.view` |
| Create | `tenant.hostel-sick-bay-vitals.create` |
| Edit/update | `tenant.hostel-sick-bay-vitals.update` |
| Soft delete | `tenant.hostel-sick-bay-vitals.delete` |
