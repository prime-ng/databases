# std_Attendance — Manual Test Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | StudentProfile |
| Feature / Screen | Attendance (daily QR scan / manual entry + bulk marking) |
| URLs | `GET /student-profile/attendance/create` · `POST /student-profile/attendance/scan` · `POST /student-profile/attendance/manual` · `GET /student-profile/bulk-attendance` · `POST /student-profile/bulk-attendance/store` |
| Route names | `attendance.create`, `attendance.scan`, `attendance.manual`, `attendance.bulk`, `attendance.bulk.store` |
| Controller | `AttendanceController` (`create`, `scanAttendance`, `manualAttendance`, `bulkAttendanceIndex`, `storeBulkAttendance`; plus dead `getAttendanceReport`) |
| Models | `StudentAttendance` (no SoftDeletes), `StudentAttendanceCorrection` |
| Policy / gates | `AttendancePolicy` → `tenant.attendance.{viewAny,view,create,update,delete,restore,forceDelete}` |
| Validation | Inline `$request->validate()` (no dedicated FormRequest) |
| Tables | `std_student_attendance`, `std_attendance_corrections` |
| Status ENUM | `Present, Absent, Late, Half Day, Short Leave, Leave` (Title Case, spaces) |
| CRUD type | Upsert via `updateOrCreate`; bulk empty status → hard delete |
| Soft delete | NO (StudentAttendance has no SoftDeletes trait) |
| Pagination | Medical incidents on bulk index paginate 10 (side panel) |
| Activity log | **None** — controller writes no activity logs |
| DB scope | TENANT (requires tenant init) |

**Prerequisites:** module `STUDENT` enabled in `modules_statuses.json`; `APP_ENV=testing`; tenant domain resolvable; a current `AcademicSession` (`is_current=1`); ≥1 active `sch_class_section_jnt` with linked students.

---

## 2. Business Conditions (detailed)

**Status values (all layers agree):** `Present`, `Absent`, `Late`, `Half Day`, `Short Leave`, `Leave`.
MySQL ENUM matching is case-insensitive on insert but stores the canonical Title Case; values with the wrong separator (`half_day` vs `Half Day`) do NOT match and are rejected/coerced-empty in strict mode — this is why bulk store's missing `in:` validation (BUG-STD-ATT-01) is risky.

**Upsert keys:**
- scan/manual: `(student_id, attendance_date, attendance_period)`
- bulk: `(student_id, academic_session_id, class_section_id, attendance_date)`

**Flow diagrams:**
```
Bulk save:
  form#attendanceForm POST /bulk-attendance/store
    for each attendance[student_id] = status:
      status non-empty  -> updateOrCreate(status, marked_by=auth id, marked_at=now)
      status empty/null -> delete matching record         (clear-all)
    commit -> redirect back  flash: "Attendance saved successfully."

Scan (QR):
  fetch POST /attendance/scan {qr_code,status:'Present',date,period:1,marked_by}
    student by qr -> else user.emp_code -> else {status:false,'Student not found with this QR code'}
    no current session -> {status:false,'... not enrolled in any current academic session'}
    else updateOrCreate -> {status:true,'Attendance recorded successfully', student, attendance}

Manual:
  fetch POST /attendance/manual {student_id,date,period,status,remarks,marked_by}
    Student::findOrFail(student_id)  (404 if missing)
    no current session -> {status:false,...}
    else updateOrCreate -> {status:true,'Attendance saved successfully', ...}
```

**Error/flash strings (verbatim):**
- Bulk success: `Attendance saved successfully.`
- Bulk failure: `Failed to save attendance: <msg>`
- No session (bulk index): `No active academic session found.`
- Scan success: `Attendance recorded successfully`
- Manual success: `Attendance saved successfully`
- Not found: `Student not found with this QR code`
- Not enrolled: `Student is not enrolled in any current academic session`

---

## 3. Manual Test Cases

### MTC-01 — Schema truth (DB)
| Step | Action | Expected |
|------|--------|----------|
| 1 | `SHOW COLUMNS FROM std_student_attendance` | 12 columns per DDL |
| 2 | `SHOW INDEX FROM std_student_attendance WHERE Non_unique=0` | unique on (student_id, attendance_date, attendance_period) |
| 3 | Inspect `status` COLUMN_TYPE | `enum('Present','Absent','Late','Half Day','Short Leave','Leave')` |
| 4 | `SHOW COLUMNS FROM std_attendance_corrections` | includes status enum(Pending,Approved,Rejected) |

### MTC-02 — Bulk apply + save (happy path)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin, open `/student-profile/bulk-attendance` | Bulk tab renders |
| 2 | Select an active class section; pick today | Student rows load with radio groups |
| 3 | Bulk actions → Present | All rows show Present checked |
| 4 | Click Save | Redirect back, toast `Attendance saved successfully.` |
| 5 | `SELECT status FROM std_student_attendance WHERE attendance_date=today AND class_section_id=X` | each = `Present` |
| 6 | `SELECT marked_by, marked_at` | marked_by=admin id, marked_at not null |

### MTC-03 — Individual override
| Step | Action | Expected |
|------|--------|----------|
| 1 | After bulk Present, set student #1 → Absent, #2 → Late | only those two change |
| 2 | Save; query DB | #1=Absent, #2=Late, rest=Present |

### MTC-04 — Clear all (delete branch)
| Step | Action | Expected |
|------|--------|----------|
| 1 | With existing records, post `attendance[id]=''` (Clear All + Save) | records for that date deleted |
| 2 | `SELECT ... WHERE attendance_date=X` | 0 rows for cleared students |

### MTC-05 — Upsert idempotency
| Step | Action | Expected |
|------|--------|----------|
| 1 | Save Present then re-save Absent for same student/date/period | 1 row only, status=Absent (no duplicate) |

### MTC-06 — Validation (scan)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST /attendance/scan without qr_code | 422, errors.qr_code |
| 2 | POST with status=`half_day` | 422, errors.status |
| 3 | POST with period=9 | 422, errors.period |
| 4 | POST unknown qr_code | 200 `{status:false,'Student not found with this QR code'}` |

### MTC-07 — Validation (manual)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST /attendance/manual without student_id | 422, errors.student_id |
| 2 | POST status=`Excused` | 422, errors.status |
| 3 | POST remarks 256 chars | 422, errors.remarks |
| 4 | POST student_id=999999999 | 404 (findOrFail) |

### MTC-08 — Validation (bulk store)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST /bulk-attendance/store missing class_section_id | 422 |
| 2 | POST class_section_id=999999999 | 422 (exists rule) |
| 3 | POST without attendance array | 422 |

### MTC-09 — Permissions
| Step | Action | Expected |
|------|--------|----------|
| 1 | Guest visits /student-profile/bulk-attendance | redirect /login |
| 2 | Permission-less user posts to /bulk-attendance/store | 403 (Gate::authorize) |
| 3 | Inspect controller | create/scan/manual/store gate `tenant.attendance.create`; index gates `tenant.attendance.viewAny` |

### MTC-10 — FK integrity
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect information_schema FK rules | student_id→std_students CASCADE; class_section_id→sch_class_section_jnt CASCADE; marked_by→sys_users SET NULL; correction.attendance_id→std_student_attendance CASCADE |

### MTC-11 — Defect / gap verification (source read)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Grep AttendanceController + StudentController for `dd($request->all());s` | absent (BUG-STD-P3-01 remediated) |
| 2 | Grep AttendanceController for `75` / `notif` | absent (GAP-STD-22) |
| 3 | `Route::has('student-profile.attendance.report')` | false (BUG-STD-ATT-02 — getAttendanceReport dead) |
| 4 | Inspect storeBulkAttendance body | validates array, NO `in:Present...` on status (BUG-STD-ATT-01) |
| 5 | Search routes/controllers for attendance-correction workflow | none (GAP-STD-ATT-03) |
