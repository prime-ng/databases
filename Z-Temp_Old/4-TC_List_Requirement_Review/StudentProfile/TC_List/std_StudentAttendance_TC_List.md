# std_StudentAttendance — Test Case List

**Module:** StudentProfile (CODE `STD`, prefix `std_`) · **Feature:** Student Attendance (Scan QR + Manual Entry + Bulk Marking)
**DB scope:** TENANT-side (`std_*` → tenant DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary table:** `std_student_attendance` · **Module URL prefix:** `/student-profile`
**Test file:** `std_Attendance_TestCas.php`
**Checklists applied:** `Gaurav_list.md` + `Shailesh_list.md`

Routes:
- `GET  /student-profile/attendance/create` — AttendanceController@create (Scan QR + Manual Entry screen)
- `POST /student-profile/attendance/scan` — AttendanceController@scanAttendance (JSON)
- `POST /student-profile/attendance/manual` — AttendanceController@manualAttendance (JSON)
- `GET  /student-profile/bulk-attendance` — AttendanceController@bulkAttendanceIndex (Bulk marking pane)
- `POST /student-profile/bulk-attendance/store` — AttendanceController@storeBulkAttendance

---

## 2. Test Case List

### Screen 1: Attendance Create Page (Scan QR + Manual Entry)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ATT-P10 | Positive | View | Attendance create screen loads with scan QR and manual sections | Both tabs rendered | test_attendance_10 | Automated |
| TC-ATT-P62 | Positive | View | Manual status buttons for all 6 statuses (Present/Absent/Late/Half Day/Short Leave/Leave) | All present | test_attendance_62 | Automated |

### Screen 2: QR Scan Attendance (POST /attendance/scan)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ATT-P14 | Positive | Ctrl | Valid QR scan persists attendance record | Row created in DB | test_attendance_14 | Automated |
| TC-ATT-P18 | Positive | Ctrl | Marked_by and marked_at recorded on scan | Both fields populated | test_attendance_18 | Automated |
| TC-ATT-P19 | Positive | Ctrl | Re-scan same student+date+period does not create duplicate (upsert) | Single row, updated | test_attendance_19 | Automated |
| TC-ATT-N30 | Negative | Ctrl | Scan missing qr_code → rejected | 422 | test_attendance_30 | Automated |
| TC-ATT-N31 | Negative | Ctrl | Scan invalid status (not in: Present,Absent,Late,Half Day,Short Leave,Leave) → rejected | 422 | test_attendance_31 | Automated |
| TC-ATT-N32 | Negative | Ctrl | Scan period out of range (min:1 max:8) → rejected | 422 | test_attendance_32 | Automated |
| TC-ATT-N39 | Negative | Ctrl | Scan unknown QR code → student not found error | JSON error message | test_attendance_39 | Automated |
| TC-ATT-N45 | Negative | Ctrl | Scan with no current academic session → business error | Error message | test_attendance_45 | Automated |

### Screen 3: Manual Attendance Entry (POST /attendance/manual)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ATT-P14 | Positive | Ctrl | Valid manual entry persists attendance record | Row created in DB | test_attendance_14 | Automated |
| TC-ATT-N33 | Negative | Ctrl | Manual missing student_id → rejected | 422 | test_attendance_33 | Automated |
| TC-ATT-N34 | Negative | Ctrl | Manual invalid status → rejected | 422 | test_attendance_34 | Automated |
| TC-ATT-N35 | Negative | Ctrl | Manual remarks exceeds max length → rejected | 422 | test_attendance_35 | Automated |
| TC-ATT-N44 | Negative | Ctrl | Manual unknown student_id → error | Error response | test_attendance_44 | Automated |

### Screen 4: Bulk Attendance Index (GET /bulk-attendance)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ATT-P11 | Positive | View | Bulk attendance index page loads with form, select, bulk-pane | Elements present | test_attendance_11 | Automated |
| TC-ATT-P12 | Positive | View | Bulk-apply "Present" marks all rows | All rows Present | test_attendance_12 | Automated |
| TC-ATT-P13 | Positive | View | Individual override after bulk apply | Overridden row changes | test_attendance_13 | Automated |
| TC-ATT-P15 | Positive | View | Mixed bulk + individual saved correctly on submit | DB reflects mix | test_attendance_15 | Automated |
| TC-ATT-P16 | Positive | View | Clear all removes records on save | Records deleted | test_attendance_16 | Automated |
| TC-ATT-P17 | Positive | View | Reload shows persisted selections | Previous values restored | test_attendance_17 | Automated |
| TC-ATT-P22 | Positive | View | Date filter loads previously saved attendance for that date | Saved attendance shown as-is | Planned |
| TC-ATT-P61 | Positive | View | Bulk actions dropdown lists all 6 statuses | 6 options present | test_attendance_61 | Automated |
| TC-ATT-P70 | Positive | Ctrl | All 6 statuses persist via bulk store | Statuses saved/retrieved | test_attendance_70 | Automated |
| TC-ATT-P71 | Positive | Ctrl | Bulk store saves with period=0 (default) | period = 0 | test_attendance_71 | Automated |
| TC-ATT-N60 | Negative | View | No class_section selected shows info state | Info message displayed | test_attendance_60 | Automated |

### Screen 5: Bulk Attendance Store (POST /bulk-attendance/store)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ATT-N36 | Negative | Ctrl | Bulk store missing attendance_date and class_section_id → rejected | 422 | test_attendance_36 | Automated |
| TC-ATT-N37 | Negative | Ctrl | Bulk store non-existing class_section_id → rejected | 422 | test_attendance_37 | Automated |
| TC-ATT-N38 | Negative | Ctrl | Bulk store missing attendance array → rejected | 422 | test_attendance_38 | Automated |
| TC-ATT-N97 | Negative | Audit | Bulk store lacks status `in:` validation — accepts arbitrary status (BUG-STD-ATT-01) | Gap documented | test_attendance_97 | Automated |

### Screen 6: Attendance Corrections

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ATT-P20 | Positive | DDL | std_attendance_corrections status ENUM matches DDL | Enum values correct | test_attendance_20 | Automated |
| TC-ATT-N98 | Negative | Audit | Correction workflow is unimplemented (GAP-STD-ATT-03) — no controller/route | Gap documented | test_attendance_98 | Automated |

### Screen 7: Attendance Reports (dead route)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ATT-N96 | Negative | Audit | getAttendanceReport() has NO registered route (BUG-STD-ATT-02) | Route absent | test_attendance_96 | Automated |

### Database — Foreign Keys

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ATT-D40 | Integrity | DDL | student_id → std_students ON DELETE CASCADE | CASCADE | test_attendance_40 | Automated |
| TC-ATT-D41 | Integrity | DDL | class_section_id → sch_class_section_jnt ON DELETE CASCADE | CASCADE | test_attendance_41 | Automated |
| TC-ATT-D42 | Integrity | DDL | marked_by → sys_users ON DELETE SET NULL | SET NULL | test_attendance_42 | Automated |
| TC-ATT-D43 | Integrity | DDL | correction attendance_id → std_student_attendance ON DELETE CASCADE | CASCADE | test_attendance_43 | Automated |

### Cross-Cutting — Auth, Tenancy, Schema, Defects

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ATT-P01 | Schema | DDL/Model | Migration, model, fillable, ENUM, unique keys, corrections schema | All asserts pass | test_attendance_01 | Automated |
| TC-ATT-P50 | Auth | Ctrl | Controller gates wired (tenant.attendance.create, tenant.attendance.viewAny) | Gates present | test_attendance_50 | Automated |
| TC-ATT-P51 | Auth | Policy | Policy exposes all ability methods | Methods present | test_attendance_51 | Automated |
| TC-ATT-N52 | Auth | Middleware | Guest redirected to /login | /login | test_attendance_52 | Automated |
| TC-ATT-N53 | Auth | Ctrl | Limited user forbidden on bulk store | 403 | test_attendance_53 | Automated |
| TC-ATT-T90 | Tenancy | Tenant | Attendance records scoped to current tenant | Resolvable | test_attendance_90 | Automated |
| TC-ATT-P91 | Security | Ctrl | Remarks free text stored without HTML execution | Not executed | test_attendance_91 | Automated |
| TC-ATT-N94 | Defect | Audit | BUG-STD-P3-01: debug comment `// dd(...)` absent from source | Comment absent | test_attendance_94 | Automated |
| TC-ATT-N95 | Defect | Audit | GAP-STD-22: attendance <75% threshold notification not implemented | Feature absent | test_attendance_95 | Automated |

---

**Total: 44 test methods (all Automated, 0 Planned).**
