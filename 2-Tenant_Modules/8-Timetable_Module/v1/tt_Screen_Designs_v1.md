# Timetable Module - Screen Designs (v1)

**Document Version:** 1.1 (Enhanced)  
**Goal:** Comprehensive UI/UX coverage for all 29 Database Tables.  
**Reference:** `tt_timetable_ddl_v6.0.sql`

---

## 1. Master Configuration Suite
**Tables Covered:** 
- `tt_shift` (UI)
- `tt_day_type` (UI)
- `tt_period_type` (UI)
- `tt_teacher_assignment_role` (UI)
- `tt_school_days` (UI)
- `tt_working_day` (UI)


### 1.2 Screen: General Settings
**Route:** `/timetable/setup/general`

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  PRIME ERP  |  ACADEMICS SETUP  |  TIMETABLE                                            [User Profile] │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Breadcrumb: Timetable > Setup > Configuration                                                         │
│                                                                                                        │
│  ┌──Tabs────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │  [Shifts] [Day Types] [Period Types] [Assignment Roles] [School Days] [Working Days - Calendar]  │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                        │
│  ** SHIFT CONFIGURATION **                                                    [+ Add New Shift]        │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │ CODE        | NAME             | START TIME | END TIME | ORDINAL | STATUS   | ACTIONS            │  │
│  │─────────────|──────────────────|────────────|──────────|─────────|──────────|────────────────────│  │
│  │ MORNING     | Morning Shift    | 07:30 AM   | 01:30 PM | 1       | [Active] | [Edit] [Delete]    │  │
│  │ AFTERNOON   | Afternoon Shift  | 12:00 PM   | 06:00 PM | 2       | [Active] | [Edit] [Delete]    │  │
│  │ EVENING     | Remedial/Sports  | 04:00 PM   | 07:00 PM | 3       | [Draft ] | [Edit] [Delete]    │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                        │
│  [Pagination: 1 of 1]                                                                                  │
│                                                                                                        │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  PRIME ERP  |  ACADEMICS SETUP  |  TIMETABLE                                            [User Profile] │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Breadcrumb: Timetable > Setup > Configuration                                                         │
│  ┌──Tabs────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │  [Shifts] [Day Types] [Period Types] [Assignment Roles] [School Days] [Working Days - Calendar]  │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                        │
│  >> DAY TYPES CONFIGURATION (tt_day_type)                                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │ CODE      | NAME            | IS WORKING? | REDUCED PERIODS? | ACTIONS                           │  │
│  │───────────|─────────────────|─────────────|──────────────────|───────────────────────────────────│  │
│  │ REGULAR   | Regular Day     | [Yes]       | [No]             | [Edit]                            │  │
│  │ HALF_DAY  | Half Day        | [Yes]       | [Yes]            | [Edit]                            │  │
│  │ EXAM      | Exam Day        | [Yes]       | [No]             | [Edit]                            │  │
│  │ HOLIDAY   | Holiday         | [No]        | [No]             | [Edit]                            │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                        │
│  >> SCHOOL CALENDAR (tt_school_days & tt_working_day)                                                  │
│  "Define which days of the week are open and override specific dates."                                 │
│                                                                                                        │
│  Weekly Pattern (tt_school_days):                                                                      │
│  [x] Mon  [x] Tue  [x] Wed  [x] Thu  [x] Fri  [x] Sat  [ ] Sun                                         │
│                                                                                                        │
│  Special Dates Override (tt_working_day):                                                              │
│  [+ Add Exception]                                                                                     │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │ DATE        | TYPE          | IS OPEN? | REMARKS              | ACTIONS                          │  │
│  │─────────────|───────────────|──────────|──────────────────────|──────────────────────────────────│  │
│  │ 25-Dec-2025 | HOLIDAY       | [No]     | Christmas            | [x]                              │  │
│  │ 14-Feb-2026 | HALF_DAY      | [Yes]    | Carnival             | [x]                              │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```
**Data Logic:**
- `tt_school_days`: Populated via checkboxes (Updates is_school_day).
- `tt_working_day`: Populated via "Add Exception" form.

---

## 2. Structure & Planning
**Tables Covered:**
- `tt_period_set` (UI)
- `tt_period_set_period_jnt` (UI)
- `tt_timetable_type` (UI)
- `tt_class_mode_rule` (UI)

### 2.1 Screen: Timetable Structure (Profiles)
**Route:** `/timetable/setup/profiles`

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  STRUCTURE PROFILES (tt_timetable_type)                                            [+ Create Profile]  │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  "A Profile links a Shift, Period Structure, and Day Type to create a schedulable mode."               │
│                                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │ PROFILE NAME       | SHIFT     | PERIOD SET (Default) | DAY TYPE | SEASONAL RANGE  | ACTIONS     │  │
│  │────────────────────|───────────|──────────────────────|──────────|─────────────────|─────────────│  │
│  │ Morning Regular    | Morning   | Regular 8P           | REGULAR  | All Year        | [Config]    │  │
│  │ Winter Short       | Morning   | Winter 6P            | REGULAR  | Dec 1 - Jan 31  | [Config]    │  │
│  │ Exam Mode          | Morning   | Exam 3P              | EXAM     | Mar 1 - Mar 15  | [Config]    │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Screen: Class Mode Assignment
**Route:** `/timetable/setup/class-modes`

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  CLASS MODE RULES (tt_class_mode_rule)                                                                 │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Apply Timetable Profiles to Classes for the current Academic Session.                                 │
│                                                                                                        │
│  Batch Update: [ Set All Class 10 to 'Morning Regular' ] [ Apply ]                                     │
│                                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │ CLASS  | ASSIGNED PROFILE       | PERIOD SET (Override) | EXAM MODE? | ACTIONS                   │  │
│  │────────|────────────────────────|───────────────────────|────────────|───────────────────────────│  │
│  │ 10-A   | [ Morning Regular ▼ ]  | [ Default (8P) ▼ ]    | [ ]        | [Save]                    │  │
│  │ 10-B   | [ Morning Regular ▼ ]  | [ Default (8P) ▼ ]    | [ ]        | [Save]                    │  │
│  │ 11-A   | [ Morning Regular ▼ ]  | [ Science 9P   ▼ ]    | [ ]        | [Save]                    │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Student Grouping & Requirements
**Tables Covered:**
- `tt_class_subgroup` (UI)
- `tt_class_subgroup_member` (UI/Service)
- `tt_class_group_requirement` (UI)

### 3.1 Screen: Subgroup Manager
**Route:** `/timetable/planning/subgroups`

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  SUBGROUP MANAGER (tt_class_subgroup)                                                                  │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Scope: [ Class 10-A ▼ ]                                                                               │
│                                                                                                        │
│  EXISTING SUBGROUPS:                                                                                   │
│  1. [ 10-A-CS ] Computer Science (Optional) - 15 Students                                              │
│  2. [ 10-A-BIO] Biology (Optional)          - 25 Students                                              │
│                                                                                                        │
│  [+ Create New Subgroup] -> Modal opens:                                                               │
│    Name: [ 10-A-HINDI ]                                                                                │
│    Type: [ LANGUAGE ▼ ]                                                                                │
│    Shared Across Sections? [ ]                                                                         │
│                                                                                                        │
│  >> MANAGE MEMBERS (tt_class_subgroup_member)                                                          │
│  "Select students to add to 10-A-CS":                                                                  │
│  [ Search Student... ]                                                                                 │
│  [x] John Doe                                                                                          │
│  [ ] Jane Smith                                                                                        │
│  (Data populated from Student Master, stored in tt_class_subgroup_member)                              │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Screen: Workload Requirements
**Route:** `/timetable/planning/requirements`

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  CLASS WORKLOAD REQUIREMENTS (tt_class_group_requirement)                                              │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Define how many periods each class needs per subject.                                                 │
│  Target: [ Class 10-A ▼ ]                                                                              │
│                                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │ SUBJECT / SUBGROUP | WEEKLY PERIODS | MAX/DAY | CONSECUTIVE? | PREFERRED    | ACTIONS            │  │
│  │────────────────────|────────────────|─────────|──────────────|──────────────|────────────────────│  │
│  │ Math               | [ 6 ]          | [ 2 ]   | [x] Allowed  | [ Morning  ] | [Delete]           │  │
│  │ English            | [ 5 ]          | [ 1 ]   | [ ] No       | [ Any      ] | [Delete]           │  │
│  │ 10-A-CS (Sub)      | [ 4 ]          | [ 2 ]   | [x] Lab (2)  | [ Afternoon] | [Delete]           │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│  [+ Add Subject Requirement]                                                                           │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Activity Management
**Tables Covered:**
- `tt_activity` (UI/Service)
- `tt_sub_activity` (Service/Internal)
- `tt_activity_teacher` (UI)

### 4.1 Screen: Activity Master
**Route:** `/timetable/planning/activities`

NOTE: `tt_sub_activity` is automatically generated when an Activity has `duration > 1` or `split` enabled. It is not manually edited usually.

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  ACTIVITY PLANNING (tt_activity)                                                                       │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  [+ Bulk Generate from Requirements] (RECOMMENDED: Fills table based on tt_class_group_requirement)    │
│                                                                                                        │
│  MANUAL OVERRIDE:                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │ ID    | CLASS | SUBJECT | SPLIT | TEACHERS (tt_activity_teacher)      | ROOM PREF | ACTIONS      │  │
│  │───────|───────|─────────|───────|─────────────────────────────────────|───────────|──────────────│  │
│  │ A-101 | 10-A  | Math    | 6=2+2+2 | [R. Sharma (Primary)]               | [Num 101] | [Edit]       │  │
│  │ A-102 | 10-A  | Sci     | 4=1+1+2 | [A. Singh (Pri), B. Lal (Asst)]     | [Lab 1 ]  | [Edit]       │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                        │
│  * Teachers column populates `tt_activity_teacher`.                                                    │
│  * Split logic (6=2+2+2) generates rows in `tt_sub_activity`.                                          │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Constraint Engine
**Tables Covered:**
- `tt_constraint_type` (UI - System Admin)
- `tt_constraint` (UI)
- `tt_teacher_unavailable` (UI)
- `tt_room_unavailable` (UI)

### 5.1 Screen: Constraint Builder
**Route:** `/timetable/constraints/builder`

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  CONSTRAINT RULES (tt_constraint)                                                    [+ Add Rule]      │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  "Define Hard (Must) and Soft (Should) rules for the algorithm."                                       │
│                                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │ RULE TYPE (tt_constraint_type)| TARGET (Who?)  | PARAMETERS       | HARD? | WEIGHT | STATUS      │  │
│  │───────────────────────────────|────────────────|──────────────────|───────|────────|─────────────│  │
│  │ Max Daily Periods             | All Teachers   | Max = 8          | [x]   | 100%   | Active      │  │
│  │ Min Gap Between Subjects      | Class 10-A     | Subj: Math, Sci  | [ ]   | 80%    | Active      │  │
│  │ Home Room                     | Class 5-A      | Room: 202        | [x]   | 100%   | Active      │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Screen: Availability Matrix
**Route:** `/timetable/constraints/availability`

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  RESOURCE UNAVAILABILITY (tt_teacher_unavailable & tt_room_unavailable)                                │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  View: [ Teachers ▼ ]  Target: [ R. Sharma ▼ ]                                                         │
│                                                                                                        │
│  Click to toggle UNAVAILABLE slots (Red = Blocked):                                                    │
│  ┌───────┬───────┬───────┬───────┬───────┬───────┐                                                     │
│  │       │ MON   │ TUE   │ WED   │ THU   │ FRI   │                                                     │
│  ├───────┼───────┼───────┼───────┼───────┼───────┤                                                     │
│  │ P1    │       │       │       │ [X]   │       │                                                     │
│  │ P2    │       │ [X]   │       │ [X]   │       │                                                     │
│  │ ...   │       │       │       │       │       │                                                     │
│  └───────┴───────┴───────┴───────┴───────┴───────┘                                                     │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Generation & Output
**Tables Covered:**
- `tt_timetable` (UI header)
- `tt_generation_run` (UI process)
- `tt_timetable_cell` (Output Data)
- `tt_timetable_cell_teacher` (Output Data)
- `tt_constraint_violation` (Output Data)

### 6.1 Screen: Scheduler Control Panel
**Route:** `/timetable/generation/run`

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  TIMETABLE GENERATOR                                                                                   │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  1. SETTINGS:                                                                                          │
│     Session: 2025-26, Profile: Morning Regular                                                         │
│                                                                                                        │
│  2. RUN (tt_generation_run):                                                                           │
│     [ Start Generation ]                                                                               │
│     Status: Completed in 4m 20s. Score: 98.5%                                                          │
│                                                                                                        │
│  3. VALIDATION REPORT (tt_constraint_violation):                                                       │
│     Found 3 Soft Violations:                                                                           │
│     - Teacher R. Sharma has gap > 2 periods on Monday.                                                 │
│                                                                                                        │
│  4. VIEW OUTPUT (tt_timetable_cell):                                                                   │
│     [ Open Interactive Grid ]                                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 6.2 Service Logic: Cell Population
**Data Source:** `TimetableEngine` (Algorithm)
- **Input:** Activities, Constraints, Master Config.
- **Process:** Recursive Swapping Algorithm.
- **Output Tables:**
    1.  `tt_timetable`: Creates new version record.
    2.  `tt_timetable_cell`: Inserts ~1000 rows (Slot assignments).
    3.  `tt_timetable_cell_teacher`: Inserts teacher mapping for each cell.
    4.  `tt_constraint_violation`: Inserts detailed error logs.

---

## 7. Substitution Management
**Tables Covered:**
- `tt_teacher_absence` (UI)
- `tt_substitution_log` (UI)

### 7.1 Screen: Absence Recorder
**Route:** `/timetable/substitution/absence`

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  RECORD ABSENCE (tt_teacher_absence)                                                                   │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Teacher: [ Mr. John Doe ▼ ]                                                                           │
│  Date:    [ 14-Oct-2025 ]                                                                              │
│  Type:    [ Sick Leave ▼ ]                                                                             │
│  Reason:  [ Viral Fever ]                                                                              │
│                                                                                                        │
│  [ Save ] --> Triggers "Find Substitution" Service                                                     │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Screen: Substitution Manager
**Route:** `/timetable/substitution/assign`

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  SUBSTITUTION ASSIGNMENT (tt_substitution_log)                                                         │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Affected Periods for John Doe:                                                                        │
│                                                                                                        │
│  ROW 1: Period 1 - Class 10A - Math                                                                    │
│  Suggestion:                                                                                           │
│  [x] Mrs. B (Free) - Load 20%                                                                          │
│  [ ] Mr. C  (Free) - Load 80%                                                                          │
│                                                                                                        │
│  [ Assign Selected ] --> Updates tt_substitution_log status='ASSIGNED'                                 │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Analytics & Audit (Read-Only Views)
**Tables Covered:**
- `tt_teacher_workload` (Background Service)
- `tt_change_log` (Background Service)

### 8.1 Screen: Teacher Workload View
**Route:** `/timetable/analytics/workload`

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  WORKLOAD ANALYTICS (Read from tt_teacher_workload)                                                    │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  * Table `tt_teacher_workload` is populated by a nightly job or post-generation trigger.               │
│                                                                                                        │
│  DISPLAY:                                                                                              │
│  Name       | Assigned / Max | Utilization | Graph                                                     │
│  -----------|----------------|-------------|-------------------------                                  │
│  R. Sharma  | 28 / 30        | 93%         | [|||||||||.]                                            │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 8.2 Screen: Audit Trail
**Route:** `/timetable/audit`

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  CHANGE LOG (Read from tt_change_log)                                                                  │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  * Populated via Database Triggers or App Observers on Create/Update/Delete.                           │
│                                                                                                        │
│  Date       | User       | Action     | Target    | Details                                            │
│  -----------|------------|------------|-----------|------------------------------------------          │
│  14-Oct     | Admin      | UPDATE     | Cell 105  | Swapped Math (P1) with Phy (P2)                    │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```
