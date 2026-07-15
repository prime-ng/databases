# Menu (PRM / Central) — Manual Testing Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Prime (PRM) |
| Feature / Screen | Menu (Menu Management) |
| URL | `http://127.0.0.1:8000/system-config/menu` (central domain) |
| Trash URL | `/system-config/menu/trash/view` |
| Controller | `Modules\Prime\Http\Controllers\MenuController` |
| Model(s) | `Modules\Prime\Models\Menu` (table `glb_menus`, conn `global_master_mysql`), `MenuModule` |
| FormRequest | `Modules\SystemConfig\Http\Requests\MenuRequest` |
| Route names | `central.system-config.menu.{index,create,store,show,edit,update,destroy,trashed,restore,forceDelete,toggleStatus,updateMenu,routeSuggestions}` |
| Permissions | `prime.menu.{viewAny,view,create,update,delete,restore,forceDelete}` |
| CRUD type | Inline create form (no modal) + full-page edit + tree view with drag-drop reorder |
| Soft delete | Yes (`deleted_at`) |
| Pagination | None (tree, capped-height scroll) |
| Activity log | Central `sys_central_activity_logs` — events `Stored / Updated / Trashed / Restored / Deleted / Toggled / Draggable Menu` |
| DB scope | CENTRAL — **no tenant initialization** |

**Prefix note:** feature prefix is `glb_` (primary table `glb_menus`), which differs from the registry PRM prefix `prm_`. Flagged.

**Environment prerequisites:** Prime/SystemConfig module enabled in `modules_statuses.json`; app served at `http://127.0.0.1:8000`; `APP_ENV=testing` for Dusk (CSRF bypass); central admin (`is_super_admin=1`) present.

---

## 2. Business Conditions (detailed)

### Validation error flow (`MenuRequest`)
- `code`: required · string · max 60 · unique in `glb_menus` scoped by `menu_for` (ignore self on update).
- `title`: required · string · max 100 · unique scoped by `menu_for`.
- `icon`: required · string · max 150.
- `sort_order`: required · integer · 0–255.
- `menu_for`: optional · one of `prime|tenant`.
- `parent_id`: nullable · must `exists:glb_menus,id`.
- `route`: required (+ `ValidCombinedRoute`) **unless** `parent_id` is null AND `is_category` is not true.
- Checkboxes (`is_active`, `is_category`, `is_direct_link`, `visible_by_default`) cast to boolean before validation.

### Activity-log flow (central sink)
```
store       → activityLog(menu,'Stored',   {message:'A new menu was created.'})
update      → activityLog(menu,'Updated',  {message, changes:{field:{old,new}}, performed_by})
destroy     → is_active=false; delete();    activityLog(menu,'Trashed')
restore     → restore();                    activityLog(menu,'Restored')
forceDelete → forceDelete();                activityLog(menu,'Deleted')
toggleStatus→ is_active=!is_active;          activityLog(menu,'Toggled', {changes})
updateMenu  → parent_id/sort_order + siblings normalise; activityLog(menu,'Draggable Menu')
```
All land in `sys_central_activity_logs` because tenancy is not initialized (Constraint #25).

### Flash messages (config/flash.php via `flash('key.menu')`)
| Key | Rendered text |
|-----|---------------|
| `created.menu` | "Menu was created successfully." |
| `updated.menu` | "Menu was updated successfully." |
| `trashed.menu` | "Menu was moved to trash." |
| `restored.menu` | "Menu was restored successfully." |
| `force_deleted.menu` | "Menu was permanently deleted." |
| `menu_order_updated.menu` | "The order of Menu was updated successfully." |
| `menu_order_update_failed.menu` | "Failed to update the order of Menu." |

---

## 3. Manual Test Cases

### TC-P10 — Index renders
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as central admin; open `/system-config/menu` | Page loads on central domain |
| 2 | Observe header | Breadcrumb "Menu Management" |
| 3 | Observe cards | Prime Menus / Prime Categories / Tenant Menus / Tenant Categories counts |
| 4 | Observe tabs | "Prime Menus" (`#prime-tab`) + "Tenant Menus" (`#tenant-tab`) |
| DB | `SELECT count(*) FROM glb_menus WHERE menu_for='prime'` | equals Prime Menus card |

### TC-P13 — Create prime category menu
| Step | Action | Expected |
|------|--------|----------|
| 1 | On Prime tab, fill Title, Code (unique), Icon; tick "Is Category"; Sort Order | — |
| 2 | Click "Add Menu" | Redirect to `?tab=prime`, green toast "Menu was created successfully." |
| DB | `SELECT * FROM glb_menus WHERE code=?` | 1 row, `menu_for='prime'`, `slug=slug(title)` |
| Log | `SELECT event FROM sys_central_activity_logs WHERE subject_id=? ORDER BY id DESC LIMIT 1` | `Stored` |

### TC-P20 — Toggle status (JSON)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/system-config/menu/{id}/toggle-status` (authenticated fetch) | JSON responds |
| Log | latest event for subject | `Toggled` |
| ⚠️ | Note DEV-PRM-MENU-001 — route param `{user}` prevents Menu binding | endpoint may act on unbound model |

### TC-P21 — Drag-drop reorder (JSON)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/system-config/menu/update-menu` `{menu_id, parent_id:0, sort_order:3}` | 200, `{success:true, message:"The order of Menu was updated successfully."}` |
| DB | `SELECT sort_order FROM glb_menus WHERE id=?` | 3 |
| Log | latest event | `Draggable Menu` |

### TC-N22 — Category cannot be nested
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST update-menu with `menu_id`=category, `parent_id`=some parent | 422, message "Failed to update the order of Menu." |

### TC-N23 — Cross-scope move blocked
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST update-menu moving a prime menu under a tenant parent | 422, "Cannot move menu across scopes (prime/tenant)." |

### TC-N30 — Required fields
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit create form empty (browser `required` removed) | Redirect back, `.alert-danger` lists errors |

### TC-N31 — Duplicate code within scope
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create two prime menus with same code | 2nd rejected (unique) |
| DB | `SELECT count(*) FROM glb_menus WHERE code=? AND menu_for='prime'` | 1 |

### TC-N50 — Guest redirect
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logout, open `/system-config/menu` | Redirect to `/login` |

### TC-N51 — viewAny gate
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as user without `prime.menu.viewAny`; open index | 403 Forbidden |

### TC-D24 — Full lifecycle
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create → edit → toggle → destroy → restore → forceDelete | Each transition succeeds; final `SELECT` returns 0 rows |

### TC-D40 — FK RESTRICT
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create parent + child; hard-delete parent at DB | FK constraint blocks deletion |

### TC-N71 / TC-N72 — 404 on missing id
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/system-config/menu/999999999/edit` | 404 |
| 2 | GET `/system-config/menu/999999999/restore` | 404 (findOrFail) |

### TC-P64 — routeSuggestions
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/system-config/menu/route-suggestions?q=menu` | JSON array of route names (≤30) |
| 2 | `?scope=prime&q=menu` | only names starting `central.` |

### TC-T91 — Central activity sink
| Step | Action | Expected |
|------|--------|----------|
| 1 | Any mutation, then inspect | Row lands in `sys_central_activity_logs` (not tenant `activity_logs`) with verbatim event string |
