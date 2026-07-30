# STP — Parent-Teacher Meeting (PTM) Requirement Document

---

## 1. Module / Sub-Module
- **Module:** StudentPortal (STP)
- **Sub-Module:** Services — PTM (Parent-Teacher Meeting)
- **Table Prefix:** stp_ (uses ptm_* tables from PTM module)

---

## 2. FRD Reference
| ID | Description | Priority |
|----|------------|----------|
| — | Not in STP FRD REQ list (belongs to Ptm module integration) | P1 |

---

## 3. Feature Description
Enables students (via the guardian/parent login) to view upcoming PTM events, browse available time slots per teacher, book a slot with optimistic locking, and cancel an existing booking.

---

## 4. User Stories / Use Cases
- **As a** parent/guardian, **I want to** see upcoming PTM events **so that** I know when meetings are scheduled.
- **As a** parent/guardian, **I want to** book an available slot with a teacher **so that** I can attend the PTM.
- **As a** parent/guardian, **I want to** cancel my booking **so that** another parent can use the slot.

---

## 5. Business Rules (BR)
| BR ID | Rule | Type | Enforcement |
|-------|------|------|-------------|
| BR-STP-001 | Data must belong to authenticated student | Permission | Queries scoped via `getStudent()` helper (guardian or student resolution) |
| — | Only published PTM events with future start dates shown | Display | `PtmEvent::active()->where('is_published', true)->whereDate('event_start_date', '>=', now())` |
| — | Only AVAILABLE slots with no CONFIRMED bookings shown | Display | `where('status', 'AVAILABLE')->whereDoesntHave('bookings', fn => where('status', 'CONFIRMED'))` |
| — | One booking per student per PTM event | Validation | `store()` checks existing CONFIRMED booking before creating new |
| — | Slot booking uses pessimistic locking | Concurrency | `$slot->lockForUpdate()` within DB transaction |
| — | Status transition on book: AVAILABLE → BOOKED | Workflow | `$slot->update(['status' => 'BOOKED'])` |
| — | Status transition on cancel: BOOKED → AVAILABLE | Workflow | `$booking->slot->update(['status' => 'AVAILABLE'])` |
| — | Guardian can resolve student via `StudentGuardianJnt` | Permission | `getStudent()` checks guardian junction first, falls back to direct `student` relation |
| — | Only bookings with CONFIRMED status and is_active = true can be cancelled | Validation | `cancel()` queries `where('status', 'CONFIRMED')->where('is_active', true)` |

---

## 6. Validations & Edge Cases
| Scenario | Input / Action | Expected Behaviour |
|----------|---------------|-------------------|
| Student (not guardian) logs in | User has no guardian pivot, but has direct student relation | `getStudent()` falls back to `Student::where('user_id', auth()->id())` |
| No active PTM events | No events with is_published + future start | Empty page with "No upcoming events" message |
| No available slots for selected event | All slots booked or no slots defined | Empty slots list, grouped by assignment title |
| Duplicate booking attempt | Same student books second slot for same event | Error: "You already have a confirmed booking for this event." |
| Race condition on slot booking | Two users book same slot simultaneously | Pessimistic lock prevents double booking; second user gets error |
| Cancel non-existent booking | Booking ID belongs to another student | `firstOrFail()` throws 404 |
| Cancel already-cancelled booking | Booking status = CANCELLED | `where('status', 'CONFIRMED')` returns empty → 404 |
| Slot becomes unavailable between page load and submit | Slot status changed by admin | Transaction checks `status !== 'AVAILABLE'` → RuntimeException |
| Event not selected | No ptm_event_id in request | `$selectedEventId` defaults to first event; slots may be empty |

---

## 7. Route Details
| Method | Route | Name | Controller Method |
|--------|-------|------|-------------------|
| GET | /ptm | student-portal.ptm.index | StudentPtmController@index |
| POST | /ptm/book | student-portal.ptm.book | StudentPtmController@store |
| POST | /ptm/cancel/{id} | student-portal.ptm.cancel | StudentPtmController@cancel |

---

## 8. Data / Entity Reference

### A. PTM Event
- **Model:** `Modules\Ptm\Models\PtmEvent`
- **Table:** `ptm_events`
- **Scope:** `active()` scope, `is_published = true`, `event_start_date >= now()`

### B. PTM Slot
- **Model:** `Modules\Ptm\Models\PtmSlot`
- **Table:** `ptm_slots`
- **Eager loads:** `assignment.ptmEvent`, `teacher`, `room`
- **Scope:** `status = 'AVAILABLE'`, `is_active = true`, no CONFIRMED bookings
- **Grouping:** Grouped by `assignment->ptmEvent->title`

### C. PTM Slot Booking
- **Model:** `Modules\Ptm\Models\PtmSlotBooking`
- **Table:** `ptm_slot_bookings`
- **Fields:** slot_id, student_id, guardian_id, status, is_active, created_by

### D. Student Resolution
- **Helper:** `getStudent()` — checks `StudentGuardianJnt` for guardian users, then falls back to direct `Student` lookup

---

## 9. Dependencies (Cross-Module)
| Module | Dependency | Type |
|--------|-----------|------|
| PTM (Ptm) | PtmEvent, PtmSlot, PtmSlotBooking | Read/Write |
| StudentProfile (STD) | StudentGuardianJnt, Student | Read |

---

## 10. Integration / API
- No AJAX endpoints (all standard POST form submissions)
- Uses database pessimistic locking for concurrency control

---

## 11. Security & Permissions
| Check | Implementation |
|-------|---------------|
| Authentication | Standard `auth` + `verified` middleware |
| Data ownership | All bookings scoped to resolved student ID |
| Concurrency | `lockForUpdate()` + DB transaction on store/cancel |
| Cancel authorization | `where('student_id', $student->id)` ownership guard |
| No authorization gates | Zero `Gate::authorize()` calls — relies on query scoping |

---

## 12. Assumptions & Constraints
- PTM module (Ptm) must be installed and configured
- Uses guardian resolution — designed for parent/guardian login primarily
- Direct student login also works via fallback
- Slot booking is non-refundable (no payment involved)

---

## 13. Known Issues / Gaps
| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| GAP-STP-PTM-01 | Zero Gate::authorize() calls in StudentPtmController | Medium | Open |
| GAP-STP-PTM-02 | No event date range shown to student (only event_start_date filtered) | Low | Open |
| GAP-STP-PTM-03 | Not in STP FRD — no formal REQ-ID assigned | Low | Open |

---

## 14. Future Enhancements
| ID | Suggestion | Priority |
|----|-----------|----------|
| ENH-STP-PTM-01 | Add email/SMS confirmation on booking | P2 |
| ENH-STP-PTM-02 | Show teacher profile photo and subject in slot listing | P3 |
| ENH-STP-PTM-03 | Add calendar sync (.ics) for booked slots | P3 |

---

## 15. V1/V2 Status
- **V1:** —
- **V2:** —
- **Status:** ✅ Implemented
- **CR:** ◌

---

## 16. Revision History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 23-07-2026 | OpenCode | Initial requirement document |
