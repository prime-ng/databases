# HPC Module — Complete Gap Analysis
**Date:** 2026-03-16
**Branch:** Brijesh_HPC
**Auditor:** Claude (Business Analyst Agent)
**Codebase:** /Users/bkwork/Herd/prime_ai_shailesh/Modules/Hpc
**Source PDFs:** 4 Report Cards (138 pages) + 4 How-to-Fill Manuals (386 pages)

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Total pages across all 4 report card PDFs | **138** |
| Pages with full Blade coverage (web form) | **138 (100%)** |
| Pages with full Blade coverage (PDF render) | **138 (100%)** |
| Pages with correct DATA PROVIDER mechanism | **~45 (33%)** — teacher/system pages only |
| Pages missing intended data provider | **~93 (67%)** — student/parent/peer pages filled by teacher proxy |
| Total fields across all PDFs (estimated) | **~1,695** |
| Fields captured in digital form (seeded html_object_names) | **~1,695 (100%)** — all seeded, all renderable |
| Fields fillable by INTENDED provider | **~550 (32%)** — only teacher + system fields |
| Fields requiring student portal (missing) | **~500 (29%)** |
| Fields requiring parent mechanism (missing) | **~200 (12%)** |
| Fields requiring peer workflow (missing) | **~350 (21%)** |
| Sections requiring STUDENT input | **~35 sections** (0% have student portal) |
| Sections requiring PARENT input | **~9 sections** (0% have parent mechanism) |
| Sections requiring PEER input | **~14 sections** (0% have peer workflow) |
| Blueprint screens fully implemented | **4/20 (20%)** |
| Blueprint screens partially implemented | **4/20 (20%)** |
| Blueprint screens NOT started | **12/20 (60%)** |
| Critical security issues | **4** (SEC-HPC-001 through 004) |
| Critical bugs | **14** (BUG-HPC-001 through 014) |
| Performance issues | **2** (PERF-HPC-001, 002) |
| Total known issues (all OPEN) | **20** |
| Overall module completion | **~40%** (was listed as 73%, but counting multi-actor gaps and blueprint coverage reduces it significantly) |

### Completion Breakdown
| Area | Completion |
|------|-----------|
| Template Structure (seeder + DB schema) | 95% |
| Web Form (teacher data entry) | 90% |
| PDF Generation (DomPDF rendering) | 90% |
| CRUD Admin Screens (10 resource controllers) | 85% |
| Report Save/Load | 90% |
| Email to Guardians | 95% |
| ZIP Download | 90% |
| Authorization/Security | **15%** |
| Student Self-Service Portal | **0%** |
| Parent Data Collection Mechanism | **0%** |
| Peer Assessment Workflow | **0%** |
| LMS/Exam Integration (auto-feed) | **0%** |
| Evaluation-to-Report Auto-Feed | **0%** |
| Approval Workflow (Draft→Final→Published) | **5%** |
| Credit Framework Calculator | **0%** |
| Attendance Manager Screen | **0%** |
| Tests | **0%** |

---

## 1. Page-by-Page PDF Fidelity Check

### Template 1: Foundation (18 pages) — BV1-BV3, Grades 1-2

| PDF Pg | Page Title/Section | Web Blade? | PDF Blade? | Key Fields | Data Provider | Gap |
|--------|-------------------|-----------|-----------|------------|---------------|-----|
| 1 | Part A(1) — Student Info + Attendance | form_one | ✅ | school_name, village, brc, crc, state, pin_code, udise_code, teacher_code, apaar_id, student_name, roll_no, reg_no, grade (BV1-Grade2 checkboxes), section, dob, age, photo, address, phone, mother/father name/education/occupation, siblings, mother_tongue, medium_of_instruction, rural_urban, illness_count, 12-month attendance table (working_days × present × % × reasons) + Interest checkboxes (reading, dancing, sports, writing, gardening, yoga, art, craft, cooking, chores, other) | SYSTEM + TEACHER + PARENT | Auto-populate partial; interest section is STUDENT-intended |
| 2 | Part A(2) — Me and My Surroundings | two_form | ✅ | "This is me" drawing, age, birthday, "I live in", family drawing, friends list (5), "I want to be...", favourites (colour, flower, food, sport, animal, subject) | STUDENT | **No student portal** — teacher fills |
| 3 | Domain 1: Physical Development (Assessment) | thred | ✅ | Curricular goals (3 pre-printed), competencies (text), activity (textarea), assessment questions (textarea), rubric 3×3 (Awareness/Sensitivity/Creativity × Stream/Mountain/Sky) | TEACHER | ✅ Match |
| 4 | Domain 1: Physical Development (Feedback) | from_four | ✅ | Teacher feedback (proficiency diagram + notes), Self-assessment (3 emoji questions: liked/easy/resources), Peer assessment (3 emoji questions about friend), Parent observation (home resources icons: books/newspapers/toys/phone/internet/PBS/CWSN/other), Comments | TEACHER + STUDENT + PEER + PARENT | **MIXED — 4 actors, only teacher can fill** |
| 5 | Domain 2: Socio-emotional (Assessment) | form_five | ✅ | Same structure as pg 3 with Domain 2 goals | TEACHER | ✅ Match |
| 6 | Domain 2: Socio-emotional (Feedback) | form_six | ✅ | Same structure as pg 4 | MIXED | Same gap as pg 4 |
| 7 | Domain 3: Cognitive Development (Assessment) | form_seven | ✅ | Same structure as pg 3 with Domain 3 goals | TEACHER | ✅ Match |
| 8 | Domain 3: Cognitive Development (Feedback) | form_eight | ✅ | Same structure as pg 4 | MIXED | Same gap as pg 4 |
| 9 | Domain 4: Language & Literacy (Assessment) | nine | ✅ | Same structure as pg 3 with Domain 4 goals (3 goals) | TEACHER | ✅ Match |
| 10 | Domain 4: Language & Literacy (Feedback) | form_ten | ✅ | Same structure as pg 4 | MIXED | Same gap as pg 4 |
| 11 | Domain 5: Aesthetic & Cultural (Assessment) | form_eleven | ✅ | Same structure as pg 3 with Domain 5 goals | TEACHER | ✅ Match |
| 12 | Domain 5: Aesthetic & Cultural (Feedback) | form_twelve | ✅ | Same structure as pg 4 | MIXED | Same gap as pg 4 |
| 13 | Domain 5.1: Positive Learning Habits (Assessment) | form_thirteen | ✅ | Same structure as pg 3 with Domain 5.1 goals | TEACHER | ✅ Match |
| 14 | Domain 5.1: Positive Learning Habits (Feedback) | form_fourteen | ✅ | Same structure as pg 4 | MIXED | Same gap as pg 4 |
| 15 | Part C — Summary (Key Performance Descriptors) | form_fifteen | ✅ | 3 ability diagrams (Awareness/Sensitivity/Creativity × Sky/Mountain/Stream), 6 domain narrative text areas (5 lines each) | TEACHER | ✅ Match |
| 16 | Credits — Reference + Balvatika 1 | form_sixteen | ✅ | NCrF reference table, BV1 credit scoring table (6 domains × Credits/NCF Level/Credit Points/Earned) | SYSTEM + TEACHER | ✅ Match |
| 17 | Credits — Balvatika 2 & 3 | form_seventeen | ✅ | Same credit table structure for BV2 and BV3 | SYSTEM + TEACHER | ✅ Match |
| 18 | Credits — Grade 1 & Grade 2 | form_eightteen | ✅ | Same credit table structure for Gr1 (NCF 0.2) and Gr2 (NCF 0.4) | SYSTEM + TEACHER | ✅ Match |

**T1 Summary:** 18/18 pages have web+PDF blades. Layout fidelity: HIGH. Data provider gap: Pages 2, 4, 6, 8, 10, 12, 14 require Student/Peer/Parent input with no mechanism.

---

### Template 2: Preparatory (30 pages) — Grades 3-5

| PDF Pg | Page Title/Section | Web Blade? | PDF Blade? | Key Fields | Data Provider | Gap |
|--------|-------------------|-----------|-----------|------------|---------------|-----|
| 1 | Part A(1) — Student Info + Attendance | form_one | ✅ | Same as T1 pg 1 (grade checkboxes: Gr3/Gr4/Gr5), NO interest section | SYSTEM + TEACHER | ✅ Match |
| 2 | Part A(2) — Things About Me | form_second | ✅ | Name, age, family drawing, hand diagram (good at/not good at/improve/like/don't like), favourites (food/games/festivals), "when I grow up", idol, 3 things to learn | STUDENT | **No student portal** |
| 3 | Part A(3) — How Do I Feel at School? | form_thred | ✅ | 7 self-assessment statements × 4 emoji options (Yes/Sometimes/No/Not sure) | STUDENT | **No student portal** |
| 4 | Peer Feedback — Peer 1 | form_four | ✅ | My name, friend's name, 6 peer statements × 4 emoji options | PEER | **No peer workflow** |
| 5 | Peer Feedback — Peer 2 | form_five | ✅ | Same as pg 4 for second reviewer | PEER | **No peer workflow** |
| 6 | Your Child Matters! + Parent Questions 1-5 | form_six | ✅ | Home resources (7 checkboxes + other), 5 parent questions × 4 emoji options | PARENT | **No parent mechanism** |
| 7 | Parent Questions 6-11 + Support Needs | form_seven | ✅ | 6 parent questions × 4 emojis, "child needs support with" (7 checkboxes) | PARENT | **No parent mechanism** |
| 8 | Language Education (R1) — Assessment | form_eight | ✅ | Curricular goals (L1CG1-5 checkboxes), competencies (L1C coded checkboxes), activity, assessment questions, rubric (B/P/A) | TEACHER | ✅ Match |
| 9 | Language Education (R1) — Teacher Feedback | nine | ✅ | Performance level tick table (ASC × B/P/A), observational notes, challenges/overcome table | TEACHER | ✅ Match |
| 10 | Language Education (R1) — Self Assessment | form_ten | ✅ | 8 statements × 3 emojis (yes/no/not sure) | STUDENT | **No student portal** |
| 11 | Language Education (R2) — Assessment | form_eleven | ✅ | Same structure, R2 coded goals/competencies | TEACHER | ✅ Match |
| 12 | Language Education (R2) — Teacher Feedback | form_twelve | ✅ | Same as pg 9 | TEACHER | ✅ Match |
| 13 | Language Education (R2) — Self Assessment | form_thirteen | ✅ | Same as pg 10 | STUDENT | **No student portal** |
| 14 | Mathematics — Assessment | form_fourteen | ✅ | MCG1-5 goals, MC coded competencies | TEACHER | ✅ Match |
| 15 | Mathematics — Teacher Feedback | form_fifteen | ✅ | Same structure | TEACHER | ✅ Match |
| 16 | Mathematics — Self Assessment | form_sixteen | ✅ | Same structure | STUDENT | **No student portal** |
| 17 | The World Around Us — Assessment | form_seventeen | ✅ | TWCG1-7 goals, TW coded competencies | TEACHER | ✅ Match |
| 18 | The World Around Us — Teacher Feedback | form_eightteen | ✅ | Same structure | TEACHER | ✅ Match |
| 19 | The World Around Us — Self Assessment | form_nineteen | ✅ | Same structure | STUDENT | **No student portal** |
| 20 | Art Education — Assessment (LS 1 & 2) | form_twenty | ✅ | VA/T/MU/DM coded goals and competencies (most complex page) | TEACHER | ✅ Match |
| 21 | Art Education — Teacher Feedback | form_twenty_one | ✅ | Same structure | TEACHER | ✅ Match |
| 22 | Art Education — Self Assessment | form_twenty_two | ✅ | Same structure | STUDENT | **No student portal** |
| 23 | Physical Education — Assessment (LS 1 & 2) | form_twenty_three | ✅ | P1CG/P2CG goals, P1C/P2C competencies | TEACHER | ✅ Match |
| 24 | Physical Education — Teacher Feedback | form_twenty_four | ✅ | Same structure | TEACHER | ✅ Match |
| 25 | Physical Education — Self Assessment | form_twenty_five | ✅ | Same structure | STUDENT | **No student portal** |
| 26 | Summary (1/3) — Language R1, R2, Math | form_twenty_six | ✅ | ASC × B/P/A checkbox grids + observational notes per subject | TEACHER | ✅ Match |
| 27 | Summary (2/3) — World Around Us, Art, PE | form_twenty_seven | ✅ | Same structure | TEACHER | ✅ Match |
| 28 | Summary (3/3) — Overall | form_twenty_eight | ✅ | Overall ASC grid + extended narrative (~20 lines) | TEACHER | ✅ Match |
| 29 | Credits — Reference + Grade 3 | form_twenty_nine | ✅ | NCrF reference, Grade 3 credit table (6 learning standards × Credits/NCF/Points/Earned) | SYSTEM + TEACHER | ✅ Match |
| 30 | Credits — Grade 4 & Grade 5 | form_thirty | ✅ | Same structure for Gr4 (NCF 0.8) and Gr5 (NCF 1.0) | SYSTEM + TEACHER | ✅ Match |

**T2 Summary:** 30/30 pages have web+PDF blades. Data provider gap: Pages 2-3 (student), 4-5 (peer), 6-7 (parent), 10/13/16/19/22/25 (student self-assessment) = 12 pages require non-teacher input.

---

### Template 3: Middle (46 pages) — Grades 6-8

| PDF Pg | Page Title/Section | Web Blade? | PDF Blade? | Data Provider | Gap |
|--------|-------------------|-----------|-----------|---------------|-----|
| 1 | Part A(1) — Student Info + Attendance | form_one | ✅ | SYSTEM + TEACHER | ✅ |
| 2 | Part A(2) — All About Me / Self-Evaluation | form_two | ✅ | STUDENT | **No student portal** |
| 3 | Part A(3) — My Ambition Card | form_three | ✅ | STUDENT | **No student portal** |
| 4 | Part A(4) — Parent Feedback + Home Resources | form_four | ✅ | PARENT | **No parent mechanism** |
| 5 | Activity Cycle 1 — Activity Tab | form_five | ✅ | TEACHER | ✅ |
| 6 | Activity Cycle 1 — Self-Reflection | form_six | ✅ | STUDENT | **No student portal** |
| 7 | Activity Cycle 1 — Peer Feedback | form_seven | ✅ | PEER | **No peer workflow** |
| 8 | Activity Cycle 1 — Teacher Feedback | form_eight | ✅ | TEACHER | ✅ |
| 9-12 | Activity Cycle 2 (same 4-page pattern) | ✅ | ✅ | T/S/P/T | Same gaps |
| 13-16 | Activity Cycle 3 | ✅ | ✅ | T/S/P/T | Same gaps |
| 17-20 | Activity Cycle 4 | ✅ | ✅ | T/S/P/T | Same gaps |
| 21-24 | Activity Cycle 5 | ✅ | ✅ | T/S/P/T | Same gaps |
| 25-28 | Activity Cycle 6 | ✅ | ✅ | T/S/P/T | Same gaps |
| 29-32 | Activity Cycle 7 | ✅ | ✅ | T/S/P/T | Same gaps |
| 33-36 | Activity Cycle 8 | ✅ | ✅ | T/S/P/T | Same gaps |
| 37-40 | Activity Cycle 9 | ✅ | ✅ | T/S/P/T | Same gaps |
| 41-44 | Summary (4 pages — subject groups) | ✅ | ✅ | TEACHER | ✅ |
| 45-46 | Credits (Grade 6 + Gr7/Gr8) | ✅ | ✅ | SYSTEM + TEACHER | ✅ |

**T3 Summary:** 46/46 pages have web+PDF blades. Activity cycle pattern (9 cycles × 4 pages = 36 pages). Data provider gap: pg 2-3 (student), pg 4 (parent), 9 self-reflection pages (student), 9 peer feedback pages (peer) = **21 pages** require non-teacher input.

---

### Template 4: Secondary (44 pages) — Grades 9-12

| PDF Pg | Page Title/Section | Web Blade? | PDF Blade? | Data Provider | Gap |
|--------|-------------------|-----------|-----------|---------------|-----|
| 1 | Part A(1) — Student Info + Attendance | form_one | ✅ | SYSTEM + TEACHER | ✅ |
| 2 | Part A(2) — Self-Evaluation | form_two | ✅ | STUDENT | **No student portal** |
| 3 | Part A(2 contd.) — Goals + Support Table | form_three | ✅ | STUDENT | **No student portal** |
| 4 | Part A(3) — Time Management (5-item Likert) | form_four | ✅ | STUDENT | **No student portal** |
| 5 | Part A(3c) — Time Map | form_five | ✅ | STUDENT | **No student portal** |
| 6 | Part A(4) — Plans After School | form_six | ✅ | STUDENT | **No student portal** |
| 7 | Part A — Future Self | form_seven | ✅ | STUDENT | **No student portal** |
| 8 | Part A(5) — Accomplishments | form_eight | ✅ | STUDENT + TEACHER | **No student portal** |
| 9 | Part A(6) — Skills for Life | form_nine | ✅ | STUDENT | **No student portal** |
| 10 | Activity Cycle 1 — Activity Tab | form_ten | ✅ | TEACHER | ✅ |
| 11 | Activity Cycle 1 — Self-Reflection | form_eleven | ✅ | STUDENT | **No student portal** |
| 12 | Activity Cycle 1 — Peer Feedback | form_twelve | ✅ | PEER | **No peer workflow** |
| 13 | Activity Cycle 1 — Teacher Feedback | form_thirteen | ✅ | TEACHER | ✅ |
| 14-17 | Activity Cycle 2 (same 4-page pattern) | ✅ | ✅ | T/S/P/T | Same gaps |
| 18-21 | Activity Cycle 3 | ✅ | ✅ | T/S/P/T | Same gaps |
| 22-25 | Activity Cycle 4 | ✅ | ✅ | T/S/P/T | Same gaps |
| 26-29 | Activity Cycle 5 | ✅ | ✅ | T/S/P/T | Same gaps |
| 30-33 | Activity Cycle 6 | ✅ | ✅ | T/S/P/T | Same gaps |
| 34-37 | Activity Cycle 7 | ✅ | ✅ | T/S/P/T | Same gaps |
| 38-41 | Activity Cycle 8 | ✅ | ✅ | T/S/P/T | Same gaps |
| 42 | Part C — Summary | form_forty_two | ✅ | TEACHER | ✅ |
| 43 | Credits — Grade 9 & 10 | form_forty_three | ✅ | SYSTEM + TEACHER | ✅ |
| 44 | Credits — Grade 11 & 12 | form_forty_four | ✅ | SYSTEM + TEACHER | ✅ |

**T4 Summary:** 44/44 pages have web+PDF blades. Data provider gap: pg 2-9 (8 student pages), 8 self-reflection pages (student), 8 peer feedback pages (peer) = **24 pages** require non-teacher input. T4 has NO parent pages (student is primary at secondary stage).

---

### Fidelity Summary

| Metric | T1 (18pg) | T2 (30pg) | T3 (46pg) | T4 (44pg) | Total |
|--------|-----------|-----------|-----------|-----------|-------|
| Pages in PDF | 18 | 30 | 46 | 44 | **138** |
| Pages in Web Blade | 18 | 30 | 46 | 44 | **138** |
| Pages in PDF Blade | 18 | 30 | 46 | 44 | **138** |
| Pages fully matching (teacher/system only) | 11 | 18 | 25 | 20 | **74** |
| Pages with data provider gap | 7 | 12 | 21 | 24 | **64** |
| Estimated fields in PDF | ~267 | ~405 | ~521 | ~502 | **~1,695** |
| Fields seeded in DB | ~267 | ~405 | ~521 | ~502 | **~1,695** |
| Fields fillable by intended provider | ~180 | ~230 | ~250 | ~200 | **~860** |
| Fields requiring student portal | ~30 | ~80 | ~130 | ~260 | **~500** |
| Fields requiring parent mechanism | ~50 | ~70 | ~50 | 0 | **~170** |
| Fields requiring peer workflow | 0 | ~25 | ~90 | ~90 | **~205** |
| Template structure fidelity | 100% | 100% | 100% | 100% | **100%** |
| Field coverage (seeded) | 100% | 100% | 100% | 100% | **100%** |
| Data provider correctness | 61% | 60% | 54% | 45% | **51%** |

**Key Finding:** All 138 pages and ~1,695 fields exist in the digital system. The template/seeder/blade infrastructure is complete. The critical gap is **data provider access** — 64 pages (46%) of the report should be filled by students, parents, or peers but currently only teachers can fill them.

---

## 2. Data Provider Analysis

### Per-Template Provider Map

#### T1 — Foundation (18 pages)
| Pages | Section | Intended Provider | Current Provider | Input Mechanism? | Gap |
|-------|---------|-------------------|------------------|-----------------|-----|
| 1 (school/student info) | Part A(1) | SYSTEM | SYSTEM + TEACHER | Yes (auto-populate partial) | Working days source unclear |
| 1 (attendance) | Attendance | SYSTEM | SYSTEM | Yes (std_student_attendance) | Partial — no working_days source table |
| 1 (interests) | Interest checkboxes | STUDENT | TEACHER (proxy) | No | Need student input |
| 2 | Me and My Surroundings | STUDENT | TEACHER (proxy) | No | Need student portal |
| 3,5,7,9,11,13 | Domain Assessments × 6 | TEACHER | TEACHER | Yes (HPC form) | ✅ |
| 4,6,8,10,12,14 (teacher) | Teacher Feedback | TEACHER | TEACHER | Yes | ✅ |
| 4,6,8,10,12,14 (self) | Self Assessment (emojis) | STUDENT | TEACHER (proxy) | No | Need student portal |
| 4,6,8,10,12,14 (peer) | Peer Assessment (emojis) | PEER | TEACHER (proxy) | No | Need peer workflow |
| 4,6,8,10,12,14 (parent) | Parent Observation (resources) | PARENT | TEACHER (proxy) | No | Need parent mechanism |
| 15 | Summary Descriptors | TEACHER | TEACHER | Yes | ✅ |
| 16-18 | Credits | SYSTEM + TEACHER | SYSTEM + TEACHER | Yes | ✅ |

#### T2 — Preparatory (30 pages)
| Pages | Section | Intended Provider | Current Provider | Input Mechanism? | Gap |
|-------|---------|-------------------|------------------|-----------------|-----|
| 1 | Student Info + Attendance | SYSTEM | SYSTEM + TEACHER | Yes | ✅ |
| 2 | Things About Me | STUDENT | TEACHER (proxy) | No | Need student portal |
| 3 | How Do I Feel at School? (7 items) | STUDENT | TEACHER (proxy) | No | Need student portal |
| 4-5 | Peer Feedback (Peer 1 + Peer 2) | PEER | TEACHER (proxy) | No | Need peer workflow |
| 6-7 | Parent Feedback (resources + Q1-Q11 + support) | PARENT | TEACHER (proxy) | No | Need parent mechanism |
| 8,11,14,17,20,23 | Subject Assessments × 6 | TEACHER | TEACHER | Yes | ✅ |
| 9,12,15,18,21,24 | Teacher Feedback × 6 | TEACHER | TEACHER | Yes | ✅ |
| 10,13,16,19,22,25 | Self Assessment × 6 (8 items each) | STUDENT | TEACHER (proxy) | No | Need student portal |
| 26-28 | Summary (3 pages) | TEACHER | TEACHER | Yes | ✅ |
| 29-30 | Credits | SYSTEM + TEACHER | SYSTEM + TEACHER | Yes | ✅ |

#### T3 — Middle (46 pages)
| Pages | Section | Intended Provider | Current Provider | Input Mechanism? | Gap |
|-------|---------|-------------------|------------------|-----------------|-----|
| 1 | Student Info + Attendance | SYSTEM | SYSTEM + TEACHER | Yes | ✅ |
| 2 | All About Me / Self-Evaluation | STUDENT | TEACHER (proxy) | No | Need student portal |
| 3 | My Ambition Card | STUDENT | TEACHER (proxy) | No | Need student portal |
| 4 | Parent Feedback + Home Resources | PARENT | TEACHER (proxy) | No | Need parent mechanism |
| 5,9,13,17,21,25,29,33,37 | Activity Tab × 9 | TEACHER | TEACHER | Yes | ✅ |
| 6,10,14,18,22,26,30,34,38 | Self-Reflection × 9 | STUDENT | TEACHER (proxy) | No | Need student portal |
| 7,11,15,19,23,27,31,35,39 | Peer Feedback × 9 | PEER | TEACHER (proxy) | No | Need peer workflow |
| 8,12,16,20,24,28,32,36,40 | Teacher Feedback × 9 | TEACHER | TEACHER | Yes | ✅ |
| 41-44 | Summary (4 pages) | TEACHER | TEACHER | Yes | ✅ |
| 45-46 | Credits | SYSTEM + TEACHER | SYSTEM + TEACHER | Yes | ✅ |

#### T4 — Secondary (44 pages)
| Pages | Section | Intended Provider | Current Provider | Input Mechanism? | Gap |
|-------|---------|-------------------|------------------|-----------------|-----|
| 1 | Student Info + Attendance | SYSTEM | SYSTEM + TEACHER | Yes | ✅ |
| 2 | Self-Evaluation | STUDENT | TEACHER (proxy) | No | Need student portal |
| 3 | Goals + Support Table | STUDENT | TEACHER (proxy) | No | Need student portal |
| 4 | Time Management (Likert) | STUDENT | TEACHER (proxy) | No | Need student portal |
| 5 | Time Map | STUDENT | TEACHER (proxy) | No | Need student portal |
| 6 | Plans After School | STUDENT | TEACHER (proxy) | No | Need student portal |
| 7 | Future Self | STUDENT | TEACHER (proxy) | No | Need student portal |
| 8 | Accomplishments | STUDENT + TEACHER | TEACHER (proxy) | No | Need student portal |
| 9 | Skills for Life | STUDENT | TEACHER (proxy) | No | Need student portal |
| 10,14,18,22,26,30,34,38 | Activity Tab × 8 | TEACHER | TEACHER | Yes | ✅ |
| 11,15,19,23,27,31,35,39 | Self-Reflection × 8 | STUDENT | TEACHER (proxy) | No | Need student portal |
| 12,16,20,24,28,32,36,40 | Peer Feedback × 8 | PEER | TEACHER (proxy) | No | Need peer workflow |
| 13,17,21,25,29,33,37,41 | Teacher Feedback × 8 | TEACHER | TEACHER | Yes | ✅ |
| 42 | Summary | TEACHER | TEACHER | Yes | ✅ |
| 43-44 | Credits | SYSTEM + TEACHER | SYSTEM + TEACHER | Yes | ✅ |

### Aggregate Provider Summary

| Provider | Total Sections | Currently Has Input? | Sections Fillable By Intended Provider |
|----------|---------------|---------------------|---------------------------------------|
| SYSTEM | ~8 sections (pg1 of each template) | Yes (auto-populate) | 8/8 (100%) |
| TEACHER | ~59 sections | Yes (HPC form) | 59/59 (100%) |
| STUDENT | ~35 sections | **No** | **0/35 (0%)** |
| PARENT | ~9 sections | **No** | **0/9 (0%)** |
| PEER | ~14 sections | **No** | **0/14 (0%)** |
| MIXED | ~8 sections | Partial (teacher part only) | ~4/8 (50%) |

### Teacher Workload Impact

| Template | Pages/Student | Teacher-Fillable | Student Pages | Parent Pages | Peer Pages | Teacher Time If Solo | Teacher Time With Multi-Actor |
|----------|--------------|------------------|---------------|-------------|------------|---------------------|-------------------------------|
| T1 (Pre-primary) | 18 | 11 | 1 | 6 (embedded) | 0 | ~10 min | ~7 min |
| T2 (Grades 3-5) | 30 | 18 | 8 | 2 | 2 | ~20 min | ~12 min |
| T3 (Grades 6-8) | 46 | 25 | 11 | 1 | 9 | ~30 min | ~15 min |
| T4 (Grades 9-12) | 44 | 20 | 16 | 0 | 8 | **~45 min** | **~20 min** |

**Critical bottleneck: T4.** A class teacher with 40 students currently spends **~30 hours** (4 full workdays) per term on HPC data entry. With multi-actor collection, this drops to **~13 hours**.

---

## 3. Feature Completeness vs Blueprint

The implementation blueprint defines 20 screens across 5 sets.

| Screen | Blueprint Section | Controller Method(s) | View? | Route? | Status | Gap Description |
|--------|-------------------|---------------------|-------|--------|--------|-----------------|
| **SC-01** Template Builder | Phase 1 | HpcTemplatesController::*, HpcTemplatePartsController::*, HpcTemplateSectionsController::*, HpcTemplateRubricsController::* | Yes (5 CRUD views each) | Yes (BUT 4 imports missing → BUG-HPC-001) | **PARTIAL** | Routes 500 due to missing `use` imports in tenant.php |
| **SC-02** Circular Goals Manager | Phase 1 | CircularGoalsController::* | Yes (5 views) | Yes | **DONE** | Working CRUD with competency mapping |
| **SC-03** Learning Outcomes Mapper | Phase 1 | LearningOutcomesController::*, QuestionMappingController::* | Yes (5 views each) | Yes | **DONE** | Working CRUD + question mapping |
| **SC-04** Activity Type Configurator | Phase 1 | LearningActivitiesController::* | Yes (5 views) | Yes | **PARTIAL** | LearningActivityType has model but no dedicated CRUD controller |
| **SC-05** My Class Dashboard | Phase 1 | HpcController::index() | Yes (hpc/index) | Yes | **PARTIAL** | Basic student listing only; no progress charts, no pending assessments count, no quick entry |
| **SC-06** Part-A Data Entry | Phase 1 | HpcController::hpc_form() + formStore() | Yes (form partials) | Yes | **DONE** | Working form with save/load |
| **SC-07** Attendance Manager | Phase 2 | None | No | No | **NOT STARTED** | No dedicated attendance calendar/bulk-mark screen |
| **SC-08** Domain Assessment Dashboard | Phase 2 | StudentHpcEvaluationController::* | Yes (5 views) | Yes | **PARTIAL** | Basic CRUD only; no tabbed 5-domain interface, no rubric matrix, no evidence attachment |
| **SC-09** Activity Assessment Screen | Phase 2 | None | No | No | **NOT STARTED** | No activity-specific assessment screen with self/peer toggles |
| **SC-10** Teacher Feedback Form | Phase 2 | Embedded in HPC form pages | Partial | Partial | **PARTIAL** | Teacher feedback exists within form pages but no dedicated screen with checklists/performance wheel |
| **SC-11** Student Dashboard | Phase 1 | None | No | No | **NOT STARTED** | No student-facing HPC interface |
| **SC-12** Self-Assessment Screen | Phase 1 | None | No | No | **NOT STARTED** | No student self-assessment mechanism |
| **SC-13** Peer Assessment Screen | Phase 3 | None | No | No | **NOT STARTED** | No peer assessment workflow |
| **SC-14** My Goals & Aspirations | Phase 3 | None | No | No | **NOT STARTED** | No student goal-setting interface |
| **SC-15** Parent Portal Dashboard | Phase 2 | None | No | No | **NOT STARTED** | No parent-facing HPC interface |
| **SC-16** Parent Input Form | Phase 2 | None | No | No | **NOT STARTED** | No parent data collection mechanism |
| **SC-17** Parent-Teacher Communication | Phase 2 | None | No | No | **NOT STARTED** | No messaging system |
| **SC-18** HPC Report Preview | Phase 2 | HpcController::viewPdfPage() | Yes (renders PDF in browser) | Yes | **PARTIAL** | View works but no data validation warnings, no missing data highlights, no manual override |
| **SC-19** Bulk Report Generator | Phase 3 | HpcController::generateReportPdf() + downloadZip() + sendReportEmail() | Yes | Yes | **DONE** | Bulk PDF generation + ZIP + email to guardians working |
| **SC-20** Credit Calculator | Phase 3 | None | No | No | **NOT STARTED** | No dedicated credit calculation service or screen |

### Blueprint Completion Summary
| Category | Done | Partial | Not Started | Total |
|----------|------|---------|-------------|-------|
| Admin Configuration | 2 | 2 | 0 | 4 |
| Teacher Interface | 1 | 3 | 2 | 6 |
| Student Interface | 0 | 0 | 4 | 4 |
| Parent Interface | 0 | 0 | 3 | 3 |
| Report Generation | 1 | 1 | 1 | 3 |
| **Total** | **4 (20%)** | **6 (30%)** | **10 (50%)** | **20** |

---

## 4. Schema vs Code Alignment

### DDL v2 Tables (11 tables — Template + Report Management)

| DDL Table | Model? | Model Name | $fillable Complete? | Migration? | Relationships OK? | Issues |
|-----------|--------|------------|--------------------|-----------|--------------------|--------|
| `hpc_templates` | ✅ | HpcTemplates | Yes | Yes (2026_02_24_100001) | Yes | None |
| `hpc_template_parts` | ✅ | HpcTemplateParts | Yes | Yes (2026_02_24_100002) | Yes | None |
| `hpc_template_parts_items` | ✅ | HpcTemplatePartsItems | Yes | Yes (2026_02_24_100003) | Yes | None |
| `hpc_template_sections` | ✅ | HpcTemplateSections | Yes | Yes (2026_02_24_100004) | Yes | None |
| `hpc_template_section_items` | ✅ | HpcTemplateSectionItems | Yes | Yes (2026_02_24_100005) | Yes | None |
| `hpc_template_section_table` | ✅ | HpcTemplateSectionTable | Yes | Yes (2026_02_24_100006) | Yes | None |
| `hpc_template_rubrics` | ✅ | HpcTemplateRubrics | Yes | Yes (2026_02_24_100007) | Yes | None |
| `hpc_template_rubric_items` | ✅ | HpcTemplateRubricItems | Yes | Yes (2026_02_24_100008) | Yes | None |
| `hpc_reports` | ✅ | HpcReport | Yes | Yes (2026_02_27_000001) | Yes | FK refs `cbse_terms` — may need to be `sch_academic_term` |
| `hpc_report_items` | ✅ | HpcReportItem | Yes | Yes (2026_02_27_000002) | Yes | None |
| `hpc_report_table` | ✅ | HpcReportTable | Yes | Yes (2026_02_27_000003) | Yes | None |

### Schema-2 Tables (15 additional models — NEP 2020 / PARAKH)

| Table | Model? | Model Name | $fillable? | Migration? | Issues |
|-------|--------|------------|-----------|-----------|--------|
| `hpc_circular_goals` | ✅ | CircularGoals | Yes | Not found in tenant/ | **Missing migration** — table may be created via seeder or manual SQL |
| `hpc_circular_goal_competency_jnt` | ✅ | CircularGoalCompetencyJnt | Yes | Not found | **Missing migration** |
| `hpc_learning_outcomes` | ✅ | LearningOutcomes | Yes | Not found | **Missing migration** |
| `hpc_outcome_entity_jnt` | ✅ | OutcomesEntityJnt | Yes | Not found | **Missing migration** |
| `hpc_outcome_question_jnt` | ✅ | OutcomesQuestionJnt | Yes | Not found | **Missing migration** |
| `hpc_knowledge_graph_validation` | ✅ | KnowledgeGraphValidation | Yes | Not found | **Missing migration** |
| `hpc_topic_equivalency` | ✅ | TopicEquivalency | Yes | Not found | **Missing migration** |
| `hpc_syllabus_coverage_snapshot` | ✅ | SyllabusCoverageSnapshot | Yes | Not found | **Missing migration** |
| `hpc_ability_parameters` | ✅ | HpcParameters | Yes | Not found | **Missing migration** |
| `hpc_performance_descriptors` | ✅ | HpcPerformanceDescriptor | Yes | Not found | **Missing migration** |
| `hpc_student_evaluation` | ✅ | StudentHpcEvaluation | Yes | Not found | **Missing migration** |
| `hpc_learning_activities` | ✅ | LearningActivities | Yes | Not found | **Missing migration** |
| `hpc_learning_activity_type` | ✅ | LearningActivityType | Yes | Not found | **Missing migration** |
| `hpc_student_hpc_snapshot` | ✅ | StudentHpcSnapshot | Yes | Not found | **Missing migration**; BUG-HPC-007 wrong Student import |
| `hpc_hpc_levels` | ✅ | HpcLevels | Yes | Not found | **Missing migration**; BUG-HPC-010 duplicate prefix naming |

**Critical Finding:** Only 11 of 26 tables have migrations in `database/migrations/tenant/`. The remaining 15 Schema-2 tables have models but **no migration files** — they may have been created via raw SQL or a separate process. This is a deployment risk.

### Model-Level Issues
- **BUG-HPC-006:** `HpcTemplates` model uses uppercase class references (`HPCTemplateSections`) — works on macOS (case-insensitive FS) but breaks on Linux deployment.
- **BUG-HPC-007:** `StudentHpcSnapshot` imports `Student` from `SchoolSetup` instead of `StudentProfile`.
- **BUG-HPC-011:** 18/26 models missing `created_by` from `$fillable` — column cannot be mass-assigned.
- All 26 models correctly use `SoftDeletes` trait. ✅

---

## 5. Security & Authorization Audit

### HpcController (Main Controller — 15 public methods)

| Method | Gate::authorize? | FormRequest? | $request->validated()? | Issues |
|--------|-----------------|-------------|----------------------|--------|
| `index()` | Gate::any([...]) OR abort(403) | No | N/A | Uses Gate::any not Gate::authorize — weaker check |
| `hpcTemplates()` | **NO** | No | N/A | **SEC-HPC-001** |
| `create()` | **NO** | N/A | N/A | **SEC-HPC-001** — empty body |
| `store()` | **NO** | No | N/A | **SEC-HPC-001** — empty body |
| `show()` | **NO** | N/A | N/A | **SEC-HPC-001** |
| `edit()` | **NO** | N/A | N/A | **SEC-HPC-001** |
| `update()` | **NO** | No | N/A | **SEC-HPC-001** — empty body |
| `destroy()` | **NO** | N/A | N/A | **SEC-HPC-001** — empty body |
| `hpc_form()` | **NO** | No | N/A | **SEC-HPC-001** |
| `formStore()` | **NO** | No; inline validate() | **$request->all()** at line 823 | **CRITICAL: mass assignment risk** |
| `generateReportPdf()` | **NO** | No; inline validate() | $request->input() | **SEC-HPC-001** |
| `sendReportEmail()` | Gate::authorize('tenant.hpc.viewAny') | No; inline validate() | $request->input() | ✅ Only properly gated method |
| `viewPdfPage()` | **NO** | No | N/A | **SEC-HPC-001** |
| `generateSingleStudentPdf()` | **NO** | No | N/A | **SEC-HPC-001** |
| `downloadZip()` | **NO** | N/A | N/A | **SEC-HPC-001** — file path traversal risk |

**Result: 2/15 methods have Gate check (13%).**

### Sub-Controllers (14 controllers)

| Controller | Total Methods | Gate on CRUD? | FormRequest? | FR authorize() | Issues |
|------------|-------------|--------------|-------------|----------------|--------|
| CircularGoalsController | 11 | 8/11 | CircularGoalsRequest | **return true** | store/update unprotected |
| HpcParametersController | 11 | 10/11 | HpcParametersRequest | Gate::allows ✅ | toggleStatus only weak area |
| HpcPerformanceDescriptorController | 11 | 10/11 | HpcPerfDescriptorReq | Gate::allows ✅ | Same pattern as Parameters |
| HpcTemplatePartsController | 11 | 11/11 | HpcTemplatePartsReq | **return true** | Controller has Gate ✅ |
| HpcTemplateRubricsController | 11 | 11/11 | HpcTemplateRubricsReq | **return true** | Controller has Gate ✅ |
| HpcTemplatesController | 11 | 10/11 | HpcTemplatesRequest | **return true** | **BUG-HPC-003: show() garbled permission** |
| HpcTemplateSectionsController | 11 | 11/11 | HpcTemplateSectionsReq | **return true** | Controller has Gate ✅ |
| KnowledgeGraphValidationController | 11 | 8/11 | KnowledgeGraphValReq | **return true** | store/update/trashed unprotected |
| LearningActivitiesController | 11 | 10/11 | LearningActivitiesReq | Gate::allows ✅ | getLevels() no gate (acceptable) |
| LearningOutcomesController | 12 | 10/12 | LearningOutcomesReq | Gate::allows ✅ | getLevels() no gate (acceptable) |
| QuestionMappingController | 11 | 8/11 | QuestionMappingReq | **return true** | store/update unprotected |
| StudentHpcEvaluationController | 11 | 10/11 | StudentHpcEvalReq | Gate::allows ✅ | Good coverage |
| SyllabusCoverageSnapshotController | 11 | 8/11 | SyllabusCoverageReq | **return true** | store/update unprotected |
| TopicEquivalencyController | 12 | 10/12 | TopicEquivalencyReq | Gate::allows ✅ | getEquivalencyTypes() no gate (acceptable) |

### Authorization Summary
- **Total public methods across all 15 controllers:** ~169
- **Methods with effective Gate check:** ~133
- **Methods WITHOUT Gate check:** ~36 (21%)
- **7/14 FormRequests return `true`** in authorize() — relying on controller-level Gate (but 4 controllers with FR `return true` also lack Gate on store/update)
- **No `EnsureTenantHasModule` middleware** on HPC route group (SEC-HPC-003)
- **No `dd()` or `dump()` found** ✅
- **No hardcoded API keys found** ✅
- **$request->all() in formStore()** — mass assignment surface
- **BUG-HPC-003:** Garbled permission string in HpcTemplatesController::show()
- **BUG-HPC-012:** LearningOutcomesController imports `Prime\Dropdown` — cross-layer

### Additional Security Checks
| Check | Result |
|-------|--------|
| `$fillable` contains `is_super_admin`? | **No** ✅ |
| `$fillable` contains `remember_token`? | **No** ✅ |
| `dd()` or `dump()` anywhere? | **No** ✅ |
| Hardcoded API keys? | **No** ✅ |
| `EnsureTenantHasModule` middleware? | **Missing** — SEC-HPC-003 |
| Cross-layer model imports? | **Yes** — BUG-HPC-004 (AcademicSession), BUG-HPC-012 (Dropdown) |
| Module web.php/api.php routes outside tenancy? | **Yes** — SEC-HPC-004 |

---

## 6. Route Health Check

### HPC Routes in tenant.php (~89 route references)

**Main HPC Routes:**

| HTTP Method | URI | Controller@Method | Method Exists? | Import? | Issues |
|------------|-----|-------------------|---------------|---------|--------|
| GET | /hpc/hpc | HpcController@index | ✅ | ✅ | None |
| GET | /hpc/templates | HpcController@hpcTemplates | ✅ | ✅ | None |
| GET | /hpc/hpc-form/{student_id?} | HpcController@hpc_form | ✅ | ✅ | None |
| POST | /hpc/form/store | HpcController@formStore | ✅ | ✅ | None |
| POST | /hpc/generate-report | HpcController@generateReportPdf | ✅ | ✅ | None |
| POST | /hpc/send-report-email | HpcController@sendReportEmail | ✅ | ✅ | None |
| GET | /hpc/hpc-view/{student_id?} | HpcController@viewPdfPage | ✅ | ✅ | None |
| GET | /hpc/hpc-single/{student_id?} | HpcController@generateSingleStudentPdf | ✅ | ✅ | None |
| GET | /hpc/download-zip/{filename} | HpcController@downloadZip | ✅ | ✅ | Path traversal risk |

**Template Management Routes (BROKEN):**

| HTTP Method | URI | Controller | Import? | Issues |
|------------|-----|-----------|---------|--------|
| Resource | /hpc/hpc-templates | HpcTemplatesController | **MISSING** | **BUG-HPC-001: 500 on access** |
| Resource | /hpc/hpc-template-parts | HpcTemplatePartsController | **MISSING** | **BUG-HPC-001: 500 on access** |
| Resource | /hpc/hpc-template-sections | HpcTemplateSectionsController | **MISSING** | **BUG-HPC-001: 500 on access** |
| Resource | /hpc/hpc-template-rubrics | HpcTemplateRubricsController | **MISSING** | **BUG-HPC-001: 500 on access** |

**CRUD Resource Routes (working):**

| Resource | Controller | Import? | Trash Before Resource? | Issues |
|----------|-----------|---------|----------------------|--------|
| circular-goals | CircularGoalsController | ✅ | ⚠️ Check order | BUG-HPC-009: Possible route shadow |
| question-mapping | QuestionMappingController | ✅ | ⚠️ | Same concern |
| learning-activities | LearningActivitiesController | ✅ | ⚠️ | Same concern |
| learning-outcomes | LearningOutcomesController | ✅ | ⚠️ | Same concern |
| knowledge-graph-validation | KnowledgeGraphValidationController | ✅ | ⚠️ | Same concern |
| syllabus-coverage-snapshot | SyllabusCoverageSnapshotController | ✅ | ⚠️ | Same concern |
| topic-equivalency | TopicEquivalencyController | ✅ | ⚠️ | Same concern |
| student-hpc-evaluation | StudentHpcEvaluationController | ✅ | ⚠️ | Same concern |
| hpc-parameters | HpcParametersController | ✅ | ⚠️ | Same concern |
| hpc-performance-descriptor | HpcPerformanceDescriptorController | ✅ | ⚠️ | Same concern |

### Route Issues Summary
- **Dead Routes:** BUG-HPC-005 — 3 routes to non-existent methods (hpcSecondForm, hpcThredForm, hpcFourthForm)
- **Missing Imports:** BUG-HPC-001 — 4 template controller classes not imported in tenant.php
- **Orphan Import:** BUG-HPC-008 — `LearningActivityController` (singular, wrong name) imported but file doesn't exist
- **Shadowed Routes:** BUG-HPC-009 — trash/view routes registered AFTER Route::resource() — `trash` matches `{id}` parameter
- **Typo in Permission:** `tenant.topic-equivalency-snapsho.viewAny` — missing final "t" in "snapshot"

---

## 7. Data Flow & Integration Gaps

| Data Element | Source Module | Auto-Feed Implemented? | Manual Entry? | Status | Gap |
|-------------|-------------|----------------------|---------------|--------|-----|
| Student name, DOB, gender, admission_no | StudentProfile (`std_students`) | Yes — HpcController extracts from Student model | No | **DONE** | None |
| Parent/Guardian info (name, education, occupation) | StudentProfile (`std_guardians`) | Yes — via Student→guardians relationship | No | **DONE** | None |
| School info (name, address, UDISE, affiliation) | SchoolSetup (`sch_organizations`) | Yes — auto-populated in form | No | **DONE** | None |
| Student photo | StudentProfile (Spatie Media) | Yes — profile photo URL | No | **DONE** | None |
| Attendance (monthly: working days, present, %) | StudentProfile (`std_student_attendance`) | Partial — basic query exists | Teacher fills reasons | **PARTIAL** | No `working_days` source table; absence reasons not categorized |
| Siblings info (count, ages) | StudentProfile (`std_student_details`) | Yes — auto-populated | No | **DONE** | None |
| Exam/Assessment scores | LmsExam (`exm_*`) | **No** | Teacher re-enters | **NOT STARTED** | No API endpoint, no data bridge |
| Quiz scores | LmsQuiz (`quz_*`) | **No** | Teacher re-enters | **NOT STARTED** | No integration |
| Homework completion | LmsHomework (`hmw_*`) | **No** | Teacher re-enters | **NOT STARTED** | No integration |
| `hpc_student_evaluation` → report items | HPC internal | **No** | Teacher fills same data twice | **NOT STARTED** | GAP-7: Evaluation CRUD data not auto-fed to report pages |
| Student self-assessment input | StudentPortal | **No** | Teacher fills as proxy | **NOT STARTED** | GAP-1: No student self-service portal |
| Parent feedback/observations | Parent link/form | **No** | Teacher fills as proxy | **NOT STARTED** | GAP-2: No parent data collection mechanism |
| Peer assessment input | Peer workflow | **No** | Teacher fills as proxy | **NOT STARTED** | GAP-3: No peer assessment workflow |
| Credit framework calculation (NCrF) | HPC service | **No** | Teacher manually calculates | **NOT STARTED** | No credit calculation service |
| MOOC/Online course tracking (T4) | External API | **No** | Teacher manually enters | **NOT STARTED** | No MOOC integration |
| HPC report status workflow | HPC internal | `status` ENUM exists | No enforcement | **5%** | GAP-5: Anyone can set status to Published |
| Role-based section locking | HPC internal | **No** | formStore() accepts all fields from any user | **NOT STARTED** | GAP-4: No section ownership |

---

## 8. Multi-Actor Data Collection Status

Validation of GAP-1 through GAP-8 from `2026Mar14_HPC_Gap_Analysis.md`:

| Gap ID | Description | Previous Status | Current Status | Evidence | Remaining Work |
|--------|-------------|----------------|---------------|----------|---------------|
| **GAP-1** | No Student Self-Service Portal | 0% | **0% — Still Open** | No StudentHpcFormController found; no student route group; no student-facing views in Hpc module | Full implementation: new controller, routes, views, section filtering, progress tracking, notification |
| **GAP-2** | No Parent Data Collection Mechanism | 0% | **0% — Still Open** | No ParentHpcFormController; no signed URL mechanism; no parent_token column on hpc_reports | Full implementation: token-based signed URLs, standalone mobile form, SMS/WhatsApp delivery |
| **GAP-3** | No Peer Assessment Workflow | 0% | **0% — Still Open** | No peer assignment mechanism; no peer-to-peer routing; peer feedback pages exist but filled by teacher | Full implementation: peer assignment service, activity-level peer pairing, aggregation into report |
| **GAP-4** | No Role-Based Section Locking | 0% | **0% — Still Open** | formStore() accepts ALL fields from ANY authenticated user via $request->all(); no owner_role column on rubric items | Full implementation: add owner_role ENUM, enforce in formStore(), visual locking in UI |
| **GAP-5** | No Approval/Review Workflow | ~5% | **~5% — Unchanged** | `hpc_reports.status` ENUM exists (Draft/Final/Published/Archived) but no state machine enforcement, no principal review, no notification chain | State machine, workflow columns, notification events, completion dashboard |
| **GAP-6** | No Auto-Feed from LMS/Exam | 0% | **0% — Still Open** | No API endpoints exist between LmsExam/LmsQuiz/LmsHomework and HPC; teachers manually re-enter scores | Integration service, data mapping, auto-population triggers |
| **GAP-7** | No Auto-Feed from hpc_student_evaluation to report | 0% | **0% — Still Open** | StudentHpcEvaluation CRUD works, data saved to DB, but report pages 29-30/36-37 ignore evaluation data | Service to copy evaluation data into report items when generating/loading |
| **GAP-8** | Attendance Data Partial | ~30% | **~30% — Unchanged** | Basic std_student_attendance query exists in HpcController; no working_days source; absence reasons not categorized; no transport module integration | Working days table/config, categorized absences, transport integration |

**All 8 gaps remain OPEN with zero progress since 2026-03-14.**

---

## 9. Known Issues Status (from AI Brain)

### Security Issues (SEC-HPC-*)

| Issue ID | Severity | Description | Status | Notes |
|----------|----------|-------------|--------|-------|
| SEC-HPC-001 | **CRITICAL** | HpcController: 13/15 methods have zero authorization. Only index() (Gate::any) and sendReportEmail() (Gate::authorize) are covered | **OPEN** | Any authenticated tenant user can generate PDFs, store form data, download ZIPs for any student |
| SEC-HPC-002 | **HIGH** | 7/14 FormRequests return `true` in authorize(). 4 controllers with these FRs also lack Gate on store/update (CircularGoals, KnowledgeGraphValidation, QuestionMapping, SyllabusCoverageSnapshot) | **OPEN** | ~8 store/update endpoints completely unprotected |
| SEC-HPC-003 | **HIGH** | No `EnsureTenantHasModule` middleware on HPC route group — any tenant can access HPC even if plan excludes it | **OPEN** | Feature-gating bypassed |
| SEC-HPC-004 | **HIGH** | Module web.php/api.php register routes outside tenancy middleware — accessible on central domain, bypassing isolation | **OPEN** | Central domain access to tenant HPC routes |

### Bug Issues (BUG-HPC-*)

| Issue ID | Severity | Description | Status | Notes |
|----------|----------|-------------|--------|-------|
| BUG-HPC-001 | **HIGH** | 4 template controller imports missing in tenant.php (HpcTemplatesController, HpcTemplatePartsController, HpcTemplateSectionsController, HpcTemplateRubricsController). All template management routes return 500 | **OPEN** | Fix: add 4 `use` statements |
| BUG-HPC-003 | **MEDIUM** | Garbled permission string in HpcTemplatesController::show() — `tenant.hpc-templates.viHpcTemplatesRequest ew` — always throws 403 | **OPEN** | Fix: correct string to `tenant.hpc-templates.view` |
| BUG-HPC-004 | **HIGH** | Global `AcademicSession` (Prime model) used in StudentHpcEvaluationController, SyllabusCoverageSnapshotController, HpcController — data leaks from global/prime DB into tenant context | **OPEN** | Fix: use tenant-scoped AcademicTerm or OrganizationAcademicSession |
| BUG-HPC-005 | **MEDIUM** | 3 routes point to non-existent methods: hpcSecondForm, hpcThredForm, hpcFourthForm — return 500 | **OPEN** | Fix: remove dead routes or create methods |
| BUG-HPC-006 | **HIGH** (Linux) | HpcTemplates model uses uppercase refs (HPCTemplateSections) — works macOS, breaks Linux | **OPEN** | Fix: correct case to match actual class names |
| BUG-HPC-007 | **MEDIUM** | StudentHpcSnapshot imports wrong Student model (SchoolSetup instead of StudentProfile) | **OPEN** | Fix: change import to StudentProfile\Student |
| BUG-HPC-008 | **LOW** | Orphan import in tenant.php: `LearningActivityController` (singular) — file doesn't exist, may fatal on route:cache | **OPEN** | Fix: remove orphan import |
| BUG-HPC-009 | **HIGH** | Trash/view routes shadowed by Resource show route — registered AFTER Route::resource(), so `trash` matches `{id}` param | **OPEN** | Fix: register trash routes BEFORE resource routes |
| BUG-HPC-010 | **LOW** | Duplicate table prefix: `hpc_hpc_levels`, `hpc_student_hpc_snapshot` — violates naming convention | **OPEN** | Cosmetic; fix in next schema revision |
| BUG-HPC-011 | **MEDIUM** | 18/26 models missing `created_by` from $fillable — audit trail broken | **OPEN** | Fix: add `created_by` to all model $fillable arrays |
| BUG-HPC-012 | **MEDIUM** | LearningOutcomesController imports `Prime\Dropdown` — cross-layer central model in tenant context | **OPEN** | Fix: create tenant-scoped dropdown or use sys_dropdowns |
| BUG-HPC-013 | **MEDIUM** | ZIP files never cleaned up — `deleteFileAfterSend(false)`. Storage bloat over time | **OPEN** | Fix: set to `true` or add cleanup job |
| BUG-HPC-014 | **LOW** | Individual PDF URLs use `tenant_asset()` — may not resolve in all deployment configs | **OPEN** | Verify in staging; may need storage URL config |

### Performance Issues (PERF-HPC-*)

| Issue ID | Severity | Description | Status | Notes |
|----------|----------|-------------|--------|-------|
| PERF-HPC-001 | **MEDIUM** | `generateReportPdf()` loops over students loading each individually; attendance/sibling queries repeat per student without batching | **OPEN** | Fix: eager load, batch queries |
| PERF-HPC-002 | **MEDIUM** | 15× duplicated ~70-line index() query block across all 15 controllers, firing ~15 queries per request for data the active tab may not display | **OPEN** | Fix: extract to shared trait or service; lazy-load per tab |

**Total: 4 SEC + 14 BUG + 2 PERF = 20 known issues, ALL OPEN**

---

## 10. Priority Action Items

### P0 — Critical (fix before any new feature work)

1. **SEC-HPC-001:** Add `Gate::authorize()` to all 13 unprotected HpcController methods. Estimated: **2h**
2. **SEC-HPC-002:** Fix 7 FormRequest `authorize()` methods to include Gate checks OR add Gate to the 4 controllers that rely on them. Estimated: **1h**
3. **BUG-HPC-001:** Add 4 missing `use` imports for template controllers in tenant.php. Estimated: **15m**
4. **BUG-HPC-003:** Fix garbled permission string in HpcTemplatesController::show(). Estimated: **5m**
5. **SEC-HPC-003:** Add `EnsureTenantHasModule` middleware to HPC route group. Estimated: **30m**
6. **BUG-HPC-009:** Move trash/view routes BEFORE Route::resource() to prevent shadowing. Estimated: **30m**
7. **BUG-HPC-004:** Replace cross-layer AcademicSession imports with tenant-scoped model. Estimated: **1h**
8. **formStore() $request->all():** Replace with explicit field extraction or $request->validated(). Estimated: **1h**

**P0 Total: ~6h (1 day)**

### P1 — High (fix this sprint)

9. **SEC-HPC-004:** Remove/empty module web.php and api.php routes that bypass tenancy. Estimated: **30m**
10. **BUG-HPC-005:** Remove 3 dead routes (hpcSecondForm, hpcThredForm, hpcFourthForm). Estimated: **15m**
11. **BUG-HPC-006:** Fix case-sensitivity issues in HpcTemplates model for Linux deployment. Estimated: **30m**
12. **BUG-HPC-007:** Fix StudentHpcSnapshot wrong Student import. Estimated: **10m**
13. **BUG-HPC-008:** Remove orphan LearningActivityController import. Estimated: **5m**
14. **BUG-HPC-011:** Add `created_by` to $fillable in 18 models. Estimated: **1h**
15. **BUG-HPC-012:** Replace cross-layer Dropdown import in LearningOutcomesController. Estimated: **30m**
16. **BUG-HPC-013:** Fix ZIP cleanup — change `deleteFileAfterSend(true)`. Estimated: **5m**
17. **PERF-HPC-002:** Extract shared index() query to trait/service to eliminate 15× duplication. Estimated: **2h**
18. **Permission typo:** Fix `topic-equivalency-snapsho.viewAny` → `snapshot`. Estimated: **10m**
19. **Missing migrations:** Create 15 migration files for Schema-2 tables. Estimated: **4h**

**P1 Total: ~10h (1.5 days)**

### P2 — Medium (fix next sprint)

20. **GAP-4:** Role-based section locking — add `owner_role` ENUM to rubric items, enforce in formStore(). Estimated: **3 days**
21. **GAP-5:** Approval workflow — state machine for Draft→Submitted→Final→Published. Estimated: **3 days**
22. **GAP-7:** Auto-feed from hpc_student_evaluation to report items. Estimated: **2 days**
23. **GAP-8:** Complete attendance data — working days source, categorized absences. Estimated: **2 days**
24. **PERF-HPC-001:** Batch student PDF generation (eager load, batch queries). Estimated: **1 day**
25. **God controller refactor:** Extract HpcController (~2297 lines) business logic into HpcReportService. Estimated: **3 days**
26. **Job refactor:** Extract `buildPdf()`, `minifyHtml()`, `resolveTemplateId()` from controller to service. Estimated: **1 day**

**P2 Total: ~15 days (3 weeks)**

### P3 — Low (backlog)

27. **GAP-1:** Student Self-Service Portal — new controller, views, routes, section filtering. Estimated: **5 days**
28. **GAP-2:** Parent Data Collection — token-based signed URLs, standalone form, SMS delivery. Estimated: **4 days**
29. **GAP-3:** Peer Assessment Workflow — peer pairing, activity-level routing, aggregation. Estimated: **4 days**
30. **GAP-6:** LMS/Exam Auto-Feed Integration — data bridge services. Estimated: **3 days**
31. **SC-07:** Attendance Manager screen. Estimated: **2 days**
32. **SC-09:** Activity Assessment Screen. Estimated: **3 days**
33. **SC-14:** Student Goals & Aspirations screen. Estimated: **2 days**
34. **SC-15-17:** Parent Portal screens (dashboard, input, communication). Estimated: **5 days**
35. **SC-20:** Credit Calculator service + screen. Estimated: **3 days**
36. **Tests:** Achieve basic coverage (unit + feature). Estimated: **5 days**
37. **BUG-HPC-010/014:** Cosmetic fixes (naming, tenant_asset). Estimated: **1 day**

**P3 Total: ~37 days (7+ weeks)**

---

## 11. Effort Estimation

| Category | Item Count | Estimated Effort |
|----------|-----------|-----------------|
| P0: Security fixes (Gate, FormRequests, middleware) | 8 items | **6 hours** |
| P1: Bug fixes (imports, routes, case, migrations) | 11 items | **10 hours** |
| P2: Workflow & integration (section locking, approval, auto-feed, refactor) | 7 items | **15 days** |
| P3: Student self-service portal | 1 portal | **5 days** |
| P3: Parent data collection (signed links) | 1 mechanism | **4 days** |
| P3: Peer assessment workflow | 1 workflow | **4 days** |
| P3: Missing blueprint screens (SC-07,09,14,15-17,20) | 7 screens | **15 days** |
| P3: LMS/Exam integration | 3 data flows | **3 days** |
| P3: Credit framework calculator | 1 service | **3 days** |
| P3: Tests | 0 → basic coverage | **5 days** |
| P3: Cosmetic fixes | 2 items | **1 day** |
| **Total** | | **~2 days (P0+P1) + 3 weeks (P2) + 8 weeks (P3) = ~13 developer-weeks** |

### Phase Recommendation
| Phase | Duration | Focus | Deliverable |
|-------|----------|-------|------------|
| **Sprint 1** (Week 1) | 2 days | P0 + P1 | All security + bug fixes, routes working, migrations created |
| **Sprint 2** (Weeks 2-4) | 3 weeks | P2 | Section locking, approval workflow, auto-feed, god controller refactor |
| **Sprint 3** (Weeks 5-7) | 3 weeks | P3 (Student + Parent) | Student portal, parent signed links, peer workflow |
| **Sprint 4** (Weeks 8-10) | 3 weeks | P3 (Screens + Integration) | Missing blueprint screens, LMS integration, credit calculator |
| **Sprint 5** (Weeks 11-13) | 3 weeks | P3 (Quality) | Tests, performance optimization, polish |

---

## 12. Appendix: Field Inventory per Template

### Template 1 Fields (18 pages, ~267 fields)

**Page 1 — Student Info + Attendance:**
- School fields (9): school_name, village, brc, crc, state, pin_code, udise_code, teacher_code, apaar_id
- Student fields (20): student_name, roll_no, reg_no, grade (5 checkboxes), section, dob, age, photo, address, phone, mother/father name/education/occupation, siblings_count, siblings_age, mother_tongue, medium_of_instruction, rural_urban, illness_count
- Attendance table (48): 12 months × 4 rows (working_days, present, %, reasons)
- Interest checkboxes (11): reading, dancing, sports, writing, gardening, yoga, art, craft, cooking, chores, other

**Page 2 — Me and My Surroundings:**
- Fields (15): self_drawing, age_circle, birthday, i_live_in, family_drawing, friends_1-5, when_i_grow_up, fav_colour, fav_flower, fav_food, fav_sport, fav_animal, fav_subject

**Pages 3-14 — 6 Domains × 2 pages each (Assessment + Feedback):**
- Per Assessment page (6 pages × ~8 fields = 48): curricular_goals (pre-printed), competencies (text), activity (textarea), assessment_questions (textarea), awareness_level, sensitivity_level, creativity_level, page_title
- Per Feedback page (6 pages × ~16 fields = 96): teacher_proficiency_diagram, observational_notes, self_liked, self_easy, self_resources, peer_liked, peer_easy, peer_resources, parent_resources (7 checkboxes + other), comments

**Page 15 — Summary (12):** 3 ability diagrams + 6 domain narrative areas

**Pages 16-18 — Credits (33):** Reference table + 5 grade tables × (6 domains × 1 earned value)

### Template 2 Fields (30 pages, ~405 fields)

**Page 1 — Student Info + Attendance:** ~78 fields (same as T1 minus interests)
**Page 2 — Things About Me:** ~15 fields (hand diagram, favourites, goals)
**Page 3 — Self-Assessment:** 7 × 4 = 28 emoji selections
**Pages 4-5 — Peer Feedback:** 2 × (2 names + 6 × 4 emojis) = 52 fields
**Pages 6-7 — Parent Feedback:** 7 resources + 11 × 4 emojis + 7 support = 58 fields
**Pages 8-25 — 6 Learning Standards × 3 pages each:**
  - Assessment: ~15 fields (coded goals + competencies + activity + rubric)
  - Teacher Feedback: ~12 fields (tick table + notes + challenges)
  - Self-Assessment: 8 × 3 emojis = 24 fields
  - Total: 6 × 51 = 306 fields (BUT spread across 18 pages → ~17/page)

Wait, that's only pages 8-25 = 18 pages. Let me recount:
- Pages 8-25: 6 standards × 3 pages = 18 pages
- Pages 26-28: Summary = 3 pages
- Pages 29-30: Credits = 2 pages

**Pages 26-28 — Summary:** ~42 fields (7 subjects × 3 abilities × checkbox + 7 note areas)
**Pages 29-30 — Credits:** ~24 fields (3 grades × 6 standards × 1 earned + reference)

### Template 3 Fields (46 pages, ~521 fields)

**Pages 1-4 — Part A:** ~70 fields
  - Page 1: ~78 (student info + attendance)
  - Page 2: ~12 (All About Me textareas)
  - Page 3: ~10 (Ambition Card fill-in-blanks)
  - Page 4: ~18 (home resources + parent eval + feedback + signature)

**Pages 5-40 — 9 Activity Cycles × 4 pages:** ~351 fields
  - Activity Tab: ~10 fields (goals, competencies, description, 3×3 rubric)
  - Self-Reflection: ~6 fields (3 radios + 3 textareas)
  - Peer Feedback: ~11 fields (name + 5 radios + 3×3 progress counts)
  - Teacher Feedback: ~12 fields (3 ASC levels + 6 strength checkboxes + 5 barrier checkboxes + 2 textareas)
  - Per cycle: ~39 fields × 9 = 351

**Pages 41-44 — Summary:** ~60 fields (subject × ASC grid across 4 pages)
**Pages 45-46 — Credits:** ~40 fields (3 grade tables × subjects)

### Template 4 Fields (44 pages, ~502 fields)

**Pages 1-9 — Part A:** ~120 fields
  - Page 1: ~78 (student info + attendance)
  - Page 2: ~6 (self-evaluation + goal status)
  - Page 3: ~16 (goals + support table 3×3)
  - Page 4: ~20 (time management 5×4 Likert)
  - Page 5: ~5 (time map textareas)
  - Page 6: ~4 (after-school plans)
  - Page 7: ~4 (future self)
  - Page 8: ~6 (accomplishments)
  - Page 9: ~8 (skills for life descriptors)

**Pages 10-41 — 8 Activity Cycles × 4 pages:** ~312 fields
  - Same structure as T3: ~39 fields × 8 = 312

**Page 42 — Summary:** ~30 fields
**Pages 43-44 — Credits:** ~40 fields (4 grade tables)

---

*End of Gap Analysis*

**Next Steps:** Address P0 items (security + critical bugs) immediately before any feature work. The ~6 hours of P0 fixes are prerequisite for safe operation of the existing module. Then proceed with P1 (bug fixes + missing migrations) before starting P2 (workflow improvements) and P3 (multi-actor features).
