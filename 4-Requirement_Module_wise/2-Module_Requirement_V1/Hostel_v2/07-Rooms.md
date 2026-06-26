# Rooms — Business Requirements

## What This Screen Does

The Rooms screen manages individual rooms within a floor. Each room has a room number, room type (single/double/triple/dormitory), capacity, amenities, and current status. Rooms are the third level in the hostel hierarchy (Hostel → Floor → Room → Bed).

---

## When This Screen Is Used

- During hostel setup to define all rooms
- When room configuration changes (capacity change, type change)
- To update room amenities or accessibility features
- To mark a room for maintenance

---

## Key Fields

- **Hostel** — Auto-filled from floor selection
- **Floor** — Which floor the room is on
- **Room Number** — Unique room identifier (e.g., "101", "A-201")
- **Block / Wing** — Auto-filled from floor's block code
- **Room Type** — Dropdown from Room Types (Tab 02)
- **Capacity** — Maximum number of beds/students
- **Current Occupancy** — Auto-calculated from active beds/allotments
- **Windows Facing** — Direction (North, South, East, West, Corner)
- **Amenities** — Room-specific facilities JSON
- **Accessibility Features** — Wheelchair accessible, ground floor, etc.
- **Status** — Available / Occupied / Under Maintenance (from Status Masters)

---

## Business Rules

- Room number must be unique within a floor
- Capacity can be increased/decreased but cannot be less than current active bed count
- Room type change is allowed only if new type supports at least the current bed count
- A room can be deleted only if all beds are deleted first
- Room status is auto-updated based on bed occupancy

---

## Related Screens

- **Floors** (Tab 06) — Parent entity
- **Room Types** (Tab 02) — Room type classification
- **Beds** (Tab 08) — Beds within the room
- **Room Inventory** (Tab 20) — Inventory items in the room
