# Meal Attendance — Business Requirements

## What This Screen Does

The Meal Attendance tab tracks which students physically received their meals on a given day. Each attendance record links a **student** to a **meal category** on a **meal date**. The system enforces idempotency via a UNIQUE constraint on `(student_id, meal_date, meal_category_id)` — a student can only be marked once per meal per day.

Attendance can be recorded through three **scan methods**: `qr` (student QR code card scanned via device), `manual` (staff types student ID in form), or `pos` (checkout transaction auto-logs attendance). The QR scan flow uses an Ajax endpoint (`apiScan`) that returns success or already-marked response. The manual form submits via standard POST (`markAttendance`).

## When This Screen Is Used

- **Meal Distribution**: Staff marks attendance as students collect their meals
- **QR Scanning**: Fast scan of QR-printed student card at meal counter
- **Manual Entry**: Staff types student ID + meal category
- **Attendance Review**: Viewing who has/hasn't been marked for a given meal
- **Bulk Marking**: (Feature mentioned but not exposed in UI — API ready)
- **QR Code Management**: Download/print QR codes for student groups

## Key Fields

- **Student** (FK → `std_students`) — The student receiving the meal
- **Meal Date** (date) — Calendar date of meal service
- **Meal Category** (FK → `caf_menu_categories`) — Which meal slot (Breakfast/Lunch/etc.)
- **Scanned At** (timestamp) — When attendance was recorded
- **Scan Method** (enum) — `qr`, `manual`, `pos`
- **Notes** (text, nullable)

## Business Rules

**Idempotency (UNIQUE):** `(student_id, meal_date, meal_category_id)` is unique. The `apiScan()` uses `firstOrCreate()` — returns existing record silently if already marked. No duplicate error thrown.

**QR** → **Manual Mapping:** Students have a `qr_number` (auto-generated in `std_students`). The QR scan sends the decoded QR value (student's QR number) to the API endpoint. The controller maps `qr_number` to `student_id` via `Student::where('qr_number', $qr)->firstOrFail()`.

**Manual Form:** The `markAttendance()` method accepts `student_id`, `meal_category_id`, `meal_date` directly from a form, validated by `StoreMealAttendanceRequest`.

**POS Auto-Attendance:** When `PosService::processTransaction()` creates an order with a meal category, it auto-creates a MealAttendance record with scan_method=pos.

**Soft Delete:** The model uses SoftDeletes. The tab query uses `->whereNull('deleted_at')` (implicit from Model::all()).

**Activity Logging:**
- Create: `"Meal attendance marked for {student} - {mealCategory}"`
- API Scan: `"QR Scan: {student} - {mealCategory}"`

## Workflow

1. Staff navigates to Cafeteria → Orders & Attendance → Meal Attendance tab
2. Default view shows today's attendance log: paginated table with Student, Date, Meal Category, Scanned At, Scan Method
3. Quick-mark form is at the top: student search/type, meal_category dropdown (pre-set to today), optional date picker
4. Staff submits form to mark attendance manually
5. OR staff uses QR scanner device → posts to `apiScan` endpoint → table refreshes
6. Staff can delete an attendance record (soft delete) via action button

## Related Screens

- **Orders** — First tab; pre-orders before meal service
- **QR Code Generation** — `/cafeteria/attendance/qr-codes` generates printable QR batch

## Requirements

- MUST display attendance at `/cafeteria/orders-attendance?tab=attendance` as paginated table with date + category columns
- MUST authorize via `cafeteria.meal.attendance.*` policy gates
- MUST enforce UNIQUE(student_id, meal_date, meal_category_id) for idempotency
- MUST support QR scan via `apiScan()` using student's qr_number → student_id mapping
- MUST support manual mark via `markAttendance()` with date picker + category dropdown
- MUST support soft delete of attendance records
- MUST log attendance creation and QR scans via activityLog()
- MUST support POS auto-attendance on checkout transaction with meal category
