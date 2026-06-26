# Analytics & Dashboard — Requirements

## What It Does
Provides comprehensive admission funnel analytics, lead source breakdown, quota fill monitoring, counselor performance tracking, behavior score computation, and data export across all admission stages.

## Service: `AdmissionAnalyticsService`

### Key Metrics

**Admission Funnel**
Stage-by-stage conversion analysis:
- Enquiries → Submitted Applications (conversion rate)
- Submitted → Verified
- Verified → Shortlisted
- Shortlisted → Allotted
- Allotted → Enrolled
- Drop-off rate at each stage

**Lead Source Breakdown**
- Groups `adm_enquiries` by `lead_source`.
- Count + percentage per source (Website, Walk-in, Campaign, Referral, Social_Media, Phone, Other).
- Trend analysis over time (monthly/quarterly).

**Quota Fill Report**
- Joins `adm_seat_capacity` with `adm_allotments` counts per class per quota.
- Displays: total_seats, seats_allotted, seats_enrolled, fill_% (`seats_allotted / total_seats * 100`).
- Visual indicators: green (<80%), yellow (80–90%), red (>90% near full).

**Counselor Performance**
- Enquiries assigned per counselor.
- Converted count and conversion rate.
- Average response time (time to first follow-up after assignment).
- Comparison across cycles.

**Behavior Score**
- `computeBehaviorScore(studentId, academicSessionId)` sums `behavior_score_impact` across incidents.
- Baseline: 100. Resets at new session start.
- Used in student profile for behavioral tracking.

### Dashboard Views

| Dashboard | Audience | Key Widgets |
|---|---|---|
| **Cycle Overview** | All admin | Active cycle summary, total enquiries, submitted apps, enrolled count, days remaining |
| **Funnel Chart** | Principal, Admin | Visual stage-by-stage funnel with count + conversion % at each stage |
| **Quota Monitor** | Admin, Counselor | Per-class per-quota seat fill status with colour indicators |
| **Lead Sources** | Marketing, Admin | Pie/bar chart of enquiry sources with trend line |
| **Counselor Board** | Admin | Counselor ranking by conversion rate, response time |
| **Behavior Report** | Principal, Class Teacher | Incident summary by class, severity distribution, resolution status |

### Export Functionality

| Export Type | Formats | Filters |
|---|---|---|
| Funnel data | CSV, PDF | Cycle, date range |
| Quota fill report | CSV, PDF | Cycle, class |
| Counselor performance | CSV | Cycle, date range |
| Behavior incidents | CSV, PDF | Cycle/class, severity, status |

CSV generation uses `fputcsv`. PDF uses DomPDF.

## Data Sources

Reads all `adm_*` tables:
- `adm_admission_cycles` — Cycle scope (status, dates).
- `adm_enquiries` — Lead source, counselor assignment.
- `adm_follow_ups` — Response time computation.
- `adm_applications` — Application pipeline by status.
- `adm_application_stages` — Stage transition timestamps for funnel timing.
- `adm_merit_lists` / `adm_merit_list_entries` — Shortlisting metrics.
- `adm_allotments` — Allotment and enrollment metrics.
- `adm_seat_capacity` — Quota fill counters.
- `adm_behavior_incidents` — Behavior incident analytics.

## Permissions

| Operation | Permission Key |
|---|---|
| View dashboard tab | `tenant.adm.dashboard.viewAny` |
| View funnel analytics | `tenant.adm.dashboard.viewAny` |
| View quota monitor | `tenant.adm.dashboard.viewAny` |
| View counselor board | `tenant.adm.dashboard.viewAny` |
| View behavior report | `tenant.adm.dashboard.viewAny` |
| Export analytics | `tenant.adm.dashboard.export` |
