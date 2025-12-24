# Screen Design Specification: Complexity Level Management
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Complexity Level Management Module**, enabling administrators to define and manage question difficulty levels (Easy, Medium, Difficult). Complexity levels are used for adaptive learning, differentiated assessment, and competency tracking.

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

**Database Table:** slb_complexity_level
├── id (INT PRIMARY KEY)
├── code (VARCHAR 20, UNIQUE) - 'EASY', 'MEDIUM', 'DIFFICULT'
├── name (VARCHAR 50) - Display name
├── complexity_level (TINYINT 1-3) - Sequential indicator
└── Indexed: code for fast lookups

**Related Tables:**
- sch_questions → Questions classified by complexity
- sch_question_pools → Filter questions by complexity
- sch_question_analytics → Difficulty index tracking

---

## 2. SCREEN LAYOUTS

### 2.1 Complexity Level List Screen
**Route:** `/curriculum/settings/complexity-levels`

#### 2.1.1 Page Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ ASSESSMENT SETTINGS > COMPLEXITY LEVELS                                    │
├────────────────────────────────────────────────────────────────────────────┤
│   [Search ______________] [+ New Level]  [Import] [Export]                 │
├────────────────────────────────────────────────────────────────────────────┤
│ Display Mode: [Card View] [List View]    Sort by: [Complexity ▼]          │
├────────────────────────────────────────────────────────────────────────────┤
│
│ COMPLEXITY PROGRESSION VIEW
│
│ ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
│ │   EASY       │        │   MEDIUM     │        │ DIFFICULT    │
│ │              │        │              │        │              │
│ │  (Level 1)   │   →    │  (Level 2)   │   →    │  (Level 3)   │
│ │              │        │              │        │              │
│ │   456 Qs     │        │   532 Qs     │        │   289 Qs     │
│ │   67.5%      │        │   79.2%      │        │   61.3%      │
│ │   Pass Rate  │        │   Pass Rate  │        │   Pass Rate  │
│ └──────────────┘        └──────────────┘        └──────────────┘
│
├────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Level │ Code      │ Name       │ Questions │ Avg Score │ Pass Rate │
│────┼───────┼───────────┼────────────┼───────────┼───────────┼───────────│
│ ☐ │   1   │ EASY      │ Easy       │   456     │   87.3%   │   67.5%   │
│ ☐ │   2   │ MEDIUM    │ Medium     │   532     │   72.1%   │   79.2%   │
│ ☐ │   3   │ DIFFICULT │ Difficult  │   289     │   58.6%   │   61.3%   │
│
│ [Download Report] [Performance Analysis] [Bulk Actions]
│
└────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components & Interactions

**Progression View:**
- Visual progression from Easy → Medium → Difficult
- Arrow indicators showing difficulty flow
- Hover → Show question breakdown by subject
- Click card → Detailed view

**Display Mode:**
- Card View (default): Horizontal progression with statistics
- List View: Traditional table format with sorting

**Buttons:**
- **[+ New Level]** – Create custom complexity level (rare)
- **[Import]** – Import configurations
- **[Export]** – Export to CSV

---

### 2.2 View Complexity Level Detail Screen
**Route:** `/curriculum/settings/complexity-levels/{id}`

#### 2.2.1 Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ COMPLEXITY LEVEL DETAIL > Medium (Level 2)            [Edit] [Delete]      │
├────────────────────────────────────────────────────────────────────────────┤
│ [Details] [Questions] [Performance Analytics] [Assessment Usage]           │
├────────────────────────────────────────────────────────────────────────────┤
│
│ DETAILS TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Level:                2 (Middle difficulty)
│ Code:                 MEDIUM
│ Name:                 Medium
│
│ Description:
│ └─ Intermediate difficulty questions requiring understanding of concepts
│    and ability to apply knowledge in familiar contexts. Students should
│    be able to recall facts and apply them with minor guidance.
│
│ Difficulty Characteristics:
│ └─ • Requires concept application
│    • May involve multiple steps
│    • Familiar context or minor variations
│    • 3-5 minutes average time to answer
│
│ Use Cases:
│ └─ • Formative assessment during unit
│    • Homework and practice questions
│    • Mid-level difficulty quizzes
│    • Differentialted assignments for average learners
│
│ Question Pool Statistics:
│ ├─ Total Questions:         532
│ ├─ Active Questions:         512
│ ├─ Inactive/Archived:        20
│ ├─ Average Student Score:    72.1%
│ ├─ Question Pass Rate:       79.2% (students scoring ≥ 60%)
│ ├─ Discrimination Index:     0.42 (Good)
│ └─ Avg Time to Answer:       4.2 minutes
│
│ Distribution by Subject:
│ • Science:    165 questions (31%)
│ • Math:       198 questions (37%)
│ • English:    98 questions (18%)
│ • SST:        71 questions (13%)
│
│ Created At:           2024-01-15 10:00:00
│ Last Modified:        2024-12-10 09:30:00
│
│ [Edit] [Download Questions] [View Analytics JSON]
│
├────────────────────────────────────────────────────────────────────────────┤
│ QUESTIONS TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Total: 532 questions classified as Medium difficulty
│
│ Class: [All ▼]  Subject: [All ▼]  Bloom: [All ▼]  [Filter]
│
│ ☐ │ Question | Type | Bloom | Subject | Created | Last Used │
│────┼──────────┼──────┼───────┼─────────┼─────────┼───────────│
│ ☐ │ Q1: Apply│ MCQ  │ Appl. │ Science │ 12/08   │ 12/09     │
│ ☐ │ Q2: Expl │ SA   │ Under.│ Math    │ 12/07   │ 12/09     │
│ ☐ │ Q3: Anal │ LA   │ Anal. │ English │ 12/06   │ 12/08     │
│
│ [Export List] [Reassign Difficulty] [View Details]
│
├────────────────────────────────────────────────────────────────────────────┤
│ PERFORMANCE ANALYTICS TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Student Performance on Medium Difficulty Questions:
│
│ Average Score:           72.1%
│ Pass Rate (≥60%):        79.2%
│ Fail Rate:               20.8%
│
│ Score Distribution (Bell Curve):
│ ╔═════════════════════════════════════════════════════════════╗
│ ║   High Performers  │    Majority    │  Struggling Learners   ║
│ ║     (80-100%)      │   (50-80%)     │      (<50%)            ║
│ ║        35%         │      48%       │        17%             ║
│ ╚═════════════════════════════════════════════════════════════╝
│
│ Question Effectiveness:
│ • Well-designed: 412 questions (77%) - Good discrimination & difficulty
│ • Review Needed: 98 questions (18%) - Low discrimination
│ • Revise Required: 22 questions (4%) - Too easy or too hard
│
│ Monthly Trend:
│ ┌─────────────────────────────────────────────────────────────┐
│ │ Oct: 71.8%  Nov: 72.5%  Dec: 72.1%  Trend: Stable        │
│ └─────────────────────────────────────────────────────────────┘
│
│ [Download Report] [Download Questions Review List]
│
├────────────────────────────────────────────────────────────────────────────┤
│ ASSESSMENT USAGE TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Used in 127 assessments and quizzes
│
│ Assessment Type Distribution:
│ • Quizzes:      45 assessments
│ • Unit Tests:   38 assessments
│ • Exams:        28 assessments
│ • Formative:    16 assessments
│
│ [View Assessments] [Download Usage Report]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Create/Edit Complexity Level Modal
**Route:** `POST /curriculum/settings/complexity-levels` or `PATCH /{id}`

#### 2.3.1 Layout
```
┌──────────────────────────────────────────────┐
│ NEW COMPLEXITY LEVEL                    [✕]  │
├──────────────────────────────────────────────┤
│                                              │
│ Level *             [2]                      │
│ (1-3 for standard complexity)                │
│                                              │
│ Code *              [MEDIUM_____]            │
│ (Uppercase, unique, max 20 chars)            │
│                                              │
│ Name *              [______________]         │
│ (Display name, e.g., "Medium")               │
│                                              │
│ Description *       [______________]         │
│                     [                       ]│
│                     [                       ]│
│ (Detailed explanation)                       │
│                                              │
│ Characteristics      [☑] Requires concept app│
│                      [☑] Multiple steps      │
│                      [☐] Unfamiliar context │
│                      [☐] High creativity    │
│                                              │
│ Estimated Time      [__ minutes]             │
│ (Average time to answer)                     │
│                                              │
│ Ideal Pass Rate     [__ %]                   │
│ (Expected % of students to pass)             │
│                                              │
├──────────────────────────────────────────────┤
│           [Cancel]  [Save]  [Save & New]    │
└──────────────────────────────────────────────┘
```

#### 2.3.2 Field Specifications

| Field | Type | Validation | Placeholder | Required |
|-------|------|-----------|------------|----------|
| Level | Number | 1-3, unique | "1" | ✓ |
| Code | Text | Max 20, alphanumeric+underscore | "EASY" | ✓ |
| Name | Text | Max 50 chars | "Easy" | ✓ |
| Description | TextArea | Max 500 chars | "Definition..." | ✓ |
| Characteristics | Checkbox | Multi-select | N/A | ✗ |
| Estimated Time | Number | Minutes, positive int | "2" | ✗ |
| Ideal Pass Rate | Number | 0-100 | "75" | ✗ |

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Complexity Level Request
```json
POST /api/v1/complexity-levels
{
  "level": 2,
  "code": "MEDIUM",
  "name": "Medium",
  "description": "Intermediate difficulty questions...",
  "characteristics": ["requires_application", "multiple_steps"],
  "estimated_time_minutes": 4,
  "ideal_pass_rate": 75
}
```

### 3.2 Create Response
```json
{
  "success": true,
  "data": {
    "id": 2,
    "level": 2,
    "code": "MEDIUM",
    "name": "Medium",
    "description": "Intermediate difficulty questions...",
    "estimated_time_minutes": 4,
    "ideal_pass_rate": 75,
    "question_count": 532,
    "avg_score": 72.1,
    "pass_rate": 79.2,
    "created_at": "2024-12-10T10:00:00Z"
  },
  "message": "Complexity level created successfully"
}
```

### 3.3 List Request
```
GET /api/v1/complexity-levels?sort=level:asc&limit=20
```

### 3.4 List Response
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "level": 1,
      "code": "EASY",
      "name": "Easy",
      "description": "Simple recall questions...",
      "question_count": 456,
      "avg_score": 87.3,
      "pass_rate": 67.5,
      "created_at": "2024-01-15T10:00:00Z"
    }
  ],
  "pagination": {
    "total": 3,
    "page": 1,
    "limit": 20
  }
}
```

### 3.5 Get Detail
```
GET /api/v1/complexity-levels/{id}
```

### 3.6 Update
```json
PATCH /api/v1/complexity-levels/{id}
{
  "description": "Updated description...",
  "ideal_pass_rate": 78
}
```

### 3.7 Delete
```
DELETE /api/v1/complexity-levels/{id}
```

---

## 4. USER WORKFLOWS

### 4.1 View Complexity Progression Workflow
**Goal:** Understand difficulty distribution across questions

1. Navigate to **Assessment Settings > Complexity Levels**
2. View card progression: Easy → Medium → Difficult
3. Observe question counts and pass rates
4. Identify imbalances (e.g., too many Easy, few Difficult)
5. Click on a level for detailed breakdown
6. Export distribution report

---

### 4.2 Classify Questions by Complexity Workflow
**Goal:** Mark a question as Easy, Medium, or Difficult

1. Open question for editing
2. Find "Complexity Level" field
3. Select from dropdown (Easy, Medium, Difficult)
4. System shows characteristics and expectations
5. Save question
6. Question filtered and analyzed by complexity

---

### 4.3 Analyze Performance by Difficulty Workflow
**Goal:** Evaluate how students perform on different difficulty levels

1. Open Complexity Level detail
2. Click **[Performance Analytics]** tab
3. View score distribution chart
4. Identify which complexity level needs improvement
5. View breakdown of questions (well-designed vs. review needed)
6. Download report for teacher analysis
7. Plan instructional interventions

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Color Coding
- **Easy:** Green (#4CAF50) - Light, bright
- **Medium:** Orange (#FF9800) - Neutral
- **Difficult:** Red (#F44336) - Dark, emphasized

### 5.2 Typography
- Level Code: Monospace, 12px, bold
- Level Name: Sans-serif, 18px, bold
- Statistics: 14px, regular
- Description: 14px, regular

### 5.3 Progression Visualization
- Horizontal flow: Easy → Medium → Difficult
- Card-based layout with arrow connectors
- Pass rate metric on each card
- Responsive stacking on mobile

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 ARIA Labels
- Level cards: aria-label="Easy level with 456 questions, 67.5% pass rate"
- Progression flow: aria-label="Complexity progression from Easy to Difficult"

### 6.2 Keyboard Navigation
- Tab through all complexity levels
- Enter to open detail
- Arrow keys to navigate progression
- Esc to close modals

### 6.3 Screen Reader Support
- Announce level name and question count
- Describe pass rate and performance metrics
- Read chart data as text alternatives

### 6.4 Responsive Design
- **Desktop:** Horizontal progression cards
- **Tablet:** Stacked cards with metrics
- **Mobile:** Single column with expandable sections

---

## 7. EDGE CASES & ERROR SCENARIOS

### 7.1 Delete Complexity Level
**Scenario:** User deletes MEDIUM level with 532 questions
```
Warning: "532 questions use this level. Delete anyway?"
Options: [Cancel] [Delete and Reassign] [Delete Anyway]
Action: Reassign to nearest adjacent level or mark as unclassified
```

### 7.2 Duplicate Code
**Scenario:** User tries to create level with code 'MEDIUM'
```
Error: "Code 'MEDIUM' already exists. Please use a unique code."
Suggestion: "Try MEDIUM-ADVANCED or MEDIUM-2"
```

### 7.3 Invalid Statistics
**Scenario:** System calculates 120% pass rate (data error)
```
Action: Auto-recalculate from source questions
Message: "Pass rate recalculated: 89.3%"
Flag: Review underlying data
```

---

## 8. PERFORMANCE CONSIDERATIONS

- Question list: Paginate by 20 items
- Statistics: Cache for 1 hour, update nightly
- Analytics charts: Lazy-load on tab open
- Search: Debounce 300ms
- Progression view: Use CSS transforms, not DOM manipulation

---

## 9. TESTING CHECKLIST

### 9.1 Functional Testing
- [ ] Create complexity level with all fields
- [ ] Edit level description and metrics
- [ ] Delete level (verify reassignment warning)
- [ ] View questions for each complexity
- [ ] Filter questions by subject/class
- [ ] View performance analytics by complexity
- [ ] Pass rate calculated correctly
- [ ] Discrimination index computed
- [ ] Export question list
- [ ] Import complexity configuration
- [ ] Complexity classification on questions

### 9.2 UI/UX Testing
- [ ] Progression cards display correctly
- [ ] Card hover effects smooth
- [ ] Charts render without errors
- [ ] Modal validation works
- [ ] Responsive layout on all devices
- [ ] Color contrast ≥ 4.5:1

### 9.3 Integration Testing
- [ ] Create level → Available in question form
- [ ] Classify question → Counted in level statistics
- [ ] Delete level → Questions unclassified
- [ ] Analytics auto-calculate on question changes
- [ ] Pass rate updates correctly

### 9.4 Accessibility Testing
- [ ] Tab order logical
- [ ] Form labels associated
- [ ] Error messages clear
- [ ] Keyboard navigation complete
- [ ] Screen reader announces stats
- [ ] Charts have text alternatives

---

## 10. FUTURE ENHANCEMENTS

- **Custom Complexity Scales:** Allow schools to define 4, 5, or 6-level scales
- **Complexity Wizard:** Interactive guide to classify questions
- **Adaptive Difficulty:** Auto-adjust question difficulty based on student responses
- **Complexity Insights Dashboard:** AI-powered recommendations
- **Item Response Theory (IRT) Integration:** Advanced psychometric analysis
- **Difficulty Curve Prediction:** Predict how new questions will perform
- **Mobile Difficulty Indicators:** Visual icons for mobile learners
- **Peer Complexity Benchmarking:** Compare with similar schools

---

## APPENDIX

### A. Standard Complexity Levels

| Level | Code | Name | Characteristics | Est. Time | Ideal Pass Rate |
|-------|------|------|-----------------|-----------|-----------------|
| 1 | EASY | Easy | Simple recall, familiar context, direct answer | 2 min | 85% |
| 2 | MEDIUM | Medium | Concept application, minor variations, 2-3 steps | 4 min | 75% |
| 3 | DIFFICULT | Difficult | Complex analysis, new context, multiple steps | 6-8 min | 55% |

### B. Bloom Level & Complexity Mapping

| Bloom Level | EASY | MEDIUM | DIFFICULT |
|-------------|------|--------|-----------|
| Remembering | ✓ | ✗ | ✗ |
| Understanding | ✓ | ✓ | ✗ |
| Applying | ✗ | ✓ | ✓ |
| Analyzing | ✗ | ✓ | ✓ |
| Evaluating | ✗ | ✗ | ✓ |
| Creating | ✗ | ✗ | ✓ |

