# Mess Attendance — Business Requirements

## What This Screen Does

The Mess Attendance screen tracks per-meal attendance for hostel students. Each meal (breakfast, lunch, snacks, dinner) records which students are present. This data is critical for mess bill calculation — students are billed only for meals they actually consume (after accounting for opt-outs and leaves).

---

## When This Screen Is Used

- At each meal time to mark who is eating
- End-of-month: verifying attendance for bill generation
- Reviewing meal consumption patterns
- Identifying students who consistently skip meals

---

## Key Fields

- **Date** — Meal date
- **Meal Type** — Breakfast / Lunch / Snacks / Dinner
- **Student** — Student marked
- **Status** — Present / Absent / Leave (auto-tagged) / Opted Out
- **Special Diet Served** — Whether special diet was provided
- **Marked By** — Mess staff who recorded
- **Marked At** — Timestamp

---

## Business Rules

- Attendance can be marked per-meal or in bulk for all meals of the day
- Students on approved leave are auto-marked as "Leave"
- Students with active opt-outs are auto-marked as "Opted Out"
- Absent students are those who are present in the hostel but did not come for the meal
- Mess attendance directly impacts mess bill calculation
- Attendance is locked after meal time + 1 hour (configurable)
- Reports available for monthly billing

---

## Workflow Steps

**Marking Attendance**
Mess staff selects meal type, marks students as present/absent. Students on leave or opt-out are auto-handled.

**Verifying**
Warden can review attendance before locking. Corrections allowed before lock.

**Billing**
End of month, attendance data feeds into mess bill calculation.

---

## Related Screens

- **Mess Bills** (Tab 37) — Attendance feeds monthly bill calculation
- **Mess Opt Outs** (Tab 35) — Opt-out status affects attendance
- **Leave Passes** (Tab 16) — Leave status auto-updates attendance
