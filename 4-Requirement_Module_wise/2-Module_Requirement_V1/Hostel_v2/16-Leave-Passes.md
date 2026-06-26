# Leave Passes — Business Requirements

## What This Screen Does

The Leave Passes screen manages the complete leave application workflow for hostel students. Students apply for leave (home, medical, festival, etc.), parents/wardens approve, and the system tracks the actual departure and return. Late returns are flagged for disciplinary follow-up.

---

## When This Screen Is Used

- Student wants to go home for the weekend or holidays
- Student needs medical leave or a doctor's appointment
- Student requests leave for a family function or festival
- Warden needs to approve or reject pending leave requests
- Security checks at the gate: verify student has valid leave pass
- Tracking late returns and follow-up actions

---

## Key Fields

- **Student** — Student applying for leave
- **Leave Type** — Home / Medical / Festival / Emergency / Other
- **From Date & Time** — When leave starts
- **To Date & Time** — When leave ends
- **Destination** — Where the student is going
- **Reason** — Why leave is needed
- **Guardian Contact** — Parent/guardian phone for verification
- **Parent Consent** — Whether parent has been informed/consented
- **Approved By** — Warden who approved
- **Actual Departure** — When student actually left (recorded at gate)
- **Actual Return** — When student actually returned (recorded at gate)
- **Late Return Remarks** — Reason if returned late
- **Linked Incident** — Creates incident if late return is repeated
- **Status** — Pending / Approved / Rejected / Cancelled / Active / Returned / Overdue

---

## Business Rules

- Student must have active allotment to apply for leave
- Parent consent must be recorded for leave (verbal or written)
- Leave cannot overlap with an existing approved leave
- Maximum consecutive leave days configurable per hostel
- If student hasn't returned by end of leave + grace period, status becomes "Overdue"
- Overdue leaves trigger notification to warden and parent
- Leave passes are printable (for gate display)
- Recurring leave patterns (e.g., every Sunday) can be set up
- Actual departure and return are recorded at the gate (not auto-filled from dates)

---

## Workflow Steps

**Applying for Leave**
Student (or warden on behalf) fills leave type, dates, destination, reason, guardian contact. Submits for approval.

**Approving Leave**
Warden reviews, checks parent consent, approves or rejects. Approved leave generates a printable pass.

**Gate Check-Out**
Student presents leave pass at gate. Guard records actual departure time.

**Gate Check-In**
Student returns. Guard records actual return time. If late, remarks are noted.

**Overdue Follow-Up**
System alerts warden of overdue students. Warden contacts parent. Repeated overdue can create an incident record.

---

## Related Screens

- **Movement Log** (Tab 17) — Auto-linked when student checks out for leave
- **Incidents** (Tab 27) — Repeated late returns create incident records
- **Visitor Log** (Tab 15) — Parent visits may be related to leave
