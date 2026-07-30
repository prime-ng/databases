# adm_QuotaConfig — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Quota Config (CRUD + Soft-Delete + Toggle Status)
**DB scope:** TENANT-side (`adm_quota_config`) · **Test style:** Browser Dusk
**Primary table:** `adm_quota_config` · **Module URL prefix:** `/admission/setup?tab=quotas`
**Test file:** `adm_QuotaConfig_TestCas.php`
**Tab:** Quota Config (third tab of Admission Setup)

Controller: `QuotaConfigController` — CRUD + trash + toggle

Routes (`adm.` prefix):
- `GET/POST /admission/quotas` — store
- `GET /admission/quotas/create` — create
- `GET /admission/quotas/{quota}` — show
- `GET/PUT /admission/quotas/{quota}/edit` — edit/update
- `DELETE /admission/quotas/{quota}` — destroy
- `GET /admission/quotas/trash/view` — trashed list
- `GET /admission/quotas/{id}/restore` — restore
- `DELETE /admission/quotas/{id}/force-delete` — force delete
- `POST /admission/quotas/{id}/toggle-status` — toggle status (AJAX)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_quota_config`: id (BIGINT PK AI), admission_cycle_id (BIGINT UNSIGNED FK), class_id (INT UNSIGNED FK), quota_type (ENUM EWS,General,Government,Management,NRI,RTE,Sibling,Staff_Ward), total_seats (UNSIGNED SMALLINT), reserved_seats (UNSIGNED SMALLINT DEFAULT 0), application_fee_waiver (BOOLEAN DEFAULT false), is_active (BOOLEAN DEFAULT true), created_by, updated_by, created_at, updated_at, deleted_at | DDL |
| BC-DB-02 | Model `QuotaConfig`: table `adm_quota_config`, SoftDeletes, fillable: 9 columns, casts: total_seats/reserved_seats → integer, application_fee_waiver/is_active → boolean | Model |
| BC-DB-03 | Relationships: cycle() belongsTo AdmissionCycle, schoolClass() belongsTo SchoolClass | Model |
| BC-DB-04 | FK: admission_cycle_id → adm_admission_cycles CASCADE; class_id → sch_classes CASCADE | Migration |
| BC-DB-05 | Indexes: idx_adm_qcfg_cycle_class (admission_cycle_id, class_id), idx_adm_qcfg_quota (quota_type) | Migration |

### BC-VAL — Validation (Inline Controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `admission_cycle_id` required exists:adm_admission_cycles,id (store only) | Ctrl |
| BC-VAL-02 | `class_id` required exists:sch_classes,id | Ctrl |
| BC-VAL-03 | `quota_type` required in:General,Government,Management,RTE,NRI,Staff_Ward,Sibling,EWS | Ctrl |
| BC-VAL-04 | `total_seats` required integer min:0 | Ctrl |
| BC-VAL-05 | `reserved_seats` required integer min:0 | Ctrl |
| BC-VAL-06 | `application_fee_waiver` nullable boolean (has()?1:0) | Ctrl |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index()/trashed() gate `tenant.adm-quota-config.viewAny` | Ctrl |
| BC-AUTH-02 | create()/store() gate `tenant.adm-quota-config.create` | Ctrl |
| BC-AUTH-03 | show() gate `tenant.adm-quota-config.view` | Ctrl |
| BC-AUTH-04 | edit()/update() gate `tenant.adm-quota-config.update` | Ctrl |
| BC-AUTH-05 | destroy() gate `tenant.adm-quota-config.delete` | Ctrl |
| BC-AUTH-06 | restore() gate `tenant.adm-quota-config.restore` | Ctrl |
| BC-AUTH-07 | forceDelete() gate `tenant.adm-quota-config.forceDelete` | Ctrl |
| BC-AUTH-08 | toggleStatus() gate `tenant.adm-quota-config.update` | Ctrl |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | index() redirects to setup tab | Ctrl |
| BC-BIZ-02 | Setup tab: loads quotas for active cycle via AdmMenuController, search by quota_type, filter by is_active | AdmMenuCtrl |
| BC-BIZ-03 | Store: defaults is_active=1, application_fee_waiver via has(), created_by/updated_by=auth() | Ctrl |
| BC-BIZ-04 | Update: excludes admission_cycle_id, handles fee_waiver checkbox, logs 'Updated' | Ctrl |
| BC-BIZ-05 | Destroy: does NOT set is_active=false before soft-delete | Ctrl |
| BC-BIZ-06 | Toggle: uses request is_active or inverts, returns JSON with formatted quota name | Ctrl |
| BC-BIZ-07 | Trashed: onlyTrashed with schoolClass relation, ordered by id DESC, paginated 15 | Ctrl |
| BC-BIZ-08 | All CRUD logged via activityLog() | Ctrl |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Store total_seats=0 accepted (min:0); FormRequest uses min:1 | Ctrl vs FR |
| BC-EDG-02 | reserved_seats can exceed total_seats (no lte:total_seats in inline validation; FormRequest has lte) | Ctrl vs FR |
| BC-EDG-03 | duplicate (cycle_id, class_id, quota_type) possible inline (no unique rule; FormRequest uses updateOrInsert in seeder) | Ctrl |

---

## 2. Test Case List

### Screen 1: Quota Tab (GET /admission/setup?tab=quotas)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMQTA-P10 | Positive | View | Tab renders: search, status filter, table (Type, Class, Total, Reserved, Fee Waiver, Toggle, Actions) | Page rendered | test_adm_qta_10 | Automated |
| TC-ADMQTA-P11 | Positive | View | Search by quota_type, filter by is_active | Filtered | test_adm_qta_11 | Automated |
| TC-ADMQTA-P12 | Positive | View | Fee Waiver badge (Yes/No), status toggle, Add New button | Elements | test_adm_qta_12 | Automated |
| TC-ADMQTA-P13 | Positive | View | Empty state "No Quotas Configured" | Empty state | test_adm_qta_13 | Automated |

### Screen 2: Create + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMQTA-P30 | Positive | View | Create form: cycle, class, quota_type, total_seats, reserved_seats, fee_waiver checkbox | All fields | test_adm_qta_30 | Automated |
| TC-ADMQTA-P31 | Positive | Ctrl | Valid create: is_active=1, logs 'Stored' | Created | test_adm_qta_31 | Automated |
| TC-ADMQTA-P32 | Positive | Ctrl | Fee waiver checked=1, unchecked=0 | Correct | test_adm_qta_32 | Automated |
| TC-ADMQTA-N33 | Negative | Val | Empty class_id/quota_type → required rejects | Errors | test_adm_qta_33 | Automated |
| TC-ADMQTA-N34 | Negative | Val | Invalid quota_type → in:[] rejects | Error | test_adm_qta_34 | Automated |
| TC-ADMQTA-N35 | Negative | Val | Invalid cycle_id/class_id → exists rejects | Errors | test_adm_qta_35 | Automated |

### Screen 3: Show, Edit, Update, Trash Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMQTA-P60 | Positive | View | Show renders all fields with Edit button | Visible | test_adm_qta_60 | Automated |
| TC-ADMQTA-P61 | Positive | View | Edit pre-populates, update succeeds | Pre-filled | test_adm_qta_61 | Automated |
| TC-ADMQTA-P62 | Positive | Ctrl | Soft-delete → trash → restore → force delete lifecycle | Lifecycle | test_adm_qta_62 | Automated |
| TC-ADMQTA-P70 | Positive | Ctrl | Toggle on/off returns JSON | JSON | test_adm_qta_70 | Automated |

### Authorization

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMQTA-P140 | Positive | Auth | CRUD with correct permissions = 200 | 200 | test_adm_qta_140 | Automated |
| TC-ADMQTA-N141 | Negative | Auth | Without permissions → 403 | 403 | test_adm_qta_141 | Automated |
