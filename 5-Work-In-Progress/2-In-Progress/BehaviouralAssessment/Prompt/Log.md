

## Report design created. Here's a summary of what was generated:

┌─────┬──────────────────────────────────┬──────────────────────────────────────────────────────────────────────────────────────────────┬───────────────────────┐
  │  #  │              Report              │                                       Key Data Sources                                       │       Audience        │
  ├─────┼──────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────┤
  │ 1   │ Student Behaviour Summary        │ ba_computed_scores, ba_assessment_ratings, ba_student_remarks, ba_incidents                  │ Teachers, Parents     │
  ├─────┼──────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────┤
  │ 2   │ Class-Section Behaviour Analysis │ ba_computed_scores, ba_incidents, ba_assessments                                             │ Class Teachers, HODs  │
  ├─────┼──────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────┤
  │ 3   │ Incident Log & Intervention      │ ba_incidents, ba_incident_witnesses_jnt, ba_incident_intervention_jnt, ba_interventions      │ Admin, Counsellors    │
  ├─────┼──────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────┤
  │ 4   │ Category & Criteria Performance  │ ba_computed_scores, ba_assessment_ratings, ba_categories, ba_criteria, ba_class_category_jnt │ HODs, Curriculum Team │
  ├─────┼──────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────┤
  │ 5   │ Teacher Assessment Progress      │ ba_assessments, ba_assessment_ratings, ba_audit_log, ba_assessment_periods                   │ Principal, Admin      │
  ├─────┼──────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────┤
  │ 6   │ Behavioural Trend Analysis       │ ba_computed_scores, ba_incidents, ba_config                                                  │ Management            │
  ├─────┼──────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────┤
✻ │ 7   │ Parent Communication Report      │ ba_computed_scores, ba_student_remarks, ba_incidents (sanitised)                             │ Parents/Guardians     │
  ├─────┼──────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────┤
──│ 8   │ Executive Dashboard              │ All 16 ba_* tables aggregated                                                                │ Principal, Management │──────────────────────────────────────────────────
❯ └─────┴──────────────────────────────────┴──────────────────────────────────────────────────────────────────────────────────────────────┴───────────────────────┘