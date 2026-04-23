# BA — Table Summary (16 tables)

| # | Table | Layer | Domain | Description |
|---|---|---|---|---|
| 1 | `ba_rating_scales` | L1 | Rating Config | Rating scales (e.g., 5-Point) with grade boundaries JSON |
| 2 | `ba_categories` | L1 | Category | Behavioural categories with polarity (positive/negative) and weights |
| 3 | `ba_interventions` | L1 | Master Data | Predefined intervention types (reward/corrective/counselling) |
| 4 | `ba_rating_levels` | L2 | Rating Config | Individual levels within a scale (label, numeric value, sort order) |
| 5 | `ba_criteria` | L2 | Category | Observable criteria within a category with weights |
| 6 | `ba_class_category_jnt` | L3 | Category | Junction: maps categories to sch_classes for class-level applicability |
| 7 | `ba_assessment_periods` | L3 | Assessment | Assessment windows with dates, deadline, and open/closed/locked lifecycle |
| 8 | `ba_config` | L3 | Configuration | School-level config per session: scale, weightage, aggregation, notification threshold |
| 9 | `ba_assessments` | L4 | Assessment | Header record per teacher per class-section per period (FSM: draft→submitted→reviewed→locked) |
| 10 | `ba_audit_log` | L4 | Audit | Immutable audit trail for rating changes (no updated_at, no deleted_at) |
| 11 | `ba_assessment_ratings` | L5 | Assessment | Core fact table: one rating per student per criterion per assessment |
| 12 | `ba_student_remarks` | L5 | Assessment | Overall teacher remark per student per assessment |
| 13 | `ba_computed_scores` | L5 | Computation | Cached computed scores per student per category per period |
| 14 | `ba_incidents` | L5 | Incident | Behavioural incident records with severity, location, follow-up, attachments |
| 15 | `ba_incident_witnesses_jnt` | L6 | Incident | Junction: polymorphic witnesses (student/staff) for incidents |
| 16 | `ba_incident_intervention_jnt` | L6 | Incident | Junction: maps incidents to interventions applied |

## Cross-Module FK Summary

| ba_* Column | References | PK Type |
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


## Summary Stats

┌────────────────────────┬─────────────────────────────────────────────────────────────────────┐
│         Metric         │                                Count                                │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ Tables                 │ 16 (ba_*) in 6 dependency layers                                    │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ Controllers            │ 11                                                                  │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ Services               │ 5                                                                   │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ FormRequests           │ 17                                                                  │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ Policies               │ 9                                                                   │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ Livewire Components    │ 9                                                                   │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ Routes                 │ 58                                                                  │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ Blade Views            │ ~55                                                                 │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ Events                 │ 5                                                                   │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ Business Rules         │ 20                                                                  │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ FSMs                   │ 2 (Assessment + Period)                                             │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ Seeders                │ 4 (1 scale + 5 levels, 9 categories + 58 criteria, 9 interventions) │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ Feature Tests          │ ~40 across 8 files                                                  │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ Unit Tests             │ ~15 across 4 files                                                  │
├────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ Implementation Sprints │ 4 phases (6 sprints)                                                │
└────────────────────────┴─────────────────────────────────────────────────────────────────────┘

Development lifecycle for the BA (Behavioural Assessment) module is ready to begin.

