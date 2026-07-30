# Prime (PRM) — Tenant Domain Management Requirement Document

## 1. Module / Feature

| Attribute | Value |
|-----------|-------|
| **Module** | Prime (PRM) |
| **Feature** | Tenant Domain Management |
| **Sub-Features** | Domain CRUD, Search, Status Toggle |
| **Prefix** | `prm_` |
| **Table** | `prm_tenant_domains` |
| **DB Layer** | prime_db |
| **Tenant Scope** | Central domain only |

## 2. Controller & Route(s)

### 2.1 TenantDomainController

**File:** `Modules/Prime/app/Http/Controllers/TenantDomainController.php` (231 lines)

| Method | HTTP | Route Name | Gate | Description |
|--------|------|-----------|------|-------------|
| `index()` | GET | `central.prime.tenant-domain.index` | `prime.tenant-domain.viewAny` | List domains with search by domain name or tenant name |
| `create()` | GET | `central.prime.tenant-domain.create` | `prime.tenant-domain.create` | Show create form with tenant dropdown |
| `store()` | POST | `central.prime.tenant-domain.store` | `prime.tenant-domain.create` | Create domain record with encrypted db_password |
| `show()` | GET | `central.prime.tenant-domain.show` | `prime.tenant-domain.view` | Show domain details with tenant |
| `edit()` | GET | `central.prime.tenant-domain.edit` | `prime.tenant-domain.update` | Show edit form |
| `update()` | PUT/PATCH | `central.prime.tenant-domain.update` | `prime.tenant-domain.update` | Update domain (db_password kept if empty) |
| `destroy()` | DELETE | `central.prime.tenant-domain.destroy` | `prime.tenant-domain.delete` | Soft-delete domain in transaction |
| `toggleStatus()` | POST | `central.prime.tenant-domain.toggleStatus` | `prime.tenant-domain.update` | Toggle is_active via AJAX in transaction |

### 2.2 Route Definitions

```php
Route::resource('tenant-domain', TenantDomainController::class);
Route::post('/tenant-domain/{domain}/toggle-status', [TenantDomainController::class, 'toggleStatus'])->name('tenant-domain.toggleStatus');
```

## 3. Business Rules

| BR ID | Rule | Enforcement |
|-------|------|-------------|
| BR-PRM-006 | Database credentials (db_password) in the School Domain record must be encrypted at rest | `Domain` model uses `SafeEncrypted` cast on `db_password` |
| BR-PRM-010 | Tenant model must implement TenantWithDatabase, HasDatabase, HasDomains | Model declaration — Domain model extends `BaseDomain` from stancl/tenancy |

## 4. Technical Implementation

### 4.1 Model: Domain

**File:** `Modules/Prime/Models/Domain.php`

```php
class Domain extends BaseDomain
{
    protected $table = 'prm_tenant_domains';

    protected function casts(): array
    {
        return [
            'db_password' => \App\Casts\SafeEncrypted::class,
        ];
    }
}
```

**Table columns (DDL):**

| Column | Type | Notes |
|--------|------|-------|
| id | INT UNSIGNED | Auto-increment PK |
| tenant_id | INT UNSIGNED | FK → prm_tenant.id (ON DELETE RESTRICT) |
| domain | VARCHAR(255) | Tenant subdomain (unique constraint in stancl/tenancy) |
| db_name | VARCHAR(100) | Tenant database name |
| db_host | VARCHAR(200) | Database host |
| db_port | VARCHAR(10) | Database port (default: 3306) |
| db_username | VARCHAR(100) | Database username |
| db_password | VARCHAR(255) | Stored encrypted via SafeEncrypted cast |
| is_active | TINYINT(1) | Active status |
| created_at | TIMESTAMP | Default CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | On update CURRENT_TIMESTAMP |
| deleted_at | TIMESTAMP | Soft delete |

### 4.2 List with Search (`index()`)

| Feature | Details |
|---------|---------|
| Base query | `Domain::query()->with('tenant')->orderBy('id', 'desc')->paginate(10)` |
| Search (domain) | `where('domain', 'like', "%{$search}%")` |
| Search (tenant) | `orWhereHas('tenant', fn($q) => $q->where('name', 'like', "%{$search}%"))` |
| Pagination | `->withQueryString()` to persist search across pages |

### 4.3 Create (`store()`)

| Step | Action |
|------|--------|
| 1 | Validate: tenant_id (required, exists:prm_tenant), domain (required, unique:prm_tenant_domains), db_name/db_host/db_port/db_username/db_password (all required), is_active (nullable boolean) |
| 2 | Normalize is_active: `$request->has('is_active') ? 1 : 0` |
| 3 | Wrap in DB transaction |
| 4 | Create via `Domain::create($validated)` |
| 5 | Log activity: "Tenant domain '{$domain->domain}' created." |
| 6 | Commit; redirect to index with success flash |
| 7 | On exception: rollback; redirect back with input + error message |

**Validation rules (inline in controller):**

| Field | Rules |
|-------|-------|
| tenant_id | Required, exists:prm_tenant,id |
| domain | Required, string, max:255, unique:prm_tenant_domains,domain |
| db_name | Required, string, max:255 |
| db_host | Required, string, max:255 |
| db_port | Required, string, max:10 |
| db_username | Required, string, max:255 |
| db_password | Required, string, max:255 |
| is_active | Nullable, boolean |

### 4.4 Edit & Update

**Edit (`edit()`):**
- Load domain with tenant via `Domain::with('tenant')->findOrFail($id)`
- Display edit form (tenant_id and domain fields NOT editable based on validation)

**Update (`update()`):**

| Step | Action |
|------|--------|
| 1 | Validate: db_name/db_host/db_port/db_username (required), db_password (nullable), is_active (nullable boolean) |
| 2 | Normalize is_active: `$request->has('is_active') ? 1 : 0` |
| 3 | If db_password is empty/null: unset it from validated data (keep existing) |
| 4 | Wrap in DB transaction |
| 5 | Update via `$domain->update($validated)` |
| 6 | Log activity: "Tenant domain '{$domain->domain}' updated." |
| 7 | Commit; redirect to index with success flash |
| 8 | On exception: rollback; redirect back with input + error message |

**Note:** The `domain` and `tenant_id` fields are NOT updated via this endpoint — only database connection details and status can be changed.

### 4.5 Soft-Delete (`destroy()`)

| Step | Action |
|------|--------|
| 1 | Find domain via `Domain::findOrFail($id)` |
| 2 | Wrap in DB transaction |
| 3 | Log activity: "Tenant domain '{$domain->domain}' soft deleted." |
| 4 | Call `$domain->delete()` |
| 5 | Commit; redirect to index with success flash |
| 6 | On exception: rollback; redirect back with error |

**Note:** There is no explicit restore or force-delete for domain records (unlike tenants and tenant groups).

### 4.6 Status Toggle (`toggleStatus()`)

| Step | Action |
|------|--------|
| 1 | Validate: is_active (required, boolean) |
| 2 | Find domain via `Domain::findOrFail($id)` |
| 3 | Set `$domain->is_active = $request->input('is_active')` |
| 4 | If save succeeds: log activity + return JSON success |
| 5 | If save fails: return JSON error with 500 status |

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

### 4.7 Error Messages

| Scenario | Message |
|----------|---------|
| Create success | flash('created.tenant_domain') |
| Update success | flash('updated.tenant_domain') |
| Delete success | flash('deleted.tenant_domain') |
| Toggle success | flash('status_updated.tenant_domain') |
| Toggle failure | flash('status_switch_failed.tenant_domain') |
| Create exception | "Failed to create tenant domain: {exception message}" |
| Update exception | "Failed to update tenant domain: {exception message}" |
| Delete exception | "Failed to delete tenant domain: {exception message}" |

## 5. Permissions

| Permission | Methods |
|-----------|---------|
| `prime.tenant-domain.viewAny` | index |
| `prime.tenant-domain.view` | show |
| `prime.tenant-domain.create` | create, store |
| `prime.tenant-domain.update` | edit, update, toggleStatus |
| `prime.tenant-domain.delete` | destroy |

## 6. Feature Dependencies

| Dependency | Type | Purpose |
|-----------|------|---------|
| `Tenant` model | Model | FK reference for tenant_id; used in create form dropdown |
| `SafeEncrypted` cast | Cast | Encrypts db_password at rest |
| `stancl/tenancy` BaseDomain | Package | Domain extends BaseDomain for tenancy integration |

## 7. DDL Schema (prm_tenant_domains)

```sql
CREATE TABLE `prm_tenant_domains` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `tenant_id` INT unsigned NOT NULL,
  `domain` VARCHAR(255) NOT NULL,
  `db_name` VARCHAR(100) NOT NULL,
  `db_host` VARCHAR(200) NOT NULL,
  `db_port` VARCHAR(10) NOT NULL DEFAULT '3306',
  `db_username` VARCHAR(100) NOT NULL,
  `db_password` VARCHAR(255) NOT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tenantDomains_tenantId` FOREIGN KEY (`tenant_id`) REFERENCES prm_tenant (`id`) ON DELETE RESTRICT
);
```

## 8. Acceptance Criteria

| AC ID | Criteria |
|-------|----------|
| AC-DMN-01 | Given valid domain data, the system creates the record with encrypted db_password and logs the activity |
| AC-DMN-02 | Given a duplicate domain, the system returns a validation error — the unique constraint prevents duplicates |
| AC-DMN-03 | Given a domain update with db_password empty, the existing password is preserved |
| AC-DMN-04 | Given a domain is soft-deleted, it no longer appears in the listing but remains in the database |
| AC-DMN-05 | Given a search query, the system returns domains matching the domain name or the tenant name |
| AC-DMN-06 | Given a status toggle, the domain's is_active flag is updated and the change is reflected immediately |
| AC-DMN-07 | Given a user without the appropriate permission, all write actions return 403 |

## 9. Edge Cases & Error Handling

| Scenario | Expected Behaviour |
|----------|-------------------|
| Create domain with duplicate domain name | Validation error: domain already taken (unique constraint) |
| Create domain for non-existent tenant | Validation error: tenant_id does not exist |
| Update domain with empty db_password | Existing password kept; not overwritten with empty string |
| Update domain with new db_password | Password re-encrypted via SafeEncrypted cast |
| Delete domain while it is the only domain for a tenant | Domain deleted; tenant retains DB but loses domain routing |
| Toggle status with missing is_active field | Validation error: is_active required |
| Database transaction failure during create/update/delete | Full rollback; user sees error message with exception details |
| Activity log creation failure | Activity log failure is non-blocking; domain operation still completes |

## 10. Known Gaps

| Gap ID | Description | Impact | Priority |
|--------|-------------|--------|----------|
| BR-PRM-006-GAP | The DDL specifies db_password as VARCHAR(255) but encrypted values may require VARCHAR(500) | Potential data truncation when encryption produces output > 255 chars | P0 |
| DMN-GAP-01 | No restore or force-delete routes for domains (unlike tenants and tenant groups) | Cannot recover soft-deleted domain via UI | P2 |
| DMN-GAP-02 | Domain and tenant_id fields are not editable after creation | Must delete and re-create to change the domain name | P2 |

## 11. Future Enhancements

| ENH ID | Enhancement | Details |
|--------|-------------|---------|
| — | Domain restore + force-delete | Add trashed/restore/forceDelete routes mirroring tenant pattern |
| — | Domain field editability | Allow domain name updates via separate endpoint or form |
