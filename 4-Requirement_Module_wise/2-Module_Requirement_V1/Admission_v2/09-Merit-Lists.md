# Merit Lists — Business Requirements

## What This Screen Does

The Merit Lists screen generates ranked lists of applicants based on composite scores (entrance test, interview, academics, sibling bonus). Within the Assessment tab group, the list view shows all merit lists by cycle and class. The detail/show page has two internal tabs:

1. **Ranked List** — All applicants ranked by composite score with quota type
2. **Allotments** — Which applicants have been allotted seats based on merit rank

---

## When This Screen Is Used

- After entrance test marks are entered: Admin generates a merit list
- Before allotment: Admin reviews the ranked list for accuracy
- After publication: Admin views the final merit list shared with parents
- Mid-allotment: Admin tracks which merit-ranked applicants have been allotted

---

## Key Fields at a Glance

**List Name / Identifier**
Auto-generated or manual label for the merit list (e.g., "Class IX Merit 2027").

**Cycle & Class**
The cycle and class this merit list covers.

**Composite Score Formula**
Configurable weighting: test score + interview score + academic score + sibling bonus. Admin defines the weights.

**Status**
Draft — being computed, not yet published.
Published — finalized and visible to parents/counselors.

**Ranked Entries**
Each entry has: rank number, applicant name, composite score, quota type, allotment status.

---

## Business Rules and Conditions

**Cycle & Class Specific**
A merit list is generated for one cycle + one class combination.

**Score Computation**
The `compute` action fetches all Selected (or Shortlisted) applications for the class, calculates composite scores based on configured weights, and ranks them in descending order.

**Publish Lock**
Once Published, the merit list cannot be re-computed. It becomes a historical record.

**Allotment Link**
Each merit list entry links to the allotment system. Allotted applicants show their allotment status directly in the list.

**Soft Delete**
Merit lists can be soft-deleted. Published lists cannot be deleted without explicit force-delete.

---

## Workflow Steps

**Generating a Merit List**
Admin navigates to the Merit List tab, clicks "Generate Merit List", selects cycle and class, configures score weights (optional), and submits. The system computes composite scores and ranks.

**Viewing Ranked List**
On the show page, the Ranked List tab displays all entries sorted by rank: rank #, applicant name, composite score, quota type.

**Viewing Allotments**
On the show page, the Allotments tab shows how many merit-ranked applicants have been allotted seats.

**Publishing a Merit List**
Admin clicks "Publish" on a Draft merit list. A confirmation dialog appears. Once published, the list is final.

**Deleting a Merit List**
Admin clicks Delete to soft-delete a Draft merit list. Published lists require additional confirmation.

---

## Example Scenario

For Class IX, there are 45 Shortlisted applicants. The admin generates a merit list with:
- Test Score: 60% weight
- Interview Score: 25% weight
- Academic (previous grades): 10% weight
- Sibling Bonus: 5% weight (if applicant has a sibling in the school)

The system computes composite scores and ranks applicants 1–45. The admin reviews and publishes the list. Seats are then allotted in rank order, respecting quota reservations.

---

## Related Screens

- **Entrance Tests** — Test scores feed into composite score computation
- **Allotments** — Allotments are generated from merit list rank order
- **Enquiry Pipeline** — Applicants are sourced from the application pipeline
- **Assessment Tab** — Merit Lists is one of two tabs in the Assessment page
