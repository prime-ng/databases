# std_Attendance — Test Case List & Requirements

**Module:** StudentProfile · **Feature/Screen:** Attendance · **Prefix:** `std_` · **DB scope:** TENANT
**Primary tables:** `std_student_attendance`, `std_attendance_corrections`
**Controller:** `Modules/StudentProfile/app/Http/Controllers/AttendanceController.php`
**Models:** `StudentAttendance`, `StudentAttendanceCorrection` · **Policy:** `AttendancePolicy`
**Test style:** Browser Dusk (`extends DuskTestCase`) — mirrors committed StudentProfile sibling `spr_BulkAttendance_TestCas.php` (this file supersedes it: daily scan + manual + bulk in ONE file).
**Test file:** `std_Attendance_TestCas.php` (class `std_Attendance_TestCas`, 44 methods).

> **Status casing (authoritative):** DDL ENUM = `('Present','Absent','Late','Half Day','Short Leave','Leave')` — **Title Case with spaces**. The live views (`student-settings/index.blade.php` bulk radios; `student-attendance/create.blade.php` manual buttons) and the scan/manual FormRequest `in:` rule all use this exact casing. The prior sibling used lowercase/underscore (`half_day`, `short_leave`) — WRONG; corrected here.

---

## 1. Business Conditions

### BC-DB (schema · Source: DDL-std_student_attendance / DDL-std_attendance_corrections)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `std_student_attendance` has id, student_id, academic_session_id, class_section_id, attendance_date, attendance_period, status, remarks, marked_by, marked_at, timestamps | DDL |
| BC-DB-02 | `status` ENUM = Present/Absent/Late/Half Day/Short Leave/Leave (Title Case) NOT NULL | DDL |
| BC-DB-03 | `attendance_period` TINYINT UNSIGNED DEFAULT 0 | DDL |
| BC-DB-04 | UNIQUE KEY (student_id, attendance_date, attendance_period) | DDL |
| BC-DB-05 | KEY idx_std_att_class_date (class_section_id, attendance_date) | DDL |
| BC-DB-06 | `std_attendance_corrections`: attendance_id, requested_by, requested_status ENUM(6), requested_period, reason TEXT, status ENUM(Pending/Approved/Rejected) DEFAULT Pending, admin_remarks, action_by, action_at | DDL |
| BC-DB-07 | StudentAttendance model: NO SoftDeletes (hard deletes), casts attendance_date=>date, marked_at=>datetime | Model source |

### BC-VAL (validation · Source: Controller inline `$request->validate()`)
| ID | Rule | Message/Behaviour | Source |
|----|------|-------------------|--------|
| BC-VAL-01 | scan `qr_code` required|string | 422 on missing | Controller@scanAttendance |
| BC-VAL-02 | scan/manual `status` required|in:Present,Absent,Late,Half Day,Short Leave,Leave | 422 on invalid case/value | Controller |
| BC-VAL-03 | scan/manual `date` required|date | 422 | Controller |
| BC-VAL-04 | scan/manual `period` required|integer|min:1|max:8 | 422 out of range | Controller |
| BC-VAL-05 | scan/manual `marked_by` required|integer | 422 | Controller |
| BC-VAL-06 | manual `student_id` required|integer | 422 | Controller@manualAttendance |
| BC-VAL-07 | manual `remarks` nullable|string|max:255 | 422 at 256 chars | Controller@manualAttendance |
| BC-VAL-08 | bulk `attendance_date` required|date | 422 | Controller@storeBulkAttendance |
| BC-VAL-09 | bulk `class_section_id` required|exists:sch_class_section_jnt,id | 422 | Controller@storeBulkAttendance |
| BC-VAL-10 | bulk `academic_session_id` required|exists:sch_org_academic_sessions_jnt,id | 422 | Controller@storeBulkAttendance |
| BC-VAL-11 | bulk `attendance` required|array | 422 | Controller@storeBulkAttendance |
| BC-VAL-12 | **bulk per-student `status` is NOT enum-validated** (accepts arbitrary string) | defect BUG-STD-ATT-01 | Controller@storeBulkAttendance |

### BC-AUTH (permissions · Source: Gate::authorize + AttendancePolicy)
| ID | Gate | Method | Source |
|----|------|--------|--------|
| BC-AUTH-01 | `tenant.attendance.create` | create, scanAttendance, manualAttendance, storeBulkAttendance | Controller |
| BC-AUTH-02 | `tenant.attendance.viewAny` | bulkAttendanceIndex, getAttendanceReport | Controller |
| BC-AUTH-03 | Policy exposes viewAny/view/create/update/delete/restore/forceDelete (`tenant.attendance.*`) | AttendancePolicy | Policy |

### BC-BIZ (behaviour · Source: Controller/Model)
| ID | Rule | Source |
|----|------|--------|
| BC-BIZ-01 | scan/manual/bulk use `updateOrCreate` keyed on (student_id, date[, period]) → idempotent upsert | Controller |
| BC-BIZ-02 | Model `boot()` saving hook sets `marked_at = now()` on every save | Model |
| BC-BIZ-03 | bulk store: empty/`null` status → record DELETED (clear-all branch) | Controller@storeBulkAttendance |
| BC-BIZ-04 | bulk store wraps in DB transaction; success flash `Attendance saved successfully.` | Controller |
| BC-BIZ-05 | scan unknown QR → JSON `{status:false, message:'Student not found with this QR code'}` | Controller@scanAttendance |
| BC-BIZ-06 | manual/scan student without current session → JSON `{status:false, message:'... not enrolled in any current academic session'}` | Controller |
| BC-BIZ-07 | manual `findOrFail` unknown student → 404 | Controller@manualAttendance |
| BC-BIZ-08 | bulk index without current academic session → redirect back with error `No active academic session found.` | Controller@bulkAttendanceIndex |
| BC-BIZ-09 | **No activity-log writes** in AttendanceController (do not assert activity_logs) | Controller |

### BC-SM (workflow — schema only)
| ID | Transition | Status |
|----|-----------|--------|
| BC-SM-01 | Correction Pending → Approved/Rejected (ENUM declares it) | **Schema-only; controller-unimplemented (GAP-STD-ATT-03)** |

### BC-REF / BC-INT (FK · Source: DDL)
| ID | FK | Referenced | onDelete | Source |
|----|-----|-----------|----------|--------|
| BC-REF-01 | std_student_attendance.student_id | std_students | CASCADE | DDL |
| BC-REF-02 | std_student_attendance.class_section_id | sch_class_section_jnt | CASCADE | DDL |
| BC-REF-03 | std_student_attendance.marked_by | sys_users | SET NULL | DDL |
| BC-REF-04 | std_attendance_corrections.attendance_id | std_student_attendance | CASCADE | DDL |
| BC-REF-05 | std_attendance_corrections.requested_by / action_by | sys_users | CASCADE / SET NULL | DDL |

### BC-EDG / BC-CFG
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | bulk store omits attendance_period → defaults to 0 | DDL DEFAULT + Controller |
| BC-EDG-02 | All six statuses persist via bulk store | View + DDL |
| BC-CFG-01 | `sys_setting` key `Period_wise_Student_Attendance` toggles period-wise marking | DDL comment (not exercised in controller) |

### Known / Discovered Source Defects
| ID | Description | Location | Proving test |
|----|-------------|----------|--------------|
| BUG-STD-P3-01 | Audit-reported stray `// dd($request->all());s` — **verified ABSENT (remediated)** | StudentController.php | test_94 |
| GAP-STD-22 | Attendance < 75% automated notification NOT implemented | Missing | test_95 |
| BUG-STD-ATT-01 | `storeBulkAttendance` has NO status `in:` enum validation | AttendanceController@storeBulkAttendance | test_97 |
| BUG-STD-ATT-02 | `getAttendanceReport()` controller method has NO registered route (dead) | AttendanceController | test_96 |
| GAP-STD-ATT-03 | `std_attendance_corrections` schema + model exist, correction workflow unimplemented (no controller/route) | Module | test_98 |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method |
|-------|----|--------|-------------|----------|--------|
| TC-P01 | BC-DB-* | DDL | Schema/model/request config truth | tables/cols/unique/enum/fillable correct | test_01 |
| TC-P02 | BC-BIZ | Screen | Create screen loads (scan+manual) | 200, sections render | test_10 |
| TC-P03 | BC-BIZ | Screen | Bulk index loads | form/select present | test_11 |
| TC-P04 | BC-BIZ | Screen-BR-1 | Bulk apply marks all Present | rows checked Present | test_12 |
| TC-P05 | BC-BIZ | Screen-BR-2 | Individual override after bulk | one Absent, rest Present | test_13 |
| TC-P06 | BC-BIZ-01 | Screen-BR-3 | Save persists to DB (Title Case) | records status=Present | test_14 |
| TC-P07 | BC-BIZ-01 | Screen-BR-4 | Mixed bulk+individual saved | DB reflects mix | test_15 |
| TC-P08 | BC-BIZ-03 | Screen-BR-5 | Clear-all deletes on save | record removed | test_16 |
| TC-P09 | BC-BIZ | Screen | Reload shows persisted selection | record intact | test_17 |
| TC-P10 | BC-BIZ-02 | Model | marked_at auto-set | not null | test_18 |
| TC-P11 | BC-BIZ-01/BC-DB-04 | DDL | Upsert no duplicate on resave | 1 row, status overwritten | test_19 |
| TC-P12 | BC-SM-01 | DDL | Correction status ENUM Pending/Approved/Rejected | present | test_20 |
| TC-P13 | BC-EDG-02 | View | All six statuses persist via bulk | statuses match | test_70 |
| TC-P14 | BC-EDG-01 | DDL | Period defaults to 0 on bulk store | period=0 | test_71 |
| TC-P15 | BC-BIZ | View | Bulk actions list all six statuses | 6 present | test_61 |
| TC-P16 | BC-BIZ | View | Manual status buttons render | ≥1 present | test_62 |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method |
|-------|----|--------|-------------|----------|--------|
| TC-N01 | BC-VAL-01 | Controller | scan missing qr_code | 422 qr_code | test_30 |
| TC-N02 | BC-VAL-02 | Controller | scan invalid status (`half_day`) | 422 status | test_31 |
| TC-N03 | BC-VAL-04 | Controller | scan period out of range (9) | 422 period | test_32 |
| TC-N04 | BC-VAL-06 | Controller | manual missing student_id | 422 student_id | test_33 |
| TC-N05 | BC-VAL-02 | Controller | manual invalid status (`Excused`) | 422 status | test_34 |
| TC-N06 | BC-VAL-07 | Controller | manual remarks 256 chars | 422 remarks | test_35 |
| TC-N07 | BC-VAL-08/09 | Controller | bulk missing date + class_section | 422 class_section_id | test_36 |
| TC-N08 | BC-VAL-09 | Controller | bulk nonexistent class_section | 422 (exists) | test_37 |
| TC-N09 | BC-VAL-11 | Controller | bulk missing attendance array | 422 attendance | test_38 |
| TC-N10 | BC-BIZ-05 | Controller | scan unknown QR | status:false, "not found" | test_39 |
| TC-N11 | BC-BIZ-07 | Controller | manual unknown student | 404/422/500 | test_44 |
| TC-N12 | BC-BIZ-06 | Controller | manual student w/o current session | status:false | test_45 |
| TC-N13 | BC-AUTH | Policy | Guest redirected to /login | /login | test_52 |
| TC-N14 | BC-AUTH-01 | Policy | Limited user forbidden on bulk store | 403/419 | test_53 |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | Method |
|-------|-----|----|--------|-------------|----------|--------|
| TC-D01 | C | BC-REF-01 | DDL | FK student ON DELETE CASCADE | rule=CASCADE | test_40 |
| TC-D02 | C | BC-REF-02 | DDL | FK class_section ON DELETE CASCADE | rule=CASCADE | test_41 |
| TC-D03 | D | BC-REF-03 | DDL | FK marked_by ON DELETE SET NULL | rule=SET NULL | test_42 |
| TC-D04 | C | BC-REF-04 | DDL | FK correction.attendance_id CASCADE | rule=CASCADE | test_43 |
| TC-D05 | E | BC-BIZ-06 | Controller | Cross-dep: no current session branch | status:false | test_45 |
| TC-D06 | F | BC-BIZ-01/03 | Controller | Lifecycle: create→override→save→clear | DB consistent | test_14/15/16 |
| TC-D07 | G | BC-DB-04 | DDL | Concurrency/upsert uniqueness | 1 row | test_19 |

### Auth / UI / Config
| TC ID | BC | Source | Description | Method |
|-------|----|--------|-------------|--------|
| TC-A01 | BC-AUTH-01/02 | Controller | Gates wired (source) | test_50 |
| TC-A02 | BC-AUTH-03 | Policy | Policy exposes all abilities | test_51 |
| TC-U01 | BC-BIZ-08 | Controller | No-class-section info/empty state | test_60 |

### Tenancy / Security (TC-T / TC-S)
| TC ID | BC | Source | Description | Expected | Method |
|-------|----|--------|-------------|----------|--------|
| TC-T01 | — | Tenant | Records scoped to initialized tenant | tenancy initialized | test_90 |
| TC-S01 | BC-DB | Security | Remarks XSS stored verbatim (escaped at render) | value intact | test_91 |

### Defect / Gap Proofs
| TC ID | Defect | Description | Method |
|-------|--------|-------------|--------|
| TC-DEF01 | BUG-STD-P3-01 | Stray debug comment absent (remediated) | test_94 |
| TC-DEF02 | GAP-STD-22 | 75% notification absent | test_95 |
| TC-DEF03 | BUG-STD-ATT-02 | getAttendanceReport dead route | test_96 |
| TC-DEF04 | BUG-STD-ATT-01 | bulk store no status enum validation | test_97 |
| TC-DEF05 | GAP-STD-ATT-03 | Correction workflow unimplemented | test_98 |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_attendance_01_migration_model_and_request_configuration_are_correct | TC-P01 | Schema | 01–09 |
| 2 | test_attendance_10_create_screen_loads_with_scan_and_manual_sections | TC-P02 | BIZ | 10–19 |
| 3 | test_attendance_11_bulk_index_loads | TC-P03 | BIZ | 10–19 |
| 4 | test_attendance_12_bulk_apply_marks_all_rows_present | TC-P04 | BIZ | 10–19 |
| 5 | test_attendance_13_individual_override_after_bulk | TC-P05 | BIZ | 10–19 |
| 6 | test_attendance_14_save_persists_to_database | TC-P06 | BIZ | 10–19 |
| 7 | test_attendance_15_mixed_bulk_and_individual_saved_correctly | TC-P07 | BIZ | 10–19 |
| 8 | test_attendance_16_clear_all_removes_records_on_save | TC-P08 | BIZ | 10–19 |
| 9 | test_attendance_17_reload_shows_persisted_selection | TC-P09 | BIZ | 10–19 |
| 10 | test_attendance_18_marked_by_and_marked_at_recorded | TC-P10 | BIZ | 10–19 |
| 11 | test_attendance_19_upsert_does_not_create_duplicate_on_resave | TC-P11 | BIZ/EDG | 10–19 |
| 12 | test_attendance_20_correction_status_enum_matches_ddl | TC-P12 | SM | 20–29 |
| 13 | test_attendance_30_scan_requires_qr_code | TC-N01 | VAL | 30–39 |
| 14 | test_attendance_31_scan_rejects_invalid_status | TC-N02 | VAL | 30–39 |
| 15 | test_attendance_32_scan_rejects_out_of_range_period | TC-N03 | VAL | 30–39 |
| 16 | test_attendance_33_manual_requires_student_id | TC-N04 | VAL | 30–39 |
| 17 | test_attendance_34_manual_rejects_invalid_status | TC-N05 | VAL | 30–39 |
| 18 | test_attendance_35_manual_remarks_max_length_enforced | TC-N06 | VAL | 30–39 |
| 19 | test_attendance_36_bulk_store_requires_date_and_class_section | TC-N07 | VAL | 30–39 |
| 20 | test_attendance_37_bulk_store_requires_existing_class_section | TC-N08 | VAL | 30–39 |
| 21 | test_attendance_38_bulk_store_requires_attendance_array | TC-N09 | VAL | 30–39 |
| 22 | test_attendance_39_scan_unknown_qr_returns_student_not_found | TC-N10 | VAL/BIZ | 30–39 |
| 23 | test_attendance_40_fk_student_on_delete_cascade | TC-D01 | REF | 40–49 |
| 24 | test_attendance_41_fk_class_section_on_delete_cascade | TC-D02 | REF | 40–49 |
| 25 | test_attendance_42_fk_marked_by_on_delete_set_null | TC-D03 | REF | 40–49 |
| 26 | test_attendance_43_correction_fk_attendance_on_delete_cascade | TC-D04 | REF | 40–49 |
| 27 | test_attendance_44_manual_unknown_student_returns_error | TC-N11 | INT | 40–49 |
| 28 | test_attendance_45_no_current_session_returns_business_error | TC-N12/TC-D05 | INT | 40–49 |
| 29 | test_attendance_50_controller_gates_are_wired | TC-A01 | AUTH | 50–59 |
| 30 | test_attendance_51_policy_exposes_all_ability_methods | TC-A02 | AUTH | 50–59 |
| 31 | test_attendance_52_guest_is_redirected_to_login | TC-N13 | AUTH | 50–59 |
| 32 | test_attendance_53_limited_user_forbidden_on_bulk_store | TC-N14 | AUTH | 50–59 |
| 33 | test_attendance_60_no_class_section_shows_info_state | TC-U01 | UI | 60–69 |
| 34 | test_attendance_61_bulk_actions_list_all_six_statuses | TC-P15 | UI | 60–69 |
| 35 | test_attendance_62_manual_status_buttons_present | TC-P16 | UI | 60–69 |
| 36 | test_attendance_70_all_six_statuses_persist_via_bulk_store | TC-P13 | EDG | 70–79 |
| 37 | test_attendance_71_period_zero_default_when_bulk_stored | TC-P14 | EDG | 70–79 |
| 38 | test_attendance_90_tenant_isolation_records_scoped | TC-T01 | Tenancy | 90–99 |
| 39 | test_attendance_91_remarks_free_text_stored_without_html_execution | TC-S01 | Security | 90–99 |
| 40 | test_attendance_94_bug_std_p3_01_debug_comment_absent | TC-DEF01 | Defect | 90–99 |
| 41 | test_attendance_95_gap_std_22_threshold_notification_absent | TC-DEF02 | Gap | 90–99 |
| 42 | test_attendance_96_get_attendance_report_has_no_registered_route | TC-DEF03 | Defect | 90–99 |
| 43 | test_attendance_97_bulk_store_lacks_status_enum_validation | TC-DEF04 | Defect | 90–99 |
| 44 | test_attendance_98_correction_workflow_unimplemented | TC-DEF05 | Gap | 90–99 |
