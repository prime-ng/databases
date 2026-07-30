# hrs_IdCardTemplates_TcList

## Module: HrStaff → HR Masters → ID Card Templates

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | HR Masters → ID Card Templates |
| Feature | ID Card Templates |
| URL(s) | `GET /hr-staff/id-card-templates` (index — redirects to HR Masters tab) |
| | `GET /hr-staff/id-card-templates/{idCardTemplate}` (show) |
| | `GET /hr-staff/id-card-templates/{idCardTemplate}/edit` (edit) |
| | `POST /hr-staff/id-card-templates` (store) |
| | `PUT /hr-staff/id-card-templates/{idCardTemplate}` (update) |
| | `DELETE /hr-staff/id-card-templates/{idCardTemplate}` (destroy) |
| | `POST /hr-staff/id-card-templates/{idCardTemplate}/toggle-status` (toggleStatus) |
| | `GET /hr-staff/id-card-templates/trash/view` (trashed) |
| | `GET /hr-staff/id-card-templates/{id}/restore` (restore) |
| | `DELETE /hr-staff/id-card-templates/{id}/force-delete` (forceDelete) |
| Controller | `Modules\HrStaff\Http\Controllers\IdCardTemplateController` — full CRUD + toggle + trash/restore/forceDelete |
| Model(s) | `Modules\HrStaff\Models\IdCardTemplate` (table: `hrs_id_card_templates`) |
| Validation (Create / Update) | `Modules\HrStaff\Http\Requests\StoreIdCardTemplateRequest` (shared for both) |
| Policy | None (gate checks directly in controller) |
| Permissions | `hrs.documents.manage` (controller) / `hrs.id_card_template.manage` (form request) |
| Pagination | List: none (all records loaded); Trash: 15 records per page |
| Soft Deletes | Yes — `SoftDeletes` trait on `IdCardTemplate` |

---

## 2. Pre-conditions

- User must be logged in with `hrs.documents.manage` (or `hrs.id_card_template.manage`) permission
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

`IdCardTemplateController::index()` redirects to `hr-staff.menu.hrMasters` with `tab=id-card-templates`. `HrMenuController::hrMasters()` loads `IdCardTemplate::orderBy('name')->get()`. Trash view loads `IdCardTemplate::onlyTrashed()->orderBy('name')->paginate(15)`.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Templates List | `HrMenuController::hrMasters()` | `IdCardTemplate::orderBy('name')->get()` | None | None |
| Trashed Templates | `trashed()` | `IdCardTemplate::onlyTrashed()->orderBy('name')->paginate(15)` | None | 15/page |

---

## 4. Test Data Strategy

- Create 5-10 IdCardTemplate records directly in DB
- Create one with `is_default = true` for default template testing
- For pagination test: create 16+ soft-deleted templates
- Pre-test cleanup: truncate `hrs_id_card_templates`

---

## 5. Business Conditions

### 5.1 Database Schema — `hrs_id_card_templates`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, Auto Increment |
| BC-DB-02 | name | VARCHAR(150) | NOT NULL |
| BC-DB-03 | layout_json | JSON | NOT NULL |
| BC-DB-04 | is_default | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-05 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-06 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-07 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-08 | created_at | TIMESTAMP | NULL |
| BC-DB-09 | updated_at | TIMESTAMP | NULL |
| BC-DB-10 | deleted_at | TIMESTAMP | NULL |

### 5.2 Validation Rules — StoreIdCardTemplateRequest (Create / Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | name | required, string, max:200 | The Template Name field is required. / The Template Name must not exceed 200 characters. |
| BC-VAL-02 | layout_json | nullable, array | The Layout JSON must be a valid array. |
| BC-VAL-03 | is_default | required, boolean | The Default Template field is required. |
| BC-VAL-04 | is_active | required, boolean | The is active field is required. |

`prepareForValidation()` transforms:
- `layout_json`: if string, JSON-decodes to array (fallback `[]`)
- `is_default`: `$this->boolean('is_default', false)`
- `is_active`: `$this->boolean('is_active', true)`

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `hrs.documents.manage` (granted) | Full access to all CRUD, toggle, trash, restore, forceDelete |
| BC-AUTH-02 | `hrs.documents.manage` (denied) | All methods return 403 |
| BC-AUTH-03 | Guest (not logged in) | Redirect to /login |

> **Note:** The `StoreIdCardTemplateRequest::authorize()` checks `hrs.id_card_template.manage` (different string from the controller's `hrs.documents.manage`). Both effectively gate the same role.

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Index page loads | Redirects to HR Masters tab with tab=id-card-templates; all templates displayed alphabetically |
| BC-BIZ-02 | Create template with valid data | Template created; redirect to HR Masters tab with success message; activity logged |
| BC-BIZ-03 | Show single template | Template details displayed |
| BC-BIZ-04 | Edit template | Edit form with pre-filled template data displayed |
| BC-BIZ-05 | Update template | Template updated; redirect to HR Masters tab with success; activity logged |
| BC-BIZ-06 | Toggle status from active to inactive | is_active flipped; JSON response `{success: true, is_active: false, message: "Status updated successfully."}` |
| BC-BIZ-07 | Toggle status from inactive to active | is_active flipped to true; JSON response |
| BC-BIZ-08 | Soft delete (destroy) | is_active set to false; record soft-deleted; redirect to HR Masters tab with success |
| BC-BIZ-09 | View trashed templates | Soft-deleted templates listed paginated at 15 per page |
| BC-BIZ-10 | Restore from trash | Record restored; is_active set to true; redirect to trash view with success; activity logged |
| BC-BIZ-11 | Force delete from trash | Record permanently deleted; redirect to trash view with success; activity logged |
| BC-BIZ-12 | `prepareForValidation()` decodes JSON string layout_json | If layout_json sent as string, auto-decoded to array |
| BC-BIZ-13 | Empty trashed list | Trash view displays empty state |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | (none) | — | `hrs_id_card_templates` has no FK columns |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load HR Masters → ID Card Templates tab | Tab displays all templates alphabetically | — | — | ⬜ |
| TC-P02 | Create template with required fields only (name, is_default, is_active) | Template created; success flash; redirect to tab | — | — | ⬜ |
| TC-P03 | Create template with all fields (name, layout_json as array, is_default=true, is_active=true) | Template created with all values stored | — | — | ⬜ |
| TC-P04 | Create template with layout_json as JSON string | `prepareForValidation()` decodes string to array; created successfully | — | — | ⬜ |
| TC-P05 | Show template | Template details page renders with name, layout, status | — | — | ⬜ |
| TC-P06 | Edit template | Edit form pre-filled with template data | — | — | ⬜ |
| TC-P07 | Update template name and layout | Template updated; success flash; activity logged | — | — | ⬜ |
| TC-P08 | Toggle status active → inactive | is_active flips to false; JSON response with success=true, is_active=false | — | — | ⬜ |
| TC-P09 | Toggle status inactive → active | is_active flips to true; JSON response with success=true, is_active=true | — | — | ⬜ |
| TC-P10 | Soft delete a template | is_active=false; record soft-deleted; redirect with success | — | — | ⬜ |
| TC-P11 | View trashed templates list | Soft-deleted templates displayed, paginated at 15 | — | — | ⬜ |
| TC-P12 | Restore a trashed template | Record restored; is_active=true; redirect with success | — | — | ⬜ |
| TC-P13 | Force delete a trashed template | Record permanently removed; redirect with success | — | — | ⬜ |
| TC-P14 | Pagination in trash view (16+ trashed templates) | Page 1: 15 records; page 2: remaining records | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Create without required `name` | Validation error: "The Template Name field is required." | — | — | ⬜ |
| TC-N02 | Create with `name` exceeding 200 characters | Validation error: "The Template Name must not exceed 200 characters." | — | — | ⬜ |
| TC-N03 | Create without `is_default` | Validation error: "The Default Template field is required." | — | — | ⬜ |
| TC-N04 | Access any template page without `hrs.documents.manage` | 403 "This action is unauthorized." | — | — | ⬜ |
| TC-N05 | Guest user attempts to access | Redirect to /login | — | — | ⬜ |
| TC-N06 | Show/edit/update/delete non-existent template | 404 | — | — | ⬜ |
| TC-N07 | Restore non-existent template | 404 (from `findOrFail`) | — | — | ⬜ |
| TC-N08 | Force delete non-existent template | 404 (from `findOrFail`) | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Activity logged on create | `activityLog()` with type 'Created', message 'ID card template created.' | — | — | ⬜ |
| TC-D02 | A | Activity logged on update | `activityLog()` with type 'Updated', message 'ID card template updated.' | — | — | ⬜ |
| TC-D03 | A | Activity logged on toggle status | Activity logged for status toggle | — | — | ⬜ |
| TC-D04 | A | Activity logged on destroy | `activityLog()` with type 'Trashed' | — | — | ⬜ |
| TC-D05 | A | Activity logged on restore | `activityLog()` with type 'Restored' | — | — | ⬜ |
| TC-D06 | A | Activity logged on forceDelete | `activityLog()` with type 'Deleted' | — | — | ⬜ |
| TC-D07 | B | SoftDeletes trait on destroy | `deleted_at` set; `is_active=false` before delete | — | — | ⬜ |
| TC-D08 | B | Restore sets is_active=true | After restore, is_active = true | — | — | ⬜ |
| TC-D09 | C | `layout_json` stored as JSON | DDL shows JSON type; model casts to array | — | — | ⬜ |
| TC-D10 | D | Gate `hrs.documents.manage` on all controller methods | Every method calls `Gate::authorize('hrs.documents.manage')` | — | — | ⬜ |
| TC-D11 | E | Route names registered | All resource + custom routes resolve correctly | — | — | ⬜ |
| TC-D12 | F | `IdCardService::getTemplate()` consumes is_default flag | Service queries `where('is_default', true)->where('is_active', true)` | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns | name, layout_json, is_default, is_active, created_by, updated_by | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` | layout_json => array, is_default => boolean, is_active => boolean | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — `SoftDeletes` trait | Trait imported; deleted_at column in DDL | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — `Gate::authorize()` on every method | All methods gate for `hrs.documents.manage` | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — DB transactions | No explicit transaction wrapping (single-table writes) | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — activity logged on all state changes | create, update, toggle, destroy, restore, forceDelete all log activity | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `is_active=false` before soft delete | `destroy()` sets is_active=false then delete() | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — restore sets is_active=true | After restore(), is_active updated to true | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — JSON response from toggleStatus | Returns `response()->json([...])` with success, is_active, message | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — redirect on create/update/destroy | All redirect with flash success message | — | — | ◌ |
| TC-CR11 | CR | P1 | Request — `StoreIdCardTemplateRequest` `prepareForValidation()` | Decodes layout_json JSON string to array; normalizes booleans | — | — | ◌ |
| TC-CR12 | CR | P1 | Routes — resource + custom routes registered | All routes: index, store, show, edit, update, destroy, toggle-status, trashed, restore, force-delete | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model $fillable
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `IdCardTemplate.php` $fillable | Contains: name, layout_json, is_default, is_active, created_by, updated_by |

#### TC-CR02: Model $casts
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect $casts | layout_json => 'array', is_default => 'boolean', is_active => 'boolean' |

#### TC-CR03: Model SoftDeletes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect model | `use SoftDeletes;` present |
| 2 | Check DDL `hrs_id_card_templates` | `deleted_at` TIMESTAMP NULL exists |

#### TC-CR04: Gate::authorize() on all methods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect IdCardTemplateController | Every method has `Gate::authorize('hrs.documents.manage')` |

#### TC-CR05: DB transactions
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review | No `DB::transaction()` — single-model writes |

#### TC-CR06: Activity logged
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() | `activityLog()` with 'Created' |
| 2 | Inspect update() | `activityLog()` with 'Updated' |
| 3 | Inspect destroy() | `activityLog()` with 'Trashed' |
| 4 | Inspect restore() | `activityLog()` with 'Restored' |
| 5 | Inspect forceDelete() | `activityLog()` with 'Deleted' |

#### TC-CR07: is_active=false before soft delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect destroy() | `$idCardTemplate->update(['is_active' => false, 'updated_by' => auth()->id()])` before `->delete()` |

#### TC-CR08: Restore sets is_active=true
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect restore() line 125 | `$idCardTemplate->update(['is_active' => true])` after `$idCardTemplate->restore()` |

#### TC-CR09: JSON response from toggleStatus
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect toggleStatus() lines 77-81 | Returns `response()->json(['success' => true, 'is_active' => bool, 'message' => "Status updated successfully."])` |

#### TC-CR10: Redirect responses
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store(), update(), destroy() | All return `redirect()->route(...)->with('success', ...)` |

#### TC-CR11: prepareForValidation()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `StoreIdCardTemplateRequest.php` lines 36-49 | JSON string decoded to array; is_default and is_active normalized via `$this->boolean()` |

#### TC-CR12: Routes registered
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list --name=hr-staff.id-card-templates` | All resource + custom routes present |

### 7.1 Positive TC Steps

#### TC-P01: Load ID Card Templates tab
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /hr-staff/id-card-templates` | Redirected to `GET /hr-staff/hr-masters?tab=id-card-templates` |
| 2 | Verify templates list | All templates displayed sorted alphabetically by name |

#### TC-P02: Create template with required fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/hr-staff/id-card-templates` with name="Standard Card", is_default=1, is_active=1 | Redirect to HR Masters tab with success "ID card template created successfully." |
| 2 | Verify DB | Template record exists with name="Standard Card", is_default=1, is_active=1 |

#### TC-P03: Create template with all fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with name="Premium Card", layout_json={"color":"blue","fields":["photo","name"]}, is_default=0, is_active=1 | Success; layout_json stored as JSON |

#### TC-P04: Create with layout_json as JSON string
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with layout_json='{"color":"red"}' (string) | prepareForValidation() decodes; created successfully; layout_json stored as JSON object |

#### TC-P05: Show template
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/hr-staff/id-card-templates/1` | Template details displayed |

#### TC-P06: Edit template
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/hr-staff/id-card-templates/1/edit` | Edit form renders with pre-filled data |

#### TC-P07: Update template
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/hr-staff/id-card-templates/1` with name="Updated Card" | Success "ID card template updated successfully."; name changed |

#### TC-P08: Toggle active → inactive
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/hr-staff/id-card-templates/1/toggle-status` | JSON: `{"success":true,"is_active":false,"message":"Status updated successfully."}` |
| 2 | Verify DB | is_active = false |

#### TC-P09: Toggle inactive → active
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-status again | JSON: `{"success":true,"is_active":true,"message":"Status updated successfully."}` |

#### TC-P10: Soft delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/hr-staff/id-card-templates/1` | Redirect to tab with "ID card template removed successfully." |
| 2 | Verify DB | is_active=false; deleted_at set |

#### TC-P11: View trashed templates
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/hr-staff/id-card-templates/trash/view` | Soft-deleted templates listed paginated at 15 |

#### TC-P12: Restore template
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/hr-staff/id-card-templates/1/restore` | Redirect with "ID card template restored successfully." |
| 2 | Verify DB | deleted_at=null; is_active=true |

#### TC-P13: Force delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete template ID 2, then DELETE `/hr-staff/id-card-templates/2/force-delete` | Redirect with "ID card template permanently deleted." |
| 2 | Verify DB | Record removed from database |

#### TC-P14: Pagination in trash
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete 16 templates | 16 records trashed |
| 2 | GET `/hr-staff/id-card-templates/trash/view?page=1` | 15 records shown |
| 3 | GET `/hr-staff/id-card-templates/trash/view?page=2` | 1 record shown |

### 7.2 Negative TC Steps

#### TC-N01: Create without name
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST without name | Validation error: "The Template Name field is required." |

#### TC-N02: Name too long
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with name of 201 characters | Validation error: "The Template Name must not exceed 200 characters." |

#### TC-N03: Create without is_default
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST without is_default | Validation error: "The Default Template field is required." |

#### TC-N04: Access without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without `hrs.documents.manage` | Authenticated |
| 2 | Access any template route | 403 "This action is unauthorized." |

#### TC-N05: Guest access
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, access template route | Redirect to /login |

#### TC-N06: Non-existent template
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET/PUT/DELETE `/hr-staff/id-card-templates/99999` | 404 |

#### TC-N07: Restore non-existent
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/hr-staff/id-card-templates/99999/restore` | 404 |

#### TC-N08: Force delete non-existent
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/hr-staff/id-card-templates/99999/force-delete` | 404 |

### 7.3 Dependency TC Steps

#### TC-D01: Activity logged on create
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template "Test" | Success |
| 2 | Check activity log | Entry: type 'Created', message 'ID card template created.', name='Test' |

#### TC-D02: Activity logged on update
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update template name | Success |
| 2 | Check activity log | Entry: type 'Updated', message 'ID card template updated.' |

#### TC-D03: Activity logged on toggle status
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-status on a template | Success |
| 2 | Check activity log | Entry exists with appropriate type and message |

#### TC-D04: Activity logged on destroy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE a template (soft delete) | Success |
| 2 | Check activity log | Entry: type 'Trashed', message 'ID card template removed.' |

#### TC-D05: Activity logged on restore
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a previously deleted template | Success |
| 2 | Check activity log | Entry: type 'Restored', message 'ID card template restored.' |

#### TC-D06: Activity logged on forceDelete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a trashed template | Success |
| 2 | Check activity log | Entry: type 'Deleted', message 'ID card template permanently deleted.' |

#### TC-D07: SoftDeletes on destroy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Destroy template ID 1 | deleted_at populated; is_active=false |

#### TC-D08: Restore sets is_active=true
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore previously deleted template | deleted_at null; is_active=true |

#### TC-D09: layout_json as JSON
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL | `layout_json` column is JSON type |
| 2 | Check model | `$casts['layout_json']` => 'array' |

#### TC-D10: Gate on all methods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review controller | Every public method has `Gate::authorize('hrs.documents.manage')` |

#### TC-D11: Route names
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run route:list | All routes under `hr-staff.id-card-templates.*` prefix present |

#### TC-D12: Service consumes is_default
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check IdCardService::getTemplate() | Queries `where('is_default', true)->where('is_active', true)` |
