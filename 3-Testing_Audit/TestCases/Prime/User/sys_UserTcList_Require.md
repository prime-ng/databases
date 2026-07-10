# Prime → User — Test Case List & Requirements (`sys_UserTcList_Require.md`)

- **Module:** Prime (PRM) · **Feature/Screen:** User (central user management)
- **DB scope:** CENTRAL (`prime_db`, connection `mysql`) — **no tenant init**
- **Primary table:** `sys_users` (DDL prefix verified `sys_` in `_prime_db_v4.sql`)
- **Controller:** `Modules\Prime\Http\Controllers\UserController`
- **FormRequest:** `Modules\Prime\Http\Requests\UserRequest`
- **Model (app):** `Modules\Prime\Models\User` (`$table=sys_users`, `$connection=mysql`, SoftDeletes)
- **Model (runner):** `App\Models\User` (testing `$table=sys_users`)
- **Activity sink:** `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog` (central; constraint #25)
- **Test file:** `sys_User_TestCas.php` (single comprehensive suite, 44 methods)
- **Base class:** `PrimeDuskTestCase` (host locked to `http://127.0.0.1:8000`)

> **Prefix note:** the module registry flag maps PRM → `prm_`, but the feature's **primary table** is `sys_users`, so per the authoritative table-prefix rule the artifact prefix is **`sys_`** (matches committed central siblings, e.g. `sys_users`). Recorded discrepancy: registry says `prm_`; DDL/table says `sys_`.

---

## 1. Business Conditions

### BC-DB (schema — `DDL-sys_users`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `sys_users` exists with columns id, emp_code, short_name, name, email, mobile_no, phone_no, two_factor_auth_enabled, email_verified_at, password, is_super_admin, super_admin_flag, remember_token, is_active, timestamps, deleted_at | DDL-sys_users |
| BC-DB-02 | Unique keys: `uq_users_empCode`, `uq_users_email`, `uq_users_mobileNo`, `uq_single_super_admin` | DDL-sys_users |
| BC-DB-03 | `super_admin_flag` is a **STORED generated** column `= CASE WHEN is_super_admin=1 THEN 1 ELSE NULL` | DDL-sys_users |
| BC-DB-04 | `emp_code` is `VARCHAR(20) NOT NULL` | DDL-sys_users |
| BC-DB-05 | Triggers `trg_users_prevent_delete_super` / `trg_users_prevent_update_super` block deleting/demoting a super admin (SQLSTATE 45000) | DDL-sys_users |
| BC-DB-06 | `deleted_at` present → soft deletes | DDL-sys_users |

### BC-VAL (validation — `UserRequest`)
| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | `name` required, string, max:255 | Req-rules |
| BC-VAL-02 | `email` required, email, max:255, `unique:sys_users,email` (ignore self on update) | Req-rules |
| BC-VAL-03 | `password` required-on-create / nullable-on-update, min:8, confirmed | Req-rules |
| BC-VAL-04 | `roles` required, array, min:1, **max:1** | Req-rules |
| BC-VAL-05 | `emp_code` required, `Rule::unique('sys_users','emp_code')->ignore(id)` | Req-rules |
| BC-VAL-06 | `short_name` required, unique:sys_users,short_name | Req-rules |
| BC-VAL-07 | `phone_no` nullable digits:10; `mobile_no` nullable digits_between:10,12 | Req-rules |
| BC-VAL-08 | `image` nullable image max:2048 (**dead — see BUG-PRM-N03**) | Req-rules |

### BC-AUTH (gates — `UserController` + routes)
| ID | Gate ↔ method | Source |
|----|---------------|--------|
| BC-AUTH-01 | `prime.user.viewAny` ↔ index/usersByRole | Ctrl |
| BC-AUTH-02 | `prime.user.create` ↔ create/store | Ctrl |
| BC-AUTH-03 | `prime.user.view` ↔ show | Ctrl |
| BC-AUTH-04 | `prime.user.update` ↔ edit/update/toggleStatus | Ctrl |
| BC-AUTH-05 | `prime.user.delete` ↔ destroy | Ctrl |
| BC-AUTH-06 | `prime.user.restore` ↔ restore/trashedUser | Ctrl |
| BC-AUTH-07 | `prime.user.forceDelete` ↔ forceDelete | Ctrl |
| BC-AUTH-08 | `prime.super-admin.promote` ↔ promoteToSuperAdmin (separate high-privilege flow) | Ctrl |

### BC-BIZ (business logic — `UserController`)
| ID | Behaviour | Source |
|----|-----------|--------|
| BC-BIZ-01 | store() hashes password (`Hash::make`) | Ctrl |
| BC-BIZ-02 | store() emails `LoginMail` credentials to the new user (`Mail::to($user->email)`) | Ctrl |
| BC-BIZ-03 | store() notifies active super admins via `UserCreatedNotification` | Ctrl |
| BC-BIZ-04 | update() whitelists fields via `$request->only([...])` — **excludes is_super_admin** | Ctrl |
| BC-BIZ-05 | usersByRole() filters `User::role($role)->paginate(10)` | Ctrl |
| BC-BIZ-06 | destroy() blocks self-deletion; sets is_active=false then soft-deletes | Ctrl |
| BC-BIZ-07 | toggleStatus() blocks self toggle (JSON success=false) | Ctrl |
| BC-BIZ-08 | Activity events (literal): `created`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled`, `Promoted` | Ctrl |
| BC-BIZ-09 | Mutations log `performed_by => Auth::user()->name` | Ctrl |
| BC-BIZ-10 | index() paginates 10; uses real counts (User/Role/Tenant) | Ctrl |

### BC-EDG / BC-CFG
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `emp_code` bounded to 20 chars | DDL |
| BC-CFG-01 | Views auto-escape `{{ $user->name }}` (no `{!! !!}`) | Blade |

### Known Source Defects (audit-equivalent, PRM prefix)
| ID | Sev | Status vs current source | Proving test |
|----|-----|--------------------------|--------------|
| SEC-PRM-003 | P0 | **REMEDIATED** — update() excludes is_super_admin; promote is a separate gate | test_user_12, test_user_90 |
| BUG-PRM-002 | P0 | **REMEDIATED** — `$fillable` excludes is_super_admin & super_admin_flag | test_user_01, test_user_91 |
| FILL-PRM-001 | P3 | **RESIDUAL** — `remember_token` still fillable | test_user_01 |
| BUG-PRM-010 | P1 | **REMEDIATED** — usersByRole filters by `$role` | test_user_14 |
| GAP-PRM-004 | P1 | **REMEDIATED** — store emails credentials to new user | test_user_10 |
| BUG-PRM-009 | P2 | **RESIDUAL/relocated** — usersByRole still uses `rand()` stub stats | test_user_15 |
| BUG-PRM-N01 | P1 | **OPEN (new)** — usersByRole omits totalTenants/activeTenants → index view undefined-var | test_user_16 |
| BUG-PRM-N02 | P2 | **OPEN (new)** — two-factor field mismatch (`two_fact_enabled` vs `two_factor_auth_enabled`) | test_user_31 |
| BUG-PRM-N03 | P2 | **OPEN (new)** — image rule key `image` vs upload/controller `user_img` (dead validation) | test_user_32 |
| BUG-PRM-N04 | P3 | **OPEN (new)** — media collection mismatch (model `image` vs controller `user_img`) | (documented; see Gap Analysis) |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01/06 | DDL | Schema/model/request config truth | Table, columns, fillable, casts, SoftDeletes correct | test_user_01 | Ready |
| TC-P02 | BC-DB-02 | DDL | Unique indexes exist | 4 unique keys present | test_user_02 | Ready |
| TC-P03 | BC-DB-03 | DDL | Generated column | super_admin_flag EXTRA=GENERATED | test_user_03 | Ready |
| TC-P04 | BC-AUTH | Routes | Routes registered | 13 central.prime.user.* routes exist | test_user_04 | Ready |
| TC-P05 | BC-AUTH | Ctrl | Gates referenced | All prime.user.* + promote gate present | test_user_05 | Ready |
| TC-P10 | BC-BIZ-01/02 | Ctrl | store hashes + emails creds | LoginMail to new user | test_user_10 | Ready |
| TC-P11 | BC-BIZ-03 | Ctrl | store notifies super admins | UserCreatedNotification | test_user_11 | Ready |
| TC-P13 | BC-AUTH-08 | Ctrl | Promotion gated separately | promote gate + route | test_user_13 | Ready |
| TC-P14 | BC-BIZ-05 | Ctrl | usersByRole filters | User::role($role) | test_user_14 | Ready |
| TC-P33 | BC-BIZ-08 | Ctrl | Literal activity events | 7 literal strings | test_user_33 | Ready |
| TC-P34 | BC-BIZ | Ctrl | Central activity sink | sys_central_activity_logs | test_user_34 | Ready |
| TC-P40 | BC-DB-01 | DB | Row persists | Row in sys_users (guarded) | test_user_40 | Ready |
| TC-P60 | UI | Blade | Index renders | Widgets/table/pagination | test_user_60 | Ready |
| TC-P61 | UI | Blade | Create form renders | All fields + submit | test_user_61 | Ready |
| TC-P62 | UI | Blade | Role filter dropdown | #dropdownRoles + All Users | test_user_62 | Ready |
| TC-P63 | UI | Blade | Trash renders | Table present | test_user_63 | Ready |
| TC-P64 | BC-BIZ-10 | Ctrl | Paginate 10 | paginate(10) | test_user_64 | Ready |

### Negative / Defect (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N15 | BUG-PRM-009 | Ctrl | rand() stub stats residual | rand(1000,2000)/rand(10,30) present | test_user_15 | Ready |
| TC-N16 | BUG-PRM-N01 | Ctrl | Missing tenant view vars | totalTenants/activeTenants absent in usersByRole | test_user_16 | Ready |
| TC-N17 | BC-BIZ-06 | Ctrl | Self-delete blocked | Auth-id guard present | test_user_17 | Ready |
| TC-N18 | BC-BIZ-07 | Ctrl | Self-toggle blocked | success=false | test_user_18 | Ready |
| TC-N30 | BC-VAL-* | Req | Validation rule set | All fragments present | test_user_30 | Ready |
| TC-N31 | BUG-PRM-N02 | Req/Ctrl | 2FA field mismatch | validated key not read by ctrl | test_user_31 | Ready |
| TC-N32 | BUG-PRM-N03 | Req/Ctrl | Image field mismatch | rule key ≠ upload key | test_user_32 | Ready |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Method | Status |
|-------|-----|----|--------|-------------|--------|--------|
| TC-D41 | B/F | BC-DB-06 | DDL/Ctrl | Soft-delete column + restore/forceDelete flow | test_user_41 | Ready |
| TC-D42 | G | BC-DB-02 | DDL | emp_code unique index | test_user_42 | Ready |
| TC-D43 | G | BC-DB-02 | DDL | email unique index | test_user_43 | Ready |
| TC-D44 | — | BC-DB-03 | DB | Generated flag mirrors is_super_admin | test_user_44 | Ready |
| TC-D45 | C | BC-DB-05 | DDL | Super-admin protection triggers | test_user_45 | Ready |

### Permissions (TC-AUTH) & Security (TC-S)
| TC ID | BC | Source | Description | Method | Status |
|-------|----|--------|-------------|--------|--------|
| TC-S50 | BC-AUTH | Blade | Guest → /login | test_user_50 | Ready |
| TC-AUTH51 | BC-AUTH-01 | Ctrl | index gates viewAny | test_user_51 | Ready |
| TC-AUTH52 | BC-AUTH-02 | Ctrl | store gates create | test_user_52 | Ready |
| TC-AUTH53 | BC-AUTH-04 | Ctrl | update gates update | test_user_53 | Ready |
| TC-AUTH54 | BC-AUTH-05 | Ctrl | destroy gates delete | test_user_54 | Ready |
| TC-AUTH55 | BC-AUTH-06/07 | Ctrl | restore/forceDelete gates | test_user_55 | Ready |
| TC-AUTH56 | BC-AUTH | Blade | View gates action controls | test_user_56 | Ready |
| TC-S90 | SEC-PRM-003 | Ctrl/Model | Escalation prevented (3 layers) | test_user_90 | Ready |
| TC-S91 | BUG-PRM-002 | Model | Mass-assignment guard | test_user_91 | Ready |
| TC-S92 | IDOR | Ctrl | Route-model binding + view gate | test_user_92 | Ready |
| TC-S93 | BC-DB-02 | DDL | Single super-admin invariant | test_user_93 | Ready |
| TC-S94 | BC-BIZ-09 | Ctrl | Actor logged on mutation | test_user_94 | Ready |
| TC-EDG70 | BC-EDG-01 | DDL | emp_code 20-char limit | test_user_70 | Ready |
| TC-S71 | BC-CFG-01 | Blade | Escaped name output | test_user_71 | Ready |

> **BC-SM:** Not applicable — the User screen has no multi-state workflow lifecycle beyond `is_active` on/off and soft-delete (covered by BC-BIZ/BC-DB).

---

## 3. Test Method Index (bands per §WP-G)
| # | Method | TC | Band |
|---|--------|----|------|
| 1 | test_user_01_schema_model_and_request_configuration_are_correct | TC-P01 | 01–09 config |
| 2 | test_user_02_sys_users_unique_indexes_exist | TC-P02 | 01–09 |
| 3 | test_user_03_super_admin_flag_is_stored_generated_column | TC-P03 | 01–09 |
| 4 | test_user_04_user_routes_are_registered | TC-P04 | 01–09 |
| 5 | test_user_05_controller_uses_exact_permission_gates | TC-P05 | 01–09 |
| 6 | test_user_10_store_hashes_password_and_emails_credentials_to_new_user | TC-P10 | 10–19 biz |
| 7 | test_user_11_store_notifies_super_admins | TC-P11 | 10–19 |
| 8 | test_user_12_update_excludes_super_admin_from_mass_assignment | TC-S/SEC-PRM-003 | 10–19 |
| 9 | test_user_13_promote_super_admin_is_separate_high_privilege_gate | TC-P13 | 10–19 |
| 10 | test_user_14_users_by_role_filters_by_role_scope | TC-P14 | 10–19 |
| 11 | test_user_15_users_by_role_still_uses_random_stub_stats | TC-N15 | 10–19 |
| 12 | test_user_16_users_by_role_omits_tenant_stats_needed_by_index_view | TC-N16 | 10–19 |
| 13 | test_user_17_destroy_blocks_self_deletion | TC-N17 | 10–19 |
| 14 | test_user_18_toggle_status_blocks_self_toggle | TC-N18 | 10–19 |
| 15 | test_user_30_request_validation_rules_are_enforced | TC-N30 | 30–39 val |
| 16 | test_user_31_two_factor_field_name_mismatch_drops_toggle | TC-N31 | 30–39 |
| 17 | test_user_32_image_validation_field_name_mismatch | TC-N32 | 30–39 |
| 18 | test_user_33_activity_log_events_are_literal_strings | TC-P33 | 30–39 |
| 19 | test_user_34_activity_sink_is_central_activity_log_table | TC-P34 | 30–39 |
| 20 | test_user_40_user_row_persists_to_sys_users | TC-P40 | 40–49 fk/dep |
| 21 | test_user_41_soft_delete_column_and_controller_flow | TC-D41 | 40–49 |
| 22 | test_user_42_emp_code_uniqueness_enforced_by_index | TC-D42 | 40–49 |
| 23 | test_user_43_email_uniqueness_enforced_by_index | TC-D43 | 40–49 |
| 24 | test_user_44_super_admin_flag_reflects_is_super_admin | TC-D44 | 40–49 |
| 25 | test_user_45_super_admin_protection_triggers_exist | TC-D45 | 40–49 |
| 26 | test_user_50_guest_is_redirected_to_login | TC-S50 | 50–59 authz |
| 27 | test_user_51_index_requires_view_any_gate | TC-AUTH51 | 50–59 |
| 28 | test_user_52_create_requires_create_gate | TC-AUTH52 | 50–59 |
| 29 | test_user_53_update_requires_update_gate | TC-AUTH53 | 50–59 |
| 30 | test_user_54_destroy_requires_delete_gate | TC-AUTH54 | 50–59 |
| 31 | test_user_55_restore_and_force_delete_require_gates | TC-AUTH55 | 50–59 |
| 32 | test_user_56_index_view_gates_action_controls | TC-AUTH56 | 50–59 |
| 33 | test_user_60_index_page_renders | TC-P60 | 60–69 ui |
| 34 | test_user_61_create_form_renders_all_fields | TC-P61 | 60–69 |
| 35 | test_user_62_role_filter_dropdown_present | TC-P62 | 60–69 |
| 36 | test_user_63_trash_page_renders | TC-P63 | 60–69 |
| 37 | test_user_64_index_paginates_ten_per_page | TC-P64 | 60–69 |
| 38 | test_user_70_emp_code_respects_twenty_char_limit | TC-EDG70 | 70–79 edge |
| 39 | test_user_71_views_escape_user_name_output | TC-S71 | 70–79 |
| 40 | test_user_90_super_admin_escalation_via_update_is_prevented | TC-S90 | 90–99 security |
| 41 | test_user_91_mass_assignment_guard_on_generated_and_flag_columns | TC-S91 | 90–99 |
| 42 | test_user_92_show_and_edit_use_route_model_binding | TC-S92 | 90–99 |
| 43 | test_user_93_single_super_admin_invariant_is_enforced | TC-S93 | 90–99 |
| 44 | test_user_94_activity_log_records_actor_for_mutations | TC-S94 | 90–99 |
