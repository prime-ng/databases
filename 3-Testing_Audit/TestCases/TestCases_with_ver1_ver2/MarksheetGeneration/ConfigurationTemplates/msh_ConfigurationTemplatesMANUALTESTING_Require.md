# Configuration Templates — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | MarksheetGeneration (MSH) |
| Feature / Screen | Configuration Templates (`02-Configuration-Templates.md`) |
| Primary URL | `/marksheet-generation/configuration?tab=config-templates` (combined tabbed screen) |
| Create page | `/marksheet-generation/config-template/create` (full page — not a modal) |
| Store endpoint | `POST /marksheet-generation/config-template` (302 redirect; **no** JSON branch) |
| Update endpoint | `PUT /marksheet-generation/config-template/{config_template}` (302 redirect) |
| Toggle endpoint | `POST\|PATCH /marksheet-generation/config-template/{id}/toggleStatus` (JSON) |
| Trash / Restore / Force | `.../config-template/trash/view`, `.../{id}/restore` (GET), `.../{id}/force-delete` (DELETE) |
| Controller | `ConfigTemplateController` (+ `MarksheetGenerationController::configuration`) |
| Service | `ConfigTemplateService` (create/update/delete + `syncClassAssignments`) |
| Models | `ConfigTemplate` (`msh_config_templates`), `MarksheetType`, `ExamGroup`, `ClassGroup`, `IaComponentType`, `ClassAssignment` (`msh_class_config_jnt`) |
| Validation | `ConfigTemplateRequest` (default Laravel messages — no custom `messages()`) |
| DDL | `MarksheetGeneration_DDL_v1.sql` (tables 1,4,5,6,7,8) |
| CRUD type | Full-page create/edit + tabbed list; toggle via AJAX JSON |
| Soft delete | Yes (`SoftDeletes`, `deleted_at`) |
| Pagination | 15 / page (`ct_page`) |
| Activity log | `sys_activity_logs` — events `Stored`, `Updated`, `Toggled`, `Deleted`, `Restored`; issuer = `user_id` |
| Permissions | `tenant.msh-config-template.{viewAny\|view\|create\|update\|delete\|restore\|forceDelete}`; page gate `tenant.msh-configuration.view` |

**Environment prerequisites**
- `MarksheetGeneration` enabled in `prime_testing/modules_statuses.json` (else every route 404s).
- MSH permissions seeded/granted (D39-MSH — unseeded by default). Grant `tenant.msh-config-template.*` + `tenant.msh-configuration.view` to the test admin.
- Tenant seed data: ≥1 active academic session (`sch_org_academic_sessions_jnt`), ≥1 `msh_marksheet_types`, ≥1 `msh_exam_groups`. (Master rows can be created via their own tabs first.)
- `APP_ENV=testing` for automated Dusk runs (CSRF bypass).

---

## 2. Business Conditions (detailed)

**Create flow**
```
Create page → fill (session, code, name, marksheet type, exam group,
   [grading schema], passing %, comp. failures, [best-of-N], [class assignments])
 → POST config-template
 → ConfigTemplateRequest validation (422 on failure for JSON; redirect-back with errors for HTML)
 → Gate::authorize('tenant.msh-config-template.create')  (403 if denied)
 → ConfigTemplateService::create()  [DB transaction]
       ├─ created_by = auth()->id()     (spoofed created_by ignored)
       ├─ ConfigTemplate::create(...)
       └─ syncClassAssignments() → msh_class_config_jnt
 → activityLog(template, 'Stored')
 → redirect combined ?tab=config-templates  (flash success)
```

**Referential integrity**
```
Delete marksheet type / exam group / academic session referenced by a template → RESTRICT (blocked)
Delete grading schema referenced by a template                                 → SET NULL (grading_schema_id → NULL)
Force-delete template                                                          → CASCADE children (msh_class_config_jnt, msh_template_*)
Force-delete template referenced by a marksheet schedule                       → RESTRICT → SQL 23000
      → controller catches → "Cannot delete this record because it is referenced by other records. Remove those references first."
```

**Error messages** — default Laravel (no custom `messages()`): e.g. *“The code field is required.”*, *“The code has already been taken.”*, *“The name field must not be greater than 150 characters.”*, *“The passing percentage field must not be greater than 100.”*. Assert on the field key in the `errors` payload rather than exact prose where the framework wording may vary by version.

**Known defects to observe**
- **BUG-MSH-003** — `exam-group/{id}/edit` redirects to the configuration page (no edit form) and does **not** 404 for a bogus id (method has no model-binding param).
- **SEC-MSH-003** — the FormRequest never blocks (`authorize()=true`); only the controller Gate denies.
- **DEV-MSH-CT-01 (candidate)** — a locked template (`is_locked=1`) is still editable; BR-MSG-027 immutability is not enforced in code.

---

## 3. Test Cases (step / action / expected)

### TC-P02 — Create config template (happy path)

| # | Action | Expected |
|---|--------|----------|
| 1 | Log in as admin with `tenant.msh-config-template.create`; go to `/marksheet-generation/config-template/create` | "New Config Template" page renders with breadcrumb *Marksheet Generation → Configuration → Create* |
| 2 | Select Academic Session, Marksheet Type, Exam Group; type unique Code + Name; passing % = 33; comp. failures = 2 | Fields accept input |
| 3 | Submit "Create Config Template" | Redirect to `/marksheet-generation/configuration?tab=config-templates`; green success toast |
| 4 | DB check | `SELECT * FROM msh_config_templates WHERE code=? AND academic_session_id=?` → 1 row; `created_by = <admin id>`; `is_active=1` |
| 5 | Activity check | `SELECT event,user_id FROM sys_activity_logs WHERE subject_type LIKE '%ConfigTemplate' AND subject_id=? ORDER BY id DESC LIMIT 1` → `event='Stored'`, `user_id=<admin id>` |

### TC-P04 — Create with class assignment

| # | Action | Expected |
|---|--------|----------|
| 1 | On create page, add a class assignment (type=class, target_id=<active class>) | Assignment row added |
| 2 | Submit | Redirect to combined config-templates tab |
| 3 | DB check | `SELECT * FROM msh_class_config_jnt WHERE config_template_id=? AND class_id=? AND deleted_at IS NULL` → 1 row |

### TC-P05 — Update config template

| # | Action | Expected |
|---|--------|----------|
| 1 | Seed a template; issue `PUT /marksheet-generation/config-template/{id}` with a new name + comp. failures=3 | 302 redirect to combined tab |
| 2 | DB check | Row `name` updated, `compartment_max_failures=3`, `updated_by=<admin id>` |
| 3 | Activity check | latest `sys_activity_logs` event = `Updated`, issuer = admin |

### TC-P09 — Toggle status

| # | Action | Expected |
|---|--------|----------|
| 1 | On config-templates tab, toggle a template's status switch (POST `/config-template/{id}/toggleStatus`) | JSON `{success:true, is_active:false, message:"Status set to Inactive"}` |
| 2 | DB check | `is_active=0` |
| 3 | Activity check | latest event = `Toggled` |

### TC-P10 / TC-P11 — Soft delete then restore

| # | Action | Expected |
|---|--------|----------|
| 1 | Delete a template (DELETE `/config-template/{id}`) | Redirect + success flash; `deleted_at` set; activity `Deleted` |
| 2 | Open trash `/config-template/trash/view`; click Restore (GET `/config-template/{id}/restore`) | Redirect to trash; `deleted_at` NULL; `is_active=1`; activity `Restored` |

### TC-N01 — Required fields

| # | Action | Expected |
|---|--------|----------|
| 1 | POST `/config-template` (Accept: application/json) with empty body | HTTP 422; `errors` include `code`, `name`, `academic_session_id`, `marksheet_type_id`, `exam_group_id` |
| 2 | DB check | No new row |

### TC-N06 — passing_percentage range

| # | Action | Expected |
|---|--------|----------|
| 1 | POST valid payload but `passing_percentage=150` | 422; `errors.passing_percentage` present (max:100) |
| 2 | Repeat with `passing_percentage=-5` | 422; min:0 |

### TC-N09 / TC-N10 — Uniqueness scope

| # | Action | Expected |
|---|--------|----------|
| 1 | Seed template (session S1, code X); POST another with (S1, X) | 422; `errors.code` (“already been taken”); no second row |
| 2 | POST (session S2, code X) with an exam group belonging to S2 | Created — unique is **per session** (`uq_msh_ct_session_code`) |

### TC-N11..N14 — `exists` rules

| # | Action | Expected |
|---|--------|----------|
| 1 | POST with `marksheet_type_id=999999999` | 422 `errors.marksheet_type_id` |
| 2 | POST with `exam_group_id=999999999` | 422 `errors.exam_group_id` |
| 3 | POST with `academic_session_id=999999999` | 422 `errors.academic_session_id` |
| 4 | POST with `grading_schema_id=999999999` | 422 `errors.grading_schema_id` |

### TC-N15..N17 — Authorization

| # | Action | Expected |
|---|--------|----------|
| 1 | Visit create page as guest | Redirect to `/login` |
| 2 | As a user WITHOUT `tenant.msh-config-template.create`, POST a **valid** payload | 403 (controller Gate; FormRequest doesn’t block — SEC-MSH-003) |
| 3 | As a user WITHOUT `...delete`, DELETE a template | 403 |

### TC-D01 / TC-D02 — FK RESTRICT

| # | Action | Expected |
|---|--------|----------|
| 1 | Create template referencing marksheet type T and exam group G | Row created |
| 2 | Attempt to force-delete T (and G) | SQL error / blocked; T and G still exist |

### TC-D03 — CASCADE children

| # | Action | Expected |
|---|--------|----------|
| 1 | Create template + a `msh_class_config_jnt` row | Junction row exists |
| 2 | Force-delete the template | `SELECT COUNT(*) FROM msh_class_config_jnt WHERE config_template_id=?` → 0 (cascaded) |

### TC-D04 — Schedule reference blocks force delete

| # | Action | Expected |
|---|--------|----------|
| 1 | Create template + a `msh_marksheet_schedules` row referencing it | Schedule exists |
| 2 | Soft-delete then force-delete the template | 23000 blocked; controller returns *“Cannot delete this record because it is referenced by other records.”* |

### TC-D06 — BUG-MSH-003 (ExamGroup edit)

| # | Action | Expected |
|---|--------|----------|
| 1 | GET `/marksheet-generation/exam-group/999999999/edit` | Redirect (302→200) to configuration page — **no** edit form, **no** 404 (method lacks model binding) |

### TC-D08 — DEV-MSH-CT-01 candidate (is_locked not enforced)

| # | Action | Expected (current behaviour) |
|---|--------|------------------------------|
| 1 | Seed template with `is_locked=1` | Row locked |
| 2 | PUT an update changing `name` | Update **succeeds** (no guard) — documents the gap vs BR-MSG-027 (verify in source) |

### TC-T01 / TC-T02 — Tenancy

| # | Action | Expected |
|---|--------|----------|
| 1 | Inspect schema in tenant context | `msh_config_templates` present; **no** `tenant_id` column (database-per-tenant) |
| 2 | GET `/config-template/999999999` | 404 (bound-model miss; no cross-record leak) |
