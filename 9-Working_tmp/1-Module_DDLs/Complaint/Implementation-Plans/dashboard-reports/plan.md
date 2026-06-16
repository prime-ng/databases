# Dashboard & Reports — Implementation Plan

## Purpose
Real-time analytics and historical reporting for complaint data: summary stats, SLA compliance, Pareto analysis, hotspot clustering, AI sentiment trends.

## Documented But Not Implemented

### Item 1: ComplaintDashboardController Is a Stub

**Source:** Routes register dashboard but controller is a stub

**Current Behavior:** `ComplaintDashboardController.php` (56 lines) only has `index()` returning `view('complaint::index')`.

**Implement:**
- [ ] `index()`: Connect to `ComplaintDashboardService` and pass real data to dashboard view:
  - Open tickets count
  - New today count
  - Average resolution hours
  - SLA breach count
  - Category distribution pie chart data

### Item 2: Dashboard AJAX Endpoints Need Verification

**Source:** `Requirements/reports-dashboard.md:41-47` — Three AJAX donut endpoints listed

**Current Behavior:** Endpoints registered in routes but need to verify they return correct data from `ComplaintDashboardService`.

**Verify:**
- [ ] `/dashboard/donut/severity-vs-department` — severity distribution per department
- [ ] `/dashboard/donut/department-vs-severity` — department distribution per severity
- [ ] `/dashboard/donut/department-status` — pending vs resolved by department

### Item 3: SLA Breach Report Should Use Resolved SLA Data

**Source:** `Requirements/reports-dashboard.md:21-24` — SLA violation types: breached / at_risk / all

**Current Behavior:** Report exists but computes SLA based on category defaults without SLA overrides.

**Implement:**
- [ ] Update `ComplaintReportController` SLA report to use `SlaResolutionService` for accurate deadline computation
- [ ] Ensure report reflects actual resolution_due_at from resolved SLA, not just category defaults

### Item 4: Missing Feature Tests

**Current Behavior:** Zero tests.

**Implement:**
- [ ] `DashboardServiceTest.php`:
  - Open tickets count returns correct number
  - Average resolution hours computed correctly
  - SLA breach count catches overdue complaints
  - Category distribution returns correct proportions
