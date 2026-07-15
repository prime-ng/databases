# prm_SalesPlanAndModuleMgmt — Manual Testing Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Prime (PRM) |
| Feature / Screen | Sales Plan & Module Mgmt (composite read-only dashboard) |
| URL | `http://127.0.0.1:8000/prime/sales-plan-mgmt` |
| Route names | `prime.sales-plan-mgmt.{index,create,store,show,edit,update,destroy}` (resource) |
| Controller | `Modules\Prime\Http\Controllers\SalesPlanAndModuleMgmtController` (uses `Request`; no FormRequest) |
| Models | `GlobalMaster\Plan`→`prm_plans`; `Billing\BillingCycle`→`prm_billing_cycles`; `GlobalMaster\Module`→`glb_modules` |
| Validation | None (read screen; only `search`/`status` query guards) |
| Migrations / DDL | `_prime_db_v4.sql` (`prm_plans`, `prm_billing_cycles`, `prm_module_plan_jnt`) |
| CRUD Type | Read/composite index only. store/update/destroy = **non-functional stubs**; create/show/edit → **missing views** |
| Soft Delete | `prm_plans` yes (`deleted_at`). `prm_billing_cycles` DDL declares none (model uses SoftDeletes — see DEV-PRM-SPM-007) |
| Pagination | 10/page per tab; params `billing_page`, `modules_page`, `plans_page` |
| Activity Log | None emitted (would-be sink: central `sys_central_activity_logs`) |
| DB scope | CENTRAL (`prime_db`, connection `mysql`), no tenant init |
| Prereq | `"Prime": true` in `prime_testing/modules_statuses.json` (else all routes 404); `APP_ENV=testing` |

## 2. Business Conditions (detail)

**Index aggregation.** A single GET renders three Bootstrap tabs sharing one `search` + `status` filter:
- **Billing Cycle** — `prm_billing_cycles` rows (Short Name, Name, Months, Description, Recurring, Status, Action).
- **Modules** — `glb_modules` rows (Name, Version, Menus, Status, Action).
- **Plans** — `prm_plans` rows (Name+detail modal, Version, Billing Cycle, Trial, Status, Action).

Each catalogue is independently paginated (10/page) with its own page param so paging one tab never disturbs the others.

**Filters.** `search` runs a LIKE across each catalogue's descriptive columns (plus numeric columns where `is_numeric`). `status` accepts only `'0'`/`'1'` (guarded by `in_array`); anything else is ignored.

**Permission split (defect surface).** The controller `index()` requires `prime.sale-plan-module-mgmt.viewAny`, but the three tabs render behind `prime.billing-cycle.viewAny` / `prime.module.viewAny` / `prime.plan.viewAny`. The row action buttons/status switches point at OTHER controllers (`central.billing.billing-cycle`, `central.global-master.module`, `central.global-master.plan`) — this screen itself performs no writes.

**Write stubs (defect surface).** `store()/update()/destroy()` bodies are only `Gate::authorize(...)` — no persistence, no redirect. `create()/show()/edit()` return `prime::create`/`prime::show`/`prime::edit` which do not exist (View-not-found at runtime).

## 3. Manual Test Cases

### MTC-01 — Index renders all three tabs (BC-BIZ-01)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log in as super-admin at `http://127.0.0.1:8000/login` | Dashboard |
| 2 | Visit `/prime/sales-plan-mgmt` | 200, breadcrumb "Sales Plan & Module Mgmt" |
| 3 | Observe tabs | `#billing-tab`, `#modules-tab`, `#plans-tab` present; Billing pane active |
| DB | `SELECT COUNT(*) FROM prime_db.prm_billing_cycles` | matches rows in billing pane (≤10) |

### MTC-02 — Plans tab + detail modal (BC-BIZ-04/05)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Click **Plans** tab | `#plans-pane` visible; columns Name/Version/Billing Cycle/Trial |
| 2 | Click a plan's info button | `#planDetail-{id}` modal lists that plan's modules |
| DB | `SELECT * FROM prm_plans p JOIN prm_billing_cycles c ON c.id=p.billing_cycle_id` | Billing Cycle column = `c.name` |

### MTC-03 — Search filter (BC-VAL-02)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Enter `MONTHLY` in search, submit | Page reloads, stays on `/prime/sales-plan-mgmt`, input shows `MONTHLY` |
| 2 | Observe billing pane | Only cycles matching short_name/name/description/months |

### MTC-04 — Status filter + invalid value (BC-VAL-03/04)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Select Active (`status=1`), submit | Only active rows across tabs |
| 2 | Select Inactive (`status=0`), submit | Only inactive rows |
| 3 | Manually hit `?status=not-a-flag` | Ignored; all rows; no error |

### MTC-05 — Empty state (BC-VAL-05)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Search a nonsense term (`zznomatch…`) | Each tab shows "Not Data Found" / "No Data Found" |

### MTC-06 — Guest blocked (BC-AUTH-05)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log out; visit `/prime/sales-plan-mgmt` | Redirect to `/login` |

### MTC-07 — store() persists nothing — DEV-PRM-SPM-001 (BC-INT-01/03)
| Step | Action | Expected |
|------|--------|----------|
| DB pre | `SELECT COUNT(*) FROM prm_plans` = N | — |
| 1 | POST to `/prime/sales-plan-mgmt` with plan fields (authenticated) | No new plan; response is empty/redirect (no create logic) |
| DB post | `SELECT COUNT(*) FROM prm_plans` | still N |

### MTC-08 — create/show/edit missing views — DEV-PRM-SPM-002 (BC-INT-04)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/prime/sales-plan-mgmt/create` | View-not-found (`prime::create` does not exist) |
| 2 | Visit `/prime/sales-plan-mgmt/1/edit` | View-not-found (`prime::edit`) |
| 3 | Visit `/prime/sales-plan-mgmt/1` | View-not-found (`prime::show`) |

### MTC-09 — Permission vocabulary mismatch — DEV-PRM-SPM-003 (BC-AUTH-03)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Grant a user only `prime.billing-cycle/module/plan.viewAny` (not `sale-plan-module-mgmt.viewAny`) | Controller returns 403 before any tab renders |

### MTC-10 — FK RESTRICT (BC-REF-01)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Attempt to delete a `prm_billing_cycles` row referenced by a plan | Blocked (`fk_plans_billingCycleId … ON DELETE RESTRICT`) |

### MTC-11 — GenerateInvoicesCommand present — GAP-PRM-001 refuted (BC-INT-08)
| Step | Action | Expected |
|------|--------|----------|
| 1 | `php artisan list \| grep prime:generate-invoices` | Command listed (registered via `PrimeServiceProvider::registerCommands`) |

### MTC-12 — Search XSS smoke (TC-S-01)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `?search=<script>zz…</script>` | Payload NOT reflected unescaped (Blade `{{ }}` escapes) |
