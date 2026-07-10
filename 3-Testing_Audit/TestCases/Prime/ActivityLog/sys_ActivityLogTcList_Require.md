# sys_ActivityLog — Test Case List & Business Conditions

**Module:** Prime (PRM) · **Feature/Screen:** ActivityLog (central activity-log viewer, READ-ONLY)
**DB scope:** CENTRAL (`sys_central_activity_logs`, connection `mysql`, `prime_db`) — no tenant init.
**Test style:** Browser Dusk, `extends PrimeDuskTestCase`, host `http://127.0.0.1:8000`.
**Prefix:** `sys_` (primary table `sys_central_activity_logs`).
**Generated:** 2026-Jul-10

Sources read (HARD RULE 1):
- `Modules/Prime/app/Http/Controllers/ActivityLogController.php` (index / search — read only; create/store/edit/update/destroy stubs)
- `Modules/Prime/app/Models/ActivityLog.php` (`$table` `sys_central_activity_logs`, `$connection` `mysql`, `$fillable`, casts, relationships)
- `prime_ai/routes/web.php` (activity-log routes: 274 search, 276 resource [prime group], 495 & 640 resource [global-master groups])
- `Modules/Prime/resources/views/activity-log/index.blade.php` (selectors, `@can`, route ref)
- `database/migrations/2026_07_08_000001_create_central_activity_logs_table.php`
- `app/Helpers/activityLog.php` (central vs tenant sink routing)

---

## 1. Business Conditions

### BC-DB (schema — constraint #25: assert via Schema::hasTable + $fillable, no DDL file)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `sys_central_activity_logs` exists on central `mysql` connection | DDL-migration / #25 |
| BC-DB-02 | Columns: `id, subject_type, subject_id, user_id, event, properties(json), ip_address, user_agent, created_at, updated_at` | DDL-migration |
| BC-DB-03 | `properties` is JSON, cast to `array` | Model:34 |
| BC-DB-04 | No `deleted_at` — append-only, no SoftDeletes | Model / #25 |
| BC-DB-05 | `user_id` FK → `sys_users` (restrictOnDelete) | Migration:24 |

### BC-VAL (validation) — none
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | No FormRequest exists; `search`/`type` are read directly from Request. `search()` returns `[]` when `search` empty | Controller:112 |

### BC-AUTH (permission gates)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `index()` requires gate `prime.activity-log.viewAny` | Controller:23 |
| BC-AUTH-02 | `create()`/`store()` require `prime.activity-log.create` | Controller:60,69 |
| BC-AUTH-03 | `edit()`/`update()` require `prime.activity-log.update` | Controller:85,94 |
| BC-AUTH-04 | `destroy()` requires `prime.activity-log.delete` | Controller:103 |
| BC-AUTH-05 | `search()` performs **NO** Gate::authorize (any authenticated user) | Controller:107 |
| BC-AUTH-06 | View card gated by `@can('prime.activity-log.view')` | index.blade:32 |

### BC-BIZ (read behaviour)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Index lists logs `latest()` first, `paginate(20)` | Controller:24,49 |
| BC-BIZ-02 | Index search filters by `type` = subject / event / user / (default) ALL | Controller:25-48 |
| BC-BIZ-03 | `search()` JSON: subject→class_basename, event→distinct event, user→user name; ALL merges 5+5+5 capped 10 | Controller:117-180 |
| BC-BIZ-04 | Events rendered lower-case (`created/updated/deleted/restored/login/logout`) | index.blade:45-53 |
| BC-BIZ-05 | Central mutations write here via `activityLog()` when untenanted | Helper:35-39 |

### BC-REF / BC-INT
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `user()` belongsTo `Modules\Prime\Models\User`; `subject()` morphTo | Model:40-48 |
| BC-INT-01 | Read source populated by activityLog() calls across Prime controllers | grep callers |

### BC-EDG / BC-CFG
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Unknown `type` value falls to ALL branch (no error) | Controller:39 |
| BC-EDG-02 | Out-of-range `?page=` renders empty page, no error | Paginator |
| BC-CFG-01 | Route registered under both `prime.` and `global-master.` prefixes; search only under `prime.` | web.php:274,276,495,640 |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01/02/03 | #25 | Schema truth | Table + columns + casts correct | test_01 | Automated |
| TC-P02 | BC-CFG-01 | web.php | Routes registered | prime + global-master index + prime search present | test_10 | Automated |
| TC-P03 | BC-BIZ-01 | Ctrl | Index renders | "Activity Log" trail shown | test_11 | Automated |
| TC-P04 | BC-BIZ-01/04 | Ctrl | Trail/empty card | Audit Trail or empty-state | test_12 | Automated |
| TC-P05 | BC-CFG-01 | web.php | Prime-prefix path renders | `/prime/activity-log` loads | test_13 | Automated |
| TC-P06 | BC-BIZ-03 | Ctrl | Search event JSON | Seeded event in results | test_14 | Automated |
| TC-P07 | BC-BIZ-02 | Ctrl | Index filter narrows | Filtered index renders | test_16 | Automated |
| TC-P08 | BC-BIZ-05/INT-01 | Helper | Seeded row renders | Latest-first row visible | test_40 | Automated |
| TC-P09 | BC-BIZ-05 | Helper | Central sink active | Untenanted + helper exists | test_41 | Automated |
| TC-P10 | BC-BIZ-02 | blade | Search form/controls | form/input/suggestion present | test_60 | Automated |
| TC-P11 | BC-BIZ-02 | blade | Type filter options | Subject/Event/User present | test_61 | Automated |
| TC-P12 | BC-BIZ-02 | blade | Reset button | `#reset-btn` present | test_62 | Automated |
| TC-P13 | BC-BIZ-01 | blade | Pagination/empty footer | present | test_63 | Automated |
| TC-P14 | BC-REF-01 | Model | Central connection | mysql + table | test_91 | Automated |
| TC-P15 | BC-DB-01 | migration | Migration file defines table | Schema::create present | test_02 | Automated |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-VAL-01 | Ctrl | Search no term | Returns `[]` | test_15 | Automated |
| TC-N02 | BC-AUTH-01 | Ctrl | Guest access | Redirect /login | test_50 | Automated |
| TC-N03 | BC-AUTH-01 | Ctrl | Limited user index | 403 Forbidden | test_51 | Automated |
| TC-N04 | BC-AUTH-02 | Ctrl | Limited user create | 403 Forbidden | test_53 | Automated |
| TC-N05 | BC-EDG-01 | Ctrl | Invalid type param | ALL fallback, no error | test_70 | Automated |
| TC-N06 | BC-EDG-02 | Paginator | Page out-of-range | Renders, no error | test_71 | Automated |
| TC-N07 | BC-BIZ-03 | Ctrl | Injection-shaped search | Bound params, JSON array | test_72 | Automated |
| TC-N08 | BC-DB-04 | Model | No soft-delete semantics | Trait absent | test_92 | Automated |

### Dependency / Security (TC-D / TC-S)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | E | BC-INT-01 | Helper | Central sink read path | Untenanted helper | test_41 | Automated |
| TC-S01 | — | BC-BIZ-02 | blade | Reflected XSS escaped | Not executed | test_90 | Automated |
| TC-S02 | — | BC-AUTH-05 | Ctrl | search() missing gate (finding) | Reachable by any authed user | test_52 | Automated |
| TC-S03 | — | BC-BIZ-03 | Ctrl | Injection-shaped input | Safe | test_72 | Automated |

---

## 3. Test Method Index
| # | Method | TC Map | Band |
|---|--------|--------|------|
| 1 | test_activitylog_01_migration_model_and_request_configuration_are_correct | TC-P01 | 01–09 |
| 2 | test_activitylog_02_central_migration_file_defines_the_table | TC-P15 | 01–09 |
| 3 | test_activitylog_10_index_and_search_routes_are_registered | TC-P02 | 10–19 |
| 4 | test_activitylog_11_index_renders_activity_trail_for_admin | TC-P03 | 10–19 |
| 5 | test_activitylog_12_index_shows_audit_trail_card_or_empty_state | TC-P04 | 10–19 |
| 6 | test_activitylog_13_prime_prefixed_index_path_also_renders | TC-P05 | 10–19 |
| 7 | test_activitylog_14_search_json_endpoint_returns_event_matches | TC-P06 | 10–19 |
| 8 | test_activitylog_15_search_json_endpoint_returns_empty_without_search_term | TC-N01 | 10–19 |
| 9 | test_activitylog_16_index_search_filter_narrows_without_error | TC-P07 | 10–19 |
| 10 | test_activitylog_40_seeded_central_row_renders_in_index | TC-P08 | 40–49 |
| 11 | test_activitylog_41_activity_log_helper_targets_central_sink_when_untenanted | TC-P09/TC-D01 | 40–49 |
| 12 | test_activitylog_50_guest_is_redirected_to_login | TC-N02 | 50–59 |
| 13 | test_activitylog_51_index_is_guarded_by_view_any_gate_for_limited_user | TC-N03 | 50–59 |
| 14 | test_activitylog_52_search_endpoint_has_no_gate_finding | TC-S02 | 50–59 |
| 15 | test_activitylog_53_create_endpoint_is_gated | TC-N04 | 50–59 |
| 16 | test_activitylog_60_search_form_and_input_present | TC-P10 | 60–69 |
| 17 | test_activitylog_61_type_filter_offers_subject_event_user_options | TC-P11 | 60–69 |
| 18 | test_activitylog_62_reset_button_present | TC-P12 | 60–69 |
| 19 | test_activitylog_63_pagination_footer_or_empty_state_present | TC-P13 | 60–69 |
| 20 | test_activitylog_70_index_with_invalid_type_param_falls_back_to_all_case | TC-N05 | 70–79 |
| 21 | test_activitylog_71_index_out_of_range_page_renders | TC-N06 | 70–79 |
| 22 | test_activitylog_72_search_json_with_injection_shaped_input_is_safe | TC-N07/TC-S03 | 70–79 |
| 23 | test_activitylog_90_reflected_search_input_is_escaped | TC-S01 | 90–99 |
| 24 | test_activitylog_91_model_is_pinned_to_central_connection | TC-P14 | 90–99 |
| 25 | test_activitylog_92_central_log_has_no_soft_delete_semantics | TC-N08 | 90–99 |

**Total: 25 methods.**

## Known Source Defects (candidates — verified in source, proven by tests above)
| ID | Description | Evidence | Proving test |
|----|-------------|----------|--------------|
| DEV-PRM-AL-001 | `search()` has NO Gate::authorize — any authenticated central user can query activity data (index requires `prime.activity-log.viewAny`) | Controller:107-181 | test_52 |
| DEV-PRM-AL-002 | `activity-log` resource registered 3× (once `prime.`, twice `global-master.`) → duplicate route-name registration | web.php:276,495,640 | test_10 |
| DEV-PRM-AL-003 | `central.global-master.activity-log.search` not registered; index.blade `data-search-url` points at the index route, not the search endpoint | web.php + index.blade:13 | test_10 |
| DEV-PRM-AL-004 | `create()/edit()/show()` return `view('prime::create'/'edit'/'show')` (non-existent view paths; real files are `activity-log/*`); `store()/update()/destroy()` are empty no-ops | Controller:58-105 | test_53 (gate), documented |
| DEV-PRM-AL-005 | Audit BR-PRM-012/023: activity-log coverage flagged <100%. Source confirms `activityLog()` invoked across many Prime controllers — documented as coverage observation, not asserted as a bug | grep callers | test_41 |
