# Subscription — Gap Analysis (`prm_Subscription`)

Single comprehensive suite: **`prm_Subscription_TestCas.php` — 37 methods**. Read-focused screen (Billing viewing layer): render, filters, AJAX panels, flag toggles, export, permissions, security. No create/edit/soft-delete matrix (read-only scope; models have no SoftDeletes).

## 1. Manual TC ↔ Dusk Method Mapping

| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| MTC-01 tab loads | `_10` | Full |
| MTC-02 filters present | `_11` | Full |
| MTC-03 data listing | `_12`, `_60` | Full |
| MTC-04 status filter | `_13`, `_70` | Full |
| MTC-05 flag toggles | `_20` | Full |
| MTC-06 invalid toggle field | `_21` | Full |
| MTC-07 toggle w/o type | `_22` | Full |
| MTC-08 detail panels | `_40`, `_41`, `_42`, `_43`, `_44` | Full |
| MTC-09 invalid detail id | `_30`, `_90` | Full |
| MTC-10 PDF/ZIP export | `_32` (no-ids), `_52` (gate) | Partial — happy-path ZIP stream asserted via gate/route only (binary stream not diffed) |
| MTC-11 XSS filters | `_33`, `_34` | Full |
| MTC-12 guest redirect | `_50` | Full |
| MTC-13 sub-status display bug | `_23` | Full (documents current behaviour) |

## 2. Coverage Summary (by category)

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive | 17 | 16 | 1 | 0 | 94% |
| Negative | 8 | 8 | 0 | 0 | 100% |
| Dependency/State | 3 | 3 | 0 | 0 | 100% |
| Security/a11y | 3 | 3 | 0 | 0 | 100% |
| Defect probes (X) | 7 | 7 | 0 | 0 | 100% |
| **Overall** | **38** | **37** | **1** | **0** | **97%** |

Gates: Negative **100%** ✅ · Positive **94% (≥90%)** ✅ · Dependency **100% (≥90%)** ✅ · Tenancy **N/A** (central single-DB module — no per-tenant isolation surface).

### Remaining Partial
| TC | Limitation | Reason |
|----|-----------|--------|
| MTC-10 (ZIP stream) | Binary ZIP body not byte-verified; only the `400 no-ids` guard + `prime.subscription.create` gate are asserted | Dusk cannot diff a streamed ZIP; export happy-path needs seeded `prm_tenant_plan_rates` ids and is environment-heavy |

## 3. Coverage-Score by Requirement Source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR) | 5 | 5 | 100% |
| Filters (Screen-Filter) | 2 | 2 | 100% |
| CRUD/Panels (Screen-Ops) | 6 | 6 | 100% |
| Permissions (Screen-PM) | 3 | 3 | 100% |
| State-Machine (BC-SM) | 3 | 3 | 100% |
| Integration (BC-INT) | 4 | 4 | 100% |
| Edge (BC-EDG) | 3 | 3 | 100% |

Every `Source`-tagged requirement item has ≥1 TC.

## 4. Cross-Reference Defect Scan (11 checks)

| # | Check | Compare | Finding | Code | Test |
|---|-------|---------|---------|------|------|
| 1 | Enum case | DDL `status` ENUM comment vs filter `in:` | Filter maps `Active/Inactive` only; `SUSPENDED/CANCELED/EXPIRED` unreachable | DEV-BIL-SUB-004 | `_70` |
| 2 | Route registration | Blade `route('central.billing...')` vs routes/web.php | All subscription routes registered (once) under `central.billing.*` | OK | `_02` |
| 3 | Gate vs Policy | `Gate::authorize('prime.subscription.*')` vs `SubscriptionPolicy` | Policy methods exist; `view` type-hints `InvoicingPayment` (copy-paste smell, harmless) | Note | `_51/52/53` |
| 4 | Fillable vs DDL | `TenantPlanRate/TenantPlan` `$fillable` vs DDL | Aligned | OK | `_01` |
| 5 | Cast vs DDL | model `$casts` vs DDL | `TenantPlanRate` decimal/date casts match | OK | `_01` |
| 6 | Service delegation | controller vs service | No Service layer for Subscription (logic in controllers) | N/A | — |
| 7 | State machine vs impl | flag toggles vs controller | Allow-list enforced; illegal path (no type) doesn't flip | OK | `_20/21/22` |
| 8 | Validation vs request | toggle field / export ids | Field allow-list + ids-required present | OK | `_21/32` |
| 9 | Error message vs source | expected vs literal | `'Invalid subscription toggle field'`, `'No IDs provided'` verbatim | OK | `_21/32` |
| 10 | Permissions vs matrix | screen matrix vs gates | subscription-details uses `prime.billing-management.view` not `prime.subscription.view` | DEV-BIL-SUB-003 | `_54` |
| 11 | Integration FK vs table | model table vs DDL | `TenantPlanBillingSchedule` → `prm_tenant_plan_billing_schedules` (plural) vs DDL singular | DEV-BIL-SUB-001 | `_03/40/42` |

### Additional layer findings
- **DEV-BIL-SUB-002** (Blade `status == 1` vs VARCHAR status) — "Sub Status" always renders "Deactive" → `_23`.
- **Audit MIG-BIL-001 (P0)** — module-wide SoftDeletes/timestamps vs DDL. Subscription models correctly avoid SoftDeletes; suite asserts this (`_01`) so a regression that adds the trait fails.
- **Audit SEC-BIL-010 (P1)** — was: `pricingDetails`/`billingDetails` unprotected. **Now resolved** (both carry `Gate::authorize('prime.subscription.view')`); `_53` guards against regression.
- **DDL drift** — `prm_tenant_plan_jnt.current_flag` GENERATED references pre-rename `org_id`; `fk_tenantPlanRates_orgPlanId` references `organization_plan_id`; `prm_plans` has a trailing comma before `)`. These are Prime-DDL authoring errors (out of Billing app scope) — recorded as edge notes (`_72`), not asserted as app defects.

## 5. Legend
Full = every step of the manual TC is asserted by a method. Partial = core asserted, a sub-aspect (e.g. binary stream) not machine-verified. Gap = no method. Defect probes assert **current** behaviour and are wired to `markTestIncomplete`/documentation so a fix flips them visibly.
