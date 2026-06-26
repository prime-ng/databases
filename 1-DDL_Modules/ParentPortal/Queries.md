
## Perant Portal : information required
---------------------------------------
- Where to show consent forms in the Dashboard?
- Where to create/show Parent Meeting confirmation?
- Where to show complaints in the Dashboard ?
- What data to show in the Transport page of Parent & Student ?



Q1: Where to show Consent Forms on Parent Dashboard?

  Current state: Consent forms have a full CRUD controller (ParentConsentFormController) and dedicated pages, but zero presence on the dashboard.

  Recommendation — Add a "Consent Forms" alert card:

  ┌──────────────────────────────────────────┬───────────────────────────────────────────────┬────────────────────────────────────────────┐
  │                         Placement        │                        What to show           │                              Why           │
  ├──────────────────────────────────────────┼───────────────────────────────────────────────┼────────────────────────────────────────────┤
  │ Top area — as a 6th stat card (or alert  │ Count of pending consent forms (not yet       │ Parents MUST act on these — they are       │
  │ banner above the 5 existing cards)       │ signed/declined, not past deadline)           │ time-sensitive and school-compliance items │
  ├──────────────────────────────────────────┼───────────────────────────────────────────────┼────────────────────────────────────────────┤
  │ Quick Navigation menu (add as 9th item)  │ "Consent Forms" with red badge if pending > 0 │ Easy access from dashboard                 │
  └──────────────────────────────────────────┴───────────────────────────────────────────────┴────────────────────────────────────────────┘

  Widget data needed:
  - pendingConsentCount = ConsentForm::active() → targeted to child's class/section → where no response exists for this guardian+student → where deadline not passed
  - Color: Red/urgent if pending > 0, Green if all signed

  Rationale: Consent forms are legal/compliance documents (field trips, medical consent, photo consent). Unlike homework, parents can't "catch up later" — deadlines are hard. This must be
  prominent, not buried in a sub-page.

  ---
  Q2: Where to create/show Parent Meeting (PTM) confirmation?

  Current state: ParentPtmController has full booking flow (index → show → book → cancel), but zero dashboard presence.

  Recommendation — Two placements:

  A. Dashboard Alert Card (conditional)

  ┌──────────────────────────────────┬────────────────────────────────────────┬────────────────────────────────────────┐
  │           Placement              │             What to show               │              When                      │
  ├──────────────────────────────────┼────────────────────────────────────────┼────────────────────────────────────────┤
  │ Alert banner at top of dashboard │ "PTM scheduled on {date} — {booked/not │ Only when an upcoming PTM event exists │
  │ (above stat cards)               │ booked}" with action button            │  for child's class/section             │
  └──────────────────────────────────┴────────────────────────────────────────┴────────────────────────────────────────┘

  Show:
  - If not booked: "PTM on 20-Apr-2026 — Book your slot now" → link to parent-portal.ptm.show
  - If booked: "PTM on 20-Apr-2026 — Slot confirmed: 10:30 AM with Mrs. Sharma" → link to booking detail
  - If past deadline & not booked: "PTM on 20-Apr-2026 — Booking closed" (grey)

  B. Quick Navigation Menu

  Add "PTM" as a navigation item with badge:
  - Red badge = upcoming PTM, no booking yet
  - Green badge = booking confirmed
  - No badge = no upcoming PTM

  Rationale: PTM is a calendar-critical event. Parents must book slots before capacity fills up. The atomic booking logic already handles race conditions — the dashboard just needs to surface
  urgency.

  ---
  Q3: Where to show Complaints on Parent Dashboard?

  Current state: ParentComplaintController has index/create/store, but zero dashboard presence.

  Recommendation — Light-touch approach:

  ┌──────────────────────────────────┬───────────────────────────────────────────────────────────┬──────────────────────────────────────────────────────────────────────────────────────────┐
  │            Placement             │                       What to show                        │                                           Why                                            │
  ├──────────────────────────────────┼───────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────┤
  │ Quick Navigation menu (add item) │ "My Complaints" with badge showing open/in-progress count │ Complaints are not urgent dashboard items — they're reference/tracking                   │
  ├──────────────────────────────────┼───────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────┤
  │ NOT a top stat card              │ —                                                         │ Unlike consent forms or PTM, complaints don't have deadlines or require immediate action │
  └──────────────────────────────────┴───────────────────────────────────────────────────────────┴──────────────────────────────────────────────────────────────────────────────────────────┘

  Optional enhancement: If a complaint has a new response/update from admin, show it in the Notifications card (which already shows last 5 notifications). This avoids cluttering the dashboard
  while ensuring the parent doesn't miss updates.

  Rationale: Complaints are initiated by the parent, not the school. The parent knows they filed one. What they need is status update visibility, which is better served via notifications than a
  persistent dashboard widget.

  ---
  Q4: What data to show on Transport page — Parent vs. Student?

  Current State Comparison

  ┌───────────────────────────────┬─────────────────────────┬────────────────┐
  │          Data Point           │      Parent Portal      │ Student Portal │
  ├───────────────────────────────┼─────────────────────────┼────────────────┤
  │ Pickup route name & code      │           Yes           │      Yes       │
  ├───────────────────────────────┼─────────────────────────┼────────────────┤
  │ Pickup stop name              │           Yes           │      Yes       │
  ├───────────────────────────────┼─────────────────────────┼────────────────┤
  │ Drop route name & code        │           Yes           │      Yes       │
  ├───────────────────────────────┼─────────────────────────┼────────────────┤
  │ Drop stop name                │           Yes           │      Yes       │
  ├───────────────────────────────┼─────────────────────────┼────────────────┤
  │ Shift name                    │           Yes           │       No       │
  ├───────────────────────────────┼─────────────────────────┼────────────────┤
  │ Vehicle number & model        │           Yes           │       No       │
  ├───────────────────────────────┼─────────────────────────┼────────────────┤
  │ Vehicle capacity              │           Yes           │       No       │
  ├───────────────────────────────┼─────────────────────────┼────────────────┤
  │ Driver name & phone           │           Yes           │       No       │
  ├───────────────────────────────┼─────────────────────────┼────────────────┤
  │ Helper/Attendant name & phone │           Yes           │       No       │
  ├───────────────────────────────┼─────────────────────────┼────────────────┤
  │ Fare/fee amount               │           Yes           │      Yes       │
  ├───────────────────────────────┼─────────────────────────┼────────────────┤
  │ Effective from date           │           Yes           │      Yes       │
  ├───────────────────────────────┼─────────────────────────┼────────────────┤
  │ Live GPS tracking             │ Yes (map + speed + ETA) │       No       │
  ├───────────────────────────────┼─────────────────────────┼────────────────┤
  │ RFID boarding log             │   Yes (last 5 events)   │       No       │
  ├───────────────────────────────┼─────────────────────────┼────────────────┤
  │ Emergency flag                │           Yes           │       No       │
  └───────────────────────────────┴─────────────────────────┴────────────────┘

  The Problem

  Student transport view is severely underdeveloped. It only shows route/stop names — no vehicle, no driver, no GPS, no boarding logs. This is a significant gap.

  Recommendation — What BOTH portals should show:

  ┌──────────────────────────────┬──────────┬──────────┬────────────────────────────────────────────────────────────────┐
  │          Data Point          │  Parent  │ Student  │                             Notes                              │
  ├──────────────────────────────┼──────────┼──────────┼────────────────────────────────────────────────────────────────┤
  │ Route & Stop (pickup + drop) │   Yes    │   Yes    │ Core info                                                      │
  ├──────────────────────────────┼──────────┼──────────┼────────────────────────────────────────────────────────────────┤
  │ Shift & Timing               │   Yes    │   Yes    │ Student needs to know bus time                                 │
  ├──────────────────────────────┼──────────┼──────────┼────────────────────────────────────────────────────────────────┤
  │ Vehicle number               │   Yes    │   Yes    │ Student must identify the bus                                  │
  ├──────────────────────────────┼──────────┼──────────┼────────────────────────────────────────────────────────────────┤
  │ Driver name & phone          │   Yes    │   Yes    │ Safety — student must be able to contact in emergency          │
  ├──────────────────────────────┼──────────┼──────────┼────────────────────────────────────────────────────────────────┤
  │ Helper/Attendant name        │   Yes    │   Yes    │ Safety                                                         │
  ├──────────────────────────────┼──────────┼──────────┼────────────────────────────────────────────────────────────────┤
  │ Fare amount                  │   Yes    │ Optional │ Less relevant for student                                      │
  ├──────────────────────────────┼──────────┼──────────┼────────────────────────────────────────────────────────────────┤
  │ Live GPS                     │   Yes    │   Yes    │ Student waiting at stop needs ETA just as much as parent       │
  ├──────────────────────────────┼──────────┼──────────┼────────────────────────────────────────────────────────────────┤
  │ Boarding log                 │   Yes    │ Optional │ More useful for parent oversight                               │
  ├──────────────────────────────┼──────────┼──────────┼────────────────────────────────────────────────────────────────┤
  │ Emergency alert              │   Yes    │   Yes    │ Both must see emergency status                                 │
  ├──────────────────────────────┼──────────┼──────────┼────────────────────────────────────────────────────────────────┤
  │ Expected pickup time         │   Add    │   Add    │ Both portals missing this — the scheduled stop time from route │
  ├──────────────────────────────┼──────────┼──────────┼────────────────────────────────────────────────────────────────┤
  │ Bus capacity/occupancy       │ Optional │    No    │ Nice-to-have for parent                                        │
  └──────────────────────────────┴──────────┴──────────┴────────────────────────────────────────────────────────────────┘

  Key additions needed for Student Portal transport:

  1. Vehicle number & model (currently missing)
  2. Driver name & phone (currently missing — safety issue)
  3. Live GPS map with ETA (currently missing)
  4. Expected pickup/drop time from route schedule
  5. Emergency contact/flag

  Key additions needed for Parent Portal transport (already good, minor gaps):

  1. Expected pickup/drop scheduled time per stop (not currently shown)
  2. Boarding notification push (currently only shows log, no alert)

  ---
  Want me to draft screen specs or wireframe descriptions for any of these changes?