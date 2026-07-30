# qns_QuestionBank_Review_TcList

## Module: QuestionBank → Question Review → Review Lifecycle

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | QuestionBank (QNS) |
| Tab Group | Question Review (Tabbed under Question Bank) |
| Features | Review List (queue), View Review Details, Approve Question, Reject Question |
| URL(s) | `/question-review` (reviewIndex), `/question-review/{id}` (reviewShow), `/question-review/{id}/approve` (reviewApprove), `/question-review/{id}/reject` (reviewReject) |
| Controller | `Modules\QuestionBank\Http\Controllers\QuestionBankController` — methods: reviewIndex(Request), reviewShow($id), reviewApprove(Request, $id), reviewReject(Request, $id) |
| Model(s) | `QuestionReviewLog` (`Modules\QuestionBank\Models\QuestionReviewLog`) — `SoftDeletes` trait, `QuestionBank` (for status FSM) |
| Validation | `reviewReject()` — inline validation requiring comment; `reviewApprove()` — no FormRequest (comment optional) |
| Permission Gates (Controller) | Controller uses `Gate::authorize()` with `tenant.question-bank.viewAny`, `.view`, `.update` directly — `QuestionReviewLogPolicy` (9 `tenant.question-review-log.*` gates) exists but is **NOT wired** to controller |
| Soft Deletes | Yes — `SoftDeletes` trait on QuestionReviewLog |
| Events | Activity log on review approve/reject (via `activityLog()`) |
| Primary Table | `qns_question_review_log` |

---

## 2. Pre-conditions

- Required permissions (controller gates): `tenant.question-bank.viewAny` (list), `tenant.question-bank.view` (detail), `tenant.question-bank.update` (approve/reject)
- At least one active Question Bank question must exist (`qns_questions_bank`); reviewIndex defaults to filtering by `IN_REVIEW` (single status via `?review_status=` param)
- Taxonomy data must exist: `slb_bloom_taxonomy`, `slb_cognitive_skill`, `slb_ques_type_specificity`, `slb_complexity_level`
- Review status dropdown must exist in `sys_dropdown_table` with key `qns_question_review_log.review_status_id` (values: PENDING, APPROVED, REJECTED)
- For taxonomy completeness tests: Questions with partial taxonomy fields (some null, some filled)
- For AI-generated tests: Questions with `created_by_AI = 1` in various statuses
- For concurrent review tests: Two active browser sessions with different reviewer users
- For review history tests: Multiple review log entries for the same question

---

## 3. Default Data Load

When review index loads (GET `/question-review`):

| Data | Source | Query | Pagination |
|------|--------|-------|------------|
| Review Queue | `QuestionBank::with(['schoolClass', 'subject', 'creator'])` with `where('status', $reviewStatus)` (single status from request, default `IN_REVIEW`) | Filterable by class, subject, review_status | 10 per page |
| Filter Data | `QuestionLookupService::getFilterData()` | Classes, Subjects, Statuses | None |

When review show loads (GET `/question-review/{id}`):

| Data | Source | Notes |
|------|--------|-------|
| Question Log Detail | `QuestionReviewLog::with(['question', 'reviewer', 'reviewStatus'])->where('id', $id)->firstOrFail()` | `$id` is `QuestionReviewLog` ID, not `QuestionBank` ID |
| Review Log | One specific `QuestionReviewLog` entry by ID | Reviewer, status, comment, timestamp |

---

## 4. BC-DB — Database Schema

### 4.1 `qns_question_review_log` — Primary Review Log Table

| BC-DB ID | Column | Type | Nullable | Default | Constraints | Notes |
|----------|--------|------|----------|---------|-------------|-------|
| BC-DB-01 | id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | PK | Surrogate primary key |
| BC-DB-02 | question_id | INT UNSIGNED | NOT NULL | — | FK → qns_questions_bank.id ON DELETE CASCADE | Question being reviewed |
| BC-DB-03 | reviewer_id | INT UNSIGNED | NOT NULL | — | FK → sys_users.id ON DELETE CASCADE | Reviewer user |
| BC-DB-04 | review_status_id | INT UNSIGNED | NOT NULL | — | FK → sys_dropdown_table.id ON DELETE CASCADE | Review decision |
| BC-DB-05 | review_comment | TEXT | YES | NULL | — | Reviewer feedback (required for rejection) |
| BC-DB-06 | reviewed_at | DATETIME | NOT NULL | — | — | When review decision was made |
| BC-DB-07 | is_active | TINYINT(1) | YES | 1 | — | Soft delete flag |
| BC-DB-08 | created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | — | Creation time |
| BC-DB-09 | updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | — | Update time |
| BC-DB-10 | deleted_at | TIMESTAMP | YES | NULL | — | Soft delete marker |

**Indexes:**
- PRIMARY KEY (`id`)
- KEY `idx_q_review_question` (`question_id`)
- KEY `idx_q_review_status` (`review_status_id`)

**Foreign Keys:**
- `fk_q_review_question` — `question_id` → `qns_questions_bank.id` ON DELETE CASCADE
- `fk_q_review_reviewer` — `reviewer_id` → `sys_users.id` ON DELETE CASCADE
- `fk_q_review_status` — `review_status_id` → `sys_dropdown_table.id` ON DELETE CASCADE

### 4.2 `qns_questions_bank` — Relevant Status Column

| BC-DB ID | Column | Type | Nullable | Default | Constraints | Notes |
|----------|--------|------|----------|---------|-------------|-------|
| BC-DB-11 | status | ENUM('DRAFT','IN_REVIEW','APPROVED','REJECTED','PUBLISHED','ARCHIVED') | NOT NULL | 'DRAFT' | Lifecycle status — managed by review actions |
| BC-DB-12 | created_by_AI | TINYINT(1) | YES | 0 | — | AI-generated flag used in review gating |

---

## 5. BC-VAL — Validation Rules

### 5.1 Review Reject Validation (inline in reviewReject)

| BC-VAL ID | Field | Rule | Error Message |
|-----------|-------|------|---------------|
| BC-VAL-01 | review_comment | required, string | "A comment is required when rejecting a question." |

### 5.2 Review Approve Validation (inline in reviewApprove)

| BC-VAL ID | Field | Rule | Notes |
|-----------|-------|------|-------|
| BC-VAL-02 | (none) | No FormRequest | Comment is optional; no validation enforced |

### 5.3 Validation Gap

| BC-VAL ID | Issue | Severity |
|-----------|-------|----------|
| BC-VAL-GAP-01 | reviewApprove has no FormRequest — no server-side validation | Medium |

---

## 6. BC-AUTH — Authorization

### 6.1 Policy Gates (NOT wired to controller)

`QuestionReviewLogPolicy` exists with 9 gates, but the controller **bypasses it entirely** — it calls `Gate::authorize('tenant.question-bank.*')` directly. All policy methods below are unreachable.

| BC-AUTH ID | Gate Name | Policy Method | Permission String | Scope |
|------------|-----------|---------------|-------------------|-------|
| BC-AUTH-01 | viewAny | `viewAny(User $user): bool` | `tenant.question-review-log.viewAny` | (unused) |
| BC-AUTH-02 | view | `view(User $user, QuestionReviewLog $log): bool` | `tenant.question-review-log.view` | (unused) |
| BC-AUTH-03 | create | `create(User $user): bool` | `tenant.question-review-log.create` | (unused) |
| BC-AUTH-04 | update | `update(User $user, QuestionReviewLog $log): bool` | `tenant.question-review-log.update` | (unused) |
| BC-AUTH-05 | delete | `delete(User $user, QuestionReviewLog $log): bool` | `tenant.question-review-log.delete` | (unused) |
| BC-AUTH-06 | restore | `restore(User $user, QuestionReviewLog $log): bool` | `tenant.question-review-log.restore` | (unused) |
| BC-AUTH-07 | forceDelete | `forceDelete(User $user, QuestionReviewLog $log): bool` | `tenant.question-review-log.forceDelete` | (unused) |
| BC-AUTH-08 | review | `review(User $user): bool` | `tenant.question-review-log.review` | (unused) |
| BC-AUTH-09 | viewHistory | `viewHistory(User $user): bool` | `tenant.question-review-log.viewHistory` | (unused) |

### 6.2 Controller Method → Actual Permission Mapping

| BC-AUTH ID | Controller Method | Gate Used | Notes |
|------------|-------------------|-----------|-------|
| BC-AUTH-C-01 | reviewIndex(Request) | `tenant.question-bank.viewAny` | Gate authorize (NOT using QuestionReviewLogPolicy) |
| BC-AUTH-C-02 | reviewShow($id) | `tenant.question-bank.view` | Gate authorize (NOT using QuestionReviewLogPolicy) |
| BC-AUTH-C-03 | reviewApprove(Request, $id) | `tenant.question-bank.update` | Gate authorize (NOT using QuestionReviewLogPolicy) |
| BC-AUTH-C-04 | reviewReject(Request, $id) | `tenant.question-bank.update` | Gate authorize (NOT using QuestionReviewLogPolicy) |

---

## 7. BC-BIZ — Business Logic

### 7.1 Business Rules

| BC-BIZ ID | Rule | Description | Enforcement Point |
|-----------|------|-------------|-------------------|
| BC-BIZ-01 | Taxonomy Completeness | All four taxonomy fields must be non-null before DRAFT→IN_REVIEW transition | QuestionCRUDService / Frontend (NOT enforced in review service) |
| BC-BIZ-02 | Rejection Requires Comment | When rejecting (IN_REVIEW→REJECTED), `comment` field is mandatory (not `review_comment`) | reviewReject() inline validation |
| BC-BIZ-03 | Immutable Review Log | Once created, review log entries cannot be edited or deleted (no update/destroy endpoints exposed) | No edit/delete routes exposed |
| BC-BIZ-04 | Status FSM: DRAFT→IN_REVIEW→APPROVED→PUBLISHED | Standard path; reviewApprove sets APPROVED (not PUBLISHED) | QuestionReviewService |
| BC-BIZ-05 | Status FSM: IN_REVIEW→REJECTED→DRAFT | Rejection moves question back to DRAFT for creator edits | reviewReject() logic |
| BC-BIZ-06 | Approval Sets APPROVED (Not PUBLISHED) | reviewApprove() transitions to APPROVED; separate publish step needed | reviewApprove() service |
| BC-BIZ-07 | Review Log Timestamp | `reviewed_at` set to current datetime on each review action | Service layer |

### 7.2 Model Attributes

| BC-BIZ ID | Attribute | Type | Notes |
|-----------|-----------|------|-------|
| BC-BIZ-ATTR-01 | `$fillable` | `['question_id', 'reviewer_id', 'review_status_id', 'review_comment', 'reviewed_at', 'is_active']` | Mass-assignable fields |
| BC-BIZ-ATTR-02 | `$casts` | `is_active => boolean`, `reviewed_at => datetime` | Attribute casting |
| BC-BIZ-ATTR-03 | `$table` | `qns_question_review_log` | DB table name |
| BC-BIZ-ATTR-04 | `$primaryKey` | `id` | Primary key |

### 7.3 Model Relationships

| BC-BIZ ID | Relation | Type | Foreign Key | Local Key |
|-----------|----------|------|-------------|-----------|
| BC-BIZ-REL-01 | question() | BelongsTo | question_id | qns_questions_bank.id |
| BC-BIZ-REL-02 | reviewer() | BelongsTo | reviewer_id | sys_users.id |
| BC-BIZ-REL-03 | reviewStatus() | BelongsTo | review_status_id | sys_dropdown_table.id |

---

## 8. BC-REF — Referential Integrity

### Foreign Keys on `qns_question_review_log`

| BC-REF ID | FK Name | Column | References Table | On Delete | Notes |
|-----------|---------|--------|-----------------|-----------|-------|
| BC-REF-01 | fk_q_review_question | question_id | qns_questions_bank.id | CASCADE | Question deletion cascades to review logs |
| BC-REF-02 | fk_q_review_reviewer | reviewer_id | sys_users.id | CASCADE | User deletion cascades to review logs |
| BC-REF-03 | fk_q_review_status | review_status_id | sys_dropdown_table.id | CASCADE | Status value deletion cascades |

### Indexes

| BC-REF ID | Index Name | Column(s) | Type | Purpose |
|-----------|------------|-----------|------|---------|
| BC-REF-04 | idx_q_review_question | question_id | INDEX | Filter reviews by question |
| BC-REF-05 | idx_q_review_status | review_status_id | INDEX | Filter reviews by status |

---

## 9. Test Case Summary

### 9.1 Positive TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-QBRV-P01 | reviewIndex — Review queue loads with filter data and pagination | Functional | List | High |
| TC-QBRV-P02 | reviewIndex — Filter by review status (IN_REVIEW / DRAFT / APPROVED) | Functional | Filter | High |
| TC-QBRV-P03 | reviewIndex — Filter by class and subject | Functional | Filter | Medium |
| TC-QBRV-P04 | reviewShow — View review details for a question | Functional | View | High |
| TC-QBRV-P05 | reviewShow — Review history displays all previous review entries | Functional | History | High |
| TC-QBRV-P06 | reviewApprove — Approve question from IN_REVIEW (standard path) | Functional | Approve | High |
| TC-QBRV-P07 | reviewApprove — Approve question from DRAFT (admin shortcut) | Functional | Approve | High |
| TC-QBRV-P08 | reviewApprove — Approve with optional comment | Functional | Approve | Medium |
| TC-QBRV-P09 | reviewReject — Reject question with mandatory comment | Functional | Reject | High |
| TC-QBRV-P10 | reviewReject — Rejected question moves back to DRAFT | Functional | Reject | High |
| TC-QBRV-P11 | Review log entry created on approve with correct reviewer_id, status, timestamp | Functional | Log | High |
| TC-QBRV-P12 | Review log entry created on reject with correct reviewer_id, status, comment, timestamp | Functional | Log | High |
| TC-QBRV-P13 | Review history — Multiple review cycles for same question | Functional | History | Medium |
| TC-QBRV-P14 | Review log immutability — Existing log entries cannot be modified via UI | Business Rule | Immutable | High |

### 9.2 Negative TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-QBRV-N01 | reviewReject — Reject without comment (validation fails) | Validation | Reject | High |
| TC-QBRV-N02 | reviewReject — Reject with empty string comment (validation fails) | Validation | Reject | High |
| TC-QBRV-N03 | reviewApprove — Non-existent question ID (404) | Validation | Approve | High |
| TC-QBRV-N04 | reviewReject — Non-existent question ID (404) | Validation | Reject | High |
| TC-QBRV-N05 | reviewShow — Non-existent review log ID (404) | Validation | View | High |
| TC-QBRV-N06 | reviewApprove — Question already REJECTED (cannot approve after reject) | Business Rule | Approve | High |
| TC-QBRV-N08 | reviewReject — Question already REJECTED (cannot reject again) | Business Rule | Reject | Medium |
| TC-QBRV-N09 | reviewApprove — Question in DRAFT (admin shortcut allowed — this should succeed) | Business Rule | Approve | Medium |
| TC-QBRV-N10 | reviewApprove — Question in PUBLISHED status (no-op or error) | Business Rule | Approve | Medium |
| TC-QBRV-N11 | reviewIndex — Without viewAny permission (403) | Auth | Permission | High |
| TC-QBRV-N12 | reviewShow — Without view permission (403) | Auth | Permission | High |
| TC-QBRV-N13 | reviewApprove — Without update permission (403) | Auth | Permission | High |
| TC-QBRV-N14 | reviewReject — Without update permission (403) | Auth | Permission | High |
| TC-QBRV-N15 | Guest user redirect to login for review routes | Auth | Security | High |

### 9.3 Dependency TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-QBRV-D01 | Review log FK cascade — Question deleted cascades to review logs | Integration | Cascade | High |
| TC-QBRV-D02 | Review log FK — Reviewer deleted cascades to review logs | Integration | Cascade | High |
| TC-QBRV-D03 | Question status FSM — Approve sets APPROVED (not PUBLISHED) | Integration | FSM | High |
| TC-QBRV-D04 | Question status FSM — Reject sets REJECTED, question falls back to DRAFT | Integration | FSM | High |
| TC-QBRV-D05 | Taxonomy data dependency — Review module reads bloom/cognitive/specificity/complexity from Syllabus | Integration | Taxonomy | High |
| TC-QBRV-D06 | Dropdown dependency — review_status_id references sys_dropdown_table | Integration | Dropdown | High |
| TC-QBRV-D07 | Cascade — Force delete review_status from sys_dropdown_table cascades to review logs | Integration | Cascade | High |

### 9.4 Code Review TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-QBRV-CR01 | reviewIndex() — Gate check + filter data loading + pagination | Code Review | Controller | High |
| TC-QBRV-CR02 | reviewShow($id) — Gate check + findOrFail + review log relations | Code Review | Controller | High |
| TC-QBRV-CR03 | reviewApprove($id) — Gate check + status transition + activity log | Code Review | Controller | High |
| TC-QBRV-CR04 | reviewReject($id) — Gate check + comment validation + status transition | Code Review | Controller | High |
| TC-QBRV-CR05 | reviewApprove() — Sets APPROVED status (not PUBLISHED) | Code Review | Service | High |
| TC-QBRV-CR06 | reviewReject() — Comment required validation logic | Code Review | Service | High |
| TC-QBRV-CR07 | Model QuestionReviewLog — SoftDeletes + fillable + casts + relationships | Code Review | Model | High |
| TC-QBRV-CR11 | Policy QuestionReviewLogPolicy — All permission methods | Code Review | Policy | High |
| TC-QBRV-CR12 | Route registration — Missing dedicated QuestionReviewController | Code Review | Route | Medium |
| TC-QBRV-CR13 | Flash messages on approve/reject success | Code Review | View | Medium |
| TC-QBRV-CR14 | Blade @can directives for review action buttons | Code Review | View | Medium |
| TC-QBRV-CR15 | No notification module integration on review events | Code Review | Integration | Medium |

### 9.5 Total TC Count

| Category | Count |
|----------|-------|
| Positive (TC-QBRV-P) | 14 |
| Negative (TC-QBRV-N) | 15 |
| Dependency (TC-QBRV-D) | 7 |
| Code Review (TC-QBRV-CR) | 12 |
| **Total** | **48** |

---

## 10. Positive TC Steps

### 10.1 Review List (REQ-QNS-REV-001)

#### TC-QBRV-P01: reviewIndex — Review queue loads with filter data and pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.question-review-log.viewAny` navigates to Question Bank → Question Review tab | Review tab loads |
| 2 | Verify filter dropdowns: Class, Subject, Review Status | All filters present |
| 3 | Verify table columns: #, Question, Class/Subject, Author, Reviewer, Status, Review Date, Action | All columns present |
| 4 | Verify pagination (20 per page) | Paginated |
| 5 | Verify questions with status IN_REVIEW, DRAFT, APPROVED appear in queue | Relevant questions shown |

---

#### TC-QBRV-P02: reviewIndex — Filter by review status (IN_REVIEW / DRAFT / APPROVED)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set filter: Review Status = IN_REVIEW | Only IN_REVIEW questions shown |
| 2 | Set filter: Review Status = DRAFT | Only DRAFT questions shown |
| 3 | Set filter: Review Status = APPROVED | Only APPROVED questions shown |
| 4 | Verify count matches expected per status | Correct filtering |

---

#### TC-QBRV-P03: reviewIndex — Filter by class and subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a specific Class from the filter | Questions filtered to that class |
| 2 | Select a specific Subject within the class | Questions filtered to that subject |
| 3 | Verify only matching questions displayed | Correct filtering |

---

### 10.2 Review Show & History (REQ-QNS-REV-002)

#### TC-QBRV-P04: reviewShow — View review details for a question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "View Details" on a question in the review queue | Review detail page loads |
| 2 | Verify left column: Question title, reviewer details, review status badge, review date | All info displayed |
| 3 | Verify right column: Status (Active/Inactive), created_at, updated_at | Timestamps displayed |
| 4 | Verify Review Comment Card: Border colour matches status (green=approved, red=rejected, yellow=pending) | Card rendered |
| 5 | Verify Question Summary Card: Class, Subject, type, marks, bloom, complexity, status, created by | Summary shown |

---

#### TC-QBRV-P05: reviewShow — Review history displays all previous review entries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Question Q1 with 3 review log entries (reject, approve, reject) | 3 log entries exist |
| 2 | Open review detail page for Q1 | Page loads |
| 3 | Verify Review History Card shows all 3 entries ordered by reviewed_at DESC | History shown |
| 4 | Verify each entry shows: reviewer name, status, comment, timestamp | All details present |

---

### 10.3 Review Approve (REQ-QNS-REV-003)

#### TC-QBRV-P06: reviewApprove — Approve question from IN_REVIEW (standard path)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Question Q1 with status = IN_REVIEW, all taxonomy fields filled | Q1 in IN_REVIEW |
| 2 | Navigate to review detail page for Q1 | Page loads |
| 3 | Click "Approve" button | POST to reviewApprove |
| 4 | System checks Gate: `tenant.question-review-log.update` | Gate passed |
| 5 | System transitions Q1.status from IN_REVIEW to APPROVED | Status updated |
| 6 | System creates QuestionReviewLog entry with reviewer_id, review_status_id=APPROVED, reviewed_at | Log created |
| 7 | Redirected to review list filtered by APPROVED | Redirect success |
| 8 | Verify success message: "Question Approved successfully." | Flash message shown |
| 9 | DB check: qns_questions_bank.status = 'APPROVED' | DB verified |
| 10 | DB check: qns_question_review_log has entry for Q1 with correct data | Log verified |

---

#### TC-QBRV-P07: reviewApprove — Approve question from DRAFT (admin shortcut)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Question Q1 with status = DRAFT | Q1 in DRAFT |
| 2 | Navigate to review detail page for Q1 | Page loads |
| 3 | Click "Approve" button | POST to reviewApprove |
| 4 | System transitions Q1.status from DRAFT directly to APPROVED | Admin shortcut works |
| 5 | DB check: qns_questions_bank.status = 'APPROVED' | DB verified |
| 6 | Verify review log entry created | Log exists |

---

#### TC-QBRV-P08: reviewApprove — Approve with optional comment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to review detail for Q1 in IN_REVIEW | Page loads |
| 2 | Enter comment: "Good question. Ready for publishing." | Comment entered |
| 3 | Click "Approve" | Approval succeeds |
| 4 | DB check: review_comment = "Good question. Ready for publishing." | Comment saved |
| 5 | Approve another question Q2 without comment | Approval succeeds |
| 6 | DB check: review_comment = NULL | Comment optional |

---

### 10.4 Review Reject (REQ-QNS-REV-004)

#### TC-QBRV-P09: reviewReject — Reject question with mandatory comment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Question Q1 with status = IN_REVIEW | Q1 in IN_REVIEW |
| 2 | Navigate to review detail page for Q1 | Page loads |
| 3 | Enter comment: "Incorrect answer key. Please fix." | Comment entered |
| 4 | Click "Reject" button | POST to reviewReject |
| 5 | System validates comment is not empty | Validation passes |
| 6 | System transitions Q1.status from IN_REVIEW to REJECTED | Status updated |
| 7 | System creates QuestionReviewLog entry with reviewer_id, review_status_id=REJECTED, comment, reviewed_at | Log created |
| 8 | Redirected to review list filtered by REJECTED | Redirect success |
| 9 | Verify success message: "Question Rejected successfully." | Flash message shown |
| 10 | DB check: qns_questions_bank.status = 'REJECTED' | DB verified |
| 11 | DB check: qns_question_review_log has entry with review_comment | Log verified |

---

#### TC-QBRV-P10: reviewReject — Rejected question moves back to DRAFT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question Q1 is rejected via reviewReject | Q1.status = REJECTED |
| 2 | Creator opens edit page for Q1 | Edit form loads |
| 3 | Creator modifies question content | Changes made |
| 4 | Creator saves question | Q1.status transitions to DRAFT |
| 5 | DB check: qns_questions_bank.status = 'DRAFT' | Ready for re-submission |

---

### 10.5 Review Log Creation (REQ-QNS-REV-005)

#### TC-QBRV-P11: Review log entry created on approve with correct reviewer_id, status, timestamp

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Approve question Q1 as Reviewer R1 | Approval done |
| 2 | DB check: qns_question_review_log.question_id = Q1.id | Correct question |
| 3 | DB check: qns_question_review_log.reviewer_id = R1.id | Correct reviewer |
| 4 | DB check: qns_question_review_log.review_status_id = APPROVED (dropdown id) | Correct status |
| 5 | DB check: qns_question_review_log.reviewed_at = current datetime | Timestamp set |

---

#### TC-QBRV-P12: Review log entry created on reject with correct data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Reject question Q2 as Reviewer R1 with comment "Fix this" | Rejection done |
| 2 | DB check: qns_question_review_log.question_id = Q2.id | Correct question |
| 3 | DB check: qns_question_review_log.reviewer_id = R1.id | Correct reviewer |
| 4 | DB check: qns_question_review_log.review_status_id = REJECTED (dropdown id) | Correct status |
| 5 | DB check: qns_question_review_log.review_comment = "Fix this" | Comment saved |
| 6 | DB check: qns_question_review_log.reviewed_at = current datetime | Timestamp set |

---

### 10.6 Review History (REQ-QNS-REV-006)

#### TC-QBRV-P13: Review history — Multiple review cycles for same question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Approve Q1 → Reject Q1 → Approve Q1 → Reject Q1 → Approve Q1 | 5 review cycles |
| 2 | Open review history for Q1 | History page loads |
| 3 | Verify all 5 entries displayed in reverse chronological order | All 5 shown |
| 4 | Verify each entry has distinct reviewed_at timestamps | Distinct timestamps |

---

### 10.7 Business Rules — Immutable Log

#### TC-QBRV-P16: Review log immutability — Existing log entries cannot be modified via UI

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create review log entry for Q1 (Approve) | Log entry exists |
| 2 | Attempt to access edit endpoint for review log | No edit route exists |
| 3 | Attempt to delete review log via UI | No delete route exists |
| 4 | Direct DB update attempt | Possible at DB level but no UI route |

---

<!-- TC-QBRV-P17 removed — Concurrent review protection does not exist in code -->

## 11. Negative TC Steps

### 11.1 Review Reject — Validation Failures

#### TC-QBRV-N01: reviewReject — Reject without comment (validation fails)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to review detail for Q1 in IN_REVIEW | Page loads |
| 2 | Click "Reject" without entering any comment | Comment empty |
| 3 | System rejects action | Validation error |
| 4 | Verify error message: "A comment is required when rejecting a question." | Error shown |
| 5 | DB check: Q1.status still IN_REVIEW (unchanged) | No change |

---

#### TC-QBRV-N02: reviewReject — Reject with empty string comment (validation fails)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter comment with whitespace only (spaces, tabs) | Empty content |
| 2 | Click "Reject" | Validation fails |
| 3 | Verify error: "A comment is required when rejecting a question." | Error shown |
| 4 | DB check: Q1.status still IN_REVIEW | No change |

---

### 11.2 Non-Existent Resources

#### TC-QBRV-N03: reviewApprove — Non-existent question ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/question-bank/question-review/99999/approve` | `findOrFail(99999)` throws ModelNotFoundException |
| 2 | Verify 404 response | 404 Not Found |

---

#### TC-QBRV-N04: reviewReject — Non-existent question ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/question-bank/question-review/99999/reject` | `findOrFail(99999)` throws ModelNotFoundException |
| 2 | Verify 404 response | 404 Not Found |

---

#### TC-QBRV-N05: reviewShow — Non-existent review log ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/question-bank/question-review/99999` | `findOrFail(99999)` throws ModelNotFoundException |
| 2 | Verify 404 response | 404 Not Found |

---

### 11.3 Business Rule Violations — Status FSM

#### TC-QBRV-N06: reviewApprove — Question already APPROVED by another reviewer (concurrent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Reviewer R1 approves Q1 (status = APPROVED) | R1 success |
| 2 | Reviewer R2 attempts to approve Q1 | Status already APPROVED |
| 3 | System returns error: "This question has already been reviewed by another reviewer." | Concurrent guard |
| 4 | DB check: Only one review log entry for Q1 approve | Single entry |

---

#### TC-QBRV-N07: reviewApprove — Question already REJECTED (cannot approve after reject)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Reviewer rejects Q1 (status = REJECTED) | Rejection done |
| 2 | Another reviewer attempts to approve Q1 | Status is REJECTED, not IN_REVIEW or DRAFT |
| 3 | System returns error or no-op | Blocked |

---

#### TC-QBRV-N08: reviewReject — Question already REJECTED (cannot reject again)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Reviewer rejects Q1 (status = REJECTED) | Rejection done |
| 2 | Another reviewer attempts to reject Q1 again | Status already REJECTED |
| 3 | System returns error or no-op | Blocked |

---

#### TC-QBRV-N09: reviewApprove — Question in DRAFT (admin shortcut allowed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Admin opens question Q1 with status DRAFT | Question detail shown |
| 2 | Clicks Approve (admin shortcut: DRAFT→APPROVED allowed) | Approve succeeds |
| 3 | Verify question status changed to APPROVED | Status = APPROVED |
| 4 | Verify review log entry created with reviewer_id, status_id for APPROVED | Log entry present |

---

#### TC-QBRV-N10: reviewApprove — Question in PUBLISHED status (no-op or error)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question Q1 has status PUBLISHED | Already published |
| 2 | Attempt to approve Q1 | Status is PUBLISHED, not IN_REVIEW or DRAFT |
| 3 | System returns error or no-op | Blocked |

---

### 11.4 Permission Gates

#### TC-QBRV-N11: reviewIndex — Without viewAny permission (403)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-bank.viewAny` | Authenticated |
| 2 | Navigate to `/question-review` | 403 Forbidden |

---

#### TC-QBRV-N12: reviewShow — Without view permission (403)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-bank.view` | Authenticated |
| 2 | Navigate to `/question-review/{id}` | 403 Forbidden |

---

#### TC-QBRV-N13: reviewApprove — Without update permission (403)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-bank.update` | Authenticated |
| 2 | POST to `/question-review/{id}/approve` | 403 Forbidden |

---

#### TC-QBRV-N14: reviewReject — Without update permission (403)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-bank.update` | Authenticated |
| 2 | POST to `/question-review/{id}/reject` | 403 Forbidden |

---

### 11.5 Security

#### TC-QBRV-N15: Guest user redirect to login for review routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logged-out (guest) user accesses `/question-review` | Redirected to login |
| 2 | Guest accesses `/question-review/{id}/approve` | Redirected to login |
| 3 | Guest accesses `/question-review/{id}/reject` | Redirected to login |

---

## 12. Dependency TC Steps

#### TC-QBRV-D01: Review log FK cascade — Question deleted cascades to review logs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Question Q1 with 2 review log entries | 2 logs exist |
| 2 | Force-delete Q1 | Q1 permanently removed |
| 3 | DB check: `qns_question_review_log` with question_id = Q1.id | 0 records (CASCADE deleted) |

---

#### TC-QBRV-D02: Review log FK — Reviewer deleted cascades to review logs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Reviewer User R1, assign R1 to review log entries | Logs linked to R1 |
| 2 | Force-delete R1 from sys_users | R1 removed |
| 3 | DB check: `qns_question_review_log` with reviewer_id = R1.id | 0 records (CASCADE deleted) |

---

#### TC-QBRV-D03: Question status FSM — Approve sets APPROVED (not PUBLISHED)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Q1 in IN_REVIEW | Status = IN_REVIEW |
| 2 | Approve Q1 | Status changes |
| 3 | DB check: qns_questions_bank.status = `APPROVED` | Correct — NOT PUBLISHED |
| 4 | DB check: Status is NOT `PUBLISHED` | Gap confirmed (must publish separately) |

---

#### TC-QBRV-D04: Question status FSM — Reject sets REJECTED, question returns to DRAFT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Q1 in IN_REVIEW | Status = IN_REVIEW |
| 2 | Reject Q1 with comment | Status changes |
| 3 | DB check: qns_questions_bank.status = `REJECTED` | Rejected |
| 4 | Creator edits and saves Q1 | Status becomes DRAFT |
| 5 | DB check: qns_questions_bank.status = `DRAFT` | Ready for re-submit |

---

#### TC-QBRV-D05: Taxonomy data dependency — Review module reads from Syllabus

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create taxonomy entries: bloom (id=1), cognitive (id=1), specificity (id=1), complexity (id=1) | Seed data exists |
| 2 | Create Q1 referencing these taxonomy IDs | Q1 created |
| 3 | Submit Q1 for review (DRAFT→IN_REVIEW) | Taxonomy check reads Syllabus tables |
| 4 | Delete a taxonomy entry (e.g., bloom_id=1) | FK constraint behavior |

---

#### TC-QBRV-D06: Dropdown dependency — review_status_id references sys_dropdown_table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Query sys_dropdown_table where key = `qns_question_review_log.review_status_id` | Returns PENDING, APPROVED, REJECTED entries |
| 2 | Create review log with a valid review_status_id from dropdown | Log created |
| 3 | Attempt to create review log with invalid review_status_id (e.g., 99999) | FK constraint violation error |

---

#### TC-QBRV-D07: Cascade — Force delete review_status from sys_dropdown_table cascades to review logs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create review status RS1 in sys_dropdown_table, create Question Q1 with review log referencing RS1 | Log linked to RS1 |
| 2 | Force-delete RS1 from sys_dropdown_table | RS1 removed |
| 3 | DB check: `qns_question_review_log` with review_status_id = RS1.id | 0 records (CASCADE deleted) |
| 4 | DB check: Q1 still exists | Question preserved |

---

## 13. Code Review TC Steps

#### TC-QBRV-CR01: reviewIndex() — Gate check + filter data loading + pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `reviewIndex()` in QuestionBankController | Gate + filter + pagination |
| 2 | Verify `Gate::authorize('tenant.question-review-log.viewAny')` | Gate called before any logic |
| 3 | Verify filter data loading (class, subject, status) | Filter params read from request |
| 4 | Verify pagination: `QuestionBank::whereIn('status', [...])->paginate(20)` | Paginated result |
| 5 | Verify view returned with compact data | View receives questions + filters |

---

#### TC-QBRV-CR02: reviewShow($id) — Gate check + findOrFail + review log relations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `reviewShow($id)` in QuestionBankController | Gate + find + relations |
| 2 | Verify `Gate::authorize('tenant.question-review-log.view')` | Permission check |
| 3 | Verify `QuestionBank::with('reviewLogs.reviewer', 'reviewLogs.reviewStatus')->findOrFail($id)` | Eager loads relations |
| 4 | Verify view passes question and review logs | Both passed to view |

---

#### TC-QBRV-CR03: reviewApprove($id) — Gate check + status transition + activity log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `reviewApprove($id)` in QuestionBankController | Full approve flow |
| 2 | Verify `Gate::authorize('tenant.question-review-log.update')` | Permission check |
| 3 | Verify `findOrFail($id)` — question found | Question loaded |
| 4 | Verify service call to transition status to APPROVED | Status update |
| 5 | Verify QuestionReviewLog entry creation with reviewer_id, status, reviewed_at | Log entry |
| 6 | Verify redirect with success flash message | Redirect + flash |

---

#### TC-QBRV-CR04: reviewReject($id) — Gate check + comment validation + status transition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `reviewReject($id)` in QuestionBankController | Full reject flow |
| 2 | Verify `Gate::authorize('tenant.question-review-log.update')` | Permission check |
| 3 | Verify `findOrFail($id)` — question found | Question loaded |
| 4 | Verify inline validation: comment is required and not empty | Validation check |
| 5 | Verify service call to transition status to REJECTED | Status update |
| 6 | Verify QuestionReviewLog entry with comment + reviewer_id + status + timestamp | Log entry |
| 7 | Verify redirect with success flash message | Redirect + flash |

---

#### TC-QBRV-CR05: reviewApprove() — Sets APPROVED status (not PUBLISHED)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review the status assignment in the approval service | Status constant used |
| 2 | Verify `question->status = 'APPROVED'` (not 'PUBLISHED') | Correct status |
| 3 | Verify no automatic publish logic follows approval | Separate publish needed |

---

#### TC-QBRV-CR06: reviewReject() — Comment required validation logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review the comment validation in reviewReject | Validation implementation |
| 2 | Verify `$request->input('review_comment')` check | Comment read from request |
| 3 | Verify `if (empty($comment))` or equivalent validation | Empty check present |
| 4 | Verify error response: back with error message | Error returned |

---

<!-- TC-QBRV-CR07 removed — Concurrent review protection does not exist in code -->
<!-- TC-QBRV-CR08 removed — AI gate logic does not exist in code -->
<!-- TC-QBRV-CR09 removed — Taxonomy completeness check does not exist in code -->

#### TC-QBRV-CR07: Model QuestionReviewLog — SoftDeletes + fillable + casts + relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify model uses `SoftDeletes` trait | Trait imported |
| 2 | Verify `$fillable` includes `question_id`, `reviewer_id`, `review_status_id`, `review_comment`, `reviewed_at`, `is_active` | Mass-assignable |
| 3 | Verify `$casts` includes `is_active => boolean`, `reviewed_at => datetime` | Correct casts |
| 4 | Verify `$table = 'qns_question_review_log'` | Correct table name |
| 5 | Verify `question()` BelongsTo relationship | Relationship defined |
| 6 | Verify `reviewer()` BelongsTo relationship | Relationship defined |
| 7 | Verify `reviewStatus()` BelongsTo relationship | Relationship defined |

---

#### TC-QBRV-CR11: Policy QuestionReviewLogPolicy — All permission methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review QuestionReviewLogPolicy | 9 permission methods |
| 2 | Verify `viewAny`: `tenant.question-review-log.viewAny` | List permission |
| 3 | Verify `view`: `tenant.question-review-log.view` | Show permission |
| 4 | Verify `create`: `tenant.question-review-log.create` | Create permission |
| 5 | Verify `update`: `tenant.question-review-log.update` | Update permission |
| 6 | Verify `delete`: `tenant.question-review-log.delete` | Soft delete permission |
| 7 | Verify `restore`: `tenant.question-review-log.restore` | Restore permission |
| 8 | Verify `forceDelete`: `tenant.question-review-log.forceDelete` | Force delete permission |
| 9 | Verify `review`: `tenant.question-review-log.review` | Review action permission |
| 10 | Verify `viewHistory`: `tenant.question-review-log.viewHistory` | History view permission |

---

#### TC-QBRV-CR12: Route registration — No dedicated QuestionReviewController

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review routes for question-review | Routes exist |
| 2 | Verify routes point to `QuestionBankController` methods (not a dedicated controller) | No separate controller |
| 3 | Verify route pattern: `reviewIndex`, `reviewShow`, `reviewApprove`, `reviewReject` | All 4 routes registered |

---

#### TC-QBRV-CR13: Flash messages on approve/reject success

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `reviewApprove()` flash message | `->with('success', flash('approved.question'))` |
| 2 | Review `reviewReject()` flash message | `->with('success', flash('rejected.question'))` |
| 3 | Verify flash keys exist in language file | Language keys defined |

---

#### TC-QBRV-CR14: Blade @can directives for review action buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review Question Review view for Approve button | `@can('tenant.question-review-log.review')` or similar |
| 2 | Review for Reject button permission check | `@can('tenant.question-review-log.review')` or similar |
| 3 | Review for View Details button | `@can('tenant.question-review-log.view')` or similar |
| 4 | Verify buttons hidden for unauthorized users | Conditional rendering |

---

#### TC-QBRV-CR15: No notification module integration on review events

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `reviewApprove()` for notification call | No notification sent |
| 2 | Review `reviewReject()` for notification call | No notification sent |
| 3 | Verify no Notification facade or event/listener pair exists | Gap: Notification not integrated |

---

## 14. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/question-review` | review.index | reviewIndex(Request) | tenant.question-bank.viewAny |
| GET | `/question-review/{id}` | review.show | reviewShow($id) | tenant.question-bank.view |
| POST | `/question-review/{id}/approve` | review.approve | reviewApprove(Request, $id) | tenant.question-bank.update |
| POST | `/question-review/{id}/reject` | review.reject | reviewReject(Request, $id) | tenant.question-bank.update |

---

## 15. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | No dedicated QuestionReviewController | Medium | Review methods live in `QuestionBankController` instead of a dedicated `QuestionReviewController`; violates Single Responsibility Principle |
| KI-02 | reviewApprove has no FormRequest (no validation) | Medium | Unlike reviewReject which has inline comment validation, reviewApprove has zero validation — relies entirely on service-layer logic |
| KI-03 | No notification module integration on review events | Medium | When a question is approved or rejected, the question creator is not notified via the Notification module; teacher must manually check status |

---

## 16. Feature Summary Matrix

| Feature | REQ ID | Controller Method(s) | Key Models | Pagination |
|---------|--------|---------------------|------------|------------|
| Review List | REQ-QNS-REV-001 | reviewIndex(Request) | QuestionBank, QuestionReviewLog | 10 per page (single status filter, default IN_REVIEW) |
| Review Detail | REQ-QNS-REV-002 | reviewShow() | QuestionBank, QuestionReviewLog, User | None |
| Approve Question | REQ-QNS-REV-003 | reviewApprove() | QuestionBank, QuestionReviewLog | None |
| Reject Question | REQ-QNS-REV-004 | reviewReject() | QuestionBank, QuestionReviewLog | None |
| Review Log | REQ-QNS-REV-005 | reviewApprove(), reviewReject() | QuestionReviewLog | None |
| Review History | REQ-QNS-REV-006 | reviewShow() (history tab) | QuestionReviewLog | None |

---

*End of file — qns_QuestionBank_Review_TcList.md*
