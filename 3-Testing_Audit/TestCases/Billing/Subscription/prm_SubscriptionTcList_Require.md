# Subscription — Test Case List & Business Conditions (`prm_Subscription`)

| Field | Value |
|-------|-------|
| Module | Billing (BIL) |
| Feature / Screen | Subscription (read-only viewing layer) |
| DB scope | **PRIME / CENTRAL** (`prime_db`) — no tenant scaffolding |
| Prefix | `prm_` (primary query table `prm_tenant_plan_rates`) |
| Primary tables | `prm_tenant_plan_rates`, `prm_tenant_plan_jnt`, `prm_tenant_plan_module_jnt`, `prm_tenant_plan_billing_schedule(+s)`, `prm_plans`, `prm_billing_cycles`, `prm_module_plan_jnt` |
| Controllers | `BillingManagementController` (tab, panels, toggle, print), `SubscriptionController` (PDF/ZIP, pricing, billing-schedule) |
| Models | `Modules\Prime\Models\TenantPlanRate` / `TenantPlan` / `TenantPlanModule` / `TenantPlanBillingSchedule`; `Modules\Billing\Models\BillingCycle` |
| Screen file | `Billing_v1/subscription.md` |
| Test file | `prm_Subscription_TestCas.php` (37 methods) |
| Activity events (verbatim) | `Store` (PDF export), `ToggleStatus` (subscription flag toggle) |

> Read-only scope: the Billing module does **not** create/modify plans — plan assignment & pricing are owned by the Prime module. Billing provides the viewing/reporting layer. Coverage is therefore read-focused (render, filters, AJAX panels, flag toggles, export, permissions) with no create/edit/soft-delete matrix. These `prm_` models do **not** use SoftDeletes (tables have no `deleted_at`).

---

## 1. Business Conditions

### BC-DB (schema)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `prm_tenant_plan_rates` is the primary subscription-list table with `tenant_plan_id, start_date, end_date, billing_cycle_id, billing_cycle_day, credit_days, monthly_rate, rate_per_cycle, currency` | DDL-prm_tenant_plan_rates |
| BC-DB-02 | `prm_tenant_plan_jnt` holds subscription flags `is_subscribed, is_trial, auto_renew, automatic_billing, is_active` + `status VARCHAR(20)` (`ACTIVE/SUSPENDED/CANCELED/EXPIRED`) | DDL-prm_tenant_plan_jnt |
| BC-DB-03 | `prm_tenant_plan_jnt.current_flag` is a GENERATED STORED column; unique key `(current_flag, plan_id)` | DDL-prm_tenant_plan_jnt |
| BC-DB-04 | `prm_tenant_plan_module_jnt` links `module_id ↔ tenant_plan_id` (subscription→module junction) | DDL-prm_tenant_plan_module_jnt |
| BC-DB-05 | Billing-schedule table exists (`prm_tenant_plan_billing_schedule` per DDL) | DDL-prm_tenant_plan_billing_schedule |
| BC-DB-06 | Subscription read models declare **no** SoftDeletes (no `deleted_at`) | Model source + Audit-MIG-BIL-001 |

### BC-VAL (validation / negative)
| ID | Condition | Error / Behaviour | Source |
|----|-----------|-------------------|--------|
| BC-VAL-01 | Toggle with a field outside the allow-list is rejected | `422 {success:false, message:'Invalid subscription toggle field'}` | Controller toggleStatus |
| BC-VAL-02 | PDF export with no `ids` is rejected | `400 {error:'No IDs provided'}` | SubscriptionController::store |
| BC-VAL-03 | Detail panel with an unknown/absent id does not return 200 with data | `404` (findOrFail) / `500` (table mismatch) | subscriptionDetails |
| BC-VAL-04 | Reflected filter values (`status`, `date_range`) are HTML-escaped | injected script must not execute | Screen-Filter + Blade |

### BC-AUTH (permissions)
| ID | Condition | Permission | Source |
|----|-----------|-----------|--------|
| BC-AUTH-01 | Subscription tab visible when user holds any billing viewAny (incl. `prime.subscription.viewAny`) | `Gate::any([... prime.subscription.viewAny ...])` | index() |
| BC-AUTH-02 | PDF/ZIP export requires `prime.subscription.create` | `Gate::authorize` | store() |
| BC-AUTH-03 | Pricing & billing-schedule panels require `prime.subscription.view` | `Gate::authorize` | pricingDetails/billingDetails |
| BC-AUTH-04 | Subscription-details & module-details panels enforce `prime.billing-management.view` (⚠ not `prime.subscription.view`) | `Gate::authorize` | subscriptionDetails/moduleDetails |
| BC-AUTH-05 | Guest is redirected to `/login` (routes behind `['auth','verified']`) | middleware | routes/web.php |

### BC-BIZ (business rules / behaviour)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Billing module is read-only for subscriptions (no create/edit UI on the tab) | Screen-BR "Read-Only Scope" |
| BC-BIZ-02 | Subscription list paginates 10 per page | Screen-BR + index() `paginate(10)` |
| BC-BIZ-03 | Table renders Organization, Plan(v), Billing Period, Billing Cycle, Credit/Billing Day, Sub Status + flag switches | subscription.blade.php |
| BC-BIZ-04 | PDF export logs activity `Store` per record | store() `activityLog(...,'Store',...)` |
| BC-BIZ-05 | Subscription flag toggle logs activity `ToggleStatus` | toggleStatus() |

### BC-SM (state machine — subscription flags / status)
| ID | State → Trigger → Next | Source |
|----|-----------------------|--------|
| BC-SM-01 | flag=0 → toggle(field) → flag=1 (and inverse) for each of `automatic_billing, auto_renew, is_trial, is_subscribed, is_active` | toggleStatus subscription branch |
| BC-SM-02 | `status` lifecycle values are `ACTIVE/SUSPENDED/CANCELED/EXPIRED` (string) | DDL comment |
| BC-SM-03 | Illegal: toggle without `type=subscription` must not flip a plan flag (routes to payment branch) | toggleStatus fallthrough |

### BC-INT (integration / junctions)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Subscription-details panel joins schedule → tenantPlan → plan/tenant, and matching rate by date window | subscriptionDetails |
| BC-INT-02 | Pricing panel loads `TenantPlanRate` by `tenant_plan_id` | pricingDetails |
| BC-INT-03 | Billing-schedule panel loads `TenantPlanBillingSchedule` by `tenant_plan_id` | billingDetails |
| BC-INT-04 | Module-details `type=subscription` → `TenantPlanModule`; else → `BillOrgInvoicingModulesJnt` (invoice join) | moduleDetails |

### BC-EDG (edge)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `Inactive` status filter maps only to `IN (0,'INACTIVE','inactive')` — `SUSPENDED/CANCELED/EXPIRED` fall through both filters | buildSubscriptionQuery |
| BC-EDG-02 | Empty result window still renders the table shell | index()/blade |
| BC-EDG-03 | GENERATED `current_flag` references pre-rename `org_id` in the DDL (drift) | DDL-prm_tenant_plan_jnt |

### Known / Candidate Source Defects (DEV-###)
| ID | Severity | Description | Proving test |
|----|----------|-------------|--------------|
| DEV-BIL-SUB-001 | High | Model `TenantPlanBillingSchedule::$table = 'prm_tenant_plan_billing_schedules'` (plural) vs DDL `prm_tenant_plan_billing_schedule` (singular) → subscription-details/billing-schedule panels throw 42S02 on a schema-correct DB | `test_..._03`, `_40`, `_42` |
| DEV-BIL-SUB-002 | Medium | `subscription.blade.php` renders `status == 1 ? 'Active' : 'Deactive'` but `status` is a VARCHAR (`'ACTIVE'`); `'ACTIVE' == 1` is false in PHP 8 → every plan shows "Deactive" | `test_..._23` |
| DEV-BIL-SUB-003 | Low | Permission inconsistency: screen maps detail view → `prime.subscription.view`, but `subscriptionDetails()`/`moduleDetails()` enforce `prime.billing-management.view` | `test_..._54` |
| DEV-BIL-SUB-004 | Low (edge) | `Inactive` filter cannot select `SUSPENDED/CANCELED/EXPIRED` plans (BC-EDG-01) | `test_..._70` |
| (audit) MIG-BIL-001 | P0 | Module-wide SoftDeletes/timestamps vs DDL — subscription models correctly avoid SoftDeletes; billing-cycle sibling affected | `test_..._01` (asserts no SoftDeletes) |
| (audit) SEC-BIL-010 | P1 → resolved for Subscription | `pricingDetails`/`billingDetails` now carry `Gate::authorize` (were unprotected at audit time) | `test_..._53` |

---

## 2. Test Case List

### Positive (`TC-P`)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01/02 | DDL | Schema tables/columns + model config correct | all present; no SoftDeletes | `test_..._01` | ✅ |
| TC-P02 | BC-AUTH-01 | routes | Routes & gates registered | `Route::has` true | `test_..._02` | ✅ |
| TC-P03 | BC-BIZ-03 | Blade | Billing-management page loads w/ subscription tab | `#subscription-tab` present | `test_..._10` | ✅ |
| TC-P04 | BC-BIZ-03 | Blade | Tab shows filters + table | date_range, status, hidden type, table | `test_..._11` | ✅ |
| TC-P05 | BC-BIZ-02/03 | Controller | `type=subscription_data` paginated table | header columns visible | `test_..._12` | ✅ |
| TC-P06 | BC-BIZ-03 | Blade | Status filter keeps subscription context | url keeps `subscription_data` | `test_..._13` | ✅ |
| TC-P07 | BC-BIZ-03 | Controller | Date-range filter renders | table present | `test_..._14` | ✅ |
| TC-P08 | BC-SM-01 | Controller | Toggle flips each allowed flag + restore | 200 + DB flip | `test_..._20` | ✅ |
| TC-P09 | BC-INT-01 | Controller | Subscription-details panel JSON html | 200 `{html}` (or skip DEV-001) | `test_..._40` | ✅ |
| TC-P10 | BC-INT-02 | Controller | Pricing panel JSON html | 200/500 | `test_..._41` | ✅ |
| TC-P11 | BC-INT-03 | Controller | Billing-schedule panel JSON html | 200/500 | `test_..._42` | ✅ |
| TC-P12 | BC-INT-04 | Controller | Module-details subscription-type JSON | 200 `{html}` | `test_..._43` | ✅ |
| TC-P13 | BC-INT-04 | Controller | Module-details invoice-type join | 200/500 | `test_..._44` | ✅ |
| TC-P14 | BC-INT-01..03 | Model | Rate relationships resolve | no throw | `test_..._45` | ✅ |
| TC-P15 | BC-BIZ-02 | Controller | Pagination 10/page | source assert | `test_..._60` | ✅ |
| TC-P16 | BC-AUTH-02/03 | Blade | Export/print controls present | one present | `test_..._61` | ✅ |
| TC-P17 | BC-BIZ-03 | Controller | Print/data subscription view | 200/500 | `test_..._62` | ✅ |

### Negative (`TC-N`)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-VAL-01 | Controller | Toggle invalid field | 422 exact message | `test_..._21` | ✅ |
| TC-N02 | BC-SM-03 | Controller | Toggle without type=subscription doesn't flip plan | flag unchanged | `test_..._22` | ✅ |
| TC-N03 | BC-VAL-03 | Controller | Subscription-details bogus id | 404/500 (not 200) | `test_..._30` | ✅ |
| TC-N04 | BC-VAL-03 | Controller | Pricing panel missing id | 200 envelope / 500 | `test_..._31` | ✅ |
| TC-N05 | BC-VAL-02 | Controller | PDF export no ids | 400 exact message | `test_..._32` | ✅ |
| TC-N06 | BC-VAL-04 | Blade | XSS in status filter escaped | no script exec | `test_..._33` | ✅ |
| TC-N07 | BC-VAL-04 | Blade | XSS in date_range escaped | no script exec | `test_..._34` | ✅ |
| TC-N08 | BC-AUTH-05 | routes | Guest redirected to /login | `/login` | `test_..._50` | ✅ |

### Dependency / State / Security (`TC-D` / `TC-S`)
| TC ID | BC | Sub-cat | Description | Method | Status |
|-------|----|---------|-------------|--------|--------|
| TC-D01 | BC-SM-01 | F | Toggle lifecycle each flag round-trip | `test_..._20` | ✅ |
| TC-D02 | BC-INT-04 | E | Cross-source module details (subscription vs invoice) | `test_..._43/44` | ✅ |
| TC-D03 | BC-DB-03/EDG-03 | G | Generated `current_flag` column definition | `test_..._72` | ✅ |
| TC-S01 | BC-VAL-04 | — | Reflected XSS (status/date) | `test_..._33/34` | ✅ |
| TC-S02 | BC-VAL-03 | — | IDOR-shape unknown direct id | `test_..._90` | ✅ |
| TC-A01 | — | — | No SEVERE console errors on tab load | `test_..._91` | ✅ |

### Cross-layer / Defect probes
| TC ID | BC | Description | Method |
|-------|----|-------------|--------|
| TC-X01 | DEV-BIL-SUB-001 | Billing-schedule table-name mismatch | `test_..._03` |
| TC-X02 | DEV-BIL-SUB-002 | Sub-status string==1 display bug | `test_..._23` |
| TC-X03 | DEV-BIL-SUB-003 | Permission-key inconsistency | `test_..._54` |
| TC-X04 | DEV-BIL-SUB-004 | Inactive filter cannot match SUSPENDED etc. | `test_..._70` |
| TC-X05 | BC-AUTH-01/02/03 | Gate presence on index/store/panels | `test_..._51/52/53` |
| TC-X06 | BC-EDG-02 | Empty state renders | `test_..._71` |
| TC-X07 | BC-BIZ-01 | Read-only (no write UI) | `test_..._15` |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_subscription_01_schema_tables_columns_and_model_configuration_are_correct` | TC-P01 | Schema | 01–09 |
| 2 | `test_subscription_02_subscription_routes_and_gates_are_registered` | TC-P02 | Schema/Route | 01–09 |
| 3 | `test_subscription_03_billing_schedule_model_table_name_matches_ddl` | TC-X01 | Defect probe | 01–09 |
| 4 | `test_subscription_10_billing_management_page_loads_with_subscription_tab` | TC-P03 | Biz | 10–19 |
| 5 | `test_subscription_11_subscription_tab_shows_filters_and_table` | TC-P04 | Biz | 10–19 |
| 6 | `test_subscription_12_subscription_data_type_returns_paginated_table` | TC-P05 | Biz | 10–19 |
| 7 | `test_subscription_13_status_filter_active_keeps_user_on_subscription_type` | TC-P06 | Biz | 10–19 |
| 8 | `test_subscription_14_date_range_filter_applies_without_error` | TC-P07 | Biz | 10–19 |
| 9 | `test_subscription_15_billing_module_exposes_no_write_ui_for_subscription` | TC-X07 | Biz | 10–19 |
| 10 | `test_subscription_20_toggle_updates_each_allowed_flag` | TC-P08/TC-D01 | State | 20–29 |
| 11 | `test_subscription_21_toggle_invalid_field_returns_422` | TC-N01 | Validation | 20–29 |
| 12 | `test_subscription_22_toggle_default_type_does_not_touch_tenant_plan` | TC-N02 | State | 20–29 |
| 13 | `test_subscription_23_sub_status_column_display_reflects_string_status` | TC-X02 | Defect probe | 20–29 |
| 14 | `test_subscription_30_subscription_details_invalid_id_is_rejected` | TC-N03 | Validation | 30–39 |
| 15 | `test_subscription_31_pricing_details_missing_id_returns_json_envelope` | TC-N04 | Validation | 30–39 |
| 16 | `test_subscription_32_pdf_export_without_ids_returns_400` | TC-N05 | Validation | 30–39 |
| 17 | `test_subscription_33_xss_in_status_filter_is_escaped` | TC-N06/TC-S01 | Security | 30–39 |
| 18 | `test_subscription_34_xss_in_date_range_filter_is_escaped` | TC-N07/TC-S01 | Security | 30–39 |
| 19 | `test_subscription_40_subscription_details_panel_returns_json_html` | TC-P09 | Integration | 40–49 |
| 20 | `test_subscription_41_pricing_details_panel_returns_json_html` | TC-P10 | Integration | 40–49 |
| 21 | `test_subscription_42_billing_schedule_panel_returns_json_html` | TC-P11 | Integration | 40–49 |
| 22 | `test_subscription_43_module_details_subscription_type_returns_json_html` | TC-P12 | Integration | 40–49 |
| 23 | `test_subscription_44_module_details_defaults_to_invoice_join` | TC-P13/TC-D02 | Integration | 40–49 |
| 24 | `test_subscription_45_tenant_plan_rate_relationships_resolve` | TC-P14 | Integration | 40–49 |
| 25 | `test_subscription_50_guest_is_redirected_to_login` | TC-N08 | Auth | 50–59 |
| 26 | `test_subscription_51_subscription_tab_gate_any_includes_subscription_viewany` | TC-X05 | Auth | 50–59 |
| 27 | `test_subscription_52_pdf_export_enforces_subscription_create_gate` | TC-X05 | Auth | 50–59 |
| 28 | `test_subscription_53_detail_panels_enforce_view_gates` | TC-X05 | Auth | 50–59 |
| 29 | `test_subscription_54_permission_key_inconsistency_between_layers_is_documented` | TC-X03 | Defect probe | 50–59 |
| 30 | `test_subscription_60_subscription_list_is_paginated_ten_per_page` | TC-P15 | UI/UX | 60–69 |
| 31 | `test_subscription_61_export_and_print_controls_present` | TC-P16 | UI/UX | 60–69 |
| 32 | `test_subscription_62_print_data_endpoint_serves_subscription_view` | TC-P17 | UI/UX | 60–69 |
| 33 | `test_subscription_70_status_filter_inactive_only_matches_zero_family` | TC-X04 | Edge | 70–79 |
| 34 | `test_subscription_71_empty_subscription_tab_renders_without_error` | TC-X06 | Edge | 70–79 |
| 35 | `test_subscription_72_tenant_plan_generated_current_flag_column_definition` | TC-D03 | Edge | 70–79 |
| 36 | `test_subscription_90_detail_panel_rejects_unknown_direct_id` | TC-S02 | Security | 90–99 |
| 37 | `test_subscription_91_no_severe_console_errors_on_tab_load` | TC-A01 | Security/a11y | 90–99 |
