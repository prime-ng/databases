# adm_EntranceTestCandidates — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Entrance Test Candidates (Register + Marks Entry)
**DB scope:** TENANT-side (`adm_entrance_test_candidates`) · **Test style:** Browser Dusk
**Primary table:** `adm_entrance_test_candidates` · **Module URL prefix:** `/admission/entrance-tests/{id}/candidates`
**Test file:** `adm_EntranceTestCandidates_TestCas.php`

Controller: `EntranceTestCandidateController` (generate list, enter marks, import)

Routes (`adm.` prefix):
- `GET /admission/entrance-tests/{test}/candidates` — candidate list
- `POST /admission/entrance-tests/{test}/candidates/generate` — auto-generate from applications
- `POST /admission/entrance-tests/{test}/candidates` — single add
- `PUT /admission/entrance-test-candidates/{candidate}` — update marks
- `POST /admission/entrance-test-candidates/{candidate}/marks` — bulk/individual marks entry
- `DELETE /admission/entrance-test-candidates/{candidate}` — soft delete

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_entrance_test_candidates`: id (BIGINT PK AI), entrance_test_id (BIGINT UNSIGNED FK → adm_entrance_tests ON DELETE CASCADE), application_id (BIGINT UNSIGNED FK → adm_applications ON DELETE CASCADE), roll_no (VARCHAR 20 NULL), marks_obtained (DECIMAL 6,2 NULL), result (ENUM('Pass','Fail','Absent','Pending') DEFAULT 'Pending'), subject_marks_json (JSON NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. UNIQUE (entrance_test_id, application_id). Indexes: idx_adm_etc_test, idx_adm_etc_app, idx_adm_etc_result | DDL |
| BC-DB-02 | Model `EntranceTestCandidate`: SoftDeletes, casts: marks_obtained→decimal:2, result→string, subject_marks_json→array, is_active→boolean. Relations: entranceTest() belongsTo, application() belongsTo | Model |

### BC-VAL — Validation
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `application_id` required integer exists:adm_applications,id unique per test | FR |
| BC-VAL-02 | `marks_obtained` nullable numeric min:0 max:test.max_marks | FR |
| BC-VAL-03 | `result` required in:Pass,Fail,Absent,Pending | FR |
| BC-VAL-04 | `roll_no` nullable string max:20 | FR |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Generate/marks gate `tenant.adm-entrance-test-candidate.update` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Generate: pulls all Shortlisted applications for the test's cycle+class, creates candidates | Service |
| BC-BIZ-02 | Roll number auto-generated on generation: {test_id}-{seq} | Service |
| BC-BIZ-03 | Marks entry: validates marks_obtained ≤ test.max_marks | Service |
| BC-BIZ-04 | Result auto-set: marks >= passing_marks → Pass, < passing_marks → Fail | Service |
| BC-BIZ-05 | Absent set separately (marks_obtained=NULL, result=Absent) | Ctrl |
| BC-BIZ-06 | Subject marks stored in subject_marks_json as array of {subject, max, marks} | Service |
| BC-BIZ-07 | Marks cannot be modified after test result is used in merit computation | Service |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No eligible applications → generate creates zero candidates | Service |
| BC-EDG-02 | marks_obtained > max_marks → validation error | Val |
| BC-EDG-03 | Regenerate deletes existing candidates before re-creating (idempotent) | Service |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMETC-P10 | Positive | Ctrl | Generate candidates from applications → created with roll_no | Generated | test_adm_etc_10 | Automated |
| TC-ADMETC-P11 | Positive | View | Candidate list: roll_no, application, marks, result badge | Rendered | test_adm_etc_11 | Automated |
| TC-ADMETC-P12 | Positive | Ctrl | Enter marks → marks_obtained stored, result auto-computed | Marked | test_adm_etc_12 | Automated |
| TC-ADMETC-P13 | Positive | Ctrl | Mark absent → result=Absent, marks_obtained=NULL | Absent | test_adm_etc_13 | Automated |
| TC-ADMETC-P14 | Positive | View | Result badges: Pass=success, Fail=danger, Absent=warning, Pending=secondary | Badges | test_adm_etc_14 | Automated |
| TC-ADMETC-N15 | Negative | Val | marks_obtained > max_marks → error | Error | test_adm_etc_15 | Automated |
| TC-ADMETC-N16 | Negative | Val | Duplicate application_id → unique constraint | Error | test_adm_etc_16 | Automated |
