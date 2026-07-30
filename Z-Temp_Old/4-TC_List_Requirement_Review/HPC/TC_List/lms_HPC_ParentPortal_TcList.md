# TC List Ã¢Ãâ¬" HPC Parent Portal

## 1. Feature Information

| Field | Value |
|---|---|
| **Module** | HPC (Higher Purpose Curriculum) |
| **Tab Group** | Parent Portal |
| **Feature** | Parent Portal Ã¢Ãâ¬" Token-based form input |
| **Controller(s)** | `Modules\Hpc\Http\Controllers\ParentHpcFormController` |
| **Model(s)** | `Modules\Hpc\Models\ParentFormToken`, `HpcReport` |
| **URL(s)** | `hpc/teacher/generate-parent-link/{report_id}`, `hpc/teacher/parent-status/{report_id}`, `hpc/parent/dashboard/{token}`, `hpc/parent/form/{token}` (GET), `hpc/parent/form/{token}` (POST) |
| **Validation** | Token auto-generated (static generateToken); report_id required+exists; guardian_id required; token exists, not expired (!isExpired), not completed (!isCompleted); expiry check: expires_at > now(); completed check: completed_at IS NOT NULL |
| **Permission(s)** | `tenant.hpc.update` (generate link), `tenant.hpc.view` (parent status). Public routes are token-based (no auth). |
| **Soft Deletes** | Yes Ã¢Ãâ¬" ParentFormToken uses SoftDeletes trait |
| **Activity Log** | None |

---

## 2. Pre-conditions

1. HPC module is installed and active.
2. Teacher user is authenticated and has `tenant.hpc.update` and `tenant.hpc.view` permissions.
3. Seed data exists: at least one HpcReport record with a student and a guardian assigned.
4. Guardian/Parent user exists in the system (with email/phone for notification).
5. `hpc_parent_form_tokens` table exists and is migrated.
6. Parent routes are public (no auth middleware) but token is required.
7. Environment variable or config constant `EXPIRY_DAYS = 7` and `MAX_SUBMISSIONS = 3` are defined.
8. Parent form has fields tagged as `parent-owned` that are distinct from student/teacher fields.

---

## 3. Default Data Load

| # | Table | Records Expected |
|---|---|---|
| 1 | `hpc_reports` | Ã¢Ãâ°Ã¥ 1 report linked to a student and guardian |
| 2 | `hpc_parent_form_tokens` | Ã¢Ãâ°Ã¥ 1 active token (not expired, not completed), Ã¢Ãâ°Ã¥ 1 expired token, Ã¢Ãâ°Ã¥ 1 completed token |
| 3 | `users` | Teacher user with permissions; Guardian user linked to student |
| 4 | `permissions` | `tenant.hpc.update` and `tenant.hpc.view` assigned to teacher |

---

## 4. Test Data Strategy

| Data Type | Source | Approach |
|---|---|---|
| Valid tokens | Factory/Seeder | Pre-seeded tokens with varying states (active, expired, completed) |
| Invalid/random tokens | Hard-coded | UUID v4 random string; short string; SQL injection attempt |
| Report IDs | Factory | Pre-seeded with known IDs |
| Guardian IDs | Factory | Pre-seeded guardian linked to student |
| Permission mismatch | Role edit | Revoke permission via Spatie before request |
| Expired token | Factory | Create token with expires_at in the past |
| Completed token | Factory | Create token with completed_at set and is_active = false |

---

## 5. Business Conditions

### 4.1 Database Schema Ã¢Ãâ¬" hpc_parent_form_tokens

| ID | Condition | Description |
|---|---|---|
| BC-DB-01 | hpc_parent_form_tokens table schema | id (PK), token (string, UNIQUE), report_id (FKÃ¢Ãâ 'hpc_reports.id), student_id (FKÃ¢Ãâ 'users.id), guardian_id (FKÃ¢Ãâ 'users.id), generated_by (FKÃ¢Ãâ 'users.id), expires_at (datetime), completed_at (nullable datetime), ip_address (string, nullable), submission_count (int, default 0), is_active (boolean, default true), deleted_at (nullable timestamp) |
| BC-DB-02 | Token UNIQUE constraint | token column has a unique index; duplicate tokens rejected at DB level |
| BC-DB-03 | EXPIRY_DAYS constant | Defined as 7 in config or model; used when generating token expiry |
| BC-DB-04 | MAX_SUBMISSIONS constant | Defined as 3; checked before allowing new submission |
| BC-DB-05 | Soft Deletes | ParentFormToken uses SoftDeletes trait |
| BC-DB-06 | FK: report_id Ã¢Ãâ ' HpcReport.id | Referential integrity enforced |
| BC-DB-07 | FK: student_id Ã¢Ãâ ' users.id | Referential integrity enforced |
| BC-DB-08 | FK: guardian_id Ã¢Ãâ ' users.id | Referential integrity enforced |

### 4.2 Validation Rules Ã¢Ãâ¬" `ParentHpcFormRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | token | Auto-generated via generateToken() | Ã¢Ãâ¬" |
| BC-VAL-02 | token (format) | Static generateToken() returns unique random string (e.g., base64_encode(random_bytes(32))) | Ã¢Ãâ¬" |
| BC-VAL-03 | report_id | required, integer, exists:hpc_reports,id | "The selected report is invalid." |
| BC-VAL-04 | guardian_id | required, integer, exists:users,id | "Guardian is required." |

### 4.3 Validation Rules Ã¢Ãâ¬" `ParentHpcFormRequest` (Update / Submit)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | token (existence) | Must exist in hpc_parent_form_tokens | Ã¢Ãâ¬" |
| BC-VAL-U02 | token (expiry) | isExpired() checks expires_at > now() | "This link has expired." |
| BC-VAL-U03 | token (completion) | isCompleted() checks completed_at IS NULL | "This form has already been submitted." |
| BC-VAL-U04 | token (expiry) | Expiry check on EVERY request (GET + POST) | Ã¢Ãâ¬" |
| BC-VAL-U05 | token (completion) | Completion check on submit only (POST) | Ã¢Ãâ¬" |
| BC-VAL-U06 | submission_count | Must be < MAX_SUBMISSIONS (3) | "Maximum submissions reached (3)." |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.hpc.update | generateParentLink() (GET hpc/teacher/generate-parent-link/{report_id}) | Without Ã¢Ãâ ' 403 |
| BC-AUTH-02 | tenant.hpc.view | parentStatus() (GET hpc/teacher/parent-status/{report_id}) | Without Ã¢Ãâ ' 403 |
| BC-AUTH-03 | Public (no auth) | dashboard(), form() (GET hpc/parent/dashboard/{token}, GET/POST hpc/parent/form/{token}) | Token-based access |
| BC-AUTH-04 | Ã¢Ãâ¬" | All teacher endpoints | Unauthenticated Ã¢Ãâ ' login redirect |
| BC-AUTH-05 | Ã¢Ãâ¬" | All permission-gated endpoints | Insufficient permissions Ã¢Ãâ ' 403 |

### 4.5 Business Logic

| ID | Condition | Description |
|---|---|---|
| BC-BIZ-01 | Token generation creates with 7-day expiry | `expires_at = now()->addDays(EXPIRY_DAYS)` |
| BC-BIZ-02 | Unique random token | `generateToken()` uses sufficient entropy to avoid collisions |
| BC-BIZ-03 | Parent dashboard validates token | Shows student info card if valid |
| BC-BIZ-04 | Parent form filters to parent-only fields | Only fields tagged `parent-owned` are shown and editable |
| BC-BIZ-05 | Submit sets completed_at | Timestamp recorded on first submission completion |
| BC-BIZ-06 | submission_count increments | Each form submission increments counter |
| BC-BIZ-07 | Max 3 submissions | After 3, further submissions rejected |
| BC-BIZ-08 | Expired link shows expired page | If expires_at < now(), render expired view |
| BC-BIZ-09 | Completed link shows thank-you page | If completed_at set, render completed/thank-you view |
| BC-BIZ-10 | Completed link shows previous submission | Re-opening completed link shows submitted data (read-only) |
| BC-BIZ-11 | Missing DB table graceful handling | If table missing, show error message not 500 |

### 4.6 Referential Integrity

| ID | Condition | Description |
|---|---|---|
| BC-REF-01 | EXPIRY_DAYS = 7 | Configured constant |
| BC-REF-02 | MAX_SUBMISSIONS = 3 | Configured constant |
| BC-REF-03 | Token uniqueness | DB unique index + validation |
| BC-REF-04 | isExpired() logic | `expires_at->isPast()` |
| BC-REF-05 | isCompleted() logic | `completed_at !== null` |

---

## 6. Test Case List Ã¢Ãâ¬" Parent Portal

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|---|
| TC-P-001 | Generate parent link Ã¢Ãâ¬" teacher UI loads link generator | Generate page renders with report dropdown and guardian select | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-002 | Generate parent link for valid report_id | Token created; link displayed with 7-day validity notice | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-003 | Verify generated token in DB | Token stored; expires_at = now + 7 days; is_active = true | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-004 | Parent opens valid unexpired token link Ã¢Ãâ¬" dashboard shows student info | Dashboard loads with student name, report name, progress info | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-005 | Parent form loads with parent-only fields | Form renders with only fields tagged as parent-owned; no student/teacher fields | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-006 | Parent fills text field in parent form | Text input editable; value accepted | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-007 | Parent selects dropdown option in parent form | Dropdown selection accepted | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-008 | Parent submits completed form | Form submits successfully; redirect to thank-you page | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-009 | Thank-you page displays after first submission | Thank-you message shown; no further action prompt | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-010 | Re-open completed link Ã¢Ãâ¬" shows "already submitted" and previous data | Thank-you page with "You have already submitted" message; previous responses visible read-only | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-011 | Parent submits form exactly 3 times (max) | Each submission accepted until count = 3 | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-012 | Fourth submission attempt after reaching MAX_SUBMISSIONS | Rejected; message "Maximum submissions reached (3)" | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-013 | Expired link shows "expired page" | Page displays "This link has expired" message; no form rendered | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-014 | Teacher views parent completion status | Status page shows token validity, submission count, completed_at | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-015 | Teacher views status for multiple parent tokens | All tokens for report listed with their individual status | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-016 | submission_count increments correctly after each submit | After 1st submit: count=1; after 2nd: count=2; after 3rd: count=3 | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-017 | Parent saves draft and returns later | Partial data persisted; form reloads with saved values | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-018 | Different parent tokens for different reports generate unique links | Each token differs; no collision | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-019 | Teacher can regenerate link if token expired | New token generated; old token deactivated | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-020 | Parent form label matches parent-friendly language | Labels use parent-appropriate terminology (not internal field names) | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-021 | IP address logged on parent submission | hpc_parent_form_tokens.ip_address populated with submitter IP | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-P-022 | Teacher sees "Link Generated" confirmation with copyable URL | Confirmation message includes clickable/copyable full URL | Tester A | Tester B | Ã¢Ã¬ÃÅ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|---|
| TC-N-001 | Invalid/random token (non-existent UUID) Ã¢Ãâ ' 404 | 404 Not Found page; no stack trace | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-002 | Expired token Ã¢Ãâ ' expired page | Expired page rendered; no form; no submission possible | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-003 | Completed token Ã¢Ãâ ' resubmit refused | Thank-you page shown; POST rejected | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-004 | Tampered token (modified last char) Ã¢Ãâ ' 404 | Token not found in DB; 404 | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-005 | Missing token parameter from URL Ã¢Ãâ ' 404 | Route not matched; 404 page | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-006 | Link for non-existent report_id Ã¢Ãâ ' teacher generation fails | Error "Report not found" on generate page | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-007 | Permission denied for teacher without `tenant.hpc.update` Ã¢Ãâ ' 403 | 403 on generate-parent-link endpoint | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-008 | Permission denied for teacher without `tenant.hpc.view` Ã¢Ãâ ' 403 | 403 on parent-status endpoint | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-009 | Guest user accessing teacher endpoint Ã¢Ãâ ' login redirect | 302 redirect to /login | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-010 | Expired token POST submit Ã¢Ãâ ' rejected | Submission ignored; expired page shown; data not saved | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-011 | completed_at token POST submit Ã¢Ãâ ' duplicate rejected | Submission ignored; thank-you page shown | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-012 | Generate token without selecting guardian | Validation error "Guardian is required" | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-013 | Generate token without report_id | Validation error "Report is required" | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-014 | CSRF token mismatch on parent form submit | 419 Page Expired; data not saved | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-015 | Expired token after previous draft save Ã¢Ãâ¬" draft inaccessible | Expired page shown; draft data still in DB but not editable | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-N-016 | Teacher attempts to generate link for unlinked student-guardian | Error "No guardian linked to this student" | Tester A | Tester B | Ã¢Ã¬ÃÅ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|---|
| TC-D-001 | A | ParentFormToken SoftDeletes Ã¢Ãâ¬" delete sets deleted_at | Soft delete sets deleted_at; record still exists in DB | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-002 | A | ParentFormToken restore after soft delete | `restore()` clears deleted_at; record queryable again | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-003 | A | ParentFormToken forceDelete Ã¢Ãâ¬" permanent removal | Row physically deleted from DB | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-004 | B | Token uniqueness enforced at DB level | Inserting duplicate token string throws unique constraint violation | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-005 | C | generateToken() randomness Ã¢Ãâ¬" low collision probability | 1000 generated tokens; zero duplicates | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-006 | D | Expiry check on EVERY request (both GET and POST) | Both dashboard load and form submit check expires_at | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-007 | D | Completion check on submit only | GET form can still open (read-only); POST is blocked | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-008 | E | Role-filtering Ã¢Ãâ¬" only parent-owned fields rendered | Non-parent fields excluded from parent form query | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-009 | B | FK to HpcReport (report_id) Ã¢Ãâ¬" orphan prevention | Cannot insert token with non-existent report_id | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-010 | B | FK to Student (student_id) Ã¢Ãâ¬" orphan prevention | Cannot insert token with non-existent student_id | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-011 | B | FK to Guardian (guardian_id) Ã¢Ãâ¬" orphan prevention | Cannot insert token with non-existent guardian_id | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-012 | F | Missing migration graceful handling | If hpc_parent_form_tokens table missing Ã¢Ãâ ' graceful error, no 500 | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-013 | G | EXPIRY_DAYS configuration change Ã¢Ãâ¬" existing tokens not affected | Tokens generated with old EXPIRY_DAYS retain original expires_at | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-014 | G | MAX_SUBMISSIONS configuration change Ã¢Ãâ¬" existing tokens use old limit | Tokens created under old limit retain original max | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-015 | H | Soft-deleted tokens excluded from active token queries | Default scope filters out deleted_at IS NOT NULL | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-016 | H | WithTrashed scope for admin token management | Admin can view and restore soft-deleted tokens | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-017 | I | submission_count never exceeds MAX_SUBMISSIONS | Business logic caps at 3; DB may enforce via check constraint | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-018 | J | ip_address captured on each submission | Request IP stored; can be used for audit | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-019 | K | Token string length sufficient for security | Token Ã¢Ãâ°Ã¥ 32 chars (or Ã¢Ãâ°Ã¥ 128 bits entropy) | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-020 | L | is_active flag soft-disable without delete | Setting is_active=false prevents use without soft-deleting | Tester A | Tester B | Ã¢Ã¬ÃÅ |
| TC-D-021 | K | Token expiry calculation uses configured timezone | `expires_at` respects app timezone setting | Tester A | Tester B | Ã¢Ã¬ÃÅ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller Ã¢Ãâ¬" Permission Gates for Teacher Endpoints | Controller uses Gate::authorize() or middleware for tenant.hpc.update (generateParentLink) and tenant.hpc.view (parentStatus); public token-based routes (dashboard, form) have no auth middleware | Ã¢Ãâ¬" | Ã¢Ãâ¬" | Ã¢ââ¬âÂ�ÃÅ |
| TC-CR02 | CR | P1 | Controller Ã¢Ãâ¬" Public Routes Without Auth Middleware | Parent dashboard/form routes have NO auth middleware; authentication is token-based via model lookup; controller validates token existence, expiry, and completion on every request | Ã¢Ãâ¬" | Ã¢Ãâ¬" | Ã¢ââ¬âÂ�ÃÅ |
| TC-CR03 | CR | P1 | Controller Ã¢Ãâ¬" Token Validation Chain (Expiry + Completion + Count) | Every controller method (dashboard, form GET, form POST) calls isExpired() and isCompleted(); submit additionally checks submission_count < MAX_SUBMISSIONS; validation order: existence Ã¢Ãâ ' expiry Ã¢Ãâ ' completion Ã¢Ãâ ' count | Ã¢Ãâ¬" | Ã¢Ãâ¬" | Ã¢ââ¬âÂ�ÃÅ |
| TC-CR04 | CR | P1 | Model Ã¢Ãâ¬" SoftDeletes Trait on ParentFormToken | ParentFormToken model uses SoftDeletes trait; delete() sets deleted_at timestamp; restore() clears deleted_at; forceDelete() permanently removes row; default queries exclude soft-deleted records | Ã¢Ãâ¬" | Ã¢Ãâ¬" | Ã¢ââ¬âÂ�ÃÅ |
| TC-CR05 | CR | P1 | Controller Ã¢Ãâ¬" JSON Response Structure After Token Generation | generateParentLink() returns response()->json() with success flag, token URL, and expiry info; client-side JS handles display of confirmation with copyable link | Ã¢Ãâ¬" | Ã¢Ãâ¬" | Ã¢ââ¬âÂ�ÃÅ |

---

## 7. Detailed Test Steps

#### TC-CR01: Controller Ã¢Ãâ¬" Permission Gates for Teacher Endpoints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ParentHpcFormController.php | Controller class found in Modules/Hpc/Http/Controllers/ |
| 2 | Inspect generateParentLink() method | Gate::authorize('tenant.hpc.update') or middleware check before token generation logic |
| 3 | Inspect parentStatus() method | Gate::authorize('tenant.hpc.view') or middleware check before status display |
| 4 | Inspect dashboard() and form() methods | No Gate::authorize() calls; routes are public (token-based) |
| 5 | Log in as user without tenant.hpc.update | Accessing generate-parent-link endpoint returns 403 |
| 6 | Log in as user without tenant.hpc.view | Accessing parent-status endpoint returns 403 |

#### TC-CR02: Controller Ã¢Ãâ¬" Public Routes Without Auth Middleware

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open routes file for HPC module | Route definitions found in module routes file |
| 2 | Inspect hpc/parent/dashboard/{token} route | No auth middleware applied; route is public |
| 3 | Inspect hpc/parent/form/{token} route | No auth middleware applied; both GET and POST are public |
| 4 | Inspect hpc/teacher/* routes | Auth middleware applied; teacher must be authenticated |
| 5 | Open incognito browser and access parent dashboard URL | Page loads without login prompt; token validation runs |

#### TC-CR03: Controller Ã¢Ãâ¬" Token Validation Chain (Expiry + Completion + Count)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ParentHpcFormController.php | Controller class found |
| 2 | Inspect dashboard() method | Calls isExpired() and isCompleted() on the token; redirects to appropriate view |
| 3 | Inspect form() GET method | Calls isExpired() and isCompleted(); shows form only if valid, unexpired, not completed |
| 4 | Inspect form() POST method | Calls isExpired(), isCompleted(), and checks submission_count < MAX_SUBMISSIONS |
| 5 | Verify validation order | Existence check first, then expiry, then completion, then count |
| 6 | Create token with isExpired()=true | dashboard/form GET and POST all reject with expired page |

#### TC-CR04: Model Ã¢Ãâ¬" SoftDeletes Trait on ParentFormToken

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ParentFormToken model | Model found in Modules/Hpc/Models/ |
| 2 | Verify SoftDeletes import | `use SoftDeletes;` trait present in class definition |
| 3 | Inspect $dates or $casts property | `deleted_at` column is cast to datetime or included in $dates |
| 4 | Call `$token->delete()` | deleted_at timestamp set; record still exists in DB |
| 5 | Query without withTrashed() | Soft-deleted record excluded from results |
| 6 | Call `$token->restore()` | deleted_at cleared; record queryable again |

#### TC-CR05: Controller Ã¢Ãâ¬" JSON Response Structure After Token Generation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open ParentHpcFormController.php | Controller found |
| 2 | Inspect generateParentLink() return | Returns response()->json() with structure containing success flag |
| 3 | Verify JSON keys | Response includes: success (bool), url (string), expires_at (date) |
| 4 | Generate a token via API | JSON response matches expected structure |
| 5 | Verify client-side handling | JS reads response and displays copyable link with expiry notice |

### 6.1 Positive TC Steps

#### TC-P-001: Generate parent link Ã¢Ãâ¬" teacher UI loads link generator

**Prerequisites:** Teacher logged in with `tenant.hpc.update` permission; reports exist.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Log in as teacher with permissions | Dashboard loads |
| 2 | Navigate to HPC teacher section | HPC teacher menu visible |
| 3 | Click "Generate Parent Link" | Form loads with report dropdown and guardian dropdown |
| 4 | Verify report dropdown populated | At least one report listed |
| 5 | Verify guardian dropdown | Guardians linked to selected student shown (or all guardians) |

#### TC-P-002: Generate parent link for valid report_id

**Prerequisites:** Teacher is on the generate link page.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Select a report from dropdown | Report selected |
| 2 | Select a guardian from dropdown | Guardian selected |
| 3 | Click "Generate Link" button | Success message displayed |
| 4 | Verify link displayed | Full URL shown: `https://.../hpc/parent/form/{token}` |
| 5 | Verify 7-day validity notice | Text: "This link will expire in 7 days" |

### TC-P-003: Verify generated token in DB

**Prerequisites:** Token generated in TC-P-002.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Query `hpc_parent_form_tokens` table | New record exists |
| 2 | Check token column | Non-null, unique string |
| 3 | Check expires_at | equals NOW() + 7 days (ÃâÃ± 1 minute) |
| 4 | Check is_active | true |
| 5 | Check submission_count | 0 |

### TC-P-004: Parent opens valid unexpired token link Ã¢Ãâ¬" dashboard shows student info

**Prerequisites:** Valid token with is_active=true, expires_at in future.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open `hpc/parent/dashboard/{token}` in incognito/guest browser | Page loads without auth prompt |
| 2 | Verify student info | Student name, class/grade displayed |
| 3 | Verify report info | Report name, description displayed |
| 4 | Check for "Begin Form" button | Button present and enabled |

### TC-P-005: Parent form loads with parent-only fields

**Prerequisites:** Token is valid, unexpired, not completed.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Click "Begin Form" (or navigate to `hpc/parent/form/{token}`) | Form loads |
| 2 | Examine form fields | Only parent-role fields visible |
| 3 | Verify absence of student/teacher fields | No student-only or teacher-only fields present |
| 4 | Check field labels | Use parent-friendly text (e.g., "Your thoughts on..." not "field_42") |

### TC-P-006: Parent fills text field in parent form

**Prerequisites:** Form loaded with text input fields.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Locate a text input field | Input is editable |
| 2 | Enter text: "My child is progressing well" | Text appears |
| 3 | Click Save/Submit | Value accepted |

### TC-P-007: Parent selects dropdown option in parent form

**Prerequisites:** Form loaded with dropdown.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Locate dropdown field | Dropdown is functional |
| 2 | Select an option | Option selected |
| 3 | Submit form | Selection persisted |

### TC-P-008: Parent submits completed form

**Prerequisites:** All required fields filled.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Complete all required fields | All valid |
| 2 | Click Submit button | Form submits |
| 3 | Check response | Redirect or success message |
| 4 | Check DB completed_at | Timestamp set |
| 5 | Check submission_count | Incremented to 1 |

### TC-P-009: Thank-you page displays after first submission

**Prerequisites:** Form just submitted.

| Step | Action | Expected Result |
|---|---|---|
| 1 | After submit, observe page | Thank-you page rendered |
| 2 | Verify message | "Thank you for your submission" or similar |
| 3 | Check no form displayed | Only thank-you content |

### TC-P-010: Re-open completed link Ã¢Ãâ¬" shows "already submitted" and previous data

**Prerequisites:** Token has completed_at set.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open `hpc/parent/dashboard/{token}` | Dashboard shows "Submission already completed" |
| 2 | Navigate to `hpc/parent/form/{token}` | Thank-you page shown |
| 3 | Check previous data visible | Previous responses displayed read-only |
| 4 | Verify no edit capability | No inputs or submit buttons |

### TC-P-011: Parent submits form exactly 3 times (max)

**Prerequisites:** Token allows up to 3 submissions.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Submit form (1st time) | submission_count = 1 |
| 2 | Re-open and submit (2nd time) | submission_count = 2 |
| 3 | Re-open and submit (3rd time) | submission_count = 3 |

### TC-P-012: Fourth submission attempt after reaching MAX_SUBMISSIONS

**Prerequisites:** submission_count = 3.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open form link | Dashboard shows "Maximum submissions reached" |
| 2 | Attempt to POST form data | Rejected; error message displayed |
| 3 | Check DB | submission_count still 3 |

### TC-P-013: Expired link shows "expired page"

**Prerequisites:** Token has expires_at in the past.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open `hpc/parent/dashboard/{expired_token}` | Expired page loads |
| 2 | Verify message | "This link has expired" |
| 3 | Check for form | No form rendered |

### TC-P-014: Teacher views parent completion status

**Prerequisites:** Teacher has `tenant.hpc.view` permission; tokens exist for report.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Log in as teacher | Teacher session |
| 2 | Navigate to `hpc/teacher/parent-status/{report_id}` | Status page loads |
| 3 | Verify token info | Token display: status (active/expired/completed), submission count, dates |
| 4 | Check submission count shown | Count matches actual submissions |

### TC-P-015: Teacher views status for multiple parent tokens

**Prerequisites:** Report has multiple guardian tokens.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open parent status page for report | All tokens listed |
| 2 | Verify each token row | Guardian name, token status, expiry date, submission count |

### TC-P-016: submission_count increments correctly after each submit

**Prerequisites:** Token with submission_count = 0.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Submit form | count = 1 |
| 2 | Submit form again | count = 2 |
| 3 | Submit form again | count = 3 |
| 4 | Verify against DB | Each increment matches request count |

### TC-P-017: Parent saves draft and returns later

**Prerequisites:** Token valid, form partially completed.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Fill some fields | Values entered |
| 2 | Click Save Draft | Values persisted; no completed_at set |
| 3 | Close browser | Session ends |
| 4 | Re-open same token link | Draft values restored |
| 5 | Continue editing | Additional edits accepted |

### TC-P-018: Different parent tokens for different reports generate unique links

**Prerequisites:** Generate tokens for 2+ reports.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Generate token for Report A | Token A created |
| 2 | Generate token for Report B | Token B created |
| 3 | Compare tokens | Token A !== Token B |

### TC-P-019: Teacher can regenerate link if token expired

**Prerequisites:** Existing expired token for report.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open generate link page | Report selected |
| 2 | System detects expired token | Optional: shows "Previous link expired" notice |
| 3 | Generate new link | New token created; old token is_active set to false |
| 4 | Open new link | Works correctly |

### TC-P-020: Parent form label matches parent-friendly language

**Prerequisites:** Form with custom labels.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open parent form for any token | Labels displayed |
| 2 | Inspect first field label | Reads naturally (e.g., "How would you describe your child's attitude?" not "field_attitude_score") |

### TC-P-021: IP address logged on parent submission

**Prerequisites:** Submit parent form.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Submit parent form | Submission succeeds |
| 2 | Check DB `hpc_parent_form_tokens.ip_address` | IP address of submitter recorded |

### TC-P-022: Teacher sees "Link Generated" confirmation with copyable URL

**Prerequisites:** Token generated successfully.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Generate token via teacher UI | Confirmation block appears |
| 2 | Verify URL displayed | Full URL: `https://domain/hpc/parent/form/{token}` |
| 3 | Verify copy button or text selectable | URL is selectable or has "Copy" button |

### TC-N-001: Invalid/random token (non-existent UUID) Ã¢Ãâ ' 404

**Prerequisites:** None.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `hpc/parent/dashboard/abc123invalidtoken` | 404 page rendered |
| 2 | Verify no stack trace | User-friendly 404 |

### TC-N-002: Expired token Ã¢Ãâ ' expired page

**Prerequisites:** Token with expires_at in past.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `hpc/parent/dashboard/{expired_token}` | Expired page shown |
| 2 | Verify message | "This link has expired. Please contact the school for a new link." |
| 3 | Navigate to `hpc/parent/form/{expired_token}` | Also expired page; no form |

### TC-N-003: Completed token Ã¢Ãâ ' resubmit refused

**Prerequisites:** Token with completed_at set.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open `hpc/parent/form/{completed_token}` | Thank-you page shown |
| 2 | Attempt POST submit with valid data | Request rejected |
| 3 | Verify DB unchanged | Original submission_count and data intact |

### TC-N-004: Tampered token (modified last char) Ã¢Ãâ ' 404

**Prerequisites:** Valid token exists.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Take valid token string | e.g., "aB3x...Yz9" |
| 2 | Change last character | "aB3x...Yz0" |
| 3 | Navigate with tampered token | 404 Not Found |

### TC-N-005: Missing token parameter from URL Ã¢Ãâ ' 404

**Prerequisites:** None.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `hpc/parent/dashboard/` (no token) | 404 page (route not matched) |
| 2 | Navigate to `hpc/parent/form/` (no token) | 404 page |

### TC-N-006: Link for non-existent report_id Ã¢Ãâ ' teacher generation fails

**Prerequisites:** Teacher on generate page.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Use browser DevTools to POST with report_id=99999 | Validation error |
| 2 | Verify error message | "The selected report is invalid" or "Report not found" |

### TC-N-007: Permission denied for teacher without `tenant.hpc.update` Ã¢Ãâ ' 403

**Prerequisites:** Teacher authenticated but lacks `tenant.hpc.update`.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Revoke `tenant.hpc.update` from teacher role | Permission removed |
| 2 | Access `hpc/teacher/generate-parent-link/{report_id}` | 403 Forbidden |
| 3 | Verify error message | Permission denied message |

### TC-N-008: Permission denied for teacher without `tenant.hpc.view` Ã¢Ãâ ' 403

**Prerequisites:** Teacher lacks `tenant.hpc.view`.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Revoke `tenant.hpc.view` | Permission removed |
| 2 | Access `hpc/teacher/parent-status/{report_id}` | 403 Forbidden |

### TC-N-009: Guest user accessing teacher endpoint Ã¢Ãâ ' login redirect

**Prerequisites:** User not logged in.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Access `hpc/teacher/generate-parent-link/1` while logged out | 302 redirect to /login |

### TC-N-010: Expired token POST submit Ã¢Ãâ ' rejected

**Prerequisites:** Token expired but was not completed (has draft data).

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open `hpc/parent/form/{expired_token}` | Expired page (GET) |
| 2 | Bypass UI and POST form data via DevTools | Rejected; expired page shown; data not saved |

### TC-N-011: completed_at token POST submit Ã¢Ãâ ' duplicate rejected

**Prerequisites:** Token has completed_at set.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open completed token form | Shows thank-you (GET) |
| 2 | POST form data via DevTools | Rejected; submission_count unchanged |

### TC-N-012: Generate token without selecting guardian

**Prerequisites:** Teacher on generate page.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Select report but leave guardian empty | Validation error |
| 2 | Submit form | Error: "Guardian is required" |

### TC-N-013: Generate token without report_id

**Prerequisites:** Teacher on generate page.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Leave report field empty | Validation error |
| 2 | Submit form | Error: "Report is required" |

### TC-N-014: CSRF token mismatch on parent form submit

**Prerequisites:** Valid token, form loaded with CSRF.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open parent form | CSRF token embedded |
| 2 | Replace CSRF token with invalid value | Token mismatch |
| 3 | Submit form | 419 Page Expired |

### TC-N-015: Expired token after previous draft save Ã¢Ãâ¬" draft inaccessible

**Prerequisites:** Token: draft saved, now expired.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open token link | Expired page shown |
| 2 | Verify draft data not exposed | No form; no draft data leakage |
| 3 | Check DB draft data | Data still present but inaccessible |

### TC-N-016: Teacher attempts to generate link for unlinked student-guardian

**Prerequisites:** Student exists; guardian exists but not linked to student.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Select report for student without linked guardian | Guardian dropdown shows message "No guardians linked" |
| 2 | Attempt to submit | Error or disabled button |

### TC-D-001: ParentFormToken SoftDeletes Ã¢Ãâ¬" delete sets deleted_at

**Prerequisites:** ParentFormToken record exists.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Call `$token->delete()` on ParentFormToken | deleted_at timestamp set |
| 2 | Query DB directly | Row exists with deleted_at NOT NULL |
| 3 | Query via default Eloquent scope | Record not returned |

### TC-D-002: ParentFormToken restore after soft delete

**Prerequisites:** Token soft-deleted.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Call `$token->restore()` | deleted_at cleared |
| 2 | Query via default scope | Token queryable |
| 3 | Verify token still functional | Can be used to access parent form |

### TC-D-003: ParentFormToken forceDelete Ã¢Ãâ¬" permanent removal

**Prerequisites:** Token record exists.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Call `$token->forceDelete()` | Row physically deleted |
| 2 | Query DB directly | Row absent |

### TC-D-004: Token uniqueness enforced at DB level

**Prerequisites:** One token record exists.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Note existing token string | e.g., "abc123" |
| 2 | Attempt to INSERT new row with same token | Unique constraint violation |
| 3 | Verify Eloquent duplicate check | Model also validates before insert |

### TC-D-005: generateToken() randomness Ã¢Ãâ¬" low collision probability

**Prerequisites:** generateToken() method accessible.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Call generateToken() 1000 times | 1000 unique strings |
| 2 | Check for duplicates | Zero duplicates |
| 3 | Verify string length | Ã¢Ãâ°Ã¥ 32 characters |
| 4 | Verify character set | Alphanumeric + special chars (high entropy) |

### TC-D-006: Expiry check on EVERY request (both GET and POST)

**Prerequisites:** Token is expired (or about to expire).

| Step | Action | Expected Result |
|---|---|---|
| 1 | Access `hpc/parent/dashboard/{token}` GET | Check performed |
| 2 | Access `hpc/parent/form/{token}` GET | Check performed |
| 3 | POST to `hpc/parent/form/{token}` | Check performed |
| 4 | Validate: every controller method calls isExpired() | All paths covered |

### TC-D-007: Completion check on submit only

**Prerequisites:** Token has completed_at set.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Access `hpc/parent/form/{token}` GET | Loads thank-you page (allowed) |
| 2 | POST to same endpoint | Rejected (completion check) |
| 3 | Verify GET not blocked | Read-only view accessible |

### TC-D-008: Role-filtering Ã¢Ãâ¬" only parent-owned fields rendered

**Prerequisites:** Form has fields for multiple roles.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open parent form | Inspect HTML for any non-parent fields |
| 2 | Count rendered fields | Only fields with role=parent are present |
| 3 | Attempt to POST non-parent field data | Server ignores field |

### TC-D-009: FK to HpcReport (report_id) Ã¢Ãâ¬" orphan prevention

**Prerequisites:** Database FK constraint exists.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Insert token with valid report_id | Success |
| 2 | Insert token with report_id=99999 | FK violation |
| 3 | Delete report that has tokens | Cascade or restrict per FK definition |

### TC-D-010: FK to Student (student_id) Ã¢Ãâ¬" orphan prevention

**Prerequisites:** FK constraint on student_id.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Insert token with valid student_id | Success |
| 2 | Insert token with student_id=99999 | FK violation |

### TC-D-011: FK to Guardian (guardian_id) Ã¢Ãâ¬" orphan prevention

**Prerequisites:** FK constraint on guardian_id.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Insert token with valid guardian_id | Success |
| 2 | Insert token with guardian_id=99999 | FK violation |

### TC-D-012: Missing migration graceful handling

**Prerequisites:** hpc_parent_form_tokens table does not exist.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Access any parent endpoint | Error message "System configuration error" or "Module not fully installed" |
| 2 | Check server logs | Exception logged but not displayed to user |
| 3 | Verify HTTP status | Not 500; user-friendly error page |

### TC-D-013: EXPIRY_DAYS configuration change Ã¢Ãâ¬" existing tokens not affected

**Prerequisites:** Tokens exist with 7-day expiry; then EXPIRY_DAYS changed to 14.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Note existing token expires_at | Set to original 7 days |
| 2 | Change EXPIRY_DAYS to 14 in config | Config updated |
| 3 | Check existing token expires_at | Unchanged (still original date) |
| 4 | Generate new token | New token has 14-day expiry |

### TC-D-014: MAX_SUBMISSIONS configuration change Ã¢Ãâ¬" existing tokens use old limit

**Prerequisites:** Tokens exist with MAX_SUBMISSIONS=3; config changed to 5.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Note existing token submission_count=3 | At limit under old config |
| 2 | Change MAX_SUBMISSIONS to 5 | Config updated |
| 3 | Try submitting existing token | Still blocked (stored as business logic, not live config) or now allowed depending on implementation |
| 4 | Verify behaviour | Implementation dependent Ã¢Ãâ¬" verify against spec |

### TC-D-015: Soft-deleted tokens excluded from active token queries

**Prerequisites:** Soft-deleted token exists.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Query for active tokens by report_id | Soft-deleted token excluded |
| 2 | Count results | Deleted token not counted |
| 3 | Verify controller uses default scope | Parent endpoints only return non-deleted tokens |

### TC-D-016: WithTrashed scope for admin token management

**Prerequisites:** Admin user; soft-deleted tokens exist.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Query with `->withTrashed()` | All tokens including deleted |
| 2 | Access admin token management UI | Option to view deleted tokens |
| 3 | Restore a deleted token | Token reactivated; functional again |

### TC-D-017: submission_count never exceeds MAX_SUBMISSIONS

**Prerequisites:** Max is 3; submission_count at 2.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Submit form (3rd time) | submission_count = 3 |
| 2 | Attempt 4th submission | Rejected; count remains 3 |
| 3 | Direct DB update to 4 | Possible only via direct DB; business logic prevents |

### TC-D-018: ip_address captured on each submission

**Prerequisites:** Submit parent form.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Submit form from IP 192.168.1.100 | ip_address = "192.168.1.100" |
| 2 | Submit from different IP | ip_address updated |

### TC-D-019: Token string length sufficient for security

**Prerequisites:** generateToken() implemented.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Generate token | String output |
| 2 | Check length | Ã¢Ãâ°Ã¥ 32 characters |
| 3 | Check entropy | Contains uppercase, lowercase, digits; preferably symbols |

### TC-D-020: is_active flag soft-disable without delete

**Prerequisites:** Token with is_active = true.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Set is_active = false | Token deactivated |
| 2 | Access token link | Error "This link is no longer active" |
| 3 | Set is_active = true | Token reactivated; works again |

### TC-D-021: Token expiry calculation uses configured timezone

**Prerequisites:** App config has timezone set.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Generate token | expires_at = now(tz) + 7 days |
| 2 | Check stored timestamp | Timezone offset matches config (e.g., UTC, America/New_York) |

---

*Document generated for HPC Parent Portal testing. Status column uses Ã¢Ã¬ÃÅ (pending), Ã°ÃŸÃŸÃ¢ (pass), Ã°ÃŸ"Ã´ (fail), Ã°ÃŸÃŸÃ¡ (blocked).*

## 8. CODE-TRACE: Controller Method Execution Traces

### CODE-TRACE-01: `generateParentLink()` ââ¬âÂ� ParentHpcFormController (Line 31)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `ParentHpcFormController.php:33` | `Gate::authorize('tenant.hpc.update')` ââ¬âÂ� teacher permission |
| 2 | `ParentHpcFormController.php:35` | Validates `guardian_id` |
| 3 | `ParentHpcFormController.php:37` | `HpcReport::findOrFail($reportId)` |
| 4 | `ParentHpcFormController.php:39-45` | `parentService->generateToken($reportId, $student_id, $guardian_id, auth()->id())` ââ¬âÂ� creates unique token with expiry |
| 5 | `ParentHpcFormController.php:47-57` | Returns JSON with URL, token, expiry |

### CODE-TRACE-02: `parentStatus()` ââ¬âÂ� ParentHpcFormController (Line 63)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `ParentHpcFormController.php:65` | `Gate::authorize('tenant.hpc.view')` ââ¬âÂ� teacher permission |
| 2 | `ParentHpcFormController.php:67` | `parentService->getParentStatus($reportId)` |
| 3 | `ParentHpcFormController.php:69-73` | Returns JSON with status data |

### CODE-TRACE-03: `form()` ââ¬âÂ� ParentHpcFormController (Line 83)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `ParentHpcFormController.php:85` | No Gate ââ¬âÂ� token-based public access |
| 2 | `ParentHpcFormController.php:87` | `parentService->validateToken($token)` ââ¬âÂ� checks expiry |
| 3 | `ParentHpcFormController.php:89-90` | If expired ? `hpc::parent.expired` view |
| 4 | `ParentHpcFormController.php:91-92` | If completed ? `hpc::parent.thank-you` view |
| 5 | `ParentHpcFormController.php:95-105` | Loads `parentService->getParentPages($templateId)`, `Organization::first()`, saved values |
| 6 | `ParentHpcFormController.php:108-118` | Returns `hpc::parent.form` view |

### CODE-TRACE-04: `save()` ââ¬âÂ� ParentHpcFormController (Line 124)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `ParentHpcFormController.php:127` | No Gate ââ¬âÂ� token-based public access |
| 2 | `ParentHpcFormController.php:129` | Validates token |
| 3 | `ParentHpcFormController.php:132` | `HpcSectionRoleService::filterPayloadByRole($payload, $templateId, 'parent')` |
| 4 | `ParentHpcFormController.php:135` | `parentService->saveResponses($tokenRecord, $filteredPayload, $request->ip())` |
| 5 | `ParentHpcFormController.php:138-142` | If `submit_final` ? `parentService->markComplete($tokenRecord)` |
| 6 | `ParentHpcFormController.php:145-168` | Returns JSON response |

### CODE-TRACE-05: `dashboard()` ââ¬âÂ� ParentHpcFormController (Line 174)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `ParentHpcFormController.php:176` | No Gate ââ¬âÂ� token-based public access |
| 2 | `ParentHpcFormController.php:178-182` | Validates token |
| 3 | `ParentHpcFormController.php:184-190` | Loads report, student, organization, parent status, checks published |
| 4 | `ParentHpcFormController.php:192-201` | Returns `hpc::parent.dashboard` view |

---
