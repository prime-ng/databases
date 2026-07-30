# Early Departures — Business Requirements

## What This Screen Does

The Early Departures tab records students leaving school before the regular dismissal time. Each departure tracks the **student**, **departure time**, **reason**, the **collecting person** (name + relation + ID proof), and an **attendance sync status** (Pending/Synced/Failed) for bridging with the attendance module.

## When This Screen Is Used

- **Student Early Pickup**: Guardian arrives to collect student before end of school day
- **Attendance Sync**: Recording partial-day attendance (student present for part of the day)
- **Security Log**: Tracking who collected the student and verifying identity via ID proof
- **Compliance**: Maintaining a record of all early departures for audit

## Key Fields

- **Departure Number** (string) — Unique auto-generated identifier
- **Student** (FK → `std_students`, withTrashed) — The departing student
- **Departure Time** (datetime) — When the student left
- **Reason** (enum) — Medical, Family_Emergency, Event, Bereavement, Other
- **Reason Details** (string 200, nullable)
- **Collecting Person Name** (string 100) — Guardian/authorized person
- **Collecting Person Relation** (enum) — Father, Mother, Guardian, Sibling, Other
- **Collecting ID Proof Type** (enum, nullable) — Aadhar, Driving_License, Passport, Other
- **Collecting ID Proof Number** (string 50, nullable)
- **Parent Authorized** (boolean)
- **Attendance Sync Status** (enum) — Pending, Synced, Failed
- **Attendance Synced At** (datetime, nullable)

## Business Rules

**Attendance Sync:** `att_sync_status` tracks integration with the attendance module. View shows status badges: Synced (green), Failed (danger), Pending Sync (warning). Synced records show the `att_synced_at` timestamp below the badge.

**Validation:** `EarlyDepartureRequest` validates `departure_time` must be `before_or_equal:now` (can't log a future departure). `collecting_person_relation` is restricted to Father/Mother/Guardian/Sibling/Other.

**Parent Authorization:** A boolean `parent_authorized` checkbox (prepared from `boolean()` cast in `prepareForValidation`).

**Soft Delete:** Uses SoftDeletes. `trashed()`, `restore()`, `forceDelete()` routes.

**Status Toggle:** Ajax endpoint `toggleStatus()` flips `is_active`.

**Search:** Controller searches across `departure_number`, `reason`, `reason_details`, `collecting_person_name`, `collecting_person_relation`, `collecting_id_proof_number`, `att_sync_status`, and student name/admission_no.

## Workflow

1. Staff navigates to Front Office → Visitor Management → Early Departures tab
2. Staff sees paginated table: Departure No., Student, Departure Time, Reason, Collected By (name + relation), Sync Status badge, Status toggle, Actions
3. Staff can create/edit/view/delete departure records
4. Attendance sync status is updated via background job or manual trigger

## Requirements

- MUST display at `/front-office/visitor-management?tab=early-departures` as paginated table
- MUST authorize via `frontoffice.early-departure.*` policy gates
- MUST show attendance sync status with color-coded badges
- MUST validate departure_time is before_or_equal:now
- MUST track collecting person details with ID proof
- MUST support status toggle via Ajax
- MUST support soft delete with restore/forceDelete
