# caf_MenuItem — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** Menu Items (CRUD + Dual Toggle + Soft-Delete)
**DB scope:** TENANT-side (`caf_menu_items`) · **Test style:** Browser Dusk
**Primary table:** `caf_menu_items` · **Module URL prefix:** `/cafeteria/menu-planning?tab=menu-items`
**Test file:** `caf_MenuItem_TestCas.php`
**Tab:** Menu Items (second tab of Menu Planning)

Controllers:
- `MenuItemController` — CRUD + toggleAvailability + toggleStatus + trash
- `CafeteriaController::menuPlanning()` — loads menu items for tabbed page

Service:
- `MenuService` — createItem, updateItem, toggleItemAvailability

Routes (`cafeteria.` prefix):
- `GET /cafeteria/menu-planning` — tabbed page (menu-items tab)
- `GET /cafeteria/menu-items` — index (redirects to menu-planning?tab=menu-items)
- `GET /cafeteria/menu-items/create` — create page
- `POST /cafeteria/menu-items` — store
- `GET /cafeteria/menu-items/{item}` — show
- `GET /cafeteria/menu-items/{item}/edit` — edit
- `PUT /cafeteria/menu-items/{item}` — update
- `DELETE /cafeteria/menu-items/{item}` — soft delete
- `POST /cafeteria/menu-items/{item}/toggle-availability` — AJAX availability toggle
- `POST /cafeteria/menu-items/{item}/toggle-status` — AJAX active toggle
- `GET /cafeteria/menu-items/trash/view` — trashed
- `GET /cafeteria/menu-items/{id}/restore` — restore
- `DELETE /cafeteria/menu-items/{id}/force-delete` — force delete

**DDL reference:** `caf_menu_items` (Cafeteria DDL)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `caf_menu_items`: id (INT UNSIGNED PK AI), category_id (INT UNSIGNED NOT NULL FK → caf_menu_categories.id ON DELETE RESTRICT), name (VARCHAR 150 NOT NULL), description (TEXT NULL), price (DECIMAL 8,2 NOT NULL), food_type (ENUM('Veg','Non_Veg','Egg','Jain') NOT NULL DEFAULT 'Veg'), calories (SMALLINT UNSIGNED NULL), protein_grams (DECIMAL 5,2 NULL), carbs_grams (DECIMAL 5,2 NULL), fat_grams (DECIMAL 5,2 NULL), allergen_notes (TEXT NULL), photo_media_id (INT UNSIGNED NULL FK → sys_media.id), is_available (TINYINT 1 DEFAULT 1), is_active (TINYINT 1 DEFAULT 1), created_by, created_at, updated_at, deleted_at. Indexes: idx_caf_mi_category, idx_caf_mi_food_type, idx_caf_mi_is_available, idx_caf_mi_photo_media, idx_caf_mi_created_by | DDL |
| BC-DB-02 | Model `MenuItem`: table caf_menu_items, SoftDeletes, fillable 13 fields, casts: price/protein_grams/carbs_grams/fat_grams→decimal:2, calories→integer, is_available→boolean, is_active→boolean. Relations: category() belongsTo MenuCategory, dailyMenuItems() hasMany DailyMenuItemJnt, orderItems() hasMany OrderItem, photo() belongsTo Media. Scopes: active(), available() | Model |

### BC-VAL — Validation (StoreMenuItemRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `category_id` required integer exists:caf_menu_categories,id | FR |
| BC-VAL-02 | `name` required string max:150 | FR |
| BC-VAL-03 | `description` nullable string | FR |
| BC-VAL-04 | `price` required numeric min:0 | FR |
| BC-VAL-05 | `food_type` required in:Veg,Non_Veg,Egg,Jain | FR |
| BC-VAL-06 | `calories` nullable integer min:0 | FR |
| BC-VAL-07 | `protein_grams` nullable numeric min:0 | FR |
| BC-VAL-08 | `carbs_grams` nullable numeric min:0 | FR |
| BC-VAL-09 | `fat_grams` nullable numeric min:0 | FR |
| BC-VAL-10 | `allergen_notes` nullable string | FR |
| BC-VAL-11 | `photo` nullable image mimes:jpeg,png,jpg,gif,webp max:2048 | FR |
| BC-VAL-12 | `photo_media_id` nullable integer exists:sys_media,id | FR |
| BC-VAL-13 | `is_available` nullable boolean | FR |
| BC-VAL-14 | `is_active` nullable boolean | FR |

### BC-AUTH — Authorization (MenuItemPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.menu-items` (viewAny) | View |
| BC-AUTH-02 | create/store gate `cafeteria.menu.item.create` | Policy |
| BC-AUTH-03 | show gate `cafeteria.menu.item.view` | Policy |
| BC-AUTH-04 | edit/update/toggleAvailability/toggleStatus gate `cafeteria.menu.item.update` | Policy |
| BC-AUTH-05 | destroy gate `cafeteria.menu.item.delete` | Policy |
| BC-AUTH-06 | restore/forceDelete gate `cafeteria.menu.item.delete` (reuses same permission) | Policy |

**NOTE:** MenuItemPolicy uses `cafeteria.menu.item.*` permission keys (with dots), while the tab view uses `cafeteria.menu-items` (with hyphen). Verify consistency.

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Menu Items tab: paginated 20, table with name, category, price, food_type badge, availability badge, status toggle, actions | View |
| BC-BIZ-02 | Create: dedicated page at /cafeteria/menu-items/create with category select dropdown | Ctrl |
| BC-BIZ-03 | Store: creates via MenuService::createItem() with auth user, logs activity | Service |
| BC-BIZ-04 | Show: dedicated page with full item details + category name | Ctrl |
| BC-BIZ-05 | Edit: dedicated page with pre-filled form + category select | Ctrl |
| BC-BIZ-06 | Update: updates via MenuService::updateItem(), logs activity | Service |
| BC-BIZ-07 | Toggle Availability: AJAX POST toggles is_available, returns JSON {status, is_available}, logs activity | Service |
| BC-BIZ-08 | Toggle Status: AJAX POST toggles is_active, returns JSON {success, is_active, message}, logs activity | Ctrl |
| BC-BIZ-09 | Soft delete: record moved to trash | Ctrl |
| BC-BIZ-10 | Search: text search by name | View |
| BC-BIZ-11 | Filter: status filter (All/Active/Inactive) | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | price negative → min:0 validation error | FR |
| BC-EDG-02 | Invalid food_type → in:Veg,Non_Veg,Egg,Jain error | FR |
| BC-EDG-03 | name > 150 chars → max validation error | FR |
| BC-EDG-04 | Invalid category_id → exists:caf_menu_categories error | FR |
| BC-EDG-05 | Photo > 2MB → max:2048 validation error | FR |
| BC-EDG-06 | calories negative → min:0 validation error | FR |
| BC-EDG-07 | Toggle availability toggles independently of is_active | Service |

---

## 2. Test Case List

### Screen 1: Menu Planning Page — Menu Items Tab (GET /cafeteria/menu-planning?tab=menu-items)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMI-P10 | Positive | View | Menu Items tab: table with Name, Category, Price, Food Type badge, Availability badge, Status toggle, Action | Rendered | test_caf_mi_10 | Automated |
| TC-CAFMI-P11 | Positive | View | Search by name, filter by status (All/Active/Inactive) | Filters | test_caf_mi_11 | Automated |
| TC-CAFMI-P12 | Positive | View | Add button links to /cafeteria/menu-items/create | Link | test_caf_mi_12 | Automated |
| TC-CAFMI-P13 | Positive | View | Food type badge styling: Veg=green, Non_Veg=red, Egg/Jain=appropriate colors | Badges | test_caf_mi_13 | Automated |
| TC-CAFMI-P14 | Positive | View | Availability badge shows Available/Unavailable with color coding | Badge | test_caf_mi_14 | Automated |
| TC-CAFMI-P15 | Positive | View | Price displayed in ₹ format with 2 decimals | Format | test_caf_mi_15 | Automated |
| TC-CAFMI-P16 | Positive | View | Paginated (20 per page), pagination links visible with 21+ items | Paginated | test_caf_mi_16 | Automated |
| TC-CAFMI-P17 | Positive | View | Empty state "No menu items found" with icon | Empty | test_caf_mi_17 | Automated |

### Screen 2: Create Page + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMI-P30 | Positive | View | Create page: Name, Category (select), Description, Price, Food Type (radio/select), Calories, Protein, Carbs, Fat, Allergen Notes, Photo upload, Available checkbox, Active checkbox | Fields | test_caf_mi_30 | Automated |
| TC-CAFMI-P31 | Positive | Ctrl | Valid store (all fields): creates menu item, logs activity, redirects to tab with success | Created | test_caf_mi_31 | Automated |
| TC-CAFMI-P32 | Positive | Ctrl | Valid store (required only: name, category, price, food_type): creates with defaults (is_available=1, is_active=1, null optionals) | Created | test_caf_mi_32 | Automated |
| TC-CAFMI-P33 | Positive | Ctrl | Store with photo upload → file stored, photo_media_id set | Photo | test_caf_mi_33 | Automated |
| TC-CAFMI-N34 | Negative | Val | Missing name → required error | Error | test_caf_mi_34 | Automated |
| TC-CAFMI-N35 | Negative | Val | name > 150 chars → max error | Error | test_caf_mi_35 | Automated |
| TC-CAFMI-N36 | Negative | Val | Missing category_id → required error | Error | test_caf_mi_36 | Automated |
| TC-CAFMI-N37 | Negative | Val | Invalid category_id → exists error | Error | test_caf_mi_37 | Automated |
| TC-CAFMI-N38 | Negative | Val | Missing price → required error | Error | test_caf_mi_38 | Automated |
| TC-CAFMI-N39 | Negative | Val | price negative → min:0 error | Error | test_caf_mi_39 | Automated |
| TC-CAFMI-N40 | Negative | Val | Missing food_type → required error | Error | test_caf_mi_40 | Automated |
| TC-CAFMI-N41 | Negative | Val | Invalid food_type → in enum error | Error | test_caf_mi_41 | Automated |
| TC-CAFMI-N42 | Negative | Val | Photo > 2MB → max:2048 error | Error | test_caf_mi_42 | Automated |
| TC-CAFMI-N43 | Negative | Val | Invalid photo mime type (e.g. .pdf) → mimes error | Error | test_caf_mi_43 | Automated |
| TC-CAFMI-N44 | Negative | Val | calories negative → min:0 error | Error | test_caf_mi_44 | Automated |

### Screen 3: Show Page

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMI-P60 | Positive | View | Show page: name, category, price, food type, nutritional info, allergen notes, photo, availability, status | Details | test_caf_mi_60 | Automated |
| TC-CAFMI-P61 | Positive | View | 404 if item not found | 404 | test_caf_mi_61 | Automated |

### Screen 4: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMI-P80 | Positive | View | Edit page: form pre-filled with existing data, category selected | Pre-filled | test_caf_mi_80 | Automated |
| TC-CAFMI-P81 | Positive | Ctrl | Update changes fields, logs activity | Updated | test_caf_mi_81 | Automated |
| TC-CAFMI-P82 | Positive | Ctrl | Update with new photo → old photo replaced, new photo_media_id set | Photo updated | test_caf_mi_82 | Automated |

### Screen 5: Toggle Availability + Toggle Status

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMI-P100 | Positive | Ctrl | Toggle availability available→unavailable → JSON {status:true, is_available:false}, activity logged | Unavailable | test_caf_mi_100 | Automated |
| TC-CAFMI-P101 | Positive | Ctrl | Toggle availability unavailable→available → JSON {status:true, is_available:true} | Available | test_caf_mi_101 | Automated |
| TC-CAFMI-P102 | Positive | Ctrl | Toggle status active→inactive → JSON {success, is_active:false} | Inactive | test_caf_mi_102 | Automated |
| TC-CAFMI-P103 | Positive | Ctrl | Toggle status inactive→active → JSON {success, is_active:true} | Active | test_caf_mi_103 | Automated |
| TC-CAFMI-P104 | Positive | Biz | Availability toggle independent from status toggle → both can be set independently | Independent | test_caf_mi_104 | Automated |

### Screen 6: Delete + Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMI-P120 | Positive | Ctrl | Soft delete item → deleted_at set, hidden from tab, appears in trash | Deleted | test_caf_mi_120 | Automated |
| TC-CAFMI-P121 | Positive | View | Trash page: table of deleted items with restore/force-delete | Table | test_caf_mi_121 | Automated |
| TC-CAFMI-P122 | Positive | Ctrl | Restore from trash → deleted_at=NULL, back in main listing | Restored | test_caf_mi_122 | Automated |
| TC-CAFMI-P123 | Positive | Ctrl | Force delete → permanently removed from DB | Perm deleted | test_caf_mi_123 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMI-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_caf_mi_200 | Automated |
| TC-CAFMI-N201 | Negative | Auth | Without viewAny → tab hidden, index 403 | 403 | test_caf_mi_201 | Automated |
| TC-CAFMI-N202 | Negative | Auth | Without create → 403 on create/store | 403 | test_caf_mi_202 | Automated |
| TC-CAFMI-N203 | Negative | Auth | Without update → 403 on update/toggle | 403 | test_caf_mi_203 | Automated |
| TC-CAFMI-N204 | Negative | Auth | Without delete → 403 on destroy/restore/forceDelete | 403 | test_caf_mi_204 | Automated |
