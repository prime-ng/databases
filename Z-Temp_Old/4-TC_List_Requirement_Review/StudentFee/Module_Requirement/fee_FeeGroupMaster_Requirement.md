# Feature Requirement: Fee Group Master

## 1. Module Name
**StudentFee** (Prefix: `fee_`)

## 2. Feature Name
**Fee Group Master** — Logical grouping of fee heads (e.g., "Academic Package")

## 3. Tab / Submodule
**Configuration** (Route: `GET /student-fee/configuration`, Name: `student-fee.configuration`, Tab: `fee-group-master`)

## 4. Description
Groups related fee heads into logical bundles (Academic Core, Transport, Hostel, Activity). Groups can be optional or mandatory. Used to simplify fee structure creation by assigning groups instead of individual heads. Each group has head membership with optional override per head and default amount per head override.

## 5. Primary Model
**`Modules\StudentFee\Models\FeeGroupMaster`** (Table: `fee_group_master`)

## 6. Controller
**`Modules\StudentFee\Http\Controllers\FeeGroupMasterController`**

### Methods Implemented:
| Method | Route | Permission |
|--------|-------|------------|
| `index()` | `GET /fee-group-master` | Redirects to configuration tab |
| `create()` | `GET /fee-group-master/create` | `tenant.fee-group-master.create` |
| `store()` | `POST /fee-group-master` | `tenant.fee-group-master.create` |
| `show($id)` | `GET /fee-group-master/{id}` | `tenant.fee-group-master.view` |
| `edit($id)` | `GET /fee-group-master/{id}/edit` | `tenant.fee-group-master.update` |
| `update()` | `PUT /fee-group-master/{id}` | `tenant.fee-group-master.update` |
| `destroy($id)` | `DELETE /fee-group-master/{id}` | `tenant.fee-group-master.delete` |
| `trashedFeeGroupMasters()` | `GET /fee-group-master/trash/view` | `tenant.fee-group-master.restore` |
| `restore($id)` | `GET /fee-group-master/{id}/restore` | `tenant.fee-group-master.restore` |
| `forceDelete($id)` | `DELETE /fee-group-master/{id}/force-delete` | `tenant.fee-group-master.forceDelete` |
| `toggleStatus()` | `POST /fee-group-master/{fee_group_master}/toggle-status` | `tenant.fee-group-master.status` |

## 7. Form Requests

### StoreFeeGroupMasterRequest
- Authorizes via `tenant.fee-group-master` CRUD permission
- Rules:
  - `code`: required, string, max:50, unique:fee_group_master,code
  - `name`: required, string, max:100
  - `description`: nullable, string
  - `display_order`: nullable, integer, min:1
  - `is_mandatory`: nullable, boolean
  - `is_active`: nullable, boolean
  - `heads`: nullable, array
  - `heads.*.head_id`: required, exists:fee_head_master,id
  - `heads.*.is_optional`: nullable, boolean
  - `heads.*.default_amount`: nullable, numeric, min:0
  - `heads.*.display_order`: nullable, integer, min:1

### UpdateFeeGroupMasterRequest
- Same rules as Store, with `code` unique ignored on self
- Authorizes via `tenant.fee-group-master` CRUD permission

### ToggleStatusRequest
- Rule: `is_active` required, boolean
- Authorizes via Gate::any including `tenant.fee-group-master.status`

## 8. Database Table Structure

**Table: `fee_group_master`**

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INT UNSIGNED | AUTO_INCREMENT PRIMARY KEY |
| `code` | VARCHAR(50) | NOT NULL, UNIQUE |
| `name` | VARCHAR(100) | NOT NULL |
| `description` | TEXT | NULLABLE |
| `is_mandatory` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `display_order` | INT | NOT NULL, DEFAULT 1 |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| `deleted_at` | TIMESTAMP | NULL (Soft Delete) |

**Indexes:**
- UNIQUE (`code`)
- INDEX `idx_fee_group_active` (`is_active`)

**Table: `fee_group_heads_jnt`** (Junction)

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INT UNSIGNED | AUTO_INCREMENT PRIMARY KEY |
| `group_id` | INT UNSIGNED | NOT NULL, FK → fee_group_master (CASCADE) |
| `head_id` | INT UNSIGNED | NOT NULL, FK → fee_head_master (CASCADE) |
| `is_optional` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `default_amount` | DECIMAL(10,2) | NULLABLE |
| `display_order` | INT | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE |

**Junction Indexes:**
- UNIQUE `uq_fee_group_head` (`group_id`, `head_id`)
- FK `fk_fgh_group` → fee_group_master(id) ON DELETE CASCADE
- FK `fk_fgh_head` → fee_head_master(id) ON DELETE CASCADE

### Model Attributes (FeeGroupMaster)
- **$fillable**: code, name, description, is_mandatory, display_order, is_active
- **$casts**: is_mandatory(boolean), display_order(integer), is_active(boolean)
- **SoftDeletes** trait used

### Model Attributes (FeeGroupHeadsJnt)
- **$fillable**: group_id, head_id, is_optional, default_amount, display_order
- **$casts**: group_id(integer), head_id(integer), is_optional(boolean), default_amount(decimal:2), display_order(integer)

### Model Scopes & Helpers
- `scopeActive(Builder)`: where is_active = true
- `scopeMandatory(Builder)`: where is_mandatory = true
- `isActive(): bool`
- `isMandatory(): bool`

## 9. Business Rules / Logic

### Mandatory Groups
- If `is_mandatory = true`: group is automatically included when a fee structure uses this group
- If `is_mandatory = false`: group can be opted in/out during student assignment

### Head Default Amount Override
- If `default_amount` is set in junction: value used as base amount when creating fee structure details
- If `default_amount` is null: amount comes from fee structure detail (per-structure pricing)

### Optional Heads within Group
- A mandatory group can have optional heads (`is_optional = true`)
- Optional heads can be deselected during student assignment

## 10. Controller Logic Details

### index()
- Redirects to `route('student-fee.configuration', ['tab' => 'fee-group-master'])`

### create()
- Authorization: `tenant.fee-group-master.create`
- Loads active fee heads ordered by display_order
- Returns create view

### store(StoreFeeGroupMasterRequest)
- Authorization: `tenant.fee-group-master.create`
- Uses `DB::transaction`
- Creates FeeGroupMaster with code, name, description, display_order (default 1), is_mandatory (boolean), is_active (boolean, default true)
- Loops through `request->input('heads', [])` and creates FeeGroupHeadsJnt for each
- Activity logged with code and head_count
- Flash message: `'Fee Group created successfully.'`
- Redirects to configuration tab

### show($id)
- Authorization: `tenant.fee-group-master.view`
- Eager loads `groupHeads.head`
- Returns show view

### edit($id)
- Authorization: `tenant.fee-group-master.update`
- Eager loads `groupHeads.head`
- Loads active fee heads for selection
- Returns edit view

### update(UpdateFeeGroupMasterRequest, $id)
- Authorization: `tenant.fee-group-master.update`
- Uses `DB::transaction`
- Updates FeeGroupMaster fields
- Full sync: deletes all existing groupHeads mappings, re-creates from submitted heads array
- Activity logged with code and head_count
- Flash message: `'Fee Group updated successfully.'`
- Redirects to configuration tab

### destroy($id)
- Authorization: `tenant.fee-group-master.delete`
- Deactivates then soft deletes
- Activity logged as 'Trashed'
- Flash message: `'Fee Group deleted successfully.'`
- Redirects to configuration tab

### trashedFeeGroupMasters()
- Authorization: `tenant.fee-group-master.restore`
- Paginates onlyTrashed records (10 per page, order by name)
- Returns trash view

### restore($id)
- Authorization: `tenant.fee-group-master.restore`
- Restores and reactivates
- Flash message: `'Fee Group restored successfully.'`
- Redirects to trashed route

### forceDelete($id)
- Authorization: `tenant.fee-group-master.forceDelete`
- Permanently deletes
- Flash message: `'Fee Group permanently deleted.'`
- Redirects to trashed route

### toggleStatus(ToggleStatusRequest, FeeGroupMaster)
- Authorization: `tenant.fee-group-master.status`
- Sets is_active from request input
- Returns JSON with `'Fee Group status updated successfully.'` or `'Failed to update Fee Group status.'`

## 11. Edge Cases & Validations
- Head IDs in heads array must exist in fee_head_master table
- Full sync on update: deletes all existing mappings (cascade from DB) — if FK fails, transaction rolls back
- Code unique enforced at DB and application level
- Deactivate before delete pattern
- Restore reactivates pattern

## 12. Dependencies / Relations
- **fee_head_master**: BelongsToMany via fee_group_heads_jnt
- **fee_group_heads_jnt**: HasMany (groupHeads relationship)
- **fee_structure_details**: HasMany through fee_structure
- **fee_concession_applicable_heads**: BelongsToMany via FeeConcessionType

## 13. API / Route Details

### Web Routes (resource + additional):
| Method | URI | Name |
|--------|-----|------|
| GET | `/fee-group-master` | `fee-group-master.index` |
| GET | `/fee-group-master/create` | `fee-group-master.create` |
| POST | `/fee-group-master` | `fee-group-master.store` |
| GET | `/fee-group-master/{fee_group_master}` | `fee-group-master.show` |
| GET | `/fee-group-master/{fee_group_master}/edit` | `fee-group-master.edit` |
| PUT | `/fee-group-master/{fee_group_master}` | `fee-group-master.update` |
| DELETE | `/fee-group-master/{fee_group_master}` | `fee-group-master.destroy` |
| GET | `/fee-group-master/trash/view` | `fee-group-master.trashed` |
| GET | `/fee-group-master/{id}/restore` | `fee-group-master.restore` |
| DELETE | `/fee-group-master/{id}/force-delete` | `fee-group-master.forceDelete` |
| POST | `/fee-group-master/{fee_group_master}/toggle-status` | `fee-group-master.toggleStatus` |

## 14. Permissions

| Operation | Permission Key |
|-----------|---------------|
| View groups list | `tenant.fee-group-master.viewAny` |
| View group details | `tenant.fee-group-master.view` |
| Create group | `tenant.fee-group-master.create` |
| Update group | `tenant.fee-group-master.update` |
| Delete group | `tenant.fee-group-master.delete` |
| Restore group | `tenant.fee-group-master.restore` |
| Force delete group | `tenant.fee-group-master.forceDelete` |
| Toggle status | `tenant.fee-group-master.status` |

## 15. Flash Messages
- `'Fee Group created successfully.'` — on store
- `'Fee Group updated successfully.'` — on update
- `'Fee Group deleted successfully.'` — on destroy
- `'Fee Group restored successfully.'` — on restore
- `'Fee Group permanently deleted.'` — on forceDelete
- `'Fee Group status updated successfully.'` — on toggleStatus success
- `'Failed to update Fee Group status.'` — on toggleStatus failure

## 16. Known Issues / Gotchas
- update() performs full sync of heads — any existing mappings not in submission are deleted
- Store uses `DB::transaction` but does NOT have explicit try-catch — relies on framework exception handling
- destroy does NOT check for existing references (fee_structure_details via FK SET NULL)
- The FeeGroupHeadsJnt model does NOT use SoftDeletes (records are hard deleted in sync)
- toggleStatus API returns plain strings instead of flash() helper keys (unlike other controllers)
