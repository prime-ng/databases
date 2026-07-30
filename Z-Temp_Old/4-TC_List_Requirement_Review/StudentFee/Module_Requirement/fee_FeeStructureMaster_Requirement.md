# Feature Requirement: Fee Structure Master

## 1. Module Name
**StudentFee** (Prefix: `fee_`)

## 2. Feature Name
**Fee Structure Master** — Complete fee package per class, academic session, and student category

## 3. Tab / Submodule
**Configuration** (Route: `GET /student-fee/configuration`, Name: `student-fee.configuration`, Tab: `fee-structure-master`)

## 4. Description
Defines the complete fee package per class, academic session, and student category. Combines fee groups and heads with specific amounts. Supports effective date ranges, board-type variations, and auto-generated installments. Each structure has a computed `total_fee_amount` (sum of all head amounts). Blocks editing or deletion if student assignments exist.

## 5. Primary Model
**`Modules\StudentFee\Models\FeeStructureMaster`** (Table: `fee_structure_master`)

**Secondary Model:** `Modules\StudentFee\Models\FeeStructureDetail` (Table: `fee_structure_details`)

## 6. Controller
**`Modules\StudentFee\Http\Controllers\FeeStructureMasterController`**

### Methods Implemented:
| Method | Route | Permission |
|--------|-------|------------|
| `index()` | `GET /fee-structure-master` | Redirects to configuration tab |
| `create()` | `GET /fee-structure-master/create` | `tenant.fee-structure-master.create` |
| `store()` | `POST /fee-structure-master` | `tenant.fee-structure-master.create` |
| `show($id)` | `GET /fee-structure-master/{id}` | `tenant.fee-structure-master.view` |
| `edit($id)` | `GET /fee-structure-master/{id}/edit` | `tenant.fee-structure-master.update` |
| `update()` | `PUT /fee-structure-master/{id}` | `tenant.fee-structure-master.update` |
| `destroy($id)` | `DELETE /fee-structure-master/{id}` | `tenant.fee-structure-master.delete` |
| `trashedFeeStructureMasters()` | `GET /fee-structure-master/trash/view` | `tenant.fee-structure-master.restore` |
| `restore($id)` | `GET /fee-structure-master/{id}/restore` | `tenant.fee-structure-master.restore` |
| `forceDelete($id)` | `DELETE /fee-structure-master/{id}/force-delete` | `tenant.fee-structure-master.forceDelete` |
| `toggleStatus()` | `POST /fee-structure-master/{fee_structure_master}/toggle-status` | `tenant.fee-structure-master.status` |

## 7. Form Requests

### StoreFeeStructureMasterRequest
- Authorizes via `tenant.fee-structure-master` CRUD permission
- Rules:
  - `academic_session_id`: required, integer
  - `class_id`: required, integer, exists:sch_classes,id
  - `student_category_id`: nullable, integer, exists:sys_dropdown_table,id
  - `code`: required, string, max:50, unique:fee_structure_master,code
  - `name`: required, string, max:100
  - `board_type`: nullable, string, max:50
  - `effective_from`: required, date
  - `effective_to`: nullable, date, after:effective_from
  - `details`: nullable, array
  - `details.*.head_id`: nullable, integer, exists:fee_head_master,id
  - `details.*.group_id`: nullable, integer, exists:fee_group_master,id
  - `details.*.amount`: required_with:details, numeric, min:0
  - `details.*.is_optional`: nullable, boolean
  - `details.*.tax_included`: nullable, boolean
  - `installments`: nullable, array
  - `installments.*.installment_name`: required_with:installments, string, max:100
  - `installments.*.due_date`: required_with:installments, date
  - `installments.*.percentage_due`: required_with:installments, numeric, min:0, max:100
  - `installments.*.grace_days`: required_with:installments, integer, min:0
  - `is_active`: nullable, boolean
- **Custom After Validation**: Sum of installment percentages must equal exactly 100%. Error message: `'The sum of installment percentages must equal exactly 100%. Current sum: ' . $totalPercentage . '%'`

### UpdateFeeStructureMasterRequest
- Same rules as Store, with `code` unique ignored on self
- Same custom after validation for installments (sum must = 100%)
- Authorizes via `tenant.fee-structure-master` CRUD permission

### ToggleStatusRequest
- Rule: `is_active` required, boolean
- Authorizes via Gate::any including `tenant.fee-structure-master.status`

## 8. Database Table Structure

**Table: `fee_structure_master`**

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INT UNSIGNED | AUTO_INCREMENT PRIMARY KEY |
| `academic_session_id` | SMALLINT UNSIGNED | NOT NULL, FK → sch_org_academic_sessions_jnt (RESTRICT) |
| `class_id` | INT UNSIGNED | NOT NULL, FK → sch_classes (RESTRICT) |
| `student_category_id` | INT UNSIGNED | NULL, FK → sys_dropdown_table (SET NULL) |
| `board_type` | VARCHAR(50) | NULLABLE |
| `code` | VARCHAR(50) | NOT NULL, UNIQUE |
| `name` | VARCHAR(100) | NOT NULL |
| `effective_from` | DATE | NOT NULL |
| `effective_to` | DATE | NULLABLE |
| `total_fee_amount` | DECIMAL(12,2) | NULL, pre-calculated sum |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| `deleted_at` | TIMESTAMP | NULL (Soft Delete) |

**Indexes:**
- UNIQUE `code`
- INDEX `idx_fee_structure_session_class` (`academic_session_id`, `class_id`)
- INDEX `idx_fee_structure_active` (`is_active`)
- FK `fk_fs_session` → sch_org_academic_sessions_jnt(id) ON DELETE RESTRICT
- FK `fk_fs_class` → sch_classes(id) ON DELETE RESTRICT
- FK `fk_fs_category` → sys_dropdown_table(id) ON DELETE SET NULL

**Table: `fee_structure_details`**

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INT UNSIGNED | AUTO_INCREMENT PRIMARY KEY |
| `fee_structure_id` | INT UNSIGNED | NOT NULL, FK → fee_structure_master (CASCADE) |
| `head_id` | INT UNSIGNED | NOT NULL, FK → fee_head_master (RESTRICT) |
| `group_id` | INT UNSIGNED | NULL, FK → fee_group_master (SET NULL) |
| `amount` | DECIMAL(10,2) | NOT NULL |
| `is_optional` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `tax_included` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `created_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE |

**Detail Indexes:**
- UNIQUE `uq_fee_structure_head` (`fee_structure_id`, `head_id`)
- FK `fk_fsd_structure` → fee_structure_master(id) ON DELETE CASCADE
- FK `fk_fsd_head` → fee_head_master(id) ON DELETE RESTRICT
- FK `fk_fsd_group` → fee_group_master(id) ON DELETE SET NULL

### Model Attributes (FeeStructureMaster)
- **$fillable**: academic_session_id, class_id, student_category_id, board_type, code, name, effective_from, effective_to, total_fee_amount, is_active
- **$casts**: academic_session_id(integer), class_id(integer), student_category_id(integer), effective_from(date), effective_to(date), total_fee_amount(decimal:2), is_active(boolean)
- **SoftDeletes** trait used

### Model Relationships
- `academicSession()`: BelongsTo → AcademicSession
- `class()`: BelongsTo → SchoolClass
- `studentCategory()`: BelongsTo → Dropdown
- `details()`: HasMany → FeeStructureDetail
- `assignments()`: HasMany → FeeStudentAssignment
- `installments()`: HasMany → FeeInstallment

### Model Scopes & Helpers
- `scopeActive(Builder)`: where is_active = true
- `scopeForSession(Builder, int)`: where academic_session_id
- `scopeForClass(Builder, int)`: where class_id
- `isCurrentlyEffective()`: checks if today is within effective_from..effective_to range

## 9. Business Rules / Logic

### Total Fee Computation
- `total_fee_amount` = sum of all `details.amount` (all details, regardless of is_optional)
- Recalculated on every store/update

### Assignment Protection
- If any FeeStudentAssignment exists for this structure:
  - Update blocked with error: `'Cannot edit: student assignments already use this structure.'`
  - Delete blocked with error: `'Cannot delete: student assignments exist for this structure.'`

### Installment Sync
- On store: if installments provided, auto-create FeeInstallment records (installment_no auto-incremented from 1)
- On update: deletes ALL existing installments, re-creates from submission
- Each installment amount_due computed as: `round((totalFee * percentage_due) / 100, 2)`
- Sum of all installment percentage_due must equal exactly 100%

### Detail Sync
- On update: deletes ALL existing details, re-creates from submission (full sync)

## 10. Controller Logic Details

### index()
- Redirects to `route('student-fee.configuration', ['tab' => 'fee-structure-master'])`

### create()
- Loads academic sessions, classes, active fee heads, active fee groups, student categories
- Returns create view

### store(StoreFeeStructureMasterRequest)
- Uses `DB::transaction`
- Computes totalFee from sum of detail amounts
- Creates FeeStructureMaster
- Creates FeeStructureDetail for each detail entry
- If installments provided: creates FeeInstallment records with auto-incrementing installment_no
- Activity logged
- Flash: `'Fee Structure created successfully.'`

### update(UpdateFeeStructureMasterRequest, $id)
- Checks `$structure->assignments()->exists()` — if true, returns back with error
- Uses `DB::transaction`
- Full sync: deletes all details, re-creates; deletes all installments, re-creates
- Activity logged
- Flash: `'Fee Structure updated successfully.'`

### destroy($id)
- Checks `$structure->assignments()->exists()` — if true, returns back with error
- Deactivates then soft deletes
- Flash: `'Fee Structure deleted successfully.'`

### toggleStatus(ToggleStatusRequest, FeeStructureMaster)
- Sets is_active from request input
- Returns JSON with `flash('status_updated.fee_structure_master')` or `flash('status_switch_failed.fee_structure_master')`

## 11. Edge Cases & Validations
- Installment percentage sum must equal exactly 100% (validated in FormRequest after hook)
- effective_to must be after effective_from (validated in FormRequest)
- Update/Destroy blocked if student assignments exist for this structure
- Full sync of details and installments on update (deletes all, re-creates)
- FK RESTRICT on head_id means a head cannot be deleted if used in any structure detail

## 12. Dependencies / Relations
- **sch_org_academic_sessions_jnt**: academic_session_id FK (RESTRICT)
- **sch_classes**: class_id FK (RESTRICT)
- **sys_dropdown_table**: student_category_id FK (SET NULL)
- **fee_head_master**: details.head_id FK (RESTRICT)
- **fee_group_master**: details.group_id FK (SET NULL)
- **fee_student_assignments**: assignments() HasMany — used for protection check
- **fee_installments**: installments() HasMany — synced on store/update

## 13. API / Route Details

### Web Routes (resource + additional):
| Method | URI | Name |
|--------|-----|------|
| GET | `/fee-structure-master` | `fee-structure-master.index` |
| GET | `/fee-structure-master/create` | `fee-structure-master.create` |
| POST | `/fee-structure-master` | `fee-structure-master.store` |
| GET | `/fee-structure-master/{fee_structure_master}` | `fee-structure-master.show` |
| GET | `/fee-structure-master/{fee_structure_master}/edit` | `fee-structure-master.edit` |
| PUT | `/fee-structure-master/{fee_structure_master}` | `fee-structure-master.update` |
| DELETE | `/fee-structure-master/{fee_structure_master}` | `fee-structure-master.destroy` |
| GET | `/fee-structure-master/trash/view` | `fee-structure-master.trashed` |
| GET | `/fee-structure-master/{id}/restore` | `fee-structure-master.restore` |
| DELETE | `/fee-structure-master/{id}/force-delete` | `fee-structure-master.forceDelete` |
| POST | `/fee-structure-master/{fee_structure_master}/toggle-status` | `fee-structure-master.toggleStatus` |

## 14. Permissions

| Operation | Permission Key |
|-----------|---------------|
| View structures list | `tenant.fee-structure-master.viewAny` |
| View structure details | `tenant.fee-structure-master.view` |
| Create structure | `tenant.fee-structure-master.create` |
| Update structure | `tenant.fee-structure-master.update` |
| Delete structure | `tenant.fee-structure-master.delete` |
| Restore structure | `tenant.fee-structure-master.restore` |
| Force delete structure | `tenant.fee-structure-master.forceDelete` |
| Toggle status | `tenant.fee-structure-master.status` |

## 15. Flash Messages
- `'Fee Structure created successfully.'` — on store
- `'Fee Structure updated successfully.'` — on update
- `'Fee Structure deleted successfully.'` — on destroy
- `'Fee Structure restored successfully.'` — on restore
- `'Fee Structure permanently deleted.'` — on forceDelete
- `flash('status_updated.fee_structure_master')` — on toggleStatus success
- `flash('status_switch_failed.fee_structure_master')` — on toggleStatus failure
- `'Cannot edit: student assignments already use this structure.'` — assignment protection
- `'Cannot delete: student assignments exist for this structure.'` — assignment protection

## 16. Known Issues / Gotchas
- Assignment protection checks `assignments()->exists()` — if any assignment exists (even inactive/soft-deleted), update/destroy is blocked
- Full sync of details/installments on update uses `->delete()` not `->forceDelete()` — if model uses SoftDeletes, records go to trash
- total_fee_amount includes optional head amounts (sum of ALL details, not just mandatory)
- academic_session_id validation only checks `integer` (no exists rule in FormRequest)
- Store/update does NOT enforce uniqueness of (session + class + category + board) combination in controller
