# Dashboard & Reports — Requirements

## What It Does
Front Office dashboard providing real-time operational snapshot. Shows today's visitor count, pending gate passes, pending certificate requests, active keys out, unresolved complaints, pending circulars. Additional API endpoints serve dashboard widgets.

## Dashboard KPIs

| Metric | Source | Description |
|--------|--------|-------------|
| Today's Visitors | `fof_visitors` WHERE DATE(in_time) = TODAY | Count of visitors today |
| Visitors on Campus | `fof_visitors` WHERE status = 'In' | Active visitors currently on campus |
| Pending Gate Passes | `fof_gate_passes` WHERE status = 'Pending_Approval' | Awaiting approval |
| Active Keys Out | `fof_key_register` WHERE status IN ('Issued','Overdue') | Keys not yet returned |
| Overdue Keys | `fof_key_register` WHERE status = 'Overdue' | Keys past return time |
| Pending Certificates | `fof_certificate_requests` WHERE status = 'Pending_Approval' | Awaiting approval |
| Unresolved Complaints | `fof_complaints` WHERE status IN ('Open','In_Progress') | Open complaints |
| Pending Circulars | `fof_circulars` WHERE status = 'Pending_Approval' | Circulars awaiting approval |
| Today's Appointments | `fof_appointments` WHERE appointment_date = TODAY AND status = 'Confirmed' | Confirmed meetings today |
| Unclaimed Lost Items | `fof_lost_found` WHERE status = 'Unclaimed' | Items awaiting claimants |

## API Endpoints (Dashboard)

| Endpoint | Returns |
|----------|---------|
| `GET /api/v1/front-office/dashboard/snapshot` | All KPI values in a single response |
| `GET /api/v1/front-office/visitors/today` | Today's visitor list with status |
| `GET /api/v1/front-office/visitors/active` | Currently checked-in visitors |
| `GET /api/v1/front-office/gate-passes/pending` | Pending approval passes |
| `GET /api/v1/front-office/early-departures/pending-sync` | Early departures with ATT sync failures |
| `GET /api/v1/front-office/certificates/pending` | Pending approval cert requests |
| `GET /api/v1/front-office/keys/overdue` | Overdue keys |
| `GET /api/v1/front-office/notices/active` | Currently active notices |
| `GET /api/v1/front-office/appointments/slots/{userId}/{date}` | Available time slots for staff |
| `GET /api/v1/front-office/circulars/{circular}/distribution-status` | Per-recipient delivery status |
| `GET /api/v1/front-office/school-events/upcoming` | Upcoming school events |

## Dashboard View (`/front-office`)
- Snapshot cards in the top row
- Quick action buttons for common tasks (New Visitor, Issue Gate Pass, Log Call, etc.)
- Recent activity stream
- Emergency notices banner (if any active)

## Permissions

| Operation | Permission Key |
|---|---|
| View dashboard | `frontoffice.visitor.view` (shared with visitor permissions) |
