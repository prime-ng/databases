# Prime-AI Platform — Development Estimation

**Date:** 2026-03-15
**Team:** 3 Experienced Laravel Developers + Claude AI (coding assistant)
**Baseline:** 762 pending sub-tasks across 27 modules (from Gap Analysis v1.0)
**Working days/month:** 22 days | **Hours/day:** 8 hrs

---

## Claude AI — Impact on Development Velocity

| Work Type | Traditional (1 dev) | With Claude (1 dev + Claude) | Acceleration |
|-----------|--------------------|-----------------------------|-------------|
| CRUD Controllers + Models + Migrations | 1 day | 0.3 days | **3.3x** |
| Blade Views (AdminLTE, forms, tables) | 1 day | 0.4 days | **2.5x** |
| Business Logic (complex services) | 1 day | 0.5 days | **2x** |
| Algorithm/Solver (ML, constraint engine) | 1 day | 0.7 days | **1.4x** |
| API Integration (Razorpay, SMS, Tally) | 1 day | 0.6 days | **1.7x** |
| Bug Fixing & Security Hardening | 1 day | 0.4 days | **2.5x** |
| Testing (Pest unit + feature) | 1 day | 0.3 days | **3.3x** |
| Code Review & Refactoring | 1 day | 0.4 days | **2.5x** |
| **Weighted Average** | **1 day** | **0.42 days** | **~2.4x** |

**What Claude CANNOT do (human-only time):**
- UI/UX design decisions, pixel-perfect styling — ~10% overhead
- Production deployment, server config, DNS — ~5% overhead
- Stakeholder meetings, requirement clarification — ~10% overhead
- Manual QA, cross-browser testing, mobile testing — ~10% overhead
- Integration testing with real data — ~5% overhead
- **Total human-only overhead: ~40% added to Claude-accelerated estimates**

**Effective multiplier:** 2.4x acceleration × 0.6 overhead = **~1.7x net effective speed per developer**
**3 devs + Claude ≈ 5.1 effective traditional developers**

---

## Module-by-Module Effort Estimation

### Tier 1 — Fix & Complete Existing Modules (Weeks 1–10)

| # | Module | Pending Tasks | Traditional (dev-days) | With Claude (dev-days) | Work Type Mix | Priority |
|---|--------|--------------|----------------------|----------------------|---------------|----------|
| G | SmartTimetable (60%→95%) | 26 | 69 | 40 | Algorithm-heavy | P0 |
| J | StudentFee (35%→90%) | 37 | 40 | 20 | CRUD + Business Logic | P0 |
| M | Library (30%→90%) | 26 | 30 | 14 | Wire routes + auth | P0 |
| I | Exam & Gradebook (25%→85%) | 34 | 50 | 25 | CRUD + Reports | P1 |
| S | LMS (30%→80%) | 37 | 50 | 25 | CRUD + Student-facing | P1 |
| H | Academics (40%→85%) | 32 | 35 | 18 | CRUD + Views | P1 |
| F | Attendance (20%→85%) | 27 | 30 | 15 | CRUD + Analytics | P1 |
| A | Tenant & System (75%→95%) | 13 | 12 | 6 | Config + Security | P2 |
| B | User & Security (55%→90%) | 23 | 20 | 10 | Auth + Security | P2 |
| V | SaaS Billing (50%→90%) | 27 | 30 | 16 | Integration + CRUD | P2 |
| Q | Communication (35%→85%) | 29 | 30 | 15 | Integration (SMS/Push) | P2 |
| D | Front Office (30%→70%) | 22 | 20 | 10 | CRUD + Views | P2 |
| N | Transport (90%→95%) | 4 | 5 | 3 | Reports + GPS | P3 |
| E | SIS (45%→85%) | 19 | 15 | 8 | CRUD + Reports | P2 |
| | **Tier 1 Subtotal** | **376** | **436** | **225** | | |

### Tier 2 — Build New Core Modules (Weeks 8–20)

| # | Module | Sub-Tasks | Traditional (dev-days) | With Claude (dev-days) | Work Type Mix | Priority |
|---|--------|----------|----------------------|----------------------|---------------|----------|
| C | Admissions (C1-C3, C5, C7) | 42 | 45 | 22 | CRUD + Workflow | P1 |
| P | HR & Payroll | 41 | 55 | 28 | CRUD + Payroll Logic | P1 |
| R | Certificates & ID Card | 52 | 45 | 22 | PDF Template + CRUD | P1 |
| K | Finance & Accounting | 70 | 100 | 52 | Business Logic heavy | P2 |
| Z | Parent Portal | 22 | 28 | 14 | Views + API | P2 |
| O | Hostel Management | 36 | 35 | 18 | CRUD + Fee Integration | P2 |
| | **Tier 2 Subtotal** | **263** | **308** | **156** | | |

### Tier 3 — Build Enhancement Modules (Weeks 18–28)

| # | Module | Sub-Tasks | Traditional (dev-days) | With Claude (dev-days) | Work Type Mix | Priority |
|---|--------|----------|----------------------|----------------------|---------------|----------|
| L | Inventory & Stock | 50 | 55 | 28 | CRUD + Workflow | P2 |
| W | Cafeteria & Mess | 12 | 15 | 8 | CRUD | P3 |
| X | Visitor & Security | 12 | 15 | 8 | CRUD + Integration | P3 |
| Y | Maintenance Helpdesk | 12 | 15 | 8 | CRUD + Workflow | P3 |
| SYS | System Administration | 12 | 18 | 10 | Infrastructure | P2 |
| | **Tier 3 Subtotal** | **98** | **118** | **62** | | |

### Tier 4 — AI & Advanced Modules (Weeks 26–36)

| # | Module | Sub-Tasks | Traditional (dev-days) | With Claude (dev-days) | Work Type Mix | Priority |
|---|--------|----------|----------------------|----------------------|---------------|----------|
| T | LXP (Learner Experience) | 47 | 70 | 40 | AI/ML + CRUD | P3 |
| U | Predictive Analytics & ML | 51 | 90 | 55 | Algorithm-heavy | P3 |
| | **Tier 4 Subtotal** | **98** | **160** | **95** | | |

---

## Consolidated Effort Summary

| Tier | Scope | Traditional | With Claude | Calendar (3 devs) |
|------|-------|------------|-------------|-------------------|
| Tier 1 | Fix & complete existing | 436 dev-days | 225 dev-days | **~17 weeks** |
| Tier 2 | Build new core modules | 308 dev-days | 156 dev-days | **~12 weeks** |
| Tier 3 | Enhancement modules | 118 dev-days | 62 dev-days | **~5 weeks** |
| Tier 4 | AI & advanced modules | 160 dev-days | 95 dev-days | **~7 weeks** |
| **Total Development** | | **1022 dev-days** | **538 dev-days** | |
| QA & Integration Testing | ~20% of dev | — | 108 dev-days | **~8 weeks** |
| **Grand Total** | | | **646 dev-days** | |

### Calendar Calculation

```
Total work    = 646 dev-days
Team capacity = 3 developers × 22 days/month = 66 dev-days/month
Duration      = 646 ÷ 66 = 9.8 months

Add buffers:
  Dependency wait time (modules block each other)  = +10%
  Requirement changes / scope creep                 = +15%
  Developer leave / unavailability                  = +5%
  Production bug fixes during development           = +5%
  Total buffer                                      = +35%

Buffered duration = 9.8 × 1.35 = ~13.2 months
```

---

## Final Timeline Estimate

| Scenario | Duration | Target Date |
|----------|----------|-------------|
| **Best case** (zero scope change, no blockers) | **10 months** | Jan 2027 |
| **Most likely** (normal scope creep + issues) | **13 months** | Apr 2027 |
| **Worst case** (major requirement changes) | **16 months** | Jul 2027 |

---

## Phased Timeline with Team Allocation

### Phase 1 — Stabilize & Secure (Weeks 1–4) — All 3 devs

| Dev | Assignment | Deliverables |
|-----|-----------|-------------|
| Dev 1 (Tarun) | SmartTimetable P01-P04 | Bug fixes + Security hardening |
| Dev 2 | StudentFee + LMS fixes | FeeConcession, seeder route, Gate auth, LMS dd() fix |
| Dev 3 | Library wiring + HPC auth | Wire Library to tenant.php, add Gate to all HPC/Library controllers |
| Claude | Parallel support for all 3 | Code generation, reviews, test writing |

**Week 4 checkpoint:** All critical security and crash bugs resolved. All modules have EnsureTenantHasModule.

### Phase 2 — Core Completion (Weeks 5–12) — Parallel tracks

| Dev | Assignment | Weeks | Deliverables |
|-----|-----------|-------|-------------|
| Dev 1 | SmartTimetable P05-P09 | 5-12 | Activity constraints, Performance, Room allocation, Constraint architecture |
| Dev 2 | Exam & Gradebook (I) | 5-10 | Marks entry, Gradebook engine, Report cards |
| Dev 2 | Attendance (F) | 11-12 | Period attendance, Analytics, Staff attendance |
| Dev 3 | Admissions (C1-C3) | 5-9 | Enquiry module, Application, Admission workflow |
| Dev 3 | StudentFee completion (J) | 10-12 | Reports, Scholarship workflow, Outstanding tracking |

**Week 12 checkpoint:** Timetable constraint foundation done. Exam marks entry working. Admission module live.

### Phase 3 — New Module Build (Weeks 13–22) — Parallel tracks

| Dev | Assignment | Weeks | Deliverables |
|-----|-----------|-------|-------------|
| Dev 1 | SmartTimetable P10-P17 | 13-22 | Teacher/Class/Inter-activity constraints, Analytics, Substitution, API |
| Dev 2 | HR & Payroll (P) | 13-18 | Leave workflow, Payroll engine, Compliance, Appraisal |
| Dev 2 | Certificates (R) | 19-22 | Template designer, Request workflow, ID cards |
| Dev 3 | Finance & Accounting (K) | 13-22 | COA, JE, AR/AP, Bank recon, GST, Reports |

**Week 22 checkpoint:** Timetable 95% complete. HR/Payroll live. Accounting foundation done.

### Phase 4 — Enhancement Modules (Weeks 23–30)

| Dev | Assignment | Weeks | Deliverables |
|-----|-----------|-------|-------------|
| Dev 1 | SmartTimetable P18-P21 + Testing | 23-26 | Room constraints, Testing, Code quality cleanup |
| Dev 1 | Parent Portal (Z) | 27-30 | Dashboard, Fee payment, Teacher messaging |
| Dev 2 | Inventory (L) | 23-27 | Item master, PO, GRN, Stock ledger |
| Dev 2 | Hostel (O) | 28-30 | Room setup, Allotment, Mess, Fee |
| Dev 3 | Accounting completion (K) | 23-26 | Budget, Asset register, Tally integration |
| Dev 3 | Communication (Q) completion | 27-28 | SMS gateway, Push notification, Emergency alerts |
| Dev 3 | Visitor (X) + Helpdesk (Y) + Cafeteria (W) | 29-30 | Smaller modules |

### Phase 5 — AI & Advanced (Weeks 31–40)

| Dev | Assignment | Weeks | Deliverables |
|-----|-----------|-------|-------------|
| Dev 1 | LXP (T) — Learning paths | 31-36 | Personalized paths, Skill graph, Gamification |
| Dev 2 | LXP (T) — Social + Mentorship | 31-36 | Forums, Peer mentoring, Activity feed |
| Dev 3 | Predictive Analytics (U) | 31-40 | Performance prediction, Attendance forecasting, Fee default, AI dashboards |
| All 3 | System Admin (SYS) + Final QA | 37-40 | Health monitoring, API mgmt, Integration testing |

---

## Parallel Execution Gantt (Simplified)

```
Week:  1    4    8    12   16   20   24   28   32   36   40
       |----|----|----|----|----|----|----|----|----|----|

Dev 1: [SmartTT Bugs+Sec][SmartTT Constraints    ][SmartTT Adv ][Parent Z][LXP         ][SYS]
Dev 2: [Fee+LMS Fix ][Exam+Gradebook][Attend][HR & Payroll ][Cert R ][Inventory L][Hostel][LXP   ]
Dev 3: [Library+HPC ][Admissions C  ][Fee J ][Finance & Accounting K      ][Q+X+Y+W    ][ML/AI U     ]

       |Phase 1     |Phase 2            |Phase 3            |Phase 4       |Phase 5     |
       |Stabilize   |Core Completion    |New Modules        |Enhancement   |AI/Advanced |
```

---

## Key Assumptions & Risks

### Assumptions
1. All 3 developers are full-time dedicated to Prime-AI (no other projects)
2. Claude AI is available for every coding session (no API outage impacts)
3. Laravel/PHP expertise — no learning curve for the tech stack
4. Database schema (v2 DDLs) is finalized — no major schema redesign needed
5. UI/UX wireframes provided by product team (devs don't design from scratch)
6. No mobile app development in scope (Parent Portal = responsive web only)

### Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Requirement changes during development | +2-4 months | Freeze requirements per phase; change requests go to next phase |
| Finance/Accounting module complexity underestimated | +1-2 months | Consider integrating with Tally/Zoho instead of building from scratch |
| ML/AI modules need data science expertise | +2-3 months | Use pre-built ML services (AWS SageMaker, OpenAI API) instead of custom models |
| Developer turnover (1 dev leaves) | +3-4 months | Document everything in AI Brain; Claude reduces dependency on individuals |
| Integration testing bottleneck at end | +1 month | Continuous integration — test each module as completed, not at the end |
| Multi-tenancy bugs discovered late | +1-2 months | Run tenant isolation tests after every module completion |

### Cost-Saving Alternatives

| Module | Build Time | Alternative | Savings |
|--------|-----------|-------------|---------|
| K — Accounting | 52 dev-days | Integrate Tally/Zoho via API | ~35 dev-days saved |
| U — Predictive Analytics | 55 dev-days | Use OpenAI API + simple dashboards | ~30 dev-days saved |
| W — Cafeteria | 8 dev-days | Defer to v2.0 | 8 dev-days saved |
| X — Visitor Mgmt | 8 dev-days | Defer to v2.0 | 8 dev-days saved |
| Y — Helpdesk | 8 dev-days | Defer to v2.0 | 8 dev-days saved |
| **If deferred** | | | **~89 dev-days = ~1.5 months faster** |

**With deferrals:** Most likely timeline drops from **13 months → 11.5 months** (Feb 2027).

---

## Milestone Checkpoints

| Milestone | Week | What's Deliverable | Platform % |
|-----------|------|-------------------|-----------|
| M1 — Stable & Secure | 4 | All bugs fixed, auth on all routes, Library wired | 40% |
| M2 — Core Academic Ready | 12 | Timetable constraints, Exam marks, Admissions, Fees | 55% |
| M3 — School Deployable | 22 | + HR/Payroll, Certificates, Accounting foundation | 72% |
| M4 — Full Operations | 30 | + Inventory, Hostel, Parent Portal, Communication | 85% |
| M5 — AI-Powered Platform | 40 | + LXP, Predictive Analytics, System Admin | 95% |
| M6 — Production Release | 42 | Final QA, Performance tuning, Documentation | 98% |

---

## Per-Module Delivery Schedule

| Module | Start Week | End Week | Duration | Dev Assigned |
|--------|-----------|---------|----------|-------------|
| SmartTimetable (complete) | 1 | 26 | 26 weeks | Dev 1 |
| StudentFee (complete) | 1 | 12 | 12 weeks | Dev 2 → Dev 3 |
| Library (wire + fix) | 1 | 4 | 4 weeks | Dev 3 |
| LMS modules (fix) | 1 | 4 | 4 weeks | Dev 2 |
| HPC (auth fix) | 1 | 4 | 4 weeks | Dev 3 |
| Exam & Gradebook | 5 | 10 | 6 weeks | Dev 2 |
| Attendance | 11 | 12 | 2 weeks | Dev 2 |
| Admissions | 5 | 9 | 5 weeks | Dev 3 |
| HR & Payroll | 13 | 18 | 6 weeks | Dev 2 |
| Certificates & ID | 19 | 22 | 4 weeks | Dev 2 |
| Finance & Accounting | 13 | 26 | 14 weeks | Dev 3 |
| Parent Portal | 27 | 30 | 4 weeks | Dev 1 |
| Inventory | 23 | 27 | 5 weeks | Dev 2 |
| Hostel | 28 | 30 | 3 weeks | Dev 2 |
| Communication (complete) | 27 | 28 | 2 weeks | Dev 3 |
| Visitor + Helpdesk + Cafeteria | 29 | 30 | 2 weeks | Dev 3 |
| LXP | 31 | 36 | 6 weeks | Dev 1 + Dev 2 |
| Predictive Analytics & ML | 31 | 40 | 10 weeks | Dev 3 |
| System Admin | 37 | 40 | 4 weeks | Dev 1 |
| Tenant/User/Billing (polish) | 37 | 40 | 4 weeks | Dev 2 |
| Final QA & Release | 41 | 42 | 2 weeks | All 3 |
