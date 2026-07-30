# Test Case List: Fee Structure Master

## 1. Module Name
**StudentFee** (Prefix: `fee_`)

## 2. Feature Name
**Fee Structure Master** — Complete fee package per class, session, and category

## 3. Tab / Submodule
**Configuration** (Route: `GET /student-fee/configuration`, Tab: `fee-structure-master`)

## 4. Reference Documents
- DDL: `pgdatabase/2-DDL_Tenant_Consolidated/StudentFee_DDL_v4.sql` (Tables 4-5: fee_structure_master, fee_structure_details)
- Controller: `Modules/StudentFee/app/Http/Controllers/FeeStructureMasterController.php`
- Store Request: `Modules/StudentFee/app/Http/Requests/StoreFeeStructureMasterRequest.php`
- Update Request: `Modules/StudentFee/app/Http/Requests/UpdateFeeStructureMasterRequest.php`
- Model: `Modules/StudentFee/app/Models/FeeStructureMaster.php`
- Model: `Modules/StudentFee/app/Models/FeeStructureDetail.php`
- Routes: `Modules/StudentFee/routes/web.php` (Lines 51-57)

## 5. Test Case Matrix

| # | Test Case | Precondition | Test Data / Steps | Expected Result | Actual Result | Status (⬜/✅/❌/◌) | V1 | V2 | Remarks |
|---|-----------|-------------|-------------------|----------------|---------------|-------------------|---|---|---|---------|
| TC-FSM-001 | View fee structure list (index redirects) | User has viewAny permission | GET /fee-structure-master | 302 Redirect to route('student-fee.configuration', ['tab' => 'fee-structure-master']) | — | ⬜ | — | — | |
| TC-FSM-002 | View create fee structure form | User has create permission | GET /fee-structure-master/create | Returns 200, shows create form with academic sessions, classes, fee heads, fee groups, student categories | — | ⬜ | — | — | |
| TC-FSM-003 | Create fee structure with details and installments (valid) | Active session, class, heads, user has create permission | POST /fee-structure-master with: academic_session_id=1, class_id=1, code=STRUCT001, name=Class 1 Fee, effective_from=2026-04-01, details=[{head_id:1, amount:5000, group_id:null}], installments=[{installment_name:'Term 1', due_date:'2026-06-15', percentage_due:50, grace_days:15}, {installment_name:'Term 2', due_date:'2026-12-15', percentage_due:50, grace_days:15}] | 302 Redirect to config tab, FeeStructureMaster created with total_fee_amount=5000, details created, installments created (installment_no=1,2), activity_log entry | — | ⬜ | — | — | |
| TC-FSM-004 | Create fee structure without installments | — | POST /fee-structure-master with valid data, no installments field | Structure created without FeeInstallment records | — | ⬜ | — | — | |
| TC-FSM-005 | Create fee structure - installment sum not 100% | — | installments=[{percentage_due:30}, {percentage_due:30}] | Validation error: 'The sum of installment percentages must equal exactly 100%. Current sum: 60%' | — | ⬜ | — | — | |
| TC-FSM-006 | Create fee structure - installment sum exactly 100% | — | installments=[{percentage_due:25}, {percentage_due:25}, {percentage_due:25}, {percentage_due:25}] | Validation passes, 4 installments created with auto-incrementing installment_no | — | ⬜ | — | — | |
| TC-FSM-007 | Create fee structure - missing required fields | — | POST /fee-structure-master with empty payload | Validation errors: academic_session_id, class_id, code, name, effective_from | — | ⬜ | — | — | |
| TC-FSM-008 | Create fee structure - duplicate code | Existing code 'STRUCT001' | POST /fee-structure-master with: code=STRUCT001 | Validation error: code already taken | — | ⬜ | — | — | |
| TC-FSM-009 | Create fee structure - effective_to before effective_from | — | effective_from=2026-06-01, effective_to=2026-05-01 | Validation error: effective_to must be after effective_from | — | ⬜ | — | — | |
| TC-FSM-010 | Create fee structure - detail amount negative | — | details=[{head_id:1, amount:-100}] | Validation error: details.0.amount must not be less than 0 | — | ⬜ | — | — | |
| TC-FSM-011 | View single fee structure details | Existing record with details, installments, session, class | GET /fee-structure-master/1 | Returns 200, shows structure with eager-loaded academicSession, class, details.head, details.group, installments | — | ⬜ | — | — | |
| TC-FSM-012 | View edit fee structure form | Existing record without student assignments | GET /fee-structure-master/1/edit | Returns 200, shows edit form with pre-filled data | — | ⬜ | — | — | |
| TC-FSM-013 | Update fee structure (no existing assignments) | Existing structure without any FeeStudentAssignment | PUT /fee-structure-master/1 with valid updated data | 302 Redirect, structure updated, old details deleted and re-created, old installments deleted and re-created (full sync) | — | ⬜ | — | — | |
| TC-FSM-014 | Update fee structure WITH existing student assignments | Structure has FeeStudentAssignment records | PUT /fee-structure-master/1 | 302 Redirect back with error: 'Cannot edit: student assignments already use this structure.' — no changes made | — | ⬜ | — | — | |
| TC-FSM-015 | Update fee structure - change details and installments simultaneously | Existing structure with old details | PUT /fee-structure-master/1 with completely new details and installments | All old details deleted, new details created; all old installments deleted, new installments created; total_fee_amount recalculated | — | ⬜ | — | — | |
| TC-FSM-016 | Delete fee structure (no assignments) | Structure without assignments | DELETE /fee-structure-master/1 | 302 Redirect, is_active=0, soft-deleted | — | ⬜ | — | — | |
| TC-FSM-017 | Delete fee structure WITH existing assignments | Structure has FeeStudentAssignment | DELETE /fee-structure-master/1 | 302 Redirect back with error: 'Cannot delete: student assignments exist for this structure.' | — | ⬜ | — | — | |
| TC-FSM-018 | View trashed fee structures | At least one soft-deleted record | GET /fee-structure-master/trash/view | Returns 200, paginated onlyTrashed with class and academicSession eager-loaded | — | ⬜ | — | — | |
| TC-FSM-019 | Restore fee structure | Soft-deleted record | GET /fee-structure-master/1/restore | Restored, is_active=1, activity_log entry | — | ⬜ | — | — | |
| TC-FSM-020 | Force delete fee structure | Trashed record | DELETE /fee-structure-master/1/force-delete | Permanently deleted, redirect to trashed route | — | ⬜ | — | — | |
| TC-FSM-021 | Toggle status on fee structure | Existing record | POST /fee-structure-master/1/toggle-status with: is_active=1 | JSON 200: {success: true, is_active: 1, message: flash('status_updated.fee_structure_master')} | — | ⬜ | — | — | |
| TC-FSM-022 | Create fee structure with student_category_id null | — | POST /fee-structure-master with: student_category_id=null | Structure created with student_category_id=NULL in DB | — | ⬜ | — | — | |
| TC-FSM-023 | Create fee structure with board_type set | — | POST /fee-structure-master with: board_type=CBSE | Structure saved with board_type='CBSE' | — | ⬜ | — | — | |
| TC-FSM-024 | Update fee structure remove all installments | Existing with 2 installments | PUT /fee-structure-master/1 with: installments=[] (empty array) | All existing installments deleted, no new ones created | — | ⬜ | — | — | |
| TC-FSM-025 | Verify total_fee_amount computed correctly | Details: head1=5000, head2=3000, head3=2000 | POST with these 3 details | total_fee_amount = 10000.00 | — | ⬜ | — | — | |
| TC-FSM-026 | Installment amount_due computed correctly | total_fee=10000, percentage_due=25 | Create structure | installment amount_due = 2500.00 (round((10000*25)/100, 2)) | — | ⬜ | — | — | |
| TC-FSM-027 | isCurrentlyEffective() helper check | effective_from=2026-01-01, effective_to=2026-12-31, current date within range | Call helper on structure | Returns true | — | ⬜ | — | — | |
| TC-FSM-028 | isCurrentlyEffective() out of range | effective_to=2026-01-01, current date after | Call helper | Returns false | — | ⬜ | — | — | |

## 6. Business Rules Coverage

| Rule | TC Coverage | Status |
|------|-------------|--------|
| Total fee = sum of all detail amounts | TC-FSM-025 | ⬜ |
| Installment sum must equal exactly 100% | TC-FSM-005, TC-FSM-006 | ⬜ |
| Update blocked if student assignments exist | TC-FSM-014 | ⬜ |
| Delete blocked if student assignments exist | TC-FSM-017 | ⬜ |
| Full sync of details on update | TC-FSM-013, TC-FSM-015 | ⬜ |
| Full sync of installments on update | TC-FSM-013, TC-FSM-015, TC-FSM-024 | ⬜ |
| installment_no auto-increments from 1 | TC-FSM-003 | ⬜ |
| amount_due computed from total × percentage/100 | TC-FSM-026 | ⬜ |
| effective_to must be after effective_from | TC-FSM-009 | ⬜ |
| Deactivate before soft delete | TC-FSM-016 | ⬜ |
| Restore reactivates | TC-FSM-019 | ⬜ |

## 7. Edge Case Coverage

| Edge Case | TC Coverage | Status |
|-----------|-------------|--------|
| No installments provided (empty/null) | TC-FSM-004 | ⬜ |
| Installments removed on update (empty array) | TC-FSM-024 | ⬜ |
| student_category_id is null | TC-FSM-022 | ⬜ |
| Duplicate code | TC-FSM-008 | ⬜ |
| Missing required fields | TC-FSM-007 | ⬜ |
| Negative detail amount | TC-FSM-010 | ⬜ |
| effective_to < effective_from | TC-FSM-009 | ⬜ |
| isCurrentlyEffective() happy path | TC-FSM-027 | ⬜ |
| isCurrentlyEffective() expired | TC-FSM-028 | ⬜ |

## 8. Known Issues / Gaps

1. **GAP-FSM-01**: `academic_session_id` validation in FormRequest only checks `integer` — no `exists` rule to verify the session actually exists in the database.
2. **GAP-FSM-02**: Assignment protection check uses `$structure->assignments()->exists()` — this checks ALL assignments (including soft-deleted ones if model uses SoftDeletes). Only active assignments should block edit.
3. **GAP-FSM-03**: total_fee_amount includes optional detail amounts (sums ALL details, not just mandatory ones). This may cause incorrect total if optional heads are included.
4. **GAP-FSM-04**: No uniqueness enforcement for (session + class + category + board) combination — multiple structures with same combo can exist simultaneously.
5. **GAP-FSM-05**: Full sync on update uses `->delete()` (soft-deletes if SoftDeletes used on FeeStructureDetail/FeeInstallment models). Installment model does NOT use SoftDeletes, so it hard-deletes.
6. **GAP-FSM-06**: Installment percentage validation requires EXACTLY 100% total — but the controller-level check for standalone installments only checks ≤100%. This inconsistency could cause issues.

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/fee-structure-master` | `fee-structure-master.index` | index() → redirect |
| GET | `/fee-structure-master/create` | `fee-structure-master.create` | create() |
| POST | `/fee-structure-master` | `fee-structure-master.store` | store() |
| GET | `/fee-structure-master/{fee_structure_master}` | `fee-structure-master.show` | show() |
| GET | `/fee-structure-master/{fee_structure_master}/edit` | `fee-structure-master.edit` | edit() |
| PUT | `/fee-structure-master/{fee_structure_master}` | `fee-structure-master.update` | update() |
| DELETE | `/fee-structure-master/{fee_structure_master}` | `fee-structure-master.destroy` | destroy() |
| GET | `/fee-structure-master/trash/view` | `fee-structure-master.trashed` | trashedFeeStructureMasters() |
| GET | `/fee-structure-master/{id}/restore` | `fee-structure-master.restore` | restore() |
| DELETE | `/fee-structure-master/{id}/force-delete` | `fee-structure-master.forceDelete` | forceDelete() |
| POST | `/fee-structure-master/{fee_structure_master}/toggle-status` | `fee-structure-master.toggleStatus` | toggleStatus() |

## 10. Execution Status

| Total TC | Passed | Failed | Blocked | Not Run |
|----------|--------|--------|---------|---------|
| 28 | 0 | 0 | 0 | 28 |
