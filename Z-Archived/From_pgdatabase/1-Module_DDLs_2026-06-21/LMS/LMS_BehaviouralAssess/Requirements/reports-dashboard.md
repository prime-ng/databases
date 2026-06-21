# Reports & Dashboard — Requirements

## What It Does
Provides analytics and reporting across four levels: individual student behavioural report cards, class-level heatmaps, school-wide analytics, and parent portal views. Supports PDF export and period-over-period trend analysis.

## Report Types

### Student Behavioural Report (FR-BA-012)
- Per-category scores with grade mapping
- Per-criterion detail (expandable rows showing individual ratings)
- Overall score and grade for the period
- Trend chart across multiple periods (last 4 periods)
- Teacher remarks (overall + per-criterion)
- Incident summary (count by type/severity for the period)
- PDF export via DomPDF

### Class Heatmap (FR-BA-013)
- Students × categories score matrix with colour coding (green→red)
- Row averages (student overall score)
- Column averages (category average for the class)
- Top performers and flagged students (below configurable threshold)
- Period comparison toggle

### School Analytics (FR-BA-014)
- Aggregate trends across all classes
- Incident frequency analysis by type, severity, location, month
- Teacher completion rates per period
- Category-wise average scores school-wide
- Year-over-year comparison
- Exportable to CSV/Excel

### Parent Portal View (FR-BA-015)
- Parents see their own child's data only
- Scores + grades + remarks per period
- Incident notifications based on threshold
- No access to other students' data
- Optional anonymised class comparison

## Dashboard Views

### Teacher Dashboard
- Pending assessments (draft status)
- Upcoming deadlines
- Recent incidents reported
- Follow-up reminders
- Quick links to assessment entry

### Principal Dashboard
- Assessment completion status across all teachers
- Flagged students (overall score < threshold)
- Category average trends
- Incident frequency overview
- Period status summary

### Parent Dashboard
- Child's current-period scores
- Grade card download
- Incident alert count
- Period selector for historical view

## AJAX Endpoints

| Endpoint | Data Returned |
|---|---|
| `GET /behavioural-assessment/reports/student/{student}` | Full student report JSON for Livewire component |
| `GET /behavioural-assessment/reports/class/{classSection}` | Class heatmap data matrix |
| `GET /behavioural-assessment/reports/school` | School analytics aggregated data |
| `GET /behavioural-assessment/reports/student/{student}/pdf` | DomPDF binary response |
| `GET /behavioural-assessment/reports/parent/{student}` | Filtered parent view data |
| `GET /behavioural-assessment/reports/completion/{period}` | Teacher completion status data |

## Permissions

| Operation | Permission Key |
|---|---|
| View student report | `tenant.ba.report.student` |
| View class report | `tenant.ba.report.class` |
| View school analytics | `tenant.ba.report.school` |
| Export PDF | `tenant.ba.report.student` |
| View parent report | `tenant.ba.report.student` |
