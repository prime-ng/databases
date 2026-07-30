# Parent Portal — Events & RSVP: Test Case List

## 1. Module Information

| Field | Value |
|-------|-------|
| Module | ParentPortal |
| Feature | Events & RSVP |
| Controller | ParentEventController |
| Routes | 4 routes (index, show, rsvp, ics) |
| Priority | P1 — Standard |
| FRD Source | REQ-PPT-013 |

---

## 2. Assumptions & Prerequisites

- Parent is authenticated with a valid Sanctum session
- Active child is resolved and linked to the parent (can_access_parent_portal = 1)
- `ppt_events` table exists and has at least one Published event
- `ppt_event_rsvps` table exists with UNIQUE(event_id, guardian_id) constraint
- Dropdown reference data is seeded for RSVP status options
- Service for .ics download works in both web and mobile contexts

---

## 3. Test Case Summary

| Test Suite | Total TC | V1 | V2 | CR | Status |
|------------|----------|----|----|----|--------|
| UI / View / Screen | 5 | — | — | ◌ | ⬜ |
| Validation (Field-Level) | 4 | — | — | ◌ | ⬜ |
| Positive / Functional | 6 | — | — | ◌ | ⬜ |
| Negative / Error | 6 | — | — | ◌ | ⬜ |
| Security / Access Control | 4 | — | — | ◌ | ⬜ |
| Business Rules (BR) | 2 | — | — | ◌ | ⬜ |
| Integration / API | 4 | — | — | ◌ | ⬜ |
| Performance / Load | 0 | — | — | ◌ | ⬜ |
| Edge Case / Boundary | 4 | — | — | ◌ | ⬜ |
| **Total** | **35** | — | — | 0 | ⬜ |

---

## 4. Detailed Test Cases

### 4.1 UI / View / Screen Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-EV-UI-01 | Events list renders with upcoming/past split | Events exist (some past, some upcoming) | GET /parent-portal/events | Upcoming and Past sections displayed; events sorted by start_datetime | — | ◌ | ⬜ |
| TC-EV-UI-02 | Existing RSVP badge shown on event card | Parent has RSVPed to an event | GET /parent-portal/events | Event card shows RSVP status badge (Attending/Not_Attending/Maybe) | — | ◌ | ⬜ |
| TC-EV-UI-03 | Event detail shows full info with RSVP form | Published event exists | GET /parent-portal/events/{event} | Title, description, datetime, venue, volunteer roles, RSVP form displayed | — | ◌ | ⬜ |
| TC-EV-UI-04 | Volunteer section with role selection | Event has volunteer_roles_json populated | View event detail | Volunteer checkbox + role dropdown shown with role options and remaining capacity | — | ◌ | ⬜ |
| TC-EV-UI-05 | .ics download link visible on event detail | Event is eligible | View event detail | "Add to Calendar" or .ics download link present | — | ◌ | ⬜ |

### 4.2 Validation (Field-Level) Tests

| TC ID | Test Case | Precondition | Input | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-EV-VL-01 | rsvp_status required | — | rsvp_status empty | Validation error | — | ◌ | ⬜ |
| TC-EV-VL-02 | rsvp_status must be valid enum value | — | rsvp_status = "Yes" | Validation error: in:Attending,Not_Attending,Maybe | — | ◌ | ⬜ |
| TC-EV-VL-03 | volunteer_role max 150 chars | is_volunteer=1 | volunteer_role = 151 chars | Validation error: max:150 | — | ◌ | ⬜ |
| TC-EV-VL-04 | rsvp_notes max 500 chars | — | rsvp_notes = 501 chars | Validation error: max:500 | — | ◌ | ⬜ |

### 4.3 Positive / Functional Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-EV-PF-01 | Submit RSVP (Attending) successfully | Upcoming event, no existing RSVP | POST /events/{event}/rsvp with rsvp_status=Attending | EventRsvp created; redirect to show with success "RSVP recorded. Thank you!" | — | ◌ | ⬜ |
| TC-EV-PF-02 | Update existing RSVP (change status) | Existing RSVP with Attending | POST /rsvp with rsvp_status=Maybe | EventRsvp updated in-place; new status shown | — | ◌ | ⬜ |
| TC-EV-PF-03 | Sign up as volunteer with valid role | Event allows volunteers; capacity available | POST /rsvp with rsvp_status=Attending, is_volunteer=1, volunteer_role="Food stall" | RSVP recorded with is_volunteer=true; volunteer count increments | — | ◌ | ⬜ |
| TC-EV-PF-04 | Download .ics file for event | Event eligible | GET /events/{event}/ics | .ics file downloaded with correct VEVENT data (UID, DTSTART, DTEND, SUMMARY, DESCRIPTION, LOCATION) | — | ◌ | ⬜ |
| TC-EV-PF-05 | View events filtered by class targeting | Events with class_id=null and class_id=match | GET /events | Only eligible events shown per isEventEligible() | — | ◌ | ⬜ |
| TC-EV-PF-06 | Past events shown in Past section | Past events exist | GET /events | Past events displayed correctly in Past section | — | ◌ | ⬜ |

### 4.4 Negative / Error Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-EV-NE-01 | RSVP for past event | Event end_datetime in past | POST /rsvp | Error: "This event has already passed." | — | ◌ | ⬜ |
| TC-EV-NE-02 | RSVP with is_volunteer=true but no role | is_volunteer=1, volunteer_role empty | POST /rsvp | Error: "Please select a volunteer role." | — | ◌ | ⬜ |
| TC-EV-NE-03 | RSVP with invalid volunteer role | volunteer_role not in roles_json | POST /rsvp | Error: "Invalid volunteer role." | — | ◌ | ⬜ |
| TC-EV-NE-04 | RSVP for full volunteer role | Role capacity already reached | POST /rsvp for full role | Error: "This volunteer role is already full." | — | ◌ | ⬜ |
| TC-EV-NE-05 | Access ineligible event (wrong class) | Event targeting different class | GET /events/{event} | 403 "You do not have access to this event." | — | ◌ | ⬜ |
| TC-EV-NE-06 | Access inactive event | Event with is_active=0 | GET /events/{event} | isEventEligible() returns false → 403 | — | ◌ | ⬜ |

### 4.5 Security / Access Control Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-EV-SC-01 | Unauthenticated access | No auth session | Access any event route | Redirected to login | — | ◌ | ⬜ |
| TC-EV-SC-02 | Access event for different class | Child in class A; event targets class B | GET /show | 403 isEventEligible() | — | ◌ | ⬜ |
| TC-EV-SC-03 | Access event with inactive status | Event status != "Published" | GET /show | 403 (scopeActive only returns Published) | — | ◌ | ⬜ |
| TC-EV-SC-04 | RSVP for event as unlinked guardian | User not linked to any child | POST /rsvp | BaseRequest.authorize() fails → 403 | — | ◌ | ⬜ |

### 4.6 Business Rule Tests

| TC ID | Test Case | BR | Steps | Expected Result | V | CR | Status |
|-------|-----------|-----|-------|-----------------|---|----|--------|
| TC-EV-BR-01 | Volunteer capacity enforcement | BR-PPT-016 | Fill role to capacity; next parent attempts same role | Last slot fills successfully; next gets "This volunteer role is already full." | — | ◌ | ⬜ |
| TC-EV-BR-02 | Unique RSVP per guardian per event | BR-PPT-001 | Submit two RSVPs for same guardian+event | Second updates first (updateOrCreate) — no duplicate | — | ◌ | ⬜ |

### 4.7 Integration / API Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-EV-IN-01 | .ics content format validation | Event with all fields populated | GET /events/{event}/ics | File headers: Content-Type=text/calendar; Content-Disposition=attachment; filename=event-{id}.ics | — | ◌ | ⬜ |
| TC-EV-IN-02 | .ics VEVENT fields correctness | Event with start, end, title, description, venue | Parse .ics content | UID format correct; DTSTART/DTEND in YYYYMMDDTHHMMSSZ; SUMMARY, DESCRIPTION, LOCATION present | — | ◌ | ⬜ |
| TC-EV-IN-03 | .ics with null end_datetime | end_datetime is null | GET /ics | Falls back to start_datetime as end | — | ◌ | ⬜ |
| TC-EV-IN-04 | Activity log created on RSVP | — | POST /rsvp | sys_activity_logs entry with event=Rsvped, context includes student, event, rsvp_status | — | ◌ | ⬜ |

### 4.8 Performance / Load Tests

*(No performance tests defined.)*

### 4.9 Edge Case / Boundary Tests

| TC ID | Test Case | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------|-----------------|---|----|--------|
| TC-EV-EC-01 | Volunteer role capacity = 0 (no slots) | Configure role with capacity=0; parent attempts sign-up | AlreadyBooked >= 0 returns true → error "role full" | — | ◌ | ⬜ |
| TC-EV-EC-02 | Event with no volunteer_roles_json (null) | volunteer_roles_json = null | Controller $roles = collect(null) → empty collection; any role attempt → "Invalid volunteer role" | — | ◌ | ⬜ |
| TC-EV-EC-03 | RSVP for event starting exactly now | start_datetime = now; end_datetime = future | isPast() checks end_datetime → not past → RSVP allowed | — | ◌ | ⬜ |
| TC-EV-EC-04 | Guardian with no std_guardians record | User has no linked guardian row in db | Any action → guardianId = null → abort_if 403 or null reference in myRsvps | — | ◌ | ⬜ |

---

## 5. Test Data Requirements

| Entity | Fields Required | Sample Data |
|--------|----------------|-------------|
| Parent (authenticated) | id, email | parent@test.com |
| Child (student) | id, is_active=1 | student_id=1 |
| Guardian (std_guardians) | id, user_id | linked to auth user |
| Guardian-Child Link | guardian_id, student_id, can_access_parent_portal=1 | jnt record |
| Event (ppt_events) | id, title, start_datetime, end_datetime, venue, class_id, section_id, status, is_active, volunteer_roles_json | Multiple variants: upcoming/past, with/without volunteer roles |
| Event RSVP (ppt_event_rsvps) | event_id, guardian_id, student_id, rsvp_status_option_id, is_volunteer, volunteer_role | Sample RSVPs for list display |
| Dropdown Entries | ppt_event_rsvps.rsvp_status → Attending, Not_Attending, Maybe | Seed data |

---

## 6. Environment & Setup

- **Backend:** Laravel 12, PHP 8.2+
- **Database:** MySQL 8, tenant_db with ppt_events + ppt_event_rsvps tables migrated
- **Auth:** Sanctum with web guard
- **Dropdown resolver:** PptDropdownResolver must have sys_dropdowns seeded for RSVP status options
- **Dependencies:** SchoolSetup (sch_classes, sch_sections), StudentProfile (std_students, std_guardians)

---

## 7. Test Execution Notes

- `ppt_events` table must exist — if not migrated, block all tests as P0 blocker
- POST /rsvp requires CSRF token
- .ics content must be validated as RFC 5545-compliant VEVENT
- Volunteer capacity check excludes current guardian's existing entries (guardian_id != current)
- `updateOrCreate` uses unique key [event_id, guardian_id] — verify second call updates, not duplicates
- Activity logging captures event = "Rsvped" with context: student, event_id, rsvp_status, is_volunteer

---

## 8. Known Issues

| # | Issue | Module | Severity | Status |
|---|-------|--------|----------|--------|
| KI-01 | `ppt_events` table NOT in DDL v2 — Model references non-existent migration | ParentPortal | **HIGH** | Open |
| KI-02 | `ppt_event_rsvps.event_id` has NO FK constraint in DDL v2 — orphan records possible | Database | **HIGH** | Open |
| KI-03 | Volunteer capacity check lacks row-level locking — race condition possible | ParentPortal | Medium | Open |
| KI-04 | .ics DESCRIPTION uses addslashes(strip_tags()) — special characters may break format | ParentPortal | Low | Open |
| KI-05 | No explicit Gate policy for event/RSVP ownership | ParentPortal | Low | Open |

---

## 9. Route Reference

| # | Method | URI | Name | Middleware |
|---|--------|-----|------|------------|
| 1 | GET | /parent-portal/events | parent-portal.events.index | auth, verified, ParentPortal |
| 2 | GET | /parent-portal/events/{event} | parent-portal.events.show | auth, verified, ParentPortal |
| 3 | POST | /parent-portal/events/{event}/rsvp | parent-portal.events.rsvp | auth, verified, ParentPortal |
| 4 | GET | /parent-portal/events/{event}/ics | parent-portal.events.ics | auth, verified, ParentPortal |

Middleware stack: web → InitializeTenancyByDomain → PreventAccessFromCentralDomains → EnsureTenantIsActive → auth → verified → ParentPortalMiddleware

---

## 10. Execution Status

| Test Suite | Total TC | Passed | Failed | Blocked | Skipped | Execution Date | Executed By |
|------------|----------|--------|--------|---------|---------|----------------|-------------|
| UI / View / Screen | 5 | — | — | — | — | — | — |
| Validation (Field-Level) | 4 | — | — | — | — | — | — |
| Positive / Functional | 6 | — | — | — | — | — | — |
| Negative / Error | 6 | — | — | — | — | — | — |
| Security / Access Control | 4 | — | — | — | — | — | — |
| Business Rules (BR) | 2 | — | — | — | — | — | — |
| Integration / API | 4 | — | — | — | — | — | — |
| Performance / Load | 0 | — | — | — | — | — | — |
| Edge Case / Boundary | 4 | — | — | — | — | — | — |
| **Total** | **35** | — | — | — | — | — | — |
