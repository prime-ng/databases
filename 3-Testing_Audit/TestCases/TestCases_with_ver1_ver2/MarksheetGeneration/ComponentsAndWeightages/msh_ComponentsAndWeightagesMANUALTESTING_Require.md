# msh — Components & Weightages — Manual Testing Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | MarksheetGeneration (`MSH`, prefix `msh_`, **tenant_db**) |
| Screen / Feature | Components & Weightages (combined tabbed page) |
| URL | `GET /marksheet-generation/components` (name `marksheet-generation.components.combined`) |
| Page Controller | `MarksheetGenerationController::components()` — Gate `tenant.msh-components.view` |
| Entity Controllers | `TemplateScholasticComponentController`, `TemplateExamWeightageController`, `TemplateIaComponentController`, `TemplateCoscholasticComponentController` |
| Models | `TemplateScholasticComponent`, `TemplateExamWeightage`, `TemplateIaComponent`, `TemplateCoscholasticComponent` |
| Requests | `TemplateScholasticComponentRequest`, `TemplateExamWeightageRequest`, `TemplateIaComponentRequest`, `TemplateCoscholasticComponentRequest` |
| Services | `TemplateScholasticComponentService` (calls `MarksheetConfigService::validateScholasticWeightageSum`), `TemplateExamWeightageService`, `TemplateIaComponentService`, `TemplateCoscholasticComponentService`, `MarksheetConfigService` |
| Migrations | `tenant/2026_06_16_1157{39,36..}_create_msh_template_*` |
| CRUD Type | Modal + AJAX (`class="ajax-form"`); store/update return JSON on `expectsJson()`; toggle/trash/restore/forceDelete via `$modalEntities` loop |
| Soft Delete | Yes (all four) |
| Pagination | 15/page per tab (`sc_page`, `ew_page`, `ia_page`, `cc_page`) |
| Activity Log | `activityLog($model,$event,['message'=>...])`; events `Stored` / `Updated` / `Toggled` / `Deleted` / `Restored` |

### Environment prerequisites
- Module **enabled** in `prime_testing/modules_statuses.json` (disabled → 404 on all routes).
- `APP_ENV=testing` (bypasses CSRF/419).
- Admin permissions granted (D39-MSH: MSH permissions are **unseeded**; the suite grants them in `setUp`).
- Tenant seed data available: at least one academic session (`sch_org_academic_sessions_jnt`), and one `lms_exam_types` row for exam-weightage cases (else those tests skip).

---

## 2. Business Conditions (detail)

### Weightage-sum enforcement (BR-MSG-002 / BR-MSG-003) — **key trace**
Enforcement is asymmetric and largely absent:

```
Scholastic CREATE  →  TemplateScholasticComponentController::store()
                      └─ TemplateScholasticComponent::create()   ← DIRECT, no service
                         (weightage sum NOT checked)             ← BUG-MSH-C01

Scholastic UPDATE  →  TemplateScholasticComponentController::update()
                      └─ TemplateScholasticComponentService::update()
                         └─ MarksheetConfigService::validateScholasticWeightageSum()
                            (throws DomainException if sum ≠ 100)
                            └─ uncaught → HTTP 500, tx rollback        ← BUG-MSH-C03

Exam CREATE/UPDATE →  TemplateExamWeightageService::create/update()
                      (validateExamWeightageSum NEVER called)          ← BUG-MSH-C02

Schedule PRECHECK  →  MarksheetScheduleController::precheck()
                      'weightages' => $template->examWeightages->count()  ← counts only,
                      never sums (confirms BR-MSH-050/009/012)
```

### Activity-log flow
- Create → `activityLog($model,'Stored',...)`.
- Update → `activityLog($model,'Updated',...)` (after service update).
- Toggle → `activityLog($model,'Toggled',...)`.
- Delete + forceDelete → `activityLog($model,'Deleted',...)`.
- Restore → `activityLog($model,'Restored',...)`.
- `issued_by` (`user_id`) = the authenticated admin.

### Exact validation messages
- Scholastic duplicate: **`The source component id has already been taken.`** (custom closure).
- Other duplicates/exists/required use default Laravel messages (no `messages()` override in any of the four requests).

---

## 3. Test Cases (step-by-step)

### TC-P01 — Create scholastic component
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as admin; open `/marksheet-generation/components` | Page loads, `scholastic-components` tab present |
| 2 | POST `/marksheet-generation/template-scholastic-component` `{config_template_id, source_component_id, weightage_percent:100, max_marks:80, is_active:1}` (AJAX/JSON) | HTTP 200, JSON `{status:true, redirect}` |
| 3 | DB check | `SELECT * FROM msh_template_scholastic_components WHERE config_template_id=? AND source_component_id=?` → 1 row, `weightage_percent=100.00`, `created_by`=admin id |
| 4 | Activity check | `SELECT * FROM {activity log} WHERE subject_type='...TemplateScholasticComponent' AND subject_id=? AND event='Stored'` → 1 row, `user_id`=admin |

### TC-CFG01 — Scholastic sum NOT validated on create (BUG-MSH-C01)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a fresh config template + two source components | rows exist |
| 2 | POST scholastic `{template, sourceA, weightage_percent:40}` | HTTP 200 (accepted) |
| 3 | POST scholastic `{template, sourceB, weightage_percent:40}` | HTTP 200 (accepted) |
| 4 | DB check | `SELECT SUM(weightage_percent) ... WHERE config_template_id=?` → **80.00 (≠ 100)** — proving create does not enforce BR-MSG-002 |

### TC-CFG02 — Scholastic update breaking sum (BUG-MSH-C03)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed a single scholastic row `weightage_percent=100` | sum=100 |
| 2 | PUT `.../{id}` with `weightage_percent:55` | **HTTP 500** (uncaught `DomainException`), not 422 |
| 3 | DB check | row still `weightage_percent=100.00` (transaction rolled back) |

### TC-CFG03 / TC-CFG04 — Exam weightage sum never enforced (BUG-MSH-C02)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create two exam-weightage rows (30 + 30) on one template | both HTTP 200 |
| 2 | DB check | `SUM(weightage_percent) < 100` persists |
| 3 | Static check | `validateExamWeightageSum` string absent from `TemplateExamWeightageService.php` and `TemplateExamWeightageController.php` |

### TC-CFG05 — Coscholastic arbitrary grading_scale (BUG-MSH-C04)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST coscholastic `{grading_scale:'NONSENSE_SCALE', ...}` | HTTP 200 |
| 2 | DB check | `grading_scale='NONSENSE_SCALE'` persisted (no `in:` enum rule) |

### TC-N01 — Scholastic required fields
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST scholastic `{}` | HTTP 422; errors for `config_template_id`, `source_component_id`, `weightage_percent` |

### TC-N02..N05 — Scholastic weightage validation
| TC | Input | Expected |
|----|-------|----------|
| N02 | `weightage_percent:150` | 422, `weightage_percent` (max:100) |
| N03 | `weightage_percent:-5` | 422 (min:0) |
| N04 | `weightage_percent:'abc'` | 422 (numeric) |
| N05 | `weightage_percent:12.345` | 422 (regex 2 dp) |

### TC-N06 — Scholastic duplicate
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed scholastic (template, source) | row exists |
| 2 | POST same (template, source) | HTTP 422, body contains `The source component id has already been taken.` |
| 3 | DB check | still exactly 1 row |

### TC-N07 / TC-N08 — Scholastic FK exists
| TC | Input | Expected |
|----|-------|----------|
| N07 | `config_template_id:999999999` | 422 `config_template_id` (exists) |
| N08 | `source_component_id:999999999` | 422 `source_component_id` (exists) |

### TC-N09..N12 — Exam & IA validation
| TC | Action | Expected |
|----|--------|----------|
| N09 | Exam `{}` / duplicate exam_type / weightage 130 | 422 each |
| N10 | Exam `exam_type_id:999999999` | 422 (exists:lms_exam_types) |
| N11 | IA `{}` / `display_order:-1` | 422 |
| N12 | IA `ia_component_type_id:999999999` | 422 (exists) |

### TC-N13..N15 — Coscholastic validation
| TC | Action | Expected |
|----|--------|----------|
| N13 | Coscholastic `{}` | 422 for config_template_id, name, code |
| N14 | Duplicate code within template | 422 `code` |
| N15 | `code` length 31 | 422 `code` (max:30) |

### TC-D01 — Config template CASCADE
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed template + scholastic child | rows exist |
| 2 | Hard-delete the config template (`forceDelete`) | template gone |
| 3 | DB check | child scholastic row also gone (ON DELETE CASCADE) |

### TC-D02 — Source component RESTRICT
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed source component referenced by a scholastic row | row exists |
| 2 | Attempt `forceDelete()` on the source component | blocked (QueryException, FK RESTRICT) |

### TC-P08 — Toggle status
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed active scholastic row | is_active=1 |
| 2 | POST `.../{id}/toggleStatus` | HTTP 200 `{success:true}` |
| 3 | DB check | `is_active=0` |
| 4 | Activity check | event `Toggled`, user_id=admin |

### TC-P09 — Delete / Restore / Force delete lifecycle
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | DELETE `.../{id}` | soft-deleted; `deleted_at` set; activity `Deleted` |
| 2 | GET `.../{id}/restore` | `deleted_at` NULL; activity `Restored` |
| 3 | DELETE `.../{id}/force-delete` | row physically removed |

### TC-S01 — Stored XSS
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create coscholastic with `name = <script>alert('msh-xss')</script>...` | 200 |
| 2 | Reload coscholastic tab | listing must NOT contain a raw `<script>alert('msh-xss')</script>` (Blade escaping) |

### TC-N17 — Guest redirect
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Clear cookies, visit `/marksheet-generation/components` | redirected to `/login` |
