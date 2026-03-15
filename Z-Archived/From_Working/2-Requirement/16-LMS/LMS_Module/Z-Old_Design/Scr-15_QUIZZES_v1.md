# Screen Design Specification: Quizzes
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Quiz Management Module**, enabling educators to create practice, diagnostic, and reinforcement quizzes with flexible question selection, answer shuffling, immediate feedback, and time tracking.

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

**Database Table:** sch_quizzes
├── id (BIGINT PRIMARY KEY)
├── name (VARCHAR 255) - "Chapter 3 Practice Quiz"
├── quiz_type (ENUM: PRACTICE, DIAGNOSTIC, REINFORCEMENT)
├── subject_id, class_id (FK)
├── num_questions (INT) - Total questions in quiz
├── shuffle_questions (BOOLEAN) - Randomize question order?
├── shuffle_options (BOOLEAN) - Randomize answer options?
├── show_immediate_feedback (BOOLEAN) - Show answers right after submission?
├── time_limit_minutes (INT) - Optional 30, 45, 60 min limits
├── description (TEXT)
├── created_by (FK to sys_users)
├── created_at (TIMESTAMP)
└── is_active (BOOLEAN)

**Related Tables:**
- sch_quiz_items → Questions in this quiz
- sch_quiz_attempts → Student attempts at this quiz

---

## 2. SCREEN LAYOUTS

### 2.1 Quizzes List View
**Route:** `/curriculum/quizzes`

#### 2.1.1 Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ QUIZZES                                      [+ Create New Quiz] [Import]   │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Filter: [Type: All ▼] [Class: All ▼] [Status: All ▼] [Search...]          │
│
│ ┌──────┬────────────────────────┬──────────┬─────────┬──────────┬──────────┐
│ │ ID   │ Quiz Name              │ Type     │ Qs/TL   │ Feedback │ Created  │
│ ├──────┼────────────────────────┼──────────┼─────────┼──────────┼──────────┤
│ │ Q001 │ Ch-3 Practice Quiz      │ PRACTICE │ 15 / 30m│ Immediate│ 2024-12  │
│ │      │ (Biology IX)            │          │         │ After    │          │
│ ├──────┼────────────────────────┼──────────┼─────────┼──────────┼──────────┤
│ │ Q002 │ Photosynthesis Diag.    │ DIAGNOSTIC
│ │ Quiz │ (Optional 20m)          │          │ 20 / -  │ On       │ 2024-12  │
│ │      │                         │          │         │ Completion
│ ├──────┼────────────────────────┼──────────┼─────────┼──────────┼──────────┤
│ │ Q003 │ Respiration Reinforce   │ REINFORCEMENT          │ 10 / 45m│ On       │ 2024-12  │
│ │      │ Quiz (Biology IX)       │          │         │ Completion
│ └──────┴────────────────────────┴──────────┴─────────┴──────────┴──────────┘
│
│ [View] [Edit] [Delete] [Publish] [View Results]
│
│ Showing 1-3 of 12 quizzes | [Next]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.2 Create/Edit Quiz
**Route:** `/curriculum/quizzes/{quizId}/edit` or `/curriculum/quizzes/new`

#### 2.2.1 Layout (Multi-Step Form)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ CREATE QUIZ                                          [Save] [Preview] [Canc]│
├────────────────────────────────────────────────────────────────────────────┤
│
│ STEP 1: BASIC INFORMATION
│ ═════════════════════════════════════════════════════════════════════════
│
│ Quiz Name *              [Chapter 3 Practice Quiz              ]
│ Description              [Practice quiz for photosynthesis chapter]
│
│ Quiz Type *              [PRACTICE ▼]  (Options: PRACTICE, DIAGNOSTIC, REINFORCEMENT)
│
│ Class *                  [IX - Ninth Grade          ▼]
│ Subject *                [Biology                   ▼]
│
│ ─────────────────────────────────────────────────────────────────────────
│ STEP 2: QUESTION SELECTION
│ ═════════════════════════════════════════════════════════════════════════
│
│ Add Questions to Quiz:
│ 
│ Option A: Add Individual Questions
│ ─────────────────────────────────────
│ [Search Questions...              ] [+ Add Question]
│ 
│ ┌─────────────────────────────────────────────────────────────────────┐
│ │ ✓ Q0234: What is photosynthesis?                    [MCQ] [Remove] │
│ │ ✓ Q0235: Explain the light reactions...             [SA]  [Remove] │
│ │ ✓ Q0236: Which statement about chlorophyll...       [MCQ] [Remove] │
│ │ ✓ Q0237: Match the process to its location...       [MAT] [Remove] │
│ │ ✓ Q0238: Describe the Calvin cycle in detail...     [LA]  [Remove] │
│ │ ✓ Q0239: The primary function of stomata...         [MCQ] [Remove] │
│ │ ✓ Q0240: How does temperature affect photosynthes.. [SA]  [Remove] │
│ │                                                                    │
│ │ [+ Add More Questions]                                             │
│ └─────────────────────────────────────────────────────────────────────┘
│
│ Quiz Total: 7 Questions
│
│ Option B: Use Question Pool
│ ───────────────────────────
│ [Select Question Pool ▼ "Biology Chapter 3 Quiz Pool"]
│ Matching Questions: 47 → Draw [5] questions randomly
│ ☑ Reshuffle on each attempt
│
│
│ STEP 3: QUIZ SETTINGS
│ ═════════════════════════════════════════════════════════════════════════
│
│ Time Limit (Optional)    [30 min ▼]  [Unlimited]
│                          
│ Question Display         ☑ Shuffle question order (different for each student)
│ & Options                ☑ Shuffle answer options (A/B/C/D randomized)
│
│ Answer Display           ☑ Show immediate feedback after each question
│ & Feedback               ☑ Show answer explanation on feedback
│
│                          ☐ Show correct answer only (no explanation)
│                          ☐ Hide answers until quiz completion
│
│ Scoring Options          [Marks per question: 1 mark] 
│                          [Negative marking: None ▼]
│                          [Partial credit: Disabled]
│
│
│ STEP 4: PREVIEW & PUBLISH
│ ═════════════════════════════════════════════════════════════════════════
│
│ Quiz Summary:
│ • Type: PRACTICE Quiz
│ • Total Questions: 7
│ • Time Limit: 30 minutes
│ • Shuffle: Yes (questions & options)
│ • Feedback: Immediate after each question
│ • Total Marks: 7
│
│ Question Breakdown:
│ • MCQ: 4 questions (4 marks)
│ • Short Answer: 2 questions (2 marks)
│ • Matching: 1 question (1 mark)
│
│ [Edit] [Preview Quiz] [Save & Publish] [Save as Draft] [Cancel]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Take Quiz Interface
**Route:** `/student/quizzes/{quizId}/attempt`

#### 2.3.1 Quiz Taking Interface
```
┌────────────────────────────────────────────────────────────────────────────┐
│ Ch-3 Practice Quiz (Biology IX)           Time Remaining: 25:43   [Submit] │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Progress: Question 3 of 7 [████░░░░░░░░░░░░░░░░░░░░░░]
│
│ ─────────────────────────────────────────────────────────────────────────
│ QUESTION 3:
│ What is the primary function of chlorophyll in photosynthesis?
│ 
│ A) ○ To break down water molecules
│ B) ○ To absorb light energy
│ C) ○ To fix carbon dioxide
│ D) ○ To release oxygen
│
│ [Navigation: [< Previous] [Next >] [Jump to Q#: 1 ▼] [Review Questions]]
│
│ ─────────────────────────────────────────────────────────────────────────
│ REVIEW PANEL (Right Sidebar)
│ 
│ Questions Answered: 2 of 7
│ Questions Unanswered: 5
│ Flagged for Review: 1
│
│ Status:
│ ✓ Q1 (Answered)     (green)
│ ✓ Q2 (Answered)     (green)
│ ○ Q3 (Current)      (blue highlight)
│ ○ Q4 (Unanswered)   (white)
│ ○ Q5 (Unanswered)   (white)
│ ⚠ Q6 (Flagged)      (orange)
│ ○ Q7 (Unanswered)   (white)
│
│ [Flag This Question for Review]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.4 Quiz Results & Feedback
**Route:** `/student/quizzes/{quizId}/results`

#### 2.4.1 Results Summary
```
┌────────────────────────────────────────────────────────────────────────────┐
│ QUIZ RESULTS: Ch-3 Practice Quiz                                           │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Overall Performance:
│
│ Your Score: 5 / 7 marks (71%)  [Performance Level: Good]
│
│ Score Breakdown:
│ ┌─────────────────────────────────┐
│ │ Correct:  5    [██████░░░]      │
│ │ Incorrect: 2   [██░░░░░░░]      │
│ └─────────────────────────────────┘
│
│ Time Taken: 18:45 (9:20 slower than average)
│ Submitted: 2024-12-08 14:32
│
│ ─────────────────────────────────────────────────────────────────────────
│ QUESTION-BY-QUESTION REVIEW:
│
│ Q1: What is photosynthesis?                    ✓ CORRECT [1/1]
│     Your Answer: "Process where plants convert light to chemical energy"
│     Feedback: Great explanation! You've captured the essence perfectly.
│
│ Q2: Explain light reactions...                 ✓ CORRECT [1/1]
│     Your Answer: [Your answer text shown]
│     Feedback: Excellent understanding of the light-dependent reactions.
│
│ Q3: Which statement about chlorophyll...       ✗ INCORRECT [0/1]
│     Your Answer: D (Incorrect)
│     Correct Answer: B
│     Feedback: Remember, chlorophyll's primary role is to ABSORB light
│     energy. Option D (oxygen release) is a byproduct, not the primary
│     function. Review the light reactions section.
│
│ Q4-Q7: [Similarly formatted with feedback]
│
│ ─────────────────────────────────────────────────────────────────────────
│ RECOMMENDATION:
│
│ Based on your performance (71%), review these topics:
│ • Chlorophyll and light absorption (Q3 - 0%)
│ • Calvin cycle details (Q5 - 0%)
│
│ Strong areas:
│ • Photosynthesis definition (100%)
│ • Light reactions (100%)
│
│ [Take Quiz Again] [View Detailed Analytics] [Download Certificate]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Quiz
```json
POST /api/v1/quizzes
{
  "name": "Chapter 3 Practice Quiz",
  "quiz_type": "PRACTICE",
  "subject_id": 5,
  "class_id": 9,
  "description": "Practice quiz for photosynthesis",
  "num_questions": 7,
  "shuffle_questions": true,
  "shuffle_options": true,
  "show_immediate_feedback": true,
  "time_limit_minutes": 30,
  "quiz_items": [
    { "question_id": 234, "ordinal": 1, "marks": 1 },
    { "question_id": 235, "ordinal": 2, "marks": 1 }
  ]
}
```

### 3.2 Quiz Created Response
```json
{
  "success": true,
  "data": {
    "id": "Q001",
    "name": "Chapter 3 Practice Quiz",
    "quiz_type": "PRACTICE",
    "total_questions": 7,
    "total_marks": 7,
    "created_at": "2024-12-01T10:00:00Z"
  }
}
```

### 3.3 Submit Quiz Attempt
```json
POST /api/v1/quizzes/{quizId}/attempts/{attemptId}/submit
{
  "answers": [
    { "question_id": 234, "answer_text": "Process of photosynthesis..." },
    { "question_id": 235, "selected_option_id": "opt_100" },
    { "question_id": 236, "selected_option_id": "opt_203" }
  ],
  "time_taken_seconds": 1125
}
```

### 3.4 Quiz Results Response
```json
{
  "success": true,
  "data": {
    "attempt_id": "ATT-12345",
    "quiz_id": "Q001",
    "student_id": "STU-456",
    "score": 5,
    "total_marks": 7,
    "percentage": 71,
    "time_taken": "18:45",
    "performance_level": "Good",
    "results": [
      {
        "question_id": 234,
        "is_correct": true,
        "marks_awarded": 1,
        "feedback": "Great explanation!"
      }
    ]
  }
}
```

---

## 4. USER WORKFLOWS

### 4.1 Create Practice Quiz Workflow
**Goal:** Build a low-stakes practice quiz with immediate feedback

1. Click **[+ Create New Quiz]**
2. **Step 1:** Name: "Ch-3 Practice Quiz", Type: PRACTICE
3. **Step 2:** Add 7 questions individually OR use Question Pool
4. **Step 3:** Set options:
   - ✓ Shuffle questions
   - ✓ Shuffle options
   - ✓ Immediate feedback
   - Time limit: 30 minutes
5. **Step 4:** Preview quiz structure
6. Click **[Save & Publish]**
7. Quiz available to students immediately

---

### 4.2 Take Quiz as Student Workflow
**Goal:** Complete a quiz and get immediate feedback

1. See **[Quizzes]** section in learning portal
2. Click on "Ch-3 Practice Quiz"
3. Click **[Start Quiz]**
4. System starts 30-minute timer
5. Answer questions one by one:
   - Click option or type answer
   - Click **[Next]** to continue
   - Use review panel to jump between questions
6. Mark difficult questions with **[Flag for Review]**
7. Finish before time expires → Click **[Submit Quiz]**
8. System auto-evaluates MCQ/options questions
9. Shows results immediately:
   - Score: 5/7 (71%)
   - Feedback per question
   - Correct vs incorrect comparison
10. Can retake quiz (teacher setting)

---

### 4.3 Teacher View Quiz Results
**Goal:** See class performance on quiz

1. Click quiz: "Ch-3 Practice Quiz"
2. View **[View Results]** tab
3. Shows:
   - Class average: 74%
   - Highest score: 95% (2 students)
   - Lowest score: 42% (1 student)
   - Most missed question: Q3 (35% got wrong)
4. Click on student → See their detailed answers
5. Export results to spreadsheet

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Color Coding
- Correct: Green (#4CAF50)
- Incorrect: Red (#F44336)
- Unanswered: Light gray (#E0E0E0)
- Flagged: Orange (#FF9800)
- Current: Blue (#2196F3)

### 5.2 Quiz Taking Interface
- Large question text (18px)
- Clear option labels (A, B, C, D)
- Progress bar prominent
- Time display countdown
- Submit button disabled until time or all answered

---

## 6. TESTING CHECKLIST

### 6.1 Functional Testing
- [ ] Create quiz with individual questions
- [ ] Create quiz with question pool
- [ ] Shuffle questions works (different order per student)
- [ ] Shuffle options works (A/B/C/D randomized)
- [ ] Time limit enforced (auto-submit at 0:00)
- [ ] Immediate feedback displays on each answer
- [ ] Student can flag and unflag questions
- [ ] Navigation between questions smooth
- [ ] Submit saves all answers
- [ ] Results calculated correctly
- [ ] Can review answers after submission
- [ ] Retake quiz creates new attempt
- [ ] Cannot edit quiz after attempts started

### 6.2 UI/UX Testing
- [ ] Timer updates in real-time
- [ ] Progress bar updates as answer
- [ ] Review panel shows current status
- [ ] Question text readable in all browsers
- [ ] Options clearly clickable/selectable
- [ ] Results page loads quickly
- [ ] Feedback scrolls if too long

### 6.3 Integration Testing
- [ ] Quiz attempts linked to student record
- [ ] Scores affect class analytics
- [ ] Attempted quiz shows in student dashboard
- [ ] Teacher can see all student attempts
- [ ] Export results with student names

### 6.4 Performance Testing
- [ ] Load quiz with 100 questions
- [ ] Submit quiz with 50 answers <3 sec
- [ ] Calculate results for 100+ students <5 sec
- [ ] Time countdown accurate within 1 second

### 6.5 Accessibility Testing
- [ ] Keyboard navigation between questions
- [ ] Screen reader announces options
- [ ] Question text has sufficient contrast
- [ ] Timer announces time warnings
- [ ] Feedback readable in screen reader
- [ ] Color not sole indicator (icon + text)

---

## 7. FUTURE ENHANCEMENTS

- **Video-Enhanced Quizzes:** Embed instructional videos with questions
- **Adaptive Difficulty:** Adjust question difficulty based on answers
- **AI Feedback:** Generate custom feedback based on student's specific error
- **Peer Comparison:** Show how student performed vs. classmates
- **Performance Tracking:** Show progress across multiple attempts
- **Scheduled Quizzes:** Set quiz availability by date/time
- **Randomized Pools:** Auto-select 10 random from 50-question pool
- **Question Analytics:** Highlight commonly missed questions
- **Mobile Optimized:** Responsive quiz-taking experience
- **Voice-Based Answers:** Audio recording for open-ended questions

