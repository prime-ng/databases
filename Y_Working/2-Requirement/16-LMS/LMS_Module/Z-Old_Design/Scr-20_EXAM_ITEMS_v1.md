# Screen Design Specification: Exam Items
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Exam Items Module**, enabling educators to configure individual exam questions with marks, negative marking, difficulty tracking, and comprehensive exam-specific grading rules that differ from regular assessments.

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
- sch_exam_items
  ├── id (BIGINT PRIMARY KEY)
  ├── exam_id (FK to sch_exams)
  ├── question_id (FK to sch_questions)
  ├── ordinal (INT) - Question order
  ├── marks (INT) - Total marks for this question
  ├── negative_mark (DECIMAL) - Negative mark per wrong
  ├── shuffle_options (BOOLEAN) - Randomize options?
  ├── expected_time_seconds (INT) - Suggested time (60-300 sec)
  ├── difficulty_level_id (FK) - Expected difficulty
  ├── is_compulsory (BOOLEAN) - Must attempt?
  └── created_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Exam Items Management
**Route:** `/curriculum/exams/{examId}/edit/items`

#### 2.1.1 Layout (Question Mapping)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ EXAM ITEMS: Final Exam - Biology (Class IX)                                │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Total Marks: 100 | Total Questions: 45 | Average Time: 120 minutes
│
│ Filter: [Section: All ▼] [Difficulty: All ▼] [Type: All ▼]
│ Search: [Search by question ID...]
│
│ ┌──────┬───────────────────────────┬──────────┬─────────┬──────────┬──────┐
│ │ Ord  │ Question Stem             │ Type     │ Marks   │ Neg Mark │ Time │
│ ├──────┼───────────────────────────┼──────────┼─────────┼──────────┼──────┤
│ │ 1    │ Q0234: What is           │ MCQ      │ 2       │ 0.50 ✓   │ 2m   │
│ │ (PA) │ photosynthesis?          │ Single   │ marks   │          │      │
│ ├──────┼───────────────────────────┼──────────┼─────────┼──────────┼──────┤
│ │ 2    │ Q0235: Chlorophyll       │ MCQ      │ 2       │ 0.50 ✓   │ 2m   │
│ │ (PA) │ function?                │ Single   │ marks   │          │      │
│ │ ...  │ [More MCQ items]         │          │         │          │      │
│ ├──────┼───────────────────────────┼──────────┼─────────┼──────────┼──────┤
│ │ 21   │ Q0245: Explain light     │ SA       │ 5       │ 0.00     │ 5m   │
│ │ (PB) │ -dependent reactions?    │          │ marks   │          │      │
│ ├──────┼───────────────────────────┼──────────┼─────────┼──────────┼──────┤
│ │ 36   │ Q0250: Detailed photo... │ LA       │ 10      │ 0.00     │ 10m  │
│ │ (PC) │ synthesis (500+ words)?  │          │ marks   │          │      │
│ └──────┴───────────────────────────┴──────────┴─────────┴──────────┴──────┘
│
│ [Edit Item] [Add Question] [Reorder] [Bulk Edit] [Print Question Sheet]
│
│ EXAM BLUEPRINT SUMMARY:
│ ┌─────────────────────────────────────────────────────────────────────┐
│ │ Part A (MCQ): 20 questions × 2 marks = 40 marks | Time: 40 min     │
│ │ Part B (SA): 15 questions, Answer 10, 5 marks ea = 50 marks | 50m  │
│ │ Part C (LA): 10 questions, Answer 3, 10 marks ea = 30 marks | 30m  │
│ │                                                                    │
│ │ Total: 100 marks in 120 minutes                                  │
│ └─────────────────────────────────────────────────────────────────────┘
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.2 Edit Exam Item Details
**Route:** `/curriculum/exams/{examId}/items/{itemId}/edit`

#### 2.2.1 Layout (Item Configuration)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ EDIT EXAM ITEM: Q0234                              [Save] [Preview] [Canc] │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Exam Section *         [Part A: MCQ                 ▼]
│ Ordinal *             [1]  (Position in exam)
│ Compulsory            [✓ Yes - Student must attempt]
│
│ ─────────────────────────────────────────────────────────────────────────
│ QUESTION INFORMATION (Read-only):
│
│ Question ID            Q0234
│ Stem                   "What is photosynthesis?"
│ Type                   MCQ Single Select
│ Correct Answer         B
│ Topic                  Ch-3: Photosynthesis
│ Bloom Level            Understand (L2)
│ Complexity             Easy
│ Created By             Sarah Teacher (2024-12-01)
│
│ ─────────────────────────────────────────────────────────────────────────
│ EXAM-SPECIFIC CONFIGURATION:
│
│ Marks for This Question * [2]  marks
│ Maximum possible marks in exam updated: 100
│
│ Negative Marking:
│ ☑ Apply negative marking
│   Per Wrong Answer: [-0.50]  marks
│   (Student gets +2 for correct, -0.50 for wrong, 0 for blank)
│
│ Shuffle Options:
│ ✓ Randomize answer options (A/B/C/D shuffled per student)
│
│ Time Allocation:
│ Expected Time: [2] minutes per question
│ (Total exam time: 2m × 45 = 90m, leaves 30m buffer)
│
│ Difficulty For Board Exam Context:
│ Question Difficulty: [Easy ▼]
│ Board Exam Difficulty Weight: [1.0x]  (Standard weight)
│ (Can adjust to 0.8x for easier, 1.2x for harder board questions)
│
│ Compulsory Attempt:
│ ☑ Student must attempt this question (cannot skip)
│ (For Boards: Usually all questions compulsory)
│
│ ─────────────────────────────────────────────────────────────────────────
│ ANSWER REVEAL SETTINGS (Exam-specific):
│
│ After submission, show:
│ ☑ Correct answer (A, B, C, or D shown)
│ ☑ Explanation text (if available in question)
│ ☑ Marks awarded (2 marks shown)
│ ☐ Student's previous attempt (for retakes)
│
│ Answer Visibility Date: [Same as exam date ▼]
│ (Options: Immediately, Exam date, +1 day, +7 days, Manual review)
│
│ ─────────────────────────────────────────────────────────────────────────
│ QUESTION ANALYTICS:
│
│ Discrimination Index: 0.72 (GOOD - Differentiates well)
│ Difficulty Index: 0.78 (Moderately Easy - 78% get it right)
│ Discrimination Status: ✓ GOOD (>0.65)
│
│ In Other Assessments: Used in 3 other quizzes/assessments
│ Total Attempts: 245 students
│ Average Score: 89% (High success rate - may be easy for Board exam)
│
│ ─────────────────────────────────────────────────────────────────────────
│
│ [Save Item] [Remove from Exam] [View Question] [Edit Question] [Cancel]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Exam Question Sheet Preview
**Route:** `/curriculum/exams/{examId}/preview`

#### 2.3.1 Layout (Student View - Question Sheet)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ FINAL EXAM - BIOLOGY (Class IX)                                            │
│ Date: 25-Dec-2024 | Time: 9:00 AM - 12:00 PM (180 minutes)                │
├────────────────────────────────────────────────────────────────────────────┤
│
│ INSTRUCTIONS:
│ • This exam consists of 45 questions divided into 3 parts
│ • Part A: 20 MCQ questions (2 marks each) - Compulsory
│ • Part B: 15 Short Answer questions (5 marks each) - Answer 10 out of 15
│ • Part C: 10 Long Answer questions (10 marks each) - Answer 3 out of 10
│ • Negative marking of -0.50 per wrong MCQ answer
│ • Total Time: 180 minutes
│
│ ═════════════════════════════════════════════════════════════════════════
│ PART A: MULTIPLE CHOICE QUESTIONS (40 marks)
│ ─────────────────────────────────────────────────────────────────────────
│ Instruction: Answer all 20 questions. [2 marks each, -0.50 negative]
│ Time: 40 minutes (2 minutes per question)
│
│ 1. What is photosynthesis?
│    A) Breakdown of glucose for energy
│    B) Process using light energy to make food from CO2 and H2O
│    C) Release of energy from organic molecules
│    D) Transport of water through plants
│
│ 2. Chlorophyll is located in:
│    A) Mitochondria
│    B) Nucleus
│    C) Chloroplast
│    D) Ribosome
│
│ ... [Questions 3-20] ...
│
│ ═════════════════════════════════════════════════════════════════════════
│ PART B: SHORT ANSWER QUESTIONS (50 marks)
│ ─────────────────────────────────────────────────────────────────────────
│ Instruction: Answer any 10 out of 15 questions. [5 marks each]
│ Time: 50 minutes (5 minutes per question average)
│
│ 21. Explain the light-dependent reactions in photosynthesis.
│
│ 22. Describe the Calvin cycle and its significance.
│
│ ... [Questions 23-35] ...
│
│ ═════════════════════════════════════════════════════════════════════════
│ PART C: LONG ANSWER QUESTIONS (30 marks)
│ ─────────────────────────────────────────────────────────────────────────
│ Instruction: Answer any 3 out of 10 questions. [10 marks each]
│ Time: 30 minutes (10 minutes per question average)
│
│ 36. Write a comprehensive essay on photosynthesis, covering:
│     a) Light reactions and location
│     b) Dark reactions (Calvin cycle)
│     c) Factors affecting photosynthesis
│     d) Significance in ecosystem
│
│ 37. Explain the differences between C3 and C4 photosynthetic pathways.
│
│ ... [Questions 38-45] ...
│
│ ═════════════════════════════════════════════════════════════════════════
│
│ EXAM STATISTICS:
│ • Total Questions: 45
│ • Total Marks: 100
│ • Passing: 40 marks (40%)
│ • Expected Duration: 180 minutes
│ • Blue Books Required: 1
│
│ [Print Exam] [Download PDF] [Share with Students] [Edit] [Publish]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Add Exam Item
```json
POST /api/v1/exams/{examId}/items
{
  "question_id": 234,
  "ordinal": 1,
  "marks": 2,
  "negative_mark": 0.50,
  "shuffle_options": true,
  "expected_time_seconds": 120,
  "is_compulsory": true,
  "difficulty_weight": 1.0
}
```

### 3.2 Item Added Response
```json
{
  "success": true,
  "data": {
    "id": 5001,
    "exam_id": "E001",
    "question_id": 234,
    "ordinal": 1,
    "marks": 2,
    "total_exam_marks": 100,
    "created_at": "2024-12-01T10:00:00Z"
  }
}
```

### 3.3 Get Exam Items
```
GET /api/v1/exams/{examId}/items
Response: Array of 45 items with metadata
```

### 3.4 Update Exam Item
```json
PATCH /api/v1/exams/{examId}/items/{itemId}
{
  "marks": 3,
  "negative_mark": 0.75,
  "expected_time_seconds": 180
}
```

---

## 4. USER WORKFLOWS

### 4.1 Build Board Exam Question Paper Workflow
**Goal:** Create comprehensive 100-mark board exam

1. Create exam: "Final Exam - Biology"
2. Go to **Exam Items**
3. Add 20 MCQ questions × 2 marks = 40 marks
4. Configure each: Negative mark = 0.50, Shuffle = Yes
5. Add 15 Short answer questions × 5 marks = 75 marks
6. Configure: Answer 10 of 15 (70-mark equivalent)
7. Add 10 Long answer questions × 10 marks = 100 marks
8. Configure: Answer 3 of 10 (30-mark equivalent)
9. Total: 40 + 50 + 30 = 100 marks
10. Review exam blueprint
11. Publish exam

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Item Difficulty Indicators
- Easy: Light blue background
- Medium: Amber background
- Difficult: Red background

### 5.2 Time Allocation Display
- Expected time: Right-aligned in item row
- Total exam time: Calculated at bottom
- Buffer time: Highlighted if remaining time too low

### 5.3 Negative Marking Display
- Checkmark if enabled
- Amount shown in red
- Formula: Correct = +2, Wrong = -0.5, Blank = 0

---

## 6. TESTING CHECKLIST

### 6.1 Functional Testing
- [ ] Add MCQ question with 2 marks
- [ ] Configure negative marking (0.50)
- [ ] Add short answer with 5 marks
- [ ] Add long answer with 10 marks
- [ ] Set expected time per question
- [ ] Enable/disable compulsory flag
- [ ] Reorder questions
- [ ] Remove question from exam
- [ ] Bulk edit 20+ exam items
- [ ] Calculate total marks correctly
- [ ] Print question sheet with all sections
- [ ] Preview exam as student would see

### 6.2 UI/UX Testing
- [ ] Exam items list displays correctly
- [ ] Item edit modal intuitive
- [ ] Time allocation calculated
- [ ] Negative marking shown clearly
- [ ] Question preview readable
- [ ] Difficulty indicators visible

### 6.3 Integration Testing
- [ ] Questions linked correctly
- [ ] Student attempts linked to exam items
- [ ] Negative marking applied during grading
- [ ] Shuffle options respected
- [ ] Compulsory questions enforced

### 6.4 Performance Testing
- [ ] Load 100 exam items quickly
- [ ] Generate question sheet PDF
- [ ] Calculate exam time distribution
- [ ] Bulk edit 50 items instantly

### 6.5 Accessibility Testing
- [ ] Question sheet printable
- [ ] Editable fields keyboard accessible
- [ ] Time display readable
- [ ] Difficulty labels descriptive

---

## 7. FUTURE ENHANCEMENTS

- **Auto Question Selection:** Suggest questions from question pool
- **Question Difficulty Distribution:** Auto-select Easy/Medium/Difficult mix
- **Bloom Distribution:** Ensure questions cover all Bloom levels
- **Time Optimization:** Alert if total time allocation seems wrong
- **Previous Exam Comparison:** Compare with last year's exam
- **Question Reuse Tracking:** Show if using same questions as last year
- **Board Exam Format:** Pre-built templates for CBSE/State boards
- **Difficulty Analytics:** Show discrimination index for each question
- **Multiple Exam Versions:** Create alternate versions for different sections
- **Secure Question Bank:** Protect questions from unauthorized access

