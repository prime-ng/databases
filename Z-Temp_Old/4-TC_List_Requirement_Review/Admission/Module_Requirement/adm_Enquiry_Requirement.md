# Enquiries — Business Requirements

## What This Screen Does

The Enquiries screen records prospective student enquiries from various lead sources (Website, Walk-in, Campaign, Referral, etc.). Each enquiry captures student and parent details, the class sought, assigned counselor, lead source information, and sibling relationships. The system auto-generates a unique enquiry number (ENQ-{YEAR}-{SEQ}) and defaults the status to "New".

The enquiries tab is the first of two tabs in the Enquiry Pipeline page (`/admission/enquiry-pipeline?tab=enquiries`). The second tab shows Applications. The pipeline provides a unified view of the admission funnel from initial enquiry through application submission.

Each enquiry can have multiple follow-ups (calls, meetings, emails, SMS, walk-ins) tracked via an AJAX-driven panel on the show page. The status progresses through the lifecycle: New → Assigned → Contacted → Interested → Not_Interested → Callback → Converted → Duplicate.

## When This Screen Is Used

- **Lead Capture**: Recording a new prospect who walks in, calls, or submits an online enquiry
- **Counselor Assignment**: Assigning enquiries to specific counselors for follow-up
- **Pipeline Tracking**: Monitoring the conversion funnel from enquiry to application
- **Follow-up Management**: Scheduling and tracking all interactions with prospects
- **Duplicate Detection**: Flagging duplicate enquiries to prevent redundant follow-ups
- **Reporting**: Analyzing lead source effectiveness, counselor performance, conversion rates

## Key Fields

**Student Information**
- Student Name (required), Date of Birth (used for age validation against cycle rules), Gender
- Father's Name, Mother's Name

**Contact Information**
- Contact Person (required), Contact Mobile (required), Contact Email

**Admission Context**
- Admission Cycle (required) — determines age rules and application period
- Class Sought (required) — target class for admission

**Lead Information**
- Lead Source (Website, Walk-in, Campaign, Referral, Social_Media, Phone, Other)
- Source Reference (e.g., campaign name, referring party)
- Assigned Counselor — FK to sys_users

**Sibling Lead**
- is_sibling_lead flag — if checked, the enquiry is linked to an existing student (sibling)
- Sibling Student ID — FK to std_students

**Status Lifecycle**
- New → Assigned → Contacted → Interested / Not_Interested / Callback → Converted / Duplicate
- Displayed as color-coded badges (New=blue, Contacted=info, Visited=warning, Applied=success, Dropped=secondary)

**Enquiry Number**
- Auto-generated format: ENQ-{YEAR}-{SEQ:5 digits} (e.g., ENQ-2026-00001)
- Sequential per year, resetting annually

## Business Rules

**Auto-Generated Enquiry Number:** On creating, the `boot()` method queries the last enquiry starting with `ENQ-{YEAR}-`, increments the 5-digit sequence, and formats the number. This ensures unique, sequentially ordered identifiers.

**Age Validation:** The `StoreEnquiryRequest::withValidator()` checks the student's DOB against the selected cycle's `age_rules_json`. If the cycle defines `min_age` or `max_age`, the calculated age at the cycle's end date must fall within the range. If either the cycle or `age_rules_json` is missing, validation is skipped.

**Sibling Lead Handling:** When `is_sibling_lead` is checked, the `sibling_student_id` is stored. When unchecked, `sibling_student_id` is forced to null regardless of submitted value.

**Delete Protection:** An enquiry cannot be deleted if it has linked applications. The destroy method checks `applications()->exists()` and aborts with 403.

**Follow-ups Are Nested:** Follow-ups are always scoped to a specific enquiry. The FollowUpController verifies `follow_up.enquiry_id === $enquiry->id` on update/destroy, aborting 404 on mismatch. When a follow-up outcome is provided, `completed_at` is automatically set to now().

**Dual Response Format:** The store method accepts both form POST (returns redirect) and JSON POST (returns JSON). This enables both the full page form and potential AJAX/API usage.

## Workflow

1. Admin records a new enquiry with student details, contact info, class sought, and lead source
2. System auto-generates enquiry number and sets status to "New"
3. Admin assigns a counselor for follow-up
4. Counselor contacts the prospect and records follow-ups (call, meeting, email, SMS, walk-in)
5. Status is updated as the prospect progresses: Contacted → Interested → Converted
6. If the prospect submits an application, it links to this enquiry
7. Duplicate enquiries are flagged via is_duplicate; unconverted enquiries are periodically reviewed

## Related Screens

- **Applications** — Second tab in the pipeline; applications linked to enquiries
- **Follow-ups** — AJAX panel within the enquiry show page
- **Admission Cycles** — Cycle determines age rules and application window
- **Counselor Management** — Users assigned as counselors for enquiry follow-up

## Requirements

- MUST display paginated enquiries list at `/admission/enquiry-pipeline?tab=enquiries` with search (name, mobile, enquiry_no) and status filter
- MUST authorize via `tenant.adm-enquiry.*` and `tenant.adm-follow-up.*` gates
- MUST auto-generate enquiry_no as ENQ-{YEAR}-{SEQ:5 digits} on create
- MUST enforce validation on store (BC-VAL-01 through 17)
- MUST enforce age validation via withValidator using cycle's age_rules_json
- MUST default status=New, is_active=true on create
- MUST handle is_sibling_lead checkbox logic (clear sibling_student_id when unchecked)
- MUST support JSON response for store when requested
- MUST abort 403 on delete if enquiry has linked applications
- MUST support follow-ups as nested AJAX CRUD under each enquiry
- MUST verify follow-up belongs to the correct enquiry on update/destroy (404 on mismatch)
- MUST set completed_at=now() when follow-up outcome is provided
- MUST support soft-delete, restore, force-delete lifecycle
- MUST provide AJAX toggle-status endpoint returning JSON
- MUST log all CRUD operations via activityLog() where applicable
