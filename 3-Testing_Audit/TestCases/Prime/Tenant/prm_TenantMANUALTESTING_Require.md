# prm_Tenant — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Prime (PRM) |
| Feature / Screen | Tenant (central tenant registration + provisioning workflow) |
| DB scope | CENTRAL `prime_db` (no tenant init) |
| Base URL | `http://127.0.0.1:8000` |
| Index | `GET /prime/tenant` → `TenantController@index` |
| Create | `GET /prime/tenant/create`, `POST /prime/tenant` |
| Setup progress | `GET /prime/tenant/setup-progress/{id}`, JSON `GET /prime/tenant/setup-status/{id}` |
| Complete setup | `GET /prime/tenant/{tenant}/complete-tenant-setup` |
| Plan / boards / modules | `POST …/update-tenant-plan`, `…/assign-boards`, `…/module/{id}/toggle`, `…/plan/{id}/toggle-status` |
| Rollover | `POST …/start-rollover`, JSON `GET …/rollover-status` |
| Reset | `POST /prime/tenant/{tenant}/reset-setup` |
| Route name prefix | `central.prime.tenant.*` (central domain group → `prime.` group) |
| Controller | `Modules\Prime\Http\Controllers\TenantController` |
| Request | `Modules\Prime\Http\Requests\TenantRequest` |
| Models | `Tenant` (prm_tenant), `Domain` (prm_tenant_domains), `TenantPlan`, `TenantPlanModule` |
| Provisioning | `App\Jobs\SetupTenantDatabase` (queued; `$tries=1`, `$timeout=600`) |
| Activity log | central `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog`; events `created`, `Trashed` |
| CRUD type | Create/Edit via full pages (not modal); resource routes |
| Soft delete | Yes (`Tenant` uses SoftDeletes; destroy soft-deletes) |
| Pagination | 10/page (`Tenant::live()->paginate(10)`) |

**Environment prerequisites:** Prime module enabled in `modules_statuses.json`; run on `127.0.0.1:8000`; `APP_ENV=testing`; central super-admin present. Provisioning (real DB creation) is **not** exercised — those checks are source/schema truth.

---

## 2. Business Conditions (detailed)

### Create → provision flow
1. Admin opens `/prime/tenant/create`, fills School Code, Short Name, Full Name, sub-domain, established date, academic session, board, tenant group + contact/address.
2. On submit, `store()` validates via `TenantRequest`, then:
   - `is_active=0`, `setup_status='pending'`, `setup_progress=0`, `setup_message='Queued for setup...'`
   - creates the tenant, sets internal `db_name` = `generateDatabaseName()`, creates domain `{sub}.{app.domain}`
   - dispatches `SetupTenantDatabase`, emails the school, notifies super admins
   - writes activity `created`
   - redirects to `central.prime.tenant.setupProgress`.

### Provisioning state machine (SetupTenantDatabase)
```
 pending ──▶ creating_database(2→5%) ──▶ running_migrations(6→88%)
        ──▶ creating_root_user(90→93%) ──▶ adding_organization(95→99%) ──▶ completed(100%)
 (any failure) ──▶ failed
 completed|failed ──▶ resetSetup ──▶ pending (re-dispatch reset=true)
 pending|in-progress ──▶ resetSetup ──▶ REJECTED ("Setup can only be reset when it has failed or already completed.")
 non-live ──▶ startRollover ──▶ REJECTED ("Rollover can only be started for a live tenant.")
```
Root user: `root@tenant.com`, random `Str::password(16)` (emailed) — **not** a hardcoded password.

### Validation error messages
- `full_domain.unique` → "This sub-domain is already taken. Please choose a different one." (attribute label "sub-domain")
- `board_ids.required` (assignBoards) → "Please select at least one board."

---

## 3. Test Cases (Step / Action / Expected)

### TC-P01 — Schema & config truth
| Step | Action | Expected |
|------|--------|----------|
| 1 | `Schema::hasTable('prm_tenant'/'prm_tenant_domains'/'prm_tenant_plan_jnt'/'prm_tenant_plan_module_jnt')` | all true |
| 2 | `Schema::hasColumn('prm_tenant', …core cols…)` | all true |
| 3 | Tenant model `getTable()`, SoftDeletes, `is_active` cast boolean | matches |
| 4 | TenantRequest source contains `exists:prm_tenant_groups,id`, `Rule::unique('prm_tenant','code')`, `alpha_dash`, glb_cities/boards/academic_sessions exists | all present |

### TC-P10 — Store defaults (source)
| 1 | Read `TenantController@store` | `is_active=0`, `setup_status='pending'`, `'Queued for setup...'`, `SetupTenantDatabase::dispatch`, `activityLog(...,'created')` present |
| DB | On real create (guarded) | new `prm_tenant` row, `setup_status='pending'`; central `sys_central_activity_logs` row event=`created` |

### TC-SM03 — Reset from failed/completed
| 1 | Read `resetSetup` | guard `in_array(setup_status,['failed','completed'])`; re-dispatch `SetupTenantDatabase::dispatch($tenant->id,true)` |
| 2 | (guarded) POST reset on a `pending` tenant | redirect back with error "Setup can only be reset when it has failed or already completed." |

### TC-SM05 — Rollover requires live tenant
| 1 | Read `startRollover` | `if (! $tenant->isLive())` → error "Rollover can only be started for a live tenant." else dispatch `AcademicSessionRolloverJob` |

### TC-N30 / TC-N53 — Guest redirect
| 1 | Visit `/prime/tenant/create` (or `/prime/tenant`) as guest | redirected to `/login` |

### TC-N31 — Required fields
| 1 | Read `TenantRequest::rules` | tenant_group_id, code, short_name, name, domain, city_id, established_date, academic_session_id, board_id all `required` |

### TC-N46 — assignBoards validation
| 1 | Read `assignBoards` | `board_ids required|array|min:1`, `exists glb_boards`, message "Please select at least one board." |

### TC-AUTH50 / TC-AUTH54 — Gates & routes
| 1 | Read controller gates | 21 `Gate::authorize` calls: viewAny(index), create(create/store), view(show/status), update(edit/update/…), delete(destroy) |
| 2 | `Route::has('central.prime.tenant.{index,create,store,show,edit,update,destroy,setupProgress,setupStatus,completeTenantSetup,startRollover,rolloverStatus,resetSetup,updateTenantPlan,tenantPlanToggleStatus,assignBoards,tenantModuleToggle,toggleStatus,archive.*})` | all true |

### BUG checks
| BUG-PRM-TENANT-001 | `Route::has('central.prime.tenant.trashed'/'restore'/'forceDelete')` true, but `method_exists(TenantController, 'trashedTenant'/'restore'/'forceDelete')` **false** | routes bind to missing methods → 500 on access (DEFECT REPRODUCES) |
| GAP-PRM-003 | Job source has `Str::password(16)`, no `Hash::make('password')` | FIXED |
| BUG-PRM-006 | Controller source has no `prime.tenant-group.update` | FIXED |
| BUG-PRM-STUB-001 | destroy source has `$tenant->delete()` + `activityLog(...,'Trashed')` | FIXED (not a stub) |

### TC-P60/61/62 — UI smoke (guarded)
| 1 | Auth as super-admin, visit `/prime/tenant` | table headers Name/Email/Domains/Status/Action |
| 2 | Visit `/prime/tenant/create` | inputs name=code/short_name/name/domain/established_date + selects tenant_group_id/academic_session_id/board_id present |
| 3 | Visit `/prime/tenant-management` | page loads (path matches); skip if module disabled (404) |

### TC-T90 — Central context
| 1 | Inside test | `tenancy()->initialized === false` (screen runs central) |

### TC-E71 — DB-name generator
| 1 | `new Tenant(); short_name='A Very Long …'; generateDatabaseNameUsingSession(null)` | short segment ≤30 chars, `[a-z0-9_]`, ends `_000000` |
