# bil_GatewayIntegration — Gap Analysis & Coverage

**Status:** 🚧 **PLANNING-STAGE SET.** This is explicitly a planning-stage artifact set: **100% of behavioural coverage is deferred (skipped)** because the feature is unbuilt. The single unbuilt-requirement is flagged below as a **DEV / gap**.

---

## 1. Coverage Model for a planning-stage set

- **Assertive coverage:** 1 method (`test_01`) — proves the *current reality* (the gap). This is the only method that runs assertions.
- **Deferred (planned) coverage:** 38 methods — each documents its intended assertion in a comment, then `markTestSkipped(...)`. They exist so the planned matrix is enumerated and traceable, and so the suite stays **green** (no false failures against non-existent code).
- **Behavioural coverage today:** **0% executed / 100% deferred** — by design.

---

## 2. Manual TC ↔ Dusk method mapping

| Manual TC | Dusk method | Coverage | Note |
|-----------|-------------|----------|------|
| MT-R01 | `..._01_planning_stage_reality_gap_is_documented` | **Full (asserts)** | Proves the gap: column present; no table/controller/route |
| MT-P10..P14 (config CRUD + test-connection) | `..._10..14` | **Deferred** | Skipped — not built |
| MT-P15..P19 (webhook events) | `..._15..19` | **Deferred** | Skipped — not built |
| MT-SM20..SM24 (state machine) | `..._20..24` | **Deferred** | Skipped — not built |
| MT-N30..N34 (validation) | `..._30..34` | **Deferred** | Skipped — not built |
| MT-D40..D43 (integration/FK) | `..._40..43` | **Deferred** | Skipped — not built |
| MT-A50..A52 (permissions) | `..._50..52` | **Deferred** | Skipped — not built |
| MT-U60..U62 (UI) | `..._60..62` | **Deferred** | Skipped — not built |
| MT-E70..E72 (edge) | `..._70..72` | **Deferred** | Skipped — not built |
| MT-S90..S92 / MT-T93..T94 (security/tenancy) | `..._90..94` | **Deferred** | Skipped — not built |

Every TC-ID maps to exactly one method; every method maps back to a TC/BC. No orphans.

---

## 3. Coverage Summary

| Category | Total TC | Full (asserts) | Deferred | Gap (unmapped) | % Executed |
|----------|----------|----------------|----------|----------------|-----------|
| Config-truth / reality | 1 | 1 | 0 | 0 | 100% |
| Positive / Business | 10 | 0 | 10 | 0 | 0% (deferred) |
| State-machine | 5 | 0 | 5 | 0 | 0% (deferred) |
| Negative / Validation | 5 | 0 | 5 | 0 | 0% (deferred) |
| Dependency / Integration | 4 | 0 | 4 | 0 | 0% (deferred) |
| Permissions | 3 | 0 | 3 | 0 | 0% (deferred) |
| UI/UX | 3 | 0 | 3 | 0 | 0% (deferred) |
| Edge | 3 | 0 | 3 | 0 | 0% (deferred) |
| Security / Tenancy | 5 | 0 | 5 | 0 | 0% (deferred) |
| **Total** | **39** | **1** | **38** | **0** | **2.6% executed / 97.4% deferred** |

> The standard gates (Negative 100%, Positive ≥ 90%, Dependency ≥ 90%, Tenancy 100%) are **N/A / deferred** for a planning-stage feature — they will be measured once the feature is implemented and the stubs are fleshed out. This is a deliberate, documented state, not a coverage failure.

---

## 4. Coverage-Score by requirement Source (WP-F)

| Section | Covered (asserts) | Total | % | Note |
|---------|-------------------|-------|---|------|
| Business Rules (`Screen-BR`) | 0 | 4 | 0% | Deferred (10–24, 40–43) |
| State-Machine (`Screen-SM`) | 0 | 5 | 0% | Deferred (20–24) |
| Validation Rules (`Screen-VR`) | 0 | 5 | 0% | Deferred (30–34) |
| Integration Points (`Screen-IP`) | 0 | 4 | 0% | Deferred (40–43) |
| Permissions (`Screen-PM`) | 0 | 3 | 0% | Deferred (50–52) |
| Webhook Security (critical) | 0 | 5 | 0% | Deferred (90–94) |
| DB hook present (`DDL`) | 1 | 1 | 100% | Asserted by test_01 |

Every `Source`-tagged requirement item has ≥1 mapped TC (all deferred except the DB-hook truth). No requirement item is left with 0 TCs.

---

## 5. Cross-Reference Defect Scan

The 11-check scan was run against the current source. Because the feature is unbuilt, most checks are **N/A (no code to compare)**; the material finding is the missing implementation itself.

| # | Check | Result |
|---|-------|--------|
| 1 | Enum case (DDL ENUM vs FormRequest `in:`) | N/A — no FormRequest. `payment_status` values `INITIATED/SUCCESS/FAILED` exist in DDL only. |
| 2 | Route registration (Blade `route()` vs `routes/*.php` + Provider) | **Finding → REQ-BIL-014**: planned routes referenced in requirement but **never registered** (`web.php`/`api.php` have none). `mapApiRoutes()` IS called, so `api.php` is live — the routes just don't exist. |
| 3 | Gate vs Policy | N/A — no controller/gate; permission keys exist only in the requirement. |
| 4 | Fillable vs DDL | Partial — `InvoicingPayment` model exists; `gateway_response` present in DDL. Verify it is in `$fillable` before webhook writes (not asserted here — out of feature scope). |
| 5 | Cast vs DDL | N/A — no gateway model. |
| 6 | Service delegation | N/A — no service. |
| 7 | State machine vs impl | **Finding → REQ-BIL-014**: documented transitions (INITIATED→SUCCESS/FAILED; gateway connected/disconnected/error) have **no implementation**. |
| 8 | Validation vs FormRequest | N/A — no FormRequest. |
| 9 | Error message vs FormRequest | N/A — no `messages()`. |
| 10 | Permissions vs Policy/Gates | **Finding → REQ-BIL-014**: `prime.invoicing-payment.create` / `prime.invoicing-audit-log.viewAny` required by the screen but no gate enforces them for gateway flows. |
| 11 | Integration FK vs migration | Partial — `bil_tenant_invoicing_payments.tenant_invoice_id` FK exists; webhook consumer that would use it is absent. |

---

## 6. Known Gap / Defect Register (DEV-equivalent)

| ID | Type | Severity | Description | Evidence | Proving test | Status |
|----|------|----------|-------------|----------|--------------|--------|
| REQ-BIL-014 | **Unbuilt requirement (DEV/gap)** | High (feature) | Payment Gateway Integration (Razorpay) is entirely unimplemented: no gateway table, no controller, no route, no webhook receiver, no signature verification, no payment UI, no config wiring. Only a pre-provisioned, unused `gateway_response` JSON column and an unwired SDK/config stub exist. | `gateway-integration.md` Current-State table; audit `Billing_Complete_Audit_2026-06-29.md` L382; source verification 2026-Jul-10. | `test_gateway_integration_01_*` (asserts the gap); 38 skipped stubs enumerate the deferred behaviour. | **OPEN — DEV backlog** |

**Legend:** *Full (asserts)* = method runs real assertions; *Deferred* = `markTestSkipped()` placeholder for planned behaviour; *Gap* = a TC with no mapped method (none here).
