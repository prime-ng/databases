# caf_WeeklyMenu — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** Weekly/Daily Menus (CRUD + Publish/Archive/Duplicate + Soft-Delete + API)
**DB scope:** TENANT-side (`caf_daily_menus`, `caf_daily_menu_items_jnt`) · **Test style:** Browser Dusk
**Primary table:** `caf_daily_menus` · **Module URL prefix:** `/cafeteria/menu-planning?tab=weekly-menus`
**Test file:** `caf_WeeklyMenu_TestCas.php`
**Tab:** Weekly Menus (third tab of Menu Planning)

Controllers:
- `WeeklyMenuController` — CRUD + publish + archive + duplicate + apiCurrentWeek + trash
- `CafeteriaController::menuPlanning()` — loads weekly menus for tabbed page

Service:
- `MenuService` — createDailyMenu, updateDailyMenu, publishMenu, archiveMenu, duplicateDailyMenu, archiveOldMenus

Routes (`cafeteria.` prefix):
- `GET /cafeteria/menu-planning` — tabbed page (weekly-menus tab)
- `GET /cafeteria/weekly-menus` — index (redirects to menu-planning?tab=weekly-menus)
- `GET /cafeteria/weekly-menus/create` — create page
- `POST /cafeteria/weekly-menus` — store
- `GET /cafeteria/weekly-menus/{menu}` — show
- `GET /cafeteria/weekly-menus/{menu}/edit` — edit
- `PUT /cafeteria/weekly-menus/{menu}` — update
- `DELETE /cafeteria/weekly-menus/{menu}` — soft delete
- `POST /cafeteria/weekly-menus/{menu}/publish` — publish (Draft→Published)
- `POST /cafeteria/weekly-menus/{menu}/archive` — archive (Published→Archived)
- `POST /cafeteria/weekly-menus/{menu}/duplicate` — duplicate (Draft only, opens modal)
- `GET /cafeteria/menus/current-week` — API: published menus for current week
- `GET /cafeteria/weekly-menus/trash/view` — trashed
- `GET /cafeteria/weekly-menus/{id}/restore` — restore
- `DELETE /cafeteria/weekly-menus/{id}/force-delete` — force delete

**DDL reference:** `caf_daily_menus`, `caf_daily_menu_items_jnt` (Cafeteria DDL)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `caf_daily_menus`: id (INT UNSIGNED PK AI), menu_date (DATE NOT NULL UNIQUE), week_start_date (DATE NOT NULL), academic_term_id (SMALLINT UNSIGNED NULL FK → sch_academic_term.id), status (ENUM('Draft','Published','Archived') DEFAULT 'Draft'), published_at (TIMESTAMP NULL), published_by (INT UNSIGNED NULL), notes (TEXT NULL), is_active (TINYINT 1 DEFAULT 1), created_by, created_at, updated_at, deleted_at. Indexes: uq_caf_dm_menu_date, idx_caf_dm_week_start, idx_caf_dm_academic_term, idx_caf_dm_status, idx_caf_dm_published_by, idx_caf_dm_created_by | DDL |
| BC-DB-02 | Table `caf_daily_menu_items_jnt`: id (INT UNSIGNED PK AI), daily_menu_id (INT UNSIGNED FK → caf_daily_menus.id ON DELETE CASCADE), menu_item_id (INT UNSIGNED FK → caf_menu_items.id ON DELETE CASCADE), meal_category_id (INT UNSIGNED FK → caf_menu_categories.id ON DELETE RESTRICT), serving_size_notes (VARCHAR 100 NULL), display_order (TINYINT UNSIGNED DEFAULT 0), is_active (TINYINT 1 DEFAULT 1), created_by, created_at, updated_at. Indexes: uq_caf_dmij (daily_menu_id, menu_item_id, meal_category_id) | DDL |
| BC-DB-03 | Model `DailyMenu`: table caf_daily_menus, SoftDeletes, fillable 8 fields, casts: menu_date/week_start_date→date, published_at→datetime, is_active→boolean. Constants: STATUSES=['Archived','Draft','Published']. Relations: academicTerm() belongsTo, publisher() belongsTo User, creator() belongsTo User, menuItems() hasMany DailyMenuItemJnt. Scopes: active(), published() | Model |
| BC-DB-04 | Model `DailyMenuItemJnt`: table caf_daily_menu_items_jnt, no SoftDeletes, fillable 6 fields, casts: display_order→integer, is_active→boolean. Relations: dailyMenu() belongsTo, menuItem() belongsTo, mealCategory() belongsTo | Model |

### BC-VAL — Validation (StoreDailyMenuRequest) — used for both store + update
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `menu_date` required date, unique:caf_daily_menus,menu_date (ignores own ID + soft-deleted) | FR |
| BC-VAL-02 | `week_start_date` required date | FR |
| BC-VAL-03 | `academic_term_id` nullable integer | FR |
| BC-VAL-04 | `notes` nullable string | FR |
| BC-VAL-05 | `is_active` nullable boolean | FR |
| BC-VAL-06 | `items` nullable array | FR |
| BC-VAL-07 | `items.*.menu_item_id` required_with:items integer exists:caf_menu_items,id | FR |
| BC-VAL-08 | `items.*.meal_category_id` required_with:items integer exists:caf_menu_categories,id | FR |
| BC-VAL-09 | `items.*.serving_size_notes` nullable string max:100 | FR |
| BC-VAL-10 | Custom validator: no duplicate (menu_item_id + meal_category_id) combinations | FR |

### BC-AUTH — Authorization (DailyMenuPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.weekly-menus` (viewAny) | View |
| BC-AUTH-02 | create/store/duplicate gate `cafeteria.daily.menu.create` | Policy |
| BC-AUTH-03 | show gate `cafeteria.daily.menu.view` | Policy |
| BC-AUTH-04 | edit/update/publish/archive gate `cafeteria.daily.menu.update` | Policy |
| BC-AUTH-05 | destroy gate `cafeteria.daily.menu.delete` | Policy |
| BC-AUTH-06 | restore/forceDelete gate `cafeteria.daily.menu.delete` (reuses same permission) | Policy |

**NOTE:** DailyMenuPolicy uses `cafeteria.daily.menu.*` permission keys, while tab view uses `cafeteria.weekly-menus`. Verify consistency.

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Weekly Menus tab: paginated 14, table with Menu Date (formatted), Week Start, Notes, Status badge, Action buttons | View |
| BC-BIZ-02 | Status filter: All/Draft/Published/Archived | View |
| BC-BIZ-03 | Create: dedicated page with date picker, academic term select, category tabs, dish checkboxes per meal category | Ctrl |
| BC-BIZ-04 | Store: creates as Draft via MenuService::createDailyMenu() in transaction, logs activity | Service |
| BC-BIZ-05 | Show: dedicated page with menu details + items table grouped by meal category | Ctrl |
| BC-BIZ-06 | Edit: dedicated page with pre-filled data, academic term, items | Ctrl |
| BC-BIZ-07 | Update: blocks if Archived (DomainException), updates via MenuService::updateDailyMenu() | Service |
| BC-BIZ-08 | Publish: Draft→Published, requires ≥1 item (BR-CAF-005), sets published_at+published_by, logs activity | Service |
| BC-BIZ-09 | Archive: Published→Archived, logs activity | Service |
| BC-BIZ-10 | Duplicate: source Draft + target_date → creates new Draft copying all items, logs activity | Service |
| BC-BIZ-11 | Duplicate guard: target date must not have existing menu (DomainException) | Service |
| BC-BIZ-12 | Action buttons per status: Draft=Publish+Duplicate+Edit+Delete, Published=Archive+View, Archived=View | View |
| BC-BIZ-13 | Duplicate modal: opens for Draft items, date picker for target_date | View |
| BC-BIZ-14 | Search: text search by notes | View |
| BC-BIZ-15 | API: GET /cafeteria/menus/current-week returns Published menus for current ISO week with items+categories | Ctrl |
| BC-BIZ-16 | Soft delete: record moved to trash | Ctrl |
| BC-BIZ-17 | Auto-archive: caf:archive-old-menus command archives Published menus >7 days old | Service |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Duplicate menu_date → unique validation error | FR |
| BC-EDG-02 | Publish with 0 items → DomainException (BR-CAF-005) | Service |
| BC-EDG-03 | Publish Archived menu → DomainException (only Draft allowed) | Service |
| BC-EDG-04 | Duplicate to existing date → DomainException | Service |
| BC-EDG-05 | Edit Archived menu → DomainException | Service |
| BC-EDG-06 | Duplicate (menu_item_id + meal_category_id) in same menu → custom validation error | FR |
| BC-EDG-07 | Invalid menu_item_id in items → exists:caf_menu_items validation error | FR |
| BC-EDG-08 | Invalid meal_category_id in items → exists:caf_menu_categories validation error | FR |

---

## 2. Test Case List

### Screen 1: Menu Planning Page — Weekly Menus Tab (GET /cafeteria/menu-planning?tab=weekly-menus)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFWM-P10 | Positive | View | Weekly Menus tab: table with Menu Date (formatted), Week Start, Notes, Status badge, Action buttons | Rendered | test_caf_wm_10 | Automated |
| TC-CAFWM-P11 | Positive | View | Status filter: All/Draft/Published/Archived | Filters | test_caf_wm_11 | Automated |
| TC-CAFWM-P12 | Positive | View | Search by notes text | Search | test_caf_wm_12 | Automated |
| TC-CAFWM-P13 | Positive | View | Add button links to /cafeteria/weekly-menus/create | Link | test_caf_wm_13 | Automated |
| TC-CAFWM-P14 | Positive | View | Draft: shows Publish + Duplicate + Edit + Delete action buttons | Draft actions | test_caf_wm_14 | Automated |
| TC-CAFWM-P15 | Positive | View | Published: shows Archive + View action buttons | Published actions | test_caf_wm_15 | Automated |
| TC-CAFWM-P16 | Positive | View | Archived: shows View action button only | Archived actions | test_caf_wm_16 | Automated |
| TC-CAFWM-P17 | Positive | View | Status badge colors: Draft=primary, Published=success, Archived=secondary | Badge colors | test_caf_wm_17 | Automated |
| TC-CAFWM-P18 | Positive | View | Paginated (14 per page), pagination links | Paginated | test_caf_wm_18 | Automated |
| TC-CAFWM-P19 | Positive | View | Empty state "No weekly menus found" with icon | Empty | test_caf_wm_19 | Automated |

### Screen 2: Create Page + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFWM-P30 | Positive | View | Create page: menu_date (date picker), week_start_date, academic_term (select), notes, category tabs with item checkboxes | Fields | test_caf_wm_30 | Automated |
| TC-CAFWM-P31 | Positive | Ctrl | Valid store with items → creates Draft menu + junction records, logs activity, redirects to tab | Created | test_caf_wm_31 | Automated |
| TC-CAFWM-P32 | Positive | Ctrl | Valid store without items → creates Draft menu with 0 items | Created empty | test_caf_wm_32 | Automated |
| TC-CAFWM-N33 | Negative | Val | Missing menu_date → required error | Error | test_caf_wm_33 | Automated |
| TC-CAFWM-N34 | Negative | Val | Duplicate menu_date → unique error "A menu already exists for this date." | Error | test_caf_wm_34 | Automated |
| TC-CAFWM-N35 | Negative | Val | Missing week_start_date → required error | Error | test_caf_wm_35 | Automated |
| TC-CAFWM-N36 | Negative | Val | Invalid menu_item_id in items → exists error | Error | test_caf_wm_36 | Automated |
| TC-CAFWM-N37 | Negative | Val | Invalid meal_category_id in items → exists error | Error | test_caf_wm_37 | Automated |
| TC-CAFWM-N38 | Negative | Val | Duplicate (menu_item_id + meal_category_id) in items → custom validation error | Error | test_caf_wm_38 | Automated |

### Screen 3: Show Page

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFWM-P50 | Positive | View | Show page: menu date, week start, academic term, status, items table grouped by meal category | Details | test_caf_wm_50 | Automated |

### Screen 4: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFWM-P70 | Positive | View | Edit page: pre-filled with menu data, items, academic term | Pre-filled | test_caf_wm_70 | Automated |
| TC-CAFWM-P71 | Positive | Ctrl | Update Draft menu → changes saved, items re-synced (delete + re-insert), logs activity | Updated | test_caf_wm_71 | Automated |
| TC-CAFWM-N72 | Negative | Biz | Update Archived menu → DomainException "Archived menus cannot be edited." | Blocked | test_caf_wm_72 | Automated |

### Screen 5: Publish + Archive + Duplicate

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFWM-P90 | Positive | Ctrl | Publish Draft menu with items → status=Published, published_at set, redirect success "Menu published" | Published | test_caf_wm_90 | Automated |
| TC-CAFWM-N91 | Negative | Biz | Publish Draft with 0 items → DomainException "Cannot publish a menu with no items" | Blocked | test_caf_wm_91 | Automated |
| TC-CAFWM-N92 | Negative | Biz | Publish Archived menu → DomainException "Only Draft menus can be published" | Blocked | test_caf_wm_92 | Automated |
| TC-CAFWM-P93 | Positive | Ctrl | Archive Published menu → status=Archived, redirect "Menu archived." | Archived | test_caf_wm_93 | Automated |
| TC-CAFWM-P94 | Positive | Ctrl | Duplicate Draft menu → modal with date picker, submit → new Draft created with same items + target_date | Duplicated | test_caf_wm_94 | Automated |
| TC-CAFWM-N95 | Negative | Biz | Duplicate to existing date → DomainException "A menu already exists for {date}." | Blocked | test_caf_wm_95 | Automated |

### Screen 6: Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFWM-P110 | Positive | Ctrl | Soft delete menu → deleted_at set, hidden from tab, in trash | Deleted | test_caf_wm_110 | Automated |
| TC-CAFWM-P111 | Positive | View | Trash page: deleted menus with restore/force-delete | Table | test_caf_wm_111 | Automated |
| TC-CAFWM-P112 | Positive | Ctrl | Restore from trash → deleted_at=NULL | Restored | test_caf_wm_112 | Automated |
| TC-CAFWM-P113 | Positive | Ctrl | Force delete → permanently removed | Perm deleted | test_caf_wm_113 | Automated |

### Screen 7: API — Current Week

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFWM-P130 | Positive | API | GET /cafeteria/menus/current-week → JSON with Published menus for current week, items+categories loaded | JSON | test_caf_wm_130 | Automated |
| TC-CAFWM-P131 | Positive | API | Current week excludes Draft/Archived menus | Filtered | test_caf_wm_131 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFWM-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_caf_wm_200 | Automated |
| TC-CAFWM-N201 | Negative | Auth | Without viewAny → tab hidden, index 403 | 403 | test_caf_wm_201 | Automated |
| TC-CAFWM-N202 | Negative | Auth | Without create → 403 on create/store/duplicate | 403 | test_caf_wm_202 | Automated |
| TC-CAFWM-N203 | Negative | Auth | Without update → 403 on update/publish/archive | 403 | test_caf_wm_203 | Automated |
| TC-CAFWM-N204 | Negative | Auth | Without delete → 403 on destroy | 403 | test_caf_wm_204 | Automated |
