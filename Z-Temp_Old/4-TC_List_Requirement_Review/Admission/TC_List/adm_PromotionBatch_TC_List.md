# adm_PromotionBatch — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Promotion Batches (CRUD + Soft-Delete + Confirm + Cancel + Records AJAX)
**DB scope:** TENANT-side (`adm_promotion_batches`, `adm_promotion_records`) · **Test style:** Browser Dusk
**Primary table:** `adm_promotion_batches` · **Module URL prefix:** `/admission/promotions-alumni?tab=batches`
**Test file:** `adm_PromotionBatch_TestCas.php`
**Tab:** Batches (first tab of Promotions & Alumni)

Controllers:
- `PromotionController` — CRUD + trash + confirm + cancel + AJAX records CRUD
- `AdmMenuController::promotionsAlumni()` — loads batches tab data

Service:
- `PromotionService` — createBatch, upsertRecord, confirmBatch (writes StudentAcademicSession), cancelBatch

Routes (`adm.` prefix):
- `GET /admission/promotions-alumni` — tabbed page (batches tab)
- `GET /admission/promotions` — index
- `GET /admission/promotions/create` — create form
- `POST /admission/promotions` — store
- `GET /admission/promotions/{promotion}` — show
- `GET /admission/promotions/{promotion}/edit` — edit (Draft only)
- `PUT /admission/promotions/{promotion}` — update (Draft only)
- `DELETE /admission/promotions/{promotion}` — soft delete (Draft only)
- `POST /admission/promotions/{promotion}/confirm` — Draft → Confirmed
- `POST /admission/promotions/{promotion}/cancel` — cancel (delete)
- `GET /admission/promotions/{promotion}/records` — JSON records
- `POST /admission/promotions/{promotion}/records` — AJAX store record
- `PUT /admission/promotions/{promotion}/records/{record}` — AJAX update record
- `DELETE /admission/promotions/{promotion}/records/{record}` — AJAX delete record
- `POST /admission/promotions/records/{record}/toggle-status` — AJAX toggle
- `GET /admission/promotions/trash/view` — trashed
- `GET /admission/promotions/{id}/restore` — restore
- `DELETE /admission/promotions/{id}/force-delete` — force delete

**DDL references:** `adm_promotion_batches` (Layer 6), `adm_promotion_records` (Layer 7)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_promotion_batches`: id (BIGINT PK AI), from_session_id (FK → sch_org_academic_sessions_jnt), to_session_id (FK), from_class_id (FK → sch_classes), to_class_id (FK), criteria_json (JSON NULL), total_students (INT UNSIGNED DEFAULT 0), promoted_count (INT UNSIGNED DEFAULT 0), detained_count (INT UNSIGNED DEFAULT 0), status (ENUM:Draft,Confirmed DEFAULT Draft), processed_by (FK → sys_users NULL), processed_at (TIMESTAMP NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at | DDL |
| BC-DB-02 | Table `adm_promotion_records`: id (BIGINT PK AI), promotion_batch_id (FK CASCADE), student_id (FK → std_students), from_class_section_id (FK → sch_class_section_jnt), to_class_section_id (FK NULL), new_roll_no (SMALLINT NULL), result (ENUM:Promoted,Detained,Transferred,Alumni,Left), remarks (TEXT NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at | DDL |
| BC-DB-03 | Model `PromotionBatch`: table adm_promotion_batches, SoftDeletes, HasFactory, fillable 14 fields, casts: criteria_json→array, processed_at→datetime, is_active→boolean. Relations: fromSession/toSession() belongsTo AcademicSession, fromClass/toClass() belongsTo SchoolClass, processedBy() belongsTo User, records() hasMany PromotionRecord | Model |
| BC-DB-04 | Model `PromotionRecord`: table adm_promotion_records, SoftDeletes, HasFactory, fillable 10 fields, casts: new_roll_no→integer, is_active→boolean. Relations: batch(), student(), fromClassSection()/toClassSection() | Model |

### BC-VAL — Validation (StorePromotionBatchRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `from_session_id` required integer exists:sch_org_academic_sessions_jnt,id | FR |
| BC-VAL-02 | `to_session_id` required integer exists:sch_org_academic_sessions_jnt,id | FR |
| BC-VAL-03 | `from_class_id` required integer exists:sch_classes,id | FR |
| BC-VAL-04 | `to_class_id` required integer exists:sch_classes,id | FR |
| BC-VAL-05 | `criteria_json` nullable array | FR |
| BC-VAL-06 | `status` nullable in:Draft,Confirmed | FR |

### BC-AUTH — Authorization (PromotionBatchPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/trashed gate `tenant.adm-promotion.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.adm-promotion.create` | Policy |
| BC-AUTH-03 | show gate `tenant.adm-promotion.view` | Policy |
| BC-AUTH-04 | edit/update/toggleStatus gate `tenant.adm-promotion.update` | Policy |
| BC-AUTH-05 | destroy/restore/forceDelete gate `tenant.adm-promotion.delete` | Policy |
| BC-AUTH-06 | confirm/cancel gate `tenant.adm-promotion.status` | Policy |
| BC-AUTH-07 | Records AJAX CRUD gate `tenant.adm-promotion.update` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Batches list: search/filter, ordered by id desc, paginated 20, loads from/to session/class relations | MenuCtrl |
| BC-BIZ-02 | List shows counts (total/promoted/detained), status badges: Draft=secondary, Confirmed=success | View |
| BC-BIZ-03 | Store: status=Draft, total_students=0, via PromotionService::createBatch() | Ctrl |
| BC-BIZ-04 | Edit/update allowed only when status=Draft | Ctrl |
| BC-BIZ-05 | Soft-delete allowed only when status=Draft (blocked if Confirmed) | Ctrl |
| BC-BIZ-06 | Show page: batch summary + records table + AJAX add/edit record form + quick actions (confirm/cancel) | View |
| BC-BIZ-07 | confirm(): Draft→Confirmed, writes StudentAcademicSession via firstOrCreate, logs activity | Service |
| BC-BIZ-08 | confirm() idempotent: already-Confirmed batches skip re-processing | Service |
| BC-BIZ-09 | cancel(): deletes batch + all records | Service |
| BC-BIZ-10 | Records AJAX: storeRecord creates per-student promotion record | Ctrl |
| BC-BIZ-11 | upsertRecord auto-resolves from_class_section_id from student's current academic session | Service |
| BC-BIZ-12 | updateRecord updates existing record (result, to_class_section, etc.) | Ctrl |
| BC-BIZ-13 | destroyRecord deletes a record | Ctrl |
| BC-BIZ-14 | toggleRecordStatus toggles is_active via AJAX | Ctrl |
| BC-BIZ-15 | updateBatchStats recalculates total/promoted/detained counts after changes | Service |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Confirm already-Confirmed batch → safe (firstOrCreate idempotent) | Service |
| BC-EDG-02 | Delete Confirmed batch → blocked (error) | Ctrl |
| BC-EDG-03 | Edit Confirmed batch → blocked (error) | Ctrl |
| BC-EDG-04 | Cancel Draft batch → deletes batch + records | Service |

---

## 2. Test Case List

### Screen 1: Batches List Tab (GET /admission/promotions-alumni?tab=batches)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMPB-P10 | Positive | View | Batches tab: table (From/To Class, Sessions, Total/Promoted/Detained, Status, Actions) | Rendered | test_adm_pb_10 | Automated |
| TC-ADMPB-P11 | Positive | View | Status badges: Draft=secondary, Confirmed=success, counts displayed | Elements | test_adm_pb_11 | Automated |
| TC-ADMPB-P12 | Positive | View | Search, paginated 20, Create button | Elements | test_adm_pb_12 | Automated |
| TC-ADMPB-P13 | Positive | View | Empty state when no batches | Empty | test_adm_pb_13 | Automated |

### Screen 2: Create + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMPB-P30 | Positive | View | Create form: from_session, to_session, from_class, to_class, criteria_json | Fields | test_adm_pb_30 | Automated |
| TC-ADMPB-P31 | Positive | Ctrl | Store: status=Draft, total_students=0, via PromotionService::createBatch() | Created | test_adm_pb_31 | Automated |
| TC-ADMPB-N32 | Negative | Val | Missing from_session_id/from_class_id → required errors | Errors | test_adm_pb_32 | Automated |
| TC-ADMPB-N33 | Negative | Val | Invalid session/class FK → exists rejects | Errors | test_adm_pb_33 | Automated |

### Screen 3: Show + Records AJAX CRUD

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMPB-P50 | Positive | View | Show: batch summary card + records table + add/edit form + confirm/cancel actions | Layout | test_adm_pb_50 | Automated |
| TC-ADMPB-P51 | Positive | Ctrl | AJAX storeRecord: creates record, updates batch counts | Created | test_adm_pb_51 | Automated |
| TC-ADMPB-P52 | Positive | Service | upsertRecord auto-resolves from_class_section from current session | Resolved | test_adm_pb_52 | Automated |
| TC-ADMPB-P53 | Positive | Ctrl | AJAX updateRecord: updates result, to_class_section, new_roll_no | Updated | test_adm_pb_53 | Automated |
| TC-ADMPB-P54 | Positive | Ctrl | AJAX destroyRecord: deletes record, updates batch counts | Deleted | test_adm_pb_54 | Automated |
| TC-ADMPB-P55 | Positive | Ctrl | AJAX toggleRecordStatus: toggles is_active | Toggled | test_adm_pb_55 | Automated |

### Screen 4: Confirm + Cancel

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMPB-P70 | Positive | Service | Confirm Draft batch → Confirmed, writes StudentAcademicSession, logs activity | Confirmed | test_adm_pb_70 | Automated |
| TC-ADMPB-P71 | Positive | Service | Confirm already-Confirmed → safe (firstOrCreate no-op) | No error | test_adm_pb_71 | Automated |
| TC-ADMPB-P72 | Positive | Service | Cancel Draft batch → deletes batch + all records | Cancelled | test_adm_pb_72 | Automated |
| TC-ADMPB-N73 | Negative | Biz | Cancel/Delete Confirmed batch → blocked | Blocked | test_adm_pb_73 | Automated |

### Screen 5: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMPB-P90 | Positive | View | Edit pre-populates form (Draft only) | Pre-filled | test_adm_pb_90 | Automated |
| TC-ADMPB-P91 | Positive | Ctrl | Update Draft batch changes fields | Updated | test_adm_pb_91 | Automated |
| TC-ADMPB-N92 | Negative | Biz | Edit Confirmed batch → blocked | Blocked | test_adm_pb_92 | Automated |

### Screen 6: Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMPB-P110 | Positive | Ctrl | Soft-delete Draft batch → appears in trash | Trashed | test_adm_pb_110 | Automated |
| TC-ADMPB-P111 | Positive | Ctrl | Restore from trash, logs 'Restored' | Restored | test_adm_pb_111 | Automated |
| TC-ADMPB-P112 | Positive | Ctrl | Force delete from trash, logs 'Deleted' | Perm deleted | test_adm_pb_112 | Automated |
| TC-ADMPB-N113 | Negative | Biz | Delete Confirmed batch → blocked | Blocked | test_adm_pb_113 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMPB-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_adm_pb_200 | Automated |
| TC-ADMPB-P201 | Positive | Auth | Confirm/Cancel with status permission → success | 200 | test_adm_pb_201 | Automated |
| TC-ADMPB-N202 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_adm_pb_202 | Automated |
| TC-ADMPB-N203 | Negative | Auth | Without create → 403 on store | 403 | test_adm_pb_203 | Automated |
| TC-ADMPB-N204 | Negative | Auth | Without update → 403 on update/records | 403 | test_adm_pb_204 | Automated |
| TC-ADMPB-N205 | Negative | Auth | Without delete → 403 on destroy | 403 | test_adm_pb_205 | Automated |
| TC-ADMPB-N206 | Negative | Auth | Without status → 403 on confirm/cancel | 403 | test_adm_pb_206 | Automated |
