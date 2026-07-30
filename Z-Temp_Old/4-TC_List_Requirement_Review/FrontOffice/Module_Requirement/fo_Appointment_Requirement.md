# Appointments — Business Requirements

## What This Screen Does

The Appointments tab manages scheduled meetings between visitors and staff members. Appointments have a **visitor name**, **contact details**, **staff member** (with_user_id), **type** (dynamically read from DB enum or fallback list), **date/time**, **purpose**, and **status** workflow. The tab splits into **Upcoming** (Scheduled/Confirmed) and **Past** (Completed/Cancelled/No_Show) sections.

## When This Screen Is Used

- **Visitor Pre-Scheduling**: Booking appointments for parents, vendors, officials
- **Front Desk Check-In**: Confirming scheduled appointments upon visitor arrival
- **Appointment Tracking**: Monitoring no-shows and completions
- **Staff Calendar**: Staff seeing who they're meeting and when

## Key Fields

- **Appointment Number** (string) — Unique auto-generated identifier
- **Appointment Type** (enum) — Dynamically read from DB column; fallback: Parent_Meeting, Official, Vendor, Principal_Meeting, Other. Legacy types mapped: Parent_Teacher_Meeting→Parent_Meeting, Admission_Enquiry/Grievance→Official
- **Staff** (FK → `sys_users`) — The person being visited
- **Visitor Name** (string 100)
- **Visitor Mobile** (string 15)
- **Visitor Email** (string 100, nullable)
- **Purpose** (string 300)
- **Appointment Date** (date)
- **Start Time** (time)
- **End Time** (time, must be after start_time)
- **Status** (enum) — Scheduled, Confirmed, Completed, Cancelled, No_Show
- **Confirmed By** (FK → `sys_users`, nullable)
- **Confirmed At** (datetime, nullable)
- **Cancellation Reason** (text, nullable)

## Business Rules

**Dynamic Type Options:** `Appointment::appointmentTypeOptions()` reads the ENUM column directly from MySQL schema. If schema reading fails, falls back to `FALLBACK_APPOINTMENT_TYPES` (Parent_Meeting, Official, Vendor, Principal_Meeting, Other).

**Legacy Type Mapping:** `normalizeAppointmentType()` maps old types: `Parent_Teacher_Meeting` → `Parent_Meeting`, `Admission_Enquiry` → `Official`, `Grievance` → `Official`.

**Date Validation:** On POST (create), `appointment_date` must be `after_or_equal:today`. On PUT (update), only `required|date`.

**Time Ordering:** `end_time` must be `after:start_time`.

**Status Workflow:** Upcoming section shows Scheduled/Confirmed appointments. Actions per status:
- Scheduled → Confirm (check), Mark Completed (circle-check), Cancel (x)
- Confirmed → Mark Completed, Cancel
- Completed/Cancelled/No_Show → appear in Past section (read-only actions)

**Confirm Action:** Sets `confirmed_by` + `confirmed_at` and status to `Confirmed`.

**Completion Action:** Sets status to `Completed`.

**Cancel Action:** Uses `.confirm-cancel` SweetAlert confirmation. Sets status to `Cancelled`.

**In-Modal Validation Errors:** The modal re-opens on validation failure via JS (line 314-321) when old('visitor_name') is present after errors.

**Soft Delete:** Uses SoftDeletes. `trashed()`, `restore()`, `forceDelete()` routes.

**Status Toggle:** Ajax endpoint `toggleStatus()` flips `is_active`.

## Workflow

1. Staff navigates to Front Office → Visitor Management → Appointments tab
2. **Upcoming** section: table with Number, Visitor, Meeting With, Type, Purpose, Date & Time, Status badge, Actions (Confirm/Complete/Cancel)
3. **Past** section: paginated table with Number, Visitor, Type & Purpose, Date, Status badge, Actions (view/delete only)
4. "Add Appointment" button opens a modal with visitor info, staff select, type dropdown, date/time pickers, purpose
5. On validation failure, modal reopens automatically with errors displayed inside

## Requirements

- MUST display at `/front-office/visitor-management?tab=appointments` with Upcoming + Past sections
- MUST authorize via `frontoffice.appointment.*` policy gates
- MUST support appointment status workflow: Scheduled→Confirmed→Completed and Scheduled/Confirmed→Cancelled
- MUST support No_Show status
- MUST dynamically load appointment types from DB enum or fallback list
- MUST map legacy appointment types to current values
- MUST validate end_time after start_time
- MUST validate appointment_date after_or_equal:today on create
- MUST reopen modal on validation errors
- MUST support status toggle via Ajax
- MUST support soft delete with restore/forceDelete
