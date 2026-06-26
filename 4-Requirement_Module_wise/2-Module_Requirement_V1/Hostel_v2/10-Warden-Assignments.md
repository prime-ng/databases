# Warden Assignments — Business Requirements

## What This Screen Does

The Warden Assignments screen manages staff assignments to hostel roles. Wardens can be assigned at the hostel level (Chief Warden, Block Warden) or floor level (Floor Warden, Assistant Warden). The assignment includes effective dates to track historical assignments.

---

## When This Screen Is Used

- At the start of each academic year to assign wardens
- When a warden is transferred or resigns
- To view past warden assignments for a hostel
- To end a warden's assignment before the effective end date

---

## Key Fields

- **Hostel** — Which hostel (dropdown)
- **Floor** — Optional: which floor (empty for hostel-level roles)
- **Staff/Employee** — Warden employee selected from employee records
- **Role** — Chief Warden / Block Warden / Floor Warden / Assistant Warden / Night Warden
- **Effective From** — Assignment start date
- **Effective To** — Assignment end date (nullable for open-ended)
- **Is Primary** — Whether this is the primary warden for the hostel
- **Notes** — Assignment notes
- **Status** — Active / Ended

---

## Business Rules

- A hostel must have at least one active warden at all times
- Multiple wardens can be assigned per hostel with different roles
- Floor-level warden assignment takes precedence over hostel-level for that floor
- When a warden assignment ends, all related permissions for that warden are revoked
- Previous assignments are kept for historical audit
- Active wardens appear in the Warden Duty Roster (Tab 19) dropdown

---

## Related Screens

- **Hostels** (Tab 05) — Wardens are assigned per hostel
- **Floors** (Tab 06) — Floor-level warden assignments
- **Warden Duty Roster** (Tab 19) — Wardens appear in duty scheduling
