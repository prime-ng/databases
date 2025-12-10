# Screen Design Specification: Assessments
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Assessment Management Module**, enabling educators to create and manage formative assessments, summative evaluations, term-end assessments, and diagnostic tests with flexible question organization, grading rules, and result tracking.

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
- sch_assessments
  ├── id (BIGINT PRIMARY KEY)
  ├── name (VARCHAR 255) - "Unit 3 Assessment"
  ├── assessment_type (ENUM: FORMATIVE, SUMMATIVE, TERM, DIAGNOSTIC)
  ├── subject_id, class_id, lesson_id (FK)
  ├── total_marks (INT) - e.g., 100 marks
  ├── description (TEXT)
  ├── passing_marks (INT) - e.g., 40 marks
  ├── academic_session_id (FK) - Links to term/session
  ├── created_by (FK to sys_users)
  ├── created_at (TIMESTAMP)
  └── is_published (BOOLEAN)

- sch_assessment_sections
  ├── assessment_id (FK)
  ├── section_name (VARCHAR 255) - "Part A", "Part B"
  ├── marks (INT) - Marks for this section
  └── instructions (TEXT) - Specific instructions for section

---

## 2. SCREEN LAYOUTS

### 2.1 Assessments List View
**Route:** `/curriculum/assessments`

#### 2.1.1 Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ ASSESSMENTS                                  [+ Create Assessment] [Import]  │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Filter: [Type: All ▼] [Class: All ▼] [Status: All ▼] [Search...]          │
│
│ ┌──────┬─────────────────────────┬──────────┬────────┬──────────┬──────────┐
│ │ ID   │ Assessment Name         │ Type     │ Marks  │ Status   │ Created  │
│ ├──────┼─────────────────────────┼──────────┼────────┼──────────┼──────────┤
│ │ A001 │ Unit 3 - Photosynthesis │ FORMATIVE        │ 50 marks │ Published│ 2024-12 │
│ │      │ (Biology IX)            │          │        │          │          │
│ ├──────┼─────────────────────────┼──────────┼────────┼──────────┼──────────┤
│ │ A002 │ Mid-Term Assessment     │ SUMMATIVE│ 100 m  │ Published│ 2024-12 │
│ │      │ (Biology IX)            │          │        │          │          │
│ ├──────┼─────────────────────────┼──────────┼────────┼──────────┼──────────┤
│ │ A003 │ Term 1 Diagnostic       │ DIAGNOSTIC       │ 40 marks │ Draft    │ 2024-12 │
│ │      │ (Chemistry IX)          │          │        │          │          │
│ └──────┴─────────────────────────┴──────────┴────────┴──────────┴──────────┘
│
│ [View] [Edit] [Delete] [Publish] [View Results] [Assign to Class]
│
│ Showing 1-3 of 8 assessments | [Next]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.2 Create/Edit Assessment - Multi-Section
**Route:** `/curriculum/assessments/{assessmentId}/edit` or `/curriculum/assessments/new`

#### 2.2.1 Layout (Multi-Step Form)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ CREATE ASSESSMENT                                    [Save] [Preview] [Canc]│
├────────────────────────────────────────────────────────────────────────────┤
│
│ STEP 1: BASIC INFORMATION
│ ═════════════════════════════════════════════════════════════════════════
│
│ Assessment Name *        [Unit 3 - Photosynthesis Assessment]
│ Description              [Assessment covering light and dark reactions]
│
│ Assessment Type *        [FORMATIVE ▼]  
│                          Options: FORMATIVE (Ongoing), SUMMATIVE (Final),
│                          TERM (End-of-term), DIAGNOSTIC (Pre-assessment)
│
│ Subject *                [Biology                   ▼]
│ Class *                  [IX - Ninth Grade          ▼]
│ Lesson *                 [Ch-3: Photosynthesis      ▼]
│ Academic Session *       [2024-25 Session 1 (Aug-Dec) ▼]
│
│ ─────────────────────────────────────────────────────────────────────────
│ STEP 2: ASSESSMENT STRUCTURE (Multi-Section)
│ ═════════════════════════════════════════════════════════════════════════
│
│ Total Assessment Marks:  [50 marks]
│ Passing Marks:          [20 marks] (40% is default, can customize)
│
│ Add Sections:
│
│ ┌─────────────────────────────────────────────────────────────────────┐
│ │ PART A: MULTIPLE CHOICE QUESTIONS                                   │
│ │                                                                    │
│ │ Marks: [20]  Duration Hint: [30 minutes]                           │
│ │                                                                    │
│ │ Instructions: "Answer all 20 questions. Each correct answer = 1 m."│
│ │ [Edit] [Remove Section]                                            │
│ │                                                                    │
│ │ Questions in this section: 20                                     │
│ └─────────────────────────────────────────────────────────────────────┘
│
│ ┌─────────────────────────────────────────────────────────────────────┐
│ │ PART B: SHORT ANSWER QUESTIONS                                      │
│ │                                                                    │
│ │ Marks: [20]  Duration Hint: [40 minutes]                           │
│ │                                                                    │
│ │ Instructions: "Answer any 4 out of 5 questions. Each = 5 marks."  │
│ │ [Edit] [Remove Section]                                            │
│ │                                                                    │
│ │ Questions in this section: 5                                      │
│ └─────────────────────────────────────────────────────────────────────┘
│
│ ┌─────────────────────────────────────────────────────────────────────┐
│ │ PART C: LONG ANSWER QUESTIONS                                       │
│ │                                                                    │
│ │ Marks: [10]  Duration Hint: [20 minutes]                           │
│ │                                                                    │
│ │ Instructions: "Answer any 1 out of 2 questions. Each = 10 marks." │
│ │ [Edit] [Remove Section]                                            │
│ │                                                                    │
│ │ Questions in this section: 2                                      │
│ └─────────────────────────────────────────────────────────────────────┘
│
│ [+ Add Another Section]
│
│
│ STEP 3: GRADING & RULES
│ ═════════════════════════════════════════════════════════════════════════
│
│ Marking Scheme:
│ ☑ Partial Credit: Award partial marks for incomplete answers
│ ☐ Negative Marking: Deduct marks for wrong answers (-0.25 per wrong)
│ ☑ Show Passing Status: Display Pass/Fail after submission
│
│ Answer Display:
│ ☑ Show answers immediately after submission
│ ☑ Show answer explanation (if available)
│ ☐ Hide answers until teacher review
│
│ Re-attempt Options:
│ Allowed Attempts: [1 ▼]  (Options: 1, 2, 3, Unlimited)
│ Show Previous Attempt: [No ▼]
│
│
│ STEP 4: REVIEW & PUBLISH
│ ═════════════════════════════════════════════════════════════════════════
│
│ Assessment Summary:
│ • Type: FORMATIVE Assessment
│ • Total Marks: 50
│ • Passing Marks: 20 (40%)
│ • Sections: 3 (Part A: 20m, Part B: 20m, Part C: 10m)
│ • Total Questions: 27
│ • Academic Session: 2024-25 Session 1
│
│ Question Breakdown:
│ • MCQ (Part A): 20 questions (20 marks)
│ • Short Answer (Part B): 5 questions (20 marks)
│ • Long Answer (Part C): 2 questions (10 marks)
│
│ [Edit] [Preview Assessment] [Save as Draft] [Publish Assessment] [Cancel]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Assessment Detail View
**Route:** `/curriculum/assessments/{assessmentId}`

#### 2.3.1 Layout (Tabs)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ ASSESSMENT: Unit 3 - Photosynthesis Assessment         [Edit] [Publish]    │
├────────────────────────────────────────────────────────────────────────────┤
│ [DETAILS] [STRUCTURE] [RESULTS] [ASSIGNMENTS] [ANALYTICS]                  │
├────────────────────────────────────────────────────────────────────────────┤
│
│ DETAILS TAB
│ ═════════════════════════════════════════════════════════════════════════
│
│ Assessment ID: A001
│ Name: Unit 3 - Photosynthesis Assessment
│ Type: FORMATIVE
│ Subject: Biology
│ Class: IX
│ Total Marks: 50
│ Passing Marks: 20 (40%)
│ Status: Published
│ Academic Session: 2024-25 Session 1
│ Created: 2024-12-01 by Sarah Teacher
│ Last Modified: 2024-12-08
│
│ Description:
│ "Assessment covering light reactions, dark reactions, and factors affecting
│  photosynthesis. Includes multiple sections for comprehensive evaluation."
│
│ ─────────────────────────────────────────────────────────────────────────
│ STRUCTURE TAB:
│
│ Part A: MCQ (20 marks, 20 questions)
│ Part B: Short Answer (20 marks, 5 questions)
│ Part C: Long Answer (10 marks, 2 questions)
│
│ Grading Rules:
│ • Partial Credit: Enabled
│ • Negative Marking: Disabled
│ • Show Passing Status: Yes
│ • Max Attempts: 1
│
│ ─────────────────────────────────────────────────────────────────────────
│ RESULTS TAB:
│
│ Assigned To: 2 classes (IX-A, IX-B) = 75 students
│ Attempts: 64 completed, 8 in progress, 3 not started
│
│ Class Performance:
│ • IX-A: Average 72%, Pass Rate 90%
│ • IX-B: Average 68%, Pass Rate 85%
│
│ Top Students:
│ 1. Arjun (94%)  2. Priya (91%)  3. Neha (89%)
│
│ Performance Distribution:
│ A (90-100): 12 students
│ B (80-89):  25 students
│ C (70-79):  18 students
│ D (60-69):  7 students
│ E (<60):    2 students
│
│ [Export Results] [Print Report]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Assessment
```json
POST /api/v1/assessments
{
  "name": "Unit 3 - Photosynthesis Assessment",
  "assessment_type": "FORMATIVE",
  "subject_id": 5,
  "class_id": 9,
  "lesson_id": 42,
  "academic_session_id": 1,
  "total_marks": 50,
  "passing_marks": 20,
  "description": "Assessment covering photosynthesis",
  "sections": [
    {
      "section_name": "Part A: MCQ",
      "marks": 20,
      "instructions": "Answer all 20 questions",
      "question_ids": [234, 235, 236, ...]
    },
    {
      "section_name": "Part B: Short Answer",
      "marks": 20,
      "instructions": "Answer any 4 out of 5",
      "question_ids": [245, 246, 247, 248, 249]
    }
  ],
  "grading_rules": {
    "partial_credit": true,
    "negative_marking": false,
    "max_attempts": 1
  }
}
```

### 3.2 Assessment Created Response
```json
{
  "success": true,
  "data": {
    "id": "A001",
    "name": "Unit 3 - Photosynthesis Assessment",
    "assessment_type": "FORMATIVE",
    "total_marks": 50,
    "sections": 3,
    "total_questions": 27,
    "status": "draft",
    "created_at": "2024-12-01T10:00:00Z"
  }
}
```

### 3.3 Get Assessment Details
```
GET /api/v1/assessments/{assessmentId}
Response: Complete assessment with all sections and questions
```

### 3.4 Publish Assessment
```json
POST /api/v1/assessments/{assessmentId}/publish
{
  "scheduled_release": "2024-12-15T10:00:00Z"  // Optional
}
```

---

## 4. USER WORKFLOWS

### 4.1 Create Multi-Section Assessment Workflow
**Goal:** Build comprehensive assessment with question parts

1. Click **[+ Create Assessment]**
2. **Step 1:** Name: "Unit 3 Assessment", Type: FORMATIVE
3. **Step 2:** Add sections:
   - Part A: MCQ (20 marks, 20 questions)
   - Part B: Short Answer (20 marks, 5 questions)
   - Part C: Long Answer (10 marks, 2 questions)
4. For each section:
   - Set marks allocation
   - Add section instructions
   - Link questions to section
5. **Step 3:** Configure grading:
   - Enable partial credit
   - Set max attempts
6. **Step 4:** Preview and publish
7. Assessment shows as "Published"

---

### 4.2 Assign Assessment to Class
**Goal:** Make assessment available to students

1. Open assessment: "Unit 3 Assessment"
2. Click **[Assign to Class]**
3. Select class: "IX-A" (50 students)
4. Set availability:
   - **Start Date:** 2024-12-15
   - **End Date:** 2024-12-20
5. Set options:
   - Max attempts: 1
   - Show results: Immediately
6. Click **[Assign]**
7. Assessment appears in student dashboard
8. Students can start on 2024-12-15

---

### 4.3 View Assessment Results
**Goal:** Analyze student performance

1. Open assessment
2. Click **[RESULTS]** tab
3. View class average: 72%
4. See distribution:
   - A grade: 12 students
   - B grade: 25 students
5. Click student → See detailed answers
6. Export results to Excel

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Color Coding
- Formative: Blue (#2196F3)
- Summative: Green (#4CAF50)
- Term: Orange (#FF9800)
- Diagnostic: Purple (#9C27B0)
- Published: Green badge
- Draft: Gray badge

### 5.2 Layout
- Multi-section structure with clear part labels
- Progress indicators for student completion
- Results distribution shown as bar charts
- Grade letter symbols (A, B, C, D, E)

---

## 6. TESTING CHECKLIST

### 6.1 Functional Testing
- [ ] Create assessment with multiple sections
- [ ] Add questions to each section
- [ ] Total marks calculated correctly
- [ ] Passing marks validation (≤ total marks)
- [ ] Edit assessment before publishing
- [ ] Cannot edit after students attempt
- [ ] Publish assessment
- [ ] Assign assessment to class
- [ ] Set availability dates
- [ ] View all student attempts
- [ ] Export results to Excel/PDF
- [ ] Delete draft assessments
- [ ] Soft-delete published assessments

### 6.2 UI/UX Testing
- [ ] Multi-step form intuitive
- [ ] Section management smooth
- [ ] Mark allocation clear
- [ ] Results table readable
- [ ] Grade distribution visible
- [ ] Search assessments by name/type

### 6.3 Integration Testing
- [ ] Assessment linked to subject/class/lesson
- [ ] Attempts linked to assessment
- [ ] Student sees assigned assessments
- [ ] Results appear in student grades
- [ ] Competencies linked to assessment questions

### 6.4 Performance Testing
- [ ] Create assessment with 100 questions
- [ ] Load results for 200+ students <3 sec
- [ ] Export results <5 seconds
- [ ] Calculate class average quickly

### 6.5 Accessibility Testing
- [ ] Form sections keyboard navigable
- [ ] Section titles clear and semantic
- [ ] Results tables have headers
- [ ] Grade colors also have text indicators
- [ ] Charts have alt text

---

## 7. FUTURE ENHANCEMENTS

- **AI Question Generator:** Auto-generate assessment questions from textbook
- **Assessment Templates:** Pre-built assessment structures for standard topics
- **Adaptive Assessments:** Difficulty adjusts based on student responses
- **Competency Mapping:** Automatically link questions to learning outcomes
- **Auto-Grading:** AI grades long answer questions
- **Blue-Print Planning:** Ensure coverage of all topics/Bloom levels
- **Answer Key Management:** Create comprehensive answer keys with rubrics
- **Peer Assessment:** Students evaluate each other's answers
- **Timed Sections:** Different time limits for different assessment parts
- **Mobile Assessment:** Take assessments on tablets/phones

