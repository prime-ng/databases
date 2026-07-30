# Alumni — Business Requirements

## What This Screen Does

The Alumni tab lists students who were marked as "Alumni" from confirmed promotion batches. It provides a read-only list with search/filter capabilities, a status toggle, and a quick link to issue Transfer Certificates (TCs) for departing students.

This is the second tab (`?tab=alumni`) of the Promotions & Alumni page at `/admission/promotions-alumni`.

This tab is essentially a view-only listing — the actual data comes from students who have completed their promotion with result=Alumni. The main actions (TC issuance) happen through the TCs tab.

## When This Screen Is Used

- **Alumni Tracking**: Viewing students who have been promoted to alumni status
- **TC Issuance**: Quick access to issue Transfer Certificates for departing students
- **Status Management**: Toggling student active/inactive status

## Key Fields

- Student Name, Admission No, Class
- TC Issued badge — indicates student already has a Transfer Certificate
- Active toggle — enable/disable student status

## Business Rules

**Data Source:** The alumni list is derived from `adm_promotion_records` where `result = 'Alumni'` within confirmed (`status = 'Confirmed'`) promotion batches. The associated `std_students` records are loaded with their current class section.

**TC Issued Indicator:** The `tc_issued` column on `std_students` is set to `true` when a Transfer Certificate is issued (via `TransferCertificateService::issueTc()`). The list shows a "TC Issued" badge for these students.

**Permission Gating:** The tab is visible to users with either `tenant.adm-promotion.viewAny` or `tenant.adm-tc.viewAny` permission.

## Workflow

1. Students are promoted with result=Alumni via promotion batches
2. They appear in the Alumni tab after batch confirmation
3. Staff can search/filter the list to find specific alumni
4. Staff can toggle student active status
5. Staff clicks "Issue TC" to open the TC creation modal on the TCs tab

## Related Screens

- **Batches Tab** — Promotion batches that produce alumni results
- **TCs Tab** — Transfer Certificate issuance (linked from Issue TC button)
- **Incidents Tab** — Behavior incidents for alumni students

## Requirements

- MUST display paginated alumni list with search (name/admission_no), class filter, gender filter
- MUST show "TC Issued" badge for students with tc_issued=true
- MUST provide Issue TC button linking to TC creation
- MUST support AJAX toggle of student is_active status
- MUST be visible to users with promotion.viewAny or tc.viewAny
