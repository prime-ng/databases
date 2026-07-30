# Test Case List: Fee Concession Type

## 1. Module Name
**StudentFee** (Prefix: `fee_`)

## 2. Feature Name
**Fee Concession Type** — Discount/concession definitions

## 3. Tab / Submodule
**Configuration** (Route: `GET /student-fee/configuration`, Tab: `fee-concession-type`)

## 4. Reference Documents
- DDL: `pgdatabase/2-DDL_Tenant_Consolidated/StudentFee_DDL_v4.sql` (Tables 8-9: fee_concession_types, fee_concession_applicable_heads)
- Controller: `Modules/StudentFee/app/Http/Controllers/FeeConcessionTypeController.php`
- Store Request: `Modules/StudentFee/app/Http/Requests/StoreFeeConcessionTypeRequest.php`
- Update Request: `Modules/StudentFee/app/Http/Requests/UpdateFeeConcessionTypeRequest.php`
- Model: `Modules/StudentFee/app/Models/FeeConcessionType.php`
- Model: `Modules/StudentFee/app/Models/FeeConcessionApplicableHead.php`
- Routes: `Modules/StudentFee/routes/web.php` (Lines 87-92)

## 5. Test Case Matrix

| # | Test Case | Precondition | Test Data / Steps | Expected Result | Actual Result | Status (⬜/✅/❌/◌) | V1 | V2 | Remarks |
|---|-----------|-------------|-------------------|----------------|---------------|-------------------|---|---|---|---------|
| TC-FCT-001 | View concession type list (index redirects) | User has viewAny permission | GET /fee-concession-type | 302 Redirect to route('student-fee.configuration', ['tab' => 'fee-concession-type']) | — | ⬜ | — | — | |
| TC-FCT-002 | View create concession type form | User has create permission | GET /fee-concession-type/create | Returns 200, shows form with concession categories, discount types, applicable options, roles | — | ⬜ | — | — | |
| TC-FCT-003 | Create concession type - Percentage, Total Fee, no approval | User has create permission | POST /fee-concession-type with: code=SIB10, name=Sibling 10%, concession_category_id=1, discount_type=Percentage, discount_value=10.00, applicable_on=Total Fee, requires_approval=0, is_active=1 | 302 Redirect to config tab, code stored as 'SIB10' (uppercase), requires_approval=0, approval_level_role_id=null, activity_log entry | — | ⬜ | — | — | |
| TC-FCT-004 | Create concession type - Fixed Amount with max cap | — | POST /fee-concession-type with: discount_type=Fixed Amount, discount_value=5000, max_cap_amount=5000 | Created with max_cap = 5000 | — | ⬜ | — | — | |
| TC-FCT-005 | Create concession type - requires approval with role | — | POST /fee-concession-type with: requires_approval=1, approval_level_role_id=2 | requires_approval=1, approval_level_role_id=2 | — | ⬜ | — | — | |
| TC-FCT-006 | Create concession type - requires approval without role | — | POST /fee-concession-type with: requires_approval=1, no approval_level_role_id | Validation error: 'Approval level is required when approval is required.' | — | ⬜ | — | — | |
| TC-FCT-007 | Create concession type - discount_value exceeds 100 for Percentage | discount_type=Percentage | POST /fee-concession-type with: discount_value=150 | Validation error: 'Percentage discount cannot exceed 100%.' | — | ⬜ | — | — | |
| TC-FCT-008 | Create concession type - max_cap less than discount_value for Fixed Amount | discount_type=Fixed Amount, discount_value=5000 | POST with: max_cap_amount=3000 | Validation error: 'Max cap cannot be less than discount value.' | — | ⬜ | — | — | |
| TC-FCT-009 | Create concession type - duplicate code | Existing code='SIB10' | POST with: code=SIB10 | Validation error: code already taken | — | ⬜ | — | — | |
| TC-FCT-010 | Create concession type - invalid discount_type value | — | POST with: discount_type=FlatRate | Validation error: discount_type must be one of Percentage,Fixed Amount | — | ⬜ | — | — | |
| TC-FCT-011 | Create concession type - invalid applicable_on value | — | POST with: applicable_on=All | Validation error: applicable_on must be one of Total Fee,Specific Heads,Specific Groups | — | ⬜ | — | — | |
| TC-FCT-012 | Create concession type - code auto-uppercased | — | POST with: code=sib10 (lowercase) | Stored as 'SIB10' | — | ⬜ | — | — | |
| TC-FCT-013 | View single concession type details | Existing record | GET /fee-concession-type/1 | Returns 200, shows with concessionCategory relationship | — | ⬜ | — | — | |
| TC-FCT-014 | View edit concession type form | Existing record | GET /fee-concession-type/1/edit | Returns 200, pre-filled form with categories, discount types, options, roles | — | ⬜ | — | — | |
| TC-FCT-015 | Update concession type - change discount value | Existing record | PUT /fee-concession-type/1 with: discount_value=15.00 | Updated, code remains unique-ignored on self | — | ⬜ | — | — | |
| TC-FCT-016 | Update concession type - toggle requires_approval on/off | Existing record with requires_approval=0 | PUT with: requires_approval=1, approval_level_role_id=3 | Updated, approval_level_role_id set to 3 | — | ⬜ | — | — | |
| TC-FCT-017 | Update concession type - remove approval (toggle off) | Existing with requires_approval=1 | PUT with: requires_approval=0 | Updated, approval_level_role_id set to null | — | ⬜ | — | — | |
| TC-FCT-018 | Delete (soft) concession type | Existing record | DELETE /fee-concession-type/1 | 302 Redirect, is_active=0, deleted_at set, activity_log 'Trashed' | — | ⬜ | — | — | |
| TC-FCT-019 | View trashed concession types | At least one soft-deleted record | GET /fee-concession-type/trash/view | Returns 200, paginated list with concessionCategory and approvalRole eager-loaded | — | ⬜ | — | — | |
| TC-FCT-020 | Restore concession type from trash | Soft-deleted record | GET /fee-concession-type/1/restore | Restored, is_active=1 | — | ⬜ | — | — | |
| TC-FCT-021 | Force delete concession type | Trashed record | DELETE /fee-concession-type/1/force-delete | Permanent delete, redirect to trashed route | — | ⬜ | — | — | |
| TC-FCT-022 | Toggle status on concession type (negate) | is_active=1 | POST /fee-concession-type/1/toggle-status (no body needed — controller negates current) | is_active toggled to 0, JSON response | — | ⬜ | — | — | |
| TC-FCT-023 | calculateDiscount() - Percentage, no max cap | discount_type=Percentage, value=10, base=10000 | Call calculateDiscount(10000) | Returns 1000.00 | — | ⬜ | — | — | |
| TC-FCT-024 | calculateDiscount() - Fixed Amount with max cap lower | discount_type=Fixed Amount, value=5000, max_cap=3000 | Call calculateDiscount(0) | Returns 3000.00 (capped) | — | ⬜ | — | — | |
| TC-FCT-025 | Calculate discount - max cap higher than computed | Percentage 10%, value=1000, max_cap=2000, base=5000 | Call calculateDiscount(5000) | Returns 500.00 (computed, no cap) | — | ⬜ | — | — | |
| TC-FCT-026 | Store exception handling - DB rollback | DB failure simulation | POST with valid data | Caught exception, rollback, return back with system_error message | — | ⬜ | — | — | |
| TC-FCT-027 | discount_value minimum (0) | — | POST with: discount_value=0 | Validation error: discount_value must be at least 0.01 | — | ⬜ | — | — | |
| TC-FCT-028 | Name max length (101 chars) | — | POST with 101-char name | Validation error: name must not exceed 100 characters | — | ⬜ | — | — | |

## 6. Business Rules Coverage

| Rule | TC Coverage | Status |
|------|-------------|--------|
| Percentage discount capped at 100% | TC-FCT-007 | ⬜ |
| Fixed Amount max_cap ≥ discount_value | TC-FCT-008 | ⬜ |
| requires_approval=true requires approval_level_role_id | TC-FCT-006 | ⬜ |
| Code auto-converted to uppercase | TC-FCT-012 | ⬜ |
| If requires_approval=false, approval_level_role_id=null | TC-FCT-017 | ⬜ |
| calculateDiscount with max cap enforcement | TC-FCT-024, TC-FCT-025 | ⬜ |
| calculateDiscount Percentage type | TC-FCT-023 | ⬜ |
| Deactivate before soft delete | TC-FCT-018 | ⬜ |
| Restore reactivates | TC-FCT-020 | ⬜ |

## 7. Edge Case Coverage

| Edge Case | TC Coverage | Status |
|-----------|-------------|--------|
| Duplicate code | TC-FCT-009 | ⬜ |
| Invalid discount_type enum | TC-FCT-010 | ⬜ |
| Invalid applicable_on enum | TC-FCT-011 | ⬜ |
| Max cap less than discount (Fixed Amount) | TC-FCT-008 | ⬜ |
| Percentage exceeds 100 | TC-FCT-007 | ⬜ |
| Requires approval without role | TC-FCT-006 | ⬜ |
| Code stored in uppercase | TC-FCT-012 | ⬜ |
| Toggle requires_approval on/off | TC-FCT-016, TC-FCT-017 | ⬜ |
| DB exception/rollback handling | TC-FCT-026 | ⬜ |
| discount_value below minimum | TC-FCT-027 | ⬜ |

## 8. Known Issues / Gaps

1. **GAP-FCT-01**: **CRITICAL** — `store()` and `update()` methods do NOT handle the `fee_concession_applicable_heads` junction table. The applicable heads/groups mapping from the form is NOT saved. This means concessions with `applicable_on = Specific Heads` or `Specific Groups` will not have their mappings persisted.
2. **GAP-FCT-02**: `toggleStatus()` negates current value (`!$feeConcessionType->is_active`) instead of using request input — inconsistent with FeeHeadMaster/FeeStructureMaster.
3. **GAP-FCT-03**: Store uses `DB::beginTransaction/commit/rollback` even though there's no junction table handling — the transaction is essentially unnecessary for the current implementation.
4. **GAP-FCT-04**: Concession category dropdown uses key pattern `concession_category.%` (dot-percent suffix), which differs from the fee head type pattern `fee_head_master.head_type_id%`.
5. **GAP-FCT-05**: No validation for `applicable_on` being 'Total Fee' when the junction table is empty — currently possible to have applicable_on=Specific Heads with no heads mapped.

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/fee-concession-type` | `fee-concession-type.index` | index() → redirect |
| GET | `/fee-concession-type/create` | `fee-concession-type.create` | create() |
| POST | `/fee-concession-type` | `fee-concession-type.store` | store() |
| GET | `/fee-concession-type/{fee_concession_type}` | `fee-concession-type.show` | show() |
| GET | `/fee-concession-type/{fee_concession_type}/edit` | `fee-concession-type.edit` | edit() |
| PUT | `/fee-concession-type/{fee_concession_type}` | `fee-concession-type.update` | update() |
| DELETE | `/fee-concession-type/{fee_concession_type}` | `fee-concession-type.destroy` | destroy() |
| GET | `/fee-concession-type/trash/view` | `fee-concession-type.trashed` | trashedFeeConcessionTypes() |
| GET | `/fee-concession-type/{id}/restore` | `fee-concession-type.restore` | restore() |
| DELETE | `/fee-concession-type/{id}/force-delete` | `fee-concession-type.forceDelete` | forceDelete() |
| POST | `/fee-concession-type/{fee_concession_type}/toggle-status` | `fee-concession-type.toggleStatus` | toggleStatus() |

## 10. Execution Status

| Total TC | Passed | Failed | Blocked | Not Run |
|----------|--------|--------|---------|---------|
| 28 | 0 | 0 | 0 | 28 |
