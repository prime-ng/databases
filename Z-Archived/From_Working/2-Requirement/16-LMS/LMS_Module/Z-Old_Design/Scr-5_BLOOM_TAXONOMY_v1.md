# Screen Design Specification: Bloom's Taxonomy Management
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Bloom's Taxonomy Management Module**, enabling administrators to configure and manage the six-level cognitive learning taxonomy (Remembering, Understanding, Applying, Analyzing, Evaluating, Creating). This taxonomy forms the foundation for question difficulty classification and assessment design.

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

**Database Table:** slb_bloom_taxonomy
├── id (INT PRIMARY KEY)
├── code (VARCHAR 20, UNIQUE) - e.g., 'REMEMBERING', 'UNDERSTANDING'
├── name (VARCHAR 100) - Full level name
├── description (VARCHAR 255) - Educational definition
├── bloom_level (TINYINT 1-6) - Sequential level indicator
└── Unique constraint: code must be unique across system

**Related Tables:**
- slb_cognitive_skill → links cognitive skills to Bloom levels
- sch_questions → questions classified by Bloom level
- sch_question_analytics → tracks usage of each level

---

## 2. SCREEN LAYOUTS

### 2.1 Bloom's Taxonomy List Screen
**Route:** `/curriculum/settings/bloom-taxonomy` or `/assessment/bloom-taxonomy`

#### 2.1.1 Page Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ ASSESSMENT SETTINGS > BLOOM'S TAXONOMY                                     │
├────────────────────────────────────────────────────────────────────────────┤
│   [Search Taxonomy ________________] [+ New Level]  [Import] [Export]      │
├────────────────────────────────────────────────────────────────────────────┤
│ Display Mode: [Grid View] [List View]    Sort by: [Level ▼]               │
├────────────────────────────────────────────────────────────────────────────┤
│
│ COGNITIVE PYRAMID VIEW (6 Levels)
│
│                        ╔════════════════════╗
│                        ║  6. CREATING       ║
│                        ║  (Highest Order)   ║
│                        ╚════════════════════╝
│                      ╔═══════════════════════╗
│                      ║  5. EVALUATING       ║
│                      ║  (Critical Thinking) ║
│                      ╚═══════════════════════╝
│                    ╔═════════════════════════╗
│                    ║  4. ANALYZING          ║
│                    ║  (Breaking Down)       ║
│                    ╚═════════════════════════╝
│                  ╔═══════════════════════════╗
│                  ║  3. APPLYING             ║
│                  ║  (Using Knowledge)       ║
│                  ╚═══════════════════════════╝
│              ╔═════════════════════════════╗
│              ║  2. UNDERSTANDING           ║
│              ║  (Explaining Ideas)         ║
│              ╚═════════════════════════════╝
│          ╔═══════════════════════════════╗
│          ║  1. REMEMBERING               ║
│          ║  (Lowest Order - Base)        ║
│          ╚═══════════════════════════════╝
│
├────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Level │ Code          │ Name          │ Description        │ Actions   │
│────┼───────┼───────────────┼───────────────┼────────────────────┼───────────│
│ ☐ │   1   │ REMEMBERING   │ Remembering   │ Recall facts and   │ ✎ # -     │
│ ☐ │   2   │ UNDERSTANDING │ Understanding │ Explain ideas and  │ ✎ # -     │
│ ☐ │   3   │ APPLYING      │ Applying      │ Use information in │ ✎ # -     │
│ ☐ │   4   │ ANALYZING     │ Analyzing     │ Draw connections   │ ✎ # -     │
│ ☐ │   5   │ EVALUATING    │ Evaluating    │ Justify decisions  │ ✎ # -     │
│ ☐ │   6   │ CREATING      │ Creating      │ Produce new ideas  │ ✎ # -     │
│
├────────────────────────────────────────────────────────────────────────────┤
│ Showing 6 of 6 items                                [Export Selected] [✓ OK]│
└────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components & Interactions

**Grid/List Toggle:**
- Grid view: Card-based pyramid visualization (default)
- List view: Traditional table with sortable columns

**Search Bar:**
- Placeholder: "Search by code or name..."
- Real-time filtering on code, name, description
- Clear button (×) to reset

**Buttons:**
- **[+ New Level]** – Create custom Bloom level (if system allows)
  - Opens Create Modal (rare, usually not editable)
  - Color: Primary (Blue)
- **[Import]** – Bulk import from CSV/JSON
  - Template download available
- **[Export]** – Export selected/all levels
  - Format options: CSV, PDF, JSON

**Pyramid View Features:**
- Click card → Detail/Edit view
- Hover → Show action buttons
- Visual hierarchy (larger base, smaller apex)
- Color-coded by cognitive level (progression from light to dark)

---

### 2.2 View Bloom Level Detail Screen
**Route:** `/curriculum/settings/bloom-taxonomy/{id}`

#### 2.2.1 Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ BLOOM LEVEL DETAIL > Remembering (Level 1)              [Edit] [Delete] [+] │
├────────────────────────────────────────────────────────────────────────────┤
│ [Details] [Cognitive Skills] [Sample Questions] [Usage Analytics]          │
├────────────────────────────────────────────────────────────────────────────┤
│
│ DETAILS TAB
│ ─────────────────────────────────────────────────────────────────────────
│ Level:                1 (Lowest Order - Foundation)
│ Code:                 REMEMBERING
│ Name:                 Remembering
│
│ Description:
│ └─ The ability to recall facts, terms, basic concepts, and answers
│    from memory. Students can recognize, list, describe, retrieve,
│    name, find, and duplicate information.
│
│ Learning Verbs (Action Words):
│ └─ List, Define, Tell, Describe, Retrieve, Name, Find, Identify
│    Recall, Recognize, Duplicate, Memorize, Reproduce, Label
│
│ Question Examples:
│ └─ "Define the term photosynthesis."
│    "List the capital cities of 5 countries."
│    "Name the parts of a flower."
│
│ Cognitive Complexity:
│ └─ Very Low (Simple recall and recognition)
│
│ Typical Question Types:
│ └─ Fill in the Blanks, Multiple Choice (definition-based),
│    True/False, Matching, Short Answer (factual)
│
│ Estimated Time to Answer:
│ └─ 30 seconds to 2 minutes
│
│ Created At:           2024-01-15 10:00:00
│ Last Modified:        2024-12-10 09:30:00
│
│ [Edit] [Download Questions for this Level] [Copy Link]
│
├────────────────────────────────────────────────────────────────────────────┤
│ COGNITIVE SKILLS TAB
│ ─────────────────────────────────────────────────────────────────────────
│ Linked Cognitive Skills (3 skills):
│ 
│ • COG-RECALL: Immediate recall of memorized material
│ • COG-RECOGNITION: Identifying information from options
│ • COG-BASIC-FACTS: Understanding basic factual knowledge
│
│ [+ Link Skill] [Manage Links]
│
├────────────────────────────────────────────────────────────────────────────┤
│ SAMPLE QUESTIONS TAB
│ ─────────────────────────────────────────────────────────────────────────
│ Questions using this Bloom level: 342 (across all subjects)
│
│ Class: [All ▼]  Subject: [All ▼]  Difficulty: [All ▼]  [Filter]
│
│ ☐ │ Question                    │ Subject  │ Class │ Type │ Uses │
│ ───┼─────────────────────────────┼──────────┼───────┼──────┼──────│
│ ☐ │ Q1: Define photosynthesis... │ Science  │ 6th   │ MCQ  │  45  │
│ ☐ │ Q2: List the planets...      │ Science  │ 7th   │ SA   │  38  │
│ ☐ │ Q3: Name the continents...   │ SST      │ 6th   │ FB   │  51  │
│
│ [Export List] [Assign to Assessment]
│
├────────────────────────────────────────────────────────────────────────────┤
│ USAGE ANALYTICS TAB
│ ─────────────────────────────────────────────────────────────────────────
│ Total Questions:     342
│ Questions Used:      287 (84%)
│ Questions Unused:    55 (16%)
│
│ Monthly Usage Trend:
│ ╔═══════════════════════════════════════════════════════════════════╗
│ ║  Nov   Dec   Jan   Feb   Mar   Apr   May   Jun   Jul   Aug   Sep   ║
│ ║  150   152   148   145   142   140   135   132   128   125   120   ║
│ ╚═══════════════════════════════════════════════════════════════════╝
│
│ Questions by Subject:
│ • Science:    142 questions (42%)
│ • Math:       98 questions (29%)
│ • SST:        67 questions (20%)
│ • English:    35 questions (10%)
│
│ [Download Report]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Create/Edit Bloom Level Modal
**Route:** `GET/POST /curriculum/settings/bloom-taxonomy/new` or `/{id}/edit`

#### 2.3.1 Layout
```
┌──────────────────────────────────────────────┐
│ NEW BLOOM LEVEL                         [✕]  │
├──────────────────────────────────────────────┤
│                                              │
│ Level *            [6]                       │
│ (1-6 for standard Bloom taxonomy)            │
│                                              │
│ Code *             [CREATING_]               │
│ (Uppercase, no spaces, unique)               │
│                                              │
│ Name *             [Creating_____________]   │
│ (Display name, max 100 chars)                │
│                                              │
│ Description        [________________]        │
│                    [                        ]│
│                    [                        ]│
│ (Detailed educational description)           │
│                                              │
│ Learning Verbs     [________________]        │
│                    [                        ]│
│ (Comma-separated action words)               │
│                                              │
│ Sample Questions   [________________]        │
│                    [                        ]│
│ (Examples for this Bloom level)              │
│                                              │
│ Estimated Time     [__ minutes]              │
│ (Average time to answer a question)          │
│                                              │
├──────────────────────────────────────────────┤
│           [Cancel]  [Save]  [Save & New]     │
└──────────────────────────────────────────────┘
```

#### 2.3.2 Field Specifications

| Field | Type | Validation | Placeholder | Required |
|-------|------|-----------|------------|----------|
| Level | Number | 1-6 (unique) | "1" | ✓ |
| Code | Text | Max 20, alphanumeric+underscore | "REMEMBERING" | ✓ |
| Name | Text | Max 100 chars | "Remembering" | ✓ |
| Description | TextArea | Max 500 chars | "Educational definition..." | ✓ |
| Learning Verbs | TextArea | Comma-separated | "List, Define, Tell..." | ✗ |
| Sample Questions | TextArea | Max 1000 chars | "Example questions..." | ✗ |
| Estimated Time | Number | Positive int (minutes) | "1" | ✗ |

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Bloom Level Request
```json
POST /api/v1/bloom-taxonomy
{
  "level": 6,
  "code": "CREATING",
  "name": "Creating",
  "description": "The ability to put parts together to form something new...",
  "learning_verbs": "Design, Construct, Create, Invent, Produce",
  "sample_questions": "Design a new experiment...",
  "estimated_time_minutes": 5
}
```

### 3.2 Create Bloom Level Response
```json
{
  "success": true,
  "data": {
    "id": 6,
    "level": 6,
    "code": "CREATING",
    "name": "Creating",
    "description": "The ability to put parts together to form something new...",
    "learning_verbs": "Design, Construct, Create, Invent, Produce",
    "sample_questions": "Design a new experiment...",
    "estimated_time_minutes": 5,
    "created_at": "2024-12-10T10:00:00Z"
  },
  "message": "Bloom level created successfully"
}
```

### 3.3 List Bloom Levels Request
```
GET /api/v1/bloom-taxonomy?sort=level:asc&limit=100
```

### 3.4 List Bloom Levels Response
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "level": 1,
      "code": "REMEMBERING",
      "name": "Remembering",
      "description": "The ability to recall facts...",
      "created_at": "2024-01-15T10:00:00Z"
    },
    {
      "id": 2,
      "level": 2,
      "code": "UNDERSTANDING",
      "name": "Understanding",
      "description": "The ability to explain ideas...",
      "created_at": "2024-01-15T10:00:00Z"
    }
  ],
  "pagination": {
    "total": 6,
    "page": 1,
    "limit": 100
  }
}
```

### 3.5 Get Bloom Level Detail
```
GET /api/v1/bloom-taxonomy/{id}
```

### 3.6 Update Bloom Level
```json
PATCH /api/v1/bloom-taxonomy/{id}
{
  "description": "Updated description...",
  "learning_verbs": "Updated verbs...",
  "sample_questions": "Updated examples..."
}
```

### 3.7 Delete Bloom Level
```
DELETE /api/v1/bloom-taxonomy/{id}
Response: 
{
  "success": true,
  "message": "Bloom level deleted successfully. 342 questions reassigned."
}
```

---

## 4. USER WORKFLOWS

### 4.1 View All Bloom Levels Workflow
**Goal:** Administrator reviews the complete Bloom taxonomy structure

1. Navigate to **Assessment Settings > Bloom's Taxonomy**
   - Displays pyramid view with all 6 levels
   - Default state: sorted by level (1-6)

2. Review each level
   - Click card to view detailed description
   - Observe cognitive complexity progression
   - Check learning verbs and sample questions

3. (Optional) Switch to list view
   - Click "List View" toggle
   - View all details in tabular format
   - Sort by level, name, or code

4. Close or navigate away
   - Pyramid remains default display

---

### 4.2 Edit Bloom Level Workflow
**Goal:** Update description, learning verbs, or sample questions

1. From list/detail view, click **[Edit]** button
2. Modify fields (description, verbs, examples, time estimate)
3. Click **[Save]** to commit changes
4. Confirmation message appears
5. Returns to detail view with updated information
6. Audit trail recorded (who, when, what changed)

---

### 4.3 View Questions for a Bloom Level Workflow
**Goal:** See which questions are classified under this Bloom level

1. Navigate to Bloom level detail view
2. Click **[Sample Questions]** tab
3. System displays paginated list of questions
4. Filter options: Class, Subject, Difficulty, Question Type
5. Export or assign to assessment as needed

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Color Coding by Level
- **Level 1 (Remembering):** Light Blue (#E3F2FD)
- **Level 2 (Understanding):** Light Cyan (#B3E5FC)
- **Level 3 (Applying):** Light Green (#C8E6C9)
- **Level 4 (Analyzing):** Light Yellow (#FFF9C4)
- **Level 5 (Evaluating):** Light Orange (#FFE0B2)
- **Level 6 (Creating):** Light Red (#FFCDD2)

### 5.2 Typography
- Header: "Bloom's Taxonomy Level X (Name)" – Bold, 24px
- Level Card Title: "Remembering" – Bold, 16px
- Description Text: Regular, 14px, line-height 1.6
- Learning Verbs: Italic, 12px (secondary text)

### 5.3 Pyramid Visualization
- Responsive scaling (mobile: single column, desktop: pyramid)
- Shadow effects on hover
- Smooth transitions (0.3s ease-in-out)
- Border highlight on selection

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 ARIA Labels
- Buttons: aria-label="Edit Remembering level"
- Pyramid cards: aria-label="Level 1: Remembering, click to view details"
- Tabs: aria-selected="true/false"
- Search: aria-describedby="search-help"

### 6.2 Keyboard Navigation
- Tab through all interactive elements
- Enter to select, Space to toggle
- Arrow keys to navigate pyramid levels
- Esc to close modals/details

### 6.3 Screen Reader Support
- Announce pyramid as "Cognitive pyramid with 6 levels"
- Read level numbers and names clearly
- Provide alt text for all icons
- Describe visual hierarchy in text

### 6.4 Responsive Design
- **Desktop (1200+px):** Pyramid display, side-by-side details
- **Tablet (768-1199px):** Stacked pyramid, scrollable content
- **Mobile (<768px):** Single column, collapsible sections

---

## 7. EDGE CASES & ERROR SCENARIOS

### 7.1 Duplicate Code
**Scenario:** User tries to create level with existing code
```
Error Message: "Code 'REMEMBERING' already exists. Please use a unique code."
Action: Highlight code field, suggest alternative (REMEMBERING_2)
```

### 7.2 Invalid Level Number
**Scenario:** User tries to assign level number outside 1-6
```
Error Message: "Level must be between 1 and 6."
Action: Clear field, show validation error
```

### 7.3 Delete Level with Active Questions
**Scenario:** User attempts to delete Bloom level used by 342 questions
```
Warning Dialog: "This level is used by 342 questions. Delete anyway?"
Options: [Cancel] [Delete and Reassign to Similar Level] [Delete Anyway]
If confirmed: Reassign or cascade delete with audit trail
```

### 7.4 Import Conflict
**Scenario:** User imports levels with codes that already exist
```
Dialog: "Found 3 existing levels. Overwrite?"
Options: [Cancel] [Skip Duplicates] [Overwrite All] [Merge]
```

---

## 8. PERFORMANCE CONSIDERATIONS

- **Pyramid Rendering:** Use CSS transforms, not DOM manipulation
- **Question List:** Lazy-load paginated results (10 per page)
- **Search:** Debounce input (300ms) before API call
- **Analytics Charts:** Cache data for 1 hour
- **Analytics Generation:** Run async job, show progress indicator

---

## 9. TESTING CHECKLIST

### 9.1 Functional Testing
- [ ] Create new Bloom level with all fields
- [ ] Edit existing level's description
- [ ] Delete level (with warning if questions exist)
- [ ] Search levels by code/name (case-insensitive)
- [ ] View detail page with all tabs (Details, Skills, Questions, Analytics)
- [ ] Toggle between grid/list views
- [ ] Sort levels by name, code, or level
- [ ] Filter questions by class, subject, difficulty
- [ ] Export levels to CSV/PDF
- [ ] Import levels from CSV
- [ ] Pagination through questions (previous/next, page jump)
- [ ] Bulk select/deselect items
- [ ] Duplicate level (pre-fill new form)

### 9.2 UI/UX Testing
- [ ] Pyramid renders correctly on desktop/tablet/mobile
- [ ] Hover effects on level cards
- [ ] Modal animations smooth and fast
- [ ] Search results appear within 1 second
- [ ] Form validation errors display clearly
- [ ] Success/error messages appear for 3+ seconds
- [ ] Buttons disabled during loading

### 9.3 Integration Testing
- [ ] Create level → Appears in list immediately
- [ ] Edit level → Questions still searchable by level
- [ ] Delete level → Questions reassigned correctly
- [ ] Export → File download starts automatically
- [ ] Import → Data validated before insertion
- [ ] Questions tab shows correct count

### 9.4 Accessibility Testing
- [ ] Tab order logical (top-to-bottom, left-to-right)
- [ ] Pyramid navigable via keyboard only
- [ ] Screen reader announces level names/numbers
- [ ] Color contrast ratio ≥ 4.5:1 on text
- [ ] Form labels associated with inputs
- [ ] Error messages linked to form fields

---

## 10. FUTURE ENHANCEMENTS

- **Custom Taxonomies:** Allow schools to define custom Bloom variants (e.g., Fink's Taxonomy, Anderson taxonomy)
- **Bloom-Cognitive Mapping Wizard:** Interactive tool to map Bloom levels to Cognitive Skills
- **Question Recommendation Engine:** Suggest optimal difficulty progression based on Bloom levels
- **Mastery Pathways:** Auto-generate question sequences progressing through Bloom levels
- **Bloom Visualization Dashboard:** Student progress through Bloom levels per subject/skill
- **Mobile Bloom Reference Card:** Exportable infographic for teachers/students
- **API Integration with External Banks:** Import/map questions from external question banks to Bloom levels

---

## APPENDIX

### A. Bloom's Taxonomy Reference (Standard 6-Level Model)

| Level | Code | Name | Description | Verbs | Examples |
|-------|------|------|-------------|-------|----------|
| 1 | REMEMBERING | Remembering | Recall facts and basic concepts | Define, Duplicate, List, Memorize, Recall, Reproduce | Q: "Define photosynthesis" |
| 2 | UNDERSTANDING | Understanding | Explain ideas or concepts | Classify, Describe, Discuss, Explain, Identify, Locate | Q: "Explain how photosynthesis works" |
| 3 | APPLYING | Applying | Use information in a new situation | Choose, Demonstrate, Dramatize, Employ, Illustrate, Interpret | Q: "Show how photosynthesis helps plants grow" |
| 4 | ANALYZING | Analyzing | Draw connections among ideas | Appraise, Compare, Criticize, Differentiate, Discriminate | Q: "Compare photosynthesis and respiration" |
| 5 | EVALUATING | Evaluating | Justify a stand or decision | Argue, Defend, Judge, Select, Support, Value, Critique | Q: "Which process is more important?" |
| 6 | CREATING | Creating | Produce new or original work | Assemble, Construct, Create, Design, Develop, Formulate | Q: "Design an experiment to test photosynthesis" |

