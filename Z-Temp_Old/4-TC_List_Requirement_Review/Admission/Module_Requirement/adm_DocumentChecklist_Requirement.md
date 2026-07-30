# Document Checklist — Business Requirements

## What This Screen Does

The Document Checklist screen defines documents applicants must upload during admission. Each item specifies name, code, mandatory flag, accepted formats, max size, and sort order. Items can be scoped to a cycle or class, or left as global templates.

It is the second tab in `/admission/setup?tab=checklist`.

## When This Screen Is Used

- Admission Setup: Configuring required documents per cycle
- Mid-Cycle: Adding or modifying document requirements
- Application: Applicants see mandatory items during submission

## Default Data

A seeder idempotently creates 10 items: Birth Certificate, Aadhar Card, TC, Marksheet, Photo, Caste Certificate, Address Proof, Income Certificate, Sibling ID, and Transfer Certificate.

## Key Fields

- **Admission Cycle** — FK to cycle (nullable = global template)
- **Class** — Optional class restriction (nullable = all classes)
- **Document Name** — Display name (e.g., "Birth Certificate")
- **Document Code** — Unique identifier per cycle (e.g., BIRTH_CERT)
- **Is Mandatory** — Required for submission
- **Accepted Formats** — Comma-separated extensions (default: pdf,jpg,png)
- **Max Size KB** — File size limit (default: 5120 = 5 MB)
- **Sort Order** — Display ordering

## Business Rules

**Two Parallel CRUDs:** Both `DocumentChecklistController` (inline validation, full-page) and `AdmSettingsController` (FormRequest, AJAX) are active. The setup tab primarily uses the former.

**Inline Validation Gaps:** Controller does NOT enforce unique `document_code` per cycle (FormRequest does). Controller accepts `document_name` up to 150 chars but DDL restricts to 100. `is_active` user input on store is ignored (always set to 1).

**No System-Item Protection:** Unlike Dropdown Needs, system items are not protected from edit/delete.

## Workflow

1. Admin navigates to Checklist tab and clicks Add New
2. Selects cycle, enters name/code, configures formats/size, marks mandatory
3. Saves — item appears in table with active toggle
4. Can edit, toggle active status, soft-delete, restore, or force-delete

## Related Screens

- Admission Cycles — parent tab
- Application Documents — FK refs checklist_item_id (RESTRICT on delete)
- Application Verification — uses checklist for document requirements

## Requirements

- MUST display checklist in setup tab with search and status filter
- MUST authorize via `tenant.adm-document-checklist.*` gates
- MUST enforce validation on store/update (BC-VAL-01 through 08)
- MUST default is_system=0, is_active=1 on create
- MUST log all CRUD operations via activityLog()
- MUST support soft-delete, restore, force-delete lifecycle
- MUST provide AJAX toggle-status endpoint returning JSON
