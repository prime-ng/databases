# hrs_appraisalCycles_TcList

## Module: HrStaff → Appraisals → Appraisal Cycles

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | Appraisals |
| Feature | Appraisal Cycles |
| URL(s) | `GET /appraisals-overview?tab=appraisal-cycles` (combined page), `GET /appraisal-cycles` (index), `POST /appraisal-cycles` (store), `GET /appraisal-cycles/{appraisalCycle}` (show), `GET /appraisal-cycles/{appraisalCycle}/edit` (edit), `PUT /appraisal-cycles/{appraisalCycle}` (update), `DELETE /appraisal-cycles/{appraisalCycle}` (destroy), `POST /appraisal-cycles/{appraisalCycle}/toggle-status` (toggleStatus), `GET /appraisal-cycles/trash/view` (trashed), `GET /appraisal-cycles/{id}/restore` (restore), `DELETE /appraisal-cycles/{id}/force-delete` (forceDelete) |
| Controller | `Modules\HrStaff\Http\Controllers\AppraisalController` — `cycleIndex()` lines 186-196, `cycleStore()` lines 198-218, `cycleShow()` lines 220-227, `cycleEdit()` lines 229-238, `cycleUpdate()` lines 304-315, `cycleToggleStatus()` lines 240-251, `cycleDestroy()` lines 253-268, `cycleTrashed()` lines 270-277, `cycleRestore()` lines 279-290, `cycleForceDelete()` lines 292-302 |
| Model(s) | `Modules\HrStaff\Models\AppraisalCycle` (table: `hrs_appraisal_cycles`) |
| Validation (Create) | `Modules\HrStaff\Http\Requests\StoreAppraisalCycleRequest` |
| Validation (Update) | `Modules\HrStaff\Http\Requests\StoreAppraisalCycleRequest` |
| Policy | `Modules\HrStaff\Policies\AppraisalCyclePolicy` |
| Permissions | `hrs.appraisal.manage` (all operations); policy restricts update/delete to draft status |
| Pagination | `cycleIndex()` — no pagination (all records); `cycleTrashed()` — 15 per page |
| Soft Deletes | Yes — `AppraisalCycle` uses `SoftDeletes` trait |
| Data Source | Direct CRUD — records created in `hrs_appraisal_cycles` |
| Activity Log | Events: `Created`, `Updated`, `Trashed`, `Restored`, `Deleted` (forceDelete) |

---

## 2. Pre-conditions

- Required permissions: `hrs.appraisal.manage`
- Required seed data: At least one active `KpiTemplate`, one active `OrganizationAcademicSession`, one active `Department`
- For edit form: Active KPI templates and academic sessions must exist in the database
- Test user must have `hrs.appraisal.manage` permission
- Tenant context must be initialized
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For delete-blocked test: Create at least one appraisal record for the cycle being deleted
- For date-validation tests: Self close before manager open scenario

---

## 3. Default Data Load

When the page loads via `HrMenuController@appraisalsIncrements()` (GET `/appraisals-overview?tab=appraisal-cycles`):

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Appraisal Cycles Grid | `HrMenuController@appraisalsIncrements()` | `AppraisalCycle::with(['academicYear', 'kpiTemplate'])->orderByDesc('self_open_date')->get()` | None (loads all) | None |
| Shared: Academic Years | `HrMenuController@appraisalsIncrements()` | `OrganizationAcademicSession::orderBy('start_date', 'desc')->get()` | None | None |
| Shared: Departments | `HrMenuController@appraisalsIncrements()` | `Department::where('is_active', true)->orderBy('name')->get()` | is_active=1 | None |

> For the edit form, `cycleEdit()` additionally loads active KPI templates.

---

## 4. Test Data Strategy

- Create test cycles with unique names using `uniqueSuffix()` pattern
- Create cycles in each status (draft, active, closed) for edit/delete restriction tests
- For date window validation: use specific dates (self_open < self_close; self_close <= manager_open; manager_open < manager_close)
- For department filter: create at least 2 departments, assign only one to the cycle
- For pagination in trash: create 16+ cycles, soft-delete them
- Pre-test cleanup: Delete created cycles by ID

---

## 5. Business Conditions

### 5.1 Database Schema — `hrs_appraisal_cycles`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | name | VARCHAR(200) | NOT NULL |
| BC-DB-03 | academic_year_id | SMALLINT UNSIGNED | NOT NULL, FK → `sch_org_academic_sessions_jnt.id` |
| BC-DB-04 | appraisal_type | ENUM('annual','mid_year','probation','confirmation') | NOT NULL |
| BC-DB-05 | kpi_template_id | BIGINT UNSIGNED | NOT NULL, FK → `hrs_kpi_templates.id` |
| BC-DB-06 | self_open_date | DATE | NOT NULL |
| BC-DB-07 | self_close_date | DATE | NOT NULL |
| BC-DB-08 | manager_open_date | DATE | NOT NULL |
| BC-DB-09 | manager_close_date | DATE | NOT NULL |
| BC-DB-10 | applicable_departments | JSON | NULL |
| BC-DB-11 | reviewer_mode | ENUM('auto','manual') | NOT NULL, DEFAULT 'auto' |
| BC-DB-12 | status | ENUM('draft','active','closed') | NOT NULL, DEFAULT 'draft' |
| BC-DB-13 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-14 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-15 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-16 | created_at | TIMESTAMP | NULL |
| BC-DB-17 | updated_at | TIMESTAMP | NULL |
| BC-DB-18 | deleted_at | TIMESTAMP | NULL — Soft delete |

### 5.2 Validation Rules — StoreAppraisalCycleRequest (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | name | required, string, max:200 | — |
| BC-VAL-02 | academic_year_id | required, exists:sch_org_academic_sessions_jnt,id | — |
| BC-VAL-03 | appraisal_type | required, in:annual,mid_year,probation,confirmation | — |
| BC-VAL-04 | kpi_template_id | required, exists:hrs_kpi_templates,id | — |
| BC-VAL-05 | self_open_date | required, date | — |
| BC-VAL-06 | self_close_date | required, date, after:self_open_date | — |
| BC-VAL-07 | manager_open_date | required, date, after_or_equal:self_close_date | — |
| BC-VAL-08 | manager_close_date | required, date, after:manager_open_date | — |
| BC-VAL-09 | applicable_departments | nullable, array | — |
| BC-VAL-10 | applicable_departments.* | integer, exists:sch_departments,id | — |
| BC-VAL-11 | reviewer_mode | required, in:auto,manual | — |
| BC-VAL-12 | is_active | required, boolean | — (auto-merged) |

### 5.3 Business Logic Service Check — createCycle()

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-VAL-13 | Service: manager_open_date >= self_close_date (BR-HRS-018) | DomainException thrown if violated |

### 5.4 Validation Rules — StoreAppraisalCycleRequest (Update)

Same rules as Create (BC-VAL-01 through BC-VAL-12). `updateCycle()` additionally checks `status === 'draft'`.

### 5.5 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `hrs.appraisal.manage` | Granted — all cycle operations succeed |
| BC-AUTH-02 | `hrs.appraisal.manage` | Denied — 403 Forbidden on all operations |
| BC-AUTH-03 | Guest access | Redirect to /login |
| BC-AUTH-04 | `hrs.appraisal.manage` + status=draft | Update and delete allowed |
| BC-AUTH-05 | `hrs.appraisal.manage` + status=active | Update and delete denied (policy: status must be draft) |

### 5.6 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-----------------|
| BC-BIZ-01 | Page load (cycles tab) | All cycles listed with academic year, KPI template, type, status, date windows |
| BC-BIZ-02 | Create cycle with all fields, valid dates | Cycle created in draft status, flash success |
| BC-BIZ-03 | Create cycle with department restriction | applicable_departments JSON saved |
| BC-BIZ-04 | Create cycle with reviewer_mode=auto | Cycle created with auto mode |
| BC-BIZ-05 | Create cycle with reviewer_mode=manual | Cycle created with manual mode |
| BC-BIZ-06 | Create each appraisal_type (annual, mid_year, probation, confirmation) | Each type saved correctly |
| BC-BIZ-07 | Update draft cycle (name, dates) | Updated, flash success |
| BC-BIZ-08 | Update active cycle | DomainException: "Cannot update cycle with status: active" |
| BC-BIZ-09 | Update closed cycle | DomainException: "Cannot update cycle with status: closed" |
| BC-BIZ-10 | Toggle status active↔inactive | JSON success |
| BC-BIZ-11 | Delete draft cycle with no appraisals | Soft-deleted, flash "Appraisal cycle removed." |
| BC-BIZ-12 | Delete cycle with appraisals | Error "Cannot delete a cycle that has appraisals linked to it." |
| BC-BIZ-13 | Show cycle details | Cycle loaded with KPI template items, appraisals, academic year |
| BC-BIZ-14 | Edit form loads with existing data | Edit form pre-filled |
| BC-BIZ-15 | View trashed cycles | Only trashed cycles, paginated 15/page |
| BC-BIZ-16 | Restore trashed cycle | Restored, is_active=true, flash success |
| BC-BIZ-17 | Force delete trashed cycle | Permanently deleted (policy returns false — forceDelete not permitted) |
| BC-BIZ-18 | Empty state — no cycles | Grid shows no records |

### 5.7 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `academic_year_id` | `sch_org_academic_sessions_jnt.id` | — (DDL has FK but no ON DELETE specified) |
| BC-REF-02 | `kpi_template_id` | `hrs_kpi_templates.id` | — (DDL has FK but no ACTION specified) |
| BC-REF-03 | `hrs_appraisals.cycle_id` | `hrs_appraisal_cycles.id` | — (blocks delete via controller check) |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Load Appraisal Cycles tab page | Grid loads all cycles with academic year, type, status, date windows | — | — | ⬜ |
| TC-P02 | Create cycle (annual, all fields, valid dates) | Created in draft, flash success "Appraisal cycle created." | — | — | ⬜ |
| TC-P03 | Create cycle (mid_year type) | Created with appraisal_type=mid_year | — | — | ⬜ |
| TC-P04 | Create cycle (probation type) | Created with appraisal_type=probation | — | — | ⬜ |
| TC-P05 | Create cycle (confirmation type) | Created with appraisal_type=confirmation | — | — | ⬜ |
| TC-P06 | Create cycle with department restriction | applicable_departments JSON saved with selected department IDs | — | — | ⬜ |
| TC-P07 | Create cycle with reviewer_mode=auto | reviewer_mode set to auto | — | — | ⬜ |
| TC-P08 | Create cycle with reviewer_mode=manual | reviewer_mode set to manual | — | — | ⬜ |
| TC-P09 | Create cycle with self_close on same day as manager_open | Valid — manager_open_date >= self_close_date | — | — | ⬜ |
| TC-P10 | View single cycle details | Show page with KPI template items, appraisals list, cycle info | — | — | ⬜ |
| TC-P11 | Edit draft cycle form loads | Edit form pre-filled with existing data | — | — | ⬜ |
| TC-P12 | Update draft cycle name and dates | Updated, flash "Appraisal cycle updated." | — | — | ⬜ |
| TC-P13 | Toggle cycle active→inactive | AJAX success, is_active flipped, JSON | — | — | ⬜ |
| TC-P14 | Soft-delete draft cycle with no appraisals | Trashed, flash "Appraisal cycle removed." | — | — | ⬜ |
| TC-P15 | View trashed cycles | Only trashed, paginated 15/page | — | — | ⬜ |
| TC-P16 | Restore trashed cycle | Restored, is_active=true, flash "Appraisal cycle restored successfully." | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Create without name | Validation error: name required | — | — | ⬜ |
| TC-N02 | Create without academic_year_id | Validation error | — | — | ⬜ |
| TC-N03 | Create with invalid appraisal_type | Validation error: in:annual,mid_year,probation,confirmation | — | — | ⬜ |
| TC-N04 | Create without kpi_template_id | Validation error | — | — | ⬜ |
| TC-N05 | Create with self_close_date before self_open_date | Validation error: after:self_open_date | — | — | ⬜ |
| TC-N06 | Create with manager_open_date before self_close_date | Validation error: after_or_equal:self_close_date | — | — | ⬜ |
| TC-N07 | Create with manager_close_date before manager_open_date | Validation error: after:manager_open_date | — | — | ⬜ |
| TC-N08 | Create with manager_open_date < self_close_date (service-level) | DomainException from AppraisalService: "Manager open date must be on or after self-appraisal close date (BR-HRS-018)." | — | — | ⬜ |
| TC-N09 | Update active cycle | Error "Cannot update cycle with status: active" | — | — | ⬜ |
| TC-N10 | Update closed cycle | Error "Cannot update cycle with status: closed" | — | — | ⬜ |
| TC-N11 | Delete cycle with appraisals | Error "Cannot delete a cycle that has appraisals linked to it." | — | — | ⬜ |
| TC-N12 | Force delete cycle (policy returns false) | 403 Forbidden (policy forceDelete returns false) | — | — | ⬜ |
| TC-N13 | Access without permission | 403 Forbidden | — | — | ⬜ |
| TC-N14 | Guest access | Redirect to /login | — | — | ⬜ |
| TC-N15 | Access non-existent cycle ID | 404 Not Found | — | — | ⬜ |
| TC-N16 | Create with invalid department ID in array | Validation error: exists:sch_departments,id | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Activity logging — create/update/delete logged | activityLog() called on all state changes | — | — | ⬜ |
| TC-D02 | B | Model casting — dates cast as date, applicable_departments as array | Correct PHP types | — | — | ⬜ |
| TC-D03 | B | Model relationship — cycle belongsTo academicYear | academicYear() returns correct session | — | — | ⬜ |
| TC-D04 | B | Model relationship — cycle belongsTo kpiTemplate | kpiTemplate() returns correct template | — | — | ⬜ |
| TC-D05 | B | Model relationship — cycle hasMany appraisals | appraisals() returns Appraisal collection | — | — | ⬜ |
| TC-D06 | C | Controller gate — all methods gate via hrs.appraisal.manage | AuthorizationException without permission | — | — | ⬜ |
| TC-D07 | D | FK academic_year_id references sch_org_academic_sessions_jnt | DB constraint enforced | — | — | ⬜ |
| TC-D08 | D | FK kpi_template_id references hrs_kpi_templates | DB constraint enforced | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns | All DDL columns in fillable array | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for dates/array/boolean | Dates cast to date, applicable_departments to array, is_active to boolean | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait | SoftDeletes used, deleted_at column exists | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined | academicYear(), kpiTemplate(), appraisals(), incrementFlags(), incrementPolicies() | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — exceptions handled (DomainException catch) | cycleStore and cycleUpdate catch DomainException and return error | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transactions on multi-step writes | createCycle/updateCycle use transactions via service | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — Gate::authorize() on every method | All cycle* methods gated by hrs.appraisal.manage | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — activity logged on all state changes | Create/update/delete/toggle/restore all call activityLog() | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — is_active=false before soft delete | cycleDestroy() sets is_active=false before delete() | — | — | ◌ |
| TC-CR10 | CR | P1 | Policy — update/delete restricted to draft status | AppraisalCyclePolicy::update/delete check status === 'draft' | — | — | ◌ |
| TC-CR11 | CR | P1 | Policy — forceDelete always returns false | forceDelete() method returns false | — | — | ◌ |
| TC-CR12 | CR | P1 | Request — prepareForValidation() normalizations | is_active merged as boolean with default true | — | — | ◌ |
| TC-CR13 | CR | P1 | Request — attributes() for friendly names | Friendly attribute names for date fields defined | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — $fillable Matches DDL Columns
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open AppraisalCycle model | File exists |
| 2 | Verify $fillable includes: name, academic_year_id, appraisal_type, kpi_template_id, self_open_date, self_close_date, manager_open_date, manager_close_date, applicable_departments, reviewer_mode, status, is_active, created_by, updated_by | All present |

#### TC-CR02: Model — $casts
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check $casts | self_open_date/self_close_date/manager_open_date/manager_close_date => date, applicable_departments => array, is_active => boolean |

#### TC-CR03: Model — SoftDeletes Trait
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check AppraisalCycle uses SoftDeletes | Trait present |

#### TC-CR04: Model — Relationships Defined
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify academicYear(), kpiTemplate(), appraisals(), incrementFlags(), incrementPolicies() | All defined with correct relation types |

#### TC-CR05: Controller — DomainException Caught
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check cycleStore() | Has catch (\DomainException $e) handling |
| 2 | Check cycleUpdate() | Has catch (\DomainException $e) handling |

#### TC-CR06: Controller — DB Transactions
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check AppraisalService@createCycle | No explicit DB::transaction() but calls AppraisalCycle::create() directly |
| 2 | Check AppraisalService@updateCycle | Same pattern — single create/update call |

#### TC-CR07: Controller — Gate::authorize()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check cycleIndex() | Gate::authorize('hrs.appraisal.manage') present |
| 2 | Check cycleStore() | Gate present |
| 3 | Check cycleShow() | Gate present |
| 4 | Check cycleEdit() | Gate present |
| 5 | Check cycleUpdate() | Gate present |
| 6 | Check cycleToggleStatus() | Gate present |
| 7 | Check cycleDestroy() | Gate present |
| 8 | Check cycleTrashed() | Gate present |
| 9 | Check cycleRestore() | Gate present |
| 10 | Check cycleForceDelete() | Gate present |

#### TC-CR08: Activity Logged On All State Changes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check cycleStore() | activityLog($cycle, 'Created', ...) present |
| 2 | Check cycleUpdate() | activityLog($cycle, 'Updated', ...) present |
| 3 | Check cycleDestroy() | activityLog($cycle, 'Trashed', ...) present |
| 4 | Check cycleRestore() | activityLog($cycle, 'Restored', ...) present |
| 5 | Check cycleForceDelete() | activityLog($cycle, 'Deleted', ...) present |

#### TC-CR09: is_active=false Before Soft Delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check cycleDestroy() | Sets is_active=false then calls delete() |

#### TC-CR10: Policy Update/Delete Restricted To Draft Status
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check AppraisalCyclePolicy::update() | Returns `$user->can('hrs.appraisal.manage') && $cycle->status === 'draft'` |
| 2 | Check AppraisalCyclePolicy::delete() | Same check |

#### TC-CR11: Policy ForceDelete Always Returns False
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check AppraisalCyclePolicy::forceDelete() | Returns false |

#### TC-CR12: Request prepareForValidation()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check StoreAppraisalCycleRequest::prepareForValidation() | Merges is_active as boolean with default true |

#### TC-CR13: Request Attributes()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check StoreAppraisalCycleRequest::attributes() | Friendly names for kpi_template_id, academic_year_id, date fields defined |

### 7.1 Positive TC Steps

#### TC-P01: Load Appraisal Cycles Tab Page
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Appraisals → Appraisal Cycles tab | Grid displays all cycles with name, type, academic year, status, date windows |

#### TC-P02: Create Cycle (Annual, All Fields, Valid Dates)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Add Cycle | Create form opens |
| 2 | Enter name "Annual TC-P02" | Name field set |
| 3 | Select academic year | Academic year selected |
| 4 | Select appraisal_type "annual" | Type set |
| 5 | Select a KPI template | Template selected |
| 6 | Set self_open_date = 2026-01-01 | Date set |
| 7 | Set self_close_date = 2026-01-31 | Date set |
| 8 | Set manager_open_date = 2026-01-31 | Date set |
| 9 | Set manager_close_date = 2026-02-28 | Date set |
| 10 | Select reviewer_mode = "auto" | Mode set |
| 11 | Click Save | Cycle created in draft, flash "Appraisal cycle created." |

#### TC-P03 Through TC-P08: Type/Mode/Department Variations
| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-P03 | Create cycle with appraisal_type=mid_year | Save | Created with mid_year type |
| TC-P04 | Create cycle with appraisal_type=probation | Save | Created with probation type |
| TC-P05 | Create cycle with appraisal_type=confirmation | Save | Created with confirmation type |
| TC-P06 | Create cycle, select specific departments | Save | applicable_departments JSON saved |
| TC-P07 | Create cycle with reviewer_mode=auto | Save | reviewer_mode=auto |
| TC-P08 | Create cycle with reviewer_mode=manual | Save | reviewer_mode=manual |

#### TC-P09: Create Cycle With Self_Close On Same Day As Manager_Open
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set self_close_date = 2026-01-31 and manager_open_date = 2026-01-31 | Same day allowed (after_or_equal) |
| 2 | Click Save | Cycle created successfully |

#### TC-P10: View Single Cycle Details
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "View" on a cycle | Show page with cycle info, KPI template items, appraisals list, academic year |

#### TC-P11: Edit Draft Cycle Form Loads
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Edit" on a draft cycle | Form pre-filled with existing data, KPI template/academic year/department dropdowns populated |

#### TC-P12: Update Draft Cycle Name And Dates
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit draft cycle | Form loads |
| 2 | Change name to "Updated TC-P12" | Name changed |
| 3 | Change self_close_date to 2026-02-05 | Date changed |
| 4 | Click Save | Updated, flash "Appraisal cycle updated." |

#### TC-P13: Toggle Cycle Active/Inactive
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click toggle on a cycle | JSON success, is_active flipped |

#### TC-P14: Soft-Delete Draft Cycle With No Appraisals
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Delete on a draft cycle with no appraisals | Confirmation |
| 2 | Confirm | Cycle trashed, flash "Appraisal cycle removed." |

#### TC-P15: View Trashed Cycles
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trash view | Only trashed cycles, paginated 15/page |

#### TC-P16: Restore Trashed Cycle
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Restore on a trashed cycle | Restored, is_active=true, flash success |

### 7.2 Negative TC Steps

#### TC-N01: Create Without Name
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave name blank | Empty |
| 2 | Fill all other required fields | Others filled |
| 3 | Click Save | Validation error: name is required |

#### TC-N02: Create Without Academic_Year_Id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave academic_year_id blank | Click Save → validation error |

#### TC-N03: Invalid Appraisal_Type
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set appraisal_type to "quarterly" | Not in allowed list |
| 2 | Click Save | Validation error |

#### TC-N04: Create Without KPI Template
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave kpi_template_id blank | Click Save → validation error |

#### TC-N05: Self_Close Before Self_Open
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set self_open = 2026-01-31, self_close = 2026-01-01 | Close before open |
| 2 | Click Save | Validation error: after:self_open_date |

#### TC-N06: Manager_Open Before Self_Close (Request Level)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set self_close = 2026-01-31, manager_open = 2026-01-30 | Manager open before self close |
| 2 | Click Save | Validation error: after_or_equal:self_close_date |

#### TC-N07: Manager_Close Before Manager_Open
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set manager_open = 2026-02-28, manager_close = 2026-02-01 | Close before open |
| 2 | Click Save | Validation error: after:manager_open_date |

#### TC-N08: Manager_Open Before Self_Close (Service Level)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set self_close=2026-01-31, manager_open=2026-01-30 (bypassing frontend validation) | Service throws DomainException: "Manager open date must be on or after self-appraisal close date (BR-HRS-018)." |

#### TC-N09: Update Active Cycle
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit an active-status cycle | Policy denies update |
| 2 | Click Save | DomainException: "Cannot update cycle with status: active" |

#### TC-N10: Update Closed Cycle
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit a closed-status cycle | Policy denies update |
| 2 | Click Save | DomainException |

#### TC-N11: Delete Cycle With Appraisals
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a cycle that has appraisal records | Error "Cannot delete a cycle that has appraisals linked to it." |

#### TC-N12: Force Delete Cycle
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt force-delete on a cycle | 403 Forbidden (policy forceDelete returns false) |

#### TC-N13: Access Without Permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without hrs.appraisal.manage | 403 Forbidden |

#### TC-N14: Guest Access
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, navigate to /appraisal-cycles | Redirect to /login |

#### TC-N15: Non-Existent Cycle ID
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to /appraisal-cycles/99999 | 404 Not Found |

#### TC-N16: Invalid Department ID
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create cycle with applicable_departments=[99999] | Validation error |

### 7.3 Dependency TC Steps

#### TC-D01: Activity Logging
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create, update, toggle, delete a cycle | Each action logged in activity log |

#### TC-D02: Model Casting
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check AppraisalCycle::$casts | Dates => date, applicable_departments => array, is_active => boolean |

#### TC-D03: Cycle BelongsTo AcademicYear
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load a cycle with academicYear relationship | cycle->academicYear returns OrganizationAcademicSession |

#### TC-D04: Cycle BelongsTo KpiTemplate
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load a cycle with kpiTemplate relationship | cycle->kpiTemplate returns KpiTemplate |

#### TC-D05: Cycle HasMany Appraisals
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load a cycle with appraisals | cycle->appraisals returns collection of Appraisal records |

#### TC-D06: Controller Gate
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify each cycle* method has Gate::authorize('hrs.appraisal.manage') | All present |

#### TC-D07: FK Academic_Year_Id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for hrs_appraisal_cycles | FK constraint on academic_year_id → sch_org_academic_sessions_jnt.id |

#### TC-D08: FK KPI Template_Id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for hrs_appraisal_cycles | FK constraint on kpi_template_id → hrs_kpi_templates.id |
