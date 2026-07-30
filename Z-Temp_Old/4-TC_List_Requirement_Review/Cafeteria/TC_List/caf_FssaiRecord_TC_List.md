# caf_FssaiRecord — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** FSSAI Records (License + Audit Compliance Tracking)
**DB scope:** TENANT-side (`caf_fssai_records`) · **Test style:** Browser Dusk
**Primary table:** `caf_fssai_records` · **Module URL prefix:** `/cafeteria/stock-compliance?tab=fssai`
**Test file:** `caf_FssaiRecord_TestCas.php`
**Tab:** FSSAI (third tab of Stock & Compliance)

Controllers:
- `FssaiController` — index (redirect), store, show, edit, update, destroy, toggleStatus, trashed, restore, forceDelete
- `CafeteriaController::stockCompliance()` — loads FSSAI records + expiring alerts for tabbed page

Service:
- `StockService` — checkFssaiExpiry (tiered expiry alerts: supplier 30d/7d, school 60d/30d)

Routes (`cafeteria.` prefix):
- `GET /cafeteria/stock-compliance` — tabbed page (fssai tab)
- `POST /cafeteria/fssai` — store (modal)
- `GET /cafeteria/fssai/{fssaiRecord}` — show
- `GET /cafeteria/fssai/{fssaiRecord}/edit` — edit
- `PUT /cafeteria/fssai/{fssaiRecord}` — update
- `DELETE /cafeteria/fssai/{fssaiRecord}` — destroy
- `POST /cafeteria/fssai/{fssaiRecord}/toggle-status` — Ajax status toggle
- `GET /cafeteria/fssai/trashed` — trashed records
- `POST /cafeteria/fssai/{id}/restore` — restore
- `DELETE /cafeteria/fssai/{id}/force-delete` — permanent delete

**DDL reference:** `caf_fssai_records` (Cafeteria DDL)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `caf_fssai_records`: id (INT UNSIGNED PK AI), supplier_id (INT UNSIGNED NULL FK → caf_suppliers.id ON DELETE SET NULL), record_type (ENUM('License','Audit') NOT NULL), license_number (VARCHAR 50 NULL), license_type (ENUM('Basic','State','Central') NULL), issue_date (DATE NULL), expiry_date (DATE NULL), licensed_entity_name (VARCHAR 150 NULL), fssai_document_media_id (INT UNSIGNED NULL FK → sys_media.id ON DELETE SET NULL), audit_date (DATE NULL), auditor_name (VARCHAR 100 NULL), audit_score (TINYINT UNSIGNED NULL), audit_remarks (TEXT NULL), corrective_actions (TEXT NULL), next_audit_date (DATE NULL), is_active (TINYINT 1 DEFAULT 1), created_by, created_at, updated_at, deleted_at. Indexes: idx_caf_fr_type, idx_caf_fr_supplier, idx_caf_fr_expiry | DDL |
| BC-DB-02 | Model `FssaiRecord`: table caf_fssai_records, SoftDeletes, fillable 15 fields, casts: issue_date→date, expiry_date→date, audit_date→date, next_audit_date→date, is_active→boolean, audit_score→integer. Scopes: active(), licenses(), audits(). Relations: supplier() belongsTo | Model |

### BC-VAL — Validation (StoreFssaiRecordRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `supplier_id` nullable integer exists:caf_suppliers,id | FR |
| BC-VAL-02 | `record_type` required in:License,Audit | FR |
| BC-VAL-03 | `license_number` required_if:License string max:50 | FR |
| BC-VAL-04 | `license_type` required_if:License in:Basic,State,Central | FR |
| BC-VAL-05 | `issue_date` required_if:License date | FR |
| BC-VAL-06 | `expiry_date` required_if:License date after_or_equal:issue_date | FR |
| BC-VAL-07 | `licensed_entity_name` required_if:License string max:150 | FR |
| BC-VAL-08 | `fssai_document_media_id` nullable integer exists:sys_media,id | FR |
| BC-VAL-09 | `audit_date` required_if:Audit date | FR |
| BC-VAL-10 | `auditor_name` required_if:Audit string max:100 | FR |
| BC-VAL-11 | `audit_score` required_if:Audit integer min:1 max:10 | FR |
| BC-VAL-12 | `audit_remarks` nullable string | FR |
| BC-VAL-13 | `corrective_actions` nullable string | FR |
| BC-VAL-14 | `next_audit_date` nullable date after:audit_date | FR |
| BC-VAL-15 | `is_active` nullable boolean (prepared from checkbox) | FR |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.fssai` (viewAny) | View |
| BC-AUTH-02 | store/create gate `cafeteria.fssai.create` | Ctrl |
| BC-AUTH-03 | show/view gate `cafeteria.fssai.view` | Ctrl |
| BC-AUTH-04 | update/toggle gate `cafeteria.fssai.update` | Ctrl |
| BC-AUTH-05 | delete gate `cafeteria.fssai.delete` | Ctrl |
| BC-AUTH-06 | restore gate `cafeteria.fssai.restore` | Ctrl |
| BC-AUTH-07 | forceDelete gate `cafeteria.fssai.forceDelete` | Ctrl |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | FSSAI tab: paginated table with Licence #, Holder (entity name), Type (License/Audit), Issued, Expires, Status toggle, Actions | View |
| BC-BIZ-02 | Search: by license_number or licensed_entity_name | View |
| BC-BIZ-03 | Status filter: All / Active / Expired / Revoked (maps to is_active false) | View |
| BC-BIZ-04 | Expiry alerts: supplier FSSAI ≤30d (warning), school license ≤60d (danger) | View |
| BC-BIZ-05 | Row with <30 days to expiry: table-warning class, badge "{N}d left" | View |
| BC-BIZ-06 | Row with expired expiry: badge "Expired" (bg-danger-subtle) | View |
| BC-BIZ-07 | Create modal: conditional form — License shows supplier, license fields; Audit shows audit fields | View |
| BC-BIZ-08 | Record type switch: JS hides/shows audit fields, clears values when switching to License | View |
| BC-BIZ-09 | Delete: sets is_active=false, then soft deletes | Ctrl |
| BC-BIZ-10 | Restore: sets is_active=true | Ctrl |
| BC-BIZ-11 | Status toggle: Ajax POST → flips is_active, returns JSON {success, is_active, message} | Ctrl |
| BC-BIZ-12 | Activity logged for: create, update (with changes diff), delete, toggle, restore, force delete | Ctrl |
| BC-BIZ-13 | Expiry check service: scans supplier + school FSSAI in tiered batches for alert dispatch | Service |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No FSSAI records → empty state "No FSSAI records." | View |
| BC-EDG-02 | Create License with expiry < issue_date → after_or_equal validation error | Val |
| BC-EDG-03 | Create Audit with next_audit_date ≤ audit_date → after validation error | Val |
| BC-EDG-04 | Create License without required fields → required_if validation errors + custom messages | Val |
| BC-EDG-05 | Switch record_type from License→Audit in modal → License fields hidden, values cleared | View |
| BC-EDG-06 | Delete already-deleted record → 404 (SoftDeletes) | Ctrl |

---

## 2. Test Case List

### Screen 1: FSSAI Tab (GET /cafeteria/stock-compliance?tab=fssai)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFFS-P10 | Positive | View | FSSAI tab: table with Licence #, Holder, Type, Issued, Expires, Status toggle, Actions | Rendered | test_caf_fs_10 | Automated |
| TC-CAFFS-P11 | Positive | View | Search by license_number or licensed_entity_name | Search | test_caf_fs_11 | Automated |
| TC-CAFFS-P12 | Positive | View | Status filter: All / Active / Expired | Filters | test_caf_fs_12 | Automated |
| TC-CAFFS-P13 | Positive | View | Expiring <30d row: table-warning + "{N}d left" badge | Warning styling | test_caf_fs_13 | Automated |
| TC-CAFFS-P14 | Positive | View | Expired row: "Expired" badge (bg-danger-subtle) | Expired badge | test_caf_fs_14 | Automated |
| TC-CAFFS-P15 | Positive | View | Empty state "No FSSAI records." | Empty | test_caf_fs_15 | Automated |
| TC-CAFFS-P16 | Positive | View | Paginated 15 per page | Paginated | test_caf_fs_16 | Automated |
| TC-CAFFS-P17 | Positive | View | Record type column shows "License" or "Audit" | Type label | test_caf_fs_17 | Automated |

### Screen 2: Alerts

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFFS-P30 | Positive | Biz | Supplier FSSAI expiring ≤30d → warning alert "{N} supplier FSSAI licence(s) expiring within 30 days" | Supplier alert | test_caf_fs_30 | Automated |
| TC-CAFFS-P31 | Positive | Biz | School license expiring ≤60d → danger alert "{N} school FSSAI licence(s) expiring within 60 days" | School alert | test_caf_fs_31 | Automated |

### Screen 3: Create FSSAI Record (Modal)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFFS-P50 | Positive | Ctrl | Create License record → stored, redirect "FSSAI record created." | Created | test_caf_fs_50 | Automated |
| TC-CAFFS-P51 | Positive | Ctrl | Create Audit record → stored, redirect "FSSAI record created." | Created | test_caf_fs_51 | Automated |
| TC-CAFFS-P52 | Positive | View | Switch record_type to Audit → all audit fields visible, license fields hidden | Conditional fields | test_caf_fs_52 | Automated |
| TC-CAFFS-P53 | Positive | View | Switch record_type to License → all license fields visible, audit fields hidden + cleared | Field switch | test_caf_fs_53 | Automated |
| TC-CAFFS-N54 | Negative | Val | Create License without license_number → "License number is required" custom error | Error | test_caf_fs_54 | Automated |
| TC-CAFFS-N55 | Negative | Val | Create License with expiry < issue_date → after_or_equal error | Error | test_caf_fs_55 | Automated |
| TC-CAFFS-N56 | Negative | Val | Create Audit without audit_date → "Audit date is required" custom error | Error | test_caf_fs_56 | Automated |
| TC-CAFFS-N57 | Negative | Val | Create Audit with next_audit_date ≤ audit_date → after validation error | Error | test_caf_fs_57 | Automated |
| TC-CAFFS-N58 | Negative | Val | Create Audit with audit_score > 10 → max:10 error | Error | test_caf_fs_58 | Automated |

### Screen 4: CRUD + Status Toggle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFFS-P70 | Positive | Ctrl | Update FSSAI record → updated, activity logged with changes diff | Updated | test_caf_fs_70 | Automated |
| TC-CAFFS-P71 | Positive | Ctrl | Toggle status active/inactive → Ajax JSON success | Toggled | test_caf_fs_71 | Automated |
| TC-CAFFS-P72 | Positive | Ctrl | Soft delete → is_active=false, deleted_at set | Deleted | test_caf_fs_72 | Automated |
| TC-CAFFS-P73 | Positive | Ctrl | Restore trashed record → is_active=true restored | Restored | test_caf_fs_73 | Automated |
| TC-CAFFS-P74 | Positive | Ctrl | Force delete → permanently removed | Force deleted | test_caf_fs_74 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFFS-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_caf_fs_200 | Automated |
| TC-CAFFS-N201 | Negative | Auth | Without viewAny → tab hidden | Hidden | test_caf_fs_201 | Automated |
| TC-CAFFS-N202 | Negative | Auth | Without create → 403 on store | 403 | test_caf_fs_202 | Automated |
| TC-CAFFS-N203 | Negative | Auth | Without update → 403 on edit/toggle | 403 | test_caf_fs_203 | Automated |
| TC-CAFFS-N204 | Negative | Auth | Without delete → 403 on destroy | 403 | test_caf_fs_204 | Automated |
| TC-CAFFS-N205 | Negative | Auth | Without restore → 403 on restore | 403 | test_caf_fs_205 | Automated |
| TC-CAFFS-N206 | Negative | Auth | Without forceDelete → 403 on force delete | 403 | test_caf_fs_206 | Automated |
