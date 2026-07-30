# Dashboard_TcList

## Module: Complaint Management → Dashboard

---

## 1. Business Conditions

### 1.1 Dashboard Data Sources (ComplaintDashboardService)

| BC ID | Component | Description |
|-------|-----------|-------------|
| BC-DB-01 | Open tickets count | Total complaints with status = OPEN |
| BC-DB-02 | New today | Complaints created today |
| BC-DB-03 | Avg resolution hours | Average hours from ticket_date to actual_resolved_at |
| BC-DB-04 | SLA breaches | Count of resolved complaints exceeding resolution_due_at |
| BC-DB-05 | Category pie chart | Complaint count grouped by category |
| BC-DB-06 | Severity levels | Count by severity dropdown value |
| BC-DB-07 | Department breakdown | Complaint count by target department |
| BC-DB-08 | Critical tickets | Top 5 tickets nearing/breaching SLA |
| BC-DB-09 | Escalation heatmap | Category vs escalation level matrix |
| BC-DB-10 | AI predictions | Insights with escalation_risk_score ≥ 80% |
| BC-DB-11 | Sentiment trend | Daily average sentiment score |
| BC-DB-12 | Donut charts | Severity-vs-Department, Department-vs-Severity, Department-Status |

### 1.2 Authorization

| BC ID | Permission |
|-------|-----------|
| BC-AUTH-01 | `tenant.complaint-dashboard.viewAny` |

### 1.3 Routes

| Method | URI | Controller Method |
|--------|-----|-------------------|
| GET | /dashboard-data | filter() |
| GET | /dashboard/donut/severity-vs-department | severityVsDepartmentDonut() |
| GET | /dashboard/donut/department-vs-severity | departmentVsSeverityDonut() |
| GET | /dashboard/donut/department-status | departmentStatusDonut() |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Date range filter | Dashboard filterable by from_date/to_date |
| BC-BIZ-02 | Real-time data | Donut charts loaded via AJAX on tab switch |
| BC-BIZ-03 | Critical tickets | Top 5 tickets prioritized by SLA breach risk |
| BC-BIZ-04 | High risk predictions | AI insights with risk >= 80% highlighted |
| BC-BIZ-05 | Sentiment trend | Daily aggregate for trend line |

---

## 2. Test Case List

### 2.1 Positive (10)

| TC ID | Description |
|-------|-------------|
| TC-P01 | Dashboard loads via complaint-mgt dashboard tab |
| TC-P02 | Open tickets count displays correct value |
| TC-P03 | New today counter updates correctly |
| TC-P04 | Category pie chart renders with correct grouping |
| TC-P05 | Severity donut chart renders correctly |
| TC-P06 | Critical tickets widget shows top 5 |
| TC-P07 | Escalation heatmap renders |
| TC-P08 | AI high-risk predictions displayed |
| TC-P09 | Sentiment trend line renders |
| TC-P10 | Date range filter updates all widgets |

### 2.2 Negative (3)

| TC ID | Description |
|-------|-------------|
| TC-N01 | Permission denied (403) |
| TC-N02 | Guest redirect (401) |
| TC-N03 | Empty state when no complaints exist |

---

## 3. Coverage Summary

| Category | Total | Full | Gap | % |
|----------|-------|------|-----|---|
| Positive | 10 | 10 | 0 | 100% |
| Negative | 3 | 3 | 0 | 100% |
| Dependency | 0 | 0 | 0 | — |
| **Total** | **13** | **13** | **0** | **100%** |
