# Visitor Management — Requirements

## What It Does
Digital replacement for the paper visitor book. Front desk receptionists register visitors (parents, vendors, government officials, etc.) with ID proof, purpose, and optional webcam photo. Auto-generates pass numbers (`VP-YYYYMMDD-NNN`), tracks check-in/out, and flags overstay visitors via scheduled command.

Integrates with VSM module (pending) for pre-registered visitor handoff from the security gate.

## Database Fields

### fof_visitor_purposes

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `name` | VARCHAR(100) | Required. e.g., "Parent Meeting". |
| `code` | VARCHAR(30) | Required. Unique. e.g., "PARENT_MTG". |
| `is_government_visit` | TINYINT(1) | Default 0. 1 = permanent retention; delete blocked. |
| `sort_order` | TINYINT UNSIGNED | Default 0. Display order in dropdown. |
| `is_active` | BOOLEAN | Default true. |

### fof_visitors

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `pass_number` | VARCHAR(25) | Required. Unique. Auto-generated: `VP-YYYYMMDD-NNN`. |
| `vsm_visitor_id` | BIGINT UNSIGNED FK → `vsm_visitors` (pending) | Nullable. Optional pre-registered visitor handoff. |
| `visitor_name` | VARCHAR(100) | Required. Full name. |
| `visitor_mobile` | VARCHAR(15) | Required. Primary mobile. |
| `visitor_email` | VARCHAR(100) | Nullable. |
| `id_proof_type` | ENUM('Aadhar','Driving_License','Passport','Voter_ID','PAN','Employee_ID','Other') | Nullable. Captured per BR-FOF-001. |
| `id_proof_number` | VARCHAR(50) | Nullable. Full number stored; last 4 shown in UI. |
| `address` | VARCHAR(200) | Nullable. |
| `organization` | VARCHAR(100) | Nullable. Company/organization. |
| `purpose_id` | BIGINT UNSIGNED FK → `fof_visitor_purposes` | Required. Visit purpose. |
| `person_to_meet` | VARCHAR(100) | Nullable. Staff/department name. |
| `meet_user_id` | INT UNSIGNED FK → `sys_users` | Nullable. Linked staff member. |
| `vehicle_number` | VARCHAR(20) | Nullable. Vehicle registration. |
| `accompanying_count` | TINYINT UNSIGNED | Default 0. Additional persons. |
| `photo_media_id` | INT UNSIGNED FK → `sys_media` | Nullable. Optional webcam photo. |
| `in_time` | DATETIME | Default CURRENT_TIMESTAMP. Registration time. |
| `out_time` | DATETIME | Nullable. Checkout time; NULL until checked out. |
| `status` | ENUM('In','Out','Overstay') | Default 'In'. In = on campus; Out = checked out; Overstay = flagged by scheduler. |
| `notes` | TEXT | Nullable. |

## Business Rules

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-FOF-001 | ID proof type + number must be captured together (both or neither) | Form validation in `RegisterVisitorRequest` |
| BR-FOF-002 | Visitors not checked out by closing time auto-flagged `Overstay` | Scheduled `fof:flag-overstay` command (default 17:00) |
| BR-FOF-007 | Government visit records (`is_government_visit=1`) cannot be deleted | `VisitorPolicy::delete()` blocks deletion |
| BR-FOF-015 | ID proof number: full number stored in DB; only last 4 digits shown in UI | Accessor/mutator on Visitor model |

**Overstay Flagging**
- Scheduled command runs at configurable closing time (default 17:00 daily)
- Batch UPDATE: `SET status = 'Overstay' WHERE status = 'In' AND out_time IS NULL`
- Returns count of records updated

**Government Visit Retention**
- Purposes with `is_government_visit = 1` (e.g., GOVT_INSPECTION) trigger permanent retention
- Delete action is blocked at the Policy layer, not the database
- Only purpose lookup determines this — not individual visitor records

## CRUD Operations

**Register Visitor**
- `POST /front-office/visitors` — validates purpose_id exists and is_active, generates pass_number, sets in_time = NOW(), status = 'In'
- If `vsm_visitor_id` provided: pre-populates fields from VSM record

**Checkout Visitor**
- `PATCH /front-office/visitors/{visitor}/checkout` — requires status = 'In' or 'Overstay', sets out_time = NOW(), status = 'Out'

**Visitor Pass (Print)**
- `GET /front-office/visitors/{visitor}/pass` — print-optimized A6 view (`@media print` CSS), no PDF download; shows pass_number, visitor_name, in_time, school logo

**List**
- Filterable by date, status (In/Out/Overstay), search by name/mobile
- Status badges with colour coding

## Seeded Visitor Purposes
8 purposes seeded: PARENT_MTG, ADMISSION_ENQ, VENDOR, GOVT_INSPECTION, DELIVERY, INTERVIEW, EMERGENCY, OTHER

## Permissions

| Operation | Permission Key |
|---|---|
| View visitors | `frontoffice.visitor.view` |
| Register visitor | `frontoffice.visitor.create` |
| Checkout visitor | `frontoffice.visitor.checkout` |
