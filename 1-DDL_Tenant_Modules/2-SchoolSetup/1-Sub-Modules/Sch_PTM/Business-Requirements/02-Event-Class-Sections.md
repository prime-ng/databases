# Event Class Sections — Business Requirements

## What This Screen Does

This screen is used to decide which classes and sections will participate in a PTM event and on which specific dates and times. Not all classes necessarily have their PTM on the same day — for example, Class 10-A may have PTM on Monday while 10-B has it on Tuesday. This screen handles that flexibility.

Each class section added to an event gets its own scheduled date, time range, meeting mode, and room assignment. Think of this as the "class-wise schedule" for the PTM event.

---

## When This Screen Is Used

- Right after creating a PTM event, admin needs to add participating classes
- Classes need different dates — 10-A on 10 May, 10-B on 11 May
- A class needs its room changed or its online meeting link updated
- A particular class should not participate in this PTM event and needs to be removed

---

## Business Rules and Conditions

**One Class Per Event Only**
A specific class and section combination can be added to a single event only once. You cannot add 10-A twice in the same event. If a class needs to meet on two different days, the current design does not support it — instead, the class would need to split into sub-batches with different teachers.

**Date Must Fall Within Event Range**
The scheduled date for a class must be within the event's start and end dates. If the event runs from 10 May to 15 May, no class can be scheduled on 20 May. This ensures all PTM activities happen within the declared event period.

**Time Range Validation**
The day start time must be before the day end time. For example, 9 AM to 1 PM is valid, but 1 PM to 9 AM is not. The total available time must be enough to accommodate at least a few slots based on the default slot duration.

**Meeting Mode Inheritance**
If a class does not specify its own meeting mode, the event's default mode applies. If the mode is In-Person, a room should be assigned. If the mode is Online, a virtual meeting link should be provided. In Hybrid mode, both can be provided.

**Duration Check**
The time between start and end should be sufficient to generate a meaningful number of slots. For example, if the slot duration is 10 minutes with 2 minutes buffer, each slot effectively takes 12 minutes. A 2-hour window from 9 AM to 11 AM can accommodate 10 such slots. Admin should be alerted if the available time is too short.

---

## Workflow Steps

**Adding a Class to Event**
Admin selects the PTM event, picks a class-section from the dropdown, sets the scheduled date, defines the start and end time, optionally selects a room or provides a virtual link, adds any notes, and submits. The class is now registered for the event.

**Viewing Registered Classes**
A list shows all classes added to the event with their dates, time ranges, meeting modes, and room assignments. Admin can quickly see which classes are ready and which still need configuration.

**Modifying Class Schedule**
Admin can change the date, time, room, or link for any class. However, if bookings already exist for this class, changing the date or time may affect parents who have already booked slots. The system should warn about this.

**Removing a Class**
Admin can remove a class from the event. This is restricted if the class already has assignments with published slots and active bookings. The system should prompt admin to handle those bookings first.

---

## Example Scenario

For the Term 1 PTM event (10 May to 15 May 2026), admin adds the following classes:

- 10-A on 10 May 2026 from 9 AM to 1 PM in Room 101 (In-Person)
- 10-B on 11 May 2026 from 9 AM to 1 PM in Room 102 (In-Person)
- 5-A on 12 May 2026 from 2 PM to 5 PM with a Zoom link (Online)
- 12-A on 13 May 2026 from 10 AM to 2 PM in Hall A (Hybrid)

Each class operates independently on its own day with its own time window. The next step is to assign teachers and batch templates to each of these class sections.
