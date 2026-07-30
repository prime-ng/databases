# adm_PromotionRecords — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Promotion Records (Per-Student Promotion Results)
**DB scope:** TENANT-side (`adm_promotion_records`) · **Test style:** Browser Dusk
**Primary table:** `adm_promotion_records` · **Module URL prefix:** `/admission/promotions/{batch}/records`
**Test file:** `adm_PromotionRecords_TestCas.php`

Controller: `PromotionRecordController` (list, update result, bulk)

Routes (`adm.` prefix):
- `GET /admission/promotions/{batch}/records` — record list per batch
- `PUT /admission/promotion-records/{record}` — update single result
- `POST /admission/promotions/{batch}/records/bulk-update` — bulk result update
- `POST /admission/promotions/{batch}/confirm` — batch confirms all records

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_promotion_records`: id (BIGINT PK AI), promotion_batch_id (BIGINT UNSIGNED FK → adm_promotion_batches ON DELETE CASCADE), student_id (INT UNSIGNED FK → std_students), from_class_section_id (INT UNSIGNED FK → sch_class_section_jnt), to_class_section_id (INT UNSIGNED FK → sch_class_section_jnt NULL), new_roll_no (SMALLINT UNSIGNED NULL), result (ENUM('Promoted','Detained','Transferred','Alumni','Left') NOT NULL), remarks (TEXT NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. UNIQUE (promotion_batch_id, student_id). Indexes: idx_adm_pr_batch, idx_adm_pr_student_id, idx_adm_pr_student, idx_adm_pr_from_section | DDL |
| BC-DB-02 | Model `PromotionRecord`: SoftDeletes, casts: result→string, new_roll_no→integer, is_active→boolean. Relations: batch() belongsTo PromotionBatch, student() belongsTo Student, fromSection() belongsTo ClassSection, toSection() belongsTo ClassSection | Model |

### BC-VAL — Validation
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `result` required in:Promoted,Detained,Transferred,Alumni,Left | FR |
| BC-VAL-02 | `to_class_section_id` required when result=Promoted, nullable otherwise | FR |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | CRUD gate `tenant.adm-promotion.update` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Records created automatically by promotion batch generation (pulls all active students from from_class) | Service |
| BC-BIZ-02 | Bulk update: upload CSV or inline edit to set result per student | Ctrl |
| BC-BIZ-03 | Result badges: Promoted=success, Not_Promoted=danger, Withdrawn=warning, Alumni=primary, Transferred=info | View |
| BC-BIZ-04 | Confirmed batches (status=Confirmed) freeze records — no further edits | Batch status |
| BC-BIZ-05 | Promoted assigns to_class_section_id as next class+section, new_roll_no via PromotionService::assignRollNumbers() | Service |
| BC-BIZ-06 | Alumni result creates alumni flag: student moves to alumni list | Service |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No students in from_class → zero records generated | Service |
| BC-EDG-02 | Duplicate student in same batch → unique constraint error | Val |
| BC-EDG-03 | Edit after batch confirmed → blocked | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMPR-P10 | Positive | View | Records list: student, from section, to section, new_roll_no, result badge | Rendered | test_adm_pr_10 | Automated |
| TC-ADMPR-P11 | Positive | Ctrl | Update single record result → stored | Updated | test_adm_pr_11 | Automated |
| TC-ADMPR-P12 | Positive | Ctrl | Bulk update records → all updated | Bulk | test_adm_pr_12 | Automated |
| TC-ADMPR-P13 | Positive | View | Result badges: Promoted=success, Detained=warning, Transferred=info, Alumni=primary, Left=secondary | Badges | test_adm_pr_13 | Automated |
| TC-ADMPR-P14 | Positive | Service | Promoted sets to_class_section_id and new_roll_no | Section+Roll | test_adm_pr_14 | Automated |
| TC-ADMPR-P15 | Positive | View | Empty state when no records | Empty | test_adm_pr_15 | Automated |
| TC-ADMPR-N16 | Negative | Val | Missing result → required error | Error | test_adm_pr_16 | Automated |
| TC-ADMPR-N17 | Negative | Biz | Edit after batch confirmed → blocked | Blocked | test_adm_pr_17 | Automated |
