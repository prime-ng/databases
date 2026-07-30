# Prime — User Role PRM (Combined Tab View)

**Feature:** User Role PRM (Combined User/Role/Permission View) | **REQ-ID:** REQ-PRM-007 / REQ-PRM-008 | **Priority:** P0 (MUST)

---

## 1. Description

The User Role PRM feature provides a combined tabbed interface that consolidates User Management and Role & Permission Management into a single unified view. It serves as the primary landing page for platform staff administration. The view has two tabs: "User" (listing platform staff with filters) and "Role-Permissions" (listing roles with their permissions). It also provides a search endpoint for AJAX-powered user and role lookups.

**Key Capabilities:**
- Tabbed interface: User tab and Role-Permissions tab
- User list with filters: role dropdown (all, specific role, no-role), search (name/email), status (active/inactive)
- Role-Permissions list with paginated roles and eager-loaded permissions
- Stats dashboard: totalUsers, activeUsers, superAdminCount, noRoleCount
- Separated pagination for each tab with preserved query strings and fragments
- Search API endpoint for users (by name) and roles (by name)

---

## 2. Controller & Model

| Artifact | Path | Lines | Status |
|----------|------|:-----:|--------|
| Controller | `Modules/Prime/app/Http/Controllers/UserRolePrmController.php` | 155 | PARTIAL |
| Models | `User` (`Modules\Prime\Models\User`), `Role` (`Modules\Prime\Models\Role`), `Permission` (`Modules\Prime\Models\Permission`) | — | PARTIAL |
| Views | `prime::user-role-permission.index`, `prime::create`, `prime::show`, `prime::edit` | — | EXISTS |

**Note:** This controller primarily handles the `index` (combined view) and `search` actions. The standard resource actions (`create`, `store`, `show`, `edit`, `update`, `destroy`) are stubs that return empty views or do nothing — actual CRUD operations are handled by `UserController` and `RolePermissionController`.

---

## 3. Routes

| Method | URI | Action | Permission | Status |
|--------|-----|--------|------------|--------|
| GET | `/prime/user-role-prm` | `index` | `prime.role-permission.viewAny` | ✅ Gate check present |
| GET | `/prime/user-role-prm/search` | `search` | — | ✅ No auth on search |
| GET | `/prime/user-role-prm/create` | `create` | — | ❌ Stub (returns empty view) |
| POST | `/prime/user-role-prm` | `store` | — | ❌ Stub (no-op) |
| GET | `/prime/user-role-prm/{user_role_prm}` | `show` | — | ❌ Stub (returns empty view) |
| GET | `/prime/user-role-prm/{user_role_prm}/edit` | `edit` | — | ❌ Stub (returns empty view) |
| PUT | `/prime/user-role-prm/{user_role_prm}` | `update` | — | ❌ Stub (no-op) |
| DELETE | `/prime/user-role-prm/{user_role_prm}` | `destroy` | — | ❌ Stub (no-op) |

---

## 4. Data Model

This feature uses the same models as User Management and Role & Permission Management:

- **User:** `sys_users` table (see `prm_UserManagement_Requirement.md` §4)
- **Role:** `sys_roles` table (see `prm_RolePermission_Requirement.md` §4)
- **Permission:** `sys_permissions` table (see `prm_RolePermission_Requirement.md` §4)

---

## 5. Controller Implementation Details

### 5.1 `index(Request $request)`

- **Gate:** `Gate::authorize('prime.role-permission.viewAny')` — uses role-permission gate
- **Active Tab:** Determined by `$request->get('tab', 'user')` — defaults to 'user'
- **Role-Permissions Tab Data:**
  - `$allRoles` — All roles with user count (`Role::withCount('users')->orderBy('name')->get()`) for filter dropdown
  - `$roles` — Paginated (10) roles with permissions, custom page name `role-permisons_page`, with tab fragment `#role-permisons`
  - `$permissions` — All permissions for the permission display
- **User Tab Data:**
  - `$selectedRole` — Filter by role: 'all' (default), specific role ID, or 'no-role'
  - `$search` — Search by name or email (LIKE %search%)
  - `$status` — Filter by is_active (0 or 1)
  - Query: `User::with('roles')->orderBy('is_super_admin', 'DESC')->orderBy('name', 'ASC')`
    - If 'no-role': `doesntHave('roles')`
    - If specific role: `whereHas('roles', fn => where('sys_roles.id', $selectedRole))`
    - Search applied as `where name LIKE or email LIKE`
    - Status filter applied as `where is_active = $status`
  - Paginated (10) with custom page name `user_page`, with tab fragment `#user`
- **Stats:** `$totalUsers`, `$activeUsers` (is_active=true), `$superAdminCount` (is_super_admin=true), `$noRoleCount` (doesntHave roles)
- **View:** `prime::user-role-permission.index` with compact data for all variables

### 5.2 `search(Request $request)` — JSON

- **Parameters:** `q` (search query), `type` ('user' or 'role')
- **Validation:** If no `q` or no `type`, returns empty array
- **User Search:** `User::where('name', 'LIKE', "%{$q}%")->orderBy('name')->limit(10)->get(['id', 'name'])`
- **Role Search:** `Role::where('name', 'LIKE', "%{$q}%")->orderBy('name')->limit(10)->get(['id', 'name'])`
- **Response:** JSON array of objects with `id` and `name` fields

### 5.3 Stub Methods

| Method | Action |
|--------|--------|
| `create()` | Returns `view('prime::create')` |
| `store()` | No-op (empty method body) |
| `show($id)` | Returns `view('prime::show')` |
| `edit($id)` | Returns `view('prime::edit')` |
| `update($request, $id)` | No-op (empty method body) |
| `destroy($id)` | No-op (empty method body) |

---

## 6. Business Rules

| BR-ID | Rule | Verification |
|-------|------|:-----------:|
| BR-PRM-023 | State-changing operations should produce activity log | ❌ Not applicable — this is primarily a read/search view |

---

## 7. Security Rules

| Rule | Implementation |
|------|---------------|
| Gate check on `index` | ✅ Uses `prime.role-permission.viewAny` |
| Search endpoint unprotected | ⚠️ `search()` has no Gate check — returns user/role names without authentication check |

---

## 8. Gaps & Known Issues

| # | Issue | Impact | Severity | Status |
|---|-------|--------|:--------:|:------:|
| 1 | `search()` endpoint has no authorization gate — any unauthenticated user can search for users and roles by name | Security — Information disclosure | P1 — High | ⬜ |
| 2 | All resource CRUD methods (except index) are stubs — actual operations are handled by UserController and RolePermissionController | Architecture (by design) | — | ⬜ |
| 3 | No feature tests exist for UserRolePrmController | Testing gap | P2 — Medium | ⬜ |

---

## 9. FRD References

| Reference | Source | Summary |
|-----------|--------|---------|
| REQ-PRM-007 | FRD §1.3 | Central Staff User Management — list, filter, search |
| REQ-PRM-008 | FRD §1.3 | Role and Permission Management — list with permissions |
| US-PRM-007 | FRD §8.1 | User story for platform staff management |
| US-PRM-008 | FRD §8.1 | User story for role and permission management |

---

## 10. Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| V1 | — | — | — |
| V2 | — | — | — |
