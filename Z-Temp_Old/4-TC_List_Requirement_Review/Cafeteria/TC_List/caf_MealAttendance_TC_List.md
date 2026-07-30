# caf_MealAttendance — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** Meal Attendance (QR Scan + Manual Mark + POS Auto-Log + Idempotency)
**DB scope:** TENANT-side (`caf_meal_attendances`) · **Test style:** Browser Dusk + API
**Primary table:** `caf_meal_attendances` · **Module URL prefix:** `/cafeteria/orders-attendance?tab=attendance`
**Test file:** `caf_MealAttendance_TestCas.php`
**Tab:** Meal Attendance (second tab of Orders & Attendance)

Controllers:
- `MealAttendanceController` — index, markAttendance (POST), apiScan (POST), destroy, qrCodes (GET), downloadQrPdf (GET)
- `CafeteriaController::ordersAttendance()` — loads attendance data for tabbed page

Routes (`cafeteria.` prefix):
- `GET /cafeteria/orders-attendance` — tabbed page (attendance tab)
- `POST /cafeteria/attendance/mark` — manual mark
- `POST /cafeteria/attendance/api/scan` — QR scan via API
- `DELETE /cafeteria/attendance/{attendance}` — delete
- `GET /cafeteria/attendance/qr-codes` — QR code generation page
- `GET /cafeteria/attendance/qr-codes/download` — bulk QR PDF download

**DDL reference:** `caf_meal_attendances` (Cafeteria DDL)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `caf_meal_attendances`: id (INT UNSIGNED PK AI), student_id (INT UNSIGNED NOT NULL FK → std_students.id ON DELETE CASCADE), meal_date (DATE NOT NULL), meal_category_id (INT UNSIGNED NOT NULL FK → caf_menu_categories.id ON DELETE RESTRICT), scanned_at (TIMESTAMP DEFAULT CURRENT_TIMESTAMP), scan_method (ENUM('qr','manual','pos') DEFAULT 'qr'), counter_name (VARCHAR 50 NULL), scanned_by (INT UNSIGNED NULL FK → sys_users.id), notes (TEXT NULL), created_by, created_at, updated_at, deleted_at. UNIQUE (student_id, meal_date, meal_category_id). Indexes: idx_caf_ma_student, idx_caf_ma_date, idx_caf_ma_category, idx_caf_ma_student_date | DDL |
| BC-DB-02 | Model `MealAttendance`: table caf_meal_attendances, SoftDeletes, fillable 6 fields, casts: meal_date→date, scanned_at→datetime. Relations: student() belongsTo, mealCategory() belongsTo, creator() belongsTo User. Scopes: today() | Model |

### BC-VAL — Validation
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `student_id` required integer exists:std_students,id (manual form) | FR |
| BC-VAL-02 | `meal_category_id` required integer exists:caf_menu_categories,id (manual + scan) | FR |
| BC-VAL-03 | `meal_date` required date nullable (defaults to today if empty) | FR |
| BC-VAL-04 | `qr_number` required exists:std_students,qr_number (scan endpoint) | Ctrl |
| BC-VAL-05 | `scan_method` nullable string in:qr,manual,pos (defaults to manual) | Ctrl |

### BC-AUTH — Authorization (MealAttendancePolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.meal.attendance` (viewAny) | View |
| BC-AUTH-02 | create/mark gate `cafeteria.meal.attendance.create` | Policy |
| BC-AUTH-03 | view gate `cafeteria.meal.attendance.view` (not explicitly used in tab) | Policy |
| BC-AUTH-04 | delete gate `cafeteria.meal.attendance.delete` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Attendance tab: paginated table with Student, Date, Meal Category, Scanned At, Scan Method badge | View |
| BC-BIZ-02 | Quick-mark form at top: student_id (select2 or typeahead), meal_category dropdown, date picker | View |
| BC-BIZ-03 | Default meal_category: first from $mealCategories list | View |
| BC-BIZ-04 | Default date: today's date | View |
| BC-BIZ-05 | QR scan endpoint: POST with qr_number → firstOrCreate with student_id, meal_date, meal_category_id, scan_method=qr | Ctrl |
| BC-BIZ-06 | QR scan: maps qr_number to student_id via Student::where('qr_number',$qr)->firstOrFail() | Ctrl |
| BC-BIZ-07 | Manual mark: POST with student_id, meal_category_id, meal_date → create with scan_method=manual | Ctrl |
| BC-BIZ-08 | Manual mark: if meal_date blank, defaults to today (Carbon::today()) | Ctrl |
| BC-BIZ-09 | Idempotency: firstOrCreate returns existing record if (student_id, meal_date, meal_category_id) already exists | Ctrl |
| BC-BIZ-10 | QR scan response: success={attendance_id, student_name, meal_category, status:'marked'} or already={status:'already_marked'} | Ctrl |
| BC-BIZ-11 | Soft delete: destroy() sets deleted_at, not physically removed | Ctrl |
| BC-BIZ-12 | Activity logged for create and apiScan ("QR Scan: {student} - {mealCategory}") | Ctrl |
| BC-BIZ-13 | POS auto-attendance: processTransaction creates MealAttendance with scan_method=pos | Service |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Duplicate QR scan for same (student, date, category) → returns existing record, no duplicate | Ctrl |
| BC-EDG-02 | Invalid qr_number → ModelNotFoundException → 422 | Ctrl |
| BC-EDG-03 | Invalid student_id → validation error (exists) | Val |
| BC-EDG-04 | Invalid meal_category_id → validation error (exists) | Val |
| BC-EDG-05 | Delete already-deleted record → 404 (model not found, SoftDeletes) | Ctrl |

---

## 2. Test Case List

### Screen 1: Meal Attendance Tab (GET /cafeteria/orders-attendance?tab=attendance)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMA-P10 | Positive | View | Attendance tab: paginated table with Student, Date, Meal Category, Scanned At, Scan Method badge | Rendered | test_caf_ma_10 | Automated |
| TC-CAFMA-P11 | Positive | View | Quick-mark form with student select, meal_category dropdown, date picker | Form visible | test_caf_ma_11 | Automated |
| TC-CAFMA-P12 | Positive | View | Meal category dropdown populated from $mealCategories | Dropdown | test_caf_ma_12 | Automated |
| TC-CAFMA-P13 | Positive | View | Date picker defaults to today | Default date | test_caf_ma_13 | Automated |
| TC-CAFMA-P14 | Positive | View | Empty state "No attendance records found" | Empty | test_caf_ma_14 | Automated |
| TC-CAFMA-P15 | Positive | View | Scan method badges: qr=info, manual=default, pos=success | Badges | test_caf_ma_15 | Automated |

### Screen 2: Manual Mark (POST /cafeteria/attendance/mark)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMA-P30 | Positive | Ctrl | Mark valid attendance → record created, redirect "Meal attendance marked for {student}" | Created | test_caf_ma_30 | Automated |
| TC-CAFMA-P31 | Positive | Ctrl | Mark with blank meal_date → defaults to today | Today | test_caf_ma_31 | Automated |
| TC-CAFMA-N32 | Positive | Val | Mark with invalid student_id → validation error | Error | test_caf_ma_32 | Automated |
| TC-CAFMA-N33 | Positive | Val | Mark with invalid meal_category_id → validation error | Error | test_caf_ma_33 | Automated |

### Screen 3: QR Scan (POST /cafeteria/attendance/api/scan)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMA-P50 | Positive | Ctrl | Valid QR scan → attendance_id, student_name, meal_category, status:'marked' | Marked | test_caf_ma_50 | Automated |
| TC-CAFMA-P51 | Positive | Ctrl | Duplicate QR scan → returns existing record, status:'already_marked' | Idempotent | test_caf_ma_51 | Automated |
| TC-CAFMA-P52 | Positive | Ctrl | QR scan logs activity "QR Scan: {student} - {mealCategory}" | Logged | test_caf_ma_52 | Automated |
| TC-CAFMA-N53 | Negative | Biz | Invalid qr_number → 422 error | Error | test_caf_ma_53 | Automated |

### Screen 4: Delete (DELETE /cafeteria/attendance/{attendance})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMA-P70 | Positive | Ctrl | Delete attendance → soft deleted, redirect | Deleted | test_caf_ma_70 | Automated |
| TC-CAFMA-N71 | Negative | Ctrl | Delete already deleted → 404 | NotFound | test_caf_ma_71 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMA-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_caf_ma_200 | Automated |
| TC-CAFMA-N201 | Negative | Auth | Without create → 403 on manual mark/scan | 403 | test_caf_ma_201 | Automated |
| TC-CAFMA-N202 | Negative | Auth | Without delete → 403 on delete | 403 | test_caf_ma_202 | Automated |
