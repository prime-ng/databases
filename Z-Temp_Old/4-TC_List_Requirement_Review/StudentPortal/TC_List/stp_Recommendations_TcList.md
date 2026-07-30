# STP — Recommendations (stp_Recommendations) — TC List

## 1. TC List ID
`stp_Recommendations_TC`

## 2. Feature Name
Recommendations / My Recommendations

## 3. Module Code
`stp_Recommendations` — StudentPortal

## 4. FRD REQ Mapping
REQ-STP-017, BR-STP-001

## 5. Route / Endpoint Coverage

| # | TC ID | Route | Method | Test Scenario | Input / Condition | Expected Result | Priority | Status |
|---|-------|-------|--------|---------------|-------------------|----------------|----------|--------|
| 1 | REC-001 | GET /my-recommendations | GET | Student with recommendations views list | Student has multiple recommendations from various sources | Tab filters (All/Quiz/Quest/Manual) displayed; recommendation cards with type, purpose, status, subject, topic, date | P0 | ⬜ |
| 2 | REC-002 | GET /my-recommendations | GET | Student with no recommendations views empty list | No recommendations assigned | Empty state displayed; all count = 0 | P0 | ⬜ |
| 3 | REC-003 | GET /my-recommendations | GET | Auto-syncs class recommendations on load | Class has RecommendationMaterial records not yet assigned to student | New StudentRecommendation records created with PENDING status | P0 | ⬜ |
| 4 | REC-004 | GET /my-recommendations | GET | Class sync skips already-existing materials | Student already has recommendation for a class material | No duplicate created (exists() check) | P0 | ⬜ |
| 5 | REC-005 | GET /my-recommendations | GET | Class sync with section filtering | Material has section_id set → only students in that section get it | Section filter applied correctly | P1 | ⬜ |
| 6 | REC-006 | GET /my-recommendations | GET | Class sync failure is non-fatal | syncClassRecommendations throws exception | Page loads normally; error logged; no crash | P1 | ⬜ |
| 7 | REC-007 | GET /my-recommendations | GET | Quiz-triggered tab shows only quiz recommendations | Student has recommendations with triggered_by_quiz_id set | Quiz tab count = filtered results | P0 | ⬜ |
| 8 | REC-008 | GET /my-recommendations | GET | Quest-triggered tab shows only quest recommendations | Student has recommendations with triggered_by_quest_id set | Quest tab count = filtered results | P0 | ⬜ |
| 9 | REC-009 | GET /my-recommendations | GET | Manual tab shows teacher-assigned only | Recommendations with both triggered_by null | Manual tab count = filtered results | P0 | ⬜ |
| 10 | REC-010 | GET /my-recommendations | GET | Student profile missing returns 403 | auth user has no Student relation | 403 Forbidden: "Student profile not found." | P0 | ⬜ |
| 11 | REC-011 | GET /my-recommendations/{id} | GET | View recommendation detail — auto-views PENDING | Recommendation status = PENDING | Status auto-changed to VIEWED; full detail shown with material info, bundle, trigger | P0 | ⬜ |
| 12 | REC-012 | GET /my-recommendations/{id} | GET | View recommendation detail — no status change if already VIEWED | Recommendation status = VIEWED | Status remains VIEWED | P0 | ⬜ |
| 13 | REC-013 | GET /my-recommendations/{id} | GET | View recommendation detail — IN_PROGRESS status unchanged | Recommendation status = IN_PROGRESS | Status unchanged | P1 | ⬜ |
| 14 | REC-014 | GET /my-recommendations/{id} | GET | View recommendation detail — COMPLETED status unchanged | Recommendation status = COMPLETED | Status unchanged | P1 | ⬜ |
| 15 | REC-015 | GET /my-recommendations/{id} | GET | Recommendation not found (wrong ID) | ID does not exist or belongs to another student | 404 Not Found | P0 | ⬜ |
| 16 | REC-016 | GET /my-recommendations/{id} | GET | Recommendation soft-deleted | is_active = false | 404 Not Found (findOrFail) | P1 | ⬜ |
| 17 | REC-017 | GET /my-recommendations/{id} | GET | Detail shows bundle materials | Recommendation belongs to a bundle | Bundle materials listed with types | P1 | ⬜ |
| 18 | REC-018 | GET /my-recommendations/{id} | GET | Detail shows quiz trigger info | triggered_by_quiz relationship loaded | Trigger quiz details displayed | P1 | ⬜ |
| 19 | REC-019 | GET /my-recommendations/{id} | GET | Detail shows quest trigger info | triggered_by_quest relationship loaded | Trigger quest details displayed | P1 | ⬜ |
| 20 | REC-020 | GET /my-recommendations/{id} | GET | Detail shows rule and event info | recommendation_rule + triggerEvent + recommendationMode loaded | Rule details displayed | P2 | ⬜ |
| 21 | REC-021 | POST /my-recommendations/{id}/status | POST | Update status to VIEWED | status = 'VIEWED' | Status updated; success message displayed | P0 | ⬜ |
| 22 | REC-022 | POST /my-recommendations/{id}/status | POST | Update status to IN_PROGRESS | status = 'IN_PROGRESS' | Status updated; success message displayed | P0 | ⬜ |
| 23 | REC-023 | POST /my-recommendations/{id}/status | POST | Update status to COMPLETED | status = 'COMPLETED' | Status updated; success message displayed | P0 | ⬜ |
| 24 | REC-024 | POST /my-recommendations/{id}/status | POST | Invalid status value rejected | status = 'REJECTED' | 422 validation error | P0 | ⬜ |
| 25 | REC-025 | POST /my-recommendations/{id}/status | POST | Missing status field | No status parameter | 422 validation error | P0 | ⬜ |
| 26 | REC-026 | POST /my-recommendations/{id}/status | POST | Update another student's recommendation | recommendation belongs to another student | 404 Not Found (findOrFail scoped to student) | P0 | ⬜ |
| 27 | REC-027 | POST /my-recommendations/{id}/status | POST | Student profile missing | No student relation | 403 Forbidden | P0 | ⬜ |
| 28 | REC-028 | POST /my-recommendations/{id}/rate | POST | Rate recommendation (5 stars with feedback) | rating = 5, feedback = "Great material!" | Rating saved; success message: "Rating saved. Thank you!" | P0 | ⬜ |
| 29 | REC-029 | POST /my-recommendations/{id}/rate | POST | Rate recommendation (1 star, no feedback) | rating = 1, feedback = null | Rating saved; feedback recorded as null | P0 | ⬜ |
| 30 | REC-030 | POST /my-recommendations/{id}/rate | POST | Rate recommendation (3 stars, empty feedback string) | rating = 3, feedback = '' | Rating saved; feedback stored as null | P1 | ⬜ |
| 31 | REC-031 | POST /my-recommendations/{id}/rate | POST | Invalid rating (0) | rating = 0 | 422 validation error (min:1) | P0 | ⬜ |
| 32 | REC-032 | POST /my-recommendations/{id}/rate | POST | Invalid rating (6) | rating = 6 | 422 validation error (max:5) | P0 | ⬜ |
| 33 | REC-033 | POST /my-recommendations/{id}/rate | POST | Non-integer rating | rating = 'abc' | 422 validation error (integer) | P0 | ⬜ |
| 34 | REC-034 | POST /my-recommendations/{id}/rate | POST | Feedback exceeds 255 chars | feedback = 256+ characters | 422 validation error (max:255) | P0 | ⬜ |
| 35 | REC-035 | POST /my-recommendations/{id}/rate | POST | Missing rating field | No rating parameter | 422 validation error | P0 | ⬜ |
| 36 | REC-036 | POST /my-recommendations/{id}/rate | POST | Rate another student's recommendation | recommendation belongs to another student | 404 Not Found | P0 | ⬜ |
| 37 | REC-037 | POST /my-recommendations/{id}/rate | POST | Re-rate (update existing rating) | Second POST with different rating | Rating updated to new value | P1 | ⬜ |
| 38 | REC-038 | — | — | Class sync runs on index AND show | Both GET routes accessed | syncClassRecommendations called both times | P1 | ⬜ |
| 39 | REC-039 | — | — | Student with no current session — class sync skipped | student->currentSession returns null | Sync gracefully skipped; no error | P1 | ⬜ |
| 40 | REC-040 | — | — | Student with session but no classSection | currentSession exists but classSection is null | Sync gracefully skipped; no error | P1 | ⬜ |

## 6. Business Rules Coverage

| BR-ID | Coverage | TC IDs |
|-------|----------|--------|
| BR-STP-001 (Ownership) | Covered | REC-015, REC-016, REC-026, REC-036 |

## 7. Validation Coverage

| Validation | Type | TC IDs |
|-----------|------|--------|
| Status must be VIEWED/IN_PROGRESS/COMPLETED | Enum | REC-024, REC-025 |
| Rating must be integer 1-5 | Range | REC-031, REC-032, REC-033, REC-035 |
| Feedback max 255 chars | Length | REC-034 |
| Recommendation ownership | Permission | REC-015, REC-026, REC-036 |
| Student profile existence | Security | REC-010, REC-027 |

## 8. FSM Coverage

| Transition | TC IDs |
|-----------|--------|
| PENDING → VIEWED (auto on detail view) | REC-011 |
| PENDING → VIEWED (manual status update) | REC-021 |
| VIEWED → IN_PROGRESS | REC-022 |
| IN_PROGRESS → COMPLETED | REC-023 |

## 9. Concurrency Coverage

| Scenario | TC IDs |
|----------|--------|
| Simultaneous status update | (no explicit lock — last write wins) |
| Duplicate class sync | REC-004 |
| Re-rating (update) | REC-037 |

## 10. Error / Exception Coverage

| Scenario | TC IDs |
|----------|--------|
| 403 — Missing student profile | REC-010, REC-027 |
| 404 — Recommendation not found / not owned | REC-015, REC-016, REC-026, REC-036 |
| 422 — Invalid status | REC-024, REC-025 |
| 422 — Invalid rating (0, 6, non-integer) | REC-031, REC-032, REC-033, REC-035 |
| 422 — Feedback too long | REC-034 |
| Non-fatal class sync failure | REC-006, REC-039, REC-040 |

---
*Generated from: `StudentRecommendationPortalController.php`, `STP_FRD_Complete_2026-06-30.md`, `pgdatabase/Backup/4-Module_Requirement/StudentPortal/my_reports/recommendations.md`*
