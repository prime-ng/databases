# Incident Warnings — Business Requirements

## What This Screen Does

The Incident Warnings screen manages the formal warning letter process for hostel incidents. When a student commits a rule violation, a warning letter can be issued at various levels (Verbal → Written → Final → Suspension → Expulsion). Each warning is documented, digitally stored, and acknowledged by parents.

---

## When This Screen Is Used

- Issuing a formal warning to a student after an incident
- Tracking warning progression for repeat offenders
- Printing warning letters for parent signature
- Recording parent acknowledgment of warnings

---

## Key Fields

- **Student** — Student receiving the warning
- **Linked Incident** — Which incident triggered the warning
- **Warning Level** — Verbal / Written / Final / Suspension / Expulsion
- **Letter Template** — Template used for the letter
- **Rendered Letter** — Final letter content (stored as text or PDF)
- **Issued By** — Warden who issued
- **Issue Date** — When issued
- **Signer** — Higher authority who signed (if required)
- **Delivery Method** — In-Person / Email / Post / Courier
- **Parent Acknowledged** — Whether parent acknowledged receipt
- **Acknowledgment Date** — When parent acknowledged
- **Status** — Draft / Issued / Acknowledged / Expired

---

## Business Rules

- Warning levels are progressive: Verbal → Written → Final → Suspension → Expulsion
- A warning cannot skip levels (e.g., cannot go directly to Final without Written first)
- Suspension and Expulsion warnings require admin/principal approval
- Parent acknowledgment is mandatory for Written level and above
- Unacknowledged warnings are followed up after 7 days
- Warning history is retained permanently

---

## Related Screens

- **Incidents** (Tab 27) — Source incident
- **Incident Types** (Tab 28) — Warning letter templates per type
