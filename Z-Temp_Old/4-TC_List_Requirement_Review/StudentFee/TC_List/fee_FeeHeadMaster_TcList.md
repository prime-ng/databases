# Test Case List: Fee Head Master

## 1. Module Name
**StudentFee** (Prefix: `fee_`)

## 2. Feature Name
**Fee Head Master** — Core fee components catalog

## 3. Tab / Submodule
**Configuration** (Route: `GET /student-fee/configuration`, Tab: `fee-head-master`)

## 4. Reference Documents
- DDL: `pgdatabase/2-DDL_Tenant_Consolidated/StudentFee_DDL_v4.sql` (Table 1: fee_head_master)
- Controller: `Modules/StudentFee/app/Http/Controllers/FeeHeadMasterController.php`
- Store Request: `Modules/StudentFee/app/Http/Requests/StoreFeeHeadMasterRequest.php`
- Update Request: `Modules/StudentFee/app/Http/Requests/UpdateFeeHeadMasterRequest.php`
- ToggleStatus Request: `Modules/StudentFee/app/Http/Requests/ToggleStatusRequest.php`
- Model: `Modules/StudentFee/app/Models/FeeHeadMaster.php`
- Routes: `Modules/StudentFee/routes/web.php` (Lines 36-41)

## 5. Test Case Matrix

| # | Test Case | Precondition | Test Data / Steps | Expected Result | Actual Result | Status (⬜/✅/❌/◌) | V1 | V2 | Remarks |
|---|-----------|-------------|-------------------|----------------|---------------|-------------------|---|---|---|---------|
| TC-FHM-001 | View fee head list (index redirects to Configuration tab) | User has tenant.fee-head-master.viewAny permission | Navigate to GET /fee-head-master | Redirects to route('student-fee.configuration', ['tab' => 'fee-head-master']) with 302 | — | ⬜ | — | — | |
| TC-FHM-002 | View create fee head form | User has tenant.fee-head-master.create permission | Navigate to GET /fee-head-master/create | Returns 200, shows create form with head_type dropdown from sys_dropdown_table | — | ⬜ | — | — | |
| TC-FHM-003 | View create form without permission | User lacks tenant.fee-head-master.create | Navigate to GET /fee-head-master/create | Returns 403 Forbidden | — | ⬜ | — | — | |
| TC-FHM-004 | Create fee head with valid data | User has create permission | POST /fee-head-master with: code=TUIT, name=Tuition Fee, head_type_id=1, frequency=Monthly, is_refundable=0, tax_applicable=1, tax_percentage=18.00, display_order=1, is_active=1 | 302 Redirect to configuration tab with flash('created.fee_head_master'), record created in fee_head_master table, activity_log entry created | — | ⬜ | — | — | |
| TC-FHM-005 | Create fee head with duplicate code | Existing record with code='TUIT' | POST /fee-head-master with: code=TUIT, name=Duplicate | 302 Redirect back with validation error on 'code': The code has already been taken | — | ⬜ | — | — | |
| TC-FHM-006 | Create fee head - missing required fields | — | POST /fee-head-master with empty payload | 302 Redirect back with validation errors: code (required), name (required), head_type_id (required), frequency (required) | — | ⬜ | — | — | |
| TC-FHM-007 | Create fee head - invalid frequency value | — | POST /fee-head-master with: frequency=Biweekly | 302 Redirect back with validation error: frequency must be one of One-time,Monthly,Quarterly,Half-Yearly,Yearly | — | ⬜ | — | — | |
| TC-FHM-008 | Create fee head - tax_percentage forced to 0 when tax_applicable=false | — | POST /fee-head-master with: tax_applicable=0, tax_percentage=18.00 | Record saved with tax_percentage=0.00 (controller forces 0) | — | ⬜ | — | — | |
| TC-FHM-009 | Create fee head - tax_percentage when tax_applicable=true | — | POST /fee-head-master with: tax_applicable=1, tax_percentage=18.00 | Record saved with tax_percentage=18.00 | — | ⬜ | — | — | |
| TC-FHM-010 | Create fee head - tax_percentage exceeds 100 | — | POST /fee-head-master with: tax_applicable=1, tax_percentage=150 | 302 Redirect back with validation error: tax_percentage may not be greater than 100 | — | ⬜ | — | — | |
| TC-FHM-011 | View single fee head details | Existing FeeHeadMaster record with ID=1, user has view permission | GET /fee-head-master/1 | Returns 200, shows fee head details with all fields | — | ⬜ | — | — | |
| TC-FHM-012 | View single fee head - not found | ID=9999 does not exist | GET /fee-head-master/9999 | Returns 404 Not Found | — | ⬜ | — | — | |
| TC-FHM-013 | View single fee head without permission | User lacks tenant.fee-head-master.view | GET /fee-head-master/1 | Returns 403 Forbidden | — | ⬜ | — | — | |
| TC-FHM-014 | View edit fee head form | Existing record, user has update permission | GET /fee-head-master/1/edit | Returns 200, form pre-filled with existing data, head_type dropdown populated | — | ⬜ | — | — | |
| TC-FHM-015 | Update fee head with valid data | Existing record ID=1 | PUT /fee-head-master/1 with: name=Updated Name, description=Updated desc | 302 Redirect to config tab, record updated with new values, activity_log entry created | — | ⬜ | — | — | |
| TC-FHM-016 | Update fee head - code unique ignored on self | Existing record ID=1 with code=TUIT | PUT /fee-head-master/1 with: code=TUIT (same code) | 302 Redirect, update succeeds (unique validation ignores self) | — | ⬜ | — | — | |
| TC-FHM-017 | Update fee head - code conflict with another record | Record ID=1 (TUIT), Record ID=2 (TRAN) | PUT /fee-head-master/1 with: code=TRAN | 302 Redirect back with validation error: code already taken | — | ⬜ | — | — | |
| TC-FHM-018 | Update fee head without permission | User lacks update permission | PUT /fee-head-master/1 with valid data | Returns 403 Forbidden | — | ⬜ | — | — | |
| TC-FHM-019 | Delete (soft) fee head | Existing record ID=1, user has delete permission | DELETE /fee-head-master/1 | 302 Redirect to config tab, record.is_active=0, deleted_at populated, activity_log 'Trashed' entry created | — | ⬜ | — | — | |
| TC-FHM-020 | Delete fee head without permission | User lacks delete permission | DELETE /fee-head-master/1 | Returns 403 Forbidden | — | ⬜ | — | — | |
| TC-FHM-021 | View trashed fee heads | At least one soft-deleted record exists, user has restore permission | GET /fee-head-master/trash/view | Returns 200, shows paginated list of onlyTrashed records | — | ⬜ | — | — | |
| TC-FHM-022 | Restore fee head from trash | Soft-deleted record ID=1, user has restore permission | GET /fee-head-master/1/restore | 302 Redirect to trashed route, record restored, deleted_at=null, is_active=1, activity_log 'Restored' entry | — | ⬜ | — | — | |
| TC-FHM-023 | Force delete fee head | Trashed record ID=1, user has forceDelete permission | DELETE /fee-head-master/1/force-delete | 302 Redirect to trashed route, record permanently deleted from DB, activity_log 'Deleted' entry | — | ⬜ | — | — | |
| TC-FHM-024 | Toggle status on fee head (activate) | Existing record with is_active=0, user has status permission | POST /fee-head-master/1/toggle-status with: is_active=1 | JSON 200: {success: true, is_active: 1, message: flash('status_updated.fee_head_master')}, DB updated | — | ⬜ | — | — | |
| TC-FHM-025 | Toggle status on fee head (deactivate) | Existing record with is_active=1 | POST /fee-head-master/1/toggle-status with: is_active=0 | JSON 200: {success: true, is_active: 0}, DB updated | — | ⬜ | — | — | |
| TC-FHM-026 | Toggle status without permission | User lacks status permission | POST /fee-head-master/1/toggle-status | Returns 403 Forbidden | — | ⬜ | — | — | |
| TC-FHM-027 | Create fee head with all nullable fields as null | — | POST /fee-head-master with: code=TEST, name=Test, head_type_id=1, frequency=Monthly (only required fields) | Record created, nullable fields (description, account_head_code) stored as null, booleans default to false | — | ⬜ | — | — | |
| TC-FHM-028 | Code field max length validation (31 chars) | — | POST /fee-head-master with: code=A very long code that exceeds thirty characters | Validation error: code must not exceed 30 characters | — | ⬜ | — | — | |
| TC-FHM-029 | Name field max length validation (101 chars) | — | POST /fee-head-master with: name=A very long name that exceeds one hundred characters but is used for testing validation... | Validation error: name must not exceed 100 characters | — | ⬜ | — | — | |
| TC-FHM-030 | Display order min value (0) | — | POST /fee-head-master with: display_order=0 | Validation error: display_order must be at least 1 | — | ⬜ | — | — | |

## 6. Business Rules Coverage

| Rule | TC Coverage | Status |
|------|-------------|--------|
| Tax calculation: tax_applicable=true → tax = amount × (tax_percentage/100) | TC-FHM-009 | ⬜ |
| Tax calculation: tax_applicable=false → tax = 0 (tax_percentage forced to 0) | TC-FHM-008 | ⬜ |
| Code is immutable after creation (update unique ignores self) | TC-FHM-016 | ⬜ |
| Deactivate before soft delete on destroy | TC-FHM-019 | ⬜ |
| Restore reactivates (is_active=true) | TC-FHM-022 | ⬜ |
| Inactive heads hidden from dropdowns (active() scope) | — | ⬜ |
| Refundable flag controls refund eligibility | — | ⬜ |

## 7. Edge Case Coverage

| Edge Case | TC Coverage | Status |
|-----------|-------------|--------|
| Duplicate unique code | TC-FHM-005 | ⬜ |
| Missing all required fields | TC-FHM-006 | ⬜ |
| Invalid enum frequency value | TC-FHM-007 | ⬜ |
| Tax percentage exceeds max (100) | TC-FHM-010 | ⬜ |
| View non-existent record (404) | TC-FHM-012 | ⬜ |
| Code max length (30 chars) exceeded | TC-FHM-028 | ⬜ |
| Name max length (100 chars) exceeded | TC-FHM-029 | ⬜ |
| Display order below minimum (0) | TC-FHM-030 | ⬜ |
| Store with only required fields (nullables) | TC-FHM-027 | ⬜ |

## 8. Known Issues / Gaps

1. **GAP-FHM-01**: `index()` redirects to configuration tab — the actual listing is rendered via `StudentFeeManagementController::configuration()`. No direct test for the tab view rendering in this controller.
2. **GAP-FHM-02**: `destroy()` does not check for existing references (e.g., fee_structure_details FK with RESTRICT) — deletion may fail with DB constraint error if head is used in structures.
3. **GAP-FHM-03**: `toggleStatus()` uses `$feeHeadMaster` implicit route model binding — if record is soft-deleted, implicit binding won't find it (only finds non-deleted records by default).
4. **GAP-FHM-04**: Flash messages use `flash()` helper keys — actual message text depends on translation files not documented here.
5. **GAP-FHM-05**: `update()` hardcodes success message 'Fee Head Master updated' instead of using `flash()` helper (inconsistent with other operations).

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/fee-head-master` | `fee-head-master.index` | index() → redirect |
| GET | `/fee-head-master/create` | `fee-head-master.create` | create() |
| POST | `/fee-head-master` | `fee-head-master.store` | store() |
| GET | `/fee-head-master/{fee_head_master}` | `fee-head-master.show` | show() |
| GET | `/fee-head-master/{fee_head_master}/edit` | `fee-head-master.edit` | edit() |
| PUT | `/fee-head-master/{fee_head_master}` | `fee-head-master.update` | update() |
| DELETE | `/fee-head-master/{fee_head_master}` | `fee-head-master.destroy` | destroy() |
| GET | `/fee-head-master/trash/view` | `fee-head-master.trashed` | trashedFeeHeadMasters() |
| GET | `/fee-head-master/{id}/restore` | `fee-head-master.restore` | restore() |
| DELETE | `/fee-head-master/{id}/force-delete` | `fee-head-master.forceDelete` | forceDelete() |
| POST | `/fee-head-master/{fee_head_master}/toggle-status` | `fee-head-master.toggleStatus` | toggleStatus() |

## 10. Execution Status

| Total TC | Passed | Failed | Blocked | Not Run |
|----------|--------|--------|---------|---------|
| 30 | 0 | 0 | 0 | 30 |
