# Test Case List — MarksheetGeneration · Student Results & Print

- **Module:** MarksheetGeneration (`MSH`) · **Prefix:** `msh_` (verified vs DDL `CREATE TABLE msh_student_results`)
- **Feature / Screen:** StudentResultsAndPrint — `MarksheetGeneration_V2/05-Student-Results-and-Print.md`
- **Primary table:** `msh_student_results` (UNIQUE `uq_msh_sr_schedule_student`; `result_status` DECLARED/WITHHELD; `promotion_status`; `withheld_reason`; `rank_in_section`/`rank_in_class`)
- **Combined screen route:** `marksheet-generation.results.combined` → `/marksheet-generation/results`
- **Controller:** `StudentResultController` (+ `MarksheetGenerationController::results()`) · **Service:** `StudentResultReviewService` · **Export:** `StudentResultExport`
- **DB scope:** TENANT-side (DDL header `Database: tenant_db`) → tenancy scaffolding required
- **Test style:** browser Dusk (`extends DuskTestCase`, `namespace Tests\Browser`) — mirrors the golden Class reference
- **Single test file:** `msh_StudentResultsAndPrint_TestCas.php` (57 methods) — one comprehensive suite, no V1/V2 split

---

## 1. Business Conditions

### BC-DB — Schema / columns / constraints (Source: DDL-msh_*)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `msh_student_results` has all aggregate/rank/promotion/result-status columns + soft-delete | DDL-msh_student_results |
| BC-DB-02 | `StudentResult` model: table `msh_student_results`, `SoftDeletes`, `$fillable`, `decimal:2` casts, relations | Model-StudentResult |
| BC-DB-03 | Relations: `marksheetSchedule`/`student`/`classSection` (BelongsTo), `subjectResults`/`coscholasticResults` (HasMany) | Model-StudentResult |
| BC-DB-04 | UNIQUE `uq_msh_sr_schedule_student` on (`schedule_id`,`student_id`) | DDL-msh_student_results |
| BC-DB-05 | `msh_student_subject_results` per-subject matrix columns (`uq_msh_ssr_schedule_student_subject`) | DDL-msh_student_subject_results |
| BC-DB-06 | `msh_student_ia_marks` teacher-entry columns (`uq_msh_siam_...`) | DDL-msh_student_ia_marks |
| BC-DB-07 | `msh_student_coscholastic_results` (`grade`,`is_auto_from_ba`) + `msh_student_attendance` (`total_working_days`,`days_present`) | DDL |
| BC-DB-08 | `msh_student_subject_exam_marks` raw matrix (`uq_msh_ssem_...`) | DDL |
| BC-DB-09 | `msh_computation_logs` is immutable: NO `deleted_at`, `ComputationLog` has no `SoftDeletes` | DDL / Model |

### BC-VAL — Validation + error (Source: StudentResultRequest / WithholdStudentResultRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `schedule_id` required|integer|`exists:msh_marksheet_schedules,id`; unique per (schedule_id,student_id) | Screen-VR-1 |
| BC-VAL-02 | `student_id` required|integer|`exists:std_students,id` | Screen-VR-2 |
| BC-VAL-03 | `class_section_id` required|integer|`exists:sch_class_section_jnt,id` | Screen-VR-3 |
| BC-VAL-04 | `overall_percentage` nullable|numeric|min:0|max:100 | Screen-VR-4 |
| BC-VAL-05 | `promotion_status` in `PROMOTED,DETAINED,COMPARTMENT,PLACED` | Screen-VR-5 |
| BC-VAL-06 | `result_status` in `DECLARED,WITHHELD` | Screen-VR-6 |
| BC-VAL-07 | `rank_in_section`/`rank_in_class` nullable|integer|min:1 | Screen-VR-7 |
| BC-VAL-08 | `withheld_reason` (withhold request) required|string|min:5|max:255 | Screen-VR-8 |

### BC-AUTH — Permission gates (Source: Controller `Gate::authorize`, results.blade `@can`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `results()` authorizes `tenant.msh-results.view` | MarksheetGenerationController |
| BC-AUTH-02 | show/index gate `tenant.msh-student-result.view`; edit/update `.update`; destroy `.delete`; export `.export`; print/pdf `.print`; withhold `.withhold`; declare `.declare` | StudentResultController |
| BC-AUTH-03 | Result tabs gated in view: `@can('tenant.msh-student-result.view')`, `...ia-mark.view`, `...coscholastic-result.view`, `...subject-result.view` | results.blade |
| BC-AUTH-04 | Guest is redirected to `/login` (auth+verified middleware) | routes/web.php |

### BC-BIZ — Business logic / activity-log events (Source: Controller / Service)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Combined screen renders 4 tabs: Student Results / Subject Results / IA Marks / Coscholastic Results | results.blade |
| BC-BIZ-02 | `store()` persists + `activityLog(..,'Stored',..)` → redirect to `student-result.show` | StudentResultController::store |
| BC-BIZ-03 | `update()` persists + `activityLog(..,'Updated',..)` | StudentResultController::update |
| BC-BIZ-04 | `destroy()` soft-deletes + `activityLog(..,'Deleted',..)` | StudentResultController::destroy |
| BC-BIZ-05 | `show()` loads schedule/student/class-section/subjectResults/coscholasticResults + exam/IA/attendance | StudentResultController::show |
| BC-BIZ-06 | `export()` → `Excel::download(new StudentResultExport(id),'student_result_{id}.xlsx')` | StudentResultController::export |
| BC-BIZ-07 | `print()` → `Template::render('MARKSHEET_PRINT', subjectId/classId/sessionId/studentId)`; `DomainException` → redirect show with error `'Cannot print: …'` | StudentResultController::print |
| BC-BIZ-08 | `downloadPdf()` → redirect to `student-result.print` with `download=1&auto=1` (html2pdf.js) | StudentResultController::downloadPdf |
| BC-BIZ-09 | `index()` redirects to `results.combined` (`tab=student-results`) | StudentResultController::index |

### BC-SM — State machine: result_status (Source: StudentResultReviewService)
| ID | State → Trigger → Next | Rule | Source |
|----|-----------------------|------|--------|
| BC-SM-01 | DECLARED → withhold(reason) → WITHHELD | writes reason + inserts `msh_computation_logs` (`WITHHOLD`); event `'Withheld'` | Service::withhold |
| BC-SM-02 | WITHHELD → declare → DECLARED | nulls `withheld_reason` + inserts log (`DECLARE`); event `'Declared'` | Service::declare |
| BC-SM-03 | *any* → withhold while `schedule.is_locked=1` → **rejected** (`DomainException 'Cannot withhold — schedule is locked.'`) | Service::withhold |
| BC-SM-04 | *any* → declare while `schedule.is_locked=1` → **rejected** (`DomainException 'Cannot declare — schedule is locked.'`) | Service::declare |

### BC-INT / BC-REF — Integration & FK behaviour (Source: DDL FKs)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `schedule_id` FK → `msh_marksheet_schedules` ON DELETE CASCADE | DDL |
| BC-REF-02 | `student_id` FK → `std_students` ON DELETE RESTRICT | DDL |
| BC-REF-03 | `class_section_id` FK → `sch_class_section_jnt` ON DELETE RESTRICT | DDL |
| BC-INT-01 | Subject/IA/Coscholastic tabs consume child tables; computation-log is a read-only integration surface | Screen-IP |

### BC-EDG — Edge / boundary (Source: DDL limits / Model docblock)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `subjectResults()` joins on `student_id` only (cross-schedule); `subjectResultsForSchedule()` scopes by schedule | Model docblock |
| BC-EDG-02 | Whitespace-only withhold reason rejected (min:5 + service `trim()===''` guard) | Service + Request |
| BC-EDG-03 | `DECIMAL(8,2)` `grand_total` persists at boundary precision (999999.99); `decimal:2` cast | DDL / Model |

---

## 2. Known Source Defects (proving tests)
| ID | Sev | Description | Proving test |
|----|-----|-------------|--------------|
| SEC-MSH-001 | P1 | `StudentResultController::create()` authorizes `tenant.msh-student-result.view` instead of `.create` | test_51 |
| SEC-MSH-002 | P1 | `StudentResultController::store()` authorizes `tenant.msh-student-result.update` instead of `.create` | test_52 |
| SEC-MSH-003 | P1 | `StudentResultRequest` / `WithholdStudentResultRequest` `authorize()` return `true` (no per-request gate) | test_09, test_53 |
| PERF-MSH-003 | P2 | Unbounded `Student::get()`/`Subject::get()` in results view (no pagination) | Documented (Gap Analysis) |
| PERF-MSH-004 | P3 | `wipePreviousResults()` hard-deletes soft-deletable result rows on recompute (permanent loss; shared w/ SchedulingAndLifecycle) | Documented (Gap Analysis) |

---

## 3. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method |
|-------|----|--------|-------------|----------|--------|
| TC-P01 | BC-DB-01/02/03 | DDL/Model | Schema + model + fillable + relations + casts | All present | test_01 |
| TC-P02 | BC-DB-04 | DDL | UNIQUE (schedule_id,student_id) index exists | index found | test_02 |
| TC-P03 | BC-DB-05 | DDL | subject-results schema | columns present | test_03 |
| TC-P04 | BC-DB-06 | DDL | IA-marks schema | columns present | test_04 |
| TC-P05 | BC-DB-07 | DDL | coscholastic + attendance schema | columns present | test_05 |
| TC-P06 | BC-DB-08 | DDL | raw exam-marks matrix schema | columns present | test_06 |
| TC-P10 | BC-BIZ-01 | results.blade | Combined screen renders 4 tabs | all 4 shown | test_10 |
| TC-P11 | BC-BIZ-02 | Controller | Store persists + logs `Stored` + promotion_status | row + log | test_11 |
| TC-P12 | BC-BIZ-03 | Controller | Update persists + logs `Updated` | grade/promotion updated | test_12 |
| TC-P14 | BC-BIZ-05 | Controller | Show page renders aggregates | grade/% shown | test_14 |
| TC-P15 | BC-BIZ-06 | Controller/Export | Export returns XLSX download | HTTP 200 | test_15 |
| TC-P16 | BC-BIZ-07 | Controller | Print route resolves (render or redirect) | 200/302 | test_16 |
| TC-P17 | BC-BIZ-08 | Controller | PDF route resolves to print download | 200/302 | test_17 |
| TC-P18 | BC-BIZ-09 | Controller | index → combined results redirect | path = /results | test_18 |
| TC-P60 | BC-INT/UIX | partial | Student search filter applies | tab/empty state | test_60 |
| TC-P61 | BC-UIX | partial | Class-section filter control present | control found | test_61 |
| TC-P62 | BC-UIX | partial | Empty-state message on no-match | message shown | test_62 |
| TC-P63 | BC-UIX | view | Breadcrumb present | crumbs shown | test_63 |

### State-machine (TC-SM)
| TC ID | BC | Source | Description | Expected | Method |
|-------|----|--------|-------------|----------|--------|
| TC-SM20 | BC-SM-01 | Service | DECLARED → WITHHELD + log `Withheld` | status/reason set | test_20 |
| TC-SM21 | BC-SM-02 | Service | WITHHELD → DECLARED + log `Declared` + clear reason | reason null | test_21 |
| TC-SM22 | BC-SM-03 | Service | Withhold blocked while schedule locked | not WITHHELD | test_22 |
| TC-SM23 | BC-SM-04 | Service | Declare blocked while schedule locked | stays WITHHELD | test_23 |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method |
|-------|----|--------|-------------|----------|--------|
| TC-N19 | BC-REF | routes | Show invalid id | 404 | test_19 |
| TC-N24 | BC-VAL-08 | Request | Withhold reason < min:5 | 422 | test_24 |
| TC-N25 | BC-VAL-08 | Request | Withhold reason missing | 422 | test_25 |
| TC-N30 | BC-VAL-01/02 | Request | Required fields block store (+body) | 422 | test_30 |
| TC-N31 | BC-VAL-01/DB-04 | Request/DDL | Duplicate (schedule,student) | 422, 1 row | test_31 |
| TC-N32 | BC-VAL-04 | Request | overall_percentage > 100 | 422 | test_32 |
| TC-N33 | BC-VAL-05 | Request | promotion_status outside enum | 422 | test_33 |
| TC-N34 | BC-VAL-06 | Request | result_status outside enum | 422 | test_34 |
| TC-N35 | BC-VAL-01 | Request | non-existent schedule_id | 422 | test_35 |
| TC-N36 | BC-VAL-02 | Request | non-existent student_id | 422 | test_36 |
| TC-N37 | BC-VAL-07 | Request | rank_in_section < 1 | 422 | test_37 |
| TC-N38 | BC-REF | routes | Update invalid id | 404 | test_38 |
| TC-N39 | BC-VAL-08 | Request | withheld_reason > max:255 | 422 | test_39 |
| TC-N50 | BC-AUTH-04 | routes | Guest → /login | redirect | test_50 |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | Method |
|-------|-----|----|--------|-------------|----------|--------|
| TC-D07 | B | BC-DB-09 | DDL/Model | computation_logs immutable; withTrashed throws | throws | test_07 |
| TC-D13 | B | BC-BIZ-04 | Controller | Destroy soft-deletes + logs `Deleted` | deleted_at set | test_13 |
| TC-D40 | B | BC-REF | Model | Soft-deleted result hidden from default scope | hidden/withTrashed | test_40 |
| TC-D41 | — | BC-DB | Model | decimal:2 round-trip | 321.75 | test_41 |
| TC-D42 | E | BC-INT-01 | view | Subject-results tab renders | tab shown | test_42 |
| TC-D43 | E | BC-INT-01 | view | IA-marks tab renders | tab shown | test_43 |
| TC-D44 | E | BC-INT-01 | view | Coscholastic tab renders | tab shown | test_44 |
| TC-D45 | E | BC-INT-01 | Controller | Computation-log index resolves | 200/302 | test_45 |

### Configuration / Security-defect / Edge / Tenancy (TC-S / TC-EDG / TC-T)
| TC ID | BC / Defect | Source | Description | Expected | Method |
|-------|-------------|--------|-------------|----------|--------|
| TC-N08 | BC-VAL-* | Request | StudentResultRequest rule strings verbatim | strings present | test_08 |
| TC-N09 | SEC-MSH-003 | Request | Withhold rules + open `authorize()` | present/true | test_09 |
| TC-S51 | SEC-MSH-001 | Controller | create() uses `.view` gate (defect) | matches regex | test_51 |
| TC-S52 | SEC-MSH-002 | Controller | store() uses `.update` gate (defect) | matches regex | test_52 |
| TC-S53 | SEC-MSH-003 | Request | StudentResultRequest authorize()=true | matches regex | test_53 |
| TC-AUTH54 | BC-AUTH-03 | view | Result tabs `@can`-gated | 4 gates present | test_54 |
| TC-AUTH55 | BC-AUTH-01 | Controller | results() gate `tenant.msh-results.view` | present | test_55 |
| TC-EDG70 | BC-EDG-01 | Model | subjectResults cross-schedule + scoped helpers | helpers exist | test_70 |
| TC-EDG71 | BC-EDG-02 | Service | Whitespace-only reason rejected | 422 | test_71 |
| TC-EDG72 | BC-EDG-03 | DDL | grand_total boundary precision | 999999.99 | test_72 |
| TC-T90 | Tenancy | routes | Foreign/out-of-range id → 404 (IDOR) | 404 | test_90 |
| TC-S91 | Security | Service | XSS in withhold reason stored verbatim | raw round-trips | test_91 |
| TC-S92 | Security | Model | onlyTrashed on ComputationLog throws | throws | test_92 |

---

## 4. Test Method Index
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 01 | test_studentresult_01_student_results_schema_and_model_are_correct | TC-P01 | Schema | 01-09 |
| 02 | test_studentresult_02_unique_schedule_student_index_exists | TC-P02 | Schema | 01-09 |
| 03 | test_studentresult_03_subject_results_schema_is_correct | TC-P03 | Schema | 01-09 |
| 04 | test_studentresult_04_ia_marks_schema_is_correct | TC-P04 | Schema | 01-09 |
| 05 | test_studentresult_05_coscholastic_and_attendance_schema_are_correct | TC-P05 | Schema | 01-09 |
| 06 | test_studentresult_06_exam_marks_matrix_schema_is_correct | TC-P06 | Schema | 01-09 |
| 07 | test_studentresult_07_computation_log_immutable_no_soft_deletes | TC-D07 | Dependency | 01-09 |
| 08 | test_studentresult_08_student_result_request_rules_are_verbatim | TC-N08 | Validation-config | 01-09 |
| 09 | test_studentresult_09_withhold_request_rules_and_open_authorize | TC-N09/SEC-MSH-003 | Validation-config | 01-09 |
| 10 | test_studentresult_10_results_screen_renders_four_tabs | TC-P10 | Business | 10-19 |
| 11 | test_studentresult_11_store_persists_and_logs_stored | TC-P11 | Business | 10-19 |
| 12 | test_studentresult_12_update_persists_and_logs_updated | TC-P12 | Business | 10-19 |
| 13 | test_studentresult_13_destroy_soft_deletes_and_logs_deleted | TC-D13 | Dependency | 10-19 |
| 14 | test_studentresult_14_show_page_displays_aggregates | TC-P14 | Business | 10-19 |
| 15 | test_studentresult_15_export_returns_xlsx_download | TC-P15 | Business | 10-19 |
| 16 | test_studentresult_16_print_route_resolves | TC-P16 | Business | 10-19 |
| 17 | test_studentresult_17_pdf_route_resolves_to_print_download | TC-P17 | Business | 10-19 |
| 18 | test_studentresult_18_index_redirects_to_combined_results | TC-P18 | Business | 10-19 |
| 19 | test_studentresult_19_invalid_id_returns_404_on_show | TC-N19 | Negative | 10-19 |
| 20 | test_studentresult_20_withhold_sets_withheld_and_logs | TC-SM20 | State-machine | 20-29 |
| 21 | test_studentresult_21_declare_sets_declared_and_clears_reason | TC-SM21 | State-machine | 20-29 |
| 22 | test_studentresult_22_withhold_blocked_when_schedule_locked | TC-SM22 | State-machine | 20-29 |
| 23 | test_studentresult_23_declare_blocked_when_schedule_locked | TC-SM23 | State-machine | 20-29 |
| 24 | test_studentresult_24_withhold_requires_reason_min_length | TC-N24 | Negative | 20-29 |
| 25 | test_studentresult_25_withhold_requires_reason_present | TC-N25 | Negative | 20-29 |
| 30 | test_studentresult_30_required_fields_block_store | TC-N30 | Negative | 30-39 |
| 31 | test_studentresult_31_duplicate_schedule_student_rejected | TC-N31 | Negative | 30-39 |
| 32 | test_studentresult_32_overall_percentage_over_100_rejected | TC-N32 | Negative | 30-39 |
| 33 | test_studentresult_33_invalid_promotion_status_rejected | TC-N33 | Negative | 30-39 |
| 34 | test_studentresult_34_invalid_result_status_rejected | TC-N34 | Negative | 30-39 |
| 35 | test_studentresult_35_nonexistent_schedule_rejected | TC-N35 | Negative | 30-39 |
| 36 | test_studentresult_36_nonexistent_student_rejected | TC-N36 | Negative | 30-39 |
| 37 | test_studentresult_37_rank_below_one_rejected | TC-N37 | Negative | 30-39 |
| 38 | test_studentresult_38_update_invalid_id_returns_404 | TC-N38 | Negative | 30-39 |
| 39 | test_studentresult_39_withhold_reason_over_255_rejected | TC-N39 | Negative | 30-39 |
| 40 | test_studentresult_40_soft_deleted_result_hidden_from_active_scope | TC-D40 | Dependency | 40-49 |
| 41 | test_studentresult_41_result_status_defaults_survive_round_trip | TC-D41 | Dependency | 40-49 |
| 42 | test_studentresult_42_subject_results_tab_renders | TC-D42 | Integration | 40-49 |
| 43 | test_studentresult_43_ia_marks_tab_renders | TC-D43 | Integration | 40-49 |
| 44 | test_studentresult_44_coscholastic_tab_renders | TC-D44 | Integration | 40-49 |
| 45 | test_studentresult_45_computation_log_index_renders_read_only | TC-D45 | Integration | 40-49 |
| 50 | test_studentresult_50_guest_redirected_to_login | TC-N50 | Permissions | 50-59 |
| 51 | test_studentresult_51_sec_msh_001_create_uses_view_gate | TC-S51 | Security-defect | 50-59 |
| 52 | test_studentresult_52_sec_msh_002_store_uses_update_gate | TC-S52 | Security-defect | 50-59 |
| 53 | test_studentresult_53_sec_msh_003_form_request_authorize_open | TC-S53 | Security-defect | 50-59 |
| 54 | test_studentresult_54_result_tabs_are_permission_gated_in_view | TC-AUTH54 | Permissions | 50-59 |
| 55 | test_studentresult_55_results_controller_gate_is_msh_results_view | TC-AUTH55 | Permissions | 50-59 |
| 60 | test_studentresult_60_student_search_filter_applies | TC-P60 | UI/UX | 60-69 |
| 61 | test_studentresult_61_class_section_filter_control_present | TC-P61 | UI/UX | 60-69 |
| 62 | test_studentresult_62_empty_state_message_when_no_results | TC-P62 | UI/UX | 60-69 |
| 63 | test_studentresult_63_breadcrumb_present_on_results_screen | TC-P63 | UI/UX | 60-69 |
| 70 | test_studentresult_70_subject_results_relationship_is_cross_schedule | TC-EDG70 | Edge | 70-79 |
| 71 | test_studentresult_71_whitespace_only_withhold_reason_rejected | TC-EDG71 | Edge | 70-79 |
| 72 | test_studentresult_72_grand_total_high_precision_persists | TC-EDG72 | Edge | 70-79 |
| 90 | test_studentresult_90_cross_tenant_direct_id_is_not_leaked | TC-T90 | Tenancy | 90-99 |
| 91 | test_studentresult_91_xss_in_withhold_reason_is_stored_escaped | TC-S91 | Security | 90-99 |
| 92 | test_studentresult_92_computation_log_force_delete_would_throw | TC-S92 | Security | 90-99 |

**Total: 57 methods.**
