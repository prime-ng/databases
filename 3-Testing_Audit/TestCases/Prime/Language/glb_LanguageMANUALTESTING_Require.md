# Language (PRM / GlobalMaster) — Manual Testing Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Prime (PRM) — CENTRAL DB (no tenant init) |
| Feature / Screen | Language |
| Base URL | `http://127.0.0.1:8000/global-master/language` |
| Route names | `central.global-master.language.{index,create,store,show,edit,update,destroy,trashed,restore,forceDelete,toggleStatus}` |
| Controller | `Modules\Prime\Http\Controllers\LanguageController` |
| Model | `Modules\Prime\Models\Language` (conn `global_master_mysql`, table `glb_languages`) |
| FormRequest | `Modules\GlobalMaster\Http\Requests\LanguageRequest` |
| Validation | code req/max:10/unique; name req/max:50/unique; native_name nullable/max:50; direction in LTR,RTL; is_active req boolean |
| Migration | `Modules/GlobalMaster/database/migrations/2025_11_10_061519_create_languages_table.php` (creates base table + prime_db view) |
| CRUD type | Page-based (create/edit/show/trash blades); AJAX toggle-status |
| Soft delete | Yes (`deleted_at`) — via migration, not in consolidated DDL |
| Pagination | Index 11/page; Trash 10/page |
| Activity Log | `sys_central_activity_logs` (central) — events: Trashed (destroy), Restored (restore), Stored (forceDelete — mislabeled), Toggled (toggle). NONE on create/update |
| Permissions | `prime.language.{viewAny,view,create,update,delete,restore,forceDelete}` (super-admin bypass via `Gate::before`) |

**Environment prerequisites:** Prime/GlobalMaster module enabled in `modules_statuses.json`; run on `http://127.0.0.1:8000`; `APP_ENV=testing`; a super-admin user (`is_super_admin=1 && super_admin_flag=1`) or seeded `prime.language.*` permissions.

## 2. Business Conditions (detailed)
- **Create:** `store()` validates via LanguageRequest, `Language::create($validated)`, redirects to index with toast `"Language was created successfully."` (`flash('created.language')`).
- **Update:** `update()` validates, `$language->update($validated)`, redirects with success value **`'update.language'`** — a raw unresolved key (bug — user sees literal text). No activity log.
- **Delete (soft):** `destroy()` sets `is_active=false`, calls `$language->delete()`, logs `Trashed`, redirects with `"Language was moved to trash."`.
- **Trash view:** `trashedLanguage()` lists `onlyTrashed()` 10/page.
- **Restore:** `restore()` on `onlyTrashed()` record → `restore()`, logs `Restored`, redirects with `"Language was restored successfully."`. Does NOT reset `is_active` (stays 0).
- **Force delete:** `forceDelete()` on `withTrashed()` → `forceDelete()`, logs **`Stored`** (mislabeled), redirects with `"Language was permanently deleted."`.
- **Toggle status:** `toggleStatus()` validates `is_active` boolean, sets value, logs `Toggled`, `save()`, returns JSON `{success:true,is_active,message:"Language status was successfully changed."}`.

**Activity flow (sinks):** central → `Modules\Prime\Models\ActivityLog` → table `sys_central_activity_logs` (columns: subject_type, subject_id, user_id, event, properties(json), ip_address, user_agent, timestamps).

## 3. Manual Test Cases

### TC-P11 — Create a language
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as super-admin; visit `/global-master/language/create` | Create form renders (name, code, native_name, direction, status switch) |
| 2 | Enter name=`Testish`, code=`tsh`, native=`टेस्ट`, direction=LTR, active | Fields accept input |
| 3 | Press "Add Language" | Redirect to `/global-master/language`, green toast "Language was created successfully." |
| 4 | DB check | `SELECT * FROM global_master.glb_languages WHERE code='tsh'` → 1 row, is_active=1, deleted_at NULL |

### TC-P13 — Delete (soft) a language
| Step | Action | Expected |
|------|--------|----------|
| 1 | From index, delete a language (confirm SweetAlert) | Toast "Language was moved to trash." |
| 2 | DB check | `deleted_at` set AND `is_active=0` |
| 3 | Activity check | `SELECT * FROM sys_central_activity_logs WHERE subject_id=? AND event='Trashed'` → 1 row |

### TC-P15 — Restore
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit trash view, restore a trashed language | Toast "Language was restored successfully." |
| 2 | DB check | `deleted_at` NULL; **`is_active` still 0** (DEV-LANG-007) |
| 3 | Activity check | event=`Restored` logged |

### TC-P16 — Force delete
| Step | Action | Expected |
|------|--------|----------|
| 1 | From trash view, force-delete a language | Toast "Language was permanently deleted." |
| 2 | DB check | Row absent |
| 3 | Activity check | event=**`Stored`** logged (DEV-LANG-003 — mislabeled) |

### TC-P17 — Toggle status
| Step | Action | Expected |
|------|--------|----------|
| 1 | Toggle a language's status switch on the index | AJAX POST `/global-master/language/{id}/toggle-status` |
| 2 | Response | JSON `{success:true,is_active:<new>,message:"Language status was successfully changed."}` |
| 3 | DB check | `is_active` = requested value |
| 4 | Activity check | event=`Toggled` logged |

### TC-N30 — Required validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit create; submit empty | Page re-renders with `.alert-danger` listing "The name field is required.", "The code field is required.", "The direction field is required." |

### TC-N31 / TC-N32 — Duplicate code / name
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create with an existing code (or name) | `.alert-danger` "The code has already been taken." (or name); no new active row |

### TC-N50 — Guest redirect
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logout; visit `/global-master/language` | Redirect to `/login` |

### TC-S92 — Invalid id 404
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/global-master/language/2147483000/edit` | 404 Not Found (`findOrFail`) |

### TC-E70 / TC-T90 — VIEW write path
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create a language via the UI | Row appears in `global_master.glb_languages` (base) |
| 2 | Query `prime_db.glb_languages` (view) | Same row visible through the mirror view |
| 3 | Confirm | Model `getConnectionName()` = `global_master_mysql` (writes bypass the view) |
