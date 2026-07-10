# msh — Components & Weightages — Test Case List (Requirements)

**Module:** MarksheetGeneration (`MSH`, prefix `msh_`, tenant_db)
**Screen / Feature:** Components & Weightages (combined tabbed page)
**Primary requirement:** `MarksheetGeneration_V2/03-Components-and-Weightages.md`
**Primary table (schema truth):** `msh_template_scholastic_components`
**Secondary tables:** `msh_template_exam_weightages`, `msh_template_ia_components`, `msh_template_coscholastic_components`
**Page route:** `GET /marksheet-generation/components` → `marksheet-generation.components.combined` → `MarksheetGenerationController::components()` (Gate `tenant.msh-components.view`)
**Test style:** Browser Dusk (`extends DuskTestCase`, `namespace Tests\Browser`). No committed MSH sibling — golden `Class` reference used.
**Files:** `msh_ComponentsAndWeightagesV1_TestCas.php` (20), `msh_ComponentsAndWeightagesV2_TestCas.php` (50).

---

## 1. Business Conditions

### BC-DB — Schema / constraints (Source: DDL)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `msh_template_scholastic_components` has `weightage_percent DECIMAL(5,2) NOT NULL`, `max_marks DECIMAL(8,2) NULL`, soft deletes | DDL-msh_template_scholastic_components |
| BC-DB-02 | UNIQUE (`config_template_id`,`source_component_id`) = `uq_msh_tsc_template_component` | DDL-msh_template_scholastic_components |
| BC-DB-03 | `msh_template_exam_weightages` UNIQUE (`config_template_id`,`exam_type_id`); `weightage_percent DECIMAL(5,2)` | DDL-msh_template_exam_weightages |
| BC-DB-04 | `msh_template_ia_components` UNIQUE (`config_template_id`,`ia_component_type_id`); `max_marks DECIMAL(5,2)`, `display_order` | DDL-msh_template_ia_components |
| BC-DB-05 | `msh_template_coscholastic_components` UNIQUE (`config_template_id`,`code`); `grading_scale VARCHAR(50) DEFAULT '3_POINT'`, `is_ba_linked` | DDL-msh_template_coscholastic_components |
| BC-DB-06 | All four models use `SoftDeletes`; casts `is_active`→bool, `weightage_percent`/`max_marks`→decimal:2 | Model source |

### BC-VAL — Validation rules (Source: FormRequests)
| ID | Condition | Message / rule | Source |
|----|-----------|----------------|--------|
| BC-VAL-01 | Scholastic: `config_template_id` required|integer|exists:msh_config_templates,id | default | Req-TemplateScholasticComponentRequest |
| BC-VAL-02 | Scholastic: `source_component_id` required|integer|exists:msh_source_components,id | default | Req |
| BC-VAL-03 | Scholastic: `weightage_percent` required|numeric|min:0|max:100|regex 2dp | default | Req |
| BC-VAL-04 | Scholastic: duplicate (template,source) on create | `The source component id has already been taken.` | Req (closure) |
| BC-VAL-05 | Scholastic: `max_marks` nullable|numeric|min:0 | default | Req |
| BC-VAL-06 | Exam: `exam_type_id` required|exists:lms_exam_types,id + unique per template; `weightage_percent` min:0|max:100 | default | Req-TemplateExamWeightageRequest |
| BC-VAL-07 | IA: `ia_component_type_id` required|exists + unique per template; `max_marks` required|numeric|min:0|regex 2dp; `display_order` required|integer|min:1 | default | Req-TemplateIaComponentRequest |
| BC-VAL-08 | Coscholastic: `code` required|string|max:30 + unique per template; `name` required|string|max:100; `grading_scale` sometimes|string|max:50 (**no `in:` enum**) | default | Req-TemplateCoscholasticComponentRequest |

### BC-AUTH — Permission gates (Source: Controllers)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Page requires `tenant.msh-components.view` | Screen-PM / MarksheetGenerationController::components |
| BC-AUTH-02 | store/update/toggle/restore require `tenant.msh-{entity}.create|update`; destroy/forceDelete require `.delete`; trashed/viewAny `.viewAny` | Each entity controller |
| BC-AUTH-03 | **SEC-MSH-003** — all four FormRequests `authorize()` return `true` (authz lives only in controller gates) | Audit-SEC-MSH-003 |
| BC-AUTH-04 | Guest is redirected to `/login` | Route middleware `auth` |

### BC-BIZ — Business logic / activity log (Source: Controllers/Services + Screen)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Create logs activity event `Stored`; update `Updated`; toggle `Toggled`; delete/forceDelete `Deleted`; restore `Restored` (issued_by = admin) | Controllers `activityLog(...)` |
| BC-BIZ-02 | store/update return JSON `{status,message,redirect}` when `expectsJson()` | Controllers |
| BC-BIZ-03 | `created_by` set from `auth()->id()` on create; `updated_by` on update/toggle | Controllers/Services |
| BC-BIZ-04 | Scholastic weightages sum to 100 (BR-MSG-002); Exam weightages sum to 100 (BR-MSG-003) | Screen-BR / DDL comments |
| BC-BIZ-05 | Combined page paginates each tab with a distinct page param (`sc_page`,`ew_page`,`ia_page`,`cc_page`); coscholastic tab searches name/code | Controller components() |

### BC-INT — Integration points / FK (Source: DDL FKs)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | `config_template_id` → `msh_config_templates` ON DELETE **CASCADE** | DDL |
| BC-INT-02 | `source_component_id` → `msh_source_components` ON DELETE **RESTRICT** | DDL |
| BC-INT-03 | exam `exam_type_id` → `lms_exam_types` ON DELETE RESTRICT (cross-module) | DDL |
| BC-INT-04 | IA `ia_component_type_id` → `msh_ia_component_types` ON DELETE RESTRICT | DDL |

### BC-REF — FK onDelete behaviour (Source: DDL)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | Hard-deleting a config template CASCADE-removes its scholastic/exam/ia/coscholastic rows | DDL |
| BC-REF-02 | A source component referenced by a scholastic row cannot be hard-deleted (RESTRICT) | DDL |

### BC-EDG — Edge / boundary (Source: DDL limits + Screen)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `weightage_percent` boundaries: 0 accepted, 100 accepted, >100 rejected, negative rejected | DDL / Req |
| BC-EDG-02 | `weightage_percent` non-numeric and >2 decimals rejected (regex) | Req |
| BC-EDG-03 | Duplicate (template,component/type/code) rejected per entity | Req |
| BC-EDG-04 | Co-scholastic `code` > 30 chars rejected | Req |
| BC-EDG-05 | Stored-XSS in coscholastic `name` is HTML-escaped in listing | Security |

### BC-CFG — Configuration rule: weightage-sum enforcement (Source: Services + Audit)
| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | Scholastic sum=100 is validated **only** by `MarksheetConfigService::validateScholasticWeightageSum()`, invoked **only** from `TemplateScholasticComponentService::create/update` | Service source |
| BC-CFG-02 | Controller `store()` calls `TemplateScholasticComponent::create()` directly → **create bypasses the sum validation** (BUG-MSH-C01) | Controller source |
| BC-CFG-03 | Controller `update()` routes through the service → sum validated; on violation an uncaught `DomainException` → HTTP 500, transaction rolls back (BUG-MSH-C03) | Controller/Service |
| BC-CFG-04 | Exam sum validator `validateExamWeightageSum()` has **no production caller** → BR-MSG-003 never enforced (BUG-MSH-C02) | Service grep |
| BC-CFG-05 | Schedule `precheck()` only **counts** weightage rows, never sums them (confirms BR-MSH-050/009/012) | MarksheetScheduleController::precheck |
| BC-CFG-06 | Co-scholastic `grading_scale` has no `in:` enum rule → out-of-spec values accepted (BUG-MSH-C04) | Req |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----------|----|--------|-------------|----------|----|----|--------|
| TC-P01 | Create | BC-BIZ-01/03 | Ctrl | Create scholastic component | 200, row persists, `Stored`, created_by=admin | 10 | 10 | Automated |
| TC-P02 | Create | BC-BIZ-01 | Ctrl | Create exam weightage | 200, `Stored` | 12 | 11 | Automated |
| TC-P03 | Create | BC-BIZ-01 | Ctrl | Create IA component | 200, `Stored`, max_marks | 13 | 12 | Automated |
| TC-P04 | Create | BC-BIZ-01/BC-DB-05 | Ctrl | Create coscholastic (grading_scale, is_ba_linked) | 200, `Stored` | 14 | 13 | Automated |
| TC-P05 | Create | BC-VAL-05 | Req | Scholastic max_marks nullable accepted | 200, null max_marks | — | 14 | Automated |
| TC-P06 | Create | BC-DB-05 | Req | Coscholastic is_ba_linked defaults false when omitted | is_ba_linked=0 | — | 15 | Automated |
| TC-P07 | Update | BC-BIZ-01/CFG-03 | Ctrl | Scholastic update keeping sum=100 | 200, `Updated` | 81 | 84 | Automated |
| TC-P08 | Toggle | BC-BIZ-01 | Ctrl | Scholastic toggle status | 200, is_active flips, `Toggled` | 82 | 90 | Automated |
| TC-P09 | Lifecycle | BC-BIZ-01/BC-REF | Ctrl | Delete → restore → forceDelete | soft-del/restore/gone + logs | 83 | 91 | Automated |
| TC-P10 | Read | BC-AUTH-01 | Ctrl | Page renders four tab panes | all tabs present | 60 | 60 | Automated |
| TC-P11 | Read | BC-BIZ-05 | Ctrl | Created scholastic row listed | source name visible | — | 61 | Automated |
| TC-P12 | Read | BC-BIZ-05 | Ctrl | Coscholastic search by code | match returned | — | 62 | Automated |
| TC-P13 | Read | BC-BIZ-05 | Ctrl | Independent page params per tab | sc/ew/ia/cc _page present | — | 63 | Automated |
| TC-P14 | Read | BC-BIZ-01 | Ctrl | Scholastic show endpoint 200 | 200 | 90 | 74(neg) | Automated |
| TC-P15 | Lifecycle | BC-BIZ-01 | Ctrl | Exam weightage delete logs Deleted | `Deleted` | — | 92 | Automated |
| TC-P16 | Lifecycle | BC-BIZ-01 | Ctrl | Coscholastic update logs Updated | `Updated` | — | 93 | Automated |

### Negative (TC-N)
| TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----------|----|--------|-------------|----------|----|----|--------|
| TC-N01 | Required | BC-VAL-01/02/03 | Req | Scholastic empty payload | 422, field errors | 30 | 30 | Automated |
| TC-N02 | Range | BC-EDG-01 | Req | Scholastic weightage 150 | 422 weightage_percent | 31 | 31 | Automated |
| TC-N03 | Range | BC-EDG-01 | Req | Scholastic weightage negative | 422 | — | 32 | Automated |
| TC-N04 | Format | BC-EDG-02 | Req | Scholastic weightage non-numeric | 422 | — | 33 | Automated |
| TC-N05 | Format | BC-EDG-02 | Req | Scholastic weightage 3 decimals | 422 (regex) | — | 34 | Automated |
| TC-N06 | Duplicate | BC-VAL-04/EDG-03 | Req | Scholastic duplicate (template,source) | 422 + exact message | 32 | 35 | Automated |
| TC-N07 | Exists | BC-INT-01 | Req | Scholastic invalid config_template_id | 422 exists | 40 | 40 | Automated |
| TC-N08 | Exists | BC-INT-02 | Req | Scholastic invalid source_component_id | 422 exists | 41 | 41 | Automated |
| TC-N09 | Required/Dup/Range | BC-VAL-06 | Req | Exam required + duplicate + >100 | 422 each | — | 36 | Automated |
| TC-N10 | Exists | BC-INT-03 | Req | Exam invalid exam_type_id | 422 exists | — | 42 | Automated |
| TC-N11 | Required/Range | BC-VAL-07 | Req | IA required + display_order<1 | 422 | — | 37 | Automated |
| TC-N12 | Exists | BC-INT-04 | Req | IA invalid ia_component_type_id | 422 exists | — | 43 | Automated |
| TC-N13 | Required | BC-VAL-08 | Req | Coscholastic required (name/code) | 422 | — | 38 | Automated |
| TC-N14 | Duplicate | BC-EDG-03 | Req | Coscholastic duplicate code | 422 code | — | 39 | Automated |
| TC-N15 | Length | BC-EDG-04 | Req | Coscholastic code > 30 | 422 code | — | 75 | Automated |
| TC-N16 | 404 | BC-BIZ | Ctrl | Scholastic show invalid id | 404 | 90 | 74 | Automated |
| TC-N17 | Auth | BC-AUTH-04 | Route | Guest → /login | redirect | 50 | 50 | Automated |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 | B/F | BC-REF-01 | DDL | Config template CASCADE removes children | child gone | — | 44 | Automated |
| TC-D02 | C | BC-REF-02 | DDL | Source component RESTRICT blocks delete | blocked | — | 45 | Automated |
| TC-D03 | F | BC-BIZ-01 | Ctrl | Full delete/restore/forceDelete lifecycle | logs + gone | 83 | 91 | Automated |
| TC-D04 | E | BC-INT-03 | DDL | Exam type is cross-module (lms_exam_types) — defensive skip when absent | skipped/ok | 12 | 11/82 | Automated |

### Edge / Security (TC-S / TC-EDG)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-E01 | BC-EDG-01 | Req | Scholastic weightage 0 boundary | 200 | 70 | 70 | Automated |
| TC-E02 | BC-EDG-01 | Req | Scholastic weightage 100 boundary | 200 | — | 71 | Automated |
| TC-S01 | BC-EDG-05 | Sec | Coscholastic stored-XSS escaped in listing | no raw `<script>` | — | 73 | Automated |
| TC-S02 | BC-AUTH-03 | Audit | SEC-MSH-003 — all requests authorize()=true | asserted | 01 | 51 | Automated |
| TC-S03 | BC-AUTH-02 | Ctrl | Controller enforces create/update gate strings | present | — | 52 | Automated |

### Configuration / Defect proofs (TC-CFG)
| TC ID | BC | Source | Description | Expected (current behaviour) | V1 | V2 | Status |
|-------|----|--------|-------------|------------------------------|----|----|--------|
| TC-CFG01 | BC-CFG-01/02 | **BUG-MSH-C01** | Scholastic create ignores sum=100 | two 40% rows persist (sum 80) | 11 | 80 | Automated |
| TC-CFG02 | BC-CFG-03 | **BUG-MSH-C03** | Scholastic update breaking sum | HTTP 500 + rollback to 100 | 80 | 81 | Automated |
| TC-CFG03 | BC-CFG-04 | **BUG-MSH-C02** | Exam sum never enforced (create/update) | non-100 sum persists | — | 82 | Automated |
| TC-CFG04 | BC-CFG-04 | **BUG-MSH-C02** | validateExamWeightageSum has no caller | static assertion | — | 83 | Automated |
| TC-CFG05 | BC-CFG-06 | **BUG-MSH-C04** | Coscholastic arbitrary grading_scale accepted | 200 + persisted | — | 72 | Automated |

---

## 3. V2 Test Method Index (bands per WP-G)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_components_01_scholastic_schema_and_model_configuration | BC-DB-01/02/06 | Schema | 01-09 |
| 2 | test_components_02_exam_weightage_schema_and_unique_index | BC-DB-03 | Schema | 01-09 |
| 3 | test_components_03_ia_component_schema_and_unique_index | BC-DB-04 | Schema | 01-09 |
| 4 | test_components_04_coscholastic_schema_and_unique_index | BC-DB-05 | Schema | 01-09 |
| 5 | test_components_05_model_casts_are_correct | BC-DB-06 | Schema | 01-09 |
| 6 | test_components_06_request_rules_config_truth_and_sec_msh_003 | BC-VAL-*/AUTH-03 | Schema | 01-09 |
| 7 | test_components_10_create_scholastic_persists_and_logs_stored | TC-P01 | Business | 10-19 |
| 8 | test_components_11_create_exam_weightage_persists_and_logs_stored | TC-P02 | Business | 10-19 |
| 9 | test_components_12_create_ia_component_persists_and_logs_stored | TC-P03 | Business | 10-19 |
| 10 | test_components_13_create_coscholastic_persists_grading_and_logs_stored | TC-P04 | Business | 10-19 |
| 11 | test_components_14_scholastic_max_marks_nullable_is_accepted | TC-P05 | Business | 10-19 |
| 12 | test_components_15_coscholastic_defaults_ba_linked_false | TC-P06 | Business | 10-19 |
| 13 | test_components_30_scholastic_required_fields_rejected | TC-N01 | Validation | 30-39 |
| 14 | test_components_31_scholastic_weightage_over_100_rejected | TC-N02 | Validation | 30-39 |
| 15 | test_components_32_scholastic_negative_weightage_rejected | TC-N03 | Validation | 30-39 |
| 16 | test_components_33_scholastic_non_numeric_weightage_rejected | TC-N04 | Validation | 30-39 |
| 17 | test_components_34_scholastic_weightage_more_than_two_decimals_rejected | TC-N05 | Validation | 30-39 |
| 18 | test_components_35_scholastic_duplicate_component_rejected_with_message | TC-N06 | Validation | 30-39 |
| 19 | test_components_36_exam_weightage_required_duplicate_and_range | TC-N09 | Validation | 30-39 |
| 20 | test_components_37_ia_component_required_and_display_order_min | TC-N11 | Validation | 30-39 |
| 21 | test_components_38_coscholastic_required_fields_rejected | TC-N13 | Validation | 30-39 |
| 22 | test_components_39_coscholastic_duplicate_code_rejected | TC-N14 | Validation | 30-39 |
| 23 | test_components_40_scholastic_invalid_config_template_rejected | TC-N07 | Integration | 40-49 |
| 24 | test_components_41_scholastic_invalid_source_component_rejected | TC-N08 | Integration | 40-49 |
| 25 | test_components_42_exam_invalid_exam_type_rejected | TC-N10 | Integration | 40-49 |
| 26 | test_components_43_ia_invalid_component_type_rejected | TC-N12 | Integration | 40-49 |
| 27 | test_components_44_config_template_cascade_removes_children | TC-D01 | Integration | 40-49 |
| 28 | test_components_45_source_component_restrict_blocks_delete_while_referenced | TC-D02 | Integration | 40-49 |
| 29 | test_components_50_guest_redirected_to_login | TC-N17 | Auth | 50-59 |
| 30 | test_components_51_sec_msh_003_all_requests_authorize_true | TC-S02 | Auth | 50-59 |
| 31 | test_components_52_controller_enforces_gate_on_store | TC-S03 | Auth | 50-59 |
| 32 | test_components_60_page_renders_four_tabs | TC-P10 | UI | 60-69 |
| 33 | test_components_61_created_scholastic_row_is_listed | TC-P11 | UI | 60-69 |
| 34 | test_components_62_coscholastic_search_filter_matches_code | TC-P12 | UI | 60-69 |
| 35 | test_components_63_component_lists_use_independent_page_params | TC-P13 | UI | 60-69 |
| 36 | test_components_70_scholastic_zero_weightage_boundary_accepted | TC-E01 | Edge | 70-79 |
| 37 | test_components_71_scholastic_exactly_100_boundary_accepted | TC-E02 | Edge | 70-79 |
| 38 | test_components_72_coscholastic_arbitrary_grading_scale_accepted_defect | TC-CFG05 | Edge | 70-79 |
| 39 | test_components_73_coscholastic_xss_payload_is_escaped_in_listing | TC-S01 | Security | 70-79 |
| 40 | test_components_74_scholastic_show_invalid_id_returns_404 | TC-N16 | Edge | 70-79 |
| 41 | test_components_75_coscholastic_code_length_over_30_rejected | TC-N15 | Edge | 70-79 |
| 42 | test_components_80_scholastic_sum_not_validated_on_create_defect | TC-CFG01 | Config | 80-89 |
| 43 | test_components_81_scholastic_update_breaking_sum_returns_500_and_rolls_back | TC-CFG02 | Config | 80-89 |
| 44 | test_components_82_exam_weightage_sum_never_enforced_defect | TC-CFG03 | Config | 80-89 |
| 45 | test_components_83_exam_weightage_validator_has_no_caller_defect | TC-CFG04 | Config | 80-89 |
| 46 | test_components_84_scholastic_update_keeping_sum_logs_updated | TC-P07 | Config | 80-89 |
| 47 | test_components_90_scholastic_toggle_logs_toggled | TC-P08 | Lifecycle | 90-99 |
| 48 | test_components_91_scholastic_delete_restore_force_delete_lifecycle | TC-P09/TC-D03 | Lifecycle | 90-99 |
| 49 | test_components_92_exam_weightage_delete_logs_deleted | TC-P15 | Lifecycle | 90-99 |
| 50 | test_components_93_coscholastic_update_logs_updated | TC-P16 | Lifecycle | 90-99 |

## 4. Known Source Defects (candidates — verify in source)
| ID | Sev | Summary | Proving test |
|----|-----|---------|--------------|
| BUG-MSH-C01 | P2 | Scholastic weightage-sum (BR-MSG-002) not validated on **create** (controller store() bypasses service) | V2 80 / V1 11 |
| BUG-MSH-C02 | P2 | Exam weightage-sum (BR-MSG-003) never enforced — `validateExamWeightageSum` is dead code | V2 82, 83 |
| BUG-MSH-C03 | P3 | Sum violation on scholastic **update** surfaces as HTTP 500 (uncaught DomainException) not 422 | V2 81 / V1 80 |
| BUG-MSH-C04 | P3 | Co-scholastic `grading_scale` has no `in:` enum constraint | V2 72 |
| SEC-MSH-003 | P1 | All four FormRequests `authorize()` return `true` | V2 06, 51 / V1 01 |
| D39-MSH | P1 | Component permissions unseeded (environment prerequisite) | setUp grant + Validation Report |
| BR-MSH-050/009/012 | P2 | `precheck()` counts weightage rows but never sums them | Gap Analysis (traced) |
