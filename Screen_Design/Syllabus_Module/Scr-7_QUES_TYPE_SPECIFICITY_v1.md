# Screen Design Specification: Question Type Specificity Management
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Question Type Specificity Management Module**, enabling administrators to configure when and how questions are used in the assessment workflow (In-Class, Homework, Summative, Formative). This classification affects visibility, grading rules, and learning analytics.

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

**Database Table:** slb_ques_type_specificity
├── id (INT PRIMARY KEY)
├── cognitive_skill_id (INT FK to slb_cognitive_skill, optional)
├── code (VARCHAR 20, UNIQUE) - e.g., 'IN_CLASS', 'HOMEWORK', 'SUMMATIVE'
├── name (VARCHAR 100) - Display name
├── description (VARCHAR 255) - Detailed explanation
└── Default codes: IN_CLASS, HOMEWORK, SUMMATIVE, FORMATIVE, DIAGNOSTIC

**Related Tables:**
- slb_cognitive_skill → Parent cognitive skill classification
- sch_questions → Questions classified by specificity
- sch_assessments → Assessment type mapping

---

## 2. SCREEN LAYOUTS

### 2.1 Question Type Specificity List Screen
**Route:** `/curriculum/settings/question-specificity`

#### 2.1.1 Page Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ ASSESSMENT SETTINGS > QUESTION TYPE SPECIFICITY                            │
├────────────────────────────────────────────────────────────────────────────┤
│   [Search ______________] [+ New Type] [Import] [Export]                   │
├────────────────────────────────────────────────────────────────────────────┤
│ Filter by Cognitive Skill: [All ▼]    Status: [All ▼]                      │
├────────────────────────────────────────────────────────────────────────────┤
│
│ QUESTION CONTEXT MATRIX
│ ┌─────────────────────┬──────────────┬──────────────┬──────────────┐
│ │ Type                │ In-Class     │ Homework     │ Summative    │
│ │                     │ (Formative)  │ (Practice)   │ (Graded)     │
│ ├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ │ Purpose             │ Classroom    │ Practice &   │ High-stakes  │
│ │                     │ engagement   │ review       │ assessment   │
│ ├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ │ Visibility          │ In-class     │ Home access  │ Controlled   │
│ │                     │ only         │              │ schedule     │
│ ├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ │ Grading             │ Optional     │ Optional     │ Required     │
│ ├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ │ Questions Used      │     287      │     156      │     245      │
│ └─────────────────────┴──────────────┴──────────────┴──────────────┘
│
├────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Code         │ Name         │ Purpose  | Cognitive Skill  │ Questions │
│────┼──────────────┼──────────────┼──────────┼──────────────────┼───────────│
│ ☐ │ IN_CLASS     │ In-Class     │ Classroom│ COG-RECALL       │   287     │
│ ☐ │ HOMEWORK     │ Homework     │ Practice │ COG-EXPLAIN      │   156     │
│ ☐ │ SUMMATIVE    │ Summative    │ Assessment│ Multiple        │   245     │
│ ☐ │ FORMATIVE    │ Formative    │ Progress │ Multiple        │   189     │
│ ☐ │ DIAGNOSTIC   │ Diagnostic   │ Baseline │ COG-RECALL       │    98     │
│
│ [+ Add Type] [Download Matrix] [Bulk Update]
│
└────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components & Interactions

**Context Matrix:**
- Visual grid showing relationship between specificity types
- Hover over cell → Show configuration details
- Click cell → Edit specificity settings

**Filter by Cognitive Skill:**
- Dropdown to filter shown types
- Shows only relevant specificity types per cognitive skill

**Buttons:**
- **[+ New Type]** – Add custom specificity type
- **[Import]** – Import from CSV/JSON
- **[Export]** – Export configuration

**Row Actions:**
- Click row → Detail view
- Inline edit for description
- Delete with warning

---

### 2.2 View Question Type Specificity Detail Screen
**Route:** `/curriculum/settings/question-specificity/{id}`

#### 2.2.1 Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ QUESTION TYPE SPECIFICITY > Homework       [Edit] [Delete]                │
├────────────────────────────────────────────────────────────────────────────┤
│ [Details] [Questions] [Assessment Usage] [Performance Analytics]           │
├────────────────────────────────────────────────────────────────────────────┤
│
│ DETAILS TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Code:                 HOMEWORK
│ Name:                 Homework
│
│ Cognitive Skill:      COG-EXPLAIN (Explanation)
│ └─ Part of Understanding level (Bloom Level 2)
│
│ Description:
│ └─ Questions provided as homework for student practice and review.
│    Used for formative assessment and skill reinforcement outside
│    the classroom. Typically not graded into final scores but tracked
│    for participation and completion metrics.
│
│ Configuration Settings:
│ ├─ Display Location:     Home/Outside Classroom
│ ├─ Time Limit:          No (unlimited)
│ ├─ Immediate Feedback:  Yes
│ ├─ Show Answers:        After Submission
│ ├─ Grading:             Optional
│ ├─ Counts Towards:      Participation (not final grade)
│ ├─ Plagiarism Check:    No
│ └─ Multiple Attempts:   Yes (unlimited)
│
│ Created At:           2024-01-15 10:00:00
│ Last Modified:        2024-12-10 09:30:00
│
│ [Edit] [Duplicate] [View Settings JSON]
│
├────────────────────────────────────────────────────────────────────────────┤
│ QUESTIONS TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Total Questions: 156 questions use this specificity type
│
│ Class: [All ▼]  Subject: [All ▼]  Difficulty: [All ▼]  [Filter]
│
│ ☐ │ Question | Type | Bloom | Difficulty | Subject │ Created Date │
│────┼──────────┼──────┼───────┼─────────────┼─────────┼──────────────│
│ ☐ │ Q1: Expl │ SA   │ U-2   │ Medium      │ Science │ 2024-12-08   │
│ ☐ │ Q2: How  │ LA   │ U-2   │ Hard        │ English │ 2024-12-07   │
│ ☐ │ Q3: Why  │ Essay│ U-2   │ Medium      │ SST     │ 2024-12-06   │
│
│ [Export Questions] [Reassign Type] [Bulk Update]
│
├────────────────────────────────────────────────────────────────────────────┤
│ ASSESSMENT USAGE TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Used in 34 assessments and quizzes
│
│ Assessment Type Distribution:
│ • Quizzes:        15 (Practice & Reinforcement)
│ • Homework Tasks: 12 (Skill Practice)
│ • Assessments:    7 (Formative)
│
│ Recent Assignments:
│ 1. Quiz: "Chapter 5 Review" - 8th Std Science  (2024-12-08)
│ 2. Assignment: "Grammar Practice" - 7th Std English  (2024-12-07)
│ 3. Homework: "Math Problem Set" - 6th Std Math  (2024-12-06)
│
│ [View All Assessments] [Download Report]
│
├────────────────────────────────────────────────────────────────────────────┤
│ PERFORMANCE ANALYTICS TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Student Performance on Homework Questions:
│
│ Average Score:          78.5%
│ Completion Rate:        92.3%
│ Time to Complete:       12-15 minutes (avg)
│
│ Skill Mastery Progression:
│ ┌─────────────────────────────────────────────────────────────┐
│ │ Student mastery improves by 8.5% on average after homework  │
│ │ Practice, indicating effectiveness of homework questions.   │
│ └─────────────────────────────────────────────────────────────┘
│
│ Top Performing Cohorts:
│ • Advanced Learners: 89.3% avg
│ • Average Learners:  78.5% avg
│ • At-Risk Learners:  68.2% avg
│
│ [Download Report] [View Detailed Analytics]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Create/Edit Question Type Specificity Modal
**Route:** `POST /curriculum/settings/question-specificity` or `PATCH /{id}`

#### 2.3.1 Layout
```
┌──────────────────────────────────────────────┐
│ NEW QUESTION TYPE SPECIFICITY          [✕]   │
├──────────────────────────────────────────────┤
│                                              │
│ Code *             [IN_CLASS_______]         │
│ (Uppercase, unique)                          │
│                                              │
│ Name *             [______________]          │
│ (Display name)                               │
│                                              │
│ Cognitive Skill    [All Cognitive Skills ▼] │
│ (Optional link)                              │
│                                              │
│ Description *      [______________]          │
│                    [                        ]│
│                                              │
│ Display Location   [◉ In-Class               │
│                    [◉ Home/Outside           │
│                    [◉ Both                   │
│                                              │
│ Time Limit         [◉ Yes [__ minutes]       │
│                    [◉ No (Unlimited)         │
│                                              │
│ Immediate Feedback [☑] Yes                   │
│ Show Answers       [Show After Submission ▼] │
│                                              │
│ Grading            [◉ Required               │
│                    [◉ Optional               │
│                    [◉ Not Graded             │
│                                              │
│ Multiple Attempts  [☑] Allow multiple        │
│ Max Attempts       [__]                      │
│                                              │
├──────────────────────────────────────────────┤
│           [Cancel]  [Save]  [Save & New]    │
└──────────────────────────────────────────────┘
```

#### 2.3.2 Field Specifications

| Field | Type | Validation | Placeholder | Required |
|-------|------|-----------|------------|----------|
| Code | Text | Max 20, unique, alphanumeric+underscore | "IN_CLASS" | ✓ |
| Name | Text | Max 100 chars | "In-Class Activity" | ✓ |
| Cognitive Skill | Dropdown | FK to slb_cognitive_skill | "All Skills" | ✗ |
| Description | TextArea | Max 500 chars | "Detailed description..." | ✓ |
| Display Location | Radio | in_class / home / both | N/A | ✓ |
| Time Limit | Toggle + Number | Yes/No + minutes | "No" | ✓ |
| Immediate Feedback | Checkbox | Boolean | Checked | ✗ |
| Show Answers | Dropdown | after_submit / never / specific_date | "After Submission" | ✓ |
| Grading | Radio | required / optional / not_graded | N/A | ✓ |
| Multiple Attempts | Checkbox | Boolean | Checked | ✗ |
| Max Attempts | Number | Positive int | "Unlimited" | ✗ |

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Question Type Specificity Request
```json
POST /api/v1/question-specificity
{
  "code": "HOMEWORK",
  "name": "Homework",
  "cognitive_skill_id": 2,
  "description": "Questions for home-based practice...",
  "display_location": "home",
  "time_limit_minutes": null,
  "immediate_feedback": true,
  "show_answers": "after_submission",
  "grading": "optional",
  "multiple_attempts": true,
  "max_attempts": null
}
```

### 3.2 Create Response
```json
{
  "success": true,
  "data": {
    "id": 2,
    "code": "HOMEWORK",
    "name": "Homework",
    "cognitive_skill_id": 2,
    "description": "Questions for home-based practice...",
    "configuration": {
      "display_location": "home",
      "time_limit_minutes": null,
      "immediate_feedback": true,
      "show_answers": "after_submission",
      "grading": "optional",
      "multiple_attempts": true,
      "max_attempts": null
    },
    "question_count": 156,
    "created_at": "2024-12-10T10:00:00Z"
  },
  "message": "Question type specificity created successfully"
}
```

### 3.3 List Request
```
GET /api/v1/question-specificity?cognitive_skill_id=2&limit=20
```

### 3.4 List Response
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "code": "IN_CLASS",
      "name": "In-Class",
      "cognitive_skill_id": 1,
      "description": "Classroom engagement questions...",
      "question_count": 287,
      "created_at": "2024-01-15T10:00:00Z"
    }
  ],
  "pagination": {
    "total": 5,
    "page": 1,
    "limit": 20
  }
}
```

### 3.5 Get Detail
```
GET /api/v1/question-specificity/{id}
```

### 3.6 Update
```json
PATCH /api/v1/question-specificity/{id}
{
  "description": "Updated description...",
  "time_limit_minutes": 30,
  "show_answers": "after_exam"
}
```

### 3.7 Delete
```
DELETE /api/v1/question-specificity/{id}
```

---

## 4. USER WORKFLOWS

### 4.1 Create Custom Question Type Specificity Workflow
**Goal:** Define new specificity type for organizational needs

1. Navigate to **Assessment Settings > Question Type Specificity**
2. Click **[+ New Type]**
3. Enter Code (e.g., "DIAGNOSTIC")
4. Enter Name (e.g., "Diagnostic Assessment")
5. Select linked Cognitive Skill (optional)
6. Enter Description
7. Configure display location, time limit, feedback rules
8. Set grading policy
9. Click **[Save]**
10. New type available for question classification

---

### 4.2 Assign Specificity Type to Questions Workflow
**Goal:** Classify questions by their instructional use

1. Open a question for editing
2. In question details, select "Question Type Specificity"
3. Choose from dropdown (IN_CLASS, HOMEWORK, SUMMATIVE, etc.)
4. System shows configuration details
5. Save question
6. Question now filtered/visible per specificity rules

---

### 4.3 View Questions by Specificity Type Workflow
**Goal:** See all questions used for specific context (e.g., homework)

1. Navigate to Question Type Specificity list
2. Click "HOMEWORK" specificity type
3. Open **[Questions]** tab
4. Filter by Class, Subject, Difficulty (optional)
5. View paginated question list
6. Export or reassign specificity type
7. View assessment usage (which quizzes use these questions)

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Color Coding by Type
- **IN_CLASS:** Blue (#1976D2)
- **HOMEWORK:** Green (#388E3C)
- **SUMMATIVE:** Red (#D32F2F)
- **FORMATIVE:** Orange (#F57C00)
- **DIAGNOSTIC:** Purple (#7B1FA2)

### 5.2 Typography
- Type Code: Monospace, 12px
- Type Name: Bold, 16px
- Description: Regular, 14px

### 5.3 Context Matrix
- Grid layout showing relationship between specificity types
- Color-coded cells for quick recognition
- Hover effects to reveal details

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 ARIA Labels
- Type buttons: aria-label="View Homework question specificity"
- Matrix cells: aria-label="In-Class type: 287 questions"

### 6.2 Keyboard Navigation
- Tab through types
- Enter to open detail
- Esc to close modals

### 6.3 Screen Reader Support
- Announce type code, name, question count
- Describe context matrix relationships in text

### 6.4 Responsive Design
- **Desktop:** Full context matrix
- **Tablet:** Stacked matrix, scrollable
- **Mobile:** Single column list

---

## 7. EDGE CASES & ERROR SCENARIOS

### 7.1 Delete Type with Active Questions
**Scenario:** User deletes HOMEWORK type with 156 questions
```
Warning: "156 questions use this type. Delete anyway?"
Options: [Cancel] [Delete and Reassign to IN_CLASS] [Delete Anyway]
```

### 7.2 Conflicting Configurations
**Scenario:** User enables time limit of 10 min with immediate feedback
```
Warning: "Time limit may prevent immediate feedback completion. Continue?"
Options: [Cancel] [Adjust] [Continue]
```

---

## 8. PERFORMANCE CONSIDERATIONS

- Question list: Paginate by 20 items
- Context matrix: Cache for 1 hour
- Search: Debounce 300ms
- Chart rendering: Use lightweight library
- Assessment usage: Query by type_id index

---

## 9. TESTING CHECKLIST

### 9.1 Functional Testing
- [ ] Create specificity type with all configurations
- [ ] Edit type and verify changes propagate
- [ ] Delete type (verify warning shown)
- [ ] View questions for each type
- [ ] Filter questions by class/subject
- [ ] Export question list
- [ ] Import specificity types from CSV
- [ ] View assessment usage
- [ ] Analytics calculations correct
- [ ] Time limit enforced in assessments
- [ ] Feedback rules applied correctly

### 9.2 UI/UX Testing
- [ ] Context matrix renders correctly
- [ ] Type cards show question count
- [ ] Modal form validates input
- [ ] Configuration JSON displays correctly
- [ ] Charts render smoothly
- [ ] Responsive layouts work on mobile

### 9.3 Integration Testing
- [ ] Create type → Available in question form
- [ ] Assign type to question → Searchable by type
- [ ] Delete type → Unassigns from questions
- [ ] Time limits enforced in assessment engine
- [ ] Feedback rules applied during grading

### 9.4 Accessibility Testing
- [ ] Tab order logical
- [ ] Color contrast ≥ 4.5:1
- [ ] Form labels associated
- [ ] Error messages linked to fields
- [ ] Keyboard navigation complete

---

## 10. FUTURE ENHANCEMENTS

- **Specificity Wizard:** Interactive guide to configure types
- **Template Library:** Pre-configured type templates
- **Audience Customization:** Different configs for different user groups
- **Automated Type Assignment:** AI suggests type based on question content
- **Type Analytics Dashboard:** Real-time performance metrics
- **Mobile-Optimized Specificity:** Configuration for mobile learners
- **Batch Configuration:** Update multiple questions' specificity at once

