# Screen Design Specification: Assessment Sections
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Assessment Sections Module**, enabling educators to organize complex assessments and exams into multiple parts (Part A, Part B, Part C, etc.) with section-specific instructions, mark allocations, time hints, and question groupings.

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
- sch_assessment_sections
  ├── id (BIGINT PRIMARY KEY)
  ├── assessment_id (FK to sch_assessments)
  ├── section_name (VARCHAR 255) - "Part A: MCQ", "Part B: Short Answer"
  ├── marks (INT) - Marks allocated to this section
  ├── ordinal (INT) - Display order (1, 2, 3...)
  ├── instructions (TEXT) - "Answer all 20 questions"
  ├── duration_hint_minutes (INT) - Suggested time (30, 40, 50 min)
  ├── question_selection_type (ENUM: FIXED, CHOOSE_N_OF_M)
  ├── min_questions_to_answer (INT) - If CHOOSE_N_OF_M: answer 4 of 5
  ├── created_by (FK to sys_users)
  └── created_at (TIMESTAMP)

**Related Tables:**
- sch_assessment_items → Questions in this section

---

## 2. SCREEN LAYOUTS

### 2.1 Assessment Sections Management (Within Assessment Edit)
**Route:** `/curriculum/assessments/{assessmentId}/edit` → Step 2: Structure

#### 2.1.1 Layout (Section Builder)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ CREATE ASSESSMENT > STEP 2: ASSESSMENT STRUCTURE                           │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Total Assessment Marks:  [50 marks]
│ Passing Marks:          [20 marks]
│
│ ═════════════════════════════════════════════════════════════════════════
│ ADD SECTIONS:
│
│ [Section 1]
│ ┌──────────────────────────────────────────────────────────────────────┐
│ │ PART A: MULTIPLE CHOICE QUESTIONS                                    │
│ │                                                                      │
│ │ Section Name *     [Part A: MCQ                                    ] │
│ │ Marks *            [20]                                             │
│ │ Ordinal *          [1]  (Display order)                             │
│ │                                                                      │
│ │ Duration Hint      [30] minutes                                     │
│ │ (Suggested time for students)                                       │
│ │                                                                      │
│ │ Instructions *                                                       │
│ │ ┌──────────────────────────────────────────────────────────────────┐
│ │ │ Answer all 20 questions. Each correct answer = 1 mark.           │
│ │ │ No negative marking. All questions are compulsory.               │
│ │ └──────────────────────────────────────────────────────────────────┘
│ │                                                                      │
│ │ Question Selection Type *  [FIXED ▼]                               │
│ │ (Options: FIXED = Answer all questions                             │
│ │           CHOOSE_N_OF_M = Answer N out of M)                       │
│ │                                                                      │
│ │ [Edit Questions for this Section] [Preview Section] [+ Add Question]
│ │                                                                      │
│ │ Questions in this section:  20 total                               │
│ │ • Q234: What is photosynthesis?                                    │
│ │ • Q235: Chlorophyll function?                                      │
│ │ • Q236: Light reactions location?                                  │
│ │ ... (18 more)                                                       │
│ │                                                                      │
│ │ [Edit] [Remove Section] [Move Up] [Move Down]                      │
│ └──────────────────────────────────────────────────────────────────────┘
│
│ [Section 2]
│ ┌──────────────────────────────────────────────────────────────────────┐
│ │ PART B: SHORT ANSWER QUESTIONS                                       │
│ │                                                                      │
│ │ Section Name *     [Part B: Short Answer                          ] │
│ │ Marks *            [20]                                             │
│ │ Ordinal *          [2]                                              │
│ │                                                                      │
│ │ Duration Hint      [40] minutes                                     │
│ │                                                                      │
│ │ Instructions *                                                       │
│ │ ┌──────────────────────────────────────────────────────────────────┐
│ │ │ Answer any 4 out of 5 questions. Each = 5 marks.                │
│ │ │ Write clear and concise answers within 30-50 words.             │
│ │ └──────────────────────────────────────────────────────────────────┘
│ │                                                                      │
│ │ Question Selection Type *  [CHOOSE_N_OF_M ▼]                       │
│ │                                                                      │
│ │ Answer N out of M questions:  [4] out of [5] questions            │
│ │ Each Question Worth:  [5] marks                                     │
│ │                                                                      │
│ │ Questions in this section:  5 total                                │
│ │ • Q245: Explain light-dependent reactions                          │
│ │ • Q246: Describe Calvin cycle                                      │
│ │ • Q247: Factors affecting photosynthesis                           │
│ │ • Q248: Compare C3 and C4 plants                                   │
│ │ • Q249: Dark reactions in detail                                   │
│ │                                                                      │
│ │ [Edit] [Remove Section] [Move Up] [Move Down]                      │
│ └──────────────────────────────────────────────────────────────────────┘
│
│ [Section 3]
│ ┌──────────────────────────────────────────────────────────────────────┐
│ │ PART C: LONG ANSWER QUESTIONS                                        │
│ │                                                                      │
│ │ Section Name *     [Part C: Long Answer                           ] │
│ │ Marks *            [10]                                             │
│ │ Ordinal *          [3]                                              │
│ │                                                                      │
│ │ Duration Hint      [20] minutes                                     │
│ │                                                                      │
│ │ Instructions *                                                       │
│ │ ┌──────────────────────────────────────────────────────────────────┐
│ │ │ Answer any 1 out of 2 questions. Each = 10 marks.               │
│ │ │ Write detailed, comprehensive answers (300+ words).             │
│ │ └──────────────────────────────────────────────────────────────────┘
│ │                                                                      │
│ │ Question Selection Type *  [CHOOSE_N_OF_M ▼]                       │
│ │                                                                      │
│ │ Answer N out of M questions:  [1] out of [2] questions            │
│ │ Each Question Worth:  [10] marks                                    │
│ │                                                                      │
│ │ Questions in this section:  2 total                                │
│ │ • Q250: Detailed photosynthesis explanation (essay)                │
│ │ • Q251: Environmental implications of photosynthesis              │
│ │                                                                      │
│ │ [Edit] [Remove Section] [Move Up] [Move Down]                      │
│ └──────────────────────────────────────────────────────────────────────┘
│
│ [+ Add Another Section]
│
│ ─────────────────────────────────────────────────────────────────────
│ SECTION SUMMARY:
│ • Part A (MCQ): 20 marks, 30 min, 20 questions (FIXED)
│ • Part B (Short Answer): 20 marks, 40 min, 5 questions (Answer 4 of 5)
│ • Part C (Long Answer): 10 marks, 20 min, 2 questions (Answer 1 of 2)
│ ─────────────────────────────────────────────────────────────────────
│ Total: 50 marks, 90 min suggested, 27 questions
│
│ [Back to Step 1] [Next: Grading Rules] [Cancel]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.2 Student View During Assessment (Section-by-Section)
**Route:** `/student/assessments/{assessmentId}/attempt` → During exam

#### 2.2.1 Layout (Taking Exam - Section View)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ Unit 3 - Photosynthesis Assessment        Time Left: 45:22   [Submit]      │
├────────────────────────────────────────────────────────────────────────────┤
│
│ SECTION: PART A - MULTIPLE CHOICE QUESTIONS
│ Time Allocated: 30 minutes | Marks: 20/50
│ 
│ Instructions:
│ "Answer all 20 questions. Each correct answer = 1 mark. No negative marking."
│
│ ─────────────────────────────────────────────────────────────────────────
│ Progress in Section: 5 of 20 questions answered [████░░░░░░░░░░░░░]
│
│ Question 1 of 20:
│ What is the primary site of photosynthesis in a plant cell?
│
│ A) ○ Mitochondria
│ B) ○ Chloroplast
│ C) ○ Ribosome
│ D) ○ Nucleus
│
│ ─────────────────────────────────────────────────────────────────────────
│ NAVIGATION:
│ [< Previous Section: Part 0] [Next Section: Part B >]
│ [Jump to Q#: 1 ▼]
│ [Review All Sections] [Review This Section]
│
│ Section Status Panel (Right Sidebar):
│ ┌────────────────────────────────────────────┐
│ │ PART A: 5/20 answered (25%)                 │
│ │ PART B: 0/5 answered (0%)                  │
│ │ PART C: 0/2 answered (0%)                  │
│ │                                            │
│ │ Q1 ✓ Q2 ✓ Q3 ○ Q4 ✓ Q5 ○ Q6 ○  [Scroll]  │
│ │ Q7 ✓ Q8 ○ Q9 ○ Q10 ○ Q11 ○ Q12 ○         │
│ │ ...                                        │
│ │                                            │
│ │ [Complete All] [Partially Complete]       │
│ └────────────────────────────────────────────┘
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Section-Based Results View
**Route:** `/student/assessments/{assessmentId}/results`

#### 2.3.1 Layout (Results Breakdown by Section)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ ASSESSMENT RESULTS: Unit 3 - Photosynthesis Assessment                    │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Overall Score: 36 / 50 marks (72%)  [Performance: Good]
│
│ ═════════════════════════════════════════════════════════════════════════
│ PART A: MULTIPLE CHOICE QUESTIONS (20 marks)
│ ─────────────────────────────────────────────────────────────────────────
│
│ Your Score: 18 / 20 marks (90%)  [Grade: A]
│
│ Questions Answered: 20 / 20 (100%)
│ Correct: 18 | Incorrect: 2 | Skipped: 0
│
│ Performance: [██████████████████░░]
│
│ Questions Analysis:
│ ✓ Q1: Correct - "Primary site of photosynthesis" → Chloroplast
│ ✓ Q2: Correct - "Function of stomata"
│ ✗ Q3: Incorrect - You answered A, Correct: B  [Feedback: ...]
│   Your Answer: Mitochondria is site of photosynthesis
│   Correct Answer: Chloroplast is site
│   Explanation: Chloroplasts contain chlorophyll needed for light absorption
│
│ ... (more questions)
│
│ ═════════════════════════════════════════════════════════════════════════
│ PART B: SHORT ANSWER QUESTIONS (20 marks)
│ ─────────────────────────────────────────────────────────────────────────
│
│ Your Score: 12 / 20 marks (60%)  [Grade: C]
│
│ Questions Answered: 4 / 5 (80%) [Choose 4 of 5]
│ You chose: Q1, Q2, Q3, Q4
│ Skipped: Q5
│
│ Answers Evaluation:
│
│ Q1: Explain light-dependent reactions
│ Your Answer: "Light-dependent reactions occur in thylakoids..."
│ Marks Awarded: 5/5  ✓ Perfect
│ Feedback: Excellent coverage of photolysis, electron transport, ATP synthesis
│
│ Q2: Describe Calvin cycle
│ Your Answer: "Calvin cycle has 3 stages: carbon fixation, reduction..."
│ Marks Awarded: 3/5  ◐ Partial
│ Feedback: Good start, but missing details on regeneration phase
│
│ Q3: Factors affecting photosynthesis
│ Your Answer: "Temperature, light, CO2 concentration"
│ Marks Awarded: 2/5  ○ Needs Improvement
│ Feedback: Too brief. Explain how each factor affects rate and mechanism.
│
│ Q4: Compare C3 and C4 plants
│ Your Answer: "C3 plants fix CO2 once, C4 plants fix CO2 twice..."
│ Marks Awarded: 2/5  ○ Needs Improvement
│ Feedback: Correct concept, but lacks details on photorespiration, efficiency
│
│ Q5: [SKIPPED - Not attempted]
│
│ ═════════════════════════════════════════════════════════════════════════
│ PART C: LONG ANSWER QUESTIONS (10 marks)
│ ─────────────────────────────────────────────────────────────────────────
│
│ Your Score: 6 / 10 marks (60%)  [Grade: C]
│
│ Questions Answered: 1 / 2 (50%) [Choose 1 of 2]
│ You answered: Q1
│ Skipped: Q2
│
│ Q1: Detailed photosynthesis explanation (essay)
│ Your Answer: [500+ word essay shown]
│ Marks Awarded: 6/10  ◐ Partial
│ Feedback: Good understanding of overall process. Lacks molecular detail on
│           electron transport chain. Consider adding quantum yield information.
│ Teacher Comment: "Good effort. Review electron transport and come for clarification."
│
│ Q2: [SKIPPED - Not attempted]
│
│ ═════════════════════════════════════════════════════════════════════════
│ SECTION SUMMARY TABLE:
│ ┌──────────────────────┬────────┬────────┬────────┬────────┐
│ │ Section              │ Score  │ Marks  │ Grade  │ Time   │
│ ├──────────────────────┼────────┼────────┼────────┼────────┤
│ │ Part A (MCQ)         │ 18/20  │ 90%    │ A      │ 28 min │
│ │ Part B (Short Ans)   │ 12/20  │ 60%    │ C      │ 42 min │
│ │ Part C (Long Ans)    │ 6/10   │ 60%    │ C      │ 20 min │
│ ├──────────────────────┼────────┼────────┼────────┼────────┤
│ │ TOTAL                │ 36/50  │ 72%    │ B      │ 90 min │
│ └──────────────────────┴────────┴────────┴────────┴────────┘
│
│ [Download Result Slip] [View Detailed Feedback] [Review Assessment]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Assessment Section
```json
POST /api/v1/assessments/{assessmentId}/sections
{
  "section_name": "Part A: Multiple Choice Questions",
  "marks": 20,
  "ordinal": 1,
  "duration_hint_minutes": 30,
  "instructions": "Answer all 20 questions. Each correct answer = 1 mark.",
  "question_selection_type": "FIXED",
  "questions": [
    { "question_id": 234, "ordinal": 1 },
    { "question_id": 235, "ordinal": 2 }
  ]
}
```

### 3.2 Section Created Response
```json
{
  "success": true,
  "data": {
    "id": 101,
    "assessment_id": "A001",
    "section_name": "Part A: MCQ",
    "marks": 20,
    "ordinal": 1,
    "question_count": 20,
    "created_at": "2024-12-01T10:00:00Z"
  }
}
```

### 3.3 Get Assessment Sections
```
GET /api/v1/assessments/{assessmentId}/sections
Response: Array of all sections with question counts and marks
```

### 3.4 Update Section Order
```json
PATCH /api/v1/assessments/{assessmentId}/sections/reorder
{
  "sections": [
    { "section_id": 101, "ordinal": 1 },
    { "section_id": 102, "ordinal": 2 },
    { "section_id": 103, "ordinal": 3 }
  ]
}
```

---

## 4. USER WORKFLOWS

### 4.1 Create Multi-Section Assessment Workflow
**Goal:** Structure assessment with distinct parts

1. Open assessment creation form
2. Go to **STEP 2: Assessment Structure**
3. For each section:
   - Enter name: "Part A: MCQ"
   - Set marks: 20
   - Set duration hint: 30 minutes
   - Write instructions
   - Choose selection type: FIXED (all questions)
4. Add questions to section
5. Repeat for Parts B, C
6. View summary showing all sections
7. Continue to grading rules
8. Publish assessment

---

### 4.2 Take Section-Based Assessment Workflow
**Goal:** Complete assessment by sections

1. Start assessment
2. System shows: "PART A: MCQ (30 min, 20 marks)"
3. Read instructions: "Answer all 20 questions..."
4. Answer 20 MCQ questions
5. Sidebar shows progress: "5/20 answered"
6. Click **[Next Section]**
7. System shows: "PART B: Short Answer"
8. Read instructions: "Answer any 4 of 5..."
9. Answer 4 short answer questions
10. Click **[Next Section]**
11. System shows: "PART C: Long Answer"
12. Answer 1 long answer essay
13. Click **[Submit Assessment]**

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Section Styling
- Section headers: Bold, 18px, dark blue
- Section marks: Bold, green, 14px
- Duration hint: Gray, italic, 12px
- Instructions: Black, 13px, paragraph style

### 5.2 Progress Indication
- Section progress bar (filled left to right)
- Question status: ✓ (answered), ○ (unanswered), ⚠ (flagged)
- Score display: Large font, color-coded (green/amber/red)

### 5.3 Results Section
- Section-wise score cards with color bands (A-E)
- Bar charts for visual comparison
- Question feedback indented under each question

---

## 6. TESTING CHECKLIST

### 6.1 Functional Testing
- [ ] Create section with FIXED selection type
- [ ] Create section with CHOOSE_N_OF_M type
- [ ] Add questions to section
- [ ] Reorder sections (move Part B before Part A)
- [ ] Delete section (if no attempts)
- [ ] Edit section instructions
- [ ] Section marks sum to total assessment marks
- [ ] Choose N of M validation (4 of 5, 1 of 2)
- [ ] Calculate section scores correctly
- [ ] Display section-wise results
- [ ] Export section-wise breakdown

### 6.2 UI/UX Testing
- [ ] Sections display in correct order
- [ ] Section headers distinguishable
- [ ] Instructions clear and readable
- [ ] Progress bar updates per section
- [ ] Navigation between sections smooth
- [ ] Results breakdown clear by section
- [ ] Mobile view shows sections properly

### 6.3 Integration Testing
- [ ] Student sees correct section questions
- [ ] Attempt linked to assessment and sections
- [ ] Results stored per section
- [ ] Analytics show section-wise breakdown

### 6.4 Performance Testing
- [ ] Load assessment with 10 sections
- [ ] Navigate between sections <1 sec
- [ ] Calculate results for 5-section assessment quickly

### 6.5 Accessibility Testing
- [ ] Section headers semantic (H2, H3)
- [ ] Instructions readable by screen reader
- [ ] Navigation buttons labeled clearly
- [ ] Progress indicator announced

---

## 7. FUTURE ENHANCEMENTS

- **Section Randomization:** Shuffle section order for each student
- **Conditional Sections:** Show Section B only if Section A score > 50%
- **Section Timer Enforcement:** Auto-move to next section after time expires
- [ ] Section-wise answer keys: Different rubrics per section
- **Section Analytics:** Compare performance across sections
- **Section Difficulty:** Adjust section difficulty based on performance
- **Voice Instructions:** Audio instructions for each section
- **Section Templates:** Pre-built section structures for standard assessments
- **Section Weights:** Different weightage for different sections in grade calculation
- **Section Branching:** Multi-level assessments with section branches

