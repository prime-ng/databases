# Payment Request — Business Requirements

## What This Screen Does

The Payment Request screen is a **read-only viewer** for the Event Processing Log. It displays system-generated payment-related events (from event mapping automation) across three sub-tabs: All, Approved, and Rejected. No CRUD operations exist — the screen is purely informational for monitoring payment processing.

## When This Screen Is Used

- **When monitoring auto-generated payments** from event mapping execution.
- **When checking the status** of system-processed payment requests.
- **When reviewing approved vs rejected** payment processing events.

## Key Fields (from EventProcessingLog)

- **Event Type** (string) — The system event that triggered this processing
- **Event ID** (integer) — ID of the source event record
- **Status** (enum: pending/processing/completed/failed/approved/rejected)
- **Request Payload** (JSON, nullable) — Input data for the event
- **Response Data** (JSON, nullable) — Output/result data
- **Error Message** (text, nullable) — Error details if failed
- **Processed By** (FK → sys_users, nullable)
- **Processed At** (timestamp, nullable)

## Business Rules

**Read-Only:**
This screen has no create, edit, or delete operations. It is purely a log viewer for the EventProcessingLog model.

**Tab Filters:**
Three sub-tabs: All (all statuses), Approved (status = approved), Rejected (status = rejected). Filtering is client-side or via query parameter.

**Search:**
Supports searching by event type, event ID, or status.

**No Soft Delete:**
As a log viewer, delete operations are not applicable.

## Workflow

1. User navigates to Accounting → Transactions → Payment Requests.
2. First sub-tab "All" loads showing all event processing logs.
3. User can switch to "Approved" or "Rejected" to filter by status.
4. Each row shows: Event Type, Event ID, Status badge, Processed At, Actions (view details).
5. User can view the full request/response payload and error details.

## Requirements

- MUST display at `/accounting/payment-request?tab=payment-requests` with 3 sub-tabs
- MUST authorize via `tenant.accounting.payment-request.*` policy gates
- MUST be read-only — no create/edit/delete
- MUST filter by All / Approved / Rejected status
- MUST show request payload and response data in detail view
- MUST show error message for failed events
