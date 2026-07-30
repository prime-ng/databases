# Test Case List: Fee Group Master

## 1. Module Name

**StudentFee** (Prefix: `fee_`)

## 2. Feature Name

**Fee Group Master** — Logical grouping of fee heads

## 3. Tab / Submodule

**Configuration** (Route: `GET /student-fee/configuration`, Tab: `fee-group-master`)

## 4. Reference Documents

- DDL: `pgdatabase/2-DDL_Tenant_Consolidated/StudentFee_DDL_v4.sql` (Tables 2-3: fee_group_master, fee_group_heads_jnt)
- Controller: `Modules/StudentFee/app/Http/Controllers/FeeGroupMasterController.php`
- Store Request: `Modules/StudentFee/app/Http/Requests/StoreFeeGroupMasterRequest.php`
- Update Request: `Modules/StudentFee/app/Http/Requests/UpdateFeeGroupMasterRequest.php`
- Model: `Modules/StudentFee/app/Models/FeeGroupMaster.php`
- Model: `Modules/StudentFee/app/Models/FeeGroupHeadsJnt.php`
- Routes: `Modules/StudentFee/routes/web.php` (Lines 43-49)

## 5. Test Case Matrix

| #          | Test Case                                                | Precondition                                                  | Test Data / Steps                                                                                                                                                             | Expected Result                                                                                                     | Actual Result | Status (⬜/✅/❌/◌) | V1  | V2  | Remarks |
| ---------- | -------------------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------- | ------------------- | --- | --- | ------- |
| TC-FGM-001 | View fee group list (index redirects)                    | User has viewAny permission                                   | GET /fee-group-master                                                                                                                                                         | 302 Redirect to route('student-fee.configuration', ['tab' => 'fee-group-master'])                                   | —             | ⬜                  | —   | —   |         |
| TC-FGM-002 | View create fee group form                               | User has create permission                                    | GET /fee-group-master/create                                                                                                                                                  | Returns 200, shows create form with active fee heads list                                                           | —             | ⬜                  | —   | —   |         |
| TC-FGM-003 | View create form without permission                      | User lacks create permission                                  | GET /fee-group-master/create                                                                                                                                                  | Returns 403 Forbidden                                                                                               | —             | ⬜                  | —   | —   |         |
| TC-FGM-004 | Create fee group with valid data (mandatory, with heads) | At least one FeeHeadMaster exists, user has create permission | POST /fee-group-master with: code=ACADEMIC, name=Academic Package, is_mandatory=1, display_order=1, heads[0]={head_id:1, is_optional:0, default_amount:null, display_order:1} | 302 Redirect to config tab, FeeGroupMaster created, FeeGroupHeadsJnt created in DB::transaction, activity_log entry | —             | ⬜                  | —   | —   |         |
| TC-FGM-005 | Create fee group with no heads (empty array)             | —                                                             | POST /fee-group-master with: code=EMPTY, name=Empty Group, heads=[]                                                                                                           | Group created with no junction records, redirects with success                                                      | —             | ⬜                  | —   | —   |         |
| TC-FGM-006 | Create fee group - missing required fields               | —                                                             | POST /fee-group-master with empty payload                                                                                                                                     | Validation errors: code (required), name (required)                                                                 | —             | ⬜                  | —   | —   |         |
| TC-FGM-007 | Create fee group - duplicate code                        | Existing record with code='ACADEMIC'                          | POST /fee-group-master with: code=ACADEMIC                                                                                                                                    | Validation error: code already taken                                                                                | —             | ⬜                  | —   | —   |         |
| TC-FGM-008 | Create fee group - invalid head_id in heads array        | head_id=9999 does not exist                                   | POST /fee-group-master with: heads[0]={head_id:9999}                                                                                                                          | Validation error: heads.0.head_id does not exist                                                                    | —             | ⬜                  | —   | —   |         |
| TC-FGM-009 | Create fee group - negative default_amount               | —                                                             | POST /fee-group-master with: heads[0]={head_id:1, default_amount:-100}                                                                                                        | Validation error: heads.0.default_amount must not be less than 0                                                    | —             | ⬜                  | —   | —   |         |
| TC-FGM-010 | View single fee group details                            | Existing record with groupHeads loaded                        | GET /fee-group-master/1                                                                                                                                                       | Returns 200, shows group with eager-loaded groupHeads.head                                                          | —             | ⬜                  | —   | —   |         |
| TC-FGM-011 | View single fee group - not found                        | ID=9999                                                       | GET /fee-group-master/9999                                                                                                                                                    | Returns 404 Not Found                                                                                               | —             | ⬜                  | —   | —   |         |
| TC-FGM-012 | View edit fee group form                                 | Existing record                                               | GET /fee-group-master/1/edit                                                                                                                                                  | Returns 200, shows edit form with pre-filled data and active fee heads                                              | —             | ⬜                  | —   | —   |         |
| TC-FGM-013 | Update fee group with full head sync                     | Existing group with 2 heads                                   | PUT /fee-group-master/1 with: code=ACADEMIC, name=Updated, heads=[{head_id:1}, {head_id:2}, {head_id:3}]                                                                      | 302 Redirect, group updated, old junction records deleted, new junction records created (full sync)                 | —             | ⬜                  | —   | —   |         |
| TC-FGM-014 | Update fee group - remove all heads (empty array)        | Existing group with 2 heads                                   | PUT /fee-group-master/1 with: heads=[]                                                                                                                                        | All existing junction records deleted, group updated with no heads                                                  | —             | ⬜                  | —   | —   |         |
| TC-FGM-015 | Update fee group - duplicate code conflict               | Record 1 (ACADEMIC), Record 2 (TRANSPORT)                     | PUT /fee-group-master/1 with: code=TRANSPORT                                                                                                                                  | Validation error: code already taken                                                                                | —             | ⬜                  | —   | —   |         |
| TC-FGM-016 | Delete (soft) fee group                                  | Existing record                                               | DELETE /fee-group-master/1                                                                                                                                                    | 302 Redirect, is_active=0, deleted_at set, activity_log 'Trashed'                                                   | —             | ⬜                  | —   | —   |         |
| TC-FGM-017 | View trashed fee groups                                  | At least one soft-deleted record                              | GET /fee-group-master/trash/view                                                                                                                                              | Returns 200, paginated onlyTrashed list (10 per page)                                                               | —             | ⬜                  | —   | —   |         |
| TC-FGM-018 | Restore fee group from trash                             | Soft-deleted record                                           | GET /fee-group-master/1/restore                                                                                                                                               | 302 Redirect to trashed route, restored, is_active=1                                                                | —             | ⬜                  | —   | —   |         |
| TC-FGM-019 | Force delete fee group                                   | Trashed record                                                | DELETE /fee-group-master/1/force-delete                                                                                                                                       | Permanent delete, redirect to trashed route                                                                         | —             | ⬜                  | —   | —   |         |
| TC-FGM-020 | Toggle status on fee group (activate)                    | is_active=0                                                   | POST /fee-group-master/1/toggle-status with: is_active=1                                                                                                                      | JSON 200: {success: true, is_active: 1, message: 'Fee Group status updated successfully.'}                          | —             | ⬜                  | —   | —   |         |
| TC-FGM-021 | Toggle status on fee group (deactivate)                  | is_active=1                                                   | POST /fee-group-master/1/toggle-status with: is_active=0                                                                                                                      | JSON 200: {success: true, is_active: 0}                                                                             | —             | ⬜                  | —   | —   |         |
| TC-FGM-022 | Toggle status fails on DB error                          | Simulate DB save failure                                      | POST /fee-group-master/1/toggle-status with: is_active=1                                                                                                                      | JSON 200: {success: false, message: 'Failed to update Fee Group status.'}                                           | —             | ⬜                  | —   | —   |         |
| TC-FGM-023 | Update fee group without permission                      | User lacks update permission                                  | PUT /fee-group-master/1                                                                                                                                                       | Returns 403 Forbidden                                                                                               | —             | ⬜                  | —   | —   |         |
| TC-FGM-024 | Create fee group with is_mandatory=false                 | —                                                             | POST /fee-group-master with: code=OPT, name=Optional, is_mandatory=0                                                                                                          | Group created as optional (is_mandatory=0)                                                                          | —             | ⬜                  | —   | —   |         |
| TC-FGM-025 | Create fee group with default amounts on heads           | —                                                             | POST /fee-group-master with: heads[0]={head_id:1, default_amount:5000.00}                                                                                                     | Junction record created with default_amount=5000.00                                                                 | —             | ⬜                  | —   | —   |         |
| TC-FGM-026 | Store transaction rollback on exception                  | Force exception during junction creation                      | POST /fee-group-master with invalid heads data                                                                                                                                | No partial creation — entire transaction rolled back                                                                | —             | ⬜                  | —   | —   |         |
| TC-FGM-027 | Code field max length (51 chars)                         | —                                                             | POST /fee-group-master with 51-char code                                                                                                                                      | Validation error: code must not exceed 50 characters                                                                | —             | ⬜                  | —   | —   |         |
| TC-FGM-028 | Name field max length (101 chars)                        | —                                                             | POST /fee-group-master with 101-char name                                                                                                                                     | Validation error: name must not exceed 100 characters                                                               | —             | ⬜                  | —   | —   |         |

## 6. Business Rules Coverage

| Rule                                                 | TC Coverage            | Status |
| ---------------------------------------------------- | ---------------------- | ------ |
| Mandatory groups auto-included in fee structures     | TC-FGM-024             | ⬜     |
| Optional heads within group (is_optional flag)       | TC-FGM-004             | ⬜     |
| Head default amount override via junction            | TC-FGM-025             | ⬜     |
| Full sync of heads on update (delete all, re-create) | TC-FGM-013, TC-FGM-014 | ⬜     |
| Deactivate before soft delete                        | TC-FGM-016             | ⬜     |
| Restore reactivates                                  | TC-FGM-018             | ⬜     |
| Transaction atomicity for create/update              | TC-FGM-026             | ⬜     |

## 7. Edge Case Coverage

| Edge Case                      | TC Coverage            | Status |
| ------------------------------ | ---------------------- | ------ |
| Duplicate code                 | TC-FGM-007             | ⬜     |
| Missing required fields        | TC-FGM-006             | ⬜     |
| Invalid head_id reference      | TC-FGM-008             | ⬜     |
| Negative default_amount        | TC-FGM-009             | ⬜     |
| Non-existent record (404)      | TC-FGM-011             | ⬜     |
| Empty heads array              | TC-FGM-005, TC-FGM-014 | ⬜     |
| Toggle status failure handling | TC-FGM-022             | ⬜     |
| Code max length exceeded       | TC-FGM-027             | ⬜     |
| Name max length exceeded       | TC-FGM-028             | ⬜     |

## 8. Known Issues / Gaps

1. **GAP-FGM-01**: `update()` performs full head sync by deleting all existing junction records — if any of those heads are referenced elsewhere via FK, the CASCADE in DB handles deletion. No manual integrity check.
2. **GAP-FGM-02**: `store()` uses `DB::transaction` but does NOT have an explicit try-catch — relies on framework exception handling for rollback.
3. **GAP-FGM-03**: `destroy()` does not check for existing references — FK `fk_fsd_group` in fee_structure_details has ON DELETE SET NULL, so deletion cascades NULL into structures.
4. **GAP-FGM-04**: `toggleStatus()` returns plain strings (`'Fee Group status updated successfully.'`) instead of `flash()` helper keys, inconsistent with other controllers.
5. **GAP-FGM-05**: FeeGroupHeadsJnt does NOT use SoftDeletes — junction records are hard deleted on sync.

## 9. Route Reference

| Method | URI                                                  | Name                            | Controller Method        |
| ------ | ---------------------------------------------------- | ------------------------------- | ------------------------ |
| GET    | `/fee-group-master`                                  | `fee-group-master.index`        | index() → redirect       |
| GET    | `/fee-group-master/create`                           | `fee-group-master.create`       | create()                 |
| POST   | `/fee-group-master`                                  | `fee-group-master.store`        | store()                  |
| GET    | `/fee-group-master/{fee_group_master}`               | `fee-group-master.show`         | show()                   |
| GET    | `/fee-group-master/{fee_group_master}/edit`          | `fee-group-master.edit`         | edit()                   |
| PUT    | `/fee-group-master/{fee_group_master}`               | `fee-group-master.update`       | update()                 |
| DELETE | `/fee-group-master/{fee_group_master}`               | `fee-group-master.destroy`      | destroy()                |
| GET    | `/fee-group-master/trash/view`                       | `fee-group-master.trashed`      | trashedFeeGroupMasters() |
| GET    | `/fee-group-master/{id}/restore`                     | `fee-group-master.restore`      | restore()                |
| DELETE | `/fee-group-master/{id}/force-delete`                | `fee-group-master.forceDelete`  | forceDelete()            |
| POST   | `/fee-group-master/{fee_group_master}/toggle-status` | `fee-group-master.toggleStatus` | toggleStatus()           |

## 10. Execution Status

| Total TC | Passed | Failed | Blocked | Not Run |
| -------- | ------ | ------ | ------- | ------- |
| 28       | 0      | 0      | 0       | 28      |
