# PROMPT: Build Peer Assessment Workflow — HPC Module
**Task ID:** P3_29
**Issue IDs:** GAP-3, SC-13
**Priority:** P3-Low
**Estimated Effort:** 4 days
**Prerequisites:** All P2 tasks complete, P3_27 (Student Portal) recommended

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
ROUTES_FILE    = {LARAVEL_REPO}/routes/tenant.php
```

---

## CONTEXT

14 sections across HPC templates require peer feedback (peer assessment emojis, peer feedback pages with 6 statements each). T2 has dedicated peer pages (2 peers per student), T3/T4 have peer feedback within each activity cycle. The workflow needs: teacher assigns peer pairs, students fill peer feedback sections, responses are anonymized and aggregated into the report.

### Schema Changes
- New table: `hpc_peer_assignments` — student_id, peer_student_id, report_id, cycle_number, status, assigned_by
- New table: `hpc_peer_responses` — assignment_id, section_item_id, value, submitted_at

### Routes
- `GET /hpc/student/peer-review/{assignment_id}` — Peer review form (student fills about assigned peer)
- `POST /hpc/student/peer-review/{assignment_id}` — Save peer review
- `POST /hpc/teacher/assign-peers/{report_id}` — Teacher assigns peer pairs
- `GET /hpc/teacher/peer-status/{report_id}` — Teacher views peer completion

---

## PRE-READ (Mandatory)

1. Gap analysis peer sections: T2 pages 4-5 (2 named peers), T3 pages 7,11,15,19,23,27,31,35,39 (9 cycles), T4 pages 12,16,20,24,28,32,36,40 (8 cycles)
2. `{MODULE_PATH}/resources/views/hpc_form/` — peer feedback blade partials

---

## STEPS

1. Create migrations for `hpc_peer_assignments` and `hpc_peer_responses`
2. Create `PeerAssignmentService` — auto-assign peers (random within class section, or teacher-selected)
3. Create `PeerHpcFormController` — form view and save for peer feedback
4. Student sees "Peer Reviews to Complete" on their dashboard (from P3_27)
5. Peer form shows only peer-tagged sections with emoji selectors
6. On completion, aggregate peer responses into the target student's report
7. Teacher dashboard shows peer completion matrix (who reviewed whom)

---

## ACCEPTANCE CRITERIA

- Teacher can assign 2 peers per student (T2) or 1 peer per activity cycle (T3/T4)
- Students see peer review tasks on their dashboard
- Peer feedback is saved and linked to the correct student's report
- Aggregated peer data appears in PDF generation
- Teacher can view completion status of all peer reviews

---

## DO NOT

- Do NOT expose peer reviewer identity to the reviewed student
- Do NOT modify existing teacher feedback pages
- Do NOT change the PDF template structure
