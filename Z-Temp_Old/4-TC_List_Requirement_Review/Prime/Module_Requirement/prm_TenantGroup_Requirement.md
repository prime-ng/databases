# Prime (PRM) — Tenant Group Management Requirement Document

## 1. Module / Feature

| Attribute | Value |
|-----------|-------|
| **Module** | Prime (PRM) |
| **Feature** | Tenant Group Management |
| **Sub-Features** | Group CRUD, Soft-Delete/Restore/Force-Delete, Status Toggle |
| **Prefix** | `prm_` |
| **Table** | `prm_tenant_groups` |
| **DB Layer** | prime_db |
| **Tenant Scope** | Central domain only |

## 2. Controller & Route(s)

### 2.1 TenantGroupController

**File:** `Modules/Prime/app/Http/Controllers/TenantGroupController.php` (191 lines)

| Method | HTTP | Route Name | Gate | Description |
|--------|------|-----------|------|-------------|
| `index()` | GET | `central.prime.tenant-group.index` | `prime.tenant-group.viewAny` | Display tenant group list |
| `create()` | GET | `central.prime.tenant-group.create` | `prime.tenant-group.create` | Show create group form |
| `store()` | POST | `central.prime.tenant-group.store` | `prime.tenant-group.create` | Create group; send email + super admin notification |
| `show()` | GET | `central.prime.tenant-group.show` | `prime.tenant-group.view` | Show group details with city and tenants |
| `edit()` | GET | `central.prime.tenant-group.edit` | `prime.tenant-group.update` | Show edit form |
| `update()` | PUT/PATCH | `central.prime.tenant-group.update` | `prime.tenant-group.update` | Update group record |
| `destroy()` | DELETE | `central.prime.tenant-group.destroy` | `prime.tenant-group.delete` | Soft-delete + deactivate |
| `trashedTenantGroup()` | GET | `central.prime.tenant-group.trashed` | `prime.tenant-group.restore` | List soft-deleted groups |
| `restore()` | GET | `central.prime.tenant-group.restore` | `prime.tenant-group.restore` | Restore soft-deleted group |
| `forceDelete()` | DELETE | `central.prime.tenant-group.forceDelete` | `prime.tenant-group.forceDelete` | Permanently delete group |
| `toggleStatus()` | POST | `central.prime.tenant-group.toggleStatus` | `prime.tenant-group.update` | Toggle is_active via AJAX |

### 2.2 Route Definitions

```php
Route::resource('tenant-group', TenantGroupController::class);
Route::get('/tenant-group/trash/view', [TenantGroupController::class, 'trashedTenantGroup'])->name('tenant-group.trashed');
Route::get('/tenant-group/{id}/restore', [TenantGroupController::class, 'restore'])->name('tenant-group.restore');
Route::delete('/tenant-group/{id}/force-delete', [TenantGroupController::class, 'forceDelete'])->name('tenant-group.forceDelete');
Route::post('/tenant-group/{tenant_group}/toggle-status', [TenantGroupController::class, 'toggleStatus'])->name('tenant-group.toggleStatus');
```

## 3. Business Rules (REQ-PRM-002)

| BR ID | Rule | Enforcement |
|-------|------|-------------|
| BR-PRM-014 | A School Group may not be deleted or force-deleted while it has active school records associated with it. A business-language error must be shown — the database constraint error must not propagate to the user interface. | DB FOREIGN KEY RESTRICT; friendly message expected |
| BR-PRM-023 | All state-changing operations must produce an activity log entry | activityLog() helper |

## 4. Technical Implementation

### 4.1 Model: TenantGroup

**Table:** `prm_tenant_groups`

**Fillable fields:**
- `code` — Short unique identifier (e.g., "GRN-TRUST")
- `short_name` — Abbreviated name (must be unique platform-wide)
- `name` — Full legal name
- `address_1`, `address_2` — Street address
- `city_id` — FK to glb_cities (required)
- `pincode` — Postal code
- `website_url` — Group website
- `email` — Contact email
- `is_active` — Active status toggle

**Relationships:**
- `city()` → belongsTo City
- `tenants()` → hasMany Tenant (all tenants)
- `liveTenants()` → hasMany Tenant where tenant_type = 'live'

**Casts:**
- `is_active` → boolean
- `city_id` → integer

### 4.2 Validation (TenantGroupRequest)

| Field | Rules |
|-------|-------|
| code | Required, string, max:20 |
| short_name | Required, string, max:50, unique:prm_tenant_groups (ignore current) |
| name | Required, string, max:150, unique:prm_tenant_groups (ignore current) |
| address_1 | Nullable, string, max:200 |
| address_2 | Nullable, string, max:200 |
| city_id | Required, exists:glb_cities |
| pincode | Nullable, string, max:10 |
| website_url | Nullable, url, max:150 |
| email | Nullable, email, max:100 |
| is_active | Boolean (checkbox: 'on' → true) |

### 4.3 Store Flow

| Step | Action |
|------|--------|
| 1 | Validate via `TenantGroupRequest` |
| 2 | Create record via `TenantGroup::create($request->validated())` |
| 3 | If email provided: send `TenantGroupCreatedMail`; log success/failure |
| 4 | Notify all active super admins via `TenantGroupCreatedNotification` |
| 5 | Log activity: "School group '{$name}' registered. {email status}" |
| 6 | Redirect to tenant management index with success flash |

### 4.4 Update Flow

| Step | Action |
|------|--------|
| 1 | Validate via `TenantGroupRequest` |
| 2 | Update via `$tenantGroup->update($request->validated())` |
| 3 | Redirect to tenant management index with success flash |

### 4.5 Soft-Delete Flow

| Step | Action |
|------|--------|
| 1 | Set `is_active = false` |
| 2 | Call `$tenantGroup->delete()` |
| 3 | Log activity: "Tenant Group moved to trashed." |
| 4 | Redirect with success flash |

**Note on BR-PRM-014:** The DDL defines `fk_tenant_tenantGroupId` as `ON DELETE RESTRICT` on `prm_tenant.tenant_group_id`. This prevents deletion of a group that has associated tenant records. However, the controller does **not** explicitly check for active tenants before deleting — the database constraint would propagate as a SQL error, not a business-language message. This is a documented gap.

### 4.6 Restore Flow

| Step | Action |
|------|--------|
| 1 | Find trashed record via `TenantGroup::withTrashed()->findOrFail($id)` |
| 2 | Call `$tenantGroup->restore()` |
| 3 | Log activity |
| 4 | Redirect to trashed list with success flash |

### 4.7 Force-Delete Flow

| Step | Action |
|------|--------|
| 1 | Find trashed record via `TenantGroup::withTrashed()->findOrFail($id)` |
| 2 | Call `$tenantGroup->forceDelete()` |
| 3 | Log activity |
| 4 | Redirect to trashed list with success flash |

### 4.8 Status Toggle

| Step | Action |
|------|--------|
| 1 | Validate `is_active` as required boolean |
| 2 | Set `$tenantGroup->is_active = $request->input('is_active')` |
| 3 | Log activity |
| 4 | Save; return JSON response with success/failure |

**JSON Response (success):**
```json
{
  "success": true,
  "is_active": true/false,
  "message": "Status updated."
}
```

**JSON Response (failure):**
```json
{
  "success": false,
  "is_active": true/false,
  "message": "Status switch failed."
}
```

### 4.9 Error Messages

| Scenario | Message |
|----------|---------|
| Create success (with email) | flash('created.tenant_group') — "Email sent to {email}" |
| Create success (without email) | flash('created.tenant_group') — "No email provided" |
| Update success | flash('updated.tenant_group') |
| Soft-delete success | flash('trashed.tenant_group') |
| Restore success | flash('restored.tenant_group') |
| Force-delete success | flash('force_deleted.tenant_group') |
| Toggle success | flash('status_updated.tenant_group') |
| Toggle failure | flash('status_switch_failed.tenant_group') |
| Delete blocked by active tenants | Database constraint error (gap — no friendly message) |

## 5. Permissions

| Permission | Methods |
|-----------|---------|
| `prime.tenant-group.viewAny` | index |
| `prime.tenant-group.view` | show |
| `prime.tenant-group.create` | create, store |
| `prime.tenant-group.update` | edit, update, toggleStatus |
| `prime.tenant-group.delete` | destroy |
| `prime.tenant-group.restore` | trashedTenantGroup, restore |
| `prime.tenant-group.forceDelete` | forceDelete |

## 6. Notifications & Mails

| Type | Trigger | Recipient | Content |
|------|---------|-----------|---------|
| `TenantGroupCreatedMail` | Group created (email provided) | Group email | Group created notification |
| `TenantGroupCreatedNotification` | Group created | All active super admins | New group registered notification |

## 7. Feature Dependencies

| Dependency | Type | Purpose |
|-----------|------|---------|
| `TenantGroupRequest` | FormRequest | Create/update validation |
| `TenantGroupCreatedMail` | Mail | Group creation email |
| `TenantGroupCreatedNotification` | Notification | Super admin notification |
| `City` model (GlobalMaster) | Model | City FK reference |

## 8. DDL Schema (prm_tenant_groups)

```sql
CREATE TABLE `prm_tenant_groups` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL,
  `short_name` varchar(50) NOT NULL,
  `name` varchar(150) NOT NULL,
  `address_1` varchar(200) DEFAULT NULL,
  `address_2` varchar(200) DEFAULT NULL,
  `city_id` INT unsigned NOT NULL,
  `pincode` varchar(10) DEFAULT NULL,
  `website_url` varchar(150) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tenantGroups_shortName` (`short_name`),
  CONSTRAINT `fk_tenantGroups_cityId` FOREIGN KEY (`city_id`) REFERENCES glb_cities (`id`) ON DELETE RESTRICT
);
```

## 9. Acceptance Criteria (REQ-PRM-002)

| AC ID | Criteria |
|-------|----------|
| AC-002-01 | Given a valid group form, the system creates the group, sends a notification to the group's email address, and records the action in the activity log |
| AC-002-02 | Given a group that has at least one associated school, a delete attempt returns a business-language validation message rather than a database exception |
| AC-002-03 | Given a group is deactivated, the status change is immediately reflected and the group can be reactivated |
| AC-002-04 | Given a soft-deleted group, it appears in the Deleted Groups list and can be permanently deleted or restored |
| AC-002-05 | Given a user without "Manage School Groups" permission, all write actions return 403 |

## 10. Edge Cases & Error Handling

| Scenario | Expected Behaviour |
|----------|-------------------|
| Delete group with active tenants | DB constraint violation; currently SQL error propagates (gap) |
| Create group with duplicate short_name | Validation error from unique rule |
| Create group with non-existent city_id | Foreign key constraint prevents creation |
| Update group email to invalid | Validation error: invalid email |
| Toggle status with missing is_active field | Validation error: is_active required |
| Group creation email fails (mailer down) | Error logged; group still created; flash message includes failure note |
| Force-delete group that has active tenants | DB constraint violation; currently SQL error propagates (gap) |

## 11. Known Gaps

| Gap ID | Description | Impact | Priority |
|--------|-------------|--------|----------|
| BR-PRM-014-GAP | Group delete blocked by active schools — no friendly business-language message; raw DB constraint error propagates to user | UX — user sees SQL error instead of "This group has active schools and cannot be deleted" | P1 |

## 12. Future Enhancements

| ENH ID | Enhancement | Details |
|--------|-------------|---------|
| — | Friendly delete-blocked message | Add explicit check in controller before delete/forceDelete for active tenant counts |
