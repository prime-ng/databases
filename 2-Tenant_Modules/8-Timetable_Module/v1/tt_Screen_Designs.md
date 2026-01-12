# Timetable Module - Screen Designs (v1)

**Document Version:** 1.0  
**Includes:** Master Setup, Activity Manager, Scheduler, Substitution  
**Reference:** `tt_timetable_ddl_v6.0.sql`

---

## Screen 1: Timetable Configuration Master
**Route:** `/timetable/setup/configuration`  
**Role Access:** Admin, Timetable Manager  
**Tables:** `tt_shift`, `tt_day_type`, `tt_period_type`, `tt_teacher_assignment_role`

### 1. Wireframe

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  PRIME ERP  |  TIMETABLE  |  ACADEMICS SETUP                                            [User Profile] │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Breadcrumb: Timetable > Setup > Configuration                                                         │
│                                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │  [Tab: Shifts]  [Tab: Day Types]  [Tab: Period Types]  [Tab: Assignment Roles]                   │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                        │
│  ** SHIFT CONFIGURATION **                                                    [+ Add New Shift]        │
│                                                                                                        │
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

### Component Specifications
- **Tabs**: Client-side switching logic.
- **Grids**: Inline editing not required; use Modal for Add/Edit.
- **Status Toggle**: Immediate AJAX update for `is_active`.

---

## Screen 2: Period Set Manager
**Route:** `/timetable/setup/period-sets`  
**Role Access:** Timetable Manager  
**Tables:** `tt_period_set`, `tt_period_set_period_jnt`

### 1. Wireframe (Edit View)

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  < Back to List |  EDIT PERIOD SET: "Regular Summer (8 Periods)"                                       │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                        │
│  ┌─ HEADER INFO ────────────────────────────────────────────────────────────────────────────────────┐  │
│  │  Code: [ REG_SUMMER_8P ]    Name: [ Regular 8-Period Summer ]   Default: [x]                     │  │
│  │  Total Periods: [ 8 ]       Teaching Periods: [ 6 ]             Range: [08:00] to [14:00]        │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                        │
│  ┌─ PERIOD STRUCTURE ───────────────────────────────────────────────────────────────────────────────┐  │
│  │  [+ Add Period]                                                                                  │  │
│  │                                                                                                  │
│  │  #  | TYPE       | LABEL    | START   | END     | DURATION | ACTIONS                             │
│  │  ---|------------|----------|---------|---------|----------|-------------------------------------│  │
│  │  1  | Teaching   | P1       | 08:00   | 08:45   | 45 min   | [Edit] [x]                          │  │
│  │  2  | Teaching   | P2       | 08:45   | 09:30   | 45 min   | [Edit] [x]                          │  │
│  │  3  | Break      | Break    | 09:30   | 09:45   | 15 min   | [Edit] [x]                          │  │
│  │  4  | Teaching   | P3       | 09:45   | 10:30   | 45 min   | [Edit] [x]                          │  │
│  │  ...                                                                                             │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                        │
│  [ Save Changes ]  [ Cancel ]                                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 2. Interaction Logic
- **Validation**: Ensure `Start Time` of next period >= `End Time` of previous.
- **Auto-Calc**: `Teaching Periods` = Count where `type.counts_as_teaching = 1`.

---

## Screen 3: Activity Manager (Filtering & Listing)
**Route:** `/timetable/planning/activities`  
**Tables:** `tt_activity`, `tt_sub_activity`, `tt_activity_teacher`

### 1. Wireframe

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  ACTIVITY MANAGER                                                             [Import CSV] [+ Create]  │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Filters:                                                                                              │
│  [ Session: 2025-26 ▼]  [ Class: 10-A ▼]  [ Subject: Math ▼]  [ Teacher: All ▼]                        │
│                                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │ ID      | SUBJECT    | TEACHER(S)       | DURATION | REQ | PREF ROOM       | DIFFICULTY | STATUS │  │
│  │─────────|────────────|──────────────────|──────────|─────|─────────────────|────────────|────────│  │
│  │ ACT-101 | Math       | R.K. Sharma      | 1        | 5/wk| -               | 85%        | Active │  │
│  │ ACT-102 | Physics    | A. Einstein      | 2 (Lab)  | 2/wk| Physics Lab     | 95%        | Active │  │
│  │ ACT-103 | Sports     | P.T. Usha        | 1        | 2/wk| Playground      | 40%        | Active │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                        │
│  [Bulk Actions ▼] -> (Activate, Deactivate, Delete)                                                    │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Screen 4: Timetable Generator (The "Scheduler")
**Route:** `/timetable/generation/run`  
**Tables:** `tt_generation_run`, `tt_timetable`

### 1. Wireframe

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  GENERATE TIMETABLE                                                                                    │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  STEP 1: CONFIGURATION                                                                                 │
│  Name: [ Final Term 1 Draft_ ]      Timetable Type: [ Morning Regular ▼ ]                              │
│  Period Set: [ Regular Summer 8P ▼ ]                                                                   │
│                                                                                                        │
│  STEP 2: STRATEGY                                                                                      │
│  [x] Allow Soft Constraint Violations                                                                  │
│  Max Placement Attempts: [ 100000 ]                                                                    │
│  Recursion Depth: [ 14 ]                                                                               │
│                                                                                                        │
│  [ START GENERATION ]                                                                                  │
│                                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │  GENERATION PROGRESS (Session UUID: 882a-...)                                                    │  │
│  │                                                                                                  │
│  │  Status: RUNNING... (45s elapsed)                                                                │  │
│  │  [██████████████████████──────] 72%                                                              │  │
│  │                                                                                                  │
│  │  Activities Placed: 850 / 1200                                                                   │  │
│  │  Hard Conflicts:    0                                                                            │  │
│  │  Soft Conflicts:    12 (Teacher Gap Preferences)                                                 │  │
│  │                                                                                                  │
│  │  [ Stop Generation ]                                                                             │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Screen 5: Substitution Manager
**Route:** `/timetable/substitution/daily`  
**Tables:** `tt_teacher_absence`, `tt_substitution_log`

### 1. Wireframe

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  SUBSTITUTION MANAGER | Date: [ 14-Oct-2025 ▼ ]                                   [+ Record Absence]   │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                        │
│  ┌─ ABSENT TEACHERS ────────────────────────────────────────────────────────────────────────────────┐  │
│  │  1. Mr. John Doe (Sick Leave) - Full Day                                                         │  │
│  │     Impact: 5 Periods                                                                            │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                        │
│  ┌─ REPLACEMENT SUGGESTIONS ────────────────────────────────────────────────────────────────────────┐  │
│  │  Period 1 (Class 10-A, Math)                                                                     │  │
│  │  ----------------------------------------------------------------------------------------------  │  │
│  │  Suggested Substitutes:                                                                          │  │
│  │  [Assign] Mrs. Jane Smith (Math Dept) | Free | Load: 2/8 | Rating: ⭐⭐⭐⭐⭐                      │  │
│  │  [Assign] Mr. Bob Wilson (Physics)    | Free | Load: 4/8 | Rating: ⭐⭐⭐⭐                        │  │
│  │                                                                                                  │  │
│  │  Period 3 (Class 9-B, Math)                                                                      │  │
│  │  ----------------------------------------------------------------------------------------------  │  │
│  │  [Assign] ...                                                                                    │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                        │
│  [ Notify All Substitutes ]  [ Print Sheet ]                                                           │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```
