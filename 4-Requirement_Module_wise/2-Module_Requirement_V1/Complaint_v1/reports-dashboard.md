# Reports & Dashboard — Requirements

## What It Does
Provides real-time analytics and historical reporting for complaint data. The Dashboard tab in the master view shows key metrics and trends. Additional report types provide deeper analysis for management decision-making.

## Dashboard Tabs
The master view includes a Dashboard tab showing:
- Open tickets count
- New tickets today
- Average resolution hours
- SLA breach count
- Category distribution pie chart

## Report Types

**Summary Report**
- Overall complaint statistics
- Status distribution (Open / In Progress / Resolved / Closed)
- Priority vs status breakdown

**SLA Report**
- Violation types: breached / at_risk / all
- Per-department SLA compliance
- Helps identify departments that consistently miss deadlines

**Pareto Analysis**
- Category/subcategory severity-weighted frequency
- Identifies the 20% categories causing 80% of complaints
- Useful for targeting root causes

**Hotspot Analysis**
- Target-based complaint clustering
- Risk score aggregation by target
- Identifies frequently complained-about entities (staff, vehicles, departments)

**AI Risk/Sentiment Report**
- Bubble chart: sentiment × escalation × safety
- Trend analysis over time
- Helps identify emerging issues before they escalate

## Dashboard Charts (AJAX Endpoints)

| Endpoint | Data Returned |
|---|---|
| `/dashboard/donut/severity-vs-department` | Severity distribution per department |
| `/dashboard/donut/department-vs-severity` | Department distribution per severity |
| `/dashboard/donut/department-status` | Pending vs resolved by department |

## Permissions

| Operation | Permission Key |
|---|---|
| View Dashboard tab | `tenant.complaint-dashboard.viewAny` |
| View Reports | Gated by individual report permissions |
