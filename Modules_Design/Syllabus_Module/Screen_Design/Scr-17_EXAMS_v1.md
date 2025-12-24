# Screen Design Specification: Exams
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Exam Management Module**, enabling educators to schedule and manage unit exams, midterms, final exams, board exams, and mock tests with date/time scheduling, negative marking, answer visibility rules, and result analysis.

### 1.2 User Roles & Permissions
| Role         | Create | View | Update | Delete | Print | Export | Import |
|--------------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| PG Support   |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| School Admin |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Principal    |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Teacher      |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Student      |   ✗    |   ✓  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |
| Parents      |   ✗    |   ✓  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |

### 1.3 Data Context

**Database Tables:**
- sch_exams
  ├── id (BIGINT PRIMARY KEY)
  ├── name (VARCHAR 255) - "Final Exam - Biology"
  ├── exam_type (ENUM: UNIT, MIDTERM, FINAL, BOARD, MOCK)
  ├── subject_id, class_id (FK)
  ├── total_marks (INT) - 100 marks
  ├── exam_date (DATE)
  ├── start_time (TIME)
  ├── end_time (TIME)
  ├── duration_minutes (INT)
  ├── negative_marking_percent (DECIMAL) - e.g., 0.25 per wrong
  ├── passing_marks (INT)
  ├── answer_visibility_date (DATE) - When answers are revealed
  ├── created_by (FK to sys_users)
  └── created_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Exams List View - Calendar & Table
**Route:** `/curriculum/exams`

#### 2.1.1 Layout (Calendar + List)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ EXAMS SCHEDULE                               [+ Schedule New Exam] [Import]  │
├────────────────────────────────────────────────────────────────────────────┤
│
│ View: [Calendar] [List] [Timeline]
│ Filter: [Type: All ▼] [Class: All ▼] [Subject: All ▼]
│
│ CALENDAR VIEW:
│ ─────────────────────────────────────────────────────────────────────────
│ December 2024
│
│       Sun    Mon    Tue    Wed    Thu    Fri    Sat
│                                              1      2
│        3      4      5      6      7      8      9
│       10     11     12     13     14     15     16
│       17     18     19    [20]    21     22     23
│       24     25     26     27     28     29     30
│       31
│
│ Exams Scheduled in This View:
│ 
│ 12/15 (Sunday): Biology Unit Exam, Physics Unit Exam (2)
│ 12/17 (Tuesday): Midterm - Biology Starts
│ 12/20 (Friday): Chemistry Unit Exam
│ 12/22-25 (Sun-Wed): Final Exams - All Subjects
│
│ UPCOMING EXAMS (Sorted by Date):
│ ─────────────────────────────────────────────────────────────────────────
│ 
│ [15 Dec]  Biology Unit Exam
│           Class IX | 10:00 AM - 11:30 AM (90 min)
│           Total Marks: 50 | Negative: 0.25 per wrong
│           [View] [Edit] [View Results]
│
│ [15 Dec]  Physics Unit Exam
│           Class IX | 2:00 PM - 3:30 PM (90 min)
│           Total Marks: 50 | Negative: 0.25 per wrong
│           [View] [Edit] [View Results]
│
│ [17 Dec]  Midterm - Biology STARTS
│           Class IX | 9:00 AM - 12:00 PM (180 min)
│           Total Marks: 100 | Passing: 40
│           [View] [Edit] [View Results]
│
│ [20 Dec]  Chemistry Unit Exam
│           Class IX | 10:00 AM - 11:30 AM (90 min)
│           Total Marks: 50 | Negative: 0.25 per wrong
│           [View] [Edit] [View Results]
│
│ [22 Dec]  Final - Biology STARTS
│           Class IX | 9:00 AM - 12:00 PM (180 min)
│           Total Marks: 100 | Passing: 40
│           [View] [Edit] [View Results]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.2 Create/Schedule Exam
**Route:** `/curriculum/exams/{examId}/edit` or `/curriculum/exams/new`

#### 2.2.1 Layout (Multi-Step Form)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ SCHEDULE EXAM                                      [Save] [Schedule] [Canc] │
├────────────────────────────────────────────────────────────────────────────┤
│
│ STEP 1: BASIC INFORMATION
│ ═════════════════════════════════════════════════════════════════════════
│
│ Exam Name *              [Final Exam - Biology                ]
│ Exam Type *              [FINAL ▼]  (Options: UNIT, MIDTERM, FINAL, BOARD, MOCK)
│
│ Subject *                [Biology                   ▼]
│ Class *                  [IX - Ninth Grade          ▼]
│
│ Total Marks *            [100]
│ Passing Marks *          [40]  (40% is default)
│
│ ─────────────────────────────────────────────────────────────────────────
│ STEP 2: SCHEDULE DETAILS
│ ═════════════════════════════════════════════════════════════════════════
│
│ Exam Date *              [25-Dec-2024]
│ Start Time *             [09:00 AM]
│ End Time *               [12:00 PM]
│ Duration *               [180 minutes] (Auto-calculated)
│
│ Exam Center Location     [School Lab A]  [School Lab B]  [Online]
│                          (Optional - for board exams)
│
│ Exam Observers           [Add observers for invigilation monitoring]
│ (Optional)
│
│ ─────────────────────────────────────────────────────────────────────────
│ STEP 3: MARKING RULES
│ ═════════════════════════════════════════════════════════════════════════
│
│ Negative Marking:
│ ☑ Enable negative marking
│   Negative Mark Per Wrong: [0.25]  marks
│
│ Partial Credit:
│ ☑ Award partial marks for long answer questions
│
│ Time Tracking:
│ ☑ Show remaining time during exam (countdown timer)
│ ☑ Auto-submit if time expires
│
│ ─────────────────────────────────────────────────────────────────────────
│ STEP 4: ANSWER VISIBILITY
│ ═════════════════════════════════════════════════════════════════════════
│
│ When should answers be revealed?
│
│ ○ Immediately after exam ends [Select date: 25-Dec-2024]
│ ○ On a specific date: [25-Dec-2024 ▼]
│ ○ After teacher review (manual)
│ ○ Hide answers indefinitely
│
│ Show Score to Students:
│ ○ Immediately after completion
│ ○ After teacher reviews answer
│ ○ On specific date: [26-Dec-2024]
│ ○ Never (scores only for teacher)
│
│
│ STEP 5: PREVIEW & PUBLISH
│ ═════════════════════════════════════════════════════════════════════════
│
│ Exam Summary:
│ • Name: Final Exam - Biology
│ • Type: FINAL
│ • Class: IX
│ • Date & Time: 25-Dec-2024, 9:00 AM - 12:00 PM (180 min)
│ • Total Marks: 100, Passing: 40
│ • Negative Marking: 0.25 per wrong
│ • Answer Visibility: 25-Dec-2024
│
│ [Edit] [Preview Exam] [Schedule Exam] [Save as Draft] [Cancel]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Exam Detail View
**Route:** `/curriculum/exams/{examId}`

#### 2.3.1 Layout (With Tabs)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ EXAM: Final Exam - Biology (Class IX)           [Edit] [View Results]      │
├────────────────────────────────────────────────────────────────────────────┤
│ [DETAILS] [QUESTION_BANK] [INSTRUCTIONS] [RESULTS] [ANALYTICS]             │
├────────────────────────────────────────────────────────────────────────────┤
│
│ DETAILS TAB
│ ═════════════════════════════════════════════════════════════════════════
│
│ Exam ID: E001
│ Name: Final Exam - Biology
│ Type: FINAL
│ Subject: Biology
│ Class: IX
│ Date: 25-Dec-2024
│ Time: 9:00 AM - 12:00 PM (180 minutes)
│ Total Marks: 100
│ Passing Marks: 40 (40%)
│ Status: Scheduled
│
│ Negative Marking: 0.25 per wrong answer
│ Partial Credit: Enabled
│ Answer Visibility Date: 25-Dec-2024
│
│ ─────────────────────────────────────────────────────────────────────────
│ QUESTION BANK TAB:
│
│ Total Questions in Exam: 45
│ • Part A: MCQ (20 questions, 20 marks)
│ • Part B: Short Answer (15 questions, 30 marks)
│ • Part C: Long Answer (10 questions, 50 marks)
│
│ Bloom Level Distribution:
│ [Remember: 10%] [Understand: 25%] [Apply: 35%] [Analyze: 20%] [Evaluate: 10%]
│
│ Difficulty Distribution:
│ [Easy: 25%] [Medium: 50%] [Difficult: 25%]
│
│ ─────────────────────────────────────────────────────────────────────────
│ RESULTS TAB:
│
│ Exam Status: Scheduled (Not yet conducted)
│ Expected: 60 students (Class IX-A, IX-B)
│
│ Completed: 0 | In Progress: 0 | Not Started: 60
│
│ [Refresh Status] [View Submissions] [Download Answer Scripts]
│
│ ─────────────────────────────────────────────────────────────────────────
│ ANALYTICS TAB (Post-exam):
│
│ Class Performance: (Will show after exam)
│ • Average Score: 65/100
│ • Pass Rate: 80%
│ • Topper: 95%, Lowest: 35%
│
│ Question Analysis:
│ • Most Missed: Q12 (60% wrong), Q25 (58% wrong)
│ • Best Answered: Q3 (95% correct), Q8 (92% correct)
│
│ [Export Analytics] [Print Report]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Schedule Exam
```json
POST /api/v1/exams
{
  "name": "Final Exam - Biology",
  "exam_type": "FINAL",
  "subject_id": 5,
  "class_id": 9,
  "total_marks": 100,
  "passing_marks": 40,
  "exam_date": "2024-12-25",
  "start_time": "09:00",
  "end_time": "12:00",
  "duration_minutes": 180,
  "negative_marking_percent": 0.25,
  "answer_visibility_date": "2024-12-25",
  "exam_items": [
    { "question_id": 234, "marks": 2, "negative_mark": 0.5 },
    { "question_id": 235, "marks": 2, "negative_mark": 0.5 }
  ]
}
```

### 3.2 Exam Scheduled Response
```json
{
  "success": true,
  "data": {
    "id": "E001",
    "name": "Final Exam - Biology",
    "exam_type": "FINAL",
    "exam_date": "2024-12-25",
    "start_time": "09:00",
    "end_time": "12:00",
    "total_marks": 100,
    "status": "scheduled",
    "created_at": "2024-12-01T10:00:00Z"
  }
}
```

### 3.3 Submit Exam
```json
POST /api/v1/exams/{examId}/attempts/{attemptId}/submit
{
  "answers": [
    { "exam_item_id": 1, "answer_text": "..." },
    { "exam_item_id": 2, "selected_option_id": "opt_100" }
  ],
  "time_taken_seconds": 10800,
  "submitted_at": "2024-12-25T11:50:00Z"
}
```

### 3.4 Get Exam Results
```
GET /api/v1/exams/{examId}/results
Response: Array of student exam results with negative marking applied
```

---

## 4. USER WORKFLOWS

### 4.1 Schedule Board Exam Workflow
**Goal:** Schedule a formal board exam with specific rules

1. Click **[+ Schedule New Exam]**
2. **Step 1:** Name: "Board Exam - Biology", Type: BOARD
3. **Step 2:** Schedule:
   - Date: 15-March-2025
   - Time: 9:00 AM - 12:00 PM (180 min)
4. **Step 3:** Set marking rules:
   - Enable negative marking: 0.25 per wrong
   - Partial credit: Enabled
5. **Step 4:** Answer visibility:
   - Reveal answers on exam date
   - Show scores after teacher review
6. **Step 5:** Add 45 questions (MCQ + Long answer)
7. Publish exam
8. Students see exam in schedule

---

### 4.2 Take Exam as Student Workflow
**Goal:** Complete exam with time management

1. On exam date, student sees: "Final Exam - Biology"
2. Click **[Start Exam]**
3. System shows:
   - Question 1 of 45
   - Time remaining: 179:45 (countdown)
   - Parts: Part A (20 MCQ), Part B (15 SA), Part C (10 LA)
4. Answer questions strategically
5. System enforces time limit
6. At 179:40, timer shows in red
7. At 180:00, system auto-submits
8. Student sees: "Exam submitted successfully"
9. Answers locked (cannot edit)

---

### 4.3 View Exam Results
**Goal:** See score and answer feedback

1. After answer visibility date (25-Dec)
2. Student clicks exam: "Final Exam - Biology"
3. Views results:
   - Score: 65/100 (65%)
   - Passing: Yes (≥40 marks)
   - Negative marking applied: -2.5 marks
4. See questions:
   - Q1-20: MCQ answers vs correct
   - Q21-35: SA answers vs model answer
   - Q36-45: LA answers with teacher feedback
5. Download result slip

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Color Coding
- Unit Exam: Blue (#2196F3)
- Midterm: Green (#4CAF50)
- Final: Red (#F44336)
- Board: Orange (#FF9800)
- Mock: Purple (#9C27B0)
- Scheduled: Light gray
- Completed: Dark gray

### 5.2 Calendar View
- Exam dates highlighted
- Multiple exams on same day stacked
- Time shown clearly (9:00 AM - 12:00 PM)
- Clickable date cells for details

### 5.3 Exam Timer
- Large countdown display (font 32px)
- Color change at warnings (≤15 min: orange, ≤5 min: red)
- Blinks at final minute

---

## 6. TESTING CHECKLIST

### 6.1 Functional Testing
- [ ] Schedule exam with future date
- [ ] Cannot schedule exam in past
- [ ] Time validation (end > start)
- [ ] Duration calculated correctly
- [ ] Negative marking calculated (0.25 × wrong)
- [ ] Auto-submit at time expiry
- [ ] Timer accuracy (within 1 second)
- [ ] Partial credit calculated
- [ ] Answer visibility rules enforced
- [ ] Cannot re-open after submission
- [ ] Export exam schedule to PDF
- [ ] Download answer scripts

### 6.2 UI/UX Testing
- [ ] Exam calendar displays correctly
- [ ] Exams at same time prevented
- [ ] Exam list sortable by date/type
- [ ] Form validation prevents incomplete data
- [ ] Timer updates smoothly
- [ ] Results displayed clearly

### 6.3 Integration Testing
- [ ] Exam linked to class/subject
- [ ] Student sees assigned exams
- [ ] Results appear in gradebook
- [ ] Competency mapping works

### 6.4 Performance Testing
- [ ] Load exam schedule with 200+ exams
- [ ] Calculate results for 300+ students <5 sec
- [ ] Export 100 answer scripts <10 sec

### 6.5 Accessibility Testing
- [ ] Exam date picker keyboard accessible
- [ ] Time picker usable
- [ ] Timer announces time updates
- [ ] Exam instructions screen reader compatible
- [ ] Color not sole indicator of exam type

---

## 7. FUTURE ENHANCEMENTS

- **Exam Hall Allotment:** Auto-assign students to exam centers/halls
- **Invigilation Management:** Track invigilators, seat arrangements
- **QR Code Scanner:** Rapid student entry using QR codes
- **Answer Script Tracking:** Barcode scanning of answer booklets
- **AI Answer Evaluation:** Auto-grade long answer questions
- **Exam Statistics:** Psychometric analysis (Cronbach's alpha, discrimination index)
- **Mobile Exam App:** Take exams on tablets with offline support
- **Secure Exam Mode:** Lock computer, disable copy/paste
- **Exam Analytics Dashboard:** Real-time monitoring of exam progress
- **Certificate Generation:** Auto-generate result certificates

