# Components & Weightages — Test Case List (TcList)

**Module:** MarksheetGeneration (`MSH`) · **Prefix:** `msh_` (verified vs DDL `CREATE TABLE msh_template_scholastic_components`)
**Screen:** Components & Weightages — combined tabbed page, 4 child entities of a `ConfigTemplate`
**Screen file:** `MarksheetGeneration_V2/03-Components-and-Weightages.md`
**Combined route:** `GET /marksheet-generation/components` → `marksheet-generation.components.combined` → `MarksheetGenerationController::components()`
**Primary table:** `msh_template_scholastic_components` (UNIQUE `uq_msh_tsc_template_component`)
**Test file:** `msh_ComponentsAndWeightages_TestCas.php` (browser Dusk, 51 methods) — ONE file, no V1/V2 split
**DB scope:** tenant-side (`msh_*`, no `tenant_id`) → tenancy scaffolding required

---

## 1. Business Conditions

### BC-DB (DDL)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `msh_template_scholastic_components`: `weightage_percent DECIMAL(5,2) NOT NULL`, `max_marks DECIMAL(8,2) NULL`, softDeletes | DDL-msh_template_scholastic_components |
| BC-DB-02 | UNIQUE `uq_msh_tsc_template_component` (`config_template_id`,`source_component_id`) | DDL-msh_template_scholastic_components |
| BC-DB-03 | `msh_template_exam_weightages`: UNIQUE `uq_msh_tew_template_exam` (`config_template_id`,`exam_type_id`) | DDL-msh_template_exam_weightages |
| BC-DB-04 | `msh_template_ia_components`: `max_marks DECIMAL(5,2) NOT NULL`, `display_order SMALLINT`, UNIQUE `uq_msh_tiac_template_type` | DDL-msh_template_ia_components |
| BC-DB-05 | `msh_template_coscholastic_components`: `code VARCHAR(30)`, `grading_scale VARCHAR(50) DEFAULT '3_POINT'`, `is_ba_linked TINYINT(1)`, UNIQUE `uq_msh_tcsc_template_code` | DDL-msh_template_coscholastic_components |
| BC-DB-06 | All 4 tables: FK `config_template_id` → `msh_config_templates` **ON DELETE CASCADE** | DDL |
| BC-DB-07 | `source_component_id` → `msh_source_components` **ON DELETE RESTRICT**; `exam_type_id`→`lms_exam_types` RESTRICT; `ia_component_type_id`→`msh_ia_component_types` RESTRICT | DDL |

### BC-VAL (FormRequests)
| ID | Rule + message | Source |
|----|----------------|--------|
| BC-VAL-01 | Scholastic: `config_template_id` required·integer·exists:msh_config_templates,id | ScholasticRequest |
| BC-VAL-02 | Scholastic: `source_component_id` required·exists:msh_source_components,id + closure duplicate → "The source component id has already been taken." | ScholasticRequest |
| BC-VAL-03 | Scholastic: `weightage_percent` required·numeric·min:0·max:100·regex 2dp | ScholasticRequest |
| BC-VAL-04 | Scholastic: `max_marks` nullable·numeric·min:0 | ScholasticRequest |
| BC-VAL-05 | Exam: `exam_type_id` exists:lms_exam_types,id + `Rule::unique(msh_template_exam_weightages,exam_type_id)` scoped; `weightage_percent` required·numeric·min:0·max:100 | ExamRequest |
| BC-VAL-06 | IA: `ia_component_type_id` exists + `Rule::unique(msh_template_ia_components,ia_component_type_id)`; `max_marks` required·numeric·min:0·regex 2dp; `display_order` integer·min:1 | IaRequest |
| BC-VAL-07 | Coscholastic: `code` required·max:30 + `Rule::unique(msh_template_coscholastic_components,code)`; `name` required·max:100; `display_order` required·integer·min:1 | CoscholasticRequest |
| BC-VAL-08 | Coscholastic: `grading_scale` `['sometimes','string','max:50']` — **no `in:` enum** (DEV-MSH-C04) | CoscholasticRequest |

### BC-AUTH (Gates + SEC)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Each entity controller enforces `Gate::authorize('tenant.msh-{entity}.{viewAny\|view\|create\|update\|delete}')` | Controllers |
| BC-AUTH-02 | **SEC-MSH-003:** all 4 FormRequests `authorize(){ return true; }` — no request-layer gating | Requests (Audit-SEC-MSH-003) |
| BC-AUTH-03 | Guest → combined page redirects to `/login` | Screen-PM |
| BC-AUTH-04 | **D39-MSH:** component permissions unseeded → env prerequisite (seeded defensively in tests) | Audit-D39-MSH |

### BC-BIZ (business logic / activity log)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | store/update/destroy/toggle/restore/forceDelete emit `activityLog()` events verbatim: `Stored`,`Updated`,`Deleted`,`Toggled`,`Restored` | Controllers |
| BC-BIZ-02 | `created_by`=auth id on store; JSON `{status,message,redirect}` on `expectsJson()`; toggle → `{success,is_active,message}` | Controllers |
| BC-BIZ-03 | **BR-MSH-050 / BR-MSH-009 / BR-MSH-012:** sum of `weightage_percent` (scholastic; and exam-type weightages) MUST = 100, but is **NOT validated at create** — `store()` bypasses the service; `validateExamWeightageSum()` is dead code | Screen-FR-01, DDL comment, Audit-BR-MSH-050 |
| BC-BIZ-04 | Scholastic **update** routes through the service which enforces the sum; violation surfaces as HTTP 500 (uncaught DomainException), rolls back — **DEV-MSH-C03** | Service + Controller |
| BC-BIZ-05 | Combined page paginates each tab independently (`sc_page`/`ew_page`/`ia_page`/`cc_page`), 15/page | MarksheetGenerationController::components() |

### BC-REF (FK onDelete)
| ID | FK → referenced → onDelete | Source |
|----|-----------|--------|
| BC-REF-01 | `config_template_id` → `msh_config_templates` → CASCADE (children removed with parent) | DDL |
| BC-REF-02 | `source_component_id` → `msh_source_components` → RESTRICT (delete blocked while referenced) | DDL |

### BC-EDG (edge / boundary)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `weightage_percent` boundaries 0 and 100 accepted; 150 / -5 / 'abc' / 12.345 rejected | DDL + Request |
| BC-EDG-02 | `code` length 31 rejected (max:30); XSS `<script>` in `name` escaped in listing | Request + Blade |
| BC-EDG-03 | Invalid record id on show → 404; valid id → 200 | Route-model binding |

> **BC-SM:** none. These entities have no status workflow beyond `is_active` toggle + soft-delete lifecycle (covered under BC-BIZ lifecycle, band 90-99). Documented as N/A.

---

## 2. Test Case List

### Positive (`TC-P`)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01..07 | DDL | Schema/model/migration/unique-index truth (4 tables) | All asserts pass | 01,02,03,04 | ✅ |
| TC-P02 | BC-DB casts | Models | Model casts decimal:2/bool/integer | Correct | 05 | ✅ |
| TC-P03 | BC-BIZ-01/02 | Controller | Create scholastic persists + logs Stored + created_by | 200, row, log | 10 | ✅ |
| TC-P04 | BC-BIZ-01 | Controller | Create exam weightage persists + Stored | 200, log | 11 | ✅ |
| TC-P05 | BC-BIZ-01 | Controller | Create IA persists (display_order,max_marks) + Stored | 200, log | 12 | ✅ |
| TC-P06 | BC-DB-05 | Controller | Create coscholastic persists grading_scale + is_ba_linked + Stored | 200, log | 13 | ✅ |
| TC-P07 | BC-VAL-04 | Request | Scholastic max_marks nullable accepted | 200, null | 14 | ✅ |
| TC-P08 | BC-DB-05 | Request | Coscholastic is_ba_linked defaults false | false | 15 | ✅ |
| TC-P09 | BC-BIZ-01 | Service | Scholastic update keeping sum → Updated | 200, log | 19 | ✅ |
| TC-P10 | BC-BIZ-05 | Controller | Page renders 4 tabs; created row listed; search by code | present | 60,61,62 | ✅ |
| TC-P11 | BC-BIZ-05 | Controller | Independent pagination page params present | sc/ew/ia/cc_page | 63 | ✅ |
| TC-P12 | BC-EDG-01 | Request | weightage 0 and 100 boundaries accepted | 200 | 70,71 | ✅ |
| TC-P13 | BC-EDG-03 | Route | Scholastic show valid id → 200 | 200 | 76 | ✅ |
| TC-P14 | BC-BIZ-01 | Controller | Toggle → Toggled; delete/restore/forceDelete lifecycle; exam delete; coscholastic update | events logged | 90,91,92,93 | ✅ |

### Negative (`TC-N`)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-VAL-01/02/03 | Request | Scholastic required fields | 422 | 30 | ✅ |
| TC-N02 | BC-VAL-03 | Request | Scholastic weightage > 100 | 422 | 31 | ✅ |
| TC-N03 | BC-VAL-03 | Request | Scholastic negative weightage | 422 | 32 | ✅ |
| TC-N04 | BC-VAL-03 | Request | Scholastic non-numeric weightage | 422 | 33 | ✅ |
| TC-N05 | BC-VAL-03 | Request | Scholastic > 2 decimals | 422 | 34 | ✅ |
| TC-N06 | BC-VAL-02 | Request | Scholastic duplicate (exact message) | 422 + message | 35 | ✅ |
| TC-N07 | BC-VAL-05 | Request | Exam required + duplicate + range>100 | 422 | 36 | ✅ |
| TC-N08 | BC-VAL-06 | Request | IA required + display_order min:1 | 422 | 37 | ✅ |
| TC-N09 | BC-VAL-07 | Request | Coscholastic required fields | 422 | 38 | ✅ |
| TC-N10 | BC-VAL-07 | Request | Coscholastic duplicate code | 422 | 39 | ✅ |
| TC-N11 | BC-VAL-01 | Request | Scholastic invalid config_template_id | 422 | 40 | ✅ |
| TC-N12 | BC-VAL-02 | Request | Scholastic invalid source_component_id | 422 | 41 | ✅ |
| TC-N13 | BC-VAL-05 | Request | Exam invalid exam_type_id | 422 | 42 | ✅ |
| TC-N14 | BC-VAL-06 | Request | IA invalid component_type_id | 422 | 43 | ✅ |
| TC-N15 | BC-EDG-02 | Request | Coscholastic code length 31 | 422 | 75 | ✅ |
| TC-N16 | BC-EDG-03 | Route | Scholastic show invalid id | 404 | 74 | ✅ |
| TC-N17 | BC-AUTH-03 | Route | Guest redirected to /login | /login | 50 | ✅ |
| TC-N18 | BC-EDG-02 | Blade | Stored XSS `<script>` escaped in listing | escaped | 73 | ✅ |

### Dependency (`TC-D`)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | B/C | BC-REF-01 | DDL | Config template hard-delete CASCADE removes children | child gone | 44 | ✅ |
| TC-D02 | C | BC-REF-02 | DDL | source_component RESTRICT blocks delete while referenced | blocked | 45 | ✅ |
| TC-D03 | F | BC-BIZ-01 | Controller | Full lifecycle create→delete→restore→forceDelete | ok | 91 | ✅ |

### Defect-proving (owned + discovered)
| TC ID | Defect | Source | Description | Expected (current) | Method | Status |
|-------|--------|--------|-------------|--------------------|--------|--------|
| TC-DEF01 | **BR-MSH-050/009/012** | Audit | Scholastic sum 40+40=80 accepted at create (store bypasses service) | 200×2, sum=80 | 16 | ✅ |
| TC-DEF02 | **BR-MSH-009/012** | Audit | Exam weightage sum never enforced (accepts non-100) | 200, sum<100 | 17 | ✅ |
| TC-DEF03 | **BR-MSH-009/012** | Audit | `validateExamWeightageSum()` has no caller (dead code, static) | not referenced | 18 | ✅ |
| TC-DEF04 | **SEC-MSH-003** | Audit | All 4 FormRequests authorize()=true | matches | 51 (+06) | ✅ |
| TC-DEF05 | **BC-AUTH-01** | Controllers | Controllers enforce gates (create/viewAny/delete strings) | present | 52 (+06) | ✅ |
| TC-DEF06 | DEV-MSH-C03 | Discovered | Scholastic update breaking sum → HTTP 500 + rollback | 500, rolled back | 80 | ✅ |
| TC-DEF07 | DEV-MSH-C04 | Discovered | Coscholastic arbitrary grading_scale accepted (no `in:`) | 200, persisted | 72 | ✅ |

---

## 3. Test Method Index

| # | Method (`test_components_NN_*`) | TC Map | Category | Band |
|---|--------------------------------|--------|----------|------|
| 1 | 01 scholastic migration/model/request config | TC-P01 | Schema | 01-09 |
| 2 | 02 exam schema+unique | TC-P01 | Schema | 01-09 |
| 3 | 03 ia schema+unique | TC-P01 | Schema | 01-09 |
| 4 | 04 coscholastic schema+unique | TC-P01 | Schema | 01-09 |
| 5 | 05 model casts | TC-P02 | Schema | 01-09 |
| 6 | 06 request rules + controller gates | TC-DEF04/05 | Config | 01-09 |
| 7 | 10 create scholastic + Stored | TC-P03 | BizRule | 10-19 |
| 8 | 11 create exam + Stored | TC-P04 | BizRule | 10-19 |
| 9 | 12 create ia + Stored | TC-P05 | BizRule | 10-19 |
| 10 | 13 create coscholastic + Stored | TC-P06 | BizRule | 10-19 |
| 11 | 14 scholastic max_marks nullable | TC-P07 | BizRule | 10-19 |
| 12 | 15 coscholastic ba_linked default | TC-P08 | BizRule | 10-19 |
| 13 | 16 scholastic sum not validated (create) | TC-DEF01 | BizRule/Defect | 10-19 |
| 14 | 17 exam sum never enforced | TC-DEF02 | BizRule/Defect | 10-19 |
| 15 | 18 exam sum validator dead code | TC-DEF03 | BizRule/Defect | 10-19 |
| 16 | 19 scholastic update keeps sum → Updated | TC-P09 | BizRule | 10-19 |
| 17-26 | 30-39 validation matrix | TC-N01..N10 | Validation | 30-39 |
| 27-32 | 40-45 FK/integration | TC-N11..N14, TC-D01/D02 | Integration | 40-49 |
| 33 | 50 guest redirect | TC-N17 | Authz | 50-59 |
| 34 | 51 SEC-MSH-003 | TC-DEF04 | Authz | 50-59 |
| 35 | 52 controller gates | TC-DEF05 | Authz | 50-59 |
| 36-39 | 60-63 render/list/search/pagination | TC-P10/P11 | UI/UX | 60-69 |
| 40-46 | 70-76 boundaries/xss/404/length/show/grading | TC-P12/P13, TC-N15/N16/N18, TC-DEF07 | Edge | 70-79 |
| 47 | 80 update sum → 500 | TC-DEF06 | Config/Defect | 80-89 |
| 48-51 | 90-93 toggle/lifecycle/delete/update | TC-P14, TC-D03 | Lifecycle | 90-99 |

**Totals:** 51 methods · Positive 14 TCs · Negative 18 TCs · Dependency 3 TCs · Defect-proving 7 TCs.
