# caf_EventMeal — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** Event Meals (CRUD + Publish + Soft-Delete)
**DB scope:** TENANT-side (`caf_event_meals`, `caf_event_meal_items_jnt`) · **Test style:** Browser Dusk
**Primary table:** `caf_event_meals` · **Module URL prefix:** `/cafeteria/menu-planning?tab=event-meals`
**Test file:** `caf_EventMeal_TestCas.php`
**Tab:** Event Meals (fourth tab of Menu Planning)

Controllers:
- `EventMealController` — CRUD + publish + trash
- `CafeteriaController::menuPlanning()` — loads event meals for tabbed page

Service:
- `MenuService` — createEventMeal, updateEventMeal, publishEventMeal

Routes (`cafeteria.` prefix):
- `GET /cafeteria/menu-planning` — tabbed page (event-meals tab)
- `GET /cafeteria/event-meals` — index (redirects to menu-planning?tab=event-meals)
- `GET /cafeteria/event-meals/create` — create page
- `POST /cafeteria/event-meals` — store
- `GET /cafeteria/event-meals/{meal}` — show
- `GET /cafeteria/event-meals/{meal}/edit` — edit
- `PUT /cafeteria/event-meals/{meal}` — update
- `DELETE /cafeteria/event-meals/{meal}` — soft delete
- `POST /cafeteria/event-meals/{meal}/publish` — publish (Draft→Published)
- `GET /cafeteria/event-meals/trash/view` — trashed
- `GET /cafeteria/event-meals/{id}/restore` — restore
- `DELETE /cafeteria/event-meals/{id}/force-delete` — force delete

**DDL reference:** `caf_event_meals`, `caf_event_meal_items_jnt` (Cafeteria DDL)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `caf_event_meals`: id (INT UNSIGNED PK AI), name (VARCHAR 150 NOT NULL), event_date (DATE NOT NULL), meal_category_id (INT UNSIGNED NOT NULL FK → caf_menu_categories.id ON DELETE RESTRICT), target_class_ids_json (JSON NULL), status (ENUM('Draft','Published','Archived') DEFAULT 'Draft'), published_at (TIMESTAMP NULL), notes (TEXT NULL), is_active (TINYINT 1 DEFAULT 1), created_by, created_at, updated_at, deleted_at. Indexes: idx_caf_em_event_date, idx_caf_em_category, idx_caf_em_status, idx_caf_em_created_by | DDL |
| BC-DB-02 | Table `caf_event_meal_items_jnt`: id (INT UNSIGNED PK AI), event_meal_id (INT UNSIGNED FK → caf_event_meals.id ON DELETE CASCADE), menu_item_id (INT UNSIGNED NULL FK → caf_menu_items.id ON DELETE SET NULL), free_text_item (VARCHAR 150 NULL), quantity_per_student (DECIMAL 5,2 NULL), display_order (TINYINT UNSIGNED DEFAULT 0), is_active (TINYINT 1 DEFAULT 1), created_by, created_at, updated_at | DDL |
| BC-DB-03 | Model `EventMeal`: table caf_event_meals, SoftDeletes, fillable 8 fields, casts: event_date→date, target_class_ids_json→array, published_at→datetime, is_active→boolean. Relations: mealCategory() belongsTo MenuCategory, eventItems() hasMany EventMealItemJnt. Scopes: active(), published(), forClass($classId) | Model |
| BC-DB-04 | Model `EventMealItemJnt`: table caf_event_meal_items_jnt, no SoftDeletes, fillable 6 fields, casts: quantity_per_student→decimal:2, display_order→integer, is_active→boolean. Relations: eventMeal() belongsTo, menuItem() belongsTo | Model |

### BC-VAL — Validation (StoreEventMealRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `name` required string max:150 | FR |
| BC-VAL-02 | `event_date` required date | FR |
| BC-VAL-03 | `meal_category_id` required integer exists:caf_menu_categories,id | FR |
| BC-VAL-04 | `target_class_ids_json` nullable array, each element integer | FR |
| BC-VAL-05 | `status` nullable in:Draft,Published,Archived | FR |
| BC-VAL-06 | `notes` nullable string | FR |
| BC-VAL-07 | `items` nullable array; items.*.menu_item_id nullable integer exists:caf_menu_items,id; items.*.free_text_item nullable string max:150; items.*.quantity_per_student nullable numeric min:0 | FR |

### BC-AUTH — Authorization (EventMealPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.event-meals` (viewAny) | View |
| BC-AUTH-02 | create/store gate `cafeteria.event.meal.create` | Policy |
| BC-AUTH-03 | show gate `cafeteria.event.meal.view` | Policy |
| BC-AUTH-04 | edit/update/publish gate `cafeteria.event.meal.update` | Policy |
| BC-AUTH-05 | destroy gate `cafeteria.event.meal.delete` | Policy |
| BC-AUTH-06 | restore/forceDelete gate `cafeteria.event.meal.delete` (reuses same permission) | Policy |

**NOTE:** EventMealPolicy uses `cafeteria.event.meal.*` permission keys, while tab view uses `cafeteria.event-meals`. Verify consistency.

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Event Meals tab: paginated 10, table with Event Name, Event Date (formatted), Category, Status badge, Action buttons | View |
| BC-BIZ-02 | Status filter: All/Draft/Published (Archived not in filter) | View |
| BC-BIZ-03 | Action buttons per status: Draft=Publish+Edit+Delete, Published=View only (no Archive in UI) | View |
| BC-BIZ-04 | Create: dedicated page with name, event_date, meal_category select, class multi-select, notes, items with item+quantity | Ctrl |
| BC-BIZ-05 | Store: creates as Draft via MenuService::createEventMeal() in transaction, logs activity | Service |
| BC-BIZ-06 | Show: dedicated page with event details + items table | Ctrl |
| BC-BIZ-07 | Edit: dedicated page with pre-filled data, classes, items | Ctrl |
| BC-BIZ-08 | Update: deletes+re-inserts items via MenuService::updateEventMeal() in transaction | Service |
| BC-BIZ-09 | Publish: Draft→Published, sets published_at, logs activity | Service |
| BC-BIZ-10 | Publish guard: throws DomainException if not Draft | Service |
| BC-BIZ-11 | Search: text search by name | View |
| BC-BIZ-12 | Soft delete: record moved to trash | Ctrl |
| BC-BIZ-13 | Class targeting: target_class_ids_json NULL/empty = all classes, array = specific classes | Model |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | name > 150 chars → max validation error | FR |
| BC-EDG-02 | Missing meal_category_id → required error | FR |
| BC-EDG-03 | Invalid meal_category_id → exists error | FR |
| BC-EDG-04 | Publish non-Draft event meal → DomainException "Only Draft event meals can be published." | Service |
| BC-EDG-05 | Duplicate item entries in same event meal → QueryException caught with user-friendly error | Ctrl |
| BC-EDG-06 | target_class_ids_json with non-integer values → each integer validation error | FR |
| BC-EDG-07 | Library item (menu_item_id) + free-text item (free_text_item) both null on same row → allowed (nullable) | FR |

---

## 2. Test Case List

### Screen 1: Menu Planning Page — Event Meals Tab (GET /cafeteria/menu-planning?tab=event-meals)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFEM-P10 | Positive | View | Event Meals tab: table with Event Name, Event Date (formatted), Category, Status badge, Action buttons | Rendered | test_caf_em_10 | Automated |
| TC-CAFEM-P11 | Positive | View | Status filter: All/Draft/Published | Filters | test_caf_em_11 | Automated |
| TC-CAFEM-P12 | Positive | View | Search by event name | Search | test_caf_em_12 | Automated |
| TC-CAFEM-P13 | Positive | View | Add button links to /cafeteria/event-meals/create | Link | test_caf_em_13 | Automated |
| TC-CAFEM-P14 | Positive | View | Draft: shows Publish + Edit + Delete buttons | Draft actions | test_caf_em_14 | Automated |
| TC-CAFEM-P15 | Positive | View | Published: shows View button only (no Archive action in UI) | Published actions | test_caf_em_15 | Automated |
| TC-CAFEM-P16 | Positive | View | Status badge colors: Draft=warning, Published=primary | Badge colors | test_caf_em_16 | Automated |
| TC-CAFEM-P17 | Positive | View | Paginated (10 per page), sorted by event_date desc | Paginated | test_caf_em_17 | Automated |
| TC-CAFEM-P18 | Positive | View | Empty state "No event meals planned" with icon | Empty | test_caf_em_18 | Automated |

### Screen 2: Create Page + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFEM-P30 | Positive | View | Create page: Name, Event Date, Meal Category (select), Classes (multi-select), Notes, Items with menu_item select or free_text input + quantity | Fields | test_caf_em_30 | Automated |
| TC-CAFEM-P31 | Positive | Ctrl | Valid store with library items → creates Draft event meal + junction records, logs activity | Created | test_caf_em_31 | Automated |
| TC-CAFEM-P32 | Positive | Ctrl | Valid store with free-text items → creates with free_text_item values | Free text | test_caf_em_32 | Automated |
| TC-CAFEM-P33 | Positive | Ctrl | Valid store with class targeting → target_class_ids_json stored as array | Targeted | test_caf_em_33 | Automated |
| TC-CAFEM-P34 | Positive | Ctrl | Valid store without items → creates Draft with 0 items | Created empty | test_caf_em_34 | Automated |
| TC-CAFEM-N35 | Negative | Val | Missing name → required error | Error | test_caf_em_35 | Automated |
| TC-CAFEM-N36 | Negative | Val | name > 150 chars → max error | Error | test_caf_em_36 | Automated |
| TC-CAFEM-N37 | Negative | Val | Missing event_date → required error | Error | test_caf_em_37 | Automated |
| TC-CAFEM-N38 | Negative | Val | Missing meal_category_id → required error | Error | test_caf_em_38 | Automated |
| TC-CAFEM-N39 | Negative | Val | Invalid meal_category_id → exists error | Error | test_caf_em_39 | Automated |

### Screen 3: Show + Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFEM-P50 | Positive | View | Show page: name, event_date, category, classes, items table | Details | test_caf_em_50 | Automated |
| TC-CAFEM-P51 | Positive | View | Edit page: pre-filled with event data and items | Pre-filled | test_caf_em_51 | Automated |
| TC-CAFEM-P52 | Positive | Ctrl | Update changes fields + items re-synced (delete + re-insert), logs activity | Updated | test_caf_em_52 | Automated |

### Screen 4: Publish

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFEM-P70 | Positive | Ctrl | Publish Draft event meal → status=Published, published_at set, redirect "published." | Published | test_caf_em_70 | Automated |
| TC-CAFEM-N71 | Negative | Biz | Publish non-Draft (Published or Archived) → DomainException | Blocked | test_caf_em_71 | Automated |

### Screen 5: Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFEM-P90 | Positive | Ctrl | Soft delete → deleted_at set, hidden from tab, in trash | Deleted | test_caf_em_90 | Automated |
| TC-CAFEM-P91 | Positive | View | Trash page: deleted event meals with restore/force-delete | Table | test_caf_em_91 | Automated |
| TC-CAFEM-P92 | Positive | Ctrl | Restore from trash → deleted_at=NULL | Restored | test_caf_em_92 | Automated |
| TC-CAFEM-P93 | Positive | Ctrl | Force delete → permanently removed | Perm deleted | test_caf_em_93 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFEM-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_caf_em_200 | Automated |
| TC-CAFEM-N201 | Negative | Auth | Without viewAny → tab hidden, index 403 | 403 | test_caf_em_201 | Automated |
| TC-CAFEM-N202 | Negative | Auth | Without create → 403 on create/store | 403 | test_caf_em_202 | Automated |
| TC-CAFEM-N203 | Negative | Auth | Without update → 403 on update/publish | 403 | test_caf_em_203 | Automated |
| TC-CAFEM-N204 | Negative | Auth | Without delete → 403 on destroy | 403 | test_caf_em_204 | Automated |
