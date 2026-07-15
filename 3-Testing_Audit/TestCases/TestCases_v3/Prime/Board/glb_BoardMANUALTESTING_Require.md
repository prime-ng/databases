# Board (PRM / GlobalMaster) — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Prime (PRM) — central `prime` route group |
| Feature / Screen | Board (Academic Board master) |
| Base URL | `http://127.0.0.1:8000/prime/board` (central; NO tenant subdomain) |
| Index route | `central.prime.board.index` → `/prime/board` |
| Create route | `central.prime.board.create` → `/prime/board/create` |
| Store route | `central.prime.board.store` (POST `/prime/board`) |
| Show route | `central.prime.board.show` → `/prime/board/{board}` |
| Edit route | `central.prime.board.edit` → `/prime/board/{board}/edit` |
| Update route | `central.prime.board.update` (PUT `/prime/board/{board}`) |
| Destroy route | `central.prime.board.destroy` (DELETE `/prime/board/{board}`) |
| Trash route | `central.prime.board.trashed` → `/prime/board/trash/view` |
| Restore route | `central.prime.board.restore` (GET `/prime/board/{id}/restore`) |
| Force-delete route | `central.prime.board.forceDelete` (DELETE `/prime/board/{id}/force-delete`) |
| Toggle route | `central.prime.board.toggleStatus` (POST `/prime/board/{board}/toggle-status`) |
| Controller | `Modules\Prime\Http\Controllers\BoardController` |
| Model | `Modules\GlobalMaster\Models\Board` (connection `global_master_mysql`, table `glb_boards`) |
| Request | `Modules\GlobalMaster\Http\Requests\BoardRequest` |
| Policy | `Modules\GlobalMaster\Policies\BoardPolicy` |
| Validation | name required|string|max:50|unique; short_name required|string|max:10|unique; is_active required|boolean |
| Table / prefix | `glb_boards` / `glb_` (global_master — registry-vs-DDL flag; Prime registry says prm_) |
| CRUD type | Full CRUD + trash/restore/force-delete + status toggle (page-based, no modal) |
| Soft delete | Yes (`deleted_at`) |
| Pagination | 10 / page |
| Activity log | Central `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog`; events: **Stored, Updated, Trashed, Restored, Deleted, Toggled** |

**Environment prerequisites**
1. Prime module ENABLED in `prime_testing/modules_statuses.json` (else `/prime/board` returns 404).
2. `APP_ENV=testing` (Dusk bypasses CSRF; else 419 on state changes).
3. Central host `http://127.0.0.1:8000` (PrimeDuskTestCase fails otherwise).
4. `global_master` database reachable via the `global_master_mysql` connection.
5. Central `sys_central_activity_logs` table present.

**Success toast text (from `config/flash.php`, `:resource` = "Board"):**
- Created → `Board was created successfully.`
- Updated → `Board was updated successfully.`
- Trashed → `Board was moved to trash.`
- Restored → `Board was restored successfully.`
- Force-deleted → `Board was permanently deleted.`
- Status change → `Board status was successfully changed.`

---

## 2. Business Conditions (detailed)

### Validation (GlobalMaster BoardRequest)
- `name`: required, string, max **50**, unique in `glb_boards` (ignores current record on update).
- `short_name`: required, string, max **10**, unique in `glb_boards` (ignores current on update).
- `is_active`: required, boolean. `prepareForValidation()` maps the HTML checkbox `'on'` → `true`, absent → `false`.

### Activity-log flow (central sink)
```
store()       -> Board::create()          -> activityLog(board, 'Stored',   {...})
update()      -> board->update()          -> activityLog(board, 'Updated',  {changes})
destroy()     -> is_active=false; delete() -> activityLog(board, 'Trashed',  {...})
restore()     -> board->restore()         -> activityLog(board, 'Restored', {...})
forceDelete() -> board->forceDelete()     -> activityLog(board, 'Deleted',  {...})
toggleStatus()-> is_active=new; save()    -> activityLog(board, 'Toggled',  {...})  (log written before save — DEV-PRM-BOARD-04)
```
All land in `sys_central_activity_logs` because tenancy is NOT initialised for central features.

### Redirects
- store / update / destroy → `central.prime.session-board-setup.index` + `#academicboard`.
- restore / forceDelete → `central.prime.board.trashed`.

---

## 3. Manual Test Cases (Step / Action / Expected)

### MTC-01 — Create a valid board
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as super admin at `/login` | Dashboard |
| 2 | Visit `/prime/board/create` | Create form with Name + Short Name + Status switch |
| 3 | Enter Name = "Central Board of Secondary Education", Short Name = "CBSE", Status ON | Fields accept input |
| 4 | Click **Add Board** | Redirect to `.../session-board-setup#academicboard`, toast `Board was created successfully.` |
| 5 | DB check | `SELECT * FROM glb_boards WHERE short_name='CBSE'` → 1 row, is_active=1, deleted_at NULL |
| 6 | Activity check | `SELECT * FROM sys_central_activity_logs WHERE subject_id={id} AND event='Stored'` → 1 row |

### MTC-02 — Required-field validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit create with empty Name | Redirect back, error "The name field is required." shown in `.alert.alert-danger` |
| 2 | Submit with empty Short Name | Error on short_name |
| 3 | DB check | No new `glb_boards` row |

### MTC-03 — Length validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Name = 51 chars | Rejected (max:50) |
| 2 | Name = 50 chars | Accepted |
| 3 | Short Name = 11 chars | Rejected (max:10) |
| 4 | Short Name = 10 chars | Accepted |

### MTC-04 — Uniqueness
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create "ICSE"/"ICSE" | Success |
| 2 | Create another with Name "ICSE" | Rejected (unique name) |
| 3 | Create another with Short Name "ICSE" | Rejected (unique short_name) |
| 4 | Edit board #1 keeping same values | Accepted (unique ignores self) |
| 5 | Soft-delete "ICSE", then create "ICSE" again | Rejected — trashed row still reserves the value (DEV-PRM-BOARD-05) |

### MTC-05 — Edit / update
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open `/prime/board/{id}/edit` | Form prefilled |
| 2 | Change Name, submit **Update Board** | Redirect + toast `Board was updated successfully.` |
| 3 | DB check | `glb_boards.name` updated |
| 4 | Activity check | event `Updated` row with `changes` payload |

### MTC-06 — Status toggle
| Step | Action | Expected |
|------|--------|----------|
| 1 | On index, flip the status switch of an active board | AJAX POST to `toggle-status`, JSON `{success:true,is_active:false, message:"Board status was successfully changed."}` |
| 2 | DB check | `glb_boards.is_active=0` |
| 3 | Activity check | event `Toggled` row |
| 4 | Flip again | is_active=1 |

### MTC-07 — Soft delete
| Step | Action | Expected |
|------|--------|----------|
| 1 | On index, click Delete (confirm) | Redirect + toast `Board was moved to trash.` |
| 2 | DB check | `deleted_at` set, `is_active=0` |
| 3 | Activity check | event `Trashed` |
| 4 | Index list | Board no longer listed |

### MTC-08 — Trash / restore
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/prime/board/trash/view` | Trashed boards listed |
| 2 | Click Restore | Redirect to trash list + toast `Board was restored successfully.` |
| 3 | DB check | `deleted_at` NULL |
| 4 | Activity check | event `Restored` |

### MTC-09 — Force delete
| Step | Action | Expected |
|------|--------|----------|
| 1 | In trash, click Permanent Delete | Redirect + toast `Board was permanently deleted.` |
| 2 | DB check | Row removed from `glb_boards` |
| 3 | Activity check | event `Deleted` |
| 4 | Restore attempt | Not possible — row gone |

### MTC-10 — Authorization
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log out, visit `/prime/board` | Redirect to `/login` |
| 2 | Log in as user WITHOUT `prime.board.viewAny` | 403 on index |
| 3 | User without `prime.board.create` submits store | 403 |
| 4 | Show view for a user without `prime.board.update` | Edit button hidden (`@can('prime.board.update')`) |

### MTC-11 — Security
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create board with Name `<script>alert(1)</script>...` | Stored verbatim in DB |
| 2 | View index page source | Script is HTML-escaped (Blade `{{ }}`), not executed |
| 3 | Attempt to mass-assign `id` / `deleted_at` via store payload | Ignored (not fillable) |
| 4 | Request `/prime/board/99999999` | 404 |

### MTC-12 — Central DB scope
| Step | Action | Expected |
|------|--------|----------|
| 1 | Confirm no tenant subdomain used | Feature served on `127.0.0.1:8000` |
| 2 | DB check | Board rows in **global_master.glb_boards**, activity in **central sys_central_activity_logs** |
