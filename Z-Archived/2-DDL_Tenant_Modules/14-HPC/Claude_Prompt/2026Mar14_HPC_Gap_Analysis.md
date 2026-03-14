# HPC Module — Gap Analysis Report
**Date:** 2026-03-14
**Module:** Hpc (Holistic Progress Card)
**Branch:** Shailesh_HPC_14_03_2026
**Auditor:** Claude Opus 4.6

---

## 1. Executive Summary

The HPC module generates report cards for K-12 students aligned with India's NEP 2020 framework. It currently operates as a **single-actor system** where the **class teacher enters all data** — including sections conceptually owned by students (self-reflection), parents (home observations), and peers (peer assessment). This creates a bottleneck where one teacher must fill 44 pages per student per term.

**Key Finding:** The database schema, template structure, and save/retrieve pipeline are solid. The gap is in **data collection workflows** — there is no mechanism for students, parents, or peers to directly contribute their portions of the report card.

---

## 2. Database Schema Summary (17 tables)

### Template Definition Layer (7 tables — complete)
| Table | Purpose | Status |
|-------|---------|--------|
| `hpc_templates` | Master template (1 per grade range) | OK |
| `hpc_template_parts` | Pages within template (up to 44) | OK |
| `hpc_template_parts_items` | Page-level items | OK |
| `hpc_template_sections` | Sections within pages | OK |
| `hpc_template_section_items` | Section-level items (text/image/table) | OK |
| `hpc_template_section_table` | Table cell definitions | OK |
| `hpc_template_rubrics` | Evaluation rubric groups | OK |
| `hpc_template_rubric_items` | Individual rubric fields (7 input types) | OK |

### Report Storage Layer (3 tables — complete)
| Table | Purpose | Status |
|-------|---------|--------|
| `hpc_reports` | One report per student/session/term | OK — has `status` ENUM (Draft/Final/Published/Archived) |
| `hpc_report_items` | All form field values (in/out columns for input/output) | OK — supports Descriptor, Numeric, Grade, Text, Boolean, Image, Json |
| `hpc_report_table` | Table/grid cell values | OK |

### Data Collection Layer (7 tables — partially used)
| Table | Purpose | Status |
|-------|---------|--------|
| `hpc_circular_goals` | NEP curricular goals per class | OK — CRUD wired |
| `hpc_circular_goal_competency_jnt` | Goal ↔ Competency mapping | OK |
| `hpc_learning_outcomes` | Learning outcomes with Bloom taxonomy | OK — CRUD wired |
| `hpc_outcome_entity_jnt` | Outcome ↔ Subject/Lesson/Topic mapping | OK |
| `hpc_outcome_question_jnt` | Outcome ↔ Question mapping | OK — CRUD wired |
| `hpc_student_evaluation` | Per-student per-subject assessment (Awareness/Sensitivity/Creativity) | OK — CRUD wired but NOT auto-fed into report |
| `hpc_learning_activities` | Learning activities per topic | OK — CRUD wired |

### Analytics Layer (3 tables — minimal use)
| Table | Purpose | Status |
|-------|---------|--------|
| `hpc_knowledge_graph_validation` | Curriculum integrity checks | OK — CRUD wired, not connected to report |
| `hpc_topic_equivalency` | Cross-syllabus topic mapping | OK — CRUD wired, not connected to report |
| `hpc_syllabus_coverage_snapshot` | Coverage percentage tracking | OK — CRUD wired, not connected to report |

### Reference Tables (2 tables — complete)
| Table | Purpose | Status |
|-------|---------|--------|
| `hpc_ability_parameters` | 3 ability parameters (Awareness, Sensitivity, Creativity) | OK |
| `hpc_performance_descriptors` | 3 performance levels (Beginner, Proficient, Advanced) | OK |

---

## 3. Data Provider Analysis — Who Fills What?

### Template 4 (Grades 9-12, 44 pages)

| Pages | Section Type | Intended Provider | Current Provider | Gap? |
|-------|-------------|-------------------|------------------|------|
| 1 | Basic Info + Attendance | **System** (auto) | System | No |
| 2-7 | Self-Evaluation, Goals, Time Management, Future Planning | **Student** | Teacher enters on behalf | **YES** |
| 8-9 | Accomplishments, Life Skills | **Student** | Teacher enters on behalf | **YES** |
| 10 | Online Courses Plan | **Student** | Teacher enters on behalf | **YES** |
| 11-12 | Project Work Planning + Schedule | **Student** | Teacher enters on behalf | **YES** |
| 13-15 | Stage Assessment Matrix | **Teacher** | Teacher | No |
| 16 | Learner + Peer Assessment | **Student + Peer** | Teacher enters on behalf | **YES** |
| 17, 27, 33 | Triple Feedback (Teacher/Learner/Peer) | **Teacher + Student + Peer** | Teacher enters all | **YES** |
| 18, 28 | Post-Project Reflections | **Teacher + Student** | Teacher enters both | **YES** |
| 19-20 | Problem-Based Inquiry | **Student** | Teacher enters on behalf | **YES** |
| 21, 23, 25 | Teacher Assessment (Stages 1-3) | **Teacher** | Teacher | No |
| 22, 24, 26 | Learner Reflection (Stages 1-3) | **Student** | Teacher enters on behalf | **YES** |
| 29-30 | Stage Descriptor Tables | **Teacher** | Teacher | No |
| 31-32 | Classroom Interaction Assessment | **Teacher** | Teacher | No |
| 34 | Learner/Peer Feedback Part D | **Student + Peer** | Teacher enters on behalf | **YES** |
| 35 | Post-Project Reflections (Specific) | **Teacher + Student + Peer** | Teacher enters all | **YES** |
| 36-37 | Awareness/Sensitivity Lists | **Teacher** | Teacher | No |
| 38 | Online Courses Evaluation | **Teacher** | Teacher | No |
| 39 | Activity Tracking | **Teacher** | Teacher | No |
| 40 | Skills Table | **Teacher** | Teacher | No |
| 41 | Framework Reference | **System** (static text) | Static | No |
| 42 | Grade Credits | **Teacher** | Teacher | No |

### Template 1 (Pre-primary)
| Section | Intended Provider | Current Provider | Gap? |
|---------|-------------------|------------------|------|
| Parent Observation | **Parent** | Teacher enters on behalf | **YES** |
| Comments & Remarks | **Parent** | Teacher enters on behalf | **YES** |

### Template 2 (Grades 1-5)
| Section | Intended Provider | Current Provider | Gap? |
|---------|-------------------|------------------|------|
| Home Resources (p6) | **Parent** | Teacher enters on behalf | **YES** |
| Parent Feedback Q1-Q10 (p6-p7) | **Parent** | Teacher enters on behalf | **YES** |
| Support Plan (p7) | **Parent + Teacher** | Teacher enters on behalf | **YES** |

### Template 3 (Grades 6-8)
| Section | Intended Provider | Current Provider | Gap? |
|---------|-------------------|------------------|------|
| Home Resources | **Parent** | Teacher enters on behalf | **YES** |
| Parent Self-Evaluation | **Parent** | Teacher enters on behalf | **YES** |
| Parent Feedback & Suggestions | **Parent** | Teacher enters on behalf | **YES** |

---

## 4. Critical Gaps

### GAP-1: No Student Self-Service Portal for HPC
- **Impact:** For Template 4 alone, ~20 pages require student input. Teachers must interview each student or fill it themselves for 30-40 students per class.
- **Pages affected (Template 4):** 2-12, 16, 19-20, 22, 24, 26, 34
- **Estimated teacher time per student:** 45-60 minutes manually entering student data

### GAP-2: No Parent Data Collection Mechanism
- **Impact:** Templates 1-3 explicitly have parent sections. Teachers must call parents or send paper forms home, then manually transcribe responses.
- **Affected sections:** Parent Observation (T1), Home Resources + Feedback Q1-Q10 (T2), Parent Self-Eval + Feedback (T3)
- **No parent authentication, no shared links, no email-based forms**

### GAP-3: No Peer Assessment Workflow
- **Impact:** Templates 3-4 have peer assessment sections where classmates evaluate each other. Currently entered by teacher.
- **Affected pages (Template 4):** 16, 17, 27, 33, 35
- **No peer-to-peer assignment or collection mechanism**

### GAP-4: No Role-Based Section Locking
- **Impact:** `formStore()` accepts ALL fields from ANY authenticated user. A student could overwrite teacher assessments or vice versa.
- **Current behavior:** Whoever POSTs the form can modify any field in any section
- **Need:** Field-level write permissions based on user role (teacher, student, parent)

### GAP-5: No Approval/Review Workflow
- **Impact:** `hpc_reports.status` has ENUM (Draft/Final/Published/Archived) but there is no workflow enforcement. No principal review step, no notification chain.
- **Current behavior:** Status is just a field — anyone can set it to "Published"

### GAP-6: No Auto-Feed from LMS/Exam Modules
- **Impact:** Teacher assessment pages (13-15, 21, 23, 25, 29-32, 38-40) require subject-wise performance data that likely exists in `lms_exam`, `lms_quiz`, and `lms_homework` tables. Teachers manually re-enter these scores.
- **Missing connections:** LmsExam scores → HPC descriptor auto-mapping, Quiz performance → Competency levels, Homework completion → Activity tracking

### GAP-7: No Auto-Feed from hpc_student_evaluation to hpc_report_items
- **Impact:** The `hpc_student_evaluation` table collects per-subject Awareness/Sensitivity/Creativity ratings via a dedicated CRUD screen. But this data is NOT auto-populated into report pages (29-30, 36-37). Teachers re-enter the same ratings.
- **The evaluation data exists in the DB but the report ignores it.**

### GAP-8: Attendance Data is Partial
- **Impact:** Page 1 shows 12-month attendance breakdown. The current system queries `std_student_attendance` and aggregates by month. This works but:
  - No working_days source for months where school is closed
  - Reasons for absence are text-free, not categorized
  - No integration with Transport module (boarding attendance)

---

## 5. Data Volume Impact

| Template | Students/Class | Pages | Student Pages | Teacher Pages | Parent Pages | Teacher Time/Student |
|----------|---------------|-------|---------------|---------------|-------------|---------------------|
| T1 (Pre-primary) | ~30 | ~5 | 0 | 3 | 2 | ~10 min |
| T2 (Grades 1-5) | ~40 | ~8 | 0 | 5 | 3 | ~15 min |
| T3 (Grades 6-8) | ~40 | ~8 | 2 | 4 | 2 | ~20 min |
| T4 (Grades 9-12) | ~40 | 44 | ~20 | ~22 | 0 | **~60 min** |

**For Template 4:** A class teacher with 40 students spends ~40 hours (5 full workdays) just entering HPC data per term. With 3 terms/year, that's 15 workdays/year on data entry alone.

---

## 6. Existing Infrastructure That Supports Multi-Actor Collection

| Component | Exists? | Notes |
|-----------|---------|-------|
| `hpc_report_items.assessed_by` | YES | FK to sys_users — can track who entered each field |
| `hpc_report_items.assessed_at` | YES | Timestamp for each entry |
| `hpc_reports.status` (Draft/Final/Published/Archived) | YES | Can drive workflow state machine |
| `hpc_template_rubric_items.input_required` | YES | Can mark which fields are mandatory |
| `hpc_template_rubric_items.input_type` (7 types) | YES | All input types already supported |
| Student login (StudentPortal module) | PARTIAL | Module exists at ~25%; has dashboard, complaints, notifications |
| Parent login | NO | No parent authentication in the system at all |
| Peer assignment system | NO | Nothing exists |
| LMS grade APIs | NO | LMS modules have no API endpoints for HPC consumption |
| EnsureTenantHasModule middleware | YES | Exists but NOT applied to HPC routes |

---

## 7. Summary Scores

| Dimension | Score | Notes |
|-----------|-------|-------|
| Template Structure | 95% | 4 templates covering all grades; data-driven rubric system |
| Report Save/Load | 90% | HpcReportService handles all 7 input types; bulk insert with retry |
| PDF Generation | 90% | 4 DomPDF templates; bulk ZIP export; all DomPDF-compatible |
| Teacher Data Entry | 85% | Single-form entry works; missing section locking |
| Student Self-Service | 0% | No student-facing form or portal integration |
| Parent Data Collection | 0% | No parent-facing form, link, or portal |
| Peer Assessment | 0% | No peer-to-peer mechanism |
| LMS Integration | 0% | No auto-feed from exam/quiz/homework |
| Evaluation → Report Auto-Feed | 0% | hpc_student_evaluation data not used in report |
| Approval Workflow | 5% | Status field exists but no enforcement |
| Security/Auth | 15% | HpcController has zero auth; FormRequests mostly return true |
