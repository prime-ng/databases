# PROMPT: Build Student Goals & Aspirations Screen — HPC Module
**Task ID:** P3_33
**Issue IDs:** SC-14
**Priority:** P3-Low
**Estimated Effort:** 2 days
**Prerequisites:** P3_27 (Student Portal)

---

## CONFIGURATION
```
MODULE_PATH    = /Users/bkwork/Herd/prime_ai/Modules/Hpc
ROUTES_FILE    = /Users/bkwork/Herd/prime_ai/routes/tenant.php
```

---

## CONTEXT

Blueprint SC-14 defines a student-facing goal setting interface: T4 pages 2-9 include self-evaluation, goals, time management, plans after school, future self, accomplishments, and skills for life. This screen provides a guided, step-by-step experience (not a long scrollable form).

---

## PRE-READ (Mandatory)

1. Gap analysis T4 pages 2-9 field inventory (~120 fields)
2. Existing form partials for T4 Part A pages

---

## STEPS

1. Create `StudentGoalsController` as part of the student portal (from P3_27)
2. Create a wizard-style multi-step form (8 steps, one per page)
3. Each step has appropriate input types: Likert scales, text areas, drawing upload, checkbox grids
4. Progress indicator showing completion across all 8 steps
5. Save progress at each step (no data loss if student navigates away)
6. Final submit marks goals section as complete
7. Add routes under `/hpc/student/goals/`

---

## ACCEPTANCE CRITERIA

- 8-step wizard guides student through all Part A pages
- Progress saved per step
- All field types render correctly (Likert, drawing, text, checkboxes)
- Data feeds into HPC report pages 2-9
- Works on tablet (students often use school tablets)

---

## DO NOT

- Do NOT build this as a single long form — use wizard steps
- Do NOT modify teacher-facing forms
