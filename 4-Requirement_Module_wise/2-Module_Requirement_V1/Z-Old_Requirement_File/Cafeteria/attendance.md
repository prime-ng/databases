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

### Attendance Record Rules

- Every attendance record must be linked to a valid existing student.
- Only existing meal categories can be selected for a record.
- The scan method must be one of: QR, Biometric, or Manual (defaults to QR).
- When the scan method is 'Manual', the staff member who performed the scan must be recorded. If left blank, the system shows: "Staff who performed the scan is required for manual entries."

### Preventing Duplicate Scans (BR-CAF-001)

- A student can only be scanned once per meal category per day. For example, a student cannot have two "Lunch" scans on the same day.
- If a student is scanned a second time (whether by QR, biometric, or any other method), the system does not create an error. Instead, it returns the existing record and shows the message: "Attendance already recorded for {meal category} on {meal date}."

### Scan Methods

- **QR Scan:** The student shows a QR code from their online portal. The POS camera scans it. No staff name is recorded.
- **Biometric Scan:** A fingerprint or facial recognition scan. No staff name is recorded.
- **Manual Scan:** A staff member selects the student from a list. In this case, the staff member's name is required and recorded.

### Data Immutability (No Editing or Deleting)

- Once an attendance record is created, it cannot be modified or deleted through the regular interface. There is no update or delete option, no active/inactive flag, and no soft delete.
- If a correction is absolutely needed, only a senior administrator can make it, and the change is recorded in the activity log. This is not available in the regular user interface.

### Integration with Meal Cards

- When a student pays for a meal using a Meal Card at the point of sale, the attendance record is created automatically at the same time as the payment transaction.
- The meal category is determined from the current meal session being run at the POS counter.

### List View

- Controller: MealAttendanceController@index. Gate: `tenant.cafeteria.meal-attendance.viewAny`.
- Tabular report with filters: date range, meal category, class/student search.
- Columns: Student Name, Class, Meal Category, Date, Time, Scan Method.

## Permissions

| Operation | Permission Key |
|---|---|
| View reports | `tenant.cafeteria.meal-attendance.viewAny` |
| Mark scan | `tenant.cafeteria.meal-attendance.scan` |
