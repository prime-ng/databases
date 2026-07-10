# prm_Subscription — Manual Testing Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Billing |
| Feature / Screen | Subscription Views (`subscription.md`) — READ-ONLY / REPORT |
| DB scope | prime_db (central), domain `http://127.0.0.1:8000` — **no tenant init** |
| Tab URL | `GET /billing/billing-management?type=subscription_data` |
| AJAX panels | `subscription-details`, `pricing-details`, `billing-details`, `module-details` (JSON `{html}`) |
| Export | `POST /billing/subscription` (`ids[]`) → PDF per id → ZIP; Print `GET /billing/billing-management/print/data?type=subscription_data` |
| Controllers | `SubscriptionController`, `BillingManagementController` |
| Prime models (read-only) | `TenantPlanRate`, `TenantPlan`, `TenantPlanBillingSchedule`, `TenantPlanModule` |
| Primary tables | `prm_tenant_plan_rates`, `prm_tenant_plan_jnt` |
| Validation | none (read-only; filters are optional query params) |
| CRUD type | **Read/Report only** (no create/edit/delete in Billing) |
| Soft delete | N/A on these tables (`prm_plans` has `deleted_at`; rate/plan-jnt do not) |
| Pagination | 10 per page |
| Activity log | `'Store'` (download/print), `'ToggleStatus'` (toggle — Prime-owned surface) |
| Permissions | `prime.subscription.{viewAny,view,create,pdf,print}` + `prime.billing-management.view` (detail panels) |

**Prerequisite (environment):** the **Billing** module must be enabled in `prime_testing/modules_statuses.json` (currently most modules `false` → 404 on routes). Run Dusk with `APP_ENV=testing` on `http://127.0.0.1:8000`. Prime plan data (tenant plans + rates) must exist for the data-dependent panels; otherwise those cases self-skip.

---

## 2. Business Conditions (detailed)

**Read-only scope (BC-BIZ-01):** the Billing subscription tab renders Prime-module data only. Any subscription state change (plan assignment, rate, schedule) is performed in the Prime module. The toggle switches shown in the row (`automatic_billing / auto_renew / is_trial / is_subscribed / is_active`) post to `billing-management.toggleStatus` and mutate `prm_tenant_plan_jnt`; treat those as a Prime-owned write surface exposed for convenience.

**Filter flow (BC-BIZ-03/04):**
```
request(type=subscription_data, status?, date_range?)
  → buildSubscriptionQuery()
       status 'Active'   → whereHas(tenantPlan, status IN [1,'ACTIVE','active'])
       status 'Inactive' → whereHas(tenantPlan, status IN [0,'INACTIVE','inactive'])
       date_range        → whereBetween(prm_tenant_plan_rates.start_date, [start,end])
  → paginate(10)
```

**AJAX panel contracts (BC-INT):** each returns HTTP 200 JSON `{ "html": "<...>" }`.
- `subscription-details?id=` → `findOrFail` (missing id ⇒ 404)
- `pricing-details?id=` / `billing-details?id=` → `where(tenant_plan_id,id)->first()/get()` (missing id ⇒ null-safe 200)
- `module-details?id=&type=subscription|invoice`

**Export (BC-BIZ-05/06):** `POST /billing/subscription` with `ids[]`; empty ids ⇒ 400 `{error:'No IDs provided'}`; each valid id → DomPDF → ZipArchive (synchronous); activity log `'Store'`.

---

## 3. Test Cases (step-by-step)

### TC-P03 — Billing Management page loads (central)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Authenticate as super-admin on `http://127.0.0.1:8000` | Session established |
| 2 | Visit `/billing/billing-management` | HTTP 200, no 403/404/419 banner |
| 3 | Inspect page | Billing management shell renders |

### TC-P04 — Subscription tab + filters visible
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/billing/billing-management?type=subscription_data` | Page loads |
| 2 | Click `#subscription-tab` | `#subscription-pane` shown |
| 3 | Inspect pane | `input[name="date_range"]`, `select[name="status"]`, hidden `type=subscription_data`, `#subscription-pane table` present |

### TC-P06 — Status filter (Active / Inactive)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open subscription tab, set Status=Active, submit | Table re-renders, no error; rows (if any) are active plans |
| 2 | Set Status=Inactive, submit | Table re-renders; rows (if any) are inactive plans |
| DB | `SELECT status FROM prm_tenant_plan_jnt WHERE id IN (visible tenant_plan_id)` | active rows ∈ {1,ACTIVE,active}; inactive ∈ {0,INACTIVE,inactive} |

### TC-P07 — Date-range filter
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open tab, set `date_range = 2024-01-01 - 2024-12-31`, submit | Table shows rates with `start_date` within window |
| DB | `SELECT start_date FROM prm_tenant_plan_rates WHERE id IN (visible)` | all within [start,end] |

### TC-P08 — Pagination caps at 10
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open tab with ≥11 rate rows | `#subscription-pane table tbody tr` count ≤ 10; pagination links present |

### TC-P09..P12 — AJAX detail panels
| Step | Action | Expected |
|------|--------|----------|
| 1 | From a row, note `data-id` (tenant_plan_id) / row-checkbox value (schedule id) | id captured |
| 2 | GET `/billing/subscription-details?id={scheduleId}` | 200 JSON with `html` key |
| 3 | GET `/billing/billing/pricing-details?id={planId}` | 200 JSON with `html` |
| 4 | GET `/billing/billing/billing-details?id={planId}` | 200 JSON with `html` |
| 5 | GET `/billing/module-details?type=subscription&id={planId}` | 200 JSON with `html` |

### TC-P14/P15 — Export & print controls
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open tab as admin | `#downloadPDFMultiBtnsSub` (PDF, @can pdf) and `#printFiltered` (@can print) present |
| 2 | Select rows, click PDF | ZIP download initiated (activity log `'Store'`, message `Subscription Download.`) |
| DB | `SELECT event FROM <central activity log> ORDER BY id DESC LIMIT 1` | `Store` |

### TC-N01 — Guest redirect
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logout | Session cleared |
| 2 | Visit `/billing/billing-management?type=subscription_data` | Redirected to `/login` |

### TC-N03 — Non-existent detail id
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/billing/subscription-details?id=999999999` | 404 (findOrFail) — no data leaked |

### TC-N05/N06 — Export edge cases
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/billing/subscription` with no `ids` | 400 `{error:'No IDs provided'}` |
| 2 | POST `/billing/subscription` with `ids=[999999999]` | 200 empty ZIP (id skipped) |

### TC-N07/N08 — Filter robustness
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open tab with `status=ZZZ` | Renders, no filter applied, no error |
| 2 | Open tab with `date_range=not-a-range` | Should render without 500 — **if 500, raise DEV-BIL-SUB-004** |

### TC-S01..S04 — Security
| Step | Action | Expected |
|------|--------|----------|
| 1 | `status=%22%3E%3Cscript%3E...%3C/script%3E` | Script NOT executed (escaped) |
| 2 | `date_range=<script>...</script>` | Script NOT executed |
| 3 | `pricing-details?id=1 OR 1=1` | Bound param; no bulk dump; 200 empty / 404 / 500 |
| 4 | Guest → direct tab URL | `/login` |

### TC-D01 — Route double-prefix quirk (DEV-BIL-SUB-003)
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/billing/billing/pricing-details?id=0` | Resolves (200/404/500) — real path |
| 2 | GET `/billing/pricing-details?id=0` | **404** — single-prefix path is not registered |

### TC-D05 — Split permission model (DEV-BIL-SUB-001)
| Step | Action | Expected |
|------|--------|----------|
| 1 | As a user with ONLY `prime.subscription.view` (no `prime.billing-management.view`), open `subscription-details`/`module-details` | **403** (panels gated on billing-management.view) — inconsistent with pricing/billing panels which succeed. Document the inconsistency. |
