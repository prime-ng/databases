# FrontOffice ── ReportsDashboard — Requirements, Test-Case List & Method Index

> **Screen type:** LIGHT, read-only KPI dashboard + 4 combined report/menu pages. No CRUD.
> **Prefix:** `fof_` (verified). **DB scope:** tenant-side. **Module status:** DISABLED in `modules_statuses.json` (env prereq).
> Sources read: `Modules/FrontOffice/routes/web.php`, `FrontOfficeDashboardController@index`, `FofMenuController@{visitorManagement,communication,registers,compliance}`, `resources/views/fof/dashboard/index.blade.php`, FrontOffice Fact Pack, Rule Card `05_`.

## 1. Feature Info

| Field | Value |
|-------|-------|
| Module / Code | FrontOffice / FOF |
| Feature | ReportsDashboard |
| Controllers | `FrontOfficeDashboardController` (KPI dashboard), `FofMenuController` (4 combined report pages) |
| Test style | Tenant-side **Dusk** (browser); status/route facts via `Route::has()` |
| Sibling mirrored | `Complaint/CmpDashboard`, `Vendor/VendorReports` (read-only report style) |
| Write surface | **None** — all endpoints are GET read views |

### 1.1 Endpoints (all GET, derived from real routes — F40)

| Route name | Path | Handler | Gate ability |
|-----------|------|---------|--------------|
| `fof.dashboard` | `/front-office` | `FrontOfficeDashboardController@index` | `frontoffice.visitor.view` |
| `fof.menu.visitorManagement` | `/front-office/visitor-management` | `FofMenuController@visitorManagement` | `frontoffice.visitor.view` |
| `fof.menu.communication` | `/front-office/communication` | `FofMenuController@communication` | `frontoffice.communication.view` |
| `fof.menu.registers` | `/front-office/registers` | `FofMenuController@registers` | `Gate::any([postal-register, dispatch-register, phone-diary, lost-found, key-register].viewAny)` |
| `fof.menu.compliance` | `/front-office/compliance` | `FofMenuController@compliance` | `frontoffice.complaint.view` |

### 1.2 Filters (query-string params, per controller)

| Page | Params read |
|------|-------------|
| visitor-management | `tab`, `search`, `status` |
| communication | `tab`, `search`, `status`, `channel` |
| registers | `tab`, `search`, `status`, `call_type` |
| compliance | `tab`, `search`, `status` |
| dashboard (index) | **none** — fixed KPIs (today/30-day/7-day windows computed server-side) |

### 1.3 Dashboard composition (real Blade selectors/labels)
- **KPI cards:** "Today's Visitors", "Gate Passes Pending", "Cert Requests Pending", "Today's Appointments", "Open Complaints", "Overstay Visitors".
- **Charts:** `#purposeChart` (donut, "Visitors by Purpose (Last 30 Days)") + `#trendChart` (bar, "Daily Visitor Trend (Last 7 Days)"), each with an always-rendered empty-state div `#purposeChartEmpty` / `#trendChartEmpty` bearing "No visitor data available yet".
- **Tables:** "Recent Visitors" (latest 5), "Upcoming Appointments" (5), "Today's Summary" side panel.
- **Export:** NONE. No CSV/PDF/download endpoint exists on the dashboard or menu pages.

## 2. Business Context (BC)
- BC-1 The dashboard surfaces read-only operational KPIs; no state is mutated by any endpoint.
- BC-2 Each menu page aggregates several fof_* registers into tabbed, filterable, paginated lists (server-side `like` search + `status`/`channel`/`call_type` scoping).
- BC-3 Access is permission-gated per page. `registers` is the only page using `Gate::any([...viewAny])` — a user holding ANY one of the 5 register `viewAny` abilities may open it.
- BC-4 Super Admin bypasses all gates (`Gate::before`) — authorization negatives MUST use a stripped non-super-admin user (Rule Card #31/#37).

## 3. Test-Case List (Light read-only set)

### Structure / alignment
| TC | Title | Assertion |
|----|-------|-----------|
| TC_A01 | All 5 report routes registered | `Route::has()` true for dashboard + 4 menu names |

### Render
| TC | Title | Assertion |
|----|-------|-----------|
| TC_R01 | Dashboard renders with KPIs | path + 6 KPI labels visible |
| TC_R02 | Charts + tables present | chart headers, `#purposeChart`/`#trendChart` present, table headings |
| TC_R03 | Visitor-Management menu renders | path + no 403 |
| TC_R04 | Communication menu renders | path + no 403 |
| TC_R05 | Registers menu renders | path + no 403 |
| TC_R06 | Compliance menu renders | path + no 403 |

### Filters
| TC | Title | Assertion |
|----|-------|-----------|
| TC_F01 | Visitor search filter | `?tab=visitors&search=…` preserved, renders |
| TC_F02 | Visitor status filter | `?status=1` preserved |
| TC_F03 | Visitor tab switch | `?tab=gate-passes` preserved |
| TC_F04 | Communication channel filter | `?tab=email-sms&channel=Email` preserved |
| TC_F05 | Registers call_type filter | `?tab=phone-diary&call_type=Incoming` preserved |
| TC_F06 | Compliance status filter | `?tab=complaints&status=Open` preserved |

### Export (absent-by-design)
| TC | Title | Assertion |
|----|-------|-----------|
| TC_X01 | No export route exists | `Route::has('fof.*export')` all false |

### Empty-state
| TC | Title | Assertion |
|----|-------|-----------|
| TC_E01 | Chart empty-state present | `#purposeChartEmpty`/`#trendChartEmpty` + "No visitor data available yet" |
| TC_E02 | Registers no-match still renders | unmatched search → page renders, no 403 |

### Permission / auth negatives
| TC | Title | Assertion |
|----|-------|-----------|
| TC_N01 | Guest redirected to login | `/front-office` → `/login` |
| TC_N02 | Dashboard 403 w/o visitor.view | stripped user → 403 |
| TC_N03 | Communication 403 w/o permission | stripped user → 403 |
| TC_N04 | Compliance 403 w/o permission | stripped user → 403 |
| TC_N05 | Registers 403 w/o any viewAny | stripped user → 403 |

## 4. Method Index (file: `fof_ReportsDashboard_TestCas.php`)
1. `test_TC_A01_all_report_routes_registered`
2. `test_TC_R01_dashboard_renders_with_kpis`
3. `test_TC_R02_dashboard_charts_and_tables_present`
4. `test_TC_R03_visitor_management_menu_renders`
5. `test_TC_R04_communication_menu_renders`
6. `test_TC_R05_registers_menu_renders`
7. `test_TC_R06_compliance_menu_renders`
8. `test_TC_F01_visitor_mgmt_search_filter`
9. `test_TC_F02_visitor_mgmt_status_filter`
10. `test_TC_F03_visitor_mgmt_tab_switch`
11. `test_TC_F04_communication_channel_filter`
12. `test_TC_F05_registers_call_type_filter`
13. `test_TC_F06_compliance_status_filter`
14. `test_TC_X01_no_export_route_exists`
15. `test_TC_E01_dashboard_chart_empty_state_present`
16. `test_TC_E02_registers_no_match_still_renders`
17. `test_TC_N01_guest_redirected_to_login`
18. `test_TC_N02_dashboard_403_without_visitor_view`
19. `test_TC_N03_communication_403_without_permission`
20. `test_TC_N04_compliance_403_without_permission`
21. `test_TC_N05_registers_403_without_any_view_any`

**Total: 21 methods** across 6 categories (structure, render, filter, export-absent, empty-state, permission).

## 5. Manual test steps (where automation is env-gated)
1. Ensure `FrontOffice: true` in `prime_testing/modules_statuses.json`; run `php artisan route:clear`.
2. `php artisan permission:cache-reset` then confirm the 8 abilities exist (`frontoffice.visitor.view`, `frontoffice.communication.view`, `frontoffice.complaint.view`, and the 5 register `*.viewAny`).
3. Log in as a user with only `frontoffice.visitor.view` → `/front-office` shows KPIs but `/front-office/communication` returns 403.
4. On `/front-office/registers?tab=phone-diary`, set `call_type=Incoming` → only incoming calls listed.
5. Confirm the dashboard shows "No visitor data available yet" when the tenant has no visitors in the last 30 days.

## 6. Known Defects mapped to ReportsDashboard
- **None P0/P1 originate in this read-only screen.** The Fact Pack §6 defect table maps no defect to `FrontOfficeDashboardController`/`FofMenuController`.
- **PERF-FOF-001 (P2, indirect):** the aggregated menu pages issue multiple unbounded `->get()` / `->paginate()` queries per render (e.g. `registers` builds inward/outward/dispatch/calls/lost/keys + a full active-user list each request). Not a functional failure — noted for the audit trail; no assertion beyond render-success.
- **Observation (not a coded defect):** `compliance` and `certificates` tabs branch `status` on `'1'/'0'` vs enum value — a status value colliding with `'1'`/`'0'` would filter `is_active` instead of `status`. Cosmetic; documented, no proving test (no user-facing failure).
