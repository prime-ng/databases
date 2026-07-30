# PostalDispatch (FOF) — Combined Test-Case List + Manual Test Spec

> **COMPOUND feature** — two sub-entities, two controllers, two tables, ONE artifact set:
> - **PostalRegister** — `fof_postal_register` / `PostalRegisterController` — Inward/Outward mail with an **acknowledgement lock FSM** (BR-FOF-009).
> - **DispatchRegister** — `fof_dispatch_register` / `DispatchRegisterController` — official outgoing correspondence log.
>
> Prefix `fof_` VERIFIED against DDL `CREATE TABLE fof_postal_register` / `fof_dispatch_register`. Tenant-side.

---

## 1. Feature Information

| Field | PostalRegister | DispatchRegister |
|-------|----------------|------------------|
| Module | FrontOffice (FOF) | FrontOffice (FOF) |
| Screen (menu) | `fof.menu.registers?tab=postal` (FofMenuController@registers) | `fof.menu.registers?tab=dispatch` |
| Controller | `Modules\FrontOffice\Http\Controllers\PostalRegisterController` | `...\DispatchRegisterController` |
| Model | `Modules\FrontOffice\Models\PostalRegister` (`extends App\Models\BaseModel`) | `...\Models\DispatchRegister` (`extends BaseModel`) |
| FormRequest | `PostalRegisterRequest` | `DispatchRegisterRequest` |
| Primary table | `fof_postal_register` | `fof_dispatch_register` |
| Route-name group | `fof.postal-register.*` | `fof.dispatch-register.*` |
| URL prefix | `/front-office/postal-register` | `/front-office/dispatch-register` |
| Permission scheme | `frontoffice.postal-register.{viewAny,create,update,delete,restore,forceDelete}` (string gates via `Gate::authorize`) | `frontoffice.dispatch-register.{viewAny,create,update,delete,restore,forceDelete}` |
| CRUD Type | Create/Edit/Delete + acknowledge + toggle-status + trash/restore/force-delete | Create/Edit/Delete + toggle-status + trash/restore/force-delete |
| Soft Delete | Yes (`SoftDeletes`, `deleted_at`) | Yes |
| Pagination | Inward 20 / Outward 20 (`inward_page`,`outward_page`); trash 15 | 25; trash 15 |
| Activity Log | sink `sys_activity_logs` via `activityLog()` — **only** `restore`→`'Restored'` and `forceDelete`→`'Deleted'`. store/update/acknowledge/toggle/destroy log **nothing** (audit-trail gap, DEV-FOF-PD-04). | Same: `'Restored'` / `'Deleted'` only. |

**Routes (verbatim from `Modules/FrontOffice/routes/web.php`, group `auth,verified` + prefix `front-office` + name `fof.`):**
- Postal: `GET postal-register/trash/view` (`.trashed`), `GET postal-register/{id}/restore` (`.restore`), `DELETE postal-register/{id}/force-delete` (`.forceDelete`), `GET postal-register` (`.index`), `POST postal-register` (`.store`), `GET postal-register/{postal}` (`.show`), `GET postal-register/{postal}/edit` (`.edit`), `PUT postal-register/{postal}` (`.update`), `DELETE postal-register/{postal}` (`.destroy`), `PATCH postal-register/{postal}/acknowledge` (`.acknowledge`), `POST|PATCH postal-register/{postal}/toggle-status` (`.toggleStatus`).
- Dispatch: same set **minus acknowledge**.

**Selectors (from `pages/partials/registers/_postal.blade.php` / `_dispatch.blade.php`):**
- Postal create modal `#addPostalModal`, form → `route('fof.postal-register.store')`; fields `postal_type`, `postal_date`, `document_type`, `subject`, `sender_name`, `recipient_name`, `sender_address`, `recipient_address`, `courier_company`, `tracking_number`, `department`, `assigned_to_user_id`, `remarks`. Acknowledge form → `route('fof.postal-register.acknowledge', $item)` (`@method('PATCH')`), button text **"Acknowledge"**; after ack a `badge bg-success "Ack. …"` replaces the button.
- Dispatch create modal `#addDispatchModal`; fields `dispatch_date`, `dispatch_mode`, `document_type`, `addressee_name`, `reference_number`, `subject`, `remarks`.

---

## 2. Business Conditions

### BC-DB — Postal (`fof_postal_register`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-P1 | `postal_number` UNIQUE (`uq_fof_pr_postal_number`) → duplicate refused | DDL |
| BC-DB-P2 | `postal_type` NOT NULL ENUM(Inward,Outward) | DDL |
| BC-DB-P3 | `postal_date` NOT NULL DATE | DDL |
| BC-DB-P4 | `document_type` NOT NULL ENUM(Letter,Courier,Parcel,Government_Notice,Cheque,Legal,Other) | DDL |
| BC-DB-P5 | `subject` NOT NULL VARCHAR(200) | DDL |
| BC-DB-P6 | `sender_name`/`recipient_name` VARCHAR(100) nullable | DDL |
| BC-DB-P7 | `sender_address`/`recipient_address` VARCHAR(200) nullable | DDL |
| BC-DB-P8 | `courier_company`/`tracking_number`/`department` VARCHAR(100) nullable | DDL |
| BC-DB-P9 | `assigned_to_user_id` INT-U nullable, FK→sys_users **ON DELETE SET NULL** | DDL |
| BC-DB-P10 | `acknowledged_at` DATETIME null; once set record is LOCKED (BR-FOF-009) | DDL/Model::isLocked |
| BC-DB-P11 | `is_active` TINYINT(1) DEFAULT 1 | DDL |
| BC-DB-P12 | `created_by`/`updated_by` BIGINT-U NOT NULL (no FK, controller-set) | DDL |
| BC-DB-P13 | `deleted_at` soft-delete column + `SoftDeletes` trait (asserted independently) | DDL/Model |

### BC-DB — Dispatch (`fof_dispatch_register`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-D1 | `dispatch_number` UNIQUE (`uq_fof_dr_dispatch_number`) → duplicate refused | DDL |
| BC-DB-D2 | `dispatch_date` NOT NULL DATE | DDL |
| BC-DB-D3 | `addressee_name` NOT NULL **VARCHAR(100)** | DDL |
| BC-DB-D4 | `subject` NOT NULL VARCHAR(200) | DDL |
| BC-DB-D5 | `document_type` NOT NULL ENUM(Letter,Notice,Legal,**Certificate**,Report,Circular,Other) | DDL |
| BC-DB-D6 | `dispatch_mode` NOT NULL ENUM(Hand,Post,Courier,Email,Fax) — **no Other** | DDL |
| BC-DB-D7 | `addressee_address` VARCHAR(200) null; `reference_number` VARCHAR(100) null | DDL |
| BC-DB-D8 | `copy_retained` TINYINT(1) DEFAULT 1 — **not a form input** (auto) | DDL/Model |
| BC-DB-D9 | `dispatched_by` INT-U null, FK→sys_users **SET NULL**; controller-set to auth id | DDL/Controller |
| BC-DB-D10 | `is_active` DEFAULT 1; `deleted_at` + `SoftDeletes` | DDL/Model |

### BC-VAL (from the real FormRequests)
| ID | Rule | Source |
|----|------|--------|
| BC-VAL-P1 | `postal_type` required, `in:Inward,Outward` | PostalRegisterRequest |
| BC-VAL-P2 | `postal_date` required, date | " |
| BC-VAL-P3 | `document_type` required, `in:Letter,Courier,Parcel,Government_Notice,Cheque,Legal,Other` | " |
| BC-VAL-P4 | `subject` required, max:200 | " |
| BC-VAL-P5 | `sender_name`/`recipient_name` nullable max:100; addresses max:200; courier/tracking/department max:100 | " |
| BC-VAL-P6 | `assigned_to_user_id` nullable integer `exists:sys_users,id` | " |
| BC-VAL-D1 | `dispatch_date` required date; `subject` required max:200 | DispatchRegisterRequest |
| BC-VAL-D2 | `addressee_name` required **max:150** (⚠ column is 100 → DEV-FOF-DR-03) | " |
| BC-VAL-D3 | `dispatch_mode` required `in:Hand,Post,Courier,Email,Fax,Other` (⚠ Other absent from DDL → DEV-FOF-DR-01) | " |
| BC-VAL-D4 | `document_type` required `in:Letter,Notice,Circular,Report,Legal,Other` (⚠ **Certificate omitted** vs DDL → DEV-FOF-DR-02) | " |

### BC-AUTH
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-1 | Every controller method calls `Gate::authorize('frontoffice.<entity>.<action>')`; index/trashed/show use `viewAny` | Controllers |
| BC-AUTH-2 | Guest (unauth) blocked by `auth,verified` middleware | routes |
| BC-AUTH-3 | Non-super-admin without ability → 403 (`Gate::before` grants Super Admin all — negatives need a non-super user + `forgetCachedPermissions()`) | Rule #31 |

### BC-BIZ / BC-AUTO
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-1 | Postal number auto `IN-YYYY-NNNN` / `OUT-YYYY-NNNN` (`generatePostalNumber`, `lockForUpdate`) | Controller |
| BC-BIZ-2 | Dispatch number auto `DSP-YYYY-NNNN` (`generateDispatchNumber`, `lockForUpdate`) | Controller |
| BC-AUTO-1 | `created_by`/`updated_by`/`dispatched_by` set from `auth()->id()` — NOT form inputs (G48) | Controller |
| BC-AUTO-2 | `copy_retained` never set by store → DB default 1 (G48) | Controller/DDL |
| BC-AUTO-3 | acknowledge sets `acknowledgement_by = auth user name`, `acknowledged_at = now()` | Controller |

### BC-SM — Postal acknowledgement lock (BR-FOF-009)
| # | State | Trigger | Next / Result | Legal? | Source |
|---|-------|---------|---------------|--------|--------|
| SM-1 | Unacknowledged | `acknowledge` | Locked (`acknowledged_at` set) | ✅ legal | Controller L82-96 |
| SM-2 | Locked | `acknowledge` again | **422** "already acknowledged" | ❌ illegal | Controller L86 |
| SM-3 | Locked | `update` | **422** "record is locked" (DAT-FOF-003 **remediated**) | ❌ illegal | Controller L157 |
| SM-4 | Locked | `destroy` | **422** "record is locked" | ❌ illegal | Controller L173 |
| SM-5 | Unacknowledged | `update` | success | ✅ legal | Controller L153-167 |
| SM-6 | Unacknowledged | `destroy` | soft-deleted | ✅ legal | Controller L169-179 |

### BC-REF / BC-INT
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-1 | postal `assigned_to_user_id` → sys_users SET NULL | DDL FK |
| BC-REF-2 | dispatch `dispatched_by` → sys_users SET NULL | DDL FK |
| BC-INT-1 | Both restore/force-delete write `sys_activity_logs` (`Restored`/`Deleted`) | Controller |

---

## 3. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-BIZ-1 | Controller | Store Inward postal | `IN-YYYY-NNNN`, created_by=auth | `test_10` | Ready |
| TC-P02 | BC-BIZ-1 | Controller | Store Outward postal | `OUT-YYYY-NNNN` | `test_11` | Ready |
| TC-P03 | BC-BIZ-2 | Controller | Store dispatch | `DSP-YYYY-NNNN`, dispatched_by=auth | `test_12` | Ready |
| TC-P04 | BC-AUTO-2 | DDL | copy_retained default 1 | true, not a form field | `test_13` | Ready |
| TC-P05 | BC-DB-P11/D10 | DDL | is_active default 1 | true | `test_14` | Ready |
| TC-P06 | BC-DB-P10 | Model | isLocked tracks acknowledged_at | false→true | `test_15` | Ready |
| TC-P07 | BC-SM SM-1 | Controller | Acknowledge unlocked | locked, ts set | `test_20` | Ready |
| TC-P08 | BC-SM SM-5 | Controller | Update unlocked | success | `test_24` | Ready |
| TC-P09 | BC-SM SM-6 | Controller | Destroy unlocked | soft-deleted | `test_25` | Ready |
| TC-P10 | BC-VAL-P5 | FormRequest | Nullable fields omittable | valid | `test_34` | Ready |
| TC-P11 | BC-REF-1 | DDL FK | Restore/force-delete lifecycle | works | `test_43`/`test_44` | Ready |
| TC-P12 | BC-VAL-P4 | FormRequest | subject exactly 200 | valid | `test_32`/`test_38` | Ready |
| TC-P13 | UI | Controller | toggle-status JSON success | `{success:true}`, flip | `test_60`/`test_61` | Ready |
| TC-P14 | UI | Controller | search/status filter | narrows | `test_62`/`test_63` | Ready |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-VAL-P1..4 | FormRequest | Missing postal required fields | reject | `test_30` | Ready |
| TC-N02 | BC-VAL-P1/P3 | FormRequest | Invalid postal ENUMs | reject | `test_31` | Ready |
| TC-N03 | BC-VAL-P4 | FormRequest | subject 201 | reject | `test_32` | Ready |
| TC-N04 | BC-VAL-P5 | FormRequest | sender_name 101 | reject | `test_33` | Ready |
| TC-N05 | BC-VAL-P6 | FormRequest | assigned_to_user_id not exists | reject | `test_35` | Ready |
| TC-N06 | BC-VAL-D1..4 | FormRequest | Missing dispatch required fields | reject | `test_36` | Ready |
| TC-N07 | BC-VAL-D3/D4 | FormRequest | Invalid dispatch ENUMs | reject | `test_37` | Ready |
| TC-N08 | BC-VAL-D1 | FormRequest | dispatch subject 201 | reject | `test_38` | Ready |
| TC-N09 | BC-DB-P1 | DDL | Duplicate postal_number | DB refuses | `test_70` | Ready |
| TC-N10 | BC-DB-D1 | DDL | Duplicate dispatch_number | DB refuses | `test_71` | Ready |
| TC-N11 | BC-DB-P5 | DDL | subject NOT NULL at DB | DB refuses | `test_72` | Ready |
| TC-N12 | BC-VAL-P4 | FormRequest | empty/whitespace subject | reject | `test_75` | Ready |
| TC-N13 | BC-SM SM-2 | Controller | Re-acknowledge locked | 422 | `test_21` | Ready |
| TC-N14 | BC-SM SM-3 | Controller | Update locked | 422 | `test_22` | Ready |
| TC-N15 | BC-SM SM-4 | Controller | Destroy locked | 422 | `test_23` | Ready |
| TC-N16 | BC-INT | Controller | Invalid id → 404 | 404 | `test_42` | Ready |

### Dependency / Integration (TC-D)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-D01 | BC-REF-1 | DDL FK | postal assigned user delete → SET NULL | nulled | `test_40` | Ready (guarded) |
| TC-D02 | BC-REF-2 | DDL FK | dispatch dispatched_by delete → SET NULL | nulled | `test_41` | Ready (guarded) |
| TC-D03 | BC-INT-1 | Controller | Activity `Restored`/`Deleted` | logged verbatim | `test_45` | Ready (guarded) |
| TC-D04 | BC-DB-P13 | DDL/Model | onlyTrashed scope | trashed only | `test_64` | Ready |

### Authorization (TC-S/AUTH)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-A01 | BC-AUTH-2 | routes | Guest → postal index | redirect/401/403 | `test_50` | Ready |
| TC-A02 | BC-AUTH-3 | Gate | No-create user denied (both) | denies | `test_51` | Ready |
| TC-A03 | BC-AUTH-1 | Gate | Granted user allowed | allows | `test_52` | Ready |
| TC-A04 | BC-AUTH-3 | Gate | No-update/delete/forceDelete denied | denies | `test_53` | Ready |
| TC-A05 | BC-AUTH-3 | routes | Limited user HTTP store | not 200/201 | `test_54` | Ready |

### State-Machine (TC-SM) — covered in Positive/Negative above (`test_20`–`test_25`).

### Security / Edge / DEV (TC-S/EDG)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-S01 | DEV-FOF-DR-03 | FormRequest/DDL | addressee_name rule max:150 > col 100 | 150 passes rule (DEV) | `test_39` | Ready |
| TC-S02 | DEV-FOF-DR-01 | FormRequest/DDL | dispatch_mode Other passes rule, DB refuses | divergence proven | `test_73` | Ready |
| TC-S03 | DEV-FOF-DR-02 | FormRequest/DDL | doc_type Certificate DDL-valid but rule-rejected | rejected (DEV) | `test_74` | Ready |
| TC-S04 | Security | Blade | XSS payload stored verbatim | stored, escaped at render | `test_76` | Ready |
| TC-S05 | Security | Controller | auto-number not user-overridable | regenerated | `test_91` | Ready |
| TC-T01 | Tenancy | stancl | rows scoped to tenant | scoped/skip | `test_90` | Ready (guarded) |

### Schema
| TC ID | Description | Method |
|-------|-------------|--------|
| TC-01 | Full DDL↔app matrix, both tables, soft-delete independent, UNIQUE indexes | `test_01` |
| TC-02 | FormRequest rule strings match source (incl. the 3 DEV divergences) | `test_02` |

---

## 4. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_postaldispatch_01_migration_model_and_request_configuration_are_correct | TC-01 | Schema | 01 |
| 2 | test_postaldispatch_02_formrequest_rules_match_source | TC-02 | Schema/DEV | 02 |
| 3 | test_postaldispatch_10_postal_number_autogenerated_on_store | TC-P01 | BC-BIZ | 10 |
| 4 | test_postaldispatch_11_outward_postal_number_prefix | TC-P02 | BC-BIZ | 11 |
| 5 | test_postaldispatch_12_dispatch_number_autogenerated_on_store | TC-P03 | BC-BIZ | 12 |
| 6 | test_postaldispatch_13_copy_retained_defaults_true | TC-P04 | BC-AUTO | 13 |
| 7 | test_postaldispatch_14_is_active_defaults_true_on_create | TC-P05 | BC-DB | 14 |
| 8 | test_postaldispatch_15_islocked_tracks_acknowledged_at | TC-P06 | BC-BIZ | 15 |
| 9 | test_postaldispatch_20_acknowledge_locks_unacknowledged_postal | TC-P07/SM-1 | BC-SM | 20 |
| 10 | test_postaldispatch_21_reacknowledge_locked_postal_is_rejected | TC-N13/SM-2 | BC-SM | 21 |
| 11 | test_postaldispatch_22_update_locked_postal_is_rejected | TC-N14/SM-3 | BC-SM | 22 |
| 12 | test_postaldispatch_23_destroy_locked_postal_is_rejected | TC-N15/SM-4 | BC-SM | 23 |
| 13 | test_postaldispatch_24_update_unlocked_postal_succeeds | TC-P08/SM-5 | BC-SM | 24 |
| 14 | test_postaldispatch_25_destroy_unlocked_postal_soft_deletes | TC-P09/SM-6 | BC-SM | 25 |
| 15 | test_postaldispatch_30_postal_required_fields_rejected_when_missing | TC-N01 | BC-VAL | 30 |
| 16 | test_postaldispatch_31_postal_invalid_enums_rejected | TC-N02 | BC-VAL | 31 |
| 17 | test_postaldispatch_32_postal_subject_length_boundary | TC-N03/TC-P12 | BC-VAL | 32 |
| 18 | test_postaldispatch_33_postal_sender_name_length_boundary | TC-N04 | BC-VAL | 33 |
| 19 | test_postaldispatch_34_postal_nullable_fields_omittable | TC-P10 | BC-VAL | 34 |
| 20 | test_postaldispatch_35_postal_assigned_user_must_exist | TC-N05 | BC-VAL | 35 |
| 21 | test_postaldispatch_36_dispatch_required_fields_rejected_when_missing | TC-N06 | BC-VAL | 36 |
| 22 | test_postaldispatch_37_dispatch_invalid_enums_rejected | TC-N07 | BC-VAL | 37 |
| 23 | test_postaldispatch_38_dispatch_subject_length_boundary | TC-N08/TC-P12 | BC-VAL | 38 |
| 24 | test_postaldispatch_39_dispatch_addressee_name_rule_exceeds_column | TC-S01 | DEV | 39 |
| 25 | test_postaldispatch_40_postal_assigned_user_set_null_on_user_delete | TC-D01 | BC-REF | 40 |
| 26 | test_postaldispatch_41_dispatch_dispatched_by_set_null_on_user_delete | TC-D02 | BC-REF | 41 |
| 27 | test_postaldispatch_42_invalid_ids_return_404 | TC-N16 | BC-INT | 42 |
| 28 | test_postaldispatch_43_restore_and_force_delete_lifecycle | TC-P11 | BC-INT | 43 |
| 29 | test_postaldispatch_44_dispatch_restore_and_force_delete_lifecycle | TC-P11 | BC-INT | 44 |
| 30 | test_postaldispatch_45_activity_log_events_are_verbatim | TC-D03 | BC-INT | 45 |
| 31 | test_postaldispatch_50_guest_cannot_access_postal_index | TC-A01 | BC-AUTH | 50 |
| 32 | test_postaldispatch_51_user_without_postal_create_permission_denied | TC-A02 | BC-AUTH | 51 |
| 33 | test_postaldispatch_52_user_with_permission_is_allowed | TC-A03 | BC-AUTH | 52 |
| 34 | test_postaldispatch_53_user_without_update_permission_denied | TC-A04 | BC-AUTH | 53 |
| 35 | test_postaldispatch_54_limited_user_store_forbidden_over_http | TC-A05 | BC-AUTH | 54 |
| 36 | test_postaldispatch_60_postal_toggle_status_endpoint | TC-P13 | UI | 60 |
| 37 | test_postaldispatch_61_dispatch_toggle_status_endpoint | TC-P13 | UI | 61 |
| 38 | test_postaldispatch_62_postal_search_matches_subject | TC-P14 | UI | 62 |
| 39 | test_postaldispatch_63_dispatch_status_filter | TC-P14 | UI | 63 |
| 40 | test_postaldispatch_64_only_trashed_scope | TC-D04 | UI | 64 |
| 41 | test_postaldispatch_70_duplicate_postal_number_rejected | TC-N09 | BC-DB | 70 |
| 42 | test_postaldispatch_71_duplicate_dispatch_number_rejected | TC-N10 | BC-DB | 71 |
| 43 | test_postaldispatch_72_postal_subject_not_null_at_db | TC-N11 | BC-DB | 72 |
| 44 | test_postaldispatch_73_dispatch_mode_other_diverges_from_ddl | TC-S02 | DEV | 73 |
| 45 | test_postaldispatch_74_dispatch_certificate_doctype_unreachable_via_form | TC-S03 | DEV | 74 |
| 46 | test_postaldispatch_75_whitespace_subject_still_required | TC-N12 | BC-VAL | 75 |
| 47 | test_postaldispatch_76_xss_payload_persisted_verbatim | TC-S04 | Security | 76 |
| 48 | test_postaldispatch_90_records_scoped_to_tenant | TC-T01 | Tenancy | 90 |
| 49 | test_postaldispatch_91_auto_number_not_user_overridable_via_store | TC-S05 | Security | 91 |

**Total: 49 test methods.**

---

## 5. Manual Test Steps (complex / workflow / DEV only)

### MTS-1 — Postal acknowledgement lock FSM (BR-FOF-009)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as user with `frontoffice.postal-register.update`; open `fof.menu.registers?tab=postal` | Inward list shows an **Acknowledge** button on unacknowledged entries |
| 2 | Create an Inward postal (modal `#addPostalModal`, subject filled) → Add Entry | Redirect to `?tab=postal`, toast "Postal entry added.", auto number `IN-YYYY-NNNN`. `SELECT postal_number,acknowledged_at FROM fof_postal_register WHERE subject='…'` → number set, `acknowledged_at` NULL |
| 3 | Click **Acknowledge** on that row | Toast "Postal entry acknowledged and locked." Row now shows `Ack. <date>` badge, no button. `SELECT acknowledged_at, acknowledgement_by` → both set |
| 4 | Click Acknowledge again (re-POST the PATCH) | HTTP **422** "This postal entry is already acknowledged." No change |
| 5 | Open Edit for the locked row and submit (PUT) | HTTP **422** "Acknowledgement already recorded — record is locked." (DAT-FOF-003 remediated) `SELECT subject` unchanged |
| 6 | Delete the locked row | HTTP **422** "…record is locked." `SELECT deleted_at` still NULL |
| 7 | On an **unacknowledged** row, Edit + submit, then Delete | Update succeeds (toast "Postal entry updated."); Delete → toast "moved to trash", `deleted_at` set |

### MTS-2 — Dispatch create + DEV divergences
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open `?tab=dispatch`, create modal `#addDispatchModal` | Modal shows Mode dropdown incl. **"Other"** and Doc-Type dropdown **without "Certificate"** |
| 2 | Select Mode = **Other**, fill required, submit | FormRequest passes; **DB insert fails** (ENUM has no Other) → 500 / value coerced to '' (DEV-FOF-DR-01). Confirm `SELECT dispatch_mode` is NOT 'Other' |
| 3 | Attempt Doc-Type = Certificate via crafted POST | FormRequest **rejects** (validation error) even though DDL allows it (DEV-FOF-DR-02) |
| 4 | Submit `addressee_name` of 120 chars | FormRequest passes (max:150) but column is VARCHAR(100) → truncated/`1406` (DEV-FOF-DR-03). Confirm stored length |
| 5 | Normal dispatch (Mode=Post, Doc=Letter) | Toast "Dispatch entry added.", `DSP-YYYY-NNNN`, `dispatched_by` = your id, `copy_retained` = 1 |

### MTS-3 — Permission gate (negative)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create a non-super-admin user with NO frontoffice permissions; clear permission cache | — |
| 2 | Visit `/front-office/postal-register` | 403 (Acknowledge / Add controls hidden by `@can`) |
| 3 | POST to `fof.postal-register.store` | 403; no row inserted |

---

## 6. Known Source Defects (carried as DEV-###)

| ID | Sev | Entity | Summary | Proving test |
|----|-----|--------|---------|--------------|
| DEV-FOF-DR-01 | P2 | Dispatch | `dispatch_mode` FormRequest+Blade allow `Other`, absent from DDL ENUM(Hand,Post,Courier,Email,Fax) → passes validation, DB refuses/coerces | `test_73` (+`test_02`) |
| DEV-FOF-DR-02 | P3 | Dispatch | `document_type` FormRequest+Blade omit `Certificate`, a valid DDL ENUM value → Certificate can never be dispatched | `test_74` (+`test_02`) |
| DEV-FOF-DR-03 | P2 | Dispatch | `addressee_name` FormRequest `max:150` exceeds DDL `VARCHAR(100)` → 101-150 char names pass validation then truncate/`1406` (G45/check-14) | `test_39` (+`test_02`) |
| DEV-FOF-PD-04 | P2 | Both | No `activityLog()` on store/update/acknowledge/toggle/destroy — only restore(`Restored`)/forceDelete(`Deleted`) logged. Audit trail gap for the primary lifecycle events | `test_45` documents; asserted absence noted |
| DAT-FOF-003 | P2 | Postal | **REMEDIATED in current source** — `update()` (L157) and `destroy()` (L173) now `abort_if($postal->isLocked(),422)`. FactPack §6 lists it as a live bypass; live code shows the guard present. Tests assert the OBSERVED (guarded) behaviour | `test_22`/`test_23` |
| DAT-FOF-002 | P2 | Both | Auto-number generators use `lockForUpdate()` read-modify-write; race can still dup under high concurrency (mitigated by the row lock + UNIQUE key) | `test_70`/`test_71` prove the UNIQUE backstop |
| SEC-FOF-003 | P1 | Both | `authorize(){return true;}` in both FormRequests (D30) — no defense-in-depth; controller `Gate::authorize` is the only guard | `test_51`/`test_53` |
