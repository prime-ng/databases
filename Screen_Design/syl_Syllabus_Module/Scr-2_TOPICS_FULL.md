# Screen Design Specification: Topic Management Module
## Document Version: 2.0 (Full Page Layouts)
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Topic Management Module**, enabling curriculum managers and teachers to create, organize, and manage hierarchical Topics and Sub-Topics within Lessons. Covers list views, hierarchical tree, create/edit flows, drag-and-drop operations, and integrations with Competencies and Questions.

### 1.2 User Roles & Permissions
| Role         | Create | View | Update | Delete | Reorder | Export | Import |
|--------------|--------|------|--------|--------|---------|--------|--------|
| Super Admin  |   ✓    |   ✓  |   ✓    |   ✓    |   ✓     |   ✓    |   ✓    |
| School Admin |   ✓    |   ✓  |   ✓    |   ✓    |   ✓     |   ✗    |   ✗    |
| Curriculum Manager |   ✓    |   ✓  |   ✓    |   ✓    |   ✓     |   ✓    |   ✗    |
| Teacher      |   ✗    |   ✓  |   ✗    |   ✗    |   ✗     |   ✗    |   ✗    |
| Student      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗     |   ✗    |   ✗    |

### 1.3 Data Context

Database Table: slb_topics
├── id (BIGINT PRIMARY KEY)
├── parent_id (FK to self for hierarchy)
├── lesson_id (FK to sch_lessons)
├── class_id (FK to sch_classes)
├── subject_id (FK to sch_subjects)
├── name (VARCHAR 150)
├── short_name (VARCHAR 50)
├── ordinal (TINYINT - sequence order)
├── level (TINYINT - hierarchy depth; 0=root, 1=child, etc.)
├── description (TEXT)
├── duration_minutes (INT)
├── learning_objectives (JSON - array of strings)
├── metadata (JSON)
├── is_active (TINYINT boolean)
├── created_at, updated_at, deleted_at (timestamps)
└── Unique constraints: (lesson_id, parent_id, name)

---

## 2. SCREEN LAYOUTS

### 2.1 Topic List Screen
**Route:** `/curriculum/lessons/{lessonId}/topics`

#### 2.1.1 Page Layout

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ SYLLABUS MANAGEMENT > LESSONS > TOPICS                                             │
├────────────────────────────────────────────────────────────────────────────────────┤
│   [_____________________________________________________] [Search]  [+ New Topic]   │
├────────────────────────────────────────────────────────────────────────────────────┤
│ CLASS: [Dropdown ▼]    SUBJECT: [Dropdown ▼]    LESSON: [Read-only]    [Filter]   │
│ STATUS: [All ▼]                                                                    │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Topic Name     │ Level │ Ordinal │ Duration │ Children │ Questions │ Actions │
│────────────────────────────────────────────────────────────────────────────────────│
│ ☐ │ Grammar Basics │  0    │    1    │ 90 min   │    2     │    12     │ + # -   │
│ ☐ │ Comprehension  │  0    │    2    │ 120 min  │    1     │     8     │ + # -   │
│ ☐ │ Writing Skills │  0    │    3    │ 60 min   │    0     │     4     │ + # -   │
│   │ ...            │ ...   │  ...    │   ...    │   ...    │    ...    │  ...    │
│────────────────────────────────────────────────────────────────────────────────────│
│ Showing 1-10 of 15 topics                                          [< 1 2 >]       │
│                                                                                     │
│ [View Hierarchy] [Export Topics] [⋯ Bulk Actions]                                 │
└────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components & Interactions

**Filter Bar:**
- **Class Dropdown** – Single-select (pre-filled, readonly if from lesson context)
- **Subject Dropdown** – Single-select (auto-filtered, readonly)
- **Lesson Dropdown** – Single-select (pre-filled, readonly)
- **Status Dropdown** – Options: Active, Inactive, All (default: All)

**Search:**
- Placeholder: "Search by topic name, short name..."
- Real-time filtering
- Search fields: name, short_name, description, learning_objectives

**View Toggle:**
- [List View] | [Hierarchy Tree] – Toggle between table and tree display

**Buttons:**
- **[+ New Topic]** – Opens Create Topic Modal (creates root topic under lesson)
  - Color: Primary (Blue)
- **[View Hierarchy]** – Opens full-screen tree view
- **[Export Topics]** – Downloads CSV with topic tree structure
- **[⋯ Bulk Actions]** – Options: Activate, Deactivate, Delete, Export
  - Enabled only when rows selected

**Column Actions (Inline):**
- Click row → Opens Topic Detail panel (right-side)
- Hover row → Show action buttons: [Add Sub] [Edit] [Delete]
- Checkbox → Selects row for bulk operations

**Pagination:**
- Records per page: 10, 25, 50, 100
- Total display: "Showing X-Y of Z topics"
- Navigation: Previous, Page numbers, Next

---

### 2.2 Hierarchical Topic Tree View
**Route:** `/curriculum/lessons/{lessonId}/topics/tree`

#### 2.2.1 Layout

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ TOPIC HIERARCHY TREE > Lesson 1 (9th English)        [← Back]  [List View]       │
├────────────────────────────────────────────────────────────────────────────────────┤
│ [+ New Topic]  [Expand All]  [Collapse All]  [Save Changes]  [⋯ Actions]         │
├────────────────────────────────────────────────────────────────────────────────────┤
│
│ ▼ 1. ≡ Grammar Basics (Level 0, Ordinal 1)              [+ Add Child] [✏️] [🗑️]
│      Duration: 90 minutes | Questions: 12 | Status: Active
│   ▼ 1.1. ≡ Parts of Speech (Level 1, Ordinal 1)       [+ Add Child] [✏️] [🗑️]
│          Duration: 45 min | Questions: 5
│   ▶ 1.2. ≡ Verb Tenses (Level 1, Ordinal 2)           [+ Add Child] [✏️] [🗑️]
│          Duration: 45 min | Questions: 7
│
│ ▼ 2. ≡ Comprehension (Level 0, Ordinal 2)              [+ Add Child] [✏️] [🗑️]
│      Duration: 120 minutes | Questions: 8 | Status: Active
│   ▶ 2.1. ≡ Reading Practice (Level 1, Ordinal 1)      [+ Add Child] [✏️] [🗑️]
│          Duration: 120 min | Questions: 8
│
│ ▶ 3. ≡ Writing Skills (Level 0, Ordinal 3)             [+ Add Child] [✏️] [🗑️]
│      Duration: 60 minutes | Questions: 4 | Status: Inactive
│
│ [+ New Topic]                                [Save Changes]
│
└────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.2.2 Drag-and-Drop Behavior
- **Reorder siblings:** Drag node left/right among same level → Updates ordinal
- **Change parent:** Drag node onto another node → Becomes child, level incremented
- **Visual feedback:** Shadow during drag, highlight drop zone, ordinal preview
- **Validation:** Prevent drag to descendant, show error message if invalid move

---

### 2.3 Create / Edit Topic Modal
**Route:** `POST /api/v1/topics` (create) | `PUT /api/v1/topics/{id}` (update)

#### 2.3.1 Layout

```
┌──────────────────────────────────────────────────────────┐
│ CREATE NEW TOPIC                                    [✕]  │
├──────────────────────────────────────────────────────────┤
│                                                          │
│ Class *                 [Read-only: 9th Standard]       │
│                                                          │
│ Subject *               [Read-only: English]            │
│                                                          │
│ Lesson *                [Read-only: Lesson 1]           │
│                                                          │
│ Parent Topic (optional) [Select Parent ▼]              │
│ (Shows current hierarchy)                               │
│ ┌──────────────────────────────────────────────────┐   │
│ │ • Grammar Basics (Level 0)                       │   │
│ │  ├─ Parts of Speech (Level 1)                   │   │
│ │  └─ Verb Tenses (Level 1)                       │   │
│ │ • Comprehension (Level 0)                        │   │
│ │  └─ Reading Practice (Level 1)                  │   │
│ └──────────────────────────────────────────────────┘   │
│                                                          │
│ Topic Name *            [________________]              │
│ (Max 150 chars)                                         │
│                                                          │
│ Short Name (optional)   [_______]                       │
│ (Max 50 chars, auto-suggested)                          │
│                                                          │
│ Ordinal *               [__] (Unique among siblings)    │
│ (System will suggest: Available: [1, 2, 4, 5])         │
│                                                          │
│ Level (auto-computed)   [0]  (Read-only)               │
│ (0=root, 1=child of parent, etc.)                      │
│                                                          │
│ Duration (minutes)      [___]                           │
│ (Optional, total teaching time)                         │
│                                                          │
│ Learning Objectives     [________________]              │
│ (Optional, JSON array or comma-separated)              │
│ ┌──────────────────────────────────────────────────┐   │
│ │ • Identify parts of speech                       │   │
│ │ • Use correct grammar in sentences              │   │
│ └──────────────────────────────────────────────────┘   │
│                                                          │
│ Description             [________________]              │
│ (Optional, supports markdown)                           │
│ ┌──────────────────────────────────────────────────┐   │
│ │ Introduction to grammar concepts including      │   │
│ │ nouns, verbs, adjectives and their functions    │   │
│ └──────────────────────────────────────────────────┘   │
│                                                          │
│ Is Active               [☑] Enable this topic           │
│                                                          │
├──────────────────────────────────────────────────────────┤
│          [Cancel]  [Save]  [Save & New]                 │
└──────────────────────────────────────────────────────────┘
```

#### 2.3.2 Field Specifications

| Field | Type | Validation | Placeholder | Required |
|-------|------|------------|-------------|----------|
| Class | Read-only | FK to sch_classes | - | ✓ |
| Subject | Read-only | FK to sch_subjects | - | ✓ |
| Lesson | Read-only | FK to sch_lessons | - | ✓ |
| Parent Topic | Tree Picker | Self-FK, no cycles | "Select parent (optional)" | ✗ |
| Topic Name | Text Input | Max 150 chars, unique per (lesson_id, parent_id) | "e.g., Grammar Basics" | ✓ |
| Short Name | Text Input | Max 50 chars, auto-generated | Auto-suggested | ✗ |
| Ordinal | Number Input | Positive integer, unique among siblings | "1" | ✓ |
| Level | Read-only | Computed as parent.level + 1 or 0 | - | Auto |
| Duration | Number Input | Positive integer (minutes) | "90" | ✗ |
| Learning Objectives | Rich Editor | JSON array, multi-line | "• Objective 1" | ✗ |
| Description | TextArea | Max 2000 chars, markdown-enabled | "Brief description..." | ✗ |
| Is Active | Toggle | Boolean | Checked | ✗ |

#### 2.3.3 Validation Rules

```
✓ Class, Subject, Lesson are required and read-only
✓ Topic Name is required
  - Max length: 150 characters
  - Unique within (lesson_id, parent_id)
  - Error: "Topic name already exists under same parent"
✓ Parent Topic is optional
  - If selected, cannot be self
  - Cannot be a descendant (prevent cycles)
  - Error: "Cannot select a child topic as parent"
✓ Ordinal is required
  - Must be positive integer
  - Unique among siblings (same parent)
  - Error: "Ordinal must be unique. Available: [1, 2, 4, 5]"
  - Option: "Auto-shift siblings" to consolidate ordinals
✓ Level is computed
  - Read-only; shows parent.level + 1 or 0 for root
✓ Duration is optional
  - If provided, must be positive integer
✓ Learning Objectives is optional
  - Supports both list (textarea) and JSON array format
✓ Description is optional
  - Max 2000 characters
  - Markdown syntax allowed
```

#### 2.3.4 Error Handling

```
Error Scenarios:
1. Topic Name Duplicate
   Message: "A topic with this name already exists under parent."
   Action: Highlight field, suggest appending number (Grammar Basics 2)

2. Ordinal Conflict
   Message: "Ordinal must be unique among siblings."
   Suggestion: "Available: [1, 2, 4, 5] (3 is taken)"
   Option: [Auto-shift siblings] to fill gap

3. Parent is Descendant
   Message: "Cannot create cycle: parent cannot be a child of this topic"
   Action: Clear parent field, show valid parents

4. Missing Required Fields
   Message: "[Topic Name] is required"
   Action: Highlight field, disable Save button

5. Network Error on Save
   Message: "Failed to save topic. Please try again."
   Retry: Auto-retry after 2s, manual Retry button
```

#### 2.3.5 Smart Features
- **Auto-short-name:** When Topic Name entered, short_name auto-suggested (can be edited)
  - Example: "Grammar Basics" → "Grammar"
- **Ordinal suggestion:** System shows available ordinals; can auto-shift siblings on save
- **Duplicate topic:** From detail view, offer "Duplicate" option that pre-fills form with existing data
- **Save & New:** After save, stays in modal, clears form for bulk creation

---

### 2.4 Topic Detail Panel (Right-side)
**Route:** `/curriculum/lessons/{lessonId}/topics/{id}`

#### 2.4.1 Layout (Tabbed Interface)

```
┌──────────────────────────────────────────────────────────────┐
│ TOPIC DETAIL > Grammar Basics                   [Edit] [More] │
├──────────────────────────────────────────────────────────────┤
│ [Overview] [Sub-Topics] [Questions] [Competencies] [Activity] │
├──────────────────────────────────────────────────────────────┤
│
│ TAB 1: OVERVIEW
│ ─────────────────────────────────────────────────────────────
│ Lesson:                     Lesson 1 (9th English)
│ Parent Topic:               None (Root)
│ Topic Name:                 Grammar Basics
│ Short Name:                 Grammar
│ Level:                      0
│ Ordinal:                    1 (of 3 topics)
│ Duration:                   90 minutes
│ Status:                     ✓ Active
│ Learning Objectives:
│   • Identify parts of speech
│   • Use correct grammar in sentences
│ Description:
│   Introduction to grammar concepts including nouns, verbs,
│   adjectives and their functions in English language.
│
│ Created By:                 John Curriculum Manager
│ Created Date:               2024-12-01
│ Last Modified By:           John Curriculum Manager
│ Last Modified Date:         2024-12-08
│
│ [Edit] [Duplicate] [Archive]
│
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ TAB 2: SUB-TOPICS (Hierarchical Tree)
│ ─────────────────────────────────────────────────────────────
│ ├─ Parts of Speech (Level 1, Ordinal 1)      [Edit] [Delete]
│ │   Duration: 45 min | Questions: 5 | Status: Active
│ │
│ └─ Verb Tenses (Level 1, Ordinal 2)          [Edit] [Delete]
│     Duration: 45 min | Questions: 7 | Status: Active
│
│ [+ Add Sub-Topic] [⋯ Manage Sub-Topics]
│
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ TAB 3: QUESTIONS (Related Questions)
│ ─────────────────────────────────────────────────────────────
│ Total Questions: 12 (across all sub-topics)
│
│ Filter: [Difficulty ▼] [Question Type ▼] [Bloom Level ▼]
│
│ ☐ │ Question Text    │ Type │ Difficulty │ Bloom │ Sub-Topic  │
│ ───┼──────────────────┼──────┼────────────┼───────┼────────────│
│ ☐ │ Q1: What is a... │ MCQ  │ Easy       │ Recall│ Parts 1.1  │
│ ☐ │ Q2: Identify...  │ MCQ  │ Medium     │ Understand│ Parts 1.1  │
│ ☐ │ Q3: Which verb..│ FB   │ Hard       │ Apply │ Tenses 1.2 │
│   │ ...              │ ...  │ ...        │ ...   │ ...        │
│
│ [Export Questions] [Link New Question] [Manage Questions]
│
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ TAB 4: COMPETENCIES (Linked Competencies)
│ ─────────────────────────────────────────────────────────────
│ Mapped Competencies: 3
│
│ ☐ │ Code    │ Competency Name     │ Type    │ NEP Alignment │
│ ───┼─────────┼─────────────────────┼─────────┼───────────────│
│ ☐ │ COMP-001│ Grammar Understanding│ SKILL   │ NEP-1.1       │
│ ☐ │ COMP-002│ Written Communication│ SKILL   │ NEP-1.2       │
│ ☐ │ COMP-003│ Language Proficiency │ ATTITUDE│ NEP-2.1       │
│
│ [+ Add Competency] [Unlink Selected] [Manage Mappings]
│
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ TAB 5: ACTIVITY LOG
│ ─────────────────────────────────────────────────────────────
│ 2024-12-08 10:45 | John Manager | Updated | Duration: 90→120 │
│ 2024-12-07 14:20 | John Manager | Updated | Status: Inactive │
│ 2024-12-01 09:15 | John Manager | Created | Grammar Basics   │
│
│ [Download Log] [Filter by Action ▼]
│
└──────────────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Topic Request
```json
POST /api/v1/topics
{
  "lesson_id": 101,
  "parent_id": null,
  "name": "Grammar Basics",
  "short_name": "Grammar",
  "ordinal": 1,
  "duration_minutes": 90,
  "learning_objectives": ["Identify parts of speech", "Use grammar correctly"],
  "description": "Introduction to grammar concepts...",
  "metadata": {"suggested_readings": ["url1", "url2"]},
  "is_active": true
}
```

### 3.2 Create Topic Response
```json
{
  "success": true,
  "data": {
    "id": 1001,
    "lesson_id": 101,
    "parent_id": null,
    "name": "Grammar Basics",
    "short_name": "Grammar",
    "ordinal": 1,
    "level": 0,
    "duration_minutes": 90,
    "learning_objectives": [...],
    "description": "...",
    "is_active": true,
    "created_at": "2024-12-09T10:30:00Z",
    "updated_at": "2024-12-09T10:30:00Z",
    "created_by": "user_123"
  },
  "message": "Topic created successfully"
}
```

### 3.3 Bulk Sequence Update (Reorder/Move)
```json
PATCH /api/v1/topics/sequence
{
  "updates": [
    {"topic_id": 1001, "parent_id": null, "ordinal": 1},
    {"topic_id": 1002, "parent_id": 1001, "ordinal": 1},
    {"topic_id": 1003, "parent_id": null, "ordinal": 2}
  ],
  "options": {"auto_shift": false}
}
```

### 3.4 List Topics Request
```
GET /api/v1/topics?lesson_id=101&status=active&page=1&limit=10&include=children,questions
```

### 3.5 Get Topic Detail Request
```
GET /api/v1/topics/{id}?include=children,questions,competencies,activity
```

### 3.6 Update Topic Request
```json
PUT /api/v1/topics/{id}
{
  "name": "Grammar Basics",
  "duration_minutes": 100,
  "is_active": true,
  "ordinal": 1
}
```

### 3.7 Delete Topic Request
```
DELETE /api/v1/topics/{id}
?cascade=true

// Response
{
  "success": true,
  "message": "Topic deleted successfully",
  "data": {
    "id": 1001,
    "deleted_children_count": 2,
    "deleted_at": "2024-12-09T11:00:00Z"
  }
}
```

---

## 4. USER WORKFLOWS

### 4.1 Create Root Topic Workflow
```
1. User navigates to Lesson page → Topics section
2. Clicks [+ New Topic]
3. Create Modal opens
4. Class, Subject, Lesson pre-filled (read-only)
5. User enters Topic Name: "Grammar Basics"
6. Short Name auto-fills: "Grammar" (editable)
7. User enters Ordinal: 1
   → System validates uniqueness: ✓ Available
8. User enters Duration: 90 minutes
9. User enters Learning Objectives:
   • Identify parts of speech
   • Use grammar correctly
10. User enters Description
11. User toggles Is Active: ON
12. User clicks [Save]
13. Form validates all fields
14. If valid:
    → POST /api/v1/topics
    → Show success toast: "Topic created successfully"
    → Modal closes, list refreshes
15. If invalid:
    → Show inline error messages
    → User corrects and retries
```

### 4.2 Create Sub-Topic Workflow
```
1. User is viewing Topic detail (Grammar Basics)
2. Clicks [+ Add Sub-Topic] in Sub-Topics tab or from tree
3. Create Modal opens with:
   - Parent Topic: Grammar Basics (pre-filled)
   - Level: 1 (auto-set, read-only)
4. User enters:
   - Topic Name: "Parts of Speech"
   - Ordinal: 1
   - Duration: 45
5. User clicks [Save]
6. POST /api/v1/topics with parent_id = 1001
7. Tree updates in real-time, parent node expands
8. New child highlighted for visibility
```

### 4.3 Reorder Topics Workflow (Drag-and-Drop)
```
1. User opens Hierarchy Tree view
2. Drags "Topic 2" from position 2 to position 1
3. Visual preview shows ordinal changes:
   - Topic 2: ordinal 2 → 1
   - Topic 1: ordinal 1 → 2
4. User releases drag
5. System shows confirmation toast: "Changes pending save"
6. User clicks [Save Changes]
7. PATCH /api/v1/topics/sequence with all changed ordinals
8. Server validates and applies changes
9. UI refreshes with new order
```

### 4.4 Move Sub-Topic to Different Parent Workflow
```
1. User drags "Parts of Speech" (child of Topic 1) to Topic 2
2. Visual preview shows:
   - Topic: Comprehension (new parent)
   - Level: 1 (unchanged)
   - Ordinal: will be next available (e.g., 2)
3. System checks for cycles → OK
4. User confirms drag drop
5. PATCH /api/v1/topics/sequence updates parent_id and ordinal
6. Server re-validates level, ordinals across affected nodes
7. UI updates hierarchy and activity log
```

### 4.5 Edit Topic Workflow
```
1. User clicks on topic in list or detail view
2. Detail panel opens (read-only initially)
3. User clicks [Edit]
4. Modal opens with all fields editable
5. User modifies duration: 90 → 120
6. User modifies description
7. User clicks [Save]
8. PUT /api/v1/topics/{id} with updated payload
9. Show success toast: "Topic updated successfully"
10. Detail panel refreshes with new data
```

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Colors & Typography
| Element | Color | Font | Size | Weight |
|---------|-------|------|------|--------|
| Page Title | #1F2937 (Dark Gray) | Inter/Roboto | 28px | Bold (700) |
| Section Title | #374151 | Inter/Roboto | 18px | Bold (600) |
| Field Label | #4B5563 | Inter/Roboto | 14px | Medium (500) |
| Input Text | #000000 | Inter/Roboto | 14px | Regular (400) |
| Level Badge | #6B7280 | Inter/Roboto | 12px | Regular (400) |
| Primary Button | #3B82F6 (Blue) | - | 14px | Medium (500) |
| Danger Button | #EF4444 (Red) | - | 14px | Medium (500) |
| Success Message | #10B981 (Green) | - | 14px | Medium (500) |
| Error Message | #EF4444 (Red) | - | 14px | Medium (500) |

### 5.2 Spacing & Layout
- **Page Padding:** 24px
- **Section Spacing:** 16px
- **Form Field Spacing:** 12px
- **Button Spacing:** 8px
- **Modal Padding:** 24px
- **List Row Height:** 48px

### 5.3 Icons
- **New:** ➕ Plus
- **Edit:** ✏️ Pencil
- **Delete:** 🗑️ Trash
- **Add Child:** ⊕ Plus in circle
- **Drag:** ≡ Hamburger
- **Expand:** ▼/▶ Chevron
- **More:** ⋯ Ellipsis

### 5.4 Responsive Design
- **Mobile (<640px):** Single column, stacked modals, tree collapses to accordion
- **Tablet (640-1024px):** Two-column layout
- **Desktop (>1024px):** Three-column with detail panel

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 Keyboard Navigation
- **Tab:** Navigate between form fields
- **Enter/Space:** Activate buttons, toggle checkboxes
- **Escape:** Close modals
- **Arrow Keys:** Navigate tree, reorder items
- **Ctrl+S:** Save form

### 6.2 ARIA Labels & Screen Readers
```html
<input id="topic-name" aria-label="Topic Name (required)" aria-required="true" />
<button aria-label="Delete topic: Grammar Basics">🗑️</button>
<ul role="tree" aria-label="Topic hierarchy">...</ul>
```

### 6.3 Validation & Error Messages
- Required fields marked with red asterisk (*)
- Error messages appear **below** field in red (#EF4444)
- Field border turns red on error
- Errors prevent form submission

### 6.4 Loading & Async States
- Skeleton loaders while data fetches
- Disable buttons during submission (show spinner)
- Toast notifications for success/error (5-second persist)

---

## 7. EDGE CASES & ERROR SCENARIOS

| Scenario | Behavior |
|----------|----------|
| Duplicate Topic Name | Show error: "Topic name already exists under this parent" |
| Invalid Ordinal | Show suggestions: "Available: [1, 2, 4, 5]" |
| Create Cycle | Show error: "Cannot use child topic as parent" |
| Large Tree | Lazy-load children, virtualize nodes, show pagination |
| Delete with Children | Confirmation: "Delete 3 sub-topics?" Options: Cascade / Reparent |
| Network Error | Auto-retry with exponential backoff, show Retry button |
| Concurrent Edit | Warn: "Topic modified by another user. Refresh?" |

---

## 8. PERFORMANCE CONSIDERATIONS

### 8.1 Data Optimization
- **Topic List:** Server-side pagination (10/25/50/100 per page)
- **Tree:** Lazy-load children on expand
- **Questions Tab:** Pagination, 10 per page
- **Activity Log:** Pagination, last 20 by default

### 8.2 Caching Strategy
- Cache lesson dropdowns (TTL: 1 hour)
- Cache topic tree (invalidate on create/edit/delete)
- Use ETags for topic detail (5-minute cache)

### 8.3 API Rate Limiting
- List: 60 req/min
- Create/Update: 30 req/min
- Reorder: 20 req/min
- Delete: 10 req/min

---

## 9. TESTING CHECKLIST

### 9.1 Functional Testing
- [ ] Create root topic with all fields
- [ ] Create sub-topic with parent prefilled
- [ ] Edit topic successfully
- [ ] Delete topic with confirmation
- [ ] Reorder topics via drag-and-drop
- [ ] Move topic between parents (change hierarchy)
- [ ] Filter topics by status
- [ ] Search topics by name
- [ ] View topic detail with all tabs
- [ ] Validate duplicate name error
- [ ] Validate ordinal uniqueness
- [ ] Validate cycle prevention
- [ ] Navigate tabs without data loss

### 9.2 UI/UX Testing
- [ ] Responsive layout (mobile/tablet/desktop)
- [ ] Modal opens/closes smoothly
- [ ] Tree expand/collapse works
- [ ] Drag-drop visual feedback
- [ ] Form validation shows errors inline
- [ ] Buttons disabled during submission
- [ ] Toast notifications appear/disappear

### 9.3 Accessibility Testing
- [ ] Keyboard navigation (Tab, Enter, Escape, Arrow keys)
- [ ] Screen reader announces labels/errors
- [ ] Color contrast meets WCAG AA
- [ ] Focus order logical

### 9.4 Integration Testing
- [ ] API calls match contract
- [ ] Error responses handled gracefully
- [ ] Related data (lesson, class, subject) loads correctly
- [ ] Questions linked correctly
- [ ] Competencies linked correctly
- [ ] Activity log populated

---

## 10. FUTURE ENHANCEMENTS

1. **CSV Import:** Bulk import topics with parent path notation (e.g., "Chapter 1/Topic A/Sub-Topic 1")
2. **Topic Templates:** Pre-built topic structures for common subjects
3. **ML Suggestions:** Auto-suggest topic grouping and ordering
4. **Real-time Collaboration:** Multiple users editing topic tree simultaneously
5. **Version History:** View and restore previous topic versions
6. **Analytics:** Topic usage stats, student performance by topic
7. **Attachments:** Upload resources to topics
8. **Advanced Search:** Full-text search with filters and facets
9. **API Integration:** Import topics from external curriculum databases
10. **Topic Dependencies:** Define prerequisite topics before accessing others

---

## Appendix A: Component Library References

| Component | Library | Notes |
|-----------|---------|-------|
| Dropdown | Headless UI / Chakra | Multi-select, search |
| Modal | Headless UI / Radix | Accessible, customizable |
| Input | Tailwind / Material UI | Text, number, textarea |
| Button | Tailwind / Chakra | Primary, secondary, danger |
| Table | TanStack Table / DataTable | Sortable, filterable, paginated |
| Tree | React Beautiful Tree / Nivo | Hierarchical, drag-drop |
| Toast | React Hot Toast / Sonner | Auto-dismiss |

---

**Document Created By:** Database Architect  
**Last Reviewed:** December 10, 2025  
**Version Control:** Git repository

