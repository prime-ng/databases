# Screen Design Specification: Question Versioning & History
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Question Version Management Module**, enabling tracking of question modifications, version history, and rollback capabilities. This ensures audit trails and allows educators to revert questions to previous states if needed.

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

**Database Table:** sch_question_versions
├── id (BIGINT PRIMARY KEY)
├── question_id (FK to sch_questions) - Parent question
├── version (INT) - Version number (1, 2, 3...)
├── data (JSON) - Full question snapshot at this version
├── change_reason (VARCHAR 255) - Why was this version created?
├── created_by (BIGINT FK to sys_users) - Who created this version
└── created_at (TIMESTAMP) - When version created

**Related Tables:**
- sch_questions → Current version (points to latest)
- sch_question_versions → Full history

---

## 2. SCREEN LAYOUTS

### 2.1 Question Version History Tab
**Route:** `/curriculum/questions/{questionId}` → Tab: "Versions"

#### 2.1.1 Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ QUESTION DETAIL > Q001: What is photosynthesis?                            │
├────────────────────────────────────────────────────────────────────────────┤
│ [Stem] [Options] [Media] [Analytics] [VERSIONS] [Assessment Usage] [Log]   │
├────────────────────────────────────────────────────────────────────────────┤
│
│ QUESTION VERSION HISTORY
│
│ Current Version: 3 (Latest)
│
│ ┌────────────────────────────────────────────────────────────────────────┐
│ │ Version 3 [CURRENT]                                                    │
│ │ Created: 2024-12-08 14:30 by Sarah Teacher                             │
│ │ Change Reason: "Revised stem wording, improved clarity"                │
│ │                                                                        │
│ │ Changes from Version 2:                                                │
│ │ • Stem: Shortened from 45 words to 35 words                            │
│ │ • Added clarifying phrase: "using light energy"                        │
│ │ • Complexity Level: No change (Easy)                                   │
│ │ • Marks: No change (1.0)                                               │
│ │                                                                        │
│ │ [View Full Version] [Compare with Previous] [Revert to This]           │
│ └────────────────────────────────────────────────────────────────────────┘
│
│ ┌────────────────────────────────────────────────────────────────────────┐
│ │ Version 2                                                              │
│ │ Created: 2024-12-01 10:15 by Sarah Teacher                             │
│ │ Change Reason: "Added answer explanation after peer review"           │
│ │                                                                        │
│ │ Changes from Version 1:                                                │
│ │ • Answer Explanation: Added comprehensive explanation                 │
│ │ • Feedback for Options 2-4: Enhanced with teaching notes              │
│ │                                                                        │
│ │ [View Full Version] [Compare with Previous] [Revert to This]           │
│ └────────────────────────────────────────────────────────────────────────┘
│
│ ┌────────────────────────────────────────────────────────────────────────┐
│ │ Version 1 [ORIGINAL]                                                   │
│ │ Created: 2024-12-01 10:00 by Sarah Teacher                             │
│ │ Change Reason: "Initial question creation"                            │
│ │                                                                        │
│ │ Initial Version - No changes                                          │
│ │                                                                        │
│ │ [View Full Version] [Revert to This]                                   │
│ └────────────────────────────────────────────────────────────────────────┘
│
│ [Download All Versions] [Export Version Comparison] [View Timeline]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.2 Compare Versions Screen
**Route:** `/curriculum/questions/{questionId}/versions/compare?v1=1&v2=3`

#### 2.2.1 Layout (Side-by-Side Comparison)
```
┌────────────────────────────────────────────────────────────────────────────┐
│ COMPARE VERSIONS > Q001                    [Close] [Download]              │
├────────────────────────────────────────────────────────────────────────────┤
│ Version [1 ▼] vs Version [3 ▼]  [Highlight Changes] [Full Diff View]      │
├────────────────────────────────────────────────────────────────────────────┤
│
│ LEFT PANE (Version 1)          │ RIGHT PANE (Version 3)
│                                │
│ STEM:                          │ STEM:
│ What is photosynthesis? It is  │ What is photosynthesis?
│ the process where plants use   │ [CHANGED: Text shortened]
│ light energy to make food from │
│ carbon dioxide and water, with │ It is the process using light
│ oxygen released as byproduct.  │ energy to make food from carbon
│                                │ dioxide and water, releasing
│ [Word Count: 45]               │ oxygen as byproduct.
│                                │
│                                │ [Word Count: 35]
│ ────────────────────────────────────────────────────────────
│ MARKS: 1.00                    │ MARKS: 1.00
│ [NO CHANGE]                    │
│
│ ────────────────────────────────────────────────────────────
│ COMPLEXITY: Easy               │ COMPLEXITY: Easy
│ [NO CHANGE]                    │
│
│ ────────────────────────────────────────────────────────────
│ ANSWER EXPLANATION:            │ ANSWER EXPLANATION:
│ [NO ANSWER PROVIDED]           │ Photosynthesis is the process
│                                │ by which plants convert light
│ [CHANGED: Now has explanation] │ energy into chemical energy...
│                                │ [ADDED: 250 characters]
│
│ ────────────────────────────────────────────────────────────
│ OPTION 2 FEEDBACK:             │ OPTION 2 FEEDBACK:
│ Incorrect. This describes      │ Incorrect. This describes
│ respiration, not              │ respiration, not photosynthesis.
│ photosynthesis.               │ Photosynthesis is about making
│                                │ food, while respiration...
│ [CHANGED: More detailed]       │ [ADDED: Teaching notes]
│
│ [Revert to Version 1] [Accept Version 3] [Back]
│
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Version Request (Auto on Update)
```json
PATCH /api/v1/questions/{questionId}
{
  "stem": "Updated stem text...",
  "answer_explanation": "Updated explanation...",
  "change_reason": "Revised stem wording, improved clarity"
  // System auto-creates version record
}
```

### 3.2 Version Created Response
```json
{
  "success": true,
  "data": {
    "id": 2847,
    "version": 3,
    "change_reason": "Revised stem wording, improved clarity",
    "created_by": "teacher_123",
    "created_at": "2024-12-08T14:30:00Z",
    "previous_version": 2
  },
  "message": "Question updated. Version 3 created."
}
```

### 3.3 Get Version History
```
GET /api/v1/questions/{questionId}/versions
Response: Array of version objects with timestamps and change reasons
```

### 3.4 Revert to Version
```json
POST /api/v1/questions/{questionId}/versions/{versionId}/revert
{
  "reason": "Reverting due to error discovered in version 3"
}
Response: Creates new version with rolled-back content
```

### 3.5 Compare Versions
```
GET /api/v1/questions/{questionId}/versions/compare?v1=1&v2=3
Response: Diff object showing changes between versions
```

---

## 4. USER WORKFLOWS

### 4.1 View Version History Workflow
**Goal:** See all changes made to a question

1. Open Question detail
2. Click **[Versions]** tab
3. View version timeline (newest first)
4. Each version shows:
   - Version number
   - Creator name and timestamp
   - Change reason (why modified)
   - Summary of changes (what changed)
5. Hover over version → Show detailed diff

---

### 4.2 Compare Two Versions Workflow
**Goal:** Side-by-side comparison of two question versions

1. Open Version History tab
2. Click **[Compare with Previous]** on a version
3. System shows side-by-side diff
4. Green highlighting shows additions
5. Red highlighting shows deletions
6. Click **[Full Diff View]** for detailed line-by-line
7. Identify changes and evaluate if correct

---

### 4.3 Revert to Previous Version Workflow
**Goal:** Roll back question to earlier state

1. Open Version History
2. If current version has error, click on earlier version
3. Click **[Revert to This Version]** button
4. Confirmation dialog: "Revert to Version 1?"
5. Optional reason field: "Reverting due to found error"
6. Click **[Confirm]**
7. System creates new version with rolled-back content
8. Students see reverted version in next assessment
9. Audit trail records: Who reverted and why

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Color Coding
- Current version: Green badge (#4CAF50)
- Version number: Bold, dark blue
- Changes: Green (additions), Red (deletions)
- Unchanged fields: Gray (#999)

### 5.2 Typography
- Version number: Bold, 16px
- Timestamp: Regular, 12px, light gray
- Change reason: Italic, 13px
- Field labels: Bold, 12px

---

## 6. TESTING CHECKLIST

### 6.1 Functional Testing
- [ ] Create question → Version 1 auto-created
- [ ] Edit question → Version 2 created
- [ ] Change reason recorded correctly
- [ ] Version number increments (1, 2, 3...)
- [ ] View version history shows all versions
- [ ] Compare two versions shows differences
- [ ] Revert to previous version works
- [ ] Revert creates new version (not overwrite)
- [ ] Audit trail shows who reverted and why
- [ ] Can't edit previous versions (read-only)
- [ ] Export version history to PDF
- [ ] Timeline view shows chronological order

### 6.2 UI/UX Testing
- [ ] Version cards render correctly
- [ ] Changes highlighted clearly (green/red)
- [ ] Side-by-side comparison readable
- [ ] Timeline shows connections between versions
- [ ] Revert confirmation prevents accidents
- [ ] No lag when loading 10+ versions

### 6.3 Integration Testing
- [ ] Student sees current version in assessment
- [ ] Revert → Student sees reverted version
- [ ] Version data consistent with questions table
- [ ] Analytics linked to version-aware data
- [ ] Export includes version information

### 6.4 Accessibility Testing
- [ ] Timeline keyboard navigable
- [ ] Version diffs announced in screen reader
- [ ] Color contrast ≥ 4.5:1 for highlights
- [ ] Timestamp formats readable
- [ ] Change descriptions clear and concise

---

## 7. FUTURE ENHANCEMENTS

- **Automatic Version Backups:** Auto-save versions at set intervals
- **Version Branching:** Create alternative versions without affecting current
- **Version Annotations:** Add comments/notes to specific versions
- **AI-Powered Change Summaries:** Auto-generate change descriptions
- **Version Diff Visualization:** Rich visual diff tool
- **Collaborative Versioning:** Track changes by multiple editors
- **Version Performance Analytics:** Compare student performance across versions
- **Scheduled Version Releases:** Release new versions on specific dates
- **Version Archiving:** Archive old versions to save space
- **A/B Testing Versions:** Test different versions in parallel

