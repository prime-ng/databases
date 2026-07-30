# inv_UnitOfMeasure — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Units of Measure (CRUD + Soft-Delete + Toggle + UOM Conversions)
**DB scope:** TENANT-side (`inv_units_of_measure`, `inv_uom_conversions`) · **Test style:** Browser Dusk
**Primary table:** `inv_units_of_measure` · **Module URL prefix:** `/inventory/masters?tab=uoms`
**Test file:** `inv_UnitOfMeasure_TestCas.php`
**Tab:** Units of Measure (second tab of Inventory Masters)

Controllers:
- `UomController` — CRUD + trash + toggle + Conversion CRUD
- `InvMenuController::masters()` — loads UOMs + conversions for tabbed page

Routes (`inventory.` prefix):
- `GET /inventory/masters` — tabbed page (uoms tab)
- `GET /inventory/uoms` — index (redirects to masters tab)
- `POST /inventory/uoms` — store via modal
- `GET /inventory/uoms/{uom}` — show
- `GET /inventory/uoms/{uom}/edit` — edit
- `PUT /inventory/uoms/{uom}` — update
- `DELETE /inventory/uoms/{uom}` — soft delete (guarded if stock items exist)
- `POST /inventory/uoms/{uom}/toggle-status` — AJAX toggle
- `GET /inventory/uoms/trash/view` — trashed
- `GET /inventory/uoms/{id}/restore` — restore
- `DELETE /inventory/uoms/{id}/force-delete` — force delete
- `POST /inventory/uom-conversions` — store conversion
- `PUT /inventory/uom-conversions/{conversion}` — update conversion
- `DELETE /inventory/uom-conversions/{conversion}` — AJAX destroy conversion

**DDL reference:** `inv_units_of_measure` (Layer 1), `inv_uom_conversions` (Layer 2)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_units_of_measure`: id (BIGINT PK AI), name (VARCHAR 50 NOT NULL), symbol (VARCHAR 10 NOT NULL), decimal_places (TINYINT NOT NULL DEFAULT 0, range 0-4), is_system (TINYINT 1 DEFAULT 0), is_active (TINYINT 1 DEFAULT 1), created_by (BIGINT UNSIGNED), updated_by (BIGINT UNSIGNED), created_at, updated_at, deleted_at. Index: idx_inv_uom_is_active | DDL |
| BC-DB-02 | Table `inv_uom_conversions`: id (BIGINT PK AI), from_uom_id (BIGINT UNSIGNED FK), to_uom_id (BIGINT UNSIGNED FK), conversion_factor (DECIMAL 15,6), effective_from (DATE NULL), effective_to (DATE NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. UNIQUE: uq_inv_uom_conv (from_uom_id, to_uom_id). Indexes: idx_inv_uom_conv_from, idx_inv_uom_conv_to | DDL |
| BC-DB-03 | Model `UnitOfMeasure`: table inv_units_of_measure, SoftDeletes, fillable 7 fields, casts: decimal_places→integer, is_system→boolean, is_active→boolean. Relations: stockGroups() hasMany (default_uom_id), stockItems() hasMany (uom_id), conversionsFrom()/conversionsTo() hasMany UomConversion | Model |

### BC-VAL — Validation (StoreUomRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `name` required string max:50 | FR |
| BC-VAL-02 | `symbol` required string max:10 | FR |
| BC-VAL-03 | `decimal_places` required integer min:0 max:4 | FR |

### BC-VAL-CONV — UOM Conversion Validation (StoreUomConversionRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-CONV-01 | `from_uom_id` required integer exists:inv_units_of_measure,id, unique composite (from_uom_id, to_uom_id) | FR |
| BC-VAL-CONV-02 | `to_uom_id` required integer exists:inv_units_of_measure,id, different:from_uom_id | FR |
| BC-VAL-CONV-03 | `conversion_factor` required numeric min:0.000001 | FR |
| BC-VAL-CONV-04 | `effective_from` nullable date | FR |
| BC-VAL-CONV-05 | `effective_to` nullable date, after_or_equal:effective_from | FR |
| BC-VAL-CONV-06 | Boot creating(): throws InvalidArgumentException if from_uom_id === to_uom_id | Model |

### BC-AUTH — Authorization (UomPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/trashed gate `tenant.inventory.uom.viewAny` | Policy |
| BC-AUTH-02 | create/store/Conversion store gate `tenant.inventory.uom.create` | Policy |
| BC-AUTH-03 | show gate `tenant.inventory.uom.view` | Policy |
| BC-AUTH-04 | edit/update/toggleStatus/Conversion update gate `tenant.inventory.uom.update` | Policy |
| BC-AUTH-05 | destroy/restore/forceDelete/Conversion destroy gate `tenant.inventory.uom.delete` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | UOMs tab shows UOM list (cards) + UOM Conversions section below | View |
| BC-BIZ-02 | UOM cards: name, symbol badge, decimal_places, items_count (loaded via withCount), status toggle, actions | View |
| BC-BIZ-03 | Store via modal: validates, creates with auth user, redirects to masters tab | Ctrl |
| BC-BIZ-04 | Update via edit page: validates, updates with auth user, redirects to masters tab | Ctrl |
| BC-BIZ-05 | Show: two-column layout — UOM details + tabs (Conversions from/to, Stock Items) | View |
| BC-BIZ-06 | Toggle: updates is_active to opposite, returns JSON {success, is_active, message} | Ctrl |
| BC-BIZ-07 | Delete guarded: rejects if stockItems()->exists() (redirect error) | Ctrl |
| BC-BIZ-08 | Conversions section: list of conversions with formula, from/to UOM, factor, dates, delete action | View |
| BC-BIZ-09 | Conversion store: unique composite (from_uom_id, to_uom_id), factor min 0.000001, different UOMs | Ctrl |
| BC-BIZ-10 | Conversion destroy: AJAX delete, returns JSON {status, message} | Ctrl |
| BC-BIZ-11 | Search: by name, filter by status (All/Active/Inactive) | View |
| BC-BIZ-12 | Empty state: "No Units of Measure Found", "No Conversions Found" | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Delete UOM used by stock items → blocked (redirect error) | Ctrl |
| BC-EDG-02 | Duplicate conversion (same from_uom + to_uom) → unique constraint/validation error | FR |
| BC-EDG-03 | Conversion from_uom = to_uom → different rule + boot InvalidArgumentException | FR/Model |
| BC-EDG-04 | effective_to before effective_from → after_or_equal rule | FR |
| BC-EDG-05 | decimal_places > 4 or < 0 → min/max rule | FR |

---

## 2. Test Case List

### Screen 1: UOMs Tab (GET /inventory/masters?tab=uoms)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVUOM-P10 | Positive | View | UOMs tab: card list (name, symbol badge, decimal places, items count, toggle, actions) + Conversions section below | Rendered | test_inv_uom_10 | Automated |
| TC-INVUOM-P11 | Positive | View | Search by name, filter by status (All/Active/Inactive) | Filters | test_inv_uom_11 | Automated |
| TC-INVUOM-P12 | Positive | View | Create UOM button opens modal with fields (Name, Symbol, Decimal Places) | Modal | test_inv_uom_12 | Automated |
| TC-INVUOM-P13 | Positive | View | Add Conversion button opens modal (From UOM, To UOM, Factor, Effective dates) | Modal | test_inv_uom_13 | Automated |
| TC-INVUOM-P14 | Positive | View | Conversions list: formula (1 X = N Y), from/to names, effective dates, delete button | List | test_inv_uom_14 | Automated |
| TC-INVUOM-P15 | Positive | View | Empty states for both UOMs and Conversions | Empty | test_inv_uom_15 | Automated |

### Screen 2: UOM Create (Modal) + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVUOM-P30 | Positive | View | Create modal: Name (required), Symbol (required max:10), Decimal Places (select 0-4) | Fields | test_inv_uom_30 | Automated |
| TC-INVUOM-P31 | Positive | Ctrl | Valid store: creates UOM, is_active=1 by default (hidden input), redirects with success | Created | test_inv_uom_31 | Automated |
| TC-INVUOM-N32 | Negative | Val | Missing name/symbol → required errors | Errors | test_inv_uom_32 | Automated |
| TC-INVUOM-N33 | Negative | Val | name > 50 chars → max error | Error | test_inv_uom_33 | Automated |
| TC-INVUOM-N34 | Negative | Val | symbol > 10 chars → max error | Error | test_inv_uom_34 | Automated |
| TC-INVUOM-N35 | Negative | Val | decimal_places > 4 → max rule | Error | test_inv_uom_35 | Automated |
| TC-INVUOM-N36 | Negative | Val | decimal_places < 0 → min rule | Error | test_inv_uom_36 | Automated |

### Screen 3: Show (GET /inventory/uoms/{uom})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVUOM-P50 | Positive | View | Show: left column — UOM details (name, symbol badge, decimal places, status) | Details | test_inv_uom_50 | Automated |
| TC-INVUOM-P51 | Positive | View | Right column: tabs — Conversions (from/to tables), Stock Items | Tabs | test_inv_uom_51 | Automated |
| TC-INVUOM-P52 | Positive | View | Conversions From table + Conversions To table | Tables | test_inv_uom_52 | Automated |
| TC-INVUOM-P53 | Positive | View | Stock Items tab: item name (link), SKU, stock group, type badge, status | Table | test_inv_uom_53 | Automated |

### Screen 4: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVUOM-P70 | Positive | View | Edit page: form pre-populated, Name, Symbol, Decimal Places, Status select | Pre-filled | test_inv_uom_70 | Automated |
| TC-INVUOM-P71 | Positive | Ctrl | Update changes fields, redirects with success | Updated | test_inv_uom_71 | Automated |

### Screen 5: UOM Conversions CRUD

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVUOM-P90 | Positive | Ctrl | Store conversion: valid data creates via modal, redirects with success | Created | test_inv_uom_90 | Automated |
| TC-INVUOM-P91 | Positive | Ctrl | Update conversion: changes factor, redirects with success | Updated | test_inv_uom_91 | Automated |
| TC-INVUOM-P92 | Positive | Ctrl | Destroy conversion: AJAX delete returns JSON {status, message} | Deleted | test_inv_uom_92 | Automated |
| TC-INVUOM-N93 | Negative | Val | Same from_uom + to_uom as existing → unique composite error | Error | test_inv_uom_93 | Automated |
| TC-INVUOM-N94 | Negative | Val | from_uom_id = to_uom_id → different rule + boot InvalidArgumentException | Error | test_inv_uom_94 | Automated |
| TC-INVUOM-N95 | Negative | Val | conversion_factor = 0 → min:0.000001 rule | Error | test_inv_uom_95 | Automated |
| TC-INVUOM-N96 | Negative | Val | effective_to before effective_from → after_or_equal rule | Error | test_inv_uom_96 | Automated |

### Screen 6: Toggle Status

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVUOM-P110 | Positive | Ctrl | Toggle active to inactive returns JSON {success, message, is_active:false} | JSON false | test_inv_uom_110 | Automated |
| TC-INVUOM-P111 | Positive | Ctrl | Toggle inactive to active returns JSON {success, message, is_active:true} | JSON true | test_inv_uom_111 | Automated |

### Screen 7: Delete (Guarded) + Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVUOM-P130 | Positive | Ctrl | Delete UOM with no stock items → soft-deleted, appears in trash | Deleted | test_inv_uom_130 | Automated |
| TC-INVUOM-N131 | Negative | Biz | Delete UOM used by stock items → redirect error message | Blocked | test_inv_uom_131 | Automated |
| TC-INVUOM-P132 | Positive | View | Trash page: table with Name, Symbol, Deleted At, restore/force-delete actions | Table | test_inv_uom_132 | Automated |
| TC-INVUOM-P133 | Positive | Ctrl | Restore from trash, logs 'Restored' | Restored | test_inv_uom_133 | Automated |
| TC-INVUOM-P134 | Positive | Ctrl | Force delete from trash, logs 'Deleted' | Perm deleted | test_inv_uom_134 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVUOM-P200 | Positive | Auth | UOM CRUD with correct permissions → 200 | 200 | test_inv_uom_200 | Automated |
| TC-INVUOM-P201 | Positive | Auth | Conversion CRUD with correct permissions → 200 | 200 | test_inv_uom_201 | Automated |
| TC-INVUOM-N202 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_inv_uom_202 | Automated |
| TC-INVUOM-N203 | Negative | Auth | Without create → 403 on UOM/conversion store | 403 | test_inv_uom_203 | Automated |
| TC-INVUOM-N204 | Negative | Auth | Without update → 403 on update/toggle | 403 | test_inv_uom_204 | Automated |
| TC-INVUOM-N205 | Negative | Auth | Without delete → 403 on destroy/restore/forceDelete | 403 | test_inv_uom_205 | Automated |
