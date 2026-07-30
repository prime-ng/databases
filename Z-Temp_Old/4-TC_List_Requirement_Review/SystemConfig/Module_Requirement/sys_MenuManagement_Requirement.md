# SystemConfig — Navigation Menu Management

**Feature:** Navigation Menu Management | **REQ-ID:** REQ-SYS-002 | **Priority:** P0 (MUST)

---

## 1. Description

The Navigation Menu Management feature enables Platform Managers and Super Admins to create, edit, reorder, soft-delete, restore, and force-delete navigation menu items. Menus form a recursive tree structure stored in `glb_menus` (global database) with self-referential `parent_id`. Each menu item can be a category heading (`is_category=true`) or a navigable item. Menus are synchronised to tenants via the Menu Sync feature.

---

## 2. Controller & Model

| Artifact | Path | Lines | Status |
|----------|------|:-----:|--------|
| Controller | `Modules/SystemConfig/app/Http/Controllers/MenuController.php` | 272 | PARTIAL |
| Model | `Modules/SystemConfig/app/Models/Menu.php` | 98 | ✅ |
| Request | `Modules/SystemConfig/app/Http/Requests/MenuRequest.php` | 62 | ✅ |
| Policy | `Modules/SystemConfig/app/Policies/MenuPolicy.php` | 66 | ✅ |
| Observer | `Modules/SystemConfig/app/Observers/MenuObserver.php` | — | ✅ |

---

## 3. Routes

| Method | URI | Action | Permission | Status |
|--------|-----|--------|------------|--------|
| GET | `/system-config/menu` | `index` | `system-config.menu.viewAny` | ✅ |
| GET | `/system-config/menu/create` | `create` | `system-config.menu.create` | ⚠️ STUB (empty) |
| POST | `/system-config/menu` | `store` | `system-config.menu.create` | ✅ (translation logic commented) |
| GET | `/system-config/menu/{menu}/edit` | `edit` | `system-config.menu.update` | ✅ |
| PUT | `/system-config/menu/{menu}` | `update` | `system-config.menu.update` | ✅ |
| DELETE | `/system-config/menu/{menu}` | `destroy` | `system-config.menu.delete` | ⚠️ STUB (empty) |
| GET | `/system-config/menu/trash` | `trashedMenu` | `system-config.menu.restore` | ✅ |
| POST | `/system-config/menu/{id}/restore` | `restore` | `system-config.menu.restore` | ⚠️ STUB (empty) |
| DELETE | `/system-config/menu/{id}/force-delete` | `forceDelete` | `system-config.menu.forceDelete` | ✅ |
| POST | `/system-config/menu/{menu}/toggle-status` | `toggleStatus` | — | ⚠️ STUB (empty) |
| POST | `/system-config/menu/update-menu` | `updateMenu` | `system-config.menu.update` | ✅ (drag-drop AJAX) |

Route registration: `web.php` (central domain — `routes/web.php`).

---

## 4. Data Model

### 4.1 Menu (`glb_menus` — global database, `mysql` connection)

| Column | Type | Required | Default | Notes |
|--------|------|:--------:|:-------:|-------|
| `id` | BIGINT UNSIGNED AUTO_INCREMENT | ✅ | — | Primary key |
| `parent_id` | BIGINT UNSIGNED | — | NULL | Self-referential FK → `glb_menus.id` |
| `code` | VARCHAR(60) | ✅ | — | UNIQUE; system identifier; permanent after creation |
| `slug` | VARCHAR(255) | ✅ | — | Auto-set from title via `Str::slug()` |
| `title` | VARCHAR(100) | ✅ | — | UNIQUE; display label |
| `description` | VARCHAR(255) | — | — | Optional description |
| `icon` | VARCHAR(150) | ✅ | — | Font Awesome icon class |
| `route` | VARCHAR(255) | Conditional | — | Required for non-category items |
| `permission` | VARCHAR(255) | — | — | Permission gate string |
| `sort_order` | TINYINT UNSIGNED | ✅ | 0 | 0–255; renumbered on drag-drop |
| `is_category` | TINYINT(1) | ✅ | 0 | Category headings have `parent_id=null` |
| `is_direct_link` | TINYINT(1) | ✅ | 0 | Opens external/direct link |
| `visible_by_default` | TINYINT(1) | ✅ | 1 | Visibility toggle |
| `is_active` | TINYINT(1) | ✅ | 1 | Status toggle |
| `menu_for` | VARCHAR(20) | ✅ | — | `tenant` or `prime` |
| `deleted_at` | TIMESTAMP | — | NULL | SoftDeletes |

### 4.2 Model Relationships

| Relationship | Type | Target | Key |
|-------------|------|--------|-----|
| `parent()` | BelongsTo | `Menu` | `parent_id` |
| `children()` | HasMany | `Menu` | `parent_id` (ordered by `sort_order`) |
| `recursiveChildren()` | HasMany | `Menu` | `parent_id` (with nested eager loading) |
| `translations()` | MorphMany | `Translation` | `translatable` |
| `permissions()` | HasMany | `Permission` | — |
| `modules()` | BelongsToMany | `Module` | `glb_menu_module_jnt` pivot |

---

## 5. Controller Implementation Details

### 5.1 `index()`

- **Gate:** `Gate::authorize('system-config.menu.viewAny')`
- **Query:** `Menu::whereNull('parent_id')->orderBy('sort_order')->with(['children', 'translations'])`
- **Translation:** Hardcoded `$languageId = 2`; loads translations filtered by `language_id=2` and `key='title'`
- **Recursive:** `setTranslatedTitleRecursive()` traverses `recursiveChildren` and sets `$menu->translated_title` (falls back to `$menu->title`)

### 5.2 `create()` — **STUB**

- **Status:** Empty method body — returns nothing (default 200 empty response)
- **FRD Gap:** No create form view rendered
- **Gate:** Not called (empty method)

### 5.3 `store(MenuRequest $request)`

- **Gate:** `Gate::authorize('system-config.menu.create')`
- **Validation:** Uses `MenuRequest` (validates code, title, icon, route, sort_order, etc.)
- **Logic:** `Menu::create($data)`
- **Translation:** ❌ **Commented out** — lines 74-80 contain translation create logic but are inactive:
  ```php
  // $translationData = [
  //     'language_id' => $data['language_id'],
  //     'key' => $data['translateable_key'],
  //     'value' => $data['translateable_value'],
  // ];
  // $menu->translations()->create($translationData);
  ```
- **Audit:** `activityLog($menu, 'Stored', ...)`
- **Redirect:** `route('system-config.menu.index')` with success flash

### 5.4 `edit(Menu $menu)`

- **Gate:** `Gate::authorize('system-config.menu.update')`
- **Logic:** Loads the full menu tree (parent menus with recursive children and translations, hardcoded `language_id=2`)
- **View:** `systemconfig::menu.edit` with `compact('menu', 'menus')`

### 5.5 `update(MenuRequest $request, Menu $menu)`

- **Gate:** `Gate::authorize('system-config.menu.update')`
- **Logic:** Captures `$original` before update, calls `$menu->update($request->validated())`
- **Change Tracking:** Computes `$changedAttributes` array with old/new values; calls `activityLog()` with structured diff
- **Known Issue:** Code is NOT explicitly stripped — relies on `$fillable` not including `code` changes (actually `code` IS in `$fillable`). **FRD gap**: BR-SYS-002 requires code to be permanent.
- **Redirect:** `route('system-config.menu.index')` with success flash

### 5.6 `destroy(Menu $menu)` — **STUB**

- **Status:** Empty method body
- **FRD Gap:** No soft-delete logic implemented

### 5.7 `trashedMenu()`

- **Gate:** `Gate::authorize('system-config.menu.restore')`
- **Logic:** `Menu::onlyTrashed()->get()`
- **View:** `systemconfig::menu.trash` — **Note:** view notation may be incorrect (reported as `systemconfig.menu.trash` without double-colon)

### 5.8 `restore($id)` — **STUB**

- **Status:** Empty method body — no restore logic implemented
- **Gate:** Not called in stub

### 5.9 `forceDelete($id)`

- **Gate:** `Gate::authorize('system-config.menu.forceDelete')`
- **Logic:** `Menu::withTrashed()->findOrFail($id)->forceDelete();` + audit log
- **Redirect:** `route('system-config.menu.index')` with success flash

### 5.10 `toggleStatus(Request $request, Menu $menu)` — **STUB**

- **Status:** Empty method body — no toggle logic implemented

### 5.11 `updateMenu(Request $request)` — AJAX Drag-Drop Reorder

- **Gate:** `Gate::authorize('system-config.menu.update')`
- **Input:** `menu_id`, `parent_id`, `sort_order`
- **Validation:** `menu_id` and `parent_id` must exist in `glb_menus`; `sort_order` min:1
- **Category Guard:** If `$menu->is_category`, `parent_id` must be null (returns 422 with error flash)
- **Save:** Updates `parent_id` and `sort_order` on the moved menu
- **Sibling Renumber (BR-SYS-004):** All siblings at the same level get sequential `sort_order` (1, 2, 3, ...) — the moved item's position is skipped during renumbering
- **Audit:** `activityLog($menu, 'Draggable Menu', ...)`
- **Response:** JSON `{success: true/false, message: ...}`

---

## 6. Business Rules

| BR-ID | Rule | Implementation | Status |
|-------|------|---------------|:------:|
| BR-SYS-002 | Menu code is permanent — update must strip it | Code is in `$fillable` — NOT stripped | ❌ GAP |
| BR-SYS-003 | Category heading must have no parent | Enforced in `updateMenu()` (422) + `MenuRequest` validation | ✅ Partial |
| BR-SYS-004 | On drag-drop, all siblings renumbered sequentially from 1 | Implemented in `updateMenu()` sibling loop | ✅ |
| BR-SYS-012 | Every mutation must produce audit log entry | `store()`, `update()`, `forceDelete()`, `updateMenu()` all call `activityLog()` | ✅ |
| BR-SYS-018 | All SYS routes accessible only from central domain | Routes in `web.php` with `auth` + `verified` middleware | ✅ |

---

## 7. Security Rules

| Rule | Implementation | Status |
|------|---------------|:------:|
| Gate check on `viewAny` | `MenuController@index` | ✅ |
| Gate check on `create` | `MenuController@store` | ✅ |
| Gate check on `update` | `MenuController@edit`, `update`, `updateMenu` | ✅ |
| Gate check on `restore` | `trashedMenu` | ✅ |
| Gate check on `forceDelete` | `MenuController@forceDelete` | ✅ |
| Gate check missing on stub methods | `create()`, `destroy()`, `restore()`, `toggleStatus()` | ❌ Empty stubs |
| No `$request->all()` used | Controller uses `$request->validated()` from `MenuRequest` | ✅ |

---

## 8. Gaps & Known Issues

| # | Issue | Impact | Severity | Status |
|---|-------|--------|:--------:|:------:|
| 1 | `create()` is empty stub — no create form rendered | Feature gap | High | ⬜ |
| 2 | `destroy()` is empty stub — no soft-delete possible | Feature gap | High | ⬜ |
| 3 | `restore()` is empty stub — no restore from trash | Feature gap | High | ⬜ |
| 4 | `toggleStatus()` is empty stub — no status toggle | Feature gap | High | ⬜ |
| 5 | Code NOT stripped in `update()` — violates BR-SYS-002 | Security/Data Integrity | High | ⬜ |
| 6 | Translation language hardcoded to ID=2 in `index()` and `edit()` | Hardcoded value | Medium | ⬜ |
| 7 | Translation create logic commented out in `store()` | Feature gap | Medium | ⬜ |
| 8 | View notation `systemconfig.menu.trash` may be incorrect (missing `::`) | Bug | Medium | ⬜ |
| 9 | `show()` method exists but is empty — not used | Dead code | Low | ⬜ |

---

## 9. FRD References

| Reference | Source | Summary |
|-----------|--------|---------|
| REQ-SYS-002 | FRD §2 | Navigation Menu Management |
| BR-SYS-002 | FRD §4 | Code is permanent |
| BR-SYS-003 | FRD §4 | Category cannot have parent |
| BR-SYS-004 | FRD §4 | Drag-drop sibling renumber |
| BR-SYS-012 | FRD §4 | Audit log requirement |
| BR-SYS-018 | FRD §4 | Central-only routes |
| US-SYS-002 | FRD §8 | User story for menu management |

---

## 10. Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| V1 | — | — | — |
| V2 | — | — | — |
