# FrontOffice → Appointment — Test Case List & Manual Test Spec (COMBINED)

> Single source for: Feature Information + Business Conditions (incl. BC-SM) + Test Case List + Test Method Index + Manual Test Steps (workflow/complex only) + Known Source Defects.
> Prefix `fof_` verified against DDL `CREATE TABLE fof_appointments`. Feature is **tenant-side** (DDL header `Database: tenant_db`).

---

## 1. Feature Information

| Attribute | Value |
|-----------|-------|
| Module | FrontOffice (FOF) |
| Feature | Appointment |
| Primary table | `fof_appointments` |
| URL base | `/front-office/appointments` (route group prefix `front-office`, name `fof.`) |
| Controller | `Modules\FrontOffice\Http\Controllers\AppointmentController` |
| FormRequest | `Modules\FrontOffice\Http\Requests\AppointmentRequest` (store + update; `authorize()` returns `true` — DEV-FOF-A07) |
| Model | `Modules\FrontOffice\Models\Appointment` (extends `App\Models\BaseModel`, `HasFactory`, `SoftDeletes`) |
| Policy | `Modules\FrontOffice\Policies\AppointmentPolicy` (type-hints `Modules\SchoolSetup\Models\User`; controller uses **string gates**, not policy calls) |
| Permission scheme | `frontoffice.appointment.{view,create,update,confirm,cancel,complete,delete,restore,forceDelete}` via `Gate::authorize()` |
| Soft delete | Yes (`deleted_at`); trash / restore / force-delete routes present |
| Pagination | 20 (upcoming + past on index; 20 on trashed) |
| Activity log | Helper `activityLog($model, '<verb>', [...])` → `Modules\GlobalMaster\Models\ActivityLog` (`$table = sys_activity_logs`). Verbs (snake_case, verbatim): `appointment_created`, `appointment_confirmed`, `appointment_cancelled`, `appointment_completed`, `appointment_deleted`, `appointment_restored`. **No log on `update`/`toggleStatus`/`forceDelete`** (DEV-FOF-A06). |
| CRUD type | Full CRUD + workflow (confirm/cancel/complete) + calendar + toggle-status JSON + trash/restore/force-delete |
| Redirect after store/update/destroy/restore/forceDelete | `route('fof.menu.visitorManagement') . '?tab=appointments'` (= `/front-office/visitor-management?tab=appointments`) |
| Env prerequisite | **FrontOffice DISABLED** in `prime_testing/modules_statuses.json` (#19) — all `/front-office/*` routes 404 until enabled. |

### Routes (from `Modules/FrontOffice/routes/web.php`, prefix `front-office`, name `fof.`)
| Verb | Path | Name | Method | Gate |
|------|------|------|--------|------|
| GET | `/appointments` | `fof.appointments.index` | index | view |
| GET | `/appointments/calendar` | `fof.appointments.calendar` | calendar | view |
| POST | `/appointments` | `fof.appointments.store` | store | create |
| GET | `/appointments/{appointment}` | `fof.appointments.show` | show | view |
| GET | `/appointments/{appointment}/edit` | `fof.appointments.edit` | edit | update |
| PUT | `/appointments/{appointment}` | `fof.appointments.update` | update | update |
| PATCH | `/appointments/{appointment}/confirm` | `fof.appointments.confirm` | confirm | confirm |
| PATCH | `/appointments/{appointment}/cancel` | `fof.appointments.cancel` | cancel | cancel |
| PATCH | `/appointments/{appointment}/complete` | `fof.appointments.complete` | complete | complete |
| POST/PATCH | `/appointments/{appointment}/toggle-status` | `fof.appointments.toggleStatus` | toggleStatus | update |
| DELETE | `/appointments/{appointment}` | `fof.appointments.destroy` | destroy | delete |
| GET | `/appointments/trash/view` | `fof.appointments.trashed` | trashed | view |
| GET | `/appointments/{id}/restore` | `fof.appointments.restore` | restore | restore |
| DELETE | `/appointments/{id}/force-delete` | `fof.appointments.forceDelete` | forceDelete | forceDelete |

---

## 2. Business Conditions

### BC-DB (DDL constraints — one testable fact per constraint; Source: `DDL-fof_appointments`)
| ID | Fact | TC |
|----|------|----|
| BC-DB-01 | `appointment_number` VARCHAR(25) NOT NULL, **UNIQUE** `uq_fof_apt_appointment_number` (auto `APT-YYYYMMDD-NNN`) | TC-N01, TC-P02 |
| BC-DB-02 | `appointment_type` ENUM NOT NULL — **DDL** `(Parent_Teacher_Meeting,Principal_Meeting,Grievance,Admission_Enquiry,Other)` vs **live/model** `(Parent_Meeting,Official,Vendor,Principal_Meeting,Other)` (DEV-FOF-A03) | TC-P13, TC-N05 |
| BC-DB-03 | `with_user_id` INT UNSIGNED NOT NULL, FK→`sys_users` **RESTRICT** | TC-N02, TC-D01 |
| BC-DB-04 | `visitor_name` VARCHAR(100) NOT NULL | TC-N02, TC-P05, TC-N06 |
| BC-DB-05 | `visitor_mobile` VARCHAR(15) NOT NULL | TC-N02 |
| BC-DB-06 | `visitor_email` VARCHAR(100) NULL | TC-P04 |
| BC-DB-07 | `purpose` VARCHAR(300) NOT NULL | TC-N02, TC-P05 |
| BC-DB-08 | `appointment_date` DATE NOT NULL | TC-N02 |
| BC-DB-09 | `start_time` / `end_time` TIME NOT NULL (`end > start`) | TC-N02, TC-N03 |
| BC-DB-10 | `status` ENUM NOT NULL DEFAULT `Pending` — **DDL** `(Pending,Confirmed,Completed,Cancelled,No_Show)`; **controller writes `Scheduled`** (DEV-FOF-A02) | TC-P06, TC-P11 |
| BC-DB-11 | `confirmed_by` INT UNSIGNED NULL, FK→`sys_users` **SET NULL** | TC-P04 |
| BC-DB-12 | `confirmed_at`, `cancellation_reason` VARCHAR(300), `notes` TEXT — all NULL | TC-P04 |
| BC-DB-13 | `is_active` TINYINT(1) NOT NULL DEFAULT 1 | TC-P06 |
| BC-DB-14 | `created_by` / `updated_by` BIGINT UNSIGNED NOT NULL, **no FK**, set by controller (G48) | TC-N02, TC-P10 |
| BC-DB-15 | `deleted_at` TIMESTAMP NULL (soft delete) + model `SoftDeletes` (asserted independently) | TC-P01, TC-D03 |
| BC-DB-16 | Composite KEY `idx_fof_apt_slot(with_user_id,appointment_date,start_time,end_time)` — **non-UNIQUE**; overlap enforced in app code only (VAL-FOF-001, now remediated) | TC-P12 |

### BC-VAL (FormRequest — Source: `AppointmentRequest::rules()`)
| ID | Rule | Source | TC |
|----|------|--------|----|
| BC-VAL-01 | `appointment_type` required, `Rule::in(appointmentTypeOptions())` (live enum) | rules() | TC-N05 |
| BC-VAL-02 | `with_user_id` required, integer, `exists:sys_users,id` | rules() | TC-N07 |
| BC-VAL-03 | `visitor_name` required, string, max:100 | rules() | TC-N06 |
| BC-VAL-04 | `visitor_mobile` required, string, max:15 | rules() | TC-N08 |
| BC-VAL-05 | `visitor_email` nullable, email, max:100 | rules() | TC-N04 |
| BC-VAL-06 | `purpose` required, string, max:300 | rules() | TC-N08 |
| BC-VAL-07 | `appointment_date` required, date, **`after_or_equal:today` on POST only** (PUT drops it — DEV-FOF-A10) | rules() | TC-N09, TC-P71 |
| BC-VAL-08 | `start_time` required; `end_time` required, `after:start_time` | rules() | TC-N03 |
| BC-VAL-09 | `notes` nullable, string, max:1000 | rules() | TC-P04 |
| BC-VAL-10 | `prepareForValidation()` normalises `appointment_type` via `LEGACY_APPOINTMENT_TYPE_MAP` | request | TC-P13 |

### BC-AUTH (Source: `Gate::authorize()` per method + `AppointmentPolicy`)
| ID | Fact | TC |
|----|------|----|
| BC-AUTH-01 | index/show/calendar/trashed require `frontoffice.appointment.view` | TC-S51 |
| BC-AUTH-02 | store requires `frontoffice.appointment.create` | TC-S52 |
| BC-AUTH-03 | edit/update/toggleStatus require `frontoffice.appointment.update` | — |
| BC-AUTH-04 | confirm/cancel/complete require `.confirm`/`.cancel`/`.complete` | (SM tests) |
| BC-AUTH-05 | destroy `.delete`; restore `.restore`; forceDelete `.forceDelete` | TC-S53 |
| BC-AUTH-06 | guest (unauthenticated) redirected to `/login` (auth+verified middleware) | TC-S50 |
| BC-AUTH-07 | `AppointmentRequest::authorize()` returns `true` — no defense-in-depth (DEV-FOF-A07 / SEC-FOF-003) | TC-S55 |

### BC-BIZ (Source: `Screen-BR`, controller)
| ID | Fact | TC |
|----|------|----|
| BC-BIZ-01 | `store()` auto-generates `appointment_number` (`APT-YYYYMMDD-NNN`, zero-padded, `lockForUpdate`) | TC-P10 |
| BC-BIZ-02 | `store()` sets `status='Scheduled'`, `created_by`/`updated_by=auth id` (auto, not form input) | TC-P10, TC-P11 |
| BC-BIZ-03 | `store()` rejects overlapping slot for the same staff (excludes Cancelled/Completed) via `lockForUpdate` + `DomainException` (VAL-FOF-001 remediated) | TC-P12 |
| BC-BIZ-04 | `index` splits Upcoming (date≥today, not Cancelled/No_Show) vs Past | TC-P60 |
| BC-BIZ-05 | `toggleStatus()` flips `is_active`, returns `{success,message,is_active}` JSON | TC-P64 |
| BC-BIZ-06 | `appointmentTypeOptions()` reads the LIVE enum via `SHOW COLUMNS`, fallback to `FALLBACK_APPOINTMENT_TYPES` | TC-P13 |

### BC-SM (State machine — Source: `Screen-SM`, controller guards)
> Statuses in play (as written by code): `Scheduled` → `Confirmed` / `Cancelled` / `Completed`. DDL also lists `Pending`, `No_Show`.

| # | State | Trigger | Guard | Next | Legal? | TC |
|---|-------|---------|-------|------|--------|----|
| SM-1 | Scheduled | confirm | `status==Scheduled` | Confirmed | legal | TC-SM20 |
| SM-2 | Confirmed | confirm | `status!=Scheduled` → abort 422 | (unchanged) | illegal | TC-SM21 |
| SM-3 | Confirmed | complete | `status ∈ {Scheduled,Confirmed}` | Completed | legal | TC-SM22 |
| SM-4 | Completed | complete | not in set → abort 422 | (unchanged) | illegal | TC-SM23 |
| SM-5 | Scheduled | cancel | `status ∉ {Completed,Cancelled}` | Cancelled | legal | TC-SM24 |
| SM-6 | Cancelled | cancel | in set → abort 422 | (unchanged) | illegal | TC-SM25 |
| SM-7 | (any) | — | **No trigger sets `No_Show`** (dead state) | — | dead | TC-SM26 |

### BC-REF / BC-INT (cross-module — Source: `DDL` FK, controller)
| ID | Fact | TC |
|----|------|----|
| BC-REF-01 | `with_user_id` → `sys_users` (RESTRICT); `staff()` belongsTo `SchoolSetup\User` | TC-D01 |
| BC-REF-02 | `confirmed_by` → `sys_users` (SET NULL); `confirmedBy()` belongsTo | TC-P04 |
| BC-INT-01 | index/edit preload `SchoolSetup\User::active()->get()` — unbounded (PERF-FOF-001) | (documented) |

### BC-AUTO (Source: controller — programmatically-managed, NEVER form inputs — G48)
`appointment_number`, `status`, `confirmed_by`, `confirmed_at`, `created_by`, `updated_by` are all set by the controller/workflow — tested as auto-behaviour, never proposed as user fields.

---

## 3. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-15 | DDL | Schema/model/soft-delete alignment | table+cols+casts+unique+trait match live schema | test_01 | Auto |
| TC-P02 | BC-DB-01 | DDL | UNIQUE appointment_number index exists | index inspection passes | test_01/02 | Auto |
| TC-P04 | BC-DB-06/11/12 | DDL | Nullable columns accept NULL | row persists with nulls | test_04 | Auto |
| TC-P05 | BC-DB-04/07 | DDL | Exactly-n VARCHAR accepted (100/300) | stored full length | test_05 | Auto |
| TC-P06 | BC-DB-10/13 | DDL | DB defaults (is_active=1, status) applied | refresh shows defaults | test_06 | Auto |
| TC-P10 | BC-BIZ-01 | Screen-BR | store auto-numbers + sets created_by | `APT-\d{8}-\d{3}`, created_by set | test_10 | Auto |
| TC-P11 | BC-BIZ-02 | Screen-BR | store sets status=Scheduled | status==Scheduled | test_11 | Auto |
| TC-P12 | BC-BIZ-03 | Audit/VAL-FOF-001 | overlap slot rejected | overlapping row not created | test_12 | Auto |
| TC-P13 | BC-BIZ-06 | source | type options from live enum + legacy map | non-empty; mapped value returned | test_13 | Auto |
| TC-P60 | BC-BIZ-04 | Screen-BR | index renders Upcoming/Past | "Upcoming" visible | test_60 | Auto |
| TC-P62 | BC-BIZ-04 | route | calendar renders | path contains /appointments/calendar | test_62 | Auto |
| TC-P64 | BC-BIZ-05 | controller | toggle-status flips is_active | is_active false + JSON success | test_64 | Auto |
| TC-P71 | BC-VAL-07 | source | update rule contract (POST-only date floor) | source contains `isMethod('post')` | test_71 | Auto |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-DB-01 | DDL | Duplicate appointment_number | DB UNIQUE violation | test_02 | Auto |
| TC-N02 | BC-DB-03..14 | DDL | Missing NOT-NULL column (×11) | DB constraint error each | test_03 | Auto |
| TC-N03 | BC-VAL-08 | rules | end_time ≤ start_time | rejected (422/302/500) | test_31 | Auto |
| TC-N04 | BC-VAL-05 | rules | invalid email | rejected | test_34 | Auto |
| TC-N05 | BC-VAL-01 | rules | invalid appointment_type | rejected | test_33 | Auto |
| TC-N06 | BC-VAL-03 | rules | visitor_name > 100 | rejected (request) | test_36 | Auto |
| TC-N07 | BC-VAL-02 | rules | with_user_id not in sys_users | rejected | test_35 | Auto |
| TC-N08 | BC-VAL-04/06 | rules | missing required fields (empty payload) | rejected | test_30 | Auto |
| TC-N09 | BC-VAL-07 | rules | past appointment_date on create | rejected | test_32 | Auto |
| TC-N10 | BC-DB-04 | DDL | over-length visitor_name at DB layer | rejected or truncated to ≤100 | test_05 | Auto |

### State-Machine (TC-SM)
| TC ID | SM | Description | Expected | Method |
|-------|----|-------------|----------|--------|
| TC-SM20 | SM-1 | confirm Scheduled | status→Confirmed | test_20 |
| TC-SM21 | SM-2 | confirm when Confirmed | 422; status unchanged | test_21 |
| TC-SM22 | SM-3 | complete Confirmed | status→Completed | test_22 |
| TC-SM23 | SM-4 | complete when Completed | 422; unchanged | test_23 |
| TC-SM24 | SM-5 | cancel Scheduled | status→Cancelled | test_24 |
| TC-SM25 | SM-6 | cancel when Cancelled | 422; unchanged | test_25 |
| TC-SM26 | SM-7 | No_Show unreachable | no status assignment to No_Show | test_26 |

### Dependency / FK (TC-D)
| TC ID | BC | Description | Expected | Method |
|-------|----|-------------|----------|--------|
| TC-D01 | BC-REF-01 | staff() relationship resolves | with_user_id matches; skip if dep absent | test_40 |
| TC-D03 | BC-DB-15 | soft-delete → restore round-trip | trashed then restored | test_43 |
| TC-D04 | BC-DB-15 | force delete permanent | row gone from withTrashed | test_44 |

### Security / Permissions / Tenancy (TC-S / TC-T)
| TC ID | BC | Description | Expected | Method |
|-------|----|-------------|----------|--------|
| TC-S50 | BC-AUTH-06 | guest → login | 302/401/403 | test_50 |
| TC-S51 | BC-AUTH-01 | index forbidden w/o view | 403 (non-super-admin) | test_51 |
| TC-S52 | BC-AUTH-02 | store forbidden w/o create | 403 | test_52 |
| TC-S53 | BC-AUTH-05 | destroy forbidden w/o delete | 403 | test_53 |
| TC-S55 | BC-AUTH-07 | FormRequest authorize()==true | true (DEV-FOF-A07) | test_55 |
| TC-S70 | BC-EDG | XSS in visitor_name escaped on show | no raw `<script>` in source | test_70 |
| TC-S72 | DEV-FOF-A06 | update emits no activity log | update() body lacks activityLog() | test_72 |
| TC-S73 | HARD#11 | activity verbs snake_case verbatim | all 6 verbs present | test_73 |
| TC-T90 | BC-INT | unknown id → 404 (IDOR) | 404/403/302 | test_90 |
| TC-T91 | BC-AUTH-06 | toggle-status requires auth | blocked | test_91 |

---

## 4. Test Method Index (41 methods)
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_appointment_01_schema_model_and_request_configuration_are_correct | TC-P01/02 | Schema | 01–09 |
| 2 | test_appointment_02_duplicate_appointment_number_is_rejected | TC-N01 | Schema/UNIQUE | 01–09 |
| 3 | test_appointment_03_notnull_columns_reject_missing_values | TC-N02 | Schema/NOT NULL | 01–09 |
| 4 | test_appointment_04_nullable_columns_accept_null | TC-P04 | Schema | 01–09 |
| 5 | test_appointment_05_varchar_length_boundaries | TC-P05/TC-N10 | Schema | 01–09 |
| 6 | test_appointment_06_db_defaults_applied_on_direct_insert | TC-P06 | Schema | 01–09 |
| 7 | test_appointment_10_store_autogenerates_number_and_audit | TC-P10 | BC-BIZ | 10–19 |
| 8 | test_appointment_11_store_sets_status_scheduled | TC-P11 | BC-BIZ | 10–19 |
| 9 | test_appointment_12_slot_overlap_double_booking_is_rejected | TC-P12 | BC-BIZ | 10–19 |
| 10 | test_appointment_13_appointment_type_options_from_live_enum | TC-P13 | BC-BIZ | 10–19 |
| 11 | test_appointment_20_confirm_scheduled_to_confirmed | TC-SM20 | BC-SM | 20–29 |
| 12 | test_appointment_21_confirm_rejected_when_not_scheduled | TC-SM21 | BC-SM | 20–29 |
| 13 | test_appointment_22_complete_confirmed_to_completed | TC-SM22 | BC-SM | 20–29 |
| 14 | test_appointment_23_complete_rejected_when_completed | TC-SM23 | BC-SM | 20–29 |
| 15 | test_appointment_24_cancel_scheduled_to_cancelled | TC-SM24 | BC-SM | 20–29 |
| 16 | test_appointment_25_cancel_rejected_when_cancelled | TC-SM25 | BC-SM | 20–29 |
| 17 | test_appointment_26_no_show_state_has_no_transition | TC-SM26 | BC-SM | 20–29 |
| 18 | test_appointment_30_store_rejects_missing_required_fields | TC-N08 | BC-VAL | 30–39 |
| 19 | test_appointment_31_end_time_must_be_after_start_time | TC-N03 | BC-VAL | 30–39 |
| 20 | test_appointment_32_appointment_date_must_be_today_or_future_on_create | TC-N09 | BC-VAL | 30–39 |
| 21 | test_appointment_33_invalid_appointment_type_rejected | TC-N05 | BC-VAL | 30–39 |
| 22 | test_appointment_34_invalid_email_rejected | TC-N04 | BC-VAL | 30–39 |
| 23 | test_appointment_35_with_user_id_must_exist_in_sys_users | TC-N07 | BC-VAL | 30–39 |
| 24 | test_appointment_36_overlength_visitor_name_rejected_by_request | TC-N06 | BC-VAL | 30–39 |
| 25 | test_appointment_40_staff_relationship_resolves | TC-D01 | FK | 40–49 |
| 26 | test_appointment_43_soft_delete_and_restore_roundtrip | TC-D03 | FK/soft-delete | 40–49 |
| 27 | test_appointment_44_force_delete_removes_permanently | TC-D04 | FK/soft-delete | 40–49 |
| 28 | test_appointment_50_guest_redirected_to_login | TC-S50 | AUTH | 50–59 |
| 29 | test_appointment_51_index_forbidden_without_view_permission | TC-S51 | AUTH | 50–59 |
| 30 | test_appointment_52_store_forbidden_without_create_permission | TC-S52 | AUTH | 50–59 |
| 31 | test_appointment_53_delete_forbidden_without_delete_permission | TC-S53 | AUTH | 50–59 |
| 32 | test_appointment_55_formrequest_authorize_returns_true | TC-S55 | AUTH | 50–59 |
| 33 | test_appointment_60_index_renders_upcoming_and_past | TC-P60 | UI | 60–69 |
| 34 | test_appointment_62_calendar_view_renders | TC-P62 | UI | 60–69 |
| 35 | test_appointment_64_toggle_status_endpoint_flips_is_active | TC-P64 | UI/JSON | 60–69 |
| 36 | test_appointment_70_xss_visitor_name_is_escaped_on_render | TC-S70 | Edge/Security | 70–79 |
| 37 | test_appointment_71_update_allows_past_date | TC-P71 | Edge/DEV | 70–79 |
| 38 | test_appointment_72_update_emits_no_activity_log | TC-S72 | Edge/DEV | 70–79 |
| 39 | test_appointment_73_activity_log_verbs_are_snake_case | TC-S73 | Edge/Audit | 70–79 |
| 40 | test_appointment_90_unknown_id_returns_404 | TC-T90 | Tenancy/IDOR | 90–99 |
| 41 | test_appointment_91_toggle_status_requires_auth | TC-T91 | Security | 90–99 |

---

## 5. Manual Test Steps (workflow / complex only — simple CRUD covered by §3 Expected)

### MT-1 — Slot overlap double-booking (VAL-FOF-001 remediated) — TC-P12
| Step | Action | Expected |
|------|--------|----------|
| 1 | Enable FrontOffice in `modules_statuses.json`; login as admin with `frontoffice.appointment.create` | Appointments menu reachable |
| 2 | Create appointment: staff = User X, date = tomorrow, 10:00–11:00, Type=Official | `Appointment APT-… scheduled.` toast; status Scheduled |
| 3 | Create another: same staff X, same date, 10:30–11:30 | Request blocked; **no new row** created. `SELECT COUNT(*) FROM fof_appointments WHERE with_user_id=X AND appointment_date=<tomorrow>` → **1** |
| 4 | Create another: same staff X, same date, 11:00–12:00 (adjacent, non-overlapping) | Succeeds (boundary `end>start` / `start<end` excludes touching edges) |
| DB | `SELECT status FROM fof_appointments WHERE ...` | overlapping attempt absent |

### MT-2 — Confirm → Complete lifecycle — TC-SM20/22
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open Upcoming; on a Scheduled row press Confirm (check icon) | `Appointment confirmed.`; status badge → Confirmed |
| 2 | DB | `SELECT status, confirmed_by, confirmed_at FROM fof_appointments WHERE id=?` → `Confirmed`, admin id, timestamp set |
| 3 | Activity | `SELECT * FROM sys_activity_logs WHERE subject_id=? AND event='appointment_confirmed'` → 1 row |
| 4 | Press Mark Complete | `Appointment marked as completed.`; status → Completed |
| 5 | Attempt Confirm again on the Completed row (via direct PATCH) | HTTP 422 `Only pending/scheduled appointments can be confirmed.`; status unchanged |
| 6 | Activity | `appointment_completed` row present; **no** `appointment_updated` row (DEV-FOF-A06) |

### MT-3 — Cancel guard — TC-SM24/25
| Step | Action | Expected |
|------|--------|----------|
| 1 | On a Scheduled row press Cancel, confirm the JS prompt | `Appointment cancelled.`; status → Cancelled; row moves to Past |
| 2 | PATCH cancel again on the Cancelled row | HTTP 422 `Appointment cannot be cancelled.`; status unchanged |

### MT-4 — Soft delete / restore / force delete — TC-D03/D04
| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete an appointment (trash icon → confirm) | `Appointment APT-… moved to trash.`; `deleted_at` set; row hidden from index |
| 2 | Open `/appointments/trash/view` | Deleted row listed |
| 3 | Restore | `Appointment APT-… restored.`; `deleted_at` NULL; **`appointment_restored`** activity row created |
| 4 | Delete again, then Force delete | `permanently deleted`; row absent from `withTrashed()`; **no** activity row for force-delete (DEV-FOF-A06) |

---

## 6. Known Source Defects (proving tests included)
| ID | Sev | Summary | Proving test |
|----|-----|---------|--------------|
| DEV-FOF-A01 (VAL-FOF-001) | P1→**Remediated** | Slot-overlap double-booking now enforced in `store()` (`lockForUpdate` + `DomainException`). `idx_fof_apt_slot` remains non-UNIQUE (DB does not enforce); `update()` does **not** re-check overlap. | test_12 (+ DEV-A10) |
| DEV-FOF-A02 | P1 | `status` ENUM mismatch: controller writes `Scheduled`; DDL enumerates `(Pending,Confirmed,Completed,Cancelled,No_Show)`. If live DB matches DDL, `Scheduled` inserts coerce/fail. | test_01, test_11 |
| DEV-FOF-A03 | P2 | `appointment_type` ENUM mismatch DDL vs live/model fallback (`Parent_Meeting`/`Official`/`Vendor`…); legacy map bridges old DDL values. | test_13 |
| DEV-FOF-A04 | P3 | `No_Show` is in the DDL status enum but no controller action can reach it (dead state). | test_26 |
| DEV-FOF-A05 | P2 | `cancellation_reason` DDL comment "Required when Cancelled" but `cancel()` validates it `nullable` — BR not enforced. | (documented; MT-3) |
| DEV-FOF-A06 | P2 | `update()`, `toggleStatus()`, `forceDelete()` emit **no** `activityLog()` — audit-trail gaps. | test_72 |
| DEV-FOF-A07 (SEC-FOF-003) | P1 | `AppointmentRequest::authorize()` returns `true` (D30) — no defense-in-depth. | test_55 |
| DEV-FOF-A08 (PERF-FOF-001) | P2 | Unbounded `SchoolSetup\User::active()->get()` preload on index/edit. | (documented) |
| DEV-FOF-A10 | P2 | `update()` (PUT) drops `after_or_equal:today` (past dates allowed) and does not re-run the overlap check. | test_71 |

> **Activity-verb divergence from FactPack §4 prediction:** the module-wide Fact Pack predicted PascalCase verbs (`Created`/`Confirmed`/…). Appointment actually uses **snake_case** verbs (`appointment_created`, …). Documented for maintainer reconciliation; asserted verbatim in test_73.
