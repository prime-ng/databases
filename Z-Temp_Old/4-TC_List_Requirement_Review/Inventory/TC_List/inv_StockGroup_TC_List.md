# inv_StockGroup — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Stock Groups (CRUD + Soft-Delete + Toggle + Protected System Groups)
**DB scope:** TENANT-side (`inv_stock_groups`) · **Test style:** Browser Dusk
**Primary table:** `inv_stock_groups` · **Module URL prefix:** `/inventory/masters?tab=stock-groups`
**Test file:** `inv_StockGroup_TestCas.php`
**Tab:** Stock Groups (first tab of Inventory Masters)

Controllers:
- `StockGroupController` — CRUD + trash + toggle
- `InvMenuController::masters()` — loads stock groups + other masters for tabbed page

Service:
- `StockGroupService` — create, update, delete (guards: stock items / children)

Routes (`inventory.` prefix):
- `GET /inventory/masters` — tabbed page (stock-groups tab default)
- `GET /inventory/stock-groups` — index (redirects to masters tab)
- `POST /inventory/stock-groups` — store via modal
- `GET /inventory/stock-groups/{stockGroup}` — show
- `GET /inventory/stock-groups/{stockGroup}/edit` — edit
- `PUT /inventory/stock-groups/{stockGroup}` — update
- `DELETE /inventory/stock-groups/{stockGroup}` — soft delete (guarded)
- `POST /inventory/stock-groups/{stockGroup}/toggle-status` — AJAX toggle
- `GET /inventory/stock-groups/trash/view` — trashed
- `GET /inventory/stock-groups/{id}/restore` — restore
- `DELETE /inventory/stock-groups/{id}/force-delete` — force delete

**DDL reference:** `inv_stock_groups` (Layer 2, Inventory DDL)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_stock_groups`: id (BIGINT PK AI), name (VARCHAR 100 NOT NULL), code (VARCHAR 20 NULL UNIQUE), alias (VARCHAR 100 NULL), parent_id (BIGINT UNSIGNED NULL self-ref FK → inv_stock_groups.id ON DELETE SET NULL), default_uom_id (BIGINT UNSIGNED NULL FK → inv_units_of_measure.id ON DELETE SET NULL), sequence (INT NOT NULL DEFAULT 0), is_system (TINYINT 1 DEFAULT 0), is_active (TINYINT 1 DEFAULT 1), created_by (BIGINT UNSIGNED), updated_by (BIGINT UNSIGNED), created_at, updated_at, deleted_at. Indexes: uq_inv_sg_code (code), idx_inv_sg_parent_id, idx_inv_sg_default_uom_id, idx_inv_sg_is_active | DDL |
| BC-DB-02 | Model `StockGroup`: table inv_stock_groups, SoftDeletes, fillable 10 fields, casts: sequence→integer, is_system→boolean, is_active→boolean. Relations: parent() belongsTo self, children() hasMany self, defaultUom() belongsTo UnitOfMeasure, stockItems() hasMany StockItem | Model |

### BC-VAL — Validation (StoreStockGroupRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `name` required string max:100 | FR |
| BC-VAL-02 | `code` nullable string max:20, unique:inv_stock_groups,code (ignores own ID on update) | FR |
| BC-VAL-03 | `alias` nullable string max:100 | FR |
| BC-VAL-04 | `parent_id` nullable integer exists:inv_stock_groups,id | FR |
| BC-VAL-05 | `default_uom_id` nullable integer exists:inv_units_of_measure,id | FR |
| BC-VAL-06 | `sequence` nullable integer min:0 | FR |

### BC-AUTH — Authorization (StockGroupPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index gate `tenant.inventory.stock-group.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.inventory.stock-group.create` | Policy |
| BC-AUTH-03 | show gate `tenant.inventory.stock-group.view` | Policy |
| BC-AUTH-04 | edit/update/toggleStatus gate `tenant.inventory.stock-group.update` | Policy |
| BC-AUTH-05 | destroy/restore/forceDelete gate `tenant.inventory.stock-group.delete` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Masters page loads 4 tabs: Stock Groups, Units of Measure, Godowns, Asset Categories | MenuCtrl |
| BC-BIZ-02 | Stock Groups list: paginated 20, loads parent + defaultUom relations | MenuCtrl |
| BC-BIZ-03 | List displayed as cards with name, code badge, parent, default UOM, sequence, status toggle, actions | View |
| BC-BIZ-04 | Store via modal: creates group via StockGroupService::create() with auth user, logs activity | Service |
| BC-BIZ-05 | Update via edit page: updates via StockGroupService::update(), logs activity | Service |
| BC-BIZ-06 | Show page: two-column layout — group details + tabs (Sub-Groups, Stock Items) | View |
| BC-BIZ-07 | Toggle: updates is_active to opposite, returns JSON {success, message, is_active} | Ctrl |
| BC-BIZ-08 | Delete guarded: rejects if stockItems()->exists() (throws DomainException → redirect error) | Service |
| BC-BIZ-09 | Delete guarded: rejects if children()->exists() (has sub-groups, throws DomainException → redirect error) | Service |
| BC-BIZ-10 | System groups (is_system=1) are seeded and cannot be deleted; DDL seeds 10 groups | DDL |
| BC-BIZ-11 | Search: text search by name and code | View |
| BC-BIZ-12 | Filter: status filter (All/Active/Inactive) | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Delete group with stock items → DomainException (redirect error) | Service |
| BC-EDG-02 | Delete group with child sub-groups → DomainException (redirect error) | Service |
| BC-EDG-03 | Duplicate code → unique constraint/validation error | FR |
| BC-EDG-04 | Self-referencing parent_id → allowed (parent_id can reference own id? actually no, it would be circular; the request doesn't guard against this) | — |
| BC-EDG-05 | is_system=1 groups (seeded) are undeletable via the same guards (has items/children) but seeded with no items/children, so could theoretically be deleted if those guards pass — however, is_system flag exists for future enforcement | DDL |

---

## 2. Test Case List

### Screen 1: Stock Groups Tab (GET /inventory/masters?tab=stock-groups)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSG-P10 | Positive | View | Masters page renders 4 tabs: Stock Groups, Units of Measure, Godowns, Asset Categories | Tabs visible | test_inv_sg_10 | Automated |
| TC-INVSG-P11 | Positive | View | Stock Groups tab: card list with name, code badge, parent, default UOM, sequence, status toggle, actions | Rendered | test_inv_sg_11 | Automated |
| TC-INVSG-P12 | Positive | View | Search by name/code, filter by status (All/Active/Inactive) | Filters | test_inv_sg_12 | Automated |
| TC-INVSG-P13 | Positive | View | Create button opens modal with form | Modal | test_inv_sg_13 | Automated |
| TC-INVSG-P14 | Positive | View | Empty state "No Stock Groups Found" | Empty | test_inv_sg_14 | Automated |

### Screen 2: Create (Modal) + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSG-P30 | Positive | View | Create modal: Name (required), Code, Alias, Parent Group (select), Default UOM (select), Sequence | Fields | test_inv_sg_30 | Automated |
| TC-INVSG-P31 | Positive | Ctrl | Valid store: creates group, logs activity, redirects with success | Created | test_inv_sg_31 | Automated |
| TC-INVSG-N32 | Negative | Val | Missing name → required error | Error | test_inv_sg_32 | Automated |
| TC-INVSG-N33 | Negative | Val | name > 100 chars → max error | Error | test_inv_sg_33 | Automated |
| TC-INVSG-N34 | Negative | Val | Duplicate code → unique error | Error | test_inv_sg_34 | Automated |
| TC-INVSG-N35 | Negative | Val | code > 20 chars → max error | Error | test_inv_sg_35 | Automated |
| TC-INVSG-N36 | Negative | Val | Invalid parent_id → exists:inv_stock_groups rejects | Error | test_inv_sg_36 | Automated |
| TC-INVSG-N37 | Negative | Val | Invalid default_uom_id → exists:inv_units_of_measure rejects | Error | test_inv_sg_37 | Automated |
| TC-INVSG-N38 | Negative | Val | Negative sequence → min:0 rule | Error | test_inv_sg_38 | Automated |

### Screen 3: Show (GET /inventory/stock-groups/{stockGroup})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSG-P50 | Positive | View | Show page: left column — group details (name, code, alias, parent, default UOM, sequence, status) | Details | test_inv_sg_50 | Automated |
| TC-INVSG-P51 | Positive | View | Right column: tabs — Sub-Groups table, Stock Items table with links | Tabs | test_inv_sg_51 | Automated |
| TC-INVSG-P52 | Positive | View | Sub-Groups tab: Name (link), Code, Alias, Sequence, Status, Actions | Table | test_inv_sg_52 | Automated |
| TC-INVSG-P53 | Positive | View | Stock Items tab: Item Name (link), SKU, Type badge, UOM, Status, Actions | Table | test_inv_sg_53 | Automated |

### Screen 4: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSG-P70 | Positive | View | Edit page: form pre-populated, parent dropdown excludes self | Pre-filled | test_inv_sg_70 | Automated |
| TC-INVSG-P71 | Positive | Ctrl | Update changes fields, logs activity | Updated | test_inv_sg_71 | Automated |
| TC-INVSG-N72 | Negative | Val | Update with duplicate code (other group) → unique error | Error | test_inv_sg_72 | Automated |
| TC-INVSG-P73 | Positive | Val | Update with same code (own group) → allowed (unique ignore) | Allowed | test_inv_sg_73 | Automated |

### Screen 5: Toggle Status

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSG-P90 | Positive | Ctrl | Toggle active to inactive returns JSON {success,message,is_active:false} | JSON false | test_inv_sg_90 | Automated |
| TC-INVSG-P91 | Positive | Ctrl | Toggle inactive to active returns JSON {success,message,is_active:true} | JSON true | test_inv_sg_91 | Automated |

### Screen 6: Delete (Guarded)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSG-P110 | Positive | Ctrl | Delete group with no items/children → soft-deleted, appears in trash | Deleted | test_inv_sg_110 | Automated |
| TC-INVSG-N111 | Negative | Biz | Delete group with stock items → DomainException, redirect error | Blocked | test_inv_sg_111 | Automated |
| TC-INVSG-N112 | Negative | Biz | Delete group with child sub-groups → DomainException, redirect error | Blocked | test_inv_sg_112 | Automated |

### Screen 7: Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSG-P130 | Positive | View | Trash page: table of deleted records with Deleted At, restore/force-delete actions | Table | test_inv_sg_130 | Automated |
| TC-INVSG-P131 | Positive | Ctrl | Restore from trash, logs 'Restored' | Restored | test_inv_sg_131 | Automated |
| TC-INVSG-P132 | Positive | Ctrl | Force delete from trash, logs 'Deleted' | Perm deleted | test_inv_sg_132 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSG-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_inv_sg_200 | Automated |
| TC-INVSG-N201 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_inv_sg_201 | Automated |
| TC-INVSG-N202 | Negative | Auth | Without create → 403 on store | 403 | test_inv_sg_202 | Automated |
| TC-INVSG-N203 | Negative | Auth | Without update → 403 on update/toggle | 403 | test_inv_sg_203 | Automated |
| TC-INVSG-N204 | Negative | Auth | Without delete → 403 on destroy/restore/forceDelete | 403 | test_inv_sg_204 | Automated |
