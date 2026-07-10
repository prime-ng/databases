# Student Leave Type — Manual Test Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | StudentProfile |
| Feature / Screen | Student Leave Type (`std_leave_types`) |
| URL prefix | `/student-profile/student-leave-types` |
| Index (real list) | `/student-profile/student-leave?tab=leave-type` (index() redirects here) |
| Controller | `Modules\StudentProfile\Http\Controllers\StudentLeaveTypeController` |
| Service | `Modules\StudentProfile\Services\LeaveService` |
| FormRequest | `StudentLeaveTypeRequest` |
| Model | `Modules\StudentProfile\Models\LeaveType` (table `std_leave_types`) |
| Policy | `LeaveTypePolicy` (`tenant.leave-type.*`) |
| Migration | `database/migrations/tenant/2026_06_15_151301_create_std_leave_types_table.php` |
| CRUD type | Full page-based CRUD (create/edit are Blade pages, not modals) + JSON toggle |
| Soft delete | Yes (SoftDeletes; delete also sets `is_active=false`) |
| Pagination | 10/page (`student_leave_types_page`) |
| Activity log | tenant `activity_logs`; events: **Created, Updated, Deleted, Restored, Force Deleted, Toggled** |
| Env prerequisite | `StudentProfile` module ENABLED in `modules_statuses.json`; `APP_ENV=testing`; tenant host `test.localhost:8000` |

### Routes (all under `/student-profile`, names `student-profile.student-leave-types.*`)
| Verb | Path | Name | Gate |
|------|------|------|------|
| GET | `/student-leave-types` | `.index` | (none — redirects; see DEV-STD-LT-01) |
| GET | `/student-leave-types/create` | `.create` | `tenant.leave-type.create` |
| POST | `/student-leave-types` | `.store` | `tenant.leave-type.create` |
| GET | `/student-leave-types/{id}` | `.show` | `tenant.leave-type.view` |
| GET | `/student-leave-types/{id}/edit` | `.edit` | `tenant.leave-type.update` |
| PUT | `/student-leave-types/{id}` | `.update` | `tenant.leave-type.update` |
| DELETE | `/student-leave-types/{id}` | `.destroy` | `tenant.leave-type.delete` |
| GET | `/student-leave-types/trash` | `.trashed` | `tenant.leave-type.restore` |
| GET | `/student-leave-types/{id}/restore` | `.restore` | `tenant.leave-type.restore` |
| DELETE | `/student-leave-types/{id}/force-delete` | `.forceDelete` | `tenant.leave-type.forceDelete` |
| POST | `/student-leave-types/{studentLeaveType}/toggle-status` | `.toggleStatus` | `tenant.leave-type.update` |

---

## 2. Business Conditions (detailed)

**Validation (`StudentLeaveTypeRequest`)**
- `code`: required · string · max 30 · unique on `std_leave_types.code` where `deleted_at IS NULL`, ignoring current id on update.
- `name`: required · string · max 100.
- `description`: nullable · string · max 255.
- `max_days_per_application`: required · integer · 0–255 (TINYINT UNSIGNED). Default 30 via `prepareForValidation`.
- `max_days_per_year`: required · integer · 0–65535 (SMALLINT UNSIGNED). Default 0.
- `advance_notice_days`: required · integer · 0–255. Default 0.
- `requires_document` / `allow_half_day` / `is_active`: boolean (checkbox coerced; defaults false / true / true).

**Toggle state machine (JSON `POST .../toggle-status`)**
```
active   --toggle-->  inactive     (event: Toggled)
inactive --toggle-->  active       (event: Toggled)
Response: { "success": true, "is_active": <bool>, "message": "Status updated successfully" }
```

**Delete flow (soft)**
```
destroy(id):  is_active := false  ->  soft delete (deleted_at set)  ->  activityLog "Deleted"
restore(id):  restore()  ->  activityLog "Restored"
forceDelete(id): permanent delete  ->  activityLog "Force Deleted"
FK guard: std_leave_applications.leave_type_id -> std_leave_types.id ON DELETE RESTRICT
          (force-delete of a referenced type is blocked by the DB)
```

**Unique-after-soft-delete:** because the unique key is composite `(code, deleted_at)`, a `code` value can be reused for a new active row once the previous row is soft-deleted.

---

## 3. Manual Test Cases

### MTC-01 — Create a leave type (happy path)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as admin with `tenant.leave-type.create` | Dashboard |
| 2 | Visit `/student-profile/student-leave-types/create` | Create form renders (code, name, description, max/app, max/year, notice, requires_document, allow_half_day, status) |
| 3 | Enter code `SICK1`, name `Sick Leave`, max/app 10, max/year 30, notice 1, submit | Redirect to `student-leave?tab=leave-type`; green toast "Student leave type created successfully" |
| 4 | DB check | `SELECT * FROM std_leave_types WHERE code='SICK1'` → 1 row, `created_by` = acting user id |
| 5 | Activity log | `SELECT * FROM activity_logs WHERE subject_type LIKE '%LeaveType%' AND event='Created'` → row present |

### MTC-02 — Required field validation
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Submit create with empty `code` | Validation error "The Leave Code field is required." (422 / redirect back with errors) |
| 2 | Submit with empty `name` | Error on Leave Name |
| 3 | Submit with existing active `code` | Unique error "The Leave Code has already been taken." |

### MTC-03 — Length & range validation
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `code` = 31 chars | Rejected (max:30) |
| 2 | `name` = 101 chars | Rejected (max:100) |
| 3 | `description` = 256 chars | Rejected (max:255) |
| 4 | `max_days_per_application` = 256 | Rejected (max:255) |
| 5 | `max_days_per_year` = 65536 | Rejected (max:65535) |
| 6 | `advance_notice_days` = 256 | Rejected (max:255) |
| 7 | any numeric = -1 | Rejected (min:0) |
| 8 | boundary 255 / 65535 / 255 | Accepted |

### MTC-04 — Edit / update
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open `/student-leave-types/{id}/edit` | Fields prefilled with current values |
| 2 | Change name, submit | Toast "…updated successfully"; DB name changed |
| 3 | Activity log | event `Updated` present |
| 4 | Keep same code on update | No duplicate error (own id ignored) |

### MTC-05 — Toggle status
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On active row, click status switch | AJAX `POST .../toggle-status` → JSON `{success:true,is_active:false,message:"Status updated successfully"}` |
| 2 | DB check | `is_active=0`; activity `Toggled` present |
| 3 | Toggle again | `is_active=1` |

### MTC-06 — Delete / restore / force-delete
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Delete a row | Soft-deleted; `is_active=0`; toast "…deleted successfully"; activity `Deleted` |
| 2 | Open trash `/student-leave-types/trash` | Deleted row listed with Deleted At |
| 3 | Restore | Row reappears in list; activity `Restored` |
| 4 | Delete again then Force-delete from trash | Row permanently removed (`withTrashed` empty); activity `Force Deleted` |
| 5 | Reuse deleted code for a new active row | Allowed (composite unique on code+deleted_at) |

### MTC-07 — FK RESTRICT (dependency)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a leave application referencing a leave type | Application row created |
| 2 | Attempt force-delete of that leave type | Blocked by `ON DELETE RESTRICT` (DB error / not removed) |

### MTC-08 — Authorization
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Guest visits create page | Redirect to `/login` |
| 2 | User without `tenant.leave-type.create` | 403 on create/store |
| 3 | User without `tenant.leave-type.delete` | 403 on destroy |
| 4 | Confirm each controller method calls `Gate::authorize('tenant.leave-type.*')` | Present for create/view/update/delete/restore/forceDelete |

### MTC-09 — UI / listing
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit leave-type tab | Table columns Code, Name, Description, Max/App, Max/Year, Notice Days, Document, Half Day, Status, Action |
| 2 | Search by code/name | Only matching rows shown |
| 3 | Filter status Active/Inactive | Filtered listing |
| 4 | No records | "No Student Leave Types Found" |

### MTC-10 — Security
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create type with name `XSS<script>alert(1)</script>` | Stored as data; show page renders escaped (no raw `<script>` executes) |
| 2 | Submit `created_by=987654` in the request | Ignored; stored `created_by` = acting user (not attacker value) |
| 3 | show/edit unknown id (99999999) | 404 |
