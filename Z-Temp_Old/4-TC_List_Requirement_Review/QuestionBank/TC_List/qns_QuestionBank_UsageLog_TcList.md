# qns_QuestionBank_UsageLog_TcList

## Module: QuestionBank → Question Usage Log

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | QuestionBank (QNS) |
| Tab Group | Question Usage Log (Tabbed under Question Bank) |
| Feature | Usage Log Listing, Filtering, Status Toggle — system-only creation by Quiz/Quest/Exam modules |
| URL(s) | `/question-bank/question-bank` (index — `question_usag_log` tab), `/question-bank/question-usage-log/{id}/toggle-status` (toggleStatus) |
| Controller | `Modules\QuestionBank\Http\Controllers\QuestionBankController` (index tab, toggleStatusLog) |
| Service | `Modules\QuestionBank\Services\QuestionLookupService` (`getQuestionUsageLogsQuery`) |
| Model(s) | `QuestionUsageLog` (`Modules\QuestionBank\Models\QuestionUsageLog`) — `SoftDeletes` trait |
| Validation | DB-level only (NOT NULL constraints, FK constraints) — no dedicated Request class |
| Permission Gates (Policy) | `tenant.question-usage-log.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status`, `.print` |
| Permission Gates (Toggle) | `tenant.question-bank.update` (used by `toggleStatusLog()`) |
| Soft Deletes | Yes — `SoftDeletes` trait on `QuestionUsageLog` |
| Activity Log Events | `Toggled` (on status toggle) |
| Auto-Generated Fields | `used_at` (CURRENT_TIMESTAMP), `created_at`, `updated_at` (timestamps) |

---

## 2. Pre-conditions

- Required permissions: `tenant.question-usage-log.viewAny` (tab view), `tenant.question-bank.update` (status toggle)
- At least one `QuestionBank` record must exist in `qns_questions_bank`
- At least one `QuestionUsageType` record must exist in `qns_question_usage_type`
- For toggle tests: At least one `QuestionUsageLog` record with `is_active = 1` or `is_active = 0`
- For cascade tests: `fk_qusage_question` and `fk_qusage_usage_type` foreign keys must exist
- For tab tests: Question Bank tab configuration must include `question_usag_log` tab

---

## 3. Default Data Load

When Question Bank index tab loads (GET `/question-bank/question-bank`) with `tab=question_usag_log`:

| Data | Source | Query | Pagination |
|------|--------|-------|------------|
| Usage Logs | `QuestionLookupService@getQuestionUsageLogsQuery` | Eager loads `question` + `usageType`; filterable by `usage_context` (via `scopeContext()`) and `is_active`; ordered by `used_at DESC` | 10 per page, `usage_logs_page` param |

---

## 4. BC-DB — Database Schema

### `qns_question_usage_log` — Question Usage Log Table

| BC-DB ID | Column | Type (DDL) | Nullable | Default | Constraints | Notes |
|----------|--------|------------|----------|---------|-------------|-------|
| BC-DB-01 | id | INT UNSIGNED | NOT NULL | | PK, AUTO_INCREMENT | Surrogate primary key |
| BC-DB-02 | question_bank_id | INT UNSIGNED | NOT NULL | | FK → `qns_questions_bank.id`, ON DELETE CASCADE | References question |
| BC-DB-03 | question_usage_type_id | INT UNSIGNED | NOT NULL | | FK → `qns_question_usage_type.id`, ON DELETE CASCADE | References usage type |
| BC-DB-04 | context_id | INT UNSIGNED | NOT NULL | | | Links to consuming module record (quiz/quest/exam ID) |
| BC-DB-05 | used_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | | When question was used |
| BC-DB-06 | is_active | TINYINT(1) | NOT NULL | 1 | | Boolean active status |
| BC-DB-07 | created_at | TIMESTAMP | NULL | CURRENT_TIMESTAMP | | |
| BC-DB-08 | updated_at | TIMESTAMP | NULL | ON UPDATE CURRENT_TIMESTAMP | | |
| BC-DB-09 | deleted_at | TIMESTAMP | NULLABLE | NULL | | Soft delete marker |

**Foreign Keys:**
| Constraint Name | Column | Referenced Table | On Delete |
|-----------------|--------|------------------|-----------|
| `fk_qusage_question` | `question_bank_id` | `qns_questions_bank.id` | CASCADE |
| `fk_qusage_usage_type` | `question_usage_type_id` | `qns_question_usage_type.id` | CASCADE |

---

## 5. BC-VAL — Validation Rules

No dedicated Request class — validation is enforced at DB level only.

| BC-VAL ID | Field | Constraint | Error Behavior |
|-----------|-------|------------|----------------|
| BC-VAL-01 | `question_bank_id` | NOT NULL + FK → `qns_questions_bank.id` | DB throws integrity constraint violation on NULL or invalid FK |
| BC-VAL-02 | `question_usage_type_id` | NOT NULL + FK → `qns_question_usage_type.id` | DB throws integrity constraint violation on NULL or invalid FK |
| BC-VAL-03 | `context_id` | NOT NULL | DB throws integrity constraint violation on NULL |
| BC-VAL-04 | `is_active` | TINYINT(1), DEFAULT 1 | DB rejects non-boolean values; model casts to boolean |
| BC-VAL-05 | `used_at` | DEFAULT CURRENT_TIMESTAMP | Auto-set on insert if omitted |

---

## 6. BC-AUTH — Authorization

### 6.1 Policy Gates

Source: `Modules\QuestionBank\Policies\QuestionUsageLogPolicy`

| BC-AUTH ID | Gate Name | Policy Method | Permission String | Scope |
|------------|-----------|---------------|-------------------|-------|
| BC-AUTH-01 | viewAny | `viewAny(User $user): bool` | `tenant.question-usage-log.viewAny` | List usage logs in tab |
| BC-AUTH-02 | view | `view(User $user, QuestionUsageLog $log): bool` | `tenant.question-usage-log.view` | View single usage log |
| BC-AUTH-03 | create | `create(User $user): bool` | `tenant.question-usage-log.create` | Create usage log |
| BC-AUTH-04 | update | `update(User $user, QuestionUsageLog $log): bool` | `tenant.question-usage-log.update` | Update usage log |
| BC-AUTH-05 | delete | `delete(User $user, QuestionUsageLog $log): bool` | `tenant.question-usage-log.delete` | Soft delete |
| BC-AUTH-06 | restore | `restore(User $user, QuestionUsageLog $log): bool` | `tenant.question-usage-log.restore` | Restore from trash |
| BC-AUTH-07 | forceDelete | `forceDelete(User $user, QuestionUsageLog $log): bool` | `tenant.question-usage-log.forceDelete` | Permanent delete |
| BC-AUTH-08 | status | `status(User $user): bool` | `tenant.question-usage-log.status` | Toggle active status |
| BC-AUTH-09 | print | `print(User $user): bool` | `tenant.question-usage-log.print` | Print/export logs |

### 6.2 Controller Gate Calls

| BC-AUTH ID | Controller Method | Gate String Used | Notes |
|------------|-------------------|------------------|-------|
| BC-AUTH-C-01 | toggleStatusLog (on QuestionBankController) | `tenant.question-bank.update` | Uses `question-bank` (dash, update), not `question-usage-log.status` |
| BC-AUTH-C-02 | index() — tab visibility | `tenant.question-bank.viewAny` (controller) / `tenant.question-usage-log.viewAny` (Blade tab config) | Controller gates entire page with `question-bank.viewAny`; Blade `@can` hides the tab. No 403 from this gate alone. |

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description | Enforcement Point |
|-----------|------|-------------|-------------------|
| BC-BIZ-01 | System-Only Creation | Usage logs are created only by Quiz, Quest, and Exam modules — no manual create route for teachers | No create/store controller methods; consuming modules call `QuestionUsageLog::create()` |
| BC-BIZ-02 | Context Tracking | `context_id` stores the consuming module record ID (quiz/quest/exam pivot ID) | Controller in each module sets context_id when creating log |
| BC-BIZ-03 | Auto-Logging on Question Assignment | Assigning a question to Quiz/Quest/Exam automatically creates a `QuestionUsageLog` record | `QuizQuestionController`, `QuestQuestionController`, `PaperSetQuestionController` |
| BC-BIZ-04 | Same Question Multiple Contexts | Same `question_bank_id` can appear in multiple logs with different `context_id` values | No unique constraint on `question_bank_id` |
| BC-BIZ-05 | Status Toggle | POST to `/question-usage-log/{id}/toggle-status` flips `is_active` | `QuestionBankController@toggleStatusLog` |
| BC-BIZ-06 | Status Toggle Activity Log | Toggle calls `activityLog()` with 'Toggled' event | Controller after toggle |
| BC-BIZ-07 | Status Toggle JSON Response | Returns `{success, is_active, message}` | Controller response |
| BC-BIZ-08 | Cascade Delete on Force Question Delete | FK `fk_qusage_question` ON DELETE CASCADE removes logs when parent question is force-deleted | DB-level cascade |
| BC-BIZ-09 | Cascade Delete on Force Usage Type Delete | FK `fk_qusage_usage_type` ON DELETE CASCADE removes logs when parent usage type is force-deleted | DB-level cascade |
| BC-BIZ-10 | Soft Delete Log Preserves Question | Soft-deleting a usage log does NOT cascade to `qns_questions_bank` | Only `deleted_at` set on log; question intact |
| BC-BIZ-11 | Logs Listed in Question Bank Tab | `question_usag_log` tab shows logs via `QuestionLookupService@getQuestionUsageLogsQuery` | Tab view rendering |
| BC-BIZ-12 | Paginated 10 Per Page | `usage_logs_page` query param controls pagination | Paginate(10, ['*'], 'usage_logs_page') |
| BC-BIZ-13 | Filter by usage_context | `usage_context` query string filters by `question_usage_type_id` | Applied in query service |
| BC-BIZ-14 | Filter by is_active | `is_active` query string filters active/inactive logs | Applied in query service |
| BC-BIZ-15 | Ordered by used_at DESC | Default sort is most recent first | `orderBy('used_at', 'desc')` |
| BC-BIZ-16 | resolveUsageTypeId() resolves code | Static method `resolveUsageTypeId('QUIZ')` returns matching ID from `qns_question_usage_type` | Model method queries by `code` column |

### 7.1 Model Attributes

| BC-BIZ ID | Attribute | Type | Notes |
|-----------|-----------|------|-------|
| BC-BIZ-ATTR-01 | `$fillable` | `['question_bank_id', 'question_usage_type_id', 'context_id', 'used_at', 'is_active']` | Mass-assignable fields |
| BC-BIZ-ATTR-02 | `$casts` | `used_at => datetime`, `is_active => boolean` | Attribute casting |
| BC-BIZ-ATTR-03 | `$table` | `qns_question_usage_log` | DB table name |
| BC-BIZ-ATTR-04 | `$primaryKey` | `id` | Primary key |

### 7.2 Model Scopes

| BC-BIZ ID | Scope | Logic |
|-----------|-------|-------|
| BC-BIZ-SCP-01 | `scopeActive` | `where('is_active', true)` |
| BC-BIZ-SCP-02 | `scopeContext` | `where('question_usage_type_id', $typeId)` |
| BC-BIZ-SCP-03 | `scopeForContextId` | `where('context_id', $contextId)` |

### 7.3 Model Relationships

| BC-BIZ ID | Relation | Type | Foreign Key | Local Key |
|-----------|----------|------|-------------|-----------|
| BC-BIZ-REL-01 | `question()` | BelongsTo | `question_bank_id` | `id` on `qns_questions_bank` |
| BC-BIZ-REL-02 | `usageType()` | BelongsTo | `question_usage_type_id` | `id` on `qns_question_usage_type` |

---

## 8. BC-REF — Referential Integrity

### Foreign Keys on `qns_question_usage_log`

| BC-REF ID | FK Name | Foreign Key Column | Referenced Table (Column) | On Delete | Notes |
|-----------|---------|--------------------|---------------------------|-----------|-------|
| BC-REF-01 | `fk_qusage_question` | `question_bank_id` | `qns_questions_bank.id` | CASCADE | Force-deleting a question cascades to all its usage logs |
| BC-REF-02 | `fk_qusage_usage_type` | `question_usage_type_id` | `qns_question_usage_type.id` | CASCADE | Force-deleting a usage type cascades to all its usage logs |

### Referential Integrity Rules

| BC-REF ID | Rule | Description |
|-----------|------|-------------|
| BC-REF-03 | No Orphan Logs | FK cascade ensures logs cannot exist without parent question or usage type |
| BC-REF-04 | Soft Delete Integrity | Soft-deleting a log preserves `question_bank_id` FK — question remains intact |
| BC-REF-05 | Cascade-Only on Force Delete | ON DELETE CASCADE triggers only on actual row deletion (force delete), not on soft delete |

---

## 9. Test Case Summary

### 9.1 Positive TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-P01 | Record Creation — Minimal with required fields | Schema | DB Layer | High |
| TC-P02 | Record Creation — With all fillable fields | Schema | DB Layer | High |
| TC-P03 | id — Auto-increment PK | Schema | DB Layer | High |
| TC-P04 | question_bank_id — FK cascade on question force delete | Schema | DB Layer | High |
| TC-P05 | question_usage_type_id — FK cascade on usage type force delete | Schema | DB Layer | High |
| TC-P06 | context_id — Required (NOT NULL) | Schema | DB Layer | High |
| TC-P07 | used_at — Defaults to CURRENT_TIMESTAMP | Schema | DB Layer | Medium |
| TC-P08 | is_active — Defaults to true (1) | Schema | DB Layer | High |
| TC-P09 | SoftDeletes — Soft delete sets deleted_at | Schema | DB Layer | High |
| TC-P10 | SoftDeletes — Restore clears deleted_at | Schema | DB Layer | High |
| TC-P11 | SoftDeletes — Force delete removes record permanently | Schema | DB Layer | High |
| TC-P12 | Model — Table name returns `qns_question_usage_log` | Schema | Model | Medium |
| TC-P13 | Model — is_active boolean cast | Schema | Model | Medium |
| TC-P14 | Model — used_at datetime cast | Schema | Model | Medium |
| TC-P15 | Model — question() BelongsTo relationship | Schema | Model | High |
| TC-P16 | Model — usageType() BelongsTo relationship | Schema | Model | High |
| TC-P17 | Model — scopeActive() filters by is_active = true | Functional | Model Scope | High |
| TC-P18 | Model — scopeContext() filters by question_usage_type_id | Functional | Model Scope | High |
| TC-P19 | Model — scopeForContextId() filters by context_id | Functional | Model Scope | High |
| TC-P20 | Model — resolveUsageTypeId('QUIZ') returns correct ID | Functional | Model | High |
| TC-P21 | Business — Same question logged for multiple contexts | Functional | Business Logic | High |
| TC-P22 | Business — Toggle status via POST flips is_active | Functional | Status Toggle | High |
| TC-P23 | Business — Toggle status returns JSON response | Functional | Status Toggle | High |
| TC-P24 | Business — Tab lists usage logs with pagination (10 per page) | Functional | Listing | High |
| TC-P25 | Business — Filter by usage_context (question_usage_type_id) | Functional | Filtering | High |
| TC-P26 | Business — Filter by is_active | Functional | Filtering | High |
| TC-P27 | Business — Logs ordered by used_at DESC | Functional | Listing | Medium |
| TC-P28 | Business — Soft delete log preserves parent question | Functional | Business Logic | High |

### 9.2 Negative TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-N01 | question_bank_id missing (NULL) — DB constraint violation | Validation | DB Layer | High |
| TC-N02 | question_usage_type_id missing (NULL) — DB constraint violation | Validation | DB Layer | High |
| TC-N03 | context_id missing (NULL) — DB constraint violation | Validation | DB Layer | High |
| TC-N04 | Invalid question_bank_id — FK constraint violation | Validation | DB Layer | High |
| TC-N05 | Invalid question_usage_type_id — FK constraint violation | Validation | DB Layer | High |
| TC-N06 | Toggle status — Without tenant.question-bank.update permission → 403 | Auth | Permission | High |
| TC-N07 | View tab — Without tenant.question-usage-log.viewAny permission → 403 | Auth | Permission | High |
| TC-N08 | Toggle status — Non-existent log ID → 404 | Functional | Status Toggle | High |
| TC-N09 | Tab access — Usage logs tab hidden when user lacks viewAny | Auth | Tab Visibility | High |
| TC-N10 | GET method on toggle-status (should be POST only) | Functional | Route | Medium |

### 9.3 Dependency TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-D01 | Cascade — Force delete question cascades to usage logs | Integration | FK Cascade | High |
| TC-D02 | Cascade — Force delete usage type cascades to usage logs | Integration | FK Cascade | High |
| TC-D03 | Integration — Quiz module auto-logs on question assignment | Integration | Module Interop | High |
| TC-D04 | Integration — Quest module auto-logs on question assignment | Integration | Module Interop | High |
| TC-D05 | Integration — Exam module (online) auto-logs on question assignment | Integration | Module Interop | High |
| TC-D06 | Integration — Exam module (offline) auto-logs on question assignment | Integration | Module Interop | High |
| TC-D07 | Integrity — Orphan logs cannot exist without parent question | Integration | FK Integrity | Medium |
| TC-D08 | Integrity — Soft delete preserves referential integrity | Integration | FK Integrity | Medium |

### 9.4 Code Review TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-CR01 | Model — SoftDeletes + fillable + casts configuration | Code Review | Model | High |
| TC-CR02 | Model — question() BelongsTo relationship definition | Code Review | Model | High |
| TC-CR03 | Model — usageType() BelongsTo relationship definition | Code Review | Model | High |
| TC-CR04 | Model — scopeActive() query implementation | Code Review | Model | Medium |
| TC-CR05 | Model — scopeContext() query implementation | Code Review | Model | Medium |
| TC-CR06 | Model — scopeForContextId() query implementation | Code Review | Model | Medium |
| TC-CR07 | Model — resolveUsageTypeId() static method | Code Review | Model | High |
| TC-CR08 | Policy — QuestionUsageLogPolicy gates (9 gates) | Code Review | Policy | High |
| TC-CR09 | Controller — toggleStatusLog() toggle logic in QuestionBankController | Code Review | Controller | High |
| TC-CR10 | Controller — toggleStatusLog() gate authorization (tenant.question-bank.update) | Code Review | Controller | High |
| TC-CR11 | Service — QuestionLookupService@getQuestionUsageLogsQuery implementation | Code Review | Service | High |
| TC-CR12 | Controller — Tab integration in QuestionBankController@index | Code Review | Controller | Medium |
| TC-CR13 | Controller — Activity logging on status toggle | Code Review | Controller | Medium |
| TC-CR14 | Blade — @can directives for permission-based tab + toggle visibility | Code Review | View | Medium |
| TC-CR15 | Controller — toggleStatusLog() JSON response format | Code Review | Controller | Medium |

### 9.5 Total TC Count

| Category | Count |
|----------|-------|
| Positive (TC-P) | 28 |
| Negative (TC-N) | 10 |
| Dependency (TC-D) | 8 |
| Code Review (TC-CR) | 15 |
| **Total** | **61** |

---

## 10. Positive TC Steps

### 10.1 DB Schema — Record Creation

#### TC-P01: Record Creation — Minimal with required fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Question Q1 in `qns_questions_bank` | Q1 exists |
| 2 | Create UsageType UT1 with code 'QUIZ' in `qns_question_usage_type` | UT1 exists |
| 3 | Insert `QuestionUsageLog` with only: `question_bank_id = Q1.id`, `question_usage_type_id = UT1.id`, `context_id = 1` | Record inserted |
| 4 | DB check: `id` | Auto-assigned (not null) |
| 5 | DB check: `is_active` | 1 (default) |
| 6 | DB check: `used_at` | Set to CURRENT_TIMESTAMP (not null) |
| 7 | DB check: `created_at` | Set to CURRENT_TIMESTAMP |

---

#### TC-P02: Record Creation — With all fillable fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Question Q1 | Q1 exists |
| 2 | Create UsageType UT1 | UT1 exists |
| 3 | Insert `QuestionUsageLog` with all fillable fields: `question_bank_id = Q1.id`, `question_usage_type_id = UT1.id`, `context_id = 10`, `used_at = '2026-07-15 10:00:00'`, `is_active = 0` | Record inserted |
| 4 | DB check: `context_id` | 10 |
| 5 | DB check: `used_at` | '2026-07-15 10:00:00' |
| 6 | DB check: `is_active` | 0 |
| 7 | DB check: `created_at` | Auto-set |

---

#### TC-P03: id — Auto-increment PK

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1 | Prerequisites exist |
| 2 | Insert Log L1 without specifying id | L1.id = 1 (auto-assigned) |
| 3 | Insert Log L2 without specifying id | L2.id = 2 (sequential, not L1.id) |
| 4 | Assert L1.id < L2.id | Sequential increment |

---

#### TC-P04: question_bank_id — FK cascade on question force delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1, Log L1 (question_bank_id = Q1.id) | All records exist |
| 2 | Force-delete Q1 (`Q1->forceDelete()`) | Q1 permanently removed |
| 3 | DB check: `qns_question_usage_log` with id = L1.id | L1 cascade-deleted (0 records) |

---

#### TC-P05: question_usage_type_id — FK cascade on usage type force delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1, Log L1 (question_usage_type_id = UT1.id) | All records exist |
| 2 | Force-delete UT1 (`UT1->forceDelete()`) | UT1 permanently removed |
| 3 | DB check: `qns_question_usage_log` with id = L1.id | L1 cascade-deleted (0 records) |

---

#### TC-P06: context_id — Required (NOT NULL)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1 | Prerequisites exist |
| 2 | Attempt INSERT without `context_id` — raw DB insert with `context_id = NULL` | Integrity constraint violation thrown by DB |

---

#### TC-P07: used_at — Defaults to CURRENT_TIMESTAMP

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1 | Prerequisites exist |
| 2 | Insert Log without specifying `used_at` | `used_at` auto-set to CURRENT_TIMESTAMP |
| 3 | Assert `used_at` is not null | Default applied |

---

#### TC-P08: is_active — Defaults to true (1)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1 | Prerequisites exist |
| 2 | Insert Log without specifying `is_active` | `is_active` = 1 (true) |
| 3 | Assert `$log->is_active` = true | Default applied |

---

### 10.2 Soft Deletes

#### TC-P09: SoftDeletes — Soft delete sets deleted_at

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1, Log L1 | L1 exists |
| 2 | Soft-delete L1 (`L1->delete()`) | `deleted_at` set to current timestamp |
| 3 | DB check: `deleted_at` on L1 | NOT NULL |
| 4 | DB check: default query excludes L1 | `QuestionUsageLog::count()` excludes trashed |

---

#### TC-P10: SoftDeletes — Restore clears deleted_at

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete L1 | `L1.deleted_at` set |
| 2 | Restore L1 (`L1->restore()`) | Restored |
| 3 | DB check: `deleted_at` on L1 | NULL |
| 4 | DB check: default query includes L1 | L1 visible |

---

#### TC-P11: SoftDeletes — Force delete removes record permanently

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete L1 | L1 in trash |
| 2 | Force-delete L1 (`L1->forceDelete()`) | L1 permanently removed |
| 3 | DB check: `withTrashed()` on L1 | 0 records (gone permanently) |

---

### 10.3 Model Configuration

#### TC-P12: Model — Table name returns `qns_question_usage_log`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Instantiate `new QuestionUsageLog()` | Instance created |
| 2 | Call `$log->getTable()` | Returns `'qns_question_usage_log'` |
| 3 | Check `$log->getKeyName()` | Returns `'id'` |

---

#### TC-P13: Model — is_active boolean cast

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert Log with `is_active = 1` (as integer) | Saved |
| 2 | Access `$log->is_active` | Returns `true` (boolean, not int) |
| 3 | Insert Log with `is_active = 0` | Saved |
| 4 | Access `$log->is_active` | Returns `false` (boolean) |

---

#### TC-P14: Model — used_at datetime cast

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert Log with `used_at = '2026-07-15 10:00:00'` | Saved |
| 2 | Access `$log->used_at` | Returns Carbon instance |
| 3 | Assert `$log->used_at instanceof Carbon` | True |
| 4 | Assert `$log->used_at->format('Y-m-d')` | `'2026-07-15'` |

---

### 10.4 Model Relationships

#### TC-P15: Model — question() BelongsTo relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1, Log L1 (question_bank_id = Q1.id) | L1 exists |
| 2 | Access `L1->question` | Returns instance of `QuestionBank` |
| 3 | Assert `L1->question->id` = Q1.id | Correct question loaded |
| 4 | Assert relationship type is `BelongsTo` | `$log->question() instanceof BelongsTo` |

---

#### TC-P16: Model — usageType() BelongsTo relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create UT1, Q1, Log L1 (question_usage_type_id = UT1.id) | L1 exists |
| 2 | Access `L1->usageType` | Returns instance of `QuestionUsageType` |
| 3 | Assert `L1->usageType->id` = UT1.id | Correct usage type loaded |
| 4 | Assert relationship type is `BelongsTo` | `$log->usageType() instanceof BelongsTo` |

---

### 10.5 Model Scopes

#### TC-P17: Model — scopeActive() filters by is_active = true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Log L1 (is_active = 1), Log L2 (is_active = 0) | Both exist |
| 2 | Query: `QuestionUsageLog::active()->get()` | Only L1 returned |
| 3 | Assert L2 is excluded from results | Scope filters correctly |

---

#### TC-P18: Model — scopeContext() filters by question_usage_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create UT1, UT2, Q1 | Types exist |
| 2 | Create L1 (question_usage_type_id = UT1.id), L2 (question_usage_type_id = UT2.id) | Both logs exist |
| 3 | Query: `QuestionUsageLog::context(UT1.id)->get()` | Only L1 returned |
| 4 | Assert L2 is excluded | Scope filters by usage type |

---

#### TC-P19: Model — scopeForContextId() filters by context_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create L1 (context_id = 10), L2 (context_id = 20) | Both exist |
| 2 | Query: `QuestionUsageLog::forContextId(10)->get()` | Only L1 returned |
| 3 | Assert L2 is excluded | Scope filters by context ID |

---

### 10.6 Model Static Methods

#### TC-P20: Model — resolveUsageTypeId('QUIZ') returns correct ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create UT1 with code = 'QUIZ' | UT1 exists with id = X |
| 2 | Call `QuestionUsageLog::resolveUsageTypeId('QUIZ')` | Returns X (UT1.id) |
| 3 | Call `QuestionUsageLog::resolveUsageTypeId('NONEXISTENT')` | Returns null |

---

### 10.7 Business Logic

#### TC-P21: Business — Same question logged for multiple contexts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1 | Prerequisites exist |
| 2 | Create L1 (question_bank_id = Q1.id, context_id = 10), L2 (question_bank_id = Q1.id, context_id = 20), L3 (question_bank_id = Q1.id, context_id = 30) | 3 logs for same question |
| 3 | Assert all 3 exist and are distinct | No unique constraint violation |
| 4 | Assert L1.context_id ≠ L2.context_id ≠ L3.context_id | Different contexts stored |

---

#### TC-P22: Business — Toggle status via POST flips is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1, Log L1 (is_active = 1) | L1 active |
| 2 | POST to `/question-usage-log/{L1.id}/toggle-status` | Request successful |
| 3 | DB check: `L1.is_active` | 0 (flipped to inactive) |
| 4 | POST to `/question-usage-log/{L1.id}/toggle-status` again | Request successful |
| 5 | DB check: `L1.is_active` | 1 (flipped back to active) |

---

#### TC-P23: Business — Toggle status returns JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1, Log L1 (is_active = 1) | L1 active |
| 2 | POST to `/question-usage-log/{L1.id}/toggle-status` | 200 OK |
| 3 | Verify response JSON contains `success` key | `true` |
| 4 | Verify response JSON contains `is_active` key | `false` (toggled) |
| 5 | Verify response JSON contains `message` key | Message string present |

---

### 10.8 Tab Listing & Filtering

#### TC-P24: Business — Tab lists usage logs with pagination (10 per page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 15+ usage logs | 15+ logs exist |
| 2 | Load Question Bank index with `tab=question_usag_log` | Tab loads |
| 3 | Verify 10 logs shown on page 1 | Pagination = 10 per page |
| 4 | Navigate to page 2 (`usage_logs_page=2`) | Remaining 5 logs shown |
| 5 | Verify pagination controls rendered | Pagination links present |

---

#### TC-P25: Business — Filter by usage_context (question_usage_type_id)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create UT1, UT2, UT3 | Types exist |
| 2 | Create L1 (question_usage_type_id = UT1.id), L2 (question_usage_type_id = UT2.id), L3 (question_usage_type_id = UT3.id) | Logs for different types |
| 3 | Load tab with `usage_context=UT1.id` filter | Only L1 shown |
| 4 | Load tab with `usage_context=UT2.id` | Only L2 shown |
| 5 | Load tab without filter | All 3 logs shown |

---

#### TC-P26: Business — Filter by is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create L1 (is_active = 1), L2 (is_active = 0), L3 (is_active = 1) | Mixed active states |
| 2 | Load tab with `is_active=1` | Only L1, L3 shown (active) |
| 3 | Load tab with `is_active=0` | Only L2 shown (inactive) |
| 4 | Load tab without filter | All 3 logs shown |

---

#### TC-P27: Business — Logs ordered by used_at DESC

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create L1 (used_at = '2026-07-10'), L2 (used_at = '2026-07-20'), L3 (used_at = '2026-07-15') | 3 logs with different dates |
| 2 | Load usage log tab | Logs ordered by `used_at DESC` |
| 3 | Verify first log is L2 (2026-07-20) | Most recent first |
| 4 | Verify last log is L1 (2026-07-10) | Oldest last |

---

#### TC-P28: Business — Soft delete log preserves parent question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1, Log L1 (question_bank_id = Q1.id) | All exist |
| 2 | Soft-delete L1 (`L1->delete()`) | L1.deleted_at set |
| 3 | DB check: `qns_questions_bank` where id = Q1.id | Q1 still exists (not cascade-deleted) |
| 4 | Restore L1 | L1 restored |
| 5 | Assert question relationship still works | `L1->question` returns Q1 |

---

## 11. Negative TC Steps

### 11.1 DB Constraint Violations

#### TC-N01: question_bank_id missing (NULL) — DB constraint violation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create UT1 | Prerequisite exists |
| 2 | Attempt raw DB INSERT without `question_bank_id` | Integrity constraint violation: Column 'question_bank_id' cannot be null |
| 3 | Verify no partial record created | Table unchanged |

---

#### TC-N02: question_usage_type_id missing (NULL) — DB constraint violation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1 | Prerequisite exists |
| 2 | Attempt raw DB INSERT without `question_usage_type_id` | Integrity constraint violation: Column 'question_usage_type_id' cannot be null |
| 3 | Verify no partial record created | Table unchanged |

---

#### TC-N03: context_id missing (NULL) — DB constraint violation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1 | Prerequisites exist |
| 2 | Attempt raw DB INSERT without `context_id` | Integrity constraint violation: Column 'context_id' cannot be null |
| 3 | Verify no partial record created | Table unchanged |

---

#### TC-N04: Invalid question_bank_id — FK constraint violation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create UT1 | Prerequisite exists |
| 2 | Attempt INSERT with `question_bank_id = 99999` (does not exist) | FK constraint violation: `fk_qusage_question` fails |
| 3 | Verify no record created | Table unchanged |

---

#### TC-N05: Invalid question_usage_type_id — FK constraint violation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1 | Prerequisite exists |
| 2 | Attempt INSERT with `question_usage_type_id = 99999` (does not exist) | FK constraint violation: `fk_qusage_usage_type` fails |
| 3 | Verify no record created | Table unchanged |

---

### 11.2 Authorization & Permissions

#### TC-N06: Toggle status — Without tenant.question-bank.update permission → 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-bank.update` permission | Authenticated |
| 2 | Create Q1, UT1, Log L1 (is_active = 1) | L1 exists |
| 3 | POST to `/question-usage-log/{L1.id}/toggle-status` | 403 Forbidden |
| 4 | DB check: `L1.is_active` | Still 1 (unchanged) |

---

#### TC-N07: View tab — Tab hidden when user lacks tenant.question-usage-log.viewAny (no 403 — controller only checks tenant.question-bank.viewAny)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-usage-log.viewAny` but WITH `tenant.question-bank.viewAny` | Authenticated |
| 2 | Load Question Bank index with `tab=question_usag_log` | Page loads (controller gate passes) |
| 3 | Verify usage log tab is NOT rendered in tab navigation | Tab excluded via Blade `@can` |

---

#### TC-N08: Toggle status — Non-existent log ID → 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no log exists with id = 99999 | Confirmed |
| 2 | POST to `/question-usage-log/99999/toggle-status` | 404 Not Found |

---

#### TC-N09: Tab access — Usage logs tab hidden when user lacks viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-usage-log.viewAny` but WITH `tenant.question-bank.viewAny` | Authenticated |
| 2 | Load Question Bank index page | Page loads without error |
| 3 | Verify `question_usag_log` tab is NOT visible in tab navigation | Tab excluded via Blade `@can` |

---

#### TC-N10: GET method on toggle-status (should be POST only)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1, Log L1 | L1 exists |
| 2 | Send GET request to `/question-usage-log/{L1.id}/toggle-status` | 405 Method Not Allowed or 404 |
| 3 | DB check: `L1.is_active` | Unchanged |

---

## 12. Dependency TC Steps

### 12.1 FK Cascade

#### TC-D01: Cascade — Force delete question cascades to usage logs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1, Log L1 (question_bank_id = Q1.id), Log L2 (question_bank_id = Q1.id) | 2 logs for Q1 |
| 2 | Force-delete Q1 (`Q1->forceDelete()`) | Q1 permanently removed |
| 3 | DB check: `qns_question_usage_log` with question_bank_id = Q1.id | 0 records (both cascade-deleted) |
| 4 | DB check: L1 and L2 with trashed | Gone permanently |

---

#### TC-D02: Cascade — Force delete usage type cascades to usage logs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1, Log L1 (question_usage_type_id = UT1.id), Log L2 (question_usage_type_id = UT1.id) | 2 logs for UT1 |
| 2 | Force-delete UT1 (`UT1->forceDelete()`) | UT1 permanently removed |
| 3 | DB check: `qns_question_usage_log` with question_usage_type_id = UT1.id | 0 records (both cascade-deleted) |
| 4 | DB check: L1 and L2 with trashed | Gone permanently |

---

### 12.2 Cross-Module Integration

#### TC-D03: Integration — Quiz module auto-logs on question assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UsageType with code 'QUIZ' | Prerequisites exist |
| 2 | Assign Q1 to a Quiz via QuizQuestionController | Question assigned to quiz |
| 3 | DB check: `qns_question_usage_log` where `question_bank_id = Q1.id` | Record created |
| 4 | Verify `question_usage_type_id` matches QUIZ type | Correct usage type |
| 5 | Verify `context_id` stores the quiz pivot record ID | Context tracks the quiz |

---

#### TC-D04: Integration — Quest module auto-logs on question assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UsageType with code 'QUEST' | Prerequisites exist |
| 2 | Assign Q1 to a Quest via QuestQuestionController | Question assigned to quest |
| 3 | DB check: `qns_question_usage_log` where `question_bank_id = Q1.id` | Record created |
| 4 | Verify `question_usage_type_id` matches QUEST type | Correct usage type |
| 5 | Verify `context_id` stores the quest pivot record ID | Context tracks the quest |

---

#### TC-D05: Integration — Exam module (online) auto-logs on question assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UsageType with code 'ONLINE_EXAM' | Prerequisites exist |
| 2 | Assign Q1 to an online exam paper set via PaperSetQuestionController | Question assigned to exam |
| 3 | DB check: `qns_question_usage_log` where `question_bank_id = Q1.id` | Record created |
| 4 | Verify `question_usage_type_id` matches ONLINE_EXAM type | Correct usage type |
| 5 | Verify `context_id` stores the exam paper set record ID | Context tracks the exam |

---

#### TC-D06: Integration — Exam module (offline) auto-logs on question assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UsageType with code 'OFFLINE_EXAM' | Prerequisites exist |
| 2 | Assign Q1 to an offline exam paper set via PaperSetQuestionController | Question assigned to exam |
| 3 | DB check: `qns_question_usage_log` where `question_bank_id = Q1.id` | Record created |
| 4 | Verify `question_usage_type_id` matches OFFLINE_EXAM type | Correct usage type |
| 5 | Verify `context_id` stores the offline exam paper set ID | Context tracks the exam |

---

### 12.3 Referential Integrity

#### TC-D07: Integrity — Orphan logs cannot exist without parent question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1, Log L1 (question_bank_id = Q1.id) | All exist |
| 2 | Force-delete Q1 | L1 cascade-deleted (FK CASCADE) |
| 3 | Verify no orphan record exists in `qns_question_usage_log` with question_bank_id = Q1.id | 0 records |
| 4 | Attempt to manually INSERT with invalid question_bank_id | FK violation (fk_qusage_question) |

---

#### TC-D08: Integrity — Soft delete preserves referential integrity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Q1, UT1, Log L1 (question_bank_id = Q1.id, question_usage_type_id = UT1.id) | All exist |
| 2 | Soft-delete L1 (`L1->delete()`) | L1.deleted_at set |
| 3 | DB check: `qns_questions_bank` where id = Q1.id | Q1 still exists (no cascade on soft delete) |
| 4 | DB check: `qns_question_usage_type` where id = UT1.id | UT1 still exists |
| 5 | Restore L1 | L1 restored |
| 6 | Assert L1->question->id = Q1.id | FK integrity preserved |

---

## 13. Code Review TC Steps

### 13.1 Model

#### TC-CR01: Model — SoftDeletes + fillable + casts configuration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Modules\QuestionBank\Models\QuestionUsageLog` | Class definition |
| 2 | Verify `use SoftDeletes;` trait imported | Trait present |
| 3 | Verify `$fillable = ['question_bank_id', 'question_usage_type_id', 'context_id', 'used_at', 'is_active']` | Correct fillable fields |
| 4 | Verify `$casts = ['used_at' => 'datetime', 'is_active' => 'boolean']` | Correct casts |
| 5 | Verify `$table = 'qns_question_usage_log'` | Correct table name |
| 6 | Verify `$primaryKey = 'id'` | Standard PK |

---

#### TC-CR02: Model — question() BelongsTo relationship definition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `question()` method in `QuestionUsageLog` | Relationship definition |
| 2 | Verify return type: `$this->belongsTo(QuestionBank::class)` | Correct model |
| 3 | Verify foreign key: `question_bank_id` | Correct FK |
| 4 | Verify `withTrashed()` not invoked on parent | Eager loading not needed |

---

#### TC-CR03: Model — usageType() BelongsTo relationship definition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `usageType()` method in `QuestionUsageLog` | Relationship definition |
| 2 | Verify return type: `$this->belongsTo(QuestionUsageType::class)` | Correct model |
| 3 | Verify foreign key: `question_usage_type_id` | Correct FK |

---

#### TC-CR04: Model — scopeActive() query implementation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `scopeActive()` in model | Scope definition |
| 2 | Verify: `$query->where('is_active', true)` | Filters active records |
| 3 | Verify scope is chainable | Returns `$query` |

---

#### TC-CR05: Model — scopeContext() query implementation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `scopeContext()` in model | Scope definition |
| 2 | Verify: `$query->where('question_usage_type_id', $typeId)` | Filters by usage type |
| 3 | Verify parameter type: `int $typeId` | Typed parameter |

---

#### TC-CR06: Model — scopeForContextId() query implementation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `scopeForContextId()` in model | Scope definition |
| 2 | Verify: `$query->where('context_id', $contextId)` | Filters by context |
| 3 | Verify parameter type: `int $contextId` | Typed parameter |

---

#### TC-CR07: Model — resolveUsageTypeId() static method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `resolveUsageTypeId()` in model | Static method |
| 2 | Verify: queries `QuestionUsageType::where('code', $code)->value('id')` | Resolves code to ID |
| 3 | Verify returns `?int` or nullable | Returns null if not found |

---

### 13.2 Policy

#### TC-CR08: Policy — QuestionUsageLogPolicy gates (9 gates)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Modules\QuestionBank\Policies\QuestionUsageLogPolicy` | 9 gate methods |
| 2 | Verify `viewAny`: `tenant.question-usage-log.viewAny` | List permission |
| 3 | Verify `view`: `tenant.question-usage-log.view` | View permission |
| 4 | Verify `create`: `tenant.question-usage-log.create` | Create permission |
| 5 | Verify `update`: `tenant.question-usage-log.update` | Update permission |
| 6 | Verify `delete`: `tenant.question-usage-log.delete` | Soft delete permission |
| 7 | Verify `restore`: `tenant.question-usage-log.restore` | Restore permission |
| 8 | Verify `forceDelete`: `tenant.question-usage-log.forceDelete` | Force delete permission |
| 9 | Verify `status`: `tenant.question-usage-log.status` | Status toggle permission (global, no model param) |
| 10 | Verify `print`: `tenant.question-usage-log.print` | Print/export permission |
| 11 | Verify policy registered in `AuthServiceProvider` | Policy bound to model |

---

### 13.3 Controller

#### TC-CR09: Controller — toggleStatusLog() toggle logic in QuestionBankController

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestionBankController@toggleStatusLog` | Method body |
| 2 | Verify model retrieval: `QuestionUsageLog::findOrFail($id)` | 404 if not found |
| 3 | Verify toggle logic: `$log->is_active = !$log->is_active` | Boolean inversion |
| 4 | Verify save: `$log->save()` | Persisted |
| 5 | Verify JSON response returned | Not a view redirect |

---

#### TC-CR10: Controller — toggleStatusLog() gate authorization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review gate call in `toggleStatusLog()` | Authorization check |
| 2 | Verify `Gate::authorize('tenant.question-bank.update')` | Uses `question-bank.update` (not `question-usage-log.status`) |
| 3 | Verify gate check occurs BEFORE toggle logic | Authorization enforced first |

---

### 13.4 Service

#### TC-CR11: Service — QuestionLookupService@getQuestionUsageLogsQuery implementation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Modules\QuestionBank\Services\QuestionLookupService@getQuestionUsageLogsQuery` | Method body |
| 2 | Verify base query: `QuestionUsageLog::with(['question', 'usageType'])` | Eager loads relationships |
| 3 | Verify ordering: `orderBy('used_at', 'desc')` | Most recent first |
| 4 | Verify `usage_context` filter: `if ($request->filled('usage_context')) $query->context($request->usage_context)` | Conditional filter via model scope |
| 5 | Verify `is_active` filter: `if ($request->filled('is_active')) $query->where('is_active', $request->is_active)` | Conditional filter |
| 6 | Verify pagination: `paginate(10, ['*'], 'usage_logs_page')` | 10 per page with custom page param |

---

### 13.5 Tab Integration

#### TC-CR12: Controller — Tab integration in QuestionBankController@index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestionBankController@index` for tab configuration | Tab setup |
| 2 | Verify `question_usag_log` tab defined in tab configuration | Tab exists |
| 3 | Verify tab permission: `tenant.question-usage-log.viewAny` | Permission-gated tab |
| 4 | Verify tab data sourced from `getQuestionUsageLogsQuery` | Data loaded via service |
| 5 | Verify tab content blade includes usage log listing view | View rendered |

---

### 13.6 Activity Logging

#### TC-CR13: Controller — Activity logging on status toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `toggleStatusLog()` after save | Activity log call |
| 2 | Verify `activityLog($log, 'Toggled', ...)` with `message` and `performed_by` | 'Toggled' event logged with basic info (NO old/new is_active) |

---

### 13.7 Blade Views

#### TC-CR14: Blade — @can directives for permission-based tab + toggle visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review tab blade for `@can('tenant.question-usage-log.viewAny')` | Tab header rendered conditionally |
| 2 | Review usage log content blade for status toggle button | Toggle button wrapped in @can |
| 3 | Verify toggle button uses `@can('tenant.question-bank.update')` | Matches controller gate |
| 4 | Verify user WITHOUT viewAny permission sees no tab | Tab hidden |
| 5 | Verify user WITHOUT update permission sees no toggle button | Toggle hidden |

---

### 13.8 Response Format

#### TC-CR15: Controller — toggleStatusLog() JSON response format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review response construction in `toggleStatusLog()` | Response structure |
| 2 | Verify `success` key: `true` | Always true on success |
| 3 | Verify `is_active` key: `$log->is_active` | New state returned |
| 4 | Verify `message` key | Human-readable message |
| 5 | Verify response code: 200 OK | Success HTTP status |

---

## 14. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/question-bank/question-bank` (index, tab: `question_usag_log`) | question-bank.question-bank.index | `QuestionBankController@index` (tab rendering) | `tenant.question-usage-log.viewAny` |
| POST | `/question-bank/question-usage-log/{question_bank}/toggle-status` | question-bank.question-usage-log.toggleStatus | `QuestionBankController@toggleStatusLog` | `tenant.question-bank.update` |
| *(No resource routes — usage log has no direct CRUD routes; creation is system-only via Quiz/Quest/Exam modules)* |

---

## 15. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | No dedicated CRUD controller for usage log | **Medium** | All operations go through `QuestionBankController` or consuming modules (Quiz, Quest, Exam). No separation of concerns. By design. |
| KI-02 | `toggleStatusLog` uses `tenant.question-bank.update` instead of `tenant.question-usage-log.status` | **Medium** | Permission mismatch: the toggle endpoint authorizes with `question-bank.update` perms but the policy has a dedicated `question-usage-log.status` gate. Could allow unintended access. |
| KI-03 | No Request/validation class for toggle input | **Low** | `toggleStatusLog()` directly inverts `$log->is_active` without any FormRequest or input validation. Relies on model boolean cast. |
| KI-04 | No manual create/edit/delete UI for admins | **Low** | Admins cannot manually correct or manage usage logs. All operations are system-only via Quiz/Quest/Exam modules. By design. |
| KI-05 | `scopeActive` / `scopeContext` / `scopeForContextId` may conflict when chained | **Low** | Combined usage of multiple scopes (`active()->context(...)`) has no unit tests; relies on query builder chaining correctness. |
| KI-06 | Cascade delete on usage type deletion may cause data loss | **Medium** | FK `fk_qusage_usage_type` ON DELETE CASCADE means deleting a usage type permanently removes all associated logs. No warning or soft-delete check. |
| KI-07 | `usage_context` filter broken — blade sends codes, service expects IDs | **High** | Blade `question-usag-log/index.blade.php` sends codes (`QUIZ`, `QUEST`, etc.) as `usage_context` values, but `QuestionLookupService::getQuestionUsageLogsQuery()` passes them to `scopeContext()` which compares against integer `question_usage_type_id` FK column. MySQL casts codes to 0, so no rows ever match. |
| KI-08 | `scopeContext()` docblock says "Code" but compares against FK ID column | **Low** | `QuestionUsageLog::scopeContext()` docblock says `Filter by usage context (Code)` but implementation does `where('question_usage_type_id', $context)` — compares against integer FK column, not code string. |
| KI-09 | Route param `{question_bank}` is misleading for usage log toggle | **Low** | `web.php` line 37 defines `{question_bank}` as the route parameter, but `toggleStatusLog($id)` treats it as a `QuestionUsageLog` ID (not `QuestionBank` ID). Works because no route-model binding exists, but confusing. |

---

## 16. Execution Status

| TC ID | Test Case Name | Status (Pass/Fail/Blocked/Skip) | Tested By | Test Date | Bug ID | Notes |
|-------|---------------|--------------------------------|-----------|-----------|--------|-------|
| TC-P01 | Record Creation — Minimal | | | | | |
| TC-P02 | Record Creation — All fields | | | | | |
| TC-P03 | id — Auto-increment PK | | | | | |
| TC-P04 | question_bank_id — FK cascade | | | | | |
| TC-P05 | question_usage_type_id — FK cascade | | | | | |
| TC-P06 | context_id — Required (NOT NULL) | | | | | |
| TC-P07 | used_at — Default CURRENT_TIMESTAMP | | | | | |
| TC-P08 | is_active — Default true | | | | | |
| TC-P09 | SoftDeletes — Soft delete | | | | | |
| TC-P10 | SoftDeletes — Restore | | | | | |
| TC-P11 | SoftDeletes — Force delete | | | | | |
| TC-P12 | Model — Table name | | | | | |
| TC-P13 | Model — is_active boolean cast | | | | | |
| TC-P14 | Model — used_at datetime cast | | | | | |
| TC-P15 | Model — question() BelongsTo | | | | | |
| TC-P16 | Model — usageType() BelongsTo | | | | | |
| TC-P17 | Model — scopeActive() | | | | | |
| TC-P18 | Model — scopeContext() | | | | | |
| TC-P19 | Model — scopeForContextId() | | | | | |
| TC-P20 | Model — resolveUsageTypeId() | | | | | |
| TC-P21 | Same question multiple contexts | | | | | |
| TC-P22 | Toggle status POST | | | | | |
| TC-P23 | Toggle status JSON response | | | | | |
| TC-P24 | Tab pagination (10 per page) | | | | | |
| TC-P25 | Filter by usage_context | | | | | |
| TC-P26 | Filter by is_active | | | | | |
| TC-P27 | Ordered by used_at DESC | | | | | |
| TC-P28 | Soft delete preserves question | | | | | |
| TC-N01 | question_bank_id NULL | | | | | |
| TC-N02 | question_usage_type_id NULL | | | | | |
| TC-N03 | context_id NULL | | | | | |
| TC-N04 | Invalid question_bank_id FK | | | | | |
| TC-N05 | Invalid question_usage_type_id FK | | | | | |
| TC-N06 | Toggle without permission | | | | | |
| TC-N07 | View tab without permission | | | | | |
| TC-N08 | Toggle non-existent ID | | | | | |
| TC-N09 | Tab hidden without viewAny | | | | | |
| TC-N10 | GET instead of POST on toggle | | | | | |
| TC-D01 | Cascade — Question force delete | | | | | |
| TC-D02 | Cascade — Usage type force delete | | | | | |
| TC-D03 | Quiz module auto-log | | | | | |
| TC-D04 | Quest module auto-log | | | | | |
| TC-D05 | Exam (online) auto-log | | | | | |
| TC-D06 | Exam (offline) auto-log | | | | | |
| TC-D07 | No orphan logs | | | | | |
| TC-D08 | Soft delete preserves integrity | | | | | |
| TC-CR01 | Model configuration | | | | | |
| TC-CR02 | question() relationship | | | | | |
| TC-CR03 | usageType() relationship | | | | | |
| TC-CR04 | scopeActive() code | | | | | |
| TC-CR05 | scopeContext() code | | | | | |
| TC-CR06 | scopeForContextId() code | | | | | |
| TC-CR07 | resolveUsageTypeId() code | | | | | |
| TC-CR08 | Policy gates (9 gates) | | | | | |
| TC-CR09 | toggleStatusLog() logic | | | | | |
| TC-CR10 | toggleStatusLog() gate | | | | | |
| TC-CR11 | getQuestionUsageLogsQuery service | | | | | |
| TC-CR12 | Tab integration | | | | | |
| TC-CR13 | Activity logging on toggle | | | | | |
| TC-CR14 | Blade @can directives | | | | | |
| TC-CR15 | JSON response format | | | | | |

---

## 17. Feature Summary Matrix

| Feature Area | Positive TCs | Negative TCs | Dependency TCs | Code Review TCs | Total |
|-------------|-------------|-------------|---------------|----------------|-------|
| DB Schema / Record Creation | 7 | 4 | 0 | 0 | 11 |
| Soft Deletes | 3 | 0 | 0 | 1 | 4 |
| Model Configuration | 3 | 0 | 0 | 1 | 4 |
| Model Relationships | 2 | 0 | 0 | 2 | 4 |
| Model Scopes | 3 | 0 | 0 | 3 | 6 |
| Model Static Methods | 1 | 0 | 0 | 1 | 2 |
| Business Logic | 6 | 0 | 0 | 0 | 6 |
| Tab Listing & Filtering | 3 | 0 | 0 | 2 | 5 |
| Authorization / Permissions | 0 | 4 | 0 | 2 | 6 |
| Status Toggle | 0 | 1 | 0 | 2 | 3 |
| Route / Method Check | 0 | 1 | 0 | 0 | 1 |
| FK Cascade | 0 | 0 | 2 | 0 | 2 |
| Cross-Module Integration | 0 | 0 | 4 | 0 | 4 |
| Referential Integrity | 0 | 0 | 2 | 0 | 2 |
| Blade Views | 0 | 0 | 0 | 1 | 1 |
| **Total** | **28** | **10** | **8** | **15** | **61** |

---

## 18. TC Count Summary

| Category | Count |
|----------|-------|
| Positive (TC-P) | 28 |
| Negative (TC-N) | 10 |
| Dependency (TC-D) | 8 |
| Code Review (TC-CR) | 15 |
| **Total** | **61** |

---

*Document Version: 1.0 — Last Updated: 2026-07-19*
*TC List covers: Question Usage Log database schema, model scopes & relationships, soft deletes, status toggle, tab listing & filtering, cross-module auto-logging (Quiz/Quest/Exam), FK cascade integrity, and related code paths. Total TC count: 61 (28 Positive + 10 Negative + 8 Dependency + 15 Code Review). Sections: 18 (BC-DB, BC-VAL, BC-AUTH, BC-BIZ, BC-REF, Test Case Summary, Positive/Negative/Dependency/CR Steps, Route Reference, Known Issues, Execution Status, Feature Summary Matrix, TC Count Summary).*
