# MSG Screen Design Specification — Part 2: Schedule, Computation & Data Entry
**Screens:** SC-MSG-09 to SC-MSG-12a | **Date:** 2026-04-13

---

## SC-MSG-09: Marksheet Schedule Dashboard

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.schedules.index` |
| Controller | `MarksheetScheduleController@index` |
| Table | `msh_marksheet_schedules`, `msh_schedule_class_jnt` |
| Actors | Super Admin, Principal, Coordinator, Class Teacher |
| Permission | `msg.schedule.view` |

### Layout
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ Marksheet Schedules                Session: [2025-26 ▼]      [+ Create Schedule]    │
├─────────────────────────────────────────────────────────────────────────────────────┤
│ Filter: [All Types ▼]  [All Status ▼]                          🔍 Search...         │
├────┬──────────────────────┬────────────┬────────────┬──────────┬────────┬───────────┤
│ #  │ Schedule Name        │ Type       │ Exam Group │ Classes  │ Status │ Actions   │
├────┼──────────────────────┼────────────┼────────────┼──────────┼────────┼───────────┤
│ 1  │ Term-1 Report Card   │ Term-1     │ TERM1      │ 9A,9B,   │ 🟢     │ [▼]       │
│    │ Secondary 2025-26    │ Report     │ (UT1+UT2   │ 10A,10B, │ PUBLI- │           │
│    │                      │            │ +HY)       │ 11A,12A  │ SHED   │           │
├────┼──────────────────────┼────────────┼────────────┼──────────┼────────┼───────────┤
│ 2  │ Term-1 Report Card   │ Term-1     │ TERM1      │ 1A,1B,   │ 🟡     │ [▼]       │
│    │ Primary 2025-26      │ Report     │ (FA1+FA2   │ 2A..5B   │ COMPU- │           │
│    │                      │            │ +SA1)      │          │ TED    │           │
├────┼──────────────────────┼────────────┼────────────┼──────────┼────────┼───────────┤
│ 3  │ UT-1 Result          │ Unit Test  │ UT1_ONLY   │ 9A,9B    │ ⚪     │ [▼]       │
│    │ Class 9 2025-26      │            │            │          │ DRAFT  │           │
└────┴──────────────────────┴────────────┴────────────┴──────────┴────────┴───────────┘
```

### Status Badges & Colours
| Status | Badge | Colour | Available Actions |
|---|---|---|---|
| DRAFT | ⚪ DRAFT | Grey | Edit, Delete, Compute |
| COMPUTED | 🟡 COMPUTED | Yellow | Review, Recompute, Enter IA, Enter Co-Scholastic, Enter Attendance |
| REVIEWED | 🔵 REVIEWED | Blue | Publish, Recompute |
| PUBLISHED | 🟢 PUBLISHED | Green | Lock, Unlock, Download PDF |
| LOCKED | 🔒 LOCKED | Dark Grey | Download PDF only |

### Action Dropdown [▼] per row
| Action | Shows When Status = | Permission | Route |
|---|---|---|---|
| Edit | DRAFT | `msg.schedule.update` | `schedules.edit` |
| Delete | DRAFT | `msg.schedule.update` | `schedules.destroy` |
| Compute Results | DRAFT | `msg.compute.trigger` | `schedules.compute` |
| Re-Compute | COMPUTED, REVIEWED | `msg.compute.trigger` | `schedules.compute` |
| Enter IA Marks | COMPUTED | `msg.ia.entry` | `schedules.ia-marks` |
| Enter Co-Scholastic | COMPUTED | `msg.coscholastic.entry` | `schedules.coscholastic` |
| Enter Attendance | COMPUTED | `msg.attendance.entry` | `schedules.attendance` |
| Review Results | COMPUTED | `msg.review.view` | `schedules.review` |
| Publish | REVIEWED | `msg.publish.execute` | `schedules.publish` |
| Lock | PUBLISHED | `msg.publish.lock` | `schedules.lock` |
| Unlock | PUBLISHED, LOCKED | `msg.publish.unlock` | `schedules.unlock` |
| Download PDF | PUBLISHED, LOCKED | `msg.report.download` | `schedules.pdf.bulk` |

### Data Sources
| Element | Query |
|---|---|
| Schedule list | `msh_marksheet_schedules` WHERE `academic_session_id = ?` with `configTemplate.marksheetType`, `configTemplate.examGroup` eager loaded |
| Classes column | `msh_schedule_class_jnt` → `sch_class_section_jnt` — show class-section codes as comma-separated |
| Student count | `msh_marksheet_schedules.total_students` (populated after computation) |
| Status name | `sys_dropdown_table` WHERE `key = 'msh_marksheet_schedules.status_id'` |

---

## SC-MSG-10: Marksheet Schedule Setup

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.schedules.create` / `.edit` |
| Controller | `MarksheetScheduleController@create` / `@store` / `@edit` / `@update` |
| Tables | `msh_marksheet_schedules`, `msh_schedule_class_jnt` |
| Actors | Super Admin, Principal |
| Permission | `msg.schedule.create` |

### Layout
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Create Marksheet Schedule                               [Save] [Cancel] │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Academic Session:   [2025-26            ▼]                             │
│  Config Template:    [CBSE Secondary T1  ▼]  ← filtered by session      │
│                                                                         │
│  Schedule Code:      [SEC_T1_2025        ]                              │
│  Schedule Name:      [Term-1 Report Card - Secondary 2025-26  ]         │
│  Issue Date:         [📅 2025-11-30      ]                              │
│                                                                         │
│  ┌─ Template Info (read-only) ──────────────────────────────────┐       │
│  │ Type: Term-1 Report Card | Exam Group: TERM1 (UT-1, UT-2,    │       │
│  │ HY-EXAM) | Grading: CBSE 9-Point | Passing: 33%              │       │
│  └──────────────────────────────────────────────────────────────┘       │
│                                                                         │
│  ┌─ Select Class-Sections ──────────────────────────────────────┐       │
│  │                                                              │       │
│  │  Class 9:  [✓] 9-A (42 students)                             │       │
│  │            [✓] 9-B (38 students)                             │       │
│  │  Class 10: [✓] 10-A (45 students)                            │       │
│  │            [✓] 10-B (40 students)                            │       │
│  │  Class 11: [✓] 11-A (35 students)                            │       │
│  │  Class 12: [ ] 12-A (30 students)  ← different template      │       │
│  │                                                              │       │
│  │  [Select All]  [Deselect All]       Total: 200 students      │       │
│  └──────────────────────────────────────────────────────────────┘       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Field Mapping
| Field | Type | DDL Column | Validation | Source |
|---|---|---|---|---|
| Academic Session | Dropdown | `academic_session_id` | Required | `sch_org_academic_sessions_jnt` (default: current) |
| Config Template | Dropdown | `config_template_id` | Required | `msh_config_templates` WHERE session = selected AND `is_active=1` |
| Code | Text Input | `code` | Required, unique per session, max:50 | Auto-suggest from template code |
| Name | Text Input | `name` | Required, max:150 | Auto-suggest from template name |
| Issue Date | Date Picker | `schedule_date` | Optional | Manual |
| Class-Sections | Checkbox list | `msh_schedule_class_jnt.class_section_id` | At least 1 selected | `sch_class_section_jnt` WHERE class_id IN (classes assigned to this template via `msh_class_config_jnt`). Show student count per section |

### Behaviour
- Selecting a template auto-populates the "Template Info" box and filters class-sections to only those classes that have this template assigned (via `msh_class_config_jnt`)
- Classes with a different template (or no template) are shown greyed out with explanation
- Student count per section fetched from `sch_class_section_jnt.actual_total_student`
- Edit mode: class-sections cannot be removed if results already computed (show warning)

---

## SC-MSG-11: Computation Progress

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.schedules.progress` |
| Controller | `ComputationController@progress` |
| Tables | `msh_computation_logs`, `msh_marksheet_schedules` |
| Actors | Super Admin, Principal, Coordinator, Class Teacher |
| Permission | `msg.compute.progress` |
| Technology | **Livewire polling** (2-second interval) |

### Layout
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Computing Results: Term-1 Report Card - Secondary 2025-26               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Overall Progress:  ████████████████░░░░░░  75%  (150 / 200 students)   │
│  Elapsed: 00:32     Estimated Remaining: 00:11                          │
│                                                                         │
│  ┌─ Class-Section Progress ─────────────────────────────────────┐       │
│  │                                                              │       │
│  │  9-A (42 students)   ████████████████████  100% ✅           │       │
│  │  9-B (38 students)   ████████████████████  100% ✅           │       │
│  │  10-A (45 students)  ██████████████░░░░░░   70% ⏳           │       │
│  │  10-B (40 students)  ░░░░░░░░░░░░░░░░░░░░    0% ⏸️ Queued    │       │
│  │  11-A (35 students)  ░░░░░░░░░░░░░░░░░░░░    0% ⏸️ Queued    │       │
│  │                                                              │       │
│  └──────────────────────────────────────────────────────────────┘       │
│                                                                         │
│  ┌─ Errors (if any) ────────────────────────────────────────────┐       │
│  │  ⚠️ Student ID 1045 (10-A): No exam result found for UT-2    │       │
│  │     Science — score set to NULL                              │       │
│  └──────────────────────────────────────────────────────────────┘       │
│                                                                         │
│                                              [Cancel Job]  [Back]       │
└─────────────────────────────────────────────────────────────────────────┘
```

### Data Sources
| Element | Source |
|---|---|
| Overall progress | `msh_computation_logs` latest row for this schedule (total_students, status) |
| Per-class progress | Computed by counting `msh_student_results` rows per class_section for this schedule vs expected student count |
| Errors | `msh_computation_logs.error_log` (JSON array, parsed and displayed) |
| Elapsed time | `msh_computation_logs.started_at` vs `NOW()` |

### Behaviour
- Page auto-refreshes via Livewire polling every 2 seconds
- When all class-sections reach 100%, show success message + auto-redirect to Schedule Dashboard
- [Cancel Job] dispatches a cancellation signal to the queued job (future enhancement)
- On failure, show error details and "Retry" button

---

## SC-MSG-12a: IA Marks Entry

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.schedules.ia-marks` |
| Controller | `ResultReviewController@iaMarksForm` / `@storeIaMarks` |
| Table | `msh_student_ia_marks` |
| Actors | Super Admin, Principal, Coordinator, Class Teacher, Subject Teacher |
| Permission | `msg.ia.entry` |

### Layout
```
┌─────────────────────────────────────────────────────────────────────────┐
│ IA Marks Entry                                                          │
│ Schedule: Term-1 Report Card - Secondary 2025-26                        │
│ Class-Section: [9-A  ▼]     Subject: [Science  ▼]            [Save All] │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  IA Components:  Notebook (max: 5)  |  Subject Enrichment (max: 5)      │
│                                                                         │
├─────┬──────────────────────┬───────────┬───────────────────┬────────────┤
│ #   │ Student Name         │ Roll No   │ Notebook (/5)     │ Enrich(/5) │
├─────┼──────────────────────┼───────────┼───────────────────┼────────────┤
│  1  │ Aarav Sharma         │ 01        │ [  4  ]           │ [  5  ]    │
│  2  │ Ananya Patel         │ 02        │ [  3  ]           │ [  4  ]    │
│  3  │ Arjun Singh          │ 03        │ [  5  ]           │ [  5  ]    │
│  4  │ Diya Gupta           │ 04        │ [  4  ]           │ [  3  ]    │
│  5  │ Ishaan Kumar         │ 05        │ [    ]            │ [    ]     │
│ ... │ ...                  │ ...       │ ...               │ ...        │
│ 42  │ Zara Khan            │ 42        │ [  4  ]           │ [  4  ]    │
├─────┼──────────────────────┼───────────┼───────────────────┼────────────┤
│     │                      │           │ Filled: 41/42     │ 41/42      │
└─────┴──────────────────────┴───────────┴───────────────────┴────────────┘
│ ⚠️ 1 student has empty marks. Empty = "Not Assessed" (will show — on    │
│    marksheet). Enter 0 explicitly for zero marks.                       │
│                                             [Save All]  [Save & Next]   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Field Mapping
| Field | Type | DDL Column | Validation | Source |
|---|---|---|---|---|
| Class-Section | Dropdown (filter) | — | Required | `msh_schedule_class_jnt` → `sch_class_section_jnt` for this schedule |
| Subject | Dropdown (filter) | — | Required | `sch_subjects` linked to selected class via `sch_class_groups_jnt` |
| Student rows | Auto-populated | — | — | `std_students` enrolled in selected class-section for this session |
| IA Mark per cell | Number Input | `msh_student_ia_marks.marks_obtained` | Optional (NULL = not assessed), min:0, max:`msh_template_ia_components.max_marks` | Manual entry |

### Behaviour
- Grid layout: students as rows, IA components as columns
- Column headers show component name + max marks
- Tab key moves to next cell (left-to-right, then next row)
- Empty cell = NULL (not assessed, shows "—" on marksheet). Explicit 0 = zero marks.
- [Save All] bulk-upserts all cells (INSERT ON DUPLICATE KEY UPDATE pattern)
- [Save & Next] saves and moves to next subject dropdown option
- "Filled: X/Y" counter per column shows completion progress
- Red highlight on cells where marks > max_marks
- Subject Teacher can only see subjects they teach (filter by `sch_employees.subject_assignments`)

---

## SC-MSG-06a: Co-Scholastic Entry Grid

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.schedules.coscholastic` |
| Controller | `ResultReviewController@coscholasticForm` / `@storeCoscholasticGrades` |
| Table | `msh_student_coscholastic_results` |
| Actors | Super Admin, Principal, Coordinator, Class Teacher |
| Permission | `msg.coscholastic.entry` |

### Layout
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Co-Scholastic Grades Entry                                              │
│ Schedule: Term-1 Report Card - Secondary 2025-26                        │
│ Class-Section: [9-A  ▼]                                    [Save All]   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Grading: A / B / C (3-Point Scale)                                     │
│                                                                         │
├─────┬────────────────────┬───────────┬──────────┬──────────┬────────────┤
│ #   │ Student Name       │ Work Ed   │ Art Ed   │ Health   │ Discipline │
│     │                    │ (A/B/C)   │ (A/B/C)  │ (A/B/C)  │ (A/B/C) 🔗 │
├─────┼────────────────────┼───────────┼──────────┼──────────┼────────────┤
│  1  │ Aarav Sharma       │ [ A  ▼]   │ [ B  ▼]  │ [ A  ▼]  │  A  (BA)   │
│  2  │ Ananya Patel       │ [ B  ▼]   │ [ A  ▼]  │ [ A  ▼]  │  B  (BA)   │
│  3  │ Arjun Singh        │ [ A  ▼]   │ [ B  ▼]  │ [ B  ▼]  │  A  (BA)   │
│ ... │ ...                │ ...       │ ...      │ ...      │ ...        │
│ 42  │ Zara Khan          │ [ A  ▼]   │ [ A  ▼]  │ [ B  ▼]  │  B  (BA)   │
└─────┴────────────────────┴───────────┴──────────┴──────────┴────────────┘
│ 🔗 Discipline column auto-populated from BehaviouralAssessment module.  │
│    Override: click the grade to manually change (logs override).        │
│                                             [Save All]  [Save & Next]   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Field Mapping
| Field | Type | DDL Column | Validation | Source |
|---|---|---|---|---|
| Class-Section | Dropdown (filter) | — | Required | `msh_schedule_class_jnt` for this schedule |
| Student rows | Auto-populated | — | — | `std_students` enrolled in selected class-section |
| Grade per cell | Dropdown (A/B/C or A/B/C/D/E) | `msh_student_coscholastic_results.grade` | Options from `msh_template_coscholastic_components.grading_scale` | Dropdown per cell |
| Discipline column | Auto-populated / Override | `msh_student_coscholastic_results.grade`, `is_auto_from_ba` | — | If `is_ba_linked=1`: pre-filled from `BehaviouralScoreService`. Editable but tracked as override (`is_auto_from_ba` set to 0 on manual change) |

### Behaviour
- Columns = co-scholastic areas from `msh_template_coscholastic_components` for the linked template
- BA-linked column (Discipline) pre-filled with grades from `BehaviouralScoreService::getStudentScore()`. Shown with "🔗 (BA)" tag.
- If teacher manually overrides a BA-linked grade, `is_auto_from_ba` set to 0 and `entered_by` set to current user
- Tab/Enter navigation between cells
- [Save All] bulk-upserts

---

## SC-MSG-09a: Attendance Entry

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.schedules.attendance` |
| Controller | `ResultReviewController@attendanceForm` / `@storeAttendance` |
| Table | `msh_student_attendance` |
| Actors | Super Admin, Principal, Coordinator, Class Teacher |
| Permission | `msg.attendance.entry` |

### Layout
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Attendance Entry                                                        │
│ Schedule: Term-1 Report Card - Secondary 2025-26                        │
│ Class-Section: [9-A  ▼]                                    [Save All]   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Default Working Days for this class-section: [ 114 ]  [Apply to All]   │
│                                                                         │
├─────┬────────────────────┬───────────┬────────────────┬─────────────────┤
│ #   │ Student Name       │ Roll No   │ Working Days   │ Days Present    │
├─────┼────────────────────┼───────────┼────────────────┼─────────────────┤
│  1  │ Aarav Sharma       │ 01        │ [ 114 ]        │ [ 110 ]         │
│  2  │ Ananya Patel       │ 02        │ [ 114 ]        │ [ 108 ]         │
│  3  │ Arjun Singh        │ 03        │ [ 114 ]        │ [ 100 ]         │
│  4  │ Diya Gupta         │ 04        │ [ 110 ]        │ [  95 ]  ⚠️     │
│ ... │ ...                │ ...       │ ...            │ ...             │
│ 42  │ Zara Khan          │ 42        │ [ 114 ]        │ [ 112 ]         │
└─────┴────────────────────┴───────────┴────────────────┴─────────────────┘
│ ⚠️ Diya has fewer working days (transferred mid-term).                  │
│ Days Present cannot exceed Working Days.                                │
│                                             [Save All]  [Save & Next]   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Field Mapping
| Field | Type | DDL Column | Validation | Source |
|---|---|---|---|---|
| Class-Section | Dropdown | — | Required | `msh_schedule_class_jnt` for this schedule |
| Default Working Days | Number Input | — | Optional helper | Manual. [Apply to All] copies value to all student rows |
| Working Days per student | Number | `msh_student_attendance.total_working_days` | Required, min:1, max:365 | Manual (or auto from Attendance module Phase 2) |
| Days Present per student | Number | `msh_student_attendance.days_present` | Required, min:0, max: ≤ working_days | Manual |

### Behaviour
- "Default Working Days" + [Apply to All] = convenience bulk-set for all students
- Individual Working Days can differ (student transferred mid-term)
- Days Present > Working Days → red border + validation error
- [Save All] bulk-upserts all rows
- If Attendance module (`att_*`) becomes available in future, show [Auto-Populate from Attendance] button that calls `AttendanceReader` service

---

## SC-MSG-12: Result Review Grid

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.schedules.review` |
| Controller | `ResultReviewController@reviewGrid` |
| Tables | `msh_student_subject_exam_marks`, `msh_student_subject_results`, `msh_student_results` |
| Actors | Super Admin, Principal, Coordinator, Class Teacher |
| Permission | `msg.review.view` |
| Technology | **Livewire component** (for filtering, sorting without page reload) |

### Layout
```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ Result Review: Term-1 Report Card - Secondary 2025-26                                       │
│ Class-Section: [9-A  ▼]                              [Mark as Reviewed]  [Back to Dashboard]│
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│ Exam Group: TERM1 (UT-1, UT-2, HY-EXAM)  |  Grading: CBSE 9-Point  |  Pass: 33%             │
│                                                                                             │
├─────┬────────────┬──────────────────────────────────────────────────────────┬───────┬───────┤
│     │            │                    ENGLISH                               │       │       │
│     │            ├──────┬──────┬────────┬────┬──────┬───────┬───────────────┤       │       │
│ #   │ Student    │ UT-1 │ UT-2 │ HY     │ NB │ Enr. │ Total │ Grade         │ ...   │ Grand │
│     │            │ /10  │ /10  │ /80    │ /5 │ /5   │ /100  │               │       │ Total │
├─────┼────────────┼──────┼──────┼────────┼────┼──────┼───────┼───────────────┼───────┼───────┤
│  1  │ Aarav S.   │  8   │  7   │  64    │  4 │  4   │  87   │ A2            │ ...   │ 487   │
│  2  │ Ananya P.  │  9   │  8   │  72    │  5 │  5   │  99   │ A1            │ ...   │ 520   │
│  3  │ Arjun S.   │  7   │  6   │  58    │  4 │  3   │  78   │ B1            │ ...   │ 410   │
│  4  │ Diya G.    │  AB  │  8   │  65    │  4 │  4   │  —    │ —             │ ...   │ —     │
│  5  │ Ishaan K.  │  6   │  5   │  WH    │  3 │  3   │  —    │ —             │ ...   │ —     │
│ ... │ ...        │ ...  │ ...  │ ...    │ .. │ ...  │ ...   │ ...           │ ...   │ ...   │
├─────┼────────────┼──────┼──────┼────────┼────┼──────┼───────┼───────────────┼───────┼───────┤
│     │ Class Avg  │ 7.4  │ 6.8  │ 62.1   │4.1 │ 3.9  │ 84.2  │               │       │ 458   │
│     │ Highest    │  10  │  10  │  78    │  5 │  5   │  99   │               │       │ 540   │
│     │ Lowest     │   3  │   3  │  28    │  2 │  1   │  42   │               │       │ 290   │
└─────┴────────────┴──────┴──────┴────────┴────┴──────┴───────┴───────────────┴───────┴───────┘
│ Legend: AB = Absent  |  WH = Withheld  |  — = Not Computed  |  🔴 = Failed (<33%)           │
│                                                                                             │
│ Summary: 42 students | 38 Promoted | 2 Compartment | 1 Detained | 1 Withheld                │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Column Structure (Dynamic — built from template config)

For EACH subject in the class:
| Sub-Column | DDL Source | Notes |
|---|---|---|
| Exam mark columns (UT-1, UT-2, HY) | `msh_student_subject_exam_marks.marks_obtained` | One column per exam type in the exam group. Header shows max marks. |
| IA component columns (NB, Enr.) | `msh_student_ia_marks.marks_obtained` | One column per IA component in the template. Only if IA configured. |
| Subject Total | `msh_student_subject_results.subject_total` | Computed |
| Subject Grade | `msh_student_subject_results.subject_grade` | From `slb_grade_division_master` |

After all subjects:
| Column | DDL Source |
|---|---|
| Grand Total | `msh_student_results.grand_total` |
| Percentage | `msh_student_results.overall_percentage` |
| Grade | `msh_student_results.overall_grade` |
| Rank | `msh_student_results.rank_in_section` |
| Result | `msh_student_results.promotion_status` |

### Behaviour
- Horizontal scroll for many subjects (sticky first 2 columns: #, Student Name)
- AB cells styled with grey background, "AB" text
- WH cells styled with orange background, "WH" text
- Failed subjects (< passing %) styled with red text
- Bottom summary row: class average, highest, lowest per column
- Click student name → navigate to SC-MSG-13 (Individual Preview)
- [Mark as Reviewed] → changes schedule status from COMPUTED to REVIEWED (requires `msg.review.view` permission)
- Sortable by any column (Livewire)
- Row highlighting: red for DETAINED, yellow for COMPARTMENT, green for PROMOTED
