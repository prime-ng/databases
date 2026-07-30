# Test Case List: Fee Installments

## 1. Module Name
**StudentFee** (Prefix: `fee_`)

## 2. Feature Name
**Fee Installments** — Scheduled payment breakdown for fee structures

## 3. Tab / Submodule
**Configuration** (Route: `GET /student-fee/configuration`, Tab: `fee-installment`)

## 4. Reference Documents
- DDL: `pgdatabase/2-DDL_Tenant_Consolidated/StudentFee_DDL_v4.sql` (Table 6: fee_installments)
- Controller: `Modules/StudentFee/app/Http/Controllers/FeeInstallmentController.php`
- Store Request: `Modules/StudentFee/app/Http/Requests/StoreFeeInstallmentRequest.php`
- Update Request: `Modules/StudentFee/app/Http/Requests/UpdateFeeInstallmentRequest.php`
- Model: `Modules/StudentFee/app/Models/FeeInstallment.php`
- Routes: `Modules/StudentFee/routes/web.php` (Lines 79-84)

## 5. Test Case Matrix

| # | Test Case | Precondition | Test Data / Steps | Expected Result | Actual Result | Status (⬜/✅/❌/◌) | V1 | V2 | Remarks |
|---|-----------|-------------|-------------------|----------------|---------------|-------------------|---|---|---|---------|
| TC-FIN-001 | View fee installments list (index redirects) | User has viewAny permission | GET /fee-installment | 302 Redirect to route('student-fee.configuration', ['tab' => 'fee-installment']) | — | ⬜ | — | — | |
| TC-FIN-002 | View create installment form | User has create permission | GET /fee-installment/create | Returns 200, shows create form with active fee structures dropdown | — | ⬜ | — | — | |
| TC-FIN-003 | Create installment with valid data (first installment) | Existing FeeStructureMaster with total details summing to 10000 | POST /fee-installment with: fee_structure_id=1, installment_no=1, installment_name='Term 1', due_date='2026-06-15', percentage_due=25.00, grace_days=15, is_active=1 | 302 Redirect to config tab, installment created, amount_due auto-calculated (2500.00), activity_log entry | — | ⬜ | — | — | |
| TC-FIN-004 | Create installment - duplicate installment_no within same structure | Existing installment_no=1 for structure_id=1 | POST /fee-installment with: fee_structure_id=1, installment_no=1 | Validation error: installment_no already taken for this fee_structure | — | ⬜ | — | — | |
| TC-FIN-005 | Create installment - same installment_no in different structure | installment_no=1 exists in structure 1 | POST /fee-installment with: fee_structure_id=2, installment_no=1 | Success — unique constraint is per fee_structure_id | — | ⬜ | — | — | |
| TC-FIN-006 | Create installment - percentage total exceeds 100% | Existing installments sum to 80% | POST /fee-installment with: percentage_due=30% | 302 back with error: 'Total installment percentage cannot exceed 100%. Currently configured: 80%' | — | ⬜ | — | — | |
| TC-FIN-007 | Create installment - percentage exactly fits (80% + 20% = 100%) | Existing total = 80% | POST /fee-installment with: percentage_due=20% | Success — total = 100%, which does not exceed 100% | — | ⬜ | — | — | |
| TC-FIN-008 | Create installment - percentage_due minimum (0) | — | POST /fee-installment with: percentage_due=0 | Validation error: percentage_due must be at least 0.01 | — | ⬜ | — | — | |
| TC-FIN-009 | Create installment - percentage_due over 100 | — | POST /fee-installment with: percentage_due=110 | Validation error: percentage_due may not be greater than 100 | — | ⬜ | — | — | |
| TC-FIN-010 | Create installment - manual amount_due override | — | POST /fee-installment with: amount_due=3000.00, percentage_due=25 | Installment saved with amount_due=3000.00 (manual override, not auto-calculated) | — | ⬜ | — | — | |
| TC-FIN-011 | Create installment - grace_days exceeds max (366) | — | POST /fee-installment with: grace_days=400 | Validation error: grace_days may not be greater than 365 | — | ⬜ | — | — | |
| TC-FIN-012 | View single installment details | Existing record | GET /fee-installment/1 | Returns 200, shows installment with feeStructure relationship | — | ⬜ | — | — | |
| TC-FIN-013 | View single installment - not found | ID=9999 | GET /fee-installment/9999 | Returns 404 Not Found | — | ⬜ | — | — | |
| TC-FIN-014 | View edit installment form | Existing record | GET /fee-installment/1/edit | Returns 200, shows edit form with pre-filled data and active fee structures | — | ⬜ | — | — | |
| TC-FIN-015 | Update installment with new percentage | Existing record ID=1 with percentage=25, structure total=10000, other installments total 50% | PUT /fee-installment/1 with: percentage_due=30 | 302 Redirect, updated, amount_due=3000 (30% of 10000), total with others = 80% (OK) | — | ⬜ | — | — | |
| TC-FIN-016 | Update installment - percentage exceeds 100% (excluding self) | Existing total (excluding self) = 80% | PUT /fee-installment/1 with: percentage_due=25% | 302 back error: 'Total installment percentage cannot exceed 100%. Already configured: 80%' (80+25=105 > 100) | — | ⬜ | — | — | |
| TC-FIN-017 | Update installment - change fee_structure_id | — | PUT /fee-installment/1 with: fee_structure_id=2 | Installment reassigned to new structure, installment_no uniqueness checked against new structure | — | ⬜ | — | — | |
| TC-FIN-018 | Delete (soft) installment | Existing record | DELETE /fee-installment/1 | 302 Redirect, is_active=0, deleted_at set | — | ⬜ | — | — | |
| TC-FIN-019 | View trashed installments | At least one soft-deleted record | GET /fee-installment/trash/view | Returns 200, paginated onlyTrashed list with feeStructure eager-loaded | — | ⬜ | — | — | |
| TC-FIN-020 | Restore installment from trash | Soft-deleted record | GET /fee-installment/1/restore | 302 Redirect to trashed route, restored, is_active=1 | — | ⬜ | — | — | |
| TC-FIN-021 | Force delete installment | Trashed record | DELETE /fee-installment/1/force-delete | Permanent delete, redirect to trashed route | — | ⬜ | — | — | |
| TC-FIN-022 | Toggle status on installment (toggle behavior) | is_active=1 | POST /fee-installment/1/toggle-status (no is_active in body — controller negates current) | is_active toggled to 0, JSON response with success | — | ⬜ | — | — | |
| TC-FIN-023 | getLastDateWithGrace() helper | due_date=2026-06-15, grace_days=15 | Call helper | Returns '2026-06-30' | — | ⬜ | — | — | |
| TC-FIN-024 | isOverdue() helper — overdue scenario | due_date=old date + grace_days passed | Call helper | Returns true | — | ⬜ | — | — | |
| TC-FIN-025 | isOverdue() helper — not overdue | due_date in future | Call helper | Returns false | — | ⬜ | — | — | |
| TC-FIN-026 | Store exception handling — DB rollback | DB write failure simulation | POST /fee-installment with valid data | Exception caught, DB rolled back, returned back with 'Something went wrong.' error | — | ⬜ | — | — | |
| TC-FIN-027 | Create installment - installment_no below min (0) | — | POST /fee-installment with: installment_no=0 | Validation error: installment_no must be at least 1 | — | ⬜ | — | — | |
| TC-FIN-028 | grace_days default when not provided | — | POST /fee-installment without grace_days | grace_days defaults to 0 in DB | — | ⬜ | — | — | |

## 6. Business Rules Coverage

| Rule | TC Coverage | Status |
|------|-------------|--------|
| Sum of percentage_due across installments ≤ 100% | TC-FIN-006, TC-FIN-007, TC-FIN-016 | ⬜ |
| amount_due auto-calculated from total × percentage/100 | TC-FIN-003 | ⬜ |
| amount_due manual override via request | TC-FIN-010 | ⬜ |
| installment_no unique per fee_structure_id | TC-FIN-004, TC-FIN-005 | ⬜ |
| Deactivate before soft delete | TC-FIN-018 | ⬜ |
| getLastDateWithGrace helper | TC-FIN-023 | ⬜ |
| isOverdue helper | TC-FIN-024, TC-FIN-025 | ⬜ |
| Grace period capped at 365 days | TC-FIN-011 | ⬜ |

## 7. Edge Case Coverage

| Edge Case | TC Coverage | Status |
|-----------|-------------|--------|
| Duplicate installment_no in same structure | TC-FIN-004 | ⬜ |
| Same installment_no in different structure (OK) | TC-FIN-005 | ⬜ |
| Percentage total exactly 100% (within limit) | TC-FIN-007 | ⬜ |
| Percentage total exceeds 100% | TC-FIN-006 | ⬜ |
| percentage_due = 0 (below min) | TC-FIN-008 | ⬜ |
| percentage_due > 100 | TC-FIN-009 | ⬜ |
| Manual amount_due override vs auto | TC-FIN-010 | ⬜ |
| Grace days over 365 | TC-FIN-011 | ⬜ |
| Installment_no below min (0) | TC-FIN-027 | ⬜ |
| Grace days not provided (default) | TC-FIN-028 | ⬜ |
| DB exception handling/rollback | TC-FIN-026 | ⬜ |

## 8. Known Issues / Gaps

1. **GAP-FIN-01**: **CRITICAL** — `FeeInstallment` model does NOT use the `SoftDeletes` trait (no `use SoftDeletes` in the model). However, `destroy()`, `trashedFeeInstallments()`, `restore()`, and `forceDelete()` methods all assume SoftDeletes behavior. `delete()` will perform a hard delete, and `restore()` will fail with `BadMethodCallException: Method restore does not exist`.
2. **GAP-FIN-02**: `toggleStatus()` negates the current value (`!$feeInstallment->is_active`) instead of using the request `is_active` input — this is inconsistent with other controllers (FeeHeadMaster, FeeStructureMaster) that use the request value directly.
3. **GAP-FIN-03**: DB transaction uses `DB::beginTransaction/commit/rollback` pattern (manual) instead of `DB::transaction()` closure — explicit rollback required in catch block.
4. **GAP-FIN-04**: Controller checks percentage ≤ 100% but does NOT require the total to be exactly 100% (unlike FeeStructureMaster which requires exactly 100% for structure-level installments).
5. **GAP-FIN-05**: `destroy()` and `trashedFeeInstallments()` routes use `$id` parameter instead of implicit route model binding (route: `{id}` not `{fee_installment}`).

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/fee-installment` | `fee-installment.index` | index() → redirect |
| GET | `/fee-installment/create` | `fee-installment.create` | create() |
| POST | `/fee-installment` | `fee-installment.store` | store() |
| GET | `/fee-installment/{fee_installment}` | `fee-installment.show` | show() |
| GET | `/fee-installment/{fee_installment}/edit` | `fee-installment.edit` | edit() |
| PUT | `/fee-installment/{fee_installment}` | `fee-installment.update` | update() |
| DELETE | `/fee-installment/{fee_installment}` | `fee-installment.destroy` | destroy() |
| GET | `/fee-installment/trash/view` | `fee-installment.trashed` | trashedFeeInstallments() |
| GET | `/fee-installment/{id}/restore` | `fee-installment.restore` | restore() |
| DELETE | `/fee-installment/{id}/force-delete` | `fee-installment.forceDelete` | forceDelete() |
| POST | `/fee-installment/{fee_installment}/toggle-status` | `fee-installment.toggleStatus` | toggleStatus() |

## 10. Execution Status

| Total TC | Passed | Failed | Blocked | Not Run |
|----------|--------|--------|---------|---------|
| 28 | 0 | 0 | 0 | 28 |
