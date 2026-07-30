# Dietary Profiles — Business Requirements

## What This Screen Does

The Dietary Profiles tab manages per-student dietary preferences, restrictions, and allergy flags. Each student has exactly one profile (enforced by `UNIQUE(student_id)`). Profiles drive the **dietary conflict check** (`assertNoDietaryConflict()`) during order placement — preventing students from ordering dishes incompatible with their registered dietary profile.

Profiles are displayed as a **card grid** (not a table). Each card shows the student's name (with food preference icon), their restriction flags as icons, and a toggle-switch for active/inactive status. Staff can create, edit, toggle-status, or delete profiles.

## When This Screen Is Used

- **Profile Setup**: Registering dietary preferences at enrollment or term start
- **Profile Updates**: Student changes dietary preference (e.g., Veg → Jain)
- **Conflict Prevention**: Ensuring menu ordering respects dietary rules
- **Status Management**: Toggling profiles active/inactive without deletion

## Key Fields

- **Student** (FK → `std_students`, UNIQUE) — One profile per student
- **Food Preference** (enum) — `Veg`, `Non_Veg`, `Egg`, `Jain`
- **Allergy Flags** (booleans, all default false):
  - `is_nut_allergy`
  - `is_dairy_allergy`
  - `is_gluten_allergy`
  - `is_soy_allergy`
- **Custom Restrictions** (text, nullable) — Free-text notes
- **Medical Dietary Note** (text, nullable) — Doctor-recommended notes
- **Is Active** (boolean, default true) — Toggle via `toggleStatus()`
- **Staff Name** — Who created/updated the profile (from `creator` relation)

## Business Rules

**One Profile Per Student:** UNIQUE constraint on `student_id`. The `updateOrCreate()` with `['student_id' => $data['student_id']]` ensures upsert — create if not exists, update if exists.

**Dietary Conflict Logic (BR-CAF-002):** Used during OrderService::placeOrder():
- Veg profile: blocks dish with food_type = Non_Veg or Egg
- Jain profile: blocks dish with food_type = Non_Veg or Egg
- Egg profile: blocks dish with food_type = Non_Veg
- Non_Veg profile: no blocking based on food_type
- Allergen keyword match: checks dish `dietary_notes` against student's allergy flags (keywords: nuts/peanuts/tree nuts → is_nut_allergy; dairy/milk/cheese → is_dairy_allergy; gluten/wheat → is_gluten_allergy; soy → is_soy_allergy)
- Staff override: users with `cafeteria.orders.viewAny` permission can skip dietary check

**Toggle Status:** `toggleStatus()` flips `is_active` between true/false. Used for temporarily disabling a profile without losing data.

**Soft Delete:** Model uses SoftDeletes. Delete removes from view but not physically.

**Activity Logging:**
- Create/Update: `"Dietary profile updated for {student}"`
- Toggle Status: `"Dietary profile {activated/deactivated} for {student}"`
- Delete: `"Dietary profile deleted for {student}"`

## Workflow

1. Staff navigates to Cafeteria → Orders & Attendance → Dietary Profiles tab
2. Staff sees card grid: each card shows Student Name + food preference icon + allergy flags + active toggle
3. Staff clicks "Add Profile" → modal form with student select, food preference radio, allergy checkboxes, text fields
4. Staff creates or saves → profile upserted via `updateOrCreate`
5. Staff toggles active/inactive via Ajax or form submit → status flipped
6. Staff deletes → soft delete with confirmation

## Related Screens

- **Orders** — First tab; dietary profiles are checked during order placement
- **Weekly Menus** — Menu items have `food_type` + `dietary_notes` that are checked against profiles

## Requirements

- MUST display dietary profiles at `/cafeteria/orders-attendance?tab=dietary-profiles` as card grid
- MUST authorize via `cafeteria.dietary.profile.*` policy gates
- MUST enforce UNIQUE(student_id) — one profile per student
- MUST support create/update via `updateOrCreate` with student_id as unique key
- MUST support toggle active/inactive status via `toggleStatus()`
- MUST support soft delete
- MUST show food preference icon and allergy flag icons on each card
- MUST enforce dietary conflict during order placement (BR-CAF-002)
- MUST log all profile mutations via activityLog()
