# Timetable Module - Technical Design Document (v1)

**Document Version:** 1.0  
**Date:** 2026-01-11  
**Status:** DRAFT  
**Author:** ERP Architect

---

## 1. Overview

The **Timetable Module (v6.0)** is a constraint-based scheduling engine designated to automate the complex process of school timetable generation. It supports multi-shift configurations, parallel periods (subgroups), and intelligent substitution management.

### Key Goals
- **Automation:** Reduce manual scheduling effort by 90% using a heuristic "recursive swapping" algorithm.
- **Flexibility:** Support strict (Hard) and preferred (Soft) constraints with adjustable weighting.
- **Optimization:** Maximize resource utilization (Labs, Rooms, Teachers).
- **Resilience:** Handle daily disruptions (Teacher Absence) with an automated substitution recommendation engine.

### Cross-Module Interactions
- **Academic Module:** Consumes Classes, Sections, Subjects (`sch_subjects`).
- **HR Module:** consumes Teacher data (`sch_teachers`) and Leave records.
- **Infrastructure:** Consumes Buildings and Rooms (`sch_rooms`).
- **Student Info:** Consumes student group definitions.

---

## 2. Data Context

**Entities:**
- **Core:** Timetable, Activity, Cell.
- **Config:** Shift, Period Set, Day Type, Constraint.
- **Resources:** Teacher, Room, Class Group.

**Cardinality Matrix:**
- **Timetable** (1) ---- (Many) **Cells**
- **Cell** (1) ---- (1) **Activity**
- **Activity** (1) ---- (Many) **Teachers**
- **Class Group** (1) ---- (Many) **Requirements**

**Retention Policy:**
- Timetable Snapshots: **5 Years** (Academic history).
- Substitution Logs: **3 Years**.
- Constraint Definitions: **Versioned** (No hard delete).

> **Refer to `tt_Data_Dictionary.md` for the complete Table Schema.**

---

## 3. Screen Layouts

The UI follows the "Prime ERP" standard with a focus on data density for schedulers and clarity for viewers.

**Priority Screens:**
1.  **Timetable Dashboard:** KPI cards for Conflicts, Substitution needs, and Generation status.
2.  **Constraint Builder:** Form to define rules like "Max Consecutive Periods".
3.  **Interactive Timetable Grid:** Drag-and-drop interface for manual overrides.
4.  **Substitution Manager:** Daily view of absent teachers and suggested replacements.
5.  **Activity Master:** List of all schedulable units (Lessons).

> **Refer to `tt_Screen_Designs.md` for detailed ASCII wireframes.**

---

## 4. Data Models (ER Diagram)

```ascii
                                    +-----------------+
                                    | tt_timetable    |
                                    +-----------------+
                                             |
                                             v
       +-------------+            +---------------------+          +-------------+
       | tt_activity |<-----------|  tt_timetable_cell  |--------->|  sch_rooms  |
       +-------------+            +---------------------+          +-------------+
             ^                               |
             |                               v
+-------------------------+      +---------------------------+
| tt_class_group_req      |      | tt_timetable_cell_teacher |
+-------------------------+      +---------------------------+
             |                               |
             v                               v
   +--------------------+          +----------------+
   | sch_class_groups   |          |  sch_teachers  |
   +--------------------+          +----------------+
                                             ^
                                             |
                                    +--------------------+
                                    | tt_teacher_absence |
                                    +--------------------+
```

---

## 5. User Workflows

### 5.1. Timetable Generation (Heuristic Algorithm)
1.  **Configuration**: Scheduler selects Academic Session, Shift, and Timetable Type (e.g., "Regular").
2.  **Constraint Load**: System loads all Active constraints (Hard & Soft).
3.  **Activity Sorting**: 
    - Sorts `tt_activity` by difficulty (most restricted first).
    - Criteria: Duration > Constraints Count > Resource Scarcity.
4.  **Allocation Loop**:
    - For each Activity `A`:
        - Find valid Time Slots `T` (Day + Period).
        - If multiple `T` exist, pick best score (Soft Constraints).
        - If no `T` exists:
            - **Swap**: Tentatively displace overlapping activity `B`.
            - **Recursion**: Try to place `B` elsewhere.
            - **Backtrack**: If depth > 14, revert and try next branch.
5.  **Finalize**:
    - Save successful allocation to `tt_timetable_cell`.
    - Log any "Unplaced Activities" and "Soft Violations".
6.  **Review**: Scheduler views Grid, manually adjusts locks, and Publishes.

### 5.2. Teacher Substitution
1.  **Trigger**: HR marks Teacher as "Absent" in `tt_teacher_absence`.
2.  **Identification**: System finds all `tt_timetable_cell` entries for that teacher on that date.
3.  **Suggestion Engine**:
    - For each impacted Cell:
        - Find free teachers in that specific Period.
        - Filter by "Subject Expertise" (Ideal) or "Assignment Role".
        - Sort by "Current Workload" (balance load) and "Fairness".
4.  **Assignment**:
    - VP/Admin selects a Substitute from the list.
    - System creates `tt_substitution_log` entry.
    - Notification sent to Substitute Teacher via App/SMS.

---

## 6. Visual Design & UI Components

**Style Guide:**
- **Grid View**: Compact rows, color-coded by Subject or Teacher.
- **Conflict Indicators**:
    - 🔴 **Red Border**: Hard Constraint Violation (Must Fix).
    - 🟡 **Yellow Warning**: Soft Constraint Violation (Advisory).
- **Drag & Drop**: Smooth animation, "Snap-to-grid" feel.
- **Filters**: Faceted search by Class, Teacher, Room, Subject.

**Colors:**
- Primary: Blue `#3B82F6` (Actions).
- Success: Green `#10B981` (Valid Slot).
- Unavailable: Grey `#E5E7EB` (Hashed pattern).

---

## 7. Accessibility (WCAG AA)

- **Keyboard Navigation**:
    - Arrow keys to move focus within Timetable Grid.
    - `Enter` to open Cell Details.
    - `Space` to select for Swap.
- **Screen Readers**:
    - Cells announce: "Monday, Period 1, Math, Room 101".
    - Warnings announce: "Conflict detected: Teacher double-booked".
- **Contrast**: Text labels on colored periods must maintain 4.5:1 ratio.

---

## 8. Testing Strategy

**Unit Tests**:
- **Constraint Logic**: Verify `check_overlap(t1, t2)` returns true/false correctly.
- **Scoring**: Verify `soft_score` decreases when preferences are ignored.

**Integration Tests**:
- **Generation**: Run full generation for a small dataset (5 classes, 10 teachers). Verify 100% placement.
- **Substitution**: Mark teacher absent -> Ensure their cells appear in "Pending Subs" list.

> **Refer to `tt_Test_Cases.md` for specific scenarios.**

---

## 9. Deployment / Runbook

1.  **DB Migration**: Execute `tt_timetable_ddl_v6.0.sql`.
2.  **Seed Master Data**:
    - `tt_shift`: Morning / Afternoon.
    - `tt_period_type`: Teaching / Break / Assembly.
    - `tt_constraint_type`: Load standard set (Max Gaps, Max Daily Hours).
3.  **Environment Config**:
    - `TIMETABLE_MAX_RECURSION_DEPTH=14`
    - `TIMETABLE_GENERATION_TIMEOUT=300` (seconds)

---

## 10. Future Enhancements

1.  **AI Optimization (Medium)**: Use Genetic Algorithms instead of heuristics for global optimization.
2.  **Exam Scheduler (High)**: Specialized mode for Exam seating arrangements (Student -> Seat mapping).
3.  **Mobile Editor (High)**: Allow simple swaps via Mobile App.
