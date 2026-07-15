# UserRolePrm — Manual Testing Specification (`sys_`)

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Prime (PRM) — **central / `prime_db`, no tenancy** |
| Feature | UserRolePrm — user ↔ role assignment / junction screen |
| URL | `http://127.0.0.1:8000/prime/user-role-prm` |
| Route names | `central.prime.user-role-prm.{index,create,store,show,edit,update,destroy,search}` |
| Controller | `Modules\Prime\Http\Controllers\UserRolePrmController` |
| Models | `Modules\Prime\Models\{User (sys_users), Role (sys_roles), Permission (sys_permissions), ActivityLog (sys_central_activity_logs)}` |
| Junction table | `sys_model_has_roles_jnt` (`role_id`, `model_type`, `model_id`) |
| View gate | `prime.role-permission.viewAny` (index only) |
| Validation | None (no FormRequest — controller reads raw `Request`) |
| CRUD type | Read + filter + name-search only; assignment CRUD is **stubbed** |
| Soft delete | `sys_users` yes; `sys_roles` no; junction no |
| Pagination | 10/page (users and roles tabs) |
| Activity log | **None in this controller** (DEV-URP-005) |
| Prerequisites | Prime central routes reachable on `127.0.0.1:8000`; `APP_ENV=testing`; admin `root@tenant.com` |

> **Environment prerequisite (E19):** the Prime area must be reachable and the admin user verified. Central Prime routes are registered in `prime_ai/routes/web.php` under the `central.` → `prime.` group (constraint 24), not in the module's own `routes/web.php`.

---

## 2. Business Conditions (detailed)

**Junction mechanics.** `sys_model_has_roles_jnt` links a `sys_roles.id` (`role_id`) to a user (`model_id`) discriminated by `model_type`. Because of `AppServiceProvider::morphMap(['user' => Modules\Prime\Models\User::class])`, the stored `model_type` for a Prime user is the alias **`user`**, and Spatie resolves `$user->roles` via `model_id` (config `model_morph_key = model_id`). The **composite PK `(role_id, model_id, model_type)`** is the only uniqueness guard against duplicate grants. FK `role_id → sys_roles ON DELETE CASCADE` removes grants when a role is hard-deleted; there is **no** FK on `model_id`, so soft/hard-deleting a user leaves the pivot row untouched.

**Index behaviour.** `index()` builds `User::with('roles')->orderBy('is_super_admin','DESC')->orderBy('name','ASC')` and applies three filters: `role` (`all` | `no-role` | a `sys_roles.id`), `search` (LIKE on `name` OR `email`), `status` (`is_active`). Paginated 10/page. Summary cards show Total / Active / Super-Admin / No-Role counts.

**Search endpoint.** `GET /prime/user-role-prm/search?q=&type=` returns `[]` if `q` or `type` is empty; for `type=user` returns up to 10 `{id,name}` matched on name LIKE; for `type=role` the same on roles; any other type → `[]`. **No authorization gate** (DEV-URP-002).

**Stub methods.** `create()/show()/edit()` → `view('prime::create'|'show'|'edit')` which do not exist → 500. `store()/update()/destroy()` are empty → no persistence, empty response (DEV-URP-003/004).

---

## 3. Manual Test Cases

### MTC-01 — Schema & config truth (automatable)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect DB | `sys_model_has_roles_jnt`, `sys_roles`, `sys_users`, `sys_permissions` exist |
| 2 | `SHOW COLUMNS FROM sys_model_has_roles_jnt` | `role_id`, `model_type`, `model_id` present |
| 3 | `SHOW INDEX FROM sys_model_has_roles_jnt` | PRIMARY key over `(role_id, model_id, model_type)` |
| 4 | Check `config('permission.table_names.model_has_roles')` | `sys_model_has_roles_jnt` |
| 5 | Check `config('permission.column_names.model_morph_key')` | `model_id` |
| 6 | `Route::has('central.prime.user-role-prm.search')` | true |

### MTC-02 — Index loads (User tab)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as `root@tenant.com` | Dashboard |
| 2 | Visit `/prime/user-role-prm` | Page "User Roles & Permissions" |
| 3 | Observe | 4 summary cards + user table with Name/Contact/Role columns |
| 4 | DB check | `SELECT COUNT(*) FROM sys_users` matches "Total Users" card |

### MTC-03 — Assign a role (junction, DB-level)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create role R and user U | rows in `sys_roles`, `sys_users` |
| 2 | Insert `(role_id=R, model_type='user', model_id=U)` | row created |
| 3 | Visit `/prime/user-role-prm?tab=user&role=R` | U appears with badge "R" |
| 4 | DB check | `SELECT * FROM sys_model_has_roles_jnt WHERE role_id=R AND model_id=U` returns 1 |

### MTC-04 — Duplicate grant rejected
| Step | Action | Expected |
|------|--------|----------|
| 1 | With row from MTC-03, insert the same triple again | INSERT fails (PK violation) |
| 2 | DB check | count for the pair remains 1 |

### MTC-05 — Role delete cascades
| Step | Action | Expected |
|------|--------|----------|
| 1 | `DELETE FROM sys_roles WHERE id=R` | role removed |
| 2 | DB check | `sys_model_has_roles_jnt WHERE role_id=R` returns 0 (ON DELETE CASCADE) |

### MTC-06 — User soft-delete retains grant
| Step | Action | Expected |
|------|--------|----------|
| 1 | Grant role to user U | pivot row exists |
| 2 | Soft-delete U (`deleted_at` set) | user hidden |
| 3 | DB check | pivot row for `model_id=U` still present |

### MTC-07 — Search endpoint
| Step | Action | Expected |
|------|--------|----------|
| 1 | `GET /prime/user-role-prm/search?q=Zeta&type=user` | JSON array of `{id,name}` |
| 2 | `GET .../search?type=user` (no q) | `[]` |
| 3 | `GET .../search?q=x` (no type) | `[]` |
| 4 | `GET .../search?q=x&type=elephant` | `[]` |
| 5 | Seed 12 matching users, search | ≤10 rows |
| 6 | Inspect a row | only keys `id`, `name` (no email/password) |

### MTC-08 — Authorization
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logout, visit `/prime/user-role-prm` | redirect to `/login` |
| 2 | Login as user without `prime.role-permission.viewAny` | 403 on index |
| 3 | Same user hits `/search?q=a&type=user` | **200 with data** (DEV-URP-002 — should be 403) |

### MTC-09 — Stub endpoints (defects)
| Step | Action | Expected (current) |
|------|--------|--------------------|
| 1 | Visit `/prime/user-role-prm/create` | 500 (view `prime::create` missing) — DEV-URP-003 |
| 2 | POST `/prime/user-role-prm` | empty response, no DB change — DEV-URP-004 |
| 3 | DB check after step 2 | `sys_model_has_roles_jnt` count unchanged |

### MTC-10 — Filters & UX
| Step | Action | Expected |
|------|--------|----------|
| 1 | `?tab=user&role=no-role` | only users with 0 roles |
| 2 | `?tab=user&search=<name>` | matching users |
| 3 | `?tab=user&status=1` | active users only |
| 4 | `?tab=user&search=zzz_no_match` | "No users found for this filter." |
| 5 | Reset link | filters cleared |
| 6 | `?tab=role-permisons` | role pane active |

### MTC-11 — Activity log absence (defect)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Note `SELECT COUNT(*) FROM sys_central_activity_logs` | baseline |
| 2 | View index / run a search | (no controller logging) |
| 3 | Re-count | **unchanged** — DEV-URP-005 |

### MTC-12 — Security smoke
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create user named `XSS<script>alert(1)</script>` | stored |
| 2 | `GET /search?q=XSS&type=user` | `Content-Type: application/json`; payload not executable HTML |
| 3 | `GET /search?q=%_%&type=user` | 200, no SQL error |
