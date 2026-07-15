# Role & Permission (PRM) — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Prime (PRM) — **CENTRAL / prime_db** |
| Feature | RolePermission |
| Base URL | `http://127.0.0.1:8000/prime/role-permission` |
| Controller | `Modules\Prime\Http\Controllers\RolePermissionController` |
| FormRequest | `Modules\Prime\Http\Requests\RolePermissionRequest` |
| Models | `Modules\Prime\Models\Role` (Spatie Role, table `sys_roles`), `Permission` (Spatie, `sys_permissions`) |
| Pivot | `sys_role_has_permissions_jnt` |
| Validation | name/short_name unique on `sys_roles`; short_name max 20; description max 255; permissions[] exist in `sys_permissions` |
| CRUD type | Full-page create/edit (NOT modal); index + show + trash views |
| Soft delete | **DISABLED** — no `deleted_at` in `sys_roles`, no SoftDeletes trait → deletes are permanent |
| Pagination | Server-rendered role table |
| Activity log | `sys_central_activity_logs` (central) — events `Stored`, `Updated`, `Toggled` (destroy), `Deleted` (forceDelete) |
| Permission gates | `prime.role-permission.{viewAny,view,create,update,delete,restore,forceDelete}` |

### Environment prerequisites
- Prime module **enabled** in `prime_testing/modules_statuses.json` (else all routes 404).
- Run on host `http://127.0.0.1:8000` (`PrimeDuskTestCase` fails otherwise).
- `APP_ENV=testing` (CSRF bypass for state-changing requests).
- A super-admin user resolvable (`is_super_admin = 1`) for privileged flows.

---

## 2. Business Conditions (detailed)

### Authorization matrix
| Action | Route | Gate |
|--------|-------|------|
| List | `central.prime.role-permission.index` | `prime.role-permission.viewAny` |
| Create form | `central.prime.role-permission.create` | `prime.role-permission.create` |
| Store | `central.prime.role-permission.store` | `prime.role-permission.create` |
| Show | `central.prime.role-permission.show` | `prime.role-permission.view` |
| Edit form | `central.prime.role-permission.edit` | `prime.role-permission.update` |
| Update | `central.prime.role-permission.update` | `prime.role-permission.update` |
| Destroy | `central.prime.role-permission.destroy` | `prime.role-permission.delete` |
| Trashed (stub) | `central.prime.role-permission.trashed` | `prime.role-permission.restore` |
| Restore (stub) | `central.prime.role-permission.restore` | `prime.role-permission.restore` |
| Force delete | `central.prime.role-permission.forceDelete` | `prime.role-permission.forceDelete` |
| Toggle single permission | `central.prime.role-permission.updateRolePermission` | `prime.role-permission.update` |
| Bulk permissions (unnamed) | `POST /prime/role-permission/{role}/permissions/update` | `prime.role-permission.update` |
| Get permissions (unnamed) | `GET /prime/role-permission/{role}/permissions` | `prime.role-permission.view` **(SEC-PRM-001 remediated)** |

### Activity-log flow
```
store()       -> activityLog(role, 'Stored',  {message, other})
update()      -> activityLog(role, 'Updated', {message, changes:{field:{old,new}}, performed_by})
destroy()     -> activityLog(role, 'Toggled', {message, other})   [DEV-PRM-010: mislabel]
forceDelete() -> activityLog(role, 'Deleted', {message})
```
All rows land in `sys_central_activity_logs` (tenancy not initialised).

---

## 3. Manual Test Cases

### MT-01 — Store a role with permissions (happy path)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as super admin; open `/prime/role-permission/create` | Create form with `name`, `short_name`, `description`, `is_system`, grouped permission checkboxes |
| 2 | Fill name `QA Role <uniq>`, short_name `qa<uniq>` (≤20), select ≥1 permission | Fields accept input |
| 3 | Submit | Redirect to user-role management with success flash |
| 4 | DB check | `SELECT * FROM sys_roles WHERE name='QA Role <uniq>'` → 1 row |
| 5 | Pivot check | `SELECT COUNT(*) FROM sys_role_has_permissions_jnt WHERE role_id=<id>` → ≥1 |
| 6 | Activity check | `SELECT event FROM sys_central_activity_logs WHERE subject_id=<id>` → `Stored` |

### MT-02 — Validation failures
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit create with empty name | Error: name required |
| 2 | Submit with existing name | Error: name unique on `sys_roles` |
| 3 | short_name 21+ chars | Error: max 20 |
| 4 | description 256+ chars | Error: max 255 |
| 5 | permissions = [] | Error: permissions required |
| 6 | permissions = ['bogus.perm'] | Error: must exist in `sys_permissions` |

### MT-03 — Delete is permanent (no soft delete)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete a role via destroy | Redirect + success flash |
| 2 | DB check | `SELECT * FROM sys_roles WHERE id=<id>` → 0 rows (row gone, not soft-deleted) |
| 3 | Pivot cascade | `SELECT COUNT(*) FROM sys_role_has_permissions_jnt WHERE role_id=<id>` → 0 |
| 4 | Activity check | event = `Toggled` **(DEV-PRM-010 — mislabel for a delete)** |
| 5 | Open Trash view | Redirect with info "Soft deletes are not enabled for roles." **(DEV-PRM-011)** |

### MT-04 — SEC-PRM-001: getPermissions authorization
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as **non-privileged** user (no `prime.role-permission.view`) | Authenticated session |
| 2 | `GET /prime/role-permission/{roleId}/permissions` | **403 Forbidden** (gate now enforced — remediated) |
| 3 | Config check | Controller `getPermissions()` contains `Gate::authorize('prime.role-permission.view')` (line 313) |
| 4 | Regression guard | If step 2 returns 200 + permissions JSON → SEC-PRM-001 has regressed (P0) |

### MT-05 — DEV-PRM-012: inline permission endpoints
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect `updateRolePermission()` validation | `exists:permissions,name` — references literal `permissions` table |
| 2 | DB check | `SHOW TABLES LIKE 'permissions'` → none; real table is `sys_permissions` |
| 3 | Conclusion | Rule can never match on this schema → toggle-single-permission endpoint is broken |

### MT-06 — Guest / auth
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logout; visit `/prime/role-permission` | Redirect to `/login` (302) |
| 2 | Unauthenticated `POST /prime/role-permission` | Blocked (302/401/419) |
