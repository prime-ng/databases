# Movement Log — Business Requirements

## What This Screen Does

The Movement Log screen is a daily in/out register for all hostel students. Every time a student leaves the hostel premises (for any reason), their out-time is recorded. When they return, their in-time is recorded. This provides a complete audit trail of student movement for safety and security purposes.

---

## When This Screen Is Used

- Student goes out for a walk, sports, or personal errand
- Student leaves for a scheduled appointment
- Gate check: Recording every student exit and entry
- End-of-day review to identify students who haven't returned
- Parent inquiry: "When did my child leave and return?"

---

## Key Fields

- **Student** — Student who is moving
- **Date** — Movement date
- **Out Time** — When student left
- **Expected Return Time** — When student is expected back
- **In Time** — When student returned (nullable)
- **Destination** — Where student is going
- **Purpose** — Walk / Sports / Errand / Appointment / Other
- **Gate Pass Issuer** — Warden/guard who authorized
- **Overnight Flag** — Whether student is permitted to stay out overnight
- **Parent Consent** — Whether parent was informed
- **Overdue Notification** — Whether notification was sent for overdue return
- **Status** — Out / Returned / Overdue

---

## Business Rules

- Every exit must be logged before student leaves the premises
- Expected return time is mandatory for non-overnight movements
- If student hasn't returned within 30 minutes of expected return, status changes to "Overdue"
- Overdue returns trigger notification to warden and parent
- Overnight movements require warden approval + parent consent
- Students on approved leave pass are exempt from separate movement log entry
- Movement log is retained for minimum 1 year

---

## Workflow Steps

**Check-Out**
Student informs warden/guard, provides destination and purpose. Out time recorded, expected return set.

**Check-In**
Student returns, in time recorded. System shows if return was on time or late.

**Pending Returns**
End-of-day: Wardens review list of students still marked "Out". Follow up on overdue students.

---

## Related Screens

- **Leave Passes** (Tab 16) — Approved leave auto-creates movement entry
- **Pending Returns** (Tab 18) — Focused view of students not yet returned
- **Incidents** (Tab 27) — Repeated late returns can create incident records
