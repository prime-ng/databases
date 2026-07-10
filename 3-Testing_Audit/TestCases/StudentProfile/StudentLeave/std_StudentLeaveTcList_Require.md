# Student Leave Management — Test Case List & Business Conditions

**Module:** StudentProfile  **Feature/Screen:** StudentLeave  **Prefix:** `std_`
**Primary table:** `std_leave_applications` (+ `std_leave_application_documents`, `std_leave_application_remarks`)
**DB scope:** TENANT  **Controller:** `Modules\StudentProfile\Http\Controllers\StdLeaveController`
**Service:** `Modules\StudentProfile\Services\LeaveService`  **Policy:** `LeaveApplicationPolicy`
**Requirement:** `StudentProfile_v2/BRD-05_Student_Leave_Management.md`
**Test file:** `std_StudentLeave_TestCas.php` (class `std_StudentLeave_TestCas`, ONE file per screen)
**URL prefix:** `/student-profile`

> This screen is the **admin/class-teacher side** of the leave workflow (review, edit, remarks, document/remark tabs). Student-side application submission/cancellation lives in the Student Portal and is out of this screen's scope; the FSM transitions reachable here are those exposed by `StdLeaveController` (`updateReview` → `LeaveService::review()`, `update`, `storeRemark`).

---

## 1. Business Conditions

### BC-DB — Schema (Source: `DDL-std_leave_applications` / `_documents` / `_remarks`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `std_leave_applications` has status ENUM `('Draft','Submitted','Under Review','Info Requested','Doc Requested','Approved','Rejected','Cancelled')` DEFAULT `'Draft'` | DDL-std_leave_applications |
| BC-DB-02 | `is_half_day` TINYINT(1) default 0; `half_day_slot` ENUM('Morning','Afternoon') NULL | DDL-std_leave_applications |
| BC-DB-03 | `total_days` / `approved_days` TINYINT UNSIGNED; `approved_days` NULL until reviewed | DDL-std_leave_applications |
| BC-DB-04 | SoftDeletes on applications + documents; `std_leave_application_remarks` has **no** `deleted_at` (permanent audit trail) | DDL |
| BC-DB-05 | `std_leave_application_remarks.remark_type` ENUM `('Comment','Info_Request','Doc_Request','Response','Status_Change')` DEFAULT `'Comment'` | DDL-std_leave_application_remarks |
| BC-DB-06 | FK `fk_la_student` ON DELETE **CASCADE**; `fk_la_session`/`fk_la_class_section`/`fk_la_leave_type`/`fk_la_applied_by` ON DELETE **RESTRICT**; `fk_la_reviewed_by` ON DELETE **SET NULL** | DDL-std_leave_applications |
| BC-DB-07 | `fk_lad_application` & `fk_lar_application` ON DELETE **CASCADE** (docs/remarks removed with the application) | DDL |

### BC-VAL — Validation (Source: controller inline `validate()`)
| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | `updateReview.status` required, `in:Under Review,Approved,Rejected,Info Requested,Doc Requested` (case-exact) | StdLeaveController::updateReview |
| BC-VAL-02 | `updateReview.review_remarks` nullable string max 1000 | updateReview |
| BC-VAL-03 | `updateReview.approved_days` nullable integer `min:0` `max:{total_days}` | updateReview |
| BC-VAL-04 | `update.leave_type_id` required `exists:std_leave_types,id` | update |
| BC-VAL-05 | `update.from_date` required date; `to_date` required date `after_or_equal:from_date` | update |
| BC-VAL-06 | `update.total_days` required integer `min:1` | update |
| BC-VAL-07 | `update.reason` required string max 2000 | update |
| BC-VAL-08 | `update.half_day_slot` nullable `in:Morning,Afternoon`; `is_half_day` nullable boolean | update |
| BC-VAL-09 | `storeRemark.leave_application_id` required `exists:std_leave_applications,id` | storeRemark |
| BC-VAL-10 | `storeRemark.attachments.*` nullable file max 5120 (5 MB); `document_type_id` exists:sys_dropdown_table,id; `description` max 255 | storeRemark |

### BC-AUTH — Authorization (Source: `Screen-PM` §4 / Policy / Controller Gates)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `index` → `Gate::authorize('tenant.student-leave.viewAny')` | StdLeaveController::index |
| BC-AUTH-02 | `getStudentsBySection` / `getApplicationsByStudent` → `tenant.student-leave.view` | controller |
| BC-AUTH-03 | `review` (page) → `tenant.student-leave.review` | controller |
| BC-AUTH-04 | `updateReview` / `edit` / `update` / `storeRemark` → `tenant.student-leave.update` | controller |
| BC-AUTH-05 | `Gate::before` grants ALL abilities to Super Admin (`is_super_admin && super_admin_flag`, or role `Super Admin`) | app/Providers/AppServiceProvider.php:64 |
| BC-AUTH-06 | Guest → redirect to `/login` | web middleware |

### BC-BIZ — Business logic / activity log (Source: Service + Controller + Screen-BR)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | On approval, `markAttendanceOnApproval` upserts `std_student_attendance` rows with status `'Leave'` for the approved range (BR-04, FR-28) | LeaveService::markAttendanceOnApproval |
| BC-BIZ-02 | `approved_days` defaults to `total_days` when omitted (FR-19) | LeaveService::review |
| BC-BIZ-03 | Review stamps `reviewed_by = auth()->id()` and `reviewed_at = now()` | LeaveService::review |
| BC-BIZ-04 | `storeRemark` blocks chat when status ∈ {Approved, Rejected, Cancelled} → 403 `"Chat is disabled for finalized applications."` | storeRemark |
| BC-BIZ-05 | `storeRemark` with neither message nor file → 422 `"Please provide a message or attach a file."` | storeRemark |
| BC-BIZ-06 | `storeRemark` creates a `comment` remark with `is_from_teacher = true`, `remarked_by = auth id` | storeRemark |
| BC-BIZ-07 | `update()` writes a `status_change` audit remark listing field changes when any field differs | LeaveService::updateApplication |
| BC-BIZ-08 | Overlapping (non-cancelled/rejected) date range rejected on `update()` (InvalidArgumentException → back w/ errors) | LeaveService::updateApplication |
| BC-BIZ-09 | Activity-log events (verbatim): `Remark Added` (storeRemark), `Reviewed` (updateReview), `Updated` (update) | controller `activityLog()` |

### BC-SM — State machine (Source: `Screen-SM` §6/§7, DDL FSM header, `LeaveService::review`/`transition`)
| ID | State → Trigger → Next | Legal? | Source |
|----|------------------------|--------|--------|
| BC-SM-01 | Submitted → updateReview(Under Review) → Under Review | ✅ | Screen-SM Step3 |
| BC-SM-02 | Submitted → updateReview(Approved) → Approved (+ attendance) | ✅ | Screen-SM Step4 |
| BC-SM-03 | Submitted → updateReview(Rejected) → Rejected | ✅ | Screen-SM Step4 |
| BC-SM-04 | Submitted → updateReview(Info Requested) → Info Requested | ✅ | Screen-SM Step4 |
| BC-SM-05 | Submitted → updateReview(Doc Requested) → Doc Requested | ✅ | Screen-SM Step4 |
| BC-SM-06 | Under Review → updateReview(Approved) → Approved | ✅ | Screen-SM Step4 |
| BC-SM-07 | Any → updateReview(**Cancelled**) → REJECTED by validation (not in whitelist) | ⛔ (guarded by BC-VAL-01) | updateReview |
| BC-SM-08 | Any → updateReview(**Submitted**/**Draft**/invalid) → REJECTED by validation | ⛔ (guarded) | updateReview |
| BC-SM-09 | Every accepted transition auto-logs a `status_change` remark with `old_status`/`new_status` | ✅ | LeaveService::transition |
| BC-SM-10 | **DEFECT (BUG-STD-15):** `updateReview`/`review()` validates only the TARGET status, never the SOURCE. Illegal moves (e.g. **Approved → Rejected**, Rejected → Approved) are **accepted** — no FSM source-state guard | ⚠️ permissive | LeaveService::review (no guard) |

### BC-INT / BC-REF — Integration & FK (Source: DDL FKs + BRD §9)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | Deleting a student cascades its leave applications (fk_la_student CASCADE) | DDL |
| BC-REF-02 | Deleting a reviewer user nulls `reviewed_by` (SET NULL) | DDL |
| BC-REF-03 | Force-deleting an application cascades its remarks & documents | DDL |
| BC-INT-01 | Approval writes into the Attendance module (`std_student_attendance`) — cross-feature (BRD-04) | LeaveService |
| BC-INT-02 | AJAX `students`/`applications` feed the Remarks/Documents tab selectors | controller |

### BC-EDG — Edge / boundary
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `approved_days == total_days` boundary accepted | BC-VAL-03 |
| BC-EDG-02 | Whitespace-only `review_remarks` passes (nullable, no trim) | BC-VAL-02 |
| BC-EDG-03 | **BUG-STD-14:** `remark_type` written as lowercase model constant (`'comment'`) is stored/read back as DDL case (`'Comment'`) → strict PHP comparison fails | DDL vs Model |

---

## 2. Test Case List

### Positive (`TC-P`)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01..07 | DDL | Schema truth: 3 tables, columns, status ENUM, migration file | tables/cols present | `test_..._01` | ✅ |
| TC-P02 | BC-DB-01 | Model | LeaveApplication config: table/fillable/casts/SoftDeletes/status constants/relations | asserts pass | `test_..._02` | ✅ |
| TC-P03 | BC-DB-04/05 | Model | Remark (no soft-delete, type constants) + Document (soft-delete + media) | asserts pass | `test_..._03` | ✅ |
| TC-P04 | — | routes | All 8 route names registered | `Route::has` true | `test_..._04` | ✅ |
| TC-P05 | BC-AUTH | Policy | Policy exposes 8 abilities | methods exist | `test_..._05` | ✅ |
| TC-P12 | BC-BIZ-06/09 | storeRemark | Valid comment persists (teacher) + `Remark Added` logged | created + logged | `test_..._12` | ✅ |
| TC-P13 | BC-BIZ-01 | Service | Approval auto-marks attendance `Leave` | rows created | `test_..._13` | ✅ |
| TC-P14 | BC-BIZ-02 | Service | approved_days defaults to total_days | equal | `test_..._14` | ✅ |
| TC-P15 | BC-BIZ-03/09 | Service | Review stamps reviewer + `Reviewed` logged | stamped | `test_..._15` | ✅ |
| TC-P16 | BC-BIZ-07/09 | Service | update() logs change + `Updated` | logged | `test_..._16` | ✅ |
| TC-P47 | BC-INT-02 | ajax | applications JSON list | 200 + array | `test_..._47` | ✅ |
| TC-P48 | BC-INT-02 | ajax | students JSON list | 200 + array | `test_..._48` | ✅ |
| TC-P53 | BC-AUTH-05 | Gate::before | Super-admin reaches index | tabs render | `test_..._53` | ✅ |
| TC-P54 | BC-AUTH | Policy | Policy references tenant.student-leave.* | strings present | `test_..._54` | ✅ |
| TC-P60 | UIX | Blade | Index renders 4 tabs | present | `test_..._60` | ✅ |
| TC-P61 | UIX | Blade | Application-review tab renders | present | `test_..._61` | ✅ |
| TC-P62 | UIX | Blade | Review page form renders | present | `test_..._62` | ✅ |
| TC-P63 | UIX | Blade | Edit page prefilled | reason shown | `test_..._63` | ✅ |
| TC-P64 | UIX | Blade | Status filter renders | present | `test_..._64` | ✅ |
| TC-P65 | UIX | Blade | Empty state renders | present | `test_..._65` | ✅ |

### State-Machine (`TC-SM`)
| TC ID | BC-SM | Description | Expected | Method | Status |
|-------|-------|-------------|----------|--------|--------|
| TC-SM20 | BC-SM-01 | Submitted → Under Review | success, status=Under Review | `test_..._20` | ✅ |
| TC-SM21 | BC-SM-02/09 | Submitted → Approved + status_change remark | success | `test_..._21` | ✅ |
| TC-SM22 | BC-SM-03 | Submitted → Rejected | success | `test_..._22` | ✅ |
| TC-SM23 | BC-SM-04 | Submitted → Info Requested | success | `test_..._23` | ✅ |
| TC-SM24 | BC-SM-05 | Submitted → Doc Requested | success | `test_..._24` | ✅ |
| TC-SM25 | BC-SM-06 | Under Review → Approved | success | `test_..._25` | ✅ |
| TC-SM26 | BC-SM-07 | → Cancelled rejected (422) | 422 | `test_..._26` | ✅ |
| TC-SM27 | BC-SM-08 | → Submitted/Draft/invalid rejected (422) | 422 | `test_..._27` | ✅ |
| TC-SM28 | BC-SM-10 | **BUG-STD-15** Approved → Rejected accepted (no guard) | accepted (proves defect) | `test_..._28` | ⚠️ |
| TC-SM29 | BC-SM-09 | Transition auto-logs status_change w/ old/new | remark present | `test_..._29` | ✅ |

### Negative (`TC-N`)
| TC ID | BC | Description | Expected | Method | Status |
|-------|----|-------------|----------|--------|--------|
| TC-N10 | BC-BIZ-04 | storeRemark on finalized → 403 exact msg | 403 | `test_..._10` | ✅ |
| TC-N11 | BC-BIZ-05 | storeRemark empty → 422 exact msg | 422 | `test_..._11` | ✅ |
| TC-N17 | BC-BIZ-08 | update() overlapping range rejected | back/errors | `test_..._17` | ✅ |
| TC-N30 | BC-VAL-01 | updateReview status required | 422 | `test_..._30` | ✅ |
| TC-N31 | BC-VAL-01 | updateReview status invalid/lowercase | 422 | `test_..._31` | ✅ |
| TC-N32 | BC-VAL-02 | review_remarks > 1000 | 422 | `test_..._32` | ✅ |
| TC-N33 | BC-VAL-03 | approved_days > total_days | 422 | `test_..._33` | ✅ |
| TC-N34 | BC-VAL-03 | approved_days negative | 422 | `test_..._34` | ✅ |
| TC-N35 | BC-VAL-04 | update leave_type_id required/exists | 422 | `test_..._35` | ✅ |
| TC-N36 | BC-VAL-05 | update to_date < from_date | 422 | `test_..._36` | ✅ |
| TC-N37 | BC-VAL-06 | update total_days < 1 | 422 | `test_..._37` | ✅ |
| TC-N38 | BC-VAL-07 | update reason required / > 2000 | 422 | `test_..._38` | ✅ |
| TC-N39 | BC-VAL-08/10 | half_day_slot invalid; description > 255 | 422 | `test_..._39` | ✅ |
| TC-N40 | BC-REF | review invalid id → 404 | 404 | `test_..._40` | ✅ |
| TC-N41 | BC-REF | updateReview invalid id → 404 | 404 | `test_..._41` | ✅ |
| TC-N42 | BC-REF | update invalid id → 404 | 404 | `test_..._42` | ✅ |
| TC-N43 | BC-VAL-09 | storeRemark non-existent application → 422 | 422 | `test_..._43` | ✅ |
| TC-N50 | BC-AUTH-06 | Guest redirected to /login | /login | `test_..._50` | ✅ |

### Dependency (`TC-D`)
| TC ID | Sub | BC | Description | Method | Status |
|-------|-----|----|-------------|--------|--------|
| TC-D44 | B/C | BC-REF-01 | Student delete cascades applications (metadata + defensive) | `test_..._44` | ✅ |
| TC-D45 | D | BC-REF-02 | reviewed_by SET NULL (metadata) | `test_..._45` | ✅ |
| TC-D46 | B | BC-REF-03 | remarks cascade on force-delete | `test_..._46` | ✅ |

### Tenancy / Security (`TC-T` / `TC-S`)
| TC ID | BC | Description | Method | Status |
|-------|----|-------------|--------|--------|
| TC-S51 | BC-AUTH-01/05 | **GAP-STD-06** limited-user index probe (observed status, no assumption) | `test_..._51` | ✅ |
| TC-S52 | BC-AUTH-04/05 | **GAP-STD-06** limited-user updateReview probe | `test_..._52` | ✅ |
| TC-EDG70 | BC-EDG-03 | **BUG-STD-14** remark_type enum-case mismatch proof | `test_..._70` | ⚠️ |
| TC-EDG71 | BC-EDG-02 | whitespace review_remarks accepted | `test_..._71` | ✅ |
| TC-EDG72 | BC-EDG-01 | approved_days == total_days boundary | `test_..._72` | ✅ |
| TC-T90 | BC-AUTH | IDOR out-of-range id → 404 | `test_..._90` | ✅ |
| TC-S91 | Security | Stored XSS in review_remarks escaped | `test_..._91` | ✅ |
| TC-S92 | Security | Mass-assignment: status not forceable via update() | `test_..._92` | ✅ |

---

## 3. Test Method Index

| # | Method (band) | TC Map | Category | Band |
|---|---------------|--------|----------|------|
| 1 | `test_student_leave_01_schema_tables_columns_and_status_enum` | TC-P01 | Schema | 01-09 |
| 2 | `test_student_leave_02_leave_application_model_configuration` | TC-P02 | Schema | 01-09 |
| 3 | `test_student_leave_03_remark_and_document_model_configuration` | TC-P03 | Schema | 01-09 |
| 4 | `test_student_leave_04_routes_registered` | TC-P04 | Config | 01-09 |
| 5 | `test_student_leave_05_policy_abilities_present` | TC-P05 | Auth | 01-09 |
| 6 | `test_student_leave_10_store_remark_blocked_on_finalized_application` | TC-N10 | BC-BIZ | 10-19 |
| 7 | `test_student_leave_11_store_remark_requires_message_or_file` | TC-N11 | BC-BIZ | 10-19 |
| 8 | `test_student_leave_12_store_remark_creates_teacher_comment_and_logs_activity` | TC-P12 | BC-BIZ | 10-19 |
| 9 | `test_student_leave_13_approval_auto_marks_attendance_leave` | TC-P13 | BC-BIZ | 10-19 |
| 10 | `test_student_leave_14_approved_days_defaults_to_total_days` | TC-P14 | BC-BIZ | 10-19 |
| 11 | `test_student_leave_15_review_sets_reviewer_and_timestamp` | TC-P15 | BC-BIZ | 10-19 |
| 12 | `test_student_leave_16_update_application_logs_change_and_activity` | TC-P16 | BC-BIZ | 10-19 |
| 13 | `test_student_leave_17_update_rejects_overlapping_range` | TC-N17 | BC-BIZ | 10-19 |
| 14 | `test_student_leave_20_transition_submitted_to_under_review` | TC-SM20 | BC-SM | 20-29 |
| 15 | `test_student_leave_21_transition_submitted_to_approved` | TC-SM21 | BC-SM | 20-29 |
| 16 | `test_student_leave_22_transition_submitted_to_rejected` | TC-SM22 | BC-SM | 20-29 |
| 17 | `test_student_leave_23_transition_submitted_to_info_requested` | TC-SM23 | BC-SM | 20-29 |
| 18 | `test_student_leave_24_transition_submitted_to_doc_requested` | TC-SM24 | BC-SM | 20-29 |
| 19 | `test_student_leave_25_transition_under_review_to_approved` | TC-SM25 | BC-SM | 20-29 |
| 20 | `test_student_leave_26_transition_to_cancelled_rejected_by_validation` | TC-SM26 | BC-SM | 20-29 |
| 21 | `test_student_leave_27_transition_to_submitted_or_draft_rejected` | TC-SM27 | BC-SM | 20-29 |
| 22 | `test_student_leave_28_no_source_state_guard_allows_illegal_reapproval` | TC-SM28 / BUG-STD-15 | BC-SM | 20-29 |
| 23 | `test_student_leave_29_transition_autologs_status_change_remark` | TC-SM29 | BC-SM | 20-29 |
| 24 | `test_student_leave_30_update_review_status_required` | TC-N30 | BC-VAL | 30-39 |
| 25 | `test_student_leave_31_update_review_status_invalid` | TC-N31 | BC-VAL | 30-39 |
| 26 | `test_student_leave_32_update_review_remarks_max_1000` | TC-N32 | BC-VAL | 30-39 |
| 27 | `test_student_leave_33_update_review_approved_days_over_total` | TC-N33 | BC-VAL | 30-39 |
| 28 | `test_student_leave_34_update_review_approved_days_negative` | TC-N34 | BC-VAL | 30-39 |
| 29 | `test_student_leave_35_update_leave_type_required_and_exists` | TC-N35 | BC-VAL | 30-39 |
| 30 | `test_student_leave_36_update_to_date_before_from_date` | TC-N36 | BC-VAL | 30-39 |
| 31 | `test_student_leave_37_update_total_days_min_one` | TC-N37 | BC-VAL | 30-39 |
| 32 | `test_student_leave_38_update_reason_required_and_max` | TC-N38 | BC-VAL | 30-39 |
| 33 | `test_student_leave_39_half_day_slot_and_description_bounds` | TC-N39 | BC-VAL | 30-39 |
| 34 | `test_student_leave_40_review_invalid_id_404` | TC-N40 | BC-REF | 40-49 |
| 35 | `test_student_leave_41_update_review_invalid_id_404` | TC-N41 | BC-REF | 40-49 |
| 36 | `test_student_leave_42_update_invalid_id_404` | TC-N42 | BC-REF | 40-49 |
| 37 | `test_student_leave_43_store_remark_application_must_exist` | TC-N43 | BC-VAL | 40-49 |
| 38 | `test_student_leave_44_student_delete_cascades_applications` | TC-D44 | BC-REF | 40-49 |
| 39 | `test_student_leave_45_reviewed_by_set_null_metadata` | TC-D45 | BC-REF | 40-49 |
| 40 | `test_student_leave_46_children_cascade_on_application_force_delete` | TC-D46 | BC-REF | 40-49 |
| 41 | `test_student_leave_47_ajax_applications_returns_json` | TC-P47 | BC-INT | 40-49 |
| 42 | `test_student_leave_48_ajax_students_returns_json` | TC-P48 | BC-INT | 40-49 |
| 43 | `test_student_leave_50_guest_redirected_to_login` | TC-N50 | BC-AUTH | 50-59 |
| 44 | `test_student_leave_51_gap_std_06_limited_user_index_probe` | TC-S51 / GAP-STD-06 | BC-AUTH | 50-59 |
| 45 | `test_student_leave_52_gap_std_06_limited_user_update_review_probe` | TC-S52 / GAP-STD-06 | BC-AUTH | 50-59 |
| 46 | `test_student_leave_53_super_admin_can_access_index` | TC-P53 | BC-AUTH | 50-59 |
| 47 | `test_student_leave_54_policy_permission_namespace` | TC-P54 | BC-AUTH | 50-59 |
| 48 | `test_student_leave_60_index_renders_four_tabs` | TC-P60 | UIX | 60-69 |
| 49 | `test_student_leave_61_application_review_tab_lists_application` | TC-P61 | UIX | 60-69 |
| 50 | `test_student_leave_62_review_page_renders_form` | TC-P62 | UIX | 60-69 |
| 51 | `test_student_leave_63_edit_page_prefilled` | TC-P63 | UIX | 60-69 |
| 52 | `test_student_leave_64_index_status_filter` | TC-P64 | UIX | 60-69 |
| 53 | `test_student_leave_65_index_empty_state` | TC-P65 | UIX | 60-69 |
| 54 | `test_student_leave_70_bug_std_14_remark_type_enum_case_mismatch` | TC-EDG70 / BUG-STD-14 | BC-EDG | 70-79 |
| 55 | `test_student_leave_71_review_remarks_whitespace_accepted` | TC-EDG71 | BC-EDG | 70-79 |
| 56 | `test_student_leave_72_approved_days_equal_total_boundary` | TC-EDG72 | BC-EDG | 70-79 |
| 57 | `test_student_leave_90_idor_out_of_range_id_not_reachable` | TC-T90 | Tenancy | 90-99 |
| 58 | `test_student_leave_91_review_remarks_xss_escaped` | TC-S91 | Security | 90-99 |
| 59 | `test_student_leave_92_update_cannot_force_status` | TC-S92 | Security | 90-99 |

**Total: 59 test methods.**

---

## 4. Known Source Defects (audit + discovered)

| ID | Title | Severity | Proving test | Notes |
|----|-------|----------|--------------|-------|
| GAP-STD-06 | StdLeaveController `Gate::authorize` reportedly commented out | P1 (audit) | `test_..._51`, `test_..._52` | **Appears REMEDIATED** — current source has active `Gate::authorize` on all 8 methods. Tests probe observed behaviour without assuming 403. |
| BUG-STD-14 | `remark_type` ENUM case mismatch (DDL `'Comment'/'Status_Change'…` vs lowercase model constants) | Medium (new) | `test_..._70` | Cross-Reference check #1. MySQL normalises to DDL case → strict PHP comparisons on the constant silently fail. |
| BUG-STD-15 | No FSM source-state guard in `updateReview`/`LeaveService::review()` | Medium (new) | `test_..._28` | Cross-Reference check #7. Illegal transitions (Approved→Rejected) accepted; only the target status is validated. |
