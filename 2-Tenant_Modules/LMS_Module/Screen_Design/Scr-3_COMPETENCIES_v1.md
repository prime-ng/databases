# Screen Design Specification: Competency Management (`slb_competencies`)

Version: 1.2
Last Updated: December 10, 2025

Purpose: Developer-ready, comprehensive UI/UX specification for managing the competency framework (NEP-aligned). Includes CRUD, hierarchical structure, mapping to Topics, analytics/insights, bulk tools, API contracts, validation rules, accessibility, and testing guidance.

1) Context & Goals
  - Competencies represent measurable learning outcomes. They may be hierarchical and mapped to Topics.
  - Goals: provide an easy way to build and maintain competency taxonomies, map competencies to curriculum Topics, and surface mastery analytics.

Data Model (reference)
```
Table: `slb_competencies`
Columns: id, code, name, class_id, subject_id, description, parent_competency_id, competency_type, nep_alignment (JSON), metadata (JSON), is_active, created_by, updated_by, created_at, updated_at, deleted_at
Unique: (code, class_id, subject_id)
```

Roles & Permissions
  - Admin / Curriculum Manager: full CRUD, hierarchical edits, export
  - Subject Coordinator: create/edit competencies for assigned subjects
  - Teacher: view, map topics, suggest edits
  - Student: view competency mastery (read-only)

2) Screens & Interaction Patterns

2.1 Competency List
  - Route: `/curriculum/competencies?classId={}&subjectId={}`
  - Components:
    - Filters: Class, Subject, Type (Knowledge/Skill/Attitude), NEP alignment, Status
    - Search: code or name
    - Table columns: Checkbox | Code | Name | Parent | Level | Type | NEP Tags | Mapped Topics | Status | Actions
    - Quick actions: View, Edit, Add Child, Export
    - Bulk actions: Activate, Deactivate, Export, Reorder
  - Pagination: server-side; selection persists across pages

2.2 Hierarchical Competency Tree
  - Visual tree similar to Topics
  - Node badges: Type, NEP primary tag
  - Drag & drop to reparent/reorder; preview shows impact
  - Constraints: prevent cycles; optionally restrict reparenting across subjects

2.3 Create / Edit Competency Modal (Full)
  - Endpoints: Create `POST /api/v1/competencies` | Update `PUT /api/v1/competencies/{id}`
  - Fields & validations:
    - Class (required)
    - Subject (required)
    - Code (required, alpha-numeric, unique per class+subject)
    - Name (required, max 200)
    - Parent Competency (tree picker) — optional
    - Type (enum: KNOWLEDGE / SKILL / ATTITUDE) — required
    - NEP Alignment: tag selector or multi-select referencing NEP taxonomy
    - Description (markdown-enabled textarea)
    - Metadata (JSON) — optional
    - Is Active (toggle)
  - UX:
    - If Parent selected, show inherited properties preview
    - Duplicate detection for Code & Name with clear resolution options

2.4 Competency Detail
  - Tabs: Overview | Topics Mapped | Student Outcomes | Activity Log
  - Topics Mapped: list with quick Unlink and View Topic actions
  - Student Outcomes: aggregated mastery metrics, distribution over sections and over time
  - Activity Log: CRUD and mapping audit entries

3) API Contracts (examples)
  - Create competency
    - POST /api/v1/competencies
    - {
    "code": "COMP-ENG-001",
    "name": "Use tense correctly",
    "class_id": 5,
    "subject_id": 12,
    "competency_type": "SKILL",
    "nep_alignment": ["NEP-1.1"],
    "description": "Ability to select proper tense in sentences",
    "is_active": true
    }
  - Bulk map topics
    - POST /api/v1/competencies/{id}/map-topics
    - { "topic_ids": [1001,1002] }

4) Bulk Tools & CSV
  - CSV format for competencies import: `code,name,parent_code,class_id,subject_id,type,nep_tags,description`
  - Import preview shows matches for parent_code and flags conflicts
  - Bulk export includes mapping counts and metadata

5) Validation & Business Rules
  - Code uniqueness enforced per (class,subject)
  - Parent cannot be self or descendant
  - If reparenting across subject/class: show explicit confirmation and consequences (e.g., child inheritance)
  - Deleting competency with mappings or student outcomes: block or require cascade with warning

6) Workflows
  - Create competency: open modal, fill fields → server-side validation → create → show toast and refresh
  - Map topics: from competency detail or mapping dashboard; select topics and confirm mapping
  - Bulk import: upload CSV → preview → resolve conflicts → start background job → notify on completion

7) Analytics & Reports
  - Mastery heatmap: competency vs class/section
  - Trend: mastery over time per competency
  - Gaps: competencies with no mapped topics; topics with no competencies
  - Export: student-level competency mastery CSV, competency summary per class

8) Accessibility & Performance
  - ARIA roles for tree and pickers, keyboard navigation
  - Lazy-load deep trees and analytics panels
  - Use background jobs for heavy imports/exports

9) Testing Checklist
  - CRUD competencies including parent-child creation
  - Unique code constraints, reparenting validation, cross-subject warnings
  - Mapping/unmapping topics, bulk import with invalid rows, analytics numbers
  - Accessibility tests: keyboard navigation, screen-reader labels

10) Telemetry & Audit
  - Events: competency.create/update/delete, competency.map, competency.unmap
  - Store audit diffs for changes, mapping events reference user/job IDs

11) Next Enhancements
  - Auto-suggest competency codes and names using historical data
  - ML-suggested competency-topic mappings based on question embeddings
  - Graph visualizer for competency → topics → questions relationships

---

End of `SCREEN_DESIGN_SLB_COMPETENCIES.md`.
