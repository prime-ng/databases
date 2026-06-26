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

### Student Uniqueness

- Each student can have only one dietary profile. If a profile already exists for a student, creating another is blocked with the message: "A dietary profile for this student already exists."
- Every profile must be linked to a valid existing student.

### Food Preference & Allergy Flags

- A food preference category must be selected (Veg, Non_Veg, Egg, or Jain).
- Allergy flags are yes/no toggles. When the nut allergy flag is enabled, the POS scan screen shows a red alert: "NUT ALLERGY — Verify meal items."
- Custom restrictions are free-form notes with no structured validation beyond character limits.
- Medical/dietary notes are free-form guidance fields with no structured validation beyond character limits.

### Profile Creation

- When the Cafeteria module is activated for a group of students, a default profile (Vegetarian, all allergy flags off) is automatically created for each student.
- If someone tries to create a second profile for a student who already has one, the system returns the message: "Student already has a dietary profile. Edit the existing profile instead."
- Profiles can be edited by the student (through their online portal) or by cafeteria staff and administrators.

### POS Scan Dietary Check

When a student's meal is scanned at the point of sale, the system checks their dietary flags and displays warnings:

- **Nut allergy** (if turned on): Shows a red banner that reads "NUT ALLERGY — Verify meal items."
- **Food preference** is compared against the food type of the items being purchased (see the Menu Items dietary conflict rules for details).
- All warnings are for display purposes only — the transaction is **not blocked** from proceeding.

### Deleting a Profile

- When a dietary profile is deleted, it stops being used for daily checks but the information is kept for historical records.
- Profiles are not automatically deleted when a student transfers or graduates — they must be removed manually if needed.
- If a profile was deleted by mistake, it can be restored using the standard restore option.

### List View

- Controller: DietaryProfileController@index. Gate: `tenant.cafeteria.dietary-profile.viewAny`.
- Columns: Student Name, Food Preference (badge), Allergies (icons), Restrictions, Status, Actions.
- Allergy icons: nut (🥜), gluten (🌾), dairy (🥛), onion/garlic (🧅).

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.cafeteria.dietary-profile.viewAny` |
| Update | `tenant.cafeteria.dietary-profile.update` |
