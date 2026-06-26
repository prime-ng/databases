# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Advanced Reports
### Screen: Tab 5: Exam Subject Comparison

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Exam Subject Comparison** report acts as a departmental audit. It compares how students performed across different subjects within the *same* exam (e.g., Comparing Math vs English vs Science for the Mid-Term).

### 1.2 Why is this necessary? (Business Justification)
- **Difficulty Audits:** If the average score for Math is 40% but English is 85%, the Principal needs to know if the Math paper was too difficult or if the Math teacher is underperforming.

---

## 2. Document Scope
- **In-Scope:** Cross-subject metric aggregation (Avg Score, Pass Rate, High/Mid/Low banding).
- **Out-of-Scope:** Student-level granularity.

---

## 3. User Personas
1. **Principal / Head of Academics:** Compares departments to ensure balanced academic delivery.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Subject Aggregation
- **Action:** Filter by a specific Exam.
- **System Behavior (`generateExamSubjectComparisonData`):**
  - Fetches all papers for the exam.
  - Iterates through the results of each paper.
  - Calculates for each subject: `Avg Pct`, `Highest`, `Lowest`, `Pass Rate %`.

### FR-02: Banding Calculations
- **System Behavior:**
  - Categorizes students in each subject into:
    - `High`: >= 75%
    - `Mid`: 40% to 74%
    - `Low`: < 40%

### FR-03: Visual Comparisons
- **System Behavior:**
  - Renders a Benchmarking bar chart (Avg Score vs Pass Rate per subject).
  - Renders a Stacked Bar Chart for the Banding (showing the proportion of High/Mid/Low students per subject).

---

## 5. Agile User Stories & Acceptance Criteria
#### Story 1: Auditing Department Performance
**As a** Principal,
**I want to** compare all subjects for the Final Exam,
**So that** I can see if the Physics paper caused an unusually high failure rate compared to Chemistry.

**Acceptance Criteria:**
- **Given** I select the Final Exam, **When** the benchmarking chart loads, **Then** I can clearly see the Pass Rate bar for Physics side-by-side with Chemistry.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_exam_papers` and their associated `lms_exam_results`.
