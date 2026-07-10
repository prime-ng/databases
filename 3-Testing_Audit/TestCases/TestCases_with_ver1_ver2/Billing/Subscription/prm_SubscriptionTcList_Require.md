# prm_Subscription — Test Case List & Business Conditions

**Module:** Billing · **Feature/Screen:** Subscription Views (`subscription.md`)
**Type:** PRIME-SIDE (prime_db, central domain `http://127.0.0.1:8000`), **READ-ONLY / REPORT / COMPOSITE** screen
**Primary tables:** `prm_tenant_plan_rates` (DDL `_prime_db_v4.sql:473`) + `prm_tenant_plan_jnt` (`:454`) · **Prefix:** `prm_`
**Controllers:** `SubscriptionController` (pricing/billing panels + PDF/ZIP), `BillingManagementController` (index tab, subscription/module detail panels, print)
**Prime models (read-only for Billing):** `TenantPlanRate`, `TenantPlan`, `TenantPlanBillingSchedule`, `TenantPlanModule`
**Base test class:** `prm_BillingDuskTestCase_TestCas` (central chain) · **User model:** `App\Models\User` · **Tenancy:** none (prime-side)

> Scope note: Billing does **not** create/modify subscriptions — plan assignment/rate/schedule writes live in the **Prime** module. This artifact set is therefore a lighter, read-focused suite: render, filters, pagination, AJAX detail-panel contracts, PDF/ZIP export, permissions, empty state. **No create/edit/delete matrix.**

---

## 1. Business Conditions

### BC-DB — Schema / constraints (Source: DDL `_prime_db_v4.sql`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `prm_tenant_plan_rates` has `id, tenant_plan_id, start_date, end_date, billing_cycle_id, billing_cycle_day, monthly_rate, rate_per_cycle, currency, min_billing_qty, discount_percent/amount, tax1..4_percent, credit_days` | DDL-prm_tenant_plan_rates |
| BC-DB-02 | `prm_tenant_plan_jnt` has `tenant_id, plan_id, is_subscribed, is_trial, auto_renew, automatic_billing, status, is_active` | DDL-prm_tenant_plan_jnt |
| BC-DB-03 | `prm_tenant_plan_jnt.status` VARCHAR(20) default `'ACTIVE'` (intended set ACTIVE/SUSPENDED/CANCELED/EXPIRED — not enforced by ENUM) | DDL-prm_tenant_plan_jnt |
| BC-DB-04 | `prm_tenant_plan_jnt.current_flag` GENERATED `(is_subscribed=1 ? tenant_id : NULL)` STORED, UNIQUE(`current_flag`,`plan_id`) | DDL-prm_tenant_plan_jnt |
| BC-DB-05 | Rate model casts: `start_date/end_date`→date, `rate_per_cycle/discount_*/tax*_percent`→decimal:2 | Model TenantPlanRate |

### BC-REF — Foreign keys (Source: DDL)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `prm_tenant_plan_rates.tenant_plan_id` → `prm_tenant_plan_jnt(id)` ON DELETE **CASCADE** | DDL-prm_tenant_plan_rates |
| BC-REF-02 | `prm_tenant_plan_rates.billing_cycle_id` → `prm_billing_cycles(id)` ON DELETE **RESTRICT** | DDL-prm_tenant_plan_rates |
| BC-REF-03 | `prm_tenant_plan_jnt.tenant_id` → `prm_tenant(id)` RESTRICT; `plan_id` → `prm_plans(id)` RESTRICT | DDL-prm_tenant_plan_jnt |

### BC-BIZ — Business rules / behaviour (Source: Screen + Controllers)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Read-only scope: no create/edit/delete of subscriptions in Billing | Screen-BR (Read-Only Scope) |
| BC-BIZ-02 | Subscription list = `buildSubscriptionQuery()` on `TenantPlanRate::query()`, **paginated 10/page** | Screen-BR + BillingManagementController:92,251 |
| BC-BIZ-03 | `status` filter maps `'Active'`→`whereHas(tenantPlan, status in [1,ACTIVE,active])`, `'Inactive'`→`[0,INACTIVE,inactive]`; any other value = no filter | BillingManagementController:256-263 |
| BC-BIZ-04 | `date_range` filter → `whereBetween('start_date', [start,end])` (parsed via `explode(' - ')`) | BillingManagementController:266-268,236-245 |
| BC-BIZ-05 | PDF/ZIP export: `POST /billing/subscription` with `ids[]` → DomPDF per id → ZipArchive (synchronous) | SubscriptionController@store:41-98 |
| BC-BIZ-06 | Export writes activity log event **`'Store'`** (`activityLog($record,'Store',['message'=>'Subscription Download.'])`) | SubscriptionController:68 |
| BC-BIZ-07 | Print writes activity log event **`'Store'`** message `'Subscription Data Print.'` | BillingManagementController:160 |
| BC-BIZ-08 | Toggle switches (`automatic_billing/auto_renew/is_trial/is_subscribed/is_active`) post to `billing-management.toggleStatus`, event **`'ToggleStatus'`** (Prime write surface, shown but owned by Prime module) | BillingManagementController:962-1022 |

### BC-INT — AJAX detail-panel integration (Source: Screen + routes + controllers)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | `GET /billing/subscription-details?id=` → JSON `{html}` (BillingManagementController@subscriptionDetails, `findOrFail`) | Screen-IP + routes:347 |
| BC-INT-02 | `GET /billing/billing/pricing-details?id=` → JSON `{html}` (SubscriptionController@pricingDetails, null-safe `first()`) | Screen-IP + routes:371 |
| BC-INT-03 | `GET /billing/billing/billing-details?id=` → JSON `{html}` (SubscriptionController@billingDetails, ordered `get()`) | Screen-IP + routes:374 |
| BC-INT-04 | `GET /billing/module-details?id=&type=subscription\|invoice` → JSON `{html}`; `subscription`=`TenantPlanModule`, else=`BillOrgInvoicingModulesJnt` | Screen-IP + routes:353 |

### BC-AUTH — Permission gates (Source: Policy + Controllers + Blade `@can`)
| ID | Gate | Guards | Source |
|----|------|--------|--------|
| BC-AUTH-01 | `prime.subscription.viewAny` | tab include + `SubscriptionController@index` | Screen-PM + blade index:14,27 |
| BC-AUTH-02 | `prime.subscription.view` | pricing/billing panels + action links (`SubscriptionController@pricingDetails/billingDetails`) | Screen-PM + Controller:102,116 |
| BC-AUTH-03 | `prime.subscription.create` | PDF/ZIP `store` | Screen-PM + Controller:44 |
| BC-AUTH-04 | `prime.subscription.pdf` | `#downloadPDFMultiBtnsSub` export control | Blade:84 |
| BC-AUTH-05 | `prime.subscription.print` | `#printFiltered` control | Blade:71 |
| BC-AUTH-06 | `prime.billing-management.view` | subscription-details + module-details panels (**inconsistent** — split from subscription.* — see DEV-BIL-SUB-001) | Controller:820,839 |

### BC-EDG — Edge / boundary
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Malformed `date_range` (no `' - '`) → `explode` yields <2 parts (defensive-input risk) | BillingManagementController:239 |
| BC-EDG-02 | `store` with empty `ids` → JSON `{error:'No IDs provided'}` 400 | SubscriptionController:46-48 |
| BC-EDG-03 | `store` with non-existent id → `find` null → `continue` → empty ZIP 200 | SubscriptionController:66 |
| BC-EDG-04 | `pricingDetails`/`billingDetails` missing id → null-safe empty panel (200) | Controller:103,117 |
| BC-EDG-05 | Empty result set (impossible date window) → empty table body, no error | Blade:134 |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | V1 | V2 |
|-------|----|--------|-------------|----------|----|----|
| TC-P01 | BC-DB-01/05 | DDL | Rate table + model schema truth | Columns/casts/relationships present | 01 | 01,03,04 |
| TC-P02 | BC-DB-02/03/04 | DDL | Plan table + status + current_flag | Columns present | 01 | 02,05 |
| TC-P03 | BC-BIZ-02 | Screen | Billing Mgmt page loads on central | 200, accessible | 02 | 10 |
| TC-P04 | BC-AUTH-01 | Screen-PM | Subscription tab + filters visible | pane, date_range, status, table | 03 | 11 |
| TC-P05 | BC-BIZ-02 | Blade | Table headers render | Organization/Plan/Billing Period… | 04 | 12 |
| TC-P06 | BC-BIZ-03 | Controller | Status filter Active/Inactive apply | table re-renders, no error | 05 | 30,31 |
| TC-P07 | BC-BIZ-04 | Controller | date_range filter applies | table renders | 06 | 33 |
| TC-P08 | BC-BIZ-02 | Controller | Pagination caps at 10 | ≤10 rows/page | 07 | 60 |
| TC-P09 | BC-INT-01 | Screen-IP | subscription-details JSON `{html}` | 200 html / 404 | 08 | 40 |
| TC-P10 | BC-INT-02 | Screen-IP | pricing-details JSON `{html}` | 200 html / 404 | 09 | 41 |
| TC-P11 | BC-INT-03 | Screen-IP | billing-details JSON `{html}` | 200 html / 404 | 10 | 42 |
| TC-P12 | BC-INT-04 | Screen-IP | module-details (subscription) JSON | 200 html / 404 | 11 | 43 |
| TC-P13 | BC-AUTH-02 | Blade | Action links present (view) | module/pricing/billing links | 12 | 51 |
| TC-P14 | BC-AUTH-04 | Blade | PDF export control present | `#downloadPDFMultiBtnsSub` | 13 | 52,64 |
| TC-P15 | BC-AUTH-05 | Blade | Print control present | `#printFiltered` | — | 53 |
| TC-P16 | BC-BIZ-08 | Blade | Toggle switches render | `.toggle-subscription` | — | 14 |
| TC-P17 | BC-BIZ-05 | Controller | Print view renders | 200 accessible | — | 72 |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | V1 | V2 |
|-------|----|--------|-------------|----------|----|----|
| TC-N01 | BC-AUTH-01 | Screen-PM | Guest → login redirect | `/login` | 15 | 54,93 |
| TC-N02 | BC-AUTH | routes mw | Guest AJAX detail → no `{html}` | not authorised | — | 55 |
| TC-N03 | BC-INT-01 | Controller | Non-existent id detail → 404/500 | error, no data | — | 44 |
| TC-N04 | BC-EDG-04 | Controller | Missing id pricing → null-safe 200 | empty panel | — | 45 |
| TC-N05 | BC-EDG-02 | Controller | store empty ids → 400 | client error | — | 70 |
| TC-N06 | BC-EDG-03 | Controller | store bad id → skips, empty ZIP | 200/400 | — | 71 |
| TC-N07 | BC-BIZ-03 | Controller | Unknown status value → no error | renders | — | 32 |
| TC-N08 | BC-EDG-01 | Controller | Malformed date_range handled | no 500 (candidate DEV-004) | — | 34 |
| TC-N09 | BC-BIZ-01 | Screen | No create/add-subscription affordance | 0 add buttons | — | 13 |

### Security (TC-S)
| TC ID | BC | Source | Description | Expected | V2 |
|-------|----|--------|-------------|----------|----|
| TC-S01 | BC-EDG | Sec | Reflected XSS via `status` | not executed | 90 |
| TC-S02 | BC-EDG | Sec | Reflected XSS via `date_range` | not executed | 91 |
| TC-S03 | BC-INT-02 | Sec | Injection-shaped id | bound, no dump | 92 |
| TC-S04 | BC-AUTH | Sec | Direct tab URL requires auth | `/login` | 93 |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | V1 | V2 |
|-------|-----|----|--------|-------------|----------|----|----|
| TC-D01 | E | BC-INT | routes | pricing route double-`/billing` prefix quirk | real path resolves; single-prefix 404 | 16 | 73 |
| TC-D02 | E | BC-INT-04 | Controller | module-details invoice branch (type≠subscription) | resolves | — | 74 |
| TC-D03 | A | BC-EDG-05 | Blade | Empty-state (impossible window) | empty table, no error | — | 61 |
| TC-D04 | C | BC-REF-02 | DDL | billing_cycle_id RESTRICT target exists | FK column + parent present | — | 06 |
| TC-D05 | E | BC-AUTH-06 | Controller | Split permission model (billing-mgmt.view vs subscription.view) | documented DEV-001 | — | 56 |

### Known Source Defects (audit + cross-reference)
| ID | Sev | Description | Proving test | Status |
|----|-----|-------------|--------------|--------|
| DEV-BIL-SUB-001 | P2 | AJAX detail panels split across two permission namespaces: `subscription-details`/`module-details` gated `prime.billing-management.view` while `pricing-details`/`billing-details` gated `prime.subscription.view` — a `subscription.view`-only user cannot see subscription/module panels | V2_56 (structural; needs scoped user to fully prove) | Open |
| DEV-BIL-SUB-002 | P3 | `SubscriptionPolicy` `view/update/delete/restore/forceDelete` type-hint `Modules\Billing\Models\InvoicingPayment` (copy-paste) instead of a subscription/plan model | Static (Policy.php:21,61,69,77,85) | Open |
| DEV-BIL-SUB-003 | P3 | Route path quirk: `pricingDetails`/`billingDetails` registered as `billing/pricing-details` under prefix `billing` → real URL `/billing/billing/pricing-details` (double segment) | V1_16 / V2_73 | Open |
| DEV-BIL-SUB-004 | P3 | `parseDateRange` `explode(' - ')` unguarded — malformed `date_range` can throw (list() undefined offset) | V2_34 (records skip on 500) | Candidate — verify |
| SEC-BIL-010 | P1 | (audit) `pricingDetails`/`billingDetails` previously unprotected | — | **REMEDIATED** — both now `Gate::authorize('prime.subscription.view')` (Controller:102,116) |
| PERF-BIL-001 | P2 | (audit) sync ZIP + unbounded `Tenant::get()`/`User::get()` + leaked temp PDFs | V2_70/71 | **PARTIAL** — temp PDFs now `@unlink`'d (Ctrl:87-89); dashboard loads capped `limit(500)` (Ctrl:117-118); ZIP still synchronous |
| REQ-BIL-002 | — | (audit) subscription lifecycle | — | Partial (read-only built; lifecycle future) |

---

## 3. V2 Method Index (band → category)
| # | Method | TC map | Band |
|---|--------|--------|------|
| 1 | 01 rates_table_schema | TC-P01 | 01-09 schema |
| 2 | 02 plan_table_schema | TC-P02 | 01-09 |
| 3 | 03 rate_model_fillable_casts | TC-P01 | 01-09 |
| 4 | 04 rate_relationships | TC-P01 | 01-09 |
| 5 | 05 plan_status_current_flag | TC-P02 | 01-09 |
| 6 | 06 rate_fk_targets | TC-D04 | 01-09 |
| 7 | 10 page_loads | TC-P03 | 10-19 biz |
| 8 | 11 tab_pane_visible | TC-P04 | 10-19 |
| 9 | 12 table_headers | TC-P05 | 10-19 |
| 10 | 13 read_only_no_create | TC-N09 | 10-19 |
| 11 | 14 toggle_switches | TC-P16 | 10-19 |
| 12 | 30 status_active_filter | TC-P06 | 30-39 val |
| 13 | 31 status_inactive_filter | TC-P06 | 30-39 |
| 14 | 32 unknown_status | TC-N07 | 30-39 |
| 15 | 33 date_range_filter | TC-P07 | 30-39 |
| 16 | 34 malformed_date_range | TC-N08 | 30-39 |
| 17 | 40 subscription_details_contract | TC-P09 | 40-49 int |
| 18 | 41 pricing_details_contract | TC-P10 | 40-49 |
| 19 | 42 billing_details_contract | TC-P11 | 40-49 |
| 20 | 43 module_details_contract | TC-P12 | 40-49 |
| 21 | 44 details_require_id | TC-N03 | 40-49 |
| 22 | 45 pricing_missing_id_safe | TC-N04 | 40-49 |
| 23 | 50 tab_gated_viewAny | TC-P04 | 50-59 auth |
| 24 | 51 action_links_gated_view | TC-P13 | 50-59 |
| 25 | 52 pdf_export_gated | TC-P14 | 50-59 |
| 26 | 53 print_gated | TC-P15 | 50-59 |
| 27 | 54 guest_redirect | TC-N01 | 50-59 |
| 28 | 55 guest_ajax_not_authorised | TC-N02 | 50-59 |
| 29 | 56 permission_model_split | TC-D05/DEV-001 | 50-59 |
| 30 | 60 pagination_caps_ten | TC-P08 | 60-69 uiux |
| 31 | 61 empty_state | TC-D03 | 60-69 |
| 32 | 62 select_all_checkbox | TC-P14 | 60-69 |
| 33 | 63 row_checkboxes_ids | TC-P14 | 60-69 |
| 34 | 64 pdf_button_clickable | TC-P14 | 60-69 |
| 35 | 70 store_no_ids_400 | TC-N05 | 70-79 edge |
| 36 | 71 store_bad_id_graceful | TC-N06 | 70-79 |
| 37 | 72 print_view_renders | TC-P17 | 70-79 |
| 38 | 73 pricing_route_quirk | TC-D01/DEV-003 | 70-79 |
| 39 | 74 module_invoice_branch | TC-D02 | 70-79 |
| 40 | 90 xss_status | TC-S01 | 90-99 sec |
| 41 | 91 xss_date_range | TC-S02 | 90-99 |
| 42 | 92 ajax_id_injection | TC-S03 | 90-99 |
| 43 | 93 direct_url_requires_auth | TC-S04 | 90-99 |
