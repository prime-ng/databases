# qns_QuestionBank_Statistics_TcList

## Module: QuestionBank → Question Statistics Management

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | QuestionBank (QNS) |
| Tab Group | Question Bank (Tabbed Interface) |
| Features | Question Statistics Display (via tab module), Sync — **NO manual CRUD** (statistics are system-computed) |
| URL(s) | `/question-bank/question-statistic/{id}`, `/question-bank/question-statistic/{question_statistic}/toggle-status`, `/question-bank/question-statistic/sync` |
| Controller | `Modules\QuestionBank\Http\Controllers\QuestionStatisticController` |
| Model(s) | `QuestionStatistic` (`Modules\QuestionBank\Models\QuestionStatistic`) — `SoftDeletes` trait |
| Validation | `QuestionStatisticRequest` (exists but not used in normal flow) |
| Permission Gates (Display) | `tenant.question_bank.view` (show), `tenant.question_bank.update` (toggleStatus, sync) |
| Soft Deletes | Yes (system-managed via FK cascade from question) |
| Events | activityLog() on store, update, destroy, restore, forceDelete |

---

## 2. Pre-conditions

- Required permissions (display only): `tenant.question_bank.viewAny` (index), `tenant.question_bank.view` (show), `tenant.question_bank.update` (toggleStatus, recalculate, sync)
- At least one question must exist in `qns_questions_bank` table with a corresponding statistic record
- For recalculate/sync tests: Sufficient answer data must exist in quiz/quest/exam attempt tables
- For guessing factor tests: Questions must be MCQ type (multiple choice)
- Statistics records are auto-created by FK cascade from `qns_questions_bank` — no manual creation needed

---

---

## 4. BC-DB — Database Schema

**Note:** Statistics records are auto-created/managed by FK cascade. Manual CRUD routes exist in controller but are dead/unused — this module is display-only.

### 4.1 `qns_question_statistics` — Question Statistics Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| question_bank_id | INT UNSIGNED | NOT NULL | — | FK → qns_questions_bank.id, UNIQUE |
| difficulty_index | DECIMAL(5,2) | YES | NULL | 0.00 – 100.00 |
| discrimination_index | DECIMAL(5,2) | YES | NULL | -1.00 – 1.00 |
| guessing_factor | DECIMAL(5,2) | YES | NULL | 0.00 – 1.00 |
| min_time_taken_seconds | INT UNSIGNED | YES | NULL | Minimum answer time |
| max_time_taken_seconds | INT UNSIGNED | YES | NULL | Maximum answer time |
| avg_time_taken_seconds | INT UNSIGNED | YES | NULL | Average answer time |
| total_attempts | INT UNSIGNED | YES | 0 | Total student attempts |
| last_computed_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Last computation timestamp |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_qstat_question_bank` (`question_bank_id`)

---

## 5. BC-VAL — Validation Rules

**Note:** `QuestionStatisticRequest` exists for the dead CRUD routes (create/update). In the intended display-only flow, no manual data entry occurs — statistics are computed by the backend service. The form request validation is not exercised in normal operation.

---

## 6. BC-AUTH — Authorization

| Permission Gate (Code) | Controller Method(s) | Purpose |
|-----------------------|---------------------|---------|
| tenant.question_bank.view | show() | View single statistic record |
| tenant.question_bank.update | toggleStatus(), sync() | Status toggle / sync |

**Orphaned CRUD gates (routes exist via Route::resource but module is display-only — no UI entry points):**
| tenant.question_bank.viewAny | index() | **abort(404)** — unreachable |
| tenant.question_bank.create | create(), store() | Not used in normal flow |
| tenant.question_bank.update | edit(), update() | Not used in normal flow |
| tenant.question_bank.delete | destroy() | Not used in normal flow |
| tenant.question_bank.restore | trashed(), restore() | Not used in normal flow |
| tenant.question_bank.forceDelete | forceDelete() | Not used in normal flow |

**Critical: Permission namespace mismatch (underscore vs hyphen)**
- Controller `Gate::authorize()` calls use `tenant.question_bank.*` (underscore)
- `QuestionStatisticPolicy` methods use `tenant.question-statistic.*` (hyphen) — Policy never invoked
- Blade `@can` directives use `tenant.question-statistic.*` (hyphen)

**Blade @can directives used in views:**
- `@can('tenant.question-statistic.view')` — Active column and status toggle

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | **Display-Only Module** | Statistics records are auto-created by FK cascade from `qns_questions_bank`. **No manual CRUD** — create/edit/delete/restore/forceDelete routes exist but are unused |
| BC-BIZ-02 | One Record Per Question | Unique constraint on `question_bank_id` ensures exactly one statistic record per question |
| BC-BIZ-03 | Compute on Demand | Statistics are computed via backend service; controller has `sync()` (dispatches background job) |
| BC-BIZ-04 | Minimum Data Threshold | Statistics computation requires minimum number of answer attempts before generating meaningful indices |
| BC-BIZ-05 | MCQ-Specific Guessing | Guessing factor is only relevant for MCQ-type questions; non-MCQ types may have NULL guessing_factor |
| BC-BIZ-06 | Performance Category Sync | Computed statistics may trigger performance category recommendation updates (difficulty-based) |
| BC-BIZ-07 | Difficulty Badge Colors | <30 success (green), <70 warning (orange/yellow), >=70 danger (red) in UI |
| BC-BIZ-08 | last_computed_at Auto-set | Automatically set to CURRENT_TIMESTAMP on record creation |
| BC-BIZ-09 | sync() dispatches background job | `sync()` method dispatches `SyncQuestionStatistics` job to queue for async recalculation |
| BC-BIZ-10 | No Scheduled Recalculation | No cron/scheduled job exists to periodically recompute statistics; data becomes stale |
| BC-BIZ-11 | Activity Log on CRUD Operations | activityLog() called on store (Stored), update (Updated), destroy (Trashed), restore (Restored), forceDelete (Deleted) — tracks performed_by for each action |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_qstat_question_bank | question_bank_id | qns_questions_bank.id | CASCADE |

When a question is deleted from `qns_questions_bank`, its statistic record is automatically cascade-deleted.

---

## 9. Test Case Summary

### 9.1 Question Statistics — Positive TCs (Display/Filter/Calculation)

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-QST-P01 | Statistics View | Positive | View single statistic record details | 4 |
| TC-QST-P02 | Statistics Toggle | Positive | Toggle statistic active status via AJAX | 4 |
| TC-QST-P03 | Statistics Store | Positive | Activity log created on statistic store | 3 |
| TC-QST-P04 | Statistics Update | Positive | Activity log created on statistic update | 3 |
| TC-QST-P05 | Statistics Soft Delete | Positive | Activity log created on statistic soft-delete | 2 |
| TC-QST-P06 | Statistics Restore | Positive | Activity log created on statistic restore | 2 |
| TC-QST-P07 | Statistics Force Delete | Positive | Activity log created on statistic force-delete | 2 |

### 9.2 Question Statistics — Negative TCs (Display/Filter/Calculation)

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-QST-N01 | Permission | Negative | Permission — toggle status without update gate | 2 |
| TC-QST-N02 | Toggle | Negative | Toggle — invalid ID (non-existent) | 2 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR01 | Code Review | Review | show() — Gate + findOrFail + with('questionBank') | 3 |
| TC-CR02 | Code Review | Review | toggleStatus() — JSON response | 3 |
| TC-CR03 | Code Review | Review | sync() — Dispatches SyncQuestionStatistics job to queue | 3 |
| TC-CR04 | Code Review | Review | Model — fillable, casts, relationships (SoftDeletes, questionBank) | 4 |
| TC-CR05 | Code Review | Review | Migration — DDL correctness vs computed nature | 4 |
| TC-CR06 | Code Review | Review | store() — activityLog call after create | 3 |
| TC-CR07 | Code Review | Review | update() — activityLog with changes diff | 3 |
| TC-CR08 | Code Review | Review | destroy() — activityLog with 'Trashed' event | 2 |
| TC-CR09 | Code Review | Review | restore() — activityLog with 'Restored' event | 2 |
| TC-CR10 | Code Review | Review | forceDelete() — activityLog with 'Deleted' event after force delete | 2 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D01 | Dependency | Dependency | FK cascade — deleting question removes statistic | 3 |
| TC-D02 | Dependency | Dependency | Sync — depends on answer data availability in attempt tables | 3 |
| TC-D03 | Dependency | Dependency | View references QuestionBank->question_content field (not question_text) | 3 |
| TC-D04 | Dependency | Dependency | Permission namespace mismatch (controller uses question_bank, blade uses question-statistic) | 3 |
| TC-D05 | Dependency | Dependency | Activity log entry created on all 5 CRUD operations | 5 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Question Statistics

#### TC-QST-P01: View single statistic record details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.question_bank.view` permission navigates to statistic show page | Show page loads |
| 2 | Verify all fields displayed: question text, difficulty, discrimination, guessing, time metrics, attempts, last_computed_at | All fields shown |
| 3 | Verify related question info displayed (from QuestionBank relationship) | Question info shown |
| 4 | Verify difficulty badge color matches value | Badge rendered |

#### TC-QST-P02: Toggle statistic active status via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.question_bank.update` permission sends toggle request | Toggle processed |
| 2 | Verify JSON response: `{success: true, is_active: false, message: "..."}` | Response correct |
| 3 | Verify DB: `is_active` flipped | Status changed |

#### TC-QST-P03: Activity log created on statistic store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new statistic via store() | Success |
| 2 | Verify `activityLog()` was called with the QuestionStatistic model, action='Stored', and message='Question Statistic created' | Logged |
| 3 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-QST-P04: Activity log created on statistic update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update a statistic via update() with changed fields | Success |
| 2 | Verify `activityLog()` called with action='Updated' and changes array containing before/after diff | Logged |
| 3 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-QST-P05: Activity log created on statistic soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a statistic via destroy() | Success |
| 2 | Verify `activityLog()` called with action='Trashed' and message='Question Statistic trashed' | Logged |

#### TC-QST-P06: Activity log created on statistic restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a trashed statistic via restore() | Success |
| 2 | Verify `activityLog()` called with action='Restored' and message='Question Statistic restored' | Logged |

#### TC-QST-P07: Activity log created on statistic force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a trashed statistic via forceDelete() | Success |
| 2 | Verify `activityLog()` called with action='Deleted' and message='Question Statistic permanently deleted' | Logged |

### 10.2 Negative TC Steps — Question Statistics

#### TC-QST-N01: Permission — toggle status without update gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.question_bank.update` sends toggle request | 403 Forbidden |

#### TC-QST-N02: Toggle — invalid ID (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST toggle request for ID=99999 | 404 Not Found |

### 10.3 Code Review TC Steps

#### TC-CR01: show() — Gate + findOrFail + with('questionBank')

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review Gate::authorize('tenant.question_bank.view') | Gate present |
| 2 | Review `QuestionStatistic::withTrashed()->with('questionBank')->findOrFail($id)` | Model resolved with trashed scope |
| 3 | Review view return: `view('questionbank::question-statistics.view')` | View correct |

#### TC-CR02: toggleStatus() — JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review Gate::authorize('tenant.question_bank.update') | Gate present |
| 2 | Review toggle logic: `$questionStatistic->is_active = !$questionStatistic->is_active; $questionStatistic->save()` | Status toggled |
| 3 | Review JSON response: `response()->json(['success' => true, 'is_active' => ...])` | JSON returned |

#### TC-CR03: sync() — Dispatches SyncQuestionStatistics job to queue

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review Gate::authorize('tenant.question_bank.update') | Gate present |
| 2 | Review `SyncQuestionStatistics::dispatch()` | Job dispatched to queue |
| 3 | Review redirect with success flash: "Statistics sync dispatched to queue" | Redirect correct |

#### TC-CR04: Model — fillable, casts, relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$fillable` array — all statistic columns listed | Fillable complete |
| 2 | Review `$casts` — decimal, boolean, datetime casts | Casts correct |
| 3 | Review `SoftDeletes` trait usage | Soft deletes enabled |
| 4 | Review `questionBank()` relationship — belongsTo QuestionBank | Relationship defined |

#### TC-CR05: Migration — DDL correctness

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `question_bank_id` column: unsignedInteger, NOT NULL, UNIQUE | Migration correct |
| 2 | Review decimal columns: `decimal(5,2)` nullable | Precision matches |
| 3 | Review time columns: `unsignedInteger` nullable | Type matches |
| 4 | Review `total_attempts`: `unsignedInteger` default 0 | Default matches |
| 5 | Review foreign key: `->references('id')->on('qns_questions_bank')->onDelete('cascade')` | FK cascade |

#### TC-CR06: store() — activityLog call after create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` method after `QuestionStatistic::create($request->validated())` | After DB insert |
| 2 | Review `activityLog($questionStatistic, 'Stored', ['message' => 'Question Statistic created', 'performed_by' => Auth::user()->name])` | Activity logged |
| 3 | Verify redirect with success flash | Flash message correct |

#### TC-CR07: update() — activityLog with changes diff

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `update()` method: capture original before update | `$original = $questionStatistic->getOriginal()` |
| 2 | Review `activityLog($questionStatistic, 'Updated', ['message' => 'Question Statistic updated', 'changes' => array_diff_assoc(...), 'performed_by' => Auth::user()->name])` | Changes diff logged |
| 3 | Verify `array_diff_assoc($questionStatistic->getAttributes(), $original)` correctly captures only changed fields | Changes accurately tracked |

#### TC-CR08: destroy() — activityLog with 'Trashed' event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `destroy()` method: is_active=false, save, delete | Soft delete sequence |
| 2 | Verify `activityLog($questionStatistic, 'Trashed', ['message' => 'Question Statistic trashed', 'performed_by' => Auth::user()->name])` logged after delete | Activity logged |

#### TC-CR09: restore() — activityLog with 'Restored' event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `restore()` method: onlyTrashed->findOrFail, restore, activityLog | Restore sequence |
| 2 | Verify `activityLog($questionStatistic, 'Restored', ['message' => 'Question Statistic restored', 'performed_by' => Auth::user()->name])` | Activity logged |

#### TC-CR10: forceDelete() — activityLog with 'Deleted' event after force delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `forceDelete()` method: withTrashed->findOrFail, forceDelete, activityLog | Force delete sequence |
| 2 | Verify `activityLog($questionStatistic, 'Deleted', ['message' => 'Question Statistic permanently deleted', 'performed_by' => Auth::user()->name])` called after forceDelete | Activity logged |

### 10.4 Dependency TC Steps

#### TC-D01: FK cascade — deleting question removes statistic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question Q1 has a statistic record in `qns_question_statistics` | Statistic exists |
| 2 | Delete Q1 from `qns_questions_bank` | Question deleted |
| 3 | Verify statistic for Q1 is automatically deleted from `qns_question_statistics` | Cascade delete worked |

#### TC-D02: Sync — depends on answer data availability

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `sync()` dispatches `SyncQuestionStatistics` job | Job dispatched to queue |
| 2 | Verify job depends on answer data in quiz/quest/exam attempt tables | Data dependency confirmed |

#### TC-D03: View references QuestionBank->question_text field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review index.blade.php for `$statistic->questionBank->question_text` | Field reference present |
| 2 | Check `qns_questions_bank` migration for `question_text` column | Column name mismatch — likely `question_content` or `ques_title` |
| 3 | Verify view may throw null property error when relationship doesn't return expected field | Potential view error |

#### TC-D04: Permission namespace mismatch (controller vs view)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Controller uses `tenant.question_bank.*` (underscore) in Gate::authorize calls | Underscore namespace |
| 2 | View uses `@can('tenant.question-statistic.view')` (hyphen) | Hyphen namespace |
| 3 | Verify mismatch causes inconsistent authorization behavior | Permission mismatch confirmed |

#### TC-D05: Activity log entry created on all 5 CRUD operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform store | Activity log: 'Stored' event created |
| 2 | Perform update (with changes) | Activity log: 'Updated' event with changes diff created |
| 3 | Perform destroy (soft-delete) | Activity log: 'Trashed' event created |
| 4 | Perform restore | Activity log: 'Restored' event created |
| 5 | Perform forceDelete | Activity log: 'Deleted' event created |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/question-bank/question-statistic/{id}` | question-bank.question-statistic.show | show() | tenant.question_bank.view |
| POST | `/question-bank/question-statistic/{question_statistic}/toggle-status` | question-bank.question-statistic.toggleStatus | toggleStatus() | tenant.question_bank.update |
| POST | `/question-bank/question-statistic/sync` | question-bank.question-statistic.sync | sync() | tenant.question_bank.update |

**Orphaned CRUD routes (exist via Route::resource but no UI — module is display-only):**
| GET | `/question-bank/question-statistic` | question-bank.question-statistic.index | index() — **abort(404)** | — |
| GET | `/question-bank/question-statistic/create` | question-bank.question-statistic.create | create() | tenant.question_bank.create |
| POST | `/question-bank/question-statistic` | question-bank.question-statistic.store | store() | tenant.question_bank.create |
| GET | `/question-bank/question-statistic/{id}/edit` | question-bank.question-statistic.edit | edit() | tenant.question_bank.update |
| PUT|PATCH | `/question-bank/question-statistic/{id}` | question-bank.question-statistic.update | update() | tenant.question_bank.update |
| DELETE | `/question-bank/question-statistic/{id}` | question-bank.question-statistic.destroy | destroy() | tenant.question_bank.delete |
| GET | `/question-bank/question-statistic/trash/view` | question-bank.question-statistic.trashed | trashed() | tenant.question_bank.restore |
| GET | `/question-bank/question-statistic/{id}/restore` | question-bank.question-statistic.restore | restore() | tenant.question_bank.restore |
| DELETE | `/question-bank/question-statistic/{id}/force-delete` | question-bank.question-statistic.forceDelete | forceDelete() | tenant.question_bank.forceDelete |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | Migration NOT NULL mismatch blocks DB write | **P0** | Migration declares `question_bank_id` as `unsignedBigInteger` but DDL spec says `INT UNSIGNED`; also `total_attempts` defaults to 0 but migration may use `nullable()` causing write failures when NULL is sent |
| KI-02 | Permission namespace mismatch | **P0** | Controller uses `tenant.question_bank.*` (underscore) but Blade view checks `tenant.question-statistic.*` (hyphen) — inconsistent auth behaviour |
| KI-03 | No scheduled recomputation job | **Medium** | No cron/scheduled task exists to periodically recompute statistics; data becomes stale over time |
| KI-04 | View references potentially missing column | **Medium** | Show view uses `$statistic->questionBank->question_text` but QuestionBank model may use `question_content` or `ques_title` — null property error |
| KI-05 | restore() does not reset is_active | **Low** | Restoring a statistic does not explicitly set `is_active = true`; record stays inactive after restore |
| KI-06 | **index() starts with abort(404) — list page dead** | **P0** | `abort(404);` is first line in `index()`. No list screen exists; statistics accessible via show(), toggleStatus(), sync() only |
| KI-07 | **Module is display-only — CRUD routes are orphaned** | **Medium** | Controller has create/store/edit/update/destroy/restore/forceDelete methods via `Route::resource` but module is display-only. Statistics are system-computed via FK cascade. These routes exist but have no UI entry points |

---

## 13. Feature Summary Matrix

| Feature | REQ ID | Controller Method(s) | Key Models | Pagination |
|---------|--------|---------------------|------------|------------|
| View Statistic | — | show() | QuestionStatistic, QuestionBank | None |
| Toggle Status | — | toggleStatus() | QuestionStatistic | None (AJAX) |
| Sync | — | sync() | QuestionStatistic | None (dispatches job) |
| **CRUD (orphaned routes)** | — | create/store/edit/update/destroy/trashed/restore/forceDelete | QuestionStatistic | **NOT USED — display-only module** |
