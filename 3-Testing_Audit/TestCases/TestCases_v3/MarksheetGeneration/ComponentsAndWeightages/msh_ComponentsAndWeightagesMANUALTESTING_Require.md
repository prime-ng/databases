# Components & Weightages — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | MarksheetGeneration (`MSH`) |
| Feature / Screen | Components & Weightages (combined tabbed page, 4 child entities) |
| Screen file | `MarksheetGeneration_V2/03-Components-and-Weightages.md` |
| Combined URL | `GET /marksheet-generation/components` (`marksheet-generation.components.combined`) |
| Combined controller | `MarksheetGenerationController::components()` |
| Entity controllers | `TemplateScholasticComponentController`, `TemplateExamWeightageController`, `TemplateIaComponentController`, `TemplateCoscholasticComponentController` |
| Requests | `TemplateScholasticComponentRequest`, `TemplateExamWeightageRequest`, `TemplateIaComponentRequest`, `TemplateCoscholasticComponentRequest` |
| Services | `TemplateScholasticComponentService`, `TemplateExamWeightageService`, `TemplateIaComponentService`, `TemplateCoscholasticComponentService`, `MarksheetConfigService` |
| Models / tables | `TemplateScholasticComponent`→`msh_template_scholastic_components`; `TemplateExamWeightage`→`msh_template_exam_weightages`; `TemplateIaComponent`→`msh_template_ia_components`; `TemplateCoscholasticComponent`→`msh_template_coscholastic_components` |
| CRUD type | Modal + AJAX on a combined tabbed page; JSON on `expectsJson()`; modal-entity edit() redirects to combined page |
| Soft delete | Yes (all 4) | Pagination | 15/page per tab (`sc_page`/`ew_page`/`ia_page`/`cc_page`) |
| Activity log | `Modules\GlobalMaster\Models\ActivityLog`; events `Stored`/`Updated`/`Deleted`/`Toggled`/`Restored` |
| Permissions | `tenant.msh-{entity}.{viewAny\|view\|create\|update\|delete\|restore\|forceDelete}` |
| DB scope | Tenant-side (`msh_*`) → tenant context required |

**Environment prerequisites:** `MarksheetGeneration: true` in `prime_testing/modules_statuses.json`; `APP_ENV=testing`; a tenant domain resolvable from `DUSK_TENANT_URL`; **D39-MSH** component permissions are unseeded, so a component-admin role/permissions must be granted (the automated suite seeds them defensively).

---

## 2. Business Conditions (detailed)

### Weightage-sum rule (owned defect — BR-MSH-050 / BR-MSH-009 / BR-MSH-012)
> **Intended:** the sum of `weightage_percent` across a template's scholastic components (and across its exam-type weightages) must equal **100** — the DDL states "Sum of weightage_percent must = 100."
>
> **Actual:**
> - **Scholastic create** — `store()` calls `TemplateScholasticComponent::create()` directly and never invokes `MarksheetConfigService::validateScholasticWeightageSum()`. Two rows of 40% (sum 80) are both accepted.
> - **Scholastic update** — routes through `TemplateScholasticComponentService::update()` which DOES call the sum validator; a break throws `DomainException`, surfacing as **HTTP 500** (not 422) and rolling the transaction back → **DEV-MSH-C03**.
> - **Exam weightages** — `validateExamWeightageSum()` exists on `MarksheetConfigService` but has **no caller** (dead code); exam sums are never enforced at create or update.
>
> Flow (scholastic create — current):
> ```
> POST /template-scholastic-component  →  Gate::authorize(create)  →  Request::validated()  →
>   TemplateScholasticComponent::create()  →  activityLog(Stored)  →  200
>   (validateScholasticWeightageSum NEVER called)
> ```

### SEC-MSH-003
All four FormRequests define `public function authorize(): bool { return true; }`. Authorization is enforced **only** in the controllers via `Gate::authorize('tenant.msh-{entity}.{ability}')`.

### DEV-MSH-C04
`grading_scale` validation is `['sometimes','string','max:50']` — there is no `in:3_POINT,5_POINT` rule, so an out-of-spec value (e.g. `NONSENSE_SCALE`) is accepted and persisted.

---

## 3. Manual Test Cases

### TC-P03 — Create scholastic component (happy path)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log in as tenant admin; open `/marksheet-generation/components` | Scholastic tab renders |
| 2 | Open the scholastic "Add" modal; select a Config Template + Source Component; weightage 100; max_marks 80; Active | Modal validates client-side |
| 3 | Submit | Green success toast; row appears in the list |
| 4 | DB check | `SELECT * FROM msh_template_scholastic_components WHERE config_template_id=? AND source_component_id=?` → 1 row, `weightage_percent=100.00`, `created_by`=admin id |
| 5 | Activity-log check | `SELECT * FROM {activity table} WHERE subject_type='...TemplateScholasticComponent' AND event='Stored'` → 1 row, `user_id`=admin |

### TC-DEF01 — Scholastic weightage sum NOT validated at create (BR-MSH-050)
| Step | Action | Expected (current, defect) |
|------|--------|----------------------------|
| 1 | On a fresh template, add scholastic component A with weightage 40 | 200 OK, row saved |
| 2 | Add component B with weightage 40 (sum now 80 ≠ 100) | **200 OK, row saved** (no sum error) |
| 3 | DB check | `SELECT SUM(weightage_percent) ... WHERE config_template_id=?` → **80.00** persisted |
| — | Expected-if-fixed | Step 2 should return 422 with a "must sum to 100" error |

### TC-DEF02 / TC-DEF03 — Exam weightage sum never enforced
| Step | Action | Expected (current, defect) |
|------|--------|----------------------------|
| 1 | Add exam weightage (exam type A) 30 | 200 OK |
| 2 | Add exam weightage (exam type B) 30 (sum 60) | **200 OK** |
| 3 | DB check | `SUM(weightage_percent)` = 60 (< 100) persisted |
| 4 | Static check | `validateExamWeightageSum` appears in `MarksheetConfigService` but in neither `TemplateExamWeightageService` nor `TemplateExamWeightageController` |

### TC-DEF06 — Scholastic update breaking the sum (DEV-MSH-C03)
| Step | Action | Expected (current) |
|------|--------|--------------------|
| 1 | Seed one scholastic row with weightage 100 (sum=100) | row exists |
| 2 | PUT the row to weightage 55 (sum would be 55) | **HTTP 500** (uncaught DomainException) |
| 3 | DB check | Row still `weightage_percent=100.00` (transaction rolled back) |

### TC-DEF07 — Coscholastic arbitrary grading_scale (DEV-MSH-C04)
| Step | Action | Expected (current) |
|------|--------|--------------------|
| 1 | Create coscholastic with `grading_scale='NONSENSE_SCALE'` | 200 OK |
| 2 | DB check | Row persisted with `grading_scale='NONSENSE_SCALE'` |

### TC-N06 — Scholastic duplicate component
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed a scholastic row for (template T, source S) | exists |
| 2 | POST another row for (T, S) | 422; body contains **"The source component id has already been taken."** |
| 3 | DB check | Still exactly 1 row for (T, S) |

### TC-N02..N05 — Scholastic weightage validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST weightage 150 | 422 (`weightage_percent`) |
| 2 | POST weightage -5 | 422 (min:0) |
| 3 | POST weightage 'abc' | 422 (numeric) |
| 4 | POST weightage 12.345 | 422 (regex 2dp) |

### TC-N17 — Guest access
| Step | Action | Expected |
|------|--------|----------|
| 1 | Clear cookies; visit `/marksheet-generation/components` | Redirect to `/login` |

### TC-D01 — Config template CASCADE
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed template + scholastic child | both exist |
| 2 | Hard-delete the config template | child row also removed (FK ON DELETE CASCADE) |

### TC-D02 — Source component RESTRICT
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed scholastic row referencing source S | exists |
| 2 | Attempt to hard-delete source S | blocked by FK (QueryException) |

### TC-P14 — Toggle / lifecycle / activity log
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/template-scholastic-component/{id}/toggleStatus` | 200 `{success:true}`; `is_active` flips; event `Toggled` logged |
| 2 | DELETE `/template-scholastic-component/{id}` | soft-deleted; event `Deleted` |
| 3 | GET `/template-scholastic-component/{id}/restore` | `deleted_at` cleared; event `Restored` |
| 4 | DELETE `/template-scholastic-component/{id}/force-delete` | row gone permanently |

### TC-P10/P11 — Combined page UI
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open combined page | 4 tab panes: `scholastic-components`, `exam-weightages`, `ia-components`, `coscholastic-components` |
| 2 | Search coscholastic by code | matching row shown |
| 3 | Inspect pagination | independent params `sc_page`/`ew_page`/`ia_page`/`cc_page` |
