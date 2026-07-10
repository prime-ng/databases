# Test Case List — MarksheetGeneration / Student Results & Print

- **Module:** MarksheetGeneration (MSH) · **Prefix:** `msh_`
- **Feature / Screen:** StudentResultsAndPrint (`05-Student-Results-and-Print.md`)
- **Primary table:** `msh_student_results` (verified in `MarksheetGeneration_DDL_v1.sql`, table 17)
- **Combined screen route:** `marksheet-generation.results.combined` → `/marksheet-generation/results` (`MarksheetGenerationController::results()`, gate `tenant.msh-results.view`)
- **Primary controller:** `StudentResultController` (index/create/store/show/edit/update/destroy + export/print/pdf/withhold/declare)
- **DB scope:** TENANT-side (DDL `Database: tenant_db`, prefix `msh_`) → tenancy scaffolding required
- **Style:** browser Dusk (golden Class reference), `extends DuskTestCase`, `namespace Tests\Browser;`

---

## 1. Business Conditions

### BC-DB — Schema / columns / constraints
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `msh_student_results` has aggregate cols (grand_total, grand_max, overall_percentage DECIMAL, overall_grade, division, rank_in_section/class, promotion_status, result_status, withheld_reason) | DDL-msh_student_results |
| BC-DB-02 | UNIQUE `(schedule_id, student_id)` = `uq_msh_sr_schedule_student` | DDL-msh_student_results |
| BC-DB-03 | FK schedule_id→msh_marksheet_schedules `ON DELETE CASCADE`; student_id→std_students `RESTRICT`; class_section_id→sch_class_section_jnt `RESTRICT` | DDL-msh_student_results |
| BC-DB-04 | `msh_student_results` uses `deleted_at` (SoftDeletes) | DDL / StudentResult model |
| BC-DB-05 | `msh_student_subject_results` per-subject columns (theory/practical/HW/quiz/quest/IA/subject_total/grade) | DDL-msh_student_subject_results |
| BC-DB-06 | `msh_student_ia_marks` teacher-entry cols; FK ia_component_id→msh_template_ia_components `RESTRICT`; `max_marks` NOT NULL | DDL-msh_student_ia_marks |
| BC-DB-07 | `msh_student_coscholastic_results` grade + `is_auto_from_ba` | DDL-msh_student_coscholastic_results |
| BC-DB-08 | `msh_student_attendance` total_working_days/days_present; UNIQUE (schedule_id, student_id); NO destroy route | DDL-msh_student_attendance |
| BC-DB-09 | `msh_student_subject_exam_marks` = core marks matrix (read-only index/show) | DDL-msh_student_subject_exam_marks |
| BC-DB-10 | **`msh_computation_logs` has NO `deleted_at`** — immutable audit log; ComputationLog does NOT use SoftDeletes → `withTrashed()/forceDelete()` throw | DDL-msh_computation_logs / ComputationLog model |

### BC-VAL — Validation rules (StudentResultRequest / WithholdStudentResultRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | schedule_id required·integer·exists:msh_marksheet_schedules,id | Req-StudentResultRequest |
| BC-VAL-02 | student_id required·integer·exists:std_students,id | Req-StudentResultRequest |
| BC-VAL-03 | class_section_id required·integer·exists:sch_class_section_jnt,id | Req-StudentResultRequest |
| BC-VAL-04 | UNIQUE (schedule_id, student_id) via `Rule::unique(...)->ignore($id)` | Req-StudentResultRequest |
| BC-VAL-05 | overall_percentage numeric·min:0·max:100 | Req-StudentResultRequest |
| BC-VAL-06 | promotion_status in PROMOTED,DETAINED,COMPARTMENT,PLACED | Req-StudentResultRequest |
| BC-VAL-07 | result_status in DECLARED,WITHHELD | Req-StudentResultRequest |
| BC-VAL-08 | rank_in_section/class integer·min:1 | Req-StudentResultRequest |
| BC-VAL-09 | withheld_reason required·string·min:5·max:255 (withhold) | Req-WithholdStudentResultRequest |

### BC-AUTH — Permission gates
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Combined results screen: `tenant.msh-results.view` | Screen-PM / MarksheetGenerationController::results() |
| BC-AUTH-02 | show/index/edit/update: `tenant.msh-student-result.view` / `.update` | StudentResultController |
| BC-AUTH-03 | destroy `.delete`; export `.export`; print/pdf `.print`; withhold `.withhold`; declare `.declare` | StudentResultController |
| BC-AUTH-04 | Tab visibility gated by `@can('tenant.msh-student-{entity}.view')` in `pages/results.blade.php` | Screen-view |
| BC-AUTH-05 | **SEC-MSH-001** create() authorizes `.view` (should be `.create`) | Audit-SEC-MSH-001 |
| BC-AUTH-06 | **SEC-MSH-002** store() authorizes `.update` (should be `.create`) | Audit-SEC-MSH-002 |
| BC-AUTH-07 | **SEC-MSH-003/D39** FormRequest `authorize()` returns `true` (no per-request gate) | Audit-SEC-MSH-003 |

### BC-BIZ — Business logic / activity-log events
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | store → `activityLog(..., 'Stored')`; created_by/updated_by = auth id | Controller |
| BC-BIZ-02 | update → `activityLog(..., 'Updated')` | Controller |
| BC-BIZ-03 | destroy → soft delete + `activityLog(..., 'Deleted')` | Controller |
| BC-BIZ-04 | withhold → service sets result_status=WITHHELD + reason; `activityLog(..., 'Withheld')`; writes msh_computation_logs action=WITHHOLD | Controller + StudentResultReviewService |
| BC-BIZ-05 | declare → service sets result_status=DECLARED, nulls reason; `activityLog(..., 'Declared')`; writes msh_computation_logs action=DECLARE | Controller + StudentResultReviewService |
| BC-BIZ-06 | index() redirects to `results.combined?tab=student-results` | Controller |
| BC-BIZ-07 | export → `Excel::download(StudentResultExport)` xlsx | Controller |
| BC-BIZ-08 | print → `Template::render('MARKSHEET_PRINT', ...)`; on `\DomainException` redirect back with error | Controller |
| BC-BIZ-09 | downloadPdf → redirect to print with `download=1&auto=1` (html2pdf.js) | Controller |
| BC-BIZ-10 | activity events verbatim: `Stored/Updated/Deleted/Withheld/Declared` (child entities also `Toggled/Restored`) | Controller |

### BC-SM — State machine (result_status)
| ID | State | Trigger | Next | Guard | Source |
|----|-------|---------|------|-------|--------|
| BC-SM-01 | DECLARED | withhold(reason) | WITHHELD | schedule not locked; reason min:5 | Screen-SM / Service |
| BC-SM-02 | WITHHELD | declare() | DECLARED (reason nulled) | schedule not locked | Screen-SM / Service |
| BC-SM-03 | any | withhold while **locked** | *rejected* (DomainException → redirect error) | is_locked=1 | Service |
| BC-SM-04 | any | declare while **locked** | *rejected* | is_locked=1 | Service |

### BC-INT — Integration points
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Print engine calls Template module `Template::render('MARKSHEET_PRINT', subjectId, classId, sessionId, studentId)` | Screen-IP / Controller |
| BC-INT-02 | Exam-mark matrix sourced from LmsExam (`exam_type_id`→lms_exam_types, `exam_result_id`→lms_exam_results) | DDL / Screen-IP |
| BC-INT-03 | Coscholastic Discipline may auto-populate from BehaviouralAssessment (`is_auto_from_ba`) | DDL / Screen-IP |

### BC-REF — FK onDelete
| ID | FK | Referenced | onDelete | Source |
|----|----|-----------|----------|--------|
| BC-REF-01 | schedule_id | msh_marksheet_schedules | CASCADE | DDL |
| BC-REF-02 | student_id | std_students | RESTRICT | DDL |
| BC-REF-03 | class_section_id | sch_class_section_jnt | RESTRICT | DDL |

### BC-EDG — Edge cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `subjectResults()`/`coscholasticResults()` join on **student_id only** (cross-schedule); use `subjectResultsForSchedule()` for scoped rows | Model docblock |
| BC-EDG-02 | grand_total DECIMAL(8,2) boundary precision | DDL |
| BC-EDG-03 | whitespace-only withheld_reason blocked (min:5 + service trim guard) | Req + Service |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----------|----|--------|-------------|----------|----|----|--------|
| TC-P01 | Config | BC-DB-01..04, BC-VAL-* | DDL/Req | Schema+model+request config correct | schema/fillable/relations/rules truth | 01 | 01,02,08 | Automated |
| TC-P02 | Render | BC-AUTH-01 | Screen | Combined screen renders 4 tabs | tabs present | 02 | 10 | Automated |
| TC-P03 | Create | BC-BIZ-01 | Controller | Store persists + Stored log | row+activity | 03 | 11 | Automated |
| TC-P04 | Read | BC-BIZ | Controller | Show displays aggregates | grade/% shown | 04 | 14 | Automated |
| TC-P05 | Update | BC-BIZ-02 | Controller | Update persists + Updated log | row+activity | 05 | 12 | Automated |
| TC-P06 | Delete | BC-BIZ-03 | Controller | Destroy soft-deletes + Deleted log | deleted_at+activity | 06 | 13 | Automated |
| TC-P07 | Export | BC-BIZ-07 | Controller | Export returns xlsx (200) | download | 11 | 15 | Automated |
| TC-P08 | Print | BC-BIZ-08 | Controller | Print route resolves (200/302) | route+gate | 12 | 16 | Automated |
| TC-P09 | PDF | BC-BIZ-09 | Controller | PDF route resolves to print download | 200/302 | — | 17 | Automated |
| TC-P10 | Redirect | BC-BIZ-06 | Controller | index redirects to combined | path=/results | 16 | 18 | Automated |
| TC-P11 | State | BC-SM-01 | Service | withhold → WITHHELD + Withheld log | status+reason+activity | 09 | 20 | Automated |
| TC-P12 | State | BC-SM-02 | Service | declare → DECLARED + reason nulled | status+activity | 10 | 21 | Automated |
| TC-P13 | Child schema | BC-DB-05..09 | DDL | Child tables schema correct | columns present | 14 | 03,04,05,06 | Automated |
| TC-P14 | UI | BC-AUTH-04 | Screen | subject/ia/coscholastic tabs render | tab content | — | 42,43,44 | Automated |
| TC-P15 | Read-only | BC-DB-09 | Controller | computation-log index resolves | 200/302 | — | 45 | Automated |

### Negative (TC-N)
| TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----------|----|--------|-------------|----------|----|----|--------|
| TC-N01 | Required | BC-VAL-01..03 | Req | Missing required → 422 | 422 | 08 | 30 | Automated |
| TC-N02 | Duplicate | BC-VAL-04, BC-DB-02 | Req/DDL | Duplicate (schedule,student) → 422; no insert | 422 | 07 | 31 | Automated |
| TC-N03 | Range | BC-VAL-05 | Req | overall_percentage>100 → 422 | 422 | — | 32 | Automated |
| TC-N04 | Enum | BC-VAL-06 | Req | promotion_status invalid → 422 | 422 | — | 33 | Automated |
| TC-N05 | Enum | BC-VAL-07 | Req | result_status invalid → 422 | 422 | — | 34 | Automated |
| TC-N06 | Exists | BC-VAL-01 | Req | schedule_id not exists → 422 | 422 | — | 35 | Automated |
| TC-N07 | Exists | BC-VAL-02 | Req | student_id not exists → 422 | 422 | — | 36 | Automated |
| TC-N08 | Range | BC-VAL-08 | Req | rank_in_section<1 → 422 | 422 | — | 37 | Automated |
| TC-N09 | 404 | BC-BIZ | Controller | show invalid id → 404 | 404 | — | 19 | Automated |
| TC-N10 | 404 | BC-BIZ | Controller | update invalid id → 404 | 404 | — | 38 | Automated |
| TC-N11 | Withhold req | BC-VAL-09 | Req | withheld_reason missing → 422 | 422 | — | 25 | Automated |
| TC-N12 | Withhold min | BC-VAL-09 | Req | withheld_reason<5 → 422 | 422 | — | 24 | Automated |
| TC-N13 | Withhold max | BC-VAL-09 | Req | withheld_reason>255 → 422 | 422 | — | 39 | Automated |
| TC-N14 | Whitespace | BC-EDG-03 | Req/Service | blank reason → 422, not withheld | 422 | — | 71 | Automated |
| TC-N15 | Auth | BC-AUTH | routes | Guest → /login | redirect | 13 | 50 | Automated |

### State-transition (TC-SM)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-SM01 | BC-SM-01 | Service | DECLARED→WITHHELD legal | status WITHHELD | 09 | 20 | Automated |
| TC-SM02 | BC-SM-02 | Service | WITHHELD→DECLARED legal | status DECLARED | 10 | 21 | Automated |
| TC-SM03 | BC-SM-03 | Service | withhold while locked (illegal) | rejected, unchanged | — | 22 | Automated |
| TC-SM04 | BC-SM-04 | Service | declare while locked (illegal) | rejected, unchanged | — | 23 | Automated |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 | B | BC-DB-04 | DDL | soft-deleted result hidden from active scope | withTrashed visible | — | 40 | Automated |
| TC-D02 | E | BC-INT-01 | Screen | print engine integrates Template module | route resolves | 12 | 16 | Automated |
| TC-D03 | G | BC-EDG-02 | DDL | grand_total precision round-trip | 999999.99 | — | 41,72 | Automated |
| TC-D04 | C | BC-DB-10 | DDL | computation-log immutable (no soft delete) | withTrashed throws | 15 | 07,92 | Automated |

### Security (TC-S)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-S01 | BC-AUTH-05 | Audit | SEC-MSH-001 create() uses `.view` gate | source proves current | — | 51 | Automated |
| TC-S02 | BC-AUTH-06 | Audit | SEC-MSH-002 store() uses `.update` gate | source proves current | — | 52 | Automated |
| TC-S03 | BC-AUTH-07 | Audit | SEC-MSH-003 FormRequest authorize()=true | source proves current | — | 53,09 | Automated |
| TC-S04 | BC-AUTH-04 | Screen | tabs permission-gated in view | @can present | — | 54 | Automated |
| TC-S05 | BC-AUTH-01 | Controller | results() gate = msh-results.view | source | — | 55 | Automated |
| TC-S06 | — | Tenancy | cross-tenant/out-of-range id → 404 (IDOR) | 404 | — | 90 | Automated |
| TC-S07 | BC-EDG-03 | Security | XSS in withheld_reason stored, Blade-escaped | stored verbatim | — | 91 | Automated |

### Known Source Defects (audit-equivalent, proving tests)
| ID | Severity | Description | Proving test | Type |
|----|----------|-------------|--------------|------|
| SEC-MSH-001 | P1 | `StudentResultController::create()` authorizes `tenant.msh-student-result.view` instead of `.create` | V2 test_51 (source assertion) | Confirmed |
| SEC-MSH-002 | P1 | `StudentResultController::store()` authorizes `tenant.msh-student-result.update` instead of `.create` | V2 test_52 | Confirmed |
| SEC-MSH-003 / D39-MSH | P1 | FormRequests (`StudentResultRequest`, `WithholdStudentResultRequest`) `authorize()` return `true` — sole reliance on controller `Gate::authorize`; perms unseeded (env prereq) | V2 test_53, test_09 | Confirmed |
| PERF-MSH-003 | P2 | `create()`/`edit()` load unbounded `Student::where('is_active',1)->get()` + classSections `->get()`; `results()` also builds unbounded `resultClassSections` — no pagination | Documented (Gap Analysis Cross-Ref #6) | Confirmed in source |
| PERF-MSH-004 | P3 | Recompute path hard-deletes soft-deletable result rows (permanent loss) — lives in the compute/schedule flow, **out of scope for this screen** | Documented; verify in MarksheetSchedule compute feature | Cross-feature |
| BUG-MSH-101 (candidate) | P3 | Entity permission ability names are inconsistent across controllers: index gates use `.viewAny` (IaMark, Coscholastic) while StudentSubjectExamMark index uses `.view`; combined results uses `tenant.msh-results.view` (a non-entity gate) — verify the permission seeder defines all of these. | Verify in source (permission seeder) | Candidate |

---

## 3. V2 Test Method Index (57 methods)
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_studentresult_01_student_results_schema_and_model_are_correct | TC-P01 | Config | 01-09 |
| 2 | test_studentresult_02_unique_schedule_student_index_exists | TC-P01/BC-DB-02 | Config | 01-09 |
| 3 | test_studentresult_03_subject_results_schema_is_correct | TC-P13 | Config | 01-09 |
| 4 | test_studentresult_04_ia_marks_schema_is_correct | TC-P13 | Config | 01-09 |
| 5 | test_studentresult_05_coscholastic_and_attendance_schema_are_correct | TC-P13 | Config | 01-09 |
| 6 | test_studentresult_06_exam_marks_matrix_schema_is_correct | TC-P13 | Config | 01-09 |
| 7 | test_studentresult_07_computation_log_immutable_no_soft_deletes | TC-D04 | Config | 01-09 |
| 8 | test_studentresult_08_student_result_request_rules_are_verbatim | TC-P01 | Config | 01-09 |
| 9 | test_studentresult_09_withhold_request_rules_and_open_authorize | TC-S03/BC-VAL-09 | Config | 01-09 |
| 10 | test_studentresult_10_results_screen_renders_four_tabs | TC-P02 | BizRule | 10-19 |
| 11 | test_studentresult_11_store_persists_and_logs_stored | TC-P03 | BizRule | 10-19 |
| 12 | test_studentresult_12_update_persists_and_logs_updated | TC-P05 | BizRule | 10-19 |
| 13 | test_studentresult_13_destroy_soft_deletes_and_logs_deleted | TC-P06 | BizRule | 10-19 |
| 14 | test_studentresult_14_show_page_displays_aggregates | TC-P04 | BizRule | 10-19 |
| 15 | test_studentresult_15_export_returns_xlsx_download | TC-P07 | BizRule | 10-19 |
| 16 | test_studentresult_16_print_route_resolves | TC-P08/TC-D02 | BizRule | 10-19 |
| 17 | test_studentresult_17_pdf_route_resolves_to_print_download | TC-P09 | BizRule | 10-19 |
| 18 | test_studentresult_18_index_redirects_to_combined_results | TC-P10 | BizRule | 10-19 |
| 19 | test_studentresult_19_invalid_id_returns_404_on_show | TC-N09 | BizRule | 10-19 |
| 20 | test_studentresult_20_withhold_sets_withheld_and_logs | TC-SM01 | StateMachine | 20-29 |
| 21 | test_studentresult_21_declare_sets_declared_and_clears_reason | TC-SM02 | StateMachine | 20-29 |
| 22 | test_studentresult_22_withhold_blocked_when_schedule_locked | TC-SM03 | StateMachine | 20-29 |
| 23 | test_studentresult_23_declare_blocked_when_schedule_locked | TC-SM04 | StateMachine | 20-29 |
| 24 | test_studentresult_24_withhold_requires_reason_min_length | TC-N12 | StateMachine | 20-29 |
| 25 | test_studentresult_25_withhold_requires_reason_present | TC-N11 | StateMachine | 20-29 |
| 30 | test_studentresult_30_required_fields_block_store | TC-N01 | Validation | 30-39 |
| 31 | test_studentresult_31_duplicate_schedule_student_rejected | TC-N02 | Validation | 30-39 |
| 32 | test_studentresult_32_overall_percentage_over_100_rejected | TC-N03 | Validation | 30-39 |
| 33 | test_studentresult_33_invalid_promotion_status_rejected | TC-N04 | Validation | 30-39 |
| 34 | test_studentresult_34_invalid_result_status_rejected | TC-N05 | Validation | 30-39 |
| 35 | test_studentresult_35_nonexistent_schedule_rejected | TC-N06 | Validation | 30-39 |
| 36 | test_studentresult_36_nonexistent_student_rejected | TC-N07 | Validation | 30-39 |
| 37 | test_studentresult_37_rank_below_one_rejected | TC-N08 | Validation | 30-39 |
| 38 | test_studentresult_38_update_invalid_id_returns_404 | TC-N10 | Validation | 30-39 |
| 39 | test_studentresult_39_withhold_reason_over_255_rejected | TC-N13 | Validation | 30-39 |
| 40 | test_studentresult_40_soft_deleted_result_hidden_from_active_scope | TC-D01 | Integration | 40-49 |
| 41 | test_studentresult_41_result_status_defaults_survive_round_trip | TC-D03 | Integration | 40-49 |
| 42 | test_studentresult_42_subject_results_tab_renders | TC-P14 | Integration | 40-49 |
| 43 | test_studentresult_43_ia_marks_tab_renders | TC-P14 | Integration | 40-49 |
| 44 | test_studentresult_44_coscholastic_tab_renders | TC-P14 | Integration | 40-49 |
| 45 | test_studentresult_45_computation_log_index_renders_read_only | TC-P15 | Integration | 40-49 |
| 50 | test_studentresult_50_guest_redirected_to_login | TC-N15 | Permissions | 50-59 |
| 51 | test_studentresult_51_sec_msh_001_create_uses_view_gate | TC-S01 | Permissions | 50-59 |
| 52 | test_studentresult_52_sec_msh_002_store_uses_update_gate | TC-S02 | Permissions | 50-59 |
| 53 | test_studentresult_53_sec_msh_003_form_request_authorize_open | TC-S03 | Permissions | 50-59 |
| 54 | test_studentresult_54_result_tabs_are_permission_gated_in_view | TC-S04 | Permissions | 50-59 |
| 55 | test_studentresult_55_results_controller_gate_is_msh_results_view | TC-S05 | Permissions | 50-59 |
| 60 | test_studentresult_60_student_search_filter_applies | TC-P02/UIX | UI/UX | 60-69 |
| 61 | test_studentresult_61_class_section_filter_control_present | UIX | UI/UX | 60-69 |
| 62 | test_studentresult_62_empty_state_message_when_no_results | UIX | UI/UX | 60-69 |
| 63 | test_studentresult_63_breadcrumb_present_on_results_screen | UIX | UI/UX | 60-69 |
| 70 | test_studentresult_70_subject_results_relationship_is_cross_schedule | BC-EDG-01 | Edge | 70-79 |
| 71 | test_studentresult_71_whitespace_only_withhold_reason_rejected | TC-N14 | Edge | 70-79 |
| 72 | test_studentresult_72_grand_total_high_precision_persists | TC-D03 | Edge | 70-79 |
| 90 | test_studentresult_90_cross_tenant_direct_id_is_not_leaked | TC-S06 | Tenancy/Sec | 90-99 |
| 91 | test_studentresult_91_xss_in_withhold_reason_is_stored_escaped | TC-S07 | Tenancy/Sec | 90-99 |
| 92 | test_studentresult_92_computation_log_force_delete_would_throw | TC-D04 | Tenancy/Sec | 90-99 |
