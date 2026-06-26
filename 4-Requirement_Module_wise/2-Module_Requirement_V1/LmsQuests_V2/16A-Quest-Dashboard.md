# Business Requirements Document (BRD)
## Module: LMS Quests
### Screen: Dashboard

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Quest Dashboard** provides a real-time, analytical overview of the Quests module. It processes millions of rows of engagement data (`lms_quests`, `lms_quiz_quest_attempts`, `lms_quest_allocations`) to present a top-level snapshot to academic administrators.

### 1.2 Why is this necessary? (Business Justification)
- **Macro Visibility & Adoption:** School administrators need to see if the Quests feature is actively being utilized. By calculating stats like "Total Submissions vs Total Allocations", the system highlights student engagement rates.

---

## 2. Document Scope
- **In-Scope:** KPI Metric Calculations, Cross-Module Data Aggregation, Date/Class/Subject Filtering, Chart rendering (Monthly Activity, Allocations, Score Distribution).
- **Out-of-Scope:** Granular student attempt evaluation.

---

## 3. User Personas
1. **Academic Coordinator / Principal:** Wants a quick snapshot of Quest module adoption across all classes.
2. **Teacher:** Checks their own activity and overall class engagement by filtering down to their assigned sections.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Global Filters
- **Action:** Select filters in the dashboard header.
- **System Behavior (`LmsQuestController::index`):**
  - **Class/Section (`class_section_id`):** Triggers an AJAX call (`getSubjectsByClass`) to load mapped subjects dynamically from `SubjectGroup`.
  - **Subject (`subject_id`):** Filters all metrics by specific subject.
  - **Date Range (`date_from`, `date_to`):** Uses `daterangepicker` to filter by custom dates (e.g., filtering `published_at` for allocations or `submitted_at` for attempts).

### FR-02: Top-Level KPI Calculation (The Math)
- **System Behavior:**
  - **Total Quests:** `COUNT(id)` from `lms_quests` based on active filters.
  - **Total Questions:** `COUNT(id)` from `lms_quest_questions` joined with filtered quests.
  - **Total Allocations:** `COUNT(id)` from `lms_quest_allocations`.
  - **Total Submissions:** `COUNT(id)` from `lms_quiz_quest_attempts` where `assessment_type = 'QUEST'` and `status` is `IN('SUBMITTED', 'TIMEOUT')`.
  - **Total Checked:** `COUNT(id)` from `lms_quiz_quest_results` indicating final grades are published.
  - **Average Score:** `AVG(percentage)` from `lms_quiz_quest_results` rounded to 1 decimal place.

### FR-03: Advanced Charts & Breakdowns
- **System Behavior:**
  - **Status Breakdown:** Exact counts of quests in `DRAFT`, `PUBLISHED`, and `ARCHIVED` states.
  - **Monthly Activity (Bar Chart):** Calculates the last 6 months dynamically. Plots Quests Created (`created_at`) vs Allocations (`created_at`).
  - **Score Distribution (Donut Chart):** Bins all `percentage` results into: `0–20`, `21–40`, `41–60`, `61–80`, `81–100`.
  - **Subject/Class Breakdowns:** Top 6 subjects and classes sorted by descending `quest_count`.

### FR-04: Recent Quests Datagrid
- **System Behavior:**
  - Displays the 8 most recently created quests.
  - Uses `withCount` on relationships to show real-time stats per row:
    - Questions Count (`questQuestions`)
    - Allocations Count (`total_alloc`)
    - Submitted Count (`total_submitted` where status is SUBMITTED/TIMEOUT)
    - Checked Count (`total_evaluated`)
  - Calculates dynamic percentages (e.g., `(Submitted / Allocations) * 100`).

---

## 5. Agile User Stories & Acceptance Criteria
#### Story 1: Tracking Monthly Engagement
**As an** Academic Coordinator,
**I want to** view the Quests Dashboard and filter by "Last 30 Days",
**So that** I can see how many quests were created and submitted recently.

**Acceptance Criteria:**
- **Given** I select a date range, **When** the page reloads, **Then** the `total_submissions` metric accurately reflects `lms_quiz_quest_attempts` where `submitted_at` falls exactly between `date_from` and `date_to`.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_quests`, `lms_quest_questions`, `lms_quest_allocations`, `lms_quiz_quest_attempts`, `lms_quiz_quest_results`, `sch_class_sections`, `sch_subjects`.
