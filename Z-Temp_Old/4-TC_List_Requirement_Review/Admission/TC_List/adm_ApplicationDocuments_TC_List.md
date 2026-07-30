# adm_ApplicationDocuments — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Application Documents (Upload + Verify)
**DB scope:** TENANT-side (`adm_application_documents`) · **Test style:** Browser Dusk
**Primary table:** `adm_application_documents` · **Module URL prefix:** `/admission/applications/{id}/documents`
**Test file:** `adm_ApplicationDocuments_TestCas.php`

Controller: `ApplicationDocumentController` (CRUD + verify/reject)
Service: `DocumentVerificationService`

Routes (`adm.` prefix):
- `GET /admission/applications/{application}/documents` — document list
- `POST /admission/applications/{application}/documents` — upload
- `POST /admission/application-documents/{document}/verify` — verify (Pending→Verified)
- `POST /admission/application-documents/{document}/reject` — reject with reason
- `DELETE /admission/application-documents/{document}` — soft delete

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_application_documents`: id (BIGINT PK AI), application_id (BIGINT UNSIGNED FK → adm_applications ON DELETE CASCADE), checklist_item_id (BIGINT UNSIGNED FK → adm_document_checklist), media_id (INT UNSIGNED FK → sys_media), original_filename (VARCHAR 255 NOT NULL), verification_status (ENUM('Pending','Verified','Rejected') DEFAULT 'Pending'), verification_remarks (TEXT NULL), verified_by (INT UNSIGNED FK → sys_users NULL), verified_at (TIMESTAMP NULL), is_physically_received (TINYINT 1 DEFAULT 0), physical_received_at (DATE NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. UNIQUE (application_id, checklist_item_id). Indexes: idx_adm_doc_app, idx_adm_doc_checklist, idx_adm_doc_media, idx_adm_doc_verified_by, idx_adm_doc_vstatus | DDL |
| BC-DB-02 | Model `ApplicationDocument`: SoftDeletes, casts: verification_status→string, verified_at→datetime, is_physically_received→boolean, physical_received_at→date, is_active→boolean. Relations: application() belongsTo, checklistItem() belongsTo, media() belongsTo, verifiedBy() belongsTo User | Model |

### BC-VAL — Validation
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `checklist_item_id` required integer exists:adm_document_checklist,id | FR |
| BC-VAL-02 | `file` required file mimes:pdf,jpg,png max:5120 | FR |
| BC-VAL-03 | `verification_remarks` required if verification_status=Rejected | FR |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Document upload gate `tenant.adm-application-document.create` | Policy |
| BC-AUTH-02 | Verify/reject gate `tenant.adm-application-document.verify` | Policy |
| BC-AUTH-03 | Delete gate `tenant.adm-application-document.delete` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Document list: shows all uploaded docs per application, grouped by checklist item | View |
| BC-BIZ-02 | Verification badges: Pending=warning, Verified=success, Rejected=danger | View |
| BC-BIZ-03 | Verified docs cannot be re-verified or re-uploaded | Service |
| BC-BIZ-04 | Rejected docs: admin can re-upload if delete first | Service |
| BC-BIZ-05 | is_physically_received toggle for front-desk collection tracking | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Re-upload same checklist item after delete → new record created | Ctrl |
| BC-EDG-02 | No documents uploaded → empty state | View |
| BC-EDG-03 | File exceeds max_size_kb → validation error | FR |
| BC-EDG-04 | File invalid format → mimes validation error | FR |

---

## 2. Test Case List

### Screen 1: Document Upload
| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAD-P10 | Positive | Ctrl | Upload valid document → stored, status=Pending, media_id set | Created | test_adm_ad_10 | Automated |
| TC-ADMAD-P11 | Positive | View | Document list shows filename, verification badge, actions | Rendered | test_adm_ad_11 | Automated |
| TC-ADMAD-P12 | Positive | Ctrl | Verify document → status=Verified, verified_by/verified_at set | Verified | test_adm_ad_12 | Automated |
| TC-ADMAD-P13 | Positive | Ctrl | Reject document with reason → status=Rejected, remarks stored | Rejected | test_adm_ad_13 | Automated |
| TC-ADMAD-P14 | Positive | Ctrl | Toggle is_physically_received → flag set | Toggled | test_adm_ad_14 | Automated |
| TC-ADMAD-N15 | Negative | Val | Duplicate checklist item upload → unique constraint error | Error | test_adm_ad_15 | Automated |
| TC-ADMAD-N16 | Negative | Val | Missing file → required error | Error | test_adm_ad_16 | Automated |

### Authorization Tests
| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAD-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_adm_ad_200 | Automated |
| TC-ADMAD-N201 | Negative | Auth | Without create → 403 on upload | 403 | test_adm_ad_201 | Automated |
| TC-ADMAD-N202 | Negative | Auth | Without verify → 403 on verify/reject | 403 | test_adm_ad_202 | Automated |
