# STP — Exam Grievances (stp_ExamGrievances) — TC List

## 1. TC List ID
`stp_ExamGrievances_TC`

## 2. Feature Name
Exam Grievances / My Grievances

## 3. Module Code
`stp_ExamGrievances` — StudentPortal

## 4. FRD REQ Mapping
REQ-STP-033, BR-STP-029, BR-STP-030

## 5. Route / Endpoint Coverage

| # | TC ID | Route | Method | Test Scenario | Input / Condition | Expected Result | Priority | Status |
|---|-------|-------|--------|---------------|-------------------|----------------|----------|--------|
| 1 | GRE-001 | GET /my-grievances | GET | Student with no grievances views empty list | No grievances filed | Empty grievance list displayed; counts all zero | P0 | ⬜ |
| 2 | GRE-002 | GET /my-grievances | GET | Student with multiple grievances views list | 2+ grievances in various statuses | All grievances displayed with type, status badge, exam details, resolution info | P0 | ⬜ |
| 3 | GRE-003 | GET /my-grievances | GET | Grievance list shows correct summary counts | 2 OPEN, 1 RESOLVED, 1 REJECTED | openCount = 2, resolvedCount = 1, rejectedCount = 1 | P0 | ⬜ |
| 4 | GRE-004 | GET /my-grievances | GET | Resolved grievance shows marks_changed details | Grievance with marks_changed = true | old_marks, new_marks, resolution_remarks, resolved_at displayed | P0 | ⬜ |
| 5 | GRE-005 | GET /my-grievances | GET | Resolved grievance without marks change | marks_changed = false | Resolution remarks shown; marks_changed not displayed | P1 | ⬜ |
| 6 | GRE-006 | GET /my-grievances | GET | Grievance with rejected status | status = REJECTED | Red status badge; rejection reason in resolution_remarks | P0 | ⬜ |
| 7 | GRE-007 | GET /my-grievances | GET | Paper title resolved correctly | Exam result references valid exam paper + exam + subject | Paper title shown as "Exam Name — Subject Name" | P1 | ⬜ |
| 8 | GRE-008 | GET /my-grievances | GET | Orphan grievance (no exam result) | Exam result deleted (soft) | paper_title = '—' gracefully handled | P2 | ⬜ |
| 9 | GRE-009 | GET /online-exam/{id}/grievance/create | GET | View grievance create form | Valid exam paper ID with existing result | Form displayed: grievance type dropdown, question selector, description textarea | P0 | ⬜ |
| 10 | GRE-010 | GET /online-exam/{id}/grievance/create | GET | No exam result found for paper | Paper ID has no result record for this student | Redirect to exam result with error: "No result found to file a grievance against." | P0 | ⬜ |
| 11 | GRE-011 | GET /online-exam/{id}/grievance/create | GET | Grievance already filed — form shows existing state | Existing grievance for this result | existing variable populated; form may show disabled state or message | P0 | ⬜ |
| 12 | GRE-012 | GET /online-exam/{id}/grievance/create | GET | Questions loaded for optional selection | Paper set has 10 questions | Question dropdown populated with question text | P1 | ⬜ |
| 13 | GRE-013 | GET /online-exam/{id}/grievance/create | GET | No paper set found — empty question list | Paper has no paper set | Question dropdown empty or hidden | P1 | ⬜ |
| 14 | GRE-014 | GET /online-exam/{id}/grievance/create | GET | Exam title resolved correctly | Valid exam_paper → exam relationship | Exam title displayed on form | P1 | ⬜ |
| 15 | GRE-015 | POST /online-exam/{id}/grievance | POST | File grievance successfully (MARKING_ERROR) | grievance_type = MARKING_ERROR, valid text ≥ 20 chars, no question_id | Grievance created with status = OPEN; redirect to my-grievances with success message | P0 | ⬜ |
| 16 | GRE-016 | POST /online-exam/{id}/grievance | POST | File grievance with question reference | grievance_type = QUESTION_ERROR, question_id = valid ID | Grievance created with question_id set | P0 | ⬜ |
| 17 | GRE-017 | POST /online-exam/{id}/grievance | POST | File grievance — OUT_OF_SYLLABUS type | grievance_type = OUT_OF_SYLLABUS, valid text | Grievance created with correct type | P0 | ⬜ |
| 18 | GRE-018 | POST /online-exam/{id}/grievance | POST | File grievance — OTHER type | grievance_type = OTHER, valid text | Grievance created with correct type | P0 | ⬜ |
| 19 | GRE-019 | POST /online-exam/{id}/grievance | POST | Duplicate grievance blocked | Same exam_result_id, second POST | Redirect to my-grievances with warning: "already filed a grievance" | P0 | ⬜ |
| 20 | GRE-020 | POST /online-exam/{id}/grievance | POST | No exam result found for paper | Paper with no result record | Redirect to exam result with error: "No result found." | P0 | ⬜ |
| 21 | GRE-021 | POST /online-exam/{id}/grievance | POST | Invalid grievance type | grievance_type = 'INVALID_TYPE' | 422 validation error | P0 | ⬜ |
| 22 | GRE-022 | POST /online-exam/{id}/grievance | POST | Grievance text too short ( < 20 chars) | grievance_text = "Short text" | 422 validation error: "at least 20 characters" | P0 | ⬜ |
| 23 | GRE-023 | POST /online-exam/{id}/grievance | POST | Grievance text too long ( > 2000 chars) | grievance_text = 2001+ characters | 422 validation error: "may not be greater than 2000 characters" | P0 | ⬜ |
| 24 | GRE-024 | POST /online-exam/{id}/grievance | POST | Empty grievance text | grievance_text = '' | 422 validation error | P0 | ⬜ |
| 25 | GRE-025 | POST /online-exam/{id}/grievance | POST | Grievance type not provided | Missing grievance_type field | 422 validation error | P0 | ⬜ |
| 26 | GRE-026 | POST /online-exam/{id}/grievance | POST | Invalid question_id | question_id = 999999 (non-existent) | 422 validation error: selected question_id does not exist | P0 | ⬜ |
| 27 | GRE-027 | — | — | Grievance FSM: OPEN status created on submit | After successful store() | status = 'OPEN'; is_active = true; no resolved_at set | P0 | ⬜ |
| 28 | GRE-028 | — | — | Admin resolves with marks change | Admin action (admin panel) | marks_changed = true; old_marks and new_marks recorded | P1 | ⬜ |
| 29 | GRE-029 | — | — | Admin rejects grievance | Admin rejection | status = REJECTED; resolution_remarks recorded | P1 | ⬜ |

## 6. Business Rules Coverage

| BR-ID | Coverage | TC IDs |
|-------|----------|--------|
| BR-STP-029 (Eligibility) | Covered | GRE-010, GRE-020 |
| BR-STP-030 (One per result) | Covered | GRE-011, GRE-019 |

## 7. Validation Coverage

| Validation | Type | TC IDs |
|-----------|------|--------|
| Grievance type must be valid | Enum | GRE-021, GRE-025 |
| Grievance text min 20 chars | Length | GRE-022, GRE-024 |
| Grievance text max 2000 chars | Length | GRE-023 |
| Question ID must exist in DB | Existence | GRE-026 |
| One grievance per result | Uniqueness | GRE-011, GRE-019 |
| Exam result must exist | Existence | GRE-010, GRE-020 |

## 8. FSM Coverage

| Transition | TC IDs |
|-----------|--------|
| (new) → OPEN | GRE-015, GRE-016, GRE-017, GRE-018, GRE-027 |
| OPEN → UNDER_REVIEW | GRE-028 (admin) |
| UNDER_REVIEW → RESOLVED (no change) | (admin action) |
| UNDER_REVIEW → RESOLVED (marks changed) | GRE-028 |
| UNDER_REVIEW → REJECTED | GRE-029 |

## 9. Concurrency Coverage

| Scenario | TC IDs |
|----------|--------|
| Double grievance submission | GRE-019 |
| Simultaneous file + resolve | (hard to reproduce — no explicit lock) |

## 10. Error / Exception Coverage

| Scenario | TC IDs |
|----------|--------|
| 302 — No exam result found | GRE-010, GRE-020 |
| 302 — Grievance already filed | GRE-011, GRE-019 |
| 422 — Invalid grievance type | GRE-021, GRE-025 |
| 422 — Text too short | GRE-022, GRE-024 |
| 422 — Text too long | GRE-023 |
| 422 — Invalid question_id | GRE-026 |

---
*Generated from: `StudentGrievanceController.php`, `ExamGrievance.php`, `STP_FRD_Complete_2026-06-30.md`, `pgdatabase/Backup/4-Module_Requirement/StudentPortal/examinations/my_grievances.md`*
