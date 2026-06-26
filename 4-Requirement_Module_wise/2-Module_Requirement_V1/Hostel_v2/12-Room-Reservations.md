# Room Reservations — Business Requirements

## What This Screen Does

The Room Reservations screen handles pre-allotment bookings during the admission process. Prospective students (who may not yet have a full student record) can reserve a bed in advance. Once the student is formally admitted, the reservation converts to a regular allotment.

---

## When This Screen Is Used

- During admission season to pre-book rooms for incoming students
- When a student wants to guarantee accommodation before fees are paid
- To manage reservation expiry and cancellation
- To track deposit amounts paid for reservation

---

## Key Fields

- **Student/Applicant** — Linked to student or applicant record
- **Hostel** — Preferred hostel
- **Room** — Preferred room (optional)
- **Bed** — Preferred bed (optional)
- **Reservation Date** — When the reservation was made
- **Expiry Date** — When the reservation expires
- **Deposit Amount** — Advance deposit paid (if any)
- **Purpose** — New Admission / Transfer / Temporary
- **Status** — Pending / Confirmed / Cancelled / Expired
- **Converted to Allotment** — Link to allotment once confirmed

---

## Business Rules

- A student can have only one active reservation
- Reservations auto-expire after the configured validity period
- Expired reservations can be renewed
- Converting a reservation to allotment uses the allotted bed (or auto-assigns if no bed was selected)
- Cancelling a reservation triggers deposit refund workflow (if applicable)
- Reservation holds the bed — bed is shown as "Reserved" during the validity period

---

## Related Screens

- **Room Allotments** (Tab 11) — Reservations convert to allotments
- **Beds** (Tab 08) — Bed status shows "Reserved" during reservation
