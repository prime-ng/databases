# Parent Portal — Events & RSVP Module Requirement

## 1. Module Overview

### 1.1 Purpose
The Events & RSVP feature enables parents to view school events (upcoming and past), RSVP with attendance status (Attending / Not Attending / Maybe), sign up as a volunteer with role-based capacity limits, and export events to personal calendars via .ics download.

### 1.2 Business Value
- Digital RSVP replaces paper-based event attendance confirmation
- Volunteer role capacity enforcement prevents over- or under-staffing
- Self-service .ics export enables parents to add events to personal calendars
- Event targeting by class/section ensures relevant event visibility
- Unique RSVP per guardian-event prevents duplicate submissions

### 1.3 Scope
**In Scope:**
- List upcoming and past events for child's class/section (class_id null = all classes)
- View event detail: title, description, date/time, venue, volunteer roles
- Submit RSVP (Attending/Not_Attending/Maybe)
- Volunteer sign-up with role selection and capacity enforcement
- Update existing RSVP (updateOrCreate pattern)
- .ics calendar export for any eligible event
- Volunteer capacity check (existing confirmed volunteers < role capacity)
- Activity logging on all actions

**Out of Scope:**
- Event creation/editing (admin panel — separate module)
- Event reminder push notifications (notification module)
- Event attendance check-in (separate feature)
- Volunteer role CRUD (admin panel)

### 1.4 Terminology
| Term | Meaning |
|------|---------|
| Event | School-organized activity (sports day, cultural fest, field trip, etc.) |
| RSVP | Parent's response indicating attendance status |
| Volunteer | Parent signing up to assist with event logistics |
| Volunteer Role | Specific duty (food stall, registration desk, etc.) with capacity limit |
| .ics | iCalendar file format for calendar application import |

---

## 2. User Roles and Access

| Role | Capability |
|------|-----------|
| Parent / Guardian | View events, RSVP, volunteer sign-up, download .ics |
| School Admin | Create/manage events, define volunteer roles (admin panel) |
| System | Enforce volunteer capacity, prevent duplicate RSVPs |

---

## 3. Functional Requirements

### REQ-PPT-013: Event Calendar and RSVP
**Priority:** Standard (P1) | **Source:** FR-PPT-13 V2

**Description:** Parent views school event calendar and RSVPs for events requiring attendance. Parent signs up as volunteer with role-based capacity limits.

**Actors:** Initiates: Parent | Manages: School Admin | Processes: System (capacity)

**Business Rules:**
| BR | Rule |
|----|------|
| BR-PPT-016 | Volunteer role capacity enforced — sign-up rejected if max_slots reached for a role |
| BR-PPT-001 | RSVP data scoped to authenticated guardian only |

**Acceptance Criteria:**
- AC1: RSVP unique per (guardian, event) — duplicate RSVP updates existing record via updateOrCreate
- AC2: Volunteer sign-up blocked when role capacity reached; clear capacity-full message shown
- AC3: .ics calendar export functional on mobile and desktop
- AC4: Push notification reminder 48h and 2h before volunteer duty (external notification module)

---

## 4. Business Rules Register

| ID | Rule | Enforcement Point |
|----|------|-------------------|
| BR-PPT-016 | Volunteer role capacity enforced | ParentEventController::rsvp (existing confirmed count < capacity) |
| — | RSVP unique per guardian per event | UNIQUE(event_id, guardian_id) + updateOrCreate |
| — | No RSVP for past events | Controller isPast() check |
| — | is_volunteer requires volunteer_role | Controller inline check |
| — | volunteer_role must exist in event.volunteer_roles_json | Controller lookup |
| — | Event eligibility = is_active AND (class_id null OR matches child class/section) | isEventEligible() private method |
| — | Only active + Published events shown | scopeActive() query scope |
| — | Guardian resolved from auth user via std_guardians.user_id | Controller Guardian::where('user_id', auth()->id()) |

---

## 5. Data Requirements

### Table: `ppt_events` (ParentPortal module)
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | PK | Yes | Auto-increment |
| title | string | Yes | Event name |
| description | text | No | HTML description |
| event_type | string | No | Category/type |
| start_datetime | datetime | Yes | Event start |
| end_datetime | datetime | Yes | Event end |
| venue | string | No | Location |
| requires_rsvp | boolean | No | Whether RSVP is needed |
| allows_volunteers | boolean | No | Whether volunteer sign-up enabled |
| volunteer_roles_json | json | No | Array of {role, capacity} objects |
| class_id | int unsigned | No | FK → sch_classes; null = all |
| section_id | int unsigned | No | FK → sch_sections; null = all |
| status | string | Yes | Published / Draft |
| is_active | boolean | Yes | |
| created_by | FK | No | |

### Table: `ppt_event_rsvps`
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | int unsigned PK | Yes | Auto-increment |
| event_id | int unsigned | Yes | FK to ppt_events (NO FK constraint in DDL v2) |
| guardian_id | int unsigned | Yes | FK → std_guardians.id (CASCADE) |
| student_id | int unsigned | No | FK → std_students.id (SET NULL) |
| rsvp_status_option_id | int unsigned | Yes | FK → sys_dropdowns (Attending/Not_Attending/Maybe) |
| is_volunteer | tinyint(1) | Yes | Default 0 |
| volunteer_role | varchar(150) | No | Conditional on is_volunteer |
| rsvp_notes | text | No | Optional notes |
| confirmed_at | timestamp | No | When confirmed |
| reminder_sent_at | timestamp | No | Last reminder dispatch |
| is_active | tinyint(1) | Yes | Default 1 |
| created_by | bigint unsigned | No | |
| created_at | timestamp | Yes | |
| updated_at | timestamp | Yes | |

**Key Constraints:**
- UNIQUE(event_id, guardian_id) — enforces one RSVP per guardian per event
- NO deleted_at — RSVPs updated in-place (rsvp_status changed)
- Foreign keys to std_guardians and std_students

### Gap: ppt_events table vs event source
The DDL v2 does not define `ppt_events` table. The Event model exists at `Modules/ParentPortal/Models/Event.php` referencing `ppt_events` table. The `ppt_event_rsvps.event_id` FK points to this table but the DDL shows no FK constraint (commented as "??????????????"). This is a documented gap — the event source/canonical table needs clarification.

### Cross-Module Dependencies
- **StudentProfile** — std_students, std_guardians, std_student_guardian_jnt
- **SchoolSetup** — sch_classes, sch_sections
- **Notification** — ntf_notifications (event reminders — external)

---

## 6. Workflow

### Workflow: Event RSVP
**Trigger:** Parent views event and submits RSVP
**End States:** RSVP recorded (Attending/Not_Attending/Maybe)

| Step | Actor | Action |
|------|-------|--------|
| 1 | Parent | View event list (upcoming/past) |
| 2 | Parent | Open event detail |
| 3 | Parent | Select RSVP status (Attending/Not_Attending/Maybe) |
| 4 | Parent | Optionally select is_volunteer + volunteer_role |
| 5 | System | Validate: event not past; role exists; capacity not exceeded |
| 6 | System | updateOrCreate EventRsvp record; redirect to event detail with success message |

**Exception Path:** Past event → error "This event has already passed." Capacity full → "This volunteer role is already full."

---

## 7. Finite State Machine (FSM)

### FSM: Event RSVP States

| From State | Event | Guard | To State | Side-Effects |
|------------|-------|-------|----------|-------------|
| No RSVP | Parent RSVPs | Event not past; valid status | Attending / Not_Attending / Maybe | Record created; confirmed_at set |
| Attending / Not_Attending / Maybe | Parent updates RSVP | Event not past | New status | Record updated in-place |
| Any | Volunteer sign-up | Capacity available; role valid | Attending + is_volunteer=1 | Volunteer count incremented |
| Any | Volunteer full | Capacity reached | (unchanged) | Error: role full |
| Any | Event ends | — | Past (terminal) | RSVP still viewable; no edits |

---

## 8. Screen Specifications

| Screen | Route | Controller@Method | View | Description |
|--------|-------|-------------------|------|-------------|
| Events List | GET /events | index | events/index | Upcoming/Past sections with RSVP indicators |
| Event Detail | GET /events/{event} | show | events/show | Full details, RSVP form, volunteer options, .ics download link |
| Submit RSVP | POST /events/{event}/rsvp | rsvp | — | Processes RSVP; redirects to show |
| ICS Download | GET /events/{event}/ics | ics | — | Returns .ics file download |

---

## 9. Route Reference

| Method | URI | Name | Controller@Method |
|--------|-----|------|-------------------|
| GET | /events | events.index | ParentEventController@index |
| GET | /events/{event} | events.show | ParentEventController@show |
| POST | /events/{event}/rsvp | events.rsvp | ParentEventController@rsvp |
| GET | /events/{event}/ics | events.ics | ParentEventController@ics |

All routes prefixed with `/parent-portal/events` and named with `parent-portal.events.` prefix.

---

## 10. Controller Analysis

### ParentEventController

**Constructor Dependencies:**
- `ParentContextService` — resolves active child context

**Key Methods:**

| Method | Request | Authorization | Validation | Error Handling |
|--------|---------|---------------|------------|---------------|
| index | — | None (class-section scoped) | — | — |
| show | — | isEventEligible() abort_unless | Route model binding | 403 if not eligible |
| rsvp | RsvpParentEventRequest | isEventEligible() abort_unless + BaseRequest authorize | rsvp_status: required in:Attending,Not_Attending,Maybe; is_volunteer: nullable boolean; volunteer_role: nullable string max:150; rsvp_notes: nullable string max:500 | Past event error; invalid role error; capacity full error |
| ics | — | isEventEligible() abort_unless | Route model binding | 403 if not eligible |

**Key Behavioral Rules:**
1. `isEventEligible()` checks: event.is_active AND (class_id null OR matches child class/section)
2. Index query: active() scope (is_active=1, status='Published') + class/section targeting + orderBy start_datetime
3. Events split into upcoming (not isPast()) and past (isPast())
4. Existing RSVPs keyed by event_id for O(1) lookup in list
5. Guardian ID resolved from auth user via `Guardian::where('user_id', auth()->id())`
6. Volunteer counts computed from actual confirmed RSVPs (groupBy volunteer_role)
7. `updateOrCreate` with unique key [event_id, guardian_id] — creates or updates

**rsvp() method flow:**
1. Check event eligibility (403 if not)
2. Resolve guardian_id
3. Check event not past
4. Validate request (FormRequest)
5. If is_volunteer: validate volunteer_role present + exists in event.volunteer_roles_json + capacity not full (excluding current guardian's existing volunteer entries)
6. updateOrCreate EventRsvp with all fields
7. Log activity
8. Redirect to event show with success

**ics() method flow:**
1. Check event eligibility (403 if not)
2. Build VCALENDAR/VEVENT manually with UID, DTSTART, DTEND, SUMMARY, DESCRIPTION, LOCATION
3. Return Response with Content-Type text/calendar and Content-Disposition attachment

---

## 11. Validation Rules & Edge Cases

| Field | Rules | Boundary | Invalid Example |
|-------|-------|----------|----------------|
| rsvp_status | required, in:Attending,Not_Attending,Maybe | — | "Yes" |
| is_volunteer | nullable, boolean | — | "yes" (string) |
| volunteer_role | nullable, string, max:150 | 150 chars max | — |
| rsvp_notes | nullable, string, max:500 | 500 chars max | — |

**Controller-Level Validation:**
- is_volunteer=true requires volunteer_role → "Please select a volunteer role."
- volunteer_role must exist in event.volunteer_roles_json array → "Invalid volunteer role."
- Volunteer capacity: existing confirmed count (excluding current guardian) >= role capacity → "This volunteer role is already full."

**Edge Cases:**
- RSVP for past event → "This event has already passed."
- Updating RSVP status (e.g., Attending → Not_Attending) → updateOrCreate changes in-place
- Volunteer capacity exactly reached → last volunteer succeeds; next gets full message
- Two parents of same child both RSVP → both succeed (unique on guardian_id, not student_id)
- Event with no volunteer roles defined → volunteer_role validation may fail if roles_json empty
- .ics export for event with null end_datetime → uses start_datetime as end
- .ics DESCRIPTION uses addslashes(strip_tags(description)) — HTML tags stripped

---

## 12. Cross-Module Dependencies

| Module | Tables Used | Dependency Type |
|--------|-------------|-----------------|
| ParentPortal | ppt_events, ppt_event_rsvps | Primary data (read + write) |
| StudentProfile | std_students, std_guardians, std_student_guardian_jnt | Child ownership |
| SchoolSetup | sch_classes, sch_sections | Event targeting |
| Prime (Dropdown) | sys_dropdowns | RSVP status option resolution |

---

## 13. Known Issues / Gaps

| # | Gap Description | Severity | Impact | Status |
|---|----------------|----------|--------|--------|
| GI-01 | `ppt_events` table NOT defined in DDL v2 — Event.php model references this table but no migration exists | High | Missing migration; feature cannot function without events table | Open |
| GI-02 | `ppt_event_rsvps.event_id` has NO FK constraint in DDL v2 — referential integrity gap | High | Orphaned RSVPs possible; no constraint for event source | Open |
| GI-03 | FRD notes EventEngine FK unclear — canonical event source undecided | High | Architectural decision pending | Open |
| GI-04 | Volunteer capacity check excludes current guardian's existing entries but does not lock row — race possible | Medium | Two simultaneous volunteer sign-ups may both succeed when 1 slot remains | Open |
| GI-05 | No explicit Gate policy for event/RSVP ownership | Low | Relies on isEventEligible() inline checks | Open |
| GI-06 | .ics DESCRIPTION uses addslashes() + strip_tags() — may not handle all special chars correctly | Low | Potential .ics format issues with special characters | Open |

---

## 14. Non-Functional Requirements

| NFR | Requirement |
|-----|-------------|
| NFR-PPT-007 | Child ownership enforced via isEventEligible() |
| NFR-PPT-009 | CSRF protection on all POST routes |
| NFR-PPT-013 | All parent actions logged to sys_activity_logs |
| NFR-PPT-016 | Mobile-first responsive design; .ics export on mobile |
| NFR-PPT-018 | Graceful degradation if event module inactive |

---

## 15. Future Enhancements

| ID | Enhancement | Priority |
|----|------------|----------|
| ENH-01 | ppt_events migration creation + FK constraints | P0 (blocker) |
| ENH-02 | Push notification reminders 48h and 2h before volunteer duty | P1 |
| ENH-03 | Event calendar view (monthly grid) instead of list | P2 |
| ENH-04 | Event capacity (overall attendee limit) | P2 |
| ENH-05 | Waitlist for full volunteer roles | P2 |
| ENH-06 | Admin RSVP summary report with export | P2 |

---

## 16. Traceability Matrix

| Requirement | BR | Screen | Workflow | Controller Method | Test Scope |
|-------------|----|--------|----------|-------------------|------------|
| List events | — | Events List | Step 1 | index | Upcoming/past split, targeting |
| View event detail | — | Event Detail | Step 2 | show | Content, volunteer counts, .ics link |
| Submit RSVP | — | Submit RSVP | Step 3–6 | rsvp | Status update, volunteer capacity |
| Volunteer sign-up | BR-PPT-016 | Submit RSVP | Step 4–5 | rsvp | Capacity enforcement, role validation |
| .ics export | — | ICS Download | — | ics | Calendar format, file download |
| Past event block | — | Submit RSVP | Step 5 | rsvp | isPast() check |
