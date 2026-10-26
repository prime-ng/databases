# Module: Dashboard

Append-only rollup. Newest entries at the bottom.

## 2026-10-20 — Insights engine, rules, digest, card actions

- **Commits:** `65d769306`, `a1aa5436a` (plus merge `25b7d5121`)
- **Files:** ~70 (engine, 33 rules, 4 models, 4 migrations, 2 consoles, 2 controllers, 4 requests, views, routes, tests)
- **What:**
  - Built `InsightEngine`, `InsightRegistry`, `InsightCache`, `PriorityScorer`, `InsightFeed`, `InsightContext`, `Finding`, `InsightActionService`.
  - Added 33 rule classes (fee, transport, hostel, library, inventory, payroll, behaviour, complaints, documents, vaccination, vendor agreements, etc.).
  - Added models `Insight`, `InsightAction`, `InsightRule`, `InsightRun` and tenant migrations `2026_10_20_000001..4`.
  - Settings UI (`insights/settings.blade.php`), dashboard section component, management/principal dashboards, routes and `RunInsightsCommand`.
  - Follow-up: `CardAction` contract, `FeeReminderCardAction`, `SendInsightDigestCommand`, `InsightDigestNotificationSeeder`, `StudentAtRiskRule`.
- **Tests:** `InsightEngineTest`, `InsightRulesTest` added; execution result `unknown`.
- **Status:** Done
- **Report:** `ai-brain-daily/daily/2026-10-20.md`

## 2026-10-21 — 107 rules, management page, topbar insights, role dashboards

- **Commits:** `93a086652`, `cda61a9d2`, `7cc9ac488` (Tarun) + audit records in `02e8afd59` / `c8d71c667`
- **Files:** 145 unique
- **What:**
  - Expanded the insight rule set to 107 rules and moved the engine/management page/role dashboards into Dashboard.
  - Added the Insights management page under Core Configuration.
  - Topbar lightbulb dropdown + insights page + per-user read state; removed insight cards from role dashboards.
  - Audit records moved under `-done` folders.
- **Tests:** not run (no test output recorded)
- **Status:** Done
- **Report:** `ai-brain-daily/daily/2026-10-21.md`

## 2026-10-22 — Leadership Key Insights panel, card grouping, demo cards seeder

- **Commits:** `f5ad6ca3a`, `84a99280b`, `acc914fc1` (Tarun Chauhan)
- **Files:** 28 unique
- **What:**
  - Demo cards seeder added; fixed `glb_app_modules` on `migrate:fresh`.
  - Added Key Insights panel to leadership dashboards with pinnable insight cards.
  - Grouped cards by module, packed 2-3 cards per row, added Library card design.
- **Status:** Done
- **Report:** [daily/2026-10-22.md](../daily/2026-10-22.md)
