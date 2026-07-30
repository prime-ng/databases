# hrs_kpiTemplates_TcList

## Module: HrStaff → Appraisals → KPI Templates

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | Appraisals |
| Feature | KPI Templates |
| URL(s) | `GET /appraisals-overview?tab=kpi-templates` (combined page), `GET /kpi-templates` (index), `POST /kpi-templates` (store), `GET /kpi-templates/{kpiTemplate}` (show), `GET /kpi-templates/{kpiTemplate}/edit` (edit), `PUT /kpi-templates/{kpiTemplate}` (update), `DELETE /kpi-templates/{kpiTemplate}` (destroy), `POST /kpi-templates/{kpiTemplate}/toggle-status` (toggleStatus), `GET /kpi-templates/trash/view` (trashed), `GET /kpi-templates/{id}/restore` (restore), `DELETE /kpi-templates/{id}/force-delete` (forceDelete) |
| Controller | `Modules\HrStaff\Http\Controllers\AppraisalController` — `kpiIndex()` lines 30-37, `kpiStore()` lines 39-63, `kpiShow()` lines 66-72, `kpiEdit()` lines 75-81, `kpiUpdate()` lines 97-122, `kpiToggleStatus()` lines 84-94, `kpiDestroy()` lines 167-182, `kpiTrashed()` lines 127-134, `kpiRestore()` lines 139-150, `kpiForceDelete()` lines 155-165 |
| Model(s) | `Modules\HrStaff\Models\KpiTemplate` (table: `hrs_kpi_templates`), `Modules\HrStaff\Models\KpiTemplateItem` (table: `hrs_kpi_template_items`) |
| Validation (Create) | `Modules\HrStaff\Http\Requests\StoreKpiTemplateRequest` |
| Validation (Update) | `Modules\HrStaff\Http\Requests\StoreKpiTemplateRequest` |
| Policy | `Modules\HrStaff\Policies\KpiTemplatePolicy` |
| Permissions | `hrs.kpi_template.manage` (policy), `hrs.appraisal.manage` (controller gate) |
| Pagination | `kpiIndex()` — no pagination (all records); `kpiTrashed()` — 15 records per page |
| Soft Deletes | Yes — `KpiTemplate` and `KpiTemplateItem` both use `SoftDeletes` trait |
| Data Source | Direct CRUD — records created in `hrs_kpi_templates` and `hrs_kpi_template_items` |
| Activity Log | Events: `Created`, `Updated`, `Trashed`, `Restored`, `Deleted` (forceDelete) |

---

## 2. Pre-conditions

- Required permissions: `hrs.appraisal.manage` (or `hrs.kpi_template.manage` via policy)
- Required seed data: At least one active KPI template with items for edit/show/toggle/delete testing
- Test user must have `hrs.appraisal.manage` permission (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For delete-blocked test: Create an appraisal cycle that references the template
- For pagination test in trash: Create at least 16 templates to soft-delete

---

## 3. Default Data Load

When the page loads via `HrMenuController@appraisalsIncrements()` (GET `/appraisals-overview?tab=kpi-templates`), the following data is fetched:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| KPI Templates Grid | `HrMenuController@appraisalsIncrements()` | `KpiTemplate::with('items')->orderBy('name')->get()` | None (loads all) | None |

> **Data Source:** KPI templates are created within the module itself (direct CRUD).

---

## 4. Test Data Strategy

- Create test KPI templates with `uniqueSuffix()` appended to names to avoid collisions
- Each test template should have at least 2 KPI items with weights summing to 100
- For pagination test in trash view: create 16+ templates, soft-delete all, verify page 2 loads
- For toggle-status test: create at least one active and one inactive template
- For delete-blocked test: create an appraisal cycle that references the template to be deleted
- Pre-test cleanup: Delete created templates by ID or name suffix before/after tests

---

## 5. Business Conditions

### 5.1 Database Schema — `hrs_kpi_templates`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | name | VARCHAR(200) | NOT NULL |
| BC-DB-03 | applicable_to | ENUM('All','Teaching','Non-Teaching') | NOT NULL, DEFAULT 'All' |
| BC-DB-04 | rating_scale | TINYINT UNSIGNED | NOT NULL, DEFAULT 5 |
| BC-DB-05 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-06 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-07 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-08 | created_at | TIMESTAMP | NULL |
| BC-DB-09 | updated_at | TIMESTAMP | NULL |
| BC-DB-10 | deleted_at | TIMESTAMP | NULL — Soft delete |

### 5.2 Database Schema — `hrs_kpi_template_items`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-11 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-12 | template_id | BIGINT UNSIGNED | NOT NULL, FK → `hrs_kpi_templates.id` |
| BC-DB-13 | kpi_name | VARCHAR(200) | NOT NULL |
| BC-DB-14 | category | ENUM('academic','behavioral','administrative') | NOT NULL |
| BC-DB-15 | weight | DECIMAL(5,2) | NOT NULL |
| BC-DB-16 | description | TEXT | NULL |
| BC-DB-17 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-18 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-19 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-20 | created_at | TIMESTAMP | NULL |
| BC-DB-21 | updated_at | TIMESTAMP | NULL |
| BC-DB-22 | deleted_at | TIMESTAMP | NULL — Soft delete |

### 5.3 Validation Rules — StoreKpiTemplateRequest (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | name | required, string, max:200 | — |
| BC-VAL-02 | applicable_to | required, in:all,teaching,non_teaching | — |
| BC-VAL-03 | rating_scale | required, integer, in:5,10 | — |
| BC-VAL-04 | is_active | required, boolean | — (auto-merged by `prepareForValidation()`) |
| BC-VAL-05 | items | sometimes, array, min:1 | — |
| BC-VAL-06 | items.*.kpi_name | required_with:items, string, max:200 | — |
| BC-VAL-07 | items.*.category | required_with:items, in:academic,behavioral,administrative | — |
| BC-VAL-08 | items.*.weight | required_with:items, numeric, min:0, max:100 | — |
| BC-VAL-09 | items.*.description | nullable, string, max:500 | — |

### 5.4 Validation Rules — StoreKpiTemplateRequest (Update)

Same rules as Create (BC-VAL-01 through BC-VAL-09). `prepareForValidation()` merges `is_active` as boolean.

### 5.5 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `hrs.appraisal.manage` | Granted — all KPI operations succeed |
| BC-AUTH-02 | `hrs.appraisal.manage` | Denied — 403 Forbidden on all operations |
| BC-AUTH-03 | Guest access | Redirect to /login |

### 5.6 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page load (kpi-templates tab) | KPI templates grid loads all active templates with items column, ordered by name |
| BC-BIZ-02 | Page load (standalone kpiIndex) | Same data as tab, no pagination |
| BC-BIZ-03 | Create template with 3 items, weights sum to 100 | Template created with all 3 items; success flash message |
| BC-BIZ-04 | Update template name | Name updated; success flash message |
| BC-BIZ-05 | Update template items (replace items array) | Old items marked is_active=false; new items created/updated via updateOrCreate |
| BC-BIZ-06 | Toggle status active→inactive | is_active flipped; JSON response with new state |
| BC-BIZ-07 | Delete template with no cycles | Template soft-deleted, is_active=false; success flash |
| BC-BIZ-08 | Delete template with appraisal cycles | Returns back with error "Cannot delete KPI template used in appraisal cycles." |
| BC-BIZ-09 | View trashed templates | Only soft-deleted templates shown, paginated 15/page |
| BC-BIZ-10 | Restore template | Template restored, is_active=true; success flash |
| BC-BIZ-11 | Force delete template | Permanently deleted; success flash |
| BC-BIZ-12 | Show template details | Template with items loaded in view |
| BC-BIZ-13 | Edit template form | Template with items loaded in editable form |
| BC-BIZ-14 | Empty state — no templates | Grid shows no records, empty state message |

### 5.7 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `hrs_kpi_template_items.template_id` | `hrs_kpi_templates.id` | No CASCADE in DDL (controller handles via `is_active=false`) |
| BC-REF-02 | `hrs_appraisal_cycles.kpi_template_id` | `hrs_kpi_templates.id` | No CASCADE — controller blocks delete if cycles exist |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Load KPI Templates tab page | Grid loads all active templates with item count, ordered by name | — | — | ⬜ |
| TC-P02 | Create template with all fields and 2 items | Template created, items created, flash "KPI template created successfully." | — | — | ⬜ |
| TC-P03 | Create template with minimum fields (no optional description) | Template created with default description=NULL | — | — | ⬜ |
| TC-P04 | View single template details | Show page displays template info and all items | — | — | ⬜ |
| TC-P05 | Edit template form loads with data | Edit form pre-filled with existing template values and items | — | — | ⬜ |
| TC-P06 | Update template name and items | Name updated, items replaced, flash "KPI template updated successfully." | — | — | ⬜ |
| TC-P07 | Toggle template from active to inactive | AJAX success, is_active becomes false, JSON | — | — | ⬜ |
| TC-P08 | Toggle template from inactive to active | AJAX success, is_active becomes true, JSON | — | — | ⬜ |
| TC-P09 | Soft-delete template with no cycles | Template trashed, is_active=false, flash "KPI template removed." | — | — | ⬜ |
| TC-P10 | View trashed templates | Only trashed templates shown, paginated | — | — | ⬜ |
| TC-P11 | Restore trashed template | Template restored, is_active=true, flash "KPI Template restored successfully." | — | — | ⬜ |
| TC-P12 | Force delete trashed template | Template permanently deleted, flash "KPI Template permanently deleted." | — | — | ⬜ |
| TC-P13 | Create template with 5-point scale | rating_scale=5 saved | — | — | ⬜ |
| TC-P14 | Create template with 10-point scale | rating_scale=10 saved | — | — | ⬜ |
| TC-P15 | Create template with applicable_to=teaching | applicable_to set to teaching | — | — | ⬜ |
| TC-P16 | Create template with applicable_to=non_teaching | applicable_to set to non_teaching | — | — | ⬜ |
| TC-P17 | Create template with academic, behavioral, and administrative items across categories | All categories saved correctly | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Create template without name | Validation error: name is required | — | — | ⬜ |
| TC-N02 | Create template with name exceeding 200 chars | Validation error: name max:200 | — | — | ⬜ |
| TC-N03 | Create template without applicable_to | Validation error: applicable_to is required | — | — | ⬜ |
| TC-N04 | Create template with invalid applicable_to | Validation error: in:all,teaching,non_teaching | — | — | ⬜ |
| TC-N05 | Create template with invalid rating_scale (not 5 or 10) | Validation error: in:5,10 | — | — | ⬜ |
| TC-N06 | Create template without items (no items key) | Template created with zero items (items is sometimes|array) — valid scenario | — | — | ⬜ |
| TC-N07 | Create template with empty items array | Template created with zero items (min:1 applies if items key present; but test empty array) | — | — | ⬜ |
| TC-N08 | Create item without kpi_name | Validation error: kpi_name is required_with:items | — | — | ⬜ |
| TC-N09 | Create item with invalid category | Validation error: in:academic,behavioral,administrative | — | — | ⬜ |
| TC-N10 | Create item with weight < 0 | Validation error: min:0 | — | — | ⬜ |
| TC-N11 | Create item with weight > 100 | Validation error: max:100 | — | — | ⬜ |
| TC-N12 | Create item with description exceeding 500 chars | Validation error: max:500 | — | — | ⬜ |
| TC-N13 | Delete template that has appraisal cycles | Error "Cannot delete KPI template used in appraisal cycles." | — | — | ⬜ |
| TC-N14 | Access without permission `hrs.appraisal.manage` | 403 Forbidden | — | — | ⬜ |
| TC-N15 | Guest access to any KPI template URL | Redirect to /login | — | — | ⬜ |
| TC-N16 | Force delete non-trashed template | Route expects ID — uses `withTrashed()` findOrFail; 404 if ID invalid | — | — | ⬜ |
| TC-N17 | Access non-existent template ID | 404 Not Found (Model binding) | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Soft-delete cascade — template soft-deleted => items keep is_active=false (no cascade) | Items remain in DB with is_active=false | — | — | ⬜ |
| TC-D02 | B | FK parent — items.template_id references hrs_kpi_templates.id | DB FK constraint enforced | — | — | ⬜ |
| TC-D03 | C | Activity logging — create/update/delete logged | `activityLog()` called with appropriate messages | — | — | ⬜ |
| TC-D04 | D | Model casting — rating_scale cast to integer, is_active cast to boolean | Correct types in JSON responses and DB | — | — | ⬜ |
| TC-D05 | D | Model relationship — template hasMany items | items() returns correct KpiTemplateItem collection | — | — | ⬜ |
| TC-D06 | D | Model relationship — items belongsTo template | template() returns correct KpiTemplate | — | — | ⬜ |
| TC-D07 | D | Controller gate — all methods gate via `hrs.appraisal.manage` | Each method throws AuthorizationException without permission | — | — | ⬜ |
| TC-D08 | E | Unique — no unique constraint on name (not enforced at DB level) | Multiple templates can share the same name | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns for KpiTemplate | All DDL columns in fillable | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$fillable` matches DDL columns for KpiTemplateItem | All DDL columns in fillable | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — `$casts` for booleans/integers/decimals | rating_scale=>integer, is_active=>boolean, weight=>decimal:2 | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — SoftDeletes trait implemented | Both models use SoftDeletes; deleted_at column exists | — | — | ◌ |
| TC-CR05 | CR | P1 | Model — relationships defined | KpiTemplate: items(), appraisalCycles(); KpiTemplateItem: template() | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — try-catch exception handling | All write methods have try-catch or let Laravel handle | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `Gate::authorize()` on every method | Each method gates via `hrs.appraisal.manage` | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — activity logged on all state changes | Create/update/delete/toggle/restore/forceDelete all call `activityLog()` | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — `is_active=false` before soft delete | `kpiDestroy()` sets is_active=false before delete() | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — `toggleStatus()` flips is_active | kpiToggleStatus() flips boolean, returns JSON | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — trash/restore/forceDelete flow | kpiTrashed() uses onlyTrashed(); kpiRestore() calls restore() and sets is_active=true; kpiForceDelete() uses withTrashed()->forceDelete() | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — JSON success response after toggle | kpiToggleStatus() returns JSON | — | — | ◌ |
| TC-CR13 | CR | P1 | Request — validation rules cover all fields | StoreKpiTemplateRequest covers name, applicable_to, rating_scale, is_active, items, and all item sub-fields | — | — | ◌ |
| TC-CR14 | CR | P1 | Request — `prepareForValidation()` normalizations | is_active merged as boolean with default true | — | — | ◌ |
| TC-CR15 | CR | P1 | Policy — all required methods defined | KpiTemplatePolicy has viewAny, view, create, update, delete, restore, forceDelete methods | — | — | ◌ |
| TC-CR16 | CR | P1 | Routes — resource + custom routes registered | All KPI template routes registered with proper verbs/names | — | — | ◌ |
| TC-CR17 | CR | P1 | View — Blade `@can` directives on action buttons | @can('hrs.appraisal.manage') on create/edit/delete buttons | — | — | ◌ |
| TC-CR18 | CR | P1 | Database — no unique constraints conflicting with validation | No unique key on name (expected: multiple templates can share names) | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — $fillable Matches DDL Columns For KpiTemplate
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/HrStaff/Models/KpiTemplate.php` | File exists |
| 2 | Verify `$fillable` array includes: name, applicable_to, rating_scale, is_active, created_by, updated_by | All present in array |

#### TC-CR02: Model — $fillable Matches DDL Columns For KpiTemplateItem
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/HrStaff/Models/KpiTemplateItem.php` | File exists |
| 2 | Verify `$fillable` includes: template_id, kpi_name, category, weight, description, is_active, created_by, updated_by | All present |

#### TC-CR03: Model — $casts For Booleans/Integers/Decimals
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check KpiTemplate::$casts | rating_scale => integer, is_active => boolean |
| 2 | Check KpiTemplateItem::$casts | weight => decimal:2, is_active => boolean |

#### TC-CR04: Model — SoftDeletes Trait Implemented
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check KpiTemplate uses SoftDeletes | Trait present, deleted_at column in DDL |
| 2 | Check KpiTemplateItem uses SoftDeletes | Trait present, deleted_at column in DDL |

#### TC-CR05: Model — Relationships Defined
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check KpiTemplate::items() | hasMany(KpiTemplateItem::class, 'template_id') defined |
| 2 | Check KpiTemplateItem::template() | belongsTo(KpiTemplate::class, 'template_id') defined |

#### TC-CR06: Controller — Try-Catch Exception Handling
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `kpiStore()` | No explicit try-catch; Laravel handles validation/authorization exceptions |
| 2 | Check `kpiUpdate()` | No explicit try-catch; same pattern |

#### TC-CR07: Controller — Gate::authorize() On Every Method
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check kpiIndex() | Gate::authorize('hrs.appraisal.manage') present |
| 2 | Check kpiStore() | Gate::authorize('hrs.appraisal.manage') present |
| 3 | Check kpiShow() | Gate::authorize('hrs.appraisal.manage') present |
| 4 | Check kpiEdit() | Gate::authorize('hrs.appraisal.manage') present |
| 5 | Check kpiUpdate() | Gate::authorize('hrs.appraisal.manage') present |
| 6 | Check kpiToggleStatus() | Gate::authorize('hrs.appraisal.manage') present |
| 7 | Check kpiDestroy() | Gate::authorize('hrs.appraisal.manage') present |
| 8 | Check kpiTrashed() | Gate::authorize('hrs.appraisal.manage') present |
| 9 | Check kpiRestore() | Gate::authorize('hrs.appraisal.manage') present |
| 10 | Check kpiForceDelete() | Gate::authorize('hrs.appraisal.manage') present |

#### TC-CR08: Controller — Activity Logged On All State Changes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check kpiStore() | `activityLog($template, 'Created', ...)` present |
| 2 | Check kpiUpdate() | `activityLog($kpiTemplate, 'Updated', ...)` present |
| 3 | Check kpiDestroy() | `activityLog($kpiTemplate, 'Trashed', ...)` present |
| 4 | Check kpiRestore() | `activityLog($kpiTemplate, 'Restored', ...)` present |
| 5 | Check kpiForceDelete() | `activityLog($kpiTemplate, 'Deleted', ...)` present |

#### TC-CR09: Controller — is_active=false Before Soft Delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check kpiDestroy() | Sets is_active=false, then delete() called |

#### TC-CR10: Controller — toggleStatus() Flips is_active
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check kpiToggleStatus() | `update(['is_active' => !$kpiTemplate->is_active])` and returns JSON |

#### TC-CR11: Controller — Trash/Restore/ForceDelete Flow
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check kpiTrashed() | Uses `KpiTemplate::onlyTrashed()->orderBy('name')->paginate(15)` |
| 2 | Check kpiRestore() | Uses `KpiTemplate::onlyTrashed()->findOrFail($id)`, calls restore(), sets is_active=true |
| 3 | Check kpiForceDelete() | Uses `KpiTemplate::withTrashed()->findOrFail($id)`, calls forceDelete() |

#### TC-CR12: Controller — JSON Success Response After Toggle
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check kpiToggleStatus() | Returns `response()->json(['success'=>true, 'is_active'=>..., 'message'=>'Status updated successfully.'])` |

#### TC-CR13: Request — Validation Rules Cover All Fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open StoreKpiTemplateRequest.php | File exists |
| 2 | Verify rules() covers: name, applicable_to, rating_scale, is_active, items, items.*.kpi_name, items.*.category, items.*.weight, items.*.description | All present with correct rules |

#### TC-CR14: Request — prepareForValidation() Normalizations
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check prepareForValidation() | Merges is_active as boolean with default true |

#### TC-CR15: Policy — All Required Methods Defined
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check KpiTemplatePolicy | Methods: viewAny, view, create, update, delete, restore, forceDelete defined |
| 2 | Verify each method gates via `hrs.kpi_template.manage` | Each returns `$user->can('hrs.kpi_template.manage')` |

#### TC-CR16: Routes — Resource + Custom Routes Registered
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` in HrStaff module | All KPI template routes present: index, store, show, edit, update, destroy, toggle-status, trash/view, restore, force-delete |

#### TC-CR17: View — Blade @can Directives On Action Buttons
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check view files for `@can('hrs.appraisal.manage')` | Guards on create/edit/delete action buttons |

#### TC-CR18: Database — No Unique Constraints Conflicting
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for hrs_kpi_templates | Only PK — no unique constraint on name |

### 7.1 Positive TC Steps

#### TC-P01: Load KPI Templates Tab Page
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin user | Dashboard loads |
| 2 | Navigate to Appraisals → KPI Templates tab | KPI templates grid displays with all active templates ordered by name |

#### TC-P02: Create Template With All Fields And 2 Items
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add Template" | Create form opens |
| 2 | Enter name "Test KPI TC-P02" | Field populated |
| 3 | Select applicable_to "Teaching" | Dropdown set |
| 4 | Select rating_scale "5" | Scale set |
| 5 | Add item 1: kpi_name="Classroom Mgmt", category="academic", weight="60.00" | Item row added |
| 6 | Add item 2: kpi_name="Punctuality", category="behavioral", weight="40.00" | Item row added |
| 7 | Click Save | Template created, redirected to KPI Templates tab, flash "KPI template created successfully." |

#### TC-P03: Create Template With Minimum Fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add Template" | Create form opens |
| 2 | Enter name "Minimal TC-P03" | Field populated |
| 3 | Select applicable_to "All" | Default |
| 4 | Select rating_scale "10" | Scale set |
| 5 | Do not add any items (items key omitted) | No items row |
| 6 | Click Save | Template created with zero items, flash success |

#### TC-P04: View Single Template Details
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "View" on an existing template | Show page loads with template info and all items listed |

#### TC-P05: Edit Template Form Loads With Data
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Edit" on an existing template | Edit form pre-filled with name, applicable_to, rating_scale, and items |

#### TC-P06: Update Template Name And Items
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load edit form for template with 2 items | Form displayed |
| 2 | Change name to "Updated TC-P06" | Name changed |
| 3 | Remove one existing item, add a new item with kpi_name="Collaboration", category="administrative", weight="30.00" | Items updated |
| 4 | Click Save | Template updated, old item marked inactive, new item created, flash "KPI template updated successfully." |

#### TC-P07: Toggle Template From Active To Inactive
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an active template | Status badge shows "Active" |
| 2 | Click toggle-status button | AJAX call, is_active becomes false, JSON `{"success":true, "is_active":false, "message":"Status updated successfully."}` |

#### TC-P08: Toggle Template From Inactive To Active
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an inactive template | Status badge shows "Inactive" |
| 2 | Click toggle-status button | AJAX call, is_active becomes true, JSON success |

#### TC-P09: Soft-Delete Template With No Cycles
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Delete" on a template with no linked cycles | Confirmation dialog (if any) |
| 2 | Confirm deletion | Template removed from grid, flash "KPI template removed." |

#### TC-P10: View Trashed Templates
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trash view | Only soft-deleted templates shown, paginated 15 per page |

#### TC-P11: Restore Trashed Template
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trash view | Trashed templates listed |
| 2 | Click "Restore" on a trashed template | Template restored, is_active=true, flash "KPI Template restored successfully." |

#### TC-P12: Force Delete Trashed Template
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trash view | Trashed templates listed |
| 2 | Click "Force Delete" on a trashed template | Template permanently deleted, flash "KPI Template permanently deleted." |

#### TC-P13: Create Template With 5-Point Scale
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with rating_scale=5 | Saved with rating_scale=5 |

#### TC-P14: Create Template With 10-Point Scale
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with rating_scale=10 | Saved with rating_scale=10 |

#### TC-P15: Create Template With Applicable_To=Teaching
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with applicable_to=teaching | applicable_to set to "Teaching" |

#### TC-P16: Create Template With Applicable_To=Non_Teaching
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with applicable_to=non_teaching | applicable_to set to "Non-Teaching" |

#### TC-P17: Create Template With All Categories
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with items across academic, behavioral, administrative categories | All categories saved correctly |

### 7.2 Negative TC Steps

#### TC-N01: Create Template Without Name
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form displays |
| 2 | Leave name blank | Field empty |
| 3 | Fill all other required fields | Other fields filled |
| 4 | Click Save | Validation error: name is required |

#### TC-N02: Create Template With Name Exceeding 200 Chars
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter name of 201 characters | Exceeds limit |
| 2 | Click Save | Validation error: name may not be greater than 200 characters |

#### TC-N03: Create Template Without Applicable_To
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave applicable_to unselected | Null value |
| 2 | Click Save | Validation error: applicable_to is required |

#### TC-N04: Create Template With Invalid Applicable_To
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set applicable_to to "invalid_value" | Not in allowed list |
| 2 | Click Save | Validation error |

#### TC-N05: Create Template With Invalid Rating_Scale
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set rating_scale to 7 | Not 5 or 10 |
| 2 | Click Save | Validation error |

#### TC-N06: Create Template With No Items Key
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit without items key | Template creates successfully (items is "sometimes") |

#### TC-N07: Create Template With Empty Items Array
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with items=[] | Template creates with zero items (min:1 on array) — validation may or may not trigger depending on framework handling |

#### TC-N08: Create Item Without Kpi_Name
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add an item row but leave kpi_name blank | Validation error: kpi_name is required |

#### TC-N09: Create Item With Invalid Category
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set category to "invalid" | Not in: academic,behavioral,administrative |
| 2 | Click Save | Validation error |

#### TC-N10: Create Item With Weight < 0
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set weight to -5 | Below 0 |
| 2 | Click Save | Validation error: weight must be at least 0 |

#### TC-N11: Create Item With Weight > 100
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set weight to 150 | Above 100 |
| 2 | Click Save | Validation error: weight may not be greater than 100 |

#### TC-N12: Create Item With Description Exceeding 500 Chars
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter description of 501 characters | Exceeds limit |
| 2 | Click Save | Validation error |

#### TC-N13: Delete Template That Has Appraisal Cycles
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create an appraisal cycle linked to this template | Cycle references template |
| 2 | Attempt to delete the template | Error: "Cannot delete KPI template used in appraisal cycles." |

#### TC-N14: Access Without Permission Hrs.Appraisal.Manage
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without hrs.appraisal.manage permission | Dashboard loads |
| 2 | Navigate to KPI Templates URL | 403 Forbidden |

#### TC-N15: Guest Access To Any KPI Template URL
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout | Session cleared |
| 2 | Navigate to GET /kpi-templates | Redirected to /login |

#### TC-N16: Access Non-Existent Template ID
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to GET /kpi-templates/99999 | 404 Not Found (model binding) |

#### TC-N17: Force Delete Non-Trashed Template
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call force-delete on a non-trashed template ID | Route uses `withTrashed()` findOrFail — succeeds but may have unexpected behavior; verify intended flow |

### 7.3 Dependency TC Steps

#### TC-D01: Soft-Delete Cascade — Template Items Stay
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with 2 items | Template and items exist |
| 2 | Soft-delete the template | Template.deleted_at set, items.deleted_at remains NULL |
| 3 | Verify items still exist in DB with is_active as-is | Items not cascade-deleted |

#### TC-D02: FK Parent — Items.Template_Id References Hrs_Kpi_Templates.Id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for hrs_kpi_template_items | FK constraint on template_id → hrs_kpi_templates.id exists |

#### TC-D03: Activity Logging — Create/Update/Delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create, update, and delete a template | Each action logged in activity log with appropriate message |

#### TC-D04: Model Casting — Rating_Scale, Is_Active
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check KpiTemplate::$casts | rating_scale=>integer, is_active=>boolean |
| 2 | Check KpiTemplateItem::$casts | weight=>decimal:2, is_active=>boolean |

#### TC-D05: Model Relationship — Template HasMany Items
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load a template with items | template->items returns collection of KpiTemplateItem records |

#### TC-D06: Model Relationship — Items BelongsTo Template
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load a KpiTemplateItem | item->template returns parent KpiTemplate |

#### TC-D07: Controller Gate — All Methods Gate Via Hrs.Appraisal.Manage
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify each method in AppraisalController starts with Gate::authorize('hrs.appraisal.manage') | All kpi* methods gated |

#### TC-D08: No Unique Constraint On Name
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create two templates with identical name "Duplicate Name" | Both created successfully |
