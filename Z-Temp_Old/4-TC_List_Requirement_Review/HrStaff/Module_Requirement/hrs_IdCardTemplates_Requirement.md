# ID Card Templates — Business Requirements

## What This Screen Does

The ID Card Templates screen allows HR Managers to create, edit, view, soft-delete, restore, and permanently delete school-configurable ID card layout templates. Each template stores a name and a JSON configuration defining the card layout fields, dimensions, and color scheme. One template can be marked as the default, which is used by the ID Card generation feature.

## When This Screen Is Used

- When HR Manager wants to create a new ID card design for the upcoming academic year
- When the school wants to switch to a different ID card layout or color scheme
- When an existing template is no longer needed and needs to be removed
- When a removed template needs to be restored
- When a template needs to be permanently purged from the system

## Default Data Load

The screen is accessed via the HR Masters tabbed page under the "ID Card Templates" tab. The `IdCardTemplateController::index()` method redirects to `hr-staff.menu.hrMasters` with `tab=id-card-templates`. The `HrMenuController::hrMasters()` loads `IdCardTemplate::orderBy('name')->get()` (no pagination — all templates loaded at once). The trashed templates view is loaded by `IdCardTemplateController::trashed()` at `GET /hr-staff/id-card-templates/trash/view` with `IdCardTemplate::onlyTrashed()->orderBy('name')->paginate(15)`.

## Key Fields at a Glance

**Template Identity**
- `name` — Human-readable template name (e.g., "Standard ID Card 2025-26")
- `is_default` — Boolean flag: exactly one template can be the default (enforced in business logic via IdCardService)
- `is_active` — Soft enable/disable; inactive templates are excluded from the default lookup

**Layout Configuration**
- `layout_json` — JSON object storing the card's field list, dimensions, color scheme, logo position, etc.

## Business Rules and Conditions

**Single Default Template.** Only one template can be marked as `is_default = true` at a time. The `IdCardService::getTemplate()` method returns the first active template with `is_default = true`.

**Soft Delete with Restore.** Templates use soft deletes. On destroy, `is_active` is set to `false` and the record is soft-deleted. On restore, `is_active` is set to `true` and the record is restored. Permanent deletion (`forceDelete`) bypasses soft delete entirely.

**Active-Only for Preview.** Only active templates (`is_active = true`) are eligible for use in ID card generation. Inactive templates remain visible in the HR Masters list but are not returned by the `active()` scope.

**JSON Layout.** The `layout_json` is stored as JSON and cast to array in the model. The `StoreIdCardTemplateRequest` has a `prepareForValidation()` method that auto-decodes JSON strings into arrays, ensuring the field is always an array for validation.

**Form-Request Authorization Mismatch.** The `StoreIdCardTemplateRequest::authorize()` checks `hrs.id_card_template.manage`, while the controller gate checks use `hrs.documents.manage`. Both effectively require HR Manager permissions, but use different permission strings. The controller gates are authoritative.

## Workflow Steps

**Creating a Template**
1. HR Manager navigates to HR Masters → ID Card Templates tab
2. System displays the list of existing templates
3. HR Manager clicks "Add New" (or equivalent button)
4. Fills in template name, sets as default if desired, configures layout JSON and active status
5. System validates, creates the template, logs activity, redirects to the HR Masters tab with success message

**Editing a Template**
1. HR Manager clicks edit on a template row
2. System loads the edit form with pre-filled template data
3. HR Manager modifies fields and saves
4. System validates, updates the template, logs activity, redirects to the HR Masters tab with success message

**Deleting, Restoring, and Force-Delete**
1. Delete: sets `is_active = false`, soft-deletes, redirects to HR Masters tab
2. Restore: restores the record, sets `is_active = true`, redirects to trash view
3. Force delete: permanently removes the record from the database, redirects to trash view

## Example Scenario

Sunshine Academy wants a new ID card design. HR Manager creates a template named "Sunshine ID Card 2025-26" with a blue color scheme, marks it as default. The next month, they update the template to change the background color. At year end, they retire the old template by deleting it (soft delete). Later they realize they need it back, so they restore it from trash.

## Related Screens

- **ID Card (Employee sub-page)** — Consumes the default template for ID card preview and PDF generation
- **HR Masters (hrMasters page)** — Tabbed container where ID Card Templates list is displayed alongside other HR master data

## Requirements

- `IdCardTemplateController` handles all CRUD with methods: `index()` (lines 21–24, redirect), `store()` (lines 29–46), `show()` (lines 51–55), `edit()` (lines 61–65), `toggleStatus()` (lines 71–82), `update()` (lines 87–102), `trashed()` (lines 107–114), `restore()` (lines 119–129), `forceDelete()` (lines 135–145), `destroy()` (lines 150–164)
- `index()` redirects to `hr-staff.menu.hrMasters` with `tab=id-card-templates`
- `toggleStatus()` returns JSON response: `{success: true, is_active: bool, message: "Status updated successfully."}`
- `trashed()` loads `IdCardTemplate::onlyTrashed()->orderBy('name')->paginate(15)`
- `restore($id)` uses `IdCardTemplate::onlyTrashed()->findOrFail($id)`, restores, sets `is_active = true`
- `forceDelete($id)` uses `IdCardTemplate::withTrashed()->findOrFail($id)` and `forceDelete()`
- `destroy()` sets `is_active = false`, `updated_by = auth()->id()`, then `delete()` (soft delete)
- Route names: resource routes under `hr-staff.id-card-templates.*` plus custom `hr-staff.id-card-templates.toggle-status`, `.trashed`, `.restore`, `.force-delete`
- All methods gate for `hrs.documents.manage` (controller) or `hrs.id_card_template.manage` (form request)
- Activity logged on create ('Created'), update ('Updated'), toggle ('Status toggled'), destroy ('Trashed'), restore ('Restored'), forceDelete ('Deleted')
- Policy: not explicitly defined — relies on Gate facade checks
- `StoreIdCardTemplateRequest` validates: `name` (required, string, max:200), `layout_json` (nullable, array), `is_default` (required, boolean), `is_active` (required, boolean); `prepareForValidation()` decodes JSON string to array for layout_json and normalizes booleans

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `hrs.documents.manage` | `store()`, `show()`, `edit()`, `toggleStatus()`, `update()`, `trashed()`, `restore()`, `forceDelete()`, `destroy()` | Controller gate — used for all methods |
| `hrs.id_card_template.manage` | `store()`, `update()` | Form request authorize — used only in `StoreIdCardTemplateRequest` |

## Logic Flow

**Page Load (`index()`).** Redirects to the HR Masters tabbed page with `tab=id-card-templates`. The `HrMenuController::hrMasters()` loads all templates with `IdCardTemplate::orderBy('name')->get()`.

**Show/Edit.** `show()` model-binds the template and renders view. `edit()` model-binds the template and renders the edit form.

**Create (`store()`).** Validates via `StoreIdCardTemplateRequest`. Sets `created_by`, `updated_by` from auth. Creates `IdCardTemplate`. Logs activity. Redirects to HR Masters tab with success flash.

**Update (`update()`).** Validates via same request. Merges `updated_by`. Updates model. Logs activity. Redirects to HR Masters tab with success flash.

**Toggle Status (`toggleStatus()`).** Flips `is_active` boolean. Updates `updated_by`. Returns JSON with new status and success message.

**Soft Delete (`destroy()`).** Sets `is_active = false`, sets `updated_by`, calls `delete()`. Logs activity. Redirects to HR Masters tab.

**Trash View (`trashed()`).** Loads only soft-deleted templates paginated at 15. Renders trash view.

**Restore (`restore()`).** Finds trashed record by ID. Calls `restore()` then sets `is_active = true`. Logs activity. Redirects to trash view.

**Force Delete (`forceDelete()`).** Finds record (including trashed). Calls `forceDelete()`. Logs activity. Redirects to trash view.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `name` | `required`, `string`, `max:200` | "The Template Name must not exceed 200 characters." |
| `layout_json` | `nullable`, `array` | "The Layout JSON must be a valid array." |
| `is_default` | `required`, `boolean` | "The Default Template field is required." |
| `is_active` | `required`, `boolean` | "The is active field is required." |

`prepareForValidation()` transforms:
- `layout_json`: if string, JSON-decode to array (fallback to `[]`)
- `is_default`: `$this->boolean('is_default', false)`
- `is_active`: `$this->boolean('is_active', true)`

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Required name missing | "The Template Name field is required." | Validation rule |
| Success — created | "ID card template created successfully." | Flash success |
| Success — updated | "ID card template updated successfully." | Flash success |
| Success — status toggled | "Status updated successfully." | JSON response |
| Success — removed | "ID card template removed successfully." | Flash success |
| Success — restored | "ID card template restored successfully." | Flash success |
| Success — permanently deleted | "ID card template permanently deleted." | Flash success |
| Missing permission | "This action is unauthorized." | 403 (Gate) |

## Success Scenarios

**SC-001 — Create Template.** HR Manager creates template named "Standard ID Card 2025-26" with layout_json = `{"color": "blue", "fields": ["photo", "name", "code"]}`, is_default = true, is_active = true. System creates the record, logs activity, redirects with success message.

**SC-002 — Toggle Status.** HR Manager toggles a template's is_active from true to false. System responds with JSON `{"success": true, "is_active": false, "message": "Status updated successfully."}`.

**SC-003 — Restore from Trash.** HR Manager views trashed templates, clicks restore on template ID 3. System restores the record, sets is_active = true, logs activity, redirects with success.

## Failure Scenarios

**FC-001 — Missing Permission.** User without `hrs.documents.manage` attempts to create a template. Returns 403 "This action is unauthorized."

**FC-002 — Non-existent Restore.** User tries to restore template ID 9999 which does not exist. System returns 404 (from `findOrFail`).

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `Modules\HrStaff\Models\IdCardTemplate` | Self | Primary table for this feature |
| `IdCardService` | Service | Consumes the template for ID card generation |
| `IdCardController` | Consumer | Uses `IdCardService::getTemplate()` which queries active + default templates |
| Activity Log | Service | `activityLog()` called on all state-changing operations |

**Table:** `hrs_id_card_templates`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED | PK, Auto Increment |
| name | VARCHAR(150) | NOT NULL |
| layout_json | JSON | NOT NULL |
| is_default | TINYINT(1) | NOT NULL DEFAULT 0 |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
