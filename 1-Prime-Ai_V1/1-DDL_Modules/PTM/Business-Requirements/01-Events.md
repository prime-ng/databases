# Events — Business Requirements

## What This Screen Does

The Events screen is the starting point of the entire PTM scheduling system. School admin or principal uses this screen to create a new PTM event, configure its basic settings, and manage all related activities under it. Every event acts as a container — classes, teachers, time slots, and parent bookings all belong to a specific event.

This screen essentially defines the "what, when, and how" of a PTM. Without an event, nothing else in the PTM module can function.

---

## When This Screen Is Used

- School wants to conduct a Term 1 PTM and needs to create a new event for it
- Admin needs to set up separate events for different purposes like Annual PTM, Mid-Term PTM, or Class-Specific Open House
- School wants to change the dates, booking window, or slot defaults of an already created event
- Admin needs to enable or disable an event so it becomes visible or hidden from parents

---

## Key Fields at a Glance

Every event needs a unique code (like PTM-T1-2526) and a title to identify it. The academic session and term link the event to the school calendar. The event has a start date and an end date — these define the overall period during which all PTM activities for this event will happen.

The default meeting mode can be set as In-Person, Online, or Hybrid. This default can later be changed at the class level if needed.

Booking window settings control when parents can start booking slots and when the booking closes. A cancellation lead time (in hours) defines how close to the meeting time a parent can still cancel their booking.

Default slot duration, buffer time between slots, and maximum participants per slot act as global fallback values. These apply only when not overridden at the batch template or assignment level.

Notification flags let the school decide whether parents should receive SMS or email alerts when a booking is confirmed or cancelled.

---

## Business Rules and Conditions

**Event Code Uniqueness**
No two events in the same school can have the same event code. The system must reject duplicate codes during creation.

**Date Range Validation**
The event end date must always be on or after the event start date. Similarly, the booking window end must be after the booking window start. Booking windows typically close before or on the event start date.

**Live Event Status**
Every event shows a live status based on the current time — Upcoming (booking has not started yet), Open (parents can book slots), or Closed (booking window has ended). This status is calculated dynamically and not stored in the database.

**Analytics Counts**
The event list screen should show important numbers for each event — how many classes are participating, total slots generated, how many slots have been booked, and the booking percentage. These counts help admin assess event progress at a glance.

**Soft Delete Protection**
When an event is deleted, all assignments, batch templates, slots, and bookings under it should also be soft-deleted. The system should warn the admin before deletion if there are active bookings.

---

## Workflow Steps

**Creating an Event**
Admin opens the create form, enters the event code, title, selects academic session and term, sets the event dates and booking window, configures default settings (slot duration, buffer, capacity, meeting mode), and submits. A success message confirms the event is created. Admin can then proceed to add classes to this event.

**Viewing Events**
The event list page shows all events with filters for academic session, status, and date range. Each event row displays key metrics like class count, booking percentage, and live status. Clicking on an event shows its full details.

**Editing an Event**
Admin can change event dates, booking window, and default settings. However, once the booking window has opened, certain critical fields like event dates or booking window end time should be restricted to prevent disruption to parents who have already booked.

**Deleting an Event**
Admin can soft-delete an event. The system asks for confirmation and warns if there are active bookings. After deletion, the event and all its child records are hidden from the active interface.

---

## Example Scenario

A school wants to conduct Term 1 PTM for the academic year 2025-26. Admin creates an event with code PTM-T1-2526 titled "Term 1 Parent-Teacher Meet 2025-26" for the 2025-2026 session. The event runs from 10 May 2026 to 15 May 2026 with in-person mode. Parents can book slots from 1 May 2026 (9 AM) until 9 May 2026 (midnight). Each meeting is set to 10 minutes with a 2-minute buffer, allowing only one parent per slot (1-on-1 meetings). Cancellation is allowed up to 24 hours before the scheduled meeting time. Email and SMS notifications are enabled for both booking and cancellation.

Once the event is created, admin will add participating classes, assign teachers to batch templates, and eventually publish the schedule for parents to book.
