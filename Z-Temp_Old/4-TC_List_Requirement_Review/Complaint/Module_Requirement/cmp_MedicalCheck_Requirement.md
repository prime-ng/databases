# Medical Check — Business Requirements

## What This Screen Does

The Medical Checks screen records medical/safety inspections conducted as part of complaint handling. Each medical check is linked to a complaint and records the check type (Alcohol Test, Drug Test, Fitness Check), result (Positive, Negative, Inconclusive), reading value, conducting officer, and optional evidence image.

## When This Screen Is Used

- **When a complaint requires medical examination** (e.g., transport accidents, health incidents).
- **When recording alcohol/drug test results** for disciplinary complaints.
- **When documenting fitness checks** for staff involved in incidents.

## Key Fields

- **Complaint** (FK → cmp_complaints) — Parent complaint
- **Check Type** (FK → sys_dropdown_table) — AlcoholTest, DrugTest, FitnessCheck
- **Conducted By** (string 100, nullable) — Doctor/Officer name
- **Conducted At** (datetime) — When check was performed
- **Result** (FK → sys_dropdown_table) — Positive, Negative, Inconclusive
- **Reading Value** (string 50, nullable) — e.g., BAC level
- **Remarks** (text, nullable)
- **Evidence Uploaded** (boolean) — Whether evidence image exists
- **Evidence Image** (Spatie Media Library, medical_img collection)

## Business Rules

**Complaint Association:**
Each medical check is linked to exactly one complaint. Multiple checks can exist per complaint.

**Check Type & Result Dropdowns:**
Both check type and result are FK references to `sys_dropdown_table`, making them configurable without code changes.

**Evidence Upload:**
Supports a single medical evidence image via Spatie Media Library with small/medium/large conversions.

**Soft Delete:**
Uses SoftDeletes. Trash view, restore, and forceDelete routes available.

## Workflow

1. User navigates to Complaint → Complaint Management → Medical Checks tab.
2. Table shows: Complaint Ticket, Check Type, Conducted By, Result, Conducted At, Actions.
3. User creates a check: selects complaint, check type, result, enters details and optional evidence.
4. Records can be edited, toggled, soft-deleted, restored, or force-deleted.

## Requirements

- MUST display at `/complaint/complaint-mgt?tab=medical` as paginated table
- MUST authorize via `tenant.medical-check.*` policy gates
- MUST link to parent complaint
- MUST support configurable check types and results via sys_dropdown_table
- MUST support evidence image upload via Spatie Media Library
- MUST support soft delete with trash view, restore, forceDelete
