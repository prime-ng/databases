# Capabilities Report — Requirement Document

## Screen Purpose & Overview

This screen is part of the Employee Reports sub-menu. The main purpose of this screen is to generate a unified master report of the academic qualifications, subject expertise, class assignments, and teaching capabilities of all school teachers.

Through this report, school coordinators and the Principal can check teaching competencies and allocation details (e.g., which teacher is teaching which class). This page serves as the primary index document for timetable validation, vacancy status verification, and teacher assessment meetings.

---

## Common Use Cases

1. **Academic Planning:** Verifying how many qualified teachers are available to teach a specific subject (e.g., Chemistry) before the start of a new academic session.
2. **Class Teacher Mapping Audit:** Auditing the "Class Teacher" assignments across all classes simultaneously to ensure no class is left without an assigned teacher and no teacher is double-assigned.
3. **Workload Utilization Check:** Verifying whether a teacher's weekly periods are under or over their maximum weekly period capacity.
4. **Competency Mapping:** Reviewing the assignment of highly qualified and experienced teachers for board examination classes (Class 10 and 12).

---

## Screen Fields & Input Rules

### Section A: Search Filters (Report Filters Settings)
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Target Subject | The subject to search qualified teachers for | Optional. Dropdown options (e.g., Mathematics, Biology). |
| Target Class | The class level to filter qualified staff | Optional. Dropdown options (e.g., Class 10, Class 12). |
| Workload Status | Filter based on workload level | Optional. Options: Over-Utilized (Weekly periods > Limit) / Under-Utilized / Optimal. |

### Section B: Report Data Grid (Table Columns)
| Column Name (Screen Label) | Display Description | Meaning (Simple terms) |
|---|---|---|
| Teacher Name | Name of the teacher | Teacher Name. |
| Highest Degree | The highest academic qualification degree | E.g., M.Sc (Physics), B.Ed. |
| Specialized Subjects | Core areas of specialization | E.g., Physics. |
| Assigned Class Teacher | The class for which the teacher serves as class teacher | Class-Section code (e.g., 10-A / None). |
| Subjects Teaching | Currently assigned classes and subjects in the timetable | E.g., Class 10 (Science), Class 11 (Physics). |
| Max Workload Limit | Maximum number of periods allowed per week | E.g., 28 Periods/Week. |
| Assigned Workload | Total periods currently assigned in the timetable | Actual assigned weekly lectures count (e.g., 24). |
| Workload Balance | Remaining weekly period capacity | Formula: `Max Workload - Assigned Workload`. |

---

## Business Rules & Validation Policies

1. **Workload Alert Rule:**
   - The system automatically highlights workload statuses:
     - **Red Alert (Over-Utilized):** If `Assigned Workload` is greater than `Max Workload Limit`.
     - **Green Tag (Optimal):** If the workload is within a close range of the maximum limit.
     - **Yellow Tag (Under-Utilized):** If assigned periods are significantly below the limit (e.g., 10 periods out of 30).

2. **Validation of Substitution Suggestions:**
   - The system uses capability data to generate smart recommendations when a timetable coordinator searches for a replacement teacher to cover an empty subject lecture.

---

## Screen Workflows & Operations

### 1. Reviewing Teacher Capabilities
- The user selects a Subject (e.g., `Physics`).
- Click "Generate". The system displays all teachers qualified to teach Physics (regardless of whether they are currently assigned to teach it).
- HR can check which teachers have remaining period capacity (workload balance).

### 2. Exporting the Capability Excel Sheet
- Download the Excel sheet for reference during timetable planning meetings.

---

## Real-World Example Scenario

**The Vice Principal** is verifying timetable workloads during a new batch division:

1. The Vice Principal opens the `Capabilities Report` page.
2. They select the filter: Subject = `Mathematics`.
3. They click "Generate Report":
   - **Rakesh Verma:** Degree = `M.Sc Math`, Class Teacher = `11-B`, Teaching = `Class 11 Math, Class 12 Math`, Max Workload = `30`, Assigned = `26`, Balance = `4 Periods` (Optimal).
   - **Vikram Rathore:** Degree = `B.Sc Math, B.Ed`, Class Teacher = `None`, Teaching = `Class 8 Math, Class 9 Math`, Max Workload = `32`, Assigned = `34`, Balance = `-2 Periods` (Over-Utilized Alert - Red).
4. The Vice Principal notes that Vikram Rathore is taking 2 lectures over his limit, whereas Rakesh Verma has a remaining capacity of 4 periods.
5. They instruct the timetable coordinator to reassign Class 9 Math tutorial lectures to Rakesh Verma, bringing Vikram Rathore's workload back to normal parameters.
