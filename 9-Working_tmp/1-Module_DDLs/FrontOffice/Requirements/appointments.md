# Appointment Scheduling — Requirements

## What It Does
Manages meeting scheduling (Parent-Teacher, Principal, Grievance, etc.) with real-time slot conflict checking. Prevents double-booking for the same staff member at the same time. Supports the full lifecycle: Pending → Confirmed → Completed → Cancelled/No_Show.

## Database Fields

### fof_appointments

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `appointment_number` | VARCHAR(25) | Required. Unique. Auto-generated: `APT-YYYYMMDD-NNN`. |
| `appointment_type` | ENUM('Parent_Teacher_Meeting','Principal_Meeting','Grievance','Admission_Enquiry','Other') | Required. |
| `with_user_id` | INT UNSIGNED FK → `sys_users` | Required. Staff member being met. |
| `visitor_name` | VARCHAR(100) | Required. |
| `visitor_mobile` | VARCHAR(15) | Required. |
| `visitor_email` | VARCHAR(100) | Nullable. |
| `purpose` | VARCHAR(300) | Required. |
| `appointment_date` | DATE | Required. |
| `start_time` | TIME | Required. |
| `end_time` | TIME | Required. Must be > start_time. |
| `status` | ENUM('Pending','Confirmed','Completed','Cancelled','No_Show') | Default 'Pending'. |
| `confirmed_by` | INT UNSIGNED FK → `sys_users` | Nullable. |
| `confirmed_at` | DATETIME | Nullable. |
| `cancellation_reason` | VARCHAR(300) | Nullable. Required when Cancelled. |
| `notes` | TEXT | Nullable. |

## Business Rules

**Slot Conflict Check**
- Custom validation rule in `BookAppointmentRequest`
- Queries for existing appointments where:
  - `with_user_id` matches
  - `appointment_date` matches
  - Time range overlaps: `start_time < new_end_time AND end_time > new_start_time`
  - Status is NOT Cancelled or No_Show
- Indexed by `idx_fof_apt_slot (with_user_id, appointment_date, start_time, end_time)` for performance

**State Machine**
```
Pending → Confirmed → Completed
       → Cancelled (reason required)
       → No_Show (automated after scheduled time without confirmation)
```

**Reminder Flow** (Phase 2)
- NTF reminder dispatched 24 hours before confirmed appointments
- Dashboard shows today's upcoming appointments

## CRUD Operations

**Book Appointment**
- `POST /front-office/appointments` — validates visitor details, staff, date/time; checks slot conflict; generates APT-YYYYMMDD-NNN

**Confirm**
- `PATCH /front-office/appointments/{appointment}/confirm` — sets confirmed_by, confirmed_at, status = 'Confirmed'

**Cancel**
- `PATCH /front-office/appointments/{appointment}/cancel` — requires cancellation_reason

**Complete**
- `PATCH /front-office/appointments/{appointment}/complete` — sets status = 'Completed'

**List / Calendar**
- List view with status filters
- Calendar view (FullCalendar.js) with colour-coded appointment types
- API endpoint: `GET /api/v1/front-office/appointments/slots/{userId}/{date}` — available time slots

## Permissions

| Operation | Permission Key |
|---|---|
| View appointments | `frontoffice.visitor.view` |
| Book/manage appointments | `frontoffice.visitor.create` |
