# Configuration Templates — Manual Test Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | MarksheetGeneration (MSH) |
| Feature / Screen | Configuration Templates (composite Configuration page) |
| Primary URL | `GET /marksheet-generation/configuration?tab=config-templates` |
| Create URL | `GET /marksheet-generation/config-template/create` (full page) |
| Store / Update / Delete | `POST /marksheet-generation/config-template` · `PUT /marksheet-generation/config-template/{id}` · `DELETE /marksheet-generation/config-template/{id}` (all **redirect**) |
| Toggle | `POST /marksheet-generation/config-template/{id}/toggleStatus` (**JSON**) |
| Restore / Force delete | `GET .../{id}/restore` · `DELETE .../{id}/force-delete` |
| Controllers | `ConfigTemplateController` (primary); masters: `MarksheetTypeController`, `ClassGroupController`, `ExamGroupController`, `IaComponentTypeController`; page: `MarksheetGenerationController::configuration` |
| Service | `ConfigTemplateService` (create/update/delete + class-assignment sync) |
| Models | `ConfigTemplate` (`msh_config_templates`); masters `MarksheetType`, `ClassGroup`, `ExamGroup`, `IaComponentType` |
| Validation | `ConfigTemplateRequest` (+ 4 master FormRequests) — all `authorize()=true` (SEC-MSH-003) |
| Primary table | `msh_config_templates` (tenant_db, prefix `msh_`) |
| CRUD type | Full-page create/edit + AJAX toggle; combined tabbed page |
| Soft delete | Yes (`deleted_at`, `SoftDeletes`) |
| Pagination | 20/page (`index`), 15/page (`trashed`) |
| Activity log | `sys_activity_logs` (`ActivityLog`), events `Stored` / `Updated` / `Toggled` / `Deleted` / `Restored`, issuer `user_id` |
| Permissions | `tenant.msh-config-template.*`; page gate `tenant.msh-configuration.view` |

**Environment prerequisites:** `MarksheetGeneration: true` in `prime_testing/modules_statuses.json`; `APP_ENV=testing`; `tenant.msh-*` permissions granted (D39-MSH — unseeded by default); at least one active `sch_org_academic_sessions_jnt` row.

---

## 2. Business Conditions (detailed)

**Create flow:** `ConfigTemplateController::store` → `Gate::authorize('tenant.msh-config-template.create')` → validated by `ConfigTemplateRequest` → `ConfigTemplateService::create($data, auth()->id())` (forces `created_by`, syncs `class_assignments` into `msh_class_config_jnt`) → `activityLog($configTemplate, 'Stored')` → **redirect** to `configuration?tab=config-templates` with success flash.

**Update flow:** identical, gate `update`, `activityLog(..., 'Updated')`. No `is_locked` guard (DEV-MSH-CT-01 candidate).

**Toggle flow:** `toggleStatus($id)` → gate `update` → flips `is_active`, sets `updated_by` → `activityLog(..., 'Toggled')` → **JSON** `{success:true, is_active, message}`.

**Delete / restore / force-delete:** soft delete + `Deleted`; restore re-activates + `Restored`; force-delete catches SQL `23000` → error flash "Cannot delete this record because it is referenced by other records. Remove those references first."

**Uniqueness:** `code` unique **per academic session** (`uq_msh_ct_session_code`).

**FK behaviour:** session/type/exam_group = RESTRICT; grading_schema = SET NULL; children (`msh_class_config_jnt`, `msh_template_*`) = CASCADE; referencing `msh_marksheet_schedules` = RESTRICT.

---

## 3. Test Cases (Step / Action / Expected)

### TC-P03 — Create config template persists + Stored activity  (auto: `test_..._10`)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as MSH admin; open `/marksheet-generation/configuration` | Configuration page loads (200), config-templates tab present |
| 2 | POST to `/marksheet-generation/config-template` with valid session/type/exam-group + unique code/name, passing_percentage=33 | Response 302→200 (redirect to combined page) |
| 3 | DB: `SELECT * FROM msh_config_templates WHERE code=? AND academic_session_id=?` | 1 row; `name` matches; `created_by` = admin id |
| 4 | DB: `SELECT * FROM sys_activity_logs WHERE subject_type='...ConfigTemplate' AND subject_id=? AND event='Stored'` | 1 row; `user_id` = admin id |

### TC-P07 — passing_percentage DB default 33.00  (auto: `test_..._14`)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Insert a row via raw DB without `passing_percentage` | Insert succeeds |
| 2 | `SELECT passing_percentage FROM msh_config_templates WHERE id=?` | Value = `33.00` |

### TC-P14 — Toggle status  (auto: `test_..._22`)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed an active template | `is_active=1` |
| 2 | POST `/marksheet-generation/config-template/{id}/toggleStatus` | JSON `{success:true,is_active:false,...}` (200) |
| 3 | DB re-read | `is_active=0` |
| 4 | Activity log | `event='Toggled'` by admin |

### TC-P15 — Master (marksheet-type) create + toggle  (auto: `test_..._25`)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a `MarksheetType` (active) | Row present |
| 2 | POST `/marksheet-generation/marksheet-type/{id}/toggleStatus` | JSON `{success:true}` (200) |
| 3 | DB re-read + activity | `is_active=0`; `Toggled` log for `MarksheetType` by admin |

### TC-N01 — Required fields rejected  (auto: `test_..._30`)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST empty payload | 422 |
| 2 | Inspect `errors` | Keys `code`, `name`, `academic_session_id`, `marksheet_type_id`, `exam_group_id` present |

### TC-N09 — Duplicate code same session rejected  (auto: `test_..._38`)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed a template with code X in session S | Row present |
| 2 | POST valid payload reusing code X + session S | 422 with `code` error |
| 3 | DB count of (S, X) | Still 1 (no insert) |

### TC-N19 — All master FormRequests self-authorize (SEC-MSH-003)  (auto: `test_..._55`)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Instantiate each of the 5 FormRequests | `authorize()` returns `true` for every one |
| 2 | Confirm | Authorization is enforced only by controller `Gate::authorize()` — the request layer never gates |

### TC-D01 — Referenced marksheet type delete blocked (RESTRICT)  (auto: `test_..._44`)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed template referencing marksheet type T | Row present |
| 2 | Force-delete T at DB/model level | Throws (FK RESTRICT `fk_msh_ct_type`) |
| 3 | Re-read T | Still exists |

### TC-D04 — Force-delete blocked when referenced by schedule (23000)  (auto: `test_..._47`)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed template + a `msh_marksheet_schedules` row referencing it | Rows present |
| 2 | Soft-delete then force-delete the template | Throws SQL 23000 (RESTRICT `fk_msh_ms_template`); controller path returns friendly error flash |

### TC-D06 — BUG-MSH-003: exam-group edit redirects without model binding  (auto: `test_..._56`)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/marksheet-generation/exam-group/999999999/edit` | 302 → 200 (combined page), **not** 404 — `edit()` takes no `ExamGroup` param so there is no route-model binding / no edit form |

### TC-D08 — Locked template still mutable (DEV-MSH-CT-01)  (auto: `test_..._21`)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed template with `is_locked=1` | Row present |
| 2 | PUT an updated name | Update succeeds (current code has no immutability guard) — documents the gap |

### TC-T02 / TC-N21 — Non-existent id 404  (auto: `test_..._91`)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/marksheet-generation/config-template/999999999` | 404 (route-model binding); no cross-record leak |

> Remaining TC-P/N/D cases (length/range validations, null grading, best-of-N, board_code, restore, cascade, XSS escape, mass-assignment guard, guest redirect, permission 403, tenancy scoping) follow the same Step/Action/Expected shape and are automated 1:1 — see the Gap Analysis mapping.
