# RBS Coverage Report — Prime-AI Platform
**Date:** 2026-03-26
**RBS Version:** v4.0 (source: `PrimeAI_Complete_Spec_v2.md`)
**V2 Requirements Version:** 2.0
**Purpose:** Assess how well the existing RBS (Requirements Breakdown Structure) specification covers each of the 46 Prime-AI modules, identify gaps where V2 requirements were extrapolated, and recommend updates for RBS v5.0.

---

## 1. Coverage Rating Scale

| Rating | Meaning | V2 Action Taken |
|--------|---------|----------------|
| HIGH | RBS has detailed feature lists, sub-features, and data points | V2 refined and structured; minimal extrapolation |
| MEDIUM-HIGH | RBS has solid feature list; some gaps in edge cases / business rules | V2 added business rules, error flows, and API detail |
| MEDIUM | RBS covers main features; sub-features and workflows are thin | V2 extrapolated ~30–40% from industry/code patterns |
| LOW-MEDIUM | RBS has headings only or very brief notes | V2 extrapolated ~50–60% from code, V1 docs, patterns |
| LOW | RBS barely mentions module or covers only 1–2 features | V2 mostly built from scratch based on code and Indian school ERP norms |
| NONE | Module absent from RBS | V2 fully extrapolated |

---

## 2. Coverage Summary Table

| # | Code | Full Name | Batch | Mode | RBS Coverage | V2 Status |
|---|------|-----------|-------|------|-------------|-----------|
| 1 | PRM | Prime App | 1 | FULL | HIGH | ✅ Done |
| 2 | BIL | Billing | 1 | FULL | HIGH | ✅ Done |
| 3 | GLB | Global Master | 1 | FULL | HIGH | ✅ Done |
| 4 | SYS | System Config | 1 | FULL | HIGH | ✅ Done |
| 5 | SCH_JOB | Scheduler/Jobs | 1 | FULL | MEDIUM-HIGH | ✅ Done |
| 6 | SCH | School Setup | 2 | FULL | HIGH | ⏳ Pending |
| 7 | TTF | Timetable Foundation | 2 | FULL | HIGH | ⏳ Pending |
| 8 | STT | Smart Timetable | 2 | FULL | MEDIUM-HIGH | ⏳ Pending |
| 9 | TTS | Standard Timetable | 2 | FULL | MEDIUM-HIGH | ⏳ Pending |
| 10 | DSH | Dashboard | 2 | FULL | MEDIUM | ⏳ Pending |
| 11 | STD | Student Profile | 3 | FULL | HIGH | ⏳ Pending |
| 12 | STP | Student Portal | 3 | FULL | MEDIUM | ⏳ Pending |
| 13 | SLB | Syllabus | 3 | FULL | HIGH | ⏳ Pending |
| 14 | SLK | Syllabus Books | 3 | FULL | MEDIUM | ⏳ Pending |
| 15 | DOC | Documentation | 3 | FULL | LOW-MEDIUM | ⏳ Pending |
| 16 | HMW | LMS Homework | 4 | FULL | HIGH | ⏳ Pending |
| 17 | QUZ | LMS Quiz | 4 | FULL | HIGH | ⏳ Pending |
| 18 | QST | LMS Quests | 4 | FULL | MEDIUM | ⏳ Pending |
| 19 | EXM | LMS Exam | 4 | FULL | HIGH | ⏳ Pending |
| 20 | QNS | Question Bank | 4 | FULL | HIGH | ⏳ Pending |
| 21 | FIN | Student Fee | 5 | FULL | HIGH | ⏳ Pending |
| 22 | PAY | Payment | 5 | FULL | MEDIUM-HIGH | ⏳ Pending |
| 23 | NTF | Notification | 5 | FULL | MEDIUM-HIGH | ⏳ Pending |
| 24 | CMP | Complaint | 5 | FULL | MEDIUM | ⏳ Pending |
| 25 | REC | Recommendation | 5 | FULL | LOW-MEDIUM | ⏳ Pending |
| 26 | TPT | Transport | 6 | FULL | HIGH | ⏳ Pending |
| 27 | LIB | Library | 6 | FULL | HIGH | ⏳ Pending |
| 28 | VND | Vendor | 6 | FULL | MEDIUM-HIGH | ⏳ Pending |
| 29 | HPC | HPC | 6 | FULL | MEDIUM | ⏳ Pending |
| 30 | ADM | Admission | 7 | RBS_ONLY | MEDIUM | ⏳ Pending |
| 31 | ATT | Attendance | 7 | RBS_ONLY | MEDIUM | ⏳ Pending |
| 32 | ACD | Academics | 7 | RBS_ONLY | MEDIUM | ⏳ Pending |
| 33 | EXA | Examination | 7 | RBS_ONLY | MEDIUM | ⏳ Pending |
| 34 | FOF | Front Office | 7 | RBS_ONLY | LOW-MEDIUM | ⏳ Pending |
| 35 | HRS | HR & Staff | 8 | RBS_ONLY | MEDIUM-HIGH | ✅ Done |
| 36 | FAC | Finance Accounting | 8 | RBS_ONLY | MEDIUM-HIGH | ✅ Done |
| 37 | INV | Inventory | 8 | RBS_ONLY | MEDIUM-HIGH | ✅ Done |
| 38 | HST | Hostel | 8 | RBS_ONLY | MEDIUM-HIGH | ✅ Done |
| 39 | COM | Communication | 8 | RBS_ONLY | MEDIUM-HIGH | ✅ Done |
| 40 | LXP | Learning Experience | 9 | RBS_ONLY | LOW-MEDIUM | ✅ Done |
| 41 | PAN | Predictive Analytics | 9 | RBS_ONLY | LOW | ✅ Done |
| 42 | CRT | Certificate | 9 | RBS_ONLY | LOW-MEDIUM | ✅ Done |
| 43 | PPT | Parent Portal | 9 | RBS_ONLY | MEDIUM | ✅ Done |
| 44 | CAF | Cafeteria | 9 | RBS_ONLY | LOW-MEDIUM | ✅ Done |
| 45 | VSM | Visitor Security | 10 | RBS_ONLY | LOW | ✅ Done |
| 46 | MNT | Maintenance | 10 | RBS_ONLY | LOW | ✅ Done |

---

## 3. Per-Module Coverage Assessment

### Batch 1 — Central Platform (FULL mode)

| Code | RBS Coverage | What RBS Covered Well | What V2 Added |
|------|-------------|----------------------|---------------|
| PRM | HIGH | Tenant mgmt, plan tiers, module licensing, white-label config | Multi-currency billing rules, tenant isolation edge cases, plan upgrade/downgrade logic |
| BIL | HIGH | SaaS invoice types, gateway integration, dunning flows | Usage metering per module, proration logic, GST rules for SaaS, failed payment retry matrix |
| GLB | HIGH | Country/state/board/language master tables | Translation management via `glb_translations`, currency precision rules, board-specific curriculum codes |
| SYS | HIGH | RBAC roles/permissions, system settings, dropdowns | Polymorphic media handling, activity log query patterns, generated column UNIQUE constraints |
| SCH_JOB | MEDIUM-HIGH | Cron job definitions, queue workers | Job failure alerting, retry strategies, dead-letter handling, distributed lock mechanism |

### Batch 2 — School Setup + Timetable (FULL mode, Pending)

| Code | RBS Coverage | What RBS Covered Well | Gaps to Address in V2 |
|------|-------------|----------------------|----------------------|
| SCH | HIGH | School profile, academic year setup, class-section creation, subject master | Branch/campus hierarchy, infra setup (rooms, labs), period config linkage to TTF |
| TTF | HIGH | Period slots, day config, teacher-subject mapping, constraint types | ConstraintCategory/Scope/TargetType taxonomy (v7.6 schema), `tt_` prefix tables in full detail |
| STT | MEDIUM-HIGH | Auto-generation concept, FETSolver mention | Backtracking+greedy algorithm detail, Tabu search / SA optimizer stages, analytics/substitution sub-modules — V2 needs to reflect 10-stage implementation reality |
| TTS | MEDIUM-HIGH | Manual timetable creation, class/teacher views | Standard views reusing AnalyticsService, relationship to STT published timetable |
| DSH | MEDIUM | Role-based widgets concept, KPI tiles | Widget registry pattern, lazy-computation, per-role dashboard config, drill-down API design |

### Batch 3 — Student & Syllabus (FULL mode, Pending)

| Code | RBS Coverage | What RBS Covered Well | Gaps to Address in V2 |
|------|-------------|----------------------|----------------------|
| STD | HIGH | Student registration, family details, documents, health records | Guardian portal linkage, multi-school transfer workflow, biometric ID linkage |
| STP | MEDIUM | Self-service portal concept, grade/fee view | Notification center, LMS activity feed, assignment submission interface |
| SLB | HIGH | Curriculum mapping, lesson plan, topic hierarchy | Coverage tracking %, chapter progress vs timetable alignment |
| SLK | MEDIUM | Book list assignment to class/subject | Publisher catalog management, ISBN tracking, edition handling |
| DOC | LOW-MEDIUM | Document templates mentioned | Template designer (variable placeholders), bulk generation queuing, digital signature integration |

### Batch 4 — LMS Assessment Suite (FULL mode, Pending)

| Code | RBS Coverage | What RBS Covered Well | Gaps to Address in V2 |
|------|-------------|----------------------|----------------------|
| HMW | HIGH | Homework assignment, submission, grading flow | Rubric-based grading, peer review, late submission policies, parent visibility rules |
| QUZ | HIGH | Quiz creation, question types, auto-grading | Adaptive question ordering, partial marks, timer controls, re-attempt policy |
| QST | MEDIUM | Gamified quests concept, badges | Quest chains, XP system, leaderboard scoping (class/school), badge taxonomy |
| EXM | HIGH | Online exam, proctoring, answer sheet | Randomized paper generation from QNS, section-wise time limits, AI proctoring hooks |
| QNS | HIGH | Question repository, difficulty levels, tagging | Bloom's taxonomy tags, media-rich questions (images/audio), version history for edited questions |

### Batch 5 — Finance + Notifications (FULL mode, Pending)

| Code | RBS Coverage | What RBS Covered Well | Gaps to Address in V2 |
|------|-------------|----------------------|----------------------|
| FIN | HIGH | Fee heads, concessions, challan, receipt | Sibling discounts, scholarship rules, hostel/transport sub-ledger linkage, partial payment handling |
| PAY | MEDIUM-HIGH | Gateway integration, UPI/netbanking | Razorpay/PayU webhook mapping, refund flow, reconciliation mismatch handling |
| NTF | MEDIUM-HIGH | Channel types (SMS/email/push), templates | Template variable substitution engine, delivery status tracking, NTF retry on COM failure |
| CMP | MEDIUM | Complaint intake, escalation | SLA timer implementation, category-wise routing rules, resolution satisfaction scoring |
| REC | LOW-MEDIUM | AI recommendations concept | Recommendation engine algorithm (collaborative filtering vs content-based), feedback loop design |

### Batch 6 — Operations (FULL mode, Pending)

| Code | RBS Coverage | What RBS Covered Well | Gaps to Address in V2 |
|------|-------------|----------------------|----------------------|
| TPT | HIGH | Routes, stops, vehicles, driver mgmt | GPS tracking API integration, RFID/QR boarding, real-time parent tracking |
| LIB | HIGH | OPAC, issue/return, fines, e-resources | Digital library (ebook/PDF reader), barcode/RFID integration, inter-library loan |
| VND | MEDIUM-HIGH | Vendor master, PO, delivery confirmation | Contract expiry alerts, vendor performance scoring, three-way matching (PO+GRN+Invoice) |
| HPC | MEDIUM | Lab usage tracking concept | DomPDF report generation (done in code), GPU/CPU utilization metrics, job queue for HPC tasks |

### Batch 7 — Core School Ops (RBS_ONLY, Pending)

| Code | RBS Coverage | What RBS Covered Well | What V2 Will Need to Extrapolate |
|------|-------------|----------------------|----------------------------------|
| ADM | MEDIUM | Enquiry → application → selection funnel | Online application portal, entrance exam scheduling, merit list generation, sibling priority rules |
| ATT | MEDIUM | Student/staff daily attendance, leave types | Biometric device integration, period-wise attendance, proxy detection, leave encashment rules |
| ACD | MEDIUM | Grade setup, marksheet, progress report | CCE/CBSE/ICSE-specific grading norms, co-scholastic assessment, term-wise vs cumulative grading |
| EXA | MEDIUM | Exam schedule, hall ticket, marks entry | Question paper security workflow, answer script scanning, moderation/scaling rules |
| FOF | LOW-MEDIUM | Reception desk, visitor log, ID cards | Call log system, courier/parcel tracking, gate pass QR generation, inter-department routing |

### Batch 8 — Backend Services (RBS_ONLY, Done)

| Code | RBS Coverage | What RBS Covered Well | What V2 Added |
|------|-------------|----------------------|---------------|
| HRS | MEDIUM-HIGH | Staff master, contracts, appraisal, payroll inputs | Payroll calculation engine detail, PF/ESI/TDS rules, appraisal scoring matrix, leave encashment |
| FAC | MEDIUM-HIGH | Chart of accounts, voucher types, trial balance | D21 integration event bus design, GST filing structure, budget vs actual tracking, bank reconciliation |
| INV | MEDIUM-HIGH | Stock mgmt, GRN, issues, PO | ABC analysis, FIFO/LIFO/weighted-average costing, barcode scanning, threshold auto-reorder |
| HST | MEDIUM-HIGH | Room allocation, wardens, mess plans | Hostel fee sub-ledger, visitor register, disciplinary log, fire drill records |
| COM | MEDIUM-HIGH | Channel config, announcements, circulars | Real-time chat (WebSocket), message threading, group broadcast limits, retention policies |

### Batch 9 — Emerging + Portals (RBS_ONLY, Done)

| Code | RBS Coverage | What V2 Required Extrapolation On |
|------|-------------|----------------------------------|
| LXP | LOW-MEDIUM | Adaptive learning path algorithm, skill taxonomy mapping, content curation workflow, SCORM/xAPI support were all extrapolated from industry standards |
| PAN | LOW | Dropout prediction ML model inputs, intervention workflow design, risk score calculation method, alert threshold configuration — largely extrapolated from EdTech analytics patterns |
| CRT | LOW-MEDIUM | Certificate template designer (SVG/HTML), digital signature chain, verification QR code, bulk generation queue — partially extrapolated |
| PPT | MEDIUM | Parent app screens were well-described; fee payment action flow, two-way messaging, teacher appointment booking were extrapolated |
| CAF | LOW-MEDIUM | Menu mgmt and meal plan basics covered; dietary restriction tracking, RFID meal token, nutritional analysis, FSSAI compliance — extrapolated |

### Batch 10 — Facility Ops (RBS_ONLY, Done)

| Code | RBS Coverage | What V2 Required Extrapolation On |
|------|-------------|----------------------------------|
| VSM | LOW | Visitor entry/exit log was mentioned; ID verification (Aadhaar/govt ID scan), gate pass QR workflow, blacklist management, security incident log — largely extrapolated from security system norms |
| MNT | LOW | Maintenance request concept present; AMC contract tracking, work order lifecycle, PPM scheduling, asset condition tracking, contractor performance scoring — largely extrapolated |

---

## 4. Modules with Highest Extrapolation Risk

These modules had LOW RBS coverage and V2 content was mostly built from industry patterns and code inspection. They carry the highest risk of requirement drift and should be prioritized for stakeholder review.

| # | Code | Extrapolation % | Key Uncertain Areas |
|---|------|----------------|---------------------|
| 1 | PAN | ~65% | ML model selection, data pipeline, prediction refresh frequency |
| 2 | LXP | ~55% | xAPI compliance, content format support, adaptive algorithm |
| 3 | MNT | ~60% | AMC workflow, PPM schedule logic, contractor billing |
| 4 | VSM | ~60% | Aadhaar integration, blacklist data source, gate hardware API |
| 5 | CRT | ~45% | Digital signature provider, QR verification backend |
| 6 | CAF | ~45% | RFID meal token hardware, FSSAI compliance specifics |
| 7 | DOC | ~50% | Template engine choice, e-signature provider |
| 8 | REC | ~50% | Recommendation algorithm selection, feedback loop design |
| 9 | FOF | ~45% | Front office workflow, courier system integration |
| 10 | QST | ~40% | Gamification rules, XP balance, badge economy design |

---

## 5. RBS v4.0 Gaps Summary

### 5.1 Missing Modules in RBS v4.0
The following modules had no meaningful RBS entry and were written entirely from first principles:

- **SCH_JOB** — Scheduler/Jobs was not a named module in RBS v4.0; it was implicit in infrastructure
- **DSH** — Dashboard was mentioned as a concept but had no feature breakdown
- **STP** — Student Portal was a sub-section of STD, not a standalone module
- **PAN** — Predictive Analytics had 2–3 bullet points only
- **HPC** — HPC was a single-paragraph mention

### 5.2 Underspecified Business Rules in RBS v4.0
Areas where RBS listed the feature but omitted business rules that V2 had to define:

| Area | Affected Modules | Rule Gap |
|------|-----------------|----------|
| Indian tax compliance | FAC, FIN, PAY, VND | GST, TDS, PF, ESI calculation rules |
| CBSE/ICSE grading norms | ACD, EXA, CRT | Grade point scales, co-scholastic grades |
| Fee concession hierarchy | FIN | Sibling, merit, staff-ward discount priority order |
| Biometric integration | ATT, VSM, FOF | Device API contract, fallback on device failure |
| Multi-branch school | SCH, STD, HRS | Whether branches share a DB or get separate tenant DBs |
| Academic calendar edge cases | SCH, ATT, EXA | Mid-year term changes, rescheduled exams |

### 5.3 Schema vs RBS Misalignments Found
During V2 writing, the following RBS-to-schema misalignments were discovered:

| Module | RBS Term | Actual Schema Column | Notes |
|--------|---------|---------------------|-------|
| STT | `academic_session_id` | `academic_term_id` | Renamed in v7.6 |
| STT | `weekly_periods` | `required_weekly_periods` | Renamed in v7.6 |
| STT | `class_group_jnt_id` | `class_id` + `section_id` | Decomposed in v7.6 |
| STT | `constraint_level` (Constraint) | `is_hard` boolean | Simplified in v7.6 |
| STT | `competancy_level` | `competency_level` | Typo corrected in v7.6 |

---

## 6. Recommendations for RBS v5.0

### Priority 1 — Add Missing Modules as First-Class Entries
| Action | Module(s) |
|--------|-----------|
| Add full RBS section | SCH_JOB, DSH |
| Elevate from sub-section to standalone | STP, PPT |
| Expand from 2-line stub to full section | PAN, HPC, MNT, VSM |

### Priority 2 — Add Business Rule Appendix
RBS v5.0 should include a dedicated **Business Rules Appendix** covering:
- Indian tax calculation rules (GST, TDS, PF, ESI)
- CBSE/ICSE/State board grading norms
- Fee concession hierarchy and priority matrix
- Attendance-linked business rules (grace period, detention threshold)
- Multi-branch data isolation rules
- Academic calendar revision procedures

### Priority 3 — Sync RBS with v7.6 Schema
All column name changes (see section 5.3) should be reflected in RBS v5.0 to prevent future drift between spec and implementation.

### Priority 4 — Add Integration Contracts Section
RBS v5.0 should include an **Integration Contracts** section documenting:
- D21 event bus payload schemas
- All inter-module event contracts (as in `_01_Cross_Module_Dependencies`)
- External API contracts (payment gateways, SMS providers, biometric devices)

### Priority 5 — Stakeholder Review for High-Extrapolation Modules
Before RBS v5.0 is finalized, the 10 high-extrapolation modules listed in Section 4 should be reviewed with:
- School management stakeholders (for operational workflows)
- IT/infrastructure team (for device integrations)
- Finance/accounts team (for FAC, FIN, PAY rules)
- A school principal or academic coordinator (for ACD, EXA, CRT rules)

---

## 7. V2 Quality Confidence Score

Based on RBS coverage and code availability:

| Confidence | Modules | Basis |
|------------|---------|-------|
| Very High (90%+) | PRM, BIL, GLB, SYS, STD, FIN, QNS, TPT, LIB | High RBS + V1 docs + implemented code |
| High (75–90%) | SCH, TTF, HMW, QUZ, EXM, FAC, INV, HST, HRS, COM, PAY, NTF | High/Med-High RBS + partial code |
| Medium (60–75%) | STT, TTS, SLB, ATT, ACD, ADM, EXA, PPT, LXP, CRT | Medium RBS + patterns from code/V1 |
| Lower (40–60%) | DSH, STP, SLK, DOC, QST, CMP, REC, VND, HPC, CAF, FOF, PAN, MNT, VSM | Low RBS + mostly extrapolated |

---

*RBS Coverage Report V2.0 — 2026-03-26. Re-run assessment after RBS v5.0 is published or after each batch of V2 documents is completed.*
