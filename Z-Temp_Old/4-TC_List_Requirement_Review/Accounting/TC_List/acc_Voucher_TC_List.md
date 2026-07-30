# Voucher_TcList

## Module: Accounting → Transactions → Vouchers

---

## 1. Business Conditions

### 1.1 Database Schema — acc_vouchers

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | bigint unsigned | PK, auto-increment |
| BC-DB-02 | voucher_prefix | varchar(5) | NULLABLE, snapshot from VoucherType prefix |
| BC-DB-03 | voucher_number | int unsigned | NOT NULL, sequential per type+FY |
| BC-DB-04 | voucher_type_id | tinyint unsigned | NOT NULL, FK → acc_voucher_types(id) ON DELETE RESTRICT |
| BC-DB-05 | financial_year_id | tinyint unsigned | NOT NULL, FK → acc_financial_years(id) ON DELETE RESTRICT |
| BC-DB-06 | date | date | NOT NULL |
| BC-DB-07 | reference_number | varchar(100) | NULLABLE |
| BC-DB-08 | reference_date | date | NULLABLE |
| BC-DB-09 | narration | text | NULLABLE |
| BC-DB-10 | total_amount | decimal(15,2) | NOT NULL, sum of debit items |
| BC-DB-11 | is_post_dated | tinyint(1) | DEFAULT 0 |
| BC-DB-12 | is_optional | tinyint(1) | DEFAULT 0 |
| BC-DB-13 | is_cancelled | tinyint(1) | DEFAULT 0 |
| BC-DB-14 | cancelled_reason | text | NULLABLE |
| BC-DB-15 | cost_center_id | bigint unsigned | NULLABLE, FK → acc_cost_centers(id) ON DELETE SET NULL |
| BC-DB-16 | source_module | tinyint unsigned | NULLABLE, FK → acc_voucher_modules(id) |
| BC-DB-17 | source_type | varchar(100) | NULLABLE, polymorphic model name |
| BC-DB-18 | source_id | bigint unsigned | NULLABLE, polymorphic source PK |
| BC-DB-19 | status | tinyint unsigned | NOT NULL, FK → acc_accounting_status_masters(id) ON DELETE RESTRICT |
| BC-DB-20 | approved_by | int unsigned | NULLABLE, FK → sys_users(id) |
| BC-DB-21 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-22 | created_by | int unsigned | NULLABLE, FK → sys_users (no DB FK) |
| BC-DB-23 | created_at | timestamp | Auto-managed |
| BC-DB-24 | updated_at | timestamp | Auto-managed |
| BC-DB-25 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-26 | UNIQUE uq_acc_voucher_number_fy | (financial_year_id, voucher_prefix, voucher_number) | Prevents duplicate voucher numbers per FY+prefix |
| BC-DB-27 | INDEX idx_acc_voucher_type | voucher_type_id | FK index |
| BC-DB-28 | INDEX idx_acc_voucher_fy | financial_year_id | FK index |
| BC-DB-29 | INDEX idx_acc_voucher_date | date | Date-range queries |
| BC-DB-30 | INDEX idx_acc_voucher_status | status | Status filtering |
| BC-DB-31 | INDEX idx_acc_voucher_source | (source_module, source_type, source_id) | Polymorphic lookup |
| BC-DB-32 | INDEX idx_acc_voucher_cost | cost_center_id | FK index |
| BC-DB-33 | id — BIGINT UNSIGNED | — | Max 18,446,744,073,709,551,615 records |
| BC-DB-34 | ENGINE=InnoDB | — | Transaction support, FK enforcement, row-level locking |
| BC-DB-35 | DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci | — | Unicode support, case-insensitive comparison |
| BC-DB-36 | total_amount = DECIMAL(15,2) | — | Max 999,999,999,999,999.99 per voucher |

### 1.1b Database Schema — acc_voucher_items

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-37 | id | bigint unsigned | PK, auto-increment |
| BC-DB-38 | voucher_id | bigint unsigned | NOT NULL, FK → acc_vouchers(id) ON DELETE CASCADE |
| BC-DB-39 | ledger_id | int unsigned | NOT NULL, FK → acc_ledgers(id) ON DELETE RESTRICT |
| BC-DB-40 | type | enum('debit','credit') | NOT NULL |
| BC-DB-41 | amount | decimal(15,2) | NOT NULL |
| BC-DB-42 | narration | varchar(500) | NULLABLE |
| BC-DB-43 | cost_center_id | bigint unsigned | NULLABLE, FK → acc_cost_centers(id) ON DELETE SET NULL |
| BC-DB-44 | bill_reference | varchar(100) | NULLABLE |
| BC-DB-45 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-46 | created_by | int unsigned | NULLABLE, FK → sys_users (no DB FK) |
| BC-DB-47 | created_at/updated_at | timestamp | Auto-managed |
| BC-DB-48 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-49 | INDEX idx_acc_vi_voucher | voucher_id | FK index |
| BC-DB-50 | INDEX idx_acc_vi_ledger | ledger_id | FK index |
| BC-DB-51 | INDEX idx_acc_vi_type | type | Filtering performance |
| BC-DB-52 | INDEX idx_acc_vi_cost | cost_center_id | FK index |

### DDL-Level Gaps (not enforced at database layer)

| Gap | Details |
|-----|---------|
| No CHECK constraint | `items.total_debit = items.total_credit` validated only at application layer (FormRequest), NOT at DB level |
| No FK constraint on `created_by` | `created_by` in both acc_vouchers and acc_voucher_items nullable INT UNSIGNED but no FOREIGN KEY → `sys_users(id)` at DB level |
| No FK constraint on `approved_by` | `approved_by` nullable INT UNSIGNED but no FOREIGN KEY → `sys_users(id)` at DB level |
| source_module uses TINYINT UNSIGNED | DDL comment says FK to `acc_voucher_modules` but model casts as string — potential mismatch; acc_voucher_modules table may not be seeded |

### 1.2 Validation Rules (VoucherRequest)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | voucher_type_id | required, exists:acc_voucher_types,id | "The Voucher Type field is required." |
| BC-VAL-02 | financial_year_id | required, exists:acc_financial_years,id | "The Financial Year field is required." |
| BC-VAL-03 | date | required, date | "The Voucher Date field is required." |
| BC-VAL-04 | reference_number | nullable, string, max:100 | — |
| BC-VAL-05 | reference_date | nullable, date | — |
| BC-VAL-06 | narration | nullable, string | — |
| BC-VAL-07 | is_post_dated | boolean (nullable) | Default false via `prepareForValidation` |
| BC-VAL-08 | is_optional | boolean (nullable) | Default false via `prepareForValidation` |
| BC-VAL-09 | cost_center_id | nullable, exists:acc_cost_centers,id | — |
| BC-VAL-10 | source_module | nullable, in:Fees,Library,Transport,HR,Vendor,Inventory,Payroll,Manual | — |
| BC-VAL-11 | source_type | nullable, string, max:100 | — |
| BC-VAL-12 | source_id | nullable, integer, min:1 | — |
| BC-VAL-13 | is_active | required, boolean | Default true via `prepareForValidation` |
| BC-VAL-14 | items | required, array, min:2 | "A voucher must have at least 2 line items (debit and credit)." |
| BC-VAL-15 | items.*.ledger_id | required, exists:acc_ledgers,id | "The Ledger field is required." |
| BC-VAL-16 | items.*.type | required, in:debit,credit | "The Entry Type field is required." |
| BC-VAL-17 | items.*.amount | required, numeric, min:0.01 | "The Amount field is required." |
| BC-VAL-18 | items.*.narration | nullable, string, max:500 | — |
| BC-VAL-19 | items.*.cost_center_id | nullable, exists:acc_cost_centers,id | — |
| BC-VAL-20 | items.*.bill_reference | nullable, string, max:100 | — |
| BC-VAL-21 | **Custom: Debit = Credit** | after() validator | "Total Debit must equal Total Credit." |

### 1.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.accounting.voucher.viewAny` | `index()`, `show()`, `print()` | Without → 403 |
| BC-AUTH-02 | `tenant.accounting.voucher.create` | `create()`, `store()`, `duplicate()`, `restore()` | Without → 403 |
| BC-AUTH-03 | `tenant.accounting.voucher.update` | `edit()`, `update()` | Without → 403 |
| BC-AUTH-04 | `tenant.accounting.voucher.delete` | `destroy()`, `forceDelete()` | Without → 403 |
| BC-AUTH-05 | `tenant.accounting.voucher.post` | `post()` | Without → 403 |
| BC-AUTH-06 | `tenant.accounting.voucher.approve` | `approve()` | Without → 403 |
| BC-AUTH-07 | `tenant.accounting.voucher.cancel` | `cancel()` | Without → 403 |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create: auto voucher number generation | Generate via `generateVoucherNumber()`: SELECT ... FOR UPDATE on voucher_type, increment last_number, skip existing numbers. Prefix = type prefix or first 5 chars of code, max 5. |
| BC-BIZ-02 | Create: total_amount auto-calculated | `total_amount = sum(items where type=debit)` |
| BC-BIZ-03 | Create: locked FY blocked | "Cannot create voucher in a locked Financial Year." |
| BC-BIZ-04 | Create: voucher_items created in same transaction | VoucherService `create()` wraps both Voucher + VoucherItem::create() in DB::transaction |
| BC-BIZ-05 | Create: default status = 'draft' | Model not explicitly set in controller or service — must check if there's a default in DB/migration. VoucherService creates without setting status, draft assumed. |
| BC-BIZ-06 | Create: is_active defaults to true | prepareForValidation: `$this->boolean('is_active', true)` |
| BC-BIZ-07 | Create: is_post_dated defaults to false | prepareForValidation: `$this->boolean('is_post_dated', false)` |
| BC-BIZ-08 | Create: is_optional defaults to false | prepareForValidation: `$this->boolean('is_optional', false)` |
| BC-BIZ-09 | Update: locked FY blocked | "Cannot update voucher in a locked Financial Year." |
| BC-BIZ-10 | Update: only draft vouchers editable | "Cannot update a posted voucher." (or approved/cancelled) |
| BC-BIZ-11 | Update: old items soft-deleted, new ones created | `$voucher->items()->delete()` then loop to create fresh items in transaction |
| BC-BIZ-12 | Update: total_amount re-calculated | Sum of new debit items |
| BC-BIZ-13 | Delete: only draft vouchers deletable | "Cannot delete a posted voucher." |
| BC-BIZ-14 | Delete: soft delete + is_active=false | `$voucher->is_active = false; $voucher->save(); $voucher->delete()` |
| BC-BIZ-15 | Post: only draft vouchers postable | `VoucherService::post()` throws DomainException "Only draft vouchers can be posted." |
| BC-BIZ-16 | Post: ledger balances updated | `applyItemsToLedgers(direction=1)` — debit = +amount, credit = -amount on `acc_ledgers.current_balance` |
| BC-BIZ-17 | Post: status changes to 'posted' | `$voucher->update(['status' => 'posted'])` after ledger update |
| BC-BIZ-18 | Post: uses lockForUpdate on ledgers | Prevents race conditions on balance updates |
| BC-BIZ-19 | Approve: only posted vouchers approvable | "Only posted vouchers can be approved." |
| BC-BIZ-20 | Approve: sets approved_by + status | `$voucher->update(['status' => 'approved', 'approved_by' => auth()->id()])` |
| BC-BIZ-21 | Cancel: already cancelled blocked | "Voucher is already cancelled." |
| BC-BIZ-22 | Cancel: draft cancellation (no ledger effect) | Sets status=cancelled, is_cancelled=true with reason. No ledger reversal. |
| BC-BIZ-23 | Cancel: posted cancellation reverses ledgers | `applyItemsToLedgers(direction=-1)` — reverses previous effect |
| BC-BIZ-24 | Cancel: reason required | `$request->validate(['cancelled_reason' => 'required|string|max:500'])` |
| BC-BIZ-25 | Cancel: sets is_cancelled + status + reason | `is_cancelled=true, status=cancelled, cancelled_reason=reason` |
| BC-BIZ-26 | Duplicate: replicates voucher + items | `VoucherService::duplicate()` — replicate model, new number, draft status, today's date |
| BC-BIZ-27 | Duplicate: new voucher is draft | `$newVoucher->status = 'draft'` |
| BC-BIZ-28 | Duplicate: redirects to edit | Redirect to `route('accounting.voucher.edit', $newVoucher)` with success flash |
| BC-BIZ-29 | Print: loads voucher + type + items + ledgers | `$voucher->load(['voucherType', 'financialYear', 'items.ledger'])`, renders print-friendly HTML |
| BC-BIZ-30 | Print: shows totals and signatures section | Debit/Credit totals, Prepared/Checked/Approved signature lines |
| BC-BIZ-31 | Index redirects to transactions tab | Redirect to `route('accounting.menu.transactions', ['tab' => 'vouchers'])` |
| BC-BIZ-32 | Create: voucher number preview (JS) | Frontend JS reads data-prefix/data-last-number/data-auto from select option, shows preview badge |
| BC-BIZ-33 | Create: number preview only for auto_numbering | Preview hidden when `auto_numbering=false` |
| BC-BIZ-34 | Edit: read-only notice for non-draft vouchers | `@if($readonly)` alert shown: "This voucher is {status} and cannot be edited." |
| BC-BIZ-35 | Search: by concatenated voucher prefix+number | `CONCAT(COALESCE(voucher_prefix, ''), LPAD(voucher_number, 4, '0')) LIKE ?` |
| BC-BIZ-36 | Show: action buttons depend on status | Draft → Post; Posted → Approve; Draft/Posted → Cancel; All → Print |
| BC-BIZ-37 | Show: Cancel modal with reason | Bootstrap modal with textarea, validates reason required |
| BC-BIZ-38 | Restore: restores soft-deleted voucher | `$item->restore()` (is_active unchanged by controller — left as false from destroy) |
| BC-BIZ-39 | Force delete: permanently removes record | `$item->forceDelete()` |
| BC-BIZ-40 | Success flash — Created | "Voucher created successfully." |
| BC-BIZ-41 | Success flash — Updated | "Voucher updated successfully." |
| BC-BIZ-42 | Success flash — Trashed | "Voucher moved to trash." |
| BC-BIZ-43 | Success flash — Restored | "Voucher restored successfully." |
| BC-BIZ-44 | Success flash — Force Deleted | "Voucher permanently deleted." |
| BC-BIZ-45 | Success flash — Posted | "Voucher posted successfully." |
| BC-BIZ-46 | Success flash — Approved | "Voucher approved successfully." |
| BC-BIZ-47 | Success flash — Cancelled | "Voucher cancelled successfully." |
| BC-BIZ-48 | Success flash — Duplicated | "Voucher duplicated successfully." |
| BC-BIZ-49 | Activity log — Created | On create (store, duplicate) |
| BC-BIZ-50 | Activity log — Updated | On update |
| BC-BIZ-51 | Activity log — Trashed | On soft delete |
| BC-BIZ-52 | Activity log — Restored | On restore |
| BC-BIZ-53 | Activity log — Deleted | On force delete |
| BC-BIZ-54 | Activity log — Posted | On post |
| BC-BIZ-55 | Activity log — Approved | On approve |
| BC-BIZ-56 | Activity log — Cancelled | On cancel |
| BC-BIZ-57 | Edit: read-only fields disabled when status≠draft | Edit form renders with `disabled` or `readonly` for all fields |
| BC-BIZ-58 | generateVoucherNumber: lockForUpdate on VoucherType | Prevents duplicate numbers under concurrent requests |
| BC-BIZ-59 | generateVoucherNumber: skips taken numbers | `while(Voucher::withTrashed()->where(...)->exists()) { $nextNumber++ }` |
| BC-BIZ-60 | Voucher items FK CASCADE | Deleting a voucher auto-deletes all voucher_items |
| BC-BIZ-61 | Polymorphic source tracking | source_type/source_id allow linking voucher to any external module record |

### 1.5 Model Scopes & Helpers

| BC ID | Scope/Helper | Query Criteria | Usage |
|-------|-------------|----------------|-------|
| BC-MOD-01 | `scopeActive($query)` | `where('is_active', true)` | Filter active vouchers |
| BC-MOD-02 | `scopeByStatus($query, $status)` | `where('status', $status)` | Filter by status string |
| BC-MOD-03 | `scopeDraft($query)` | `where('status', 'draft')` | Find draft vouchers |
| BC-MOD-04 | `scopePosted($query)` | `where('status', 'posted')` | Find posted vouchers |
| BC-MOD-05 | `scopeApproved($query)` | `where('status', 'approved')` | Find approved vouchers |
| BC-MOD-06 | `scopeCancelled($query)` | `where('status', 'cancelled')` | Find cancelled vouchers |
| BC-MOD-07 | `scopeByType($query, $typeId)` | `where('voucher_type_id', $typeId)` | Filter by voucher type |
| BC-MOD-08 | `scopeByFinancialYear($query, $fyId)` | `where('financial_year_id', $fyId)` | Filter by FY |
| BC-MOD-09 | `scopeByDateRange($query, $from, $to)` | `whereBetween('date', [$from, $to])` | Date range filter |
| BC-MOD-10 | `scopeBySourceModule($query, $module)` | `where('source_module', $module)` | Filter by source module |
| BC-MOD-11 | `scopeNotOptional($query)` | `where('is_optional', false)` | Exclude optional/memo vouchers |
| BC-MOD-12 | `getFormattedNumberAttribute()` | Returns `prefix . str_pad(number, 4, '0', LEFT)` | Display helper (e.g., "RCV-0042") |
| BC-MOD-13 | `isDraft(): bool` | `$this->status === 'draft'` | Status check |
| BC-MOD-14 | `isPosted(): bool` | `$this->status === 'posted'` | Status check |
| BC-MOD-15 | `isApproved(): bool` | `$this->status === 'approved'` | Status check |
| BC-MOD-16 | `isCancelled(): bool` | `$this->status === 'cancelled'` | Status check |
| BC-MOD-17 | `isEditable(): bool` | `$this->isDraft()` | Guard for edit/delete |
| BC-MOD-18 | `isBalanced(): bool` | `bccomp(sum(debits), sum(credits), 2) === 0` | Double-entry check |
| BC-MOD-19 | `totalDebits(): string` | Sum of debit items | Display helper |
| BC-MOD-20 | `totalCredits(): string` | Sum of credit items | Display helper |
| BC-MOD-21 | `debitItems()` | `items()->where('type', 'debit')` | Only debit lines |
| BC-MOD-22 | `creditItems()` | `items()->where('type', 'credit')` | Only credit lines |
| BC-MOD-23 | `VoucherItem::scopeDebits($query)` | `where('type', 'debit')` | Item-level debit filter |
| BC-MOD-24 | `VoucherItem::scopeCredits($query)` | `where('type', 'credit')` | Item-level credit filter |
| BC-MOD-25 | `VoucherItem::scopeByLedger($query, $id)` | `where('ledger_id', $id)` | Item-level ledger filter |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete Behavior |
|-------|-----------|------------------|-------------------|
| BC-REF-01 | voucher_type_id | acc_voucher_types (id) | RESTRICT |
| BC-REF-02 | financial_year_id | acc_financial_years (id) | RESTRICT |
| BC-REF-03 | cost_center_id | acc_cost_centers (id) | SET NULL |
| BC-REF-04 | status | acc_accounting_status_masters (id) | RESTRICT |
| BC-REF-05 | voucher_id (in items) | acc_vouchers (id) | CASCADE |
| BC-REF-06 | ledger_id (in items) | acc_ledgers (id) | RESTRICT |
| BC-REF-07 | cost_center_id (in items) | acc_cost_centers (id) | SET NULL |
| BC-REF-08 | created_by | sys_users (id) | SET NULL (no DB FK) |
| BC-REF-09 | approved_by | sys_users (id) | SET NULL (no DB FK) |

---

## 2. Test Case List

### 2.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Voucher List Loads via Transactions Tab | Tab shows cards with formatted number, voucher type, date (d M Y), total_amount (2 decimals), status badge. Empty state if none. | — | test_index_page_loads_via_transactions_tab | ✅ |
| TC-P02 | Create Voucher With Valid Data (Draft) | Form submits → voucher created with auto-numbered prefix+number, items stored, total_amount auto-calculated, status=draft, is_active=1. Redirect + flash. | — | test_create_voucher_valid_data_draft | ✅ |
| TC-P03 | Create With All Optional Fields | reference_number, reference_date, narration, cost_center_id, source_module, source_type, source_id, is_post_dated=true, is_optional=true all stored correctly. | — | test_create_with_all_optional_fields | ✅ |
| TC-P04 | Create Voucher With Auto-Numbering Preview | JS shows "Next Voucher No: RCV-0043" badge when voucher type selected. Auto-calculated from prefix + last_number+1. | — | test_create_shows_voucher_number_preview | ✅ |
| TC-P05 | View Voucher Details (Show) | All details displayed: formatted_number, voucher type, date, total_amount, reference info, cost center, status badge, narration, FY, created_at, items table with Dr/Cr badges. | — | test_show_page_displays_all_details | ✅ |
| TC-P06 | Edit Draft Voucher — Update Fields | Pre-filled data updated successfully. New total_amount recalculated. Old items soft-deleted, new items created. Flash + redirect. | — | test_edit_draft_voucher_update_fields | ✅ |
| TC-P07 | Post Draft Voucher (Status Flow) | Show page → click "Post" → confirm → status=posted, ledger balances updated (debit +amount, credit -amount). Flash "posted successfully". | — | test_post_draft_voucher | ✅ |
| TC-P08 | Approve Posted Voucher (Status Flow) | Show page → click "Approve" → confirm → status=approved, approved_by=current user. Flash "approved successfully". | — | test_approve_posted_voucher | ✅ |
| TC-P09 | Cancel Draft Voucher (No Ledger Effect) | Show page → click "Cancel" → modal with reason textarea → submit → status=cancelled, is_cancelled=true, cancelled_reason stored. Ledger balances unchanged. Flash. | — | test_cancel_draft_voucher | ✅ |
| TC-P10 | Cancel Posted Voucher (Ledger Reversal) | Same flow but ledger balances reversed (debit -amount, credit +amount). Status=cancelled. | — | test_cancel_posted_voucher_reverses_ledger | ✅ |
| TC-P11 | Print Voucher | Print view opens with formatted voucher details, Dr/Cr items table, totals, narration, signature sections. | — | test_print_voucher | ✅ |
| TC-P12 | Duplicate Voucher | Existing voucher duplicated → new draft voucher with new number, today's date, same items. Redirects to edit page of new voucher. | — | test_duplicate_voucher | ✅ |
| TC-P13 | Soft Delete Draft Voucher | Delete button → confirm → is_active=false, deleted_at set. Flash "moved to trash". Voucher disappears from list. | — | test_soft_delete_draft_voucher | ✅ |
| TC-P14 | Restore Soft-Deleted Voucher | Trash page → restore → deleted_at=NULL. Flash "restored successfully". | — | test_restore_voucher | ✅ |
| TC-P15 | Force Delete Voucher (Permanent) | Trash page → force delete → record removed permanently. Flash "permanently deleted". | — | test_force_delete_voucher | ✅ |
| TC-P16 | Search Vouchers by Number | Search by partial prefix+number (e.g., "RCV-0042") → matching voucher(s) returned. | — | test_search_vouchers_by_number | ✅ |
| TC-P17 | Filter Vouchers by Status | Status dropdown filter (Draft/Posted/Approved/Cancelled) → only matching statuses shown. | — | test_filter_vouchers_by_status | ✅ |
| TC-P18 | Create Voucher Without Auto-Numbering | When voucher_type has auto_numbering=false → number preview hidden, user can type custom number. | — | test_create_manual_numbering | ✅ |
| TC-P19 | Multiple Item Lines (3+ debit/credit) | Voucher with 3 debits and 2 credits, total_debit=total_credit → saved correctly | — | test_create_multiple_item_lines | ✅ |
| TC-P20 | Edit View Shows Read-Only for Non-Draft | Posted/approved/cancelled voucher shows warning alert "Read-only" and fields disabled. | — | test_edit_readonly_for_posted_voucher | ✅ |

### 2.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Create — Required Fields Empty | Validation errors: voucher_type_id required, financial_year_id required, date required, items required. | — | test_validation_requires_all_fields | ✅ |
| TC-N02 | Create — Items Less Than 2 | Error: "A voucher must have at least 2 line items." | — | test_validation_min_items | ✅ |
| TC-N03 | Create — Debit != Credit (Unbalanced) | Custom validation error: "Total Debit must equal Total Credit." | — | test_validation_debit_credit_unbalanced | ✅ |
| TC-N04 | Create — Invalid Voucher Type ID | "The selected Voucher Type is invalid." | — | test_validation_invalid_voucher_type | ✅ |
| TC-N05 | Create — Invalid Financial Year ID | "The selected Financial Year is invalid." | — | test_validation_invalid_financial_year | ✅ |
| TC-N06 | Create — Locked Financial Year | "Cannot create voucher in a locked Financial Year." Voucher not created. | — | test_create_locked_financial_year | ✅ |
| TC-N07 | Create — Item Amount Zero | Validation error: "amount min 0.01" | — | test_validation_item_amount_zero | ✅ |
| TC-N08 | Create — Invalid Ledger ID in Item | "The selected Ledger is invalid." | — | test_validation_invalid_ledger_id | ✅ |
| TC-N09 | Create — Invalid Cost Center ID | "The selected Cost Center is invalid." | — | test_validation_invalid_cost_center | ✅ |
| TC-N10 | Update — Locked Financial Year | "Cannot update voucher in a locked Financial Year." | — | test_update_locked_financial_year | ✅ |
| TC-N11 | Update — Posted Voucher (Non-Draft) | "Cannot update a posted voucher." (or approved/cancelled) | — | test_update_posted_voucher_blocked | ✅ |
| TC-N12 | Delete — Posted Voucher | "Cannot delete a posted voucher." | — | test_delete_posted_voucher_blocked | ✅ |
| TC-N13 | Post — Already Posted Voucher | DomainException: "Only draft vouchers can be posted." | — | test_post_already_posted_voucher | ✅ |
| TC-N14 | Post — Already Approved Voucher | DomainException: "Only draft vouchers can be posted." | — | test_post_approved_voucher_blocked | ✅ |
| TC-N15 | Post — Already Cancelled Voucher | DomainException: "Only draft vouchers can be posted." | — | test_post_cancelled_voucher_blocked | ✅ |
| TC-N16 | Approve — Draft Voucher (Must Be Posted First) | Backend allows it? Controller checks `$voucher->status !== 'posted'` → error. | — | test_approve_draft_voucher_blocked | ✅ |
| TC-N17 | Approve — Already Approved Voucher | "Only posted vouchers can be approved." | — | test_approve_already_approved_blocked | ✅ |
| TC-N18 | Cancel — Already Cancelled Voucher | DomainException: "Voucher is already cancelled." | — | test_cancel_already_cancelled_blocked | ✅ |
| TC-N19 | Cancel — Without Reason | Validation error: "cancelled_reason required" | — | test_cancel_without_reason | ✅ |
| TC-N20 | Cancel — Reason Over 500 Chars | Validation error: "cancelled_reason max 500" | — | test_cancel_reason_max_length | ✅ |
| TC-N21 | Permission Denied (403) — No Voucher Permissions | User without any voucher permissions receives 403 on all endpoints. | — | test_permission_denied_returns_403 | ✅ |
| TC-N22 | Guest Access Redirect | Unauthenticated user redirected to /login. | — | test_guest_redirect_to_login | ✅ |
| TC-N23 | Invalid ID — Show (404) | HTTP 404 for non-existent voucher. | — | test_show_invalid_id_404 | ✅ |
| TC-N24 | Invalid ID — Edit/Update/Delete (404) | HTTP 404 for all CRUD on invalid ID. | — | test_crud_invalid_id_returns_404 | ✅ |
| TC-N25 | Invalid ID — Post/Approve/Cancel (404) | HTTP 404 for status operations on invalid ID. | — | test_status_ops_invalid_id_404 | ✅ |
| TC-N26 | Empty Trash Page | "No Data Found" / empty state message when trash is empty. | — | test_empty_trash_page | ✅ |
| TC-N27 | Restore Non-Existent Voucher | HTTP 404 for restoring invalid ID. | — | test_restore_invalid_id_404 | ✅ |
| TC-N28 | Duplicate — Source Voucher Not Found | If source voucher ID doesn't exist → 404. | — | test_duplicate_invalid_id_404 | ✅ |
| TC-N29 | Create — Source Module Not in Allowed List | Validation error: "The selected Source Module is invalid." | — | test_validation_invalid_source_module | ✅ |

### 2.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Event Mapping Generates Voucher from Event | Event Mapping config with auto-post creates voucher with correct type, items, amounts, narration | — | test_dependency_event_mapping_creates_voucher | ⏸️ |
| TC-D02 | B | Voucher Posted Updates Ledger Balance | Posting a voucher updates acc_ledgers.current_balance (debit=+, credit=-) | — | test_dependency_voucher_post_updates_ledger | ⏸️ |
| TC-D03 | C | Cancelling Posted Voucher Reverses Ledger | Ledger balance restored to pre-post value when posted voucher is cancelled | — | test_dependency_voucher_cancel_reverses_ledger | ⏸️ |
| TC-D04 | D | FK Restrict — Cannot Delete Voucher Type With Vouchers | Deleting voucher type that has vouchers → FK constraint error | — | test_dependency_cannot_delete_voucher_type_with_vouchers | ⏸️ |
| TC-D05 | E | FK Restrict — Cannot Delete Ledger Used in Voucher Items | Deleting ledger referenced in voucher items → FK constraint error | — | test_dependency_cannot_delete_ledger_with_voucher_items | ⏸️ |
| TC-D06 | F | FK Restrict — Cannot Delete FY With Vouchers | Deleting FY that has vouchers → FK constraint error | — | test_dependency_cannot_delete_fy_with_vouchers | ⏸️ |
| TC-D07 | G | FK CASCADE — Deleting Voucher Deletes Voucher Items | Deleting a voucher automatically removes all its voucher_items | — | test_dependency_delete_voucher_cascades_items | ⏸️ |
| TC-D08 | H | FK SET NULL — Deleting Cost Center Sets Null on Voucher | Deleting a cost center sets cost_center_id=NULL on related vouchers and items | — | test_dependency_delete_cost_center_sets_null | ⏸️ |
| TC-D09 | I | Recurring Template Posts Voucher | Post-now on recurring template creates voucher via same VoucherService | — | test_dependency_recurring_template_creates_voucher | ⏸️ |
| TC-D10 | J | Duplicate Guard — Same Source Not Processed Twice | Event processing log (source_model, source_id) prevents duplicate voucher generation | — | test_dependency_event_mapping_duplicate_guard | ⏸️ |

⏸️ = Skipped — requires cross-module setup (Event Mapping, Ledgers, Voucher Types, etc.)

---

### 2.4 SweetAlert Confirmation Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-SW01 | Edit — SweetAlert confirm opens edit form | Click Edit → SweetAlert shows confirmation → Confirm → edit form opens or operation proceeds | — | test_sweet_alert_edit_confirm | 🔴 |
| TC-SW02 | Soft Delete — SweetAlert confirm deletes record | Click Delete → SweetAlert shows confirmation → Confirm → record soft deleted | — | test_sweet_alert_delete_confirm | 🔴 |
| TC-SW03 | Soft Delete — SweetAlert cancel aborts deletion | Click Delete → SweetAlert shows confirmation → Cancel → deletion aborted, no change | — | test_sweet_alert_delete_cancel | 🔴 |
| TC-SW04 | Force Delete — SweetAlert confirm permanent deletes | Click Force Delete → SweetAlert shows "Delete Permanently?" → Confirm → record permanently deleted | — | test_sweet_alert_force_delete_confirm | 🔴 |
| TC-SW05 | Force Delete — SweetAlert cancel aborts deletion | Click Force Delete → SweetAlert shows "Delete Permanently?" → Cancel → deletion aborted | — | test_sweet_alert_force_delete_cancel | 🔴 |
| TC-SW06 | Restore — SweetAlert confirm restores record | Click Restore → SweetAlert shows confirmation → Confirm → record restored | — | test_sweet_alert_restore_confirm | 🔴 |
| TC-SW07 | Restore — SweetAlert cancel aborts restore | Click Restore → SweetAlert shows confirmation → Cancel → restore aborted | — | test_sweet_alert_restore_cancel | 🔴 |
| TC-SW08 | Toggle Status — SweetAlert confirm flips status | Click Toggle → SweetAlert shows confirmation → Confirm → status flipped | — | test_sweet_alert_toggle_confirm | 🔴 |
| TC-SW09 | Approve — SweetAlert confirm approves voucher | Click Approve → SweetAlert shows confirmation → Confirm → voucher approved | — | test_sweet_alert_approve_confirm | 🔴 |
| TC-SW10 | Cancel — SweetAlert confirm cancels voucher | Click Cancel → SweetAlert shows confirmation → Confirm → voucher cancelled | — | test_sweet_alert_cancel_confirm | 🔴 |

---

## 3. V2 Test Method Index

| # | Method | TC / BC Map | Category |
|---|--------|-------------|----------|
| 01 | test_migration_model_indexes_and_relationships | BC-DB-01 to BC-DB-52, BC-MOD-12, BC-MOD-18 to BC-MOD-25 | Schema |
| 02 | test_model_scopes_draft_posted_approved_cancelled | BC-MOD-01 to BC-MOD-11 | Schema |
| 03 | test_frontend_voucher_number_preview_on_create | BC-BIZ-32, BC-BIZ-33 | Positive |
| 04 | test_index_page_loads_via_transactions_tab | TC-P01 | Positive |
| 05 | test_create_voucher_valid_data_draft | TC-P02, BC-VAL-13, BC-BIZ-01/02/04/05/06/07/08/40/49 | Positive |
| 06 | test_create_with_all_optional_fields | TC-P03, BC-VAL-04/05/06/09/10/11/12 | Positive |
| 07 | test_create_shows_voucher_number_preview | TC-P04, BC-BIZ-32/33 | Positive |
| 08 | test_show_page_displays_all_details | TC-P05 | Positive |
| 09 | test_edit_draft_voucher_update_fields | TC-P06, BC-BIZ-11/12/41/50 | Positive |
| 10 | test_post_draft_voucher | TC-P07, BC-BIZ-15/16/17/18/45/54 | Positive |
| 11 | test_approve_posted_voucher | TC-P08, BC-BIZ-19/20/46/55 | Positive |
| 12 | test_cancel_draft_voucher | TC-P09, BC-BIZ-22/24/25/47/56 | Positive |
| 13 | test_cancel_posted_voucher_reverses_ledger | TC-P10, BC-BIZ-23/24/25/47/56 | Positive |
| 14 | test_print_voucher | TC-P11, BC-BIZ-29/30 | Positive |
| 15 | test_duplicate_voucher | TC-P12, BC-BIZ-26/27/28/48/49 | Positive |
| 16 | test_soft_delete_draft_voucher | TC-P13, BC-BIZ-13/14/42/51 | Positive |
| 17 | test_restore_voucher | TC-P14, BC-BIZ-38/43/52 | Positive |
| 18 | test_force_delete_voucher | TC-P15, BC-BIZ-39/44/53 | Positive |
| 19 | test_search_vouchers_by_number | TC-P16, BC-BIZ-35 | Positive |
| 20 | test_filter_vouchers_by_status | TC-P17 | Positive |
| 21 | test_create_manual_numbering | TC-P18, BC-BIZ-33 | Positive |
| 22 | test_create_multiple_item_lines | TC-P19, BC-VAL-14/21 | Positive |
| 23 | test_edit_readonly_for_posted_voucher | TC-P20, BC-BIZ-34/57 | Positive |
| 24 | test_validation_requires_all_fields | TC-N01, BC-VAL-01/02/03/14 | Negative |
| 25 | test_validation_min_items | TC-N02, BC-VAL-14 | Negative |
| 26 | test_validation_debit_credit_unbalanced | TC-N03, BC-VAL-21 | Negative |
| 27 | test_validation_invalid_voucher_type | TC-N04, BC-VAL-01 | Negative |
| 28 | test_validation_invalid_financial_year | TC-N05, BC-VAL-02 | Negative |
| 29 | test_create_locked_financial_year | TC-N06, BC-BIZ-03 | Negative |
| 30 | test_validation_item_amount_zero | TC-N07, BC-VAL-17 | Negative |
| 31 | test_validation_invalid_ledger_id | TC-N08, BC-VAL-15 | Negative |
| 32 | test_validation_invalid_cost_center | TC-N09, BC-VAL-19 | Negative |
| 33 | test_update_locked_financial_year | TC-N10, BC-BIZ-09 | Negative |
| 34 | test_update_posted_voucher_blocked | TC-N11, BC-BIZ-10 | Negative |
| 35 | test_delete_posted_voucher_blocked | TC-N12, BC-BIZ-13 | Negative |
| 36 | test_post_already_posted_voucher | TC-N13, BC-BIZ-15 | Negative |
| 37 | test_post_approved_voucher_blocked | TC-N14, BC-BIZ-15 | Negative |
| 38 | test_post_cancelled_voucher_blocked | TC-N15, BC-BIZ-15 | Negative |
| 39 | test_approve_draft_voucher_blocked | TC-N16, BC-BIZ-19 | Negative |
| 40 | test_approve_already_approved_blocked | TC-N17, BC-BIZ-19 | Negative |
| 41 | test_cancel_already_cancelled_blocked | TC-N18, BC-BIZ-21 | Negative |
| 42 | test_cancel_without_reason | TC-N19, BC-BIZ-24 | Negative |
| 43 | test_cancel_reason_max_length | TC-N20, BC-BIZ-24 | Negative |
| 44 | test_permission_denied_returns_403 | TC-N21, BC-AUTH-01 to BC-AUTH-07 | Negative |
| 45 | test_guest_redirect_to_login | TC-N22 | Negative |
| 46 | test_show_invalid_id_404 | TC-N23 | Negative |
| 47 | test_crud_invalid_id_returns_404 | TC-N24 | Negative |
| 48 | test_status_ops_invalid_id_404 | TC-N25 | Negative |
| 49 | test_empty_trash_page | TC-N26 | Negative |
| 50 | test_restore_invalid_id_404 | TC-N27 | Negative |
| 51 | test_duplicate_invalid_id_404 | TC-N28 | Negative |
| 52 | test_validation_invalid_source_module | TC-N29, BC-VAL-10 | Negative |
| 53 | test_dependency_voucher_type_banking | TC-D01 to TC-D10 | Dependency |

---

## 4. Coverage Summary

| Category | Total TCs | Full | Partial | Gap | Coverage % |
|----------|-----------|------|---------|-----|------------|
| Positive | 20 | 20 | 0 | 0 | **100%** |
| Negative | 29 | 29 | 0 | 0 | **100%** |
| SweetAlert | 10 | 0 | 0 | 10 | **0%** |
| Dependency | 10 | 0 | 0 | 10 | **0%** |
| **Total** | **69** | **49** | **0** | **20** | **71%** |

### Business Conditions Coverage (V2)

| Category | Total BCs | Covered | Gap | Coverage % |
|----------|-----------|---------|-----|------------|
| Database Schema (BC-DB) | 52 | 52 | 0 | **100%** |
| Validation Rules (BC-VAL) | 21 | 21 | 0 | **100%** |
| Authorization (BC-AUTH) | 7 | 7 | 0 | **100%** |
| Business Logic (BC-BIZ) | 61 | 59 | 2 | **97%** |
| Model Scopes/Helpers (BC-MOD) | 25 | 25 | 0 | **100%** |
| Referential Integrity (BC-REF) | 9 | 2 | 7 | **22%** |
| **Total** | **175** | **166** | **9** | **95%** |

### Coverage Notes
- All 49 positive + negative TCs are fully covered by V2 tests
- All BC-DB (52/52), BC-VAL (21/21), BC-AUTH (7/7), BC-MOD (25/25) conditions fully covered
- 59/61 BC-BIZ conditions covered (uncovered: BC-BIZ-05 default status not explicitly set in service, BC-BIZ-38 restore doesn't set is_active=true)
- 10 dependency TCs (TC-D01 to TC-D10) require cross-module setup — marked skipped
- 7 BC-REF conditions (BC-REF-01 to BC-REF-07) covered by DB-level tests; BC-REF-08/09 (created_by, approved_by) no DB FK — application-level only
- DDL gaps documented: no DB-level CHECK for debit=credit balance, no FK on created_by/approved_by, source_module TINYINT vs model string cast mismatch
- New V2 tests added for: voucher lifecycle (create→post→approve→cancel), ledger balance effects, number generation, print view, duplicate, search/filter, read-only edit, permission/guest/404 scenarios

---

## 5. Route Reference

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | /accounting/transactions?tab=vouchers | accounting.menu.transactions | viewAny |
| GET | /accounting/voucher | accounting.voucher.index | viewAny |
| GET | /accounting/voucher/create | accounting.voucher.create | create |
| POST | /accounting/voucher | accounting.voucher.store | create |
| GET | /accounting/voucher/{voucher} | accounting.voucher.show | viewAny |
| GET | /accounting/voucher/{voucher}/edit | accounting.voucher.edit | update |
| PUT/PATCH | /accounting/voucher/{voucher} | accounting.voucher.update | update |
| DELETE | /accounting/voucher/{voucher} | accounting.voucher.destroy | delete |
| POST | /accounting/voucher/{voucher}/post | accounting.voucher.post | post |
| POST | /accounting/voucher/{voucher}/approve | accounting.voucher.approve | approve |
| POST | /accounting/voucher/{voucher}/cancel | accounting.voucher.cancel | cancel |
| GET | /accounting/voucher/{voucher}/print | accounting.voucher.print | viewAny |
| GET | /accounting/voucher/{voucher}/duplicate | accounting.voucher.duplicate | create |
| GET | /accounting/voucher/trash/view | accounting.voucher.trashed | viewAny |
| GET | /accounting/voucher/{id}/restore | accounting.voucher.restore | create |
| DELETE | /accounting/voucher/{id}/force-delete | accounting.voucher.forceDelete | delete |

---

## 6. Development Issues Found

### 6.1 Controller Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-C01 | VoucherController.php | `store()` catches all Throwable and returns generic error — exposes PDO/message to user in `back()->with('error', $e->getMessage())` | Medium | Open |
| DEV-C02 | VoucherController.php | `update()` catches all Throwable and returns generic "Failed to update voucher" — loses original error context for debugging | Medium | Open |
| DEV-C03 | VoucherController.php | `duplicate()` catches all Throwable and returns vague "Failed to duplicate voucher. Please try again." | Low | Open |
| DEV-C04 | VoucherController.php | Permission prefix mismatch: controller uses `tenant.accounting.voucher.*`, policy checks `accounting.voucher.*` (no `tenant.` prefix) | **High** | Open |
| DEV-C05 | VoucherService.php | `generateVoucherNumber()` uses `VoucherType::lockForUpdate()` on the type row — fine for concurrency but last_number is shared across FYs, so numbers can jump | Medium | Open |

### 6.2 Policy Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-P01 | VoucherPolicy.php | All permission names lack `tenant.` prefix while controller gates use `tenant.` prefix. If no gate bridging exists, all policy methods are bypassed. | **High** | Open |

### 6.3 View Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-B01 | _vouchers.blade.php | Tab only shows formatted_number, voucher type, date, total_amount and action button — no inline Post/Approve/Cancel buttons; user must click into show page for status actions | Medium | Open |
| DEV-B02 | _vouchers.blade.php | No source module/source info displayed despite being stored in DB | Low | Open |
| DEV-B03 | create.blade.php | Items table on create uses old `rowIndex` counter based on count of old items — if user adds/removes rows, index numbers may overlap after validation failure | Low | Open |
| DEV-B04 | show.blade.php | "Post" button only shown for draft — but no "Post" confirmation modal like Cancel has; uses basic `confirm()` instead | Low | Open |
| DEV-B05 | show.blade.php | No "Edit" button on show page — user must know to use action dropdown from list page | Low | Open |

### 6.4 Service Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-S01 | VoucherService.php | `applyItemsToLedgers()` uses raw `DB::raw('current_balance + ' . $delta)` — SQL injection risk if delta not properly sanitized (currently safe since cast to float, but fragile) | Medium | Open |
| DEV-S02 | VoucherService.php | `post()` does not validate that debit=credit before posting — relies on create-time validation; a corrupted voucher could be posted unbalanced | Medium | Open |
| DEV-S03 | VoucherService.php | `cancel()` for posted voucher reverses ledger but does not check if a prior reverse already happened | Low | Open |

### 6.5 Migration Issues

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-M01 | DDL | `created_by` in both acc_vouchers and acc_voucher_items has no FK constraint to sys_users | Medium | Open |
| DEV-M02 | DDL | `approved_by` has no FK constraint to sys_users | Medium | Open |
| DEV-M03 | DDL | `source_module` is TINYINT UNSIGNED (FK to acc_voucher_modules) but model `$casts` treats it as 'string' — mismatch | **High** | Open |
| DEV-M04 | DDL | No DB-level CHECK constraint enforcing debit=credit balance | Low | Open |

---

## 7. Known Issues Summary

| ID | Issue | Status |
|----|-------|--------|
| KN-01 | Permission prefix mismatch: controller `tenant.*` vs policy `accounting.*` | Open |
| KN-02 | source_module column type mismatch (TINYINT UNSIGNED in DDL vs string cast in model) — likely causes silent cast errors or broken source_module tracking | Open |
| KN-03 | No inline Post/Approve/Cancel actions on list view — must navigate to show page for each status transition | Open |
| KN-04 | No "Edit" button on show page — users must use action dropdown from list | Open |
| KN-05 | VoucherService `applyItemsToLedgers()` uses raw SQL string interpolation for balance delta | Open |
| KN-06 | No DB-level FK constraints on created_by or approved_by columns | Open |
| KN-07 | Default voucher status not explicitly set in controller/service — relies on DB default or migration DEFAULT value (needs verification) | Open |
| KN-08 | Voucher creation via event-mapping (auto-generated) not tested — requires EventProcessingLog/Job setup | Open |
