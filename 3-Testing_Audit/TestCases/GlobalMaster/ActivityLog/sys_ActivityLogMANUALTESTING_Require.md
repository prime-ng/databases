# Activity Log — Manual Testing Specification (`sys_`)

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | GlobalMaster (GLB) — **Prime / Central** (`prime_db`), served by the Prime module |
| Feature / Screen | Activity Log — central audit-sink viewer (**READ-ONLY** list + search) |
| Page URL | `GET /global-master/activity-log` (host `http://127.0.0.1:8000`) |
| Search | Same endpoint via query string: `?search=<term>&type=<subject\|event\|user\|(empty=all)>` (server-rendered) |
| LIVE controller | `Modules\Prime\Http\Controllers\ActivityLogController::index()` → `ActivityLog::latest()->paginate(20)` + search filter; view `prime::activity-log.index` |
| DEAD controller | `Modules\GlobalMaster\Http\Controllers\ActivityLogController::index()` → `paginate(10)`, view `globalmaster::activity-log.index` (reconciliation DEV-GLB-A02) |
| Model | `Modules\Prime\Models\ActivityLog` — `sys_central_activity_logs`, connection `mysql`, `HasFactory`, **NO SoftDeletes**; cast `properties=array`; `subject()` morphTo, `user()` belongsTo |
| Route | `Route::resource('activity-log', …)` name `central.global-master.activity-log.*`; middleware `auth,verified` |
| Migrations | Central migration only — **NO consolidated DDL** for `sys_central_activity_logs` in `_prime_db_v4.sql` (DEV-GLB-A01) |
| CRUD type | **Read-only viewer.** `create/store/edit/update/destroy` are gated non-functional stubs (DEV-GLB-A02) |
| Pagination | 20/page (LIVE Prime). Footer `withQueryString()->links()` preserves search across pages |
| Activity log source | This screen IS the central sink — `activityLog()` writes here when tenancy is not initialised (BC-INT) |
| Auth | index gate `prime.activity-log.viewAny`; super-admin `Gate::before` bypass |

**Environment prerequisites:** (1) **GlobalMaster AND Prime** ENABLED in `prime_testing/modules_statuses.json` (else 404). (2) Central host `http://127.0.0.1:8000`, `APP_ENV=testing`. (3) A resolvable super-admin (`DUSK_ADMIN_EMAIL` / `is_super_admin`). (4) `sys_central_activity_logs` table must exist (central migration run) — otherwise DB/render tests self-skip (DEV-GLB-A01 guard).

---

## 2. Business Conditions (detailed)

### Index / search flow (`index`)

```
GET /global-master/activity-log[?search=&type=]
  │
  ├─ Gate::authorize('prime.activity-log.viewAny')
  ├─ $query = ActivityLog::latest()                                    ← newest first
  ├─ if search filled:
  │      type=subject → LOWER(SUBSTRING_INDEX(subject_type,'\',-1)) LIKE %term%
  │      type=event   → event LIKE %term%
  │      type=user    → whereHas('user', name LIKE %term%)
  │      else (all)   → (subject) OR (event) OR (user name)
  └─ $activityLogs = $query->paginate(20)  →  view('prime::activity-log.index')
```

### Blade render (`prime::activity-log.index`)

- Card header "Audit Trail" + total badge + `firstItem()–lastItem() of total`.
- Per row: event badge (color/icon by event: created/updated/deleted/restored/login/logout), `class_basename(subject_type)`, `#subject_id`, `created_at->diffForHumans()`, actor initials + `user->name ?? 'System'`, `ip_address`, `user_agent`, optional `properties[message]`, collapsible `properties[changes]` diff.
- Empty: `No activity logs found.` (`@forelse … @empty`).
- Footer: `$activityLogs->withQueryString()->links()`.
- All dynamic text via `{{ }}` (HTML-escaped) → XSS-safe on output.

### AJAX note

The Prime controller declares a `search()` method returning JSON suggestions, but **no route maps to it** (`Route::resource` exposes only index/create/store/show/edit/update/destroy; the blade's `data-search-url` points at the index route). Search coverage is therefore exercised through the **server-rendered index** query string, not a dedicated JSON endpoint.

---

## 3. Test Cases (Step / Action / Expected)

### TC-P01 — Schema / model configuration
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect `Modules\Prime\Models\ActivityLog` | `getTable()='sys_central_activity_logs'`, connection `mysql`, fillable = 7 columns, cast `properties=array` |
| 2 | Check traits | NO `SoftDeletes` (never call `withTrashed`) |
| 3 | Check relationships | `subject()` morphTo, `user()` belongsTo |

### TC-P04 — Latest ordering
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed two rows; push the first `created_at` a day back | — |
| 2 | `ActivityLog::latest()->whereIn(ids)->first()` | The newer row is returned first |

### TC-P06 / TC-P07 — Render + central sink
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed a `Modules\Prime\Models\ActivityLog` row with a unique subject token + event | Row persisted to `sys_central_activity_logs` |
| 2 | Login as super-admin, visit `/global-master/activity-log` | 200, no login/403 banner; Audit Trail card present |
| 3 | Inspect | `class_basename(subject_type)` token + event visible in a `.log-row` |

### TC-P11 — Pagination 20/page
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed 21 rows | — |
| 2 | Visit index | `.card-footer` paginator; a `page=2` link exists (proves ≤20/page; source = `paginate(20)`) |

### TC-P12..P15 — Search matrix
| TC | Query | Expected |
|----|-------|----------|
| TC-P12 | `?type=subject&search=<subjectToken>` | Row with that subject shown; a different subject token NOT shown; stays on index path |
| TC-P13 | `?type=event&search=<eventToken>` | Row with that event shown; a different event token NOT shown |
| TC-P14 | `?type=user&search=<adminName>` | Rows attributed to that user shown |
| TC-P15 | `?type=&search=<token>` (ALL) | Row matched by subject OR event OR user shown |

### TC-N01 — Guest redirect
| Step | Action | Expected |
|------|--------|----------|
| 1 | Clear cookies, visit `/global-master/activity-log` | Redirect to `/login` (auth,verified) |

### TC-N02 — viewAny gate (defensive)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as a non-super-admin, visit index | Body shows 403 / Forbidden / Unauthorized |
| 2 | If the user resolves as privileged (super-admin `Gate::before` bypass) | Test self-skips, documenting the bypass |

### TC-N03 — XSS-safe render
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed a row with `event='<script>alert(1)</script>'` and a scripted subject | — |
| 2 | Visit index, inspect page source | Raw `<script>alert(1)</script>` NOT present as HTML (Blade-escaped) |

### TC-N04 — Empty state
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `?type=event&search=<improbable-token>` | "No activity logs found." rendered |

### TC-D01 — Write stubs (DEV-GLB-A02)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Reflect the LIVE Prime controller | `index/create/store/edit/update/destroy/search` declared; create/store/edit/update/destroy are gated non-functional stubs (read-only screen) |

### TC-D02 — Two-controller reconciliation (DEV-GLB-A02)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read the LIVE Prime controller source | contains `paginate(20)` + `prime::activity-log.index` |
| 2 | Read the DEAD GlobalMaster controller source | contains `paginate(10)` (reconciliation marker) |

### TC-D03 — Wrong event in sink (DEV-GLB-A03 cross-ref)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed a row (stands in for Language) with `event='Stored'` on a delete path | — |
| 2 | Visit index | The (wrong) event `Stored` renders verbatim — the viewer is a fair audit surface; the wrong-event defect is **owned by the Language feature** |

### TC-T01 — Central context
| Step | Action | Expected |
|------|--------|----------|
| 1 | Run suite | `tenancy()->initialized === false`; base URL on `127.0.0.1` |

---

## 4. Notes / Limitations

- **No create/edit/delete matrix** — those routes exist (Route::resource) but the controller methods are gated non-functional stubs; testing them would assert nothing meaningful. Deliberately out of scope for this read-only viewer.
- **viewAny 403** is not deterministically observable because the central super-admin `Gate::before` resolves dotted abilities; `_31` provisions a limited user and self-skips if it resolves as privileged.
- **DB/render tests self-skip** when `sys_central_activity_logs` is absent (DEV-GLB-A01 no-DDL guard) — the suite stays green in a partial environment.
