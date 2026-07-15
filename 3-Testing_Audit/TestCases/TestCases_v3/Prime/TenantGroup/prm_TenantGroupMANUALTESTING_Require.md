# Tenant Group — Manual Testing Specification (`prm_TenantGroupMANUALTESTING_Require.md`)

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Prime (PRM) — **CENTRAL DB (`prime_db`)**, no tenancy |
| Feature / Screen | TenantGroup |
| Base URL | `http://127.0.0.1:8000/prime/tenant-group` (listing surfaced on `/prime/tenant-management#tenant-group`) |
| Controller | `Modules\Prime\Http\Controllers\TenantGroupController` |
| Request | `Modules\Prime\Http\Requests\TenantGroupRequest` |
| Model | `Modules\Prime\Models\TenantGroup` |
| Table (prefix `prm_`) | `prm_tenant_groups` |
| CRUD type | Full-page forms (create/edit blades), AJAX only for status toggle |
| Soft delete | Yes (`deleted_at`) |
| Pagination | Trash list 10/page |
| Activity Log | `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog` |
| Login | `root@tenant.com` / `password` (super admin — needs `is_super_admin` + `super_admin_flag`) |

**Routes (`central.prime.tenant-group.*`):** index, create, store, show, edit, update, destroy, trashed (`/trash/view`), restore (`/{id}/restore`), forceDelete (`/{id}/force-delete`), toggleStatus (`POST /{tenant_group}/toggle-status`).

**Permissions:** `prime.tenant-group.{viewAny, view, create, update, delete, restore, forceDelete}`.

**Activity event strings (LITERAL — verify exactly):** store→`created`, destroy→`Trashed`, restore→`Restored`, forceDelete→`Deleted`, toggleStatus→`Toggled`. **update → none.**

---

## 2. Business Conditions & Flows

**Create flow:** valid POST → `TenantGroup::create(validated())` → if `email` set, sends `TenantGroupCreatedMail` (failure is caught & logged, does not block) → notifies active super admins (`TenantGroupCreatedNotification`) → `activityLog(group, 'created')` → redirect to `tenant-management#tanent-group` with success flash `"Tenant Group was created successfully. — <email status>"`.

**Delete (soft):** `is_active=false` then `delete()` → `activityLog(group, 'Trashed')` → flash `"Tenant Group was moved to trash."`

**Restore:** `withTrashed()->restore()` → `activityLog(group, 'Restored')` → redirect to trashed list.

**Force delete:** `withTrashed()->forceDelete()` → `activityLog(group, 'Deleted')`. **Blocked by FK RESTRICT if a `prm_tenant` row references the group.**

**Toggle status:** validates `is_active` boolean → sets flag → `activityLog(group, 'Toggled')` → JSON `{success, is_active, message}`.

**Validation error messages:** default Laravel messages (no custom `messages()`), e.g. "The code field is required.", "The short name has already been taken.", "The selected city id is invalid.", "The website url field must be a valid URL.".

---

## 3. Manual Test Cases

### MTC-01 — Create a valid tenant group
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as super admin, open `/prime/tenant-group/create` | Form with code, name, short_name, address_1/2, pincode, website_url, email, city select, status switch |
| 2 | Fill unique code/short_name/name + valid city + valid email, submit | Redirect to `tenant-management#tanent-group`, green success toast |
| 3 | DB check | `SELECT * FROM prm_tenant_groups WHERE code='<code>'` → 1 row, `is_active=1` |
| 4 | Activity check | `SELECT * FROM sys_central_activity_logs WHERE subject_type LIKE '%TenantGroup' AND event='created'` → 1 row for the new id |

### MTC-02 — Required-field validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit create form with code, short_name, name, city all empty | Page re-renders with error list; no DB row created |
| 2 | DB check | No new `prm_tenant_groups` row |

### MTC-03 — Duplicate short_name / name
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create group A | Success |
| 2 | Create group B reusing A's short_name | Error "The short name has already been taken." |
| 3 | Create group C reusing A's name | Error "The name has already been taken." (app-level only; note D25-PRM-006) |

### MTC-04 — Edit (update)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open edit for an existing group | Fields pre-filled with current values |
| 2 | Change name, submit | Redirect + success flash; `SELECT name` reflects new value |
| 3 | Activity check | **No** new activity-log row (D25-PRM-003) |

### MTC-05 — Status toggle
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/prime/tenant-group/{id}/toggle-status` with `is_active=0` | JSON `{success:true, is_active:false, message:"...status was successfully changed."}` |
| 2 | DB check | `is_active=0` persisted |
| 3 | Activity check | `event='Toggled'` row present |
| 4 | POST with `is_active='banana'` | 422 validation error on `is_active` |

### MTC-06 — Soft delete → restore → force delete
| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete a group | `deleted_at` set, `is_active=0`; activity `Trashed` |
| 2 | Open `/prime/tenant-group/trash/view` | Group appears in trashed list |
| 3 | Restore | `deleted_at` null; activity `Restored` |
| 4 | Delete again, then force-delete | Row removed from DB; activity `Deleted` |
| 5 | Force-delete while a `prm_tenant` references the group | Blocked (FK RESTRICT / DB error) |

### MTC-07 — Authorization
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logout, visit `/prime/tenant-group` | Redirect to `/login` |
| 2 | Login as user without `prime.tenant-group.*` | 403 on index/create/show/edit; store forbidden, nothing persisted |

### MTC-08 — Security
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create group with name `<script>alert(1)</script>` | Stored; on edit page the raw `<script>` is HTML-escaped (no alert) |
| 2 | GET `/prime/tenant-group/999999` (show/edit) | 404 |

### MTC-09 — Boundaries & optionals
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit code=20 chars, short_name=50, name=150, pincode=10 | Accepted |
| 2 | Submit with all optional fields empty | Accepted (nullable) |
| 3 | Submit with checkbox unchecked | `is_active=0` persisted; checked → `is_active=1` |
