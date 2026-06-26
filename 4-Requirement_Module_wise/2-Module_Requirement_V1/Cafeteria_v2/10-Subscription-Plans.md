# Subscription Plans — Business Requirements

## What This Screen Does

The Subscription Plans screen defines meal packages the school offers — for example, "Full Day Meal Plan" (all meals), "Lunch Only Plan," or "Hostel Mess Plan." Each plan specifies which meal categories are included, the billing period (Monthly/Termly/Annual), and the price.

---

## When This Screen Is Used

- The school wants to offer different meal packages for the new academic year
- A new plan needs to be created (e.g., "Staff Lunch Plan")
- An existing plan's price or included categories need updating
- A plan is no longer offered and needs to be deactivated

---

## Key Fields at a Glance

**Plan Name**
Clear name — e.g., "Full Day Plan," "Hostel Mess Plan," "Staff Lunch Plan."

**Included Meal Categories**
Which meal categories are covered (multi-select from Menu Categories).

**Billing Period**
Monthly, Termly, or Annual.

**Price**
Plan price in INR (e.g., ₹2,500/month).

**Academic Term**
Optional — which term this plan applies to.

**Plan Type**
- General: Available for voluntary subscription by any student.
- Hostel: Auto-enrolls students on hostel allotment (cheapest active plan assigned).
- Staff: Available for staff members. Payroll deduction flag signals PAY module.
- Hostel and Staff are mutually exclusive.

**Status**
Active or Inactive.

---

## Business Rules and Conditions

**Hostel Plan Auto-Enrollment (BR-CAF-015)**
When a student is allotted a hostel bed, the cheapest active hostel plan is auto-assigned. Start date = allotment date. End date = academic term end.

**Staff Plan (BR-CAF-019)**
CAF never writes to PAY tables. `payroll_deduction_flag` on staff meal logs is a read-only signal.

**Plan Deletion Protection**
A plan with active enrollments cannot be deleted. All enrollments must be cancelled or expired first.

**Hostel/Staff Mutual Exclusivity**
A plan cannot be both hostel plan and staff plan.

---

## Workflow Steps

**Creating a Plan**
Enter name → select included meal categories → choose billing period → set price → optionally select academic term and plan type → submit.

**Editing a Plan**
Update any field. Changes apply to new enrollments only.

**Deactivating a Plan**
Plan becomes unavailable for new enrollments. Existing enrollments remain active.

---

## Example Scenario

School creates two plans:
1. **Full Day Meal Plan** — ₹2,500/month. Included: Breakfast, Lunch, Snacks. Billing: Monthly. Type: General.
2. **Hostel Mess Plan** — ₹4,000/month. Included: Breakfast, Lunch, Snacks, Dinner. Billing: Monthly. Type: Hostel.

When hostel student Ravi is allotted a bed, the Hostel Mess Plan is auto-assigned.

---

## Related Screens

- **Enrollments** — Student/staff enrollment in plans
- **Meal Cards** — Plan fees can be deducted from meal card
- **Weekly Menus** — Plans define which meal categories are covered
