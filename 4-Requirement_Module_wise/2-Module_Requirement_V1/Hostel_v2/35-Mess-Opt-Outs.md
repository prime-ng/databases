# Mess Opt Outs — Business Requirements

## What This Screen Does

The Mess Opt Outs screen allows students to temporarily or permanently opt out of specific meals in the mess. Students can opt out for a date range (e.g., going home for the weekend), for specific meals (e.g., skip dinner every Tuesday), or on a recurring basis. Opt-outs affect mess attendance marking and bill calculation.

---

## When This Screen Is Used

- Student is going home for the weekend and won't need meals
- Student has a medical reason to skip certain meals
- Student wants to opt out of mess temporarily (e.g., fasting)
- Recurring pattern: Student is always absent for Sunday lunch
- Reviewing and approving opt-out requests

---

## Key Fields

- **Student** — Student opting out
- **Date Range** — From date to to date
- **Meals** — Which meals to opt out of (Breakfast / Lunch / Snacks / Dinner / All)
- **Recurring** — Whether this is a recurring pattern (Daily / Weekly / Weekdays Only / Weekends Only / Custom)
- **Reason** — Why opting out
- **Approved By** — Warden who approved
- **Mess Bill Credit** — Whether this opt-out reduces the mess bill
- **Status** — Pending / Approved / Rejected / Expired

---

## Business Rules

- Opt-outs can be applied to specific meals or all meals
- Recurring opt-outs auto-apply to future dates until cancelled
- Opt-outs longer than 7 consecutive days require warden approval
- Student must have an active hostel allotment
- Approved opt-outs automatically reflect in mess attendance
- Mess bill credit depends on the duration and meal type
- Emergency opt-outs (medical) are fast-tracked

---

## Related Screens

- **Mess Attendance** (Tab 34) — Opt-outs auto-update attendance
- **Mess Bills** (Tab 37) — Opt-outs affect bill calculation
- **Special Diets** (Tab 36) — Dietary opt-outs (not meals, but food choices)
