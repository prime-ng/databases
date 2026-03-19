# PROMPT: Build Parent Portal Screens — HPC Module
**Task ID:** P3_34
**Issue IDs:** SC-15, SC-16, SC-17
**Priority:** P3-Low
**Estimated Effort:** 5 days
**Prerequisites:** P3_28 (Parent Data Collection)

---

## CONFIGURATION
```
MODULE_PATH    = /Users/bkwork/Herd/prime_ai/Modules/Hpc
ROUTES_FILE    = /Users/bkwork/Herd/prime_ai/routes/tenant.php
```

---

## CONTEXT

3 blueprint screens for parents: SC-15 (Parent Dashboard — overview of child's HPC progress), SC-16 (Parent Input Form — questionnaire and resource indicators), SC-17 (Parent-Teacher Communication — messaging about HPC reports). The parent data collection mechanism (P3_28) provides the signed URL infrastructure; this task builds the full parent experience.

---

## PRE-READ (Mandatory)

1. P3_28 implementation (parent token system)
2. Gap analysis parent sections per template

---

## STEPS

1. **SC-15 Dashboard:** Create parent dashboard showing child's HPC status, completion progress, previous reports
2. **SC-16 Input Form:** Enhance the basic parent form from P3_28 with better UX — home resources checklist, 11 questionnaire items with emoji selectors, support needs checkboxes
3. **SC-17 Communication:** Add simple comment/message system between parent and class teacher on the HPC report
4. Add a "View Published Report" feature for parents to see the final PDF
5. All screens accessible via signed URL (no login required)

---

## ACCEPTANCE CRITERIA

- Parent dashboard shows child's HPC overview
- Input form covers all parent sections (T1: 6 embedded, T2: pages 6-7, T3: page 4)
- Parent can leave comments for teacher
- Teacher can respond to parent comments
- Published PDF viewable by parent

---

## DO NOT

- Do NOT build a full parent account system
- Do NOT implement real-time chat — simple threaded comments are sufficient
