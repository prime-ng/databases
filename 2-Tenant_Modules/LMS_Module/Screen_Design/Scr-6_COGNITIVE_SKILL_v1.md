# Screen Design Specification: Cognitive Skills Management
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Cognitive Skills Management Module**, enabling administrators to define and manage cognitive skill categories that students develop through learning. Cognitive skills are mapped to Bloom's taxonomy levels and linked to questions for competency-based assessment.

### 1.2 User Roles & Permissions
| Role         | Create | View | Update | Delete | Print | Export | Import |
|--------------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| PG Support   |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| School Admin |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Principal    |   ✗    |   ✓  |   ✗    |   ✗    |   ✓   |   ✗    |   ✗    |
| Teacher      |   ✗    |   ✓  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |
| Student      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |
| Parents      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |

### 1.3 Data Context

**Database Table:** slb_cognitive_skill
├── id (INT PRIMARY KEY)
├── bloom_id (INT FK to slb_bloom_taxonomy) - Links to Bloom level (1-6)
├── code (VARCHAR 20, UNIQUE) - e.g., 'COG-RECALL', 'COG-ANALYSIS'
├── name (VARCHAR 100) - Skill name
├── description (VARCHAR 255) - Skill definition
└── Indexed: bloom_id for fast filtering

**Related Tables:**
- slb_bloom_taxonomy → Parent taxonomy level
- slb_ques_type_specificity → Question specificity filters
- sch_questions → Cognitive skill classification
- sch_student_learning_outcomes → Student progress tracking

---

## 2. SCREEN LAYOUTS

### 2.1 Cognitive Skills List Screen
**Route:** `/curriculum/settings/cognitive-skills`

#### 2.1.1 Page Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ ASSESSMENT SETTINGS > COGNITIVE SKILLS                                     │
├────────────────────────────────────────────────────────────────────────────┤
│   [Search Skills _______________] [+ New Skill]  [Import] [Export]         │
├────────────────────────────────────────────────────────────────────────────┤
│ Filter by Bloom Level: [All ▼]  Group by: [Bloom Level] [Alphabetical]    │
├────────────────────────────────────────────────────────────────────────────┤
│
│ LEVEL 1: REMEMBERING
│ ──────────────────────────────────────────────────────────────────────────
│ ☐ │ Code          │ Name              │ Description            │ Questions │
│────┼───────────────┼───────────────────┼────────────────────────┼───────────│
│ ☐ │ COG-RECALL    │ Immediate Recall  │ Retrieving facts...    │    156    │
│ ☐ │ COG-RECOGNIZE │ Recognition       │ Identifying from set... │    89    │
│
│ LEVEL 2: UNDERSTANDING
│ ──────────────────────────────────────────────────────────────────────────
│ ☐ │ COG-EXPLAIN   │ Explanation       │ Clarifying concepts... │    142    │
│ ☐ │ COG-SUMMARIZE │ Summarization     │ Condensing info...     │    98     │
│ ☐ │ COG-CLASSIFY  │ Classification    │ Grouping by criteria.. │    67     │
│
│ LEVEL 3: APPLYING
│ ──────────────────────────────────────────────────────────────────────────
│ ☐ │ COG-EXECUTE   │ Execution         │ Using in new context.. │    124    │
│ ☐ │ COG-IMPLEMENT │ Implementation    │ Applying procedures... │    78     │
│
│ [+ Add New Skill] [Download Report] [Bulk Actions ▼]
│
└────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components & Interactions

**Filter by Bloom Level:**
- Dropdown options: All, Remembering, Understanding, Applying, Analyzing, Evaluating, Creating
- Default: All
- Auto-groups skills by selected level

**Group By Options:**
- By Bloom Level (default)
- Alphabetical by name
- By question count

**Buttons:**
- **[+ New Skill]** – Opens Create Skill Modal
- **[Import]** – Bulk import from CSV/JSON
- **[Export]** – Export skills to CSV/PDF

**Row Actions:**
- Click row → View detail
- Hover → Show [Edit] [Delete] buttons
- Bulk select via checkbox

---

### 2.2 View Cognitive Skill Detail Screen
**Route:** `/curriculum/settings/cognitive-skills/{id}`

#### 2.2.1 Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ COGNITIVE SKILL > COG-RECALL (Immediate Recall)           [Edit] [Delete]  │
├────────────────────────────────────────────────────────────────────────────┤
│ [Details] [Questions] [Student Progress] [Activity Log]                    │
├────────────────────────────────────────────────────────────────────────────┤
│
│ DETAILS TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Code:                  COG-RECALL
│ Name:                  Immediate Recall
│
│ Bloom Level:           1 - REMEMBERING
│ └─ Part of the foundational cognitive level in Bloom's taxonomy
│
│ Description:
│ └─ The ability to retrieve specific facts and basic concepts from memory.
│    This is the simplest form of cognitive skill, requiring students to
│    recognize and recall information without interpretation or elaboration.
│
│ Associated Question Types:
│ └─ Fill in the Blanks, Matching, True/False, MCQ (definition-based)
│
│ Created At:            2024-01-15 10:00:00
│ Last Modified:         2024-12-10 09:30:00
│
│ [Edit] [Duplicate] [Export Details]
│
├────────────────────────────────────────────────────────────────────────────┤
│ QUESTIONS TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Total Questions Using This Skill: 156 questions
│
│ Class: [All ▼]  Subject: [All ▼]  Difficulty: [All ▼]  [Filter]
│
│ ☐ │ Question | Type | Class | Subject | Difficulty | Last Used │
│────┼──────────┼──────┼───────┼─────────┼─────────────┼───────────│
│ ☐ │ Q1: Name │ FB   │ 6th   │ Science │ Easy        │ 2024-12-08│
│ ☐ │ Q2: List │ MCQ  │ 7th   │ Math    │ Easy        │ 2024-12-07│
│ ☐ │ Q3: Reca │ FB   │ 8th   │ English │ Easy        │ 2024-12-06│
│
│ [Export Questions] [Assign to Assessment] [Download Report]
│
├────────────────────────────────────────────────────────────────────────────┤
│ STUDENT PROGRESS TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Students Assessed on This Skill: 1,245 students
│ Average Mastery: 78.5%
│
│ Mastery Distribution:
│ • Not Started:  12% (149 students)
│ • In Progress:  35% (435 students)
│ • Proficient:   40% (498 students)
│ • Mastered:     13% (162 students)
│
│ [View Student List] [Download Report] [Export Data]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Create/Edit Cognitive Skill Modal
**Route:** `POST /curriculum/settings/cognitive-skills` or `PATCH /{id}`

#### 2.3.1 Layout
```
┌──────────────────────────────────────────────────────┐
│ NEW COGNITIVE SKILL                            [✕]   │
├──────────────────────────────────────────────────────┤
│                                                      │
│ Bloom Level *       [Understanding ▼]               │
│ (Select parent level)                               │
│                                                      │
│ Code *              [COG-_________________]          │
│ (Uppercase, unique, e.g., COG-RECALL)               │
│                                                      │
│ Name *              [__________________]             │
│ (Display name, max 100 chars)                        │
│                                                      │
│ Description         [__________________]             │
│                     [                              ]│
│ (Detailed skill definition)                         │
│                                                      │
│ Question Types      [☑] Fill in Blanks              │
│ (Applicable types)  [☑] Multiple Choice             │
│                     [☐] True/False                  │
│                     [☐] Short Answer                │
│                     [☐] Matching                    │
│                                                      │
├──────────────────────────────────────────────────────┤
│              [Cancel]  [Save]  [Save & New]         │
└──────────────────────────────────────────────────────┘
```

#### 2.3.2 Field Specifications

| Field | Type | Validation | Placeholder | Required |
|-------|------|-----------|------------|----------|
| Bloom Level | Dropdown | FK to slb_bloom_taxonomy | "Select Bloom Level" | ✓ |
| Code | Text | Max 20, alphanumeric | "COG-RECALL" | ✓ |
| Name | Text | Max 100 chars | "Immediate Recall" | ✓ |
| Description | TextArea | Max 500 chars | "Skill definition..." | ✓ |
| Question Types | Checkbox | Multi-select | N/A | ✗ |

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Cognitive Skill Request
```json
POST /api/v1/cognitive-skills
{
  "bloom_id": 1,
  "code": "COG-RECALL",
  "name": "Immediate Recall",
  "description": "The ability to retrieve specific facts and basic concepts...",
  "question_types": ["FILL_BLANK", "MATCHING", "TRUE_FALSE"]
}
```

### 3.2 Create Cognitive Skill Response
```json
{
  "success": true,
  "data": {
    "id": 1,
    "bloom_id": 1,
    "bloom": {
      "id": 1,
      "code": "REMEMBERING",
      "name": "Remembering"
    },
    "code": "COG-RECALL",
    "name": "Immediate Recall",
    "description": "The ability to retrieve specific facts...",
    "question_types": ["FILL_BLANK", "MATCHING", "TRUE_FALSE"],
    "created_at": "2024-12-10T10:00:00Z"
  },
  "message": "Cognitive skill created successfully"
}
```

### 3.3 List Cognitive Skills Request
```
GET /api/v1/cognitive-skills?bloom_id=1&group_by=bloom&limit=50
```

### 3.4 List Cognitive Skills Response
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "bloom_id": 1,
      "code": "COG-RECALL",
      "name": "Immediate Recall",
      "description": "The ability to retrieve specific facts...",
      "question_count": 156,
      "created_at": "2024-01-15T10:00:00Z"
    }
  ],
  "pagination": {
    "total": 18,
    "page": 1,
    "limit": 50
  }
}
```

### 3.5 Get Cognitive Skill Detail
```
GET /api/v1/cognitive-skills/{id}
```

### 3.6 Update Cognitive Skill
```json
PATCH /api/v1/cognitive-skills/{id}
{
  "description": "Updated description...",
  "question_types": ["FILL_BLANK", "MCQ", "MATCHING"]
}
```

### 3.7 Delete Cognitive Skill
```
DELETE /api/v1/cognitive-skills/{id}
Response:
{
  "success": true,
  "message": "Cognitive skill deleted. 156 questions reassigned."
}
```

---

## 4. USER WORKFLOWS

### 4.1 Create New Cognitive Skill Workflow
**Goal:** Add a new cognitive skill for assessment purposes

1. Navigate to **Assessment Settings > Cognitive Skills**
2. Click **[+ New Skill]** button
3. Select Bloom Level from dropdown (e.g., "Remembering")
4. Enter Code (e.g., "COG-RECALL")
5. Enter Name (e.g., "Immediate Recall")
6. Add Description explaining the skill
7. Select applicable Question Types
8. Click **[Save]**
9. System validates uniqueness of code
10. Skill appears in list grouped under its Bloom level

---

### 4.2 Assign Cognitive Skill to Questions Workflow
**Goal:** Filter and view questions classified under a skill

1. Open Cognitive Skill detail view
2. Click **[Questions]** tab
3. System displays all questions tagged with this skill
4. (Optional) Filter by Class, Subject, Difficulty
5. View question count and usage statistics
6. Export question list or assign to assessment

---

### 4.3 Track Student Progress by Cognitive Skill Workflow
**Goal:** Monitor which students have mastered this cognitive skill

1. Open Cognitive Skill detail
2. Click **[Student Progress]** tab
3. View mastery distribution chart
4. Filter by Class, Subject, Assessment period
5. Click on mastery segment (e.g., "Mastered" = 162 students)
6. View individual student scores and attempts
7. Export report for further analysis

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Color Coding
- Bloom Level background in header: Color-coded to level (per Bloom module)
- Skill name: Bold, dark gray (#333)
- Question count badge: Rounded, primary blue with white text

### 5.2 Typography
- Skill Code: Monospace font (Courier), 12px
- Skill Name: Bold, 16px
- Description: Regular, 14px
- Meta info: Light gray, 12px

### 5.3 Grouping Visualization
- Grouped by Bloom Level with collapsible sections
- Skill cards indent slightly under level headers
- Clear visual separation between levels

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 ARIA Labels
- Skill links: aria-label="View cognitive skill COG-RECALL"
- Bloom level groups: aria-label="Level 1: Remembering skills group, 3 skills"
- Checkboxes: aria-label="Select COG-RECALL for bulk action"

### 6.2 Keyboard Navigation
- Tab through all skills
- Enter to select/open detail
- Arrow keys to expand/collapse groups
- Esc to close modals

### 6.3 Screen Reader Support
- Announce skill code, name, and Bloom level
- Read question count clearly
- Describe mastery distribution as text + visualization

### 6.4 Responsive Design
- **Desktop:** Grouped table with expandable sections
- **Tablet:** Single column, collapsible Bloom level groups
- **Mobile:** Stacked cards, one skill per row

---

## 7. EDGE CASES & ERROR SCENARIOS

### 7.1 Duplicate Code
**Scenario:** User creates skill with code that already exists
```
Error: "Code 'COG-RECALL' already exists. Please use a unique code."
Action: Highlight code field, suggest COG-RECALL-2
```

### 7.2 Delete Skill with Active Questions
**Scenario:** User deletes skill linked to 156 questions
```
Warning: "This skill is used by 156 questions. Delete anyway?"
Options: [Cancel] [Delete and Reassign] [Delete Anyway]
```

### 7.3 Orphaned Skills
**Scenario:** Bloom level deleted; orphan cognitive skills remain
```
Action: Auto-reassign skills to similar level or mark as disabled
Message: "3 skills reassigned from deleted Bloom level"
```

---

## 8. PERFORMANCE CONSIDERATIONS

- Question list: Paginate at 20 per page
- Student progress: Cache calculations (update hourly)
- Search: Debounce by 300ms
- Chart rendering: Use lightweight library (Chart.js or similar)
- Grouping: Use backend aggregation, not frontend filtering

---

## 9. TESTING CHECKLIST

### 9.1 Functional Testing
- [ ] Create skill with all required fields
- [ ] Create skill with Bloom level auto-selected
- [ ] Edit skill description and question types
- [ ] Delete skill (verify warning if questions exist)
- [ ] Search skills by code/name (case-insensitive)
- [ ] Filter by Bloom level
- [ ] Group by Bloom level/alphabetical
- [ ] View all questions for a skill
- [ ] Pagination in questions list
- [ ] Export skills to CSV
- [ ] Import skills from CSV
- [ ] Bulk delete skills
- [ ] View student progress by skill

### 9.2 UI/UX Testing
- [ ] Grouped sections expand/collapse smoothly
- [ ] Question count badge displays correctly
- [ ] Modal appears and closes smoothly
- [ ] Form validation real-time
- [ ] Success message shows on save
- [ ] Error messages clear and actionable

### 9.3 Integration Testing
- [ ] Create skill → Appears in Bloom level group
- [ ] Link skill to question → Question searchable by skill
- [ ] Delete skill → Questions lose skill assignment
- [ ] Reassign questions on skill delete
- [ ] Student progress auto-calculates

### 9.4 Accessibility Testing
- [ ] Tab order logical
- [ ] Skill codes readable in monospace
- [ ] Color contrast ≥ 4.5:1
- [ ] Form labels associated with inputs
- [ ] Error messages linked to fields
- [ ] Charts have text alternative

---

## 10. FUTURE ENHANCEMENTS

- **Skill Tree Visualization:** Interactive tree showing skill hierarchies
- **Proficiency Rubrics:** Define mastery thresholds per skill
- **Skill Recommendations:** Suggest next skills based on mastery
- **Competency Mapping:** Link skills to NEP competencies
- **Adaptive Learning Paths:** Auto-generate paths based on skill gaps
- **Mobile Skill Tracker:** Standalone app for student skill tracking
- **Real-time Skill Dashboards:** Teacher dashboard showing class skill progress

---

## APPENDIX

### A. Standard Cognitive Skills by Bloom Level

| Level | Code | Name | Question Types |
|-------|------|------|-----------------|
| 1 | COG-RECALL | Immediate Recall | Fill Blanks, Matching |
| 1 | COG-RECOGNIZE | Recognition | MCQ, True/False |
| 2 | COG-EXPLAIN | Explanation | Short Answer, Essay |
| 2 | COG-SUMMARIZE | Summarization | Short Answer |
| 2 | COG-CLASSIFY | Classification | MCQ, Matching |
| 3 | COG-EXECUTE | Execution | Application Problem |
| 3 | COG-IMPLEMENT | Implementation | Project, Case Study |
| 4 | COG-COMPARE | Comparison | Essay, Long Answer |
| 4 | COG-DIFFERENTIATE | Differentiation | Long Answer |
| 5 | COG-JUDGE | Judgment | Essay, Critique |
| 5 | COG-DEFEND | Defense | Debate, Essay |
| 6 | COG-DESIGN | Design | Project, Creation |
| 6 | COG-INVENT | Invention | Open-ended Problem |

