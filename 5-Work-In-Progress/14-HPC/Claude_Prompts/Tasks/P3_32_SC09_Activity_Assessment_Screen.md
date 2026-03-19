# PROMPT: Build Activity Assessment Screen — HPC Module
**Task ID:** P3_32
**Issue IDs:** SC-09
**Priority:** P3-Low
**Estimated Effort:** 3 days
**Prerequisites:** P3_27 (Student Portal)

---

## CONFIGURATION
```
MODULE_PATH    = /Users/bkwork/Herd/prime_ai/Modules/Hpc
ROUTES_FILE    = /Users/bkwork/Herd/prime_ai/routes/tenant.php
```

---

## CONTEXT

Blueprint SC-09 defines an Activity Assessment Screen: a dedicated interface for activity-cycle assessments (T3 has 9 cycles, T4 has 8 cycles) with toggles showing teacher/self/peer views side-by-side. Currently activity assessment is embedded in the sequential form pages.

---

## PRE-READ (Mandatory)

1. Gap analysis T3/T4 activity cycle structure (4 pages per cycle: Activity Tab, Self-Reflection, Peer Feedback, Teacher Feedback)
2. Existing form partials for activity cycles

---

## STEPS

1. Create `HpcActivityAssessmentController`
2. Create tabbed view: activity cycle selector → 4-panel layout (teacher/self/peer/summary)
3. Teacher panel: editable assessment and feedback
4. Self/Peer panels: read-only view of student/peer submissions (from P3_27/P3_29)
5. Summary panel: aggregated rubric scores across all actors
6. Add routes under `/hpc/activity-assessment/`

---

## ACCEPTANCE CRITERIA

- Teacher can see all 4 perspectives for each activity cycle in one screen
- Activity cycles are selectable via tabs or dropdown
- Rubric scores aggregate correctly across teacher/self/peer
- Editable only for teacher sections

---

## DO NOT

- Do NOT duplicate data storage — reference existing form data
- Do NOT modify PDF templates
