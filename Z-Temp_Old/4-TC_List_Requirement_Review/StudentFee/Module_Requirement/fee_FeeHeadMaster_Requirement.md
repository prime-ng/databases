# Feature Requirement: Fee Head Master

## 1. Module Name
**StudentFee** (Prefix: `fee_`)

## 2. Feature Name
**Fee Head Master** — Core fee components catalog (Tuition, Transport, Hostel, etc.)

## 3. Tab / Submodule
**Configuration** (Route: `GET /student-fee/configuration`, Name: `student-fee.configuration`, Tab: `fee-head-master`)

## 4. Description
Defines the catalog of fee types (heads) that can be charged to students. Each head has a type (Tuition, Admission, Development, Exam, Lab, Library, Transport, Sports, Activity, Hostel), frequency (One-time, Monthly, Quarterly, Half-Yearly, Yearly), and optional tax configuration. Refundable flag controls whether amounts can be refunded on withdrawal.

## 5. Primary Model
**`Modules\StudentFee\Models\FeeHeadMaster`** (Table: `fee_head_master`)

## 6. Controller
**`Modules\StudentFee\Http\Controllers\FeeHeadMasterController`**

### Methods Implemented:
| Method | Route | Permission |
|--------|-------|------------|
| `index()` | `GET /fee-head-master` | Redirects to configuration tab |
| `create()` | `GET /fee-head-master/create` | `tenant.fee-head-master.create` |
| `store()` | `POST /fee-head-master` | `tenant.fee-head-master.create` |
| `show($id)` | `GET /fee-head-master/{id}` | `tenant.fee-head-master.view` |
| `edit($id)` | `GET /fee-head-master/{id}/edit` | `tenant.fee-head-master.update` |
| `update()` | `PUT /fee-head-master/{id}` | `tenant.fee-head-master.update` |
| `destroy($id)` | `DELETE /fee-head-master/{id}` | `tenant.fee-head-master.delete` |
| `trashedFeeHeadMasters()` | `GET /fee-head-master/trash/view` | `tenant.fee-head-master.restore` |
| `restore($id)` | `GET /fee-head-master/{id}/restore` | `tenant.fee-head-master.restore` |
| `forceDelete($id)` | `DELETE /fee-head-master/{id}/force-delete` | `tenant.fee-head-master.forceDelete` |
| `toggleStatus()` | `POST /fee-head-master/{fee_head_master}/toggle-status` | `tenant.fee-head-master.status` |

## 7. Form Requests

### StoreFeeHeadMasterRequest
- Authorizes via `tenant.fee-head-master` CRUD permission
- Rules:
  - `code`: required, string, max:30, unique:fee_head_master,code
  - `name`: required, string, max:100
  - `head_type_id`: required, integer, exists:sys_dropdown_table,id
  - `frequency`: required, in:One-time,Monthly,Quarterly,Half-Yearly,Yearly
  - `tax_percentage`: nullable, numeric, min:0, max:100
  - `account_head_code`: nullable, string, max:50
  - `display_order`: nullable, integer, min:1
  - `description`: nullable, string
  - `is_refundable`: nullable, boolean
  - `tax_applicable`: nullable, boolean
  - `is_active`: nullable, boolean

### UpdateFeeHeadMasterRequest
- Same rules as Store, with `code` unique ignored on self (via `Rule::unique(...)->ignore($feeHeadId)`)
- Authorizes via `tenant.fee-head-master` CRUD permission

### ToggleStatusRequest
- Rule: `is_active` required, boolean
- Authorizes via Gate::any on multiple status permissions including `tenant.fee-head-master.status`

## 8. Database Table Structure

**Table: `fee_head_master`**

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INT UNSIGNED | AUTO_INCREMENT PRIMARY KEY |
| `code` | VARCHAR(30) | NOT NULL, UNIQUE (uq_fee_head_code) |
| `name` | VARCHAR(100) | NOT NULL |
| `description` | VARCHAR(255) | NULLABLE |
| `head_type_id` | INT UNSIGNED | NOT NULL, FK → sys_dropdown_table (head_type_id classification) |
| `frequency` | ENUM('One-time','Monthly','Quarterly','Half-Yearly','Yearly') | NOT NULL, DEFAULT 'Monthly' |
| `is_refundable` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `tax_applicable` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `tax_percentage` | DECIMAL(5,2) | DEFAULT 0.00 |
| `account_head_code` | VARCHAR(50) | NULLABLE, ERP integration |
| `display_order` | INT | NOT NULL, DEFAULT 1 |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| `deleted_at` | TIMESTAMP | NULL (Soft Delete) |

**Indexes:**
- UNIQUE `uq_fee_head_code` (`code`)
- INDEX `idx_fee_head_type` (`head_type_id`)
- INDEX `idx_fee_head_active` (`is_active`)

### Model Attributes
- **$fillable**: code, name, description, head_type_id, frequency, is_refundable, tax_applicable, tax_percentage, account_head_code, display_order, is_active
- **$casts**: head_type_id(integer), is_refundable(boolean), tax_applicable(boolean), tax_percentage(decimal:2), display_order(integer), is_active(boolean), frequency(string)
- **SoftDeletes** trait used

### Model Scopes & Helpers
- `scopeActive(Builder)`: where is_active = true
- `calculateTax(float $amount)`: returns tax_percentage% of amount if tax_applicable, else 0
- `calculateTotal(float $amount)`: returns amount + calculateTax(amount)

### Relationships
- `headType()`: BelongsTo → Dropdown (sys_dropdown_table) via head_type_id
- `groupMappings()`: HasMany → FeeGroupHeadsJnt via head_id
- `concessionTypes()`: BelongsToMany → FeeConcessionType via fee_concession_applicable_heads

## 9. Business Rules / Logic

### Tax Calculation
- When `tax_applicable = true`: `tax_amount = amount × (tax_percentage / 100)`
- When `tax_applicable = false`: `tax_amount = 0` regardless of tax_percentage value (controller forces 0)
- The `calculateTax(float $amount)` helper computes tax for a given amount
- The `calculateTotal(float $amount)` helper returns `amount + tax_amount`

### Frequency Behavior
- `One-time`: Charged once (admission fee, development fee)
- `Monthly`: Charged every month (tuition fee)
- `Quarterly`: Charged every 3 months
- `Half-Yearly`: Charged every 6 months
- `Yearly`: Charged once per academic year

### Refundable Logic
- `is_refundable = true`: Amount can be refunded via FeeRefund on student withdrawal
- `is_refundable = false`: Not eligible for refund

### Head Type Integration
- `head_type_id` references `sys_dropdown_table` for dynamic categorization
- Dropdown values: Tuition Fee, Transport Fee, Hostel Fee, Library Fee, Sports Fee, Examination Fee, Laboratory Fee, Activity Fee, Development Fee, Other Fee

## 10. Controller Logic Details

### index()
- Redirects to `route('student-fee.configuration', ['tab' => 'fee-head-master'])`

### create()
- Authorization: `tenant.fee-head-master.create`
- Loads active head types from `sys_dropdown_table` where key matches `fee_head_master.head_type_id%`
- Returns create view with headTypes collection

### store(StoreFeeHeadMasterRequest)
- Authorization: `tenant.fee-head-master.create`
- Handles boolean fields via `$request->boolean()` (is_refundable, tax_applicable, is_active)
- Forces `tax_percentage = 0` if `tax_applicable` is false
- Creates FeeHeadMaster record
- Activity logged with code and name
- Flash message: `flash('created.fee_head_master')`
- Redirects to configuration tab

### show($id)
- Authorization: `tenant.fee-head-master.view`
- findOrFail returns 404 if not found
- Returns show view

### edit($id)
- Authorization: `tenant.fee-head-master.update`
- Loads head types same as create
- Returns edit view

### update(UpdateFeeHeadMasterRequest, $id)
- Authorization: `tenant.fee-head-master.update`
- Same boolean handling and tax logic as store
- Activity logged with old_code and new_code
- Flash message: `'Fee Head Master updated'`
- Redirects to configuration tab

### destroy($id)
- Authorization: `tenant.fee-head-master.delete`
- Deactivates (is_active = false) before soft delete
- Activity logged as 'Trashed'
- Flash message: `flash('trashed.fee_head_master')`
- Redirects to configuration tab

### trashedFeeHeadMasters()
- Authorization: `tenant.fee-head-master.restore`
- Paginates onlyTrashed records (10 per page)
- Returns trash view

### restore($id)
- Authorization: `tenant.fee-head-master.restore`
- Restores model and reactivates (is_active = true)
- Activity logged as 'Restored'
- Flash message: `flash('restored.fee_head_master')`
- Redirects to trashed route

### forceDelete($id)
- Authorization: `tenant.fee-head-master.forceDelete`
- Uses withTrashed()->findOrFail
- Permanently deletes
- Activity logged as 'Deleted'
- Flash message: `flash('force_deleted.fee_head_master')`
- Redirects to trashed route

### toggleStatus(ToggleStatusRequest, FeeHeadMaster)
- Authorization: `tenant.fee-head-master.status`
- Sets is_active from request input
- Activity logged as 'Toggled'
- Returns JSON response with success flag and message `flash('status_updated.fee_head_master')` or `flash('status_switch_failed.fee_head_master')`

## 11. Edge Cases & Validations
- Code is immutable after creation (not enforced in controller, but update uses unique-ignore on self)
- If tax_applicable is false, tax_percentage is forced to 0 (cannot store non-zero)
- Deactivate before soft delete: done in destroy
- Restore reactivates: done in restore
- Inactive heads hidden from fee structure dropdowns (via `active()` scope)
- Head type dropdown must be active (where is_active = true)

## 12. Dependencies / Relations
- **sys_dropdown_table**: head_type_id FK → Head type classification
- **fee_group_heads_jnt**: HasMany via head_id (group mappings)
- **fee_concession_applicable_heads**: BelongsToMany → FeeConcessionType
- **fee_structure_details**: HasMany via head_id (structure line items)
- **fee_group_master**: BelongsToMany via fee_group_heads_jnt

## 13. API / Route Details

### Web Routes (resource + additional):
| Method | URI | Name | Middleware |
|--------|-----|------|-----------|
| GET | `/fee-head-master` | `fee-head-master.index` | web, tenant |
| GET | `/fee-head-master/create` | `fee-head-master.create` | web, tenant |
| POST | `/fee-head-master` | `fee-head-master.store` | web, tenant |
| GET | `/fee-head-master/{fee_head_master}` | `fee-head-master.show` | web, tenant |
| GET | `/fee-head-master/{fee_head_master}/edit` | `fee-head-master.edit` | web, tenant |
| PUT | `/fee-head-master/{fee_head_master}` | `fee-head-master.update` | web, tenant |
| DELETE | `/fee-head-master/{fee_head_master}` | `fee-head-master.destroy` | web, tenant |
| GET | `/fee-head-master/trash/view` | `fee-head-master.trashed` | web, tenant |
| GET | `/fee-head-master/{id}/restore` | `fee-head-master.restore` | web, tenant |
| DELETE | `/fee-head-master/{id}/force-delete` | `fee-head-master.forceDelete` | web, tenant |
| POST | `/fee-head-master/{fee_head_master}/toggle-status` | `fee-head-master.toggleStatus` | web, tenant |

## 14. Permissions

| Operation | Permission Key |
|-----------|---------------|
| View heads list | `tenant.fee-head-master.viewAny` (via Gate::authorize on view tab) |
| View head details | `tenant.fee-head-master.view` |
| Create head | `tenant.fee-head-master.create` |
| Update head | `tenant.fee-head-master.update` |
| Delete head | `tenant.fee-head-master.delete` |
| Restore head | `tenant.fee-head-master.restore` |
| Force delete head | `tenant.fee-head-master.forceDelete` |
| Toggle status | `tenant.fee-head-master.status` |

## 15. Flash Messages
- `flash('created.fee_head_master')` — on store
- `'Fee Head Master updated'` — on update (hardcoded string)
- `flash('trashed.fee_head_master')` — on destroy
- `flash('restored.fee_head_master')` — on restore
- `flash('force_deleted.fee_head_master')` — on forceDelete
- `flash('status_updated.fee_head_master')` — on toggleStatus success
- `flash('status_switch_failed.fee_head_master')` — on toggleStatus failure

## 16. Known Issues / Gotchas
- Code uniqueness is enforced at DB level (UNIQUE index) and application level (FormRequest)
- tax_percentage can be stored as non-zero even when tax_applicable=false in raw DB, but controller forces 0
- toggleStatus uses `$feeHeadMaster` implicit route model binding
- destroy does NOT check for existing references before delete (no FK protection check)
- `index()` always redirects — the actual listing is rendered via the `configuration()` tab view
