# FrontOffice → GatePass — Test Case List & Manual Testing Spec (COMBINED)

> Single combined artifact: Feature Information + Business Conditions (incl. `BC-SM`) + Test-Case List
> + Test-Method Index + Manual Test Steps (workflow/state paths only) + Known Source Defects.
> Prefix `fof_` verified against DDL `CREATE TABLE fof_gate_passes` (UNIQUE `uq_fof_gp_pass_number`).

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | FrontOffice (FOF) |
| Feature | GatePass |
| Primary table | `fof_gate_passes` (22-col, SoftDeletes, UNIQUE `pass_number`) |
| DB scope | **TENANT-SIDE** (`tenant_db`, no `tenant_id` col) → tenancy init required |
| URL base | `/front-office/gate-passes` (route-name base `fof.gate-passes.`) |
| Controller | `Modules\FrontOffice\Http\Controllers\GatePassController` |
| Service | `Modules\FrontOffice\Services\GatePassService` (FSM + BR-FOF-004 + pass-number gen) |
| Models | `Modules\FrontOffice\Models\GatePass` (verified `$table`, fillable, casts, SoftDeletes, scopes) |
| FormRequest | `Modules\FrontOffice\Http\Requests\IssueGatePassRequest` (store + update) |
| Validation | `person_type` in Student,Staff; `student_id`/`staff_user_id` required_if; `purpose` ENUM; `purpose_details` max:200; `expected_return_time` date; withValidator BR-FOF-004 |
| Blade | `resources/views/fof/gate-passes/{index,create,edit,show,trash}.blade.php` |
| CRUD type | Create / Read / Update / Delete + workflow verbs (approve, reject, exit, return) + toggle-status + trash/restore/force-delete |
| Soft delete | Yes (`deleted_at`; `SoftDeletes` trait present — asserted independently) |
| Pagination | History tab `paginate(20)`; trash `paginate(15)` |
| Permission scheme | `frontoffice.gate-pass.{view,create,update,delete,restore,forceDelete,approve}` — **string `Gate::authorize()` gates** (NOT model-bound policy on the enforced path) |
| Activity log | `activityLog($model, '<Event>', [...])` → **`sys_activity_logs`** (GlobalMaster\ActivityLog `$table`). Events: `Created` (service), `Updated`, `Deleted` (soft+force), `Restored`, `Approved`, `Rejected`, `Exited`, `Returned`. **No** activity log on `toggleStatus`. |

**Route surface (verified from `routes/web.php`, prefix `front-office`, name `fof.`):**

| Verb | Path | Name | Controller method | Gate | Activity |
|------|------|------|-------------------|------|----------|
| GET | /gate-passes | `fof.gate-passes.index` | index | `...view` | — |
| GET | /gate-passes/create | `...create` | create | `...create` | — |
| POST | /gate-passes | `...store` | store → `svc.createPass` | `...create` | `Created` |
| GET | /gate-passes/{gatePass} | `...show` | show | `...view` | — |
| GET | /gate-passes/{gatePass}/edit | `...edit` | edit | `...update` | — |
| PUT | /gate-passes/{gatePass} | `...update` | update | `...update` | `Updated` |
| DELETE | /gate-passes/{gatePass} | `...destroy` | destroy | `...delete` | `Deleted` |
| PATCH | /gate-passes/{gatePass}/approve | `...approve` | approve → `svc.approvePass` | `...approve` | `Approved` |
| PATCH | /gate-passes/{gatePass}/reject | `...reject` | reject → `svc.rejectPass` | `...approve` | `Rejected` |
| PATCH | /gate-passes/{gatePass}/exit | `...exit` | markExited → `svc.markExited` | `...update` | `Exited` |
| PATCH | /gate-passes/{gatePass}/return | `...return` | markReturned → `svc.markReturned` | `...update` | `Returned` |
| POST\|PATCH | /gate-passes/{gatePass}/toggle-status | `...toggleStatus` | toggleStatus | `...update` | — |
| GET | /gate-passes/trash/view | `...trashed` | trashed | `...view` | — |
| GET | /gate-passes/{id}/restore | `...restore` | restore | `...restore` | `Restored` |
| DELETE | /gate-passes/{id}/force-delete | `...forceDelete` | forceDelete | `...forceDelete` | `Deleted` |

> Note: `reject` is gated by `...approve` (not a distinct `...reject` ability). `markExited`/`markReturned`/`toggleStatus` are gated by `...update`.

---

## 2. Business Conditions

### BC-DB — DDL constraints (`fof_gate_passes`) — Source: `DDL-fof_gate_passes`

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `pass_number` VARCHAR(25) NOT NULL, **UNIQUE** `uq_fof_gp_pass_number` → duplicate rejected | DDL |
| BC-DB-02 | `person_type` ENUM(Student,Staff) NOT NULL (no default) → missing/invalid rejected | DDL |
| BC-DB-03 | `purpose` ENUM(Medical,Personal,Official,Sports,Family_Emergency,Other) NOT NULL → missing/invalid rejected | DDL |
| BC-DB-04 | `purpose_details` VARCHAR(200) NULL → over-length (201) rejected; exactly-200 accepted; NULL accepted | DDL |
| BC-DB-05 | `student_id` INT UNSIGNED NULL, FK `std_students` **RESTRICT** on delete | DDL |
| BC-DB-06 | `staff_user_id` INT UNSIGNED NULL, FK `sys_users` **SET NULL** | DDL |
| BC-DB-07 | `approved_by` INT UNSIGNED NULL, FK `sys_users` **SET NULL** | DDL |
| BC-DB-08 | `status` ENUM(6) NOT NULL DEFAULT `Pending_Approval` (auto-set by service) | DDL |
| BC-DB-09 | `parent_notified` TINYINT(1) NOT NULL DEFAULT 0 (set true for student passes by service) | DDL |
| BC-DB-10 | `is_active` TINYINT(1) NOT NULL DEFAULT 1 | DDL |
| BC-DB-11 | `created_by`/`updated_by` BIGINT UNSIGNED NOT NULL (no FK, no default) → missing rejected | DDL |
| BC-DB-12 | `exit_time`/`expected_return_time`/`actual_return_time`/`approved_at` DATETIME NULL | DDL |
| BC-DB-13 | `rejection_reason` TEXT NULL (populated on reject) | DDL |
| BC-DB-14 | `deleted_at` TIMESTAMP NULL + model `SoftDeletes` trait (asserted independently) | DDL/model |

### BC-VAL — FormRequest rules — Source: `IssueGatePassRequest`

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `person_type` required, in:Student,Staff | Req |
| BC-VAL-02 | `student_id` required_if person_type=Student, nullable, exists:std_students,id | Req |
| BC-VAL-03 | `staff_user_id` required_if person_type=Staff, nullable, exists:sys_users,id | Req |
| BC-VAL-04 | `purpose` required, ENUM domain | Req |
| BC-VAL-05 | `purpose_details` nullable, string, max:200 (matches DDL) | Req |
| BC-VAL-06 | `expected_return_time` nullable, date | Req |
| BC-VAL-07 | withValidator (POST only): second active student pass → error "This student already has an active gate pass." | Req |
| BC-VAL-08 | `reject` inline validate: `rejection_reason` required, string, max:500 | Controller |

### BC-AUTH — Authorization — Source: `Controller Gate::authorize` / `GatePassPolicy`

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Every controller method calls `Gate::authorize('frontoffice.gate-pass.<action>')` | Controller |
| BC-AUTH-02 | Non-super-admin without the ability is denied (403 on route; gate denies at layer) | Gate |
| BC-AUTH-03 | Super Admin allowed all via `Gate::before` (#31) — negatives need a fresh non-super user | Constraint #31 |
| BC-AUTH-04 | Guest hitting `/front-office/*` redirected to `/login` (`auth`+`verified` middleware) | Route |

### BC-BIZ — Business rules — Source: `GatePassService` / Screen-BR

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `pass_number` auto-generated `GP-YYYYMMDD-NNN`, sequence increments per day (locked) | Svc `generatePassNumber` |
| BC-BIZ-02 | New pass status auto = `Pending_Approval`; `created_by`/`updated_by` = auth id | Svc `createPass` |
| BC-BIZ-03 | BR-FOF-004: one active pass per student (`Pending_Approval`/`Approved`/`Exited`) — 2nd blocked | Svc + Req |
| BC-BIZ-04 | BR-FOF-003: student pass dispatches `fof.gate_pass.student_created` event and sets `parent_notified=true` | Svc |
| BC-BIZ-05 | Staff pass leaves `parent_notified=false` | Svc |
| BC-BIZ-06 | `toggleStatus` flips `is_active`, returns JSON `{success, message, is_active}` (no activity log) | Controller |

### BC-SM — State machine (`status`) — Source: `GatePassService` / Screen-SM

State model: `Pending_Approval → Approved → Exited → Returned`; `Pending_Approval → Rejected`. `Cancelled` is a declared ENUM value with **no** transition path.

| ID | From | Trigger | To | Legal? | Guard on failure | Source |
|----|------|---------|-----|--------|------------------|--------|
| BC-SM-01 | Pending_Approval | approvePass | Approved | ✅ legal | — | Svc |
| BC-SM-02 | Pending_Approval | rejectPass | Rejected | ✅ legal | sets rejection_reason | Svc |
| BC-SM-03 | Approved | markExited | Exited | ✅ legal | sets exit_time | Svc |
| BC-SM-04 | Exited | markReturned | Returned | ✅ legal | sets actual_return_time | Svc |
| BC-SM-05 | Approved/Rejected/… | approvePass | — | ❌ illegal | DomainException "Cannot approve a pass with status '…'." | Svc |
| BC-SM-06 | non-Pending | rejectPass | — | ❌ illegal | DomainException | Svc |
| BC-SM-07 | Pending/Rejected | markExited | — | ❌ illegal | DomainException "Cannot mark exit…" | Svc |
| BC-SM-08 | Approved/other | markReturned | — | ❌ illegal | DomainException "Cannot mark return…" | Svc |
| BC-SM-09 | any | (cancel) | Cancelled | — | **No route/service verb** → DEV-FOF-GP-002 | Gap |

### BC-REF / BC-INT — Relationships & cross-module — Source: model / DDL

| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `student()` belongsTo StudentProfile\Student (withTrashed) via `student_id` | Model |
| BC-REF-02 | `staff()` belongsTo SchoolSetup\User via `staff_user_id` | Model |
| BC-REF-03 | `approvedBy()` belongsTo SchoolSetup\User via `approved_by` | Model |
| BC-INT-01 | student passes emit `fof.gate_pass.student_created` (NTF decoupled via event) | Svc |

### BC-AUTO — Programmatically-managed fields (G48) — Source: `GatePassService`

| ID | Field | Managed by | Never a form input |
|----|-------|-----------|--------------------|
| BC-AUTO-01 | `pass_number` | service (`GP-…`) | ✅ |
| BC-AUTO-02 | `status` | service/workflow | ✅ |
| BC-AUTO-03 | `created_by`/`updated_by` | `auth()->id()` | ✅ |
| BC-AUTO-04 | `parent_notified` | service (student) | ✅ |
| BC-AUTO-05 | `approved_by`/`approved_at`/`exit_time`/`actual_return_time`/`rejection_reason` | workflow verbs | ✅ |

### BC-EDG — Edge — Source: Screen/DDL

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Free-text `purpose_details` stores XSS payload verbatim (view-layer encoding) | Security |
| BC-EDG-02 | `rejection_reason` NULL until a rejection occurs | DDL |

---

## 3. Test Case List

### Positive (TC-P)

| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-P01 | Config | BC-DB-01..14 | DDL | Full DDL↔app alignment matrix | table/cols/casts/fillable align | `test_gatePass_01` | Auto |
| TC-P02 | Config | BC-DB-14 | DDL | soft-delete col + trait independent | both true | `test_gatePass_02` | Auto |
| TC-P03 | Config | BC-DB-01 | DDL | UNIQUE index on pass_number present | unique index found | `test_gatePass_03` | Auto |
| TC-P04 | Config | BC-AUTO | Model | fillable supports tested fields | all present | `test_gatePass_04` | Auto |
| TC-P05 | Config | BC-VAL | Req | FormRequest rule strings present | verbatim strings found | `test_gatePass_05` | Auto |
| TC-P06 | Biz | BC-AUTO-01..03 | Svc | auto pass_number/status/created_by | GP-, Pending_Approval, id set | `test_gatePass_06` | Auto |
| TC-P07 | Biz | BC-BIZ-02 | Svc | service issues staff pass | Pending_Approval | `test_gatePass_10` | Auto |
| TC-P08 | Biz | BC-BIZ-04 | Svc | student pass sets parent_notified | true | `test_gatePass_11` | Auto* |
| TC-P09 | Biz | BC-BIZ-05 | Svc | staff pass no parent notify | false | `test_gatePass_12` | Auto |
| TC-P10 | Biz | BC-BIZ-01 | Svc | pass_number format GP-YYYYMMDD-NNN | regex match | `test_gatePass_14` | Auto |
| TC-P11 | Biz | BC-BIZ-01 | Svc | sequence increments | seqB > seqA | `test_gatePass_15` | Auto |
| TC-P12 | SM | BC-SM-01 | Svc | approve legal | Approved + approved_by/at | `test_gatePass_20` | Auto |
| TC-P13 | SM | BC-SM-02 | Svc | reject legal | Rejected + reason | `test_gatePass_21` | Auto |
| TC-P14 | SM | BC-SM-03 | Svc | mark exited legal | Exited + exit_time | `test_gatePass_22` | Auto |
| TC-P15 | SM | BC-SM-04 | Svc | mark returned legal | Returned + return_time | `test_gatePass_23` | Auto |
| TC-P16 | SM | BC-SM-01..04 | Svc | full lifecycle | Pending→Returned | `test_gatePass_28` | Auto |
| TC-P17 | DB | BC-DB-04 | DDL | purpose_details exactly 200 accepted | saved len 200 | `test_gatePass_33` | Auto |
| TC-P18 | DB | BC-DB-04,12 | DDL | nullable cols accept null | row saved | `test_gatePass_34` | Auto |
| TC-P19 | Ref | BC-REF-02 | Model | staff relation resolves | user matches | `test_gatePass_40` | Auto |
| TC-P20 | Ref | BC-REF-03 | Model | approvedBy relation resolves | not null | `test_gatePass_41` | Auto |
| TC-P21 | Ref | BC-DB-14 | Model | soft delete + restore | round-trips | `test_gatePass_42` | Auto |
| TC-P22 | Auth | BC-AUTH-01 | Gate | admin allowed all abilities | all true | `test_gatePass_50` | Auto |
| TC-P23 | Auth | BC-AUTH-02 | Gate | grant permission → allow | true after grant | `test_gatePass_53` | Auto* |
| TC-P24 | UI | Screen | Blade | index renders | sees "Gate Pass" | `test_gatePass_60` | Auto* |
| TC-P25 | UI | Screen | Blade | create page shows fields | person_type/purpose present | `test_gatePass_61` | Auto* |
| TC-P26 | UI | Route | routes | route surface registered | all names present | `test_gatePass_62` | Auto* |
| TC-P27 | Edge | BC-BIZ-06 | Controller | toggle flips is_active | false | `test_gatePass_71` | Auto |
| TC-P28 | Log | BC-BIZ-02 | Svc | Created activity → sys_activity_logs | count ≥ before | `test_gatePass_70` | Auto* |
| TC-P29 | Tenancy | §A | — | tenant context initialized | initialized | `test_gatePass_90` | Auto |

`*` = gated by an env/cross-module prerequisite → `markTestSkipped` when unavailable (still a real assertion when available).

### Negative (TC-N)

| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-N01 | DB | BC-DB-02,03,11 | DDL | missing NOT-NULL cols rejected (person_type, purpose, created_by, updated_by) | DB refuses | `test_gatePass_30` | Auto |
| TC-N02 | DB | BC-DB-01 | DDL | duplicate pass_number rejected (G43) | UNIQUE violation | `test_gatePass_31` | Auto |
| TC-N03 | DB | BC-DB-04 | DDL | purpose_details over-length (201) rejected (G45) | DB/validation refuses | `test_gatePass_32` | Auto |
| TC-N04 | DB | BC-DB-02 | DDL | invalid person_type ENUM rejected | refused | `test_gatePass_35` | Auto |
| TC-N05 | DB | BC-DB-03 | DDL | invalid purpose ENUM rejected | refused | `test_gatePass_36` | Auto |
| TC-N06 | Val | BC-VAL-01..03 | Req | required + required_if rules declared | rules present | `test_gatePass_37` | Auto |
| TC-N07 | Val | BC-VAL-05 | Req | max:200 matches DDL VARCHAR(200) | present | `test_gatePass_38` | Auto |
| TC-N08 | SM | BC-SM-05 | Svc | approve illegal when not pending | DomainException | `test_gatePass_24` | Auto |
| TC-N09 | SM | BC-SM-06 | Svc | reject illegal when not pending | DomainException | `test_gatePass_25` | Auto |
| TC-N10 | SM | BC-SM-07 | Svc | exit illegal when not approved | DomainException | `test_gatePass_26` | Auto |
| TC-N11 | SM | BC-SM-08 | Svc | return illegal when not exited | DomainException | `test_gatePass_27` | Auto |
| TC-N12 | Biz | BC-BIZ-03 | Svc | second active student pass blocked | DomainException | `test_gatePass_13` | Auto* |
| TC-N13 | Auth | BC-AUTH-02 | Gate | limited user denied approve | false | `test_gatePass_51` | Auto* |
| TC-N14 | Auth | BC-AUTH-02 | Gate | limited user denied create | false | `test_gatePass_52` | Auto* |
| TC-N15 | Auth | BC-AUTH-04 | Route | guest redirected from index | at /login | `test_gatePass_54` | Auto* |
| TC-N16 | SM | BC-SM-09 | Gap | Cancelled has no transition path | no cancel route | `test_gatePass_29` | Auto |
| TC-N17 | Def | SEC-FOF-003 | Req | authorize() returns true (defect) | true | `test_gatePass_39` | Auto |
| TC-N18 | FK | BC-REF | Model | restore ≠ recover force-deleted | null | `test_gatePass_44` | Auto |

### Dependency / FK (TC-D)

| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | FK | BC-DB-05 | DDL | student_id FK ON DELETE RESTRICT | restrict | `test_gatePass_45` | Auto* |
| TC-D02 | FK | BC-DB-14 | Model | force delete removes row | null | `test_gatePass_43` | Auto |
| TC-D03 | Int | BC-INT-01 | Svc | student pass emits event (via createPass) | parent_notified true | `test_gatePass_11` | Auto* |

### Security / Tenancy (TC-S / TC-T)

| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-S01 | Sec | BC-EDG-01 | Security | XSS payload stored verbatim | equals input | `test_gatePass_91` | Auto |
| TC-S02 | Edge | BC-EDG-02 | DDL | rejection_reason null before reject | null | `test_gatePass_72` | Auto |
| TC-T01 | Tenancy | §A | — | tenant context initialized | initialized | `test_gatePass_90` | Auto |

---

## 4. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_gatePass_01_migration_model_and_request_configuration_are_correct | TC-P01 | Config | 01–09 |
| 2 | test_gatePass_02_soft_delete_column_and_trait_are_independent | TC-P02 | Config | 01–09 |
| 3 | test_gatePass_03_unique_pass_number_index_present | TC-P03 | Config | 01–09 |
| 4 | test_gatePass_04_fillable_supports_tested_fields | TC-P04 | Config | 01–09 |
| 5 | test_gatePass_05_form_request_rules_contain_expected_strings | TC-P05 | Config | 01–09 |
| 6 | test_gatePass_06_programmatic_fields_are_auto_managed | TC-P06 | Biz/Auto | 01–09 |
| 7 | test_gatePass_10_service_creates_staff_pass | TC-P07 | Biz | 10–19 |
| 8 | test_gatePass_11_student_pass_sets_parent_notified | TC-P08/TC-D03 | Biz | 10–19 |
| 9 | test_gatePass_12_staff_pass_does_not_notify_parent | TC-P09 | Biz | 10–19 |
| 10 | test_gatePass_13_one_active_pass_per_student_blocks_second | TC-N12 | Biz | 10–19 |
| 11 | test_gatePass_14_pass_number_format | TC-P10 | Biz | 10–19 |
| 12 | test_gatePass_15_pass_number_sequence_increments | TC-P11 | Biz | 10–19 |
| 13 | test_gatePass_20_approve_legal_transition | TC-P12 | SM | 20–29 |
| 14 | test_gatePass_21_reject_legal_transition | TC-P13 | SM | 20–29 |
| 15 | test_gatePass_22_mark_exited_legal_transition | TC-P14 | SM | 20–29 |
| 16 | test_gatePass_23_mark_returned_legal_transition | TC-P15 | SM | 20–29 |
| 17 | test_gatePass_24_approve_illegal_when_not_pending | TC-N08 | SM | 20–29 |
| 18 | test_gatePass_25_reject_illegal_when_not_pending | TC-N09 | SM | 20–29 |
| 19 | test_gatePass_26_exit_illegal_when_not_approved | TC-N10 | SM | 20–29 |
| 20 | test_gatePass_27_return_illegal_when_not_exited | TC-N11 | SM | 20–29 |
| 21 | test_gatePass_28_full_lifecycle_pending_to_returned | TC-P16 | SM | 20–29 |
| 22 | test_gatePass_29_cancelled_status_has_no_transition_path | TC-N16 | SM | 20–29 |
| 23 | test_gatePass_30_required_columns_reject_missing_values | TC-N01 | Val/DB | 30–39 |
| 24 | test_gatePass_31_duplicate_pass_number_rejected | TC-N02 | DB | 30–39 |
| 25 | test_gatePass_32_purpose_details_over_length_rejected | TC-N03 | DB | 30–39 |
| 26 | test_gatePass_33_purpose_details_max_length_accepted | TC-P17 | DB | 30–39 |
| 27 | test_gatePass_34_nullable_columns_accept_null | TC-P18 | DB | 30–39 |
| 28 | test_gatePass_35_invalid_person_type_enum_rejected | TC-N04 | DB | 30–39 |
| 29 | test_gatePass_36_invalid_purpose_enum_rejected | TC-N05 | DB | 30–39 |
| 30 | test_gatePass_37_form_request_declares_required_rules | TC-N06 | Val | 30–39 |
| 31 | test_gatePass_38_form_request_max_matches_ddl | TC-N07 | Val | 30–39 |
| 32 | test_gatePass_39_form_request_authorize_returns_true_defect | TC-N17 | Def | 30–39 |
| 33 | test_gatePass_40_staff_relation_resolves | TC-P19 | Ref | 40–49 |
| 34 | test_gatePass_41_approved_by_relation_resolves | TC-P20 | Ref | 40–49 |
| 35 | test_gatePass_42_soft_delete_and_restore | TC-P21 | FK | 40–49 |
| 36 | test_gatePass_43_force_delete_removes_row | TC-D02 | FK | 40–49 |
| 37 | test_gatePass_44_restore_does_not_recover_force_deleted | TC-N18 | FK | 40–49 |
| 38 | test_gatePass_45_student_fk_is_restrict | TC-D01 | FK | 40–49 |
| 39 | test_gatePass_50_admin_allowed_all_abilities | TC-P22 | Auth | 50–59 |
| 40 | test_gatePass_51_limited_user_denied_approve | TC-N13 | Auth | 50–59 |
| 41 | test_gatePass_52_limited_user_denied_create | TC-N14 | Auth | 50–59 |
| 42 | test_gatePass_53_granting_permission_allows_create | TC-P23 | Auth | 50–59 |
| 43 | test_gatePass_54_guest_redirected_from_index | TC-N15 | Auth | 50–59 |
| 44 | test_gatePass_60_index_page_renders | TC-P24 | UI | 60–69 |
| 45 | test_gatePass_61_create_page_shows_form_fields | TC-P25 | UI | 60–69 |
| 46 | test_gatePass_62_routes_registered_or_module_disabled | TC-P26 | UI | 60–69 |
| 47 | test_gatePass_70_activity_log_created_recorded | TC-P28 | Log | 70–79 |
| 48 | test_gatePass_71_toggle_status_flips_is_active | TC-P27 | Edge | 70–79 |
| 49 | test_gatePass_72_reject_requires_reason | TC-S02 | Edge | 70–79 |
| 50 | test_gatePass_90_tenant_context_initialized | TC-T01/TC-P29 | Tenancy | 90–99 |
| 51 | test_gatePass_91_xss_payload_stored_verbatim | TC-S01 | Security | 90–99 |

**Total: 51 methods.**

---

## 5. Manual Test Steps (workflow / state-machine paths only)

Simple CRUD/validation cases are fully specified by section 3's Expected column and are not restated here.
Prerequisite for all UI steps: FrontOffice enabled in `modules_statuses.json`, `APP_ENV=testing`, logged in as an admin with `frontoffice.gate-pass.*`.

### MTS-1 — Issue a staff gate pass (happy path)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/front-office/gate-passes/create` | "Issue Gate Pass" form loads; Pass Number shows "Auto-generated (GP-YYYYMMDD-NNN)" (readonly) |
| 2 | Select Person Type = Staff | Student select hides, Staff select shows |
| 3 | Pick a staff member, Purpose = Official, click "Issue Pass" | Redirect to `…?tab=gate-passes`; toast "Gate pass GP-… issued and pending approval." |
| 4 | DB check | `SELECT status, pass_number FROM fof_gate_passes ORDER BY id DESC LIMIT 1` → `Pending_Approval`, `GP-<today>-NNN` |
| 5 | Activity check | `SELECT event FROM sys_activity_logs ORDER BY id DESC LIMIT 1` → `Created` |

### MTS-2 — Approve → Exit → Return lifecycle (BC-SM-01/03/04)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On the Pending tab, click "Approve" for the pass | Toast "…approved."; row moves to Active tab |
| 2 | DB check | `status=Approved`, `approved_by` = your id, `approved_at` not null; activity `Approved` |
| 3 | On Active tab click "Mark Exited" | Toast "…marked as Exited."; `exit_time` set; activity `Exited` |
| 4 | Click "Mark Returned" | Toast "…marked as Returned."; `actual_return_time` set; activity `Returned`; row in History |

### MTS-3 — Reject (BC-SM-02)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On Pending tab click "Reject" → enter reason → submit | Toast "…rejected." |
| 2 | Empty reason | Inline `required` blocks submit (rejection_reason required, max:500) |
| 3 | DB check | `status=Rejected`, `rejection_reason` = entered text; activity `Rejected` |

### MTS-4 — BR-FOF-004 one active pass per student (BC-BIZ-03)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Issue a Student pass for student X | Succeeds; pass Pending_Approval |
| 2 | Issue a second Student pass for student X | Validation error on `student_id`: "This student already has an active gate pass." (FormRequest) — and service throws DomainException if bypassed |
| 3 | DB check | `SELECT COUNT(*) FROM fof_gate_passes WHERE student_id=X AND status IN ('Pending_Approval','Approved','Exited')` → 1 |

### MTS-5 — Illegal transition guard (BC-SM-05..08)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Attempt `PATCH /gate-passes/{id}/exit` on a Pending pass (e.g. via direct request) | Service throws DomainException "Cannot mark exit for a pass with status 'Pending_Approval'." → HTTP 500 (tolerated as {500}) |
| 2 | Attempt approve on an already-Approved pass | DomainException "Cannot approve a pass with status 'Approved'." |

---

## 6. Known Source Defects (carried into Gap Analysis as DEV-###)

| ID | Sev | Source | Summary | Proving test |
|----|-----|--------|---------|--------------|
| DEV-FOF-GP-001 (=SEC-FOF-003) | P1 | FactPack §6 | `IssueGatePassRequest::authorize()` returns `true` — no defense-in-depth fallback (D30); relies solely on controller `Gate::authorize` | `test_gatePass_39` asserts `authorize() === true` |
| DEV-FOF-GP-002 | P2 (new) | Cross-ref (DDL vs Svc/Route) | `status` ENUM declares `Cancelled` but there is **no** controller/service verb or route that sets it → `Cancelled` state is unreachable (dead state) | `test_gatePass_29` asserts no `fof.gate-passes.cancel` route |
| DEV-FOF-GP-003 (=DAT-FOF-004) | P2 | FactPack §6 | Audit (2026-06-29) flagged gate-pass create as lacking row locks. **Current source uses `DB::transaction` + `lockForUpdate()`** in `createPass`/`generatePassNumber` → appears remediated; verify in source before re-raising | Observed in `GatePassService` (documented, not asserted as a bug) |
| DEV-FOF-GP-004 (=DAT-FOF-002) | P2 | FactPack §6 | Register-number generators use read-modify-write. GatePass uses `lockForUpdate()` → mitigated for this feature; UNIQUE key is the DB backstop | `test_gatePass_31` proves UNIQUE backstop |
| DEV-FOF-GP-005 | P3 (obs) | Cross-ref (BC-VAL-07 vs Svc) | BR-FOF-004 enforced in **two** layers (FormRequest withValidator + service `lockForUpdate`), but the FormRequest check is unlocked/outside the txn → only the service check is race-safe. Not a bug (defense-in-depth), noted for maintainer | `test_gatePass_13` (service layer) |
