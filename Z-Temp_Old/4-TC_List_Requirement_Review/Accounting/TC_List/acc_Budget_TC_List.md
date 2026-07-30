# Budget_TcList

## Module: Accounting → Transactions → Budgets

---

## 1. Business Conditions

### 1.1 Database Schema — acc_budgets

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | bigint unsigned | PK, auto-increment |
| BC-DB-02 | financial_year_id | tinyint unsigned | NOT NULL, FK → acc_financial_years(id) ON DELETE RESTRICT |
| BC-DB-03 | cost_center_id | bigint unsigned | NOT NULL, FK → acc_cost_centers(id) ON DELETE RESTRICT |
| BC-DB-04 | ledger_id | int unsigned | NOT NULL, FK → acc_ledgers(id) ON DELETE RESTRICT |
| BC-DB-05 | budgeted_amount | decimal(15,2) | NOT NULL DEFAULT 0.00 |
| BC-DB-06 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-07 | created_by | int unsigned | NULLABLE, FK → sys_users (no DB FK) |
| BC-DB-08 | created_at | timestamp | Auto-managed |
| BC-DB-09 | updated_at | timestamp | Auto-managed |
| BC-DB-10 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-11 | UNIQUE uq_acc_budget | (financial_year_id, cost_center_id, ledger_id) | One budget per FY + CC + Ledger |
| BC-DB-12 | INDEX idx_acc_budget_cc | cost_center_id | FK index |
| BC-DB-13 | INDEX idx_acc_budget_ledger | ledger_id | FK index |
| BC-DB-14 | id — BIGINT UNSIGNED | — | Max 18 quintillion records |
| BC-DB-15 | ENGINE=InnoDB | — | Transaction support, FK enforcement |
| BC-DB-16 | DEFAULT CHARSET=utf8mb4 | — | Unicode support |
| BC-DB-17 | budgeted_amount = DECIMAL(15,2) | — | Max 999,999,999,999,999.99 |

### DDL-Level Gaps

| Gap | Details |
|-----|---------|
| No FK on `created_by` | created_by INT UNSIGNED with no FK to sys_users |
| No CHECK constraint | budgeted_amount >= 0 enforced only at application layer |

### 1.2 Validation Rules (BudgetRequest)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | financial_year_id | required, exists:acc_financial_years,id | "The Financial Year field is required." |
| BC-VAL-02 | cost_center_id | required, exists:acc_cost_centers,id | "The Cost Center field is required." |
| BC-VAL-03 | ledger_id | required, exists:acc_ledgers,id + unique combo (FY, CC, ledger) ignoring current | "The Ledger field is required." |
| BC-VAL-04 | budgeted_amount | required, numeric, min:0 | "The Budget Amount field is required." |
| BC-VAL-05 | is_active | required, boolean | Default true via `prepareForValidation` |

### 1.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.accounting.budget.viewAny` | `index()`, `show()`, `trashed()` | Without → 403 |
| BC-AUTH-02 | `tenant.accounting.budget.create` | `create()`, `store()`, `restore()` | Without → 403 |
| BC-AUTH-03 | `tenant.accounting.budget.update` | `edit()`, `update()`, `toggleStatus()` | Without → 403 |
| BC-AUTH-04 | `tenant.accounting.budget.delete` | `destroy()`, `forceDelete()` | Without → 403 |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create: unique combo enforced | Duplicate (FY + CC + Ledger) rejected via validation unique rule |
| BC-BIZ-02 | Create: stores created_by | `created_by = auth()->id()` |
| BC-BIZ-03 | Delete: soft delete + is_active=false | Sets is_active=false first, then delete() |
| BC-BIZ-04 | Restore: sets is_active=true | After restore(), sets is_active=true |
| BC-BIZ-05 | Toggle status (AJAX) | POST with is_active boolean → flips → JSON |
| BC-BIZ-06 | Index redirects to transactions tab | Redirect to `route('accounting.menu.transactions', ['tab' => 'budgets'])` |
| BC-BIZ-07 | Budget variance report: only posted vouchers | JOIN acc_vouchers WHERE status='posted' |
| BC-BIZ-08 | Budget variance report: only debit items | `vi.type = 'debit'` for actual consumption |
| BC-BIZ-09 | Budget variance: variance = budgeted - actual | Positive = under budget, negative = over budget |
| BC-BIZ-10 | Budget variance: variance_percent = (variance/budgeted)*100 | Returns 0 if budgeted=0 |
| BC-BIZ-11 | Budget variance: unallocated cost centers | COALESCE(cc.name, 'Unallocated') |
| BC-BIZ-12 | Success flash — Created | "Budget created successfully." |
| BC-BIZ-13 | Success flash — Updated | "Budget updated successfully." |
| BC-BIZ-14 | Success flash — Trashed | "Budget moved to trash." |
| BC-BIZ-15 | Success flash — Restored | "Budget restored successfully." |
| BC-BIZ-16 | Success flash — Force Deleted | "Budget permanently deleted." |
| BC-BIZ-17 | Activity log — Created | On store |
| BC-BIZ-18 | Activity log — Updated | On update |
| BC-BIZ-19 | Activity log — Trashed | On destroy |
| BC-BIZ-20 | Activity log — Restored | On restore |
| BC-BIZ-21 | Activity log — Deleted | On forceDelete |
| BC-BIZ-22 | Activity log — Toggled | On toggleStatus |

### 1.5 Model Scopes & Helpers

| BC ID | Scope/Helper | Criteria | Usage |
|-------|-------------|----------|-------|
| BC-MOD-01 | `scopeActive($query)` | `where('is_active', true)` | Filter active |
| BC-MOD-02 | `scopeByFinancialYear($query, $fyId)` | `where('financial_year_id', $fyId)` | Filter by FY |
| BC-MOD-03 | `scopeByCostCenter($query, $ccId)` | `where('cost_center_id', $ccId)` | Filter by cost center |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete |
|-------|-----------|------------------|----------|
| BC-REF-01 | financial_year_id | acc_financial_years (id) | RESTRICT |
| BC-REF-02 | cost_center_id | acc_cost_centers (id) | RESTRICT |
| BC-REF-03 | ledger_id | acc_ledgers (id) | RESTRICT |
| BC-REF-04 | created_by | sys_users (id) | SET NULL (no DB FK) |

---

## 2. Test Case List

### 2.1 Positive Test Cases

| TC ID | Description | Expected Result | V2 Test | Status |
|-------|-------------|----------------|---------|--------|
| TC-P01 | List loads via Transactions tab | Cards show ledger, cost center, FY, amount. Empty state. | test_index_page_loads_via_transactions_tab | ✅ |
| TC-P02 | Create with valid data | Budget created with FY+CC+Ledger combo, amount, is_active=1. Flash. | test_create_budget_valid_data | ✅ |
| TC-P03 | Create — zero budgeted amount | budgeted_amount = 0.00 is allowed (min:0). | test_create_zero_amount | ✅ |
| TC-P04 | Edit — update budgeted_amount | Amount changed, other fields unchanged. | test_edit_update_amount | ✅ |
| TC-P05 | Edit — change ledger (unique combo) | Changing ledger to available combo allowed. Duplicate blocked. | test_edit_change_ledger | ✅ |
| TC-P06 | Toggle active status (AJAX) | Click toggle → is_active flips. JSON. | test_toggle_active_status | ✅ |
| TC-P07 | Full lifecycle: delete→trash→restore→force delete | All 5 states verified. | test_trash_restore_force_delete | ✅ |
| TC-P08 | Search budgets by ledger name | search via ledger name (hasWhere) matches results. | test_search_budgets | ✅ |
| TC-P09 | Filter by active/inactive status | Status filter shows correct results. | test_filter_by_status | ✅ |

### 2.2 Negative Test Cases

| TC ID | Description | Expected Result | V2 Test | Status |
|-------|-------------|----------------|---------|--------|
| TC-N01 | Create — required fields empty | Validation errors: financial_year_id, cost_center_id, ledger_id, budgeted_amount. | test_validation_requires_all_fields | ✅ |
| TC-N02 | Create — duplicate combo (FY+CC+Ledger) | Unique validation rejects duplicate. | test_validation_duplicate_combo | ✅ |
| TC-N03 | Create — negative budgeted amount | min:0 validation error. | test_validation_negative_amount | ✅ |
| TC-N04 | Create — invalid financial_year_id | exists validation error. | test_validation_invalid_fy | ✅ |
| TC-N05 | Create — invalid cost_center_id | exists validation error. | test_validation_invalid_cost_center | ✅ |
| TC-N06 | Create — invalid ledger_id | exists validation error. | test_validation_invalid_ledger | ✅ |
| TC-N07 | Edit — duplicate combo on update | Change to combo that already exists → unique error (ignores current). | test_edit_duplicate_combo | ✅ |
| TC-N08 | Permission denied (403) | User without permissions → 403. | test_permission_denied_returns_403 | ✅ |
| TC-N09 | Guest access redirect | Unauthenticated → /login. | test_guest_redirect_to_login | ✅ |
| TC-N10 | Invalid ID — show/edit/update/delete (404) | HTTP 404 for non-existent budget. | test_crud_invalid_id_returns_404 | ✅ |
| TC-N11 | Toggle invalid ID (404) | HTTP 404 for status toggle on non-existent budget. | test_toggle_invalid_id_404 | ✅ |
| TC-N12 | Empty trash page | Empty state when no trashed items. | test_empty_trash_page | ✅ |

### 2.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | Status |
|-------|----------|-------------|----------------|--------|
| TC-D01 | A | Budget variance report loads | Report renders with correct budget vs actual columns. | ⏸️ |
| TC-D02 | B | FK RESTRICT — cannot delete FY with budgets | Deleting FY with budgets → FK constraint error | ⏸️ |
| TC-D03 | C | FK RESTRICT — cannot delete CC with budgets | Deleting cost center with budgets → FK error | ⏸️ |
| TC-D04 | D | FK RESTRICT — cannot delete ledger with budgets | Deleting ledger with budgets → FK error | ⏸️ |
| TC-D05 | E | Budget variance shows actual from posted vouchers | Posting a voucher updates the variance report's actual column. | ⏸️ |

⏸️ = Skipped — requires cross-module setup

---

### 2.4 SweetAlert Confirmation Test Cases

| TC ID | Description | Expected Result | V2 Test | Status |
|-------|-------------|----------------|---------|--------|
| TC-SW01 | Edit — SweetAlert confirm opens edit form | Click Edit → SweetAlert shows confirmation → Confirm → edit form opens or operation proceeds | test_sweet_alert_edit_confirm | 🔴 |
| TC-SW02 | Soft Delete — SweetAlert confirm deletes record | Click Delete → SweetAlert shows confirmation → Confirm → record soft deleted | test_sweet_alert_delete_confirm | 🔴 |
| TC-SW03 | Soft Delete — SweetAlert cancel aborts deletion | Click Delete → SweetAlert shows confirmation → Cancel → deletion aborted, no change | test_sweet_alert_delete_cancel | 🔴 |
| TC-SW04 | Force Delete — SweetAlert confirm permanent deletes | Click Force Delete → SweetAlert shows "Delete Permanently?" → Confirm → record permanently deleted | test_sweet_alert_force_delete_confirm | 🔴 |
| TC-SW05 | Force Delete — SweetAlert cancel aborts deletion | Click Force Delete → SweetAlert shows "Delete Permanently?" → Cancel → deletion aborted | test_sweet_alert_force_delete_cancel | 🔴 |
| TC-SW06 | Restore — SweetAlert confirm restores record | Click Restore → SweetAlert shows confirmation → Confirm → record restored | test_sweet_alert_restore_confirm | 🔴 |
| TC-SW07 | Restore — SweetAlert cancel aborts restore | Click Restore → SweetAlert shows confirmation → Cancel → restore aborted | test_sweet_alert_restore_cancel | 🔴 |
| TC-SW08 | Toggle Status — SweetAlert confirm flips status | Click Toggle → SweetAlert shows confirmation → Confirm → status flipped | test_sweet_alert_toggle_confirm | 🔴 |

---

## 3. V2 Test Method Index

| # | Method | TC / BC Map | Category |
|---|--------|-------------|----------|
| 01 | test_migration_model_indexes_and_relationships | BC-DB-01 to BC-DB-17, BC-MOD-01/02/03 | Schema |
| 02 | test_index_page_loads_via_transactions_tab | TC-P01 | Positive |
| 03 | test_create_budget_valid_data | TC-P02, BC-VAL-01/04/05, BC-BIZ-01/02/12/17 | Positive |
| 04 | test_create_zero_amount | TC-P03, BC-VAL-04 | Positive |
| 05 | test_edit_update_amount | TC-P04, BC-BIZ-13/18 | Positive |
| 06 | test_edit_change_ledger | TC-P05, BC-VAL-03 | Positive |
| 07 | test_toggle_active_status | TC-P06, BC-BIZ-05/22 | Positive |
| 08 | test_trash_restore_force_delete | TC-P07, BC-BIZ-03/04/14/15/16/19/20/21 | Positive |
| 09 | test_search_budgets | TC-P08 | Positive |
| 10 | test_filter_by_status | TC-P09 | Positive |
| 11 | test_validation_requires_all_fields | TC-N01, BC-VAL-01/02/03/04 | Negative |
| 12 | test_validation_duplicate_combo | TC-N02, BC-VAL-03 | Negative |
| 13 | test_validation_negative_amount | TC-N03, BC-VAL-04 | Negative |
| 14 | test_validation_invalid_fy | TC-N04, BC-VAL-01 | Negative |
| 15 | test_validation_invalid_cost_center | TC-N05, BC-VAL-02 | Negative |
| 16 | test_validation_invalid_ledger | TC-N06, BC-VAL-03 | Negative |
| 17 | test_edit_duplicate_combo | TC-N07, BC-VAL-03 | Negative |
| 18 | test_permission_denied_returns_403 | TC-N08, BC-AUTH-01 to BC-AUTH-04 | Negative |
| 19 | test_guest_redirect_to_login | TC-N09 | Negative |
| 20 | test_crud_invalid_id_returns_404 | TC-N10 | Negative |
| 21 | test_toggle_invalid_id_404 | TC-N11 | Negative |
| 22 | test_empty_trash_page | TC-N12 | Negative |
| 23 | test_dependency_reports_fk_constraints | TC-D01 to TC-D05 | Dependency |

---

## 4. Coverage Summary

| Category | Total TCs | Full | Partial | Gap | Coverage % |
|----------|-----------|------|---------|-----|------------|
| Positive | 9 | 9 | 0 | 0 | **100%** |
| Negative | 12 | 12 | 0 | 0 | **100%** |
| SweetAlert | 8 | 0 | 0 | 8 | **0%** |
| Dependency | 5 | 0 | 0 | 5 | **0%** |
| **Total** | **34** | **21** | **0** | **13** | **62%** |

### BC Coverage: 100% BC-DB, BC-VAL, BC-AUTH, BC-MOD; 22/22 BC-BIZ covered

---

## 5. Route Reference

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | /accounting/transactions?tab=budgets | accounting.menu.transactions | viewAny |
| GET | /accounting/budget | accounting.budget.index | viewAny |
| GET | /accounting/budget/create | accounting.budget.create | create |
| POST | /accounting/budget | accounting.budget.store | create |
| GET | /accounting/budget/{budget} | accounting.budget.show | viewAny |
| GET | /accounting/budget/{budget}/edit | accounting.budget.edit | update |
| PUT/PATCH | /accounting/budget/{budget} | accounting.budget.update | update |
| DELETE | /accounting/budget/{budget} | accounting.budget.destroy | delete |
| POST | /accounting/budget/{budget}/toggle-status | accounting.budget.toggleStatus | update |
| GET | /accounting/budget/trash/view | accounting.budget.trashed | viewAny |
| GET | /accounting/budget/{id}/restore | accounting.budget.restore | create |
| DELETE | /accounting/budget/{id}/force-delete | accounting.budget.forceDelete | delete |
| GET | /accounting/report/budget-variance | accounting.report.budget-variance | viewAny |

---

## 6. Development Issues Found

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-01 | ReportService.php | Variance report joins voucher_items on ledger_id only — does NOT match cost_center_id. Actuals from different CC on same ledger counted against budget. | Medium | Open |
| DEV-02 | BudgetRequest | Budget unique rule ignored on create (should only ignore on edit). No test to confirm. | Low | Open |
| DEV-03 | Controller | `show()` uses `viewAny` permission instead of `view` | Low | Open |
| DEV-04 | BudgetPolicy.php | All permissions lack `tenant.` prefix while controller uses `tenant.` | **High** | Open |
| DEV-05 | DDL | No FK constraint on `created_by` | Medium | Open |
| DEV-06 | View | Create/edit form has `enctype="multipart/form-data"` with no file uploads | Low | Open |

---

## 7. Known Issues Summary

| ID | Issue | Status |
|----|-------|--------|
| KN-01 | Variance report doesn't match cost_center_id — actuals from different CC counted against same-ledger budget | Open |
| KN-02 | Permission prefix mismatch: controller `tenant.*` vs policy `accounting.*` | Open |
| KN-03 | No DB-level FK on `created_by` | Open |
| KN-04 | show() uses viewAny instead of view permission | Open |
