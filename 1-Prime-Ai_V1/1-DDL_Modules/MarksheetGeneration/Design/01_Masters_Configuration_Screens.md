# MSG Screen Design Specification — Part 1: Masters & Configuration
**Screens:** SC-MSG-01 to SC-MSG-08 | **Date:** 2026-04-13

---

## SC-MSG-01: Marksheet Type Master

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.marksheet-types.index` / `.create` / `.edit` |
| Controller | `MarksheetTypeController` |
| Table | `msh_marksheet_types` |
| Actors | Super Admin, Principal |
| Permission | `msg.config.create`, `msg.config.update`, `msg.config.delete` |

### Layout: Index View (List)
```
┌─────────────────────────────────────────────────────────────────┐
│ Marksheet Types                              [+ Add New Type]   │
├─────┬────────────┬─────────────────────┬────────┬───────────────┤
│  #  │ Code       │ Name                │ Status │ Actions       │
├─────┼────────────┼─────────────────────┼────────┼───────────────┤
│  1  │ UNIT_TEST  │ Unit Test Result    │ Active │ [Edit] [Del]  │
│  2  │ TERM1      │ Term-1 Report Card  │ Active │ [Edit] [Del]  │
│  3  │ TERM2      │ Term-2 Report Card  │ Active │ [Edit] [Del]  │
│  4  │ ANNUAL     │ Annual Report Card  │ Active │ [Edit] [Del]  │
└─────┴────────────┴─────────────────────┴────────┴───────────────┘
```

### Layout: Create/Edit Form
| Field | Type | DDL Column | Validation | Source |
|---|---|---|---|---|
| Code | Text Input | `code` VARCHAR(30) | Required, unique, uppercase, max:30, regex:`/^[A-Z0-9_]+$/` | Manual entry |
| Name | Text Input | `name` VARCHAR(100) | Required, max:100 | Manual entry |
| Description | Textarea | `description` VARCHAR(255) | Optional, max:255 | Manual entry |
| Display Order | Number | `display_order` SMALLINT | Required, min:1 | Manual entry |
| Active | Toggle | `is_active` TINYINT(1) | Default: ON | Toggle switch |

### Behaviour
- Code auto-uppercased on input (Alpine.js `x-model` + `.toUpperCase()`)
- Delete is soft-delete. Show confirmation modal.
- List sortable by `display_order` via drag-drop (update `display_order` on drop)

---

## SC-MSG-07a: Class Group Management

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.class-groups.index` / `.create` / `.edit` |
| Controller | `ClassGroupController` |
| Tables | `msh_class_groups`, `msh_class_group_items_jnt` |
| Actors | Super Admin, Principal |
| Permission | `msg.class-group.manage` |

### Layout: Index + Inline Edit
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Marksheet Class Groups                               [+ Add Group]      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─ PRIMARY (Classes 1-5) ──────────────────────────── [Edit] [Del] ─┐  │
│  │  [Class 1] [Class 2] [Class 3] [Class 4] [Class 5]  [+ Add]       │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌─ MIDDLE (Classes 6-8) ───────────────────────────── [Edit] [Del] ─┐  │
│  │  [Class 6] [Class 7] [Class 8]                      [+ Add]       │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌─ SECONDARY (Classes 9-12) ───────────────────────── [Edit] [Del] ─┐  │
│  │  [Class 9] [Class 10] [Class 11] [Class 12]        [+ Add]        │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

### Layout: Create/Edit Group Form
| Field | Type | DDL Column | Validation | Source |
|---|---|---|---|---|
| Code | Text Input | `msh_class_groups.code` | Required, unique, max:30 | Manual (PRIMARY, MIDDLE, etc.) |
| Name | Text Input | `msh_class_groups.name` | Required, max:100 | Manual |
| Description | Textarea | `msh_class_groups.description` | Optional, max:255 | Manual |
| Classes | Multi-select Chips | `msh_class_group_items_jnt.class_id` | At least 1 class | Dropdown: `sch_classes` WHERE `is_active=1` ORDER BY `ordinal` |

### Behaviour
- Classes displayed as removable chips/tags inside the group card
- [+ Add] opens a dropdown of available classes (exclude classes already in ANY group)
- A class can only belong to ONE marksheet group (validate on add)
- Removing a class removes the `msh_class_group_items_jnt` row (soft delete)

---

## SC-MSG-02: Exam Group Setup

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.exam-groups.index` / `.create` / `.edit` |
| Controller | `ExamGroupController` |
| Tables | `msh_exam_groups`, `msh_exam_group_items_jnt` |
| Actors | Super Admin, Principal, Coordinator |
| Permission | `msg.exam-group.manage` |

### Layout: Index View
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Exam Groups              Session: [2025-26 ▼]         [+ Add Group]     │
├─────┬──────────┬──────────────────────┬──────────────────┬──────────────┤
│  #  │ Code     │ Name                 │ Exam Types       │ Actions      │
├─────┼──────────┼──────────────────────┼──────────────────┼──────────────┤
│  1  │ TERM1    │ Term-1               │ UT-1, UT-2,      │ [Edit] [Del] │
│     │          │                      │ HY-EXAM          │              │
│  2  │ TERM2    │ Term-2               │ UT-3, UT-4,      │ [Edit] [Del] │
│     │          │                      │ ANNUAL-EXAM      │              │
│  3  │ ANNUAL   │ Full Year            │ UT-1..UT-4,      │ [Edit] [Del] │
│     │          │                      │ HY, ANNUAL       │              │
└─────┴──────────┴──────────────────────┴──────────────────┴──────────────┘
```

### Layout: Create/Edit Form
| Field | Type | DDL Column | Validation | Source |
|---|---|---|---|---|
| Academic Session | Dropdown (readonly on edit) | `msh_exam_groups.academic_session_id` | Required | `sch_org_academic_sessions_jnt` WHERE `is_active=1`. Default: current session (`is_current=1`) |
| Code | Text Input | `msh_exam_groups.code` | Required, unique per session, max:30 | Manual |
| Name | Text Input | `msh_exam_groups.name` | Required, max:100 | Manual |
| Description | Textarea | `msh_exam_groups.description` | Optional | Manual |
| Term Start Date | Date Picker | `msh_exam_groups.start_date` | Optional (used for HW/Quiz date range) | Manual |
| Term End Date | Date Picker | `msh_exam_groups.end_date` | Optional, must be > start_date | Manual |
| Exam Types | Multi-select Checkbox List | `msh_exam_group_items_jnt.exam_type_id` | At least 1 selected | `lms_exam_types` WHERE `is_active=1` ORDER BY display order. Show code + name. Checkboxes. |

### Behaviour
- Session selector at top filters the list
- Exam types shown as checkbox list with drag handle for `display_order`
- Same exam type can appear in multiple groups (e.g., UT-1 in both TERM1 and ANNUAL)
- Dates are optional but recommended — they drive the date range for Homework/Quiz/Quest score aggregation

---

## SC-MSG-03: Config Template Builder

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.config-templates.create` / `.edit` |
| Controller | `ConfigTemplateController` |
| Table | `msh_config_templates` |
| Actors | Super Admin, Principal |
| Permission | `msg.config.create`, `msg.config.update` |

### Layout: Create/Edit — Multi-Tab Form
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Config Template: CBSE Secondary Term-1 2025-26            [Save] [Back] │
│                                                                         │
│ ┌──────────┬──────────────┬──────────────┬─────────────┬──────────────┐ │
│ │ Basic    │ Components   │ Exam Weight  │ IA Setup    │ Co-Schol.    │ │
│ │ Info     │ & Weightage  │              │             │              │ │
│ └──────────┴──────────────┴──────────────┴─────────────┴──────────────┘ │
│                                                                         │
│  [TAB CONTENT BELOW]                                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Tab 1: Basic Info
| Field | Type | DDL Column | Validation | Source |
|---|---|---|---|---|
| Academic Session | Dropdown | `academic_session_id` | Required | `sch_org_academic_sessions_jnt` (default: current) |
| Marksheet Type | Dropdown | `marksheet_type_id` | Required | `msh_marksheet_types` WHERE `is_active=1` |
| Exam Group | Dropdown | `exam_group_id` | Required | `msh_exam_groups` WHERE `academic_session_id` = selected session AND `is_active=1` |
| Grading Schema | Dropdown | `grading_schema_id` | Optional | `slb_grade_division_master` WHERE `is_active=1` — show `code + ' — ' + name` grouped by `grading_type` |
| Code | Text Input | `code` | Required, unique per session, max:50 | Manual (auto-suggest from type+group) |
| Name | Text Input | `name` | Required, max:150 | Manual |
| Board Affiliation | Dropdown | `board_code` | Optional | Static list: CBSE, ICSE, STATE, CUSTOM |
| Passing % | Number | `passing_percentage` | Required, min:0, max:100, default:33 | Manual |
| Compartment Max Failures | Number | `compartment_max_failures` | Required, min:0, max:10, default:2 | Manual |
| Best-of-N Enabled | Toggle | `is_best_of_n_enabled` | Default: OFF | Toggle |
| Best-of-N Count | Number | `best_of_n_count` | Required if best-of-N ON, min:1 | Manual (hidden if toggle OFF) |

### Tab 2: Scholastic Components & Weightage
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Scholastic Components                          Total: [100.00%] ✅      │
├────────────────────┬─────────────┬───────────────┬──────────────────────┤
│ Component          │ Include     │ Weightage (%) │ Max Marks (optional) │
├────────────────────┼─────────────┼───────────────┼──────────────────────┤
│ Examination ⭐     │ [✓] (fixed) │ [  80.00  ]   │ [         ]          │
│ Homework           │ [✓]         │ [   5.00  ]   │ [         ]          │
│ Quiz               │ [✓]         │ [   5.00  ]   │ [         ]          │
│ Quest              │ [✓]         │ [  10.00  ]   │ [         ]          │
├────────────────────┼─────────────┼───────────────┼──────────────────────┤
│                    │             │  Total: 100%  │                      │
└────────────────────┴─────────────┴───────────────┴──────────────────────┘
│ ⭐ Examination is mandatory and cannot be unchecked                     │
│ ⚠️ Total must equal 100% before saving                                  │
└─────────────────────────────────────────────────────────────────────────┘
```

| Field | Type | DDL Column | Validation | Source |
|---|---|---|---|---|
| Include Checkbox | Checkbox | (controls row existence in `msh_template_scholastic_components`) | Exam always checked | `msh_source_components` (4 rows) |
| Weightage % | Number Input | `weightage_percent` DECIMAL(5,2) | Required if included, min:0.01, max:100 | Manual |
| Max Marks | Number Input | `max_marks` DECIMAL(8,2) | Optional | Manual |

**Validation:** SUM of all included component `weightage_percent` must = 100.00. Show real-time total with green checkmark / red warning.

### Tab 3: Exam Weightage (SC-MSG-04)
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Per-Exam Weightage (within Examination component)   Total: [100%] ✅    │
│                                                                         │
│ Exam Group: Term-1 (UT-1, UT-2, HY-EXAM)                                │
├────────────────────┬───────────────┬────────────────────────────────────│
│ Exam Type          │ Weightage (%) │ Max Marks (from lms_exam_papers)   │
├────────────────────┼───────────────┼────────────────────────────────────│
│ UT-1 (Unit Test 1) │ [  10.00  ]   │ 10 (auto-detected)                 │
│ UT-2 (Unit Test 2) │ [  10.00  ]   │ 10 (auto-detected)                 │
│ HY-EXAM (Half Yr)  │ [  80.00  ]   │ 80 (auto-detected)                 │
├────────────────────┼───────────────┼────────────────────────────────────│
│                    │ Total: 100%   │                                    │
└────────────────────┴───────────────┴────────────────────────────────────│
└─────────────────────────────────────────────────────────────────────────┘
```

| Field | Type | DDL Column | Validation | Source |
|---|---|---|---|---|
| Exam Type | Label (read-only) | — | — | From `msh_exam_group_items_jnt` → `lms_exam_types.code + name` |
| Weightage % | Number Input | `msh_template_exam_weightages.weightage_percent` | Required, min:0.01, max:100 | Manual |
| Max Marks | Label (read-only) | `msh_template_exam_weightages.max_marks` | Auto-detected | From `lms_exam_papers.total_marks` for matching exam (informational) |

**Validation:** SUM of exam weightages must = 100.00. Rows are auto-populated from the linked exam group.

### Tab 4: IA Components (SC-MSG-05)
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Internal Assessment Components                     [+ Add Component]    │
├──────────────────────────┬───────────────┬──────────────────────────────┤
│ IA Component             │ Max Marks     │ Actions                      │
├──────────────────────────┼───────────────┼──────────────────────────────┤
│ Notebook Submission      │ [  5.00  ]    │ [↑] [↓] [Remove]             │
│ Subject Enrichment       │ [  5.00  ]    │ [↑] [↓] [Remove]             │
├──────────────────────────┼───────────────┼──────────────────────────────┤
│                          │ IA Total: 10  │                              │
└──────────────────────────┴───────────────┴──────────────────────────────┘
│ Note: IA marks are entered per subject per student by the teacher.      │
│ IA Total is added to the subject total alongside exam marks.            │
└─────────────────────────────────────────────────────────────────────────┘
```

| Field | Type | DDL Column | Validation | Source |
|---|---|---|---|---|
| IA Component Type | Dropdown | `msh_template_ia_components.ia_component_type_id` | Required | `msh_ia_component_types` WHERE `is_active=1` |
| Max Marks | Number Input | `msh_template_ia_components.max_marks` DECIMAL(5,2) | Required, min:0.5, max:100 | Manual |
| Display Order | Drag handle | `msh_template_ia_components.display_order` | Auto | Drag-drop reorder |

**Behaviour:** [+ Add Component] adds a new row with dropdown to select type. Types already added are excluded from dropdown.

### Tab 5: Co-Scholastic Setup (SC-MSG-06)
```
┌────────────────────────────────────────────────────────────────────────┐
│ Co-Scholastic Areas                               [+ Add Area]         │
├──────────────────────────┬────────────┬────────────┬───────────────────┤
│ Area                     │ Code       │ Grading    │ BA Linked?        │
├──────────────────────────┼────────────┼────────────┼───────────────────┤
│ Work Education           │ WORK_ED    │ 3-Point ▼  │ [ ]               │
│ Art Education            │ ART_ED     │ 3-Point ▼  │ [ ]               │
│ Health & Physical Ed     │ HEALTH_PE  │ 3-Point ▼  │ [ ]               │
│ Discipline               │ DISCIPLINE │ 3-Point ▼  │ [✓] Auto from BA  │
└──────────────────────────┴────────────┴────────────┴───────────────────┘
│ ⚠️ "BA Linked" pulls grade from BehaviouralAssessment module.          │
│    Only available if BA module is configured for this session.         │
└────────────────────────────────────────────────────────────────────────┘
```

| Field | Type | DDL Column | Validation | Source |
|---|---|---|---|---|
| Name | Text Input | `msh_template_coscholastic_components.name` | Required, max:100 | Manual |
| Code | Text Input | `msh_template_coscholastic_components.code` | Required, unique per template, max:30 | Auto-suggest from name |
| Grading Scale | Dropdown | `msh_template_coscholastic_components.grading_scale` | Required | Static: `3_POINT` (A/B/C), `5_POINT` (A/B/C/D/E) |
| BA Linked | Checkbox | `msh_template_coscholastic_components.is_ba_linked` | — | If checked, grade auto-populated from `BehaviouralScoreService`. Disable if `ba_config` not found |

---

## SC-MSG-07: Class/Group Template Assignment

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.config-templates.assign` |
| Controller | `ConfigTemplateController@assignToClass` |
| Table | `msh_class_config_jnt` |
| Actors | Super Admin, Principal |
| Permission | `msg.config.create` |

### Layout: Split Panel
```
┌────────────────────────────────────────────────────────────────────────┐
│ Template Assignment         Session: [2025-26 ▼]                       │
├──────────────────────────────┬─────────────────────────────────────────┤
│ TEMPLATES                    │ ASSIGNMENT MAP                          │
│                              │                                         │
│ ○ CBSE Primary Annual        │  CLASS GROUPS:                          │
│ ● CBSE Secondary Term-1  ◄──│─ ┌─ PRIMARY (1-5) ───────────────────┐   │
│ ○ CBSE Secondary Term-2     │  │  Template: CBSE Primary Annual    │   │
│ ○ CBSE Sr.Sec Annual        │  │  [Change ▼] [Remove]              │   │
│                              │  └──────────────────────────────────┘   │
│                              │  ┌─ SECONDARY (9-12) ───────────────┐   │
│                              │  │  Template: CBSE Secondary Term-1 │   │
│                              │  │  [Change ▼] [Remove]             │   │
│                              │  └──────────────────────────────────┘   │
│                              │                                         │
│                              │  CLASS OVERRIDES:                       │
│                              │  ┌─ Class 12 ───────────────────────┐   │
│                              │  │  Template: CBSE Sr.Sec Annual    │   │
│                              │  │  ⚠️ Overrides SECONDARY group    │   │
│                              │  │  [Change ▼] [Remove Override]    │   │
│                              │  └──────────────────────────────────┘   │
│                              │                                         │
│                              │  UNASSIGNED CLASSES:                    │
│                              │  ┌─ Class 6, Class 7, Class 8 ──────┐   │
│                              │  │  [Assign Template ▼]             │   │
│                              │  └──────────────────────────────────┘   │
│                              │                                         │
│                              │                            [Save All]   │
└──────────────────────────────┴─────────────────────────────────────────┘
```

### Data Sources
| Element | Source |
|---|---|
| Templates list (left panel) | `msh_config_templates` WHERE `academic_session_id` = selected session AND `is_active=1` |
| Class Groups (right panel) | `msh_class_groups` → `msh_class_group_items_jnt` → `sch_classes` |
| Current assignments | `msh_class_config_jnt` WHERE `config_template_id` IN (templates for this session) |
| Unassigned classes | `sch_classes` NOT IN any `msh_class_config_jnt` row AND NOT IN any `msh_class_group_items_jnt` that has a group assignment |

### Behaviour
- **Group assignment:** Assigns template to `class_group_id` in `msh_class_config_jnt`. Applies to all classes in the group.
- **Class override:** Assigns template to `class_id` in `msh_class_config_jnt`. Override badge shown with warning icon.
- **Inheritance display:** Group-level assignment shown with inherited classes listed inside the card.
- **Conflict:** A class cannot have both a direct assignment AND a group assignment to the SAME template. Direct wins and shows override badge.
- **Unassigned warning:** Classes with no assignment (direct or via group) shown in red "Unassigned" section.

---

## SC-MSG-08: Practical Configuration

### Screen Identity
| Item | Value |
|---|---|
| Route | `marksheet-generation.practical-configs.index` |
| Controller | `PracticalConfigController` |
| Table | `msh_subject_practical_configs` |
| Actors | Super Admin, Principal, Coordinator |
| Permission | `msg.practical.manage` |

### Layout: Class-Subject Grid
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Practical Exam Configuration     Session: [2025-26 ▼]       [Save All]  │
│                                  Class:   [Class 9   ▼]                 │
├─────────────────────┬─────────────┬─────────────┬───────────────────────┤
│ Subject             │ Has Pract.? │ Theory Max  │ Practical Max         │
├─────────────────────┼─────────────┼─────────────┼───────────────────────┤
│ English             │ [ ]         │ —           │ —                     │
│ Hindi               │ [ ]         │ —           │ —                     │
│ Mathematics         │ [ ]         │ —           │ —                     │
│ Science             │ [✓]         │ [  70.00 ]  │ [  30.00 ]            │
│ Social Science      │ [ ]         │ —           │ —                     │
│ Computer Science    │ [✓]         │ [  50.00 ]  │ [  50.00 ]            │
│ Physical Education  │ [✓]         │ [  30.00 ]  │ [  70.00 ]            │
└─────────────────────┴─────────────┴─────────────┴───────────────────────┘
│ Note: Theory + Practical must equal the exam paper total marks.         │
│ Only subjects with "Has Practical" checked will show split on marksheet.│
└─────────────────────────────────────────────────────────────────────────┘
```

### Field Mapping
| Field | Type | DDL Column | Validation | Source |
|---|---|---|---|---|
| Class | Dropdown (filter) | `msh_subject_practical_configs.class_id` | Required | `sch_classes` WHERE `is_active=1` ORDER BY `ordinal` |
| Subject | Label (row) | `msh_subject_practical_configs.subject_id` | — | `sch_subjects` linked to selected class via `sch_class_groups_jnt` |
| Has Practical | Checkbox | `msh_subject_practical_configs.has_practical` | — | If unchecked, Theory/Practical fields disabled |
| Theory Max | Number | `msh_subject_practical_configs.theory_max_marks` DECIMAL(5,2) | Required if has_practical, min:1 | Manual |
| Practical Max | Number | `msh_subject_practical_configs.practical_max_marks` DECIMAL(5,2) | Required if has_practical, min:1 | Manual |

### Behaviour
- Class dropdown changes → reload subject list for that class
- Checking "Has Practical" enables Theory Max + Practical Max inputs
- Theory + Practical should be validated at app level (informational warning, not hard block — actual paper total comes from `lms_exam_papers.total_marks`)
- [Save All] bulk-upserts all rows for the selected class in one request
- Existing configs loaded on class change; subjects with no config default to unchecked
