# inv_AssetCategory — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Asset Categories (CRUD + Soft-Delete + Toggle)
**DB scope:** TENANT-side (`inv_asset_categories`) · **Test style:** Browser Dusk
**Primary table:** `inv_asset_categories` · **Module URL prefix:** `/inventory/masters?tab=asset-categories`
**Test file:** `inv_AssetCategory_TestCas.php`
**Tab:** Asset Categories (fourth tab of Inventory Masters)

Controllers:
- `AssetCategoryController` — CRUD + trash + toggle
- `InvMenuController::masters()` — loads asset categories for tabbed page

Service:
- `AssetCategoryService` — create, update, delete

Routes (`inventory.` prefix):
- `GET /inventory/masters` — tabbed page (asset-categories tab)
- `GET /inventory/asset-categories` — index (redirects to masters tab)
- `POST /inventory/asset-categories` — store via modal
- `GET /inventory/asset-categories/{assetCategory}` — show
- `GET /inventory/asset-categories/{assetCategory}/edit` — edit
- `PUT /inventory/asset-categories/{assetCategory}` — update
- `DELETE /inventory/asset-categories/{assetCategory}` — soft delete
- `POST /inventory/asset-categories/{assetCategory}/toggle-status` — AJAX toggle
- `GET /inventory/asset-categories/trash/view` — trashed
- `GET /inventory/asset-categories/{id}/restore` — restore
- `DELETE /inventory/asset-categories/{id}/force-delete` — force delete

**DDL reference:** `inv_asset_categories` (Layer 2, Inventory DDL)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_asset_categories`: id (BIGINT PK AI), name (VARCHAR 100 NOT NULL), code (VARCHAR 20 NULL), useful_life_years (DECIMAL 5,1 NULL), depreciation_rate (DECIMAL 5,2 NULL), is_active (TINYINT 1 DEFAULT 1), created_by (BIGINT UNSIGNED), updated_by (BIGINT UNSIGNED), created_at, updated_at, deleted_at. Indexes: idx_inv_ac_is_active | DDL |
| BC-DB-02 | Model `AssetCategory`: table inv_asset_categories, SoftDeletes, fillable 6 fields, casts: useful_life_years→decimal:5:1, depreciation_rate→decimal:5:2, is_active→boolean. Relations: assets() hasMany Asset | Model |

### BC-VAL — Validation (StoreAssetCategoryRequest / UpdateAssetCategoryRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `name` required string max:100 | FR |
| BC-VAL-02 | `code` nullable string max:20 | FR |
| BC-VAL-03 | `useful_life_years` nullable numeric min:0 | FR |
| BC-VAL-04 | `depreciation_rate` nullable numeric min:0 max:100 | FR |
| BC-VAL-05 | `is_active` boolean (default 1 on create, hidden field) | FR |

### BC-AUTH — Authorization (AssetCategoryPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index gate `tenant.inventory.asset-category.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.inventory.asset-category.create` | Policy |
| BC-AUTH-03 | show gate `tenant.inventory.asset-category.view` | Policy |
| BC-AUTH-04 | edit/update/toggleStatus gate `tenant.inventory.asset-category.update` | Policy |
| BC-AUTH-05 | destroy/restore/forceDelete gate `tenant.inventory.asset-category.delete` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Masters page loads 4 tabs: Stock Groups, Units of Measure, Godowns, Asset Categories | MenuCtrl |
| BC-BIZ-02 | Asset Categories list: paginated 20, name, code badge, useful life, depreciation rate, assets count badge, status toggle, actions | View |
| BC-BIZ-03 | Store via modal: creates via AssetCategoryService::create() with auth user, logs activity | Service |
| BC-BIZ-04 | Update via edit page: updates via AssetCategoryService::update(), logs activity | Service |
| BC-BIZ-05 | Toggle: updates is_active to opposite, returns JSON {success, message, is_active} | Ctrl |
| BC-BIZ-06 | Search: text search by name | View |
| BC-BIZ-07 | Filter: status filter (All/Active/Inactive) | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | name > 100 chars → max validation error | FR |
| BC-EDG-02 | code > 20 chars → max validation error | FR |
| BC-EDG-03 | depreciation_rate > 100 → max:100 validation error | FR |
| BC-EDG-04 | depreciation_rate negative → min:0 validation error | FR |
| BC-EDG-05 | useful_life_years negative → min:0 validation error | FR |

---

## 2. Test Case List

### Screen 1: Asset Categories Tab (GET /inventory/masters?tab=asset-categories)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAC-P10 | Positive | View | Masters page renders Asset Categories tab with card list | Tab visible | test_inv_ac_10 | Automated |
| TC-INVAC-P11 | Positive | View | Card shows name, code badge, useful life, depreciation rate, assets count, status toggle, actions | Rendered | test_inv_ac_11 | Automated |
| TC-INVAC-P12 | Positive | View | Search by name, filter by status (All/Active/Inactive) | Filters | test_inv_ac_12 | Automated |
| TC-INVAC-P13 | Positive | View | Create button opens modal with form | Modal | test_inv_ac_13 | Automated |
| TC-INVAC-P14 | Positive | View | Empty state "No Asset Categories Found" | Empty | test_inv_ac_14 | Automated |

### Screen 2: Create (Modal) + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAC-P30 | Positive | View | Create modal: Name (required), Code, Useful Life, Depreciation Rate | Fields | test_inv_ac_30 | Automated |
| TC-INVAC-P31 | Positive | Ctrl | Valid store (all fields): creates category, logs activity, redirects with success | Created | test_inv_ac_31 | Automated |
| TC-INVAC-P32 | Positive | Ctrl | Valid store (name only): creates category with null optionals | Created | test_inv_ac_32 | Automated |
| TC-INVAC-N33 | Negative | Val | Missing name → required error | Error | test_inv_ac_33 | Automated |
| TC-INVAC-N34 | Negative | Val | name > 100 chars → max error | Error | test_inv_ac_34 | Automated |
| TC-INVAC-N35 | Negative | Val | code > 20 chars → max error | Error | test_inv_ac_35 | Automated |
| TC-INVAC-N36 | Negative | Val | depreciation_rate > 100 → max error | Error | test_inv_ac_36 | Automated |
| TC-INVAC-N37 | Negative | Val | depreciation_rate negative → min error | Error | test_inv_ac_37 | Automated |
| TC-INVAC-N38 | Negative | Val | useful_life_years negative → min error | Error | test_inv_ac_38 | Automated |

### Screen 3: Toggle Status

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAC-P50 | Positive | Ctrl | Toggle active to inactive returns JSON {success,message,is_active:false} | JSON false | test_inv_ac_50 | Automated |
| TC-INVAC-P51 | Positive | Ctrl | Toggle inactive to active returns JSON {success,message,is_active:true} | JSON true | test_inv_ac_51 | Automated |

### Screen 4: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAC-P70 | Positive | View | Edit page: form pre-populated with existing data | Pre-filled | test_inv_ac_70 | Automated |
| TC-INVAC-P71 | Positive | Ctrl | Update changes fields, logs activity | Updated | test_inv_ac_71 | Automated |

### Screen 5: Delete + Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAC-P90 | Positive | Ctrl | Delete category → soft-deleted, appears in trash | Deleted | test_inv_ac_90 | Automated |
| TC-INVAC-P91 | Positive | View | Trash page: table of deleted records with restore/force-delete actions | Table | test_inv_ac_91 | Automated |
| TC-INVAC-P92 | Positive | Ctrl | Restore from trash, logs 'Restored' | Restored | test_inv_ac_92 | Automated |
| TC-INVAC-P93 | Positive | Ctrl | Force delete from trash, logs 'Deleted' | Perm deleted | test_inv_ac_93 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAC-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_inv_ac_200 | Automated |
| TC-INVAC-N201 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_inv_ac_201 | Automated |
| TC-INVAC-N202 | Negative | Auth | Without create → 403 on store | 403 | test_inv_ac_202 | Automated |
| TC-INVAC-N203 | Negative | Auth | Without update → 403 on update/toggle | 403 | test_inv_ac_203 | Automated |
| TC-INVAC-N204 | Negative | Auth | Without delete → 403 on destroy/restore/forceDelete | 403 | test_inv_ac_204 | Automated |
