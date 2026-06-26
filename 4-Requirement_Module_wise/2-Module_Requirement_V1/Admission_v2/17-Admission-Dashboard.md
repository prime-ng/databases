# Admission Dashboard — Business Requirements

## What This Screen Does

The Admission Dashboard is the command center for the entire admission module. It provides a real-time overview of the admission pipeline through:

1. **Advanced Filters** — Cycle selector, date range picker, class filter, counselor filter
2. **6-Card KPI Funnel** — Enquiries → Applications → Shortlisted → Selected (Verified) → Allotted → Enrolled
3. **Charts** — Monthly pipeline flow trends (grouped bar chart), lead generation channels (doughnut chart)
4. **Seat Fill Progression** — Per-class progress bars showing filled vs total seats
5. **Counselor Performance** — Leaderboard with conversion rates
6. **Recent CRM Leads** — Latest enquiries table with status badges
7. **Active Application Pipelines** — Latest application table with stage status
8. **Quick Access Links** — Navigation buttons to all admission sub-pages

---

## When This Screen Is Used

- Every visit: This is the default landing page for the Admission module
- Morning check: Admin reviews yesterday's enquiries and application activity
- Weekly review: Admin analyzes funnel metrics and counselor performance
- Bottleneck identification: Admin spots pipeline drop-offs between stages
- Seat monitoring: Admin checks how many seats are filled per class

---

## Key Sections at a Glance

**Filter Panel**
A sophisticated filter bar with:
- Admission Cycle dropdown (drives all dashboard data)
- Date Range picker (pre-set ranges: Today, Last 7 Days, Last 30 Days, This Month, Last Month)
- Class Sought dropdown
- Counselor dropdown
- Apply / Reset buttons

**6-Card KPI Funnel**
Six gradient-colored cards in a row showing the admission funnel:
| Card | Gradient Color | Icon |
|------|---------------|------|
| Enquiries | Purple | phone-volume |
| Applications | Blue | file-signature |
| Shortlisted | Amber | user-clock |
| Selected (Verified) | Pink | user-check |
| Allotted | Green | clipboard-check |
| Enrolled | Violet | graduation-cap |

Each card shows the count in large bold text.

**Pipeline Flow Trends (Bar Chart)**
A grouped bar chart showing monthly enquiry vs application counts over a 6-month period.

**Lead Generation Channels (Doughnut Chart)**
A doughnut chart showing the distribution of enquiry lead sources (Website, Walk-in, Campaign, Referral, Social Media, Phone, Other).

**Seat Fill Progression**
Per-class horizontal progress bars with color coding:
- Green (< 60% filled)
- Yellow (60–89% filled)
- Red (90%+ filled)

Each bar shows: filled count / total seats, and enrolled vs available breakdown.

**Counselor Performance Table**
A table ranking counselors by:
- Enquiries handled
- Conversions (enquiry → application)
- Conversion rate percentage

---

## Business Rules and Conditions

**Active Cycle Required**
The dashboard displays a prominent warning banner if no active admission cycle exists, with a direct link to the Setup page.

**Cycle-Driven Data**
All dashboard data is scoped to the selected admission cycle. Different cycles show different data.

**Date Range Filter**
If no custom date range is selected, the dashboard shows data for the entire cycle duration.

**Real-Time Counts**
All KPI counts refresh on page load. No automatic polling — the user must refresh the page.

**Counselor Performance**
Counselors with zero enquiries or zero applications still appear in the table with 0 counts and 0% conversion.

---

## Workflow Steps

**Arriving at the Dashboard**
Admin navigates to the Admission module. The dashboard loads with the active cycle selected and default date range.

**Filtering Data**
Admin selects a different cycle, date range, class, or counselor and clicks "Apply". The page reloads with filtered data.

**Analyzing the Funnel**
Admin reads the 6-card KPI row from left to right to understand the pipeline: how many enquiries → applications → shortlisted → selected → allotted → enrolled.

**Analyzing Charts**
The grouped bar chart shows monthly trends. The doughnut chart shows lead source distribution.

**Checking Seat Fill**
The seat progression bars show which classes are filling up. Red bars indicate near-capacity classes that need attention.

**Reviewing Counselor Performance**
The counselor table shows who is performing well and who needs support.

**Navigating to Sub-Pages**
Admin clicks any of the quick access buttons (Setup, Enquiry Pipeline, Assessment, Allotment & Enrollment, Promotions & Alumni) to drill into specific areas.

---

## Example Scenario

An administrator starts their day by visiting the Admission Dashboard. They see:
- Active Cycle: "2027-28" (selected)
- Funnel: 150 Enquiries → 85 Applications → 60 Shortlisted → 45 Selected → 30 Allotted → 20 Enrolled
- The bar chart shows a spike in enquiries in January (open house event)
- The doughnut chart shows 40% of leads come from Walk-in, 30% from Website
- Class IX is 95% filled (red bar) — needs a capacity decision
- Counselor Priya has the highest conversion rate at 72%
- Two recent enquiries need follow-up (status: New)

The admin clicks "Enquiry Pipeline" to follow up on the new leads.

---

## Related Screens

- **Setup** — Cycle configuration and seat capacity management
- **Enquiry Pipeline** — Detailed CRM for enquiries and applications
- **Assessment** — Entrance tests and merit lists
- **Allotment & Enrollment** — Seat allotments and enrollment conversion
- **Promotions & Alumni** — Batch promotions, TCs, incidents
