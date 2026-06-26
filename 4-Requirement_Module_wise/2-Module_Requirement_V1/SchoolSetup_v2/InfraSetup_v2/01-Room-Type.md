# Room Type — Business Requirements

## What This Screen Does

The Room Type screen is where the school defines what *kinds* of rooms exist on campus. A Room Type is a category or classification — for example, "Science Lab", "Computer Lab", "Classroom", "Sports Room", "Library", "Music Room", etc.

Think of this as creating a catalogue of room categories. Later, when individual rooms are created, each room will be assigned one of these types.

---

## When This Screen Is Used

- A new type of room is needed (e.g., school builds a new "Robotics Lab")
- Admin wants to update room type details (name, code, required resources)
- A room type is no longer needed and should be deactivated
- Admin wants to track how many rooms exist under each room type
- School wants to mark certain room types as "Class House Rooms" (used as homerooms for class sections)

---

## Key Fields at a Glance

**Code**
A short, unique identifier for the room type. Examples: `SCI_LAB`, `BIO_LAB`, `CRI_GRD`, `TT_ROOM`, `BDM_CRT`. This code is used for quick identification and filtering.

**Short Name**
A brief display name for the room type. Example: "Science Lab", "Biology Lab", "Cricket Ground".

**Full Name**
A detailed, descriptive name for the room type.

**Required Resources (Optional)**
A text field describing what equipment or resources this type of room needs. Example: "Microscopes, Lab Coats, Safety Goggles" for a Science Lab. This helps the facilities team know what each room type should contain.

**Class House Room (Yes/No)**
A flag that marks whether this room type can be used as a homeroom for a class section. If set to Yes, rooms of this type can be assigned to class sections as their permanent room. Example: "Classroom" would be Yes, "Science Lab" would be No.

**Room Count (Auto-calculated)**
The system automatically counts how many active rooms exist under this room type. This number is updated whenever a room is created, deleted, or its status changes. Admin can also manually trigger a recalculation.

**Status**
Each room type can be Active (available for use) or Inactive (temporarily disabled).

---

## Business Rules and Conditions

**Unique Code**
Every room type must have a unique code. No two room types can share the same code.

**Unique Short Name**
Every room type must have a unique short name. This prevents duplicate-looking entries.

**Room Count Auto-Sync**
When a room belonging to this type is created, activated, deactivated, or deleted, the room count for this room type is automatically updated. This ensures the count is always accurate.

**Manual Count Recalculation**
An admin can trigger a full recalculation of all room type counts at any time using the "Update Room Type Counts" button. This is useful if counts ever get out of sync.

**Soft Delete Protection**
A room type cannot be permanently deleted if there are active rooms linked to it. The system will show an error message if the admin tries to force delete a room type that still has rooms.

---

## What Shows in the List

| Column | Description |
|--------|-------------|
| Sr. No | Row number |
| Code | Unique room type code |
| Short Name | Brief display name |
| Room Type Name | Full descriptive name |
| Room Total | Auto-calculated count of active rooms of this type |
| Status | Active/Inactive toggle |
| Action | View, Edit, Delete buttons |

---

## Workflow Steps

**Adding a New Room Type**
Admin clicks Add, fills in Code, Short Name, Full Name, optionally adds Required Resources, marks whether it's a Class House Room, and submits. The new room type appears in the list with Room Count = 0.

**Editing a Room Type**
Admin clicks Edit on any room type, modifies fields, and saves. Changes are logged in the activity log.

**Viewing a Room Type**
Admin clicks View to see full details of a room type.

**Toggling Status**
Admin clicks the status switch to activate or deactivate a room type. Inactive room types cannot be selected when creating new rooms.

**Deleting a Room Type**
Admin can soft-delete a room type. It moves to the trash where it can be restored or permanently deleted (if no rooms are linked).

---

## Example Scenario

A school wants to set up the following room types:
- **Code:** `CLASSRM`, **Name:** "Standard Classroom", **Class House Room:** Yes
- **Code:** `SCI_LAB`, **Name:** "Science Laboratory", **Resources:** "Microscopes, Bunsen burners, Safety goggles", **Class House Room:** No
- **Code:** `COMP_LAB`, **Name:** "Computer Laboratory", **Resources:** "40 Desktop computers, Projector", **Class House Room:** No
- **Code:** `PLAY_GRD`, **Name:** "Playground", **Class House Room:** No

After creating these, the admin can proceed to create individual rooms under each type.

---

## Related Screens

- **Room** — Each room must be assigned a room type
- **Room Type Rooms** — View all rooms grouped by room type
- **Class Section Mapping** — Uses room types marked as Class House Room
