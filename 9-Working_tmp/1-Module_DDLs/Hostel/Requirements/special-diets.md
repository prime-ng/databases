# Special Diets — Requirements

## What It Does
Tracks students with special dietary requirements (diabetic, Jain, gluten-free, nut allergy, religious fasting, custom). Allows mess staff to view and accommodate per-meal dietary needs.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `diet_type` | ENUM(diabetic, jain_vegetarian, gluten_free, nut_allergy, religious_fasting, custom) | Required. |
| `custom_description` | VARCHAR(300) | Nullable. |
| `fasting_days_json` | JSON | Nullable. |
| `effective_from` | DATE | Required. |
| `effective_to` | DATE | Nullable. |
| `prescribed_by` | VARCHAR(150) | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

- A student can have multiple diet types
- Medical diets require a doctor's note
- Mess staff see per-meal list of active special diets

## CRUD Operations

**Create** — `GET /hostel/mess/special-diets/create` → form | `POST /hostel/mess/special-diets` → validates → saves → redirects

**List** — Tab in Mess & Dining | Paginated

**Get Students (AJAX)** — `GET /hostel/mess/special-diets/get-students` → JSON

**Toggle Status** — `POST /hostel/mess/special-diets/{diet}/toggle-status` → JSON

**Edit** — `GET /hostel/mess/special-diets/{id}/edit` | `PUT`

**Delete (Soft)** — `DELETE /hostel/mess/special-diets/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View | `tenant.hostel-special-diet.viewAny` |
| Create | `tenant.hostel-special-diet.create` |
| Edit | `tenant.hostel-special-diet.update` |
