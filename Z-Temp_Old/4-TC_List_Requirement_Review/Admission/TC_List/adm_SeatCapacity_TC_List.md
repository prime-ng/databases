# adm_SeatCapacity — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Seat Capacity (CRUD + Soft-Delete + Toggle Status)
**DB scope:** TENANT-side (`adm_seat_capacity`) · **Test style:** Browser Dusk
**Primary table:** `adm_seat_capacity` · **Module URL prefix:** `/admission/setup?tab=seats`
**Test file:** `adm_SeatCapacity_TestCas.php`
**Tab:** Seat Capacity (fourth tab of Admission Setup)

Controller: `SeatCapacityController` — CRUD + trash + toggle

Routes (`adm.` prefix):
- `GET/POST /admission/seats` — store
- `GET /admission/seats/create` — create
- `GET /admission/seats/{seat}` — show
- `GET/PUT /admission/seats/{seat}/edit` — edit/update
- `DELETE /admission/seats/{seat}` — destroy
- `GET /admission/seats/trash/view` — trashed list
- `GET /admission/seats/{id}/restore` — restore
- `DELETE /admission/seats/{id}/force-delete` — force delete
- `POST /admission/seats/{id}/toggle-status` — toggle status (AJAX)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_seat_capacity`: id (BIGINT PK AI), admission_cycle_id (BIGINT UNSIGNED FK), class_id (INT UNSIGNED FK), quota_type (ENUM EWS,General,Government,Management,NRI,RTE,Sibling,Staff_Ward), total_seats (UNSIGNED SMALLINT), seats_allotted (UNSIGNED SMALLINT DEFAULT 0), seats_enrolled (UNSIGNED SMALLINT DEFAULT 0), is_active (BOOLEAN DEFAULT true), created_by, updated_by, created_at, updated_at, deleted_at | DDL |
| BC-DB-02 | Model `SeatCapacity`: table `adm_seat_capacity`, SoftDeletes, fillable: 9 columns, casts: total_seats/seats_allotted/seats_enrolled → integer, is_active → boolean | Model |
| BC-DB-03 | Accessor: available_seats = max(0, total_seats - seats_allotted) | Model |
| BC-DB-04 | Relationships: cycle() belongsTo AdmissionCycle, schoolClass() belongsTo SchoolClass | Model |
| BC-DB-05 | FK: admission_cycle_id → adm_admission_cycles CASCADE; class_id → sch_classes CASCADE | Migration |
| BC-DB-06 | UNIQUE: (admission_cycle_id, class_id, quota_type) — uq_adm_sc_cycle_class_quota | Migration |
| BC-DB-07 | Indexes: idx_adm_sc_cycle, idx_adm_sc_class | Migration |

### BC-VAL — Validation (Inline Controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `admission_cycle_id` required exists:adm_admission_cycles,id (store only) | Ctrl |
| BC-VAL-02 | `class_id` required exists:sch_classes,id | Ctrl |
| BC-VAL-03 | `quota_type` required in:General,Government,Management,RTE,NRI,Staff_Ward,Sibling,EWS + unique on (cycle, class, quota_type) | Ctrl |
| BC-VAL-04 | `total_seats` required integer min:1 | Ctrl |
| BC-VAL-05 | `is_active` nullable boolean (defaults to true if not provided) | Ctrl |
| BC-VAL-06 | Store auto-sets: seats_allotted=0, seats_enrolled=0 | Ctrl |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index()/trash() gate `tenant.adm-seat-capacity.viewAny` | Ctrl |
| BC-AUTH-02 | create()/store() gate `tenant.adm-seat-capacity.create` | Ctrl |
| BC-AUTH-03 | show() gate `tenant.adm-seat-capacity.view` | Ctrl |
| BC-AUTH-04 | edit()/update() gate `tenant.adm-seat-capacity.update` | Ctrl |
| BC-AUTH-05 | destroy() gate `tenant.adm-seat-capacity.delete` | Ctrl |
| BC-AUTH-06 | restore() gate `tenant.adm-seat-capacity.restore` | Ctrl |
| BC-AUTH-07 | forceDelete() gate `tenant.adm-seat-capacity.forceDelete` | Ctrl |
| BC-AUTH-08 | toggleStatus() gate `tenant.adm-seat-capacity.update` | Ctrl |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Setup tab: loads seat capacities for active cycle via AdmMenuController, search by quota_type/class, filter by is_active | AdmMenuCtrl |
| BC-BIZ-02 | Store: validates unique (cycle, class, quota_type) via Rule::unique, defaults is_active true, seats_allotted=0, seats_enrolled=0 | Ctrl |
| BC-BIZ-03 | Update: validates unique ignoring current id, handles is_active checkbox, logs 'Updated' | Ctrl |
| BC-BIZ-04 | Destroy: does NOT set is_active=false before soft-delete | Ctrl |
| BC-BIZ-05 | Toggle: uses request is_active or inverts, returns JSON with class+quota name | Ctrl |
| BC-BIZ-06 | available_seats accessor = max(0, total_seats - seats_allotted) | Model |
| BC-BIZ-07 | Trashed: onlyTrashed with cycle+schoolClass relations, paginated 15 | Ctrl |
| BC-BIZ-08 | All CRUD logged via activityLog() | Ctrl |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Duplicate (cycle, class, quota_type) → unique constraint rejects | BC-VAL-03 |
| BC-EDG-02 | total_seats=0 → min:1 rejects | BC-VAL-04 |
| BC-EDG-03 | seats_allotted increments from allotment process (not from this CRUD) | BC-DB-01 |

---

## 2. Test Case List

### Screen 1: Seat Capacity Tab (GET /admission/setup?tab=seats)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMSCT-P10 | Positive | View | Tab renders: search, status filter, table (Class, Quota, Total, Allotted/Enrolled, Available, Toggle, Actions) | Page rendered | test_adm_sct_10 | Automated |
| TC-ADMSCT-P11 | Positive | View | Search by quota_type, filter by is_active | Filtered | test_adm_sct_11 | Automated |
| TC-ADMSCT-P12 | Positive | View | Available seats column computed, Allotted/Enrolled badges, toggle, Add New | Elements | test_adm_sct_12 | Automated |
| TC-ADMSCT-P13 | Positive | View | Empty state "No Seats Configured" | Empty state | test_adm_sct_13 | Automated |

### Screen 2: Create + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMSCT-P30 | Positive | View | Create form: cycle, class, quota_type, total_seats, is_active checkbox | All fields | test_adm_sct_30 | Automated |
| TC-ADMSCT-P31 | Positive | Ctrl | Valid create: seats_allotted=0, seats_enrolled=0, logs 'Created' | Created | test_adm_sct_31 | Automated |
| TC-ADMSCT-P32 | Positive | Ctrl | is_active defaults to true when unchecked | Default active | test_adm_sct_32 | Automated |
| TC-ADMSCT-N33 | Negative | Val | Empty class/quota_type → required rejects | Errors | test_adm_sct_33 | Automated |
| TC-ADMSCT-N34 | Negative | Val | Duplicate (cycle, class, quota_type) → unique rejects | Error | test_adm_sct_34 | Automated |
| TC-ADMSCT-N35 | Negative | Val | total_seats=0 → min:1 rejects | Error | test_adm_sct_35 | Automated |
| TC-ADMSCT-N36 | Negative | Val | Invalid cycle_id/class_id → exists rejects | Errors | test_adm_sct_36 | Automated |

### Screen 3: Show, Edit, Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMSCT-P60 | Positive | View | Show renders: cycle, class, quota, total, allotted, enrolled, available, active status, Edit button | All fields | test_adm_sct_60 | Automated |
| TC-ADMSCT-P61 | Positive | View | Edit pre-populates form | Pre-filled | test_adm_sct_61 | Automated |
| TC-ADMSCT-P62 | Positive | Ctrl | Update succeeds, logs 'Updated' | Updated | test_adm_sct_62 | Automated |
| TC-ADMSCT-P63 | Positive | Ctrl | Available seats = max(0, total - allotted) | Computed | test_adm_sct_63 | Automated |

### Screen 4: Trash Lifecycle + Toggle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMSCT-P90 | Positive | Ctrl | Soft-delete → trash → restore → force delete lifecycle | Lifecycle | test_adm_sct_90 | Automated |
| TC-ADMSCT-P100 | Positive | Ctrl | Toggle on/off returns JSON with class+quota message | JSON | test_adm_sct_100 | Automated |

### Authorization

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMSCT-P140 | Positive | Auth | CRUD with correct permissions = 200 | 200 | test_adm_sct_140 | Automated |
| TC-ADMSCT-N141 | Negative | Auth | Without permissions → 403 | 403 | test_adm_sct_141 | Automated |
