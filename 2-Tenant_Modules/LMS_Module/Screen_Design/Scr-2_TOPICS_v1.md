# Screen Design Specification: Topic Management (`slb_topics`)

Version: 1.2
Last Updated: December 10, 2025

Purpose: Developer-focused UI/UX specification for managing hierarchical Topics and Sub-Topics. Provides complete details for list & tree management, create/edit flows, drag/drop operations, API contracts, validation rules, accessibility, testing, and operational notes — aligned with the `sch_lesson` screen detail level.

1) Context & Goals
  - Topics are hierarchical units under `Lesson` and are the primary content grouping for Questions and Competencies.
  - Primary goals: make hierarchy management intuitive, keep ordinals consistent and auditable, enable bulk operations, and ensure tight integration with Competency mappings and Question tagging.

Data Model (reference)
```
Table: `slb_topics`
Columns: id, parent_id, lesson_id, class_id, subject_id, name, short_name, ordinal, level, description, duration_minutes, learning_objectives (JSON), metadata (JSON), is_active, created_by, updated_by, created_at, updated_at, deleted_at
Primary/Unique: PK(id), Unique(lesson_id, parent_id, name)
```

Roles & Permissions
  - Admin: full CRUD, bulk operations, audit access
  - Curriculum Manager: create/edit within assigned classes/subjects
  - Teacher: suggest edits, view, link competencies
  - Student: read-only

2) Screens & Interaction Patterns

2.1 Topic List (Landing)
  - Route: `/curriculum/lessons/{lessonId}/topics`
  - Components:
    - Breadcrumb: Class > Subject > Lesson > Topics
    - Primary action: `+ New Topic` (opens Create modal)
    - Filter bar: Status, Search, Tag/Objective filter, Duration range
    - Table with columns: Checkbox | Name | Short Name | Level | Ordinal | Duration | Children | Questions | Status | Actions
    - Quick actions per row: View (open detail panel), Edit, Add Child, Reorder handle, Menu (Duplicate / Export / Delete)
  - Behaviors:
    - Server-side pagination (10/25/50), server-side filtering & search
    - Selection persists across pagination for bulk actions with clear selection count

2.2 Hierarchical Topic Tree (Primary Management UX)
  - Embedded Tree Tab or full-screen tree view at `/curriculum/lessons/{lessonId}/topics/tree`
  - Node content: name, ordinal badge, duration, small icons for questions/competencies
  - Drag-and-drop semantics:
    - Reorder among siblings → updates ordinal
    - Move to new parent → updates parent_id and level; server re-validates level and cascading rules
    - Visual preview on drag showing ordinal preview and number of nodes affected
  - Constraints:
    - Prevent moves that create cycles
    - Disallow exceeding configured max depth (if defined in org settings)
  - Performance:
    - Lazy-load children
    - Virtualize long lists inside nodes

2.3 Create / Edit Topic Modal (Full spec)
  - Endpoints: Create `POST /api/v1/topics` | Update `PUT /api/v1/topics/{id}`
  - Fields (order & validation):
    - Class (readonly if context provided) — required
    - Subject (readonly/auto) — required
    - Lesson (required)
    - Parent Topic (tree picker) — optional; showing hierarchy to pick
    - Name (text) — required, 1-150 chars, no control characters
    - Short Name (text) — optional, 1-50 chars; auto-suggested from Name
    - Ordinal (integer) — required; client shows available ordinals among siblings
    - Duration (minutes) — optional, integer >= 1
    - Learning Objectives (rich editor or tags) — optional, supports list/JSON
    - Description (textarea) — optional, supports markdown
    - Metadata (JSON) — optional for integrations
    - Is Active (boolean toggle)
  - Validation rules:
    - Name unique per (`lesson_id`,`parent_id`)
    - Parent cannot be self or descendant
    - Ordinal must be positive; if collision, provide option to auto-shift siblings
  - UX niceties:
    - Parent selection shows current level preview
    - When parent chosen, Level read-only shows computed level
    - Inline help for Learning Objectives format
    - Save states: Draft vs Published (if required by workflow)

2.4 Topic Detail Panel
  - Overview: metadata, learning objectives, created/updated info
  - Tabs:
    - Sub-Topics (tree) — inline management actions
    - Questions — links to filtered Question bank and quick-stats (difficulty, tags)
    - Competencies — mapped competencies with Add/Unlink
    - Activity Log — audit trail with timestamp, user, change summary
  - Quick actions: Duplicate Topic (deep copy with option to include children), Export (topic + children as JSON/CSV)

3) API Contracts & Examples
  - Create Topic
    - POST /api/v1/topics
    - Body:
      {
        "lesson_id": 123,
        "parent_id": null,
        "name": "Grammar Basics",
        "short_name": "Grammar",
        "ordinal": 1,
        "duration_minutes": 90,
        "learning_objectives": ["Identify nouns","Use tenses"],
        "metadata": {"suggested_readings": ["url1"]},
        "is_active": true
      }
    - Success: 201 Created { full topic object including computed `level` }

  - Update Topic
    - PUT /api/v1/topics/{id}
    - Partial updates allowed; returns updated object

  - Bulk Sequence / Move
    - PATCH /api/v1/topics/sequence
    - Body:
      {
        "updates": [{"topic_id": 11, "parent_id": null, "ordinal": 1}, ...],
        "options": {"auto_shift": true}
      }
    - Returns: 200 with changed rows and audit references

  - Fetch with includes
    - GET /api/v1/topics/{id}?include=children,questions,competencies,activity

4) Error Handling & Validation Messages
  - 400 Bad Request: Missing required fields
  - 409 Conflict: Name already exists under same parent
  - 422 Unprocessable: Parent is descendant (message: "Invalid parent — would create cyclic hierarchy")
  - 429 Too Many Requests: Rate-limit sensitive endpoints (reorder)

5) Workflows
  - Create Topic (root): click `+ New Topic` → fill required fields → Save → show toast 'Topic created' and highlight in tree
  - Add Sub-Topic: Add from parent node → Parent prefilled → Save → parent auto-expands
  - Move Topic (drag/drop): preview → confirm → PATCH sequence → refresh affected nodes and activity log
  - Delete Topic: warn if has children/questions → options: Cancel / Cascade Delete / Reparent children to parent

6) Accessibility & Keyboard
  - Tree: ARIA roles `tree` / `treeitem` / `group`
  - Keyboard navigation: Up/Down navigate, Right expand, Left collapse, Enter view, Ctrl+Arrow for reparent (or provide separate keyboard move mode)
  - Modals: focus trap, accessible labels and helper texts

7) Performance & Scalability
  - Lazy load child sets on expand
  - Server-side filtering & pagination for lists and questions tab
  - Use background jobs for heavy exports/imports

8) Testing Checklist (detailed)
  - Create root topic with valid and invalid payloads
  - Create nested topics to depth N and ensure `level` correct
  - Attempt to create cycle — assert rejection
  - Reorder siblings and verify resulting ordinals & audit log
  - Move topic between parents (including across lessons if policy allows) and validate constraints
  - Delete topic with children: cascade and reparent flows
  - UI: keyboard navigation, screen-reader labels, mobile behavior

9) Telemetry & Audit
  - Track events: topic.create, topic.update, topic.delete, topic.reorder with user, timestamp, client info
  - Record diffs for `topic.update` in audit table for rollback/traceability

10) Edge Cases & Operational Notes
  - Large trees: recommend paginated/virtualized UI and incremental import/export
  - Concurrent reorder conflicts: use optimistic locking and provide conflict resolution UI
  - Data migration note: when merging `sub_topic` into `slb_topics`, ensure `level` and `parent_id` computed safely

11) Next Enhancements
  - CSV import with parent path syntax (e.g. "Chapter 1/Topic A/Subtopic 1")
  - Undo/Redo stack for drag/drop operations
  - ML suggestions for grouping topics and auto-assigning ordinals

---

End of `SCREEN_DESIGN_SLB_TOPICS.md`.
