# std_StudentReports — Test Case List & Business Conditions

**Module:** StudentProfile · **Feature/Screen:** StudentReports (composite, read-only) · **Prefix:** `std_`
**Controller:** `Modules/StudentProfile/app/Http/Controllers/StudentReportController.php` → `combinedStudentReport()`
**Routes:** `student-profile.reports.index` (`GET /student-profile/reports-mgt`), `student-profile.reports.class-strength` (`GET /student-profile/reports/class-wise-student-strength`) — **both** hit `combinedStudentReport`.
**View:** `studentprofile::reports.index` (tabs: student-strength · admission-register · medical-profile)
**Permission gate:** `tenant.student.viewAny` (report) · `tenant.student.export` (export)
**DB scope:** TENANT · **Composite read tables:** `std_students`, `std_student_academic_sessions`, `std_health_profiles`, `std_medical_incidents`, `std_student_attendance`
**Test style:** Browser Dusk (`extends DuskTestCase`), mirrors committed sibling `spr_StudentCompleteProfile_TestCas`.

> Read-focused matrix (no create/edit/delete). Coverage: render each report, filters, export path, permissions, empty state, tenancy isolation.

---

## 1. Business Conditions

### BC-DB (schema — composite read tables)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `std_students` exists with `admission_no, first_name, gender, dob, is_active` | DDL-std_students |
| BC-DB-02 | `std_student_academic_sessions` exists with `student_id, academic_session_id, class_section_id, is_current, admission_date` | DDL-std_student_academic_sessions |
| BC-DB-03 | `std_health_profiles` exists with `student_id, blood_group, allergies, chronic_conditions` | DDL-std_health_profiles |
| BC-DB-04 | `std_medical_incidents` exists (`student_id`, incident fields) | DDL-std_medical_incidents |
| BC-DB-05 | `std_student_attendance` exists (`student_id`, `status`) | DDL-std_student_attendance |

### BC-AUTH (authorization)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `combinedStudentReport` calls `Gate::authorize('tenant.student.viewAny')` | Controller L72 |
| BC-AUTH-02 | Report routes sit behind `auth`+`verified`+tenancy middleware → guest redirected to `/login` | RouteServiceProvider |
| BC-AUTH-03 | User lacking `tenant.student.viewAny` is denied (403) | Gate |
| BC-AUTH-04 | Export requires `tenant.student.export` | StudentController@export L4061 |

### BC-BIZ (report business rules)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Report scopes to current-session enrollments (`is_current=1` AND `academic_session_id=currentSessionId`) | Controller L94-95 · Screen-BR BR-04 |
| BC-BIZ-02 | Strength report: totals per class-section, gender split, caste category (General / OBC-SC-ST), RTE/EWS, class teacher | Controller L114-149 · FR-18..22 |
| BC-BIZ-03 | Admission register: admission no/date, name, DOB, gender, father/mother, prev school, TC no | Controller L154-182 · FR-25..28 |
| BC-BIZ-04 | Medical report: students with allergies or chronic conditions; blood group, emergency contact | Controller L187-216 · FR-30..32 |
| BC-BIZ-05 | Report is read-only — no activity-log rows written on render | Controller (no write) |

### BC-VAL (filters)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `class_id` filter applied via `whereHas('classSection', class_id)` | Controller L105-107 · FR-23 |
| BC-VAL-02 | `academic_session_id` filter selects the session | Controller L77 · FR-23 |
| BC-VAL-03 | `from_date`/`to_date` filter `admission_date` range | Controller L97-103 · FR-29 |
| BC-VAL-04 | Malformed filter values must not 500 | Robustness |

### BC-INT / BC-REF (integration & export)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | `StudentsExport implements ShouldQueue` | Exports/StudentsExport L14 |
| BC-INT-02 | Excel & CSV export dispatched via `Excel::queue(...)` (async) | StudentController L4153,4158 |
| BC-REF-01 | Composite eager-loads `student.profile/guardians/healthProfile`, `classSection.class/section/classTeacher` | Controller L84-93 |

### BC-EDG (edge)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No current session + no `academic_session_id` → null deref on `$currentSession->id` (**DEV-STD-R2**) | Controller L77 |
| BC-EDG-02 | Out-of-range `class_id` yields empty report, not 500 | Robustness |

### BC-CFG / cross-module
| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | Index breadcrumb links `route('complaint.reports.summary')` — unregistered cross-module route (**DEV-STD-R1**) | index.blade L2 |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-P01 | Schema | BC-DB-01..05 | DDL | Composite tables + controller wiring correct | Tables/columns present; gate+view wired | `test_..._01` | ✅ |
| TC-P02 | Route | BC-AUTH-01 | routes | Both routes registered → combinedStudentReport | Route::has true; action bound | `test_..._02` | ✅ |
| TC-P03 | Config | — | Controller | Controller methods exist | 3 methods present | `test_..._03` | ✅ |
| TC-P10 | Render | BC-BIZ | view | Index renders 3 report tabs | 3 panes present | `test_..._10` | ✅ |
| TC-P11 | Render | BC-BIZ-02 | FR-18..22 | Strength columns render | 9 columns present | `test_..._11` | ✅ |
| TC-P12 | Render | BC-BIZ-03 | FR-25..28 | Admission columns render | 7 columns present | `test_..._12` | ✅ |
| TC-P13 | Render | BC-BIZ-04 | FR-30..32 | Medical columns render | 4 columns present | `test_..._13` | ✅ |
| TC-P14 | Biz | BC-BIZ-01 | Controller | Current-session scoping | `is_current=1` + session filter | `test_..._14` | ✅ |
| TC-P15 | Stability | — | — | Index renders w/o server error | No Whoops/500 | `test_..._15` | ✅ |
| TC-P16 | Route | BC-AUTH-01 | routes | Class-strength alias renders report | Same composite view | `test_..._16` | ✅ |
| TC-P30 | Filter | BC-VAL-01 | FR-23 | class_id accepted+applied | No 500; where applied | `test_..._30` | ✅ |
| TC-P31 | Filter | BC-VAL-02 | FR-23 | academic_session_id accepted | No 500 | `test_..._31` | ✅ |
| TC-P32 | Filter | BC-VAL-03 | FR-29 | date range accepted+applied | No 500; whereDate applied | `test_..._32` | ✅ |
| TC-P51 | Auth | BC-AUTH-01 | Controller | Report guarded by viewAny | Gate present | `test_..._51` | ✅ |
| TC-P53 | Auth | BC-AUTH-01 | Controller | Alias gated | Gate present | `test_..._53` | ✅ |
| TC-P54 | Auth | BC-AUTH-01 | gate | Authorized admin OK | 200/302 | `test_..._54` | ✅ |
| TC-P55 | Render | BC-BIZ | view | Admin can view report | Content renders | `test_..._55` | ✅ |
| TC-P60 | UI | BC-BIZ | views | Empty-state messages present | 3 strings present | `test_..._60` | ✅ |
| TC-P61 | UI | BC-BIZ-02 | view | Strength iterates rows + @empty | forelse/empty present | `test_..._61` | ✅ |
| TC-P62 | UI | FR-24 | views | Chart containers present | 3 chart ids | `test_..._62` | ✅ |
| TC-P64 | UI | — | view | 3 named tabs declared | Tab ids present | `test_..._64` | ✅ |

### Negative (TC-N)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-N33 | Filter | BC-VAL-04 | robustness | Malformed filters no 500 | Graceful render | `test_..._33` | ✅ |
| TC-N50 | Auth | BC-AUTH-02 | middleware | Guest redirected to login | `/login` in path | `test_..._50` | ✅ |
| TC-N52 | Auth | BC-AUTH-03 | gate | No-permission user forbidden | 403/302/401 | `test_..._52` | ✅ |
| TC-N70 | Edge | BC-EDG-01 | Controller | Null-unsafe currentSession (**DEV-STD-R2**) | Null-deref path proven | `test_..._70` | ✅ |
| TC-N71 | Edge | BC-EDG-02 | robustness | OOB class_id no 500 | Graceful render | `test_..._71` | ✅ |

### Dependency / Integration (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D40 | E | BC-INT-01 | Export | StudentsExport implements ShouldQueue | interface present | `test_..._40` | ✅ |
| TC-D41 | E | BC-INT-02 | StudentController | Excel export queued | `Excel::queue` xlsx | `test_..._41` | ✅ |
| TC-D42 | E | BC-INT-02 | StudentController | CSV export queued | `Excel::queue` csv | `test_..._42` | ✅ |
| TC-D43 | E | **PERF-STD-10** | StudentController | PDF export synchronous inline (perf gap) | `Pdf::...->download()`, no queue | `test_..._43` | ✅ |
| TC-D44 | E | BC-AUTH-04 | StudentController | Export permission gate | `tenant.student.export` | `test_..._44` | ✅ |
| TC-D45 | E | BC-REF-01 | Controller | Composite relationships eager-loaded | 5 relations present | `test_..._45` | ✅ |
| TC-D63 | E | BC-CFG-01 | index.blade | Breadcrumb dead route (**DEV-STD-R1**) | `Route::has(...)` false | `test_..._63` | ✅ |

### Tenancy / Security (TC-T / TC-S)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-T90 | Tenancy | — | tenancy | Report runs within tenant context | tenancy initialized | `test_..._90` | ✅ |
| TC-T91 | Tenancy | — | tenancy | Report bound to tenant host | host in URL | `test_..._91` | ✅ |
| TC-S92 | Security | BC-BIZ-05 | ActivityLog | Read writes no activity-log rows | count unchanged | `test_..._92` | ✅ |
| TC-S93 | Security | — | filters | Reflected filter input not executed | no XSS flag | `test_..._93` | ✅ |
| TC-T94 | Tenancy | BC-AUTH-02 | middleware | No report data w/o auth | no pane leaked | `test_..._94` | ✅ |

### Known Source Defects
| ID | Severity | Description | Proving test |
|----|----------|-------------|--------------|
| PERF-STD-10 | P2 | Export path for large student datasets: Excel/CSV now queued, but **PDF export builds the full collection in-request and streams synchronously via `Pdf::...->download()`** — memory/timeout risk for 1000+ students | `test_..._43` |
| DEV-STD-R1 | P2 | Report index breadcrumb links `route('complaint.reports.summary')`, an **unregistered cross-module route** → `RouteNotFoundException`/500 on render | `test_..._63` |
| DEV-STD-R2 | P2 | `$currentSessionId = $request->academic_session_id ?? $currentSession->id;` — **null deref** when no current session and no session param | `test_..._70` |

---

## 3. Test Method Index
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_..._01_underlying_read_tables_and_report_wiring_are_correct | TC-P01 | Schema | 01-09 |
| 2 | test_..._02_both_report_routes_are_registered_to_combined_report | TC-P02 | Route | 01-09 |
| 3 | test_..._03_report_controller_methods_exist | TC-P03 | Config | 01-09 |
| 4 | test_..._10_report_index_renders_with_three_report_tabs | TC-P10 | Render | 10-19 |
| 5 | test_..._11_student_strength_tab_renders_expected_columns | TC-P11 | Render | 10-19 |
| 6 | test_..._12_admission_register_tab_renders_expected_columns | TC-P12 | Render | 10-19 |
| 7 | test_..._13_medical_profile_tab_renders_expected_columns | TC-P13 | Render | 10-19 |
| 8 | test_..._14_report_scopes_to_current_session_records | TC-P14 | Biz | 10-19 |
| 9 | test_..._15_report_index_renders_without_server_error | TC-P15 | Stability | 10-19 |
| 10 | test_..._16_class_strength_route_renders_same_report | TC-P16 | Route | 10-19 |
| 11 | test_..._30_class_filter_param_is_accepted | TC-P30 | Filter | 30-39 |
| 12 | test_..._31_academic_session_filter_param_is_accepted | TC-P31 | Filter | 30-39 |
| 13 | test_..._32_admission_date_range_filter_param_is_accepted | TC-P32 | Filter | 30-39 |
| 14 | test_..._33_malformed_filter_values_do_not_500 | TC-N33 | Filter | 30-39 |
| 15 | test_..._40_students_export_declares_shouldqueue | TC-D40 | Export | 40-49 |
| 16 | test_..._41_excel_export_path_is_queued | TC-D41 | Export | 40-49 |
| 17 | test_..._42_csv_export_path_is_queued | TC-D42 | Export | 40-49 |
| 18 | test_..._43_pdf_export_path_is_synchronous_inline_perf_gap | TC-D43 (PERF-STD-10) | Export | 40-49 |
| 19 | test_..._44_export_requires_export_permission | TC-D44 | Export | 40-49 |
| 20 | test_..._45_report_eager_loads_composite_relationships | TC-D45 | Integration | 40-49 |
| 21 | test_..._50_guest_is_redirected_to_login | TC-N50 | Auth | 50-59 |
| 22 | test_..._51_report_is_guarded_by_student_viewany | TC-P51 | Auth | 50-59 |
| 23 | test_..._52_user_without_permission_is_forbidden | TC-N52 | Auth | 50-59 |
| 24 | test_..._53_class_strength_alias_uses_same_gate | TC-P53 | Auth | 50-59 |
| 25 | test_..._54_authorized_admin_receives_ok | TC-P54 | Auth | 50-59 |
| 26 | test_..._55_authenticated_admin_can_view_report | TC-P55 | Render | 50-59 |
| 27 | test_..._60_empty_state_messages_present_in_views | TC-P60 | UI | 60-69 |
| 28 | test_..._61_strength_view_iterates_report_rows | TC-P61 | UI | 60-69 |
| 29 | test_..._62_chart_containers_present | TC-P62 | UI | 60-69 |
| 30 | test_..._63_breadcrumb_references_unregistered_route_dev_std_r1 | TC-D63 (DEV-STD-R1) | UI | 60-69 |
| 31 | test_..._64_index_defines_three_named_tabs | TC-P64 | UI | 60-69 |
| 32 | test_..._70_no_current_session_null_deref_dev_std_r2 | TC-N70 (DEV-STD-R2) | Edge | 70-79 |
| 33 | test_..._71_out_of_range_class_id_does_not_500 | TC-N71 | Edge | 70-79 |
| 34 | test_..._90_report_runs_within_tenant_context | TC-T90 | Tenancy | 90-99 |
| 35 | test_..._91_report_url_is_bound_to_tenant_host | TC-T91 | Tenancy | 90-99 |
| 36 | test_..._92_rendering_report_writes_no_activity_log | TC-S92 | Security | 90-99 |
| 37 | test_..._93_reflected_filter_input_is_not_executed | TC-S93 | Security | 90-99 |
| 38 | test_..._94_no_report_data_without_authentication | TC-T94 | Tenancy | 90-99 |

**Total: 38 methods.**
