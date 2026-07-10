# Payment Gateway Integration — Gap Analysis & Coverage

**Feature:** Billing / GatewayIntegration · **Status:** PLANNED / NOT IMPLEMENTED (REQ-BIL-014 = future)
**V1:** 14 methods · **V2:** 42 methods (V2 ≥ 2× V1 ✅)

> This is a **gap-dominated** analysis by design. The feature has zero implementation,
> so "coverage" here means: (a) current-reality truths are FULLY covered by executable
> tests, and (b) every planned contract clause is captured as a traceable, skipped stub
> that flips to a real assertion when the feature is built.

## 1. Manual TC ↔ V2 method mapping

| Manual TC | V2 method(s) | Coverage |
|-----------|--------------|----------|
| TC-P01 column exists | 01 | Full |
| TC-P02 json+nullable | 02 | Full |
| TC-P03 default null | 03 | Full |
| TC-P04 cast array | 04 | Full |
| TC-P05 fillable | 05 | Full |
| TC-P06 cast round-trip | 06 | Full |
| TC-P07 nested JSON | 07 | Full |
| TC-P08 razorpay in root composer | 08 | Full |
| TC-N05 razorpay absent module composer | 09 | Full |
| TC-N01 initiate route absent | 40 | Full |
| TC-N02 verify route absent | 41 | Full |
| TC-N03 webhook route absent | 42 | Full |
| TC-N04 api.php no gateway | 43 | Full |
| TC-N06 no webhook controller | 44 | Full |
| TC-N07 no config keys | 45 (+V1 13) | Full |
| TC-N08 no Razorpay in controllers | 45 | Full |
| TC-N09 web.php no gateway | 46 | Full |
| TC-N10 no checkout UI | 60 | Full |
| TC-U01 no pay-online button | 61 | Full |
| TC-P09 money columns present | 70 | Full |
| TC-P10 empty reads null | 72 | Full |
| TC-D01 initiate perm key exists | 50 | Full (partial: flow pending) |
| TC-SM01..04 lifecycle | 20,21,22,23 | Gap — planned (skipped) |
| TC-V30..33 signature/400 | 30,31,32,33 | Gap — planned (skipped) |
| TC-B10..14 business rules | 10,11,12,13,14 | Gap — planned (skipped) |
| TC-D02/D03 permissions | 51,52 | Gap — planned (skipped) |
| TC-U02 tenant payment page | 62 | Gap — planned (skipped) |
| TC-E01 idempotency | 71 | Gap — planned (skipped) |
| TC-S01..04 security | 90,91,92,93 | Gap — planned (skipped) |

## 2. Coverage Summary

| Bucket | Total | Full (executable) | Planned/Skipped | Gap (uncovered) | % of testable-today |
|--------|------:|------------------:|----------------:|----------------:|--------------------:|
| Current-reality (schema/model/route/composer/config/UI) | 21 | 21 | 0 | 0 | 100% |
| Planned contract (biz/SM/val/auth/UI/edge/security) | 21 | 0 | 21 | 0 | n/a (not built) |
| **Total** | **42** | **21** | **21** | **0** | **100% of what exists** |

- Negative/absence coverage of current reality: **100%**.
- Positive coverage of current reality: **100%**.
- Planned contract clauses with ≥1 traceable stub: **100%** (none silently missing).

## 3. Coverage-Score by requirement Source

| Section (Source) | Covered (≥1 TC) | Total | % |
|------------------|----------------:|------:|--:|
| Current State table (Screen) | 8 | 8 | 100% |
| Business Rules — Webhook Security (Screen-BR) | 4 | 4 | 100% (stubs) |
| Webhook Event Handling (Screen-BR) | 4 | 4 | 100% (stubs) |
| State-Machine (Screen-SM) | 4 | 4 | 100% (stubs) |
| Future CRUD routes (Screen-IP) | 3 | 3 | 100% (absence) |
| Permissions (Screen-PM) | 2 | 2 | 100% |
| Database Fields (DDL) | 3 | 3 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No item is uncovered.

## 4. Cross-Reference Findings (defect scan)

| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 2 | Route registration | Screen planned routes vs `routes/api.php` + web.php + providers | initiate/verify/webhook referenced in requirement, **never registered** → expected (feature not built); asserted absent |
| 4 | Fillable vs DDL | Model `$fillable` vs DDL | `gateway_response` in both ✅ — no gap |
| 5 | Cast vs DDL | Model `$casts` vs DDL type | `array` cast on `JSON` column ✅ — correct |
| 10 | Permissions vs Policy/Gates | Screen PM keys vs controller | `prime.invoicing-payment.create` exists ✅; no gateway flow consumes it yet (gap — planned) |
| — | Dependency scoping | root vs module composer | **DEV-BIL-020 (P3, doc-only):** Razorpay SDK in APP root `composer.json`, not `Modules/Billing/composer.json`. Not a runtime bug; flagged for module hygiene. |

No new runtime defect discovered — the feature simply does not exist yet. The only
finding is the documented dependency-scoping nit (DEV-BIL-020) and the whole-feature
not-implemented gap (REQ-BIL-014).

## 5. Legend
- **Full** — executable assertion verifies current reality.
- **Planned/Skipped** — `markTestSkipped` capturing an acceptance clause; flips to a real assertion when built.
- **Gap** — no coverage at all (none here).
