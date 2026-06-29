# Hostel (HST) — Process Flows + State Machine (FSM) Catalog
Source: `HST_FRD_2026-06-29.md` §6 | Date: 2026-06-29 | Full step detail in FRD §6; this formalises FSMs.

## Part A — Process Flow Index (10 workflows, FRD §6)
| WF | Name | Trigger → End | Key BRs | Exception path | Notifications |
|----|------|---------------|---------|----------------|---------------|
| 6.1 | Student Room Allocation | Allot request → Active allotment | BR-001/002/003/015/027 | gender/fee/maintenance block | — |
| 6.2 | Room Change Request | Request → new active allotment | BR-042/043 | reject w/ reason | student informed |
| 6.3 | Leave Pass Approval & Return | Apply → Approved → Returned | BR-004/005/006/012/019 | late return → incident (BR-012) | parent on approve/return |
| 6.4 | Daily Roll-Call & Absence Alert | Open session → Locked | BR-007/017/018/030 | absent → alert (BR-017) | parent on absent |
| 6.5 | In-Out Movement & Overdue Return | Out → In | BR-031 | overdue → alert | parent on overdue |
| 6.6 | Discipline Incident & Escalation | Log → Resolved | BR-008/022/034 | repeated offender flag | parent on moderate/serious |
| 6.7 | Complaint SLA & Escalation | Raise → Resolved | BR-020/048 | past 48h → escalate | chief warden on breach |
| 6.8 | Sick Bay Admission & Discharge | Admit → Discharged | BR-016/029/049 | full → block | parent on admit & discharge |
| 6.9 | Mess Opt-Out & Monthly Billing | Opt-out → Bill | BR-025/026 | past cut-off → reject | — |
| 6.10 | Room Reservation → Conversion | Reserve → Allotted / Expired | BR-023/024 | hold lapse → auto-expire | — |

## Part B — FSM Catalog (states · transitions · guards · side-effects)

### FSM-1 Bed Allotment
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| (none) | Allot | bed free + student unallotted + gender ok + fee struct exists + bed not maintenance | Active | occupancy++ (BR-010/052); audit |
| Active | Room-change approve | new bed free | Transferred | old closed, new Active (BR-043); occupancy moves |
| Active | Vacate / bulk-vacate | typed confirm for bulk (BR-014) | Vacated | occupancy−−; irreversible; audit |
**Terminal:** Transferred, Vacated. **Illegal:** Active→Active on another bed (must transfer). ⚠ BR-001/002 uniqueness currently inert (DAT-HST-001).

### FSM-2 Leave Pass
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| Pending | Approve | end≥start (BR-004) | Approved | mark shifts+meals on-leave (BR-005/006); parent notified |
| Pending | Reject | reason | Rejected | — |
| Approved | Mark return (on time) | — | Returned | — |
| Approved | Mark return (late) | past expected | Returned-Late | auto late-arrival incident (BR-012) |
**Terminal:** Rejected, Returned, Returned-Late.

### FSM-3 Hostel Complaint
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| Open | Assign/Work | — | In-Progress | — |
| In-Progress | Resolve | resolution note present (BR-048) | Resolved | — |
| Open/In-Progress | SLA breach (48h) | auto | Escalated | chief warden notified (BR-020) |
**Terminal:** Resolved, Closed. ⚠ escalation central-scheduled (JOB-HST-001).

### FSM-4 Sick Bay
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| (none) | Admit | sick bay < capacity (BR-029) | Admitted | attendance→sick-bay (BR-016); parent notified (BR-049) |
| Admitted | Discharge | — | Discharged | parent notified (BR-049) |
**Terminal:** Discharged.

### FSM-5 Room Reservation
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| Pending | Confirm/convert | student exists + bed free (BR-024) | Converted | creates Active allotment |
| Pending | Hold lapse | past hold period | Expired | frees bed (BR-023) |
**Terminal:** Converted, Expired, Cancelled.

### FSM-6 Bed Maintenance / Availability
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| Available | Open ticket | — | Maintenance | bed unavailable for allotment (BR-027/050) |
| Maintenance | Close ticket | — | Available | bed allottable again |

### FSM-7 Discipline Incident
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| Logged | (moderate/serious) | severity | Logged+Notified | parent notified (BR-008); offender count++ |
| Logged | Resolve | — | Resolved | warning letter immutable if issued (BR-034); ≥3/yr → repeated-offender (BR-022) |

### FSM-8 Attendance Session
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| (none) | Open | unique hostel/date/shift (BR-007) | Open | attributed to on-duty warden (BR-041) |
| Open | Edit | chief warden ≤24h (BR-030) | Open | — |
| Open | 24h elapse | auto | Locked | immutable |
**Terminal:** Locked.
