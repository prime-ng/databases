# fee_FeeFineRules_TcList

## Module: StudentFee → Fine Management → Fee Fine Rules

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | StudentFee |
| Tab Group | Fine Management |
| Feature | Fee Fine Rules |
| URL(s) | `/student-fee/fine-management` (tab), `/student-fee/fee-fine-rule` (index), `/student-fee/fee-fine-rule/create` (create), `/student-fee/fee-fine-rule` (store), `/student-fee/fee-fine-rule/{id}` (show), `/student-fee/fee-fine-rule/{id}/edit` (edit), `/student-fee/fee-fine-rule/{id}` (update), `/student-fee/fee-fine-rule/{id}` (destroy), `/student-fee/fee-fine-rule/trash/view` (trashed), `/student-fee/fee-fine-rule/{id}/restore` (restore), `/student-fee/fee-fine-rule/{id}/force-delete` (forceDelete), `/student-fee/fee-fine-rule/{fee_fine_rule}/toggle-status` (toggleStatus) |
| Controller | `Modules\StudentFee\Http\Controllers\FeeFineRuleController` |
| Model(s) | `Modules\StudentFee\Models\FeeFineRule` (table: `fee_fine_rules`) |
| Validation (Create) | `Modules\StudentFee\Http\Requests\StoreFeeFineRuleRequest` |
| Validation (Update) | `Modules\StudentFee\Http\Requests\UpdateFeeFineRuleRequest` |
| Permissions | `tenant.fee-fine-rule.view`, `tenant.fee-fine-rule.create`, `tenant.fee-fine-rule.update`, `tenant.fee-fine-rule.delete`, `tenant.fee-fine-rule.restore`, `tenant.fee-fine-rule.forceDelete`, `tenant.fee-fine-rule.status` |
| Soft Deletes | Yes (`SoftDeletes` trait; `destroy()` sets `is_active=false` before soft-delete; `restore()` sets `is_active=true`) |
| Activity Log | Events: `Created`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |

---

## 2. Pre-conditions

- Required permissions: `tenant.fee-fine-rule.{view,create,update,delete,restore,forceDelete,status}`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized
- For applicable_on tests: At least one active Fee Structure, Installment, or Head record exists
- Dusk environment variables: DUSK_TENANT_URL, DUSK_ADMIN_EMAIL, DUSK_ADMIN_PASSWORD

---

## 3. Default Data Load

When the page loads via `StudentFeeManagementController@fineManagement()` (GET `/student-fee/fine-management`), the following data is fetched:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Fine Rules | `FeeFineRule::paginate(10)` | All rules | None | 10/page |
| Fine Transactions | `FeeFineTransaction::with(['student.user','invoice','fineRule'])->latest('fine_date')->paginate(15)` | Latest first | search( student name), waived status | 15/page |

---

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Rule name uniqueness**: No unique constraint; names can repeat
- **Pre-test cleanup**: Delete created fine rules by ID before/after tests
- **Dropdown option sets**: `applicableOptions` = ['Fee Structure', 'Installment', 'Head']; `fineTypes` = ['Percentage', 'Fixed', 'Percentage+Capped']; `expiryActions` = ['None', 'Mark Defaulter', 'Remove Name', 'Suspend']

---

## 5. Business Conditions

### 5.1 Database Schema — `fee_fine_rules`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | rule_name | VARCHAR(100) | NOT NULL |
| BC-DB-03 | applicable_on | ENUM('Fee Structure','Installment','Head') | NOT NULL, DEFAULT 'Installment' |
| BC-DB-04 | applicable_id | INT UNSIGNED | NOT NULL, ID based on applicable_on |
| BC-DB-05 | fine_type | ENUM('Percentage','Fixed','Percentage+Capped') | NOT NULL |
| BC-DB-06 | fine_value | DECIMAL(10,2) | NOT NULL |
| BC-DB-07 | fine_calculation_mode | ENUM('PerDay','FlatPerTier') | NOT NULL, DEFAULT 'PerDay' |
| BC-DB-08 | max_fine_amount | DECIMAL(10,2) | NULLABLE |
| BC-DB-09 | grace_period_days | INT | NOT NULL, DEFAULT 0 |
| BC-DB-10 | recurring | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-11 | recurring_interval_days | INT | NULLABLE |
| BC-DB-12 | max_fine_installments | INT | NULLABLE |
| BC-DB-13 | applicable_from_day | INT | NOT NULL, DEFAULT 1 |
| BC-DB-14 | applicable_to_day | INT | NULLABLE |
| BC-DB-15 | action_on_expiry | ENUM('None','Mark Defaulter','Remove Name','Suspend') | NULLABLE |
| BC-DB-16 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-17 | created_by | INT UNSIGNED | Set in controller |
| BC-DB-18 | updated_by | INT UNSIGNED | Set in controller |
| BC-DB-19 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-20 | updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-21 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `StoreFeeFineRuleRequest`

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | rule_name | required, string, max:100 | — |
| BC-VAL-02 | applicable_on | required, in:Fee Structure,Installment,Head | — |
| BC-VAL-03 | applicable_id | required, integer, min:1 | — |
| BC-VAL-04 | fine_type | required, in:Percentage,Fixed,Percentage+Capped | — |
| BC-VAL-05 | fine_value | required, numeric, min:0 | — |
| BC-VAL-06 | max_fine_amount | nullable, numeric, min:0 | — |
| BC-VAL-07 | grace_period_days | nullable, integer, min:0 | — |
| BC-VAL-08 | recurring | nullable, boolean | — |
| BC-VAL-09 | recurring_interval_days | nullable, integer, min:1 | — |
| BC-VAL-10 | max_fine_installments | nullable, integer, min:1 | — |
| BC-VAL-11 | applicable_from_day | required, integer, min:1 | — |
| BC-VAL-12 | applicable_to_day | nullable, integer, gte:applicable_from_day | — |
| BC-VAL-13 | action_on_expiry | nullable, in:None,Mark Defaulter,Remove Name,Suspend | — |
| BC-VAL-14 | is_active | nullable, boolean | — |

### 5.3 Conditional Validation (Controller After-Validation)

| BC ID | Condition | Rule | Error Message |
|-------|-----------|------|---------------|
| BC-VAL-C01 | fine_type = Percentage+Capped AND max_fine_amount missing | Required | "Max fine amount is required for capped percentage fine." |
| BC-VAL-C02 | recurring enabled AND recurring_interval_days missing | Required | "Recurring interval days required when recurring fine is enabled." |

### 5.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.fee-fine-rule.view | index(), show() | Without → 403 |
| BC-AUTH-02 | tenant.fee-fine-rule.create | create(), store() | Without → 403 |
| BC-AUTH-03 | tenant.fee-fine-rule.update | edit(), update() | Without → 403 |
| BC-AUTH-04 | tenant.fee-fine-rule.delete | destroy() | Without → 403 |
| BC-AUTH-05 | tenant.fee-fine-rule.restore | trashedFeeFineRules(), restore() | Without → 403 |
| BC-AUTH-06 | tenant.fee-fine-rule.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-07 | tenant.fee-fine-rule.status | toggleStatus() | Without → 403 |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | fine_type != Percentage+Capped | max_fine_amount forced to null in store/update |
| BC-BIZ-02 | recurring not enabled | recurring_interval_days and max_fine_installments forced to null |
| BC-BIZ-03 | Create with Percentage+Capped + max_fine_amount | max_fine_amount stored as provided |
| BC-BIZ-04 | Create with recurring enabled + interval_days | recurring=true, recurring_interval_days stored |
| BC-BIZ-05 | Soft delete | is_active set to false before delete(); record moved to trash |
| BC-BIZ-06 | Restore | deleted_at nullified; is_active set to true |
| BC-BIZ-07 | Force delete | Record permanently removed from DB |
| BC-BIZ-08 | Toggle status | is_active flipped; JSON response with success flag |
| BC-BIZ-09 | Calculate fine (Percentage) | fine = (base_amount × fine_value) / 100 |
| BC-BIZ-10 | Calculate fine (Fixed) | fine = fine_value |
| BC-BIZ-11 | Calculate fine (Percentage+Capped) | fine = min(percentage_calc, max_fine_amount) |
| BC-BIZ-12 | Calculate fine (appliesForDays) | Returns true if overdueDays within [applicable_from_day, applicable_to_day] |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | applicable_id | (polymorphic — Fee Structure/Installment/Head tables) | No FK constraint |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Fine Rules Page Loads Via Fine Management Tab | Page loads with rules grid (10/page) and transactions grid (15/page) | — | — | ⬜ |
| TC-P02 | Create Percentage Fine Rule | Rule created with fine_type=Percentage, fine_value=2.00, max_fine_amount=null | — | — | ⬜ |
| TC-P03 | Create Fixed Fine Rule | Rule created with fine_type=Fixed, fine_value=500.00 | — | — | ⬜ |
| TC-P04 | Create Percentage+Capped Fine Rule | Rule created with fine_type=Percentage+Capped, fine_value=5.00, max_fine_amount=2000.00 | — | — | ⬜ |
| TC-P05 | Create Recurring Fine Rule | Rule created with recurring=true, recurring_interval_days=7, max_fine_installments=4 | — | — | ⬜ |
| TC-P06 | Create Fine Rule With Expiry Action "Remove Name" | Rule created with action_on_expiry="Remove Name" | — | — | ⬜ |
| TC-P07 | Create Fine Rule With Grace Period | Rule created with grace_period_days=5 | — | — | ⬜ |
| TC-P08 | Create Fine Rule With Day Range | Rule created with applicable_from_day=1, applicable_to_day=30 | — | — | ⬜ |
| TC-P09 | Create Fine Rule With FlatPerTier Mode | Rule created with fine_calculation_mode=FlatPerTier | — | — | ⬜ |
| TC-P10 | Edit Fine Rule Name and Value | Rule updated with new rule_name and fine_value | — | — | ⬜ |
| TC-P11 | Edit Fine Rule: Remove Capped → max_fine_amount Cleared | Changing from Percentage+Capped to Fixed clears max_fine_amount | — | — | ⬜ |
| TC-P12 | Edit Fine Rule: Disable Recurring → Interval Cleared | Disabling recurring clears recurring_interval_days and max_fine_installments | — | — | ⬜ |
| TC-P13 | Show Fine Rule Details | Rule details page shows all fields correctly | — | — | ⬜ |
| TC-P14 | Soft Delete Fine Rule | Rule deactivated (is_active=false) and moved to trash | — | — | ⬜ |
| TC-P15 | View Trashed Fine Rules | Trash page lists only soft-deleted rules | — | — | ⬜ |
| TC-P16 | Restore Fine Rule From Trash | Rule restored with is_active=true | — | — | ⬜ |
| TC-P17 | Force Delete Fine Rule | Rule permanently removed from DB | — | — | ⬜ |
| TC-P18 | Toggle Fine Rule Status Active → Inactive | is_active flips; JSON response `{success: true, is_active: false}` | — | — | ⬜ |
| TC-P19 | Toggle Fine Rule Status Inactive → Active | is_active flips to true; JSON response success | — | — | ⬜ |
| TC-P20 | Full Lifecycle: Create → Edit → Toggle → Delete → Restore → Force Delete | All transitions succeed; activity logged at each step | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `rule_name` | Validation error: "The rule name field is required." | — | — | ⬜ |
| TC-N02 | Required — Missing `applicable_on` | Validation error: "The applicable on field is required." | — | — | ⬜ |
| TC-N03 | Required — Missing `fine_type` | Validation error: "The fine type field is required." | — | — | ⬜ |
| TC-N04 | Required — Missing `fine_value` | Validation error: "The fine value field is required." | — | — | ⬜ |
| TC-N05 | Required — Missing `applicable_id` | Validation error: "The applicable id field is required." | — | — | ⬜ |
| TC-N06 | Required — Missing `applicable_from_day` | Validation error: "The applicable from day field is required." | — | — | ⬜ |
| TC-N07 | Invalid — `fine_type` not in allowed values | Validation error: "The selected fine type is invalid." | — | — | ⬜ |
| TC-N08 | Invalid — `applicable_on` not in allowed values | Validation error: "The selected applicable on is invalid." | — | — | ⬜ |
| TC-N09 | Invalid — `action_on_expiry` not in allowed values | Validation error: "The selected action on expiry is invalid." | — | — | ⬜ |
| TC-N10 | Conditional — Percentage+Capped Without max_fine_amount | Validation error: "Max fine amount is required for capped percentage fine." | — | — | ⬜ |
| TC-N11 | Conditional — Recurring Enabled Without Interval | Validation error: "Recurring interval days required when recurring fine is enabled." | — | — | ⬜ |
| TC-N12 | Invalid — `applicable_to_day` less than `applicable_from_day` | Validation error on gte rule | — | — | ⬜ |
| TC-N13 | Boundary — `rule_name` > 100 characters | Validation fails on rule_name.max | — | — | ⬜ |
| TC-N14 | Boundary — `fine_value` negative | Validation fails on fine_value.min (must be >= 0) | — | — | ⬜ |
| TC-N15 | Permission 403 — No Fee Fine Rule Permissions | 403 Forbidden on all CRUD endpoints | — | — | ⬜ |
| TC-N16 | Guest Access Redirect | Redirected to /login for all fine rule routes | — | — | ⬜ |
| TC-N17 | XSS Injection In rule_name | Stored as literal string; Blade escapes output | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Soft Delete → is_active set false Before delete | `is_active` = 0 before `deleted_at` set | — | — | ⬜ |
| TC-D02 | B | Restore → is_active set true | `is_active` = 1 after restore | — | — | ⬜ |
| TC-D03 | C | Force Delete → Record Permanently Removed | Record gone from DB; not in trash | — | — | ⬜ |
| TC-D04 | D | Create → created_by and updated_by Set | Both fields set to auth()->id() | — | — | ⬜ |
| TC-D05 | E | Update → updated_by Updated | updated_by set to current auth()->id() | — | — | ⬜ |
| TC-D06 | F | Toggle Status → JSON Response Format | `{success: true/false, is_active: bool, message: string}` | — | — | ⬜ |
| TC-D07 | G | Activity Logged After Create | `activityLog()` called with event 'Created' and rule details | — | — | ⬜ |
| TC-D08 | H | Activity Logged After Update | `activityLog()` called with event 'Updated' | — | — | ⬜ |
| TC-D09 | I | Activity Logged After Delete (Trashed) | `activityLog()` called with event 'Trashed' | — | — | ⬜ |
| TC-D10 | J | Activity Logged After Restore | `activityLog()` called with event 'Restored' | — | — | ⬜ |
| TC-D11 | K | Activity Logged After Force Delete | `activityLog()` called with event 'Deleted' | — | — | ⬜ |
| TC-D12 | L | Activity Logged After Toggle | `activityLog()` called with event 'Toggled' | — | — | ⬜ |
| TC-D13 | M | Calculate Fine — Percentage Mode | `calculateFine(10000)` with fine_type=Percentage, fine_value=2 → 200.00 | — | — | ⬜ |
| TC-D14 | N | Calculate Fine — Fixed Mode | `calculateFine(10000)` with fine_type=Fixed, fine_value=500 → 500.00 | — | — | ⬜ |
| TC-D15 | O | Calculate Fine — Percentage+Capped | `calculateFine(100000)` with fine_type=Percentage+Capped, fine_value=5, max=2000 → 2000.00 | — | — | ⬜ |
| TC-D16 | P | appliesForDays — Within Range | overdueDays=15, applicable_from_day=1, applicable_to_day=30 → true | — | — | ⬜ |
| TC-D17 | Q | appliesForDays — Outside Range | overdueDays=35, applicable_from_day=1, applicable_to_day=30 → false | — | — | ⬜ |
| TC-D18 | R | Force Delete of Non-Existent ID | 404 ModelNotFoundException | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can checks for create, edit, delete, status, restore, forceDelete | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — DB Transactions in store/update | store() and update() do NOT use DB transactions (single create/update call) | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — activityLog Called After All CRUD Events | Create, update, destroy, restore, forceDelete, toggleStatus all have activityLog() call | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — Gate::authorize() Before Each Action | All controller methods call Gate::authorize() before business logic | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P02: Create Percentage Fine Rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Student Fee → Fine Management | Tab loads with fine rules grid |
| 2 | Click "Add Fine Rule" button | Create form opens with dropdown options |
| 3 | Enter rule_name: "Test Percentage Fine" | Field filled |
| 4 | Select applicable_on: "Installment" | Dropdown selected |
| 5 | Enter applicable_id: 1 | Field filled |
| 6 | Select fine_type: "Percentage" | Dropdown selected |
| 7 | Enter fine_value: 2.00 | Field filled |
| 8 | Select fine_calculation_mode: "PerDay" | Dropdown selected |
| 9 | Enter applicable_from_day: 1 | Field filled |
| 10 | Leave max_fine_amount empty | Auto-set to null (not Percentage+Capped) |
| 11 | Set is_active checkbox | Checked |
| 12 | Click "Save" | POST to store() route |
| 13 | Check response | Success flash: "Fee Fine Rule created successfully." |
| 14 | DB check: `SELECT * FROM fee_fine_rules WHERE rule_name='Test Percentage Fine'` | Record exists; fine_type='Percentage'; fine_value=2.00; max_fine_amount=NULL |

### TC-N10: Percentage+Capped Without max_fine_amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Fill all required fields | Fields set |
| 3 | Select fine_type: "Percentage+Capped" | Dropdown selected |
| 4 | Leave max_fine_amount empty | Empty |
| 5 | Click "Save" | Validation fails |
| 6 | Check error message | "Max fine amount is required for capped percentage fine." |

### TC-P14: Soft Delete Fine Rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a fine rule | Rule exists with ID=X |
| 2 | Click "Delete" on that rule | DELETE request to destroy() |
| 3 | Check is_active before delete | is_active = false |
| 4 | Check deleted_at | Timestamp set |
| 5 | Check flash message | flash('trashed.fee_fine_rule') |
| 6 | Verify rule not in main list | Rule hidden from active list |
| 7 | Navigate to trash view | Rule visible in trash |

---

## 8. Known Issues

- `created_by` and `updated_by` are set in controller but not in `$fillable` of model (they are fillable via merge)
- `edit()` and `create()` methods pass `applicableOptions`, `fineTypes`, `expiryActions` as arrays — no dynamic loading from DB
- `toggleStatus()` uses `ToggleStatusRequest` but the request itself is generic

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/student-fee/fine-management` | `student-fee.fineManagement` | `StudentFeeManagementController@fineManagement` |
| GET | `/student-fee/fee-fine-rule` | `student-fee.fee-fine-rule.index` | `index` |
| GET | `/student-fee/fee-fine-rule/create` | `student-fee.fee-fine-rule.create` | `create` |
| POST | `/student-fee/fee-fine-rule` | `student-fee.fee-fine-rule.store` | `store` |
| GET | `/student-fee/fee-fine-rule/{id}` | `student-fee.fee-fine-rule.show` | `show` |
| GET | `/student-fee/fee-fine-rule/{id}/edit` | `student-fee.fee-fine-rule.edit` | `edit` |
| PUT/PATCH | `/student-fee/fee-fine-rule/{id}` | `student-fee.fee-fine-rule.update` | `update` |
| DELETE | `/student-fee/fee-fine-rule/{id}` | `student-fee.fee-fine-rule.destroy` | `destroy` |
| GET | `/student-fee/fee-fine-rule/trash/view` | `student-fee.fee-fine-rule.trashed` | `trashedFeeFineRules` |
| GET | `/student-fee/fee-fine-rule/{id}/restore` | `student-fee.fee-fine-rule.restore` | `restore` |
| DELETE | `/student-fee/fee-fine-rule/{id}/force-delete` | `student-fee.fee-fine-rule.forceDelete` | `forceDelete` |
| POST | `/student-fee/fee-fine-rule/{fee_fine_rule}/toggle-status` | `student-fee.fee-fine-rule.toggleStatus` | `toggleStatus` |

## 10. Execution Status

| Total TC | Passed | Failed | Blocked | Skipped | Execution Date |
|----------|--------|--------|---------|---------|----------------|
| 0 | 0 | 0 | 0 | 0 | — |
