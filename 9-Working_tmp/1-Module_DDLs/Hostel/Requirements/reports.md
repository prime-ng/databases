# Reports — Requirements

## What It Does
Parameterized operational reports across all hostel domains — occupancy, attendance, leave, incidents, maintenance, mess, medical, warden, laundry, reservations, fee, visitors, sick bay. Supports PDF and Excel export.

## Database Fields
No database table. Aggregates data from all hst_* tables with date-range and entity filters.

## Report Suites

| Report | Description | Filters | Export |
|---|---|---|---|
| Occupancy Snapshot | Bed occupancy per hostel/floor/room | Hostel, Floor, Date | PDF/Excel |
| Attendance Snapshot | Attendance % per session/shift | Date range, Hostel, Floor | PDF/Excel |
| Leave Passes | Leave pass counts and statuses | Date range, Status, Student | PDF |
| Leave Approvals | Pending/approved/rejected approvals | Date range, Approver | PDF/Excel |
| Discipline Suite | Incidents by type, severity, student | Date range, Type, Severity | PDF/Excel |
| Maintenance Suite | Tickets by status, cost | Date range, Severity, Status | PDF/Excel |
| Mess Suite | Menu plan, attendance, billing | Date range, Hostel | PDF/Excel |
| Medical Suite | Sick bay admissions, treatments | Date range, Hostel | PDF/Excel |
| Warden Suite | Duty roster coverage, assignments | Date range, Warden | PDF/Excel |
| Laundry Suite | Tickets, turnaround time | Date range, Hostel | PDF/Excel |
| Reservation Suite | Reservations by status | Date range, Hostel | PDF/Excel |
| Fee Suite | Structures, demands, defaulters | Session, Hostel | PDF/Excel |
| Visitors Report | Visitor log by type, date | Date range, Purpose | PDF |
| Sick Bay Report | Admission trends | Date range, Hostel | PDF/Excel |

## CRUD Operations

**Index** — `GET /hostel/reports` → report selection page with links to each report suite

**Occupancy** — `GET /hostel/reports/occupancy` | `GET /hostel/reports/occupancy-snapshot` → occupancy report with export

**Attendance** — `GET /hostel/reports/attendance` | `GET /hostel/reports/attendance-snapshot` → attendance report with export

**Leave Passes** — `GET /hostel/reports/leave-passes` → leave pass report

**Leave Approvals** — `GET /hostel/reports/leave-approvals` → leave approval report | `POST /hostel/reports/leave-approvals/{id}/approve` and `/reject`

**Discipline** — `GET /hostel/reports/discipline-suite` → discipline report with student search and history

**Maintenance** — `GET /hostel/reports/maintenance-suite` → maintenance report

**Mess** — `GET /hostel/reports/mess-suite` → mess operations report

**Medical** — `GET /hostel/reports/medical-suite` → medical admissions report

**Warden** — `GET /hostel/reports/warden-suite` → warden coverage report with export

**Laundry** — `GET /hostel/reports/laundry-suite` → laundry report with export

**Reservation** — `GET /hostel/reports/reservation-suite` → reservation report with export

**Fee** — `GET /hostel/reports/fee-suite` → fee report with export

**Export** — `GET /hostel/reports/{suite}/export/{format}` → PDF or Excel download

## Permissions

| Operation | Permission Key |
|---|---|
| View reports | `tenant.hostel-report.viewAny` |
