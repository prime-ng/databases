# adm_AdmissionCycle — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Cycles (CRUD + Soft-Delete + Toggle Status + Activate/Close)
**DB scope:** TENANT-side (`adm_admission_cycles` → tenant DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary table:** `adm_admission_cycles` · **Module URL prefix:** `/admission/setup?tab=cycles`
**Test file:** `adm_AdmissionCycle_TestCas.php`
**Tab:** Cycles (first tab of the Admission Setup page)

Controller:
- `AdmissionCycleController` — CRUD + trash + toggle + activate/close

Routes (grouped under `adm.` prefix):
- `GET/POST /admission/cycles` — index (GET), store (POST)
- `GET /admission/cycles/create` — create
- `GET /admission/cycles/{cycle}` — show
- `GET/PUT /admission/cycles/{cycle}/edit` — edit (GET), update (PUT)
- `DELETE /admission/cycles/{cycle}` — destroy
- `GET /admission/cycles/trash/view` — trashed list
- `GET /admission/cycles/{id}/restore` — restore
- `DELETE /admission/cycles/{id}/force-delete` — force delete
- `POST /admission/cycles/{id}/toggle-status` — toggle status (AJAX)
- `POST /admission/cycles/{cycle}/activate` — activate draft cycle
- `POST /admission/cycles/{cycle}/close` — close active cycle

Views:
- `index.blade.php` — cycles index listing
- `create.blade.php` — create form
- `edit.blade.php` — edit form
- `show.blade.php` — cycle detail view
- `trash.blade.php` — soft-deleted cycles list
- `_cycles.blade.php` — partial used in setup tabbed page
- `_cycle-form.blade.php` — reusable form partial
- `setup.blade.php` — parent setup page with tab navigation

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_admission_cycles`: id (BIGINT PK AI), academic_session_id (SMALLINT UNSIGNED FK), name (VARCHAR 100), cycle_code (VARCHAR 20 UNIQUE), start_date (DATE), end_date (DATE), application_fee (DECIMAL 10,2 DEFAULT 0.00), admission_no_format (VARCHAR 100 NULLABLE), sibling_bonus_score (TINYINT UNSIGNED DEFAULT 5), age_rules_json (JSON NULLABLE), refund_policy_json (JSON NULLABLE), application_form_url (VARCHAR 255 NULLABLE), status (ENUM Draft,Active,Closed,Archived DEFAULT Draft), is_active (TINYINT DEFAULT 1), created_by (BIGINT UNSIGNED), updated_by (BIGINT UNSIGNED), created_at, updated_at, deleted_at | DDL |
| BC-DB-02 | Model `AdmissionCycle`: table `adm_admission_cycles`, SoftDeletes, fillable: 14 columns | AdmissionCycle.php:19-35 |
| BC-DB-03 | Casts: start_date/end_date → date, application_fee → decimal:2, age_rules_json/refund_policy_json → array, is_active → boolean | AdmissionCycle.php:37-44 |
| BC-DB-04 | Relationships: academicSession (BelongsTo), documentChecklist (HasMany), quotaConfigs (HasMany), seatCapacities (HasMany), entranceTests (HasMany), enquiries (HasMany), meritLists (HasMany), applications (HasMany) | AdmissionCycle.php:51-89 |
| BC-DB-05 | Scope: scopeActive() filters by status='Active' AND is_active=true | AdmissionCycle.php:46-49 |
| BC-DB-06 | Foreign key: academic_session_id → sch_org_academic_sessions_jnt(id) ON UPDATE CASCADE | Migration |
| BC-DB-07 | Indexes: idx_adm_cyc_session (academic_session_id), idx_adm_cyc_status (status) | Migration |

### BC-VAL — Validation (Store & Update Request)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `academic_session_id` required integer exists:sch_org_academic_sessions_jnt,id | Req:58,60 |
| BC-VAL-02 | `name` required string max:100 | Req:59,61 |
| BC-VAL-03 | `cycle_code` required string max:20 unique (ignore current id on update) | Req:60,62 |
| BC-VAL-04 | `start_date` required date | Req:61,63 |
| BC-VAL-05 | `end_date` required date after:start_date | Req:62,64 |
| BC-VAL-06 | `application_fee` nullable numeric min:0 | Req:63,65 |
| BC-VAL-07 | `admission_no_format` nullable string max:100 | Req:64,66 |
| BC-VAL-08 | `sibling_bonus_score` nullable integer min:0 max:100 | Req:65,67 |
| BC-VAL-09 | `status` required string in:Draft,Active,Archived,Closed | Req:66,68 |
| BC-VAL-10 | `is_active` required boolean | Req:67,69 |
| BC-VAL-11 | `age_rules_json` nullable (JSON string→array in prepareForValidation) | Req:68,70 |
| BC-VAL-12 | `refund_policy_json` nullable (JSON string→array in prepareForValidation) | Req:69,71 |
| BC-VAL-13 | `application_form_url` nullable url max:255 | Req:70,72 |
| BC-VAL-14 | prepareForValidation: is_active→boolean(), decode age_rules_json/refund_policy_json | Req:20-52 |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index()/trashed() gate `tenant.adm-cycle.viewAny` | Ctrl:31,259 |
| BC-AUTH-02 | create()/store() gate `tenant.adm-cycle.create` | Ctrl:60,74 |
| BC-AUTH-03 | show() gate `tenant.adm-cycle.view` | Ctrl:99 |
| BC-AUTH-04 | edit()/update() gate `tenant.adm-cycle.update` | Ctrl:128,142 |
| BC-AUTH-05 | destroy() gate `tenant.adm-cycle.delete` | Ctrl:176 |
| BC-AUTH-06 | restore() gate `tenant.adm-cycle.restore` | Ctrl:269 |
| BC-AUTH-07 | forceDelete() gate `tenant.adm-cycle.forceDelete` | Ctrl:282 |
| BC-AUTH-08 | toggleStatus() gate `tenant.adm-cycle.update` | Ctrl:197 |
| BC-AUTH-09 | activate()/close() gate `tenant.adm-cycle.status` | Ctrl:231,245 |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Index: searches by name/cycle_code LIKE, filters by is_active, orders by id DESC, paginates 15 | Ctrl:33-46 |
| BC-BIZ-02 | Index: passes active academic sessions for filter dropdown | Ctrl:48-50 |
| BC-BIZ-03 | Store: defaults status=Draft, is_active=false, created_by/updated_by=auth()->id() | Ctrl:76-80 |
| BC-BIZ-04 | Store: logs 'Stored', redirects to adm.menu.setup?tab=cycles | Ctrl:84-91 |
| BC-BIZ-05 | Update: aborts 403 if status='Archived' | Ctrl:143 |
| BC-BIZ-06 | Update: tracks attribute changes, logs 'Updated' with old/new values | Ctrl:145-164 |
| BC-BIZ-07 | Destroy: sets is_active=false, saves, soft-deletes, logs 'Trashed' | Ctrl:178-189 |
| BC-BIZ-08 | Activate: pipeline activates Draft→Active, checks no other active per session | Ctrl:229-237, Pipeline |
| BC-BIZ-09 | Close: pipeline closes Active→Closed | Ctrl:243-251, Pipeline |
| BC-BIZ-10 | Toggle: AJAX, flips is_active, returns JSON {success, is_active, message} | Ctrl:195-224 |
| BC-BIZ-11 | Trashed: onlyTrashed, ordered by name, paginated 15 | Ctrl:257-261 |
| BC-BIZ-12 | Restore: onlyTrashed→restore, logs 'Restored' | Ctrl:267-274 |
| BC-BIZ-13 | ForceDelete: withTrashed→forceDelete, logs 'Deleted' | Ctrl:280-287 |
| BC-BIZ-14 | Show: loads academicSession, documentChecklist (sorted), active quotas, seatCapacities, counts stats | Ctrl:97-121 |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Non-existing id for show/edit/update/destroy → 404 | Ctrl |
| BC-EDG-02 | withTrashed/onlyTrashed for restore/forceDelete → 404 if not found | Ctrl:270,283 |
| BC-EDG-03 | Archived cycle update → 403 abort | Ctrl:143 |
| BC-EDG-04 | Activate/close DomainException → caught, redirected with error flash | Ctrl:234-236,248-250 |
| BC-EDG-05 | end_date before start_date → validation rejects | BC-VAL-05 |
| BC-EDG-06 | Duplicate cycle_code → unique constraint rejects | BC-VAL-03 |
| BC-EDG-07 | application_fee negative → min:0 rejects | BC-VAL-06 |
| BC-EDG-08 | sibling_bonus_score >100 → max:100 rejects | BC-VAL-08 |

---

## 2. Test Case List

### Screen 1: Cycles Index / Setup Tab (GET /admission/setup?tab=cycles)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMCYC-P10 | Positive | Ctrl | Index renders with search, status filter, table, pagination | Page rendered | test_adm_cycle_10 | Automated |
| TC-ADMCYC-P11 | Positive | Ctrl | Search by name/cycle_code narrows results | Filtered | test_adm_cycle_11 | Automated |
| TC-ADMCYC-P12 | Positive | Ctrl | Filter by is_active status narrows results | Filtered | test_adm_cycle_12 | Automated |
| TC-ADMCYC-P13 | Positive | Ctrl | Paginated (15 per page) | Paginated | test_adm_cycle_13 | Automated |
| TC-ADMCYC-P14 | Positive | View | Rows: Name, Code, Session, Start/End Date, Status badge, Actions | Columns visible | test_adm_cycle_14 | Automated |
| TC-ADMCYC-P15 | Positive | View | Status badges color-coded (Draft=gray, Active=green, Closed=red, Archived=dark) | Badge colors | test_adm_cycle_15 | Automated |
| TC-ADMCYC-P16 | Positive | View | Add New button, Trash link (permission-gated) | Links visible | test_adm_cycle_16 | Automated |
| TC-ADMCYC-P17 | Positive | View | Empty state when no records | "No records found" | test_adm_cycle_17 | Automated |

### Screen 2: Create Form (GET /admission/cycles/create)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMCYC-P30 | Positive | View | All fields rendered: academic_session_id, name, cycle_code, start_date, end_date, application_fee, admission_no_format, sibling_bonus_score, status, is_active, age_rules_json, refund_policy_json, application_form_url | All fields | test_adm_cycle_30 | Automated |
| TC-ADMCYC-P31 | Positive | View | Academic session dropdown shows only active sessions | Sessions loaded | test_adm_cycle_31 | Automated |

### Screen 3: Store (POST /admission/cycles)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMCYC-P40 | Positive | Ctrl | Valid create succeeds, defaults status=Draft/is_active=false, redirects with success flash | Created | test_adm_cycle_40 | Automated |
| TC-ADMCYC-P41 | Positive | Ctrl | Activity logged ('Stored') | Logged | test_adm_cycle_41 | Automated |
| TC-ADMCYC-N42 | Negative | Val | Empty required fields → validation errors | Errors | test_adm_cycle_42 | Automated |
| TC-ADMCYC-N43 | Negative | Val | Duplicate cycle_code → unique error | Error | test_adm_cycle_43 | Automated |
| TC-ADMCYC-N44 | Negative | Val | end_date before start_date → after rule rejects | Error | test_adm_cycle_44 | Automated |
| TC-ADMCYC-N45 | Negative | Val | Negative application_fee → min:0 rejects | Error | test_adm_cycle_45 | Automated |
| TC-ADMCYC-N46 | Negative | Val | sibling_bonus_score >100 → max:100 rejects | Error | test_adm_cycle_46 | Automated |
| TC-ADMCYC-N47 | Negative | Val | Invalid status value → in:Draft,Active,Archived,Closed rejects | Error | test_adm_cycle_47 | Automated |

### Screen 4: Show (GET /admission/cycles/{cycle})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMCYC-P60 | Positive | Ctrl | Show renders header, stats, details, tabs (Checklist/Quotas/Seats) | Page rendered | test_adm_cycle_60 | Automated |
| TC-ADMCYC-P61 | Positive | View | Activate button visible only for Draft, Close only for Active | Conditional | test_adm_cycle_61 | Automated |
| TC-ADMCYC-P62 | Positive | Ctrl | JSON request returns cycle data with academic session | JSON | test_adm_cycle_62 | Automated |

### Screen 5: Edit + Update (GET+PUT /admission/cycles/{cycle})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMCYC-P70 | Positive | View | Edit form pre-populated with existing data | Pre-filled | test_adm_cycle_70 | Automated |
| TC-ADMCYC-P71 | Positive | Ctrl | Valid update succeeds, tracks changes, logs 'Updated' | Updated | test_adm_cycle_71 | Automated |
| TC-ADMCYC-N72 | Negative | Biz | Update archived cycle → 403 | 403 | test_adm_cycle_72 | Automated |

### Screen 6: Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMCYC-P90 | Positive | Ctrl | Soft-delete: is_active=false, soft-deletes, logs 'Trashed' | Trashed | test_adm_cycle_90 | Automated |
| TC-ADMCYC-P91 | Positive | Ctrl | Restore: onlyTrashed→restore, logs 'Restored' | Restored | test_adm_cycle_91 | Automated |
| TC-ADMCYC-P92 | Positive | Ctrl | Force delete: withTrashed→forceDelete, logs 'Deleted' | Perm deleted | test_adm_cycle_92 | Automated |

### Screen 7: Toggle Status (POST /admission/cycles/{id}/toggle-status)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMCYC-P100 | Positive | Ctrl | Toggle on/off returns JSON {success, is_active, message} | JSON | test_adm_cycle_100 | Automated |
| TC-ADMCYC-P101 | Positive | Ctrl | Activity logged ('Toggled') | Logged | test_adm_cycle_101 | Automated |

### Screen 8: Activate / Close

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMCYC-P110 | Positive | Biz | Activate Draft→Active | Activated | test_adm_cycle_110 | Automated |
| TC-ADMCYC-P111 | Positive | Biz | Close Active→Closed | Closed | test_adm_cycle_111 | Automated |
| TC-ADMCYC-N112 | Negative | Biz | Activate non-Draft → DomainException error flash | Error | test_adm_cycle_112 | Automated |
| TC-ADMCYC-N113 | Negative | Biz | Activate when another active exists → DomainException | Error | test_adm_cycle_113 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMCYC-P140 | Positive | Auth | Index/trash with viewAny = 200 | 200 | test_adm_cycle_140 | Automated |
| TC-ADMCYC-P141 | Positive | Auth | Create/store with create = 200 | 200 | test_adm_cycle_141 | Automated |
| TC-ADMCYC-P142 | Positive | Auth | Show with view = 200 | 200 | test_adm_cycle_142 | Automated |
| TC-ADMCYC-P143 | Positive | Auth | Edit/update with update = 200 | 200 | test_adm_cycle_143 | Automated |
| TC-ADMCYC-P144 | Positive | Auth | Destroy with delete = 200 | 200 | test_adm_cycle_144 | Automated |
| TC-ADMCYC-P145 | Positive | Auth | Restore with restore = 200 | 200 | test_adm_cycle_145 | Automated |
| TC-ADMCYC-P146 | Positive | Auth | forceDelete with forceDelete = 200 | 200 | test_adm_cycle_146 | Automated |
| TC-ADMCYC-P147 | Positive | Auth | Activate/close with status = 200 | 200 | test_adm_cycle_147 | Automated |
| TC-ADMCYC-N148 | Negative | Auth | Without viewAny → 403 | 403 | test_adm_cycle_148 | Automated |
| TC-ADMCYC-N149 | Negative | Auth | Without create → 403 | 403 | test_adm_cycle_149 | Automated |
| TC-ADMCYC-N150 | Negative | Auth | Without update → 403 | 403 | test_adm_cycle_150 | Automated |
| TC-ADMCYC-N151 | Negative | Auth | Without delete → 403 | 403 | test_adm_cycle_151 | Automated |
| TC-ADMCYC-N152 | Negative | Auth | Without status → 403 on activate/close | 403 | test_adm_cycle_152 | Automated |
