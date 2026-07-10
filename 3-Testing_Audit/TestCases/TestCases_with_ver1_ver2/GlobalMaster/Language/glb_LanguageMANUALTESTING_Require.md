# glb_Language — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | GlobalMaster (central / prime-side) |
| Feature / Screen | Language (platform reference language master) |
| Base URL | `http://127.0.0.1:8000/global-master/language` (central domain) |
| Route name prefix | `central.global-master.language.*` |
| **Live Controller** | `Modules\Prime\Http\Controllers\LanguageController` (NOT the GlobalMaster one — see reconciliation note) |
| Views | `prime::language.{index,create,edit,show,trash}` |
| Model | `Modules\Prime\Models\Language` — conn `global_master_mysql`, table `glb_languages`, SoftDeletes, HasFactory, **no `$casts`** |
| FormRequest | `Modules\GlobalMaster\Http\Requests\LanguageRequest` (`authorize()` returns `true`) |
| Primary table | `glb_languages` (VIEW on central `mysql`; real table on `global_master_mysql`) |
| Migration | `Modules/GlobalMaster/database/migrations/2025_11_10_061519_create_languages_table.php` |
| CRUD type | Full CRUD + soft-delete/restore/force-delete + AJAX status toggle (page-based create/edit forms, not modals) |
| Soft delete | Yes (`deleted_at`) — added by migration `softDeletes()` (NOT in the consolidated DDL spec) |
| Pagination | Index 11/page; Trash 10/page |
| Activity log | Central: `Modules\Prime\Models\ActivityLog` → conn `mysql`, table `sys_central_activity_logs`, `user_id = Auth::id()`. Events: destroy=`Trashed`, restore=`Restored`, forceDelete=`Stored` (bug), toggle=`Toggled`. store/update do NOT log. |
| Permissions | `prime.language.{viewAny,view,create,update,delete,restore,forceDelete}` |

> **Reconciliation:** The audit report was written against `Modules\GlobalMaster\Http\Controllers\LanguageController` (renders `globalmaster::`, registered as `global-master.language.*` by the disabled GlobalMaster module → 404 in test env). The routes actually reachable at `central.global-master.language.*` are served by the **Prime** controller, which correctly gates every method. Manual steps below target the **live** central routes.

### Environment prerequisites (must hold before running)

1. **`APP_ENV=testing`** (bypasses CSRF/419) — the runner sets it.
2. Host is **`http://127.0.0.1:8000`** (the central domain); the base test case fails otherwise.
3. **Prime module enabled** in `prime_testing/modules_statuses.json` (renders `prime::` views). **GlobalMaster** should also be enabled so its `LanguageRequest` and activity-log models autoload reliably; both are currently `false`.
4. A super-admin user exists (email `root@tenant.com` / `superadmin@prime.com`, password `password`) with `is_super_admin=1`.
5. At least one valid `glb_languages` id exists (VIEW-backed; the `LanguageSeeder` seeds core languages).

---

## 2. Business Conditions (detailed)

### Validation (LanguageRequest)
```
code        : required | string | max:10 | unique(glb_languages,code) ignore self
name        : required | string | max:50 | unique(glb_languages,name) ignore self
native_name : nullable | string | max:50
direction   : required | in:LTR,RTL          (case-sensitive; matches DDL ENUM)
is_active   : required | boolean             (prepareForValidation: 'on'->true else false)
```
No `messages()` → default Laravel error text (e.g. "The code field is required.").

### Activity-log / flash flow
```
store    -> Language::create()                 -> redirect index  + flash('created.language')      -> "Language was created successfully."   [NO activity log]
update   -> $language->update()                -> redirect index  + 'update.language' (RAW LITERAL) -> shows "update.language"                 [NO activity log]  ★BUG-GLB-006b
destroy  -> is_active=false; save; delete()    -> log 'Trashed'   -> redirect index + flash('trashed.language')      -> "Language was moved to trash."
restore  -> restore()                          -> log 'Restored'  -> redirect .trashed + flash('restored.language')  -> "Language was restored successfully."
forceDel -> forceDelete()                      -> log 'Stored'    -> redirect .trashed + flash('force_deleted.language') -> "Language was permanently deleted."  ★BUG-GLB-006a (event mislabeled)
toggle   -> is_active=new; log 'Toggled'; save -> JSON {success, is_active, message: flash('status_updated.language')}
```
Central activity rows land in `sys_central_activity_logs` (conn `mysql`): `subject_type=Modules\Prime\Models\Language`, `subject_id`, `user_id=Auth::id()`, `event`, `properties` (JSON), `ip_address`, `user_agent`.

---

## 3. Test Cases (step-by-step)

### TC-P04 — Create a language (happy path)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as super admin | Dashboard loads on `127.0.0.1:8000` |
| 2 | Visit `/global-master/language/create` | Create form renders: `name`, `code`, `native_name` text inputs, `#direction` select (LTR/RTL), status switch, "Add Language" button |
| 3 | Fill name="Testish 0713", code="tsh13", native_name="टेस्ट", direction=LTR, status on | Fields accept input |
| 4 | Press "Add Language" | Redirect to `/global-master/language`; success banner "Language was created successfully." |
| 5 | DB check | `SELECT * FROM glb_languages WHERE code='tsh13'` → 1 row, `is_active=1`, `deleted_at IS NULL` |
| 6 | Activity check | `SELECT * FROM sys_central_activity_logs WHERE subject_type LIKE '%Language' AND event='Trashed'` → **no new row from store** (store does not log) |

### TC-P06 / BUG-GLB-006b — Update + raw flash literal
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create/seed a language, note its id | Row exists |
| 2 | Visit `/global-master/language/{id}/edit` | Form prefilled with current name/code/native_name/direction |
| 3 | Change name, press "Update Language" | Redirect to index |
| 4 | DB check | `SELECT name FROM glb_languages WHERE id={id}` → new name |
| 5 | Flash check | Banner shows the **literal string `update.language`** (untranslated key) — ★BUG-GLB-006b, not "Language was updated successfully." |

### TC-P07 / TC-SM-03 — Destroy (soft delete + Trashed log)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed active language id | Row `is_active=1`, `deleted_at NULL` |
| 2 | Submit DELETE `/global-master/language/{id}` (trash/eraser button, SweetAlert confirm) | Redirect to index; "Language was moved to trash." |
| 3 | DB check | `deleted_at IS NOT NULL` AND `is_active=0` |
| 4 | Activity check | `sys_central_activity_logs` newest row for this subject → `event='Trashed'`, `user_id=<admin>` |

### TC-P09 / TC-SM-04 — Restore
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/global-master/language/trash/view` | Trashed languages listed (paginate 10) |
| 2 | Click restore (recycle icon) → GET `/global-master/language/{id}/restore` | Redirect to trash view; "Language was restored successfully." |
| 3 | DB check | `deleted_at IS NULL` |
| 4 | Activity check | Newest row → `event='Restored'` |

### TC-P10 / TC-SM-05 / BUG-GLB-006a — Force delete (Stored log bug)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | With a trashed language, submit DELETE `/global-master/language/{id}/force-delete` | Redirect to trash; "Language was permanently deleted." |
| 2 | DB check | `SELECT COUNT(*) FROM glb_languages WHERE id={id}` → 0 |
| 3 | Activity check | Newest row → **`event='Stored'`** (★BUG-GLB-006a — mislabeled; should be 'Deleted') |

### TC-P11 / TC-SM-01/02 — Toggle status (AJAX JSON)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On index, flip the status switch of a language (POST `/global-master/language/{id}/toggle-status` with `is_active`) | JSON `{success:true, is_active:<new>, message:"Language status was successfully changed."}` |
| 2 | DB check | `is_active` flipped |
| 3 | Activity check | Newest row → `event='Toggled'` |

### TC-N01/N02/N03 — Required validation
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST store with code missing | Redirect back with error "The code field is required." (no row created) |
| 2 | POST store with name missing | Error "The name field is required." |
| 3 | POST store with direction missing/invalid | Error on direction (must be LTR/RTL) |

### TC-N08/N09 — Duplicate code / name
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed language code="dup01", name="Dup Name" | Row exists |
| 2 | POST store with code="dup01" | Unique error on code; no second row |
| 3 | POST store with name="Dup Name" | Unique error on name; no second row |

### TC-N04/N05/N06 — Length limits
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST store code = 11 chars | Rejected (max:10) |
| 2 | POST store name = 51 chars | Rejected (max:50) |
| 3 | POST store native_name = 51 chars | Rejected (max:50) |

### TC-S01..S06 — Authorization (limited user → 403) [SEC-GLB-010 / SEC-GLB-005 reconciled]
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a user with `is_super_admin=0` and NO `prime.language.*` permissions | User exists |
| 2 | GET `/global-master/language` | **403** (viewAny gate) |
| 3 | GET `/global-master/language/create` and POST store | **403** (create gate) — audit SEC-GLB-010 does NOT reproduce on the live central route |
| 4 | GET edit, PUT update | **403** (update gate) |
| 5 | DELETE destroy | **403** (delete gate) — audit SEC-GLB-005 prefix mismatch does NOT reproduce on the live central route |
| 6 | restore / forceDelete / toggleStatus | **403** (restore / forceDelete / update gates) |

### TC-N15 — Guest redirect
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Logout | Session cleared |
| 2 | Visit `/global-master/language` | Redirect to `/login` |

### TC-S08/S09 — XSS on free-text fields
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create language with name=`<script>alert(1)</script>NAME` (via model or store) | Row persists literal payload |
| 2 | Visit index | Blade `{{ }}` escapes it → rendered as text, `<script>` NOT executed; page source contains `&lt;script&gt;` |
| 3 | Repeat for native_name | Escaped on render |

### TC-N12/N13/N14 / TC-S10 — 404 / IDOR
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET edit with id=99999999 | 404 (findOrFail) |
| 2 | DELETE destroy with id=99999999 | 404 |
| 3 | GET restore with id=99999999 | 404 |

### TC-D03 — Translations FK cascade (defensive)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | If `glb_translations` exists, create a translation for a language | Row exists |
| 2 | Force-delete the language | Translations for it are cascade-removed (ON DELETE CASCADE) |
| 3 | If table absent | Skip (partial environment) |
