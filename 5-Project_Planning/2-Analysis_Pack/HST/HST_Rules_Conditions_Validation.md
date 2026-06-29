# Hostel (HST) — Business Rules + Requirement Conditions + Validation & Edge-Case Catalog
Source: `HST_FRD_2026-06-29.md` §4 | Date: 2026-06-29 | All IDs reused from the FRD (no renumbering).

## Part A — Business Rules Register (54)

| BR | Rule | Type | Pri | REQ |
|----|------|------|-----|-----|
| BR-HST-001 | A bed can have only one active allotment at a time | Concurrency | P0 | 008 |
| BR-HST-002 | A student can have only one active allotment at a time | Concurrency | P0 | 008 |
| BR-HST-003 | Student gender must match hostel type before allotment | Validation | P0 | 008 |
| BR-HST-004 | Leave pass end date on/after start date | Validation | P0 | 013 |
| BR-HST-005 | Leave approval auto-marks leave-period shifts on-leave | Workflow | P0 | 013 |
| BR-HST-006 | Leave approval auto-marks leave-period meals on-leave | Workflow | P0 | 013,016 |
| BR-HST-007 | Attendance session unique per hostel/date/shift | Concurrency | P0 | 011 |
| BR-HST-008 | Moderate/serious incidents auto-notify parent | Workflow | P0 | 020 |
| BR-HST-009 | Hostel cannot be deactivated with active allotments | Validation | P0 | 001 |
| BR-HST-010 | Room status auto Full/Available vs capacity | Calculation | P0 | 003 |
| BR-HST-011 | Prorated fee = (monthly ÷ 30) × remaining days | Calculation | P0 | 019 |
| BR-HST-012 | Late return auto-creates late-arrival incident | Workflow | P0 | 013 |
| BR-HST-013 | Block/floor wardens scoped to assigned hostels/floors | Permission | P0 | 006,027,028 |
| BR-HST-014 | Academic-year bulk vacate needs typed confirm; audited; irreversible | Workflow | P0 | 008 |
| BR-HST-015 | Fee structure must exist for room type + meal plan before allotment | Validation | P0 | 008 |
| BR-HST-016 | Sick-bay admission auto-marks attendance sick-bay | Workflow | P1 | 023 |
| BR-HST-017 | Absent at roll call (not leave/sick) → parent notification | Workflow | P0 | 011 |
| BR-HST-018 | Below attendance threshold (90%) flagged on dashboard | Calculation | P1 | 011,027 |
| BR-HST-019 | Warden may view outstanding fees before approving leave (advisory) | Permission | P1 | 013 |
| BR-HST-020 | Complaint past deadline (48h) auto-escalates to chief warden | Workflow | P1 | 021 |
| BR-HST-021 | Visit outside visiting hours requires warden override + reason | Validation | P1 | 022 |
| BR-HST-022 | Incident threshold (3/yr) → repeated-offender flag | Calculation | P1 | 020 |
| BR-HST-023 | Unconfirmed reservation past hold period auto-expires, frees bed | Workflow | P1 | 009 |
| BR-HST-024 | Reservation→allotment only if student exists and bed free | Validation | P1 | 009 |
| BR-HST-025 | Monthly mess bill total system-computed, not manually overwritten | Calculation | P1 | 017 |
| BR-HST-026 | Meal opt-out before configured cut-off | Validation | P1 | 017 |
| BR-HST-027 | Bed under maintenance cannot receive new allotment | Validation | P0 | 004 |
| BR-HST-028 | Lost/damaged laundry may raise recovery charge | Workflow | P2 | 025 |
| BR-HST-029 | Sick-bay admission blocked at capacity | Validation | P1 | 023 |
| BR-HST-030 | Attendance session editable by chief warden ≤24h, then locked | Workflow | P0 | 011 |
| BR-HST-031 | Movement overdue beyond 30 min → parent notification | Workflow | P1 | 012 |
| BR-HST-032 | Damage-recovery charge pushed only after responsible student identified | Validation | P1 | 019,024 |
| BR-HST-033 | One current chief warden per hostel; new ends prior | Workflow | P0 | 001,006 |
| BR-HST-034 | Warning-letter content immutable once generated; retained | Workflow | P0 | 020 |
| BR-HST-035 | Floor number unique within a hostel | Validation | P0 | 002 |
| BR-HST-036 | Floor cannot deactivate with active rooms | Validation | P0 | 002 |
| BR-HST-037 | Room number unique within its floor | Validation | P0 | 003 |
| BR-HST-038 | Bed label unique within its room | Validation | P0 | 004 |
| BR-HST-039 | Status/room-type/bed-type values are config masters | Configuration | P0 | 005 |
| BR-HST-040 | A master option in use cannot be deleted, only deactivated | Validation | P0 | 005 |
| BR-HST-041 | Attendance session attributed to on-duty warden | Workflow | P2 | 007 |
| BR-HST-042 | Rejected room-change must record a reason | Validation | P1 | 010 |
| BR-HST-043 | Room-change approval closes old allotment, creates new active | Workflow | P1 | 010 |
| BR-HST-044 | One mess-menu entry per hostel/week/day/meal | Validation | P1 | 014 |
| BR-HST-045 | Special diet auto-expires at end date unless ongoing | Workflow | P1 | 015 |
| BR-HST-046 | One mess-attendance record per hostel/date/meal/student | Validation | P1 | 016 |
| BR-HST-047 | One fee structure per hostel/session/room-type/meal-plan/effective-from | Validation | P0 | 018 |
| BR-HST-048 | Complaint not resolvable without a resolution note | Validation | P1 | 021 |
| BR-HST-049 | Sick-bay admission and discharge each notify parent | Workflow | P1 | 023 |
| BR-HST-050 | Bed with open maintenance ticket unavailable until closed | Workflow | P1 | 024 |
| BR-HST-051 | Hostel emergency contacts are hostel-level | Configuration | P2 | 026 |
| BR-HST-052 | Dashboard occupancy/attendance use pre-computed counts | Calculation | P0 | 027 |
| BR-HST-053 | Each report scoped to user's permitted hostels/floors | Permission | P1 | 028 |
| BR-HST-054 | Audit trail written automatically, not user-editable | Workflow | P1 | 029 |

**By type:** Validation 19 · Workflow 18 · Calculation 7 · Concurrency 3 · Permission 4 · Configuration 3.

## Part B — Requirement Conditions Catalog (keyed to BR IDs; populates `5-Requirement_Conditions/`)
*Each condition states its trigger and the on-violation behaviour a tester can verify.*

| Cond (=BR) | Entity/Field | Condition | Trigger | On-Violation Behaviour |
|------------|-------------|-----------|---------|------------------------|
| BR-HST-001 | Bed.active_allotment | ≤1 active allotment per bed | Allot / room-change | Reject "Bed already occupied"; no 2nd row created |
| BR-HST-002 | Student.active_allotment | ≤1 active allotment per student | Allot | Reject "Student already allotted" |
| BR-HST-003 | Student.gender vs Hostel.type | gender matches hostel type | Allot | Reject "Gender mismatch with hostel" |
| BR-HST-009 | Hostel.is_active | no active allotments when deactivating | Deactivate hostel | Block; list blocking allotments |
| BR-HST-015 | FeeStructure | exists for room-type+meal-plan | Allot | Block allotment until fee structure created |
| BR-HST-027/050 | Bed.status | not Maintenance / no open ticket | Allot | Reject "Bed under maintenance" |
| BR-HST-004 | LeavePass.dates | end ≥ start | Save leave | Field error; not saved |
| BR-HST-026 | MealOptOut.requested_at | before cut-off | Opt-out request | Reject "Past opt-out cut-off" |
| BR-HST-021 | Visit.time | within visiting hours OR override+reason | Log visit | Require warden override + reason |
| BR-HST-029 | SickBay.occupancy | < capacity | Admit | Block "Sick bay full" |
| BR-HST-048 | Complaint.resolution_note | present before Resolved | Resolve complaint | Block "Resolution note required" |
| BR-HST-035/037/038/044/046/047 | uniqueness keys | unique within parent scope | Create | Reject duplicate with scope message |
| BR-HST-024 | Reservation→Allotment | student exists + bed free | Convert | Block; keep reservation pending |
| BR-HST-032 | DamageCharge.student | responsible student identified | Push charge | Hold charge until student set |
| BR-HST-040 | Master option in use | not referenced when deleting | Delete master | Block; offer deactivate |
| BR-HST-036 | Floor.is_active | no active rooms when deactivating | Deactivate floor | Block |

## Part C — Validation & Edge-Case Catalog (highest-risk rules)
| Rule | Valid | Invalid | Boundary | Empty/Null | Concurrency |
|------|-------|---------|----------|-----------|-------------|
| BR-HST-001/002 (single active allotment) | allot free bed to unallotted student | allot occupied bed / already-allotted student | last free bed in room | null bed/student → reject | **two wardens allot same bed simultaneously → exactly one succeeds (row lock / UNIQUE)** ⚠ DAT-HST-001 |
| BR-HST-010/052 (occupancy count) | count rises on allot, falls on vacate | manual count edit | room hits capacity → Full | zero occupancy → Available | **concurrent allot/vacate must not drift count** ⚠ DAT-HST-002 |
| BR-HST-011 (proration) | mid-month join → (rate÷30)×remaining | negative/zero days | join on 1st = full; on last day = 1 day | null effective-from → reject | n/a |
| BR-HST-025 (mess bill) | total = base+diet−leave−optout+adj | manual total overwrite blocked | all-leave month = 0 | null components → 0 | **bill compute vs concurrent opt-out** ⚠ MIG-HST-001 (must be generated) |
| BR-HST-007/030 (attendance session) | one session/hostel/date/shift | duplicate create returns existing | edit at 23h59 ok, 24h01 locked | — | **two wardens open same session → one row** |
| BR-HST-005/006 (leave auto-mark) | approve → shifts+meals on-leave | partial mark | leave spanning month boundary | — | leave approve vs roll-call same minute |
| BR-HST-023 (reservation expiry) | expires past hold, frees bed | early expiry | exactly at hold deadline | — | expiry job vs manual confirm |
| BR-HST-034 (warning immutable) | generated letter read-only | edit attempt blocked | — | — | — |

> ⚠ markers = rules with a confirmed audit defect (DAT-HST-001/002, MIG-HST-001) — prioritise their tests.
