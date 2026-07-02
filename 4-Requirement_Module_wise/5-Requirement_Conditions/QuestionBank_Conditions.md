# Requirement Conditions Catalog — QuestionBank (QNS)

**Module Code:** QNS | **Prefix:** `qns_*` | **DB Layer:** tenant_db
**Date:** 2026-06-30 | **Version:** 1.1 | **Author:** pa-business-analyst
**Source:** `QNS_FRD_Complete_2026-06-30.md` Section 3.2

This catalog records every condition and guard that governs a requirement — including validation rules, visibility conditions, permission guards, and workflow gates. It is the canonical reference for QA test design and FormRequest authoring.

---

## Format Key

| Column | Meaning |
|--------|---------|
| Condition ID | Unique ID; format: `{BR_ID}-C{nn}` |
| Entity / Field | The data entity or UI field this condition applies to |
| Condition (business language) | What must be true for the action to proceed |
| Type | Validation / Permission / Workflow |
| Trigger | The event that evaluates this condition |
| On-Violation Behaviour | What the system does when the condition is not met |

---

## BR-QNS-001 — Taxonomy Completeness Before Review

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| BR-QNS-001-C01 | Bloom's Taxonomy Level | Must be selected before submitting for review | Validation | Submit for review | Error: "Bloom's Taxonomy Level is required." Question stays in Draft. |
| BR-QNS-001-C02 | Cognitive Skill | Must be selected before submitting for review | Validation | Submit for review | Error: "Cognitive Skill is required." Question stays in Draft. |
| BR-QNS-001-C03 | Question Type Specificity | Must be selected before submitting for review | Validation | Submit for review | Error: "Question Type Specificity is required." Question stays in Draft. |
| BR-QNS-001-C04 | Complexity Level | Must be selected before submitting for review | Validation | Submit for review | Error: "Complexity Level is required." Question stays in Draft. |

---

## BR-QNS-002 — MCQ Correct Option Requirements

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| BR-QNS-002-C01 | MCQ options — correct count (any MCQ) | At least one option must be marked as the correct answer | Validation | Question save (MCQ type) | Error: "At least one option must be marked as correct." Save blocked. |
| BR-QNS-002-C02 | MCQ Single — correct count | Exactly one option may be marked correct | Validation | Question save (MCQ Single type) | System auto-deselects the previously marked correct option when a new one is selected; no error shown. |
| BR-QNS-002-C03 | MCQ options — minimum count | MCQ questions must have at least 2 options | Validation | Question save (MCQ type) | Error: "MCQ questions must have at least 2 options." |
| BR-QNS-002-C04 | MCQ options — maximum count | MCQ questions may not exceed 5 options | Validation | Question save (MCQ type) | Error: "MCQ questions may not have more than 5 options." |

---

## BR-QNS-003 — Assessment Picker Visibility

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| BR-QNS-003-C01 | Question Status — assessment picker | Only questions with status Approved or Published may appear in the assessment question picker | Permission | Assessment question picker query (from consuming modules) | Row excluded silently from picker results. |
| BR-QNS-003-C02 | Question availability flags — quiz picker | for_quiz flag must be true for the question to appear in a Quiz builder | Permission | Quiz question picker query | Row excluded silently. |
| BR-QNS-003-C03 | Question availability flags — quest picker | for_quest flag must be true for the question to appear in a Quest builder | Permission | Quest question picker query | Row excluded silently. |
| BR-QNS-003-C04 | Question availability flags — exam picker | for_exam flag must be true for the question to appear in an Exam paper builder | Permission | Exam question picker query | Row excluded silently. |
| BR-QNS-003-C05 | Question availability flags — offline exam | for_offline_exam flag must be true for the question to appear in an Offline Exam paper builder | Permission | Offline Exam picker query | Row excluded silently. |

---

## BR-QNS-004 — Statistics Computation Thresholds

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| BR-QNS-004-C01 | total_attempts | Statistics are only computed when at least 1 attempt exists | Validation | Statistics computation trigger | Update skipped; metrics remain at prior computed value or null. |
| BR-QNS-004-C02 | Discrimination Index — group size | At least 4 attempts must exist in both the top 27% group and the bottom 27% group to compute a valid Discrimination Index | Validation | Statistics computation | discrimination_index stored as null; label: "Insufficient data." |
| BR-QNS-004-C03 | Guessing Factor — attempt threshold | Guessing Factor uses empirical bottom-group rate only if total_attempts ≥ 30; otherwise uses 100 ÷ option count as cold-start estimate | Calculation | Statistics computation (MCQ only) | Cold-start formula applied when total_attempts < 30. |
| BR-QNS-004-C04 | Guessing Factor — question type | Guessing Factor is computed for MCQ questions only | Calculation | Statistics computation | guessing_factor stored as null for all non-MCQ question types. |
| BR-QNS-004-C05 | Time metrics — outlier guard | Time entries of zero seconds or exceeding 3× the expected answer time (or 3600 seconds if no expected time is set) are excluded from time statistics | Calculation | Statistics computation | Outlier records excluded from min/max/avg computation silently. |

---

## BR-QNS-005 — Usage Log — Unused Question Filter

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| BR-QNS-005-C01 | Usage log — context type match | When an assessment is configured to use only previously unused questions, a question is excluded if a usage log entry exists for the same assessment type (Quiz, Quest, Exam, or Offline Exam) | Workflow | Question picker query when unused filter is active | Row excluded silently from picker results. |

---

## BR-QNS-006 — Availability Scope

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| BR-QNS-006-C01 | Availability scope = Global | All teachers on the platform may see and use this question | Permission | Any question list or picker query | No additional filter applied. |
| BR-QNS-006-C02 | Availability scope = School Only | Only teachers at the same school as the creating teacher may see and use this question | Permission | Any question list or picker query | Row excluded if requesting user is from a different school. |
| BR-QNS-006-C03 | Availability scope = Class Only | Only teachers who currently teach the question's linked class may see and use this question | Permission | Any question list or picker query | Row excluded if requesting teacher does not teach the linked class. |
| BR-QNS-006-C04 | Availability scope = Section Only | Only teachers who currently teach the question's linked section may see and use this question | Permission | Any question list or picker query | Row excluded if requesting teacher does not teach the linked section. |
| BR-QNS-006-C05 | Availability scope = Entity (Student Group) Only | Only teachers who currently teach the question's linked student group may see and use this question | Permission | Any question list or picker query | Row excluded if requesting teacher does not teach the linked group. |
| BR-QNS-006-C06 | Availability scope = Student Only | Only teachers who currently teach the question's linked student may see and use this question | Permission | Any question list or picker query | Row excluded if requesting teacher does not teach the linked student. |

---

## BR-QNS-007 — Platform Content Edit Protection

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| BR-QNS-007-C01 | content_owner = Platform Content — edit | School teachers cannot edit a question whose Content Owner is "Platform Content" | Permission | Edit action on a question | Error: "This question is owned by the platform and cannot be edited. Use Clone to create your own copy." |
| BR-QNS-007-C02 | content_owner = Platform Content — delete | School teachers cannot delete a question whose Content Owner is "Platform Content" | Permission | Delete action on a question | Error: "This question is owned by the platform and cannot be deleted." |
| BR-QNS-007-C03 | Clone — not identical | A cloned question must differ from the original in at least one content field | Validation | Clone save action | Error: "The cloned question must differ from the original." |

---

## BR-QNS-008 — AI-Generated Question Review Gate

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| BR-QNS-008-C01 | created_by_AI = 1 — bypass In Review | AI-generated questions cannot have their status changed to Approved or Published while still in Draft status — they must pass through the In Review stage | Workflow | Any status change action on an AI-generated question in Draft | Transition blocked: "AI-generated questions must go through review before approval." |
| BR-QNS-008-C02 | created_by_AI = 1 — admin shortcut blocked | Not even a School Admin may fast-track an AI-generated question from Draft to Approved | Permission | Admin status change action | Same block as C01; admin shortcut is suppressed for AI-generated questions. |

---

## BR-QNS-009 — Version Snapshot Trigger

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| BR-QNS-009-C01 | Edit — content fields changed | A version snapshot of the prior state must be saved before any edit that changes question_content, content_format, marks, negative_marks, question_type_id, or any option (text, correctness, or order) | Workflow | Question save (edit path), when content fields differ from stored value | Snapshot inserted into version history; version counter incremented. If snapshot insert fails, edit is rolled back. |
| BR-QNS-009-C02 | Edit — status change only | If an edit action changes only the question's status (no content, option, or marks fields change), no version snapshot is created | Workflow | Status change (not via content edit form) | No snapshot created; version counter unchanged. |
| BR-QNS-009-C03 | Edit — student attempts exist | If at least one student has submitted a response to this question, the content edit form is blocked entirely | Permission | Edit action | Error: "This question cannot be edited because it has been answered by students. Use Clone to create a variant." |

---

## BR-QNS-010 — Negative Marks Range

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| BR-QNS-010-C01 | negative_marks — minimum | Negative marks must be ≥ 0 | Validation | Question save | Error: "Negative marks cannot be negative." |
| BR-QNS-010-C02 | negative_marks — ceiling | Negative marks must be strictly less than the question's marks value | Validation | Question save | Error: "Negative marks must be less than the question's marks value." |

---

## BR-QNS-011 — Review Rejection Comment

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| BR-QNS-011-C01 | review_comment — required on rejection | When a reviewer selects the Reject action, the review comment field must be non-empty | Validation | Reject action on review | Error: "A comment is required when rejecting a question." Rejection blocked until comment is entered. |
| BR-QNS-011-C02 | Concurrent review | If two reviewers both attempt to review the same question at the same time, only the first action succeeds | Workflow | Approve or Reject action when review is already resolved | Error to second reviewer: "This question has already been reviewed by another reviewer." |

---

## BR-QNS-012 — Topic Weightage Sum

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| BR-QNS-012-C01 | Topic weightage total | When a question is mapped to more than one topic, the sum of all weightage values should equal 100 | Validation (soft) | Question save with multiple topic entries | Warning shown: "Topic weightages currently sum to [X]. Consider adjusting to total 100." Save proceeds. |

---

## Non-BR Conditions (Platform-Level Rules)

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|---------------------|------|---------|----------------------|
| PLAT-QNS-C01 | AI generation — rate limit | A user may not submit more than 10 AI question generation requests within any 60-second window | Permission (rate limit) | AI generation POST request | HTTP 429: "Too many requests — please wait before generating more questions." |
| PLAT-QNS-C02 | AI generation — count per request | A single AI generation request may specify between 1 and 20 questions | Validation | AI generation POST request | Error: "Please request between 1 and 20 questions per generation." |
| PLAT-QNS-C03 | Import — row limit | An Excel import file may not contain more than 500 question rows | Validation | File upload / validate step | Error: "Import file cannot exceed 500 questions. Please split the file." |
| PLAT-QNS-C04 | Import — duplicate check | Questions already existing in the bank (matched by title hash, LOWER normalized) are skipped, not duplicated | Validation | Import commit step | Skipped rows reported in import summary; no error for individual duplicates. |
| PLAT-QNS-C05 | Textbook page reference | The page number reference cannot exceed the linked textbook's total page count | Validation | Question save when textbook and page number are provided | Error: "Page reference cannot exceed the book's total pages." |
| PLAT-QNS-C06 | Module access guard | Only tenants with an active QuestionBank module license may access any Question Bank route | Permission | All route requests in /question-bank/* | HTTP 403 with "You do not have access to the Question Bank module." |
