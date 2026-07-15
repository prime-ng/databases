# FrontOffice ── ReportsDashboard — Gap Analysis

> Read-only screen. Gap analysis covers render/filter/permission surfaces only; no DDL write-path
> coverage obligations (G43–G45 apply to CRUD write screens and are out of scope here).

## 1. Coverage matrix

| Surface | Real source element | Covered by | Gap? |
|---------|--------------------|-----------|------|
| KPI render | `index()` 11 KPI computations → Blade labels | TC_R01 | None (labels asserted) |
| Charts | `#purposeChart`, `#trendChart`, JSON data payloads | TC_R02, TC_E01 | Chart *values* not asserted (rendered via JS/Chart.js; DOM-present asserted instead) — acceptable for a Dusk render test |
| Dashboard tables | recentVisitors / upcomingAppointments / recentComplaints | TC_R02 | Row-level content not asserted (data-dependent); headings asserted |
| visitor-management page | `visitorManagement()` tabs+filters | TC_R03, TC_F01–F03 | Per-tab pagination page-names (`vis_page`,`gp_page`,…) not individually exercised |
| communication page | `communication()` tabs+filters | TC_R04, TC_F04 | `status` filter per-tab not each exercised (channel is the distinctive one) |
| registers page | `registers()` Gate::any + filters | TC_R05, TC_F05, TC_E02, TC_N05 | None material |
| compliance page | `compliance()` tabs+filters | TC_R06, TC_F06, TC_N04 | `'1'/'0'` vs enum status branch noted, not asserted |
| Permissions | 4 distinct gate strings + Gate::any set | TC_N02–N05 | None |
| Guest auth | `auth` middleware | TC_N01 | None |
| Export | (no route) | TC_X01 | None — absence proven |

## 2. Intentional (documented) gaps
- **G-1 Chart data-value assertions.** Chart.js renders to `<canvas>` — pixel/data assertions are brittle in Dusk. We assert the canvas + empty-state DOM instead. Data-correctness belongs to a controller unit test, not a browser test.
- **G-2 Per-tab pagination cursors.** Each menu page defines several independent paginators. Exercising every `*_page` cursor adds little on a read-only screen; render + one representative filter per page is sufficient for the light set.
- **G-3 Seeded-data-dependent table rows.** Recent/upcoming tables depend on tenant data volume; asserting specific rows would be non-deterministic. Headings + no-error render asserted (Rule Card #36 spirit).
- **G-4 500-vs-422 / validation.** No write path → no validation surface on this screen; N/A.

## 3. Defect cross-reference (from Fact Pack §6)
| Defect | Maps here? | Handling |
|--------|-----------|----------|
| PERF-FOF-001 (P2) | Indirect — unbounded `->get()` in menu aggregations | Documented in TcList §6; render-success only, no assertion |
| All other FOF defects | No | Belong to their owning CRUD features, not this dashboard |

**No new `DEV-###` raised** — the read-only screen behaves as sourced; no DDL/route/model divergence discovered for its endpoints.

## 4. Environment-gated (cannot pass until prereqs met)
- Whole suite requires `FrontOffice: true` in `modules_statuses.json` (#19), a resolvable `DUSK_TENANT_URL` tenant domain, ChromeDriver, and `APP_ENV=testing`. These are prerequisites, not coverage gaps.
