# Menu (PRM / Central) — Test Case List & Business Conditions

- **Module:** Prime (PRM) — **Feature/Screen:** Menu (Menu Management)
- **DB scope:** CENTRAL (`global_master` DB via connection `global_master_mysql`); no tenant init. Host `http://127.0.0.1:8000`.
- **Primary table:** `glb_menus` — **Prefix:** `glb_` (DDL-verified). ⚠️ Registry lists PRM prefix `prm_`; the feature's primary table is `glb_menus`, so artifacts use `glb_`. **Registry-vs-DDL flag.**
- **Controller:** `Modules\Prime\Http\Controllers\MenuController` — **Model:** `Modules\Prime\Models\Menu` (+ `MenuModule`)
- **FormRequest:** `Modules\SystemConfig\Http\Requests\MenuRequest`
- **Route group:** `Route::domain(app.domain)->name('central.')` → `prefix('system-config')->name('system-config.')` → `central.system-config.menu.*`
- **Permission gates:** `prime.menu.{viewAny|view|create|update|delete|restore|forceDelete}` (verified in controller + `PrimeMenuPolicy`).
- **Activity sink:** central `sys_central_activity_logs` (`Modules\Prime\Models\ActivityLog`, connection `mysql`) — tenancy never initialized (Constraint #25).

---

## 1. Business Conditions

### BC-DB (schema — `DDL-glb_menus`, `_global_db_v4.sql`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `glb_menus` PK `id` INT unsigned AI | DDL-glb_menus |
| BC-DB-02 | `parent_id` INT unsigned NULL, self-FK `fk_glb_menus_parentId` ON DELETE **RESTRICT** | DDL-glb_menus |
| BC-DB-03 | `code` varchar(60) NOT NULL, **global** unique `uq_glb_menus_code` | DDL-glb_menus |
| BC-DB-04 | `slug` varchar(150) NOT NULL (auto from title) | DDL-glb_menus |
| BC-DB-05 | `title` varchar(100) NOT NULL | DDL-glb_menus |
| BC-DB-06 | `icon` varchar(150), `route` varchar(255), `description` varchar(255) | DDL-glb_menus |
| BC-DB-07 | `sort_order` int unsigned NOT NULL | DDL-glb_menus |
| BC-DB-08 | `is_category`, `visible_by_default`(def 1), `is_active`(def 1) tinyint(1) | DDL-glb_menus |
| BC-DB-09 | `deleted_at` — soft delete | DDL-glb_menus |
| BC-DB-10 | CHECK `chk_glb_menus_is_category_parentId`: `is_category=1 → parent_id IS NULL` | DDL-glb_menus |
| BC-DB-11 | ⚠️ `menu_for` + `permission` columns used by model/controller but **absent** from consolidated DDL (schema drift) | Model + DDL |

### BC-VAL (`MenuRequest`, `Screen-VR`)
| ID | Rule | Message/Behaviour | Source |
|----|------|-------------------|--------|
| BC-VAL-01 | `code` required, string, max 60, unique(glb_menus) scoped by `menu_for` | Laravel default | Screen-VR-1 |
| BC-VAL-02 | `title` required, string, max 100, unique scoped by `menu_for` | Laravel default | Screen-VR-2 |
| BC-VAL-03 | `icon` required, string, max 150 | Laravel default | Screen-VR-3 |
| BC-VAL-04 | `sort_order` required, integer, min 0, max 255 | Laravel default | Screen-VR-4 |
| BC-VAL-05 | `menu_for` sometimes, `in:prime,tenant` | Laravel default | Screen-VR-5 |
| BC-VAL-06 | `parent_id` nullable, `exists:glb_menus,id` | Laravel default | Screen-VR-6 |
| BC-VAL-07 | `route` required (string,max255,`ValidCombinedRoute`) **unless** parent_id null AND not category | conditional | Screen-VR-7 |
| BC-VAL-08 | checkboxes coerced to bool in `prepareForValidation` | — | Screen-VR-8 |

### BC-AUTH (`PrimeMenuPolicy` + controller gates, `Screen-PM`)
| ID | Gate | Guards | Source |
|----|------|--------|--------|
| BC-AUTH-01 | `prime.menu.viewAny` | index, tree render | Screen-PM-1 |
| BC-AUTH-02 | `prime.menu.create` | create form, store | Screen-PM-2 |
| BC-AUTH-03 | `prime.menu.view` | show | Screen-PM-3 |
| BC-AUTH-04 | `prime.menu.update` | edit, update, toggleStatus, updateMenu | Screen-PM-4 |
| BC-AUTH-05 | `prime.menu.delete` | destroy | Screen-PM-5 |
| BC-AUTH-06 | `prime.menu.restore` | trashedMenu, restore | Screen-PM-6 |
| BC-AUTH-07 | `prime.menu.forceDelete` | forceDelete | Screen-PM-7 |

### BC-BIZ (controller/model behaviour, activity events)
| ID | Behaviour | Event (verbatim) | Source |
|----|-----------|------------------|--------|
| BC-BIZ-01 | store: create + default `menu_for='prime'` | `Stored` | Controller |
| BC-BIZ-02 | update: diff changes + log | `Updated` | Controller |
| BC-BIZ-03 | destroy: set is_active=false then soft-delete | `Trashed` | Controller |
| BC-BIZ-04 | restore | `Restored` | Controller |
| BC-BIZ-05 | forceDelete | `Deleted` | Controller |
| BC-BIZ-06 | toggleStatus: JSON flip is_active | `Toggled` | Controller |
| BC-BIZ-07 | updateMenu: reorder + sibling normalisation | `Draggable Menu` | Controller |
| BC-BIZ-08 | `setTitleAttribute` derives `slug = Str::slug(title)` | — | Model |
| BC-BIZ-09 | index summary counts by `menu_for` + `is_category` | — | Controller |
| BC-BIZ-10 | routeSuggestions: filter route names by scope (`central.` prefix) + query | — | Controller |

### BC-SM (status lifecycle)
| ID | State → Trigger → Next | Source |
|----|------------------------|--------|
| BC-SM-01 | Active → toggleStatus → Inactive (and back) | Screen-SM-1 |
| BC-SM-02 | Active → destroy → Trashed (soft) | Screen-SM-2 |
| BC-SM-03 | Trashed → restore → Active | Screen-SM-3 |
| BC-SM-04 | Trashed → forceDelete → Deleted (gone) | Screen-SM-4 |

### BC-REF / BC-INT
| ID | Relationship | onDelete | Source |
|----|--------------|----------|--------|
| BC-REF-01 | `parent_id` → `glb_menus.id` | RESTRICT | DDL |
| BC-INT-01 | `translations` morphMany → `glb_translations` | CASCADE (lang) | Model/DDL |
| BC-INT-02 | `modules` belongsToMany → `glb_menu_module_jnt` | — | Model |
| BC-INT-03 | Navbar (`App\View\Components\Backend\Partials\Navbar`) consumes menus for tenant nav | — | Component |

### BC-EDG
| ID | Edge | Source |
|----|------|--------|
| BC-EDG-01 | `show()` only authorizes, returns no body | Controller |
| BC-EDG-02 | edit/restore/forceDelete of missing id → 404 (`findOrFail`) | Controller |
| BC-EDG-03 | updateMenu with `parent_id=0` → treated as NULL (top-level) | Controller |
| BC-EDG-04 | Menu routes registered in **three** identical `system-config` groups (DUP-PRM-001) | routes/web.php |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-P01 | Config | BC-DB-* | DDL | Schema/model/request config truth | All asserts pass | test_menu_01 | ✅ |
| TC-P02 | Config | BC-AUTH-* | routes | Routes registered central.system-config.menu.* | Route::has true | test_menu_02 | ✅ |
| TC-P10 | Render | BC-BIZ-09 | Controller | Index loads cards+tabs | Cards/tabs shown | test_menu_10 | ✅ |
| TC-P11 | Render | BC-AUTH-01 | View | Prime tree container | Present | test_menu_11 | ✅ |
| TC-P12 | Render | BC-AUTH-01 | View | Tenant tree container | Present | test_menu_12 | ✅ |
| TC-P13 | Create | BC-BIZ-01/08 | Controller | Create prime menu persists+logs Stored | Row+slug+log | test_menu_13 | ✅ |
| TC-P14 | Biz | BC-BIZ-08 | Model | slug auto from title | Slugged | test_menu_14 | ✅ |
| TC-P15 | Biz | BC-BIZ-01 | Controller | menu_for default | prime | test_menu_15 | ✅ |
| TC-P16 | Biz | BC-BIZ-09 | Controller | summary counts by scope | Correct | test_menu_16 | ✅ |
| TC-P20 | SM | BC-SM-01/BC-BIZ-06 | Controller | toggleStatus flips is_active | Responds | test_menu_20 | ✅ |
| TC-P21 | SM | BC-BIZ-07 | Controller | reorder updates sort_order | 200 + updated | test_menu_21 | ✅ |
| TC-P60 | UX | — | View | Breadcrumb Menu Management | Seen | test_menu_60 | ✅ |
| TC-P61 | UX | — | View | Tab persistence via query | Active pane | test_menu_61 | ✅ |
| TC-P62 | UX | BC-EDG | View | Empty-state markup | Present | test_menu_62 | ✅ |
| TC-P63 | UX | BC-BIZ-10 | View | Route autocomplete input | Present | test_menu_63 | ✅ |
| TC-P64 | UX | BC-BIZ-10 | Controller | routeSuggestions JSON list | Array | test_menu_64 | ✅ |
| TC-P65 | UX | BC-BIZ-10 | Controller | scope=prime → central.* only | Filtered | test_menu_65 | ✅ |
| TC-P66 | UX | BC-BIZ-10 | Controller | filter by query term | Filtered | test_menu_66 | ✅ |

### Negative (TC-N)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-N22 | SM | BC-DB-10 | Controller | reorder category+parent | 422 | test_menu_22 | ✅ |
| TC-N23 | SM | BC-BIZ-07 | Controller | cross-scope move | 422 | test_menu_23 | ✅ |
| TC-N30 | Val | BC-VAL-01..04 | FormRequest | required fields | alert-danger | test_menu_30 | ✅ |
| TC-N31 | Val | BC-VAL-01 | FormRequest | dup code within scope | Rejected | test_menu_31 | ✅ |
| TC-N32 | Val | BC-VAL-01 | FormRequest | code>60 | max:60 | test_menu_32 | ✅ |
| TC-N33 | Val | BC-VAL-02 | FormRequest | title>100 | max:100 | test_menu_33 | ✅ |
| TC-N34 | Val | BC-VAL-04 | FormRequest | sort_order range | 0..255 | test_menu_34 | ✅ |
| TC-N35 | Val | BC-VAL-05 | FormRequest | invalid menu_for | in:prime,tenant | test_menu_35 | ✅ |
| TC-N36 | Val | BC-VAL-06 | FormRequest | bad parent_id | exists rule | test_menu_36 | ✅ |
| TC-N37 | Val | BC-BIZ-07 | Controller | updateMenu invalid | 422/302 | test_menu_37 | ✅ |
| TC-N38 | Val | BC-VAL-07 | FormRequest | route conditional | Rule present | test_menu_38 | ✅ |
| TC-N39 | Sec | BC-EDG | View | XSS title not executed | No exec | test_menu_39 | ✅ |
| TC-N50 | Auth | BC-AUTH | Middleware | guest → /login | Redirect | test_menu_50 | ✅ |
| TC-N51 | Auth | BC-AUTH-01 | Gate | index needs viewAny | 403 | test_menu_51 | ✅ |
| TC-N57 | Auth | BC-AUTH-04 | Controller | toggleStatus needs update | Gate string | test_menu_57 | ✅ |
| TC-N58 | Auth | BC-AUTH-02/01 | View | create form gated | @can | test_menu_58 | ✅ |
| TC-N59 | Auth | BC-AUTH-04/05 | View | tree actions gated | @can | test_menu_59 | ✅ |
| TC-N70 | Edge | BC-EDG-01 | Controller | show() authz-only | No body | test_menu_70 | ✅ |
| TC-N71 | Edge | BC-EDG-02 | Controller | edit missing id | 404 | test_menu_71 | ✅ |
| TC-N72 | Edge | BC-EDG-02 | Controller | restore missing id | 404 | test_menu_72 | ✅ |
| TC-N73 | Defect | DEV-PRM-MENU-001 | routes | toggle {user} vs Menu | Param mismatch | test_menu_73 | ✅ |
| TC-N74 | Defect | DEV-PRM-MENU-002 | DDL | global unique vs scoped val | Global index | test_menu_74 | ✅ |

### Dependency (TC-D) & Tenancy/Security (TC-T/S)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D24 | F | BC-SM-* | Controller | full lifecycle | All transitions | test_menu_24 | ✅ |
| TC-D40 | C | BC-REF-01 | DDL | parent FK RESTRICT | Blocked | test_menu_40 | ✅ |
| TC-D41 | B | BC-DB-09 | Model | soft-delete hides | Excluded | test_menu_41 | ✅ |
| TC-D42 | B | BC-AUTH-06 | View | trashed view | Lists trashed | test_menu_42 | ✅ |
| TC-D43 | B | BC-SM-03 | Controller | restore | Recovered | test_menu_43 | ✅ |
| TC-D44 | B | BC-SM-04 | Controller | force-delete | Gone | test_menu_44 | ✅ |
| TC-D45 | E | BC-INT-01 | Model | translations morph | glb_translations | test_menu_45 | ✅ |
| TC-D46 | E | BC-INT-02 | Model | modules pivot | glb_menu_module_jnt | test_menu_46 | ✅ |
| TC-T90 | Tenancy | — | Model | central connection, no tenancy | global_master | test_menu_90 | ✅ |
| TC-T91 | Tenancy | BC-BIZ-* | Constraint#25 | central activity sink + events | Verbatim | test_menu_91 | ✅ |
| TC-S92 | Sec | BC-BIZ-10 | Controller | reflected query not executed | JSON | test_menu_92 | ✅ |
| TC-S93 | Sec | — | routes | GET on POST toggle | 405/404/302 | test_menu_93 | ✅ |

---

## 3. Known Source Defects (documented, with proving tests)
| ID | Sev | Description | Proving test |
|----|-----|-------------|--------------|
| DEV-PRM-MENU-001 | P2 | `toggleStatus` route param `{user}` ≠ controller `Menu $menu` → implicit binding broken; controller acts on an unbound empty model | test_menu_73 |
| DEV-PRM-MENU-002 | P2 | DB `uq_glb_menus_code` is **global** unique, but FormRequest scopes code uniqueness by `menu_for` → same code across prime/tenant passes validation then 500s at DB | test_menu_74 |
| DEV-PRM-MENU-003 | P3 | `menu_for`/`permission` used by model+controller but absent from consolidated DDL (schema drift) | test_menu_01 (fail-soft) |
| DEV-PRM-MENU-004 | P3 | `MenuRequest` route-required condition is inverted for categories/top-level leaves (category requires route; top-level leaf doesn't) | test_menu_38 (documents rule) |
| DEV-PRM-MENU-005 | P4 | `is_direct_link` validated in FormRequest but not fillable/no column → silently dropped | (noted in Gap) |
| PERF-PRM-002 | P2 | `Navbar::resolveActiveMainMenu()` calls `Menu::find()` in a `while` loop (N+1 by menu depth). In Blade component `App\View\Components\Backend\Partials\Navbar` — **DEAD-PRM-001**: Blade component, not a route file (static-only) | Gap (static) |
| DUP-PRM-001 | P4 | Menu routes registered in 3 identical `system-config` groups | test_menu_02 context |

## 4. Test Method Index
| # | Method | TC | Band |
|---|--------|----|------|
| 1 | test_menu_01_schema_model_and_request_configuration_are_correct | TC-P01 | 01–09 |
| 2 | test_menu_02_menu_routes_are_registered_under_central_system_config | TC-P02 | 01–09 |
| 3–9 | test_menu_10..16 | TC-P10..P16 | 10–19 |
| 10–14 | test_menu_20..24 | TC-P20/P21/N22/N23/D24 | 20–29 |
| 15–24 | test_menu_30..39 | TC-N30..N39 | 30–39 |
| 25–31 | test_menu_40..46 | TC-D40..D46 | 40–49 |
| 32–36 | test_menu_50/51/57/58/59 | TC-N50/N51/N57/N58/N59 | 50–59 |
| 37–43 | test_menu_60..66 | TC-P60..P66 | 60–69 |
| 44–48 | test_menu_70..74 | TC-N70..N74 | 70–79 |
| 49–52 | test_menu_90..93 | TC-T90/T91/S92/S93 | 90–99 |

**Total: 52 test methods.**
