# sys_ActivityLog — Manual Testing Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Prime (PRM) |
| Feature / Screen | ActivityLog — central activity-log viewer (READ-ONLY) |
| URL (canonical) | `http://127.0.0.1:8000/global-master/activity-log` |
| URL (alias) | `http://127.0.0.1:8000/prime/activity-log` |
| Search endpoint | `GET /prime/activity-log/search?type={subject|event|user}&search={term}` (JSON) |
| Controller | `Modules\Prime\Http\Controllers\ActivityLogController` (`index`, `search` used; CRUD stubs unused) |
| Model | `Modules\Prime\Models\ActivityLog` → `sys_central_activity_logs` (connection `mysql`) |
| Validation | None (no FormRequest; `search`/`type` read directly) |
| Migration | `database/migrations/2026_07_08_000001_create_central_activity_logs_table.php` (central; **no consolidated DDL** — constraint #25) |
| CRUD type | Read-only (list + search/filter + paginate) |
| Soft Delete | No (append-only) |
| Pagination | 20 / page (`paginate(20)`) |
| Activity Log | This screen READS the central log; it is written by `activityLog()` when untenanted |
| Permission gate | Index: `prime.activity-log.viewAny`; view card `@can('prime.activity-log.view')`; search: none |

## 2. Business Conditions (detail)
- **Index** (`ActivityLogController@index`): `Gate::authorize('prime.activity-log.viewAny')` → `ActivityLog::latest()` → optional `search` filter by `type` (subject / event / user / ALL) → `paginate(20)` → `prime::activity-log.index`.
- **Search** (`ActivityLogController@search`): **no gate**. Empty `search` → `[]`. `type=subject` → distinct `class_basename(subject_type)` labels (max 10). `type=event` → distinct `event` labels (max 10). `type=user` → distinct user names (max 10). Default (ALL) → 5 subjects + 5 events + 5 users, capped 10. Returns `{label: ...}` JSON array.
- **Rendering**: events lower-case (`created/updated/deleted/restored/login/logout`); subject shown as `class_basename`; actor = `user->name` or "System"; IP / user-agent / change-diff shown when present.
- **Central sink**: `activityLog($subject,$event,$props)` writes to `Modules\Prime\Models\ActivityLog` when `tenancy()->initialized === false`.

## 3. Manual Test Cases

### MTC-01 — Schema truth
| Step | Action | Expected |
|------|--------|----------|
| 1 | `SHOW TABLES LIKE 'sys_central_activity_logs'` on central DB | 1 row |
| 2 | `SHOW COLUMNS` | id, subject_type, subject_id, user_id, event, properties(json), ip_address, user_agent, created_at, updated_at; **no deleted_at** |
| 3 | Inspect model | `$table=sys_central_activity_logs`, `$connection=mysql`, `properties` cast array, no SoftDeletes |

### MTC-02 — Admin renders index
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log in as super-admin, visit `/global-master/activity-log` | 200; breadcrumb "Activity Log" |
| 2 | Observe card | "Audit Trail" with total badge, or "No activity logs found" empty state |
| 3 | Observe footer | Pagination links (if >20 rows) |

### MTC-03 — Search JSON (event)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed a central log row with a unique event | Row created |
| 2 | `GET /prime/activity-log/search?type=event&search={event}` | 200, JSON array containing `{label:"{event}"}` |
| 3 | Delete seed | Row gone (permanent, no soft delete) |

### MTC-04 — Search empty term
| Step | Action | Expected |
|------|--------|----------|
| 1 | `GET /prime/activity-log/search` (no `search`) | 200, `[]` |

### MTC-05 — Index filter
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/global-master/activity-log?type=event&search=created` | 200; filtered trail renders; no error |
| 2 | Visit with `type=nonsense` | ALL fallback; renders; no error |

### MTC-06 — Permissions
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log out, visit index | Redirect to `/login` |
| 2 | Log in as user WITHOUT `prime.activity-log.viewAny`, visit index | 403 Forbidden |
| 3 | Same limited user visit `/prime/activity-log/create` | 403 Forbidden |
| 4 | Any authenticated user hit `/prime/activity-log/search?...` | 200 JSON (**no gate** — finding DEV-PRM-AL-001) |

### MTC-07 — UI controls
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect search bar | `#search-form`, `#search-input`, `#suggestion-box`, `#filter-type` (All/Subject/Event/User), `#reset-btn` present |

### MTC-08 — Security / edge
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit index with `?search=<script>...</script>` | Reflected value escaped, script NOT executed |
| 2 | `GET search?type=event&search=%' OR '1'='1` | 200 JSON array; no SQL error (bound params) |
| 3 | Visit index with `?page=99999` | Renders, no error |

## 4. Cross-reference findings (see Gap Analysis for full table)
- DEV-PRM-AL-001 search() missing gate · DEV-PRM-AL-002 triple route registration · DEV-PRM-AL-003 search-url wiring · DEV-PRM-AL-004 orphaned CRUD stubs · DEV-PRM-AL-005 coverage observation (BR-PRM-012/023).
