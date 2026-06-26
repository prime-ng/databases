# Housekeeping — Business Requirements

## What This Screen Does

The Housekeeping screen tracks daily cleaning and maintenance service logs for rooms and common areas. Each cleaning session records which areas were cleaned, by whom, quality rating, and any issues found. This ensures accountability and consistent cleanliness standards across the hostel.

---

## When This Screen Is Used

- Daily room cleaning by housekeeping staff
- Common area cleaning (corridors, lobby, stairs, bathrooms)
- Deep cleaning or special cleaning requests
- Quality inspection by warden
- Monthly housekeeping performance review

---

## Key Fields

- **Room / Area** — Which room or common area was cleaned
- **Service Type** — Daily Cleaning / Deep Clean / Bathroom Clean / Linen Change / Common Area / Other
- **Cleaning Staff** — Staff member who performed cleaning
- **Cleaning Date** — Date of service
- **Time** — Time of cleaning
- **Quality Rating** — 1-5 star rating (can be given by warden during inspection)
- **Issues Found** — Any cleanliness issues or missing items
- **Re-cleaning Required** — Flag if cleaning was unsatisfactory
- **Verified By** — Warden who inspected (nullable)
- **Photo Evidence** — Before/after photos (optional)
- **Status** — Completed / Verified / Re-cleaning Required

---

## Business Rules

- Each room should have at least one daily cleaning entry
- Common areas are cleaned on schedule (configurable frequency)
- Quality rating below 3 requires re-cleaning
- Re-cleaning must be completed within 4 hours
- Housekeeping records are retained for minimum 3 months
- Staff can mark completion; only warden can verify
- Linen change schedule is tracked separately (weekly/bi-weekly configurable)

---

## Related Screens

- **Rooms** (Tab 07) — Housekeeping per room
- **Laundry Tickets** (Tab 23) — Linen change linked to laundry service
