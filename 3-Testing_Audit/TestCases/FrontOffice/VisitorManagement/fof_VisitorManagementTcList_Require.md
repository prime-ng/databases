# FrontOffice → Visitor Management — Test Case List & Manual Testing Spec (COMBINED)

> **Compound feature:** `fof_visitors` (VisitorController) **+** `fof_visitor_purposes` (VisitorPurposeController).
> Single comprehensive Dusk suite: `fof_VisitorManagement_TestCas.php` (42 test methods).
> Sources read: DDL (FactPack §2), `RegisterVisitorRequest`, `StoreVisitorPurposeRequest`, `VisitorController`,
> `VisitorPurposeController`, `VisitorService`, `VisitorPolicy`, `Visitor`/`VisitorPurpose` models,
> `routes/web.php`, `create.blade.php` (both), screen file `visitor-management.md`, audit `FrontOffice_Technical_Audit_2026-06-29.md`.

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | FrontOffice (FOF) |
| Feature | VisitorManagement (compound) |
| Screen / menu | `GET /front-office/visitor-management?tab=visitors|visitor-purposes` (`fof.menu.visitorManagement`) |
| Primary URLs | `/front-office/visitors*` (`fof.visitors.*`), `/front-office/visitor-purposes*` (`fof.visitor-purposes.*`) |
| Controllers | `VisitorController`, `VisitorPurposeController` (+ `FofMenuController::visitorManagement`) |
| Service | `VisitorService` (pass-number gen, checkout FSM, flagOverstay) |
| Models | `Modules\FrontOffice\Models\Visitor` (`fof_visitors`), `Modules\FrontOffice\Models\VisitorPurpose` (`fof_visitor_purposes`) |
| FormRequests | `RegisterVisitorRequest`, `StoreVisitorPurposeRequest` (both `authorize(): true` — SEC-FOF-003 / D30) |
| Validation | Visitor: name req/max100, mobile req/regex `^[0-9]{10,15}$`, email nullable/email/max100, purpose_id req/exists, accompanying_count int 0–20, photo image ≤2MB. Purpose: name req/max100, code req/max30/**unique**, sort_order int 0–255. |
| Migrations | `2026_06_15_154601_create_fof_visitors_table.php`, `2026_06_15_154557_create_fof_visitor_purposes_table.php` (tenant) |
| CRUD type | Full CRUD + workflow (checkout FSM, toggle-status, overstay flag) on both entities |
| Soft delete | Yes on both (`SoftDeletes`; `deleted_at`) — verified in models & live schema |
| Pagination | visitors 25/page; visitor-purposes 20/page; trash 15/20 |
| Activity log | Tenant sink = **`sys_activity_logs`** via `Modules\GlobalMaster\Models\ActivityLog` (NOT `activity_logs` — see DEV-FOF-VM-05). Visitor events: `Created` (service), `Updated`, `Deleted` (soft & force), `Restored`, `CheckedOut`. **VisitorPurpose emits NO activity log** (DEV-FOF-VM-06). |
| Permission scheme | String gates `frontoffice.visitor.{view,create,update,delete,restore,forceDelete,checkout}`, `frontoffice.visitor-purpose.{viewAny,view,create,update,delete,restore,forceDelete}` (note: purpose index/trash use `viewAny`). |
| DB scope | TENANT-side → tenancy init in `setUp`, guarded `tenancy()->end()` in `tearDown`. |

## 2. Business Conditions

### BC-DB (DDL constraints — one testable fact per constraint)
| ID | Fact | Source |
|----|------|--------|
| BC-DB-01 | `fof_visitors` has all 26 DDL columns; live schema | DDL-fof_visitors |
| BC-DB-02 | `fof_visitors.pass_number` **UNIQUE** (`uq_fof_vis_pass_number`) | DDL-fof_visitors |
| BC-DB-03 | `fof_visitors` NOT-NULL-no-default user cols: `visitor_name`, `visitor_mobile`, `purpose_id` | DDL-fof_visitors |
| BC-DB-04 | `in_time` DEFAULT CURRENT_TIMESTAMP; `status` DEFAULT 'In' (auto — not user input) | DDL-fof_visitors |
| BC-DB-05 | VARCHAR sizes: visitor_name 100, visitor_mobile 15, visitor_email 100, id_proof_number 50, address 200, organization 100, person_to_meet 100, vehicle_number 20, pass_number 25 | DDL-fof_visitors |
| BC-DB-06 | FK `purpose_id` → `fof_visitor_purposes` **RESTRICT**; `meet_user_id`/`photo_media_id` SET NULL | DDL-fof_visitors |
| BC-DB-07 | `fof_visitors` soft-delete (`deleted_at`) + `SoftDeletes` trait (asserted independently) | DDL / Model |
| BC-DB-08 | `fof_visitor_purposes.code` **UNIQUE** (`uq_fof_vp_code`) | DDL-fof_visitor_purposes |
| BC-DB-09 | Purpose NOT-NULL-no-default user cols: `name`, `code` | DDL-fof_visitor_purposes |
| BC-DB-10 | Purpose VARCHAR: name 100, code 30; `sort_order` TINYINT-U default 0; `is_government_visit`/`is_active` default | DDL-fof_visitor_purposes |

### BC-VAL (FormRequest rules + messages)
| ID | Fact | Source |
|----|------|--------|
| BC-VAL-01 | visitor_name required, max:100 | RegisterVisitorRequest |
| BC-VAL-02 | visitor_mobile required, regex `/^[0-9]{10,15}$/` | RegisterVisitorRequest |
| BC-VAL-03 | visitor_email nullable, email, max:100 | RegisterVisitorRequest |
| BC-VAL-04 | purpose_id required, exists:fof_visitor_purposes,id | RegisterVisitorRequest |
| BC-VAL-05 | accompanying_count integer, min:0, max:20 (DDL allows 255 → stricter form, OK) | RegisterVisitorRequest |
| BC-VAL-06 | id_proof_type nullable in-enum; id_proof_number nullable max:50 — **no `required_with` pair rule** (BR-FOF-001 gap → DEV-FOF-VM-04) | RegisterVisitorRequest / Screen-BR-FOF-001 |
| BC-VAL-07 | purpose code unique:fof_visitor_purposes,code,{id} (edit-aware) | StoreVisitorPurposeRequest |
| BC-VAL-08 | purpose name required max:100; sort_order int 0–255 | StoreVisitorPurposeRequest |

### BC-AUTH (permission gate ↔ method)
| ID | Fact | Source |
|----|------|--------|
| BC-AUTH-01 | index/show/pass/trashed → `frontoffice.visitor.view` | VisitorController |
| BC-AUTH-02 | create/store → `frontoffice.visitor.create`; update/edit/toggleStatus → `.update` | VisitorController |
| BC-AUTH-03 | destroy → `.delete`; restore → `.restore`; forceDelete → `.forceDelete`; checkout → `.checkout` | VisitorController |
| BC-AUTH-04 | purpose index/trashed → `frontoffice.visitor-purpose.viewAny`; show → `.view`; store → `.create` | VisitorPurposeController |
| BC-AUTH-05 | Gates are Spatie permission strings, NOT model-bound policy (Gate::before grants Super Admin all) | VisitorController / Audit-SEC-FOF-001 |

### BC-BIZ (business logic / activity-log)
| ID | Fact | Source |
|----|------|--------|
| BC-BIZ-01 | `pass_number` auto-generated `VP-YYYYMMDD-NNN` by `VisitorService::generatePassNumber()` (uses `lockForUpdate`) | VisitorService |
| BC-BIZ-02 | On register: status='In', in_time=now(), created_by/updated_by=auth id (auto) | VisitorService |
| BC-BIZ-03 | Activity `Created` logged on register with pass in properties | VisitorService |
| BC-BIZ-04 | Activity `Updated`/`Deleted`/`Restored` on visitor lifecycle; force-delete also logs `Deleted` | VisitorController |
| BC-BIZ-05 | `id_proof_number` stored plaintext — no encrypted cast, no masking accessor (BR-FOF-015 unmet → SEC-FOF-004) | Visitor model / Audit-SEC-FOF-004 |
| BC-BIZ-06 | `VisitorService::flagOverstay()` sets In+no-out → 'Overstay', writes `updated_by=null` (ORM-FOF-001) | VisitorService / Audit-ORM-FOF-001 |
| BC-BIZ-07 | Purpose is_active defaults true; created_by/updated_by=auth id; **no activity log** | VisitorPurposeController |

### BC-SM (state machine — visitor status)
| ID | State → Trigger → Next | Source |
|----|----------------------|--------|
| BC-SM-01 | In → checkout → Out (out_time set, `CheckedOut` logged) | Screen-SM / VisitorService |
| BC-SM-02 | Overstay → checkout → Out (allowed) | VisitorService |
| BC-SM-03 | Out → checkout → **rejected 422** ("Only visitors currently on campus can be checked out.") | VisitorService (abort_if) |
| BC-SM-04 | In → flagOverstay (scheduler) → Overstay | VisitorService / BR-FOF-002 |
| BC-SM-05 | is_active true ↔ toggleStatus → flips (JSON) | VisitorController |

### BC-REF / BC-INT (FK & cross-module)
| ID | Fact | Source |
|----|------|--------|
| BC-REF-01 | purpose_id RESTRICT: purpose referenced by a visitor cannot be force-deleted | DDL |
| BC-INT-01 | `meet_user_id`→sys_users, `photo_media_id`→sys_media, `vsm_visitor_id`→vsm (pending, no FK) — cross-module, guarded | DDL / FactPack §5 |

### BC-EDG (edge/boundary)
| ID | Fact | Source |
|----|------|--------|
| BC-EDG-01 | Soft-delete → trash → restore roundtrip | Screen |
| BC-EDG-02 | Force-delete removes record entirely | Controller |
| BC-EDG-03 | Restore/show unknown id → 404 | Route model binding |
| BC-EDG-04 | XSS payload in visitor_name escaped by Blade on render | Security |

## 3. Test Case List

### Positive (TC-P)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-P01 | Schema | BC-DB-01/05/07 | DDL | Full visitor DDL↔app alignment | All cols/casts/soft-delete asserted | `test_..._01` | Ready |
| TC-P02 | Schema | BC-DB-08/09/10 | DDL | Purpose schema + UNIQUE index | code UNIQUE index present | `test_..._02` | Ready |
| TC-P03 | Schema | BC-BIZ | Model | Relationships + scopes resolve | belongsTo/hasMany/active/ordered/onCampus | `test_..._03` | Ready |
| TC-P04 | Config | BC-AUTH | routes | All web routes registered | Route::has true for 17 names | `test_..._04` | Ready |
| TC-P10 | Biz | BC-BIZ-01/02 | Service | Auto pass_number `VP-…` + status In | regex match, created_by=admin | `test_..._10` | Ready |
| TC-P11 | Biz | BC-BIZ-07 | Controller | Purpose is_active default + govt flag | is_active true, govt persists | `test_..._11` | Ready |
| TC-P14 | Biz | BC-BIZ-03 | Service | Activity `Created` on register | log row exists | `test_..._14` | Ready |
| TC-P15 | Biz | BC-BIZ-04 | Controller | Activity `Updated` on update | log row exists | `test_..._15` | Ready |
| TC-P20 | SM | BC-SM-01 | Service | Checkout In→Out | status Out, out_time set | `test_..._20` | Ready |
| TC-P21 | SM | BC-SM-02 | Service | Checkout Overstay→Out | status Out | `test_..._21` | Ready |
| TC-P23 | SM | BC-SM-05 | Controller | toggle-status flips is_active | 200 + flipped | `test_..._23` | Ready |
| TC-P33 | Val | BC-DB-05 | DDL | visitor_name exactly 100 accepted | saved len 100 | `test_..._33` | Ready |
| TC-P36 | Val | BC-DB (nullable) | DDL | Nullable optional fields accept null | row saves | `test_..._36` | Ready |
| TC-P60 | UI | BC-AUTH-01 | Blade | Index + menu render, shows pass | no Server Error, sees pass | `test_..._60` | Ready |
| TC-P61 | UI | BC-VAL-04 | Blade | Create page + purpose dropdown | fields + purpose name present | `test_..._61` | Ready |
| TC-P62 | UI | Screen | Blade | Pass print view renders | shows pass_number | `test_..._62` | Ready |
| TC-P63 | UI | BC-BIZ | Controller | Index search by name | filtered result visible | `test_..._63` | Ready |
| TC-P70 | Edge | BC-EDG-01 | Screen | Soft-delete → restore roundtrip | trashed then restored | `test_..._70` | Ready |
| TC-P71 | Edge | BC-EDG-02 | Controller | Force-delete removes record | gone from withTrashed | `test_..._71` | Ready |

### Negative (TC-N)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-N30 | Required | BC-DB-03 | DDL | Missing visitor_name/mobile/purpose_id | DB NOT NULL rejection | `test_..._30` | Ready |
| TC-N31 | Required | BC-DB-09 | DDL | Missing purpose name/code | DB NOT NULL rejection | `test_..._31` | Ready |
| TC-N32 | Length | BC-DB-05 | DDL | visitor_name > 100 | rejected/truncated ≤100 | `test_..._32` | Ready |
| TC-N34 | Length | BC-DB-10 | DDL | purpose code > 30 | rejected/truncated ≤30 | `test_..._34` | Ready |
| TC-N35 | Format | BC-VAL-02 | FormRequest | Mobile fails regex | store rejected, not persisted | `test_..._35` | Ready |
| TC-N42 | Unique | BC-DB-02 | DDL | Duplicate pass_number | UNIQUE violation | `test_..._42` | Ready |
| TC-N43 | Unique | BC-DB-08 | DDL | Duplicate purpose code | UNIQUE violation | `test_..._43` | Ready |
| TC-N44 | FK | BC-REF-01 | DDL | Force-delete referenced purpose | RESTRICT blocks | `test_..._44` | Ready |
| TC-N45 | FK | BC-VAL-04 | FormRequest | Non-existent purpose_id | store rejected | `test_..._45` | Ready |
| TC-N50 | Auth | BC-AUTH | routes | Guest → login redirect | 302 login / 401 | `test_..._50` | Ready |
| TC-N51 | Auth | BC-AUTH-01 | Gate | View forbidden w/o perm (403) | 403 (non-super-admin) | `test_..._51` | Ready |
| TC-N52 | Auth | BC-AUTH-02 | Gate | Create forbidden w/o perm | 403 | `test_..._52` | Ready |
| TC-N53 | Auth | BC-AUTH-04 | Gate | Purpose viewAny forbidden | 403 | `test_..._53` | Ready |
| TC-N22 | SM | BC-SM-03 | Service | Checkout when already Out | 422 rejection | `test_..._22` | Ready |
| TC-N72 | Edge | BC-EDG-03 | routes | Restore unknown id | 404 | `test_..._72` | Ready |
| TC-S73 | Security | BC-EDG-04 | Blade | XSS in name escaped | no executable script node | `test_..._73` | Ready |
| TC-S90 | Security | BC-INT | routes | Unknown/cross-tenant id | 404 (no leak) | `test_..._90` | Ready |
| TC-S91 | Security | BC-DB | Model | PK not mass-assignable | id unchanged | `test_..._91` | Ready |

### Defect-proving (document current behaviour)
| TC ID | Cat | Defect | Description | Expected (current) | Method |
|-------|-----|--------|-------------|--------------------|--------|
| TC-D16 | Security | SEC-FOF-004 | id_proof plaintext | raw value == input, no encrypted cast/accessor | `test_..._16` |
| TC-D17 | Job | JOB-FOF-002 / ORM-FOF-001 | flagOverstay service works; updated_by=null | In→Overstay, updated_by null | `test_..._17` |
| TC-D18 | Audit | DEV-FOF-VM-06 | Purpose controller no activity log | source has no `activityLog(` | `test_..._18` |
| TC-D37 | Val | DEV-FOF-VM-04 | BR-FOF-001 pair rule missing | request has no `required_with` | `test_..._37` |
| TC-D54 | Security | SEC-FOF-001 | Govt visitor deletable (policy bypassed) | soft-delete succeeds | `test_..._54` |

## 4. Test Method Index (42 methods)

| # | Method | TC | Cat | Band |
|---|--------|----|-----|------|
| 1 | test_visitor_management_01_schema_model_and_request_configuration_are_correct | TC-P01 | Schema | 01–09 |
| 2 | test_visitor_management_02_purpose_schema_model_and_unique_index_are_correct | TC-P02 | Schema | 01–09 |
| 3 | test_visitor_management_03_relationships_and_scopes_resolve | TC-P03 | Schema | 01–09 |
| 4 | test_visitor_management_04_web_routes_are_registered | TC-P04 | Config | 01–09 |
| 5 | test_visitor_management_10_pass_number_auto_generated_in_vp_format | TC-P10 | Biz | 10–19 |
| 6 | test_visitor_management_11_purpose_is_active_defaults_true_and_govt_flag_persists | TC-P11 | Biz | 10–19 |
| 7 | test_visitor_management_14_activity_log_created_event_on_register | TC-P14 | Biz | 10–19 |
| 8 | test_visitor_management_15_activity_log_updated_and_deleted_events | TC-P15 | Biz | 10–19 |
| 9 | test_visitor_management_16_id_proof_number_stored_plaintext_SEC_FOF_004 | TC-D16 | Sec | 10–19 |
| 10 | test_visitor_management_17_flag_overstay_service_promotes_in_visitors_BR_FOF_002 | TC-D17 | Job | 10–19 |
| 11 | test_visitor_management_18_purpose_controller_emits_no_activity_log_DEV | TC-D18 | Audit | 10–19 |
| 12 | test_visitor_management_20_checkout_transitions_in_to_out | TC-P20 | SM | 20–29 |
| 13 | test_visitor_management_21_checkout_allowed_from_overstay | TC-P21 | SM | 20–29 |
| 14 | test_visitor_management_22_checkout_rejected_when_already_out | TC-N22 | SM | 20–29 |
| 15 | test_visitor_management_23_toggle_status_endpoint_flips_is_active | TC-P23 | SM | 20–29 |
| 16 | test_visitor_management_30_required_columns_reject_missing_values | TC-N30 | Val | 30–39 |
| 17 | test_visitor_management_31_purpose_required_columns_reject_missing_values | TC-N31 | Val | 30–39 |
| 18 | test_visitor_management_32_visitor_name_over_length_is_not_persisted_beyond_100 | TC-N32 | Val | 30–39 |
| 19 | test_visitor_management_33_visitor_name_exactly_100_chars_is_accepted | TC-P33 | Val | 30–39 |
| 20 | test_visitor_management_34_purpose_code_over_length_boundary | TC-N34 | Val | 30–39 |
| 21 | test_visitor_management_35_mobile_regex_rejected_via_form_request | TC-N35 | Val | 30–39 |
| 22 | test_visitor_management_36_nullable_fields_accept_null | TC-P36 | Val | 30–39 |
| 23 | test_visitor_management_37_br_fof_001_id_proof_pair_not_enforced_DEV | TC-D37 | Val | 30–39 |
| 24 | test_visitor_management_42_duplicate_pass_number_rejected_by_db | TC-N42 | Unique | 40–49 |
| 25 | test_visitor_management_43_duplicate_purpose_code_rejected_by_db | TC-N43 | Unique | 40–49 |
| 26 | test_visitor_management_44_purpose_id_fk_restrict_blocks_hard_delete | TC-N44 | FK | 40–49 |
| 27 | test_visitor_management_45_invalid_purpose_id_rejected_by_form_request | TC-N45 | FK | 40–49 |
| 28 | test_visitor_management_50_guest_is_redirected_to_login | TC-N50 | Auth | 50–59 |
| 29 | test_visitor_management_51_visitor_view_forbidden_without_permission | TC-N51 | Auth | 50–59 |
| 30 | test_visitor_management_52_visitor_create_forbidden_without_permission | TC-N52 | Auth | 50–59 |
| 31 | test_visitor_management_53_purpose_viewany_forbidden_without_permission | TC-N53 | Auth | 50–59 |
| 32 | test_visitor_management_54_government_visitor_is_deletable_SEC_FOF_001 | TC-D54 | Sec | 50–59 |
| 33 | test_visitor_management_60_index_and_menu_pages_render | TC-P60 | UI | 60–69 |
| 34 | test_visitor_management_61_create_page_renders_with_purpose_dropdown | TC-P61 | UI | 60–69 |
| 35 | test_visitor_management_62_pass_print_view_renders | TC-P62 | UI | 60–69 |
| 36 | test_visitor_management_63_index_search_filters_by_name | TC-P63 | UI | 60–69 |
| 37 | test_visitor_management_70_soft_delete_then_restore_roundtrip | TC-P70 | Edge | 70–79 |
| 38 | test_visitor_management_71_force_delete_removes_record | TC-P71 | Edge | 70–79 |
| 39 | test_visitor_management_72_restore_invalid_id_returns_404 | TC-N72 | Edge | 70–79 |
| 40 | test_visitor_management_73_xss_in_visitor_name_is_escaped_on_render | TC-S73 | Sec | 70–79 |
| 41 | test_visitor_management_90_cross_tenant_direct_id_is_not_exposed | TC-S90 | Tenancy | 90–99 |
| 42 | test_visitor_management_91_mass_assignment_guard_on_auto_fields | TC-S91 | Sec | 90–99 |

## 5. Manual Test Steps (workflow / defect paths only)

### MT-1 — Checkout FSM (BC-SM-01/02/03)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Register a visitor (purpose selected) | Row created, status badge **In**, pass `VP-YYYYMMDD-NNN`. DB: `SELECT status,in_time FROM fof_visitors WHERE id=? → In, now`. |
| 2 | Click Checkout on that visitor | Toast "checked out successfully". DB: `status='Out'`, `out_time` set. Activity: `sys_activity_logs` has `CheckedOut`. |
| 3 | Attempt Checkout again on same visitor | Rejected (HTTP 422 "Only visitors currently on campus can be checked out."); status stays Out. |
| 4 | (Scheduler) run `fof:flag-overstay` with an In+no-out visitor | That visitor → status **Overstay**. NOTE JOB-FOF-002: command is not scheduled / not `tenants:run`-wrapped in production; run manually per tenant. |

### MT-2 — Government-retention (SEC-FOF-001 defect)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create purpose with **Government Visit** checked (`is_government_visit=1`) | Purpose saved. |
| 2 | Register a visitor with that purpose | Visitor saved. |
| 3 | Delete that visitor (as a user with `frontoffice.visitor.delete`) | **Deletion SUCCEEDS today** (soft-deleted). BR-FOF-007 intends this to be blocked, but `destroy()` uses the string gate, not `VisitorPolicy::delete()`. DB: `deleted_at` set. **Record as SEC-FOF-001.** |

### MT-3 — ID proof PII (SEC-FOF-004 defect)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Register visitor with ID proof type Aadhar + number `AADHAAR123456` | Saved. |
| 2 | Inspect DB | `SELECT id_proof_number … → AADHAAR123456` (full plaintext; no encryption). UI shows last-4 only per spec, but storage is plaintext. **Record SEC-FOF-004.** |

## 6. Known Source Defects (DEV-###)

| ID | Sev | Summary | Proving method |
|----|-----|---------|----------------|
| SEC-FOF-001 | P1 | Govt-retention (BR-FOF-007) bypassed — `destroy`/`forceDelete` use string gate, not `VisitorPolicy` guard; govt visitor deletable | `test_..._54` |
| JOB-FOF-002 | P1 | `fof:flag-overstay` not scheduled / not `tenants:run`-wrapped → `Overstay` unreachable in prod (service method itself works) | `test_..._17` |
| SEC-FOF-004 | P2 | `id_proof_number` stored plaintext — no encrypted cast, no masking accessor (BR-FOF-015 unmet) | `test_..._16` |
| SEC-FOF-003 | P1 | Both FormRequests `authorize(){return true;}` (D30) — no defense-in-depth | `test_..._01` (asserts request structure) |
| ORM-FOF-001 | P3 | `flagOverstay()` writes `updated_by=null` (non-existent user) | `test_..._17` |
| DEV-FOF-VM-04 | P2 | BR-FOF-001 (id-proof type+number both-or-neither) not enforced — no `required_with` in RegisterVisitorRequest | `test_..._37` |
| DEV-FOF-VM-05 | P3 (DOC) | FactPack states tenant sink `activity_logs`; real tenant `ActivityLog` model binds `sys_activity_logs`. Suite asserts the model's actual table. | `test_..._14/15` |
| DEV-FOF-VM-06 | P2 | `VisitorPurposeController` emits NO activity log on any CRUD (audit-trail gap vs VisitorController) | `test_..._18` |
| Note (not a defect) | — | DAT-FOF-002 mitigation: `VisitorService::generatePassNumber()` **does** use `lockForUpdate()` — visitor pass-number generation is row-locked (corrects FactPack "unlocked read-modify-write" for this feature). | — |
