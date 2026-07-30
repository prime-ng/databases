# Lost & Found — Business Requirements

## What This Screen Does

The Lost & Found tab tracks items found on school premises. Items are split into Unclaimed (active) and Claimed/Disposed (closed) sections. Staff can log found items, record claims with claimant details, and mark items as claimed.

## When This Screen Is Used

- **Found Item Logging**: Recording items found by staff/students
- **Claim Processing**: Verifying and processing claims with claimant details
- **Disposal**: Marking unclaimed items as disposed

## Key Fields

- **item_number** (string) — Auto-generated unique identifier
- **item_description** (string) — Item name/description
- **found_location** (string, nullable) — Where found
- **found_date** (date) — When found
- **status** (enum) — Unclaimed, Claimed, Disposed
- **claimant_name** (string, nullable) — Person who claimed
- **claimant_contact** (string, nullable) — Claimant phone
- **claimed_date** (datetime, nullable) — When claimed
- **remarks** (text, nullable)

## Business Rules

**Status Field:** Uses string-based status (Unclaimed/Claimed/Disposed), not boolean. Unclaimed items show warning border; Claimed items show success border.

**Claim Modal:** Per-item claim modal with claimant name + contact number required. Accessible via "Claim" button on Unclaimed items.

**Unclaimed Section:** Shows items where status ≠ Claimed. Each card shows item_number badge (warning/info color), description, location, found date, status badge, Claim button, Status toggle, Actions.

**Claimed/Disposed Section:** Shows closed items with green success border. Shows claimant name + claimed date.

## Requirements

- MUST display in Registers tab group with Unclaimed + Claimed/Disposed sections
- MUST authorize via `frontoffice.lost-found.*` policy gates
- MUST show claim modal for Unclaimed items
- MUST require claimant name + contact in claim modal
- MUST support status toggle via Ajax
- MUST create entries via modal form
- MUST search across item_description, item_number, found_location, claimant_name, status
