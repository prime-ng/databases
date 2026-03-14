# Screen Design Specification: Question Options Management
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Question Options Management Module**, enabling creation and management of answer choices for multiple-choice, matching, and fill-in-the-blank questions. This module handles option feedback, distractor analysis, and option-level performance metrics.

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

**Database Table:** sch_question_options
├── id (BIGINT PRIMARY KEY)
├── question_id (FK to sch_questions) - Parent question
├── ordinal (SMALLINT) - Display order (1, 2, 3, 4...)
├── option_text (TEXT) - Option content (with rich text support)
├── is_correct (BOOLEAN) - Marks correct answer
├── feedback (TEXT) - Feedback for this specific option
├── image_url (VARCHAR) - Option has image (e.g., for diagram MCQ)
└── Indexed: question_id, is_correct for fast filtering

**Related Tables:**
- sch_questions → Parent question
- sch_attempt_answers → Student responses to options
- sch_question_analytics → Option performance metrics

---

## 2. SCREEN LAYOUTS

### 2.1 Question Options Management Screen (In Detail View)
**Route:** `/curriculum/questions/{questionId}` → Tab: "Options"

#### 2.1.1 Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ QUESTION DETAIL > Q001: What is photosynthesis?     [Edit] [Copy] [Delete] │
├────────────────────────────────────────────────────────────────────────────┤
│ [Stem] [OPTIONS] [Media] [Analytics] [Versions] [Assessment Usage] [Log]   │
├────────────────────────────────────────────────────────────────────────────┤
│
│ OPTIONS FOR MCQ_SINGLE (Single Select)
│
│ ┌─────────────────────────────────────────────────────────────────────────┐
│ │ OPTION 1 [☑ CORRECT]       Editable    ✔ 1,652/1,847 students (89.4%)  │
│ ├─────────────────────────────────────────────────────────────────────────┤
│ │ Text:  The process by which plants make their own food using sunlight,  │
│ │        water, and carbon dioxide.                                       │
│ │                                                                         │
│ │ Feedback: ✓ Correct! This is the complete definition of photosynthesis.│
│ │                                                                         │
│ │ Image: (none)  [+ Attach Image]                                        │
│ │                                                                         │
│ │ Distractor Type: N/A (Correct Answer)                                  │
│ │ Student Selection Rate: 89.4%                                          │
│ │                                                                         │
│ │ [Edit] [Delete] [↑ Move Up] [↓ Move Down]                              │
│ └─────────────────────────────────────────────────────────────────────────┘
│
│ ┌─────────────────────────────────────────────────────────────────────────┐
│ │ OPTION 2 [☐ INCORRECT]     Plausible Distractor                        │
│ ├─────────────────────────────────────────────────────────────────────────┤
│ │ Text:  The process by which plants release oxygen during respiration.   │
│ │                                                                         │
│ │ Feedback: ✗ Incorrect. This describes respiration, not photosynthesis. │
│ │           Photosynthesis is about making food, while respiration is    │
│ │           about breaking down that food for energy.                    │
│ │                                                                         │
│ │ Image: (none)  [+ Attach Image]                                        │
│ │                                                                         │
│ │ Distractor Type: [Plausible ▼]  (confuses related process)             │
│ │ Student Selection Rate: 5.3% (98 students)                             │
│ │ Analysis: Good distractor - plausible but incorrect                    │
│ │                                                                         │
│ │ [Edit] [Delete] [↑ Move Up] [↓ Move Down]                              │
│ └─────────────────────────────────────────────────────────────────────────┘
│
│ ┌─────────────────────────────────────────────────────────────────────────┐
│ │ OPTION 3 [☐ INCORRECT]     Impossible Distractor                       │
│ ├─────────────────────────────────────────────────────────────────────────┤
│ │ Text:  The process by which plants absorb water from the soil.          │
│ │                                                                         │
│ │ Feedback: ✗ Incorrect. This describes water absorption, not           │
│ │           photosynthesis. While water IS used in photosynthesis, the  │
│ │           absorption of water itself is not photosynthesis.           │
│ │                                                                         │
│ │ Image: (none)  [+ Attach Image]                                        │
│ │                                                                         │
│ │ Distractor Type: [Impossible ▼]  (factually unrelated)                 │
│ │ Student Selection Rate: 3.6% (67 students)                             │
│ │ Analysis: Good distractor - clearly incorrect                          │
│ │                                                                         │
│ │ [Edit] [Delete] [↑ Move Up] [↓ Move Down]                              │
│ └─────────────────────────────────────────────────────────────────────────┘
│
│ ┌─────────────────────────────────────────────────────────────────────────┐
│ │ OPTION 4 [☐ INCORRECT]     Plausible Distractor                        │
│ ├─────────────────────────────────────────────────────────────────────────┤
│ │ Text:  The process by which animals break down glucose for energy.      │
│ │                                                                         │
│ │ Feedback: ✗ Incorrect. This describes cellular respiration in animals. │
│ │           Only plants perform photosynthesis, not animals.             │
│ │                                                                         │
│ │ Image: (none)  [+ Attach Image]                                        │
│ │                                                                         │
│ │ Distractor Type: [Plausible ▼]  (confuses similar process)             │
│ │ Student Selection Rate: 1.6% (30 students)                             │
│ │ Analysis: Excellent distractor - catches common misconceptions         │
│ │                                                                         │
│ │ [Edit] [Delete] [↑ Move Up] [↓ Move Down]                              │
│ └─────────────────────────────────────────────────────────────────────────┘
│
│ [+ Add Option] [Randomize Order] [View All Student Responses] [Export]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.2 Edit Option Modal
**Route:** In-place or modal overlay

#### 2.2.1 Layout
```
┌──────────────────────────────────────────────────────────┐
│ EDIT OPTION (Question: What is photosynthesis?)    [✕]  │
├──────────────────────────────────────────────────────────┤
│                                                          │
│ OPTION TEXT *          [_________________]               │
│                        [                               ]│
│ (Rich text editor)                                       │
│                                                          │
│ MARK AS CORRECT        [☑] This is the correct answer   │
│                                                          │
│ FEEDBACK TEXT          [_________________]               │
│                        [                               ]│
│ (Explain why correct/incorrect)                         │
│                                                          │
│ IMAGE                  [+ Upload Image]                  │
│ (For diagram-based options)  [+ Attach from Library]    │
│                                                          │
│ DISTRACTOR TYPE        [Plausible ▼]                    │
│ (If not correct)       Options: Plausible, Impossible   │
│                                                          │
│ DISPLAY ORDER          [2]                              │
│                                                          │
├──────────────────────────────────────────────────────────┤
│               [Cancel]  [Save]  [Save & Next]           │
└──────────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Option Request
```json
POST /api/v1/questions/{questionId}/options
{
  "ordinal": 1,
  "option_text": "The process by which plants make their own food...",
  "is_correct": true,
  "feedback": "Correct! This is the complete definition.",
  "image_url": null,
  "distractor_type": "correct_answer"
}
```

### 3.2 Update Option Request
```json
PATCH /api/v1/questions/{questionId}/options/{optionId}
{
  "option_text": "Updated option text...",
  "feedback": "Updated feedback...",
  "distractor_type": "plausible"
}
```

### 3.3 Reorder Options Request
```json
PATCH /api/v1/questions/{questionId}/options/reorder
{
  "order": [3, 1, 4, 2]  // New ordinal sequence
}
```

### 3.4 List Options Response
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "question_id": 2847,
      "ordinal": 1,
      "option_text": "The process by which plants...",
      "is_correct": true,
      "feedback": "Correct!",
      "student_selection_count": 1652,
      "student_selection_percentage": 89.4
    }
  ]
}
```

---

## 4. USER WORKFLOWS

### 4.1 Create Question Options Workflow
**Goal:** Add multiple choice options when creating a question

1. In Create Question form, Step 3: Options
2. Auto-generates 4 blank option fields
3. Enter Option 1 text
4. Check "Mark as Correct Answer"
5. Add feedback: "Correct! Because..."
6. Enter Options 2-4 (incorrect options)
7. For each wrong option, add feedback explaining the misconception
8. Set Distractor Type (Plausible or Impossible)
9. Preview question rendering
10. Click **[Save]** → Question created with options

---

### 4.2 Edit Option Feedback Workflow
**Goal:** Improve feedback for a specific option

1. Open question detail
2. Click **[OPTIONS]** tab
3. Click **[Edit]** on Option 2 (incorrect option)
4. Modify feedback text
5. Make more educational, less punitive
6. Click **[Save]**
7. Feedback updated, next student sees new version

---

### 4.3 Analyze Distractor Effectiveness Workflow
**Goal:** Evaluate if wrong options are good distractors

1. Open question detail
2. Click **[OPTIONS]** tab
3. View each option's student selection percentage
4. Identify if any wrong option is too popular (confusing)
5. If Option 2 shows 15% selection, it's a good distractor
6. If Option 3 shows <1% selection, it's too obvious
7. Click **[Edit]** on weak distractors
8. Revise option text to be more plausible
9. Save and retest

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Color Coding
- Correct option: Green (#4CAF50) with checkmark
- Incorrect options: Light gray (#EFEFEF) with × mark
- Distractor label: Orange (#FF9800) badge
- Student percentage: Dark blue text, right-aligned

### 5.2 Typography
- Option text: Regular, 14px
- Distractor type: Bold, 12px, uppercase
- Selection percentage: Bold, 12px
- Feedback text: Italic, 13px, lighter gray

### 5.3 Layout
- Card-based layout for each option
- Visual hierarchy: Text > Feedback > Metrics
- Performance metrics right-aligned
- Action buttons bottom-right

---

## 6. TESTING CHECKLIST

### 6.1 Functional Testing
- [ ] Create option and mark as correct
- [ ] Create multiple incorrect options
- [ ] Set distractor type (Plausible/Impossible)
- [ ] Add feedback text for each option
- [ ] Reorder options via drag-drop or up/down arrows
- [ ] Edit option text
- [ ] Delete option (verify warning if used)
- [ ] View student selection percentage
- [ ] Export options to CSV
- [ ] Attach image to option
- [ ] Rich text formatting in option text

### 6.2 UI/UX Testing
- [ ] Options render in correct order
- [ ] Selection percentage displays clearly
- [ ] Correct option visually distinct
- [ ] Distractor type label shows
- [ ] Edit modal appears on button click
- [ ] Drag-drop reordering smooth
- [ ] Mobile layout responsive

### 6.3 Integration Testing
- [ ] Create question → Options available
- [ ] Student attempts → Selection recorded
- [ ] Analytics calculate correctly
- [ ] Delete option → Students can't select it
- [ ] Reorder → New order appears in assessment

### 6.4 Accessibility Testing
- [ ] Options keyboard navigable
- [ ] Color contrast ≥ 4.5:1
- [ ] Correct answer indicated in screen reader
- [ ] Selection percentages announced
- [ ] Form labels associated

---

## 10. FUTURE ENHANCEMENTS

- **Option Image Generation:** Auto-create diagrams from text
- **AI Distractor Creation:** Auto-generate plausible wrong answers
- **Option Performance Dashboard:** Visual analytics per option
- **A/B Testing Options:** Test different option formulations
- **Emotion-Based Feedback:** Adaptive feedback based on student mood
- **Audio Options:** Record audio for language questions
- **Video Options:** Include video in option content
- **Branching Options:** Different follow-up questions per option

