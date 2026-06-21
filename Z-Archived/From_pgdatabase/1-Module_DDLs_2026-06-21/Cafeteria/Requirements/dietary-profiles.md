# Dietary Profiles — Requirements

## Parent Tab: Orders & Attendance

## What It Does
Per-student dietary preference and restriction profile — one profile per student. Flags food preferences, allergies, and restrictions that are checked at POS scan time.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `student_id` | INT UNSIGNED FK → std_students | Required. Unique. One profile per student. |
| `food_preference` | ENUM('Veg','Non_Veg','Egg','Jain') | Default 'Veg'. |
| `is_no_onion_garlic` | TINYINT(1) | Default 0. |
| `is_gluten_free` | TINYINT(1) | Default 0. |
| `is_nut_allergy` | TINYINT(1) | Default 0. Flagged on POS scan. |
| `is_dairy_free` | TINYINT(1) | Default 0. |
| `custom_restrictions` | TEXT | Nullable. Free-form notes. |
| `medical_dietary_note` | TEXT | Nullable. Doctor-recommended guidance. |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

## Business Rules

### Field-Level Validation

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `student_id` | Required, exists:std_students,id, unique | "A dietary profile for this student already exists." |
| `food_preference` | Required, enum: Veg/Non_Veg/Egg/Jain | |
| `is_nut_allergy` | Required, boolean | If true: POS scan shows RED alert "NUT ALLERGY — Verify meal items." |
| `custom_restrictions` | Nullable, string, max:500 | |
| `medical_dietary_note` | Nullable, string, max:1000 | |

### Profile Creation

- Auto-created with defaults (Veg, all flags 0) when Cafeteria module is activated for a student body.
- If profile already exists, create attempt returns: "Student already has a dietary profile. Edit the existing profile instead."
- Editable by student (via portal) or admin/cafeteria staff.

### POS Scan Dietary Check

At POS scan time, the student's dietary flags are read and displayed as warnings:
- `is_nut_allergy = true`: RED banner "NUT ALLERGY — Verify meal items."
- `food_preference` cross-checked against purchased items' `food_type` (see Menu Items dietary conflict rules).
- Warnings are display-only — transaction is NOT blocked.

### Soft Delete

- Soft-deleting hides profile from active checks but retains data for history.
- Not auto-deleted on student transfer/graduation.
- Restore: standard pattern.

### List View

- Controller: DietaryProfileController@index. Gate: `tenant.cafeteria.dietary-profile.viewAny`.
- Columns: Student Name, Food Preference (badge), Allergies (icons), Restrictions, Status, Actions.
- Allergy icons: nut (🥜), gluten (🌾), dairy (🥛), onion/garlic (🧅).

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.cafeteria.dietary-profile.viewAny` |
| Update | `tenant.cafeteria.dietary-profile.update` |
