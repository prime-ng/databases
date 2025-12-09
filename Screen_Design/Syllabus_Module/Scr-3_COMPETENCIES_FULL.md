# Screen Design Specification: Competency Management Module
## Document Version: 2.0 (Full Page Layouts)
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Competency Management Module**, enabling curriculum managers to build and maintain the competency framework (NEP-aligned), create hierarchical competencies, and link them to Topics. Covers list views, CRUD operations, hierarchical management, bulk tools, and integrations with Topics.

### 1.2 User Roles & Permissions
| Role         | Create | View | Update | Delete | Reorder | Map Topics | Export | Import |
|--------------|--------|------|--------|--------|---------|------------|--------|--------|
| Super Admin  |   ✓    |   ✓  |   ✓    |   ✓    |   ✓     |     ✓      |   ✓    |   ✓    |
| School Admin |   ✓    |   ✓  |   ✓    |   ✓    |   ✓     |     ✓      |   ✗    |   ✗    |
| Curriculum Manager |   ✓    |   ✓  |   ✓    |   ✓    |   ✓     |     ✓      |   ✓    |   ✗    |
| Teacher      |   ✗    |   ✓  |   ✗    |   ✗    |   ✗     |     ✓      |   ✗    |   ✗    |
| QA / Auditor |   ✗    |   ✓  |   ✗    |   ✗    |   ✗     |     ✗      |   ✗    |   ✗    |

### 1.3 Data Context

Database Table: slb_competencies
├── id (BIGINT PRIMARY KEY)
├── code (VARCHAR 50 - e.g., "COMP-ENG-001")
├── name (VARCHAR 200)
├── class_id (FK to sch_classes, nullable)
├── subject_id (FK to sch_subjects, nullable)
├── description (TEXT)
├── parent_competency_id (FK to self for hierarchy, nullable)
├── competency_type (ENUM: KNOWLEDGE, SKILL, ATTITUDE)
├── nep_alignment (JSON - array of NEP codes)
├── metadata (JSON)
├── is_active (TINYINT boolean)
├── created_at, updated_at, deleted_at (timestamps)
└── Unique constraints: (code, class_id, subject_id)

---

## 2. SCREEN LAYOUTS

### 2.1 Competency List Screen
**Route:** `/curriculum/competencies`

#### 2.1.1 Page Layout

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ SYLLABUS MANAGEMENT > COMPETENCIES                                                 │
├────────────────────────────────────────────────────────────────────────────────────┤
│   [_____________________________________________________] [Search]  [+ New Competency]│
├────────────────────────────────────────────────────────────────────────────────────┤
│ CLASS: [Dropdown ▼]    SUBJECT: [Dropdown ▼]    TYPE: [All ▼]    STATUS: [All ▼]  │
│ NEP ALIGNMENT: [Select ▼]                                            [Filter]      │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Code        │ Competency Name  │ Type    │ Parent      │ Topics │ Status │ A  │
│────────────────────────────────────────────────────────────────────────────────────│
│ ☐ │ COMP-ENG-001│ Grammar Mastery  │ SKILL   │ None        │   3    │ Active │ +#-│
│ ☐ │ COMP-ENG-002│ Communication    │ SKILL   │ None        │   2    │ Active │ +#-│
│ ☐ │ COMP-ENG-003│ Creative Writing │ SKILL   │ Communication│  1    │ Active │ +#-│
│   │ ...         │ ...              │ ...     │ ...         │  ...   │  ...   │... │
│────────────────────────────────────────────────────────────────────────────────────│
│ Showing 1-10 of 25 competencies                                   [< 1 2 3 >]      │
│                                                                                     │
│ [View Hierarchy] [Export Competencies] [⋯ Bulk Actions]                           │
└────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components & Interactions

**Filter Bar:**
- **Class Dropdown** – Single-select, optional (all classes if not selected)
- **Subject Dropdown** – Single-select, auto-filtered by class
- **Type Dropdown** – Options: All, Knowledge, Skill, Attitude
- **Status Dropdown** – Options: All, Active, Inactive
- **NEP Alignment** – Multi-select tags (e.g., NEP-1.1, NEP-1.2)

**Search:**
- Placeholder: "Search by code, name..."
- Fields: code, name, description, nep_alignment

**Buttons:**
- **[+ New Competency]** – Opens Create Competency Modal
- **[View Hierarchy]** – Opens full-screen tree view
- **[Export Competencies]** – Downloads CSV with competency structure
- **[⋯ Bulk Actions]** – Options: Activate, Deactivate, Delete, Export
  - Enabled only when rows selected

**Column Actions:**
- Click row → Opens Competency Detail panel
- Hover row → Show action buttons: [Add Child] [Edit] [Delete]
- Checkbox → Select row for bulk operations

**Pagination:**
- Records per page: 10, 25, 50, 100
- Total display: "Showing X-Y of Z competencies"

---

### 2.2 Hierarchical Competency Tree View
**Route:** `/curriculum/competencies/tree`

#### 2.2.1 Layout

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ COMPETENCY HIERARCHY TREE                           [← Back]  [List View]         │
├────────────────────────────────────────────────────────────────────────────────────┤
│ [+ New Competency] [Expand All] [Collapse All] [Save Changes] [⋯ Actions]        │
├────────────────────────────────────────────────────────────────────────────────────┤
│
│ ▼ COMP-ENG-001: Grammar Mastery (SKILL)              [+ Add Child] [✏️] [🗑️]
│    NEP: NEP-1.1, NEP-1.2 | Topics Mapped: 3 | Status: Active
│   ▶ COMP-ENG-003: Parts of Speech (SKILL)          [+ Add Child] [✏️] [🗑️]
│      NEP: NEP-1.1 | Topics Mapped: 2
│   ▶ COMP-ENG-004: Tenses (SKILL)                   [+ Add Child] [✏️] [🗑️]
│      NEP: NEP-1.2 | Topics Mapped: 1
│
│ ▼ COMP-ENG-002: Communication (SKILL)               [+ Add Child] [✏️] [🗑️]
│    NEP: NEP-2.1 | Topics Mapped: 2 | Status: Active
│   ▶ COMP-ENG-005: Listening (SKILL)               [+ Add Child] [✏️] [🗑️]
│      NEP: NEP-2.1 | Topics Mapped: 1
│   ▶ COMP-ENG-006: Speaking (SKILL)                [+ Add Child] [✏️] [🗑️]
│      NEP: NEP-2.2 | Topics Mapped: 1
│
│ [+ New Competency]                               [Save Changes]
│
└────────────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Create / Edit Competency Modal
**Route:** `POST /api/v1/competencies` | `PUT /api/v1/competencies/{id}`

#### 2.3.1 Layout

```
┌──────────────────────────────────────────────────────────────┐
│ CREATE NEW COMPETENCY                               [✕]      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ Class (optional)        [Select Class ▼]                    │
│ (Leave empty for framework-level competency)                │
│                                                              │
│ Subject (optional)      [Select Subject ▼]                  │
│ (Auto-filtered by class; leave empty for all subjects)     │
│                                                              │
│ Code *                  [COMP-ENG-001]                      │
│ (Unique per class-subject)                                  │
│ [☐ Auto-generate]                                           │
│                                                              │
│ Name *                  [________________]                   │
│ (Max 200 chars, e.g., "Grammar Mastery")                   │
│                                                              │
│ Parent Competency       [Select Parent ▼]                   │
│ (optional, shows hierarchy)                                 │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ • Grammar Mastery (SKILL)                            │   │
│ │  ├─ Parts of Speech (SKILL)                         │   │
│ │  └─ Tenses (SKILL)                                  │   │
│ │ • Communication (SKILL)                              │   │
│ │  ├─ Listening (SKILL)                               │   │
│ │  └─ Speaking (SKILL)                                │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                              │
│ Competency Type *       [Select Type ▼]                     │
│ (KNOWLEDGE / SKILL / ATTITUDE)                             │
│                                                              │
│ NEP Alignment           [Multi-select ▼]                    │
│ (E.g., NEP-1.1, NEP-2.1)                                   │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ ✓ NEP-1.1  ✓ NEP-1.2  ☐ NEP-2.1  ☐ NEP-3.1        │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                              │
│ Description             [________________]                   │
│ (Optional, supports markdown)                               │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ Ability to understand and apply correct grammar     │   │
│ │ in written and spoken English language             │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                              │
│ Metadata (JSON)         [________________]                   │
│ (Optional, for integrations)                                │
│                                                              │
│ Is Active               [☑] Enable this competency         │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│            [Cancel]  [Save]  [Save & New]                   │
└──────────────────────────────────────────────────────────────┘
```

#### 2.3.2 Field Specifications

| Field | Type | Validation | Placeholder | Required |
|-------|------|------------|-------------|----------|
| Class | Dropdown | FK to sch_classes, nullable | "All classes" | ✗ |
| Subject | Dropdown | FK to sch_subjects, filtered | "All subjects" | ✗ |
| Code | Text Input | Max 50 chars, unique per (class, subject), alphanumeric | "COMP-ENG-001" | ✓ |
| Name | Text Input | Max 200 chars, unique per (class, subject) | "e.g., Grammar Mastery" | ✓ |
| Parent Competency | Tree Picker | Self-FK, no cycles | "None (root)" | ✗ |
| Competency Type | Dropdown | Enum: KNOWLEDGE, SKILL, ATTITUDE | "Select Type" | ✓ |
| NEP Alignment | Multi-select | JSON array of codes | "Select tags" | ✗ |
| Description | TextArea | Max 2000 chars, markdown | "Description..." | ✗ |
| Metadata | JSON Input | Valid JSON object | "{}" | ✗ |
| Is Active | Toggle | Boolean | Checked | ✗ |

#### 2.3.3 Validation Rules

```
✓ Code is required
  - Max length: 50 characters
  - Unique within (class_id, subject_id)
  - Alphanumeric and hyphens allowed
  - Error: "Code must be unique for selected class and subject"
✓ Name is required
  - Max length: 200 characters
  - Error: "Competency name is required"
✓ Competency Type is required
  - Must be KNOWLEDGE, SKILL, or ATTITUDE
✓ Parent Competency is optional
  - If selected, cannot be self
  - Cannot be a descendant (prevent cycles)
  - Error: "Cannot create cycle"
✓ Class/Subject are optional
  - If parent competency selected, inherit or allow cross-subject with warning
✓ NEP Alignment is optional
  - Multiple tags allowed
  - Validates against NEP taxonomy
✓ Description is optional
  - Max 2000 characters
✓ Metadata is optional
  - Must be valid JSON if provided
```

#### 2.3.4 Error Handling

```
Error Scenarios:
1. Duplicate Code
   Message: "Code must be unique for selected class and subject"
   Suggestion: "Available codes: [COMP-ENG-004, COMP-ENG-005]"

2. Parent is Descendant
   Message: "Cannot create cycle: parent cannot be a child of this competency"

3. Missing Required Fields
   Message: "[Code] is required"
   Action: Highlight field, disable Save button

4. Invalid JSON in Metadata
   Message: "Metadata must be valid JSON"
   Example: Show valid format hint

5. Network Error
   Message: "Failed to save competency. Please try again."
   Action: Auto-retry, manual Retry button
```

#### 2.3.5 Smart Features
- **Auto-code Generation:** Click [☐ Auto-generate] to generate code from name + class/subject
  - Example: Class="9th", Subject="English", Name="Grammar" → "COMP-ENG-001"
- **Duplicate:** Offer "Duplicate" button in detail view to copy competency
- **Save & New:** After save, stays in modal for bulk creation

---

### 2.4 Competency Detail Panel (Right-side)
**Route:** `/curriculum/competencies/{id}`

#### 2.4.1 Layout (Tabbed Interface)

```
┌──────────────────────────────────────────────────────────────┐
│ COMPETENCY DETAIL > Grammar Mastery         [Edit] [More]    │
├──────────────────────────────────────────────────────────────┤
│ [Overview] [Topics Mapped] [Student Outcomes] [Activity Log] │
├──────────────────────────────────────────────────────────────┤
│
│ TAB 1: OVERVIEW
│ ─────────────────────────────────────────────────────────────
│ Code:                       COMP-ENG-001
│ Competency Name:            Grammar Mastery
│ Competency Type:            SKILL (Green badge)
│ Status:                     ✓ Active
│ Class:                      9th Standard (or All)
│ Subject:                    English (or All)
│ Parent Competency:          None (Root)
│ NEP Alignment:              NEP-1.1, NEP-1.2
│ Topics Mapped:              3 topics
│ Description:
│   Ability to understand and apply correct grammar in written
│   and spoken English language, including parts of speech,
│   tenses, and sentence structure.
│
│ Created By:                 Curriculum Manager
│ Created Date:               2024-12-01
│ Last Modified By:           Curriculum Manager
│ Last Modified Date:         2024-12-08
│
│ [Edit] [Duplicate] [Archive]
│
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ TAB 2: TOPICS MAPPED
│ ─────────────────────────────────────────────────────────────
│ Total Topics Mapped: 3
│
│ ☐ │ Topic Name      │ Lesson        │ Class | Subject │ Status │
│ ───┼─────────────────┼───────────────┼───────┼─────────┼────────│
│ ☐ │ Grammar Basics  │ Lesson 1      │ 9th   │ English │ Active │
│ ☐ │ Parts of Speech │ Lesson 1      │ 9th   │ English │ Active │
│ ☐ │ Verb Tenses     │ Lesson 1      │ 9th   │ English │ Active │
│
│ [+ Add Topic] [Unlink Selected] [View All Topics in Bank]
│
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ TAB 3: STUDENT OUTCOMES & ANALYTICS
│ ─────────────────────────────────────────────────────────────
│ Mastery Statistics:
│   Master: 45% | Proficient: 35% | Developing: 15% | Beginning: 5%
│
│ Student Performance by Class:
│ ┌─────────────────┬──────────────┬──────────────┐
│ │ Class           │ Avg Mastery  │ Student Count│
│ ├─────────────────┼──────────────┼──────────────┤
│ │ 9A (Section 1)  │ 75.5%        │ 35 students  │
│ │ 9B (Section 2)  │ 68.2%        │ 32 students  │
│ │ 9C (Section 3)  │ 72.1%        │ 38 students  │
│ └─────────────────┴──────────────┴──────────────┘
│
│ [Export Report] [View Detailed Analytics]
│
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ TAB 4: ACTIVITY LOG
│ ─────────────────────────────────────────────────────────────
│ 2024-12-08 14:30 | Manager | Mapped to Topic 1003           │
│ 2024-12-07 10:15 | Manager | Updated | NEP Alignment       │
│ 2024-12-01 09:00 | Manager | Created | Grammar Mastery     │
│
│ [Download Log] [Filter by Action ▼]
│
└──────────────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Competency Request
```json
POST /api/v1/competencies
{
  "code": "COMP-ENG-001",
  "name": "Grammar Mastery",
  "class_id": 9,
  "subject_id": 5,
  "parent_competency_id": null,
  "competency_type": "SKILL",
  "nep_alignment": ["NEP-1.1", "NEP-1.2"],
  "description": "Ability to understand and apply correct grammar...",
  "metadata": {"custom_field": "value"},
  "is_active": true
}
```

### 3.2 Create Competency Response
```json
{
  "success": true,
  "data": {
    "id": 501,
    "code": "COMP-ENG-001",
    "name": "Grammar Mastery",
    "class_id": 9,
    "subject_id": 5,
    "parent_competency_id": null,
    "competency_type": "SKILL",
    "nep_alignment": ["NEP-1.1", "NEP-1.2"],
    "description": "...",
    "is_active": true,
    "created_at": "2024-12-09T10:30:00Z",
    "updated_at": "2024-12-09T10:30:00Z"
  },
  "message": "Competency created successfully"
}
```

### 3.3 List Competencies Request
```
GET /api/v1/competencies?class_id=9&subject_id=5&type=SKILL&status=active&page=1&limit=10
```

### 3.4 Get Competency Detail Request
```
GET /api/v1/competencies/{id}?include=children,topics,outcomes,activity
```

### 3.5 Update Competency Request
```json
PUT /api/v1/competencies/{id}
{
  "name": "Grammar Mastery",
  "nep_alignment": ["NEP-1.1", "NEP-1.2", "NEP-2.1"],
  "is_active": true
}
```

### 3.6 Bulk Map Topics to Competency
```json
POST /api/v1/competencies/{id}/map-topics
{
  "topic_ids": [1001, 1002, 1003],
  "options": {"overwrite": false}
}
```

### 3.7 Delete Competency Request
```
DELETE /api/v1/competencies/{id}

// Response
{
  "success": true,
  "message": "Competency deleted successfully",
  "data": {
    "id": 501,
    "deleted_at": "2024-12-09T11:00:00Z"
  }
}
```

---

## 4. USER WORKFLOWS

### 4.1 Create Competency Workflow
```
1. User clicks [+ New Competency]
2. Create Modal opens
3. User selects Class (optional): 9th Standard
4. Subject auto-filters: English
5. User enters Code: COMP-ENG-001 (or clicks Auto-generate)
6. User enters Name: "Grammar Mastery"
7. User selects Type: SKILL
8. User selects NEP Alignment: NEP-1.1, NEP-1.2
9. User enters Description
10. User clicks [Save]
11. Form validates all fields
12. If valid:
    → POST /api/v1/competencies
    → Show success toast
    → Modal closes, list refreshes
13. If invalid:
    → Show inline errors
    → User corrects and retries
```

### 4.2 Create Child Competency Workflow
```
1. User is viewing Competency detail (Grammar Mastery)
2. Clicks [+ Add Child] or [+ New Competency] in tree
3. Modal opens with:
   - Parent Competency: Grammar Mastery (pre-filled)
   - Class/Subject: inherited from parent
4. User enters:
   - Code: COMP-ENG-003
   - Name: "Parts of Speech"
   - Type: SKILL
5. User clicks [Save]
6. POST /api/v1/competencies with parent_competency_id = 501
7. Tree updates, parent node expands
8. New child highlighted
```

### 4.3 Map Topics to Competency Workflow
```
1. User is viewing Competency detail
2. Clicks [Topics Mapped] tab
3. Sees current mapped topics
4. Clicks [+ Add Topic]
5. Topic search modal opens
6. User searches for topic: "Grammar Basics"
7. User selects topic from dropdown
8. Topic appears in preview
9. User clicks [Map]
10. POST /api/v1/competencies/{id}/map-topics with topic_id
11. UI updates, show success toast
12. Topic appears in Topics Mapped list
```

### 4.4 Bulk Import Competencies Workflow (via CSV)
```
1. User clicks [⋯ Bulk Actions] → Import Competencies
2. CSV upload modal opens
3. User selects CSV file with format:
   code,name,parent_code,class_id,subject_id,type,nep_tags,description
4. System parses and shows preview:
   - Matched rows (green ✓)
   - Unmatched parent codes (red ✗) with manual resolution options
5. User resolves conflicts (map parent codes or skip)
6. User clicks [Confirm Import]
7. Background job starts, returns job_id
8. UI shows job progress: "Processing... (15/45 completed)"
9. On completion, show report:
   - Successfully imported: 42
   - Failed: 3 (reasons shown)
10. User can export failed rows for correction
```

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Type Badges & Colors
| Type | Color | Font Color |
|------|-------|-----------|
| KNOWLEDGE | #93C5FD (Light Blue) | #1E40AF (Dark Blue) |
| SKILL | #86EFAC (Light Green) | #166534 (Dark Green) |
| ATTITUDE | #FBBF24 (Light Amber) | #B45309 (Dark Amber) |

### 5.2 Typography & Spacing
- **Page Padding:** 24px
- **Section Spacing:** 16px
- **Form Field Spacing:** 12px
- **Button Spacing:** 8px
- **Modal Padding:** 24px

### 5.3 Icons
- **New:** ➕ Plus
- **Edit:** ✏️ Pencil
- **Delete:** 🗑️ Trash
- **Map:** 🔗 Link
- **Unmap:** 🔓 Unlink
- **Import:** ⬆️ Upload
- **Export:** ⬇️ Download

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 Keyboard Navigation
- **Tab:** Navigate form fields and buttons
- **Enter/Space:** Activate buttons, toggle selections
- **Escape:** Close modals
- **Arrow Keys:** Navigate tree, dropdowns
- **Ctrl+S:** Save form

### 6.2 ARIA Labels & Screen Readers
```html
<input id="comp-name" aria-label="Competency Name (required)" aria-required="true" />
<button aria-label="Add child competency">➕</button>
<ul role="tree" aria-label="Competency hierarchy">...</ul>
```

### 6.3 Validation & Error Messages
- Required fields marked with red asterisk (*)
- Error messages below field in red (#EF4444)
- Field border turns red on error
- Errors prevent form submission

---

## 7. PERFORMANCE CONSIDERATIONS

### 7.1 Data Optimization
- **List:** Server-side pagination (10/25/50/100 per page)
- **Tree:** Lazy-load children on expand
- **Topics Tab:** Pagination, 10 per page
- **Analytics:** Cache results (5-minute TTL)

### 7.2 Caching Strategy
- Cache dropdowns (class/subject list, NEP codes) – TTL: 1 hour
- Cache competency detail – TTL: 5 minutes
- Invalidate on create/edit/delete

### 7.3 API Rate Limiting
- List: 60 req/min
- Create/Update: 30 req/min
- Map/Unmap: 30 req/min
- Delete: 10 req/min

---

## 8. TESTING CHECKLIST

### 8.1 Functional Testing
- [ ] Create competency with all fields
- [ ] Create child competency with parent prefilled
- [ ] Edit competency successfully
- [ ] Delete competency (with/without mapped topics)
- [ ] Prevent cycles (cannot use child as parent)
- [ ] Map topics to competency
- [ ] Unmap topics from competency
- [ ] Filter competencies by type, status, NEP alignment
- [ ] Search competencies by code/name
- [ ] View competency detail with all tabs
- [ ] Validate duplicate code error
- [ ] Auto-code generation works

### 8.2 UI/UX Testing
- [ ] Responsive layout (mobile/tablet/desktop)
- [ ] Modal opens/closes smoothly
- [ ] Tree expand/collapse works
- [ ] Type badges display with correct colors
- [ ] Form validation shows errors inline
- [ ] Buttons disabled during submission
- [ ] Toast notifications appear/disappear

### 8.3 Accessibility Testing
- [ ] Keyboard navigation works
- [ ] Screen reader announces labels/errors
- [ ] Color contrast meets WCAG AA
- [ ] Focus order is logical

### 8.4 Integration Testing
- [ ] API calls match contract
- [ ] Error responses handled gracefully
- [ ] Competency counts reflect mapped topics
- [ ] Activity log populated correctly

---

## 9. FUTURE ENHANCEMENTS

1. **CSV Import:** Bulk import competencies with parent path notation
2. **Competency Templates:** Pre-built competency frameworks for subjects
3. **ML Suggestions:** Auto-suggest competency grouping and hierarchy
4. **Real-time Collaboration:** Multiple users editing simultaneously
5. **Mastery Analytics:** Visualize student mastery trends by competency
6. **Competency Gaps:** Identify unmapped competencies and weak coverage
7. **Attachments:** Upload resources and references to competencies
8. **Competency Alignment:** Map to external frameworks (IB, Cambridge, etc.)
9. **API Integration:** Import competencies from national/state curriculum databases
10. **Proficiency Levels:** Define proficiency descriptors (Beginning, Developing, Proficient, Master)

---

## Appendix A: Component Library References

| Component | Library | Notes |
|-----------|---------|-------|
| Dropdown | Headless UI / Chakra | Multi-select, search, filter |
| Modal | Headless UI / Radix | Accessible, customizable |
| Input | Tailwind / Material UI | Text, number, textarea |
| Button | Tailwind / Chakra | Primary, secondary, danger |
| Table | TanStack Table | Sortable, filterable, paginated |
| Tree | React Beautiful Tree | Hierarchical, drag-drop |
| Toast | React Hot Toast | Auto-dismiss |

---

**Document Created By:** Database Architect  
**Last Reviewed:** December 10, 2025  
**Version Control:** Git repository

