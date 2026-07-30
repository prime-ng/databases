# FrontOffice → Complaint — Test Case List & Manual Test Spec (COMBINED)

> Single-source combined artifact: Feature Information + Business Conditions (incl. BC-SM) +
> Test Case List + Test Method Index + Manual Test Steps (workflow/money only) + Known Defects.
> Feature unit = screen `FrontOffice_v1/complaints.md`. Test file: `fof_Complaint_TestCas.php`.

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | FrontOffice (FOF) |
| Feature | Complaint (front-office lightweight complaint intake) |
| Primary table | `fof_complaints` (prefix `fof_` — verified vs DDL `CREATE TABLE`) |
| Controller | `Modules\FrontOffice\Http\Controllers\ComplaintController` |
| Model | `Modules\FrontOffice\Models\FofComplaint` (`$table = fof_complaints`, `SoftDeletes`, `HasFactory`) |
| Validation | **Inline `$request->validate()` in controller** (no dedicated FormRequest) |
| Migrations | None module-local; live table from consolidated tenant migration set / DDL |
| CRUD Type | Full-page CRUD (create/edit/show/index/trash) + workflow verbs (resolve, escalate, toggleStatus) |
| Soft Delete | Yes (`deleted_at`); trash / restore / forceDelete routes |
| Pagination | Yes — index paginate(20) open + closed sections; trash paginate(15) |
| Activity Log | `activityLog()` → `Modules\GlobalMaster\Models\ActivityLog` → **`sys_activity_logs`** |
| DB scope | **TENANT-SIDE** (tenancy init required in setUp; `tenancy()->end()` in tearDown) |
| Base URL prefix | `/front-office` (auth+verified group); route-name base `fof.complaints.` |

### Routes (verbatim — `Modules/FrontOffice/routes/web.php`)
| Verb | Path | Name | Controller method | Permission gate |
|------|------|------|-------------------|-----------------|
| GET | `/front-office/complaints` | `fof.complaints.index` | index | `frontoffice.complaint.view` |
| GET | `/front-office/complaints/create` | `fof.complaints.create` | create | `frontoffice.complaint.create` |
| POST | `/front-office/complaints` | `fof.complaints.store` | store | `frontoffice.complaint.create` |
| GET | `/front-office/complaints/{complaint}` | `fof.complaints.show` | show | `frontoffice.complaint.view` |
| GET | `/front-office/complaints/{complaint}/edit` | `fof.complaints.edit` | edit | `frontoffice.complaint.update` |
| PUT | `/front-office/complaints/{complaint}` | `fof.complaints.update` | update | `frontoffice.complaint.update` |
| DELETE | `/front-office/complaints/{complaint}` | `fof.complaints.destroy` | destroy | `frontoffice.complaint.delete` |
| PATCH | `/front-office/complaints/{complaint}/resolve` | `fof.complaints.resolve` | resolve | `frontoffice.complaint.update` |
| PATCH | `/front-office/complaints/{complaint}/escalate` | `fof.complaints.escalate` | escalate | `frontoffice.complaint.update` |
| POST/PATCH | `/front-office/complaints/{complaint}/toggle-status` | `fof.complaints.toggleStatus` | toggleStatus | `frontoffice.complaint.update` |
| GET | `/front-office/complaints/trash/view` | `fof.complaints.trashed` | trashed | `frontoffice.complaint.view` |
| GET | `/front-office/complaints/{id}/restore` | `fof.complaints.restore` | restore | `frontoffice.complaint.restore` |
| DELETE | `/front-office/complaints/{id}/force-delete` | `fof.complaints.forceDelete` | forceDelete | `frontoffice.complaint.forceDelete` |

### Activity events (verbatim from controller — NOT the `Created/Updated` set the FactPack predicted)
| Method | Event string |
|--------|-------------|
| store | `complaint_registered` |
| update | `complaint_updated` |
| destroy | `complaint_deleted` |
| resolve | `complaint_resolved` |
| escalate | `complaint_escalated` |
| restore | `Restored` |
| forceDelete | `Deleted` |

### Blade form fields (verbatim — `create.blade.php` / `edit.blade.php`)
- create: `complainant_name`, `complainant_contact`, `complaint_type` (select), `description` (textarea), `urgency` (select). Submit button text **"Register Complaint"**.
- edit: adds `assigned_to_user_id` (select), `resolution_notes` (textarea), `status` (select), `is_active` (switch). Submit **"Update Complaint"**.
- `complaint_type` select options (both blades): `Academic, Infrastructure, Staff, Transport, Fee, Other` — **diverges from DDL ENUM** (see DEV-FOF-CMP-01).

---

## 2. Business Conditions

### BC-DB (DDL constraints — `fof_complaints`)
| ID | Fact | Source |
|----|------|--------|
| BC-DB-01 | `complaint_number VARCHAR(30) NOT NULL`, UNIQUE `uq_fof_cmp_complaint_number` → duplicate rejected | DDL-fof_complaints |
| BC-DB-02 | `complainant_name VARCHAR(100) NOT NULL` (no default) → missing rejected; 100 ok, 101 rejected | DDL-fof_complaints |
| BC-DB-03 | `complainant_contact VARCHAR(15) NULL` → omit ok; 16 rejected | DDL-fof_complaints |
| BC-DB-04 | `complaint_type ENUM(Academic,Facility,Staff_Behavior,Fee,Safety,Transportation,Food,Hygiene,Other) NOT NULL` | DDL-fof_complaints |
| BC-DB-05 | `description TEXT NOT NULL` (no default) → missing rejected | DDL-fof_complaints |
| BC-DB-06 | `urgency ENUM(Normal,Urgent,Critical) NOT NULL DEFAULT 'Normal'` → default applied | DDL-fof_complaints |
| BC-DB-07 | `status ENUM(Open,In_Progress,Resolved,Closed,Escalated) NOT NULL DEFAULT 'Open'` → default applied | DDL-fof_complaints |
| BC-DB-08 | `is_active TINYINT(1) NOT NULL DEFAULT 1` → default applied | DDL-fof_complaints |
| BC-DB-09 | FK `assigned_to_user_id → sys_users` ON DELETE SET NULL | DDL-fof_complaints |
| BC-DB-10 | FK `resolved_by → sys_users` ON DELETE SET NULL | DDL-fof_complaints |
| BC-DB-11 | FK `cmp_complaint_id → cmp_complaints` ON DELETE SET NULL (cross-module) | DDL-fof_complaints |
| BC-DB-12 | `created_by`/`updated_by BIGINT UNSIGNED NOT NULL` (no FK) — controller-set, not form input (G48) | DDL-fof_complaints |
| BC-DB-13 | `deleted_at TIMESTAMP NULL` + model `SoftDeletes` trait (assert independently) | DDL / model |

### BC-VAL (controller inline validation)
| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | store: `complainant_name required string max:100` | Controller store() |
| BC-VAL-02 | store: `complainant_contact nullable string max:15` | Controller store() |
| BC-VAL-03 | store: `complaint_type required in:Academic,Infrastructure,Staff,Transport,Fee,Other` | Controller store() |
| BC-VAL-04 | store: `description required string` | Controller store() |
| BC-VAL-05 | store: `urgency required in:Normal,Urgent,Critical` | Controller store() |
| BC-VAL-06 | update adds: `status required in:Open,In_Progress,Resolved,Escalated,Closed`, `resolution_notes nullable max:1000`, `assigned_to_user_id nullable integer exists:sys_users,id` | Controller update() |
| BC-VAL-07 | resolve: `resolution_notes required string max:1000` | Controller resolve() |

### BC-AUTH (permissions — Spatie string gates, `Gate::authorize`)
| ID | Fact | Source |
|----|------|--------|
| BC-AUTH-01 | index/show/trashed require `frontoffice.complaint.view` | Controller |
| BC-AUTH-02 | create/store require `frontoffice.complaint.create` | Controller |
| BC-AUTH-03 | edit/update/resolve/escalate/toggleStatus require `frontoffice.complaint.update` | Controller |
| BC-AUTH-04 | destroy requires `frontoffice.complaint.delete` | Controller |
| BC-AUTH-05 | restore requires `frontoffice.complaint.restore`; forceDelete requires `frontoffice.complaint.forceDelete` | Controller |
| BC-AUTH-06 | `Gate::before` grants Super Admin ALL — negatives must use a non-super-admin (#31) | Rule Card #31 |

### BC-BIZ (business rules)
| ID | Fact | Source |
|----|------|--------|
| BC-BIZ-01 | store auto-generates `complaint_number` = `CMP-YYYYMMDD-NNN` (row-locked read-modify-write) | Controller generateComplaintNumber() |
| BC-BIZ-02 | store forces `status='Open'`, `created_by`/`updated_by=auth id`; client status/number ignored | Controller store() |
| BC-BIZ-03 | index splits Open+In_Progress (ordered by urgency) vs Resolved/Escalated/Closed | Controller index() |
| BC-BIZ-04 | resolve sets `status=Resolved`, `resolution_notes`, `resolved_by`, `resolved_at` | Controller resolve() |
| BC-BIZ-05 | escalate creates a linked `cmp_complaints` row and sets `cmp_complaint_id`, `status=Escalated` | Controller escalate() |
| BC-BIZ-06 | toggleStatus flips `is_active` and returns JSON `{success,message,is_active}` | Controller toggleStatus() |

### BC-SM (state machine — `status`)
```
Open ──(update)──▶ In_Progress ──(resolve)──▶ Resolved
  │                    │
  ├──(resolve)─────────┘
  └──(escalate)──▶ Escalated (creates CMP)
Open/In_Progress ──(update, no guard)──▶ Closed | any state   ← DEV-FOF-CMP-02
```
| ID | State | Trigger | Next | Legal? | Source |
|----|-------|---------|------|--------|--------|
| BC-SM-01 | Open | resolve (+notes) | Resolved | legal | Controller resolve() |
| BC-SM-02 | In_Progress | resolve (+notes) | Resolved | legal | Controller resolve() |
| BC-SM-03 | Resolved/Escalated/Closed | resolve | — | ILLEGAL → DomainException | Controller resolve() throw_unless |
| BC-SM-04 | Open/In_Progress | escalate | Escalated | legal (cross-module) | Controller escalate() |
| BC-SM-05 | Resolved/Closed/Escalated | escalate | — | ILLEGAL → DomainException | Controller escalate() throw_unless |
| BC-SM-06 | any (cmp_complaint_id set) | escalate | — | ILLEGAL → DomainException | Controller escalate() throw_unless |
| BC-SM-07 | Open | update (status=Closed) | Closed | **permitted (no FSM guard)** → DEV-FOF-CMP-02 | Controller update() |

### BC-INT (integration / cross-module)
| ID | Fact | Source |
|----|------|--------|
| BC-INT-01 | escalate touches `cmp_complaints`, `cmp_complaint_categories`, `sys_dropdown_table` — guard + skip if absent | Controller escalate() |
| BC-INT-02 | `assigned_to_user_id`/`resolved_by` reference `sys_users` | DDL FK |

### BC-EDG (edge)
| ID | Fact | Source |
|----|------|--------|
| BC-EDG-01 | Unknown complaint id (RMB) → 404 | Route model binding |
| BC-EDG-02 | Stored XSS in `description` must render escaped on show | Security |
| BC-EDG-03 | soft-delete → restore → force-delete lifecycle intact | Model SoftDeletes |

---

## 3. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-* | DDL | Schema/model/route config alignment | All present | `_01_` | Auto |
| TC-P02 | BC-BIZ-01/02 | Controller | Store creates complaint, status Open, auto number, activity | Row + `complaint_registered` | `_10_` | Auto |
| TC-P03 | BC-DB-06 | DDL | urgency DB default Normal | 'Normal' | `_13_` | Auto |
| TC-P04 | BC-DB-07 | DDL | status DB default Open | 'Open' | `_14_` | Auto |
| TC-P05 | BC-DB-08 | DDL | is_active default true | true | `_12_` | Auto |
| TC-P06 | BC-BIZ-03 | Controller | Index renders open/closed sections | Complaint listed | `_15_` | Auto |
| TC-P07 | BC-VAL-01(max) | Controller | complainant_name exactly 100 accepted | Row created | `_33_` | Auto |
| TC-P08 | BC-BIZ-06 | Controller | toggle-status returns 200 + flips is_active | 200 JSON | `_63_` | Auto |
| TC-P09 | BC-EDG-03 | Model | soft-delete/restore/force-delete lifecycle | State intact | `_72_` | Auto |
| TC-P10 | BC-BIZ-03 | Controller | Index search by complainant_name | Match shown | `_60_` | Auto |
| TC-P11 | BC-BIZ-03 | Controller | Index status filter | Match shown | `_61_` | Auto |
| TC-P12 | BC-DB-01 | DDL | Show page displays detail | complaint_number visible | `_62_` | Auto |
| TC-P13 | BC-EDG-03 | Model | Trash page lists soft-deleted | Number shown | `_73_` | Auto |

### State-machine (TC-SM)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-SM01 | BC-SM-01 | Controller | Open → Resolved (resolve) | status Resolved + `complaint_resolved` | `_20_` | Auto |
| TC-SM02 | BC-SM-02 | Controller | In_Progress → Resolved | status Resolved | `_21_` | Auto |
| TC-SM03 | BC-SM-03 | Controller | resolve when Resolved (illegal) | rejected {403,419,500,302}, unchanged | `_22_` | Auto |
| TC-SM04 | BC-SM-04 | Controller | Open → Escalated + CMP row (cross-module) | linked cmp_complaints + `complaint_escalated` | `_23_` | Auto/Skip |
| TC-SM05 | BC-SM-06 | Controller | escalate when already linked (illegal) | rejected, unchanged | `_24_` | Auto |
| TC-SM06 | BC-SM-05 | Controller | escalate when Closed (illegal) | rejected, unchanged | `_25_` | Auto |
| TC-SM07 | BC-SM-07 | Controller | update sets status Closed (no FSM guard) | Closed persisted (DEV-FOF-CMP-02) | `_26_` | Auto |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-DB-01 | DDL | Duplicate complaint_number | UNIQUE violation | `_02_` | Auto |
| TC-N02 | BC-VAL-01/03/04/05 | Controller | Store missing required web fields | No row created | `_30_` | Auto |
| TC-N03 | BC-DB-02/04/05 | DDL | DB insert missing NOT-NULL columns | Integrity error | `_31_` | Auto |
| TC-N04 | BC-VAL-01 | Controller | complainant_name 101 chars | No row | `_32_` | Auto |
| TC-N05 | BC-VAL-02 | Controller | complainant_contact 16 chars | No row | `_34_` | Auto |
| TC-N06 | BC-VAL-03 | Controller | Invalid complaint_type | No row | `_35_` | Auto |
| TC-N07 | BC-VAL-05 | Controller | Invalid urgency | No row | `_36_` | Auto |
| TC-N08 | BC-VAL-07 | Controller | resolve missing resolution_notes | status unchanged | `_37_` | Auto |
| TC-N09 | BC-VAL-06 | Controller | update non-existent assigned_to_user_id | not persisted | `_41_` | Auto |
| TC-N10 | BC-EDG-01 | Route | Unknown id → 404 | 404 | `_70_` | Auto |

### Dependency / FK (TC-D)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-D01 | BC-DB-09/10/11 | DDL | FKs configured (assigned/resolved/cmp) | 3 FKs present | `_40_` | Auto |
| TC-D02 | BC-DB-11 | DDL | cmp_complaint_id ON DELETE SET NULL | SET NULL | `_42_` | Auto/Skip |
| TC-D03 | BC-INT-01 | Controller | escalate cross-module CMP creation | linked row (or skip) | `_23_` | Auto/Skip |

### Permissions (TC-AUTH)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-AU01 | — | Auth | Guest → /login | redirect | `_50_` | Auto |
| TC-AU02 | BC-AUTH-01/06 | Controller | No `view` perm → 403 index | 403 | `_51_` | Auto |
| TC-AU03 | BC-AUTH-02 | Controller | No `create` perm → store blocked | {403,419}, no row | `_52_` | Auto |
| TC-AU04 | BC-AUTH-04 | Controller | No `delete` perm → destroy blocked | {403,419}, not deleted | `_53_` | Auto |

### Security / Tenancy (TC-S / TC-T)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-S01 | BC-EDG-02 | Security | XSS in description escaped on show | raw script absent | `_71_` | Auto |
| TC-S02 | BC-BIZ-02 | Security | Store ignores client status/number (mass-assign) | status Open, number CMP- | `_90_` | Auto |
| TC-T01 | — | Tenancy | Cross-tenant direct-ID IDOR | 404 (skip if 1 tenant) | `_91_` | Skip-doc |
| TC-DEV1 | — | DDL vs app | complaint_type ENUM divergence | documented DEV | `_04_` | Auto |
| TC-DEV2 | — | Controller | complaint_number format vs spec | CMP-Ymd-NNN | `_11_` | Auto |
| TC-CFG1 | BC-DB-13 | DDL/model | soft-delete column & trait independent | both present | `_03_` | Auto |

---

## 4. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_complaint_01_migration_model_and_request_configuration_are_correct` | TC-P01 | Schema | 01–09 |
| 2 | `test_complaint_02_complaint_number_unique_index_rejects_duplicates` | TC-N01 | Schema/Unique | 01–09 |
| 3 | `test_complaint_03_soft_delete_column_and_trait_are_independently_present` | TC-CFG1 | Schema | 01–09 |
| 4 | `test_complaint_04_complaint_type_enum_diverges_between_ddl_and_app` | TC-DEV1 | Schema/DEV | 01–09 |
| 5 | `test_complaint_10_store_registers_complaint_with_defaults_and_activity` | TC-P02 | BizRule | 10–19 |
| 6 | `test_complaint_11_complaint_number_format_follows_code_not_spec` | TC-DEV2 | BizRule/DEV | 10–19 |
| 7 | `test_complaint_12_is_active_defaults_true_on_direct_create` | TC-P05 | BizRule | 10–19 |
| 8 | `test_complaint_13_urgency_defaults_normal_at_db_level` | TC-P03 | BizRule | 10–19 |
| 9 | `test_complaint_14_status_defaults_open_at_db_level` | TC-P04 | BizRule | 10–19 |
| 10 | `test_complaint_15_index_page_renders_open_and_closed_sections` | TC-P06 | BizRule | 10–19 |
| 11 | `test_complaint_20_resolve_transitions_open_to_resolved` | TC-SM01 | StateMachine | 20–29 |
| 12 | `test_complaint_21_resolve_transitions_in_progress_to_resolved` | TC-SM02 | StateMachine | 20–29 |
| 13 | `test_complaint_22_resolve_rejected_when_already_resolved` | TC-SM03 | StateMachine | 20–29 |
| 14 | `test_complaint_23_escalate_open_creates_linked_cmp_record` | TC-SM04/TC-D03 | StateMachine/Int | 20–29 |
| 15 | `test_complaint_24_escalate_rejected_when_already_linked` | TC-SM05 | StateMachine | 20–29 |
| 16 | `test_complaint_25_escalate_rejected_when_closed` | TC-SM06 | StateMachine | 20–29 |
| 17 | `test_complaint_26_update_allows_direct_status_change_bypassing_fsm` | TC-SM07 | StateMachine/DEV | 20–29 |
| 18 | `test_complaint_30_store_rejects_missing_required_web_fields` | TC-N02 | Validation | 30–39 |
| 19 | `test_complaint_31_db_rejects_missing_not_null_columns` | TC-N03 | Validation | 30–39 |
| 20 | `test_complaint_32_store_rejects_overlength_complainant_name` | TC-N04 | Validation | 30–39 |
| 21 | `test_complaint_33_store_accepts_exact_max_length_complainant_name` | TC-P07 | Validation | 30–39 |
| 22 | `test_complaint_34_store_rejects_overlength_contact` | TC-N05 | Validation | 30–39 |
| 23 | `test_complaint_35_store_rejects_invalid_complaint_type` | TC-N06 | Validation | 30–39 |
| 24 | `test_complaint_36_store_rejects_invalid_urgency` | TC-N07 | Validation | 30–39 |
| 25 | `test_complaint_37_resolve_requires_resolution_notes` | TC-N08 | Validation | 30–39 |
| 26 | `test_complaint_40_foreign_keys_are_configured` | TC-D01 | Integration | 40–49 |
| 27 | `test_complaint_41_update_rejects_nonexistent_assigned_user` | TC-N09 | Integration | 40–49 |
| 28 | `test_complaint_42_cmp_complaint_id_fk_on_delete_set_null` | TC-D02 | Integration | 40–49 |
| 29 | `test_complaint_50_guest_is_redirected_to_login` | TC-AU01 | Permissions | 50–59 |
| 30 | `test_complaint_51_user_without_view_permission_gets_403` | TC-AU02 | Permissions | 50–59 |
| 31 | `test_complaint_52_user_without_create_permission_cannot_store` | TC-AU03 | Permissions | 50–59 |
| 32 | `test_complaint_53_user_without_delete_permission_cannot_destroy` | TC-AU04 | Permissions | 50–59 |
| 33 | `test_complaint_60_index_search_by_complainant_name` | TC-P10 | UI/UX | 60–69 |
| 34 | `test_complaint_61_index_status_filter` | TC-P11 | UI/UX | 60–69 |
| 35 | `test_complaint_62_show_page_displays_detail` | TC-P12 | UI/UX | 60–69 |
| 36 | `test_complaint_63_toggle_status_endpoint_returns_json_ok` | TC-P08 | UI/UX | 60–69 |
| 37 | `test_complaint_70_show_invalid_id_returns_404` | TC-N10 | Edge | 70–79 |
| 38 | `test_complaint_71_description_xss_is_escaped_on_show` | TC-S01 | Edge/Security | 70–79 |
| 39 | `test_complaint_72_soft_delete_restore_force_delete_lifecycle` | TC-P09 | Edge | 70–79 |
| 40 | `test_complaint_73_trash_page_lists_soft_deleted_record` | TC-P13 | Edge | 70–79 |
| 41 | `test_complaint_90_store_ignores_client_supplied_status_mass_assignment` | TC-S02 | Security | 90–99 |
| 42 | `test_complaint_91_cross_tenant_direct_id_is_not_accessible` | TC-T01 | Tenancy | 90–99 |

**Total: 42 methods.**

---

## 5. Manual Test Steps (workflow / state-machine only)

> Simple CRUD/validation cases are fully specified by the Expected column in §3. Manual steps below
> are provided only for the multi-step workflow paths a human tester genuinely needs.

### MTS-1 — Resolve a complaint (Open → Resolved)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login; create a complaint (status Open) | Complaint appears in the "Open" section |
| 2 | Open detail / edit; trigger `PATCH .../resolve` with resolution_notes | Redirect to `fof.menu.compliance?tab=complaints` with success flash |
| 3 | DB check | `SELECT status, resolved_at, resolved_by, resolution_notes FROM fof_complaints WHERE id=?` → status='Resolved', resolved_at not null, notes set |
| 4 | Activity check | `SELECT * FROM sys_activity_logs` has a `complaint_resolved` entry for the complaint |
| 5 | Attempt resolve again | DomainException — HTTP 500/302 (tolerated); status stays 'Resolved' |

### MTS-2 — Escalate to CMP module (Open → Escalated, cross-module)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure `cmp_complaints`, `cmp_complaint_categories`, and `sys_dropdown_table` (severity/priority/status/complainant_type keys) are seeded | Dependencies present |
| 2 | Create complaint (status Open); trigger `PATCH .../escalate` | Redirect to show with "CMP ticket … created" flash |
| 3 | DB check (fof) | `SELECT status, cmp_complaint_id FROM fof_complaints WHERE id=?` → status='Escalated', cmp_complaint_id not null |
| 4 | DB check (cmp) | `SELECT ticket_no, title FROM cmp_complaints WHERE id=?` → new row, title "Escalated from Front Office: {number}" |
| 5 | Activity check | `sys_activity_logs` has `complaint_escalated` with ticket_no in properties |
| 6 | Attempt escalate again | DomainException ("already linked to CMP ticket") — status unchanged |

### MTS-3 — Update bypasses FSM (DEV-FOF-CMP-02)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create complaint (status Open) | Open |
| 2 | Edit and set Status = Closed directly; submit `PUT .../update` | Redirect with success; **status is set to Closed with no FSM guard** |
| 3 | DB check | `status='Closed'` — proves update() does not enforce the resolve/escalate lifecycle. Record as DEV-FOF-CMP-02 |

---

## 6. Known Source Defects (DEV-###)

| ID | Sev | Summary | Proving test | Behaviour asserted |
|----|-----|---------|--------------|--------------------|
| DEV-FOF-CMP-01 | P2 | `complaint_type` app value-set `{Academic,Infrastructure,Staff,Transport,Fee,Other}` (controller `in:` + both Blade selects) diverges from DDL ENUM `{Academic,Facility,Staff_Behavior,Fee,Safety,Transportation,Food,Hygiene,Other}`. Values `Infrastructure/Staff/Transport` are NOT valid DB ENUM members → silent truncation / insert failure. | `test_complaint_04` | Live ENUM contains Facility/Staff_Behavior, not Infrastructure |
| DEV-FOF-CMP-02 | P2 | `update()` has NO state-machine guard — `status` is freely settable to any value (e.g. Open→Closed), bypassing the guarded resolve()/escalate() transitions. | `test_complaint_26` | Closed persists directly via update |
| BUG-FOF-004 | P3 | `complaint_number` format is `CMP-YYYYMMDD-NNN` (generateComplaintNumber), deviating from the spec `FOF-CMP-YYYY-NNNNN`. | `test_complaint_11` | number matches `/^CMP-\d{8}-\d{3,}$/` |
| BUG-FOF-001 | — (remediated) | Audit flagged `toggleStatus(): JsonResponse` unimported → 500. In current source `use Illuminate\Http\JsonResponse;` IS present. | `test_complaint_63` | toggle returns 200 JSON |
| BUG-FOF-003 | — (remediated) | Audit flagged `escalate()` as a status-flip stub. Current source creates a linked `cmp_complaints` row. | `test_complaint_23` | linked cmp row exists (or skip if CMP absent) |
| PERF-FOF-001 | P2 | index()/edit() preload `User::where('is_active',true)->orderBy('name')->get()` unbounded (full active-staff list per render). Documented; no dedicated assertion. | — | note only |
| SEC-FOF-003 | (n/a here) | The D30 `authorize(){return true;}` FormRequest pattern does NOT apply — Complaint uses inline `$request->validate()`, no FormRequest. Only the Gate string protects the action. | — | note only |
