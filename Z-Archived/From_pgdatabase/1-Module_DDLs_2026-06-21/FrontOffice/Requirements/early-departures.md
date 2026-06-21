# Student Early Departure — Requirements

## What It Does
Records student mid-day parent/guardian pickups with identity verification. Logs collector details (name, relation, ID proof) for security audit. Syncs with the Attendance (ATT) module to mark the student absent for remaining periods after departure.

## Database Fields

### fof_early_departures

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `departure_number` | VARCHAR(25) | Required. Unique. Auto-generated: `ED-YYYYMMDD-NNN`. |
| `student_id` | INT UNSIGNED FK → `std_students` | Required. |
| `departure_time` | DATETIME | Required. Time student is collected. |
| `reason` | ENUM('Medical','Family_Emergency','Event','Bereavement','Other') | Required. |
| `reason_details` | VARCHAR(200) | Nullable. |
| `collecting_person_name` | VARCHAR(100) | Required. Name of collecting adult. |
| `collecting_person_relation` | ENUM('Father','Mother','Guardian','Sibling','Other') | Required. |
| `collecting_id_proof_type` | ENUM('Aadhar','Driving_License','Passport','Other') | Nullable. |
| `collecting_id_proof_number` | VARCHAR(50) | Nullable. |
| `parent_authorized` | TINYINT(1) | Default 0. 1 = parent authorized pickup. |
| `att_sync_status` | ENUM('Pending','Synced','Failed') | Default 'Pending'. ATT module sync status. |
| `att_synced_at` | DATETIME | Nullable. ATT sync success timestamp. |
| `notes` | TEXT | Nullable. |

## Business Rules

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-FOF-013 | ATT sync failure is NOT acceptable silently — must alert front desk and retry | Flash alert + `EarlyDepartureAttSyncJob` with 3 retries |

**ATT Sync Flow**
1. Departure logged → `EarlyDepartureService::logDeparture()` generates number, persists record
2. `syncAttendance()` called synchronously:
   - Calls ATT service: `AttendanceService::markAbsentFromPeriod(student_id, date, from_time=departure_time)`
   - On success: `att_sync_status = 'Synced'`, `att_synced_at = NOW()`
   - On failure: `att_sync_status = 'Failed'`, dispatch `EarlyDepartureAttSyncJob` (3 retries, 60s backoff), flash warning to user

**Collector Identity Verification**
- Name and relation are always required
- ID proof is recommended but optional
- `parent_authorized` flag indicates whether parent gave verbal/written authorization

## CRUD Operations

**Log Departure**
- `POST /front-office/early-departures` — validates student_id, departure_time (must be before or equal to now), collecting person details
- Generates `departure_number` ED-YYYYMMDD-NNN
- Returns print-optimized slip view

**List**
- Filtered by date
- ATT sync status badges (Pending/Synced/Failed with retry CTA)

## Permissions

| Operation | Permission Key |
|---|---|
| View early departures | `frontoffice.early-departure.view` |
| Log early departure | `frontoffice.early-departure.create` |
