# adm_TransferCertificate — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Transfer Certificates (CRUD + Soft-Delete + Issue + Cancel + PDF)
**DB scope:** TENANT-side (`adm_transfer_certificates`) · **Test style:** Browser Dusk
**Primary table:** `adm_transfer_certificates` · **Module URL prefix:** `/admission/promotions-alumni?tab=tcs`
**Test file:** `adm_TransferCertificate_TestCas.php`
**Tab:** TCs (third tab of Promotions & Alumni)

Controllers:
- `AlumniController` — TC store, show, issue, cancel, pdf, trash, restore, forceDelete
- `AdmMenuController::promotionsAlumni()` — loads TCs list

Service:
- `TransferCertificateService` — issueTc (generates PDF+QR, deactivates student/user, closes session), cancelTc, issueDuplicate

Routes (`adm.` prefix):
- `GET /admission/promotions-alumni` — tabbed page (tcs tab)
- `POST /admission/alumni/tc` — store
- `GET /admission/alumni/tc/{tc}` — show
- `POST /admission/alumni/tc/{tc}/issue` — issue (Draft → Issued)
- `POST /admission/alumni/tc/{tc}/cancel` — cancel
- `GET /admission/alumni/tc/{tc}/pdf` — download PDF
- `GET /admission/alumni/tc/{id}/restore` — restore
- `DELETE /admission/alumni/tc/{id}/force-delete` — force delete
- `GET /admission/alumni/tc/trash/view` — trashed list
- `GET /admission/alumni/tc/by-student/{studentId}` — get draft TC for student

**DDL reference:** `adm_transfer_certificates` (Layer 8)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_transfer_certificates`: id (BIGINT PK AI), student_id (FK → std_students), tc_number (VARCHAR 30 UNIQUE), issue_date (DATE NULL), leaving_date (DATE NOT NULL), class_at_leaving (VARCHAR 30), reason_for_leaving (TEXT NULL), conduct (ENUM:Excellent,Good,Satisfactory,Poor DEFAULT Good), destination_school (VARCHAR 150 NULL), academic_status (VARCHAR 100 NULL), fees_cleared (BOOLEAN DEFAULT false), is_duplicate (BOOLEAN DEFAULT false), original_tc_id (FK self-ref NULL), media_id (FK → sys_media NULL), issued_by (FK → sys_users NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at | DDL |
| BC-DB-02 | Model `TransferCertificate`: table adm_transfer_certificates, SoftDeletes, HasFactory, fillable 17 fields, casts: issue_date/leaving_date→date, fees_cleared/is_duplicate→boolean, is_active→boolean. Computed attribute `status`: Issued if issue_date not null, Cancelled if deleted_at not null, else Draft. Relations: student(), originalTc(), duplicateTcs(), issuedBy() | Model |

### BC-VAL — Validation (StoreTransferCertificateRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `student_id` required integer exists:std_students,id | FR |
| BC-VAL-02 | `tc_number` required string max:30 unique:adm_transfer_certificates | FR |
| BC-VAL-03 | `issue_date` required date | FR |
| BC-VAL-04 | `leaving_date` required date | FR |
| BC-VAL-05 | `class_at_leaving` required string max:30 | FR |
| BC-VAL-06 | `reason_for_leaving` nullable string | FR |
| BC-VAL-07 | `conduct` nullable in:Excellent,Good,Satisfactory,Poor | FR |
| BC-VAL-08 | `destination_school` nullable string max:150 | FR |
| BC-VAL-09 | `academic_status` nullable string max:100 | FR |
| BC-VAL-10 | `fees_cleared` nullable boolean | FR |
| BC-VAL-11 | `is_duplicate` nullable boolean | FR |
| BC-VAL-12 | `original_tc_id` nullable integer exists:adm_transfer_certificates,id | FR |

### BC-AUTH — Authorization (TransferCertificatePolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/trashed gate `tenant.adm-tc.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.adm-tc.create` | Policy |
| BC-AUTH-03 | show gate `tenant.adm-tc.view` | Policy |
| BC-AUTH-04 | edit/update gate `tenant.adm-tc.update` | Policy |
| BC-AUTH-05 | destroy/restore/forceDelete gate `tenant.adm-tc.delete` | Policy |
| BC-AUTH-06 | issue/cancel/pdf gate `tenant.adm-tc.status` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | TCs list: search, filter, paginated, ordered by id desc, loads student + issuedBy relations | MenuCtrl |
| BC-BIZ-02 | Store: creates TC in Draft (no issue_date set yet) | Ctrl |
| BC-BIZ-03 | issue(): Draft→Issued: sets issue_date=now, generates PDF with QR via DomPDF, stores to sys_media | Service |
| BC-BIZ-04 | Issue deactivates student: std_students.is_active = 0 | Service |
| BC-BIZ-05 | Issue deactivates user: sys_users.is_active = 0 | Service |
| BC-BIZ-06 | Issue closes academic session: std_student_academic_sessions.end_date = now | Service |
| BC-BIZ-07 | Issue sets tc_issued = true on std_students | Service |
| BC-BIZ-08 | cancel(): cancels Issued TC (appends cancellation reason), no reversal of deactivation | Service |
| BC-BIZ-09 | pdf(): renders transfer-certificate PDF template with QR code | Ctrl |
| BC-BIZ-10 | issueDuplicate(): creates new TC with is_duplicate=true + original_tc_id, then issues | Service |
| BC-BIZ-11 | Computed status: Issued (issue_date set), Cancelled (deleted_at), else Draft | Model |
| BC-BIZ-12 | Show: detail with issue/cancel/preview actions (buttons change by status) | View |
| BC-BIZ-13 | Trash: soft-deleted TCs with restore/force-delete | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Issue already-issued TC (issue_date already set) → blocked | Service |
| BC-EDG-02 | Duplicate tc_number → unique constraint error | FR |
| BC-EDG-03 | Duplicate TC without original_tc_id → allowed (no reference) | Service |
| BC-EDG-04 | Soft-delete Issued TC → still in trash with Cancelled status | Model |

---

## 2. Test Case List

### Screen 1: TCs Tab (GET /admission/promotions-alumni?tab=tcs)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMTC-P10 | Positive | View | TCs tab: search, table (Student, TC Number, Issue Date, Leaving Date, Class, Conduct, Issued By, Actions) | Rendered | test_adm_tc_10 | Automated |
| TC-ADMTC-P11 | Positive | View | Create TC modal opens with full form (student, tc_number, dates, conduct, fees, etc.) | Modal | test_adm_tc_11 | Automated |
| TC-ADMTC-P12 | Positive | View | Status display: Draft/Issued/Cancelled (computed) | Statuses | test_adm_tc_12 | Automated |
| TC-ADMTC-P13 | Positive | View | Empty state when no TCs | Empty | test_adm_tc_13 | Automated |

### Screen 2: Create + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMTC-P30 | Positive | Ctrl | Store: creates draft TC (no issue_date, no media_id) | Created | test_adm_tc_30 | Automated |
| TC-ADMTC-N31 | Negative | Val | Missing student_id/tc_number/issue_date → required errors | Errors | test_adm_tc_31 | Automated |
| TC-ADMTC-N32 | Negative | Val | Duplicate tc_number → unique error | Error | test_adm_tc_32 | Automated |
| TC-ADMTC-N33 | Negative | Val | Invalid conduct → in:Excellent,Good,Satisfactory,Poor rejects | Error | test_adm_tc_33 | Automated |

### Screen 3: Show + Issue + Cancel + PDF

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMTC-P50 | Positive | View | TC show: student info, tc_number, issue/leaving dates, class, conduct, reason, destination, fees, status | All fields | test_adm_tc_50 | Automated |
| TC-ADMTC-P51 | Positive | View | Action buttons context-sensitive: Draft→Issue/Cancel, Issued→Cancel/PDF | Buttons | test_adm_tc_51 | Automated |
| TC-ADMTC-P52 | Positive | Service | Issue: sets issue_date, generates PDF+QR, stores media_id | Issued | test_adm_tc_52 | Automated |
| TC-ADMTC-P53 | Positive | Service | Issue deactivates student (std_students.is_active = 0) | Student inactive | test_adm_tc_53 | Automated |
| TC-ADMTC-P54 | Positive | Service | Issue deactivates user (sys_users.is_active = 0) | User inactive | test_adm_tc_54 | Automated |
| TC-ADMTC-P55 | Positive | Service | Issue closes academic session (end_date = now) | Session closed | test_adm_tc_55 | Automated |
| TC-ADMTC-P56 | Positive | Service | Issue sets tc_issued = true on student | tc_issued | test_adm_tc_56 | Automated |
| TC-ADMTC-P57 | Positive | Service | Cancel: cancels Issued TC (no reversal of deactivation) | Cancelled | test_adm_tc_57 | Automated |
| TC-ADMTC-P58 | Positive | Ctrl | PDF download renders transfer-certificate template with QR | PDF | test_adm_tc_58 | Automated |
| TC-ADMTC-N59 | Negative | Service | Issue already-issued TC → blocked (issue_date already set) | Blocked | test_adm_tc_59 | Automated |

### Screen 4: Duplicate TC

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMTC-P70 | Positive | Service | issueDuplicate: creates TC with is_duplicate=true + original_tc_id, then issues | Duplicate | test_adm_tc_70 | Automated |

### Screen 5: Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMTC-P90 | Positive | Ctrl | Soft-delete Draft TC → appears in trash | Trashed | test_adm_tc_90 | Automated |
| TC-ADMTC-P91 | Positive | Ctrl | Restore from trash, logs 'Restored' | Restored | test_adm_tc_91 | Automated |
| TC-ADMTC-P92 | Positive | Ctrl | Force delete from trash, logs 'Deleted' | Perm deleted | test_adm_tc_92 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMTC-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_adm_tc_200 | Automated |
| TC-ADMTC-P201 | Positive | Auth | Issue/Cancel with status permission → success | 200 | test_adm_tc_201 | Automated |
| TC-ADMTC-N202 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_adm_tc_202 | Automated |
| TC-ADMTC-N203 | Negative | Auth | Without create → 403 on store | 403 | test_adm_tc_203 | Automated |
| TC-ADMTC-N204 | Negative | Auth | Without status → 403 on issue/cancel | 403 | test_adm_tc_204 | Automated |
