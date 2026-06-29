# Hostel (HST) — User Stories + KPI Catalog
Source: `HST_FRD_2026-06-29.md` | Date: 2026-06-29 | Stories link to REQ-/BR- IDs (no renumbering).

## Part A — User Stories (every P0/P1 REQ; P2 on request)

### Fully-expanded (Gherkin) — highest-value flows

**US-HST-008 · P0 · REQ-HST-008 — Bed allotment**
> As a **Warden**, I want to allot a student to a free bed so that they have a confirmed place.
```
Scenario: Happy path
  Given a free bed in a hostel matching the student's gender and a fee structure exists
  When I allot the student to the bed
  Then the bed shows one active allotment and room occupancy increments
Scenario: Bed already occupied (BR-001)
  Given a bed with an active allotment
  When another warden allots a second student to it at the same time
  Then exactly one allotment succeeds and the other is rejected "Bed already occupied"
Scenario: Gender mismatch (BR-003)
  Given a girls' hostel
  When I allot a boy student
  Then the system rejects "Gender mismatch with hostel"
Definition of Done: occupancy count correct; audit logged; concurrency safe (row lock/UNIQUE).
```

**US-HST-013 · P0 · REQ-HST-013 — Leave pass**
> As a **Warden**, I want to approve a leave pass so that shifts and meals auto-mark on-leave.
```
Scenario: Approve (BR-005/006)
  Given a leave pass with end date on/after start date
  When I approve it
  Then all roll-call shifts and meals in the period are marked on-leave and the parent is notified
Scenario: Late return (BR-012)
  Given an approved leave whose expected return time has passed
  When the student is marked returned late
  Then a system-generated late-arrival incident is created
Scenario: Invalid dates (BR-004)
  Given end date before start date
  When I save → rejected with a field error
```

**US-HST-011 · P0 · REQ-HST-011 — Roll-call attendance**
> As a **Warden**, I want to mark roll-call so absentees' parents are alerted.
```
Scenario: Absence alert (BR-017)
  Given a student not on leave or in sick bay
  When I mark them absent at roll call
  Then a parent notification is dispatched
Scenario: One session per shift (BR-007)
  When I open a roll-call for a hostel/date/shift that already has one
  Then the existing session is returned (no duplicate)
Scenario: Edit lock (BR-030)
  Given a session older than 24 hours
  When a warden tries to edit it → blocked (locked)
```

### Compact stories — remaining P0/P1 REQs (As-a / I-want / so-that · key AC → REQ)
| US | Role | I want… | so that… | Key AC (BR) | REQ |
|----|------|---------|----------|-------------|-----|
| US-HST-001 | Admin | configure a hostel | rooms attach to it | can't deactivate with allotments (BR-009); one chief warden (BR-033) | 001 |
| US-HST-002 | Admin | manage floors | rooms group by floor | floor number unique (BR-035); no deactivate w/ rooms (BR-036) | 002 |
| US-HST-003 | Admin | set up rooms | beds attach | room status auto Full/Available (BR-010); number unique (BR-037) | 003 |
| US-HST-004 | Admin | manage beds | students allot | bed unique/room (BR-038); maintenance bed not allottable (BR-027) | 004 |
| US-HST-005 | Admin | configure masters | values aren't hard-coded | in-use option not deletable (BR-040) | 005 |
| US-HST-006 | Admin | assign wardens | scoped access | wardens scoped to hostels/floors (BR-013) | 006 |
| US-HST-018 | Accountant | define fee structures | fees compute | one per hostel/session/type/plan/date (BR-047) | 018 |
| US-HST-019 | Accountant | assign & push fees | dues reach accounts | prorate (BR-011); push after student set (BR-032) | 019 |
| US-HST-020 | Warden | log discipline incidents | parents informed | moderate/serious notify (BR-008); letter immutable (BR-034); 3/yr flag (BR-022) | 020 |
| US-HST-027 | Chief Warden | see a live dashboard | manage at a glance | pre-computed counts (BR-052); below-90% flag (BR-018) | 027 |
| US-HST-009 | Warden | reserve a room pre-admission | hold a bed | auto-expire past hold (BR-023); convert if free (BR-024) | 009 |
| US-HST-010 | Warden | process room-change | students move | reject needs reason (BR-042); approve transfers (BR-043) | 010 |
| US-HST-012 | Warden | log in-out movement | overdue flagged | overdue 30 min → alert (BR-031) | 012 |
| US-HST-014 | Mess Supervisor | plan weekly menu | boarders know meals | one entry/hostel/week/day/meal (BR-044) | 014 |
| US-HST-015 | Medical | assign special diets | dietary needs met | auto-expire unless ongoing (BR-045) | 015 |
| US-HST-016 | Mess Supervisor | mark mess attendance | billing inputs | one record/hostel/date/meal/student (BR-046) | 016 |
| US-HST-017 | Accountant | run mess opt-out & billing | accurate bills | cut-off (BR-026); total system-computed (BR-025) | 017 |
| US-HST-021 | Warden | manage complaints | issues resolved/escalated | no resolve w/o note (BR-048); 48h escalate (BR-020) | 021 |
| US-HST-022 | Warden | log visitors | campus safe | outside-hours needs override (BR-021) | 022 |
| US-HST-023 | Medical | run sick bay | health tracked | capacity block (BR-029); admit/discharge notify (BR-049) | 023 |
| US-HST-024 | Warden | track inventory & maintenance | beds safe | open ticket → bed unavailable (BR-050) | 024 |
| US-HST-028 | Chief Warden | run reports | inspection-ready | scoped to permitted hostels (BR-053) | 028 |
| US-HST-029 | Admin | rely on an audit trail | accountability | auto-written, not editable (BR-054) | 029 |

> Coverage: **26/26 P0+P1 REQs have a story** (quality-gate satisfied). P2 (007/025/026) stories on request.

## Part B — KPI / Metrics Catalog
| KPI | Definition / Formula (business) | Source | Target | Cadence |
|-----|--------------------------------|--------|--------|---------|
| Bed Occupancy % | active allotments ÷ total beds | RPT-001 | 85–95% | Weekly |
| Roll-call Attendance % | present ÷ (boarders − on-leave − sick) | RPT-002 | ≥ 98% | Daily |
| Students Below Threshold | count with attendance < 90% (BR-018) | Dashboard | trend ↓ | Daily |
| Leave Compliance | on-time returns ÷ total returns | RPT-003 | ≥ 95% | Monthly |
| Movement Overdue Rate | overdue returns ÷ total movements (BR-031) | RPT-004 | < 2% | Weekly |
| Hostel Fee Collection % | collected ÷ demanded (BR-011) | RPT-005 | ≥ 90% | Monthly |
| Discipline Incident Rate | incidents ÷ boarders; repeated offenders (BR-022) | RPT-006 | trend ↓ | Monthly |
| Mess Cost / Boarder | total mess bill ÷ boarders (BR-025) | RPT-007 | budget band | Monthly |
| Complaint SLA Compliance | resolved-within-48h ÷ total (BR-020) | complaint data | ≥ 90% | Monthly |
| Sick Bay Admissions | admissions; recurring-illness count | RPT-013 | trend ↓ | Monthly |
| Maintenance Turnaround | avg open→close days for bed tickets (BR-050) | RPT-009 | < 3 days | Weekly |
| Notification Delivery % | delivered ÷ dispatched per channel | notification log | ≥ 98% | Weekly |
