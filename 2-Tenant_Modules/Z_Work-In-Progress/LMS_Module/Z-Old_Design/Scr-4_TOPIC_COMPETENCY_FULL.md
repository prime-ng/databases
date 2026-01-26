# Screen Design Specification: Topic-Competency Mapping Module
## Document Version: 2.0 (Full Page Layouts)
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Topic-Competency Mapping Module**, enabling curriculum managers to link Topics (`slb_topics`) to Competencies (`slb_competencies`) via the join table `slb_topic_competency_jnt`. Covers mapping dashboard, bulk operations, CSV import/export, job management, analytics, and integrations.

### 1.2 User Roles & Permissions
| Role               | Map | Unmap | Bulk Map | CSV Import | CSV Export | Analytics | Audit |
|--------------------|-----|-------|----------|------------|------------|-----------|-------|
| Super Admin        |  ✓  |   ✓   |    ✓     |      ✓     |      ✓     |     ✓     |   ✓   |
| School Admin       |  ✓  |   ✓   |    ✓     |      ✗     |      ✗     |     ✓     |   ✗   |
| Curriculum Manager |  ✓  |   ✓   |    ✓     |      ✓     |      ✓     |     ✓     |   ✓   |
| Teacher            |  ✓  |   ✗   |    ✗     |      ✗     |      ✗     |     ✓     |   ✗   |
| QA / Auditor       |  ✗  |   ✗   |    ✗     |      ✗     |      ✗     |     ✓     |   ✓   |

### 1.3 Data Context

Database Table: slb_topic_competency_jnt
├── topic_id (FK to slb_topics, part of PK)
├── competency_id (FK to slb_competencies, part of PK)
├── mapped_by (User ID)
├── mapped_at (Timestamp)
├── mapping_source (ENUM: UI, CSV, API, ML)
├── notes (TEXT, optional)
└── Primary Key: (topic_id, competency_id)

---

## 2. SCREEN LAYOUTS

### 2.1 Mapping Dashboard (Primary)
**Route:** `/curriculum/mappings/topics-competencies`

#### 2.1.1 Page Layout (Three-Column)


┌────────────────────────────────────────────────────────────────────────────────────┐
│ CURRICULUM MAPPINGS > TOPICS ↔ COMPETENCIES                                        │
├────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                    │
│ ┌─────────────────────────┬────────────────────┬──────────────────────────────┐    │
│ │ TOPIC SELECTOR          │ ACTIONS            │ COMPETENCY SELECTOR          │    │
│ │ (Left Pane)             │ (Middle)           │ (Right Pane)                 │    │
│ ├─────────────────────────┼────────────────────┼──────────────────────────────┤    │
│ │                         │                    │                              │    │
│ │ CLASS: [9th ▼]          │                    │ TYPE: [All ▼]                │    │
│ │ SUBJECT: [English ▼]    │   SELECTED:        │ NEP: [Select ▼]              │    │
│ │ LESSON: [Lesson 1 ▼]    │   Topics: 2        │ STATUS: [Active ▼]           │    │
│ │ SEARCH: [________]      │   Competencies: 1  │ SEARCH: [________]           │    │
│ │                         │                    │                              │    │
│ │ ▼ Grammar Basics (0)    │   [Map →]          │ ▼ SKILL (12)                 │    │
│ │ ├─ Parts of Speech (✓)  │                    │  • Grammar Mastery (✓)       │    │
│ │ ├─ Verb Tenses (✓)      │   [← Unmap]        │  • Parts of Speech (✓)       │    │
│ │ └─ Sentence Structure    │                    │  • Listening Skills         │    │
│ │                         │   [Import CSV]     │  • Speaking Skills           │    │
│ │ Comprehension (0)       │   [Export CSV]     │                              │    │
│ │ ├─ Reading Practice     │   [Analytics]      │ ▶ KNOWLEDGE (8)              │    │
│ │ └─ Listening Skills     │                    │                              │    │
│ │                         │                    │ ▶ ATTITUDE (5)               │    │
│ │                         │                    │                              │    │
│ │ [Tree View]             │                    │ [Selected Competencies:      │    │
│ │ [+ New Topic]           │                    │  • Grammar Mastery]          │    │
│ │                         │                    │                              │    │
│ └─────────────────────────┴────────────────────┴──────────────────────────────┘    │
│                                                                                    │
│ MAPPING PREVIEW PANEL (Below)                                                      │
│ ┌─────────────────────────────────────────────────────────────────────────────┐    │
│ │ Current Mappings for Selected Items:                                        │    │
│ │                                                                             │    │
│ │ Topic: Grammar Basics (Lesson 1)                                            │    │
│ │ └─ Mapped Competencies: Grammar Mastery, Parts of Speech                    │    │
│ │                                                                             │    │
│ │ Topic: Parts of Speech (Lesson 1)                                           │    │
│ │ └─ Mapped Competencies: Grammar Mastery, Parts of Speech                    │    │
│ │                                                                             │    │
│ │ Competency: Grammar Mastery                                                 │    │
│ │ └─ Mapped Topics: Grammar Basics, Parts of Speech, Verb Tenses              │    │
│ └─────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                    │
│ MAPPING SUMMARY (Bottom)                                                           │
│ Total Mappings: 15 | Topics Mapped: 8/12 | Competencies Mapped: 18/25              │
│ Coverage: 67% | Gaps: 4 topics unmapped | Unused: 7 competencies                   │
│                                                                                    │
└────────────────────────────────────────────────────────────────────────────────────┘


#### 2.1.2 Components & Interactions

**Left Pane (Topic Selector):**
- **Filters:** Class, Subject, Lesson, Status
- **Search:** Real-time search by topic name
- **Display:** Hierarchical tree or list view toggle
- **Selection:** Checkbox for multi-select topics
- **Selected count:** Badge showing "2 selected"
- **Buttons:** [Tree View] [+ New Topic]

**Middle Pane (Actions):**
- **Selected Display:** Shows count of selected topics and competencies
- **Action Buttons:**
  - `[Map →]` – Creates mappings (enabled when both sides selected)
  - `[← Unmap]` – Removes mappings (enabled when mappings exist)
  - `[Undo]` – Reverts last mapping action (5-10 second window)
- **Bulk Operations:**
  - `[Import CSV]` – CSV upload for bulk mapping
  - `[Export CSV]` – Download current mappings
  - `[Analytics]` – Show coverage metrics and gaps
- **Job Status:** Shows "Processing... (15/45)" if bulk job running

**Right Pane (Competency Selector):**
- **Filters:** Type (Knowledge/Skill/Attitude), NEP Alignment, Status
- **Search:** Real-time search by competency code/name
- **Display:** Hierarchical tree or flat list toggle
- **Selection:** Checkbox for multi-select competencies
- **Color-coded types:** Blue=Knowledge, Green=Skill, Amber=Attitude
- **Buttons:** [+ New Competency]

**Mapping Preview Panel (Below all panes):**
- Shows current mappings for selected topic/competency
- Live updates when selection changes
- Displays direction (Topic → Competencies or Competency → Topics)

**Summary Bar (Bottom):**
- Total mapping count, coverage percentage
- Counts: topics with mappings, competencies with mappings
- Gap analysis: unmapped topics/competencies count

---

### 2.2 Topic Detail → Competencies Tab (Embedded Mapping)
**Route:** `/curriculum/lessons/{lessonId}/topics/{topicId}`

#### 2.2.1 Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│ TOPIC DETAIL > Grammar Basics                          [Edit] [More] │
├──────────────────────────────────────────────────────────────────────┤
│ [Overview] [Sub-Topics] [Questions] [Competencies] [Activity]        │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      |
│ TAB: COMPETENCIES (Linked Competencies)                              |
│ ─────────────────────────────────────────────────────────────────────|
│ Mapped Competencies: 3                                               |
│                                                                      |
│ ☐ │ Code          │ Competency Name      │ Type   │ Mapped │ Actions │
│ ──┼───────────────┼──────────────────────┼────────┼────────┼─────────│
│ ☐ │ COMP-ENG-001  │ Grammar Mastery      │ SKILL  │ Today  │ View ✕  │
│ ☐ │ COMP-ENG-003  │ Parts of Speech      │ SKILL  │ Dec 8  │ View ✕  │
│ ☐ │ COMP-ENG-004  │ Tenses               │ SKILL  │ Dec 7  │ View ✕  │
│
│ [+ Add Competency] [Unmap Selected] [View All in Bank]
│
│ Quick Map:
│ Search: [_________________]  [Search]
│ Suggestions: Grammar Mastery (already mapped) | Writing Skills | ...
│
└──────────────────────────────────────────────────────────────────────┘
```

**Behaviors:**
- Click [+ Add Competency] → Competency search modal opens
- Type to search, see typeahead suggestions (showing mapped status)
- Select competency → Maps immediately with success toast
- Click ✕ on row → Unmap with confirmation

---

### 2.3 Competency Detail → Topics Tab (Embedded Mapping)
**Route:** `/curriculum/competencies/{id}`

#### 2.3.1 Layout

```
┌──────────────────────────────────────────────────────────────┐
│ COMPETENCY DETAIL > Grammar Mastery    [Edit] [More]        │
├──────────────────────────────────────────────────────────────┤
│ [Overview] [Topics Mapped] [Student Outcomes] [Activity Log] │
├──────────────────────────────────────────────────────────────┤
│
│ TAB: TOPICS MAPPED
│ ─────────────────────────────────────────────────────────────
│ Total Topics Mapped: 3
│
│ ☐ │ Topic Name      │ Lesson    │ Class │ Subject │ Mapped │ Actions│
│ ───┼─────────────────┼───────────┼───────┼─────────┼────────┼────────│
│ ☐ │ Grammar Basics  │ Lesson 1  │ 9th   │ English │ Today  │ View ✕ │
│ ☐ │ Parts of Speech │ Lesson 1  │ 9th   │ English │ Dec 8  │ View ✕ │
│ ☐ │ Verb Tenses     │ Lesson 1  │ 9th   │ English │ Dec 7  │ View ✕ │
│
│ [+ Map Topics] [Unmap Selected] [Bulk Map via CSV]
│
└──────────────────────────────────────────────────────────────┘
```

---

### 2.4 CSV Import Modal
**Route:** POST `/api/v1/mappings/import`

#### 2.4.1 Layout

```
┌──────────────────────────────────────────────────────────────┐
│ BULK IMPORT MAPPINGS (via CSV)                         [✕]   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ STEP 1: UPLOAD FILE                                         │
│ ─────────────────────────────────────────────────────────────
│ [Choose File] or Drag & Drop CSV here                       │
│ ⬆️ mapping_import.csv (125 KB)                              │
│                                                              │
│ Expected Format:                                            │
│ topic_code,topic_name,competency_code,competency_name,...  │
│                                                              │
│ [Click to download template]                               │
│                                                              │
│ STEP 2: PREVIEW & RESOLVE                                   │
│ ─────────────────────────────────────────────────────────────
│ Parsing... 42/45 rows processed                             │
│                                                              │
│ ✓ 40 rows matched successfully                              │
│ ⚠️  2 rows with warnings (unmatched parent codes)           │
│ ✕ 3 rows with errors (invalid format)                       │
│                                                              │
│ [Matched Rows] [Warnings] [Errors]  ← Tabs                 │
│                                                              │
│ Warnings Tab:                                               │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ Row 23: Topic "Grammar Basics" not found             │   │
│ │ Action: [Ignore] [Map to: ___________]              │   │
│ │                                                      │   │
│ │ Row 35: Competency "COMP-ENG-999" not found         │   │
│ │ Action: [Ignore] [Map to: ___________]              │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                              │
│ STEP 3: CONFIRM & IMPORT                                    │
│ ─────────────────────────────────────────────────────────────
│ ☑ Overwrite existing mappings                              │
│ ☐ Send notification on completion                          │
│                                                              │
│ Summary: Will import 40 mappings, skip 2, ignore 3          │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│          [Cancel]  [← Back]  [Import →]                     │
└──────────────────────────────────────────────────────────────┘
```

---

### 2.5 CSV Export Modal
**Route:** GET `/api/v1/mappings/export`

#### 2.5.1 Layout

```
┌──────────────────────────────────────────────────────────────┐
│ BULK EXPORT MAPPINGS (as CSV)                         [✕]   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ Export Options:                                             │
│                                                              │
│ ☑ Include all mappings (1,245 rows)                        │
│ ☐ Filter by Class: [9th Standard ▼]                       │
│ ☐ Filter by Subject: [English ▼]                          │
│ ☐ Filter by Competency Type: [SKILL ▼]                   │
│ ☐ Include mapping metadata (mapped_by, mapped_at, source) │
│                                                              │
│ Output Format:                                              │
│ ☑ CSV (Comma-separated)                                    │
│ ☐ Excel (XLSX)                                             │
│ ☐ JSON                                                      │
│                                                              │
│ File Name: mapping_export_2024-12-10.csv                    │
│                                                              │
│ Preview (first 5 rows):                                     │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ topic_code,topic_name,competency_code,...            │   │
│ │ ENG-1-001,Grammar Basics,COMP-ENG-001,...            │   │
│ │ ENG-1-002,Parts of Speech,COMP-ENG-001,...           │   │
│ │ ...                                                   │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                [Cancel]  [Download]                         │
└──────────────────────────────────────────────────────────────┘
```

---

### 2.6 Bulk Job Progress Modal
**Route:** GET `/api/v1/jobs/{job_id}`

#### 2.6.1 Layout

```
┌──────────────────────────────────────────────────────────────┐
│ IMPORT JOB STATUS                                      [✕]   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ Job ID: job-2024-12-10-12345                               │
│ Status: PROCESSING                                          │
│ Started: 2024-12-10 12:45:30                               │
│ Elapsed: 5 min 23 sec                                       │
│                                                              │
│ Progress:                                                   │
│ ┌────────────────────────────────────────────────────┐    │
│ │ ████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ 35% │
│ │ 35 of 100 mappings processed                       │    │
│ └────────────────────────────────────────────────────┘    │
│                                                              │
│ Results So Far:                                             │
│   ✓ Successful: 33                                         │
│   ⚠️  Warnings: 2 (e.g., duplicate entries skipped)        │
│   ✕ Errors: 0                                              │
│                                                              │
│ Current Item: Processing mapping [34/100]                  │
│ Topic: "Verb Tenses" → Competency: "Tenses"              │
│                                                              │
│ [Pause] [Cancel] [Minimize]                               │
│                                                              │
│ Estimated Time Remaining: ~9 minutes                       │
│                                                              │
│ ─ Job Details ─                                            │
│ ☐ Show detailed logs (errors and warnings)                │
│                                                              │
└──────────────────────────────────────────────────────────────┘

// After Completion:

┌──────────────────────────────────────────────────────────────┐
│ IMPORT JOB COMPLETED                                   [✕]   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ Job ID: job-2024-12-10-12345                               │
│ Status: ✓ COMPLETED                                        │
│ Duration: 15 min 42 sec                                    │
│                                                              │
│ Final Results:                                              │
│   ✓ Successfully imported: 98                              │
│   ⚠️  Warnings: 2 (skipped duplicates)                     │
│   ✕ Errors: 0                                              │
│   ◯ Total processed: 100                                   │
│                                                              │
│ Summary:                                                    │
│ └─ Added 98 new mappings                                   │
│ └─ 2 duplicate rows skipped (already mapped)              │
│ └─ Coverage improved from 67% → 82%                        │
│                                                              │
│ [Download Report (CSV)]  [View Detailed Logs]              │
│ [Close] [Back to Dashboard]                               │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

### 2.7 Analytics / Coverage Dashboard
**Route:** `/curriculum/mappings/analytics`

#### 2.7.1 Layout

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ MAPPING ANALYTICS & COVERAGE REPORT                                                │
├────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                    │
│ KEY METRICS                                                                        │
│ ├─ Total Mappings: 245                                                            │
│ ├─ Topics Mapped: 18 / 24 (75%)                                                  │
│ ├─ Competencies Mapped: 22 / 25 (88%)                                            │
│ └─ Overall Coverage: 81.5%                                                        │
│                                                                                    │
│ COVERAGE BY CLASS/SUBJECT                                                         │
│ ┌─────────────────────┬──────────┬─────────┬──────────────────────────────────┐  │
│ │ Class / Subject     │ Topics   │ Mapped  │ Coverage %                       │  │
│ ├─────────────────────┼──────────┼─────────┼──────────────────────────────────┤  │
│ │ 9th Standard        │          │         │                                  │  │
│ │  └─ English         │   4      │   4     │ ████████████████████ 100%      │  │
│ │  └─ Maths           │   6      │   5     │ ██████████████░░░░░░░ 83%      │  │
│ │  └─ Science         │   5      │   3     │ ████████░░░░░░░░░░░░░ 60%      │  │
│ │                                                                               │  │
│ │ 10th Standard       │          │         │                                  │  │
│ │  └─ English         │   3      │   3     │ ████████████████████ 100%      │  │
│ │  └─ Maths           │   4      │   2     │ ██████░░░░░░░░░░░░░░░ 50%      │  │
│ └─────────────────────┴──────────┴─────────┴──────────────────────────────────┘  │
│                                                                                    │
│ GAPS & UNMAPPED ITEMS                                                             │
│ ├─ Unmapped Topics (6):                                                          │
│ │   • Probability (9th Maths)                                                   │
│ │   • Statistics (9th Maths)                                                   │
│ │   • Organic Chemistry (10th Science)                                         │
│ │   • Genetics (10th Science)                                                 │
│ │   • Trigonometry (10th Maths)                                               │
│ │   • Ecosystems (10th Science)                                               │
│                                                                                    │
│ ├─ Unused Competencies (3):                                                      │
│ │   • COMP-MAT-099: Advanced Problem Solving (0 mapped topics)                │
│ │   • COMP-SCI-005: Biotechnology (0 mapped topics)                           │
│ │   • COMP-ENG-025: Academic Writing (0 mapped topics)                        │
│                                                                                    │
│ TREND OVER TIME                                                                   │
│ Coverage Trend (Last 90 days):                                                   │
│ ┌──────────────────────────────────────────────────────────────────────┐        │
│ │   100%  ╱╲                                                            │        │
│ │    80%  ╱  ╲╱╲╱╲╱╲                                                   │        │
│ │    60%  ╱                                                             │        │
│ │    40%  ╱                                                             │        │
│ │    20%  ╱                                                             │        │
│ │    0%   └──────────────────────────────────────────────────────────   │        │
│ │        Sep    Oct    Nov    Dec                                        │        │
│ │        30%   45%    65%    81.5%                                      │        │
│ └──────────────────────────────────────────────────────────────────────┘        │
│                                                                                    │
│ [Download Report] [Schedule Review] [Export Data]                               │
│                                                                                    │
└────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Single Mapping Request
```json
POST /api/v1/mappings/topics/{topic_id}/competencies
{
  "competency_id": 501,
  "notes": "Mapped during curriculum alignment review"
}
```

### 3.2 Create Single Mapping Response
```json
{
  "success": true,
  "data": {
    "topic_id": 1001,
    "competency_id": 501,
    "mapped_by": "user_123",
    "mapped_at": "2024-12-10T12:30:00Z",
    "mapping_source": "UI",
    "notes": "Mapped during curriculum alignment review"
  },
  "message": "Mapping created successfully"
}
```

### 3.3 Remove Single Mapping Request
```
DELETE /api/v1/mappings/topics/{topic_id}/competencies/{competency_id}

// Response
{
  "success": true,
  "message": "Mapping removed successfully",
  "data": {
    "topic_id": 1001,
    "competency_id": 501,
    "deleted_at": "2024-12-10T12:35:00Z"
  }
}
```

### 3.4 Bulk Map Request
```json
POST /api/v1/mappings/bulk
{
  "mappings": [
    {"topic_id": 1001, "competency_id": 501},
    {"topic_id": 1002, "competency_id": 501},
    {"topic_id": 1001, "competency_id": 502}
  ],
  "options": {
    "overwrite": false,
    "source": "UI",
    "notify_on_complete": true
  }
}

// Response (202 Accepted for large batches)
{
  "success": true,
  "job_id": "job-2024-12-10-abc123",
  "message": "Bulk mapping job started",
  "data": {
    "mapping_count": 3,
    "processing_status": "QUEUED",
    "estimated_duration": "5 minutes"
  }
}
```

### 3.5 Import CSV Request
```
POST /api/v1/mappings/import
Content-Type: multipart/form-data

Field: file (CSV file)
Body rows format:
topic_code,topic_name,competency_code,competency_name,notes

// Response (202 Accepted, returns job_id)
{
  "success": true,
  "job_id": "job-2024-12-10-def456",
  "message": "CSV import job started",
  "data": {
    "file_rows_count": 45,
    "processing_status": "PARSING",
    "preview": {
      "matched_rows": 40,
      "warning_rows": 2,
      "error_rows": 3
    }
  }
}
```

### 3.6 Export CSV Request
```
GET /api/v1/mappings/export?class_id=9&subject_id=5&format=csv&include_metadata=true

// Response: CSV file download
Content-Disposition: attachment; filename="mappings_export_2024-12-10.csv"

topic_code,topic_name,competency_code,competency_name,mapped_by,mapped_at,source
ENG-1-001,Grammar Basics,COMP-ENG-001,Grammar Mastery,user_123,2024-12-01T09:15:00Z,UI
...
```

### 3.7 Get Mapping Analytics
```
GET /api/v1/mappings/analytics?class_id=9&days=90

// Response
{
  "success": true,
  "data": {
    "total_mappings": 245,
    "topics_mapped_count": 18,
    "topics_total_count": 24,
    "competencies_mapped_count": 22,
    "competencies_total_count": 25,
    "coverage_percentage": 81.5,
    "unmapped_topics": [...],
    "unused_competencies": [...],
    "coverage_trend": [
      {"date": "2024-09-10", "coverage": "30%"},
      ...
    ]
  }
}
```

---

## 4. USER WORKFLOWS

### 4.1 Single Map (from Topic Detail)
```
1. User opens Topic detail → Competencies tab
2. Clicks [+ Add Competency]
3. Search modal appears
4. User types: "Grammar" → Typeahead shows matches:
   - ✓ Grammar Mastery (already mapped)
   - ☐ Grammar Fundamentals (not mapped)
   - ☐ Parts of Speech (not mapped)
5. User clicks "Grammar Fundamentals"
6. Confirmation toast shows: "Mapping created"
7. Competency appears in table (mapped_at: Today)
8. Detail panel refreshes, competency count increments
```

### 4.2 Bulk Map (from Dashboard)
```
1. User navigates to Mapping Dashboard
2. Selects Topics on left: "Grammar Basics", "Parts of Speech"
3. Selects Competencies on right: "Grammar Mastery", "Parts of Speech"
4. Mapping preview shows:
   - Will create 4 mappings (2 topics × 2 competencies)
5. User clicks [Map →]
6. If small batch:
   - Client calls POST /api/v1/mappings/bulk directly
   - Wait for response, show results, refresh UI
7. If large batch:
   - Background job created, user sees progress modal
   - Job processes asynchronously
   - Notification sent on completion
```

### 4.3 CSV Import Workflow
```
1. User clicks [Import CSV] from mapping dashboard
2. Import modal opens, STEP 1: Upload
3. User clicks [Choose File] or drags CSV
4. File uploads and system parses
5. STEP 2: Preview & Resolve
   - 40 rows matched ✓
   - 2 rows with warnings ⚠️
   - 3 rows with errors ✕
6. User clicks "Warnings" tab
7. For each unmatched row:
   - User either [Ignore] or [Map to: ________]
   - Auto-suggest dropdown helps find correct topic/competency
8. After resolving all warnings:
   - [Confirm & Import]
9. STEP 3: Confirm
   - Shows summary: "Will import 40, skip 2, ignore 3"
   - Checkbox: ☑ Overwrite existing mappings
10. User clicks [Import →]
11. Background job starts, progress modal shows
12. On completion: Report shows success count, warnings, skipped
13. User can [Download Report] for audit trail
```

### 4.4 CSV Export Workflow
```
1. User clicks [Export CSV] from dashboard
2. Export modal opens
3. User selects filters:
   - ☑ Include all mappings (1,245 rows)
   - ☐ Filter by Class: [9th Standard]
4. Output format: ☑ CSV
5. Includes metadata: ☑ (mapped_by, mapped_at, source)
6. User clicks [Download]
7. Browser downloads CSV file: "mapping_export_2024-12-10.csv"
8. File contains mapping history and source information
```

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Colors
| Element | Color |
|---------|-------|
| Mapped (checkmark) | #10B981 (Green) |
| Unmapped | #D1D5DB (Gray) |
| Warning | #F59E0B (Amber) |
| Error | #EF4444 (Red) |
| Selected | #3B82F6 (Blue) |

### 5.2 Spacing & Layout
- **Pane Width:** Each outer pane (left/right) = 30% of container width
- **Middle Pane:** 10% width for action buttons
- **Modal Padding:** 24px
- **Button Spacing:** 8px horizontal, 12px vertical

### 5.3 Icons
- **Map:** 🔗 Link
- **Unmap:** 🔓 Unlink
- **Import:** ⬆️ Upload
- **Export:** ⬇️ Download
- **Mapped:** ✓ Checkmark
- **Unmapped:** ☐ Checkbox
- **Warning:** ⚠️ Warning
- **Error:** ✕ X
- **Analytics:** 📊 Chart

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 Keyboard Navigation
- **Tab:** Move between panes and buttons
- **Enter/Space:** Select items, toggle checkboxes
- **Arrow Keys:** Navigate lists
- **Escape:** Close modals
- **Ctrl+M:** Trigger Map action (if focused on right pane)

### 6.2 ARIA Labels & Screen Readers
```html
<div role="region" aria-label="Topic selector pane">...</div>
<button aria-label="Map selected topics to competencies">Map →</button>
<div aria-live="polite" aria-label="Mapping results">
  Success: 3 mappings created
</div>
```

### 6.3 Async Notifications
- Use ARIA live regions to announce job progress
- Toast notifications with auto-dismiss (5 seconds)
- Modal progress indicators for long-running jobs

---

## 7. PERFORMANCE CONSIDERATIONS

### 7.1 Optimization
- **Selectors:** Lazy-load tree children on expand
- **Pagination:** 10 items per page in modal lists
- **Debounce:** Search input (300ms delay)
- **Memoization:** Cache selector state while modal open

### 7.2 Caching
- Cache topic/competency lists (5-minute TTL, invalidate on create/delete)
- Cache analytics (hourly TTL)
- Use ETags for job status polling

### 7.3 API Rate Limiting
- Map/Unmap: 30 req/min
- Bulk Map: 10 req/min (large batches queued as jobs)
- Import: 1 job/min per user
- Export: 5 exports/min per user

---

## 8. TESTING CHECKLIST

### 8.1 Functional Testing
- [ ] Map single topic to competency (from both directions)
- [ ] Unmap single mapping (with/without confirmation)
- [ ] Bulk map multiple topics to multiple competencies
- [ ] Bulk unmap multiple mappings
- [ ] Prevent duplicate mappings (UI deduplication)
- [ ] CSV import with valid/invalid rows
- [ ] CSV import with unmatched items and manual resolution
- [ ] CSV export with and without filters
- [ ] Import job progress tracking and completion
- [ ] Undo recent mapping action
- [ ] Cross-subject mappings (if policy allows)

### 8.2 UI/UX Testing
- [ ] Dashboard panes responsive and draggable borders (optional)
- [ ] Mapping preview updates on selection change
- [ ] Type badges color-coded correctly (Knowledge/Skill/Attitude)
- [ ] Search/filter real-time in both panes
- [ ] Modal opens/closes smoothly
- [ ] Progress modal updates in real-time during job
- [ ] Toast notifications appear/disappear
- [ ] Job report displays correctly

### 8.3 Accessibility Testing
- [ ] Keyboard navigation works in all panes
- [ ] ARIA labels for complex regions
- [ ] Screen reader announces mapping counts and results
- [ ] Color contrast meets WCAG AA
- [ ] Live regions announce job progress

### 8.4 Integration Testing
- [ ] API calls match contract
- [ ] Error responses handled gracefully
- [ ] Duplicate mapping prevention
- [ ] Cross-subject constraints enforced
- [ ] Job idempotency (retry without creating duplicates)
- [ ] Mapping count metrics match DB counts

---

## 9. FUTURE ENHANCEMENTS

1. **ML-based Suggestions:** Auto-suggest mappings with confidence scores using question/topic embeddings
2. **Mapping Score & Review Queue:** Assign review scores, allow stakeholder approval workflow
3. **Graph Visualization:** Show mapping density and relationships visually
4. **Batch Verification:** Allow curriculum team to QA and approve bulk imports before final commit
5. **Mapping History:** View and restore previous mapping versions
6. **Performance Alignment:** Show student performance correlated with topic-competency mappings
7. **Drag-Drop in Dashboard:** Drag topics from left to right pane for quick mapping
8. **Advanced Filtering:** Filter by NEP code, mapping source, date range
9. **Competency Grouping:** Group mappings by competency type or NEP framework
10. **API Webhooks:** Notify external systems when mappings change

---

## Appendix A: Component Library References

| Component | Library | Notes |
|-----------|---------|-------|
| Paned Layout | Allotment / React DnD | Resizable panes |
| Tree Selector | React Beautiful Tree | Hierarchical selection |
| Search/Typeahead | Combobox Aria / Downshift | Accessible dropdown |
| Modal | Radix Dialog | Accessible modal |
| Progress | Radix Progress | Accessible progress bar |
| Toast | React Hot Toast | Dismissible notifications |
| Table | TanStack Table | Sortable, filterable, paginated |
| Job Status | WebSocket / Polling | Real-time updates |

---

**Document Created By:** Database Architect  
**Last Reviewed:** December 10, 2025  
**Version Control:** Git repository

