# Screen Design Specification: Lesson Management Module
## Document Version: 1.0
**Last Updated:** December 9, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Lesson Management Module**, enabling teachers and administrators to create, view, edit, and manage lessons within the curriculum structure (Class → Subject → Lesson → Topic → Sub-Topics).

### 1.2 User Roles & Permissions
| Role         | Create | View | Update | Delete | print | Export | Import |
|--------------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| PG Support   |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| School Admin |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✗    |   ✗    |
| Principal    |   ✓    |   ✓  |   ✗    |   ✗    |   ✓   |   ✗    |   ✗    |
| Teacher      |   ✗    |   ✓  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |
| Student      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |
| Parents      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗   |   ✗    |   ✗    |



### 1.3 Data Context

Database Table: sch_lessons
├── id (BIGINT PRIMARY KEY)
├── name (VARCHAR 50)
├── code (VARCHAR 7)
├── class_id (FK to sch_classes)
├── subject_id (FK to sch_subjects)
├── ordinal (TINYINT - sequence order)
├── description (TEXT)
├── duration (INT - periods required)
├── is_active (TINYINT boolean)
├── created_at, updated_at, deleted_at (timestamps)
└── Unique constraints: (class_id, subject_id, name) & (class_id, subject_id, ordinal)
+

---

## 2. SCREEN LAYOUTS

### 2.1 Lesson List Screen
**Route:** `/curriculum/lessons` or `/subjects/{subjectId}/lessons`

#### 2.1.1 Page Layout

┌────────────────────────────────────────────────────────────────────────────────────┐
│ SYLLABUS MANAGEMENT > LESSONS                                                      │
├────────────────────────────────────────────────────────────────────────────────────┤
│   [_____________________________________________________] [Search]  [+ New Lesson] │
├────────────────────────────────────────────────────────────────────────────────────┤
│ CLASS: [Dropdown ▼]    SUBJECT: [Dropdown ▼]    STATUS: [Dropdown ▼]      [Filter] │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Subject     | Lesson Name    │ Code  │ Sequence │ Duration │ Status   │ Action |
│────────────────────────────────────────────────────────────────────────────────────│
│ ☐ │ Science     | Lesson 1       │ 9_ENG │    1     │ 5 Periods│ Active   │ + # -  |
│ ☐ │ Science     | Lesson 2       │ 9_ENG │    2     │ 4 Periods│ Inactive │ + # -  |
│ ☐ │ Science     | Lesson 3       │ 9_ENG │    3     │ 6 Periods│ Active   │ + # -  |
│   │ Science     | ...            │  ...  │  ...     │   ...    │   ...    │        |
│────────────────────────────────────────────────────────────────────────────────────│
│ Showing 1-10 of 45 lessons                                           [< 1 2 3 >]   │
└────────────────────────────────────────────────────────────────────────────────────┘


#### 2.1.2 Components & Interactions

**Filter Bar:**
- **Class Dropdown** – Single-select (filter by class)
  - Options: 6th, 7th, 8th, 9th, 10th, 11th, 12th
  - Default: Current class context
- **Subject Dropdown** – Single-select
  - Populated based on selected class
  - Options: All sections for selected class
- **Status Dropdown**
  - Options: Active, Inactive, All
  - Default: Active

**Search Button:**
- Placeholder: "Search by lesson name or code..."
- Real-time filtering
- Search fields: name, code, description

**Sort Options:**
- By Name (A-Z, Z-A)
- By Sequence Order (Ascending, Descending)
- By Duration (Low-High, High-Low)
- By Created Date (Newest, Oldest)
- By Status (Active First, Inactive First)

**Buttons:**
- **[+ New Lesson]** – Opens Create Lesson Modal
  - Color: Primary (Blue)
  - Icon: Plus
- **[⋯ Actions]** – Bulk actions dropdown
  - Options: Delete Selected, Activate, Deactivate, Export
  - Enabled only when rows are selected

**Column Actions (Inline):**
- Click row → Opens Lesson Detail/Edit Modal
- Right-click row → Context menu
  - Options: View, Edit, Duplicate, Delete, Copy Link
- Hover row → Show action buttons: [Edit] [View Topics] [Delete]

**Pagination:**
- Records per page: 10, 25, 50, 100
- Total records display: "Showing X-Y of Z"
- Navigation: Previous, Page numbers (1-10 max visible), Next
- Jump to page: [Go to page: ___]

---

### 2.2 Create Lesson Screen (Modal)
**Route:** `GET /curriculum/lessons/new` or Modal overlay

#### 2.2.1 Layout
```
┌──────────────────────────────────────────────────┐
│ CREATE NEW LESSON                            [✕] │
├──────────────────────────────────────────────────┤
│                                                  │
│ Class *              [Dropdown ▼]               │
│ (e.g., 9th Standard)                            │
│                                                  │
│ Subject *            [Dropdown ▼]               │
│ (filtered by class)                             │
│                                                  │
│ Lesson Name *        [________________]         │
│ (Max 50 chars, e.g., "Lesson 1" or "Chapter 5") │
│                                                  │
│ Lesson Code          [_______]                  │
│ (Auto-generated: 9_ENG, 9_MAT)                 │
│ [☐ Auto-generate]                              │
│                                                  │
│ Sequence Order *     [__] (e.g., 1, 2, 3...)   │
│ (Must be unique per class-subject)              │
│                                                  │
│ Duration (Periods)   [__] periods               │
│ (Approx. teaching time)                         │
│                                                  │
│ Description          [________________]         │
│ (Multi-line text, optional)                     │
│ ┌────────────────────────────────────────────┐ │
│ │ Brief description of lesson content...     │ │
│ └────────────────────────────────────────────┘ │
│                                                  │
│ Active Status        [☑] Enable this lesson     │
│                                                  │
├──────────────────────────────────────────────────┤
│              [Cancel]  [Save]  [Save & New]     │
└──────────────────────────────────────────────────┘
```

#### 2.2.2 Field Specifications

| Field | Type | Validation | Placeholder | Required |
|-------|------|------------|-------------|----------|
| Class | Dropdown | FK to sch_classes | "Select Class" | ✓ |
| Subject | Dropdown | FK to sch_subjects, filtered | "Select Subject" | ✓ |
| Lesson Name | Text Input | Max 50 chars, no special chars | "e.g., Lesson 1" | ✓ |
| Lesson Code | Text Input | Max 7 chars, alphanumeric | Auto-filled | ✗ |
| Sequence Order | Number Input | Positive integer, unique per class-subject | "1" | ✓ |
| Duration | Number Input | Positive integer (periods) | "5" | ✗ |
| Description | TextArea | Max 2000 chars | "Brief description..." | ✗ |
| Active Status | Toggle | Boolean | Checked | ✗ |

#### 2.2.3 Validation Rules
```
✓ Class is required
✓ Subject is required (auto-filtered by class)
✓ Lesson Name is required
  - Max length: 50 characters
  - Cannot be empty
  - Must be unique within class-subject combination
✓ Sequence Order is required
  - Must be positive integer
  - Must be unique within class-subject combination
  - Alert if ordinal > max ordinal + 1 (skip numbers not allowed)
✓ Duration is optional
  - If provided, must be positive integer
✓ Description is optional
  - Max 2000 characters
✓ Lesson Code auto-generated as {classCode}_{subjectCode}
  - Example: 9_ENG, 9_MAT
  - Can be manually overridden
```

#### 2.2.4 Error Handling
```
Error Scenarios:
1. Duplicate Lesson Name
   Message: "A lesson with this name already exists for this class-subject."
   Action: Highlight field, show suggestion to append (1, 2, 3...)
   
2. Invalid Sequence Order
   Message: "Sequence order must be unique for this class-subject."
   Suggestion: "Available orders: [1, 2, 4, 5] (3 is taken)"
   
3. Class/Subject Not Selected
   Message: "Please select both Class and Subject."
   
4. Network Error on Save
   Message: "Failed to save lesson. Please try again."
   Retry: Auto-retry after 2 seconds, manual retry button
```

#### 2.2.5 Smart Features
- **Auto-code Generation:** When class + subject selected, code is auto-populated
  - Example: Class="9th", Subject="English" → Code="9_ENG"
  - User can override before save
- **Duplicate Lesson:** Pre-fill from existing lesson (copy button in list view)
  - Opens Create Modal with all fields populated
  - User changes name, ordinal, duration as needed
- **Save & New:** Clears form after save, stays in Create modal
  - Useful for bulk lesson creation

---

### 2.3 View / Edit Lesson Screen
**Route:** `/curriculum/lessons/{id}` or Modal overlay

#### 2.3.1 Layout (Tabbed Interface)
```
┌──────────────────────────────────────────────────────────────┐
│ LESSON DETAIL > Lesson 1 (9_ENG)              [Edit] [Delete] │
├──────────────────────────────────────────────────────────────┤
│ [Basic Info] [Topics] [Related Questions] [Activity Log]     │
├──────────────────────────────────────────────────────────────┤
│
│ TAB 1: BASIC INFO
│ ─────────────────────────────────────────────────────────────
│ Class:                  9th Standard
│ Subject:                English
│ Lesson Name:            Lesson 1
│ Lesson Code:            9_ENG
│ Sequence Order:         1 (out of 5 lessons)
│ Duration:               5 Periods
│ Status:                 ✓ Active
│ Description:
│   └─ Introduction to English Literature and basic grammar
│        concepts for students to build foundational skills.
│
│ Created By:             John Teacher
│ Created Date:           2024-12-01
│ Last Modified By:       John Teacher
│ Last Modified Date:     2024-12-08
│
│ [Edit] [Duplicate] [Archive]
│
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ TAB 2: TOPICS (Hierarchical List)
│ ─────────────────────────────────────────────────────────────
│ ├─ Topic 1: Grammar Basics                    [⊕ Add Sub-Topic]
│ │   Duration: 2 Periods | Questions: 12 | Status: Active
│ │   ├─ Sub-Topic 1.1: Parts of Speech
│ │   │   Duration: 1 Period | Questions: 5
│ │   └─ Sub-Topic 1.2: Verb Tenses
│ │       Duration: 1 Period | Questions: 7
│ │
│ ├─ Topic 2: Comprehension                     [⊕ Add Sub-Topic]
│ │   Duration: 2 Periods | Questions: 8 | Status: Active
│ │   └─ Sub-Topic 2.1: Reading Practice
│ │       Duration: 2 Periods | Questions: 8
│ │
│ └─ Topic 3: Writing Skills                    [⊕ Add Sub-Topic]
│     Duration: 1 Period | Questions: 4 | Status: Inactive
│
│ [+ New Topic] [⋯ Manage Topics]
│
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ TAB 3: RELATED QUESTIONS
│ ─────────────────────────────────────────────────────────────
│ Total Questions: 24 (across all topics)
│ 
│ Filter by: [Difficulty ▼] [Question Type ▼] [Bloom Level ▼]
│
│ ☐ │ Question | Type | Difficulty | Bloom Level | Topics      │
│ ───┼──────────┼──────┼────────────┼─────────────┼──────────────│
│ ☐ │ Q1: What│ MCQ  │ Medium     │ Understand  │ Topic 1.1    │
│ ☐ │ Q2: Expl│ SA   │ Hard       │ Analyze     │ Topic 1.2    │
│ ☐ │ Q3: Fill│ FB   │ Easy       │ Remember    │ Topic 2.1    │
│   │ ...     │ ...  │ ...        │ ...         │ ...          │
│
│ [Export Questions] [Assign to Assessment]
│
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ TAB 4: ACTIVITY LOG
│ ─────────────────────────────────────────────────────────────
│ 2024-12-08 10:45 | John Teacher | Updated | Duration: 5→6    │
│ 2024-12-07 14:20 | John Teacher | Updated | Status: Active   │
│ 2024-12-01 09:15 | John Teacher | Created | Lesson 1         │
│
│ [Download Log] [Filter by Action ▼]
│
└──────────────────────────────────────────────────────────────┘
```

#### 2.3.2 Edit Mode Interaction
- **[Edit] Button** on View screen opens inline editing or modal
- Fields become editable (same validation as Create)
- **[Save]** commits changes, shows success toast
- **[Cancel]** reverts to read-only view
- **[Delete]** button with confirmation dialog

---

### 2.4 Lesson Sequence Management Screen
**Route:** `/curriculum/lessons/sequence` or inline in list

#### 2.4.1 Drag-and-Drop Sequence Editor
```
┌──────────────────────────────────────────────────────────────┐
│ LESSON SEQUENCE MANAGER                                       │
├──────────────────────────────────────────────────────────────┤
│ Class: [9th Standard ▼]  Subject: [English ▼]  [Confirm] [Reset]│
├──────────────────────────────────────────────────────────────┤
│
│ 1. ≡ Lesson 1 (Grammar Basics)           Duration: 5 Periods  │
│                                           Status: Active       │
│
│ 2. ≡ Lesson 2 (Comprehension)            Duration: 4 Periods  │
│                                           Status: Active       │
│
│ 3. ≡ Lesson 3 (Writing Skills)           Duration: 6 Periods  │
│                                           Status: Inactive     │
│
│ [+ Add New Lesson]                        [Save Changes]
│
└──────────────────────────────────────────────────────────────┘
```
- Drag by ≡ icon to reorder
- Visual feedback on drag (highlight, shadow)
- Real-time ordinal recalculation on drag
- **[Save Changes]** persists all ordinal updates
- **[Reset]** reverts to last saved state

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Lesson Request
```json
POST /api/v1/lessons
{
  "class_id": 9,
  "subject_id": 5,
  "name": "Lesson 1",
  "code": "9_ENG",
  "ordinal": 1,
  "duration": 5,
  "description": "Introduction to English Literature",
  "is_active": true
}
```

### 3.2 Create Lesson Response
```json
{
  "success": true,
  "data": {
    "id": 101,
    "class_id": 9,
    "subject_id": 5,
    "name": "Lesson 1",
    "code": "9_ENG",
    "ordinal": 1,
    "duration": 5,
    "description": "Introduction to English Literature",
    "is_active": true,
    "created_at": "2024-12-09T10:30:00Z",
    "updated_at": "2024-12-09T10:30:00Z",
    "created_by": "teacher_123"
  },
  "message": "Lesson created successfully"
}
```

### 3.3 List Lessons Request
```
GET /api/v1/lessons?class_id=9&subject_id=5&status=active&page=1&limit=10&sort=ordinal:asc
```

### 3.4 List Lessons Response
```json
{
  "success": true,
  "data": [
    {
      "id": 101,
      "name": "Lesson 1",
      "code": "9_ENG",
      "ordinal": 1,
      "duration": 5,
      "is_active": true,
      "class": "9th Standard",
      "subject": "English",
      "topic_count": 3,
      "question_count": 24,
      "created_at": "2024-12-01T09:15:00Z"
    },
    {
      "id": 102,
      "name": "Lesson 2",
      "code": "9_ENG",
      "ordinal": 2,
      "duration": 4,
      "is_active": true,
      "class": "9th Standard",
      "subject": "English",
      "topic_count": 2,
      "question_count": 15,
      "created_at": "2024-12-02T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 45,
    "pages": 5
  }
}
```

### 3.5 Get Lesson Detail Request
```
GET /api/v1/lessons/{id}
```

### 3.6 Get Lesson Detail Response
```json
{
  "success": true,
  "data": {
    "id": 101,
    "name": "Lesson 1",
    "code": "9_ENG",
    "ordinal": 1,
    "duration": 5,
    "description": "Introduction to English Literature",
    "is_active": true,
    "class_id": 9,
    "class": {
      "id": 9,
      "name": "9th Standard",
      "code": "9"
    },
    "subject_id": 5,
    "subject": {
      "id": 5,
      "name": "English",
      "code": "ENG"
    },
    "topics": [
      {
        "id": 1001,
        "name": "Grammar Basics",
        "parent_id": null,
        "level": 0,
        "duration_minutes": 120,
        "question_count": 12
      }
    ],
    "created_at": "2024-12-01T09:15:00Z",
    "updated_at": "2024-12-08T10:45:00Z",
    "created_by_name": "John Teacher",
    "modified_by_name": "John Teacher"
  }
}
```

### 3.7 Update Lesson Request
```json
PUT /api/v1/lessons/{id}
{
  "name": "Lesson 1 - Updated",
  "duration": 6,
  "description": "Updated description",
  "is_active": true,
  "ordinal": 1
}
```

### 3.8 Delete Lesson Request
```
DELETE /api/v1/lessons/{id}

// Response
{
  "success": true,
  "message": "Lesson deleted successfully",
  "data": {
    "id": 101,
    "deleted_at": "2024-12-09T11:00:00Z"
  }
}
```

---

## 4. USER WORKFLOWS

### 4.1 Create New Lesson Workflow
```
1. User clicks [+ New Lesson] on List screen
2. Create Lesson Modal opens
3. User selects Class (e.g., 9th)
4. Subject dropdown auto-filters for 9th (e.g., English, Maths, Science)
5. User selects Subject (e.g., English)
6. Code auto-generates: 9_ENG
7. User enters Lesson Name: "Lesson 1"
8. User enters Sequence Order: 1
   → System validates uniqueness: ✓ Available
9. User enters Duration: 5 periods
10. User enters Description: "Introduction..."
11. User toggles Active Status: ON
12. User clicks [Save]
13. Form validates all fields
14. If valid:
    → POST /api/v1/lessons with payload
    → Show success toast: "Lesson created successfully"
    → Modal closes or stays open with [Save & New]
15. If invalid:
    → Show inline error messages
    → Highlight problematic fields
    → User corrects and retries
```

### 4.2 Edit Lesson Workflow
```
1. User clicks on lesson row in List view
2. View modal opens (read-only initially)
3. User clicks [Edit] button
4. Fields become editable (same form as Create)
5. User modifies fields (e.g., duration 5→6)
6. User clicks [Save]
7. Form validates
8. If valid:
    → PUT /api/v1/lessons/{id} with updated payload
    → Show success toast: "Lesson updated successfully"
    → Modal refreshes with new data
9. If invalid:
    → Show inline errors
    → User corrects and retries
```

### 4.3 Reorder Lessons Workflow
```
1. User navigates to Sequence Manager screen
2. User selects Class + Subject
3. List shows all lessons for that class-subject in current sequence
4. User drags lesson 3 to position 1
5. Ordinals recalculate: 3→1, 1→2, 2→3
6. User confirms visual order is correct
7. User clicks [Save Changes]
8. PATCH /api/v1/lessons/sequence with payload:
   {
     "updates": [
       {"lesson_id": 103, "ordinal": 1},
       {"lesson_id": 101, "ordinal": 2},
       {"lesson_id": 102, "ordinal": 3}
     ]
   }
9. Show success toast: "Lesson sequence updated"
```

### 4.4 View Lesson with Topics Workflow
```
1. User clicks on lesson in List view
2. View modal opens to Basic Info tab
3. User clicks [Topics] tab
4. System loads hierarchical topic tree
5. Tree shows:
   ├─ Topic 1 (Parent)
   │  ├─ Sub-Topic 1.1
   │  └─ Sub-Topic 1.2
   └─ Topic 2 (Parent)
6. User clicks [⊕ Add Sub-Topic] under Topic 1
7. Topic creation modal opens with:
   - Parent set to Topic 1
   - Level auto-set to 1
8. User creates sub-topic
9. Tree updates in real-time
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
| Helper Text | #6B7280 | Inter/Roboto | 12px | Regular (400) |
| Primary Button | #3B82F6 (Blue) | - | 14px | Medium (500) |
| Danger Button | #EF4444 (Red) | - | 14px | Medium (500) |
| Success Message | #10B981 (Green) | - | 14px | Medium (500) |
| Error Message | #EF4444 (Red) | - | 14px | Medium (500) |

### 5.2 Spacing & Layout
- **Page Padding:** 24px (top, bottom, left, right)
- **Section Spacing:** 16px between sections
- **Form Field Spacing:** 12px between field rows
- **Button Spacing:** 8px between buttons (horizontal)
- **Modal Padding:** 24px
- **List Row Height:** 48px (minimum)

### 5.3 Icons
- **New:** ➕ Plus Icon
- **Edit:** ✏️ Pencil Icon
- **Delete:** 🗑️ Trash Icon
- **View:** 👁️ Eye Icon
- **Duplicate:** 📋 Copy Icon
- **Drag:** ≡ Hamburger Icon
- **Collapse/Expand:** ▼/▶ Chevron Icon
- **More Actions:** ⋯ Ellipsis Icon
- **Close:** ✕ X Icon

### 5.4 Responsive Design
| Breakpoint | Width | Grid Layout |
|------------|-------|-------------|
| Mobile | < 640px | 1 column, stacked |
| Tablet | 640px - 1024px | 2 columns |
| Desktop | > 1024px | 3+ columns |

**Mobile Adjustments:**
- Dropdowns collapse to full-width selections
- Modals take 95% screen width (max 100%)
- List view becomes card-based (single column)
- Hide non-essential columns (e.g., code)

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 Keyboard Navigation
- **Tab Key:** Navigate between form fields
- **Enter/Space:** Activate buttons, toggle checkboxes
- **Escape:** Close modals, cancel operations
- **Arrow Keys:** Navigate dropdowns, reorder items
- **Ctrl+S:** Save form (if supported)

### 6.2 ARIA Labels & Screen Readers
```html
<!-- Example -->
<input 
  id="lesson-name"
  aria-label="Lesson Name (required)"
  aria-required="true"
  placeholder="e.g., Lesson 1"
/>

<button aria-label="Delete lesson: Lesson 1">
  🗑️
</button>
```

### 6.3 Validation & Error Messages
- All required fields marked with red asterisk (*)
- Error messages appear **below** field in red (#EF4444)
- Field border turns red on error (focus state: red outline)
- Errors prevent form submission
- User can correct and resubmit

### 6.4 Loading & Async States
- Show skeleton loaders while data fetches
- Disable buttons during submission (show loading spinner)
- Toast notifications for success/error (persist 5 seconds)
- Optimistic UI updates where applicable

---

## 7. EDGE CASES & ERROR SCENARIOS

| Scenario | Behavior |
|----------|----------|
| No Class Selected | Disable Subject dropdown, show hint "Select Class first" |
| No Subject Selected | Disable Create button, show hint "Select Subject first" |
| Duplicate Lesson Name | Show error: "Lesson name already exists for this class-subject" |
| Invalid Sequence Order | Show error: "Sequence must be unique. Available: [1, 2, 4, 5]" |
| No Topics Created | Show info message: "No topics yet. Create topics for this lesson." |
| Delete with Child Topics | Show confirmation: "This lesson has 3 topics. Delete all?" |
| Network Error | Show error toast with Retry button, auto-retry after 2s |
| User Lacks Permission | Disable Edit/Delete buttons, show "You don't have permission" |
| Concurrent Edit | Show warning: "This lesson was modified by another user. Refresh?" |

---

## 8. PERFORMANCE CONSIDERATIONS

### 8.1 Data Optimization
- **Lesson List:** Pagination (10/25/50/100 per page)
- **Topics Tree:** Lazy-load sub-topics on expand
- **Questions Tab:** Lazy-load, pagination (10 per page)
- **Activity Log:** Pagination, show last 20 by default

### 8.2 Caching Strategy
- Cache class/subject dropdowns (TTL: 1 hour)
- Cache lesson detail for 5 minutes (invalidate on edit)
- Cache topics tree (invalidate on topic create/edit/delete)

### 8.3 API Rate Limiting
- List endpoint: 60 requests/minute
- Create/Update: 30 requests/minute
- Delete: 10 requests/minute

---

## 9. TESTING CHECKLIST

### 9.1 Functional Testing
- [ ] Create lesson with all fields
- [ ] Create lesson with only required fields
- [ ] Edit lesson successfully
- [ ] Delete lesson with confirmation
- [ ] Bulk delete lessons
- [ ] Reorder lessons via drag-and-drop
- [ ] Filter lessons by class/subject/status
- [ ] Search lessons by name/code
- [ ] View lesson detail with all tabs
- [ ] Navigate between tabs without data loss
- [ ] Validate duplicate name error
- [ ] Validate duplicate ordinal error
- [ ] Auto-code generation works
- [ ] Manual code override works

### 9.2 UI/UX Testing
- [ ] Responsive layout on mobile/tablet/desktop
- [ ] Modal opens/closes smoothly
- [ ] Form validation shows inline errors
- [ ] Toast notifications appear and disappear
- [ ] Loading states show while fetching
- [ ] Buttons disabled during submission
- [ ] Keyboard navigation works (Tab, Enter, Escape)
- [ ] Screen reader announces labels/errors
- [ ] Color contrast meets WCAG AA standards

### 9.3 Integration Testing
- [ ] API calls match contract
- [ ] Error responses handled gracefully
- [ ] Success messages show correct data
- [ ] Related data (class, subject) loads correctly
- [ ] Topics list fetches for lesson detail
- [ ] Activity log populated correctly

---

## 10. FUTURE ENHANCEMENTS

1. **Bulk Import:** Import lessons from CSV/Excel
2. **Lesson Templates:** Pre-built lesson structures
3. **Lesson Recommendations:** AI suggestions based on curriculum
4. **Real-time Collaboration:** Multiple users editing lesson simultaneously
5. **Version History:** View and restore previous lesson versions
6. **Analytics:** Lesson usage statistics, student performance per lesson
7. **Attachments:** Upload PDF, images, videos to lessons
8. **Search & Replace:** Find and replace text across multiple lessons
9. **API Integration:** Import lessons from external curriculum databases
10. **Mobile App:** Native mobile support for lesson management

---

## Appendix A: Component Library References

| Component | Library | Notes |
|-----------|---------|-------|
| Dropdown | Headless UI / Chakra UI | Multi-select, search, filter |
| Modal | Headless UI / Radix UI | Accessible, customizable |
| Input | Tailwind / Material UI | Text, number, textarea |
| Button | Tailwind / Chakra UI | Primary, secondary, danger |
| Table | TanStack Table / DataTable | Sortable, filterable, paginated |
| Toast | React Hot Toast / Sonner | Auto-dismiss, position customizable |
| Tree | React Beautiful Tree / Nivo | Hierarchical display, drag-drop |
| Loader | React Loading / Skeleton | Pulse animation |

---

**Document Created By:** Database Architect  
**Last Reviewed:** December 9, 2025  
**Next Review Date:** March 9, 2025  
**Version Control:** See Git Commit History
