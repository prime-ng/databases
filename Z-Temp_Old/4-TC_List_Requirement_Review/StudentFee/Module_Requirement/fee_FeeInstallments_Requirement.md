# Feature Requirement: Fee Installments

## 1. Module Name
**StudentFee** (Prefix: `fee_`)

## 2. Feature Name
**Fee Installments** — Scheduled payment breakdown for fee structures

## 3. Tab / Submodule
**Configuration** (Route: `GET /student-fee/configuration`, Name: `student-fee.configuration`, Tab: `fee-installment`)

## 4. Description
Divides the total fee amount into scheduled payments (installments) per fee structure. Typically 4 quarterly installments at 25% each, but configurable to any number with any percentage split. Each installment has a due date, grace period, and overdue detection.

## 5. Primary Model
**`Modules\StudentFee\Models\FeeInstallment`** (Table: `fee_installments`)

## 6. Controller
**`Modules\StudentFee\Http\Controllers\FeeInstallmentController`**

### Methods Implemented:
| Method | Route | Permission |
|--------|-------|------------|
| `index()` | `GET /fee-installment` | Redirects to configuration tab |
| `create()` | `GET /fee-installment/create` | `tenant.fee-installment.create` |
| `store()` | `POST /fee-installment` | `tenant.fee-installment.create` |
| `show($id)` | `GET /fee-installment/{id}` | `tenant.fee-installment.view` |
| `edit($id)` | `GET /fee-installment/{id}/edit` | `tenant.fee-installment.update` |
| `update()` | `PUT /fee-installment/{id}` | `tenant.fee-installment.update` |
| `destroy($id)` | `DELETE /fee-installment/{id}` | `tenant.fee-installment.delete` |
| `trashedFeeInstallments()` | `GET /fee-installment/trash/view` | `tenant.fee-installment.restore` |
| `restore($id)` | `GET /fee-installment/{id}/restore` | `tenant.fee-installment.restore` |
| `forceDelete($id)` | `DELETE /fee-installment/{id}/force-delete` | `tenant.fee-installment.forceDelete` |
| `toggleStatus()` | `POST /fee-installment/{fee_installment}/toggle-status` | `tenant.fee-installment.status` |

## 7. Form Requests

### StoreFeeInstallmentRequest
- Authorizes via `tenant.fee-installment` CRUD permission
- Rules:
  - `fee_structure_id`: required, integer, exists:fee_structure_master,id
  - `installment_no`: required, integer, min:1, unique within fee_structure_id
  - `installment_name`: required, string, max:100
  - `due_date`: required, date
  - `percentage_due`: required, numeric, min:0.01, max:100
  - `amount_due`: nullable, numeric, min:0
  - `grace_days`: nullable, integer, min:0, max:365
  - `is_active`: nullable, boolean

### UpdateFeeInstallmentRequest
- Same rules as Store, with `installment_no` unique ignored on self within same fee_structure_id
- Authorizes via `tenant.fee-installment` CRUD permission

### ToggleStatusRequest
- Rule: `is_active` required, boolean
- Authorizes via Gate::any including `tenant.fee-installment.status`

## 8. Database Table Structure

**Table: `fee_installments`**

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INT UNSIGNED | AUTO_INCREMENT PRIMARY KEY |
| `fee_structure_id` | INT UNSIGNED | NOT NULL, FK → fee_structure_master (CASCADE) |
| `installment_no` | INT | NOT NULL |
| `installment_name` | VARCHAR(100) | NOT NULL |
| `due_date` | DATE | NOT NULL |
| `percentage_due` | DECIMAL(5,2) | NOT NULL |
| `amount_due` | DECIMAL(10,2) | NULL, calculated amount |
| `grace_days` | INT | NOT NULL, DEFAULT 0 |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE |

**Indexes:**
- UNIQUE `uq_fee_installment_structure_no` (`fee_structure_id`, `installment_no`)
- FK `fk_fi_structure` → fee_structure_master(id) ON DELETE CASCADE

### Model Attributes
- **$fillable**: fee_structure_id, installment_no, installment_name, due_date, percentage_due, amount_due, grace_days, is_active
- **$casts**: fee_structure_id(integer), installment_no(integer), due_date(date), percentage_due(decimal:2), amount_due(decimal:2), grace_days(integer), is_active(boolean)
- **No SoftDeletes** trait used

### Model Scopes & Helpers
- `scopeActive(Builder)`: where is_active = true
- `scopeForStructure(Builder, int)`: where fee_structure_id
- `calculateAmount()`: returns amount_due if set, else computes from structure total
- `getLastDateWithGrace()`: returns due_date + grace_days (null if no due_date)
- `isOverdue()`: returns true if current date > due_date + grace_days

## 9. Business Rules / Logic

### Percentage Validation
- Sum of `percentage_due` across all installments for a structure must NOT exceed 100%
- Checked in controller before create/update
- On create: `existingPercentage + newPercentage <= 100`
- On update: `existingPercentage (excluding self) + newPercentage <= 100`
- Error: `'Total installment percentage cannot exceed 100%. Currently configured: ' . $existingPercentage . '%'`
- Error on update: `'Total installment percentage cannot exceed 100%. Already configured: ' . $existingPercentage . '%'`

### Amount Computation
- `amount_due` computed as: `round((totalAmount * percentage_due) / 100, 2)` where totalAmount = sum of structure details amounts
- If `amount_due` is manually provided in request, that value is used directly

### Due Date with Grace
- Actual last payment date = due_date + grace_days
- `getLastDateWithGrace()` returns the grace-extended date
- `isOverdue()` returns true if current date > last date with grace

### Installment Uniqueness
- `installment_no` unique per `fee_structure_id` (enforced by DB unique index and FormRequest)

## 10. Controller Logic Details

### index()
- Redirects to `route('student-fee.configuration', ['tab' => 'fee-installment'])`

### create()
- Authorization: `tenant.fee-installment.create`
- Loads active fee structures ordered by name
- Returns create view

### store(StoreFeeInstallmentRequest)
- Authorization: `tenant.fee-installment.create`
- Uses `DB::beginTransaction/commit/rollback` (no `DB::transaction` closure)
- Loads structure with details
- Checks percentage total ≤ 100% — if exceeded, returns back with error on `percentage_due` field
- Computes amount_due from totalAmount * percentage (or uses manually provided amount_due)
- Creates FeeInstallment record
- Activity logged
- Flash: `flash('created.fee_installment')`
- On exception: rollback, report, return back with `'Something went wrong.'`

### show($id)
- Authorization: `tenant.fee-installment.view`
- Loads feeStructure relationship
- Returns show view

### edit($id)
- Authorization: `tenant.fee-installment.update`
- Loads active fee structures
- Returns edit view

### update(UpdateFeeInstallmentRequest, $id)
- Authorization: `tenant.fee-installment.update`
- Uses `DB::beginTransaction/commit/rollback`
- Checks percentage total excluding current installment — if exceeded, returns back with error
- Computes amount_due same as store
- Updates FeeInstallment
- Flash: `flash('updated.fee_installment')`

### destroy($id)
- Authorization: `tenant.fee-installment.delete`
- Deactivates then soft deletes
- Flash: `flash('trashed.fee_installment')`

### toggleStatus(ToggleStatusRequest, FeeInstallment)
- Authorization: `tenant.fee-installment.status`
- Toggles is_active (negates current value: `! $feeInstallment->is_active`)
- Returns JSON with `flash('status_updated.fee_installment')` or `flash('status_switch_failed.fee_installment')`

## 11. Edge Cases & Validations
- Percentage total cannot exceed 100% (no minimum requirement for totaling exactly 100%)
- `percentage_due` min:0.01 (must be positive, cannot be 0)
- grace_days limited to max 365
- `installment_no` min:1, unique per structure
- Manual `amount_due` override bypasses automatic calculation
- DB::beginTransaction/commit/rollback used instead of closure — must ensure rollback on all exceptions

## 12. Dependencies / Relations
- **fee_structure_master**: fee_structure_id FK (CASCADE on delete)
- **fee_invoices**: installment_id FK (SET NULL)
- **fee_structure_details**: used for totalAmount calculation

## 13. API / Route Details

### Web Routes (resource + additional):
| Method | URI | Name |
|--------|-----|------|
| GET | `/fee-installment` | `fee-installment.index` |
| GET | `/fee-installment/create` | `fee-installment.create` |
| POST | `/fee-installment` | `fee-installment.store` |
| GET | `/fee-installment/{fee_installment}` | `fee-installment.show` |
| GET | `/fee-installment/{fee_installment}/edit` | `fee-installment.edit` |
| PUT | `/fee-installment/{fee_installment}` | `fee-installment.update` |
| DELETE | `/fee-installment/{fee_installment}` | `fee-installment.destroy` |
| GET | `/fee-installment/trash/view` | `fee-installment.trashed` |
| GET | `/fee-installment/{id}/restore` | `fee-installment.restore` |
| DELETE | `/fee-installment/{id}/force-delete` | `fee-installment.forceDelete` |
| POST | `/fee-installment/{fee_installment}/toggle-status` | `fee-installment.toggleStatus` |

## 14. Permissions

| Operation | Permission Key |
|-----------|---------------|
| View installments list | `tenant.fee-installment.viewAny` |
| View installment details | `tenant.fee-installment.view` |
| Create installment | `tenant.fee-installment.create` |
| Update installment | `tenant.fee-installment.update` |
| Delete installment | `tenant.fee-installment.delete` |
| Restore installment | `tenant.fee-installment.restore` |
| Force delete installment | `tenant.fee-installment.forceDelete` |
| Toggle status | `tenant.fee-installment.status` |

## 15. Flash Messages
- `flash('created.fee_installment')` — on store
- `flash('updated.fee_installment')` — on update
- `flash('trashed.fee_installment')` — on destroy
- `flash('restored.fee_installment')` — on restore
- `flash('force_deleted.fee_installment')` — on forceDelete
- `flash('status_updated.fee_installment')` — on toggleStatus success
- `flash('status_switch_failed.fee_installment')` — on toggleStatus failure
- `'Something went wrong.'` — on exception in store/update
- `'Total installment percentage cannot exceed 100%. Currently configured: ' . $existingPercentage . '%'` — on store validation
- `'Total installment percentage cannot exceed 100%. Already configured: ' . $existingPercentage . '%'` — on update validation

## 16. Known Issues / Gotchas
- FeeInstallment model does NOT use the SoftDeletes trait — but the controller calls `delete()` and `restore()`. If the model lacks SoftDeletes, `delete()` performs hard delete and `restore()` will fail.
- The model file does NOT import or use SoftDeletes (line 11-13 only uses HasFactory).
- togglStatus negates current value (`!$feeInstallment->is_active`) instead of using request input (unlike other controllers)
- DB::beginTransaction/commit/rollback pattern used instead of `DB::transaction()` closure — explicit rollback on catch
- destroy/trashed/restore/forceDelete routes reference the model but destruct uses `$id` parameter instead of implicit binding
