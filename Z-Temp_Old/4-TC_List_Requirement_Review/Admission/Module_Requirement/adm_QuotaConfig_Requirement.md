# Quota Config — Business Requirements

## What This Screen Does

The Quota Config screen defines seat allocation categories (quotas) per class for an admission cycle. Each quota entry specifies the quota type, total seats, reserved seats, and whether the application fee is waived. Examples: General, Management, RTE, EWS, Sibling, Staff Ward, NRI, Government.

It is the third tab in `/admission/setup?tab=quotas`.

## When This Screen Is Used

- Admission Setup: Defining seat distribution quotas per class
- Compliance: Ensuring RTE/EWS mandated reserved seats are configured
- Reporting: Reviewing quota utilization during the admission process

## Default Data

A seeder creates 6 quota types per class (General, Management, Staff_Ward, Sibling, RTE, EWS) with sensible defaults (General=30 seats, RTE=5 reserved, EWS=fee waiver).

## Key Fields

- **Admission Cycle** — FK to cycle
- **Class** — FK to class (required)
- **Quota Type** — Enum: General, Government, Management, RTE, NRI, Staff_Ward, Sibling, EWS
- **Total Seats** — Total seats allocated for this quota+class
- **Reserved Seats** — Mandated minimum reserved seats (e.g., 25% for RTE)
- **Fee Waiver** — Checkbox; if checked, application fee is waived for this quota

## Business Rules

**Seeded Per Class:** The seeder creates quota configs for each active class, ensuring complete coverage.

**Inline Validation Gaps:** Controller does NOT enforce `reserved_seats <= total_seats` (FormRequest does via `lte:total_seats`). Controller uses `min:0` for `total_seats` while FormRequest uses `min:1`.

## Workflow

1. Admin navigates to Quota Config tab and clicks Add New
2. Selects cycle, class, quota type, sets seat numbers, marks fee waiver
3. Saves — entry appears in table with active toggle, total seats badge, fee waiver badge
4. Can edit, toggle, soft-delete, restore, force-delete

## Requirements

- MUST display quotas per active cycle in setup tab with search/filter
- MUST authorize via `tenant.adm-quota-config.*` gates
- MUST enforce validation: quota_type in enum, total_seats ≥ 0, class/cycle exist
- MUST default is_active=1, log CRUD via activityLog()
- MUST support soft-delete, restore, force-delete
- MUST provide AJAX toggle-status endpoint returning JSON
