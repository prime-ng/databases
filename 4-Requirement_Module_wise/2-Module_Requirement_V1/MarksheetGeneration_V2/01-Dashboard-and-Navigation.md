# Business Requirements Document (BRD)
## Module: Marksheet Generation
### Screen: Dashboard & Navigation

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Marksheet Generation Module** is a massive aggregation engine. It takes raw scores from `LmsExam`, `LmsQuiz`, `LmsHomework` and computes them into formal Report Cards (Marksheets). The **Dashboard** acts as the command center for this operation.

### 1.2 Why is this necessary? (Business Justification)
- **Centralized Insights:** Generating a school-wide marksheet is a complex, multi-step process. The dashboard provides clear metrics (Active Templates, Live Schedules, Computed Results) to ensure the Exam Coordinator knows exactly what stage the results are in.

---

## 2. Document Scope
- **In-Scope:** The main Dashboard (`dashboard.blade.php`), statistical widgets, and the 4-pillar combined navigation system (Configuration, Components, Scheduling, Results).
- **Out-of-Scope:** The inner workings of the actual templates.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Key Metric Widgets (Stats)
- **System Behavior:** The dashboard calculates and displays live counts for:
  1. **Marksheet Types** (e.g., Unit Test, Annual)
  2. **Config Templates**
  3. **Schedules** (Batch processing events)
  4. **Student Results** (Total generated marksheets)
  5. **Schedule Classes**
  6. **Practical Configs**
- Each metric must show an "Active vs Inactive" breakdown.

### FR-02: 4-Pillar Navigation System
The module abandons traditional deep sidebars for a "Combined Tab" approach. Clicking any pillar opens a sub-navigation view:
- **Configuration (`/configuration`):** Marksheet Types, IA Component Types, Config Templates, Class Groups, Exam Groups.
- **Components (`/components`):** Scholastic Components, Exam Weightages, IA Components, Coscholastic Components.
- **Scheduling (`/scheduling`):** Practical Configs, Marksheet Schedules, Schedule Classes.
- **Results (`/results`):** Student Results, Subject Results, IA Marks, Coscholastic Results.

### FR-03: Recent Activity Tabs
- **Recent Schedules:** A table showing the latest generated marksheet schedules, their associated template, date, and active status.
- **Recent Results:** A table showing the latest student results computed by the system.

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Tracking Marksheet Progress
**As an** Exam Coordinator,
**I want to** see how many Student Results have been generated on the dashboard,
**So that** I know if the background computation job has finished processing the school's marks.

**Acceptance Criteria:**
- **Given** I am on the Marksheet Dashboard, **When** the page loads, **Then** I see a red stat card displaying the exact count of computed `total_results`.
