# Screen Design Specification: Question Types Management
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Question Types Management Module**, enabling administrators to configure and manage different question formats (MCQ Single Select, MCQ Multiple Select, Short Answer, Long Answer, Matching, Fill in Blanks, Numeric, Coding). Each type has unique rendering, grading, and analytics requirements.

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

**Database Table:** slb_question_types
├── id (INT PRIMARY KEY)
├── code (VARCHAR 30, UNIQUE) - e.g., 'MCQ_SINGLE', 'SHORT_ANSWER'
├── name (VARCHAR 100) - Display name
├── has_options (BOOLEAN) - Does type support options?
├── auto_gradable (BOOLEAN) - Can system auto-grade?
├── description (TEXT) - Type definition
└── Indexed: code, auto_gradable for filtering

**Related Tables:**
- sch_questions → Questions by type
- sch_question_options → Options for MCQ, Matching, etc.
- sch_attempt_answers → Student responses

---

## 2. SCREEN LAYOUTS

### 2.1 Question Types List Screen
**Route:** `/curriculum/settings/question-types`

#### 2.1.1 Page Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ ASSESSMENT SETTINGS > QUESTION TYPES                                       │
├────────────────────────────────────────────────────────────────────────────┤
│   [Search ______________] [+ New Type]  [Import] [Export]                  │
├────────────────────────────────────────────────────────────────────────────┤
│ Filter: [Has Options: All ▼] [Auto-Gradable: All ▼] [Status: Active ▼]    │
├────────────────────────────────────────────────────────────────────────────┤
│
│ QUESTION TYPES OVERVIEW
│
│ ┌────────────────────────┐  ┌────────────────────────┐  ┌─────────────────┐
│ │  AUTO-GRADABLE TYPES   │  │  MANUAL GRADING TYPES  │  │  HYBRID TYPES   │
│ ├────────────────────────┤  ├────────────────────────┤  ├─────────────────┤
│ │ • MCQ Single           │  │ • Short Answer         │  │ • Numeric       │
│ │ • MCQ Multiple         │  │ • Long Answer (Essay)  │  │ • Fill Blanks   │
│ │ • True/False           │  │ • Coding               │  │ • Matching      │
│ │ • Matching             │  │                        │  │                 │
│ │ • Fill Blanks          │  │ Can use rubrics and    │  │ Semi-auto or    │
│ │                        │  │ manual marking         │  │ auto-grading    │
│ │ System marks instantly │  │                        │  │                 │
│ └────────────────────────┘  └────────────────────────┘  └─────────────────┘
│
├────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Code            │ Name         │ Has Opts │ Auto-Grad │ Questions │
│────┼─────────────────┼──────────────┼──────────┼───────────┼───────────│
│ ☐ │ MCQ_SINGLE      │ MCQ (Single) │ Yes      │ Yes       │   1204    │
│ ☐ │ MCQ_MULTI       │ MCQ (Multi)  │ Yes      │ Yes       │    687    │
│ ☐ │ SHORT_ANSWER    │ Short Answer │ No       │ No        │    532    │
│ ☐ │ LONG_ANSWER     │ Long Answer  │ No       │ No        │    289    │
│ ☐ │ FILL_BLANK      │ Fill Blanks  │ Yes      │ Yes       │    456    │
│ ☐ │ MATCHING        │ Matching     │ Yes      │ Yes       │    234    │
│ ☐ │ NUMERIC         │ Numeric      │ No       │ Yes       │    178    │
│ ☐ │ CODING          │ Coding       │ No       │ No        │     67    │
│ ☐ │ TRUE_FALSE      │ True/False   │ Yes      │ Yes       │    912    │
│
│ [Download Type Guide] [View Grading Rules] [Bulk Update]
│
└────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components & Interactions

**Type Overview:**
- Grouped by grading category
- Visual boxes showing type characteristics
- Click to expand details

**Filter Options:**
- Has Options: Yes, No, All
- Auto-Gradable: Yes, No, All
- Status: Active, Inactive, All

**Buttons:**
- **[+ New Type]** – Create custom question type
- **[Import]** – Import type definitions
- **[Export]** – Export to CSV

**Row Actions:**
- Click → Detail view
- Hover → Show [Edit] [View Questions] [Delete]

---

### 2.2 View Question Type Detail Screen
**Route:** `/curriculum/settings/question-types/{id}`

#### 2.2.1 Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ QUESTION TYPE > MCQ (Single Select)              [Edit] [Delete]           │
├────────────────────────────────────────────────────────────────────────────┤
│ [Details] [Questions] [Grading Rules] [Sample] [Usage Statistics]          │
├────────────────────────────────────────────────────────────────────────────┤
│
│ DETAILS TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Code:                 MCQ_SINGLE
│ Name:                 Multiple Choice Question (Single Select)
│
│ Classification:
│ ├─ Has Options:      Yes
│ ├─ Auto-Gradable:    Yes (Instant feedback possible)
│ ├─ Grading Method:   Exact match
│ └─ Max Points:       Custom per question
│
│ Description:
│ └─ Student selects one correct answer from multiple options. This is the
│    most common question type for objective assessment. Supports immediate
│    feedback and automated grading based on correct option(s).
│
│ Type Characteristics:
│ • Can have 2-10 options per question
│ • Only one option marked as correct
│ • Optional distractor labels (plausible, impossible)
│ • Supports image/rich media options
│ • Can randomize option order per student
│
│ Grading Configuration:
│ ├─ Scoring:         All-or-nothing (full marks or zero)
│ ├─ Negative Marks:  Configurable per question
│ ├─ Partial Credit:  Not applicable
│ └─ Appeal Process:  Supported (question review)
│
│ Typical Bloom Levels: Remembering, Understanding, Applying, Analyzing
│
│ Typical Complexity: Easy to Difficult (depends on option distractors)
│
│ Use in Assessments:
│ ├─ Quizzes:          High usage (80% of quiz questions)
│ ├─ Exams:            Very high usage (85% of exam questions)
│ ├─ Formative Tests:  High usage (75% of formative)
│ └─ Summative Tests:  Very high usage (85% of summative)
│
│ Technical Requirements:
│ ├─ Display:         Single column layout with radio buttons
│ ├─ Rendering:       Fast (minimal JS required)
│ ├─ Mobile Support:  Excellent
│ └─ Accessibility:   Excellent (native form controls)
│
│ Created At:           2024-01-15 10:00:00
│ Last Modified:        2024-12-10 09:30:00
│
│ [Edit] [Duplicate] [View Configuration JSON]
│
├────────────────────────────────────────────────────────────────────────────┤
│ QUESTIONS TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Total Questions of This Type: 1,204 questions
│
│ Class: [All ▼]  Subject: [All ▼]  Difficulty: [All ▼]  [Filter]
│
│ ☐ │ Question | Bloom | Difficulty │ Subject │ Options │ Last Used │
│────┼──────────┼───────┼─────────────┼─────────┼─────────┼───────────│
│ ☐ │ Q1: Which│ Rem   │ Easy        │ Science │ 4       │ 2024-12-09│
│ ☐ │ Q2: What │ Und   │ Medium      │ Math    │ 5       │ 2024-12-08│
│ ☐ │ Q3: Why  │ Ana   │ Hard        │ English │ 4       │ 2024-12-07│
│
│ [Export Questions] [Reassign Type] [View Performance]
│
├────────────────────────────────────────────────────────────────────────────┤
│ GRADING RULES TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Automatic Grading Configuration:
│
│ Scoring Method:       All-or-Nothing
│ └─ Full marks if answer correct, zero otherwise
│
│ Partial Credit:       Not Applicable
│
│ Negative Marking:     Configurable per question
│ └─ Example: -0.25 marks for incorrect answer (reduces random guessing)
│
│ Case Sensitivity:     N/A (options are presented)
│ Whitespace Handling:  N/A
│
│ Appeals/Reviews:      Supported
│ └─ Teachers can review student responses if question marked incorrect
│
│ Special Rules:        None
│
├────────────────────────────────────────────────────────────────────────────┤
│ SAMPLE TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Example MCQ Question:
│
│ Q: What is the capital of France?
│
│ A) Paris          [Selected]
│ B) Lyon
│ C) Marseille
│ D) Nice
│
│ ✓ Correct! The capital of France is Paris.
│
│ ┌─────────────────────────────────────────────────────────────┐
│ │ Rendering: Single column with radio buttons (mobile-friendly)│
│ │ Time Limit: Optional (teacher-configurable)                 │
│ │ Show Explanation: Yes (teacher can provide feedback)        │
│ └─────────────────────────────────────────────────────────────┘
│
├────────────────────────────────────────────────────────────────────────────┤
│ USAGE STATISTICS TAB
│ ──────────────────────────────────────────────────────────────────────────
│ MCQ Single Usage Trends:
│
│ Total Questions:      1,204
│ Questions Used:       1,089 (90%)
│ Questions Unused:     115 (10%)
│
│ Monthly Usage:
│ ┌─────────────────────────────────────────────────────────────┐
│ │ Oct: 1,050  Nov: 1,075  Dec: 1,089  Trend: ↑ Growing     │
│ └─────────────────────────────────────────────────────────────┘
│
│ Subject Distribution:
│ • Science:    324 questions (27%)
│ • Math:       389 questions (32%)
│ • English:    245 questions (20%)
│ • SST:        246 questions (20%)
│
│ Performance Metrics:
│ • Avg Student Score:      82.1% (high - good for assessment)
│ • Question Discrimination: 0.45 (good - differentiates learners)
│ • Difficulty Index:        0.82 (easy - good for confidence)
│
│ [Download Report] [View Trends Chart]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Create/Edit Question Type Modal
**Route:** `POST /curriculum/settings/question-types` or `PATCH /{id}`

#### 2.3.1 Layout
```
┌──────────────────────────────────────────────────┐
│ NEW QUESTION TYPE                          [✕]   │
├──────────────────────────────────────────────────┤
│                                                  │
│ Code *                [MCQ_SINGLE_]              │
│ (Unique, uppercase, max 30 chars)                │
│                                                  │
│ Name *                [_________________]        │
│ (Display name, max 100 chars)                    │
│                                                  │
│ Description *         [_________________]        │
│                       [                         ]│
│                       [                         ]│
│ (Detailed explanation)                           │
│                                                  │
│ Has Options           [☑] Yes                    │
│ (Can define choices?)  [☐] No                    │
│                                                  │
│ Max Options           [__] (if yes above)        │
│ (Maximum allowed options)                        │
│                                                  │
│ Auto-Gradable         [◉] Yes                    │
│ (System can grade?)    [◉] No                    │
│                                                  │
│ Grading Method        [Exact Match ▼]            │
│ (if auto-gradable)    Options: Exact, Fuzzy      │
│                                                  │
│ Supports Images       [☑] Yes                    │
│ (Can options have images?)                       │
│                                                  │
│ Mobile-Optimized      [☑] Yes                    │
│ (Renders well on phones?)                        │
│                                                  │
│ Randomize Options     [☑] Supported              │
│ (Can order be randomized?)                       │
│                                                  │
├──────────────────────────────────────────────────┤
│              [Cancel]  [Save]  [Save & New]     │
└──────────────────────────────────────────────────┘
```

#### 2.3.2 Field Specifications

| Field | Type | Validation | Placeholder | Required |
|-------|------|-----------|------------|----------|
| Code | Text | Max 30, unique, alphanumeric+underscore | "MCQ_SINGLE" | ✓ |
| Name | Text | Max 100 chars | "Multiple Choice (Single)" | ✓ |
| Description | TextArea | Max 500 chars | "Type definition..." | ✓ |
| Has Options | Checkbox | Boolean | Checked | ✓ |
| Max Options | Number | 2-20 (if has_options) | "5" | ✗ |
| Auto-Gradable | Radio | Yes/No | "Yes" | ✓ |
| Grading Method | Dropdown | Exact, Fuzzy, Partial | "Exact Match" | ✗ |
| Supports Images | Checkbox | Boolean | Checked | ✗ |
| Mobile-Optimized | Checkbox | Boolean | Checked | ✗ |
| Randomize Options | Checkbox | Boolean | Checked | ✗ |

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Question Type Request
```json
POST /api/v1/question-types
{
  "code": "MCQ_SINGLE",
  "name": "Multiple Choice Question (Single Select)",
  "description": "Student selects one correct answer from multiple options...",
  "has_options": true,
  "max_options": 8,
  "auto_gradable": true,
  "grading_method": "exact_match",
  "supports_images": true,
  "mobile_optimized": true,
  "randomize_options": true
}
```

### 3.2 Create Response
```json
{
  "success": true,
  "data": {
    "id": 1,
    "code": "MCQ_SINGLE",
    "name": "Multiple Choice Question (Single Select)",
    "description": "Student selects one correct answer...",
    "has_options": true,
    "max_options": 8,
    "auto_gradable": true,
    "grading_method": "exact_match",
    "supports_images": true,
    "mobile_optimized": true,
    "randomize_options": true,
    "question_count": 1204,
    "created_at": "2024-12-10T10:00:00Z"
  },
  "message": "Question type created successfully"
}
```

### 3.3 List Request
```
GET /api/v1/question-types?has_options=true&auto_gradable=true&limit=50
```

### 3.4 List Response
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "code": "MCQ_SINGLE",
      "name": "Multiple Choice Question (Single Select)",
      "has_options": true,
      "auto_gradable": true,
      "question_count": 1204,
      "created_at": "2024-01-15T10:00:00Z"
    }
  ],
  "pagination": {
    "total": 9,
    "page": 1,
    "limit": 50
  }
}
```

### 3.5 Get Detail
```
GET /api/v1/question-types/{id}
```

### 3.6 Update
```json
PATCH /api/v1/question-types/{id}
{
  "description": "Updated description...",
  "max_options": 10
}
```

### 3.7 Delete
```
DELETE /api/v1/question-types/{id}
```

---

## 4. USER WORKFLOWS

### 4.1 Create Custom Question Type Workflow
**Goal:** Define new question format not in standard list

1. Navigate to **Assessment Settings > Question Types**
2. Click **[+ New Type]**
3. Enter Code (e.g., "ESSAY_SHORT")
4. Enter Name and Description
5. Configure: Has options, Auto-gradable, Grading method
6. Specify rendering options (mobile-optimized, randomize, etc.)
7. Click **[Save]**
8. Type available for question creation

---

### 4.2 View All Questions of a Type Workflow
**Goal:** See which questions use specific question type

1. Open Question Type detail view
2. Click **[Questions]** tab
3. System displays all questions of this type
4. Filter by Class, Subject, Difficulty
5. View performance statistics
6. Export question list or reassign type
7. Identify rarely-used questions for archiving

---

### 4.3 Understand Grading Rules for a Type Workflow
**Goal:** Learn how questions are graded automatically

1. Open Question Type detail
2. Click **[Grading Rules]** tab
3. View scoring method (all-or-nothing, partial, etc.)
4. See negative marking policy
5. Check if appeals allowed
6. Review special grading rules
7. Download grading guide for teachers

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Color Coding by Category
- **Auto-Gradable:** Green (#4CAF50)
- **Manual Grading:** Orange (#FF9800)
- **Hybrid:** Blue (#2196F3)

### 5.2 Typography
- Type Code: Monospace, 12px, bold
- Type Name: Sans-serif, 16px, bold
- Description: Regular, 14px
- Meta info: Light gray, 12px

### 5.3 Overview Layout
- Three category boxes showing type grouping
- Icons indicating auto-grading capability
- Usage counts for each type

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 ARIA Labels
- Type cards: aria-label="MCQ Single Select: 1204 questions, auto-gradable"
- Category groups: aria-label="Auto-gradable question types group"

### 6.2 Keyboard Navigation
- Tab through all question types
- Enter to open detail
- Arrow keys to navigate categories
- Esc to close modals

### 6.3 Screen Reader Support
- Announce type name, code, question count
- Describe grading method clearly
- Read usage statistics as text

### 6.4 Responsive Design
- **Desktop:** Three-column overview boxes
- **Tablet:** Two-column overview boxes
- **Mobile:** Single column with expandable sections

---

## 7. EDGE CASES & ERROR SCENARIOS

### 7.1 Delete Type with Active Questions
**Scenario:** User deletes MCQ_SINGLE with 1,204 questions
```
Warning: "1,204 questions use this type. Delete anyway?"
Options: [Cancel] [Delete and Reassign] [Delete Anyway]
Action: Reassign to similar type or keep as untyped
```

### 7.2 Invalid Grading Method
**Scenario:** User selects "Fuzzy Match" for True/False type
```
Warning: "True/False questions should use Exact Match grading."
Options: [Cancel] [Change to Exact Match] [Continue]
```

### 7.3 No Grading Rules Defined
**Scenario:** Auto-gradable type created but no grading method specified
```
Error: "Auto-gradable types must have a grading method defined."
Action: Show grading method selector
```

---

## 8. PERFORMANCE CONSIDERATIONS

- Question list: Paginate by 30 items
- Type overview: Cache for 1 day
- Statistics: Auto-calculate nightly
- Search: Debounce 300ms
- Grading rule evaluation: Indexed lookups only

---

## 9. TESTING CHECKLIST

### 9.1 Functional Testing
- [ ] Create question type with all fields
- [ ] Edit type configuration
- [ ] Delete type (verify warning if questions exist)
- [ ] View all questions of a type
- [ ] Filter questions by subject/class/difficulty
- [ ] View grading rules
- [ ] View sample rendering
- [ ] Export question list
- [ ] Import type definitions from CSV
- [ ] Auto-grading works per type rules
- [ ] Manual grading types require teacher input
- [ ] Partial credit calculated correctly

### 9.2 UI/UX Testing
- [ ] Type overview boxes render correctly
- [ ] Category grouping clear and organized
- [ ] Detail tabs load without delay
- [ ] Sample rendering displays properly
- [ ] Modal form validates input
- [ ] Responsive layout on all devices
- [ ] Color coding consistent

### 9.3 Integration Testing
- [ ] Create type → Available in question form
- [ ] Assign type to question → Counted in statistics
- [ ] Delete type → Questions lose type assignment
- [ ] Grading rules applied during assessment
- [ ] Analytics auto-calculate for type
- [ ] Export includes type information

### 9.4 Accessibility Testing
- [ ] Tab order logical throughout
- [ ] Type codes readable in monospace
- [ ] Color contrast ≥ 4.5:1
- [ ] Form labels associated with inputs
- [ ] Error messages linked to fields
- [ ] Keyboard navigation complete
- [ ] Screen reader announces all content

---

## 10. FUTURE ENHANCEMENTS

- **Type Template Library:** Pre-configured types for download
- **Custom Grading Algorithms:** Define evaluation formulas per type
- **Type Wizard:** Interactive tool to create question type
- **Rendering Preview:** Live preview of type display
- **Bulk Type Conversion:** Convert questions between types
- **Type Performance Dashboard:** Analytics-driven type recommendations
- **Mobile Type Optimization:** Separate rendering for mobile learners
- **AI Question Type Classification:** Auto-detect type from question text

---

## APPENDIX

### A. Standard Question Types

| Code | Name | Has Options | Auto-Gradable | Usage % |
|------|------|-------------|---------------|---------|
| MCQ_SINGLE | MCQ (Single) | Yes | Yes | 32% |
| MCQ_MULTI | MCQ (Multi-Select) | Yes | Yes | 18% |
| TRUE_FALSE | True/False | Yes | Yes | 24% |
| SHORT_ANSWER | Short Answer | No | No | 14% |
| LONG_ANSWER | Long Answer (Essay) | No | No | 8% |
| FILL_BLANK | Fill in the Blanks | Yes | Yes | 12% |
| MATCHING | Matching | Yes | Yes | 6% |
| NUMERIC | Numeric | No | Yes | 5% |
| CODING | Coding | No | No | 2% |

### B. Grading Method Capabilities

| Type | Method | Partial Credit | Appeal | Remarks |
|------|--------|----------------|--------|---------|
| MCQ | Exact Match | No | Yes | Industry standard |
| True/False | Exact Match | No | Yes | Simple binary |
| Short Answer | Fuzzy Match | No | Yes | Requires pattern |
| Essay | Manual | Yes | Yes | Teacher judgement |
| Matching | Exact Match | No | Yes | All pairs must match |
| Fill Blank | Pattern Matching | No | Yes | Case-insensitive |
| Numeric | Range/Tolerance | Yes | Yes | ±10% accepted |
| Coding | Test Suite | Partial | Yes | Automated testing |

