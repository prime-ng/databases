# FrontOffice :: NoticesEvents — Test Case List & Manual Testing (Combined)

> **COMPOUND feature.** This screen bundles two sub-entities that share the FrontOffice
> Communication menu (`fof.menu.communication`), each with its own controller, model, table,
> routes and permission slug. Both are covered by the single suite `fof_NoticesEvents_TestCas.php`.

---

## 1. Feature Information

| Field | Notice Board | School Events |
|-------|--------------|---------------|
| Module | FrontOffice (FOF) | FrontOffice (FOF) |
| Sub-feature | NoticeBoard | SchoolEvent |
| Primary table | `fof_notices` | `fof_school_events` |
| Controller | `Modules\FrontOffice\Http\Controllers\NoticeBoardController` | `...\SchoolEventController` |
| Model | `Modules\FrontOffice\Models\Notice` (extends `Model`, `InteractsWithMedia`) | `Modules\FrontOffice\Models\SchoolEvent` (extends `App\Models\BaseModel`) |
| Index URL | `/front-office/notices` | `/front-office/school-events` |
| Route-name group | `fof.notices.*` | `fof.school-events.*` |
| Validation | **Inline `$request->validate()`** (no FormRequest class) | **Inline `$request->validate()`** (no FormRequest class) |
| Migrations | consolidated tenant set (module `database/migrations` empty) | same |
| CRUD Type | Full CRUD + toggle-status + soft-delete/restore/force-delete | same |
| Soft Delete | Yes (`SoftDeletes`, `deleted_at`) | Yes |
| Pagination | index `paginate(25)`; trash `paginate(15)` | past events `paginate(20)`; trash `paginate(15)` |
| Store/Update redirect | `route('fof.menu.communication').'?tab=notices'` | `...'?tab=school-events'` |
| Permission slug | `frontoffice.notice.{view,create,update,delete,restore,forceDelete}` | `frontoffice.school-event.{...}` |
| Activity log sink | `sys_activity_logs` (via `activityLog()` → `GlobalMaster\ActivityLog`) | same |
| Activity events (verbatim) | **restore→`Restored`, forceDelete→`Deleted` ONLY** (store/update/destroy/toggle log NOTHING) | **destroy→`Deleted`, restore→`Restored`, forceDelete→`Deleted`** (store/update/toggle log NOTHING) |
| Media | `notice_attachment` single-file collection (`sys_media`) | none |

**DB scope:** TENANT-SIDE (all `fof_*` tables live in `tenant_db`). Tests initialize tenant context in `setUp`, end it in `tearDown`.

---

## 2. Business Conditions

### BC-DB — DDL constraints (fof_notices)
| ID | Fact | Source |
|----|------|--------|
| BC-DB-N01 | `title` VARCHAR(200) NOT NULL — required + max-length 200 | DDL-fof_notices |
| BC-DB-N02 | `content` LONGTEXT NOT NULL — required, no max | DDL-fof_notices |
| BC-DB-N03 | `category` ENUM('Academic','Administrative','Sports','Cultural','Holiday','Emergency','Other') NOT NULL | DDL-fof_notices |
| BC-DB-N04 | `audience` ENUM('All','Students','Staff','Parents') NOT NULL DEFAULT 'All' | DDL-fof_notices |
| BC-DB-N05 | `display_from` DATE NOT NULL — required | DDL-fof_notices |
| BC-DB-N06 | `display_until` DATE NULL — omittable | DDL-fof_notices |
| BC-DB-N07 | `is_pinned`/`is_emergency` TINYINT(1) DEFAULT 0 | DDL-fof_notices |
| BC-DB-N08 | `status` ENUM('Active','Archived') DEFAULT 'Active' — server-managed (G48) | DDL-fof_notices |
| BC-DB-N09 | `is_active` TINYINT(1) DEFAULT 1 | DDL-fof_notices |
| BC-DB-N10 | `attachment_media_id` INT-U NULL, FK→`sys_media` ON DELETE SET NULL | DDL-fof_notices |
| BC-DB-N11 | `created_by`/`updated_by` BIGINT-U NOT NULL, no FK — controller-set (G48) | DDL-fof_notices |
| BC-DB-N12 | NO UNIQUE key → duplicates allowed (G43 documented absence) | DDL-fof_notices |
| BC-DB-N13 | `deleted_at` present + `SoftDeletes` trait present (assert independently) | DDL/Model |

### BC-DB — DDL constraints (fof_school_events)
| ID | Fact | Source |
|----|------|--------|
| BC-DB-E01 | `event_name` VARCHAR(200) NOT NULL — required + max 200 | DDL-fof_school_events |
| BC-DB-E02 | `event_type` ENUM('Academic','Sports','Cultural','PTM','Holiday','Exam','Admission','Other') NOT NULL | DDL |
| BC-DB-E03 | `start_date` DATE NOT NULL — required | DDL |
| BC-DB-E04 | `end_date` DATE **NOT NULL** (>= start_date) | DDL |
| BC-DB-E05 | `description` TEXT NULL — omittable | DDL |
| BC-DB-E06 | `venue` VARCHAR(200) NULL — omittable, max 200 | DDL |
| BC-DB-E07 | `audience` ENUM('All','Students','Staff','Parents') DEFAULT 'All' | DDL |
| BC-DB-E08 | `is_public`/`notification_sent` TINYINT(1) DEFAULT 0 | DDL |
| BC-DB-E09 | `is_active` TINYINT(1) DEFAULT 1 | DDL |
| BC-DB-E10 | `created_by`/`updated_by` NOT NULL, no FK — controller-set (G48) | DDL |
| BC-DB-E11 | NO UNIQUE key → duplicates allowed (G43) | DDL |
| BC-DB-E12 | `deleted_at` + `SoftDeletes` (independent) | DDL/Model |

### BC-VAL — Inline validation rules
| ID | Fact | Source |
|----|------|--------|
| BC-VAL-N01 | notice.category `in:Academic,Administrative,Event,Holiday,Emergency,General` (app) | NoticeBoardController |
| BC-VAL-N02 | notice.audience `in:All,Students,Parents,Staff,Management` (app) | NoticeBoardController |
| BC-VAL-N03 | notice.display_until `nullable\|date\|after_or_equal:display_from` | NoticeBoardController |
| BC-VAL-N04 | notice.attachment `nullable\|file\|max:10240` | NoticeBoardController |
| BC-VAL-E01 | event.event_type `in:Academic,Sports,Cultural,PTM,Holiday,Function,Other` (app) | SchoolEventController |
| BC-VAL-E02 | event.audience `in:All,Students,Parents,Staff,Management` (app) | SchoolEventController |
| BC-VAL-E03 | event.end_date `nullable\|date\|after_or_equal:start_date` (app) | SchoolEventController |
| BC-VAL-E04 | event.venue `nullable\|string\|max:150` (app) | SchoolEventController |

### BC-AUTH — Authorization
| ID | Fact | Source |
|----|------|--------|
| BC-AUTH-01 | Every controller method calls `Gate::authorize('frontoffice.<entity>.<action>')` string gate | Controllers |
| BC-AUTH-02 | Guest → redirect `/login` (auth+verified middleware) | routes/web.php |
| BC-AUTH-03 | Non-super-admin lacking the ability → 403 (Super Admin bypasses via `Gate::before` — #31) | FactPack §4 |

### BC-SM — Lifecycle
| ID | State→Trigger→Next | Entity | Source |
|----|--------------------|--------|--------|
| BC-SM-01 | active → toggle-status → inactive (`is_active` flip, JSON) | both | Controller.toggleStatus |
| BC-SM-02 | active → destroy → trashed (`deleted_at` set) | both | Controller.destroy |
| BC-SM-03 | trashed → restore → active | both | Controller.restore |
| BC-SM-04 | trashed → forceDelete → gone | both | Controller.forceDelete |

### BC-BIZ — Business rules
| ID | Fact | Source |
|----|------|--------|
| BC-BIZ-01 | BR-FOF-014: emergency notice visible regardless of display window; expired non-emergency hidden (`scopeVisible`) | Notice model |
| BC-BIZ-02 | Index orders by `display_from desc`, then `is_pinned desc` | NoticeBoardController.index |
| BC-BIZ-03 | Events index splits `upcoming()` (start_date >= today) vs past | SchoolEventController.index |
| BC-BIZ-04 | `scopeActive()` excludes `is_active=0` | both models |

### BC-REF / BC-INT — Dependencies
| ID | Fact | Source |
|----|------|--------|
| BC-REF-01 | notice.attachment_media_id → `sys_media` (SET NULL); guarded if `sys_media` absent | DDL |

### BC-AUTO — Programmatically-managed (G48, never form inputs)
| ID | Fact | Source |
|----|------|--------|
| BC-AUTO-01 | notice/event `created_by`/`updated_by` = `auth()->id()` | Controllers.store/update |
| BC-AUTO-02 | notice `status` server default 'Active' (never posted) | DDL/Controller |

### BC-EDG — Edge / boundaries
| ID | Fact | Source |
|----|------|--------|
| BC-EDG-01 | notice.content LONGTEXT stores long HTML | DDL |
| BC-EDG-02 | event.description TEXT stores long content | DDL |
| BC-EDG-03 | invalid show id → 404 (RMB `findOrFail`) | routes |

---

## 3. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|-----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-N01..13 | DDL | Notice schema/model/cast/soft-delete alignment | matches LIVE schema | `_01` | Automated |
| TC-P02 | BC-DB-E01..12 | DDL | Event schema/model/cast/soft-delete alignment | matches LIVE schema | `_02` | Automated |
| TC-P03 | BC-DB-N06 | DDL | Notice nullable cols omitted → persists | row saved, NULLs | `_05` | Automated |
| TC-P04 | BC-DB-E05/E06 | DDL | Event nullable cols omitted → persists | row saved, NULLs | `_06` | Automated |
| TC-P05 | BC-DB-N04/N07/N08/N09,E07..E09 | DDL | Defaults applied on create | All/0/Active/1 | `_07` | Automated |
| TC-P06 | BC-DB | Model | Casts return typed bool/date | typed values | `_08` | Automated |
| TC-P07 | BC-DB-N12/E11 | DDL | No UNIQUE → duplicate rows allowed | both persist | `_09` | Automated |
| TC-P08 | BC-BIZ-04 | Model | Notice/Event active scope excludes inactive | filtered | `_10`,`_12` | Automated |
| TC-P09 | BC-BIZ-01 | Model | Emergency bypasses display window (BR-FOF-014) | visible | `_11` | Automated |
| TC-P10 | BC-BIZ-03 | Model | Event upcoming scope filters by start_date | future in / past out | `_13` | Automated |
| TC-P11 | BC-AUTO-02 | DDL | Notice status default Active | 'Active' | `_14` | Automated |
| TC-P12 | BC-DB-N03 | DDL | Notice category accepts DB-valid values | stored | `_34` | Automated |
| TC-P13 | BC-DB-E02 | DDL | Event type accepts DB-valid (incl Exam/Admission) | stored | `_37` | Automated |
| TC-P14 | BC-AUTO-01 | Controller | created_by/updated_by set on store (notice/event) | = acting user | `_42`,`_43` | Automated |
| TC-P15 | BC-SM-01 | Controller | Toggle-status flips is_active (notice/event) | flipped + JSON | `_20`,`_21` | Automated |
| TC-P16 | BC-SM-02/03/04 | Controller | Soft-delete / restore / force-delete lifecycle | as expected | `_22`–`_27` | Automated |
| TC-P17 | BC-DB-N01/E01 | DDL | Max-length (200) title/event_name accepted | stored intact | `_30`,`_31` | Automated |
| TC-P18 | UI | Blade | Index lists / search / audience filter / show / edit-update | rendered | `_60`–`_67` | Automated |
| TC-P19 | BC-BIZ-02 | Controller | Pinned ordering available | pinned surfaces | `_68` | Automated |
| TC-P20 | BC-EDG-01/02 | DDL | Long LONGTEXT/TEXT stored | intact | `_74`,`_75` | Automated |
| TC-P21 | BC-EDG-03 | routes | Trash listings render (notice/event) | shows deleted | `_70`,`_71` | Automated |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|-----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-DB-N01/N02/N03/N05 | DDL | Missing required notice col rejected | DB error | `_03` | Automated |
| TC-N02 | BC-DB-E01/E02/E03 | DDL | Missing required event col rejected | DB error | `_04` | Automated |
| TC-N03 | BC-DB-N01/E01/E06 | DDL/G45 | Over-length title/event_name/venue rejected/truncated | ≤ max | `_30`–`_32` | Automated |
| TC-N04 | DEV-FOF-NE-001 | Controller↔DDL | Notice category app-only 'Event'/'General' not persisted canonically | rejected/coerced | `_33` | Automated |
| TC-N05 | DEV-FOF-NE-002 | Controller↔DDL | audience 'Management' not in DB ENUM (notice+event) | rejected/coerced | `_35` | Automated |
| TC-N06 | DEV-FOF-NE-003 | Controller↔DDL | event_type 'Function' not in DB ENUM | rejected/coerced | `_36` | Automated |
| TC-N07 | DEV-FOF-NE-004 | DDL↔Controller | event end_date omitted (app nullable, DB NOT NULL) | DB error | `_38` | Automated |
| TC-N08 | BC-VAL | Controller | Notice store missing required → no 2xx | 302/422/500 | `_39` | Automated |
| TC-N09 | BC-REF-01 | DDL | notice bad attachment_media_id FK rejected | FK error (guarded) | `_40` | Automated |
| TC-N10 | BC-EDG-03 | routes | Show 404 for missing id (notice/event) | 404 | `_72`,`_73` | Automated |
| TC-N11 | BC-AUTH-02 | routes | Guest redirected to /login (notice/event) | /login | `_50`,`_51` | Automated |
| TC-N12 | BC-AUTH-03 | Gate | Limited user 403 on index/store (notice/event) | 403/419 | `_52`–`_55` | Automated |
| TC-N13 | TC-S | Security | Stored XSS in title/event_name escaped | no raw `<script>` | `_90`,`_91` | Automated |

### Dependency / Integration (TC-D)
| TC ID | BC | Source | Description | Expected | Method |
|-------|-----|--------|-------------|----------|--------|
| TC-D01 | BC-REF-01 | DDL | attachment FK declared SET NULL | schema confirms | `_41` |
| TC-D02 | BC-REF-01 | DDL | invalid FK id rejected (guard if sys_media absent) | FK error/skip | `_40` |

### DEV proving (source defects)
| TC ID | DEV | Description | Method |
|-------|-----|-------------|--------|
| TC-DEV01 | DEV-FOF-NE-005 | Notice store/update/destroy log NOTHING (only restore/forceDelete) | `_92` |
| TC-DEV02 | DEV-FOF-NE-005 | Event store/update log NOTHING (destroy/restore/forceDelete do) | `_93` |
| TC-DEV03 | DEV-FOF-NE-001/002/003 | ENUM divergences proven | `_33`,`_35`,`_36` |
| TC-DEV04 | DEV-FOF-NE-004 | end_date NOT NULL vs nullable | `_38` |
| TC-DEV05 | DEV-FOF-NE-006 | venue max:150 stricter than column(200) — noted | `_32` |

---

## 4. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 01 | `_01_notice_schema_and_model_alignment` | TC-P01 | Schema | 01-09 |
| 02 | `_02_event_schema_and_model_alignment` | TC-P02 | Schema | 01-09 |
| 03 | `_03_notice_required_columns_reject_missing` | TC-N01 | Schema/G44 | 01-09 |
| 04 | `_04_event_required_columns_reject_missing` | TC-N02 | Schema/G44 | 01-09 |
| 05 | `_05_notice_nullable_columns_accept_omitted` | TC-P03 | Schema/G44 | 01-09 |
| 06 | `_06_event_nullable_columns_accept_omitted` | TC-P04 | Schema/G44 | 01-09 |
| 07 | `_07_column_defaults_applied_on_create` | TC-P05 | Schema | 01-09 |
| 08 | `_08_casts_return_typed_values` | TC-P06 | Schema | 01-09 |
| 09 | `_09_no_unique_constraint_allows_duplicates` | TC-P07 | Schema/G43 | 01-09 |
| 10 | `_10_notice_active_scope_excludes_inactive` | TC-P08 | BC-BIZ | 10-19 |
| 11 | `_11_notice_visible_scope_emergency_bypasses_dates` | TC-P09 | BC-BIZ | 10-19 |
| 12 | `_12_event_active_scope_excludes_inactive` | TC-P08 | BC-BIZ | 10-19 |
| 13 | `_13_event_upcoming_scope_filters_by_start_date` | TC-P10 | BC-BIZ | 10-19 |
| 14 | `_14_notice_status_is_server_default_active` | TC-P11 | BC-AUTO | 10-19 |
| 20 | `_20_notice_toggle_status_flips_is_active` | TC-P15 | BC-SM | 20-29 |
| 21 | `_21_event_toggle_status_flips_is_active` | TC-P15 | BC-SM | 20-29 |
| 22 | `_22_notice_soft_delete_moves_to_trash` | TC-P16 | BC-SM | 20-29 |
| 23 | `_23_event_soft_delete_and_activity_logged` | TC-P16 | BC-SM | 20-29 |
| 24 | `_24_notice_restore_from_trash` | TC-P16 | BC-SM | 20-29 |
| 25 | `_25_event_restore_from_trash` | TC-P16 | BC-SM | 20-29 |
| 26 | `_26_notice_force_delete_is_permanent` | TC-P16 | BC-SM | 20-29 |
| 27 | `_27_event_force_delete_is_permanent` | TC-P16 | BC-SM | 20-29 |
| 30 | `_30_notice_title_length_boundary` | TC-P17/TC-N03 | BC-VAL/G45 | 30-39 |
| 31 | `_31_event_name_length_boundary` | TC-P17/TC-N03 | BC-VAL/G45 | 30-39 |
| 32 | `_32_event_venue_length_boundary` | TC-N03/DEV | BC-VAL/G45 | 30-39 |
| 33 | `_33_notice_category_app_values_not_in_db_enum` | TC-N04 | DEV | 30-39 |
| 34 | `_34_notice_category_db_valid_values_accepted` | TC-P12 | BC-VAL | 30-39 |
| 35 | `_35_audience_management_not_in_db_enum` | TC-N05 | DEV | 30-39 |
| 36 | `_36_event_type_function_not_in_db_enum` | TC-N06 | DEV | 30-39 |
| 37 | `_37_event_type_db_valid_values_accepted` | TC-P13 | BC-VAL | 30-39 |
| 38 | `_38_event_end_date_notnull_vs_nullable_divergence` | TC-N07 | DEV | 30-39 |
| 39 | `_39_notice_store_rejects_missing_required` | TC-N08 | BC-VAL | 30-39 |
| 40 | `_40_notice_attachment_fk_enforced` | TC-N09/TC-D02 | BC-REF | 40-49 |
| 41 | `_41_notice_attachment_fk_is_set_null` | TC-D01 | BC-REF | 40-49 |
| 42 | `_42_notice_created_by_set_by_controller` | TC-P14 | BC-AUTO | 40-49 |
| 43 | `_43_event_created_by_set_by_controller` | TC-P14 | BC-AUTO | 40-49 |
| 50 | `_50_guest_redirected_from_notices` | TC-N11 | BC-AUTH | 50-59 |
| 51 | `_51_guest_redirected_from_events` | TC-N11 | BC-AUTH | 50-59 |
| 52 | `_52_notice_index_requires_view_permission` | TC-N12 | BC-AUTH | 50-59 |
| 53 | `_53_notice_store_requires_create_permission` | TC-N12 | BC-AUTH | 50-59 |
| 54 | `_54_event_index_requires_view_permission` | TC-N12 | BC-AUTH | 50-59 |
| 55 | `_55_event_store_requires_create_permission` | TC-N12 | BC-AUTH | 50-59 |
| 60 | `_60_notice_index_lists_records` | TC-P18 | UI | 60-69 |
| 61 | `_61_notice_search_filters_results` | TC-P18 | UI | 60-69 |
| 62 | `_62_notice_audience_filter_applies` | TC-P18 | UI | 60-69 |
| 63 | `_63_notice_show_displays_details` | TC-P18 | UI | 60-69 |
| 64 | `_64_notice_edit_and_update` | TC-P18 | UI | 60-69 |
| 65 | `_65_event_index_lists_records` | TC-P18 | UI | 60-69 |
| 66 | `_66_event_show_displays_details` | TC-P18 | UI | 60-69 |
| 67 | `_67_event_edit_and_update` | TC-P18 | UI | 60-69 |
| 68 | `_68_notice_pinned_ordering_available` | TC-P19 | UI | 60-69 |
| 70 | `_70_notice_trash_shows_deleted` | TC-P21 | BC-EDG | 70-79 |
| 71 | `_71_event_trash_shows_deleted` | TC-P21 | BC-EDG | 70-79 |
| 72 | `_72_notice_show_404_for_missing` | TC-N10 | BC-EDG | 70-79 |
| 73 | `_73_event_show_404_for_missing` | TC-N10 | BC-EDG | 70-79 |
| 74 | `_74_notice_content_accepts_long_html` | TC-P20 | BC-EDG | 70-79 |
| 75 | `_75_event_description_accepts_long_text` | TC-P20 | BC-EDG | 70-79 |
| 90 | `_90_notice_title_xss_is_escaped` | TC-N13 | TC-S | 90-99 |
| 91 | `_91_event_name_xss_is_escaped` | TC-N13 | TC-S | 90-99 |
| 92 | `_92_notice_partial_activity_logging_documents_gap` | TC-DEV01 | DEV | 90-99 |
| 93 | `_93_event_partial_activity_logging_documents_gap` | TC-DEV02 | DEV | 90-99 |

**Total: 61 test methods.**

---

## 5. Manual Test Steps (complex / workflow / defect-proving only)

### MT-1 — School Event soft-delete writes 'Deleted' activity log (BC-SM-02, `_23`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin with `frontoffice.school-event.*` | Dashboard |
| 2 | Create an event (name, type Academic, start today, end tomorrow) | Row in `fof_school_events` |
| 3 | From the events list, delete it | Redirect to communication `?tab=school-events`, success flash |
| 4 | `SELECT deleted_at FROM fof_school_events WHERE id=<id>` | NOT NULL |
| 5 | `SELECT event FROM sys_activity_logs WHERE subject_id=<id> ORDER BY id DESC LIMIT 1` | `Deleted` |

### MT-2 — Notice restore writes 'Restored'; store/update/destroy write NOTHING (DEV-FOF-NE-005, `_24`,`_92`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create a notice | Row saved; **no** new `sys_activity_logs` row for it (documented gap) |
| 2 | Edit the notice title | Updated; **no** activity row (documented gap) |
| 3 | Soft-delete it | `deleted_at` set; **no** activity row (documented gap) |
| 4 | Restore it from trash view | `deleted_at` NULL; `sys_activity_logs.event = 'Restored'` present |
| 5 | Force-delete it | row gone; `sys_activity_logs.event = 'Deleted'` present |

### MT-3 — ENUM divergences (DEV-FOF-NE-001/002/003, `_33`,`_35`,`_36`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Post a notice with `category=General` (offered in the UI dropdown) | App validation passes; DB rejects/coerces (value NOT stored as `General`) — divergence |
| 2 | Post a notice/event with `audience=Management` | Same divergence (not a DB ENUM member) |
| 3 | Post an event with `event_type=Function` | Same divergence |
| 4 | Attempt `event_type=Exam` via model layer | DB accepts; app FormRequest would reject — reverse divergence |

### MT-4 — end_date NOT-NULL-vs-nullable (DEV-FOF-NE-004, `_38`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Post an event with `end_date` left blank | App validation passes (rule is `nullable`) |
| 2 | Observe persistence | DB insert fails (`end_date` is NOT NULL) → 500 / integrity error. Data-loss/UX defect |

---

## 6. Known Source Defects (carried to Gap Analysis)

| ID | Sev | Sub-entity | Summary | Proving test |
|----|-----|-----------|---------|--------------|
| DEV-FOF-NE-001 | P2 | Notice | `category` app ENUM (`Event`,`General`) diverges from DB ENUM (`Sports`,`Cultural`,`Other`) | `_33`,`_34` |
| DEV-FOF-NE-002 | P2 | both | `audience` app list adds `Management` (not a DB ENUM value) | `_35` |
| DEV-FOF-NE-003 | P2 | Event | `event_type` app allows `Function`, rejects DB-valid `Exam`/`Admission` | `_36`,`_37` |
| DEV-FOF-NE-004 | P1 | Event | `end_date` DB NOT NULL but FormRequest `nullable` → blank end_date breaks insert | `_38` |
| DEV-FOF-NE-005 | P2 | both | Partial activity logging: store/update (and notice destroy) write no `activityLog()` | `_92`,`_93` |
| DEV-FOF-NE-006 | P3 | Event | `venue` FormRequest `max:150` stricter than column `VARCHAR(200)` | `_32` |
| SEC-FOF-003 | P1 | both | (module-wide) no FormRequest class → no `authorize()` defense-in-depth; inline validate only | n/a (documented) |
