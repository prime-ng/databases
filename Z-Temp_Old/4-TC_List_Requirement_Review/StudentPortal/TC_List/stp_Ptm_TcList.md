# STP — PTM (Parent-Teacher Meeting) TC List

---

## 1. Module / Sub-Module
- **Module:** StudentPortal (STP)
- **Sub-Module:** Services — PTM

---

## 2. FRD / BR Reference
- Not in STP FRD REQ list (Ptm module integration)
- BR-STP-001 — Data must belong to authenticated student

---

## 3. Test Scenarios

| TC ID | Test Case | Preconditions | Test Steps | Expected Result | Status |
|-------|-----------|--------------|------------|----------------|--------|
| TC-STP-PTM-001 | Verify PTM page loads with events | Published PTM events with future dates exist | 1) Login as guardian 2) Navigate to /ptm | Events list shown; first event auto-selected; available slots displayed | ⬜ |
| TC-STP-PTM-002 | Verify PTM page loads without events | No published future events | 1) Login as guardian 2) Navigate to /ptm | "No upcoming events" empty state | ⬜ |
| TC-STP-PTM-003 | Verify available slots grouped by assignment title | Slots for multiple assignments exist | 1) Login as guardian 2) Navigate to /ptm | Slots grouped under assignment/event titles with teacher name, time, room | ⬜ |
| TC-STP-PTM-004 | Verify existing booking displayed when already booked | Student has CONFIRMED booking for event | 1) Login as guardian 2) Navigate to /ptm | Existing booking details shown; book button hidden | ⬜ |
| TC-STP-PTM-005 | Verify successful slot booking | Slot is AVAILABLE, no existing booking | 1) Login as guardian 2) POST /ptm/book with slot_id + ptm_event_id | Success message; slot status becomes BOOKED; booking shown | ⬜ |
| TC-STP-PTM-006 | Verify duplicate booking blocked | Student already has CONFIRMED booking | 1) Login as guardian 2) Try booking another slot | Error: "You already have a confirmed booking for this event." | ⬜ |
| TC-STP-PTM-007 | Verify race condition on slot booking | Two simultaneous POST requests | 1) Send two concurrent POST /ptm/book for same slot | First succeeds; second fails with "This slot is no longer available" | ⬜ |
| TC-STP-PTM-008 | Verify optimistic locking on slot status change | Slot status changed by admin between page load and submit | 1) Login 2) Admin changes slot to UNAVAILABLE 3) Submit booking | Error: "This slot is no longer available" | ⬜ |
| TC-STP-PTM-009 | Verify cancel booking | Student has CONFIRMED booking | 1) Login as guardian 2) POST /ptm/cancel/{id} | Booking cancelled; slot returns to AVAILABLE | ⬜ |
| TC-STP-PTM-010 | Verify cancel already cancelled booking | Booking already CANCELLED | 1) Login as guardian 2) POST /ptm/cancel/{id} on cancelled booking | 404 Not Found | ⬜ |
| TC-STP-PTM-011 | Verify cancel another student's booking | Booking belongs to different student | 1) Login as Student A 2) POST /ptm/cancel/{B_id} | 404 Not Found (ownership scoped) | ⬜ |
| TC-STP-PTM-012 | Verify validation — missing slot_id | POST without slot_id | 1) Login 2) POST /ptm/book with no slot_id | 422 validation error | ⬜ |
| TC-STP-PTM-013 | Verify validation — invalid slot_id | POST with non-existent slot_id | 1) Login 2) POST /ptm/book with slot_id = 99999 | 422 validation error | ⬜ |
| TC-STP-PTM-014 | Verify guardian resolution via StudentGuardianJnt | Logged-in user is guardian | 1) Login as guardian with active pivot 2) Navigate to /ptm | Student resolved via pivot; bookings scoped to linked student | ⬜ |
| TC-STP-PTM-015 | Verify direct student login works | Logged-in user is student (no guardian pivot) | 1) Login as student 2) Navigate to /ptm | Student resolved directly; bookings scoped to own ID | ⬜ |
| TC-STP-PTM-016 | Verify no student profile returns error | User has no student relation and no guardian pivot | 1) Login as non-staff user 2) Navigate to /ptm | Redirect with error: "Student profile not found" | ⬜ |
| TC-STP-PTM-017 | Verify event switch changes available slots | Multiple events exist | 1) Login 2) Navigate to /ptm?ptm_event_id={2nd_event} | Slots for 2nd event shown | ⬜ |

---

## 4. Test Data Requirements
- Published PtmEvent records with future event_start_date
- PtmSlot records linked to PtmAssignment with status = AVAILABLE
- PtmSlotBooking records for booked/cancelled scenarios
- StudentGuardianJnt records for guardian resolution testing
- At least two students for ownership tests

---

## 5. Test Environment
- **Browser:** Chrome / Firefox / Edge (latest)
- **Auth:** Authenticated guardian and student users
- **DB:** Tenant database seeded with PTM module data

---

## 6. Automation Scope
| TC ID | Automatable? | Notes |
|-------|-------------|-------|
| TC-STP-PTM-001–017 | Yes | Use Pest HTTP tests; concurrent booking uses `Http::pool()` or raw DB test |

---

## 7. Pass / Fail Criteria
- **Pass:** All TC IDs pass; booking/cancel FSM correct; ownership guards work; concurrency handled
- **Fail:** Double booking; ownership leak; incorrect state transitions

---

## 8. Known Issues
| Issue | Description | Severity |
|-------|-------------|----------|
| GAP-STP-PTM-01 | Zero Gate::authorize() calls in controller | Medium |
| GAP-STP-PTM-02 | Not in FRD — no formal REQ/BR assignment | Low |

---

## 9. Route Reference
| Method | URI | Name |
|--------|-----|------|
| GET | /ptm | student-portal.ptm.index |
| POST | /ptm/book | student-portal.ptm.book |
| POST | /ptm/cancel/{id} | student-portal.ptm.cancel |

---

## 10. Execution Status
| Total TCs | Passed | Failed | Blocked | Not Run |
|-----------|--------|--------|---------|---------|
| 17 | — | — | — | 17 |
