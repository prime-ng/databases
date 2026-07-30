# vnd_Vendor_Item_TcList

## Module: Vendor → Item Management → Item CRUD

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Vendor (VND) |
| Tab Group | Vendor Dashboard → Items Tab |
| Features | Item List, Create/Edit/View/Delete/Restore/Force-Delete, Toggle Status, Item Photo Upload via Media Library, Activity Logging |
| URL(s) | `/vendor-item`, `/vendor-item/create`, `/vendor-item/{vendor-item}/edit`, `/vendor-item/{vendor-item}`, `/vendor-item/trash/view`, `/vendor-item/{id}/restore`, `/vendor-item/{id}/force-delete`, `/vendor-item/{id}/toggle-status` |
| Controller | `Modules\Vendor\Http\Controllers\VndItemController` |
| Model(s) | `VndItem` |
| Validation | `VndItemRequest` + Controller (12 rules — 11 in FormRequest + 1 file validation in controller) |
| Permission Gates | `tenant.vendor-item.viewAny`, `tenant.vendor-item.view`, `tenant.vendor-item.create`, `tenant.vendor-item.update`, `tenant.vendor-item.delete`, `tenant.vendor-item.restore`, `tenant.vendor-item.forceDelete` |
| Soft Deletes | Yes — VndItem model uses `SoftDeletes` trait |
| Events | `activityLog()` on store, update, destroy, restore, forceDelete, toggleStatus |
| Media Handling | Spatie Media Library — `item_photo` collection (singleFile), conversions (small 150×150, medium 400×400) |

---

## 2. Pre-conditions

- Required permissions: `tenant.vendor-item.viewAny`, `tenant.vendor-item.create`, `tenant.vendor-item.update`, `tenant.vendor-item.view`, `tenant.vendor-item.delete`, `tenant.vendor-item.restore`, `tenant.vendor-item.forceDelete`
- At least one active record in `sys_dropdown_table` for `category_id` reference (item categories)
- At least one active record in `sys_dropdown_table` for `unit_id` reference (units of measurement)
- For search/filter tests: at least one item record with populated fields
- For item_photo tests: Spatie Media Library properly configured with `item_photo` collection
- For toggle-status tests: at least one active and one inactive item record
- For trash/restore tests: at least one soft-deleted item record
- For deactivation-warning tests: at least one active agreement item referencing the item

---

## 3. Default Data Load

### 3.1 Filter Data for Items Tab

The `vendorItemsQuery()` method (in VendorController) returns:
- `vendorItems` — Paginated VndItem records
- Search: item_name, item_code, hsn_sac_code
- Status: is_active filter

### 3.2 Test Data Setup Requirements

- Create 2+ category dropdown records in `sys_dropdown_table` (e.g. "Electronics", "Stationery")
- Create 2+ unit dropdown records in `sys_dropdown_table` (e.g. "Pieces", "Hours", "Months")
- Populate 5+ VndItem records with varied item_type (SERVICE/PRODUCT), item_nature (CONSUMABLE/ASSET/SERVICE/NA), and is_active status
- Create at least one VndAgreementItem record linking to a VndItem for deactivation-warning tests

---

## 4. BC-DB — Database Schema

### 4.1 `vnd_items` — Primary Item Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| item_code | VARCHAR(50) | YES | NULL | Unique item code |
| item_name | VARCHAR(100) | NOT NULL | — | Item name |
| item_type | ENUM('SERVICE','PRODUCT') | NOT NULL | — | Type classification |
| item_nature | ENUM('CONSUMABLE','ASSET','SERVICE','NA') | NOT NULL | 'NA' | Nature classification |
| category_id | INT UNSIGNED | NOT NULL | — | FK → sys_dropdown_table(id) RESTRICT |
| unit_id | INT UNSIGNED | NOT NULL | — | FK → sys_dropdown_table(id) RESTRICT |
| hsn_sac_code | VARCHAR(20) | YES | NULL | HSN/SAC code for taxation |
| default_price | DECIMAL(12,2) | YES | 0.00 | Default selling price |
| reorder_level | DECIMAL(12,2) | YES | 0.00 | Reorder threshold |
| item_photo_uploaded | TINYINT(1) | YES | 0 | Flag indicating photo presence |
| description | TEXT | YES | NULL | Item description |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| is_deleted | TINYINT(1) | YES | 0 | Deleted flag (legacy — SoftDeletes also used) |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_vnd_items_code` (`item_code`)
- INDEX `idx_vnd_items_type` (`item_type`)

---

## 5. BC-VAL — Validation Rules

### 5.1 VndItemRequest Validation

| Field | Rules | Error Message |
|-------|-------|---------------|
| item_code | nullable, string, max:50, unique:vnd_items (ignore $itemId, whereNull deleted_at) | "The item code has already been taken." (unique) |
| item_name | required, string, max:100 | "The item name field is required." |
| item_type | required, in:SERVICE,PRODUCT | "The item type field is required." |
| item_nature | required, in:CONSUMABLE,ASSET,SERVICE,NA | "The item nature field is required." |
| category_id | required, integer, exists:sys_dropdown_table,id | "The category id field is required." |
| unit_id | required, integer, exists:sys_dropdown_table,id | "The unit id field is required." |
| default_price | nullable, numeric, min:0 | — |
| reorder_level | nullable, numeric, min:0 | — |
| hsn_sac_code | nullable, string, max:20 | — |
| is_active | nullable, boolean | "The is active field must be true or false." |
| description | nullable, string | — |
| item_photo | Controller-level: `$request->hasFile('item_photo')` check, Spatie Media Library validates file type | Invalid file rejected by Media Library |

**prepareForValidation:** `is_active` is converted from checkbox to boolean via `$this->boolean('is_active')`

**Unique Rule On Update:** Uses `Rule::unique('vnd_items', 'item_code')->ignore($itemId)->whereNull('deleted_at')` to exclude soft-deleted records and the current record

**Authorization:** `authorize()` method returns `true` (no Gate check in FormRequest — defence delegated to controller)

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method(s) | Model Policy |
|----------------|---------------------|-------------|
| tenant.vendor-item.viewAny | index() | VndItemPolicy@viewAny |
| tenant.vendor-item.view | show() | VndItemPolicy@view |
| tenant.vendor-item.create | create(), store() | VndItemPolicy@create |
| tenant.vendor-item.update | edit(), update(), toggleStatus() | VndItemPolicy@update |
| tenant.vendor-item.delete | destroy() | VndItemPolicy@delete |
| tenant.vendor-item.restore | trashed(), restore() | VndItemPolicy@restore |
| tenant.vendor-item.forceDelete | forceDelete() | VndItemPolicy@forceDelete |

**index() Gate Behaviour:** Uses `Gate::authorize('tenant.vendor-item.viewAny')` — single permission required

**Blade @can directives (expected in views):**
- `@can('tenant.vendor-item.viewAny')` — List access
- `@can('tenant.vendor-item.create')` — Create button
- `@can('tenant.vendor-item.update')` — Edit and Toggle Status actions
- `@can('tenant.vendor-item.view')` — View action button
- `@can('tenant.vendor-item.delete')` — Delete action button

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | Item List Pagination | index() returns paginated item list on vendor dashboard Items tab (10 per page) |
| BC-BIZ-02 | Search Across Item Fields | index() searches item_name and item_code via `like` with wildcards |
| BC-BIZ-03 | Item Photo Upload | store() handles `item_photo` via Spatie Media Library — adds to `item_photo` collection |
| BC-BIZ-04 | Item Photo Replacement | update() clears existing `item_photo` collection and re-uploads if a new file is provided |
| BC-BIZ-05 | Change Tracking on Update | update() captures changes via `$item->getChanges()` and logs old/new values before redirect |
| BC-BIZ-06 | Deactivate Before Soft-Delete | destroy() manually sets `is_active=false` before calling `$item->delete()` — redundant with SoftDeletes (Known Issue) |
| BC-BIZ-07 | Restore with Reactivation | restore() calls `restore()` and sets `is_active=true` |
| BC-BIZ-08 | Activity Log All Operations | activityLog() called on store, update, destroy, restore, forceDelete, toggleStatus |
| BC-BIZ-09 | Toggle Status via AJAX | toggleStatus() validates is_active as required|boolean, returns JSON success/error response |
| BC-BIZ-10 | Force Delete with Media Cleanup | forceDelete() uses `withTrashed()->findOrFail()`, calls `clearMediaCollection('item_photo')`, then `forceDelete` |
| BC-BIZ-11 | Unique Item Code (Soft-Delete Aware) | Validation ignores soft-deleted records and the current record on update |
| BC-BIZ-12 | Category/Unit FK Restrict | category_id and unit_id FK → sys_dropdown_table(id) with RESTRICT — cannot delete referenced dropdown if items exist |
| BC-BIZ-13 | Active Scope | Model defines `scopeActive()` — where is_active = true |
| BC-BIZ-14 | Item Deactivation Warning (FRD Rule 1) | Business rule requires checking active agreement items before deactivation — **NOT IMPLEMENTED** in code (Known Issue) |
| BC-BIZ-15 | Item Photo Helpers | Model provides `hasPhoto()` (boolean) and `photoUrl()` (URL string) helper methods |
| BC-BIZ-16 | Redirect After Save | All store/update operations redirect to `vendor.vendor.index` (Vendor Dashboard), not `vendor-item.index` — unexpected UX (Known Issue) |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_vnd_item_category | vnd_items.category_id | sys_dropdown_table.id | RESTRICT |
| fk_vnd_item_unit | vnd_items.unit_id | sys_dropdown_table.id | RESTRICT |

---

## 9. Test Case Summary

### 9.1 Item CRUD — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VND-ITEM-P01 | Item CRUD | Positive | Item list loads with search | 4 |
| TC-VND-ITEM-P02 | Item CRUD | Positive | Create item — all required fields (PRODUCT, CONSUMABLE) | 6 |
| TC-VND-ITEM-P03 | Item CRUD | Positive | Create item — SERVICE type with SERVICE nature | 6 |
| TC-VND-ITEM-P04 | Item CRUD | Positive | Create item — all optional fields (item_code, HSN, price, reorder, photo, description) | 7 |
| TC-VND-ITEM-P05 | Item CRUD | Positive | Create item — item_photo upload via media library | 5 |
| TC-VND-ITEM-P06 | Item CRUD | Positive | View item detail with relations (category, unit) | 3 |
| TC-VND-ITEM-P07 | Item CRUD | Positive | Edit item — update item_name, item_type | 5 |
| TC-VND-ITEM-P08 | Item CRUD | Positive | Edit item — change item_photo (clear old, upload new) | 5 |
| TC-VND-ITEM-P09 | Item CRUD | Positive | Edit item — change tracking logs old/new values | 4 |
| TC-VND-ITEM-P10 | Item CRUD | Positive | Toggle status — active to inactive | 4 |
| TC-VND-ITEM-P11 | Item CRUD | Positive | Toggle status — inactive to active | 4 |
| TC-VND-ITEM-P12 | Item CRUD | Positive | Soft-delete item | 4 |
| TC-VND-ITEM-P13 | Item CRUD | Positive | Restore item from trash (is_active restored to 1) | 4 |
| TC-VND-ITEM-P14 | Item CRUD | Positive | Force-delete item (permanent with media cleanup) | 4 |
| TC-VND-ITEM-P15 | Item CRUD | Positive | Search items — by item_name | 3 |
| TC-VND-ITEM-P16 | Item CRUD | Positive | Search items — by item_code | 3 |
| TC-VND-ITEM-P17 | Item CRUD | Positive | Filter items — by status (active/inactive) | 3 |
| TC-VND-ITEM-P18 | Item CRUD | Positive | hasPhoto() and photoUrl() helper methods return correct values | 3 |
| TC-VND-ITEM-P19 | Item CRUD | Positive | Media conversions (small 150×150, medium 400×400) generated on upload | 4 |
| TC-VND-ITEM-P20 | Item CRUD | Positive | Activity log created on item store | 3 |
| TC-VND-ITEM-P21 | Item CRUD | Positive | Activity log created on item update | 3 |
| TC-VND-ITEM-P22 | Item CRUD | Positive | Activity log created on item soft-delete | 3 |
| TC-VND-ITEM-P23 | Item CRUD | Positive | Activity log created on item restore | 3 |
| TC-VND-ITEM-P24 | Item CRUD | Positive | Activity log created on item force-delete | 3 |
| TC-VND-ITEM-P25 | Item CRUD | Positive | Activity log created on item toggle-status | 3 |
| TC-VND-ITEM-P26 | Item CRUD | Positive | addMediaFromRequest('item_photo') stores photo to item_photo collection | 4 |
| TC-VND-ITEM-P27 | Item CRUD | Positive | singleFile() replaces old photo when new one uploaded | 4 |
| TC-VND-ITEM-P28 | Item CRUD | Positive | clearMediaCollection('item_photo') on update before adding new photo | 4 |
| TC-VND-ITEM-P29 | Item CRUD | Positive | hasPhoto() returns true/false based on media existence in item_photo collection | 4 |
| TC-VND-ITEM-P30 | Item CRUD | Positive | photoUrl() returns URL when photo exists, null when no photo; conversion URLs via 'small'/'medium' | 5 |
| TC-VND-ITEM-P31 | Item CRUD | Positive | active() scope filters is_active = true | 3 |
| TC-VND-ITEM-P32 | Item CRUD | Positive | item belongsTo category (Dropdown) and unit (Dropdown) | 3 |
| TC-VND-ITEM-P33 | Item CRUD | Positive | item hasMany agreementItems (VndAgreementItem) | 3 |

### 9.2 Item CRUD — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VND-ITEM-N01 | Item CRUD | Negative | Create — missing item_name | 2 |
| TC-VND-ITEM-N02 | Item CRUD | Negative | Create — item_name exceeds 100 chars | 2 |
| TC-VND-ITEM-N03 | Item CRUD | Negative | Create — missing item_type | 2 |
| TC-VND-ITEM-N04 | Item CRUD | Negative | Create — invalid item_type (not SERVICE or PRODUCT) | 2 |
| TC-VND-ITEM-N05 | Item CRUD | Negative | Create — missing item_nature | 2 |
| TC-VND-ITEM-N06 | Item CRUD | Negative | Create — invalid item_nature (not in enum list) | 2 |
| TC-VND-ITEM-N07 | Item CRUD | Negative | Create — missing category_id | 2 |
| TC-VND-ITEM-N08 | Item CRUD | Negative | Create — category_id non-existent (invalid FK) | 2 |
| TC-VND-ITEM-N09 | Item CRUD | Negative | Create — category_id non-integer (string) | 2 |
| TC-VND-ITEM-N10 | Item CRUD | Negative | Create — missing unit_id | 2 |
| TC-VND-ITEM-N11 | Item CRUD | Negative | Create — unit_id non-existent (invalid FK) | 2 |
| TC-VND-ITEM-N12 | Item CRUD | Negative | Create — unit_id non-integer (string) | 2 |
| TC-VND-ITEM-N13 | Item CRUD | Negative | Create — item_code exceeds 50 chars | 2 |
| TC-VND-ITEM-N14 | Item CRUD | Negative | Create — duplicate item_code (existing active) | 2 |
| TC-VND-ITEM-N15 | Item CRUD | Negative | Create — default_price negative value | 2 |
| TC-VND-ITEM-N16 | Item CRUD | Negative | Create — reorder_level negative value | 2 |
| TC-VND-ITEM-N17 | Item CRUD | Negative | Create — hsn_sac_code exceeds 20 chars | 2 |
| TC-VND-ITEM-N18 | Item CRUD | Negative | Create — default_price non-numeric (string) | 2 |
| TC-VND-ITEM-N19 | Item CRUD | Negative | Update — duplicate item_code (existing different item) | 3 |
| TC-VND-ITEM-N20 | Item CRUD | Negative | Update — item_code changed to soft-deleted item's code (should succeed) | 3 |
| TC-VND-ITEM-N21 | Item CRUD | Negative | Toggle status — missing is_active parameter | 2 |
| TC-VND-ITEM-N22 | Item CRUD | Negative | Toggle status — non-boolean is_active value | 2 |
| TC-VND-ITEM-N23 | Item CRUD | Negative | Toggle status — non-existent item ID | 2 |
| TC-VND-ITEM-N24 | Item CRUD | Negative | Force delete — non-existent item ID | 2 |
| TC-VND-ITEM-N25 | Item CRUD | Negative | Restore — non-existent item ID | 2 |
| TC-VND-ITEM-N26 | Item CRUD | Negative | Permission — index without tenant.vendor-item.viewAny | 2 |
| TC-VND-ITEM-N27 | Item CRUD | Negative | Permission — create without tenant.vendor-item.create | 2 |
| TC-VND-ITEM-N28 | Item CRUD | Negative | Permission — store without tenant.vendor-item.create | 2 |
| TC-VND-ITEM-N29 | Item CRUD | Negative | Permission — edit without tenant.vendor-item.update | 2 |
| TC-VND-ITEM-N30 | Item CRUD | Negative | Permission — update without tenant.vendor-item.update | 2 |
| TC-VND-ITEM-N31 | Item CRUD | Negative | Permission — view show without tenant.vendor-item.view | 2 |
| TC-VND-ITEM-N32 | Item CRUD | Negative | Permission — destroy without tenant.vendor-item.delete | 2 |
| TC-VND-ITEM-N33 | Item CRUD | Negative | Permission — trashed without tenant.vendor-item.restore | 2 |
| TC-VND-ITEM-N34 | Item CRUD | Negative | Permission — restore without tenant.vendor-item.restore | 2 |
| TC-VND-ITEM-N35 | Item CRUD | Negative | Permission — forceDelete without tenant.vendor-item.forceDelete | 2 |
| TC-VND-ITEM-N36 | Item CRUD | Negative | Permission — toggleStatus without tenant.vendor-item.update | 2 |
| TC-VND-ITEM-N37 | Item CRUD | Negative | Create — is_active non-boolean string value | 2 |
| TC-VND-ITEM-N38 | Item CRUD | Negative | Create — item_name whitespace-only string (potential data quality) | 2 |
| TC-VND-ITEM-N39 | Item CRUD | Negative | Upload — invalid file type for item_photo (non-image) | 3 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-ITEM-CR01 | Code Review | Review | index() — Gate + search (item_name, item_code) + latest() + paginate(10) | 4 |
| TC-ITEM-CR02 | Code Review | Review | store() — Gate + create + media upload + activityLog + flash | 5 |
| TC-ITEM-CR03 | Code Review | Review | update() — change tracking with getChanges + media re-upload logic | 6 |
| TC-ITEM-CR04 | Code Review | Review | destroy() — manual is_active=false before delete (redundant) | 4 |
| TC-ITEM-CR05 | Code Review | Review | restore() — onlyTrashed()->findOrFail + restore + is_active=true | 4 |
| TC-ITEM-CR06 | Code Review | Review | forceDelete() — withTrashed()->findOrFail + clearMediaCollection + forceDelete | 4 |
| TC-ITEM-CR07 | Code Review | Review | toggleStatus() — Gate + validation + AJAX JSON response | 5 |
| TC-ITEM-CR08 | Code Review | Review | VndItemRequest — all field rules and unique ignore logic | 5 |
| TC-ITEM-CR09 | Code Review | Review | VndItemRequest — authorize() returns true (no Gate) | 2 |
| TC-ITEM-CR10 | Code Review | Review | VndItemRequest — prepareForValidation is_active boolean cast | 3 |
| TC-ITEM-CR11 | Code Review | Review | VndItem Model — fillable, casts, scopes, helpers | 5 |
| TC-ITEM-CR12 | Code Review | Review | VndItem Model — relationships (category, unit, agreementItems) | 3 |
| TC-ITEM-CR13 | Code Review | Review | VndItem Model — Spatie Media Collection (item_photo) and conversions | 4 |
| TC-ITEM-CR14 | Code Review | Review | Flash messages — all 6 controller operations | 6 |
| TC-ITEM-CR15 | Code Review | Review | Redirect after store/update — goes to vendor.vendor.index (not vendor-item.index) | 3 |
| TC-ITEM-CR16 | Code Review | Review | No check for active agreement items before deactivation (FRD Rule 1 gap) | 3 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-ITEM-D01 | Dependency | Dependency | Category FK → sys_dropdown_table — RESTRICT on delete | 3 |
| TC-ITEM-D02 | Dependency | Dependency | Unit FK → sys_dropdown_table — RESTRICT on delete | 3 |
| TC-ITEM-D03 | Dependency | Dependency | SoftDelete — deleted items excluded from unique item_code validation | 3 |
| TC-ITEM-D04 | Dependency | Dependency | Spatie Media Library — item_photo collection single-file replacement | 3 |
| TC-ITEM-D05 | Dependency | Dependency | Spatie Media Library — media conversions (small 150×150, medium 400×400) | 3 |
| TC-ITEM-D06 | Dependency | Dependency | DB UNIQUE KEY — uq_vnd_items_code enforces item_code uniqueness at DB level | 3 |
| TC-ITEM-D07 | Dependency | Dependency | DB INDEX — idx_vnd_items_type indexes item_type column | 2 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Item CRUD

#### TC-VND-ITEM-P01: Item list loads with search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-item.viewAny` permission navigates to Items tab on Vendor Dashboard or `/vendor-item` | Item list loads |
| 2 | Verify search input is present | Search field visible |
| 3 | Verify paginated item list with columns: item_code, item_name, item_type, item_nature, category, unit, default_price, is_active toggle, Actions | All columns present |
| 4 | Verify pagination links (10 per page) | Paginated |

#### TC-VND-ITEM-P02: Create item — all required fields (PRODUCT, CONSUMABLE)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-item.create` permission clicks "Add Item" | Create form loads |
| 2 | Enter item_name="Office Chair", select item_type="PRODUCT", select item_nature="CONSUMABLE" | Fields populated |
| 3 | Select category_id (valid dropdown record), select unit_id (valid dropdown record) | Category and Unit selected |
| 4 | Leave optional fields (item_code, HSN, price, photo, description) blank | Optional fields empty |
| 5 | Set is_active=true (checkbox checked) | Active |
| 6 | Click Submit | Redirected to vendor.vendor.index (Vendor Dashboard), success flash message shown |

#### TC-VND-ITEM-P03: Create item — SERVICE type with SERVICE nature

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter item_name="Consulting Service", select item_type="SERVICE", select item_nature="SERVICE" | Service item configured |
| 3 | Select valid category_id and unit_id | FK fields set |
| 4 | Submit form | Success |
| 5 | Verify DB record: item_type='SERVICE', item_nature='SERVICE' | DB verified |
| 6 | Verify redirect to vendor.vendor.index with success flash | Redirected |

#### TC-VND-ITEM-P04: Create item — all optional fields (item_code, HSN, price, reorder, photo, description)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill required fields: item_name="Premium Laptop", item_type="PRODUCT", item_nature="ASSET", category_id=valid, unit_id=valid | Required fields set |
| 3 | Fill optional fields: item_code="LAP-001", hsn_sac_code="84713000", default_price="99999.99", reorder_level="5.00" | Optional fields populated |
| 4 | Upload item_photo (image file) | Photo attached |
| 5 | Enter description="High-end business laptop" | Description entered |
| 6 | Submit form | Success |
| 7 | Verify DB record has all 11 fillable fields populated correctly | DB verified |

#### TC-VND-ITEM-P05: Create item — item_photo upload via media library

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill all required fields (item_name, item_type, item_nature, category_id, unit_id) | Required fields set |
| 3 | Upload a valid image file to item_photo field | File selected |
| 4 | Submit form | Success |
| 5 | Verify media record exists in media table: collection_name='item_photo', model_type=VndItem, singleFile | Photo stored via Spatie |

#### TC-VND-ITEM-P06: View item detail with relations (category, unit)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-item.view` permission clicks "View" on an item row | Show page loads |
| 2 | Verify all item fields are displayed: item_code, item_name, item_type, item_nature, hsn_sac_code, default_price, reorder_level, description, is_active | All fields visible |
| 3 | Verify category name (from sys_dropdown_table) and unit name (from sys_dropdown_table) are displayed via eager-loaded relations | Relations shown |

#### TC-VND-ITEM-P07: Edit item — update item_name, item_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-item.update` permission clicks "Edit" on an item | Edit form loads with pre-filled data |
| 2 | Change item_name to "Updated Item Name", change item_type to "SERVICE" | Fields changed |
| 3 | Click Update | Redirected to vendor.vendor.index |
| 4 | Verify success flash message appears | Success message |
| 5 | Verify item list shows updated item_name and item_type | Changes reflected |

#### TC-VND-ITEM-P08: Edit item — change item_photo (clear old, upload new)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Item has existing item_photo (item_photo_uploaded=1) | Existing photo |
| 2 | Open edit form, upload a new image file for item_photo | New file selected |
| 3 | Submit update | Success |
| 4 | Verify old media record in item_photo collection is removed (clearMediaCollection called) | Old media cleared |
| 5 | Verify new media record exists in item_photo collection with updated image | New photo stored |

#### TC-VND-ITEM-P09: Edit item — change tracking logs old/new values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Item has default_price="100.00" and reorder_level="10.00" | Existing values |
| 2 | Edit item and change default_price to "150.00" and reorder_level to "15.00" | Fields changed |
| 3 | Submit update | Success |
| 4 | Verify activity log entry contains old values ("100.00", "10.00") and new values ("150.00", "15.00") for changed fields | Change tracked |

#### TC-VND-ITEM-P10: Toggle status — active to inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an active item (is_active=true) in the list | Active item visible |
| 2 | Click status toggle to deactivate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": false, "message": "..."}` | AJAX success |
| 4 | Verify DB: is_active = 0 for the item and activity log entry created | Deactivated |

#### TC-VND-ITEM-P11: Toggle status — inactive to active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an inactive item (is_active=false) in the list | Inactive item visible |
| 2 | Click status toggle to activate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": true, "message": "..."}` | AJAX success |
| 4 | Verify DB: is_active = 1 for the item and activity log entry created | Activated |

#### TC-VND-ITEM-P12: Soft-delete item

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-item.delete` permission clicks "Delete" on an active item | Confirmation prompt |
| 2 | Confirm deletion | Item soft-deleted |
| 3 | Verify item no longer appears in active item list | Removed from active |
| 4 | Verify DB: deleted_at is not null AND is_active = 0 (manually set before delete) | Soft-deleted |

#### TC-VND-ITEM-P13: Restore item from trash (is_active restored to 1)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-item.restore` permission navigates to `/vendor-item/trash/view` | Trash list loads |
| 2 | Locate a soft-deleted item | Item visible in trash |
| 3 | Click Restore | Item restored |
| 4 | Verify item appears in active list, deleted_at is NULL, is_active=1, and activity log entry created | Restored and reactivated |

#### TC-VND-ITEM-P14: Force-delete item (permanent with media cleanup)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-item.forceDelete` permission navigates to trash view | Trash list loads |
| 2 | Locate a soft-deleted item (with item_photo) and click "Force Delete" | Confirmation prompt |
| 3 | Confirm permanent deletion | Item permanently deleted |
| 4 | Verify DB record no longer exists (including withTrashed), media collection cleared, and activity log entry created | Permanently deleted |

#### TC-VND-ITEM-P15: Search items — by item_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Items tab, enter search term matching part of an item_name | Filter applied |
| 2 | Verify result list contains only items with matching item_name | Filtered results |
| 3 | Verify search is case-insensitive and uses LIKE %term% | Wildcard search |

#### TC-VND-ITEM-P16: Search items — by item_code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Items tab, enter search term matching part of an item_code | Filter applied |
| 2 | Verify result list contains only items with matching item_code | Filtered results |
| 3 | Verify partial match works (e.g. "LAP" matches "LAP-001") | Wildcard search |

#### TC-VND-ITEM-P17: Filter items — by status (active/inactive)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Items tab, set status filter to "Active" (1) | Filter applied |
| 2 | Verify only active items (is_active=1) are shown | Active-only list |
| 3 | Set status filter to "Inactive" (0) and verify only inactive items shown | Inactive-only list |

#### TC-VND-ITEM-P18: hasPhoto() and photoUrl() helper methods return correct values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Item with uploaded photo (item_photo_uploaded=1, media exists) | Item has photo |
| 2 | Call `$item->hasPhoto()` | Returns true |
| 3 | Call `$item->photoUrl()` | Returns valid URL string to the photo |

#### TC-VND-ITEM-P19: Media conversions (small 150×150, medium 400×400) generated on upload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload item_photo to a new item | Photo uploaded |
| 2 | Check media conversions: `$media->getUrl('small')` | Returns 150×150 conversion URL |
| 3 | Check media conversions: `$media->getUrl('medium')` | Returns 400×400 conversion URL |
| 4 | Verify original image also accessible via `$media->getUrl()` | Original available |

#### TC-VND-ITEM-P20: Activity log created on item store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new item via store() | Success |
| 2 | Verify `activityLog()` was called with the VndItem model, action='Stored', and message | Logged |
| 3 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-VND-ITEM-P21: Activity log created on item update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update an item via update() | Success |
| 2 | Verify `activityLog()` called with action='Updated' and changes array | Logged |
| 3 | Verify changes contains old/new values for modified fields | Change tracking |

#### TC-VND-ITEM-P22: Activity log created on item soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete an item via destroy() | Success |
| 2 | Verify `activityLog()` called with action='Trashed' | Logged |

#### TC-VND-ITEM-P23: Activity log created on item restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a trashed item via restore() | Success |
| 2 | Verify `activityLog()` called with action='Restored' | Logged |

#### TC-VND-ITEM-P24: Activity log created on item force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a trashed item via forceDelete() | Success |
| 2 | Verify `activityLog()` called with action='Deleted' and message | Logged |

#### TC-VND-ITEM-P25: Activity log created on item toggle-status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle item status via toggleStatus() | AJAX success |
| 2 | Verify `activityLog()` called with action='Toggled' | Logged |
| 3 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-VND-ITEM-P26: addMediaFromRequest('item_photo') stores photo to item_photo collection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form and fill required fields (item_name, item_type, item_nature, category_id, unit_id) | Required fields set |
| 2 | Upload a valid image file to item_photo field | File selected |
| 3 | Submit the form | Success |
| 4 | Verify media record in `media` table: `collection_name='item_photo'`, `model_type` = VndItem, file exists on disk | Photo stored via Spatie Media Library |

#### TC-VND-ITEM-P27: singleFile() replaces old photo when new one uploaded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Item has existing photo in item_photo collection | Existing media record |
| 2 | Upload a second image to the same item's item_photo field via update | New file selected |
| 3 | Submit update | Success |
| 4 | Call `$item->getMedia('item_photo')` | Only 1 media record returned (old one replaced by singleFile) |

#### TC-VND-ITEM-P28: clearMediaCollection('item_photo') on update before adding new photo

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Item has existing item_photo (verified via hasPhoto() = true) | Existing photo |
| 2 | Open edit form, upload a new image file for item_photo | New file selected |
| 3 | Submit update | Success |
| 4 | Verify `clearMediaCollection('item_photo')` was called (old media records in item_photo collection = 0, new media record = 1) | Old cleared, new stored |

#### TC-VND-ITEM-P29: hasPhoto() returns true/false based on media existence in item_photo collection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Item A with uploaded photo and media record in item_photo collection | Item A has photo |
| 2 | Call `$itemA->hasPhoto()` | Returns true |
| 3 | Item B with no uploaded photo and no media record | Item B has no photo |
| 4 | Call `$itemB->hasPhoto()` | Returns false |

#### TC-VND-ITEM-P30: photoUrl() returns URL when photo exists, null when no photo; conversion URLs via 'small'/'medium'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Item A with uploaded photo in item_photo collection | Item A has photo |
| 2 | Call `$itemA->photoUrl()` | Returns valid URL string to the original photo |
| 3 | Call `$itemA->photoUrl('small')` | Returns URL for 150×150 conversion |
| 4 | Call `$itemA->photoUrl('medium')` | Returns URL for 400×400 conversion |
| 5 | Item B with no photo; call `$itemB->photoUrl()` | Returns null |

#### TC-VND-ITEM-P31: active() scope filters is_active = true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DB has mix of active (is_active=1) and inactive (is_active=0) items | Mixed records |
| 2 | Call `VndItem::active()->get()` | Returns only items where is_active = 1 |
| 3 | Verify no inactive items appear in the result set | Scope applied correctly |

#### TC-VND-ITEM-P32: item belongsTo category (Dropdown) and unit (Dropdown)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fetch an item with valid category_id and unit_id | Item loaded |
| 2 | Access `$item->category` | Returns related Dropdown record for category |
| 3 | Access `$item->unit` | Returns related Dropdown record for unit |

#### TC-VND-ITEM-P33: item hasMany agreementItems (VndAgreementItem)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fetch an item that has associated VndAgreementItem records | Item loaded |
| 2 | Access `$item->agreementItems` | Returns collection of VndAgreementItem records |
| 3 | Verify each agreementItem has item_id matching the item's id | Relationship correct |

### 10.2 Negative TC Steps — Item CRUD

#### TC-VND-ITEM-N01: Create — missing item_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without item_name | Validation error |
| 2 | Verify error: "The item name field is required." | Error shown |

#### TC-VND-ITEM-N02: Create — item_name exceeds 100 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set item_name to a 101-character string | Exceeds max |
| 2 | Submit | Validation error: "The item name must not be greater than 100 characters." |

#### TC-VND-ITEM-N03: Create — missing item_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without item_type | Validation error |
| 2 | Verify error: "The item type field is required." | Error shown |

#### TC-VND-ITEM-N04: Create — invalid item_type (not SERVICE or PRODUCT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set item_type = "INVALID_TYPE" | Invalid value |
| 2 | Submit | Validation error: "The selected item type is invalid." |

#### TC-VND-ITEM-N05: Create — missing item_nature

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without item_nature | Validation error |
| 2 | Verify error: "The item nature field is required." | Error shown |

#### TC-VND-ITEM-N06: Create — invalid item_nature (not in enum list)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set item_nature = "INVALID_NATURE" | Invalid value |
| 2 | Submit | Validation error: "The selected item nature is invalid." |

#### TC-VND-ITEM-N07: Create — missing category_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without category_id | Validation error |
| 2 | Verify error: "The category id field is required." | Error shown |

#### TC-VND-ITEM-N08: Create — category_id non-existent (invalid FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set category_id = 99999 (no matching sys_dropdown_table record) | Invalid FK |
| 2 | Submit | Validation error: "The selected category id is invalid." (exists rule) |

#### TC-VND-ITEM-N09: Create — category_id non-integer (string)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set category_id = "abc" | Non-integer value |
| 2 | Submit | Validation error: "The category id must be an integer." |

#### TC-VND-ITEM-N10: Create — missing unit_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without unit_id | Validation error |
| 2 | Verify error: "The unit id field is required." | Error shown |

#### TC-VND-ITEM-N11: Create — unit_id non-existent (invalid FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set unit_id = 99999 (no matching sys_dropdown_table record) | Invalid FK |
| 2 | Submit | Validation error: "The selected unit id is invalid." (exists rule) |

#### TC-VND-ITEM-N12: Create — unit_id non-integer (string)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set unit_id = "xyz" | Non-integer value |
| 2 | Submit | Validation error: "The unit id must be an integer." |

#### TC-VND-ITEM-N13: Create — item_code exceeds 50 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set item_code to a 51-character string | Exceeds max |
| 2 | Submit | Validation error: "The item code must not be greater than 50 characters." |

#### TC-VND-ITEM-N14: Create — duplicate item_code (existing active)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Item "LAP-001" already exists (active) | Existing record |
| 2 | Submit create with item_code="LAP-001" | Validation error: "The item code has already been taken." |

#### TC-VND-ITEM-N15: Create — default_price negative value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set default_price = "-100.00" | Negative value |
| 2 | Submit | Validation error: "The default price must be at least 0." |

#### TC-VND-ITEM-N16: Create — reorder_level negative value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set reorder_level = "-5.00" | Negative value |
| 2 | Submit | Validation error: "The reorder level must be at least 0." |

#### TC-VND-ITEM-N17: Create — hsn_sac_code exceeds 20 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set hsn_sac_code to a 21-character string | Exceeds max |
| 2 | Submit | Validation error |

#### TC-VND-ITEM-N18: Create — default_price non-numeric (string)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set default_price = "not-a-price" | Non-numeric value |
| 2 | Submit | Validation error: "The default price must be a number." |

#### TC-VND-ITEM-N19: Update — duplicate item_code (existing different item)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Item A has code="CODE-A", Item B has code="CODE-B" | Two items exist |
| 2 | Edit Item B and change item_code to "CODE-A" | Duplicate attempt |
| 3 | Submit | Validation error: "The item code has already been taken." |

#### TC-VND-ITEM-N20: Update — item_code changed to soft-deleted item's code (should succeed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Item "DEL-ITEM" is soft-deleted (deleted_at NOT NULL) | Trashed item |
| 2 | Edit any active item and change item_code to "DEL-ITEM" | Unique validation ignores soft-deleted records |
| 3 | Submit — should succeed because unique ignores whereNull deleted_at | Update successful |

#### TC-VND-ITEM-N21: Toggle status — missing is_active parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/vendor-item/{id}/toggle-status` without is_active in request body | Validation error |
| 2 | Verify error: "The is active field is required." | Error returned |

#### TC-VND-ITEM-N22: Toggle status — non-boolean is_active value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/vendor-item/{id}/toggle-status` with is_active="not-a-boolean" | Validation error |
| 2 | Verify error: "The is active field must be true or false." | Error returned |

#### TC-VND-ITEM-N23: Toggle status — non-existent item ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/vendor-item/99999/toggle-status` with is_active=true | Item 99999 doesn't exist |
| 2 | Verify 404 Not Found from findOrFail | 404 error |

#### TC-VND-ITEM-N24: Force delete — non-existent item ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/vendor-item/99999/force-delete` | Item 99999 doesn't exist |
| 2 | Verify 404 Not Found from withTrashed()->findOrFail | 404 error |

#### TC-VND-ITEM-N25: Restore — non-existent item ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/vendor-item/99999/restore` | Item 99999 doesn't exist |
| 2 | Verify 404 Not Found from onlyTrashed()->findOrFail | 404 error |

#### TC-VND-ITEM-N26: Permission — index without tenant.vendor-item.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-item.viewAny` permission accesses Items tab | 403 Forbidden |
| 2 | Verify `Gate::authorize('tenant.vendor-item.viewAny')` fails | Aborted |

#### TC-VND-ITEM-N27: Permission — create without tenant.vendor-item.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-item.create` accesses `/vendor-item/create` | 403 Forbidden |

#### TC-VND-ITEM-N28: Permission — store without tenant.vendor-item.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-item.create` POSTs to `/vendor-item` | 403 Forbidden |

#### TC-VND-ITEM-N29: Permission — edit without tenant.vendor-item.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-item.update` accesses `/vendor-item/{id}/edit` | 403 Forbidden |

#### TC-VND-ITEM-N30: Permission — update without tenant.vendor-item.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-item.update` PUTs to `/vendor-item/{id}` | 403 Forbidden |

#### TC-VND-ITEM-N31: Permission — view show without tenant.vendor-item.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-item.view` accesses `/vendor-item/{id}` | 403 Forbidden |

#### TC-VND-ITEM-N32: Permission — destroy without tenant.vendor-item.delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-item.delete` DELETEs `/vendor-item/{id}` | 403 Forbidden |

#### TC-VND-ITEM-N33: Permission — trashed without tenant.vendor-item.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-item.restore` accesses `/vendor-item/trash/view` | 403 Forbidden |

#### TC-VND-ITEM-N34: Permission — restore without tenant.vendor-item.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-item.restore` POSTs to `/vendor-item/{id}/restore` | 403 Forbidden |

#### TC-VND-ITEM-N35: Permission — forceDelete without tenant.vendor-item.forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-item.forceDelete` DELETEs `/vendor-item/{id}/force-delete` | 403 Forbidden |

#### TC-VND-ITEM-N36: Permission — toggleStatus without tenant.vendor-item.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-item.update` POSTs to `/vendor-item/{id}/toggle-status` | 403 Forbidden |

#### TC-VND-ITEM-N37: Create — is_active non-boolean string value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set is_active = "yes" (string, not boolean) | Invalid value |
| 2 | Submit | Validation error: "The is active field must be true or false." |

#### TC-VND-ITEM-N38: Create — item_name whitespace-only string (potential data quality)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set item_name = "   " (whitespace-only) | Passes required + string validation |
| 2 | Submit | Depending on implementation, may store whitespace string — potential data quality issue |

#### TC-VND-ITEM-N39: Upload — invalid file type for item_photo (non-image)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form and upload a PDF or .txt file to item_photo field | Invalid file type |
| 2 | Submit | Validation error (media library may reject non-image file) or Spatie silently fails |

### 10.3 Code Review TC Steps

#### TC-ITEM-CR01: index() — Gate + search (item_name, item_code) + latest() + paginate(10)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-item.viewAny')` at method start | Gate present |
| 2 | Review search logic: `where('item_name', 'like', "%{$search}%")->orWhere('item_code', 'like', "%{$search}%")` | Search on item_name and item_code |
| 3 | Review `->latest()->paginate(10)` with `->withQueryString()` | Ordering and pagination |
| 4 | Review return view with paginated items collection | View returned |

#### TC-ITEM-CR02: store() — Gate + create + media upload + activityLog + flash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-item.create')` | Gate present |
| 2 | Review `VndItem::create($request->validated())` | Creation via validated data |
| 3 | Review media upload logic: `$request->hasFile('item_photo')` → `$item->addMedia(...)->toMediaCollection('item_photo')` | Media upload |
| 4 | Review `activityLog($item, 'Stored', [...])` | Activity logged |
| 5 | Review `redirect()->route('vendor.vendor.index')->with('success', ...)` | Flash success — note: redirects to Vendor Dashboard, not item index |

#### TC-ITEM-CR03: update() — change tracking with getChanges + media re-upload logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-item.update')` | Gate present |
| 2 | Review `$item->findOrFail($id)` | Model retrieved |
| 3 | Review `$original = $item->getOriginal()` before update | Original captured |
| 4 | Review `$item->update($request->validated())` | Update via validated data |
| 5 | Review photo re-upload: if new file, `$item->clearMediaCollection('item_photo')` then `addMedia(...)` | Media replaced |
| 6 | Review `$changes = $item->getChanges()` and activityLog with old/new values | Change tracking logged |

#### TC-ITEM-CR04: destroy() — manual is_active=false before delete (redundant)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-item.delete')` | Gate present |
| 2 | Review `$item->is_active = false; $item->save();` before delete | Manual deactivation |
| 3 | Review `$item->delete()` — triggers SoftDeletes | Soft delete |
| 4 | Review activityLog with action='Trashed' and flash message | Activity + flash |

#### TC-ITEM-CR05: restore() — onlyTrashed()->findOrFail + restore + is_active=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-item.restore')` | Gate present |
| 2 | Review `VndItem::onlyTrashed()->findOrFail($id)` | Scoped to trashed only |
| 3 | Review `$item->restore()` then `$item->is_active = true; $item->save()` | Restore + reactivate |
| 4 | Review activityLog and flash redirect | Activity + flash |

#### TC-ITEM-CR06: forceDelete() — withTrashed()->findOrFail + clearMediaCollection + forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-item.forceDelete')` | Gate present |
| 2 | Review `VndItem::withTrashed()->findOrFail($id)` | Bypasses soft-delete scope |
| 3 | Review `$item->clearMediaCollection('item_photo')` before forceDelete | Media cleanup |
| 4 | Review `$item->forceDelete()` and activityLog | Permanent delete + log |

#### TC-ITEM-CR07: toggleStatus() — Gate + validation + AJAX JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-item.update')` — uses update permission, not dedicated status permission (Known Issue) | Gate uses update |
| 2 | Review inline validation: `$request->validate(['is_active' => 'required|boolean'])` | Validation |
| 3 | Review `VndItem::findOrFail($id)` | Model binding |
| 4 | Review activityLog call before save | Activity before save |
| 5 | Review JSON success/error response based on `$item->save()` | AJAX JSON response |

#### TC-ITEM-CR08: VndItemRequest — all field rules and unique ignore logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review item_code: nullable|string|max:50|unique with ignore $itemId and whereNull deleted_at | Unique logic |
| 2 | Review item_name: required|string|max:100 | Required field |
| 3 | Review item_type: required|in:SERVICE,PRODUCT | Enum validation |
| 4 | Review item_nature: required|in:CONSUMABLE,ASSET,SERVICE,NA | Enum validation |
| 5 | Review category_id and unit_id: required|integer|exists:sys_dropdown_table,id | FK validation with exists |

#### TC-ITEM-CR09: VndItemRequest — authorize() returns true (no Gate)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `authorize()` method | Returns `true` |
| 2 | Note: No Gate check in FormRequest — relies entirely on controller Gate | Defence-in-depth gap |

#### TC-ITEM-CR10: VndItemRequest — prepareForValidation is_active boolean cast

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `prepareForValidation()` method | Merges is_active |
| 2 | Review `$this->boolean('is_active')` conversion | Checkbox to boolean |
| 3 | Note: This runs before validation so is_active is always boolean when validated | Pre-processing |

#### TC-ITEM-CR11: VndItem Model — fillable, casts, scopes, helpers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$fillable` array — 11 fields (item_code, item_name, item_type, item_nature, category_id, unit_id, hsn_sac_code, default_price, reorder_level, is_active, description) | All fillable fields |
| 2 | Review `$casts` — default_price→decimal:2, reorder_level→decimal:2, item_photo_uploaded→boolean, is_active→boolean | Casts configured |
| 3 | Review `scopeActive()` — where is_active = true | Active scope |
| 4 | Review `hasPhoto()` — returns boolean based on item_photo_uploaded flag | Photo helper |
| 5 | Review `photoUrl()` — returns URL string for the photo | URL helper |

#### TC-ITEM-CR12: VndItem Model — relationships (category, unit, agreementItems)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `category()` — belongsTo Dropdown::class | FK relationship to category |
| 2 | Review `unit()` — belongsTo Dropdown::class | FK relationship to unit |
| 3 | Review `agreementItems()` — hasMany VndAgreementItem | Has many agreement items |

#### TC-ITEM-CR13: VndItem Model — Spatie Media Collection (item_photo) and conversions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `registerMediaCollections()` — 'item_photo' collection, singleFile() | Collection defined |
| 2 | Review `registerMediaConversions()` — 'small' (150×150) and 'medium' (400×400) | Conversions defined |
| 3 | Review `InteractsWithMedia` trait is used via `HasMedia` interface | Trait present |
| 4 | Review `addMediaConversion('small')->width(150)->height(150)->sharpen(10)` and medium variant | Conversion config |

#### TC-ITEM-CR14: Flash messages — all 6 controller operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review store() flash: success message on item creation | Create flash |
| 2 | Review update() flash: success message on item update | Update flash |
| 3 | Review destroy() flash: success message on item soft-delete | Delete flash |
| 4 | Review restore() flash: success message on item restore | Restore flash |
| 5 | Review forceDelete() flash: success message on permanent delete | Force delete flash |
| 6 | Review toggleStatus() flash: success/error JSON response messages | Toggle flash messages |

#### TC-ITEM-CR15: Redirect after store/update — goes to vendor.vendor.index (not vendor-item.index)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review store() redirect: `redirect()->route('vendor.vendor.index')` | Redirects to Vendor Dashboard |
| 2 | Review update() redirect: `redirect()->route('vendor.vendor.index')` | Redirects to Vendor Dashboard |
| 3 | Note: Neither store() nor update() redirect to `vendor-item.index` — user must navigate to Items tab manually | Unexpected UX |

#### TC-ITEM-CR16: No check for active agreement items before deactivation (FRD Rule 1 gap)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review destroy() — no check `VndAgreementItem::where('item_id', $id)->where('is_active', true)->exists()` before deactivation | Missing check |
| 2 | Review toggleStatus() — no check for active agreement items before toggling to inactive | Missing check |
| 3 | Note: FRD Rule 1 requires warning when deactivating an item with active agreement items — **NOT IMPLEMENTED** | Known Gap |

### 10.4 Dependency TC Steps

#### TC-ITEM-D01: Category FK → sys_dropdown_table — RESTRICT on delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Category C1 has 2 associated items in vnd_items | Referenced dropdown |
| 2 | Attempt to delete C1 from sys_dropdown_table | RESTRICT violation |
| 3 | Verify DB error: Cannot delete or update a parent row — FK constraint fails | Delete blocked |

#### TC-ITEM-D02: Unit FK → sys_dropdown_table — RESTRICT on delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Unit U1 has 2 associated items in vnd_items | Referenced dropdown |
| 2 | Attempt to delete U1 from sys_dropdown_table | RESTRICT violation |
| 3 | Verify DB error: Cannot delete or update a parent row — FK constraint fails | Delete blocked |

#### TC-ITEM-D03: SoftDelete — deleted items excluded from unique item_code validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Item "DEL-LAP" is soft-deleted (deleted_at NOT NULL) | Trashed item |
| 2 | Create new item with item_code="DEL-LAP" | Unique validation ignores soft-deleted record |
| 3 | Verify item created successfully despite code matching soft-deleted record | Created |

#### TC-ITEM-D04: Spatie Media Library — item_photo collection single-file replacement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload a photo to item with collection='item_photo' | File uploaded |
| 2 | Upload a second photo to same item same collection via update() | clearMediaCollection called first |
| 3 | Access `$item->getMedia('item_photo')` | Only 1 media record (old one cleared) |

#### TC-ITEM-D05: Spatie Media Library — media conversions (small 150×150, medium 400×400)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload an image to item_photo | Image uploaded |
| 2 | Check `registerMediaConversions()` in Model | Conversions defined |
| 3 | Verify converted images are generated on upload (check media_uploads or conversion directory) | Conversions generated |

#### TC-ITEM-D06: DB UNIQUE KEY — uq_vnd_items_code enforces item_code uniqueness at DB level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert two records with same item_code via raw SQL (bypassing app validation) | DB constraint violation |
| 2 | Verify DB error: Duplicate entry for key 'uq_vnd_items_code' | Unique key enforced |
| 3 | Note: This is a defence-in-depth layer — app-level validation should catch first | Redundant enforcement |

#### TC-ITEM-D07: DB INDEX — idx_vnd_items_type indexes item_type column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `EXPLAIN SELECT * FROM vnd_items WHERE item_type = 'PRODUCT'` | Query uses idx_vnd_items_type index |
| 2 | Verify Extra column shows "Using index condition" or similar | Index utilized |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/vendor-item` | vendor-item.index | index() | tenant.vendor-item.viewAny |
| GET | `/vendor-item/create` | vendor-item.create | create() | tenant.vendor-item.create |
| POST | `/vendor-item` | vendor-item.store | store() | tenant.vendor-item.create |
| GET | `/vendor-item/{vendor-item}` | vendor-item.show | show() | tenant.vendor-item.view |
| GET | `/vendor-item/{vendor-item}/edit` | vendor-item.edit | edit() | tenant.vendor-item.update |
| PUT | `/vendor-item/{vendor-item}` | vendor-item.update | update() | tenant.vendor-item.update |
| DELETE | `/vendor-item/{vendor-item}` | vendor-item.destroy | destroy() | tenant.vendor-item.delete |
| GET | `/vendor-item/trash/view` | vendor-item.trashed | trashed() | tenant.vendor-item.restore |
| GET | `/vendor-item/{id}/restore` | vendor-item.restore | restore() | tenant.vendor-item.restore |
| DELETE | `/vendor-item/{id}/force-delete` | vendor-item.forceDelete | forceDelete() | tenant.vendor-item.forceDelete |
| POST | `/vendor-item/{id}/toggle-status` | vendor-item.toggleStatus | toggleStatus() | tenant.vendor-item.update |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | destroy() manually sets is_active=false before delete — redundant with SoftDeletes | **Low** | SoftDeletes already marks deleted_at; manual is_active=false is unnecessary |
| KI-02 | restore() manually sets is_active=true — redundant | **Low** | restore() already restores the model; manually setting is_active=true is unnecessary |
| KI-03 | toggleStatus() uses tenant.vendor-item.update instead of a dedicated status permission | **Low** | No dedicated `tenant.vendor-item.status` permission exists; status toggle reuses update permission |
| KI-04 | All redirects after store/update go to vendor.vendor.index (Vendor Dashboard) not vendor-item.index | **Medium** | User must manually navigate to Items tab after creating/editing an item — unexpected UX |
| KI-05 | No check for active agreement items before deactivation (FRD Rule 1 not implemented) | **High** | Business rule requires warning when deactivating an item that has active VndAgreementItem records — no such check exists in destroy() or toggleStatus() |
| KI-06 | item_code unique validation exists at app level AND enforced by DB UNIQUE KEY | **Info** | Defence-in-depth — app-level validation via Rule::unique + DB-level uq_vnd_items_code constraint |
| KI-07 | VndItemRequest authorize() returns true | **Medium** | No Gate check in FormRequest — defence-in-depth collapsed; relies solely on controller Gate |
| KI-08 | index view query string preserved via withQueryString() | **Info** | Pagination links maintain current query parameters for search/filter state |

---

## 13. Feature Summary Matrix

| Feature | Controller Method(s) | Key Models | Pagination |
|---------|---------------------|------------|------------|
| Item List (Tab) | index() | VndItem | 10 per page |
| Create Item | create(), store() | VndItem | None (form) |
| View Item | show() | VndItem | None |
| Edit Item | edit(), update() | VndItem | None (form) |
| Soft-Delete / Restore | destroy(), trashed(), restore() | VndItem | 10 per page (trash) |
| Force Delete | forceDelete() | VndItem | None |
| Toggle Status | toggleStatus() | VndItem | None (AJAX) |
| Item Photo Upload | store(), update() | VndItem, Media | None |
