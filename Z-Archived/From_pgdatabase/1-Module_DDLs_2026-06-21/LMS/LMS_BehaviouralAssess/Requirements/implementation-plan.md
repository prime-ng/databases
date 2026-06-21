# Behavioural Assessment Module — Requirements Index

## Purpose
Master index of all per-tab requirement files. Each tab below has its own `.md` file with detailed database fields, business rules, CRUD operations, and permissions.

---

## Tab → Requirement File Map

| Tab | Requirement File | FR Coverage | Key Tables |
|-----|-----------------|-------------|------------|
| **Rating Scales** | `rating-scales.md` | FR-BA-001 | `ba_rating_scales`, `ba_rating_levels` |
| **Categories & Criteria** | `categories.md` | FR-BA-002 | `ba_categories`, `ba_criteria`, `ba_class_category_jnt` |
| **Assessment Periods** | `assessment-periods.md` | FR-BA-003 | `ba_assessment_periods` |
| **Configuration** | `configuration.md` | FR-BA-004 | `ba_config` |
| **Assessments (Teacher Entry)** | `assessments.md` | FR-BA-005, FR-BA-006 | `ba_assessments`, `ba_assessment_ratings`, `ba_student_remarks` |
| **Review & Approval** | `reviews.md` | FR-BA-008 | `ba_assessments` (status FSM) |
| **Incidents** | `incidents.md` | FR-BA-007 | `ba_incidents`, `ba_incident_witnesses_jnt`, `ba_incident_intervention_jnt` |
| **Interventions** | `interventions.md` | FR-BA-007 | `ba_interventions` |
| **Score Computation** | `scores-computation.md` | FR-BA-009, FR-BA-010, FR-BA-011 | `ba_computed_scores`, all assessment tables |
| **Reports & Dashboard** | `reports-dashboard.md` | FR-BA-012, FR-BA-013, FR-BA-014, FR-BA-015 | `ba_computed_scores`, `ba_incidents`, `ba_assessments` |
| **Audit Log** | `audit-log.md` | BR-BA-009 | `ba_audit_log` |

---

## Entity Summary (16 Tables)

| # | Table | Domain | Layer | Description |
|---|---|---|---|---|
| 1 | `ba_rating_scales` | Rating Config | L1 | Rating scales with grade types and min/max bounds |
| 2 | `ba_categories` | Category | L1 | Behavioural categories with polarity and weights |
| 3 | `ba_interventions` | Master Data | L1 | Predefined intervention types |
| 4 | `ba_rating_levels` | Rating Config | L2 | Individual levels within a scale |
| 5 | `ba_criteria` | Category | L2 | Observable criteria within a category |
| 6 | `ba_class_category_jnt` | Category | L3 | Class-category applicability mapping |
| 7 | `ba_assessment_periods` | Assessment | L3 | Assessment windows with lifecycle |
| 8 | `ba_config` | Configuration | L3 | School-level settings per session |
| 9 | `ba_assessments` | Assessment | L4 | Teacher assessment header records |
| 10 | `ba_audit_log` | Audit | L4 | Immutable audit trail |
| 11 | `ba_assessment_ratings` | Assessment | L5 | Core fact table (student × criterion ratings) |
| 12 | `ba_student_remarks` | Assessment | L5 | Overall teacher remarks per student |
| 13 | `ba_computed_scores` | Computation | L5 | Cached computed scores |
| 14 | `ba_incidents` | Incident | L5 | Behavioural incident records |
| 15 | `ba_incident_witnesses_jnt` | Incident | L6 | Witness junction |
| 16 | `ba_incident_intervention_jnt` | Incident | L6 | Intervention junction |

---

## Business Rules Summary (20 Rules)

| Rule ID | Rule | Enforcement |
|---|---|---|
| BR-BA-001 | Unique rating per (assessment, student, criterion) | DB constraint |
| BR-BA-002 | One assessment per teacher per class-section per period | DB constraint |
| BR-BA-003 | Locked period prevents ALL assessment edits | Service layer |
| BR-BA-004 | Multi-teacher ratings averaged during score computation | Service layer |
| BR-BA-005 | Category score = weighted average of criterion scores | Service layer |
| BR-BA-006 | Overall score = weighted average of category scores | Service layer |
| BR-BA-007 | Result integration formula with configurable weightage | Service layer |
| BR-BA-008 | Incident core fields immutable after creation | Service layer |
| BR-BA-009 | All rating changes logged to audit log | Model observer |
| BR-BA-010 | Teacher scope: class teacher (all) vs subject teacher (mapped) | Service layer |
| BR-BA-011 | One config per academic session | DB constraint |
| BR-BA-012 | Unique computed score per (student, category, period) | DB constraint |
| BR-BA-013 | Default seed data provisioned during tenant onboarding | Seeder |
| BR-BA-014 | Assessment grid auto-saves draft every 30 seconds | Frontend |
| BR-BA-015 | Parent notification at or above configured threshold | Service layer |
| BR-BA-016 | Grade boundaries configurable per rating scale | Service layer |
| BR-BA-017 | Weights use proportional calculation (no sum-to-100 requirement) | Service layer |
| BR-BA-018 | Assessment period can optionally link to academic term | Form validation |
| BR-BA-019 | Negative polarity criteria scored inversely | Service layer |
| BR-BA-020 | All entities use soft deletes + audit columns (except audit_log) | DB constraint |

---

## Cross-Module Dependencies

| BA Column | References | PK Type |
|---|---|---|
| `ba_class_category_jnt.class_id` | `sch_classes.id` | INT UNSIGNED |
| `ba_assessment_periods.academic_session_id` | `sch_org_academic_sessions_jnt.id` | SMALLINT UNSIGNED |
| `ba_assessment_periods.academic_term_id` | `sch_academic_term.id` | SMALLINT UNSIGNED |
| `ba_config.academic_session_id` | `sch_org_academic_sessions_jnt.id` | SMALLINT UNSIGNED |
| `ba_assessments.teacher_id` | `sch_employees.id` | INT UNSIGNED |
| `ba_assessments.class_section_id` | `sch_class_section_jnt.id` | INT UNSIGNED |
| `ba_assessments.reviewed_by` | `sch_employees.id` | INT UNSIGNED |
| `ba_assessment_ratings.student_id` | `std_students.id` | INT UNSIGNED |
| `ba_student_remarks.student_id` | `std_students.id` | INT UNSIGNED |
| `ba_computed_scores.student_id` | `std_students.id` | INT UNSIGNED |
| `ba_incidents.student_id` | `std_students.id` | INT UNSIGNED |
| `ba_incidents.reported_by` | `sch_employees.id` | INT UNSIGNED |

---

## Priority Summary

| Priority | Count | Key Items |
|---|---|---|
| **P0** | 3 | Locked period prevents edits (BR-BA-003), Assessment FSM enforcement, Score computation accuracy |
| **P1** | 6 | FormRequests, observers for audit logging, permission enforcement, seed data, DDL alignment |
| **P2** | 4 | Frontend auto-save, drag-and-drop reorder, parent notification channel, PDF export |

---

## Development Phases

| Phase | Sprint | Focus | FRs Covered | Controllers |
|---|---|---|---|---|
| 1 | 1 | Configuration Foundation | BA-001, BA-002, BA-003, BA-004 | RatingScale, Category, Criterion, ClassCategory, AssessmentPeriod, Config |
| 2 | 2–3 | Assessment Workflow | BA-005, BA-006, BA-008 | Assessment, AssessmentReview |
| 3 | 4 | Incident Management | BA-007 | Incident, Intervention |
| 4 | 5–6 | Score Computation & Reports | BA-009, BA-010, BA-011, BA-012, BA-013, BA-014, BA-015 | Report |

## Key Architecture Decisions

1. **No `tenant_id` column** — stancl/tenancy v3.9 uses database-per-tenant isolation.
2. **`ba_class_category_jnt` maps to `sch_classes` directly** — NOT `sch_class_groups_jnt` (which is a subject+study_format junction used by Timetable).
3. **Result integration is pull-based** — Exam/Result module calls `BehaviouralScoreService::getBulkScores()`. BA never writes to `exm_*` tables.
4. **`ba_audit_log` is IMMUTABLE** — no `updated_at`, no `deleted_at`. Append-only.
5. **Negative polarity scores inverted** at service layer: `inverted = (max + 1) - raw`.
6. **`ba_config` is NOT seeded** — created on first access by `BehaviouralConfigService::getConfig()`.
