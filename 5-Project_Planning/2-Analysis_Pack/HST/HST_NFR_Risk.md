# Hostel (HST) — NFR Catalog + Risk Register
Source: `HST_FRD_2026-06-29.md` §9 + Mode A audit | Date: 2026-06-29

## Part A — Non-Functional Requirements
| NFR-ID | Category | Requirement (measurable) | Threshold |
|--------|----------|--------------------------|-----------|
| NFR-HST-001 | Performance | Dashboard occupancy/attendance via pre-computed counts (BR-052) — no per-request aggregation | < 1 s for a 500+-bed hostel |
| NFR-HST-002 | Scalability | Allotment, roll-call, mess attendance scale to 500+ students/hostel, multi-hostel | roll-call save < 2 s for 500 rows |
| NFR-HST-003 | Concurrency | Bed allotment and occupancy counters are race-safe (row lock / UNIQUE / generated column) | 0 double-allotments under concurrent allot |
| NFR-HST-004 | Security | Health (sick bay, special diet) and discipline records restricted to warden/medical roles | enforced at query layer |
| NFR-HST-005 | Data isolation | One school's hostel data never visible to another | per-tenant DB |
| NFR-HST-006 | Compliance/Safety | Child-safety: every gate movement and visitor logged; absence/overdue alerts to parents (POCSO-aligned) | alert within threshold (30 min movement, roll-call same session) |
| NFR-HST-007 | Auditability | All changes auto-logged, immutable warning letters, irreversible bulk-vacate audited | 100% of state changes logged |
| NFR-HST-008 | Availability | Roll-call and gate-movement usable during hostel hours on warden mobile | responsive layout |
| NFR-HST-009 | Reliability | Parent notifications and fee-demand pushes are delivered, with retry, not silently dropped | delivery confirmed/queued, never fire-and-forget |

## Part B — Risk Register
| RISK-ID | Risk | Cat | Likelihood | Impact | Mitigation | Trigger / Early-warning |
|---------|------|-----|-----------|--------|------------|------------------------|
| RISK-HST-001 | Two students allotted the same bed (uniqueness columns inert — DAT-HST-001) | Data integrity | High | High | Restore generated UNIQUE columns + row lock; test BR-001/002 concurrency | duplicate active allotments in report |
| RISK-HST-002 | Monthly mess bill insert fails / wrong total (MIG-HST-001 total_amount plain) | Financial | High | High | Make total_amount a generated column or compute in locked service (BR-025) | MessBill::create errors / zero bills |
| RISK-HST-003 | Parent safety alerts never delivered (notification stub — BUG-HST-006) | Safety/Compliance | High | High | Implement notification job + listeners; delivery log (BR-008/017/031/049) | parents report no alerts |
| RISK-HST-004 | Hostel fee demands never reach StudentFee (BUG-HST-007 returns null) | Financial | High | Med | Implement forwardToStudentFee; reconcile demands (BR-011/032) | demands raised but no fee record |
| RISK-HST-005 | Complaint SLA escalation never fires per tenant (JOB-HST-001 central) | Operational | Med | Med | Wrap command in tenants:run (BR-020) | breached complaints not escalated |
| RISK-HST-006 | Occupancy counter drift under concurrent allot/vacate (DAT-HST-002 no lock) | Data integrity | Med | Med | Atomic increment/lock (BR-010/052) | dashboard count ≠ actual |
| RISK-HST-007 | Zero tests — regressions on the safety/finance core | Quality | High | High | Critical-path test suite (Testing Architect) | defects reach production |
| RISK-HST-008 | Prerequisite modules (StudentFee, NTF, HPC) incomplete | Dependency | Med | Med | Sequence per dependency map; feature-flag integrations | integration endpoints unavailable |
| RISK-HST-009 | Health/discipline PII over-exposed if role scoping incomplete (BR-013/053) | Privacy | Low | High | Enforce warden/medical scoping at query layer (NFR-004) | non-medical role sees sick-bay data |
