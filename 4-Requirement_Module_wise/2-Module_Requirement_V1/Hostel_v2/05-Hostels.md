# Hostels — Business Requirements

## What This Screen Does

The Hostels screen registers and manages the hostel buildings themselves. Each hostel record represents a physical building with its own name, code, gender allocation, capacity, address, and facilities. This is the top-level entity in the hostel hierarchy (Hostel → Floor → Room → Bed).

---

## When This Screen Is Used

- Setting up a new hostel building
- Updating hostel contact information or facilities
- Viewing hostel capacity and current occupancy
- Deactivating a hostel that is temporarily or permanently closed

---

## Key Fields

- **Name** — Hostel building name (e.g., "Boys Hostel A", "Girls Hostel B")
- **Code** — Short code for identification (e.g., "BHA", "GHB")
- **Gender Type** — Boys / Girls / Co-educational
- **Total Capacity** — Maximum number of students
- **Current Occupancy** — Auto-calculated from active allotments
- **Address** — Building address with city, state, pincode
- **Contact Number** — Main hostel office phone
- **Warden Name** — Primary warden assigned
- **Facilities** — JSON list of available amenities (WiFi, AC, Hot Water, Laundry, Gym, etc.)
- **Description** — Additional notes about the hostel
- **Status** — Active / Inactive

---

## Business Rules

- Hostel name must be unique within a tenant
- A hostel cannot be deleted if it has active floors, rooms, beds, or allotments
- Gender type can restrict which students can be allotted (e.g., Boys hostel only allots male students)
- Occupancy is auto-calculated from active allotments (cannot be manually entered)
- Facilities are stored as JSON key-value pairs for flexibility (no separate table needed)
- Warden is linked via Warden Assignments (Tab 10), not stored directly on hostel

---

## Workflow Steps

**Adding a Hostel**
Admin opens Add Hostel form, enters building details, sets gender type, specifies capacity, provides address and contact, selects available facilities, and submits.

**Viewing Hostel List**
The hostel list shows all buildings with name, code, gender type, total capacity, current occupancy, and status.

**Editing a Hostel**
Admin can update contact details, address, facilities, or capacity. Changes are immediate.

**Deactivating a Hostel**
Toggle status to Inactive. Active floors/rooms/beds remain but no new allotments can be made.

---

## Related Screens

- **Floors** (Tab 06) — Floors belong to a hostel
- **Warden Assignments** (Tab 10) — Wardens are assigned per hostel
- **Room Allotments** (Tab 11) — Allotments reference the hostel via room/bed hierarchy
