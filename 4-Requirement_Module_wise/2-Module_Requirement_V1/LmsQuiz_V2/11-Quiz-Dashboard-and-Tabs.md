# Business Requirements Document (BRD)
## Module: LMS Quiz
### Sub-Module: Main Navigation
### Screen: Quiz Dashboard & Tab Module

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **LMS Quiz Module** uses a centralized 8-Tab Navigation structure (`tab.blade.php`) to keep all quiz-related operations within a single unified interface. The primary landing tab is the **Quiz Dashboard**, which provides real-time analytical KPIs and visual charts about quiz usage across the school.

### 1.2 Why is this necessary? (Business Justification)
- **Single Page Application (SPA) Feel:** Keeps the user context intact without forcing full page reloads across different menus.
- **Executive Oversight:** The Dashboard immediately highlights completion rates and average scores, allowing admins to instantly gauge academic health.

---

## 2. Document Scope
- **In-Scope:** The 8-Tab container logic. The Dashboard filters, KPI cards, Charts, and Breakdown tables.
- **Out-of-Scope:** The inner workings of the other 7 tabs (documented in BRDs 12-18).

---

## 3. User Personas
1. **Academic Head / Admin:** Lands here to review aggregate quiz statistics.
2. **Teacher:** Uses the tab container to navigate between creation and allocation.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: The 8-Tab Navigation Container
- **System Behavior:** A persistent `nav-tab` header.
- **Tabs & Access Control:**
  1. **Dashboard:** `@can('tenant.quiz-dashboard.view')`
  2. **Difficulty Distribution Config:** `@can('tenant.difficulty-config.viewAny')`
  3. **Assessment Types:** `@can('tenant.assessment-type.viewAny')`
  4. **Quiz Creation:** `@can('tenant.quiz.viewAny')`
  5. **Quiz Questions:** `@can('tenant.quiz-question.viewAny')`
  6. **Quiz Allocation:** `@can('tenant.quiz-allocation.viewAny')`
  7. **Quiz Summary:** `@can('tenant.quiz-summary.view')`
  8. **Activity Log:** `@can('tenant.quiz-activity-log.view')`

### FR-02: Dashboard Filtering
- **Action:** Filter the entire dashboard analytics.
- **Fields:**
  - **Class & Section:** Dropdown.
  - **Subject / Study Format:** Dropdown.
  - **Status:** (DRAFT, PUBLISHED, ARCHIVED).
  - **Date Range:** Daterangepicker mapping to `date_from` and `date_to`.

### FR-03: Dashboard Analytics (KPIs & Charts)
- **KPI Cards (6 metrics):**
  1. Total Quizzes (with Published sub-text)
  2. Questions (in pool)
  3. Allocations
  4. Attempts (with In-Progress sub-text)
  5. Submitted (with % completion rate)
  6. Avg Score (%)
- **Charts (Chart.js):**
  - **Grouped Bar Chart:** Monthly Activity (Quizzes Created vs Allocations).
  - **Doughnut Chart:** Score Distribution (0-20%, 21-40%, 41-60%, 61-80%, 81-100%).
- **Data Tables:**
  - **Subject-wise Quiz Breakdown:** Shows Subject, Quizzes Count, Questions Count, Avg Marks, and a visual Share Progress Bar.
  - **Quiz Status Breakdown:** Progress bars showing the ratio of Draft vs Published vs Archived quizzes.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Executive Dashboard View
**As an** Academic Head,
**I want to** see the Average Score percentage across all quizzes on the main dashboard,
**So that** I instantly know the general academic performance level of the school without running complex reports.

**Acceptance Criteria:**
- **Given** I log into the Quiz module, **When** I land on the Dashboard tab, **Then** I see the 6 KPI cards including the "Avg Score", which updates dynamically if I change the Class/Section filter.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** Mass aggregation of `lms_quizzes`, `lms_quiz_allocations`, `lms_quiz_attempts`.
- **Outgoing Dependencies:** Acts as the gateway to all other Quiz BRDs (12 through 18).
