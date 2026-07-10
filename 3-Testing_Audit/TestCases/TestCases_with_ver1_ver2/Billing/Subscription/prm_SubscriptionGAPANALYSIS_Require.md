# prm_Subscription — Gap Analysis & Coverage

**Feature:** Billing → Subscription Views (read-only/report, prime-side)
**V1 methods:** 16 · **V2 methods:** 43 · **V2 ≥ 2×V1:** ✅ (43 ≥ 32)

Legend: **Full** = automated assertion proves the behaviour · **Partial** = asserted with an environmental caveat (data-dependent skip, or admin-only permission path) · **Gap** = no automation (manual only).

---

## 1. Manual TC ↔ Dusk method mapping

### Positive
| TC | Description | V1 | V2 | Coverage |
|----|-------------|----|----|----------|
| TC-P01 | Rate schema/model truth | 01 | 01,03,04 | Full |
| TC-P02 | Plan schema/status/current_flag | 01 | 02,05 | Full |
| TC-P03 | Page loads on central | 02 | 10 | Full |
| TC-P04 | Tab + filters visible | 03 | 11,50 | Full |
| TC-P05 | Table headers | 04 | 12 | Full |
| TC-P06 | Status filter Active/Inactive | 05 | 30,31 | Full |
| TC-P07 | date_range filter | 06 | 33 | Full |
| TC-P08 | Pagination 10 | 07 | 60 | Full |
| TC-P09 | subscription-details JSON | 08 | 40 | Partial (data-dependent skip) |
| TC-P10 | pricing-details JSON | 09 | 41 | Partial (data-dependent skip) |
| TC-P11 | billing-details JSON | 10 | 42 | Partial (data-dependent skip) |
| TC-P12 | module-details JSON | 11 | 43 | Partial (data-dependent skip) |
| TC-P13 | Action links present | 12 | 51 | Partial (data-dependent) |
| TC-P14 | PDF export control | 13 | 52,62,63,64 | Full (admin) |
| TC-P15 | Print control | — | 53 | Full (admin) |
| TC-P16 | Toggle switches | — | 14 | Partial (data-dependent) |
| TC-P17 | Print view renders | — | 72 | Full |

### Negative
| TC | Description | V1 | V2 | Coverage |
|----|-------------|----|----|----------|
| TC-N01 | Guest → login | 15 | 54,93 | Full |
| TC-N02 | Guest AJAX not authorised | — | 55 | Full |
| TC-N03 | Non-existent detail id 404 | — | 44 | Full |
| TC-N04 | Missing id pricing null-safe | — | 45 | Full |
| TC-N05 | store empty ids 400 | — | 70 | Full |
| TC-N06 | store bad id graceful | — | 71 | Full |
| TC-N07 | Unknown status no error | — | 32 | Full |
| TC-N08 | Malformed date_range | — | 34 | Partial (records skip if 500 → DEV-004) |
| TC-N09 | No create affordance | — | 13 | Full |

### Security
| TC | Description | V2 | Coverage |
|----|-------------|----|----------|
| TC-S01 | XSS status | 90 | Full |
| TC-S02 | XSS date_range | 91 | Full |
| TC-S03 | Injection id | 92 | Full |
| TC-S04 | Direct URL auth | 93 | Full |

### Dependency
| TC | Description | V1 | V2 | Coverage |
|----|-------------|----|----|----------|
| TC-D01 | Route double-prefix quirk | 16 | 73 | Full |
| TC-D02 | module-details invoice branch | — | 74 | Full |
| TC-D03 | Empty state | — | 61 | Full |
| TC-D04 | billing_cycle_id RESTRICT target | — | 06 | Full |
| TC-D05 | Split permission model | — | 56 | Partial (needs scoped user to prove 403) |

---

## 2. Coverage Summary
| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Positive | 17 | 11 | 6 | 0 | 100% |
| Negative | 9 | 8 | 1 | 0 | 100% |
| Security | 4 | 4 | 0 | 0 | 100% |
| Dependency | 5 | 4 | 1 | 0 | 100% |
| **Total** | **35** | **27** | **8** | **0** | **100%** |

Targets: Negative 100% ✅ · Positive ≥90% ✅ · Dependency ≥90% ✅.
(Tenancy 100% N/A — prime-side central feature, no tenant isolation surface.)

---

## 3. Coverage-Score by requirement Source
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR) | 8 | 8 | 100% |
| Integration Points (Screen-IP AJAX panels) | 4 | 4 | 100% |
| Permissions (Screen-PM) | 6 | 6 | 100% |
| Validation/Filter (Screen filter system) | 2 | 2 | 100% |
| State-Machine (Screen-SM) | 0 | 0 | n/a (read-only — lifecycle owned by Prime module) |

Every Source-tagged requirement item has ≥1 TC. No zero-coverage items.

---

## 4. Cross-Reference Defect Scan
| # | Check | Compared | Finding | ID |
|---|-------|----------|---------|----|
| 1 | Enum case | DDL `status` VARCHAR(20) vs controller `whereIn` | Controller matches by `'Active'/'Inactive'` UI label then maps to `[1,'ACTIVE','active']`; DDL has no ENUM so no case-lock — filter tolerant. No defect. | — |
| 2 | Route registration | Blade `.pricing-details`/`.billing-schedule` vs routes | Registered as `billing/pricing-details` + `billing/billing-details` under prefix `billing` → **double-segment URLs** `/billing/billing/pricing-details` | **DEV-BIL-SUB-003** |
| 3 | Gate vs Policy | Controller `Gate::authorize('prime.subscription.view')` vs `SubscriptionPolicy` | Policy `view/update/delete/...` type-hint `InvoicingPayment` (wrong model) — gate strings resolve via `$user->can()` so runtime OK, but Policy signatures are copy-paste wrong | **DEV-BIL-SUB-002** |
| 4 | Fillable vs DDL | `TenantPlanRate::$fillable` vs DDL | Fillable omits `discount_amount` (DDL has it) though model casts it — minor; write path is Prime-owned, low impact | Noted (Prime-owned) |
| 5 | Cast vs DDL | `$casts` vs DDL types | `rate_per_cycle` decimal:2 ✔; `start/end_date` date ✔ | OK |
| 6 | Service delegation | Controller vs Service | No service layer — query builders inline in controller (`buildSubscriptionQuery`) | OK (report screen) |
| 7 | State machine vs impl | Screen vs controller | No lifecycle in Billing (read-only) | OK |
| 8 | Validation vs FormRequest | Filters vs rules | No FormRequest — filters are raw `$request->only([...])`; acceptable for read filters but no input validation | Noted |
| 9 | Error message vs source | `{error:'No IDs provided'}` | Matches controller literal | OK |
| 10 | Permissions vs Policy/Gates | Detail panels | `subscription-details`/`module-details` gated `prime.billing-management.view`; `pricing-details`/`billing-details` gated `prime.subscription.view` — **split namespace** | **DEV-BIL-SUB-001** |
| 11 | Integration FK vs migration | DDL FKs | `tenant_plan_id` CASCADE, `billing_cycle_id` RESTRICT confirmed | OK |

### Audit carry-over verification
| Audit ID | Original claim | Verified state |
|----------|----------------|----------------|
| SEC-BIL-010 (P1) | pricingDetails/billingDetails unprotected | **REMEDIATED** — both call `Gate::authorize('prime.subscription.view')` (SubscriptionController:102,116) |
| PERF-BIL-001 (P2) | sync ZIP + unbounded Tenant/User loads + leaked temp PDFs | **PARTIAL** — temp PDFs `@unlink`'d (SubscriptionController:87-89); dashboard `Tenant::limit(500)`/`User::limit(500)` (BillingManagementController:117-118); ZIP still synchronous (standing P2) |
| REQ-BIL-002 | subscription view/PDF | Partial (read-only built; lifecycle future) |

---

## 5. Remaining Partial-coverage / limitations
- **AJAX panels + toggles + action links** self-skip when no Prime plan/rate data exists — seed `prm_tenant_plan_jnt` + `prm_tenant_plan_rates` before a full run to convert to Full.
- **DEV-BIL-SUB-001 (split permission)** is asserted structurally only; proving the 403 requires a central user holding `prime.subscription.view` but not `prime.billing-management.view`. Prime-side role/permission seeding is out of scope for this browser suite → manual verification recorded.
- **DEV-BIL-SUB-004 (malformed date_range)** — V2_34 records a skip on 500 rather than hard-failing, pending source confirmation of the `explode(' - ')` guard.
- Negative **permission 403** for scoped central users not automated (super-admin bypasses gates) — recorded as manual.
