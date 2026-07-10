# Student Leave Management — Manual Test Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | StudentProfile |
| Feature / Screen | StudentLeave (admin / class-teacher side) |
| URL (index) | `/student-profile/student-leave` (tabs: `?tab=leave-type|application-review|documents|leave-remarks`) |
| Review page | `GET /student-profile/student-leave/{id}/review` |
| Update review | `PUT /student-profile/student-leave/{id}/update-review` |
| Edit page | `GET /student-profile/student-leave/{id}/edit` |
| Update | `PUT /student-profile/student-leave/{id}/update` |
| Remark store | `POST /student-profile/student-leave/remarks/store` |
| AJAX students | `GET /student-profile/ajax/student-leave/students?section_id=` |
| AJAX applications | `GET /student-profile/ajax/student-leave/applications?student_id=` |
| Controller | `StdLeaveController` (index, review, updateReview, edit, update, getStudentsBySection, getApplicationsByStudent, storeRemark) |
| Service | `LeaveService` (review, updateApplication, markAttendanceOnApproval, transition, createAndSubmit, cancel, respondTo*) |
| Models | `LeaveApplication`, `LeaveApplicationDocument`, `LeaveApplicationRemark`, `LeaveType` |
| Policy | `LeaveApplicationPolicy` (viewAny/view/create/update/review/delete/restore/forceDelete) |
| Tables | `std_leave_applications`, `std_leave_application_documents`, `std_leave_application_remarks` |
| Validation | Inline `$request->validate()` in controller (no dedicated FormRequest for this screen) |
| Migrations | `database/migrations/tenant/2026_06_15_1513*_create_std_leave_*` (module dir empty — 05_ #26) |
| CRUD type | Workflow review + edit + threaded remarks (not classic modal CRUD) |
| Soft delete | Applications & documents: yes; Remarks: **no** (permanent audit trail) |
| Pagination | Applications list 15/page (`leave_applications_page`); leave types 10/page |
| Activity log | Tenant `activity_logs` (`Modules\GlobalMaster\Models\ActivityLog`); events: `Remark Added`, `Reviewed`, `Updated` |
| DB scope | TENANT (requires tenant init) |
| Prerequisite | StudentProfile module ENABLED in `modules_statuses.json`; `APP_ENV=testing` for CSRF bypass |

---

## 2. Business Conditions (detailed)

### Status FSM (`std_leave_applications.status`)
```
Draft ──submit──▶ Submitted ──open──▶ Under Review
                     ▲                     │
                     │            ┌────────┼───────────────┐
        student      │        approve   reject      request info/doc
        responds ────┘           │        │               │
                                 ▼        ▼               ▼
                             Approved  Rejected   Info/Doc Requested
                             (attendance                 │  student responds
                              → 'Leave')         ────────┘  → Submitted (re-review)

Cancel (student, portal side) from {Draft, Submitted, Info Requested, Doc Requested} → Cancelled
```
**This screen** reaches the FSM only through `updateReview` (target ∈ {Under Review, Approved, Rejected, Info Requested, Doc Requested}). `Draft`, `Submitted`, `Cancelled` are NOT valid targets of `updateReview` (rejected at validation).

### Key error messages (verbatim)
- Finalized chat: `Chat is disabled for finalized applications.` (403)
- Empty remark: `Please provide a message or attach a file.` (422)
- Overlap: `A leave application already exists for the selected date range.`

### Auto-update flow — approval → attendance
```
updateReview(status=Approved)
   → LeaveService::review()  sets reviewed_by, reviewed_at, approved_days(=total_days if omitted)
   → transition(Approved)    updates status + inserts status_change remark
   → markAttendanceOnApproval()
        for each day in [from_date .. from_date + approved_days):
            std_student_attendance.updateOrCreate(status='Leave', remarks='Leave approved — Application #{id}')
```

### Known defects to exercise
- **GAP-STD-06** (audit): reported Gate::authorize commented out. Verified current source has them ACTIVE → appears remediated. Manual step: log in as a non-super-admin user WITHOUT `tenant.student-leave.*` permissions and confirm whether the index/updateReview is blocked (expected 403 if remediated).
- **BUG-STD-14** (new): `remark_type` stored value normalises to DDL case (`Comment`), not the lowercase model constant (`comment`).
- **BUG-STD-15** (new): approving then re-submitting the review to Rejected is accepted (no FSM source guard).

---

## 3. Test Cases (step-by-step)

### TC-P01 — Schema truth
| Step | Action | Expected |
|------|--------|----------|
| 1 | `SHOW TABLES LIKE 'std_leave_%'` | 3 tables: applications, documents, remarks |
| 2 | `SHOW COLUMNS FROM std_leave_applications` | status/half_day_slot/approved_days/reviewed_by/deleted_at present |
| 3 | `SHOW COLUMNS FROM std_leave_application_remarks` | NO `deleted_at` column |
| 4 | Inspect status ENUM | exactly the 8 values, case as DDL |

### TC-N10 — Chat blocked on finalized application
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed an application with status `Approved` | row exists |
| 2 | `POST /student-profile/student-leave/remarks/store` with `leave_application_id`, `message` | HTTP 403 |
| 3 | Read JSON body | `message` = `Chat is disabled for finalized applications.` |
| 4 | `SELECT COUNT(*) FROM std_leave_application_remarks WHERE leave_application_id=? AND remark_type='comment'` | 0 new comment |

### TC-N11 — Remark requires message or file
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed application status `Submitted` | row exists |
| 2 | POST remark with empty `message`, no file | HTTP 422 |
| 3 | JSON body | `Please provide a message or attach a file.` |

### TC-P12 — Add teacher comment
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST remark with `message` on a Submitted app | HTTP 200/302 success |
| 2 | `SELECT is_from_teacher, remarked_by FROM std_leave_application_remarks WHERE leave_application_id=? ORDER BY id DESC LIMIT 1` | `is_from_teacher=1`, `remarked_by=<admin id>` |
| 3 | `SELECT event FROM activity_logs WHERE subject_id=? AND event='Remark Added'` | 1 row |

### TC-P13 — Approval auto-marks attendance
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed Submitted app for a student with a current session | row exists |
| 2 | `PUT .../update-review` with `status=Approved, approved_days=total_days` | success |
| 3 | `SELECT status FROM std_leave_applications WHERE id=?` | `Approved` |
| 4 | `SELECT COUNT(*) FROM std_student_attendance WHERE student_id=? AND status='Leave'` | ≥ 1 |

### TC-P14 / TC-P15 — approved_days default + reviewer stamp
| Step | Action | Expected |
|------|--------|----------|
| 1 | Approve without `approved_days` | success |
| 2 | `SELECT approved_days, total_days, reviewed_by, reviewed_at` | approved_days=total_days; reviewer & timestamp not null |
| 3 | `SELECT event FROM activity_logs WHERE event='Reviewed'` | 1 row |

### TC-P16 / TC-N17 — Update application + overlap guard
| Step | Action | Expected |
|------|--------|----------|
| 1 | Edit a Submitted app; change reason/dates via `PUT .../update` | success; reason updated |
| 2 | `SELECT * FROM std_leave_application_remarks WHERE remark_type='status_change'` | change-log remark present |
| 3 | `activity_logs` event `Updated` | 1 row |
| 4 | Seed a second app on an adjacent range; update it ONTO the first range | rejected (back with errors); range not persisted |

### TC-SM20..25 — Legal transitions
For each (source → target): seed app in source status → `PUT .../update-review status=<target>` → success → `SELECT status` = target → a `status_change` remark with matching `old_status`/`new_status` exists. Approve also creates attendance.

### TC-SM26/27 — Illegal targets rejected by validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | `PUT .../update-review status=Cancelled` | 422 |
| 2 | `status=Submitted` / `Draft` / `Foobar` | 422 each |
| 3 | `SELECT status` | unchanged |

### TC-SM28 — BUG-STD-15 (no source guard)
| Step | Action | Expected (current, defective) |
|------|--------|-------------------------------|
| 1 | Seed app status `Approved` | row exists |
| 2 | `PUT .../update-review status=Rejected` | **accepted** (200/302) — should be blocked |
| 3 | `SELECT status` | `Rejected` (illegal move persisted) → defect confirmed |

### TC-N30..N39 — Validation matrix (`updateReview` + `update`)
Each row: authenticate as admin, POST the malformed payload → expect HTTP 422.
| Case | Field / rule | Payload | Expect |
|------|--------------|---------|--------|
| N30 | status required | omit status | 422 |
| N31 | status whitelist | `status=approved` (lowercase) | 422 |
| N32 | review_remarks ≤1000 | 1001 chars | 422 |
| N33 | approved_days ≤ total | total+5 | 422 |
| N34 | approved_days ≥0 | −1 | 422 |
| N35 | leave_type_id req/exists | omit / 99999999 | 422 |
| N36 | to_date ≥ from_date | reversed | 422 |
| N37 | total_days ≥1 | 0 | 422 |
| N38 | reason req/≤2000 | '' / 2001 chars | 422 |
| N39 | half_day_slot in Morning,Afternoon; description ≤255 | 'Evening'; 256 chars | 422 |

### TC-N40..43 — Not-found / FK
| Case | Action | Expect |
|------|--------|--------|
| N40 | GET review id 99999999 | 404 |
| N41 | PUT update-review id 99999999 | 404 |
| N42 | PUT update id 99999999 | 404 |
| N43 | storeRemark leave_application_id 99999999 | 422 |

### TC-D44..46 — FK integrity
| Case | Action | Expect |
|------|--------|--------|
| D44 | Confirm `student_id` FK CASCADE (metadata); app row present | column present |
| D45 | Confirm `reviewed_by` FK SET NULL (metadata) | column present |
| D46 | Force-delete an application with a child remark | remark cascade-deleted |

### TC-N50 / TC-S51 / TC-S52 — Authorization
| Case | Action | Expect |
|------|--------|--------|
| N50 | Visit index as guest | redirect `/login` |
| S51 (GAP-STD-06) | Log in as limited non-super user w/o `tenant.student-leave.*`, GET index | observe status — **403 if remediated**; 200/302 would reproduce the audit defect |
| S52 (GAP-STD-06) | Same user PUT update-review | observe status (expected 403) |
| P53 | Super-admin GET index | tabs render (Gate::before bypass) |

### TC-P60..65 — UI/UX
Render index (4 tabs `#leave-type-tab`/`#application-review-tab`/`#documents-tab`/`#leave-remarks-tab`), review-page form (`input[name=status]`, `textarea[name=review_remarks]`, `input[name=approved_days]`), edit page prefill, status filter, empty state.

### TC-EDG70 — BUG-STD-14 (enum case)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Insert remark with `remark_type='comment'` (model constant) | inserted |
| 2 | `SELECT remark_type FROM std_leave_application_remarks WHERE id=?` | `Comment` (DDL case) — NOT `comment` |
| 3 | Compare stored value `=== LeaveApplicationRemark::TYPE_COMMENT` | FALSE → defect confirmed |

### TC-T90 / TC-S91 / TC-S92 — Tenancy & Security
| Case | Action | Expect |
|------|--------|--------|
| T90 | GET review with out-of-range id 2147480000 | 404 (IDOR unreachable) |
| S91 | Set review_remarks to `<script>` payload, re-render review page | payload escaped, not executed |
| S92 | PUT update with extra `status=Approved` | status ignored; unchanged |
