# Student Profile Dashboard Design (Deliverable C)

**Route:** `/dashboard/student-profile` or `/students/dashboard`
**Role Access:** Principal, School Admin, Coordinator

## 1. Dashboard Overview
The Student Profile Dashboard provides a bird's-eye view of the institution's demographics, admission health, and daily strength. It helps administrators track enrollment trends, gender diversity, and daily attendance.

## 2. Wireframe

```ascii
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  PRIME ERP  |  ACADEMICS  |  STUDENTS  |  HR  |  REPORTS                          [User Profile]     │
├──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Breadcrumb: Academics > Student Management > Dashboard                                              │
│                                                                                                      │
│  ┌─────────────────────────────────┐   ┌──────────────────────────────────────────────────────────┐  │
│  │  DASHBOARD FILTERS              │   │  QUICK ACTIONS                                           │  │
│  │  Session: [ 2025-2026 ▼ ]       │   │  [+ New Admission]  [Bulk Import]  [ID Card Print]       │  │
│  │  Class:   [ All Classes ▼ ]     │   │                                                          │  │
│  └─────────────────────────────────┘   └──────────────────────────────────────────────────────────┘  │
│                                                                                                      │
│  ┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐  ┌─────────────────────┐     │
│  │ TOTAL STUDENTS     │  │ NEW ADMISSIONS     │  │ ATTRITION (YTD)    │  │ ATTENDANCE TODAY    │     │
│  │ 1,250              │  │ 120                │  │ 15                 │  │ 92%                 │     │
│  │ ▲ 5% vs last year  │  │ (This Session)     │  │ ▼ 2% vs last year  │  │ (1150/1250)         │     │
│  └────────────────────┘  └────────────────────┘  └────────────────────┘  └─────────────────────┘     │
│                                                                                                      │
│  ┌────────────────────────────────────────────┐  ┌───────────────────────────────────────────────┐   │
│  │  STUDENT DISTRIBUTION (BY CLASS)           │  │  GENDER RATIO                                 │   │
│  │  [Bar Chart Visualization]                 │  │  [Donut Chart]                                │   │
│  │                                            │  │                                               │   │
│  │  200 |    █                                │  │      /`````\   Boys (55%)                     │   │
│  │  150 |    █    █                           │  │     |       |                                 │   │
│  │  100 |    █    █    █    █                 │  │     |_______|   Girls (45%)                   │   │
│  │   50 |    █    █    █    █    █            │  │      \     /                                  │   │
│  │      └────┴────┴────┴────┴────┴────        │  │       `---`                                   │   │
│  │           1    2    3    4    5            │  │                                               │   │
│  │                                            │  │  Total: 1250                                  │   │
│  └────────────────────────────────────────────┘  └───────────────────────────────────────────────┘   │
│                                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │  ⚠️ CRITICAL ALERTS & TASKS                                                                     │ │
│  │  [!] 5 New Admissions pending document verification.                                            │ │
│  │  [!] Class 10-A has low attendance (below 75%) for 3 consecutive days.                          │ │
│  │  [!] 12 Students marked as 'Suspended' - Review required.                                       │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                      │
│  ┌────────────────────────────────────────────┐  ┌───────────────────────────────────────────────┐   │
│  │  ADMISSION TREND (Last 5 Years)            │  │  STUDENT CATEGORIES (RTE/EWS)                 │   │
│  │  [Line Chart]                              │  │  ┌─────────────────────────────────────────┐  │   │
│  │         /```\                              │  │  │ Category    | Count   | % of Total      │  │   │
│  │      /``     \                             │  │  │-------------|---------|-----------------│  │   │
│  │     /         \                            │  │  │ General     | 800     | 64%             │  │   │
│  │  --/           \--                         │  │  │ OBC         | 300     | 24%             │  │   │
│  │                                            │  │  │ SC/ST       | 100     | 8%              │  │   │
│  │   2021  2022  2023  2024  2025             │  │  │ RTE/EWS     | 50      | 4%              │  │   │
│  │                                            │  │  └─────────────────────────────────────────┘  │   │
│  └────────────────────────────────────────────┘  └───────────────────────────────────────────────┘   │
│                                                                                                      │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

## 3. Interaction Design

### 3.1 KPI Cards
*   **Total Students**: Count of `std_students` where `is_active = 1` AND `current_status = 'Active'`.
    *   *Click Action*: Go to Student List filtered by Active.
*   **New Admissions**: Count of `std_students` where `admission_date` is in current Academic Session.
    *   *Click Action*: Go to Student List filtered by Joined Date > Session Start.
*   **Attrition**: Count of `std_student_academic_sessions` where `count_as_attrition = 1` in current session.
*   **Attendance Today**: % of students marked 'Present' in `std_student_attendance` for today.

### 3.2 Visualizations
*   **Student Distribution (Bar)**: Group by `sch_classes.name`.
    *   *Data Source*: `std_student_academic_sessions` joined via `class_section_id`.
*   **Gender Ratio (Donut)**: Group by `std_students.gender`.
*   **Admission Trend (Line)**: Annual admission counts over last 5 years.

### 3.3 Critical Alerts
1.  **Doc Verification**: `std_student_documents` where `is_verified = 0`.
2.  **Low Attendance**: Classes where avg daily attendance < 75%.
3.  **Suspended**: Students with `current_status_id` mapping to 'Suspended'.

## 4. Technical Data Sources

| Widget/Section | Primary Table | Logic/Filter |
| :--- | :--- | :--- |
| **Total Students** | `std_students` | `COUNT(id)` where `is_active=1` |
| **Admission Count** | `std_students` | `COUNT(id)` where `admission_date` BETWEEN SessionStart AND SessionEnd |
| **Gender Ratio** | `std_students` | `COUNT(id)` GROUP BY `gender` |
| **Class Distribution** | `std_student_academic_sessions` | `COUNT(student_id)` WHERE `is_current=1` GROUP BY `class_id` |
| **Attendance** | `std_student_attendance` | `COUNT` Present / Total Marked for `CURDATE()` |
| **Categories** | `std_student_profiles` | `COUNT` GROUP BY `caste_category` or `is_ews` |

