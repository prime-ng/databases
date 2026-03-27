# FOF — Front Office Module Feature Specification
**Version:** 1.0 | **Date:** 2026-03-27 | **Based on:** FOF_FrontOffice_Requirement.md v2
**Author Role:** Business Analyst + DB Architect

---

## Section 1 — Module Identity & Scope

### 1.1 Module Identity

| Attribute | Value |
|-----------|-------|
| Module Code | FOF |
| Module Name | FrontOffice |
| Namespace | `Modules\FrontOffice` |
| Route prefix | `front-office/` |
| Route name prefix | `fof.` |
| DB prefix | `fof_*` |
| Database | `tenant_db` (one per school — NO `tenant_id` column on any table) |
| Module type | Tenant module (school-specific operational data) |
| Status | 0% — Greenfield |
| Tenancy | Stancl/tenancy v3.9, database-per-tenant |

### 1.2 Module Scale

| Artifact | Count |
|----------|-------|
| Controllers | 18 |
| Models | 22 |
| Services | 5 |
| FormRequests | 10 |
| `fof_*` tables | 22 |
| Blade views (est.) | ~60 |
| Artisan commands | 1 (`fof:flag-overstay`) |
| Jobs | 1 (`EarlyDepartureAttSyncJob`) |
| Seeders | 1 (`FofVisitorPurposeSeeder`) + 1 runner |

### 1.3 In-Scope Feature Groups (All 17 FRs)

| Phase | Feature Group | FR IDs |
|-------|--------------|--------|
| Phase 1 | Visitor Management | FR-FOF-01 |
| Phase 1 | Gate Pass (Student/Staff Early Exit) | FR-FOF-02 |
| Phase 1 | Student Early Departure (linked to ATT) | FR-FOF-03 |
| Phase 1 | Phone Call Log (Phone Diary) | FR-FOF-04 |
| Phase 1 | Postal / Courier Register | FR-FOF-05 |
| Phase 1 | Dispatch Register | FR-FOF-06 |
| Phase 2 | Circular Management + NTF Distribution | FR-FOF-07 |
| Phase 2 | Digital Notice Board | FR-FOF-08 |
| Phase 2 | School Calendar Events | FR-FOF-17 |
| Phase 3 | Certificate Request + Issuance | FR-FOF-13 |
| Phase 3 | Complaint Handling (Front-Office Level) | FR-FOF-14 |
| Phase 4 | Appointment Scheduling | FR-FOF-09 |
| Phase 4 | Lost and Found Register | FR-FOF-10 |
| Phase 4 | Key Management Register | FR-FOF-11 |
| Phase 4 | Emergency Contact Directory | FR-FOF-12 |
| Phase 5 | Feedback Collection | FR-FOF-15 |
| Phase 5 | Email and SMS Communication | FR-FOF-16 |

### 1.4 Out-of-Scope

- **Admission Enquiry** — handled entirely by the ADM module (`adm_enquiries`, `adm_applications`)
- **Biometric / Vehicle Entry Log** — handled by VSM module; FOF only receives pre-registered visitor handoff from VSM
- **Full HR Leave Management** — handled by HRS module; FOF key register covers physical key issue/return only
- **Attendance Management** — FOF triggers ATT service call on early departure; FOF does NOT write to `att_*` tables directly
- **Full Complaint Workflow** — FOF handles lightweight intake only; full complaint lifecycle managed by CMP module

### 1.5 FOF vs VSM Distinction

| Aspect | FOF (Front Office) | VSM (Visitor Security) |
|--------|--------------------|------------------------|
| Actor | Receptionist (inside campus) | Security guard (at main gate) |
| Entry point | Reception desk | Security booth / main gate |
| Visitor record | Operational detail, visitor pass, purpose | Gate entry/exit timestamps, ID scan |
| Integration | Receives handoff from VSM for pre-registered visitors | Notifies FOF when visitor arrives |
| Key feature | Visitor register, circulars, certificates, complaints | Biometric scan, vehicle log, guard log |

---

## Section 2 — Entity Inventory (All 22 Tables)

> **FK type convention:**
> - `fof_*` table PKs: `BIGINT UNSIGNED` — so all `fof_*` FK columns use `BIGINT UNSIGNED`
> - `sys_users.id = INT UNSIGNED` → functional FK columns → `INT UNSIGNED` (EXCEPT `created_by`/`updated_by` which use `BIGINT UNSIGNED` with no FK constraint)
> - `std_students.id = INT UNSIGNED` → student FK columns → `INT UNSIGNED`
> - `sys_media.id = INT UNSIGNED` → `photo_media_id`, `attachment_media_id`, `media_id` → `INT UNSIGNED`
> - `cmp_complaints.id = INT UNSIGNED` → `cmp_complaint_id` → `INT UNSIGNED`
> - `vsm_visitors.id = BIGINT UNSIGNED` (pending module, follows new-module convention) → `vsm_visitor_id` → `BIGINT UNSIGNED`

---

### Domain A — Core Registers (8 tables)

---

#### `fof_visitor_purposes` — Lookup: purpose-of-visit master

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `name` | VARCHAR(100) | NOT NULL | — | — | e.g., "Parent Meeting" |
| `code` | VARCHAR(30) | NOT NULL | — | UNIQUE | e.g., "PARENT_MTG" — programmatic lookup |
| `is_government_visit` | TINYINT(1) | NOT NULL | 0 | — | 1 = permanent retention; delete blocked by VisitorPolicy (BR-FOF-007) |
| `sort_order` | TINYINT UNSIGNED | NOT NULL | 0 | — | Display order in dropdown |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `uq_fof_vp_code (code)`
**Seeded:** 8 purposes (see Seeder section)

---

#### `fof_visitors` — Visitor register (digital replacement for paper visitor book)

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `pass_number` | VARCHAR(25) | NOT NULL | — | UNIQUE | VP-YYYYMMDD-NNN; auto-generated by VisitorService |
| `vsm_visitor_id` | BIGINT UNSIGNED | NULL | — | FK→vsm_visitors | Optional pre-registered visitor handoff from VSM gate security |
| `visitor_name` | VARCHAR(100) | NOT NULL | — | — | Full name of visitor |
| `visitor_mobile` | VARCHAR(15) | NOT NULL | — | — | Primary mobile number |
| `visitor_email` | VARCHAR(100) | NULL | — | — | Optional email |
| `id_proof_type` | ENUM('Aadhar','Driving_License','Passport','Voter_ID','PAN','Employee_ID','Other') | NULL | — | — | Government ID type |
| `id_proof_number` | VARCHAR(50) | NULL | — | — | Full ID number stored; last 4 shown in UI (BR-FOF-015) |
| `address` | VARCHAR(200) | NULL | — | — | Visitor address |
| `organization` | VARCHAR(100) | NULL | — | — | Visitor's company/organization |
| `purpose_id` | BIGINT UNSIGNED | NOT NULL | — | FK→fof_visitor_purposes | Visit purpose (required) |
| `person_to_meet` | VARCHAR(100) | NULL | — | — | Name of staff/dept to meet |
| `meet_user_id` | INT UNSIGNED | NULL | — | FK→sys_users | Linked staff member (optional) |
| `vehicle_number` | VARCHAR(20) | NULL | — | — | Vehicle registration if applicable |
| `accompanying_count` | TINYINT UNSIGNED | NOT NULL | 0 | — | Number of additional accompanying persons |
| `photo_media_id` | INT UNSIGNED | NULL | — | FK→sys_media | Optional webcam photo; sys_media uses INT UNSIGNED |
| `in_time` | DATETIME | NOT NULL | CURRENT_TIMESTAMP | — | Registration time; set at creation |
| `out_time` | DATETIME | NULL | — | — | Checkout time; NULL until checked out |
| `status` | ENUM('In','Out','Overstay') | NOT NULL | 'In' | — | In = on campus; Out = checked out; Overstay = not checked out by closing |
| `notes` | TEXT | NULL | — | — | Additional remarks |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `uq_fof_vis_pass_number (pass_number)`, `idx_fof_vis_date (DATE(in_time))`, `idx_fof_vis_status (status)`, `idx_fof_vis_mobile (visitor_mobile)`, `idx_fof_vis_purpose (purpose_id)`, `idx_fof_vis_vsm (vsm_visitor_id)`

---

#### `fof_gate_passes` — Student/staff early exit authorization

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `pass_number` | VARCHAR(25) | NOT NULL | — | UNIQUE | GP-YYYYMMDD-NNN; auto-generated |
| `person_type` | ENUM('Student','Staff') | NOT NULL | — | — | Determines which FK is populated |
| `student_id` | INT UNSIGNED | NULL | — | FK→std_students | NULL for staff passes; std_students uses INT UNSIGNED |
| `staff_user_id` | INT UNSIGNED | NULL | — | FK→sys_users | NULL for student passes |
| `purpose` | ENUM('Medical','Personal','Official','Sports','Family_Emergency','Other') | NOT NULL | — | — | Reason for early exit |
| `purpose_details` | VARCHAR(200) | NULL | — | — | Free-text elaboration |
| `exit_time` | DATETIME | NULL | — | — | Actual exit timestamp; set when marking Exited |
| `expected_return_time` | DATETIME | NULL | — | — | Stated return time |
| `actual_return_time` | DATETIME | NULL | — | — | Set when marking Returned |
| `parent_notified` | TINYINT(1) | NOT NULL | 0 | — | 1 = NTF dispatched (student passes; BR-FOF-003) |
| `status` | ENUM('Pending_Approval','Approved','Rejected','Exited','Returned','Cancelled') | NOT NULL | 'Pending_Approval' | — | Gate pass lifecycle |
| `approved_by` | INT UNSIGNED | NULL | — | FK→sys_users | Principal/HOD who approved/rejected |
| `approved_at` | DATETIME | NULL | — | — | Approval/rejection timestamp |
| `rejection_reason` | TEXT | NULL | — | — | Required when Rejected |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `uq_fof_gp_pass_number (pass_number)`, `idx_fof_gp_student (student_id)`, `idx_fof_gp_staff (staff_user_id)`, `idx_fof_gp_status (status)`, `idx_fof_gp_approved_by (approved_by)`

---

#### `fof_early_departures` — Student mid-day parent pickup (feeds ATT module)

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `departure_number` | VARCHAR(25) | NOT NULL | — | UNIQUE | ED-YYYYMMDD-NNN |
| `student_id` | INT UNSIGNED | NOT NULL | — | FK→std_students | std_students uses INT UNSIGNED |
| `departure_time` | DATETIME | NOT NULL | — | — | Time student is collected |
| `reason` | ENUM('Medical','Family_Emergency','Event','Bereavement','Other') | NOT NULL | — | — | Departure reason |
| `reason_details` | VARCHAR(200) | NULL | — | — | Optional elaboration |
| `collecting_person_name` | VARCHAR(100) | NOT NULL | — | — | Name of collecting adult (security audit) |
| `collecting_person_relation` | ENUM('Father','Mother','Guardian','Sibling','Other') | NOT NULL | — | — | Relation to student |
| `collecting_id_proof_type` | ENUM('Aadhar','Driving_License','Passport','Other') | NULL | — | — | ID proof type of collector |
| `collecting_id_proof_number` | VARCHAR(50) | NULL | — | — | ID proof number of collector |
| `parent_authorized` | TINYINT(1) | NOT NULL | 0 | — | 1 = parent verbally/written authorized the pickup |
| `att_sync_status` | ENUM('Pending','Synced','Failed') | NOT NULL | 'Pending' | — | ATT module sync status (BR-FOF-013) |
| `att_synced_at` | DATETIME | NULL | — | — | Timestamp when ATT sync succeeded |
| `notes` | TEXT | NULL | — | — | Additional remarks |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `uq_fof_ed_departure_number (departure_number)`, `idx_fof_ed_student (student_id)`, `idx_fof_ed_date (DATE(departure_time))`, `idx_fof_ed_att_sync (att_sync_status)`

---

#### `fof_phone_diary` — Incoming/outgoing call log

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `call_type` | ENUM('Incoming','Outgoing') | NOT NULL | — | — | Direction of call |
| `call_date` | DATE | NOT NULL | — | — | Date of call |
| `call_time` | TIME | NOT NULL | — | — | Time of call |
| `caller_name` | VARCHAR(100) | NOT NULL | — | — | Caller name (Incoming) or person called (Outgoing) |
| `caller_number` | VARCHAR(15) | NULL | — | — | Phone number |
| `caller_organization` | VARCHAR(100) | NULL | — | — | Organization of caller |
| `recipient_name` | VARCHAR(100) | NULL | — | — | Name of staff who took/made the call |
| `recipient_user_id` | INT UNSIGNED | NULL | — | FK→sys_users | Linked sys_user (optional) |
| `purpose` | VARCHAR(200) | NOT NULL | — | — | Call purpose summary |
| `message` | TEXT | NULL | — | — | Full call notes |
| `action_required` | TINYINT(1) | NOT NULL | 0 | — | 1 = follow-up action pending |
| `action_notes` | TEXT | NULL | — | — | What action is required |
| `action_completed` | TINYINT(1) | NOT NULL | 0 | — | 1 = action resolved |
| `logged_by` | INT UNSIGNED | NULL | — | FK→sys_users | Staff who logged the call |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_fof_pd_date_type (call_date, call_type)`, `idx_fof_pd_recipient (recipient_user_id)`, `idx_fof_pd_action (action_required)`, `idx_fof_pd_logged_by (logged_by)`

---

#### `fof_postal_register` — Inward/outward mail and courier register

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `postal_type` | ENUM('Inward','Outward') | NOT NULL | — | — | Direction of mail |
| `postal_number` | VARCHAR(30) | NOT NULL | — | UNIQUE | IN-YYYY-NNNN (Inward) or OUT-YYYY-NNNN (Outward) |
| `postal_date` | DATE | NOT NULL | — | — | Date received/dispatched |
| `sender_name` | VARCHAR(100) | NULL | — | — | Sender (Inward) |
| `sender_address` | VARCHAR(200) | NULL | — | — | Sender address |
| `recipient_name` | VARCHAR(100) | NULL | — | — | Recipient (Outward) |
| `recipient_address` | VARCHAR(200) | NULL | — | — | Recipient address |
| `document_type` | ENUM('Letter','Courier','Parcel','Government_Notice','Cheque','Legal','Other') | NOT NULL | — | — | Type of postal item |
| `subject` | VARCHAR(200) | NOT NULL | — | — | Brief description of contents |
| `courier_company` | VARCHAR(100) | NULL | — | — | Courier service name |
| `tracking_number` | VARCHAR(100) | NULL | — | — | Courier tracking number |
| `department` | VARCHAR(100) | NULL | — | — | School department concerned |
| `assigned_to_user_id` | INT UNSIGNED | NULL | — | FK→sys_users | Staff assigned to handle/follow up |
| `acknowledgement_by` | VARCHAR(100) | NULL | — | — | Name of person who acknowledged receipt |
| `acknowledged_at` | DATETIME | NULL | — | — | Acknowledgement timestamp; once set, record is locked (BR-FOF-009) |
| `remarks` | TEXT | NULL | — | — | Additional notes |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `uq_fof_pr_postal_number (postal_number)`, `idx_fof_pr_type_date (postal_type, postal_date)`, `idx_fof_pr_assigned (assigned_to_user_id)`

---

#### `fof_dispatch_register` — Official outgoing correspondence log

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `dispatch_number` | VARCHAR(30) | NOT NULL | — | UNIQUE | DSP-YYYY-NNNN; auto-generated |
| `dispatch_date` | DATE | NOT NULL | — | — | Date of dispatch |
| `addressee_name` | VARCHAR(100) | NOT NULL | — | — | Recipient name/organization |
| `addressee_address` | VARCHAR(200) | NULL | — | — | Recipient address |
| `subject` | VARCHAR(200) | NOT NULL | — | — | Subject/brief description |
| `document_type` | ENUM('Letter','Notice','Legal','Certificate','Report','Circular','Other') | NOT NULL | — | — | Type of document dispatched |
| `dispatch_mode` | ENUM('Hand','Post','Courier','Email','Fax') | NOT NULL | — | — | Delivery method |
| `reference_number` | VARCHAR(100) | NULL | — | — | Internal/external reference number |
| `copy_retained` | TINYINT(1) | NOT NULL | 1 | — | 1 = copy kept at school |
| `dispatched_by` | INT UNSIGNED | NULL | — | FK→sys_users | Staff who dispatched |
| `remarks` | TEXT | NULL | — | — | Additional notes |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `uq_fof_dr_dispatch_number (dispatch_number)`, `idx_fof_dr_date (dispatch_date)`, `idx_fof_dr_dispatched_by (dispatched_by)`

---

#### `fof_emergency_contacts` — External emergency contact directory

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `contact_name` | VARCHAR(100) | NOT NULL | — | — | Name of contact/organization |
| `organization` | VARCHAR(150) | NULL | — | — | Organization name |
| `contact_type` | ENUM('Hospital','Police','Fire','Ambulance','Transport','Utility','Parent_Emergency','Government','Other') | NOT NULL | — | — | Category for grouping |
| `primary_phone` | VARCHAR(15) | NOT NULL | — | — | Primary phone number |
| `alternate_phone` | VARCHAR(15) | NULL | — | — | Backup number |
| `address` | VARCHAR(200) | NULL | — | — | Physical address |
| `notes` | TEXT | NULL | — | — | Additional info |
| `sort_order` | TINYINT UNSIGNED | NOT NULL | 0 | — | Display order within type group |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_fof_ec_type (contact_type)`

---

### Domain B — Communication (4 tables)

---

#### `fof_circulars` — Official school circulars with approval + distribution lifecycle

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `circular_number` | VARCHAR(30) | NOT NULL | — | UNIQUE | CIR-YYYY-NNNN; auto-generated |
| `title` | VARCHAR(200) | NOT NULL | — | — | Circular heading |
| `subject` | VARCHAR(300) | NOT NULL | — | — | One-line subject |
| `body` | LONGTEXT | NOT NULL | — | — | Rich text HTML content |
| `audience` | ENUM('Parents','Staff','Both','Specific_Class','Specific_Section') | NOT NULL | — | — | Target recipient group |
| `audience_filter_json` | JSON | NULL | — | — | Class/section IDs when audience = Specific_Class/Section; e.g., `{"class_ids":[3,4]}` |
| `effective_date` | DATE | NOT NULL | — | — | Circular effective/issue date |
| `expires_on` | DATE | NULL | — | — | Optional expiry date |
| `attachment_media_id` | INT UNSIGNED | NULL | — | FK→sys_media | Optional attachment PDF; sys_media uses INT UNSIGNED |
| `status` | ENUM('Draft','Pending_Approval','Approved','Distributed','Recalled') | NOT NULL | 'Draft' | — | Lifecycle status |
| `approved_by` | INT UNSIGNED | NULL | — | FK→sys_users | Principal/admin who approved |
| `approved_at` | DATETIME | NULL | — | — | Approval timestamp |
| `distributed_at` | DATETIME | NULL | — | — | Distribution trigger timestamp |
| `distributed_by` | INT UNSIGNED | NULL | — | FK→sys_users | Staff who triggered distribution |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `uq_fof_cir_circular_number (circular_number)`, `idx_fof_cir_status (status)`, `idx_fof_cir_approved_by (approved_by)`, `idx_fof_cir_attachment (attachment_media_id)`

---

#### `fof_circular_distributions` — Append-only per-recipient NTF delivery log

> **EXCEPTION:** This table is an **append-only immutable log** — no `deleted_at`, no `updated_by`.

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `circular_id` | BIGINT UNSIGNED | NOT NULL | — | FK→fof_circulars | Source circular |
| `recipient_user_id` | INT UNSIGNED | NOT NULL | — | FK→sys_users | Recipient user |
| `channel` | ENUM('Email','SMS','Push') | NOT NULL | — | — | Delivery channel |
| `status` | ENUM('Queued','Sent','Delivered','Failed') | NOT NULL | 'Queued' | — | Delivery status |
| `sent_at` | TIMESTAMP | NULL | — | — | When NTF job dispatched |
| `delivered_at` | TIMESTAMP | NULL | — | — | Delivery confirmation from NTF gateway |
| `read_at` | TIMESTAMP | NULL | — | — | Read receipt (if available) |
| `ntf_log_id` | BIGINT UNSIGNED | NULL | — | — | NTF module log reference (no FK constraint — cross-module reference) |
| `created_at` | TIMESTAMP | NULL | — | — | Row creation timestamp |
| `updated_at` | TIMESTAMP | NULL | — | — | |

**Indexes:** `idx_fof_cd_circular (circular_id)`, `idx_fof_cd_recipient (circular_id, recipient_user_id)`, `idx_fof_cd_status (status)`

---

#### `fof_notices` — Digital notice board entries

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `title` | VARCHAR(200) | NOT NULL | — | — | Notice heading |
| `content` | LONGTEXT | NOT NULL | — | — | Full notice body (rich text) |
| `category` | ENUM('Academic','Administrative','Sports','Cultural','Holiday','Emergency','Other') | NOT NULL | — | — | Notice category |
| `audience` | ENUM('All','Students','Staff','Parents') | NOT NULL | 'All' | — | Visibility audience |
| `display_from` | DATE | NOT NULL | — | — | Notice visible from this date |
| `display_until` | DATE | NULL | — | — | NULL = no expiry; bypassed when is_emergency=1 |
| `is_pinned` | TINYINT(1) | NOT NULL | 0 | — | 1 = always shown at top |
| `is_emergency` | TINYINT(1) | NOT NULL | 0 | — | 1 = bypasses display date constraints (BR-FOF-014) |
| `attachment_media_id` | INT UNSIGNED | NULL | — | FK→sys_media | Optional attachment; sys_media uses INT UNSIGNED |
| `status` | ENUM('Active','Archived') | NOT NULL | 'Active' | — | Active = shown; Archived = hidden |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_fof_ntc_display (display_from, display_until, status)`, `idx_fof_ntc_emergency (is_emergency)`, `idx_fof_ntc_audience (audience)`, `idx_fof_ntc_pinned (is_pinned)`

---

#### `fof_school_events` — Public-facing school calendar events

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `event_name` | VARCHAR(200) | NOT NULL | — | — | Event title |
| `event_type` | ENUM('Academic','Sports','Cultural','PTM','Holiday','Exam','Admission','Other') | NOT NULL | — | — | Event category |
| `start_date` | DATE | NOT NULL | — | — | Event start date |
| `end_date` | DATE | NOT NULL | — | — | Event end date; must be >= start_date |
| `description` | TEXT | NULL | — | — | Event description |
| `venue` | VARCHAR(200) | NULL | — | — | Event location |
| `audience` | ENUM('All','Students','Staff','Parents') | NOT NULL | 'All' | — | Target audience |
| `is_public` | TINYINT(1) | NOT NULL | 0 | — | 1 = visible on public-facing school website |
| `notification_sent` | TINYINT(1) | NOT NULL | 0 | — | 1 = NTF blast dispatched |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_fof_se_date_type (start_date, event_type)`, `idx_fof_se_public (is_public)`

---

### Domain C — Appointments & Support (4 tables)

---

#### `fof_appointments` — Meeting scheduling with slot conflict check

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `appointment_number` | VARCHAR(25) | NOT NULL | — | UNIQUE | APT-YYYYMMDD-NNN |
| `appointment_type` | ENUM('Parent_Teacher_Meeting','Principal_Meeting','Grievance','Admission_Enquiry','Other') | NOT NULL | — | — | Meeting type |
| `with_user_id` | INT UNSIGNED | NOT NULL | — | FK→sys_users | Staff member being met |
| `visitor_name` | VARCHAR(100) | NOT NULL | — | — | Visitor/parent name |
| `visitor_mobile` | VARCHAR(15) | NOT NULL | — | — | Contact number |
| `visitor_email` | VARCHAR(100) | NULL | — | — | Optional email |
| `purpose` | VARCHAR(300) | NOT NULL | — | — | Meeting agenda/purpose |
| `appointment_date` | DATE | NOT NULL | — | — | Scheduled date |
| `start_time` | TIME | NOT NULL | — | — | Slot start time |
| `end_time` | TIME | NOT NULL | — | — | Slot end time; must be > start_time |
| `status` | ENUM('Pending','Confirmed','Completed','Cancelled','No_Show') | NOT NULL | 'Pending' | — | Appointment lifecycle |
| `confirmed_by` | INT UNSIGNED | NULL | — | FK→sys_users | Staff who confirmed |
| `confirmed_at` | DATETIME | NULL | — | — | Confirmation timestamp |
| `cancellation_reason` | VARCHAR(300) | NULL | — | — | Required when Cancelled |
| `notes` | TEXT | NULL | — | — | Pre/post meeting notes |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `uq_fof_apt_appointment_number (appointment_number)`, `idx_fof_apt_with_user (with_user_id)`, `idx_fof_apt_date (appointment_date)`, `idx_fof_apt_status (status)`, `idx_fof_apt_slot (with_user_id, appointment_date, start_time, end_time)` (for conflict check)

---

#### `fof_lost_found` — Lost and found item register

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `item_number` | VARCHAR(25) | NOT NULL | — | UNIQUE | LF-YYYY-NNNN |
| `item_description` | VARCHAR(300) | NOT NULL | — | — | Description of found item |
| `category` | ENUM('Electronics','Clothing','Stationery','ID_Card','Money','Jewellery','Books','Sports','Other') | NOT NULL | — | — | Item category |
| `found_date` | DATE | NOT NULL | — | — | Date item was found |
| `found_location` | VARCHAR(200) | NOT NULL | — | — | Where item was found |
| `found_by_name` | VARCHAR(100) | NOT NULL | — | — | Name of person who found it |
| `found_by_user_id` | INT UNSIGNED | NULL | — | FK→sys_users | Linked user if applicable |
| `photo_media_id` | INT UNSIGNED | NULL | — | FK→sys_media | Photo of item; sys_media uses INT UNSIGNED |
| `status` | ENUM('Unclaimed','Claimed','Disposed','Returned_to_Authority') | NOT NULL | 'Unclaimed' | — | Item disposition status |
| `claimant_name` | VARCHAR(100) | NULL | — | — | Name of person claiming item |
| `claimant_contact` | VARCHAR(15) | NULL | — | — | Claimant contact number |
| `claimed_date` | DATE | NULL | — | — | Date item was claimed |
| `disposal_notes` | TEXT | NULL | — | — | Notes when Disposed or Returned |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `uq_fof_lf_item_number (item_number)`, `idx_fof_lf_status (status)`, `idx_fof_lf_found_date (found_date)`, `idx_fof_lf_photo (photo_media_id)`

---

#### `fof_key_register` — Physical key issue/return tracking

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `key_label` | VARCHAR(100) | NOT NULL | — | — | e.g., "Science Lab A Key" |
| `key_tag_number` | VARCHAR(30) | NOT NULL | — | — | Physical tag/number on key |
| `key_type` | ENUM('Room','Lab','Vehicle','Cabinet','Store','Other') | NOT NULL | — | — | Key category |
| `issued_to_user_id` | INT UNSIGNED | NULL | — | FK→sys_users | NULL = key currently available |
| `purpose` | VARCHAR(200) | NULL | — | — | Reason for issue |
| `issued_at` | DATETIME | NULL | — | — | Issue timestamp |
| `expected_return_at` | DATETIME | NULL | — | — | Expected return time |
| `returned_at` | DATETIME | NULL | — | — | Actual return timestamp |
| `status` | ENUM('Available','Issued','Overdue','Lost') | NOT NULL | 'Available' | — | Key status; Overdue auto-set when past expected_return_at |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_fof_kr_status_user (status, issued_to_user_id)`, `idx_fof_kr_issued_to (issued_to_user_id)`

---

#### `fof_certificate_requests` — Certificate request with multi-stage approval and PDF issuance

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `request_number` | VARCHAR(25) | NOT NULL | — | UNIQUE | CERT-YYYY-NNNNN |
| `student_id` | INT UNSIGNED | NOT NULL | — | FK→std_students | std_students uses INT UNSIGNED |
| `cert_type` | ENUM('Bonafide','Character','Fee_Paid','Study','TC_Copy','Migration','Conduct','Other') | NOT NULL | — | — | Certificate type; TC_Copy and Migration require FIN fee clearance |
| `purpose` | VARCHAR(200) | NOT NULL | — | — | Stated purpose of request |
| `copies_requested` | TINYINT UNSIGNED | NOT NULL | 1 | — | Number of copies; 1–5 |
| `is_urgent` | TINYINT(1) | NOT NULL | 0 | — | 1 = escalates approval priority |
| `applicant_name` | VARCHAR(100) | NULL | — | — | Name of person requesting (parent/student) |
| `applicant_contact` | VARCHAR(15) | NULL | — | — | Contact number of applicant |
| `stages_json` | JSON | NULL | — | — | Multi-stage approval history; [{stage, status, by, at, remarks}] |
| `status` | ENUM('Pending_Approval','Approved','Rejected','Issued','Cancelled') | NOT NULL | 'Pending_Approval' | — | Request lifecycle |
| `approved_by` | INT UNSIGNED | NULL | — | FK→sys_users | Approving authority |
| `approved_at` | DATETIME | NULL | — | — | Approval timestamp |
| `rejection_reason` | TEXT | NULL | — | — | Required when Rejected |
| `cert_number` | VARCHAR(30) | NULL | — | UNIQUE | BON-YYYY-NNN, CHAR-YYYY-NNN etc.; NULL until issued (BR-FOF-006); UNIQUE allows multiple NULLs |
| `issued_at` | DATETIME | NULL | — | — | Issuance timestamp |
| `issued_by` | INT UNSIGNED | NULL | — | FK→sys_users | Staff who issued the certificate |
| `issued_to` | VARCHAR(100) | NULL | — | — | Receiver name (may differ from applicant) |
| `media_id` | INT UNSIGNED | NULL | — | FK→sys_media | Generated PDF; sys_media uses INT UNSIGNED |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `uq_fof_cr_request_number (request_number)`, `uq_fof_cr_cert_number (cert_number)`, `idx_fof_cr_student (student_id)`, `idx_fof_cr_status (status)`, `idx_fof_cr_cert_type (cert_type)`, `idx_fof_cr_approved_by (approved_by)`, `idx_fof_cr_issued_by (issued_by)`, `idx_fof_cr_media (media_id)`

---

### Domain D — Complaints & Feedback (3 tables)

---

#### `fof_complaints` — Front-office lightweight complaint intake

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `complaint_number` | VARCHAR(30) | NOT NULL | — | UNIQUE | FOF-CMP-YYYY-NNNNN |
| `complainant_name` | VARCHAR(100) | NOT NULL | — | — | Person filing the complaint |
| `complainant_contact` | VARCHAR(15) | NULL | — | — | Contact number |
| `complaint_type` | ENUM('Academic','Facility','Staff_Behavior','Fee','Safety','Transportation','Food','Hygiene','Other') | NOT NULL | — | — | Complaint category |
| `description` | TEXT | NOT NULL | — | — | Full complaint description |
| `urgency` | ENUM('Normal','Urgent','Critical') | NOT NULL | 'Normal' | — | Priority level |
| `assigned_to_user_id` | INT UNSIGNED | NULL | — | FK→sys_users | Staff handling the complaint |
| `status` | ENUM('Open','In_Progress','Resolved','Closed','Escalated') | NOT NULL | 'Open' | — | Resolution status |
| `resolution_notes` | TEXT | NULL | — | — | Resolution details |
| `resolved_at` | DATETIME | NULL | — | — | Resolution timestamp |
| `resolved_by` | INT UNSIGNED | NULL | — | FK→sys_users | Staff who resolved |
| `cmp_complaint_id` | INT UNSIGNED | NULL | — | FK→cmp_complaints | Set on escalation; cmp_complaints uses INT UNSIGNED PK |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `uq_fof_cmp_complaint_number (complaint_number)`, `idx_fof_cmp_status_urgency (status, urgency)`, `idx_fof_cmp_assigned (assigned_to_user_id)`, `idx_fof_cmp_escalated (cmp_complaint_id)`

---

#### `fof_feedback_forms` — Feedback form definitions (MCQ/rating/text questions)

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `title` | VARCHAR(200) | NOT NULL | — | — | Form title |
| `description` | TEXT | NULL | — | — | Form instructions/description |
| `questions_json` | JSON | NOT NULL | — | — | Array of questions: [{type, question, options}] |
| `token` | VARCHAR(64) | NOT NULL | — | UNIQUE | Public access token for URL; GET /feedback/{token} |
| `is_anonymous_allowed` | TINYINT(1) | NOT NULL | 0 | — | 1 = anonymous submissions accepted (BR-FOF-010) |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable; inactive forms show "closed" page |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `uq_fof_ff_token (token)`, `idx_fof_ff_active (is_active)`

---

#### `fof_feedback_responses` — Individual form submissions

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `feedback_form_id` | BIGINT UNSIGNED | NOT NULL | — | FK→fof_feedback_forms | Parent form |
| `respondent_user_id` | INT UNSIGNED | NULL | — | FK→sys_users | NULL = anonymous submission; BR-FOF-010 enforces NULL when is_anonymous=1 |
| `respondent_name` | VARCHAR(100) | NULL | — | — | Optional name for anonymous submissions |
| `is_anonymous` | TINYINT(1) | NOT NULL | 0 | — | 1 = user chose anonymous; respondent_user_id MUST be NULL |
| `responses_json` | JSON | NOT NULL | — | — | Array of answers: [{question_id, answer}] |
| `submitted_at` | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | — | Submission timestamp |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint); use 0 for anonymous |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_fof_fr_form (feedback_form_id)`, `idx_fof_fr_respondent (respondent_user_id)`, `idx_fof_fr_submitted (submitted_at)`

---

### Domain E — Communication Logs (3 tables)

---

#### `fof_email_templates` — Reusable email templates with placeholder support

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `name` | VARCHAR(100) | NOT NULL | — | — | Template name (internal reference) |
| `subject` | VARCHAR(300) | NOT NULL | — | — | Email subject (may contain {{placeholders}}) |
| `body` | LONGTEXT | NOT NULL | — | — | HTML body with {{placeholder}} support |
| `module` | VARCHAR(50) | NULL | — | — | Source module e.g., 'FrontOffice' |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_fof_et_active (is_active)`

---

#### `fof_communication_logs` — Bulk email/SMS send audit log

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `template_id` | BIGINT UNSIGNED | NULL | — | FK→fof_email_templates | Template used (NULL if ad-hoc) |
| `channel` | ENUM('Email','SMS') | NOT NULL | — | — | Communication channel |
| `subject` | VARCHAR(300) | NULL | — | — | Email subject (NULL for SMS) |
| `body` | TEXT | NOT NULL | — | — | Message body |
| `recipient_group` | VARCHAR(100) | NOT NULL | — | — | e.g., 'All_Parents', 'Class_5_Parents', 'All_Staff' |
| `total_recipients` | INT UNSIGNED | NOT NULL | 0 | — | Total recipient count |
| `sent_count` | INT UNSIGNED | NOT NULL | 0 | — | Successfully sent count |
| `failed_count` | INT UNSIGNED | NOT NULL | 0 | — | Failed delivery count |
| `sent_at` | TIMESTAMP | NULL | — | — | When bulk send was dispatched |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_fof_cl_created_at (created_at)`, `idx_fof_cl_channel (channel)`, `idx_fof_cl_template (template_id)`

---

#### `fof_sms_logs` — Per-recipient SMS delivery tracking

| Column | Type | Nullable | Default | Constraint | Comment |
|--------|------|----------|---------|------------|---------|
| `id` | BIGINT UNSIGNED | NOT NULL | AI | PK | Primary key |
| `communication_log_id` | BIGINT UNSIGNED | NOT NULL | — | FK→fof_communication_logs | Parent bulk send log |
| `recipient_user_id` | INT UNSIGNED | NOT NULL | — | FK→sys_users | Recipient user |
| `mobile_number` | VARCHAR(15) | NOT NULL | — | — | Destination mobile number |
| `message` | TEXT | NOT NULL | — | — | SMS message text |
| `sms_units` | TINYINT UNSIGNED | NOT NULL | 1 | — | Number of SMS units (>160 chars = multi-unit; BR-FOF-011) |
| `status` | ENUM('Queued','Sent','Delivered','Failed') | NOT NULL | 'Queued' | — | Delivery status |
| `sent_at` | TIMESTAMP | NULL | — | — | Send timestamp |
| `delivered_at` | TIMESTAMP | NULL | — | — | Delivery confirmation |
| `gateway_response` | TEXT | NULL | — | — | Raw gateway response for debugging |
| `is_active` | TINYINT(1) | NOT NULL | 1 | — | Soft enable/disable |
| `created_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `updated_by` | BIGINT UNSIGNED | NOT NULL | — | — | sys_users.id (no FK constraint) |
| `created_at` | TIMESTAMP | NULL | — | — | |
| `updated_at` | TIMESTAMP | NULL | — | — | |
| `deleted_at` | TIMESTAMP | NULL | — | — | Soft delete |

**Indexes:** `idx_fof_sl_comm_log (communication_log_id)`, `idx_fof_sl_recipient (recipient_user_id)`, `idx_fof_sl_status (status)`

---

## Section 3 — Entity Relationship Diagram (Text-based)

```
══════════════════════════════════════════════════════════════════
  FOF MODULE — INTERNAL RELATIONSHIPS
══════════════════════════════════════════════════════════════════

CORE REGISTERS
  fof_visitor_purposes ──< fof_visitors (purpose_id)

COMMUNICATION
  fof_circulars ──────────< fof_circular_distributions (circular_id)
  fof_feedback_forms ─────< fof_feedback_responses (feedback_form_id)
  fof_email_templates ────< fof_communication_logs (template_id)
  fof_communication_logs ─< fof_sms_logs (communication_log_id)

══════════════════════════════════════════════════════════════════
  CROSS-MODULE FK REFERENCES (FOF → External)
══════════════════════════════════════════════════════════════════

→ sys_users (INT UNSIGNED PK)
  fof_visitors.meet_user_id [FK, nullable]
  fof_gate_passes.staff_user_id [FK, nullable — staff passes only]
  fof_gate_passes.approved_by [FK, nullable]
  fof_phone_diary.recipient_user_id [FK, nullable]
  fof_phone_diary.logged_by [FK, nullable]
  fof_postal_register.assigned_to_user_id [FK, nullable]
  fof_dispatch_register.dispatched_by [FK, nullable]
  fof_circulars.approved_by [FK, nullable]
  fof_circulars.distributed_by [FK, nullable]
  fof_circular_distributions.recipient_user_id [FK, NOT NULL]
  fof_appointments.with_user_id [FK, NOT NULL]
  fof_appointments.confirmed_by [FK, nullable]
  fof_lost_found.found_by_user_id [FK, nullable]
  fof_key_register.issued_to_user_id [FK, nullable — NULL = available]
  fof_certificate_requests.approved_by [FK, nullable]
  fof_certificate_requests.issued_by [FK, nullable]
  fof_complaints.assigned_to_user_id [FK, nullable]
  fof_complaints.resolved_by [FK, nullable]
  fof_feedback_responses.respondent_user_id [FK, nullable — NULL for anonymous]

→ sys_media (INT UNSIGNED PK)
  fof_visitors.photo_media_id [FK, nullable — INT UNSIGNED]
  fof_circulars.attachment_media_id [FK, nullable — INT UNSIGNED]
  fof_notices.attachment_media_id [FK, nullable — INT UNSIGNED]
  fof_lost_found.photo_media_id [FK, nullable — INT UNSIGNED]
  fof_certificate_requests.media_id [FK, nullable — INT UNSIGNED]

→ std_students (INT UNSIGNED PK)
  fof_gate_passes.student_id [FK, nullable — NULL for staff passes]
  fof_early_departures.student_id [FK, NOT NULL]
  fof_certificate_requests.student_id [FK, NOT NULL]

→ vsm_visitors (BIGINT UNSIGNED PK — pending module)
  fof_visitors.vsm_visitor_id [FK, nullable — pre-registered visitor handoff ONLY]

→ cmp_complaints (INT UNSIGNED PK)
  fof_complaints.cmp_complaint_id [FK, nullable — INT UNSIGNED; set on escalation ONLY]

══════════════════════════════════════════════════════════════════
  TABLES WITH NO FOF DEPENDENCIES (Layer 1)
══════════════════════════════════════════════════════════════════
  fof_visitor_purposes      — no fof_* deps
  fof_emergency_contacts    — no fof_* deps
  fof_notices               — no fof_* deps
  fof_school_events         — no fof_* deps
  fof_email_templates       — no fof_* deps
  fof_feedback_forms        — no fof_* deps
  fof_key_register          — no fof_* deps (→ sys_users only)

══════════════════════════════════════════════════════════════════
  EXTERNAL TABLES — READ ONLY (FOF never modifies schema)
══════════════════════════════════════════════════════════════════
  sys_users         — staff lookup, approvals, assignments
  sys_media         — file storage for photos, attachments, PDFs
  sys_activity_logs — audit trail (WRITE: certs, circulars, govt visits)
  std_students      — student gate pass, early departure, certificates
  vsm_visitors      — pre-registered visitor handoff
  cmp_complaints    — escalation FK linkage only
  ntf_notifications — FOF fires events; NTF module owns delivery
```

---

## Section 4 — Business Rules (15 Rules)

| Rule ID | Rule | Table / Column | Enforcement Point |
|---------|------|---------------|-------------------|
| BR-FOF-001 | Visitor ID proof type and number must be captured | `fof_visitors.id_proof_type`, `id_proof_number` | `form_validation` — `RegisterVisitorRequest` |
| BR-FOF-002 | Visitors not checked out by school closing time auto-flagged `Overstay` | `fof_visitors.status = 'Overstay'` | `scheduled_command` — `fof:flag-overstay` runs at configurable closing time (default 17:00) |
| BR-FOF-003 | Student gate passes require parent NTF dispatch before exit authorization | `fof_gate_passes.parent_notified` | `service_layer` — `GatePassService::createPass()` dispatches NTF; front desk warned on NTF failure |
| BR-FOF-004 | A student may only have one active gate pass (Pending/Approved/Exited) at a time | `fof_gate_passes` — student_id + status | `form_validation` — custom rule in `IssueGatePassRequest` queries for existing active pass |
| BR-FOF-005 | TC_Copy and Migration certificate require no outstanding fees | `fof_certificate_requests.cert_type IN ('TC_Copy','Migration')` | `service_layer` — `CertificateIssuanceService::issue()` calls FIN balance check before proceeding |
| BR-FOF-006 | Certificate numbers must be unique per type per school-year | `fof_certificate_requests.cert_number` | `db_constraint` (UNIQUE on cert_number) + `service_layer` — `getNextCertNumber()` with type prefix |
| BR-FOF-007 | Government inspection visitor records cannot be deleted | `fof_visitors` where `purpose.is_government_visit = 1` | `policy` — `VisitorPolicy::delete()` blocks deletion; permanently retained |
| BR-FOF-008 | Approved circulars cannot be edited; new version must be created | `fof_circulars.status IN ('Approved','Distributed')` | `service_layer` — `CircularController::update()` blocked; returns HTTP 403 with message |
| BR-FOF-009 | Postal register entries are locked after acknowledgement is recorded | `fof_postal_register.acknowledged_at IS NOT NULL` | `service_layer` — `PostalRegisterController::acknowledge()` sets lock; update blocked once set |
| BR-FOF-010 | Anonymous feedback: respondent_user_id must be NULL; is_anonymous must be 1 | `fof_feedback_responses.respondent_user_id`, `is_anonymous` | `service_layer` — `FeedbackController::publicSubmit()` enforces NULL user_id when is_anonymous=1 |
| BR-FOF-011 | SMS over 160 characters counted as multiple units; cost shown before send | `fof_sms_logs.sms_units` | `form_validation` — client-side counter + `SendBulkSmsRequest` server-side unit calculation |
| BR-FOF-012 | Key already issued cannot be re-issued until returned | `fof_key_register.status = 'Issued'` | `service_layer` — `KeyRegisterController::issue()` checks current status; blocks if Issued/Overdue |
| BR-FOF-013 | Student early departure ATT sync failure must be surfaced to receptionist — silent failure not acceptable | `fof_early_departures.att_sync_status = 'Failed'` | `service_layer` — `EarlyDepartureService::syncAttendance()` updates status, dispatches retry job AND sets front desk flash alert |
| BR-FOF-014 | Emergency notices bypass display date constraints and are always shown | `fof_notices.is_emergency = 1` | `model_event` / controller — `NoticeBoardController` always includes `is_emergency = 1` notices regardless of `display_until` |
| BR-FOF-015 | Aadhar ID proof numbers displayed with only last 4 digits visible in UI | `fof_visitors.id_proof_number` when `id_proof_type = 'Aadhar'` | `policy` — Blade helper/directive masks number; full number stored encrypted per tenant policy; never sent to browser in full |

---

## Section 5 — Workflow State Machines (5 FSMs)

### FSM 1 — Visitor Lifecycle

```
[Walk-in arrives at reception desk]
        │
        ▼ VisitorService::createVisitor()
        │  - pass_number generated: VP-YYYYMMDD-NNN
        │  - in_time = NOW()
        │  - if vsm_visitor_id provided: auto-populate from vsm_visitors
        │
      [In] ◄────── initial state
        │
        ├──(staff clicks Checkout)──► VisitorService::checkoutVisitor()
        │                                - out_time = NOW()
        │                                - status = 'Out'
        │                              [Out] ✅ TERMINAL
        │
        └──(closing time + out_time IS NULL)──► fof:flag-overstay command
                                                  - batch UPDATE status = 'Overstay'
                                                  - targets all In visitors with out_time NULL
                                                [Overstay] ⚠️

Overstay → Out: receptionist can still manually check out an overstay visitor
```

**Pre-conditions:** Visitor name, mobile, id_proof_type, id_proof_number, purpose_id required (BR-FOF-001)
**Permanent retention:** Records with `is_government_visit=1` cannot be deleted (BR-FOF-007)

---

### FSM 2 — Gate Pass Lifecycle

```
[Gate pass created]
        │
        ▼ GatePassService::createPass()
        │  - pass_number generated: GP-YYYYMMDD-NNN
        │  - if student: NTF parent notification dispatched (BR-FOF-003)
        │  - BR-FOF-004: existing active pass check (blocks duplicate)
        │
[Pending_Approval]
        │
        ├──(authority approves)──► GatePassService::approvePass()
        │                           - approved_by, approved_at recorded
        │                           - front desk notified
        │                          [Approved]
        │                                │
        │                          (person exits at gate)
        │                          GatePassService::markExited()
        │                          - exit_time = NOW()
        │                                │
        │                             [Exited]
        │                                │
        │                          (person re-enters)
        │                          GatePassService::markReturned()
        │                          - actual_return_time = NOW()
        │                                │
        │                           [Returned] ✅ TERMINAL
        │
        ├──(authority rejects)──► rejection_reason required
        │                          [Rejected] TERMINAL
        │
        └──(issuer cancels)──────► [Cancelled] TERMINAL
```

---

### FSM 3 — Circular Lifecycle

```
[Draft created]
        │
        ▼ CircularService::createCircular()
        │  - circular_number: CIR-YYYY-NNNN
[Draft]
        │
        └──(submit for approval)──► CircularService::submitForApproval()
                                      - status = Pending_Approval
                                      - NTF to principal
              [Pending_Approval]
                      │
                      ├──(principal approves)──► CircularService::approve()
                      │                           - status = Approved
                      │                           - approved_by, approved_at set
                      │                           - LOCKS editing (BR-FOF-008)
                      │          [Approved]
                      │                │
                      │          (distribute trigger)
                      │          CircularService::distribute()
                      │          - resolve recipients from audience_filter_json
                      │          - DB transaction:
                      │            * fof_circular_distributions rows (status=Queued)
                      │            * NTF email + SMS jobs dispatched per recipient
                      │            * distributed_at = NOW()
                      │          [Distributed] ✅
                      │                │
                      │          (recall if needed)
                      │          [Recalled]
                      │
                      └──(principal rejects)──► status = Draft (return with notes)
                                                 [Draft] (editable again)
```

---

### FSM 4 — Certificate Request Lifecycle

```
[Request submitted]
        │
        ▼ CertificateIssuanceService::requestCertificate()
        │  - request_number: CERT-YYYY-NNNNN
[Pending_Approval]
        │
        ├──(approver approves)──► status = Approved
        │                          - stages_json updated
        │          [Approved]
        │                │
        │          (front desk issues)
        │          CertificateIssuanceService::issue()
        │          Pre-condition: TC_Copy/Migration → FIN fee clearance (BR-FOF-005)
        │          - cert_number = getNextCertNumber(type, year)
        │          - DomPDF generates PDF with school letterhead
        │          - PDF stored in sys_media → media_id set
        │          - issued_at, issued_by, issued_to recorded
        │          - NTF dispatched to student/parent
        │          [Issued] ✅ TERMINAL
        │
        ├──(approver rejects)──► rejection_reason required; applicant NTF sent
        │                          [Rejected] TERMINAL
        │
        └──(cancelled)──────────► [Cancelled] TERMINAL

Cert Number Prefix Mapping:
  Bonafide → BON | Character → CHAR | Fee_Paid → FEE | Study → STD
  TC_Copy  → TC  | Migration → MIG  | Conduct  → COND | Other → CERT
```

---

### FSM 5 — Appointment Lifecycle

```
[Appointment booked]
        │
        ▼ AppointmentController::store()
        │  - appointment_number: APT-YYYYMMDD-NNN
        │  - slot conflict check: no existing Confirmed for same staff at same time
        │  - with_user notified of pending appointment
[Pending]
        │
        ├──(staff confirms)──► status = Confirmed
        │                       - confirmed_by, confirmed_at set
        │                       - NTF reminder scheduled
        │          [Confirmed]
        │                │
        │          (visitor arrives, meeting occurs)
        │          [Completed] ✅ TERMINAL
        │                │
        │          (visitor does not show)
        │          [No_Show] (auto-flagged after appointment_date + 1 hour passes)
        │
        └──(staff/visitor cancels)──► cancellation_reason required
                                       [Cancelled] TERMINAL
```

---

## Section 6 — Functional Requirements Summary (17 FRs)

### Phase 1 — Core Registers

| FR ID | Name | Phase | Tables Used | Key Validations | Related BRs | Depends On |
|-------|------|-------|-------------|-----------------|-------------|------------|
| FR-FOF-01 | Visitor Management | 1 | `fof_visitors`, `fof_visitor_purposes` | ID proof required; pass_number unique | BR-001,002,007,015 | sys_users, sys_media, vsm_visitors |
| FR-FOF-02 | Gate Pass (Student/Staff) | 1 | `fof_gate_passes` | One active pass per student; person type validates FK | BR-003,004 | sys_users, std_students, NTF |
| FR-FOF-03 | Student Early Departure | 1 | `fof_early_departures` | student_id required; departure_time required; collecting person ID | BR-013 | std_students, ATT service, NTF |
| FR-FOF-04 | Phone Call Log | 1 | `fof_phone_diary` | call_type required; caller_name required; purpose required | — | sys_users |
| FR-FOF-05 | Postal/Courier Register | 1 | `fof_postal_register` | postal_number unique; subject required | BR-009 | sys_users |
| FR-FOF-06 | Dispatch Register | 1 | `fof_dispatch_register` | dispatch_number unique; addressee required; mode valid | — | sys_users |

### Phase 2 — Communication

| FR ID | Name | Phase | Tables Used | Key Validations | Related BRs | Depends On |
|-------|------|-------|-------------|-----------------|-------------|------------|
| FR-FOF-07 | Circular Management | 2 | `fof_circulars`, `fof_circular_distributions` | audience_filter_json required for Specific_Class/Section; unique circular_number | BR-008 | NTF, sys_users, sys_media |
| FR-FOF-08 | Digital Notice Board | 2 | `fof_notices` | display_until after display_from if provided; category valid | BR-014 | sys_media |
| FR-FOF-17 | School Calendar Events | 2 | `fof_school_events` | end_date >= start_date; event_type valid | — | NTF |

### Phase 3 — Certificates & Complaints

| FR ID | Name | Phase | Tables Used | Key Validations | Related BRs | Depends On |
|-------|------|-------|-------------|-----------------|-------------|------------|
| FR-FOF-13 | Certificate Request & Issuance | 3 | `fof_certificate_requests` | student_id exists; copies 1–5; cert_number UNIQUE | BR-005,006 | std_students, FIN, sys_media, DomPDF |
| FR-FOF-14 | Complaint Handling | 3 | `fof_complaints` | complaint_number unique; description required | — | sys_users, CMP module |

### Phase 4 — Support Features

| FR ID | Name | Phase | Tables Used | Key Validations | Related BRs | Depends On |
|-------|------|-------|-------------|-----------------|-------------|------------|
| FR-FOF-09 | Appointment Scheduling | 4 | `fof_appointments` | with_user_id exists; no slot conflict for same staff | — | sys_users, NTF |
| FR-FOF-10 | Lost & Found Register | 4 | `fof_lost_found` | item_number unique; found_location required | — | sys_media |
| FR-FOF-11 | Key Management | 4 | `fof_key_register` | key not already Issued before re-issue | BR-012 | sys_users |
| FR-FOF-12 | Emergency Contacts | 4 | `fof_emergency_contacts` | contact_type valid; primary_phone required | — | — |

### Phase 5 — Feedback & Bulk Communication

| FR ID | Name | Phase | Tables Used | Key Validations | Related BRs | Depends On |
|-------|------|-------|-------------|-----------------|-------------|------------|
| FR-FOF-15 | Feedback Collection | 5 | `fof_feedback_forms`, `fof_feedback_responses` | token unique; anonymous submission enforces NULL user_id | BR-010 | — |
| FR-FOF-16 | Email & SMS Communication | 5 | `fof_communication_logs`, `fof_email_templates`, `fof_sms_logs` | SMS > 160 chars shows multi-unit cost; template_id exists if provided | BR-011 | NTF |

---

## Section 7 — Permission Matrix

| Permission String | Admin | Front Office Staff | Principal | Comm Mgr | Teacher | Student/Parent |
|-------------------|-------|-------------------|-----------|----------|---------|----------------|
| `frontoffice.visitor.view` | ✅ | ✅ | ✅ | — | — | — |
| `frontoffice.visitor.create` | ✅ | ✅ | — | — | — | — |
| `frontoffice.visitor.checkout` | ✅ | ✅ | — | — | — | — |
| `frontoffice.visitor.delete` | ✅ | — | — | — | — | — |
| `frontoffice.gate-pass.view` | ✅ | ✅ | ✅ | — | ✅ | — |
| `frontoffice.gate-pass.create` | ✅ | ✅ | — | — | ✅ | — |
| `frontoffice.gate-pass.approve` | ✅ | — | ✅ | — | — | — |
| `frontoffice.early-departure.view` | ✅ | ✅ | ✅ | — | — | — |
| `frontoffice.early-departure.create` | ✅ | ✅ | — | — | — | — |
| `frontoffice.circular.view` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (distributed only) |
| `frontoffice.circular.create` | ✅ | — | — | ✅ | — | — |
| `frontoffice.circular.approve` | ✅ | — | ✅ | — | — | — |
| `frontoffice.circular.distribute` | ✅ | — | ✅ | ✅ | — | — |
| `frontoffice.notice.view` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `frontoffice.notice.create` | ✅ | ✅ | ✅ | ✅ | — | — |
| `frontoffice.notice.delete` | ✅ | — | ✅ | — | — | — |
| `frontoffice.certificate-request.view` | ✅ | ✅ | ✅ | — | — | ✅ (own requests) |
| `frontoffice.certificate-request.create` | ✅ | ✅ | — | — | — | ✅ |
| `frontoffice.certificate-request.approve` | ✅ | — | ✅ | — | — | — |
| `frontoffice.certificate-request.issue` | ✅ | ✅ | — | — | — | — |
| `frontoffice.complaint.view` | ✅ | ✅ | ✅ | — | — | ✅ (own complaints) |
| `frontoffice.complaint.create` | ✅ | ✅ | — | — | — | ✅ |
| `frontoffice.feedback.view` | ✅ | ✅ | ✅ | — | — | — |
| `frontoffice.feedback.create` | ✅ | ✅ | — | — | — | — |
| `frontoffice.communication.email` | ✅ | — | — | ✅ | — | — |
| `frontoffice.communication.sms` | ✅ | — | — | ✅ | — | — |
| `frontoffice.emergency-contact.view` | ✅ | ✅ | ✅ | — | — | — |
| `frontoffice.emergency-contact.create` | ✅ | ✅ | — | — | — | — |

---

## Section 8 — Service Architecture (5 Services)

---

### Service 1: `VisitorService`

```
Service:    VisitorService
File:       app/Services/VisitorService.php
Namespace:  Modules\FrontOffice\App\Services
Fires:      No direct NTF dispatch (NTF handled by GatePassService for exits)
Depends on: —

Key Methods:
  createVisitor(array $data): Visitor
    └── Generates pass_number VP-YYYYMMDD-NNN using today's date + 3-digit seq
    └── Sets in_time = NOW(), status = 'In'
    └── If vsm_visitor_id provided: reads vsm_visitors to pre-populate fields
    └── Returns persisted Visitor model

  checkoutVisitor(Visitor $visitor): Visitor
    └── Sets out_time = NOW(), status = 'Out'
    └── Validates visitor is currently 'In' or 'Overstay'

  flagOverstay(): int
    └── Batch UPDATE: status = 'Overstay' WHERE status = 'In' AND out_time IS NULL
    └── Called by fof:flag-overstay Artisan command (scheduled at school closing time)
    └── Returns count of records flagged
```

---

### Service 2: `GatePassService`

```
Service:    GatePassService
File:       app/Services/GatePassService.php
Namespace:  Modules\FrontOffice\App\Services
Fires:      NTF parent notification on pass creation (student passes)
Depends on: NTF module (via event dispatch)

Key Methods:
  createPass(array $data): GatePass
    └── Validates BR-FOF-004: no active pass for student_id
    └── Generates pass_number GP-YYYYMMDD-NNN
    └── If person_type = Student: dispatches NTF parent notification (BR-FOF-003)
    └── Sets status = 'Pending_Approval'

  approvePass(GatePass $pass, int $approvedBy, ?string $remarks): GatePass
    └── Updates status = 'Approved', approved_by, approved_at = NOW()
    └── Notifies front desk

  rejectPass(GatePass $pass, string $reason, int $rejectedBy): GatePass
    └── Updates status = 'Rejected', rejection_reason, approved_by, approved_at = NOW()

  markExited(GatePass $pass): GatePass
    └── Updates status = 'Exited', exit_time = NOW()
    └── Pre-condition: status must be 'Approved'

  markReturned(GatePass $pass): GatePass
    └── Updates status = 'Returned', actual_return_time = NOW()
    └── Pre-condition: status must be 'Exited'
```

---

### Service 3: `CircularService`

```
Service:    CircularService
File:       app/Services/CircularService.php
Namespace:  Modules\FrontOffice\App\Services
Fires:      NTF email + optional SMS per recipient on distribute()
Depends on: NTF module, SchoolSetup (class/section resolution)

Key Methods:
  createCircular(array $data): Circular
    └── Generates circular_number CIR-YYYY-NNNN
    └── Sets status = 'Draft'

  submitForApproval(Circular $circular): Circular
    └── Updates status = 'Pending_Approval'
    └── NTF dispatched to principal/approver

  approve(Circular $circular, int $approvedBy): Circular
    └── Updates status = 'Approved', approved_by, approved_at = NOW()
    └── Locks editing (BR-FOF-008)

  distribute(Circular $circular, int $distributedBy): void
    └── Pre-condition: status = 'Approved'
    └── Resolve recipients based on audience:
          Parents/Both: all parent users with students in target classes
          Staff/Both:   all staff users
          Specific_Class/Section: filter by audience_filter_json class/section IDs
    └── DB transaction:
          For each recipient:
            - Create fof_circular_distributions (status = Queued)
            - Dispatch NTF email job
            - If SMS enabled: dispatch NTF SMS job
          Update fof_circulars.status = 'Distributed', distributed_at = NOW()

  recall(Circular $circular): Circular
    └── Updates status = 'Recalled' (distribution stops but already-sent NTFs not recalled)
```

---

### Service 4: `CertificateIssuanceService`

```
Service:    CertificateIssuanceService
File:       app/Services/CertificateIssuanceService.php
Namespace:  Modules\FrontOffice\App\Services
Fires:      NTF to student/parent on issue()
Depends on: FIN fee-clearance service (TC_Copy, Migration), DomPDF, sys_media

Key Methods:
  requestCertificate(array $data): CertificateRequest
    └── Generates request_number CERT-YYYY-NNNNN
    └── Sets status = 'Pending_Approval'
    └── Notifies approver

  approve(CertificateRequest $request, int $approvedBy): CertificateRequest
    └── Updates status = 'Approved'; stages_json appended
    └── Notifies front desk: ready to issue

  issue(CertificateRequest $request, string $issuedTo, int $issuedBy): CertificateRequest
    └── Step 1: Verify status = 'Approved'
    └── Step 2: If cert_type in [TC_Copy, Migration]:
                  FIN fee-clearance check → block if outstanding fees (BR-FOF-005)
    └── Step 3: cert_number = getNextCertNumber(cert_type, year)
    └── Step 4: Load student data + school branding from sch_organizations
    └── Step 5: Render DomPDF using blade template for cert_type
    └── Step 6: Store PDF in sys_media → media_id set
    └── Step 7: Update cert_number, issued_at = NOW(), issued_by, issued_to, status = 'Issued'
    └── Step 8: Dispatch NTF to student/parent: certificate ready for collection

  reject(CertificateRequest $request, string $reason, int $rejectedBy): CertificateRequest
    └── Updates status = 'Rejected', rejection_reason; NTF to applicant

  getNextCertNumber(string $certType, int $year): string
    └── Prefix map: Bonafide→BON | Character→CHAR | Fee_Paid→FEE | Study→STD
    └──            TC_Copy→TC   | Migration→MIG  | Conduct→COND | Other→CERT
    └── Format: {PREFIX}-{YYYY}-{NNN} — sequence resets each year per type
    └── Uses DB lock to prevent duplicate assignment (BR-FOF-006)
```

---

### Service 5: `EarlyDepartureService`

```
Service:    EarlyDepartureService
File:       app/Services/EarlyDepartureService.php
Namespace:  Modules\FrontOffice\App\Services
Fires:      NTF confirmation to parent; EarlyDepartureAttSyncJob on failure
Depends on: ATT module service call, NTF module

Key Methods:
  logDeparture(array $data): EarlyDeparture
    └── Generates departure_number ED-YYYYMMDD-NNN
    └── Creates fof_early_departures record (att_sync_status = 'Pending')
    └── Dispatches parent confirmation NTF
    └── Calls syncAttendance() immediately after creation

  syncAttendance(EarlyDeparture $departure): void
    └── Step 1: Resolve student_id and departure_time from record
    └── Step 2: Call ATT service: markAbsentFromPeriod(student_id, date, departure_time)
    └── Step 3: If success:
                  Update att_sync_status = 'Synced', att_synced_at = NOW()
    └── Step 4: If failure:
                  Update att_sync_status = 'Failed'
                  Dispatch EarlyDepartureAttSyncJob (3 retries, 60s delay)
                  Set front desk session flash alert (BR-FOF-013 — silent failure NOT acceptable)
```

---

## Section 9 — Integration Contracts (5 Integrations)

| Integration | FOF Action | External Module | How | Payload | Failure Handling |
|-------------|-----------|-----------------|-----|---------|------------------|
| **ATT Sync** | Early departure logged | Attendance (ATT) | Service method call: `ATT::markAbsentFromPeriod()` | `{student_id, date, departure_time}` | `att_sync_status = 'Failed'`; EarlyDepartureAttSyncJob dispatched (3 retries, 60s); front desk flash alert raised (BR-FOF-013) |
| **NTF Circular** | Circular distributed | Notification (NTF) | Event dispatch per recipient; NTF module handles email/SMS delivery | `{recipient_user_id, circular_id, channel, subject, body}` | `fof_circular_distributions.status = 'Failed'`; NTF queue retry via NTF's retry mechanism |
| **NTF Gate Pass** | Student gate pass created | Notification (NTF) | `GatePassService::createPass()` dispatches NTF event | `{student_id, pass_number, parent_mobile}` | `parent_notified` remains 0; front desk warned; pass still created |
| **FIN Fee Check** | Certificate issued (TC_Copy/Migration) | StudentFee (FIN) | `CertificateIssuanceService::issue()` calls FIN balance check service before issuing | `{student_id}` → returns `{has_outstanding: bool, amount: decimal}` | Block issuance if `has_outstanding = true`; display outstanding amount; advise student to clear fees |
| **CMP Escalation** | FOF complaint escalated | Complaint (CMP) | `ComplaintController::escalate()` calls CMP service to create full complaint | `{fof_complaint_id, title, description, urgency, complainant_name}` → CMP returns `cmp_complaint_id` | If CMP creation fails: FOF complaint status remains 'Open'; error shown to staff |

---

## Section 10 — Non-Functional Requirements

| NFR | Requirement | Implementation Note |
|-----|-------------|---------------------|
| Performance | Visitor registration < 1 second | Minimal validation; pass_number generated in service layer; no complex queries at registration time |
| Performance | Visitor list loads < 2 seconds | `idx_fof_vis_date (DATE(in_time))` + `idx_fof_vis_status`; paginated 25/page; eager-load purpose only |
| Scalability | 300+ visitor registrations/day per tenant | Composite index on `in_time`; `DATE(in_time)` functional index for daily queries |
| Print Support | Visitor pass, gate pass, early departure slip via CSS `@media print` (no PDF) | Dedicated `*_pass.blade.php` views with print-only CSS; A6 slip format; school logo + pass details |
| Certificate PDF | DomPDF with school letterhead template per cert type | Separate blade template per cert_type; fetches school branding from `sch_organizations`; stored in sys_media |
| ATT Sync Failure | Silent failure NOT acceptable (BR-FOF-013) | `EarlyDepartureService` must set flash alert AND dispatch retry job; `att_sync_status = 'Failed'` badge shown in today's departures list |
| NTF Graceful Degrade | Queue retry if NTF channel unavailable | FOF dispatches events; NTF module owns retry; FOF logs status via `fof_circular_distributions.status` |
| Government Visit Retention | Permanent; no deletion | `VisitorPolicy::delete()` checks `purpose.is_government_visit`; `sys_activity_logs` audit entry on attempt |
| Aadhar Masking | Last 4 digits only in UI | Blade `@aadhar_mask($value)` helper directive; full number never sent in API response or HTML output |
| Tablet Support | Responsive for visitor/early departure forms | Tailwind responsive classes; tested at 768px (tablet) breakpoint; large input fields for touch |
| Localisation | Certificate templates support regional language | `glb_translations` for cert content; Laravel `lang/` for UI strings |
| Audit | Cert issuances, circular distributions, govt visits logged | `sys_activity_logs` write calls in `CertificateIssuanceService::issue()`, `CircularService::distribute()`, `VisitorPolicy::delete()` attempt |

---

## Section 11 — Test Plan Outline

### Feature Tests (Pest)

| File | Key Scenarios |
|------|--------------|
| `tests/Feature/FrontOffice/VisitorRegistrationTest.php` | Register visitor → pass_number VP-format generated; in_time set; status=In |
| `tests/Feature/FrontOffice/VisitorCheckoutTest.php` | Checkout visitor → out_time recorded; status=Out |
| `tests/Feature/FrontOffice/OverstayFlagTest.php` | Run `fof:flag-overstay` → unchecked visitors become Overstay; checked-out visitors unaffected |
| `tests/Feature/FrontOffice/GovtVisitDeleteBlockTest.php` | Delete gov't visit record → 403 blocked; non-govt visit → 200 deleted |
| `tests/Feature/FrontOffice/VSMHandoffTest.php` | Visitor with vsm_visitor_id → FOF auto-populates name/mobile/org from vsm_visitors |
| `tests/Feature/FrontOffice/GatePassCreateTest.php` | Create student gate pass → status=Pending_Approval; parent_notified=1; NTF event fired |
| `tests/Feature/FrontOffice/DuplicateGatePassTest.php` | Student with active pass → second request blocked with validation error (BR-FOF-004) |
| `tests/Feature/FrontOffice/GatePassApprovalTest.php` | Approve gate pass → status=Approved; approved_by/approved_at set |
| `tests/Feature/FrontOffice/GatePassLifecycleTest.php` | Full: Pending → Approved → Exited → Returned; each transition verifies correct column updates |
| `tests/Feature/FrontOffice/EarlyDepartureAttSyncTest.php` | Log departure → ATT mock returns success → att_sync_status=Synced |
| `tests/Feature/FrontOffice/EarlyDepartureAttFailTest.php` | Log departure → ATT mock throws exception → att_sync_status=Failed; EarlyDepartureAttSyncJob queued; session has alert |
| `tests/Feature/FrontOffice/PostalAcknowledgeLockTest.php` | Acknowledge postal entry → subsequent PATCH returns 403 (record locked) |
| `tests/Feature/FrontOffice/CircularDraftApproveTest.php` | Create draft → submit → principal approves → status=Approved |
| `tests/Feature/FrontOffice/CircularEditBlockTest.php` | Attempt edit on Approved circular → 403 returned (BR-FOF-008) |
| `tests/Feature/FrontOffice/CircularDistributionTest.php` | Distribute circular → fof_circular_distributions rows created; NTF events fired |
| `tests/Feature/FrontOffice/CircularAudienceFilterTest.php` | Class 5-only circular → only Class 5 parents in distributions table |
| `tests/Feature/FrontOffice/AppointmentDoubleBookTest.php` | Same staff / same slot → second booking blocked with slot conflict error |
| `tests/Feature/FrontOffice/KeyDoubleIssueTest.php` | Re-issue Issued key → blocked; must be returned first (BR-FOF-012) |
| `tests/Feature/FrontOffice/CertificateRequestTest.php` | Request Bonafide → request_number CERT-format assigned; status=Pending_Approval |
| `tests/Feature/FrontOffice/CertificateFeesBlockTest.php` | Issue TC_Copy → FIN mock returns outstanding fees → issuance blocked (BR-FOF-005) |
| `tests/Feature/FrontOffice/CertificateIssuanceTest.php` | Issue Bonafide (fees clear) → PDF generated (Storage::fake); cert_number assigned; status=Issued |
| `tests/Feature/FrontOffice/FeedbackAnonymousTest.php` | Submit anonymous form → respondent_user_id IS NULL in DB (BR-FOF-010) |
| `tests/Feature/FrontOffice/FeedbackPublicTokenTest.php` | GET /feedback/{token} → correct form rendered without auth middleware |
| `tests/Feature/FrontOffice/ComplaintEscalateTest.php` | Escalate complaint → CMP complaint created; fof_complaints.cmp_complaint_id set; status=Escalated |
| `tests/Feature/FrontOffice/BulkEmailSendTest.php` | Send email to All_Parents → recipient list resolved; comm_log created with correct total_recipients |

### Unit Tests (PHPUnit)

| File | Key Scenarios |
|------|--------------|
| `tests/Unit/FrontOffice/CertificateNumberUniqueTest.php` | Two Bonafide requests same year → sequential cert numbers (BON-2026-001, BON-2026-002) |
| `tests/Unit/FrontOffice/NoticeEmergencyBypassTest.php` | Emergency notice with expired display_until → still included in active notice query |
| `tests/Unit/FrontOffice/SmsMultiPartTest.php` | 161-char SMS → sms_units=2; 160-char SMS → sms_units=1 |
| `tests/Unit/FrontOffice/AadharMaskTest.php` | aadhar_mask('123456789012') → '****-****-9012'; mask does not apply to non-Aadhar types |

### Test Infrastructure

**Required seeder for test DB:** `FofVisitorPurposeSeeder` (provides `fof_visitor_purposes.is_government_visit` for BR-FOF-007 tests)

**Factories:**
- `VisitorFactory` — generates `pass_number` (VP-YYYYMMDD-NNN), `in_time`, `status=In`
- `GatePassFactory` — generates `pass_number` (GP-YYYYMMDD-NNN), `person_type`, `status=Pending_Approval`
- `CircularFactory` — generates `circular_number` (CIR-YYYY-NNNN), `status=Draft`
- `CertificateRequestFactory` — generates `request_number` (CERT-YYYY-NNNNN), `cert_type`, `status=Pending_Approval`

**Mock strategy:**
- `Event::fake()` — circular distribution NTF tests (CircularDistributionTest, CircularAudienceFilterTest)
- `Queue::fake()` — `EarlyDepartureAttSyncJob` queuing test (EarlyDepartureAttFailTest)
- ATT service mock (Mockery) — EarlyDepartureAttSyncTest, EarlyDepartureAttFailTest
- FIN fee service mock (Mockery) — CertificateFeesBlockTest
- `Storage::fake()` — CertificateIssuanceTest (DomPDF PDF output)

---

*Quality Gate Check:*
- [x] All 22 fof_* tables in Section 2 entity inventory
- [x] All 17 FRs (FOF-01 to FOF-17) in Section 6
- [x] All 15 business rules (BR-FOF-001 to BR-FOF-015) in Section 4 with enforcement point
- [x] All 5 FSMs documented with state diagrams and side effects
- [x] All 5 services listed with key method signatures
- [x] All 5 integration contracts documented
- [x] `fof_visitors.vsm_visitor_id → vsm_visitors.id` noted as nullable (pre-reg handoff only)
- [x] `fof_complaints.cmp_complaint_id → cmp_complaints.id` noted as nullable; INT UNSIGNED (matches cmp_complaints PK)
- [x] `fof_certificate_requests.cert_number` UNIQUE constraint noted (BR-FOF-006)
- [x] No `tenant_id` column on any table
- [x] BR-FOF-007 enforcement point: policy
- [x] BR-FOF-008 enforcement point: service_layer/controller
- [x] BR-FOF-013 (ATT sync failure = front desk alert, not silent) explicitly noted
- [x] Permission matrix covers all 6 roles
- [x] FOF vs VSM distinction stated in Section 1
- [x] Cross-module column types verified: sys_users.id=INT, std_students.id=INT, sys_media.id=INT, cmp_complaints.id=INT
