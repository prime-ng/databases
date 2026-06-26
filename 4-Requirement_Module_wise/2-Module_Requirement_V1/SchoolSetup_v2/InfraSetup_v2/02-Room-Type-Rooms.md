# Room Type Rooms — Business Requirements

## What This Screen Does

The Room Type Rooms screen provides a quick, visual way to see **which rooms exist under which room types**. It is a read-only view that shows room types on the left side and their corresponding rooms on the right side.

Think of this as a "Browse by Category" view — select one or more room types, and instantly see all rooms that belong to those types.

---

## When This Screen Is Used

- Admin wants to see all Science Labs across the campus
- Timetable coordinator wants to check what rooms are available under "Computer Lab" type
- Facilities manager wants to audit rooms by category
- Admin needs a quick overview of room distribution by type

---

## How the Screen Works

The screen is divided into two panels:

**Left Panel — Room Types List**
A scrollable table showing all room types with checkboxes. Admin can select one or more room types by checking the boxes. A "Select All" checkbox at the top allows selecting all types at once.

**Right Panel — Rooms List**
A scrollable table that shows all rooms belonging to the selected room type(s). The list updates in real-time when room type selections change.

---

## What Shows in the Rooms List

| Column | Description |
|--------|-------------|
| Code | Unique room code |
| Name | Room name |
| Building | Which building this room is in |
| Capacity | Seating capacity |
| Room Available From Date | When this room becomes/became available |
| Can Host Lecture (L) | Suitable for lecture-style classes |
| Can Host Practical (P) | Suitable for practical/lab work |
| Can Host Exam (E) | Suitable for conducting exams |
| Can Host Activity (A) | Suitable for co-curricular activities |
| Can Host Sports (S) | Suitable for sports/PE |
| Allocated Classes | Count of class sections assigned to this room |

Below the table, a badge shows the **Total** count of rooms currently displayed.

---

## Business Rules

**Read-Only View**
This screen is for viewing only. To add, edit, or delete rooms, admin must go to the Room tab.

**Real-Time Filtering**
When admin checks/unchecks room types, the rooms list updates immediately without page reload (AJAX).

**Only Active Rooms Shown**
Inactive rooms are not displayed in this view.

---

## Example Scenario

The admin selects "Science Lab" and "Computer Lab" from the left panel. The right panel instantly shows:
- Science Lab 1 (Senior Wing, Capacity 30, Available from 01-Apr-2026)
- Science Lab 2 (Junior Wing, Capacity 25, Available from 01-Apr-2026)
- Computer Lab 1 (Admin Block, Capacity 40, Available from 15-Mar-2026)

The admin can quickly see which buildings have these rooms and their current allocation status.

---

## Related Screens

- **Room Type** — Define the room types shown on the left panel
- **Room** — Create and manage the individual rooms shown on the right panel
- **Building** — Buildings that rooms belong to
