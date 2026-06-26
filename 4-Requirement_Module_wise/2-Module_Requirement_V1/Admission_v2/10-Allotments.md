# Allotments — Business Requirements

## What This Screen Does

The Allotments screen manages the seat allocation process. After a merit list is published, the system allots seats to eligible applicants based on merit rank and quota reservations. Each allotment represents a specific applicant being assigned a seat in a specific class under a specific quota.

The screen shows an allotments list (within the Allotment & Enrollment tab group) with status, applicant details, quota type, and action buttons. Each allotment has its own show page with detailed information, offer letter generation, and accept/decline actions.

---

## When This Screen Is Used

- After merit list publication: Admin or system generates allotments in rank order
- Parent response window: Allotment show page allows parents to accept or decline the offer
- Admin needs to manually allot a seat to a specific applicant
- Admin tracks allotment status — how many have accepted, declined, or pending

---

## Key Fields at a Glance

**Applicant**
The applicant being allotted a seat. Links to the application record.

**Class & Cycle**
The class and admission cycle for the allotment.

**Quota Type**
The quota under which this allotment is made (e.g., General, RTE, Staff Ward).

**Status**
Allotted — seat has been assigned, awaiting parent response.
Accepted — parent has accepted the offer.
Declined — parent has declined the offer.
Enrolled — applicant has completed enrollment.
Withdrawn — applicant withdrew after allotment.

**Offer Letter**
A PDF generated via DomPDF with verification QR code. Downloaded from the allotment show page.

---

## Business Rules and Conditions

**Merit Order Processing**
Allotments are processed in merit rank order. Higher-ranked applicants get first choice of available seats.

**Quota Respect**
Allotments respect quota reservations. If a quota is full, applicants of that quota type are allotted under General (if available) or waitlisted.

**Capacity Check**
The system refuses to create an allotment if the class has no remaining seats.

**Accept/Decline Workflow**
After allotment, the parent has a configurable window to accept or decline. If no response, the allotment may be auto-released after the deadline.

**Offer Letter PDF**
The offer letter is generated on-demand via DomPDF. It includes a QR code for verification.

**Soft Delete**
Allotments can be soft-deleted. Deleting an allotment frees the seat for the next waitlisted applicant.

---

## Workflow Steps

**Generating Allotments**
Admin clicks "Generate Allotments" from the merit list or allotment page. The system processes applicants in rank order, matching them to available seats per quota.

**Viewing Allotment List**
The allotment tab displays all allotments with status badges, applicant names, class, quota, and action buttons.

**Viewing Allotment Details**
Admin clicks on an allotment to open the show page. This page displays:
- Applicant details
- Allotment status and history
- Offer Letter download button
- Accept/Decline actions (if pending)

**Generating Offer Letter**
Admin clicks "Generate Offer Letter" on the allotment show page. A PDF downloads with the applicant's details and a QR verification code.

**Accepting / Declining an Allotment**
Admin or parent clicks Accept/Decline. On accept, the applicant moves to Enrolled status (pending actual enrollment). On decline, the seat is freed.

**Deleting an Allotment**
Admin clicks Delete. A confirmation dialog appears. The allotment is soft-deleted.

---

## Example Scenario

After publishing the Class IX merit list, the system processes the top 60 applicants (for 60 seats):
1. Rank #1 (General quota) → Allotted to General seat
2. Rank #2 (RTE quota) → Allotted to RTE seat
3. Rank #3 (General quota) → Allotted to General seat
...
Processing continues until all 60 seats are filled. Remaining applicants are marked as Waitlisted.

---

## Related Screens

- **Merit Lists** — Allotments are generated from merit list rank order
- **Enrollment** — Accepted allotments proceed to enrollment conversion
- **Withdrawals** — Allotted seats can be withdrawn (pre-enrollment)
- **Dashboard** — Allotment counts feed into funnel KPIs
- **Offer Letter PDF** — Generated from the allotment show page
