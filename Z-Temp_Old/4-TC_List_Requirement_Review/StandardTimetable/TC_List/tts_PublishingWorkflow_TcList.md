# tts_publishing_workflow_TcList

## Module: StandardTimetable → Publishing → Publishing & Approval Workflow

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | StandardTimetable |
| Tab Group | Publishing |
| Feature | Publishing & Approval Workflow |
| URL(s) | `POST /standard-timetable/submit-for-approval/{id}`, `POST /standard-timetable/approve/{id}`, `POST /standard-timetable/publish/{id}` |
| Controller | `Modules\StandardTimetable\Http\Controllers\StandardTimetableController` — `submitForApproval()` lines 658-675, `approve()` lines 677-694, `publish()` lines 696-713 |
| Model(s) | `Modules\TimetableFoundation\Models\Timetable` (table: `tt_timetables`) |
| Validation | None (no Form Request — ID is route-parameter, status checked in controller) |
| Policy | `Modules\StandardTimetable\Policies\StandardTimetablePolicy` — `publish()` method |
| Permissions | `standard-timetable.publish` |
| Pagination | None (action-only endpoints) |
| Soft Deletes | Yes (`Timetable` uses `SoftDeletes` trait; DDL shows `deleted_at` column) |

---

## 2. Pre-conditions

- Required permissions: `standard-timetable.publish`
- Required seed data: At least one `Timetable` record with `generation_method='MANUAL'` in each status (`DRAFT`, `GENERATED`, `PUBLISHED`)
- Tenant context via `tenancy()->initialize()`
- Dusk env vars: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

No data load — these are action-only AJAX endpoints that change the timetable status. Each endpoint receives the timetable ID as a URL parameter.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| None | Action endpoint | `Timetable::where('generation_method','MANUAL')->findOrFail($id)` | None | None |

---

## 4. Test Data Strategy

- Create `Timetable` records directly in DB with specific `status` values and `generation_method='MANUAL'`
- Use consistent naming: `"Test Timetable [purpose]"`, code `"TT_TEST_[timestamp]"`
- Pre-test cleanup: Delete created timetables by code after tests
- Verify `published_at` is set on PUBLISHED status and null otherwise
- Verify `activityLog` entries for each transition

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_timetables` (relevant columns)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | code | VARCHAR(50) | NOT NULL, UNIQUE (`uq_tt_code`) |
| BC-DB-03 | name | VARCHAR(200) | NOT NULL |
| BC-DB-04 | generation_method | ENUM('MANUAL','SEMI_AUTO','FULL_AUTO') | NOT NULL DEFAULT 'MANUAL' |
| BC-DB-05 | status | ENUM('DRAFT','GENERATING','GENERATED','PUBLISHED','ARCHIVED') | NOT NULL DEFAULT 'DRAFT' |
| BC-DB-06 | published_at | TIMESTAMP | NULL — set to `now()` on approve/publish |
| BC-DB-07 | published_by | INT UNSIGNED | DEFAULT NULL, FK → `sys_users.id`, ON DELETE SET NULL |
| BC-DB-08 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-09 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-10 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-11 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

> **Note:** The code checks `$timetable->status === 'PUBLISHED'` for immutability in `lockCell`/`unlockCell`/`lockAll`/`placeCell`/`removeCell`. The DDL defines the ENUM with 5 values including 'PUBLISHED'. No code↔DDL discrepancy identified.

### 5.2 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | standard-timetable.publish | Without → 403 on submitForApproval/approve/publish |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 5.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Submit DRAFT timetable | `status` updated to `GENERATED`; `published_at` remains null; activityLog 'Submitted' recorded |
| BC-BIZ-02 | Submit GENERATED timetable | Returns 422: "Only draft timetables can be submitted." |
| BC-BIZ-03 | Submit PUBLISHED timetable | Returns 422: "Only draft timetables can be submitted." |
| BC-BIZ-04 | Approve GENERATED timetable | `status` updated to `PUBLISHED`; `published_at` set to now(); activityLog 'Published' recorded |
| BC-BIZ-05 | Approve DRAFT timetable | Returns 422: "Only submitted timetables can be approved." |
| BC-BIZ-06 | Approve PUBLISHED timetable | Returns 422: "Only submitted timetables can be approved." |
| BC-BIZ-07 | Publish DRAFT timetable | `status` updated to `PUBLISHED`; `published_at` set to now(); activityLog 'Published' recorded |
| BC-BIZ-08 | Publish GENERATED timetable | `status` updated to `PUBLISHED`; `published_at` set to now(); activityLog 'Published' recorded |
| BC-BIZ-09 | Publish PUBLISHED timetable | Returns 422: "Timetable cannot be published from current state." |
| BC-BIZ-10 | Publish ARCHIVED timetable | Returns 422: "Timetable cannot be published from current state." |
| BC-BIZ-11 | Non-existent timetable ID on any action | 404 via `findOrFail` |
| BC-BIZ-12 | Timetable with `generation_method != 'MANUAL'` on any action | 404 via `where('generation_method','MANUAL')->findOrFail()` |

### 5.4 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | published_by | sys_users (id) | SET NULL |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Submit DRAFT timetable for approval | Status changes DRAFT → GENERATED; published_at null; JSON success | — | — | ⬜ |
| TC-P02 | Approve GENERATED timetable | Status changes GENERATED → PUBLISHED; published_at set; JSON success | — | — | ⬜ |
| TC-P03 | Publish DRAFT timetable (skip approval) | Status changes DRAFT → PUBLISHED; published_at set; JSON success | — | — | ⬜ |
| TC-P04 | Publish GENERATED timetable (skip approval) | Status changes GENERATED → PUBLISHED; published_at set; JSON success | — | — | ⬜ |
| TC-P05 | Full lifecycle: DRAFT → submit → approve | Timeline: DRAFT → submitForApproval → GENERATED → approve → PUBLISHED; published_at set on approve | — | — | ⬜ |
| TC-P06 | Full lifecycle: DRAFT → publish direct | Timeline: DRAFT → publish → PUBLISHED; published_at set on publish | — | — | ⬜ |
| TC-P07 | Activity Log on submitForApproval | activityLog('Submitted') entry created with timetable name and user | — | — | ⬜ |
| TC-P08 | Activity Log on approve | activityLog('Published') entry created with timetable name and user | — | — | ⬜ |
| TC-P09 | Activity Log on publish | activityLog('Published') entry created with timetable name and user | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Submit GENERATED timetable | 422: "Only draft timetables can be submitted." | — | — | ⬜ |
| TC-N02 | Submit PUBLISHED timetable | 422: "Only draft timetables can be submitted." | — | — | ⬜ |
| TC-N03 | Approve DRAFT timetable | 422: "Only submitted timetables can be approved." | — | — | ⬜ |
| TC-N04 | Approve PUBLISHED timetable | 422: "Only submitted timetables can be approved." | — | — | ⬜ |
| TC-N05 | Publish PUBLISHED timetable | 422: "Timetable cannot be published from current state." | — | — | ⬜ |
| TC-N06 | Publish ARCHIVED timetable | 422: "Timetable cannot be published from current state." | — | — | ⬜ |
| TC-N07 | Submit non-existent timetable | 404 | — | — | ⬜ |
| TC-N08 | Approve non-existent timetable | 404 | — | — | ⬜ |
| TC-N09 | Publish non-existent timetable | 404 | — | — | ⬜ |
| TC-N10 | Submit timetable with generation_method != 'MANUAL' | 404 (findOrFail scoped to MANUAL only) | — | — | ⬜ |
| TC-N11 | Approve timetable with generation_method != 'MANUAL' | 404 | — | — | ⬜ |
| TC-N12 | Publish timetable with generation_method != 'MANUAL' | 404 | — | — | ⬜ |
| TC-N13 | No permission (standard-timetable.publish) | 403 on submitForApproval/approve/publish | — | — | ⬜ |
| TC-N14 | Guest access to any action | Redirect to /login | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | ENUM status transition — DRAFT→GENERATED | DB accepts DRAFT, DRAFT→GENERATED transition via submitForApproval; status constraint enforced at application level | — | — | ⬜ |
| TC-D02 | A | ENUM status transition — GENERATED→PUBLISHED | DB accepts GENERATED→PUBLISHED transition via approve/publish; invalid transitions rejected by controller | — | — | ⬜ |
| TC-D03 | B | Timetable with SoftDeletes — deleted timetable actions | Soft-deleted timetable not found by `findOrFail` → 404 | — | — | ⬜ |
| TC-D04 | C | FK published_by SET NULL — delete user after publish | Publish timetable (published_by set); delete user → published_by = NULL | — | — | ⬜ |
| TC-D05 | D | Activity Logging — all three actions | activityLog() called on submitForApproval('Submitted'), approve('Published'), publish('Published'); log entries contain timetable name and user | — | — | ⬜ |
| TC-D06 | E | Gate coverage — publish gate on all three methods | StandardTimetablePolicy@publish() gates all three endpoints; `Gate::authorize('standard-timetable.publish')` called before any status check | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — Gate::authorize('standard-timetable.publish') on All Three Methods | `submitForApproval()`, `approve()`, and `publish()` each call `Gate::authorize('standard-timetable.publish')` at the top before any logic; no other authorization method used | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — Status ENUM Validation Via If-Check (Not Form Request) | All three methods check `$timetable->status` with if-condition and return 422 JSON with specific message; no null status or empty string accepted | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — JSON Success Response After Status Change | Each method returns `response()->json(['success'=>true, 'message'=>...])`; no HTML/flash redirect responses | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — activity Logged on All State Changes | activityLog() called with correct event name ('Submitted'/'Published') after each successful status update | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Policy — publish() Method Defined in StandardTimetablePolicy | `StandardTimetablePolicy` has `publish(User $user)` method returning `$user->can('standard-timetable.publish')` | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Routes — All Three POST Routes Registered | `web.php` defines `POST submit-for-approval/{id}`, `POST approve/{id}`, `POST publish/{id}` with correct controller method mapping | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Model — $casts for status and published_at | `Timetable` model casts `status` to string, `published_at` to datetime/timestamp | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Controller — Gate::authorize('standard-timetable.publish') on All Three Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StandardTimetableController.php` | File found in `Modules/StandardTimetable/Http/Controllers/` |
| 2 | Inspect `submitForApproval()` line 658 | First logic line is `Gate::authorize('standard-timetable.publish')` |
| 3 | Inspect `approve()` line 677 | First logic line is `Gate::authorize('standard-timetable.publish')` |
| 4 | Inspect `publish()` line 696 | First logic line is `Gate::authorize('standard-timetable.publish')` |
| 5 | Confirm no other authorization pattern used | All three use identical `Gate::authorize()` call |

#### TC-CR02: Controller — Status ENUM Validation Via If-Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `submitForApproval()` | `if ($timetable->status !== 'DRAFT')` check returns 422 with "Only draft timetables can be submitted." |
| 2 | Inspect `approve()` | `if ($timetable->status !== 'GENERATED')` check returns 422 with "Only submitted timetables can be approved." |
| 3 | Inspect `publish()` | `if ($timetable->status !== 'DRAFT' && $timetable->status !== 'GENERATED')` check returns 422 with "Timetable cannot be published from current state." |
| 4 | Verify no fallback for null/empty status | All three only accept the allowed status values explicitly |

#### TC-CR03: Controller — JSON Success Response After Status Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `submitForApproval()` after update | Returns `response()->json(['success'=>true, 'message'=>'Timetable submitted for approval.'])` |
| 2 | Inspect `approve()` after update | Returns `response()->json(['success'=>true, 'message'=>'Timetable published.'])` |
| 3 | Inspect `publish()` after update | Returns `response()->json(['success'=>true, 'message'=>'Timetable published.'])` |

#### TC-CR04: Controller — activity Logged on All State Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `submitForApproval()` | `activityLog($timetable, 'Submitted', [...])` called after status update |
| 2 | Inspect `approve()` | `activityLog($timetable, 'Published', [...])` called after status update |
| 3 | Inspect `publish()` | `activityLog($timetable, 'Published', [...])` called after status update |
| 4 | Verify message content | Each log entry includes timetable name and `auth()->user()?->name` |

#### TC-CR05: Policy — publish() Method Defined in StandardTimetablePolicy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StandardTimetablePolicy.php` | File found in `Modules/StandardTimetable/Policies/` |
| 2 | Verify `publish()` method exists | Method `publish(User $user): bool` returns `$user->can('standard-timetable.publish')` |

#### TC-CR06: Routes — All Three POST Routes Registered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `web.php` in routes folder | Routes file found |
| 2 | Verify `submit-for-approval` route | `Route::post('submit-for-approval/{id}', ...)->name('submitForApproval')` registered |
| 3 | Verify `approve` route | `Route::post('approve/{id}', ...)->name('approve')` registered |
| 4 | Verify `publish` route | `Route::post('publish/{id}', ...)->name('publish')` registered |

#### TC-CR07: Model — $casts for status and published_at

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Timetable.php` in `Modules/TimetableFoundation/Models/` | Model file found |
| 2 | Inspect `$casts` property | `status` is cast to string/appropriate type; `published_at` is cast to `datetime` |
| 3 | Verify no missing cast for ENUM | ENUM values read as strings; cast ensures correct type |

### 7.1 Positive TC Steps

#### TC-P01: Submit DRAFT Timetable for Approval

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with status='DRAFT', generation_method='MANUAL', code='TT_SUBMIT_01' | Timetable exists with ID=X |
| 2 | POST to `/standard-timetable/submit-for-approval/{X}` | JSON response |
| 3 | Check response | `{"success": true, "message": "Timetable submitted for approval."}` |
| 4 | DB check: `SELECT status, published_at FROM tt_timetables WHERE id=X` | `status` = 'GENERATED', `published_at` = NULL |

---

#### TC-P02: Approve GENERATED Timetable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with status='GENERATED', generation_method='MANUAL', code='TT_APPROVE_01' | Timetable exists with ID=Y |
| 2 | POST to `/standard-timetable/approve/{Y}` | JSON response |
| 3 | Check response | `{"success": true, "message": "Timetable published."}` |
| 4 | DB check: `SELECT status, published_at FROM tt_timetables WHERE id=Y` | `status` = 'PUBLISHED', `published_at` is NOT NULL and is recent |

---

#### TC-P03: Publish DRAFT Timetable (Skip Approval)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with status='DRAFT', generation_method='MANUAL', code='TT_PUBLISH_DRAFT' | Timetable exists with ID=Z |
| 2 | POST to `/standard-timetable/publish/{Z}` | JSON response |
| 3 | Check response | `{"success": true, "message": "Timetable published."}` |
| 4 | DB check | `status` = 'PUBLISHED', `published_at` is NOT NULL |

---

#### TC-P04: Publish GENERATED Timetable (Skip Approval)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with status='GENERATED', generation_method='MANUAL', code='TT_PUBLISH_GEN' | Timetable exists with ID=W |
| 2 | POST to `/standard-timetable/publish/{W}` | JSON response |
| 3 | Check response | `{"success": true, "message": "Timetable published."}` |
| 4 | DB check | `status` = 'PUBLISHED', `published_at` is NOT NULL |

---

#### TC-P05: Full Lifecycle — DRAFT → Submit → Approve

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with status='DRAFT', code='TT_FULL_A' | Timetable exists with ID=A |
| 2 | POST `/standard-timetable/submit-for-approval/{A}` | Success: "Timetable submitted for approval." |
| 3 | DB check: status | 'GENERATED' |
| 4 | POST `/standard-timetable/approve/{A}` | Success: "Timetable published." |
| 5 | DB check: status, published_at | 'PUBLISHED', published_at set |

---

#### TC-P06: Full Lifecycle — DRAFT → Publish Direct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create timetable with status='DRAFT', code='TT_FULL_B' | Timetable exists with ID=B |
| 2 | POST `/standard-timetable/publish/{B}` | Success: "Timetable published." |
| 3 | DB check: status, published_at | 'PUBLISHED', published_at set |

---

#### TC-P07: Activity Log on submitForApproval

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create DRAFT timetable with code='TT_ACTLOG_01' | Timetable exists |
| 2 | POST submit-for-approval | Success |
| 3 | Check activity_log table | Entry with event='Submitted', timetable name and user present |

---

#### TC-P08: Activity Log on approve

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create GENERATED timetable with code='TT_ACTLOG_02' | Timetable exists |
| 2 | POST approve | Success |
| 3 | Check activity_log table | Entry with event='Published', timetable name and user present |

---

#### TC-P09: Activity Log on publish

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create DRAFT timetable with code='TT_ACTLOG_03' | Timetable exists |
| 2 | POST publish | Success |
| 3 | Check activity_log table | Entry with event='Published', timetable name and user present |

### 7.2 Negative TC Steps

#### Negative Tests — Publishing Workflow (Compact)

| TC ID | Step 1 | Step 2 | Expected |
|-------|--------|--------|----------|
| TC-N01 | Create GENERATED timetable → POST submit-for-approval | 422 JSON | "Only draft timetables can be submitted." |
| TC-N02 | Create PUBLISHED timetable → POST submit-for-approval | 422 JSON | "Only draft timetables can be submitted." |
| TC-N03 | Create DRAFT timetable → POST approve | 422 JSON | "Only submitted timetables can be approved." |
| TC-N04 | Create PUBLISHED timetable → POST approve | 422 JSON | "Only submitted timetables can be approved." |
| TC-N05 | Create PUBLISHED timetable → POST publish | 422 JSON | "Timetable cannot be published from current state." |
| TC-N06 | Create ARCHIVED timetable → POST publish | 422 JSON | "Timetable cannot be published from current state." |
| TC-N07 | POST submit-for-approval/99999 | 404 | Model not found |
| TC-N08 | POST approve/99999 | 404 | Model not found |
| TC-N09 | POST publish/99999 | 404 | Model not found |
| TC-N10 | Create timetable with generation_method='FULL_AUTO', status='DRAFT' → POST submit-for-approval | 404 | findOrFail scoped to MANUAL only |
| TC-N11 | Same as N10 → POST approve | 404 | Same |
| TC-N12 | Same as N10 → POST publish | 404 | Same |

---

#### TC-N13: No Permission (standard-timetable.publish)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as user without `standard-timetable.publish` permission | User authenticated |
| 2 | POST to `/standard-timetable/submit-for-approval/{id}` | 403 Forbidden |
| 3 | POST to `/standard-timetable/approve/{id}` | 403 Forbidden |
| 4 | POST to `/standard-timetable/publish/{id}` | 403 Forbidden |

---

#### TC-N14: Guest Access to Any Action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (no authenticated user) | Guest session |
| 2 | POST to `/standard-timetable/submit-for-approval/{id}` | Redirect to /login |
| 3 | POST to `/standard-timetable/approve/{id}` | Redirect to /login |
| 4 | POST to `/standard-timetable/publish/{id}` | Redirect to /login |

### 7.3 Dependency TC Steps

#### TC-D01: ENUM Status Transition — DRAFT → GENERATED

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create DRAFT timetable | status = 'DRAFT' |
| 2 | POST submit-for-approval | status updated to 'GENERATED' |
| 3 | Verify GENERATED accepted | DB stores 'GENERATED' correctly |

#### TC-D02: ENUM Status Transition — GENERATED → PUBLISHED

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create GENERATED timetable | status = 'GENERATED' |
| 2 | POST approve | status updated to 'PUBLISHED' |
| 3 | Verify PUBLISHED accepted | DB stores 'PUBLISHED' correctly |

#### TC-D03: Timetable with SoftDeletes — Deleted Timetable Actions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create DRAFT timetable | Timetable exists with ID=X |
| 2 | Soft-delete it: `Timetable::find(X)->delete()` | deleted_at set |
| 3 | POST submit-for-approval/{X} | 404 — not found (findOrFail excludes soft-deleted) |

#### TC-D04: FK published_by SET NULL — Delete User After Publish

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create and approve/publish timetable | published_by = user ID |
| 2 | Delete the user (sys_users) | User deleted |
| 3 | Query timetable published_by | NULL |

#### TC-D05: Activity Logging — All Three Actions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 DRAFT timetables | IDs X, Y, Z |
| 2 | POST submit-for-approval/X, approve/Y, publish/Z | All succeed |
| 3 | Query activity_log | 3 entries: 'Submitted' for X, 'Published' for Y, 'Published' for Z |

#### TC-D06: Gate Coverage — publish Gate on All Three Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `submitForApproval()` | `Gate::authorize('standard-timetable.publish')` is called |
| 2 | Inspect `approve()` | `Gate::authorize('standard-timetable.publish')` is called |
| 3 | Inspect `publish()` | `Gate::authorize('standard-timetable.publish')` is called |
| 4 | Login as user without this permission | All three return 403 |
