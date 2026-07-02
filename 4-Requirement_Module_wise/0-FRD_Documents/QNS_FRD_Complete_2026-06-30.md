# QuestionBank — Complete Analysis Pack
**Module Code:** QNS | **Prefix:** `qns_*` | **DB Layer:** tenant_db
**Date:** 2026-06-30 | **Version:** 1.1 | **Author:** pa-business-analyst
**Supersedes:** `QNS_FRD_Complete_2026-06-29.md`
**Sources:** V2 Requirement Doc, V1 Screen Specs (QuestionBank_v2/), live code (Modules/QuestionBank/), tenant migrations, Technical Audit (QuestionBank_Complete_Audit_2026-06-29.md), D31 formula contract (QuestionStatisticsService.php)

> **Version 1.1 changes:** Technical Audit (2026-06-29) surfaced 4 additional P0 findings — duplicate policy registration (QuestionBankPolicy dead), missing permission seeder, reviewApprove() FSM bypass, and statistics migration NOT NULL mismatch. Effective completion revised from ~65% to ~50%. Health score 37/100 (NO-GO). All REQ/BR/RPT/ENH IDs unchanged from v1.0.

---

## Table of Contents

| Section | Artifact |
|---------|---------|
| Section 1 | Functional Requirements Document — FRD (standalone link + summary) |
| Section 2 | Requirements Traceability Matrix (RTM) |
| Section 3 | Business Rules Register + Requirement Conditions Catalog + Validation & Edge-Case Catalog |
| Section 4 | Process Flows + FSM Catalog |
| Section 5 | Data Dictionary (Business View) + Cross-Module Dependency Map |
| Section 6 | NFR Catalog + Risk Register |
| Section 7 | Prioritization (MoSCoW) + Effort Estimation & Sprint Task Breakdown |
| Section 8 | User Stories + Acceptance Criteria + Reporting & KPI Spec |
| Section 9 | Feature Specification (Key Screens) |
| Section 10 | Module Knowledge Reference |

---

# SECTION 1 — FUNCTIONAL REQUIREMENTS DOCUMENT (Reference)

Standalone FRD: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/QNS_FRD_2026-06-30.md`

**FRD Summary (for quick reference):**
- 14 requirements (REQ-QNS-001 through REQ-QNS-014)
- 12 business rules (BR-QNS-001 through BR-QNS-012)
- 5 reports (RPT-QNS-001 through RPT-QNS-005)
- 5 enhancements (ENH-QNS-001 through ENH-QNS-005)
- Priority split: 4 P0 / 7 P1 / 3 P2
- 4 workflows: Question Lifecycle FSM, AI Generation, Excel Import, Statistics Computation

---

# SECTION 2 — REQUIREMENTS TRACEABILITY MATRIX (RTM)

| REQ ID | Feature | Priority | BR Refs | Key Screen(s) | Workflow | Report(s) | Code Status | Gaps |
|--------|---------|----------|---------|--------------|---------|----------|------------|------|
| REQ-QNS-001 | Question Creation & Management | P0 | BR-001, 002, 006, 007, 010 | SCR-QNS-01, 02, 03, 04 | WF-1 | — | Partial (~85%) | Gate missing on index, print, import; policy dead (SEC-QNS-003) |
| REQ-QNS-002 | Question Types | P1 | BR-002 | SCR-QNS-02, 03 | WF-1 | — | Partial | Match type UI incomplete; LATEX rendering not conditional |
| REQ-QNS-003 | Bloom's Taxonomy Tagging | P0 | BR-001 | SCR-QNS-02, 03 | WF-1 | RPT-003 | Implemented | scopeApproved() references wrong column (IMP-QNS-05) |
| REQ-QNS-004 | Version History | P1 | BR-009 | SCR-QNS-09 | WF-1 | — | Partial | Routes not wired to web.php; no version diff view |
| REQ-QNS-005 | Review & Approval Workflow | P0 | BR-003, 008, 011 | SCR-QNS-13 | WF-1 | RPT-004 | Partial | reviewApprove() bypasses APPROVED state; no dedicated controller; no notifications |
| REQ-QNS-006 | Media Management | P1 | — | SCR-QNS-02, 03 | — | — | Partial (~80%) | Wrong policy gate (competency.* instead of question-media.*) |
| REQ-QNS-007 | Tag System | P1 | — | SCR-QNS-08 | — | — | Partial (~90%) | Routes not wired in module web.php |
| REQ-QNS-008 | Multi-Topic Mapping | P2 | BR-012 | SCR-QNS-02 | — | — | Schema only | No weightage sum validation |
| REQ-QNS-009 | Performance Category Mapping | P2 | — | SCR-QNS-02 | — | — | Schema only | No seeder-driven recommendation_type linkage verified |
| REQ-QNS-010 | Question Statistics | P1 | BR-004 | SCR-QNS-10 | WF-4 | RPT-002 | Partial | Service implemented; migration NOT NULL mismatch blocks DB write; routes not wired; no scheduled job |
| REQ-QNS-011 | Usage Logging | P1 | BR-005 | SCR-QNS-11 | — | — | Partial | Model exists; no view; consuming modules not confirmed writing log |
| REQ-QNS-012 | Bulk Import via Excel | P1 | — | SCR-QNS-12 | WF-3 | — | Partial | Auth gap on validateFile and startImport; LOWER() duplicate check not indexed |
| REQ-QNS-013 | Printable Question Paper | P2 | — | SCR-QNS-05 | — | — | Implemented | Gate missing on print action |
| REQ-QNS-014 | AI Question Generation | P0 | BR-008 | SCR-QNS-06, 07 | WF-2 | RPT-005 | Stub only (~15%) | Zero auth on all methods; demo data returned; no AIQuestionService; no rate limit; no FormRequest |

**RTM Summary:** 4 of 14 REQs are fully or substantially implemented (REQ-003, 007, 009 schema, 013). 8 are partial with material gaps. 2 are stub only (REQ-005 workflow, REQ-014 AI generation). Zero REQs have passing test coverage.

---

# SECTION 3 — BUSINESS RULES REGISTER + CONDITIONS CATALOG + VALIDATION CATALOG

## 3.1 Business Rules Register (full)

| BR ID | Rule Statement (business language) | Type | Trigger | Enforcement Point | Priority |
|-------|-----------------------------------|------|---------|-------------------|----------|
| BR-QNS-001 | Before a question can be submitted for review, all four taxonomy fields must be filled in: Bloom's Taxonomy Level, Cognitive Skill, Question Type Specificity, and Complexity Level. A question missing any of these cannot leave Draft status. | Validation | Submit for review | Question creation form; review submission handler | P0 |
| BR-QNS-002 | MCQ questions (Single Correct or Multi Correct) must have at least one answer option marked as correct. MCQ Single questions may have exactly one correct option. Attempting to submit otherwise is blocked with a specific error. | Validation | Question save | Question creation and edit forms | P0 |
| BR-QNS-003 | Only questions with a status of Approved or Published are visible in the question picker used by Quiz, Quest, and Exam builders. Draft, In Review, Rejected, and Archived questions are completely excluded. | Permission | Assessment question picker query | Question list queries in consuming modules; list controller scope filter | P0 |
| BR-QNS-004 | The Difficulty Index is computed as: (count of correct responses ÷ total attempt count) × 100. The Discrimination Index is: (correct-answer rate in the top 27% of students by score) minus (correct-answer rate in the bottom 27%) × 100; negative values flag a poorly constructed or mis-keyed question. The Guessing Factor applies to MCQ only: if at least 30 attempts exist, use the empirical bottom-group correct rate × 100; otherwise use 100 ÷ number of active options. Any metric is null if insufficient attempts exist (fewer than 4 per group). | Calculation | Nightly statistics job; on-demand trigger | QuestionStatisticsService |P1 |
| BR-QNS-005 | When an assessment is set to use only previously unused questions, the question picker cross-checks the usage log for the specific assessment type (Quiz, Quest, Exam, or Offline Exam) and excludes any question already used in that context. | Workflow | Assessment builder — unused filter applied | Question picker query in consuming modules | P1 |
| BR-QNS-006 | Availability scope determines which teachers see and may use a question. Global means all teachers on the platform. School Only means teachers within this school. Class Only means teachers who teach this class. Section Only means teachers in the named section. Student Group Only means teachers for the named group. One Student Only means teachers of that student. All question list and picker queries must apply this filter based on the requesting user's context. | Permission | Any question list query; any picker query | Question list controller; consuming module pickers | P0 |
| BR-QNS-007 | Questions owned by the Platform (Content Owner = Platform Content) cannot be edited or deleted by school teachers. A school teacher may only clone such a question to create their own editable copy, which is then school-owned. | Permission | Edit and Delete actions | Question policy; question controller actions | P1 |
| BR-QNS-008 | Questions generated by the AI system are marked with a special flag at creation. These questions must pass through the full In Review stage before being used in any assessment. No role — not even a School Admin — may bypass the In Review stage for AI-generated questions. | Workflow | Status change actions on AI-flagged questions | Review workflow; status change controller; question policy | P0 |
| BR-QNS-009 | A version snapshot of the question's full prior state (question text, options, marks, taxonomy) must be saved before any edit that changes question content, option text, correct-answer status, marks, negative marks, or question type. Pure status changes do not trigger a snapshot. | Workflow | Question update (edit path) | Question update handler; snapshot service | P1 |
| BR-QNS-010 | Negative marks must be greater than or equal to zero and strictly less than the question's marks value. Negative marks equal to or exceeding the marks value are rejected with a validation error. | Validation | Question save | Question creation and edit form request | P1 |
| BR-QNS-011 | When a reviewer rejects a question, a written explanation of the rejection reason is mandatory. Rejecting without providing a comment is blocked with "A comment is required when rejecting a question." | Validation | Reject action | Review controller; review form request | P0 |
| BR-QNS-012 | When a question is linked to multiple topics, the sum of all topic weightage values should equal 100 (expressed as a percentage). This is enforced as a soft warning shown on save — the teacher is alerted and can continue, but the discrepancy is recorded. | Validation | Question save with multi-topic mapping | Question update handler | P2 |

## 3.2 Requirement Conditions Catalog

*(Saved separately to: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/5-Requirement_Conditions/QuestionBank_Conditions.md`)*

| Condition ID | Entity/Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|-------------|---------------------|------|---------|----------------------|
| BR-QNS-001-C01 | Bloom's Taxonomy Level | Must be selected before review submission | Validation | Submit for review | Error: "Bloom's Taxonomy Level is required." Question stays in Draft. |
| BR-QNS-001-C02 | Cognitive Skill | Must be selected before review submission | Validation | Submit for review | Error shown; question stays in Draft. |
| BR-QNS-001-C03 | Question Type Specificity | Must be selected before review submission | Validation | Submit for review | Error shown; question stays in Draft. |
| BR-QNS-001-C04 | Complexity Level | Must be selected before review submission | Validation | Submit for review | Error shown; question stays in Draft. |
| BR-QNS-002-C01 | MCQ — correct option count | At least one option must be marked correct | Validation | Question save | Error: "At least one option must be marked as correct." |
| BR-QNS-002-C02 | MCQ Single — correct count | Exactly one option may be correct | Validation | Question save | System auto-deselects previous correct when a new one is selected. |
| BR-QNS-003-C01 | Question status — assessment visibility | Only Approved or Published questions visible in assessment builders | Permission | Assessment question picker query | Row excluded silently from picker results. |
| BR-QNS-005-C01 | Usage log — unused filter | Question must not have a usage log entry for the same context type | Workflow | Picker query with unused filter | Row excluded from picker results. |
| BR-QNS-006-C01 | Availability scope — Class Only | Requesting teacher must teach the question's class | Permission | Question list query | Row excluded from list. |
| BR-QNS-006-C02 | Availability scope — Section Only | Requesting teacher must teach the question's named section | Permission | Question list query | Row excluded from list. |
| BR-QNS-006-C03 | Availability scope — Student Only | Requesting teacher must teach the named student | Permission | Question list query | Row excluded from list. |
| BR-QNS-007-C01 | Platform Content — edit protection | School teacher cannot edit or delete Platform Content questions | Permission | Edit / Delete action | Error: "This question is owned by the platform and cannot be edited. Use Clone to create your own copy." |
| BR-QNS-008-C01 | AI-generated — review bypass | AI-generated question cannot skip In Review regardless of user role | Workflow | Status change to Approved/Published on AI-generated question | Transition blocked: "AI-generated questions must be reviewed before approval." |
| BR-QNS-009-C01 | Version trigger — content fields | Edit changes question_content, content_format, marks, negative_marks, question_type_id, or any option | Workflow | Question save (edit) | Snapshot created before save; version counter incremented. |
| BR-QNS-009-C02 | Version trigger — status change only | Edit only changes status; no content fields changed | Workflow | Status change action | No snapshot created. |
| BR-QNS-010-C01 | Negative marks range | 0 ≤ negative_marks < marks | Validation | Question save | Error: "Negative marks must be less than the question's marks value." |
| BR-QNS-011-C01 | Rejection comment | review_comment must be non-empty on reject action | Validation | Reject action | Error: "A comment is required when rejecting a question." |
| BR-QNS-012-C01 | Topic weightage sum | Sum of all weightages for a question should equal 100 | Validation (soft) | Question save with multi-topic | Warning: "Topic weightages currently sum to [X]. Consider adjusting to total 100." |

## 3.3 Validation & Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty/Null | Concurrency Case | Expected Behaviour |
|-------------|--------------|----------------|---------|------------|-----------------|-------------------|
| Question title | "Photosynthesis — Light Reactions" (200 chars) | Blank | 255 chars (VARCHAR limit) | Blocked with "Title is required" | — | Error if empty or > 255 chars |
| MCQ options count | 3 options, 1 correct | 0 options for MCQ | 2 options minimum / 5 maximum | Empty options array | — | Error: "MCQ questions must have between 2 and 5 options" |
| Marks value | 1.50 | 0.00 or negative | 999.99 (DECIMAL 5,2 max) | Not null (default 1.00) | Two teachers updating marks simultaneously | Last-writer-wins; no optimistic lock currently |
| Negative marks | 0.50 when marks = 2.00 | 2.00 when marks = 2.00 (equal) | negative_marks = marks − 0.01 | null → treated as 0 | — | Error if negative_marks >= marks |
| Bloom Level (taxonomy) | Bloom Level 3 (Apply) | Not selected | 1–6 (6 valid values) | Blocked on review submission | — | Warning in Draft; hard error on submit for review |
| Status transition — In Review → Published | Admin approves then publishes | Direct change from In Review to Published | — | — | Two reviewers both click Approve simultaneously | First action succeeds; second gets "already reviewed" error |
| Status transition — Archived → Published | Archived → Draft → In Review → Approved → Published | Direct Archived → Published | — | — | — | Transition blocked with explanation |
| Question used by student — Edit | N/A (never allowed after student attempt) | Edit attempted after student has answered | 0 attempts = allowed; 1 attempt = blocked | — | — | Error: "This question cannot be edited because it has been answered by students. Clone to create a variant." |
| Clone — identical to original | Clone with any change to content | Identical clone (no changes) | — | — | — | Error: "The cloned question must differ from the original." |
| Textbook page reference | Page 47 (book has 200 pages) | Page 350 (book has 200 pages) | page = total pages (valid); page = total_pages + 1 (invalid) | Null (optional field) | — | Error: "Page reference cannot exceed the book's total pages." |
| AI generation — count | 5 questions | 21 questions | 20 (maximum) | 0 (invalid) | — | Error if count > 20 or < 1 |
| AI generation — rate limit | 9 requests in 60 seconds | 11th request in 60 seconds | 10th request (allowed; 11th blocked) | — | — | HTTP 429 with "Too many requests" message |
| Import file size | 200 rows (within limit) | 600 rows | 500 rows (maximum) | Empty file | — | Error: "Import file cannot exceed 500 questions." |
| Statistics — Discrimination Index | Question with 40 students: top 27% (11) have 80% correct, bottom 27% (11) have 20% correct → index = 60 | No result (null if < 4 per group) | 4 attempts per group (minimum for computation) | No attempts → null | Two jobs computing same question simultaneously | Wrapped in transaction with consistent snapshot read; second job overwrites first (both produce same result) |

---

# SECTION 4 — PROCESS FLOWS + FSM CATALOG

## 4.1 FSM — Question Lifecycle

**Entity:** Question (qns_questions_bank.status)
**Driver:** ENUM column on question record

| From State | Event / Action | Guard / Condition | To State | Side-Effects |
|------------|---------------|------------------|----------|-------------|
| (New) | Teacher saves | All required fields valid | DRAFT | Question created; current_version = 1 |
| DRAFT | Teacher submits for review | Taxonomy complete (BR-001) | IN_REVIEW | Reviewer notified via Notification module |
| DRAFT | Admin approves directly | No guard (admin shortcut) | APPROVED | review_log entry created |
| IN_REVIEW | Reviewer approves | — | APPROVED | review_log entry (comment optional); author notified |
| IN_REVIEW | Reviewer rejects | review_comment non-empty (BR-011) | REJECTED | review_log entry (comment required); author notified with comment |
| IN_REVIEW | Teacher cancels review | Teacher is the original author | DRAFT | — |
| REJECTED | Teacher edits content | No student attempts | DRAFT (auto on edit) | Version snapshot created |
| DRAFT | Teacher re-submits | Taxonomy complete | IN_REVIEW | New review cycle |
| APPROVED | Admin publishes | — | PUBLISHED | Question visible in all eligible assessment pickers |
| APPROVED | Admin archives | — | ARCHIVED | Question removed from all pickers |
| PUBLISHED | Admin archives | — | ARCHIVED | Question removed from all pickers; existing assessments retain their copies |
| ARCHIVED | Admin returns to draft | No student attempts | DRAFT | Fresh workflow begins |

**Terminal states:** ARCHIVED (standard retirement). Questions with student attempts cannot be moved to any state that would allow content changes.

**Illegal transitions (blocked by system):**
- IN_REVIEW → PUBLISHED (must pass through APPROVED)
- ARCHIVED → PUBLISHED (must return to DRAFT first)
- PUBLISHED → DRAFT if any student has answered the question
- AI-generated: DRAFT → APPROVED (must pass through IN_REVIEW)
- AI-generated: DRAFT → PUBLISHED (same; must pass through IN_REVIEW and APPROVED)

**Status master:** `status` ENUM on `qns_questions_bank` — values: DRAFT, IN_REVIEW, APPROVED, REJECTED, PUBLISHED, ARCHIVED.

---

## 4.2 FSM — Review Log

**Entity:** Review decision (qns_question_review_log.review_status_id)

| From State | Event | Guard | To State | Side-Effect |
|------------|-------|-------|----------|------------|
| (Open for review) | Reviewer approves | — | APPROVED | review_log row inserted; question status → APPROVED |
| (Open for review) | Reviewer rejects | review_comment non-empty | REJECTED | review_log row inserted; question status → DRAFT |
| APPROVED / REJECTED | (nothing — log is immutable) | — | (no change) | Cannot be edited or deleted |

---

## 4.3 Process Flow — AI Question Generation (expanded)

```
Teacher opens AI Generator
    |
    | [Gate check: tenant.ai-question-generator.viewAny]
    | [Currently MISSING — P0 SEC-QNS-002]
    v
Form: Provider, Class, Subject, Lesson, Topic, Type, Bloom, Complexity, Count
    |
    | POST /question-bank/ai-generator/generate
    v
[AIQuestionGenerateRequest validation]
    - provider ∈ {openai, gemini}
    - all curriculum fields present
    - 1 ≤ count ≤ 20
    |
    | [Rate limit check: max 10/min/user — Currently MISSING — BUG-QNS-07]
    v
AIQuestionService::generate(provider, params)
    - Loads key: config('services.{provider}.key')   [Currently reads env() directly — BUG]
    - Builds structured prompt incorporating curriculum context
    - Makes HTTP call to provider API
    - Parses JSON response into question DTOs
    |
    | For each generated question:
    v
QuestionBankService::createFromAI(questionDTO)
    - INSERT qns_questions_bank (status=DRAFT, created_by_AI=1)
    - INSERT qns_question_options (if MCQ)
    |
    v
Response to teacher: list of created DRAFT question IDs
    |
    v
Teacher reviews each question on AI Review screen (SCR-QNS-07)
    |
    | [Teacher edits fields, submits each for review]
    v
Normal review workflow (WF-1) — AI-generated gate (BR-QNS-008) enforced
```

---

# SECTION 5 — DATA DICTIONARY + CROSS-MODULE DEPENDENCY MAP

## 5.1 Data Dictionary (Business View)

### Entity: Question

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|----------------|---------|------|---------|----------------|------|
| Internal Title | Teacher's reference name; not shown to students unless the "Show title to students" toggle is on | Short text (255 chars) | Yes | Any text | No |
| Question Content | The question text displayed to students | Rich text | Yes | Plain text, HTML, Markdown, LaTeX, JSON | No |
| Content Format | Controls how the question content renders | Choice | Yes | Plain Text, HTML, Markdown, LaTeX, JSON | No |
| Class | The school class this question belongs to | Lookup (from School Setup) | Yes | Active classes in this school | No |
| Subject | The subject within the chosen class | Lookup | Yes | Subjects for the selected class | No |
| Lesson | The syllabus lesson the question tests | Lookup | Yes | Lessons for the selected subject | No |
| Primary Topic | The specific topic within the lesson | Lookup | Yes | Topics for the selected lesson | No |
| Competency | The specific learning outcome the question targets | Lookup | Yes | Competencies linked to the topic | No |
| Bloom's Taxonomy Level | Cognitive level of the question (1=Remember through 6=Create) | Lookup | Yes | 1–6 | No |
| Cognitive Skill | Mental process required (Recall, Application, Critical Thinking, etc.) | Lookup | Yes | Values from Syllabus module | No |
| Complexity Level | Teacher's difficulty rating for the question | Lookup | Yes | Easy, Medium, Hard, Very Hard | No |
| Question Type Specificity | Sub-classification within the question type | Lookup | Yes | Values from Syllabus module | No |
| Question Type | The format of the question | Lookup | Yes | MCQ Single, MCQ Multi, True/False, Short Answer, Essay, Fill in Blank, Match the Columns | No |
| Marks | Points awarded for a correct answer | Decimal | Yes | > 0.00 (default 1.00) | No |
| Negative Marks | Points deducted for an incorrect answer | Decimal | No | 0.00 ≤ value < Marks (default 0.00) | No |
| Expected Answer Time | Estimated seconds a student needs to answer | Whole number | No | Any positive number | No |
| Content Owner | Who owns and controls editing rights | Choice | Yes | Platform Content, School Content | No |
| School-Specific | Restricts the question to the creating school only | Toggle | No | Yes/No | No |
| Availability Scope | Who can see and use this question | Choice | Yes | Global, This School Only, This Class Only, This Section Only, This Student Group Only, One Specific Student | No |
| Usable in Quiz | Whether this question can appear in quizzes | Toggle | No | Yes/No (default Yes for Quiz) | No |
| Usable in Quest | Whether this question can appear in quests | Toggle | No | Yes/No | No |
| Usable in Exam | Whether this question can appear in online exams | Toggle | No | Yes/No | No |
| Usable in Offline Exam | Whether this question can appear in printed offline papers | Toggle | No | Yes/No | No |
| Textbook Reference | The textbook this question is drawn from | Lookup | No | Books linked to the subject | No |
| Page Number | The specific page in the textbook | Number | No | 1 to book's total pages | No |
| External Reference | A code linking to an external question bank or NCERT | Short text | No | Any alphanumeric code | No |
| AI-Generated | Whether this question was created by an AI provider | Toggle (read-only) | System-set | Yes/No | No |
| Status | Current lifecycle stage of the question | Computed/Workflow | System-managed | Draft, In Review, Approved, Rejected, Published, Archived | No |
| Version Number | How many times this question's content has been changed | Number (read-only) | System-set | Starting at 1, incrementing on each content edit | No |
| Teacher Explanation | Explanation shown to students after they answer | Rich text | No | Any text | No |

### Entity: Answer Option

| Business Field | Meaning | Type | Required | Notes | PII? |
|----------------|---------|------|---------|-------|------|
| Option Text | The text of this answer choice | Rich text | Yes (for MCQ/Match) | — | No |
| Display Order | The position of this option in the list | Number | No | Default ordering | No |
| Correct Answer | Whether this option is the right answer | Toggle | Yes (at least one) | Multiple for MCQ Multi | No |
| Option Explanation | Why this option is correct or incorrect | Rich text | No | Shown after answering | No |

### Entity: Question Tag

| Business Field | Meaning | Type | Required | PII? |
|----------------|---------|------|---------|------|
| Short Code | A unique abbreviation for the tag (for system lookup) | Short text | Yes | No |
| Display Name | The full tag name visible to teachers | Text | Yes | No |

### Entity: Review Log Entry (immutable)

| Business Field | Meaning | Type | Required | PII? |
|----------------|---------|------|---------|------|
| Reviewer | The teacher who made the review decision | Lookup (staff) | Yes | Internal |
| Decision | Approved or Rejected | Choice | Yes | Internal |
| Comment | The reviewer's written feedback (mandatory for Rejected) | Text | Conditional | Internal |
| Date and Time | When the decision was made | Timestamp | Yes | Internal |

### Entity: Question Statistics (computed)

| Business Field | Meaning | Type | Required | PII? |
|----------------|---------|------|---------|------|
| Difficulty Index | Percentage of students who answered correctly (0–100). Low = hard, High = easy. | Decimal | Computed | No |
| Discrimination Index | Difference between top-group and bottom-group correct rate (−100 to +100). Negative = mis-keyed or poor question. | Decimal | Computed | No |
| Guessing Factor | MCQ only: estimated percentage of correct answers due to random guessing. Null for other types. | Decimal | Computed (MCQ only) | No |
| Shortest Answer Time | Fastest time a student answered this question correctly | Seconds | Computed | No |
| Longest Answer Time | Longest valid time taken (with outliers excluded) | Seconds | Computed | No |
| Average Answer Time | Mean time taken across all valid attempts | Seconds | Computed | No |
| Total Attempts | Count of all evaluated student responses | Whole number | Computed | No |
| Last Computed | When these metrics were last refreshed | Timestamp | System-set | No |

---

## 5.2 Cross-Module Dependency Map

### Inbound (Question Bank reads from)

| Source Module | Data / Entity | Why |
|--------------|--------------|-----|
| Syllabus (slb_*) | Bloom taxonomy, cognitive skill, complexity levels, question types, type specificity, performance categories, lessons, topics, competencies, books, entity groups | All taxonomy tagging; curriculum anchoring FKs; performance category mapping |
| School Setup (sch_*) | Classes, sections, subjects | Curriculum anchoring; availability scope enforcement |
| Student Profile (std_*) | Student records | STUDENT_ONLY availability scoping |
| System Config (sys_*) | User records (creator, reviewer); dropdown values (review status, recommendation type) | Ownership, review workflow, dropdown-driven types |
| Quiz / Quest modules | Student attempt answers | Statistics computation input (answer feed) |
| Exam module | Student attempt answers and results | Statistics computation input (answer feed) |

### Outbound (Question Bank feeds)

| Target Module | Mechanism | What is provided |
|--------------|-----------|-----------------|
| LmsQuiz | for_quiz flag; question picker reads qns_questions_bank | Quiz question sourcing (Approved / Published only) |
| LmsQuests | for_quest flag; question picker reads qns_questions_bank | Quest question sourcing |
| LmsExam | for_exam / for_offline_exam flags; paper builder reads qns_questions_bank | Exam paper question sourcing; offline paper question pool |
| Recommendation (rec_*) | qns_question_performance_category_jnt (recommendation_type: REVISION/PRACTICE/CHALLENGE) | Personalised learning path questions for the LXP engine |
| Scheduler | Nightly job trigger contract | Statistics computation scheduling |
| Notification | Events fired on status changes (question submitted, approved, rejected) | In-app and email notifications to authors and reviewers |

### External Dependencies

| External Service | Purpose | Current Status |
|-----------------|---------|---------------|
| OpenAI (GPT-4o-mini) | AI-assisted question generation | Keys moved to env(); generation still returns demo data stub (P0 gap) |
| Google Gemini (2.0 Flash) | AI-assisted question generation | Same as above |
| maatwebsite/laravel-excel | Excel bulk import and export | Implemented (QuestionImport, QuestionReadOnly classes) |

---

# SECTION 6 — NFR CATALOG + RISK REGISTER

## 6.1 NFR Catalog

| ID | Category | Requirement | Threshold |
|----|----------|-------------|-----------|
| NFR-QNS-001 | Performance | Question list pagination at 100,000 questions with class+subject filter using indexed queries | Response < 2 s at p95 |
| NFR-QNS-002 | Performance | AI generation endpoint — complete or timeout | Hard 30-second timeout with user-friendly message |
| NFR-QNS-003 | Performance | Statistics background job — per question and batch | 1 s/question; full bank batch < 15 minutes |
| NFR-QNS-004 | Performance | Taxonomy filter dropdowns served from cache | Cache hit < 200 ms; TTL 1 hour |
| NFR-QNS-005 | Security | AI provider API keys must never appear in source code or version control | Zero hits in codebase scan for literal key strings |
| NFR-QNS-006 | Security | Module-access guard must be present on all routes | Any request from an unlicensed tenant returns 403 |
| NFR-QNS-007 | Security | Every controller action must enforce a named permission check via a seeded permission | Unauthenticated and unauthorised requests return 403/401 |
| NFR-QNS-008 | Security | Policy registration must produce exactly one effective policy per model | Duplicate Gate::policy() registrations for the same model are a P0 defect |
| NFR-QNS-009 | Security | AI generation endpoint throttled | Maximum 10 requests per user per minute; HTTP 429 on excess |
| NFR-QNS-010 | Security | FormRequest authorize() methods must evaluate a real permission, not return Auth::check() | No hardcoded true or bare auth check in any FormRequest |
| NFR-QNS-011 | Usability | LaTeX questions must render with MathJax in all views | No raw LaTeX markup visible to teachers or students |
| NFR-QNS-012 | Usability | Form data preserved on validation failure | Teacher returned to first error with all prior entries intact |
| NFR-QNS-013 | Usability | Full-text search on question title and content | Search returns results within 2 seconds for up to 100,000 questions |
| NFR-QNS-014 | Scalability | Question bank may grow to 100,000+ questions | Statistics computation must never block HTTP requests |
| NFR-QNS-015 | Data Integrity | UUID binary storage for questions | BIN_TO_UUID / UUID_TO_BIN conversions applied consistently; model cast prevents raw binary leakage |
| NFR-QNS-016 | Compliance | Question import audit trail | All imports logged with importer identity, file name, and timestamp |

## 6.2 Risk Register

| Risk ID | Risk | Category | Likelihood | Impact | Mitigation | Owner | Early Warning |
|---------|------|----------|-----------|--------|-----------|-------|--------------|
| RISK-QNS-001 | Duplicate policy registration (QuestionBankPolicy dead) means all CRUD authorization checks go to the wrong policy — any teacher can approve questions, platform content can be edited by teachers, etc. | Security | Confirmed (P0) | H | Fix ServiceProvider to register QuestionBankPolicy only; remove duplicate | Backend Developer | Any 403 that passes when it should not |
| RISK-QNS-002 | No permission seeder means all teachers get 403 on all Question Bank screens (except super-admin) | Security | Confirmed (P0) | H | Create TenantPermissionSeeder for QNS module; assign to Teacher, Admin, Dept Head roles | Backend Developer | Teachers report they cannot open the Question Bank |
| RISK-QNS-003 | AI generation returns demo data hardcoded in controller — teachers believe AI is working when it is not | Data Quality | Confirmed (P0) | M | Remove getDemoResponse() early return; implement AIQuestionService with real HTTP calls | Backend Developer | Teacher-reported generated questions are always identical |
| RISK-QNS-004 | Statistics migration NOT NULL constraint on nullable columns (discrimination_index, guessing_factor) causes QuestionStatisticsService to fail on DB write for MCQ-only cases and newly-added questions | Data Quality | Confirmed (P0) | H | Add migration to make these columns NULLABLE; no service code change needed (service already handles nulls correctly per D31) | DB Architect | NullConstraintViolation exceptions in scheduler logs |
| RISK-QNS-005 | scopeApproved() references column 'ques_reviewed_status' which does not exist (actual column is 'status') — silently returns zero questions to assessment builders | Data Quality | Confirmed (P0) | H | Fix model scope to reference 'status' column | Backend Developer | Assessment builders show empty question picker |
| RISK-QNS-006 | reviewApprove() workflow sets question directly to PUBLISHED, bypassing the required APPROVED state — AI-generated questions can be deployed to live assessments without completing the review gate | Security / Workflow | Confirmed (P0) | H | Fix review approve handler to set status = APPROVED; require separate publish action | Backend Developer | Questions with created_by_AI=1 found in assessments without review log |
| RISK-QNS-007 | Zero authorization on all 7 AIQuestionGeneratorController methods — any authenticated user can trigger AI API calls, generating uncontrolled costs | Security | Confirmed (P0) | H | Add Gate::authorize() to all methods; register and enforce AiQuestionGeneratorPolicy | Backend Developer | Unexpected AI provider API charges |
| RISK-QNS-008 | EnsureTenantHasModule middleware absent from route group — schools without QNS license can access all Question Bank routes | Security | Confirmed (P0) | M | Add EnsureTenantHasModule:QNS to the module route group middleware | Backend Developer | Schools not subscribing to QNS module can browse questions |
| RISK-QNS-009 | All 6 FormRequests return Auth::check() in authorize() — no resource-level protection; defence-in-depth collapsed | Security | Confirmed (P1) | M | Implement Gate::allows() checks per D30 platform rule | Backend Developer | Privilege escalation via direct API calls |
| RISK-QNS-010 | Zero test coverage across all 7 controllers and 2 services | Quality | Confirmed | H | Write minimum 25 Pest tests (T-QNS-01 through T-QNS-25 defined in V2 requirement doc) | Testing Architect | Any regression goes undetected until production |

---

# SECTION 7 — PRIORITIZATION (MOSCOW) + EFFORT ESTIMATION

## 7.1 MoSCoW Prioritization

### Must Have (P0 — blocks production)
- REQ-QNS-001 (Question Creation) — core function; existing code has auth gaps and dead policy
- REQ-QNS-003 (Taxonomy Tagging) — all other filtering / analytics depends on this being enforced
- REQ-QNS-005 (Review & Approval Workflow) — review workflow has FSM bypass and no dedicated controller
- REQ-QNS-014 (AI Generation) — currently a non-functional stub with critical security gaps

**Security remediations (not REQ-linked but P0 blocks):**
- Fix duplicate policy registration
- Create permission seeder
- Fix scopeApproved() column name bug
- Fix reviewApprove() FSM bypass
- Fix statistics migration NOT NULL mismatch
- Add EnsureTenantHasModule middleware
- Add Gate::authorize() to all AI controller methods
- Add API rate limiting to AI generation endpoint
- Extract AIQuestionService and remove demo data stub

### Should Have (P1 — required before release)
- REQ-QNS-002 (Question Types — full UI for all 7 types)
- REQ-QNS-004 (Version History — wire routes and build diff view)
- REQ-QNS-006 (Media Management — fix wrong policy gate)
- REQ-QNS-007 (Tag System — wire routes)
- REQ-QNS-010 (Question Statistics — fix migration, wire routes, add scheduled job)
- REQ-QNS-011 (Usage Logging — build usage log view)
- REQ-QNS-012 (Bulk Import — fix auth gaps, fix duplicate detection)
- All 6 FormRequests: replace Auth::check() with real Gate::allows() (D30 rule)

### Could Have (P2 — valuable but not blocking)
- REQ-QNS-008 (Multi-Topic Mapping — add soft weightage validation)
- REQ-QNS-009 (Performance Category Mapping — verify recommendation linkage)
- REQ-QNS-013 (Print — fix auth gap; already mostly working)
- ENH-QNS-001 (Paper Template Builder)
- ENH-QNS-002 (Analytics Dashboard)

### Won't Have (this release)
- ENH-QNS-003 (Batch AI with Queue — deferred to after core AI generation works)
- ENH-QNS-004 (Collaborative Review — complex; deferred)
- ENH-QNS-005 (Question Health Score — deferred until statistics are stable)

## 7.2 Effort Estimation & Sprint Task Breakdown

| # | Task | Type | Effort (h) | Depends on | Sprint |
|---|------|------|-----------|-----------|-------|
| 1 | Fix duplicate Gate::policy() registration in QuestionBankServiceProvider | Security | 1 | — | 1 |
| 2 | Create QNS permission seeder — define 15 permissions, assign to Teacher / Dept Head / Admin roles | Security | 3 | — | 1 |
| 3 | Fix scopeApproved() column name bug in QuestionBank model (ques_reviewed_status → status) | Bug Fix | 1 | — | 1 |
| 4 | Add EnsureTenantHasModule:QNS middleware to route group | Security | 1 | — | 1 |
| 5 | Add Gate::authorize() to QuestionBankController@index, @print, @validateFile, @startImport | Security | 2 | 2 | 1 |
| 6 | Fix reviewApprove() FSM: set status = APPROVED, not PUBLISHED | Bug Fix | 2 | — | 1 |
| 7 | Add migration to make statistics columns NULLABLE (discrimination_index, guessing_factor, avg_time_taken_seconds) | Schema | 1 | — | 1 |
| 8 | Fix QuestionMediaStoreController policy gates: replace tenant.competency.* with tenant.question-media.* | Bug Fix | 1 | — | 1 |
| 9 | Replace all 6 FormRequest authorize() methods with real Gate::allows() calls | Security | 4 | 2 | 1 |
| 10 | Extract AIQuestionService: HTTP calls to OpenAI and Gemini; structured curriculum prompt; JSON response parser | Backend | 12 | — | 2 |
| 11 | Move AI keys to config/services.php; replace env() direct calls; rotate confirmed-compromised keys | Security | 2 | — | 2 |
| 12 | Remove getDemoResponse() early return and dead code from AIQuestionGeneratorController | Bug Fix | 1 | 10 | 2 |
| 13 | Add Gate::authorize() to all 7 AIQuestionGeneratorController methods | Security | 2 | 2 | 2 |
| 14 | Add throttle:10,1 middleware to AI generation route | Security | 1 | — | 2 |
| 15 | Create AIQuestionGenerateRequest FormRequest replacing inline Validator::make() | Backend | 2 | — | 2 |
| 16 | Build QuestionReviewController: submit, approve, reject, publish, archive actions with proper FSM | Backend | 8 | 6 | 2 |
| 17 | Wire Notification module calls on review events (submission, approval, rejection) | Integration | 4 | 16 | 2 |
| 18 | Build AI Review screen (SCR-QNS-07): list generated drafts; edit before submit | Frontend | 6 | 10 | 2 |
| 19 | Wire version history routes in module web.php; build version diff view (SCR-QNS-09) | Backend + Frontend | 6 | — | 3 |
| 20 | Wire statistics routes in module web.php; fix scheduled statistics job dispatch | Backend | 4 | 7 | 3 |
| 21 | Wire tag management routes; complete tag autocomplete in question form | Backend + Frontend | 3 | — | 3 |
| 22 | Build Review Queue screen (SCR-QNS-13): pending reviews list with claim/approve/reject actions | Frontend | 6 | 16 | 3 |
| 23 | Build Usage Logs screen (SCR-QNS-11): per-question assessment usage list | Frontend | 3 | — | 3 |
| 24 | Fix Bulk Import auth gaps (validateFile and startImport); replace LOWER() duplicate check | Backend | 3 | 2 | 3 |
| 25 | Write 25 Pest tests (T-QNS-01 through T-QNS-25 per V2 req doc §12) | Testing | 20 | 1–24 | 4 |
| 26 | Extract QuestionBankService: createQuestion(), updateQuestion(), createVersionSnapshot(), submitForReview() | Refactor | 8 | — | 4 |
| 27 | Cache taxonomy filter data in getFilterData() (1-hour TTL) | Performance | 2 | — | 4 |
| 28 | Remove duplicate models (QuestionStatistics.php) and policies (AIQuestionPolicy.php) | Cleanup | 1 | — | 4 |

**Total estimated effort:** ~112 developer-hours (~14 developer-days)
**Sprint plan:** 4 sprints of approximately 3–4 days each.
**Critical path:** Tasks 1–9 (Sprint 1 security fixes) must be completed before any production access. Task 10 (AIQuestionService) is the gate for all AI-related tasks. Tasks 16–17 (QuestionReviewController + Notifications) gate the P0 workflow fix.

---

# SECTION 8 — USER STORIES + ACCEPTANCE CRITERIA + REPORTING & KPI SPEC

## 8.1 User Stories (P0 and P1 REQs)

---

**US-QNS-001** | Priority: P0 | REQ: REQ-QNS-001
*As a Subject Teacher, I want to create a new question with all required curriculum and taxonomy information so that the question is ready for review and can be used in assessments.*

Acceptance Criteria:
```
Scenario: Happy path — MCQ creation
  Given a teacher is logged in and navigates to Question Bank > Create Question
  When the teacher fills in all required fields (class, subject, lesson, topic, competency, Bloom level,
       cognitive skill, complexity, type specificity, question type, marks, content) and adds 4 options
       with 1 marked correct, and clicks Save
  Then the question is created with status = Draft and appears in the teacher's question list.

Scenario: Missing taxonomy field
  Given a teacher completes all fields except Bloom's Taxonomy Level
  When the teacher clicks Save
  Then the system displays "Bloom's Taxonomy Level is required" and no record is created.

Scenario: Permission denied
  Given a user without the "Create Question" permission
  When the user attempts to access the Create Question screen
  Then the system returns a 403 response.

Scenario: MCQ with no correct option
  Given a teacher creates an MCQ question with 3 options but marks none as correct
  When the teacher clicks Save
  Then the system displays "At least one option must be marked as correct."
```

---

**US-QNS-003** | Priority: P0 | REQ: REQ-QNS-003
*As an Exam Coordinator, I want to browse approved and published questions filtered by Bloom's Taxonomy Level so that I can select cognitively balanced questions for an assessment paper.*

```
Scenario: Happy path — filtered browse
  Given an Exam Coordinator opens the Question Bank list
  When they select Class 10, Subject: Physics, Bloom Level: Analyse
  Then only questions with status Approved or Published, in Class 10 Physics, tagged Bloom Level 4 (Analyse) appear.

Scenario: Draft question excluded
  Given a Draft question exists for Class 10 Physics with Bloom Level 4
  When the Coordinator applies the above filter
  Then the Draft question does not appear in results.

Scenario: Empty result
  Given no Approved or Published questions exist for the selected filter
  When the Coordinator applies the filter
  Then the list shows "No questions found matching these filters."
```

---

**US-QNS-005** | Priority: P0 | REQ: REQ-QNS-005
*As a Department Head, I want to review questions submitted by teachers — approving good ones and rejecting weak ones with feedback — so that only quality questions reach assessments.*

```
Scenario: Happy path — approval
  Given a question is In Review and the Department Head opens it
  When the Head clicks "Approve" (with or without a comment)
  Then the question status changes to Approved, the original author is notified, and a review log entry is created.

Scenario: Rejection without comment
  Given a reviewer clicks "Reject" without entering a comment
  When the system processes the action
  Then the rejection is blocked with "A comment is required when rejecting a question."

Scenario: AI-generated — direct to Published attempt blocked
  Given an AI-generated question is Approved
  When an admin attempts to change its status directly to Published via the status dropdown
  Then the system processes the publish action (AI gate applies at DRAFT→IN_REVIEW, not APPROVED→PUBLISHED [consistent with FSM]).

Scenario: Concurrent review
  Given two reviewers both open the same question in In Review
  When both click "Approve" within seconds of each other
  Then the first action succeeds; the second reviewer sees "This question has already been reviewed by another reviewer."
```

---

**US-QNS-014** | Priority: P0 | REQ: REQ-QNS-014
*As a Subject Teacher, I want to generate MCQ questions using AI by specifying the topic and Bloom level so that I can quickly grow the question bank without writing every question manually.*

```
Scenario: Successful AI generation
  Given a teacher selects OpenAI provider, Class 9, Subject: Biology, Topic: Photosynthesis, Bloom Level 3, Type MCQ, Count 5
  When the teacher clicks "Generate"
  Then the system calls the AI provider and creates 5 Draft questions with the AI-generated flag set.

Scenario: API key not configured
  Given no OpenAI API key is set in the server configuration
  When the teacher clicks "Generate"
  Then the system shows "AI Question Generation is not available — please contact the administrator" and makes no API call.

Scenario: Rate limit exceeded
  Given a teacher has submitted 10 AI generation requests in the last 60 seconds
  When the teacher submits the 11th request
  Then the system responds with "Too many requests — please wait before generating more questions." (HTTP 429)

Scenario: Unauthorized access
  Given a user without the "Use AI Generator" permission
  When the user attempts to access /question-bank/ai-generator
  Then the system returns 403.
```

---

**US-QNS-010** | Priority: P1 | REQ: REQ-QNS-010
*As a School Admin, I want to see the Difficulty Index and Discrimination Index for each question so that I can identify questions that are too easy, too hard, or mis-keyed.*

```
Scenario: Statistics viewed
  Given a question has been answered by at least 30 students
  When the Admin opens the question's Statistics screen
  Then the screen shows a Difficulty Index, Discrimination Index, Guessing Factor (if MCQ), average response time, and total attempts.

Scenario: Negative discrimination flagged
  Given a question's Discrimination Index is −15
  When the Admin views the statistics
  Then the screen highlights "This question may be mis-keyed or poorly constructed — consider reviewing."

Scenario: Insufficient data
  Given a question has only 2 student attempts
  When the Admin views the statistics
  Then Difficulty Index shows the computed value; Discrimination Index shows "Insufficient data (minimum 4 per group)."
```

---

## 8.2 Reporting & KPI Spec

| KPI | Definition (business) | Source Data | Target | Cadence |
|-----|----------------------|-------------|--------|---------|
| Question Bank Size | Total number of Published questions available for assessment use | qns_questions_bank (status = Published) | School-specific goal | Monthly |
| Average Difficulty Index | Mean Difficulty Index across all Published questions per subject | qns_question_statistics | 40–70 (neither trivially easy nor impossibly hard) | Monthly |
| Bloom Level Coverage | Count of Published questions per Bloom Level per subject; any level with zero questions is a gap | qns_questions_bank + slb_bloom_taxonomy | All 6 Bloom levels covered for each subject | Per term |
| Review Turnaround Time | Average days between question submission for review and review decision | qns_question_review_log.reviewed_at − qns_questions_bank.updated_at (when status changed to IN_REVIEW) | < 3 business days | Monthly |
| AI Generation Adoption | Count of AI-generated questions that progressed to Published status vs total created | qns_questions_bank (created_by_AI=1) | 30% of AI-drafted questions reach Published | Monthly |

---

# SECTION 9 — FEATURE SPECIFICATION (KEY SCREENS)

## Screen: Question Bank List — SCR-QNS-01

**Layout:** Table with a filter panel above; tabs across the top.
**Tabs:** All Questions / Draft / Pending Review / Approved / Published / Archived / AI-Generated
**Permissions required:** View Question Bank

| # | Field (column in table) | Type | Notes |
|---|------------------------|------|-------|
| 1 | Internal Title | Text link | Clicking opens Detail view |
| 2 | Question Type | Text badge | MCQ, TF, Essay, etc. |
| 3 | Bloom Level | Text | 1 (Remember) through 6 (Create) |
| 4 | Complexity | Text badge | Easy / Medium / Hard / Very Hard |
| 5 | Status | Coloured badge | Draft (grey) / In Review (yellow) / Approved (blue) / Published (green) / Archived (dark) |
| 6 | Marks | Number | — |
| 7 | Created By | Name | Staff name |
| 8 | Created Date | Date | — |
| 9 | Actions | Button group | View / Edit / Clone / Delete |

**Filters:** Class, Subject, Lesson, Topic, Bloom Level, Complexity Level, Question Type, Status, Tags, Created By, Date Range, AI-Generated only toggle
**Empty state:** "No questions found. Click 'Add Question' to create your first question."
**Bulk actions (Admin only):** Bulk Approve (selected in-review items), Bulk Archive (selected published items)
**Pagination:** 20 per page

---

## Screen: Create / Edit Question — SCR-QNS-02 / SCR-QNS-03

**Layout:** Four-section form (single long page with anchored section headers).
**Permissions required:** Create Question (create) / Edit Question + no student attempts (edit)

| Section | Fields | Notes |
|---------|-------|-------|
| A — Basic Info | Internal Title, Show Title Toggle, Class, Subject, Lesson, Topic (up to 4 levels), Competency, Question Type, Complexity Level, Marks, Negative Marks | Cascading dropdowns; Class → Subject → Lesson → Topic |
| A — Content | Question Content (rich text editor), Content Format selector, Expected Answer Time, Teacher Explanation, Media attachments for question | MathJax preview if LATEX selected |
| B — Settings | Content Owner, School-Specific toggle, Usage type checkboxes (Quiz/Quest/Exam/Offline Exam), Availability Scope + conditional field (section/group/student picker) | Conditional fields appear based on Availability Scope selection |
| B — Reference | Textbook, Page Number, External Reference | Page number validated against book total pages |
| C — Taxonomy | Bloom's Taxonomy Level, Cognitive Skill, Question Type Specificity | All required; validated on review submission |
| C — Answer Options | (shown for MCQ and Match only) Up to 5 options; each has text, correct toggle, option explanation, option media | Minimum 1 correct for MCQ; exactly 1 for Single; auto-sort |
| D — Tags & Topics | Tag picker (autocomplete), Additional topic links with weightage, Performance category mappings | Soft warning if weightages don't sum to 100 |

**Actions:** Save (creates Draft) / Save and Submit for Review / Cancel
**Form validation:** All required fields shown before leaving page if missing.

---

## Screen: Review Queue — SCR-QNS-13

**Layout:** Two-panel; left = pending review list; right = question detail.
**Permissions required:** Review Question (Reviewer, Admin)

| # | Column | Notes |
|---|--------|-------|
| 1 | Question Title | Link to detail |
| 2 | Submitted By | Author name |
| 3 | Class / Subject | — |
| 4 | Submitted Date | — |
| 5 | Assigned Reviewer | Name or "Unassigned" |
| 6 | Actions | Claim / Review |

**Review detail panel:** Full question view (content, options, taxonomy, version history). Approve button (comment optional). Reject button (comment required). Cancel Review button (author only).

---

## Screen: AI Question Generator — SCR-QNS-06

**Layout:** Two-column; left = generation form; right = generated question preview list (loaded after generation).
**Permissions required:** Use AI Question Generator

| # | Field | Type | Required |
|---|-------|------|---------|
| 1 | AI Provider | Choice: OpenAI / Google Gemini | Yes |
| 2 | Class | Dropdown | Yes |
| 3 | Subject | Cascading dropdown | Yes |
| 4 | Lesson | Cascading dropdown | Yes |
| 5 | Topic | Cascading dropdown | Yes |
| 6 | Question Type | Dropdown | Yes |
| 7 | Bloom Level | Dropdown (1–6) | Yes |
| 8 | Complexity Level | Dropdown | Yes |
| 9 | Number of Questions | Number (1–20) | Yes |

**Action:** Generate Questions (POST with rate limit enforcement).
**Preview pane:** Shows each generated question with an Edit before Saving button. Teacher can edit, reject, or submit each generated Draft for review.

---

# SECTION 10 — MODULE KNOWLEDGE REFERENCE

## Current State (as at 2026-06-30)

| Attribute | Value |
|-----------|-------|
| Module Code | QNS |
| Prefix | qns_* |
| DB Layer | tenant_db |
| Controllers | 7 |
| Models | 16 (1 duplicate: QuestionStatistics vs QuestionStatistic) |
| Services | 2 (QuestionStatisticsService — high quality D31 impl; QuestionUsageCheckService) |
| FormRequests | 6 (all return Auth::check() — D30 gap) |
| Policies | 10 (2 confirmed dead: QuestionBankPolicy overwritten; AIQuestionPolicy never registered) |
| Views | 45 |
| Seeders | 9 + support file; NO permission seeder |
| Tests | 0 (critical gap) |
| DDL Tables | 13 (all migrations confirmed present) |
| Effective Completion | ~50% (revised down from 65–70% after Technical Audit 2026-06-29) |
| Health Score | 37 / 100 (NO-GO) |
| FRD Status | v1.1 generated 2026-06-30; supersedes 2026-06-29 |

## P0 Gaps (6 total — all block production)

| Gap ID | Description | Fix |
|--------|-------------|-----|
| GAP-QNS-P0-01 | Duplicate Gate::policy(QuestionBank::class) in ServiceProvider — QuestionBankPolicy dead, all CRUD auth checks dispatch to AiQuestionGeneratorPolicy | Fix ServiceProvider to register QuestionBankPolicy only; remove duplicate |
| GAP-QNS-P0-02 | No permission seeder — all Question Bank permissions undefined; every intended role receives 403 (only super-admin passes Gate::before bypass) | Create permission seeder; define ~15 permissions; assign to Teacher/DeptHead/Admin |
| GAP-QNS-P0-03 | scopeApproved() references column 'ques_reviewed_status' — does not exist; scope returns zero rows; assessment builders see empty question picker | Fix to reference 'status' column |
| GAP-QNS-P0-04 | reviewApprove() sets status = PUBLISHED, bypassing required APPROVED state — AI-generated questions can reach live assessments without completing the review gate (BR-QNS-008) | Fix to set status = APPROVED; require separate publish action |
| GAP-QNS-P0-05 | AI generation returns demo data (getDemoResponse() early return at line 222 of AIQuestionGeneratorController) — all 7 methods on AIQuestionGeneratorController have zero authorization | Implement AIQuestionService; remove stub; add Gate::authorize() |
| GAP-QNS-P0-06 | Statistics migration has NOT NULL on discrimination_index, guessing_factor, avg_time_taken_seconds — service correctly produces null per D31 spec but DB write fails with SQLSTATE 1048 | Migration: make these columns NULLABLE |

## P1 Gaps (9 total)

| Gap ID | Description |
|--------|-------------|
| GAP-QNS-P1-01 | Wrong policy gate on QuestionMediaStoreController: tenant.competency.* instead of tenant.question-media.* |
| GAP-QNS-P1-02 | All 6 FormRequests return Auth::check() in authorize() — no resource-level protection (D30 pattern) |
| GAP-QNS-P1-03 | EnsureTenantHasModule middleware missing from route group |
| GAP-QNS-P1-04 | No rate limiting on AI generation endpoint — runaway API cost risk |
| GAP-QNS-P1-05 | AI generation uses inline Validator::make() instead of FormRequest |
| GAP-QNS-P1-06 | QuestionReviewController not built; review workflow embedded in 2746-line fat controller |
| GAP-QNS-P1-07 | Statistics, version history, and tag routes not wired in module web.php |
| GAP-QNS-P1-08 | No scheduled job for statistics computation (QuestionStatisticsService exists but is never called automatically) |
| GAP-QNS-P1-09 | Notification module not called on any status transition (no submission, approval, or rejection notifications) |

## Pending Next Steps

1. Sprint 1 (immediate): resolve all 6 P0 gaps + P1-01 through P1-05 (security and data integrity)
2. Sprint 2: build AIQuestionService, QuestionReviewController, Notification integration, AI Review screen
3. Sprint 3: wire missing routes, build Review Queue screen, Usage Log view, Bulk Import fixes, scheduled statistics job
4. Sprint 4: 25 Pest tests (T-QNS-01 through T-QNS-25), QuestionBankService extraction, cache taxonomy filters, cleanup duplicates
5. Post-sprint: ENH-QNS-001 (Paper Template Builder) and ENH-QNS-002 (Analytics Dashboard) as P1-on-approval items

## Version History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0 | 2026-06-29 | pa-business-analyst | Initial seed and FRD generation from V2 req doc + live code |
| 1.1 | 2026-06-30 | pa-business-analyst | Incorporated Technical Audit findings (4 new P0s); revised completion to ~50%; health score 37/100; all IDs preserved |
