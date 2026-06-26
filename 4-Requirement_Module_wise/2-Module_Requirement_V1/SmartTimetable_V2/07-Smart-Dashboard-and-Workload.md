# Business Requirements Document (BRD)
## Module: Smart Timetable
### Feature 07: Smart Dashboard & Teacher Workload Analytics

---

## 1. Executive Summary
The Smart Timetable dashboard provides an immediate, high-level summary of the entire timetable ecosystem. One of its primary responsibilities is calculating and surfacing Teacher Workload to ensure compliance with labor laws or school limits.

## 2. Core Components
- `SmartTimetableController.php` (Lines 1-300)
- Tables: `sys_configs`, `sch_teachers`, `tt_timetable_cells`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Deep Dashboard Aggregation
- **Data Preloading:** The controller uses heavy Eager Loading (`with()` and `withCount()`) to fetch the entire dependency tree in one go (Activities -> Subject -> StudyFormat -> RequiredRoomType -> Teachers -> AssignmentRole).
- Groups all activities hierarchically by `Class-Section` code to build the dashboard's primary table.

### FR-02: Workload Computation Engine
- **Baseline Metric:** Fetches `max_weekly_periods_can_be_allocated_to_teacher` from `tt_configs` (Defaults to 48 periods/week).
- Iterates over every single teacher to calculate their workload percentage:
  - `assigned = teacher->timetable_cell_assignments_count`
  - `percent = (assigned / max) * 100`
- **Categorization Logic:**
  - **Overloaded:** If percentage >= 100%. (Increment `overloadedCount`).
  - **High Workload:** If percentage >= 80% but < 100%. (Increment `highWorkloadCount`).
  - **Optimal Workload:** If percentage >= 50% but < 80%. (Increment `optimalWorkloadCount`).

### FR-03: Requirement Target Resolution
- Identifies missing configurations by scanning `RequirementConsolidation` models.
- Separates them into `groupedRequirements['groups']` (Whole class requirements) vs `groupedRequirements['subgroups']` (Parallel/Elective subgroups like CS vs PE).

---

## 4. Acceptance Criteria
- **Given** the global max weekly periods is set to 48, **When** Teacher A is assigned 50 periods by the AI algorithm, **Then** the Smart Timetable Dashboard must explicitly increment the 'Overloaded Teachers' metric and highlight Teacher A so the admin can manually intervene and reduce their workload.
