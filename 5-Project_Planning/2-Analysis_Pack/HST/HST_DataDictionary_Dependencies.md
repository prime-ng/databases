# Hostel (HST) — Data Dictionary + Cross-Module Dependency Map
Source: `HST_FRD_2026-06-29.md` §5 + DDL `Hostel_DDL_v4.sql` + `HST_Hostel.md` | Date: 2026-06-29

## Part A — Business Entity Dictionary (business view; privacy-classified)

| Business Entity | What it represents | Key information | Privacy |
|-----------------|--------------------|----------------|---------|
| Hostel/Building | A residential building | name, type (boys/girls), chief warden, active flag | Internal |
| Floor | A floor within a hostel | floor number (unique/hostel), active flag | Internal |
| Room | A room on a floor | number (unique/floor), room type, capacity, status (Available/Full/Maintenance) | Internal |
| Bed | A bed within a room | label (unique/room), bed type, status, current allotment | Internal |
| Config Master | Configurable value lists | status / room-type / bed-type options, active flag | Internal |
| Warden Assignment | Warden→hostel/floor scope | warden, scope, role (chief/block/floor), current flag | Internal |
| Duty Roster | On-duty warden per shift | hostel, date, shift, warden | Internal |
| Bed Allotment | A student's active bed | student, bed, session, status, dates | **Confidential** (student) |
| Room Reservation | Pre-admission hold | prospective name/student, bed, hold-until, status | Confidential |
| Room Change Request | A move request | from/to bed, reason, status, rejection reason | Internal |
| Attendance Session / Record | Roll-call per shift | hostel, date, shift, per-student present/absent/leave/sick | Confidential |
| Movement (In-Out) | Gate pass register | student, out-time, expected/actual return, overdue flag | Confidential |
| Leave Pass | Approved leave | student, dates, reason, guardian, status, consent | Confidential |
| Mess Menu | Weekly menu | hostel, week, day, meal, items | Public (within school) |
| Special Diet | Per-student diet | student, diet type, dates, ongoing flag | **Sensitive** (health) |
| Mess Attendance | Per-meal presence | hostel, date, meal, student | Internal |
| Mess Opt-Out / Bill | Opt-outs + monthly bill | student, meal, date; bill base/diet/leave/optout/adj/total | Confidential (financial) |
| Fee Structure | Charge config | hostel, session, room-type, meal-plan, rate, effective-from | Internal |
| Fee Demand | Charge raised on student | student, amount, source, status | Confidential (financial) |
| Discipline Incident / Warning | Conduct record + letter | student, severity, description, warning content (immutable) | **Confidential** |
| Complaint | Hostel complaint | raiser, category, status, SLA, resolution note | Confidential |
| Visitor | Visit register | visitor, student, in/out, override reason, media | Confidential |
| Sick Bay (admission/vitals/meds) | Infirmary record | student, admit/discharge, vitals, medications | **Sensitive** (health) |
| Room Inventory / Maintenance / Housekeeping | Asset & upkeep | item, condition, ticket, photos | Internal |
| Laundry Ticket | Laundry handling | student, items, status, loss/damage | Internal |
| Emergency Contact | Hostel-level contacts | type, name, phone (doctor/ambulance/police…) | Internal |
| Audit Log / Notification Log | Change & dispatch trail | actor, before/after, channel, status | Internal |

**Retention:** academic-year-scoped operational data retained for audit; health (sick bay, special diet) and discipline records are sensitive and access-restricted to warden/medical roles. **Per-tenant isolation:** all `hst_*` data is isolated within the school's database.

## Part B — Cross-Module Dependency Map

### Inbound (Hostel reads from)
| Source Module | Data/Entity | Why |
|---------------|-------------|-----|
| StudentProfile (STD) | student, gender, session | allotment, attendance, leave, fees |
| SchoolSetup (SCH) | academic session, organization | year-scoping, branding |
| System (SYS) | users, media, dropdowns, activity log | wardens, photos, config masters, audit |
| HrStaff | warden staff records | warden assignment/roster |

### Outbound (Hostel feeds)
| Target Module | Mechanism | What |
|---------------|-----------|------|
| StudentFee (FIN) | service/demand push | hostel fees, mess bills, damage-recovery, laundry recovery (BR-011/025/028/032; REQ-019) |
| Notification (NTF) | notification events | parent alerts: absence (BR-017), incident (BR-008), movement overdue (BR-031), sick bay (BR-049), complaint escalation (BR-020) |
| HPC (Holistic Progress Card) | record link | sick-bay / discipline signals feed wellbeing (D34) |
| Accounting (ACC) | voucher (future) | mess/fee receipts (deferred) |

### Integration risk (from audit)
- **FIN demand push** (REQ-019 / BR-011/032) — `forwardToStudentFee()` returns null (BUG-HST-007): demands computed but **not delivered**.
- **NTF parent alerts** (BR-008/017/031/049) — delivery is a `Log::info` stub with 0 listeners (BUG-HST-006): **computed, not sent**.
- **Complaint SLA escalation** (BR-020) — scheduled centrally without per-tenant wrapping (JOB-HST-001): **never fires per tenant**.
> These three are the cross-module wiring gaps to close before the dependent BRs can be considered enforced.
