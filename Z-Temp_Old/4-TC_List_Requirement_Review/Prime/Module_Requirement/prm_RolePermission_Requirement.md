# Prime — Role & Permission Management

**Feature:** Role & Permission Management | **REQ-ID:** REQ-PRM-008 | **Priority:** P0 (MUST)

---

## 1. Description

The Role & Permission Management feature enables Super Admins to create and manage central platform roles. Each role receives a set of permissions following the pattern "module.feature.action" (e.g., "prime.tenant.create"). Permissions can be toggled individually or synced in bulk. Roles can be assigned to platform users through the User Management feature. The feature handles the complete lifecycle of roles (CRUD) and provides dedicated endpoints for permission querying and updating.

**Key Capabilities:**
- Create roles with name, short_name, description, organization_id, and is_system flag
- View all roles with their associated permissions (structured by module → feature → action)
- Edit role metadata and sync permissions in bulk
- Filter roles by organization
- Soft-delete roles (trashed view), restore, and force-delete
- Dedicated endpoints for toggling individual permissions via AJAX
- Dedicated endpoint for bulk permission sync
- Dedicated endpoint for retrieving a role's permission list as JSON
- Permissions are grouped by Module and Feature for hierarchical display

---

## 2. Controller & Model

| Artifact | Path | Lines | Status |
|----------|------|:-----:|--------|
| Controller | `Modules/Prime/app/Http/Controllers/RolePermissionController.php` | 319 | PARTIAL |
| Model (Role) | `Modules/Prime/app/Models/Role.php` | — | PARTIAL |
| Model (Permission) | `Modules/Prime/app/Models/Permission.php` | — | PARTIAL |
| Form Request | `Modules/Prime/app/Http/Requests/RolePermissionRequest.php` | 65 | EXISTS |
| View (index) | `prime::role-permission.index` | — | EXISTS |
| View (create) | `prime::role-permission.create` | — | EXISTS |
| View (show) | `prime::role-permission.show` | — | EXISTS |
| View (edit) | `prime::role-permission.edit` | — | EXISTS |

**Models:** Uses Spatie Permission package tables:
- `sys_roles` — Role table with Spatie `HasRoles` trait
- `sys_permissions` — Permission table with Spatie `HasPermissions` trait
- `sys_role_has_permissions_jnt` — Role-permission junction table
- `sys_model_has_roles_jnt` — User-role assignment table
- `sys_model_has_permissions_jnt` — Direct user-permission assignment table

---

## 3. Routes

| Method | URI | Action | Permission | Status |
|--------|-----|--------|------------|--------|
| GET | `/prime/role-permission` | `index` | `prime.role-permission.viewAny` | ✅ Gate check present |
| GET | `/prime/role-permission/create` | `create` | `prime.role-permission.create` | ✅ Gate check present |
| POST | `/prime/role-permission` | `store` | `prime.role-permission.create` | ✅ Gate check present |
| GET | `/prime/role-permission/{role_permission}` | `show` | `prime.role-permission.view` | ✅ Gate check present |
| GET | `/prime/role-permission/{role_permission}/edit` | `edit` | `prime.role-permission.update` | ✅ Gate check present |
| PUT | `/prime/role-permission/{role_permission}` | `update` | `prime.role-permission.update` | ✅ Gate check present |
| DELETE | `/prime/role-permission/{role_permission}` | `destroy` | `prime.role-permission.delete` | ✅ Gate check present |
| GET | `/prime/role-permission/{organization}/get-roles` | `getRolesByOrganization` | `prime.role-permission.viewAny` | ✅ Gate check present |
| GET | `/prime/role-permission/trash/view` | `trashedRolePermission` | `prime.role-permission.restore` | ✅ (returns info about no soft-deletes) |
| GET | `/prime/role-permission/{id}/restore` | `restore` | `prime.role-permission.restore` | ✅ (returns info about no soft-deletes) |
| DELETE | `/prime/role-permission/{id}/force-delete` | `forceDelete` | `prime.role-permission.forceDelete` | ✅ Gate check present |
| PATCH | `/prime/role-permission/{role}/update` | `updateRolePermission` | `prime.role-permission.update` | ✅ Gate check present |
| GET | `/prime/role-permission/{role}/permissions` | `getPermissions` | `prime.role-permission.view` | ✅ Gate check present |
| POST | `/prime/role-permission/{role}/permissions/update` | `updatePermissions` | `prime.role-permission.update` | ✅ Gate check present |

---

## 4. Data Model

### 4.1 Role (`sys_roles` — prime_db)

| Column | Type | Required | Default | Notes |
|--------|------|:--------:|:-------:|-------|
| `id` | INT UNSIGNED AUTO_INCREMENT | ✅ | — | Primary key |
| `name` | VARCHAR(50) | ✅ | — | UNIQUE with guard_name |
| `short_name` | VARCHAR(20) | ✅ | — | UNIQUE with guard_name; dropdown display |
| `description` | VARCHAR(255) | — | NULL | Role description |
| `guard_name` | VARCHAR(255) | ✅ | — | Laravel guard (typically 'web') |
| `is_system` | TINYINT(1) | ✅ | 0 | If true, role belongs to PrimeGurukul system |
| `is_active` | TINYINT(1) | ✅ | 1 | — |
| `created_at` | TIMESTAMP | — | — | — |
| `updated_at` | TIMESTAMP | — | — | — |

### 4.2 Permission (`sys_permissions` — prime_db)

| Column | Type | Required | Default | Notes |
|--------|------|:--------:|:-------:|-------|
| `id` | INT UNSIGNED AUTO_INCREMENT | ✅ | — | Primary key |
| `short_name` | VARCHAR(20) | ✅ | — | UNIQUE with guard_name |
| `name` | VARCHAR(100) | ✅ | — | Format: `module.feature.action` (e.g., `prime.tenant.create`) |
| `guard_name` | VARCHAR(255) | ✅ | — | Laravel guard |
| `is_active` | TINYINT(1) | ✅ | 1 | — |
| `created_at` | TIMESTAMP | — | — | — |
| `updated_at` | TIMESTAMP | — | — | — |

### 4.3 Junction Tables

| Table | Columns | Foreign Keys |
|-------|---------|-------------|
| `sys_role_has_permissions_jnt` | permission_id, role_id | permission_id → sys_permissions.id ON DELETE CASCADE; role_id → sys_roles.id ON DELETE CASCADE |
| `sys_model_has_roles_jnt` | role_id, model_type, model_id | role_id → sys_roles.id ON DELETE CASCADE |
| `sys_model_has_permissions_jnt` | permission_id, model_type, model_id | permission_id → sys_permissions.id ON DELETE CASCADE |

---

## 5. Controller Implementation Details

### 5.1 `index()`

- **Gate:** `Gate::authorize('prime.role-permission.viewAny')`
- **Query:** `Role::with('permissions')->get()` — all roles with eager-loaded permissions
- **Data:** Also loads all permissions via `Permission::all()`
- **View:** `prime::role-permission.index` with `compact('roles', 'permissions')`

### 5.2 `getRolesByOrganization(string $organizationId)`

- **Gate:** `Gate::authorize('prime.role-permission.viewAny')`
- **Query:** Finds Organization, then `Role::where('organization_id', $organizationId)->with('permissions')->get()`
- **Data:** Also loads all permissions and all organizations
- **View:** Same index view with `compact('roles', 'permissions', 'organizations', 'organization')`

### 5.3 `create()`

- **Gate:** `Gate::authorize('prime.role-permission.create')`
- **Data:** Loads all permissions and groups them by Module (first segment of dot-notation name → e.g., 'prime') and Feature (second segment → e.g., 'tenant'). Groups sorted alphabetically.
- **View:** `prime::role-permission.create` with `compact('groupedPermissions')`

### 5.4 `store(RolePermissionRequest $request)`

- **Gate:** `Gate::authorize('prime.role-permission.create')`
- **Data:** Creates Role with `name`, `organization_id`, `short_name`, `description`, `is_system`
- **Permission Sync:** `$role->syncPermissions((array) $request->input('permissions'))`
- **Audit:** `activityLog($role, 'Stored', ...)`
- **Redirect:** `central.prime.user-role-prm.index#tanent`

### 5.5 `show(string $id)`

- **Gate:** `Gate::authorize('prime.role-permission.view')`
- **Query:** `Role::with('permissions:id,name')->findOrFail($id)`
- **Permission Structuring:** Parses each permission name by `.` delimiter into `$module.$feature.$action` format, structures as `[$module][$feature][] = $action`. Both module and feature levels sorted alphabetically via `ksort()`.
- **Users:** Also loads users with this role: `User::role($role->name)->get(['id', 'name', 'email', 'is_active'])`
- **View:** `prime::role-permission.show` with `compact('role', 'structuredPermissions', 'usersWithRole')`

### 5.6 `edit(string $id)`

- **Gate:** `Gate::authorize('prime.role-permission.update')`
- **Query:** `Role::with('permissions:id,name')->findOrFail($id)`
- **Permission Structuring:** Loads all permission names, creates a role-permission map (`$rolePermissionMap` keyed by permission name with flip), then structures them as `[$module][$feature][$action] = ['name' => ..., 'assigned' => bool]`
- **View:** `prime::role-permission.edit` with `compact('role', 'structuredPermissions')`

### 5.7 `update(RolePermissionRequest $request, string $id)`

- **Gate:** `Gate::authorize('prime.role-permission.update')`
- **Data:** Updates `name`, `short_name`, `description`, `is_system` on the role
- **Permission Sync:** `$role->syncPermissions($request->input('permissions'))` — replaces full permission set
- **Audit:** Captures changed attributes with old/new values; calls `activityLog()` only when changes exist
- **Redirect:** `central.prime.user-role-prm.index#tanent`

### 5.8 `destroy(string $id)`

- **Gate:** `Gate::authorize('prime.role-permission.delete')`
- **Logic:** `$role = Role::findOrFail($id); $role->delete()`
- **Note:** Although the controller calls `delete()`, the Role model's `SoftDeletes` status may vary — the trashed/restore endpoints return info messages that soft deletes are not enabled for roles.
- **Audit:** `activityLog($role, 'Toggled', ...)`
- **Redirect:** `central.prime.user-role-prm.index#tanent`

### 5.9 `trashedRolePermission()`

- **Gate:** `Gate::authorize('prime.role-permission.restore')`
- **Logic:** Returns with info message "Soft deletes are not enabled for roles."
- **Redirect:** `central.prime.user-role-prm.index?tab=role-permisons`

### 5.10 `restore($id)`

- **Gate:** `Gate::authorize('prime.role-permission.restore')`
- **Logic:** Same as trashed — returns info message
- **Redirect:** `central.prime.user-role-prm.index?tab=role-permisons`

### 5.11 `forceDelete($id)`

- **Gate:** `Gate::authorize('prime.role-permission.forceDelete')`
- **Logic:** `Role::findOrFail($id)->delete()` — deletes the role
- **Audit:** `activityLog($role, 'Deleted', 'Role permanently deleted.')`
- **Redirect:** `central.prime.user-role-prm.index?tab=role-permisons`

### 5.12 `updateRolePermission(Request $request, Role $role)` — PATCH

- **Gate:** `Gate::authorize('prime.role-permission.update')`
- **Validation:** `permission` required|string|exists:sys_permissions,name; `enabled` required|boolean
- **Logic:** If enabled, `$role->givePermissionTo($permissionName)`; else `$role->revokePermissionTo($permissionName)`
- **Response:** JSON `{ success, message }`

### 5.13 `getPermissions(Role $role): JsonResponse`

- **Gate:** `Gate::authorize('prime.role-permission.view')`
- **Logic:** Returns `$role->permissions->pluck('name')->toArray()`
- **Response:** JSON `{ permissions: [...] }`

### 5.14 `updatePermissions(Request $request, Role $role)` — POST

- **Gate:** `Gate::authorize('prime.role-permission.update')`
- **Validation:** `permissions` required|array; `permissions.*` string|exists:sys_permissions,name
- **Logic:** `$role->syncPermissions($request->permissions)` — sync by permission names, not IDs
- **Response:** JSON `{ message: "Permissions updated successfully." }`

---

## 6. Business Rules

| BR-ID | Rule | Verification |
|-------|------|:-----------:|
| BR-PRM-020 | Permission data for a role may only be returned to authenticated users who hold "View Role Permissions" permission | ✅ `getPermissions()` has `Gate::authorize('prime.role-permission.view')` |
| BR-PRM-023 | All state-changing operations must produce activity log entry | ✅ store, update, destroy, forceDelete call `activityLog()` |
| BR-PRM-019 | Login email on user creation | ❌ Not applicable (roles are not users) |

---

## 7. Security Rules

| Rule | Implementation |
|------|---------------|
| Gate check on `viewAny` | ✅ `index()`, `getRolesByOrganization()` |
| Gate check on `create` | ✅ `create()`, `store()` |
| Gate check on `view` | ✅ `show()`, `getPermissions()` |
| Gate check on `update` | ✅ `edit()`, `update()`, `updateRolePermission()`, `updatePermissions()` |
| Gate check on `delete` | ✅ `destroy()` |
| Gate check on `restore` | ✅ `trashedRolePermission()`, `restore()` |
| Gate check on `forceDelete` | ✅ `forceDelete()` |
| Permission names validated against DB | ✅ `exists:sys_permissions,name` in FormRequest and inline validation |
| No `$request->all()` on model | ✅ Controller uses explicit field assignment |

---

## 8. Gaps & Known Issues

| # | Issue | Impact | Severity | Status |
|---|-------|--------|:--------:|:------:|
| 1 | `trashedRolePermission()` and `restore()` are stubs — they return info messages instead of actual functionality | Feature gap | P2 — Low | ⬜ |
| 2 | `RolePermissionRequest` is imported from `Modules\SchoolSetup` namespace: `use Modules\SchoolSetup\Http\Requests\RolePermissionRequest;` — cross-module dependency | Architecture | P1 — Medium | ⬜ |
| 3 | No check for `organization_id` existence when creating/updating roles — relies on FK constraint | Validation | P2 — Low | ⬜ |
| 4 | No feature tests exist for RolePermissionController | Testing gap | P1 — High | ⬜ |
| 5 | `is_system` flag is editable via edit form — a role with `is_system=1` could be made `is_system=0` | Data integrity | P2 — Low | ⬜ |

---

## 9. FRD References

| Reference | Source | Summary |
|-----------|--------|---------|
| REQ-PRM-008 | FRD §1.3 | Role and Permission Management — create, edit, delete, assign permissions |
| BR-PRM-020 | FRD §1.4 | Permission endpoint requires auth |
| BR-PRM-023 | FRD §1.4 | Activity log for all state-changing actions |
| US-PRM-008 | FRD §8.1 | User story for role and permission management |
| WF-4 | FRD §1.6 | Platform Role Permission Assignment workflow |

---

## 10. Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| V1 | — | — | — |
| V2 | — | — | — |
