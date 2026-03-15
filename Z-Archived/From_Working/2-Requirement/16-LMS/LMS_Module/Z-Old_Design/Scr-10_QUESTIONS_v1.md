# Screen Design Specification: Question Bank Management
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Question Bank Management Module**, the core system for creating, editing, organizing, and versioning educational questions. This module supports complex question hierarchies, multi-media attachments, tagging, versioning, and comprehensive metadata management for assessment alignment.

### 1.2 User Roles & Permissions
| Role         | Create | View | Update | Delete | Print | Export | Import |
|--------------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| PG Support   |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| School Admin |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✗    |   ✓    |
| Principal    |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Teacher      |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Student      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |
| Parents      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |

### 1.3 Data Context

**Database Table:** sch_questions
├── id (BIGINT PRIMARY KEY)
├── topic_id (FK to slb_topics) - Hierarchical location
├── competency_id (FK to slb_competencies) - Skill alignment
├── lesson_id (FK to slb_lessons) - Denormalized for speed
├── class_id, subject_id (FKs for context)
├── question_type_id (FK to slb_question_types) - MCQ, SA, etc.
├── bloom_id (FK to slb_bloom_taxonomy) - Cognitive level
├── complexity_level_id (FK to slb_complexity_level) - Difficulty
├── cognitive_skill_id (FK to slb_cognitive_skill)
├── ques_type_specificity_id (FK to slb_ques_type_specificity)
├── stem (TEXT) - Question text with optional markup
├── answer_explanation (TEXT) - Answer key and rationale
├── marks (DECIMAL) - Points allocated
├── negative_marks (DECIMAL) - For MCQ guessing penalty
├── estimated_time_seconds (INT) - Time to answer
├── tags (JSON) - Array of tag strings
├── is_active (BOOLEAN)
├── is_public (BOOLEAN) - Share between tenants
├── version (INT) - Version tracking
└── Timestamps: created_at, updated_at, deleted_at

**Related Tables:**
- sch_question_options → Answer choices
- sch_question_media → Attachments (images, audio, video)
- sch_question_tag_jnt → Tag associations
- sch_question_versions → Version history
- sch_assessment_items → Used in assessments
- sch_question_analytics → Performance metrics

---

## 2. SCREEN LAYOUTS

### 2.1 Question Bank List Screen
**Route:** `/curriculum/questions` or `/subjects/{subjectId}/questions`

#### 2.1.1 Page Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ SYLLABUS MANAGEMENT > QUESTION BANK                                        │
├────────────────────────────────────────────────────────────────────────────┤
│ [Search Questions ___________________________] [+ New Question]             │
│ [Bulk Import] [Export] [Duplicate from Pool]                               │
├────────────────────────────────────────────────────────────────────────────┤
│ FILTERS:                                                                    │
│ Class: [All ▼] Subject: [All ▼] Lesson: [All ▼] Topic: [All ▼]             │
│ Type: [All ▼] Bloom: [All ▼] Difficulty: [All ▼] Status: [Active ▼]      │
│ [Filter] [Clear Filters] [Save Filter Set]                                │
├────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Question ID │ Question (Stem)    │ Type  │ Bloom │ Diff │ Used │ Actions │
│────┼─────────────┼────────────────────┼───────┼───────┼──────┼──────┼─────────│
│ ☐ │ Q001        │ What is photosyn..│ MCQ-S │ Rem   │ Easy │ 245  │ ⋯ Menu  │
│ ☐ │ Q002        │ Explain the proce..│ SA    │ Und   │ Med  │ 156  │ ⋯ Menu  │
│ ☐ │ Q003        │ Compare two types..│ LA    │ Ana   │ Diff │ 89   │ ⋯ Menu  │
│ ☐ │ Q004        │ Design an experim..│ Project│ Cre  │ Diff │ 42   │ ⋯ Menu  │
│                                                                            │
│ Showing 1-25 of 2,847 questions             [< 1 2 3 4 >]  Rows: [25 ▼]   │
├────────────────────────────────────────────────────────────────────────────┤
│ Total Questions: 2,847 | Active: 2,624 (92%) | Inactive: 223 (8%)        │
│ Bulk Actions: [Delete Selected] [Change Type] [Add Tag] [Export Selected] │
└────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components & Interactions

**Search Bar:**
- Placeholder: "Search by question ID, text, tags..."
- Real-time search across stem, options, tags
- Autocomplete suggestions

**Multi-Filter:**
- Hierarchical: Class → Subject → Lesson → Topic
- Question attributes: Type, Bloom, Difficulty, Specificity
- Status filter: Active, Inactive, All
- Saved filter sets for common searches

**Column Options (Customizable):**
- Question ID, Stem (preview), Type, Bloom, Difficulty, Complexity, Used Count, Created Date, Last Modified, Creator

**Row Actions:**
- Click row → Detail/Edit view
- Hover → Show buttons: [Edit] [Copy] [View in Assessment] [Delete]
- Right-click → Context menu

**Bulk Operations:**
- Select via checkbox
- Bulk: Delete, Change Type, Add Tag, Reassign Topic, Export
- Update status to Active/Inactive

---

### 2.2 View Question Detail Screen
**Route:** `/curriculum/questions/{questionId}`

#### 2.2.1 Layout (Multi-Tab)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ QUESTION DETAIL > Q001: What is photosynthesis?      [Edit] [Copy] [Delete] │
├────────────────────────────────────────────────────────────────────────────┤
│ [Stem] [Options] [Media] [Analytics] [Versions] [Assessment Usage] [Log]   │
├────────────────────────────────────────────────────────────────────────────┤
│
│ STEM TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Question ID:            Q001
│ Status:                 ✓ Active
│
│ Stem (Question Text):
│ └─ What is photosynthesis? (with optional rich text formatting)
│    [Shows with HTML rendering - bold, italic, subscript, etc.]
│
│ Question Classification:
│ ├─ Class:               9th Standard
│ ├─ Subject:             Science
│ ├─ Lesson:              Lesson 3: Photosynthesis & Respiration
│ ├─ Topic:               Topic 2.1: Photosynthesis Process
│ └─ Competency:          (Optional) Understand life processes
│
│ Question Attributes:
│ ├─ Type:                Multiple Choice (Single Select)
│ ├─ Bloom Level:         REMEMBERING (Level 1)
│ ├─ Cognitive Skill:     COG-RECALL
│ ├─ Complexity Level:    Easy
│ ├─ Specificity Type:    In-Class
│ ├─ Marks:               1.00
│ ├─ Negative Marks:      0.00
│ └─ Estimated Time:      1-2 minutes
│
│ Answer & Explanation:
│ └─ Photosynthesis is the process by which plants convert light energy
│    into chemical energy in the form of glucose. It occurs in the
│    chloroplasts and requires light, water, and carbon dioxide.
│
│ Reference Material:
│ └─ NCERT Science Textbook, Chapter 6, Section 1
│    Khan Academy: https://www.khanacademy.org/science/biology/photosynthesis
│
│ Tags:
│ └─ [Biology] [Life-Processes] [Photosynthesis] [Revision] [NCERT]
│    [+ Add Tag]
│
│ Created By:             Sarah Teacher (2024-12-01 10:00 AM)
│ Last Modified By:       Sarah Teacher (2024-12-08 02:30 PM)
│ Version:                2 (Current: View History)
│
│ [Edit Stem] [View Version History] [Revert to Previous]
│
├────────────────────────────────────────────────────────────────────────────┤
│ OPTIONS TAB (MCQ Questions)
│ ──────────────────────────────────────────────────────────────────────────
│ Option A (☑ CORRECT ANSWER):
│ └─ The process by which plants make their own food using sunlight,
│    water, and carbon dioxide.
│    Feedback: ✓ Correct! This is the complete definition.
│
│ Option B:
│ └─ The process by which plants release oxygen during respiration.
│    Feedback: ✗ Incorrect. This describes respiration, not photosynthesis.
│    Distractor Type: Plausible but incorrect
│
│ Option C:
│ └─ The process by which plants absorb water from the soil.
│    Feedback: ✗ Incorrect. This describes absorption, not photosynthesis.
│    Distractor Type: Impossible
│
│ Option D:
│ └─ The process by which animals break down glucose for energy.
│    Feedback: ✗ Incorrect. This describes cellular respiration in animals.
│    Distractor Type: Plausible but incorrect
│
│ [Add Option] [Reorder Options] [Randomize on Display]
│
├────────────────────────────────────────────────────────────────────────────┤
│ MEDIA TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Attached Media (2 items):
│
│ 1. Image: Photosynthesis Diagram
│    File: photosynthesis_diagram.png (245 KB)
│    Purpose: Question Illustration
│    Upload Date: 2024-12-01
│    [Remove] [Preview]
│
│ 2. Image: Chloroplast Structure
│    File: chloroplast_structure.jpg (189 KB)
│    Purpose: Supporting Material
│    Upload Date: 2024-12-08
│    [Remove] [Preview]
│
│ [+ Attach Media] [Upload New]
│
├────────────────────────────────────────────────────────────────────────────┤
│ ANALYTICS TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Question Performance Metrics:
│
│ Total Uses:              245 (across all assessments)
│ Total Attempts:          1,847 (students attempted this question)
│ Average Score:           82.3%
│ Pass Rate (≥60%):        89.4%
│
│ Difficulty Index:        0.82 (Question is relatively easy)
│ Discrimination Index:    0.35 (Fair - moderately good)
│
│ Option Performance:
│ • Option A (Correct):    1,652 students (89.4%)
│ • Option B:              98 students (5.3%)
│ • Option C:              67 students (3.6%)
│ • Option D:              30 students (1.6%)
│
│ Average Time Spent:      1.2 minutes
│
│ Recommendation:         This question is working well. Good difficulty
│                         and discrimination. Useful for formative assessment.
│
│ [Download Full Analytics Report] [View Question Performance Chart]
│
├────────────────────────────────────────────────────────────────────────────┤
│ VERSIONS TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Version History (3 versions):
│
│ Version 2 (CURRENT):
│ • Created: 2024-12-08 02:30 PM by Sarah Teacher
│ • Change: Updated stem wording, improved clarity
│ • Change Reason: "Revised per teacher feedback"
│
│ Version 1:
│ • Created: 2024-12-01 10:00 AM by Sarah Teacher
│ • Change: Original question
│ • Change Reason: "Initial creation"
│
│ [Compare Versions] [Revert to Version 1] [Download All Versions]
│
├────────────────────────────────────────────────────────────────────────────┤
│ ASSESSMENT USAGE TAB
│ ──────────────────────────────────────────────────────────────────────────
│ Used in 12 Assessments:
│
│ Assessment Type      | Assessment Name           | Date Used │ Status
│ ─────────────────────┼───────────────────────────┼───────────┼────────
│ Quiz                 | Chapter 5 Review Quiz     │ 2024-12-08│ Active
│ Unit Test            | Unit 3 Test (9th Science) │ 2024-12-01│ Closed
│ Homework             | Photosynthesis Practice   │ 2024-11-25│ Active
│ Formative Assessment | Daily Lesson Review       │ 2024-11-20│ Closed
│
│ [View Full Assessment List] [Duplicate to New Assessment]
│
├────────────────────────────────────────────────────────────────────────────┤
│ ACTIVITY LOG TAB
│ ──────────────────────────────────────────────────────────────────────────
│ 2024-12-08 14:30 | Sarah Teacher | UPDATED | Changed stem wording
│ 2024-12-01 10:15 | Sarah Teacher | CREATED | Created question
│ 2024-12-01 10:05 | Sarah Teacher | TAGGED  | Added tags: Biology, Revision
│
│ [Download Log] [Filter by Action]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Create/Edit Question Modal (Multi-Step Form)
**Route:** `POST /curriculum/questions` or `PATCH /{questionId}`

#### 2.3.1 Step 1: Basic Information

```
┌──────────────────────────────────────────────────────────────────┐
│ CREATE QUESTION - Step 1/3: BASIC INFORMATION              [✕]   │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│ CLASS *              [9th Standard ▼]                            │
│ (Auto-filters subject)                                           │
│                                                                  │
│ SUBJECT *            [Science ▼]                                 │
│ (Auto-filters lesson)                                            │
│                                                                  │
│ LESSON *             [Lesson 3: Photosynthesis ▼]                │
│ (Auto-filters topic)                                             │
│                                                                  │
│ TOPIC *              [Topic 2.1: Photosynthesis Process ▼]       │
│ (Hierarchical selector)                                          │
│                                                                  │
│ COMPETENCY           [Understand life processes ▼]               │
│ (Optional)                                                       │
│                                                                  │
│ QUESTION TYPE *      [Multiple Choice (Single) ▼]                │
│ (Determines next step options)                                   │
│                                                                  │
│ BLOOM LEVEL *        [REMEMBERING ▼]                             │
│                                                                  │
│ COGNITIVE SKILL      [COG-RECALL ▼]                              │
│ (Optional, auto-suggests based on Bloom)                         │
│                                                                  │
│ COMPLEXITY LEVEL *   [Easy ▼]                                    │
│                                                                  │
│ SPECIFICITY TYPE     [In-Class ▼]                                │
│ (Optional)                                                       │
│                                                                  │
│ MARKS *              [1.00]                                      │
│                                                                  │
│ NEGATIVE MARKS       [-0.25]  (Leave blank if N/A)               │
│                                                                  │
│ STATUS               [☑] Active                                  │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                [Cancel]  [Previous]  [Next >]                   │
└──────────────────────────────────────────────────────────────────┘
```

#### 2.3.2 Step 2: Question Stem & Content

```
┌──────────────────────────────────────────────────────────────────┐
│ CREATE QUESTION - Step 2/3: STEM & CONTENT                 [✕]   │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│ QUESTION STEM *      [_____________________________]              │
│                      [                                           ]│
│                      [                                           ]│
│ (Rich text editor: Bold, Italic, Lists, Subscript, Math)         │
│                                                                  │
│ ANSWER KEY & EXPLANATION *                                       │
│                      [_____________________________]              │
│                      [                                           ]│
│                      [                                           ]│
│ (How to solve the question + correct answer)                     │
│                                                                  │
│ REFERENCE MATERIAL    [_____________________________]              │
│                      [                                           ]│
│ (Book chapter, link, etc.)                                       │
│                                                                  │
│ ESTIMATED TIME       [__ minutes]                                │
│ (For time management)                                            │
│                                                                  │
│ TAGS                 [________] [+ Add Tag]                      │
│ Example: Biology, Photosynthesis, NCERT                          │
│                                                                  │
│ ATTACH MEDIA         [+ Upload Image/Audio/Video]                │
│ (For question illustration)                                      │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                [Cancel]  [< Previous]  [Next >]                 │
└──────────────────────────────────────────────────────────────────┘
```

#### 2.3.3 Step 3: Options (for MCQ/Matching/Fill Blank)

```
┌──────────────────────────────────────────────────────────────────┐
│ CREATE QUESTION - Step 3/3: OPTIONS                         [✕]   │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│ OPTION 1 * (☑ SELECT AS CORRECT ANSWER)                          │
│           [_____________________________]                         │
│           [                                                     ]│
│ Feedback  [_____________________________]                         │
│                                                                  │
│ OPTION 2                                                         │
│           [_____________________________]                         │
│           [                                                     ]│
│ Feedback  [_____________________________]                         │
│ Distractor Type: [Plausible ▼]                                   │
│                                                                  │
│ OPTION 3                                                         │
│           [_____________________________]                         │
│           [                                                     ]│
│ Feedback  [_____________________________]                         │
│ Distractor Type: [Impossible ▼]                                  │
│                                                                  │
│ OPTION 4                                                         │
│           [_____________________________]                         │
│           [                                                     ]│
│ Feedback  [_____________________________]                         │
│ Distractor Type: [Plausible ▼]                                   │
│                                                                  │
│ [+ Add Option] [Randomize Order] [Preview Question]              │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                [Cancel]  [< Previous]  [Save]  [Save & New]     │
└──────────────────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Question Request
```json
POST /api/v1/questions
{
  "class_id": 9,
  "subject_id": 5,
  "lesson_id": 42,
  "topic_id": 156,
  "competency_id": null,
  "question_type_id": 1,
  "bloom_id": 1,
  "cognitive_skill_id": 1,
  "complexity_level_id": 1,
  "ques_type_specificity_id": 1,
  "stem": "What is photosynthesis?",
  "answer_explanation": "Photosynthesis is the process...",
  "reference_material": "NCERT Chapter 6, Section 1",
  "marks": 1.00,
  "negative_marks": 0.00,
  "estimated_time_seconds": 90,
  "tags": ["Biology", "Photosynthesis", "NCERT"],
  "is_active": true,
  "is_public": false,
  "options": [
    {
      "ordinal": 1,
      "option_text": "The process by which plants make their own food...",
      "is_correct": true,
      "feedback": "Correct! This is the complete definition."
    }
  ]
}
```

### 3.2 Create Response
```json
{
  "success": true,
  "data": {
    "id": 2847,
    "question_id": "Q001",
    "class_id": 9,
    "subject_id": 5,
    "lesson_id": 42,
    "topic_id": 156,
    "question_type": {
      "id": 1,
      "code": "MCQ_SINGLE",
      "name": "Multiple Choice (Single)"
    },
    "stem": "What is photosynthesis?",
    "marks": 1.00,
    "negative_marks": 0.00,
    "version": 1,
    "is_active": true,
    "created_at": "2024-12-10T10:00:00Z",
    "created_by": "teacher_123"
  },
  "message": "Question created successfully"
}
```

### 3.3 List Questions Request
```
GET /api/v1/questions?class_id=9&subject_id=5&lesson_id=42&
topic_id=156&question_type_id=1&bloom_id=1&complexity_level_id=1&
is_active=true&page=1&limit=25&sort=created_at:desc
```

### 3.4 List Response
```json
{
  "success": true,
  "data": [
    {
      "id": 2847,
      "question_id": "Q001",
      "stem": "What is photosynthesis?",
      "question_type": "MCQ (Single)",
      "bloom_level": "REMEMBERING",
      "complexity_level": "Easy",
      "marks": 1.00,
      "usage_count": 245,
      "created_by": "Sarah Teacher",
      "created_at": "2024-12-01T10:00:00Z"
    }
  ],
  "pagination": {
    "total": 2847,
    "page": 1,
    "limit": 25
  }
}
```

### 3.5 Get Question Detail
```
GET /api/v1/questions/{questionId}
```

### 3.6 Update Question
```json
PATCH /api/v1/questions/{questionId}
{
  "stem": "Updated question text...",
  "answer_explanation": "Updated explanation...",
  "complexity_level_id": 2,
  "is_active": false
}
```

### 3.7 Delete Question
```
DELETE /api/v1/questions/{questionId}
```

---

## 4. USER WORKFLOWS

### 4.1 Create New Question Workflow
**Goal:** Add a new question to the question bank

1. Click **[+ New Question]** from list view
2. **Step 1:** Select Class, Subject, Lesson, Topic
3. Choose Question Type (MCQ, SA, etc.)
4. Set Bloom level, Complexity, Marks
5. **Step 2:** Enter question stem (with rich text formatting)
6. Add answer explanation and reference material
7. Tag the question (Biology, Revision, etc.)
8. (Optional) Attach media (images, diagrams)
9. **Step 3:** For MCQ, add 4-5 options
10. Mark correct option and add feedback
11. Preview question rendering
12. Click **[Save]** → Question appears in list
13. System auto-creates version 1 record

---

### 4.2 Edit Existing Question Workflow
**Goal:** Update question content and metadata

1. Open question detail view
2. Click **[Edit]** button
3. Modify stem, options, answer, etc.
4. Change Bloom level or Complexity (if needed)
5. Click **[Save]**
6. System creates new version record
7. Old version preserved in version history
8. Confirmation: "Question updated. New version created."

---

### 4.3 Search & Filter Questions Workflow
**Goal:** Find specific questions for editing or assessment

1. Navigate to Question Bank list
2. Use search: "photosynthesis" → Real-time results
3. (Or) Set filters: Class=9th, Subject=Science, Bloom=Understanding
4. Click **[Filter]** button
5. View filtered results with custom columns
6. Click question → Detail view
7. Edit or assign to assessment

---

### 4.4 View Question Performance Workflow
**Goal:** Analyze how students perform on this question

1. Open question detail
2. Click **[Analytics]** tab
3. View metrics: Average score, Pass rate, Difficulty index
4. See option-wise performance (which options students selected)
5. Check recommendation (is this question working well?)
6. Identify if question needs revision (low discrimination)
7. Export analytics report for teacher use

---

### 4.5 Bulk Import Questions Workflow
**Goal:** Import many questions from CSV/Excel

1. Click **[Bulk Import]** from list view
2. Download template CSV
3. Fill template with questions (stem, options, marks, etc.)
4. Upload CSV file
5. System validates format and data
6. Preview: Show first 10 questions for confirmation
7. Click **[Import]** → Creates all questions
8. System shows: "200 questions imported successfully"
9. Log file shows any validation errors

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Color Coding
- Question ID: Dark blue (#1976D2), monospace
- Question Type: Per type (MCQ=Blue, SA=Orange, etc.)
- Bloom Level: Per level color (Remembering=Light Blue, etc.)
- Status Badge: Green (Active), Gray (Inactive)

### 5.2 Typography
- Stem preview: Regular, 14px, line-height 1.5
- Question Type badge: Bold, 12px
- Meta info: Light gray, 12px
- Options in detail: Regular, 13px

### 5.3 Layout Principles
- List view: Narrow stem preview (truncate at 60 chars)
- Detail view: Full stem with formatting
- Step-by-step form: Progress indicator (1/3, 2/3, 3/3)
- Rich text editor: Minimal toolbar (Bold, Italic, Lists, Links)

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 ARIA Labels
- Question row: aria-label="Question Q001: What is photosynthesis? MCQ Single, Remembering level"
- Detail tabs: aria-selected="true" for active tab
- Correct option: aria-label="Correct answer (marked with checkmark)"

### 6.2 Keyboard Navigation
- Tab through list rows
- Enter to open detail
- Esc to close modals
- Alt+S to save (in form)
- Alt+N for new question

### 6.3 Screen Reader Support
- Announce question ID and stem clearly
- Read question type and attributes
- Describe option selection (correct/incorrect)
- Read analytics metrics as text (not just charts)

### 6.4 Responsive Design
- **Desktop:** Full table with all columns, side panels
- **Tablet:** Stacked columns, modal detail view
- **Mobile:** Single column list, full-width detail view

---

## 7. EDGE CASES & ERROR SCENARIOS

### 7.1 Delete Question Used in Active Assessment
**Scenario:** User tries to delete question used in 5 active quizzes
```
Warning: "This question is used in 5 active assessments. Delete anyway?"
Options: [Cancel] [Delete and Reassign] [Delete Anyway]
Action: Reassign to similar question or archive instead of delete
```

### 7.2 No Correct Option Selected
**Scenario:** User saves MCQ without marking correct answer
```
Error: "Please mark at least one correct option before saving."
Action: Highlight options section, show validation error
```

### 7.3 Rich Text Formatting Errors
**Scenario:** User pastes formatted text with unsupported tags
```
Action: Auto-strip unsupported HTML tags, keep only allowed formatting
Message: "Some formatting was removed. Only basic formatting supported."
```

### 7.4 Import File Validation
**Scenario:** CSV has missing stem for 10 questions
```
Error Summary: "10 rows failed validation (missing stem)"
Action: Show preview of failed rows with error messages
Option: [Skip Failed Rows] [Fix and Re-upload]
```

---

## 8. PERFORMANCE CONSIDERATIONS

- List view: Paginate by 25 items, lazy-load thumbnails
- Search: Debounce 500ms, search stem + tags only (not options)
- Detail view: Lazy-load tabs (only load clicked tab content)
- Analytics: Cache for 1 hour, async calculation job
- Option rendering: Use virtual scrolling for 100+ options
- Media: Lazy-load images, use thumbnails

---

## 9. TESTING CHECKLIST

### 9.1 Functional Testing
- [ ] Create question with all required fields
- [ ] Create MCQ with 4 options, mark correct
- [ ] Create SA/LA question (no options)
- [ ] Edit question stem, marks, complexity
- [ ] Delete question (verify warning if used)
- [ ] Search by question text
- [ ] Filter by class/subject/lesson/topic
- [ ] Filter by Bloom/Complexity/Type
- [ ] View question detail with all tabs
- [ ] View analytics and performance metrics
- [ ] Export questions to CSV
- [ ] Import questions from CSV
- [ ] Version history shows all changes
- [ ] Revert to previous version works
- [ ] Bulk select and export
- [ ] Tags work correctly
- [ ] Media attachment works
- [ ] Rich text formatting preserved

### 9.2 UI/UX Testing
- [ ] Question stem preview truncates correctly
- [ ] Type badge displays with correct color
- [ ] List table sorts by any column
- [ ] Filters apply correctly
- [ ] Detail tabs load without delay
- [ ] Rich text editor toolbar works
- [ ] Options reorderable (drag/drop)
- [ ] Media previews display correctly
- [ ] Analytics charts render smoothly
- [ ] Responsive layout works on mobile
- [ ] Search autocomplete works

### 9.3 Integration Testing
- [ ] Create question → Appears in list
- [ ] Edit question → Changes visible in list
- [ ] Delete question → Removed from list
- [ ] Assign to assessment → Question available in assessment
- [ ] Student attempts question → Analytics updated
- [ ] Export includes all metadata
- [ ] Import creates questions with correct attributes
- [ ] Version changes tracked correctly
- [ ] Media associations preserved

### 9.4 Accessibility Testing
- [ ] Tab order logical in forms
- [ ] Question stem readable in screen reader
- [ ] Options announced clearly
- [ ] Rich text editor keyboard accessible
- [ ] Color contrast ≥ 4.5:1
- [ ] Form labels associated with inputs
- [ ] Error messages linked to fields
- [ ] Tables have headers and scope
- [ ] Charts have text alternatives

---

## 10. FUTURE ENHANCEMENTS

- **Question Editor AI:** Auto-generate MCQ options from stem
- **Plagiarism Detection:** Check student answers for copying
- **Speech-to-Text Question Creation:** Create questions by voice
- **Question Template Library:** Pre-formatted templates per type
- **Adaptive Question Difficulty:** Auto-adjust difficulty during quiz
- **Question Recommendation Engine:** Suggest similar questions for review
- **Collaborative Question Creation:** Multiple teachers editing together
- **Mobile Question Creator:** Create questions on tablet/mobile
- **Video Question Support:** Include video in question stem
- **3D Model Support:** Embed interactive 3D models in questions

---

## APPENDIX

### A. Question Type Field Mapping

| Type | Stem | Options | Marks | Negative | Time |
|------|------|---------|-------|----------|------|
| MCQ Single | Required | 2-10 | Yes | Yes | Optional |
| MCQ Multi | Required | 2-10 | Yes | Yes | Optional |
| Short Answer | Required | No | Yes | No | Optional |
| Long Answer | Required | No | Yes | No | Optional |
| Fill Blank | Required | 2-5 | Yes | No | Optional |
| Matching | Required | Pairs | Yes | No | Optional |
| True/False | Required | 2 | Yes | Yes | Optional |
| Numeric | Required | No | Yes | Yes | Optional |
| Coding | Required | No | Yes | No | Required |

### B. Question Difficulty vs. Bloom Level Matrix

| Bloom | Easy | Medium | Difficult |
|-------|------|--------|-----------|
| Remembering | ✓✓✓ | ✓ | ✗ |
| Understanding | ✓✓ | ✓✓ | ✓ |
| Applying | ✓ | ✓✓ | ✓✓ |
| Analyzing | ✗ | ✓ | ✓✓✓ |
| Evaluating | ✗ | ✓ | ✓✓✓ |
| Creating | ✗ | ✗ | ✓✓✓ |

