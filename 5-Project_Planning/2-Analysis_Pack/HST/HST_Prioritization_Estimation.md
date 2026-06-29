# Hostel (HST) — Prioritization + Effort Estimation + Sprint Tasks
Source: FRD priorities + Mode A audit | Date: 2026-06-29 | Estimates assume DDL/code ~exist (remediation-weighted).

## Part A — MoSCoW
- **Must (P0, 13):** REQ-HST-001,002,003,004,005,006,008,011,013,018,019,020,027 — the residential + safety + fee core.
- **Should (P1, 13):** REQ-HST-009,010,012,014,015,016,017,021,022,023,024,028,029.
- **Could (P2, 3):** REQ-HST-007 (duty roster), REQ-HST-025 (laundry), REQ-HST-026 (emergency contacts).
- **Won't (this release):** GPS-style live tracking, predictive occupancy (not in FRD scope).

## Part B — RICE (top remediation candidates)
| Item | Reach | Impact | Confidence | Effort(d) | RICE | Rank |
|------|------:|-------:|-----------:|----------:|-----:|------|
| Fix bed-allotment uniqueness + lock (RISK-001) | All hostels | 3 | 0.9 | 3 | high | 1 |
| Fix mess-bill generated total (RISK-002) | All boarders | 3 | 0.9 | 2 | high | 2 |
| Wire parent notifications (RISK-003) | All parents | 3 | 0.8 | 5 | high | 3 |
| Wire fee-demand push (RISK-004) | Accounts | 2 | 0.8 | 3 | med | 4 |
| Per-tenant complaint escalation (RISK-005) | Wardens | 2 | 0.8 | 1 | med | 5 |

## Part C — Sprint Task Breakdown
*Type: Schema / Backend / Frontend / Integration / Testing. Sequenced so fixes unblock features.*

### Sprint 1 — Data-integrity & finance core (unblock the P0 defects)
| # | Task | Type | Eff(h) | Depends on | BR/REQ |
|---|------|------|-------:|-----------|--------|
| 1 | Restore generated UNIQUE cols `gen_active_bed_id`/`gen_active_student_id` in migration + row lock on allot | Schema+Backend | 10 | — | BR-001/002, REQ-008 |
| 2 | Make `hst_mess_bills.total_amount` generated (or locked-service compute); add to fillable handling | Schema+Backend | 8 | — | BR-025, REQ-017 |
| 3 | Atomic occupancy counter (increment/lock) | Backend | 6 | 1 | BR-010/052, REQ-003/027 |
| 4 | Tests: concurrent allotment, occupancy drift, mess-bill compute | Testing | 8 | 1-3 | RISK-001/002/006 |

### Sprint 2 — Cross-module wiring (notifications, fees, escalation)
| # | Task | Type | Eff(h) | Depends on | BR/REQ |
|---|------|------|-------:|-----------|--------|
| 5 | Implement parent-notification job + listeners (absence/incident/movement/sick-bay) + delivery log | Integration | 16 | NTF | BR-008/017/031/049 |
| 6 | Implement `forwardToStudentFee()` demand push + reconcile | Integration | 10 | FIN | BR-011/032, REQ-019 |
| 7 | Wrap `hst:escalate-complaints` in `tenants:run` scheduler | Backend | 3 | — | BR-020, REQ-021 |
| 8 | Tests: notification dispatch, fee-demand push, complaint SLA | Testing | 8 | 5-7 | RISK-003/004/005 |

### Sprint 3 — Workflow completeness & hardening
| # | Task | Type | Eff(h) | Depends on | BR/REQ |
|---|------|------|-------:|-----------|--------|
| 9 | Reservation auto-expiry job + conversion guard | Backend | 6 | — | BR-023/024, REQ-009 |
| 10 | Special-diet auto-expiry; meal opt-out cut-off enforcement | Backend | 5 | — | BR-045/026, REQ-015/017 |
| 11 | Fee-structure-exists hard block before allot (currently soft log) | Backend | 3 | 1 | BR-015, REQ-008/018 |
| 12 | Role-scoping at query layer for health/discipline/reports | Backend | 8 | — | BR-013/053, NFR-004 |
| 13 | Tests: leave auto-mark, reservation expiry, role scoping | Testing | 8 | 9-12 | — |

### Sprint 4 — P1/P2 features & reports
| # | Task | Type | Eff(h) | Depends on | BR/REQ |
|---|------|------|-------:|-----------|--------|
| 14 | Reporting suite scoping + 14 reports export | Frontend+Backend | 16 | 12 | REQ-028, RPT-001..014 |
| 15 | Duty roster, laundry recovery, emergency contacts (P2) | Full | 12 | — | REQ-007/025/026 |
| 16 | Dashboard widgets (attendance-threshold, overdue, pending reservations) | Frontend | 8 | 3 | REQ-027 |

**Rough total:** ~152 h (~4 sprints, 1 dev). Assumes the 25 hst tables exist (they do); +N if the generated-column migrations need a data backfill on existing tenants.
