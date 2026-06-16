# PTM Scheduling System: Requirements and Schema

This document outlines the comprehensive requirements, business logic, and database schema for a Parent-Teacher Meeting (PTM) scheduling module capable of handling different dates, time slots, and teacher-defined batches across various classes and sections.

---

## 1. Core Functional Requirements
To ensure the system is flexible enough for a school environment, the following logic must be supported:

* **Granular Scheduling:** Each Class + Section can have its own unique date and time range.
* **Teacher Batches:** Teachers can define reusable time "Batches". Below are the examples  : 
  - 2 Hours slot for for 12 Student Starting from 9 AM to 11 AM (10 Min. for each Student) and apply them to specific classes + Section.
  - 10 Min. Slot for every Student of every Class+Section
* **Conflict Resolution:** The system must prevent a teacher from being scheduled for two different meetings at the same time, even if they occur in different classes+section.
* **Break/Buffer Support:** Ability to mark specific intervals as "Break" (unbookable) and include "Buffer" times between slots.

---

## 2. Slot Allocation System
2 Type of slot allocation should be supported by the system : 
* **Allocated by School:** School can allocate Slot (Either 1-on-1 meetings for every student OR "Group Slot" (participants > 1 for a single Slot))
* **Picked by Parents:** Teacher will create Slot and make those available for Parents to choose as per their preference. Parents/Students can claim available slots on a first-come, first-served basis from the Slots provided to them.

### Booking & Deadlines
1.  **Limit per Student:** One student/parent can book exactly one slot per teacher per event.
2.  **Booking Window:** Define start and end dates for when the booking portal is open to parents.
3.  **Cancellation Policy:** Prevent cancellations within a specified timeframe (e.g., 24 hours before the meet).

---

## 3. Business Rules & Conditions
The following conditions must be enforced within the system logic:

### Teacher & Staff Constraints
1.  **No Double-Booking:** A teacher's availability is a global constraint across all assigned classes.
2.  **Ownership:** Only assigned class/subject teachers or administrators can modify a class schedule.
3.  **Mandatory Breaks:** System must allow "Block-out" periods for lunch or staff meetings.
4.  **Buffer Times:** School may enforce a 2–5 minute gap between slots to allow for parent rotation.
5.  **Teacher Allocation:** Default allocation will be the Class Teacher of the Class+Section. But Any other Teacher alos can be assigned if required.
6.  **Multi Teacher Assignment:** School may devide Class+Section into multipal Bathces and assign all those bathc same timeslot with different techers.

### Batch & Slot Logic
1.  **Template Reusability:** Teachers can create one batch template and apply it to multiple sections (e.g., 10A, 10B, 10C).
2.  **Slot Capacity:** Support both 1-on-1 meetings and "Group Slot" (participants > 1 for a single Slot).
3.  **Dynamic Duration:** Different grade levels can have different meeting durations (e.g., Primary: 15 mins, Secondary: 10 mins).
4.  **Global Fallback Defaults:** If Slot Duration, Buffer Gap, or Max Participants are not specified on the Batch Template or Assignment level, the system must automatically fallback to the defaults defined at the parent PTM Event level (`default_slot_duration_min`, `default_buffer_min`, `default_max_participants`).

---


