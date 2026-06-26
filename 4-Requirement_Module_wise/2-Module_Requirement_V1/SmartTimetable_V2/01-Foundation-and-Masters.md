# Business Requirements Document (BRD)
## Module: Smart Timetable Ecosystem
### Feature 01: Foundation & Masters

---

## 1. Executive Summary
The Timetable module is a complex engine divided into Foundation, Standard, and Smart tiers. Before any timetable can be generated, the school must define its base structural parameters: Shifts, Academic Terms, Period Configurations, and Working Days. This ensures that the generated schedule perfectly aligns with physical school hours.

## 2. Core Components
- `TimetableFoundation` Module
- Controllers: `SchoolShiftController`, `AcademicTermController`, `PeriodConfigController`, `PeriodSetController`, `WorkingDayController`
- DDL Tables: `sch_academic_term`, `tt_configs`, `tt_shifts`, `tt_period_configs`, `tt_period_sets`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Academic Terms (`sch_academic_term`)
- Defines the active chunks of the year (e.g., Summer Term, Winter Term).
- Stores the `term_start_date`, `term_end_date`, `term_total_teaching_days`, and bounds like `term_max_resting_periods_per_day`.
- Ensures only ONE term can have `is_current = 1` using a generated `current_flag` to enforce database uniqueness.

### FR-02: Shifts & Period Configs (`tt_shifts`, `tt_period_configs`)
- **Shift Master:** Defines Morning, Afternoon, or Evening shifts (`start_time`, `end_time`).
- **Period Configurations (v7.7 Update):** Schools require fixed timeslots school-wide. The `tt_period_configs` table establishes the exact Master Grid of periods (e.g., Period 1 is 08:00 to 08:45).
- **Period Sets:** Instead of defining custom times, `tt_period_sets` maps *which* subset of the master periods a specific class uses. (e.g., Nursery uses Periods 1 to 5, Class 10 uses Periods 1 to 8).

### FR-03: Day Types & Working Days
- Differentiates between Full Working Day, Half Day, Holiday.
- Defines `tt_working_days` tracking exactly which days of the week (Monday-Saturday) are active for academic scheduling.

---

## 4. Acceptance Criteria
- **Given** I am a Timetable Admin, **When** I create a "Morning Shift", **Then** I must be able to define a universal master grid of 8 periods in `tt_period_configs`. **When** I assign this to Class 1, **Then** I can restrict Class 1 to only use Periods 1 through 5 from that master grid.
