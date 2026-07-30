# Visitors — Business Requirements

## What This Screen Does

The Visitors tab tracks all physical visitors to the school campus. Each visitor is issued a **pass number** (unique identifier) and their entry is logged with **in-time**, **purpose**, **person to meet**, and optional **vehicle number** and **photo**. Visitors can be **checked out** (out_time set), printing a pass, and their records are soft-deletable unless linked to a government visit purpose.

## When This Screen Is Used

- **Visitor Check-In**: Registering visitors at the security gate with purpose + ID proof
- **On-Campus Monitoring**: Viewing currently checked-in visitors ("On Campus" / "Overstay" status)
- **Visitor Check-Out**: Recording departure time when visitor leaves
- **Pass Printing**: Generating a visitor pass with QR/bar code for display
- **Attendance Logging**: Maintaining a record of all visitor entries for security audits

## Key Fields

- **Pass Number** (string) — Unique auto-generated identifier
- **Visitor Name** (string 100) — Full name
- **Visitor Mobile** (string, regex 10-15 digits)
- **Visitor Email** (string 100, nullable)
- **ID Proof** (enum, nullable) — Aadhar, Driving_License, Passport, Voter_ID, PAN, Employee_ID, Other
- **ID Proof Number** (string 50, nullable)
- **Address** (string 200, nullable)
- **Organization** (string 100, nullable)
- **Purpose** (FK → `fof_visitor_purposes`) — Linked visit reason
- **Person to Meet** (string 100, nullable)
- **Meet User** (FK → `sys_users`, nullable) — Staff member being visited
- **Vehicle Number** (string 20, nullable)
- **Accompanying Count** (integer 0-20)
- **Photo** (media library collection `visitor_photo`, nullable)
- **In Time** (datetime) — Check-in timestamp
- **Out Time** (datetime, nullable) — Check-out timestamp
- **Status** (derived) — "In" / "Overstay" / "Checked Out" (based on in_time + out_time)

## Business Rules

**Government Visit Protection (BR-FOF-007):** `VisitorPolicy::delete()` and `forceDelete()` return `false` if `$visitor->purpose->is_government_visit === true`. The policy returns 403 silently.

**Check-Out Flow:** `checkout()` method on `VisitorController` sets `out_time = now()` and status logic. Triggered via PATCH route with SweetAlert confirm.

**Pass Printing:** `pass()` method returns a dedicated pass view. JavaScript helper `printVisitorPass(id)` opens in a popup window with `auto=1` query param to trigger auto-print.

**Soft Delete:** Uses SoftDeletes. `trashed()`, `restore()`, `forceDelete()` routes available.

**Status Toggle:** Ajax endpoint `toggleStatus()` flips `is_active`.

**Media:** Implements `HasMedia` via Spatie Media Library with single-file collection `visitor_photo` for photo upload.

**Search:** The controller's `visitorManagement()` searches across `pass_number`, `visitor_name`, `visitor_mobile`, `organization`, `person_to_meet`, `status`, and the purpose's `name`/`code`.

## Workflow

1. Staff navigates to Front Office → Visitor Management → Visitors tab (default)
2. Staff sees paginated table: Pass Number, Visitor Details (name + mobile + org), Purpose, In Time, Person to Meet, Status badge, Status toggle, Actions
3. Status badges: "On Campus" (green), "Overstay" (red), "Checked Out" (grey)
4. Checked-in visitors show "Check Out" button and "Print Pass" button
5. Staff can view visitor detail, edit, or delete records

## Requirements

- MUST display at `/front-office/visitor-management?tab=visitors` as paginated table (default tab)
- MUST authorize via `frontoffice.visitor.*` policy gates
- MUST show visitor status badges (On Campus / Overstay / Checked Out)
- MUST support check-in (create), check-out (PATCH), and pass printing
- MUST protect government visit visitors from delete/forceDelete (BR-FOF-007)
- MUST support visitor photo via Spatie Media Library
- MUST support status toggle via Ajax
- MUST support soft delete with restore/forceDelete
