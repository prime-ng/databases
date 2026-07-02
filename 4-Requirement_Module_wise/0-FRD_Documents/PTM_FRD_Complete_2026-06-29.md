# PTM — Complete Analysis Pack
# Parent-Teacher Meeting Module | 2026-06-29

**Sources read:** DDL v3 (Sch_PTM_DDL_v3.sql), 17 tenant migrations, 11 controllers, 9 models, 6 services, routes/web.php (103 lines), V1 screen specs (PTM_v2/ — 8 screen files), decisions.md D35 + D36, modules-map.md, ParentPortal V2/07-PTM-and-Grievances.md

**Module Knowledge file:** `AI_Brain/module-knowledge/PTM_PTM.md`

**Standalone FRD:** This file is the combined Complete Analysis Pack. All section headings below map to the Analysis Mode Catalog.

---

## Table of Contents

1. [FRD — Section 1: Module Overview](#frd-section-1)
2. [FRD — Section 2: User Roles & Access](#frd-section-2)
3. [FRD — Section 3: Functional Requirements](#frd-section-3)
4. [FRD — Section 4: Business Rules Register](#frd-section-4)
5. [FRD — Section 5: Data Requirements](#frd-section-5)
6. [FRD — Section 6: Workflows](#frd-section-6)
7. [FRD — Section 7: Reporting & Analytics](#frd-section-7)
8. [FRD — Section 8: Future Enhancement Log](#frd-section-8)
9. [FRD — Section 9: Non-Functional Requirements](#frd-section-9)
10. [FRD — Section 10: Gap Analysis Readiness Index](#frd-section-10)
11. [Requirements Traceability Matrix (RTM)](#rtm)
12. [Process Flows + FSM Catalog](#process-flows)
13. [Data Dictionary (Business View)](#data-dictionary)
14. [Cross-Module Dependency Map](#dependency-map)
15. [NFR Catalog + Risk Register](#nfr-risk)
16. [Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks](#prioritization)
17. [User Stories + Acceptance Criteria + Reporting & KPI Spec](#user-stories)
18. [Requirement Conditions Catalog + Validation & Edge-Case Catalog](#conditions)

---

## FRD — Section 1: Module Overview {#frd-section-1}

### 1.1 Purpose

The Parent-Teacher Meeting (PTM) module enables Indian K-12 schools to plan, schedule, and manage structured parent-teacher meetings. It covers the full lifecycle from creating a PTM occasion tied to the academic calendar, through scheduling which classes participate and when, building reusable time-slot templates, assigning teachers to their meeting windows, generating concrete bookable slots, and allowing parents to book or cancel meetings — either by self-selecting slots or receiving school-assigned allocations.

### 1.2 Business Value

- Eliminates informal, crowded PTMs where parents wait indefinitely — every parent gets a fixed, dignified time slot.
- Gives schools control over meeting format (in-person, online, hybrid) per event or per class.
- Reduces administrative burden: reusable batch templates mean a teacher sets up once and reuses across terms.
- Provides clear post-meeting records (attendance, notes) and analytics (booking rates, no-show rates) to improve participation over time.
- Supports both school-controlled (admin assigns slots) and parent-choice (parents self-book) scheduling models within the same event.

### 1.3 Scope

**In Scope:**
- PTM event creation and configuration per academic session and term
- Class-section participation scheduling (date, time window, room or meeting link)
- Reusable batch templates (time grid, slot duration, buffer, capacity)
- Teacher-class assignments with allocation modes (school-assigned vs parent-pick)
- Multi-teacher parallel sub-batch support for large classes
- Teacher unavailability (blockout) management with automatic slot masking
- Automated meeting slot generation from templates, with blockout enforcement
- Manual slot management (block, unblock, add, cancel)
- Parent self-booking, school-allocated booking, cancellation, and rescheduling
- Post-meeting attendance marking and teacher meeting notes
- Booking and cancellation notifications to parents and teachers
- Management dashboard with real-time booking analytics
- Reporting: event summary, teacher schedule, class-wise status, attendance, parent history

**Out of Scope:**
- Video conferencing hosting — only the meeting link (URL) is stored; the call itself is external (Zoom, Teams, etc.)
- Displaying academic results or grade cards during the meeting interface
- Fee collection for PTM registration — seven database tables exist for this feature but the implementation is not yet built (noted as enhancement ENH-PTM-007)
- Communication with parents outside of the booking notification flow — handled by the Communication module
- Automated meeting minutes or AI transcription

### 1.4 Terminology

| Business Term | Meaning |
|---------------|---------|
| PTM Event | A named, school-wide parent-teacher meeting occasion (e.g. "Term 1 PTM 2025-26") linked to an academic session and term. Acts as the container for all scheduling beneath it. |
| Class Schedule (within Event) | The specific date, operating time window, meeting mode, and venue assigned to one class-section within a PTM event. |
| Batch Template | A reusable configuration defining the time window, meeting duration, buffer between slots, and maximum participants per slot. Created by a teacher; applied to one or more class-sections. |
| Slot Grid | The set of individual time-slot entries within a batch template (e.g. 9:00–9:10, 9:10–9:20). Includes break markers. |
| Assignment | The record linking a Batch Template to a specific Class Schedule and a primary teacher. Setting the assignment to Published generates the concrete meeting slots and opens booking. |
| Sub-Batch | An extension of an assignment where additional teachers share a class-section in parallel groups, each with their own slot grid and student list. |
| Blockout | A time interval within an event during which a teacher (or all teachers) is unavailable. Slots overlapping a blockout are automatically set to Blocked. |
| Meeting Slot | A concrete, dated, wall-clock time slot (e.g. 10 May 2026, 9:00–9:10 AM, Mrs. Sharma, Room 101). Has a status and capacity. |
| Booking | A parent's confirmed reservation of a specific meeting slot for their child's meeting with a teacher. |
| Booking Window | The period during which parents may book or cancel their slots (set at event level). |
| School-Allocated Mode | The school assigns each student to a specific slot; parents view their allocated time but cannot change it. |
| Parent-Pick Mode | Parents log in and choose their preferred available slot on a first-come, first-served basis. |
| Cancellation Lead Time | The minimum number of hours before a meeting time within which a parent can still self-cancel. After this threshold, only admin can cancel. |
| Active Booking | A booking with CONFIRMED status. Only one active booking per student per teacher per event is permitted. |

---

## FRD — Section 2: User Roles & Access {#frd-section-2}

### 2.1 Actors

| Actor | Description | Primary PTM Actions |
|-------|-------------|---------------------|
| School Administrator | Principal or designated admin; full PTM authority | Create/edit/delete events, manage all assignments, publish, cancel, generate reports |
| Academic Coordinator | Scheduling authority below Principal | Create events, manage class schedules and assignments, view reports |
| Class Teacher | Teacher participating in PTM | Manage own batch templates and blockouts; mark attendance; add meeting notes; view own schedule |
| School Staff / Receptionist | Support role | Book or cancel on behalf of parents; view bookings; assist with admin allocation |
| Parent | Guardian of enrolled students | Self-book/cancel slots in Parent-Pick mode; view confirmed meeting details |
| Student | Enrolled student | View their confirmed meeting schedule (read-only) |

> Data is isolated per school — no user in one school can see any PTM data from another school.

### 2.2 Role-Feature Matrix

| Feature | School Admin | Academic Coord. | Class Teacher | School Staff | Parent | Student |
|---------|:---:|:---:|:---:|:---:|:---:|:---:|
| Create / edit PTM Event | Yes | Yes | No | No | No | No |
| Delete PTM Event | Yes | No | No | No | No | No |
| Manage Class Schedules | Yes | Yes | No | No | No | No |
| Create Batch Template | Yes | Yes | Yes (own) | No | No | No |
| Edit / Delete Batch Template | Yes | Yes | Yes (own) | No | No | No |
| Create Assignment | Yes | Yes | No | No | No | No |
| Publish Assignment | Yes | Yes | No | No | No | No |
| Manage Blockouts | Yes | Yes | Yes (own) | No | No | No |
| View Slots | Yes | Yes | Yes (own) | Yes | No | No |
| Block / Unblock a Slot | Yes | Yes | Yes (own) | No | No | No |
| Book on behalf of Parent | Yes | No | No | Yes | No | No |
| Self-book a Slot | No | No | No | No | Yes | No |
| Cancel Booking (admin) | Yes | No | No | Yes | No | No |
| Self-cancel Booking | No | No | No | No | Yes (lead time) | No |
| Reschedule Booking | Yes | No | No | No | Yes (if allowed) | No |
| Mark Attendance / No-Show | Yes | No | Yes | No | No | No |
| Add Meeting Notes | No | No | Yes | No | No | No |
| View Event Dashboard | Yes | Yes | Yes (own) | Yes | No | No |
| View Reports | Yes | Yes | Yes (own) | No | No | No |
| View My Bookings | No | No | No | No | Yes | Yes |

---

## FRD — Section 3: Functional Requirements {#frd-section-3}

---

### REQ-PTM-001 — PTM Event Management
**Priority:** Core (P0) | **Tags:** [CONFIGURATION] [DATA_ENTRY] [WORKFLOW]

**Description:**
School administrators can create a named PTM Event that serves as the container for an entire parent-teacher meeting occasion. The event establishes the overall date range, meeting mode, booking window, default slot parameters, notification preferences, and an activation status. Multiple events can exist per academic session (e.g. one per term). The event list shows live analytics per event.

**Actors:** Initiates — School Administrator, Academic Coordinator | Views — all internal roles

**Business Rules:** BR-PTM-001, BR-PTM-002, BR-PTM-014

**Acceptance Criteria:**
- [ ] A new event can be created with: unique code, title, academic session, academic term, event dates, meeting mode, booking window, cancellation lead time, reschedule toggle, default slot duration / buffer / capacity, notification toggles.
- [ ] Duplicate event codes within the same school are rejected with a clear error message.
- [ ] Event end date cannot be before event start date — validation prevents save.
- [ ] Booking window end must be after booking window start — validation prevents save.
- [ ] The event list shows for each event: title, date range, live status (Upcoming / Open / Closed), participating class count, total slots generated, booked slot count, and booking percentage.
- [ ] Live status is computed dynamically from current time vs booking window — it is not stored as a field.
- [ ] The activation toggle (Enable / Disable) hides or shows the event from parent-facing views without deleting it.
- [ ] An event can be soft-deleted; if confirmed bookings exist, the system warns before proceeding; soft-delete cascades to all child records.
- [ ] Soft-deleted events appear only in a Trash view; only users with the Restore permission can recover them.
- [ ] A soft-deleted event can be permanently deleted only by an administrator with the Force-Delete permission.

**Integration:** SchoolSetup (academic sessions and terms), Notification module (for downstream booking events)

**Enhancement Notes:** ENH-PTM-001 (auto-allocation), ENH-PTM-004 (reminder notifications)

---

### REQ-PTM-002 — Class-Section Event Scheduling
**Priority:** Core (P0) | **Tags:** [CONFIGURATION] [DATA_ENTRY]

**Description:**
Once a PTM event is created, an administrator assigns which class-sections will participate and configures each one's scheduled date, operating time window (day start and end), meeting mode override, and room or virtual meeting link. Each class-section gets exactly one schedule entry per event.

**Actors:** Initiates — School Administrator, Academic Coordinator | Views — all internal roles

**Business Rules:** BR-PTM-002

**Acceptance Criteria:**
- [ ] A class-section can be added to a PTM event by selecting it from the school's active class-sections.
- [ ] Each class-section entry requires: scheduled date (must fall within event start–end dates), day operating start and end times, meeting mode (defaults to event-level mode, can be overridden), room (for in-person) or virtual meeting link (for online).
- [ ] A class-section cannot be added to the same event twice — the system prevents duplicates.
- [ ] Meeting mode of IN_PERSON requires a room selection (or displays a warning if room is not specified).
- [ ] Meeting mode of ONLINE requires a virtual meeting link.
- [ ] An entry can be soft-deleted; soft-deleting cascades to assignments and slots under that class-section within the event.
- [ ] The class-section schedule list for an event shows each entry's date, time window, mode, room, and booking status summary.

**Integration:** SchoolSetup (class-sections, rooms)

---

### REQ-PTM-003 — Meeting Batch Template Management
**Priority:** Core (P0) | **Tags:** [CONFIGURATION] [DATA_ENTRY]

**Description:**
Teachers and administrators can create and manage reusable Batch Templates that define the shape of a teacher's meeting block — the operating time window, per-meeting duration, buffer gap between meetings, and maximum participants per meeting slot. A batch template is owned by a teacher but can be applied by an administrator to any assignment.

**Actors:** Initiates — School Administrator, Academic Coordinator, Class Teacher (own templates) | Views — all internal roles

**Business Rules:** BR-PTM-009

**Acceptance Criteria:**
- [ ] A batch template can be created with: unique code, name, owner teacher, window start time, window end time, meeting duration (minutes), buffer time (minutes), maximum participants per slot, optional description.
- [ ] A batch template can be reused across multiple events and multiple class-sections.
- [ ] A class teacher can manage only their own batch templates; administrators can manage all templates.
- [ ] Editing a batch template does not retroactively change already-generated slots for published assignments — slots already generated are fixed.
- [ ] A template can be activated or deactivated; deactivated templates cannot be selected for new assignments.
- [ ] A template with active assignments (published) cannot be deleted; it must be deactivated instead.
- [ ] The template list shows name, owner, window time range, slot duration, buffer, capacity, and number of assignments using it.

**Integration:** (none beyond school auth)

---

### REQ-PTM-004 — Batch Time Grid Management
**Priority:** Standard (P1) | **Tags:** [CONFIGURATION] [DATA_ENTRY]

**Description:**
Within a batch template, an administrator or teacher can define an explicit time grid — a sequence of individual slot entries (ordinal, start time, end time, optional break marker). This allows hand-crafting a non-uniform schedule (e.g. inserting a tea break in the middle). When the system generates meeting slots, it respects these grid entries. If no explicit grid is provided, the system generates slots dynamically from the window bounds and duration.

**Actors:** Initiates — School Administrator, Academic Coordinator, Class Teacher (own)

**Business Rules:** BR-PTM-009

**Acceptance Criteria:**
- [ ] Grid entries can be added to a batch template one by one or generated automatically (system fills window with slots of the specified duration + buffer).
- [ ] Each entry has an ordinal (display order), start time, end time, and an optional Break flag with a label (e.g. "Tea Break").
- [ ] No two entries in the same template may share the same ordinal or the same start time.
- [ ] Break-flagged entries are marked Blocked when slots are generated — parents cannot book them.
- [ ] Grid entries for a template with active published assignments can be edited; the administrator is warned that slot regeneration is required to apply changes.
- [ ] An entry can be deleted from the grid (if the template is not published).
- [ ] Viewing a template shows its grid in time order with visual differentiation for break entries.

---

### REQ-PTM-005 — Teacher-Class Assignment
**Priority:** Core (P0) | **Tags:** [WORKFLOW] [DATA_ENTRY]

**Description:**
An administrator creates an Assignment to connect a Batch Template to a specific Class-Section Schedule within a PTM event, designating a primary teacher and choosing an allocation mode. An assignment starts in Draft state. When published, meeting slots are generated automatically. Publishing is the gate that makes slots visible to parents.

**Actors:** Initiates — School Administrator, Academic Coordinator | Views — all internal roles (teacher sees own)

**Business Rules:** BR-PTM-010, BR-PTM-013

**Acceptance Criteria:**
- [ ] An assignment is created by selecting: event, class-section schedule (which class on which date), batch template, primary teacher, allocation mode (School-Allocated or Parent-Pick), optional overrides for buffer and max participants.
- [ ] Only one assignment per (class-section, teacher) within an event is allowed.
- [ ] The primary teacher defaults to the class teacher of the selected class-section (can be changed by admin).
- [ ] An assignment starts in Draft (unpublished) state; slots are not visible to parents.
- [ ] When an administrator publishes an assignment, the system generates all meeting slots from the batch template grid, applies blockout masking, and sets the assignment to Published.
- [ ] Changing the batch template, primary teacher, or overrides after publishing marks slots as stale; the administrator must explicitly regenerate slots.
- [ ] An attempt to unpublish an assignment with confirmed bookings produces a warning listing affected bookings.
- [ ] An assignment with confirmed bookings cannot be soft-deleted — all bookings must be cancelled first.
- [ ] The assignment list shows class, teacher, template, mode, publish status, slot count, and booking count.
- [ ] A teacher can view only assignments where they are the primary teacher or a sub-batch teacher.

**Integration:** Slot generation (REQ-PTM-008), Batch Template (REQ-PTM-003), Class-Section Schedule (REQ-PTM-002)

---

### REQ-PTM-006 — Multi-Teacher Sub-Batch Assignment
**Priority:** Standard (P1) | **Tags:** [CONFIGURATION] [DATA_ENTRY]

**Description:**
For large class-sections that need to be split into parallel groups, additional teachers can be added to an assignment as sub-batch participants. Each sub-batch teacher receives their own set of generated slots (parallel to the primary teacher's) with an optional student filter defining which students belong to their group. Sub-batch teachers may use a different room or virtual link than the primary teacher.

**Actors:** Initiates — School Administrator, Academic Coordinator

**Business Rules:** BR-PTM-004 (no double-booking extends to sub-batch teachers)

**Acceptance Criteria:**
- [ ] An administrator can add one or more additional teachers to an assignment with: teacher name, sub-batch label (e.g. "Roll 1–20"), optional room or virtual link, optional student filter (roll number range or explicit student list).
- [ ] Each additional teacher generates their own set of slots when the assignment is published.
- [ ] The no-double-booking rule applies to additional teachers — if a teacher is already in another assignment with overlapping slots, a conflict warning is shown.
- [ ] A teacher cannot be added as both the primary teacher and a sub-batch teacher in the same assignment.
- [ ] Sub-batch entries can be added or removed before the assignment is published; after publishing, changes require regeneration.
- [ ] Student filters are stored as configuration — they guide the admin during school-allocated booking but are not automatically enforced during parent-pick booking (parents select their child's teacher).

---

### REQ-PTM-007 — Teacher Unavailability Management
**Priority:** Core (P0) | **Tags:** [DATA_ENTRY] [WORKFLOW]

**Description:**
Teachers and administrators can create Blockout records marking a teacher as unavailable for a defined time window within a PTM event (e.g. lunch break, staff meeting). Blockouts with no teacher specified apply to all teachers in the event (school-wide blockout). When a blockout is created or removed, the status of all affected meeting slots is updated immediately.

**Actors:** Initiates — School Administrator, Academic Coordinator, Class Teacher (own) | Views — all internal roles

**Business Rules:** BR-PTM-011, BR-PTM-012

**Acceptance Criteria:**
- [ ] A blockout is created by selecting: event, optional teacher (blank = all teachers), date (must be within event dates), start time, end time, reason.
- [ ] End time must be after start time — validation prevents save.
- [ ] When a blockout is saved, all slots under that event whose time window overlaps the blockout (even partial overlap) are set to Blocked.
- [ ] When a blockout is removed, previously blocked slots that no longer overlap any active blockout are restored to their appropriate status (Available, Booked, or Full based on their booking count).
- [ ] Removing a blockout does NOT affect slots that were already Blocked due to an is_break marker — those remain Blocked.
- [ ] A teacher can create and manage only their own blockouts; administrators can manage all.
- [ ] A blockout does NOT automatically cancel existing confirmed bookings that fall within its time window — it prevents new bookings only. Admin must cancel affected bookings manually if needed.
- [ ] The blockout list shows all blockouts for an event, filterable by teacher and date, with a count of affected slots.

**Integration:** Slot status update (REQ-PTM-008, REQ-PTM-009)

---

### REQ-PTM-008 — Meeting Slot Generation
**Priority:** Core (P0) | **Tags:** [WORKFLOW] [SCHEDULED]

**Description:**
When an assignment is published, the system automatically generates concrete, dated meeting slots for each teacher in the assignment. Slots inherit their timing from the batch template grid (or from dynamic calculation if no explicit grid exists). Slots overlapping any blockout or marked as breaks are set to Blocked. The generation can also be triggered manually to regenerate after template or blockout changes.

**Actors:** Initiates — System (on publish) | Monitored by — School Administrator, Academic Coordinator

**Business Rules:** BR-PTM-009, BR-PTM-010, BR-PTM-011

**Acceptance Criteria:**
- [ ] Publishing an assignment triggers slot generation for the primary teacher and all sub-batch teachers.
- [ ] Each non-break grid entry produces one Available slot with: exact wall-clock start and end (combining class schedule date + template time), teacher, capacity, room or virtual link, and assignment link.
- [ ] Each break grid entry produces one Blocked slot marked as a break (not visible to parents).
- [ ] Any slot whose time window overlaps an active blockout for the same teacher (or a school-wide blockout) is set to Blocked at generation time.
- [ ] Regeneration (triggered after template or blockout changes) deletes existing slots for the assignment and regenerates them; confirmed bookings are NOT automatically cancelled — admin must decide how to handle them before regenerating (system warns if bookings exist).
- [ ] Slot generation uses the fallback chain for parameters: Assignment override → Batch Template → Event default (BR-PTM-009).
- [ ] No two slots for the same teacher within the same event may share the same start time.
- [ ] After generation, the assignment summary shows total slots, available count, blocked count.

---

### REQ-PTM-009 — Slot Lifecycle Management
**Priority:** Standard (P1) | **Tags:** [WORKFLOW] [DATA_ENTRY]

**Description:**
Administrators and teachers can manage individual meeting slots after generation: view the full slot list with filters, manually block or unblock specific slots, manually create exceptional slots outside the normal template, and cancel entire slots (which cancels all bookings on that slot). Slot statuses are updated dynamically as bookings are placed or cancelled.

**Actors:** Initiates — School Administrator, Class Teacher (own) | Views — all internal roles

**Business Rules:** BR-PTM-012, BR-PTM-013

**Acceptance Criteria:**
- [ ] The slot list shows: date, start/end time, teacher, room or virtual link, capacity, booked count, status. Filters by event, class, teacher, date, and status.
- [ ] An administrator can manually block an Available slot; if the slot has confirmed bookings, the system warns and requires the bookings to be cancelled first.
- [ ] An administrator can unblock a Blocked slot (excluding break slots which cannot be unblocked by admin).
- [ ] An administrator can manually create a slot by specifying teacher, date, start time, end time, capacity, and room; the no-double-booking constraint applies (teacher cannot have another slot at the same start time).
- [ ] An administrator can cancel a slot; all confirmed bookings on that slot are cancelled automatically and cancellation notifications are sent.
- [ ] Slot status transitions are: Available → Booked (first booking confirmed) → Full (all capacity used); Booked / Available → Blocked (admin block or blockout overlap); any non-Completed → Cancelled (admin cancel); any confirmed → Completed (time has passed and admin marks complete).
- [ ] A Completed slot cannot revert to Available.
- [ ] Slots marked as breaks are not shown in the parent booking interface.

---

### REQ-PTM-010 — Parent Self-Booking (Parent-Pick Mode)
**Priority:** Core (P0) | **Tags:** [WORKFLOW] [DATA_ENTRY]

**Description:**
In Parent-Pick mode, parents log into the school portal, select a PTM event, choose their child, browse available slots per teacher, and book a preferred time. The booking is confirmed immediately if the slot is available and all rules pass. A parent may book one slot per teacher per child within the event.

**Actors:** Initiates — Parent | Processed — System | Views — Parent, School Administrator, Class Teacher (own)

**Business Rules:** BR-PTM-003, BR-PTM-005, BR-PTM-006, BR-PTM-012

**Acceptance Criteria:**
- [ ] A parent can only book within the event's booking window; outside the window, the book button is disabled and a message explains when booking opens or closed.
- [ ] The parent sees only Published assignments for active events within the booking window.
- [ ] The parent selects their child (in case of multiple children), then sees teachers for that child's class-section in the event.
- [ ] Each teacher's slot list shows only Available and Booked (not Full) slots; Blocked and Full slots are hidden.
- [ ] The parent may optionally add a comment (e.g. "Want to discuss maths performance") before confirming.
- [ ] The system validates immediately before confirming: booking window still open, slot still Available or Booked (not full), student does not already have a confirmed booking with this teacher for this event.
- [ ] A successful booking produces a CONFIRMED booking record, decrements the slot's available count, and — if event notifications are enabled — sends a booking confirmation notification.
- [ ] The parent can book multiple different teachers for the same child within one event.
- [ ] The booking confirmation screen and "My Bookings" view show: event name, teacher, date, time, room or meeting link, and cancellation lead time.
- [ ] Empty state: if no slots are available for a teacher, the parent sees a clear message ("No available slots for this teacher") not a blank page.

**Integration:** ParentPortal module (parent-facing view), Notification module (confirmation alert)

---

### REQ-PTM-011 — School-Allocated Booking
**Priority:** Standard (P1) | **Tags:** [WORKFLOW] [DATA_ENTRY]

**Description:**
In School-Allocated mode, the school administrator or staff assigns specific slots to students rather than allowing parents to choose. The admin views the class roster and the available slots, then maps each student to a slot. Parents see their allocated slot and time but cannot change it. An auto-allocation option (future enhancement) assigns slots algorithmically.

**Actors:** Initiates — School Administrator, School Staff | Views — Parent (assigned slot only), Class Teacher

**Business Rules:** BR-PTM-003 (bypassed for admin), BR-PTM-005

**Acceptance Criteria:**
- [ ] An administrator can view all students in a class-section along with the available slots for the assignment teacher.
- [ ] The administrator can select a student and assign them to an available slot; the booking is created as CONFIRMED.
- [ ] A student can be assigned to only one slot per teacher per event; attempting to assign again shows a conflict error.
- [ ] Admin allocation bypasses the booking window check (can allocate before or after the booking window).
- [ ] Allocated parents see their confirmed slot in the parent-facing view in read-only mode (no booking or rescheduling controls in school-allocated mode).
- [ ] An administrator can remove a school-allocated booking and re-allocate the student to a different slot.
- [ ] The allocation screen shows for each student: name, roll number, current booking status (Allocated / Not Allocated).

**Integration:** ParentPortal (read-only view for parent), StudentProfile (student roster), Notification module

---

### REQ-PTM-012 — Booking Cancellation
**Priority:** Core (P0) | **Tags:** [WORKFLOW]

**Description:**
Parents can cancel a confirmed booking up to the lead time configured in the event. After the lead time has passed, only administrators or school staff can cancel. Cancellation restores slot availability and triggers a notification if enabled.

**Actors:** Initiates — Parent (self-service within lead time), School Administrator, School Staff | System — updates slot status

**Business Rules:** BR-PTM-007, BR-PTM-006

**Acceptance Criteria:**
- [ ] A parent sees a Cancel button on their confirmed bookings only while the cancellation lead time has not expired.
- [ ] When the deadline passes (slot_start minus lead_time_hours < now), the Cancel button is disabled for the parent; an administrator or staff can still cancel.
- [ ] Cancellation requires an optional reason from the parent; a mandatory reason from admin is encouraged but not enforced.
- [ ] Upon cancellation: booking status becomes CANCELLED, cancellation timestamp is recorded, slot's booked count decreases by one, slot status is recalculated (Full → Booked or Booked → Available as appropriate).
- [ ] A cancelled booking preserves its record; the parent can book a different slot after cancellation (the CANCELLED booking does not prevent a fresh booking with the same teacher in the same event).
- [ ] A cancellation notification is sent to the parent if the event has cancellation notifications enabled.
- [ ] The cancellation is recorded in the activity log (who cancelled, when, reason).

---

### REQ-PTM-013 — Booking Rescheduling
**Priority:** Standard (P1) | **Tags:** [WORKFLOW]

**Description:**
If the PTM event allows rescheduling, a parent can move their confirmed booking to a different available slot with the same teacher. Rescheduling is implemented as a cancel-and-re-book operation executed atomically.

**Actors:** Initiates — Parent, School Administrator

**Business Rules:** BR-PTM-008, BR-PTM-007

**Acceptance Criteria:**
- [ ] The reschedule option is available to a parent only if: the event's Allow Reschedule setting is Yes, and the cancellation lead time has not expired.
- [ ] A parent selects a new available slot; the system cancels the old booking and creates a CONFIRMED booking on the new slot in a single atomic operation.
- [ ] If the new slot becomes unavailable between selection and confirmation, the reschedule fails with an error and the original booking remains unchanged.
- [ ] An administrator can reschedule a booking regardless of the Allow Reschedule setting or lead time.
- [ ] Rescheduling fires the appropriate booking confirmation and cancellation notifications.
- [ ] The activity log records the reschedule with both the old and new slot details.

---

### REQ-PTM-014 — Post-Meeting Attendance & Notes
**Priority:** Standard (P1) | **Tags:** [DATA_ENTRY] [WORKFLOW]

**Description:**
After a PTM day, a class teacher reviews their list of confirmed bookings and marks each meeting as Attended or No-Show. Teachers may also record brief meeting notes against each booking. These records support post-event analytics on participation rates.

**Actors:** Initiates — Class Teacher | Views — School Administrator, Academic Coordinator (reports)

**Business Rules:** (none specific; relies on booking status FSM)

**Acceptance Criteria:**
- [ ] After a slot's scheduled time has passed, the teacher's view of that slot shows each confirmed booking with an Attended / No-Show toggle.
- [ ] Marking Attended transitions the booking to COMPLETED and records an attendance timestamp.
- [ ] Marking No-Show transitions the booking to NO_SHOW; this does not restore slot availability (the meeting time is in the past).
- [ ] A teacher can add free-text meeting notes (up to 500 characters) against any booking.
- [ ] Meeting notes are visible to the teacher and administrator; they are not visible to the parent.
- [ ] Attendance can be corrected after the fact (e.g. changing No-Show to Completed) by the teacher or administrator.
- [ ] The teacher's post-meeting view shows: student name, class, booking time, parent comment, attendance status, meeting notes field.

---

### REQ-PTM-015 — Booking Notifications
**Priority:** Standard (P1) | **Tags:** [NOTIFICATION]

**Description:**
The module sends notification alerts to parents and optionally teachers at key booking lifecycle events: booking confirmed, booking cancelled, no-show recorded, and meeting completed. Notification sending is controlled by per-event flags.

**Actors:** Initiates — System | Recipients — Parent, Class Teacher (optional)

**Business Rules:** (notification flags in event settings)

**Acceptance Criteria:**
- [ ] When a booking is confirmed (self-book or admin-book) and the event's "Notify parent on booking" flag is on, a notification is dispatched to the parent with the teacher's name, meeting date and time, and room or link.
- [ ] When a booking is cancelled and the event's "Notify parent on cancellation" flag is on, a notification is dispatched to the parent.
- [ ] When a booking is marked No-Show, an optional no-show notification can be sent to the parent (controlled by event flag).
- [ ] Teacher-side notifications (booking confirmed, cancelled, no-show) are controlled by separate event flags.
- [ ] Notifications are delivered asynchronously (queued) to avoid delaying the booking confirmation response. [Currently synchronous — P1 gap]
- [ ] Notification delivery failure does not roll back the booking; failures are logged and retried by the queue system.
- [ ] Notification content includes event name, teacher name, date, time, and meeting link (if applicable).

**Integration:** Notification module

---

### REQ-PTM-016 — Management Dashboard & Analytics
**Priority:** Standard (P1) | **Tags:** [DASHBOARD] [REPORT]

**Description:**
A management interface gives administrators and coordinators an at-a-glance view of each PTM event's progress: how many classes are participating, how many slots have been generated, how many are booked, and the booking completion percentage. AJAX data feeds allow live-updating views of teacher schedules, student lists, and slot availability.

**Actors:** Views — School Administrator, Academic Coordinator, Class Teacher (own event data)

**Business Rules:** (computed/display rules, no transactional rules)

**Acceptance Criteria:**
- [ ] The event list and event detail screen show live metrics: participating class count, total slot count, booked count, blocked count, booking percentage.
- [ ] An AJAX endpoint returns all teachers assigned to a class-section within an event.
- [ ] An AJAX endpoint returns teachers assigned to a specific assignment.
- [ ] An AJAX endpoint returns all students enrolled in a PTM event (via their class-section).
- [ ] An AJAX endpoint returns a teacher's slot availability within an event (showing Available / Booked / Full / Blocked slots).
- [ ] The combined management view has tabbed navigation: Setup (events, class schedules, templates), Scheduling (assignments, blockouts, slots), Bookings (booking list, per-student status).
- [ ] All dashboard data respects the school's data isolation (no cross-school data visible).

---

### REQ-PTM-017 — PTM Reporting
**Priority:** Enhanced (P2) | **Tags:** [REPORT]

**Description:**
Dedicated report screens present formatted, exportable views of PTM data for administrative review, parent communication, and post-event analysis.

**Actors:** Views — School Administrator, Academic Coordinator, Class Teacher (own reports)

**Business Rules:** (see Section 7)

**Acceptance Criteria:**
- [ ] Five report types are available (see Section 7 for full specifications: RPT-PTM-001 through RPT-PTM-005).
- [ ] Each report can be filtered by event, class-section, teacher, and date range.
- [ ] Reports can be exported to PDF and/or Excel/CSV.
- [ ] A teacher's schedule report can be printed as a take-to-PTM-day reference sheet.
- [ ] All reports are scoped to the current school — no cross-tenant data.

---

## FRD — Section 4: Business Rules Register {#frd-section-4}

| ID | Rule | Type | Trigger | Enforcement |
|----|------|------|---------|-------------|
| BR-PTM-001 | No two PTM events in the same school may share the same event code. | Validation | Event creation and edit | Save prevented with error |
| BR-PTM-002 | Event end date ≥ event start date. Booking window end > booking window start. Booking window typically closes on or before event start date. | Validation | Event creation and edit | Save prevented with error |
| BR-PTM-003 | Self-booking (parent) is only allowed when current date-time is within the booking window (≥ booking_window_start AND ≤ booking_window_end). Admin booking bypasses this check. | Workflow | Booking creation (parent-pick) | Booking rejected if outside window |
| BR-PTM-004 | A teacher cannot have two meeting slots with the same start time — not within one assignment, nor across different assignments in the same event or across events. | Validation | Slot generation and manual slot creation | DB unique constraint + application check; generation error shown to admin |
| BR-PTM-005 | A student may have only one CONFIRMED booking per teacher per event. Cancelled, No-Show, or Completed bookings do not count toward this limit — the student may re-book. | Validation | Booking creation | Booking rejected with clear message |
| BR-PTM-006 | The booking count on a slot must be less than the slot's capacity before a new booking is accepted. Full slots (booked_count = capacity) cannot be booked. | Validation | Booking creation | Booking rejected; slot status shown as Full to parent |
| BR-PTM-007 | A parent may only self-cancel a booking if current_time + cancellation_lead_time_hours ≤ slot_start. After this threshold, only an administrator or school staff may cancel. | Validation | Self-cancellation by parent | Cancel button hidden/disabled; error if attempted via API |
| BR-PTM-008 | Rescheduling is implemented as an atomic cancel-and-re-book. Rescheduling is only available when: (a) the event's Allow Reschedule flag is Yes, and (b) the cancellation lead time has not expired. Administrators bypass both restrictions. | Workflow | Rescheduling action | Reschedule option hidden if not allowed; both steps fail together if new slot unavailable |
| BR-PTM-009 | Slot duration, buffer time, and maximum participants per slot are resolved by a three-level fallback: Assignment override (highest) → Batch Template value → Event default (lowest). The first non-null, non-zero value in the chain is used. | Calculation | Slot generation | Applied in slot generation service |
| BR-PTM-010 | Publishing an assignment triggers deletion of all existing slots for that assignment and regeneration from the batch template grid, applying blockout masks at generation time. | Workflow | Assignment publish / regenerate | Executed transactionally; confirmed bookings are warned about before regeneration |
| BR-PTM-011 | When a blockout is created, all slots in the same event whose time window overlaps the blockout are set to Blocked. When a blockout is deleted, affected slots that no longer overlap any blockout are restored (to Available, Booked, or Full based on booking count). Break slots remain Blocked regardless. | Workflow | Blockout create / delete | Applied by slot-sync service after blockout save/delete |
| BR-PTM-012 | A meeting slot with status Blocked, Full, or Cancelled cannot be booked. Only Available and Booked (with remaining capacity) slots accept new bookings. | Validation | Booking creation | Booking rejected with appropriate status message |
| BR-PTM-013 | An assignment that has one or more confirmed bookings cannot be soft-deleted. All bookings must be cancelled before the assignment can be removed. | Workflow | Assignment delete | Delete prevented; error message lists booking count |
| BR-PTM-014 | Deleting a PTM event soft-deletes all child records (class schedules, batch templates in use, assignments, slots, bookings) in cascade. If confirmed bookings exist, the system requires an additional confirmation step before proceeding. | Workflow | Event delete | Warning dialog shows booking count; cascade soft-delete executed on confirmation |
| BR-PTM-015 | Unpublishing an assignment that has confirmed bookings must produce a warning listing affected bookings. The administrator must acknowledge before proceeding. Unpublishing does not automatically cancel bookings. | Workflow | Assignment unpublish | Warning dialog; unpublish proceeds only on explicit confirmation |

---

## FRD — Section 5: Data Requirements {#frd-section-5}

### 5.1 PTM Event (Container)

| Business Field | Meaning | Type | Required | Privacy |
|----------------|---------|------|----------|---------|
| Event Code | Unique short identifier (e.g. PTM-T1-2526) | Short text | Yes | Internal |
| Title | Human-readable name of the event | Text | Yes | Internal |
| Academic Session | School year this event belongs to | Reference | Yes | Internal |
| Academic Term | Term within the session (Term 1, Mid-Term, etc.) | Reference | No | Internal |
| Description | Free-form notes shown to staff | Long text | No | Internal |
| Event Start Date | First day of the PTM occasion | Date | Yes | Internal |
| Event End Date | Last day of the PTM occasion | Date | Yes | Internal |
| Default Meeting Mode | In-Person / Online / Hybrid — applies unless overridden at class level | List | Yes | Internal |
| Booking Window Opens | Date-time when parents may start booking | Date-time | Yes | Internal |
| Booking Window Closes | Date-time when parent booking ends | Date-time | Yes | Internal |
| Cancellation Lead Time | Minimum hours before slot start for self-cancellation | Number | Yes | Internal |
| Allow Rescheduling | Whether parents may move their booking | Yes/No | Yes | Internal |
| Default Meeting Duration | Fallback slot duration in minutes | Number | Yes | Internal |
| Default Buffer Time | Fallback gap between meetings in minutes | Number | Yes | Internal |
| Default Capacity | Fallback max participants per slot | Number | Yes | Internal |
| Notify Parent on Booking | Send alert when booking is confirmed | Yes/No | Yes | Internal |
| Notify Parent on Cancellation | Send alert when booking is cancelled | Yes/No | Yes | Internal |
| Active | Whether the event is visible to parents | Yes/No | Yes | Internal |

### 5.2 Class-Section Schedule

| Business Field | Meaning | Required | Privacy |
|----------------|---------|----------|---------|
| Class-Section | Which class-section participates | Yes | Internal |
| Scheduled Date | Date the class will hold its meetings | Yes | Internal |
| Day Start Time | Earliest meetings may start | Yes | Internal |
| Day End Time | Latest meetings must end | Yes | Internal |
| Meeting Mode Override | In-Person / Online / Hybrid (overrides event default) | No | Internal |
| Room | Physical room for in-person meetings | No | Internal |
| Virtual Meeting Link | URL for online meetings | No | Internal |
| Notes | Admin notes about this class's setup | No | Internal |

### 5.3 Batch Template

| Business Field | Meaning | Required | Privacy |
|----------------|---------|----------|---------|
| Template Code | Unique short code | Yes | Internal |
| Template Name | Descriptive name | Yes | Internal |
| Owner Teacher | Teacher who created and owns this template | Yes | Internal |
| Window Start Time | Earliest the meeting block begins | Yes | Internal |
| Window End Time | Latest the meeting block ends | Yes | Internal |
| Meeting Duration | Per-meeting duration in minutes | Yes | Internal |
| Buffer Between Meetings | Gap between consecutive meetings in minutes | Yes | Internal |
| Max Participants Per Meeting | 1 = one-on-one; >1 = group meeting | Yes | Internal |
| Description | Optional notes | No | Internal |

### 5.4 Batch Slot Grid Entry

| Business Field | Meaning | Required |
|----------------|---------|----------|
| Order | Display/generation sequence number | Yes |
| Start Time | When this slot begins (time of day) | Yes |
| End Time | When this slot ends | Yes |
| Is Break | Whether this is an unbookable break | Yes |
| Break Label | Label for the break (e.g. "Tea Break") | If Break = Yes |

### 5.5 Assignment

| Business Field | Meaning | Required | Privacy |
|----------------|---------|----------|---------|
| PTM Event | Which event | Yes | Internal |
| Class-Section Schedule | Which class-section on which date | Yes | Internal |
| Batch Template | The meeting time grid applied | Yes | Internal |
| Primary Teacher | Teacher running the meetings | Yes | Internal |
| Allocation Mode | School-Allocated or Parent-Pick | Yes | Internal |
| Duration Override | Overrides batch template duration (optional) | No | Internal |
| Buffer Override | Overrides batch template buffer (optional) | No | Internal |
| Capacity Override | Overrides max participants (optional) | No | Internal |
| Published | Whether slots are visible/bookable | Yes | Internal |
| Published At | When the assignment was published | Auto | Internal |
| Internal Notes | Notes for admin use | No | Internal |

### 5.6 Meeting Slot

| Business Field | Meaning | Required | Privacy |
|----------------|---------|----------|---------|
| Meeting Date & Start Time | Wall-clock start (date + time) | Yes | Internal |
| Meeting End Time | Wall-clock end | Yes | Internal |
| Teacher | Teacher conducting the meeting | Yes | Internal |
| Capacity | Maximum bookings allowed | Yes | Internal |
| Booked Count | Current confirmed booking count | Auto | Internal |
| Status | Available / Booked / Full / Blocked / Completed / Cancelled | Auto | Internal |
| Is Break | Whether this is an unbookable break slot | Auto | Internal |
| Room | Physical room | No | Internal |
| Virtual Meeting Link | URL override for this slot | No | Internal |

### 5.7 Booking

| Business Field | Meaning | Required | Privacy |
|----------------|---------|----------|---------|
| Meeting Slot | Which slot is being reserved | Yes | Internal |
| Student | Which student the meeting is about | Yes | Internal |
| Booked By | Who placed the booking (parent or staff) | Yes | Internal |
| Parent's Message | Pre-meeting note from parent to teacher | No | Internal |
| Booking Status | Confirmed / Cancelled / No-Show / Completed / Rescheduled | Auto | Internal |
| Booked At | When the booking was placed | Auto | Internal |
| Cancelled At | When cancellation occurred | Auto | Internal |
| Cancellation Reason | Why it was cancelled | No | Internal |
| Attended | Did the student/parent attend? (Yes / No / Not recorded) | No | Internal |
| Meeting Notes | Post-meeting notes recorded by teacher | No | Internal — not visible to parent |

### 5.8 Teacher Blockout

| Business Field | Meaning | Required | Privacy |
|----------------|---------|----------|---------|
| PTM Event | Which event this blockout scopes to | Yes | Internal |
| Teacher | Which teacher (blank = all teachers) | No | Internal |
| Blockout Date | Date of unavailability | Yes | Internal |
| Start Time | Start of unavailability window | Yes | Internal |
| End Time | End of unavailability window | Yes | Internal |
| Reason | Explanation (e.g. "Lunch", "Staff Meeting") | Yes | Internal |

**Privacy note:** No PII beyond student-teacher assignment identification. Parent's Message and Meeting Notes are sensitive school records accessible only to the teacher and admin — never surfaced in any report visible to other parents.

---

## FRD — Section 6: Workflows {#frd-section-6}

### Workflow 1: Create and Launch a PTM Event

**Trigger:** Academic coordinator decides to run a PTM.
**End States:** Event is Published and booking window is open for parents.

**Steps:**
1. [Admin] Creates PTM Event — sets code, title, session, term, dates, meeting mode, booking window, defaults, notification flags.
2. [Admin] Adds Class-Section Schedules — for each class-section, sets date, time window, mode, room/link.
3. [Admin / Teacher] Creates Batch Templates — teacher builds their preferred time grid (or uses an existing template).
4. [Admin] Creates Assignments — links batch template + primary teacher to each class-section; sets allocation mode.
5. [Optional — Admin] Adds Sub-Batch Teachers for large classes.
6. [Admin / Teacher] Creates Blockouts — marks unavailability windows for each teacher.
7. [Admin] Reviews Assignments, then Publishes — system generates slots, applies blockout masks.
8. [System] Booking window opens at the configured date-time; parents can now book.

**Exception paths:**
- If the booking window opens before all assignments are published, parents see only the published class schedules.
- If slot generation finds a double-booking conflict (two assignments for the same teacher at the same start time), generation halts for that teacher and an error is shown; admin must adjust the templates before republishing.

**Notifications triggered:** None during setup. Notifications trigger per booking.

---

### Workflow 2: Parent Self-Booking (Parent-Pick Mode)

**Trigger:** Parent logs into parent portal during the event's booking window.
**End States:** Booking CONFIRMED or booking rejected with an informative error.

**Actors / Swimlanes:** Parent | System

**Steps:**
1. [Parent] Selects active PTM event from portal.
2. [Parent] Chooses child (if multiple).
3. [System] Shows list of teachers for the child's class-section in the event.
4. [Parent] Selects a teacher, views their available time slots.
5. [System] Displays Available slots only (not Blocked, Full, or Cancelled).
6. [Parent] Clicks a preferred slot; optionally adds a message.
7. [Parent] Confirms booking.
8. [System] Validates: booking window open; slot is Available/Booked (not full); student has no existing CONFIRMED booking with this teacher in this event; no time overlap with the student's other confirmed bookings.
9. [System] Creates CONFIRMED booking, decrements slot booked count, updates slot status.
10. [System] Sends booking confirmation notification (if enabled).
11. [Parent] Sees confirmation screen and the booking in "My Bookings."

**Exception paths:**
- Booking window closed → "Booking for this event is not currently open."
- Slot just became Full (race condition) → "That slot is no longer available — please choose another."
- Student already has a booking with this teacher → "You already have a booking with this teacher. Please cancel it first if you want a different time."

---

### Workflow 3: Admin School-Allocated Booking

**Trigger:** Administrator publishes assignment in School-Allocated mode and begins assigning students.
**End States:** All students have been allocated a slot, or admin has allocated as many as possible.

**Steps:**
1. [Admin] Opens assignment in School-Allocated mode.
2. [Admin] Views class roster (student list) alongside available slots grid.
3. [Admin] Selects a student and an available slot; confirms allocation.
4. [System] Creates CONFIRMED booking (bypassing booking window check).
5. [System] Sends booking notification to parent (if enabled).
6. [Admin] Repeats for each student.
7. [Parent] Views their allocated slot in portal (read-only — no booking or rescheduling controls).

**Exception paths:**
- Student already allocated to a slot → system shows current allocation; admin can revoke and reallocate.
- More students than available slots → remaining students are marked "Not Allocated"; admin must add more slots or adjust the template.

---

### Workflow 4: Booking Cancellation

**Trigger:** Parent or admin initiates cancellation of a CONFIRMED booking.
**End States:** Booking CANCELLED, slot restored, notification sent.

**Steps:**
1. [Parent / Admin] Selects booking from list and requests cancellation.
2. [System — for parent] Checks cancellation lead time: if slot_start − now < lead_time_hours, parent cannot self-cancel.
3. [Parent / Admin] Optionally provides cancellation reason.
4. [Parent / Admin] Confirms cancellation.
5. [System] Sets booking to CANCELLED, records cancelled_at and reason.
6. [System] Decrements slot booked count; recalculates slot status (Full → Booked or Booked → Available).
7. [System] Sends cancellation notification (if enabled).

**Exception paths:**
- Lead time expired and actor is parent → "Cancellation is no longer available (less than X hours before the meeting). Please contact the school."
- Booking already CANCELLED / COMPLETED → operation rejected.

---

### Workflow 5: Post-Meeting Attendance Recording

**Trigger:** PTM day has passed; teacher reviews their bookings.
**End States:** All bookings marked Attended (COMPLETED) or No-Show; meeting notes added.

**Steps:**
1. [Teacher] Opens their post-meeting booking list for the event.
2. [System] Shows all CONFIRMED bookings for the teacher's assignments with attendance controls.
3. [Teacher] For each booking: marks Attended → booking becomes COMPLETED; or marks No-Show → booking becomes NO_SHOW.
4. [Teacher] Optionally adds meeting notes per booking.
5. [System] Records attendance and notes; updates booking status.

**Exception paths:**
- Teacher mistakenly marks No-Show for a student who was present → teacher or admin can correct by changing status back to COMPLETED.

---

## FRD — Section 7: Reporting & Analytics {#frd-section-7}

### RPT-PTM-001 — Event Booking Summary

| Attribute | Value |
|-----------|-------|
| Purpose | Overview of booking completion across an entire PTM event |
| Audience | School Administrator, Academic Coordinator |
| Frequency | On-demand during and after the event |
| Contents | Total slots, booked slots, available slots, blocked slots, cancelled slots, booking percentage; breakdown by class-section and by teacher |
| Filters | Event (required), class-section (optional) |
| Export | PDF, Excel |
| Rules | Booking percentage = confirmed bookings / (total slots − blocked slots) × 100 |

### RPT-PTM-002 — Teacher Schedule

| Attribute | Value |
|-----------|-------|
| Purpose | A teacher's complete meeting schedule for a PTM day |
| Audience | Class Teacher, School Administrator |
| Frequency | On-demand before and during event |
| Contents | Teacher name, event, date, time window; chronological slot list with slot time, student name, parent name, parent comment, attendance status, meeting notes field |
| Filters | Event (required), teacher (required) |
| Export | PDF (printable format for use on PTM day), Excel |
| Rules | Shows only slots belonging to the selected teacher; break slots shown as dividers |

### RPT-PTM-003 — Class-wise Booking Status

| Attribute | Value |
|-----------|-------|
| Purpose | Which students in a class have booked and which have not |
| Audience | School Administrator, Academic Coordinator, Class Teacher (own class) |
| Frequency | On-demand during the booking window |
| Contents | Class-section, event, list of students: name, roll number, booking status (Booked with slot time / Not Booked), teacher booked with |
| Filters | Event, class-section, booking status |
| Export | Excel, CSV |
| Rules | Students with CONFIRMED bookings show slot time; all others show "Not Booked" |

### RPT-PTM-004 — Attendance & No-Show Report

| Attribute | Value |
|-----------|-------|
| Purpose | Post-event participation analysis |
| Audience | School Administrator, Academic Coordinator |
| Frequency | After PTM day |
| Contents | Total meetings scheduled (confirmed bookings), attended count, no-show count, attendance rate %, no-show rate %; list of no-show students with teacher and slot time |
| Filters | Event, class-section, teacher |
| Export | PDF, Excel |
| Rules | Attendance rate = COMPLETED / (COMPLETED + NO_SHOW) × 100 (excludes CONFIRMED meetings not yet marked) |

### RPT-PTM-005 — Parent Booking History

| Attribute | Value |
|-----------|-------|
| Purpose | Individual parent's complete booking trail for audit and support |
| Audience | School Administrator, School Staff |
| Frequency | On-demand (typically for parent support queries) |
| Contents | Parent name, student, event history: event title, teacher, slot time, booking status, booked at, cancelled at, reason |
| Filters | Student (required), academic session |
| Export | PDF |
| Rules | Shows all booking statuses including CANCELLED and historical events; no cross-school data |

---

## FRD — Section 8: Future Enhancement Log {#frd-section-8}

| ID | Description | Priority | Effort Estimate | Dependency |
|----|-------------|----------|-----------------|------------|
| ENH-PTM-001 | Auto-allocation for School-Allocated mode: algorithm distributes students across available slots automatically, balancing load and avoiding conflicts | P1 → P0 on approval | 12h Backend | REQ-PTM-011 |
| ENH-PTM-002 | iCal / calendar export: parents and teachers can download their confirmed meetings as a calendar file (.ics) for Google Calendar, Outlook, etc. | P2 | 6h Backend | REQ-PTM-010 |
| ENH-PTM-003 | Video meeting link integration: direct integration with Zoom, Google Meet, or Teams APIs to auto-generate unique meeting links per booking rather than one link per class-section | P2 | 20h Integration | REQ-PTM-010 |
| ENH-PTM-004 | Reminder notifications: automated pre-meeting reminders sent 24 hours and 1 hour before the scheduled meeting time | P1 → on approval | 10h Backend (Job) | REQ-PTM-015 |
| ENH-PTM-005 | Teacher schedule PDF: printable one-page schedule with the teacher's complete slot list for the PTM day, formatted for offline use | P1 → P2 | 8h Backend | RPT-PTM-002 |
| ENH-PTM-006 | Bulk booking cancellation: when a slot is cancelled or an event is rescheduled, a bulk action cancels all affected bookings and notifies parents in one operation | P1 | 8h Backend | REQ-PTM-009 |
| ENH-PTM-007 | PTM Registration Fee: implement the payment sub-system (7 payment tables already exist in the database) to collect a registration fee per booking — gateway configuration, online/offline payment, refund, reconciliation, and audit trail | P2 | 60h (see payment tables in Module Knowledge) | Payment module |

---

## FRD — Section 9: Non-Functional Requirements {#frd-section-9}

### 9.1 Performance

- Slot generation for a full PTM event (100 teachers × 20 slots = 2,000 slots) must complete within 10 seconds.
- Parent booking page must load the available slot list within 2 seconds for any class-section with up to 50 slots.
- The management dashboard must calculate booking percentages within 1 second.
- Reports must generate within 5 seconds for events with up to 1,000 bookings.

### 9.2 Security

- All PTM data is scoped to a single school's database — no cross-school data access is possible by design (database-per-tenant architecture).
- Only authenticated users with the correct permissions may access any PTM screen — all routes protected.
- Parent users may only view or modify their own bookings (not other parents' bookings).
- Class teachers may manage only their own assignments, blockouts, and attendance records.
- Admin booking cancellation must be logged with the acting user's identity and reason.
- The booking uniqueness constraint (one confirmed booking per student per teacher per event) must be enforced at both application and database level. [Currently the DB-level constraint is degraded — see Known Gaps P0 in Module Knowledge.]
- Meeting notes entered by a teacher are confidential to the school (teacher + admin only) and must not appear in any parent-facing view or export.

### 9.3 Usability

- A parent must be able to complete a slot booking in 3 steps or fewer after selecting the event.
- Empty states must explain the next action (e.g. "No classes have been scheduled for this event yet — return after the schedule is published.").
- The teacher's post-meeting attendance list must load pre-populated with all confirmed bookings for that day — no manual search required.
- All date and time display must use the IST (Indian Standard Time) timezone consistently.
- The combined management view must provide single-screen access to setup, scheduling, and bookings without requiring navigation across three separate menu sections.

---

## FRD — Section 10: Gap Analysis Readiness Index {#frd-section-10}

### 10.1 Coverage Table

| REQ ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|--------|---------|----------|------|:-----------------:|:-------------:|:----------:|:-------------------:|:----------------:|
| REQ-PTM-001 | PTM Event Management | P0 | CONFIGURATION, DATA_ENTRY | Yes (ptm_events) | Yes | No | No | Yes |
| REQ-PTM-002 | Class-Section Event Scheduling | P0 | CONFIGURATION, DATA_ENTRY | Yes (jnt table) | Yes | No | No | Yes |
| REQ-PTM-003 | Meeting Batch Template Management | P0 | CONFIGURATION, DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-PTM-004 | Batch Time Grid Management | P1 | CONFIGURATION, DATA_ENTRY | Yes (slot template) | Yes | No | No | Yes |
| REQ-PTM-005 | Teacher-Class Assignment | P0 | WORKFLOW, DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-PTM-006 | Multi-Teacher Sub-Batch Assignment | P1 | CONFIGURATION, DATA_ENTRY | Yes (jnt table) | Yes | No | No | Yes |
| REQ-PTM-007 | Teacher Unavailability Management | P0 | DATA_ENTRY, WORKFLOW | Yes (blockouts) | Yes | No | No | Yes |
| REQ-PTM-008 | Meeting Slot Generation | P0 | WORKFLOW, SCHEDULED | Yes (ptm_slots) | Yes (dashboard) | No | No | Yes |
| REQ-PTM-009 | Slot Lifecycle Management | P1 | WORKFLOW, DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-PTM-010 | Parent Self-Booking (Parent-Pick) | P0 | WORKFLOW, DATA_ENTRY | Yes (bookings) | Yes (ParentPortal) | Yes | Yes | Yes |
| REQ-PTM-011 | School-Allocated Booking | P1 | WORKFLOW, DATA_ENTRY | Yes | Yes | No | Yes | Yes |
| REQ-PTM-012 | Booking Cancellation | P0 | WORKFLOW | No (existing) | Yes | No | Yes | Yes |
| REQ-PTM-013 | Booking Rescheduling | P1 | WORKFLOW | No (existing) | Yes | No | Yes | Yes |
| REQ-PTM-014 | Post-Meeting Attendance & Notes | P1 | DATA_ENTRY, WORKFLOW | No (existing) | Yes | No | No | Yes |
| REQ-PTM-015 | Booking Notifications | P1 | NOTIFICATION | No (existing) | No | No | Yes | Yes |
| REQ-PTM-016 | Management Dashboard & Analytics | P1 | DASHBOARD, REPORT | No (existing) | Yes | Yes (AJAX) | No | Yes |
| REQ-PTM-017 | PTM Reporting | P2 | REPORT | No (existing) | Yes | No | No | Yes |

### 10.2 Business Rule Coverage

| BR ID | Rule Summary | DDL Enforced | Code Enforced | Test Coverage |
|-------|-------------|:---:|:---:|:---:|
| BR-PTM-001 | Event code uniqueness | Yes (UNIQUE key) | Yes | No |
| BR-PTM-002 | Date range validation | No | Yes (FormRequest) | No |
| BR-PTM-003 | Booking window enforcement | No | Yes (Service) | No |
| BR-PTM-004 | No teacher double-booking | Yes (UNIQUE on slot) | Yes (overlap check) | No |
| BR-PTM-005 | One confirmed booking per student/teacher/event | Partial (degraded — D36) | Yes (Service check) | No |
| BR-PTM-006 | Slot capacity enforcement | No | Yes (Service) | No |
| BR-PTM-007 | Cancellation lead time | No | Yes (Service) | No |
| BR-PTM-008 | Reschedule = cancel + re-book | No | Yes (Service transaction) | No |
| BR-PTM-009 | Three-level parameter fallback | No | Yes (Service) | No |
| BR-PTM-010 | Publish triggers slot generation | No | Yes (Controller/Service) | No |
| BR-PTM-011 | Blockout masks slots | No | Yes (Service) | No |
| BR-PTM-012 | Blocked slots cannot be booked | No | Yes (Service) | No |
| BR-PTM-013 | Assignment delete protection | No | Not verified | No |
| BR-PTM-014 | Event cascade soft-delete | Yes (ON DELETE CASCADE for hard FKs) | Partial (soft-delete cascade unverified) | No |
| BR-PTM-015 | Unpublish warning with bookings | No | Not verified | No |

### 10.3 Report Coverage

| RPT ID | Report | Screen Built | Export Built |
|--------|--------|:---:|:---:|
| RPT-PTM-001 | Event Booking Summary | Partial (AJAX widgets) | No |
| RPT-PTM-002 | Teacher Schedule | Partial (AJAX) | No |
| RPT-PTM-003 | Class-wise Booking Status | No | No |
| RPT-PTM-004 | Attendance & No-Show Report | No | No |
| RPT-PTM-005 | Parent Booking History | No | No |

### 10.4 Totals

| Metric | Count |
|--------|-------|
| Total Requirements (REQ) | 17 |
| P0 (Core) Requirements | 8 |
| P1 (Standard) Requirements | 8 |
| P2 (Enhanced) Requirements | 1 |
| Total Business Rules (BR) | 15 |
| Total Reports (RPT) | 5 |
| Total Enhancements (ENH) | 7 |
| Total Workflows | 5 |
| Total NFRs | 9 |
| Total Risks | 8 |
| Total User Stories (P0+P1) | 8 |

---

## Requirements Traceability Matrix (RTM) {#rtm}

| REQ ID | Feature | BR Refs | Screen(s) | Workflow(s) | Report(s) | Code Status | Gap |
|--------|---------|---------|-----------|-------------|-----------|-------------|-----|
| REQ-PTM-001 | PTM Event Management | BR-001, 002, 014 | ptm-event (CRUD + trash) | WF-1 | RPT-001 | BUILT (full CRUD, service, policy) | No tests; cascade soft-delete unverified |
| REQ-PTM-002 | Class-Section Scheduling | BR-002 | ptm-event-class-section (CRUD) | WF-1 | — | BUILT | No tests |
| REQ-PTM-003 | Batch Template Management | BR-009 | ptm-batch-template (CRUD) | WF-1 | — | BUILT | No tests |
| REQ-PTM-004 | Batch Time Grid | BR-009 | ptm-batch-slot-template (CRUD) | WF-1 | — | BUILT | No tests; static vs dynamic generation edge cases untested |
| REQ-PTM-005 | Teacher-Class Assignment | BR-010, 013, 015 | ptm-assignment (CRUD + publish) | WF-1 | — | BUILT | Unpublish warning BR-015 unverified; delete protection BR-013 unverified |
| REQ-PTM-006 | Multi-Teacher Sub-Batch | BR-004 | ptm-assignment-teacher (CRUD) | WF-1 | — | BUILT | No tests |
| REQ-PTM-007 | Teacher Blockout | BR-011, 012 | ptm-blockout (CRUD) | WF-1 | — | BUILT | No tests; sync service verified in code |
| REQ-PTM-008 | Slot Generation | BR-004, 009, 010, 011 | management dashboard | WF-1 | RPT-001 | BUILT (PtmSlotService) | No tests; regeneration with bookings warning unverified |
| REQ-PTM-009 | Slot Lifecycle Management | BR-012, 013 | ptm-slot (CRUD) | — | — | PARTIAL | No block/unblock with bookings validation; no tests |
| REQ-PTM-010 | Parent Self-Booking | BR-003, 005, 006, 012 | ptm-slot-booking / ParentPortal | WF-2 | — | PARTIAL | ParentPortal integration unimplemented; race condition (no FOR UPDATE); booking uniqueness DB constraint degraded (D36) |
| REQ-PTM-011 | School-Allocated Booking | BR-003 bypass, 005 | ptm-slot-booking admin view | WF-3 | — | PARTIAL | No dedicated admin allocation screen; auto-allocation not built |
| REQ-PTM-012 | Booking Cancellation | BR-007, 006 | ptm-slot-booking / cancel route | WF-4 | — | BUILT (cancel action) | Lead-time validation built; no tests |
| REQ-PTM-013 | Rescheduling | BR-008, 007 | ptm-slot-booking / reschedule | WF-4 | — | BUILT (reschedule action) | No tests |
| REQ-PTM-014 | Post-Meeting Attendance | — | ptm-slot-booking views | WF-5 | RPT-004 | PARTIAL | attended field exists; no dedicated post-meeting view |
| REQ-PTM-015 | Notifications | — | (none — background) | all | — | PARTIAL | Synchronous; uses session('tenant_id'); Notification routes commented out |
| REQ-PTM-016 | Management Dashboard | — | management/ views (10) | — | — | PARTIAL | AJAX endpoints built; booking % widgets limited |
| REQ-PTM-017 | PTM Reporting | — | (not built) | — | RPT-001…005 | NOT STARTED | All 5 reports missing dedicated screens and exports |

---

## Process Flows + FSM Catalog {#process-flows}

### Process Flow 1: PTM Event Setup to First Booking

```
[Admin] Create Event
    ↓
[Admin] Add Class-Section Schedules (one per participating class)
    ↓
[Teacher / Admin] Create Batch Templates
    ↓
[Admin] Create Assignments (event + class-section + template + teacher + mode)
    ↓ (optional)
[Admin / Teacher] Create Blockouts
    ↓
[Admin] Publish Assignment → [System] Generate Slots (break/blockout slots = BLOCKED)
    ↓
[System] Booking window opens at configured date-time
    ↓
[Parent] Logs in → selects event → selects child → selects teacher → selects slot → confirms
    ↓
[System] Creates CONFIRMED Booking; updates slot booked count; sends notification
```

Exception: Double-booking detected at generation time → Admin must adjust templates and regenerate.

---

### Process Flow 2: Blockout Lifecycle

```
[Admin / Teacher] Creates Blockout (event, optional teacher, date, time window)
    ↓
[System] Finds all slots under event that overlap the blockout
    ↓
[System] Sets overlapping slots to BLOCKED (except already-Completed slots)
    ↓ (later)
[Admin / Teacher] Deletes Blockout
    ↓
[System] Finds slots that were Blocked solely due to this blockout (no other blockout applies, not a break)
    ↓
[System] Restores each such slot to: Available (if booked_count=0), Booked (0<booked_count<capacity), Full (booked_count=capacity)
```

Note: Existing confirmed bookings in the blocked window are NOT automatically cancelled.

---

### FSM: Meeting Slot Status

```
States: AVAILABLE → BOOKED → FULL
                          ↓               ↓
                      BLOCKED ←←←←←←← any of the above (admin block or blockout overlap)
                          ↑
               (blockout removed) ← any above state

        AVAILABLE / BOOKED / FULL / BLOCKED → CANCELLED (admin action)
        AVAILABLE / BOOKED / FULL / BLOCKED / CANCELLED → COMPLETED (time passed + admin marks)

Terminal states: COMPLETED, CANCELLED (cannot revert)

Guards:
  AVAILABLE → BOOKED: first booking confirmed (booked_count becomes 1, still < capacity)
  BOOKED → FULL: confirmed bookings reach capacity
  FULL → BOOKED: a booking is cancelled (booked_count drops below capacity)
  BOOKED / FULL → AVAILABLE: all bookings cancelled (booked_count = 0)
  any → BLOCKED: admin manual block OR blockout overlap detected
  BLOCKED → previous: admin unblock OR blockout removed (only if no other blockout applies; break slots remain BLOCKED permanently)
  any non-Completed → CANCELLED: admin slot cancellation (cascades to cancel all bookings)

Side-effects:
  → BOOKED: parent booking count incremented
  → FULL: parent sees "Full" / slot hidden from new booking interface
  → BLOCKED: slot hidden from parent booking interface
  → CANCELLED: all CONFIRMED bookings on this slot are cancelled; notifications sent
  → COMPLETED: booking list shows as historical
```

---

### FSM: Booking Status

```
States: CONFIRMED → CANCELLED (parent self-cancel within lead time, or admin cancel any time)
                 → NO_SHOW (teacher marks after slot time)
                 → COMPLETED (teacher marks as attended)
                 → RESCHEDULED (treated as CANCELLED with a new CONFIRMED booking created)

Terminal states: COMPLETED, NO_SHOW (no re-activation after the fact — admin can correct via status update)

Guards:
  new → CONFIRMED: booking window open (or admin bypass); slot Available/Booked; uniqueness pass; capacity pass
  CONFIRMED → CANCELLED: lead time not expired (parent) OR admin role
  CONFIRMED → RESCHEDULED: allow_reschedule = Yes (or admin) AND lead time not expired; new slot must be valid
  CONFIRMED → NO_SHOW: slot time has passed; actor is teacher or admin
  CONFIRMED → COMPLETED: slot time has passed; actor is teacher or admin

Side-effects:
  → CONFIRMED: slot booked_count +1; slot status updated; notification to parent
  → CANCELLED: slot booked_count -1; slot status recalculated; notification to parent
  → NO_SHOW: no slot change; optional notification
  → COMPLETED: no slot change; optional notification
  → RESCHEDULED: old slot decremented; new booking created as CONFIRMED; notifications fired
```

---

### FSM: Assignment Publish State

```
States: DRAFT → PUBLISHED

Guards:
  DRAFT → PUBLISHED: class-section schedule exists; batch template has at least one grid entry or a valid window; primary teacher assigned

Side-effects:
  → PUBLISHED: slot generation executed; published_at timestamp recorded; slots visible to parents

Reverse: PUBLISHED → DRAFT (unpublish): allowed with warning if confirmed bookings exist
```

---

## Data Dictionary (Business View) {#data-dictionary}

*This section provides the business-language view. For the technical column-level mapping see the Module Knowledge file and DDL v3.*

### Entity: PTM Event
Represents a named parent-teacher meeting occasion. Contains all event-level settings that govern how the meeting will run. Everything else (class schedules, assignments, slots, bookings) is a child of this entity.

### Entity: Class-Section Schedule
Specifies which class-section will participate in a PTM event, on which date, and in what time window and venue. Ensures each class has exactly one scheduled date per event.

### Entity: Batch Template
A reusable time blueprint created by a teacher. Defines the bounds of a teacher's meeting block and the per-slot parameters. Decoupled from any specific event so it can be reused across terms.

### Entity: Slot Grid Entry
One line in the batch template's schedule — a specific time window, with a flag indicating whether it is a bookable meeting slot or an unbookable break. The grid is the source from which concrete slots are generated.

### Entity: Assignment
The connector record that activates a PTM schedule for a class. Links the template, the class-section date, and the teacher. Its Published flag is the on/off switch for parent visibility.

### Entity: Sub-Batch Teacher
An extension to an assignment that supports a class being split between multiple teachers running in parallel. Each sub-batch teacher has their own set of slots and an optional student filter.

### Entity: Blockout
An interval during which a teacher is unavailable. Automatically propagates to mask affected slots. The teacher's guard against being double-scheduled.

### Entity: Meeting Slot
The concrete, dated, wall-clock time slot that a parent can book. Generated from the Batch Template grid and the Class-Section Schedule date. Carries live capacity and booking count.

### Entity: Booking
A parent's reservation of a meeting slot for their child. The core transactional record of the PTM module. Carries the full lifecycle history through status transitions.

---

## Cross-Module Dependency Map {#dependency-map}

### Inbound (PTM reads from these modules)

| Source Module | Tables Accessed | Data Used | Why |
|---------------|----------------|-----------|-----|
| SchoolSetup | `sch_class_section_jnt` | Class-section membership | Scheduling which classes participate |
| SchoolSetup | `sch_rooms` | Room data | Room assignment for in-person meetings |
| SchoolSetup | `sys_users` | Staff identity | Teacher and creator identification |
| SchoolSetup | `sch_org_academic_sessions_jnt` | Academic session | Anchoring events to academic year |
| TimetableFoundation | `sch_academic_terms` | Term data | Anchoring events to academic term |
| StudentProfile | `std_students` | Student identity | Booking: which student the meeting is for |

### Outbound (PTM feeds into these modules)

| Target Module | Mechanism | Data Pushed | Purpose |
|---------------|-----------|-------------|---------|
| Notification | `Notification::create()` (direct model write, synchronous) | Booking and cancellation events | Parent and teacher alerts |
| ParentPortal | Service layer calls (undocumented — P1 gap) | Available slots, confirmed bookings | Parent self-booking interface |

### Integration Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Notification module routes are globally commented out | All PTM notifications fail silently | Restore Notification module routes (separate fix) |
| PTM creates Notification model records directly (no event dispatch) | Notification failure inside DB transaction can cause booking rollback | Convert to queued Job (ENH-PTM-004) |
| ParentPortal integration contract undefined | Parent-Pick mode is unusable until ParentPortal connects to PTM service layer | Document and implement integration (see PARENT-PTM-001) |
| Payment tables orphaned | PTM registration fee collection non-functional | Implement payment sub-system or clarify module ownership |

---

## NFR Catalog + Risk Register {#nfr-risk}

### NFR Catalog

| ID | Category | Requirement | Acceptance Threshold |
|----|----------|-------------|---------------------|
| NFR-PTM-001 | Performance | Slot generation for a full 100-teacher event (2,000 slots) | ≤ 10 seconds |
| NFR-PTM-002 | Performance | Parent slot-list page load | ≤ 2 seconds for ≤ 50 slots |
| NFR-PTM-003 | Performance | Management dashboard booking metrics | ≤ 1 second |
| NFR-PTM-004 | Performance | Report generation (≤ 1,000 bookings) | ≤ 5 seconds |
| NFR-PTM-005 | Security | All PTM data scoped to school's database | Zero cross-tenant data access — by architecture |
| NFR-PTM-006 | Security | Booking uniqueness enforced at both application and DB level | Zero duplicate confirmed bookings per student per teacher per event |
| NFR-PTM-007 | Security | Meeting notes visible to teacher and admin only | Meeting notes never appear in parent-facing views or exports |
| NFR-PTM-008 | Usability | Parent booking completion | ≤ 3 steps after selecting event |
| NFR-PTM-009 | Availability | PTM booking service during event booking window | ≥ 99.5% uptime; graceful rejection (not silent failure) on concurrent full-slot scenario |

### Risk Register

| ID | Risk | Category | Likelihood | Impact | Mitigation | Owner |
|----|------|----------|:----------:|:------:|-----------|-------|
| RISK-PTM-001 | Booking uniqueness DB constraint degraded (D36) — duplicate confirmed bookings possible | Technical / Data Integrity | H | H | Fix `active_booking_key` migration to use `virtualAs`; add Pest test for concurrent booking | Dev |
| RISK-PTM-002 | Race condition on last slot (no pessimistic lock) — two parents confirm the same full slot | Technical / Concurrency | M | M | Add `SELECT ... FOR UPDATE` on slot row during booking transaction | Dev |
| RISK-PTM-003 | Notification module routes globally commented out — all PTM notifications silently fail | Technical / Integration | H (known) | M | Fix Notification module (separate work item); add queue-level retry | Dev |
| RISK-PTM-004 | ParentPortal–PTM integration undocumented — parent-pick mode unusable | Technical / Integration | H | H | Document and implement service contract between ParentPortal and PtmSlotBookingService | Dev / BA |
| RISK-PTM-005 | 7 payment tables with zero models — PTM registration fees cannot be collected if required | Technical / Business | L | H | Clarify whether PTM fees are in scope; implement or defer to ENH-PTM-007 | PM / Dev |
| RISK-PTM-006 | Zero test coverage — regressions in booking rules (BR-005, BR-007, BR-009) undetected | Technical / Quality | H | H | Write Pest test suite (20+ cases) before any production deployment | Dev / QA |
| RISK-PTM-007 | Synchronous notifications inside DB transactions — notification error causes booking rollback | Technical / Reliability | M | M | Extract to queued Job (ENH-PTM-004) | Dev |
| RISK-PTM-008 | ENUM fields (allocation_mode, meeting_mode, status) violate D29 — schools cannot extend values without migration | Architecture / Compliance | L | L | Plan D29 migration to sys_dropdown_table for v4 of the PTM DDL (defer to after core gaps are resolved) | Arch |

---

## Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks {#prioritization}

### MoSCoW Prioritization

**Must (P0 — Core):**
REQ-PTM-001 Event Management, REQ-PTM-002 Class Scheduling, REQ-PTM-003 Batch Templates, REQ-PTM-005 Assignments, REQ-PTM-007 Blockouts, REQ-PTM-008 Slot Generation, REQ-PTM-010 Parent Self-Booking, REQ-PTM-012 Cancellation — These are the scheduling backbone. Without them there is no PTM.

**Should (P1 — Standard):**
REQ-PTM-004 Slot Grid, REQ-PTM-006 Multi-Teacher, REQ-PTM-009 Slot Lifecycle, REQ-PTM-011 School-Allocated, REQ-PTM-013 Rescheduling, REQ-PTM-014 Attendance, REQ-PTM-015 Notifications, REQ-PTM-016 Dashboard — Important for complete operations but the system can run without them in a first release.

**Could (P2 — Enhanced):**
REQ-PTM-017 Reporting — Useful but can be deferred.

**Won't (this release):**
Video meeting platform integration (ENH-PTM-003), D29 ENUM migration (RISK-PTM-008), partitioning of slot/booking tables.

### Effort Estimation — Remaining Work

| # | Task | Type | Effort (h) | Sprint | Depends On |
|---|------|------|------------|--------|------------|
| 1 | Fix `active_booking_key` migration — add `virtualAs` generated column expression | Schema | 2h | R1 | — |
| 2 | Add `SELECT ... FOR UPDATE` on slot in `PtmSlotBookingService::create()` | Backend | 3h | R1 | — |
| 3 | Verify / add `Gate::authorize` to all PtmManagementController AJAX routes | Backend | 3h | R1 | — |
| 4 | Write Pest tests: slot generation (static + dynamic modes, blockout masking) | Testing | 10h | R1 | — |
| 5 | Write Pest tests: booking create, uniqueness, capacity, cancellation, reschedule | Testing | 12h | R1 | — |
| 6 | Write Pest tests: blockout sync with slot statuses | Testing | 5h | R1 | — |
| 7 | Verify assignment delete protection (BR-PTM-013) and add if missing | Backend | 3h | R1 | — |
| 8 | Verify unpublish warning (BR-PTM-015) and implement if missing | Backend | 4h | R1 | — |
| 9 | PTM Payment sub-system: models for 7 payment tables | Schema/Backend | 8h | R2 | Task 1 |
| 10 | PTM Payment Gateway controller + views (online gateway config) | Backend/Frontend | 12h | R2 | Task 9 |
| 11 | PTM Payment service: create payment, verify, refund | Backend | 15h | R2 | Task 9 |
| 12 | PTM Offline payment + reconciliation screens | Backend/Frontend | 10h | R2 | Task 9 |
| 13 | Document ParentPortal–PTM integration contract | Analysis | 4h | R3 | — |
| 14 | ParentPortal: implement parent-pick booking flow (connect to PtmSlotBookingService) | Frontend/Backend | 16h | R3 | Task 13 |
| 15 | Extract PTM notifications to queued Job (PtmBookingNotificationJob) | Backend | 8h | R3 | — |
| 16 | Report: Event Booking Summary screen + PDF/Excel export (RPT-PTM-001) | Backend/Frontend | 8h | R3 | — |
| 17 | Report: Teacher Schedule screen + PDF export (RPT-PTM-002) | Backend/Frontend | 8h | R3 | — |
| 18 | Report: Class-wise Booking Status + Excel export (RPT-PTM-003) | Backend/Frontend | 6h | R3 | — |
| 19 | Report: Attendance & No-Show report (RPT-PTM-004) | Backend/Frontend | 6h | R3 | — |
| 20 | Report: Parent Booking History (RPT-PTM-005) | Backend/Frontend | 5h | R3 | — |
| 21 | Admin school-allocated booking screen (student roster + slot grid) | Frontend/Backend | 12h | R3 | — |
| 22 | Auto-allocation algorithm for SCHOOL_ALLOCATED mode (ENH-PTM-001) | Backend | 12h | R4 | Task 21 |
| 23 | Pre-meeting reminder notifications (T-24h, T-1h) via scheduled job | Backend | 10h | R4 | Task 15 |
| 24 | iCal calendar export for confirmed bookings (ENH-PTM-002) | Backend | 6h | R4 | — |
| 25 | Teacher schedule PDF (ENH-PTM-005) | Backend | 8h | R4 | Task 17 |

**Sprint Summary:**

| Sprint | Focus | Estimated Hours |
|--------|-------|----------------|
| R1 | P0 security + correctness fixes + test suite | ~42h |
| R2 | Payment sub-system | ~45h |
| R3 | ParentPortal integration + notifications async + reports + admin allocation | ~73h |
| R4 | Enhancements (auto-alloc, reminders, exports) | ~36h |
| **Total remaining** | | **~196h** |

Estimated completed to date: ~150h (core CRUD, services, 9 entities, views, 6 services).
**Total estimated module effort: ~346h**

---

## User Stories + Acceptance Criteria + Reporting & KPI Spec {#user-stories}

### US-PTM-001 | Priority P0 | REQ ref: REQ-PTM-001

**As a School Administrator, I want to create a PTM event for the academic term so that all scheduling for that parent-teacher meeting flows under one named container.**

```
Scenario: Successful event creation
  Given I am logged in as School Administrator
  When I fill in all required event fields (code, title, session, dates, booking window, defaults)
  And I submit the create form
  Then a new PTM event is created with status Active
  And I am redirected to the event detail page
  And the event appears in the event list

Scenario: Duplicate event code rejected
  Given an event with code "PTM-T1-2526" already exists for this school
  When I try to create another event with code "PTM-T1-2526"
  Then the form is rejected with the message "This event code already exists"
  And no event is created

Scenario: Invalid date range rejected
  Given I enter an event end date that is before the start date
  When I submit the form
  Then the form is rejected with the message "End date must be on or after start date"

Scenario: Insufficient permission
  Given I am logged in as a Class Teacher (not an admin)
  When I try to access the Create Event screen
  Then I receive an access denied response
```

**Definition of Done:** Event created and visible in list. Code uniqueness enforced. Date validation enforced. Audit log entry created. Academic session and term correctly linked. Activation toggle functional.

---

### US-PTM-002 | Priority P0 | REQ ref: REQ-PTM-002

**As a School Administrator, I want to add the participating class-sections to a PTM event so that each class has a scheduled date and operating window.**

```
Scenario: Add class-section to event
  Given a PTM event exists
  When I add Class 10-A with date 10 May 2026, window 9:00-13:00, mode In-Person, Room 101
  Then 10-A is listed as a participating class for this event

Scenario: Duplicate class-section rejected
  Given 10-A is already added to this event
  When I try to add 10-A again
  Then the form is rejected with "This class-section is already scheduled for this event"

Scenario: Scheduled date outside event range
  Given the event runs 10 May – 15 May 2026
  When I set a class-section's scheduled date to 20 May 2026
  Then the form is rejected with "Scheduled date must fall within the event dates"
```

---

### US-PTM-003 | Priority P0 | REQ ref: REQ-PTM-003

**As a Class Teacher, I want to create a reusable batch template so that I can apply the same meeting time structure across different PTM events without re-entering it each time.**

```
Scenario: Create batch template
  Given I am logged in as a Class Teacher
  When I create a template "Morning 9-11 AM, 10 min slots" with window 09:00-11:00, duration 10 min, buffer 0 min, capacity 1
  Then the template is saved and assigned to me as owner

Scenario: Template reuse
  Given I published an assignment last term using my template
  When I create a new assignment for this term
  Then my template appears in the template dropdown and can be selected

Scenario: Non-owner cannot edit teacher's template
  Given Teacher A owns template "Morning 9-11 AM"
  When Teacher B (different teacher) tries to edit that template
  Then access is denied
```

---

### US-PTM-005 | Priority P0 | REQ ref: REQ-PTM-005

**As a School Administrator, I want to assign a teacher and batch template to a class-section within a PTM event and publish the assignment so that meeting slots are generated and parents can begin booking.**

```
Scenario: Create and publish assignment
  Given a class-section schedule exists and a batch template exists
  When I create an assignment linking them with Teacher: Mrs. Sharma, Mode: Parent-Pick
  And I click Publish
  Then the assignment status becomes Published
  And the system generates meeting slots from the template
  And break-flagged grid entries become Blocked slots
  And blockout-overlapping slots become Blocked slots

Scenario: Publish with no batch slot grid
  Given a batch template with no slot grid entries and no window time set
  When I try to publish the assignment
  Then publishing is rejected with "Batch template has no valid slot grid — add slot grid entries or set a window with duration"

Scenario: Assignment with bookings cannot be deleted
  Given an assignment has 3 confirmed bookings
  When I try to delete the assignment
  Then the delete is rejected with "This assignment has 3 confirmed bookings — cancel them before deleting"
```

---

### US-PTM-007 | Priority P0 | REQ ref: REQ-PTM-007

**As a Class Teacher, I want to mark my lunch break as unavailable during a PTM day so that no parent is accidentally booked during that time.**

```
Scenario: Create teacher-specific blockout
  Given I am Mrs. Sharma, assigned to 10-A on 10 May 2026
  When I create a blockout for 10 May, 12:00–13:00, reason "Lunch"
  Then slots I own between 12:00–13:00 on 10 May are changed to Blocked
  And parents cannot book those slots

Scenario: Create school-wide blockout
  Given I am an administrator
  When I create a blockout with no specific teacher for 10:00–10:30, reason "Morning Assembly"
  Then ALL teachers' slots between 10:00–10:30 are changed to Blocked

Scenario: Remove blockout restores slots
  Given a blockout exists covering Mrs. Sharma's 12:00–13:00 slots
  And none of those slots have confirmed bookings
  When I delete the blockout
  Then Mrs. Sharma's 12:00–13:00 slots are restored to Available
```

---

### US-PTM-008 | Priority P0 | REQ ref: REQ-PTM-008

**As a School Administrator, I want the system to automatically generate meeting slots when I publish an assignment so that I do not have to create each slot manually.**

```
Scenario: Slot generation on publish (static grid)
  Given assignment uses a batch template with 12 grid entries (10 meeting + 1 break + 1 buffer)
  When I publish the assignment
  Then 10 Available slots, 1 Blocked break slot, and 1 Blocked buffer slot are created for 10 May

Scenario: Slot generation with dynamic calculation
  Given assignment uses a batch template with window 09:00–11:00, duration 10 min, buffer 2 min (no explicit grid)
  When I publish
  Then the system generates 10 Available slots with 2-minute gaps (9:00, 9:12, 9:24 … 9:48, 10:00, …)

Scenario: Regeneration warns about existing bookings
  Given an assignment has 3 confirmed bookings
  When I click Regenerate Slots
  Then a warning appears: "3 confirmed bookings exist — regeneration will delete and recreate all slots. Parents with bookings will need to rebook. Proceed?"
  And slots are regenerated only after I confirm
```

---

### US-PTM-010 | Priority P0 | REQ ref: REQ-PTM-010

**As a Parent, I want to log in and book an available meeting slot with my child's class teacher so that I have a confirmed appointment time during the PTM.**

```
Scenario: Successful parent self-booking
  Given I am logged in as a parent with child enrolled in Class 10-A
  And the PTM event is in the booking window
  And Teacher Mrs. Sharma has Available slots
  When I select Mrs. Sharma's 09:00 AM slot and add the comment "Want to discuss maths"
  And I confirm the booking
  Then a CONFIRMED booking is created for my child with Mrs. Sharma at 09:00 AM
  And I receive a booking confirmation notification
  And the slot shows Booked in its status

Scenario: Booking outside window rejected
  Given the booking window has closed
  When I try to book a slot
  Then I see "Booking for this event is closed" and cannot proceed

Scenario: Duplicate booking with same teacher rejected
  Given I already have a confirmed booking with Mrs. Sharma for this event
  When I try to book another slot with Mrs. Sharma for the same child
  Then I see "You already have a confirmed booking with this teacher for this event"

Scenario: Full slot rejected
  Given a 1-on-1 slot is Full (booked_count = 1 = capacity)
  When I try to book that slot
  Then I see "That slot is no longer available — please choose another"
```

**Definition of Done:** Booking created as CONFIRMED. Slot booked_count updated. Notification dispatched. "My Bookings" shows the confirmed booking. Lead time information visible to parent.

---

### US-PTM-012 | Priority P0 | REQ ref: REQ-PTM-012

**As a Parent, I want to cancel a confirmed booking if my plans change so that the slot becomes available for another parent.**

```
Scenario: Successful self-cancellation within lead time
  Given I have a CONFIRMED booking for a slot 25 hours away
  And the event cancellation lead time is 24 hours
  When I cancel the booking with reason "Family emergency"
  Then the booking status becomes CANCELLED
  And the slot's booked count decreases
  And the slot status returns to Available
  And I receive a cancellation notification

Scenario: Self-cancellation blocked after lead time
  Given the slot is 12 hours away and lead time is 24 hours
  When I try to cancel
  Then the Cancel button is disabled
  And I see "Cancellation is not available — less than 24 hours until your meeting. Please contact the school."

Scenario: Admin can cancel after lead time
  Given the slot is 2 hours away (within lead time)
  When a School Administrator cancels the booking on my behalf
  Then the booking is cancelled and the slot availability is restored
```

---

### Reporting & KPI Spec

| KPI | Definition (business) | Source | Target | Cadence |
|-----|----------------------|--------|--------|---------|
| Booking Completion Rate | Confirmed bookings ÷ (Total available slots) × 100 | RPT-PTM-001 | ≥ 80% per event | Per event |
| Attendance Rate | Completed meetings ÷ (Completed + No-Show) × 100 | RPT-PTM-004 | ≥ 70% | Per event |
| No-Show Rate | No-Show count ÷ Confirmed bookings × 100 | RPT-PTM-004 | ≤ 15% | Per event |
| Booking Cancellation Rate | Cancelled bookings ÷ Total bookings made × 100 | RPT-PTM-001 | ≤ 10% | Per event |
| Slot Utilisation Rate | (Total slots − Blocked slots) used as confirmed ÷ (Total slots − Blocked) × 100 | RPT-PTM-001 | ≥ 75% | Per event |
| Teacher Availability Ratio | Non-blocked available slots ÷ Total generated slots × 100 | RPT-PTM-002 | ≥ 60% per teacher per event | Per event |

---

## Requirement Conditions Catalog + Validation & Edge-Case Catalog {#conditions}

### Requirement Conditions Catalog

*(Reuses BR- IDs — no parallel numbering)*

| Condition ID | Entity / Field | Condition | Type | Trigger | On-Violation Behaviour |
|--------------|----------------|-----------|------|---------|----------------------|
| BR-PTM-001 | PTM Event / Event Code | Code must be unique within the school | Validation | Create / Edit | Save rejected: "Event code already in use" |
| BR-PTM-002 | PTM Event / Dates | event_end_date ≥ event_start_date | Validation | Create / Edit | Save rejected: "End date must be on or after start date" |
| BR-PTM-002 | PTM Event / Booking Window | booking_window_end > booking_window_start | Validation | Create / Edit | Save rejected: "Booking window end must be after start" |
| BR-PTM-003 | Booking / Booking Window | NOW ≥ booking_window_start AND NOW ≤ booking_window_end (self-booking only) | Workflow | Booking creation (parent) | Booking rejected: "Booking window is closed" |
| BR-PTM-004 | Meeting Slot / Teacher + Start Time | (teacher_id, slot_start) must be unique within the event | Validation | Slot generation / manual slot create | Generation error shown; DB unique constraint enforces at insert |
| BR-PTM-005 | Booking / Student-Teacher-Event | Only one CONFIRMED booking per student per teacher per event | Validation | Booking creation | Booking rejected: "Already have a confirmed booking with this teacher" |
| BR-PTM-006 | Booking / Slot Capacity | booked_count < capacity AND status ≠ FULL, BLOCKED, CANCELLED | Validation | Booking creation | Booking rejected with slot status shown |
| BR-PTM-007 | Booking / Cancellation | slot_start − NOW ≥ cancellation_lead_time_hours (self-cancel) | Validation | Self-cancellation | Action prevented; message: "Cannot cancel within X hours of meeting" |
| BR-PTM-008 | Booking / Reschedule | allow_reschedule = true AND lead time not expired (self-reschedule) | Workflow | Reschedule initiation | Reschedule option not shown; or rejected with explanation |
| BR-PTM-009 | Slot Generation / Parameters | Duration = assignment_override OR template_value OR event_default | Calculation | Slot generation | System resolves chain; never NULL (event default always set) |
| BR-PTM-010 | Assignment / Publish | Publishing triggers slot delete + regeneration | Workflow | Assignment publish action | Generation executes transactionally; failure rolls back publish |
| BR-PTM-011 | Slot / Blockout Overlap | Slots overlapping a blockout become BLOCKED | Workflow | Blockout create / delete | Slot statuses updated by sync service |
| BR-PTM-012 | Booking / Slot Status | Slot must be Available or Booked (with capacity) | Validation | Booking creation | Rejected with slot status |
| BR-PTM-013 | Assignment / Delete | No active (CONFIRMED) bookings may exist | Workflow | Assignment delete | Delete rejected; count of bookings shown |
| BR-PTM-014 | Event / Delete | Cascade soft-delete to all children | Workflow | Event delete | Warning with booking count; cascade on confirmation |
| BR-PTM-015 | Assignment / Unpublish | Warn if confirmed bookings exist | Workflow | Assignment unpublish | Warning dialog shown; proceeds on confirmation only |

---

### Validation & Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty/Null | Concurrency Case | Expected Behaviour |
|-------------|--------------|----------------|----------|------------|-----------------|-------------------|
| Event Code | "PTM-T1-2526" | "PTM/T1" (special chars) or duplicate | 20 chars max | Rejected (required) | Two admins create same code simultaneously | Second insert fails DB unique; user sees "already in use" |
| Event Dates | Start 10 May, End 15 May | End 9 May (before Start) | Start = End allowed (single-day event) | Rejected (required) | — | Validation error |
| Booking Window | Opens 1 May, Closes 9 May | Closes 8 April (before Opens) | Opens = Closes (instant window) | Rejected (required) | — | Validation error |
| Slot Duration | 10 min | 0 or negative | 1 min minimum | Falls back to event default | — | Fallback chain applied |
| Slot Capacity | 1 (one-on-one) | 0 or negative | 1 = one-on-one, 2+ = group | Falls back to batch template then event | — | Minimum 1 enforced |
| Cancellation Lead Time | 24 hrs | -1 (negative) | 0 hrs (can cancel up to start) | Defaults to 0 | — | Minimum 0 enforced |
| Booking creation — capacity | booked_count = 0, capacity = 1 → allow | booked_count = 1, capacity = 1 → reject | booked_count = capacity - 1 → last slot, still allowed | — | Two parents click at exact same ms | Second insert hits DB check; rejected with "no longer available" |
| Booking uniqueness | Student 312 books Mrs. Sharma once | Student 312 books Mrs. Sharma twice in same event | Student has CANCELLED booking, then tries fresh booking → allowed | — | Two tabs of same parent browser book simultaneously | DB generated-column UNIQUE prevents second (when fixed per D36) |
| Blockout time | Start 12:00, End 13:00 | Start 13:00, End 12:00 | Start = End (zero-duration — no practical effect, should be rejected) | Rejected (required) | Two admins create overlapping blockouts | Both saved; both applied — union of blockout ranges masks slots |
| Slot regeneration with bookings | Admin confirms warning → regenerate | Admin ignores warning; bookings remain | All bookings cancelled before regenerate | — | Admin publishes while parent is mid-booking | Booking completes on old slots; regeneration replaces slots; parent's booking references a soft-deleted slot — must handle gracefully |
| Cancellation lead time boundary | Slot at 14:00, now 10:00, lead = 4h → NOW + 4h = 14:00 = exactly at boundary | NOW 10:01, lead 4h, slot 14:00 → 1 min past boundary | slot_start − NOW = exactly lead_time_hours → allow (inclusive) | — | — | Use ≤ comparison (inclusive at boundary) |
| Reschedule with new slot full | New slot is Available → allow | New slot is Full → reject; original booking unchanged | New slot becomes Full between selection and confirm | — | Same race as booking | Original remains CONFIRMED; error shown for new slot |
| Delete event with bookings | Admin confirms warning | Admin cancels warning → no delete | Event with 0 bookings → immediate delete (no warning) | — | — | Cascade only after confirmation |

---

*End of PTM — Complete Analysis Pack*
*Generated: 2026-06-29 | Agent: pa-business-analyst | Sources: DDL v3, 17 migrations, 11 controllers, 9 models, 6 services, 8 V1 screen specs, decisions.md D35+D36*
