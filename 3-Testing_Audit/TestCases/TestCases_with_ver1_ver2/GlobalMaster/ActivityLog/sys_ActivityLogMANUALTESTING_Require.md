# Activity Log (Central Audit Viewer) — Manual Test Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | GlobalMaster (central / Prime-side) |
| Feature | ActivityLog — read-only audit trail viewer |
| URL (central) | `http://127.0.0.1:8000` + `route('central.global-master.activity-log.index')` (resolve at runtime; commonly `/activity-log`) |
| Search endpoint | `route('central.global-master.activity-log.search')` (GET, JSON) |
| Wired Controller | `Modules\Prime\Http\Controllers\ActivityLogController` (index paginate 20, view `prime::activity-log.index`, search JSON) |
| Sibling Controller | `Modules\GlobalMaster\Http\Controllers\ActivityLogController` (index paginate 10, view `globalmaster::activity-log.index`) |
| Model of record | `Modules\GlobalMaster\Models\ActivityLog` → `sys_activity_logs` (tenancy-aware `user()`) |
| Central model | `Modules\Prime\Models\ActivityLog` → `sys_central_activity_logs` (connection `mysql`) |
| Validation | None (read-only; store/edit/update/destroy are stubs) |
| Migration table | `sys_activity_logs` (dead `activity_logs` migration also exists — MIG-GLB-001) |
| CRUD Type | Read-only (index + search only) |
| Soft Delete | **No** (no `deleted_at`; do not call withTrashed/forceDelete — C12) |
| Pagination | 10/page (GlobalMaster ctrl) · 20/page (Prime central ctrl) |
| Activity Log | This IS the activity-log feature. Rows written by global `activityLog()` helper |
| Permission | `prime.activity-log.viewAny` (index), `prime.activity-log.view` (card), search = **none (SEC gap)** |

### Environment prerequisites (must hold before manual/automated runs)
1. **GlobalMaster AND Prime enabled** in `prime_testing/modules_statuses.json` (both currently `false` → every route 404).
2. **`APP_ENV=testing`** for Dusk (bypasses CSRF/419).
3. **Host `http://127.0.0.1:8000`** (enforced by `PrimeDuskTestCase`; non-127.0.0.1 fails setUp).
4. `sys_activity_logs` / `sys_central_activity_logs` migrated; a valid central `sys_users` row for FK.

---

## 2. Business Conditions (detailed)

### Audit sink routing (BC-BIZ-06/07, RISK-GLB-008)
```
activityLog($subject, $event, $properties)
   │  $subject === null  ─────────────► return null            (BC-BIZ-08)
   │
   │  build row { subject_type=get_class($subject), subject_id=$subject->getKey(),
   │              user_id=Auth::id(), event, properties, ip_address, user_agent }
   │
   ├─ tenancy()->initialized ? ─► TenantActivityLog::create  → sys_activity_logs (GlobalMaster model)
   └─ else                     ─► CentralActivityLog::create → sys_central_activity_logs (Prime model)
```
> The **central viewer reads `sys_central_activity_logs`**; the designated `sys_activity_logs` is the **tenant** sink. Two divergent tables for one conceptual feature. Documented as BUG-GLB-ALOG-03 / RISK-GLB-008.

### Permission flow (BC-AUTH)
```
GET index ─► auth middleware ─► guest? ─► redirect /login          (BC-AUTH-02)
                              └─ authed ─► Gate viewAny? ─► no ─► 403 (BC-AUTH-01)
                                                          └─ yes ─► render
                                                                     └─ @can('prime.activity-log.view')? ─► no ─► card hidden (empty page)  (BUG-GLB-ALOG-02)
GET search ─► auth middleware ─► (NO Gate) ─► JSON suggestions      (BUG-GLB-ALOG-01 SEC)
super_admin ─► Gate::before grants all                              (BC-AUTH-05)
```

### Event badge styling (BC-EDG-03, Blade `match`)
`created`→success · `updated`→primary · `deleted`→danger · `restored`→warning · `login`→info · `logout`→secondary · **default→secondary**.

---

## 3. Manual Test Cases

### TC-P01 — Schema truth (`sys_activity_logs`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | `DESCRIBE sys_activity_logs;` | Columns id, subject_type, subject_id, user_id, event, properties, ip_address, user_agent, created_at, updated_at |
| 2 | Check for `deleted_at` | **Absent** (no soft delete) |
| 3 | `SHOW INDEX FROM sys_activity_logs;` | Indexes on (subject_type,subject_id), (user_id), (created_at,user_id) |
| 4 | `SHOW CREATE TABLE sys_activity_logs;` | FK `user_id` → `sys_users(id)` ON DELETE CASCADE |
| DB | `SELECT COUNT(*) FROM information_schema.columns WHERE table_name='sys_activity_logs'` | ≥ 10 |

### TC-P07 — Newest-first ordering
| Step | Action | Expected |
|------|--------|----------|
| 1 | Insert 2 rows, backdate the first `created_at` | 2 rows present |
| 2 | Open the audit index | Newest row appears at top |
| DB | `SELECT id FROM sys_activity_logs ORDER BY created_at DESC LIMIT 1` | = newest id |

### TC-P08 — Pagination
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed > 20 rows | Rows present |
| 2 | Open Prime central index | 20 rows/page, pagination footer visible |
| 3 | Open GlobalMaster index | 10 rows/page |
| 4 | Search then page | Query string retained (`withQueryString`) |

### TC-P10 — Helper writes row with issued_by
| Step | Action | Expected |
|------|--------|----------|
| 1 | Authenticate as admin (central, no tenancy) | Session active |
| 2 | Call `activityLog($model, 'created', ['message'=>'x'])` | Returns a row |
| DB | `SELECT event,user_id FROM sys_central_activity_logs ORDER BY id DESC LIMIT 1` | event='created', user_id=admin id |

### TC-P12 — Index renders (browser)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as super-admin at 127.0.0.1:8000 | Dashboard |
| 2 | Visit activity-log index | Heading "Activity Log", "Audit Trail" card, total-count badge |
| 3 | If empty | "No activity logs found." shown |

### TC-P13/TC-P14 — Search & filter controls
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect the search bar | `#search-input`, `#filter-type`, `#reset-btn` present |
| 2 | Open the type dropdown | Options: All, Subject, Event, User |
| 3 | Type ≥ 1 char | Suggestion box (`#suggestion-box`) queries `activity-log/search` (JSON) |

### TC-N01 — Guest redirect
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logout | Session cleared |
| 2 | Visit activity-log index | Redirect to `/login` (HTTP 302) |

### TC-N02/TC-N03 — Index is gated (premise correction)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read GlobalMaster controller `index()` | `// Gate::authorize('global-master.activity-log.viewAny')` commented; `Gate::any(['prime.activity-log.viewAny']) \|\| abort(403)` ACTIVE |
| 2 | Read Prime controller `index()` | `Gate::authorize('prime.activity-log.viewAny')` ACTIVE |
| 3 | Login as user WITHOUT `prime.activity-log.viewAny` | 403 (not a blank/ungated page) |

### TC-S01 — Search endpoint unguarded (SEC — BUG-GLB-ALOG-01)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read Prime controller `search()` | **No** `Gate::authorize`/`Gate::any` in the method |
| 2 | As a low-privilege authenticated user, GET `activity-log/search?search=a&type=user` | Returns JSON of user names / events / subjects (info disclosure) |
| Note | Expected FIX | add `Gate::authorize('prime.activity-log.viewAny')` at top of `search()` |

### TC-S02 — Card gate mismatch (BUG-GLB-ALOG-02)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Grant a user `prime.activity-log.viewAny` but NOT `prime.activity-log.view` | Permission set |
| 2 | Open the index | Page loads (200) but the Audit Trail card is **hidden** (empty page) |

### TC-D03/TC-D04 — Divergent sinks (BUG-GLB-ALOG-03 / RISK-GLB-008)
| Step | Action | Expected |
|------|--------|----------|
| 1 | `SELECT ...` from `sys_central_activity_logs` after a central action | Central actions logged here |
| 2 | Inspect `Modules\Prime\Models\ActivityLog::$table` | `sys_central_activity_logs` |
| 3 | Inspect `Modules\GlobalMaster\Models\ActivityLog::$table` | `sys_activity_logs` |
| 4 | Read `app/Helpers/activityLog.php` | Branches on `tenancy()->initialized` between the two models |

### TC-EDG-02..05 — Rendering edges
| Step | Action | Expected |
|------|--------|----------|
| 1 | Row with unknown `event` | secondary badge (default style) |
| 2 | Row with null `subject_type` | `—` placeholder |
| 3 | Row with no matching user | `System` label |
| 4 | Row with null `ip_address`/`user_agent` | those lines hidden |

### TC-S03/TC-S04 — Output escaping
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create a log with `properties.message = <script>alert(1)</script>` | Stored verbatim in JSON |
| 2 | Render the index | Value HTML-escaped (`{{ }}`), no script execution |
