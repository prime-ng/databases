# caf_MealCategory — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** Meal Categories (CRUD + Reorder + Toggle + Soft-Delete)
**DB scope:** TENANT-side (`caf_menu_categories`) · **Test style:** Browser Dusk
**Primary table:** `caf_menu_categories` · **Module URL prefix:** `/cafeteria/menu-planning?tab=categories`
**Test file:** `caf_MealCategory_TestCas.php`
**Tab:** Meal Categories (first tab of Menu Planning)

Controllers:
- `MenuCategoryController` — CRUD + reorder + toggle + trash
- `CafeteriaController::menuPlanning()` — loads categories for tabbed page

Service:
- `MenuService` — createCategory, updateCategory, reorderCategories

Routes (`cafeteria.` prefix):
- `GET /cafeteria/menu-planning` — tabbed page (categories tab default)
- `GET /cafeteria/menu-categories` — index (redirects to menu-planning?tab=categories)
- `POST /cafeteria/menu-categories` — store via modal
- `GET /cafeteria/menu-categories/{menuCategory}` — show (JSON or redirect)
- `GET /cafeteria/menu-categories/{menuCategory}/edit` — edit (JSON or redirect)
- `PUT /cafeteria/menu-categories/{menuCategory}` — update via modal
- `DELETE /cafeteria/menu-categories/{menuCategory}` — soft delete
- `POST /cafeteria/menu-categories/reorder` — AJAX drag-and-drop reorder
- `POST /cafeteria/menu-categories/{menuCategory}/toggle` — AJAX toggle
- `GET /cafeteria/menu-categories/trash/view` — trashed
- `GET /cafeteria/menu-categories/{id}/restore` — restore
- `DELETE /cafeteria/menu-categories/{id}/force-delete` — force delete (guarded: dependencies)

**DDL reference:** `caf_menu_categories` (Cafeteria DDL)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `caf_menu_categories`: id (INT UNSIGNED PK AI), name (VARCHAR 100 NOT NULL), code (VARCHAR 20 NULL UNIQUE), meal_time (ENUM('Breakfast','Lunch','Snacks','Dinner','Tuck_Shop') NOT NULL), meal_start_time (TIME NULL), description (TEXT NULL), display_order (TINYINT UNSIGNED DEFAULT 0), is_active (TINYINT 1 DEFAULT 1), created_by (INT UNSIGNED NULL), created_at, updated_at, deleted_at. Indexes: uq_caf_mc_code (code), idx_caf_mc_created_by | DDL |
| BC-DB-02 | Model `MenuCategory`: table caf_menu_categories, SoftDeletes, fillable 7 fields, casts: is_active→boolean, display_order→integer. Relations: menuItems() hasMany MenuItem, dailyMenuItems() hasMany DailyMenuItemJnt, eventMeals() hasMany EventMeal, mealAttendances() hasMany MealAttendance, orders() hasMany Order, staffMealLogs() hasMany StaffMealLog. Scopes: ordered() (orderBy display_order), active() (where is_active=true). Methods: hasDependencies(), dependencySummary() | Model |

### BC-VAL — Validation (StoreMenuCategoryRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `name` required string max:100 | FR |
| BC-VAL-02 | `code` nullable string max:20, unique:caf_menu_categories,code (ignores own ID + soft-deleted) | FR |
| BC-VAL-03 | `meal_time` required in:Breakfast,Lunch,Snacks,Dinner,Tuck_Shop | FR |
| BC-VAL-04 | `meal_start_time` nullable | FR |
| BC-VAL-05 | `description` nullable string | FR |
| BC-VAL-06 | `display_order` nullable integer min:0 max:255 | FR |
| BC-VAL-07 | `is_active` nullable boolean | FR |

### BC-AUTH — Authorization (MenuCategoryPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.menu-categories` (viewAny) | View |
| BC-AUTH-02 | create/store gate `cafeteria.menu-categories.create` | Policy |
| BC-AUTH-03 | show gate `cafeteria.menu-categories.view` | Policy |
| BC-AUTH-04 | edit/update/toggle/reorder gate `cafeteria.menu-categories.update` | Policy |
| BC-AUTH-05 | destroy gate `cafeteria.menu-categories.delete` | Policy |
| BC-AUTH-06 | restore gate `cafeteria.menu-categories.restore` | Policy |
| BC-AUTH-07 | forceDelete gate `cafeteria.menu-categories.forceDelete` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Menu Planning page loads 4 tabs: Meal Categories (default), Menu Items, Weekly Menus, Event Meals | View |
| BC-BIZ-02 | Categories list: sortable table (Sortable.js), drag handle, name+description, meal_time, status toggle, actions | View |
| BC-BIZ-03 | Categories fetched with `ordered()` scope (ordered by display_order) — no pagination | MenuCtrl |
| BC-BIZ-04 | Store via modal: creates via MenuService::createCategory() with auth user, logs activity | Service |
| BC-BIZ-05 | Update via inline modal: pre-filled from data-category JSON, updates via MenuService::updateCategory(), logs activity | Service |
| BC-BIZ-06 | Drag-and-drop reorder: AJAX POST with ordered IDs, MenuService::reorderCategories() updates display_order in transaction | Service |
| BC-BIZ-07 | Toggle: flips is_active, returns JSON {success, is_active, message}, logs activity | Ctrl |
| BC-BIZ-08 | Soft delete: no dependency check, record moved to trash, logs activity | Ctrl |
| BC-BIZ-09 | Force delete: checks hasDependencies() → blocks with error listing dependencies (menuItems, dailyMenuItems, eventMeals, mealAttendances, orders, staffMealLogs) | Ctrl |
| BC-BIZ-10 | Force delete (bypass): manually deletes child records with FK_CHECKS=0 | Ctrl |
| BC-BIZ-11 | Search: text search by name | View |
| BC-BIZ-12 | Filter: status filter (All/Active/Inactive) | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Duplicate code → unique: validation error (unique ignores soft-deleted) | FR |
| BC-EDG-02 | name > 100 chars → max validation error | FR |
| BC-EDG-03 | code > 20 chars → max validation error | FR |
| BC-EDG-04 | display_order > 255 → max validation error | FR |
| BC-EDG-05 | Invalid meal_time → in:Breakfast,Lunch,Snacks,Dinner,Tuck_Shop error | FR |
| BC-EDG-06 | Force delete with menu items → error listing 'menu items' dependency | Ctrl |
| BC-EDG-07 | Force delete with event meals → error listing 'event meals' dependency | Ctrl |
| BC-EDG-08 | Force delete with orders → error listing 'orders' dependency | Ctrl |
| BC-EDG-09 | Soft delete → record hidden from main listing, visible in trash | Ctrl |

---

## 2. Test Case List

### Screen 1: Menu Planning Page — Categories Tab (GET /cafeteria/menu-planning?tab=categories)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMC-P10 | Positive | View | Menu Planning page renders 4 tabs: Meal Categories (active), Menu Items, Weekly Menus, Event Meals | Tabs visible | test_caf_mc_10 | Automated |
| TC-CAFMC-P11 | Positive | View | Categories tab: sortable table with drag handle, name+description, meal_time, status toggle, action buttons | Rendered | test_caf_mc_11 | Automated |
| TC-CAFMC-P12 | Positive | View | Search by name, filter by status (All/Active/Inactive) | Filters | test_caf_mc_12 | Automated |
| TC-CAFMC-P13 | Positive | View | Create button opens modal with form fields | Modal | test_caf_mc_13 | Automated |
| TC-CAFMC-P14 | Positive | View | Empty state "No categories found" when no records | Empty | test_caf_mc_14 | Automated |
| TC-CAFMC-P15 | Positive | View | Categories display in display_order sequence (no pagination, all loaded) | Ordered | test_caf_mc_15 | Automated |

### Screen 2: Create (Modal) + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMC-P30 | Positive | View | Create modal: Name (required), Code, Meal Time (required select), Start Time, Description, Display Order, Active checkbox | Fields | test_caf_mc_30 | Automated |
| TC-CAFMC-P31 | Positive | Ctrl | Valid store (all fields): creates category, logs activity, redirects with success | Created | test_caf_mc_31 | Automated |
| TC-CAFMC-P32 | Positive | Ctrl | Valid store (required only): creates with defaults (display_order=0, is_active=1) | Created | test_caf_mc_32 | Automated |
| TC-CAFMC-N33 | Negative | Val | Missing name → required error | Error | test_caf_mc_33 | Automated |
| TC-CAFMC-N34 | Negative | Val | name > 100 chars → max error | Error | test_caf_mc_34 | Automated |
| TC-CAFMC-N35 | Negative | Val | Missing meal_time → required error | Error | test_caf_mc_35 | Automated |
| TC-CAFMC-N36 | Negative | Val | Invalid meal_time → in enum error | Error | test_caf_mc_36 | Automated |
| TC-CAFMC-N37 | Negative | Val | Duplicate code → unique error | Error | test_caf_mc_37 | Automated |
| TC-CAFMC-N38 | Negative | Val | code > 20 chars → max error | Error | test_caf_mc_38 | Automated |
| TC-CAFMC-N39 | Negative | Val | display_order negative → min:0 error | Error | test_caf_mc_39 | Automated |
| TC-CAFMC-N40 | Negative | Val | display_order > 255 → max:255 error | Error | test_caf_mc_40 | Automated |

### Screen 3: Edit + Update (Inline Modal)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMC-P50 | Positive | View | Click Edit on row → modal opens with pre-filled data from data-category JSON | Pre-filled | test_caf_mc_50 | Automated |
| TC-CAFMC-P51 | Positive | Ctrl | Update changes fields (name, code, meal_time, etc.), logs activity | Updated | test_caf_mc_51 | Automated |
| TC-CAFMC-P52 | Positive | Val | Update with same code → allowed (unique ignores own ID) | Allowed | test_caf_mc_52 | Automated |
| TC-CAFMC-P53 | Positive | View | View mode (title=View) opens modal with all fields disabled | Read-only | test_caf_mc_53 | Automated |
| TC-CAFMC-N54 | Negative | Val | Update with duplicate code (other record) → unique error | Error | test_caf_mc_54 | Automated |

### Screen 4: Drag-and-Drop Reorder

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMC-P70 | Positive | View | Drag handle visible on each row, cursor:grab | Handle | test_caf_mc_70 | Automated |
| TC-CAFMC-P71 | Positive | Ctrl | Drag row to new position → AJAX POST with ordered IDs, success toast "Categories reordered" | Reordered | test_caf_mc_71 | Automated |
| TC-CAFMC-P72 | Positive | Ctrl | After reorder, display_order updated sequentially (0,1,2...) in DB | DB order | test_caf_mc_72 | Automated |
| TC-CAFMC-P73 | Positive | Ctrl | Page refresh shows new order persists | Persisted | test_caf_mc_73 | Automated |

### Screen 5: Toggle Status

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMC-P90 | Positive | Ctrl | Toggle active to inactive → JSON {success, is_active:false, message}, activity logged | JSON false | test_caf_mc_90 | Automated |
| TC-CAFMC-P91 | Positive | Ctrl | Toggle inactive to active → JSON {success, is_active:true, message}, activity logged | JSON true | test_caf_mc_91 | Automated |

### Screen 6: Delete (Soft Delete)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMC-P110 | Positive | Ctrl | Soft delete category → deleted_at set, appears in trash, logs activity | Deleted | test_caf_mc_110 | Automated |
| TC-CAFMC-P111 | Positive | View | Deleted category hidden from main listing | Hidden | test_caf_mc_111 | Automated |
| TC-CAFMC-P112 | Positive | View | Soft delete allowed even with dependencies (menu items, orders, etc.) | Allowed | test_caf_mc_112 | Automated |

### Screen 7: Trash + Restore + Force Delete

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMC-P130 | Positive | View | Trash page: table of deleted records with Deleted At, restore/force-delete actions | Table | test_caf_mc_130 | Automated |
| TC-CAFMC-P131 | Positive | View | Empty trash state when no deleted records | Empty | test_caf_mc_131 | Automated |
| TC-CAFMC-P132 | Positive | Ctrl | Restore from trash → deleted_at=NULL, logs activity | Restored | test_caf_mc_132 | Automated |
| TC-CAFMC-P133 | Positive | Ctrl | Force delete with no dependencies → record permanently removed | Perm deleted | test_caf_mc_133 | Automated |
| TC-CAFMC-N134 | Negative | Biz | Force delete with dependencies (e.g. menu items exist) → error listing dependencies | Blocked | test_caf_mc_134 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMC-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_caf_mc_200 | Automated |
| TC-CAFMC-N201 | Negative | Auth | Without viewAny → categories tab hidden, index 403 | 403 | test_caf_mc_201 | Automated |
| TC-CAFMC-N202 | Negative | Auth | Without create → 403 on store | 403 | test_caf_mc_202 | Automated |
| TC-CAFMC-N203 | Negative | Auth | Without update → 403 on update/toggle/reorder | 403 | test_caf_mc_203 | Automated |
| TC-CAFMC-N204 | Negative | Auth | Without delete → 403 on destroy | 403 | test_caf_mc_204 | Automated |
| TC-CAFMC-N205 | Negative | Auth | Without restore → 403 on restore | 403 | test_caf_mc_205 | Automated |
| TC-CAFMC-N206 | Negative | Auth | Without forceDelete → 403 on force-delete | 403 | test_caf_mc_206 | Automated |
