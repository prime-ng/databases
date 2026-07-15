# std_StudentEdit — Manual Test Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | StudentProfile (`std_`) |
| Feature/Screen | StudentEdit (edit page + per-tab updates + lifecycle) |
| DB scope | **Tenant** (tenant init required) |
| Base URL | `{DUSK_TENANT_URL}/student-profile/student/{id}/edit` |
| Controller | `Modules\StudentProfile\Http\Controllers\StudentController` |
| Primary table | `std_students` (+ `std_student_profiles`, `std_student_addresses`, `std_guardians`, `std_student_guardian_jnt`, `std_student_academic_sessions`, `std_previous_education`, `std_student_documents`, `std_health_profiles`, `std_vaccination_records`) |
| Models | `Student` (SoftDeletes, encrypted `aadhar_id`), `Guardian` (SoftDeletes), `StudentAcademicSession` (**no** SoftDeletes), `StudentHealthProfile` (`std_health_profiles`) |
| Validation | Inline `$request->validate()` (no FormRequest for these routes — GAP-STD-05) |
| Migrations | Central `prime_ai/database/migrations/tenant/2026_06_15_151302_create_std_students_table.php` (module-local dir is empty) |
| CRUD type | Multi-tab edit (login/details/profile/address/parent/session/prev-ed/document/health/vaccination) + lifecycle |
| Soft delete | Student ✅, Guardian ✅, Session ❌ (DDL-STD-12) |
| Pagination | Trash view: 10/page |
| Activity log | Tenant `activity_logs` (`Modules\GlobalMaster\Models\ActivityLog`) — events `Deleted`, `Restored`, `Force Deleted`, `pii_aadhar_updated` (verbatim) |

### Environment prerequisites
- **StudentProfile module must be ENABLED** in `prime_testing/modules_statuses.json` (currently `false` → 404 on every route). Dusk is NOT run here (module disabled).
- `APP_ENV=testing` (CSRF bypass; else 419).
- Tenant seeded at `DUSK_TENANT_URL`; admin `root@tenant.com` / `password` with `tenant.student.*` permissions.

---

## 2. Business Conditions (detail + flows)

**Login update (`PUT /student/{user}/update-login`)** — `name`, `short_name`, `emp_code`, `email` required and unique-except-self; `password` nullable, min 8, confirmed. Blank password ⇒ hash preserved. Success flash: `Student login updated successfully`.

**Details update (`PUT /student/{student}/update-student-details`)** — required `user_id`(exists), `admission_no`(unique-self), `admission_date`, `first_name`, `dob`, `current_status_id`. Address block: `ensureSinglePrimaryAddress()` keeps exactly one primary. Success flash: `Student details updated successfully`.

**Profile update (`PUT /student/{student}/update-profile`)** — dropdown FKs must `exists:sys_dropdown_table,id`. `updateOrCreate` on `std_student_profiles`.

**Session update (`PUT /session/{session}/update`)** — required `academic_session_id`, `class_section_id`, `session_status_id`, `house`, `dis_note`; when status = left/withdrawn, `leaving_date` + `reason_quit` become required. Setting `is_current=1` clears sibling sessions' `is_current`.

**Health update (`PUT /student/{student}/health-profile/update`)** — **no `validate()`**; only present fields are written (finding BC-VAL-09). Blood-group validation lives on the create route `POST /student/create-student-medical-details` (`in:A+,A-,B+,B-,AB+,AB-,O+,O-`, `next_due_date.* >= date_administered.*`).

**Lifecycle** — `DELETE /student/{student}` soft-deletes student+user and logs `Deleted`; `PATCH /student/{id}/restore` restores and logs `Restored`; `DELETE /student/{id}/force-delete` permanently removes (guarded for FK/media) and logs `Force Deleted`; `POST /student/{student}/toggle-status` returns JSON.

**Activity flow:** mutation → `DB::commit()` → `activityLog($subject, '<Event>', [...])` → row in tenant `activity_logs` (`subject_type=Modules\StudentProfile\Models\Student`, `subject_id`, `event`, `user_id`, `properties`).

---

## 3. Manual Test Cases (Step / Action / Expected)

### TC-P01 — Schema truth
| Step | Action | Expected |
|------|--------|----------|
| 1 | `DESCRIBE std_students` | Columns of BC-DB-01 present; `deleted_at` nullable |
| 2 | `SHOW INDEX FROM std_students` | UNIQUE on `admission_no`, `user_id`, `aadhar_id` |
| 3 | Inspect `Student::$casts` | `aadhar_id => encrypted` |
| 4 | Inspect `StudentAcademicSession` traits | No `SoftDeletes` |

### TC-P14 — Blank password preserved
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open edit → Login tab of a student with a user | Fields prefilled |
| 2 | `SELECT password FROM sys_users WHERE id={user}` | note hash H0 |
| 3 | Submit login update leaving password blank | Success flash |
| 4 | Re-query password | Still H0 (unchanged) |

### TC-P15 — Details update persists note
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit details update with a new `note` | `Student details updated successfully` |
| 2 | `SELECT note FROM std_students WHERE id={id}` | equals submitted note |

### TC-SM21 — Destroy soft-deletes + audit
| Step | Action | Expected |
|------|--------|----------|
| 1 | `DELETE /student/{id}` | redirect + success flash |
| 2 | `SELECT deleted_at FROM std_students WHERE id={id}` | not null |
| 3 | `SELECT * FROM activity_logs WHERE subject_id={id} AND event='Deleted'` | ≥1 row (AUD-STD-04 remediated) |

### TC-SM23 / TC-SM24 — Restore / Force delete
| Step | Action | Expected |
|------|--------|----------|
| 1 | Soft-delete then `PATCH /student/{id}/restore` | student row `deleted_at` null; `activity_logs` event `Restored` |
| 2 | Soft-delete then `DELETE /student/{id}/force-delete` | row gone (or handled FK/media error); `activity_logs` event `Force Deleted` |

### TC-N30..N38 — Validation matrix
| TC | Action | Expected |
|----|--------|----------|
| N30 | Details update missing `first_name/dob/current_status_id` | 422 / redirect-with-errors |
| N31 | Login update email = another user's email | 422 (unique) |
| N32 | Login update password `short` | 422 (min:8) |
| N33 | Medical create `blood_group=INVALID` | 422 (in-set) |
| N34 | Session update missing `dis_note/house/status` | 422 |
| N35 | Profile update `religion=999999999` | 422 (exists) |
| N36 | Address update missing `address_type/address` | 422 |
| N37 | Vaccination `next_due_date < date_administered` | 422 |
| N38 | Parent update missing `first_name/gender/mobile_no` | 422 |

### TC-S80 / S81 / S92 — SEC-STD-01
| Step | Action | Expected |
|------|--------|----------|
| 1 | Grep edit `_student-login.blade.php` for `is_super_admin` | **absent** (remediated) |
| 2 | Grep `updateLogin()` body | no `is_super_admin` |
| 3 | POST details update with injected `is_super_admin=1` | ignored; `std_students` has no such column |
| 4 | Grep **create** `_student-login.blade.php` | toggle still present (residual — cross-ref finding) |

### TC-S54 — SEC-STD-02
| Step | Action | Expected |
|------|--------|----------|
| 1 | Grep controller for `Gate::authorize('school-setup.student` | **no match** (remediated) |
| 2 | Grep for `tenant.student.update/delete/restore/forceDelete` | present |

### TC-P82 / P83 — GAP-STD-05 / BUG-STD-P3-02
| Step | Action | Expected |
|------|--------|----------|
| 1 | List `Modules/StudentProfile/app/Http/Requests` | only `StudentLeaveTypeRequest.php` |
| 2 | Check `resources/views/student/edit.blade.bkp` | file exists (defect) |

### TC-T90 / TC-S91 — Tenancy / XSS
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/student/987654321/edit` | no student data rendered (404-ish) |
| 2 | Save `note = <script>…</script>`, re-open details tab | payload escaped, not executed |
