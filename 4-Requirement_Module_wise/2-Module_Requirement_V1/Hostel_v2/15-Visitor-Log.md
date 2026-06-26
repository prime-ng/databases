# Visitor Log — Business Requirements

## What This Screen Does

The Visitor Log screen is a digital visitor register that replaces the traditional paper register at the hostel gate. Every visitor — parent, relative, guest, vendor, service provider — must be logged with their details, visit time, purpose, and checkout time. Visitor photos and ID proofs can be attached for security.

---

## When This Screen Is Used

- A parent or relative comes to visit a student
- A service provider (plumber, electrician) enters the hostel
- A delivery person drops off items
- Any unknown person needs to be registered at the gate
- Security review of past visitors

---

## Key Fields

- **Visitor Name** — Full name of the visitor
- **Relationship** — Parent / Guardian / Relative / Friend / Vendor / Other
- **Phone Number** — Contact number
- **ID Proof Type & Number** — Aadhaar, Driver's License, etc.
- **Student to Visit** — Which student (if applicable)
- **Purpose** — Reason for visit
- **In Time** — When they entered
- **Out Time** — When they left (nullable, filled on checkout)
- **Outside Hours Override** — Flag if visit is outside permitted hours
- **Remarks** — Any security notes
- **Visitor Photo** — Photo capture for identification
- **ID Proof Document** — Upload scan of ID
- **Status** — Checked In / Checked Out

---

## Business Rules

- Every visitor must show valid ID proof before entry
- Outside-hours visits require warden approval (override flag)
- Visitors cannot be checked out without recording out time
- Visitor photo is mandatory for security purposes
- Student to visit can be left blank for non-student visits (vendors, etc.)
- Visitor log is retained for minimum 6 months (or as per local regulations)
- Reports available for security audit

---

## Workflow Steps

**Check-In**
Guard/warden enters visitor name, contact, ID proof, selects student (optional), captures photo, records in time. Visitor badge can be printed (optional).

**Check-Out**
Visitor returns to gate, guard records out time. If visitor didn't check out within reasonable hours, alert is shown.

**Viewing Logs**
Search by visitor name, date, student name, or purpose. Export for security audits.

---

## Related Screens

- **Leave Passes** (Tab 16) — Visitors related to student leave
- **Sick Bay** (Tab 30) — Parent visits for sick students
