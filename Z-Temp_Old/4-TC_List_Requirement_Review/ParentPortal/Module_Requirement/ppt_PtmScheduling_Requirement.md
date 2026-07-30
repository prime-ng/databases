# Parent Portal — PTM Scheduling Module Requirement

## 1. Module Overview

### 1.1 Purpose
The PTM (Parent-Teacher Meeting) Scheduling feature enables parents to view upcoming PTM events, browse available time slots per teacher, book appointments, cancel (up to 1 hour before), and reschedule bookings. Race conditions in slot booking are prevented using database-level locking (SELECT...FOR UPDATE within a DB transaction).

### 1.2 Business Value
- Eliminates physical PTM sign-up sheets and manual coordination
- Prevents double-booking with atomic transaction + row-level locking
- Gives parents flexible self-service slot selection per teacher
- Supports cancellation and rescheduling, reducing teacher no-show time
- Real-time availability — booked slots immediately removed from pool
- Blockout support for teacher unavailability during specific times

### 1.3 Scope
**In Scope:**
- List upcoming PTM events for child's class-section
- View event details: teachers, available slots grouped by teacher
- Book a specific slot for a teacher (atomic, race-condition-safe)
- Cancel own booking (time guard: ≥ 1 hour before PTM)
- Reschedule booking to a different slot (if event allows)
- Booking window validation (if configured on the event)
- Time overlap prevention — no concurrent bookings for same time
- One-booking-per-event limit per student
- Notification dispatch on book/cancel (if event config enables it)
- Slot capacity management (booked_count < capacity)
- Blockout date/time overlap detection
- Activity logging on all actions

**Out of Scope:**
- PTM event creation/management (Ptm module, admin panel)
- Teacher slot assignment (Ptm module)
- Blockout management (Ptm module)
- PTM reminder notifications (scheduled job, not controller-triggered)

### 1.4 Terminology
| Term | Meaning |
|------|---------|
| PTM Event | A scheduled parent-teacher meeting event (e.g., "Term 1 PTM") with dates |
| Slot | A specific time window assigned to a teacher for the event |
| Booking | A parent's confirmed reservation of a slot |
| Blockout | Period during which a teacher is unavailable (PtmBlockout) |
| Booking Window | Configured start/end datetime range during which booking is allowed |
| Reschedule | Moving an existing booking to a different slot in the same event |

---

## 2. User Roles and Access

| Role | Capability |
|------|-----------|
| Parent / Guardian | View PTM events, book slots, cancel/reschedule own bookings |
| School Admin | Create PTM events, assign teacher slots, manage blockouts (Ptm module) |
| Teacher | View own schedule (Ptm module) |
| System | Dispatch booking/cancellation notifications, enforce race-condition guard |

---

## 3. Functional Requirements

### REQ-PPT-012: PTM Scheduling
**Priority:** Standard (P1) | **Source:** FR-PPT-12 V2

**Description:** School publishes PTM time slots. Parent books available slots per teacher. Race conditions prevented via DB transaction with SELECT...FOR UPDATE. Parent can cancel up to 1 hour before PTM.

**Actors:** Initiates: School Admin (create PTM events) + Parent (book slot) | Notified: Parent + Teacher

**Business Rules:**
| BR | Rule |
|----|------|
| BR-PPT-015 | One booking per teacher per PTM event per student; slot immediately released on cancel |
| BR-PPT-020 | Cancellation not permitted within 1 hour of PTM appointment |

**Acceptance Criteria:**
- AC1: Double-booking prevented via DB transaction (SELECT...FOR UPDATE); concurrent attempt gets "slot just taken"
- AC2: Booking confirmation sent to both parent and teacher within 2 minutes (if event notification enabled)
- AC3: Cancelled slot immediately available for rebooking
- AC4: Reminder push notification 24h and 1h before PTM appointment
- AC5: Virtual meeting link displayed if school provides one (via PtmEvent data)

---

## 4. Business Rules Register

| ID | Rule | Enforcement Point |
|----|------|-------------------|
| BR-PPT-015 | One booking per teacher per event per student; slot released on cancel | DB transaction + exists check in book() |
| BR-PPT-020 | No cancellation within 1 hour of PTM | isCancellable() method on PtmBooking model |
| — | Slot capacity enforced (booked_count < capacity) | book() locked slot check |
| — | Slot must be active | book() lockForUpdate check |
| — | Slot status must not be BLOCKED | book() check |
| — | Blockout detection — slot overlaps active blockout | book() isSlotBlockedByBlockout() |
| — | Booking window validation (if configured) | book() check event booking_window_start/end |
| — | One booking per student per event | book() exists check |
| — | No time overlap with existing bookings | book() PtmBooking overlap query |
| — | Slot must belong to child's class-section | assertSlotBelongsToChildClassSection() |
| — | Booking must belong to auth user for cancel | cancel() abort_unless |
| — | Booking student must match active child | cancel() abort_unless |
| — | Rescheduling allowed only if event allows it | reschedule() check event->allow_reschedule |

---

## 5. Data Requirements

### Primary Tables (Ptm module — not PPT-owned)

**Table: `ptm_events`**
| Key Field | Type | Notes |
|-----------|------|-------|
| id | PK | |
| title | string | Event name |
| event_start_date / event_end_date | date | PTM date range |
| booking_window_start / booking_window_end | datetime | Optional booking window |
| allow_reschedule | boolean | Whether rescheduling allowed |
| notify_parent_on_book / notify_parent_on_cancel | boolean | Notification toggles |

**Table: `ptm_slots`**
| Key Field | Type | Notes |
|-----------|------|-------|
| id | PK | |
| teacher_id | FK | → sys_users |
| assignment_id | FK | → ptm_event_class_sections |
| slot_start / slot_end | datetime | Time window |
| capacity | int | Max bookings |
| booked_count | int | Current bookings |
| status | enum | AVAILABLE, BOOKED, FULL, BLOCKED |
| is_active | boolean | |

**Table: `ptm_slot_bookings`**
| Key Field | Type | Notes |
|-----------|------|-------|
| id | PK | |
| slot_id | FK | → ptm_slots |
| ptm_event_id | FK | → ptm_events |
| teacher_id | FK | → sys_users |
| student_id | FK | → std_students |
| booked_by_user_id | FK | → sys_users |
| status | enum | CONFIRMED, CANCELLED |
| parent_comments | text | Optional notes from parent |
| booked_at | datetime | |
| cancelled_at | datetime | |
| cancel_reason | string | |

**Table: `ptm_blockouts`**
| Key Field | Type | Notes |
|-----------|------|-------|
| id | PK | |
| ptm_event_id | FK | |
| teacher_id | FK | nullable (null = event-wide) |
| blockout_date | date | |
| start_time / end_time | time | |

### Cross-Module Dependencies
- **Ptm** — all primary tables (ptm_events, ptm_slots, ptm_slot_bookings, ptm_blockouts)
- **StudentProfile** — std_students, std_guardians
- **SchoolSetup** — sch_class_sections
- **Notification** — ntf_notifications (PTM_BOOKED, PTM_CANCELLED events)

---

## 6. Workflow

### Workflow: PTM Slot Booking (WF-6)
**Trigger:** Parent selects an available time slot for a teacher
**End States:** Booked (confirmation sent), Slot_Released (after cancellation)

| Step | Actor | Action |
|------|-------|--------|
| 1 | Parent | View PTM event; select teacher; choose available time slot |
| 2 | System | Begin DB transaction; SELECT...FOR UPDATE on slot row |
| 3 | System | Validate: slot active, capacity not reached, not BLOCKED, not blocked by blockout, booking window open, not duplicate, no time overlap |
| 4 | System | Create PtmBooking (status=CONFIRMED); increment slot booked_count; update slot status (BOOKED/FULL) |
| 5 | System | Commit transaction; if event.notify_parent_on_book → create notification |
| 6 | Parent (cancel) | Request cancellation ≥ 1 hour before PTM |
| 7 | System | Check time guard; update booking status=CANCELLED; decrement slot booked_count; restore slot status |

**Exception Path:** Race condition → second user gets "This slot is no longer available." Cancellation < 1 hour → "This booking can no longer be cancelled."

---

## 7. Finite State Machine (FSM)

### FSM: PTM Slot Booking States

| From State | Event | Guard | To State | Side-Effects |
|------------|-------|-------|----------|-------------|
| Available | Parent books | SELECT...FOR UPDATE; capacity OK; no conflicts | Booked | Confirmation notification; slot count++ |
| Available | Concurrent race | Slot taken mid-transaction | Available | Error: "slot just taken" |
| Booked | Parent cancels | ≥ 1 hour before PTM; owns booking | Cancelled | Slot released; teacher notified |
| Booked | Parent cancels | < 1 hour | Booked | Error: cannot cancel |
| Booked | Time passes | — | Completed (terminal) | No action possible |

### FSM: Slot States (from Ptm module)

| From State | Event | To State |
|------------|-------|----------|
| AVAILABLE | booked_count reaches 0 after checkout | AVAILABLE |
| AVAILABLE | booked_count > 0 | BOOKED |
| BOOKED | booked_count reaches capacity | FULL |
| BOOKED | booked_count decrements | AVAILABLE / BOOKED |
| BLOCKED | — | (static, set by admin) |

---

## 8. Screen Specifications

| Screen | Route | Controller@Method | View | Description |
|--------|-------|-------------------|------|-------------|
| PTM Events List | GET /ptm | index | ptm/index | Upcoming events with existing bookings |
| PTM Event Detail | GET /ptm/{ptmEvent} | show | ptm/show | Teachers grouped with slots; existing bookings highlighted; isEventToday flag |
| Book Slot | POST /ptm/slot/{slot}/book | book | — | Atomic booking; redirects to event detail |
| Cancel Booking | POST /ptm/booking/{booking}/cancel | cancel | — | Time-guarded cancellation |
| Reschedule Booking | POST /ptm/booking/{booking}/reschedule | reschedule | — | Cancel old + book new in transaction |

---

## 9. Route Reference

| Method | URI | Name | Controller@Method |
|--------|-----|------|-------------------|
| GET | /ptm | ptm.index | ParentPtmController@index |
| GET | /ptm/{ptmEvent} | ptm.show | ParentPtmController@show |
| POST | /ptm/slot/{slot}/book | ptm.book | ParentPtmController@book |
| POST | /ptm/booking/{booking}/cancel | ptm.cancel | ParentPtmController@cancel |
| POST | /ptm/booking/{booking}/reschedule | ptm.reschedule | ParentPtmController@reschedule |

All routes prefixed with `/parent-portal/ptm` and named with `parent-portal.ptm.` prefix.

---

## 10. Controller Analysis

### ParentPtmController

**Constructor Dependencies:**
- `ParentContextService` — resolves active child context

**Key Methods:**

| Method | Request | Authorization | Validation | Error Handling |
|--------|---------|---------------|------------|---------------|
| index | — | None (class-section scoped) | — | — |
| show | — | None (class-section scoped) | Route model binding | — |
| book | BookParentPtmRequest | authorize() checks slot → class-section match | notes: nullable max:1000 | All exceptions caught → back with error |
| cancel | CancelParentPtmRequest | abort_unless (booking ownership, child match, isCancellable) | Empty rules | abort 403/422 |
| reschedule | RescheduleParentPtmRequest | abort_unless (ownership, child match) + assertSlotBelongsToChildClassSection | new_slot_id: required, exists | All exceptions caught → back with error |

**Key Behavioral Rules:**

**book() method flow (atomic transaction):**
1. Assert slot belongs to child's class-section
2. DB::transaction with lockForUpdate on slot:
   - Check slot active, capacity, not BLOCKED
   - Check blockout (isSlotBlockedByBlockout)
   - Check booking window (event boundaries)
   - Check no duplicate booking on same slot by same user
   - Check no existing booking for same student+event
   - Check no time overlap with other bookings
   - Create booking; increment booked_count; update slot status
   - Optionally create notification (if event.notify_parent_on_book)
3. On success → redirect to show; on failure → back with error

**cancel() method flow:**
1. abort_unless: booking belongs to auth user AND matches active child
2. abort_unless: isCancellable() returns true (time guard)
3. DB::transaction: update status to CANCELLED; decrement slot booked_count; update slot status
4. Optionally create cancellation notification
5. Redirect back with success

**reschedule() method flow:**
1. Ownership checks + assertSlotBelongsToChildClassSection
2. Check event allows reschedule
3. DB::transaction:
   - Cancel old booking (status=CANCELLED, cancel_reason="Rescheduled to another slot")
   - Decrement old slot count; update old slot status
   - Lock new slot; validate (active, capacity, not BLOCKED)
   - Create new booking; increment new slot count; update status
4. Redirect to show with success

---

## 11. Validation Rules & Edge Cases

| Field | Rules | Notes |
|-------|-------|-------|
| notes (book) | nullable, string, max:1000 | Optional parent comments |
| new_slot_id (reschedule) | required, integer, exists:ptm_slots,id | Target slot must exist |
| Booking ownership | booked_by_user_id === auth()->id() | abort_unless 403 |
| Child ownership | booking->student_id === child->id | abort_unless 403 |
| Time guard | isCancellable() returns true | abort_unless 422 |

**Edge Cases:**
- Simultaneous booking on same slot → lockForUpdate ensures only one succeeds
- Booking after booking_window_end → transaction throws "Booking window is closed"
- Booking during active blockout → "This slot has been blocked due to a blockout"
- Booking when slot status is BLOCKED → "This slot is blocked and cannot be booked"
- Booking on slot at full capacity → "This slot is already fully booked"
- Cancelling 59 minutes before PTM → "This booking can no longer be cancelled"
- Rescheduling when event disallows it → "Rescheduling is not allowed for this event"
- Booking same slot twice for same user → "You have already booked this slot"
- Booking second slot in same event → "You already have a booking for this PTM event"
- Booking overlapping time slot → "You already have another booking at this time"

---

## 12. Cross-Module Dependencies

| Module | Tables Used | Dependency Type |
|--------|-------------|-----------------|
| Ptm | ptm_events, ptm_slots, ptm_slot_bookings, ptm_blockouts | Primary data (read + write) |
| StudentProfile | std_students, std_guardians | Child ownership |
| SchoolSetup | sch_class_sections | Class-section scoping |
| Notification | ntf_notifications | Booking/cancellation alerts |

---

## 13. Known Issues / Gaps

| # | Gap Description | Severity | Impact | Status |
|---|----------------|----------|--------|--------|
| GI-01 | BookParentPtmRequest embeds slot→class-section authorization in authorize() — mixes concerns | Medium | Authorization logic duplicated between controller and form request | Open |
| GI-02 | CancelParentPtmRequest has empty rules array (container only) | Low | All validation done via abort_unless in controller | Open |
| GI-03 | RescheduleParentPtmRequest validates new_slot_id exists but not capacity/status (done in transaction) | Low | Late validation — capacity check inside transaction after lock | Open |
| GI-04 | No explicit Gate policy for PTM ownership | Low | Relies on inline abort_unless checks | Open |
| GI-05 | Notification creation wrapped in try-catch with silent failure | Low | Notifications may silently fail to send | Open |
| GI-06 | Child class-section match for slot is done in assertSlotBelongsToChildClassSection but not on PTM event scoping at index/show level | Low | Event list is already scoped to class-section via eventClassSections relationship | Open |

---

## 14. Non-Functional Requirements

| NFR | Requirement |
|-----|-------------|
| NFR-PPT-007 | Child ownership enforced on booking, cancel, reschedule |
| NFR-PPT-009 | CSRF protection on all POST routes |
| NFR-PPT-012 | Race-condition prevention via SELECT...FOR UPDATE |
| NFR-PPT-013 | All parent actions logged to sys_activity_logs |
| NFR-PPT-016 | Mobile-first responsive design |

---

## 15. Future Enhancements

| ID | Enhancement | Priority |
|----|------------|----------|
| ENH-01 | Virtual meeting link display on booking confirmation | P1 |
| ENH-02 | PTM calendar sync (.ics export for booked slots) | P2 |
| ENH-03 | Waitlist for fully booked slots | P2 |
| ENH-04 | Bulk booking — book slots for multiple teachers at once | P2 |
| ENH-05 | Teacher availability heat map (popular vs quiet hours) | P3 |

---

## 16. Traceability Matrix

| Requirement | BR | Screen | Workflow | Controller Method | Test Scope |
|-------------|----|--------|----------|-------------------|------------|
| List PTM events | — | PTM Events List | — | index | Event visibility, existing bookings |
| View event + slots | — | PTM Event Detail | WF-6 Step 1 | show | Teacher grouping, slot display, isEventToday |
| Book slot | BR-PPT-015 | Book Slot | WF-6 Step 2–5 | book | Atomic booking, capacity, blockout, overlap |
| Cancel booking | BR-PPT-015, BR-PPT-020 | Cancel Booking | WF-6 Step 6–7 | cancel | Time guard, slot release |
| Reschedule booking | — | Reschedule Booking | — | reschedule | Old slot release, new slot lock |
