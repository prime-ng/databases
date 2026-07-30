# Circulars — Business Requirements

## What This Screen Does

The Circulars tab manages official school circulars with an approval workflow. Circulars go through Draft → Pending_Approval → Approved → Distributed statuses, with optional recall. Each circular targets an audience (All_Parents, All_Staff, All_Students, Custom) and can include an attachment.

## When This Screen Is Used

- **School Notices**: Sending official communications to parents/staff/students
- **Approval Workflow**: Manager approves draft circulars before distribution
- **Record Keeping**: Archived circulars for audit

## Key Fields

- **circular_number** (string) — Auto-generated unique identifier
- **title** (string 200) — Circular title
- **subject** (string 200, nullable) — Subject line
- **body** (text) — Full circular content
- **audience** (enum) — All_Parents, All_Staff, All_Students, Custom
- **audience_filter_json** (json, nullable) — Custom audience filter criteria
- **effective_date** (date, nullable) — When circular takes effect
- **expires_on** (date, nullable) — When circular expires
- **status** (enum) — Draft, Pending_Approval, Approved, Distributed, Recalled
- **approved_by / approved_at** — Approval user + timestamp
- **distributed_by / distributed_at** — Distribution user + timestamp

## Business Rules

**Locked State:** `isLocked()` returns true when status is Approved or Distributed — prevents editing.

**Status Workflow:** Draft → Pending_Approval → Approved → Distributed. Recalled can be triggered from any post-Draft state.

**Attachment:** Single file via Spatie Media Library `circular_attachment` collection.

**Audience:** `audience_filter_json` stores JSON filter for Custom audience targeting.

## Requirements

- MUST display in Communication tab group as paginated table
- MUST authorize via `frontoffice.circular.*` policy gates
- MUST support status workflow: Draft→Pending_Approval→Approved→Distributed
- MUST support Recalled status
- MUST lock editing when Approved or Distributed
- MUST support single file attachment via Spatie Media Library
- MUST search by title, circular_number
- MUST support status filter: All/Draft/Pending_Approval/Approved/Distributed/Recalled
