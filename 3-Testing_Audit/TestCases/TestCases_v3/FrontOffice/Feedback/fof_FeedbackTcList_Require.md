# FrontOffice · Feedback — Test Case List + Manual Test Spec (COMBINED)

> Single source for the test-case matrix **and** the manual-testing spec (Feature Info + BC + TC list + Method Index + Manual Steps + Known Defects). Prefix `fof_` verified against `FrontOffice_DDL_v1.sql` (`fof_feedback_forms`, `fof_feedback_responses`).

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | FrontOffice (FOF) |
| Feature / Screen | Feedback |
| Controller | `Modules\FrontOffice\Http\Controllers\FeedbackController` |
| Models | `FeedbackForm` (`fof_feedback_forms`), `FeedbackResponse` (`fof_feedback_responses`) — both `extends BaseModel`, `SoftDeletes` |
| Validation | **Inline `$request->validate()`** — there is NO FormRequest class |
| Authenticated URL base | `/front-office/feedback` (middleware `auth`,`verified`; route-name group `fof.feedback.*`) |
| Public URL base | `/feedback/{token}` (middleware `throttle:30,1`, **no auth**; names `fof.feedback.public` / `fof.feedback.submit`) |
| Permissions | `frontoffice.feedback.{view,create,update,delete,restore,forceDelete}` — string Gates (`Gate::authorize(...)`) in every admin method |
| CRUD Type | Full CRUD + soft-delete lifecycle + toggle-status + public token submission + report |
| Soft Delete | Yes (`deleted_at` on both tables; `SoftDeletes` on both models) |
| Pagination | index `paginate(20)`, trashed `paginate(15)` |
| Activity Log | Tenant sink `sys_activity_logs` via `Modules\GlobalMaster\Models\ActivityLog` (helper `activityLog()`). **Only** `destroy`→`Deleted`, `forceDelete`→`Deleted`, `restore`→`Restored` are logged. `store`/`update`/`toggleStatus` emit NO activity log. |
| DB scope | TENANT-SIDE (`fof_*` in `tenant_db`) → tenancy init required |

### Routes (verbatim from `Modules/FrontOffice/routes/web.php`)

| Name | Verb | Path | Method | Gate |
|------|------|------|--------|------|
| `fof.feedback.index` | GET | `/front-office/feedback` | `index` | `frontoffice.feedback.view` |
| `fof.feedback.create` | GET | `/front-office/feedback/create` | `create` | `frontoffice.feedback.create` |
| `fof.feedback.store` | POST | `/front-office/feedback` | `store` | `frontoffice.feedback.create` |
| `fof.feedback.report` | GET | `/front-office/feedback/{form}/report` | `report`/`show` | `frontoffice.feedback.view` |
| `fof.feedback.edit` | GET | `/front-office/feedback/{form}/edit` | `edit` | `frontoffice.feedback.update` |
| `fof.feedback.update` | PUT | `/front-office/feedback/{form}` | `update` | `frontoffice.feedback.update` |
| `fof.feedback.destroy` | DELETE | `/front-office/feedback/{form}` | `destroy` | `frontoffice.feedback.delete` |
| `fof.feedback.toggleStatus` | POST/PATCH | `/front-office/feedback/{form}/toggle-status` | `toggleStatus` | `frontoffice.feedback.update` |
| `fof.feedback.trashed` | GET | `/front-office/feedback/trash/view` | `trashed` | `frontoffice.feedback.restore` |
| `fof.feedback.restore` | GET | `/front-office/feedback/{id}/restore` | `restore` | `frontoffice.feedback.restore` |
| `fof.feedback.forceDelete` | DELETE | `/front-office/feedback/{id}/force-delete` | `forceDelete` | `frontoffice.feedback.forceDelete` |
| `fof.feedback.public` | GET | `/feedback/{token}` | `publicForm` | none (public) |
| `fof.feedback.submit` | POST | `/feedback/{token}` | `publicSubmit` | none (public) |

### Form inputs (create/edit — from `create.blade.php` + inline rules)
`title` (required, ≤200), `description` (nullable, ≤1000), `questions[i][label]` (required, ≤255), `questions[i][type]` (required, in `rating|yes_no|text`), `is_anonymous_allowed` (checkbox, boolean). **Auto/programmatic (G48 — never form inputs):** `token` (`Str::uuid()`), `questions_json` (assembled from `questions`), `is_active` (=true), `created_by`/`updated_by` (=`auth()->id()`). Public submit input: `answers` (required array).

---

## 2. Business Conditions

### BC-DB (DDL constraints — one testable fact each)

| ID | Fact | Source |
|----|------|--------|
| BC-DB-01 | `fof_feedback_forms.title` VARCHAR(200) NOT NULL | DDL |
| BC-DB-02 | `description` TEXT NULL | DDL |
| BC-DB-03 | `questions_json` JSON NOT NULL | DDL |
| BC-DB-04 | `token` VARCHAR(64) NOT NULL, UNIQUE `uq_fof_ff_token` | DDL |
| BC-DB-05 | `is_anonymous_allowed` TINYINT(1) NOT NULL DEFAULT 0 | DDL |
| BC-DB-06 | `is_active` TINYINT(1) NOT NULL DEFAULT 1 | DDL |
| BC-DB-07 | `created_by`/`updated_by` BIGINT UNSIGNED NOT NULL (no FK) | DDL |
| BC-DB-08 | `deleted_at` present; `SoftDeletes` on model (assert independently) | DDL/Model |
| BC-DB-09 | `fof_feedback_responses.feedback_form_id` NOT NULL, FK→`fof_feedback_forms` **RESTRICT** | DDL |
| BC-DB-10 | `respondent_user_id` INT UNSIGNED NULL, FK→`sys_users` **SET NULL** | DDL |
| BC-DB-11 | `respondent_name` VARCHAR(100) NULL | DDL |
| BC-DB-12 | `is_anonymous` TINYINT(1) NOT NULL DEFAULT 0 (comment: "1 = anonymous; respondent_user_id MUST be NULL") | DDL |
| BC-DB-13 | `responses_json` JSON NOT NULL | DDL |
| BC-DB-14 | `submitted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP | DDL |
| BC-DB-15 | `fof_feedback_responses.created_by` BIGINT UNSIGNED NOT NULL **DEFAULT 0**; `updated_by` NOT NULL (no default) | DDL |

### BC-VAL (inline validation)

| ID | Fact | Source |
|----|------|--------|
| BC-VAL-01 | `title` required, string, max:200 | Controller store/update |
| BC-VAL-02 | `description` nullable, string, max:1000 (**stricter than DDL TEXT**) | Controller |
| BC-VAL-03 | `questions` required, array, min:1 | Controller |
| BC-VAL-04 | `questions.*.label` required, string, max:255 | Controller |
| BC-VAL-05 | `questions.*.type` required, in:rating,yes_no,text | Controller |
| BC-VAL-06 | `is_anonymous_allowed` boolean | Controller |
| BC-VAL-07 | publicSubmit `answers` required, array | Controller |

### BC-AUTH

| ID | Fact | Source |
|----|------|--------|
| BC-AUTH-01 | admin methods gate on `frontoffice.feedback.{view/create/update/delete/restore/forceDelete}` | Controller |
| BC-AUTH-02 | `trashed`+`restore` both require `...restore`; `toggleStatus` requires `...update` | Controller |
| BC-AUTH-03 | public routes (`publicForm`/`publicSubmit`) have NO gate (anonymous by design) | Controller/routes |
| BC-AUTH-04 | guest on `/front-office/feedback` → redirect `/login` | middleware `auth` |
| BC-AUTH-05 | non-super-admin without ability → 403 (Gate::before grants super-admin all) | Rule Card #31 |

### BC-BIZ

| ID | Fact | Source |
|----|------|--------|
| BC-BIZ-01 | store auto-generates `token = Str::uuid()`, sets `is_active=true`, `created_by/updated_by=auth id` | Controller |
| BC-BIZ-02 | `questions_json` assembled from `questions[]`; cast to array | Controller/Model |
| BC-BIZ-03 | index shows `withCount('responses')` | Controller |
| BC-BIZ-04 | report aggregates `responses_json[idx]` per question via `countBy()` | Controller |
| BC-BIZ-05 | `publicForm` serves only `is_active=true` forms; else `abort(404)` | Controller |
| BC-BIZ-06 | store/update redirect to `fof.menu.communication?tab=feedback` | Controller |

### BC-SM (state-machine / lifecycle)

| ID | State | Trigger | Next | Legality | Source |
|----|-------|---------|------|----------|--------|
| BC-SM-01 | Active | `destroy` | Trashed (deleted_at set) | legal | Controller |
| BC-SM-02 | Trashed | `restore` | Active | legal | Controller |
| BC-SM-03 | Trashed | `forceDelete` | Gone (row removed) | legal | Controller |
| BC-SM-04 | Gone | `restore` | — | **illegal** (unrecoverable) | derived |
| BC-SM-05 | is_active=1 | `toggleStatus` | is_active=0 (and back) | legal | Controller |

### BC-REF / BC-INT

| ID | Fact | Source |
|----|------|--------|
| BC-REF-01 | response requires an existing `feedback_form_id` (FK) | DDL |
| BC-REF-02 | force-deleting a form with responses is blocked (RESTRICT) | DDL |
| BC-REF-03 | deleting the respondent user nulls `respondent_user_id` (SET NULL) | DDL |

### BC-AUTO (programmatic — tested as auto-behaviour, never form inputs — G48)
`token`, `questions_json`, `is_active`, `created_by`, `updated_by`, `submitted_at`.

### Known defects mapped to Feedback (see §6)
SEC-FOF-002 (P1), DEV-FOF-F01 (P1, new), DEAD-FOF-001 (P3), plus the "no activity log on create/update" gap and description-max divergence.

---

## 3. Test Case List

### Positive

| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-P01 | Schema | BC-DB-01..15 | DDL | Full DDL↔app alignment, model config, inline rules, gates, events | matrix holds | `test_feedback_01_*` | ✅ |
| TC-P02 | Schema | BC-DB-04 | DDL | token UNIQUE index present | index found | `test_feedback_02_*` | ✅ |
| TC-P03 | Schema | BC-DB-09/10 | DDL | responses FKs (RESTRICT/SET NULL) | rules match | `test_feedback_03_*` | ✅ |
| TC-P04 | Schema | BC-DB-08 | DDL | deleted_at + SoftDeletes independent | both true | `test_feedback_04_*` | ✅ |
| TC-P05 | Biz | BC-BIZ-01/02 | Ctrl | create → uuid token, defaults, array cast | token 36-char, active | `test_feedback_10_*` | ✅ |
| TC-P06 | Biz | BC-BIZ-02 | Model | questions_json roundtrip | 2 questions kept | `test_feedback_11_*` | ✅ |
| TC-P07 | Biz | BC-BIZ-03 | Ctrl | withCount('responses') | ≥2 | `test_feedback_12_*` | ✅ |
| TC-P08 | Biz | BC-BIZ-04 | Ctrl | report aggregation builds | summary non-empty | `test_feedback_13_*` | ✅ |
| TC-P09 | UI | BC-BIZ | Blade | index page renders | lands on feedback | `test_feedback_15_*` | ✅ |
| TC-P10 | UI | BC-VAL | Blade | create page renders real fields | selectors present | `test_feedback_16_*` | ✅ |
| TC-P11 | Biz | BC-BIZ-05 | Ctrl | public form renders active token | survey shown | `test_feedback_17_*` | ✅ |
| TC-P12 | SM | BC-SM-05 | Ctrl | toggle flips is_active both ways | 1↔0 | `test_feedback_23_*` | ✅ |
| TC-P13 | Val+ | BC-DB-02 | DDL | omit nullable description succeeds | null stored | `test_feedback_33_*` | ✅ |
| TC-P14 | Val+ | BC-DB-01 | DDL | title exactly 200 chars accepted | stored len 200 | `test_feedback_35_*` | ✅ |
| TC-P15 | Edge | BC-BIZ-02 | Model | special chars in question label roundtrip | intact | `test_feedback_70_*` | ✅ |
| TC-P16 | Edge | BC-BIZ-04 | Ctrl | empty-response report handled | 0 responses | `test_feedback_71_*` | ✅ |
| TC-P17 | Sec | BC-AUTH-03 | Routes | public token route unauthenticated | no login redirect | `test_feedback_90_*` | ✅ |

### Negative

| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-N01 | NotNull | BC-DB-01 | DDL | missing title rejected | reject | `test_feedback_30_*` | ✅ |
| TC-N02 | NotNull | BC-DB-04 | DDL | missing token rejected | reject | `test_feedback_31_*` | ✅ |
| TC-N03 | NotNull | BC-DB-03 | DDL | missing questions_json rejected | reject | `test_feedback_32_*` | ✅ |
| TC-N04 | Length | BC-DB-01 | DDL | title 201 chars rejected/truncated | ≤200 | `test_feedback_34_*` | ✅ |
| TC-N05 | Unique | BC-DB-04 | DDL | duplicate token rejected | reject | `test_feedback_36_*` | ✅ |
| TC-N06 | Val | BC-VAL-05 | Ctrl | type constrained to rating/yes_no/text | rule present | `test_feedback_37_*` | ✅ |
| TC-N07 | Biz | BC-BIZ-05 | Ctrl | inactive form not served publicly | null | `test_feedback_18_*` | ✅ |
| TC-N08 | Biz | BC-BIZ-05 | Ctrl | unknown token not served | null | `test_feedback_19_*` | ✅ |
| TC-N09 | FK | BC-REF-01 | DDL | response w/ bad form_id rejected | reject/skip | `test_feedback_40_*` | ✅ |
| TC-N10 | FK | BC-REF-02 | DDL | force-delete form w/ responses blocked | reject/skip | `test_feedback_41_*` | ✅ |
| TC-N11 | Auth | BC-AUTH-04 | mw | guest → /login | redirect | `test_feedback_50_*` | ✅ |
| TC-N12 | Auth | BC-AUTH-05 | Gate | no-permission user → 403 | 403 | `test_feedback_51_*` | ✅ |
| TC-N13 | SM | BC-SM-04 | derived | restore after force-delete impossible | null | `test_feedback_22_*` | ✅ |
| TC-N14 | Sec | BC-BIZ | Blade | stored XSS in title escaped | escaped | `test_feedback_91_*` | ✅ |
| TC-N15 | Defect | DEV-FOF-F01 | Ctrl+DDL | null created_by insert rejected | reject | `test_feedback_25_*` | ✅ |

### Dependency / State / Security / Defect

| TC ID | Cat | BC | Source | Description | Method | Status |
|-------|-----|----|--------|-------------|--------|--------|
| TC-D01 | Dep | BC-REF-03 | DDL | respondent SET NULL on user delete (guarded) | `test_feedback_42_*` | ✅ |
| TC-SM01 | SM | BC-SM-01..03 | Ctrl | delete→restore→forceDelete lifecycle | `test_feedback_20_*` | ✅ |
| TC-SM02 | SM | BC-SM-01 | Ctrl | activity 'Deleted' → sys_activity_logs | `test_feedback_21_*` | ✅ |
| TC-S01 | Sec | BC-AUTH-01 | Ctrl | gate ability mapped per action | `test_feedback_52_*` | ✅ |
| TC-S02 | Sec | BC-DB-12 | Ctrl | SEC-FOF-002: anon stores null respondent, is_anonymous never set | `test_feedback_24_*` | ✅ |
| TC-S03 | Sec | DEV-FOF-F01 | Ctrl | public submit e2e tolerant (failure surface) | `test_feedback_26_*` | ✅ |
| TC-DEAD01 | Defect | DEAD-FOF-001 | Ctrl | commented expiry guard + no expires_at col | `test_feedback_14_*` | ✅ |
| TC-X01 | Xref | BC-VAL-02 | DDL | description request stricter than DDL TEXT | `test_feedback_38_*` | ✅ |
| TC-U01 | UI | BC-BIZ | Blade | trash page renders | `test_feedback_60_*` | ✅ |
| TC-T01 | Tenancy | — | env | cross-tenant isolation smoke (guarded) | `test_feedback_92_*` | ✅ |

---

## 4. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_feedback_01_schema_model_and_validation_configuration_are_correct` | TC-P01 | Schema | 01 |
| 2 | `test_feedback_02_forms_token_unique_index_present` | TC-P02 | Schema | 02 |
| 3 | `test_feedback_03_responses_foreign_keys_present` | TC-P03 | Schema | 03 |
| 4 | `test_feedback_04_soft_delete_column_and_trait_independent` | TC-P04 | Schema | 04 |
| 5 | `test_feedback_10_form_create_generates_uuid_token_and_defaults` | TC-P05 | Biz | 10 |
| 6 | `test_feedback_11_questions_json_cast_roundtrip` | TC-P06 | Biz | 11 |
| 7 | `test_feedback_12_with_count_responses_relationship` | TC-P07 | Biz | 12 |
| 8 | `test_feedback_13_report_aggregation_builds_summary` | TC-P08 | Biz | 13 |
| 9 | `test_feedback_14_dead_expiry_guard_and_no_expires_at_column` | TC-DEAD01 | Defect | 14 |
| 10 | `test_feedback_15_index_page_renders` | TC-P09 | UI | 15 |
| 11 | `test_feedback_16_create_page_renders_fields` | TC-P10 | UI | 16 |
| 12 | `test_feedback_17_public_form_renders_for_active_token` | TC-P11 | Biz | 17 |
| 13 | `test_feedback_18_public_form_inactive_not_served` | TC-N07 | Neg | 18 |
| 14 | `test_feedback_19_public_form_unknown_token` | TC-N08 | Neg | 19 |
| 15 | `test_feedback_20_soft_delete_restore_force_delete_lifecycle` | TC-SM01 | SM | 20 |
| 16 | `test_feedback_21_activity_log_deleted_event_in_sys_activity_logs` | TC-SM02 | SM | 21 |
| 17 | `test_feedback_22_force_deleted_form_cannot_be_restored` | TC-N13 | Neg/SM | 22 |
| 18 | `test_feedback_23_toggle_status_flips_is_active` | TC-P12 | SM | 23 |
| 19 | `test_feedback_24_anonymous_allowed_stores_null_respondent` | TC-S02 | Sec | 24 |
| 20 | `test_feedback_25_null_created_by_violates_not_null` | TC-N15 | Defect | 25 |
| 21 | `test_feedback_26_public_submit_end_to_end_tolerant` | TC-S03 | Sec | 26 |
| 22 | `test_feedback_30_missing_title_rejected` | TC-N01 | Neg | 30 |
| 23 | `test_feedback_31_missing_token_rejected` | TC-N02 | Neg | 31 |
| 24 | `test_feedback_32_missing_questions_json_rejected` | TC-N03 | Neg | 32 |
| 25 | `test_feedback_33_nullable_description_omitted_succeeds` | TC-P13 | Pos | 33 |
| 26 | `test_feedback_34_title_over_length_rejected` | TC-N04 | Neg | 34 |
| 27 | `test_feedback_35_title_max_length_accepted` | TC-P14 | Pos | 35 |
| 28 | `test_feedback_36_duplicate_token_rejected` | TC-N05 | Neg | 36 |
| 29 | `test_feedback_37_question_type_enum_constrained` | TC-N06 | Neg | 37 |
| 30 | `test_feedback_38_description_request_stricter_than_ddl` | TC-X01 | Xref | 38 |
| 31 | `test_feedback_40_response_requires_valid_form_id` | TC-N09 | FK | 40 |
| 32 | `test_feedback_41_force_delete_form_restricted_with_responses` | TC-N10 | FK | 41 |
| 33 | `test_feedback_42_respondent_set_null_on_user_delete` | TC-D01 | Dep | 42 |
| 34 | `test_feedback_50_guest_redirected_to_login` | TC-N11 | Auth | 50 |
| 35 | `test_feedback_51_forbidden_without_permission` | TC-N12 | Auth | 51 |
| 36 | `test_feedback_52_gate_abilities_mapped_per_action` | TC-S01 | Sec | 52 |
| 37 | `test_feedback_60_trash_page_renders` | TC-U01 | UI | 60 |
| 38 | `test_feedback_70_questions_json_stores_special_characters` | TC-P15 | Edge | 70 |
| 39 | `test_feedback_71_empty_report_handled` | TC-P16 | Edge | 71 |
| 40 | `test_feedback_90_public_route_is_unauthenticated` | TC-P17 | Sec | 90 |
| 41 | `test_feedback_91_stored_xss_title_escaped` | TC-N14 | Sec | 91 |
| 42 | `test_feedback_92_cross_tenant_isolation_smoke` | TC-T01 | Tenancy | 92 |

**Total: 42 methods.**

---

## 5. Manual Test Steps (complex / workflow / defect flows only)

### MT-1 — Create feedback form (staff)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin; open `/front-office/feedback/create` | Form Details + Questions List render |
| 2 | Enter Title, add ≥1 question (label + type), toggle "Anonymous Responses" | fields accept input |
| 3 | Press "Create Form" | redirect `/front-office/communication?tab=feedback`, flash "Feedback form created." |
| 4 | DB check | `SELECT title,token,is_active,questions_json FROM fof_feedback_forms ORDER BY id DESC LIMIT 1` → token is a 36-char UUID, `is_active=1`, `questions_json` holds the entered array |
| 5 | Activity check | `SELECT * FROM sys_activity_logs WHERE subject_type LIKE '%FeedbackForm%' AND event='Created'` → **NO row** (store does NOT log — documented gap) |

### MT-2 — Public anonymous submission (SEC-FOF-002 + DEV-FOF-F01)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Copy the form `token`; open `/feedback/{token}` logged OUT | survey renders; anonymous banner shown when `is_anonymous_allowed=1` |
| 2 | Answer all questions, press "Submit Feedback" | **Observed defect DEV-FOF-F01:** controller writes `created_by=NULL` into a NOT NULL column → HTTP 500 (submission fails). Tolerate {thankyou page, 500}. |
| 3 | DB check | `SELECT respondent_user_id,is_anonymous,created_by FROM fof_feedback_responses WHERE feedback_form_id=? ` → if a row exists, `respondent_user_id IS NULL` but `is_anonymous=0` (SEC-FOF-002: flag never set); if no row, DEV-FOF-F01 rejected it |

### MT-3 — Soft-delete lifecycle
| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete a form (destroy) | `deleted_at` set; `sys_activity_logs` event `Deleted` |
| 2 | Open trash `/front-office/feedback/trash/view`; restore | `deleted_at` cleared; event `Restored` |
| 3 | Delete again, then force-delete | row removed; event `Deleted`; restoring the id → 404 |

### MT-4 — Permission negative
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as a non-super-admin WITHOUT `frontoffice.feedback.view`; open `/front-office/feedback` | 403 Forbidden |
| 2 | Grant `frontoffice.feedback.view`, clear permission cache, reload | index renders |

---

## 6. Known Source Defects (proving tests)

| ID | Sev | Summary | Current source truth | Proving test |
|----|-----|---------|----------------------|--------------|
| SEC-FOF-002 | P1 | `is_anonymous_allowed` handling (BR-FOF-010) | Source now uses `respondent_user_id = is_anonymous_allowed ? null : auth()->id()` — **appears partially remediated**; BUT the `is_anonymous` column is never set (stays 0) and the semantics are all-or-nothing (form-level), not a per-respondent choice | `test_feedback_24_*`, `test_feedback_26_*` |
| DEV-FOF-F01 | P1 (new) | `publicSubmit` passes `created_by=NULL`/`updated_by=NULL` (anonymous branch, and `auth()->id()` is null on the guest public route) into NOT NULL columns → NOT NULL violation → public submission fails (HTTP 500) | `FeedbackResponse::create([... 'created_by'=>null,'updated_by'=>null ...])`; `fof_feedback_responses.created_by`/`updated_by` are `NOT NULL` | `test_feedback_25_*`, `test_feedback_26_*` |
| DEAD-FOF-001 | P3 | Commented-out expiry guards in `publicForm`/`publicSubmit` referencing a non-existent `expires_at` column | Lines ~178–180 / ~250–254 commented; no `expires_at` in DDL/model | `test_feedback_14_*` |
| (gap) | P3 | No activity log on `store`/`update`/`toggleStatus` (only delete/restore/forceDelete log) | Controller has no `activityLog()` in those methods | documented (MT-1 step 5) |
| (xref-14) | P4 | `description` validated `max:1000` while DDL column is `TEXT` (request stricter than DB — safe, but a divergence) | inline rule vs DDL | `test_feedback_38_*` |
