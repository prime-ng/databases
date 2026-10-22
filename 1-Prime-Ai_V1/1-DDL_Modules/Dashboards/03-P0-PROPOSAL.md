# P0 Foundation — proposal

20 Oct 2026 · for approval before any code · branch `development` (prime_ai)

P0 builds the engine, the 4 tables, the card, the settings screen and **2 pilot rules** that prove the
whole loop end to end. P1 (Principal, ~30 rules) starts only after P0's exit gate.

## Decisions taken (20 Oct 2026)

| # | Decision | Answer |
|---|---|---|
| D6 | Card status writes | **Full lifecycle**: acknowledge, assign (owner + due), snooze, dismiss with reason. Never touches school data. |
| D1 | Thresholds | **Defaults in each rule + a settings screen** to override them and switch rules on/off per school |
| D8 | Existing role dashboards | **Add on top**: insight sections above the current widgets, nothing removed |
| D10 | Table prefix | **`dsh_`** |

Still open, not needed for P0: D2 Management sees named teachers? · D3 LMS-01 measure · D4 salary in TT-01 ·
D5 needs-data items · D7 digest channels · D9 build order after Principal.

## Where the cards appear

| Role | Lands on (sys_role_dashboards) | P0 placement |
|---|---|---|
| Super Admin, School Admin | `/dashboard` | Insight section on top of the main dashboard |
| Principal, Vice Principal | `/dashboard/principal` | Insight section on top; each sees only the rules for their own role |
| Management | `/dashboard/management` | Insight section on top |

One Blade component, `<x-dashboard::insights.section />`, used on all three pages. It renders a shell
immediately and loads cards over AJAX, like the existing async charts, so the page paint is not slowed.

## What gets built

### Tables (4 new create migrations, `database/migrations/tenant/`)

| Table | Purpose | Notes |
|---|---|---|
| `dsh_insight_rules` | One row per rule: key, module, title, type, severity, default_params, params (school override), min_sample, schedule, roles, is_active | Seeded from the rule registry; settings screen edits `params`, `roles`, `is_active` |
| `dsh_insights` | One row per detected condition on one entity | `fingerprint` unique among open rows (generated column `open_fingerprint` = fingerprint while status ≠ resolved, NULL otherwise — avoids the NULL-distinct trap); status, priority, payload json, assignee, due, snoozed_until, detected/resolved timestamps |
| `dsh_insight_actions` | Audit trail of every acknowledge/assign/snooze/dismiss/reopen/auto-resolve | Append-only |
| `dsh_insight_runs` | One row per rule execution | Duration, counts, error message |

### Code (all in `Modules/Dashboard`)

| Piece | File(s) | Job |
|---|---|---|
| Contract | `app/Insights/Contracts/InsightRule.php` | `key()`, `defaults()`, `evaluate(InsightContext): iterable<Finding>` |
| Value objects | `app/Insights/Finding.php`, `InsightContext.php` | A finding = entity, headline, evidence, impact, confidence, since, link (route name + params) |
| Registry | `config/insights.php` (module config) | List of rule classes + their default roles; the seeder syncs it to `dsh_insight_rules` |
| Engine | `app/Insights/InsightEngine.php` | Runs each active rule in try/catch, upserts by fingerprint, auto-resolves open insights the run no longer finds, logs `dsh_insight_runs` |
| Scorer | `app/Insights/PriorityScorer.php` | The 0–100 formula from the plan; acknowledged −30%, unowned +10%/week |
| Feed | `app/Insights/InsightFeed.php` | Cards for one user: their roles' rules, open + not snoozed, link permission checked, Top 5 + grouped, cached 5 min per user |
| Command | `tenant:insights:run {--rule=}` | Runs the engine for the current tenant; scheduled daily 05:30 across tenants in `routes/console.php` |
| Controller | `InsightController` | `GET feed`, `POST {insight}/acknowledge`, `assign`, `snooze`, `dismiss`, `reopen` |
| Settings | `InsightSettingsController` + page `/dashboard/insight-settings` | Table of rules: on/off, roles, threshold params (validated against each rule's `defaults()` keys) |
| Views | `resources/views/components/insights/section.blade.php`, `card.blade.php` + one small JS file | Card as in the plan's mock-up; sparkline with ApexCharts (already global) |

### Permissions (`config/permissionslist.php` + `permission_role_defaults.php`)

| Key | Who gets it by default |
|---|---|
| `tenant.dashboard.insights.viewAny` | Super Admin, School Admin, Management, Principal, Vice Principal |
| `tenant.dashboard.insights.act` (acknowledge/assign/snooze/dismiss) | same 5 roles |
| `tenant.dashboard.insight-settings.viewAny` / `.update` | Super Admin, School Admin |

### The 2 pilot rules (prove the loop; both have data on test.localhost today)

| Rule | Roles | Why this one |
|---|---|---|
| **LMS-07** Homework grading backlog by teacher (submitted, not graded > 7 days; 3,864 today) | Principal, Vice Principal | Academic, per-teacher entity, deep link with filters, clears when graded |
| **TPT-04** Vehicle / driver documents expiring in 30 days (2 fitness, 1 insurance today) | School Admin, Management | Operations, per-vehicle entity, urgency from a date, clears when the date is renewed |

### Seeder and tests

- `DashboardInsightRuleSeeder` — idempotent sync of the registry into `dsh_insight_rules` (never overwrites a
  school's `params`/`roles`/`is_active`); added to `TenantDatabaseSeeder` and the /seeder Foundation group.
- Feature tests for the engine (fire, de-dupe, auto-resolve, snooze expiry) and the 2 rules (fire + clear
  fixtures). **Written by me, run by you** — I will not run the suite.

## Not in P0

Digests, mobile push, event listeners (real-time rules), the other ~147 rules, the "Why am I seeing this?"
copy for rules that don't exist yet, any change to existing widgets.

## Exit gate

1. `tenants:migrate` + seeder clean on test.localhost.
2. `tenant:insights:run` produces LMS-07 and TPT-04 cards; re-running does not duplicate them.
3. Grading a backlog / renewing a document makes the card resolve on the next run.
4. Acknowledge, assign, snooze, dismiss work from the card and show in `dsh_insight_actions`.
5. Your test run is green.

## Order of work (each step reviewable on its own)

1. Migrations + models + seeder
2. Contract, engine, scorer, command, schedule
3. The 2 rules
4. Feed, controller, routes, permissions
5. Card component on the 3 pages
6. Settings screen
7. Tests
