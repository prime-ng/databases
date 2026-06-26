# Mess Bills — Business Requirements

## What This Screen Does

The Mess Bills screen computes and manages monthly mess bills for each student. The bill is calculated based on planned meals, actual attendance, leave days, opt-outs, special diet charges, and any manual adjustments. The final amount can be pushed to the student's fee account for consolidated collection.

---

## When This Screen Is Used

- End of each month: Generating mess bills for all hostel students
- Reviewing individual student mess bills
- Applying manual adjustments (credits or additional charges)
- Pushing mess bills to the fee module
- Student/parent inquiry about mess charges

---

## Key Fields

- **Student** — Billed student
- **Month / Year** — Billing period
- **Planned Meals** — Number of meals in the month
- **Consumed Meals** — Based on attendance records
- **Leave Days** — Days on approved leave
- **Opt-Out Days** — Days with approved opt-out
- **Base Charge** — Standard mess fee for the period
- **Leave Credit** — Credit for leave days
- **Opt-Out Credit** — Credit for opt-out days
- **Special Diet Charge** — Additional charge if applicable
- **Manual Adjustment** — Any manual addition/deduction
- **Total Amount** — Final amount (auto-calculated)
- **Pushed to Fee** — Whether amount has been sent to fee account
- **Pushed Date** — When pushed to fee
- **Status** — Draft / Final / Pushed / Disputed / Paid

---

## Business Rules

- Bills are generated monthly, typically at month-end
- Calculation: Base charge − Leave credit − Opt-out credit + Special diet charge ± Manual adjustment
- Leave credit is calculated based on number of meal-times missed during leave period
- Opt-out credit depends on configured policy (full credit, partial credit, or no credit)
- Bills must be in "Final" status before pushing to fee module
- Once pushed, corrections require a reversing entry and re-push
- Disputed bills are reviewed by warden/finance

---

## Workflow Steps

**Generating Bills**
Warden selects month/year, system calculates bill for each student based on attendance, leaves, opt-outs.

**Reviewing**
Warden reviews bills, applies manual adjustments if needed.

**Finalizing**
Bills are marked Final. Students/parents can view on portal.

**Pushing to Fee**
Final bills are pushed to the fee module for collection.

---

## Related Screens

- **Mess Attendance** (Tab 34) — Attendance data feeds bill calculation
- **Mess Opt Outs** (Tab 35) — Opt-outs generate credits
- **Leave Passes** (Tab 16) — Leave days generate credits
- **Fee Demands** (Tab 39) — Pushed bills appear as fee demands
