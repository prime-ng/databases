# Dashboard — Business Requirements

## What This Screen Does

The Dashboard tab provides a real-time overview of the complaint management system. It displays key metrics (open tickets, new today, avg resolution time, SLA breaches), visual charts (category pie, severity donut, escalation heatmap, sentiment trend), critical tickets widget, and AI risk predictions. All data is filterable by date range and loaded via AJAX for individual chart components.

## When This Screen Is Used

- **At the start of the day** to get a quick overview of pending complaints.
- **When monitoring SLA compliance** and identifying breach risks.
- **When analyzing complaint patterns** by category, severity, or department.
- **When reviewing AI-predicted high-risk complaints** for proactive intervention.

## Key Widgets

- **Stat Cards:** Open Tickets count, New Today, Avg Resolution Hours, SLA Breaches
- **Category Pie Chart:** Complaint distribution by category
- **Severity Donut:** Complaint count by severity level
- **Department Breakdown:** Complaints by target department
- **Critical Tickets:** Top 5 tickets nearing or breaching SLA
- **Escalation Heatmap:** Category vs escalation level matrix
- **AI High-Risk Predictions:** Insights with risk ≥ 80%
- **Sentiment Trend:** Daily average sentiment line chart
- **Donut Charts:** Severity-vs-Department, Department-vs-Severity, Department-Status

## Business Rules

**Date Range Filter:**
All dashboard widgets respect a global date range filter (from_date/to_date). Default range is typically the current month.

**AJAX Loading:**
Donut charts and individual widgets load via AJAX to prevent page load slowdown. Three dedicated AJAX endpoints serve donut chart data.

**Critical Tickets Logic:**
The top 5 tickets are selected based on proximity to SLA breach — tickets where elapsed time is closest to resolution_due_at.

**High-Risk AI Predictions:**
Filters `cmp_ai_insights` where `escalation_risk_score >= 80` to flag complaints needing immediate attention.

**Repeated Target Analysis:**
The dashboard identifies complainants/targets with frequent complaints and calculates frustration probability.

## Workflow

1. User navigates to Complaint → Complaint Management → Dashboard tab (default).
2. Stat cards load at the top showing key metrics.
3. Charts render below: pie, donut, heatmap, sentiment trend.
4. Critical tickets and high-risk AI predictions highlight urgent items.
5. User can filter by date range to refine all widgets.

## Requirements

- MUST display as default tab at `/complaint/complaint-mgt?tab=dashboard`
- MUST authorize via `tenant.complaint-dashboard.viewAny`
- MUST show stat cards: Open Tickets, New Today, Avg Resolution Hours, SLA Breaches
- MUST render category pie chart
- MUST render severity donut
- MUST show critical tickets (top 5 by SLA breach risk)
- MUST show escalation heatmap
- MUST show AI high-risk predictions (risk ≥ 80%)
- MUST show sentiment trend line
- MUST load donut charts via AJAX endpoints
- MUST support date range filtering for all widgets
