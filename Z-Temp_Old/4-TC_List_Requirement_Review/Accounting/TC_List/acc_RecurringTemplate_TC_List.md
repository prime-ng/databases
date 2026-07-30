# RecurringTemplate_TcList

## Module: Accounting → Transactions → Recurring Templates

---

## 1. Business Conditions

### 1.1 Database Schema — acc_recurring_templates

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | bigint unsigned | PK, auto-increment |
| BC-DB-02 | name | varchar(150) | NOT NULL |
| BC-DB-03 | voucher_type_id | tinyint unsigned | NOT NULL, FK → acc_voucher_types(id) ON DELETE RESTRICT |
| BC-DB-04 | frequency | enum('Daily','Weekly','Monthly','Quarterly','Yearly') | NOT NULL |
| BC-DB-05 | start_date | date | NOT NULL |
| BC-DB-06 | end_date | date | NULLABLE (NULL = indefinite) |
| BC-DB-07 | day_of_month | tinyint | NULLABLE (for Monthly frequency) |
| BC-DB-08 | narration | text | NULLABLE |
| BC-DB-09 | total_amount | decimal(15,2) | NOT NULL |
| BC-DB-10 | last_posted_date | date | NULLABLE |
| BC-DB-11 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-12 | created_by | int unsigned | NULLABLE, FK → sys_users (no DB FK) |
| BC-DB-13 | created_at | timestamp | Auto-managed |
| BC-DB-14 | updated_at | timestamp | Auto-managed |
| BC-DB-15 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-16 | INDEX idx_acc_rt_type | voucher_type_id | FK index |
| BC-DB-17 | ENGINE=InnoDB | — | Transaction support, FK enforcement |
| BC-DB-18 | DEFAULT CHARSET=utf8mb4 | — | Unicode support |

### 1.1b Database Schema — acc_recurring_template_lines

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-19 | id | bigint unsigned | PK, auto-increment |
| BC-DB-20 | recurring_template_id | bigint unsigned | NOT NULL, FK → acc_recurring_templates(id) ON DELETE CASCADE |
| BC-DB-21 | ledger_id | int unsigned | NOT NULL, FK → acc_ledgers(id) ON DELETE RESTRICT |
| BC-DB-22 | type | enum('debit','credit') | NOT NULL |
| BC-DB-23 | amount | decimal(15,2) | NOT NULL |
| BC-DB-24 | narration | varchar(500) | NULLABLE |
| BC-DB-25 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-26 | created_by | int unsigned | NULLABLE, FK → sys_users (no DB FK) |
| BC-DB-27 | created_at/updated_at | timestamp | Auto-managed |
| BC-DB-28 | deleted_at | timestamp | NULLABLE (soft delete) |
| BC-DB-29 | INDEX idx_acc_rtl_template | recurring_template_id | FK index |
| BC-DB-30 | INDEX idx_acc_rtl_ledger | ledger_id | FK index |

### DDL-Level Gaps

| Gap | Details |
|-----|---------|
| **Critical: `next_run_at` missing from DDL** | Model casts `next_run_at` as date, service writes to it, but column does NOT exist in `acc_recurring_templates` DDL. Will cause SQL errors on executeNow/runDueTemplates. |
| No FK on `created_by` | Both tables have created_by INT UNSIGNED with no FK to sys_users |
| `day_of_month` not used in scheduling | `computeNextRun()` adds months but never adjusts to day_of_month value |
| No DB-level CHECK for debit=credit | `total_amount` must balance Dr=Cr but no DB constraint enforces it |
| `isBalanced()` never called | Model has `isBalanced()` helper but controller never calls it — unbalanced templates can be saved |

### 1.2 Validation Rules (RecurringTemplateRequest)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | name | required, string, max:150 | — |
| BC-VAL-02 | voucher_type_id | required, exists:acc_voucher_types,id | "The Voucher Type field is required." |
| BC-VAL-03 | frequency | required, in:Daily,Weekly,Monthly,Quarterly,Yearly | — |
| BC-VAL-04 | start_date | required, date | — |
| BC-VAL-05 | end_date | nullable, date, after:start_date | — |
| BC-VAL-06 | day_of_month | nullable, integer, min:1, max:31 | — |
| BC-VAL-07 | narration | nullable, string | — |
| BC-VAL-08 | is_active | required, boolean | Default true via `prepareForValidation` |
| BC-VAL-09 | lines | required, array, min:2 | — |
| BC-VAL-10 | lines.*.ledger_id | required, exists:acc_ledgers,id | "The Ledger field is required." |
| BC-VAL-11 | lines.*.type | required, in:debit,credit | — |
| BC-VAL-12 | lines.*.amount | required, numeric, min:0.01 | "The Amount field is required." |
| BC-VAL-13 | lines.*.narration | nullable, string, max:500 | — |

### 1.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.accounting.recurring-template.viewAny` | `index()`, `show()`, `trashed()` | Without → 403 |
| BC-AUTH-02 | `tenant.accounting.recurring-template.view` | (Policy method, not used by controller) | Without → 403 |
| BC-AUTH-03 | `tenant.accounting.recurring-template.create` | `create()`, `store()`, `restore()` | Without → 403 |
| BC-AUTH-04 | `tenant.accounting.recurring-template.update` | `edit()`, `update()`, `toggleStatus()` | Without → 403 |
| BC-AUTH-05 | `tenant.accounting.recurring-template.delete` | `destroy()`, `forceDelete()` | Without → 403 |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create: total_amount auto-calculated | `total_amount = sum(items where type=debit)` from service `store()` |
| BC-BIZ-02 | Create: lines created in same transaction | Controller wraps both template + lines creation in DB::transaction |
| BC-BIZ-03 | Update: old lines deleted, new ones created | `$template->lines()->delete()` then re-created from request |
| BC-BIZ-04 | Delete: soft delete + is_active=false | `$template->is_active = false; $template->save(); $template->delete()` |
| BC-BIZ-05 | Post Now: throws if inactive | DomainException: "Cannot post an inactive recurring template." |
| BC-BIZ-06 | Post Now: throws if no lines | DomainException: "Template has no lines." |
| BC-BIZ-07 | Post Now: creates draft voucher | `VoucherService->create()` with status='draft', narration="Recurring: {name}" |
| BC-BIZ-08 | Post Now: posts voucher immediately | `VoucherService->post($voucher->fresh())` — applies to ledgers, sets status='posted' |
| BC-BIZ-09 | Post Now: updates last_posted_date | Set to today's date |
| BC-BIZ-10 | Post Now: updates next_run_at | Computed via `computeNextRun()`: Daily→+1day, Weekly→+1week, Monthly→+1month, Quarterly→+3months, Yearly→+1year |
| BC-BIZ-11 | Post Now: resolves active FY | Finds FY with highest start_date, throws if none |
| BC-BIZ-12 | Post Now: same transaction | Voucher creation + posting + template update all in one DB::transaction |
| BC-BIZ-13 | `runDueTemplates()`: finds due templates | Active templates where `next_run_at <= now()` |
| BC-BIZ-14 | `runDueTemplates()`: error isolation | One template failure doesn't stop others — error logged per template |
| BC-BIZ-15 | `runDueTemplates()`: returns count | Returns integer count of successfully processed |
| BC-BIZ-16 | Toggle status (AJAX) | POST with is_active boolean → flips field → JSON response |
| BC-BIZ-17 | Restore: sets is_active=true | After `restore()`, sets `is_active = true` |
| BC-BIZ-18 | Index redirects to transactions tab | Redirect to `route('accounting.menu.transactions', ['tab' => 'recurring-templates'])` |
| BC-BIZ-19 | Success flash — Created | "Recurring Template created successfully." |
| BC-BIZ-20 | Success flash — Updated | "Recurring Template updated successfully." |
| BC-BIZ-21 | Success flash — Trashed | "Recurring Template moved to trash." |
| BC-BIZ-22 | Success flash — Restored | "Recurring Template restored successfully." |
| BC-BIZ-23 | Success flash — Force Deleted | "Recurring Template permanently deleted." |
| BC-BIZ-24 | Success flash — Posted | "Posted. Voucher {number} created." |
| BC-BIZ-25 | Activity log — Created | On store |
| BC-BIZ-26 | Activity log — Updated | On update |
| BC-BIZ-27 | Activity log — Trashed | On destroy |
| BC-BIZ-28 | Activity log — Restored | On restore |
| BC-BIZ-29 | Activity log — Deleted | On forceDelete |
| BC-BIZ-30 | Activity log — Toggled | On toggleStatus |
| BC-BIZ-31 | Activity log — Posted | On postNow |
| BC-BIZ-32 | `computeNextRun()`: unknown frequency | Throws DomainException |

### 1.5 Model Scopes & Helpers

| BC ID | Scope/Helper | Criteria | Usage |
|-------|-------------|----------|-------|
| BC-MOD-01 | `scopeActive($query)` | `where('is_active', true)` | Filter active |
| BC-MOD-02 | `scopeDue($query)` | `where is_active=true, start_date<=now(), (end_date null or >=now())` | Find due templates |
| BC-MOD-03 | `isBalanced(): bool` | `bccomp(sum(debits), sum(credits), 2) === 0` | Check Dr=Cr |
| BC-MOD-04 | `debitLines()` scope | `lines()->where('type', 'debit')` | Only debit lines |
| BC-MOD-05 | `creditLines()` scope | `lines()->where('type', 'credit')` | Only credit lines |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete |
|-------|-----------|------------------|----------|
| BC-REF-01 | voucher_type_id | acc_voucher_types (id) | RESTRICT |
| BC-REF-02 | recurring_template_id (lines) | acc_recurring_templates (id) | CASCADE |
| BC-REF-03 | ledger_id (lines) | acc_ledgers (id) | RESTRICT |
| BC-REF-04 | created_by | sys_users (id) | SET NULL (no DB FK) |

---

## 2. Test Case List

### 2.1 Positive Test Cases

| TC ID | Description | Expected Result | V2 Test | Status |
|-------|-------------|----------------|---------|--------|
| TC-P01 | List loads via Transactions tab | Cards show name, frequency badge, voucher type, amount, status. Empty state if none. | test_index_page_loads_via_transactions_tab | ✅ |
| TC-P02 | Create with valid data (Daily) | Template created with lines, total_amount auto-calc, is_active=1. Flash. | test_create_daily_template_valid | ✅ |
| TC-P03 | Create with all frequencies | Daily, Weekly, Monthly, Quarterly, Yearly all stored/displayed correctly. | test_create_all_frequencies | ✅ |
| TC-P04 | Create with end_date | Template with end date stored; scopeDue respects end_date boundary. | test_create_with_end_date | ✅ |
| TC-P05 | Create with all optional fields | narration, day_of_month, end_date all stored. | test_create_with_optional_fields | ✅ |
| TC-P06 | Edit template — update fields | Pre-filled data updated, old lines deleted, new lines created. | test_edit_update_fields | ✅ |
| TC-P07 | Post Now — creates and posts voucher | VoucherService called, draft created, posted immediately. Flash shows number. | test_post_now_creates_voucher | ✅ |
| TC-P08 | Post Now — updates next_run_at | Daily → +1 day, Weekly → +1 week, etc. Field updated in DB. | test_post_now_updates_next_run | ✅ |
| TC-P09 | Toggle active status (AJAX) | Click toggle → is_active flips. JSON response. | test_toggle_active_status | ✅ |
| TC-P10 | Full lifecycle: delete→trash→restore→force delete | All states verified, DB transitions correct. | test_trash_restore_force_delete | ✅ |
| TC-P11 | Multiple lines (3+ debit/credit) | Template with multiple Dr/Cr lines saved correctly, balanced. | test_create_multiple_lines | ✅ |

### 2.2 Negative Test Cases

| TC ID | Description | Expected Result | V2 Test | Status |
|-------|-------------|----------------|---------|--------|
| TC-N01 | Create — required fields empty | Validation errors: name, voucher_type_id, frequency, start_date, lines. | test_validation_requires_all_fields | ✅ |
| TC-N02 | Create — items less than 2 | min:2 validation error on lines. | test_validation_min_items | ✅ |
| TC-N03 | Create — invalid frequency | Not in allowed ENUM values → validation error. | test_validation_invalid_frequency | ✅ |
| TC-N04 | Create — invalid voucher_type_id | exists validation error. | test_validation_invalid_voucher_type | ✅ |
| TC-N05 | Create — end_date before start_date | after:start_date validation error. | test_validation_end_date_before_start | ✅ |
| TC-N06 | Create — item amount zero | min:0.01 validation error. | test_validation_item_amount_zero | ✅ |
| TC-N07 | Create — invalid ledger_id | exists validation error. | test_validation_invalid_ledger | ✅ |
| TC-N08 | Create — day_of_month out of range | min:1 max:31 validation error. | test_validation_day_of_month_range | ✅ |
| TC-N09 | Post Now — inactive template | "Cannot post an inactive recurring template." | test_post_now_inactive_template | ✅ |
| TC-N10 | Post Now — template with no lines | "Template has no lines." | test_post_now_no_lines | ✅ |
| TC-N11 | Edit — change voucher_type | Voucher type can be changed on update (no restriction). | test_edit_change_voucher_type | ✅ |
| TC-N12 | Permission denied (403) | User without permissions receives 403. | test_permission_denied_returns_403 | ✅ |
| TC-N13 | Guest access redirect | Unauthenticated → /login. | test_guest_redirect_to_login | ✅ |
| TC-N14 | Invalid ID — show/edit/update/delete (404) | HTTP 404 for non-existent template. | test_crud_invalid_id_returns_404 | ✅ |
| TC-N15 | Post Now — invalid ID (404) | HTTP 404 for post-now on non-existent template. | test_post_now_invalid_id_404 | ✅ |
| TC-N16 | Empty trash page | Empty state when no trashed items. | test_empty_trash_page | ✅ |
| TC-N17 | Restore invalid ID (404) | HTTP 404. | test_restore_invalid_id_404 | ✅ |
| TC-N18 | Force delete invalid ID (404) | HTTP 404. | test_force_delete_invalid_id_404 | ✅ |

### 2.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | Status |
|-------|----------|-------------|----------------|--------|
| TC-D01 | A | FK RESTRICT — cannot delete voucher type used by template | Deleting voucher_type with templates → FK error | ⏸️ |
| TC-D02 | B | FK RESTRICT — cannot delete ledger used in template lines | Deleting ledger used in template lines → FK error | ⏸️ |
| TC-D03 | C | FK CASCADE — delete template deletes lines | Deleting template auto-removes all line templates | ⏸️ |
| TC-D04 | D | Post Now uses VoucherService → voucher created | Voucher appears in Vouchers tab with correct type, amount, items | ⏸️ |
| TC-D05 | E | Post Now posts voucher → ledger balances update | Ledger balances reflect posted voucher amounts | ⏸️ |
| TC-D06 | F | `runDueTemplates()` scheduled job | Daily cron/scheduler calls runDueTemplates, processes due templates | ⏸️ |

⏸️ = Skipped — requires cross-module setup (Voucher, Ledger, Scheduler)

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
| TC-SW09 | Post Now — SweetAlert confirm posts recurring template | Click Post Now → SweetAlert shows confirmation → Confirm → template posts voucher | test_sweet_alert_post_now_confirm | 🔴 |

---

## 3. V2 Test Method Index

| # | Method | TC / BC Map | Category |
|---|--------|-------------|----------|
| 01 | test_migration_model_indexes_and_relationships | BC-DB-01 to BC-DB-30 | Schema |
| 02 | test_model_scope_due | BC-MOD-02 | Schema |
| 03 | test_isBalanced_helper | BC-MOD-03 | Schema |
| 04 | test_index_page_loads_via_transactions_tab | TC-P01 | Positive |
| 05 | test_create_daily_template_valid | TC-P02, BC-VAL-01/08/09, BC-BIZ-01/02/19/25 | Positive |
| 06 | test_create_all_frequencies | TC-P03, BC-VAL-03 | Positive |
| 07 | test_create_with_end_date | TC-P04, BC-VAL-05 | Positive |
| 08 | test_create_with_optional_fields | TC-P05, BC-VAL-06/07 | Positive |
| 09 | test_edit_update_fields | TC-P06, BC-BIZ-03/20/26 | Positive |
| 10 | test_post_now_creates_voucher | TC-P07, BC-BIZ-05/06/07/08/12/24/31 | Positive |
| 11 | test_post_now_updates_next_run | TC-P08, BC-BIZ-09/10/32 | Positive |
| 12 | test_toggle_active_status | TC-P09, BC-BIZ-16/30 | Positive |
| 13 | test_trash_restore_force_delete | TC-P10, BC-BIZ-04/17/21/22/23/27/28/29 | Positive |
| 14 | test_create_multiple_lines | TC-P11 | Positive |
| 15 | test_validation_requires_all_fields | TC-N01, BC-VAL-01/02/03/04/09 | Negative |
| 16 | test_validation_min_items | TC-N02, BC-VAL-09 | Negative |
| 17 | test_validation_invalid_frequency | TC-N03, BC-VAL-03 | Negative |
| 18 | test_validation_invalid_voucher_type | TC-N04, BC-VAL-02 | Negative |
| 19 | test_validation_end_date_before_start | TC-N05, BC-VAL-05 | Negative |
| 20 | test_validation_item_amount_zero | TC-N06, BC-VAL-12 | Negative |
| 21 | test_validation_invalid_ledger | TC-N07, BC-VAL-10 | Negative |
| 22 | test_validation_day_of_month_range | TC-N08, BC-VAL-06 | Negative |
| 23 | test_post_now_inactive_template | TC-N09, BC-BIZ-05 | Negative |
| 24 | test_post_now_no_lines | TC-N10, BC-BIZ-06 | Negative |
| 25 | test_edit_change_voucher_type | TC-N11 | Negative |
| 26 | test_permission_denied_returns_403 | TC-N12, BC-AUTH-01 to BC-AUTH-05 | Negative |
| 27 | test_guest_redirect_to_login | TC-N13 | Negative |
| 28 | test_crud_invalid_id_returns_404 | TC-N14 | Negative |
| 29 | test_post_now_invalid_id_404 | TC-N15 | Negative |
| 30 | test_empty_trash_page | TC-N16 | Negative |
| 31 | test_restore_invalid_id_404 | TC-N17 | Negative |
| 32 | test_force_delete_invalid_id_404 | TC-N18 | Negative |
| 33 | test_dependency_voucher_ledger_scheduler | TC-D01 to TC-D06 | Dependency |

---

## 4. Coverage Summary

| Category | Total TCs | Full | Partial | Gap | Coverage % |
|----------|-----------|------|---------|-----|------------|
| Positive | 11 | 11 | 0 | 0 | **100%** |
| Negative | 18 | 18 | 0 | 0 | **100%** |
| SweetAlert | 9 | 0 | 0 | 9 | **0%** |
| Dependency | 6 | 0 | 0 | 6 | **0%** |
| **Total** | **44** | **29** | **0** | **15** | **66%** |

### BC Coverage

| Category | Total BCs | Covered | Gap | Coverage % |
|----------|-----------|---------|-----|------------|
| Database (BC-DB) | 30 | 30 | 0 | **100%** |
| Validation (BC-VAL) | 13 | 13 | 0 | **100%** |
| Authorization (BC-AUTH) | 5 | 5 | 0 | **100%** |
| Business Logic (BC-BIZ) | 32 | 31 | 1 | **97%** |
| Model Scopes (BC-MOD) | 5 | 5 | 0 | **100%** |
| Referential (BC-REF) | 4 | 1 | 3 | **25%** |
| **Total** | **89** | **85** | **4** | **96%** |

---

## 5. Route Reference

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | /accounting/transactions?tab=recurring-templates | accounting.menu.transactions | viewAny |
| GET | /accounting/recurring-template | accounting.recurring-template.index | viewAny |
| GET | /accounting/recurring-template/create | accounting.recurring-template.create | create |
| POST | /accounting/recurring-template | accounting.recurring-template.store | create |
| GET | /accounting/recurring-template/{recurring_template} | accounting.recurring-template.show | viewAny |
| GET | /accounting/recurring-template/{recurring_template}/edit | accounting.recurring-template.edit | update |
| PUT/PATCH | /accounting/recurring-template/{recurring_template} | accounting.recurring-template.update | update |
| DELETE | /accounting/recurring-template/{recurring_template} | accounting.recurring-template.destroy | delete |
| POST | /accounting/recurring-template/{recurring_template}/post-now | accounting.recurring-template.postNow | post |
| POST | /accounting/recurring-template/{recurring_template}/toggle-status | accounting.recurring-template.toggleStatus | update |
| GET | /accounting/recurring-template/trash/view | accounting.recurring-template.trashed | viewAny |
| GET | /accounting/recurring-template/{id}/restore | accounting.recurring-template.restore | create |
| DELETE | /accounting/recurring-template/{id}/force-delete | accounting.recurring-template.forceDelete | delete |

---

## 6. Development Issues Found

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-01 | DDL | **`next_run_at` column missing** from `acc_recurring_templates` DDL — model casts it as date, service writes to it, column doesn't exist. Will cause SQL errors. | **Critical** | Open |
| DEV-02 | DDL | `day_of_month` field exists but `computeNextRun()` never adjusts to it — only adds months without setting day. Feature incomplete. | Medium | Open |
| DEV-03 | trash.blade.php | View references `$template->next_run_date` but the model uses `next_run_at` cast. Attribute doesn't exist — view error. | **High** | Open |
| DEV-04 | _recurring-templates.blade.php | Badge `match()` compares lowercase `'daily'` etc. but ENUM stores `'Daily'` (PascalCase). Badge colors always fall to default. | Medium | Open |
| DEV-05 | RecurringTemplatePolicy.php | All permissions lack `tenant.` prefix while controller gates use `tenant.` prefix. Policy bypassed if no gate bridging. | **High** | Open |
| DEV-06 | DDL | `created_by` in both tables has no FK constraint to `sys_users` | Medium | Open |
| DEV-07 | Controller | `isBalanced()` model helper never called — unbalanced templates can be saved. | Low | Open |

---

## 7. Known Issues Summary

| ID | Issue | Status |
|----|-------|--------|
| KN-01 | `next_run_at` column missing from DDL — **critical blocker** for scheduled execution | Open |
| KN-02 | `day_of_month` not implemented in computeNextRun() — Monthly frequency always posts on addMonth() date | Open |
| KN-03 | Trash view references non-existent `next_run_date` attribute — causes view error | Open |
| KN-04 | Frequency badge colors broken — match() case mismatch (lowercase vs PascalCase) | Open |
| KN-05 | Permission prefix mismatch: controller `tenant.*` vs policy `accounting.*` | Open |
| KN-06 | No DB-level FK on `created_by` | Open |
| KN-07 | `isBalanced()` never validated in controller — unbalanced templates saved silently | Open |
