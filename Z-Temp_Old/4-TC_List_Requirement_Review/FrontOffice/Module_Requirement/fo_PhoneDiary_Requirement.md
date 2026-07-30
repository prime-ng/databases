# Phone Diary — Business Requirements

## What This Screen Does

The Phone Diary tracks incoming/outgoing phone calls. Each entry records caller details, purpose, message, and whether follow-up action is required. Calls requiring action that aren't completed show a pending badge and "Mark Done" button.

## When This Screen Is Used

- **Call Logging**: Recording all official phone calls
- **Action Tracking**: Following up on calls that need action
- **Communication Audit**: History of phone communications

## Key Fields

- **call_type** (enum) — Incoming, Outgoing
- **call_date** (date) — Call date
- **call_time** (time) — Call time
- **caller_name** (string 100) — Caller's name
- **caller_number** (string 15, nullable) — Phone number
- **caller_organization** (string 100, nullable) — Organization
- **purpose** (string 200) — Reason for call
- **message** (text, nullable) — Call notes
- **action_required** (boolean) — Whether follow-up needed
- **action_notes** (string, nullable) — Action details
- **action_completed** (boolean) — Whether action done
- **action_completed_at** (datetime, nullable)

## Business Rules

**Pending Actions:** Header shows badge count (`$pendingActions`) for calls with `action_required && !action_completed`. Cards with pending action have yellow `border-warning` left border (vs green for resolved/no action).

**Mark Done:** Calls with action_required and not completed show "Mark Done" button calling `fof.phone-diary.complete`.

**Call Type Badges:** Incoming (green), Outgoing (primary/blue).

**Action Toggle:** `actionNotesWrapper` div shown/hidden via JS when "Action Required" checkbox is toggled in create modal.

## Requirements

- MUST display in Registers tab group as card-style list
- MUST authorize via `frontoffice.phone-diary.*` policy gates
- MUST show pending action count badge in header
- MUST show yellow border for pending-action calls, green for resolved
- MUST show Incoming (green) / Outgoing (blue) badges
- MUST show Mark Done button for unresolved action calls
- MUST search across caller_name, caller_number, organization, purpose, message, action_notes
- MUST filter by call_type (Incoming/Outgoing/All)
