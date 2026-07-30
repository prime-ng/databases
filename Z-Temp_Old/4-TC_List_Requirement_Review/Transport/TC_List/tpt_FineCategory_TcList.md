# Fine Category — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Transport (TPT) |
| **Tab Group** | Transport Master |
| **Feature** | Fine Category |
| **URL(s)** | `/transport/transport-master` (index via tab `fine_category`), `/transport/fine-category/create` (create), `/transport/fine-category/{id}` (show), `/transport/fine-category/{id}/edit` (edit), `/transport/fine-category/trash/view` (trash), `/transport/fine-category/{id}/restore` (restore), `/transport/fine-category/{id}/force-delete` (forceDelete), `/transport/fine-category/{id}/toggle-status` (toggleStatus) |
| **Controller** | `Modules\Transport\Http\Controllers\FineCategoryController` — 10 methods — ⚠️ `index()` NOT called for tab listing; standalone route only |
| **Tab Container Controller** | `Modules\Transport\Http\Controllers\TransportMasterController@index()` — tab id `fine_category`, private `fineCategoryQuery()` for listing |
| **Model(s)** | `Modules\Transport\Models\TptFineCategory` — SoftDeletes, 1 relationship |
| **Validation** | `Modules\Transport\Http\Requests\FineCategoryRequest` — 3 rules + prepareForValidation |
| **Permissions** | `tenant.fine-category.viewAny`, `tenant.fine-category.view`, `tenant.fine-category.create`, `tenant.fine-category.update`, `tenant.fine-category.delete`, `tenant.fine-category.restore`, `tenant.fine-category.forceDelete` |
| **Soft Deletes** | Yes (`TptFineCategory` uses `SoftDeletes` trait) |
| **Activity Log** | Events: `Created`, `Updated`, `Trashed`, `Restored`, `Force Deleted`, `Toggled` |
| **DB Table** | `tpt_fine_category` — 5 data columns, PK is TINYINT UNSIGNED |
| **Blade Views** | `fine-category/index.blade.php` (tab), `create.blade.php`, `edit.blade.php`, `show.blade.php`, `trash.blade.php` |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in with `tenant.fine-category.*` permissions |
| PC-02 | `tpt_fine_category` table must exist with ENUM('Transport','Finance') on `initiated_by` column |
| PC-03 | Tab must be registered in `transportmaster.blade.php` with id `fine_category` |
| PC-04 | Browser must support JavaScript for status toggle AJAX and pagination |
| PC-05 | Database must have no unique constraint on `category_name` (duplicate names allowed per DDL) |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Load fine categories with `latest()` ordering, 20 per page | `FineCategoryController.php:18` — `TptFineCategory::latest()->paginate(20)` |
| DL-02 | List columns: **Category Name**, **Initiated By**, **Evidence Required** (Yes/No badge), **Status** (toggle switch), **Action** | `fine-category/index.blade.php:32-40` |
| DL-03 | Status toggle shows only for `@can('tenant.fine-category.update')` | `fine-category/index.blade.php:35` |
| DL-04 | Action column shows for `@canany(['tenant.fine-category.view', 'tenant.fine-category.update', 'tenant.fine-category.delete'])` | `fine-category/index.blade.php:38` |
| DL-05 | Search by category name, filter by status (All/Active/Inactive) | `fine-category/index.blade.php:8-15` |
| DL-06 | Evidence Required displayed as badge: `bg-success` "Yes" / `bg-secondary` "No" | `fine-category/index.blade.php:49-53` |
| DL-07 | Empty state: "No fine categories found." for colspan 5 | `fine-category/index.blade.php:78` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Category — Transport** | category_name="Late Fee", initiated_by="Transport", evidence_required=true |
| TD-02 | **Valid Category — Finance** | category_name="Fine Waiver", initiated_by="Finance", evidence_required=false |
| TD-03 | **Max Length Name** | category_name = 100 chars (VARCHAR(100) limit) |
| TD-04 | **Duplicate Name** | Same category_name "Late Fee" for two records — allowed (no unique constraint) |
| TD-05 | **Evidence Required = false** | Checkbox unchecked — `prepareForValidation()` converts to boolean false |
| TD-06 | **Invalid Initiated By** | Any value other than "Transport" or "Finance" — ENUM violation |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | TINYINT UNSIGNED | PK, AUTO_INCREMENT |
| BC-DB-02 | `category_name` | VARCHAR(100) | NOT NULL |
| BC-DB-03 | `initiated_by` | ENUM('Transport','Finance') | NOT NULL, DEFAULT 'Transport' |
| BC-DB-04 | `evidence_required` | TINYINT(1) | DEFAULT 0 |
| BC-DB-05 | `is_active` | TINYINT(1) | DEFAULT 1 |
| BC-DB-06 | `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-07 | `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-08 | `deleted_at` | TIMESTAMP NULL | Soft delete support |

### BC-VAL: Validation Conditions

| BC ID | Field | Rule | Source |
|-------|-------|------|--------|
| BC-VAL-01 | `category_name` | required, string, max:100 | `FineCategoryRequest.php:21-25` |
| BC-VAL-02 | `initiated_by` | required, in:Transport,Finance | `FineCategoryRequest.php:26-29` |
| BC-VAL-03 | `evidence_required` | nullable, boolean (checkbox normalized) | `FineCategoryRequest.php:30-33,37-42` |

### BC-AUTH: Authorization Conditions

| BC ID | Permission | Controller Method | Source |
|-------|-----------|-------------------|--------|
| BC-AUTH-01 | `tenant.fine-category.viewAny` | `index()` — Gate authorize | `FineCategoryController.php:16` |
| BC-AUTH-02 | `tenant.fine-category.create` | `create()` + `store()` — Gate authorize | `FineCategoryController.php:25,32` |
| BC-AUTH-03 | `tenant.fine-category.view` | `show()` — Gate authorize | `FineCategoryController.php:47` |
| BC-AUTH-04 | `tenant.fine-category.update` | `edit()` + `update()` + `toggleStatus()` — Gate authorize | `FineCategoryController.php:56,65,140` |
| BC-AUTH-05 | `tenant.fine-category.delete` | `destroy()` — Gate authorize | `FineCategoryController.php:81` |
| BC-AUTH-06 | `tenant.fine-category.restore` | `trashed()` + `restore()` — Gate authorize | `FineCategoryController.php:97,108` |
| BC-AUTH-07 | `tenant.fine-category.forceDelete` | `forceDelete()` — Gate authorize | `FineCategoryController.php:124` |

### BC-BIZ: Business Conditions

| BC ID | Condition | Expected | Source |
|-------|-----------|----------|--------|
| BC-BIZ-01 | `destroy()` does NOT set `is_active=false` before soft-delete | Record deleted with `is_active` unchanged | `FineCategoryController.php:83-84` — **Inconsistent** with Route/Shift/Vehicle pattern |
| BC-BIZ-02 | `forceDelete()` uses `withTrashed()` | Correct — finds both active and trashed records | `FineCategoryController.php:126` |
| BC-BIZ-03 | `update()` has NO change tracking | No `getOriginal()`/`getChanges()` — **Missing** compared to Shift/Vehicle pattern | `FineCategoryController.php:67-68` |
| BC-BIZ-04 | `update()` uses `$id` parameter (no route model binding) | `$record = TptFineCategory::findOrFail($id)` — manual lookup | `FineCategoryController.php:67` |
| BC-BIZ-05 | `toggleStatus()` uses `$request->boolean('is_active')` | Correct boolean normalization | `FineCategoryController.php:147` |
| BC-BIZ-06 | `evidence_required` checkbox value="1" normalized via `prepareForValidation()` | `$this->boolean('evidence_required')` | `FineCategoryRequest.php:40` |
| BC-BIZ-07 | Redirect always goes to `transport.transport-master.index` with `?tab=fine_category` | Tab param preserved | `FineCategoryController.php:41,75,91,118,134` |
| BC-BIZ-08 | Model has `fineMasters()` hasMany relationship | FK: `tpt_fine_master.fine_category_id` → `tpt_fine_category.id` ON DELETE RESTRICT | `TptFineCategory.php:27-29`, DDL line 395 |

### BC-REF: Reference & UI Conditions

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-REF-01 | Tab id `fine_category-pane`, hidden `tab=fine_category` in search form | `fine-category/index.blade.php:1,6` |
| BC-REF-02 | Status toggle has explicit `permission="tenant.fine-category.update"` | `fine-category/index.blade.php:57-61` |
| BC-REF-03 | Action component has granular permissions: view/edit/delete | `fine-category/index.blade.php:69-71` |
| BC-REF-04 | Create form: category_name text input, initiated_by dropdown (2 options), evidence_required checkbox | `fine-category/create.blade.php:24-51` |
| BC-REF-05 | Edit form: same fields + `is_active` status switch | `fine-category/edit.blade.php:24-56` |
| BC-REF-06 | Trash columns: Category Name, Initiated By, Status ("Deleted" badge), Action (restore/forceDelete) | `fine-category/trash.blade.php:10-15` |
| BC-REF-07 | `$is_active` field used in edit blade (line 55) but model `$fillable` does NOT include `is_active` — auto-handled via `status-switch` component | `TptFineCategory.php:14-19` vs `fine-category/edit.blade.php:55` |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create category — Transport initiated, evidence required | All fields valid | Created, 20 per page pagination, activityLog "Created" |
| TC-P-02 | Create category — Finance initiated, no evidence | initiated_by="Finance", evidence_required=false | Created with evidence_required=0 |
| TC-P-03 | Create category with max-length name | category_name = 100 chars | Created successfully |
| TC-P-04 | Create duplicate category name | Same name as existing | Created (no unique constraint on name) |
| TC-P-05 | Edit category name | Change name from "Late Fee" to "Late Fee Revised" | Updated, no change tracking in activityLog |
| TC-P-06 | Edit initiated_by from Transport to Finance | Change dropdown | Updated successfully |
| TC-P-07 | Edit evidence_required from Yes to No | Toggle switch off | Updated, evidence_required=false |
| TC-P-08 | Toggle status Active → Inactive | Click status switch | AJAX 200, `is_active=0`, toggle moves |
| TC-P-09 | Toggle status Inactive → Active | Click status switch | AJAX 200, `is_active=1`, toggle moves |
| TC-P-10 | View category details | Click eye icon | Show page displays all fields |
| TC-P-11 | Search category by name | Type partial name in search | Filtered results matching name |
| TC-P-12 | Filter by Active status | Select "Active" | Only is_active=1 records |
| TC-P-13 | Filter by Inactive status | Select "Inactive" | Only is_active=0 records |
| TC-P-14 | Soft delete category | Click delete | `deleted_at` set, `is_active` unchanged, activityLog "Trashed" |
| TC-P-15 | View trashed list | Navigate to trash | Only soft-deleted records shown with "Deleted" badge |
| TC-P-16 | Restore soft-deleted category | Click restore in trash | `deleted_at` cleared, activityLog "Restored" |
| TC-P-17 | Force delete trashed category | Click permanent delete | Record removed from DB, activityLog "Force Deleted" |
| TC-P-18 | Pagination across 20+ records | Create 25 records, go to page 2 | Page 1 = 20 records, Page 2 = 5 records |
| TC-P-19 | Pagination with tab param preserved | Click page 2 | URL: `?tab=fine_category&page=2` |
| TC-P-20 | Clear search filter | Click reset button after search | Tab reloads without filters |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create with empty category_name | Submit blank name | "Category name is required." or "The category name field is required." |
| TC-N-02 | Create with invalid initiated_by | POST value "Admin" | DB ENUM violation OR Request `in` rule failure |
| TC-N-03 | Create with category_name > 100 chars | 101-character string | "The category name must not be greater than 100 characters." |
| TC-N-04 | Access index without `tenant.fine-category.viewAny` | No permission | 403 Access Denied |
| TC-N-05 | Access create without `tenant.fine-category.create` | No permission | 403 Access Denied |
| TC-N-06 | Access edit without `tenant.fine-category.update` | No permission | 403 Access Denied |
| TC-N-07 | Access destroy without `tenant.fine-category.delete` | No permission | 403 Access Denied |
| TC-N-08 | Access restore without `tenant.fine-category.restore` | No permission | 403 Access Denied |
| TC-N-09 | Access forceDelete without `tenant.fine-category.forceDelete` | No permission | 403 Access Denied |
| TC-N-10 | Show non-existent ID | GET /fine-category/99999 | `findOrFail` → 404 |
| TC-N-11 | Edit non-existent ID | GET /fine-category/99999/edit | `findOrFail` → 404 |
| TC-N-12 | Update non-existent ID | PUT /fine-category/99999 | `findOrFail` → 404 |
| TC-N-13 | Delete non-existent ID | DELETE /fine-category/99999 | `findOrFail` → 404 |
| TC-N-14 | Restore non-trashed record | Call restore on active record | `onlyTrashed()->findOrFail()` → 404 |
| TC-N-15 | Force delete active (non-trashed) record | Call forceDelete on active | `withTrashed()->findOrFail()` finds it → succeeds (different from destroy) |
| TC-N-16 | Toggle status with invalid is_active value | POST with is_active="invalid" | "The is_active field must be true or false." |
| TC-N-17 | Toggle status on non-existent record | POST /fine-category/99999/toggle-status | `findOrFail` → 404 |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Delete category that has fine masters | Category linked via `fine_category_id` FK RESTRICT | Delete fails — FK constraint violation |
| TC-D-02 | Force delete — verify record removed | Query `withTrashed()` after forceDelete | Record not in DB |
| TC-D-03 | Verify `is_active` NOT set to false before soft-delete | Check DB after delete | `is_active` retains original value (1 or 0) |
| TC-D-04 | Verify `trashed()` only returns soft-deleted records | `onlyTrashed()` scope | Active records not in trash list |
| TC-D-05 | Verify `trashed()` ordered by `latest('deleted_at')` | Multiple deletes | Most recently deleted appears first |

### TC-CR: Code Review Test Cases

| ID | Test Case | Steps | Expected |
|----|-----------|-------|----------|
| TC-CR-01 | **Gate authorize in index()** | 1. Open `FineCategoryController.php:16` | `Gate::authorize('tenant.fine-category.viewAny')` called before query |
| TC-CR-02 | **Gate authorize in create()** | 1. Open `FineCategoryController.php:25` | `Gate::authorize('tenant.fine-category.create')` |
| TC-CR-03 | **Gate authorize in store()** | 1. Open `FineCategoryController.php:32` | `Gate::authorize('tenant.fine-category.create')` |
| TC-CR-04 | **Gate authorize in show()** | 1. Open `FineCategoryController.php:47` | `Gate::authorize('tenant.fine-category.view')` |
| TC-CR-05 | **Gate authorize in edit()** | 1. Open `FineCategoryController.php:56` | `Gate::authorize('tenant.fine-category.update')` |
| TC-CR-06 | **Gate authorize in update()** | 1. Open `FineCategoryController.php:65` | `Gate::authorize('tenant.fine-category.update')` |
| TC-CR-07 | **Gate authorize in destroy()** | 1. Open `FineCategoryController.php:81` | `Gate::authorize('tenant.fine-category.delete')` |
| TC-CR-08 | **Gate authorize in trashed()** | 1. Open `FineCategoryController.php:97` | `Gate::authorize('tenant.fine-category.restore')` |
| TC-CR-09 | **Gate authorize in restore()** | 1. Open `FineCategoryController.php:108` | `Gate::authorize('tenant.fine-category.restore')` |
| TC-CR-10 | **Gate authorize in forceDelete()** | 1. Open `FineCategoryController.php:124` | `Gate::authorize('tenant.fine-category.forceDelete')` |
| TC-CR-11 | **Gate authorize in toggleStatus()** | 1. Open `FineCategoryController.php:140` | `Gate::authorize('tenant.fine-category.update')` |
| TC-CR-12 | **activityLog after store()** | 1. Open `FineCategoryController.php:36-38` | `activityLog($record, 'Created', ['message' => 'Fine category created.'])` |
| TC-CR-13 | **activityLog after update()** | 1. Open `FineCategoryController.php:70-72` | `activityLog($record, 'Updated', ['message' => 'Fine category updated.'])` — NO change tracking |
| TC-CR-14 | **activityLog after destroy()** | 1. Open `FineCategoryController.php:86-88` | `activityLog($record, 'Trashed', ['message' => 'Fine category trashed.'])` |
| TC-CR-15 | **activityLog after restore()** | 1. Open `FineCategoryController.php:113-115` | `activityLog($record, 'Restored', ['message' => 'Fine category restored.'])` |
| TC-CR-16 | **activityLog after forceDelete()** | 1. Open `FineCategoryController.php:129-131` | `activityLog($record, 'Force Deleted', ['message' => 'Fine category permanently deleted.'])` |
| TC-CR-17 | **activityLog after toggleStatus()** | 1. Open `FineCategoryController.php:150-152` | `activityLog($record, 'Toggled', ['message' => 'Fine category status updated.'])` |
| TC-CR-18 | **GAP: destroy() does NOT set is_active=false** | 1. Open `FineCategoryController.php:83-84` | Only `$record->delete()` — no `is_active=false` before delete |
| TC-CR-19 | **GAP: update() has NO change tracking** | 1. Open `FineCategoryController.php:67-68` | Direct `$record->update()` — no `getOriginal()`/`getChanges()` |
| TC-CR-20 | **GAP: update() uses manual findOrFail($id)** | 1. Open `FineCategoryController.php:67` | `$record = TptFineCategory::findOrFail($id)` — no route model binding |
| TC-CR-21 | **forceDelete() uses withTrashed() — CORRECT** | 1. Open `FineCategoryController.php:126` | `TptFineCategory::withTrashed()->findOrFail($id)` — correct pattern |
| TC-CR-22 | **restore() uses onlyTrashed() — CORRECT** | 1. Open `FineCategoryController.php:110` | `TptFineCategory::onlyTrashed()->findOrFail($id)` — correct pattern |
| TC-CR-23 | **trashed() uses onlyTrashed() + latest('deleted_at')** | 1. Open `FineCategoryController.php:99-101` | `TptFineCategory::onlyTrashed()->latest('deleted_at')->paginate(20)` |
| TC-CR-24 | **toggleStatus() inline validation** | 1. Open `FineCategoryController.php:142-144` | `$request->validate(['is_active' => 'required\|boolean'])` |
| TC-CR-25 | **toggleStatus() uses $request->boolean()** | 1. Open `FineCategoryController.php:147` | `$record->is_active = $request->boolean('is_active')` — proper normalization |
| TC-CR-26 | **FineCategoryRequest authorize() POST** | 1. Open `FineCategoryRequest.php:12-14` | POST → `tenant.fine-category.create` |
| TC-CR-27 | **FineCategoryRequest authorize() non-POST** | 1. Open `FineCategoryRequest.php:15` | Non-POST → `tenant.fine-category.update` |
| TC-CR-28 | **FineCategoryRequest prepareForValidation()** | 1. Open `FineCategoryRequest.php:37-42` | `$this->boolean('evidence_required')` checkbox normalization |
| TC-CR-29 | **Model $fillable** | 1. Open `TptFineCategory.php:14-19` | `category_name`, `initiated_by`, `evidence_required`, `is_active` |
| TC-CR-30 | **Model $casts** | 1. Open `TptFineCategory.php:21-24` | `evidence_required => boolean`, `is_active => boolean` |
| TC-CR-31 | **Model fineMasters() relationship** | 1. Open `TptFineCategory.php:27-29` | `$this->hasMany(TptFineMaster::class, 'fine_category_id')` |
| TC-CR-32 | **DDL PK is TINYINT UNSIGNED** | 1. Open DDL line 373 | `id` TINYINT UNSIGNED AUTO_INCREMENT — not INT (max 255 records) |
| TC-CR-33 | **DDL initiated_by ENUM** | 1. Open DDL line 375 | `ENUM('Transport','Finance') NOT NULL DEFAULT 'Transport'` |
| TC-CR-34 | **Blade status-switch has explicit permission** | 1. Open `fine-category/index.blade.php:57-61` | `permission="tenant.fine-category.update"` — only shown to authorized |
| TC-CR-35 | **Blade action has granular permissions** | 1. Open `fine-category/index.blade.php:66-73` | view/edit/delete permissions individually set |
| TC-CR-36 | **Redirect preserves tab parameter** | 1. Open `FineCategoryController.php:41,75,91,118,134` | `->route('transport.transport-master.index', ['tab' => 'fine_category'])` |
| TC-CR-37 | **Model lacks scopeActive()** | 1. Open `TptFineCategory.php` | No `scopeActive()` defined — unlike Shift/Vehicle/Route |
| TC-CR-38 | **FK from fine_master has RESTRICT** | 1. Open DDL line 395 | `CONSTRAINT fk_fm_fine_category ... ON DELETE RESTRICT` — prevents delete if linked |

---

## 7. Detailed Test Steps

### TC-P-01: Create category — Transport initiated, evidence required

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.fine-category.create` permission | Login successful |
| 2 | Navigate to Fine Category create page: `GET /transport/fine-category/create` | Create form displayed with 3 fields: category_name (text), initiated_by (dropdown), evidence_required (checkbox) |
| 3 | Enter category_name = "Late Fee" | Text input shows "Late Fee" |
| 4 | Select initiated_by = "Transport" | Dropdown shows "Transport" selected |
| 5 | Check evidence_required checkbox | Checkbox is checked (value=1) |
| 6 | Click "Create Category" button | Form submits POST to `/transport/fine-category` |
| 7 | **Verify**: `FineCategoryRequest@authorize()` returns true (POST → `tenant.fine-category.create`) | Gate passes |
| 8 | **Verify**: `FineCategoryRequest@rules()` validates: category_name (required, max:100), initiated_by (required, in:Transport,Finance), evidence_required (nullable, boolean) | Validation passes |
| 9 | **Verify**: `prepareForValidation()` converts evidence_required checkbox to boolean | `$this->boolean('evidence_required')` = true |
| 10 | **Verify**: `TptFineCategory::create()` inserts with `is_active` default (1) | DB row created |
| 11 | **Verify**: `activityLog($record, 'Created', ['message' => 'Fine category created.'])` called | Activity log entry created |
| 12 | **Verify**: Redirect to `transport.transport-master.index?tab=fine_category` | URL contains `?tab=fine_category` |
| 13 | **Verify**: Flash message `flash('created.fine_category')` displayed | Success toast shown |
| 14 | **Verify**: New "Late Fee" category visible in list with Category Name, Initiated By="Transport", Evidence="Yes", Status=Active | Row displayed |

### TC-P-08: Toggle status Active → Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.fine-category.update` permission | Login successful |
| 2 | Navigate to Transport Master → Fine Category tab | Category list displayed with status toggle switches |
| 3 | Locate an active category (is_active=1) | Green toggle switch in "On" position |
| 4 | Click the status toggle switch | AJAX POST to `/transport/fine-category/{id}/toggle-status` with `{is_active: false}` |
| 5 | **Verify**: `Gate::authorize('tenant.fine-category.update')` checked | Gate passes (user has permission) |
| 6 | **Verify**: `$request->validate(['is_active' => 'required\|boolean'])` | Validation passes |
| 7 | **Verify**: `$record = TptFineCategory::findOrFail($id)` | Record found |
| 8 | **Verify**: `$record->is_active = $request->boolean('is_active')` | is_active set to false |
| 9 | **Verify**: `$record->save()` | DB updated |
| 10 | **Verify**: `activityLog($record, 'Toggled', [...])` called | Activity log entry created |
| 11 | **Verify**: JSON response `{"success":true, "is_active": false, "message": "..."}` | Response received |
| 12 | **Verify**: Toggle switch moves to "Off" (grey/red) position | Visual confirmation |

### TC-P-14: Soft delete category

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.fine-category.delete` permission | Login successful |
| 2 | Navigate to Fine Category tab | Category list with action buttons |
| 3 | Click delete (trash icon) on an active category | Confirmation dialog (if any) |
| 4 | Confirm deletion | DELETE request to `/transport/fine-category/{id}` |
| 5 | **Verify**: `Gate::authorize('tenant.fine-category.delete')` | Gate passes |
| 6 | **Verify**: `$record = TptFineCategory::findOrFail($id)` | Record found |
| 7 | **Verify**: `$record->delete()` called | `deleted_at` timestamp set |
| 8 | **CRITICAL**: Verify `is_active` is NOT set to false before delete | `is_active` retains original value (unlike Route/Shift pattern) |
| 9 | **Verify**: `activityLog($record, 'Trashed', [...])` called | Activity log entry created |
| 10 | **Verify**: Redirect to `transport.transport-master.index?tab=fine_category` | Success |
| 11 | **Verify**: Flash message `flash('deleted.fine_category')` | Success toast |
| 12 | **Verify**: Category no longer visible in active list | Row disappeared |
| 13 | **Verify**: Category visible in trash (navigate to `/transport/fine-category/trash/view`) | Shows in trash with "Deleted" badge |

### TC-P-17: Force delete trashed category

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.fine-category.forceDelete` permission | Login successful |
| 2 | Navigate to trash: `GET /transport/fine-category/trash/view` | Trashed categories list |
| 3 | Locate a trashed category | Row with "Deleted" badge |
| 4 | Click permanent delete (red X icon) | DELETE request to `/transport/fine-category/{id}/force-delete` |
| 5 | **Verify**: `Gate::authorize('tenant.fine-category.forceDelete')` | Gate passes |
| 6 | **Verify**: `TptFineCategory::withTrashed()->findOrFail($id)` | Record found even though soft-deleted |
| 7 | **Verify**: `$record->forceDelete()` | Record permanently removed from DB |
| 8 | **Verify**: `activityLog($record, 'Force Deleted', [...])` | Activity log entry created |
| 9 | **Verify**: Redirect to `transport.transport-master.index?tab=fine_category` | Success |
| 10 | **Verify**: Flash message `flash('force_deleted.fine_category')` | Success toast |
| 11 | **Verify**: Record no longer exists in trash or active list | Fully removed |

### TC-N-02: Create with invalid initiated_by

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Login successful |
| 2 | Navigate to create page | Form displayed |
| 3 | Enter category_name = "Test" | Valid name |
| 4 | Select initiated_by = a custom value (or manipulate POST to send "Admin") | Dropdown only has Transport/Finance options |
| 5 | Submit form | Form submitted |
| 6 | **Verify**: If ENUM validation at DB level — MySQL error 1265 "Data truncated for column 'initiated_by'" | OR |
| 7 | **Verify**: If Request `in:Transport,Finance` catches it — "Initiated by must be Transport or Finance." | Validation error displayed |
| 8 | **Verify**: Record NOT created in DB | No new row |

### TC-D-03: Verify is_active NOT set to false before soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category with is_active=1 | Record created |
| 2 | Note the is_active value in DB | is_active = 1 |
| 3 | Delete the category (soft delete) | Success |
| 4 | Query DB with `withTrashed()`: `SELECT is_active, deleted_at FROM tpt_fine_category WHERE id = {id}` | `is_active = 1` (unchanged), `deleted_at` IS NOT NULL |
| 5 | Compare with ShiftController pattern: `$shift->is_active = false; $shift->save(); $shift->delete();` | **GAP**: FineCategory does NOT deactivate before delete |

### TC-CR-18: GAP — destroy() missing is_active=false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineCategoryController.php` | File loaded |
| 2 | Locate `destroy()` method at line 79 | Method visible |
| 3 | Review lines 83-84 | Only `$record->delete()` — NO `$record->is_active = false` |
| 4 | Compare with `ShiftController.php:124-126` | Shift: `$shift->is_active = false; $shift->save(); $shift->delete();` |
| 5 | Compare with `VehicleController.php:191-193` | Vehicle: `$vehicle->is_active = false; $vehicle->save(); $vehicle->delete();` |
| 6 | **Document**: FineCategory inconsistent — deletes without deactivating | **GAP** |

### TC-CR-19: GAP — update() missing change tracking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineCategoryController.php` | File loaded |
| 2 | Locate `update()` method at line 63 | Method visible |
| 3 | Review lines 67-68 | Only `$record->update($request->validated())` — NO `getOriginal()`/`getChanges()` |
| 4 | Compare with `ShiftController.php:85-98` | Shift captures old/new values per field |
| 5 | **Document**: FineCategory update has no field-level change tracking | **GAP**: activityLog only logs "Fine category updated." without details |

---

### TC-P-02: Create category — Finance initiated, no evidence

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form displayed |
| 2 | Enter category_name = "Fine Waiver" | Valid name |
| 3 | Select initiated_by = "Finance" | Dropdown |
| 4 | Leave evidence_required UNCHECKED | Checkbox off → boolean(false) |
| 5 | Click "Create Category" | POST to store |
| 6 | **Verify**: `prepareForValidation()`: `$this->boolean('evidence_required')` = false | Normalized |
| 7 | **Verify**: `TptFineCategory::create()` with evidence_required=0 | DB: evidence_required=0 |
| 8 | **Verify**: List shows Evidence = "No" (bg-secondary badge) | Badge displayed |

### TC-P-03: Create category with max-length name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form |
| 2 | Enter category_name = 100 chars (e.g., "A" x 100) | At VARCHAR(100) limit |
| 3 | Select initiated_by = "Transport" | Valid |
| 4 | Click Create | POST |
| 5 | **Verify**: Rules: `max:100` passes | 100 chars accepted |
| 6 | **Verify**: Created with 100-char name | DB stores full 100 chars |

### TC-P-04: Create duplicate category name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category "Late Fee" | Existing record |
| 2 | Create another category "Late Fee" | Same name |
| 3 | **Verify**: Created successfully | No unique constraint on name |
| 4 | List shows 2 entries named "Late Fee" | Both visible |

### TC-P-05: Edit category name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit page for "Late Fee" | `GET /fine-category/{id}/edit` |
| 2 | **Verify**: `Gate::authorize('tenant.fine-category.update')` | Authorized |
| 3 | **Verify**: `TptFineCategory::findOrFail($id)` | Record loaded |
| 4 | Change name to "Late Fee Revised" | Updated |
| 5 | Click Save | PUT to `/fine-category/{id}` |
| 6 | **Verify**: `Gate::authorize('tenant.fine-category.update')` in update() | Authorized |
| 7 | **Verify**: `$record->update($request->validated())` | DB updated |
| 8 | **Verify**: `activityLog($record, 'Updated', [...])` | Activity logged (NO change details) |
| 9 | **Verify**: Redirect + flash | Success |
| 10 | **Verify**: List shows "Late Fee Revised" | Updated name |

### TC-P-06: Edit initiated_by from Transport to Finance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit category currently "Transport" | Edit form |
| 2 | Change initiated_by to "Finance" | Dropdown changed |
| 3 | Save | `update()` called |
| 4 | **Verify**: `FineCategoryRequest@rules()`: `in:Transport,Finance` passes | Valid |
| 5 | DB: `SELECT initiated_by WHERE id = X` | "Finance" |

### TC-P-07: Edit evidence_required from Yes to No

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit category with evidence_required=true | Edit form, checkbox checked |
| 2 | Uncheck evidence_required | Checkbox off |
| 3 | Save | `update()` called |
| 4 | **Verify**: `prepareForValidation()` normalizes to false | Boolean false |
| 5 | DB: `evidence_required` = 0 | Updated |

### TC-P-09: Toggle status Inactive → Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate inactive category (is_active=0) | Grey toggle |
| 2 | Click toggle | AJAX POST with is_active=true |
| 3 | **Verify**: `$request->boolean('is_active')` = true | Normalized |
| 4 | **Verify**: `$record->is_active = true` | Saved |
| 5 | **Verify**: JSON `{success:true, is_active:true}` | Response |
| 6 | **Verify**: Toggle moves to green "On" | UI updated |

### TC-P-10: View category details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click view icon on category | GET `/fine-category/{id}` |
| 2 | **Verify**: `Gate::authorize('tenant.fine-category.view')` | Authorized |
| 3 | **Verify**: `TptFineCategory::findOrFail($id)` | Record found |
| 4 | **Verify**: Show page displays: Category Name, Initiated By, Evidence Required (Yes/No), Status (Active/Inactive), Created At | All fields |

### TC-P-11: Search category by name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to fine category tab | List with search bar |
| 2 | Enter "Late" in search input | Partial name |
| 3 | Click Search | GET with `search=Late` |
| 4 | **Verify**: `TptFineCategory::where('category_name', 'like', '%Late%')->latest()->paginate(20)` | Filtered results |
| 5 | **Verify**: Only categories containing "Late" shown | Filtered |

### TC-P-12: Filter by Active status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Status = "Active" from dropdown | status=1 |
| 2 | Click Search | `where('is_active', 1)` |
| 3 | **Verify**: Only is_active=1 records | Filtered |

### TC-P-13: Filter by Inactive status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Status = "Inactive" | status=0 |
| 2 | Click Search | `where('is_active', 0)` |
| 3 | **Verify**: Only is_active=0 records | Filtered |

### TC-P-15: View trashed list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash: `GET /fine-category/trash/view` | Trash page |
| 2 | **Verify**: `Gate::authorize('tenant.fine-category.restore')` | Authorized |
| 3 | **Verify**: `TptFineCategory::onlyTrashed()->latest('deleted_at')->paginate(20)` | Trashed records, 20/page, ordered by deleted_at desc |
| 4 | **Verify**: Columns: Category Name, Initiated By, Status="Deleted" badge, Action (restore+forceDelete) | Per trash.blade.php |

### TC-P-16: Restore soft-deleted category

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash | Trashed list |
| 2 | Click restore on a trashed category | GET to `/fine-category/{id}/restore` |
| 3 | **Verify**: `Gate::authorize('tenant.fine-category.restore')` | Authorized |
| 4 | **Verify**: `TptFineCategory::onlyTrashed()->findOrFail($id)` | Found in trash |
| 5 | **Verify**: `$record->restore()` | deleted_at = NULL |
| 6 | **Verify**: `activityLog($record, 'Restored', [...])` | Activity logged |
| 7 | **Verify**: Redirect + flash | Success |
| 8 | **Verify**: Category back in active list | Restored |

### TC-P-18: Pagination across 20+ records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 25 categories | 25 records |
| 2 | Navigate to fine category tab | Page 1 shows first 20 |
| 3 | Click page 2 | `?tab=fine_category&page=2` |
| 4 | **Verify**: Page 2 shows remaining 5 records | 20 per page |

### TC-P-19: Pagination with tab param preserved

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to fine category tab | URL: `?tab=fine_category` |
| 2 | Click page 2 | URL: `?tab=fine_category&page=2` |
| 3 | **Verify**: `$data->appends(['tab' => request('tab')])->links()` | Tab param in pagination links |

### TC-P-20: Clear search filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search for "Late" | Filtered |
| 2 | Click reset/refresh button | URL: `?tab=fine_category` (no search param) |
| 3 | **Verify**: All categories shown | Filter cleared |

### TC-N-01: Create with empty category_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create | Form |
| 2 | Leave category_name empty | Blank |
| 3 | Select initiated_by = "Transport" | Valid |
| 4 | Click Create | POST |
| 5 | **Verify**: Rule `category_name.required` | "The category name field is required." |

### TC-N-03: Create with category_name > 100 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create | Form |
| 2 | Enter 101-char name | Exceeds VARCHAR(100) |
| 3 | Click Create | POST |
| 4 | **Verify**: Rule `category_name.max:100` | "The category name must not be greater than 100 characters." |

### TC-N-04 through TC-N-09: Permission tests

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.fine-category.viewAny` | No permission |
| 2 | Navigate to index | `Gate::authorize()` → 403 |
| 3 | Login as user WITHOUT `tenant.fine-category.create` | No permission |
| 4 | Navigate to create | `Gate::authorize()` → 403 |
| 5 | POST to store | `Gate::authorize()` → 403 |
| 6 | Login as user WITHOUT `tenant.fine-category.update` | No permission |
| 7 | Navigate to edit | `Gate::authorize()` → 403 |
| 8 | PUT to update | `Gate::authorize()` → 403 |
| 9 | POST to toggle-status | `Gate::authorize()` → 403 |
| 10 | Login as user WITHOUT `tenant.fine-category.delete` | No permission |
| 11 | DELETE to destroy | `Gate::authorize()` → 403 |
| 12 | Login as user WITHOUT `tenant.fine-category.restore` | No permission |
| 13 | Navigate to trash | `Gate::authorize()` → 403 |
| 14 | GET to restore | `Gate::authorize()` → 403 |
| 15 | Login as user WITHOUT `tenant.fine-category.forceDelete` | No permission |
| 16 | DELETE to forceDelete | `Gate::authorize()` → 403 |

### TC-N-10 through TC-N-13: Non-existent ID tests

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/fine-category/99999` (show) | `findOrFail()` → 404 |
| 2 | GET `/fine-category/99999/edit` (edit) | `findOrFail()` → 404 |
| 3 | PUT `/fine-category/99999` (update) | `findOrFail()` → 404 |
| 4 | DELETE `/fine-category/99999` (destroy) | `findOrFail()` → 404 |

### TC-N-14: Restore non-trashed record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call `/fine-category/{id}/restore` on active (non-deleted) record | `onlyTrashed()->findOrFail()` → 404 |

### TC-N-15: Force delete active record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call forceDelete on active (non-deleted) record | `withTrashed()->findOrFail()` FINDS it (unlike restore) |
| 2 | **Verify**: `$record->forceDelete()` | Record deleted |
| 3 | **Note**: forceDelete uses `withTrashed()` → works on both active AND trashed | Different from restore which uses `onlyTrashed()` |

### TC-N-16: Toggle status invalid is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggle-status with `is_active="invalid"` | `$request->validate(['is_active' => 'required|boolean'])` fails |
| 2 | **Verify**: "The is_active field must be true or false." | Validation error |

### TC-N-17: Toggle status on non-existent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-status with id=99999 | `findOrFail()` → 404 |

### TC-D-01: Delete category that has fine masters (FK RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fine category with id=X | Category exists |
| 2 | Create fine master with fine_category_id=X | References category |
| 3 | Try to DELETE category X | DDL FK `fk_fm_fine_category` ON DELETE RESTRICT |
| 4 | **Verify**: Delete fails with FK constraint violation | MySQL error 1451 |
| 5 | **Note**: Cannot delete category while fine masters reference it | Must delete fine masters first |

### TC-D-02: Force delete — verify record removed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete category X | Trashed |
| 2 | Force delete category X | `forceDelete()` called |
| 3 | Query `TptFineCategory::withTrashed()->find(X)` | Not found (null) |
| 4 | Query `activity_log` for "Force Deleted" entry | Log exists |

### TC-D-04: Verify trashed() only returns soft-deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 categories, soft-delete 2 of them | Mix of active + trashed |
| 2 | Navigate to trash | Only 2 trashed records shown |
| 3 | Count = 2 | `onlyTrashed()` scope applied |

### TC-D-05: Verify trashed() ordered by latest deleted_at

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete category A at 10:00 | deleted_at = 10:00 |
| 2 | Delete category B at 10:05 | deleted_at = 10:05 |
| 3 | Navigate to trash | Category B shown first (latest deleted_at) |
| 4 | **Verify**: `latest('deleted_at')` clause | Most recent first |

### TC-BIZ-DEEP-01: index() uses paginate(20)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineCategoryController.php:18` | `TptFineCategory::latest()->paginate(20)` |
| 2 | 20 records per page | Consistent pagination |

### TC-BIZ-DEEP-02: store() uses $request->validated()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineCategoryController.php:34` | `TptFineCategory::create($request->validated())` |
| 2 | Only validated fields passed | Safe mass-assignment |

### TC-BIZ-DEEP-03: All methods redirect with tab param

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open store() line 40-42 | `->route('transport.transport-master.index', ['tab' => 'fine_category'])` |
| 2 | Same pattern in update(), destroy(), restore(), forceDelete() | Consistent redirect |

### TC-BIZ-DEEP-04: Category name length limit 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Rule: `category_name` → `max:100` | VARCHAR(100) in DDL |
| 2 | 101 chars → validation error | DB would truncate but request catches first |

### TC-BIZ-DEEP-05: No unique constraint on category_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for UNIQUE on category_name | NOT present |
| 2 | Duplicate names allowed | Multiple categories with same name |

### TC-BIZ-DEEP-06: DDL TINYINT PK limits to 255 records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open DDL line 373 | `id` TINYINT UNSIGNED — max 255 |
| 2 | Create 256th record | Integrity constraint violation |
| 3 | **Note**: Practical max = 255 categories | Design limitation |

### TC-BIZ-DEEP-07: Model lacks scopeActive()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptFineCategory.php` | No `scopeActive()` method |
| 2 | Compare with Shift, Vehicle, Route models | Others have scopeActive() |
| 3 | **Note**: is_active filter handled via blade search, not model scope | Different pattern |

### TC-BIZ-DEEP-08: is_active NOT in model $fillable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open model `$fillable` | `category_name`, `initiated_by`, `evidence_required`, `is_active` |
| 2 | **Actually**: is_active IS in fillable | Line 18 includes `is_active` |
| 3 | Correct — toggleStatus sets is_active directly via `$record->is_active = ...; $record->save()` | Fillable allows mass assignment |

### TC-BIZ-DEEP-09: Model casts boolean for is_active and evidence_required

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open model `$casts` | `evidence_required => boolean`, `is_active => boolean` |
| 2 | DB stores 1/0, model returns true/false | Proper casting |

### TC-BIZ-DEEP-10: fineMasters() hasMany relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open model line 27-29 | `$this->hasMany(TptFineMaster::class, 'fine_category_id')` |
| 2 | FK: `tpt_fine_master.fine_category_id` references `tpt_fine_category.id` | ON DELETE RESTRICT |

### TC-BIZ-DEEP-11: Controller manually finds record in destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `destroy($id)` line 79-84 | `$record = TptFineCategory::findOrFail($id); $record->delete()` |
| 2 | No route-model-binding | Manual lookup |

### TC-BIZ-DEEP-12: Same pattern for show(), edit(), update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `show($id)`: `findOrFail($id)` | Manual |
| 2 | `edit($id)`: `findOrFail($id)` | Manual |
| 3 | `update($id)`: `findOrFail($id)` | Manual |
| 4 | `toggleStatus($id)`: `findOrFail($id)` | Manual |
| 5 | All use manual `findOrFail($id)`, not route-model-binding | Consistent |

### TC-BIZ-DEEP-13: Flash messages use translation keys

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Store: `flash('created.fine_category')` | Translation key |
| 2 | Update: `flash('updated.fine_category')` | Translation key |
| 3 | Destroy: `flash('deleted.fine_category')` | Translation key |
| 4 | Restore: `flash('restored.fine_category')` | Translation key |
| 5 | ForceDelete: `flash('force_deleted.fine_category')` | Translation key |
| 6 | ToggleStatus: `flash('status_updated.fine_category')` | Translation key |
| 7 | **Note**: Uses translation keys (not hardcoded like PickupPointRoute) | Better pattern |

### TC-BIZ-DEEP-14: Index blade uses colspan=5 for empty state

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `index.blade.php:78` | `<td colspan="5">No fine categories found.</td>` |
| 2 | 5 columns: Name, Initiated By, Evidence, Status, Action | Correct colspan |

### TC-BIZ-DEEP-15: Status toggle in blade shows conditionally

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 59: `@can('tenant.fine-category.update')` | Toggle only for authorized |
| 2 | User without update permission → no toggle | Read-only status text |

### TC-BIZ-DEEP-16: Action column shows conditionally

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 69-71: `@canany(['view', 'update', 'delete'])` | Action column for any of 3 permissions |
| 2 | User with view only → sees show action | Conditional |

### TC-BIZ-DEEP-17: Edit form has is_active switch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `edit.blade.php` | Status switch included |
| 2 | is_active can be toggled on edit form (non-AJAX) | Form-based status change |

### TC-BIZ-DEEP-18: Evidence required badge colors

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | evidence_required=true → badge `bg-success` "Yes" | Green badge |
| 2 | evidence_required=false → badge `bg-secondary` "No" | Grey badge |

### TC-BIZ-DEEP-19: Index blade search form

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade search bar: input name="search" | Text input |
| 2 | Status filter: select name="status" with options All/Active/Inactive | Dropdown |
| 3 | Reset link: `route('transport.transport-master.index', ['tab' => 'fine_category'])` | Clears filters |

### TC-BIZ-DEEP-20: Store does not check for duplicate name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `store()` | No duplicate check |
| 2 | `FineCategoryRequest` rules | No `unique` rule on `category_name` |
| 3 | Two categories with same name allowed | Business decision |

### TC-BIZ-DEEP-21: Show page uses singular `record` variable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `show()`: `compact('record')` | Single record variable |
| 2 | `edit()`: `compact('record')` | Same variable name |
| 3 | `index()`: `compact('data')` | Different variable name (data vs record) |

### TC-BIZ-DEEP-22: Controller consistently uses $record variable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `store()`: `$record = TptFineCategory::create(...)` | Local variable |
| 2 | `show()`: `$record = TptFineCategory::findOrFail($id)` | Local |
| 3 | `update()`: `$record = TptFineCategory::findOrFail($id)` | Local |
| 4 | `destroy()`: `$record = TptFineCategory::findOrFail($id)` | Local |
| 5 | `restore()`: `$record = TptFineCategory::onlyTrashed()->findOrFail($id)` | Local |
| 6 | `forceDelete()`: `$record = TptFineCategory::withTrashed()->findOrFail($id)` | Local |
| 7 | `toggleStatus()`: `$record = TptFineCategory::findOrFail($id)` | Local |
| 8 | All methods use `$record` naming | Consistent |

### TC-BIZ-DEEP-23: toggleStatus returns JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `toggleStatus()` lines 154-158 | `return response()->json([...])` |
| 2 | `success: true` | Boolean |
| 3 | `is_active: $record->is_active` | Current boolean value |
| 4 | `message: flash('status_updated.fine_category')` | Translated message |

### TC-BIZ-DEEP-24: Invoice/created_at vs updated_at

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record | `created_at` and `updated_at` both set to now |
| 2 | Update record | `updated_at` refreshed, `created_at` unchanged |

### TC-BIZ-DEEP-25: Soft delete sets deleted_at but keeps record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `destroy()` → `$record->delete()` | `deleted_at` = now |
| 2 | `TptFineCategory::find($id)` | null (excludes soft-deleted) |
| 3 | `TptFineCategory::withTrashed()->find($id)` | Record exists with deleted_at set |

### TC-BIZ-DEEP-26: Restore clears deleted_at

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `restore()` → `$record->restore()` | `deleted_at` = NULL |
| 2 | `TptFineCategory::find($id)` | Record found (no longer excluded) |

### TC-BIZ-DEEP-27: Force delete removes record permanently

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `forceDelete()` → `$record->forceDelete()` | Record deleted from DB |
| 2 | `TptFineCategory::withTrashed()->find($id)` | null (completely gone) |

### TC-BIZ-DEEP-28: Activity log entries have consistent message formatting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Created: "Fine category created." | Lowercase sentence |
| 2 | Updated: "Fine category updated." | Lowercase sentence |
| 3 | Trashed: "Fine category trashed." | Lowercase sentence |
| 4 | Restored: "Fine category restored." | Lowercase sentence |
| 5 | Force Deleted: "Fine category permanently deleted." | Full sentence |
| 6 | Toggled: "Fine category status updated." | Full sentence |

### TC-BIZ-DEEP-29: Controller does not validate soft-delete double-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete already soft-deleted record | `findOrFail($id)` → 404 (soft-deleted excluded) |
| 2 | Cannot delete same record twice | Protected by default SoftDeletes scope |

### TC-BIZ-DEEP-30: Index blade table responsive structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `<table class="table table-sm">` | Bootstrap table |
| 2 | `<thead>` with 5 columns | Proper header |
| 3 | `<tbody>` with `@forelse` | Data or empty state |
| 4 | `@empty` → "No fine categories found." | Empty state |

### TC-BIZ-DEEP-31: Pagination links with appends

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$data->appends(request()->query())->links()` | Preserves all query params |
| 2 | Tab param preserved across pages | `?tab=fine_category&page=2` |

### TC-BIZ-DEEP-32: Model has no date casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open model `$casts` | `evidence_required`, `is_active` only |
| 2 | `created_at`, `updated_at`, `deleted_at` handled by Laravel default | Carbon instances |

### TC-BIZ-DEEP-33: DDL has_default values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `initiated_by` DEFAULT 'Transport' | Default value |
| 2 | `evidence_required` DEFAULT 0 | Default false |
| 3 | `is_active` DEFAULT 1 | Default true |

### TC-BIZ-DEEP-34: Controller index uses latest() ordering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `TptFineCategory::latest()->paginate(20)` | Ordered by `created_at` DESC |
| 2 | Newest categories shown first | Reverse chronological |

### TC-BIZ-DEEP-35: No search or filter query methods in controller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `index()` | No `when(request('search'))` closure |
| 2 | Search/filter handled via `<x-backend.tab.search-bar>` component | Search form submits to same URL with GET params |
| 3 | Component handles filtering internally | Not in controller |

### TC-BIZ-DEEP-36: Evidence required boolean normalization in request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `prepareForValidation()`: `$this->merge(['evidence_required' => $this->boolean('evidence_required')])` | Converts checkbox to boolean |
| 2 | Checkbox checked → true | Normalized |
| 3 | Checkbox unchecked → false | Normalized |

### TC-BIZ-DEEP-37: Request authorize gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `FineCategoryRequest.authorize()` | POST → create, non-POST → update |
| 2 | Controller also calls `Gate::authorize()` | Double auth for store/update |

### TC-BIZ-DEEP-38: Created category inherits default is_active=1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create category without setting is_active | `is_active` defaults to 1 (DDL DEFAULT + model $attributes) |
| 2 | `$record->is_active` = true | Active by default |

### TC-BIZ-DEEP-39: DDL no unique index on category_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for UNIQUE constraint on category_name | NOT present |
| 2 | Multiple categories can share name | No DB-level uniqueness |

### TC-BIZ-DEEP-40: TINYINT UNSIGNED PK capacity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `id` TINYINT UNSIGNED → range 0-255 | Max 255 categories |
| 2 | After 255 records, INSERT fails | PK overflow |

### TC-BIZ-DEEP-41: Evidence required badge display logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `@if($item->evidence_required)` → green badge | True → "Yes" |
| 2 | `@else` → grey badge | False → "No" |

### TC-BIZ-DEEP-42: Initiated by dropdown has 2 options

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form: `<select name="initiated_by">` | 2 options: Transport, Finance |
| 2 | ENUM DDL: `ENUM('Transport','Finance')` | Only these values allowed |

### TC-BIZ-DEEP-43: Soft-deleted records can be restored multiple times

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete → restore → delete again | Second delete possible |
| 2 | `restore()` sets deleted_at=NULL | Clean slate |

### TC-BIZ-DEEP-44: ForceDelete on already-force-deleted record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force delete record X | Permanently removed |
| 2 | Call forceDelete again on same ID | `withTrashed()->findOrFail()` → 404 (gone) |

### TC-BIZ-DEEP-45: ToggleStatus AJAX error response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$record->save()` returns true → success JSON | 200 with success:true |
| 2 | If save() returns false → no error handling | Controller does NOT handle save() failure |

### TC-BIZ-DEEP-46: All controller methods return appropriate HTTP codes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET → 200 (views) | Success |
| 2 | POST → 302 (redirect) | Redirect |
| 3 | DELETE → 302 (redirect) | Redirect |
| 4 | toggleStatus POST → 200 (JSON) | JSON |
| 5 | Gate fails → 403 | Forbidden |
| 6 | findOrFail fails → 404 | Not found |

### TC-BIZ-DEEP-47: Create and edit views share similar structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Both have breadcrumb + card + form | Consistent layout |
| 2 | Create: no is_active toggle | Status defaults to active |
| 3 | Edit: has is_active toggle | Can change status via edit form |

### TC-BIZ-DEEP-48: Trash blade shows "Deleted" badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trash blade line 10-15: Status column shows "Deleted" badge | Visual indicator |
| 2 | Action column: restore + forceDelete icons | Two actions available |

### TC-BIZ-DEEP-49: DDL columns without default values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `category_name` VARCHAR(100) NOT NULL | Required, no default |
| 2 | Validation enforces required | DB constraint backup |

### TC-BIZ-DEEP-50: Activity log entry not wrapped in DB transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `store()`: `create()` then `activityLog()` | No DB::beginTransaction |
| 2 | If activityLog fails, record still created | No atomicity |
| 3 | Same pattern in update(), destroy(), etc. | All lack transaction wrapping |

### CODE-TRACE: index() method full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.fine-category.viewAny')` | Authorization check |
| 2 | `TptFineCategory::latest()->paginate(20)` | Query: `SELECT * FROM tpt_fine_category ORDER BY created_at DESC LIMIT 20 OFFSET 0` |
| 3 | `compact('data')` | View receives `$data` variable |
| 4 | View renders table rows | Paginated list |

### CODE-TRACE: create() method full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.fine-category.create')` | Authorization check |
| 2 | `return view('transport::fine-category.create')` | Create form displayed |
| 3 | Form has: category_name (text), initiated_by (select with Transport/Finance), evidence_required (checkbox) | 3 fields |

### CODE-TRACE: store() method full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `FineCategoryRequest` instantiated | Request object |
| 2 | `authorize()`: POST → `Gate::allows('tenant.fine-category.create')` | Authorization |
| 3 | `rules()`: category_name required|max:100, initiated_by required|in:Transport,Finance, evidence_required nullable|boolean | Validation rules |
| 4 | `prepareForValidation()`: `$this->boolean('evidence_required')` | Checkbox normalized |
| 5 | If validation fails → redirect back with errors | 302 with $errors |
| 6 | `FineCategoryController::store()` called | Method entry |
| 7 | `Gate::authorize('tenant.fine-category.create')` | Double auth |
| 8 | `$request->validated()` returns only validated fields | Safe array |
| 9 | `TptFineCategory::create([...])` | INSERT query |
| 10 | `activityLog($record, 'Created', [...])` | Activity log INSERT |
| 11 | `redirect()->route('transport.transport-master.index', ['tab' => 'fine_category'])` | 302 redirect |
| 12 | `->with('success', flash('created.fine_category'))` | Flash session data |

### CODE-TRACE: update() method full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `FineCategoryRequest` instantiated | Request object |
| 2 | `authorize()`: non-POST → `Gate::allows('tenant.fine-category.update')` | Authorization |
| 3 | `rules()`: same as create | Validation |
| 4 | `prepareForValidation()` | Boolean normalize |
| 5 | `FineCategoryController::update()` called | Method entry |
| 6 | `Gate::authorize('tenant.fine-category.update')` | Double auth |
| 7 | `TptFineCategory::findOrFail($id)` | SELECT query |
| 8 | `$record->update($request->validated())` | UPDATE query |
| 9 | `activityLog($record, 'Updated', [...])` | Activity log (NO change tracking) |
| 10 | `redirect()->route(..., ['tab' => 'fine_category'])` | 302 redirect |

### CODE-TRACE: destroy() method full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.fine-category.delete')` | Authorization |
| 2 | `TptFineCategory::findOrFail($id)` | SELECT (finds only non-deleted) |
| 3 | `$record->delete()` | UPDATE `deleted_at` = now() |
| 4 | `activityLog($record, 'Trashed', [...])` | Activity log |
| 5 | **GAP**: No `is_active=false` before delete | Route/Shift pattern has this |

### CODE-TRACE: toggleStatus() method full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.fine-category.update')` | Authorization |
| 2 | `$request->validate(['is_active' => 'required|boolean'])` | Inline validation |
| 3 | `TptFineCategory::findOrFail($id)` | SELECT |
| 4 | `$record->is_active = $request->boolean('is_active')` | Boolean assignment |
| 5 | `$record->save()` | UPDATE `is_active` |
| 6 | `activityLog($record, 'Toggled', [...])` | Activity log |
| 7 | `return response()->json([...])` | JSON response |

### CODE-TRACE: restore() method full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.fine-category.restore')` | Authorization |
| 2 | `TptFineCategory::onlyTrashed()->findOrFail($id)` | SELECT with WHERE deleted_at IS NOT NULL |
| 3 | `$record->restore()` | UPDATE `deleted_at` = NULL |
| 4 | `activityLog($record, 'Restored', [...])` | Activity log |
| 5 | `redirect()->route(..., ['tab' => 'fine_category'])` | 302 redirect |

### CODE-TRACE: forceDelete() method full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.fine-category.forceDelete')` | Authorization |
| 2 | `TptFineCategory::withTrashed()->findOrFail($id)` | SELECT (finds both deleted AND non-deleted) |
| 3 | `$record->forceDelete()` | DELETE FROM tpt_fine_category WHERE id = X |
| 4 | `activityLog($record, 'Force Deleted', [...])` | Activity log |
| 5 | `redirect()->route(..., ['tab' => 'fine_category'])` | 302 redirect |

### CODE-TRACE: trashed() method full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.fine-category.restore')` | Authorization |
| 2 | `TptFineCategory::onlyTrashed()->latest('deleted_at')->paginate(20)` | SELECT with WHERE deleted_at IS NOT NULL ORDER BY deleted_at DESC |
| 3 | `compact('data')` | View receives trashed records |

### TC-BIZ-DEEP-51: Controller has 10 public methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count: index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus | 11 methods (including toggleStatus) |
| 2 | FineCategoryController has NO private helpers | No normalizeBoolean, no timeToMinutes, etc. |

### TC-BIZ-DEEP-52: All methods return either view, redirect, or JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | index/create/edit/show/trashed → view() | 5 view returns |
| 2 | store/update/destroy/restore/forceDelete → redirect() | 5 redirect returns |
| 3 | toggleStatus → response()->json() | 1 JSON return |

### TC-BIZ-DEEP-53: No DB::beginTransaction in any method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search for `DB::beginTransaction` | NOT found |
| 2 | Compare with PickupPointRoute which wraps all CUD in transactions | No atomicity guarantee |

### TC-BIZ-DEEP-54: No withTrashed/onlyTrashed inconsistency in index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `index()` uses `TptFineCategory::latest()` (no withTrashed) | Only non-deleted records |
| 2 | Correct — index should not show trashed | Consistent with other controllers |

### TC-BIZ-DEEP-55: forceDelete uses withTrashed (different from PickupPointRoute)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `FineCategoryController::forceDelete()`: `withTrashed()->findOrFail($id)` | Works on active AND trashed |
| 2 | `PickupPointRouteController::forceDelete()`: `onlyTrashed()->findOrFail($id)` | Only works on trashed |
| 3 | FineCategory pattern is MORE permissive | Can force-delete active records directly |

### TC-BIZ-DEEP-56: DDL has no FK to restrict category deletion from fine_master — actually there IS

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL line 395: `CONSTRAINT fk_fm_fine_category FOREIGN KEY (fine_category_id) REFERENCES tpt_fine_category(id) ON DELETE RESTRICT` | FK exists |
| 2 | Cannot delete category with fine masters | RESTRICT prevents deletion |

### TC-BIZ-DEEP-57: Model soft-deletes enabled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `use SoftDeletes` trait | Imported |
| 2 | DDL has `deleted_at` column | Nullable timestamp |

### TC-BIZ-DEEP-58: View variables naming

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | index + trashed → `compact('data')` | `$data` |
| 2 | create → no variables | Empty view |
| 3 | show, edit → `compact('record')` | `$record` |
| 4 | Consistent per view type | Predictable naming |

### TC-BIZ-DEEP-59: FineCategoryRequest rules for update same as create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `FineCategoryRequest@rules()` | Same for POST and non-POST |
| 2 | No conditional rules based on method | Identical validation |

### TC-BIZ-DEEP-60: Search bar component handles filtering logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `<x-backend.tab.search-bar>` | Reusable component |
| 2 | Passes search/status params via GET | Controller receives params |
| 3 | Component may apply `where` clauses | Not in controller code |

### TC-BIZ-DEEP-61: Evidence required checkbox in create form

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form line 45-51: `<input type="checkbox" name="evidence_required" value="1">` | Checkbox |
| 2 | Hidden field `evidence_required=0` before checkbox | Proper boolean submission |
| 3 | `prepareForValidation()` converts to boolean | Safe storage |

### TC-BIZ-DEEP-62: Initiated by dropdown options

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | "Transport" → value="Transport" | Option 1 |
| 2 | "Finance" → value="Finance" | Option 2 |
| 3 | ENUM matches dropdown values | Consistent |

### TC-BIZ-DEEP-63: Activity log entries have description field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Created: message = 'Fine category created.' | Descriptive |
| 2 | Updated: message = 'Fine category updated.' | Descriptive (no field details) |
| 3 | Trashed: message = 'Fine category trashed.' | Descriptive |
| 4 | Restored: message = 'Fine category restored.' | Descriptive |
| 5 | Force Deleted: message = 'Fine category permanently deleted.' | Descriptive |
| 6 | Toggled: message = 'Fine category status updated.' | Descriptive |

### TC-BIZ-DEEP-64: No pagination parameters in URL on first load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to tab | URL: `?tab=fine_category` |
| 2 | Page 1 shows (no page param) | Default |

### TC-BIZ-DEEP-65: Status filter values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | status="" (All) → no filter | All records |
| 2 | status=1 (Active) → `where('is_active', 1)` | Active only |
| 3 | status=0 (Inactive) → `where('is_active', 0)` | Inactive only |

### TC-BIZ-DEEP-66: Controller passes no additional data to create view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `create()` returns `view('transport::fine-category.create')` | No compact data |
| 2 | Dropdown values hardcoded in blade | Static Transport/Finance options |

### TC-BIZ-DEEP-67: Controller passes single record to edit and show

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `edit()`: `compact('record')` | Single TptFineCategory instance |
| 2 | `show()`: `compact('record')` | Same structure |

### TC-BIZ-DEEP-68: No AJAX endpoints in FineCategoryController

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search for `response()->json()` | Only in toggleStatus |
| 2 | No getStudents, getRoutes, getSections, etc. | Simple CRUD only |

### TC-BIZ-DEEP-69: All methods accept $id parameter (no route model binding)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `show($id)`, `edit($id)`, `update(Request, $id)`, `destroy($id)`, `restore($id)`, `forceDelete($id)`, `toggleStatus(Request, $id)` | All use `$id` |
| 2 | No route-model-binding: `FineCategory $record` | Not used |

### TC-BIZ-DEEP-70: Translated flash messages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `flash('created.fine_category')` → reads from translation file | Translatable |
| 2 | `flash('updated.fine_category')` | Translatable |
| 3 | `flash('deleted.fine_category')` | Translatable |
| 4 | `flash('restored.fine_category')` | Translatable |
| 5 | `flash('force_deleted.fine_category')` | Translatable |
| 6 | `flash('status_updated.fine_category')` | Translatable |

### TC-BIZ-DEEP-71: Empty state text

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Index empty: "No fine categories found." | colspan=5 |
| 2 | Trash empty: likely similar message | colspan=5 |

### TC-BIZ-DEEP-72: DDL ENGINE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL likely uses InnoDB | FK support |
| 2 | CHARSET utf8mb4 | Unicode support |

### TC-BIZ-DEEP-73: Controller does not validate evidence_required at model level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$fillable` includes `evidence_required` | Mass assignable |
| 2 | No model-level `$casts` for boolean → actually there IS | `evidence_required => boolean` in casts |

### TC-BIZ-DEEP-74: TINYINT max value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | TINYINT UNSIGNED max = 255 | 255 categories max |
| 2 | After 255 → MySQL error 1062 (if PK auto-increment fails) or 1264 (out of range) | PK overflow |

### TC-BIZ-DEEP-75: All CRUD methods lack transaction wrapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | store: create + activityLog | No transaction |
| 2 | update: findOrFail + update + activityLog | No transaction |
| 3 | destroy: findOrFail + delete + activityLog | No transaction |
| 4 | restore: onlyTrashed + restore + activityLog | No transaction |
| 5 | forceDelete: withTrashed + forceDelete + activityLog | No transaction |

### TC-BIZ-DEEP-76: Evidence_required parameter name matches DB column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request field: `evidence_required` | Matches column |
| 2 | Model `$fillable`: `evidence_required` | Matches |
| 3 | DDL column: `evidence_required` | Consistent naming |

### TC-BIZ-DEEP-77: Controller does not use $request->boolean for is_active in update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `update()` calls `$record->update($request->validated())` | Uses validated data |
| 2 | `FineCategoryRequest` does NOT include `is_active` in rules | is_active not validated in request |
| 3 | Edit form includes `is_active` switch | But is_active is NOT in `$request->validated()` — it's set separately |

### TC-BIZ-DEEP-78: Edit form submits is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit blade line 55: status switch with name="is_active" | is_active in update form |
| 2 | Model `$fillable` has `is_active` | Mass assignable |
| 3 | `$request->validated()` does NOT include is_active (not in rules) | `is_active` NOT in validated — but it's in `$request->all()` via `$fillable` |
| 4 | **Note**: $fillable allows is_active via `create()` or direct `$record->is_active = ...` | But update() uses `$request->validated()` which excludes is_active |

### TC-BIZ-DEEP-79: Update form NOT having is_active in validation rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `FineCategoryRequest@rules()` does NOT include `is_active` | Not validated |
| 2 | Edit form sends is_active | But update() uses `$request->validated()` → is_active stripped |
| 3 | `$record->update()` only updates validated fields | is_active NOT updated via edit form |
| 4 | **GAP**: Edit form has is_active switch but it has no effect | Status can only be changed via toggleStatus AJAX |

### TC-BIZ-DEEP-80: is_active only changeable via toggleStatus

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `toggleStatus()` sets is_active directly | `$record->is_active = $request->boolean('is_active')` |
| 2 | Edit form is_active has NO effect | `$request->validated()` excludes is_active |
| 3 | **Impact**: Edit form status switch is misleading | User thinks they changed status but it doesn't save |

### TC-BIZ-DEEP-81: No policy class for FineCategory

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search for `FineCategoryPolicy` | NOT found |
| 2 | `Gate::authorize()` uses permission string directly | No dedicated policy class |
| 3 | Permissions managed via generic `Gate::authorize('tenant.fine-category.*')` | String-based authorization |

### TC-BIZ-DEEP-82: Controller does not check for soft-deleted record in show()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `show($id)`: `TptFineCategory::findOrFail($id)` | `findOrFail` excludes soft-deleted |
| 2 | Accessing soft-deleted record via show → 404 | Cannot view trashed records directly |

### TC-BIZ-DEEP-83: Controller does not check for soft-deleted record in edit()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `edit($id)`: `TptFineCategory::findOrFail($id)` | Same as show — excludes trashed |
| 2 | Cannot edit trashed record | Must restore first |

### TC-BIZ-DEEP-84: Flash messages consistent pattern

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All CUD methods: `->with('success', flash('action.fine_category'))` | Flash key = `{past_tense}.fine_category` |
| 2 | Created: `created.fine_category` | Pattern |
| 3 | Updated: `updated.fine_category` | Pattern |
| 4 | Deleted: `deleted.fine_category` | Pattern |
| 5 | Restored: `restored.fine_category` | Pattern |
| 6 | Force deleted: `force_deleted.fine_category` | Pattern |
| 7 | Status updated: `status_updated.fine_category` | Pattern |

### TC-BIZ-DEEP-85: Store does not check for existing name (no unique validation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create "Late Fee" | Success |
| 2 | Create "Late Fee" again | Success (no unique constraint) |
| 3 | Two records with identical name | Duplicate allowed |

### TC-BIZ-DEEP-86: Model fineMasters() relationship for FK integrity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$category->fineMasters` → Collection of TptFineMaster | hasMany |
| 2 | Can eager load: `TptFineCategory::with('fineMasters')->get()` | Eager loading |
| 3 | **Note**: Controller never eager loads fineMasters | Not used in views |

### TC-BIZ-DEEP-87: Controller does not limit max records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No check for TINYINT max (255) | Unlimited until DB error |
| 2 | Create 256th record | PK auto-increment fails |

### TC-BIZ-DEEP-88: Search functionality details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search box: `<input type="text" name="search">` | Text input |
| 2 | Status filter: `<select name="status">` with 3 options | Dropdown |
| 3 | Search bar component submits GET with tab param | Preserves tab context |

### TC-BIZ-DEEP-89: Pagination 20 per page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `index()` paginate(20) | 20 records per page |
| 2 | `trashed()` paginate(20) | 20 records per page |
| 3 | Consistent pagination size | 20 across all lists |

### TC-BIZ-DEEP-90: Model initial `is_active` default

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Model `$attributes` not explicitly set for is_active | Relies on DDL DEFAULT 1 |
| 2 | New category without setting is_active | `is_active` = 1 |

### TC-BIZ-DEEP-91: restore uses onlyTrashed() — must restore from trash only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `restore($id)`: `onlyTrashed()->findOrFail($id)` | Must be soft-deleted |
| 2 | Cannot restore active record | 404 |

### TC-BIZ-DEEP-92: forceDelete uses withTrashed() — can delete any record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `forceDelete($id)`: `withTrashed()->findOrFail($id)` | Finds active OR trashed |
| 2 | Can force-delete active record | Direct permanent delete |

### TC-BIZ-DEEP-93: DDL default for evidence_required

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `evidence_required` DEFAULT 0 | Default false |
| 2 | New record without setting evidence_required | `evidence_required = 0` |

### TC-BIZ-DEEP-94: Controller does not validate max category name length against DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Validation: `max:100` | Matches DDL VARCHAR(100) |
| 2 | Request catches before DB truncation | Consistent |

### TC-BIZ-DEEP-95: No export/import functionality

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search for `Excel`, `Export`, `Import` | NOT found in controller |
| 2 | No bulk operations | Simple CRUD only |

### TC-BIZ-DEEP-96: Controller coverage gaps summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No is_active validation in FineCategoryRequest | Edit form status switch has no effect |
| 2 | No DB::beginTransaction/commit/rollback | CUD not atomic |
| 3 | No unique name validation | Duplicates allowed |
| 4 | No activityLog with change tracking | update() doesn't log changed fields |
| 5 | No is_active=false before soft-delete | Route/Shift pattern has this |

### TC-BIZ-DEEP-97: All permission strings follow tenant.entity.action pattern

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `tenant.fine-category.viewAny` | index |
| 2 | `tenant.fine-category.create` | create, store |
| 3 | `tenant.fine-category.view` | show |
| 4 | `tenant.fine-category.update` | edit, update, toggleStatus |
| 5 | `tenant.fine-category.delete` | destroy |
| 6 | `tenant.fine-category.restore` | trashed, restore |
| 7 | `tenant.fine-category.forceDelete` | forceDelete |

### TC-BIZ-DEEP-98: No permission for trashed view specifically

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | trashed() uses `Gate::authorize('tenant.fine-category.restore')` | Uses restore permission |
| 2 | No dedicated `tenant.fine-category.trashed` permission | Relies on restore |

### TC-BIZ-DEEP-99: View structure consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `transport::fine-category.index` | Index list |
| 2 | `transport::fine-category.create` | Create form |
| 3 | `transport::fine-category.edit` | Edit form |
| 4 | `transport::fine-category.show` | Detail view |
| 5 | `transport::fine-category.trashed` | Deleted records |
| 6 | View directory: `resources/views/transport/fine-category/` | 5 blade files |

### TC-BIZ-DEEP-100: Summary — FineCategory vs Syllabus comparison

| Dimension | FineCategory | Syllabus (slb_Lessons) |
|-----------|-------------|------------------------|
| Controller methods | 11 (incl toggleStatus) | 12 (incl toggleStatus) |
| Soft deletes | Yes | Yes |
| Form request | FineCategoryRequest | Custom per entity |
| Transactions | None | Likely has |
| Change tracking | None | Likely has |
| Permissions | 7 strings | Similar pattern |
| Activity log | Yes (no tracking) | Yes |

---

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: FineCategory | Date: 2026-07-21*
