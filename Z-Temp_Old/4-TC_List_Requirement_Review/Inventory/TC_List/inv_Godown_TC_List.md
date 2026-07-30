# inv_Godown — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Godowns / Storage Locations (CRUD + Soft-Delete + Toggle + Hierarchy)
**DB scope:** TENANT-side (`inv_godowns`) · **Test style:** Browser Dusk
**Primary table:** `inv_godowns` · **Module URL prefix:** `/inventory/masters?tab=godowns`
**Test file:** `inv_Godown_TestCas.php`
**Tab:** Godowns (third tab of Inventory Masters)

Controllers:
- `GodownController` — CRUD + trash + toggle + restore/forceDelete
- `InvMenuController::masters()` — loads godowns for tabbed page

Routes (`inventory.` prefix):
- `GET /inventory/masters` — tabbed page (godowns tab)
- `GET /inventory/godowns` — index (redirects to masters tab)
- `POST /inventory/godowns` — store via modal
- `GET /inventory/godowns/{godown}` — show (details + stock balances + sub-locations)
- `GET /inventory/godowns/{godown}/edit` — edit
- `PUT /inventory/godowns/{godown}` — update
- `DELETE /inventory/godowns/{godown}` — soft delete (guarded if stock on hand or sub-locations exist)
- `POST /inventory/godowns/{godown}/toggle-status` — AJAX toggle
- `GET /inventory/godowns/trash/view` — trashed
- `GET /inventory/godowns/{id}/restore` — restore
- `DELETE /inventory/godowns/{id}/force-delete` — force delete

**DDL reference:** `inv_godowns` (Layer 2 — depends on `sch_employees`)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_godowns`: id (BIGINT PK AI), name (VARCHAR 100 NOT NULL), code (VARCHAR 20 NULL UNIQUE), parent_id (BIGINT UNSIGNED NULL FK self-ref), address (VARCHAR 500 NULL), in_charge_employee_id (INT UNSIGNED NULL FK to sch_employees), is_system (TINYINT 1 DEFAULT 0), is_active (TINYINT 1 DEFAULT 1), created_by (BIGINT UNSIGNED), updated_by (BIGINT UNSIGNED), created_at, updated_at, deleted_at. Indexes: idx_inv_gdn_parent_id, idx_inv_gdn_in_charge_employee_id, idx_inv_gdn_is_active. FK: parent_id → inv_godowns.id ON DELETE SET NULL | DDL |
| BC-DB-02 | Model `Godown`: table inv_godowns, SoftDeletes, fillable 9 fields, casts: is_system→boolean, is_active→boolean. Relations: parent() BelongsTo (self), children() HasMany (self), stockBalances() HasMany, stockEntries() HasMany, stockIssues() HasMany, stockAdjustments() HasMany, goodsReceiptNotes() HasMany, inChargeEmployee() BelongsTo (User). Scope: active() | Model |
| BC-DB-03 | Seed data: 6 seeded godowns (Main Store, Science Lab Store, Sports Store, Library Store, Stationery Store, Computer Lab Store) with is_system=1 | Seeder |

### BC-VAL — Validation (StoreGodownRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `name` required string max:100 | FR |
| BC-VAL-02 | `code` nullable string max:20 unique:inv_godowns,code (ignores current on update) | FR |
| BC-VAL-03 | `parent_id` nullable integer exists:inv_godowns,id | FR |
| BC-VAL-04 | `address` nullable string max:500 | FR |
| BC-VAL-05 | `in_charge_employee_id` nullable integer (no FK constraint enforced at DB level — commented) | FR |

### BC-AUTH — Authorization (GodownPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index gate `tenant.inventory.godown.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.inventory.godown.create` | Policy |
| BC-AUTH-03 | show gate `tenant.inventory.godown.view` | Policy |
| BC-AUTH-04 | edit/update/toggleStatus gate `tenant.inventory.godown.update` | Policy |
| BC-AUTH-05 | destroy/restore/forceDelete/trashed gate `tenant.inventory.godown.delete` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Godowns tab shows godown list as cards with search and status filter | View |
| BC-BIZ-02 | Godown cards: name, code badge, parent location, address (truncated 60), status toggle, action buttons | View |
| BC-BIZ-03 | Store via modal: validates, creates via GodownService with auth user, activity log 'Created', redirects to masters tab | Ctrl/Service |
| BC-BIZ-04 | Update via edit page: validates, updates via GodownService with auth user, activity log 'Updated', redirects to masters tab | Ctrl/Service |
| BC-BIZ-05 | Show: two-column layout — left column Godown Details, right column tabs (Stock Balances, Sub-locations) | View |
| BC-BIZ-06 | Godown Details in show: name, code, parent (linked), address, in-charge (name + emp_code), status badge | View |
| BC-BIZ-07 | Stock Balances tab: table with item name (linked), SKU, current qty (formatted with UOM decimal/symbol), value/unit, total value, grand total footer | View |
| BC-BIZ-08 | Sub-locations tab: table with name (linked), code, address (truncated 60), status badge, view action | View |
| BC-BIZ-09 | Toggle: updates is_active to opposite, returns JSON {success, is_active, message} | Ctrl |
| BC-BIZ-10 | Delete guarded: rejects with DomainException if stockBalances with current_qty > 0 exists (redirect error) | Service |
| BC-BIZ-11 | Delete guarded: rejects with DomainException if children()->exists() — has sub-locations (redirect error) | Service |
| BC-BIZ-12 | Search: by name, filter by status (All/Active/Inactive) | View |
| BC-BIZ-13 | Edit page: form pre-populated, excludes self from parent_id dropdown, staff users for in-charge, status select | View |
| BC-BIZ-14 | Empty state: "No Godowns Found" with warehouse icon | View |
| BC-BIZ-15 | Create modal: hidden is_active = 1 input (default active) | View |
| BC-BIZ-16 | Pagination: appends tab=godowns to pagination links | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Delete godown with stock on hand (current_qty > 0) → blocked with DomainException message | Service |
| BC-EDG-02 | Delete godown with children (sub-locations) → blocked with DomainException message | Service |
| BC-EDG-03 | Duplicate code → unique constraint violation / validation error | FR |
| BC-EDG-04 | Self-referencing parent_id (godown as own parent) — no explicit guard, but parent dropdown excludes current on edit; store doesn't exclude self | Potential gap |
| BC-EDG-05 | Set parent_id to child godown → creates circular reference (no circular detection in service) | Potential gap |
| BC-EDG-06 | name > 100 chars → max validation error | FR |
| BC-EDG-07 | address > 500 chars → max validation error | FR |

---

## 2. Test Case List

### Screen 1: Godowns Tab (GET /inventory/masters?tab=godowns)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGOD-P10 | Positive | View | Godowns tab: card list (name, code badge, parent, address truncated, toggle, actions) | Rendered | test_inv_god_10 | Automated |
| TC-INVGOD-P11 | Positive | View | Search by name, filter by status (All/Active/Inactive) | Filters | test_inv_god_11 | Automated |
| TC-INVGOD-P12 | Positive | View | Create Godown button opens modal with all fields (Name, Code, Parent Location, Address, In-Charge) | Modal | test_inv_god_12 | Automated |
| TC-INVGOD-P13 | Positive | View | Empty state "No Godowns Found" with warehouse icon | Empty | test_inv_god_13 | Automated |
| TC-INVGOD-P14 | Positive | View | Pagination links append `tab=godowns` query param | Paginated | test_inv_god_14 | Automated |

### Screen 2: Godown Create (Modal) + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGOD-P30 | Positive | View | Create modal: Name (required), Code (optional), Parent Location (select), Address (textarea), In-Charge (select staff) | Fields | test_inv_god_30 | Automated |
| TC-INVGOD-P31 | Positive | Ctrl | Valid store: creates godown, is_active=1 by default (hidden input), redirects with success, activity logged | Created | test_inv_god_31 | Automated |
| TC-INVGOD-P32 | Positive | Ctrl | Store with parent_id: creates as sub-location under selected parent | Created | test_inv_god_32 | Automated |
| TC-INVGOD-P33 | Positive | Ctrl | Store with code: saves unique code | Created | test_inv_god_33 | Automated |
| TC-INVGOD-P34 | Positive | Ctrl | Store with in_charge_employee_id: assigns employee as in-charge | Created | test_inv_god_34 | Automated |
| TC-INVGOD-N35 | Negative | Val | Missing name → required error | Error | test_inv_god_35 | Automated |
| TC-INVGOD-N36 | Negative | Val | Name > 100 chars → max error | Error | test_inv_god_36 | Automated |
| TC-INVGOD-N37 | Negative | Val | Duplicate code → unique validation error | Error | test_inv_god_37 | Automated |
| TC-INVGOD-N38 | Negative | Val | Code > 20 chars → max error | Error | test_inv_god_38 | Automated |
| TC-INVGOD-N39 | Negative | Val | parent_id non-existent → exists validation error | Error | test_inv_god_39 | Automated |
| TC-INVGOD-N40 | Negative | Val | Address > 500 chars → max error | Error | test_inv_god_40 | Automated |

### Screen 3: Show (GET /inventory/godowns/{godown})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGOD-P50 | Positive | View | Show: left column — Godown Details (name, code, parent link, address, in-charge name+code, status badge) | Details | test_inv_god_50 | Automated |
| TC-INVGOD-P51 | Positive | View | Right column: tabs — Stock Balances (count badge), Sub-locations (count badge) | Tabs | test_inv_god_51 | Automated |
| TC-INVGOD-P52 | Positive | View | Stock Balances tab: item name (link), SKU, current qty (UOM decimal/symbol), value/unit, total value, grand total footer | Table | test_inv_god_52 | Automated |
| TC-INVGOD-P53 | Positive | View | Sub-locations tab: name (link), code badge, address (truncated 60), status badge, view action | Table | test_inv_god_53 | Automated |
| TC-INVGOD-P54 | Positive | View | Main Location (no parent): shows "Main Location (None)" with muted text | Display | test_inv_god_54 | Automated |
| TC-INVGOD-P55 | Positive | View | Parent name is linked to parent's show page | Link | test_inv_god_55 | Automated |

### Screen 4: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGOD-P70 | Positive | View | Edit page: form pre-populated, name, code, parent_id (excludes self), address, in_charge_employee_id, is_active select | Pre-filled | test_inv_god_70 | Automated |
| TC-INVGOD-P71 | Positive | Ctrl | Update changes fields, redirects with success, activity logged | Updated | test_inv_god_71 | Automated |
| TC-INVGOD-P72 | Positive | Ctrl | Update clears optional fields (code, parent_id, address, in_charge) to null | Updated | test_inv_god_72 | Automated |
| TC-INVGOD-P73 | Positive | Ctrl | Update code to new unique value, or clear to null | Updated | test_inv_god_73 | Automated |
| TC-INVGOD-N74 | Negative | Val | Update: missing name → required error | Error | test_inv_god_74 | Automated |
| TC-INVGOD-N75 | Negative | Val | Update: duplicate code (taken by another godown) → unique error | Error | test_inv_god_75 | Automated |

### Screen 5: Toggle Status

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGOD-P90 | Positive | Ctrl | Toggle active to inactive returns JSON {success, message, is_active:false} | JSON false | test_inv_god_90 | Automated |
| TC-INVGOD-P91 | Positive | Ctrl | Toggle inactive to active returns JSON {success, message, is_active:true} | JSON true | test_inv_god_91 | Automated |

### Screen 6: Delete (Guarded) + Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGOD-P110 | Positive | Ctrl | Delete godown with no stock and no children → soft-deleted, appears in trash, activity logged | Deleted | test_inv_god_110 | Automated |
| TC-INVGOD-N111 | Negative | Biz | Delete godown with stock on hand (current_qty > 0) → redirect error with DomainException message | Blocked | test_inv_god_111 | Automated |
| TC-INVGOD-N112 | Negative | Biz | Delete godown with children (sub-locations) → redirect error with DomainException message | Blocked | test_inv_god_112 | Automated |
| TC-INVGOD-P113 | Positive | View | Trash page: table with Name, Code, Deleted At, restore/force-delete actions | Table | test_inv_god_113 | Automated |
| TC-INVGOD-P114 | Positive | Ctrl | Restore from trash, logs 'Restored' | Restored | test_inv_god_114 | Automated |
| TC-INVGOD-P115 | Positive | Ctrl | Force delete from trash, logs 'Deleted' | Perm deleted | test_inv_god_115 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGOD-P200 | Positive | Auth | Godown CRUD with correct permissions → 200/redirect | 200 | test_inv_god_200 | Automated |
| TC-INVGOD-N201 | Negative | Auth | Without viewAny → 403 on tab/index | 403 | test_inv_god_201 | Automated |
| TC-INVGOD-N202 | Negative | Auth | Without create → 403 on store | 403 | test_inv_god_202 | Automated |
| TC-INVGOD-N203 | Negative | Auth | Without update → 403 on update/toggle | 403 | test_inv_god_203 | Automated |
| TC-INVGOD-N204 | Negative | Auth | Without delete → 403 on destroy/trashed/restore/forceDelete | 403 | test_inv_god_204 | Automated |
