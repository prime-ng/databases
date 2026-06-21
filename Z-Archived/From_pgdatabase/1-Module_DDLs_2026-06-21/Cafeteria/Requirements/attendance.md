# Meal Attendance — Requirements

## Parent Tab: Orders & Attendance

## What It Does
QR/biometric/manual meal scan records — idempotent per student per meal per day. Tracks who ate what meal and when.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `meal_date` | DATE | Required. |
| `meal_category_id` | INT UNSIGNED FK → caf_menu_categories | Required. ON DELETE RESTRICT. |
| `scanned_at` | TIMESTAMP | Default CURRENT_TIMESTAMP. Exact scan timestamp. |
| `scan_method` | ENUM('QR','Biometric','Manual') | Default 'QR'. |
| `counter_name` | VARCHAR(100) | Nullable. POS counter name. |
| `scanned_by` | INT UNSIGNED FK → sys_users | Nullable. Staff for manual scans. |
| `created_at` | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `student_id` | Required, exists:std_students,id | "The selected student is invalid." |
| `meal_date` | Required, date | |
| `meal_category_id` | Required, exists:caf_menu_categories,id | |
| `scan_method` | Required, enum: QR/Biometric/Manual | Default 'QR'. |
| `scanned_by` | Required if scan_method = 'Manual' | "Staff who performed the scan is required for manual entries." |

### Idempotency (BR-CAF-001)

- UNIQUE KEY on `(student_id, meal_date, meal_category_id)`: one scan per student per meal per day.
- Double-scan (QR or biometric): system returns existing record instead of throwing error.
- Flash message: "Attendance already recorded for {meal_category} on {meal_date}."

### Scan Methods

- **QR:** Student presents QR code from portal. Scanned by POS camera. `scanned_by` = NULL.
- **Biometric:** Fingerprint/face scan. `scanned_by` = NULL.
- **Manual:** Staff selects student from list. `scanned_by` required.

### Data Immutability

- No `updated_at`, no `is_active`, no `deleted_at`. Once created, cannot be modified or deleted.
- Correction needed: senior admin only, with activity log entry. Not exposed to regular UI.

### Integration with Meal Cards

- When MealCard-mode POS transaction is processed, attendance record is auto-created in same transaction.
- `meal_category_id` derived from POS session's current meal context.

### List View

- Controller: MealAttendanceController@index. Gate: `tenant.cafeteria.meal-attendance.viewAny`.
- Tabular report with filters: date range, meal category, class/student search.
- Columns: Student Name, Class, Meal Category, Date, Time, Scan Method.

## Permissions

| Operation | Permission Key |
|---|---|
| View reports | `tenant.cafeteria.meal-attendance.viewAny` |
| Mark scan | `tenant.cafeteria.meal-attendance.scan` |
