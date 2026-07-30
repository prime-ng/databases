# Parent Portal — PTM Scheduling: Test Case List

## 1. Module Information

| Field | Value |
|-------|-------|
| Module | ParentPortal |
| Feature | PTM Scheduling |
| Controller | ParentPtmController |
| Routes | 5 routes (index, show, book, cancel, reschedule) |
| Priority | P1 — Standard |
| FRD Source | REQ-PPT-012 |

---

## 2. Assumptions & Prerequisites

- Parent is authenticated with a valid Sanctum session
- Active child is resolved and linked to the parent (can_access_parent_portal = 1)
- Ptm module is active and tables (ptm_events, ptm_slots, ptm_slot_bookings, ptm_blockouts) are migrated
- At least one active+upcoming PTM event exists for child's class-section
- At least one teacher slot is available for booking (capacity > booked_count)
- DB supports row-level locking (InnoDB) for SELECT...FOR UPDATE

---

## 3. Test Case Summary

| Test Suite | Total TC | V1 | V2 | CR | Status |
|------------|----------|----|----|----|--------|
| UI / View / Screen | 5 | — | — | ◌ | ⬜ |
| Validation (Field-Level) | 3 | — | — | ◌ | ⬜ |
| Positive / Functional | 8 | — | — | ◌ | ⬜ |
| Negative / Error | 8 | — | — | ◌ | ⬜ |
| Security / Access Control | 5 | — | — | ◌ | ⬜ |
| Business Rules (BR) | 4 | — | — | ◌ | ⬜ |
| Integration / API | 3 | — | — | ◌ | ⬜ |
| Performance / Load | 2 | — | — | ◌ | ⬜ |
| Edge Case / Boundary | 6 | — | — | ◌ | ⬜ |
| **Total** | **44** | — | — | 0 | ⬜ |

---

## 4. Detailed Test Cases

### 4.1 UI / View / Screen Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-PT-UI-01 | PTM events list renders with upcoming events | Active+upcoming events for child's class-section | GET /parent-portal/ptm | Events list with titles, dates, booking status; existing bookings shown | — | ◌ | ⬜ |
| TC-PT-UI-02 | PTM event detail shows teachers grouped with slots | Event has multiple teacher assignments | GET /parent-portal/ptm/{event} | Teachers listed with available time slots grouped; booked slots visually distinct | — | ◌ | ⬜ |
| TC-PT-UI-03 | Existing bookings highlighted on event detail | Parent has one CONFIRMED booking | GET /parent-portal/ptm/{event} | Booked slot highlighted; "Booked" badge shown | — | ◌ | ⬜ |
| TC-PT-UI-04 | Empty state when no upcoming events | No PTM events for child's class-section | GET /parent-portal/ptm | Empty state message or "No upcoming PTM events" | — | ◌ | ⬜ |
| TC-PT-UI-05 | isEventToday flag affects UI | Event date is today | GET /parent-portal/ptm/{event} | UI reflects that event is today (no special action blocked; just visual) | — | ◌ | ⬜ |

### 4.2 Validation (Field-Level) Tests

| TC ID | Test Case | Precondition | Input | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-PT-VL-01 | notes max 1000 chars (book) | — | notes = 1001 chars | Validation error | — | ◌ | ⬜ |
| TC-PT-VL-02 | new_slot_id required (reschedule) | — | new_slot_id empty | Validation error: required | — | ◌ | ⬜ |
| TC-PT-VL-03 | new_slot_id must exist (reschedule) | — | new_slot_id = -1 | Validation error: exists:ptm_slots,id | — | ◌ | ⬜ |

### 4.3 Positive / Functional Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-PT-PF-01 | Book available slot successfully | Slot with capacity > booked_count | POST /ptm/slot/{slot}/book | Booking created CONFIRMED; booked_count incremented; slot status updated; redirect with success | — | ◌ | ⬜ |
| TC-PT-PF-02 | Book slot with parent notes | Slot available | POST book with notes="Looking forward" | Booking created with parent_comments saved | — | ◌ | ⬜ |
| TC-PT-PF-03 | Cancel own booking (≥1h before PTM) | Booking exists; PTM > 1h away | POST /ptm/booking/{booking}/cancel | Booking status=CANCELLED; slot booked_count decremented; success message | — | ◌ | ⬜ |
| TC-PT-PF-04 | Reschedule booking to different slot | Event allows reschedule; target slot available | POST /ptm/booking/{booking}/reschedule with new_slot_id | Old booking cancelled; new booking created CONFIRMED; slot counts adjusted | — | ◌ | ⬜ |
| TC-PT-PF-05 | View events filtered by class-section | Events exist for different class-sections | GET /ptm | Only events matching child's class-section shown | — | ◌ | ⬜ |
| TC-PT-PF-06 | Book last available slot (fills capacity) | Slot at capacity-1 booked; capacity=1 | Book remaining slot | Slot status becomes FULL after booking | — | ◌ | ⬜ |
| TC-PT-PF-07 | Booking window validation passes | booking_window_start < now < booking_window_end | Attempt book | Booking succeeds | — | ◌ | ⬜ |
| TC-PT-PF-08 | Book slot after blockout ends | Blockout for teacher+time has ended | Attempt book | Booking succeeds | — | ◌ | ⬜ |

### 4.4 Negative / Error Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-PT-NE-01 | Book fully booked slot | booked_count >= capacity | POST book | Error: "This slot is already fully booked." | — | ◌ | ⬜ |
| TC-PT-NE-02 | Book BLOCKED slot | Slot status=BLOCKED | POST book | Error: "This slot is blocked and cannot be booked." | — | ◌ | ⬜ |
| TC-PT-NE-03 | Book inactive slot | Slot is_active=0 | POST book | Error: "This slot is no longer available." | — | ◌ | ⬜ |
| TC-PT-NE-04 | Cancel booking < 1h before PTM | PTM start in 30 minutes | POST cancel | abort 422: "This booking can no longer be cancelled." | — | ◌ | ⬜ |
| TC-PT-NE-05 | Book same slot twice for same user | Booking already exists for user+slot | POST book | Error: "You have already booked this slot." | — | ◌ | ⬜ |
| TC-PT-NE-06 | Book second slot in same event | Already has CONFIRMED booking in this event | POST book on different slot | Error: "You already have a booking for this PTM event." | — | ◌ | ⬜ |
| TC-PT-NE-07 | Book overlapping time slot | Another booking with overlapping time | POST book overlapping time | Error: "You already have another booking at this time." | — | ◌ | ⬜ |
| TC-PT-NE-08 | Reschedule when event disallows it | event->allow_reschedule = false | POST reschedule | Error: "Rescheduling is not allowed for this event." | — | ◌ | ⬜ |

### 4.5 Security / Access Control Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-PT-SC-01 | Cancel another parent's booking | Booking owned by different user | POST cancel | abort 403: booking ownership check fails | — | ◌ | ⬜ |
| TC-PT-SC-02 | Book slot for different class-section | Slot assigned to different class | POST book on mismatched slot | BookParentPtmRequest.authorize() returns false → 403 | — | ◌ | ⬜ |
| TC-PT-SC-03 | Cancel booking for different child | Booking.student_id != active child | POST cancel | abort 403: student_id mismatch | — | ◌ | ⬜ |
| TC-PT-SC-04 | Unauthenticated access | No auth session | Access any PTM route | Redirected to login | — | ◌ | ⬜ |
| TC-PT-SC-05 | Slot not belonging to child's class-section | assertSlotBelongsToChildClassSection fails | POST book | 403 "This slot is not available for your child's class." | — | ◌ | ⬜ |

### 4.6 Business Rule Tests

| TC ID | Test Case | BR | Steps | Expected Result | V | CR | Status |
|-------|-----------|-----|-------|-----------------|---|----|--------|
| TC-PT-BR-01 | One booking per student per event | BR-PPT-015 | Book one slot; try booking another | Second blocked | — | ◌ | ⬜ |
| TC-PT-BR-02 | Slot released on cancel | BR-PPT-015 | Cancel booking; check slot availability | Slot booked_count decremented; slot becomes AVAILABLE | — | ◌ | ⬜ |
| TC-PT-BR-03 | No cancellation within 1h | BR-PPT-020 | Try cancel 30 min before | Error: "This booking can no longer be cancelled." | — | ◌ | ⬜ |
| TC-PT-BR-04 | Cancel exactly 1h before PTM | BR-PPT-020 | Try cancel exactly 60 min before | isCancellable() should allow it (>= 1 hour) | — | ◌ | ⬜ |

### 4.7 Integration / API Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-PT-IN-01 | Concurrent booking — first succeeds | Two requests simultaneously for same slot | Fire two concurrent POST book | First succeeds; second gets "slot taken" | — | ◌ | ⬜ |
| TC-PT-IN-02 | Notification created on book (if enabled) | event->notify_parent_on_book = true | POST book | ntf_notifications record created with PTM_BOOKED event | — | ◌ | ⬜ |
| TC-PT-IN-03 | Notification created on cancel (if enabled) | event->notify_parent_on_cancel = true | POST cancel | ntf_notifications record created with PTM_CANCELLED event | — | ◌ | ⬜ |

### 4.8 Performance / Load Tests

| TC ID | Test Case | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------|-----------------|---|----|--------|
| TC-PT-PF-01 | Concurrent booking race condition (10 simultaneous) | Fire 10 concurrent requests for same slot | Exactly 1 succeeds; 9 fail with appropriate message | — | ◌ | ⬜ |
| TC-PT-PF-02 | Event detail page load with 50+ slots | Event with 50 teacher slots, 10 bookings | Page loads within 3 seconds | — | ◌ | ⬜ |

### 4.9 Edge Case / Boundary Tests

| TC ID | Test Case | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------|-----------------|---|----|--------|
| TC-PT-EC-01 | Booking at exact booking_window_start | Submit exactly at window opens | Booking succeeds (>= boundary) | — | ◌ | ⬜ |
| TC-PT-EC-02 | Booking at exact booking_window_end | Submit exactly at window closes | Booking succeeds if now <= window_end; fails if now > window_end | — | ◌ | ⬜ |
| TC-PT-EC-03 | Blockout covering entire event duration | Blockout all day for teacher | Book any slot → "blocked due to a blockout" | — | ◌ | ⬜ |
| TC-PT-EC-04 | Booking when slot_start == slot_end (zero-length) | Invalid slot configuration | Transaction should handle gracefully | — | ◌ | ⬜ |
| TC-PT-EC-05 | Event with no booking_window (null boundaries) | booking_window_start/end = null | Book succeeds (skip window check) | — | ◌ | ⬜ |
| TC-PT-EC-06 | Reschedule to a slot that becomes full mid-transaction | Target slot fills up during transaction | Transaction rolls back; old booking cancelled? — verify rollback | — | ◌ | ⬜ |

---

## 5. Test Data Requirements

| Entity | Fields Required | Sample Data |
|--------|----------------|-------------|
| Parent (authenticated) | id, email | parent@test.com |
| Child (student) | id, is_active=1 | student_id=1 |
| Guardian-Child Link | guardian_id, student_id, can_access_parent_portal=1 | jnt record |
| Class Section | id | class_section_id=1 |
| PTM Event | id, title, event_start/end dates, booking_window, allow_reschedule, notification flags | Various configurations |
| PTM Slot | id, teacher_id, assignment_id, slot_start/end, capacity, booked_count, status | Multiple slots per event |
| PTM Booking | id, slot_id, student_id, booked_by_user_id, status | CONFIRMED + CANCELLED variants |
| PTM Blockout | id, ptm_event_id, teacher_id, blockout_date, start/end time | Teacher-specific and event-wide |

---

## 6. Environment & Setup

- **Backend:** Laravel 12, PHP 8.2+
- **Database:** MySQL 8 with InnoDB (row-level locking support)
- **Auth:** Sanctum with web guard
- **Dependencies:** Ptm module (ptm_events, ptm_slots, ptm_slot_bookings, ptm_blockouts tables migrated)
- **Concurrency tests:** Use PHPUnit with database transactions or dedicated load-testing tool

---

## 7. Test Execution Notes

- ALL book/cancel/reschedule actions occur within DB transactions
- Use `lockForUpdate()` verification in test assertions where possible
- Concurrent booking tests require simultaneous request simulation (Laravel's `Http::pool` or external tool)
- Notification creation is best-effort (wrapped in try-catch) — test with and without notification module
- `isCancellable()` logic depends on `ptm_slots.slot_start` datetime — ensure test data has correct times
- Blockout matching uses date string + time string comparison, not full datetime

---

## 8. Known Issues

| # | Issue | Module | Severity | Status |
|---|-------|--------|----------|--------|
| KI-01 | BookParentPtmRequest embeds authorization logic in authorize() — concern mixing | Ptm | Medium | Open |
| KI-02 | Notification creation silently fails (try-catch with Log::error) — no user-visible feedback | ParentPortal | Low | Open |
| KI-03 | `isSlotBlockedByBlockout` compares formatted time strings (H:i:s) — timezone sensitive | Ptm | Low | Open |
| KI-04 | No explicit Gate policy for booking ownership — relies on abort_unless inline checks | ParentPortal | Low | Open |
| KI-05 | Concurrency test for rescheduling edge case (old cancelled, new slot taken mid-txn) scenario complex | ParentPortal | Medium | Open |
| KI-06 | Inline validation in book() (exception-based flow control) vs form request pattern | ParentPortal | Low | Open |

---

## 9. Route Reference

| # | Method | URI | Name | Middleware |
|---|--------|-----|------|------------|
| 1 | GET | /parent-portal/ptm | parent-portal.ptm.index | auth, verified, ParentPortal |
| 2 | GET | /parent-portal/ptm/{ptmEvent} | parent-portal.ptm.show | auth, verified, ParentPortal |
| 3 | POST | /parent-portal/ptm/slot/{slot}/book | parent-portal.ptm.book | auth, verified, ParentPortal |
| 4 | POST | /parent-portal/ptm/booking/{booking}/cancel | parent-portal.ptm.cancel | auth, verified, ParentPortal |
| 5 | POST | /parent-portal/ptm/booking/{booking}/reschedule | parent-portal.ptm.reschedule | auth, verified, ParentPortal |

Middleware stack: web → InitializeTenancyByDomain → PreventAccessFromCentralDomains → EnsureTenantIsActive → auth → verified → ParentPortalMiddleware

---

## 10. Execution Status

| Test Suite | Total TC | Passed | Failed | Blocked | Skipped | Execution Date | Executed By |
|------------|----------|--------|--------|---------|---------|----------------|-------------|
| UI / View / Screen | 5 | — | — | — | — | — | — |
| Validation (Field-Level) | 3 | — | — | — | — | — | — |
| Positive / Functional | 8 | — | — | — | — | — | — |
| Negative / Error | 8 | — | — | — | — | — | — |
| Security / Access Control | 5 | — | — | — | — | — | — |
| Business Rules (BR) | 4 | — | — | — | — | — | — |
| Integration / API | 3 | — | — | — | — | — | — |
| Performance / Load | 2 | — | — | — | — | — | — |
| Edge Case / Boundary | 6 | — | — | — | — | — | — |
| **Total** | **44** | — | — | — | — | — | — |
