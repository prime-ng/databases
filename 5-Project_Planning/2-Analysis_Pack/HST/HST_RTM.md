# Hostel (HST) — Requirements Traceability Matrix (RTM)
**Spine of the analysis pack** | Source: `HST_FRD_2026-06-29.md` | Date: 2026-06-29

Each requirement traced to its business rules, workflow, report, test need, and current code status.
Code-status references the Mode A audit (`Hostel_Technical_Audit_2026-06-29.md`).

| REQ | Feature | Pri | Business Rules | Workflow | Report(s) | Test | Code Status (audit) |
|-----|---------|-----|----------------|----------|-----------|------|---------------------|
| REQ-HST-001 | Hostel/Building Config | P0 | BR-009, BR-033 | — | — | Yes | Built |
| REQ-HST-002 | Floor Management | P0 | BR-035, BR-036 | — | — | Yes | Built |
| REQ-HST-003 | Room Setup | P0 | BR-010, BR-037 | — | RPT-001 | Yes | 🟡 BR-010 occupancy at risk (DAT-HST-002 no lock) |
| REQ-HST-004 | Bed Management | P0 | BR-027, BR-038 | — | — | Yes | Built |
| REQ-HST-005 | Config Masters | P0 | BR-039, BR-040 | — | — | Yes | Built |
| REQ-HST-006 | Warden Assignment & Scoped Access | P0 | BR-013, BR-033 | — | — | Yes | Built |
| REQ-HST-007 | Warden Duty Roster | P2 | BR-041 | — | RPT-014 | Yes | Built |
| REQ-HST-008 | Student Bed Allotment | P0 | BR-001, BR-002, BR-003, BR-014, BR-015 | 6.1 | RPT-001 | Yes | 🔴 **BR-001/002 BROKEN** (DAT-HST-001 inert generated UNIQUE → double-allotment) |
| REQ-HST-009 | Room Reservation | P1 | BR-023, BR-024 | 6.10 | RPT-014 | Yes | 🟡 expiry job (BR-023) depends on scheduler |
| REQ-HST-010 | Room Change Request | P1 | BR-042, BR-043 | 6.2 | — | Yes | Built |
| REQ-HST-011 | Daily Roll-Call Attendance | P0 | BR-007, BR-017, BR-018, BR-030 | 6.4 | RPT-002 | Yes | 🟡 BR-017 parent alert via BUG-HST-006 stub |
| REQ-HST-012 | In-Out Movement Register | P1 | BR-031 | 6.5 | RPT-004 | Yes | 🟡 BR-031 overdue alert via notification stub |
| REQ-HST-013 | Leave Pass Management | P0 | BR-004, BR-005, BR-006, BR-012, BR-019 | 6.3 | RPT-003 | Yes | Built; BR-012 auto-incident present |
| REQ-HST-014 | Weekly Mess Menu | P1 | BR-044 | — | — | Yes | Built |
| REQ-HST-015 | Special Diet Assignment | P1 | BR-045 | — | — | Yes | Built |
| REQ-HST-016 | Mess Attendance | P1 | BR-006, BR-046 | — | RPT-007 | Yes | Built |
| REQ-HST-017 | Mess Opt-Out & Monthly Billing | P1 | BR-025, BR-026 | 6.9 | RPT-007 | Yes | 🔴 **BR-025 BROKEN** (MIG-HST-001 total_amount plain→insert fails) |
| REQ-HST-018 | Fee Structure Config | P0 | BR-047 | — | — | Yes | 🟡 BR-015 check is soft log (VAL-HST-002) |
| REQ-HST-019 | Fee Assignment, Proration & Demand Push | P0 | BR-011, BR-032 | — | RPT-005 | Yes | 🔴 demand push stub (BUG-HST-007 returns null) |
| REQ-HST-020 | Discipline Incident & Warning Letters | P0 | BR-008, BR-022, BR-034 | 6.6 | RPT-006 | Yes | 🟡 BR-008 parent alert via BUG-HST-006 stub |
| REQ-HST-021 | Hostel Complaint Register | P1 | BR-020, BR-048 | 6.7 | — | Yes | 🟡 BR-020 SLA escalation central-scheduled (JOB-HST-001) |
| REQ-HST-022 | Visitor Register | P1 | BR-021 | — | RPT-011, RPT-012 | Yes | Built |
| REQ-HST-023 | Sick Bay Management | P1 | BR-016, BR-029, BR-049 | 6.8 | RPT-013 | Yes | 🟡 BR-049 alerts via notification stub |
| REQ-HST-024 | Room Inventory, Bed Maintenance & Housekeeping | P1 | BR-032, BR-050 | — | RPT-008, RPT-009 | Yes | Built |
| REQ-HST-025 | Laundry Tracking | P2 | BR-028 | — | RPT-010 | Yes | Built |
| REQ-HST-026 | Emergency Contacts | P2 | BR-051 | — | — | Yes | Built |
| REQ-HST-027 | Hostel Dashboard | P0 | BR-013, BR-018, BR-052 | — | — | Yes | 🟡 BR-052 pre-computed counts depend on generated cols (DAT-HST-001) |
| REQ-HST-028 | Reporting Suite | P1 | BR-013, BR-053 | — | RPT-001..014 | Yes | Built (scoping per BR-053) |
| REQ-HST-029 | Audit Trail & Notification Log | P1 | BR-054 | — | — | Yes | Built |

### Coverage roll-up (reconciles to FRD §10.4)
- **29 REQ** (13 P0 · 13 P1 · 3 P2) — every REQ has ≥1 BR or is a pure CRUD/report feature.
- **54 BR** — all mapped to a REQ (see Rules register).
- **10 workflows** (6.1–6.10) cover the multi-step requirements; **14 reports** (RPT-001..014).
- **5 REQ carry confirmed code defects** from the audit (REQ-008, 017, 019 = 🔴; 011, 020, 021, 027 = 🟡) — these are the priority fixes.

### Test gap
The module has **0 module-level/Dusk tests** (per audit). Every "Test = Yes" row above is an open test-coverage gap → see Sprint Tasks (Testing lane) and hand to Testing Architect.
