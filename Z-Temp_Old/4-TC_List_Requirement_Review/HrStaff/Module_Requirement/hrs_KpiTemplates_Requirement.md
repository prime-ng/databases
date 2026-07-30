# KPI Templates — Business Requirements

## What This Screen Does

KPI Templates let HR define reusable performance evaluation frameworks. Each template contains a set of Key Performance Indicator items grouped by category — academic, behavioral, or administrative — with percentage weights that must sum to exactly 100. The template also sets the rating scale (5-point or 10-point) and determines which staff category it applies to (all, teaching, or non-teaching).

Once created, templates are assigned to appraisal cycles. The system snapshots the template at cycle creation time; changes to a template after cycles have started do not retroactively alter existing appraisals.

---

## When This Screen Is Used

- HR Policy Setup when the school designs its annual appraisal framework before the academic year begins
- Template Revision when the school updates KPI criteria mid-year and wants new cycles to use the revised version
- Role-Based Evaluation when HR needs separate templates for teaching versus non-teaching staff

---

## Default Data Load

The KPI Templates tab loads via `HrMenuController@appraisalsIncrements()` (GET `/appraisals-overview?tab=kpi-templates`). A standalone index page also exists at `GET /kpi-templates` via `AppraisalController@kpiIndex()`. Both load all active `KpiTemplate` records with their `items` relationship, ordered by name, with no pagination. Shared dropdowns (academic sessions, departments, employees) are loaded by the `HrMenuController` for the combined page.

---

## Key Fields at a Glance

**Template Identity**
The Template Name uniquely identifies the KPI framework, such as "Teaching KPI 2025-26" or "Admin Staff Evaluation". The Applicable To field restricts the template to all, teaching-only, or non-teaching-only staff categories.

**Rating Configuration**
The Rating Scale selects either a 5-point (1=Poor to 5=Excellent) or 10-point scale. All items in the template share the same scale. The weighted overall rating is computed as the sum of each item's rating multiplied by its weight percentage, divided by total weight.

**KPI Items**
Each item has a KPI Name (e.g., "Lesson Plan Quality", "Student Engagement"), a Category (academic, behavioral, administrative), a Weight percentage, and an optional Description explaining what the KPI measures. The sum of all item weights in a template must equal exactly 100.00.

---

## Business Rules and Conditions

**Weight Sum Constraint**
When saving or updating a template, the sum of all item weights must equal exactly 100.00. The system enforces this at the application layer via form request validation rules.

**Item Update Behavior**
When an existing template is updated and items are provided, the system marks existing items as `is_active = false` and then creates or updates items by matching on `(template_id, kpi_name)`. Items not included in the update payload are preserved unchanged.

**Delete Protection**
A KPI template cannot be soft-deleted if it is referenced by any appraisal cycle. The system checks `appraisalCycles()->exists()` before allowing deletion and returns an error message if cycles exist.

---

## Workflow Steps

**Creating a KPI Template**
HR navigates to Appraisals → KPI Templates, clicks Add Template, enters "Teacher Evaluation 2025-26", selects "Teaching" as applicable-to, picks the 5-point rating scale, and adds KPI items: "Classroom Management" (academic, 40%), "Student Feedback" (behavioral, 35%), "Administrative Compliance" (administrative, 25%). The weight indicator shows 100% reached. HR saves, and the system creates the template with all items.

---

## Example Scenario

A school conducts annual appraisals for both teaching and non-teaching staff. HR creates two templates: "Teaching KPI 2025-26" (5-point scale, applicable to teaching, items: Student Performance 40%, Lesson Quality 30%, Punctuality 15%, Collaboration 15%) and "Admin KPI 2025-26" (10-point scale, applicable to non-teaching, items: Process Adherence 50%, Timeliness 30%, Teamwork 20%). Each template item weight sums to 100. The teaching template is then assigned to the annual appraisal cycle for all teaching faculty.

---

## Related Screens

- **Appraisal Cycles** — Assigns KPI templates to time-bound review periods
- **Appraisals** — Uses the template items as the rating criteria for each employee

---

## Requirements

- `AppraisalController@kpiIndex()` lists all active KPI templates with their items, ordered by name, gated by `hrs.appraisal.manage`.
- `AppraisalController@kpiStore()` validates via `StoreKpiTemplateRequest`, creates the `KpiTemplate` record, loops through `items` array to create `KpiTemplateItem` records, sets `created_by`/`updated_by` to `auth()->id()`, logs activity via `activityLog()`, and redirects to tab with success flash message.
- `AppraisalController@kpiShow()` loads a single template with items relationship, gated by `hrs.appraisal.manage`.
- `AppraisalController@kpiEdit()` loads a single template with items for inline editing, gated by `hrs.appraisal.manage`.
- `AppraisalController@kpiUpdate()` validates via `StoreKpiTemplateRequest`, updates the template, and if items are provided in the request, marks existing items `is_active = false` then uses `updateOrCreate()` on `(template_id, kpi_name)` for each new item entry.
- `AppraisalController@kpiToggleStatus()` flips `is_active` boolean via AJAX POST, gated by `hrs.appraisal.manage`, returns JSON `{success, is_active, message}`.
- `AppraisalController@kpiDestroy()` checks `appraisalCycles()->exists()` — if true, returns back with error "Cannot delete KPI template used in appraisal cycles."; otherwise sets `is_active=false`, soft-deletes, logs activity, redirects with "KPI template removed.".
- `AppraisalController@kpiTrashed()` lists only trashed templates with pagination (15/page), gated by `hrs.appraisal.manage`.
- `AppraisalController@kpiRestore()` restores from soft-delete, sets `is_active=true`, logs activity, redirects to trash view.
- `AppraisalController@kpiForceDelete()` permanently deletes using `forceDelete()`, logs activity, redirects to trash view.
- `StoreKpiTemplateRequest::authorize()` checks `Gate::allows('hrs.appraisal.manage')`.
- `StoreKpiTemplateRequest::rules()`: `name` required|string|max:200, `applicable_to` required|in:all,teaching,non_teaching, `rating_scale` required|integer|in:5,10, `is_active` required|boolean, `items` sometimes|array|min:1, `items.*.kpi_name` required_with:items|string|max:200, `items.*.category` required_with:items|in:academic,behavioral,administrative, `items.*.weight` required_with:items|numeric|min:0|max:100, `items.*.description` nullable|string|max:500.
- `StoreKpiTemplateRequest::prepareForValidation()` merges `is_active` as boolean with default `true`.
- `KpiTemplate` model uses `SoftDeletes`, table `hrs_kpi_templates`, `$casts` rating_scale=>integer, is_active=>boolean.
- `KpiTemplateItem` model uses `SoftDeletes`, table `hrs_kpi_template_items`, `$casts` weight=>decimal:2, is_active=>boolean.
- `KpiTemplatePolicy` defines viewAny/view/create/update/delete/restore/forceDelete all gated by `hrs.kpi_template.manage`.
- Routes: `GET/POST /kpi-templates`, `GET/PUT /kpi-templates/{kpiTemplate}`, `GET /kpi-templates/{kpiTemplate}/edit`, `GET /kpi-templates/{kpiTemplate}` (show), `DELETE /kpi-templates/{kpiTemplate}`, `POST /kpi-templates/{kpiTemplate}/toggle-status`, `GET /kpi-templates/trash/view`, `GET /kpi-templates/{id}/restore`, `DELETE /kpi-templates/{id}/force-delete`.

---

## Who Can Access

| Gate/Permission | Methods | Notes |
|---|---|---|
| `hrs.appraisal.manage` | `kpiIndex`, `kpiStore`, `kpiShow`, `kpiEdit`, `kpiUpdate`, `kpiToggleStatus`, `kpiDestroy`, `kpiTrashed`, `kpiRestore`, `kpiForceDelete` | HR role — all KPI operations require this permission |
| Guest | — | No access — redirected to /login |

`KpiTemplatePolicy` defines all methods gated by `hrs.kpi_template.manage` but the controller uses `Gate::authorize('hrs.appraisal.manage')` directly.

---

## Logic Flow

1. **Page Load**: `kpiIndex()` gates via `hrs.appraisal.manage`, fetches `KpiTemplate::active()->with('items')->orderBy('name')->get()`, returns view with templates collection.
2. **Create**: `kpiStore()` validates via `StoreKpiTemplateRequest`. Extracts `items` array from validated data and removes it from template data. Sets `created_by`/`updated_by` to auth ID. Creates `KpiTemplate` record. Iterates items, sets `template_id`, `is_active=true`, `created_by`/`updated_by`, creates each `KpiTemplateItem`. Logs activity. Redirects to appraisals tab with success flash.
3. **Edit/Update**: `kpiEdit()` loads template with items. `kpiUpdate()` validates via request. If `items` key is present in validated data: marks all existing items `is_active=false`, then for each new item uses `updateOrCreate(['template_id','kpi_name'], [...])` to create or update. Updates template fields. Logs activity. Redirects.
4. **Toggle Status**: `kpiToggleStatus()` toggles `is_active` on the model, saves, returns JSON response.
5. **Delete**: `kpiDestroy()` checks for referencing appraisal cycles. If found, returns back with error. Otherwise sets `is_active=false`, soft-deletes, logs activity, redirects.
6. **Trash/Restore/ForceDelete**: Standard soft-delete pattern — `onlyTrashed() paginate(15)', `restore()` + set `is_active=true`, `withTrashed()->forceDelete()`.

---

## Validate Before Save

| Field | Rule(s) | Error Message |
|---|---|---|
| name | required, string, max:200 | — (Laravel default) |
| applicable_to | required, in:all,teaching,non_teaching | — |
| rating_scale | required, integer, in:5,10 | — |
| is_active | required, boolean | — (auto-merged from checkbox) |
| items | sometimes, array, min:1 | — |
| items.*.kpi_name | required_with:items, string, max:200 | — |
| items.*.category | required_with:items, in:academic,behavioral,administrative | — |
| items.*.weight | required_with:items, numeric, min:0, max:100 | — |
| items.*.description | nullable, string, max:500 | — |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|---|---|---|
| Delete blocked by appraisal cycles | "Cannot delete KPI template used in appraisal cycles." | Controller check (back with error) |
| Toggle status success | "Status updated successfully." | JSON response |
| Store success | "KPI template created successfully." | Flash success |
| Update success | "KPI template updated successfully." | Flash success |
| Remove success | "KPI template removed." | Flash success |
| Restore success | "KPI Template restored successfully." | Flash success |
| Force delete success | "KPI Template permanently deleted." | Flash success |

---

## Success Scenarios

**SC-001 — Create KPI Template with Items**: HR creates a template named "Teacher KPI" with 5-point scale, applicable to teaching, and 3 items (Classroom 40%, Behavior 35%, Admin 25%). System creates the template record and all 3 item records, logs activity, and redirects to the KPI Templates tab with success message.

**SC-002 — Update Items via UpdateOrCreate**: HR edits an existing template, changes the weight of one item from 30% to 25%, and adds a new item. System marks old items inactive, creates/updates via `(template_id, kpi_name)` matching, preserving the updated weight and adding the new item.

**SC-003 — Toggle Status**: HR toggles a template inactive. System flips `is_active` to false and returns JSON success with the new state.

---

## Failure Scenarios

**FC-001 — Delete Template with Active Cycles**: HR attempts to delete a template that is referenced by an existing appraisal cycle. System checks `appraisalCycles()->exists()`, returns back with error "Cannot delete KPI template used in appraisal cycles."

**FC-002 — Missing Required Fields**: HR submits a template without a name. Validation fails, form re-displays with field errors.

**FC-003 — Invalid Rating Scale**: HR enters 7 as the rating scale. Validation rejects as `in:5,10`.

---

## Dependencies module and tables

| Dependency | Type | Details |
|---|---|---|
| `hrs_appraisal_cycles.kpi_template_id` | Child FK | `hrs_appraisal_cycles` references `hrs_kpi_templates.id`, ON DELETE — blocked by controller check `appraisalCycles()->exists()` |
| `hrs_kpi_template_items.template_id` | Child FK | `hrs_kpi_template_items` references `hrs_kpi_templates.id`, ON DELETE — no cascade in DDL; soft-delete marks `is_active=false` |
| `sys_users.id` | FK parent | `created_by`, `updated_by` reference `sys_users.id` |
| Activity Log | Service | All create/update/delete actions logged via `activityLog()` |

**Table:** `hrs_kpi_templates`

| Column | Type | Details |
|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| name | VARCHAR(200) | NOT NULL |
| applicable_to | ENUM('All','Teaching','Non-Teaching') | NOT NULL, DEFAULT 'All' |
| rating_scale | TINYINT UNSIGNED | NOT NULL, DEFAULT 5 |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |

**Table:** `hrs_kpi_template_items`

| Column | Type | Details |
|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| template_id | BIGINT UNSIGNED | NOT NULL, FK → `hrs_kpi_templates.id` |
| kpi_name | VARCHAR(200) | NOT NULL |
| category | ENUM('academic','behavioral','administrative') | NOT NULL |
| weight | DECIMAL(5,2) | NOT NULL |
| description | TEXT | NULL |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
