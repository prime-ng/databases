# Screen Design Specification: Topic-Competency Mapping (`slb_topic_competency_jnt`)

Version: 1.2
Last Updated: December 10, 2025

Purpose: Developer-ready UI/UX specification for mapping Topics (`slb_topics`) to Competencies (`slb_competencies`) using the join table `slb_topic_competency_jnt`. This document covers single and bulk mapping UIs, import/export flows, job handling, analytics, API contracts, validation rules, accessibility, telemetry, and testing — at the same level of detail as the Lesson spec.

1) Context & Goals
  - Mapping Topics to Competencies enables analytics on coverage and student mastery. Mappings should be easy to maintain and auditable.
  - Goals: fast single/multi mapping, safe bulk operations, clear validation for cross-subject rules, and actionable analytics for gaps and coverage.

Data Model (reference)
```
Table: `slb_topic_competency_jnt`
Columns: topic_id, competency_id, mapped_by, mapped_at, mapping_source (UI|CSV|API|ML), notes (nullable)
Primary Key: (topic_id, competency_id)
Indexes: idx_topic(topic_id), idx_competency(competency_id)
```

Roles & Permissions
  - Admin / Curriculum Manager: full map/unmap, bulk import/export, audit
  - Subject Coordinator / Teacher: create mappings for assigned subjects
  - QA / Auditor: view-only access to mappings and change history

2) Screens & Interaction Patterns

2.1 Mapping Dashboard (Primary)
  - Route: `/curriculum/mappings/topics-competencies`
  - Layout: three-column layout
    - Left: Topic selector (tree/search) with filters: Class, Subject, Lesson, Status
    - Middle: Action area with `Map Selected →` and `← Unmap Selected`, quick-filters, preview
    - Right: Competency selector (tree/list) with filters: Type, NEP alignment, Status
  - Selection semantics: support multi-select on both sides; show counts and preview of existing mappings before action
  - Undo: small undo toast for recent mapping actions (5–10s) where possible
  - Job for large batches: actions above threshold (e.g., >200 mappings) run as background job

2.2 Topic Detail → Competencies Tab
  - Show mapped competencies with badges, mapping source, mapped_by, mapped_at
  - Quick Map: typeahead search for competency; show suggested competency matches with score
  - Unlink: confirmation modal when removal affects student outcomes

2.3 Competency Detail → Topics Tab
  - Show mapped topics with lesson/class context and quick link to topic detail
  - Bulk unlink/map from this view

2.4 Bulk Mapping Import/Export
  - CSV import format: `topic_code,topic_name,competency_code,competency_name,notes`
  - Import preview: server attempts best-effort match by code → name; show unmatched rows and allow manual resolution
  - Import confirmation starts background job: returns job id; UI shows job progress, success metrics (mapped_count, failed_count)
  - Export: CSV with mapping metadata and counts

3) API Contracts & Examples
  - Map single
    - POST /api/v1/mappings/topics/{topic_id}/competencies
    - Body: { "competency_id": 201, "notes": "mapped during curriculum review" }
    - Response: 201 Created {mapping object}

  - Unmap single
    - DELETE /api/v1/mappings/topics/{topic_id}/competencies/{competency_id}
    - Response: 204 No Content

  - Bulk map
    - POST /api/v1/mappings/bulk
    - Body:
      {
        "mappings": [{"topic_id": 11, "competency_id": 201}, ...],
        "options": {"source": "CSV", "notify_on_complete": true}
      }
    - Response: 202 Accepted { "job_id": "job-123" }

  - Import CSV
    - POST /api/v1/mappings/import
    - Multipart upload -> server returns `job_id` to monitor

  - Job status
    - GET /api/v1/jobs/{job_id}
    - Response includes progress, success_count, failure_count, errors (sample rows)

4) Validation Rules & Business Logic
  - Deduplication: prevent creating duplicate (topic_id, competency_id) pairs
  - Cross-subject constraints: by default, only allow mapping when `topic.class_id/subject_id` matches `competency.class_id/subject_id`; if org policy allows cross-mappings, show warning and record `mapping_source` = 'cross-subject'
  - Mapping deletes: if mapping has downstream student outcomes, require confirm and record deletion reason in audit
  - Background jobs: implement idempotency for retries

5) Workflows (detailed)
  - Single map via Topic Detail:
    1. Open Topic → Competencies tab → type in competency → select and click Map
    2. Client POSTs mapping, on success UI updates and shows toast
  - Dashboard multi-map:
    1. Select topics on left, select competencies on right → click `Map Selected`
    2. If selection size small → client calls bulk API; if large → create background job
    3. On job completion notify user and refresh affected topic/competency counts
  - CSV import:
    1. Upload file → preview shows matched/unmatched rows
    2. Resolve mismatches (manual map) → confirm → background job runs
    3. User receives notification and job report with details

6) Analytics, Reports & Metrics
  - Coverage metrics: topics mapped per competency, competencies per topic
  - Gap analysis: list topics without competencies and competencies with low topic coverage
  - Trend metrics: how mapping counts evolve over time (useful during curriculum updates)
  - Exports: mapping report per lesson/class and per competency

7) Accessibility & UX
  - Keyboard accessible tree and multi-select (Shift/Ctrl for multi-select)
  - ARIA live regions for job status notifications
  - Clear focus order and labels for mapping actions

8) Telemetry & Audit
  - Events: mapping.create, mapping.delete, mapping.import.started/completed, mapping.job.failed
  - Audit record: who mapped/unmapped, when, source (UI/CSV/API/ML), and optional notes

9) Operational Considerations
  - Throttling: protect bulk endpoints and require background jobs for large batches
  - Idempotency: bulk endpoints should be idempotent using client-generated request id
  - Retention: retain mapping audit for configurable retention window; export raw job logs for SRE

10) Testing Checklist
  - Single map/unmap success and conflict cases
  - Bulk map via UI and CSV import with valid and invalid rows
  - Cross-subject mapping warnings and policy enforcement
  - Large uploads / background job retry and idempotency
  - Analytics numbers validation vs DB counts
  - Accessibility keyboard and screen-reader flows

11) Next Enhancements
  - ML-based auto-mapping suggestions with confidence scores
  - Mapping score & review queue for curriculum team
  - Graph visualization of mapping density and gaps

---

End of `SCREEN_DESIGN_SLB_TOPIC_COMPETENCY_JNT.md`.
