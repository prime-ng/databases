# Teacher Profile — Requirement Document

## Screen Purpose & Overview

This screen is part of the Employee Creation & Profile Mgmt sub-menu. When an employee's system role is designated as "Teacher", this tab activates to capture and manage their specific academic and teaching details.

The primary objective of this screen is to track teachers' academic qualifications, subject expertise, class teacher assignments, weekly workload limits, teaching experience, and professional certifications. This data serves as the foundation for the school's SmartTimetable generator, exam duty scheduling, and daily substitute arrangement workflows.

---

## Common Use Cases

1. **Configuring Class Teacher Assignments:** Assigning a teacher as the primary class teacher for a specific grade and section (e.g., Class Teacher for Grade 10-A).
2. **Subject Mapping:** Mapping the specific subjects and grade levels a teacher is certified to teach (e.g., Grade 11 Physics, Grade 12 Mathematics).
3. **Tracking Qualifications & Board Registrations:** Storing academic degrees (e.g., B.Ed, M.Sc, PhD) and board registration numbers to maintain school compliance records.
4. **Timetable & Exam Scheduling:** Providing capacity data to the timetable generator regarding teacher qualifications and weekly period limits.
5. **Substitute Teacher Management:** Dynamically recommending qualified standby teachers based on matching subject expertise and free periods when a regular teacher goes on leave.

---

## Screen Fields & Input Rules

### Section A: Academic Qualifications & Experience
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Highest Qualification | Teacher's highest earned degree | Required. Dropdown: B.Ed, M.Ed, M.Sc, MA, PhD. |
| Specialized Subjects | Core areas of specialization | Required. Multi-select dropdown: Mathematics, Physics, Chemistry, English, etc. |
| Board Registration Number | Unique educator board registration ID | Optional. String input. Must be unique. |
| Total Teaching Experience | Total teaching experience in years and months | Required. Numeric input (Years and Months, e.g., 5 Years 2 Months). Minimum is 0. |
| Academic Certifications | Scanned copies of teaching credentials/licenses | Optional. PDF upload (e.g., CTET certificate). Max size: 5MB. |

### Section B: Teaching Capabilities & Class Assignments
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Is Class Teacher? | Indicates if the teacher is a primary class teacher | Required. Toggle button (Yes/No). Defaults to "No". |
| Assigned Class & Section | The class and section assigned to the teacher | Required if 'Is Class Teacher' is Yes. Dropdown: Class & Section (e.g., Class 10-A). |
| Subject Expertise | Mapping of grades and subjects the teacher can teach | Required. Multi-select grid mapping (e.g., Class 9 - Science, Class 10 - Chemistry). |
| Max Workload (Periods/Week) | Maximum teaching periods allowed per week | Required. Numeric input (e.g., 24 periods per week). Range: 1 to 48. |
| Preferred Board | Preferred education board affiliation | Required. Multi-select checkboxes: CBSE / ICSE / State Board. |

---

## Business Rules & Validation Policies

1. **Single Class Teacher Constraint:**
   - A specific Class and Section can have **only one** assigned Class Teacher at any given time.
   - If HR attempts to assign a class/section (e.g., 11-B) that already has an active class teacher mapped, the system displays a confirmation pop-up alert and blocks the action until the user overrides or confirms the change.

2. **Substitute Suggestion Rules:**
   - When a teacher applies for leave, the coordination engine cross-references the teacher's schedule with other staff members' "Subject Expertise" and "Max Workload" settings to automatically generate a list of available substitute teachers.

3. **Weekly Workload Limits:**
   - The timetable generation system enforces the defined `Max Workload` constraint. The scheduling engine will throw an error and block finalization if the assigned periods exceed a teacher's weekly limit.

---

## Screen Workflows & Operations

### 1. Configuring Academic Details (Create/Update)
- When a new employee profile is created with the "Teacher" role, the "Teacher Profile" tab is activated.
- The Admin opens this tab, selects the teacher's qualifications, maps specialized subjects, and uploads scanned certificates.
- Clicks Save to store the record.

### 2. Mapping Class Teacher Roles & Subject Capabilities (Assign)
- The Admin toggles "Is Class Teacher" to "Yes".
- Selects the target Class and Section from the dropdown menu.
- In the Subject Expertise grid, the Admin clicks "Add Row" and links classes (e.g., Class 9) with subjects (e.g., Biology).
- Clicks Save.

### 3. Modifying Workload Limits (Edit)
- If a teacher's availability or schedule changes, the Admin can edit the `Max Workload` (periods per week) value from the profile tab to reflect the new capacity.

---

## Real-World Example Scenario

**School Admin** is setting up the Teacher Profile for a new recruit, **Rakesh Verma**:

1. Rakesh Verma's basic employee profile has already been saved with the role "Teacher".
2. The Admin navigates to the `Teacher Profile` tab.
3. Inputs the details:
   - Highest Qualification: `M.Sc in Physics` and `B.Ed`.
   - Total Teaching Experience: `6 Years`.
   - Is Class Teacher: Toggles to `Yes` and selects Class: `Class 11`, Section: `B`.
   - Subject Expertise mapping: Maps `Class 11 - Physics`, `Class 12 - Physics`, and `Class 10 - Science`.
   - Max Workload: `30 Periods/Week`.
4. Uploads Rakesh's B.Ed degree and CTET certificates.
5. Clicks Save.
6. **System Action:** The system validates that Class 11-B has no other class teacher assigned. Rakesh Verma is successfully registered as the Class Teacher for 11-B, and his subject credentials sync with the timetable module.
