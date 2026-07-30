# Postal Register — Business Requirements

## What This Screen Does

The Postal Register tracks all incoming (Inward) and outgoing (Outward) mail. Entries are split into two sub-tabs (Inward Mail / Outward Mail) with card-style layout. Each entry captures sender/recipient, document type, subject, courier details, tracking, and departmental assignment.

## When This Screen Is Used

- **Inward Mail Logging**: Receiving letters, couriers, parcels, government notices
- **Outward Mail Logging**: Sending official correspondence
- **Acknowledgment Tracking**: Marking inward mail as acknowledged
- **Courier Tracking**: Recording courier company + tracking numbers

## Key Fields

- **postal_type** (enum) — Inward, Outward
- **postal_number** (string) — Auto-generated unique identifier
- **postal_date** (date) — Mail received/sent date
- **document_type** (enum) — Letter, Courier, Parcel, Government_Notice, Cheque, Legal, Other
- **subject** (string) — Mail subject
- **sender_name / sender_address** — For inward
- **recipient_name / recipient_address** — For outward
- **courier_company / tracking_number** — Courier tracking
- **acknowledged_at** (datetime, nullable) — When inward mail was acknowledged
- **department / assigned_to_user_id** — Departmental routing
- **remarks** (text, nullable)

## Requirements

- MUST display in Registers tab group with Inward/Outward sub-tabs
- MUST authorize via `frontoffice.postal-register.*` policy gates
- MUST show card-style layout with colored left border
- MUST show Acknowledge button for unacknowledged inward mail
- MUST show acknowledged date badge for acknowledged mail
- MUST support status toggle via Ajax
- MUST create entries via modal form
- MUST search across postal_number, tracking_number, sender/recipient, subject, department
