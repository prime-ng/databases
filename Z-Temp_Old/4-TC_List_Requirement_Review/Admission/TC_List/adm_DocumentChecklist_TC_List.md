# adm_DocumentChecklist — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Document Checklist (CRUD + Soft-Delete + Toggle Status)
**DB scope:** TENANT-side (`adm_document_checklist`) · **Test style:** Browser Dusk
**Primary table:** `adm_document_checklist` · **Module URL prefix:** `/admission/setup?tab=checklist`
**Test file:** `adm_DocumentChecklist_TestCas.php`
**Tab:** Document Checklist (second tab of Admission Setup)

Controllers:
- `DocumentChecklistController` — CRUD + trash + toggle
- `AdmSettingsController` — AJAX alternative CRUD endpoints
- `AdmMenuController::setup()` — loads checklist data for setup tab

Routes (`adm.` prefix):
- `GET/POST /admission/checklists` — store
- `GET /admission/checklists/create` — create
- `GET /admission/checklists/{checklist}` — show
- `GET/PUT /admission/checklists/{checklist}/edit` — edit/update
- `DELETE /admission/checklists/{checklist}` — destroy
- `GET /admission/checklists/trash/view` — trashed list
- `GET /admission/checklists/{id}/restore` — restore
- `DELETE /admission/checklists/{id}/force-delete` — force delete
- `POST /admission/checklists/{id}/toggle-status` — toggle status (AJAX)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_document_checklist`: id (BIGINT PK AI), admission_cycle_id (BIGINT UNSIGNED FK NULLABLE), class_id (INT UNSIGNED FK NULLABLE), document_name (VARCHAR 100), document_code (VARCHAR 30), is_mandatory (BOOLEAN DEFAULT true), is_system (BOOLEAN DEFAULT false), accepted_formats (VARCHAR 100 DEFAULT 'pdf,jpg,png'), max_size_kb (INT UNSIGNED DEFAULT 5120), sort_order (TINYINT UNSIGNED DEFAULT 0), is_active (BOOLEAN DEFAULT true), created_by, updated_by, created_at, updated_at, deleted_at | DDL |
| BC-DB-02 | Model `DocumentChecklist`: table `adm_document_checklist`, SoftDeletes, fillable: 12 columns, casts: is_mandatory/is_system/is_active → boolean | Model |
| BC-DB-03 | Relationships: cycle() belongsTo AdmissionCycle, applicationDocuments() hasMany ApplicationDocument | Model |
| BC-DB-04 | FK: admission_cycle_id → adm_admission_cycles ON DELETE CASCADE; class_id → sch_classes ON DELETE SET NULL | Migration |
| BC-DB-05 | FK: adm_application_documents.checklist_item_id → adm_document_checklist ON DELETE RESTRICT | Migration |

### BC-VAL — Validation (Inline Controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `admission_cycle_id` required exists:adm_admission_cycles,id (store only) | Ctrl:51 |
| BC-VAL-02 | `class_id` nullable exists:sch_classes,id | Ctrl:52,109 |
| BC-VAL-03 | `document_name` required string max:150 | Ctrl:53,110 |
| BC-VAL-04 | `document_code` required string max:50 | Ctrl:54,111 |
| BC-VAL-05 | `sort_order` nullable integer min:1 | Ctrl:55,112 |
| BC-VAL-06 | `is_mandatory` nullable boolean (has()?1:0) | Ctrl:56,61,113,118 |
| BC-VAL-07 | `accepted_formats` nullable string max:255 | Ctrl:57,114 |
| BC-VAL-08 | `max_size_kb` nullable integer min:1 | Ctrl:58,115 |
| BC-VAL-09 | Store auto-sets: is_system=0, is_active=1 | Ctrl:62-63 |

### BC-VAL-FR — Validation (StoreDocumentChecklistRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-FR-01 | `document_code` unique scoped to (admission_cycle_id, document_code), ignores current id | FR:26-31 |
| BC-VAL-FR-02 | `is_mandatory` required boolean (not nullable) | FR:33 |
| BC-VAL-FR-03 | `is_system` nullable boolean | FR:34 |
| BC-VAL-FR-04 | `accepted_formats` max:100 (not 255) | FR:35 |
| BC-VAL-FR-05 | `sort_order` min:0 (not 1) | FR:37 |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index()/trashed() gate `tenant.adm-document-checklist.viewAny` | Ctrl |
| BC-AUTH-02 | create()/store() gate `tenant.adm-document-checklist.create` | Ctrl |
| BC-AUTH-03 | show() gate `tenant.adm-document-checklist.view` | Ctrl |
| BC-AUTH-04 | edit()/update() gate `tenant.adm-document-checklist.update` | Ctrl |
| BC-AUTH-05 | destroy() gate `tenant.adm-document-checklist.delete` | Ctrl |
| BC-AUTH-06 | restore() gate `tenant.adm-document-checklist.restore` | Ctrl |
| BC-AUTH-07 | forceDelete() gate `tenant.adm-document-checklist.forceDelete` | Ctrl |
| BC-AUTH-08 | toggleStatus() gate `tenant.adm-document-checklist.update` | Ctrl |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | index() redirects to setup tab (standalone index not used) | Ctrl:26 |
| BC-BIZ-02 | Setup tab: loads checklist via AdmMenuController with search/is_active filter | AdmMenuCtrl |
| BC-BIZ-03 | Store: is_mandatory via has() check, defaults is_system=0, is_active=1 | Ctrl:61-63 |
| BC-BIZ-04 | Store: does NOT enforce unique document_code per cycle (potential data issue) | Ctrl:50-59 |
| BC-BIZ-05 | Destroy: does NOT set is_active=false before soft-delete | Ctrl:169 |
| BC-BIZ-06 | Toggle: uses request is_active or inverts current, returns JSON | Ctrl:135-160 |
| BC-BIZ-07 | All CRUD logged via activityLog() | Ctrl throughout |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Duplicate document_code per cycle allowed (inline validation missing unique rule) | DEV-01 |
| BC-EDG-02 | Controller max:150 for document_name but DDL=100 → oversize potential | DEV-02 |
| BC-EDG-03 | is_active ignored on store (always set to 1) | DEV-05 |
| BC-EDG-04 | sort_order=0 rejected by inline (min:1) but accepted by FormRequest (min:0) | BC-VAL-05 vs FR |

---

## 2. Test Case List

### Screen 1: Checklist Tab (GET /admission/setup?tab=checklist)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMCHK-P10 | Positive | View | Tab renders: search, status filter, table (Order, Name, Code, Mandatory, Formats, Max Size, Toggle, Actions) | Page rendered | test_adm_chk_10 | Automated |
| TC-ADMCHK-P11 | Positive | View | Search by document_name/code, filter by is_active | Filtered | test_adm_chk_11 | Automated |
| TC-ADMCHK-P12 | Positive | View | Mandatory badge (Yes/No), status toggle, Add New button, Trash link | Elements | test_adm_chk_12 | Automated |
| TC-ADMCHK-P13 | Positive | View | Empty state "No Documents Configured" | Empty state | test_adm_chk_13 | Automated |

### Screen 2: Create + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMCHK-P30 | Positive | View | Create form: cycle_id, name, code, class, formats, max_size, sort_order, is_mandatory, is_active | All fields | test_adm_chk_30 | Automated |
| TC-ADMCHK-P31 | Positive | Ctrl | Valid create succeeds, is_system=0, is_active=1, logs 'Stored' | Created | test_adm_chk_31 | Automated |
| TC-ADMCHK-P32 | Positive | Ctrl | is_mandatory checked=1, unchecked=0 | Correct value | test_adm_chk_32 | Automated |
| TC-ADMCHK-N33 | Negative | Val | Empty name/code → validation errors | Errors | test_adm_chk_33 | Automated |
| TC-ADMCHK-N34 | Negative | Val | Invalid cycle_id/class_id → exists rejects | Errors | test_adm_chk_34 | Automated |
| TC-ADMCHK-N35 | Negative | Val | max_size_kb=0 → min:1 rejects | Error | test_adm_chk_35 | Automated |

### Screen 3: Show, Edit, Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMCHK-P60 | Positive | View | Show renders all fields with Edit button | Visible | test_adm_chk_60 | Automated |
| TC-ADMCHK-P61 | Positive | View | Edit pre-populates form | Pre-filled | test_adm_chk_61 | Automated |
| TC-ADMCHK-P62 | Positive | Ctrl | Update succeeds, logs 'Updated' | Updated | test_adm_chk_62 | Automated |

### Screen 4: Trash Lifecycle + Toggle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMCHK-P90 | Positive | Ctrl | Soft-delete, appears in trash | Trashed | test_adm_chk_90 | Automated |
| TC-ADMCHK-P91 | Positive | Ctrl | Restore brings back to main index | Restored | test_adm_chk_91 | Automated |
| TC-ADMCHK-P92 | Positive | Ctrl | Force delete removes permanently | Perm deleted | test_adm_chk_92 | Automated |
| TC-ADMCHK-P100 | Positive | Ctrl | Toggle on/off returns JSON | JSON | test_adm_chk_100 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMCHK-P140 | Positive | Auth | All CRUD with correct permissions = 200 | 200 | test_adm_chk_140 | Automated |
| TC-ADMCHK-N141 | Negative | Auth | Without permissions → 403 | 403 | test_adm_chk_141 | Automated |
