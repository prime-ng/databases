# Infrastructure Setup — Business Requirements Overview

## Module Purpose

The Infrastructure Setup module enables a school to define its physical infrastructure — buildings, room types, and individual rooms. This is the foundation module that answers the question: **"What physical spaces does the school have?"**

Think of this as a digital map of the school campus. Before the timetable can schedule classes, before events can be assigned venues, before any room booking can happen — the rooms must first be defined here.

---

## Who Uses This Module

| Role | Primary Activities |
|------|-------------------|
| Admin / Principal | Define buildings, approve room types, oversee infrastructure |
| Timetable Coordinator | Assign rooms for classes, exams, activities |
| Facilities Manager | Track room capacity, resources, availability |
| Academic Coordinator | Map class sections to rooms (class house rooms) |

---

## Module Screens (Tab-wise)

The entire Infra Setup is accessible through a single multi-tab interface at: `/school-setup/infrasetup`

| Tab | Screen | Purpose |
|-----|--------|---------|
| Room Type | Room Type Master | Define categories of rooms (Science Lab, Classroom, Sports Room) |
| Room Type Rooms | Room Type Rooms View | View all rooms under selected room types side-by-side |
| Building | Building Master | Register school buildings (wings, blocks) |
| Room | Room Master | Register individual rooms with capacity, capabilities, resources |

---

## Core Business Flow

```
School Campus
       ↓
Define Buildings (Junior Wing, Senior Wing, Admin Block, etc.)
       ↓
Define Room Types (Classroom, Science Lab, Computer Lab, Sports Room, etc.)
       ↓
Create Rooms (Assign each room to a Building + Room Type)
       ↓
Each Room gets: Code, Capacity, Max Limit, Resource Tags
       ↓
Room Capabilities (Can it host: Lecture? Practical? Exam? Activity? Sports?)
       ↓
Timetable & Other Modules Use These Rooms for Scheduling
```

---

## Coding Convention

### Building Code Format
- 2-digit numeric code (10–99)
- Example: `10` = Junior Wing, `11` = Senior Wing, `12` = Admin Block

### Room Code Format
- Format: `{Building_Code}{Floor_Letter}-{Class+Section}`
- Building: 2 digits (10–99)
- Floor: 1 letter (G=Ground, F=First, S=Second, T=Third, or A/B/C/D/E)
- Class+Section: 3 characters (e.g., 09A, 10A, 12B)
- Example: `11G-10A` = Senior Wing, Ground Floor, Class 10 Section A

### Room Type Code Format
- Short code like `SCI_LAB`, `BIO_LAB`, `CRI_GRD`, `TT_ROOM`, `BDM_CRT`
- Used for identification and filtering

---

## Document Index

| File | Screen | Description |
|------|--------|-------------|
| [01-Room-Type.md](./01-Room-Type.md) | Room Type | Room categories and classification |
| [02-Room-Type-Rooms.md](./02-Room-Type-Rooms.md) | Room Type Rooms | View rooms by room type (AJAX) |
| [03-Building.md](./03-Building.md) | Building | Building/wing registration |
| [04-Room.md](./04-Room.md) | Room | Individual room creation with capabilities |

---

## Key Dependencies Between Screens

- A **Building** must exist before a **Room** can be assigned to it
- A **Room Type** must exist before a **Room** can be assigned a type
- **Room Type Rooms** is a read-only view derived from Room + Room Type data
- **Rooms** with `class_house_room = 1` are used by Class Section mapping (subject-class-mapping)
- The **Timetable** module depends on rooms being defined here

---

## Data Tables Reference

| Table | Description |
|-------|-------------|
| `sch_buildings` | Building master — code, short_name, name |
| `sch_rooms_type` | Room type master — code, short_name, name, resources, class_house_room flag, room count |
| `sch_rooms` | Room master — building, room type, code, capacity, capabilities, availability date |
