# Business Requirements Document (BRD)
## Module: Smart Timetable Ecosystem
### Feature 02: Requirements & Preparation

---

## 1. Executive Summary
Before the AI or Standard drag-and-drop can place a class, the system must know EXACTLY what is required. How many Math periods does Class 10-A need per week? Which teachers are assigned to it? This module calculates the "Slot Requirements".

## 2. Core Components
- `TimetableFoundation` Module
- Controllers: `RequirementConsolidationController`, `SlotRequirementController`, `ActivityController`
- DDL Category: Timetable Requirement, Timetable Preparation

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Slot Requirements (`SlotRequirementController`)
- Evaluates the school's syllabus payload.
- If Class 10 Math requires 6 periods a week, the system generates a `SlotRequirement`.
- Tracks `allocated_slots` vs `required_slots`. A requirement is only fully met when `allocated_slots == required_slots`.

### FR-02: Activities & Sub-Activities (`ActivityController`)
- **Activity:** A schedulable block. E.g., "Class 10-A Math".
- **Sub-Activity (Parallel Classes):** Sometimes PE or Electives (like CS vs Biology) run parallel. Sub-activities allow the engine to know that "10-A CS" and "10-A Biology" must be scheduled in the *exact same timeslot* but in different rooms with different teachers.
- **Activity-Teacher Mapping:** Hard-links specific teachers to activities so the algorithm knows *who* is teaching.

### FR-03: Requirement Consolidation
- A dashboard that highlights discrepancies. E.g., If Class 9 requires 40 periods a week based on syllabus, but the `PeriodSet` only gives them 35 periods a week, the consolidation engine flags a red error blocking timetable generation.

---

## 4. Acceptance Criteria
- **Given** Class 10-A requires 5 Math periods and 2 parallel Elective periods (CS/Bio), **When** the requirement consolidation runs, **Then** it must generate 5 standard Math activities and 1 parallel sub-activity group. **If** the total required periods exceed the class's maximum available periods, **Then** the system must throw a configuration error.
