# Smart Transport — Audit & Roadmap (2026-10-23)

Static audit (code + DDL + migrations, no live DB, no browser) of
`Modules/Transport`, `Modules/SmartTransport` and
`pgdatabase/2-DDL_Tenant_Enhanced/Transport/Transport_DDL_v2.4.sql`.

Scope decisions taken before the audit:
1. **Both modules ship.** Transport and SmartTransport are both live, so both are audited and the fork drift is a risk in itself.
2. **SmartTransport is the "smart" target.** It is judged against the SmartTimetable bar: background engine, proposals, suggestions, measurable savings.
3. The output is Markdown in this folder.
4. The audit was solo and static: no agents, no DB queries, no page loads. Render-time 500s are therefore NOT covered.

| File | What it answers |
|---|---|
| [01-CURRENT-STATUS.md](01-CURRENT-STATUS.md) | What exists today: menus, tabs, tables, services, and how far the two forks have drifted |
| [02-PRODUCTION-READINESS-AUDIT.md](02-PRODUCTION-READINESS-AUDIT.md) | Severity-ranked findings with file:line, and a go-live verdict |
| [03-SMART-FEATURE-ASSESSMENT.md](03-SMART-FEATURE-ASSESSMENT.md) | How "smart" SmartTransport really is, measured against SmartTimetable |
| [04-RESEARCH-AND-ROADMAP.md](04-RESEARCH-AND-ROADMAP.md) | Market research, the star features to build, and a phased plan |
| [05-SIMPLE-EXAMPLES.md](05-SIMPLE-EXAMPLES.md) | Every issue and every suggestion explained with a simple example from our own app |

## One-paragraph verdict

SmartTransport already holds more real intelligence than most Indian school ERPs:

- **SuggestionEngine:** 68 rules.
- **LossRecoveryAdvisor:** 26 loss-recovery strategies (merge, split, right-size, central hub, shift reuse and others).
- **TransportCostAnalysisService:** per-route and per-bus cost analysis.
- **RouteProposalPlanner:** clusters stops into routes, capacity-aware (k-means).

It is **not production-ready**, for four reasons:

1. **(a) A one-click endpoint hard-deletes every route, trip and incident** in the tenant, and both modules share those tables.
2. **(b) The proposal lifecycle stops at "Auto_Generated".** The DDL designs review, approve and restore, but no code promotes a proposal to live routes.
3. **(c) All smart computation runs synchronously** inside the page request, using straight-line distances and a public demo routing server.
4. **(d) The two modules are a 343-file copy-paste fork** that has already drifted in 155 files.

To become a SmartTimetable-class "star" feature, it needs four things:

- an engine that runs in the background and generates proposals
- a review/approve/rollback lifecycle with snapshots
- road-network distances
- a savings ledger that proves money saved
