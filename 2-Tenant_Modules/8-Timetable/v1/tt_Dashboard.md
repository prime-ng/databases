# Timetable Module - Dashboard Designs (v1)

**Document Version:** 1.0  
**Route:** `/timetable/dashboard`  
**Role Access:** Admin, Principal, Scheduler  
**Reference:** `tt_timetable_ddl_v6.0.sql`

---

## 1. Timetable Operations Dashboard
**Goal:** High-level overview of scheduling health and daily operations.

### 1.1 Wireframe

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  PRIME ERP  |  TIMETABLE OPERATIONS  |  MY SCHEDULE  |  REPORTS                       [User Profile]   │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Breadcrumb: Timetable > Dashboard                                                                     │
│                                                                                                        │
│  ┌─────────────────────────────────┐   ┌────────────────────────────────────────────────────────────┐  │
│  │  CONTEXT                        │   │  QUICK ACTIONS                                             │  │
│  │  Session: [ 2025-26 ▼ ]         │   │  [+ New Timetable]  [+ Record Absence]  [View My Schedule] │  │
│  │  Today: Mon, 14 Oct (Regular)   │   │                                                            │  │
│  └─────────────────────────────────┘   └────────────────────────────────────────────────────────────┘  │
│                                                                                                        │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐  ┌─────────────────────┐ │
│  │ TOTAL CLASSES TODAY  │  │ ABSENT TEACHERS      │  │ UNCOVERED PERIODS    │  │ SOFT CONFLICTS      │ │
│  │ 142                  │  │ 3                    │  │ 2                    │  │ 15                  │ │
│  │ All Running          │  │ (Waitlist: 0)        │  │ Action Req           │  │ (Acceptable)        │ │
│  └──────────────────────┘  └──────────────────────┘  └──────────────────────┘  └─────────────────────┘ │
│                                                                                                        │
│  ┌──────────────────────────────────────────────┐  ┌─────────────────────────────────────────────────┐ │
│  │  TEACHER UTILIZATION (Global)                │  │  SUBSTITUTION TRENDS (Last 30 Days)             │ │
│  │  [ Bar Chart ]                               │  │  [ Line Chart ]                                 │ │
│  │  Full Load (>25 pds) : ████████ 60%          │  │        /```\      /                             │ │
│  │  Normal    (18-25)   : ████ 30%              │  │       /     \____/                              │ │
│  │  Underload (<18 pds) : █ 10%                 │  │      /                                          │ │
│  │                                              │  │   Sep 14       Oct 01       Oct 14              │ │
│  └──────────────────────────────────────────────┘  └─────────────────────────────────────────────────┘ │
│                                                                                                        │
│  ┌───────────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │  ⚠️ CRITICAL ALERTS                                                                               │ │
│  │  [!] Room 101 (Physics Lab) is double-booked on Tue P3 (Class 10-A, 11-B). Resolve Conflict.      │ │
│  │  [!] Mrs. Sharma (Math) has exceeded Max Daily limit (9 periods) on Friday.                       │ │
│  │  [!] "Annual Day" (Oct 20) requires timetable adjustment.                                         │ │
│  └───────────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                        │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Data Elements
- **Total Classes**: Count `tt_timetable_cell` where day = current_day.
- **Absent Teachers**: Count `tt_teacher_absence` where date = today.
- **Uncovered**: Count `tt_substitution_log` where status != 'ASSIGNED'.

---

## 2. Substitution Dashboard
**Route:** `/timetable/substitution/dashboard`
**Goal:** Manage daily firefighting of absent teachers.

### 2.1 Wireframe

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  SUBSTITUTION CONTROL CENTER                                                                           │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Date: [ Today (14 Oct) ▼ ]   Status: [ All ▼ ]                                                        │
│                                                                                                        │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐                          │
│  │ TOTAL ABSENCES       │  │ PERIODS IMPACTED     │  │ COVERAGE RATIO       │                          │
│  │ 5 Teachers           │  │ 28 Periods           │  │ 92% (26/28)          │                          │
│  └──────────────────────┘  └──────────────────────┘  └──────────────────────┘                          │
│                                                                                                        │
│  ┌───────────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │  LIVE STATUS BOARD                                                                                │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐  │ │
│  │  │ TEACHER          | PERIODS | STATUS     | SUB ASSIGNED TO       | NOTIFIED?                 │  │ │
│  │  │──────────────────|─────────|────────────|───────────────────────|───────────────────────────│  │ │
│  │  │ Mr. A. Singh     | P1, P2  | COVERED    | Mrs. B. Kaur (P1)     | [x] SMS Sent              │  │ │
│  │  │                  |         |            | Mr. C. Lal (P2)       | [x] App Read              │  │ │
│  │  │ Mrs. P. Guha     | P4, P5  | PENDING    | [ Select Sub ]        | -                         │  │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                        │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Technical Data Sources (Mapping)

| Widget | Table | Logic |
| :--- | :--- | :--- |
| **Total Classes** | `tt_timetable_cell` | `COUNT(id)` where `day_of_week` = TODAY |
| **Absent Teachers** | `tt_teacher_absence` | `COUNT(id)` where `absence_date` = TODAY |
| **Conflicts** | `tt_constraint_violation` | `SUM(violation_count)` |
| **Substitute List** | `tt_substitution_log` | `SELECT *` JOIN `sch_teachers` |
