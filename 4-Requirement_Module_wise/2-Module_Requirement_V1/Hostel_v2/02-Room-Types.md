# Room Types — Business Requirements

## What This Screen Does

The Room Types screen is the master configuration where the school defines all categories of rooms available in the hostel. Common examples include Single Room, Double Room, Triple Sharing, Dormitory, VIP Room, and Cottage. This classification drives room configuration, pricing in fee structures, and occupancy reporting.

---

## When This Screen Is Used

- During initial hostel setup to define available room categories
- When a new type of accommodation is introduced
- To update room type names or descriptions
- To deactivate a room type that is no longer available

---

## Key Fields

- **Name** — Display name (e.g., "Single Room", "Double Sharing", "Dormitory")
- **Description** — Brief explanation of the room type
- **Default Capacity** — Standard number of beds for this type
- **Status** — Active / Inactive

---

## Business Rules

- Room type name must be unique within a tenant
- Deactivating a room type does not affect existing rooms using that type
- Only active room types appear in room creation dropdowns
- Room type can be soft-deleted only if no rooms are currently assigned to it

---

## Related Screens

- **Rooms** (Tab 07) — Room type is a dropdown selection when creating/editing rooms
- **Fee Structures** (Tab 38) — Fee rates can be configured per room type
