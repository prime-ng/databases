# Feature Requirement: Fee Concession Type

## 1. Module Name
**StudentFee** (Prefix: `fee_`)

## 2. Feature Name
**Fee Concession Type** — Discount/concession definitions applicable to student fees

## 3. Tab / Submodule
**Configuration** (Route: `GET /student-fee/configuration`, Name: `student-fee.configuration`, Tab: `fee-concession-type`)

## 4. Description
Defines discount/concession types applicable to student fees. Supports percentage or fixed amount discounts applied to total fee, specific heads, or specific groups. Concessions can require approval workflow with role-based authorization.

## 5. Primary Model
**`Modules\StudentFee\Models\FeeConcessionType`** (Table: `fee_concession_types`)

**Secondary Model:** `Modules\StudentFee\Models\FeeConcessionApplicableHead` (Table: `fee_concession_applicable_heads`)

## 6. Controller
**`Modules\StudentFee\Http\Controllers\FeeConcessionTypeController`**

### Methods Implemented:
| Method | Route | Permission |
|--------|-------|------------|
| `index()` | `GET /fee-concession-type` | Redirects to configuration tab |
| `create()` | `GET /fee-concession-type/create` | `tenant.fee-concession-type.create` |
| `store()` | `POST /fee-concession-type` | `tenant.fee-concession-type.create` |
| `show($id)` | `GET /fee-concession-type/{id}` | `tenant.fee-concession-type.view` |
| `edit($id)` | `GET /fee-concession-type/{id}/edit` | `tenant.fee-concession-type.update` |
| `update()` | `PUT /fee-concession-type/{id}` | `tenant.fee-concession-type.update` |
| `destroy($id)` | `DELETE /fee-concession-type/{id}` | `tenant.fee-concession-type.delete` |
| `trashedFeeConcessionTypes()` | `GET /fee-concession-type/trash/view` | `tenant.fee-concession-type.restore` |
| `restore($id)` | `GET /fee-concession-type/{id}/restore` | `tenant.fee-concession-type.restore` |
| `forceDelete($id)` | `DELETE /fee-concession-type/{id}/force-delete` | `tenant.fee-concession-type.forceDelete` |
| `toggleStatus()` | `POST /fee-concession-type/{fee_concession_type}/toggle-status` | `tenant.fee-concession-type.status` |

## 7. Form Requests

### StoreFeeConcessionTypeRequest
- Authorizes via `tenant.fee-concession-type` CRUD permission
- Rules:
  - `code`: required, string, max:50, unique:fee_concession_types,code
  - `name`: required, string, max:100
  - `concession_category_id`: required, integer, exists:sys_dropdown_table,id
  - `discount_type`: required, in:Percentage,Fixed Amount
  - `discount_value`: required, numeric, min:0.01, max:100 (if Percentage)
  - `applicable_on`: required, in:Total Fee,Specific Heads,Specific Groups
  - `max_cap_amount`: nullable, numeric, min:0, gte:discount_value (if Fixed Amount)
  - `requires_approval`: nullable, boolean
  - `approval_level_role_id`: required_if:requires_approval,1 , nullable, integer, exists:sys_roles,id
  - `is_active`: nullable, boolean
- Custom messages:
  - `'Percentage discount cannot exceed 100%.'`
  - `'Max cap cannot be less than discount value.'`
  - `'Approval level is required when approval is required.'`

### UpdateFeeConcessionTypeRequest
- Same rules as Store, with `code` unique ignored on self
- Same custom messages

### ToggleStatusRequest
- Rule: `is_active` required, boolean
- Authorizes via Gate::any including `tenant.fee-concession-type.status`

## 8. Database Table Structure

**Table: `fee_concession_types`**

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INT UNSIGNED | AUTO_INCREMENT PRIMARY KEY |
| `code` | VARCHAR(50) | NOT NULL, UNIQUE |
| `name` | VARCHAR(100) | NOT NULL |
| `concession_category_id` | INT UNSIGNED | NOT NULL, FK → sys_dropdown_table (RESTRICT) |
| `discount_type` | ENUM('Percentage','Fixed Amount') | NOT NULL |
| `discount_value` | DECIMAL(10,2) | NOT NULL |
| `applicable_on` | ENUM('Total Fee','Specific Heads','Specific Groups') | NOT NULL |
| `max_cap_amount` | DECIMAL(10,2) | NULLABLE |
| `requires_approval` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `approval_level_role_id` | INT | NULL, FK → sys_roles |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| `deleted_at` | TIMESTAMP | NULL (Soft Delete) |

**Indexes:**
- UNIQUE `code`
- INDEX `idx_concession_category` (`concession_category_id`)
- FK `fk_concession_category` → sys_dropdown_table(id) ON DELETE RESTRICT

**Table: `fee_concession_applicable_heads`** (Junction)

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INT UNSIGNED | AUTO_INCREMENT PRIMARY KEY |
| `concession_type_id` | INT UNSIGNED | NOT NULL, FK → fee_concession_types (CASCADE) |
| `head_id` | INT UNSIGNED | NULL, FK → fee_head_master (CASCADE) |
| `group_id` | INT UNSIGNED | NULL, FK → fee_group_master (CASCADE) |
| `created_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |

**Junction Indexes:**
- UNIQUE `uq_concession_head` (`concession_type_id`, `head_id`)
- UNIQUE `uq_concession_group` (`concession_type_id`, `group_id`)
- CHECK `chk_cah_head_or_group`: (head_id IS NOT NULL AND group_id IS NULL) OR (head_id IS NULL AND group_id IS NOT NULL)

### Model Attributes (FeeConcessionType)
- **$fillable**: code, name, concession_category_id, discount_type, discount_value, applicable_on, max_cap_amount, requires_approval, approval_level_role_id, is_active
- **$casts**: concession_category_id(integer), discount_value(decimal:2), max_cap_amount(decimal:2), requires_approval(boolean), approval_level_role_id(integer), is_active(boolean), discount_type(string), applicable_on(string)
- **SoftDeletes** trait used

### Model Scopes & Helpers
- `scopeActive(Builder)`: where is_active = true
- `calculateDiscount(float $baseAmount)`: computes discount based on type, value, and max cap
- `requiresApproval(): bool`
- `getApprovalLevel(): ?int`

### Model Constants
- `TYPE_PERCENTAGE = 'Percentage'`, `TYPE_FIXED = 'Fixed Amount'`
- `APPLY_TOTAL = 'Total Fee'`, `APPLY_HEADS = 'Specific Heads'`, `APPLY_GROUPS = 'Specific Groups'`

## 9. Business Rules / Logic

### Discount Computation
- Percentage on Total Fee: `discount = total_fee × (discount_value / 100)`
- Percentage on Specific Heads: `discount = sum(head_amounts) × (discount_value / 100)`
- Fixed Amount: `discount = discount_value` (direct)
- If max_cap_amount set: `discount = min(computed_discount, max_cap_amount)`

### Applicable On Behavior
- `Total Fee`: Discount applies to entire fee amount
- `Specific Heads`: Discount applies only to mapped heads (via junction table)
- `Specific Groups`: Discount applies only to mapped groups (via junction table)

### Approval Workflow
- If `requires_approval=true`: `approval_level_role_id` must be set
- The specified role receives approval notifications when student concession is created

## 10. Controller Logic Details

### index()
- Redirects to `route('student-fee.configuration', ['tab' => 'fee-concession-type'])`

### create()
- Authorization: `tenant.fee-concession-type.create`
- Loads concession categories from sys_dropdown_table (key: `concession_category.%`)
- Loads discount types array, applicable options, and roles
- Returns create view

### store(StoreFeeConcessionTypeRequest)
- Authorization: `tenant.fee-concession-type.create`
- Uses `DB::beginTransaction/commit/rollback`
- Converts code to uppercase via `strtoupper()`
- Sets approval_level_role_id only if requires_approval is true
- Creates FeeConcessionType record (NO junction table handling for heads/groups in current code)
- Activity logged
- Flash: `flash('created.fee_concession_type')`
- On exception: rollback, report, return back with system_error message

### update(UpdateFeeConcessionTypeRequest, $id)
- Authorization: `tenant.fee-concession-type.update`
- Same logic as store
- Flash: `flash('updated.fee_concession_type')`

### destroy($id)
- Authorization: `tenant.fee-concession-type.delete`
- Deactivates then soft deletes
- Flash: `flash('trashed.fee_concession_type')`

### toggleStatus(ToggleStatusRequest, FeeConcessionType)
- Authorization: `tenant.fee-concession-type.status`
- Toggles is_active (negates current value: `! $feeConcessionType->is_active`)
- Returns JSON with `flash('status_updated.fee_concession_type')` or `flash('status_switch_failed.fee_concession_type')`

## 11. Edge Cases & Validations
- discount_value must be 0.01-100 for Percentage type, 0.01+ for Fixed Amount
- max_cap_amount cannot be less than discount_value for Fixed Amount type
- approval_level_role_id required when requires_approval=true
- If requires_approval=false, approval_level_role_id is set to null
- Code stored in uppercase

## 12. Dependencies / Relations
- **sys_dropdown_table**: concession_category_id FK (RESTRICT)
- **sys_roles**: approval_level_role_id FK (nullable)
- **fee_concession_applicable_heads**: HasMany (applicable head/group mappings)
- **fee_head_master**: BelongsToMany via junction
- **fee_group_master**: BelongsToMany via junction
- **fee_student_concessions**: HasMany (student concession applications)

## 13. API / Route Details

### Web Routes (resource + additional):
| Method | URI | Name |
|--------|-----|------|
| GET | `/fee-concession-type` | `fee-concession-type.index` |
| GET | `/fee-concession-type/create` | `fee-concession-type.create` |
| POST | `/fee-concession-type` | `fee-concession-type.store` |
| GET | `/fee-concession-type/{fee_concession_type}` | `fee-concession-type.show` |
| GET | `/fee-concession-type/{fee_concession_type}/edit` | `fee-concession-type.edit` |
| PUT | `/fee-concession-type/{fee_concession_type}` | `fee-concession-type.update` |
| DELETE | `/fee-concession-type/{fee_concession_type}` | `fee-concession-type.destroy` |
| GET | `/fee-concession-type/trash/view` | `fee-concession-type.trashed` |
| GET | `/fee-concession-type/{id}/restore` | `fee-concession-type.restore` |
| DELETE | `/fee-concession-type/{id}/force-delete` | `fee-concession-type.forceDelete` |
| POST | `/fee-concession-type/{fee_concession_type}/toggle-status` | `fee-concession-type.toggleStatus` |

## 14. Permissions

| Operation | Permission Key |
|-----------|---------------|
| View concession types list | `tenant.fee-concession-type.viewAny` |
| View concession type details | `tenant.fee-concession-type.view` |
| Create concession type | `tenant.fee-concession-type.create` |
| Update concession type | `tenant.fee-concession-type.update` |
| Delete concession type | `tenant.fee-concession-type.delete` |
| Restore concession type | `tenant.fee-concession-type.restore` |
| Force delete concession type | `tenant.fee-concession-type.forceDelete` |
| Toggle status | `tenant.fee-concession-type.status` |

## 15. Flash Messages
- `flash('created.fee_concession_type')` — on store
- `flash('updated.fee_concession_type')` — on update
- `flash('trashed.fee_concession_type')` — on destroy
- `flash('restored.fee_concession_type')` — on restore
- `flash('force_deleted.fee_concession_type')` — on forceDelete
- `flash('status_updated.fee_concession_type')` — on toggleStatus success
- `flash('status_switch_failed.fee_concession_type')` — on toggleStatus failure

## 16. Known Issues / Gotchas
- The store/update methods do NOT handle the `fee_concession_applicable_heads` junction table — the applicable heads/groups mapping is NOT being saved in the current controller implementation
- `trashedFeeConcessionTypes()` eager loads `concessionCategory` and `approvalRole` relationships
- toggleStatus negates current value instead of using request input (inconsistent with FeeHeadMaster/FeeStructureMaster controllers)
- Code is converted to uppercase via `strtoupper()` before save
- Discount category dropdown uses key `concession_category.%` pattern (note the dot-percent, different from head_type pattern)
