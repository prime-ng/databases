# Screen Design Specification: Assessment Items
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Assessment Items Module**, enabling educators to map individual questions to assessments with marks allocation, negative marking rules, option shuffling settings, and detailed question metadata.

### 1.2 User Roles & Permissions
| Role         | Create | View | Update | Delete | Print | Export | Import |
|--------------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| PG Support   |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| School Admin |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Principal    |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Teacher      |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Student      |   ✗    |   ✓  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |
| Parents      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |

### 1.3 Data Context

**Database Tables:**
- sch_assessment_items
  ├── id (BIGINT PRIMARY KEY)
  ├── assessment_id (FK to sch_assessments)
  ├── assessment_section_id (FK) - Which part of assessment
  ├── question_id (FK to sch_questions)
  ├── ordinal (INT) - Question order (1, 2, 3...)
  ├── marks (INT) - Marks for this question (e.g., 2 marks)
  ├── negative_mark (DECIMAL) - Negative mark per wrong (-0.5)
  ├── shuffle_options (BOOLEAN) - Randomize options for each student?
  ├── partial_credit_enabled (BOOLEAN)
  └── created_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Assessment Items List (Within Assessment Edit)
**Route:** `/curriculum/assessments/{assessmentId}/edit/items`

#### 2.1.1 Layout (Question Mapping Interface)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ ASSESSMENT ITEMS: Unit 3 - Photosynthesis Assessment                       │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Total Marks: 50 | Total Questions: 27
│ Average Marks per Question: 1.85
│
│ Filter: [Section: All ▼] [Question Type: All ▼] [Status: All ▼]
│ Search: [Search by question ID or stem...]
│
│ ┌──────┬───────────────────────────┬─────────┬──────────┬────────┬────────┐
│ │ Ord  │ Question Stem             │ Type    │ Marks    │ Neg    │ Shuffle│
│ ├──────┼───────────────────────────┼─────────┼──────────┼────────┼────────┤
│ │ 1    │ Q0234: What is           │ MCQ     │ 1        │ 0.00   │ ✓      │
│ │ (PA) │ photosynthesis?          │         │ marks    │        │        │
│ │      │                          │         │          │        │        │
│ ├──────┼───────────────────────────┼─────────┼──────────┼────────┼────────┤
│ │ 2    │ Q0235: Chlorophyll       │ MCQ     │ 1        │ 0.00   │ ✓      │
│ │ (PA) │ function in leaf?        │         │ marks    │        │        │
│ │      │                          │         │          │        │        │
│ ├──────┼───────────────────────────┼─────────┼──────────┼────────┼────────┤
│ │ 3    │ Q0236: Light reactions   │ MCQ     │ 1        │ 0.00   │ ✓      │
│ │ (PA) │ location in chloroplast? │         │ marks    │        │        │
│ │      │                          │         │          │        │        │
│ │ ...  │ [More questions]         │         │          │        │        │
│ ├──────┼───────────────────────────┼─────────┼──────────┼────────┼────────┤
│ │ 21   │ Q0245: Explain light     │ SA      │ 5        │ 0.00   │ ✗      │
│ │ (PB) │ -dependent reactions?    │         │ marks    │        │        │
│ │      │                          │         │          │        │        │
│ ├──────┼───────────────────────────┼─────────┼──────────┼────────┼────────┤
│ │ 26   │ Q0250: Detailed photo... │ LA      │ 10       │ 0.00   │ ✗      │
│ │ (PC) │ synthesis explanation?   │         │ marks    │        │        │
│ │      │                          │         │          │        │        │
│ └──────┴───────────────────────────┴─────────┴──────────┴────────┴────────┘
│
│ [Edit Item] [Add Question] [Reorder] [Bulk Edit] [Export List]
│
│ Legend: (PA) = Part A, (PB) = Part B, (PC) = Part C
│         SA = Short Answer, LA = Long Answer
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.2 Edit Assessment Item
**Route:** `/curriculum/assessments/{assessmentId}/items/{itemId}/edit`

#### 2.2.1 Layout (Item Edit Modal)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ EDIT ASSESSMENT ITEM: Q0234                                 [Save] [Cancel] │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Assessment Section *    [Part A: MCQ        ▼]
│ Ordinal *              [1]  (Question position)
│
│ ─────────────────────────────────────────────────────────────────────────
│ QUESTION INFORMATION (Read-only - from question bank):
│ 
│ Question ID            Q0234
│ Stem                   "What is photosynthesis?"
│ Type                   MCQ Single Select
│ Correct Answer         B - "Process using light energy to make food"
│ Topic                  Ch-3: Photosynthesis
│ Bloom Level            Understand (L2)
│ Complexity             Easy
│ Cognitive Skill        Memory Recall
│
│ ─────────────────────────────────────────────────────────────────────────
│ ASSESSMENT-SPECIFIC SETTINGS:
│
│ Marks for This Question * [1]  marks
│ (Total assessment marks updated: 50 → 50)
│
│ Negative Marking for Wrong Answer:
│ ○ No negative marking (MCQ auto-correct)
│ ● Apply negative mark: [-0.00]  marks
│   (If student selects wrong option, deduct this amount)
│
│ Shuffle Options:
│ ✓ Shuffle answer options for each student
│   (Options A/B/C/D randomized differently per student)
│
│ Partial Credit:
│ ☐ Enable partial credit for this question
│   (For MCQ multiple select: 0.25 mark per correct option selected)
│
│ Answer Reveal:
│ ☑ Show correct answer after submission
│ ☑ Show explanation text
│ ☐ Show student's previous attempt answer
│
│ ─────────────────────────────────────────────────────────────────────────
│ ITEM-SPECIFIC METADATA:
│
│ Difficulty Index (from analytics): 0.78
│ Discrimination Index: 0.65 (GOOD)
│ Expected Time: 1-2 minutes
│
│ Question Usage Stats:
│ • Used in 4 other assessments
│ • Used in 2 practice quizzes
│ • Total student attempts: 145
│ • Average score: 89% (Good)
│
│ ─────────────────────────────────────────────────────────────────────────
│
│ [Save Item Settings] [Remove from Assessment] [View Question] [Cancel]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Bulk Edit Items
**Route:** `/curriculum/assessments/{assessmentId}/items/bulk-edit`

#### 2.3.1 Layout (Bulk Operations)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ BULK EDIT ASSESSMENT ITEMS                                    [Done] [Canc] │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Select Items to Edit:  [Select All] [Deselect All] [Clear Filters]
│
│ ┌──────┬───────────────────────────┬─────────┬──────────────────────────┐
│ │ ☑    │ Q0234: What is           │ MCQ     │ Marks: [1]  Neg: [0.00] │
│ │      │ photosynthesis?          │         │ Shuffle: ✓              │
│ ├──────┼───────────────────────────┼─────────┼──────────────────────────┤
│ │ ☑    │ Q0235: Chlorophyll       │ MCQ     │ Marks: [1]  Neg: [0.00] │
│ │      │ function?                │         │ Shuffle: ✓              │
│ ├──────┼───────────────────────────┼─────────┼──────────────────────────┤
│ │ ☑    │ Q0236: Light reactions   │ MCQ     │ Marks: [1]  Neg: [0.00] │
│ │      │ location?                │         │ Shuffle: ✓              │
│ │ [Selected: 20 items]                                                   │
│ └──────┴───────────────────────────┴─────────┴──────────────────────────┘
│
│ ─────────────────────────────────────────────────────────────────────────
│ BULK OPERATIONS:
│
│ Apply to Selected Items:
│
│ Marks (New Value):   [Leave as is ▼]  or  [Set all to: 2 marks]
│
│ Negative Mark:       [Leave as is ▼]  or  [Set all to: 0.25 marks]
│
│ Shuffle Options:     [Keep current ▼] or [Enable for All] [Disable All]
│
│ Partial Credit:      [Keep current ▼] or [Enable for All] [Disable All]
│
│ Show Answers:        [Keep current ▼] or [Show for All]   [Hide All]
│
│ ─────────────────────────────────────────────────────────────────────────
│ PREVIEW:
│ 
│ 20 selected items:
│ • Change marks to 2 marks → Total: 40 marks (from 20)
│ • Enable shuffling for all
│
│ [Apply Bulk Changes] [Cancel]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Add Assessment Item
```json
POST /api/v1/assessments/{assessmentId}/items
{
  "assessment_section_id": 101,
  "question_id": 234,
  "ordinal": 1,
  "marks": 2,
  "negative_mark": 0.25,
  "shuffle_options": true,
  "partial_credit_enabled": false,
  "show_answer_after_submission": true
}
```

### 3.2 Item Added Response
```json
{
  "success": true,
  "data": {
    "id": 1001,
    "assessment_id": "A001",
    "assessment_section_id": 101,
    "question_id": 234,
    "ordinal": 1,
    "marks": 2,
    "created_at": "2024-12-01T10:00:00Z",
    "total_assessment_marks": 50
  }
}
```

### 3.3 Get Assessment Items
```
GET /api/v1/assessments/{assessmentId}/items?section_id=101
Response: Array of 20+ items with metadata
```

### 3.4 Update Item
```json
PATCH /api/v1/assessments/{assessmentId}/items/{itemId}
{
  "marks": 2,
  "negative_mark": 0.5,
  "shuffle_options": true
}
```

### 3.5 Reorder Items
```json
PATCH /api/v1/assessments/{assessmentId}/items/reorder
{
  "items": [
    { "item_id": 1001, "ordinal": 1 },
    { "item_id": 1002, "ordinal": 2 },
    { "item_id": 1003, "ordinal": 3 }
  ]
}
```

---

## 4. USER WORKFLOWS

### 4.1 Add Questions to Assessment Workflow
**Goal:** Map individual questions with assessment-specific settings

1. Open assessment: "Unit 3 Assessment"
2. Go to **Assessment Items** tab
3. Click **[Add Question]**
4. Search/select: Q0234 "What is photosynthesis?"
5. Set marks: 1 mark (MCQ worth 1 mark)
6. Leave negative mark: 0.00
7. Enable shuffle: Yes
8. Click **[Add]**
9. Question added to assessment
10. Repeat for 26 more questions

---

### 4.2 Bulk Change Marks Workflow
**Goal:** Update marks for all MCQ questions

1. Open Assessment Items
2. Select all 20 MCQ questions
3. Click **[Bulk Edit]**
4. Set "Marks: 2 marks per question"
5. Preview: "Total changes: 20→40 marks"
6. Click **[Apply]**
7. All MCQ marks updated
8. Assessment total: 50 marks updated

---

### 4.3 Apply Negative Marking Workflow
**Goal:** Configure negative marking per wrong answer

1. Open Assessment Items
2. Select all MCQ items in Part A
3. Click **[Bulk Edit]**
4. Set negative mark: "0.25 per wrong"
5. Apply to 20 items
6. During exam: Wrong answer = -0.25 marks
7. Correct answer = +1 mark

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Item Display
- Ordinal: Bold, 12px
- Question stem: 13px, truncated to 50 chars
- Marks: Green, bold
- Negative mark: Red, if > 0
- Shuffle icon: Checkmark for enabled
- Section: (PA), (PB), (PC) abbreviations

### 5.2 Edit Modal
- Section dropdown highlighted
- Read-only question info in gray
- Editable fields (marks, negative) in white
- Toggle switches for yes/no options

---

## 6. TESTING CHECKLIST

### 6.1 Functional Testing
- [ ] Add question to assessment
- [ ] Set marks per question
- [ ] Configure negative marking
- [ ] Enable/disable shuffle options
- [ ] Reorder questions (move Q3 before Q1)
- [ ] Remove question from assessment
- [ ] Bulk edit 20+ questions
- [ ] Total marks calculated correctly
- [ ] Marks do not exceed assessment total
- [ ] Negative mark ≤ marks per question
- [ ] Partial credit validation
- [ ] Export items to CSV

### 6.2 UI/UX Testing
- [ ] Items list loads quickly (27 items)
- [ ] Edit modal opens smoothly
- [ ] Bulk edit preview accurate
- [ ] Reorder drag-and-drop smooth
- [ ] Search questions functional
- [ ] Filter by section/type works

### 6.3 Integration Testing
- [ ] Items linked to questions
- [ ] Items linked to sections
- [ ] Attempt answers linked to items
- [ ] Marks recorded correctly in results
- [ ] Negative marking applied in grading
- [ ] Shuffle options respected in exam

### 6.4 Performance Testing
- [ ] Load 100+ items without lag
- [ ] Bulk edit 50 items <2 sec
- [ ] Reorder 30 items instantly
- [ ] Export 100 items to CSV <5 sec

### 6.5 Accessibility Testing
- [ ] Item list keyboard navigable
- [ ] Edit modal keyboard accessible
- [ ] Marks input accepts keyboard entry
- [ ] Checkboxes for selection
- [ ] Labels associated with inputs

---

## 7. FUTURE ENHANCEMENTS

- **Smart Question Selection:** Auto-select questions by Bloom/difficulty
- **Import Questions from Pool:** Auto-add 10 random from pool
- **Item Analytics Display:** Show question discrimination per item
- **Conditional Items:** Show Q15 only if Q14 answered correctly
- **Item Weights:** Different weight per item in final score calculation
- **Item Difficulty Adjustment:** Adjust difficulty mid-assessment
- **Item Randomization:** Random item selection per student
- **Item Group Scoring:** Score groups of items together
- **Answer Key Management:** Detailed answer keys per item
- **Item Banking:** Create reusable question sets

