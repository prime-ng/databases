# LMS Homework Analytics — Requirement Document

## 1. Screen Purpose & Overview

The **Homework Analytics** tab is the analytical landing page for teachers and coordinators. It offers graphical displays of student performance metrics, showing trends in submission rates, average grade curves, and late submission frequencies. 

Teachers use these analytics to identify syllabus areas where students struggle, enabling targeted remedial interventions.

---

## 2. Common Business Use Cases

1. **Analyzing Class Submissions:** A teacher reviews the submission rate graph to see which students missed homework on a particular topic.
2. **Identifying Difficult Topics:** A coordinator filters average scores by subject. A low average on a topic (e.g., *Probability*) indicates a need for classroom review.
3. **Evaluating Grading Spreads:** A teacher reviews the grade distribution bar chart (e.g. A, B, C, D spreads) to assess student understanding levels.

---

## 3. Database Schema & Data Dictionary

*   **Primary Tables**: `lms_homework`, `lms_homework_assignment`, `lms_homework_submissions`
*   **Data Aggregation Schema**:
    *   `Submission Rates`: Grouped by `homework_id` count of `status_id = SUBMITTED` / total assignments.
    *   `Grade Distribution`: Counts of `marks_obtained` grouped in percentile bins ($0\%-39\%$, $40\%-59\%$, $60\%-79\%$, $80\%-100\%$).
    *   `Timeliness Index`: Ratio of on-time submissions vs. late submissions.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Class** | Dropdown | Yes | Select active class from `sch_classes`. | None |
| **Section** | Dropdown | No | Select section from `sch_sections`. | None |
| **Subject** | Dropdown | No | Filtered list based on class. | None |
| **Time Period** | Dropdown select | Yes | `Last 7 Days` \| `Last 30 Days` \| `Current Term` \| `Full Year`. | `Last 30 Days` |

---

## 5. Business Logic & Validation Policies

1. **Analytical Performance Formulas**:
   * **Timeliness Index** ($\text{Index}_{\text{time}}$):
     $$\text{Index}_{\text{time}} = \frac{\text{On-Time Submissions}}{\text{On-Time Submissions} + \text{Late Submissions}}$$
   * **Topic Difficulty Score** ($\text{Score}_{\text{difficulty}}$):
     $$\text{Score}_{\text{difficulty}} = 1.0 - \text{Ratio}_{\text{avg}}$$
     *(where a higher score indicates a more difficult topic, with a lower average grade).*
2. **Dynamic Chart Rendering**:
   * If a selected class-subject filter has zero published homework, the page displays a placeholder message: *"No homework assignments found for the selected criteria."*
   * The system caches aggregated metrics for 1 hour to optimize performance, invalidating the cache when a new homework is published or a grade is saved.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as a Teacher or Administrator.
* Navigate to the LmsHomework dashboard and click the **Homework Analytics** tab.

### Scenario A: Displaying Dashboard Analytics
1. Select Class: `Class 10`.
2. Select Time Period: `Last 30 Days`.
3. Click **"Generate Analytics"**.
4. **Expected Result**: Charts load successfully, displaying:
   * A donut chart of overall submission statuses (Submitted, Late, Overdue, Pending).
   * A bar chart showing the average score per homework.
   * A line chart of submission rate trends over the last 30 days.

### Scenario B: Empty State Validation
1. Select a class section that has no assignments created (e.g. a newly formed section).
2. Click **"Generate Analytics"**.
3. **Expected Result**: The charts display empty states with the notification: *"No homework assignments found for the selected criteria."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/lms-home-work/home-works?tab=homework_analytics`

### 2. Analytics Load Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/lms-home-work/home-works?tab=homework_analytics')
            ->select('class_id', $this->classId)
            ->press('@generate-btn')
            ->waitFor('.chart-container')
            ->assertVisible('@submission-rate-chart')
            ->assertVisible('@grade-distribution-chart');
});
```
