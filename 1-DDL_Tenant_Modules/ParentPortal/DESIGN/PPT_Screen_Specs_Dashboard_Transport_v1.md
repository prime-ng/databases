# ParentPortal & StudentPortal — Screen Specs & Wireframe Descriptions

> **Document:** PPT_Screen_Specs_Dashboard_Transport_v1.md
> **Date:** 2026-04-14
> **Author:** Business Analyst (Claude)
> **Scope:** Dashboard enhancements (Consent Forms, PTM, Complaints) + Transport page parity
> **Status:** DRAFT — Pending stakeholder review

---

## Table of Contents

1. [Context & Current State](#1-context--current-state)
2. [SC-PPT-D01: Dashboard — Consent Forms Alert](#2-sc-ppt-d01-dashboard--consent-forms-alert)
3. [SC-PPT-D02: Dashboard — PTM Confirmation Card](#3-sc-ppt-d02-dashboard--ptm-confirmation-card)
4. [SC-PPT-D03: Dashboard — Complaints Quick Link](#4-sc-ppt-d03-dashboard--complaints-quick-link)
5. [SC-PPT-T01: Parent Transport Page — Enhancements](#5-sc-ppt-t01-parent-transport-page--enhancements)
6. [SC-STP-T01: Student Transport Page — Full Rebuild](#6-sc-stp-t01-student-transport-page--full-rebuild)
7. [Data Contract — Controller Changes](#7-data-contract--controller-changes)
8. [Transport Feature Parity Matrix](#8-transport-feature-parity-matrix)
9. [Open Questions](#9-open-questions)

---

## 1. Context & Current State

### Parent Portal Dashboard — Current Layout

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  [ALERT BANNER AREA — currently empty]                                                             │
├────────────────┬────────────────┬────────────────┬────────────────┬────────────────────────────────┤
│   Attendance   │    Homework    │    Upcoming    │    Fee Due     │  Leave Applications            │
│      85%       │    3 pending   │    2 exams     │    ₹12,500     │  5 total (2 pending)           │
├────────────────┴────────────────┴────────────────┴────────────────┴────────────────────────────────┤
│                                                                                                    │
│  ┌─── Today's Timetable ───────────────────────────────────────────────────────────────────────┐   │
│  │  Period 1: Math (Mrs. Sharma, Room 201)                                                     │   │
│  │  Period 2: English (Mr. Patel, Room 105)                                                    │   │
│  │  ... horizontal scroll ...                                                                  │   │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                    │
│  ┌─────── Child Profile ────────┐  ┌─────── Quick Navigation (8 items) ────────────────────────┐   │
│  │  Avatar                      │  │  Attendance     | Timetable      | Homework               │   │
│  │  Name, Class                 │  │  Results        | Fees           | Leave     Teachers     │   │
│  │  Roll No, Adm#               │  │  Notifications                                            │   │
│  │  [Settings]                  │  └───────────────────────────────────────────────────────────┘   │
│  └──────────────────────────────┘                                                                  │
│                                                                                                    │
│  ┌─ Pending Homework ───────────┐  ┌─ Upcoming Exams ──────────────────────────────────────────┐   │
│  │  Subject  | Title   |Due     │  │  Name | Subject | Date | Days                             │   │
│  │  ... 5 rows max ...          │  │  ... 5 rows max ...                                       │   │
│  └──────────────────────────────┘  └───────────────────────────────────────────────────────────┘   │
│                                                                                                    │
│  ┌─ Fee Status ─────────────────┐  ┌─ Notifications ───────────────────────────────────────────┐   │
│  │  Total    | Paid    | Due    │  │  5 most recent                                            │   │
│  │  Progress bar                │  │  ... unread dot + time ...                                │   │
│  └──────────────────────────────┘  └───────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### What's Missing (identified by BA review)

| Item | Current Status | Priority |
|------|---------------|----------|
| Consent Forms | Full controller + 2 views exist, **zero dashboard presence** | **P0** (legal/compliance) |
| PTM Scheduling | Full controller + 2 views exist, **zero dashboard presence** | **P1** (time-sensitive) |
| Complaints | Full controller + 2 views exist, **zero dashboard presence** | **P2** (informational) |
| Student Transport | Minimal view (route/stop only), **missing 8+ data points** | **P1** (safety) |

---

## 2. SC-PPT-D01: Dashboard — Consent Forms Alert

### Business Justification

Consent forms are **legal/compliance documents** — field trip permissions, medical consent, photo usage rights, etc. They have hard deadlines. Unlike homework, parents cannot "catch up later". Missing a consent form can block a child from participating in school activities.

**This must be the most prominent dashboard element when pending forms exist.**

### Wireframe — Alert Banner (top of dashboard, above stat cards)

```
┌──────────────────────────────────────────────────────────────────────┐
│ ⚠ CONSENT FORMS REQUIRING YOUR ATTENTION                            │
│ ┌────────────────────────────────────────────┬──────────┬──────────┐│
│ │ Form Title                                  │ Deadline  │ Action   ││
│ ├────────────────────────────────────────────┼──────────┼──────────┤│
│ │ 🔴 Annual Sports Day — Field Trip Consent  │ 18 Apr    │ [Sign]   ││
│ │ 🔴 Photo/Video Usage Consent 2026-27       │ 25 Apr    │ [Sign]   ││
│ └────────────────────────────────────────────┴──────────┴──────────┘│
│                                    [View All Consent Forms →]        │
└──────────────────────────────────────────────────────────────────────┘
```

### Placement Rules

| Condition | Behaviour |
|-----------|-----------|
| Pending consent forms > 0 | Show alert banner at **top of page**, above stat cards. Background: `#fff3cd` (warning yellow). Border-left: 4px solid `#ffc107`. |
| Pending consent forms = 0 | **Hide banner entirely** — do not show an empty/green banner. |
| Consent form deadline ≤ 3 days away | Row background: `#f8d7da` (light red). Icon: red circle. |
| Consent form deadline > 3 days | Row background: default. Icon: orange circle. |
| All forms signed | Banner disappears. |

### Data Specification

**New variable required in `ParentDashboardController::index()`:**

```
$pendingConsentForms = ConsentForm::active()
    ->where(function ($q) use ($child, $session) {
        $q->whereNull('class_id')                           // targeted to ALL
          ->orWhere(function ($q2) use ($child, $session) {
              $q2->where('class_id', $session->classSection->class_id)
                 ->where(function ($q3) use ($session) {
                     $q3->whereNull('section_id')
                        ->orWhere('section_id', $session->classSection->section_id);
                 });
          });
    })
    ->where('deadline', '>=', now())                        // not expired
    ->whereDoesntHave('responses', function ($q) use ($child, $guardianId) {
        $q->where('student_id', $child->id)
          ->where('guardian_id', $guardianId);
    })
    ->orderBy('deadline')
    ->get(['id', 'title', 'deadline', 'allow_decline']);
```

**Pass to view:** `$pendingConsentForms` (Collection)

### Quick Navigation Enhancement

Add **9th item** to existing Quick Navigation grid:

```
┌──────────────────────────────────────────────────────────────────┐
│  Attendance | Timetable | Homework  | Results                    │
│  Fees       | Leave     | Teachers  | Notifications              │
│  📋 Consent Forms [🔴 2]                                         │
└──────────────────────────────────────────────────────────────────┘
```

| Element | Value |
|---------|-------|
| Icon | `fa fa-file-signature` |
| Label | "Consent Forms" |
| Badge | Red pill with count if pending > 0; hidden if 0 |
| Route | `parent-portal.consent-forms.index` |

### Acceptance Criteria

- [ ] AC-01: Banner appears when ≥1 unsigned consent form exists for active child's class/section
- [ ] AC-02: Banner disappears immediately after all forms are signed (no page refresh delay if using Livewire/AJAX)
- [ ] AC-03: "Sign" button links to `parent-portal.consent-forms.show` for that form
- [ ] AC-04: "View All" links to `parent-portal.consent-forms.index`
- [ ] AC-05: Forms with deadline ≤ 3 days show red highlight
- [ ] AC-06: Quick Nav shows consent forms with badge count
- [ ] AC-07: Banner does NOT appear if child has no active session
- [ ] AC-08: Multi-child scenario — banner shows forms for **active child only**

---

## 3. SC-PPT-D02: Dashboard — PTM Confirmation Card

### Business Justification

Parent-Teacher Meetings have **limited slots with capacity constraints**. Slots fill up fast. Parents who don't see the PTM alert on dashboard may miss the booking window, leading to complaints and operational overhead for the school. The dashboard must surface PTM urgency.

### Wireframe — Conditional PTM Card

**State A: Upcoming PTM, NOT YET BOOKED (urgent)**

```
┌──────────────────────────────────────────────────────────────────────┐
│ 📅 PARENT-TEACHER MEETING                              [Book Now →] │
│─────────────────────────────────────────────────────────────────────-│
│                                                                      │
│  Event:     Mid-Term Progress Review                                 │
│  Date:      Saturday, 20 April 2026                                  │
│  Venue:     School Auditorium / Online (Zoom)                        │
│                                                                      │
│  Status:    🔴 NOT BOOKED — Slots filling up                         │
│  Slots:     12 of 20 available                                       │
│                                                                      │
│  [Book Your Slot →]                                                  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

- **Card border:** Left 4px solid `#e74c3c` (red)
- **Background:** `#ffeaea` (light red tint)

**State B: Upcoming PTM, BOOKED (confirmed)**

```
┌──────────────────────────────────────────────────────────────────────┐
│ 📅 PARENT-TEACHER MEETING                         [View Details →]  │
│─────────────────────────────────────────────────────────────────────-│
│                                                                      │
│  Event:     Mid-Term Progress Review                                 │
│  Date:      Saturday, 20 April 2026                                  │
│                                                                      │
│  ✅ CONFIRMED                                                        │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  Teacher:   Mrs. Sharma (Mathematics)                         │   │
│  │  Time:      10:30 AM – 10:45 AM                               │   │
│  │  Venue:     Room 201                                          │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  [Cancel Booking]    [View All Bookings →]                           │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

- **Card border:** Left 4px solid `#27ae60` (green)
- **Background:** `#eafaf1` (light green tint)

**State C: No upcoming PTM**

Card is **hidden entirely** — no empty state needed.

### Placement

| Condition | Position on Dashboard |
|-----------|----------------------|
| PTM exists (booked or not) | Below the 5 stat cards, **above** Today's Timetable. Full-width card. |
| No PTM | Card hidden. No placeholder. |
| PTM date < today | Card hidden (past event). |
| PTM date = today | Card shows with special "TODAY" badge: `🟢 TODAY — Your meeting is at 10:30 AM` |

### Data Specification

**New variables required in `ParentDashboardController::index()`:**

```
// Upcoming PTM event for this child's class/section
$ptmEvent = PtmEvent::active()
    ->upcoming()
    ->where(function ($q) use ($session) {
        $q->where('class_id', $session->classSection->class_id)
          ->where(function ($q2) use ($session) {
              $q2->whereNull('section_id')
                 ->orWhere('section_id', $session->classSection->section_id);
          });
    })
    ->with(['slots' => fn ($q) => $q->where('is_active', true)])
    ->first();

// Parent's existing booking for this PTM (if any)
$ptmBooking = null;
$ptmAvailableSlots = 0;
$ptmTotalSlots = 0;

if ($ptmEvent) {
    $ptmBooking = PtmBooking::where('guardian_id', $guardianId)
        ->where('student_id', $child->id)
        ->where('status', 'Booked')
        ->whereHas('slot', fn ($q) => $q->where('ptm_event_id', $ptmEvent->id))
        ->with(['slot.teacher'])
        ->first();

    $ptmTotalSlots = $ptmEvent->slots->sum('capacity');
    $ptmAvailableSlots = $ptmEvent->slots->sum(fn ($s) => max(0, $s->capacity - $s->booked_count));
}
```

**Pass to view:** `$ptmEvent`, `$ptmBooking`, `$ptmAvailableSlots`, `$ptmTotalSlots`

### Quick Navigation Enhancement

Add **10th item** (or replace if grid restructured to 2 rows x 5):

| Element | Value |
|---------|-------|
| Icon | `fa fa-calendar-check` |
| Label | "PTM" |
| Badge | Red "Book" if upcoming + not booked; Green check if booked; hidden if no PTM |
| Route | `parent-portal.ptm.index` |

### Acceptance Criteria

- [ ] AC-01: PTM card appears when an upcoming PTM exists for active child's class/section
- [ ] AC-02: "Not Booked" state shows red urgency styling and "Book Now" CTA
- [ ] AC-03: "Confirmed" state shows green styling with teacher name, time slot, and venue
- [ ] AC-04: "Cancel Booking" button present only if booking `isCancellable()` (not within 1 hour)
- [ ] AC-05: Slot count shows `available / total` (updated on page load, not live)
- [ ] AC-06: Card hidden when no upcoming PTM exists
- [ ] AC-07: Card hidden when PTM date is in the past
- [ ] AC-08: On PTM day, card shows "TODAY" badge with confirmed time
- [ ] AC-09: Multi-child — PTM card reflects **active child's** class/section only
- [ ] AC-10: "Book Now" navigates to `parent-portal.ptm.show` for that event

---

## 4. SC-PPT-D03: Dashboard — Complaints Quick Link

### Business Justification

Complaints are **parent-initiated**, not school-initiated. The parent knows they filed one. The primary need is **status update visibility**, not a persistent dashboard widget. A lightweight approach is appropriate: add to Quick Navigation + leverage existing Notifications card for updates.

### Wireframe — Quick Navigation Addition Only

```
┌──────────────────────────────────────────────────────────────────┐
│  Row 1:  Attendance | Timetable | Homework  | Results | Fees     │
│  Row 2:  Leave | Teachers | Notifications | Consent | PTM       │
│  Row 3:  📢 Complaints [3]  | 📄 Documents | 🎉 Events         │
└──────────────────────────────────────────────────────────────────┘
```

### Design Decision: NOT a Stat Card

| Option | Recommendation | Rationale |
|--------|---------------|-----------|
| Stat card (6th card) | **No** | Complaints don't have deadlines or require urgent action. Adding a stat card dilutes the urgency of the existing 5 cards. |
| Alert banner | **No** | Banner is reserved for compliance items (consent forms). Complaints are not compliance. |
| Quick Nav item | **Yes** | Quick access with badge showing open/in-progress count. Non-intrusive. |
| Notification feed | **Yes (complement)** | When admin responds to a complaint, it should appear in the existing Notifications card (last 5 items). This is the natural "status update" channel. |

### Quick Navigation Spec

| Element | Value |
|---------|-------|
| Icon | `fa fa-exclamation-triangle` |
| Label | "Complaints" |
| Badge | Orange pill with count of open + in-progress complaints; hidden if 0 |
| Route | `parent-portal.complaint.index` |

### Data Specification

**New variable in `ParentDashboardController::index()`:**

```
$openComplaintCount = \Modules\Complaint\Models\Complaint::where('created_by', auth()->id())
    ->whereIn('status', ['In-Progress', 'Open', 'Assigned', 'Under Review'])
    ->count();
```

**Pass to view:** `$openComplaintCount` (int)

### Notification Integration (No code change — verify existing behaviour)

When an admin updates a complaint status or adds a response, the Complaint module should dispatch a Laravel notification to the parent user. This notification will automatically appear in the existing "Recent Notifications" card on the dashboard.

**Verify:** Does `Modules/Complaint` dispatch notifications on status change? If not, this is a **dependency** for the complaints dashboard integration.

### Acceptance Criteria

- [ ] AC-01: Quick Nav shows "Complaints" item with open count badge
- [ ] AC-02: Badge hidden when open complaint count = 0
- [ ] AC-03: Badge colour: orange (`#f39c12`)
- [ ] AC-04: Clicking navigates to `parent-portal.complaint.index`
- [ ] AC-05: Complaint status updates appear in Notifications card (requires Complaint module notification dispatch — verify)

---

## 5. SC-PPT-T01: Parent Transport Page — Enhancements

### Current State (Already Good — Minor Gaps)

The Parent Portal transport page is comprehensive. It already shows:
- Pickup/drop routes with shift, stop name
- Vehicle number, model, capacity
- Driver name & phone (clickable `tel:` link)
- Helper/attendant name & phone
- Transport fare
- Live GPS map (OpenStreetMap embed) with speed, ETA, location
- Emergency flag alert
- RFID boarding log (last 5 events)

### Missing Items (Enhancement Requests)

| Gap ID | Missing Data | Priority | Source Table/Column |
|--------|-------------|----------|-------------------|
| TPT-P01 | **Scheduled pickup time** per stop | P1 | `tpt_pickup_point_routes.estimated_time` or `tpt_stops.pickup_time` |
| TPT-P02 | **Scheduled drop time** per stop | P1 | `tpt_stops.drop_time` or calculated from route |
| TPT-P03 | **Boarding notification** (push alert when child boards/alights) | P2 | Requires event dispatch from Transport module on `tpt_student_boarding_log` insert |
| TPT-P04 | **Route map** showing all stops on the route (not just live position) | P3 | `tpt_stops` coordinates for the route |

### Wireframe — Enhanced Pickup Card (additions in **bold**)

```
┌─── Pickup Route ────────────────────────────────────────────────────┐
│  Route Name:     Route A - North Zone                               │
│  Route Code:     RT-NORTH-01                                        │
│  Pickup Stop:    Green Park Colony, Gate 2                          │
│  **Pickup Time:  7:15 AM** ← NEW                                   │
│  Shift:          Morning                                            │
│  **ETA from school: ~25 min** ← NEW (from pickup_point_routes)     │
│                                                                      │
│  Effective From: 01 Apr 2026                                        │
└─────────────────────────────────────────────────────────────────────┘
```

### Wireframe — Enhanced Drop Card

```
┌─── Drop Route ──────────────────────────────────────────────────────┐
│  Route Name:     Route A - North Zone                               │
│  Route Code:     RT-NORTH-01                                        │
│  Drop Stop:      Green Park Colony, Gate 2                          │
│  **Drop Time:    2:30 PM** ← NEW                                   │
│  Shift:          Afternoon                                          │
│  Fare:           ₹3,500 / term                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Data Changes Required

**In `ParentTransportController::index()`:**

```php
// Add stop timing data (if columns exist on tpt_stops or tpt_pickup_point_routes)
$pickupTime = $allocation?->pickupStop?->pickup_time
    ?? $allocation?->pickupRoute?->pickupPointRoutes
        ->firstWhere('stop_id', $allocation?->pickup_stop_id)
        ?->estimated_time;

$dropTime = $allocation?->dropStop?->drop_time ?? null;
```

**Pass additionally:** `$pickupTime`, `$dropTime`

### Acceptance Criteria

- [ ] AC-01: Pickup time displayed if available in DB (graceful `—` if null)
- [ ] AC-02: Drop time displayed if available in DB (graceful `—` if null)
- [ ] AC-03: No layout change to existing sections (additive only)
- [ ] AC-04: Verify `tpt_stops` or `tpt_pickup_point_routes` has time columns before implementing

---

## 6. SC-STP-T01: Student Transport Page — Full Rebuild

### Current State (Severely Underdeveloped)

**Controller** (`StudentPortalController::transport()`):
- Fetches only: `pickupRoute`, `dropRoute`, `pickupStop`, `dropStop`
- Does NOT load: vehicle, driver, helper, shift, GPS, boarding log
- Only 2 variables passed: `$allocation`

**View** (`studentportal::transport.index`):
- Shows only: route name, route code, stop name, fare, effective date
- No vehicle info, no driver contact, no GPS, no boarding events
- **Critical safety gap: Student cannot identify their bus or contact driver**

### Proposed Full Wireframe

```
┌──────────────────────────────────────────────────────────────────────┐
│  My Transport                                          Home > Transport │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──── Pickup Route (green top border) ────┬──── Drop Route (blue)──┐│
│  │  Route:      Route A - North Zone       │  Route:   Route A      ││
│  │  Code:       RT-NORTH-01                │  Code:    RT-NORTH-01  ││
│  │  Stop:       Green Park Colony          │  Stop:    Green Park   ││
│  │  ⏰ Time:    7:15 AM               NEW │  ⏰ Time: 2:30 PM  NEW ││
│  │  Shift:      Morning               NEW │  Shift:   Afternoon NEW ││
│  │  From:       01 Apr 2026               │                         ││
│  └────────────────────────────────────────┴─────────────────────────┘│
│                                                                      │
│  ┌──── Vehicle & Staff (purple top border) ─────────────────────────┐│
│  │                                                                   ││
│  │  🚌 Vehicle                  👤 Driver          👤 Attendant     ││
│  │  ┌──────────────────┐       ┌───────────────┐  ┌──────────────┐ ││
│  │  │ KA-01-AB-1234    │       │ 🧑 Ramesh K.  │  │ 🧑 Suresh P. │ ││
│  │  │ Tata Starbus     │       │ 📞 9876543210 │  │ 📞 9876543211│ ││
│  │  │ 42 seats         │       │   [Call]       │  │   [Call]      │ ││
│  │  └──────────────────┘       └───────────────┘  └──────────────┘ ││
│  │                                                                   ││
│  │  Fare: ₹3,500 / term                                             ││
│  └──────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  ┌──── Live GPS Tracking (if available) ────────────────────────────┐│
│  │                                                                   ││
│  │  Status: 🟢 LIVE    Speed: 35 km/h    ETA: ~12 min              ││
│  │  Location: Near Rajaji Nagar, 4th Block                          ││
│  │                                                                   ││
│  │  ┌──────────────────────────────────────────────────────────┐    ││
│  │  │                                                          │    ││
│  │  │              [OpenStreetMap Embed]                        │    ││
│  │  │              Pin at GPS coordinates                       │    ││
│  │  │              250px height                                 │    ││
│  │  │                                                          │    ││
│  │  └──────────────────────────────────────────────────────────┘    ││
│  │                                                                   ││
│  │  ⚠️ Emergency Alert (red banner, only if emergency_flag=true)    ││
│  │                                                                   ││
│  └──────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  ┌──── Recent Boarding Log (RFID) ──────────────────────────────────┐│
│  │                                                                   ││
│  │  Date         │ Boarded   │ Alighted  │ Device                   ││
│  │  ─────────────┼───────────┼───────────┼──────────                ││
│  │  14 Apr 2026  │ 7:18 AM   │ 8:02 AM   │ BUS-RFID-01            ││
│  │  12 Apr 2026  │ 7:15 AM   │ 7:58 AM   │ BUS-RFID-01            ││
│  │  11 Apr 2026  │ 7:22 AM   │ 8:05 AM   │ BUS-RFID-01            ││
│  │  ... (last 5 records) ...                                        ││
│  │                                                                   ││
│  │  No boarding records yet. (empty state)                          ││
│  └──────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  ┌──── Not Assigned (empty state) ──────────────────────────────────┐│
│  │  🚌 (large icon, muted)                                          ││
│  │  No active transport allocation found.                            ││
│  │  Please contact the school office if you use school transport.    ││
│  └──────────────────────────────────────────────────────────────────┘│
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Controller Changes Required

**Replace** the current minimal `StudentPortalController::transport()` with full data loading, matching ParentTransportController pattern:

```php
// CURRENT (minimal — only 4 relations)
$allocation = TptStudentAllocationJnt::where('student_id', $student->id)
    ->where('active_status', true)
    ->with(['pickupRoute', 'dropRoute', 'pickupStop', 'dropStop'])
    ->first();

// PROPOSED (full parity with ParentTransportController)
$allocation = TptStudentAllocationJnt::where('student_id', $student->id)
    ->where('active_status', true)
    ->with([
        'pickupRoute.shift',
        'pickupRoute.pickupPointRoutes',
        'pickupStop',
        'dropRoute.shift',
        'dropStop',
        'pickupRoute.driverRouteVehicles' => fn ($q) => $q
            ->where('is_active', true)
            ->with(['vehicle', 'driver', 'helper'])
            ->latest(),
    ])
    ->first();

$vehicleAssignment = $allocation?->pickupRoute
    ?->driverRouteVehicles?->first();

// Live GPS (same logic as ParentTransportController)
$livePosition = null;
$gpsAvailable = Schema::hasTable('tpt_gps_trip_log')
    && Schema::hasTable('tpt_live_trip');
// ... (same GPS query as parent controller) ...

// Boarding log (same logic)
$boardingLog = collect();
if (Schema::hasTable('tpt_student_boarding_log')) {
    // ... (same query as parent controller) ...
}

// Pickup/drop times
$pickupTime = $allocation?->pickupStop?->pickup_time
    ?? $allocation?->pickupRoute?->pickupPointRoutes
        ->firstWhere('stop_id', $allocation?->pickup_stop_id)
        ?->estimated_time;
$dropTime = $allocation?->dropStop?->drop_time ?? null;

return view('studentportal::transport.index', compact(
    'allocation', 'vehicleAssignment',
    'livePosition', 'gpsAvailable', 'boardingLog',
    'pickupTime', 'dropTime',
));
```

### View Sections — Detail Spec

#### Section 1: Route Cards (2-column)

| Field | Pickup Card | Drop Card |
|-------|------------|-----------|
| Top border | 4px solid `#00b894` (green) | 4px solid `#0984e3` (blue) |
| Icon | `fa fa-arrow-circle-up text-success` | `fa fa-arrow-circle-down text-primary` |
| Route Name | `$pickup->name` | `$drop->name` |
| Route Code | `$pickup->code` in `<code>` tag | `$drop->code` in `<code>` tag |
| Stop Name | `$pStop->name` | `$dStop->name` |
| **Time** | `$pickupTime` formatted `h:i A` (or `—`) | `$dropTime` formatted `h:i A` (or `—`) |
| **Shift** | `$pickup->shift->name` (or `—`) | `$drop->shift->name` (or `—`) |
| Effective From | `$allocation->effective_from` (pickup only) | — |

#### Section 2: Vehicle & Staff Card

| Field | Source | Display |
|-------|--------|---------|
| Vehicle Number | `$vehicleAssignment->vehicle->registration_number` | Bold, blue, large font |
| Vehicle Model | `$vehicleAssignment->vehicle->manufacturer` + `model` | Normal text below number |
| Capacity | `$vehicleAssignment->vehicle->seating_capacity` | "{n} seats" |
| Driver Name | `$vehicleAssignment->driver->name` | With initials avatar |
| Driver Phone | `$vehicleAssignment->driver->phone` | Clickable `tel:` link with phone icon |
| Helper Name | `$vehicleAssignment->helper->name` | With initials avatar (hidden if null) |
| Helper Phone | `$vehicleAssignment->helper->phone` | Clickable `tel:` link (hidden if null) |
| Fare | `$allocation->fare` | `₹{formatted amount} / term` |

**Empty state:** If no vehicle assignment: "Vehicle details not yet assigned."

#### Section 3: Live GPS Tracking

| Element | Source | Behaviour |
|---------|--------|-----------|
| Status badge | `$livePosition` existence | Green "LIVE" if data present; grey "Offline" if null |
| GPS not available | `$gpsAvailable = false` | Show: "Live tracking is not yet enabled for this route." |
| No active trip | GPS available but `$livePosition = null` | Show: "No live trip in progress." |
| Location | `$livePosition['location']` | Text display |
| Speed | `$livePosition['speed']` | `{n} km/h` |
| ETA | `$livePosition['eta']` | `~{n} min` |
| Map | OpenStreetMap iframe embed | 100% width, 250px height, centered on lat/lng |
| Emergency | `$livePosition['emergency'] = true` | Red banner: "Emergency reported on this trip. Contact school immediately." |
| Last updated | `$livePosition['logged_at']` | Relative time: "Updated 2 minutes ago" |

#### Section 4: Boarding Log Table

| Column | Source | Format |
|--------|--------|--------|
| Date | `trip_date` | `d M Y` |
| Boarded | `boarding_time` | `h:i A` as green badge |
| Alighted | `unboarding_time` | `h:i A` as blue badge (or `—` if null) |
| Device | `device_id` | Code text |

**Empty state:** "No boarding records yet."
**Limit:** Last 5 records, ordered by `trip_date DESC, id DESC`

### Acceptance Criteria

- [ ] AC-01: Student transport page shows vehicle number, model, and capacity
- [ ] AC-02: Driver name and phone displayed with clickable `tel:` link
- [ ] AC-03: Helper/attendant info shown if assigned, hidden if null
- [ ] AC-04: Pickup and drop times displayed if available in DB
- [ ] AC-05: Shift name displayed for both routes
- [ ] AC-06: Live GPS map appears when GPS tables exist and trip is active
- [ ] AC-07: Emergency alert banner shown when `emergency_flag = true`
- [ ] AC-08: Boarding log shows last 5 RFID events
- [ ] AC-09: Graceful empty states for all optional sections
- [ ] AC-10: Layout matches ParentPortal transport page structure
- [ ] AC-11: No new DB tables or migrations required (reads existing Transport module data)
- [ ] AC-12: Fare amount displayed

---

## 7. Data Contract — Controller Changes

### ParentDashboardController::index() — New Variables

| Variable | Type | Query Source | Passed To View |
|----------|------|-------------|---------------|
| `$pendingConsentForms` | Collection | `ppt_consent_forms` LEFT ANTI-JOIN `ppt_consent_form_responses` | Yes |
| `$ptmEvent` | ?PtmEvent | `ppt_ptm_events` (active, upcoming, class/section match) | Yes |
| `$ptmBooking` | ?PtmBooking | `ppt_ptm_bookings` (guardian + student + event match) | Yes |
| `$ptmAvailableSlots` | int | Computed from `$ptmEvent->slots` | Yes |
| `$ptmTotalSlots` | int | Computed from `$ptmEvent->slots` | Yes |
| `$openComplaintCount` | int | `cmp_complaints` WHERE created_by = auth + status IN open states | Yes |

### StudentPortalController::transport() — Expanded Variables

| Variable | Type | Currently Passed | After Change |
|----------|------|:---:|:---:|
| `$allocation` | ?TptStudentAllocationJnt | Yes (minimal relations) | Yes (full relations) |
| `$vehicleAssignment` | ?DriverRouteVehicle | No | **Yes** |
| `$livePosition` | ?array | No | **Yes** |
| `$gpsAvailable` | bool | No | **Yes** |
| `$boardingLog` | Collection | No | **Yes** |
| `$pickupTime` | ?string | No | **Yes** |
| `$dropTime` | ?string | No | **Yes** |

---

## 8. Transport Feature Parity Matrix

| Feature | Parent (Current) | Parent (After) | Student (Current) | Student (After) |
|---------|:---:|:---:|:---:|:---:|
| Route name & code | Yes | Yes | Yes | Yes |
| Stop name | Yes | Yes | Yes | Yes |
| **Scheduled pickup/drop time** | No | **Yes** | No | **Yes** |
| Shift name | Yes | Yes | No | **Yes** |
| Vehicle number & model | Yes | Yes | No | **Yes** |
| Vehicle capacity | Yes | Yes | No | **Yes** |
| Driver name & phone | Yes | Yes | No | **Yes** |
| Helper name & phone | Yes | Yes | No | **Yes** |
| Fare amount | Yes | Yes | Yes | Yes |
| Effective from date | Yes | Yes | Yes | Yes |
| Live GPS map | Yes | Yes | No | **Yes** |
| GPS speed & ETA | Yes | Yes | No | **Yes** |
| Emergency flag | Yes | Yes | No | **Yes** |
| RFID boarding log | Yes | Yes | No | **Yes** |
| Boarding push notification | No | **P2** | No | **P2** |
| Route stop map | No | **P3** | No | **P3** |

---

## 9. Open Questions

| # | Question | Stakeholder | Impact |
|---|----------|------------|--------|
| Q-01 | Does the Complaint module dispatch Laravel notifications on status change? If not, complaints won't appear in the dashboard notifications card. | Dev team | SC-PPT-D03 dependency |
| Q-02 | Do `tpt_stops` or `tpt_pickup_point_routes` have scheduled time columns (`pickup_time`, `drop_time`, `estimated_time`)? Need to verify DDL. | DB Architect | SC-PPT-T01 & SC-STP-T01 feasibility |
| Q-03 | Should the dashboard Quick Navigation be restructured from 1 row x 8 to a 2-row or 3-row grid to accommodate new items (Consent, PTM, Complaints, Documents, Events)? | UI/UX | Layout decision |
| Q-04 | Should the Student Portal also get a PTM awareness card? (Students could remind parents.) | Product Owner | Scope decision |
| Q-05 | For multi-child parents: should consent form counts be aggregated across ALL children or only active child? Current spec says active child only. | Product Owner | SC-PPT-D01 scope |
| Q-06 | Should the Student transport page show driver phone number? Privacy consideration — some schools may not want students calling drivers directly. | Product Owner / School Admin | SC-STP-T01 field visibility |
| Q-07 | Should boarding push notifications (TPT-P03) be a Phase 1 or Phase 2 item? Requires Transport module event dispatch changes. | Product Owner | Prioritization |

---

## Appendix A: Dashboard Layout — Proposed Final State

```
┌──────────────────────────────────────────────────────────────────────┐
│  ⚠ CONSENT FORMS REQUIRING ATTENTION (banner, conditional) ← NEW   │
│  │ Form Title │ Deadline │ [Sign] │                                  │
├──────────┬──────────┬──────────┬──────────┬──────────────────────────┤
│ Attendance│ Homework │ Upcoming │ Fee Due  │ Leave Applications      │
│  85%     │ 3 pending│ 2 exams  │ ₹12,500  │ 5 total (2 pending)    │
├──────────┴──────────┴──────────┴──────────┴──────────────────────────┤
│                                                                      │
│  ┌─── 📅 PTM CARD (conditional, full width) ← NEW ─────────────┐   │
│  │  Status: NOT BOOKED / CONFIRMED with details                  │   │
│  │  [Book Now] or [View Details] / [Cancel]                      │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─── Today's Timetable (horizontal scroll) ────────────────────┐   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─ Child Profile ──┐  ┌─ Quick Navigation (expanded) ─────────┐   │
│  │  Avatar, Name    │  │  Row 1: Attendance | Timetable |       │   │
│  │  Class, Roll     │  │         Homework | Results | Fees      │   │
│  │  [Settings]      │  │  Row 2: Leave | Teachers | Notif |    │   │
│  └──────────────────┘  │         Consent [🔴2] | PTM [🟢] ← NEW│   │
│                         │  Row 3: Complaints [3] | Documents |  │   │
│                         │         Events | Transport | Health   │   │
│                         └──────────────────────────────────────-─┘   │
│                                                                      │
│  ┌─ Pending Homework ────┐  ┌─ Upcoming Exams ─────────────────┐   │
│  └───────────────────────┘  └──────────────────────────────────-┘   │
│                                                                      │
│  ┌─ Fee Status ──────────┐  ┌─ Notifications ──────────────────┐   │
│  └───────────────────────┘  └──────────────────────────────────-┘   │
└──────────────────────────────────────────────────────────────────────┘
```

---

**End of Document**

> Next steps: Review open questions (Q-01 through Q-07) with stakeholders, then proceed to implementation tickets.
