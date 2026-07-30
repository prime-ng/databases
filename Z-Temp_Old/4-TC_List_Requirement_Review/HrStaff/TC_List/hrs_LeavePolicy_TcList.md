# hrs_LeavePolicy_TcList

## Module: HrStaff → Leave Management → Leave Policy

## 1. Feature Information

| Item | Details |
|------|---------|
| Module / Tab Group / Feature | HrStaff / Leave Management / Leave Policy |
| URL(s) | `GET /leave-policy` (`hr-staff.leave-policy.show`), `PUT /leave-policy` (`hr-staff.leave-policy.update`) |
| Controller | `Modules\HrStaff\Http\Controllers\LeaveController::policy()` lines 27–35, `updatePolicy()` lines 40–61 |
| Model(s) | `Modules\HrStaff\Models\LeavePolicy` (table: `hrs_leave_policies`) |
| Validation (Update) | `Modules\HrStaff\Http\Requests\UpdateLeavePolicyRequest` |
| Policy | None — direct `Gate::authorize('hrs.leave_type.manage')` in controller |
| Permissions | `hrs.leave_type.manage` |
| Pagination | None (single-record view) |
| Soft Deletes | Yes — `SoftDeletes` trait on model |
| Read-Only | No — policy can be updated |

## 2. Pre-conditions

- User must be logged in with `hrs.leave_type.manage` permission
- At least one academic session record exists in `sch_org_academic_sessions_jnt`
- Dusk env: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

## 3. Default Data Load

`LeaveController::policy()` loads the single active global-default policy (`LeavePolicy::active()->globalDefault()->first()`) and academic year options. Rendered via `hrstaff::leave.policy`.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Policy | `LeaveController::policy()` | `LeavePolicy::active()->globalDefault()->first()` | is_active=true, academic_year_id=null | None (single record) |
| Academic Years | `LeaveController::policy()` | `OrganizationAcademicSession::orderByDesc('start_date')->get()` | None | None |

## 4. Test Data Strategy

- Create one global-default policy record directly in `hrs_leave_policies` with `academic_year_id = NULL` and known values
- For the create scenario, ensure no global-default policy exists
- Use consistent values: `max_backdated_days=3`, `min_advance_days=0`, `approval_levels=2`, `optional_holiday_count=2`, `is_active=1`

## 5. Business Conditions

### 5.1 Database Schema — `hrs_leave_policies`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | BIGINT UNSIGNED | PK, Auto Increment |
| BC-DB-02 | `academic_year_id` | SMALLINT UNSIGNED | NULL, FK → `sch_org_academic_sessions_jnt.id` |
| BC-DB-03 | `max_backdated_days` | TINYINT UNSIGNED | NOT NULL, DEFAULT 3 |
| BC-DB-04 | `min_advance_days` | TINYINT UNSIGNED | NOT NULL, DEFAULT 0 |
| BC-DB-05 | `approval_levels` | TINYINT UNSIGNED | NOT NULL, DEFAULT 2 |
| BC-DB-06 | `optional_holiday_count` | TINYINT UNSIGNED | NOT NULL, DEFAULT 2 |
| BC-DB-07 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-08 | `created_by` | BIGINT UNSIGNED | NOT NULL |
| BC-DB-09 | `updated_by` | BIGINT UNSIGNED | NOT NULL |
| BC-DB-10 | `created_at` | TIMESTAMP | NULL |
| BC-DB-11 | `updated_at` | TIMESTAMP | NULL |
| BC-DB-12 | `deleted_at` | TIMESTAMP | NULL (Soft delete) |
| BC-DB-13 | KEY `fk_hrs_lvpol_ayid` | INDEX | (`academic_year_id`) |

### 5.2 Validation Rules — `UpdateLeavePolicyRequest`

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `academic_year_id` | `nullable\|exists:sch_org_academic_sessions_jnt,id` | — (default Laravel) |
| BC-VAL-02 | `max_backdated_days` | `required\|integer\|min:0\|max:30` | — |
| BC-VAL-03 | `min_advance_days` | `required\|integer\|min:0\|max:30` | — |
| BC-VAL-04 | `approval_levels` | `required\|integer\|in:1,2` | — |
| BC-VAL-05 | `optional_holiday_count` | `required\|integer\|min:0\|max:10` | — |
| BC-VAL-06 | `is_active` | `required\|boolean` | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|------------|----------|
| BC-AUTH-01 | `hrs.leave_type.manage` | Policy view and update allowed |
| BC-AUTH-02 | No permission | `GET /leave-policy` → 403 |
| BC-AUTH-03 | No permission | `PUT /leave-policy` → 403 |
| BC-AUTH-04 | Guest | Redirect to `/login` |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Default page load with existing policy | Policy form pre-filled with current values |
| BC-BIZ-02 | Default page load without any policy | Empty form with default values from request attributes |
| BC-BIZ-03 | Update all fields with valid data | Existing policy record updated; redirect with success flash |
| BC-BIZ-04 | Update when no policy exists (first save) | New policy created with academic_year_id from current session; success flash |
| BC-BIZ-05 | `approval_levels=1` saved | Single-level approval mode enabled |
| BC-BIZ-06 | `approval_levels=2` saved | Two-level approval mode enabled |
| BC-BIZ-07 | `max_backdated_days=0` saved | Backdated applications disabled |
| BC-BIZ-08 | `max_backdated_days=30` saved | Max backdated window at upper limit |
| BC-BIZ-09 | Activity log entry | "Leave policy updated." logged after save |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `academic_year_id` | `sch_org_academic_sessions_jnt` | — (FK exists in DDL but no explicit ON DELETE; defaults to RESTRICT) |

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load Leave Policy page with existing policy | Form shows current `max_backdated_days`, `min_advance_days`, `approval_levels`, `optional_holiday_count` pre-filled | — | — | ⬜ |
| TC-P02 | Load Leave Policy page without any policy | Form shows empty/default values | — | — | ⬜ |
| TC-P03 | Update `max_backdated_days` to 5 | Policy updated; flash "Leave policy updated successfully." | — | — | ⬜ |
| TC-P04 | Update `approval_levels` to 1 | Policy updated; approval mode set to single-level | — | — | ⬜ |
| TC-P05 | Update `min_advance_days` to 2 | Policy updated | — | — | ⬜ |
| TC-P06 | Update `optional_holiday_count` to 3 | Policy updated | — | — | ⬜ |
| TC-P07 | Create new policy when none exists | New `hrs_leave_policies` record created with `academic_year_id` from current session | — | — | ⬜ |
| TC-P08 | Update all fields simultaneously | All fields updated; redirect with success flash | — | — | ⬜ |
| TC-P09 | Set `is_active` to false | Policy marked inactive; `is_active = 0` saved | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Submit with `max_backdated_days = -1` | Validation error: must be at least 0 | — | — | ⬜ |
| TC-N02 | Submit with `max_backdated_days = 31` | Validation error: may not be greater than 30 | — | — | ⬜ |
| TC-N03 | Submit with `approval_levels = 3` | Validation error: invalid selection | — | — | ⬜ |
| TC-N04 | Submit with `min_advance_days = -1` | Validation error: must be at least 0 | — | — | ⬜ |
| TC-N05 | Submit with `optional_holiday_count = 11` | Validation error: may not be greater than 10 | — | — | ⬜ |
| TC-N06 | Submit with non-numeric `max_backdated_days` | Validation error: must be an integer | — | — | ⬜ |
| TC-N07 | Submit without `is_active` field (missing) | Validation error: field is required | — | — | ⬜ |
| TC-N08 | Access page without `hrs.leave_type.manage` | 403 Forbidden | — | — | ⬜ |
| TC-N09 | Guest access to page | Redirect to login | — | — | ⬜ |
| TC-N10 | Submit with invalid `academic_year_id` | Validation error: selected academic year is invalid | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Model `$fillable` matches DDL columns | All updatable DDL columns are in `$fillable` | — | — | ⬜ |
| TC-D02 | A | Model `$casts` for integer/boolean fields | `max_backdated_days`, `min_advance_days`, `approval_levels`, `optional_holiday_count` cast to integer; `is_active` cast to boolean | — | — | ⬜ |
| TC-D03 | A | Model uses `SoftDeletes` trait | `deleted_at` column handled correctly | — | — | ⬜ |
| TC-D04 | A | Policy has `BelongsTo` relationship to `OrganizationAcademicSession` | `$this->belongsTo(OrganizationAcademicSession::class, 'academic_year_id')` works | — | — | ⬜ |
| TC-D05 | B | `LeaveApprovalService` reads `approval_levels` from policy | Approval FSM respects policy setting | — | — | ⬜ |
| TC-D06 | B | `LeaveService::applyLeave()` reads `max_backdated_days` from policy | Backdated validation uses policy value | — | — | ⬜ |
| TC-D07 | C | Activity logged on policy update | `activityLog(null, 'Updated', ...)` called with message "Leave policy updated." | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model `$fillable` — matches DDL columns | Mass-assignment protection covers all editable columns | — | — | ◌ |
| TC-CR02 | CR | P1 | Model `$casts` — integer/boolean casts | `$casts` array correctly defines types | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — `SoftDeletes` trait | Trait present; `deleted_at` column exists in DDL | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — `BelongsTo` relationship | `academicYear()` relationship defined | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — `Gate::authorize()` on all methods | Both `policy()` and `updatePolicy()` call `Gate::authorize('hrs.leave_type.manage')` | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — activity logged on state change | `activityLog()` called in `updatePolicy()` | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — `is_active=false` before soft delete (N/A for policy) | Policy uses `update()` directly, no delete action | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — JSON success response after update | Redirect with flash message (non-AJAX) | — | — | ◌ |
| TC-CR09 | CR | P1 | Request — validation rules cover all fields; `prepareForValidation()` normalizations | `UpdateLeavePolicyRequest` has rules for all 6 fields; `prepareForValidation()` casts `is_active` to boolean | — | — | ◌ |
| TC-CR10 | CR | P1 | Routes — resource + custom routes registered | `GET /leave-policy` and `PUT /leave-policy` registered with correct names | — | — | ◌ |
| TC-CR11 | CR | P1 | View — Blade `@can` directives on action buttons | Policy form uses `@can('hrs.leave_type.manage')` | — | — | ◌ |
| TC-CR12 | CR | P1 | View — null-safe checks for relationship variables | Policy view checks `$policy` before rendering | — | — | ◌ |
| TC-CR13 | CR | P1 | Breadcrumb — route registered in config | `hr-staff.menu.leaveManagement?tab=leave-policy` in breadcrumb config | — | — | ◌ |
| TC-CR14 | CR | P1 | Database — unique indexes match validation | No unique indexes except PK (intentional — single-record pattern) | — | — | ◌ |

## 7. Detailed Test Steps

#### TC-CR01: Model `$fillable` matches DDL columns
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Modules/HrStaff/Models/LeavePolicy.php` | Inspect `$fillable` array |
| 2 | Compare against `hrs_leave_policies` DDL columns | All non-PK, non-timestamp columns present |

#### TC-CR02: Model `$casts` for integer/boolean fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeavePolicy.php` | Inspect `$casts` array |
| 2 | Verify `max_backdated_days`, `min_advance_days`, `approval_levels`, `optional_holiday_count` | All cast to `integer` |
| 3 | Verify `is_active` | Cast to `boolean` |

#### TC-CR03: Model uses `SoftDeletes` trait
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeavePolicy.php` | Check for `use SoftDeletes;` |
| 2 | Verify DDL `hrs_leave_policies` has `deleted_at` column | Column exists as TIMESTAMP NULL |

#### TC-CR04: Model `BelongsTo` relationship
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeavePolicy.php` | Verify `academicYear()` returns `$this->belongsTo(OrganizationAcademicSession::class, 'academic_year_id')` |

#### TC-CR05: Controller `Gate::authorize()` on all methods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveController.php` | Verify `policy()` line 29 has `Gate::authorize('hrs.leave_type.manage')` |
| 2 | Verify `updatePolicy()` line 42 has same gate | Protected |

#### TC-CR06: Activity logged on state change
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveController.php` `updatePolicy()` | Verify `activityLog(null, 'Updated', ...)` at line 57 |

#### TC-CR07: No delete action for policy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveController.php` | No destroy/trashed/restore methods exist |

#### TC-CR08: Redirect with flash message after update
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveController.php` `updatePolicy()` line 59-60 | `redirect()->route(...)` with `->with('success', ...)` |

#### TC-CR09: Validation request rules and `prepareForValidation()`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `UpdateLeavePolicyRequest.php` | Verify `rules()` returns rules for all fields |
| 2 | Verify `prepareForValidation()` | Casts `is_active` to boolean with default true |

#### TC-CR10: Routes registered correctly
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` | Verify `GET /leave-policy` and `PUT /leave-policy` with correct names |

#### TC-CR11: Blade `@can` directives
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `resources/views/leave/policy.blade.php` | Verify `@can('hrs.leave_type.manage')` on form/save button |

#### TC-CR12: View null-safe checks
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `resources/views/leave/policy.blade.php` | Verify `isset($policy)` or `@if($policy)` check before rendering fields |

#### TC-CR13: Breadcrumb config
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `Modules/HrStaff/config/breadcrumb.php` | Verify route entry for leave policy |

#### TC-CR14: Unique indexes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for `hrs_leave_policies` | Only PK index; no unique constraints (intentional) |

### 7.1 Positive TC Steps

#### TC-P01: Load Leave Policy page with existing policy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user with `hrs.leave_type.manage` | Dashboard loads |
| 2 | Navigate to `GET /leave-policy` | Policy form displays with pre-filled values from existing global-default policy |

#### TC-P02: Load Leave Policy page without any policy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no global-default policy exists in DB | — |
| 2 | Log in as user with `hrs.leave_type.manage` | Dashboard loads |
| 3 | Navigate to `GET /leave-policy` | Form displays with default/empty values |

#### TC-P03: Update `max_backdated_days` to 5
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load policy page | Current `max_backdated_days` shown |
| 2 | Change `max_backdated_days` to 5 | — |
| 3 | Submit form (PUT /leave-policy) | Redirect; flash "Leave policy updated successfully." |
| 4 | Reload page | `max_backdated_days` shows 5 |

#### TC-P04: Update `approval_levels` to 1
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load policy page | Current `approval_levels` shown |
| 2 | Change `approval_levels` to 1 | Single-level approval |
| 3 | Submit form | Redirect with success flash |

#### TC-P05: Update `min_advance_days` to 2
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load policy page, set `min_advance_days` to 2, submit | Redirect with success flash; value persists on reload |

#### TC-P06: Update `optional_holiday_count` to 3
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load policy page, set `optional_holiday_count` to 3, submit | Redirect with success flash; value persists on reload |

#### TC-P07: Create new policy when none exists
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete all global-default policies from DB | — |
| 2 | Load policy page | Empty form |
| 3 | Fill all fields: `max_backdated_days=3`, `approval_levels=2`, etc. | — |
| 4 | Submit form | New policy created; success flash; page reloads with saved values |

#### TC-P08: Update all fields simultaneously
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load policy page, set all fields to new values | — |
| 2 | Submit form | Redirect; all values persisted |
| 3 | Reload page | All fields show updated values |

#### TC-P09: Set `is_active` to false
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load policy page, uncheck `is_active` | — |
| 2 | Submit form | Redirect with success; `is_active = 0` saved |

### 7.2 Negative TC Steps

#### TC-N01: Submit with `max_backdated_days = -1`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load policy page, set `max_backdated_days` to -1 | — |
| 2 | Submit form | Validation error: "The max backdated days must be at least 0." |

#### TC-N02: Submit with `max_backdated_days = 31`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `max_backdated_days` to 31 | — |
| 2 | Submit form | Validation error: "The max backdated days may not be greater than 30." |

#### TC-N03: Submit with `approval_levels = 3`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `approval_levels` to 3 | — |
| 2 | Submit form | Validation error: "The selected approval levels is invalid." |

#### TC-N04: Submit with `min_advance_days = -1`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `min_advance_days` to -1 | — |
| 2 | Submit form | Validation error |

#### TC-N05: Submit with `optional_holiday_count = 11`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `optional_holiday_count` to 11 | — |
| 2 | Submit form | Validation error |

#### TC-N06: Submit with non-numeric `max_backdated_days`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `max_backdated_days` to "abc" | — |
| 2 | Submit form | Validation error: "The max backdated days must be an integer." |

#### TC-N07: Submit without `is_active`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Remove `is_active` from form submission | — |
| 2 | Submit form | Validation error: "The is active field is required." |

#### TC-N08: Access page without `hrs.leave_type.manage`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `hrs.leave_type.manage` | — |
| 2 | Navigate to `GET /leave-policy` | 403 Forbidden |

#### TC-N09: Guest access
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out | — |
| 2 | Navigate to `GET /leave-policy` | Redirect to `/login` |

#### TC-N10: Submit with invalid `academic_year_id`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `academic_year_id` to 99999 | — |
| 2 | Submit form | Validation error: "The selected academic year is invalid." |

### 7.3 Dependency TC Steps

#### TC-D01: Model `$fillable` matches DDL columns
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeavePolicy.php` | Verify `$fillable` contains all editable columns: `academic_year_id`, `max_backdated_days`, `min_advance_days`, `approval_levels`, `optional_holiday_count`, `is_active`, `created_by`, `updated_by` |

#### TC-D02: Model `$casts` for integer/boolean fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeavePolicy.php` | Verify `$casts` has `max_backdated_days`, `min_advance_days`, `approval_levels`, `optional_holiday_count` → integer; `is_active` → boolean |

#### TC-D03: Model uses `SoftDeletes` trait
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeavePolicy.php` | Confirm `use SoftDeletes;` present |
| 2 | Check DDL `hrs_leave_policies` | `deleted_at` column exists as TIMESTAMP NULL |

#### TC-D04: Policy has `BelongsTo` relationship to `OrganizationAcademicSession`
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeavePolicy.php` | Verify `academicYear()` returns `$this->belongsTo(OrganizationAcademicSession::class, 'academic_year_id')` |

#### TC-D05: `LeaveApprovalService` reads `approval_levels` from policy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `approval_levels = 1` in policy | — |
| 2 | Submit a leave application and approve as HOD | Application status becomes `approved` (bypasses L2) |
| 3 | Set `approval_levels = 2` | — |
| 4 | Submit another leave application and approve as HOD | Application status becomes `pending_l2` |

#### TC-D06: `LeaveService::applyLeave()` reads `max_backdated_days` from policy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `max_backdated_days = 3` | — |
| 2 | Submit leave application with `from_date` 5 days ago | DomainException: backdated window exceeded |
| 3 | Set `max_backdated_days = 10` | — |
| 4 | Submit same application | Application created successfully |

#### TC-D07: Activity logged on policy update
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LeaveController.php` `updatePolicy()` | Confirm `activityLog(null, 'Updated', ['message' => 'Leave policy updated.'])` at line 57 |
| 2 | Update policy via UI | Activity log entry recorded with type "Updated" |
