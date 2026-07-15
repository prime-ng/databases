# Lost & Found — Test Case List & Manual Testing Spec (COMBINED)

> Module **FrontOffice (FOF)** · Feature **LostFound** · Primary table `fof_lost_found` · Prefix `fof_`
> Source of truth: `LostFoundController`, `LostFoundRequest`, `LostFound` model, `routes/web.php`,
> `resources/views/fof/lost-found/*`, `FrontOffice_DDL_v1.sql` §15. Read 2026-Jul-15.

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | FrontOffice |
| Feature / Screen | Lost & Found register |
| Primary table | `fof_lost_found` (soft-delete, `is_active`) |
| URL base | `/front-office/lost-found` (route-name group `fof.lost-found.*`) |
| Controller | `Modules\FrontOffice\Http\Controllers\LostFoundController` |
| FormRequest | `Modules\FrontOffice\Http\Requests\LostFoundRequest` (store: 3 rules; PUT/PATCH adds status + claimant rules) |
| Model | `Modules\FrontOffice\Models\LostFound` (`$table=fof_lost_found`, SoftDeletes, casts `found_date`/`claimed_date`=date, `is_active`=boolean; scopes `active`, `unclaimed`) |
| Validation | `LostFoundRequest` + inline `$request->validate()` in `claim()` |
| Migration | `database/migrations/tenant/2026_06_15_154552_create_fof_lost_found_table.php` |
| CRUD Type | Full CRUD + workflow (claim / toggle-status / trash-restore-forceDelete) |
| Soft Delete | Yes (`deleted_at`), trait `SoftDeletes` |
| Pagination | Closed list paginated 20/page; trash 15/page; Unclaimed list un-paginated (`->get()`) |
| Permission scheme | `frontoffice.lost-found.{viewAny,create,update,delete,restore,forceDelete}` (Spatie string gates via `Gate::authorize`) |
| Activity log | Sink `sys_activity_logs` via `Modules\GlobalMaster\Models\ActivityLog`. Events: `claim`→`item_claimed`, `restore`→`Restored`, `forceDelete`→`Deleted`. **store/update/destroy/toggleStatus log nothing (DEV-LF-006).** |
| DB scope | TENANT-SIDE (tenancy init in setUp/end in tearDown) |

### Routes (verbatim from `routes/web.php`, group prefix `front-office`, name `fof.`)
| Verb | Path | Name | Controller method | Gate |
|------|------|------|-------------------|------|
| GET | `/lost-found/trash/view` | `fof.lost-found.trashed` | trashed | viewAny |
| GET | `/lost-found/{id}/restore` | `fof.lost-found.restore` | restore | restore |
| DELETE | `/lost-found/{id}/force-delete` | `fof.lost-found.forceDelete` | forceDelete | forceDelete |
| GET | `/lost-found` | `fof.lost-found.index` | index | viewAny |
| POST | `/lost-found` | `fof.lost-found.store` | store | create |
| GET | `/lost-found/{lostFound}` | `fof.lost-found.show` | show | viewAny |
| GET | `/lost-found/{lostFound}/edit` | `fof.lost-found.edit` | edit | update |
| PUT | `/lost-found/{lostFound}` | `fof.lost-found.update` | update | update |
| DELETE | `/lost-found/{lostFound}` | `fof.lost-found.destroy` | destroy | delete |
| PATCH | `/lost-found/{lostFound}/claim` | `fof.lost-found.claim` | claim | update |
| POST\|PATCH | `/lost-found/{lostFound}/toggle-status` | `fof.lost-found.toggleStatus` | toggleStatus | update |

---

## 2. Business Conditions

### BC-DB (DDL `fof_lost_found` — one testable fact per constraint)
| ID | Fact | Source |
|----|------|--------|
| BC-DB-01 | `item_number` VARCHAR(25) NOT NULL, **UNIQUE** `uq_fof_lf_item_number`, auto `LF-YYYYMMDD-NNN` | DDL-fof_lost_found |
| BC-DB-02 | `item_description` VARCHAR(300) NOT NULL | DDL |
| BC-DB-03 | `category` ENUM(Electronics,Clothing,Stationery,ID_Card,Money,Jewellery,Books,Sports,Other) NOT NULL, no default | DDL |
| BC-DB-04 | `found_date` DATE NOT NULL | DDL |
| BC-DB-05 | `found_location` VARCHAR(200) NOT NULL | DDL |
| BC-DB-06 | `found_by_name` VARCHAR(100) NOT NULL | DDL |
| BC-DB-07 | `found_by_user_id` INT UNSIGNED NULL, FK→`sys_users` ON DELETE SET NULL | DDL |
| BC-DB-08 | `photo_media_id` INT UNSIGNED NULL, FK→`sys_media` ON DELETE SET NULL | DDL |
| BC-DB-09 | `status` ENUM(Unclaimed,Claimed,Disposed,Returned_to_Authority) NOT NULL DEFAULT 'Unclaimed' | DDL |
| BC-DB-10 | `claimant_name` VARCHAR(100) NULL | DDL |
| BC-DB-11 | `claimant_contact` VARCHAR(15) NULL | DDL |
| BC-DB-12 | `claimed_date` DATE NULL | DDL |
| BC-DB-13 | `disposal_notes` TEXT NULL | DDL |
| BC-DB-14 | `is_active` TINYINT(1) NOT NULL DEFAULT 1 (boolean cast) | DDL |
| BC-DB-15 | `created_by`/`updated_by` BIGINT UNSIGNED NOT NULL (no FK, set by controller) | DDL |
| BC-DB-16 | `deleted_at` TIMESTAMP NULL (soft delete) + model `SoftDeletes` (asserted independently) | DDL/Model |

### BC-VAL (FormRequest + inline validation)
| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | store: `item_description` required\|string\|max:150 | LostFoundRequest |
| BC-VAL-02 | store: `found_location` nullable\|string\|max:200 | LostFoundRequest |
| BC-VAL-03 | store/update: `found_date` required\|date\|before_or_equal:today | LostFoundRequest |
| BC-VAL-04 | update(PUT/PATCH): `status` required\|in:Unclaimed,Claimed,Disposed | LostFoundRequest |
| BC-VAL-05 | update: `claimant_name` nullable\|required_if:status,Claimed\|max:100; `claimant_contact` nullable\|required_if:status,Claimed\|max:15 | LostFoundRequest |
| BC-VAL-06 | claim(): `claimant_name` required\|string\|max:150; `claimant_contact` required\|string\|max:20 | Controller::claim |

### BC-AUTH (gate ↔ method)
| ID | Gate | Methods | Source |
|----|------|---------|--------|
| BC-AUTH-01 | `frontoffice.lost-found.viewAny` | index, show, trashed | Controller |
| BC-AUTH-02 | `frontoffice.lost-found.create` | store | Controller |
| BC-AUTH-03 | `frontoffice.lost-found.update` | edit, update, claim, toggleStatus | Controller |
| BC-AUTH-04 | `frontoffice.lost-found.delete` | destroy | Controller |
| BC-AUTH-05 | `frontoffice.lost-found.restore` | restore | Controller |
| BC-AUTH-06 | `frontoffice.lost-found.forceDelete` | forceDelete | Controller |
| BC-AUTH-07 | `Gate::before` grants Super Admin all — negatives need a non-super-admin + cache flush (#31) | — | Rule Card |

### BC-BIZ (business logic / activity log)
| ID | Fact | Source |
|----|------|--------|
| BC-BIZ-01 | `item_number` auto-generated `LF-YYYYMMDD-NNN` (zero-padded 3, `lockForUpdate`) in `store()` | Controller::generateNumber |
| BC-BIZ-02 | `store()` forces `status='Unclaimed'`, `created_by`/`updated_by`=auth id | Controller::store |
| BC-BIZ-03 | `claim()` logs `item_claimed`; `restore()` logs `Restored`; `forceDelete()` logs `Deleted` | Controller |
| BC-BIZ-04 | `update()` sets `claimed_date=now()` on →Claimed; nulls claimant_name/contact/claimed_date on →non-Claimed | Controller::update |
| BC-BIZ-05 | `toggleStatus()` flips `is_active`, returns JSON `{success,message,is_active}` | Controller::toggleStatus |
| BC-BIZ-06 | index splits Unclaimed (get) vs Claimed/Disposed (paginate 20); `search` filters `item_description`; `status` filters `is_active` | Controller::index |

### BC-SM (state machine — `status`)
| ID | State | Trigger | Next | Rule | Source |
|----|-------|---------|------|------|--------|
| BC-SM-01 | Unclaimed | claim() | Claimed | legal; sets claimed_date + claimant | Controller::claim |
| BC-SM-02 | Claimed | claim() | — | illegal → abort 422 "Item already claimed." | Controller::claim |
| BC-SM-03 | Disposed | claim() | — | illegal → abort 422 "Item has been disposed." | Controller::claim |
| BC-SM-04 | Unclaimed/Claimed/Disposed | update() | any of the 3 | allowed with **no transition guard** (DEV-LF-007) | Controller::update |
| BC-SM-05 | any | update(status=Returned_to_Authority) | — | rejected by `in:` rule; 4th enum unreachable (DEV-LF-005) | LostFoundRequest |

### BC-REF (FK / onDelete)
| ID | FK | Referenced | onDelete | Source |
|----|-----|-----------|----------|--------|
| BC-REF-01 | `found_by_user_id` | `sys_users.id` | SET NULL | DDL |
| BC-REF-02 | `photo_media_id` | `sys_media.id` | SET NULL | DDL |

### BC-INT / BC-EDG
| ID | Fact | Source |
|----|------|--------|
| BC-INT-01 | `sys_media` may be absent in test DB — guard media/force-delete ops (#11) | Rule Card |
| BC-EDG-01 | Soft-delete → trash → restore roundtrip; force-delete permanent | Controller/Model |
| BC-EDG-02 | Free-text `item_description` XSS-escaped by Blade `{{ }}` | Blade index |

### BC-AUTO
| ID | Fact | Source |
|----|------|--------|
| BC-AUTO-01 | No model observers / cross-module auto-updates for LostFound (BaseModel is a thin `Model`) | Model |

---

## 3. Test Case List

### Positive (TC-P)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-P01 | Schema | BC-DB-01..16 | DDL | Full DDL↔app alignment, UNIQUE index, soft-delete independent | matrix passes | `test_lost_found_01` | ✅ |
| TC-P02 | Route | BC-AUTH | routes | 11 routes registered | all present | `test_lost_found_02` | ✅ |
| TC-P03 | Scope | BC-BIZ | Model | `active`/`unclaimed` scopes chain | ≥0 count | `test_lost_found_03` | ✅ |
| TC-P04 | Default | BC-DB-09/14 | DDL | status→Unclaimed, is_active→1 on omit | defaults applied | `test_lost_found_10` | ✅ |
| TC-P05 | Auto# | BC-BIZ-01 | Controller | item_number matches `LF-YYYYMMDD-NNN` | regex match | `test_lost_found_11` | ✅ |
| TC-P06 | Activity | BC-BIZ-03 | Controller | claim logs `item_claimed` | logged | `test_lost_found_12` | ✅ |
| TC-P07 | Activity | BC-BIZ-03 | Controller | restore→Restored, forceDelete→Deleted | logged | `test_lost_found_13` | ✅ |
| TC-P08 | SM | BC-SM-01 | Controller | claim Unclaimed→Claimed | status Claimed, date set | `test_lost_found_20` | ✅ |
| TC-P09 | SM | BC-BIZ-04 | Controller | update→Claimed sets claimed_date | date set | `test_lost_found_23` | ✅ |
| TC-P10 | Biz | BC-BIZ-05 | Controller | toggle-status flips is_active (JSON) | flipped | `test_lost_found_26` | ✅ |
| TC-P11 | Length | BC-DB-02 | DDL | item_description exactly 300 accepted | saved | `test_lost_found_32` | ✅ |
| TC-P12 | Nullable | BC-DB-10..13 | DDL | claimant/claimed_date/disposal/user/media null accepted | saved | `test_lost_found_34` | ✅ |
| TC-P13 | Nullable | BC-DB-08 | DDL | photo_media_id null accepted | saved | `test_lost_found_43` | ✅ |
| TC-P14 | Perm+ | BC-AUTH-01 | Controller | admin with gate reaches index | 200/500 | `test_lost_found_55` | ✅ |
| TC-P15 | Render | BC-BIZ-06 | Blade | index renders with item_number | visible | `test_lost_found_60` | ✅ |
| TC-P16 | Render | Blade | Blade | edit renders status select + fields | present | `test_lost_found_61` | ✅ |
| TC-P17 | Search | BC-BIZ-06 | Controller | index search filters by description | match seen | `test_lost_found_62` | ✅ |
| TC-P18 | Edge | BC-EDG-01 | Model | soft-delete→restore roundtrip | restored | `test_lost_found_70` | ✅ |
| TC-P19 | Edge | BC-EDG-01 | Model | force-delete removes record | gone | `test_lost_found_71` | ✅ |

### Negative (TC-N)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-N01 | Required | BC-DB-01..06 | DDL | missing item_number/description/category/found_date/found_location/found_by_name | DB rejects each | `test_lost_found_30` | ✅ |
| TC-N02 | Length | BC-DB-02 | DDL | item_description > 300 | rejected/truncated | `test_lost_found_31` | ✅ |
| TC-N03 | Length | BC-DB-05 | DDL | found_location > 200 | rejected/truncated | `test_lost_found_33` | ✅ |
| TC-N04 | Val | BC-VAL-03 | Request | update future found_date | rejected | `test_lost_found_38` | ✅ |
| TC-N05 | Unique | BC-DB-01 | DDL | duplicate item_number | UNIQUE violation | `test_lost_found_40` | ✅ |
| TC-N06 | FK | BC-REF-01 | DDL | invalid found_by_user_id | FK violation (tolerant) | `test_lost_found_42` | ✅ |
| TC-N07 | SM | BC-SM-02 | Controller | claim already-Claimed | 422 rejected | `test_lost_found_21` | ✅ |
| TC-N08 | SM | BC-SM-03 | Controller | claim Disposed | 422 rejected | `test_lost_found_22` | ✅ |
| TC-N09 | SM | BC-SM-05 | Request | update status=Returned_to_Authority | rejected | `test_lost_found_25` | ✅ |
| TC-N10 | Auth | BC-AUTH | routes | guest → login redirect | 302 login | `test_lost_found_50` | ✅ |
| TC-N11 | Auth | BC-AUTH-01 | Controller | index forbidden w/o viewAny | 403/302 | `test_lost_found_51` | ✅ |
| TC-N12 | Auth | BC-AUTH-01 | Controller | trashed forbidden w/o viewAny | 403/302 | `test_lost_found_52` | ✅ |
| TC-N13 | Auth | BC-AUTH-03 | Controller | edit forbidden w/o update | 403/302 | `test_lost_found_53` | ✅ |
| TC-N14 | Auth | BC-AUTH-04 | Controller | destroy forbidden w/o delete, row not deleted | 403/302 + intact | `test_lost_found_54` | ✅ |
| TC-N15 | Edge | BC-EDG | Controller | restore invalid id | 404 | `test_lost_found_72` | ✅ |
| TC-N16 | Sec | BC-EDG-02 | Blade | XSS in item_description escaped | no script node | `test_lost_found_73` | ✅ |
| TC-N17 | Sec | — | Model | mass-assignment guard on PK | id unchanged | `test_lost_found_91` | ✅ |
| TC-N18 | Sec | BC-INT | Controller | unknown direct id (IDOR) | 404 | `test_lost_found_90` | ✅ |

### Dependency (TC-D)
| TC ID | Sub | BC | Description | Expected | Method | Status |
|-------|-----|----|-------------|----------|--------|--------|
| TC-D01 | B | BC-EDG-01 | soft/force-delete data preservation | roundtrip | `test_lost_found_70/71` | ✅ |
| TC-D02 | D | BC-REF-01/02 | FK SET NULL columns nullable | null accepted / FK enforced | `test_lost_found_42/43` | ✅ |
| TC-D03 | E | BC-INT-01 | sys_media guarded (force-delete try/catch) | green in partial env | helper `forceDeleteLostFound` | ✅ |
| TC-D04 | F | BC-SM | full lifecycle create→claim/update→toggle→delete→restore→forceDelete | each step asserted | `test_lost_found_20..26,70,71` | ✅ |

### Known-defect proving cases (TC-DEV)
| TC ID | DEV | Description | Method | Status |
|-------|-----|-------------|--------|--------|
| TC-DEV01 | DEV-LF-001 | store() cannot persist (category + found_by_name unset; found_location nullable) | `test_lost_found_41` | ✅ |
| TC-DEV02 | DEV-LF-002 | found_location DDL NOT NULL vs request nullable | `test_lost_found_35` | ✅ |
| TC-DEV03 | DEV-LF-003 | item_description max:150 vs col 300 | `test_lost_found_36` | ✅ |
| TC-DEV04 | DEV-LF-004 | claim() max:150/20 vs col 100/15 | `test_lost_found_37` | ✅ |
| TC-DEV05 | DEV-LF-005 | Returned_to_Authority unreachable via update | `test_lost_found_25` | ✅ |
| TC-DEV06 | DEV-LF-006 | store/update/destroy/toggleStatus emit no activity log | `test_lost_found_14` | ✅ |
| TC-DEV07 | DEV-LF-007 | update() has no FSM guard (Claimed→Unclaimed nulls claimant) | `test_lost_found_24` | ✅ |
| TC-DEV08 | DEV-LF-008 | disposal_notes never captured | `test_lost_found_74` | ✅ |
| TC-DEV09 | SEC-FOF-003 | LostFoundRequest::authorize() returns true (D30) | `test_lost_found_92` | ✅ |

---

## 4. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_lost_found_01_schema_model_and_request_configuration_are_correct | TC-P01 | Schema | 01-09 |
| 2 | test_lost_found_02_web_routes_are_registered | TC-P02 | Route | 01-09 |
| 3 | test_lost_found_03_model_scopes_resolve | TC-P03 | Scope | 01-09 |
| 4 | test_lost_found_10_status_and_is_active_defaults_apply_on_create | TC-P04 | Biz | 10-19 |
| 5 | test_lost_found_11_item_number_uniqueness_and_format_contract | TC-P05 | Biz | 10-19 |
| 6 | test_lost_found_12_activity_log_uses_item_claimed_string_on_claim | TC-P06 | Biz | 10-19 |
| 7 | test_lost_found_13_activity_log_restored_and_deleted_events | TC-P07 | Biz | 10-19 |
| 8 | test_lost_found_14_store_update_destroy_emit_no_activity_log_DEV | TC-DEV06 | Biz/DEV | 10-19 |
| 9 | test_lost_found_20_claim_transitions_unclaimed_to_claimed | TC-P08 | SM | 20-29 |
| 10 | test_lost_found_21_claim_rejected_when_already_claimed | TC-N07 | SM | 20-29 |
| 11 | test_lost_found_22_claim_rejected_when_disposed | TC-N08 | SM | 20-29 |
| 12 | test_lost_found_23_update_to_claimed_sets_claimed_date | TC-P09 | SM | 20-29 |
| 13 | test_lost_found_24_update_away_from_claimed_clears_claimant_fields_DEV | TC-DEV07 | SM/DEV | 20-29 |
| 14 | test_lost_found_25_update_cannot_set_returned_to_authority_DEV | TC-N09/TC-DEV05 | SM/DEV | 20-29 |
| 15 | test_lost_found_26_toggle_status_endpoint_flips_is_active | TC-P10 | Biz | 20-29 |
| 16 | test_lost_found_30_required_columns_reject_missing_values | TC-N01 | Validation | 30-39 |
| 17 | test_lost_found_31_item_description_over_length_beyond_300 | TC-N02 | Validation | 30-39 |
| 18 | test_lost_found_32_item_description_exactly_300_chars_is_accepted | TC-P11 | Validation | 30-39 |
| 19 | test_lost_found_33_found_location_over_length_beyond_200 | TC-N03 | Validation | 30-39 |
| 20 | test_lost_found_34_nullable_fields_accept_null | TC-P12 | Validation | 30-39 |
| 21 | test_lost_found_35_found_location_ddl_notnull_vs_request_nullable_DEV | TC-DEV02 | DEV | 30-39 |
| 22 | test_lost_found_36_item_description_max_divergence_DEV | TC-DEV03 | DEV | 30-39 |
| 23 | test_lost_found_37_claim_validation_max_exceeds_columns_DEV | TC-DEV04 | DEV | 30-39 |
| 24 | test_lost_found_38_update_future_found_date_rejected_via_form_request | TC-N04 | Validation | 30-39 |
| 25 | test_lost_found_40_duplicate_item_number_rejected_by_db | TC-N05 | Integrity | 40-49 |
| 26 | test_lost_found_41_store_endpoint_fails_missing_required_columns_DEV | TC-DEV01 | DEV | 40-49 |
| 27 | test_lost_found_42_found_by_user_id_invalid_fk_rejected | TC-N06/TC-D02 | FK | 40-49 |
| 28 | test_lost_found_43_photo_media_id_accepts_null | TC-P13/TC-D02 | FK | 40-49 |
| 29 | test_lost_found_50_guest_is_redirected_to_login | TC-N10 | Auth | 50-59 |
| 30 | test_lost_found_51_index_viewany_forbidden_without_permission | TC-N11 | Auth | 50-59 |
| 31 | test_lost_found_52_trashed_viewany_forbidden_without_permission | TC-N12 | Auth | 50-59 |
| 32 | test_lost_found_53_edit_update_forbidden_without_permission | TC-N13 | Auth | 50-59 |
| 33 | test_lost_found_54_destroy_delete_forbidden_without_permission | TC-N14 | Auth | 50-59 |
| 34 | test_lost_found_55_admin_with_permission_can_open_index | TC-P14 | Auth | 50-59 |
| 35 | test_lost_found_60_index_page_renders_with_item | TC-P15 | UI | 60-69 |
| 36 | test_lost_found_61_edit_page_renders_with_status_select | TC-P16 | UI | 60-69 |
| 37 | test_lost_found_62_index_search_filters_by_description | TC-P17 | UI | 60-69 |
| 38 | test_lost_found_70_soft_delete_then_restore_roundtrip | TC-P18/TC-D01 | Edge | 70-79 |
| 39 | test_lost_found_71_force_delete_removes_record | TC-P19/TC-D01 | Edge | 70-79 |
| 40 | test_lost_found_72_restore_invalid_id_returns_404 | TC-N15 | Edge | 70-79 |
| 41 | test_lost_found_73_xss_in_item_description_is_escaped_on_render | TC-N16 | Security | 70-79 |
| 42 | test_lost_found_74_disposal_notes_never_captured_DEV | TC-DEV08 | DEV | 70-79 |
| 43 | test_lost_found_90_unknown_direct_id_is_not_exposed | TC-N18 | Security | 90-99 |
| 44 | test_lost_found_91_mass_assignment_guard_on_primary_key | TC-N17 | Security | 90-99 |
| 45 | test_lost_found_92_form_request_authorize_returns_true_SEC_FOF_003 | TC-DEV09 | Security/DEV | 90-99 |

---

## 5. Manual Test Steps (workflow / defect paths only)

### MT-1 — Claim an unclaimed item (BC-SM-01)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed an Unclaimed item (model create with category+found_by_name+found_location) | row `status=Unclaimed` |
| 2 | Open `/front-office/lost-found`, click **Claim** on the item | Claim modal opens |
| 3 | Enter Claimant Name + Contact, submit (PATCH `.../claim`) | redirect back, toast "Item marked as claimed." |
| 4 | DB check | `SELECT status,claimed_date,claimant_name FROM fof_lost_found WHERE id=? ` → `Claimed`, today, name set |
| 5 | Activity check | `SELECT event FROM sys_activity_logs WHERE subject_id=?` → `item_claimed` present |

### MT-2 — Illegal claim transitions (BC-SM-02/03)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed item `status=Claimed` | — |
| 2 | PATCH `.../claim` again | HTTP 422 "Item already claimed."; claimant unchanged |
| 3 | Seed item `status=Disposed`, PATCH claim | HTTP 422 "Item has been disposed."; status stays Disposed |

### MT-3 — Broken create path (DEV-LF-001)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open Log Found Item modal, fill Item Name + Found Date + Location, submit (POST `/lost-found`) | Server error (500) — `category`/`found_by_name` are NOT NULL with no default and are never set |
| 2 | DB check | `SELECT COUNT(*) FROM fof_lost_found WHERE item_description=?` → 0 (no row created) |
| 3 | Record | DEV-LF-001 — create is non-functional until controller supplies category + found_by_name and found_location is required |

### MT-4 — Toggle record status (BC-BIZ-05)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST/PATCH `.../toggle-status` (AJAX, X-Requested-With) | JSON `{success:true,is_active:false}` |
| 2 | DB check | `is_active` flipped; **no** activity-log row (DEV-LF-006) |

---

## 6. Known Source Defects (DEV-###)
See §3 "Known-defect proving cases" — DEV-LF-001..008 + SEC-FOF-003. Each has a proving test asserting **current** behaviour and a tripwire so the test flips when the defect is fixed. Full analysis in `fof_LostFoundGAPANALYSIS_Require.md`.
