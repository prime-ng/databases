# Screen Design Specification: Question Pools
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Question Pool Management Module**, enabling educators to create adaptive, dynamic question collections with intelligent filtering based on Bloom level, complexity, cognitive skills, and specificity type.

### 1.2 User Roles & Permissions
| Role         | Create | View | Update | Delete | Print | Export | Import |
|--------------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| PG Support   |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| School Admin |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Principal    |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Teacher      |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✗    |   ✗    |
| Student      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |
| Parents      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |

### 1.3 Data Context

**Database Tables:**
- sch_question_pools
  ├── id (BIGINT PRIMARY KEY)
  ├── name (VARCHAR 255) - "Biology Chapter 3 Quiz Pool"
  ├── description (TEXT)
  ├── subject_id, class_id, lesson_id (FK)
  ├── min_questions (INT) - Minimum 5 questions in pool
  ├── created_by (FK to sys_users)
  └── created_at (TIMESTAMP)

- sch_question_pool_filters
  ├── pool_id (FK)
  ├── bloom_id (FK) - Target Bloom level
  ├── complexity_level_id (FK) - Target difficulty
  ├── cognitive_skill_id (FK) - Target skill
  ├── ques_type_specificity_id (FK) - Target context
  └── question_type_id (FK) - Optional filter

---

## 2. SCREEN LAYOUTS

### 2.1 Question Pools List View
**Route:** `/curriculum/question-pools`

#### 2.1.1 Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ QUESTION POOLS                              [+ Create New Pool] [Import]    │
├────────────────────────────────────────────────────────────────────────────┤
│
│ Filter: [Class: All ▼] [Subject: All ▼] [Status: All ▼] [Search...]       │
│
│ ┌─────┬──────────────────────┬────────────┬────────────┬──────────┬────────┐
│ │ ID  │ Pool Name            │ Class/Subj │ Questions  │ Created  │ Action │
│ ├─────┼──────────────────────┼────────────┼────────────┼──────────┼────────┤
│ │ 1   │ Biology Chapter 3    │ IX / Bio   │ 47 Active  │ 2024-    │ [Edit] │
│ │     │ Quiz Pool            │            │ (Min: 5)   │ 12-01    │ [View] │
│ │     │                      │            │            │          │ [...]  │
│ ├─────┼──────────────────────┼────────────┼────────────┼──────────┼────────┤
│ │ 2   │ Revision - Photosyn  │ IX / Bio   │ 23 Active  │ 2024-    │ [Edit] │
│ │     │ thesis               │            │ (Min: 10)  │ 12-05    │ [View] │
│ │     │                      │            │            │          │ [...]  │
│ ├─────┼──────────────────────┼────────────┼────────────┼──────────┼────────┤
│ │ 3   │ Final Exam - Mixed   │ X / Chemistry         │ 156 Active │ 2024- │ [Edit] │
│ │     │ Questions            │            │ (Min: 20)  │ 12-08    │ [View] │
│ │     │                      │            │            │          │ [...]  │
│ └─────┴──────────────────────┴────────────┴────────────┴──────────┴────────┘
│
│ [Delete] [Download as PDF] [Export to CSV]
│
│ Showing 1-3 of 8 pools | [Next]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.2 Create/Edit Question Pool
**Route:** `/curriculum/question-pools/{poolId}/edit` or `/curriculum/question-pools/new`

#### 2.2.1 Layout (Multi-Step Form)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ CREATE QUESTION POOL                                      [Save] [Cancel]   │
├────────────────────────────────────────────────────────────────────────────┤
│
│ STEP 1: BASIC INFORMATION
│ ═════════════════════════════════════════════════════════════════════════
│
│ Pool Name *              [Biology Chapter 3 Quiz Pool        ]
│ Description              [This pool contains 50+ carefully curated questions]
│
│ Class *                  [IX - Ninth Grade          ▼]
│ Subject *                [Biology                   ▼]
│ Lesson *                 [Ch-3: Photosynthesis      ▼]
│
│ Minimum Questions *      [5]  (Questions must have unique topics within pool)
│
│ Status                   [Active] [Inactive]
│ Accessibility            [Public - All Teachers] [Private - Owner Only]
│
│
│ STEP 2: FILTER CRITERIA
│ ═════════════════════════════════════════════════════════════════════════
│
│ Bloom Level Filters
│ ─────────────────────
│ Include questions at Bloom level:
│ ☑ Remember (L1)      ☑ Understand (L2)   ☑ Apply (L3)
│ ☑ Analyze (L4)       ☑ Evaluate (L5)     ☑ Create (L6)
│
│ Complexity Level Filters
│ ────────────────────────
│ ☑ Easy (L1)          ☑ Medium (L2)       ☑ Difficult (L3)
│
│ Cognitive Skills Filters
│ ────────────────────────
│ ☑ Critical Thinking   ☑ Problem Solving
│ ☑ Analysis            ☑ Synthesis
│ ☑ Evaluation          ☑ Memory Recall
│
│ Question Type Specificity
│ ─────────────────────────
│ ☑ In-Class             ☑ Homework
│ ☑ Summative            ☑ Formative
│
│ Question Types
│ ──────────────
│ ☑ MCQ Single           ☑ MCQ Multiple Select
│ ☑ Short Answer         ☑ Long Answer
│ ☑ Fill Blanks          ☑ Matching
│
│
│ STEP 3: PREVIEW & CONFIRM
│ ═════════════════════════════════════════════════════════════════════════
│
│ Matching Questions Found: 47
│ Average Complexity: Medium
│ Bloom Distribution: [L1: 5] [L2: 12] [L3: 15] [L4: 10] [L5: 4] [L6: 1]
│
│ Complexity Distribution:
│ Easy (40%)  |████████████████
│ Medium (50%)|██████████████████████
│ Difficult (10%)|████
│
│ [Edit Filters] [Save Pool] [Cancel]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Question Pool Detail View
**Route:** `/curriculum/question-pools/{poolId}`

#### 2.3.1 Layout (With Tabs)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ QUESTION POOL: Biology Chapter 3 Quiz Pool                [Edit] [...]     │
├────────────────────────────────────────────────────────────────────────────┤
│ [DETAILS] [QUESTIONS] [FILTERS] [DISTRIBUTION] [USAGE]                     │
├────────────────────────────────────────────────────────────────────────────┤
│
│ DETAILS TAB
│ ═════════════════════════════════════════════════════════════════════════
│
│ Pool ID: POOL-0001
│ Name: Biology Chapter 3 Quiz Pool
│ Status: Active
│ Created: 2024-12-01 14:30 by Sarah Teacher
│ Last Modified: 2024-12-08 10:15
│ Accessibility: Public
│
│ Description:
│ "This pool contains carefully curated questions covering Chapter 3:
│  Photosynthesis. Questions range from basic recall to application and
│  analysis. Suitable for formative and summative assessments."
│
│ ─────────────────────────────────────────────────────────────────────────
│ FILTERS APPLIED:
│
│ Bloom Levels:     Remember, Understand, Apply, Analyze
│ Complexity:       Easy, Medium
│ Cognitive Skills: Critical Thinking, Analysis
│ Specificity:      In-Class, Homework
│ Question Types:   MCQ Single, Short Answer
│
│ ─────────────────────────────────────────────────────────────────────────
│ POOL STATISTICS:
│ 
│ Total Questions:  47
│ Min Questions:    5
│ Average Score:    78%
│ Questions Used:   12 (in 4 active assessments)
│ Last Used:        2024-12-08
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Question Pool
```json
POST /api/v1/question-pools
{
  "name": "Biology Chapter 3 Quiz Pool",
  "description": "Questions for Chapter 3 assessment",
  "subject_id": 5,
  "class_id": 9,
  "lesson_id": 42,
  "min_questions": 5,
  "filters": {
    "bloom_ids": [1, 2, 3, 4],
    "complexity_ids": [1, 2],
    "cognitive_skill_ids": [3, 5],
    "specificity_ids": [1, 2],
    "question_type_ids": [1, 2]
  }
}
```

### 3.2 Pool Created Response
```json
{
  "success": true,
  "data": {
    "id": 1,
    "pool_id": "POOL-0001",
    "name": "Biology Chapter 3 Quiz Pool",
    "matching_questions": 47,
    "created_at": "2024-12-01T14:30:00Z",
    "status": "active"
  }
}
```

### 3.3 Get Matching Questions
```
GET /api/v1/question-pools/{poolId}/questions
Response: Array of 47 question objects matching filters
```

### 3.4 Update Pool Filters
```json
PATCH /api/v1/question-pools/{poolId}
{
  "filters": {
    "complexity_ids": [1, 2, 3]  // Now include all levels
  }
}
```

---

## 4. USER WORKFLOWS

### 4.1 Create Question Pool Workflow
**Goal:** Build an adaptive question collection based on learning objectives

1. Click **[+ Create New Pool]**
2. **Step 1:** Enter pool name, select class/subject/lesson
3. **Step 2:** Select filter criteria:
   - Bloom levels (must match learning objectives)
   - Complexity (Easy/Medium/Difficult distribution)
   - Cognitive skills (Critical thinking, Problem-solving)
   - Specificity (In-class, homework, summative)
   - Question types (MCQ, Short answer, etc.)
4. **Step 3:** Preview matching questions (47 found)
5. View distribution charts:
   - Bloom level breakdown
   - Complexity distribution
   - Cognitive skill coverage
6. Click **[Save Pool]**
7. System creates pool and indexes 47 questions

---

### 4.2 Use Pool for Assessment Workflow
**Goal:** Randomly select questions from pool for assessment

1. Create assessment → Select "Use Question Pool"
2. Choose pool: "Biology Chapter 3 Quiz Pool"
3. System shows: "47 questions match your criteria"
4. Set assessment options:
   - **Draw 10 questions** from this pool
   - **Shuffle questions** for each student
   - **Randomize options** for each student
5. Click **[Create Assessment]**
6. System automatically selects 10 random questions
7. Each student sees different 10 questions (within same pool)

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Color Coding
- Bloom levels: Color gradient (L1-L6)
- Complexity: Light (Easy), Amber (Medium), Red (Difficult)
- Status: Green (Active), Gray (Inactive)

### 5.2 Distribution Visualizations
- Horizontal bar charts for Bloom levels
- Pie charts for complexity distribution
- Grid layout for filter selection

---

## 6. TESTING CHECKLIST

### 6.1 Functional Testing
- [ ] Create pool with valid filters
- [ ] System counts matching questions correctly
- [ ] Edit pool → Filter count updates
- [ ] Delete pool (soft delete - preserve history)
- [ ] Pool filters: All combinations tested (Bloom × Complexity × Skills × Type)
- [ ] Min questions validation (≥1)
- [ ] Duplicate pool names prevented
- [ ] Export pool questions to CSV
- [ ] Import pool configuration from CSV
- [ ] Pool distribution calculations accurate

### 6.2 UI/UX Testing
- [ ] Multi-step form intuitive
- [ ] Filter selections update count in real-time
- [ ] Distribution charts load quickly (47+ items)
- [ ] Preview shows correct questions
- [ ] Search pools by name/description

### 6.3 Integration Testing
- [ ] Assessment can reference pool
- [ ] Selecting from pool for assessment works
- [ ] Updated filter → Assessment sees new questions
- [ ] Analytics track pool usage

### 6.4 Performance Testing
- [ ] Create pool with 100+ matching questions
- [ ] Load distribution charts without lag
- [ ] Filter count calculation <500ms
- [ ] Export 50+ questions to PDF

### 6.5 Accessibility Testing
- [ ] Checkboxes keyboard navigable
- [ ] Charts have text descriptions
- [ ] Color not sole indicator of selection
- [ ] Min questions validation announced

---

## 7. FUTURE ENHANCEMENTS

- **Smart Pool Recommendations:** Auto-suggest pools based on recent topics
- **Pool Templates:** Pre-built pools for standard curricula
- **AI-Generated Pools:** Auto-generate based on learning objectives
- **Difficulty Balancing:** Auto-adjust complexity distribution
- **Performance-Based Pools:** Create pools from underperforming topic questions
- **Question Effectiveness Ranking:** Prioritize high-discrimination questions
- **Pool Versioning:** Track pool changes over time
- **Collaborative Pools:** Share pools between schools
- **Pool Analytics Dashboard:** Track which pools perform best
- **Scheduled Pool Updates:** Auto-refresh pools monthly

