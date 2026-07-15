# Tenant Domain — Manual Testing Spec (`prm_TenantDomainMANUALTESTING_Require.md`)

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Prime (PRM) — **CENTRAL / prime_db** |
| Feature / Screen | TenantDomain |
| Base URL | `http://127.0.0.1:8000/prime/tenant-domain` |
| Controller | `Modules\Prime\Http\Controllers\TenantDomainController` |
| Model | `Modules\Prime\Models\Domain` (extends Stancl `Database\Models\Domain`) |
| Primary table | `prm_tenant_domains` (prefix `prm_`) |
| Validation | **Inline** `$request->validate()` in controller (no FormRequest class) |
| Routes | `central.prime.tenant-domain.{index,create,store,show,edit,update,destroy}` + `.toggleStatus` |
| CRUD type | Full-page create/edit (NOT modal) + AJAX status toggle |
| Soft delete | **NO** — `deleted_at` column exists but model lacks `SoftDeletes` → **hard delete (BUG-PRM-002)** |
| Pagination | 10 / page, `orderBy id desc` |
| Activity Log | `sys_central_activity_logs` (central), events `created` / `updated` / `deleted`, `user_id = Auth::id()` |
| Auth | `auth` + `verified` middleware; permission gates `prime.tenant-domain.*` |

## 2. Business Conditions (detail)

### Create flow (`store`)
1. Gate `prime.tenant-domain.create`.
2. Validate: `tenant_id` (required, exists:prm_tenant,id), `domain` (required, string, max:255, unique), `db_name`/`db_host`/`db_username` (required, string, max:255), `db_port` (required, string, max:10), `db_password` (required, string, max:255), `is_active` (nullable, boolean).
3. `is_active` overridden: `$request->has('is_active') ? 1 : 0`.
4. `Domain::create($validated)` — `db_password` encrypted by cast; `domain` lowercased by Stancl concern.
5. `activityLog($domain, 'created', [...])` → `sys_central_activity_logs`.
6. Redirect `central.prime.tenant-domain.index` with `success` = "Tenant Domain was created successfully."

### Update flow (`update`)
- Gate `prime.tenant-domain.update`.
- Validate: `db_name`/`db_host`/`db_username` (required), `db_port` (required, max:10), `db_password` (nullable), `is_active` (nullable, boolean). **`tenant_id` & `domain` are NOT accepted (immutable).**
- Blank `db_password` → unset → existing kept.
- `activityLog(..., 'updated', ...)`; redirect index with "Tenant Domain was updated successfully."

### Delete flow (`destroy`)
- Gate `prime.tenant-domain.delete`.
- `activityLog(..., 'deleted', ...)` then `$domain->delete()` = **HARD delete** (BUG-PRM-002). Redirect index with "Tenant Domain was deleted successfully."

### Toggle status (`toggleStatus`, AJAX)
- Gate `prime.tenant-domain.update`; validate `is_active` required boolean.
- Set + save; log `updated`; return JSON `{success, is_active, message="Tenant Domain status was successfully changed."}`.

---

## 3. Manual Test Cases (Step / Action / Expected + DB + Activity checks)

### MTC-01 — Create a tenant domain (happy path) [TC-P04]
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as super admin at `http://127.0.0.1:8000/login` | Central dashboard loads |
| 2 | Visit `/prime/tenant-domain` | List renders, "Tenant Domains" heading, search box |
| 3 | Click Add / visit `/prime/tenant-domain/create` | Create form with Tenant select, Domain, DB Name/Host/Port/Username/Password, status switch |
| 4 | Fill valid values, unique domain e.g. `school-a.localhost`, submit | Redirect to index; green toast "Tenant Domain was created successfully." |
| 5 | DB check | `SELECT * FROM prm_tenant_domains WHERE domain='school-a.localhost'` → 1 row |
| 6 | Encryption check | `SELECT db_password FROM prm_tenant_domains WHERE domain='school-a.localhost'` → **NOT** the plaintext (ciphertext) |
| 7 | Activity check | `SELECT * FROM sys_central_activity_logs WHERE subject_type='Modules\\Prime\\Models\\Domain' AND event='created' AND subject_id=<id>` → 1 row, `user_id` = admin |

### MTC-02 — Domain persisted lowercase [TC-E01]
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create domain `MixedCase.LOCALHOST` | Success |
| 2 | DB check | stored `domain` = `mixedcase.localhost` (lowercased) |

### MTC-03 — Update DB connection fields [TC-P05]
| Step | Action | Expected |
|------|--------|----------|
| 1 | Edit an existing domain, change DB Host, leave password blank, submit | Redirect + "Tenant Domain was updated successfully." |
| 2 | DB check | `db_host` updated; `db_password` unchanged (compare raw before/after) |
| 3 | Immutability | Tenant + Domain shown read-only; cannot change |
| 4 | Activity | new row event=`updated` |

### MTC-04 — Delete is a HARD delete (BUG-PRM-002) [TC-D02]
| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete a domain | Success toast |
| 2 | DB check | `SELECT COUNT(*) FROM prm_tenant_domains WHERE id=<id>` → **0** (row gone; `deleted_at` never set) |
| 3 | Note | No trash/restore screen exists; deletion is permanent — **defect** |

### MTC-05 — Toggle status [TC-SM01/02]
| Step | Action | Expected |
|------|--------|----------|
| 1 | On index, flip status switch of an inactive domain | AJAX JSON `{success:true, is_active:1}`; toast "Tenant Domain status was successfully changed." |
| 2 | DB | `is_active` = 1 |
| 3 | Flip active → inactive | `is_active` = 0 |
| 4 | Activity | event=`updated` each toggle |

### MTC-06 — Validation: required fields [TC-N01..N04]
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit create with tenant_id blank (via API/removing HTML5 required) | 422; error "The tenant id field is required." |
| 2 | Blank domain | 422 error on domain |
| 3 | Blank db_name/host/port/username/password | 422 error per field |

### MTC-07 — Validation: duplicate + length + existence [TC-N03,N05,N06,N07]
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create a domain equal to an existing one | 422 "domain has already been taken" |
| 2 | Domain > 255 chars | 422 length error |
| 3 | db_port 11 chars | 422 length error |
| 4 | tenant_id = 999999999 | 422 exists error |

### MTC-08 — Update immutability [TC-N09]
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit update with smuggled `tenant_id`/`domain` | Accepted but ignored |
| 2 | DB | tenant_id & domain unchanged |

### MTC-09 — Search & empty state [TC-P13]
| Step | Action | Expected |
|------|--------|----------|
| 1 | Search by domain substring | Only matching rows |
| 2 | Search by tenant name | Matching rows |
| 3 | Search nonsense string | "No Tenant Domain Data Found" |

### MTC-10 — Permissions [TC-AU01..07, TC-N11]
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logout, visit `/prime/tenant-domain` | Redirect `/login` |
| 2 | Login as user WITHOUT `prime.tenant-domain.*` | index/store/show/update/destroy/toggle → 403 |
| 3 | Action/Status columns | Hidden when user lacks update/view/delete perms |

### MTC-11 — Security [TC-S01..03]
| Step | Action | Expected |
|------|--------|----------|
| 1 | Search `?search=<script>alert(1)</script>` | Value escaped; no script executes |
| 2 | Domain containing HTML | Rendered escaped as text |
| 3 | Visit `/prime/tenant-domain/999999999` | 404 |

### MTC-12 — FK RESTRICT [TC-D03]
| Step | Action | Expected |
|------|--------|----------|
| 1 | Attempt to delete a `prm_tenant` row referenced by a domain | Integrity constraint violation (ON DELETE RESTRICT) |

### MTC-13 — Defect documentation (BUG-PRM-003 / 004)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create with 150-char db_name | Passes validation (max:255) though DDL VARCHAR(100) — mismatch, **BUG-PRM-003** |
| 2 | Create with ~250-char password | Encrypted ciphertext may overflow VARCHAR(255) — **BUG-PRM-004** |
