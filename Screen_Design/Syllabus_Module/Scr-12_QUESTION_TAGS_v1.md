# Screen Design Specification: Question Tags Management
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Question Tags Management Module**, enabling creation and management of keywords and labels for questions. Tags facilitate searching, filtering, and organization of large question banks across multiple dimensions (topics, standards, curriculum references, learning objectives).

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

**Database Tables:**
1. sch_question_tags
   ├── id (BIGINT PRIMARY KEY)
   ├── short_name (VARCHAR 100, UNIQUE) - e.g., 'biology', 'photosynthesis'
   ├── name (VARCHAR 255) - Display name
   └── Tag examples: Chapter references, Learning objectives, Difficulty descriptors

2. sch_question_tag_jnt
   ├── question_id (FK to sch_questions)
   ├── tag_id (FK to sch_question_tags)
   └── Allows many-to-many relationship

**Related Tables:**
- sch_questions → Tagged questions
- sch_question_pools → Filter by tags

---

## 2. SCREEN LAYOUTS

### 2.1 Question Tags List Screen
**Route:** `/curriculum/settings/question-tags`

#### 2.1.1 Layout
```
┌────────────────────────────────────────────────────────────────────────────┐
│ ASSESSMENT SETTINGS > QUESTION TAGS                                        │
├────────────────────────────────────────────────────────────────────────────┤
│ [Search Tags __________________] [+ New Tag]  [Import] [Export]           │
├────────────────────────────────────────────────────────────────────────────┤
│ Sort by: [Alphabetical ▼] Usage: [All ▼] Status: [All ▼]                 │
├────────────────────────────────────────────────────────────────────────────┤
│ TAG CLOUD VIEW (Popular tags larger):
│
│         ┌──────────┐  ┌────────┐  ┌──────────────┐
│         │ Biology  │  │ NCERT  │  │ Photosynthesis│
│         │  (542 Qs)│  │(387Qs) │  │   (234 Qs)    │
│         └──────────┘  └────────┘  └──────────────┘
│     ┌─────────┐  ┌──────────────┐  ┌──────────┐
│     │Revision │  │ Challenging  │  │ Practice │
│     │(298 Qs) │  │  (156 Qs)    │  │ (187 Qs) │
│     └─────────┘  └──────────────┘  └──────────┘
│
├────────────────────────────────────────────────────────────────────────────┤
│ TAG LIST VIEW
│ ☐ │ Tag Name         │ Short Name      │ Questions │ Created │ Actions  │
│────┼──────────────────┼─────────────────┼───────────┼─────────┼──────────│
│ ☐ │ Biology          │ biology         │   542     │ 2024-01 │ ⋯ Menu   │
│ ☐ │ NCERT            │ ncert           │   387     │ 2024-01 │ ⋯ Menu   │
│ ☐ │ Photosynthesis   │ photosynthesis  │   234     │ 2024-01 │ ⋯ Menu   │
│ ☐ │ Revision         │ revision        │   298     │ 2024-02 │ ⋯ Menu   │
│
│ [Download Tag Cloud] [Merge Tags] [Bulk Update]
│
└────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components

**Tag Cloud View:**
- Visual representation with font size = usage frequency
- Click tag → Filter questions with this tag
- Hover → Show question count

**List View:**
- Sortable columns: Name, Short Name, Question Count, Created Date
- Search by tag name (real-time)
- Filter by usage frequency

**Buttons:**
- **[+ New Tag]** – Create new tag
- **[Merge Tags]** – Combine similar tags
- **[Bulk Update]** – Change tags on multiple questions

---

### 2.2 Create/Edit Tag Modal
**Route:** `POST /curriculum/settings/question-tags` or `PATCH /{tagId}`

#### 2.2.1 Layout
```
┌──────────────────────────────────────────────────┐
│ NEW QUESTION TAG                            [✕]  │
├──────────────────────────────────────────────────┤
│                                                  │
│ Tag Name *            [__________________]       │
│ (Display name, e.g., "Photosynthesis")           │
│                                                  │
│ Short Name *          [__________________]       │
│ (Unique, lowercase, e.g., "photosynthesis")      │
│                                                  │
│ Description           [__________________]       │
│                       [                        ]│
│ (Optional, for reference)                        │
│                                                  │
│ Category              [General ▼]                │
│ (Optional grouping)   Options: Biology, Physics, │
│                                Chemistry, etc.   │
│                                                  │
│ Color                 [Green █] (for cloud view) │
│                                                  │
├──────────────────────────────────────────────────┤
│              [Cancel]  [Save]  [Save & New]     │
└──────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Tag Request
```json
POST /api/v1/question-tags
{
  "name": "Photosynthesis",
  "short_name": "photosynthesis",
  "description": "Questions related to photosynthesis process",
  "category": "Biology"
}
```

### 3.2 Create Response
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Photosynthesis",
    "short_name": "photosynthesis",
    "description": "Questions related to photosynthesis process",
    "question_count": 234,
    "created_at": "2024-12-10T10:00:00Z"
  },
  "message": "Tag created successfully"
}
```

### 3.3 List Tags Request
```
GET /api/v1/question-tags?sort=question_count:desc&limit=50
```

### 3.4 List Response
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Biology",
      "short_name": "biology",
      "question_count": 542,
      "category": "Science"
    }
  ],
  "pagination": {
    "total": 145,
    "page": 1,
    "limit": 50
  }
}
```

---

## 4. USER WORKFLOWS

### 4.1 Create New Tag Workflow
**Goal:** Create a new tag for organizing questions

1. Navigate to **Settings > Question Tags**
2. Click **[+ New Tag]**
3. Enter Tag Name (e.g., "Photosynthesis")
4. Auto-generates Short Name (e.g., "photosynthesis")
5. Optionally select Category
6. Click **[Save]**
7. Tag available for tagging questions

---

### 4.2 Tag a Question Workflow
**Goal:** Add tags to a question

1. Open Question detail
2. Scroll to Tags section
3. Click **[+ Add Tag]**
4. Autocomplete dropdown shows existing tags
5. Select "Photosynthesis", "Biology", "NCERT"
6. View selected tags as removable chips
7. Click **[Save Question]**
8. Tags saved and searchable

---

### 4.3 Search Questions by Tag Workflow
**Goal:** Find all questions with specific tag

1. Navigate to Question Bank list
2. Click on a tag (from cloud view or list)
3. System filters: Shows only questions with that tag
4. View filtered question list
5. Further filter by Bloom, Complexity if needed
6. Export question set
7. Assign to assessment

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Color Coding
- Tag clouds: Frequency → Font size
- Tags in questions: Colored badges (green, blue, orange)
- Hover effect: Slight background highlight

### 5.2 Typography
- Tag name: Bold, 14px
- Tag count: Light gray, 12px
- Short name: Monospace, 11px

---

## 6. TESTING CHECKLIST

### 6.1 Functional Testing
- [ ] Create new tag with unique short name
- [ ] Edit tag name and description
- [ ] Delete tag (verify reassignment)
- [ ] Search tags by name
- [ ] Filter questions by tag
- [ ] Add multiple tags to question
- [ ] Remove tag from question
- [ ] Merge similar tags
- [ ] Tag cloud renders correctly
- [ ] Cloud click filters questions
- [ ] Export tagged question list
- [ ] Import tags from CSV

### 6.2 UI/UX Testing
- [ ] Cloud view shows size variation
- [ ] List view sorts correctly
- [ ] Modal form validates
- [ ] Autocomplete suggestions appear
- [ ] Tag chips removable
- [ ] Responsive on mobile

### 6.3 Integration Testing
- [ ] Create tag → Available in question form
- [ ] Tag question → Counted in tag statistics
- [ ] Delete tag → Questions lose tag
- [ ] Search by tag works
- [ ] Filter persists across views

---

## 7. FUTURE ENHANCEMENTS

- **Tag Hierarchy:** Parent-child tag relationships
- **AI Tag Suggestion:** Auto-suggest tags from question content
- **Tag Analytics Dashboard:** Popular tags, usage trends
- **Collaborative Tagging:** Multiple teachers creating tags
- **Multi-language Tags:** Same tag in multiple languages
- **Tag Synonyms:** Treat similar tags as equivalent
- **Permission-Based Tags:** Tags visible to specific roles
- **Tag Autocomplete Improvement:** ML-based suggestions

