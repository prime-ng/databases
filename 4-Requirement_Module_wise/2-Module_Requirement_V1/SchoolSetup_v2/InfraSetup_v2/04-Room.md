# Room — Business Requirements

## What This Screen Does

The Room screen is where the school registers each individual room on campus. Every classroom, laboratory, sports room, activity room, examination hall — every physical space that can be used for teaching, learning, or activities — is created here.

This is the most detailed screen in the Infrastructure Setup module. Each room gets:
- A unique code following the school's naming convention
- Assigned to a Building and a Room Type
- Capacity and resource information
- Capability flags (what the room can be used for)

---

## When This Screen Is Used

- A new room is built or renovated
- Admin needs to update room capacity or resources
- A room becomes unavailable (under renovation) and needs a future availability date
- Timetable coordinator needs to check room capabilities
- Admin wants to assign a room as a homeroom for a class section
- A room is being decommissioned

---

## Key Fields at a Glance

**Code**
A unique alphanumeric code following the school's convention. Format: `{Building_Code}{Floor_Letter}-{Class+Section}`. Example: `11G-10A` means Building 11 (Senior Wing), Ground Floor, for Class 10 Section A.

**Short Name**
A brief display name for the room. Example: "Senior Wing Ground Floor 10A".

**Full Name**
A detailed descriptive name for the room.

**Building (Dropdown)**
Which building this room is located in. Selected from the list of active buildings.

**Room Type (Dropdown)**
What type of room this is. Selected from the list of active room types.

**Capacity**
How many seats the room has. This is the normal seating capacity for lectures.

**Max Limit**
The absolute maximum number of people the room can hold. This could be higher than capacity if extra chairs are added.

**Resource Tags (Optional)**
A description of equipment available in the room. Examples: "Projector, Smart Board, AC, Lab Equipment". This helps teachers and timetable planners know what each room offers.

**Capability Flags (Yes/No Toggles)**
Each room can be marked for one or more uses:
| Flag | Label | Meaning |
|------|-------|---------|
| Can Host Lecture | L | Room has seats and writing surface for lectures |
| Can Host Practical | P | Room has seats, writing surface, and lab equipment |
| Can Host Exam | E | Room has seating suitable for exams |
| Can Host Activity | A | Open space suitable for co-curricular activities |
| Can Host Sports | S | Room/ground suitable for sports and PE |

A room can have multiple capabilities. For example, a room could be marked for both Lecture and Exam.

**Room Available From Date**
If the room is newly built or under renovation, this date shows when it becomes/will become available for use. If left blank, the room is available immediately.

**Status**
Each room can be Active (available for scheduling) or Inactive (temporarily unavailable).

---

## Business Rules and Conditions

**Unique Code**
Every room must have a unique code. No two rooms can share the same code.

**Unique Short Name**
Every room must have a unique short name.

**Building is Mandatory**
A room cannot be created without assigning it to a building.

**Room Type is Mandatory**
A room cannot be created without assigning it a room type.

**Room Count Auto-Update**
When a room is created, activated, deactivated, or deleted, the system automatically updates the room count for its room type.

**Soft Delete Protection**
A room cannot be permanently deleted if it is linked to other records (e.g., PTM events or class section assignments).

**Capability Display**
In the list view, capabilities are shown as badge letters: L (Lecture), P (Practical), E (Exam), A (Activity), S (Sports).

---

## What Shows in the List

| Column | Description |
|--------|-------------|
| Code | Unique room code |
| Short Name | Brief display name |
| Room Name | Full room name |
| Building | Which building the room is in |
| Room Type | What type of room it is |
| Capacity | Seating capacity |
| Available From | Date when room becomes/will become available |
| Capabilities | Badge icons: L, P, E, A, S |
| Status | Active/Inactive toggle |
| Action | View, Edit, Delete buttons |

---

## Workflow Steps

**Adding a New Room**
Admin clicks Add, selects Building from dropdown, selects Room Type from dropdown, enters Code (e.g., `11G-10A`), Short Name, Full Name, Capacity, Max Limit, optionally adds Resource Tags, toggles capability flags (Lecture, Practical, Exam, Activity, Sports), optionally sets Available From Date, and submits.

**Filtering Rooms**
Admin can filter rooms by:
- **Search** — by room name or code
- **Room Type** — dropdown to filter by room type
- **Status** — All / Active / Inactive

**Editing a Room**
Admin clicks Edit, modifies any field, and saves. If the room type is changed, the room count for both the old and new room type is automatically updated.

**Viewing a Room**
Admin clicks View to see full details including building name, room type, capabilities, and resources.

**Toggling Status**
Admin clicks the status switch to activate or deactivate a room.

**Deleting a Room**
Admin can soft-delete a room. It moves to the trash where it can be restored or permanently deleted.

---

## Example Scenario

A school is setting up for the new academic year. They create the following rooms:

**Room 1:** 
- Building: Senior Wing (Code: 11)
- Room Type: Standard Classroom
- Code: `11G-10A`
- Capacity: 40, Max Limit: 45
- Capabilities: Lecture ✅, Exam ✅
- Available: Immediately

**Room 2:**
- Building: Senior Wing (Code: 11)
- Room Type: Science Laboratory
- Code: `11F-SCI`
- Capacity: 30, Max Limit: 35
- Resources: "Microscopes, Bunsen burners, Sinks"
- Capabilities: Lecture ✅, Practical ✅, Exam ✅
- Available: From 01-Jul-2026 (lab is being refurbished)

When Room 2 is created, the Room Type "Science Laboratory" count automatically increments. Timetable planners can see both rooms and know that Room 2 is unavailable until July.

---

## Related Screens

- **Building** — Buildings must exist before rooms can be assigned
- **Room Type** — Room types must exist before rooms can be categorized
- **Room Type Rooms** — Quick view of rooms by type
- **Class Section Mapping** — Uses rooms with class_house_room flag for homeroom assignment
- **Timetable** — Uses room data for scheduling classes
